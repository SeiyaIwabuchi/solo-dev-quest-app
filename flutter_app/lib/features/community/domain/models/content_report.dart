import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'content_report.freezed.dart';
part 'content_report.g.dart';

/// コンテンツ報告モデル
/// 不適切なコンテンツの報告を表現
@freezed
class ContentReport with _$ContentReport {
  const factory ContentReport({
    required String reportId,
    required String reporterId,
    required String targetType,
    required String targetId,
    required String reason,
    String? reasonDetail,
    required DateTime reportedAt,
    required String reviewStatus,
    DateTime? reviewedAt,
    String? reviewerId,
    String? reviewNote,
  }) = _ContentReport;

  factory ContentReport.fromJson(Map<String, dynamic> json) =>
      _$ContentReportFromJson(json);

  /// FirestoreドキュメントスナップショットからContentReportを生成
  factory ContentReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContentReport(
      reportId: doc.id,
      reporterId: data['reporterId'] as String,
      targetType: data['targetType'] as String,
      targetId: data['targetId'] as String,
      reason: data['reason'] as String,
      reasonDetail: data['reasonDetail'] as String?,
      reportedAt: (data['reportedAt'] as Timestamp).toDate(),
      reviewStatus: data['reviewStatus'] as String,
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewerId: data['reviewerId'] as String?,
      reviewNote: data['reviewNote'] as String?,
    );
  }
}

/// 報告理由
enum ReportReason {
  spam('spam', 'スパム'),
  harassment('harassment', '嫌がらせ'),
  inappropriate('inappropriate', '不適切な内容'),
  other('other', 'その他');

  const ReportReason(this.value, this.displayName);
  final String value;
  final String displayName;
}

/// 審査ステータス
enum ReviewStatus {
  pending('pending', '審査待ち'),
  approved('approved', '承認'),
  rejected('rejected', '却下');

  const ReviewStatus(this.value, this.displayName);
  final String value;
  final String displayName;
}
