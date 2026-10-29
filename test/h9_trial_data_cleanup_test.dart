import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/trial_data_cleanup.dart';

void main() {
  test('confirm phrase mismatch does not delete', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final store = DiverStore(repo);
    await repo.signIn(email: AppOwner.email, password: 'x');
    await pumpEventQueue();

    expect(
      () => store.runTrialDataDeletion(
        selection: const TrialDeleteSelection(partnerEmailOutbox: true),
        confirmPhrase: 'wrong',
        backupAcknowledged: true,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('jeju orange exact id is protected; ambiguous blocks delete', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    repo.seedShopName('jeju-orange-1', kJejuOrangeShopName);
    final store = DiverStore(repo);
    await repo.signIn(email: AppOwner.email, password: 'x');
    await pumpEventQueue();

    final snap = await store.fetchTrialDataCounts();
    expect(snap.jejuOrange.kind, JejuOrangeResolveKind.exactOne);
    expect(snap.jejuOrange.shopId, 'jeju-orange-1');

    repo.seedShopName('jeju-orange-2', kJejuOrangeShopName);
    final amb = await store.fetchTrialDataCounts();
    expect(amb.jejuOrange.kind, JejuOrangeResolveKind.ambiguous);
    expect(
      () => store.runTrialDataDeletion(
        selection: const TrialDeleteSelection(trialShops: true),
        confirmPhrase: kTrialDeleteConfirmPhrase,
        backupAcknowledged: true,
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      () => store.runTrialDataDeletion(
        selection: const TrialDeleteSelection(
          trialShops: true,
          includeJejuOrange: true,
        ),
        confirmPhrase: kTrialDeleteConfirmPhrase,
        backupAcknowledged: true,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('trial shop delete skips protected jeju orange shop', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    repo.seedShopName('jeju-orange-1', kJejuOrangeShopName);
    repo.seedShopName('trial-shop', '시험 샵');
    final store = DiverStore(repo);
    await repo.signIn(email: AppOwner.email, password: 'x');
    await pumpEventQueue();

    final result = await store.runTrialDataDeletion(
      selection: const TrialDeleteSelection(trialShops: true),
      confirmPhrase: kTrialDeleteConfirmPhrase,
      backupAcknowledged: true,
    );
    expect(result.successCount, greaterThanOrEqualTo(1));
    final after = await store.fetchTrialDataCounts();
    expect(after.jejuOrange.shopId, 'jeju-orange-1');
    expect(repo.roleHistoryFor('x'), isEmpty); // no accidental history
  });

  test('include jeju orange deletes that shop and its partner, not the admin', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    repo.seedShopName('jeju-orange-1', kJejuOrangeShopName);
    repo.seedShopName('trial-shop', '시험 샵');
    final store = DiverStore(repo);
    await repo.signIn(email: AppOwner.email, password: 'x');
    await pumpEventQueue();
    await repo.promoteMemberToPartner(
      uid: 'pending-instructor',
      shopId: 'jeju-orange-1',
      actorUid: store.uid!,
      actorName: 'admin',
    );

    await store.runTrialDataDeletion(
      selection: const TrialDeleteSelection(trialUsers: true),
      confirmPhrase: kTrialDeleteConfirmPhrase,
      backupAcknowledged: true,
    );
    var members = await repo.fetchMembers();
    expect(members.map((m) => m.uid), contains('pending-instructor'));
    expect(members.any((m) => m.email == AppOwner.email), isTrue);
    expect(repo.createdShopName('jeju-orange-1'), kJejuOrangeShopName);

    final result = await store.runTrialDataDeletion(
      selection: const TrialDeleteSelection(
        trialShops: true,
        trialUsers: true,
        includeJejuOrange: true,
      ),
      confirmPhrase: kTrialDeleteConfirmPhrase,
      backupAcknowledged: true,
    );
    members = await repo.fetchMembers();
    expect(members.map((m) => m.uid), isNot(contains('pending-instructor')));
    expect(members.any((m) => m.email == AppOwner.email), isTrue);
    expect(repo.createdShopName('jeju-orange-1'), isNull);
    expect(repo.createdShopName('trial-shop'), isNull);
    expect(result.notes, contains('건너뛴 항목: 없음'));
  });

  test('permission-denied names the collection and the rest still count', () {
    expect(
      trialDeleteCollectionName('shops/reef/daily_stats/2026-10-29'),
      'daily_stats',
    );
    expect(
      trialDeleteCollectionName('shops/reef/partner_contracts/c1/events/e1'),
      'events',
    );
    expect(
      trialDeleteCollectionName('shops/reef/daily_stats'),
      'daily_stats',
    );
    expect(
      trialDeleteDeniedNote('shops/reef/daily_stats/2026-10-29'),
      'permission-denied: daily_stats (shops/reef/daily_stats/2026-10-29)',
    );

    final ledger = TrialDeleteLedger();
    ledger.deleted(2, 'shops/reef/bookings');
    ledger.denied('shops/reef/daily_stats/2026-10-29');
    ledger.denied('shops/reef/contract_terms/current');
    ledger.deleted(1, '샵 삭제 reef');
    ledger.finish();

    expect(ledger.success, 3);
    expect(ledger.failure, 2);
    expect(ledger.skipped, [
      'shops/reef/daily_stats/2026-10-29',
      'shops/reef/contract_terms/current',
    ]);
    expect(
      ledger.notes,
      contains(
        '건너뛴 항목: shops/reef/daily_stats/2026-10-29, shops/reef/contract_terms/current',
      ),
    );
    final result = ledger.toResult();
    expect(result.successCount, 3);
    expect(result.skippedPaths, ledger.skipped);
  });
}
