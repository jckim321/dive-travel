import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/travel_style.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/diver_stats.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';

void main() {
  const emptyStats = DiverStats(
    displayName: '다이버',
    totalLogCount: 0,
    uniqueRegionsCount: 0,
    isInstructor: false,
  );

  DiveRegion region(String continent, {int logs = 2}) {
    return DiveRegion(
      id: continent,
      name: continent,
      latitude: 1,
      longitude: 1,
      logCount: logs,
      continent: continent,
    );
  }

  test('첫 로그는 아시아를 다음에 연다', () {
    final insight = TravelStyleAnalyzer.analyze(
      regions: const [],
      stats: emptyStats,
      shops: const [],
    );
    expect(insight.kind, TravelStyleKind.firstOcean);
    expect(insight.nextContinent, ContinentId.asia);
    expect(insight.stampCount, 0);
  });

  test('아시아만 있으면 오세아니아를 연다', () {
    final insight = TravelStyleAnalyzer.analyze(
      regions: [region(ContinentId.asia)],
      stats: emptyStats.copyWith(totalLogCount: 4, uniqueRegionsCount: 1),
      shops: const [],
    );
    expect(insight.kind, TravelStyleKind.homeContinent);
    expect(insight.nextContinent, ContinentId.oceania);
    expect(insight.stampedContinents, {ContinentId.asia});
  });

  test('골든 지역은 딥 로컬 스타일이다', () {
    final insight = TravelStyleAnalyzer.analyze(
      regions: [region(ContinentId.asia, logs: 20)],
      stats: emptyStats.copyWith(totalLogCount: 20, uniqueRegionsCount: 1),
      shops: const [],
    );
    expect(insight.kind, TravelStyleKind.deepLocal);
  });

  test('확정 예약이 있으면 가장 가까운 출국을 고른다', () {
    final now = DateTime(2026, 9, 16);
    final later = TourBooking(
      id: 'later',
      shopId: 'b',
      shopName: 'Bohol',
      productName: '2D',
      price: 1,
      createdAt: now,
      tourDate: DateTime(2026, 10, 10),
    );
    final sooner = TourBooking(
      id: 'soon',
      shopId: 'd',
      shopName: 'Dahab',
      productName: '3D',
      price: 1,
      createdAt: now,
      tourDate: DateTime(2026, 9, 20),
    );
    final trip = TravelStyleAnalyzer.nextTrip([later, sooner], now: now);
    expect(trip?.id, 'soon');
    expect(TravelStyleAnalyzer.daysUntil(sooner.scheduledFor, now: now), 4);
  });
}
