// T034: App Router with go_router
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/task_management/presentation/screens/project_list_screen.dart';
import '../../features/community/presentation/screens/question_list_screen.dart';
import '../../features/community/presentation/screens/question_detail_screen.dart';
import '../../features/community/presentation/screens/question_post_screen.dart';

/// アプリケーションのルーティング設定
/// 
/// ルート構造:
/// - `/` - 認証状態に応じてログイン画面またはプロジェクト一覧画面
/// - `/login` - ログイン画面
/// - `/projects` - プロジェクト一覧画面 (認証必須)
/// - `/community/questions` - 質問一覧画面 (認証必須)
/// - `/community/question/:id` - 質問詳細画面 (認証必須)
/// - `/community/question/post` - 質問投稿画面 (認証必須)
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null;
      final isLoggingIn = state.matchedLocation == '/login';

      // 未認証でログイン画面以外にアクセスしようとした場合
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // 認証済みでログイン画面にアクセスしようとした場合
      if (isLoggedIn && isLoggingIn) {
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

      GoRoute(
        path: '/community/question/:id',
        builder: (context, state) {
          final questionId = state.pathParameters['id']!;
          return QuestionDetailScreen(questionId: questionId);
        },
      ),

      GoRoute(
        path: '/community/question/post',
        builder: (context, state) => const QuestionPostScreen(),
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
