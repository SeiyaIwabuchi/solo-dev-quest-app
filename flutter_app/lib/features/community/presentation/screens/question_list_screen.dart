// T030: QuestionListScreen - 質問一覧画面
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/question_provider.dart';
import '../widgets/question_list_item.dart';
import '../../../../shared/widgets/category_tag_chip.dart';

/// 質問一覧画面
/// 
/// 機能:
/// - 質問一覧の表示 (ページネーション対応)
/// - カテゴリフィルタ (Flutter/Firebase/Dart/Backend/Design/Other)
/// - ソート切り替え (最新/回答数/評価順)
/// - Pull-to-refresh
/// - 質問投稿画面への遷移
/// - 質問詳細画面への遷移
class QuestionListScreen extends ConsumerStatefulWidget {
  const QuestionListScreen({super.key});

  @override
  ConsumerState<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends ConsumerState<QuestionListScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedCategory;
  String _sortBy = 'latest';

  @override
  void initState() {
    super.initState();
    // 初回ロード
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(questionListProvider.notifier).loadQuestions();
    });
    
    // スクロール監視でページネーション
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // 80%スクロールで次ページ読み込み
      ref.read(questionListProvider.notifier).loadMoreQuestions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(questionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('質問'),
        leading: IconButton(
          onPressed: () => context.go('/projects'),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'プロジェクト一覧に戻る',
        ),
        actions: [
          // ソート切り替えボタン
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
              ref.read(questionListProvider.notifier).changeSortBy(value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'latest',
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: _sortBy == 'latest' ? theme.colorScheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '最新順',
                      style: TextStyle(
                        color: _sortBy == 'latest' ? theme.colorScheme.primary : null,
                        fontWeight: _sortBy == 'latest' ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'answer_count',
                child: Row(
                  children: [
                    Icon(
                      Icons.comment,
                      color: _sortBy == 'answer_count' ? theme.colorScheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '回答数順',
                      style: TextStyle(
                        color: _sortBy == 'answer_count' ? theme.colorScheme.primary : null,
                        fontWeight: _sortBy == 'answer_count' ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'evaluation_score',
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: _sortBy == 'evaluation_score' ? theme.colorScheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '評価順',
                      style: TextStyle(
                        color: _sortBy == 'evaluation_score' ? theme.colorScheme.primary : null,
                        fontWeight: _sortBy == 'evaluation_score' ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(questionListProvider.notifier).refresh();
        },
        child: Column(
          children: [
            // カテゴリフィルタ
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // "すべて"オプション
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CategoryTagChip(
                      categoryTag: 'すべて',
                      isSelected: _selectedCategory == null,
                      onTap: () {
                        setState(() {
                          _selectedCategory = null;
                        });
                        ref.read(questionListProvider.notifier).filterByCategory(null);
                      },
                    ),
                  ),
                  // カテゴリオプション
                  ..._buildCategoryChips(),
                ],
              ),
            ),
            
            // 質問一覧
            Expanded(
              child: _buildQuestionList(state, theme),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // T034: 質問投稿画面への遷移
          context.go('/community/question/post');
        },
        icon: const Icon(Icons.add),
        label: const Text('質問する'),
      ),
    );
  }

  List<Widget> _buildCategoryChips() {
    const categories = [
      'Flutter',
      'Firebase',
      'Dart',
      'Backend',
      'Design',
      'Other',
    ];

    return categories.map((category) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: CategoryTagChip(
          categoryTag: category,
          isSelected: _selectedCategory == category,
          onTap: () {
            setState(() {
              _selectedCategory = category;
            });
            ref.read(questionListProvider.notifier).filterByCategory(category);
          },
        ),
      );
    }).toList();
  }

  Widget _buildQuestionList(QuestionListState state, ThemeData theme) {
    // エラー表示
    if (state.error != null && state.questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(questionListProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    // ローディング表示 (初回)
    if (state.isLoading && state.questions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // 空リスト表示
    if (state.questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.question_answer_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '質問がありません',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '最初の質問を投稿してみましょう！',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // 質問一覧表示
    return ListView.builder(
      controller: _scrollController,
      itemCount: state.questions.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // ローディングインジケータ (ページネーション中)
        if (index == state.questions.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final question = state.questions[index];
        return QuestionListItem(
          question: question,
          onTap: () {
            // T035: Analytics event - question_viewed
            ref.read(communityAnalyticsServiceProvider).logQuestionViewed(
              questionId: question.questionId,
              categoryTag: question.categoryTag,
              hasAnswer: question.answerCount > 0,
              viewSource: 'list',
            );
            
            // T034: 質問詳細画面への遷移
            context.go('/community/question/${question.questionId}');
          },
        );
      },
    );
  }
}
