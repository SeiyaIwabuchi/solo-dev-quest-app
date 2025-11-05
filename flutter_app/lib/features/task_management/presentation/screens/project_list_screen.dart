import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/project.dart';
import '../../providers/project_providers.dart';
import '../../providers/task_providers.dart';
import '../widgets/project_card.dart';
import '../widgets/create_project_dialog.dart';
import 'project_detail_screen.dart';

/// プロジェクト一覧画面
class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(userProjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロジェクト'),
        actions: [
          // 質問機能への直接アクセス
          IconButton(
            onPressed: () => context.push('/community/questions'),
            icon: const Icon(Icons.question_answer),
            tooltip: 'Q&A コミュニティ',
          ),
        ],
      ),
      body: projectsAsync.when(
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
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'エラーが発生しました',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ref.invalidate(userProjectsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('再読み込み'),
              ),
            ],
          ),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userProjectsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                
                // プロジェクトの進捗率を取得
                final statisticsAsync = ref.watch(
                  projectTaskStatisticsProvider(project.id),
                );

                return statisticsAsync.when(
                  loading: () => ProjectCard(
                    project: project,
                    progressRate: 0.0,
                    onTap: () => _navigateToProjectDetail(context, project),
                  ),
                  error: (_, __) => ProjectCard(
                    project: project,
                    progressRate: 0.0,
                    onTap: () => _navigateToProjectDetail(context, project),
                  ),
                  data: (statistics) => ProjectCard(
                    project: project,
                    progressRate: statistics.completionRate,
                    onTap: () => _navigateToProjectDetail(context, project),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProjectDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('新規プロジェクト'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 120,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'プロジェクトがありません',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            '新しいプロジェクトを作成して\n開発作業を始めましょう！',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => _showCreateProjectDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('プロジェクトを作成'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.push('/community/questions'),
            icon: const Icon(Icons.help_outline),
            label: const Text('質問を見る'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateProjectDialog(BuildContext context) async {
    final project = await showDialog(
      context: context,
      builder: (context) => const CreateProjectDialog(),
    );

    if (project != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('プロジェクトを作成しました'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// プロジェクト詳細画面へ遷移
  void _navigateToProjectDetail(BuildContext context, Project project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(project: project),
      ),
    );
  }
}
