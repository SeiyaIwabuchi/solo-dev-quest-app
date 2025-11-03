/// リソースが見つからない場合の例外クラス
class NotFoundException implements Exception {
  /// エラーメッセージ
  final String message;

  /// 見つからなかったリソースの種類（例: 'Project', 'Task'）
  final String? resourceType;

  /// 見つからなかったリソースのID
  final String? resourceId;

  const NotFoundException(
    this.message, {
    this.resourceType,
    this.resourceId,
  });

  @override
  String toString() {
    if (resourceType != null && resourceId != null) {
      return 'NotFoundException: $resourceType (ID: $resourceId) - $message';
    }
    if (resourceType != null) {
      return 'NotFoundException: $resourceType - $message';
    }
    return 'NotFoundException: $message';
  }
}
