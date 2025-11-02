import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/auth_repository.dart';

/// Provider for [AuthRepository] instance
/// 
/// This provider creates and provides a singleton instance of [AuthRepository]
/// that can be accessed throughout the app.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider for Firebase Auth state changes stream
/// 
/// Emits events whenever the user's authentication state changes:
/// - User signs in
/// - User signs out
/// - User's token is refreshed
/// 
/// Returns a stream of [User?] where:
/// - `User` object when authenticated
/// - `null` when not authenticated
final authStateChangesProvider = StreamProvider<User?>((ref) {
  ref.watch(authRepositoryProvider);
  return FirebaseAuth.instance.authStateChanges();
});

/// Provider for the current authenticated user
/// 
/// Returns the currently signed-in [User] or `null` if not authenticated.
/// This is a synchronous snapshot of the current auth state.
/// 
/// For listening to auth state changes, use [authStateChangesProvider] instead.
final currentUserProvider = Provider<User?>((ref) {
  return FirebaseAuth.instance.currentUser;
});

// TODO: Add providers for:
// - UserProfile from Firestore (AsyncValue<UserModel?>)
// - Auth loading state
// - Auth error state
