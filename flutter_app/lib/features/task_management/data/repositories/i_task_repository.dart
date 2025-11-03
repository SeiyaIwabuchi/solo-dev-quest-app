import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task.dart';
import '../models/task_statistics.dart';
import '../../domain/enums/task_sort_by.dart';

/// タスクリポジトリのインターフェース
abstract class ITaskRepository {
  /// プロジェクト内のタスク一覧をリアルタイムで監視
  ///
  /// [projectId] プロジェクトID
  /// [sortBy] ソート順（デフォルト: 作成日時降順）
  /// [filterCompleted] 完了タスクのフィルター（null: すべて、true: 完了のみ、false: 未完了のみ）
  /// [limit] 取得件数制限（無限スクロール用、デフォルト: 30）
  /// [startAfterDoc] カーソルの開始位置（ページネーション用）
  /// 戻り値: タスク一覧のStream
  Stream<List<Task>> watchProjectTasks({
    required String projectId,
    TaskSortBy sortBy = TaskSortBy.createdAt,
    bool? filterCompleted,
    int limit = 30,
    DocumentSnapshot? startAfterDoc,
  });

  /// プロジェクト内のタスク一覧を一度だけ取得（無限スクロール用）
  ///
  /// [projectId] プロジェクトID
  /// [sortBy] ソート順（デフォルト: 作成日時降順）
  /// [filterCompleted] 完了タスクのフィルター（null: すべて、true: 完了のみ、false: 未完了のみ）
  /// [limit] 取得件数制限（デフォルト: 30）
  /// [startAfterDoc] カーソルの開始位置（ページネーション用）
  /// 戻り値: タスク一覧とカーソルのペア
  Future<(List<Task>, DocumentSnapshot?)> getProjectTasks({
    required String projectId,
    TaskSortBy sortBy = TaskSortBy.createdAt,
    bool? filterCompleted,
    int limit = 30,
    DocumentSnapshot? startAfterDoc,
  });

  /// 特定のタスクをリアルタイムで監視
  ///
  /// [taskId] タスクID
  /// 戻り値: タスクのStream
  Stream<Task?> watchTask({required String taskId});

  /// 新しいタスクを作成
  ///
  /// [projectId] プロジェクトID
  /// [userId] ユーザーID
  /// [name] タスク名（1-200文字）
  /// [description] タスク説明（0-1000文字、オプション）
  /// [dueDate] 期限（オプション）
  /// 戻り値: 作成されたタスク
  Future<Task> createTask({
    required String projectId,
    required String userId,
    required String name,
    String? description,
    DateTime? dueDate,
  });

  /// タスクを更新
  ///
  /// [taskId] タスクID
  /// [name] タスク名（1-200文字）
  /// [description] タスク説明（0-1000文字、オプション）
  /// [dueDate] 期限（オプション）
  /// 戻り値: 更新されたタスク
  Future<Task> updateTask({
    required String taskId,
    required String name,
    String? description,
    DateTime? dueDate,
  });

  /// タスクの完了/未完了を切り替え
  ///
  /// [taskId] タスクID
  /// [isCompleted] 完了フラグ
  /// 戻り値: 更新されたタスク
  Future<Task> toggleTaskCompletion({
    required String taskId,
    required bool isCompleted,
  });

  /// タスクを削除
  ///
  /// [taskId] タスクID
  Future<void> deleteTask({required String taskId});

  /// プロジェクトのタスク統計情報を取得
  ///
  /// [projectId] プロジェクトID
  /// 戻り値: タスク統計情報
  Future<TaskStatistics> getProjectTaskStatistics({
    required String projectId,
  });

  /// プロジェクトのタスク統計情報をリアルタイムで監視
  ///
  /// [projectId] プロジェクトID
  /// 戻り値: タスク統計情報のStream
  Stream<TaskStatistics> watchProjectTaskStatistics({
    required String projectId,
  });

  /// タスクが存在するか確認
  ///
  /// [taskId] タスクID
  /// 戻り値: 存在する場合true
  Future<bool> exists({required String taskId});
}
