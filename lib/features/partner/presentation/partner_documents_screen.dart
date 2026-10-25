import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star_loi_pdf.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_star_application.dart';
import 'package:dive_travel_app/core/models/partner_document.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_back_button.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_loi_form_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Partner-facing list of approved public documents + LOI status.
class PartnerDocumentsScreen extends StatefulWidget {
  const PartnerDocumentsScreen({super.key});

  @override
  State<PartnerDocumentsScreen> createState() => _PartnerDocumentsScreenState();
}

class _PartnerDocumentsScreenState extends State<PartnerDocumentsScreen> {
  bool _loading = true;
  Object? _error;
  List<PartnerDocument> _docs = const [];
  List<DiveStarApplication> _apps = const [];
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
      final uid = store.uid;
      final apps = uid == null || uid.isEmpty
          ? const <DiveStarApplication>[]
          : await store.listDiveStarApplications(partnerUid: uid);
      if (!mounted) {
        return;
      }
      setState(() {
        _docs = docs;
        _config = config;
        _apps = apps;
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

  String _statusLabel(AppLocalizations l10n, DiveStarPipelineStatus s) {
    return switch (s) {
      DiveStarPipelineStatus.guideSent => l10n.pipelineGuideSent,
      DiveStarPipelineStatus.loiReceived => l10n.pipelineLoiReceived,
      DiveStarPipelineStatus.docsSubmitted => l10n.pipelineDocsSubmitted,
      DiveStarPipelineStatus.underReview => l10n.pipelineUnderReview,
      DiveStarPipelineStatus.resultNotified => l10n.pipelineResultNotified,
    };
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

    return PartnerTheme.wrap(
      Scaffold(
      appBar: AppBar(
        leading: const PartnerBackButton(),
        title: Text(l10n.partnerDocsTitle),
      ),
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
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.draw_outlined),
                        title: Text(l10n.partnerLoiOpenForm),
                        subtitle: Text(l10n.partnerLoiOpenFormHint),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final done = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => const PartnerLoiFormScreen(),
                            ),
                          );
                          if (done == true && mounted) {
                            await _reload();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.partnerLoiStatusSection,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_apps.isEmpty)
                      Text(l10n.partnerLoiStatusEmpty)
                    else
                      for (final app in _apps) ...[
                        Card(
                          child: ListTile(
                            title: Text(app.companyName),
                            subtitle: Text(
                              [
                                DateFormat.yMMMd()
                                    .format(app.submittedAt.toLocal()),
                                _statusLabel(l10n, app.pipelineStatus),
                              ].join(' · '),
                            ),
                            trailing: IconButton(
                              tooltip: l10n.adminDocActionPrint,
                              icon: const Icon(Icons.print_outlined),
                              onPressed: () async {
                                final bytes = await buildDiveStarLoiPdf(app);
                                await Printing.layoutPdf(
                                  onLayout: (_) async => bytes,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    const SizedBox(height: 16),
                    Text(
                      l10n.adminDocsListSection,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
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
    return PartnerTheme.wrap(
      Scaffold(
      appBar: AppBar(
        leading: const PartnerBackButton(),
        title: Text(doc.title),
      ),
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
      ),
    );
  }
}
