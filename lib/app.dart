import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:dive_travel_app/core/auth/device_pin_controller.dart';
import 'package:dive_travel_app/core/auth/device_pin_store.dart';
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
    this.devicePinStore,
  });

  final bool firebaseReady;
  final DiverRepository? repository;

  /// Injected in tests; production uses [PrefsDevicePinStore].
  final DevicePinStore? devicePinStore;

  @override
  State<DiveTravelApp> createState() => _DiveTravelAppState();
}

class _DiveTravelAppState extends State<DiveTravelApp> {
  SessionController? _session;
  DiverStore? _store;
  DevicePinController? _pins;

  @override
  void initState() {
    super.initState();
    _bindRepository(widget.repository);
  }

  @override
  void didUpdateWidget(covariant DiveTravelApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.devicePinStore != widget.devicePinStore) {
      _tearDown();
      _bindRepository(widget.repository);
    }
  }

  void _tearDown() {
    _session?.removeListener(_onSession);
    _session?.dispose();
    _store?.dispose();
    _pins?.dispose();
    _session = null;
    _store = null;
    _pins = null;
  }

  void _bindRepository(DiverRepository? repository) {
    final resolved = repository ??
        (widget.firebaseReady ? FirestoreDiverRepository() : null);
    if (resolved == null) {
      _session = null;
      _store = null;
      _pins = null;
      return;
    }
    _session = SessionController(resolved);
    _store = DiverStore(resolved);
    _pins = DevicePinController(widget.devicePinStore ?? PrefsDevicePinStore());
    _session!.addListener(_onSession);
    unawaited(_pins!.load().then((_) {
      if (!mounted) return;
      unawaited(_pins!.syncAuthUid(_session?.user?.uid));
    }));
  }

  void _onSession() {
    final pins = _pins;
    final session = _session;
    if (pins == null || session == null) {
      return;
    }
    unawaited(pins.syncAuthUid(session.user?.uid));
  }

  @override
  void dispose() {
    _tearDown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final store = _store;
    final pins = _pins;
    if (session == null || store == null || pins == null) {
      return _localizedApp(home: const FirebaseSetupScreen());
    }

    return SessionScope(
      session: session,
      child: DiverStoreScope(
        store: store,
        child: DevicePinScope(
          controller: pins,
          child: _localizedApp(home: const AuthGate()),
        ),
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
