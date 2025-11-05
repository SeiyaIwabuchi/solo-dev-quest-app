import '../models/question.dart';
import '../../../auth/domain/models/user_model.dart';

/// 質問リポジトリインターフェース
/// Q&A機能の質問データアクセスを抽象化
abstract class QuestionRepository {
  /// ユーザー情報を取得（authorName/authorAvatarUrl取得用）
  Future<UserModel?> getUserInfo(String userId);
  /// 質問を投稿
  /// 10 DevCoinを消費してFirestoreに質問を作成
  Future<Question> postQuestion({
    required String title,
    required String body,
    String? codeExample,
    required String categoryTag,
  });

  /// 質問詳細を取得
  Future<Question?> getQuestion(String questionId);

  /// 質問一覧を取得（ページネーション対応）
  Future<List<Question>> getQuestions({
    String? categoryTag,
    String sortBy = 'latest',
    int limit = 20,
    String? startAfter,
  });

  /// 質問を検索
  Future<List<Question>> searchQuestions({
    String? keyword,
    String? categoryTag,
    String sortBy = 'latest',
    int limit = 20,
    String? startAfter,
  });

  /// 質問を更新
  Future<void> updateQuestion(
    String questionId, {
    String? title,
    String? body,
    String? codeExample,
  });

  /// 質問を削除（ソフト削除）
  Future<void> deleteQuestion(String questionId);

  /// 質問の閲覧数をインクリメント
  Future<void> incrementViewCount(String questionId);

  /// 質問のリアルタイム更新をリッスン
  Stream<Question?> watchQuestion(String questionId);
}
