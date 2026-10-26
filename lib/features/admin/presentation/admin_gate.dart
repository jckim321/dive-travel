import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/auth/device_pin_controller.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:dive_travel_app/features/auth/presentation/device_pin_dialogs.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

Future<void> openAdminMode(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final store = DiverStoreScope.of(context);
  final session = SessionScope.of(context);
  final pins = DevicePinScope.of(context);
  if (!store.stats.isAdmin) {
    store.lockAdminConsole();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.adminAccessDenied)),
    );
    return;
  }
  final uid = store.uid ?? session.user?.uid ?? '';
  if (uid.isEmpty) {
    return;
  }
  if (!store.adminConsoleUnlocked) {
    final hasPin = pins.hasPin && pins.pinnedUid == uid;
    final unlocked = hasPin
        ? await showDevicePinUnlockDialog(
            context,
            uid: uid,
            onLockedOut: () => _lockOut(context, l10n),
          )
        : await showDevicePinSetupDialog(context, uid: uid);
    if (unlocked != true || !context.mounted) {
      return;
    }
    store.unlockAdminConsole();
  }
  if (!context.mounted) {
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const AdminDashboardScreen(),
    ),
  );
}

Future<void> _lockOut(BuildContext context, AppLocalizations l10n) async {
  final session = SessionScope.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.devicePinLockedOut)),
  );
  await session.signOut();
}
