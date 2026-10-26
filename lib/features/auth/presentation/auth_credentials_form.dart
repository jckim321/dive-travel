import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/auth/auth_identity.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/auth/presentation/signup_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Id + password submitted from [AuthCredentialsForm].
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
  final bool keepSignedIn;
  final String authEmail;
  final String displayName;
  final String loginId;
}

/// Login fields. Tabs are optional so a parent sheet can own them.
class AuthCredentialsForm extends StatefulWidget {
  const AuthCredentialsForm({
    super.key,
    required this.onSubmit,
    this.busy = false,
    this.errorText,
    this.onSignUpChanged,
    this.initialSignUp = false,
    this.showTabs = true,
    this.onOpenSignUp,
  });

  final Future<void> Function(AuthCredentials credentials) onSubmit;
  final bool busy;
  final String? errorText;
  final ValueChanged<bool>? onSignUpChanged;
  final bool initialSignUp;

  /// When false, the parent draws 「처음이에요 | 다시 왔어요」.
  final bool showTabs;

  /// Overrides the default full-screen signup push.
  final VoidCallback? onOpenSignUp;

  @override
  State<AuthCredentialsForm> createState() => _AuthCredentialsFormState();
}

class _AuthCredentialsFormState extends State<AuthCredentialsForm> {
  final _nameTag = TextEditingController();
  final _password = TextEditingController();
  var _keepSignedIn = true;
  var _obscure = true;
  String? _localError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSignUpChanged?.call(false);
    });
  }

  @override
  void dispose() {
    _nameTag.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _openSignup() async {
    final custom = widget.onOpenSignUp;
    if (custom != null) {
      custom();
      return;
    }
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const SignupScreen()),
    );
    if (ok == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final nameTag = _nameTag.text;
    final password = _password.text;
    setState(() => _localError = null);

    final issue = AuthIdentity.nameTagIssue(nameTag, allowEmail: true);
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
        signUp: false,
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
    final error = _localError ?? widget.errorText;
    return Column(
      key: const Key('auth-credentials-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showTabs) ...[
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
        ],
        TextField(
          key: const Key('auth-login-id'),
          controller: _nameTag,
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
          onSubmitted: (_) => _submit(),
          decoration: _fieldDecoration(
            label: l10n.authPassword,
            hint: l10n.authPasswordFieldHint,
            prefix: Icons.lock_outline,
            suffix: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppTheme.muted,
              ),
            ),
          ),
        ),
        CheckboxListTile(
          key: const Key('auth-keep-signed-in'),
          contentPadding: EdgeInsets.zero,
          value: _keepSignedIn,
          onChanged: widget.busy
              ? null
              : (value) => setState(() => _keepSignedIn = value ?? true),
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            l10n.authKeepSignedInShort,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        if (error != null) ...[
          Text(
            error,
            key: const Key('auth-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 8),
        ],
        FilledButton(
          key: const Key('auth-submit'),
          onPressed: widget.busy ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.navy,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: widget.busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.authLogin),
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
