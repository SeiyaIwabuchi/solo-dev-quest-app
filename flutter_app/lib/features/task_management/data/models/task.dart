import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'task.freezed.dart';
part 'task.g.dart';

/// タスクモデル
@freezed
class Task with _$Task {
  const factory Task({
    /// タスクID
    required String id,

    /// プロジェクトID（外部キー）
    required String projectId,

    /// ユーザーID（所有者）
    required String userId,

    /// タスク名（1-200文字）
    required String name,

    /// タスク説明（0-1000文字、オプション）
    String? description,

    /// 期限（オプション）
    DateTime? dueDate,

    /// 完了フラグ
    required bool isCompleted,

    /// 作成日時
    required DateTime createdAt,

    /// 更新日時
    required DateTime updatedAt,

    /// 完了日時（完了時のみ）
    DateTime? completedAt,
  }) = _Task;

  const Task._();

  /// JSONからTaskオブジェクトを生成
  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  /// FirestoreドキュメントからTaskオブジェクトを生成
  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      projectId: data['projectId'] as String,
      userId: data['userId'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      isCompleted: data['isCompleted'] as bool,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// TaskオブジェクトをFirestore用のMapに変換
  Map<String, dynamic> toFirestore() => {
        'projectId': projectId,
        'userId': userId,
        'name': name,
        'description': description,
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
        'isCompleted': isCompleted,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      };

  /// 期限超過かどうか判定
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }
}
