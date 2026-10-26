import 'package:dive_travel_app/core/models/same_boat_search.dart';

/// Saved zero-result search. No name, email, or phone.
class SameBoatAlert {
  const SameBoatAlert({
    required this.id,
    required this.search,
    required this.createdAt,
  });

  static const limit = 20;

  final String id;
  final SameBoatSearch search;
  final DateTime createdAt;

  bool sameConditions(SameBoatSearch other) => search.sameConditions(other);

  Map<String, dynamic> toMap() {
    final regions = search.regionIds.toList()..sort();
    return {
      'id': id,
      'when': search.when.firestoreValue,
      'region_ids': regions,
      if (search.party != null) 'party': search.party,
      if (search.budgetMax != null) 'budget_max': search.budgetMax,
      'last_call': search.lastCall,
      'departing_soon': search.departingSoon,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  static SameBoatAlert? fromMap(Map<String, dynamic> data) {
    final id = (data['id'] as String?)?.trim() ?? '';
    final createdAt = _time(data['created_at']);
    if (id.isEmpty || createdAt == null) {
      return null;
    }
    final regions = <String>{
      for (final value in (data['region_ids'] as List<dynamic>? ?? const []))
        if (value is String && value.trim().isNotEmpty) value.trim(),
    };
    return SameBoatAlert(
      id: id,
      createdAt: createdAt,
      search: SameBoatSearch(
        when: SameBoatWhenStorage.parse(data['when']),
        regionIds: regions,
        party: (data['party'] as num?)?.toInt(),
        budgetMax: (data['budget_max'] as num?)?.toInt(),
        lastCall: data['last_call'] == true,
        departingSoon: data['departing_soon'] == true,
      ),
    );
  }

  static List<SameBoatAlert> listFrom(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    final alerts = <SameBoatAlert>[];
    for (final item in raw) {
      final map = item is Map<String, dynamic>
          ? item
          : item is Map
              ? Map<String, dynamic>.from(item)
              : null;
      if (map == null) {
        continue;
      }
      final alert = fromMap(map);
      if (alert != null) {
        alerts.add(alert);
      }
    }
    return alerts;
  }
}

enum SeatAlertWrite { saved, alreadySaved }

class SeatAlertUpdate {
  const SeatAlertUpdate(this.result, this.alerts);

  final SeatAlertWrite result;
  final List<SameBoatAlert> alerts;
}

/// Keeps at most [SameBoatAlert.limit] alerts. A matching search is not stored again.
SeatAlertUpdate appendSeatAlert({
  required List<SameBoatAlert> existing,
  required SameBoatSearch search,
  required DateTime now,
  String? id,
}) {
  if (existing.any((alert) => alert.sameConditions(search))) {
    return SeatAlertUpdate(SeatAlertWrite.alreadySaved, existing);
  }
  final next = [
    ...existing,
    SameBoatAlert(
      id: (id ?? '').trim().isEmpty
          ? 'alert-${now.microsecondsSinceEpoch}'
          : id!.trim(),
      search: search,
      createdAt: now,
    ),
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  if (next.length <= SameBoatAlert.limit) {
    return SeatAlertUpdate(SeatAlertWrite.saved, next);
  }
  return SeatAlertUpdate(
    SeatAlertWrite.saved,
    next.sublist(next.length - SameBoatAlert.limit),
  );
}

DateTime? _time(dynamic value) {
  if (value is DateTime) {
    return value.toUtc();
  }
  if (value is String) {
    return DateTime.tryParse(value)?.toUtc();
  }
  try {
    final dynamic clock = value;
    final converted = clock.toDate();
    if (converted is DateTime) {
      return converted.toUtc();
    }
  } catch (_) {}
  return null;
}
