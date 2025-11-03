import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// T094: エラーをキャッチしてユーザーフレンドリーなメッセージを表示するウィジェット
/// 
/// アプリ全体またはサブツリーでエラーを捕捉し、Crashlyticsにレポート
class ErrorBoundary extends StatelessWidget {
  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
  });

  final Widget child;
  final void Function(Object error, StackTrace stackTrace)? onError;

  @override
  Widget build(BuildContext context) {
    return child;
  }

  /// エラーハンドラーを登録（main.dartで使用）
  static void initialize() {
    // Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    // Async errors not caught by Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
}

/// エラー画面ウィジェット
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({
    super.key,
    required this.error,
    this.stackTrace,
    this.onRetry,
  });

  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'エラーが発生しました',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '予期しないエラーが発生しました。\nもう一度お試しください。',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('再試行'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 特定のウィジェットツリー内でエラーをキャッチするラッパー
class CatchErrorWidget extends StatefulWidget {
  const CatchErrorWidget({
    super.key,
    required this.child,
    this.onError,
  });

  final Widget child;
  final void Function(Object error, StackTrace stackTrace)? onError;

  @override
  State<CatchErrorWidget> createState() => _CatchErrorWidgetState();
}

class _CatchErrorWidgetState extends State<CatchErrorWidget> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorScreen(
        error: _error!,
        stackTrace: _stackTrace,
        onRetry: () {
          setState(() {
            _error = null;
            _stackTrace = null;
          });
        },
      );
    }

    return ErrorBoundaryWrapper(
      onError: (error, stackTrace) {
        setState(() {
          _error = error;
          _stackTrace = stackTrace;
        });
        widget.onError?.call(error, stackTrace);
        
        // Crashlyticsにレポート
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: 'Caught by CatchErrorWidget',
        );
      },
      child: widget.child,
    );
  }
}

/// 内部エラーハンドリングウィジェット
class ErrorBoundaryWrapper extends StatelessWidget {
  const ErrorBoundaryWrapper({
    super.key,
    required this.child,
    required this.onError,
  });

  final Widget child;
  final void Function(Object error, StackTrace stackTrace) onError;

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      onError(details.exception, details.stack ?? StackTrace.current);
      return ErrorScreen(
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    return child;
  }
}
