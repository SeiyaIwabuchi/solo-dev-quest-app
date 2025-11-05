import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/services/retry_service.dart';
import 'core/services/user_validation_service.dart';
import 'features/community/data/local/question_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // T093: Firebase Crashlytics の初期化
  if (!kDebugMode) {
    // プロダクションビルドのみでCrashlyticsを有効化
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    
    // Async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  
  // T085: Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  // Firebase Emulator接続 (開発環境のみ)
  if (kDebugMode) {
    await _connectToFirebaseEmulator();
  }
  
  // T038: 古いキャッシュを削除（24時間以上前のデータ）
  _cleanupOldCache();
  
  runApp(const ProviderScope(child: MyApp()));
}

/// T038: 古いキャッシュを削除（バックグラウンドで実行）
void _cleanupOldCache() {
  Future.microtask(() async {
    try {
      final cache = QuestionCache();
      final deletedCount = await cache.deleteOldCache();
      if (kDebugMode) {
        print('Deleted $deletedCount old cached questions');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to cleanup old cache: $e');
      }
    }
  });
}

Future<void> _connectToFirebaseEmulator() async {
  // Android Emulatorの場合は10.0.2.2を使用、それ以外はlocalhostを使用
  final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
  
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  
  // Cloud Functions はリージョンを指定してエミュレーターに接続
  FirebaseFunctions.instanceFor(region: 'asia-northeast1')
      .useFunctionsEmulator(host, 5001);
}

/// T034: App with go_router navigation and user validation
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  late final UserValidationService _userValidationService;

  @override
  void initState() {
    super.initState();
    _userValidationService = UserValidationService();
    
    // ライフサイクル監視を開始
    WidgetsBinding.instance.addObserver(this);
    
    // アプリ起動時にユーザー検証を実行
    _validateUserOnStartup();
  }

  @override
  void dispose() {
    // ライフサイクル監視を停止
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // アプリ復帰時にユーザー検証を実行
    _userValidationService.handleLifecycleChange(state);
  }

  /// アプリ起動時にユーザー検証を実行
  Future<void> _validateUserOnStartup() async {
    // 起動直後は少し待ってから実行（Firebase初期化完了を待つ）
    await Future.delayed(const Duration(milliseconds: 500));
    await _userValidationService.validateAndLogoutIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    // T091: Initialize retry service for automatic sync when connection restored
    ref.read(retryServiceProvider);

    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Solo Dev Quest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Localization settings for DatePicker and other widgets
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
        Locale('en', 'US'),
      ],
      routerConfig: router,
    );
  }
}
