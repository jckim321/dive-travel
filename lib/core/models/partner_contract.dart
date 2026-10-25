import 'package:dive_travel_app/core/data/dive_star.dart';

/// Bilateral partner contract vault document (H6 framework).
enum PartnerContractKind {
  master,
  annex;

  static PartnerContractKind parse(dynamic raw) {
    if ((raw as String?)?.trim() == 'annex') {
      return PartnerContractKind.annex;
    }
    return PartnerContractKind.master;
  }

  String get firestoreValue => name;
}

enum PartnerContractStatus {
  drafting,
  awaitingSignature,
  executed,
  voided;

  static PartnerContractStatus parse(dynamic raw) {
    switch ((raw as String?)?.trim()) {
      case 'awaiting_signature':
        return PartnerContractStatus.awaitingSignature;
      case 'executed':
        return PartnerContractStatus.executed;
      case 'voided':
        return PartnerContractStatus.voided;
      case 'drafting':
      default:
        return PartnerContractStatus.drafting;
    }
  }

  String get firestoreValue => switch (this) {
        PartnerContractStatus.drafting => 'drafting',
        PartnerContractStatus.awaitingSignature => 'awaiting_signature',
        PartnerContractStatus.executed => 'executed',
        PartnerContractStatus.voided => 'voided',
      };

  bool get isTerminal =>
      this == PartnerContractStatus.executed ||
      this == PartnerContractStatus.voided;
}

enum PartnerContractEventType {
  uploaded,
  sent,
  viewed,
  revisionRequested,
  signed,
  voided,
  executed;

  static PartnerContractEventType parse(dynamic raw) {
    switch ((raw as String?)?.trim()) {
      case 'sent':
        return PartnerContractEventType.sent;
      case 'viewed':
        return PartnerContractEventType.viewed;
      case 'revision_requested':
        return PartnerContractEventType.revisionRequested;
      case 'signed':
        return PartnerContractEventType.signed;
      case 'voided':
        return PartnerContractEventType.voided;
      case 'executed':
        return PartnerContractEventType.executed;
      case 'uploaded':
      default:
        return PartnerContractEventType.uploaded;
    }
  }

  String get firestoreValue => switch (this) {
        PartnerContractEventType.uploaded => 'uploaded',
        PartnerContractEventType.sent => 'sent',
        PartnerContractEventType.viewed => 'viewed',
        PartnerContractEventType.revisionRequested => 'revision_requested',
        PartnerContractEventType.signed => 'signed',
        PartnerContractEventType.voided => 'voided',
        PartnerContractEventType.executed => 'executed',
      };
}

/// Shop-level rollup for admin contract overview (no collectionGroup).
enum PartnerContractShopStatus {
  none,
  awaitingSignature,
  executed,
  expiringSoon;

  String get firestoreHint => name;
}

class PartnerContractSignature {
  const PartnerContractSignature({
    required this.signerUid,
    required this.signerName,
    required this.signaturePngBase64,
    required this.signedAt,
    required this.docSha256,
  });

  factory PartnerContractSignature.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return PartnerContractSignature(
        signerUid: '',
        signerName: '',
        signaturePngBase64: '',
        signedAt: DateTime.fromMillisecondsSinceEpoch(0),
        docSha256: '',
      );
    }
    return PartnerContractSignature(
      signerUid: (data['signer_uid'] as String? ?? '').trim(),
      signerName: (data['signer_name'] as String? ?? '').trim(),
      signaturePngBase64:
          (data['signature_png_base64'] as String? ?? '').trim(),
      signedAt: DiveStar.parseDate(data['signed_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      docSha256: (data['doc_sha256'] as String? ?? '').trim(),
    );
  }

  final String signerUid;
  final String signerName;
  final String signaturePngBase64;
  final DateTime signedAt;
  final String docSha256;

  bool get isComplete =>
      signerUid.isNotEmpty &&
      signerName.isNotEmpty &&
      signaturePngBase64.isNotEmpty &&
      docSha256.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'signer_uid': signerUid,
      'signer_name': signerName,
      'signature_png_base64': signaturePngBase64,
      'doc_sha256': docSha256,
      'signed_at': signedAt.toUtc().toIso8601String(),
    };
  }
}

class PartnerContractSignerStep {
  const PartnerContractSignerStep({
    required this.role,
    required this.order,
    this.required = true,
  });

  factory PartnerContractSignerStep.fromMap(Map<String, dynamic> data) {
    return PartnerContractSignerStep(
      role: (data['role'] as String? ?? 'partner').trim(),
      order: (data['order'] as num?)?.toInt() ?? 1,
      required: data['required'] != false,
    );
  }

  final String role;
  final int order;
  final bool required;

  Map<String, dynamic> toMap() => {
        'role': role,
        'order': order,
        'required': required,
      };

  /// Default H6 plan: ops sends, then partner signs.
  static List<PartnerContractSignerStep> defaultPlan() => const [
        PartnerContractSignerStep(role: 'ops', order: 1),
        PartnerContractSignerStep(role: 'partner', order: 2),
      ];
}

class PartnerContract {
  const PartnerContract({
    required this.id,
    required this.shopId,
    required this.kind,
    required this.title,
    required this.version,
    required this.status,
    required this.fileUrl,
    required this.fileSha256,
    required this.uploadedAt,
    required this.uploadedByUid,
    this.validFrom,
    this.validUntil,
    this.fileContentType = 'application/pdf',
    this.sentAt,
    this.executedAt,
    this.voidedAt,
    this.voidReason = '',
    this.signerPlan = const [],
    this.signature,
    this.revisionNote = '',
    this.revisionRequestedAt,
    this.lastViewedAt,
    this.serverSealHash,
    this.identityReauthAt,
    this.compositePdfUrl,
    this.externalEsignProvider,
    this.externalEsignEnvelopeId,
  });

  factory PartnerContract.fromDocument(
    String id,
    Map<String, dynamic> data,
  ) {
    final planRaw = data['signer_plan'];
    final plan = <PartnerContractSignerStep>[];
    if (planRaw is List) {
      for (final item in planRaw) {
        if (item is Map) {
          plan.add(
            PartnerContractSignerStep.fromMap(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }
    final sigRaw = data['signature'];
    return PartnerContract(
      id: id,
      shopId: (data['shop_id'] as String? ?? '').trim(),
      kind: PartnerContractKind.parse(data['kind']),
      title: (data['title'] as String? ?? '').trim(),
      version: (data['version'] as String? ?? '1').trim(),
      status: PartnerContractStatus.parse(data['status']),
      fileUrl: (data['file_url'] as String? ?? '').trim(),
      fileSha256: (data['file_sha256'] as String? ?? '').trim(),
      fileContentType:
          (data['file_content_type'] as String? ?? 'application/pdf').trim(),
      uploadedAt: DiveStar.parseDate(data['uploaded_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      uploadedByUid: (data['uploaded_by_uid'] as String? ?? '').trim(),
      validFrom: DiveStar.parseDate(data['valid_from']),
      validUntil: DiveStar.parseDate(data['valid_until']),
      sentAt: DiveStar.parseDate(data['sent_at']),
      executedAt: DiveStar.parseDate(data['executed_at']),
      voidedAt: DiveStar.parseDate(data['voided_at']),
      voidReason: (data['void_reason'] as String? ?? '').trim(),
      signerPlan: plan.isEmpty ? PartnerContractSignerStep.defaultPlan() : plan,
      signature: sigRaw is Map
          ? PartnerContractSignature.fromMap(
              Map<String, dynamic>.from(sigRaw),
            )
          : null,
      revisionNote: (data['revision_note'] as String? ?? '').trim(),
      revisionRequestedAt: DiveStar.parseDate(data['revision_requested_at']),
      lastViewedAt: DiveStar.parseDate(data['last_viewed_at']),
      serverSealHash: data['server_seal_hash'] as String?,
      identityReauthAt: DiveStar.parseDate(data['identity_reauth_at']),
      compositePdfUrl: data['composite_pdf_url'] as String?,
      externalEsignProvider: data['external_esign_provider'] as String?,
      externalEsignEnvelopeId: data['external_esign_envelope_id'] as String?,
    );
  }

  final String id;
  final String shopId;
  final PartnerContractKind kind;
  final String title;
  final String version;
  final PartnerContractStatus status;
  final String fileUrl;
  final String fileSha256;
  final String fileContentType;
  final DateTime uploadedAt;
  final String uploadedByUid;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final DateTime? sentAt;
  final DateTime? executedAt;
  final DateTime? voidedAt;
  final String voidReason;
  final List<PartnerContractSignerStep> signerPlan;
  final PartnerContractSignature? signature;
  final String revisionNote;
  final DateTime? revisionRequestedAt;
  final DateTime? lastViewedAt;
  final String? serverSealHash;
  final DateTime? identityReauthAt;
  final String? compositePdfUrl;
  final String? externalEsignProvider;
  final String? externalEsignEnvelopeId;

  bool get canPartnerAct =>
      status == PartnerContractStatus.awaitingSignature;

  bool get isSealed => status.isTerminal;

  /// Days until [validUntil]; null if no end date.
  int? daysUntilExpiry({DateTime? now}) {
    final until = validUntil;
    if (until == null) {
      return null;
    }
    final today = DateTime(now?.year ?? DateTime.now().year,
        now?.month ?? DateTime.now().month, now?.day ?? DateTime.now().day);
    final end = DateTime(until.year, until.month, until.day);
    return end.difference(today).inDays;
  }

  bool get isExpiringSoon {
    final days = daysUntilExpiry();
    return status == PartnerContractStatus.executed &&
        days != null &&
        days >= 0 &&
        days <= 30;
  }

  Map<String, dynamic> toDraftFields({required String adminUid}) {
    return {
      'shop_id': shopId,
      'kind': kind.firestoreValue,
      'title': title,
      'version': version,
      'status': PartnerContractStatus.drafting.firestoreValue,
      'file_url': fileUrl,
      'file_sha256': fileSha256,
      'file_content_type': fileContentType,
      'uploaded_by_uid': adminUid,
      if (validFrom != null) 'valid_from': validFrom!.toUtc().toIso8601String(),
      if (validUntil != null)
        'valid_until': validUntil!.toUtc().toIso8601String(),
      'signer_plan': [
        for (final step in (signerPlan.isEmpty
            ? PartnerContractSignerStep.defaultPlan()
            : signerPlan))
          step.toMap(),
      ],
      'revision_note': '',
      'void_reason': '',
      'server_seal_hash': null,
      'identity_reauth_at': null,
      'composite_pdf_url': null,
      'external_esign_provider': null,
      'external_esign_envelope_id': null,
    };
  }

  static PartnerContractShopStatus rollupStatus(
    List<PartnerContract> docs, {
    DateTime? now,
  }) {
    if (docs.isEmpty) {
      return PartnerContractShopStatus.none;
    }
    final visible = [
      for (final d in docs)
        if (d.status != PartnerContractStatus.voided) d,
    ];
    if (visible.isEmpty) {
      return PartnerContractShopStatus.none;
    }
    if (visible.any((d) => d.status == PartnerContractStatus.awaitingSignature)) {
      return PartnerContractShopStatus.awaitingSignature;
    }
    final executed = [
      for (final d in visible)
        if (d.status == PartnerContractStatus.executed) d,
    ];
    if (executed.isEmpty) {
      return PartnerContractShopStatus.none;
    }
    if (executed.any((d) => d.isExpiringSoon)) {
      return PartnerContractShopStatus.expiringSoon;
    }
    return PartnerContractShopStatus.executed;
  }
}

class PartnerContractEvent {
  const PartnerContractEvent({
    required this.id,
    required this.type,
    required this.uid,
    required this.at,
    required this.docSha256,
    this.meta = const {},
  });

  factory PartnerContractEvent.fromDocument(
    String id,
    Map<String, dynamic> data,
  ) {
    final metaRaw = data['meta'];
    return PartnerContractEvent(
      id: id,
      type: PartnerContractEventType.parse(data['type']),
      uid: (data['uid'] as String? ?? '').trim(),
      at: DiveStar.parseDate(data['at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      docSha256: (data['doc_sha256'] as String? ?? '').trim(),
      meta: metaRaw is Map
          ? Map<String, dynamic>.from(metaRaw)
          : const {},
    );
  }

  final String id;
  final PartnerContractEventType type;
  final String uid;
  final DateTime at;
  final String docSha256;
  final Map<String, dynamic> meta;
}
