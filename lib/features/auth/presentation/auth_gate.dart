import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/features/auth/presentation/auth_screen.dart';
import 'package:dive_travel_app/features/shell/presentation/main_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    if (!session.ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!session.isSignedIn) {
      return const AuthScreen();
    }
    return const MainShell();
  }
}
