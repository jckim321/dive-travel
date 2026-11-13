import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/auth/auth_identity.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/auth/presentation/signup_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

bool _authEnglish(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'en';

/// Visible label and hint for the login id field.
String authIdFieldText(BuildContext context) =>
    _authEnglish(context) ? 'Email or ID' : '이메일 또는 아이디';

Future<void> showForgotPasswordDialog(BuildContext context) async {
  final email = TextEditingController();
  final english = _authEnglish(context);
  final typed = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(english ? 'Forgot password' : '비밀번호 찾기'),
        content: TextField(
          key: const Key('auth-reset-email'),
          controller: email,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: InputDecoration(
            labelText: english ? 'Email' : '이메일',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(english ? 'Cancel' : '취소'),
          ),
          TextButton(
            key: const Key('auth-reset-send'),
            onPressed: () => Navigator.of(dialogContext).pop(email.text.trim()),
            child: Text(english ? 'Send' : '보내기'),
          ),
        ],
      );
    },
  );
  email.dispose();
  if (typed == null || !context.mounted) {
    return;
  }
  if (!typed.contains('@')) {
    await _showForgotNotice(
      context,
      english
          ? 'Accounts signed up with an ID should contact help@divetravel.com.'
          : '아이디로 가입하신 계정은 help@divetravel.com으로 문의해 주세요.',
    );
    return;
  }
  try {
    await SessionScope.of(context).sendPasswordReset(typed);
  } catch (_) {}
  if (!context.mounted) {
    return;
  }
  await _showForgotNotice(
    context,
    english
        ? 'If this email is registered, we sent a reset mail. Check spam too.'
        : '가입한 이메일이라면 안내 메일을 보냈어요. 스팸함도 확인해 보세요.',
  );
}

Future<void> _showForgotNotice(BuildContext context, String message) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(_authEnglish(context) ? 'OK' : '확인'),
          ),
        ],
      );
    },
  );
}

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
            label: authIdFieldText(context),
            hint: authIdFieldText(context),
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
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
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
            ),
            TextButton(
              key: const Key('auth-forgot-password'),
              onPressed: widget.busy
                  ? null
                  : () => showForgotPasswordDialog(context),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.ocean,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _authEnglish(context) ? 'Forgot password' : '비밀번호 찾기',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
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
