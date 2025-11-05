// T023: Integration test for question post flow
// 質問投稿フローの統合テスト：ユーザーがDevCoinを持って質問を投稿し、Firestoreに保存され、残高が減算されることを確認

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solo_dev_quest/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Question Post Flow Integration Tests', () {
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

    testWidgets('US1-AS1: DevCoinを持つユーザーが質問を投稿し、10 DevCoinが消費され質問が公開される', (tester) async {
      // Given: テストユーザーをログインし、100 DevCoinを付与
      final testUser = await _createTestUserWithDevCoin(100);
      
      // アプリを起動
      await tester.pumpWidget(const ProviderScope(child: app.MyApp()));
      await tester.pumpAndSettle();

      // 質問投稿画面に遷移
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 質問投稿フォームに入力
      await tester.enterText(
        find.byType(TextFormField).first,
        'Flutterでアニメーションが動作しない問題について',
      );

      // カテゴリ選択 (Flutter)
      await tester.tap(find.text('Flutter'));
      await tester.pumpAndSettle();

      // 本文入力
      final bodyField = find.byType(TextFormField).at(1);
      await tester.enterText(
        bodyField,
        'AnimationControllerを使ってアニメーションを作成していますが、forward()メソッドを呼んでも動作しません。コード例も含めて質問させていただきます。',
      );

      // コード例入力（ExpansionTileを展開）
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();
      
      final codeField = find.byType(TextFormField).at(2);
      await tester.enterText(
        codeField,
        '''
class MyAnimation extends StatefulWidget {
  @override
  _MyAnimationState createState() => _MyAnimationState();
}

class _MyAnimationState extends State<MyAnimation> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _controller.forward(); // これが動作しない
  }
}
        ''',
      );

      // When: 投稿ボタンをタップ
      await tester.tap(find.text('投稿する'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Then: 成功メッセージが表示される
      expect(find.text('質問を投稿しました！'), findsOneWidget);

      // Firestoreに質問が保存されていることを確認
      final questionsSnapshot = await FirebaseFirestore.instance
          .collection('questions')
          .where('authorId', isEqualTo: testUser.uid)
          .limit(1)
          .get();

      expect(questionsSnapshot.docs.length, 1);
      
      final questionData = questionsSnapshot.docs.first.data();
      expect(questionData['title'], 'Flutterでアニメーションが動作しない問題について');
      expect(questionData['categoryTag'], 'Flutter');
      expect(questionData['answerCount'], 0);
      expect(questionData['viewCount'], 0);
      expect(questionData['deletionStatus'], 'normal');

      // DevCoin残高が90に減算されていることを確認（100 - 10 = 90）
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(testUser.uid)
          .get();
      
      expect(userDoc.data()?['devCoinBalance'], 90);

      // DevCoinトランザクション履歴が記録されていることを確認
      final transactionSnapshot = await FirebaseFirestore.instance
          .collection('devcoin_transactions')
          .where('userId', isEqualTo: testUser.uid)
          .where('type', isEqualTo: 'question_post')
          .limit(1)
          .get();

      expect(transactionSnapshot.docs.length, 1);
      final transactionData = transactionSnapshot.docs.first.data();
      expect(transactionData['amount'], -10);
      expect(transactionData['questionId'], questionsSnapshot.docs.first.id);
    });

    testWidgets('US1-AS3: DevCoin不足ユーザーが質問投稿を試みると、不足ダイアログが表示される', (tester) async {
      // Given: テストユーザーをログインし、5 DevCoinのみ付与（10 DevCoin不足）
      await _createTestUserWithDevCoin(5);
      
      // アプリを起動
      await tester.pumpWidget(const ProviderScope(child: app.MyApp()));
      await tester.pumpAndSettle();

      // 質問投稿画面に遷移
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 質問投稿フォームに入力
      await tester.enterText(
        find.byType(TextFormField).first,
        'テスト質問',
      );

      await tester.tap(find.text('Flutter'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(1),
        'これはテスト用の質問本文です。',
      );

      // When: 投稿ボタンをタップ
      await tester.tap(find.text('投稿する'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Then: DevCoin不足ダイアログが表示される
      expect(find.text('DevCoin不足'), findsOneWidget);
      expect(find.text('質問の投稿には10 DevCoinが必要です。'), findsOneWidget);
      expect(find.text('他の開発者の質問に回答する (5 DevCoin)'), findsOneWidget);
      expect(find.text('プレミアムプランに加入する (毎月200 DevCoin)'), findsOneWidget);
      expect(find.text('プレミアムプランを見る'), findsOneWidget);

      // ダイアログを閉じる
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();

      // 質問が投稿されていないことを確認
      final questionsSnapshot = await FirebaseFirestore.instance
          .collection('questions')
          .where('title', isEqualTo: 'テスト質問')
          .get();

      expect(questionsSnapshot.docs.length, 0);
    });

    testWidgets('T037: 重複投稿制限エラーハンドリングの確認', (tester) async {
      // Given: テストユーザーをログインし、100 DevCoinを付与
      final testUser = await _createTestUserWithDevCoin(100);
      
      // 最初の質問を直接Firestoreに投稿（5分以内の重複をシミュレート）
      await FirebaseFirestore.instance
          .collection('questions')
          .add({
        'title': '重複テスト質問',
        'body': '最初の質問',
        'authorId': testUser.uid,
        'authorName': 'テストユーザー',
        'categoryTag': 'Flutter',
        'createdAt': FieldValue.serverTimestamp(),
        'answerCount': 0,
        'viewCount': 0,
        'evaluationScore': 0,
        'deletionStatus': 'normal',
      });

      // アプリを起動
      await tester.pumpWidget(const ProviderScope(child: app.MyApp()));
      await tester.pumpAndSettle();

      // 質問投稿画面に遷移
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 同じタイトルで質問投稿を試みる
      await tester.enterText(
        find.byType(TextFormField).first,
        '重複テスト質問', // 同じタイトル
      );

      await tester.tap(find.text('Flutter'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(1),
        '重複した質問の本文です。',
      );

      // When: 投稿ボタンをタップ
      await tester.tap(find.text('投稿する'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Then: 重複投稿エラーメッセージが表示される
      expect(find.text('同じタイトルの質問は5分以内に投稿できません'), findsOneWidget);

      // SnackBarのOKボタンをタップ
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 重複した質問が投稿されていないことを確認
      final questionsSnapshot = await FirebaseFirestore.instance
          .collection('questions')
          .where('title', isEqualTo: '重複テスト質問')
          .get();

      expect(questionsSnapshot.docs.length, 1); // 最初の1件のみ
    });
  });
}

/// テスト用ユーザーを作成してDevCoinを付与
Future<User> _createTestUserWithDevCoin(int devCoinBalance) async {
  // テスト用のメールアドレスでユーザー作成
  final email = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
  final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: email,
    password: 'test123456',
  );

  final user = credential.user!;

  // Firestoreにユーザープロファイルを作成してDevCoinを付与
  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'email': email,
    'displayName': 'テストユーザー',
    'devCoinBalance': devCoinBalance,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  return user;
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

  // テストで作成されたDevCoinトランザクションを削除
  final transactionsSnapshot = await FirebaseFirestore.instance
      .collection('devcoin_transactions')
      .get();

  for (final doc in transactionsSnapshot.docs) {
    await doc.reference.delete();
  }
}