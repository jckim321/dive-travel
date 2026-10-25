import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:printing/printing.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star_loi_pdf.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_back_button.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class PartnerLoiFormScreen extends StatefulWidget {
  const PartnerLoiFormScreen({super.key});

  @override
  State<PartnerLoiFormScreen> createState() => _PartnerLoiFormScreenState();
}

class _PartnerLoiFormScreenState extends State<PartnerLoiFormScreen> {
  final _company = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _country = TextEditingController();
  final _notes = TextEditingController();
  final _strokes = <List<Offset>>[];
  List<Offset> _currentStroke = [];
  final _signatureKey = GlobalKey();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final store = DiverStoreScope.of(context);
      final shopId =
          store.stats.ownedShopId ?? AppConstants.defaultPartnerShopId;
      final shop = DiveShopCatalog.byId(shopId);
      setState(() {
        if (_company.text.isEmpty) {
          _company.text = shop?.name ?? '';
        }
        if (_country.text.isEmpty) {
          _country.text = shop?.country ?? '';
        }
        if (_contact.text.isEmpty) {
          _contact.text = store.stats.displayName;
        }
      });
    });
  }

  @override
  void dispose() {
    _company.dispose();
    _contact.dispose();
    _email.dispose();
    _phone.dispose();
    _country.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _hasSignature =>
      _strokes.any((s) => s.length > 1) || _currentStroke.length > 1;

  Future<String?> _captureSignaturePngBase64() async {
    final boundary = _signatureKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      return null;
    }
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      return null;
    }
    return base64Encode(bytes.buffer.asUint8List());
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final uid = store.uid;
    if (uid == null || uid.isEmpty) {
      return;
    }
    if (_company.text.trim().isEmpty ||
        _contact.text.trim().isEmpty ||
        !_hasSignature) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.partnerLoiMissingFields)),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final signature = await _captureSignaturePngBase64();
      if (signature == null || signature.isEmpty) {
        throw StateError('signature');
      }
      final shopId =
          store.stats.ownedShopId ?? AppConstants.defaultPartnerShopId;
      final shop = DiveShopCatalog.byId(shopId);
      final app = await store.submitDiveStarApplication(
        shopId: shopId,
        shopName: shop?.name ?? shopId,
        partnerUid: uid,
        companyName: _company.text,
        contactName: _contact.text,
        contactEmail: _email.text,
        contactPhone: _phone.text,
        country: _country.text,
        notes: _notes.text,
        signaturePngBase64: signature,
      );
      final pdfBytes = await buildDiveStarLoiPdf(app);
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.partnerLoiSubmitted)),
      );
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PartnerTheme.wrap(
      Scaffold(
      appBar: AppBar(
        leading: const PartnerBackButton(),
        title: Text(l10n.partnerLoiTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(l10n.partnerLoiHint),
          const SizedBox(height: 12),
          TextField(
            controller: _company,
            decoration: InputDecoration(labelText: l10n.partnerLoiCompany),
          ),
          TextField(
            controller: _contact,
            decoration: InputDecoration(labelText: l10n.partnerLoiContact),
          ),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l10n.partnerLoiEmail),
          ),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: l10n.partnerLoiPhone),
          ),
          TextField(
            controller: _country,
            decoration: InputDecoration(labelText: l10n.partnerLoiCountry),
          ),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: InputDecoration(labelText: l10n.partnerLoiNotes),
          ),
          const SizedBox(height: 16),
          Text(l10n.partnerLoiSignature),
          const SizedBox(height: 8),
          RepaintBoundary(
            key: _signatureKey,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: GestureDetector(
                onPanStart: (d) {
                  setState(() {
                    _currentStroke = [d.localPosition];
                  });
                },
                onPanUpdate: (d) {
                  setState(() {
                    _currentStroke = [..._currentStroke, d.localPosition];
                  });
                },
                onPanEnd: (_) {
                  setState(() {
                    if (_currentStroke.isNotEmpty) {
                      _strokes.add(_currentStroke);
                    }
                    _currentStroke = [];
                  });
                },
                child: CustomPaint(
                  painter: _SignaturePainter(
                    strokes: [
                      ..._strokes,
                      if (_currentStroke.isNotEmpty) _currentStroke,
                    ],
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() {
                _strokes.clear();
                _currentStroke = [];
              }),
              child: Text(l10n.partnerLoiClearSignature),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.partnerLoiSubmit),
          ),
        ],
      ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter({required this.strokes});

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length < 2) {
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
