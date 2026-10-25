import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_star_application.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_dive_star_milestone.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_documents_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_product_menu_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_radar_painter.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_settlement_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_stats_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_voucher_logic.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_vouchers_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class PartnerDashboardScreen extends StatefulWidget {
  const PartnerDashboardScreen({super.key});

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen> {
  List<DiveStarApplication> _apps = const [];
  var _docsBadge = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadApps());
  }

  Future<void> _loadApps() async {
    if (!mounted) {
      return;
    }
    final store = DiverStoreScope.of(context);
    final shopId = store.partnerOwnedShopId;
    final uid = store.uid?.trim() ?? '';
    try {
      final list = uid.isEmpty
          ? const <DiveStarApplication>[]
          : await store.listDiveStarApplications(partnerUid: uid);
      var badge = 0;
      try {
        final contracts = await store.listPartnerContracts(
          shopId,
          forPartner: true,
        );
        badge = store.partnerContractAwaitingCount(contracts);
      } catch (_) {
        badge = 0;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _apps = list;
        _docsBadge = badge;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _apps = const [];
        _docsBadge = 0;
      });
    }
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return PartnerTheme.wrap(
      Scaffold(
        body: SafeArea(
          child: ListenableBuilder(
            listenable: store,
            builder: (context, _) {
              final shopId = store.partnerOwnedShopId;
              final shop = DiveShopCatalog.byId(shopId);
              final live = store.liveStatsFor(shopId);
              final shopName = live?.name ?? shop?.name ?? shopId;
              final step = PartnerDiveStarMilestone.resolve(
                diveStarGrade: live?.diveStar ?? 0,
                latestApplication: PartnerDiveStarMilestone.latestForShop(
                  _apps,
                  shopId,
                ),
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _HomeHeader(
                    shopName: shopName,
                    onShopInfo: () => _open(
                      ResortDeskScreen(shopId: shopId, partnerMode: true),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _QuickGrid(
                    onProducts: () => _open(
                      const PartnerProductMenuScreen(),
                    ),
                    onBookings: () =>
                        _open(PartnerVouchersScreen(shopId: shopId)),
                    bookingsBadge: partnerVoucherUnreadArrivedCount(
                      store.shopBookings,
                    ),
                    onStats: () => _open(PartnerStatsScreen(shopId: shopId)),
                    onDocs: () => _open(const PartnerDocumentsScreen()),
                    docsBadge: _docsBadge,
                  ),
                  const SizedBox(height: 14),
                  _BusinessHighlight(
                    milestoneStep: step,
                    avgOverall: live?.avgOverall ?? 0,
                    reviewCount: live?.reviewCount ?? 0,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('partner-home-settlement'),
                      onPressed: () => _open(
                        PartnerSettlementScreen(shopId: shopId),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: PartnerTheme.accent,
                        foregroundColor: PartnerTheme.bg,
                      ),
                      child: Text(
                        l10n.partnerQuickSettlement,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.shopName,
    required this.onShopInfo,
  });

  final String shopName;
  final VoidCallback onShopInfo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          key: const Key('partner-home-exit'),
          icon: const Icon(
            Icons.chevron_left,
            color: PartnerTheme.text,
            size: 28,
          ),
          tooltip: l10n.partnerExit,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          visualDensity: VisualDensity.compact,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.partnerTitle,
                style: const TextStyle(
                  color: PartnerTheme.textDim,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                shopName,
                style: const TextStyle(
                  color: PartnerTheme.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton(
          key: const Key('partner-home-shop-info'),
          onPressed: onShopInfo,
          child: Text(l10n.partnerHomeShopInfo),
        ),
      ],
    );
  }
}

class _QuickGrid extends StatelessWidget {
  const _QuickGrid({
    required this.onProducts,
    required this.onBookings,
    required this.bookingsBadge,
    required this.onStats,
    required this.onDocs,
    this.docsBadge = 0,
  });

  final VoidCallback onProducts;
  final VoidCallback onBookings;
  final int bookingsBadge;
  final VoidCallback onStats;
  final VoidCallback onDocs;
  final int docsBadge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _QuickTile(
            key: const Key('partner-quick-products'),
            label: l10n.partnerQuickProducts,
            icon: Icons.inventory_2_outlined,
            onTap: onProducts,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickTile(
            key: const Key('partner-quick-bookings'),
            label: l10n.partnerQuickBookings,
            icon: Icons.confirmation_number_outlined,
            badgeCount: bookingsBadge,
            onTap: onBookings,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickTile(
            key: const Key('partner-quick-stats'),
            label: l10n.partnerQuickStats,
            icon: Icons.bar_chart_outlined,
            onTap: onStats,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickTile(
            key: const Key('partner-quick-docs'),
            label: l10n.partnerQuickDocs,
            icon: Icons.description_outlined,
            badgeCount: docsBadge,
            onTap: onDocs,
          ),
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PartnerTheme.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PartnerTheme.border),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: PartnerTheme.accent, size: 22),
                  if (badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        key: const Key('partner-quick-bookings-badge'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: PartnerTheme.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: const TextStyle(
                            color: PartnerTheme.bg,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PartnerTheme.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessHighlight extends StatelessWidget {
  const _BusinessHighlight({
    required this.milestoneStep,
    required this.avgOverall,
    required this.reviewCount,
  });

  final PartnerDiveStarMilestoneStep milestoneStep;
  final double avgOverall;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      key: const Key('partner-business-highlight'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: PartnerTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PartnerTheme.orange, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.partnerBusinessHighlightTitle,
            style: const TextStyle(
              color: PartnerTheme.text,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.partnerHighlightJourney,
            style: const TextStyle(
              color: PartnerTheme.textDim,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 110,
            child: CustomPaint(
              painter: const PartnerRadarPainter(),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    l10n.partnerHighlightEmptyMetrics,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: PartnerTheme.textDim,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.partnerHighlightBookingHits,
            style: const TextStyle(
              color: PartnerTheme.textDim,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.partnerHighlightEmptyMetrics,
            style: const TextStyle(color: PartnerTheme.textDim, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.partnerHighlightPromoHits,
            style: const TextStyle(
              color: PartnerTheme.textDim,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.partnerHighlightEmptyMetrics,
            style: const TextStyle(color: PartnerTheme.textDim, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.partnerHighlightMilestoneTitle,
            style: const TextStyle(
              color: PartnerTheme.textDim,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _MilestoneStepper(current: milestoneStep),
          const SizedBox(height: 14),
          Text(
            l10n.partnerHighlightReviewsTitle,
            style: const TextStyle(
              color: PartnerTheme.textDim,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _ReviewRow(avgOverall: avgOverall, reviewCount: reviewCount),
        ],
      ),
    );
  }
}

class _MilestoneStepper extends StatelessWidget {
  const _MilestoneStepper({required this.current});

  final PartnerDiveStarMilestoneStep current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.partnerMilestoneGeneral,
      l10n.partnerMilestonePreReview,
      l10n.partnerMilestoneOneStar,
      l10n.partnerMilestoneTwoStar,
      l10n.partnerMilestoneThreeStar,
    ];
    final currentIndex = PartnerDiveStarMilestoneStep.values.indexOf(current);
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: i <= currentIndex
                    ? PartnerTheme.accent
                    : PartnerTheme.border,
              ),
            ),
          _MilestoneNode(
            label: labels[i],
            state: i < currentIndex
                ? _NodeState.done
                : (i == currentIndex ? _NodeState.current : _NodeState.todo),
          ),
        ],
      ],
    );
  }
}

enum _NodeState { done, current, todo }

class _MilestoneNode extends StatefulWidget {
  const _MilestoneNode({required this.label, required this.state});

  final String label;
  final _NodeState state;

  @override
  State<_MilestoneNode> createState() => _MilestoneNodeState();
}

class _MilestoneNodeState extends State<_MilestoneNode>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _MilestoneNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _syncPulse();
    }
  }

  bool get _isWidgetTestBinding {
    // Avoid importing flutter_test from lib/; settle tests never end on .repeat().
    return WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
  }

  void _syncPulse() {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final wantPulse = widget.state == _NodeState.current &&
        !reduce &&
        !_isWidgetTestBinding;
    if (wantPulse) {
      _pulse ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      );
      if (!_pulse!.isAnimating) {
        _pulse!.repeat(reverse: true);
      }
    } else {
      _pulse?.stop();
      _pulse?.value = 1;
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.state == _NodeState.done;
    final current = widget.state == _NodeState.current;
    final color = done
        ? PartnerTheme.accent
        : (current ? PartnerTheme.orange : PartnerTheme.borderStrong);

    Widget dot = Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done || current ? color.withValues(alpha: 0.25) : PartnerTheme.bg,
        border: Border.all(color: color, width: 2),
      ),
      child: done
          ? const Icon(Icons.check, size: 14, color: PartnerTheme.accent)
          : null,
    );

    if (current && _pulse != null) {
      dot = FadeTransition(
        opacity: Tween<double>(begin: 0.45, end: 1).animate(_pulse!),
        child: dot,
      );
    }

    return SizedBox(
      width: 52,
      child: Column(
        children: [
          dot,
          const SizedBox(height: 4),
          Text(
            widget.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: current ? PartnerTheme.orange : PartnerTheme.textDim,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.avgOverall, required this.reviewCount});

  final double avgOverall;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (reviewCount <= 0) {
      return Text(
        l10n.partnerHighlightNoReviews,
        style: const TextStyle(color: PartnerTheme.textDim, fontSize: 13),
      );
    }
    final rating = (avgOverall * 10).round() / 10;
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating.round() ? Icons.star : Icons.star_border,
            size: 18,
            color: PartnerTheme.orange,
          ),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: PartnerTheme.text,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          l10n.partnerHighlightReviewCount(reviewCount),
          style: const TextStyle(color: PartnerTheme.textDim, fontSize: 12),
        ),
      ],
    );
  }
}
