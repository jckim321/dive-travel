import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/partner_meeting_report.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_partner_meeting_pdf.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';
import 'package:printing/printing.dart';

/// White A4 sheet. Buttons stay outside the paper.
class AdminPartnerMeetingPreview extends StatelessWidget {
  const AdminPartnerMeetingPreview({
    super.key,
    required this.report,
    required this.shopName,
    required this.periodLabel,
    this.onPrint,
    this.readOnly = false,
  });

  final PartnerMeetingReport report;
  final String shopName;
  final String periodLabel;
  final Future<void> Function(Uint8List bytes)? onPrint;

  /// Partner and link views. Save and send stay off the paper.
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final period = report.recipe.compare
        ? '$periodLabel · ${l10n.partnerMeetingCompareNote}'
        : periodLabel;
    return Theme(
      data: AdminConsoleTheme.dark,
      child: Scaffold(
        backgroundColor: AdminConsoleTheme.bg,
        appBar: AppBar(
          title: Text(
            readOnly ? l10n.partnerMeetingInbox : l10n.partnerMeetingPreviewTitle,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Text(
              l10n.partnerMeetingPreviewHint,
              style: const TextStyle(
                color: AdminConsoleTheme.muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return ConstrainedBox(
                      constraints: BoxConstraints(minHeight: width * 297 / 210),
                      child: ColoredBox(
                        key: const Key('partner-meeting-paper'),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
                          child: _PaperBody(
                            report: report,
                            shopName: shopName,
                            period: period,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (readOnly)
              FilledButton.icon(
                key: const Key('partner-meeting-print'),
                style: FilledButton.styleFrom(
                  backgroundColor: AdminConsoleTheme.amber,
                  foregroundColor: AdminConsoleTheme.bg,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => _print(context),
                icon: const Icon(Icons.print_outlined),
                label: Text(l10n.partnerMeetingPrint),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('partner-meeting-print'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AdminConsoleTheme.amber,
                        foregroundColor: AdminConsoleTheme.bg,
                      ),
                      onPressed: () => _print(context),
                      icon: const Icon(Icons.print_outlined),
                      label: Text(l10n.partnerMeetingPrint),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('partner-meeting-save'),
                      onPressed: () => _save(context),
                      icon: const Icon(Icons.bookmark_border),
                      label: Text(l10n.partnerMeetingSave),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('partner-meeting-send'),
                      onPressed: null,
                      icon: const Icon(Icons.send_outlined),
                      label: Text(l10n.partnerMeetingSend),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final store = DiverStoreScope.of(context);
    final id = await store.saveMeetingReport(report);
    if (!context.mounted || id == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).partnerMeetingSaved)),
    );
  }

  Future<void> _print(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bytes = await buildPartnerMeetingPdf(
      report: report,
      shopName: shopName,
      periodLabel: periodLabel,
      l10n: l10n,
    );
    final custom = onPrint;
    if (custom != null) {
      await custom(bytes);
      return;
    }
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
}

class _PaperBody extends StatelessWidget {
  const _PaperBody({
    required this.report,
    required this.shopName,
    required this.period,
  });

  final PartnerMeetingReport report;
  final String shopName;
  final String period;

  static const _ink = Color(0xFF142033);
  static const _muted = Color(0xFF5C6B7A);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sections = report.recipe.sections;
    final snapshot = report.snapshot;
    return DefaultTextStyle(
      style: const TextStyle(color: _ink, fontSize: 14, height: 1.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.partnerMeetingPaperKicker(shopName),
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.partnerMeetingPaperTitle,
            style: const TextStyle(
              color: _ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(period, style: const TextStyle(color: _muted)),
          if (sections.conclusion) ...[
            const SizedBox(height: 20),
            Text(
              l10n.partnerMeetingConclusion,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              snapshot.conclusion,
              key: const Key('partner-meeting-conclusion'),
            ),
          ],
          if (sections.funnel) ...[
            const SizedBox(height: 20),
            Text(
              l10n.partnerMeetingFunnel,
              key: const Key('partner-meeting-funnel'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _Count(
                  label: l10n.partnerMeetingOpens,
                  count: snapshot.funnel.opens,
                ),
                _Count(
                  label: l10n.seatBriefViews,
                  count: snapshot.funnel.views,
                  countKey: const Key('partner-meeting-views'),
                ),
                _Count(
                  label: l10n.seatBriefFlags,
                  count: snapshot.funnel.flags,
                ),
                _Count(label: l10n.seatBriefPays, count: snapshot.funnel.pays),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.seatBriefScoreFill(snapshot.fillPercent)),
            if (snapshot.funnelPrevious != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.partnerMeetingPrevious(
                  snapshot.funnelPrevious!.opens,
                  snapshot.funnelPrevious!.views,
                  snapshot.funnelPrevious!.flags,
                  snapshot.funnelPrevious!.pays,
                ),
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ],
          if (sections.scorecard) ...[
            const SizedBox(height: 20),
            Text(
              l10n.seatBriefScoreTitle,
              key: const Key('partner-meeting-score'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            if (snapshot.scoreRows.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.seatBriefConclusionWait,
                  key: const Key('partner-meeting-score-empty'),
                ),
              )
            else
              for (final row in snapshot.scoreRows)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${row.title}  ${l10n.seatBriefScoreCounts(row.views, row.flags, row.pays)}  '
                    '${l10n.seatBriefScoreFill(row.fillPercent)}',
                  ),
                ),
          ],
          if (sections.demand && snapshot.demands.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              l10n.seatBriefMissedTitle,
              key: const Key('partner-meeting-demand'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            for (final line in snapshot.demands)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('${line.label}  ${line.count}'),
              ),
          ],
          if (sections.proposals && snapshot.proposals.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              l10n.partnerMeetingProposals,
              key: const Key('partner-meeting-proposals'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            for (var i = 0; i < snapshot.proposals.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('${i + 1}. ${snapshot.proposals[i]}'),
              ),
          ],
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.count, this.countKey});

  final String label;
  final int count;
  final Key? countKey;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: _PaperBody._muted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            key: countKey,
            style: const TextStyle(
              color: _PaperBody._ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
