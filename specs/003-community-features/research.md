# Research: Phase 2 コミュニティ機能

**Date**: 2025-11-04  
**Branch**: `003-community-features`  
**Purpose**: Technical Context内の「NEEDS CLARIFICATION」項目を調査し、実装の技術的実現可能性とベストプラクティスを確立する。

## Research Tasks

### 1. SNS API統合 (X API v2, Threads API, Instagram Graph API)

**Decision**: 
- **X API v2**: `twitter-api-v2` npm package (v1.17.2+) を使用
- **Threads API**: 公式SDKが未成熟のため、REST API直接呼び出し + axios
- **Instagram Graph API**: Facebook公式 `facebook-nodejs-business-sdk` (v20.0.0+) を使用

**Rationale**:
- X API v2は成熟したコミュニティSDK(`twitter-api-v2`)が存在し、OAuth 2.0認証・レート制限管理が組み込み済み
- Threads APIは2023年12月リリースで公式SDK未提供のため、RESTful API直接呼び出しが現実的
- Instagram Graph APIはFacebook公式SDKが最も信頼性が高く、ビジネスアカウント統合が容易

**Authentication Flow**:
1. **OAuth 2.0 PKCE Flow** (すべてのSNS共通)
   - Flutter側: `flutter_appauth` パッケージでOAuth認証フロー実装
   - Cloud Functions側: アクセストークン・リフレッシュトークンをFirestore暗号化保存
   - セキュリティ: `firebase_auth`のカスタムクレームでSNS連携ステータス管理

2. **X (Twitter) 認証**:
   - Client ID/Secretは環境変数 (Firebase Functions Config / Secret Manager)
   - Callback URL: `https://[project-id].firebaseapp.com/__/auth/handler`
   - スコープ: `tweet.read`, `users.read`, `like.write`, `tweet.write`

3. **Threads 認証**:
   - Instagram Business Account経由でThreads APIアクセス
   - スコープ: `threads_basic`, `threads_content_publish`
   - 制約: ビジネスアカウント必須 (個人アカウント不可)

4. **Instagram 認証**:
   - Facebook Appと連携、Instagram Business/Creator Account必須
   - スコープ: `instagram_basic`, `instagram_content_publish`

**Rate Limit Management**:
```typescript
// Cloud Functions実装例
interface RateLimitConfig {
  provider: 'twitter' | 'threads' | 'instagram';
  maxRequests: number; // 500 req/hour
  windowMs: number;    // 3600000 (1時間)
}

class SNSRateLimiter {
  async checkLimit(userId: string, provider: string): Promise<boolean> {
    const doc = await firestore
      .collection('api_rate_limits')
      .doc(`${userId}_${provider}`)
      .get();
    
    const now = Date.now();
    const data = doc.data();
    
    if (!data || now - data.windowStart > this.windowMs) {
      // 新しいウィンドウ
      await doc.ref.set({ windowStart: now, count: 1 });
      return true;
    }
    
    if (data.count >= this.maxRequests) {
      return false; // レート制限到達
    }
    
    await doc.ref.update({ count: admin.firestore.FieldValue.increment(1) });
    return true;
  }
}
```

**Caching Strategy**:
- Redis不使用 (Firebase依存を避ける) → Firestore TTLインデックスでキャッシュ管理
- キャッシュコレクション: `hashtag_posts_cache` (TTL: 5分)
- キャッシュキー: `${hashtag}_${provider}_${timestamp}`

**Alternatives Considered**:
- **Zapier/IFTTT統合**: 遅延が大きく(数分~数時間)、リアルタイム性要件を満たさない
- **Webhook購読**: X APIはEnterprise専用($42,000/月~)、Threads APIはWebhook未対応
- **スクレイピング**: 利用規約違反、API凍結リスク高

**PoC Validation Plan**:
1. X API v2でハッシュタグ検索 (`GET /2/tweets/search/recent`) 実装
2. レート制限テスト (500 req/時到達時の挙動確認)
3. Threads API可用性確認 (公式ドキュメント変更が頻繁なため最新仕様確認)
4. Instagram Graph APIでビジネスアカウント投稿取得テスト

---

### 2. アプリ内課金統合 (App Store / Google Play Billing)

**Decision**: 
- **Flutter Package**: `in_app_purchase` (公式パッケージ v3.1.13+)
- **サブスクリプション管理**: Firebase Extensions `firestore-stripe-payments` は使用せず、StoreKit 2 / Google Play Billing Library 6直接統合
- **検証**: Cloud Functionsで購入レシート検証 (App Store Server API / Google Play Developer API)

**Rationale**:
- `in_app_purchase`はFlutter公式パッケージで、iOS/Android両対応、メンテナンスが安定
- Stripe統合は手数料が高く(2.9% + $0.30 + App Store/Google手数料30%)、アプリ内課金が必須
- レシート検証をCloud Functions側で行うことで不正購入を防止

**Implementation Architecture**:

```dart
// Flutter側実装
class PremiumSubscriptionService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final String productId = 'premium_monthly_680'; // App Store Connect / Play Console登録ID
  
  Future<void> purchasePremium() async {
    final ProductDetailsResponse response = await _iap.queryProductDetails({productId});
    final ProductDetails product = response.productDetails.first;
    
    final PurchaseParam params = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: params);
  }
  
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased) {
        // Cloud Functionsでレシート検証
        _verifyPurchase(purchase);
      }
    }
  }
  
  Future<void> _verifyPurchase(PurchaseDetails purchase) async {
    final callable = FirebaseFunctions.instance.httpsCallable('verifyPremiumPurchase');
    await callable.call({
      'receipt': purchase.verificationData.serverVerificationData,
      'platform': Platform.isIOS ? 'ios' : 'android',
    });
  }
}
```

```typescript
// Cloud Functions実装
export const verifyPremiumPurchase = functions.https.onCall(async (data, context) => {
  const { receipt, platform } = data;
  const userId = context.auth?.uid;
  
  if (platform === 'ios') {
    // App Store Server API検証
    const response = await fetch('https://buy.itunes.apple.com/verifyReceipt', {
      method: 'POST',
      body: JSON.stringify({ 'receipt-data': receipt, password: SHARED_SECRET }),
    });
    const result = await response.json();
    
    if (result.status === 0) {
      // 購入成功、Firestoreに記録
      await admin.firestore().collection('premium_subscriptions').doc(userId).set({
        planType: 'premium',
        startDate: admin.firestore.FieldValue.serverTimestamp(),
        nextRenewalDate: new Date(result.latest_receipt_info.expires_date_ms),
        status: 'active',
      });
      
      // 200 DevCoin付与
      await grantDevCoin(userId, 200, 'free', 'premium_monthly_bonus');
    }
  } else {
    // Google Play Developer API検証
    // (同様の実装)
  }
});
```

**Subscription Status Sync**:
- **App Store Server Notifications V2**: Cloud Functionsエンドポイント `POST /webhook/apple-subscription` でサブスク更新・キャンセル・期限切れを受信
- **Google Real-time Developer Notifications**: Cloud Pub/SubでGoogle Play購読イベントを受信
- 決済失敗時の猶予期間管理: Firestore Scheduled Functionsで毎日1回チェック、7日経過後に特典停止

**Testing Strategy**:
- **Sandbox環境**: App Store Connect Sandbox / Google Play Test Track
- **テストアカウント**: 開発者用Sandboxアカウントで無料テスト購入
- **自動テスト**: `integration_test`でモックIAPプラグイン使用

**Alternatives Considered**:
- **RevenueCat**: サードパーティサブスク管理SaaS、月額$0~$2,500だがベンダーロックインリスク
- **Stripe + Webhookのみ**: App Store/Google Playガイドライン違反でリジェクトリスク

---

### 3. Firestore複合インデックス設計 (質問検索・フィルタリング最適化)

**Decision**:
以下の複合インデックスを`firestore.indexes.json`に定義:

```json
{
  "indexes": [
    {
      "collectionGroup": "questions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "categoryTag", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "questions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "categoryTag", "order": "ASCENDING" },
        { "fieldPath": "answerCount", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "questions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "categoryTag", "order": "ASCENDING" },
        { "fieldPath": "evaluationScore", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "questions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "deletionStatus", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

**Rationale**:
- カテゴリフィルタ + ソート(最新/回答数/評価順)の組み合わせクエリを高速化
- `deletionStatus`インデックスでソフト削除コンテンツを効率的に除外
- 全文検索は初期実装では`title`フィールドの前方一致検索、将来的にAlgolia統合検討

**Query Examples**:
```dart
// カテゴリ「Flutter」、最新順
final query = FirebaseFirestore.instance
  .collection('questions')
  .where('categoryTag', isEqualTo: 'Flutter')
  .where('deletionStatus', isEqualTo: 'normal')
  .orderBy('createdAt', descending: true)
  .limit(20);

// カテゴリ「Firebase」、回答数順
final query = FirebaseFirestore.instance
  .collection('questions')
  .where('categoryTag', isEqualTo: 'Firebase')
  .where('deletionStatus', isEqualTo: 'normal')
  .orderBy('answerCount', descending: true)
  .limit(20);
```

**Performance Expectations**:
- 10,000質問: <1秒
- 100,000質問: <3秒(NFR-002達成)
- ページネーション: `startAfterDocument()`で効率的な無限スクロール

**Alternatives Considered**:
- **Algolia**: 月額$0.50/1,000検索、全文検索機能強力だが初期コスト高
- **Elasticsearch on GCE**: 運用コスト・複雑性が高く、Firebase-First原則に反する

---

### 4. オフライン対応・ローカルキャッシュ戦略

**Decision**:
- **Firestore Persistence**: 有効化 (`FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true)`)
- **追加ローカルストレージ**: 
  - `shared_preferences`: ユーザー設定、最後に閲覧したカテゴリ
  - `sqflite`: 閲覧履歴(過去24時間分)、オフライン時の質問下書き

**Rationale**:
- Firestore Persistenceで自動的にクエリ結果をキャッシュ、オフライン時に再利用
- 画像キャッシュは`cached_network_image`パッケージで自動管理(デフォルト7日保持)
- 下書き機能でオフライン時の投稿データ損失を防止

**Implementation**:
```dart
// 閲覧履歴保存
class ViewHistoryService {
  final Database _db;
  
  Future<void> saveViewedQuestion(Question question) async {
    await _db.insert('view_history', {
      'questionId': question.id,
      'title': question.title,
      'viewedAt': DateTime.now().millisecondsSinceEpoch,
      'cachedData': jsonEncode(question.toJson()),
    });
    
    // 24時間以上古い履歴は削除
    final cutoff = DateTime.now().subtract(Duration(hours: 24)).millisecondsSinceEpoch;
    await _db.delete('view_history', where: 'viewedAt < ?', whereArgs: [cutoff]);
  }
  
  Future<List<Question>> getOfflineQuestions() async {
    final results = await _db.query('view_history', orderBy: 'viewedAt DESC');
    return results.map((row) => Question.fromJson(jsonDecode(row['cachedData']))).toList();
  }
}
```

**Alternatives Considered**:
- **Hive**: NoSQLローカルDB、パフォーマンス高いが`sqflite`で十分
- **Isar**: 次世代ローカルDB、まだベータ版で安定性不明

---

### 5. コンテンツモデレーション・不適切投稿対策

**Decision**:
- **Phase 2初期**: ユーザー報告ベース + 管理者手動審査
- **Phase 3以降**: Google Cloud Natural Language API (Moderate Text)で自動検知

**Rationale**:
- 初期ユーザー数が少ない段階では手動モデレーションが現実的
- AI自動検知は誤検知リスクがあり、ユーザー体験を損なう可能性
- 報告→審査フローを確立してからAI補助を導入

**Manual Moderation Workflow**:
1. ユーザーが「報告」ボタンを押す (質問/回答/コメント)
2. Firestoreに`ContentReport`ドキュメント作成 (審査ステータス: `pending`)
3. 管理者用Webダッシュボード (Firebase Hosting + Admin SDK) で報告一覧を表示
4. 管理者が「承認」→ソフト削除 (7日後完全削除) または「却下」
5. 報告者・投稿者にプッシュ通知 (Firebase Cloud Messaging)

**Automated Moderation (Future)**:
```typescript
// Cloud Functions: 投稿時に自動スキャン
export const scanQuestionContent = functions.firestore
  .document('questions/{questionId}')
  .onCreate(async (snap, context) => {
    const question = snap.data();
    
    // Google Cloud Natural Language API
    const [result] = await languageClient.moderateText({
      document: { content: question.title + ' ' + question.body, type: 'PLAIN_TEXT' },
    });
    
    const categories = result.moderationCategories;
    if (categories.some(c => c.confidence > 0.8 && ['Toxic', 'Profanity'].includes(c.name))) {
      // 高信頼度で有害コンテンツ検出 → 自動ソフト削除
      await snap.ref.update({ deletionStatus: 'soft_deleted', deletionReason: 'auto_moderation' });
      
      // 管理者に通知
      await sendAdminNotification('High-confidence toxic content detected', question.id);
    }
  });
```

**Alternatives Considered**:
- **OpenAI Moderation API**: 無料だが英語特化、日本語精度低い
- **AWS Comprehend**: コスト高 ($0.0001/文字)、Firebase統合複雑

---

## Best Practices Summary

### DevCoin トランザクション管理
```typescript
// Firestoreトランザクションで残高整合性保証
export const postQuestion = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  const { title, body, categoryTag } = data;
  
  return await admin.firestore().runTransaction(async (transaction) => {
    const userRef = admin.firestore().collection('users').doc(userId);
    const userDoc = await transaction.get(userRef);
    
    const balance = userDoc.data()?.devCoinBalance || 0;
    if (balance < 10) {
      throw new functions.https.HttpsError('failed-precondition', 'Insufficient DevCoin balance');
    }
    
    // 残高減算
    transaction.update(userRef, { devCoinBalance: admin.firestore.FieldValue.increment(-10) });
    
    // 質問作成
    const questionRef = admin.firestore().collection('questions').doc();
    transaction.set(questionRef, {
      title,
      body,
      categoryTag,
      authorId: userId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      answerCount: 0,
      deletionStatus: 'normal',
    });
    
    return { questionId: questionRef.id };
  });
});
```

### エラーハンドリング・フォールバック
- SNS APIエラー時: キャッシュデータ表示 + 手動更新ボタン
- Firestore書き込み失敗時: ローカルsqfliteに下書き保存 + リトライキュー
- 画像読み込み失敗時: プレースホルダー画像 + 「再読み込み」ボタン

### セキュリティルール
```javascript
// firestore.rules
match /questions/{questionId} {
  allow read: if resource.data.deletionStatus == 'normal';
  allow create: if request.auth != null 
    && request.resource.data.authorId == request.auth.uid
    && request.resource.data.keys().hasAll(['title', 'body', 'categoryTag']);
  allow update: if request.auth != null 
    && resource.data.authorId == request.auth.uid
    && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['authorId', 'createdAt']);
  allow delete: if false; // 削除は管理者のみ (Cloud Functions経由)
}
```

---

## PoC Validation Checklist

- [ ] X API v2でハッシュタグ検索実装 (レート制限テスト含む)
- [ ] Threads API可用性確認 (2025年Q1時点の最新仕様)
- [ ] Instagram Graph API投稿取得テスト
- [ ] `in_app_purchase`でSandbox購入フロー検証 (iOS/Android)
- [ ] Firestore複合インデックスのクエリパフォーマンス測定 (10,000質問データで2秒以内)
- [ ] オフライン時の閲覧履歴キャッシュ動作確認
- [ ] DevCoinトランザクション並行処理テスト (残高整合性保証)

---

## Dependencies & Integration Points

### Phase 1依存
- `001-user-auth`: Firebase Authentication UID、SNS OAuth連携基盤
- `002-task-management`: DevCoin残高管理、トランザクション処理ロジック
- AI抽象化レイヤー: 既存Claude→GPTフォールバック機構の継承

### External Services
- X API v2 (Twitter Developer Portal登録必須)
- Threads API (Meta Developer登録、Instagram Business Account必須)
- Instagram Graph API (Facebook App作成必須)
- App Store Connect (アプリ内課金商品登録)
- Google Play Console (サブスクリプション商品登録)

### Legal & Compliance
- 利用規約更新: SNSアカウント連携・外部投稿取得・コンテンツ報告に関する条項追加
- プライバシーポリシー更新: SNSアクセストークン保管、外部APIデータ取得に関する記載
- 資金決済法対応: プレミアムプラン月額DevCoinボーナス(無料扱い)は有効期限なし

---

## Conclusion

すべての「NEEDS CLARIFICATION」項目を調査し、実装可能性を確認しました。主要リスクは以下の通り:

1. **SNS API可用性**: Threads APIの仕様変更頻度が高く、PoC検証が必須
2. **レート制限管理**: 500 req/時の上限を超えないキャッシュ戦略が重要
3. **アプリ内課金検証**: Sandbox環境での十分なテストが必要

Phase 1 (データモデル・契約設計)に進む準備が整いました。
