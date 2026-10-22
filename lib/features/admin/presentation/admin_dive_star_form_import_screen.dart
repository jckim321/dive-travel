import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/dive_star_form_import.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_star_assessment.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Paste Dive Star form JSON → validate → save as inactive draft.
class AdminDiveStarFormImportScreen extends StatefulWidget {
  const AdminDiveStarFormImportScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminDiveStarFormImportScreen> createState() =>
      _AdminDiveStarFormImportScreenState();
}

class _AdminDiveStarFormImportScreenState
    extends State<AdminDiveStarFormImportScreen> {
  final _jsonController = TextEditingController();
  bool _loading = true;
  bool _importing = false;
  Object? _error;
  List<DiveStarForm> _forms = const [];
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final store = DiverStoreScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final forms = await store.listDiveStarForms();
      if (!mounted) {
        return;
      }
      setState(() {
        _forms = forms;
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

  String _validateMessage(AppLocalizations l10n, String code) {
    if (code == 'empty') {
      return l10n.adminDiveStarFormImportEmpty;
    }
    if (code == 'invalid_json' || code == 'not_object') {
      return l10n.adminDiveStarFormImportInvalidJson;
    }
    if (code == 'missing_version') {
      return l10n.adminDiveStarFormImportMissingVersion;
    }
    if (code.startsWith('area_sum_')) {
      return l10n.adminDiveStarFormImportAreaSum;
    }
    if (code.startsWith('duplicate_')) {
      return l10n.adminDiveStarFormImportDuplicateId;
    }
    if (code.startsWith('item_sum_')) {
      return l10n.adminDiveStarFormImportItemSum;
    }
    return l10n.adminDiveStarFormImportInvalid(code);
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    setState(() {
      _importing = true;
      _statusMessage = null;
    });
    try {
      final form = DiveStarFormImport.parseAndValidate(_jsonController.text);
      final saved = await store.importDiveStarFormDraft(form);
      if (!mounted) {
        return;
      }
      setState(() {
        _importing = false;
        _statusMessage = l10n.adminDiveStarFormImportSaved(saved.version);
      });
      await _reload();
    } on DiveStarFormImportException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _importing = false;
        _statusMessage = _validateMessage(l10n, e.message);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      final msg = '$error';
      setState(() {
        _importing = false;
        _statusMessage = msg.contains('already exists')
            ? l10n.adminDiveStarFormImportExists
            : msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return adminScreenShell(
      embedded: widget.embedded,
      title: l10n.adminDiveStarFormImportTitle,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('$_error'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    Text(
                      l10n.adminDiveStarFormImportHint,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AdminConsoleTheme.muted,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _jsonController,
                      maxLines: 12,
                      decoration: InputDecoration(
                        labelText: l10n.adminDiveStarFormImportPasteLabel,
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _importing ? null : _import,
                      child: _importing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.adminDiveStarFormImportAction),
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(_statusMessage!),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      l10n.adminDiveStarFormListSection,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_forms.isEmpty)
                      Text(l10n.adminDiveStarFormListEmpty)
                    else
                      for (final form in _forms) ...[
                        Card(
                          child: ListTile(
                            title: Text(DiveStarForm.versionLabel(form.version)),
                            subtitle: Text(
                              [
                                form.active
                                    ? l10n.adminDiveStarFormStatusActive
                                    : l10n.adminDiveStarFormStatusDraft,
                                '${form.areas.length} areas',
                                '${form.items.length} items',
                                '${form.gates.length} gates',
                              ].join(' · '),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FilledButton.tonal(
                                onPressed: null,
                                child: Text(l10n.adminDiveStarFormActivate),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.adminDiveStarFormActivateLockedHint,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AdminConsoleTheme.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                  ],
                ),
    );
  }
}
