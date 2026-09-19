import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController(text: AppOwner.email);
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(text: AppOwner.displayName);
  bool _isSignUp = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final session = SessionScope.of(context);
    final l10n = AppLocalizations.of(context);
    final password = _passwordController.text;
    setState(() {
      _error = null;
      _info = null;
    });
    if (password.length < 6) {
      setState(() => _error = l10n.authErrorWeakPassword);
      return;
    }
    try {
      if (_isSignUp) {
        await session.signUp(
          email: _emailController.text,
          password: password,
          displayName: _nameController.text,
        );
      } else {
        await session.signIn(
          email: _emailController.text,
          password: password,
        );
      }
    } catch (error) {
      debugPrint('Auth error: $error');
      if (error is FirebaseAuthException) {
        debugPrint('Auth code=${error.code} message=${error.message}');
      }
      if (!mounted) {
        return;
      }
      setState(() => _error = _messageFor(error, AppLocalizations.of(context)));
    }
  }

  Future<void> _resetPassword() async {
    final session = SessionScope.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() {
      _error = null;
      _info = null;
    });
    try {
      await session.sendPasswordReset(_emailController.text);
      if (!mounted) {
        return;
      }
      setState(() => _info = l10n.authResetPasswordSent);
    } catch (error) {
      debugPrint('Password reset error: $error');
      if (!mounted) {
        return;
      }
      setState(() => _error = _messageFor(error, l10n));
    }
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
            _isSignUp = false;
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
          const SizedBox(height: 24),
          if (_isSignUp) ...[
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.authDisplayName,
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: l10n.authEmail,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
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
          const SizedBox(height: 24),
          FilledButton(
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
            onPressed: session.busy ? null : _resetPassword,
            child: Text(l10n.authResetPassword),
          ),
          TextButton(
            onPressed: () => setState(() => _isSignUp = !_isSignUp),
            child: Text(_isSignUp ? l10n.authHaveAccount : l10n.authNoAccount),
          ),
        ],
      ),
    );
  }
}
