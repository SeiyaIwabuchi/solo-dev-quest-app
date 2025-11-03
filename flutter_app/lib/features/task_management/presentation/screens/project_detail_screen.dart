import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/project.dart';
import '../../data/models/task.dart';
import '../../providers/task_providers.dart';
import '../../providers/project_providers.dart';
import '../../providers/repository_providers.dart';
import '../../domain/enums/task_sort_by.dart';
import '../../domain/enums/task_filter_state.dart';
import '../widgets/task_tile.dart';
import '../widgets/progress_indicator_widget.dart';
import '../widgets/completion_celebration_dialog.dart';
import '../widgets/edit_project_dialog.dart';
import '../widgets/task_sort_filter_controls.dart';
import '../../../../shared/widgets/delete_confirmation_dialog.dart';
import '../../../../shared/widgets/offline_indicator.dart';
import '../../../../core/services/analytics_service.dart';
import 'task_edit_screen.dart';

/// プロジェクト詳細画面（リアルタイム同期対応）
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
  // ソート・フィルター状態
  TaskSortBy _sortBy = TaskSortBy.createdAt;
  TaskFilterState _filterState = TaskFilterState.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // プロジェクト情報をリアルタイムで監視
    final projectAsync = ref.watch(projectProvider(widget.project.id));
    
    // フィルター完了状態を計算
    bool? filterCompleted;
    switch (_filterState) {
      case TaskFilterState.all:
      case TaskFilterState.overdue:
        filterCompleted = null;
        break;
      case TaskFilterState.completed:
        filterCompleted = true;
        break;
      case TaskFilterState.uncompleted:
        filterCompleted = false;
        break;
    }
    
    // タスク一覧をリアルタイムで監視
    final tasksAsync = ref.watch(projectTasksProvider(ProjectTasksParams(
      projectId: widget.project.id,
      sortBy: _sortBy,
      filterCompleted: filterCompleted,
      limit: 100, // インデックスビルド中は制限を小さくする
    )));

    // プロジェクトの統計情報を取得
    final statisticsAsync = ref.watch(projectTaskStatisticsProvider(widget.project.id));

    return projectAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('エラー')),
        body: Center(
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
                error.toString(),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      data: (currentProject) {
        // プロジェクトが削除された場合
        if (currentProject == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('プロジェクトが削除されました'),
                ),
              );
            }
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          appBar: AppBarWithOfflineIndicator(
            title: currentProject.name,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditProjectDialog(context, ref, currentProject),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _handleDeleteProject(context, ref, currentProject);
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
                      if (currentProject.description != null &&
                          currentProject.description!.isNotEmpty) ...[
                        Text(
                          currentProject.description!,
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

              // ソート・フィルターコントロール
              TaskSortFilterControls(
                currentSortBy: _sortBy,
                currentFilterState: _filterState,
                onSortChanged: (newSortBy) {
                  setState(() {
                    _sortBy = newSortBy;
                  });
                },
                onFilterChanged: (newFilterState) {
                  setState(() {
                    _filterState = newFilterState;
                  });
                },
              ),

              // タスク一覧
              Expanded(
                child: _buildTaskList(context, ref, theme, currentProject, tasksAsync),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showTaskEditScreen(context, ref, currentProject),
            icon: const Icon(Icons.add),
            label: const Text('新規タスク'),
          ),
        );
      },
    );
  }

  /// タスク一覧を構築
  Widget _buildTaskList(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Project currentProject,
    AsyncValue<List<Task>> tasksAsync,
  ) {
    return tasksAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
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
              error.toString(),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(projectTasksProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('再読み込み'),
            ),
          ],
        ),
      ),
      data: (tasks) {
        // 期限超過フィルターを適用（クライアント側フィルタリング）
        List<Task> filteredTasks = tasks;
        if (_filterState == TaskFilterState.overdue) {
          final now = DateTime.now();
          filteredTasks = tasks.where((task) {
            return !task.isCompleted &&
                task.dueDate != null &&
                task.dueDate!.isBefore(now);
          }).toList();
        }

        if (filteredTasks.isEmpty) {
          return _buildEmptyState(context, ref, currentProject);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(projectTasksProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filteredTasks.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final task = filteredTasks[index];
              return TaskTile(
                task: task,
                onTap: () => _showTaskEditScreen(context, ref, currentProject, task: task),
                onCheckboxTap: (isCompleted) =>
                    _handleTaskCompletion(context, ref, currentProject, task.id, isCompleted),
                onDelete: () => _handleDeleteTask(context, ref, currentProject, task),
              );
            },
          ),
        );
      },
    );
  }

  /// 空状態UI
  Widget _buildEmptyState(BuildContext context, WidgetRef ref, Project currentProject) {
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
            onPressed: () => _showTaskEditScreen(context, ref, currentProject),
            icon: const Icon(Icons.add),
            label: const Text('タスクを作成'),
          ),
        ],
      ),
    );
  }

  /// プロジェクト編集ダイアログを表示
  Future<void> _showEditProjectDialog(
    BuildContext context,
    WidgetRef ref,
    Project currentProject,
  ) async {
    await EditProjectDialog.show(
      context: context,
      project: currentProject,
    );
    // リアルタイム同期により自動的に更新されるため、手動更新不要
  }

  /// タスク作成・編集画面を表示
  Future<void> _showTaskEditScreen(
    BuildContext context,
    WidgetRef ref,
    Project currentProject,
    {Task? task}
  ) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TaskEditScreen(
          projectId: currentProject.id,
          task: task,
        ),
      ),
    );
    // リアルタイム同期により自動的に更新されるため、手動更新不要
  }

  /// タスク完了状態を切り替え
  Future<void> _handleTaskCompletion(
    BuildContext context,
    WidgetRef ref,
    Project currentProject,
    String taskId,
    bool isCompleted,
  ) async {
    try {
      final repository = ref.read(taskRepositoryProvider);
      await repository.toggleTaskCompletion(
        taskId: taskId,
        isCompleted: isCompleted,
      );

      // T092: タスク完了イベントをログ
      if (isCompleted) {
        final analytics = ref.read(analyticsServiceProvider);
        analytics.logTaskCompleted(
          taskId: taskId,
          projectId: currentProject.id,
        );
      }

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

        // タスクを完了した場合、プロジェクトが100%完了したか確認
        if (isCompleted) {
          _checkProjectCompletion(context, ref, currentProject);
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
  Future<void> _checkProjectCompletion(
    BuildContext context,
    WidgetRef ref,
    Project currentProject,
  ) async {
    // 少し待ってから統計を取得（Firestoreの更新が反映されるまで）
    await Future.delayed(const Duration(milliseconds: 500));

    if (!context.mounted) return;

    final statisticsAsync = await ref.read(
      projectTaskStatisticsProvider(currentProject.id).future,
    );

    // 完了率が100%の場合、祝福ダイアログを表示
    if (statisticsAsync.isProjectCompleted) {
      // T092: プロジェクト完了イベントをログ
      final analytics = ref.read(analyticsServiceProvider);
      analytics.logProjectCompleted(
        projectId: currentProject.id,
        projectName: currentProject.name,
        totalTasks: statisticsAsync.totalTasks,
      );

      if (context.mounted) {
        await CompletionCelebrationDialog.show(
          context: context,
          projectName: currentProject.name,
          // TODO: AI褒めメッセージの統合（Phase 5 T051で実装）
          aiPraiseMessage: null,
        );
      }
    }
  }

  /// プロジェクト削除を処理
  Future<void> _handleDeleteProject(
    BuildContext context,
    WidgetRef ref,
    Project currentProject,
  ) async {
    // タスク数を取得
    final statisticsAsync = ref.read(projectTaskStatisticsProvider(currentProject.id));
    
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
      await repository.deleteProject(projectId: currentProject.id);

      if (context.mounted) {
        // ローディングを閉じる
        Navigator.of(context).pop();
        
        // 成功メッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${currentProject.name}を削除しました'),
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
  Future<void> _handleDeleteTask(
    BuildContext context,
    WidgetRef ref,
    Project currentProject,
    Task task,
  ) async {
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
      }
      // リアルタイム同期により自動的に更新されるため、手動更新不要
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
