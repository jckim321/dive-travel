import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/partner_document.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_partner_doc_config_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class AdminPartnerDocumentsScreen extends StatefulWidget {
  const AdminPartnerDocumentsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminPartnerDocumentsScreen> createState() =>
      _AdminPartnerDocumentsScreenState();
}

class _AdminPartnerDocumentsScreenState
    extends State<AdminPartnerDocumentsScreen> {
  bool _loading = true;
  Object? _error;
  List<PartnerDocument> _docs = const [];
  List<DocumentShareRecord> _shares = const [];
  PartnerDocConfig? _config;
  PartnerDocCategory? _filter;

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
      final docs = await store.ensurePartnerDocumentsSeeded();
      final config = await store.ensurePartnerDocConfig();
      final shares = await store.listDocumentShares();
      if (!mounted) {
        return;
      }
      setState(() {
        _docs = docs;
        _config = config;
        _shares = shares;
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

  String _categoryLabel(AppLocalizations l10n, PartnerDocCategory c) {
    return switch (c) {
      PartnerDocCategory.criteria => l10n.adminDocCatCriteria,
      PartnerDocCategory.partnerGuide => l10n.adminDocCatPartnerGuide,
      PartnerDocCategory.application => l10n.adminDocCatApplication,
      PartnerDocCategory.auditor => l10n.adminDocCatAuditor,
      PartnerDocCategory.training => l10n.adminDocCatTraining,
      PartnerDocCategory.contract => l10n.adminDocCatContract,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = _filter == null
        ? _docs
        : _docs.where((d) => d.category == _filter).toList();

    return adminScreenShell(
      embedded: widget.embedded,
      title: l10n.adminDocsTitle,
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
                      l10n.adminDocsHint,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AdminConsoleTheme.muted,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const AdminPartnerDocConfigScreen(),
                            ),
                          );
                          if (mounted) {
                            await _reload();
                          }
                        },
                        icon: const Icon(Icons.tune),
                        label: Text(l10n.adminDocConfigTitle),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: Text(l10n.adminDocFilterAll),
                          selected: _filter == null,
                          onSelected: (_) => setState(() => _filter = null),
                        ),
                        for (final cat in PartnerDocCategory.values)
                          FilterChip(
                            label: Text(_categoryLabel(l10n, cat)),
                            selected: _filter == cat,
                            onSelected: (_) => setState(() => _filter = cat),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.adminDocsListSection,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (filtered.isEmpty)
                      Text(l10n.adminDocsEmpty)
                    else
                      for (final doc in filtered) ...[
                        Card(
                          child: ListTile(
                            title: Text(doc.title),
                            subtitle: Text(
                              [
                                _categoryLabel(l10n, doc.category),
                                doc.language.toUpperCase(),
                                'v${doc.version}',
                                doc.status == PartnerDocStatus.approved
                                    ? l10n.adminDocStatusApproved
                                    : l10n.adminDocStatusDraft,
                                doc.audience == PartnerDocAudience.public
                                    ? l10n.adminDocAudiencePublic
                                    : l10n.adminDocAudienceInternal,
                              ].join(' · '),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => _PartnerDocumentDetailPage(
                                    document: doc,
                                    config: _config!,
                                  ),
                                ),
                              );
                              if (mounted) {
                                await _reload();
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    const SizedBox(height: 24),
                    Text(
                      l10n.adminDocsShareHistory,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_shares.isEmpty)
                      Text(l10n.adminDocsShareHistoryEmpty)
                    else
                      for (final share in _shares)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(share.documentTitle),
                          subtitle: Text(
                            [
                              DateFormat.yMMMd()
                                  .add_Hm()
                                  .format(share.createdAt.toLocal()),
                              share.shopName.isEmpty
                                  ? share.shopId
                                  : share.shopName,
                              share.method.firestoreValue,
                            ].join(' · '),
                          ),
                        ),
                  ],
                ),
    );
  }
}

class _PartnerDocumentDetailPage extends StatefulWidget {
  const _PartnerDocumentDetailPage({
    required this.document,
    required this.config,
  });

  final PartnerDocument document;
  final PartnerDocConfig config;

  @override
  State<_PartnerDocumentDetailPage> createState() =>
      _PartnerDocumentDetailPageState();
}

class _PartnerDocumentDetailPageState extends State<_PartnerDocumentDetailPage> {
  Uint8List? _pdfBytes;
  bool _loadingPdf = true;
  bool _updatingStatus = false;
  DiveShop? _selectedShop;
  late PartnerDocument _doc;

  PartnerDocument get doc => _doc;

  @override
  void initState() {
    super.initState();
    _doc = widget.document;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPdf());
  }

  Future<void> _toggleStatus(AppLocalizations l10n) async {
    if (_updatingStatus) {
      return;
    }
    final next = _doc.status == PartnerDocStatus.approved
        ? PartnerDocStatus.draft
        : PartnerDocStatus.approved;
    setState(() => _updatingStatus = true);
    try {
      await DiverStoreScope.of(context).updatePartnerDocumentStatus(
        documentId: _doc.id,
        status: next,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _doc = _doc.copyWith(status: next);
        _updatingStatus = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next == PartnerDocStatus.approved
                ? l10n.adminDocStatusApproved
                : l10n.adminDocStatusDraft,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _updatingStatus = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  Future<void> _loadPdf() async {
    setState(() {
      _loadingPdf = true;
    });
    try {
      if (doc.assetPath.isEmpty) {
        throw StateError('no asset');
      }
      final data = await rootBundle.load(doc.assetPath);
      if (!mounted) {
        return;
      }
      setState(() {
        _pdfBytes = data.buffer.asUint8List();
        _loadingPdf = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _pdfBytes = null;
        _loadingPdf = false;
      });
    }
  }

  String _linkForDoc() {
    if (doc.url.isNotEmpty) {
      return doc.url;
    }
    // Public asset path hint for partners (web build may expose assets).
    return doc.assetPath;
  }

  PartnerMessageTemplate get _template {
    final lang = _selectedShop == null ? doc.language : doc.language;
    return widget.config.templateFor(lang);
  }

  String get _partnerName =>
      _selectedShop?.name ?? '{파트너명}';

  String get _filledBody => _template.fill(
        partnerName: _partnerName,
        link: _linkForDoc(),
      );

  String get _filledSubject => _template.fillSubject(
        partnerName: _partnerName,
        link: _linkForDoc(),
      );

  Future<bool> _confirmDraftIfNeeded(AppLocalizations l10n) async {
    if (!doc.isDraft) {
      return true;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDocDraftWarnTitle),
        content: Text(l10n.adminDocDraftWarnBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.adminHqClose),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.adminDocDraftWarnContinue),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _record(
    PartnerDocShareMethod method, {
    required AppLocalizations l10n,
  }) async {
    final store = DiverStoreScope.of(context);
    await store.recordDocumentShare(
      documentId: doc.id,
      documentTitle: doc.title,
      shopId: _selectedShop?.hullId ?? '',
      shopName: _selectedShop?.name ?? '',
      method: method,
      adminUid: store.uid ?? '',
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.adminDocShareRecorded)),
    );
  }

  Future<void> _share(AppLocalizations l10n) async {
    if (!await _confirmDraftIfNeeded(l10n)) {
      return;
    }
    final bytes = _pdfBytes;
    try {
      if (bytes != null && !kIsWeb) {
        await SharePlus.instance.share(
          ShareParams(
            text: _filledBody,
            files: [
              XFile.fromData(
                bytes,
                mimeType: 'application/pdf',
                name: '${doc.id}.pdf',
              ),
            ],
          ),
        );
      } else if (bytes != null && kIsWeb) {
        // Web share is unreliable; fall back to copy.
        await Clipboard.setData(ClipboardData(text: '$_filledBody\n$_linkForDoc()'));
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminDocShareFallbackCopy)),
        );
      } else {
        await Clipboard.setData(ClipboardData(text: '$_filledBody\n$_linkForDoc()'));
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminDocShareFallbackCopy)),
        );
      }
      await _record(PartnerDocShareMethod.share, l10n: l10n);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: '$_filledBody\n$_linkForDoc()'));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminDocShareFallbackCopy)),
      );
      await _record(PartnerDocShareMethod.link, l10n: l10n);
    }
  }

  Future<void> _email(AppLocalizations l10n) async {
    if (!await _confirmDraftIfNeeded(l10n)) {
      return;
    }
    final body = '$_filledBody\n\n${l10n.adminDocEmailAttachHint}';
    final uri = Uri.parse(
      'mailto:?subject=${Uri.encodeComponent(_filledSubject)}'
      '&body=${Uri.encodeComponent(body)}',
    );
    await launchUrl(uri);
    await _record(PartnerDocShareMethod.email, l10n: l10n);
  }

  Future<void> _copyLink(AppLocalizations l10n) async {
    if (!await _confirmDraftIfNeeded(l10n)) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: _linkForDoc()));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.adminDocLinkCopied)),
    );
    await _record(PartnerDocShareMethod.link, l10n: l10n);
  }

  Future<void> _showQr(AppLocalizations l10n) async {
    if (!await _confirmDraftIfNeeded(l10n)) {
      return;
    }
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDocQrTitle),
        content: SizedBox(
          width: 240,
          height: 240,
          child: QrImageView(
            data: _linkForDoc(),
            version: QrVersions.auto,
            backgroundColor: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.adminHqClose),
          ),
        ],
      ),
    );
    await _record(PartnerDocShareMethod.qr, l10n: l10n);
  }

  Future<void> _printNormal(AppLocalizations l10n) async {
    if (!await _confirmDraftIfNeeded(l10n)) {
      return;
    }
    final bytes = _pdfBytes;
    if (bytes == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminDocPdfMissing)),
      );
      return;
    }
    await Printing.layoutPdf(onLayout: (_) async => bytes);
    if (!mounted) {
      return;
    }
    await _record(PartnerDocShareMethod.print, l10n: l10n);
  }

  Future<void> _printFax(AppLocalizations l10n) async {
    if (!await _confirmDraftIfNeeded(l10n)) {
      return;
    }
    final shop = _selectedShop;
    final cover = await _buildFaxCoverPdf(
      documentTitle: doc.title,
      toName: shop?.name ?? l10n.adminDocFaxToBlank,
      fromName: 'Dive Travel',
      pages: _pdfBytes == null ? 1 : 2,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => cover,
      name: 'fax-cover-${doc.id}',
    );
    if (_pdfBytes != null) {
      await Printing.layoutPdf(onLayout: (_) async => _pdfBytes!);
    }
    await _record(PartnerDocShareMethod.print, l10n: l10n);
  }

  Future<Uint8List> _buildFaxCoverPdf({
    required String documentTitle,
    required String toName,
    required String fromName,
    required int pages,
  }) async {
    final pdf = pw.Document();
    final date = DateFormat.yMMMd().format(DateTime.now());
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'FAX COVER / 팩스 표지',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Text('To / 받는 곳: $toName'),
            pw.SizedBox(height: 8),
            pw.Text('From / 보내는 곳: $fromName'),
            pw.SizedBox(height: 8),
            pw.Text('Date / 날짜: $date'),
            pw.SizedBox(height: 8),
            pw.Text('Pages / 쪽수: $pages'),
            pw.SizedBox(height: 8),
            pw.Text('Document / 문서명: $documentTitle'),
            pw.SizedBox(height: 32),
            pw.Text(
              'Please print this cover with the attached document and send via multifunction fax.',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
    return pdf.save();
  }

  Future<void> _download(AppLocalizations l10n) async {
    final bytes = _pdfBytes;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminDocPdfMissing)),
      );
      return;
    }
    await Printing.sharePdf(bytes: bytes, filename: '${doc.id}.pdf');
  }

  Future<void> _pickShop(AppLocalizations l10n) async {
    final shops = DiverStoreScope.of(context).shops;
    final picked = await showDialog<DiveShop>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.adminDocPickPartner),
        children: [
          for (final shop in shops)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, shop),
              child: Text('${shop.name} · ${shop.country}'),
            ),
        ],
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedShop = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final channels = widget.config.channelsForCountry(
      _selectedShop?.country ?? '',
    );

    return Scaffold(
      appBar: AppBar(title: Text(doc.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            [
              'v${doc.version}',
              doc.status == PartnerDocStatus.approved
                  ? l10n.adminDocStatusApproved
                  : l10n.adminDocStatusDraft,
              doc.audience == PartnerDocAudience.public
                  ? l10n.adminDocAudiencePublic
                  : l10n.adminDocAudienceInternal,
              doc.language.toUpperCase(),
            ].join(' · '),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _updatingStatus ? null : () => _toggleStatus(l10n),
            child: Text(
              doc.status == PartnerDocStatus.approved
                  ? l10n.adminDocMarkDraft
                  : l10n.adminDocMarkApproved,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 360,
            child: _loadingPdf
                ? const Center(child: CircularProgressIndicator())
                : _pdfBytes == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            l10n.adminDocPdfMissingDetail(doc.assetPath),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
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
                onPressed: () => _printNormal(l10n),
                child: Text(l10n.adminDocActionPrint),
              ),
              FilledButton.tonal(
                onPressed: () => _download(l10n),
                child: Text(l10n.adminDocActionDownload),
              ),
              FilledButton.tonal(
                onPressed: () => _share(l10n),
                child: Text(l10n.adminDocActionShare),
              ),
              FilledButton.tonal(
                onPressed: () => _email(l10n),
                child: Text(l10n.adminDocActionEmail),
              ),
              FilledButton.tonal(
                onPressed: () => _copyLink(l10n),
                child: Text(l10n.adminDocActionCopyLink),
              ),
              FilledButton.tonal(
                onPressed: () => _showQr(l10n),
                child: Text(l10n.adminDocActionQr),
              ),
              FilledButton.tonal(
                onPressed: () => _printFax(l10n),
                child: Text(l10n.adminDocActionFaxPrint),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.adminDocSendToPartner,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _selectedShop == null
                  ? l10n.adminDocPickPartner
                  : '${_selectedShop!.name} · ${_selectedShop!.country}',
            ),
            trailing: const Icon(Icons.storefront_outlined),
            onTap: () => _pickShop(l10n),
          ),
          if (_selectedShop != null) ...[
            Text(
              l10n.adminDocRecommendedChannels(channels.join(', ')),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AdminConsoleTheme.muted,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _filledBody,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
