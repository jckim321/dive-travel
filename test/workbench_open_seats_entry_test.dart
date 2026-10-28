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

  ShopProduct trip({
    String submittedByUid = 'test-user',
    ProductPublishStatus status = ProductPublishStatus.approved,
  }) {
    return ShopProduct(
      id: 'trip-1',
      shopId: 's1',
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
  }) async {
    final repo = MemoryDiverRepository.forTest();
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
    expect(seatsButton(), findsNothing);
    expect(find.text(hint), findsOneWidget);
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
    expect(find.text(hint), findsOneWidget);
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

  testWidgets('관리자·파트너 게시 구역도 승인 상품은 버튼, 새 상품은 안내', (tester) async {
    final gold = await openStore(tester);
    await pumpForm(
      tester,
      store: gold,
      partnerMode: true,
      existing: trip(),
    );
    await scrollFormToEnd(tester);
    expect(seatsButton(), findsOneWidget);
    expect(tester.widget<FilledButton>(seatsButton()), isA<FilledButton>());
    await openSeats(tester);

    await pumpForm(tester, store: gold, partnerMode: true);
    await scrollFormToEnd(tester);
    expect(seatsButton(), findsNothing);
    expect(tester.widget<Text>(seatsHint()).data, hint);

    await pumpForm(tester, store: gold, existing: trip());
    await scrollFormToEnd(tester);
    expect(seatsButton(), findsOneWidget);

    final silver = await openStore(tester, grade: MemberGrade.silver);
    await pumpForm(
      tester,
      store: silver,
      partnerMode: true,
      existing: trip(),
    );
    await scrollFormToEnd(tester);
    expect(seatsButton(), findsNothing);
    expect(seatsHint(), findsNothing);
  });
}
