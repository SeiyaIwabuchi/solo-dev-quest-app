import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_statistics.freezed.dart';
part 'task_statistics.g.dart';

/// タスク統計情報モデル
@freezed
class TaskStatistics with _$TaskStatistics {
  const factory TaskStatistics({
    /// 総タスク数
    required int totalTasks,

    /// 完了タスク数
    required int completedTasks,

    /// 期限超過タスク数
    required int overdueTasks,
  }) = _TaskStatistics;

  const TaskStatistics._();

  /// JSONからTaskStatisticsオブジェクトを生成
  factory TaskStatistics.fromJson(Map<String, dynamic> json) =>
      _$TaskStatisticsFromJson(json);

  /// 完了率を計算（0-100）
  double get completionRate {
    if (totalTasks == 0) return 0.0;
    return (completedTasks / totalTasks) * 100;
  }

  /// プロジェクト完了判定
  bool get isProjectCompleted {
    return totalTasks > 0 && completedTasks == totalTasks;
  }
}
