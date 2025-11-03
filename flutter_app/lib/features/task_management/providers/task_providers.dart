import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/models/task.dart';
import '../data/models/task_statistics.dart';
import '../domain/enums/task_sort_by.dart';
import 'repository_providers.dart';

/// プロジェクト内のタスク一覧を監視するStreamProvider
/// 
/// [projectId] プロジェクトID
/// [sortBy] ソート順（デフォルト: 作成日時降順）
/// [filterCompleted] 完了タスクのフィルター（null: すべて、true: 完了のみ、false: 未完了のみ）
final projectTasksProvider = StreamProvider.autoDispose
    .family<List<Task>, ProjectTasksParams>((ref, params) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchProjectTasks(
    projectId: params.projectId,
    sortBy: params.sortBy,
    filterCompleted: params.filterCompleted,
    limit: params.limit,
  );
});

/// 特定のタスクを監視するStreamProvider
final taskProvider = StreamProvider.autoDispose.family<Task?, String>((ref, taskId) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTask(taskId: taskId);
});

/// プロジェクトのタスク統計情報を取得するStreamProvider
/// リアルタイムで統計情報を更新するため、StreamProviderを使用
final projectTaskStatisticsProvider = StreamProvider.autoDispose
    .family<TaskStatistics, String>((ref, projectId) {
  // リポジトリから直接統計情報を監視（Firestore側で集計）
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchProjectTaskStatistics(projectId: projectId);
});

/// プロジェクトタスク取得用のパラメータクラス
class ProjectTasksParams {
  const ProjectTasksParams({
    required this.projectId,
    this.sortBy = TaskSortBy.createdAt,
    this.filterCompleted,
    this.limit = 30,
    this.startAfterDoc,
  });

  final String projectId;
  final TaskSortBy sortBy;
  final bool? filterCompleted;
  final int limit;
  final DocumentSnapshot? startAfterDoc;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProjectTasksParams &&
        other.projectId == projectId &&
        other.sortBy == sortBy &&
        other.filterCompleted == filterCompleted &&
        other.limit == limit &&
        other.startAfterDoc == startAfterDoc;
  }

  @override
  int get hashCode {
    return Object.hash(
      projectId,
      sortBy,
      filterCompleted,
      limit,
      startAfterDoc,
    );
  }
}
