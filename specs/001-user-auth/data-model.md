# Data Model: User Authentication

**Feature**: 001-user-auth  
**Date**: 2025-11-01  
**Status**: Phase 1 Design

## Overview

認証機能で使用するデータモデル定義。Firebase Authentication(ユーザー認証情報)、Cloud Firestore(ユーザープロファイル・メタデータ)、OS Secure Storage(認証トークン)の3層構造。

---

## Entity 1: User (Firebase Authentication)

Firebase Authenticationが管理する認証ユーザー。

### Fields

| Field | Type | Required | Description | Validation |
|-------|------|----------|-------------|------------|
| uid | String | Yes | Firebase自動生成のユーザー一意ID | Firebase管理 |
| email | String | Yes | ユーザーメールアドレス | RFC 5322形式 |
| emailVerified | Boolean | Yes | メールアドレス確認済みフラグ | Phase 0ではfalse固定 |
| displayName | String? | No | Googleサインイン時の表示名 | 最大256文字 |
| photoURL | String? | No | Googleサインイン時のプロフィール画像URL | 有効なURL形式 |
| createdAt | DateTime | Yes | アカウント作成日時 | Firebase管理 |
| lastSignInAt | DateTime | Yes | 最終ログイン日時 | Firebase管理 |
| providerData | List | Yes | 認証プロバイダー情報(email/google) | Firebase管理 |

### Relationships
- 1対1: UserProfile (Firestore)

### State Transitions
```
[未登録] --register()--> [認証済み]
[認証済み] --signOut()--> [未認証]
[未認証] --signIn()--> [認証済み]
[認証済み] --deleteAccount()--> [削除済み] (Phase 0では未実装)
```

### Notes
- Firebase Authenticationが自動管理
- Flutter側では`FirebaseAuth.instance.currentUser`でアクセス
- パスワードはFirebase側でハッシュ化され、クライアント側でアクセス不可

---

## Entity 2: UserProfile (Cloud Firestore)

ユーザーのプロファイルとメタデータ。Firebase Authenticationと1対1対応。

### Firestore Path
```
/users/{uid}
```

### Fields

| Field | Type | Required | Description | Validation |
|-------|------|----------|-------------|------------|
| uid | String | Yes | Firebase AuthのUID(ドキュメントID) | Firebase Auth連携 |
| email | String | Yes | メールアドレス(Firebase Authと同期) | RFC 5322形式 |
| displayName | String? | No | 表示名 | 最大50文字 |
| photoURL | String? | No | プロフィール画像URL | 有効なURL形式 |
| createdAt | Timestamp | Yes | アカウント作成日時 | Firestore serverTimestamp() |
| lastActivityAt | Timestamp | Yes | 最終アクティビティ日時(セッション管理用) | Firestore serverTimestamp() |
| authProvider | String | Yes | 認証プロバイダー("email" or "google") | enum値 |
| isDeleted | Boolean | No | 削除フラグ(論理削除用) | デフォルトfalse |

### Indexes
```
Collection: users
- uid (自動)
- email (単一フィールドインデックス)
- lastActivityAt (単一フィールドインデックス、セッション有効期限チェック用)
```

### Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      // 自分のプロフィールのみ読み書き可能
      allow read: if request.auth != null && request.auth.uid == uid;
      allow create: if request.auth != null && request.auth.uid == uid;
      allow update: if request.auth != null && request.auth.uid == uid;
      allow delete: if false; // Phase 0では削除不可
    }
  }
}
```

### Relationships
- 1対1: User (Firebase Authentication)

### State Transitions
```
[存在しない] --createProfile()--> [アクティブ]
[アクティブ] --updateActivity()--> [アクティブ] (lastActivityAt更新)
[アクティブ] --30日経過--> [セッション期限切れ] (再ログイン要求)
[アクティブ] --deleteAccount()--> [削除済み] (isDeleted=true) (Phase 0では未実装)
```

### Notes
- 新規登録時にFirebase Authユーザー作成と同時に自動生成
- `lastActivityAt`は毎回のアプリ起動時・画面遷移時に更新
- 30日間`lastActivityAt`が更新されない場合、セッション期限切れとして強制ログアウト

---

## Entity 3: LoginLock (Cloud Firestore)

ブルートフォース攻撃対策のログイン試行回数管理。

### Firestore Path
```
/login_locks/{email}
```

### Fields

| Field | Type | Required | Description | Validation |
|-------|------|----------|-------------|------------|
| email | String | Yes | メールアドレス(ドキュメントID) | RFC 5322形式 |
| failedAttempts | Number | Yes | ログイン失敗回数 | 0以上の整数 |
| lastAttemptAt | Timestamp | Yes | 最終試行日時 | Firestore serverTimestamp() |
| lockedUntil | Timestamp? | No | ロック解除日時(15分後) | lastAttemptAt + 15分 |

### Indexes
```
Collection: login_locks
- email (自動、ドキュメントID)
```

### Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /login_locks/{email} {
      // Cloud Functionsからのみアクセス可能
      allow read, write: if false;
    }
  }
}
```

### State Transitions
```
[存在しない] --ログイン失敗--> [カウント1]
[カウント1-4] --ログイン失敗--> [カウント+1]
[カウント5] --ログイン失敗--> [ロック中] (lockedUntil設定)
[ロック中] --15分経過--> [カウントリセット]
[カウント1-5] --ログイン成功--> [削除]
```

### Notes
- Cloud Functionsから操作される(クライアント直接アクセス不可)
- ログイン成功時にドキュメント削除でカウントリセット
- 15分経過後は自動的にログイン許可(Cloud Functionsでチェック)

---

## Entity 4: AuthToken (OS Secure Storage)

認証トークンの永続化。Firebase AuthのトークンをOSネイティブのセキュアストレージに保存。

### Storage Location
- **iOS**: Keychain (kSecClassGenericPassword)
- **Android**: EncryptedSharedPreferences (KeyStore)

### Fields

| Key | Type | Required | Description | Validation |
|-----|------|----------|-------------|------------|
| firebase_token | String | Yes | Firebase ID Token | JWT形式 |
| refresh_token | String | Yes | Firebase Refresh Token | Firebase管理 |
| token_expiry | String | Yes | トークン有効期限 | ISO 8601形式 |

### Notes
- `flutter_secure_storage` packageでアクセス
- アプリアンインストール時に自動削除
- ログアウト時に明示的に削除(`storage.delete()`)

---

## Validation Rules Summary

### Email Validation
```dart
bool isValidEmail(String email) {
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
  );
  return emailRegex.hasMatch(email);
}
```

### Password Validation
```dart
bool isValidPassword(String password) {
  return password.length >= 8;
}
```

### Display Name Validation
```dart
bool isValidDisplayName(String? name) {
  if (name == null) return true; // Optional field
  return name.length <= 50;
}
```

---

## Data Flow

### 新規登録フロー
```
1. ユーザーがメールアドレス・パスワード入力
2. Flutter: バリデーション実行
3. Flutter: FirebaseAuth.createUserWithEmailAndPassword()
4. Firebase Auth: User作成 (uid生成)
5. Flutter: Firestoreに UserProfile ドキュメント作成
   - /users/{uid} に email, createdAt, lastActivityAt, authProvider 保存
6. Flutter: flutter_secure_storage にトークン保存
7. Flutter: ホーム画面遷移
```

### ログインフロー
```
1. ユーザーがメールアドレス・パスワード入力
2. Flutter: Cloud Functions checkLoginRateLimit() 呼び出し
3. Cloud Functions: login_locks/{email} チェック
   - lockedUntil > 現在時刻 → エラー返却
   - failedAttempts >= 5 → lockedUntil設定 → エラー返却
   - それ以外 → 許可
4. Flutter: FirebaseAuth.signInWithEmailAndPassword()
5. Firebase Auth: 認証成功/失敗
6. Flutter: Cloud Functions recordLoginAttempt() 呼び出し
   - 成功 → login_locks/{email} 削除
   - 失敗 → failedAttempts インクリメント
7. Flutter: 成功時、Firestore UserProfile.lastActivityAt 更新
8. Flutter: 成功時、flutter_secure_storage にトークン保存
9. Flutter: ホーム画面遷移
```

### Googleサインインフロー
```
1. ユーザーが「Googleでログイン」タップ
2. Flutter: GoogleSignIn().signIn()
3. Google SDK: Googleアカウント選択・認証
4. Flutter: Firebase AuthにGoogle認証情報渡す
5. Firebase Auth: User作成/既存ユーザー取得
6. Flutter: 新規ユーザーの場合、Firestore UserProfile 作成
7. Flutter: Firestore UserProfile.lastActivityAt 更新
8. Flutter: flutter_secure_storage にトークン保存
9. Flutter: ホーム画面遷移
```

### セッション復元フロー
```
1. アプリ起動
2. Flutter: FirebaseAuth.instance.currentUser チェック
3. Firebase Auth: ローカルトークン検証
4. Flutter: トークン有効 → Firestore lastActivityAt チェック
5. Flutter: 現在時刻 - lastActivityAt > 30日 → ログアウト処理
6. Flutter: 30日以内 → lastActivityAt 更新 → ホーム画面
```

---

## Migration Strategy

### Phase 0 → Phase 1
- UserProfile にDevCoinフィールド追加予定:
  - `freeDevCoin: Number` (無料DevCoin残高)
  - `paidDevCoin: Number` (有料DevCoin残高)
  - `devCoinHistory: Array` (DevCoin獲得/消費履歴)

### Phase 1 → Phase 2
- UserProfile にコミュニティ関連フィールド追加予定:
  - `reputation: Number` (評判スコア)
  - `questionsCount: Number` (質問数)
  - `answersCount: Number` (回答数)
  - `snsConnections: Map` (SNS連携情報)

### Phase 2 → Phase 3
- UserProfile にAI機能フィールド追加予定:
  - `aiCharacterPreset: String` (AI仮想クライアント設定)
  - `scoldingLevel: String` (AI説教レベル)
  - `visualizationTheme: String` (可視化テーマ選択)

---

## Notes

- すべてのタイムスタンプはUTC timezone
- Firestoreの`serverTimestamp()`を使用してサーバー時刻を記録(クライアント時刻の不正防止)
- `freezed` packageでFlutter側モデルクラスをイミュータブルに実装
- Cloud Firestore Emulatorでローカルテスト可能
