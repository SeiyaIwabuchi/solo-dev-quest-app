# Cloud Functions API Contracts

**Version**: 1.0.0  
**Date**: 2025-11-04  
**Protocol**: Firebase Cloud Functions (HTTPS Callable)

## Authentication

すべてのエンドポイントは`firebase_auth`による認証が必要です。
- Flutterクライアント: `FirebaseFunctions.instance.httpsCallable('functionName')`
- 認証トークンは自動的にリクエストヘッダーに含まれます

---

## 1. Question Management

### 1.1 POST /postQuestion - 質問投稿

**Description**: ユーザーが技術的な質問を投稿し、10 DevCoinを消費する。

**Request**:
```typescript
interface PostQuestionRequest {
  title: string;           // 5~200文字
  body: string;            // 10~10,000文字
  codeExample?: string;    // 0~5,000文字
  categoryTag: 'Flutter' | 'Firebase' | 'Dart' | 'Backend' | 'Design' | 'Other';
}
```

**Response**:
```typescript
interface PostQuestionResponse {
  questionId: string;
  remainingDevCoin: number;
}
```

**Errors**:
- `unauthenticated`: 未認証
- `failed-precondition`: DevCoin残高不足 (< 10)
- `invalid-argument`: バリデーションエラー (タイトル・本文が空、文字数超過等)
- `resource-exhausted`: 重複投稿制限 (同一タイトル5分以内)

**Implementation Notes**:
- Firestoreトランザクションで残高チェック→減算→質問作成を原子的に実行
- 同一タイトルチェックはFirestore `where('title', '==', title)` + `where('authorId', '==', userId)` + `where('createdAt', '>', 5分前)`

---

### 1.2 POST /postAnswer - 回答投稿

**Description**: 質問に対する回答を投稿し、5 DevCoin(無料)を獲得する。

**Request**:
```typescript
interface PostAnswerRequest {
  questionId: string;
  body: string;  // 10~10,000文字
}
```

**Response**:
```typescript
interface PostAnswerResponse {
  answerId: string;
  rewardDevCoin: number;      // 5 (固定)
  totalDevCoin: number;       // 更新後の総DevCoin残高
}
```

**Errors**:
- `unauthenticated`: 未認証
- `not-found`: 質問が存在しない、または削除済み
- `invalid-argument`: バリデーションエラー

**Implementation Notes**:
- トランザクション: 回答作成 → DevCoin付与 → 質問の`answerCount`インクリメント
- DevCoinトランザクション履歴: `{ type: 'answer_reward', amount: 5, isFree: true, questionId, answerId }`

---

### 1.3 POST /selectBestAnswer - ベストアンサー選択

**Description**: 質問者が最も役立った回答をベストアンサーとして選択し、回答者に追加15 DevCoin(無料)を付与。

**Request**:
```typescript
interface SelectBestAnswerRequest {
  questionId: string;
  answerId: string;
}
```

**Response**:
```typescript
interface SelectBestAnswerResponse {
  success: boolean;
  rewardedUserId: string;
  rewardAmount: number;  // 15 (固定)
}
```

**Errors**:
- `unauthenticated`: 未認証
- `permission-denied`: 質問者本人ではない
- `failed-precondition`: 既にベストアンサーが選択済み
- `not-found`: 質問または回答が存在しない

**Implementation Notes**:
- トランザクション: 回答の`isBestAnswer = true` → 質問の`bestAnswerId`更新 → 回答者にDevCoin付与
- 通知: 回答者にプッシュ通知 (Firebase Cloud Messaging)

---

### 1.4 POST /evaluateAnswer - 回答評価

**Description**: ユーザーが回答に対して「役立った」または「役立たなかった」を評価。

**Request**:
```typescript
interface EvaluateAnswerRequest {
  answerId: string;
  isHelpful: boolean;  // true: 役立った, false: 役立たなかった
}
```

**Response**:
```typescript
interface EvaluateAnswerResponse {
  success: boolean;
  newEvaluationScore: number;  // 更新後の評価スコア
}
```

**Errors**:
- `unauthenticated`: 未認証
- `already-exists`: 既に評価済み (1ユーザー1回答1評価)
- `not-found`: 回答が存在しない

**Implementation Notes**:
- `answer_evaluations`に`{userId}_{answerId}`で評価記録を作成
- トランザクション: 評価記録作成 → 回答の`helpfulCount`または`notHelpfulCount`インクリメント → `evaluationScore`更新

---

### 1.5 GET /searchQuestions - 質問検索

**Description**: キーワード検索・カテゴリフィルタ・ソート条件で質問を検索。

**Request**:
```typescript
interface SearchQuestionsRequest {
  keyword?: string;           // タイトルフィールドの前方一致検索（部分一致は不可。例: keyword="Fire"は"Firebase"にマッチするが、"base"ではマッチしない）。将来的にAlgolia統合で全文検索対応予定
  categoryTag?: string;       // カテゴリフィルタ
  sortBy: 'latest' | 'answer_count' | 'evaluation_score';
  limit?: number;             // デフォルト: 20, 最大: 50
  startAfter?: string;        // ページネーション用ドキュメントID
}
```

**Response**:
```typescript
interface SearchQuestionsResponse {
  questions: Array<{
    questionId: string;
    title: string;
    body: string;
    authorName: string;
    authorAvatarUrl?: string;
    categoryTag: string;
    createdAt: string;       // ISO 8601
    answerCount: number;
    viewCount: number;
    evaluationScore: number;
    hasBestAnswer: boolean;
  }>;
  hasMore: boolean;          // 次のページが存在するか
  nextPageToken?: string;    // 次ページ取得用トークン
}
```

**Errors**:
- `unauthenticated`: 未認証
- `invalid-argument`: バリデーションエラー (limitが範囲外等)

**Implementation Notes**:
- Firestore複合インデックスを活用 (categoryTag + sortBy順序)
- キーワード検索は初期実装では`title`フィールドの前方一致 (`where('title', '>=', keyword)`)
- ページネーション: `startAfterDocument()`使用。`nextPageToken`は最後のドキュメントIDをBase64エンコードした文字列。クライアントは次ページ取得時にこのトークンを`startAfter`パラメータに渡す

---

## 2. Community Interaction

### 2.1 POST /postComment - コメント投稿

**Description**: 質問または回答にコメントを投稿。

**Request**:
```typescript
interface PostCommentRequest {
  targetType: 'question' | 'answer';
  targetId: string;
  body?: string;              // カスタムコメント (1~500文字)
  templateType?: 'encouragement' | 'helpful' | 'question';  // テンプレート種別
}
```

**Response**:
```typescript
interface PostCommentResponse {
  commentId: string;
}
```

**Errors**:
- `unauthenticated`: 未認証
- `invalid-argument`: `body`と`templateType`両方未指定、または文字数超過
- `not-found`: 対象が存在しない

**Implementation Notes**:
- テンプレート展開: サーバー側で`templateType`を実際の日本語テキストに変換
- 通知: 対象の投稿者にプッシュ通知

---

### 2.2 POST /reportContent - コンテンツ報告

**Description**: 不適切なコンテンツ(質問・回答・コメント)を報告。

**Request**:
```typescript
interface ReportContentRequest {
  targetType: 'question' | 'answer' | 'comment';
  targetId: string;
  reason: 'spam' | 'harassment' | 'inappropriate' | 'other';
  reasonDetail?: string;  // 0~500文字
}
```

**Response**:
```typescript
interface ReportContentResponse {
  reportId: string;
  message: string;  // "報告を受け付けました。24時間以内に審査いたします。"
}
```

**Errors**:
- `unauthenticated`: 未認証
- `already-exists`: 同じ対象を既に報告済み
- `not-found`: 対象が存在しない

**Implementation Notes**:
- `content_reports`コレクションに報告記録を作成 (`reviewStatus: 'pending'`)
- 管理者用Webダッシュボードで審査 (別途実装)

---

## 3. SNS Integration

### 3.1 POST /fetchHashtagTimeline - ハッシュタグタイムライン取得

**Description**: 外部SNS(X/Threads/Instagram)の#個人開発チャレンジ投稿を取得。

**Request**:
```typescript
interface FetchHashtagTimelineRequest {
  hashtag: string;           // デフォルト: "個人開発チャレンジ"
  providers?: Array<'twitter' | 'threads' | 'instagram'>;  // デフォルト: 全て
  limit?: number;            // デフォルト: 20, 最大: 50
  olderThan?: string;        // ページネーション用タイムスタンプ (ISO 8601)
}
```

**Response**:
```typescript
interface FetchHashtagTimelineResponse {
  posts: Array<{
    postId: string;
    provider: 'twitter' | 'threads' | 'instagram';
    authorName: string;
    authorUsername: string;
    authorAvatarUrl?: string;
    body: string;
    mediaUrls?: string[];
    postedAt: string;        // ISO 8601
    originalUrl: string;
    likeCount?: number;
    repostCount?: number;
  }>;
  hasMore: boolean;
  cacheStatus: {
    twitter: 'available' | 'rate_limited' | 'error';      // available: 正常取得, rate_limited: レート制限到達（キャッシュ返却）, error: API障害
    threads: 'available' | 'rate_limited' | 'error';
    instagram: 'available' | 'rate_limited' | 'error';
  };
}
```

**Errors**:
- `unauthenticated`: 未認証
- `resource-exhausted`: レート制限到達 (500 req/時)

**Implementation Notes**:
- キャッシュ優先: `hashtag_posts`コレクションの`fetchedAt`が5分以内ならキャッシュから返却
- レート制限チェック: `api_rate_limits`コレクションで各プロバイダーのリクエスト数を管理
- API障害時: 利用可能なプロバイダーのみ取得、`cacheStatus`で状態を返す

---

### 3.2 POST /connectSNS - SNSアカウント連携

**Description**: OAuth認証でSNSアカウントを連携。

**Request**:
```typescript
interface ConnectSNSRequest {
  provider: 'twitter' | 'threads' | 'instagram';
  authorizationCode: string;  // OAuthコールバックで取得したコード
  codeVerifier: string;       // PKCE用
}
```

**Response**:
```typescript
interface ConnectSNSResponse {
  success: boolean;
  providerUserId: string;
  providerUsername: string;
}
```

**Errors**:
- `unauthenticated`: 未認証
- `invalid-argument`: 認証コードが無効
- `already-exists`: 既に連携済み

**Implementation Notes**:
- OAuth 2.0 PKCEフローでアクセストークン取得
- トークンを暗号化して`sns_connections`に保存
- リフレッシュトークンで自動更新 (有効期限前に更新)

---

### 3.3 POST /performSNSAction - SNSアクション実行

**Description**: アプリ内から外部SNS投稿にいいね・リツイート・コメント。

**Request**:
```typescript
interface PerformSNSActionRequest {
  postId: string;            // hashtag_postsのpostId
  action: 'like' | 'retweet' | 'comment';
  commentText?: string;      // action='comment'時に必須（1~500文字）。action='like'または'retweet'時は不要
}
```

**Response**:
```typescript
interface PerformSNSActionResponse {
  success: boolean;
  message: string;
}
```

**Errors**:
- `unauthenticated`: 未認証
- `failed-precondition`: SNSアカウント未連携
- `resource-exhausted`: レート制限到達
- `permission-denied`: アクション実行権限なし (例: 鍵アカウント)

**Implementation Notes**:
- `sns_connections`から該当プロバイダーのアクセストークン取得
- 各SNS APIを呼び出し: X API `POST /2/tweets/:id/liking_users`, Threads API, Instagram Graph API
- アクション記録: `sns_interactions`コレクション (将来的な分析用)

---

## 4. Premium Subscription

### 4.1 POST /verifyPremiumPurchase - プレミアムプラン購入検証

**Description**: App Store / Google Playの購入レシートを検証し、サブスクリプションを有効化。

**Request**:
```typescript
interface VerifyPremiumPurchaseRequest {
  platform: 'ios' | 'android';
  receipt: string;           // iOS: receiptData, Android: purchaseToken
  productId: string;         // 'premium_monthly_680'
}
```

**Response**:
```typescript
interface VerifyPremiumPurchaseResponse {
  success: boolean;
  subscriptionStatus: 'active' | 'cancelled' | 'expired';
  currentPeriodEnd: string;  // ISO 8601
  devCoinGranted: number;    // 200 (初回のみ)
}
```

**Errors**:
- `unauthenticated`: 未認証
- `invalid-argument`: レシートが無効。詳細理由: `RECEIPT_EXPIRED`（有効期限切れ）, `RECEIPT_ALREADY_USED`（既に使用済み）, `RECEIPT_INVALID_FORMAT`（フォーマット不正）, `PRODUCT_ID_MISMATCH`（商品IDが一致しない）
- `already-exists`: 既にサブスクリプション有効

**Implementation Notes**:
- iOS: App Store Server API `POST /verifyReceipt` で検証
- Android: Google Play Developer API `GET /purchases/subscriptionsv2/:token` で検証
- 検証成功: `premium_subscriptions`作成 + 200 DevCoin(無料)付与

---

### 4.2 POST /webhook/appleSubscription - App Storeサブスク通知

**Description**: App Store Server Notifications V2を受信し、サブスク状態を更新。

**Request**: (App Storeから自動送信)
```typescript
// Apple通知ペイロード (JWS署名検証必須)
interface AppleNotificationPayload {
  notificationType: 'DID_RENEW' | 'DID_FAIL_TO_RENEW' | 'DID_CHANGE_RENEWAL_STATUS' | ...;
  data: {
    signedTransactionInfo: string;  // JWS
  };
}
```

**Implementation Notes**:
- JWS署名検証 (Apple公開鍵で検証)
- `DID_RENEW`: サブスク更新、200 DevCoin付与
- `DID_FAIL_TO_RENEW`: 決済失敗、猶予期間開始 (`status: 'payment_failed_grace'`)
- `DID_CHANGE_RENEWAL_STATUS` (cancelled): キャンセル (`status: 'cancelled'`)

---

### 4.3 POST /webhook/googleSubscription - Google Playサブスク通知

**Description**: Google Real-time Developer Notificationsを受信 (Cloud Pub/Sub経由)。

**Request**: (Google Playから自動送信)
```typescript
interface GoogleNotificationPayload {
  subscriptionNotification: {
    notificationType: number;  // 1: RECOVERED, 2: RENEWED, 4: CANCELED, 13: EXPIRED, ...
    purchaseToken: string;
  };
}
```

**Implementation Notes**:
- Cloud Pub/Subトピック購読
- 通知タイプに応じてサブスク状態更新
- 詳細情報はGoogle Play Developer APIで追加取得

---

## 5. Scheduled Functions

### 5.1 scheduledDeleteExpiredContent - 期限切れコンテンツ削除

**Schedule**: 毎日午前3時 (JST)

**Description**: ソフト削除から7日経過したコンテンツを完全削除。

**Implementation**:
```typescript
export const scheduledDeleteExpiredContent = functions.pubsub
  .schedule('0 3 * * *')
  .timeZone('Asia/Tokyo')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const cutoff = new Date(now.toMillis() - 7 * 24 * 60 * 60 * 1000);
    
    // 質問・回答・コメントで scheduledDeletionAt < cutoff のものを完全削除
    const questionsSnapshot = await admin.firestore()
      .collection('questions')
      .where('scheduledDeletionAt', '<', cutoff)
      .get();
    
    const batch = admin.firestore().batch();
    questionsSnapshot.docs.forEach(doc => {
      batch.update(doc.ref, { deletionStatus: 'permanently_deleted' });
    });
    await batch.commit();
  });
```

---

### 5.2 scheduledCheckPremiumPaymentFailed - プレミアム決済失敗チェック

**Schedule**: 毎日午前0時 (JST)

**Description**: 決済失敗から7日経過したサブスクを期限切れに変更。

**Implementation**:
```typescript
export const scheduledCheckPremiumPaymentFailed = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('Asia/Tokyo')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    
    const snapshot = await admin.firestore()
      .collection('premium_subscriptions')
      .where('status', '==', 'payment_failed_grace')
      .where('gracePeriodEnd', '<', now)
      .get();
    
    const batch = admin.firestore().batch();
    snapshot.docs.forEach(doc => {
      batch.update(doc.ref, { status: 'expired' });
    });
    await batch.commit();
    
    // ユーザーに通知: "プレミアムプランが期限切れになりました"
  });
```

---

### 5.3 scheduledCleanupHashtagCache - ハッシュタグキャッシュクリーンアップ

**Schedule**: 5分ごと

**Description**: `fetchedAt`から5分以上経過したハッシュタグ投稿キャッシュを削除。

**Implementation**:
```typescript
export const scheduledCleanupHashtagCache = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const cutoff = new Date(now.toMillis() - 5 * 60 * 1000);
    
    const snapshot = await admin.firestore()
      .collection('hashtag_posts')
      .where('fetchedAt', '<', cutoff)
      .get();
    
    const batch = admin.firestore().batch();
    snapshot.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
  });
```

---

## Error Handling Standards

すべてのエンドポイントで統一されたエラーレスポンス:

```typescript
interface ErrorResponse {
  code: 'unauthenticated' | 'permission-denied' | 'not-found' | 'already-exists' | 
        'invalid-argument' | 'failed-precondition' | 'resource-exhausted' | 'internal';
  message: string;  // 日本語エラーメッセージ
  details?: {
    retryAfter?: string;  // レート制限エラー時の再試行可能時刻（ISO 8601形式、例: "2025-11-05T15:30:00Z"）
    [key: string]: any;   // その他の追加情報（開発環境のみ）
  };
}
```

**Client-Side Error Handling**:
```dart
try {
  final result = await FirebaseFunctions.instance
    .httpsCallable('postQuestion')
    .call(request);
} on FirebaseFunctionsException catch (e) {
  switch (e.code) {
    case 'failed-precondition':
      // DevCoin不足ダイアログ表示
      break;
    case 'resource-exhausted':
      // "投稿制限に達しました" メッセージ
      break;
    default:
      // 一般エラー
  }
}
```

---

## Rate Limiting

| Endpoint | Limit | Window |
|----------|-------|--------|
| postQuestion | 10回/時 | 1時間 |
| postAnswer | 30回/時 | 1時間 |
| fetchHashtagTimeline | 50回/時 (全プロバイダー合計500 req) | 1時間 |
| performSNSAction | 100回/時 | 1時間 |

**Implementation**: Firestore `api_rate_limits`コレクションでユーザーごとに管理。

---

## Testing

### Unit Tests (Functions)
```bash
cd functions
npm test
```

### Integration Tests (Emulator)
```bash
firebase emulators:start
cd flutter_app
flutter test integration_test/
```

### E2E Tests (実環境)
- Sandbox環境 (App Store Connect, Google Play Test Track)
- テストユーザーアカウント

---

## Versioning

- **API Version**: ヘッダー不要 (単一バージョン)
- **Breaking Changes**: 新関数名でデプロイ (`postQuestionV2`)、旧関数は1ヶ月後に廃止
