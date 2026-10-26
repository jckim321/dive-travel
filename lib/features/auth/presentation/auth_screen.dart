import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/features/auth/presentation/auth_credentials_form.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Checked box: keep the Firebase session after the browser closes.
/// Cleared box: end it when the browser session ends. No-op off the web.
Future<void> applyKeepSignedIn(bool keepSignedIn) async {
  if (!kIsWeb) return;
  await FirebaseAuth.instance.setPersistence(
    keepSignedIn ? Persistence.LOCAL : Persistence.SESSION,
  );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  var _signUp = true;
  String? _error;

  Future<void> _submit(AuthCredentials credentials) async {
    final session = SessionScope.of(context);
    setState(() => _error = null);
    try {
      await applyKeepSignedIn(credentials.keepSignedIn);
      if (credentials.signUp) {
        await session.signUp(
          email: credentials.authEmail,
          password: credentials.password,
          displayName: credentials.displayName,
          loginId: credentials.loginId,
        );
      } else {
        await session.signIn(
          email: credentials.authEmail,
          password: credentials.password,
        );
      }
    } catch (error) {
      _handleAuthError(error);
    }
  }

  void _handleAuthError(Object error) {
    debugPrint('Auth error: $error');
    if (error is FirebaseAuthException) {
      debugPrint('Auth code=${error.code} message=${error.message}');
    }
    if (!mounted) return;
    setState(() => _error = _messageFor(error, AppLocalizations.of(context)));
  }

  String _messageFor(Object error, AppLocalizations l10n) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return l10n.authErrorInvalidEmail;
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return l10n.authErrorInvalidCredential;
        case 'email-already-in-use':
          if (_signUp) return l10n.authErrorLoginIdInUse;
          return l10n.authErrorEmailInUse;
        case 'weak-password':
          return l10n.authErrorWeakPassword;
        case 'operation-not-allowed':
          return l10n.authErrorOperationNotAllowed;
        case 'unauthorized-domain':
        case 'app-not-authorized':
        case 'invalid-api-key':
        case 'api-key-not-valid.-please-pass-a-valid-api-key.':
          return l10n.authErrorGeneric;
        case 'network-request-failed':
          return l10n.authErrorNetwork;
      }
      return '${l10n.authErrorGeneric} (${error.code})';
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
        case 'not-found':
        case 'unavailable':
        case 'failed-precondition':
        case 'unimplemented':
          return l10n.authErrorFirestore;
      }
    }
    return l10n.authErrorGeneric;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFE7EEF2),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
              children: [
                _AuthHero(signUp: _signUp),
                const SizedBox(height: 16),
                Material(
                  color: Colors.white,
                  elevation: 0,
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                    child: AuthCredentialsForm(
                      busy: session.busy,
                      errorText: _error,
                      onSignUpChanged: (signUp) => setState(() {
                        _signUp = signUp;
                        _error = null;
                      }),
                      onSubmit: _submit,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6D8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Text(
                      l10n.authTrialNote,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A6A12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.signUp});

  final bool signUp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A9BB3), Color(0xFF3FCFC8)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DIVE TRAVEL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.authHeroTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                height: 1.25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              signUp ? l10n.authHeroSignupHint : l10n.authHeroLoginHint,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
