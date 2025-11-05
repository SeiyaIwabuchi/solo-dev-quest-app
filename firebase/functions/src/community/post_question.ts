import * as admin from 'firebase-admin';
import {onCall, HttpsError} from 'firebase-functions/v2/https';
import {Timestamp, FieldValue} from 'firebase-admin/firestore';

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * postQuestion Cloud Function
 * 
 * 技術的質問を投稿し、10 DevCoinを消費する
 * 
 * Firestoreトランザクションで以下を原子的に実行:
 * 1. ユーザーのDevCoin残高チェック (>= 10)
 * 2. DevCoin残高を10減算
 * 3. 質問ドキュメントを作成
 * 4. DevCoinトランザクション履歴を記録
 * 
 * 重複投稿防止:
 * - 同一ユーザーが同一タイトルの質問を5分以内に投稿することを禁止
 */

interface PostQuestionRequest {
  title: string;           // 5~200文字
  body: string;            // 10~10,000文字
  codeExample?: string;    // 0~5,000文字
  categoryTag: 'Flutter' | 'Firebase' | 'Dart' | 'Backend' | 'Design' | 'Other';
}

interface PostQuestionResponse {
  questionId: string;
  remainingDevCoin: number;
}

export const postQuestion = onCall<PostQuestionRequest>(
  {region: 'asia-northeast1'},
  async (request): Promise<PostQuestionResponse> => {
    // 認証チェック
    if (!request.auth) {
      throw new HttpsError(
        'unauthenticated',
        'ユーザー認証が必要です'
      );
    }

    const userId = request.auth.uid;
    const { title, body, codeExample, categoryTag } = request.data;

    // バリデーション
    if (!title || title.length < 5 || title.length > 200) {
      throw new HttpsError(
        'invalid-argument',
        'タイトルは5~200文字である必要があります'
      );
    }

    if (!body || body.length < 10 || body.length > 10000) {
      throw new HttpsError(
        'invalid-argument',
        '質問本文は10~10,000文字である必要があります'
      );
    }

    if (codeExample && codeExample.length > 5000) {
      throw new HttpsError(
        'invalid-argument',
        'コード例は5,000文字以内である必要があります'
      );
    }

    const validCategories = ['Flutter', 'Firebase', 'Dart', 'Backend', 'Design', 'Other'];
    if (!categoryTag || !validCategories.includes(categoryTag)) {
      throw new HttpsError(
        'invalid-argument',
        'カテゴリタグが無効です'
      );
    }

    const db = admin.firestore();

    // 重複投稿チェック（同一タイトル5分制限）
    const fiveMinutesAgo = Timestamp.fromMillis(Date.now() - 5 * 60 * 1000);

    const duplicateCheck = await db
      .collection('questions')
      .where('authorId', '==', userId)
      .where('title', '==', title)
      .where('createdAt', '>', fiveMinutesAgo)
      .where('deletionStatus', '==', 'normal')
      .limit(1)
      .get();

    if (!duplicateCheck.empty) {
      throw new HttpsError(
        'resource-exhausted',
        '同じタイトルの質問は5分以内に投稿できません'
      );
    }

    // ユーザー情報の存在確認のみ実施
    // authorNameとauthorAvatarUrlは表示時に動的に取得する
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new HttpsError(
        'not-found',
        'ユーザー情報が見つかりません'
      );
    }

    // Firestoreトランザクション実行
    try {
      const result = await db.runTransaction(async (transaction) => {
        const userRef = db.collection('users').doc(userId);
        const userSnapshot = await transaction.get(userRef);

        if (!userSnapshot.exists) {
          throw new Error('ユーザーが存在しません');
        }

        const currentBalance = userSnapshot.data()!.devCoinBalance || 0;

        // 残高チェック
        if (currentBalance < 10) {
          throw new Error('DevCoin残高が不足しています');
        }

        // 質問ドキュメント作成
        // authorNameとauthorAvatarUrlは保存せず、表示時に動的に取得
        const questionRef = db.collection('questions').doc();
        const questionData = {
          questionId: questionRef.id,
          title,
          body,
          codeExample: codeExample || null,
          authorId: userId,
          categoryTag,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: null,
          answerCount: 0,
          viewCount: 0,
          evaluationScore: 0,
          bestAnswerId: null,
          deletionStatus: 'normal',
          deletionReason: null,
          scheduledDeletionAt: null,
        };

        transaction.set(questionRef, questionData);

        // DevCoin残高減算
        const newBalance = currentBalance - 10;
        transaction.update(userRef, { devCoinBalance: newBalance });

        // DevCoinトランザクション履歴記録
        const transactionRef = db.collection('devcoin_transactions').doc();
        transaction.set(transactionRef, {
          userId,
          type: 'question_post',
          amount: -10,
          isFree: false,
          relatedId: questionRef.id,
          relatedType: 'question',
          createdAt: FieldValue.serverTimestamp(),
        });

        return {
          questionId: questionRef.id,
          remainingDevCoin: newBalance,
        };
      });

      return result;
    } catch (error: any) {
      if (error.message === 'DevCoin残高が不足しています') {
        throw new HttpsError(
          'failed-precondition',
          'DevCoin残高が不足しています。質問の投稿には10 DevCoinが必要です。'
        );
      }
      throw new HttpsError(
        'internal',
        `質問の投稿に失敗しました: ${error.message}`
      );
    }
  }
);
