import 'package:flutter/material.dart';

/// A reusable error dialog widget for displaying authentication errors
///
/// Usage:
/// ```dart
/// ErrorDialog.show(
///   context: context,
///   title: 'エラー',
///   message: 'ログインに失敗しました',
/// );
/// ```
class ErrorDialog extends StatelessWidget {
  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  /// The error dialog title
  final String title;

  /// The error message to display
  final String message;

  /// Optional custom action button label (defaults to "閉じる")
  final String? actionLabel;

  /// Optional callback when action button is pressed
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.error_outline,
        color: Colors.red,
        size: 48,
      ),
      title: Text(title),
      content: Text(
        message,
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onAction?.call();
          },
          child: Text(actionLabel ?? '閉じる'),
        ),
      ],
    );
  }

  /// Shows an error dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }

  /// Shows a network error dialog with retry option
  static Future<void> showNetworkError({
    required BuildContext context,
    required VoidCallback onRetry,
  }) {
    return show(
      context: context,
      title: 'ネットワークエラー',
      message: 'インターネット接続を確認して、もう一度お試しください。',
      actionLabel: '再試行',
      onAction: onRetry,
    );
  }

  /// Shows a generic authentication error dialog
  static Future<void> showAuthError({
    required BuildContext context,
    required String message,
  }) {
    return show(
      context: context,
      title: '認証エラー',
      message: message,
    );
  }
}
