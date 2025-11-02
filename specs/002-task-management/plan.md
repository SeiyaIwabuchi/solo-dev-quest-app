# Implementation Plan: Project and Task Management

**Branch**: `002-task-management` | **Date**: 2025-11-03 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-task-management/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

個人開発者向けのプロジェクトとタスク管理機能を実装する。ユーザーは複数のプロジェクトを作成し、各プロジェクト内でタスクを作成・編集・削除・完了マークできる。タスク完了時にはAI褒めシステムと非同期連携し、モチベーション維持機能のトリガーとなる。Cloud Firestoreをデータストレージとし、オフライン対応とリアルタイム同期を実装。無限スクロールで大量タスクのパフォーマンスを最適化する。

**Phase 1 Status**: ✅ Completed (2025-11-03)
- ✅ Research: 無限スクロール、Firestoreカーソル管理、モック戦略、インデックス設計、ベストプラクティス
- ✅ Data Model: Project/Task/TaskStatisticsエンティティ定義、Firestoreスキーマ設計完了
- ✅ Contracts: IProjectRepository, ITaskRepository インターフェース定義、Firestore/Fake実装例
- ✅ Quickstart: 開発者向け実装ガイド作成、アーキテクチャ・パターン・チェックリスト完備
- ✅ Agent Context: copilot-instructions.md更新（Dart 3.9.2+, Flutter 3.35.7+, Firestore追加）
- ✅ Constitution Check: 全7原則に準拠確認済み

**Phase 2 Status**: ✅ Completed (2025-11-03)
- ✅ Task Decomposition: 103タスク生成、11フェーズ構成（Setup, Foundational, US1-US7, Enhancements, Polish）
- ✅ User Story Mapping: 7ユーザーストーリーを優先度順に整理（P1: US1-US4 MVP、P2: US5-US6、P3: US7）
- ✅ Dependency Analysis: Phase依存関係、User Story依存関係、並列実行可能性を明確化
- ✅ MVP Definition: Phase 0-5（53タスク）= US1-US4 = コアタスク管理機能
- ✅ Parallel Opportunities: 20+の並列実行可能タスクを特定（Phase 1で4並列、US1で4並列等）
- ✅ Implementation Strategy: MVP-First、段階的デリバリー、並列チーム戦略を定義

## Technical Context

**Language/Version**: Dart 3.9.2+, Flutter 3.35.7+ (Stable channel)
**Primary Dependencies**: 
- flutter_riverpod 2.6.1 (状態管理)
- cloud_firestore 5.5.1 (データベース)
- freezed 2.5.7 (イミュータブルモデル)
- NEEDS CLARIFICATION: 無限スクロール実装のベストプラクティス（lazy loading パターン）
- NEEDS CLARIFICATION: Firestoreクエリカーソルの効率的な管理方法

**Storage**: Cloud Firestore (NoSQL)
- Collections: `projects`, `tasks`
- オフライン永続化有効
- リアルタイムリスナーでUI自動更新

**Testing**: Flutter Test Framework
- Widget Test: UI コンポーネント
- Integration Test: ユーザーフロー
- NEEDS CLARIFICATION: Firestoreモック戦略（エミュレーター vs fake実装）

**Target Platform**: iOS 15+, Android 8.0+, Web (モバイル優先)
**Project Type**: Mobile (クロスプラットフォーム Flutter アプリ)

**Performance Goals**:
- プロジェクト作成→表示: 3秒以内
- タスク作成→表示: 2秒以内  
- タスク完了マーク→進捗率更新: 1秒以内
- 100タスク表示時: 60fps維持
- 無限スクロール: 次ページ読み込み500ms以内

**Constraints**:
- オフライン対応必須（ローカルキャッシュ + 自動同期）
- 同期競合: Last Write Wins戦略
- AI褒めシステムとの非同期連携（ブロッキングなし）
- Firestore読み取り最適化（不要なクエリ削減）

**Scale/Scope**:
- 想定ユーザー: 個人開発者、1ユーザーあたりプロジェクト数無制限
- タスク数: プロジェクトあたり最大1000タスク想定
- 画面数: 4画面（プロジェクトリスト、プロジェクト詳細、タスク作成/編集）
- NEEDS CLARIFICATION: Firestoreインデックス設計（ソート・フィルター用）

## Constitution Check (Post-Design)

> [!IMPORTANT]
> Re-validate all design decisions against the constitution after completing Phase 1 (Design & Contracts).

**Status**: ✅ Completed (2025-11-03)

| Principle | Compliant? | Notes |
|-----------|------------|-------|
| I. User-Centric Motivation | ✅ | プロジェクト100%完了時のお祝いメッセージ + AI賞賛（非同期）を実装。タスク完了の即時フィードバックを提供。 |
| II. MVP-First & Phased Delivery | ✅ | 基本的なCRUD機能をMVPとして定義。無限スクロール等の高度な機能も段階的に実装可能。 |
| III. Firebase-First Architecture | ✅ | Cloud Firestore（NoSQL）をメインストレージとして採用。セキュリティルール・インデックス設計完了。 |
| IV. AI Abstraction & Resilience | ✅ | AI賞賛機能は非同期・非ブロッキング統合。既存のAI抽象化レイヤーを活用（001-user-authで実装済み）。 |
| V. Legal & Compliance by Design | ✅ | 課金・DevCoin経済は本機能の対象外。ユーザーデータはFirebaseセキュリティルールで保護。 |
| VI. Flutter Cross-Platform Strategy | ✅ | Riverpod（StateNotifier/StreamProvider）を使用した状態管理。Freezedでイミュータブルモデル定義。 |
| VII. Community-Driven Growth | ✅ | 本機能はタスク管理のみでコミュニティ機能なし。将来的なコミュニティ統合の基盤として設計。 |

**Compliance Notes**:
- **Principle I**: FR-016でプロジェクト100%完了時の体験を明確化。Edge Case #5でAI賞賛の非同期実装を保証。
- **Principle II**: 基本CRUD機能（FR-001～FR-009）をMVP、無限スクロール（FR-015）を拡張機能として段階化。
- **Principle III**: Firestoreコレクション設計（`projects/`, `tasks/`）、複合インデックス設計、セキュリティルールを完全定義。カスタムバックエンド不要。
- **Principle IV**: AI賞賛呼び出しは既存の抽象化レイヤー（001-user-authで実装済み）を再利用。障害時もタスク管理機能は影響なし。
- **Principle V**: 本機能は無料機能のみで課金なし。Firestoreセキュリティルールでユーザー所有権を厳格に管理（userId検証）。
- **Principle VI**: RiverpodのStreamProviderでリアルタイムUI更新。Freezed + json_serializableでイミュータブルモデル生成。テスト戦略（Unit/Widget/Integration）定義済み。
- **Principle VII**: タスク管理は個人機能のみ。将来的なコミュニティ統合（タスク共有等）の拡張ポイントを残す設計。

**Identified Risks**:
なし（すべての原則に準拠）

**Follow-up Actions**:
なし（Constitution Check合格）

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
