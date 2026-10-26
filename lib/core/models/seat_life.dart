import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Top-level analytics for one same-boat seat. Not a seat or payment record.
///
/// `seat_events/{id}` is create-only. `seat_daily/{yyyy-mm-dd}` only grows by
/// 1. `seat_outcomes/{seatId}` is the frozen summary an admin writes.
const seatLifeEventKinds = [
  'open',
  'view',
  'flag',
  'expire',
  'pay',
  'cancel',
  'close',
];

const seatDayFields = [
  'opens',
  'views',
  'flags',
  'expires',
  'pays',
  'cancels',
  'closes',
];

const seatLifeForbiddenKeys = [
  'name',
  'display_name',
  'email',
  'phone',
  'uid',
  'guest_contact',
];

const seatViewFlushInterval = Duration(seconds: 30);

/// sha256 of the member id. The raw id is not stored.
String seatUserKey(String uid) =>
    sha256.convert(utf8.encode(uid)).toString();

String seatLifeId(String productId, String optionId) {
  final product = productId.replaceAll('/', '_');
  if (optionId.isEmpty) {
    return 'p_$product';
  }
  return 'p_${product}__o_${optionId.replaceAll('/', '_')}';
}

String seatDayId(DateTime at) {
  final local = at.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String? seatDayField(String kind) {
  return switch (kind) {
    'open' => 'opens',
    'view' => 'views',
    'flag' => 'flags',
    'expire' => 'expires',
    'pay' => 'pays',
    'cancel' => 'cancels',
    'close' => 'closes',
    _ => null,
  };
}

String openEventId(String seatId) => 'open_$seatId';

String viewEventId(String userKey, String seatId, DateTime windowStart) {
  final bucket = windowStart.toUtc().millisecondsSinceEpoch ~/
      seatViewFlushInterval.inMilliseconds;
  return 'view_${userKey}_${seatId}_$bucket';
}

String flagEventId(String userKey, String seatId, DateTime until) =>
    'flag_${userKey}_${seatId}_${until.toUtc().millisecondsSinceEpoch}';

String expireEventId(String seatId, String userKey, DateTime expiresAt) =>
    'expire_${seatId}_${userKey}_${expiresAt.toUtc().millisecondsSinceEpoch}';

String closeEventId(String seatId) => 'close_$seatId';

String payEventId(
  String userKey,
  String seatId,
  DateTime? tour,
  int price,
  int party,
) {
  final day = tour == null ? 'none' : seatDayId(tour);
  return 'pay_${userKey}_${seatId}_${day}_${price}_$party';
}

String unflagEventId(String userKey, String seatId, DateTime now) =>
    'unflag_${userKey}_${seatId}_${seatDayId(now)}';

String cancelEventId(String bookingId) =>
    'cancel_${bookingId.replaceAll('/', '_')}';

DateTime seatDateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool seatDeparturePassed(DateTime departure, DateTime now) =>
    seatDateOnly(departure).isBefore(seatDateOnly(now));

class SeatLifeEvent {
  const SeatLifeEvent({
    required this.id,
    required this.kind,
    required this.seatId,
    required this.shopId,
    required this.productId,
    required this.userKey,
    required this.at,
    this.optionId = '',
    this.region = '',
    this.resort = '',
    this.departure = '',
    this.price = 0,
    this.partySize = 0,
    this.memberGrade = '',
    this.nationality = '',
    this.shareNationality = false,
    this.closeReason = '',
  });

  final String id;
  final String kind;
  final String seatId;
  final String shopId;
  final String productId;
  final String optionId;
  final String region;
  final String resort;
  final String departure;
  final int price;
  final int partySize;
  final String memberGrade;
  final String nationality;
  final bool shareNationality;
  final String userKey;
  final DateTime at;
  final String closeReason;

  SeatLifeEvent issued({required String id, DateTime? at}) {
    return SeatLifeEvent(
      id: id,
      kind: kind,
      seatId: seatId,
      shopId: shopId,
      productId: productId,
      optionId: optionId,
      region: region,
      resort: resort,
      departure: departure,
      price: price,
      partySize: partySize,
      memberGrade: memberGrade,
      nationality: nationality,
      shareNationality: shareNationality,
      userKey: userKey,
      at: at ?? this.at,
      closeReason: closeReason,
    );
  }

  Map<String, Object?> toStoredMap() {
    return {
      'kind': kind,
      'seat_id': seatId,
      'shop_id': shopId,
      'product_id': productId,
      'option_id': optionId,
      'region': region,
      'resort': resort,
      'departure': departure,
      'price': price,
      'party_size': partySize,
      'member_grade': memberGrade,
      'user_key': userKey,
      'at': at.toUtc().toIso8601String(),
      if (shareNationality && nationality.isNotEmpty) 'nationality': nationality,
      if (closeReason.isNotEmpty) 'close_reason': closeReason,
    };
  }

  bool get withinShape => seatEventShapeAllowed(toStoredMap());

  static SeatLifeEvent? fromMap(String id, Map<String, dynamic> data) {
    final atRaw = data['at'];
    final at = atRaw is String ? DateTime.tryParse(atRaw) : null;
    final kind = data['kind'];
    final seatId = data['seat_id'];
    final userKey = data['user_key'];
    if (at == null || kind is! String || seatId is! String || userKey is! String) {
      return null;
    }
    return SeatLifeEvent(
      id: id,
      kind: kind,
      seatId: seatId,
      shopId: data['shop_id'] as String? ?? '',
      productId: data['product_id'] as String? ?? '',
      optionId: data['option_id'] as String? ?? '',
      region: data['region'] as String? ?? '',
      resort: data['resort'] as String? ?? '',
      departure: data['departure'] as String? ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      partySize: (data['party_size'] as num?)?.toInt() ?? 0,
      memberGrade: data['member_grade'] as String? ?? '',
      nationality: data['nationality'] as String? ?? '',
      shareNationality: data['nationality'] is String,
      userKey: userKey,
      at: at,
      closeReason: data['close_reason'] as String? ?? '',
    );
  }
}

bool seatEventShapeAllowed(Map<String, Object?> data) {
  const allowed = {
    'kind',
    'seat_id',
    'shop_id',
    'product_id',
    'option_id',
    'region',
    'resort',
    'departure',
    'price',
    'party_size',
    'member_grade',
    'user_key',
    'at',
    'nationality',
    'close_reason',
  };
  if (data.keys.any((key) => !allowed.contains(key))) {
    return false;
  }
  if (data.keys.any(seatLifeForbiddenKeys.contains)) {
    return false;
  }
  final kind = data['kind'];
  final seatId = data['seat_id'];
  final shopId = data['shop_id'];
  final productId = data['product_id'];
  final optionId = data['option_id'];
  final region = data['region'];
  final resort = data['resort'];
  final departure = data['departure'];
  final price = data['price'];
  final party = data['party_size'];
  final grade = data['member_grade'];
  final userKey = data['user_key'];
  final at = data['at'];
  if (kind is! String || !seatLifeEventKinds.contains(kind)) {
    return false;
  }
  if (!_shortText(seatId, 1, 200) ||
      !_shortText(shopId, 0, 120) ||
      !_shortText(productId, 1, 120) ||
      !_shortText(optionId, 0, 120) ||
      !_shortText(region, 0, 80) ||
      !_shortText(resort, 0, 120)) {
    return false;
  }
  if (departure is! String ||
      (departure.isNotEmpty &&
          !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(departure))) {
    return false;
  }
  if (price is! int || price < 0 || party is! int || party < 0) {
    return false;
  }
  if (grade is! String ||
      !const {'', 'silver', 'gold', 'diamond', 'platinum'}.contains(grade)) {
    return false;
  }
  if (userKey is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(userKey)) {
    return false;
  }
  if (at is! String || DateTime.tryParse(at) == null) {
    return false;
  }
  final nationality = data['nationality'];
  if (nationality != null &&
      (nationality is! String ||
          nationality.length < 2 ||
          nationality.length > 8)) {
    return false;
  }
  final reason = data['close_reason'];
  if (reason != null && reason != 'sold_out' && reason != 'departed') {
    return false;
  }
  return true;
}

bool _shortText(Object? value, int min, int max) {
  return value is String && value.length >= min && value.length <= max;
}

Map<String, int> seatDayCreate(String field) {
  return {for (final name in seatDayFields) name: name == field ? 1 : 0};
}

bool seatDayCreateAllowed(Map<String, int> data) {
  if (data.length != seatDayFields.length) {
    return false;
  }
  var ones = 0;
  for (final name in seatDayFields) {
    final value = data[name];
    if (value == null || value < 0 || value > 1) {
      return false;
    }
    ones += value;
  }
  return ones == 1;
}

/// Exactly one counter grows by 1. Decrease, jump, and extra keys fail.
bool seatDayPlusOneAllowed(Map<String, int> before, Map<String, int> after) {
  if (before.length != seatDayFields.length ||
      after.length != seatDayFields.length) {
    return false;
  }
  var grown = 0;
  for (final name in seatDayFields) {
    final left = before[name];
    final right = after[name];
    if (left == null || right == null) {
      return false;
    }
    if (right == left) {
      continue;
    }
    if (right != left + 1) {
      return false;
    }
    grown += 1;
  }
  return grown == 1;
}

class SeatViewBuffer {
  SeatViewBuffer({this.interval = seatViewFlushInterval});

  final Duration interval;
  final Map<String, _SeatWatch> _watches = {};

  bool get isEmpty => _watches.isEmpty;

  void watch(SeatLifeEvent event, DateTime now) {
    final current = _watches[event.seatId];
    if (current == null) {
      _watches[event.seatId] = _SeatWatch(
        event: event,
        windowStart: now,
        dirty: true,
      );
      return;
    }
    _watches[event.seatId] = _SeatWatch(
      event: event,
      windowStart: current.windowStart,
      dirty: current.dirty,
    );
  }

  /// One event per seat per window. Empty until [interval] or the screen leaves.
  List<SeatLifeEvent> poll(DateTime now, {bool leaving = false}) {
    final out = <SeatLifeEvent>[];
    final drop = <String>[];
    for (final entry in _watches.entries) {
      final watch = entry.value;
      if (!watch.dirty) {
        continue;
      }
      final due = leaving || now.difference(watch.windowStart) >= interval;
      if (!due) {
        continue;
      }
      out.add(
        watch.event.issued(
          id: viewEventId(watch.event.userKey, watch.event.seatId, watch.windowStart),
          at: now,
        ),
      );
      if (leaving) {
        drop.add(entry.key);
      } else {
        _watches[entry.key] = _SeatWatch(
          event: watch.event,
          windowStart: now,
          dirty: true,
        );
      }
    }
    for (final seatId in drop) {
      _watches.remove(seatId);
    }
    return out;
  }
}

class _SeatWatch {
  const _SeatWatch({
    required this.event,
    required this.windowStart,
    required this.dirty,
  });

  final SeatLifeEvent event;
  final DateTime windowStart;
  final bool dirty;
}

class SeatLifeHold {
  const SeatLifeHold({
    required this.uid,
    required this.seats,
    required this.expiresAt,
    this.lockedPrice = 0,
  });

  final String uid;
  final int seats;
  final DateTime expiresAt;
  final int lockedPrice;
}

class SeatLifeSeat {
  const SeatLifeSeat({
    required this.productId,
    required this.optionId,
    required this.shopId,
    required this.region,
    required this.resort,
    required this.price,
    required this.capacity,
    required this.booked,
    this.departure,
    this.holds = const [],
  });

  final String productId;
  final String optionId;
  final String shopId;
  final String region;
  final String resort;
  final DateTime? departure;
  final int price;
  final int capacity;
  final int booked;
  final List<SeatLifeHold> holds;

  String get seatId => seatLifeId(productId, optionId);

  String get departureDay =>
      departure == null ? '' : seatDayId(departure!);
}

class SeatOutcome {
  const SeatOutcome({
    required this.seatId,
    required this.shopId,
    required this.openedOn,
    required this.firstFlagMinutes,
    required this.closeMinutes,
    required this.fillRate,
    required this.payRate,
    required this.expireCount,
    required this.closeReason,
  });

  final String seatId;
  final String shopId;
  final String openedOn;
  final int firstFlagMinutes;
  final int closeMinutes;
  final int fillRate;
  final int payRate;
  final int expireCount;
  final String closeReason;

  Map<String, Object?> toMap() {
    return {
      'seat_id': seatId,
      'shop_id': shopId,
      'opened_on': openedOn,
      'first_flag_minutes': firstFlagMinutes,
      'close_minutes': closeMinutes,
      'fill_rate': fillRate,
      'pay_rate': payRate,
      'expire_count': expireCount,
      'close_reason': closeReason,
    };
  }
}

bool seatOutcomeAllowed(Map<String, Object?> data) {
  const allowed = {
    'seat_id',
    'shop_id',
    'opened_on',
    'first_flag_minutes',
    'close_minutes',
    'fill_rate',
    'pay_rate',
    'expire_count',
    'close_reason',
  };
  if (data.length != allowed.length ||
      data.keys.any((key) => !allowed.contains(key))) {
    return false;
  }
  if (data.keys.any(seatLifeForbiddenKeys.contains)) {
    return false;
  }
  final fill = data['fill_rate'];
  final pay = data['pay_rate'];
  final expires = data['expire_count'];
  final reason = data['close_reason'];
  return data['seat_id'] is String &&
      data['shop_id'] is String &&
      data['opened_on'] is String &&
      data['first_flag_minutes'] is int &&
      data['close_minutes'] is int &&
      fill is int &&
      fill >= 0 &&
      fill <= 100 &&
      pay is int &&
      pay >= 0 &&
      pay <= 100 &&
      expires is int &&
      expires >= 0 &&
      (reason == '' || reason == 'sold_out' || reason == 'departed');
}

bool sameSeatMap(Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) {
  if (a.length != b.length) {
    return false;
  }
  for (final key in a.keys) {
    if (a[key] != b[key]) {
      return false;
    }
  }
  return true;
}

/// Expired holds and passed departures. A second call with the same ids adds nothing.
List<SeatLifeEvent> seatSweepEvents({
  required Iterable<SeatLifeSeat> seats,
  required DateTime now,
  required Set<String> existingIds,
  required String actorUid,
}) {
  final actorKey = seatUserKey(actorUid);
  final out = <SeatLifeEvent>[];
  for (final seat in seats) {
    for (final hold in seat.holds) {
      if (hold.expiresAt.isAfter(now)) {
        continue;
      }
      final holderKey = seatUserKey(hold.uid);
      final id = expireEventId(seat.seatId, holderKey, hold.expiresAt);
      if (existingIds.contains(id)) {
        continue;
      }
      out.add(
        SeatLifeEvent(
          id: id,
          kind: 'expire',
          seatId: seat.seatId,
          shopId: seat.shopId,
          productId: seat.productId,
          optionId: seat.optionId,
          region: seat.region,
          resort: seat.resort,
          departure: seat.departureDay,
          price: hold.lockedPrice,
          partySize: hold.seats,
          userKey: holderKey,
          at: now,
        ),
      );
    }
    final departed =
        seat.departure != null && seatDeparturePassed(seat.departure!, now);
    final soldOut = seat.capacity > 0 && seat.booked >= seat.capacity;
    if (!departed && !soldOut) {
      continue;
    }
    final id = closeEventId(seat.seatId);
    if (existingIds.contains(id)) {
      continue;
    }
    out.add(
      SeatLifeEvent(
        id: id,
        kind: 'close',
        seatId: seat.seatId,
        shopId: seat.shopId,
        productId: seat.productId,
        optionId: seat.optionId,
        region: seat.region,
        resort: seat.resort,
        departure: seat.departureDay,
        price: seat.price,
        partySize: seat.booked,
        userKey: actorKey,
        at: now,
        closeReason: departed ? 'departed' : 'sold_out',
      ),
    );
  }
  return out;
}

SeatOutcome summarizeSeat({
  required SeatLifeSeat seat,
  required List<SeatLifeEvent> events,
}) {
  final mine = [
    for (final event in events)
      if (event.seatId == seat.seatId) event,
  ]..sort((a, b) => a.at.compareTo(b.at));
  SeatLifeEvent? open;
  SeatLifeEvent? flag;
  SeatLifeEvent? close;
  var pays = 0;
  var flags = 0;
  var expires = 0;
  for (final event in mine) {
    switch (event.kind) {
      case 'open':
        open ??= event;
      case 'flag':
        flags += 1;
        flag ??= event;
      case 'pay':
        pays += 1;
      case 'expire':
        expires += 1;
      case 'close':
        close ??= event;
    }
  }
  int minutes(DateTime? from, DateTime? to) {
    if (from == null || to == null) {
      return -1;
    }
    return to.difference(from).inMinutes;
  }

  final fill = seat.capacity <= 0
      ? 0
      : (seat.booked * 100 ~/ seat.capacity).clamp(0, 100);
  final payRate = flags == 0 ? 0 : (pays * 100 ~/ flags).clamp(0, 100);
  return SeatOutcome(
    seatId: seat.seatId,
    shopId: seat.shopId,
    openedOn: open == null ? '' : seatDayId(open.at),
    firstFlagMinutes: minutes(open?.at, flag?.at),
    closeMinutes: minutes(open?.at, close?.at),
    fillRate: fill,
    payRate: payRate,
    expireCount: expires,
    closeReason: close?.closeReason ?? '',
  );
}
