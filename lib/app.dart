import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_repository.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/firestore_diver_repository.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/auth/presentation/auth_gate.dart';
import 'package:dive_travel_app/features/auth/presentation/firebase_setup_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class DiveTravelApp extends StatefulWidget {
  const DiveTravelApp({
    super.key,
    this.firebaseReady = false,
    this.repository,
  });

  final bool firebaseReady;
  final DiverRepository? repository;

  @override
  State<DiveTravelApp> createState() => _DiveTravelAppState();
}

class _DiveTravelAppState extends State<DiveTravelApp> {
  SessionController? _session;
  DiverStore? _store;

  @override
  void initState() {
    super.initState();
    _bindRepository(widget.repository);
  }

  @override
  void didUpdateWidget(covariant DiveTravelApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _session?.dispose();
      _store?.dispose();
      _bindRepository(widget.repository);
    }
  }

  void _bindRepository(DiverRepository? repository) {
    final resolved = repository ??
        (widget.firebaseReady ? FirestoreDiverRepository() : null);
    if (resolved == null) {
      _session = null;
      _store = null;
      return;
    }
    _session = SessionController(resolved);
    _store = DiverStore(resolved);
  }

  @override
  void dispose() {
    _session?.dispose();
    _store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final store = _store;
    if (session == null || store == null) {
      return _localizedApp(home: const FirebaseSetupScreen());
    }

    return SessionScope(
      session: session,
      child: DiverStoreScope(
        store: store,
        child: _localizedApp(home: const AuthGate()),
      ),
    );
  }

  Widget _localizedApp({required Widget home}) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: AppConstants.defaultLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
  }
}
