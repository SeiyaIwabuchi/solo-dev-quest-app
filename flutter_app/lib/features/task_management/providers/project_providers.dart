import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/models/project.dart';
import 'repository_providers.dart';

/// ユーザーのプロジェクト一覧を監視するStreamProvider
final userProjectsProvider = StreamProvider.autoDispose<List<Project>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  
  if (user == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(projectRepositoryProvider);
  return repository.watchUserProjects(userId: user.uid);
});

/// 特定のプロジェクトを監視するStreamProvider
final projectProvider = StreamProvider.autoDispose.family<Project?, String>((ref, projectId) {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.watchProject(projectId: projectId);
});
