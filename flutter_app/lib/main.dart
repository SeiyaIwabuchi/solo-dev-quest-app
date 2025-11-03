import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/task_management/presentation/screens/project_list_screen.dart';
import 'core/services/retry_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
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

/// T080-T081: App with authentication state-based routing
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
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
      // T081: Authentication state-based routing
      home: const AuthWrapper(),
    );
  }
}

/// T080-T081: Wrapper widget that handles authentication state routing
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
    // T091: Initialize retry service for automatic sync when connection restored
    ref.read(retryServiceProvider);
  }

  /// T080: Check session on app start
  Future<void> _checkSession() async {
    final authRepository = ref.read(authRepositoryProvider);
    final currentUser = authRepository.getCurrentUser();

    if (currentUser != null) {
      // User is logged in, check session expiry
      final isSessionValid = await authRepository.checkSessionExpiry(currentUser.uid);
      
      if (!isSessionValid && mounted) {
        // Session expired, show message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('セッションの有効期限が切れました。再度ログインしてください。'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isCheckingSession = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking session
    if (_isCheckingSession) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // T081: Listen to auth state changes and route accordingly
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // User is logged in, show project list screen
          return const ProjectListScreen();
        } else {
          // User is not logged in, show login screen
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('エラーが発生しました: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Retry
                  setState(() {
                    _isCheckingSession = true;
                  });
                  _checkSession();
                },
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
