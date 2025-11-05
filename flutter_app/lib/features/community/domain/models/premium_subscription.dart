import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'premium_subscription.freezed.dart';
part 'premium_subscription.g.dart';

/// プレミアムサブスクリプションモデル
/// ユーザーのプレミアムプラン契約情報を表現
@freezed
class PremiumSubscription with _$PremiumSubscription {
  const factory PremiumSubscription({
    required String userId,
    required String planType,
    required String platform,
    required String productId,
    required String originalTransactionId,
    String? latestReceiptData,
    String? purchaseToken,
    required DateTime startDate,
    required DateTime currentPeriodStart,
    required DateTime currentPeriodEnd,
    DateTime? nextRenewalDate,
    required String status,
    DateTime? cancelledAt,
    DateTime? paymentFailedAt,
    DateTime? gracePeriodEnd,
    DateTime? lastDevCoinGrantedAt,
  }) = _PremiumSubscription;

  factory PremiumSubscription.fromJson(Map<String, dynamic> json) =>
      _$PremiumSubscriptionFromJson(json);

  /// FirestoreドキュメントスナップショットからPremiumSubscriptionを生成
  factory PremiumSubscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PremiumSubscription(
      userId: doc.id,
      planType: data['planType'] as String,
      platform: data['platform'] as String,
      productId: data['productId'] as String,
      originalTransactionId: data['originalTransactionId'] as String,
      latestReceiptData: data['latestReceiptData'] as String?,
      purchaseToken: data['purchaseToken'] as String?,
      startDate: (data['startDate'] as Timestamp).toDate(),
      currentPeriodStart: (data['currentPeriodStart'] as Timestamp).toDate(),
      currentPeriodEnd: (data['currentPeriodEnd'] as Timestamp).toDate(),
      nextRenewalDate: data['nextRenewalDate'] != null
          ? (data['nextRenewalDate'] as Timestamp).toDate()
          : null,
      status: data['status'] as String,
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      paymentFailedAt: data['paymentFailedAt'] != null
          ? (data['paymentFailedAt'] as Timestamp).toDate()
          : null,
      gracePeriodEnd: data['gracePeriodEnd'] != null
          ? (data['gracePeriodEnd'] as Timestamp).toDate()
          : null,
      lastDevCoinGrantedAt: data['lastDevCoinGrantedAt'] != null
          ? (data['lastDevCoinGrantedAt'] as Timestamp).toDate()
          : null,
    );
  }
}

/// プレミアムプラン種別
enum PremiumPlanType {
  premium('premium', '月額680円');

  const PremiumPlanType(this.value, this.displayName);
  final String value;
  final String displayName;
}

/// プラットフォーム
enum PurchasePlatform {
  ios('ios', 'iOS'),
  android('android', 'Android');

  const PurchasePlatform(this.value, this.displayName);
  final String value;
  final String displayName;
}

/// サブスクリプションステータス
enum SubscriptionStatus {
  active('active', '有効'),
  cancelled('cancelled', 'キャンセル済み'),
  expired('expired', '期限切れ'),
  paymentFailedGrace('payment_failed_grace', '決済失敗（猶予期間中）');

  const SubscriptionStatus(this.value, this.displayName);
  final String value;
  final String displayName;
}
