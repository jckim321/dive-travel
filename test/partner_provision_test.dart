import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/partner_provision.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/shop_hull_id.dart';

void main() {
  const password = 'wave-pass-1';
  const loginId = 'ocean01';

  test('store provision returns the password and a hull without --', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final store = DiverStore(repo);
    await repo.signIn(email: AppOwner.email, password: 'test');
    await pumpEventQueue();
    final sessionUid = (await repo.currentAuthUser())?.uid;

    final result = await store.provisionPartnerAccount(
      shopName: 'Ocean Dive',
      loginId: loginId,
      password: password,
    );

    expect(result.password, password);
    expect(result.createdAccount, isTrue);
    expect(result.hullId, 'ocean-dive');
    expect(result.hullId.contains('--'), isFalse);
    final member = store.members.firstWhere((item) => item.uid == result.uid);
    expect(member.isBusiness, isTrue);
    expect(member.ownedShopId, 'ocean-dive');
    expect(member.userRole, 'business');
    expect(_storedBlob(repo, member), isNot(contains(password)));
    expect((await repo.currentAuthUser())?.uid, sessionUid);
    expect(sessionUid, isNot(result.uid));
  });

  test('several shops with the same name create no account', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    repo.seedShopName('blue', 'Blue');
    repo.seedShopName('blue-west', 'Blue');
    final before = (await repo.fetchMembers()).length;

    final result = await repo.provisionPartner(
      shopName: 'Blue',
      loginId: loginId,
      password: password,
      actorUid: 'admin',
      actorName: 'Admin',
    );

    expect(result.needsChoice, isTrue);
    expect(result.password, isEmpty);
    expect(repo.partnerAuthCreateCount, 0);
    expect((await repo.fetchMembers()).length, before);
  });

  test('a failed promote resumes the same login without a second auth user', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    repo.debugFailNextPartnerPromote = true;
    await expectLater(
      repo.provisionPartner(
        shopName: 'Ocean Dive',
        loginId: loginId,
        password: password,
        actorUid: 'admin',
        actorName: 'Admin',
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'PROMOTE_FAILED',
        ),
      ),
    );
    expect(repo.partnerAuthCreateCount, 1);

    final again = await repo.provisionPartner(
      shopName: 'Ocean Dive',
      loginId: loginId,
      password: password,
      actorUid: 'admin',
      actorName: 'Admin',
    );

    expect(repo.partnerAuthCreateCount, 1);
    expect(again.createdAccount, isFalse);
    expect(again.password, password);
    expect(again.hullId.contains('--'), isFalse);
    final member = (await repo.fetchMembers()).firstWhere(
      (item) => item.loginId == loginId,
    );
    expect(member.isBusiness, isTrue);
    expect(member.ownedShopId, again.hullId);
    expect(_storedBlob(repo, member), isNot(contains(password)));
  });

  test('a changed primary uid stops before promote', () async {
    var adminUid = 'admin-1';
    var promoted = false;
    await expectLater(
      runPartnerProvision(
        shopName: 'Ocean Dive',
        loginId: loginId,
        password: password,
        actorUid: 'admin-1',
        actorName: 'Admin',
        ensureShop: (_) async => const ShopHullResolve.existing('ocean-dive'),
        findLogin: (_) async => null,
        hullClaimedByOther: (hullId, exceptUid) async => false,
        createDiver: (draft) async {
          expect(draft.password, password);
          adminUid = 'other';
          return const ProvisionedDiver(uid: 'new-diver', createdAuth: true);
        },
        promote: ({
          required uid,
          required hullId,
          required actorUid,
          required actorName,
        }) async {
          promoted = true;
        },
        primaryUid: () => adminUid,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'ADMIN_SESSION_LOST',
        ),
      ),
    );
    expect(promoted, isFalse);
  });
}

String _storedBlob(MemoryDiverRepository repo, MemberAccount member) {
  return '${member.email} ${member.displayName} ${member.loginId} '
      '${member.ownedShopId} ${member.userRole} '
      '${repo.createdShopName(member.ownedShopId)} '
      '${repo.roleHistoryFor(member.uid)}';
}
