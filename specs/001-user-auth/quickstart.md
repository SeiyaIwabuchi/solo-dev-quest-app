# Quickstart Guide: User Authentication

**Feature**: 001-user-auth  
**Date**: 2025-11-01  
**Estimated Time**: 2-3 hours for basic setup

## Prerequisites

### Required Tools
- Flutter SDK 3.x (Stable channel)
- Dart 3.x
- Firebase CLI (`npm install -g firebase-tools`)
- Node.js 20 LTS (Cloud Functions開発用)
- VS Code + Flutter/Dart extensions

### Firebase Project Setup
1. [Firebase Console](https://console.firebase.google.com/) でプロジェクト作成
2. Authentication有効化 (Email/Password, Google)
3. Cloud Firestore作成 (本番モード)
4. Cloud Functions有効化 (Blaze plan必要)

---

## Step 1: Flutter Project Setup (10 min)

### 1.1 Dependencies追加

`pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.13.0
  cloud_functions: ^4.5.0
  
  # Authentication
  google_sign_in: ^6.1.0
  flutter_secure_storage: ^9.0.0
  
  # State Management
  flutter_riverpod: ^2.4.0
  
  # Code Generation
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  
  # Code Generation
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
  
  # Testing
  mockito: ^5.4.0
```

### 1.2 Firebase初期化

`lib/main.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart'; // flutterfire configure生成

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Emulator接続(開発環境のみ)
  if (kDebugMode) {
    await _connectToEmulator();
  }
  
  runApp(ProviderScope(child: MyApp()));
}

Future<void> _connectToEmulator() async {
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
}
```

### 1.3 Firebase設定生成

```bash
# Firebase CLIログイン
firebase login

# Firebaseプロジェクト選択
firebase use solo-dev-quest-dev

# FlutterFire CLI設定
flutterfire configure

# 対象プラットフォーム選択: iOS, Android, Web
```

---

## Step 2: Data Models作成 (15 min)

### 2.1 User Model

`lib/features/auth/domain/models/user_model.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
    required DateTime createdAt,
    required DateTime lastActivityAt,
    required String authProvider, // 'email' or 'google'
    @Default(false) bool isDeleted,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'],
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActivityAt: (data['lastActivityAt'] as Timestamp).toDate(),
      authProvider: data['authProvider'],
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActivityAt': Timestamp.fromDate(lastActivityAt),
      'authProvider': authProvider,
      'isDeleted': isDeleted,
    };
  }
}
```

### 2.2 Code Generation実行

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Step 3: AuthRepository実装 (30 min)

`lib/features/auth/data/repositories/auth_repository.dart`:
```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/user_model.dart';
import '../../exceptions/auth_exceptions.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _functions = functions ?? FirebaseFunctions.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? getCurrentUser() => _auth.currentUser;

  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestoreにユーザープロファイル作成
      await _createUserProfile(credential.user!, 'email');

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    // Rate limit check
    await _checkRateLimit(email);

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Record success
      await _recordLoginAttempt(email, success: true);

      // Update last activity
      await _updateLastActivity(credential.user!.uid);

      return credential;
    } on FirebaseAuthException catch (e) {
      // Record failure
      await _recordLoginAttempt(email, success: false);
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Create profile if new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserProfile(userCredential.user!, 'google');
      } else {
        await _updateLastActivity(userCredential.user!.uid);
      }

      return userCredential;
    } on PlatformException catch (e) {
      throw NetworkException(
        message: 'Googleサインインは現在利用できません。メール/パスワード認証をご利用ください',
      );
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Private helpers

  Future<void> _checkRateLimit(String email) async {
    try {
      final callable = _functions.httpsCallable('checkLoginRateLimit');
      await callable.call({'email': email});
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'permission-denied') {
        throw RateLimitException(
          message: e.message ?? '15分後に再試行してください',
          remainingMinutes: e.details?['remainingMinutes'],
        );
      }
    }
  }

  Future<void> _recordLoginAttempt(String email, {required bool success}) async {
    await _functions.httpsCallable('recordLoginAttempt').call({
      'email': email,
      'success': success,
    });
  }

  Future<void> _createUserProfile(User user, String provider) async {
    final userModel = UserModel(
      uid: user.uid,
      email: user.email!,
      displayName: user.displayName,
      photoURL: user.photoURL,
      createdAt: DateTime.now(),
      lastActivityAt: DateTime.now(),
      authProvider: provider,
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userModel.toFirestore());
  }

  Future<void> _updateLastActivity(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastActivityAt': FieldValue.serverTimestamp(),
    });
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return Exception('このメールアドレスは既に使用されています');
      case 'invalid-email':
        return Exception('有効なメールアドレスを入力してください');
      case 'weak-password':
        return Exception('パスワードは8文字以上で入力してください');
      case 'user-not-found':
      case 'wrong-password':
        return Exception('メールアドレスまたはパスワードが正しくありません');
      default:
        return Exception('認証エラーが発生しました');
    }
  }
}
```

---

## Step 4: Riverpod Providers設定 (10 min)

`lib/features/auth/presentation/providers/auth_provider.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});
```

---

## Step 5: Cloud Functions実装 (30 min)

### 5.1 Functions初期化

```bash
cd functions
npm install
```

### 5.2 Rate Limit Functions実装

`functions/src/index.ts`:
```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const checkLoginRateLimit = functions
  .region('asia-northeast1')
  .https.onCall(async (data, context) => {
    const { email } = data;

    if (!email) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'メールアドレスが必要です'
      );
    }

    const lockRef = admin.firestore().collection('login_locks').doc(email);
    const lockDoc = await lockRef.get();

    if (!lockDoc.exists) {
      return { allowed: true };
    }

    const lockData = lockDoc.data()!;
    const now = new Date();

    if (lockData.lockedUntil && lockData.lockedUntil.toDate() > now) {
      const remainingMs = lockData.lockedUntil.toDate().getTime() - now.getTime();
      const remainingMinutes = Math.ceil(remainingMs / 60000);

      throw new functions.https.HttpsError(
        'permission-denied',
        'セキュリティ上の理由により一時的にログインできません。15分後に再試行してください',
        { remainingMinutes }
      );
    }

    if (lockData.failedAttempts >= 5) {
      const lockedUntil = new Date(now.getTime() + 15 * 60 * 1000);

      await lockRef.update({
        lockedUntil: admin.firestore.Timestamp.fromDate(lockedUntil),
      });

      throw new functions.https.HttpsError(
        'permission-denied',
        'ログイン試行回数が上限に達しました。15分後に再試行してください',
        { remainingMinutes: 15 }
      );
    }

    return { allowed: true };
  });

export const recordLoginAttempt = functions
  .region('asia-northeast1')
  .https.onCall(async (data, context) => {
    const { email, success } = data;

    if (!email || typeof success !== 'boolean') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        '不正なパラメータです'
      );
    }

    const lockRef = admin.firestore().collection('login_locks').doc(email);

    if (success) {
      await lockRef.delete();
      return { recorded: true };
    } else {
      const lockDoc = await lockRef.get();
      const currentAttempts = lockDoc.exists
        ? (lockDoc.data()?.failedAttempts || 0)
        : 0;

      await lockRef.set(
        {
          failedAttempts: currentAttempts + 1,
          lastAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      return { recorded: true, failedAttempts: currentAttempts + 1 };
    }
  });
```

### 5.3 Functions Deploy

```bash
npm run build
firebase deploy --only functions
```

---

## Step 6: UI実装 (45 min)

### 6.1 ログイン画面

`lib/features/auth/presentation/screens/login_screen.dart`:
```dart
class LoginScreen extends ConsumerStatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).signInWithEmailPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
      // Navigate to home
    } on RateLimitException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('ログインに失敗しました');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final credential = await ref.read(authRepositoryProvider).signInWithGoogle();
      if (credential != null) {
        // Navigate to home
      }
    } catch (e) {
      _showError('Googleサインインに失敗しました');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'メールアドレス'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'パスワード'),
              obscureText: true,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              child: Text('ログイン'),
            ),
            SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _signInWithGoogle,
              icon: Icon(Icons.g_mobiledata),
              label: Text('Googleでログイン'),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
```

---

## Step 7: Testing (30 min)

### 7.1 Firebase Emulator起動

```bash
firebase emulators:start
```

### 7.2 Integration Test実行

```bash
flutter test integration_test/auth_flow_test.dart
```

---

## Next Steps

- [ ] パスワードリセット画面実装
- [ ] 新規登録画面実装
- [ ] エラーハンドリング改善
- [ ] flutter_secure_storageでトークン永続化
- [ ] セッション有効期限チェック実装
- [ ] Firestore Security Rules設定
- [ ] 本番Firebaseデプロイ

---

## Troubleshooting

### Emulator接続エラー
```bash
# Emulator再起動
firebase emulators:start --export-on-exit --import=./emulator-data
```

### Google Sign-In失敗
- Firebase ConsoleでSHA-1フィンガープリント登録確認
- `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) 最新版確認

### Functions Deploy失敗
```bash
# Node.jsバージョン確認
node --version  # 20 LTS必要

# Firebase CLI更新
npm install -g firebase-tools@latest
```
