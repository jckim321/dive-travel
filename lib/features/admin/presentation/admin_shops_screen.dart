import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class AdminShopsScreen extends StatelessWidget {
  const AdminShopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final shops = store.shops;
    final plaque = store.plaqueQueue;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminShopsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            l10n.adminPlaqueQueue,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (plaque.isEmpty)
            Card(child: ListTile(title: Text(l10n.adminPlaqueEmpty)))
          else
            for (final stats in plaque) ...[
              _PlaqueTile(
                shop: DiveShopCatalog.byId(stats.shopId),
                shopId: stats.shopId,
                stars: stats.diveStar,
                rating: stats.avgOverall,
                reviewCount: stats.reviewCount,
                status: stats.plaqueStatus,
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 16),
          Text(
            l10n.adminShopMonitor,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final shop in shops) ...[
            _ShopMonitorTile(shop: shop),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _PlaqueTile extends StatelessWidget {
  const _PlaqueTile({
    required this.shop,
    required this.shopId,
    required this.stars,
    required this.rating,
    required this.reviewCount,
    required this.status,
  });

  final DiveShop? shop;
  final String shopId;
  final int stars;
  final double rating;
  final int reviewCount;
  final PlaqueStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final name = shop?.name ?? shopId;
    final statusLabel = switch (status) {
      PlaqueStatus.queued => l10n.adminPlaqueQueued,
      PlaqueStatus.shipped => l10n.adminPlaqueShipped,
      PlaqueStatus.none => l10n.adminPlaqueNone,
    };

    return Card(
      child: ListTile(
        leading: const Icon(Icons.workspace_premium),
        title: Text(name),
        subtitle: Text(
          '${l10n.exploreDiveStar(stars)} · '
          '${l10n.homeDiveStarSubtitle(rating.toStringAsFixed(1), reviewCount)}\n'
          '$statusLabel',
        ),
        isThreeLine: true,
        trailing: status == PlaqueStatus.shipped
            ? const Icon(Icons.check_circle_outline, color: Color(0xFFC4A35A))
            : FilledButton(
                onPressed: () {
                  store.setPlaqueStatus(
                    shopId: shopId,
                    status: status == PlaqueStatus.queued
                        ? PlaqueStatus.shipped
                        : PlaqueStatus.queued,
                  );
                },
                child: Text(
                  status == PlaqueStatus.queued
                      ? l10n.adminPlaqueMarkShipped
                      : l10n.adminPlaqueRequest,
                ),
              ),
      ),
    );
  }
}

class _ShopMonitorTile extends StatelessWidget {
  const _ShopMonitorTile({required this.shop});

  final DiveShop shop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        title: Text(shop.name),
        subtitle: Text(
          shop.reviewCount > 0
              ? '${shop.location} · ${l10n.exploreDiveStar(shop.stars)} · '
                    '${l10n.homeDiveStarSubtitle(shop.rating.toStringAsFixed(1), shop.reviewCount)}'
              : '${shop.location} · ${l10n.exploreStarPending}',
        ),
        trailing: const Icon(Icons.edit_outlined),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ResortDeskScreen(shopId: shop.hullId),
          ),
        ),
      ),
    );
  }
}
