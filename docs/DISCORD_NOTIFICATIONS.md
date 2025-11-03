# Discord通知設定ガイド

GitHub ActionsからDiscordへリリース通知を送信するための設定手順です。

## 前提条件

- Discordサーバーの管理者権限
- GitHubリポジトリの管理者権限

## 設定手順

### 1. Discord Webhook URLの作成

1. **通知を送りたいDiscordチャンネルを開く**
   
2. **チャンネル設定を開く**
   - チャンネル名の横の歯車アイコンをクリック

3. **ウェブフックを作成**
   - 「連携サービス」を選択
   - 「ウェブフック」をクリック
   - 「新しいウェブフック」をクリック

4. **ウェブフックの設定**
   - 名前: `Solo Dev Quest Bot` (任意)
   - アイコン: 好みのアイコンを設定 (任意)
   - 「ウェブフックURLをコピー」をクリック
   - URLを安全な場所に保存

### 2. GitHub Secretsの設定

1. **GitHubリポジトリを開く**
   - `https://github.com/SeiyaIwabuchi/`

2. **Settings → Secrets and variables → Actions**

3. **新しいシークレットを追加**
   - 「New repository secret」をクリック
   - Name: `DISCORD_WEBHOOK_URL`
   - Secret: コピーしたDiscord Webhook URLを貼り付け
   - 「Add secret」をクリック

### 3. 動作確認

設定後、以下のいずれかのアクションで通知が送信されます:

#### リリース通知 (`release.yml`)

- **トリガー**: `production`ブランチへのpush、または手動実行
- **通知内容**:
  - ✅ 成功: リリースバージョン、ダウンロードリンク
  - ❌ 失敗: エラー詳細へのリンク

#### Firebaseデプロイ通知 (`firebase-deploy.yml`)

- **トリガー**: `production`ブランチへのpush、PRマージ、または手動実行
- **通知内容**:
  - ✅ 成功: デプロイ完了通知
  - ❌ 失敗: エラー詳細へのリンク

## 通知の例

### リリース成功時

```
🚀 リリース完了

Solo Dev Quest の新しいバージョンがリリースされました!

バージョン: v1.0.0
ブランチ: production
コミット: abc123...
```

### Firebaseデプロイ成功時

```
🔥 Firebaseデプロイ完了

Solo Dev Quest のFirestoreルールがデプロイされました。

ブランチ: production
コミット: abc123...
トリガー: push
```

## トラブルシューティング

### 通知が届かない場合

1. **Webhook URLが正しく設定されているか確認**
   - GitHub Settings → Secrets でシークレットが存在するか確認

2. **Discordチャンネルの権限を確認**
   - ウェブフックがチャンネルに投稿する権限があるか確認

3. **GitHub Actionsのログを確認**
   - Actions タブでワークフローの実行ログを確認
   - Discord通知ステップでエラーが発生していないか確認

### Webhook URLを変更したい場合

1. Discord側で新しいWebhook URLを生成
2. GitHub Secrets の `DISCORD_WEBHOOK_URL` を更新

## カスタマイズ

### 通知メッセージの変更

ワークフローファイル(`.github/workflows/*.yml`)の以下の部分を編集:

- `embed-title`: 通知のタイトル
- `embed-description`: 通知の本文
- `embed-color`: 埋め込みの色(10進数)
  - 成功(緑): 3066993
  - Firebase(オレンジ): 15105570
  - 失敗(赤): 15158332

### Bot名・アイコンの変更

```yaml
username: "Solo Dev Quest Bot"  # Bot名
avatar-url: "https://..."       # アイコン画像URL
```

## 参考リンク

- [Discord Webhook ドキュメント](https://discord.com/developers/docs/resources/webhook)
- [GitHub Actions Secrets](https://docs.github.com/ja/actions/security-guides/encrypted-secrets)
- [discord-webhook Action](https://github.com/tsickert/discord-webhook)
