/// Max digit count after stripping non-digits (10+ → over cap).
/// 9 allows the max value 100,000,000.
const kWorkbenchPriceMaxDigits = 9;

/// Max accepted unit price (above → over cap). 1억 원.
const kWorkbenchPriceMaxValue = 100000000; // 100,000,000

/// TextField maxLength allowing commas / spaces / 원 around digits.
/// Fits `100,000,000` plus a little slack.
const kWorkbenchPriceInputMaxLength = 12;

/// Why [parseWorkbenchPrice] rejected the input.
enum WorkbenchPriceParseFailure {
  /// Empty, non-numeric, zero, or negative.
  emptyOrNonPositive,

  /// Too many digits or value above [kWorkbenchPriceMaxValue].
  overCap,
}

/// Result of parsing a workbench price field.
class WorkbenchPriceParse {
  const WorkbenchPriceParse.ok(this.value) : failure = null;
  const WorkbenchPriceParse.fail(this.failure) : value = null;

  final int? value;
  final WorkbenchPriceParseFailure? failure;

  bool get isOk => value != null && failure == null;
}

/// Parses a workbench price field. Digits-only after stripping commas, spaces,
/// and 「원」. Distinguishes empty/non-positive from over-cap.
WorkbenchPriceParse parseWorkbenchPrice(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return const WorkbenchPriceParse.fail(
      WorkbenchPriceParseFailure.emptyOrNonPositive,
    );
  }
  if (trimmed.startsWith('-')) {
    return const WorkbenchPriceParse.fail(
      WorkbenchPriceParseFailure.emptyOrNonPositive,
    );
  }
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) {
    return const WorkbenchPriceParse.fail(
      WorkbenchPriceParseFailure.emptyOrNonPositive,
    );
  }
  if (digits.length > kWorkbenchPriceMaxDigits) {
    return const WorkbenchPriceParse.fail(WorkbenchPriceParseFailure.overCap);
  }
  final n = int.tryParse(digits);
  if (n == null || n <= 0) {
    return const WorkbenchPriceParse.fail(
      WorkbenchPriceParseFailure.emptyOrNonPositive,
    );
  }
  if (n > kWorkbenchPriceMaxValue) {
    return const WorkbenchPriceParse.fail(WorkbenchPriceParseFailure.overCap);
  }
  return WorkbenchPriceParse.ok(n);
}

/// Parses a workbench price field. Returns a positive int, or null when invalid.
int? parsePositivePrice(String raw) => parseWorkbenchPrice(raw).value;

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
        optionName = null,
        failure = null;
  const WorkbenchPriceCheck.fail(
    this.target, {
    this.optionName,
    required this.failure,
  });

  final WorkbenchPriceTarget? target;
  final String? optionName;
  final WorkbenchPriceParseFailure? failure;

  bool get isOk => target == null;
}

WorkbenchPriceCheck _failFromParse({
  required WorkbenchPriceTarget target,
  required WorkbenchPriceParse parse,
  String? optionName,
}) {
  return WorkbenchPriceCheck.fail(
    target,
    optionName: optionName,
    failure: parse.failure ?? WorkbenchPriceParseFailure.emptyOrNonPositive,
  );
}

/// Shared rules for [OpsProductWorkbench] save (partner / admin / creator).
WorkbenchPriceCheck checkWorkbenchPrices({
  required String diverRaw,
  required bool hasNondivers,
  required String nondiverRaw,
  required String childRaw,
  required Iterable<WorkbenchNamedOptionPrice> namedOptions,
}) {
  final diver = parseWorkbenchPrice(diverRaw);
  if (!diver.isOk) {
    return _failFromParse(target: WorkbenchPriceTarget.diver, parse: diver);
  }
  if (hasNondivers) {
    final nondiver = parseWorkbenchPrice(nondiverRaw);
    if (!nondiver.isOk) {
      return _failFromParse(
        target: WorkbenchPriceTarget.nondiver,
        parse: nondiver,
      );
    }
    final child = parseWorkbenchPrice(childRaw);
    if (!child.isOk) {
      return _failFromParse(target: WorkbenchPriceTarget.child, parse: child);
    }
  }
  for (final option in namedOptions) {
    final parsed = parseWorkbenchPrice(option.priceRaw);
    if (!parsed.isOk) {
      return _failFromParse(
        target: WorkbenchPriceTarget.option,
        parse: parsed,
        optionName: option.name,
      );
    }
  }
  return const WorkbenchPriceCheck.ok();
}

/// True when a stored unit price is within the workbench save/approve band.
bool isWorkbenchUnitPriceAllowed(int price) =>
    price > 0 && price <= kWorkbenchPriceMaxValue;
