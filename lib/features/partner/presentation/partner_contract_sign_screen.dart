import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/partner_contract.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_back_button.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class PartnerContractSignScreen extends StatefulWidget {
  const PartnerContractSignScreen({
    super.key,
    required this.shopId,
    required this.contractId,
  });

  final String shopId;
  final String contractId;

  @override
  State<PartnerContractSignScreen> createState() =>
      _PartnerContractSignScreenState();
}

class _PartnerContractSignScreenState extends State<PartnerContractSignScreen> {
  final _name = TextEditingController();
  final _revision = TextEditingController();
  final _signatureKey = GlobalKey();
  final _strokes = <List<Offset>>[];
  var _currentStroke = <Offset>[];
  var _loading = true;
  var _busy = false;
  var _viewed = false;
  var _agreed = false;
  Object? _error;
  PartnerContract? _doc;
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _name.dispose();
    _revision.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final store = DiverStoreScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final doc = await store.getPartnerContract(
        shopId: widget.shopId,
        contractId: widget.contractId,
      );
      if (doc == null) {
        throw StateError('missing');
      }
      final bytes = await store.fetchPartnerContractFileBytes(doc.fileUrl);
      if (doc.canPartnerAct) {
        await store.markPartnerContractViewed(
          shopId: widget.shopId,
          contractId: widget.contractId,
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _doc = doc;
        _pdfBytes = Uint8List.fromList(bytes);
        _loading = false;
        _name.text = store.stats.displayName == '다이버'
            ? ''
            : store.stats.displayName;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<String?> _captureSignaturePngBase64() async {
    final boundary = _signatureKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      return null;
    }
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      return null;
    }
    return base64Encode(data.buffer.asUint8List());
  }

  Future<void> _sign() async {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final doc = _doc;
    if (doc == null || !_viewed || !_agreed || _busy) {
      return;
    }
    if (_name.text.trim().isEmpty || _strokes.isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      final signature = await _captureSignaturePngBase64();
      if (signature == null || signature.isEmpty) {
        throw StateError('signature');
      }
      await store.signPartnerContractVerified(
        shopId: widget.shopId,
        contractId: widget.contractId,
        signerName: _name.text.trim(),
        signaturePngBase64: signature,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error.toString().contains('file_sha256_mismatch')
          ? l10n.partnerVaultShaMismatch
          : '$error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _requestRevision() async {
    final memo = _revision.text.trim();
    if (memo.isEmpty || _busy) {
      return;
    }
    final store = DiverStoreScope.of(context);
    setState(() => _busy = true);
    try {
      await store.requestPartnerContractRevision(
        shopId: widget.shopId,
        contractId: widget.contractId,
        memo: memo,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _sharePack() async {
    final l10n = AppLocalizations.of(context);
    final doc = _doc;
    final pdf = _pdfBytes;
    if (doc == null || pdf == null) {
      return;
    }
    final sig = doc.signature;
    final meta = StringBuffer()
      ..writeln(doc.title)
      ..writeln('sha256=${doc.fileSha256}')
      ..writeln('status=${doc.status.firestoreValue}');
    if (sig != null) {
      meta
        ..writeln('signer=${sig.signerName}')
        ..writeln('signer_uid=${sig.signerUid}')
        ..writeln('signed_at=${sig.signedAt.toIso8601String()}')
        ..writeln('sig_doc_sha256=${sig.docSha256}');
    }
    await Clipboard.setData(ClipboardData(text: meta.toString()));
    await Printing.sharePdf(bytes: pdf, filename: '${doc.id}.pdf');
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.partnerVaultDownload)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final doc = _doc;
    final canSign = doc?.canPartnerAct == true;

    return PartnerTheme.wrap(
      Scaffold(
        appBar: AppBar(
          leading: const PartnerBackButton(),
          title: Text(doc?.title ?? l10n.partnerVaultTitle),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('$_error'))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      SizedBox(
                        height: 360,
                        child: _pdfBytes == null
                            ? const Center(child: CircularProgressIndicator())
                            : PdfPreview(
                                build: (_) async => _pdfBytes!,
                                canChangeOrientation: false,
                                canChangePageFormat: false,
                                canDebug: false,
                                allowPrinting: false,
                                allowSharing: false,
                              ),
                      ),
                      const SizedBox(height: 12),
                      if (doc?.status == PartnerContractStatus.executed) ...[
                        FilledButton(
                          key: const Key('partner-contract-download'),
                          onPressed: _sharePack,
                          child: Text(l10n.partnerVaultDownload),
                        ),
                      ],
                      if (canSign) ...[
                        CheckboxListTile(
                          key: const Key('partner-contract-viewed'),
                          value: _viewed,
                          onChanged: (v) =>
                              setState(() => _viewed = v ?? false),
                          title: Text(l10n.partnerVaultAckView),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        CheckboxListTile(
                          key: const Key('partner-contract-agree'),
                          value: _agreed,
                          onChanged: (v) =>
                              setState(() => _agreed = v ?? false),
                          title: Text(l10n.partnerVaultAgree),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        TextField(
                          key: const Key('partner-contract-signer-name'),
                          controller: _name,
                          decoration: InputDecoration(
                            labelText: l10n.partnerVaultSignerName,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.partnerVaultSignature),
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
                                  _currentStroke = [
                                    ..._currentStroke,
                                    d.localPosition,
                                  ];
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
                                    if (_currentStroke.isNotEmpty)
                                      _currentStroke,
                                  ],
                                ),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          key: const Key('partner-contract-sign'),
                          onPressed: _busy || !_viewed || !_agreed
                              ? null
                              : _sign,
                          child: Text(l10n.partnerVaultSign),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          key: const Key('partner-contract-revision'),
                          controller: _revision,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: l10n.partnerVaultRevisionHint,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          key: const Key('partner-contract-revision-send'),
                          onPressed: _busy ? null : _requestRevision,
                          child: Text(l10n.partnerVaultRevision),
                        ),
                      ],
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
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final stroke in strokes) {
      if (stroke.length < 2) {
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
