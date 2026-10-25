import 'package:dive_travel_app/core/constants/option_group.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/features/admin/analytics/admin_sales_math.dart';

/// One option already loaded with its shop product. No extra read.
class AdminListedOption {
  const AdminListedOption({
    required this.shopId,
    required this.productId,
    required this.optionId,
    required this.name,
    required this.group,
  });

  final String shopId;
  final String productId;
  final String optionId;
  final String name;
  final String group;
}

/// One counted option name inside a group. Empty [group] is unclassified.
class AdminOptionGroupLine {
  const AdminOptionGroupLine({
    required this.group,
    required this.name,
    required this.count,
  });

  final String group;
  final String name;
  final int count;
}

class AdminOptionGroupTally {
  const AdminOptionGroupTally({
    required this.names,
    required this.lines,
  });

  /// Every option name in the window, before the on-screen top-N cut.
  final List<({String name, int count})> names;

  /// Same picks, each carrying the group found on the current product.
  final List<AdminOptionGroupLine> lines;

  bool get hasKnownGroup => lines.any((line) => line.group.isNotEmpty);

  int get total => lines.fold<int>(0, (sum, line) => sum + line.count);
}

/// Counts option names the same way as before, then attaches a group.
///
/// A booking stores one option id and a joined name list. Each name uses
/// that id when it matches, otherwise the only same-named option on the
/// product. Missing product, ambiguous name, or empty group is unclassified.
AdminOptionGroupTally countAdminOptionGroups({
  required List<TourBooking> bookings,
  required AdminSalesWindow window,
  required List<AdminListedOption> catalog,
}) {
  final byProduct = <String, List<AdminListedOption>>{};
  for (final option in catalog) {
    final key = '${option.shopId}|${option.productId}';
    byProduct.putIfAbsent(key, () => <AdminListedOption>[]).add(option);
  }
  final nameCounts = <String, int>{};
  final grouped = <String, Map<String, int>>{};
  for (final booking in bookings) {
    if (!window.contains(booking.createdAt)) {
      continue;
    }
    final raw = booking.optionName.trim();
    if (raw.isEmpty) {
      continue;
    }
    final options = byProduct['${booking.shopId}|${booking.productId}'];
    for (final part in raw.split('·')) {
      final name = part.trim();
      if (name.isEmpty) {
        continue;
      }
      nameCounts[name] = (nameCounts[name] ?? 0) + 1;
      final group = _groupFor(booking: booking, name: name, options: options);
      final bucket = grouped.putIfAbsent(group, () => <String, int>{});
      bucket[name] = (bucket[name] ?? 0) + 1;
    }
  }
  final names = [
    for (final entry in nameCounts.entries) (name: entry.key, count: entry.value),
  ]..sort((a, b) => b.count.compareTo(a.count));
  final lines = <AdminOptionGroupLine>[];
  for (final code in [for (final group in optionGroups) group.id, '']) {
    final bucket = grouped[code];
    if (bucket == null) {
      continue;
    }
    final rows = [
      for (final entry in bucket.entries)
        AdminOptionGroupLine(group: code, name: entry.key, count: entry.value),
    ]..sort((a, b) => b.count.compareTo(a.count));
    lines.addAll(rows);
  }
  return AdminOptionGroupTally(names: names, lines: lines);
}

String _groupFor({
  required TourBooking booking,
  required String name,
  required List<AdminListedOption>? options,
}) {
  if (options == null) {
    return '';
  }
  final id = booking.optionId.trim();
  if (id.isNotEmpty) {
    for (final option in options) {
      if (option.optionId == id && option.name.trim() == name) {
        return normalizeOptionGroup(option.group);
      }
    }
  }
  final named = [
    for (final option in options)
      if (option.name.trim() == name) option,
  ];
  if (named.length == 1) {
    return normalizeOptionGroup(named.single.group);
  }
  return '';
}

List<String> reportOptionGroupTexts(List<AdminOptionGroupLine> lines) {
  final out = <String>[];
  String? current;
  for (final line in lines) {
    if (line.group != current) {
      current = line.group;
      out.add(optionGroupNameKo(line.group));
    }
    out.add('${line.name}  ${line.count}');
  }
  return out;
}
