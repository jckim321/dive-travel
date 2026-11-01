import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_products_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/planner_trip_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/profile/presentation/my_crafted_trips_section.dart';
import 'package:dive_travel_app/features/profile/presentation/profile_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    DiverStore store,
    Widget home, {
    SessionController? session,
    Size size = const Size(900, 6400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: session == null
            ? MaterialApp(
                theme: AppTheme.light,
                locale: AppConstants.defaultLocale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: home,
              )
            : SessionScope(
                session: session,
                child: MaterialApp(
                  theme: AppTheme.light,
                  locale: AppConstants.defaultLocale,
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: home,
                ),
              ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('관리자 상품 등록은 기획 여행 화면을 연다', (tester) async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await store.refreshShopStats();
    await pump(tester, store, const AdminProductsScreen());

    await tester.tap(find.byKey(const Key('admin-product-register')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(PlannerTripScreen), findsOneWidget);
    expect(find.byType(TravelProductRegistrationScreen), findsNothing);
  });

  testWidgets('내 기획 목록의 새 여행과 기존 여행은 기획 여행 화면을 연다', (tester) async {
    const trip = ShopProduct(
      id: 'my-whale',
      shopId: 'curated-whale',
      name: '내가 짠 고래',
      consumerPrice: 100000,
      professionalPrice: 80000,
      schedule: '아침 포인트',
      listingKind: ProductListingKind.curated,
    );
    final repo = MemoryDiverRepository.forTest();
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await pump(
      tester,
      store,
      const MyCraftedTripsSection(
        products: [trip],
        memberGrade: MemberGrade.gold,
        viewerUid: 'test-user',
      ),
      size: const Size(900, 800),
    );

    await tester.tap(find.byKey(const Key('craft-new-trip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(PlannerTripScreen), findsOneWidget);
    expect(find.byType(TravelProductRegistrationScreen), findsNothing);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('내가 짠 고래'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final screen = tester.widget<PlannerTripScreen>(find.byType(PlannerTripScreen));
    expect(screen.existing?.id, 'my-whale');
    expect(find.text('아침 포인트'), findsOneWidget);
    expect(find.byType(TravelProductRegistrationScreen), findsNothing);
  });

  testWidgets('골드 회원의 내 화면에서 새 기획 여행을 연다', (tester) async {
    final repo = MemoryDiverRepository.forTest();
    await repo.setMemberGrade(uid: 'test-user', grade: MemberGrade.gold);
    final store = DiverStore(repo);
    final session = SessionController(repo);
    addTearDown(store.dispose);
    addTearDown(session.dispose);
    await tester.pump();
    await tester.pump();
    expect(store.stats.memberGrade, MemberGrade.gold);

    await pump(tester, store, const ProfileScreen(), session: session);
    await tester.scrollUntilVisible(
      find.byKey(const Key('profile-crafted-trips-link')),
      500,
    );
    await tester.tap(find.byKey(const Key('profile-crafted-trips-link')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(PlannerTripScreen), findsOneWidget);
    expect(find.byType(TravelProductRegistrationScreen), findsNothing);
  });
}
