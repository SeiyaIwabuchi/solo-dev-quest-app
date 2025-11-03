/// 認証・認可エラーを表す例外クラス
class UnauthorizedException implements Exception {
  /// エラーメッセージ
  final String message;

  /// エラーコード（オプション）
  final String? code;

  const UnauthorizedException(this.message, {this.code});

  @override
  String toString() {
    if (code != null) {
      return 'UnauthorizedException [$code]: $message';
    }
    return 'UnauthorizedException: $message';
  }
}
