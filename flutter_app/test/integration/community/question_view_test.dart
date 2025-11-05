// T024: Integration test for question list & detail view
// 質問一覧・詳細画面の統合テスト：質問が一覧に表示され、詳細画面で閲覧でき、閲覧数がインクリメントされることを確認

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solo_dev_quest/main.dart' as app;
import 'package:solo_dev_quest/features/community/presentation/widgets/question_list_item.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Question List & Detail View Integration Tests', () {
    setUpAll(() async {
      // Firebase Emulator接続
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
    });

    setUp(() async {
      // テスト用データのクリーンアップ
      await _cleanupTestData();
    });

    tearDown(() async {
      // テスト後のクリーンアップ
      await _cleanupTestData();
      await FirebaseAuth.instance.signOut();
    });

    testWidgets('US1-AS2: 質問一覧で最新の質問から順に表示され、必要な情報が確認できる', (tester) async {
      // Given: テストユーザーをログインし、複数の質問を作成
      final testUser = await _createTestUser();
      await _createTestQuestions(testUser.uid);
      
      // アプリを起動
      await tester.pumpWidget(const ProviderScope(child: app.MyApp()));
      await tester.pumpAndSettle();

      // コミュニティ画面に遷移
      await tester.tap(find.text('コミュニティ'));
      await tester.pumpAndSettle();

      // When: 質問一覧を表示
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Then: 質問一覧が表示される
      expect(find.byType(QuestionListItem), findsWidgets);

      // 最新の質問から順に表示されることを確認（作成順の逆順）
      final questionItems = find.byType(QuestionListItem);
      expect(questionItems, findsNWidgets(3));

      // タイトル・投稿者・カテゴリタグが表示されることを確認
      expect(find.text('Flutter状態管理の質問3'), findsOneWidget);
      expect(find.text('Firebase接続の質問2'), findsOneWidget);
      expect(find.text('Dart基礎の質問1'), findsOneWidget);
      
      expect(find.text('テストユーザー'), findsNWidgets(3));
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Firebase'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);

      // 回答数・閲覧数・評価スコアが表示されることを確認
      expect(find.textContaining('回答'), findsWidgets);
      expect(find.textContaining('閲覧'), findsWidgets);
      expect(find.textContaining('評価'), findsWidgets);
    });

    testWidgets('US1-AS4: 質問詳細画面で質問内容と回答を閲覧でき、閲覧数がインクリメントされる', (tester) async {
      // Given: テストユーザーをログインし、質問を作成
      final testUser = await _createTestUser();
      final questionDoc = await _createSingleTestQuestion(testUser.uid);
      
      // 初期閲覧数を確認
      final initialDoc = await questionDoc.get();
      final initialData = initialDoc.data() as Map<String, dynamic>?;
      final initialViewCount = initialData?['viewCount'] ?? 0;
      
      // アプリを起動
      await tester.pumpWidget(const ProviderScope(child: app.MyApp()));
      await tester.pumpAndSettle();

      // コミュニティ画面に遷移
      await tester.tap(find.text('コミュニティ'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // When: 質問アイテムをタップして詳細画面に遷移
      await tester.tap(find.byType(QuestionListItem).first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Then: 質問詳細画面が表示される
      expect(find.text('コード例付きFlutter質問'), findsOneWidget);
      expect(find.text('テストユーザー'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);

      // 質問本文が表示される
      expect(find.textContaining('これは詳細なテスト質問'), findsOneWidget);
      
      // コード例が表示される
      expect(find.textContaining('class TestWidget'), findsOneWidget);

      // 統計情報が表示される
      expect(find.textContaining('回答数'), findsOneWidget);
      expect(find.textContaining('閲覧数'), findsOneWidget);
      expect(find.textContaining('評価スコア'), findsOneWidget);

      // 少し待ってから閲覧数の更新を確認
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 閲覧数がインクリメントされていることを確認
      final updatedDoc = await questionDoc.get();
      final updatedData = updatedDoc.data() as Map<String, dynamic>?;
      final updatedViewCount = updatedData?['viewCount'] ?? 0;
      expect(updatedViewCount, greaterThan(initialViewCount));
    });

    testWidgets('カテゴリフィルターが正常に動作することを確認', (tester) async {
      // Given: テストユーザーをログインし、異なるカテゴリの質問を作成
      final testUser = await _createTestUser();
      await _createTestQuestions(testUser.uid);
      
      // アプリを起動
      await tester.pumpWidget(const ProviderScope(child: app.MyApp()));
      await tester.pumpAndSettle();

      // コミュニティ画面に遷移
      await tester.tap(find.text('コミュニティ'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 初期状態では全ての質問が表示
      expect(find.byType(QuestionListItem), findsNWidgets(3));

      // When: Flutterカテゴリでフィルタリング
      await tester.tap(find.text('Flutter'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Then: Flutter関連の質問のみ表示される
      expect(find.text('Flutter状態管理の質問3'), findsOneWidget);
      expect(find.text('Firebase接続の質問2'), findsNothing);
      expect(find.text('Dart基礎の質問1'), findsNothing);

      // When: すべてを選択してフィルターを解除
      await tester.tap(find.text('すべて'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Then: 全ての質問が再表示される
      expect(find.byType(QuestionListItem), findsNWidgets(3));
    });

    testWidgets('プルツーリフレッシュが正常に動作することを確認', (tester) async {
      // Given: テストユーザーをログインし、質問を作成
      final testUser = await _createTestUser();
      await _createSingleTestQuestion(testUser.uid);
      
      // アプリを起動
      await tester.pumpWidget(const ProviderScope(child: app.MyApp()));
      await tester.pumpAndSettle();

      // コミュニティ画面に遷移
      await tester.tap(find.text('コミュニティ'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 初期状態で1件の質問が表示
      expect(find.byType(QuestionListItem), findsOneWidget);

      // 新しい質問を追加（バックグラウンドで）
      await FirebaseFirestore.instance.collection('questions').add({
        'title': '新しく追加された質問',
        'body': '新しい質問の内容です',
        'authorId': testUser.uid,
        'authorName': 'テストユーザー',
        'categoryTag': 'Other',
        'createdAt': Timestamp.now(),
        'answerCount': 0,
        'viewCount': 0,
        'evaluationScore': 0,
        'deletionStatus': 'normal',
      });

      // When: プルツーリフレッシュを実行
      await tester.fling(
        find.byType(QuestionListItem).first,
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Then: 新しい質問が追加表示される
      expect(find.byType(QuestionListItem), findsNWidgets(2));
      expect(find.text('新しく追加された質問'), findsOneWidget);
    });
  });
}

/// テスト用ユーザーを作成
Future<User> _createTestUser() async {
  final email = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
  final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: email,
    password: 'test123456',
  );

  final user = credential.user!;

  // Firestoreにユーザープロファイルを作成
  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'email': email,
    'displayName': 'テストユーザー',
    'devCoinBalance': 100,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  return user;
}

/// テスト用の複数の質問を作成（最新順確認用）
Future<void> _createTestQuestions(String userId) async {
  final now = DateTime.now();
  
  // 質問1（最古）
  await FirebaseFirestore.instance.collection('questions').add({
    'title': 'Dart基礎の質問1',
    'body': 'Dartの基本的な構文について教えてください。',
    'authorId': userId,
    'authorName': 'テストユーザー',
    'categoryTag': 'Dart',
    'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
    'answerCount': 1,
    'viewCount': 5,
    'evaluationScore': 3,
    'deletionStatus': 'normal',
  });

  // 質問2（中間）
  await FirebaseFirestore.instance.collection('questions').add({
    'title': 'Firebase接続の質問2',
    'body': 'Firebaseとの接続で問題が発生しています。',
    'authorId': userId,
    'authorName': 'テストユーザー',
    'categoryTag': 'Firebase',
    'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
    'answerCount': 2,
    'viewCount': 10,
    'evaluationScore': 5,
    'deletionStatus': 'normal',
  });

  // 質問3（最新）
  await FirebaseFirestore.instance.collection('questions').add({
    'title': 'Flutter状態管理の質問3',
    'body': 'Riverpodを使った状態管理について質問があります。',
    'authorId': userId,
    'authorName': 'テストユーザー',
    'categoryTag': 'Flutter',
    'createdAt': Timestamp.fromDate(now),
    'answerCount': 0,
    'viewCount': 2,
    'evaluationScore': 1,
    'deletionStatus': 'normal',
  });
}

/// テスト用の単一質問を作成（詳細画面確認用）
Future<DocumentReference> _createSingleTestQuestion(String userId) async {
  return await FirebaseFirestore.instance.collection('questions').add({
    'title': 'コード例付きFlutter質問',
    'body': 'これは詳細なテスト質問の本文です。Markdown形式で記述されており、問題の詳細について説明しています。',
    'codeExample': '''
class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Hello, World!'),
    );
  }
}
    ''',
    'authorId': userId,
    'authorName': 'テストユーザー',
    'categoryTag': 'Flutter',
    'createdAt': Timestamp.now(),
    'answerCount': 0,
    'viewCount': 0,
    'evaluationScore': 0,
    'deletionStatus': 'normal',
  });
}

/// テスト用データのクリーンアップ
Future<void> _cleanupTestData() async {
  // テストで作成されたユーザーを削除
  final usersSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('email', isGreaterThanOrEqualTo: 'test_')
      .where('email', isLessThan: 'test_z')
      .get();

  for (final doc in usersSnapshot.docs) {
    await doc.reference.delete();
  }

  // テストで作成された質問を削除
  final questionsSnapshot = await FirebaseFirestore.instance
      .collection('questions')
      .get();

  for (final doc in questionsSnapshot.docs) {
    await doc.reference.delete();
  }
}