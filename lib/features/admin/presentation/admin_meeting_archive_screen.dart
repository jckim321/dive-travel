import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/partner_meeting_report.dart';
import 'package:dive_travel_app/core/models/seat_brief.dart';
import 'package:dive_travel_app/core/models/seat_life.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_partner_meeting_preview.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_partner_meeting_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Saved meeting reports. Send and unsend stay here. Rebuild does not copy numbers.
class AdminMeetingArchiveScreen extends StatefulWidget {
  const AdminMeetingArchiveScreen({super.key, this.now});

  final DateTime? now;

  @override
  State<AdminMeetingArchiveScreen> createState() =>
      _AdminMeetingArchiveScreenState();
}

class _AdminMeetingArchiveScreenState extends State<AdminMeetingArchiveScreen> {
  var _loading = true;
  List<PartnerMeetingReport> _reports = const [];

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _copyLink(PartnerMeetingReport report) async {
    final url = meetingReportShareUrl(Uri.base, report.id);
    try {
      await Clipboard.setData(ClipboardData(text: url));
    } catch (error, stackTrace) {
      debugPrint('meeting report link copy failed $error');
      debugPrint('$stackTrace');
      return;
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).partnerMeetingLinkCopied),
      ),
    );
  }

  Future<void> _load() async {
    final store = DiverStoreScope.of(context);
    try {
      await store.ensureShopStatsLoaded();
      final rows = await store.listMeetingReports();
      if (!mounted) {
        return;
      }
      setState(() {
        _reports = rows;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('meeting archive failed $error');
      debugPrint('$stackTrace');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _share(PartnerMeetingReport report, bool shared) async {
    final store = DiverStoreScope.of(context);
    final ok = await store.setMeetingReportShared(
      id: report.id,
      shared: shared,
      at: _now,
    );
    if (!mounted) {
      return;
    }
    if (!ok) {
      debugPrint('meeting report share failed ${report.id}');
      return;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shared ? l10n.partnerMeetingSent : l10n.partnerMeetingUnsent,
        ),
      ),
    );
    await _load();
  }

  Future<void> _open(PartnerMeetingReport report) async {
    final store = DiverStoreScope.of(context);
    try {
      await store.ensureShopStatsLoaded();
    } catch (error, stackTrace) {
      debugPrint('meeting archive shop failed $error');
      debugPrint('$stackTrace');
    }
    if (!mounted) {
      return;
    }
    final shop = _shop(store, report.recipe.hullId);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminPartnerMeetingPreview(
          report: report,
          shopName: shop == null ? report.recipe.hullId : _label(shop),
          periodLabel: meetingReportPeriodLabel(report.recipe),
        ),
      ),
    );
  }

  Future<void> _again(PartnerMeetingReport saved) async {
    final store = DiverStoreScope.of(context);
    final recipe = saved.recipe.nextMonth();
    final from = DateTime(
      recipe.periodStart.year,
      recipe.periodStart.month,
      recipe.periodStart.day,
    );
    final to = DateTime(
      recipe.periodEnd.year,
      recipe.periodEnd.month,
      recipe.periodEnd.day,
    ).add(const Duration(days: 1));
    try {
      final events = await store.seatEventsBetween(from: from, to: to);
      final demands = await store.seatDemandsBetween(from: from, to: to);
      final earlier = seatBriefPreviousWindow(
        SeatBriefWindow(start: from, end: to),
      );
      final List<SeatLifeEvent> previous = recipe.compare
          ? await store.seatEventsBetween(from: earlier.start, to: earlier.end)
          : const <SeatLifeEvent>[];
      await store.ensureShopStatsLoaded();
      if (!mounted) {
        return;
      }
      final shop = _shop(store, recipe.hullId);
      final report = buildPartnerMeetingReport(
        id: 'preview',
        recipe: recipe,
        events: events,
        demands: demands,
        seats: shop == null ? const [] : meetingReportSeats(shop),
        createdAt: _now,
        previousEvents: previous,
      );
      final name = shop == null ? recipe.hullId : _label(shop);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AdminPartnerMeetingPreview(
            report: report,
            shopName: name,
            periodLabel: meetingReportPeriodLabel(recipe),
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('meeting report rebuild failed $error');
      debugPrint('$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    return Theme(
      data: AdminConsoleTheme.dark,
      child: Scaffold(
        backgroundColor: AdminConsoleTheme.bg,
        appBar: AppBar(title: Text(l10n.partnerMeetingArchive)),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _reports.isEmpty
            ? Center(child: Text(l10n.partnerMeetingArchiveEmpty))
            : ListView(
                key: const Key('partner-meeting-archive-list'),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  for (final report in _reports)
                    _ArchiveRow(
                      report: report,
                      name: _partnerName(store, report.recipe.hullId),
                      range: meetingReportPeriodLabel(report.recipe),
                      onOpen: () => _open(report),
                      onAgain: () => _again(report),
                      onSend: () => _share(report, true),
                      onUnsend: () => _share(report, false),
                      onCopyLink: () => _copyLink(report),
                    ),
                ],
              ),
      ),
    );
  }
}

class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({
    required this.report,
    required this.name,
    required this.range,
    required this.onOpen,
    required this.onAgain,
    required this.onSend,
    required this.onUnsend,
    required this.onCopyLink,
  });

  final PartnerMeetingReport report;
  final String name;
  final String range;
  final VoidCallback onOpen;
  final VoidCallback onAgain;
  final VoidCallback onSend;
  final VoidCallback onUnsend;
  final VoidCallback onCopyLink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sent = report.shared;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            key: Key('partner-meeting-archive-row-${report.id}'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                meetingReportCreatedLabel(report.createdAt),
                key: Key('partner-meeting-archive-date-${report.id}'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: sent ? AdminConsoleTheme.amber : AdminConsoleTheme.border,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  sent ? l10n.partnerMeetingSentBadge : l10n.partnerMeetingDraft,
                  key: Key('partner-meeting-archive-status-${report.id}'),
                  style: TextStyle(
                    color: sent ? AdminConsoleTheme.bg : AdminConsoleTheme.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                range,
                style: const TextStyle(
                  color: AdminConsoleTheme.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: Key('partner-meeting-archive-open-${report.id}'),
                onPressed: onOpen,
                child: Text(l10n.partnerMeetingPreviewTitle),
              ),
              OutlinedButton(
                key: Key('partner-meeting-archive-again-${report.id}'),
                onPressed: onAgain,
                child: Text(l10n.partnerMeetingAgain),
              ),
              if (!report.shared)
                FilledButton(
                  key: Key('partner-meeting-archive-send-${report.id}'),
                  onPressed: onSend,
                  child: Text(l10n.partnerMeetingSend),
                )
              else
                OutlinedButton(
                  key: Key('partner-meeting-archive-unsend-${report.id}'),
                  onPressed: onUnsend,
                  child: Text(l10n.partnerMeetingUnsend),
                ),
              OutlinedButton(
                key: Key('partner-meeting-copy-link-${report.id}'),
                onPressed: onCopyLink,
                child: Text(l10n.partnerMeetingCopyLink),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _partnerName(DiverStore store, String hull) {
  final shop = _shop(store, hull);
  if (shop == null) {
    return hull;
  }
  return _label(shop);
}

ShopLiveStats? _shop(DiverStore store, String hull) {
  for (final stats in store.shopStats) {
    if (partnerShopHull(stats.shopId) == hull) {
      return stats;
    }
  }
  return null;
}

String _label(ShopLiveStats shop) {
  final name = (shop.name ?? '').trim();
  return name.isEmpty ? shop.shopId : name;
}
