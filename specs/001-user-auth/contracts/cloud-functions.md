# API Contracts: User Authentication

**Feature**: 001-user-auth  
**Date**: 2025-11-01  
**Type**: Cloud Functions for Firebase (HTTPS Callable)

## Overview

認証機能で使用するCloud Functions API。ブルートフォース攻撃対策のためのレート制限管理を提供。

---

## Function 1: checkLoginRateLimit

ログイン試行前にレート制限をチェック。ロック中の場合はエラーを返す。

### Endpoint
```
HTTPS Callable Function
Region: asia-northeast1 (Tokyo)
```

### Request
```typescript
interface CheckLoginRateLimitRequest {
  email: string; // ログイン試行するメールアドレス
}
```

### Response (Success)
```typescript
interface CheckLoginRateLimitResponse {
  allowed: boolean; // true固定(ロック中の場合は例外スロー)
}
```

### Response (Error)
```typescript
{
  code: 'permission-denied',
  message: string, // エラーメッセージ
  details?: {
    lockedUntil: string, // ISO 8601形式のロック解除時刻
    remainingMinutes: number // 残りロック時間(分)
  }
}
```

### Error Messages
- `"セキュリティ上の理由により一時的にログインできません。15分後に再試行してください"` (ロック中)
- `"ログイン試行回数が上限に達しました。15分後に再試行してください"` (5回失敗時)

### Business Logic
```typescript
export const checkLoginRateLimit = functions
  .region('asia-northeast1')
  .https.onCall(async (data: CheckLoginRateLimitRequest, context) => {
    const { email } = data;
    
    // 入力検証
    if (!email || typeof email !== 'string') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'メールアドレスが必要です'
      );
    }
    
    const lockRef = admin.firestore().collection('login_locks').doc(email);
    const lockDoc = await lockRef.get();
    
    if (!lockDoc.exists) {
      // ロックレコードなし → 許可
      return { allowed: true };
    }
    
    const lockData = lockDoc.data();
    const now = new Date();
    
    // ロック期間チェック
    if (lockData.lockedUntil && lockData.lockedUntil.toDate() > now) {
      const remainingMs = lockData.lockedUntil.toDate().getTime() - now.getTime();
      const remainingMinutes = Math.ceil(remainingMs / 60000);
      
      throw new functions.https.HttpsError(
        'permission-denied',
        'セキュリティ上の理由により一時的にログインできません。15分後に再試行してください',
        {
          lockedUntil: lockData.lockedUntil.toDate().toISOString(),
          remainingMinutes
        }
      );
    }
    
    // 5回失敗チェック
    if (lockData.failedAttempts >= 5) {
      const lockedUntil = new Date(now.getTime() + 15 * 60 * 1000);
      
      await lockRef.update({
        lockedUntil: admin.firestore.Timestamp.fromDate(lockedUntil)
      });
      
      throw new functions.https.HttpsError(
        'permission-denied',
        'ログイン試行回数が上限に達しました。15分後に再試行してください',
        {
          lockedUntil: lockedUntil.toISOString(),
          remainingMinutes: 15
        }
      );
    }
    
    return { allowed: true };
  });
```

### Example Usage (Flutter)
```dart
final callable = FirebaseFunctions.instance
    .httpsCallable('checkLoginRateLimit');

try {
  final result = await callable.call({
    'email': 'user@example.com',
  });
  
  if (result.data['allowed'] == true) {
    // ログイン試行許可
    await _attemptLogin();
  }
} on FirebaseFunctionsException catch (e) {
  if (e.code == 'permission-denied') {
    // ロック中エラー表示
    _showErrorDialog(e.message);
  }
}
```

---

## Function 2: recordLoginAttempt

ログイン試行結果を記録。成功時はカウントリセット、失敗時はカウント増加。

### Endpoint
```
HTTPS Callable Function
Region: asia-northeast1 (Tokyo)
```

### Request
```typescript
interface RecordLoginAttemptRequest {
  email: string;   // ログイン試行したメールアドレス
  success: boolean; // ログイン成功=true, 失敗=false
}
```

### Response
```typescript
interface RecordLoginAttemptResponse {
  recorded: boolean; // true固定
  failedAttempts?: number; // 失敗時の現在の失敗回数
}
```

### Business Logic
```typescript
export const recordLoginAttempt = functions
  .region('asia-northeast1')
  .https.onCall(async (data: RecordLoginAttemptRequest, context) => {
    const { email, success } = data;
    
    // 入力検証
    if (!email || typeof email !== 'string') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'メールアドレスが必要です'
      );
    }
    
    if (typeof success !== 'boolean') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'success フラグが必要です'
      );
    }
    
    const lockRef = admin.firestore().collection('login_locks').doc(email);
    
    if (success) {
      // ログイン成功 → カウントリセット
      await lockRef.delete();
      return { recorded: true };
    } else {
      // ログイン失敗 → カウント増加
      const lockDoc = await lockRef.get();
      const currentAttempts = lockDoc.exists 
        ? (lockDoc.data()?.failedAttempts || 0) 
        : 0;
      
      await lockRef.set({
        failedAttempts: currentAttempts + 1,
        lastAttemptAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      
      return { 
        recorded: true, 
        failedAttempts: currentAttempts + 1 
      };
    }
  });
```

### Example Usage (Flutter)
```dart
// ログイン成功時
await FirebaseFunctions.instance
    .httpsCallable('recordLoginAttempt')
    .call({
      'email': email,
      'success': true,
    });

// ログイン失敗時
try {
  await FirebaseFunctions.instance
      .httpsCallable('recordLoginAttempt')
      .call({
        'email': email,
        'success': false,
      });
} catch (e) {
  // エラーハンドリング
}
```

---

## Function 3: cleanupExpiredLocks (Scheduled)

15分以上経過したロックレコードを定期的にクリーンアップ。

### Trigger
```
Cloud Scheduler (Cron)
Schedule: every 1 hours
Region: asia-northeast1 (Tokyo)
```

### Business Logic
```typescript
export const cleanupExpiredLocks = functions
  .region('asia-northeast1')
  .pubsub.schedule('every 1 hours')
  .timeZone('Asia/Tokyo')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const locksRef = admin.firestore().collection('login_locks');
    
    // 15分以上前のロックをクエリ
    const expiredLocks = await locksRef
      .where('lockedUntil', '<=', now)
      .get();
    
    // バッチ削除
    const batch = admin.firestore().batch();
    expiredLocks.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();
    
    console.log(`Cleaned up ${expiredLocks.size} expired login locks`);
    return null;
  });
```

---

## Security

### Authentication Requirements
- すべてのHTTPS Callable Functionsは認証不要(ログイン前に呼び出されるため)
- ただし、レート制限により悪用を防止

### Input Validation
- すべての入力パラメータで型チェック実施
- メールアドレス形式検証(RFC 5322)
- 不正な入力は`invalid-argument`エラーを返す

### Rate Limiting
- Cloud FunctionsのデフォルトレートリミットExpress limits:
  - 1000 requests/100 seconds per region
  - 100 concurrent requests
- 追加のアプリケーションレベルレート制限は未実装(Phase 0では不要)

---

## Error Handling

### Error Codes
| Code | Description | Handling |
|------|-------------|----------|
| `permission-denied` | ログインロック中 | ユーザーに待機メッセージ表示 |
| `invalid-argument` | 不正なパラメータ | 開発者向けエラー(通常発生しない) |
| `internal` | サーバー内部エラー | リトライ可能エラー |
| `unavailable` | Firestore一時的に利用不可 | リトライ可能エラー |

### Retry Strategy (Flutter側)
```dart
Future<T> retryCallableFunction<T>(
  HttpsCallable callable,
  Map<String, dynamic> params, {
  int maxRetries = 3,
}) async {
  int attempt = 0;
  
  while (attempt < maxRetries) {
    try {
      final result = await callable.call(params);
      return result.data as T;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unavailable' || e.code == 'internal') {
        attempt++;
        if (attempt >= maxRetries) rethrow;
        await Future.delayed(Duration(seconds: 2 * attempt));
      } else {
        rethrow; // permission-denied等はリトライ不要
      }
    }
  }
  
  throw Exception('Max retries exceeded');
}
```

---

## Testing

### Unit Tests (Functions)
```typescript
// functions/test/auth-rate-limit.test.ts
import * as admin from 'firebase-admin';
import * as test from 'firebase-functions-test';

describe('checkLoginRateLimit', () => {
  it('should allow login when no lock exists', async () => {
    const result = await wrapped({ email: 'test@example.com' });
    expect(result.allowed).toBe(true);
  });

  it('should deny login when locked', async () => {
    // ロックレコード作成
    await admin.firestore().collection('login_locks').doc('test@example.com').set({
      failedAttempts: 5,
      lockedUntil: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 10 * 60 * 1000)
      )
    });
    
    // ロック中エラー期待
    await expect(wrapped({ email: 'test@example.com' }))
      .rejects.toThrow('permission-denied');
  });
});
```

### Integration Tests (Flutter)
```dart
testWidgets('ログイン試行5回失敗でロック', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // 5回ログイン失敗
  for (int i = 0; i < 5; i++) {
    await tester.enterText(find.byKey(Key('email')), 'test@example.com');
    await tester.enterText(find.byKey(Key('password')), 'wrongpassword');
    await tester.tap(find.text('ログイン'));
    await tester.pumpAndSettle();
  }
  
  // 6回目でロックメッセージ表示
  await tester.enterText(find.byKey(Key('email')), 'test@example.com');
  await tester.enterText(find.byKey(Key('password')), 'wrongpassword');
  await tester.tap(find.text('ログイン'));
  await tester.pumpAndSettle();
  
  expect(find.text('15分後に再試行してください'), findsOneWidget);
});
```

---

## Deployment

### Firebase Functions Deploy
```bash
# 初回デプロイ
cd functions
npm install
npm run build
firebase deploy --only functions

# 特定関数のみデプロイ
firebase deploy --only functions:checkLoginRateLimit,functions:recordLoginAttempt
```

### Environment Variables
```bash
# .env (ローカル開発用)
FIREBASE_PROJECT_ID=solo-dev-quest-dev

# 本番環境変数設定
firebase functions:config:set app.environment=production
```

---

## Monitoring

### Logs
```bash
# リアルタイムログ監視
firebase functions:log --only checkLoginRateLimit

# エラーログフィルタ
firebase functions:log --only checkLoginRateLimit | grep ERROR
```

### Metrics (Firebase Console)
- Invocations/minute
- Error rate
- Execution time (p50, p95, p99)
- Active instances
