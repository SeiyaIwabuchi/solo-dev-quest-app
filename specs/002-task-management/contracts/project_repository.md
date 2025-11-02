# Project Repository Contract

**Feature**: 002-task-management  
**Interface**: `IProjectRepository`  
**Purpose**: プロジェクトのCRUD操作とクエリのためのリポジトリインターフェース

---

## Interface Definition

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project.dart';

/// プロジェクトリポジトリインターフェース
/// 
/// 実装:
/// - FirestoreProjectRepository: 本番用Firestore接続
/// - FakeProjectRepository: テスト用メモリ内実装
abstract class IProjectRepository {
  /// ユーザーの全プロジェクトをストリームで取得
  /// 
  /// [userId] 取得対象ユーザーID
  /// [limit] 取得件数上限（デフォルト: 制限なし）
  /// [startAfterDoc] ページネーション用カーソル（次ページ取得時に指定）
  /// 
  /// Returns: プロジェクトリストのストリーム（作成日時降順）
  /// 
  /// Throws: 
  /// - [FirebaseException] Firestore接続エラー時
  /// - [UnauthorizedException] 認証エラー時
  Stream<List<Project>> watchUserProjects({
    required String userId,
    int? limit,
    DocumentSnapshot? startAfterDoc,
  });
  
  /// プロジェクトIDで単一プロジェクトをストリームで取得
  /// 
  /// [projectId] 取得対象プロジェクトID
  /// 
  /// Returns: プロジェクトのストリーム（存在しない場合null）
  /// 
  /// Throws: 
  /// - [FirebaseException] Firestore接続エラー時
  /// - [NotFoundException] プロジェクトが見つからない場合
  Stream<Project?> watchProject(String projectId);
  
  /// 新規プロジェクトを作成
  /// 
  /// [userId] プロジェクト所有者のユーザーID
  /// [name] プロジェクト名（1-100文字）
  /// [description] プロジェクト説明（NULL許可、最大500文字）
  /// 
  /// Returns: 作成されたプロジェクト（IDを含む）
  /// 
  /// Throws: 
  /// - [ValidationException] バリデーションエラー（name空文字等）
  /// - [FirebaseException] Firestore書き込みエラー時
  /// 
  /// Business Rules:
  /// - createdAt, updatedAt は自動的にサーバータイムスタンプが設定される
  /// - プロジェクトIDはFirestoreが自動生成
  Future<Project> createProject({
    required String userId,
    required String name,
    String? description,
  });
  
  /// 既存プロジェクトを更新
  /// 
  /// [projectId] 更新対象プロジェクトID
  /// [name] 新しいプロジェクト名（NULL時は変更なし）
  /// [description] 新しい説明（NULL時は変更なし）
  /// 
  /// Returns: 更新後のプロジェクト
  /// 
  /// Throws: 
  /// - [NotFoundException] プロジェクトが存在しない場合
  /// - [ValidationException] バリデーションエラー
  /// - [FirebaseException] Firestore書き込みエラー時
  /// 
  /// Business Rules:
  /// - updatedAt は自動的にサーバータイムスタンプが更新される
  /// - userId, createdAt は変更不可
  Future<Project> updateProject({
    required String projectId,
    String? name,
    String? description,
  });
  
  /// プロジェクトを削除（関連タスクも削除）
  /// 
  /// [projectId] 削除対象プロジェクトID
  /// 
  /// Returns: void
  /// 
  /// Throws: 
  /// - [NotFoundException] プロジェクトが存在しない場合
  /// - [FirebaseException] Firestore書き込みエラー時
  /// 
  /// Business Rules:
  /// - カスケード削除: 関連するすべてのタスクも削除される
  /// - トランザクション内で実行（プロジェクト削除とタスク削除はアトミック）
  Future<void> deleteProject(String projectId);
  
  /// プロジェクトの存在確認
  /// 
  /// [projectId] 確認対象プロジェクトID
  /// 
  /// Returns: 存在する場合true
  Future<bool> exists(String projectId);
}
```

---

## Data Transfer Objects (DTOs)

### CreateProjectRequest

```dart
/// プロジェクト作成リクエスト
@freezed
class CreateProjectRequest with _$CreateProjectRequest {
  const factory CreateProjectRequest({
    required String name,
    String? description,
  }) = _CreateProjectRequest;
  
  factory CreateProjectRequest.fromJson(Map<String, dynamic> json) 
      => _$CreateProjectRequestFromJson(json);
}
```

### UpdateProjectRequest

```dart
/// プロジェクト更新リクエスト
@freezed
class UpdateProjectRequest with _$UpdateProjectRequest {
  const factory UpdateProjectRequest({
    String? name,
    String? description,
  }) = _UpdateProjectRequest;
  
  factory UpdateProjectRequest.fromJson(Map<String, dynamic> json) 
      => _$UpdateProjectRequestFromJson(json);
}
```

---

## Implementation Notes

### Firestore Implementation Example

```dart
class FirestoreProjectRepository implements IProjectRepository {
  final FirebaseFirestore _firestore;
  final String _collectionPath = 'projects';
  
  FirestoreProjectRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  @override
  Stream<List<Project>> watchUserProjects({
    required String userId,
    int? limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);
    
    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Project.fromFirestore(doc))
          .toList();
    });
  }
  
  @override
  Stream<Project?> watchProject(String projectId) {
    return _firestore
        .collection(_collectionPath)
        .doc(projectId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return Project.fromFirestore(doc);
    });
  }
  
  @override
  Future<Project> createProject({
    required String userId,
    required String name,
    String? description,
  }) async {
    // Validation
    if (name.trim().isEmpty || name.length > 100) {
      throw ValidationException('プロジェクト名は1-100文字である必要があります');
    }
    
    if (description != null && description.length > 500) {
      throw ValidationException('説明は500文字以内である必要があります');
    }
    
    final now = DateTime.now();
    final docRef = _firestore.collection(_collectionPath).doc();
    
    final project = Project(
      id: docRef.id,
      userId: userId,
      name: name.trim(),
      description: description?.trim(),
      createdAt: now,
      updatedAt: now,
    );
    
    await docRef.set(project.toFirestore());
    
    return project;
  }
  
  @override
  Future<Project> updateProject({
    required String projectId,
    String? name,
    String? description,
  }) async {
    final docRef = _firestore.collection(_collectionPath).doc(projectId);
    final docSnapshot = await docRef.get();
    
    if (!docSnapshot.exists) {
      throw NotFoundException('プロジェクトが見つかりません: $projectId');
    }
    
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (name != null) {
      if (name.trim().isEmpty || name.length > 100) {
        throw ValidationException('プロジェクト名は1-100文字である必要があります');
      }
      updates['name'] = name.trim();
    }
    
    if (description != null) {
      if (description.length > 500) {
        throw ValidationException('説明は500文字以内である必要があります');
      }
      updates['description'] = description.trim();
    }
    
    await docRef.update(updates);
    
    final updatedDoc = await docRef.get();
    return Project.fromFirestore(updatedDoc);
  }
  
  @override
  Future<void> deleteProject(String projectId) async {
    final batch = _firestore.batch();
    
    // Delete project
    final projectRef = _firestore.collection(_collectionPath).doc(projectId);
    final projectDoc = await projectRef.get();
    
    if (!projectDoc.exists) {
      throw NotFoundException('プロジェクトが見つかりません: $projectId');
    }
    
    batch.delete(projectRef);
    
    // Delete all related tasks (cascade delete)
    final tasksSnapshot = await _firestore
        .collection('tasks')
        .where('projectId', isEqualTo: projectId)
        .get();
    
    for (final taskDoc in tasksSnapshot.docs) {
      batch.delete(taskDoc.reference);
    }
    
    await batch.commit();
  }
  
  @override
  Future<bool> exists(String projectId) async {
    final doc = await _firestore
        .collection(_collectionPath)
        .doc(projectId)
        .get();
    return doc.exists;
  }
}
```

### Fake Implementation Example (for Testing)

```dart
class FakeProjectRepository implements IProjectRepository {
  final Map<String, Project> _projects = {};
  final _controller = StreamController<List<Project>>.broadcast();
  
  @override
  Stream<List<Project>> watchUserProjects({
    required String userId,
    int? limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    final userProjects = _projects.values
        .where((p) => p.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return Stream.value(limit != null 
        ? userProjects.take(limit).toList() 
        : userProjects);
  }
  
  @override
  Stream<Project?> watchProject(String projectId) {
    return Stream.value(_projects[projectId]);
  }
  
  @override
  Future<Project> createProject({
    required String userId,
    required String name,
    String? description,
  }) async {
    final id = 'project_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    
    final project = Project(
      id: id,
      userId: userId,
      name: name.trim(),
      description: description?.trim(),
      createdAt: now,
      updatedAt: now,
    );
    
    _projects[id] = project;
    return project;
  }
  
  @override
  Future<Project> updateProject({
    required String projectId,
    String? name,
    String? description,
  }) async {
    final existing = _projects[projectId];
    if (existing == null) {
      throw NotFoundException('プロジェクトが見つかりません: $projectId');
    }
    
    final updated = existing.copyWith(
      name: name ?? existing.name,
      description: description ?? existing.description,
      updatedAt: DateTime.now(),
    );
    
    _projects[projectId] = updated;
    return updated;
  }
  
  @override
  Future<void> deleteProject(String projectId) async {
    if (!_projects.containsKey(projectId)) {
      throw NotFoundException('プロジェクトが見つかりません: $projectId');
    }
    _projects.remove(projectId);
  }
  
  @override
  Future<bool> exists(String projectId) async {
    return _projects.containsKey(projectId);
  }
  
  void dispose() {
    _controller.close();
  }
}
```

---

## Error Handling

### Custom Exceptions

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

/// 認証エラー
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  
  @override
  String toString() => 'UnauthorizedException: $message';
}
```

---

## Usage Example (Riverpod Integration)

```dart
/// プロジェクトリポジトリのProvider
final projectRepositoryProvider = Provider<IProjectRepository>((ref) {
  // 本番環境
  return FirestoreProjectRepository();
  
  // テスト環境
  // return FakeProjectRepository();
});

/// ユーザーのプロジェクト一覧を監視するProvider
final userProjectsProvider = StreamProvider.family<List<Project>, String>(
  (ref, userId) {
    final repository = ref.watch(projectRepositoryProvider);
    return repository.watchUserProjects(userId: userId);
  },
);

/// 単一プロジェクトを監視するProvider
final projectProvider = StreamProvider.family<Project?, String>(
  (ref, projectId) {
    final repository = ref.watch(projectRepositoryProvider);
    return repository.watchProject(projectId);
  },
);
```

---

## Testing Strategy

### Unit Tests

```dart
void main() {
  group('IProjectRepository', () {
    late IProjectRepository repository;
    
    setUp(() {
      repository = FakeProjectRepository();
    });
    
    test('createProject creates a new project with correct fields', () async {
      final project = await repository.createProject(
        userId: 'user123',
        name: 'Test Project',
        description: 'Test Description',
      );
      
      expect(project.id, isNotEmpty);
      expect(project.userId, 'user123');
      expect(project.name, 'Test Project');
      expect(project.description, 'Test Description');
      expect(project.createdAt, isNotNull);
      expect(project.updatedAt, isNotNull);
    });
    
    test('updateProject updates existing project', () async {
      final created = await repository.createProject(
        userId: 'user123',
        name: 'Original Name',
      );
      
      final updated = await repository.updateProject(
        projectId: created.id,
        name: 'Updated Name',
      );
      
      expect(updated.name, 'Updated Name');
      expect(updated.updatedAt.isAfter(created.updatedAt), true);
    });
    
    test('deleteProject removes project', () async {
      final project = await repository.createProject(
        userId: 'user123',
        name: 'To Delete',
      );
      
      await repository.deleteProject(project.id);
      
      expect(await repository.exists(project.id), false);
    });
  });
}
```

### Integration Tests (with Firestore Emulator)

```dart
void main() {
  setUpAll(() async {
    // Firebase Emulator接続設定
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  });
  
  group('FirestoreProjectRepository Integration', () {
    late IProjectRepository repository;
    
    setUp(() {
      repository = FirestoreProjectRepository();
    });
    
    tearDown(() async {
      // Clean up Firestore data
      final snapshot = await FirebaseFirestore.instance
          .collection('projects')
          .get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    });
    
    test('watchUserProjects returns real-time updates', () async {
      const userId = 'user123';
      
      final stream = repository.watchUserProjects(userId: userId);
      
      // Initial state: empty
      expect(await stream.first, isEmpty);
      
      // Create project
      await repository.createProject(
        userId: userId,
        name: 'Test Project',
      );
      
      // Stream should emit updated list
      final projects = await stream.first;
      expect(projects.length, 1);
      expect(projects.first.name, 'Test Project');
    });
  });
}
```

---

## Summary

プロジェクトリポジトリの契約が完了しました：

| メソッド | 用途 | 戻り値 |
|---------|------|--------|
| `watchUserProjects` | ユーザーのプロジェクト一覧をストリーム取得 | `Stream<List<Project>>` |
| `watchProject` | 単一プロジェクトをストリーム取得 | `Stream<Project?>` |
| `createProject` | 新規プロジェクト作成 | `Future<Project>` |
| `updateProject` | プロジェクト更新 | `Future<Project>` |
| `deleteProject` | プロジェクト削除（カスケード） | `Future<void>` |
| `exists` | プロジェクト存在確認 | `Future<bool>` |

Firestore実装とFake実装の例、エラー処理、テスト戦略が定義されました。
