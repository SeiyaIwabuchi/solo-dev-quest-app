/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import * as admin from "firebase-admin";
import {setGlobalOptions} from "firebase-functions/v2";
import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";

// Initialize Firebase Admin SDK
admin.initializeApp();

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 10});

// ========================
// Type Definitions
// ========================

interface CheckLoginRateLimitRequest {
  email: string;
}

interface CheckLoginRateLimitResponse {
  allowed: boolean;
}

interface LoginLockData {
  failedAttempts: number;
  lastAttemptAt: admin.firestore.Timestamp;
  lockedUntil?: admin.firestore.Timestamp;
}

interface RecordLoginAttemptRequest {
  email: string;
  success: boolean;
}

interface RecordLoginAttemptResponse {
  recorded: boolean;
  failedAttempts?: number;
}

// ========================
// Cloud Functions
// ========================

/**
 * checkLoginRateLimit
 *
 * ログイン試行前にレート制限をチェック。
 * ロック中の場合はエラーを返す。
 *
 * @param request.data.email - ログイン試行するメールアドレス
 * @returns {allowed: true} ログイン試行が許可された
 * @throws {HttpsError} ロック中の場合
 */
export const checkLoginRateLimit = onCall(
  {region: "asia-northeast1"},
  async (
    request: CallableRequest<CheckLoginRateLimitRequest>
  ): Promise<CheckLoginRateLimitResponse> => {
    const {email} = request.data;

    // 入力検証
    if (!email || typeof email !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "メールアドレスが必要です"
      );
    }

    const lockRef = admin.firestore().collection("login_locks").doc(email);
    const lockDoc = await lockRef.get();

    if (!lockDoc.exists) {
      // ロックレコードなし → 許可
      return {allowed: true};
    }

    const lockData = lockDoc.data() as LoginLockData;
    const now = new Date();

    // ロック期間チェック
    if (lockData.lockedUntil && lockData.lockedUntil.toDate() > now) {
      const remainingMs =
        lockData.lockedUntil.toDate().getTime() - now.getTime();
      const remainingMinutes = Math.ceil(remainingMs / 60000);

      throw new HttpsError(
        "permission-denied",
        "セキュリティ上の理由により一時的にログインできません。15分後に再試行してください",
        {
          lockedUntil: lockData.lockedUntil.toDate().toISOString(),
          remainingMinutes,
        }
      );
    }

    // 5回失敗チェック
    if (lockData.failedAttempts >= 5) {
      const lockedUntil = new Date(now.getTime() + 15 * 60 * 1000);

      await lockRef.update({
        lockedUntil: admin.firestore.Timestamp.fromDate(lockedUntil),
      });

      throw new HttpsError(
        "permission-denied",
        "ログイン試行回数が上限に達しました。15分後に再試行してください",
        {
          lockedUntil: lockedUntil.toISOString(),
          remainingMinutes: 15,
        }
      );
    }

    return {allowed: true};
  }
);

/**
 * cleanupExpiredLocks
 *
 * T091: 定期実行ジョブ - 15分以上経過したログインロックを削除
 *
 * スケジュール: 毎時実行 (every 1 hours)
 *
 * 実行内容:
 * - login_locks コレクション内の lockedUntil が現在時刻より過去のドキュメントを削除
 * - バッチ処理でまとめて削除 (最大500件/バッチ)
 *
 * @returns {Promise<void>} 削除完了
 */
export const cleanupExpiredLocks = onSchedule(
  {
    schedule: "every 1 hours",
    region: "asia-northeast1",
    timeZone: "Asia/Tokyo",
  },
  async () => {
    const now = admin.firestore.Timestamp.now();

    // 15分以上経過したロックを検索
    const expiredLocksQuery = admin
      .firestore()
      .collection("login_locks")
      .where("lockedUntil", "<=", now)
      .limit(500);

    const snapshot = await expiredLocksQuery.get();

    if (snapshot.empty) {
      console.log("No expired locks to clean up");
      return;
    }

    // バッチ削除
    const batch = admin.firestore().batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();

    console.log(`Cleaned up ${snapshot.size} expired login locks`);
  }
);

/**
 * recordLoginAttempt
 *
 * ログイン試行結果を記録。
 * 成功時はカウントリセット、失敗時はカウント増加。
 *
 * @param request.data.email - ログイン試行したメールアドレス
 * @param request.data.success - ログイン成功=true, 失敗=false
 * @returns {recorded: true, failedAttempts?: number} 記録完了
 * @throws {HttpsError} 不正な入力の場合
 */
export const recordLoginAttempt = onCall(
  {region: "asia-northeast1"},
  async (
    request: CallableRequest<RecordLoginAttemptRequest>
  ): Promise<RecordLoginAttemptResponse> => {
    const {email, success} = request.data;

    // 入力検証
    if (!email || typeof email !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "メールアドレスが必要です"
      );
    }

    if (typeof success !== "boolean") {
      throw new HttpsError(
        "invalid-argument",
        "success フラグが必要です"
      );
    }

    const lockRef = admin.firestore().collection("login_locks").doc(email);

    if (success) {
      // ログイン成功 → カウントリセット
      await lockRef.delete();
      return {recorded: true};
    } else {
      // ログイン失敗 → カウント増加
      const lockDoc = await lockRef.get();
      const currentAttempts = lockDoc.exists ?
        (lockDoc.data()?.failedAttempts || 0) :
        0;

      await lockRef.set({
        failedAttempts: currentAttempts + 1,
        lastAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      return {
        recorded: true,
        failedAttempts: currentAttempts + 1,
      };
    }
  }
);
