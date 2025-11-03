import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/task.dart';

/// タスクタイルウィジェット
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.onTap,
    this.onCheckboxTap,
    this.onDelete,
  });

  final Task task;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onCheckboxTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;

    final listTile = ListTile(
      leading: Checkbox(
        value: task.isCompleted,
        onChanged: onCheckboxTap != null
            ? (value) => onCheckboxTap!(value ?? false)
            : null,
      ),
      title: Text(
        task.name,
        style: theme.textTheme.bodyLarge?.copyWith(
          decoration: task.isCompleted
              ? TextDecoration.lineThrough
              : TextDecoration.none,
          color: task.isCompleted
              ? theme.colorScheme.onSurfaceVariant.withOpacity(0.6)
              : null,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              task.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: task.isCompleted
                    ? theme.colorScheme.onSurfaceVariant.withOpacity(0.5)
                    : theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (task.dueDate != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: isOverdue ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '期限: ${DateFormat('yyyy/MM/dd').format(task.dueDate!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isOverdue
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isOverdue ? FontWeight.bold : null,
                  ),
                ),
                if (isOverdue) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '期限超過',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onError,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
      trailing: task.isCompleted
          ? Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );

    // 削除機能が有効な場合はDismissibleでラップ
    if (onDelete != null) {
      return Dismissible(
        key: ValueKey(task.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: theme.colorScheme.error,
          child: Icon(
            Icons.delete,
            color: theme.colorScheme.onError,
          ),
        ),
        confirmDismiss: (direction) async {
          // 削除確認ダイアログを表示
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('タスクを削除'),
              content: Text('「${task.name}」を削除してもよろしいですか？\nこの操作は取り消せません。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  child: const Text('削除'),
                ),
              ],
            ),
          ) ?? false;
        },
        onDismissed: (direction) => onDelete!(),
        child: listTile,
      );
    }

    return listTile;
  }
}
