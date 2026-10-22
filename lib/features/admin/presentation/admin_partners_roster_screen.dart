import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_dive_star_assessment_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

enum PartnerTierFilter {
  all,
  reviewPending,
  star1,
  star2,
  star3,
  needsAction,
}

/// 회원관리 «제휴파트너» — 샵 리스트 + Dive Star / 리뷰전 / 조치필요 칩.
class AdminPartnersRosterScreen extends StatefulWidget {
  const AdminPartnersRosterScreen({
    super.key,
    this.embedded = false,
    this.onOpenProducts,
  });

  final bool embedded;
  final ValueChanged<String>? onOpenProducts;

  @override
  State<AdminPartnersRosterScreen> createState() =>
      _AdminPartnersRosterScreenState();
}

class _AdminPartnersRosterScreenState extends State<AdminPartnersRosterScreen> {
  PartnerTierFilter _tier = PartnerTierFilter.all;

  bool _matches(DiveShop shop, ShopLiveStats? stats) {
    final reviews = stats?.reviewCount ?? shop.reviewCount;
    final stars = stats?.diveStar ?? shop.stars;
    final plaque = stats?.plaqueStatus ?? PlaqueStatus.none;
    switch (_tier) {
      case PartnerTierFilter.all:
        return true;
      case PartnerTierFilter.reviewPending:
        return reviews == 0;
      case PartnerTierFilter.star1:
        return stars == 1;
      case PartnerTierFilter.star2:
        return stars == 2;
      case PartnerTierFilter.star3:
        return stars == 3;
      case PartnerTierFilter.needsAction:
        return reviews == 0 || plaque == PlaqueStatus.queued;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final plaque = store.plaqueQueue;
        final filtered = [
          for (final shop in store.shops)
            if (_matches(
              shop,
              store.liveStatsFor(shop.hullId) ?? store.liveStatsFor(shop.id),
            ))
              shop,
        ];

        return adminScreenShell(
          embedded: widget.embedded,
          title: l10n.adminMembersSubPartners,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.embedded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.adminMembersSubPartners,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final entry in <(PartnerTierFilter, String)>[
                        (PartnerTierFilter.all, l10n.adminPartnerTierAll),
                        (
                          PartnerTierFilter.needsAction,
                          l10n.adminMembersNeedsAction,
                        ),
                        (
                          PartnerTierFilter.reviewPending,
                          l10n.adminPartnerTierReviewPending,
                        ),
                        (
                          PartnerTierFilter.star1,
                          l10n.adminPartnerTierStar1,
                        ),
                        (
                          PartnerTierFilter.star2,
                          l10n.adminPartnerTierStar2,
                        ),
                        (
                          PartnerTierFilter.star3,
                          l10n.adminPartnerTierStar3,
                        ),
                      ]) ...[
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            key: Key('admin-partner-tier-${entry.$1.name}'),
                            label: Text(entry.$2),
                            selected: _tier == entry.$1,
                            onSelected: (_) =>
                                setState(() => _tier = entry.$1),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    if (plaque.isNotEmpty &&
                        (_tier == PartnerTierFilter.all ||
                            _tier == PartnerTierFilter.needsAction)) ...[
                      Text(
                        l10n.adminPlaqueQueue,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      for (final stats in plaque) ...[
                        _RosterPlaqueTile(
                          shopId: stats.shopId,
                          stars: stats.diveStar,
                          rating: stats.avgOverall,
                          reviewCount: stats.reviewCount,
                          status: stats.plaqueStatus,
                          internalScore: stats.internalScore,
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 12),
                    ],
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Center(child: Text(l10n.adminPartnerTierEmpty)),
                      )
                    else
                      for (final shop in filtered) ...[
                        _RosterShopTile(
                          shop: shop,
                          internalScore:
                              store.liveStatsFor(shop.hullId)?.internalScore ??
                              store.liveStatsFor(shop.id)?.internalScore ??
                              0,
                          onOpenProducts: widget.onOpenProducts,
                        ),
                        const SizedBox(height: 8),
                      ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RosterPlaqueTile extends StatelessWidget {
  const _RosterPlaqueTile({
    required this.shopId,
    required this.stars,
    required this.rating,
    required this.reviewCount,
    required this.status,
    required this.internalScore,
  });

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
    final name = DiveShopCatalog.byId(shopId)?.name ?? shopId;
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

class _RosterShopTile extends StatelessWidget {
  const _RosterShopTile({
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
              return;
            }
            if (value == 'dive_star_assess') {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AdminDiveStarAssessmentScreen(
                    shopId: shop.hullId,
                    shopName: shop.name,
                  ),
                ),
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'products',
              child: Text(l10n.adminViewShopProducts),
            ),
            PopupMenuItem(
              value: 'dive_star_assess',
              child: Text(l10n.adminDiveStarAssessmentMenu),
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
