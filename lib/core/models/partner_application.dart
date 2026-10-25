import 'package:dive_travel_app/core/data/dive_star.dart';

/// One application per person. Document id is [applicantUid].
class PartnerApplicationLimits {
  static const login = 80;
  static const shop = 80;
  static const contact = 40;
  static const phone = 40;
  static const region = 40;
  static const intro = 80;
  static const link = 200;
}

class PartnerApplicationInvalid implements Exception {
  const PartnerApplicationInvalid(this.code);

  /// `shop`, `contact`, `phone`, `region`, `intro`, `link`, or `consent`.
  final String code;
}

enum PartnerApplicationStatus {
  incoming,
  handled;

  static PartnerApplicationStatus parse(dynamic raw) {
    if ((raw as String?)?.trim() == 'handled') {
      return PartnerApplicationStatus.handled;
    }
    return PartnerApplicationStatus.incoming;
  }

  String get firestoreValue => switch (this) {
        PartnerApplicationStatus.incoming => 'new',
        PartnerApplicationStatus.handled => 'handled',
      };
}

class PartnerApplication {
  const PartnerApplication({
    required this.applicantUid,
    required this.loginId,
    required this.shopName,
    required this.contactName,
    required this.phone,
    required this.region,
    required this.intro,
    required this.link,
    required this.consent,
    required this.status,
    required this.createdAt,
    this.handledAt,
    this.handledByUid = '',
  });

  factory PartnerApplication.fromMap(String id, Map<String, dynamic> data) {
    return PartnerApplication(
      applicantUid: (data['applicant_uid'] as String? ?? id).trim(),
      loginId: (data['login_id'] as String? ?? '').trim(),
      shopName: (data['shop_name'] as String? ?? '').trim(),
      contactName: (data['contact_name'] as String? ?? '').trim(),
      phone: (data['phone'] as String? ?? '').trim(),
      region: (data['region'] as String? ?? '').trim(),
      intro: (data['intro'] as String? ?? '').trim(),
      link: (data['link'] as String? ?? '').trim(),
      consent: data['consent'] == true,
      status: PartnerApplicationStatus.parse(data['status']),
      createdAt: DiveStar.parseDate(data['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      handledAt: DiveStar.parseDate(data['handled_at']),
      handledByUid: (data['handled_by_uid'] as String? ?? '').trim(),
    );
  }

  final String applicantUid;
  final String loginId;
  final String shopName;
  final String contactName;
  final String phone;
  final String region;
  final String intro;
  final String link;
  final bool consent;
  final PartnerApplicationStatus status;
  final DateTime createdAt;
  final DateTime? handledAt;
  final String handledByUid;
}

void validatePartnerApplication({
  required String shopName,
  required String contactName,
  required String phone,
  required String region,
  required String intro,
  required String link,
  required bool consent,
}) {
  if (shopName.trim().isEmpty ||
      shopName.trim().length > PartnerApplicationLimits.shop) {
    throw const PartnerApplicationInvalid('shop');
  }
  if (contactName.trim().isEmpty ||
      contactName.trim().length > PartnerApplicationLimits.contact) {
    throw const PartnerApplicationInvalid('contact');
  }
  if (phone.trim().isEmpty ||
      phone.trim().length > PartnerApplicationLimits.phone) {
    throw const PartnerApplicationInvalid('phone');
  }
  if (region.trim().isEmpty ||
      region.trim().length > PartnerApplicationLimits.region) {
    throw const PartnerApplicationInvalid('region');
  }
  if (intro.trim().isEmpty ||
      intro.trim().length > PartnerApplicationLimits.intro) {
    throw const PartnerApplicationInvalid('intro');
  }
  if (link.trim().length > PartnerApplicationLimits.link) {
    throw const PartnerApplicationInvalid('link');
  }
  if (!consent) {
    throw const PartnerApplicationInvalid('consent');
  }
}

int countIncomingPartnerApplications(Iterable<PartnerApplication> rows) {
  var count = 0;
  for (final row in rows) {
    if (row.status == PartnerApplicationStatus.incoming) {
      count++;
    }
  }
  return count;
}

List<PartnerApplication> sortPartnerApplicationsNewestFirst(
  List<PartnerApplication> rows,
) {
  final copy = List<PartnerApplication>.from(rows);
  copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return copy;
}

/// A link may be shown as text. It may be opened only when it is https.
/// `javascript:` and every other scheme return null and must not be launched.
Uri? partnerApplicationHttpsUri(String raw) {
  final trimmed = raw.trim();
  if (!trimmed.toLowerCase().startsWith('https://')) {
    return null;
  }
  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    return null;
  }
  return uri;
}
