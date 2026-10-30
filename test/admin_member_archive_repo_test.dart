import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/app_user.dart';

void main() {
  const member = 'pending-instructor';
  const actor = 'test-user';

  test('soft delete keeps the name and bookings, then restore clears it', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final shopId = AppConstants.defaultPartnerShopId;
    await repo.createBooking(
      uid: member,
      shopId: shopId,
      shopName: 'Shop',
      productName: 'Pkg',
      price: 1000,
      divers: 1,
    );

    await repo.softDeleteMember(uid: member, actorUid: actor);
    final deleted = (await repo.fetchMembers()).singleWhere((m) => m.uid == member);
    expect(deleted.displayName, '대기 강사');
    expect(deleted.ownedShopId, isEmpty);
    expect(deleted.deletedAt, isNotNull);
    expect(deleted.loginBlocked, isTrue);
    expect(await repo.isLoginBlocked(member), isTrue);
    expect((await repo.fetchShopBookings(shopId)).length, 1);

    await repo.ensureUserDocument(
      const AppUser(
        uid: member,
        email: 'instructor@dive.local',
        displayName: '바뀐이름',
      ),
    );
    expect(
      (await repo.fetchMembers()).singleWhere((m) => m.uid == member).displayName,
      '대기 강사',
    );

    await repo.restoreDeletedMember(member);
    final restored = (await repo.fetchMembers()).singleWhere((m) => m.uid == member);
    expect(restored.deletedAt, isNull);
    expect(restored.displayName, '대기 강사');
    expect(restored.loginBlocked, isFalse);
    expect(await repo.isLoginBlocked(member), isFalse);
    expect((await repo.fetchShopBookings(shopId)).length, 1);
  });

  test('an admin cannot block, withdraw, or delete themselves', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    Future<void> expectSelf(Future<void> call) {
      return expectLater(
        call,
        throwsA(
          predicate((Object e) => e is StateError && e.message == 'ADMIN_SELF'),
        ),
      );
    }

    await expectSelf(
      repo.setAccountBlocked(uid: actor, blocked: true, actorUid: actor),
    );
    await expectSelf(repo.withdrawMember(uid: actor, actorUid: actor));
    await expectSelf(repo.softDeleteMember(uid: actor, actorUid: actor));

    final self = (await repo.fetchMembers()).singleWhere((m) => m.uid == actor);
    expect(self.accountBlocked, isFalse);
    expect(self.withdrawnAt, isNull);
    expect(self.deletedAt, isNull);
    expect(self.displayName, '테스트 다이버');
  });

  test('a linked partner can be blocked but not withdrawn or deleted', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.promoteMemberToPartner(
      uid: member,
      shopId: 'reef-shop',
      actorUid: actor,
      actorName: 'admin',
    );

    Future<void> expectLinked(Future<void> call) {
      return expectLater(
        call,
        throwsA(
          predicate((Object e) => e is StateError && e.message == 'SHOP_LINKED'),
        ),
      );
    }

    await expectLinked(repo.withdrawMember(uid: member, actorUid: actor));
    await expectLinked(repo.softDeleteMember(uid: member, actorUid: actor));
    final kept = (await repo.fetchMembers()).singleWhere((m) => m.uid == member);
    expect(kept.displayName, '대기 강사');
    expect(kept.deletedAt, isNull);
    expect(kept.withdrawnAt, isNull);
    expect(kept.ownedShopId, 'reef-shop');

    await repo.setAccountBlocked(uid: member, blocked: true, actorUid: actor);
    expect(
      (await repo.fetchMembers()).singleWhere((m) => m.uid == member).accountBlocked,
      isTrue,
    );
  });

  test('the store puts a failed delete back', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await pumpEventQueue();
    await store.ensureAdminInboxLoaded();
    await repo.promoteMemberToPartner(
      uid: member,
      shopId: 'reef-shop',
      actorUid: actor,
      actorName: 'admin',
    );
    await store.refreshAdminInbox();

    await expectLater(
      store.softDeleteMember(member),
      throwsA(
        predicate((Object e) => e is StateError && e.message == 'SHOP_LINKED'),
      ),
    );
    final row = store.members.singleWhere((m) => m.uid == member);
    expect(row.deletedAt, isNull);
    expect(row.displayName, '대기 강사');
    expect(row.ownedShopId, 'reef-shop');
  });
}
