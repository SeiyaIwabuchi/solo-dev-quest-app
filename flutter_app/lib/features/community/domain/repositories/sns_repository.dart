import '../models/hashtag_post.dart';

/// SNSリポジトリインターフェース
/// 外部SNS統合機能のデータアクセスを抽象化
abstract class SnsRepository {
  /// ハッシュタグタイムラインを取得
  /// X/Threads/Instagramの#個人開発チャレンジ投稿を統合表示
  Future<List<HashtagPost>> fetchHashtagTimeline({
    String hashtag = '個人開発チャレンジ',
    List<String>? providers,
    int limit = 20,
    DateTime? olderThan,
  });

  /// SNSアカウントを連携
  /// OAuth 2.0 PKCEフローでトークン取得・保存
  Future<void> connectSns({
    required String provider,
    required String authorizationCode,
    required String codeVerifier,
  });

  /// SNS連携を解除
  Future<void> disconnectSns(String provider);

  /// SNS連携状態を取得
  Future<Map<String, bool>> getSnsConnectionStatus();

  /// SNSアクションを実行（いいね・リツイート・コメント）
  Future<void> performSnsAction({
    required String postId,
    required String action,
    String? commentText,
  });

  /// ハッシュタグ投稿のリアルタイム更新をリッスン
  Stream<List<HashtagPost>> watchHashtagTimeline({
    String hashtag = '個人開発チャレンジ',
    List<String>? providers,
  });
}
