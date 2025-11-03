# Research: User Authentication

**Feature**: 001-user-auth  
**Date**: 2025-11-01  
**Status**: Phase 0 Complete

## Overview

Phase 0認証機能の技術調査。Firebase Authentication + Flutter Secure Storage + Riverpod構成での実装方針、セキュリティ対策、エラーハンドリング戦略を決定。

---

## R1: トークンセキュア保存(iOS Keychain / Android Keystore)

### Decision
`flutter_secure_storage` package (^9.0.0) を使用し、認証トークンをOSネイティブのセキュアストレージに保存。

### Rationale
- **iOS**: Keychainに自動保存され、デバイスパスコード/Face ID/Touch IDで保護
- **Android**: KeyStoreに自動保存され、ハードウェアバックアップの暗号化で保護
- **クロスプラットフォーム**: 単一APIでiOS/Android両対応
- **Firebase連携**: Firebase Auth SDKのトークンをflutter_secure_storageで永続化可能

### Implementation Details
```dart
// 保存
final storage = FlutterSecureStorage();
await storage.write(key: 'firebase_token', value: token);

// 読み込み
final token = await storage.read(key: 'firebase_token');

// 削除(ログアウト時)
await storage.delete(key: 'firebase_token');
```

### Alternatives Considered
- **shared_preferences**: 暗号化なしで保存されるため却下(セキュリティリスク)
- **SQLite with SQLCipher**: 過剰な複雑性。flutter_secure_storageで十分
- **Firebase Auth SDK自動管理**: トークン永続化の細かい制御ができないため、flutter_secure_storageと併用

---

## R2: Firebase Authenticationセッション管理

### Decision
Firebase Authentication SDKのデフォルトセッション管理を使用。トークン自動更新はSDKに委譲し、30日間のセッション有効期限はFirebase側で設定。

### Rationale
- **自動トークン更新**: Firebase SDKが有効期限切れ前に自動的にトークンをリフレッシュ
- **セッション永続化**: `setPersistence(Persistence.LOCAL)` でローカルストレージに保存(Webの場合)。モバイルはデフォルトで永続化
- **30日有効期限**: Firebase Consoleの「Authentication > Settings > User session duration」で設定可能
- **アクティビティ追跡**: 最終ログイン時刻をFirestoreに記録し、30日経過後は強制ログアウト

### Implementation Details
```dart
// セッション状態監視
FirebaseAuth.instance.authStateChanges().listen((User? user) {
  if (user != null) {
    // ログイン状態
    // 最終アクティビティをFirestoreに記録
    _updateLastActivity(user.uid);
  } else {
    // ログアウト状態
  }
});

// 30日経過チェック(アプリ起動時)
Future<void> _checkSessionExpiry() async {
  final lastActivity = await _getLastActivity(currentUser.uid);
  if (DateTime.now().difference(lastActivity).inDays > 30) {
    await FirebaseAuth.instance.signOut();
  }
}
```

### Alternatives Considered
- **カスタムトークン管理**: Firebase SDKの自動更新機能を使わず独自実装 → 却下(複雑性増大、バグリスク)
- **JWT手動検証**: Firebase Admin SDKで毎回トークン検証 → 却下(パフォーマンス低下)

---

## R3: Googleサインインエラーハンドリング

### Decision
`google_sign_in` package (^6.1.0) を使用。サービス障害・ネットワークエラー時はキャッチしてエラーメッセージ表示 + メール/パスワード認証への誘導UIを提供。

### Rationale
- **外部サービス依存**: Googleサービス障害時もアプリアクセス可能にするため、フォールバック必須
- **ユーザー体験**: 認証キャンセル vs サービス障害を区別し、適切なメッセージ表示
- **リトライ機構**: 一時的なネットワークエラーには「再試行」ボタンを提供

### Implementation Details
```dart
Future<UserCredential?> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    
    if (googleUser == null) {
      // ユーザーがキャンセル → エラーメッセージなし
      return null;
    }

    final GoogleSignInAuthentication googleAuth = 
        await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
    
  } on PlatformException catch (e) {
    // Googleサービス障害
    if (e.code == 'network_error' || e.code == 'sign_in_failed') {
      _showErrorDialog(
        'Googleサインインは現在利用できません。メール/パスワード認証をご利用ください'
      );
    }
    return null;
  } catch (e) {
    // その他のエラー
    _showErrorDialog('予期しないエラーが発生しました');
    return null;
  }
}
```

### Alternatives Considered
- **Googleサインインのみ提供**: メール/パスワード認証なし → 却下(外部依存リスク大)
- **カスタムOAuth実装**: google_sign_in packageを使わず独自実装 → 却下(複雑性とメンテナンスコスト)

---

## R4: ブルートフォース攻撃対策(5回失敗→15分ロック)

### Decision
Firestore Rulesではなく、**Cloud Functions for Firebase**でログイン試行回数を管理し、5回失敗でアカウント一時ロック。

### Rationale
- **クライアント側では不十分**: Flutter側でのカウントは簡単にバイパス可能
- **Firestore Rulesの限界**: Rulesではログイン試行カウントのような複雑なロジックを実装困難
- **Cloud Functions**: サーバーサイドで確実にログイン試行を記録・検証
- **15分自動解除**: Cloud Functionsでロック時刻を記録し、15分経過後は自動的にログイン許可

### Implementation Details

**Cloud Functions (TypeScript)**:
```typescript
// functions/src/auth-rate-limit.ts
export const checkLoginRateLimit = functions.https.onCall(async (data, context) => {
  const { email } = data;
  const lockRef = admin.firestore().collection('login_locks').doc(email);
  const lockDoc = await lockRef.get();

  if (lockDoc.exists) {
    const { failedAttempts, lockedUntil } = lockDoc.data();
    
    // ロック期間中か確認
    if (lockedUntil && lockedUntil.toDate() > new Date()) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'セキュリティ上の理由により一時的にログインできません。15分後に再試行してください'
      );
    }
    
    // 5回失敗でロック
    if (failedAttempts >= 5) {
      await lockRef.update({
        lockedUntil: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 15 * 60 * 1000) // 15分後
        )
      });
      throw new functions.https.HttpsError(
        'permission-denied',
        'ログイン試行回数が上限に達しました。15分後に再試行してください'
      );
    }
  }
  
  return { allowed: true };
});

export const recordLoginAttempt = functions.https.onCall(async (data, context) => {
  const { email, success } = data;
  const lockRef = admin.firestore().collection('login_locks').doc(email);

  if (success) {
    // ログイン成功 → カウントリセット
    await lockRef.delete();
  } else {
    // ログイン失敗 → カウント増加
    await lockRef.set({
      failedAttempts: admin.firestore.FieldValue.increment(1),
      lastAttempt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
  }
});
```

**Flutter側**:
```dart
Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
  // 1. レート制限チェック
  final callable = FirebaseFunctions.instance.httpsCallable('checkLoginRateLimit');
  try {
    await callable.call({'email': email});
  } catch (e) {
    // ロック中
    _showErrorDialog(e.message);
    return null;
  }

  // 2. ログイン試行
  try {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // 成功 → カウントリセット
    await FirebaseFunctions.instance.httpsCallable('recordLoginAttempt')
        .call({'email': email, 'success': true});
    
    return credential;
  } on FirebaseAuthException catch (e) {
    // 失敗 → カウント増加
    await FirebaseFunctions.instance.httpsCallable('recordLoginAttempt')
        .call({'email': email, 'success': false});
    
    throw e;
  }
}
```

### Alternatives Considered
- **Firestoreのみで実装**: Firestore Rulesだけで試行回数管理 → 却下(Rulesの複雑性とバグリスク)
- **アカウント永久ロック**: 5回失敗で管理者解除まで永久ロック → 却下(ユーザビリティ低下)
- **CAPTCHA導入**: reCAPTCHA v3で人間判定 → Phase 0では過剰、Phase 2以降で検討

---

## R5: パスワードリセットリンク1時間有効期限

### Decision
Firebase Authenticationの`sendPasswordResetEmail()`を使用。有効期限はFirebase側で1時間に設定済み(デフォルト)。

### Rationale
- **Firebase標準機能**: `sendPasswordResetEmail()` APIが1時間有効のリセットリンクを自動生成
- **カスタマイズ不要**: Firebaseのデフォルト設定(1時間)が要件を満たす
- **セキュリティ**: リンクは1回のみ使用可能(再使用不可)
- **メールテンプレート**: Firebase Consoleで日本語メールテンプレートをカスタマイズ可能

### Implementation Details
```dart
Future<void> sendPasswordResetEmail(String email) async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    _showSuccessDialog(
      'パスワードリセットメールを送信しました。メールに記載されたリンクは1時間有効です'
    );
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      _showErrorDialog('このメールアドレスは登録されていません');
    } else {
      _showErrorDialog('メール送信に失敗しました');
    }
  }
}
```

### Alternatives Considered
- **カスタムリセットトークン**: Cloud Functionsで独自トークン生成 → 却下(Firebase標準機能で十分)
- **SMSリセット**: 電話番号でのパスワードリセット → Phase 0では不要、Phase 3以降で検討

---

## R6: Riverpodでの認証状態管理

### Decision
`riverpod` (^2.4.0) + `StateNotifier`でグローバル認証状態を管理。Firebase Auth SDKの`authStateChanges()`をStreamProviderでラップ。

### Rationale
- **リアクティブ**: Firebase認証状態変更を自動的にUI反映
- **グローバルアクセス**: 全画面から`ref.watch(authStateProvider)`で認証状態取得
- **テスト容易性**: StateNotifierはモック可能でテストしやすい
- **憲法準拠**: Constitution Principle VIでRiverpod使用が義務付けられている

### Implementation Details
```dart
// providers/auth_provider.dart
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance);
});

// 認証状態に基づくルーティング
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// ログイン状態チェック
class AuthStateNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthStateNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    state = await AsyncValue.guard(() async {
      // セッション有効期限チェック
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final lastActivity = await _getLastActivity(user.uid);
        if (DateTime.now().difference(lastActivity).inDays > 30) {
          await FirebaseAuth.instance.signOut();
          return null;
        }
      }
      return user;
    });
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    state = const AsyncValue.data(null);
  }
}

final authStateNotifierProvider = 
    StateNotifierProvider<AuthStateNotifier, AsyncValue<User?>>((ref) {
  return AuthStateNotifier();
});
```

### Alternatives Considered
- **Provider (旧版)**: riverpod推奨により却下
- **Bloc**: 憲法でRiverpod使用が明記されているため却下
- **GetX**: 憲法でRiverpod使用が明記されているため却下

---

## R7: Firebase Emulator Suiteでの認証テスト

### Decision
Firebase Emulator Suite (Authentication, Firestore, Functions) をローカル開発・テストに使用。本番Firebaseを汚染せずにテスト可能。

### Rationale
- **本番分離**: 開発・テストデータが本番Firebaseに混入しない
- **オフライン開発**: インターネット接続不要でローカル開発可能
- **高速テスト**: ネットワーク遅延なしでテスト高速化
- **無料**: Emulatorは無料で使用可能(本番API課金なし)

### Implementation Details

**Firebase Emulator起動**:
```bash
# firebase.json設定
{
  "emulators": {
    "auth": {
      "port": 9099
    },
    "firestore": {
      "port": 8080
    },
    "functions": {
      "port": 5001
    },
    "ui": {
      "enabled": true,
      "port": 4000
    }
  }
}

# Emulator起動
firebase emulators:start
```

**Flutter側でEmulator接続**:
```dart
// main.dart
Future<void> _connectToEmulator() async {
  if (kDebugMode) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
  }
}
```

**Integration Test**:
```dart
// integration_test/auth_flow_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp();
    await _connectToEmulator();
  });

  testWidgets('完全な認証フロー', (tester) async {
    // 1. 新規登録
    await tester.pumpWidget(MyApp());
    await tester.tap(find.text('新規登録'));
    await tester.pumpAndSettle();
    
    await tester.enterText(find.byKey(Key('email')), 'test@example.com');
    await tester.enterText(find.byKey(Key('password')), 'password123');
    await tester.tap(find.text('登録'));
    await tester.pumpAndSettle();
    
    // ホーム画面に遷移確認
    expect(find.text('ホーム'), findsOneWidget);
    
    // 2. ログアウト
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    
    // 3. ログイン
    await tester.enterText(find.byKey(Key('email')), 'test@example.com');
    await tester.enterText(find.byKey(Key('password')), 'password123');
    await tester.tap(find.text('ログイン'));
    await tester.pumpAndSettle();
    
    expect(find.text('ホーム'), findsOneWidget);
  });
}
```

### Alternatives Considered
- **本番Firebase直接テスト**: 本番データ汚染リスクのため却下
- **モックライブラリ**: fake_cloud_firestoreなど → Emulatorの方が本番に近い挙動
- **テストアカウント分離**: 本番Firebaseにテスト用プロジェクト作成 → コスト増大のため却下

---

## Summary

Phase 0リサーチ完了。すべての技術的不明点を解決し、実装方針を決定:

1. **トークン保存**: flutter_secure_storage (iOS Keychain / Android Keystore)
2. **セッション管理**: Firebase SDK自動管理 + 30日有効期限(Firestore記録)
3. **Googleサインイン**: google_sign_in package + エラーハンドリング + フォールバックUI
4. **ブルートフォース対策**: Cloud Functions でレート制限(5回失敗→15分ロック)
5. **パスワードリセット**: Firebase標準機能(1時間有効期限)
6. **状態管理**: Riverpod StreamProvider + StateNotifier
7. **テスト環境**: Firebase Emulator Suite + Integration Test

次のステップ: Phase 1でdata-model.md、contracts/、quickstart.mdを生成。
