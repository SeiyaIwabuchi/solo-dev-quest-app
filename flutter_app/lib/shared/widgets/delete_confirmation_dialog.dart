import 'package:flutter/material.dart';

/// 削除確認ダイアログ
/// 
/// プロジェクトやタスクなどのリソースを削除する前に、
/// ユーザーに確認を求める再利用可能なダイアログウィジェット。
class DeleteConfirmationDialog extends StatelessWidget {
  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.warningMessage,
    this.confirmButtonText = '削除',
    this.cancelButtonText = 'キャンセル',
  });

  /// ダイアログのタイトル
  final String title;

  /// 確認メッセージ
  final String message;

  /// 警告メッセージ（オプション）
  /// 例: "このプロジェクトには10個のタスクが含まれています"
  final String? warningMessage;

  /// 確認ボタンのテキスト
  final String confirmButtonText;

  /// キャンセルボタンのテキスト
  final String cancelButtonText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: colorScheme.error,
        size: 48,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyLarge,
          ),
          if (warningMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warningMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelButtonText),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: Text(confirmButtonText),
        ),
      ],
    );
  }

  /// ダイアログを表示する静的メソッド
  /// 
  /// [context] - ビルドコンテキスト
  /// [title] - ダイアログのタイトル
  /// [message] - 確認メッセージ
  /// [warningMessage] - 警告メッセージ（オプション）
  /// [confirmButtonText] - 確認ボタンのテキスト（デフォルト: "削除"）
  /// [cancelButtonText] - キャンセルボタンのテキスト（デフォルト: "キャンセル"）
  /// 
  /// 戻り値: ユーザーが削除を確認した場合は true、キャンセルした場合は false
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String? warningMessage,
    String confirmButtonText = '削除',
    String cancelButtonText = 'キャンセル',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: title,
        message: message,
        warningMessage: warningMessage,
        confirmButtonText: confirmButtonText,
        cancelButtonText: cancelButtonText,
      ),
    );

    return result ?? false;
  }
}
