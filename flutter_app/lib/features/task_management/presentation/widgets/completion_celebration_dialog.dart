import 'package:flutter/material.dart';

/// プロジェクト完了時の祝福ダイアログ
class CompletionCelebrationDialog extends StatelessWidget {
  const CompletionCelebrationDialog({
    super.key,
    required this.projectName,
    this.aiPraiseMessage,
  });

  final String projectName;
  final String? aiPraiseMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 祝福アイコン
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.celebration,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            // おめでとうメッセージ
            Text(
              'おめでとうございます！',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // プロジェクト名
            Text(
              '「$projectName」',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              'のすべてのタスクが完了しました！',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // AI褒めメッセージ（あれば表示）
            if (aiPraiseMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        aiPraiseMessage!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 閉じるボタン
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ダイアログを表示
  static Future<void> show({
    required BuildContext context,
    required String projectName,
    String? aiPraiseMessage,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CompletionCelebrationDialog(
        projectName: projectName,
        aiPraiseMessage: aiPraiseMessage,
      ),
    );
  }
}
