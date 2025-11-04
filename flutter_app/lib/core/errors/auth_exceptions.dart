/// 認証関連のカスタム例外クラス
library;

/// レート制限例外
/// ログイン試行回数が制限を超えた場合にスローされる
class RateLimitException implements Exception {
  final String message;
  final DateTime? lockedUntil;

  RateLimitException({
    required this.message,
    this.lockedUntil,
  });

  @override
  String toString() => 'RateLimitException: $message';
}

/// ネットワーク例外
/// ネットワーク接続エラー時にスローされる
class NetworkException implements Exception {
  final String message;
  final dynamic originalError;

  NetworkException({
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// 認証例外
/// Firebase Authenticationのエラーをラップする
class AuthException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AuthException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AuthException: $message${code != null ? ' (code: $code)' : ''}';
}

/// ユーザー未登録例外
/// メールアドレスが登録されていない場合にスローされる
class UserNotFoundException implements Exception {
  final String email;

  UserNotFoundException(this.email);

  @override
  String toString() => 'UserNotFoundException: User with email $email not found';
}

/// 無効なクレデンシャル例外
/// メールアドレスまたはパスワードが正しくない場合にスローされる
class InvalidCredentialsException implements Exception {
  final String message;

  InvalidCredentialsException({
    this.message = 'メールアドレスまたはパスワードが正しくありません',
  });

  @override
  String toString() => 'InvalidCredentialsException: $message';
}

/// メールアドレス既に使用されている例外
/// 新規登録時に既存のメールアドレスを使用した場合にスローされる
class EmailAlreadyInUseException implements Exception {
  final String email;

  EmailAlreadyInUseException(this.email);

  @override
  String toString() => 'EmailAlreadyInUseException: Email $email is already in use';
}

/// 弱いパスワード例外
/// パスワードが8文字未満の場合にスローされる
class WeakPasswordException implements Exception {
  final String message;

  WeakPasswordException({
    this.message = 'パスワードは8文字以上で入力してください',
  });

  @override
  String toString() => 'WeakPasswordException: $message';
}

/// 無効なメールアドレス例外
/// メールアドレスの形式が不正な場合にスローされる
class InvalidEmailException implements Exception {
  final String email;

  InvalidEmailException(this.email);

  @override
  String toString() => 'InvalidEmailException: Invalid email format: $email';
}
