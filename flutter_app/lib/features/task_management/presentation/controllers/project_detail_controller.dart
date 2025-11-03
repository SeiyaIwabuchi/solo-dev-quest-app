import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/project.dart';
import '../../data/repositories/i_project_repository.dart';
import '../../providers/repository_providers.dart';
import '../../../../core/exceptions/validation_exception.dart';
import '../../../../core/exceptions/not_found_exception.dart';

/// プロジェクト詳細画面のコントローラー
///
/// プロジェクトの編集・削除操作を管理します。
class ProjectDetailController extends StateNotifier<AsyncValue<void>> {
  ProjectDetailController(this._repository) : super(const AsyncValue.data(null));

  final IProjectRepository _repository;

  /// プロジェクト情報を更新
  ///
  /// [projectId] 更新対象のプロジェクトID
  /// [name] 新しいプロジェクト名（1-100文字）
  /// [description] 新しいプロジェクト説明（0-500文字、オプション）
  ///
  /// バリデーションエラーの場合は[ValidationException]をスロー
  /// プロジェクトが見つからない場合は[NotFoundException]をスロー
  Future<Project> updateProject({
    required String projectId,
    required String name,
    String? description,
  }) async {
    // バリデーション
    if (name.trim().isEmpty) {
      throw ValidationException('プロジェクト名を入力してください');
    }
    if (name.trim().length > 100) {
      throw ValidationException('プロジェクト名は100文字以内で入力してください');
    }
    if (description != null && description.trim().length > 500) {
      throw ValidationException('プロジェクト説明は500文字以内で入力してください');
    }

    // プロジェクトが存在するか確認
    final exists = await _repository.exists(projectId: projectId);
    if (!exists) {
      throw NotFoundException('プロジェクトが見つかりません');
    }

    state = const AsyncValue.loading();

    try {
      final updatedProject = await _repository.updateProject(
        projectId: projectId,
        name: name.trim(),
        description: description?.trim().isNotEmpty == true ? description!.trim() : null,
      );

      state = const AsyncValue.data(null);
      return updatedProject;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// プロジェクトを削除（関連タスクもカスケード削除）
  ///
  /// [projectId] 削除対象のプロジェクトID
  ///
  /// プロジェクトが見つからない場合は[NotFoundException]をスロー
  Future<void> deleteProject({required String projectId}) async {
    // プロジェクトが存在するか確認
    final exists = await _repository.exists(projectId: projectId);
    if (!exists) {
      throw NotFoundException('プロジェクトが見つかりません');
    }

    state = const AsyncValue.loading();

    try {
      await _repository.deleteProject(projectId: projectId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

/// ProjectDetailControllerのプロバイダー
final projectDetailControllerProvider =
    StateNotifierProvider<ProjectDetailController, AsyncValue<void>>((ref) {
  final repository = ref.watch(projectRepositoryProvider);
  return ProjectDetailController(repository);
});
