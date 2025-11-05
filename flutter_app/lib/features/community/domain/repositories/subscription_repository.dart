import '../models/premium_subscription.dart';

/// サブスクリプションリポジトリインターフェース
/// プレミアムプランの課金・管理機能を抽象化
abstract class SubscriptionRepository {
  /// プレミアムプラン購入を検証
  /// App Store / Google Playのレシートを検証してサブスクリプション有効化
  Future<PremiumSubscription> verifyPremiumPurchase({
    required String platform,
    required String receipt,
    required String productId,
  });

  /// 現在のサブスクリプション状態を取得
  Future<PremiumSubscription?> getCurrentSubscription();

  /// サブスクリプションをキャンセル
  /// プラットフォームのAPI経由でキャンセル処理
  Future<void> cancelSubscription();

  /// プレミアム会員かどうかを判定
  Future<bool> isPremiumActive();

  /// サブスクリプションのリアルタイム更新をリッスン
  Stream<PremiumSubscription?> watchSubscription();
}
