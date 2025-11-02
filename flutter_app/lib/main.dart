import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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
          // User is logged in, show home screen
          return const MyHomePage(title: 'Solo Dev Quest');
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
