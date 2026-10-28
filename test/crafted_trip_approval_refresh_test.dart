import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/profile/presentation/profile_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const uid = 'test-user';
  const shopId = 'curated-mine';
  const productId = 'trip-1';

  Future<({MemoryDiverRepository repo, DiverStore store, SessionController session})>
  loadPending(WidgetTester tester) async {
    final repo = MemoryDiverRepository.forTest();
    await repo.setMemberGrade(uid: uid, grade: MemberGrade.gold);
    await repo.clearGradeCelebration(uid);
    await repo.saveShopProduct(
      shopId: shopId,
      product: const ShopProduct(
        id: productId,
        shopId: shopId,
        name: '블루홀',
        consumerPrice: 100000,
        professionalPrice: 80000,
        submittedByUid: uid,
        publishStatus: ProductPublishStatus.pending,
        active: false,
      ),
    );
    final store = DiverStore(repo);
    final session = SessionController(repo);
    addTearDown(store.dispose);
    addTearDown(session.dispose);
    await store.refreshShopStats();
    await tester.pump();
    expect(store.uid, uid);
    expect(store.stats.memberGrade, MemberGrade.gold);
    expect(
      store.craftedProductsFor(uid).single.publishStatus,
      ProductPublishStatus.pending,
    );
    return (repo: repo, store: store, session: session);
  }

  Future<void> pumpProfile(
    WidgetTester tester, {
    required DiverStore store,
    required SessionController session,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: SessionScope(
          session: session,
          child: const MaterialApp(
            locale: Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProfileScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('마이를 열면 승인된 여행의 빈자리 버튼이 보인다', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    final loaded = await loadPending(tester);
    await loaded.repo.setShopProductPublishStatus(
      shopId: shopId,
      productId: productId,
      status: ProductPublishStatus.approved,
    );
    expect(
      loaded.store.craftedProductsFor(uid).single.publishStatus,
      ProductPublishStatus.pending,
    );

    await pumpProfile(
      tester,
      store: loaded.store,
      session: loaded.session,
    );

    expect(find.byKey(Key('crafted-open-seats-$productId')), findsOneWidget);
    expect(
      tester.widget(find.byKey(Key('crafted-open-seats-$productId'))),
      isA<FilledButton>(),
    );
    expect(find.text(l10n.profileCraftedTripsTitle), findsOneWidget);
    expect(find.text(l10n.profileCraftStatusPending), findsNothing);
    expect(find.text(l10n.profileCraftStatusLive), findsOneWidget);
    expect(
      loaded.store.craftedProductsFor(uid).single.publishStatus,
      ProductPublishStatus.approved,
    );
  });

  testWidgets('당겨서 새로고침하면 승인 상태가 갱신된다', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    final loaded = await loadPending(tester);
    await pumpProfile(
      tester,
      store: loaded.store,
      session: loaded.session,
    );
    expect(find.byKey(Key('crafted-open-seats-$productId')), findsNothing);
    expect(find.text(l10n.profileCraftStatusPending), findsOneWidget);

    await loaded.repo.setShopProductPublishStatus(
      shopId: shopId,
      productId: productId,
      status: ProductPublishStatus.approved,
    );
    expect(
      loaded.store.craftedProductsFor(uid).single.publishStatus,
      ProductPublishStatus.pending,
    );

    await tester.fling(
      find.byKey(const Key('profile-departure-desk')),
      const Offset(0, 400),
      1200,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(Key('crafted-open-seats-$productId')), findsOneWidget);
    expect(find.text(l10n.profileCraftStatusPending), findsNothing);
    expect(
      loaded.store.craftedProductsFor(uid).single.publishStatus,
      ProductPublishStatus.approved,
    );
  });
}
