import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';

void main() {
  test('promote then demote updates flags and history', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final store = DiverStore(repo);
    await repo.signIn(email: AppOwner.email, password: 'test');
    await pumpEventQueue();
    await store.ensureAdminInboxLoaded();

    const targetUid = 'guest-diver';
    await repo.promoteMemberToPartner(
      uid: targetUid,
      shopId: 'temp-shop',
      actorUid: 'admin',
      actorName: 'Admin',
    );
    await repo.demoteMemberFromPartner(
      uid: targetUid,
      actorUid: 'admin',
      actorName: 'Admin',
    );
    await store.refreshAdminInbox();

    await store.promoteMemberToPartner(
      uid: targetUid,
      shopId: AppConstants.defaultPartnerShopId,
    );

    final after = store.members.firstWhere((m) => m.uid == targetUid);
    expect(after.isBusiness, isTrue);
    expect(after.ownedShopId, AppConstants.defaultPartnerShopId);
    expect(after.userRole, 'business');
    expect(repo.roleHistoryFor(targetUid).last['action'], 'promote_partner');

    expect(
      () => store.promoteMemberToPartner(
        uid: targetUid,
        shopId: 'other-shop',
      ),
      throwsA(isA<StateError>()),
    );

    await store.demoteMemberFromPartner(targetUid);
    final demoted = store.members.firstWhere((m) => m.uid == targetUid);
    expect(demoted.isBusiness, isFalse);
    expect(demoted.ownedShopId, isEmpty);
    expect(demoted.userRole, 'diver');
    expect(repo.roleHistoryFor(targetUid).last['action'], 'demote_partner');
  });

  test('admin forTest is not automatically business', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final store = DiverStore(repo);
    await repo.signIn(email: AppOwner.email, password: 'test');
    await pumpEventQueue();
    expect(store.stats.isAdmin, isTrue);
    expect(store.stats.isBusiness, isFalse);
  });
}
