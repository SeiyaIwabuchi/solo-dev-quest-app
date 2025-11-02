# Firebase デプロイ設定 (Spark プラン)

## 概要

このプロジェクトでは、GitHub ActionsでFirestore Rulesを自動デプロイします。  
**Note**: Sparkプラン（無料）のため、Cloud Functionsはデプロイされません。

## セットアップ手順

### 1. サービスアカウントの作成

1. [Firebase Console](https://console.firebase.google.com/)にアクセス
2. プロジェクト（``）を選択
3. ⚙️（設定） → **プロジェクトの設定** → **サービス アカウント** タブ
4. **新しい秘密鍵の生成** をクリック
5. **キーを生成** をクリック
6. JSONファイルがダウンロードされます

⚠️ **重要**: このJSONファイルは機密情報です。絶対にGitにコミットしないでください。

### 2. サービスアカウントに権限を付与

1. [Google Cloud Console](https://console.cloud.google.com/)にアクセス
2. プロジェクト（``）を選択
3. **IAMと管理** → **IAM**
4. サービスアカウント（`firebase-adminsdk-...@.iam.gserviceaccount.com`）を探す
5. 編集（鉛筆アイコン）をクリック
6. ロールを追加：
   - **Firebase Rules Admin** または **Cloud Datastore Owner**
7. **保存**

### 3. GitHub Secretsへの登録

1. GitHubリポジトリページ → **Settings**
2. **Secrets and variables** → **Actions**
3. **New repository secret** をクリック
4. 入力：
   - Name: `GOOGLE_APPLICATION_CREDENTIALS`
   - Secret: ダウンロードしたJSONファイルの**内容全体**をコピー＆ペースト
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

### 認証エラー
サービスアカウントのJSON形式が正しいか確認してください：
- JSONファイル全体をコピーしているか
- 余分な改行やスペースが入っていないか

### 権限不足エラー
サービスアカウントに以下のロールが付与されているか確認：
- **Firebase Rules Admin** または
- **Cloud Datastore Owner**

### API有効化エラー
```
Error: firestore.googleapis.com is not enabled
```
→ Firebase Consoleで Firestore Database を有効化してください

### プロジェクトID確認
```bash
cd firebase
cat .firebaserc
# "" であることを確認
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
