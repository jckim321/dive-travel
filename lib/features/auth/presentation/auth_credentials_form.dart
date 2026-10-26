import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/auth/auth_identity.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Name tag + password submitted from [AuthCredentialsForm].
class AuthCredentials {
  const AuthCredentials({
    required this.signUp,
    required this.nameTag,
    required this.password,
    required this.keepSignedIn,
    required this.authEmail,
    required this.displayName,
    required this.loginId,
  });

  final bool signUp;
  final String nameTag;
  final String password;

  /// True keeps the session after the browser closes.
  final bool keepSignedIn;
  final String authEmail;
  final String displayName;
  final String loginId;
}

/// Sign-up / sign-in fields shared by the auth page and a future login sheet.
class AuthCredentialsForm extends StatefulWidget {
  const AuthCredentialsForm({
    super.key,
    required this.onSubmit,
    this.busy = false,
    this.errorText,
    this.onSignUpChanged,
  });

  final Future<void> Function(AuthCredentials credentials) onSubmit;
  final bool busy;
  final String? errorText;
  final ValueChanged<bool>? onSignUpChanged;

  @override
  State<AuthCredentialsForm> createState() => _AuthCredentialsFormState();
}

class _AuthCredentialsFormState extends State<AuthCredentialsForm> {
  final _nameTag = TextEditingController();
  final _password = TextEditingController();
  var _signUp = true;
  var _keepSignedIn = true;
  String? _localError;

  @override
  void dispose() {
    _nameTag.dispose();
    _password.dispose();
    super.dispose();
  }

  void _setSignUp(bool signUp) {
    if (_signUp == signUp) return;
    setState(() {
      _signUp = signUp;
      _localError = null;
    });
    widget.onSignUpChanged?.call(signUp);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final nameTag = _nameTag.text;
    final password = _password.text;
    setState(() => _localError = null);

    final issue = AuthIdentity.nameTagIssue(nameTag, allowEmail: !_signUp);
    if (issue != null) {
      setState(() => _localError = _issueMessage(l10n, issue));
      return;
    }
    if (password.length < 6) {
      setState(() => _localError = l10n.authErrorWeakPassword);
      return;
    }

    final trimmed = nameTag.trim();
    await widget.onSubmit(
      AuthCredentials(
        signUp: _signUp,
        nameTag: trimmed,
        password: password,
        keepSignedIn: _keepSignedIn,
        authEmail: AuthIdentity.toAuthEmail(trimmed),
        displayName: trimmed,
        loginId: AuthIdentity.storedLoginId(trimmed),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = _localError ?? widget.errorText;
    return Column(
      key: const Key('auth-credentials-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _AuthTab(
              key: const Key('auth-tab-signup'),
              label: l10n.authFirstVisit,
              selected: _signUp,
              onTap: () => _setSignUp(true),
            ),
            const SizedBox(width: 22),
            _AuthTab(
              key: const Key('auth-tab-login'),
              label: l10n.authWelcomeBack,
              selected: !_signUp,
              onTap: () => _setSignUp(false),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          key: const Key('auth-login-id'),
          controller: _nameTag,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
          decoration: InputDecoration(
            labelText: l10n.authNameTag,
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('auth-password'),
          controller: _password,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: l10n.authPassword,
            hintText: l10n.authPasswordHint,
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        CheckboxListTile(
          key: const Key('auth-keep-signed-in'),
          contentPadding: EdgeInsets.zero,
          value: _keepSignedIn,
          onChanged: widget.busy
              ? null
              : (value) => setState(() => _keepSignedIn = value ?? true),
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            l10n.authKeepSignedIn,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            key: const Key('auth-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('auth-submit'),
          onPressed: widget.busy ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.navy,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: widget.busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.authStart),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.authForgotPasswordNote,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
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
                color: selected ? AppTheme.navy : Colors.transparent,
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
