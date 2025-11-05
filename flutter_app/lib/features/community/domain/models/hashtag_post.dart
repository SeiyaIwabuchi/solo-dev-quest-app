import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'hashtag_post.freezed.dart';
part 'hashtag_post.g.dart';

/// ハッシュタグ投稿モデル
/// 外部SNS(X/Threads/Instagram)の投稿を表現
@freezed
class HashtagPost with _$HashtagPost {
  const factory HashtagPost({
    required String postId,
    required String provider,
    required String originalPostId,
    required String authorName,
    required String authorUsername,
    String? authorAvatarUrl,
    required String body,
    List<String>? mediaUrls,
    required DateTime postedAt,
    required DateTime fetchedAt,
    required String originalUrl,
    int? likeCount,
    int? repostCount,
  }) = _HashtagPost;

  factory HashtagPost.fromJson(Map<String, dynamic> json) =>
      _$HashtagPostFromJson(json);

  /// FirestoreドキュメントスナップショットからHashtagPostを生成
  factory HashtagPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HashtagPost(
      postId: doc.id,
      provider: data['provider'] as String,
      originalPostId: data['originalPostId'] as String,
      authorName: data['authorName'] as String,
      authorUsername: data['authorUsername'] as String,
      authorAvatarUrl: data['authorAvatarUrl'] as String?,
      body: data['body'] as String,
      mediaUrls: data['mediaUrls'] != null
          ? List<String>.from(data['mediaUrls'] as List)
          : null,
      postedAt: (data['postedAt'] as Timestamp).toDate(),
      fetchedAt: (data['fetchedAt'] as Timestamp).toDate(),
      originalUrl: data['originalUrl'] as String,
      likeCount: data['likeCount'] as int?,
      repostCount: data['repostCount'] as int?,
    );
  }
}

/// SNSプロバイダー
enum SnsProvider {
  twitter('twitter', 'X (Twitter)', 'https://x.com'),
  threads('threads', 'Threads', 'https://threads.net'),
  instagram('instagram', 'Instagram', 'https://instagram.com');

  const SnsProvider(this.value, this.displayName, this.baseUrl);
  final String value;
  final String displayName;
  final String baseUrl;
}
