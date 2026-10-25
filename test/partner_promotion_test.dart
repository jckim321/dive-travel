import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/partner_promotion.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_proposal_inbox_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_contract_vault_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  final start = DateTime(2026, 10, 1);
  final end = DateTime(2026, 10, 31);

  PartnerPromotion row({
    required String id,
    required String shopId,
    required DateTime createdAt,
    String note = '안내',
  }) {
    return PartnerPromotion(
      id: id,
      shopId: shopId,
      kind: 'early_bird',
      startsOn: start,
      endsOn: end,
      note: note,
      status: PartnerPromotionStatus.incoming,
      createdAt: createdAt,
      createdByUid: 'partner-1',
    );
  }

  test('처리함은 새 제안 수에 들어가지 않는다', () {
    final rows = [
      row(id: 'a', shopId: 'shop-a', createdAt: DateTime.utc(2026, 1, 2)),
      PartnerPromotion(
        id: 'b',
        shopId: 'shop-a',
        kind: 'other',
        startsOn: start,
        endsOn: end,
        note: '끝',
        status: PartnerPromotionStatus.handled,
        createdAt: DateTime.utc(2026, 1, 3),
        createdByUid: 'partner-1',
      ),
    ];
    expect(countIncomingPartnerPromotions(rows), 1);
  });

  test('받은편지함은 샵별 최근 20건을 합쳐 화면에서 정렬한다', () {
    final older = row(
      id: 'old',
      shopId: 'shop-a',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final newer = row(
      id: 'new',
      shopId: 'shop-b',
      createdAt: DateTime.utc(2026, 3, 1),
    );
    final crowded = [
      for (var i = 0; i < 25; i++)
        row(
          id: 'c$i',
          shopId: 'shop-c',
          createdAt: DateTime.utc(2026, 2, 1).add(Duration(days: i)),
        ),
    ];
    final merged = mergePartnerPromotions([
      [older],
      [newer],
      crowded,
    ]);
    expect(merged.first.id, 'new');
    expect(merged.where((item) => item.shopId == 'shop-c'), hasLength(20));
    expect(merged.any((item) => item.id == 'old'), isTrue);
    expect(merged.any((item) => item.id == 'c0'), isFalse);
  });

  test('다른 샵 목록에는 제안이 없고 빈 설명은 저장되지 않는다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    expect(
      () => repo.createPartnerPromotion(
        shopId: 'shop-a',
        partnerUid: 'partner-1',
        kind: 'early_bird',
        startsOn: start,
        endsOn: end,
        note: '   ',
      ),
      throwsA(isA<PartnerPromotionInvalid>()),
    );
    expect(await repo.listPartnerPromotions('shop-a'), isEmpty);

    await repo.createPartnerPromotion(
      shopId: 'shop-a',
      partnerUid: 'partner-1',
      kind: 'price_off',
      startsOn: start,
      endsOn: end,
      note: '주중 할인',
    );
    expect(await repo.listPartnerPromotions('shop-b'), isEmpty);
    expect((await repo.listPartnerPromotions('shop-a')).single.note, '주중 할인');
  });

  test('샵당 최근 20건만 읽고 처리함은 지우지 않는다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    for (var i = 0; i < 21; i++) {
      await repo.createPartnerPromotion(
        shopId: 'shop-a',
        partnerUid: 'partner-1',
        kind: 'other',
        startsOn: start,
        endsOn: end,
        note: '제안 $i',
      );
    }
    final listed = await repo.listPartnerPromotions('shop-a');
    expect(listed, hasLength(20));

    await repo.markPartnerPromotionHandled(
      shopId: 'shop-a',
      proposalId: listed.first.id,
      adminUid: 'admin-1',
    );
    final after = await repo.listPartnerPromotions('shop-a');
    expect(after, hasLength(20));
    expect(
      after.firstWhere((item) => item.id == listed.first.id).status,
      PartnerPromotionStatus.handled,
    );
    expect(
      () => repo.markPartnerPromotionHandled(
        shopId: 'shop-a',
        proposalId: listed.first.id,
        adminUid: 'admin-1',
      ),
      throwsStateError,
    );
  });

  testWidgets('제휴파트너가 제안을 보내면 보냈어요만 남는다', (tester) async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await repo.signIn(email: 'partner@dive.local', password: 'test');
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PartnerContractVaultScreen(shopId: 'bohol-hideout'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('partner-promo-chip')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('partner-promo-form')), findsOneWidget);
    expect(find.byKey(const Key('partner-terms-panel')), findsNothing);
    await tester.enterText(
      find.byKey(const Key('partner-promo-from')),
      '2026-11-01',
    );
    await tester.enterText(
      find.byKey(const Key('partner-promo-until')),
      '2026-11-20',
    );
    await tester.enterText(
      find.byKey(const Key('partner-promo-note')),
      '주말 얼리버드',
    );
    await tester.ensureVisible(find.byKey(const Key('partner-promo-send')));
    await tester.tap(find.byKey(const Key('partner-promo-send')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.partnerPromoSent), findsOneWidget);
    final saved = await repo.listPartnerPromotions('bohol-hideout');
    expect(saved, hasLength(1));
    expect(saved.single.status, PartnerPromotionStatus.incoming);
    expect(saved.single.note, '주말 얼리버드');
    expect(saved.single.kind, 'early_bird');
  });

  testWidgets('받은편지함은 카드만 보여주고 처리함으로 바꿀 수 있다', (tester) async {
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final created = await repo.createPartnerPromotion(
      shopId: 'bohol-hideout',
      partnerUid: 'partner-1',
      kind: 'same_boat',
      startsOn: start,
      endsOn: end,
      note: '같은배 한 줄',
    );
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await repo.signIn(email: AppOwner.email, password: 'test');
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AdminConsoleTheme.dark,
          home: const AdminProposalInboxScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(Key('admin-promo-card-${created.id}')), findsOneWidget);
    expect(find.text('보홀 오션 하이드아웃'), findsOneWidget);
    expect(find.text('같은배 한 줄'), findsOneWidget);
    expect(find.textContaining(l10n.adminPromoNew), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);

    await tester.tap(find.byKey(Key('admin-promo-handle-${created.id}')));
    await tester.pumpAndSettle();

    expect(find.textContaining(l10n.adminPromoHandled), findsOneWidget);
    expect(find.byKey(Key('admin-promo-handle-${created.id}')), findsNothing);
    expect(find.text('같은배 한 줄'), findsOneWidget);
  });
}
