import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:solo_dev_quest/core/exceptions/validation_exception.dart';
import 'package:solo_dev_quest/core/exceptions/not_found_exception.dart';
import 'package:solo_dev_quest/features/task_management/data/models/project.dart';
import 'package:solo_dev_quest/features/task_management/data/repositories/firestore_project_repository.dart';

/// Firebase Emulator統合テスト - Project Repository
///
/// このファイルはunit testとして実行可能な統合テストです。
/// Firebase Emulatorを事前に起動してから実行してください。
/// 
/// **実行前提条件**:
/// 1. Firebase Emulatorが起動していること（firebase emulators:start）
/// 2. Emulatorがlocalhost:8080でFirestoreを提供していること
/// 
/// **実行コマンド**:
/// ```bash
/// fvm flutter test integration_test/project_repository_integration_test.dart
/// ```
void main() {
  late FirestoreProjectRepository repository;
  const testUserId = 'test-user-123';

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
    repository = FirestoreProjectRepository();
  });

  tearDown(() async {
    // テスト後のクリーンアップ（全プロジェクト削除）
    final snapshot = await FirebaseFirestore.instance
        .collection('projects')
        .where('userId', isEqualTo: testUserId)
        .get();
    
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
    
    // タスクも削除
    final tasksSnapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: testUserId)
        .get();
    
    for (final doc in tasksSnapshot.docs) {
      await doc.reference.delete();
    }
  });

  group('Project Repository Integration Tests', () {
    group('createProject', () {
      test('正常にプロジェクトを作成できること', () async {
        final project = await repository.createProject(
          userId: testUserId,
          name: 'Test Project',
          description: 'Test Description',
        );

        expect(project.id, isNotEmpty);
        expect(project.userId, testUserId);
        expect(project.name, 'Test Project');
        expect(project.description, 'Test Description');
        expect(project.createdAt, isNotNull);
        expect(project.updatedAt, isNotNull);
        
        // Firestoreに実際に保存されていることを確認
        final doc = await FirebaseFirestore.instance
            .collection('projects')
            .doc(project.id)
            .get();
        
        expect(doc.exists, true);
        expect(doc.data()!['name'], 'Test Project');
      });

      test('説明なしでプロジェクトを作成できること', () async {
        final project = await repository.createProject(
          userId: testUserId,
          name: 'Project without description',
        );

        expect(project.description, isNull);
        expect(project.name, 'Project without description');
      });

      test('プロジェクト名が空の場合はValidationExceptionをスローすること', () async {
        expect(
          () => repository.createProject(
            userId: testUserId,
            name: '',
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('プロジェクト名が100文字を超える場合はValidationExceptionをスローすること', () async {
        final longName = 'a' * 101;
        
        expect(
          () => repository.createProject(
            userId: testUserId,
            name: longName,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('説明が500文字を超える場合はValidationExceptionをスローすること', () async {
        final longDescription = 'a' * 501;
        
        expect(
          () => repository.createProject(
            userId: testUserId,
            name: 'Valid Name',
            description: longDescription,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('プロジェクト名の前後の空白がトリミングされること', () async {
        final project = await repository.createProject(
          userId: testUserId,
          name: '  Trimmed Name  ',
          description: '  Trimmed Description  ',
        );

        expect(project.name, 'Trimmed Name');
        expect(project.description, 'Trimmed Description');
      });
    });

    group('watchUserProjects', () {
      test('ユーザーのプロジェクト一覧をリアルタイムで取得できること', () async {
        final stream = repository.watchUserProjects(userId: testUserId);

        // 初期状態: 空
        expect(await stream.first, isEmpty);

        // プロジェクトを作成
        await repository.createProject(
          userId: testUserId,
          name: 'Project 1',
        );

        // Streamが更新されることを確認
        final projects = await stream.first;
        expect(projects.length, 1);
        expect(projects.first.name, 'Project 1');
      });

      test('複数プロジェクトが作成日時降順でソートされること', () async {
        // 3つのプロジェクトを作成（時間差を確保）
        final project1 = await repository.createProject(
          userId: testUserId,
          name: 'Project 1',
        );
        await Future.delayed(const Duration(milliseconds: 100));
        
        final project2 = await repository.createProject(
          userId: testUserId,
          name: 'Project 2',
        );
        await Future.delayed(const Duration(milliseconds: 100));
        
        final project3 = await repository.createProject(
          userId: testUserId,
          name: 'Project 3',
        );

        final stream = repository.watchUserProjects(userId: testUserId);
        final projects = await stream.first;

        expect(projects.length, 3);
        // 新しい順（降順）
        expect(projects[0].id, project3.id);
        expect(projects[1].id, project2.id);
        expect(projects[2].id, project1.id);
      });

      test('他のユーザーのプロジェクトは取得されないこと', () async {
        await repository.createProject(
          userId: testUserId,
          name: 'My Project',
        );
        
        await repository.createProject(
          userId: 'other-user-456',
          name: 'Other User Project',
        );

        final stream = repository.watchUserProjects(userId: testUserId);
        final projects = await stream.first;

        expect(projects.length, 1);
        expect(projects.first.name, 'My Project');
      });

      test('limitパラメータで取得件数を制限できること', () async {
        // 5つのプロジェクトを作成
        for (int i = 0; i < 5; i++) {
          await repository.createProject(
            userId: testUserId,
            name: 'Project $i',
          );
        }

        final stream = repository.watchUserProjects(
          userId: testUserId,
          limit: 3,
        );
        final projects = await stream.first;

        expect(projects.length, 3);
      });
    });

    group('watchProject', () {
      test('プロジェクトIDで単一プロジェクトを取得できること', () async {
        final created = await repository.createProject(
          userId: testUserId,
          name: 'Single Project',
        );

        final stream = repository.watchProject(projectId: created.id);
        final project = await stream.first;

        expect(project, isNotNull);
        expect(project!.id, created.id);
        expect(project.name, 'Single Project');
      });

      test('存在しないプロジェクトIDの場合nullを返すこと', () async {
        final stream = repository.watchProject(projectId: 'non-existent-id');
        final project = await stream.first;

        expect(project, isNull);
      });

      test('プロジェクトが更新されたらStreamが更新されること', () async {
        final created = await repository.createProject(
          userId: testUserId,
          name: 'Original Name',
        );

        final stream = repository.watchProject(projectId: created.id);
        
        // 初期状態を確認
        final original = await stream.first;
        expect(original!.name, 'Original Name');

        // プロジェクトを更新
        await repository.updateProject(
          projectId: created.id,
          name: 'Updated Name',
        );

        // Streamが更新を反映することを確認
        final updated = await stream.first;
        expect(updated!.name, 'Updated Name');
      });
    });

    group('updateProject', () {
      test('プロジェクト名を更新できること', () async {
        final created = await repository.createProject(
          userId: testUserId,
          name: 'Original Name',
        );

        final updated = await repository.updateProject(
          projectId: created.id,
          name: 'Updated Name',
        );

        expect(updated.name, 'Updated Name');
        expect(updated.description, created.description);
        expect(updated.updatedAt.isAfter(created.updatedAt), true);
      });

      test('説明を更新できること', () async {
        final created = await repository.createProject(
          userId: testUserId,
          name: 'Project Name',
          description: 'Original Description',
        );

        final updated = await repository.updateProject(
          projectId: created.id,
          description: 'Updated Description',
        );

        expect(updated.name, created.name);
        expect(updated.description, 'Updated Description');
      });

      test('名前と説明を同時に更新できること', () async {
        final created = await repository.createProject(
          userId: testUserId,
          name: 'Original Name',
          description: 'Original Description',
        );

        final updated = await repository.updateProject(
          projectId: created.id,
          name: 'Updated Name',
          description: 'Updated Description',
        );

        expect(updated.name, 'Updated Name');
        expect(updated.description, 'Updated Description');
      });

      test('存在しないプロジェクトの更新時はNotFoundExceptionをスローすること', () async {
        expect(
          () => repository.updateProject(
            projectId: 'non-existent-id',
            name: 'Updated Name',
          ),
          throwsA(isA<NotFoundException>()),
        );
      });

      test('無効な名前での更新時はValidationExceptionをスローすること', () async {
        final created = await repository.createProject(
          userId: testUserId,
          name: 'Valid Name',
        );

        expect(
          () => repository.updateProject(
            projectId: created.id,
            name: '',
          ),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('deleteProject', () {
      test('プロジェクトを削除できること', () async {
        final created = await repository.createProject(
          userId: testUserId,
          name: 'To Delete',
        );

        await repository.deleteProject(created.id);

        final exists = await repository.exists(created.id);
        expect(exists, false);
      });

      test('プロジェクト削除時に関連タスクもカスケード削除されること', () async {
        final project = await repository.createProject(
          userId: testUserId,
          name: 'Project with Tasks',
        );

        // タスクを作成
        final taskRef = FirebaseFirestore.instance.collection('tasks').doc();
        await taskRef.set({
          'projectId': project.id,
          'userId': testUserId,
          'name': 'Test Task',
          'isCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // プロジェクトを削除
        await repository.deleteProject(project.id);

        // タスクも削除されていることを確認
        final taskDoc = await taskRef.get();
        expect(taskDoc.exists, false);
      });

      test('存在しないプロジェクトの削除時はNotFoundExceptionをスローすること', () async {
        expect(
          () => repository.deleteProject('non-existent-id'),
          throwsA(isA<NotFoundException>()),
        );
      });
    });

    group('exists', () {
      test('存在するプロジェクトの場合trueを返すこと', () async {
        final created = await repository.createProject(
          userId: testUserId,
          name: 'Existing Project',
        );

        final exists = await repository.exists(created.id);
        expect(exists, true);
      });

      test('存在しないプロジェクトの場合falseを返すこと', () async {
        final exists = await repository.exists('non-existent-id');
        expect(exists, false);
      });
    });

    group('Concurrent Operations', () {
      test('複数のプロジェクト作成を並行実行できること', () async {
        final futures = <Future<Project>>[];
        
        for (int i = 0; i < 5; i++) {
          futures.add(repository.createProject(
            userId: testUserId,
            name: 'Concurrent Project $i',
          ));
        }

        final projects = await Future.wait(futures);
        
        expect(projects.length, 5);
        expect(projects.map((p) => p.id).toSet().length, 5); // すべて異なるID
      });

      test('Last Write Wins戦略で衝突が解決されること', () async {
        final created = await repository.createProject(
          userId: testUserId,
          name: 'Original',
        );

        // 2つの更新を並行実行
        final update1 = repository.updateProject(
          projectId: created.id,
          name: 'Update 1',
        );
        
        final update2 = repository.updateProject(
          projectId: created.id,
          name: 'Update 2',
        );

        await Future.wait([update1, update2]);

        // 最後の書き込みが勝つ（どちらかの名前になっている）
        final stream = repository.watchProject(created.id);
        final final_ = await stream.first;
        
        expect(final_!.name, anyOf('Update 1', 'Update 2'));
      });
    });
  });
}
