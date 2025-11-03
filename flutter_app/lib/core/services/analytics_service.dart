import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase Analytics サービス
/// 
/// T092: プロジェクトとタスク管理の主要アクションを追跡
class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  /// プロジェクト作成イベント
  Future<void> logProjectCreated({
    required String projectId,
    String? projectName,
  }) async {
    await _analytics.logEvent(
      name: 'project_created',
      parameters: {
        'project_id': projectId,
        if (projectName != null) 'project_name': projectName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// タスク作成イベント
  Future<void> logTaskCreated({
    required String taskId,
    required String projectId,
    String? taskName,
    bool? hasDueDate,
  }) async {
    await _analytics.logEvent(
      name: 'task_created',
      parameters: {
        'task_id': taskId,
        'project_id': projectId,
        if (taskName != null) 'task_name': taskName,
        if (hasDueDate != null) 'has_due_date': hasDueDate,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// タスク完了イベント
  Future<void> logTaskCompleted({
    required String taskId,
    required String projectId,
    String? taskName,
  }) async {
    await _analytics.logEvent(
      name: 'task_completed',
      parameters: {
        'task_id': taskId,
        'project_id': projectId,
        if (taskName != null) 'task_name': taskName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// プロジェクト完了イベント（100%達成）
  Future<void> logProjectCompleted({
    required String projectId,
    required int totalTasks,
    String? projectName,
  }) async {
    await _analytics.logEvent(
      name: 'project_completed',
      parameters: {
        'project_id': projectId,
        if (projectName != null) 'project_name': projectName,
        'total_tasks': totalTasks,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// プロジェクト編集イベント
  Future<void> logProjectEdited({
    required String projectId,
  }) async {
    await _analytics.logEvent(
      name: 'project_edited',
      parameters: {
        'project_id': projectId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// タスク編集イベント
  Future<void> logTaskEdited({
    required String taskId,
    required String projectId,
  }) async {
    await _analytics.logEvent(
      name: 'task_edited',
      parameters: {
        'task_id': taskId,
        'project_id': projectId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// プロジェクト削除イベント
  Future<void> logProjectDeleted({
    required String projectId,
    required int taskCount,
  }) async {
    await _analytics.logEvent(
      name: 'project_deleted',
      parameters: {
        'project_id': projectId,
        'task_count': taskCount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// タスク削除イベント
  Future<void> logTaskDeleted({
    required String taskId,
    required String projectId,
  }) async {
    await _analytics.logEvent(
      name: 'task_deleted',
      parameters: {
        'task_id': taskId,
        'project_id': projectId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// カスタム画面表示イベント
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }
}

/// Analytics サービスプロバイダー
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});
