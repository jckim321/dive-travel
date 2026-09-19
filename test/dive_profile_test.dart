import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/dive_log.dart';
import 'package:dive_travel_app/core/models/diver_stats.dart';

void main() {
  test('탱크 10개는 10로그씩 찬다', () {
    const stats = DiverStats(
      displayName: '다이버',
      totalLogCount: 24,
      uniqueRegionsCount: 2,
      isInstructor: false,
    );
    expect(stats.tankFill(0), 1);
    expect(stats.tankFill(1), 1);
    expect(stats.tankFill(2), closeTo(0.4, 0.001));
    expect(stats.tankFill(3), 0);
  });

  test('100 이후에는 다음 100 구간이 이어진다', () {
    DiverStats of(int logs) => DiverStats(
          displayName: '다이버',
          totalLogCount: logs,
          uniqueRegionsCount: 1,
          isInstructor: false,
        );

    expect(of(100).hasReachedMaster, isTrue);
    expect(of(100).centuryProgress, 1);
    expect(of(100).currentCenturyTarget, 100);
    expect(of(100).centuryFill(0), 1);
    expect(of(100).centuryFill(1), 0);

    expect(of(137).centuryProgress, closeTo(0.37, 0.001));
    expect(of(137).currentCenturyTarget, 200);
    expect(of(137).centuryFill(0), 1);
    expect(of(137).centuryFill(1), closeTo(0.37, 0.001));
    expect(of(137).logsToNextCentury, 63);

    expect(of(1000).hasReachedLegend, isTrue);
    expect(of(1000).centuryFill(9), 1);
  });

  test('BMV는 평균수심이 없으면 최대수심으로 계산한다', () {
    const profile = DiveProfile(
      maxDepthM: 20,
      minutes: 40,
      startBar: 200,
      endBar: 50,
      tankLiters: 12,
    );
    expect(profile.sacLitersPerMin, closeTo(15, 0.05));
  });

  test('최근에 작성한 로그가 앞으로 온다', () {
    final older = DiveLog(
      id: 'old',
      siteName: '코멜',
      divedAt: DateTime(2026, 9, 16),
      memo: '',
      createdAt: DateTime(2026, 9, 1),
    );
    final newer = DiveLog(
      id: 'new',
      siteName: '보홀',
      divedAt: DateTime(2026, 8, 1),
      memo: '',
      createdAt: DateTime(2026, 9, 16),
    );
    final logs = [older, newer]
      ..sort((a, b) => b.writtenAt.compareTo(a.writtenAt));
    expect(logs.first.id, 'new');
  });
}
