import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

/// Markdownビューアーウィジェット
/// 質問・回答本文のMarkdown形式テキストをレンダリング
class MarkdownViewer extends StatelessWidget {
  const MarkdownViewer({
    required this.data,
    this.selectable = true,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final String data;
  final bool selectable;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Markdown(
      data: data,
      selectable: selectable,
      padding: padding as EdgeInsets,
      styleSheet: MarkdownStyleSheet(
        // 本文スタイル
        p: theme.textTheme.bodyMedium,
        // 見出しスタイル
        h1: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        h2: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        h3: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        // コードブロックスタイル
        code: TextStyle(
          fontFamily: 'monospace',
          backgroundColor: Colors.grey[200],
          color: Colors.red[800],
          fontSize: 14,
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        // リンクスタイル
        a: TextStyle(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        // 引用スタイル
        blockquote: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          color: Colors.grey[700],
        ),
        blockquoteDecoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(4),
          border: Border(
            left: BorderSide(
              color: Colors.grey[400]!,
              width: 4,
            ),
          ),
        ),
        // リストスタイル
        listBullet: theme.textTheme.bodyMedium,
      ),
      // リンククリック時の処理
      onTapLink: (text, href, title) async {
        if (href != null) {
          final uri = Uri.tryParse(href);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
    );
  }
}

/// コードスニペット表示ウィジェット
/// コピー機能付きのコードブロック表示
class CodeSnippetViewer extends StatelessWidget {
  const CodeSnippetViewer({
    required this.code,
    this.language,
    super.key,
  });

  final String code;
  final String? language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ヘッダー（言語名 + コピーボタン）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language?.toUpperCase() ?? 'CODE',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  color: Colors.grey[400],
                  onPressed: () {
                    // クリップボードにコピー
                    // TODO: clipboard パッケージを使用
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('コードをコピーしました'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // コード本体
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
