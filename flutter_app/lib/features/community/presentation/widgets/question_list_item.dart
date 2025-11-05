// T033: QuestionListItem widget for displaying question in list view
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/question.dart';
import '../../../../shared/widgets/category_tag_chip.dart';
import '../providers/user_info_provider.dart';

/// 質問一覧のアイテムウィジェット
/// 
/// 表示内容:
/// - タイトル、本文プレビュー (最大100文字)
/// - 投稿者名、アバター、投稿日時 (動的に取得)
/// - カテゴリタグ
/// - 統計情報 (回答数、閲覧数、評価スコア)
/// - ベストアンサーバッジ (採用済みの場合)
class QuestionListItem extends ConsumerWidget {
  final Question question;
  final VoidCallback onTap;

  const QuestionListItem({
    super.key,
    required this.question,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    
    // ユーザー情報を動的に取得
    final userInfoAsync = ref.watch(userInfoProvider(question.authorId));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー: 投稿者情報 & 投稿日時
              Row(
                children: [
                  // ユーザー情報を動的に表示
                  userInfoAsync.when(
                    data: (userInfo) {
                      final displayName = userInfo?.displayName ?? 'Anonymous';
                      final photoURL = userInfo?.photoURL;
                      
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // アバター
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: photoURL != null
                                ? NetworkImage(photoURL)
                                : null,
                            child: photoURL == null
                                ? Text(
                                    displayName.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(fontSize: 14),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          
                          // 投稿者名 & 投稿日時
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                dateFormat.format(question.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          child: SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '読込中...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
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
                      ],
                    ),
                    error: (_, __) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          child: Icon(Icons.person, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unknown',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
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
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // ベストアンサーバッジ
                  if (question.bestAnswerId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '解決済',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // タイトル
              Text(
                question.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // 本文プレビュー
              Text(
                question.body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // フッター: カテゴリタグ & 統計情報
              Row(
                children: [
                  // カテゴリタグ
                  CategoryTagChip(
                    categoryTag: question.categoryTag,
                    isSelected: false,
                    onTap: null, // リスト内では選択不可
                  ),
                  
                  const Spacer(),
                  
                  // 統計情報
                  _StatItem(
                    icon: Icons.comment_outlined,
                    count: question.answerCount,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  _StatItem(
                    icon: Icons.visibility_outlined,
                    count: question.viewCount,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 16),
                  _StatItem(
                    icon: Icons.star_outline,
                    count: question.evaluationScore,
                    color: Colors.amber.shade700,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 統計情報アイテム (回答数、閲覧数、評価スコア)
class _StatItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
