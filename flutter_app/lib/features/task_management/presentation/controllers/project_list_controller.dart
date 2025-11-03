import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/project.dart';
import '../../providers/repository_providers.dart';
import '../../../../core/exceptions/validation_exception.dart';

/// プロジェクトリストの状態管理コントローラー
class ProjectListController extends StateNotifier<AsyncValue<void>> {
  ProjectListController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  /// プロジェクトを作成
  Future<Project> createProject({
    required String name,
    String? description,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ユーザーが認証されていません');
      }

      final repository = _ref.read(projectRepositoryProvider);
      final project = await repository.createProject(
        userId: user.uid,
        name: name,
        description: description,
      );

      state = const AsyncValue.data(null);
      return project;
    } on ValidationException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

/// ProjectListControllerのプロバイダー
final projectListControllerProvider =
    StateNotifierProvider.autoDispose<ProjectListController, AsyncValue<void>>(
  (ref) => ProjectListController(ref),
);
