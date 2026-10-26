import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/session_controller.dart';
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
      backgroundColor: const Color(0xFF0C5EA6),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _LoginBackdrop(),
          SafeArea(
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
        ],
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

const _loginBg = AssetImage('assets/images/login_bg.webp');

class _LoginBackdrop extends StatefulWidget {
  const _LoginBackdrop();

  @override
  State<_LoginBackdrop> createState() => _LoginBackdropState();
}

class _LoginBackdropState extends State<_LoginBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 42),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(_loginBg, context);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  void _syncMotion() {
    final route = ModalRoute.of(context);
    final visible =
        TickerMode.valuesOf(context).enabled && (route == null || route.isCurrent);
    if (visible) {
      if (!_motion.isAnimating) _motion.repeat();
    } else if (_motion.isAnimating) {
      _motion.stop(canceled: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF49C4F2),
                  Color(0xFF1B86D0),
                  Color(0xFF0C5EA6),
                  Color(0xFF08487C),
                ],
                stops: [0, 0.28, 0.62, 1],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedBuilder(
              animation: _motion,
              builder: (context, child) {
                final wave = math.sin(_motion.value * math.pi * 2);
                return Transform.translate(
                  offset: Offset(wave * 8, -wave * 6),
                  child: Transform.scale(
                    scale: 1.1 + wave * 0.025,
                    child: child,
                  ),
                );
              },
              child: Image(
                image: _loginBg,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                gaplessPlayback: true,
                frameBuilder: (context, child, frame, _) {
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
              ),
            ),
          ),
          CustomPaint(
            painter: _RisingBubblesPainter(repaint: _motion),
            child: const SizedBox.expand(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00061A2C),
                  Color(0x00061A2C),
                  Color(0x59061A2C),
                  Color(0xC2061A2C),
                ],
                stops: [0, 0.45, 0.74, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RisingBubblesPainter extends CustomPainter {
  _RisingBubblesPainter({required this.repaint}) : super(repaint: repaint);

  final Animation<double> repaint;

  static const _bubbles = <(double, double, double, double)>[
    (0.16, 0.05, 5, 0.72),
    (0.38, 0.41, 3.5, 0.9),
    (0.62, 0.18, 6, 0.64),
    (0.78, 0.63, 4, 0.8),
    (0.9, 0.3, 3, 1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x47FFFFFF);
    final t = repaint.value;
    for (final (x, phase, radius, speed) in _bubbles) {
      final progress = (t * speed + phase) % 1;
      final y = size.height * (1.08 - progress * 1.25);
      final drift = math.sin((progress + phase) * math.pi * 2) * 6;
      canvas.drawCircle(Offset(size.width * x + drift, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RisingBubblesPainter oldDelegate) => false;
}
