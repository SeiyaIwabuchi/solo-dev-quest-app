import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'question.freezed.dart';
part 'question.g.dart';

/// 質問モデル
/// Q&Aプラットフォームの質問を表現
@freezed
class Question with _$Question {
  const factory Question({
    required String questionId,
    required String title,
    required String body,
    String? codeExample,
    required String authorId,
    required String authorName,
    String? authorAvatarUrl,
    required String categoryTag,
    required DateTime createdAt,
    DateTime? updatedAt,
    required int answerCount,
    required int viewCount,
    required int evaluationScore,
    String? bestAnswerId,
    required String deletionStatus,
    String? deletionReason,
    DateTime? scheduledDeletionAt,
  }) = _Question;

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);

  /// FirestoreドキュメントスナップショットからQuestionを生成
  factory Question.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Question(
      questionId: doc.id,
      title: data['title'] as String,
      body: data['body'] as String,
      codeExample: data['codeExample'] as String?,
      authorId: data['authorId'] as String,
      authorName: data['authorName'] as String,
      authorAvatarUrl: data['authorAvatarUrl'] as String?,
      categoryTag: data['categoryTag'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      answerCount: data['answerCount'] as int,
      viewCount: data['viewCount'] as int,
      evaluationScore: data['evaluationScore'] as int,
      bestAnswerId: data['bestAnswerId'] as String?,
      deletionStatus: data['deletionStatus'] as String,
      deletionReason: data['deletionReason'] as String?,
      scheduledDeletionAt: data['scheduledDeletionAt'] != null
          ? (data['scheduledDeletionAt'] as Timestamp).toDate()
          : null,
    );
  }
}

/// 質問のカテゴリタグ
enum QuestionCategory {
  flutter('Flutter'),
  firebase('Firebase'),
  dart('Dart'),
  backend('Backend'),
  design('Design'),
  other('Other');

  const QuestionCategory(this.displayName);
  final String displayName;
}

/// 削除ステータス
enum DeletionStatus {
  normal('normal'),
  softDeleted('soft_deleted'),
  permanentlyDeleted('permanently_deleted');

  const DeletionStatus(this.value);
  final String value;
}
