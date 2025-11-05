import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/models/question.dart';
import '../../domain/repositories/question_repository.dart';
import '../../../auth/domain/models/user_model.dart';
import '../local/question_cache.dart';

/// 質問リポジトリ実装
/// Firestore + Cloud Functionsを使用したQ&A機能のデータアクセス
/// T038: オフラインキャッシュ統合（過去24時間の質問をローカルに保存）
class QuestionRepositoryImpl implements QuestionRepository {
  QuestionRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
    QuestionCache? cache,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? 
            FirebaseFunctions.instanceFor(region: 'asia-northeast1'),
        _auth = auth ?? FirebaseAuth.instance,
        _cache = cache ?? QuestionCache();

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  final QuestionCache _cache;

  @override
  Future<Question> postQuestion({
    required String title,
    required String body,
    String? codeExample,
    required String categoryTag,
  }) async {
    try {
      // Cloud Functions経由で質問を投稿（DevCoin消費含む）
      final callable = _functions.httpsCallable('postQuestion');
      final result = await callable.call<Map<String, dynamic>>({
        'title': title,
        'body': body,
        'codeExample': codeExample,
        'categoryTag': categoryTag,
      });

      final questionId = result.data['questionId'] as String;

      // 投稿した質問を取得
      final question = await getQuestion(questionId);
      if (question == null) {
        throw Exception('質問の取得に失敗しました');
      }

      return question;
    } on FirebaseFunctionsException catch (e) {
      throw _handleFunctionsException(e);
    } catch (e) {
      throw Exception('質問の投稿に失敗しました: $e');
    }
  }

  @override
  Future<Question?> getQuestion(String questionId) async {
    try {
      final doc =
          await _firestore.collection('questions').doc(questionId).get();

      if (!doc.exists) {
        return null;
      }

      final question = Question.fromFirestore(doc);
      
      // T038: キャッシュに保存（閲覧履歴として記録）
      await _cache.cacheQuestion(question);

      return question;
    } on FirebaseException catch (e) {
      // オフライン時: キャッシュから取得を試みる
      if (e.code == 'unavailable') {
        final cachedQuestion = await _cache.getCachedQuestion(questionId);
        if (cachedQuestion != null) {
          return cachedQuestion;
        }
      }
      throw Exception('質問の取得に失敗しました: $e');
    } catch (e) {
      throw Exception('質問の取得に失敗しました: $e');
    }
  }

  @override
  Future<List<Question>> getQuestions({
    String? categoryTag,
    String sortBy = 'latest',
    int limit = 20,
    String? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('questions')
          .where('deletionStatus', isEqualTo: 'normal');

      // カテゴリフィルター
      if (categoryTag != null) {
        query = query.where('categoryTag', isEqualTo: categoryTag);
      }

      // ソート順序
      switch (sortBy) {
        case 'latest':
          query = query.orderBy('createdAt', descending: true);
          break;
        case 'answer_count':
          query = query.orderBy('answerCount', descending: true);
          break;
        case 'evaluation_score':
          query = query.orderBy('evaluationScore', descending: true);
          break;
      }

      // ページネーション
      if (startAfter != null) {
        final startDoc =
            await _firestore.collection('questions').doc(startAfter).get();
        if (startDoc.exists) {
          query = query.startAfterDocument(startDoc);
        }
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      final questions = snapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();
      
      // T038: 取得した質問をキャッシュに保存
      for (final question in questions) {
        await _cache.cacheQuestion(question);
      }
      
      return questions;
    } on FirebaseException catch (e) {
      // オフライン時: キャッシュから取得を試みる
      if (e.code == 'unavailable') {
        if (categoryTag != null) {
          return await _cache.getCachedQuestionsByCategory(
            categoryTag,
            limit: limit,
          );
        }
        return await _cache.getCachedQuestions(limit: limit);
      }
      throw Exception('質問一覧の取得に失敗しました: $e');
    } catch (e) {
      throw Exception('質問一覧の取得に失敗しました: $e');
    }
  }

  @override
  Future<List<Question>> searchQuestions({
    String? keyword,
    String? categoryTag,
    String sortBy = 'latest',
    int limit = 20,
    String? startAfter,
  }) async {
    try {
      // キーワード検索はCloud Functions経由（将来的にAlgolia統合予定）
      if (keyword != null && keyword.isNotEmpty) {
        final callable = _functions.httpsCallable('searchQuestions');
        final result = await callable.call<Map<String, dynamic>>({
          'keyword': keyword,
          'categoryTag': categoryTag,
          'sortBy': sortBy,
          'limit': limit,
          'startAfter': startAfter,
        });

        final questionsData = result.data['questions'] as List;
        return questionsData
            .map((data) => Question.fromJson(data as Map<String, dynamic>))
            .toList();
      }

      // キーワードなしの場合は通常のgetQuestionsを使用
      return getQuestions(
        categoryTag: categoryTag,
        sortBy: sortBy,
        limit: limit,
        startAfter: startAfter,
      );
    } on FirebaseFunctionsException catch (e) {
      throw _handleFunctionsException(e);
    } catch (e) {
      throw Exception('質問の検索に失敗しました: $e');
    }
  }

  @override
  Future<void> updateQuestion(
    String questionId, {
    String? title,
    String? body,
    String? codeExample,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('ログインが必要です');
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updateData['title'] = title;
      if (body != null) updateData['body'] = body;
      if (codeExample != null) updateData['codeExample'] = codeExample;

      await _firestore.collection('questions').doc(questionId).update(updateData);
    } catch (e) {
      throw Exception('質問の更新に失敗しました: $e');
    }
  }

  @override
  Future<void> deleteQuestion(String questionId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('ログインが必要です');
      }

      // ソフト削除（Cloud Functions経由が望ましいが、ここでは直接更新）
      final scheduledDeletionAt = DateTime.now().add(const Duration(days: 7));

      await _firestore.collection('questions').doc(questionId).update({
        'deletionStatus': 'soft_deleted',
        'deletionReason': 'user_request',
        'scheduledDeletionAt': Timestamp.fromDate(scheduledDeletionAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('質問の削除に失敗しました: $e');
    }
  }

  @override
  Future<void> incrementViewCount(String questionId) async {
    try {
      await _firestore.collection('questions').doc(questionId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      // 閲覧数の更新失敗はサイレントに無視
      print('閲覧数の更新に失敗しました: $e');
    }
  }

  @override
  Stream<Question?> watchQuestion(String questionId) {
    return _firestore
        .collection('questions')
        .doc(questionId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return Question.fromFirestore(doc);
    });
  }

  @override
  Future<UserModel?> getUserInfo(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        return null;
      }
      return UserModel.fromFirestore(doc.data()!);
    } catch (e) {
      print('ユーザー情報の取得に失敗しました: $e');
      return null;
    }
  }

  /// FirebaseFunctionsExceptionを適切なエラーメッセージに変換
  Exception _handleFunctionsException(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return Exception('ログインが必要です');
      case 'failed-precondition':
        return Exception(e.message ?? 'DevCoin残高が不足しています');
      case 'invalid-argument':
        return Exception(e.message ?? '入力内容が不正です');
      case 'resource-exhausted':
        return Exception(e.message ?? '投稿制限に達しました');
      case 'not-found':
        return Exception(e.message ?? 'データが見つかりません');
      default:
        return Exception(e.message ?? 'エラーが発生しました');
    }
  }
}
