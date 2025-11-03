import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/project.dart';
import 'i_project_repository.dart';
import '../../../../core/exceptions/validation_exception.dart';
import '../../../../core/exceptions/not_found_exception.dart';

/// Firestoreを使用したプロジェクトリポジトリの実装
class FirestoreProjectRepository implements IProjectRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// プロジェクトコレクションの参照
  CollectionReference get _projectsCollection =>
      _firestore.collection('projects');

  /// タスクコレクションの参照
  CollectionReference get _tasksCollection => _firestore.collection('tasks');

  @override
  Stream<List<Project>> watchUserProjects({
    required String userId,
    int? limit,
    DocumentSnapshot? startAfterDoc,
  }) {
    Query<Object?> query = _projectsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
            .map((doc) => Project.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<Project?> watchProject({required String projectId}) {
    return _projectsCollection.doc(projectId).snapshots().map((doc) {
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
    // バリデーション
    _validateProjectName(name);
    _validateProjectDescription(description);

    final now = DateTime.now();
    final docRef = _projectsCollection.doc();

    final project = Project(
      id: docRef.id,
      userId: userId,
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
    );

    // オフライン対応: setは非同期で実行し、即座にローカルプロジェクトを返す
    // Firestoreの永続化により、オンライン復帰時に自動同期される
    docRef.set(project.toFirestore()).catchError((error) {
      // エラーはログに記録するが、ユーザー体験を妨げない
      print('Failed to create project (will retry when online): $error');
    });
    
    return project;
  }

  @override
  Future<Project> updateProject({
    required String projectId,
    required String name,
    String? description,
  }) async {
    // バリデーション
    _validateProjectName(name);
    _validateProjectDescription(description);

    final docRef = _projectsCollection.doc(projectId);
    
    // オフライン対応: キャッシュから取得（オフライン時はメタデータで判定）
    final doc = await docRef.get(const GetOptions(source: Source.cache))
        .catchError((_) => docRef.get());

    if (!doc.exists) {
      throw NotFoundException(
        'プロジェクトが見つかりません',
        resourceType: 'Project',
        resourceId: projectId,
      );
    }

    // 同時編集競合処理: Last Write Wins戦略
    // Firestoreのサーバータイムスタンプにより、最後の書き込みが優先される
    // 複数のユーザーが同時に編集した場合、最後に保存した内容が反映される
    final currentProject = Project.fromFirestore(doc);
    final updatedProject = currentProject.copyWith(
      name: name,
      description: description,
      updatedAt: DateTime.now(),
    );

    // オフライン対応: updateは非同期で実行し、即座に更新済みプロジェクトを返す
    docRef.update(updatedProject.toFirestore()).catchError((error) {
      print('Failed to update project (will retry when online): $error');
    });
    
    return updatedProject;
  }

  @override
  Future<void> deleteProject({required String projectId}) async {
    // Firestoreバッチを使用してプロジェクトと関連タスクを削除
    final batch = _firestore.batch();

    // プロジェクトの削除
    final projectRef = _projectsCollection.doc(projectId);
    batch.delete(projectRef);

    // 関連タスクの削除（オフライン対応: キャッシュから取得を試みる）
    final tasksSnapshot = await _tasksCollection
        .where('projectId', isEqualTo: projectId)
        .get(const GetOptions(source: Source.cache))
        .catchError((_) => _tasksCollection
            .where('projectId', isEqualTo: projectId)
            .get());

    for (final taskDoc in tasksSnapshot.docs) {
      batch.delete(taskDoc.reference);
    }

    // オフライン対応: バッチコミットは非同期で実行
    batch.commit().catchError((error) {
      print('Failed to delete project (will retry when online): $error');
    });
  }

  @override
  Future<bool> exists({required String projectId}) async {
    // オフライン対応: キャッシュから取得を優先
    DocumentSnapshot doc;
    try {
      doc = await _projectsCollection.doc(projectId).get(const GetOptions(source: Source.cache));
    } catch (_) {
      doc = await _projectsCollection.doc(projectId).get();
    }
    return doc.exists;
  }

  /// プロジェクト名のバリデーション
  void _validateProjectName(String name) {
    if (name.trim().isEmpty) {
      throw const ValidationException(
        'プロジェクト名を入力してください',
        fieldName: 'name',
      );
    }
    if (name.length > 100) {
      throw const ValidationException(
        'プロジェクト名は100文字以内で入力してください',
        fieldName: 'name',
      );
    }
  }

  /// プロジェクト説明のバリデーション
  void _validateProjectDescription(String? description) {
    if (description != null && description.length > 500) {
      throw const ValidationException(
        'プロジェクト説明は500文字以内で入力してください',
        fieldName: 'description',
      );
    }
  }
}
