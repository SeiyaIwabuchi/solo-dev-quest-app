import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'answer.freezed.dart';
part 'answer.g.dart';

/// 回答モデル
/// 質問に対する回答を表現
@freezed
class Answer with _$Answer {
  const factory Answer({
    required String answerId,
    required String questionId,
    required String body,
    required String authorId,
    required String authorName,
    String? authorAvatarUrl,
    required DateTime createdAt,
    DateTime? updatedAt,
    required bool isBestAnswer,
    required int helpfulCount,
    required int notHelpfulCount,
    required int evaluationScore,
    required String deletionStatus,
    String? deletionReason,
    DateTime? scheduledDeletionAt,
  }) = _Answer;

  factory Answer.fromJson(Map<String, dynamic> json) =>
      _$AnswerFromJson(json);

  /// FirestoreドキュメントスナップショットからAnswerを生成
  factory Answer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Answer(
      answerId: doc.id,
      questionId: data['questionId'] as String,
      body: data['body'] as String,
      authorId: data['authorId'] as String,
      authorName: data['authorName'] as String,
      authorAvatarUrl: data['authorAvatarUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isBestAnswer: data['isBestAnswer'] as bool,
      helpfulCount: data['helpfulCount'] as int,
      notHelpfulCount: data['notHelpfulCount'] as int,
      evaluationScore: data['evaluationScore'] as int,
      deletionStatus: data['deletionStatus'] as String,
      deletionReason: data['deletionReason'] as String?,
      scheduledDeletionAt: data['scheduledDeletionAt'] != null
          ? (data['scheduledDeletionAt'] as Timestamp).toDate()
          : null,
    );
  }
}
