// T034: App Router with go_router
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/password_reset_screen.dart';
import '../../features/task_management/presentation/screens/project_list_screen.dart';
import '../../features/community/presentation/screens/question_list_screen.dart';
import '../../features/community/presentation/screens/question_detail_screen.dart';
import '../../features/community/presentation/screens/question_post_screen.dart';

/// Firebase認証状態の変化を監視するためのクラス
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<User?> _subscription;

  GoRouterRefreshStream(Stream<User?> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (User? user) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// アプリケーションのルーティング設定
/// 
/// ルート構造:
/// - `/` - 認証状態に応じてログイン画面またはプロジェクト一覧画面
/// - `/login` - ログイン画面
/// - `/register` - 新規登録画面
/// - `/password-reset` - パスワードリセット画面
/// - `/projects` - プロジェクト一覧画面 (認証必須)
/// - `/community/questions` - 質問一覧画面 (認証必須)
/// - `/community/question/:id` - 質問詳細画面 (認証必須)
/// - `/community/question/post` - 質問投稿画面 (認証必須)
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';
      final isResettingPassword = state.matchedLocation == '/password-reset';

      // 未認証で認証関連画面以外にアクセスしようとした場合
      if (!isLoggedIn && !isLoggingIn && !isRegistering && !isResettingPassword) {
        return '/login';
      }

      // 認証済みで認証関連画面にアクセスしようとした場合
      if (isLoggedIn && (isLoggingIn || isRegistering || isResettingPassword)) {
        return '/projects';
      }

      return null; // リダイレクトなし
    },
    routes: [
      // ログイン画面
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // 新規登録画面
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // パスワードリセット画面
      GoRoute(
        path: '/password-reset',
        builder: (context, state) => const PasswordResetScreen(),
      ),

      // プロジェクト一覧画面 (ホーム)
      GoRoute(
        path: '/projects',
        builder: (context, state) => const ProjectListScreen(),
      ),

      // ルート (認証状態で自動リダイレクト)
      GoRoute(
        path: '/',
        redirect: (context, state) {
          final user = FirebaseAuth.instance.currentUser;
          return user != null ? '/projects' : '/login';
        },
      ),

      // コミュニティ機能ルート
      GoRoute(
        path: '/community/questions',
        builder: (context, state) => const QuestionListScreen(),
      ),

      // 注意: より具体的なパス（/post）を先に定義する必要がある
      // そうしないと /community/question/post が /community/question/:id にマッチしてしまう
      GoRoute(
        path: '/community/question/post',
        builder: (context, state) => const QuestionPostScreen(),
      ),

      GoRoute(
        path: '/community/question/:id',
        builder: (context, state) {
          final questionId = state.pathParameters['id']!;
          return QuestionDetailScreen(questionId: questionId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('エラー'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'ページが見つかりません',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.go('/projects');
              },
              child: const Text('ホームに戻る'),
            ),
          ],
        ),
      ),
    ),
  );
});
