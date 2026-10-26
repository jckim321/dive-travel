import 'package:flutter/widgets.dart';

import 'package:dive_travel_app/core/auth/device_pin_store.dart';

enum DevicePinVerify {
  ok,
  wrong,
  lockedOut,
  missing,
  invalid,
}

/// Device-only PIN lock for admin/partner sessions.
/// Hash stays on the device; [unlocked] is in-memory for this app process.
class DevicePinController extends ChangeNotifier {
  DevicePinController(this._store, {this.maxFails = 5});

  final DevicePinStore _store;
  final int maxFails;

  DevicePinRecord? _record;
  var _ready = false;
  var _unlocked = false;
  String? _sessionUid;

  bool get ready => _ready;
  bool get unlocked => _unlocked;
  bool get hasPin => _record != null;
  String? get pinnedUid => _record?.uid;
  int get fails => _record?.fails ?? 0;

  /// True when a signed-in staff account must enter the PIN before the shell.
  bool needsUnlock({
    required String? uid,
    required bool isStaff,
  }) {
    if (!_ready || !isStaff) {
      return false;
    }
    if (uid == null || uid.isEmpty) {
      return false;
    }
    if (_record == null || _record!.uid != uid) {
      return false;
    }
    return !_unlocked;
  }

  Future<void> load() async {
    _record = await _store.read();
    _ready = true;
    notifyListeners();
  }

  /// Call when auth uid changes. Clears the PIN on logout or account switch.
  Future<void> syncAuthUid(String? uid) async {
    _sessionUid = uid;
    if (!_ready) {
      await load();
    }
    if (uid == null || uid.isEmpty) {
      await clearPin();
      _unlocked = false;
      notifyListeners();
      return;
    }
    final record = _record;
    if (record != null && record.uid != uid) {
      await clearPin();
      _unlocked = false;
      notifyListeners();
      return;
    }
    if (record != null && record.uid == uid) {
      // Cold start: keep locked until verify.
      notifyListeners();
      return;
    }
    notifyListeners();
  }

  Future<DevicePinVerify> setPin({
    required String uid,
    required String pin,
  }) async {
    if (uid.isEmpty || !isValidDevicePin(pin)) {
      return DevicePinVerify.invalid;
    }
    final record = DevicePinRecord(
      uid: uid,
      hash: hashDevicePin(uid: uid, pin: pin),
    );
    await _store.write(record);
    _record = record;
    _unlocked = true;
    _sessionUid = uid;
    notifyListeners();
    return DevicePinVerify.ok;
  }

  Future<DevicePinVerify> verify({
    required String uid,
    required String pin,
  }) async {
    if (!isValidDevicePin(pin)) {
      return DevicePinVerify.invalid;
    }
    final record = _record ?? await _store.read();
    _record = record;
    if (record == null || record.uid != uid) {
      return DevicePinVerify.missing;
    }
    final expected = hashDevicePin(uid: uid, pin: pin);
    if (expected == record.hash) {
      _record = record.copyWith(fails: 0);
      await _store.write(_record!);
      _unlocked = true;
      notifyListeners();
      return DevicePinVerify.ok;
    }
    final fails = record.fails + 1;
    if (fails >= maxFails) {
      await clearPin();
      _unlocked = false;
      notifyListeners();
      return DevicePinVerify.lockedOut;
    }
    _record = record.copyWith(fails: fails);
    await _store.write(_record!);
    notifyListeners();
    return DevicePinVerify.wrong;
  }

  void markUnlocked() {
    if (_unlocked) {
      return;
    }
    _unlocked = true;
    notifyListeners();
  }

  void lockSession() {
    if (!_unlocked) {
      return;
    }
    _unlocked = false;
    notifyListeners();
  }

  Future<void> clearPin() async {
    await _store.clear();
    _record = null;
  }

  /// Test helper.
  @visibleForTesting
  String? get debugSessionUid => _sessionUid;
}

class DevicePinScope extends InheritedNotifier<DevicePinController> {
  const DevicePinScope({
    super.key,
    required DevicePinController controller,
    required super.child,
  }) : super(notifier: controller);

  static DevicePinController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<DevicePinScope>();
    assert(scope != null, 'DevicePinScope가 위젯 트리에 없습니다.');
    return scope!.notifier!;
  }

  static DevicePinController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DevicePinScope>()
        ?.notifier;
  }
}
