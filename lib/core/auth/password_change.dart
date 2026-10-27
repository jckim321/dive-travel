/// Why a password change stopped. The password itself is never stored here.
final class PasswordChangeException implements Exception {
  const PasswordChangeException(this.code);

  final String code;

  static const wrong = 'WRONG_PASSWORD';
  static const tooShort = 'TOO_SHORT';
  static const relogin = 'RELOGIN';

  @override
  String toString() => 'PasswordChangeException($code)';
}

/// Maps a Firebase Auth error code onto [PasswordChangeException] codes.
String passwordChangeCodeForAuth(String code) {
  switch (code) {
    case 'wrong-password':
    case 'invalid-credential':
    case 'invalid-login-credentials':
      return PasswordChangeException.wrong;
    case 'weak-password':
      return PasswordChangeException.tooShort;
    default:
      return PasswordChangeException.relogin;
  }
}
