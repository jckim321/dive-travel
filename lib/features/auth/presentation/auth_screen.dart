import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/auth/auth_identity.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final session = SessionScope.of(context);
    final l10n = AppLocalizations.of(context);
    final password = _passwordController.text;
    final loginRaw = _loginController.text;
    setState(() {
      _error = null;
      _info = null;
    });
    if (password.length < 6) {
      setState(() => _error = l10n.authErrorWeakPassword);
      return;
    }

    if (_isSignUp) {
      final id = AuthIdentity.normalizeLoginId(loginRaw);
      if (AuthIdentity.looksLikeEmail(loginRaw)) {
        setState(() => _error = l10n.authErrorLoginIdFormat);
        return;
      }
      if (AuthIdentity.isReservedLoginId(id)) {
        setState(() => _error = l10n.authErrorLoginIdReserved);
        return;
      }
      if (!AuthIdentity.isValidLoginId(id)) {
        setState(() => _error = l10n.authErrorLoginIdFormat);
        return;
      }
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        setState(() => _error = l10n.authErrorDisplayNameRequired);
        return;
      }
      try {
        await session.signUp(
          email: AuthIdentity.toAuthEmail(id),
          password: password,
          displayName: name,
          loginId: id,
        );
      } catch (error) {
        _handleAuthError(error);
      }
      return;
    }

    // Login: username or email (@ → pass through).
    final authEmail = AuthIdentity.toAuthEmail(loginRaw);
    if (!AuthIdentity.looksLikeEmail(loginRaw)) {
      final id = AuthIdentity.normalizeLoginId(loginRaw);
      if (!AuthIdentity.loginIdPattern.hasMatch(id)) {
        setState(() => _error = l10n.authErrorLoginIdFormat);
        return;
      }
    }
    try {
      await session.signIn(email: authEmail, password: password);
    } catch (error) {
      _handleAuthError(error);
    }
  }

  void _handleAuthError(Object error) {
    debugPrint('Auth error: $error');
    if (error is FirebaseAuthException) {
      debugPrint('Auth code=${error.code} message=${error.message}');
    }
    if (!mounted) {
      return;
    }
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
          if (_isSignUp) {
            return l10n.authErrorLoginIdInUse;
          }
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
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _isSignUp ? l10n.authSignup : l10n.authLogin,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.authWelcome,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (_isSignUp) ...[
            TextField(
              key: const Key('auth-display-name'),
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.authDisplayName,
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            key: const Key('auth-login-id'),
            controller: _loginController,
            keyboardType: _isSignUp
                ? TextInputType.text
                : TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: _isSignUp
                ? const [AutofillHints.username]
                : const [AutofillHints.username, AutofillHints.email],
            decoration: InputDecoration(
              labelText: _isSignUp ? l10n.authLoginId : l10n.authLoginIdOrEmail,
              hintText: _isSignUp ? l10n.authLoginIdHint : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('auth-password'),
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.authPassword,
              hintText: l10n.authPasswordHint,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (_info != null) ...[
            const SizedBox(height: 12),
            Text(
              _info!,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.authPasswordResetHiddenHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('auth-submit'),
            onPressed: session.busy ? null : _submit,
            child: session.busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isSignUp ? l10n.authSignup : l10n.authLogin),
          ),
          TextButton(
            onPressed: () => setState(() {
              _isSignUp = !_isSignUp;
              _error = null;
              _info = null;
            }),
            child: Text(_isSignUp ? l10n.authHaveAccount : l10n.authNoAccount),
          ),
        ],
      ),
    );
  }
}
