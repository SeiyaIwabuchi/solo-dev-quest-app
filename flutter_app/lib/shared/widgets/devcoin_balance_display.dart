import 'package:flutter/material.dart';

/// DevCoin残高表示ウィジェット
/// ユーザーのDevCoin残高を視覚的に表示するUI部品
class DevCoinBalanceDisplay extends StatelessWidget {
  const DevCoinBalanceDisplay({
    required this.balance,
    this.size = DevCoinDisplaySize.medium,
    this.showLabel = true,
    this.onTap,
    super.key,
  });

  final int balance;
  final DevCoinDisplaySize size;
  final bool showLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // サイズに応じたスタイル
    final iconSize = switch (size) {
      DevCoinDisplaySize.small => 16.0,
      DevCoinDisplaySize.medium => 24.0,
      DevCoinDisplaySize.large => 32.0,
    };

    final textStyle = switch (size) {
      DevCoinDisplaySize.small => theme.textTheme.bodySmall,
      DevCoinDisplaySize.medium => theme.textTheme.bodyLarge,
      DevCoinDisplaySize.large => theme.textTheme.headlineSmall,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.amber,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // DevCoinアイコン（コインのイラスト）
            Icon(
              Icons.monetization_on,
              color: Colors.amber,
              size: iconSize,
            ),
            const SizedBox(width: 6),
            // 残高表示
            Text(
              _formatBalance(balance),
              style: textStyle?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.amber[800],
              ),
            ),
            if (showLabel) ...[
              const SizedBox(width: 4),
              Text(
                'DevCoin',
                style: textStyle?.copyWith(
                  fontSize: (textStyle.fontSize ?? 14) * 0.8,
                  color: Colors.amber[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 残高をカンマ区切りでフォーマット
  String _formatBalance(int balance) {
    return balance.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

/// DevCoin残高変動アニメーション付き表示
/// 残高が増減した際にアニメーションで視覚的フィードバックを提供
class AnimatedDevCoinBalanceDisplay extends StatefulWidget {
  const AnimatedDevCoinBalanceDisplay({
    required this.balance,
    this.size = DevCoinDisplaySize.medium,
    this.showLabel = true,
    this.onTap,
    super.key,
  });

  final int balance;
  final DevCoinDisplaySize size;
  final bool showLabel;
  final VoidCallback? onTap;

  @override
  State<AnimatedDevCoinBalanceDisplay> createState() =>
      _AnimatedDevCoinBalanceDisplayState();
}

class _AnimatedDevCoinBalanceDisplayState
    extends State<AnimatedDevCoinBalanceDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedDevCoinBalanceDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.balance != widget.balance) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: DevCoinBalanceDisplay(
            balance: widget.balance,
            size: widget.size,
            showLabel: widget.showLabel,
            onTap: widget.onTap,
          ),
        );
      },
    );
  }
}

/// DevCoin表示サイズ
enum DevCoinDisplaySize {
  small,
  medium,
  large,
}
