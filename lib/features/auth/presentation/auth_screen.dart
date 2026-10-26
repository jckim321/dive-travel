import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/auth/guest_browse_store.dart';
import 'package:dive_travel_app/core/auth/known_member_store.dart';
import 'package:dive_travel_app/core/auth/auth_identity.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/auth/presentation/signup_screen.dart';
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

Future<void> applyKeepSignedIn(bool keepSignedIn) async {
  if (!kIsWeb) return;
  await FirebaseAuth.instance.setPersistence(
    keepSignedIn ? Persistence.LOCAL : Persistence.SESSION,
  );
}

/// Full-screen gate / push auth: brand + login card (default 「다시 왔어요」).
class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.popOnSuccess = false,
    this.showBrowseLink = true,
    this.initialSignUp = false,
  });

  final bool popOnSuccess;

  /// When true (root gate), show 「먼저 둘러보기」.
  final bool showBrowseLink;

  /// Unused for the card default (always login); kept for call-site compat.
  final bool initialSignUp;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginId = TextEditingController();
  final _password = TextEditingController();
  var _keepSignedIn = true;
  var _obscure = true;
  String? _error;

  @override
  void dispose() {
    _loginId.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _openSignup() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const SignupScreen(),
      ),
    );
    if (!mounted) return;
    if (ok == true) {
      if (widget.popOnSuccess) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _submitLogin() async {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.of(context);
    final raw = _loginId.text;
    final password = _password.text;
    setState(() => _error = null);

    final issue = AuthIdentity.nameTagIssue(raw, allowEmail: true);
    if (issue != null) {
      setState(() => _error = _issueMessage(l10n, issue));
      return;
    }
    if (password.length < 6) {
      setState(() => _error = l10n.authErrorWeakPassword);
      return;
    }

    final trimmed = raw.trim();
    try {
      await applyKeepSignedIn(_keepSignedIn);
      await session.signIn(
        email: AuthIdentity.toAuthEmail(trimmed),
        password: password,
      );
      await deviceKnownMember.markKnown();
      if (!mounted) return;
      if (widget.popOnSuccess) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = authFailureMessage(error, l10n, signUp: false),
      );
    }
  }

  String _issueMessage(AppLocalizations l10n, NameTagIssue issue) {
    switch (issue) {
      case NameTagIssue.empty:
        return l10n.authErrorNameTagRequired;
      case NameTagIssue.reserved:
        return l10n.authErrorLoginIdReserved;
      case NameTagIssue.format:
        return l10n.authErrorLoginIdFormat;
      case NameTagIssue.tooLong:
        return l10n.authErrorNameTagTooLong;
    }
  }

  void _browseAsGuest() {
    guestBrowse.enable();
    if (widget.popOnSuccess) {
      Navigator.of(context).maybePop(false);
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData prefix,
    Widget? suffix,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD5DBE0)),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(prefix, color: AppTheme.muted, size: 22),
      suffixIcon: suffix,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppTheme.oceanLight, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.of(context);
    return Scaffold(
      key: const Key('auth-full-screen'),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD7EAF4),
              Color(0xFFEAF4F8),
              Color(0xFFF7FBFC),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
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
                  const Text(
                    'DIVE TRAVEL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.navy,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: SizedBox(
                      width: 56,
                      height: 2,
                      child: ColoredBox(color: AppTheme.gold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.authWelcomeBanner,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Material(
                    color: Colors.white,
                    elevation: 0,
                    shadowColor: const Color(0x140B1F33),
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              _AuthTab(
                                key: const Key('auth-tab-signup'),
                                label: l10n.authFirstVisit,
                                selected: false,
                                onTap: _openSignup,
                              ),
                              const SizedBox(width: 22),
                              _AuthTab(
                                key: const Key('auth-tab-login'),
                                label: l10n.authWelcomeBack,
                                selected: true,
                                onTap: () {},
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            key: const Key('auth-login-id'),
                            controller: _loginId,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username],
                            decoration: _fieldDecoration(
                              label: l10n.authNameTag,
                              hint: l10n.authIdFieldHint,
                              prefix: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key('auth-password'),
                            controller: _password,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submitLogin(),
                            decoration: _fieldDecoration(
                              label: l10n.authPassword,
                              hint: l10n.authPasswordFieldHint,
                              prefix: Icons.lock_outline,
                              suffix: IconButton(
                                key: const Key('auth-password-visibility'),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppTheme.muted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          CheckboxListTile(
                            key: const Key('auth-keep-signed-in'),
                            contentPadding: EdgeInsets.zero,
                            value: _keepSignedIn,
                            onChanged: session.busy
                                ? null
                                : (v) => setState(
                                      () => _keepSignedIn = v ?? true,
                                    ),
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              l10n.authKeepSignedInShort,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          if (_error != null) ...[
                            Text(
                              _error!,
                              key: const Key('auth-error'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          FilledButton(
                            key: const Key('auth-submit'),
                            onPressed: session.busy ? null : _submitLogin,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.navy,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: session.busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l10n.authLogin),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.showBrowseLink) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      key: const Key('auth-browse-first'),
                      onPressed: _browseAsGuest,
                      child: Text(
                        l10n.authBrowseFirst,
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    l10n.authFooterCheer,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.authFooterContact,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 12,
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

class _AuthTab extends StatelessWidget {
  const _AuthTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppTheme.gold : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected ? AppTheme.navy : AppTheme.muted,
            ),
          ),
        ),
      ),
    );
  }
}
