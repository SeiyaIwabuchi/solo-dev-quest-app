# Flutter Authentication API Contract

**Feature**: 001-user-auth  
**Date**: 2025-11-01  
**Type**: Flutter Dart API (AuthRepository)

## Overview

FlutterアプリケーションでのFirebase Authentication操作を抽象化したリポジトリインターフェース。

---

## AuthRepository Interface

### Methods

#### 1. registerWithEmailPassword

メールアドレスとパスワードで新規ユーザー登録。

```dart
Future<UserCredential> registerWithEmailPassword({
  required String email,
  required String password,
});
```

**Parameters**:
- `email`: ユーザーメールアドレス
- `password`: パスワード(8文字以上)

**Returns**: `UserCredential` (Firebase Auth)

**Throws**:
- `FirebaseAuthException`:
  - `email-already-in-use`: メールアドレス既存
  - `invalid-email`: 無効なメール形式
  - `weak-password`: パスワードが弱い(8文字未満)
- `NetworkException`: ネットワークエラー

**Example**:
```dart
try {
  final credential = await authRepository.registerWithEmailPassword(
    email: 'user@example.com',
    password: 'password123',
  );
  print('登録成功: ${credential.user?.uid}');
} on FirebaseAuthException catch (e) {
  if (e.code == 'email-already-in-use') {
    print('このメールアドレスは既に使用されています');
  }
}
```

---

#### 2. signInWithEmailPassword

メールアドレスとパスワードでログイン。

```dart
Future<UserCredential> signInWithEmailPassword({
  required String email,
  required String password,
});
```

**Parameters**:
- `email`: ユーザーメールアドレス
- `password`: パスワード

**Returns**: `UserCredential` (Firebase Auth)

**Throws**:
- `FirebaseAuthException`:
  - `user-not-found`: ユーザー存在しない
  - `wrong-password`: パスワード不一致
  - `invalid-email`: 無効なメール形式
  - `user-disabled`: アカウント無効化済み
- `RateLimitException`: ログイン試行回数上限(5回失敗)
- `NetworkException`: ネットワークエラー

**Example**:
```dart
try {
  final credential = await authRepository.signInWithEmailPassword(
    email: 'user@example.com',
    password: 'password123',
  );
  print('ログイン成功');
} on RateLimitException catch (e) {
  print('15分後に再試行してください');
} on FirebaseAuthException catch (e) {
  if (e.code == 'wrong-password') {
    print('メールアドレスまたはパスワードが正しくありません');
  }
}
```

---

#### 3. signInWithGoogle

Googleアカウントでサインイン。

```dart
Future<UserCredential?> signInWithGoogle();
```

**Returns**: 
- `UserCredential?`: ログイン成功時
- `null`: ユーザーがキャンセル

**Throws**:
- `PlatformException`: Googleサービス障害
- `NetworkException`: ネットワークエラー

**Example**:
```dart
try {
  final credential = await authRepository.signInWithGoogle();
  if (credential != null) {
    print('Googleサインイン成功');
  } else {
    print('ユーザーがキャンセルしました');
  }
} on PlatformException catch (e) {
  if (e.code == 'sign_in_failed') {
    print('Googleサインインは現在利用できません');
  }
}
```

---

#### 4. sendPasswordResetEmail

パスワードリセットメール送信。

```dart
Future<void> sendPasswordResetEmail({
  required String email,
});
```

**Parameters**:
- `email`: 登録済みメールアドレス

**Throws**:
- `FirebaseAuthException`:
  - `user-not-found`: ユーザー存在しない
  - `invalid-email`: 無効なメール形式
- `NetworkException`: ネットワークエラー

**Example**:
```dart
try {
  await authRepository.sendPasswordResetEmail(
    email: 'user@example.com',
  );
  print('パスワードリセットメールを送信しました');
} on FirebaseAuthException catch (e) {
  if (e.code == 'user-not-found') {
    print('このメールアドレスは登録されていません');
  }
}
```

---

#### 5. signOut

ログアウト。

```dart
Future<void> signOut();
```

**Throws**:
- `Exception`: ログアウト失敗(稀)

**Example**:
```dart
await authRepository.signOut();
print('ログアウトしました');
```

---

#### 6. getCurrentUser

現在のログインユーザーを取得。

```dart
User? getCurrentUser();
```

**Returns**: 
- `User?`: ログイン中のユーザー
- `null`: ログアウト状態

**Example**:
```dart
final user = authRepository.getCurrentUser();
if (user != null) {
  print('ログイン中: ${user.email}');
} else {
  print('未ログイン');
}
```

---

#### 7. authStateChanges

認証状態変更のStream。

```dart
Stream<User?> authStateChanges();
```

**Returns**: `Stream<User?>` - 認証状態変更時にemit

**Example**:
```dart
authRepository.authStateChanges().listen((user) {
  if (user != null) {
    print('ログイン: ${user.email}');
  } else {
    print('ログアウト');
  }
});
```

---

## Custom Exceptions

### RateLimitException

ログイン試行回数上限エラー。

```dart
class RateLimitException implements Exception {
  final String message;
  final DateTime? lockedUntil;
  final int? remainingMinutes;

  RateLimitException({
    required this.message,
    this.lockedUntil,
    this.remainingMinutes,
  });

  @override
  String toString() => message;
}
```

**Example**:
```dart
throw RateLimitException(
  message: '15分後に再試行してください',
  lockedUntil: DateTime.now().add(Duration(minutes: 15)),
  remainingMinutes: 15,
);
```

---

### NetworkException

ネットワークエラー。

```dart
class NetworkException implements Exception {
  final String message;
  final bool isRetryable;

  NetworkException({
    required this.message,
    this.isRetryable = true,
  });

  @override
  String toString() => message;
}
```

**Example**:
```dart
throw NetworkException(
  message: 'ネットワーク接続を確認してください',
  isRetryable: true,
);
```

---

## Implementation

### AuthRepository (Concrete Class)

```dart
class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFunctions _functions;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFunctions? functions,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _functions = functions ?? FirebaseFunctions.instance;

  // Methods implementation...
  
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    // 1. Rate limit check
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

    // 2. Sign in
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Record success
      await _functions.httpsCallable('recordLoginAttempt').call({
        'email': email,
        'success': true,
      });

      return credential;
    } on FirebaseAuthException catch (e) {
      // 4. Record failure
      await _functions.httpsCallable('recordLoginAttempt').call({
        'email': email,
        'success': false,
      });

      rethrow;
    }
  }
}
```

---

## Riverpod Providers

```dart
// providers/auth_provider.dart

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

## Testing

### Mock AuthRepository

```dart
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthRepository', () {
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
    });

    test('signInWithEmailPassword success', () async {
      // Arrange
      final mockCredential = MockUserCredential();
      when(mockAuthRepository.signInWithEmailPassword(
        email: 'test@example.com',
        password: 'password123',
      )).thenAnswer((_) async => mockCredential);

      // Act
      final result = await mockAuthRepository.signInWithEmailPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      // Assert
      expect(result, mockCredential);
      verify(mockAuthRepository.signInWithEmailPassword(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);
    });

    test('signInWithEmailPassword throws RateLimitException', () async {
      // Arrange
      when(mockAuthRepository.signInWithEmailPassword(
        email: any,
        password: any,
      )).thenThrow(RateLimitException(
        message: '15分後に再試行してください',
      ));

      // Act & Assert
      expect(
        () => mockAuthRepository.signInWithEmailPassword(
          email: 'test@example.com',
          password: 'password123',
        ),
        throwsA(isA<RateLimitException>()),
      );
    });
  });
}
```
