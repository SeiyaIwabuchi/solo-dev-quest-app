<!--
Sync Impact Report:
Version Change: [Template] → 1.0.0
Modified Principles: Initial constitution creation
Added Sections:
  - Core Principles (7 principles defined)
  - Technology Stack Standards
  - User Experience Standards
  - Development Workflow
  - Governance
Templates Status:
  - plan-template.md: ✅ Updated (Constitution Check gates added, Flutter+Firebase project structure defined)
  - spec-template.md: ✅ Updated (Constitution alignment comments added to user story section)
  - tasks-template.md: ✅ Updated (Path conventions updated, Phase structure aligned with constitution)
  - README.md: ✅ Created (Project overview with constitution reference)
Follow-up TODOs:
  - Establish automated constitution compliance checks in CI/CD (Phase 1 task)
  - Create constitution checklist for PR reviews
  - Document constitution amendment process in contribution guidelines (when opened)
-->

# Solo Dev Quest Constitution

## Core Principles

### I. User-Centric Motivation Design (NON-NEGOTIABLE)
すべての機能はユーザーのモチベーション維持を最優先に設計されなければならない。
- ゲーミフィケーション要素は「楽しさ」よりも「継続の動機づけ」を優先する
- タスク完了時の即時フィードバック（AI褒め、可視化の進行）を必須とする
- サボり防止機能（AI説教システム）は段階的かつ配慮的に実装する
- すべてのUI/UX判断において「開発者が孤独を感じない設計」を検証する

**理由**: 本アプリの核心的価値は「個人開発者の3大課題解決」であり、モチベーション維持が最も重要な課題である。

### II. MVP-First & Phased Delivery
機能は段階的に実装し、各フェーズで独立して価値を提供しなければならない。
- Phase 1（MVP）で基本的なタスク管理 + AI褒め + マラソンランナー可視化を完成させる
- 各機能は最小限の実装で動作確認可能にする（PoC駆動）
- 新機能追加前に既存機能の安定性を確保する
- Phase間の依存関係を最小化し、並行開発可能な構造を維持する

**理由**: 個人開発プロジェクトとして、早期リリースとユーザーフィードバック取得が成功の鍵となる。

### III. Firebase-First Architecture
Firebaseエコシステムを最大限活用し、バックエンド開発の複雑さを最小化する。
- 認証: Firebase Authentication必須
- データベース: Cloud Firestoreをメインストレージとする
- サーバーレス関数: Cloud Functions (Node.js/TypeScript) で実装
- リアルタイム機能: Firestore Realtime Listenersを活用
- ストレージ: Firebase Storageを画像・動画に使用
- カスタムバックエンドサーバーの構築は原則禁止（Firebase Functionsで解決）

**理由**: 個人開発のリソース制約下で、スケーラブルかつ低コストなインフラを実現する。

### IV. AI Abstraction & Resilience
AI機能は特定のプロバイダーに依存せず、障害時の冗長性を確保する。
- メインAI: Claude 3.5 Haiku (Anthropic)
- フォールバックAI: GPT-4o mini (OpenAI)
- AI呼び出しは抽象化レイヤーを通して実行し、プロバイダー切り替えを容易にする
- レート制限・障害時の自動フォールバック機構を実装する
- AI生成コンテンツは必ずログ記録し、品質改善のデータとする

**理由**: AI機能はアプリの核心価値であり、可用性確保が必須。プロバイダー依存のリスクを分散する。

### V. Legal & Compliance by Design
法的要件（資金決済法、利用規約、プライバシー）を設計段階から組み込む。
- DevCoin経済システムは無料/有料を明確に分離管理する
- 有料DevCoinは6ヶ月有効期限を厳守（資金決済法対応）
- すべての課金処理はApp Store/Google Play課金APIを使用（独自決済禁止）
- ユーザーデータの収集・利用目的を明示し、GDPR/個人情報保護法に準拠
- 利用規約・プライバシーポリシーは法務レビュー後に実装する

**理由**: 課金機能を持つアプリとして、法的トラブルを未然に防ぐことが事業継続の前提条件。

### VI. Flutter Cross-Platform Strategy
単一コードベースでiOS/Android/Webをカバーし、プラットフォーム固有の最適化を行う。
- 状態管理: Riverpodを標準とする（Provider/Blocは使用禁止）
- UI実装: Material Design 3をベースに、プラットフォーム別の調整を許容
- ネイティブ機能: Platform Channelsで実装し、各プラットフォームの体験を最適化
- Web版は基本機能のみ提供し、モバイルアプリへの誘導を優先
- テスト: Widget Test + Integration Testを各機能に必須化

**理由**: 開発効率を最大化しつつ、各プラットフォームでのユーザー体験を損なわない。

### VII. Community-Driven Growth
コミュニティ機能は段階的に構築し、ユーザー間の自然な交流を促進する。
- SNS連携（X/Threads/Instagram）は外部APIを活用し、実装コストを最小化
- ハッシュタグタイムラインは技術的実現性をPoC検証後に実装判断
- Q&Aプラットフォームは質問・回答の質を担保するDevCoin経済設計を優先
- スパム・荒らし対策を初期段階から組み込む（報告機能、自動検知）
- コミュニティガイドラインを明確化し、健全な開発者コミュニティを育成

**理由**: 孤独感の解消はコミュニティの質に依存する。健全な成長が持続可能性の鍵。

## Technology Stack Standards

すべての開発は以下の技術スタックに準拠しなければならない。

**フロントエンド**:
- Flutter 3.x以上（Stable channel）
- Dart 3.x以上
- Riverpod 2.x（状態管理）
- go_router（ルーティング）
- freezed（イミュータブルモデル）

**バックエンド**:
- Firebase Authentication（認証）
- Cloud Firestore（データベース）
- Cloud Functions for Firebase（サーバーレス）
- Firebase Storage（ファイルストレージ）
- Node.js 20 LTS + TypeScript 5.x（Functions実装）

**AI統合**:
- Anthropic Claude API（メイン）
- OpenAI GPT API（フォールバック）
- Cloud Functions経由で呼び出し（クライアント直接呼び出し禁止）

**開発ツール**:
- Firebase Emulator Suite（ローカル開発）
- GitHub Actions（CI/CD）
- Flutter Test（単体・統合テスト）

**モニタリング**:
- Firebase Crashlytics（クラッシュレポート）
- Firebase Performance Monitoring（パフォーマンス）
- Firebase Analytics（ユーザー行動分析）

## User Experience Standards

すべてのUI/UX実装は以下の基準を満たさなければならない。

**即時フィードバック**:
- タスク完了時、0.5秒以内にAI褒めメッセージを表示
- 可視化アニメーション（マラソンランナー進行等）は3秒以内に完了
- すべてのユーザーアクションに視覚的フィードバックを提供

**エラーハンドリング**:
- ネットワークエラー時は明確なリトライオプションを表示
- AI機能失敗時は代替手段（後で再試行、フォールバックAI）を提示
- データ損失リスクのある操作には確認ダイアログを表示

**アクセシビリティ**:
- すべてのインタラクティブ要素は最小タップ領域48x48dpを確保
- 色のみに依存しない情報伝達（アイコン・テキスト併用）
- スクリーンリーダー対応（Semanticsウィジェット活用）

**パフォーマンス**:
- アプリ起動時間: 3秒以内にメイン画面表示
- 画面遷移: 60fps維持（jankyフレーム5%以下）
- AI応答待機時はスケルトンUI・ローディングアニメーション表示

## Development Workflow

開発は以下のワークフローに従う。

**Phase-Driven Development**:
1. **Phase 0**: 要件定義 + 技術調査（PoC）
2. **Phase 1**: MVP実装（認証・タスク管理・可視化・AI褒め・DevCoin基盤）
3. **Phase 2**: コミュニティ機能（SNS連携・ハッシュタグタイムライン・Q&A）
4. **Phase 3**: 高度な機能（AI仮想クライアント・AI説教・追加可視化テーマ）
5. **Phase 4**: 継続改善（パフォーマンス最適化・ユーザーフィードバック対応）

**ブランチ戦略**:
- `main`: 本番リリース可能な安定版
- `develop`: 開発統合ブランチ
- `feature/###-feature-name`: 機能開発ブランチ（仕様番号プレフィックス）
- `hotfix/issue-description`: 緊急修正ブランチ

**コードレビュー**:
- すべてのPRはセルフレビュー + 自動テスト合格後にマージ
- 憲法原則への準拠を必ずチェック（特にPrinciple I, II, V）
- 破壊的変更は必ずマイグレーション計画を添付

**テスト戦略**:
- 単体テスト: ビジネスロジック・状態管理クラス
- ウィジェットテスト: UI部品の振る舞い
- 統合テスト: ユーザーストーリー単位の主要フロー
- E2Eテスト: クリティカルパス（認証・課金・AI機能）のみ実装

## Governance

**憲法の優先順位**:
本憲法はすべての開発判断・設計判断に優先する。憲法と矛盾する実装は認められない。

**憲法改正プロセス**:
1. 改正提案を`.specify/memory/constitution.md`に記録
2. 改正理由・影響範囲を明記
3. 関連テンプレート・ドキュメントの更新計画を添付
4. バージョン番号を適切にインクリメント（MAJOR/MINOR/PATCH）
5. 改正履歴をSync Impact Reportとして記録

**バージョニングルール**:
- **MAJOR**: 原則の削除・根本的な再定義（後方互換性なし）
- **MINOR**: 新原則の追加・既存原則の重要な拡張
- **PATCH**: 文言の明確化・誤字修正・非本質的な改善

**コンプライアンスレビュー**:
- すべてのPRで憲法準拠をチェックリストで確認
- Phase完了時に憲法ゲート審査を実施
- 憲法違反を発見した場合は即座に修正チケットを起票

**ガイダンスファイル**:
実行時の開発ガイダンスは`.github/copilot-instructions.md`を参照。憲法と矛盾する場合は憲法が優先される。

**Version**: 1.0.0 | **Ratified**: 2025-11-01 | **Last Amended**: 2025-11-01
