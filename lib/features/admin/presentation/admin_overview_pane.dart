import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/dive_star_application.dart';
import 'package:dive_travel_app/core/models/partner_contract.dart';
import 'package:dive_travel_app/core/models/partner_promotion.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/features/admin/overview/admin_overview_metrics.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Admin home. Reads ranged shop bookings and the newest five per shop.
///
/// When the shop count grows, replace the per-shop listeners with one
/// aggregated latest-bookings document instead of one subscription each.
class AdminOverviewPane extends StatefulWidget {
  const AdminOverviewPane({
    super.key,
    required this.onOpenInstructors,
    required this.onOpenContracts,
    required this.onOpenDiveStarReview,
    required this.onOpenBookings,
    required this.onOpenProducts,
    required this.onOpenProposals,
  });

  final VoidCallback onOpenInstructors;
  final VoidCallback onOpenContracts;
  final VoidCallback onOpenDiveStarReview;
  final VoidCallback onOpenBookings;
  final VoidCallback onOpenProducts;
  final VoidCallback onOpenProposals;

  @override
  State<AdminOverviewPane> createState() => _AdminOverviewPaneState();
}

class _AdminOverviewPaneState extends State<AdminOverviewPane> {
  final _liveByShop = <String, List<TourBooking>>{};
  final _subs = <StreamSubscription<List<TourBooking>>>[];
  List<TourBooking> _bookings = const [];
  List<PartnerContract> _contracts = const [];
  List<DiveStarApplication> _applications = const [];
  var _newProposals = 0;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final store = DiverStoreScope.of(context);
    try {
      await store.ensureShopStatsLoaded();
      await store.ensureAdminInboxLoaded();
      if (!mounted) {
        return;
      }
      final now = DateTime.now();
      final windows = AdminOverviewWindows.of(now);
      final batches = <List<TourBooking>>[];
      final contracts = <PartnerContract>[];
      for (final stats in store.shopStats) {
        final id = stats.shopId;
        batches.add(
          await store.fetchShopBookingsCreatedBetween(
            shopId: id,
            start: windows.recentStart,
            end: windows.recentEnd,
          ),
        );
        batches.add(
          await store.fetchShopBookingsCreatedBetween(
            shopId: id,
            start: windows.previousMonthStart,
            end: windows.previousMonthEnd,
          ),
        );
        batches.add(
          await store.fetchShopBookingsCreatedBetween(
            shopId: id,
            start: windows.yearAgoMonthStart,
            end: windows.yearAgoMonthEnd,
          ),
        );
        batches.add(
          await store.fetchShopBookingsCreatedBetween(
            shopId: id,
            start: windows.yearAgoChartStart,
            end: windows.yearAgoChartEnd,
          ),
        );
        batches.add(
          await store.fetchShopBookingsCancelledBetween(
            shopId: id,
            start: windows.cancelStart,
            end: windows.cancelEnd,
          ),
        );
        contracts.addAll(await store.listPartnerContracts(id));
      }
      final applications = await store.listDiveStarApplications();
      final proposals = await store.loadPartnerPromotionInbox();
      if (!mounted) {
        return;
      }
      _listen(store);
      setState(() {
        _bookings = mergeOverviewBookings(batches);
        _contracts = contracts;
        _applications = applications;
        _newProposals = countIncomingPartnerPromotions(proposals);
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  void _listen(DiverStore store) {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    _liveByShop.clear();
    for (final stats in store.shopStats) {
      final id = stats.shopId;
      _subs.add(
        store.watchLatestShopBookings(id).listen((rows) {
          if (!mounted) {
            return;
          }
          setState(() => _liveByShop[id] = rows);
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final now = DateTime.now();
    final figures = _loading
        ? AdminOverviewFigures.empty
        : buildAdminOverviewFigures(bookings: _bookings, now: now);
    final alert = _loading
        ? null
        : evaluateAdminOverviewAlert(bookings: _bookings, now: now);
    final certify = store.pendingInstructors.length;
    final awaiting = _contracts
        .where((item) => item.status == PartnerContractStatus.awaitingSignature)
        .length;
    final reviews = _applications
        .where((item) => item.pipelineStatus == DiveStarPipelineStatus.underReview)
        .length;
    final products = store.pendingProductApprovals.length;
    final activity = buildAdminActivity(
      now: now,
      members: store.members,
      bookings: _bookings,
      contracts: _contracts,
      applications: _applications,
    );
    final live = latestLiveBookings(_liveByShop);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final header = _Header(
          l10n: l10n,
          alert: alert,
          figures: figures,
          wide: wide,
          loading: _loading,
          error: _error,
        );
        final queue = _QueueSection(
          l10n: l10n,
          certify: certify,
          awaiting: awaiting,
          reviews: reviews,
          products: products,
          proposals: _newProposals,
          onOpenInstructors: widget.onOpenInstructors,
          onOpenContracts: widget.onOpenContracts,
          onOpenDiveStarReview: widget.onOpenDiveStarReview,
          onOpenProducts: widget.onOpenProducts,
          onOpenProposals: widget.onOpenProposals,
        );
        final chart = _ChartCard(
          title: wide ? l10n.adminOverviewChart30 : l10n.adminOverviewChart14,
          values: wide ? figures.last30Net : figures.last14Net,
          compare: wide && figures.hasYearAgoChart
              ? figures.last30YearAgoNet
              : null,
          missingCompare: wide && !figures.hasYearAgoChart,
          bars: !wide,
          compareLabel: l10n.adminOverviewPriorYear,
          missingLabel: l10n.adminOverviewNoCompare,
        );
        final liveCard = _LiveCard(
          l10n: l10n,
          bookings: live,
          members: store.members,
          onSeeAll: widget.onOpenBookings,
        );
        final feed = _ActivityCard(l10n: l10n, items: activity);
        if (!wide) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              header,
              const SizedBox(height: 16),
              queue,
              const SizedBox(height: 16),
              chart,
              const SizedBox(height: 16),
              liveCard,
              const SizedBox(height: 16),
              feed,
            ],
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: ListView(
                        children: [
                          chart,
                          const SizedBox(height: 16),
                          liveCard,
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ListView(
                        children: [
                          queue,
                          const SizedBox(height: 16),
                          feed,
                        ],
                      ),
                    ),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.l10n,
    required this.alert,
    required this.figures,
    required this.wide,
    required this.loading,
    required this.error,
  });

  final AppLocalizations l10n;
  final AdminOverviewAlert? alert;
  final AdminOverviewFigures figures;
  final bool wide;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricCard(
        cardKey: const Key('admin-overview-today-bookings'),
        label: l10n.adminOverviewTodayBookings,
        value: _count(figures.todayCount),
        detail: _countDelta(
          figures.todayCount,
          figures.yesterdayCount,
          l10n,
        ),
        detailColor: _deltaColor(figures.todayCount - figures.yesterdayCount),
      ),
      _MetricCard(
        cardKey: const Key('admin-overview-today-paid'),
        label: l10n.adminOverviewTodayPaid,
        value: _won(figures.todayGross),
        detail: _moneyDelta(
          figures.todayGross,
          figures.yesterdayGross,
          l10n,
        ),
        detailColor: _deltaColor(figures.todayGross - figures.yesterdayGross),
      ),
      _MetricCard(
        cardKey: const Key('admin-overview-today-cancel'),
        label: l10n.adminOverviewTodayCancel,
        value: '${_count(figures.todayCancelCount)} · ${_won(figures.todayRefund)}',
        detail: alert?.cancelSpike == true
            ? l10n.adminOverviewMoreThanUsual
            : l10n.adminOverviewRefund,
        detailColor: figures.todayCancelCount > 0
            ? AdminConsoleTheme.danger
            : AdminConsoleTheme.muted,
      ),
      _MetricCard(
        cardKey: const Key('admin-overview-month'),
        label: l10n.adminOverviewMonthSales,
        value: _won(figures.monthNet),
        detail: _monthDetail(figures, l10n),
        detailColor: _deltaColor(figures.monthNet - figures.previousMonthNet),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (loading)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(error!, style: const TextStyle(color: AdminConsoleTheme.danger)),
          ),
        if (alert != null) ...[
          _AlertBanner(l10n: l10n, alert: alert!),
          const SizedBox(height: 12),
        ],
        if (wide)
          Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: cards[i]),
              ],
            ],
          )
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.15,
            children: cards,
          ),
        const SizedBox(height: 8),
        Text(
          l10n.adminOverviewBasis,
          key: const Key('admin-overview-basis'),
          style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
        ),
      ],
    );
  }

  String _count(int value) {
    final unit = l10n.adminOverviewCountUnit;
    if (unit.isEmpty) {
      return '$value';
    }
    return '$value$unit';
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.l10n, required this.alert});

  final AppLocalizations l10n;
  final AdminOverviewAlert alert;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      if (alert.cancelSpike)
        '${l10n.adminOverviewCancelSpike} ${alert.todayCancels}${l10n.adminOverviewCountUnit}',
      if (alert.droppingShops.isNotEmpty)
        '${l10n.adminOverviewWeekDrop}: ${alert.droppingShops.join(', ')}',
    ];
    return Container(
      key: const Key('admin-overview-alert'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AdminConsoleTheme.amber.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminConsoleTheme.amber),
      ),
      child: Text(
        lines.join('\n'),
        style: const TextStyle(
          color: AdminConsoleTheme.amber,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.cardKey,
    required this.label,
    required this.value,
    required this.detail,
    required this.detailColor,
  });

  final Key cardKey;
  final String label;
  final String value;
  final String detail;
  final Color detailColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: cardKey,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminConsoleTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminConsoleTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AdminConsoleTheme.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: detailColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _QueueSection extends StatelessWidget {
  const _QueueSection({
    required this.l10n,
    required this.certify,
    required this.awaiting,
    required this.reviews,
    required this.products,
    required this.proposals,
    required this.onOpenInstructors,
    required this.onOpenContracts,
    required this.onOpenDiveStarReview,
    required this.onOpenProducts,
    required this.onOpenProposals,
  });

  final AppLocalizations l10n;
  final int certify;
  final int awaiting;
  final int reviews;
  final int products;
  final int proposals;
  final VoidCallback onOpenInstructors;
  final VoidCallback onOpenContracts;
  final VoidCallback onOpenDiveStarReview;
  final VoidCallback onOpenProducts;
  final VoidCallback onOpenProposals;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _QueueTile(
        tileKey: const Key('admin-overview-queue-certify'),
        label: l10n.adminOverviewQueueCertify,
        value: '$certify',
        dim: certify == 0,
        onTap: onOpenInstructors,
      ),
      _QueueTile(
        tileKey: const Key('admin-overview-queue-sign'),
        label: l10n.adminOverviewQueueSign,
        value: '$awaiting',
        dim: awaiting == 0,
        onTap: onOpenContracts,
      ),
      _QueueTile(
        tileKey: const Key('admin-overview-queue-divestar'),
        label: l10n.adminOverviewQueueDiveStar,
        value: '$reviews',
        dim: reviews == 0,
        onTap: onOpenDiveStarReview,
      ),
      _QueueTile(
        tileKey: const Key('admin-overview-queue-proposal'),
        label: l10n.adminOverviewQueueProposal,
        value: '$proposals',
        dim: proposals == 0,
        onTap: onOpenProposals,
      ),
      if (products >= 1)
        _QueueTile(
          tileKey: const Key('admin-overview-queue-products'),
          label: l10n.adminOverviewQueueProducts,
          value: '$products',
          dim: false,
          onTap: onOpenProducts,
        ),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminConsoleTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminConsoleTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adminOverviewQueueTitle,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.1,
            children: tiles,
          ),
        ],
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    required this.tileKey,
    required this.label,
    required this.value,
    required this.dim,
    required this.onTap,
  });

  final Key tileKey;
  final String label;
  final String value;
  final bool dim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dim ? 0.4 : 1,
      child: Material(
        color: AdminConsoleTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: tileKey,
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AdminConsoleTheme.muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.values,
    required this.compare,
    required this.missingCompare,
    required this.bars,
    required this.compareLabel,
    required this.missingLabel,
  });

  final String title;
  final List<int> values;
  final List<int>? compare;
  final bool missingCompare;
  final bool bars;
  final String compareLabel;
  final String missingLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('admin-overview-chart'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminConsoleTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminConsoleTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (!bars && compare != null)
            Text(
              compareLabel,
              style: const TextStyle(color: AdminConsoleTheme.ice, fontSize: 12),
            ),
          if (missingCompare)
            Text(
              missingLabel,
              key: const Key('admin-overview-no-compare'),
              style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
            ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: _SalesPainter(
                values: values,
                compare: compare,
                bars: bars,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesPainter extends CustomPainter {
  _SalesPainter({
    required this.values,
    required this.compare,
    required this.bars,
  });

  final List<int> values;
  final List<int>? compare;
  final bool bars;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }
    var max = 1;
    for (final value in values) {
      if (value > max) {
        max = value;
      }
    }
    final prior = compare;
    if (prior != null) {
      for (final value in prior) {
        if (value > max) {
          max = value;
        }
      }
    }
    if (bars) {
      final gap = 4.0;
      final width = (size.width - gap * (values.length - 1)) / values.length;
      final paint = Paint()..color = AdminConsoleTheme.aqua;
      for (var i = 0; i < values.length; i++) {
        final h = size.height * (values[i] / max);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              i * (width + gap),
              size.height - h,
              width,
              h,
            ),
            const Radius.circular(3),
          ),
          paint,
        );
      }
      return;
    }
    _line(canvas, size, values, AdminConsoleTheme.aqua, max);
    if (prior != null && prior.length == values.length) {
      _line(canvas, size, prior, AdminConsoleTheme.ice, max);
    }
  }

  void _line(Canvas canvas, Size size, List<int> series, Color color, int max) {
    final path = Path();
    for (var i = 0; i < series.length; i++) {
      final x = series.length == 1
          ? size.width / 2
          : size.width * i / (series.length - 1);
      final y = size.height - size.height * (series[i] / max);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _SalesPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.compare != compare ||
        oldDelegate.bars != bars;
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({
    required this.l10n,
    required this.bookings,
    required this.members,
    required this.onSeeAll,
  });

  final AppLocalizations l10n;
  final List<TourBooking> bookings;
  final List<MemberAccount> members;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('admin-overview-live'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminConsoleTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminConsoleTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.adminOverviewLive,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                key: const Key('admin-overview-see-all'),
                onPressed: onSeeAll,
                child: Text(l10n.adminOverviewSeeAll),
              ),
            ],
          ),
          if (bookings.isEmpty)
            Text(
              l10n.adminOverviewLiveEmpty,
              style: const TextStyle(color: AdminConsoleTheme.muted),
            )
          else
            for (final booking in bookings) _LiveRow(l10n: l10n, booking: booking, members: members),
        ],
      ),
    );
  }
}

class _LiveRow extends StatelessWidget {
  const _LiveRow({
    required this.l10n,
    required this.booking,
    required this.members,
  });

  final AppLocalizations l10n;
  final TourBooking booking;
  final List<MemberAccount> members;

  @override
  Widget build(BuildContext context) {
    final badge = liveBadgeFor(booking);
    final (label, color) = switch (badge) {
      AdminLiveBadge.paid => (l10n.adminOverviewPaid, AdminConsoleTheme.aqua),
      AdminLiveBadge.cancelled => (
          l10n.adminOverviewCancelled,
          AdminConsoleTheme.danger,
        ),
      AdminLiveBadge.partialRefund => (
          l10n.adminOverviewPartial,
          AdminConsoleTheme.amber,
        ),
      AdminLiveBadge.other => ('', AdminConsoleTheme.muted),
    };
    final shop = booking.shopName.trim();
    final product = booking.productName.trim();
    final place = [
      if (shop.isNotEmpty) shop,
      if (product.isNotEmpty) product,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              _hhmm(booking.createdAt),
              style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_guest(booking, members, l10n)),
                if (place.isNotEmpty)
                  Text(
                    place,
                    style: const TextStyle(
                      color: AdminConsoleTheme.muted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(_won(booking.price)),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.l10n, required this.items});

  final AppLocalizations l10n;
  final List<AdminActivityItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('admin-overview-activity'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminConsoleTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminConsoleTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adminOverviewActivity,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              l10n.adminOverviewActivityEmpty,
              style: const TextStyle(color: AdminConsoleTheme.muted),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${_hhmm(item.at)}  ${_kind(l10n, item.kind)}  ${item.label}',
                ),
              ),
          const SizedBox(height: 8),
          Text(
            l10n.adminOverviewActivityGap,
            key: const Key('admin-overview-activity-gap'),
            style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

String _kind(AppLocalizations l10n, AdminActivityKind kind) {
  return switch (kind) {
    AdminActivityKind.signup => l10n.adminOverviewJoin,
    AdminActivityKind.refund => l10n.adminOverviewRefund,
    AdminActivityKind.signature => l10n.adminOverviewSigned,
    AdminActivityKind.diveStar => l10n.adminOverviewApplied,
  };
}

String _guest(
  TourBooking booking,
  List<MemberAccount> members,
  AppLocalizations l10n,
) {
  if (booking.guestDisplayName.trim().isNotEmpty) {
    return booking.guestDisplayName.trim();
  }
  for (final member in members) {
    if (member.uid == booking.uid && member.displayName.trim().isNotEmpty) {
      return member.displayName.trim();
    }
  }
  return l10n.adminOverviewNoName;
}

String _hhmm(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _won(int value) {
  final formatted = NumberFormat.decimalPattern('ko').format(value.abs());
  final sign = value < 0 ? '-' : '';
  return '$sign₩$formatted';
}

String _countDelta(int today, int yesterday, AppLocalizations l10n) {
  final delta = today - yesterday;
  if (delta == 0) {
    return l10n.adminOverviewSameAsYesterday;
  }
  final sign = delta > 0 ? '+' : '';
  return '${l10n.adminOverviewVsYesterday} $sign$delta';
}

String _moneyDelta(int today, int yesterday, AppLocalizations l10n) {
  if (yesterday <= 0) {
    return l10n.adminOverviewNoCompare;
  }
  final pct = (((today - yesterday) / yesterday) * 100).round();
  final sign = pct > 0 ? '+' : '';
  return '${l10n.adminOverviewVsYesterday} $sign$pct%';
}

String _monthDetail(AdminOverviewFigures figures, AppLocalizations l10n) {
  final month = _percentPhrase(
    figures.monthNet,
    figures.previousMonthNet,
    l10n.adminOverviewVsMonth,
    l10n.adminOverviewNoCompare,
  );
  final year = figures.hasYearAgoMonth
      ? _percentPhrase(
          figures.monthNet,
          figures.yearAgoMonthNet,
          l10n.adminOverviewVsYear,
          l10n.adminOverviewNoCompare,
        )
      : '${l10n.adminOverviewVsYear} ${l10n.adminOverviewNoCompare}';
  return '$month\n$year';
}

String _percentPhrase(int now, int then, String label, String missing) {
  if (then <= 0) {
    return '$label $missing';
  }
  final pct = (((now - then) / then) * 100).round();
  final sign = pct > 0 ? '+' : '';
  return '$label $sign$pct%';
}

Color _deltaColor(int delta) {
  if (delta > 0) {
    return AdminConsoleTheme.aqua;
  }
  if (delta < 0) {
    return AdminConsoleTheme.danger;
  }
  return AdminConsoleTheme.muted;
}
