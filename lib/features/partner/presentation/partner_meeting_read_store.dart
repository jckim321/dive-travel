import 'package:shared_preferences/shared_preferences.dart';

/// Report ids this device has opened. Unread is whatever is not in the set.
abstract class PartnerMeetingReadStore {
  Future<Set<String>> readIds();
  Future<void> markRead(String id);
}

class MemoryPartnerMeetingReadStore implements PartnerMeetingReadStore {
  final Set<String> ids = <String>{};

  @override
  Future<Set<String>> readIds() async => Set<String>.of(ids);

  @override
  Future<void> markRead(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return;
    }
    ids.add(trimmed);
  }
}

class PrefsPartnerMeetingReadStore implements PartnerMeetingReadStore {
  PrefsPartnerMeetingReadStore({SharedPreferences? prefs})
    : _prefsOverride = prefs;

  static const key = 'partner_meeting_read_ids';

  final SharedPreferences? _prefsOverride;
  SharedPreferences? _prefs;

  Future<SharedPreferences> _ready() async {
    if (_prefs != null) {
      return _prefs!;
    }
    if (_prefsOverride != null) {
      return _prefs = _prefsOverride;
    }
    try {
      return _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      SharedPreferences.setMockInitialValues(const {});
      return _prefs = await SharedPreferences.getInstance();
    }
  }

  @override
  Future<Set<String>> readIds() async {
    final prefs = await _ready();
    final raw = prefs.getStringList(key) ?? const <String>[];
    return {
      for (final id in raw)
        if (id.trim().isNotEmpty) id.trim(),
    };
  }

  @override
  Future<void> markRead(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final prefs = await _ready();
    final next = await readIds();
    if (next.contains(trimmed)) {
      return;
    }
    next.add(trimmed);
    await prefs.setStringList(key, next.toList()..sort());
  }
}
