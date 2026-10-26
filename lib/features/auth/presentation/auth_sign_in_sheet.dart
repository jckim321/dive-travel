import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/auth/known_member_store.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/features/auth/presentation/auth_credentials_form.dart';
import 'package:dive_travel_app/features/auth/presentation/auth_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Opens sign-in for a gated action.
/// Returning devices get a compact sheet; first-time visitors get [AuthScreen].
/// Returns true when the session is signed in afterwards.
Future<bool> ensureSignedIn(BuildContext context) async {
  final session = SessionScope.of(context);
  if (session.isSignedIn) return true;

  final known = await deviceKnownMember.isKnown();
  if (!context.mounted) return false;

  if (known) {
    final signedIn = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        final bottom = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          key: const Key('auth-sign-in-sheet'),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
          child: SingleChildScrollView(
            child: _LoginSheet(
              session: session,
              initialSignUp: false,
            ),
          ),
        );
      },
    );
    return signedIn == true && session.isSignedIn;
  }

  final signedIn = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => const AuthScreen(
        popOnSuccess: true,
        showBrowseLink: false,
      ),
    ),
  );
  return signedIn == true && session.isSignedIn;
}

class _LoginSheet extends StatefulWidget {
  const _LoginSheet({
    required this.session,
    this.initialSignUp = true,
  });

  final SessionController session;
  final bool initialSignUp;

  @override
  State<_LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<_LoginSheet> {
  late var _signUp = widget.initialSignUp;
  String? _error;

  Future<void> _submit(AuthCredentials credentials) async {
    setState(() => _error = null);
    try {
      await applyKeepSignedIn(credentials.keepSignedIn);
      if (credentials.signUp) {
        await widget.session.signUp(
          email: credentials.authEmail,
          password: credentials.password,
          displayName: credentials.displayName,
          loginId: credentials.loginId,
        );
      } else {
        await widget.session.signIn(
          email: credentials.authEmail,
          password: credentials.password,
        );
      }
      await deviceKnownMember.markKnown();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = authFailureMessage(
          error,
          AppLocalizations.of(context),
          signUp: _signUp,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    return AuthCredentialsForm(
      busy: session.busy,
      errorText: _error,
      initialSignUp: widget.initialSignUp,
      onSignUpChanged: (signUp) => setState(() {
        _signUp = signUp;
        _error = null;
      }),
      onSubmit: _submit,
    );
  }
}
