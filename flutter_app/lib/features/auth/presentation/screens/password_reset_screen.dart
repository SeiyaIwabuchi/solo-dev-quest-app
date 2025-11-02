import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/error_dialog.dart';

/// パスワードリセット画面
/// 
/// T065-T069: パスワード忘れユーザーがメールアドレスを入力し、
/// パスワードリセットリンクを受信する。
/// 
/// セキュリティ上、メールアドレスの存在有無は表示せず、
/// 常に「送信しました」メッセージを表示する。
class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
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

  /// T068: 送信ボタンタップ時の処理
  Future<void> _handleSendResetEmail() async {
    // フォームバリデーション
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Show loading overlay
    if (mounted) {
      LoadingOverlay.show(context, message: 'メール送信中...');
    }

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      // Hide loading overlay
      if (mounted) {
        LoadingOverlay.hide(context);
      }

      // 送信成功
      if (mounted) {
        setState(() {
          _emailSent = true;
        });
      }
    } on InvalidEmailException {
      // Hide loading overlay
      if (mounted) {
        LoadingOverlay.hide(context);
      }
      // T069: エラーハンドリング
      if (mounted) {
        await ErrorDialog.showAuthError(
          context: context,
          message: '有効なメールアドレスを入力してください',
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
          onRetry: _handleSendResetEmail,
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
          message: 'メール送信に失敗しました: ${e.message}',
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
        title: const Text('パスワードリセット'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _emailSent ? _buildSuccessMessage() : _buildResetForm(),
        ),
      ),
    );
  }

  /// パスワードリセットフォーム
  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          // アイコン
          Icon(
            Icons.lock_reset,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 32),
          // タイトル
          Text(
            'パスワードをお忘れですか？',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '登録されているメールアドレスを入力してください。\nパスワードリセット用のリンクをお送りします。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // T066: メールアドレス入力フィールド
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'メールアドレス',
              hintText: 'example@example.com',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            enabled: !_isLoading,
            validator: _validateEmail,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => _handleSendResetEmail(),
          ),
          const SizedBox(height: 24),
          // T067: リセットメールを送信ボタン
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSendResetEmail,
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
                    'リセットメールを送信',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          // ログイン画面に戻るリンク
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            child: const Text('ログイン画面に戻る'),
          ),
        ],
      ),
    );
  }

  /// 送信成功メッセージ
  Widget _buildSuccessMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        // 成功アイコン
        Icon(
          Icons.mark_email_read,
          size: 100,
          color: Colors.green,
        ),
        const SizedBox(height: 32),
        // タイトル
        Text(
          'メールを送信しました',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // メッセージ
        Text(
          '${_emailController.text} 宛に\nパスワードリセット用のリンクを送信しました。',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'メールが届かない場合は、迷惑メールフォルダをご確認ください。',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'リンクの有効期限は1時間です。',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        // ログイン画面に戻るボタン
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'ログイン画面に戻る',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
