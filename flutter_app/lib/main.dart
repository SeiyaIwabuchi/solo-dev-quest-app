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
  
  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _connectToFirebaseEmulator() async {
  // Android Emulatorの場合は10.0.2.2を使用、それ以外はlocalhostを使用
  final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
  
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
}

/// T034: App with go_router navigation
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
