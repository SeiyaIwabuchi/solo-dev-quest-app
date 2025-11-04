# Quick Start: Phase 2 コミュニティ機能

**Target Audience**: 開発者 (このフィーチャーの実装を開始する人)  
**Prerequisites**: Phase 1 (認証・タスク管理・DevCoin基盤) 実装完了

---

## 1. セットアップ (5分)

### 1.1 ブランチ切り替え

```bash
cd /path/to/
git checkout 003-community-features
git pull origin 003-community-features
```

### 1.2 依存関係インストール

**Flutter**:
```bash
cd flutter_app
flutter pub get
```

**Firebase Functions**:
```bash
cd ../firebase/functions
npm install
```

**追加パッケージ** (Phase 2新規):
```bash
cd ../../flutter_app

# SNS SDK (Functions側)
cd ../firebase/functions
npm install twitter-api-v2 axios facebook-nodejs-business-sdk

# Flutter課金SDK
cd ../../flutter_app
flutter pub add in_app_purchase
flutter pub add cached_network_image  # 画像キャッシュ
flutter pub add sqflite               # オフラインキャッシュ
```

### 1.3 Firebase Emulator起動

```bash
cd ../firebase
firebase emulators:start
```

- Firestore UI: http://localhost:4000/firestore
- Functions UI: http://localhost:4001
- Auth UI: http://localhost:4000/auth

---

## 2. データベース準備 (10分)

### 2.1 Firestoreインデックス作成

`firebase/firestore.indexes.json`に以下を追加 (既に追加済みの場合はスキップ):

```json
{
  "indexes": [
    {
      "collectionGroup": "questions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "categoryTag", "order": "ASCENDING" },
        { "fieldPath": "deletionStatus", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "questions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "categoryTag", "order": "ASCENDING" },
        { "fieldPath": "deletionStatus", "order": "ASCENDING" },
        { "fieldPath": "answerCount", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "questions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "categoryTag", "order": "ASCENDING" },
        { "fieldPath": "deletionStatus", "order": "ASCENDING" },
        { "fieldPath": "evaluationScore", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "answers",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "questionId", "order": "ASCENDING" },
        { "fieldPath": "deletionStatus", "order": "ASCENDING" },
        { "fieldPath": "evaluationScore", "order": "DESCENDING" }
      ]
    }
  ]
}
```

**デプロイ**:
```bash
firebase deploy --only firestore:indexes
```

### 2.2 セキュリティルール更新

`firebase/firestore.rules`に以下を追加:

```javascript
// Questions
match /questions/{questionId} {
  allow read: if resource.data.deletionStatus == 'normal';
  allow create: if request.auth != null 
    && request.auth.uid == request.resource.data.authorId
    && request.resource.data.deletionStatus == 'normal';
  allow update: if request.auth != null 
    && request.auth.uid == resource.data.authorId
    && !request.resource.data.diff(resource.data).affectedKeys()
      .hasAny(['authorId', 'createdAt', 'deletionStatus']);
  allow delete: if false;
}

// Answers
match /answers/{answerId} {
  allow read: if resource.data.deletionStatus == 'normal';
  allow create: if request.auth != null 
    && request.auth.uid == request.resource.data.authorId;
  allow update: if request.auth != null 
    && request.auth.uid == resource.data.authorId
    && !request.resource.data.diff(resource.data).affectedKeys()
      .hasAny(['authorId', 'createdAt', 'isBestAnswer', 'deletionStatus']);
  allow delete: if false;
}

// Comments (以下同様に追加...)
```

**デプロイ**:
```bash
firebase deploy --only firestore:rules
```

### 2.3 テストデータ投入 (Emulator)

```bash
cd firebase/scripts
node seed-test-data.js
```

`seed-test-data.js`の内容例:
```javascript
const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'demo-project' });

const firestore = admin.firestore();

async function seedData() {
  // テストユーザー作成
  await firestore.collection('users').doc('test_user_1').set({
    uid: 'test_user_1',
    displayName: 'テスト太郎',
    email: 'test1@example.com',
    devCoinBalance: 100,
  });

  // テスト質問作成
  await firestore.collection('questions').add({
    title: 'FlutterでFirebase Authのエラーハンドリング方法は?',
    body: 'サインイン失敗時のエラーを適切に表示したいです...',
    categoryTag: 'Flutter',
    authorId: 'test_user_1',
    authorName: 'テスト太郎',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    answerCount: 0,
    viewCount: 0,
    evaluationScore: 0,
    deletionStatus: 'normal',
  });

  console.log('✅ Seed data created');
}

seedData();
```

---

## 3. 開発環境構成 (15分)

### 3.1 環境変数設定

**Firebase Functions** (`functions/.env`):
```bash
# X API
TWITTER_CLIENT_ID=your_client_id
TWITTER_CLIENT_SECRET=your_client_secret

# Threads API (Meta App)
META_APP_ID=your_app_id
META_APP_SECRET=your_app_secret

# Instagram Graph API
INSTAGRAM_APP_ID=your_app_id
INSTAGRAM_APP_SECRET=your_app_secret

# App Store
APPLE_SHARED_SECRET=your_shared_secret

# Google Play
GOOGLE_PLAY_SERVICE_ACCOUNT_KEY=path/to/service-account.json
```

**Flutter** (`flutter_app/.env`):
```bash
# アプリ内課金商品ID
IOS_PREMIUM_PRODUCT_ID=premium_monthly_680
ANDROID_PREMIUM_PRODUCT_ID=premium_monthly_680
```

### 3.2 VSCode設定

`.vscode/launch.json`にデバッグ設定追加:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter (Emulator)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=FIREBASE_EMULATOR=true"
      ]
    },
    {
      "name": "Firebase Functions (Debug)",
      "type": "node",
      "request": "attach",
      "port": 9229,
      "restart": true
    }
  ]
}
```

---

## 4. 開発フロー (Phase 2優先順位)

### Priority 1 (Week 1-2): Q&A基本機能

**実装順序**:
1. ✅ データモデル準備 (Firestore collections作成)
2. ✅ Cloud Functions実装
   - `postQuestion` (質問投稿)
   - `postAnswer` (回答投稿)
   - `selectBestAnswer` (ベストアンサー選択)
3. ✅ Flutter UI実装
   - 質問一覧画面 (`lib/features/community/presentation/question_list_screen.dart`)
   - 質問投稿画面 (`question_post_screen.dart`)
   - 質問詳細画面 (`question_detail_screen.dart`)
   - 回答投稿UI (詳細画面内)

**テスト**:
```bash
# Functions単体テスト
cd firebase/functions
npm test src/community/question.test.ts

# Flutter統合テスト
cd ../../flutter_app
flutter test integration_test/question_flow_test.dart
```

---

### Priority 2 (Week 3-4): 検索・フィルタリング

**実装順序**:
1. ✅ `searchQuestions` Cloud Function実装
2. ✅ 検索UI (`search_questions_screen.dart`)
3. ✅ カテゴリフィルタ・ソート機能

**Firestoreクエリ例**:
```dart
final query = FirebaseFirestore.instance
  .collection('questions')
  .where('categoryTag', isEqualTo: 'Flutter')
  .where('deletionStatus', isEqualTo: 'normal')
  .orderBy('createdAt', descending: true)
  .limit(20);
```

---

### Priority 3 (Week 5-6): SNS統合 (PoC必須)

**PoC検証** (実装前に実施):
1. X API v2ハッシュタグ検索テスト
2. Threads API可用性確認 (仕様変更チェック)
3. Instagram Graph API投稿取得テスト

**実装順序** (PoC成功後):
1. ✅ OAuth認証フロー (`connectSNS` Function)
2. ✅ ハッシュタグタイムライン取得 (`fetchHashtagTimeline`)
3. ✅ タイムラインUI (`hashtag_timeline_screen.dart`)
4. ✅ SNSアクション実装 (`performSNSAction`)

**注意**: Threads APIは仕様変更頻度が高いため、最新ドキュメント確認必須 (https://developers.facebook.com/docs/threads)

---

### Priority 4 (Week 7): プレミアムプラン

**実装順序**:
1. ✅ App Store Connect / Google Play Console商品登録
2. ✅ `verifyPremiumPurchase` Function実装
3. ✅ Webhookエンドポイント (`appleSubscription`, `googleSubscription`)
4. ✅ Flutter購入UI (`premium_plan_screen.dart`)

**Sandbox Testing**:
- iOS: App Store Connect Sandboxアカウント作成
- Android: Google Play Test Trackに内部テストアプリアップロード

---

### Priority 5 (Week 8): コメント・応援・モデレーション

**実装順序**:
1. ✅ コメント機能 (`postComment` Function + UI)
2. ✅ 報告機能 (`reportContent` Function + UI)
3. ✅ 管理者ダッシュボード (Firebase Hosting + Admin SDK)
4. ✅ Scheduled Functions (削除・猶予期間チェック)

---

## 5. よくある開発タスク

### 5.1 新しいCloud Function追加

```bash
cd firebase/functions/src/community
touch my_new_function.ts
```

`my_new_function.ts`:
```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const myNewFunction = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', '認証が必要です');
  }
  
  // ロジック実装
  return { success: true };
});
```

`src/index.ts`にエクスポート追加:
```typescript
export { myNewFunction } from './community/my_new_function';
```

**デプロイ**:
```bash
firebase deploy --only functions:myNewFunction
```

---

### 5.2 新しい画面追加

```bash
cd flutter_app/lib/features/community/presentation
mkdir my_new_screen
touch my_new_screen/my_new_screen.dart
touch my_new_screen/my_new_screen_controller.dart
```

**ルーティング追加** (`lib/core/router/app_router.dart`):
```dart
GoRoute(
  path: '/my-new-screen',
  builder: (context, state) => const MyNewScreen(),
),
```

---

### 5.3 Riverpod Provider追加

`lib/features/community/providers/my_provider.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier();
});

class MyNotifier extends StateNotifier<MyState> {
  MyNotifier() : super(MyState.initial());
  
  Future<void> fetchData() async {
    // ロジック実装
  }
}

class MyState {
  final bool isLoading;
  final List<String> items;
  
  MyState({required this.isLoading, required this.items});
  
  factory MyState.initial() => MyState(isLoading: false, items: []);
}
```

---

### 5.4 統合テスト追加

`flutter_app/integration_test/my_flow_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:solo_dev_quest/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('質問投稿フロー', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    // 質問投稿ボタンをタップ
    await tester.tap(find.byKey(const Key('post_question_button')));
    await tester.pumpAndSettle();
    
    // タイトル入力
    await tester.enterText(
      find.byKey(const Key('question_title_field')),
      'テスト質問'
    );
    
    // 投稿実行
    await tester.tap(find.byKey(const Key('submit_button')));
    await tester.pumpAndSettle();
    
    // 確認
    expect(find.text('質問を投稿しました'), findsOneWidget);
  });
}
```

**実行**:
```bash
flutter test integration_test/my_flow_test.dart
```

---

## 6. デバッグTips

### 6.1 Firestore Emulatorデータ確認

```bash
# ブラウザでUI確認
open http://localhost:4000/firestore

# CLIでクエリ実行
firebase firestore:get questions --limit 10
```

### 6.2 Cloud Functionsログ確認

```bash
# Emulator
firebase emulators:logs

# 本番
firebase functions:log --only postQuestion
```

### 6.3 Flutter DevToolsでネットワーク確認

```bash
flutter run --dart-define=FIREBASE_EMULATOR=true
# 別ターミナルで
flutter pub global run devtools
```

Network Tabで`httpsCallable`呼び出しを確認可能。

---

## 7. トラブルシューティング

### 7.1 "Insufficient DevCoin balance"エラー

**原因**: Phase 1のDevCoin管理ロジックが正しく動作していない

**解決**:
```bash
# Emulatorでユーザー残高を手動更新
firebase firestore:set users/test_user_1 '{"devCoinBalance": 100}' --merge
```

### 7.2 Firestoreインデックス作成エラー

**エラー**: `The query requires an index`

**解決**:
1. エラーメッセージ内のリンクをクリック → Firebaseコンソールで自動作成
2. または`firestore.indexes.json`に手動追加後デプロイ

### 7.3 SNS API認証エラー

**エラー**: `401 Unauthorized`

**解決**:
1. `.env`ファイルのClient ID/Secretが正しいか確認
2. OAuth Callback URLがFirebase Authingに登録されているか確認
3. アクセストークンの有効期限切れ → リフレッシュトークンで更新

---

## 8. リリース前チェックリスト

- [ ] すべての統合テスト通過
- [ ] Firebase Emulatorでフルフロー動作確認
- [ ] Sandbox環境でアプリ内課金テスト (iOS/Android)
- [ ] SNS API PoC検証完了 (X/Threads/Instagram)
- [ ] Firestoreセキュリティルールデプロイ済み
- [ ] Cloud Functionsデプロイ済み
- [ ] 利用規約・プライバシーポリシー更新 (法務レビュー完了)
- [ ] Firebase Performance Monitoringで主要画面のパフォーマンス確認 (60fps維持)
- [ ] Firebase Crashlyticsで既知のクラッシュ0件確認

---

## 9. 参考リンク

- [Spec](./spec.md)
- [Data Model](./data-model.md)
- [API Contracts](./contracts/cloud-functions-api.md)
- [Research](./research.md)
- [Firebase Emulator Docs](https://firebase.google.com/docs/emulator-suite)
- [Riverpod Docs](https://riverpod.dev/)
- [X API v2 Docs](https://developer.twitter.com/en/docs/twitter-api)
- [Threads API Docs](https://developers.facebook.com/docs/threads)
- [Instagram Graph API Docs](https://developers.facebook.com/docs/instagram-api)

---

**🎉 準備完了! 開発開始してください。**
