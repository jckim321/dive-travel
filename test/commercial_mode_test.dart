import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  Future<AppLocalizations> loadKo() {
    return AppLocalizations.delegate.load(const Locale('ko'));
  }

  test('상품 카드는 출발일과 빈자리를 가진다', () {
    final dahab = DiveShopCatalog.byId('dahab-bluehole');
    expect(dahab, isNotNull);
    expect(dahab!.departure, isNotNull);
    expect(dahab.departure!.lastCall, isTrue);
    expect(dahab.departure!.emptySeats, 1);
    expect(dahab.departure!.windowLabel, '09.20 – 09.23');
  });

  test('기상 취소는 샵 예약을 weather_cancelled 로 바꾸고 전액 환불한다', () async {
    final repo = MemoryDiverRepository.forTest();
    final tour = DateTime(2026, 11, 1);
    await repo.createBooking(
      uid: 'test-user',
      shopId: AppConstants.defaultPartnerShopId,
      shopName: '보홀 오션 하이드아웃',
      productName: '2탱크 펀다이빙',
      price: 180000,
      tourDate: tour,
    );
    await repo.cancelBookingsForWeather(
      shopId: AppConstants.defaultPartnerShopId,
      tourDate: tour,
    );
    final bookings = await repo.watchBookings('test-user').first;
    expect(bookings.first.status, BookingStatus.weatherCancelled);
    expect(bookings.first.refundPercent, 100);
    expect(bookings.first.paymentStatus, 'refunded');
  });

  testWidgets('마이페이지에서 파트너 모드로 들어간다', (tester) async {
    await tester.pumpWidget(
      DiveTravelApp(
        firebaseReady: true,
        repository: MemoryDiverRepository.forTest(),
      ),
    );
    await tester.pump();
    await tester.pump();
    final l10n = await loadKo();

    await tester.tap(find.text(l10n.navProfile));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open-partner-mode')), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-partner-mode')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.partnerTitle), findsWidgets);
    expect(find.text(l10n.partnerProductForm), findsOneWidget);
  });

  testWidgets('버디 탭의 영어 글에 번역 보기가 뜬다', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('ko');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    await tester.pumpWidget(
      DiveTravelApp(
        firebaseReady: true,
        repository: MemoryDiverRepository.forTest(),
      ),
    );
    await tester.pump();
    await tester.pump();
    final l10n = await loadKo();

    await tester.tap(find.text(l10n.navCommunity));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const Key('tide-board')), const Offset(0, -420));
    await tester.pumpAndSettle();
    expect(find.text(l10n.translateAction), findsWidgets);
  });
}
