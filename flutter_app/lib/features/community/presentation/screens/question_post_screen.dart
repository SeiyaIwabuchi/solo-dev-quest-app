// T032: QuestionPostScreen - 質問投稿画面
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/question_provider.dart';
import '../../../../shared/widgets/category_tag_chip.dart';
import '../../../../shared/widgets/devcoin_balance_display.dart';

/// 質問投稿画面
/// 
/// 機能:
/// - 質問タイトル入力 (5~200文字)
/// - 質問本文入力 (10~10,000文字)
/// - コード例入力 (オプション、0~5,000文字)
/// - カテゴリ選択 (Flutter/Firebase/Dart/Backend/Design/Other)
/// - DevCoin残高表示 (投稿コスト: 10 DevCoin)
/// - バリデーション & 投稿処理
/// - エラーハンドリング (T036, T037)
class QuestionPostScreen extends ConsumerStatefulWidget {
  const QuestionPostScreen({super.key});

  @override
  ConsumerState<QuestionPostScreen> createState() => _QuestionPostScreenState();
}

class _QuestionPostScreenState extends ConsumerState<QuestionPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _codeExampleController = TextEditingController();
  
  String? _selectedCategory;
  bool _isPosting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _codeExampleController.dispose();
    super.dispose();
  }

  Future<void> _postQuestion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('カテゴリを選択してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      final repository = ref.read(questionRepositoryProvider);
      
      // 質問投稿 (Cloud Function呼び出し)
      final question = await repository.postQuestion(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        codeExample: _codeExampleController.text.trim().isEmpty
            ? null
            : _codeExampleController.text.trim(),
        categoryTag: _selectedCategory!,
      );

      if (!mounted) return;

      // T035: Analytics event - question_posted
      ref.read(communityAnalyticsServiceProvider).logQuestionPosted(
        questionId: question.questionId,
        categoryTag: _selectedCategory!,
        hasCodeExample: _codeExampleController.text.trim().isNotEmpty,
      );

      // 成功メッセージ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('質問を投稿しました！'),
          backgroundColor: Colors.green,
        ),
      );

      // 質問一覧をリフレッシュ
      ref.read(questionListProvider.notifier).refresh();

      // 質問詳細画面に遷移（投稿画面を閉じて詳細を開く）
      if (!mounted) return;
      Navigator.pop(context); // 投稿画面を閉じる
      context.push('/community/question/${question.questionId}');
    } on Exception catch (e) {
      if (!mounted) return;

      // エラーメッセージをパース
      final errorMessage = _parseErrorMessage(e.toString());
      
      // T036: DevCoin不足エラー
      if (errorMessage.contains('DevCoin残高が不足しています')) {
        _showDevCoinInsufficientDialog();
        return;
      }
      
      // T037: 重複投稿エラー
      if (errorMessage.contains('同じタイトルの質問は5分以内に投稿できません')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('同じタイトルの質問は5分以内に投稿できません'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        return;
      }

      // その他のエラー
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  // T036: DevCoin不足ダイアログ
  void _showDevCoinInsufficientDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('DevCoin不足'),
          ],
        ),
        content: const Text(
          '質問の投稿には10 DevCoinが必要です。\n\nDevCoinを獲得するには:\n・他の開発者の質問に回答する (5 DevCoin)\n・プレミアムプランに加入する (毎月200 DevCoin)',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('閉じる'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: プレミアムプラン画面へ遷移
            },
            child: const Text('プレミアムプランを見る'),
          ),
        ],
      ),
    );
  }

  String _parseErrorMessage(String error) {
    // FirebaseFunctionsExceptionのメッセージをパース
    if (error.contains('ユーザー情報が見つかりません') || error.contains('ユーザーが存在しません')) {
      return 'ユーザー情報が見つかりません。再度ログインしてください。';
    }
    if (error.contains('DevCoin残高が不足しています')) {
      return 'DevCoin残高が不足しています';
    }
    if (error.contains('同じタイトルの質問は5分以内に投稿できません')) {
      return '同じタイトルの質問は5分以内に投稿できません';
    }
    if (error.contains('ログインが必要です')) {
      return 'ログインが必要です';
    }
    if (error.contains('タイトルは')) {
      return 'タイトルは5文字以上200文字以内で入力してください';
    }
    if (error.contains('本文は')) {
      return '本文は10文字以上10,000文字以内で入力してください';
    }
    return 'エラーが発生しました。もう一度お試しください。';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('質問を投稿'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // DevCoin残高表示 & 投稿コスト説明
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '現在の残高',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        // TODO: 実際の残高を取得して表示
                        const DevCoinBalanceDisplay(
                          balance: 100, // ダミー値
                          size: DevCoinDisplaySize.medium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('投稿コスト'),
                        const Spacer(),
                        Icon(Icons.monetization_on, size: 16, color: Colors.amber.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '10 DevCoin',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // タイトル入力
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル *',
                hintText: '質問のタイトルを入力してください',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              maxLength: 200,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'タイトルを入力してください';
                }
                if (value.trim().length < 5) {
                  return 'タイトルは5文字以上で入力してください';
                }
                if (value.trim().length > 200) {
                  return 'タイトルは200文字以内で入力してください';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // カテゴリ選択
            Text(
              'カテゴリ *',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Flutter',
                'Firebase',
                'Dart',
                'Backend',
                'Design',
                'Other',
              ].map((category) {
                return CategoryTagChip(
                  categoryTag: category,
                  isSelected: _selectedCategory == category,
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // 本文入力
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: '本文 *',
                hintText: '質問の詳細を入力してください\nMarkdown記法が使えます',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 10,
              maxLength: 10000,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '本文を入力してください';
                }
                if (value.trim().length < 10) {
                  return '本文は10文字以上で入力してください';
                }
                if (value.trim().length > 10000) {
                  return '本文は10,000文字以内で入力してください';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // コード例入力 (オプション)
            ExpansionTile(
              title: const Text('コード例 (オプション)'),
              leading: const Icon(Icons.code),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    controller: _codeExampleController,
                    decoration: const InputDecoration(
                      hintText: 'コード例を入力してください',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 8,
                    maxLength: 5000,
                    style: const TextStyle(fontFamily: 'monospace'),
                    validator: (value) {
                      if (value != null && value.trim().length > 5000) {
                        return 'コード例は5,000文字以内で入力してください';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 投稿ボタン
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isPosting ? null : _postQuestion,
                child: _isPosting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('投稿する'),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 注意事項
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '投稿前の確認事項',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '・質問内容は丁寧かつ具体的に記載してください\n'
                      '・コミュニティガイドラインに違反する投稿は削除される場合があります\n'
                      '・同じタイトルの質問は5分以内に投稿できません',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
