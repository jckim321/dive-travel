import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/partner_contract_terms.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_contract_terms_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_contract_vault_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  test('값이 없는 샵은 문서를 만들지 않는다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    expect(await repo.getPartnerContractTerms('jeju-orange'), isNull);
    expect(await repo.listPartnerContractTermRevisions('jeju-orange'), isEmpty);
  });

  test('바뀐 항목이 없으면 조건과 이력을 쓰지 않는다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    expect(
      () => repo.savePartnerContractTerms(
        shopId: 'shop-a',
        next: PartnerContractTerms.empty,
        adminUid: 'admin-1',
        actorName: '운영자',
        changes: const [],
      ),
      throwsA(isA<PartnerContractTermsUnchanged>()),
    );
    expect(await repo.getPartnerContractTerms('shop-a'), isNull);
    expect(await repo.listPartnerContractTermRevisions('shop-a'), isEmpty);
  });

  test('수수료만 바꾸면 이력은 그 한 줄이고 다음 저장은 새 항목만 남긴다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    const first = PartnerContractTerms(commissionRatePercent: 12);
    final firstChanges = diffPartnerContractTerms(
      PartnerContractTerms.empty,
      first,
    );
    expect(firstChanges, hasLength(1));
    expect(firstChanges.single.field, PartnerContractTermFields.commission);
    expect(firstChanges.single.before, isEmpty);
    expect(firstChanges.single.after, '12');

    await repo.savePartnerContractTerms(
      shopId: 'shop-a',
      next: first,
      adminUid: 'admin-1',
      actorName: '운영자',
      changes: firstChanges,
    );
    final saved = await repo.getPartnerContractTerms('shop-a');
    expect(saved?.commissionRatePercent, 12);
    expect(saved?.updatedByUid, 'admin-1');
    final history = await repo.listPartnerContractTermRevisions('shop-a');
    expect(history, hasLength(1));
    expect(history.single.changes, hasLength(1));

    final second = PartnerContractTerms(
      commissionRatePercent: 12,
      partyDiscountPercent: 5,
    );
    final secondChanges = diffPartnerContractTerms(saved!, second);
    expect(
      secondChanges.map((change) => change.field),
      [PartnerContractTermFields.party],
    );
    await repo.savePartnerContractTerms(
      shopId: 'shop-a',
      next: second,
      adminUid: 'admin-1',
      actorName: '운영자',
      changes: secondChanges,
    );
    final later = await repo.listPartnerContractTermRevisions('shop-a');
    expect(later, hasLength(2));
    expect(later.first.changes.single.field, PartnerContractTermFields.party);
    expect(later.first.changes.single.after, '5');
  });

  test('강사 FOC는 한쪽만 적으면 저장 값이 되지 않는다', () {
    expect(
      () => parsePartnerContractTerms(
        commission: '',
        party: '',
        season: '',
        focPay: '10',
        focFree: '',
      ),
      throwsA(isA<PartnerContractTermsInvalid>()),
    );
  });

  testWidgets('제휴파트너 계약 조건은 읽기 전용이고 없으면 미입력이다', (tester) async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final store = DiverStore(repo);
    addTearDown(store.dispose);
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

    expect(find.byKey(const Key('partner-terms-panel')), findsNothing);
    await tester.tap(find.byKey(const Key('partner-terms-chip')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('partner-terms-panel')), findsOneWidget);
    expect(find.byKey(const Key('partner-terms-commission')), findsOneWidget);
    expect(find.text(l10n.adminTermsMissing), findsWidgets);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('관리자는 수수료를 저장하고 같은 값이면 막는다', (tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
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
          home: const AdminContractTermsScreen(
            initialShopId: 'bohol-hideout',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.adminTermsHistoryEmpty), findsOneWidget);
    await tester.enterText(find.byKey(const Key('admin-terms-commission')), '12');
    await tester.ensureVisible(find.byKey(const Key('admin-terms-save')));
    await tester.tap(find.byKey(const Key('admin-terms-save')));
    await tester.pumpAndSettle();

    expect(find.textContaining('수수료율'), findsWidgets);
    expect(find.textContaining('미입력 → 12%'), findsOneWidget);
    final saved = await repo.getPartnerContractTerms('bohol-hideout');
    expect(saved?.commissionRatePercent, 12);
    expect(
      await repo.listPartnerContractTermRevisions('bohol-hideout'),
      hasLength(1),
    );

    await tester.ensureVisible(find.byKey(const Key('admin-terms-save')));
    await tester.tap(find.byKey(const Key('admin-terms-save')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.adminTermsUnchanged), findsOneWidget);
    expect(
      await repo.listPartnerContractTermRevisions('bohol-hideout'),
      hasLength(1),
    );
  });
}
