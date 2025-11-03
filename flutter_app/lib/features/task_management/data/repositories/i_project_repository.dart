import '../models/project.dart';

/// プロジェクトリポジトリのインターフェース
abstract class IProjectRepository {
  /// ユーザーのプロジェクト一覧をリアルタイムで監視
  ///
  /// [userId] ユーザーID
  /// 戻り値: プロジェクト一覧のStream
  Stream<List<Project>> watchUserProjects({required String userId});

  /// 特定のプロジェクトをリアルタイムで監視
  ///
  /// [projectId] プロジェクトID
  /// 戻り値: プロジェクトのStream
  Stream<Project?> watchProject({required String projectId});

  /// 新しいプロジェクトを作成
  ///
  /// [userId] ユーザーID
  /// [name] プロジェクト名（1-100文字）
  /// [description] プロジェクト説明（0-500文字、オプション）
  /// 戻り値: 作成されたプロジェクト
  Future<Project> createProject({
    required String userId,
    required String name,
    String? description,
  });

  /// プロジェクトを更新
  ///
  /// [projectId] プロジェクトID
  /// [name] プロジェクト名（1-100文字）
  /// [description] プロジェクト説明（0-500文字、オプション）
  /// 戻り値: 更新されたプロジェクト
  Future<Project> updateProject({
    required String projectId,
    required String name,
    String? description,
  });

  /// プロジェクトを削除（関連タスクもカスケード削除）
  ///
  /// [projectId] プロジェクトID
  Future<void> deleteProject({required String projectId});

  /// プロジェクトが存在するか確認
  ///
  /// [projectId] プロジェクトID
  /// 戻り値: 存在する場合true
  Future<bool> exists({required String projectId});
}
