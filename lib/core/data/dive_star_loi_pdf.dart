import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:dive_travel_app/core/models/dive_star_application.dart';

/// Builds a printable Letter of Intent PDF from a submitted application.
Future<Uint8List> buildDiveStarLoiPdf(DiveStarApplication app) async {
  final pdf = pw.Document();
  final date = DateFormat.yMMMMd().format(app.submittedAt.toLocal());
  pw.MemoryImage? signature;
  if (app.signaturePngBase64.isNotEmpty) {
    try {
      signature = pw.MemoryImage(base64Decode(app.signaturePngBase64));
    } catch (_) {
      signature = null;
    }
  }

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Dive Star Letter of Intent / 심사 신청 의향서',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Submitted: $date'),
            pw.SizedBox(height: 20),
            _row('Shop / 샵', app.shopName),
            _row('Company / 상호', app.companyName),
            _row('Contact / 담당자', app.contactName),
            _row('Email', app.contactEmail),
            _row('Phone', app.contactPhone),
            _row('Country', app.country),
            pw.SizedBox(height: 12),
            pw.Text('Notes / 메모'),
            pw.Text(app.notes.isEmpty ? '-' : app.notes),
            pw.SizedBox(height: 24),
            pw.Text(
              'I request Dive Star evaluation for the shop above.',
            ),
            pw.Text('위 샵에 대한 다이브스타 심사를 신청합니다.'),
            pw.SizedBox(height: 20),
            pw.Text('Signature / 서명'),
            pw.SizedBox(height: 8),
            if (signature != null)
              pw.Container(
                height: 80,
                width: 220,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey600),
                ),
                child: pw.Image(signature, fit: pw.BoxFit.contain),
              )
            else
              pw.Text('(no signature image)'),
            pw.SizedBox(height: 8),
            pw.Text(app.contactName),
          ],
        );
      },
    ),
  );
  return pdf.save();
}

pw.Widget _row(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TextSpan(text: value.isEmpty ? '-' : value),
        ],
      ),
    ),
  );
}
