import 'package:dive_travel_app/core/data/dive_star.dart';

/// Promotion kinds a partner may propose. Edit this list and the matching
/// `kind in [...]` allow-list in firebase/firestore.rules together.
const List<PartnerPromotionKind> partnerPromotionKinds = [
  PartnerPromotionKind(id: 'early_bird', labelKo: '얼리버드', labelEn: 'Early bird'),
  PartnerPromotionKind(id: 'price_off', labelKo: '가격 할인', labelEn: 'Price off'),
  PartnerPromotionKind(id: 'same_boat', labelKo: '같은배', labelEn: 'Same boat'),
  PartnerPromotionKind(id: 'other', labelKo: '기타', labelEn: 'Other'),
];

class PartnerPromotionKind {
  const PartnerPromotionKind({
    required this.id,
    required this.labelKo,
    required this.labelEn,
  });

  final String id;
  final String labelKo;
  final String labelEn;

  String labelFor(String languageCode) =>
      languageCode == 'ko' ? labelKo : labelEn;
}

PartnerPromotionKind? partnerPromotionKindById(String id) {
  for (final kind in partnerPromotionKinds) {
    if (kind.id == id) {
      return kind;
    }
  }
  return null;
}

class PartnerPromotionInvalid implements Exception {
  const PartnerPromotionInvalid(this.code);

  /// `kind`, `note`, or `period`.
  final String code;
}

enum PartnerPromotionStatus {
  incoming,
  handled;

  static PartnerPromotionStatus parse(dynamic raw) {
    if ((raw as String?)?.trim() == 'handled') {
      return PartnerPromotionStatus.handled;
    }
    return PartnerPromotionStatus.incoming;
  }

  String get firestoreValue => switch (this) {
        PartnerPromotionStatus.incoming => 'new',
        PartnerPromotionStatus.handled => 'handled',
      };
}

class PartnerPromotion {
  const PartnerPromotion({
    required this.id,
    required this.shopId,
    required this.kind,
    required this.startsOn,
    required this.endsOn,
    required this.note,
    required this.status,
    required this.createdAt,
    required this.createdByUid,
    this.handledAt,
    this.handledByUid = '',
  });

  factory PartnerPromotion.fromMap(String id, Map<String, dynamic> data) {
    return PartnerPromotion(
      id: id,
      shopId: (data['shop_id'] as String? ?? '').trim(),
      kind: (data['kind'] as String? ?? '').trim(),
      startsOn: DiveStar.parseDate(data['starts_on']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      endsOn: DiveStar.parseDate(data['ends_on']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      note: (data['note'] as String? ?? '').trim(),
      status: PartnerPromotionStatus.parse(data['status']),
      createdAt: DiveStar.parseDate(data['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      createdByUid: (data['created_by_uid'] as String? ?? '').trim(),
      handledAt: DiveStar.parseDate(data['handled_at']),
      handledByUid: (data['handled_by_uid'] as String? ?? '').trim(),
    );
  }

  final String id;
  final String shopId;
  final String kind;
  final DateTime startsOn;
  final DateTime endsOn;
  final String note;
  final PartnerPromotionStatus status;
  final DateTime createdAt;
  final String createdByUid;
  final DateTime? handledAt;
  final String handledByUid;
}

/// Newest first. Each shop may contribute at most [perShop] rows.
List<PartnerPromotion> mergePartnerPromotions(
  Iterable<List<PartnerPromotion>> batches, {
  int perShop = 20,
}) {
  final merged = <PartnerPromotion>[];
  for (final batch in batches) {
    final rows = List<PartnerPromotion>.from(batch)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (rows.length > perShop) {
      merged.addAll(rows.take(perShop));
    } else {
      merged.addAll(rows);
    }
  }
  merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return merged;
}

void validatePartnerPromotion({
  required String kind,
  required DateTime startsOn,
  required DateTime endsOn,
  required String note,
}) {
  if (partnerPromotionKindById(kind) == null) {
    throw const PartnerPromotionInvalid('kind');
  }
  final text = note.trim();
  if (text.isEmpty || text.length > 80) {
    throw const PartnerPromotionInvalid('note');
  }
  final start = DateTime(startsOn.year, startsOn.month, startsOn.day);
  final end = DateTime(endsOn.year, endsOn.month, endsOn.day);
  if (end.isBefore(start) || !end.isBefore(start.add(const Duration(days: 366)))) {
    throw const PartnerPromotionInvalid('period');
  }
}

DateTime? parsePartnerPromotionDay(String raw) {
  final text = raw.trim();
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
  if (match == null) {
    return null;
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  return date;
}
