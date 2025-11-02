import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/error_dialog.dart';
import 'password_reset_screen.dart';
import 'register_screen.dart';

/// ユーザーログイン画面
/// 
/// メールアドレスとパスワードで既存ユーザーがログインを行う。
/// ブルートフォース攻撃対策として、5回失敗で15分間ロックされる。
/// ログイン成功後、ホーム画面に自動遷移する。
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// メールアドレスのバリデーション
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'メールアドレスを入力してください';
    }
    if (!isValidEmail(value)) {
      return getEmailValidationError();
    }
    return null;
  }

  /// パスワードのバリデーション
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'パスワードを入力してください';
    }
    return null;
  }

  /// ログインボタンタップ時の処理
  Future<void> _handleLogin() async {
    // フォームバリデーション
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Show loading overlay
    if (mounted) {
      LoadingOverlay.show(context, message: 'ログイン中...');
    }

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Hide loading overlay
      if (mounted) {
        LoadingOverlay.hide(context);
      }

      // ログイン成功
      // 注: AuthWrapperが自動的にホーム画面に遷移するため、手動遷移は不要
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ログインしました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on RateLimitException catch (e) {
      // Hide loading overlay
      if (mounted) {
        LoadingOverlay.hide(context);
      }
      // レート制限エラー - 特別な処理
      _showRateLimitError(e);
    } on UserNotFoundException {
      // Hide loading overlay
      if (mounted) {
        LoadingOverlay.hide(context);
      }
      if (mounted) {
        await ErrorDialog.showAuthError(
          context: context,
          message: 'このメールアドレスは登録されていません',
        );
      }
    } on InvalidCredentialsException {
      // Hide loading overlay
      if (mounted) {
        LoadingOverlay.hide(context);
      }
      if (mounted) {
        await ErrorDialog.showAuthError(
          context: context,
          message: 'メールアドレスまたはパスワードが正しくありません',
        );
      }
    } on NetworkException {
      // Hide loading overlay
      if (mounted) {
        LoadingOverlay.hide(context);
      }
      if (mounted) {
        await ErrorDialog.showNetworkError(
          context: context,
          onRetry: _handleLogin,
        );
      }
    } on AuthException catch (e) {
      // Hide loading overlay
      if (mounted) {
        LoadingOverlay.hide(context);
      }
      if (mounted) {
        await ErrorDialog.showAuthError(
          context: context,
          message: 'ログインに失敗しました: ${e.message}',
        );
      }
    } catch (e) {
      // Hide loading overlay
      if (mounted) {
        LoadingOverlay.hide(context);
      }
      if (mounted) {
        await ErrorDialog.show(
          context: context,
          title: 'エラー',
          message: '予期しないエラーが発生しました',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// レート制限エラーの表示
  /// 
  /// 15分間のロック情報を含む詳細なエラーダイアログを表示
  void _showRateLimitError(RateLimitException e) {
    if (!mounted) return;

    final lockedUntil = e.lockedUntil ?? DateTime.now().add(const Duration(minutes: 15));
    final now = DateTime.now();
    final remainingMinutes =
        lockedUntil.difference(now).inMinutes.clamp(0, 15);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_clock, color: Colors.red),
            SizedBox(width: 8),
            Text('アカウントロック中'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              e.message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'ロック解除まで: 約$remainingMinutes分',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'セキュリティのため、複数回のログイン失敗後は一時的にログインが制限されます。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 新規登録画面への遷移
  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }

  /// Googleサインインボタンタップ時の処理
  /// 
  /// T060: signInWithGoogle()を呼び出し、認証フローを実行
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    // Show loading overlay
    if (mounted) {
      LoadingOverlay.show(context, message: 'Googleアカウントで認証中...');
    }

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final user = await authRepository.signInWithGoogle();

      // Hide loading overlay
      if (mounted) {
        LoadingOverlay.hide(context);
      }

      // ユーザーがキャンセルした場合
      if (user == null) {
        // キャンセルはエラーではないため、何もしない
        return;
      }

      // ログイン成功
      // 注: AuthWrapperが自動的にホーム画面に遷移するため、手動遷移は不要
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Googleアカウントでログインしました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on NetworkException catch (e) {
      // Hide loading overlay
      if (mounted) {
        LoadingOverlay.hide(context);
      }
      // T061: Googleサービス障害時のフォールバックメッセージ
      if (mounted) {
        await ErrorDialog.show(
          context: context,
          title: 'ネットワークエラー',
          message: e.message,
        );
      }
    } on AuthException catch (e) {
      // Hide loading overlay
      if (mounted) {
        LoadingOverlay.hide(context);
      }
      if (mounted) {
        await ErrorDialog.showAuthError(
          context: context,
          message: 'Googleサインインに失敗しました: ${e.message}',
        );
      }
    } catch (e) {
      // Hide loading overlay
      if (mounted) {
        LoadingOverlay.hide(context);
      }
      if (mounted) {
        await ErrorDialog.show(
          context: context,
          title: 'エラー',
          message: '予期しないエラーが発生しました',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ログイン'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                // アプリアイコンまたはロゴ
                Icon(
                  Icons.login,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 32),
                // タイトル
                Text(
                  'おかえりなさい',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'メールアドレスとパスワードを入力してください',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // メールアドレス入力フィールド
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'メールアドレス',
                    hintText: 'example@example.com',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  validator: _validateEmail,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 16),
                // パスワード入力フィールド
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                    hintText: 'パスワードを入力',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  validator: _validatePassword,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _handleLogin(),
                ),
                const SizedBox(height: 24),
                // ログインボタン
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'ログイン',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                // 区切り線
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'または',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                // T059: Googleでログインボタン
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  icon: Image.network(
                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                    height: 24,
                    width: 24,
                    errorBuilder: (context, error, stackTrace) {
                      // ネットワークエラー時のフォールバックアイコン
                      return const Icon(Icons.g_mobiledata, size: 24);
                    },
                  ),
                  label: const Text(
                    'Googleでログイン',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // T070: パスワードを忘れた場合のリンク
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PasswordResetScreen(),
                            ),
                          );
                        },
                  child: const Text('パスワードを忘れた場合'),
                ),
                const SizedBox(height: 8),
                // 新規登録へのリンク
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'アカウントをお持ちでない方',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _navigateToRegister,
                      child: const Text('新規登録'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
