import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/i_project_repository.dart';
import '../data/repositories/firestore_project_repository.dart';
import '../data/repositories/i_task_repository.dart';
import '../data/repositories/firestore_task_repository.dart';

/// プロジェクトリポジトリのプロバイダー
final projectRepositoryProvider = Provider<IProjectRepository>((ref) {
  return FirestoreProjectRepository();
});

/// タスクリポジトリのプロバイダー
final taskRepositoryProvider = Provider<ITaskRepository>((ref) {
  return FirestoreTaskRepository();
});
