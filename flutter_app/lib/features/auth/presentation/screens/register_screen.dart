import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/error_dialog.dart';

/// ユーザー新規登録画面
/// 
/// メールアドレスとパスワードで新規ユーザー登録を行う。
/// 登録成功後、ホーム画面に自動遷移する。
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
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
    if (!isValidPassword(value)) {
      return getPasswordValidationError();
    }
    return null;
  }

  /// 登録ボタンタップ時の処理
  Future<void> _handleRegister() async {
    // フォームバリデーション
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Show loading overlay
    if (mounted) {
      LoadingOverlay.show(context, message: '登録中...');
    }

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.registerWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Hide loading overlay
      if (mounted) {
        LoadingOverlay.hide(context);
      }

      // 登録成功
      // 注: AuthWrapperが自動的にホーム画面に遷移するため、手動遷移は不要
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('登録が完了しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on WeakPasswordException catch (e) {
      // Hide loading overlay
      if (mounted) {
        LoadingOverlay.hide(context);
      }
      if (mounted) {
        await ErrorDialog.showAuthError(
          context: context,
          message: e.message,
        );
      }
    } on EmailAlreadyInUseException {
      // Hide loading overlay
      if (mounted) {
        LoadingOverlay.hide(context);
      }
      if (mounted) {
        await ErrorDialog.showAuthError(
          context: context,
          message: 'このメールアドレスは既に登録されています',
        );
      }
    } on InvalidEmailException {
      // Hide loading overlay
      if (mounted) {
        LoadingOverlay.hide(context);
      }
      if (mounted) {
        await ErrorDialog.showAuthError(
          context: context,
          message: 'メールアドレスの形式が正しくありません',
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
          onRetry: _handleRegister,
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
          message: '登録に失敗しました: ${e.message}',
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
        title: const Text('新規登録'),
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
                  Icons.person_add,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 32),
                // タイトル
                Text(
                  'アカウントを作成',
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
                    hintText: '8文字以上',
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
                  autofillHints: const [AutofillHints.newPassword],
                  onFieldSubmitted: (_) => _handleRegister(),
                ),
                const SizedBox(height: 24),
                // 登録ボタン
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
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
                          '登録',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                // ログイン画面へのリンク
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'すでにアカウントをお持ちですか？',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      child: const Text('ログイン'),
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
