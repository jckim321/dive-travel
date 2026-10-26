import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/seat_life.dart';

void main() {
  test('views stay buffered until leave or 30 seconds', () {
    final buffer = SeatViewBuffer();
    final start = DateTime.utc(2026, 10, 27, 1);
    final event = _view();
    for (var i = 0; i < 5; i++) {
      buffer.watch(event, start.add(Duration(seconds: i)));
    }
    expect(buffer.poll(start.add(const Duration(seconds: 10))), isEmpty);
    expect(
      buffer.poll(start.add(const Duration(seconds: 29))),
      isEmpty,
    );

    final left = buffer.poll(
      start.add(const Duration(seconds: 20)),
      leaving: true,
    );
    expect(left, hasLength(1));
    expect(left.single.kind, 'view');
    expect(left.single.id, startsWith('view_'));
    expect(
      buffer.poll(start.add(const Duration(seconds: 21)), leaving: true),
      isEmpty,
    );

    final again = SeatViewBuffer();
    again.watch(event, start);
    expect(again.poll(start.add(const Duration(seconds: 30))), hasLength(1));
    expect(again.poll(start.add(const Duration(seconds: 31))), isEmpty);
    expect(again.poll(start.add(const Duration(seconds: 60))), hasLength(1));
  });

  test('record keeps a member hash and nationality only with consent', () {
    final key = seatUserKey('member-7');
    expect(key, hasLength(64));
    expect(key, isNot(contains('member-7')));

    final hidden = _view(shareNationality: false);
    final shown = _view();
    expect(hidden.toStoredMap().containsKey('nationality'), isFalse);
    expect(shown.toStoredMap()['nationality'], 'KR');
    expect(shown.toStoredMap()['user_key'], key);
    for (final field in seatLifeForbiddenKeys) {
      expect(shown.toStoredMap().containsKey(field), isFalse);
      expect(hidden.toStoredMap().containsKey(field), isFalse);
    }
    expect(
      seatEventShapeAllowed({...shown.toStoredMap(), 'email': 'a@b.c'}),
      isFalse,
    );
  });

  test('day counters allow +1 and reject a decrease or a jump', () {
    final created = seatDayCreate('views');
    expect(seatDayCreateAllowed(created), isTrue);
    final plus = Map<String, int>.from(created)..['views'] = 2;
    expect(seatDayPlusOneAllowed(created, plus), isTrue);
    final down = Map<String, int>.from(plus)..['views'] = 1;
    expect(seatDayPlusOneAllowed(plus, down), isFalse);
    final jump = Map<String, int>.from(created)..['views'] = 3;
    expect(seatDayPlusOneAllowed(created, jump), isFalse);
    final extra = Map<String, int>.from(created);
    expect(seatDayPlusOneAllowed(created, {...extra, 'email': 1}), isFalse);
  });

  test('admin sweep records expiry and departure once', () async {
    final now = DateTime(2026, 10, 27, 9);
    final seat = SeatLifeSeat(
      productId: 'prod',
      optionId: '',
      shopId: 'shop',
      region: 'PH',
      resort: 'Reef',
      departure: DateTime(2026, 10, 26),
      price: 200000,
      capacity: 4,
      booked: 2,
      holds: [
        SeatLifeHold(
          uid: 'member-7',
          seats: 1,
          expiresAt: now.subtract(const Duration(hours: 2)),
          lockedPrice: 100000,
        ),
      ],
    );
    final first = seatSweepEvents(
      seats: [seat],
      now: now,
      existingIds: const {},
      actorUid: 'admin-1',
    );
    expect(first.map((event) => event.kind).toSet(), {'expire', 'close'});
    expect(first.every((event) => event.withinShape), isTrue);
    expect(
      first.every((event) => !event.toStoredMap().containsKey('email')),
      isTrue,
    );

    final repo = MemoryDiverRepository.forTest();
    for (final event in first) {
      expect(await repo.createSeatEvent(event), isTrue);
      expect(await repo.createSeatEvent(event), isFalse);
      final field = seatDayField(event.kind);
      expect(await repo.bumpSeatDay(dayId: seatDayId(event.at), field: field!), isTrue);
    }
    final ids = {for (final event in await repo.listSeatEvents()) event.id};
    final second = seatSweepEvents(
      seats: [seat],
      now: now,
      existingIds: ids,
      actorUid: 'admin-1',
    );
    expect(second, isEmpty);

    final events = await repo.listSeatEvents();
    final line = summarizeSeat(seat: seat, events: events);
    final again = summarizeSeat(seat: seat, events: events);
    expect(line.toMap(), again.toMap());
    expect(line.expireCount, 1);
    expect(line.closeReason, 'departed');
    expect(line.fillRate, 50);
    await repo.saveSeatOutcome(line);
    await repo.saveSeatOutcome(again);
    expect(repo.debugSeatOutcomeWrites, 1);
    expect(repo.debugSeatDay(seatDayId(now))!['expires'], 1);
    expect(repo.debugSeatDay(seatDayId(now))!['closes'], 1);
  });

  test('rest fields keep numbers and times as Firestore types', () {
    final fields = seatRestFields({
      'views': 1,
      'kind': 'view',
      'at': DateTime.utc(2026, 10, 27, 1),
    });
    expect(fields['views'], {'integerValue': '1'});
    expect(fields['kind'], {'stringValue': 'view'});
    expect(
      fields['at'],
      {'timestampValue': '2026-10-27T01:00:00.000Z'},
    );
  });
}

SeatLifeEvent _view({bool shareNationality = true}) {
  return SeatLifeEvent(
    id: 'pending',
    kind: 'view',
    seatId: seatLifeId('prod', ''),
    shopId: 'shop',
    productId: 'prod',
    region: 'PH',
    resort: 'Reef',
    departure: '2026-11-01',
    price: 1000,
    partySize: 0,
    memberGrade: 'gold',
    nationality: 'KR',
    shareNationality: shareNationality,
    userKey: seatUserKey('member-7'),
    at: DateTime.utc(2026, 10, 27, 1),
  );
}
