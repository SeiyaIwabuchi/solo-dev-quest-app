// T035: Analytics service for tracking user events
import 'package:firebase_analytics/firebase_analytics.dart';

/// Firebase Analytics イベント送信サービス
/// 
/// Phase 2 Community Features の分析イベント:
/// - question_posted: 質問投稿時
/// - question_viewed: 質問詳細閲覧時
class CommunityAnalyticsService {
  final FirebaseAnalytics _analytics;

  CommunityAnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  /// 質問投稿イベント
  /// 
  /// Parameters:
  /// - questionId: 投稿された質問のID
  /// - categoryTag: 選択されたカテゴリ
  /// - hasCodeExample: コード例が含まれているか
  Future<void> logQuestionPosted({
    required String questionId,
    required String categoryTag,
    required bool hasCodeExample,
  }) async {
    await _analytics.logEvent(
      name: 'question_posted',
      parameters: {
        'question_id': questionId,
        'category_tag': categoryTag,
        'has_code_example': hasCodeExample ? 'yes' : 'no',
      },
    );
  }

  /// 質問閲覧イベント
  /// 
  /// Parameters:
  /// - questionId: 閲覧された質問のID
  /// - categoryTag: 質問のカテゴリ
  /// - hasAnswer: 回答が存在するか
  /// - viewSource: 閲覧元 (list: 一覧から, direct: 直接リンク, notification: 通知から)
  Future<void> logQuestionViewed({
    required String questionId,
    required String categoryTag,
    required bool hasAnswer,
    String viewSource = 'list',
  }) async {
    await _analytics.logEvent(
      name: 'question_viewed',
      parameters: {
        'question_id': questionId,
        'category_tag': categoryTag,
        'has_answer': hasAnswer ? 'yes' : 'no',
        'view_source': viewSource,
      },
    );
  }

  /// スクリーン表示イベント (自動追跡用)
  /// 
  /// Parameters:
  /// - screenName: 画面名 (例: question_list, question_detail, question_post)
  /// - screenClass: 画面クラス名 (Flutter widget名)
  Future<void> logScreenView({
    required String screenName,
    required String screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }
}
