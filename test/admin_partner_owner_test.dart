import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/app_user.dart';
import 'package:dive_travel_app/core/models/shop_operating.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_partner_shop_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  test('owner transfer keeps the shop id, reviews, grade, and bookings', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final made = await repo.provisionPartner(
      shopName: '푸른 리프',
      loginId: 'ocean01',
      password: 'password12',
      actorUid: 'test-user',
      actorName: '테스트 다이버',
    );
    final shopId = made.hullId;
    final previousUid = made.uid;
    await repo.saveShopProfile(
      shopId: shopId,
      name: '푸른 리프',
      location: '세부',
      productName: '펀다이빙',
      consumerPrice: 100000,
      professionalPrice: 80000,
    );
    await repo.saveShopProduct(
      shopId: shopId,
      product: ShopProduct(
        id: 'trip',
        shopId: shopId,
        name: '펀다이빙',
        consumerPrice: 100000,
        professionalPrice: 80000,
      ),
    );
    final reviewed = DateTime.utc(2026, 1, 1);
    await repo.setDiveStarGrade(
      shopId: shopId,
      grade: 2,
      reviewedAt: reviewed,
      expiresAt: reviewed.add(const Duration(days: 365)),
    );
    final booking = await repo.createBooking(
      uid: 'guest-1',
      shopId: shopId,
      shopName: '푸른 리프',
      productName: '펀다이빙',
      price: 100000,
    );
    expect(booking, isNotNull);
    await repo.ensureUserDocument(
      const AppUser(
        uid: 'guest-1',
        email: 'guest@dive.local',
        displayName: '게스트',
      ),
      loginId: 'diver02',
    );
    await repo.ensureUserDocument(
      const AppUser(
        uid: 'guest-2',
        email: 'guest2@dive.local',
        displayName: '게스트2',
      ),
      loginId: 'diver03',
    );
    await repo.ensureUserDocument(
      const AppUser(
        uid: 'guest-solo',
        email: 'solo@dive.local',
        displayName: '솔로',
      ),
      loginId: 'solo01',
    );
    final other = await repo.provisionPartner(
      shopName: '다른 리프',
      loginId: 'other01',
      password: 'password12',
      actorUid: 'test-user',
      actorName: '테스트 다이버',
    );
    await repo.saveShopProfile(
      shopId: 'orphan-reef',
      name: '주인 없는 리프',
      location: '세부',
      productName: '',
      consumerPrice: 0,
      professionalPrice: 0,
    );

    final before = (await repo.fetchMembers()).singleWhere(
      (member) => member.uid == previousUid,
    );
    final beforeStats = await repo.fetchShopStat(shopId);
    final beforeBookings = await repo.fetchShopBookings(shopId);

    expect(
      () => repo.transferShopOwner(
        shopId: shopId,
        toUid: 'test-user',
        byUid: 'test-user',
        byName: '테스트 다이버',
      ),
      throwsA(
        isA<StateError>().having(
          (error) => '$error',
          'error',
          contains('OWNER_IS_ADMIN'),
        ),
      ),
    );
    expect(
      () => repo.transferShopOwner(
        shopId: shopId,
        toUid: other.uid,
        byUid: 'test-user',
        byName: '테스트 다이버',
      ),
      throwsA(
        isA<StateError>().having(
          (error) => '$error',
          'error',
          contains('OWNER_HAS_SHOP'),
        ),
      ),
    );
    final firstLink = await repo.transferShopOwner(
      shopId: 'orphan-reef',
      toUid: 'guest-solo',
      byUid: 'test-user',
      byName: '테스트 다이버',
    );
    expect(firstLink.fromUid, isEmpty);
    expect(firstLink.fromOwnerId, '(없음)');
    expect(firstLink.toOwnerId, 'solo01');
    final solo = (await repo.fetchMembers()).singleWhere(
      (member) => member.uid == 'guest-solo',
    );
    expect(solo.isBusiness, isTrue);
    expect(solo.userRole, 'business');
    expect(solo.ownedShopId, 'orphan-reef');
    expect(solo.loginId, 'solo01');
    final orphan = await repo.fetchShopStat('orphan-reef');
    expect(orphan?.shopId, 'orphan-reef');
    expect(orphan?.name, '주인 없는 리프');
    final orphanEvents = await repo.fetchShopOperatingEvents('orphan-reef');
    expect(orphanEvents, hasLength(1));
    expect(orphanEvents.single.kind, 'owner');
    expect(orphanEvents.single.fromOwnerId, '(없음)');
    expect(orphanEvents.single.toOwnerId, 'solo01');
    expect(orphanEvents.single.fromName, isEmpty);
    expect(orphanEvents.single.toName, isEmpty);
    final stillOwner = (await repo.fetchMembers()).singleWhere(
      (member) => member.uid == previousUid,
    );
    expect(stillOwner.isBusiness, isTrue);
    expect(stillOwner.ownedShopId, shopId);

    await repo.transferShopOwner(
      shopId: shopId,
      toUid: 'guest-1',
      byUid: 'test-user',
      byName: '테스트 다이버',
      shopName: '산호 리프',
    );

    final members = await repo.fetchMembers();
    final previous = members.singleWhere((member) => member.uid == previousUid);
    final next = members.singleWhere((member) => member.uid == 'guest-1');
    expect(previous.loginId, before.loginId);
    expect(previous.isBusiness, isFalse);
    expect(previous.ownedShopId, isEmpty);
    expect(previous.userRole, 'diver');
    expect(next.isBusiness, isTrue);
    expect(next.ownedShopId, shopId);
    expect(next.userRole, 'business');
    expect(next.loginId, 'diver02');

    final stats = await repo.fetchShopStat(shopId);
    expect(stats?.shopId, shopId);
    expect(stats?.name, '산호 리프');
    expect(stats?.diveStar, beforeStats?.diveStar);
    expect(stats?.reviewCount, beforeStats?.reviewCount);
    expect(stats?.products.map((item) => item.id), ['trip']);
    final bookings = await repo.fetchShopBookings(shopId);
    expect(bookings.map((item) => item.id), beforeBookings.map((item) => item.id));

    final named = await repo.fetchShopOperatingEvents(shopId);
    expect(named, hasLength(1));
    expect(named.single.kind, 'owner');
    expect(named.single.fromOwnerId, 'ocean01');
    expect(named.single.toOwnerId, 'diver02');
    expect(named.single.fromName, '푸른 리프');
    expect(named.single.toName, '산호 리프');

    await repo.transferShopOwner(
      shopId: shopId,
      toUid: 'guest-2',
      byUid: 'test-user',
      byName: '테스트 다이버',
    );
    final kept = await repo.fetchShopStat(shopId);
    expect(kept?.name, '산호 리프');
    expect(kept?.shopId, shopId);
    final events = await repo.fetchShopOperatingEvents(shopId);
    expect(events, hasLength(2));
    expect(events.first.kind, 'owner');
    expect(events.first.fromOwnerId, 'diver02');
    expect(events.first.toOwnerId, 'diver03');
    expect(events.first.fromName, isEmpty);
    expect(events.first.toName, isEmpty);
    final again = (await repo.fetchMembers()).singleWhere(
      (member) => member.uid == previousUid,
    );
    expect(again.loginId, before.loginId);
    expect(again.isBusiness, isFalse);
  });

  testWidgets('partner detail searches a login id and records the owner change', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final made = await repo.provisionPartner(
      shopName: '푸른 리프',
      loginId: 'ocean01',
      password: 'password12',
      actorUid: 'test-user',
      actorName: '테스트 다이버',
    );
    final shopId = made.hullId;
    await repo.saveShopProfile(
      shopId: shopId,
      name: '푸른 리프',
      location: '세부',
      productName: '펀다이빙',
      consumerPrice: 100000,
      professionalPrice: 80000,
    );
    await repo.ensureUserDocument(
      const AppUser(
        uid: 'guest-1',
        email: 'guest@dive.local',
        displayName: '게스트',
      ),
      loginId: 'Diver02',
    );

    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await store.refreshShopStats();
    await store.ensureAdminInboxLoaded();

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminPartnerShopScreen(shopId: shopId),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final search = find.byKey(const Key('admin-partner-owner-search'));
    await tester.ensureVisible(search);
    await tester.pump();
    await tester.enterText(search, 'diver02');
    await tester.tap(find.byKey(const Key('admin-partner-owner-find')));
    await tester.pump();

    expect(find.byKey(const Key('admin-partner-owner-picked')), findsOneWidget);
    expect(find.text('diver02'), findsWidgets);

    final name = find.byKey(const Key('admin-partner-owner-name'));
    await tester.ensureVisible(name);
    await tester.pump();
    await tester.enterText(name, '산호 리프');
    final save = find.byKey(const Key('admin-partner-owner-save'));
    await tester.ensureVisible(save);
    await tester.pump();
    await tester.tap(save);
    await tester.pump();

    expect(find.text('소유주를 변경할까요?'), findsOneWidget);
    expect(find.textContaining('ocean01'), findsWidgets);
    expect(find.textContaining('diver02'), findsWidgets);
    expect(find.textContaining('푸른 리프 → 산호 리프'), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-partner-owner-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('ocean01 → diver02'), findsOneWidget);
    expect(find.textContaining('푸른 리프 → 산호 리프'), findsWidgets);
    final previous = store.members.singleWhere((member) => member.uid == made.uid);
    final next = store.members.singleWhere((member) => member.uid == 'guest-1');
    expect(previous.isBusiness, isFalse);
    expect(previous.ownedShopId, isEmpty);
    expect(previous.loginId, 'ocean01');
    expect(next.isBusiness, isTrue);
    expect(next.ownedShopId, shopId);
    expect(store.liveStatsFor(shopId)?.name, '산호 리프');
    expect(store.liveStatsFor(shopId)?.shopId, shopId);
  });

  testWidgets('a shop with no owner shows (없음) then the new login id', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.saveShopProfile(
      shopId: 'orphan-reef',
      name: '주인 없는 리프',
      location: '세부',
      productName: '',
      consumerPrice: 0,
      professionalPrice: 0,
    );
    await repo.ensureUserDocument(
      const AppUser(
        uid: 'guest-solo',
        email: 'solo@dive.local',
        displayName: '솔로',
      ),
      loginId: 'solo01',
    );

    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await store.refreshShopStats();
    await store.ensureAdminInboxLoaded();

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AdminPartnerShopScreen(shopId: 'orphan-reef'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final search = find.byKey(const Key('admin-partner-owner-search'));
    await tester.ensureVisible(search);
    await tester.pump();
    await tester.enterText(search, 'solo01');
    await tester.tap(find.byKey(const Key('admin-partner-owner-find')));
    await tester.pump();
    expect(find.byKey(const Key('admin-partner-owner-picked')), findsOneWidget);

    final save = find.byKey(const Key('admin-partner-owner-save'));
    await tester.ensureVisible(save);
    await tester.pump();
    await tester.tap(save);
    await tester.pump();
    expect(find.textContaining('(없음)'), findsWidgets);
    expect(find.textContaining('solo01'), findsWidgets);

    await tester.tap(find.byKey(const Key('admin-partner-owner-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('(없음) → solo01'), findsOneWidget);
    final next = store.members.singleWhere((member) => member.uid == 'guest-solo');
    expect(next.isBusiness, isTrue);
    expect(next.ownedShopId, 'orphan-reef');
    expect(next.userRole, 'business');
    expect(store.liveStatsFor('orphan-reef')?.shopId, 'orphan-reef');
    expect(store.liveStatsFor('orphan-reef')?.name, '주인 없는 리프');
  });
}
