import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/partner_contract.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Admin vault: upload / send / void / download for one shop.
class AdminContractVaultScreen extends StatefulWidget {
  const AdminContractVaultScreen({
    super.key,
    this.embedded = false,
    this.initialShopId,
  });

  final bool embedded;
  final String? initialShopId;

  @override
  State<AdminContractVaultScreen> createState() =>
      _AdminContractVaultScreenState();
}

class _AdminContractVaultScreenState extends State<AdminContractVaultScreen> {
  String? _shopId;
  var _loading = false;
  var _busy = false;
  List<PartnerContract> _docs = const [];
  final _title = TextEditingController();
  final _version = TextEditingController(text: '1');
  var _kind = PartnerContractKind.master;

  @override
  void initState() {
    super.initState();
    _shopId = widget.initialShopId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shopId != null) {
        _reload();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AdminContractVaultScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialShopId != null &&
        widget.initialShopId != oldWidget.initialShopId) {
      _shopId = widget.initialShopId;
      _reload();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _version.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final shopId = _shopId;
    if (shopId == null) {
      return;
    }
    final store = DiverStoreScope.of(context);
    setState(() => _loading = true);
    try {
      final docs = await store.listPartnerContracts(shopId);
      if (!mounted) {
        return;
      }
      setState(() {
        _docs = docs;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  Future<void> _upload() async {
    final l10n = AppLocalizations.of(context);
    final shopId = _shopId;
    if (shopId == null || _busy) {
      return;
    }
    if (_title.text.trim().isEmpty) {
      return;
    }
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (picked.isEmpty) {
      return;
    }
    final bytes = await picked.first.readAsBytes();
    if (bytes.isEmpty) {
      return;
    }
    final store = DiverStoreScope.of(context);
    setState(() => _busy = true);
    try {
      await store.uploadPartnerContractDraft(
        shopId: shopId,
        pdfBytes: Uint8List.fromList(bytes),
        kind: _kind,
        title: _title.text.trim(),
        version: _version.text.trim(),
      );
      _title.clear();
      await _reload();
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

  Future<void> _send(PartnerContract doc) async {
    final store = DiverStoreScope.of(context);
    setState(() => _busy = true);
    try {
      await store.sendPartnerContract(
        shopId: doc.shopId,
        contractId: doc.id,
      );
      await _reload();
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

  Future<void> _void(PartnerContract doc) async {
    final store = DiverStoreScope.of(context);
    setState(() => _busy = true);
    try {
      await store.voidPartnerContract(
        shopId: doc.shopId,
        contractId: doc.id,
      );
      await _reload();
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

  Future<void> _download(PartnerContract doc) async {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    try {
      final bytes = await store.fetchPartnerContractFileBytes(doc.fileUrl);
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
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: '${doc.id}.pdf',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminVaultDownload)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final shops = store.shops;
    final day = DateFormat('yyyy.MM.dd');

    final body = ListView(
      key: const Key('admin-contract-vault'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        DropdownButtonFormField<String>(
          key: const Key('admin-vault-shop'),
          value: _shopId,
          decoration: InputDecoration(labelText: l10n.adminVaultPickShop),
          items: [
            for (final shop in shops)
              DropdownMenuItem(
                value: shop.hullId,
                child: Text(
                  store.liveStatsFor(shop.hullId)?.name ??
                      DiveShopCatalog.byId(shop.hullId)?.name ??
                      shop.name,
                ),
              ),
          ],
          onChanged: (value) {
            setState(() => _shopId = value);
            _reload();
          },
        ),
        if (_shopId != null) ...[
          const SizedBox(height: 12),
          TextField(
            key: const Key('admin-vault-title'),
            controller: _title,
            decoration: InputDecoration(labelText: l10n.adminVaultTitleHint),
          ),
          TextField(
            key: const Key('admin-vault-version'),
            controller: _version,
            decoration: InputDecoration(labelText: l10n.adminVaultVersionHint),
          ),
          DropdownButtonFormField<PartnerContractKind>(
            value: _kind,
            items: [
              DropdownMenuItem(
                value: PartnerContractKind.master,
                child: Text(l10n.adminVaultKindMaster),
              ),
              DropdownMenuItem(
                value: PartnerContractKind.annex,
                child: Text(l10n.adminVaultKindAnnex),
              ),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => _kind = v);
              }
            },
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('admin-vault-upload'),
            onPressed: _busy ? null : _upload,
            child: Text(l10n.adminVaultUpload),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_docs.isEmpty)
            Text(
              l10n.adminVaultEmpty,
              style: const TextStyle(color: AdminConsoleTheme.muted),
            )
          else
            for (final doc in _docs)
              Card(
                key: Key('admin-vault-doc-${doc.id}'),
                color: AdminConsoleTheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        doc.title,
                        style: const TextStyle(
                          color: AdminConsoleTheme.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${doc.status.firestoreValue} · v${doc.version} · ${day.format(doc.uploadedAt)}',
                        style: const TextStyle(
                          color: AdminConsoleTheme.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (doc.status == PartnerContractStatus.drafting ||
                              doc.status ==
                                  PartnerContractStatus.awaitingSignature)
                            OutlinedButton(
                              key: Key('admin-vault-send-${doc.id}'),
                              onPressed: _busy ? null : () => _send(doc),
                              child: Text(l10n.adminVaultSend),
                            ),
                          if (!doc.isSealed)
                            OutlinedButton(
                              key: Key('admin-vault-void-${doc.id}'),
                              onPressed: _busy ? null : () => _void(doc),
                              child: Text(l10n.adminVaultVoid),
                            ),
                          if (doc.status == PartnerContractStatus.executed)
                            FilledButton(
                              key: Key('admin-vault-download-${doc.id}'),
                              onPressed: () => _download(doc),
                              child: Text(l10n.adminVaultDownload),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ],
    );

    if (widget.embedded) {
      return body;
    }
    return Scaffold(
      backgroundColor: AdminConsoleTheme.bg,
      appBar: AppBar(title: Text(l10n.adminContractsSubVault)),
      body: body,
    );
  }
}
