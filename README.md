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
7. **Community-Driven Growth** - 健全なコミュニティ育成1

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

- Flutter 3.x以上 (3.35.7以上推奨)
- Dart 3.x以上 (3.9.2以上推奨)
- Node.js 20 LTS以上
- Firebase CLI 13.x以上
- Git
- Java (Android開発時)
- Xcode (iOS開発時)

### セットアップ手順

```bash
# リポジトリクローン
git clone https://github.com/[username]/.git
cd 

# Flutter依存関係インストール
cd flutter_app
flutter pub get
cd ..

# Firebase Emulator Suiteセットアップ
cd firebase/functions
npm install
cd ../..

# Firebase Emulatorの起動（開発環境）
cd firebase
firebase emulators:start
# または特定のエミュレータのみ起動:
# firebase emulators:start --only auth,firestore,functions

# アプリ実行（別ターミナル）
cd flutter_app
flutter run
# または特定のデバイスで実行:
# flutter run -d chrome    # Web
# flutter run -d macos     # macOS
```

### Firebase Emulatorコマンド集

```bash
# Emulatorの起動（すべてのサービス）
firebase emulators:start

# 特定のサービスのみ起動
firebase emulators:start --only auth,firestore
firebase emulators:start --only functions

# バックグラウンドで起動
firebase emulators:start &

# Emulator UIの表示（ブラウザ）
# http://localhost:4000 で自動的に開きます

# データのエクスポート（状態保存）
firebase emulators:export ./emulator-data

# データのインポート（状態復元）
firebase emulators:start --import=./emulator-data

# Emulatorの停止
# Ctrl+C で停止、またはプロセスをkillする
# バックグラウンド起動時:
pkill -f "firebase emulators:start"

# Emulatorのログを確認
# 起動時のターミナルに表示されます
# または Emulator UI (http://localhost:4000) の Logs タブで確認

# Cloud Functionsの再デプロイ（開発中）
# Emulatorは自動的にホットリロードしますが、手動で再起動する場合:
cd firebase/functions
npm run build
cd ..
firebase emulators:start
```

### 認証機能セットアップ (001-user-auth)

#### 開発環境（Firebase Emulator使用）

開発時は Firebase Emulator を使用するため、Firebase Console での設定は不要です。以下の手順で認証機能をローカルでテストできます:

1. **Firebase Emulatorの起動**
   ```bash
   cd firebase
   firebase emulators:start
   ```
   
   起動後、以下のサービスが利用可能になります:
   - Authentication Emulator: `http://localhost:9099`
   - Firestore Emulator: `http://localhost:8080`
   - Cloud Functions Emulator: `http://localhost:5001`
   - Emulator UI: `http://localhost:4000`

2. **アプリの実行**
   ```bash
   cd flutter_app
   flutter run
   ```
   
   アプリは自動的にEmulatorに接続します（`lib/main.dart`の`kDebugMode`分岐により自動切り替え）

3. **テストユーザーの作成**
   - アプリの新規登録画面からテストアカウントを作成
   - または Emulator UI (`http://localhost:4000`) の Authentication タブから手動作成

4. **認証機能のテスト**
   - メール/パスワード登録・ログイン
   - Googleサインイン（Emulator内で動作）
   - パスワードリセット（Emulator内でリセットメールが表示される）
   - レート制限（5回失敗で15分ロック）
   - セッション管理（30日間有効）

#### Emulatorデータの永続化

テストデータを保存して次回起動時に復元する場合:

```bash
# データエクスポート（Emulator起動中に実行）
firebase emulators:export ./emulator-data

# 次回起動時にインポート
firebase emulators:start --import=./emulator-data --export-on-exit
```

### Firebase本番環境設定（本番リリース時のみ）

開発時はFirebase Emulatorを使用するため不要ですが、本番リリース時に以下を設定してください：

1. **Firebase Authenticationプロバイダー有効化**
   - [Firebase Console](https://console.firebase.google.com/) → Authentication → Sign-in method
   - Email/Passwordを有効化
   - Googleサインインを有効化（サポートメールアドレス設定）

2. **Google Sign-In追加設定**
   - **Android**: `keytool`でSHA-1フィンガープリント取得 → Firebase Consoleに登録
   - **iOS**: `GoogleService-Info.plist`のReversed Client IDを`Info.plist`に追加

3. **firebase_options.dartの生成**
   ```bash
   flutterfire configure
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
