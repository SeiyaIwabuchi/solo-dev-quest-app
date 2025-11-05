import '../models/answer.dart';

/// 回答リポジトリインターフェース
/// Q&A機能の回答データアクセスを抽象化
abstract class AnswerRepository {
  /// 回答を投稿
  /// 5 DevCoinを獲得してFirestoreに回答を作成
  Future<Answer> postAnswer({
    required String questionId,
    required String body,
  });

  /// 回答詳細を取得
  Future<Answer?> getAnswer(String answerId);

  /// 質問に対する回答一覧を取得
  Future<List<Answer>> getAnswersByQuestion(
    String questionId, {
    String sortBy = 'evaluation_score',
    int limit = 50,
  });

  /// 回答を更新
  Future<void> updateAnswer(
    String answerId, {
    required String body,
  });

  /// 回答を削除（ソフト削除）
  Future<void> deleteAnswer(String answerId);

  /// ベストアンサーを選択
  /// 質問者のみ実行可能、回答者に15 DevCoin付与
  Future<void> selectBestAnswer({
    required String questionId,
    required String answerId,
  });

  /// 回答を評価（役立った/役立たなかった）
  /// 1ユーザー1回答1評価のみ
  Future<void> evaluateAnswer({
    required String answerId,
    required bool isHelpful,
  });

  /// 回答のリアルタイム更新をリッスン
  Stream<List<Answer>> watchAnswersByQuestion(String questionId);
}
