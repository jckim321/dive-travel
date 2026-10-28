import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/features/logbook/presentation/new_sea_stamp.dart';
import 'package:dive_travel_app/features/shell/presentation/main_shell.dart';

void main() {
  setUp(NewSeaStamp.debugReset);

  Future<void> pumpSignedInApp(
    WidgetTester tester, {
    MemoryDiverRepository? repository,
  }) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      DiveTravelApp(
        firebaseReady: true,
        repository: repository ?? MemoryDiverRepository.forTest(),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> openTab(WidgetTester tester, int index) async {
    final context = tester.element(find.byType(NavigationBar));
    MainShell.goToTab(context, index);
    await tester.pump();
  }

  Future<void> openAddLog(WidgetTester tester) async {
    await openTab(tester, 3);
    tester
        .widget<FloatingActionButton>(find.byType(FloatingActionButton))
        .onPressed
        ?.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> saveSite(WidgetTester tester, String site) async {
    await tester.enterText(find.byType(TextField).first, site);
    tester
        .widget<TextButton>(find.byKey(const Key('logbook-save-appbar')))
        .onPressed
        ?.call();
    await tester.pump();
    await tester.pump();
  }

  Future<void> pumpUntilStamp(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      if (find.byKey(const Key('new-sea-stamp')).evaluate().isNotEmpty) {
        return;
      }
      await tester.pump(const Duration(milliseconds: 16));
    }
    fail('NEW SEA stamp did not appear');
  }

  Future<void> letStampFinish(WidgetTester tester) async {
    await tester.pump(NewSeaStamp.duration);
    await tester.pump();
    expect(find.byKey(const Key('new-sea-stamp')), findsNothing);
  }

  Future<void> openProfile(WidgetTester tester) async {
    await openTab(tester, 4);
  }

  test('도장은 크게 시작해서 1로 자리잡는다', () {
    expect(newSeaStampScale(0), closeTo(1.22, 0.001));
    expect(newSeaStampScale(0.1), greaterThan(1));
    expect(newSeaStampScale(0.1), lessThan(1.22));
    expect(newSeaStampScale(0.28), 1);
    expect(newSeaStampScale(1), 1);
    expect(newSeaStampOpacity(0), 0);
    expect(newSeaStampOpacity(0.5), 1);
    expect(newSeaStampOpacity(1), 0);
  });

  testWidgets('새 지역을 저장하면 NEW SEA 도장이 찍히고 여권에 바로 생긴다', (tester) async {
    await pumpSignedInApp(tester);
    await openAddLog(tester);
    await saveSite(tester, '코멜');
    await pumpUntilStamp(tester);

    expect(find.text('NEW SEA'), findsOneWidget);
    expect(find.text('코멜'), findsWidgets);
    expect(
      tester.widget<Text>(find.byKey(const Key('new-sea-stamp-name'))).data,
      '코멜',
    );
    expect(
      tester
          .widget<Transform>(find.byKey(const Key('new-sea-stamp-scale')))
          .transform
          .getMaxScaleOnAxis(),
      greaterThan(1),
    );

    final stamp = find.byKey(const Key('new-sea-stamp'));
    final hits = tester.hitTestOnBinding(tester.getCenter(stamp));
    expect(
      hits.path.where(
        (entry) => entry.target == tester.renderObject(stamp),
      ),
      isEmpty,
    );
    expect(hits.path, isNotEmpty);

    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester
          .widget<Transform>(find.byKey(const Key('new-sea-stamp-scale')))
          .transform
          .getMaxScaleOnAxis(),
      closeTo(1, 0.001),
    );

    await openProfile(tester);
    expect(find.byKey(const Key('profile-passport-stamp-cozumel')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('profile-passport-name-cozumel'))).data,
      '코멜',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('profile-passport-count-cozumel'))).data,
      '1',
    );

    await letStampFinish(tester);
  });

  testWidgets('같은 지역을 다시 저장하면 도장이 나오지 않는다', (tester) async {
    await pumpSignedInApp(tester);
    await openAddLog(tester);
    await saveSite(tester, '코멜');
    await pumpUntilStamp(tester);
    await letStampFinish(tester);

    await openAddLog(tester);
    await saveSite(tester, '코멜');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('new-sea-stamp')), findsNothing);
    expect(find.text('NEW SEA'), findsNothing);
  });

  testWidgets('수정으로 새 지역을 적어도 도장은 나오지 않는다', (tester) async {
    await pumpSignedInApp(tester);
    await openAddLog(tester);
    await saveSite(tester, '코멜');
    await pumpUntilStamp(tester);
    await letStampFinish(tester);

    tester.widget<TextButton>(find.byKey(const Key('log-edit'))).onPressed?.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await saveSite(tester, '팔라우');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('new-sea-stamp')), findsNothing);
    await openProfile(tester);
    expect(find.byKey(const Key('profile-passport-stamp-palau')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('profile-passport-name-palau'))).data,
      '팔라우',
    );
    expect(find.byKey(const Key('profile-passport-stamp-cozumel')), findsNothing);
  });

  testWidgets('불러온 지역과 이미 기록한 지역에는 도장이 나오지 않는다', (tester) async {
    final repo = MemoryDiverRepository.forTest();
    await pumpSignedInApp(tester, repository: repo);
    await repo.addLog(
      uid: 'test-user',
      siteName: '보홀',
      divedAt: DateTime(2026, 1, 1),
      memo: '',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('new-sea-stamp')), findsNothing);

    await openProfile(tester);
    expect(find.byKey(const Key('profile-passport-stamp-bohol')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('profile-passport-count-bohol'))).data,
      '1',
    );

    await openAddLog(tester);
    await saveSite(tester, '보홀');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('new-sea-stamp')), findsNothing);

    await openProfile(tester);
    expect(
      tester.widget<Text>(find.byKey(const Key('profile-passport-count-bohol'))).data,
      '2',
    );
  });

  testWidgets('같은 지역 도장은 세션에서 한 번만 올린다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                NewSeaStamp.show(
                  context,
                  regionId: 'bohol',
                  regionName: '보홀',
                );
                NewSeaStamp.show(
                  context,
                  regionId: 'bohol',
                  regionName: '보홀',
                );
              },
              child: const Text('stamp'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('stamp'));
    await tester.pump();
    expect(find.byKey(const Key('new-sea-stamp')), findsOneWidget);
    expect(find.text('NEW SEA'), findsOneWidget);
    expect(find.text('보홀'), findsOneWidget);
    await tester.pump(NewSeaStamp.duration);
    await tester.pump();
    expect(find.byKey(const Key('new-sea-stamp')), findsNothing);
  });
}
