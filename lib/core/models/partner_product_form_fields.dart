import 'package:dive_travel_app/core/models/shop_product.dart';

/// Partner form category chips (시안 22): resort / day trip / liveaboard.
const partnerCategoryChips = <ProductCategory>[
  ProductCategory.resortPackage,
  ProductCategory.dayTrip,
  ProductCategory.liveaboard,
];

bool isPartnerCategoryChip(ProductCategory category) {
  return partnerCategoryChips.contains(category);
}

/// Which chip is selected, or null when stored value is outside the three
/// (e.g. funDive / course) until the user taps a chip.
ProductCategory? selectedPartnerCategoryChip(ProductCategory stored) {
  return isPartnerCategoryChip(stored) ? stored : null;
}

/// Resolve category for save: keep [stored] until the user has chosen a chip.
ProductCategory categoryForPartnerSave({
  required ProductCategory stored,
  required bool userSelectedChip,
  required ProductCategory chipValue,
}) {
  if (!userSelectedChip) {
    return stored;
  }
  return chipValue;
}

/// Parsed nights/days from a duration label, or [parsed] false when freeform.
class DurationLabelParts {
  const DurationLabelParts({
    required this.parsed,
    this.nights,
    this.days,
  });

  final bool parsed;
  final int? nights;
  final int? days;
}

/// Parses labels like `2박 3일`, `2박`, `3일`. Other text → [parsed] false.
DurationLabelParts parseDurationLabelParts(String? label) {
  final raw = (label ?? '').trim();
  if (raw.isEmpty) {
    return const DurationLabelParts(parsed: true, nights: null, days: null);
  }
  final nightsMatch = RegExp(r'(\d+)\s*박').firstMatch(raw);
  final daysMatch = RegExp(r'(\d+)\s*일').firstMatch(raw);
  if (nightsMatch == null && daysMatch == null) {
    return const DurationLabelParts(parsed: false);
  }
  // Reject leftover letters that are not 박/일/digits/whitespace.
  final stripped = raw
      .replaceAll(RegExp(r'\d+\s*박'), '')
      .replaceAll(RegExp(r'\d+\s*일'), '')
      .replaceAll(RegExp(r'[\s·/,.-]'), '');
  if (stripped.isNotEmpty) {
    return const DurationLabelParts(parsed: false);
  }
  int? nights;
  int? days;
  if (nightsMatch != null) {
    nights = int.tryParse(nightsMatch.group(1)!);
  }
  if (daysMatch != null) {
    days = int.tryParse(daysMatch.group(1)!);
  } else if (nights != null) {
    days = nights <= 0 ? 1 : nights + 1;
  }
  if (nights == null && days != null) {
    nights = days <= 1 ? 0 : days - 1;
  }
  return DurationLabelParts(parsed: true, nights: nights, days: days);
}

String combineDurationLabel({required int nights, required int days}) {
  final n = nights < 0 ? 0 : nights;
  final d = days < 1 ? 1 : days;
  return '$n박 $d일';
}

/// Duration string written on partner save.
String durationLabelForPartnerSave({
  required String originalLabel,
  required bool userEditedFields,
  required int? nights,
  required int? days,
}) {
  if (!userEditedFields) {
    return originalLabel;
  }
  final n = nights ?? 0;
  final d = days ?? (n <= 0 ? 1 : n + 1);
  return combineDurationLabel(nights: n, days: d);
}
