import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:solo_dev_quest/core/exceptions/validation_exception.dart';
import 'package:solo_dev_quest/core/exceptions/not_found_exception.dart';
import 'package:solo_dev_quest/features/task_management/data/models/task.dart';
import 'package:solo_dev_quest/features/task_management/domain/enums/task_sort_by.dart';
import 'package:solo_dev_quest/features/task_management/data/repositories/firestore_task_repository.dart';

/// Firebase Emulator統合テスト - Task Repository
/// 
/// **実行前提条件**:
/// 1. Firebase Emulatorが起動していること（firebase emulators:start）
/// 2. Emulatorがlocalhost:8080でFirestoreを提供していること
/// 
/// **実行コマンド**:
/// ```bash
/// fvm flutter test integration_test/task_repository_integration_test.dart
/// ```
void main() {
  late FirestoreTaskRepository repository;
  const testUserId = 'test-user-123';
  const testProjectId = 'test-project-123';

  setUpAll(() async {
    // Firebase初期化（Emulator接続）
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: 'test-app-id',
        messagingSenderId: 'test-sender-id',
        projectId: 'test-project-id',
      ),
    );

    // Firebase Emulator接続設定
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    
    // Firestoreの設定（オフライン永続化無効化 - テスト用）
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  });

  setUp(() {
    repository = FirestoreTaskRepository();
  });

  tearDown(() async {
    // テスト後のクリーンアップ（全タスク削除）
    final snapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: testUserId)
        .get();
    
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  });

  group('Task Repository Integration Tests', () {
    group('createTask', () {
      test('正常にタスクを作成できること', () async {
        final task = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Test Task',
          description: 'Test Description',
          dueDate: DateTime(2025, 12, 31),
        );

        expect(task.id, isNotEmpty);
        expect(task.projectId, testProjectId);
        expect(task.userId, testUserId);
        expect(task.name, 'Test Task');
        expect(task.description, 'Test Description');
        expect(task.dueDate, DateTime(2025, 12, 31));
        expect(task.isCompleted, false);
        expect(task.completedAt, isNull);
        expect(task.createdAt, isNotNull);
        expect(task.updatedAt, isNotNull);
        
        // Firestoreに実際に保存されていることを確認
        final doc = await FirebaseFirestore.instance
            .collection('tasks')
            .doc(task.id)
            .get();
        
        expect(doc.exists, true);
        expect(doc.data()!['name'], 'Test Task');
      });

      test('説明と期限なしでタスクを作成できること', () async {
        final task = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Simple Task',
        );

        expect(task.description, isNull);
        expect(task.dueDate, isNull);
        expect(task.name, 'Simple Task');
      });

      test('タスク名が空の場合はValidationExceptionをスローすること', () async {
        expect(
          () => repository.createTask(
            projectId: testProjectId,
            userId: testUserId,
            name: '',
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('タスク名が200文字を超える場合はValidationExceptionをスローすること', () async {
        final longName = 'a' * 201;
        
        expect(
          () => repository.createTask(
            projectId: testProjectId,
            userId: testUserId,
            name: longName,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('説明が1000文字を超える場合はValidationExceptionをスローすること', () async {
        final longDescription = 'a' * 1001;
        
        expect(
          () => repository.createTask(
            projectId: testProjectId,
            userId: testUserId,
            name: 'Valid Name',
            description: longDescription,
          ),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('watchProjectTasks', () {
      test('プロジェクトのタスク一覧をリアルタイムで取得できること', () async {
        final stream = repository.watchProjectTasks(projectId: testProjectId);

        // 初期状態: 空
        expect(await stream.first, isEmpty);

        // タスクを作成
        await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Task 1',
        );

        // Streamが更新されることを確認
        final tasks = await stream.first;
        expect(tasks.length, 1);
        expect(tasks.first.name, 'Task 1');
      });

      test('作成日時降順でソートされること（デフォルト）', () async {
        // 3つのタスクを作成（時間差を確保）
        final task1 = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Task 1',
        );
        await Future.delayed(const Duration(milliseconds: 100));
        
        final task2 = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Task 2',
        );
        await Future.delayed(const Duration(milliseconds: 100));
        
        final task3 = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Task 3',
        );

        final stream = repository.watchProjectTasks(
          projectId: testProjectId,
          sortBy: TaskSortBy.createdAt,
        );
        final tasks = await stream.first;

        expect(tasks.length, 3);
        // 新しい順（降順）
        expect(tasks[0].id, task3.id);
        expect(tasks[1].id, task2.id);
        expect(tasks[2].id, task1.id);
      });

      test('期限日時昇順でソートできること', () async {
        // 期限が異なる3つのタスクを作成
        final task1 = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Task 1',
          dueDate: DateTime(2025, 12, 31),
        );
        
        final task2 = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Task 2',
          dueDate: DateTime(2025, 11, 30),
        );
        
        final task3 = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Task 3',
          dueDate: DateTime(2026, 1, 15),
        );

        final stream = repository.watchProjectTasks(
          projectId: testProjectId,
          sortBy: TaskSortBy.dueDate,
        );
        final tasks = await stream.first;

        expect(tasks.length, 3);
        // 期限が早い順
        expect(tasks[0].id, task2.id); // 2025-11-30
        expect(tasks[1].id, task1.id); // 2025-12-31
        expect(tasks[2].id, task3.id); // 2026-01-15
      });

      test('完了済みタスクのみフィルターできること', () async {
        final task1 = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Task 1',
        );
        await repository.toggleTaskCompletion(taskId: task1.id, isCompleted: true);
        
        await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Task 2',
        );

        final stream = repository.watchProjectTasks(
          projectId: testProjectId,
          filterCompleted: true,
        );
        final tasks = await stream.first;

        expect(tasks.length, 1);
        expect(tasks.first.name, 'Task 1');
        expect(tasks.first.isCompleted, true);
      });

      test('未完了タスクのみフィルターできること', () async {
        final task1 = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Task 1',
        );
        await repository.toggleTaskCompletion(taskId: task1.id, isCompleted: true);
        
        await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Task 2',
        );

        final stream = repository.watchProjectTasks(
          projectId: testProjectId,
          filterCompleted: false,
        );
        final tasks = await stream.first;

        expect(tasks.length, 1);
        expect(tasks.first.name, 'Task 2');
        expect(tasks.first.isCompleted, false);
      });

      test('limitパラメータで取得件数を制限できること', () async {
        // 5つのタスクを作成
        for (int i = 0; i < 5; i++) {
          await repository.createTask(
            projectId: testProjectId,
            userId: testUserId,
            name: 'Task $i',
          );
        }

        final stream = repository.watchProjectTasks(
          projectId: testProjectId,
          limit: 3,
        );
        final tasks = await stream.first;

        expect(tasks.length, 3);
      });
    });

    group('watchTask', () {
      test('タスクIDで単一タスクを取得できること', () async {
        final created = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Single Task',
        );

        final stream = repository.watchTask(taskId: created.id);
        final task = await stream.first;

        expect(task, isNotNull);
        expect(task!.id, created.id);
        expect(task.name, 'Single Task');
      });

      test('存在しないタスクIDの場合nullを返すこと', () async {
        final stream = repository.watchTask(taskId: 'non-existent-id');
        final task = await stream.first;

        expect(task, isNull);
      });
    });

    group('updateTask', () {
      test('タスク名を更新できること', () async {
        final created = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Original Name',
        );

        final updated = await repository.updateTask(
          taskId: created.id,
          name: 'Updated Name',
        );

        expect(updated.name, 'Updated Name');
        expect(updated.description, created.description);
        expect(updated.updatedAt.isAfter(created.updatedAt), true);
      });

      test('説明を更新できること', () async {
        final created = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Task Name',
          description: 'Original Description',
        );

        final updated = await repository.updateTask(
          taskId: created.id,
          name: created.name,
          description: 'Updated Description',
        );

        expect(updated.name, created.name);
        expect(updated.description, 'Updated Description');
      });

      test('期限を更新できること', () async {
        final created = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Task Name',
          dueDate: DateTime(2025, 12, 31),
        );

        final newDueDate = DateTime(2026, 1, 15);
        final updated = await repository.updateTask(
          taskId: created.id,
          name: created.name,
          dueDate: newDueDate,
        );

        expect(updated.dueDate, newDueDate);
      });

      test('存在しないタスクの更新時はNotFoundExceptionをスローすること', () async {
        expect(
          () => repository.updateTask(
            taskId: 'non-existent-id',
            name: 'Updated Name',
          ),
          throwsA(isA<NotFoundException>()),
        );
      });
    });

    group('toggleTaskCompletion', () {
      test('タスクを完了状態に変更できること', () async {
        final created = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Task to Complete',
        );

        final completed = await repository.toggleTaskCompletion(
          taskId: created.id,
          isCompleted: true,
        );

        expect(completed.isCompleted, true);
        expect(completed.completedAt, isNotNull);
        expect(completed.updatedAt.isAfter(created.updatedAt), true);
      });

      test('タスクを未完了状態に戻せること', () async {
        final created = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Task to Uncomplete',
        );

        // まず完了状態にする
        final completed = await repository.toggleTaskCompletion(
          taskId: created.id,
          isCompleted: true,
        );
        expect(completed.isCompleted, true);

        // 未完了に戻す
        final uncompleted = await repository.toggleTaskCompletion(
          taskId: created.id,
          isCompleted: false,
        );

        expect(uncompleted.isCompleted, false);
        expect(uncompleted.completedAt, isNull);
      });

      test('存在しないタスクの完了切り替え時はNotFoundExceptionをスローすること', () async {
        expect(
          () => repository.toggleTaskCompletion(
            taskId: 'non-existent-id',
            isCompleted: true,
          ),
          throwsA(isA<NotFoundException>()),
        );
      });
    });

    group('deleteTask', () {
      test('タスクを削除できること', () async {
        final created = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'To Delete',
        );

        await repository.deleteTask(taskId: created.id);

        final exists = await repository.exists(taskId: created.id);
        expect(exists, false);
      });

      test('存在しないタスクの削除時はNotFoundExceptionをスローすること', () async {
        expect(
          () => repository.deleteTask(taskId: 'non-existent-id'),
          throwsA(isA<NotFoundException>()),
        );
      });
    });

    group('getProjectTaskStatistics', () {
      test('タスク統計を正しく計算できること', () async {
        // 4つのタスクを作成: 2完了、1未完了、1期限超過
        final task1 = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Task 1 - Completed',
        );
        await repository.toggleTaskCompletion(taskId: task1.id, isCompleted: true);

        final task2 = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Task 2 - Completed',
        );
        await repository.toggleTaskCompletion(taskId: task2.id, isCompleted: true);

        await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Task 3 - Uncompleted',
        );

        await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Task 4 - Overdue',
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
        );

        final stats = await repository.getProjectTaskStatistics(projectId: testProjectId);

        expect(stats.totalTasks, 4);
        expect(stats.completedTasks, 2);
        expect(stats.overdueTasks, 1);
        expect(stats.completionRate, closeTo(50.0, 0.1));
        expect(stats.isProjectCompleted, false);
      });

      test('全タスク完了時isProjectCompletedがtrueになること', () async {
        final task1 = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Task 1',
        );
        await repository.toggleTaskCompletion(taskId: task1.id, isCompleted: true);

        final task2 = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Task 2',
        );
        await repository.toggleTaskCompletion(taskId: task2.id, isCompleted: true);

        final stats = await repository.getProjectTaskStatistics(projectId: testProjectId);

        expect(stats.totalTasks, 2);
        expect(stats.completedTasks, 2);
        expect(stats.completionRate, 100.0);
        expect(stats.isProjectCompleted, true);
      });

      test('タスクがない場合は0%を返すこと', () async {
        final stats = await repository.getProjectTaskStatistics(projectId: 'empty-project');

        expect(stats.totalTasks, 0);
        expect(stats.completedTasks, 0);
        expect(stats.overdueTasks, 0);
        expect(stats.completionRate, 0.0);
        expect(stats.isProjectCompleted, false);
      });
    });

    group('exists', () {
      test('存在するタスクの場合trueを返すこと', () async {
        final created = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Existing Task',
        );

        final exists = await repository.exists(taskId: created.id);
        expect(exists, true);
      });

      test('存在しないタスクの場合falseを返すこと', () async {
        final exists = await repository.exists(taskId: 'non-existent-id');
        expect(exists, false);
      });
    });

    group('Complex Scenarios', () {
      test('無限スクロールシナリオ: ページネーションが正しく動作すること', () async {
        // 50個のタスクを作成
        for (int i = 0; i < 50; i++) {
          await repository.createTask(
            projectId: testProjectId,
            userId: testUserId,
            name: 'Task $i',
          );
          await Future.delayed(const Duration(milliseconds: 10));
        }

        // 最初の30件を取得
        final stream1 = repository.watchProjectTasks(
          projectId: testProjectId,
          limit: 30,
        );
        final page1 = await stream1.first;

        expect(page1.length, 30);

        // 最後のドキュメントを取得してカーソルとして使用
        final lastDoc = await FirebaseFirestore.instance
            .collection('tasks')
            .doc(page1.last.id)
            .get();

        // 次の20件を取得
        final stream2 = repository.watchProjectTasks(
          projectId: testProjectId,
          limit: 30,
          startAfterDoc: lastDoc,
        );
        final page2 = await stream2.first;

        expect(page2.length, 20);
        
        // ページ1とページ2のタスクIDが重複しないことを確認
        final page1Ids = page1.map((t) => t.id).toSet();
        final page2Ids = page2.map((t) => t.id).toSet();
        expect(page1Ids.intersection(page2Ids).isEmpty, true);
      });

      test('ソート+フィルターの複合シナリオ', () async {
        // 完了済みタスク（期限あり）
        final task1 = await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Completed 1',
          dueDate: DateTime(2025, 12, 31),
        );
        await repository.toggleTaskCompletion(taskId: task1.id, isCompleted: true);

        // 未完了タスク（期限あり）
        await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Uncompleted 1',
          dueDate: DateTime(2025, 11, 30),
        );

        // 未完了タスク（期限あり）
        await repository.createTask(
          projectId: testProjectId,
          userId: testUserId,
          name: 'Uncompleted 2',
          dueDate: DateTime(2026, 1, 15),
        );

        // 未完了タスクのみを期限昇順で取得
        final stream = repository.watchProjectTasks(
          projectId: testProjectId,
          sortBy: TaskSortBy.dueDate,
          filterCompleted: false,
        );
        final tasks = await stream.first;

        expect(tasks.length, 2);
        expect(tasks[0].name, 'Uncompleted 1'); // 2025-11-30
        expect(tasks[1].name, 'Uncompleted 2'); // 2026-01-15
      });

      test('並行操作シナリオ: 複数のタスク作成を並行実行できること', () async {
        final futures = <Future<Task>>[];
        
        for (int i = 0; i < 10; i++) {
          futures.add(repository.createTask(
            projectId: testProjectId,
            userId: testUserId,
            name: 'Concurrent Task $i',
          ));
        }

        final tasks = await Future.wait(futures);
        
        expect(tasks.length, 10);
        expect(tasks.map((t) => t.id).toSet().length, 10); // すべて異なるID
      });
    });
  });
}
