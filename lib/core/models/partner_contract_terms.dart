import 'package:dive_travel_app/core/data/dive_star.dart';

/// Stored on `shops/{shopId}/contract_terms/current`. Missing fields mean
/// the admin has not entered that value yet.
abstract final class PartnerContractTermFields {
  static const commission = 'commission_rate_percent';
  static const party = 'party_discount_percent';
  static const season = 'season_discount_percent';
  static const focPay = 'instructor_foc_pay';
  static const focFree = 'instructor_foc_free';
  static const validFrom = 'valid_from';
  static const validUntil = 'valid_until';
  static const updatedAt = 'updated_at';
  static const updatedByUid = 'updated_by_uid';

  static const allowed = [
    commission,
    party,
    season,
    focPay,
    focFree,
    validFrom,
    validUntil,
    updatedAt,
    updatedByUid,
  ];
}

class PartnerContractTermsUnchanged implements Exception {
  const PartnerContractTermsUnchanged();
}

class PartnerContractTermsInvalid implements Exception {
  const PartnerContractTermsInvalid(this.code);

  /// `number`, `foc`, or `period`.
  final String code;
}

class PartnerContractTermChange {
  const PartnerContractTermChange({
    required this.field,
    required this.before,
    required this.after,
  });

  factory PartnerContractTermChange.fromMap(Map<String, dynamic> data) {
    return PartnerContractTermChange(
      field: (data['field'] as String? ?? '').trim(),
      before: (data['before'] as String? ?? '').trim(),
      after: (data['after'] as String? ?? '').trim(),
    );
  }

  final String field;
  final String before;
  final String after;

  Map<String, dynamic> toMap() => {
        'field': field,
        'before': before,
        'after': after,
      };
}

class PartnerContractTermRevision {
  const PartnerContractTermRevision({
    required this.id,
    required this.at,
    required this.uid,
    required this.actorName,
    required this.changes,
  });

  factory PartnerContractTermRevision.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final raw = data['changes'];
    return PartnerContractTermRevision(
      id: id,
      at: DiveStar.parseDate(data['at']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      uid: (data['uid'] as String? ?? '').trim(),
      actorName: (data['actor_name'] as String? ?? '').trim(),
      changes: [
        if (raw is List)
          for (final item in raw)
            if (item is Map)
              PartnerContractTermChange.fromMap(
                Map<String, dynamic>.from(item),
              ),
      ],
    );
  }

  final String id;
  final DateTime at;
  final String uid;
  final String actorName;
  final List<PartnerContractTermChange> changes;
}

class PartnerContractTerms {
  const PartnerContractTerms({
    this.commissionRatePercent,
    this.partyDiscountPercent,
    this.seasonDiscountPercent,
    this.instructorFocPay,
    this.instructorFocFree,
    this.validFrom,
    this.validUntil,
    this.updatedAt,
    this.updatedByUid = '',
  });

  static const empty = PartnerContractTerms();

  factory PartnerContractTerms.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return empty;
    }
    return PartnerContractTerms(
      commissionRatePercent: _readDouble(data[PartnerContractTermFields.commission]),
      partyDiscountPercent: _readDouble(data[PartnerContractTermFields.party]),
      seasonDiscountPercent: _readDouble(data[PartnerContractTermFields.season]),
      instructorFocPay: _readInt(data[PartnerContractTermFields.focPay]),
      instructorFocFree: _readInt(data[PartnerContractTermFields.focFree]),
      validFrom: DiveStar.parseDate(data[PartnerContractTermFields.validFrom]),
      validUntil: DiveStar.parseDate(data[PartnerContractTermFields.validUntil]),
      updatedAt: DiveStar.parseDate(data[PartnerContractTermFields.updatedAt]),
      updatedByUid: (data[PartnerContractTermFields.updatedByUid] as String? ?? '')
          .trim(),
    );
  }

  final double? commissionRatePercent;
  final double? partyDiscountPercent;
  final double? seasonDiscountPercent;
  final int? instructorFocPay;
  final int? instructorFocFree;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final DateTime? updatedAt;
  final String updatedByUid;

  /// Value fields only. The repository adds the server clock and uid.
  Map<String, dynamic> toValueMap() {
    return {
      if (commissionRatePercent != null)
        PartnerContractTermFields.commission: commissionRatePercent,
      if (partyDiscountPercent != null)
        PartnerContractTermFields.party: partyDiscountPercent,
      if (seasonDiscountPercent != null)
        PartnerContractTermFields.season: seasonDiscountPercent,
      if (instructorFocPay != null)
        PartnerContractTermFields.focPay: instructorFocPay,
      if (instructorFocFree != null)
        PartnerContractTermFields.focFree: instructorFocFree,
      if (validFrom != null) PartnerContractTermFields.validFrom: validFrom,
      if (validUntil != null) PartnerContractTermFields.validUntil: validUntil,
    };
  }
}

PartnerContractTerms parsePartnerContractTerms({
  required String commission,
  required String party,
  required String season,
  required String focPay,
  required String focFree,
  DateTime? validFrom,
  DateTime? validUntil,
}) {
  final payText = focPay.trim();
  final freeText = focFree.trim();
  if (payText.isEmpty != freeText.isEmpty) {
    throw const PartnerContractTermsInvalid('foc');
  }
  if (validFrom != null &&
      validUntil != null &&
      _dateOnly(validUntil).isBefore(_dateOnly(validFrom))) {
    throw const PartnerContractTermsInvalid('period');
  }
  return PartnerContractTerms(
    commissionRatePercent: _parsePercent(commission),
    partyDiscountPercent: _parsePercent(party),
    seasonDiscountPercent: _parsePercent(season),
    instructorFocPay: payText.isEmpty ? null : _parseFocPay(payText),
    instructorFocFree: freeText.isEmpty ? null : _parseFocFree(freeText),
    validFrom: validFrom == null ? null : _dateOnly(validFrom),
    validUntil: validUntil == null ? null : _dateOnly(validUntil),
  );
}

List<PartnerContractTermChange> diffPartnerContractTerms(
  PartnerContractTerms before,
  PartnerContractTerms after,
) {
  final changes = <PartnerContractTermChange>[];
  void add(String field, String previous, String next) {
    if (previous == next) {
      return;
    }
    changes.add(
      PartnerContractTermChange(field: field, before: previous, after: next),
    );
  }

  add(
    PartnerContractTermFields.commission,
    formatPartnerTermNumber(before.commissionRatePercent),
    formatPartnerTermNumber(after.commissionRatePercent),
  );
  add(
    PartnerContractTermFields.party,
    formatPartnerTermNumber(before.partyDiscountPercent),
    formatPartnerTermNumber(after.partyDiscountPercent),
  );
  add(
    PartnerContractTermFields.season,
    formatPartnerTermNumber(before.seasonDiscountPercent),
    formatPartnerTermNumber(after.seasonDiscountPercent),
  );
  add(
    PartnerContractTermFields.focPay,
    formatPartnerTermNumber(before.instructorFocPay),
    formatPartnerTermNumber(after.instructorFocPay),
  );
  add(
    PartnerContractTermFields.focFree,
    formatPartnerTermNumber(before.instructorFocFree),
    formatPartnerTermNumber(after.instructorFocFree),
  );
  add(
    PartnerContractTermFields.validFrom,
    formatPartnerTermDay(before.validFrom),
    formatPartnerTermDay(after.validFrom),
  );
  add(
    PartnerContractTermFields.validUntil,
    formatPartnerTermDay(before.validUntil),
    formatPartnerTermDay(after.validUntil),
  );
  return changes;
}

String formatPartnerTermNumber(num? value) {
  if (value == null) {
    return '';
  }
  final text = value.toString();
  if (text.endsWith('.0')) {
    return text.substring(0, text.length - 2);
  }
  return text;
}

String formatPartnerTermDay(DateTime? value) {
  if (value == null) {
    return '';
  }
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

double? _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return null;
}

int? _readInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  return null;
}

double? _parsePercent(String raw) {
  final text = raw.trim();
  if (text.isEmpty) {
    return null;
  }
  final value = double.tryParse(text.replaceAll(',', ''));
  if (value == null || value < 0 || value > 100) {
    throw const PartnerContractTermsInvalid('number');
  }
  return value;
}

int _parseFocPay(String raw) {
  final value = int.tryParse(raw);
  if (value == null || value < 1 || value > 100) {
    throw const PartnerContractTermsInvalid('number');
  }
  return value;
}

int _parseFocFree(String raw) {
  final value = int.tryParse(raw);
  if (value == null || value < 0 || value > 100) {
    throw const PartnerContractTermsInvalid('number');
  }
  return value;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
