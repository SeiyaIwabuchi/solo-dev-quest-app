/// バリデーションエラーを表す例外クラス
class ValidationException implements Exception {
  /// エラーメッセージ
  final String message;

  /// 検証に失敗したフィールド名（オプション）
  final String? fieldName;

  const ValidationException(this.message, {this.fieldName});

  @override
  String toString() {
    if (fieldName != null) {
      return 'ValidationException: $fieldName - $message';
    }
    return 'ValidationException: $message';
  }
}
