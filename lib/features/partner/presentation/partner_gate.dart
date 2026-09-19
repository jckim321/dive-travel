import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_dashboard_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

Future<void> openPartnerMode(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final store = DiverStoreScope.of(context);
  if (!store.stats.isBusiness) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.partnerAccessDenied)),
    );
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const PartnerDashboardScreen(),
    ),
  );
}
