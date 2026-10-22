import 'package:dive_travel_app/core/data/dive_star.dart';

/// Pipeline for a shop's Dive Star application journey.
enum DiveStarPipelineStatus {
  guideSent,
  loiReceived,
  docsSubmitted,
  underReview,
  resultNotified;

  static DiveStarPipelineStatus parse(dynamic raw) {
    switch ((raw as String?)?.trim()) {
      case 'loi_received':
        return DiveStarPipelineStatus.loiReceived;
      case 'docs_submitted':
        return DiveStarPipelineStatus.docsSubmitted;
      case 'under_review':
        return DiveStarPipelineStatus.underReview;
      case 'result_notified':
        return DiveStarPipelineStatus.resultNotified;
      case 'guide_sent':
      default:
        return DiveStarPipelineStatus.guideSent;
    }
  }

  String get firestoreValue => switch (this) {
        DiveStarPipelineStatus.guideSent => 'guide_sent',
        DiveStarPipelineStatus.loiReceived => 'loi_received',
        DiveStarPipelineStatus.docsSubmitted => 'docs_submitted',
        DiveStarPipelineStatus.underReview => 'under_review',
        DiveStarPipelineStatus.resultNotified => 'result_notified',
      };

  DiveStarPipelineStatus? get next {
    final i = DiveStarPipelineStatus.values.indexOf(this);
    if (i < 0 || i >= DiveStarPipelineStatus.values.length - 1) {
      return null;
    }
    return DiveStarPipelineStatus.values[i + 1];
  }
}

/// In-app letter of intent submitted by a partner shop.
class DiveStarApplication {
  const DiveStarApplication({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.partnerUid,
    required this.companyName,
    required this.contactName,
    required this.contactEmail,
    required this.contactPhone,
    required this.country,
    required this.notes,
    required this.signaturePngBase64,
    required this.pipelineStatus,
    required this.submittedAt,
    this.reminderDueAt,
    this.updatedAt,
  });

  factory DiveStarApplication.fromDocument(
    String id,
    Map<String, dynamic> data,
  ) {
    return DiveStarApplication(
      id: id,
      shopId: (data['shop_id'] as String? ?? '').trim(),
      shopName: (data['shop_name'] as String? ?? '').trim(),
      partnerUid: (data['partner_uid'] as String? ?? '').trim(),
      companyName: (data['company_name'] as String? ?? '').trim(),
      contactName: (data['contact_name'] as String? ?? '').trim(),
      contactEmail: (data['contact_email'] as String? ?? '').trim(),
      contactPhone: (data['contact_phone'] as String? ?? '').trim(),
      country: (data['country'] as String? ?? '').trim(),
      notes: (data['notes'] as String? ?? '').trim(),
      signaturePngBase64: (data['signature_png_base64'] as String? ?? '').trim(),
      pipelineStatus: DiveStarPipelineStatus.parse(data['pipeline_status']),
      submittedAt:
          DiveStar.parseDate(data['submitted_at']) ?? DateTime.now().toUtc(),
      reminderDueAt: DiveStar.parseDate(data['reminder_due_at']),
      updatedAt: DiveStar.parseDate(data['updated_at']),
    );
  }

  final String id;
  final String shopId;
  final String shopName;
  final String partnerUid;
  final String companyName;
  final String contactName;
  final String contactEmail;
  final String contactPhone;
  final String country;
  final String notes;
  final String signaturePngBase64;
  final DiveStarPipelineStatus pipelineStatus;
  final DateTime submittedAt;
  final DateTime? reminderDueAt;
  final DateTime? updatedAt;

  bool get reminderDue {
    final due = reminderDueAt;
    if (due == null) {
      return false;
    }
    return !due.isAfter(DateTime.now().toUtc());
  }

  Map<String, dynamic> toCreateMap() => {
        'shop_id': shopId,
        'shop_name': shopName,
        'partner_uid': partnerUid,
        'company_name': companyName,
        'contact_name': contactName,
        'contact_email': contactEmail,
        'contact_phone': contactPhone,
        'country': country,
        'notes': notes,
        'signature_png_base64': signaturePngBase64,
        'pipeline_status': DiveStarPipelineStatus.loiReceived.firestoreValue,
      };

  DiveStarApplication copyWith({
    DiveStarPipelineStatus? pipelineStatus,
    DateTime? reminderDueAt,
    bool clearReminder = false,
  }) {
    return DiveStarApplication(
      id: id,
      shopId: shopId,
      shopName: shopName,
      partnerUid: partnerUid,
      companyName: companyName,
      contactName: contactName,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      country: country,
      notes: notes,
      signaturePngBase64: signaturePngBase64,
      pipelineStatus: pipelineStatus ?? this.pipelineStatus,
      submittedAt: submittedAt,
      reminderDueAt:
          clearReminder ? null : (reminderDueAt ?? this.reminderDueAt),
      updatedAt: updatedAt,
    );
  }
}

/// Queued outbound mail for admin/manual or future Cloud Function send.
class PartnerEmailOutboxItem {
  const PartnerEmailOutboxItem({
    required this.id,
    required this.toEmail,
    required this.subject,
    required this.body,
    required this.status,
    required this.createdAt,
    this.applicationId = '',
    this.shopId = '',
  });

  factory PartnerEmailOutboxItem.fromDocument(
    String id,
    Map<String, dynamic> data,
  ) {
    return PartnerEmailOutboxItem(
      id: id,
      toEmail: (data['to_email'] as String? ?? '').trim(),
      subject: (data['subject'] as String? ?? '').trim(),
      body: (data['body'] as String? ?? '').trim(),
      status: (data['status'] as String? ?? 'pending').trim(),
      createdAt: DiveStar.parseDate(data['created_at']) ?? DateTime.now().toUtc(),
      applicationId: (data['application_id'] as String? ?? '').trim(),
      shopId: (data['shop_id'] as String? ?? '').trim(),
    );
  }

  final String id;
  final String toEmail;
  final String subject;
  final String body;
  final String status;
  final DateTime createdAt;
  final String applicationId;
  final String shopId;

  bool get isPending => status == 'pending';
}
