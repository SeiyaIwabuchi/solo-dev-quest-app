# Firebase デプロイ設定 (Spark プラン)

## 概要

このプロジェクトでは、GitHub ActionsでFirestore Rulesを自動デプロイします。  
**Note**: Sparkプラン（無料）のため、Cloud Functionsはデプロイされません。

## セットアップ手順

### 1. Firebase CIトークンの取得

ローカル環境で以下のコマンドを実行：

```bash
firebase login:ci
```

実行後：
1. ブラウザが開き、Googleアカウントでのログインを求められます
2. 認証後、ターミナルにトークンが表示されます
3. このトークンをコピー

⚠️ **重要**: このトークンは機密情報です。絶対にGitにコミットしないでください。

### 2. GitHub Secretsへの登録

1. GitHubリポジトリページ → **Settings**
2. **Secrets and variables** → **Actions**
3. **New repository secret** をクリック
4. 入力：
   - Name: `FIREBASE_TOKEN`
   - Secret: コピーしたトークン
5. **Add secret** をクリック

### 3. デプロイの実行

#### 自動デプロイ
- `main`ブランチへのpush時に自動実行

#### 手動デプロイ
1. GitHub → **Actions** タブ
2. **Deploy to Firebase** ワークフロー選択
3. **Run workflow** → ブランチ選択（`main`）
4. **Run workflow** 実行

## デプロイ内容

### ✅ Firestore Rules
- `firebase/firestore.rules`
- usersコレクション: 自分のプロフィールのみ読み書き可
- login_locksコレクション: Cloud Functionsのみアクセス可

### ❌ Cloud Functions (Sparkプランでは不可)
- checkLoginRateLimit
- recordLoginAttempt
- cleanupExpiredLocks

**代替案**: Emulatorでローカル動作確認のみ

## ローカルデプロイ

GitHub Actionsを使わない場合：

```bash
cd firebase
firebase deploy --only firestore:rules
```

## トラブルシューティング

### トークンエラー
```bash
# 新しいトークンを取得
firebase login:ci
# GitHub Secretsを更新
```

### 権限不足
Firebaseプロジェクトで適切な権限（Editor以上）が必要です。

### プロジェクトID確認
```bash
cd firebase
cat .firebaserc
# "solo-dev-quest-app" であることを確認
```

## セキュリティ

### トークン管理
- ✅ GitHub Secretsに保存
- ❌ コードに直接記載
- ❌ 環境変数ファイルに保存

### トークン更新
3-6ヶ月ごとの更新を推奨

## モニタリング

デプロイ後の確認：

1. **Firebase Console**
   - Firestore Database → Rules タブ
   - ルールが更新されていることを確認

2. **GitHub Actions**
   - Actionsタブでログ確認

3. **アプリ動作確認**
   - 新規登録
   - ログイン
   - データ保存

## 参考

- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- [GitHub Actions Documentation](https://docs.github.com/actions)
