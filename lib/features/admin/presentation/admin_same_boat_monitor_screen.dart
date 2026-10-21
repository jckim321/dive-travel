import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Read-only board: seats opened by registrants; admin monitors only.
class AdminSameBoatMonitorScreen extends StatelessWidget {
  const AdminSameBoatMonitorScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final open = [
          for (final product in store.allShopProducts)
            if (_hasOpenSeats(product)) product,
        ]..sort((a, b) {
          final aStart = a.departureStart ?? DateTime(9999);
          final bStart = b.departureStart ?? DateTime(9999);
          return aStart.compareTo(bStart);
        });

        final body = ListView(
          key: const Key('admin-same-boat-monitor'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              l10n.adminSameBoatHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: embedded ? AdminConsoleTheme.muted : null,
              ),
            ),
            const SizedBox(height: 16),
            if (open.isEmpty)
              Card(
                color: embedded ? AdminConsoleTheme.surfaceHigh : null,
                child: ListTile(
                  title: Text(
                    l10n.adminSameBoatEmpty,
                    style: TextStyle(
                      color: embedded ? AdminConsoleTheme.muted : null,
                    ),
                  ),
                ),
              )
            else
              for (final product in open) ...[
                _SameBoatTile(product: product, embedded: embedded),
                const SizedBox(height: 8),
              ],
          ],
        );

        return adminScreenShell(
          embedded: embedded,
          title: l10n.adminSameBoatTitle,
          body: body,
        );
      },
    );
  }
}

bool _hasOpenSeats(ShopProduct product) {
  if (product.openEmptySeats) {
    return true;
  }
  for (final option in product.options) {
    if (option.openEmptySeats) {
      return true;
    }
  }
  return false;
}

class _SameBoatTile extends StatelessWidget {
  const _SameBoatTile({required this.product, required this.embedded});

  final ShopProduct product;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shopName =
        DiveShopCatalog.byId(product.shopId)?.name ?? product.shopId;
    final remaining = product.remainingSeats;
    final flagged = product.flaggedSeats;
    final departure = product.departureStart;
    final deadline = product.flagClosesAt;
    final dayFmt = DateFormat('yyyy.MM.dd');

    return Card(
      color: embedded ? AdminConsoleTheme.surfaceHigh : null,
      child: ListTile(
        leading: Icon(
          Icons.directions_boat_outlined,
          color: embedded ? AdminConsoleTheme.aqua : null,
        ),
        title: Text(
          product.name,
          style: TextStyle(
            color: embedded ? Colors.white : null,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          [
            shopName,
            l10n.adminSameBoatRemaining(remaining),
            l10n.adminSameBoatFlagged(flagged),
            if (departure != null) dayFmt.format(departure),
            if (deadline != null) 'flag ${dayFmt.format(deadline)}',
          ].join(' · '),
          style: TextStyle(
            color: embedded ? AdminConsoleTheme.muted : null,
            fontSize: 12,
          ),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                TravelProductRegistrationScreen(existing: product),
          ),
        ),
      ),
    );
  }
}
