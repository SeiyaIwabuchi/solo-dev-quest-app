import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task.dart';
import '../models/task_statistics.dart';
import '../../domain/enums/task_sort_by.dart';
import 'i_task_repository.dart';
import '../../../../core/exceptions/validation_exception.dart';
import '../../../../core/exceptions/not_found_exception.dart';

/// Firestoreを使用したタスクリポジトリの実装
class FirestoreTaskRepository implements ITaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// タスクコレクションの参照
  CollectionReference get _tasksCollection => _firestore.collection('tasks');

  @override
  Stream<List<Task>> watchProjectTasks({
    required String projectId,
    TaskSortBy sortBy = TaskSortBy.createdAt,
    bool? filterCompleted,
    int limit = 30,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query query = _tasksCollection.where('projectId', isEqualTo: projectId);

    // 完了フィルター
    if (filterCompleted != null) {
      query = query.where('isCompleted', isEqualTo: filterCompleted);
    }

    // ソート
    switch (sortBy) {
      case TaskSortBy.createdAt:
        query = query.orderBy('createdAt', descending: true);
        break;
      case TaskSortBy.dueDate:
        query = query.orderBy('dueDate', descending: false);
        break;
    }

    // ページネーション
    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList());
  }

  @override
  Future<(List<Task>, DocumentSnapshot?)> getProjectTasks({
    required String projectId,
    TaskSortBy sortBy = TaskSortBy.createdAt,
    bool? filterCompleted,
    int limit = 30,
    DocumentSnapshot? startAfterDoc,
  }) async {
    Query query = _tasksCollection.where('projectId', isEqualTo: projectId);

    // 完了フィルター
    if (filterCompleted != null) {
      query = query.where('isCompleted', isEqualTo: filterCompleted);
    }

    // ソート
    switch (sortBy) {
      case TaskSortBy.createdAt:
        query = query.orderBy('createdAt', descending: true);
        break;
      case TaskSortBy.dueDate:
        query = query.orderBy('dueDate', descending: false);
        break;
    }

    // ページネーション
    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    query = query.limit(limit);

    // オフライン対応: キャッシュから取得を優先、失敗したらサーバーから取得
    QuerySnapshot snapshot;
    try {
      snapshot = await query.get(const GetOptions(source: Source.cache));
    } catch (_) {
      // キャッシュがない場合はサーバーから取得
      snapshot = await query.get();
    }
    
    final tasks = snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

    return (tasks, lastDoc);
  }

  @override
  Stream<Task?> watchTask({required String taskId}) {
    return _tasksCollection.doc(taskId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Task.fromFirestore(doc);
    });
  }

  @override
  Future<Task> createTask({
    required String projectId,
    required String userId,
    required String name,
    String? description,
    DateTime? dueDate,
  }) async {
    // バリデーション
    _validateTaskName(name);
    _validateTaskDescription(description);

    final now = DateTime.now();
    final docRef = _tasksCollection.doc();

    final task = Task(
      id: docRef.id,
      projectId: projectId,
      userId: userId,
      name: name,
      description: description,
      dueDate: dueDate,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      completedAt: null,
    );

    // オフライン対応: setは非同期で実行し、即座にローカルタスクを返す
    docRef.set(task.toFirestore()).catchError((error) {
      print('Failed to create task (will retry when online): $error');
    });
    
    return task;
  }

  @override
  Future<Task> updateTask({
    required String taskId,
    required String name,
    String? description,
    DateTime? dueDate,
  }) async {
    // バリデーション
    _validateTaskName(name);
    _validateTaskDescription(description);

    final docRef = _tasksCollection.doc(taskId);
    
    // オフライン対応: キャッシュから取得
    final doc = await docRef.get(const GetOptions(source: Source.cache))
        .catchError((_) => docRef.get());

    if (!doc.exists) {
      throw NotFoundException(
        'タスクが見つかりません',
        resourceType: 'Task',
        resourceId: taskId,
      );
    }

    // 同時編集競合処理: Last Write Wins戦略
    // Firestoreのサーバータイムスタンプにより、最後の書き込みが優先される
    // 複数のユーザーが同時に編集した場合、最後に保存した内容が反映される
    final currentTask = Task.fromFirestore(doc);
    final updatedTask = currentTask.copyWith(
      name: name,
      description: description,
      dueDate: dueDate,
      updatedAt: DateTime.now(),
    );

    // オフライン対応: updateは非同期で実行し、即座に更新済みタスクを返す
    docRef.update(updatedTask.toFirestore()).catchError((error) {
      print('Failed to update task (will retry when online): $error');
    });
    
    return updatedTask;
  }

  @override
  Future<Task> toggleTaskCompletion({
    required String taskId,
    required bool isCompleted,
  }) async {
    final docRef = _tasksCollection.doc(taskId);
    
    // オフライン対応: キャッシュから取得
    final doc = await docRef.get(const GetOptions(source: Source.cache))
        .catchError((_) => docRef.get());

    if (!doc.exists) {
      throw NotFoundException(
        'タスクが見つかりません',
        resourceType: 'Task',
        resourceId: taskId,
      );
    }

    final currentTask = Task.fromFirestore(doc);
    final now = DateTime.now();

    final updatedTask = currentTask.copyWith(
      isCompleted: isCompleted,
      completedAt: isCompleted ? now : null,
      updatedAt: now,
    );

    // オフライン対応: updateは非同期で実行し、即座に更新済みタスクを返す
    docRef.update(updatedTask.toFirestore()).catchError((error) {
      print('Failed to toggle task completion (will retry when online): $error');
    });
    
    return updatedTask;
  }

  @override
  Future<void> deleteTask({required String taskId}) async {
    // オフライン対応: deleteは非同期で実行
    _tasksCollection.doc(taskId).delete().catchError((error) {
      print('Failed to delete task (will retry when online): $error');
    });
  }

  @override
  Future<TaskStatistics> getProjectTaskStatistics({
    required String projectId,
  }) async {
    // オフライン対応: キャッシュから取得を優先
    QuerySnapshot tasksSnapshot;
    try {
      tasksSnapshot = await _tasksCollection
          .where('projectId', isEqualTo: projectId)
          .get(const GetOptions(source: Source.cache));
    } catch (_) {
      tasksSnapshot = await _tasksCollection
          .where('projectId', isEqualTo: projectId)
          .get();
    }

    final totalTasks = tasksSnapshot.docs.length;
    final completedTasks = tasksSnapshot.docs
        .where((doc) => (doc.data() as Map<String, dynamic>)['isCompleted'] == true)
        .length;

    final now = DateTime.now();
    final overdueTasks = tasksSnapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['isCompleted'] == true) return false;
      if (data['dueDate'] == null) return false;
      return (data['dueDate'] as Timestamp).toDate().isBefore(now);
    }).length;

    return TaskStatistics(
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      overdueTasks: overdueTasks,
    );
  }

  @override
  Future<bool> exists({required String taskId}) async {
    // オフライン対応: キャッシュから取得を優先
    DocumentSnapshot doc;
    try {
      doc = await _tasksCollection.doc(taskId).get(const GetOptions(source: Source.cache));
    } catch (_) {
      doc = await _tasksCollection.doc(taskId).get();
    }
    return doc.exists;
  }

  /// タスク名のバリデーション
  void _validateTaskName(String name) {
    if (name.trim().isEmpty) {
      throw const ValidationException(
        'タスク名を入力してください',
        fieldName: 'name',
      );
    }
    if (name.length > 200) {
      throw const ValidationException(
        'タスク名は200文字以内で入力してください',
        fieldName: 'name',
      );
    }
  }

  /// タスク説明のバリデーション
  void _validateTaskDescription(String? description) {
    if (description != null && description.length > 1000) {
      throw const ValidationException(
        'タスク説明は1000文字以内で入力してください',
        fieldName: 'description',
      );
    }
  }
}
