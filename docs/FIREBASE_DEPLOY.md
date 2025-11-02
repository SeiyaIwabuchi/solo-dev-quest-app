# Firebase デプロイ設定 (Spark プラン)

## 概要

このプロジェクトでは、GitHub ActionsでFirestore Rulesを自動デプロイします。  
**Note**: Sparkプラン（無料）のため、Cloud Functionsはデプロイされません。

## セットアップ手順

### 1. サービスアカウントの作成

1. [Firebase Console](https://console.firebase.google.com/)にアクセス
2. プロジェクト（`solo-dev-quest-app`）を選択
3. ⚙️（設定） → **プロジェクトの設定** → **サービス アカウント** タブ
4. **新しい秘密鍵の生成** をクリック
5. **キーを生成** をクリック
6. JSONファイルがダウンロードされます

⚠️ **重要**: このJSONファイルは機密情報です。絶対にGitにコミットしないでください。

### 2. サービスアカウントに権限を付与

1. [Google Cloud Console](https://console.cloud.google.com/)にアクセス
2. プロジェクト（`solo-dev-quest-app`）を選択
3. **IAMと管理** → **IAM**
4. サービスアカウント（`firebase-adminsdk-...@solo-dev-quest-app.iam.gserviceaccount.com`）を探す
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

## Cloud Functions デプロイ (Blaze プラン)

### HTTP関数 vs Callable関数の選択

#### Callable Functions (`onCall`)
- **用途**: 認証済みユーザー専用の機能
- **特徴**:
  - Firebase Authentication トークンが自動的に付与される
  - `request.auth` で認証情報にアクセス可能
  - Flutter側は `FirebaseFunctions.httpsCallable()` で呼び出し
- **適用例**: ユーザープロフィール更新、課金処理、プライベートデータ操作

#### HTTP Functions (`onRequest`)
- **用途**: 未認証ユーザーからのアクセスが必要な機能
- **特徴**:
  - 認証トークン不要
  - 標準的なHTTPリクエスト/レスポンス
  - Flutter側は `http.post()` で呼び出し
  - IAM権限設定が必須
- **適用例**: ログイン前のレート制限チェック、パブリックAPI、Webhook

### ⚠️ 重要: Callable関数での認証エラー

**問題**: ログイン前のユーザーがCallable関数を呼ぶと `unavailable` エラーが発生

**原因**: 
- Callable関数はFirebase Authentication トークンを前提としている
- ログイン前のユーザーは未認証なのでトークンが存在しない
- Cloud Functions側で認証トークンの検証に失敗

**解決策**: 
ログイン前に呼び出す必要がある関数（レート制限チェックなど）は、**HTTP関数で実装**する

```typescript
// ❌ ログイン前には使えない
export const checkLoginRateLimit = onCall({region: "asia-northeast1"}, async (request) => {
  // request.auth は undefined になる
});

// ✅ ログイン前でも使える
export const checkLoginRateLimit = onRequest({region: "asia-northeast1", cors: true}, async (request, response) => {
  // HTTPリクエストとして処理
});
```

### HTTP関数のIAM権限設定

HTTP関数デプロイ後、未認証ユーザーからの呼び出しを許可するため、IAM権限の設定が必須です。

```bash
# Cloud Runサービス名を確認（関数名は小文字に変換される）
gcloud run services list --region=asia-northeast1 --project=solo-dev-quest-app

# allUsersにinvoker権限を付与
gcloud run services add-iam-policy-binding <service-name> \
  --region=asia-northeast1 \
  --member="allUsers" \
  --role="roles/run.invoker" \
  --project=solo-dev-quest-app
```

**例**:
```bash
gcloud run services add-iam-policy-binding checkloginratelimit \
  --region=asia-northeast1 \
  --member="allUsers" \
  --role="roles/run.invoker" \
  --project=solo-dev-quest-app
```

### デプロイ手順

1. **関数の実装** (`firebase/functions/src/index.ts`)
2. **デプロイ**:
   ```bash
   cd firebase
   firebase deploy --only functions
   ```
3. **IAM権限設定** (HTTP関数の場合):
   ```bash
   gcloud run services add-iam-policy-binding <service-name> \
     --region=asia-northeast1 \
     --member="allUsers" \
     --role="roles/run.invoker" \
     --project=solo-dev-quest-app
   ```

### Flutter側の実装

#### Callable関数の場合
```dart
final callable = FirebaseFunctions.instanceFor(region: 'asia-northeast1')
    .httpsCallable('functionName');
await callable.call({'param': 'value'});
```

#### HTTP関数の場合
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

final response = await http.post(
  Uri.parse('https://asia-northeast1-solo-dev-quest-app.cloudfunctions.net/functionName'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({'param': 'value'}),
);

if (response.statusCode == 200) {
  final data = json.decode(response.body);
  // 処理
}
```

### トラブルシューティング

#### `unavailable` エラー
- **原因**: Callable関数を未認証ユーザーが呼び出そうとしている
- **解決**: HTTP関数に変更

#### `not-found` エラー
- **原因**: 関数がデプロイされていない、またはリージョンが違う
- **確認**: `firebase functions:list` でデプロイ状況を確認

#### 認証エラー (HTTP関数)
- **原因**: IAM権限が設定されていない
- **解決**: `gcloud run services add-iam-policy-binding` で権限付与

#### DNS lookup 失敗
- **原因**: デバイスのネットワーク接続問題
- **解決**: エミュレータ/実機を再起動、ネットワーク設定を確認

## 参考

- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Cloud Functions: Callable vs HTTP](https://firebase.google.com/docs/functions/callable)
- [Cloud Run IAM permissions](https://cloud.google.com/run/docs/securing/managing-access-iam)
