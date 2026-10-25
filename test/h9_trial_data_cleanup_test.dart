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
}
