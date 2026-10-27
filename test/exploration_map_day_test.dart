import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/widgets/exploration_map.dart';
import 'package:dive_travel_app/core/widgets/pulsing_marker.dart';
import 'package:dive_travel_app/core/widgets/world_outline_painter.dart';

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

  testWidgets('낮 바다·황동 테두리·큰 제목이고 카드는 더 납작하다', (tester) async {
    await pumpMap(tester);

    expect(
      tester.widget<AspectRatio>(find.byType(AspectRatio)).aspectRatio,
      greaterThan(2.3),
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

    expect(find.byKey(const Key('exploration-map-sun')), findsOneWidget);
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
    final caption = tester.getRect(find.text('My ocean map'));
    expect(diver.bottom, lessThan(caption.top));

    final markers = tester
        .widgetList<PulsingMarker>(find.byType(PulsingMarker))
        .toList();
    expect(markers.where((marker) => marker.isGolden), hasLength(1));
    expect(
      markers.singleWhere((marker) => marker.isGolden).color,
      const Color(0xFFC4A35A),
    );
    expect(
      markers.singleWhere((marker) => !marker.isGolden).color,
      const Color(0xFFD7F3FF),
    );
    for (final marker in find.byType(PulsingMarker).evaluate()) {
      final spot = tester.getCenter(find.byWidget(marker.widget));
      expect(diver.contains(spot), isFalse);
      expect(caption.contains(spot), isFalse);
    }
  });
}
