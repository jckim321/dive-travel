import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class AdminShopsScreen extends StatelessWidget {
  const AdminShopsScreen({
    super.key,
    this.embedded = false,
    this.onOpenProducts,
  });

  final bool embedded;
  final ValueChanged<String>? onOpenProducts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final shops = store.shops;
        final plaque = store.plaqueQueue;

        return adminScreenShell(
          embedded: embedded,
          title: l10n.adminShopsTitle,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(
                l10n.adminPartnersGradeHint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: embedded ? AdminConsoleTheme.muted : null,
                ),
              ),
              const SizedBox(height: 16),
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
                    internalScore: stats.internalScore,
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
                _ShopMonitorTile(
                  shop: shop,
                  internalScore:
                      store.liveStatsFor(shop.hullId)?.internalScore ??
                      store.liveStatsFor(shop.id)?.internalScore ??
                      0,
                  onOpenProducts: onOpenProducts,
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
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
    required this.internalScore,
  });

  final DiveShop? shop;
  final String shopId;
  final int stars;
  final double rating;
  final int reviewCount;
  final PlaqueStatus status;
  final int internalScore;

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
          '${l10n.adminInternalScore} $internalScore · $statusLabel',
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
  const _ShopMonitorTile({
    required this.shop,
    required this.internalScore,
    this.onOpenProducts,
  });

  final DiveShop shop;
  final int internalScore;
  final ValueChanged<String>? onOpenProducts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        title: Text(shop.name),
        subtitle: Text(
          shop.reviewCount > 0
              ? '${shop.location} · ${l10n.exploreDiveStar(shop.stars)} · '
                    '${l10n.homeDiveStarSubtitle(shop.rating.toStringAsFixed(1), shop.reviewCount)} · '
                    '${l10n.adminInternalScore} $internalScore'
              : '${shop.location} · ${l10n.exploreStarPending} · '
                    '${l10n.adminInternalScore} $internalScore',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'products') {
              onOpenProducts?.call(shop.hullId);
              return;
            }
            if (value == 'desk') {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ResortDeskScreen(shopId: shop.hullId),
                ),
              );
              return;
            }
            if (value == 'score') {
              await _editInternalScore(context, shop.hullId, internalScore);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'products',
              child: Text(l10n.adminViewShopProducts),
            ),
            PopupMenuItem(
              value: 'score',
              child: Text(l10n.adminInternalScoreEdit),
            ),
            PopupMenuItem(
              value: 'desk',
              child: Text(l10n.exploreEditResort),
            ),
          ],
        ),
        onTap: onOpenProducts == null
            ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ResortDeskScreen(shopId: shop.hullId),
                ),
              )
            : () => onOpenProducts!(shop.hullId),
      ),
    );
  }
}

Future<void> _editInternalScore(
  BuildContext context,
  String shopId,
  int current,
) async {
  final l10n = AppLocalizations.of(context);
  final store = DiverStoreScope.of(context);
  final controller = TextEditingController(text: current > 0 ? '$current' : '');
  final score = await showDialog<int>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.adminInternalScoreEdit),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: l10n.adminInternalScore,
            hintText: l10n.adminInternalScoreHint,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.adminHqClose),
          ),
          FilledButton(
            onPressed: () {
              final raw = int.tryParse(controller.text.trim()) ?? 0;
              Navigator.pop(context, raw.clamp(0, 100));
            },
            child: Text(l10n.briefSave),
          ),
        ],
      );
    },
  );
  controller.dispose();
  if (score == null || !context.mounted) {
    return;
  }
  await store.setInternalScore(shopId: shopId, score: score);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.adminInternalScoreSaved)),
    );
  }
}
