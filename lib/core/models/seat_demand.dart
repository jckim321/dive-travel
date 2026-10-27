import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:dive_travel_app/core/models/same_boat_search.dart';
import 'package:dive_travel_app/core/models/seat_life.dart';

/// Which filter a widen step removed. Stored only when that step shows seats.
enum SeatUnlock {
  budget,
  party,
  when,
  where,
  more;

  static SeatUnlock? parse(String? value) {
    for (final unlock in SeatUnlock.values) {
      if (unlock.name == value) {
        return unlock;
      }
    }
    return null;
  }
}

/// The condition [SameBoatSearch.widen] would drop, if any.
SeatUnlock? seatUnlockOf(SameBoatSearch search) {
  if (search.budgetMax != null) {
    return SeatUnlock.budget;
  }
  if (search.party != null) {
    return SeatUnlock.party;
  }
  if (search.when != SameBoatWhen.any) {
    return SeatUnlock.when;
  }
  if (search.regionIds.isNotEmpty) {
    return SeatUnlock.where;
  }
  if (search.lastCall || search.departingSoon) {
    return SeatUnlock.more;
  }
  return null;
}

/// One unmet same-boat search. Create-only. No name, email, or phone.
class SeatDemand {
  const SeatDemand({
    required this.id,
    required this.userKey,
    required this.day,
    required this.search,
    required this.at,
    this.unlockBy,
  });

  static final _regionIds = RegExp(
    r'^[a-z0-9-]{1,40}(,[a-z0-9-]{1,40}){0,19}$',
  );
  static final _id = RegExp(
    r'^[0-9a-f]{64}_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9a-f]{64}$',
  );

  final String id;
  final String userKey;
  final String day;
  final SameBoatSearch search;
  final DateTime at;
  final SeatUnlock? unlockBy;

  static SeatDemand forSearch({
    required String uid,
    required SameBoatSearch search,
    required DateTime at,
    SeatUnlock? unlockBy,
  }) {
    final userKey = seatUserKey(uid);
    final day = seatDayId(at);
    final regions = search.regionIds.toList()..sort();
    final payload = [
      search.when.firestoreValue,
      regions.join(','),
      '${search.party ?? 0}',
      '${search.budgetMax ?? 0}',
      search.lastCall ? '1' : '0',
      search.departingSoon ? '1' : '0',
    ].join('|');
    final conditions = sha256.convert(utf8.encode(payload)).toString();
    return SeatDemand(
      id: '${userKey}_${day}_$conditions',
      userKey: userKey,
      day: day,
      search: search,
      at: at,
      unlockBy: unlockBy,
    );
  }

  String get regionIds {
    final regions = search.regionIds.toList()..sort();
    return regions.join(',');
  }

  Map<String, Object> toMap() {
    return {
      'user_key': userKey,
      'day': day,
      'when': search.when.firestoreValue,
      'region_ids': regionIds,
      'party': search.party ?? 0,
      'budget_max': search.budgetMax ?? 0,
      'last_call': search.lastCall,
      'departing_soon': search.departingSoon,
      'at': at.toUtc(),
      if (unlockBy != null) 'unlock_by': unlockBy!.name,
    };
  }

  bool get withinShape {
    final data = toMap();
    const base = {
      'user_key',
      'day',
      'when',
      'region_ids',
      'party',
      'budget_max',
      'last_call',
      'departing_soon',
      'at',
    };
    final allowed = unlockBy == null ? base : {...base, 'unlock_by'};
    if (data.length != allowed.length ||
        data.keys.any((key) => !allowed.contains(key))) {
      return false;
    }
    const banned = ['name', 'display_name', 'email', 'phone', 'uid'];
    if (data.keys.any(banned.contains)) {
      return false;
    }
    final when = data['when'];
    final regions = data['region_ids'];
    final party = data['party'];
    final budget = data['budget_max'];
    return _id.hasMatch(id) &&
        id.startsWith('${userKey}_${day}_') &&
        userKey.length == 64 &&
        day == seatDayId(at) &&
        when is String &&
        when == search.when.firestoreValue &&
        regions is String &&
        regions.length <= 900 &&
        (regions.isEmpty || _regionIds.hasMatch(regions)) &&
        party is int &&
        party >= 0 &&
        party <= 20 &&
        budget is int &&
        budget >= 0 &&
        budget <= 100000000 &&
        data['last_call'] is bool &&
        data['departing_soon'] is bool &&
        (unlockBy == null || SeatUnlock.parse(unlockBy!.name) == unlockBy);
  }

  static SeatDemand? fromStored(String id, Map<String, dynamic> data) {
    final at = _storedAt(data['at']);
    final userKey = data['user_key'];
    final day = data['day'];
    if (at == null || userKey is! String || day is! String) {
      return null;
    }
    final party = (data['party'] as num?)?.toInt() ?? 0;
    final budget = (data['budget_max'] as num?)?.toInt() ?? 0;
    final regions = <String>{
      for (final part in (data['region_ids'] as String? ?? '').split(','))
        if (part.isNotEmpty) part,
    };
    return SeatDemand(
      id: id,
      userKey: userKey,
      day: day,
      at: at,
      unlockBy: SeatUnlock.parse(data['unlock_by'] as String?),
      search: SameBoatSearch(
        when: SameBoatWhenStorage.parse(data['when']),
        regionIds: regions,
        party: party == 0 ? null : party,
        budgetMax: budget == 0 ? null : budget,
        lastCall: data['last_call'] == true,
        departingSoon: data['departing_soon'] == true,
      ),
    );
  }
}

DateTime? _storedAt(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
