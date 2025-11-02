# Implementation Plan: User Authentication

**Branch**: `001-user-auth` | **Date**: 2025-11-01 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-user-auth/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Phase 0の認証機能として、Firebase Authenticationを使用したメール/パスワード認証とGoogleサインインを実装する。ユーザーは新規登録・ログイン・ログアウト・パスワードリセット機能を利用でき、セッション管理により30日間のログイン状態維持が可能。セキュリティ対策として、認証トークンのOSセキュアストレージ保存、ブルートフォース攻撃対策(5回失敗で15分ロック)、パスワードリセットリンク1時間有効期限を実装。Googleサインイン失敗時はメール/パスワード認証へのフォールバックを提供し、サービス継続性を確保。

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: Dart 3.x, Flutter 3.x (Stable channel)  
**Primary Dependencies**: firebase_auth, firebase_core, google_sign_in, flutter_secure_storage, riverpod  
**Storage**: Firebase Authentication (user credentials), OS Secure Storage (iOS Keychain, Android Keystore for tokens), Cloud Firestore (user profile metadata)  
**Testing**: flutter_test (unit/widget tests), integration_test (E2E authentication flows), Firebase Emulator Suite (local testing)  
**Target Platform**: iOS 15+, Android 8.0+ (API level 26+), Web (基本機能のみ)
**Project Type**: Mobile cross-platform (Flutter)  
**Performance Goals**: 新規登録30秒以内完了、既存ログイン5秒以内完了、アプリ再起動時2秒以内でセッション復元  
**Constraints**: ネットワークエラー時のリトライ機構必須、オフライン対応不要(認証は常時オンライン前提)、パスワードリセット1時間有効期限厳守  
**Scale/Scope**: Phase 0 MVP - 5つのユーザーストーリー、7画面（登録/ログイン/パスワードリセット/エラーダイアログ等）、初期ユーザー数100-1000人想定

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Phase 0 Check**: ✅ PASSED (2025-11-01)  
**Phase 1 Re-check**: ✅ PASSED (2025-11-01)

すべての憲法原則に準拠。Phase 1設計完了後も違反なし。

### Principle I: User-Centric Motivation Design
- [x] 機能がユーザーのモチベーション維持に貢献するか？
  - 認証機能自体は直接的なモチベーション維持機能ではないが、スムーズなログイン体験(Googleサインイン、セッション維持)によりアプリ利用の障壁を最小化
- [x] タスク完了時の即時フィードバックが設計されているか？
  - 登録・ログイン成功時の即座のホーム画面遷移、エラー時の明確なメッセージ表示により、ユーザーアクションへの即時フィードバックを提供
- [N/A] 「開発者が孤独を感じない」という視点で検証したか？
  - 認証機能は孤独感解消に直接寄与しないが、後続機能(コミュニティ、AI褒め等)へのゲートウェイとして機能

### Principle II: MVP-First & Phased Delivery
- [x] この機能はどのPhaseに属するか明確か？
  - Phase 0として明確に定義。すべての後続機能の前提条件
- [x] 独立して価値を提供できるか？
  - 認証機能単体では価値提供できないが、Phase 0として他機能の基盤として必須
- [x] Phase間の依存関係は最小化されているか？
  - 認証はPhase 1以降のすべての機能に依存されるが、逆依存なし。最小依存構造を実現

### Principle III: Firebase-First Architecture
- [x] Firebase Authenticationで認証を実装しているか？
  - メール/パスワード、Googleサインイン両方でFirebase Authenticationを使用
- [x] Cloud Firestoreをメインストレージとして使用しているか？
  - ユーザープロファイルメタデータはFirestoreに保存(認証トークンはOSセキュアストレージ)
- [x] カスタムバックエンドサーバーを避けているか？
  - カスタムサーバー不要。Firebase Authentication + Firestore + OS Secure Storageのみで完結

### Principle IV: AI Abstraction & Resilience
- [N/A] AI呼び出しは抽象化レイヤーを通しているか？
  - 認証機能はAI機能を使用しない
- [N/A] フォールバック機構が実装されているか？
  - Googleサインイン失敗時のメール/パスワード認証への誘導はフォールバック戦略として実装
- [N/A] AI生成コンテンツのログ記録が設計されているか？
  - AI機能不使用のためN/A

### Principle V: Legal & Compliance by Design
- [N/A] DevCoin経済システムは無料/有料を分離しているか？
  - 認証機能はDevCoin経済に直接関与しない
- [N/A] 有料DevCoinの6ヶ月有効期限を実装しているか？
  - 認証機能では課金要素なし
- [x] プライバシーポリシー・利用規約への影響を検討したか？
  - ユーザーメールアドレス収集、Googleアカウント連携に関するプライバシーポリシー記載が必要
  - 認証トークンのセキュア保存方針の明示が必要
  - パスワードリセット時のメール送信に関する利用規約記載が必要

### Principle VI: Flutter Cross-Platform Strategy
- [x] Riverpodで状態管理を実装しているか？
  - 認証状態管理にRiverpod StateNotifierProviderを使用
- [x] Material Design 3に準拠しているか？
  - ログイン・登録画面はMaterial Design 3のコンポーネント(TextField, ElevatedButton等)を使用
- [x] Widget Test + Integration Testが計画されているか？
  - Widget Test: 各認証画面UIの単体テスト
  - Integration Test: 登録→ログアウト→ログイン→パスワードリセットの全フロー

### Principle VII: Community-Driven Growth
- [N/A] コミュニティ機能はスパム対策を含んでいるか？
  - 認証機能はコミュニティ機能の前提条件だが、スパム対策自体は後続Phaseで実装
- [x] 外部API依存の実現性検証（PoC）を行ったか？
  - Firebase Authentication、Google Sign-Inは実績豊富で実現性確認済み
- [N/A] 健全なコミュニティ育成の観点で設計したか？
  - 認証機能は健全なユーザー管理の基盤として機能(1ユーザー1アカウント原則)

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
# Solo Dev Quest App: Flutter + Firebase Architecture
lib/
├── core/
│   ├── constants/          # アプリ定数、テーマ、色定義
│   ├── utils/              # ヘルパー関数、拡張メソッド
│   ├── errors/             # カスタムエラークラス
│   └── router/             # go_router設定
├── features/
│   ├── auth/               # 認証機能
│   │   ├── data/           # Firebase Auth連携
│   │   ├── domain/         # ユーザーモデル、リポジトリインターフェース
│   │   ├── presentation/   # ログイン・サインアップ画面
│   │   └── providers/      # Riverpod プロバイダー
│   ├── tasks/              # タスク管理機能
│   ├── visualization/      # 進捗可視化（マラソンランナー等）
│   ├── ai/                 # AI機能（褒め、説教、仮想クライアント）
│   ├── devcoin/            # DevCoin経済システム
│   ├── community/          # Q&A、SNS連携、タイムライン
│   └── [feature-name]/     # 新機能用ディレクトリ（この計画で追加）
└── shared/
    ├── widgets/            # 共通UIコンポーネント
    ├── models/             # 共通データモデル
    └── services/           # 共通サービス（Analytics等）

test/
├── unit/                   # 単体テスト
├── widget/                 # ウィジェットテスト
└── integration/            # 統合テスト

functions/                  # Firebase Cloud Functions
├── src/
│   ├── ai/                 # AI API呼び出し処理
│   ├── devcoin/            # DevCoin管理ロジック
│   ├── notifications/      # プッシュ通知処理
│   └── scheduled/          # スケジュールジョブ
├── package.json
└── tsconfig.json

assets/
├── images/                 # 画像アセット
├── animations/             # Lottieアニメーション
└── fonts/                  # カスタムフォント

firestore.rules             # Firestoreセキュリティルール
storage.rules               # Firebase Storageセキュリティルール
firebase.json               # Firebase設定
```

**Structure Decision**: Flutter + Firebase構成を採用。機能ごとにfeatures/配下でクリーンアーキテクチャを適用し、データ層（Firebase連携）、ドメイン層（ビジネスロジック）、プレゼンテーション層（UI）を分離。Cloud FunctionsはTypeScriptで実装し、AI APIやバックエンドロジックを担当。

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
