import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/project.dart';
import '../../data/models/task.dart';
import '../../providers/task_providers.dart';
import '../../providers/repository_providers.dart';
import '../controllers/task_list_controller.dart';
import '../widgets/task_tile.dart';
import '../widgets/progress_indicator_widget.dart';
import '../widgets/completion_celebration_dialog.dart';
import '../widgets/edit_project_dialog.dart';
import '../../../../shared/widgets/delete_confirmation_dialog.dart';
import '../../../../shared/widgets/offline_indicator.dart';
import 'task_edit_screen.dart';

/// プロジェクト詳細画面
class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({
    super.key,
    required this.project,
  });

  final Project project;

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  late Project _currentProject;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingInitial = true;

  @override
  void initState() {
    super.initState();
    _currentProject = widget.project;
    _scrollController.addListener(_onScroll);
    
    // 初期データを読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialTasks();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 初期タスク一覧を読み込み
  Future<void> _loadInitialTasks() async {
    final controller = ref.read(taskListControllerProvider.notifier);
    await controller.loadInitialTasks(_currentProject.id);
    if (mounted) {
      setState(() {
        _isLoadingInitial = false;
      });
    }
  }

  /// スクロールイベントを処理
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // 80%スクロールしたら次のページを読み込み
      final controller = ref.read(taskListControllerProvider.notifier);
      controller.loadMoreTasks(_currentProject.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // プロジェクトの統計情報を取得
    final statisticsAsync = ref.watch(projectTaskStatisticsProvider(_currentProject.id));

    return Scaffold(
      appBar: AppBarWithOfflineIndicator(
        title: _currentProject.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProjectDialog(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _handleDeleteProject(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('プロジェクトを削除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // プロジェクト情報カード
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentProject.description != null &&
                      _currentProject.description!.isNotEmpty) ...[
                    Text(
                      _currentProject.description!,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // 進捗率表示
                  statisticsAsync.when(
                    data: (statistics) => ProgressIndicatorWidget(
                      progressRate: statistics.completionRate,
                    ),
                    loading: () => const ProgressIndicatorWidget(
                      progressRate: 0.0,
                    ),
                    error: (_, __) => const ProgressIndicatorWidget(
                      progressRate: 0.0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // タスク一覧セクション
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'タスク一覧',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                statisticsAsync.when(
                  data: (statistics) => Text(
                    '${statistics.completedTasks} / ${statistics.totalTasks}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // タスク一覧
          Expanded(
            child: _buildTaskList(context, theme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskEditScreen(context),
        icon: const Icon(Icons.add),
        label: const Text('新規タスク'),
      ),
    );
  }

  /// タスク一覧を構築
  Widget _buildTaskList(BuildContext context, ThemeData theme) {
    final taskListState = ref.watch(taskListControllerProvider);

    if (_isLoadingInitial) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (taskListState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              taskListState.error.toString(),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _loadInitialTasks(),
              icon: const Icon(Icons.refresh),
              label: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }

    if (taskListState.tasks.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadInitialTasks();
      },
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: taskListState.tasks.length + (taskListState.hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          // ローディングインジケーターを表示
          if (index == taskListState.tasks.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: taskListState.isLoadingMore
                    ? const CircularProgressIndicator()
                    : const SizedBox.shrink(),
              ),
            );
          }

          final task = taskListState.tasks[index];
          return TaskTile(
            task: task,
            onTap: () => _showTaskEditScreen(context, task: task),
            onCheckboxTap: (isCompleted) =>
                _handleTaskCompletion(context, ref, task.id, isCompleted),
            onDelete: () => _handleDeleteTask(context, task),
          );
        },
      ),
    );
  }

  /// 空状態UI
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 120,
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'タスクがありません',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            '新しいタスクを作成して\n開発作業を始めましょう！',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => _showTaskEditScreen(context),
            icon: const Icon(Icons.add),
            label: const Text('タスクを作成'),
          ),
        ],
      ),
    );
  }

  /// プロジェクト編集ダイアログを表示
  Future<void> _showEditProjectDialog(BuildContext context) async {
    final updatedProject = await EditProjectDialog.show(
      context: context,
      project: _currentProject,
    );

    if (updatedProject != null && mounted) {
      setState(() {
        _currentProject = updatedProject;
      });
    }
  }

  /// タスク作成・編集画面を表示
  Future<void> _showTaskEditScreen(BuildContext context, {Task? task}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TaskEditScreen(
          projectId: _currentProject.id,
          task: task,
        ),
      ),
    );

    if (result == true && context.mounted) {
      // タスクが作成/更新された場合は、タスクリストを再読み込み
      await _loadInitialTasks();
      // プロジェクト統計を更新
      ref.invalidate(projectTaskStatisticsProvider(_currentProject.id));
    }
  }

  /// タスク完了状態を切り替え
  Future<void> _handleTaskCompletion(
    BuildContext context,
    WidgetRef ref,
    String taskId,
    bool isCompleted,
  ) async {
    try {
      final controller = ref.read(taskListControllerProvider.notifier);
      await controller.toggleTaskCompletion(
        taskId: taskId,
        isCompleted: isCompleted,
      );

      if (context.mounted) {
        // 成功メッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCompleted ? 'タスクを完了しました!' : 'タスクを未完了に戻しました',
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        // タスクリストを再読み込み
        await _loadInitialTasks();
        
        // プロジェクト統計を更新
        ref.invalidate(projectTaskStatisticsProvider(_currentProject.id));

        // タスクを完了した場合、プロジェクトが100%完了したか確認
        if (isCompleted) {
          _checkProjectCompletion(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// プロジェクト完了を確認し、100%の場合は祝福ダイアログを表示
  Future<void> _checkProjectCompletion(BuildContext context) async {
    // 少し待ってから統計を取得（Firestoreの更新が反映されるまで）
    await Future.delayed(const Duration(milliseconds: 500));

    if (!context.mounted) return;

    final statisticsAsync = await ref.read(
      projectTaskStatisticsProvider(_currentProject.id).future,
    );

    // 完了率が100%の場合、祝福ダイアログを表示
    if (statisticsAsync.isProjectCompleted) {
      if (context.mounted) {
        await CompletionCelebrationDialog.show(
          context: context,
          projectName: _currentProject.name,
          // TODO: AI褒めメッセージの統合（Phase 5 T051で実装）
          aiPraiseMessage: null,
        );
      }
    }
  }

  /// プロジェクト削除を処理
  Future<void> _handleDeleteProject(BuildContext context) async {
    // タスク数を取得
    final statisticsAsync = ref.read(projectTaskStatisticsProvider(_currentProject.id));
    
    final taskCount = statisticsAsync.when(
      data: (statistics) => statistics.totalTasks,
      loading: () => 0,
      error: (_, __) => 0,
    );

    // 削除確認ダイアログを表示
    final shouldDelete = await DeleteConfirmationDialog.show(
      context: context,
      title: 'プロジェクトを削除',
      message: 'このプロジェクトを削除してもよろしいですか？\nこの操作は取り消せません。',
      warningMessage: taskCount > 0
          ? 'このプロジェクトには$taskCount個のタスクが含まれています。すべてのタスクも削除されます。'
          : null,
    );

    if (!shouldDelete || !context.mounted) return;

    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // プロジェクトを削除（関連タスクも削除される）
      final repository = ref.read(projectRepositoryProvider);
      await repository.deleteProject(projectId: _currentProject.id);

      if (context.mounted) {
        // ローディングを閉じる
        Navigator.of(context).pop();
        
        // 成功メッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_currentProject.name}を削除しました'),
            duration: const Duration(seconds: 3),
          ),
        );

        // プロジェクト一覧画面に戻る
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        // ローディングを閉じる
        Navigator.of(context).pop();
        
        // エラーメッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// タスク削除を処理
  Future<void> _handleDeleteTask(BuildContext context, Task task) async {
    try {
      final repository = ref.read(taskRepositoryProvider);
      await repository.deleteTask(taskId: task.id);

      if (context.mounted) {
        // 成功メッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${task.name}」を削除しました'),
            duration: const Duration(seconds: 2),
          ),
        );

        // タスクリストを再読み込み
        await _loadInitialTasks();
        
        // プロジェクト統計を更新
        ref.invalidate(projectTaskStatisticsProvider(_currentProject.id));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
