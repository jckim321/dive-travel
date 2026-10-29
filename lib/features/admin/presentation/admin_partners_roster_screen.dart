import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
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

enum PartnerGradeCard {
  all,
  regular,
  star1,
  star2,
  star3,
  other,
}

/// 한 리조트는 한 칸. 활동 중지·계약종료·폐업은 기타, 활동중만 등급.
/// 등급 0(심사 전)은 일반파트너.
PartnerGradeCard partnerRosterBucket(ShopLiveStats stats) {
  if (!stats.operatingStatus.acceptsCustomers) {
    return PartnerGradeCard.other;
  }
  return switch (stats.diveStar) {
    1 => PartnerGradeCard.star1,
    2 => PartnerGradeCard.star2,
    3 => PartnerGradeCard.star3,
    _ => PartnerGradeCard.regular,
  };
}

/// 회원관리 «제휴 리조트» — 등급 카드와 샵 목록.
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
  PartnerGradeCard _grade = PartnerGradeCard.all;
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
    if (_grade == PartnerGradeCard.all) return true;
    return partnerRosterBucket(stats) == _grade;
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
                child: _GradeGrid(
                  shops: store.shopStats,
                  selected: _grade,
                  onSelect: (grade) => setState(() => _grade = grade),
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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    if (plaque.isNotEmpty && _grade == PartnerGradeCard.all) ...[
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

class _GradeGrid extends StatelessWidget {
  const _GradeGrid({
    required this.shops,
    required this.selected,
    required this.onSelect,
  });

  final List<ShopLiveStats> shops;
  final PartnerGradeCard selected;
  final ValueChanged<PartnerGradeCard> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    int count(PartnerGradeCard card) {
      return shops.where((shop) => partnerRosterBucket(shop) == card).length;
    }

    final cards = <_GradeSpec>[
      _GradeSpec(PartnerGradeCard.all, l10n.adminPartnerTierAll, Icons.circle_outlined, Colors.white, shops.length),
      _GradeSpec(PartnerGradeCard.regular, l10n.adminPartnerGradeRegular, Icons.storefront_outlined, AdminConsoleTheme.aqua, count(PartnerGradeCard.regular)),
      _GradeSpec(PartnerGradeCard.star1, l10n.adminPartnerGradeDiveStar, Icons.star, _diveStarYellow, count(PartnerGradeCard.star1), stars: 1),
      _GradeSpec(PartnerGradeCard.star2, l10n.adminPartnerGradeDiveStar, Icons.star, _diveStarYellow, count(PartnerGradeCard.star2), stars: 2),
      _GradeSpec(PartnerGradeCard.star3, l10n.adminPartnerGradeDiveStar, Icons.star, _diveStarYellow, count(PartnerGradeCard.star3), stars: 3),
      _GradeSpec(PartnerGradeCard.other, l10n.adminPartnerGradeOther, Icons.pause_circle_outline, AdminConsoleTheme.muted, count(PartnerGradeCard.other)),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      mainAxisExtent: 92,
      children: [
        for (final card in cards)
          _GradeCard(
            spec: card,
            selected: selected == card.grade,
            onTap: () => onSelect(card.grade),
          ),
      ],
    );
  }
}

const _diveStarYellow = Color(0xFFFFE14A);

class _GradeSpec {
  const _GradeSpec(
    this.grade,
    this.label,
    this.icon,
    this.color,
    this.count, {
    this.stars = 0,
  });

  final PartnerGradeCard grade;
  final String label;
  final IconData icon;
  final Color color;
  final int count;

  /// 다이브스타 카드만 숫자 위에 이 개수만큼 노란 별을 그린다.
  final int stars;
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _GradeSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminConsoleTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('admin-partner-grade-${spec.grade.name}'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFFE2B15A) : AdminConsoleTheme.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              spec.stars > 0
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < spec.stars; i++) ...[
                            if (i > 0) const SizedBox(width: 1),
                            const Icon(Icons.star, size: 14, color: _diveStarYellow),
                          ],
                        ],
                      ),
                    )
                  : Icon(spec.icon, size: 14, color: spec.color),
              const SizedBox(height: 4),
              Text(
                '${spec.count}',
                style: TextStyle(
                  color: spec.color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                spec.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
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
