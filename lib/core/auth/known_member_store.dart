import 'package:shared_preferences/shared_preferences.dart';

const _kKnown = 'auth.known_member_on_device';

/// Whether this device has completed sign-up or sign-in at least once.
/// Returning visitors get the compact sheet; first-time visitors get AuthScreen.
abstract class KnownMemberStore {
  Future<bool> isKnown();
  Future<void> markKnown();
  Future<void> clear();
}

/// Default production store. Tests may replace [deviceKnownMember].
KnownMemberStore deviceKnownMember = PrefsKnownMemberStore();

class PrefsKnownMemberStore implements KnownMemberStore {
  PrefsKnownMemberStore({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;
  SharedPreferences? _prefs;

  Future<SharedPreferences> _ready() async {
    if (_prefs != null) return _prefs!;
    if (_prefsOverride != null) return _prefs = _prefsOverride;
    try {
      return _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      SharedPreferences.setMockInitialValues(const {});
      return _prefs = await SharedPreferences.getInstance();
    }
  }

  @override
  Future<bool> isKnown() async {
    final prefs = await _ready();
    return prefs.getBool(_kKnown) == true;
  }

  @override
  Future<void> markKnown() async {
    final prefs = await _ready();
    await prefs.setBool(_kKnown, true);
  }

  @override
  Future<void> clear() async {
    final prefs = await _ready();
    await prefs.remove(_kKnown);
  }
}

class MemoryKnownMemberStore implements KnownMemberStore {
  MemoryKnownMemberStore({bool known = false}) : _known = known;

  var _known = false;

  @override
  Future<bool> isKnown() async => _known;

  @override
  Future<void> markKnown() async {
    _known = true;
  }

  @override
  Future<void> clear() async {
    _known = false;
  }
}
