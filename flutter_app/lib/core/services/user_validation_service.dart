import 'package:flutter/material.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

/// ユーザー存在確認サービス
/// 
/// アプリ起動時・復帰時にFirebaseAuthとFirestoreの整合性をチェックし、
/// Firestoreにユーザーが存在しない場合は自動的にログアウトする
class UserValidationService {
  final AuthRepository _authRepository;
  bool _isValidating = false;

  UserValidationService({
    AuthRepository? authRepository,
  }) : _authRepository = authRepository ?? AuthRepository();

  /// ユーザーの存在を確認し、存在しない場合はログアウト
  /// 
  /// Returns: ユーザーが有効な場合true、ログアウトした場合false
  Future<bool> validateAndLogoutIfNeeded() async {
    // 既にチェック中の場合はスキップ（重複実行防止）
    if (_isValidating) {
      return true;
    }

    _isValidating = true;
    try {
      // Firestoreにユーザーが存在するか確認
      final exists = await _authRepository.validateCurrentUserExists();
      
      if (!exists) {
        // ユーザーが存在しない場合は自動ログアウト
        debugPrint('User not found in Firestore. Logging out...');
        await _authRepository.signOut();
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Failed to validate user: $e');
      // エラー時は念のためログアウト
      try {
        await _authRepository.signOut();
      } catch (signOutError) {
        debugPrint('Failed to sign out after validation error: $signOutError');
      }
      return false;
    } finally {
      _isValidating = false;
    }
  }

  /// アプリのライフサイクル変化を監視してユーザー検証を実行
  /// 
  /// AppLifecycleStateがresumedになった時にチェックを実行
  Future<void> handleLifecycleChange(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await validateAndLogoutIfNeeded();
    }
  }
}
