import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/dev/dev_roles.dart';
import 'package:dive_travel_app/core/models/same_boat_seat_open.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

void main() {
  test('DevRoles.canUse is owner-email only', () {
    expect(DevRoles.canUse(AppOwner.email), isTrue);
    expect(DevRoles.canUse('other@example.com'), isFalse);
    expect(DevRoles.canUse(null), isFalse);
  });

  test('grants stay off', () {
    expect(AppConstants.grantAdminToCurrentSession, isFalse);
    expect(AppConstants.grantBusinessToCurrentSession, isFalse);
  });

  test('partner overlay makes effective isAdmin false', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final store = DiverStore(repo);
    await repo.signIn(email: AppOwner.email, password: 'test');
    await pumpEventQueue();

    expect(store.canUseDevRoles, isTrue);
    expect(store.stats.isAdmin, isTrue);

    await store.applyDevRole(
      kind: DevRoleKind.partner,
      ownedShopId: AppConstants.defaultPartnerShopId,
    );
    expect(store.stats.isAdmin, isFalse);
    expect(store.stats.isBusiness, isTrue);
    expect(store.stats.ownedShopId, AppConstants.defaultPartnerShopId);

    await store.applyDevRole(kind: DevRoleKind.admin);
    expect(store.stats.isAdmin, isTrue);
    expect(store.stats.isBusiness, isFalse);
  });

  test('non-owner cannot applyDevRole', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final store = DiverStore(repo);
    await repo.signIn(email: 'guest@example.com', password: 'test');
    await pumpEventQueue();
    expect(store.canUseDevRoles, isFalse);
    expect(
      () => store.applyDevRole(kind: DevRoleKind.diver),
      throwsStateError,
    );
  });

  test('same-boat statusWhenOpen uses effective admin flag', () {
    expect(
      SameBoatSeatOpenLogic.statusWhenOpen(
        isAdmin: false,
        previous: SameBoatStatus.closed,
      ),
      SameBoatStatus.pending,
    );
    expect(
      SameBoatSeatOpenLogic.statusWhenOpen(
        isAdmin: true,
        previous: SameBoatStatus.closed,
      ),
      SameBoatStatus.approved,
    );
  });
}
