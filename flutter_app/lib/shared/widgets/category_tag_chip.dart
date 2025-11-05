import 'package:flutter/material.dart';

/// カテゴリタグチップウィジェット
/// 質問のカテゴリを視覚的に表示するUI部品
class CategoryTagChip extends StatelessWidget {
  const CategoryTagChip({
    required this.categoryTag,
    this.onTap,
    this.isSelected = false,
    super.key,
  });

  final String categoryTag;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    // カテゴリごとの色マッピング
    final categoryColors = {
      'Flutter': Colors.blue,
      'Firebase': Colors.orange,
      'Dart': Colors.teal,
      'Backend': Colors.purple,
      'Design': Colors.pink,
      'Other': Colors.grey,
    };

    final color = categoryColors[categoryTag] ?? Colors.grey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Chip(
        label: Text(
          categoryTag,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
        backgroundColor: isSelected ? color : color.withOpacity(0.1),
        side: BorderSide(
          color: color,
          width: isSelected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}

/// カテゴリフィルターチップリスト
/// 複数のカテゴリタグを横スクロール可能なリストで表示
class CategoryFilterChips extends StatelessWidget {
  const CategoryFilterChips({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    super.key,
  });

  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 「すべて」フィルター
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CategoryTagChip(
              categoryTag: 'すべて',
              isSelected: selectedCategory == null,
              onTap: () => onCategorySelected(null),
            ),
          ),
          // 各カテゴリフィルター
          ...categories.map((category) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CategoryTagChip(
                  categoryTag: category,
                  isSelected: selectedCategory == category,
                  onTap: () => onCategorySelected(category),
                ),
              )),
        ],
      ),
    );
  }
}
