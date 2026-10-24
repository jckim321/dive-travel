import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/dev/dev_roles.dart';
import 'package:dive_travel_app/core/models/same_boat_seat_open.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

void main() {
  test('DevRoles.canUse is owner-email only when enabled', () {
    expect(DevRoles.enabled, isTrue);
    expect(DevRoles.canUse(AppOwner.email), isTrue);
    expect(DevRoles.canUse('other@example.com'), isFalse);
    expect(DevRoles.canUse(null), isFalse);
  });

  test('canUseDevRoles is false for non-owner even if repo is admin', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final store = DiverStore(repo);
    await repo.signIn(email: 'guest@example.com', password: 'test');
    await pumpEventQueue();
    expect(store.canUseDevRoles, isFalse);
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

  test('admin→partner overlay publish goes live (not pending)', () async {
    final shopId = AppConstants.defaultPartnerShopId;
    final repo = MemoryDiverRepository.forTest(
      isAdmin: true,
      isBusiness: true,
      ownedShopId: shopId,
    );
    final store = DiverStore(repo);
    await repo.signIn(email: AppOwner.email, password: 'test');
    await pumpEventQueue();
    await store.applyDevRole(kind: DevRoleKind.partner, ownedShopId: shopId);

    final draft = ShopProduct(
      id: 'partner-live-1',
      shopId: shopId,
      name: '즉시 공개 테스트',
      consumerPrice: 120000,
      professionalPrice: 120000,
      active: false,
      publishStatus: ProductPublishStatus.draft,
    );
    await store.saveShopProduct(
      shopId: shopId,
      product: draft,
      intent: ProductSaveIntent.submitForReview,
    );
    final saved = store.productsForShop(shopId).firstWhere((p) => p.id == draft.id);
    expect(saved.publishStatus, ProductPublishStatus.approved);
    expect(saved.active, isTrue);
    expect(saved.isListedPublicly, isTrue);
  });

  test('same-boat statusWhenOpen goes live; legacy pending stays for partner', () {
    expect(
      SameBoatSeatOpenLogic.statusWhenOpen(
        isAdmin: false,
        previous: SameBoatStatus.closed,
      ),
      SameBoatStatus.approved,
    );
    expect(
      SameBoatSeatOpenLogic.statusWhenOpen(
        isAdmin: true,
        previous: SameBoatStatus.closed,
      ),
      SameBoatStatus.approved,
    );
    expect(
      SameBoatSeatOpenLogic.statusWhenOpen(
        isAdmin: false,
        previous: SameBoatStatus.pending,
      ),
      SameBoatStatus.pending,
    );
    expect(
      SameBoatSeatOpenLogic.statusWhenOpen(
        isAdmin: true,
        previous: SameBoatStatus.pending,
      ),
      SameBoatStatus.approved,
    );
  });
}
