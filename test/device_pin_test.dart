import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/core/auth/device_pin_controller.dart';
import 'package:dive_travel_app/core/auth/device_pin_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  test('기기 핀은 해시만 저장하고 5번 실패하면 지운다', () async {
    final store = MemoryDevicePinStore();
    final pins = DevicePinController(store, maxFails: 5);
    await pins.load();

    expect(
      await pins.setPin(uid: 'u1', pin: '1234'),
      DevicePinVerify.ok,
    );
    final saved = await store.read();
    expect(saved, isNotNull);
    expect(saved!.hash, isNot(equals('1234')));
    expect(saved.hash, hashDevicePin(uid: 'u1', pin: '1234'));

    for (var i = 0; i < 4; i++) {
      expect(
        await pins.verify(uid: 'u1', pin: '0000'),
        DevicePinVerify.wrong,
      );
    }
    expect(
      await pins.verify(uid: 'u1', pin: '0000'),
      DevicePinVerify.lockedOut,
    );
    expect(await store.read(), isNull);
  });

  test('로그아웃·다른 계정이면 핀을 지운다', () async {
    final store = MemoryDevicePinStore();
    final pins = DevicePinController(store);
    await pins.setPin(uid: 'u1', pin: '1234');
    await pins.syncAuthUid(null);
    expect(await store.read(), isNull);

    await pins.setPin(uid: 'u1', pin: '1234');
    await pins.syncAuthUid('u2');
    expect(await store.read(), isNull);
  });

  testWidgets('핀이 있으면 앱을 다시 열 때 잠금 해제한다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final pinStore = MemoryDevicePinStore();
    await pinStore.write(
      DevicePinRecord(
        uid: 'test-user',
        hash: hashDevicePin(uid: 'test-user', pin: '4321'),
      ),
    );

    await tester.pumpWidget(
      DiveTravelApp(
        firebaseReady: true,
        repository: MemoryDiverRepository.forTest(isAdmin: true),
        devicePinStore: pinStore,
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('device-pin-unlock-page')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('device-pin-unlock-field')),
      '4321',
    );
    await tester.tap(find.byKey(const Key('device-pin-unlock-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('device-pin-unlock-page')), findsNothing);
    expect(find.byKey(const Key('home-scroll')), findsOneWidget);
  });

  testWidgets('관리자는 처음 핀을 정한 뒤 대시보드에 들어가고, 같은 세션에서는 다시 묻지 않는다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final pinStore = MemoryDevicePinStore();
    await tester.pumpWidget(
      DiveTravelApp(
        firebaseReady: true,
        repository: MemoryDiverRepository.forTest(isAdmin: true),
        devicePinStore: pinStore,
      ),
    );
    await tester.pump();
    await tester.pump();
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tester.tap(find.text(l10n.navProfile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-profile-settings')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('profile-settings-scroll')),
      const Offset(0, -560),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open-admin-mode')));
    await tester.tap(find.byKey(const Key('open-admin-mode')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('device-pin-set-field')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('device-pin-set-field')), '2468');
    await tester.enterText(
      find.byKey(const Key('device-pin-confirm-field')),
      '2468',
    );
    await tester.tap(find.byKey(const Key('device-pin-set-submit')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.adminHqTitle), findsOneWidget);
    final saved = await pinStore.read();
    expect(saved?.hash, hashDevicePin(uid: 'test-user', pin: '2468'));

    await tester.tap(find.text(l10n.adminHqClose));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open-admin-mode')));
    await tester.tap(find.byKey(const Key('open-admin-mode')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('device-pin-set-field')), findsNothing);
    expect(find.byKey(const Key('admin-pin-field')), findsNothing);
    expect(find.text(l10n.adminHqTitle), findsOneWidget);
  });
}
