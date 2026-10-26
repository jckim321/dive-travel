import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/auth/device_pin_controller.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_dashboard_screen.dart';
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
  /// After the first settled profile load; restored sessions skip auto-open.
  var _staffRoutePrimed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = DiverStoreScope.of(context);
    if (!identical(_store, store)) {
      _store?.removeListener(_maybeOpenStaffConsole);
      _store = store;
      _store!.addListener(_maybeOpenStaffConsole);
    }
    final pins = DevicePinScope.of(context);
    if (!identical(_pins, pins)) {
      _pins?.removeListener(_maybeOpenStaffConsole);
      _pins = pins;
      _pins!.addListener(_maybeOpenStaffConsole);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOpenStaffConsole());
  }

  @override
  void dispose() {
    _store?.removeListener(_maybeOpenStaffConsole);
    _pins?.removeListener(_maybeOpenStaffConsole);
    super.dispose();
  }

  /// After a fresh staff sign-in (and device PIN if set), open HQ / partner.
  /// Cold start with an already-signed-in session stays on the customer shell.
  void _maybeOpenStaffConsole() {
    if (!mounted) {
      return;
    }
    final store = _store;
    if (store == null) {
      return;
    }
    if (store.loading) {
      return;
    }
    final pins = DevicePinScope.of(context);
    final uid = store.uid;
    if (uid == null || uid.isEmpty) {
      _openedForUid = null;
      _staffRoutePrimed = true;
      return;
    }
    final live = store.stats;
    final staff = live.isAdmin || live.isBusiness;
    if (pins.needsUnlock(uid: uid, isStaff: staff)) {
      return;
    }
    if (!_staffRoutePrimed) {
      _staffRoutePrimed = true;
      // Restored session: remember uid so we do not push a console over tests/home.
      _openedForUid = uid;
      return;
    }
    if (!staff) {
      return;
    }
    if (_openedForUid == uid) {
      return;
    }
    _openedForUid = uid;
    if (live.isAdmin) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const AdminDashboardScreen(),
        ),
      );
      return;
    }
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
    final uid = store.uid;
    final live = store.stats;
    final staff = live.isAdmin || live.isBusiness;
    // While prefs load, show the shell; switch to unlock once ready.
    if (pins.ready &&
        pins.needsUnlock(uid: uid, isStaff: staff) &&
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
