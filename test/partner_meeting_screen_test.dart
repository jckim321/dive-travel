import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/partner_meeting_report.dart';
import 'package:dive_travel_app/core/models/seat_life.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_partner_meeting_pdf.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_partner_meeting_preview.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_partner_meeting_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_same_boat_brief_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('미리보기는 고른 샵의 숫자만 종이에 담고 보내기는 아직 막혀 있다', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.saveShopProfile(
      shopId: 'palau-dive',
      name: '팔라우 다이브센터',
      location: '팔라우',
      productName: '펀다이빙',
      consumerPrice: 180000,
      professionalPrice: 120000,
      country: '팔라우',
    );
    await repo.saveShopProduct(
      shopId: 'palau-dive',
      product: const ShopProduct(
        id: 'palau-live',
        shopId: 'palau-dive',
        name: '펀다이빙',
        continent: 'palau',
        consumerPrice: 180000,
        professionalPrice: 120000,
        capacity: 10,
        bookedSeats: 8,
      ),
    );
    await repo.createSeatEvent(
      _event('palau-view', 'palau-dive', DateTime(2026, 10, 22, 11)),
    );
    await repo.createSeatEvent(
      _event('cebu-view', 'cebu-dive', DateTime(2026, 10, 22, 12)),
    );
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    final printed = Completer<List<int>>();

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminSameBoatBriefScreen(
            now: DateTime(2026, 10, 27, 15),
            onMeetingPrint: (bytes) {
              printed.complete(bytes);
              return Future<void>.value();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const Key('admin-partner-meeting-open')),
              matching: find.byType(Text),
            ),
          )
          .data,
      '미팅 보고서 만들기',
    );
    await tester.tap(find.byKey(const Key('admin-partner-meeting-open')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('파트너 미팅 보고서'), findsWidgets);
    expect(find.text('조건을 고르면 보고서를 만들어 드려요'), findsOneWidget);
    expect(find.text('2026.10.21 ~ 10.27'), findsWidgets);
    await tester.tap(find.byKey(const Key('partner-meeting-shop')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('팔라우 다이브센터').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('전체 (상품 1개)'), findsOneWidget);
    expect(find.text('한 줄 결론'), findsOneWidget);
    expect(find.text('누가 찾나요'), findsNothing);
    expect(find.text('월간 요약'), findsNothing);
    expect(find.text('새 자리 제안'), findsNothing);

    await tester.tap(
      find.byKey(const Key('partner-meeting-section-conclusion')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('partner-meeting-section-proposals')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('partner-meeting-preset-30')));
    await tester.pump();
    expect(find.text('2026.09.28 ~ 10.27'), findsOneWidget);
    await tester.tap(find.byKey(const Key('partner-meeting-preset-7')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('partner-meeting-preview')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.byKey(const Key('partner-meeting-paper')), findsOneWidget);
    expect(find.text('같은배 빈자리 운영 리포트'), findsOneWidget);
    expect(find.text('다이브트래블 × 팔라우 다이브센터 · 미팅 자료'), findsOneWidget);
    expect(find.byKey(const Key('partner-meeting-conclusion')), findsNothing);
    expect(find.byKey(const Key('partner-meeting-proposals')), findsNothing);
    expect(find.byKey(const Key('partner-meeting-funnel')), findsOneWidget);
    expect(find.byKey(const Key('partner-meeting-score-empty')), findsNothing);
    expect(_text(tester, 'partner-meeting-views'), '1');
    expect(find.text('채움 80%'), findsWidgets);
    expect(find.text('국적비밀'), findsNothing);
    expect(find.textContaining('cebu'), findsNothing);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('partner-meeting-save')))
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('partner-meeting-send')))
          .onPressed,
      isNull,
    );
    expect(repo.debugSeatEventQueries, isNotEmpty);
    expect(repo.debugSeatEventQueries.first.$1, DateTime(2026, 10, 21));
    expect(repo.debugSeatEventQueries.first.$2, DateTime(2026, 10, 28));

    await tester.ensureVisible(find.byKey(const Key('partner-meeting-print')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('partner-meeting-print')));
    await tester.runAsync(
      () => printed.future.timeout(const Duration(seconds: 5)),
    );
    final bytes = await printed.future;
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
  });

  test('PDF는 A4에 NotoSansKR과 한글을 담는다', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    final now = DateTime(2026, 10, 27, 15);
    final report = buildPartnerMeetingReport(
      id: 'preview',
      recipe: MeetingReportRecipe(
        shopId: 'palau-dive',
        productIds: const ['palau-live'],
        regionId: 'palau',
        periodStart: DateTime(2026, 10, 21),
        periodEnd: DateTime(2026, 10, 27),
        compare: false,
      ),
      events: [
        _event('palau-view', 'palau-dive', DateTime(2026, 10, 22, 11)),
        _event('cebu-view', 'cebu-dive', DateTime(2026, 10, 22, 12)),
      ],
      demands: const [],
      seats: const [
        MeetingReportSeat(
          shopId: 'palau-dive',
          productId: 'palau-live',
          productName: '펀다이빙',
          regionId: 'palau',
          booked: 8,
          capacity: 10,
        ),
      ],
      createdAt: now,
    );
    final bytes = await buildPartnerMeetingPdf(
      report: report,
      shopName: '팔라우 다이브센터',
      periodLabel: '2026.10.21 ~ 10.27',
      l10n: l10n,
    );
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    final latin = latin1.decode(bytes, allowInvalid: true);
    final text = '$latin${_inflateStreams(bytes)}';
    expect(
      text.contains('NotoSansKR') || text.contains('Noto Sans KR'),
      isTrue,
    );
    expect(text.contains('595'), isTrue);
    expect(text.contains('841'), isTrue);
    expect(text.contains('cebu-dive'), isFalse);
    expect(text.contains('국적비밀'), isFalse);
    expect(text.contains('<D314>'), isTrue);
  });

  testWidgets('성적표에 줄이 없으면 더 쌓이면 알려 드린다는 한 줄을 보여 준다', (tester) async {
    final report = _emptyScoreReport();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdminPartnerMeetingPreview(
          report: report,
          shopName: '팔라우 다이브센터',
          periodLabel: '2026.10.21 ~ 10.27',
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('partner-meeting-score')), findsOneWidget);
    expect(
      find.byKey(const Key('partner-meeting-score-empty')),
      findsOneWidget,
    );
    expect(find.text('기록이 더 쌓이면 알려 드릴게요'), findsOneWidget);

    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    final bytes = await buildPartnerMeetingPdf(
      report: report,
      shopName: '팔라우 다이브센터',
      periodLabel: '2026.10.21 ~ 10.27',
      l10n: l10n,
    );
    final text =
        '${latin1.decode(bytes, allowInvalid: true)}${_inflateStreams(bytes)}';
    expect(text.contains('<AE30>'), isTrue);
  });

  testWidgets('저장은 새 문서를 만들고 보관함에서 보내고 다음 달을 다시 만든다', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.saveShopProfile(
      shopId: 'palau-dive',
      name: '팔라우 다이브센터',
      location: '팔라우',
      productName: '펀다이빙',
      consumerPrice: 180000,
      professionalPrice: 120000,
      country: '팔라우',
    );
    await repo.saveShopProduct(
      shopId: 'palau-dive',
      product: const ShopProduct(
        id: 'palau-live',
        shopId: 'palau-dive',
        name: '펀다이빙',
        continent: 'palau',
        consumerPrice: 180000,
        professionalPrice: 120000,
        capacity: 10,
        bookedSeats: 8,
      ),
    );
    await repo.createSeatEvent(
      _event('palau-view', 'palau-dive', DateTime(2026, 10, 22, 11)),
    );
    final store = DiverStore(repo);
    addTearDown(store.dispose);

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminPartnerMeetingScreen(now: DateTime(2026, 10, 27, 15)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('partner-meeting-shop')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('팔라우 다이브센터').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('partner-meeting-preview')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('partner-meeting-save')));
    await tester.tap(find.byKey(const Key('partner-meeting-save')));
    await tester.pump();
    await tester.pump();

    expect(repo.debugMeetingReports, hasLength(1));
    final saved = repo.debugMeetingReports.entries.single;
    expect(saved.value['shared'], isFalse);
    expect(saved.value.containsKey('shared_at'), isFalse);
    expect(saved.value.containsKey('user_key'), isFalse);
    expect(saved.value['shop_id'], 'palau-dive');
    expect(find.text('저장했어요'), findsWidgets);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('partner-meeting-archive')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('partner-meeting-archive')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(
      tester
          .widget<Text>(
            find.byKey(Key('partner-meeting-archive-row-${saved.key}')),
          )
          .data,
      '팔라우 다이브센터',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(Key('partner-meeting-archive-date-${saved.key}')),
          )
          .data,
      '2026.10.27',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(Key('partner-meeting-archive-status-${saved.key}')),
          )
          .data,
      '미발송',
    );
    expect(
      find.byKey(Key('partner-meeting-copy-link-${saved.key}')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(Key('partner-meeting-archive-send-${saved.key}')),
    );
    await tester.pump();
    await tester.pump();
    expect(repo.debugMeetingReports[saved.key]!['shared'], isTrue);
    expect(repo.debugMeetingReports[saved.key]!['shared_at'], isA<String>());
    expect(
      tester
          .widget<Text>(
            find.byKey(Key('partner-meeting-archive-status-${saved.key}')),
          )
          .data,
      '보냄',
    );

    await tester.tap(
      find.byKey(Key('partner-meeting-archive-unsend-${saved.key}')),
    );
    await tester.pump();
    await tester.pump();
    expect(repo.debugMeetingReports[saved.key]!['shared'], isFalse);
    expect(
      repo.debugMeetingReports[saved.key]!.containsKey('shared_at'),
      isFalse,
    );

    await tester.tap(
      find.byKey(Key('partner-meeting-archive-again-${saved.key}')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('2026.11.21 ~ 11.27'), findsOneWidget);
    expect(_text(tester, 'partner-meeting-views'), '0');
    expect(repo.debugMeetingReports, hasLength(1));
    final storedFunnel =
        repo.debugMeetingReports[saved.key]!['snapshot'] as Map;
    expect((storedFunnel['funnel'] as Map)['views'], 1);
    expect(repo.debugSeatEventQueries.last, (
      DateTime(2026, 11, 21),
      DateTime(2026, 11, 28),
    ));
  });
}

String _text(WidgetTester tester, String key) {
  return tester.widget<Text>(find.byKey(Key(key))).data!;
}

PartnerMeetingReport _emptyScoreReport() {
  return buildPartnerMeetingReport(
    id: 'preview',
    recipe: MeetingReportRecipe(
      shopId: 'palau-dive',
      periodStart: DateTime(2026, 10, 21),
      periodEnd: DateTime(2026, 10, 27),
      sections: const MeetingReportSections(
        conclusion: false,
        funnel: false,
        scorecard: true,
        demand: false,
        proposals: false,
      ),
    ),
    events: const [],
    demands: const [],
    seats: const [],
    createdAt: DateTime(2026, 10, 27, 15),
  );
}

String _inflateStreams(List<int> bytes) {
  final source = latin1.decode(bytes, allowInvalid: true);
  final out = StringBuffer();
  var cursor = 0;
  while (true) {
    final start = source.indexOf('stream', cursor);
    if (start < 0) {
      break;
    }
    var dataStart = start + 'stream'.length;
    if (dataStart < source.length && source.codeUnitAt(dataStart) == 13) {
      dataStart++;
    }
    if (dataStart < source.length && source.codeUnitAt(dataStart) == 10) {
      dataStart++;
    }
    final end = source.indexOf('endstream', dataStart);
    if (end < 0) {
      break;
    }
    var dataEnd = end;
    if (dataEnd > dataStart && source.codeUnitAt(dataEnd - 1) == 10) {
      dataEnd--;
    }
    if (dataEnd > dataStart && source.codeUnitAt(dataEnd - 1) == 13) {
      dataEnd--;
    }
    try {
      final inflated = ZLibDecoder().convert(bytes.sublist(dataStart, dataEnd));
      out.write(latin1.decode(inflated, allowInvalid: true));
    } catch (_) {}
    cursor = end + 'endstream'.length;
  }
  return out.toString();
}

SeatLifeEvent _event(String id, String shopId, DateTime at) {
  return SeatLifeEvent(
    id: id,
    kind: 'view',
    seatId: 'seat-1',
    shopId: shopId,
    productId: 'palau-live',
    userKey: 'a' * 64,
    region: '팔라우',
    nationality: '국적비밀',
    at: at,
  );
}
