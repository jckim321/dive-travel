import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_partner_shop_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Member linked to this shop. A business owner wins over a leftover link.
MemberAccount? partnerMemberForShop(List<MemberAccount> members, String shopId) {
  final id = shopId.trim();
  MemberAccount? fallback;
  for (final member in members) {
    if (member.ownedShopId.trim() != id) {
      continue;
    }
    if (member.isBusiness) {
      return member;
    }
    fallback ??= member;
  }
  return fallback;
}

String partnerShopDisplayName(ShopLiveStats stats) {
  final name = (stats.name ?? '').trim();
  return name.isEmpty ? stats.shopId : name;
}

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
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final store = DiverStoreScope.of(context);
      unawaited(store.ensureShopStatsLoaded());
      unawaited(store.ensureAdminInboxLoaded());
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _matches(ShopLiveStats stats) {
    switch (_tier) {
      case PartnerTierFilter.all:
        return true;
      case PartnerTierFilter.reviewPending:
        return stats.reviewCount == 0;
      case PartnerTierFilter.star1:
        return stats.diveStar == 1;
      case PartnerTierFilter.star2:
        return stats.diveStar == 2;
      case PartnerTierFilter.star3:
        return stats.diveStar == 3;
      case PartnerTierFilter.needsAction:
        return stats.reviewCount == 0 || stats.plaqueStatus == PlaqueStatus.queued;
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
        final needle = _query.text.trim().toLowerCase();
        final filtered = [
          for (final stats in store.shopStats)
            if (_matches(stats) &&
                _searchHit(stats, store.members, needle))
              stats,
        ]..sort(
            (a, b) => partnerShopDisplayName(a).compareTo(partnerShopDisplayName(b)),
          );

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
                child: TextField(
                  key: const Key('admin-partners-search'),
                  controller: _query,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.adminPartnersSearch,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
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
                      PopupMenuButton<PartnerTierFilter>(
                        key: const Key('admin-partner-tier-more'),
                        tooltip: l10n.adminFilterMore,
                        onSelected: (value) => setState(() => _tier = value),
                        itemBuilder: (context) => [
                          for (final entry in <(PartnerTierFilter, String)>[
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
                          ])
                            PopupMenuItem(
                              value: entry.$1,
                              child: Text(entry.$2),
                            ),
                        ],
                        child: Chip(
                          label: Text(
                            {
                                  PartnerTierFilter.star1,
                                  PartnerTierFilter.star2,
                                  PartnerTierFilter.star3,
                                }.contains(_tier)
                                ? switch (_tier) {
                                    PartnerTierFilter.star1 =>
                                      l10n.adminPartnerTierStar1,
                                    PartnerTierFilter.star2 =>
                                      l10n.adminPartnerTierStar2,
                                    _ => l10n.adminPartnerTierStar3,
                                  }
                                : l10n.adminFilterMore,
                          ),
                          avatar: const Icon(Icons.expand_more, size: 16),
                        ),
                      ),
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
                      for (final stats in filtered) ...[
                        _RosterShopTile(
                          stats: stats,
                          owner: partnerMemberForShop(store.members, stats.shopId),
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

bool _searchHit(ShopLiveStats stats, List<MemberAccount> members, String needle) {
  if (needle.isEmpty) {
    return true;
  }
  final owner = partnerMemberForShop(members, stats.shopId);
  final haystack = [
    partnerShopDisplayName(stats),
    stats.shopId,
    stats.location ?? '',
    owner?.displayName ?? '',
    owner?.listHandle ?? '',
  ].join(' ').toLowerCase();
  return haystack.contains(needle);
}

class _RosterShopTile extends StatelessWidget {
  const _RosterShopTile({
    required this.stats,
    required this.owner,
    this.onOpenProducts,
  });

  final ShopLiveStats stats;
  final MemberAccount? owner;
  final ValueChanged<String>? onOpenProducts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rep = _shown(owner?.displayName ?? '');
    final handle = _shown(owner?.listHandle ?? '');
    final status = shopOperatingStatusLabel(l10n, stats.operatingStatus);
    return Card(
      child: ListTile(
        key: Key('admin-partner-row-${stats.shopId}'),
        title: Text(partnerShopDisplayName(stats)),
        subtitle: Text(
          '${l10n.adminPartnerRepresentative} $rep · '
          '${l10n.adminPartnerLoginId} $handle · $status',
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AdminPartnerShopScreen(
                shopId: stats.shopId,
                onOpenProducts: onOpenProducts,
              ),
            ),
          );
        },
      ),
    );
  }
}

String _shown(String raw) {
  final value = raw.trim();
  return value.isEmpty ? '—' : value;
}
