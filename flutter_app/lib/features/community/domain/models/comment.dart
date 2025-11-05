import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

/// コメントモデル
/// 質問・回答に対するコメントを表現
@freezed
class Comment with _$Comment {
  const factory Comment({
    required String commentId,
    required String targetType,
    required String targetId,
    required String body,
    String? templateType,
    required String authorId,
    required String authorName,
    String? authorAvatarUrl,
    required DateTime createdAt,
    required String deletionStatus,
    String? deletionReason,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);

  /// FirestoreドキュメントスナップショットからCommentを生成
  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      commentId: doc.id,
      targetType: data['targetType'] as String,
      targetId: data['targetId'] as String,
      body: data['body'] as String,
      templateType: data['templateType'] as String?,
      authorId: data['authorId'] as String,
      authorName: data['authorName'] as String,
      authorAvatarUrl: data['authorAvatarUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      deletionStatus: data['deletionStatus'] as String,
      deletionReason: data['deletionReason'] as String?,
    );
  }
}

/// コメント対象種別
enum CommentTargetType {
  question('question'),
  answer('answer');

  const CommentTargetType(this.value);
  final String value;
}

/// コメントテンプレート種別
enum CommentTemplateType {
  encouragement('encouragement', '頑張ってください!'),
  helpful('helpful', '参考になりました'),
  question('question', '詳細を教えてください');

  const CommentTemplateType(this.value, this.text);
  final String value;
  final String text;
}
