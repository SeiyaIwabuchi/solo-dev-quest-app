# Solo Dev Quest

個人開発者が抱える「モチベーション維持」「孤独感」「知識不足」の3大課題を解決する、AI×ゲーミフィケーションを活用した開発支援プラットフォーム。

## 🎯 プロジェクトビジョン

個人開発者が長期的にプロジェクトを継続し、楽しく開発を続けられる環境を提供します。

### 解決する3大課題

1. **モチベーション維持** - ゲーミフィケーション＋AI褒め/説教システム
2. **孤独感** - AI仮想クライアント＋コミュニティ機能
3. **知識不足** - DevCoin経済圏を活用したQ&Aプラットフォーム

詳細は[企画書.md](./企画書.md)を参照してください。

## 🏗️ 技術スタック

- **フロントエンド**: Flutter 3.x + Riverpod + go_router
- **バックエンド**: Firebase (Auth, Firestore, Functions, Storage)
- **AI**: Claude 3.5 Haiku (メイン) + GPT-4o mini (フォールバック)
- **CI/CD**: GitHub Actions
- **開発環境**: Firebase Emulator Suite

## 📐 プロジェクト憲法

本プロジェクトのすべての開発判断は[プロジェクト憲法](./.specify/memory/constitution.md)に従います。

### 7つの核心原則

1. **User-Centric Motivation Design** - モチベーション維持を最優先
2. **MVP-First & Phased Delivery** - 段階的な価値提供
3. **Firebase-First Architecture** - Firebaseエコシステム活用
4. **AI Abstraction & Resilience** - AI機能の冗長性確保
5. **Legal & Compliance by Design** - 法的要件の組み込み
6. **Flutter Cross-Platform Strategy** - 効率的なマルチプラットフォーム開発
7. **Community-Driven Growth** - 健全なコミュニティ育成

## 📂 プロジェクト構造

```
lib/
├── core/              # 共通基盤（constants, utils, errors, router）
├── features/          # 機能別ディレクトリ（auth, tasks, visualization, ai, devcoin, community）
│   └── [feature]/     # data, domain, presentation, providers
└── shared/            # 共有コンポーネント（widgets, models, services）

functions/             # Firebase Cloud Functions (TypeScript)
├── src/
│   ├── ai/            # AI API呼び出し処理
│   ├── devcoin/       # DevCoin管理ロジック
│   └── notifications/ # プッシュ通知処理

test/
├── unit/              # 単体テスト
├── widget/            # ウィジェットテスト
└── integration/       # 統合テスト

.specify/              # 開発ガイダンス・憲法
├── memory/
│   └── constitution.md  # プロジェクト憲法
└── templates/         # 仕様・計画・タスクテンプレート
```

## 🚀 開発フェーズ

### Phase 1: MVP (2-3ヶ月)
- ユーザー認証
- 基本タスク管理
- マラソンランナー可視化
- AI褒めシステム
- DevCoinシステム基盤

### Phase 2: コミュニティ (1-2ヶ月)
- SNS連携・投稿機能
- ハッシュタグタイムライン
- Q&A基本機能

### Phase 3: 高度な機能 (2-3ヶ月)
- AI仮想クライアント
- AI説教システム
- 追加可視化テーマ

### Phase 4: 継続改善
- パフォーマンス最適化
- ユーザーフィードバック対応
- 新テーマ追加

## 🛠️ 開発セットアップ

### 前提条件

- Flutter 3.x以上
- Node.js 20 LTS以上
- Firebase CLI
- Git

### セットアップ手順

```bash
# リポジトリクローン
git clone https://github.com/[username]/.git
cd 

# Flutter依存関係インストール
flutter pub get

# Firebase Emulator Suiteセットアップ
cd functions
npm install
cd ..

# Firebase Emulatorの起動
firebase emulators:start

# アプリ実行（別ターミナル）
flutter run
```

## 📋 開発ワークフロー

1. **仕様作成**: `.specify/templates/spec-template.md`を基に機能仕様を作成
2. **計画立案**: `.specify/templates/plan-template.md`で実装計画を策定
3. **タスク分解**: `.specify/templates/tasks-template.md`でタスクリスト作成
4. **実装**: 憲法チェックを通過後、feature/###-feature-nameブランチで開発
5. **テスト**: Widget Test + Integration Testを実装
6. **レビュー**: PRで憲法準拠を確認後マージ

## 📄 ライセンス

[ライセンスを指定してください]

## 🤝 コントリビューション

このプロジェクトは現在個人開発中です。将来的にコントリビューションを受け付ける予定です。

## 📞 連絡先

[連絡先情報を記載してください]

---

**Version**: 1.0.0 | **Last Updated**: 2025-11-01
