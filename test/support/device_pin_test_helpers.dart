import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/auth/device_pin_store.dart';

/// Default test PIN used when a setup or unlock dialog is showing.
const kTestDevicePin = '2468';

Future<MemoryDevicePinStore> memoryPinStoreWith({
  String uid = 'test-user',
  String pin = kTestDevicePin,
}) async {
  final store = MemoryDevicePinStore();
  await store.write(
    DevicePinRecord(
      uid: uid,
      hash: hashDevicePin(uid: uid, pin: pin),
    ),
  );
  return store;
}

/// Completes either first-time setup or unlock if a PIN dialog is open.
Future<void> completeDevicePinIfAsked(
  WidgetTester tester, {
  String pin = kTestDevicePin,
}) async {
  if (find.byKey(const Key('device-pin-set-field')).evaluate().isNotEmpty) {
    await tester.enterText(find.byKey(const Key('device-pin-set-field')), pin);
    await tester.enterText(
      find.byKey(const Key('device-pin-confirm-field')),
      pin,
    );
    await tester.tap(find.byKey(const Key('device-pin-set-submit')));
    await tester.pumpAndSettle();
    return;
  }
  if (find.byKey(const Key('admin-pin-field')).evaluate().isNotEmpty) {
    await tester.enterText(find.byKey(const Key('admin-pin-field')), pin);
    await tester.tap(find.byKey(const Key('admin-pin-submit')));
    await tester.pumpAndSettle();
  }
  if (find.byKey(const Key('device-pin-unlock-field')).evaluate().isNotEmpty) {
    await tester.enterText(
      find.byKey(const Key('device-pin-unlock-field')),
      pin,
    );
    await tester.tap(find.byKey(const Key('device-pin-unlock-submit')));
    await tester.pumpAndSettle();
  }
}
