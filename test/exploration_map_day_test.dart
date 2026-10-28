import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/theme/region_neon.dart';
import 'package:dive_travel_app/core/widgets/exploration_map.dart';
import 'package:dive_travel_app/core/widgets/pulsing_marker.dart';
import 'package:dive_travel_app/core/widgets/travel_title_bar.dart';
import 'package:dive_travel_app/core/widgets/world_outline_painter.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  const sandFill = Color(0xFFF6EBD4);
  const sandStroke = Color(0xD9FFFFFF);
  const numberGold = Color(0xFFF0D48A);

  Future<void> pumpMap(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExplorationMap(
            regions: [
              DiveRegion(
                id: 'palau',
                name: '팔라우',
                latitude: 7,
                longitude: 134,
                logCount: 1,
                continent: 'pacific',
              ),
              DiveRegion(
                id: 'maldives',
                name: '몰디브',
                latitude: 3,
                longitude: 73,
                logCount: 20,
                continent: 'indian',
              ),
            ],
            titleEnglish: 'My ocean map',
            titleLocalized: '나의 글로벌 바다 개척 지도',
            exploredEnglish: 'Exploring 2 regions so far',
            exploredLocalized: '현재까지 총 2개 지역 탐험 중',
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('낮 바다·황동 테두리·큰 제목이고 지도는 더 높다', (tester) async {
    await pumpMap(tester);

    expect(
      tester.widget<AspectRatio>(find.byType(AspectRatio)).aspectRatio,
      closeTo(1.75, 0.01),
    );

    final porthole = tester.widget<DecoratedBox>(
      find.byKey(const Key('exploration-map-porthole')),
    );
    final frame = porthole.decoration as BoxDecoration;
    final colors = (frame.gradient as LinearGradient).colors;
    expect(colors, contains(const Color(0xFFD4AF57)));

    final outline = tester.widget<CustomPaint>(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is WorldOutlinePainter,
      ),
    );
    final painter = outline.painter as WorldOutlinePainter;
    expect(painter.fill, sandFill);
    expect(painter.stroke, sandStroke);

    final sunPaint = tester.widget<CustomPaint>(
      find.byKey(const Key('exploration-map-sun')),
    );
    expect(sunPaint.painter, isA<ExplorationSunPainter>());
    expect(ExplorationSunPainter.rayCount, 7);
    expect(ExplorationSunPainter.rayOpacity, 0.4);
    expect(ExplorationSunPainter.rayTipOpacity, 0);
    expect(ExplorationSunPainter.rayBaseHalfWidth, lessThan(6));
    expect(ExplorationSunPainter.diskRadius, greaterThan(16));
    final mapSize = tester.getSize(find.byKey(const Key('exploration-map-sun')));
    final origin = ExplorationSunPainter.originFor(mapSize);
    expect(origin.dx, greaterThan(mapSize.width * 0.8));
    expect(origin.dy, lessThan(mapSize.height * 0.2));
    final ends = ExplorationSunPainter.rayEnds(mapSize);
    expect(ends, hasLength(ExplorationSunPainter.rayCount));
    final wedge = ExplorationSunPainter.rayVertices(origin, ends.first);
    expect(wedge[1], ends.first);
    expect(
      (wedge[0] - wedge[2]).distance,
      closeTo(ExplorationSunPainter.rayBaseHalfWidth * 2, 0.01),
    );
    var lowest = 0.0;
    for (final end in ends) {
      expect(end.dx, lessThan(origin.dx));
      if (end.dy > lowest) {
        lowest = end.dy;
      }
    }
    expect(lowest, greaterThan(mapSize.height * 0.45));
    expect(find.byKey(const Key('exploration-map-diver')), findsOneWidget);

    final title = tester.widget<Text>(find.text('My ocean map'));
    expect(title.style?.fontSize, 19);
    expect(title.style?.fontWeight, FontWeight.w800);
    final numbers = tester.widget<Text>(
      find.text('Exploring 2 regions so far'),
    );
    expect(numbers.style?.fontSize, 22);
    expect(numbers.style?.color, numberGold);

    final diver = tester.getRect(
      find.byKey(const Key('exploration-map-diver')),
    );
    final card = tester.getRect(
      find.byKey(const Key('exploration-map-porthole')),
    );
    final caption = tester.getRect(find.text('My ocean map'));
    expect(diver.width, closeTo(56, 1));
    expect(diver.center.dx, lessThan(card.center.dx));
    expect(diver.top, lessThanOrEqualTo(card.top + 2));
    expect(diver.left, lessThan(card.left + 8));
    expect(diver.bottom, lessThan(caption.top));

    final markers = tester
        .widgetList<PulsingMarker>(find.byType(PulsingMarker))
        .toList();
    expect(markers.where((marker) => marker.isGolden), isEmpty);
    expect(
      markers.singleWhere((marker) => marker.tooltip!.contains('팔라우')).color,
      regionNeonTeal,
    );
    expect(
      markers.singleWhere((marker) => marker.tooltip!.contains('몰디브')).color,
      regionNeonBrightTeal,
    );
    expect(
      markers.every((marker) => !marker.doubleRing && !marker.softGlow),
      isTrue,
    );
    expect(
      find.byWidgetPredicate((widget) {
        final decoration = widget is Container ? widget.decoration : null;
        return decoration is BoxDecoration &&
            decoration.color == const Color(0xFFFFF6E4);
      }),
      findsNWidgets(2),
    );
    for (final marker in find.byType(PulsingMarker).evaluate()) {
      final spot = tester.getCenter(find.byWidget(marker.widget));
      expect(diver.contains(spot), isFalse);
      expect(caption.contains(spot), isFalse);
    }
  });

  testWidgets('사진 카드는 폰 너비에서 약 140이다', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryDiverRepository.forTest();
    final store = DiverStore(repo);
    final session = SessionController(repo);
    addTearDown(store.dispose);
    addTearDown(session.dispose);
    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: SessionScope(
          session: session,
          child: const MaterialApp(
            locale: Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: TravelPosterHeader()),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.getSize(find.byKey(const Key('home-hero-card'))).height,
      closeTo(140, 6),
    );
  });

  testWidgets('지도 마커 금빛은 여권과 같은 단계다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExplorationMap(
            regions: [
              DiveRegion(
                id: 'teal',
                name: '청록해',
                latitude: 7,
                longitude: 134,
                logCount: 5,
                continent: 'pacific',
              ),
              DiveRegion(
                id: 'bright',
                name: '밝은바다',
                latitude: 8,
                longitude: 120,
                logCount: 20,
                continent: 'pacific',
              ),
              DiveRegion(
                id: 'gold',
                name: '금색',
                latitude: 3,
                longitude: 73,
                logCount: 80,
                continent: 'indian',
              ),
              DiveRegion(
                id: 'ring',
                name: '이중',
                latitude: 10,
                longitude: 100,
                logCount: 250,
                continent: 'asia',
              ),
              DiveRegion(
                id: 'glow',
                name: '빛',
                latitude: 1,
                longitude: 50,
                logCount: 1200,
                continent: 'asia',
              ),
            ],
            titleEnglish: 'My ocean map',
            titleLocalized: '나의 글로벌 바다 개척 지도',
            exploredEnglish: 'Exploring 5 regions so far',
            exploredLocalized: '현재까지 총 5개 지역 탐험 중',
          ),
        ),
      ),
    );
    await tester.pump();

    PulsingMarker marker(String name) {
      return tester.widget<PulsingMarker>(
        find.byWidgetPredicate(
          (widget) => widget is PulsingMarker && widget.tooltip!.contains(name),
        ),
      );
    }

    final teal = marker('청록해');
    final bright = marker('밝은바다');
    final gold = marker('금색');
    final ring = marker('이중');
    final glow = marker('빛');
    expect(teal.color, regionNeonTeal);
    expect(teal.isGolden, isFalse);
    expect(bright.color, regionNeonBrightTeal);
    expect(bright.isGolden, isFalse);
    expect(gold.color, regionNeonGold);
    expect(gold.isGolden, isTrue);
    expect(gold.doubleRing, isFalse);
    expect(gold.softGlow, isFalse);
    expect(ring.doubleRing, isTrue);
    expect(ring.softGlow, isFalse);
    expect(ring.color, regionNeonGold);
    expect(glow.doubleRing, isTrue);
    expect(glow.softGlow, isTrue);
    expect(glow.isGolden, isTrue);
    expect(glow.tooltip, contains('단골 우수 지역'));
  });
}
