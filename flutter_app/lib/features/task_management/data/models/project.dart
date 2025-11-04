import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'project.freezed.dart';
part 'project.g.dart';

/// プロジェクトモデル
@freezed
class Project with _$Project {
  const factory Project({
    /// プロジェクトID
    required String id,

    /// ユーザーID（所有者）
    required String userId,

    /// プロジェクト名（1-100文字）
    required String name,

    /// プロジェクト説明（0-500文字、オプション）
    String? description,

    /// 作成日時
    required DateTime createdAt,

    /// 更新日時
    required DateTime updatedAt,
  }) = _Project;

  const Project._();

  /// JSONからProjectオブジェクトを生成
  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);

  /// FirestoreドキュメントからProjectオブジェクトを生成
  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Project(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// ProjectオブジェクトをFirestore用のMapに変換
  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'description': description,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}
