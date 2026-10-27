import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/core/auth/device_pin_store.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/partner_meeting_report.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_partner_meeting_preview.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_dashboard_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_meeting_inbox_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_meeting_read_store.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('파트너 받은 보고서는 shared와 샵 앞부분으로만 고르고 종이는 읽기 전용이다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(
      isBusiness: true,
      ownedShopId: 'palau-dive--fundive',
    );
    await repo.saveMeetingReport(_stored('mr_palau', 'palau-dive'));
    await repo.saveMeetingReport(_stored('mr_draft', 'palau-dive'));
    await repo.saveMeetingReport(_stored('mr_cebu', 'cebu-dive'));
    await repo.setMeetingReportShared(id: 'mr_palau', shared: true);
    await repo.setMeetingReportShared(id: 'mr_cebu', shared: true);
    final store = DiverStore(repo);
    addTearDown(store.dispose);

    await tester.pumpWidget(
      _home(store, MemoryPartnerMeetingReadStore()),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('partner-meeting-inbox')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(repo.debugMeetingReportQueries, isNotEmpty);
    expect(
      repo.debugMeetingReportQueries.every(
        (query) => query.shared && query.shopId == 'palau-dive',
      ),
      isTrue,
    );
    expect(
      find.byKey(const Key('partner-meeting-inbox-row-mr_palau')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('partner-meeting-inbox-row-mr_draft')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('partner-meeting-inbox-row-mr_cebu')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('partner-meeting-inbox-row-mr_palau')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('partner-meeting-paper')), findsOneWidget);
    expect(find.byKey(const Key('partner-meeting-save')), findsNothing);
    expect(find.byKey(const Key('partner-meeting-send')), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('partner-meeting-print')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('비로그인 링크는 볼 수 없어요 한 줄이다', (tester) async {
    final repo = MemoryDiverRepository.forTest();
    await repo.signOut();
    await tester.pumpWidget(
      DiveTravelApp(
        firebaseReady: true,
        repository: repo,
        devicePinStore: _EmptyPinStore(),
        initialReportId: 'mr_palau',
      ),
    );
    await _until(tester, find.byKey(const Key('partner-meeting-link-denied')));
    expect(find.text('이 보고서를 볼 수 없어요'), findsOneWidget);
    expect(find.byKey(const Key('partner-meeting-paper')), findsNothing);
  });

  testWidgets('다른 샵이거나 미발송이면 링크는 열리지 않는다', (tester) async {
    final repo = MemoryDiverRepository.forTest(
      isBusiness: true,
      ownedShopId: 'cebu-dive',
    );
    await repo.saveMeetingReport(_stored('mr_palau', 'palau-dive'));
    await repo.setMeetingReportShared(id: 'mr_palau', shared: true);
    await tester.pumpWidget(
      DiveTravelApp(
        firebaseReady: true,
        repository: repo,
        devicePinStore: _EmptyPinStore(),
        initialReportId: 'mr_palau',
      ),
    );
    await _until(tester, find.byKey(const Key('partner-meeting-link-denied')));
    expect(find.byKey(const Key('partner-meeting-paper')), findsNothing);

    final owner = MemoryDiverRepository.forTest(
      isBusiness: true,
      ownedShopId: 'palau-dive--fundive',
    );
    await owner.saveMeetingReport(_stored('mr_draft', 'palau-dive'));
    await tester.pumpWidget(
      DiveTravelApp(
        firebaseReady: true,
        repository: owner,
        devicePinStore: _EmptyPinStore(),
        initialReportId: 'mr_draft',
      ),
    );
    await _until(tester, find.byKey(const Key('partner-meeting-link-denied')));
    expect(find.byKey(const Key('partner-meeting-paper')), findsNothing);
  });

  testWidgets('자기 샵의 보낸 보고서는 링크로 열린다', (tester) async {
    final repo = MemoryDiverRepository.forTest(
      isBusiness: true,
      ownedShopId: 'palau-dive--fundive',
    );
    await repo.saveMeetingReport(_stored('mr_palau', 'palau-dive'));
    await repo.setMeetingReportShared(id: 'mr_palau', shared: true);
    await tester.pumpWidget(
      DiveTravelApp(
        firebaseReady: true,
        repository: repo,
        devicePinStore: _EmptyPinStore(),
        initialReportId: 'mr_palau',
      ),
    );
    await _until(tester, find.byKey(const Key('partner-meeting-paper')));
    final preview = tester.widget<AdminPartnerMeetingPreview>(
      find.byType(AdminPartnerMeetingPreview),
    );
    expect(preview.readOnly, isTrue);
    expect(preview.report.id, 'mr_palau');
    expect(preview.report.shared, isTrue);
    expect(find.byKey(const Key('partner-meeting-link-denied')), findsNothing);
    expect(find.byKey(const Key('partner-meeting-save')), findsNothing);
  });

  test('열어 본 보고서 id는 기기에 남는다', () async {
    SharedPreferences.setMockInitialValues(const {});
    final store = PrefsPartnerMeetingReadStore();
    expect(await store.readIds(), isEmpty);
    await store.markRead('mr_palau');
    await store.markRead('  ');
    expect(await store.readIds(), {'mr_palau'});
    expect(await PrefsPartnerMeetingReadStore().readIds(), {'mr_palau'});
  });

  testWidgets('안 읽은 보고서가 있으면 받은 보고서 버튼이 청록으로 채워진다', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(
      isBusiness: true,
      ownedShopId: 'palau-dive--fundive',
    );
    await repo.saveMeetingReport(_stored('mr_palau', 'palau-dive'));
    await repo.saveMeetingReport(_stored('mr_next', 'palau-dive'));
    await repo.saveMeetingReport(_stored('mr_draft', 'palau-dive'));
    await repo.setMeetingReportShared(id: 'mr_palau', shared: true);
    await repo.setMeetingReportShared(id: 'mr_next', shared: true);
    final reads = MemoryPartnerMeetingReadStore();
    final store = DiverStore(repo);
    addTearDown(store.dispose);

    await tester.pumpWidget(_home(store, reads));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('새 보고서 2'), findsOneWidget);
    expect(find.byKey(const Key('partner-meeting-inbox-dot')), findsOneWidget);
    final filled = tester.widget<FilledButton>(
      find.byKey(const Key('partner-meeting-inbox')),
    );
    expect(
      filled.style?.backgroundColor?.resolve(const <WidgetState>{}),
      PartnerTheme.accent,
    );
    final before = tester
        .widget<FadeTransition>(find.byKey(const Key('partner-meeting-inbox-dot')))
        .opacity
        .value;
    await tester.pump(const Duration(milliseconds: 350));
    final after = tester
        .widget<FadeTransition>(find.byKey(const Key('partner-meeting-inbox-dot')))
        .opacity
        .value;
    expect(before, isNot(after));

    await tester.tap(find.byKey(const Key('partner-meeting-inbox')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('partner-meeting-inbox-row-mr_palau')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(reads.ids, {'mr_palau'});

    Navigator.of(
      tester.element(find.byType(AdminPartnerMeetingPreview)),
    ).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    Navigator.of(
      tester.element(find.byType(PartnerMeetingInboxScreen)),
    ).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('새 보고서 1'), findsOneWidget);
    expect(
      tester.widget(find.byKey(const Key('partner-meeting-inbox'))),
      isA<FilledButton>(),
    );

    await tester.tap(find.byKey(const Key('partner-meeting-inbox')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('partner-meeting-inbox-row-mr_next')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    Navigator.of(
      tester.element(find.byType(AdminPartnerMeetingPreview)),
    ).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    Navigator.of(
      tester.element(find.byType(PartnerMeetingInboxScreen)),
    ).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('새 보고서 1'), findsNothing);
    expect(find.byKey(const Key('partner-meeting-inbox-dot')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('partner-meeting-inbox')),
        matching: find.text('받은 보고서'),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget(find.byKey(const Key('partner-meeting-inbox'))),
      isA<OutlinedButton>(),
    );
  });

  testWidgets('받은 보고서가 없으면 버튼은 테두리만 있다', (tester) async {
    final repo = MemoryDiverRepository.forTest(
      isBusiness: true,
      ownedShopId: 'palau-dive',
    );
    await repo.saveMeetingReport(_stored('mr_draft', 'palau-dive'));
    final store = DiverStore(repo);
    addTearDown(store.dispose);

    await tester.pumpWidget(_home(store, MemoryPartnerMeetingReadStore()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('새 보고서'), findsNothing);
    expect(
      tester.widget(find.byKey(const Key('partner-meeting-inbox'))),
      isA<OutlinedButton>(),
    );
  });
}

Widget _home(DiverStore store, PartnerMeetingReadStore reads) {
  return DiverStoreScope(
    store: store,
    child: MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PartnerDashboardScreen(readStore: reads),
    ),
  );
}

class _EmptyPinStore implements DevicePinStore {
  @override
  Future<void> clear() async {}

  @override
  Future<DevicePinRecord?> read() async => null;

  @override
  Future<void> write(DevicePinRecord record) async {}
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40; i++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

PartnerMeetingReport _stored(String id, String shopId) {
  return buildPartnerMeetingReport(
    id: id,
    recipe: MeetingReportRecipe(
      shopId: shopId,
      periodStart: DateTime(2026, 10, 21),
      periodEnd: DateTime(2026, 10, 27),
    ),
    events: const [],
    demands: const [],
    seats: const [],
    createdAt: DateTime(2026, 10, 27, 15),
  );
}
