import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/auth/known_member_store.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/auth/presentation/auth_credentials_form.dart';
import 'package:dive_travel_app/features/auth/presentation/auth_screen.dart';
import 'package:dive_travel_app/features/auth/presentation/signup_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Opens sign-in over the current screen.
/// Cold start and sign-out use [AuthScreen]; every in-app gate uses this sheet.
/// Returns true when the session is signed in afterwards.
Future<bool> ensureSignedIn(BuildContext context) async {
  final session = SessionScope.of(context);
  if (session.isSignedIn) return true;
  if (!context.mounted) return false;

    final signedIn = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      final available = media.size.height - media.viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: available * 0.92),
          child: const AuthPromptSheet(),
        ),
      );
    },
  );
  return signedIn == true && session.isSignedIn;
}

/// Login / signup over the page the user was already on.
class AuthPromptSheet extends StatefulWidget {
  const AuthPromptSheet({super.key});

  @override
  State<AuthPromptSheet> createState() => _AuthPromptSheetState();
}

class _AuthPromptSheetState extends State<AuthPromptSheet> {
  var _signUp = false;
  String? _error;

  Future<void> _submit(AuthCredentials credentials) async {
    final session = SessionScope.of(context);
    setState(() => _error = null);
    try {
      await applyKeepSignedIn(credentials.keepSignedIn);
      await session.signIn(
        email: credentials.authEmail,
        password: credentials.password,
      );
      await deviceKnownMember.markKnown();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = authFailureMessage(
          error,
          AppLocalizations.of(context),
          signUp: false,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final signupHeight = (constraints.maxHeight - 96).clamp(
          240.0,
          constraints.maxHeight,
        );
        return Padding(
          key: const Key('auth-sign-in-sheet'),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5DBE0),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _SheetTab(
                    key: const Key('auth-tab-signup'),
                    label: l10n.authFirstVisit,
                    selected: _signUp,
                    onTap: () => setState(() {
                      _signUp = true;
                      _error = null;
                    }),
                  ),
                  const SizedBox(width: 22),
                  _SheetTab(
                    key: const Key('auth-tab-login'),
                    label: l10n.authWelcomeBack,
                    selected: !_signUp,
                    onTap: () => setState(() {
                      _signUp = false;
                      _error = null;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_signUp)
                SizedBox(
                  height: signupHeight,
                  child: SignupScreen(
                    embedded: true,
                    onBackToLogin: () => setState(() {
                      _signUp = false;
                      _error = null;
                    }),
                  ),
                )
              else
                AuthCredentialsForm(
                  busy: session.busy,
                  errorText: _error,
                  showTabs: false,
                  onSubmit: _submit,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetTab extends StatelessWidget {
  const _SheetTab({
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
