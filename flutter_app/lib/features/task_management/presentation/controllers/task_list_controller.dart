import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/task.dart';
import '../../domain/enums/task_sort_by.dart';
import '../../providers/repository_providers.dart';
import '../../../../core/exceptions/validation_exception.dart';

/// タスクリストの状態
class TaskListState {
  const TaskListState({
    this.tasks = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.lastDocument,
    this.error,
    this.sortBy = TaskSortBy.createdAt,
    this.filterCompleted,
  });

  final List<Task> tasks;
  final bool isLoadingMore;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final Object? error;
  final TaskSortBy sortBy;
  final bool? filterCompleted;

  TaskListState copyWith({
    List<Task>? tasks,
    bool? isLoadingMore,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    Object? error,
    TaskSortBy? sortBy,
    bool? filterCompleted,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument ?? this.lastDocument,
      error: error,
      sortBy: sortBy ?? this.sortBy,
      filterCompleted: filterCompleted ?? this.filterCompleted,
    );
  }

  /// 状態をリセット
  TaskListState reset() {
    return const TaskListState();
  }
}

/// タスクリストの状態管理コントローラー
class TaskListController extends StateNotifier<TaskListState> {
  TaskListController(this._ref) : super(const TaskListState());

  final Ref _ref;
  static const int _pageSize = 30;

  /// 初期タスク一覧を読み込み
  Future<void> loadInitialTasks(
    String projectId, {
    TaskSortBy sortBy = TaskSortBy.createdAt,
    bool? filterCompleted,
  }) async {
    try {
      // 状態をリセット
      state = TaskListState(
        sortBy: sortBy,
        filterCompleted: filterCompleted,
      );

      final repository = _ref.read(taskRepositoryProvider);
      final (tasks, lastDoc) = await repository.getProjectTasks(
        projectId: projectId,
        sortBy: sortBy,
        filterCompleted: filterCompleted,
        limit: _pageSize,
      );

      state = state.copyWith(
        tasks: tasks,
        lastDocument: lastDoc,
        hasMore: tasks.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(error: e);
    }
  }

  /// 次のページを読み込み（無限スクロール用）
  Future<void> loadMoreTasks(String projectId) async {
    if (state.isLoadingMore || !state.hasMore) {
      return;
    }

    try {
      state = state.copyWith(isLoadingMore: true, error: null);

      final repository = _ref.read(taskRepositoryProvider);
      final (newTasks, lastDoc) = await repository.getProjectTasks(
        projectId: projectId,
        sortBy: state.sortBy,
        filterCompleted: state.filterCompleted,
        limit: _pageSize,
        startAfterDoc: state.lastDocument,
      );

      state = state.copyWith(
        tasks: [...state.tasks, ...newTasks],
        lastDocument: lastDoc,
        isLoadingMore: false,
        hasMore: newTasks.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e,
      );
    }
  }

  /// タスクを作成
  Future<Task> createTask({
    required String projectId,
    required String name,
    String? description,
    DateTime? dueDate,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ユーザーが認証されていません');
      }

      final repository = _ref.read(taskRepositoryProvider);
      final task = await repository.createTask(
        projectId: projectId,
        userId: user.uid,
        name: name,
        description: description,
        dueDate: dueDate,
      );

      return task;
    } on ValidationException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// タスクを更新
  Future<Task> updateTask({
    required String taskId,
    required String name,
    String? description,
    DateTime? dueDate,
  }) async {
    try {
      final repository = _ref.read(taskRepositoryProvider);
      final task = await repository.updateTask(
        taskId: taskId,
        name: name,
        description: description,
        dueDate: dueDate,
      );

      return task;
    } on ValidationException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// タスクの完了状態を切り替え
  Future<void> toggleTaskCompletion({
    required String taskId,
    required bool isCompleted,
  }) async {
    try {
      final repository = _ref.read(taskRepositoryProvider);
      await repository.toggleTaskCompletion(
        taskId: taskId,
        isCompleted: isCompleted,
      );
    } catch (e) {
      rethrow;
    }
  }
}

/// TaskListControllerのプロバイダー
final taskListControllerProvider =
    StateNotifierProvider.autoDispose<TaskListController, TaskListState>(
  (ref) => TaskListController(ref),
);
