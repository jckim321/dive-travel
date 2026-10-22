import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/partner_document.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Partner-facing list of approved public documents.
class PartnerDocumentsScreen extends StatefulWidget {
  const PartnerDocumentsScreen({super.key});

  @override
  State<PartnerDocumentsScreen> createState() => _PartnerDocumentsScreenState();
}

class _PartnerDocumentsScreenState extends State<PartnerDocumentsScreen> {
  bool _loading = true;
  Object? _error;
  List<PartnerDocument> _docs = const [];
  PartnerDocConfig? _config;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final store = DiverStoreScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final docs = await store.listApprovedPublicPartnerDocuments();
      final config = await store.ensurePartnerDocConfig();
      if (!mounted) {
        return;
      }
      setState(() {
        _docs = docs;
        _config = config;
        _loading = false;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final shopId =
        store.stats.ownedShopId ?? AppConstants.defaultPartnerShopId;
    final shop = DiveShopCatalog.byId(shopId);
    final channels =
        _config?.channelsForCountry(shop?.country ?? '') ?? const <String>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.partnerDocsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$_error'),
                      FilledButton(
                        onPressed: _reload,
                        child: Text(l10n.adminDiveStarAssessmentRetry),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    Text(
                      l10n.partnerDocsHint,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (channels.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.adminDocRecommendedChannels(channels.join(', ')),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_docs.isEmpty)
                      Text(l10n.partnerDocsEmpty)
                    else
                      for (final doc in _docs) ...[
                        Card(
                          child: ListTile(
                            title: Text(doc.title),
                            subtitle: Text(
                              'v${doc.version} · ${doc.language.toUpperCase()}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    PartnerDocumentViewerPage(document: doc),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                  ],
                ),
    );
  }
}

class PartnerDocumentViewerPage extends StatefulWidget {
  const PartnerDocumentViewerPage({super.key, required this.document});

  final PartnerDocument document;

  @override
  State<PartnerDocumentViewerPage> createState() =>
      _PartnerDocumentViewerPageState();
}

class _PartnerDocumentViewerPageState extends State<PartnerDocumentViewerPage> {
  Uint8List? _pdfBytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await rootBundle.load(widget.document.assetPath);
      if (!mounted) {
        return;
      }
      setState(() {
        _pdfBytes = data.buffer.asUint8List();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _pdfBytes = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final doc = widget.document;
    return Scaffold(
      appBar: AppBar(title: Text(doc.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            'v${doc.version} · ${l10n.adminDocStatusApproved} · '
            '${l10n.adminDocAudiencePublic}',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 420,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _pdfBytes == null
                    ? Center(child: Text(l10n.adminDocPdfMissing))
                    : PdfPreview(
                        build: (_) async => _pdfBytes!,
                        allowPrinting: false,
                        allowSharing: false,
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        canDebug: false,
                      ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: _pdfBytes == null
                    ? null
                    : () => Printing.layoutPdf(
                          onLayout: (_) async => _pdfBytes!,
                        ),
                child: Text(l10n.adminDocActionPrint),
              ),
              FilledButton.tonal(
                onPressed: _pdfBytes == null
                    ? null
                    : () => Printing.sharePdf(
                          bytes: _pdfBytes!,
                          filename: '${doc.id}.pdf',
                        ),
                child: Text(l10n.adminDocActionDownload),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
