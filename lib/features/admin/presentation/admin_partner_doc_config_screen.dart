import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/partner_document.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Edit country channel presets and KO/EN message templates.
class AdminPartnerDocConfigScreen extends StatefulWidget {
  const AdminPartnerDocConfigScreen({super.key});

  @override
  State<AdminPartnerDocConfigScreen> createState() =>
      _AdminPartnerDocConfigScreenState();
}

class _AdminPartnerDocConfigScreenState
    extends State<AdminPartnerDocConfigScreen> {
  bool _loading = true;
  bool _saving = false;
  Object? _error;
  PartnerDocConfig? _config;

  late final TextEditingController _krChannels;
  late final TextEditingController _jpChannels;
  late final TextEditingController _thChannels;
  late final TextEditingController _idChannels;
  late final TextEditingController _defaultChannels;
  late final TextEditingController _koSubject;
  late final TextEditingController _koBody;
  late final TextEditingController _enSubject;
  late final TextEditingController _enBody;

  @override
  void initState() {
    super.initState();
    _krChannels = TextEditingController();
    _jpChannels = TextEditingController();
    _thChannels = TextEditingController();
    _idChannels = TextEditingController();
    _defaultChannels = TextEditingController();
    _koSubject = TextEditingController();
    _koBody = TextEditingController();
    _enSubject = TextEditingController();
    _enBody = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _krChannels.dispose();
    _jpChannels.dispose();
    _thChannels.dispose();
    _idChannels.dispose();
    _defaultChannels.dispose();
    _koSubject.dispose();
    _koBody.dispose();
    _enSubject.dispose();
    _enBody.dispose();
    super.dispose();
  }

  List<String> _parseChannels(String raw) {
    return [
      for (final part in raw.split(RegExp(r'[,/\s]+')))
        if (part.trim().isNotEmpty) part.trim().toLowerCase(),
    ];
  }

  Future<void> _load() async {
    final store = DiverStoreScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final config = await store.ensurePartnerDocConfig();
      if (!mounted) {
        return;
      }
      _apply(config);
      setState(() {
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

  void _apply(PartnerDocConfig config) {
    _krChannels.text = (config.channelsByCountry['KR'] ?? const []).join(', ');
    _jpChannels.text = (config.channelsByCountry['JP'] ?? const []).join(', ');
    _thChannels.text = (config.channelsByCountry['TH'] ?? const []).join(', ');
    _idChannels.text = (config.channelsByCountry['ID'] ?? const []).join(', ');
    _defaultChannels.text =
        (config.channelsByCountry['DEFAULT'] ?? const []).join(', ');
    final ko = config.templateFor('ko');
    final en = config.templateFor('en');
    _koSubject.text = ko.subject;
    _koBody.text = ko.body;
    _enSubject.text = en.subject;
    _enBody.text = en.body;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    setState(() => _saving = true);
    try {
      final next = PartnerDocConfig(
        channelsByCountry: {
          'KR': _parseChannels(_krChannels.text),
          'JP': _parseChannels(_jpChannels.text),
          'TH': _parseChannels(_thChannels.text),
          'ID': _parseChannels(_idChannels.text),
          'DEFAULT': _parseChannels(_defaultChannels.text),
        },
        templates: {
          'ko': PartnerMessageTemplate(
            subject: _koSubject.text.trim(),
            body: _koBody.text.trim(),
          ),
          'en': PartnerMessageTemplate(
            subject: _enSubject.text.trim(),
            body: _enBody.text.trim(),
          ),
        },
      );
      await store.savePartnerDocConfig(next);
      if (!mounted) {
        return;
      }
      setState(() {
        _config = next;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminDocConfigSaved)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminDocConfigTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('$_error'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    Text(l10n.adminDocConfigChannelsHint),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _krChannels,
                      decoration: InputDecoration(
                        labelText: l10n.adminDocConfigChannelsKr,
                      ),
                    ),
                    TextField(
                      controller: _jpChannels,
                      decoration: InputDecoration(
                        labelText: l10n.adminDocConfigChannelsJp,
                      ),
                    ),
                    TextField(
                      controller: _thChannels,
                      decoration: InputDecoration(
                        labelText: l10n.adminDocConfigChannelsTh,
                      ),
                    ),
                    TextField(
                      controller: _idChannels,
                      decoration: InputDecoration(
                        labelText: l10n.adminDocConfigChannelsId,
                      ),
                    ),
                    TextField(
                      controller: _defaultChannels,
                      decoration: InputDecoration(
                        labelText: l10n.adminDocConfigChannelsDefault,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(l10n.adminDocConfigTemplatesHint),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _koSubject,
                      decoration: InputDecoration(
                        labelText: l10n.adminDocConfigKoSubject,
                      ),
                    ),
                    TextField(
                      controller: _koBody,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: l10n.adminDocConfigKoBody,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _enSubject,
                      decoration: InputDecoration(
                        labelText: l10n.adminDocConfigEnSubject,
                      ),
                    ),
                    TextField(
                      controller: _enBody,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: l10n.adminDocConfigEnBody,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(l10n.briefSave),
                    ),
                    if (_config != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.adminDocConfigPlaceholders,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
    );
  }
}
