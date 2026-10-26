import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/auth/auth_identity.dart';
import 'package:dive_travel_app/core/auth/known_member_store.dart';
import 'package:dive_travel_app/core/constants/auth_terms_consent.dart';
import 'package:dive_travel_app/core/constants/nationality.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/auth/presentation/auth_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Full-screen signup matching the SignupOne mock (ocean header + form).
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _loginId = TextEditingController();
  final _password = TextEditingController();
  final _legalName = TextEditingController();
  final _birthDate = TextEditingController();
  final _phone = TextEditingController();
  var _profileExpanded = false;
  var _obscure = true;
  var _agreeAll = false;
  var _agreeTerms = false;
  var _agreePrivacy = false;
  var _agreeMarketing = false;
  String? _nationality;
  String? _error;

  @override
  void dispose() {
    _loginId.dispose();
    _password.dispose();
    _legalName.dispose();
    _birthDate.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _setAgreeAll(bool? value) {
    final on = value ?? false;
    setState(() {
      _agreeAll = on;
      _agreeTerms = on;
      _agreePrivacy = on;
      _agreeMarketing = on;
    });
  }

  void _syncAgreeAll() {
    setState(() {
      _agreeAll = _agreeTerms && _agreePrivacy && _agreeMarketing;
    });
  }

  Future<void> _showTermsSheet(String title, String body) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            24 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.navy,
                  ),
                ),
                const SizedBox(height: 12),
                Text(body, style: const TextStyle(height: 1.45)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.navy),
                  child: Text(AppLocalizations.of(ctx).authTermsClose),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.of(context);
    setState(() => _error = null);

    final issue = AuthIdentity.nameTagIssue(_loginId.text);
    if (issue != null) {
      setState(() => _error = _issueMessage(l10n, issue));
      return;
    }
    if (_password.text.length < 6) {
      setState(() => _error = l10n.authErrorWeakPassword);
      return;
    }
    if (!_agreeTerms || !_agreePrivacy) {
      setState(() => _error = l10n.authErrorTermsRequired);
      return;
    }

    final trimmed = _loginId.text.trim();
    final legal = _legalName.text.trim();
    try {
      await applyKeepSignedIn(true);
      await session.signUp(
        email: AuthIdentity.toAuthEmail(trimmed),
        password: _password.text,
        displayName: legal.isNotEmpty ? legal : trimmed,
        loginId: AuthIdentity.storedLoginId(trimmed),
        nationality: _nationality,
        birthDate: _birthDate.text.trim(),
        phone: _phone.text.trim(),
        termsAccepted: _agreeTerms,
        privacyAccepted: _agreePrivacy,
        marketingOptIn: _agreeMarketing,
      );
      await deviceKnownMember.markKnown();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = authFailureMessage(error, l10n, signUp: true),
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

  InputDecoration _box(String? hint) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD5DBE0)),
    );
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
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
      key: const Key('auth-signup-screen'),
      backgroundColor: const Color(0xFFF3F6F8),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 12,
              12,
              28,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A3A5C), Color(0xFF0B1F33), Color(0xFF16344A)],
              ),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DIVE TRAVEL',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.authSignupPanelTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.authSignupHeroBody,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    key: const Key('auth-signup-close'),
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                Text(
                  l10n.authNameTag,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.navy,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('auth-signup-login-id'),
                  controller: _loginId,
                  decoration: _box(l10n.authIdExampleHint),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.authIdRuleHintLong,
                  style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.authPassword,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.navy,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('auth-signup-password'),
                  controller: _password,
                  obscureText: _obscure,
                  decoration: _box(null).copyWith(
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.authPasswordRuleHint,
                  style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
                const SizedBox(height: 14),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    key: const Key('auth-signup-profile-toggle'),
                    onTap: () =>
                        setState(() => _profileExpanded = !_profileExpanded),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.authSignupMoreAbout,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.navy,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.authSignupMoreAboutHint,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _profileExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: AppTheme.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_profileExpanded) ...[
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('auth-signup-legal-name'),
                    controller: _legalName,
                    decoration: _box(l10n.authSignupLegalNameHint).copyWith(
                      labelText: l10n.authSignupLegalName,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    key: const Key('auth-signup-birth'),
                    controller: _birthDate,
                    decoration: _box('YYYY-MM-DD').copyWith(
                      labelText: l10n.authSignupBirthDate,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    key: const Key('auth-signup-phone'),
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: _box(l10n.authSignupPhoneHint).copyWith(
                      labelText: l10n.authSignupPhone,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    key: const Key('auth-signup-nationality'),
                    initialValue: _nationality ?? '',
                    decoration: _box(null).copyWith(
                      labelText: l10n.authNationality,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(l10n.authNationalityNone),
                      ),
                      for (final n in nationalityChoices())
                        DropdownMenuItem(value: n.code, child: Text(n.nameKo)),
                    ],
                    onChanged: (v) => setState(
                      () => _nationality = (v == null || v.isEmpty) ? null : v,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                CheckboxListTile(
                  key: const Key('auth-consent-all'),
                  contentPadding: EdgeInsets.zero,
                  value: _agreeAll,
                  onChanged: _setAgreeAll,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(l10n.authConsentAll),
                ),
                CheckboxListTile(
                  key: const Key('auth-consent-terms'),
                  contentPadding: EdgeInsets.zero,
                  value: _agreeTerms,
                  onChanged: (v) {
                    setState(() => _agreeTerms = v ?? false);
                    _syncAgreeAll();
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Row(
                    children: [
                      Expanded(child: Text(l10n.authConsentTerms)),
                      TextButton(
                        onPressed: () => _showTermsSheet(
                          l10n.authConsentTerms,
                          AuthTermsConsent.termsOfServiceKo,
                        ),
                        child: Text(l10n.authTermsView),
                      ),
                    ],
                  ),
                ),
                CheckboxListTile(
                  key: const Key('auth-consent-privacy'),
                  contentPadding: EdgeInsets.zero,
                  value: _agreePrivacy,
                  onChanged: (v) {
                    setState(() => _agreePrivacy = v ?? false);
                    _syncAgreeAll();
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Row(
                    children: [
                      Expanded(child: Text(l10n.authConsentPrivacy)),
                      TextButton(
                        onPressed: () => _showTermsSheet(
                          l10n.authConsentPrivacy,
                          AuthTermsConsent.privacyPolicyKo,
                        ),
                        child: Text(l10n.authTermsView),
                      ),
                    ],
                  ),
                ),
                CheckboxListTile(
                  key: const Key('auth-consent-marketing'),
                  contentPadding: EdgeInsets.zero,
                  value: _agreeMarketing,
                  onChanged: (v) {
                    setState(() => _agreeMarketing = v ?? false);
                    _syncAgreeAll();
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Row(
                    children: [
                      Expanded(child: Text(l10n.authConsentMarketing)),
                      TextButton(
                        onPressed: () => _showTermsSheet(
                          l10n.authConsentMarketing,
                          AuthTermsConsent.marketingOptInKo,
                        ),
                        child: Text(l10n.authTermsView),
                      ),
                    ],
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
                  key: const Key('auth-signup-submit'),
                  onPressed: session.busy ? null : _submit,
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.authSignupAndBrowse),
                ),
                const SizedBox(height: 12),
                TextButton(
                  key: const Key('auth-signup-to-login'),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text.rich(
                    TextSpan(
                      text: '${l10n.authHaveAccountPrompt} ',
                      style: const TextStyle(color: AppTheme.muted),
                      children: [
                        TextSpan(
                          text: l10n.authWelcomeBack,
                          style: const TextStyle(
                            color: AppTheme.navy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
