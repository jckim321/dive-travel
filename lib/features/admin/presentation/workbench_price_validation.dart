/// Parses a workbench price field. Returns a positive int, or null when empty,
/// non-numeric, zero, or negative (so save can block `?? 0` silent zeros).
int? parsePositivePrice(String raw) {
  final n = int.tryParse(raw.trim());
  if (n == null || n <= 0) {
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

/// Result of checking diver / optional guest / named option prices.
class WorkbenchPriceCheck {
  const WorkbenchPriceCheck.ok() : target = null;
  const WorkbenchPriceCheck.fail(this.target);

  final WorkbenchPriceTarget? target;

  bool get isOk => target == null;
}

/// Shared rules for [OpsProductWorkbench] save (partner / admin / creator).
WorkbenchPriceCheck checkWorkbenchPrices({
  required String diverRaw,
  required bool hasNondivers,
  required String nondiverRaw,
  required String childRaw,
  required Iterable<String> namedOptionPriceRaws,
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
  for (final raw in namedOptionPriceRaws) {
    if (parsePositivePrice(raw) == null) {
      return const WorkbenchPriceCheck.fail(WorkbenchPriceTarget.option);
    }
  }
  return const WorkbenchPriceCheck.ok();
}
