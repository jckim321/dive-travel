import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/auth/device_pin_controller.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/features/auth/presentation/device_pin_dialogs.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_dashboard_screen.dart';
import 'package:dive_travel_app/features/shell/presentation/main_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

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
    // Guests browse the shell. Sign-in stays a sheet over the current screen.
    return const _SignedInHome();
  }
}

class _SignedInHome extends StatefulWidget {
  const _SignedInHome();

  @override
  State<_SignedInHome> createState() => _SignedInHomeState();
}

class _SignedInHomeState extends State<_SignedInHome> {
  DiverStore? _store;
  DevicePinController? _pins;
  String? _openedForUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = DiverStoreScope.of(context);
    if (!identical(_store, store)) {
      _store?.removeListener(_maybeOpenPartner);
      _store = store;
      _store!.addListener(_maybeOpenPartner);
    }
    final pins = DevicePinScope.of(context);
    if (!identical(_pins, pins)) {
      _pins?.removeListener(_maybeOpenPartner);
      _pins = pins;
      _pins!.addListener(_maybeOpenPartner);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOpenPartner());
  }

  @override
  void dispose() {
    _store?.removeListener(_maybeOpenPartner);
    _pins?.removeListener(_maybeOpenPartner);
    super.dispose();
  }

  void _maybeOpenPartner() {
    if (!mounted) {
      return;
    }
    final store = _store;
    if (store == null) {
      return;
    }
    final pins = DevicePinScope.of(context);
    final uid = store.uid;
    if (uid == null || uid.isEmpty) {
      _openedForUid = null;
      return;
    }
    if (store.loading) {
      return;
    }
    final live = store.stats;
    final staff = live.isAdmin || live.isBusiness;
    if (pins.needsUnlock(uid: uid, isStaff: staff)) {
      return;
    }
    // Admin always stays on customer shell (even if leftover is_business).
    if (live.isAdmin || !live.isBusiness) {
      return;
    }
    if (_openedForUid == uid) {
      return;
    }
    _openedForUid = uid;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PartnerDashboardScreen(),
      ),
    );
  }

  Future<void> _onLockedOut() async {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.devicePinLockedOut)),
    );
    await session.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final store = DiverStoreScope.of(context);
    final pins = DevicePinScope.of(context);
    if (!pins.ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final uid = store.uid;
    final live = store.stats;
    final staff = live.isAdmin || live.isBusiness;
    if (pins.needsUnlock(uid: uid, isStaff: staff) &&
        uid != null &&
        uid.isNotEmpty) {
      return DevicePinUnlockPage(
        uid: uid,
        onLockedOut: _onLockedOut,
      );
    }
    return const MainShell();
  }
}
