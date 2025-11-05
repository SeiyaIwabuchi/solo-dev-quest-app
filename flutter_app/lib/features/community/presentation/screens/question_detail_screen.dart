// T031: QuestionDetailScreen - 質問詳細画面
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/question_provider.dart';
import '../../domain/models/question.dart';
import '../../../../shared/widgets/category_tag_chip.dart';
import '../../../../shared/widgets/markdown_viewer.dart';

/// 質問詳細画面
/// 
/// 機能:
/// - 質問の詳細表示 (タイトル、本文、コード例)
/// - 投稿者情報表示
/// - 統計情報表示 (回答数、閲覧数、評価スコア)
/// - 閲覧回数の自動インクリメント (incrementViewCount)
/// - 回答一覧表示 (Phase 3で実装予定)
/// - 回答投稿ボタン (Phase 3で実装予定)
class QuestionDetailScreen extends ConsumerStatefulWidget {
  final String questionId;

  const QuestionDetailScreen({
    super.key,
    required this.questionId,
  });

  @override
  ConsumerState<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends ConsumerState<QuestionDetailScreen> {
  @override
  void initState() {
    super.initState();
    // 閲覧回数インクリメント (バックグラウンドで実行、エラーは無視)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(questionRepositoryProvider).incrementViewCount(widget.questionId);
    });
  }

  void _logQuestionViewedAnalytics(Question question) {
    // T035: Analytics event - question_viewed
    ref.read(communityAnalyticsServiceProvider).logQuestionViewed(
      questionId: question.questionId,
      categoryTag: question.categoryTag,
      hasAnswer: question.answerCount > 0,
      viewSource: 'direct',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final questionAsync = ref.watch(questionDetailProvider(widget.questionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('質問詳細'),
        actions: [
          // 共有ボタン (将来実装)
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: 共有機能実装
            },
          ),
          // メニューボタン (報告、編集、削除)
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'report':
                  // TODO: 報告機能実装
                  break;
                case 'edit':
                  // TODO: 編集画面遷移
                  break;
                case 'delete':
                  // TODO: 削除確認ダイアログ
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag),
                    SizedBox(width: 8),
                    Text('報告する'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('編集'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete),
                    SizedBox(width: 8),
                    Text('削除'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: questionAsync.when(
        data: (question) {
          if (question == null) {
            return _buildNotFound(theme);
          }
          // Analytics イベントを送信 (初回のみ)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _logQuestionViewedAnalytics(question);
          });
          return _buildQuestionDetail(question, theme);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => _buildError(theme, error.toString()),
      ),
      // Phase 3で回答投稿ボタンを追加
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () { /* 回答投稿画面へ */ },
      //   icon: const Icon(Icons.reply),
      //   label: const Text('回答する'),
      // ),
    );
  }

  Widget _buildQuestionDetail(Question question, ThemeData theme) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー: 投稿者情報 & カテゴリ
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: question.authorAvatarUrl != null
                    ? NetworkImage(question.authorAvatarUrl!)
                    : null,
                child: question.authorAvatarUrl == null
                    ? Text(
                        question.authorName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 18),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.authorName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dateFormat.format(question.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              CategoryTagChip(
                categoryTag: question.categoryTag,
                isSelected: false,
                onTap: null,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // ベストアンサーバッジ
          if (question.bestAnswerId != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'この質問は解決済みです',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          
          // タイトル
          Text(
            question.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 統計情報
          Row(
            children: [
              _StatChip(
                icon: Icons.comment_outlined,
                label: '回答',
                count: question.answerCount,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.visibility_outlined,
                label: '閲覧',
                count: question.viewCount,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.star_outline,
                label: '評価',
                count: question.evaluationScore,
                color: Colors.amber.shade700,
              ),
            ],
          ),
          
          const Divider(height: 32),
          
          // 本文 (Markdown表示)
          MarkdownViewer(data: question.body),
          
          // コード例 (存在する場合)
          if (question.codeExample != null && question.codeExample!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'コード例',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            CodeSnippetViewer(
              code: question.codeExample!,
              language: _detectLanguage(question.categoryTag),
            ),
          ],
          
          const Divider(height: 32),
          
          // 回答一覧 (Phase 3で実装)
          Text(
            '回答 (${question.answerCount})',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // TODO: Phase 3で回答一覧を実装
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                '回答機能はPhase 3で実装予定です',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '質問が見つかりません',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '削除されたか、存在しない質問です',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('戻る'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme, String error) {
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
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // 再読み込み
              ref.invalidate(questionDetailProvider(widget.questionId));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  String _detectLanguage(String categoryTag) {
    switch (categoryTag) {
      case 'Flutter':
      case 'Dart':
        return 'dart';
      case 'Firebase':
      case 'Backend':
        return 'javascript';
      default:
        return '';
    }
  }
}

/// 統計情報チップ
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        '$label: $count',
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }
}
