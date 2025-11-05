import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../providers/question_provider.dart';

/// ユーザー情報を取得するプロバイダー（キャッシュ付き）
/// authorIdからユーザー情報を動的に取得
final userInfoProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  final repository = ref.watch(questionRepositoryProvider);
  return repository.getUserInfo(userId);
});
