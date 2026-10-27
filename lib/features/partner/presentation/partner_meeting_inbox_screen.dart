import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/partner_meeting_report.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_partner_meeting_preview.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_meeting_read_store.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Shared reports for this partner's shop. The list query keeps both filters.
class PartnerMeetingInboxScreen extends StatefulWidget {
  const PartnerMeetingInboxScreen({
    super.key,
    this.shopName = '',
    this.readStore,
  });

  final String shopName;
  final PartnerMeetingReadStore? readStore;

  @override
  State<PartnerMeetingInboxScreen> createState() =>
      _PartnerMeetingInboxScreenState();
}

class _PartnerMeetingInboxScreenState extends State<PartnerMeetingInboxScreen> {
  var _loading = true;
  List<PartnerMeetingReport> _reports = const [];
  late final PartnerMeetingReadStore _reads =
      widget.readStore ?? PrefsPartnerMeetingReadStore();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final store = DiverStoreScope.of(context);
    final owned = store.stats.ownedShopId ?? '';
    try {
      final rows = await store.listSharedMeetingReports(owned);
      if (!mounted) {
        return;
      }
      setState(() {
        _reports = rows;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('meeting inbox failed $error');
      debugPrint('$stackTrace');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _open(PartnerMeetingReport report) async {
    await _reads.markRead(report.id);
    if (!mounted) {
      return;
    }
    final named = widget.shopName.trim();
    final shopName = named.isEmpty ? report.recipe.hullId : named;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminPartnerMeetingPreview(
          report: report,
          shopName: shopName,
          periodLabel: meetingReportPeriodLabel(report.recipe),
          readOnly: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PartnerTheme.wrap(
      Scaffold(
        backgroundColor: PartnerTheme.bg,
        appBar: AppBar(title: Text(l10n.partnerMeetingInbox)),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _reports.isEmpty
            ? Center(
                child: Text(
                  l10n.partnerMeetingInboxEmpty,
                  key: const Key('partner-meeting-inbox-empty'),
                ),
              )
            : ListView(
                key: const Key('partner-meeting-inbox-list'),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  for (final report in _reports)
                    ListTile(
                      key: Key('partner-meeting-inbox-row-${report.id}'),
                      title: Text(meetingReportPeriodLabel(report.recipe)),
                      subtitle: Text(
                        meetingReportCreatedLabel(report.createdAt),
                      ),
                      onTap: () => _open(report),
                    ),
                ],
              ),
      ),
    );
  }
}
