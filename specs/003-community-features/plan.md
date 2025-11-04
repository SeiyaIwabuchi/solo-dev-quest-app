# Implementation Plan: Phase 2 コミュニティ機能

**Branch**: `003-community-features` | **Date**: 2025-11-04 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-community-features/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Phase 2ではコミュニティ機能を実装し、個人開発者の「孤独感解消」「知識不足解決」を達成する。主要機能は以下の通り:

1. **Q&Aプラットフォーム**: 技術的質問の投稿(10 DevCoin消費)・回答投稿(5 DevCoin獲得)・ベストアンサー選択(追加15 DevCoin)
2. **ハッシュタグタイムライン**: 外部SNS(X/Threads/Instagram)の#個人開発チャレンジ投稿をアプリ内で統合表示
3. **SNSインタラクション**: アプリ内から直接いいね・リツイート・コメント
4. **検索・フィルタリング**: キーワード検索、カテゴリフィルタ、複数ソート(最新/回答数/評価順)
5. **コメント・応援機能**: 質問・回答へのコメント、テンプレート応援メッセージ
6. **プレミアムプラン**: 月額680円でAI無制限・広告なし・月200 DevCoin付与

技術的アプローチ: Cloud Firestore + 複合インデックスで質問検索を高速化、Cloud FunctionsでSNS API呼び出しとレート制限管理、トランザクション機能でDevCoin残高の整合性を保証。

## Technical Context

**Language/Version**: 
- Flutter: 3.35.7+ (Stable channel)
- Dart: 3.9.2+
- Node.js: 20 LTS (Cloud Functions)
- TypeScript: 5.x

**Primary Dependencies**: 
- Frontend: riverpod (状態管理), go_router (ルーティング), freezed (イミュータブルモデル), firebase_auth, cloud_firestore, firebase_storage, in_app_purchase, cached_network_image, sqflite
- Backend: Firebase Admin SDK, Anthropic SDK (Claude API), OpenAI SDK (フォールバック)
- SNS統合: twitter-api-v2 (X API v2), axios (Threads API REST), facebook-nodejs-business-sdk (Instagram Graph API), flutter_appauth (OAuth 2.0 PKCE)
- 課金: in_app_purchase (Flutter公式パッケージ), StoreKit 2 (iOS), Google Play Billing Library 6 (Android)

**Storage**: 
- Cloud Firestore (質問・回答・コメント・ユーザープロファイル)
- Firebase Storage (画像・動画アセット)
- ローカルキャッシュ: shared_preferences (軽量データ), sqflite (オフライン質問キャッシュ)

**Testing**: 
- flutter_test (単体テスト・ウィジェットテスト)
- integration_test (E2Eテスト)
- Firebase Emulator Suite (ローカルFirestore/Functions/Auth検証)

**Target Platform**: 
- iOS 15.0+ (iPhone/iPad)
- Android API 21+ (Android 5.0 Lollipop以降)
- Web (基本機能のみ - モバイルアプリへの誘導優先)

**Project Type**: Mobile-first (Flutter cross-platform)

**Performance Goals**: 
- 質問検索レスポンス: 2秒以内(10,000質問時)
- タイムライン初回読み込み: 3秒以内
- 画面遷移: 60fps維持(jankyフレーム5%以下)
- SNS API呼び出し: レート制限500req/時以内

**Constraints**: 
- オフライン時: 過去24時間の閲覧コンテンツをキャッシュから表示
- DevCoinトランザクション: Firestoreトランザクションで残高整合性保証(ACID)
- SNS APIレート制限到達時: 5分キャッシュデータで対応
- モデレーション: 報告から24時間以内に審査完了

**Scale/Scope**: 
- 初期想定ユーザー数: 1,000~10,000 MAU
- 質問数想定: 初年度10,000~100,000件
- 画面数: 約15画面(Q&A投稿/一覧/詳細/検索、タイムライン、プレミアムプラン購入等)
- Cloud Functions: 5~10エンドポイント(質問投稿、回答報酬付与、SNS API呼び出し、モデレーション等)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: User-Centric Motivation Design
- [x] 機能がユーザーのモチベーション維持に貢献するか? ✅ Q&Aで知識不足を解決し、タイムラインで他者の進捗を見てモチベーション維持
- [x] タスク完了時の即時フィードバックが設計されているか? ✅ 回答投稿で即座に5 DevCoin付与、ベストアンサー選択で通知+15 DevCoin付与
- [x] 「開発者が孤独を感じない」という視点で検証したか? ✅ ハッシュタグタイムライン・コメント・応援機能で他の開発者とのつながりを実現

### Principle II: MVP-First & Phased Delivery
- [x] この機能はどのPhaseに属するか明確か? ✅ Phase 2として明確に定義、P1(Q&A)→P2(タイムライン・検索)→P3(コメント・プレミアム)で段階実装
- [x] 独立して価値を提供できるか? ✅ 各ユーザーストーリーは独立してテスト可能、Phase 1のDevCoin基盤に依存するが機能として独立
- [x] Phase間の依存関係は最小化されているか? ✅ Phase 1(認証・DevCoin)に依存、Phase 3(AI仮想クライアント)とは独立

### Principle III: Firebase-First Architecture
- [x] Firebase Authenticationで認証を実装しているか? ✅ 001-user-auth実装済み、質問投稿者・回答者の識別に使用
- [x] Cloud Firestoreをメインストレージとして使用しているか? ✅ 質問・回答・コメント・ユーザープロファイルすべてFirestoreで管理
- [x] カスタムバックエンドサーバーを避けているか? ✅ Cloud Functionsのみ使用、カスタムサーバー不使用

### Principle IV: AI Abstraction & Resilience
- [x] AI呼び出しは抽象化レイヤーを通しているか? ✅ Phase 1で実装済みのAI抽象化レイヤーを継承(Claude→GPTフォールバック)
- [x] フォールバック機構が実装されているか? ✅ Phase 1実装済み、Phase 2では追加AI機能なし(既存AI褒め機能を利用)
- [x] AI生成コンテンツのログ記録が設計されているか? N/A Phase 2ではユーザー生成コンテンツのみ(AI生成なし)

### Principle V: Legal & Compliance by Design
- [x] DevCoin経済システムは無料/有料を分離しているか? ✅ 回答報酬(無料DevCoin)とプレミアムボーナス(無料DevCoin)は明確に分離
- [x] 有料DevCoinの6ヶ月有効期限を実装しているか? ✅ Phase 1実装済みの有効期限管理を継承
- [x] プライバシーポリシー・利用規約への影響を検討したか? ✅ SNSアカウント連携・外部投稿取得・コンテンツ報告機能の利用規約・プライバシーポリシー更新が必要(Phase 0リサーチで法務レビュー項目化)

### Principle VI: Flutter Cross-Platform Strategy
- [x] Riverpodで状態管理を実装しているか? ✅ 質問・回答・タイムライン状態すべてRiverpodで管理
- [x] Material Design 3に準拠しているか? ✅ Phase 1のデザインシステムを継承、新規UI部品もMaterial Design 3準拠
- [x] Widget Test + Integration Testが計画されているか? ✅ 各ユーザーストーリーに対応する統合テスト計画済み

### Principle VII: Community-Driven Growth
- [x] コミュニティ機能はスパム対策を含んでいるか? ✅ コンテンツ報告機能(24時間審査)、重複投稿防止(5分制限)、ソフト削除(7日猶予)
- [x] 外部API依存の実現性検証(PoC)を行ったか? 🔄 Phase 0でSNS API(X/Threads/Instagram)のPoC検証を実施予定(NOTE-001)
- [x] 健全なコミュニティ育成の観点で設計したか? ✅ DevCoin経済で質問・回答の質を担保、モデレーション機能でスパム・荒らし対策

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

**No violations detected.** すべての憲法原則に準拠しています。
