/// Username ↔ Firebase Auth email helpers (H8).
///
/// Firebase Auth still uses email/password; usernames map to a synthetic
/// address on [syntheticDomain]. Real emails (containing `@`) pass through.
abstract final class AuthIdentity {
  static const String syntheticDomain = 'users.dive-travel.app';

  static final RegExp loginIdPattern = RegExp(r'^[a-z0-9_]{4,20}$');

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

  /// Maps login field → Firebase Auth email.
  ///
  /// - Contains `@` → trimmed email (existing owner accounts keep working).
  /// - Otherwise → `{loginId}@users.dive-travel.app`.
  static String toAuthEmail(String loginOrEmail) {
    final trimmed = loginOrEmail.trim();
    if (trimmed.contains('@')) {
      return trimmed;
    }
    final id = normalizeLoginId(trimmed);
    return '$id@$syntheticDomain';
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
