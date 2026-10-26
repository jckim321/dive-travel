import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Profile fields from a signup whose users-document write did not land.
class PendingProfile {
  const PendingProfile({
    required this.uid,
    this.displayName,
    this.loginId,
    this.nationality,
    this.birthDate,
    this.phone,
    this.termsAccepted,
    this.privacyAccepted,
    this.marketingOptIn,
  });

  final String uid;
  final String? displayName;
  final String? loginId;
  final String? nationality;
  final String? birthDate;
  final String? phone;
  final bool? termsAccepted;
  final bool? privacyAccepted;
  final bool? marketingOptIn;

  Map<String, Object?> toJson() => {
        'uid': uid,
        'display_name': displayName,
        'login_id': loginId,
        'nationality': nationality,
        'birth_date': birthDate,
        'phone': phone,
        'terms': termsAccepted,
        'privacy': privacyAccepted,
        'marketing': marketingOptIn,
      };

  static PendingProfile? fromJson(Map<String, Object?> json) {
    final uid = (json['uid'] as String?)?.trim() ?? '';
    if (uid.isEmpty) return null;
    return PendingProfile(
      uid: uid,
      displayName: json['display_name'] as String?,
      loginId: json['login_id'] as String?,
      nationality: json['nationality'] as String?,
      birthDate: json['birth_date'] as String?,
      phone: json['phone'] as String?,
      termsAccepted: json['terms'] as bool?,
      privacyAccepted: json['privacy'] as bool?,
      marketingOptIn: json['marketing'] as bool?,
    );
  }
}

/// Signup succeeded in Auth, but the users/{uid} profile write failed.
class ProfileWriteException implements Exception {
  const ProfileWriteException({required this.uid, required this.code});

  final String uid;
  final String code;

  String get detail => '($code / users/$uid)';

  @override
  String toString() => 'ProfileWriteException $detail';
}

abstract class PendingProfileStore {
  Future<void> save(PendingProfile profile);
  Future<PendingProfile?> forUid(String uid);
  Future<void> clear(String uid);
}

/// In-memory queue. Tests replace [pendingProfileWrites] with this.
class MemoryPendingProfileStore implements PendingProfileStore {
  PendingProfile? _profile;

  @override
  Future<void> save(PendingProfile profile) async {
    _profile = profile;
  }

  @override
  Future<PendingProfile?> forUid(String uid) async {
    final profile = _profile;
    if (profile == null || profile.uid != uid) return null;
    return profile;
  }

  @override
  Future<void> clear(String uid) async {
    if (_profile?.uid == uid) _profile = null;
  }
}

class PrefsPendingProfileStore implements PendingProfileStore {
  PrefsPendingProfileStore({SharedPreferences? prefs}) : _prefsOverride = prefs;

  static const _key = 'auth.pending_profile_v1';

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
  Future<void> save(PendingProfile profile) async {
    final prefs = await _ready();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  @override
  Future<PendingProfile?> forUid(String uid) async {
    final prefs = await _ready();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final profile = PendingProfile.fromJson(Map<String, Object?>.from(decoded));
      if (profile == null || profile.uid != uid) return null;
      return profile;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clear(String uid) async {
    final current = await forUid(uid);
    if (current == null) return;
    final prefs = await _ready();
    await prefs.remove(_key);
  }
}

/// Tests use the memory store. [main] switches this to prefs before runApp.
PendingProfileStore pendingProfileWrites = MemoryPendingProfileStore();
