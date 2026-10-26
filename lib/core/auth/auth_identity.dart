import 'dart:convert';

/// Username ↔ Firebase Auth email helpers (H8).
///
/// Firebase Auth still uses email/password; usernames map to a synthetic
/// address on [syntheticDomain]. Real emails (containing `@`) pass through.
///
/// Legacy ids (`a-z`, `0-9`, `_`, 4–20) keep the old `{id}@domain` mapping so
/// existing accounts still sign in. Any other allowed name tag is UTF-8 hex
/// with an `u_` prefix, because the fake mailbox must stay ASCII.
abstract final class AuthIdentity {
  static const String syntheticDomain = 'users.dive-travel.app';

  static final RegExp loginIdPattern = RegExp(r'^[a-z0-9_]{4,20}$');

  /// Hangul syllables, English letters, digits, and `_` (legacy ids).
  static final RegExp nameTagChars = RegExp(r'^[A-Za-z0-9_\uAC00-\uD7A3]+$');

  /// Firebase local-part limit. `u_` plus hex must fit.
  static const int maxLocalPartLength = 64;

  /// Blocked as login ids (case-insensitive).
  static const Set<String> reservedLoginIds = {
    'admin',
    'root',
    'system',
    'dive',
    'divetravel',
    'dive_travel',
    'apdi',
    'owner',
    'support',
    'help',
    'null',
    'undefined',
    'test',
    'guest',
    'partner',
    'moderator',
    'mod',
    'staff',
  };

  /// True when [input] looks like an email (contains `@`).
  static bool looksLikeEmail(String input) => input.trim().contains('@');

  static String normalizeLoginId(String raw) => raw.trim().toLowerCase();

  static bool isValidLoginId(String raw) {
    final id = normalizeLoginId(raw);
    return loginIdPattern.hasMatch(id) && !isReservedLoginId(id);
  }

  static bool isReservedLoginId(String raw) {
    final id = normalizeLoginId(raw);
    return reservedLoginIds.contains(id);
  }

  /// True for the pre-Hangul id shape, after lowercasing. Reserved words can
  /// still match this; callers reject those separately.
  static bool isLegacyLoginId(String raw) {
    return loginIdPattern.hasMatch(normalizeLoginId(raw));
  }

  /// Why a name tag cannot be used. Null means it can.
  ///
  /// [allowEmail] is the sign-in path: a real address passes through.
  static NameTagIssue? nameTagIssue(String raw, {bool allowEmail = false}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return NameTagIssue.empty;
    if (allowEmail && trimmed.contains('@')) return null;
    if (isReservedLoginId(trimmed)) return NameTagIssue.reserved;
    if (isLegacyLoginId(trimmed)) return null;
    if (!nameTagChars.hasMatch(trimmed)) return NameTagIssue.format;
    if (hexLocalPart(trimmed) == null) return NameTagIssue.tooLong;
    return null;
  }

  /// UTF-8 hex local part `u_` + lowercase hex, or null when it will not fit.
  static String? hexLocalPart(String nameTag) {
    final bytes = utf8.encode(nameTag);
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    final local = 'u_$hex';
    if (local.length > maxLocalPartLength) return null;
    return local;
  }

  /// Value stored as `login_id`. Legacy ids stay lowercased; other tags keep
  /// the typed name so the profile does not show the hex mailbox.
  static String storedLoginId(String raw) {
    final trimmed = raw.trim();
    if (isLegacyLoginId(trimmed)) return normalizeLoginId(trimmed);
    return trimmed;
  }

  /// Maps login field → Firebase Auth email.
  ///
  /// - Contains `@` → trimmed email (existing owner accounts keep working).
  /// - Legacy id → `{lowercased id}@users.dive-travel.app` (unchanged).
  /// - Otherwise → `u_{utf8 hex}@users.dive-travel.app`.
  static String toAuthEmail(String loginOrEmail) {
    final trimmed = loginOrEmail.trim();
    if (trimmed.contains('@')) {
      return trimmed;
    }
    if (isLegacyLoginId(trimmed)) {
      return '${normalizeLoginId(trimmed)}@$syntheticDomain';
    }
    final local = hexLocalPart(trimmed);
    if (local == null) {
      return '${normalizeLoginId(trimmed)}@$syntheticDomain';
    }
    return '$local@$syntheticDomain';
  }

  /// Login id from a synthetic auth email; null for real emails / empty.
  static String? loginIdFromAuthEmail(String? email) {
    final value = (email ?? '').trim().toLowerCase();
    if (value.isEmpty || !value.endsWith('@$syntheticDomain')) {
      return null;
    }
    final local = value.split('@').first;
    return local.isEmpty ? null : local;
  }
}

enum NameTagIssue { empty, reserved, format, tooLong }
