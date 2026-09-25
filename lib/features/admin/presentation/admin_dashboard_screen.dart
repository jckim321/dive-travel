import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_instructors_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_members_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_posts_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_pricing_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_products_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_shops_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_weather_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

enum _AdminHub { overview, members, certify, shops, ops }

enum _ShopsSub { monitor, products, pricing }

enum _OpsSub { posts, weather }

/// Dive Travel HQ 관리자 콘솔.
/// 상단 1차 탭 + 필요 시 2차 탭, 현황 탭에 KPI·대기 작업·등급 분포.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  _AdminHub _hub = _AdminHub.overview;
  _ShopsSub _shopsSub = _ShopsSub.monitor;
  _OpsSub _opsSub = _OpsSub.posts;

  void _go(_AdminHub hub, {Object? sub}) {
    setState(() {
      _hub = hub;
      if (hub == _AdminHub.shops && sub is _ShopsSub) {
        _shopsSub = sub;
      }
      if (hub == _AdminHub.ops && sub is _OpsSub) {
        _opsSub = sub;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final pending = store.pendingInstructors.length;
    final plaque = store.plaqueQueue.length;
    final hidden = store.posts.where((p) => p.hidden).length;
    final pendingProducts = store.pendingProductApprovals.length;

    return Theme(
      data: AdminConsoleTheme.dark,
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: AdminConsoleTheme.bg,
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.adminHqTitle),
                  Text(
                    l10n.adminHqSubtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AdminConsoleTheme.muted,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(
                    l10n.adminHqClose,
                    style: const TextStyle(
                      color: AdminConsoleTheme.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox.shrink(key: Key('admin-menu-pricing')),
                _PrimaryTabStrip(
                  hub: _hub,
                  pendingCertify: pending,
                  pendingProducts: pendingProducts,
                  onSelect: _go,
                ),
                if (_hub == _AdminHub.shops)
                  _SubTabStrip(
                    labels: [
                      l10n.adminShopsTitle,
                      l10n.adminProductsTab,
                      l10n.adminPricingTitle,
                    ],
                    keys: const [
                      Key('admin-sub-shops'),
                      Key('admin-sub-products'),
                      Key('admin-menu-pricing'),
                    ],
                    selected: switch (_shopsSub) {
                      _ShopsSub.monitor => 0,
                      _ShopsSub.products => 1,
                      _ShopsSub.pricing => 2,
                    },
                    onSelect: (i) => _go(
                      _AdminHub.shops,
                      sub: switch (i) {
                        1 => _ShopsSub.products,
                        2 => _ShopsSub.pricing,
                        _ => _ShopsSub.monitor,
                      },
                    ),
                  ),
                if (_hub == _AdminHub.ops)
                  _SubTabStrip(
                    labels: [
                      l10n.adminPostsTitle,
                      l10n.weatherAdminTitle,
                    ],
                    keys: const [
                      Key('admin-sub-posts'),
                      Key('admin-menu-weather'),
                    ],
                    selected: _opsSub == _OpsSub.posts ? 0 : 1,
                    onSelect: (i) => _go(
                      _AdminHub.ops,
                      sub: i == 0 ? _OpsSub.posts : _OpsSub.weather,
                    ),
                  ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: KeyedSubtree(
                      key: ValueKey('${_hub.name}-$_shopsSub-$_opsSub'),
                      child: _bodyFor(
                        l10n: l10n,
                        store: store,
                        pending: pending,
                        plaque: plaque,
                        hidden: hidden,
                        pendingProducts: pendingProducts,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _bodyFor({
    required AppLocalizations l10n,
    required DiverStore store,
    required int pending,
    required int plaque,
    required int hidden,
    required int pendingProducts,
  }) {
    switch (_hub) {
      case _AdminHub.overview:
        return _OverviewPane(
          onJump: _go,
          memberCount: store.members.length,
          pendingCertify: pending,
          plaqueCount: plaque,
          postCount: store.posts.length,
          hiddenCount: hidden,
          shopCount: store.shops.length,
          pendingProducts: pendingProducts,
          members: store.members,
        );
      case _AdminHub.members:
        return const AdminMembersScreen(embedded: true);
      case _AdminHub.certify:
        return const AdminInstructorsScreen(embedded: true);
      case _AdminHub.shops:
        return switch (_shopsSub) {
          _ShopsSub.monitor => const AdminShopsScreen(embedded: true),
          _ShopsSub.products => const AdminProductsScreen(embedded: true),
          _ShopsSub.pricing => const AdminPricingScreen(embedded: true),
        };
      case _AdminHub.ops:
        return _opsSub == _OpsSub.posts
            ? const AdminPostsScreen(embedded: true)
            : const AdminWeatherScreen(embedded: true);
    }
  }
}

class _PrimaryTabStrip extends StatelessWidget {
  const _PrimaryTabStrip({
    required this.hub,
    required this.pendingCertify,
    required this.pendingProducts,
    required this.onSelect,
  });

  final _AdminHub hub;
  final int pendingCertify;
  final int pendingProducts;
  final void Function(_AdminHub hub, {Object? sub}) onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabs = <(_AdminHub, IconData, String, int)>[
      (_AdminHub.overview, Icons.dashboard_outlined, l10n.adminTabOverview, 0),
      (_AdminHub.members, Icons.groups_outlined, l10n.adminTabMembers, 0),
      (
        _AdminHub.certify,
        Icons.verified_user_outlined,
        l10n.adminTabCertify,
        pendingCertify,
      ),
      (
        _AdminHub.shops,
        Icons.storefront_outlined,
        l10n.adminTabShops,
        pendingProducts,
      ),
      (_AdminHub.ops, Icons.tune_outlined, l10n.adminTabOps, 0),
    ];

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (id, icon, label, badge) = tabs[index];
          final selected = hub == id;
          return _PrimaryTabChip(
            key: switch (id) {
              _AdminHub.members => const Key('admin-menu-members'),
              _AdminHub.certify => const Key('admin-menu-instructors'),
              _AdminHub.shops => const Key('admin-menu-shops'),
              _AdminHub.ops => const Key('admin-menu-posts'),
              _AdminHub.overview => const Key('admin-tab-overview'),
            },
            icon: icon,
            label: label,
            selected: selected,
            badge: badge,
            onTap: () => onSelect(id),
          );
        },
      ),
    );
  }
}

class _PrimaryTabChip extends StatelessWidget {
  const _PrimaryTabChip({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AdminConsoleTheme.aqua.withValues(alpha: 0.16)
          : AdminConsoleTheme.surfaceHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 78,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AdminConsoleTheme.aqua
                  : AdminConsoleTheme.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected
                        ? AdminConsoleTheme.aqua
                        : AdminConsoleTheme.muted,
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -10,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AdminConsoleTheme.danger,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge > 9 ? '9+' : '$badge',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AdminConsoleTheme.aqua
                      : AdminConsoleTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubTabStrip extends StatelessWidget {
  const _SubTabStrip({
    required this.labels,
    required this.selected,
    required this.onSelect,
    this.keys = const [],
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;
  final List<Key> keys;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Material(
                color: selected == i
                    ? AdminConsoleTheme.aqua
                    : AdminConsoleTheme.surface,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  key: i < keys.length ? keys[i] : null,
                  onTap: () => onSelect(i),
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: selected == i
                            ? AdminConsoleTheme.bg
                            : AdminConsoleTheme.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OverviewPane extends StatelessWidget {
  const _OverviewPane({
    required this.onJump,
    required this.memberCount,
    required this.pendingCertify,
    required this.plaqueCount,
    required this.postCount,
    required this.hiddenCount,
    required this.shopCount,
    required this.pendingProducts,
    required this.members,
  });

  final void Function(_AdminHub hub, {Object? sub}) onJump;
  final int memberCount;
  final int pendingCertify;
  final int plaqueCount;
  final int postCount;
  final int hiddenCount;
  final int shopCount;
  final int pendingProducts;
  final List<MemberAccount> members;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gradeCounts = <MemberGrade, int>{
      for (final g in MemberGrade.valuesInOrder) g: 0,
    };
    for (final m in members) {
      gradeCounts[m.grade] = (gradeCounts[m.grade] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Text(
          l10n.adminDashboardTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(l10n.adminDashboardSubtitle),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _MetricCard(
              label: l10n.adminMetricMembers,
              value: '$memberCount',
              accent: AdminConsoleTheme.aqua,
              onTap: () => onJump(_AdminHub.members),
            ),
            _MetricCard(
              label: l10n.adminMetricPendingCert,
              value: '$pendingCertify',
              accent: pendingCertify > 0
                  ? AdminConsoleTheme.danger
                  : AdminConsoleTheme.ice,
              onTap: () => onJump(_AdminHub.certify),
            ),
            _MetricCard(
              label: l10n.adminMetricPlaques,
              value: '$plaqueCount',
              accent: AdminConsoleTheme.amber,
              onTap: () => onJump(_AdminHub.shops, sub: _ShopsSub.monitor),
            ),
            _MetricCard(
              label: l10n.adminProductsTab,
              value: '$pendingProducts',
              accent: pendingProducts > 0
                  ? AdminConsoleTheme.danger
                  : AdminConsoleTheme.aqua,
              onTap: () => onJump(_AdminHub.shops, sub: _ShopsSub.products),
            ),
            _MetricCard(
              label: l10n.adminMetricPosts,
              value: '$postCount',
              accent: AdminConsoleTheme.ice,
              hint: hiddenCount > 0
                  ? l10n.adminMetricHidden(hiddenCount)
                  : null,
              onTap: () => onJump(_AdminHub.ops, sub: _OpsSub.posts),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          icon: Icons.bolt_outlined,
          title: l10n.adminAttentionTitle,
        ),
        const SizedBox(height: 10),
        if (pendingCertify == 0 &&
            plaqueCount == 0 &&
            hiddenCount == 0 &&
            pendingProducts == 0)
          _EmptyAttention(message: l10n.adminAttentionClear)
        else ...[
          if (pendingCertify > 0)
            _AttentionTile(
              icon: Icons.verified_user_outlined,
              title: l10n.adminAttentionCertify(pendingCertify),
              color: AdminConsoleTheme.danger,
              onTap: () => onJump(_AdminHub.certify),
            ),
          if (pendingProducts > 0) ...[
            const SizedBox(height: 8),
            _AttentionTile(
              icon: Icons.add_box_outlined,
              title: '${l10n.adminProductPendingQueue} · $pendingProducts',
              color: AdminConsoleTheme.danger,
              onTap: () => onJump(_AdminHub.shops, sub: _ShopsSub.products),
            ),
          ],
          if (plaqueCount > 0) ...[
            const SizedBox(height: 8),
            _AttentionTile(
              icon: Icons.workspace_premium_outlined,
              title: l10n.adminAttentionPlaque(plaqueCount),
              color: AdminConsoleTheme.amber,
              onTap: () => onJump(_AdminHub.shops, sub: _ShopsSub.monitor),
            ),
          ],
          if (hiddenCount > 0) ...[
            const SizedBox(height: 8),
            _AttentionTile(
              icon: Icons.visibility_off_outlined,
              title: l10n.adminAttentionHidden(hiddenCount),
              color: AdminConsoleTheme.ice,
              onTap: () => onJump(_AdminHub.ops, sub: _OpsSub.posts),
            ),
          ],
        ],
        const SizedBox(height: 20),
        _SectionHeader(
          icon: Icons.bar_chart_rounded,
          title: l10n.adminGradeMixTitle,
        ),
        const SizedBox(height: 10),
        _GradeMixCard(
          counts: gradeCounts,
          labels: {
            MemberGrade.member: l10n.memberGradeMember,
            MemberGrade.special: l10n.memberGradeSpecial,
            MemberGrade.vip: l10n.memberGradeVip,
            MemberGrade.instructor: l10n.memberGradeInstructor,
          },
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          icon: Icons.grid_view_rounded,
          title: l10n.adminQuickActions,
        ),
        const SizedBox(height: 10),
        _QuickAction(
          icon: Icons.percent,
          title: l10n.adminPricingTitle,
          subtitle: l10n.adminPricingSubtitle,
          onTap: () => onJump(_AdminHub.shops, sub: _ShopsSub.pricing),
        ),
        const SizedBox(height: 8),
        _QuickAction(
          icon: Icons.thunderstorm_outlined,
          title: l10n.weatherAdminTitle,
          subtitle: l10n.weatherAdminBody,
          onTap: () => onJump(_AdminHub.ops, sub: _OpsSub.weather),
        ),
        const SizedBox(height: 8),
        _QuickAction(
          icon: Icons.storefront_outlined,
          title: l10n.adminShopsTitle,
          subtitle: l10n.adminMetricShops(shopCount),
          onTap: () => onJump(_AdminHub.shops, sub: _ShopsSub.monitor),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.onTap,
    this.hint,
  });

  final String label;
  final String value;
  final Color accent;
  final VoidCallback onTap;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminConsoleTheme.surfaceHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AdminConsoleTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AdminConsoleTheme.muted,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: accent,
                  height: 1,
                ),
              ),
              if (hint != null) ...[
                const SizedBox(height: 4),
                Text(
                  hint!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AdminConsoleTheme.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AdminConsoleTheme.aqua),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AdminConsoleTheme.text,
          ),
        ),
      ],
    );
  }
}

class _EmptyAttention extends StatelessWidget {
  const _EmptyAttention({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminConsoleTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminConsoleTheme.border),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AdminConsoleTheme.muted),
      ),
    );
  }
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeMixCard extends StatelessWidget {
  const _GradeMixCard({required this.counts, required this.labels});

  final Map<MemberGrade, int> counts;
  final Map<MemberGrade, String> labels;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final max = counts.values.fold<int>(1, (a, b) => a > b ? a : b);
    const colors = {
      MemberGrade.member: AdminConsoleTheme.muted,
      MemberGrade.special: AdminConsoleTheme.ice,
      MemberGrade.vip: AdminConsoleTheme.amber,
      MemberGrade.instructor: AdminConsoleTheme.aqua,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AdminConsoleTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminConsoleTheme.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final grade in MemberGrade.valuesInOrder) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${counts[grade] ?? 0}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: colors[grade],
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            height: total == 0
                                ? 8
                                : 16 +
                                    72 *
                                        ((counts[grade] ?? 0) / max),
                            decoration: BoxDecoration(
                              color: colors[grade],
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: (colors[grade] ?? Colors.white)
                                      .withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final grade in MemberGrade.valuesInOrder)
                Expanded(
                  child: Text(
                    labels[grade] ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AdminConsoleTheme.muted,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminConsoleTheme.surfaceHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AdminConsoleTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AdminConsoleTheme.aqua.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AdminConsoleTheme.aqua, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AdminConsoleTheme.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AdminConsoleTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AdminConsoleTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
