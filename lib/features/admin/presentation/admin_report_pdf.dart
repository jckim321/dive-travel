import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:dive_travel_app/features/admin/analytics/admin_report_math.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Loaded only when the reader asks for a PDF. Not a startup font.
const adminReportFontAsset = 'assets/fonts/NotoSansKR-Regular.ttf';

Future<Uint8List> buildAdminReportPdf(
  AdminReportDocument document,
  AppLocalizations l10n,
) async {
  final data = await rootBundle.load(adminReportFontAsset);
  final font = pw.Font.ttf(data);
  final pdf = pw.Document(
    theme: pw.ThemeData.withFont(base: font, bold: font),
  );
  final totals = document.snapshot.totals;
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) {
        return [
          pw.Text(
            '${l10n.adminReportHeading}  ${document.periodLabel}',
            style: const pw.TextStyle(fontSize: 18),
          ),
          pw.SizedBox(height: 12),
          if (document.showSummary) ...[
            pw.Text(l10n.adminReportSummary, style: const pw.TextStyle(fontSize: 14)),
            pw.Text('${l10n.adminSalesGross} ${_pdfWon(totals.gross)}'),
            pw.Text('${l10n.adminSalesRefund} ${_pdfWon(totals.refund)}'),
            pw.Text('${l10n.adminSalesNet} ${_pdfWon(totals.net)}'),
            pw.SizedBox(height: 10),
          ],
          if (document.showTrend) ...[
            pw.Text(l10n.adminReportTrend, style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 4),
            pw.Text(
              '${l10n.adminSalesNet} ${_pdfWon(document.dailyNet.fold<int>(0, (a, b) => a + b))}',
            ),
            pw.SizedBox(height: 10),
          ],
          if (document.showPartners) ...[
            pw.Text(l10n.adminReportPartnerTable, style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 4),
            for (final row in document.snapshot.partners)
              pw.Text('${row.shopName}  ${row.received}  ${_pdfWon(row.net)}'),
            pw.SizedBox(height: 10),
          ],
          if (document.showProducts) ...[
            pw.Text(l10n.adminReportProductRank, style: const pw.TextStyle(fontSize: 14)),
            for (final row in document.snapshot.topProducts)
              pw.Text('${row.label}  ${_pdfWon(row.net)}  ${row.count}'),
            pw.SizedBox(height: 10),
          ],
          if (document.showOptions) ...[
            pw.Text(l10n.adminStatsOptions, style: const pw.TextStyle(fontSize: 14)),
            if (!document.optionsApply || document.options.isEmpty)
              pw.Text(l10n.adminStatsGathering)
            else ...[
              for (final option in document.options)
                pw.Text('${option.name}  ${option.count}'),
              if (document.topOption != null)
                pw.Text('${l10n.adminStatsMost}: ${document.topOption}'),
            ],
            pw.Text(l10n.adminStatsOptionsHint),
            pw.SizedBox(height: 10),
          ],
          if (document.showCancels) ...[
            pw.Text(l10n.adminReportCancels, style: const pw.TextStyle(fontSize: 14)),
            pw.Text(
              '${totals.cancelCount} · ${_pdfWon(totals.refund)}',
            ),
            pw.SizedBox(height: 10),
          ],
          if (document.showBasis) pw.Text(document.basisText),
          pw.SizedBox(height: 8),
          pw.Text(document.fontLicense, style: const pw.TextStyle(fontSize: 9)),
        ];
      },
    ),
  );
  return pdf.save();
}

String _pdfWon(int value) {
  final sign = value < 0 ? '-' : '';
  return '$sign${value.abs()}원';
}
