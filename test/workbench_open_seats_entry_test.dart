import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  const hint = '승인되면 빈자리를 열 수 있어요';
  const creatorHint =
      '승인 요청을 누르면 저장돼요. 관리자 승인 후 마이 > 내 캡틴 카드에서 『빈자리 열기』로 날짜와 인원을 정할 수 있어요.';

  ShopProduct trip({
    String shopId = 's1',
    String submittedByUid = 'test-user',
    ProductPublishStatus status = ProductPublishStatus.approved,
  }) {
    return ShopProduct(
      id: 'trip-1',
      shopId: shopId,
      name: '블루홀',
      consumerPrice: 100000,
      professionalPrice: 80000,
      submittedByUid: submittedByUid,
      publishStatus: status,
      active: true,
    );
  }

  Future<DiverStore> openStore(
    WidgetTester tester, {
    MemberGrade grade = MemberGrade.gold,
    bool isAdmin = false,
    String? ownedShopId,
  }) async {
    final repo = MemoryDiverRepository.forTest(
      isAdmin: isAdmin,
      isBusiness: ownedShopId != null && ownedShopId.isNotEmpty,
      ownedShopId: ownedShopId,
    );
    if (grade != MemberGrade.silver) {
      await repo.setMemberGrade(uid: 'test-user', grade: grade);
      await repo.clearGradeCelebration('test-user');
    }
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await store.refreshShopStats();
    await tester.pump();
    expect(store.uid, 'test-user');
    expect(store.stats.memberGrade, grade);
    expect(store.stats.isAdmin, isAdmin);
    if (ownedShopId != null) {
      expect(store.stats.ownedShopId, ownedShopId);
    }
    return store;
  }

  Future<void> pumpForm(
    WidgetTester tester, {
    required DiverStore store,
    ShopProduct? existing,
    bool creatorMode = false,
    bool partnerMode = false,
  }) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TravelProductRegistrationScreen(
            key: UniqueKey(),
            creatorMode: creatorMode,
            partnerMode: partnerMode,
            existing: existing,
            startEditing: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> toStep5(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const Key('creator-wizard-next')));
      await tester.pump();
    }
    expect(find.byKey(const Key('creator-wizard-step-5')), findsOneWidget);
  }

  Finder seatsButton() => find.byKey(
        const Key('workbench-open-seats'),
        skipOffstage: false,
      );

  Finder seatsHint() => find.byKey(
        const Key('workbench-open-seats-hint'),
        skipOffstage: false,
      );

  Future<void> scrollFormToEnd(WidgetTester tester) async {
    final controller = tester
        .widget<ListView>(find.byKey(const Key('partner-product-form-scroll')))
        .controller!;
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    if (controller.position.pixels < controller.position.maxScrollExtent) {
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();
    }
  }

  Future<void> openSeats(WidgetTester tester) async {
    final button = seatsButton();
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SameBoatSeatsScreen), findsOneWidget);
  }

  testWidgets('골드 새 상품은 5단계에서 안내만 보인다', (tester) async {
    final store = await openStore(tester);
    await pumpForm(tester, store: store, creatorMode: true);
    expect(seatsButton(), findsNothing);
    expect(seatsHint(), findsNothing);

    await toStep5(tester);
    expect(find.byKey(const Key('creator-wizard-next')), findsNothing);
    expect(find.byKey(const Key('creator-wizard-prev')), findsOneWidget);
    expect(find.text('승인 요청'), findsOneWidget);
    expect(seatsButton(), findsNothing);
    expect(find.text(creatorHint), findsOneWidget);
    expect(find.byKey(const Key('creator-wizard-preview')), findsOneWidget);
  });

  testWidgets('골드 본인 승인 상품은 5단계 채운 버튼으로 빈자리 창을 연다', (tester) async {
    final store = await openStore(tester);
    await pumpForm(
      tester,
      store: store,
      creatorMode: true,
      existing: trip(),
    );
    expect(seatsButton(), findsNothing);

    await toStep5(tester);
    final button = seatsButton();
    expect(button, findsOneWidget);
    expect(tester.widget<FilledButton>(button).child, isA<Text>());
    expect(find.text('빈자리 열기'), findsOneWidget);
    expect(seatsHint(), findsNothing);
    await openSeats(tester);
  });

  testWidgets('골드 승인 대기는 안내만 보인다', (tester) async {
    final store = await openStore(tester);
    await pumpForm(
      tester,
      store: store,
      creatorMode: true,
      existing: trip(status: ProductPublishStatus.pending),
    );
    await toStep5(tester);
    expect(seatsButton(), findsNothing);
    expect(find.text(creatorHint), findsOneWidget);
  });

  testWidgets('실버와 남의 여행은 5단계에도 입구가 없다', (tester) async {
    final silver = await openStore(tester, grade: MemberGrade.silver);
    await pumpForm(
      tester,
      store: silver,
      creatorMode: true,
      existing: trip(),
    );
    await toStep5(tester);
    expect(seatsButton(), findsNothing);
    expect(seatsHint(), findsNothing);

    final gold = await openStore(tester);
    await pumpForm(
      tester,
      store: gold,
      creatorMode: true,
      existing: trip(submittedByUid: 'other'),
    );
    await toStep5(tester);
    expect(seatsButton(), findsNothing);
    expect(seatsHint(), findsNothing);
  });

  testWidgets('파트너는 자기 샵 승인 상품만 버튼, 새 상품은 안내', (tester) async {
    final partner = await openStore(
      tester,
      grade: MemberGrade.silver,
      ownedShopId: 's1',
    );
    await pumpForm(
      tester,
      store: partner,
      partnerMode: true,
      existing: trip(),
    );
    await scrollFormToEnd(tester);
    expect(seatsButton(), findsOneWidget);
    expect(tester.widget<FilledButton>(seatsButton()), isA<FilledButton>());
    await openSeats(tester);

    await pumpForm(
      tester,
      store: partner,
      partnerMode: true,
      existing: trip(status: ProductPublishStatus.pending),
    );
    await scrollFormToEnd(tester);
    expect(seatsButton(), findsNothing);
    expect(tester.widget<Text>(seatsHint()).data, hint);

    await pumpForm(tester, store: partner, partnerMode: true);
    await scrollFormToEnd(tester);
    expect(seatsButton(), findsNothing);
    expect(seatsHint(), findsOneWidget);
  });

  testWidgets('관리자는 모든 승인 상품에 버튼이 보이고 승인 대기는 안내', (tester) async {
    final admin = await openStore(
      tester,
      grade: MemberGrade.silver,
      isAdmin: true,
    );
    await pumpForm(
      tester,
      store: admin,
      existing: trip(shopId: 'any-shop', submittedByUid: 'someone'),
    );
    await scrollFormToEnd(tester);
    expect(seatsButton(), findsOneWidget);

    await pumpForm(
      tester,
      store: admin,
      existing: trip(
        shopId: 'any-shop',
        status: ProductPublishStatus.pending,
      ),
    );
    await scrollFormToEnd(tester);
    expect(seatsButton(), findsNothing);
    expect(seatsHint(), findsOneWidget);
  });

  testWidgets('파트너는 남의 샵 상품에서 빈자리 입구가 숨는다', (tester) async {
    final partner = await openStore(
      tester,
      grade: MemberGrade.silver,
      ownedShopId: 'my-shop',
    );
    await pumpForm(
      tester,
      store: partner,
      partnerMode: true,
      existing: trip(shopId: 'other-shop'),
    );
    await scrollFormToEnd(tester);
    expect(seatsButton(), findsNothing);
    expect(seatsHint(), findsNothing);
  });
}
