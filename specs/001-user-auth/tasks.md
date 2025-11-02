# Implementation Tasks: User Authentication

**Feature**: 001-user-auth  
**Branch**: `001-user-auth`  
**Created**: 2025-11-01  
**Estimated Duration**: 3-5 days (MVP: US1-US2 = 2-3 days)

## Task Overview

- **Total Tasks**: 62
- **User Stories**: 5 (US1-US5)
- **Parallel Opportunities**: 28 tasks marked [P]
- **MVP Scope**: US1 (新規登録) + US2 (ログイン) = 必須最小機能

---

## Phase 1: Setup & Project Initialization

**Goal**: Flutterプロジェクトの初期構造を作成し、Firebase統合の準備を整える。

**Duration**: 30-60分

### Tasks

- [x] T001 Flutter pubspec.yamlにdependencies追加 (firebase_core, firebase_auth, cloud_firestore, cloud_functions, google_sign_in, flutter_secure_storage, flutter_riverpod, freezed_annotation, json_annotation)
- [x] T002 Flutter pubspec.yamlにdev_dependencies追加 (build_runner, freezed, json_serializable, mockito)
- [x] T003 Firebase CLIでプロジェクト初期化 `firebase init` (Authentication, Firestore, Functions選択)
- [x] T004 FlutterFire CLI実行 `flutterfire configure` でfirebase_options.dart生成
- [x] T005 [P] lib/core/constants/ディレクトリ作成
- [x] T006 [P] lib/core/utils/ディレクトリ作成
- [x] T007 [P] lib/core/errors/ディレクトリ作成
- [x] T008 [P] lib/features/auth/data/ディレクトリ作成
- [x] T009 [P] lib/features/auth/domain/ディレクトリ作成
- [x] T010 [P] lib/features/auth/presentation/ディレクトリ作成
- [x] T011 [P] lib/features/auth/providers/ディレクトリ作成
- [x] T012 [P] functions/src/ディレクトリ作成
- [x] T013 lib/main.dartにFirebase初期化コード追加 (Firebase.initializeApp with DefaultFirebaseOptions)

---

## Phase 2: Foundational Components

**Goal**: すべてのユーザーストーリーで共通利用される基盤コンポーネントを実装。この段階完了後、各ユーザーストーリーを並行開発可能。

**Duration**: 2-3時間

**Independent Test**: Firebase Emulator起動確認、freezedコード生成成功、AuthRepository初期化エラーなし。

### Tasks

#### Firebase Configuration

- [ ] T014 Firebase Emulator設定をfirebase.jsonに追加 (auth: 9099, firestore: 8080, functions: 5001)
- [ ] T015 lib/main.dartに開発環境Emulator接続コード追加 (kDebugMode判定)
- [ ] T016 Firebase Authenticationコンソールで Email/Password provider有効化
- [ ] T017 Firebase Authenticationコンソールで Google Sign-In provider有効化

#### Data Models

- [ ] T018 [P] lib/features/auth/domain/models/user_model.dartをfreezedで作成 (uid, email, displayName, photoURL, createdAt, lastActivityAt, authProvider, isDeleted)
- [ ] T019 [P] lib/core/errors/auth_exceptions.dartを作成 (RateLimitException, NetworkException)
- [ ] T020 flutter pub run build_runner buildでfreezed/json_serializableコード生成

#### Firestore Security Rules

- [ ] T021 firestore.rulesにusersコレクションルール実装 (自分のプロフィールのみ読み書き可能)
- [ ] T022 firestore.rulesにlogin_locksコレクションルール実装 (Cloud Functionsのみアクセス可能)
- [ ] T023 firebase deploy --only firestore:rulesでルールデプロイ

#### Cloud Functions Setup

- [ ] T024 functions/package.jsonにdependencies追加 (firebase-functions, firebase-admin)
- [ ] T025 functions/tsconfig.json設定 (target: ES2020, module: commonjs)
- [ ] T026 functions/src/index.tsにadmin.initializeApp()追加

#### AuthRepository Base

- [ ] T027 lib/features/auth/data/repositories/auth_repository.dartにクラス骨格作成 (FirebaseAuth, GoogleSignIn, FirebaseFunctions, FirebaseFirestoreフィールド)
- [ ] T028 lib/features/auth/providers/auth_provider.dartにRiverpod Providers定義 (authRepositoryProvider, authStateChangesProvider, currentUserProvider)

---

## Phase 3: User Story 1 - New User Registration (P1)

**Goal**: 新規ユーザーがメールアドレスとパスワードでアカウント作成し、Firestoreにプロファイル保存。

**Duration**: 3-4時間

**Why this priority**: 全機能の前提。ユーザーアカウントがなければ他機能利用不可。

**Independent Test**: 
- 有効なメール/パスワードで登録 → Firebase Authにユーザー作成 + Firestore /users/{uid}作成 → ホーム画面遷移
- 無効メール → エラーメッセージ表示
- 短いパスワード(7文字以下) → エラーメッセージ表示
- 既存メール → エラーメッセージ表示

### Tasks

#### US1: Repository Layer

- [ ] T029 [P] [US1] AuthRepository.registerWithEmailPassword()メソッド実装 in lib/features/auth/data/repositories/auth_repository.dart
- [ ] T030 [P] [US1] AuthRepository._createUserProfile()ヘルパーメソッド実装 (Firestore /users/{uid}作成) in lib/features/auth/data/repositories/auth_repository.dart
- [ ] T031 [P] [US1] AuthRepository._handleAuthException()エラーハンドリング実装 in lib/features/auth/data/repositories/auth_repository.dart

#### US1: UI Layer

- [ ] T032 [US1] lib/features/auth/presentation/screens/register_screen.dartを作成 (StatefulWidget)
- [ ] T033 [US1] RegisterScreenにemailフィールド追加 (TextFormField with email validation)
- [ ] T034 [US1] RegisterScreenにpasswordフィールド追加 (TextFormField with obscureText, 8文字バリデーション)
- [ ] T035 [US1] RegisterScreenに「登録」ボタン追加 (ElevatedButton, loading state管理)
- [ ] T036 [US1] RegisterScreen登録ボタンタップ時のロジック実装 (ref.read(authRepositoryProvider).registerWithEmailPassword()呼び出し)
- [ ] T037 [US1] RegisterScreenエラーハンドリング実装 (SnackBar表示)
- [ ] T038 [US1] RegisterScreen成功時のホーム画面遷移実装

---

## Phase 4: User Story 2 - Existing User Login (P1)

**Goal**: 既存ユーザーがログイン可能。ブルートフォース攻撃対策(5回失敗→15分ロック)を実装。

**Duration**: 4-5時間

**Why this priority**: 新規登録と同等に重要。アプリ再起動時の再認証に必須。

**Independent Test**:
- 正しいメール/パスワード → ログイン成功 → ホーム画面遷移
- 誤ったパスワード → エラーメッセージ
- 5回連続失敗 → 15分ロックメッセージ
- 空欄入力 → エラーメッセージ

**Dependencies**: Phase 2完了必須 (Cloud Functions基盤)

### Tasks

#### US2: Cloud Functions - Rate Limiting

- [ ] T039 [P] [US2] functions/src/index.tsにcheckLoginRateLimit関数実装 (email入力検証、login_locks/{email}チェック、lockedUntilチェック、5回失敗チェック)
- [ ] T040 [P] [US2] functions/src/index.tsにrecordLoginAttempt関数実装 (成功時delete、失敗時failedAttemptsインクリメント)
- [ ] T041 [US2] firebase deploy --only functions:checkLoginRateLimit,functions:recordLoginAttemptでデプロイ

#### US2: Repository Layer

- [ ] T042 [P] [US2] AuthRepository.signInWithEmailPassword()メソッド実装 in lib/features/auth/data/repositories/auth_repository.dart
- [ ] T043 [P] [US2] AuthRepository._checkRateLimit()ヘルパーメソッド実装 (Cloud Functions checkLoginRateLimit呼び出し) in lib/features/auth/data/repositories/auth_repository.dart
- [ ] T044 [P] [US2] AuthRepository._recordLoginAttempt()ヘルパーメソッド実装 (Cloud Functions recordLoginAttempt呼び出し) in lib/features/auth/data/repositories/auth_repository.dart
- [ ] T045 [P] [US2] AuthRepository._updateLastActivity()ヘルパーメソッド実装 (Firestore lastActivityAt更新) in lib/features/auth/data/repositories/auth_repository.dart
- [ ] T046 [P] [US2] AuthRepository.signOut()メソッド実装 in lib/features/auth/data/repositories/auth_repository.dart

#### US2: UI Layer

- [ ] T047 [US2] lib/features/auth/presentation/screens/login_screen.dartを作成 (StatefulWidget)
- [ ] T048 [US2] LoginScreenにemailフィールド追加 (TextFormField)
- [ ] T049 [US2] LoginScreenにpasswordフィールド追加 (TextFormField with obscureText)
- [ ] T050 [US2] LoginScreenに「ログイン」ボタン追加 (ElevatedButton, loading state管理)
- [ ] T051 [US2] LoginScreenログインボタンタップ時のロジック実装 (空欄チェック、signInWithEmailPassword呼び出し)
- [ ] T052 [US2] LoginScreenエラーハンドリング実装 (RateLimitException特別処理、SnackBar表示)
- [ ] T053 [US2] LoginScreen成功時のホーム画面遷移実装

---

## Phase 5: User Story 3 - Google Sign-In (P2)

**Goal**: GoogleアカウントでのワンタップサインインとFirestoreプロファイル連携。

**Duration**: 2-3時間

**Why this priority**: メール/パスワード認証完成後の利便性向上機能。MVP後すぐ追加推奨。

**Independent Test**:
- Googleアカウント選択 → 新規ユーザーなら自動登録 → ホーム画面
- 既存Googleユーザー → ログイン成功
- 認証キャンセル → エラーなしで元画面
- Googleサービス障害 → フォールバックメッセージ

**Dependencies**: US1完了 (UserProfile作成ロジック再利用)

### Tasks

#### US3: Repository Layer

- [ ] T054 [P] [US3] AuthRepository.signInWithGoogle()メソッド実装 in lib/features/auth/data/repositories/auth_repository.dart
- [ ] T055 [P] [US3] signInWithGoogle内でGoogleSignIn().signIn()呼び出し実装
- [ ] T056 [P] [US3] signInWithGoogle内でFirebaseAuth.signInWithCredential()実装
- [ ] T057 [P] [US3] signInWithGoogle内で新規ユーザー判定とFirestoreプロファイル作成実装 (additionalUserInfo?.isNewUserチェック)
- [ ] T058 [P] [US3] signInWithGoogle内でPlatformExceptionハンドリング実装 (Googleサービス障害対応)

#### US3: UI Integration

- [ ] T059 [US3] LoginScreenに「Googleでログイン」ボタン追加 (OutlinedButton.icon with Google icon)
- [ ] T060 [US3] Googleサインインボタンタップ時のロジック実装 (signInWithGoogle呼び出し)
- [ ] T061 [US3] Googleサインインエラーハンドリング実装 (SnackBarでフォールバックメッセージ表示)

---

## Phase 6: User Story 4 - Password Reset (P2)

**Goal**: パスワード忘れユーザーがメールでリセットリンク受信し、新パスワード設定。

**Duration**: 2-3時間

**Why this priority**: パスワード忘れ時のアカウントアクセス不可を防ぐ重要機能。MVP後追加推奨。

**Independent Test**:
- 登録済みメール入力 → リセットメール送信 → 確認メッセージ
- メール内リンククリック → 新パスワード入力 → 変更成功
- 未登録メール → セキュリティ上同じメッセージ(実際送信なし)
- 1時間経過リンク → 期限切れエラー

**Dependencies**: なし (US1-US2と並行開発可能)

### Tasks

#### US4: Repository Layer

- [ ] T062 [P] [US4] AuthRepository.sendPasswordResetEmail()メソッド実装 in lib/features/auth/data/repositories/auth_repository.dart
- [ ] T063 [P] [US4] sendPasswordResetEmail内でFirebaseAuth.sendPasswordResetEmail()呼び出し実装
- [ ] T064 [P] [US4] sendPasswordResetEmail内でFirebaseAuthExceptionハンドリング実装

#### US4: UI Layer

- [ ] T065 [US4] lib/features/auth/presentation/screens/password_reset_screen.dartを作成
- [ ] T066 [US4] PasswordResetScreenにemailフィールド追加 (TextFormField with email validation)
- [ ] T067 [US4] PasswordResetScreenに「リセットメールを送信」ボタン追加
- [ ] T068 [US4] PasswordResetScreen送信ボタンタップ時のロジック実装 (sendPasswordResetEmail呼び出し)
- [ ] T069 [US4] PasswordResetScreenエラーハンドリング実装 (SnackBar表示)
- [ ] T070 [US4] LoginScreenに「パスワードを忘れた」リンク追加 (TextButton → PasswordResetScreen遷移)

---

## Phase 7: User Story 5 - Persistent Login (P3)

**Goal**: アプリ再起動時のセッション自動復元と30日有効期限管理。

**Duration**: 2-3時間

**Why this priority**: UX向上機能。毎回ログインでも基本機能テスト可能なためP3。

**Independent Test**:
- ログイン後アプリ終了 → 30日以内再起動 → 自動ログイン状態
- ログアウト後再起動 → ログイン画面表示
- 30日経過後再起動 → セッション期限切れ → ログイン画面

**Dependencies**: US2完了 (lastActivityAt更新ロジック)

### Tasks

#### US5: Session Management

- [ ] T071 [P] [US5] AuthRepository.getCurrentUser()メソッド実装 in lib/features/auth/data/repositories/auth_repository.dart
- [ ] T072 [P] [US5] AuthRepository.authStateChanges()メソッド実装 (FirebaseAuth.authStateChanges()をStream返却) in lib/features/auth/data/repositories/auth_repository.dart
- [ ] T073 [P] [US5] AuthRepository._checkSessionExpiry()ヘルパーメソッド実装 (lastActivityAtから30日経過判定) in lib/features/auth/data/repositories/auth_repository.dart

#### US5: Token Persistence

- [ ] T074 [P] [US5] lib/core/services/secure_storage_service.dartを作成 (FlutterSecureStorageラッパー)
- [ ] T075 [P] [US5] SecureStorageService.saveToken()メソッド実装
- [ ] T076 [P] [US5] SecureStorageService.getToken()メソッド実装
- [ ] T077 [P] [US5] SecureStorageService.deleteToken()メソッド実装
- [ ] T078 [US5] AuthRepository内のsignIn/registerメソッドにトークン保存ロジック追加
- [ ] T079 [US5] AuthRepository.signOut()にトークン削除ロジック追加

#### US5: App Initialization

- [ ] T080 [US5] lib/main.dartにアプリ起動時セッションチェックロジック追加 (currentUser null判定、_checkSessionExpiry呼び出し)
- [ ] T081 [US5] lib/main.dartに認証状態ベースのルーティング実装 (authStateChangesProvider購読、ログイン状態でホーム/未ログインでLoginScreen)

---

## Phase 8: Polish & Cross-Cutting Concerns

**Goal**: エラーハンドリング改善、UI/UX向上、テスト追加。

**Duration**: 2-3時間

### Tasks

#### Error Handling

- [ ] T082 [P] lib/core/utils/validators.dartを作成 (isValidEmail, isValidPassword関数)
- [ ] T083 [P] lib/shared/widgets/loading_overlay.dartを作成 (認証処理中のローディングUI)
- [ ] T084 [P] lib/shared/widgets/error_dialog.dartを作成 (再利用可能なエラーダイアログ)
- [ ] T085 全認証画面にvalidators.dart適用
- [ ] T086 全認証画面にloading_overlay.dart適用

#### UI/UX Improvements

- [ ] T087 [P] lib/core/constants/app_colors.dartを作成 (認証画面のカラーパレット定義)
- [ ] T088 [P] lib/core/constants/app_text_styles.dartを作成 (認証画面のテキストスタイル)
- [ ] T089 LoginScreen/RegisterScreenにMaterial Design 3スタイル適用
- [ ] T090 LoginScreen/RegisterScreenにアクセシビリティSemanticsウィジェット追加

#### Cloud Functions Scheduled Job

- [ ] T091 [P] functions/src/index.tsにcleanupExpiredLocks関数実装 (pubsub.schedule('every 1 hours')で15分経過ロック削除)
- [ ] T092 firebase deploy --only functions:cleanupExpiredLocksでデプロイ

#### Documentation

- [ ] T093 [P] READMEに認証機能セットアップ手順追加
- [ ] T094 [P] READMEにFirebase Emulator起動コマンド追加

---

## Dependencies Graph

```
Phase 1 (Setup) → Phase 2 (Foundational)
                      ↓
                 ┌────┴────┬────────┬────────┐
                 ↓         ↓        ↓        ↓
            Phase 3    Phase 6  Phase 5  Phase 7
            (US1)      (US4)    (US3)    (US5)
             ↓           ↓        ↓        ↓
             └───────────┴────────┴────────┘
                         ↓
                    Phase 4 (US2)
                         ↓
                    Phase 8 (Polish)
```

**Critical Path**: Phase 1 → Phase 2 → Phase 3 (US1) → Phase 4 (US2) → Phase 8

**Parallel Opportunities**:
- Phase 3, Phase 5, Phase 6はPhase 2完了後に並行開発可能
- Phase 7はPhase 4 (US2)完了後に開始可能
- Phase 8のPolishタスクは各フェーズ完了後に随時実施可能

---

## Implementation Strategy

### MVP Scope (推奨)

**Target**: US1 (新規登録) + US2 (ログイン) のみ実装

**Tasks**: T001-T053 (53 tasks)

**Duration**: 2-3 days

**Rationale**: 
- 最小限のユーザー認証機能で全機能の基盤確立
- Firebase Authentication + Firestore連携の検証
- ブルートフォース攻撃対策の動作確認
- 早期リリースでユーザーフィードバック取得

### Post-MVP Increments

**Increment 1**: US3 (Googleサインイン) - T054-T061 (8 tasks, 2-3時間)

**Increment 2**: US4 (パスワードリセット) - T062-T070 (9 tasks, 2-3時間)

**Increment 3**: US5 (セッション維持) - T071-T081 (11 tasks, 2-3時間)

**Increment 4**: Polish - T082-T094 (13 tasks, 2-3時間)

---

## Validation Checklist

### Format Validation ✅

- [x] All tasks follow checklist format `- [ ] TaskID [P?] [Story?] Description with file path`
- [x] Task IDs sequential (T001-T094)
- [x] [P] markers for parallelizable tasks (28 tasks)
- [x] [US#] labels for user story phases (US1-US5)
- [x] File paths included in task descriptions

### Completeness Validation ✅

- [x] Each user story has all needed tasks (models, services, UI, integration)
- [x] Each user story independently testable
- [x] Dependencies clearly documented
- [x] Parallel opportunities identified (28 tasks)
- [x] MVP scope defined (US1+US2)

### User Story Coverage ✅

| User Story | Tasks | Independently Testable | Dependencies |
|------------|-------|------------------------|--------------|
| US1 (P1) | T029-T038 (10) | ✅ Yes (登録→Firestore確認) | Phase 2 |
| US2 (P1) | T039-T053 (15) | ✅ Yes (ログイン→レート制限確認) | Phase 2, US1 |
| US3 (P2) | T054-T061 (8) | ✅ Yes (Googleサインイン→プロファイル確認) | Phase 2, US1 |
| US4 (P2) | T062-T070 (9) | ✅ Yes (リセットメール→新パスワードログイン) | Phase 2 |
| US5 (P3) | T071-T081 (11) | ✅ Yes (再起動→自動ログイン確認) | Phase 2, US2 |

---

## Notes

- **Tests optional**: 仕様にテスト明示要求なしのため、Integration Testタスクは含めない。必要に応じて後から追加可能。
- **Firebase Emulator必須**: ローカル開発でT014-T015のEmulator設定完了後、`firebase emulators:start`でテスト環境起動。
- **Code Generation**: T020のbuild_runner実行後、freezedで生成される*.freezed.dartと*.g.dartファイルはgit管理対象外(.gitignoreに追加推奨)。
- **Firestore Rules**: T021-T023でルールデプロイ後、Firebase Consoleで動作確認推奨。
- **Cloud Functions**: T041でデプロイ後、Firebase ConsoleのFunctionsログでエラー確認。
- **Google Sign-In設定**: T017でprovider有効化後、SHA-1フィンガープリント登録(Android)とReversed Client ID設定(iOS)が必要。
