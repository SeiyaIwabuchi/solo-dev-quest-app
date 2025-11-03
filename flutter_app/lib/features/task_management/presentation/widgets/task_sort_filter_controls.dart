import 'package:flutter/material.dart';

import '../../domain/enums/task_sort_by.dart';
import '../../domain/enums/task_filter_state.dart';

/// タスクのソート・フィルターコントロール
class TaskSortFilterControls extends StatelessWidget {
  const TaskSortFilterControls({
    super.key,
    required this.currentSortBy,
    required this.currentFilterState,
    required this.onSortChanged,
    required this.onFilterChanged,
  });

  final TaskSortBy currentSortBy;
  final TaskFilterState currentFilterState;
  final ValueChanged<TaskSortBy> onSortChanged;
  final ValueChanged<TaskFilterState> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // ソートボタン
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showSortMenu(context),
              icon: const Icon(Icons.sort, size: 20),
              label: Text(
                _getSortLabel(currentSortBy),
                style: const TextStyle(fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // フィルターボタン
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showFilterMenu(context),
              icon: Icon(
                Icons.filter_list,
                size: 20,
                color: currentFilterState != TaskFilterState.all
                    ? theme.colorScheme.primary
                    : null,
              ),
              label: Text(
                currentFilterState.displayName,
                style: TextStyle(
                  fontSize: 14,
                  color: currentFilterState != TaskFilterState.all
                      ? theme.colorScheme.primary
                      : null,
                  fontWeight: currentFilterState != TaskFilterState.all
                      ? FontWeight.bold
                      : null,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                side: currentFilterState != TaskFilterState.all
                    ? BorderSide(color: theme.colorScheme.primary, width: 2)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(TaskSortBy sortBy) {
    switch (sortBy) {
      case TaskSortBy.createdAt:
        return '作成日順';
      case TaskSortBy.dueDate:
        return '期限順';
    }
  }

  void _showSortMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                'ソート順',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Divider(height: 1),
            _buildSortOption(
              context,
              TaskSortBy.createdAt,
              '作成日順',
              '新しいタスクから表示',
              Icons.access_time,
            ),
            _buildSortOption(
              context,
              TaskSortBy.dueDate,
              '期限順',
              '期限が近いタスクから表示',
              Icons.calendar_today,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    TaskSortBy sortBy,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = currentSortBy == sortBy;
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? theme.colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? theme.colorScheme.primary : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(Icons.check, color: theme.colorScheme.primary)
          : null,
      onTap: () {
        Navigator.pop(context);
        onSortChanged(sortBy);
      },
    );
  }

  void _showFilterMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                'フィルター',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Divider(height: 1),
            _buildFilterOption(
              context,
              TaskFilterState.all,
              'すべてのタスク',
              Icons.checklist,
            ),
            _buildFilterOption(
              context,
              TaskFilterState.uncompleted,
              '未完了のタスク',
              Icons.radio_button_unchecked,
            ),
            _buildFilterOption(
              context,
              TaskFilterState.completed,
              '完了済みのタスク',
              Icons.check_circle,
            ),
            _buildFilterOption(
              context,
              TaskFilterState.overdue,
              '期限超過のタスク',
              Icons.warning_amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    TaskFilterState filterState,
    String title,
    IconData icon,
  ) {
    final isSelected = currentFilterState == filterState;
    final theme = Theme.of(context);

    return ListTile(
      leading: Text(
        filterState.icon,
        style: const TextStyle(fontSize: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? theme.colorScheme.primary : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: theme.colorScheme.primary)
          : null,
      onTap: () {
        Navigator.pop(context);
        onFilterChanged(filterState);
      },
    );
  }
}
