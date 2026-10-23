/// Max digit count after stripping non-digits (12+ → invalid).
/// 11 allows the max value 10,000,000,000.
const kWorkbenchPriceMaxDigits = 11;

/// Max accepted price value (above → invalid).
const kWorkbenchPriceMaxValue = 10000000000; // 10,000,000,000

/// TextField maxLength allowing commas / spaces / 원 around digits.
const kWorkbenchPriceInputMaxLength = 16;

/// Parses a workbench price field. Digits-only after stripping commas, spaces,
/// and 「원」. Returns a positive int, or null when empty, non-numeric, zero,
/// negative, too many digits, or above [kWorkbenchPriceMaxValue].
int? parsePositivePrice(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (trimmed.startsWith('-')) {
    return null;
  }
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) {
    return null;
  }
  if (digits.length > kWorkbenchPriceMaxDigits) {
    return null;
  }
  final n = int.tryParse(digits);
  if (n == null || n <= 0 || n > kWorkbenchPriceMaxValue) {
    return null;
  }
  return n;
}

/// Which guest / option price failed workbench save validation.
enum WorkbenchPriceTarget {
  diver,
  nondiver,
  child,
  option,
}

/// Named option (addon / individual) price input for validation.
class WorkbenchNamedOptionPrice {
  const WorkbenchNamedOptionPrice({
    required this.name,
    required this.priceRaw,
  });

  final String name;
  final String priceRaw;
}

/// Result of checking diver / optional guest / named option prices.
class WorkbenchPriceCheck {
  const WorkbenchPriceCheck.ok()
      : target = null,
        optionName = null;
  const WorkbenchPriceCheck.fail(this.target, {this.optionName});

  final WorkbenchPriceTarget? target;
  final String? optionName;

  bool get isOk => target == null;
}

/// Shared rules for [OpsProductWorkbench] save (partner / admin / creator).
WorkbenchPriceCheck checkWorkbenchPrices({
  required String diverRaw,
  required bool hasNondivers,
  required String nondiverRaw,
  required String childRaw,
  required Iterable<WorkbenchNamedOptionPrice> namedOptions,
}) {
  if (parsePositivePrice(diverRaw) == null) {
    return const WorkbenchPriceCheck.fail(WorkbenchPriceTarget.diver);
  }
  if (hasNondivers) {
    if (parsePositivePrice(nondiverRaw) == null) {
      return const WorkbenchPriceCheck.fail(WorkbenchPriceTarget.nondiver);
    }
    if (parsePositivePrice(childRaw) == null) {
      return const WorkbenchPriceCheck.fail(WorkbenchPriceTarget.child);
    }
  }
  for (final option in namedOptions) {
    if (parsePositivePrice(option.priceRaw) == null) {
      return WorkbenchPriceCheck.fail(
        WorkbenchPriceTarget.option,
        optionName: option.name,
      );
    }
  }
  return const WorkbenchPriceCheck.ok();
}
