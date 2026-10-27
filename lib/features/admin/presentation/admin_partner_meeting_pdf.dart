import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:dive_travel_app/core/models/partner_meeting_report.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_report_pdf.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// A4 pages from the same snapshot the preview shows.
Future<Uint8List> buildPartnerMeetingPdf({
  required PartnerMeetingReport report,
  required String shopName,
  required String periodLabel,
  required AppLocalizations l10n,
}) async {
  final data = await rootBundle.load(adminReportFontAsset);
  final font = pw.Font.ttf(data);
  final pdf = pw.Document(
    theme: pw.ThemeData.withFont(base: font, bold: font),
  );
  final sections = report.recipe.sections;
  final snapshot = report.snapshot;
  final period = report.recipe.compare
      ? '$periodLabel · ${l10n.partnerMeetingCompareNote}'
      : periodLabel;
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) {
        return [
          pw.Text(
            l10n.partnerMeetingPaperKicker(shopName),
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            l10n.partnerMeetingPaperTitle,
            style: const pw.TextStyle(fontSize: 18),
          ),
          pw.SizedBox(height: 4),
          pw.Text(period, style: const pw.TextStyle(fontSize: 11)),
          if (sections.conclusion) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              l10n.partnerMeetingConclusion,
              style: const pw.TextStyle(fontSize: 13),
            ),
            pw.SizedBox(height: 4),
            pw.Text(snapshot.conclusion),
          ],
          if (sections.funnel) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              l10n.partnerMeetingFunnel,
              style: const pw.TextStyle(fontSize: 13),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              '${l10n.partnerMeetingOpens} ${snapshot.funnel.opens}    '
              '${l10n.seatBriefViews} ${snapshot.funnel.views}    '
              '${l10n.seatBriefFlags} ${snapshot.funnel.flags}    '
              '${l10n.seatBriefPays} ${snapshot.funnel.pays}',
            ),
            pw.SizedBox(height: 4),
            pw.Text(l10n.seatBriefScoreFill(snapshot.fillPercent)),
            if (snapshot.funnelPrevious != null)
              pw.Text(
                l10n.partnerMeetingPrevious(
                  snapshot.funnelPrevious!.opens,
                  snapshot.funnelPrevious!.views,
                  snapshot.funnelPrevious!.flags,
                  snapshot.funnelPrevious!.pays,
                ),
              ),
          ],
          if (sections.scorecard) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              l10n.seatBriefScoreTitle,
              style: const pw.TextStyle(fontSize: 13),
            ),
            for (final row in snapshot.scoreRows) ...[
              pw.SizedBox(height: 6),
              pw.Text(
                '${row.title}  ${l10n.seatBriefScoreCounts(row.views, row.flags, row.pays)}  '
                '${l10n.seatBriefScoreFill(row.fillPercent)}',
              ),
            ],
          ],
          if (sections.demand && snapshot.demands.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              l10n.seatBriefMissedTitle,
              style: const pw.TextStyle(fontSize: 13),
            ),
            for (final line in snapshot.demands)
              pw.Text('${line.label}  ${line.count}'),
          ],
          if (sections.proposals && snapshot.proposals.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              l10n.partnerMeetingProposals,
              style: const pw.TextStyle(fontSize: 13),
            ),
            for (var i = 0; i < snapshot.proposals.length; i++)
              pw.Text('${i + 1}. ${snapshot.proposals[i]}'),
          ],
        ];
      },
    ),
  );
  return pdf.save();
}
