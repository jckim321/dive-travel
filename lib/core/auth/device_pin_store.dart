import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kUid = 'device_pin.uid';
const _kHash = 'device_pin.hash';
const _kFails = 'device_pin.fails';

class DevicePinRecord {
  const DevicePinRecord({
    required this.uid,
    required this.hash,
    this.fails = 0,
  });

  final String uid;
  final String hash;
  final int fails;

  DevicePinRecord copyWith({String? uid, String? hash, int? fails}) {
    return DevicePinRecord(
      uid: uid ?? this.uid,
      hash: hash ?? this.hash,
      fails: fails ?? this.fails,
    );
  }
}

/// Hashes a 4-digit PIN for one account. Never send the raw PIN or hash to a server.
String hashDevicePin({required String uid, required String pin}) {
  return sha256.convert(utf8.encode('$uid|$pin')).toString();
}

bool isValidDevicePin(String pin) => RegExp(r'^\d{4}$').hasMatch(pin);

abstract class DevicePinStore {
  Future<DevicePinRecord?> read();
  Future<void> write(DevicePinRecord record);
  Future<void> clear();
}

class PrefsDevicePinStore implements DevicePinStore {
  PrefsDevicePinStore({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;
  SharedPreferences? _prefs;

  Future<SharedPreferences> _ready() async {
    return _prefs ??= _prefsOverride ?? await SharedPreferences.getInstance();
  }

  @override
  Future<DevicePinRecord?> read() async {
    final prefs = await _ready();
    final uid = prefs.getString(_kUid)?.trim() ?? '';
    final hash = prefs.getString(_kHash)?.trim() ?? '';
    if (uid.isEmpty || hash.isEmpty) {
      return null;
    }
    return DevicePinRecord(
      uid: uid,
      hash: hash,
      fails: prefs.getInt(_kFails) ?? 0,
    );
  }

  @override
  Future<void> write(DevicePinRecord record) async {
    final prefs = await _ready();
    await prefs.setString(_kUid, record.uid);
    await prefs.setString(_kHash, record.hash);
    await prefs.setInt(_kFails, record.fails);
  }

  @override
  Future<void> clear() async {
    final prefs = await _ready();
    await prefs.remove(_kUid);
    await prefs.remove(_kHash);
    await prefs.remove(_kFails);
  }
}

class MemoryDevicePinStore implements DevicePinStore {
  DevicePinRecord? _record;

  @override
  Future<DevicePinRecord?> read() async => _record;

  @override
  Future<void> write(DevicePinRecord record) async {
    _record = record;
  }

  @override
  Future<void> clear() async {
    _record = null;
  }
}
