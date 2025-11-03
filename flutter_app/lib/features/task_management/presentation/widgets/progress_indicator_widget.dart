import 'package:flutter/material.dart';

/// 進捗率を表示するウィジェット
class ProgressIndicatorWidget extends StatelessWidget {
  const ProgressIndicatorWidget({
    super.key,
    required this.progressRate,
    this.height = 8.0,
    this.showPercentage = true,
    this.borderRadius = 4.0,
  });

  /// 進捗率 (0-100)
  final double progressRate;
  
  /// プログレスバーの高さ
  final double height;
  
  /// パーセンテージを表示するかどうか
  final bool showPercentage;
  
  /// ボーダーの丸み
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedProgress = (progressRate / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showPercentage)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '進捗率',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${progressRate.toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getProgressColor(theme, normalizedProgress),
                ),
              ),
            ],
          ),
        if (showPercentage) const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: LinearProgressIndicator(
            value: normalizedProgress,
            minHeight: height,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(theme, normalizedProgress),
            ),
          ),
        ),
      ],
    );
  }

  /// 進捗率に応じた色を取得
  Color _getProgressColor(ThemeData theme, double progress) {
    if (progress >= 1.0) {
      // 100%完了: 成功色
      return theme.colorScheme.primary;
    } else if (progress >= 0.5) {
      // 50%以上: プライマリ色
      return theme.colorScheme.primary;
    } else if (progress > 0) {
      // 50%未満: 警告色
      return Colors.orange;
    } else {
      // 0%: グレー
      return theme.colorScheme.onSurfaceVariant;
    }
  }
}
