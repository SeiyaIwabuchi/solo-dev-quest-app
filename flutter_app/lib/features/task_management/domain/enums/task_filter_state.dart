/// タスクのフィルター状態を指定するEnum
enum TaskFilterState {
  /// すべてのタスク
  all,

  /// 完了済みタスクのみ
  completed,

  /// 未完了タスクのみ
  uncompleted,

  /// 期限超過タスクのみ
  overdue,
}

extension TaskFilterStateExtension on TaskFilterState {
  /// フィルター状態の表示名
  String get displayName {
    switch (this) {
      case TaskFilterState.all:
        return 'すべて';
      case TaskFilterState.completed:
        return '完了済み';
      case TaskFilterState.uncompleted:
        return '未完了';
      case TaskFilterState.overdue:
        return '期限超過';
    }
  }

  /// フィルター状態のアイコン
  String get icon {
    switch (this) {
      case TaskFilterState.all:
        return '📋';
      case TaskFilterState.completed:
        return '✅';
      case TaskFilterState.uncompleted:
        return '⏳';
      case TaskFilterState.overdue:
        return '⚠️';
    }
  }
}
