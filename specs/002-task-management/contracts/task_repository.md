# Task Repository Contract

**Feature**: 002-task-management  
**Interface**: `ITaskRepository`  
**Purpose**: タスクのCRUD操作とクエリのためのリポジトリインターフェース

---

## Interface Definition

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

/// タスクリポジトリインターフェース
/// 
/// 実装:
/// - FirestoreTaskRepository: 本番用Firestore接続
/// - FakeTaskRepository: テスト用メモリ内実装
abstract class ITaskRepository {
  /// プロジェクトの全タスクをストリームで取得
  /// 
  /// [projectId] 取得対象プロジェクトID
  /// [limit] 取得件数上限（デフォルト: 30 for infinite scroll）
  /// [startAfterDoc] ページネーション用カーソル（次ページ取得時に指定）
  /// [sortBy] ソート基準（createdAt or dueDate）
  /// [filterCompleted] 完了状態フィルター（null=全て、true=完了のみ、false=未完了のみ）
  /// 
  /// Returns: タスクリストのストリーム（指定順）
  /// 
  /// Throws: 
  /// - [FirebaseException] Firestore接続エラー時
  Stream<List<Task>> watchProjectTasks({
    required String projectId,
    int limit = 30,
    DocumentSnapshot? startAfterDoc,
    TaskSortBy sortBy = TaskSortBy.createdAt,
    bool? filterCompleted,
  });
  
  /// タスクIDで単一タスクをストリームで取得
  /// 
  /// [taskId] 取得対象タスクID
  /// 
  /// Returns: タスクのストリーム（存在しない場合null）
  /// 
  /// Throws: 
  /// - [FirebaseException] Firestore接続エラー時
  Stream<Task?> watchTask(String taskId);
  
  /// 新規タスクを作成
  /// 
  /// [projectId] 所属プロジェクトID
  /// [userId] タスク所有者のユーザーID（プロジェクト所有者と一致必須）
  /// [name] タスク名（1-200文字）
  /// [description] タスク説明（NULL許可、最大1000文字）
  /// [dueDate] 期限日時（NULL許可）
  /// 
  /// Returns: 作成されたタスク（IDを含む）
  /// 
  /// Throws: 
  /// - [ValidationException] バリデーションエラー
  /// - [FirebaseException] Firestore書き込みエラー時
  /// 
  /// Business Rules:
  /// - isCompleted は自動的に false が設定される
  /// - completedAt は null
  /// - createdAt, updatedAt は自動的にサーバータイムスタンプが設定される
  Future<Task> createTask({
    required String projectId,
    required String userId,
    required String name,
    String? description,
    DateTime? dueDate,
  });
  
  /// 既存タスクを更新
  /// 
  /// [taskId] 更新対象タスクID
  /// [name] 新しいタスク名（NULL時は変更なし）
  /// [description] 新しい説明（NULL時は変更なし）
  /// [dueDate] 新しい期限（NULL時は変更なし）
  /// 
  /// Returns: 更新後のタスク
  /// 
  /// Throws: 
  /// - [NotFoundException] タスクが存在しない場合
  /// - [ValidationException] バリデーションエラー
  /// - [FirebaseException] Firestore書き込みエラー時
  /// 
  /// Business Rules:
  /// - updatedAt は自動的にサーバータイムスタンプが更新される
  /// - projectId, userId, isCompleted, completedAt は変更不可（専用メソッドを使用）
  Future<Task> updateTask({
    required String taskId,
    String? name,
    String? description,
    DateTime? dueDate,
  });
  
  /// タスクの完了状態を切り替え
  /// 
  /// [taskId] 対象タスクID
  /// [isCompleted] 新しい完了状態
  /// 
  /// Returns: 更新後のタスク
  /// 
  /// Throws: 
  /// - [NotFoundException] タスクが存在しない場合
  /// - [FirebaseException] Firestore書き込みエラー時
  /// 
  /// Business Rules:
  /// - isCompleted = true の場合、completedAt = DateTime.now()
  /// - isCompleted = false の場合、completedAt = null
  /// - updatedAt も更新される
  Future<Task> toggleTaskCompletion({
    required String taskId,
    required bool isCompleted,
  });
  
  /// タスクを削除
  /// 
  /// [taskId] 削除対象タスクID
  /// 
  /// Returns: void
  /// 
  /// Throws: 
  /// - [NotFoundException] タスクが存在しない場合
  /// - [FirebaseException] Firestore書き込みエラー時
  Future<void> deleteTask(String taskId);
  
  /// プロジェクトのタスク統計を取得（Progress Metrics計算用）
  /// 
  /// [projectId] 対象プロジェクトID
  /// 
  /// Returns: タスク統計情報
  /// 
  /// Throws: 
  /// - [FirebaseException] Firestore接続エラー時
  Future<TaskStatistics> getProjectTaskStatistics(String projectId);
  
  /// タスクの存在確認
  /// 
  /// [taskId] 確認対象タスクID
  /// 
  /// Returns: 存在する場合true
  Future<bool> exists(String taskId);
}

/// タスクソート基準
enum TaskSortBy {
  /// 作成日時降順（デフォルト）
  createdAt,
  /// 期限昇順
  dueDate,
}
```

---

## Data Transfer Objects (DTOs)

### CreateTaskRequest

```dart
/// タスク作成リクエスト
@freezed
class CreateTaskRequest with _$CreateTaskRequest {
  const factory CreateTaskRequest({
    required String name,
    String? description,
    DateTime? dueDate,
  }) = _CreateTaskRequest;
  
  factory CreateTaskRequest.fromJson(Map<String, dynamic> json) 
      => _$CreateTaskRequestFromJson(json);
}
```

### UpdateTaskRequest

```dart
/// タスク更新リクエスト
@freezed
class UpdateTaskRequest with _$UpdateTaskRequest {
  const factory UpdateTaskRequest({
    String? name,
    String? description,
    DateTime? dueDate,
  }) = _UpdateTaskRequest;
  
  factory UpdateTaskRequest.fromJson(Map<String, dynamic> json) 
      => _$UpdateTaskRequestFromJson(json);
}
```

### TaskStatistics

```dart
/// タスク統計情報（Progress Metrics用）
@freezed
class TaskStatistics with _$TaskStatistics {
  const factory TaskStatistics({
    required int totalTasks,
    required int completedTasks,
    required int overdueTasks,
  }) = _TaskStatistics;
  
  const TaskStatistics._();
  
  /// 完了率 (0-100)
  double get completionRate {
    if (totalTasks == 0) return 0.0;
    return (completedTasks / totalTasks) * 100;
  }
  
  /// プロジェクト完了判定
  bool get isProjectCompleted {
    return totalTasks > 0 && completedTasks == totalTasks;
  }
  
  factory TaskStatistics.fromJson(Map<String, dynamic> json) 
      => _$TaskStatisticsFromJson(json);
}
```

---

## Implementation Notes

### Firestore Implementation Example

```dart
class FirestoreTaskRepository implements ITaskRepository {
  final FirebaseFirestore _firestore;
  final String _collectionPath = 'tasks';
  
  FirestoreTaskRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  @override
  Stream<List<Task>> watchProjectTasks({
    required String projectId,
    int limit = 30,
    DocumentSnapshot? startAfterDoc,
    TaskSortBy sortBy = TaskSortBy.createdAt,
    bool? filterCompleted,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_collectionPath)
        .where('projectId', isEqualTo: projectId);
    
    // Filter by completion status
    if (filterCompleted != null) {
      query = query.where('isCompleted', isEqualTo: filterCompleted);
    }
    
    // Sort
    switch (sortBy) {
      case TaskSortBy.createdAt:
        query = query.orderBy('createdAt', descending: true);
        break;
      case TaskSortBy.dueDate:
        query = query.orderBy('dueDate', descending: false);
        break;
    }
    
    // Pagination
    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }
    
    query = query.limit(limit);
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Task.fromFirestore(doc))
          .toList();
    });
  }
  
  @override
  Stream<Task?> watchTask(String taskId) {
    return _firestore
        .collection(_collectionPath)
        .doc(taskId)
        .snapshots()
        .map((doc) {
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
    // Validation
    if (name.trim().isEmpty || name.length > 200) {
      throw ValidationException('タスク名は1-200文字である必要があります');
    }
    
    if (description != null && description.length > 1000) {
      throw ValidationException('説明は1000文字以内である必要があります');
    }
    
    final now = DateTime.now();
    final docRef = _firestore.collection(_collectionPath).doc();
    
    final task = Task(
      id: docRef.id,
      projectId: projectId,
      userId: userId,
      name: name.trim(),
      description: description?.trim(),
      dueDate: dueDate,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      completedAt: null,
    );
    
    await docRef.set(task.toFirestore());
    
    return task;
  }
  
  @override
  Future<Task> updateTask({
    required String taskId,
    String? name,
    String? description,
    DateTime? dueDate,
  }) async {
    final docRef = _firestore.collection(_collectionPath).doc(taskId);
    final docSnapshot = await docRef.get();
    
    if (!docSnapshot.exists) {
      throw NotFoundException('タスクが見つかりません: $taskId');
    }
    
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (name != null) {
      if (name.trim().isEmpty || name.length > 200) {
        throw ValidationException('タスク名は1-200文字である必要があります');
      }
      updates['name'] = name.trim();
    }
    
    if (description != null) {
      if (description.length > 1000) {
        throw ValidationException('説明は1000文字以内である必要があります');
      }
      updates['description'] = description.trim();
    }
    
    if (dueDate != null) {
      updates['dueDate'] = Timestamp.fromDate(dueDate);
    }
    
    await docRef.update(updates);
    
    final updatedDoc = await docRef.get();
    return Task.fromFirestore(updatedDoc);
  }
  
  @override
  Future<Task> toggleTaskCompletion({
    required String taskId,
    required bool isCompleted,
  }) async {
    final docRef = _firestore.collection(_collectionPath).doc(taskId);
    final docSnapshot = await docRef.get();
    
    if (!docSnapshot.exists) {
      throw NotFoundException('タスクが見つかりません: $taskId');
    }
    
    final now = DateTime.now();
    
    await docRef.update({
      'isCompleted': isCompleted,
      'completedAt': isCompleted ? Timestamp.fromDate(now) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    final updatedDoc = await docRef.get();
    return Task.fromFirestore(updatedDoc);
  }
  
  @override
  Future<void> deleteTask(String taskId) async {
    final docRef = _firestore.collection(_collectionPath).doc(taskId);
    final docSnapshot = await docRef.get();
    
    if (!docSnapshot.exists) {
      throw NotFoundException('タスクが見つかりません: $taskId');
    }
    
    await docRef.delete();
  }
  
  @override
  Future<TaskStatistics> getProjectTaskStatistics(String projectId) async {
    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('projectId', isEqualTo: projectId)
        .get();
    
    final totalTasks = snapshot.docs.length;
    final completedTasks = snapshot.docs
        .where((doc) => doc.data()['isCompleted'] == true)
        .length;
    
    final now = DateTime.now();
    final overdueTasks = snapshot.docs.where((doc) {
      final data = doc.data();
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
  Future<bool> exists(String taskId) async {
    final doc = await _firestore
        .collection(_collectionPath)
        .doc(taskId)
        .get();
    return doc.exists;
  }
}
```

### Fake Implementation Example (for Testing)

```dart
class FakeTaskRepository implements ITaskRepository {
  final Map<String, Task> _tasks = {};
  
  @override
  Stream<List<Task>> watchProjectTasks({
    required String projectId,
    int limit = 30,
    DocumentSnapshot? startAfterDoc,
    TaskSortBy sortBy = TaskSortBy.createdAt,
    bool? filterCompleted,
  }) {
    var projectTasks = _tasks.values
        .where((t) => t.projectId == projectId)
        .toList();
    
    // Filter
    if (filterCompleted != null) {
      projectTasks = projectTasks
          .where((t) => t.isCompleted == filterCompleted)
          .toList();
    }
    
    // Sort
    switch (sortBy) {
      case TaskSortBy.createdAt:
        projectTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case TaskSortBy.dueDate:
        projectTasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
    }
    
    // Limit
    return Stream.value(projectTasks.take(limit).toList());
  }
  
  @override
  Stream<Task?> watchTask(String taskId) {
    return Stream.value(_tasks[taskId]);
  }
  
  @override
  Future<Task> createTask({
    required String projectId,
    required String userId,
    required String name,
    String? description,
    DateTime? dueDate,
  }) async {
    final id = 'task_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    
    final task = Task(
      id: id,
      projectId: projectId,
      userId: userId,
      name: name.trim(),
      description: description?.trim(),
      dueDate: dueDate,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      completedAt: null,
    );
    
    _tasks[id] = task;
    return task;
  }
  
  @override
  Future<Task> updateTask({
    required String taskId,
    String? name,
    String? description,
    DateTime? dueDate,
  }) async {
    final existing = _tasks[taskId];
    if (existing == null) {
      throw NotFoundException('タスクが見つかりません: $taskId');
    }
    
    final updated = existing.copyWith(
      name: name ?? existing.name,
      description: description ?? existing.description,
      dueDate: dueDate ?? existing.dueDate,
      updatedAt: DateTime.now(),
    );
    
    _tasks[taskId] = updated;
    return updated;
  }
  
  @override
  Future<Task> toggleTaskCompletion({
    required String taskId,
    required bool isCompleted,
  }) async {
    final existing = _tasks[taskId];
    if (existing == null) {
      throw NotFoundException('タスクが見つかりません: $taskId');
    }
    
    final now = DateTime.now();
    final updated = existing.copyWith(
      isCompleted: isCompleted,
      completedAt: isCompleted ? now : null,
      updatedAt: now,
    );
    
    _tasks[taskId] = updated;
    return updated;
  }
  
  @override
  Future<void> deleteTask(String taskId) async {
    if (!_tasks.containsKey(taskId)) {
      throw NotFoundException('タスクが見つかりません: $taskId');
    }
    _tasks.remove(taskId);
  }
  
  @override
  Future<TaskStatistics> getProjectTaskStatistics(String projectId) async {
    final projectTasks = _tasks.values
        .where((t) => t.projectId == projectId)
        .toList();
    
    final totalTasks = projectTasks.length;
    final completedTasks = projectTasks
        .where((t) => t.isCompleted)
        .length;
    final overdueTasks = projectTasks
        .where((t) => !t.isCompleted && t.isOverdue)
        .length;
    
    return TaskStatistics(
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      overdueTasks: overdueTasks,
    );
  }
  
  @override
  Future<bool> exists(String taskId) async {
    return _tasks.containsKey(taskId);
  }
}
```

---

## Error Handling

### Custom Exceptions

（`project_repository.md`と同様の例外定義を使用）

```dart
/// バリデーションエラー
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  
  @override
  String toString() => 'ValidationException: $message';
}

/// リソース未検出エラー
class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
  
  @override
  String toString() => 'NotFoundException: $message';
}
```

---

## Usage Example (Riverpod Integration)

```dart
/// タスクリポジトリのProvider
final taskRepositoryProvider = Provider<ITaskRepository>((ref) {
  // 本番環境
  return FirestoreTaskRepository();
  
  // テスト環境
  // return FakeTaskRepository();
});

/// プロジェクトのタスク一覧を監視するProvider
final projectTasksProvider = StreamProvider.family<List<Task>, String>(
  (ref, projectId) {
    final repository = ref.watch(taskRepositoryProvider);
    return repository.watchProjectTasks(projectId: projectId);
  },
);

/// 単一タスクを監視するProvider
final taskProvider = StreamProvider.family<Task?, String>(
  (ref, taskId) {
    final repository = ref.watch(taskRepositoryProvider);
    return repository.watchTask(taskId);
  },
);

/// プロジェクトの統計情報を取得するProvider
final projectStatisticsProvider = FutureProvider.family<TaskStatistics, String>(
  (ref, projectId) {
    final repository = ref.watch(taskRepositoryProvider);
    return repository.getProjectTaskStatistics(projectId);
  },
);
```

---

## Testing Strategy

### Unit Tests

```dart
void main() {
  group('ITaskRepository', () {
    late ITaskRepository repository;
    
    setUp(() {
      repository = FakeTaskRepository();
    });
    
    test('createTask creates a new task with correct fields', () async {
      final task = await repository.createTask(
        projectId: 'project123',
        userId: 'user123',
        name: 'Test Task',
        description: 'Test Description',
        dueDate: DateTime(2025, 12, 31),
      );
      
      expect(task.id, isNotEmpty);
      expect(task.projectId, 'project123');
      expect(task.userId, 'user123');
      expect(task.name, 'Test Task');
      expect(task.description, 'Test Description');
      expect(task.dueDate, DateTime(2025, 12, 31));
      expect(task.isCompleted, false);
      expect(task.completedAt, isNull);
    });
    
    test('toggleTaskCompletion updates completion status', () async {
      final task = await repository.createTask(
        projectId: 'project123',
        userId: 'user123',
        name: 'Test Task',
      );
      
      // Complete
      final completed = await repository.toggleTaskCompletion(
        taskId: task.id,
        isCompleted: true,
      );
      
      expect(completed.isCompleted, true);
      expect(completed.completedAt, isNotNull);
      
      // Uncomplete
      final uncompleted = await repository.toggleTaskCompletion(
        taskId: task.id,
        isCompleted: false,
      );
      
      expect(uncompleted.isCompleted, false);
      expect(uncompleted.completedAt, isNull);
    });
    
    test('getProjectTaskStatistics returns correct metrics', () async {
      const projectId = 'project123';
      
      // Create 3 tasks: 2 completed, 1 overdue
      await repository.createTask(
        projectId: projectId,
        userId: 'user123',
        name: 'Task 1',
      );
      
      final task2 = await repository.createTask(
        projectId: projectId,
        userId: 'user123',
        name: 'Task 2',
      );
      await repository.toggleTaskCompletion(taskId: task2.id, isCompleted: true);
      
      final task3 = await repository.createTask(
        projectId: projectId,
        userId: 'user123',
        name: 'Task 3',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      
      final stats = await repository.getProjectTaskStatistics(projectId);
      
      expect(stats.totalTasks, 3);
      expect(stats.completedTasks, 1);
      expect(stats.overdueTasks, 1);
      expect(stats.completionRate, closeTo(33.33, 0.01));
    });
  });
}
```

### Integration Tests (with Firestore Emulator)

```dart
void main() {
  setUpAll(() async {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  });
  
  group('FirestoreTaskRepository Integration', () {
    late ITaskRepository repository;
    
    setUp(() {
      repository = FirestoreTaskRepository();
    });
    
    tearDown(() async {
      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    });
    
    test('watchProjectTasks returns real-time updates', () async {
      const projectId = 'project123';
      
      final stream = repository.watchProjectTasks(projectId: projectId);
      
      // Initial state: empty
      expect(await stream.first, isEmpty);
      
      // Create task
      await repository.createTask(
        projectId: projectId,
        userId: 'user123',
        name: 'Test Task',
      );
      
      // Stream should emit updated list
      final tasks = await stream.first;
      expect(tasks.length, 1);
      expect(tasks.first.name, 'Test Task');
    });
    
    test('pagination works correctly', () async {
      const projectId = 'project123';
      
      // Create 50 tasks
      for (int i = 0; i < 50; i++) {
        await repository.createTask(
          projectId: projectId,
          userId: 'user123',
          name: 'Task $i',
        );
      }
      
      // First page
      final page1 = await repository.watchProjectTasks(
        projectId: projectId,
        limit: 30,
      ).first;
      
      expect(page1.length, 30);
      
      // Second page (using cursor)
      final lastDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(page1.last.id)
          .get();
      
      final page2 = await repository.watchProjectTasks(
        projectId: projectId,
        limit: 30,
        startAfterDoc: lastDoc,
      ).first;
      
      expect(page2.length, 20);
    });
  });
}
```

---

## Performance Optimization

### Infinite Scroll Implementation

```dart
class TaskListController extends StateNotifier<AsyncValue<List<Task>>> {
  final ITaskRepository _repository;
  final String _projectId;
  
  static const int _pageSize = 30;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  
  TaskListController(this._repository, this._projectId) 
      : super(const AsyncValue.loading()) {
    _loadInitial();
  }
  
  Future<void> _loadInitial() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await _repository
          .watchProjectTasks(
            projectId: _projectId,
            limit: _pageSize,
          )
          .first;
      
      if (tasks.length < _pageSize) {
        _hasMore = false;
      }
      
      if (tasks.isNotEmpty) {
        final lastTaskId = tasks.last.id;
        _lastDocument = await FirebaseFirestore.instance
            .collection('tasks')
            .doc(lastTaskId)
            .get();
      }
      
      state = AsyncValue.data(tasks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> loadMore() async {
    if (!_hasMore || _lastDocument == null) return;
    
    try {
      final currentTasks = state.value ?? [];
      
      final moreTasks = await _repository
          .watchProjectTasks(
            projectId: _projectId,
            limit: _pageSize,
            startAfterDoc: _lastDocument,
          )
          .first;
      
      if (moreTasks.length < _pageSize) {
        _hasMore = false;
      }
      
      if (moreTasks.isNotEmpty) {
        final lastTaskId = moreTasks.last.id;
        _lastDocument = await FirebaseFirestore.instance
            .collection('tasks')
            .doc(lastTaskId)
            .get();
      }
      
      state = AsyncValue.data([...currentTasks, ...moreTasks]);
    } catch (e, stack) {
      // Keep existing data, just log error
      print('Error loading more tasks: $e');
    }
  }
  
  bool get hasMore => _hasMore;
}
```

---

## Summary

タスクリポジトリの契約が完了しました：

| メソッド | 用途 | 戻り値 |
|---------|------|--------|
| `watchProjectTasks` | プロジェクトのタスク一覧をストリーム取得（ページネーション対応） | `Stream<List<Task>>` |
| `watchTask` | 単一タスクをストリーム取得 | `Stream<Task?>` |
| `createTask` | 新規タスク作成 | `Future<Task>` |
| `updateTask` | タスク更新（名前・説明・期限） | `Future<Task>` |
| `toggleTaskCompletion` | 完了状態切り替え | `Future<Task>` |
| `deleteTask` | タスク削除 | `Future<void>` |
| `getProjectTaskStatistics` | プロジェクト統計取得 | `Future<TaskStatistics>` |
| `exists` | タスク存在確認 | `Future<bool>` |

無限スクロール実装、ソート/フィルター機能、テスト戦略が定義されました。
