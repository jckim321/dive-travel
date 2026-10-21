import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Approve leftover-seat listings and monitor live same-boat inventory.
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
        final pending = [
          for (final product in store.allShopProducts)
            if (product.hasPendingSameBoat) product,
        ];
        final live = [
          for (final product in store.allShopProducts)
            if (_hasLiveSeats(product)) product,
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
              l10n.adminSameBoatApproveHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: embedded ? AdminConsoleTheme.muted : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.adminSameBoatPendingQueue,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (pending.isEmpty)
              Card(
                color: embedded ? AdminConsoleTheme.surfaceHigh : null,
                child: ListTile(
                  title: Text(
                    l10n.adminSameBoatPendingEmpty,
                    style: TextStyle(
                      color: embedded ? AdminConsoleTheme.muted : null,
                    ),
                  ),
                ),
              )
            else
              for (final product in pending) ...[
                _PendingSameBoatTile(product: product, embedded: embedded),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 20),
            Text(
              l10n.adminSameBoatLiveTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (live.isEmpty)
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
              for (final product in live) ...[
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

bool _hasLiveSeats(ShopProduct product) {
  if (product.listsOnSameBoat) {
    return true;
  }
  for (final option in product.options) {
    if (option.listsOnSameBoat) {
      return true;
    }
  }
  return false;
}

class _PendingSameBoatTile extends StatelessWidget {
  const _PendingSameBoatTile({
    required this.product,
    required this.embedded,
  });

  final ShopProduct product;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final shopName =
        DiveShopCatalog.byId(product.shopId)?.name ?? product.shopId;
    final dayFmt = DateFormat('yyyy.MM.dd');

    return Card(
      color: embedded ? AdminConsoleTheme.surfaceHigh : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              product.name,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: embedded ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              [
                shopName,
                if (product.capacity > 0)
                  l10n.adminSameBoatRemaining(product.capacity),
                if (product.departureStart != null)
                  dayFmt.format(product.departureStart!),
                if (product.flagClosesAt != null)
                  '${l10n.workbenchFlagDeadline} ${dayFmt.format(product.flagClosesAt!)}',
              ].join(' · '),
              style: TextStyle(
                fontSize: 12,
                color: embedded ? AdminConsoleTheme.muted : null,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await store.setSameBoatStatus(
                        shopId: product.shopId,
                        productId: product.id,
                        status: SameBoatStatus.rejected,
                      );
                    },
                    child: Text(l10n.adminSameBoatReject),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    key: Key('admin-same-boat-approve-${product.id}'),
                    onPressed: () async {
                      await store.setSameBoatStatus(
                        shopId: product.shopId,
                        productId: product.id,
                        status: SameBoatStatus.approved,
                      );
                    },
                    child: Text(l10n.adminSameBoatApprove),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SameBoatSeatsScreen(
                      product: product,
                      adminBypassApproval: true,
                    ),
                  ),
                );
              },
              child: Text(l10n.sameBoatSeatsEdit),
            ),
          ],
        ),
      ),
    );
  }
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
            if (deadline != null)
              '${l10n.workbenchFlagDeadline} ${dayFmt.format(deadline)}',
          ].join(' · '),
          style: TextStyle(
            color: embedded ? AdminConsoleTheme.muted : null,
          ),
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SameBoatSeatsScreen(
                  product: product,
                  adminBypassApproval: true,
                ),
              ),
            );
          },
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TravelProductRegistrationScreen(
                lockedShopId: product.shopId,
                existing: product,
              ),
            ),
          );
        },
      ),
    );
  }
}
