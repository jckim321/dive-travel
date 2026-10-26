import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/auth/known_member_store.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/auth/presentation/auth_credentials_form.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

String authFailureMessage(
  Object error,
  AppLocalizations l10n, {
  required bool signUp,
}) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return l10n.authErrorInvalidEmail;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return l10n.authErrorInvalidCredential;
      case 'email-already-in-use':
        if (signUp) return l10n.authErrorLoginIdInUse;
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

/// Checked box: keep the Firebase session after the browser closes.
/// Cleared box: end it when the browser session ends. No-op off the web.
Future<void> applyKeepSignedIn(bool keepSignedIn) async {
  if (!kIsWeb) return;
  await FirebaseAuth.instance.setPersistence(
    keepSignedIn ? Persistence.LOCAL : Persistence.SESSION,
  );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.popOnSuccess = false,
    this.initialSignUp = true,
  });

  /// When true (gated first visit), pop with `true` after a successful auth.
  final bool popOnSuccess;

  final bool initialSignUp;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late var _signUp = widget.initialSignUp;
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
      await deviceKnownMember.markKnown();
      if (!mounted) return;
      if (widget.popOnSuccess) {
        Navigator.of(context).pop(true);
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
    setState(
      () => _error = authFailureMessage(
        error,
        AppLocalizations.of(context),
        signUp: _signUp,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.of(context);
    return Scaffold(
      key: const Key('auth-full-screen'),
      backgroundColor: AppTheme.seaMist,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F4F8),
              AppTheme.seaMist,
              Color(0xFFF2F7FA),
            ],
            stops: [0, 0.45, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  if (widget.popOnSuccess)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        key: const Key('auth-full-close'),
                        onPressed: () =>
                            Navigator.of(context).maybePop(false),
                        icon: const Icon(Icons.close, color: AppTheme.navy),
                      ),
                    ),
                  _BrandWordmark(
                    subtitle: _signUp
                        ? l10n.authHeroSignupHint
                        : l10n.authHeroLoginHint,
                  ),
                  const SizedBox(height: 20),
                  Material(
                    color: Colors.white,
                    elevation: 0,
                    shadowColor: const Color(0x140B1F33),
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                      child: AuthCredentialsForm(
                        busy: session.busy,
                        errorText: _error,
                        initialSignUp: widget.initialSignUp,
                        onSignUpChanged: (signUp) => setState(() {
                          _signUp = signUp;
                          _error = null;
                        }),
                        onSubmit: _submit,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.authTrialNote,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-line brand mark with a one-shot entrance (fade + rise, gold rule expand).
class _BrandWordmark extends StatefulWidget {
  const _BrandWordmark({required this.subtitle});

  final String subtitle;

  @override
  State<_BrandWordmark> createState() => _BrandWordmarkState();
}

class _BrandWordmarkState extends State<_BrandWordmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _rule;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _fade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _rule = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
    );
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          const Text(
            'DIVE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.navy,
              fontSize: 34,
              height: 1.05,
              letterSpacing: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'TRAVEL',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.navy,
              fontSize: 28,
              height: 1.05,
              letterSpacing: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _rule,
            builder: (context, _) {
              return Center(
                child: SizedBox(
                  width: 72 * _rule.value.clamp(0.0, 1.0),
                  height: 2,
                  child: const ColoredBox(color: AppTheme.gold),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
