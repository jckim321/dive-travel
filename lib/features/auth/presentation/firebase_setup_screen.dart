import 'package:flutter/material.dart';

import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l10n.firebaseSetupTitle, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(l10n.firebaseSetupBody),
        ],
      ),
    );
  }
}
