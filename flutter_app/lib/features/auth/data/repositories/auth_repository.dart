import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/services/secure_storage_service.dart';

/// Repository for managing user authentication operations
/// 
/// This repository handles all authentication-related operations including:
/// - Email/password registration and login
/// - Google Sign-In
/// - Password reset
/// - Session management
/// - User profile management in Firestore
class AuthRepository {
  /// Firebase Authentication instance
  final FirebaseAuth _firebaseAuth;
  
  /// Google Sign-In instance
  final GoogleSignIn _googleSignIn;
  
  /// Cloud Firestore instance for user profile management
  final FirebaseFirestore _firebaseFirestore;

  /// T074: Secure storage service for token persistence
  final SecureStorageService _secureStorage;

  /// Creates an instance of [AuthRepository]
  /// 
  /// By default, uses the default instances of Firebase services.
  /// Custom instances can be provided for testing purposes.
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firebaseFirestore,
    SecureStorageService? secureStorage,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firebaseFirestore = firebaseFirestore ?? FirebaseFirestore.instance,
        _secureStorage = secureStorage ?? SecureStorageService();

  /// Registers a new user with email and password
  /// 
  /// Creates a Firebase Auth user and a corresponding Firestore user profile.
  /// 
  /// Throws:
  /// - [WeakPasswordException] if password is less than 8 characters
  /// - [EmailAlreadyInUseException] if email is already registered
  /// - [InvalidEmailException] if email format is invalid
  /// - [NetworkException] if network error occurs
  /// - [AuthException] for other authentication errors
  Future<User> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Create user with Firebase Authentication
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw AuthException(message: 'Failed to create user');
      }

      // Create user profile in Firestore
      await _createUserProfile(
        uid: user.uid,
        email: email,
        authProvider: 'email',
      );

      // T078: Save token to secure storage for persistent login
      await _saveUserToken(user);

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthException(message: 'Registration failed: $e', originalError: e);
    }
  }

  /// Creates a user profile document in Firestore
  /// 
  /// This is called after successful Firebase Auth user creation.
  /// Creates a document at /users/{uid} with user metadata.
  Future<void> _createUserProfile({
    required String uid,
    required String email,
    required String authProvider,
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final now = FieldValue.serverTimestamp();
      await _firebaseFirestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
        'createdAt': now,
        'lastActivityAt': now,
        'authProvider': authProvider,
        'isDeleted': false,
      });
    } catch (e) {
      // If Firestore profile creation fails, we should delete the Auth user
      // to maintain consistency
      try {
        await _firebaseAuth.currentUser?.delete();
      } catch (_) {
        // Ignore deletion error, user can be cleaned up later
      }
      throw AuthException(message: 'Failed to create user profile: $e', originalError: e);
    }
  }

  /// Handles FirebaseAuthException and converts to custom exceptions
  /// 
  /// Maps Firebase error codes to domain-specific exception types
  /// for better error handling in the UI layer.
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return WeakPasswordException(message: 'Password must be at least 8 characters');
      case 'email-already-in-use':
        return EmailAlreadyInUseException(e.email ?? '');
      case 'invalid-email':
        return InvalidEmailException(e.email ?? '');
      case 'user-not-found':
        return UserNotFoundException(e.email ?? '');
      case 'wrong-password':
        return InvalidCredentialsException(message: 'Incorrect password');
      case 'network-request-failed':
        return NetworkException(message: 'Network error. Please check your connection', originalError: e);
      case 'too-many-requests':
        return RateLimitException(message: 'Too many attempts. Please try again later');
      default:
        return AuthException(message: 'Authentication error: ${e.message}', code: e.code, originalError: e);
    }
  }

  /// Signs in a user with email and password
  /// 
  /// Implements rate limiting via Cloud Functions to prevent brute force attacks.
  /// After 5 failed attempts, the account is locked for 15 minutes.
  /// 
  /// Throws:
  /// - [RateLimitException] if account is locked due to too many failed attempts
  /// - [UserNotFoundException] if email is not registered
  /// - [InvalidCredentialsException] if password is incorrect
  /// - [NetworkException] if network error occurs
  /// - [AuthException] for other authentication errors
  Future<User> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Check rate limit before attempting login
      await _checkRateLimit(email);

      // Attempt Firebase Authentication sign in
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw AuthException(message: 'Failed to sign in');
      }

      // Record successful login attempt
      await _recordLoginAttempt(email: email, success: true);

      // Update last activity timestamp
      await _updateLastActivity(user.uid);

      // T078: Save token to secure storage for persistent login
      await _saveUserToken(user);

      return user;
    } on FirebaseAuthException catch (e) {
      // Record failed login attempt
      await _recordLoginAttempt(email: email, success: false);
      throw _handleAuthException(e);
    } catch (e) {
      // If it's already a custom exception, rethrow it
      if (e is RateLimitException ||
          e is UserNotFoundException ||
          e is InvalidCredentialsException ||
          e is NetworkException ||
          e is AuthException) {
        rethrow;
      }
      throw AuthException(message: 'Sign in failed: $e', originalError: e);
    }
  }

  /// Checks login rate limit via Cloud Functions (HTTP)
  /// 
  /// Calls the checkLoginRateLimit HTTP Function to verify if the user
  /// is allowed to attempt login. Throws [RateLimitException] if locked.
  Future<void> _checkRateLimit(String email) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://asia-northeast1-solo-dev-quest-app.cloudfunctions.net/checkLoginRateLimit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        // Rate limit check passed
        return;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 403 && data['error'] == 'permission-denied') {
        final details = data['details'] as Map<String, dynamic>?;
        final remainingMinutes = details?['remainingMinutes'] as int? ?? 15;
        throw RateLimitException(
          message: data['message'] ??
              'Too many login attempts. Please try again later',
          lockedUntil: details?['lockedUntil'] != null
              ? DateTime.parse(details!['lockedUntil'] as String)
              : DateTime.now().add(Duration(minutes: remainingMinutes)),
        );
      }

      throw NetworkException(
        message: 'Failed to check rate limit: ${data['message'] ?? 'Unknown error'}',
      );
    } catch (e) {
      if (e is RateLimitException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to check rate limit: $e',
        originalError: e,
      );
    }
  }

  /// Records a login attempt via Cloud Functions (HTTP)
  /// 
  /// Calls the recordLoginAttempt HTTP Function to track successful
  /// and failed login attempts for rate limiting purposes.
  Future<void> _recordLoginAttempt({
    required String email,
    required bool success,
  }) async {
    try {
      await http.post(
        Uri.parse(
            'https://asia-northeast1-solo-dev-quest-app.cloudfunctions.net/recordLoginAttempt'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'success': success,
        }),
      );
    } catch (e) {
      // ログイン試行の記録失敗はエラーとして扱わない（ログに記録のみ）
      print('Failed to record login attempt: $e');
    }
  }

  /// Updates the user's last activity timestamp in Firestore
  /// 
  /// This is used for session expiry management (30-day timeout).
  Future<void> _updateLastActivity(String uid) async {
    try {
      await _firebaseFirestore.collection('users').doc(uid).update({
        'lastActivityAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Don't throw on update failure to avoid blocking user flow
      print('Failed to update last activity: $e');
    }
  }

  /// Signs out the current user
  /// 
  /// Signs out from both Firebase Auth and Google Sign-In if applicable.
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
        // T079: Delete tokens from secure storage
        _secureStorage.deleteToken(),
      ]);
    } catch (e) {
      throw AuthException(message: 'Failed to sign out: $e', originalError: e);
    }
  }

  /// Signs in a user with their Google account
  /// 
  /// Initiates Google Sign-In flow, authenticates with Firebase,
  /// and creates a Firestore profile for new users.
  /// 
  /// Returns:
  /// - [User?] - The signed-in user, or null if user cancelled the flow
  /// 
  /// Throws:
  /// - [PlatformException] if Google Sign-In service is unavailable
  /// - [NetworkException] if network error occurs
  /// - [AuthException] for other authentication errors
  Future<User?> signInWithGoogle() async {
    try {
      // T055: Initiate Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // User cancelled the sign-in
      if (googleUser == null) {
        return null;
      }

      // Obtain Google authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential for Firebase Auth
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // T056: Sign in to Firebase with Google credential
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      final user = userCredential.user;
      if (user == null) {
        throw AuthException(message: 'Failed to sign in with Google');
      }

      // T057: Check if this is a new user and create Firestore profile
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser) {
        await _createUserProfile(
          uid: user.uid,
          email: user.email ?? '',
          authProvider: 'google',
          displayName: user.displayName,
          photoURL: user.photoURL,
        );
      }

      // Update last activity timestamp for session management
      await _updateLastActivity(user.uid);

      // T078: Save token to secure storage for persistent login
      await _saveUserToken(user);

      return user;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Authentication errors
      throw _handleAuthException(e);
    } on PlatformException catch (e) {
      // T058: Handle Google Sign-In specific errors
      if (e.code == 'sign_in_failed' || e.code == 'network_error') {
        throw NetworkException(
          message: 'Google Sign-In is currently unavailable. Please try again or use email/password login',
          originalError: e,
        );
      }
      throw AuthException(
        message: 'Google Sign-In failed: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      // Catch any other unexpected errors
      if (e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw AuthException(
        message: 'Google Sign-In failed: $e',
        originalError: e,
      );
    }
  }

  /// Sends a password reset email to the specified email address
  /// 
  /// T062-T064: Password reset email functionality
  /// Sends a Firebase Authentication password reset link to the user's email.
  /// The link is valid for 1 hour.
  /// 
  /// Note: For security reasons, this method does not reveal whether
  /// the email exists in the system. It will succeed regardless.
  /// 
  /// Throws:
  /// - [InvalidEmailException] if email format is invalid
  /// - [NetworkException] if network error occurs
  /// - [AuthException] for other authentication errors
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      // T063: Call Firebase Auth sendPasswordResetEmail
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // T064: Handle FirebaseAuthException
      throw _handleAuthException(e);
    } catch (e) {
      // Catch any other unexpected errors
      if (e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw AuthException(
        message: 'Failed to send password reset email: $e',
        originalError: e,
      );
    }
  }

  /// T071: Gets the currently signed-in user
  /// 
  /// Returns the current Firebase Auth user if logged in, null otherwise.
  /// This is a synchronous method that returns the cached user state.
  /// 
  /// Returns:
  /// - [User?]: The currently signed-in user, or null if not authenticated
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  /// T072: Returns a stream of authentication state changes
  /// 
  /// Emits a new User object whenever the authentication state changes
  /// (e.g., user signs in, signs out, or token refresh occurs).
  /// 
  /// Returns:
  /// - [Stream<User?>]: Stream that emits User when authenticated, null when not
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  /// T078: Helper method to save user token to secure storage
  /// 
  /// Extracts Firebase ID token and saves it to secure storage
  /// for persistent login functionality.
  Future<void> _saveUserToken(User user) async {
    try {
      // Get ID token from Firebase Auth user
      final idTokenResult = await user.getIdTokenResult();
      final idToken = await user.getIdToken();
      
      if (idToken == null) {
        print('Warning: Unable to get ID token for user ${user.uid}');
        return;
      }

      // Save token to secure storage
      await _secureStorage.saveToken(
        firebaseToken: idToken,
        refreshToken: user.refreshToken ?? '',
        tokenExpiry: idTokenResult.expirationTime?.toIso8601String() ?? 
            DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
      );
    } catch (e) {
      // Don't throw error to avoid blocking user flow
      print('Failed to save user token: $e');
    }
  }

  /// T073: Checks if the user's session has expired (30 days)
  /// 
  /// Queries Firestore to get the user's lastActivityAt timestamp
  /// and compares it with the current time. If more than 30 days
  /// have passed, signs the user out.
  /// 
  /// Returns:
  /// - [bool]: true if session is valid, false if expired
  Future<bool> checkSessionExpiry(String uid) async {
    try {
      // オフライン対応: キャッシュから取得を優先、タイムアウト付き
      DocumentSnapshot userDoc;
      try {
        userDoc = await _firebaseFirestore
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
      } catch (cacheError) {
        // キャッシュがない場合、サーバーから取得を試みる（3秒タイムアウト）
        try {
          userDoc = await _firebaseFirestore
              .collection('users')
              .doc(uid)
              .get()
              .timeout(const Duration(seconds: 3));
        } catch (serverError) {
          // 取得失敗時はセッション有効として扱う（オフライン時にログアウトさせない）
          print('Failed to check session expiry (offline?): $serverError');
          return true;
        }
      }
      
      if (!userDoc.exists) {
        // User profile doesn't exist, sign out
        await signOut();
        return false;
      }

      final data = userDoc.data() as Map<String, dynamic>?;
      if (data == null || data['lastActivityAt'] == null) {
        // No lastActivityAt field, consider session valid
        // Update it for future checks (non-blocking)
        _updateLastActivity(uid).catchError((e) {
          print('Failed to update last activity: $e');
        });
        return true;
      }

      final lastActivityAt = (data['lastActivityAt'] as Timestamp).toDate();
      final now = DateTime.now();
      final daysSinceLastActivity = now.difference(lastActivityAt).inDays;

      if (daysSinceLastActivity > 30) {
        // Session expired (more than 30 days since last activity)
        await signOut();
        return false;
      }

      // Session is valid, update last activity (non-blocking)
      _updateLastActivity(uid).catchError((e) {
        print('Failed to update last activity: $e');
      });
      return true;
    } catch (e) {
      // On error, assume session is valid (don't block user when offline)
      print('Failed to check session expiry: $e');
      return true;
    }
  }
}
