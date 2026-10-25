import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/constants/partner_application_consent.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/partner_application.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/profile/presentation/partner_application_link_line.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class PartnerApplicationScreen extends StatefulWidget {
  const PartnerApplicationScreen({super.key});

  @override
  State<PartnerApplicationScreen> createState() =>
      _PartnerApplicationScreenState();
}

class _PartnerApplicationScreenState extends State<PartnerApplicationScreen> {
  final _shop = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  final _region = TextEditingController();
  final _intro = TextEditingController();
  final _link = TextEditingController();
  var _loading = true;
  var _busy = false;
  var _consent = false;
  PartnerApplication? _existing;
  String? _notice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _shop.dispose();
    _contact.dispose();
    _phone.dispose();
    _region.dispose();
    _intro.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final existing =
          await DiverStoreScope.of(context).myPartnerApplication();
      if (!mounted) {
        return;
      }
      setState(() {
        _existing = existing;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _notice = '$error';
        _loading = false;
      });
    }
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    if (_busy || _existing != null || !_consent) {
      return;
    }
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final saved = await DiverStoreScope.of(context).submitPartnerApplication(
        shopName: _shop.text,
        contactName: _contact.text,
        phone: _phone.text,
        region: _region.text,
        intro: _intro.text,
        link: _link.text,
        consent: _consent,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _existing = saved;
        _notice = l10n.partnerApplySent;
      });
    } on PartnerApplicationInvalid catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _notice = switch (error.code) {
          'link' => l10n.partnerApplyBadLink,
          'consent' => l10n.partnerApplyNeedConsent,
          _ => l10n.partnerApplyBadField,
        };
      });
    } catch (error) {
      if (mounted) {
        setState(() => _notice = '$error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final existing = _existing;
    return Scaffold(
      backgroundColor: AppTheme.seaMist,
      appBar: AppBar(title: Text(l10n.partnerApplyTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              key: const Key('partner-apply-form'),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                if (existing != null)
                  _Readonly(application: existing)
                else ...[
                  _field(
                    key: const Key('partner-apply-shop'),
                    controller: _shop,
                    label: l10n.partnerApplyShop,
                    maxLength: PartnerApplicationLimits.shop,
                  ),
                  _field(
                    key: const Key('partner-apply-contact'),
                    controller: _contact,
                    label: l10n.partnerApplyContact,
                    maxLength: PartnerApplicationLimits.contact,
                  ),
                  _field(
                    key: const Key('partner-apply-phone'),
                    controller: _phone,
                    label: l10n.partnerApplyPhone,
                    maxLength: PartnerApplicationLimits.phone,
                  ),
                  _field(
                    key: const Key('partner-apply-region'),
                    controller: _region,
                    label: l10n.partnerApplyRegion,
                    maxLength: PartnerApplicationLimits.region,
                  ),
                  _field(
                    key: const Key('partner-apply-intro'),
                    controller: _intro,
                    label: l10n.partnerApplyIntro,
                    maxLength: PartnerApplicationLimits.intro,
                  ),
                  _field(
                    key: const Key('partner-apply-link'),
                    controller: _link,
                    label: l10n.partnerApplyLink,
                    maxLength: PartnerApplicationLimits.link,
                  ),
                  const SizedBox(height: 8),
                  Text(partnerApplicationConsentKo),
                  CheckboxListTile(
                    key: const Key('partner-apply-consent'),
                    contentPadding: EdgeInsets.zero,
                    value: _consent,
                    onChanged: (value) =>
                        setState(() => _consent = value ?? false),
                    title: Text(l10n.partnerApplyConsent),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const Key('partner-apply-send'),
                    onPressed: _consent && !_busy ? _send : null,
                    child: Text(l10n.partnerApplySend),
                  ),
                ],
                if (_notice != null) ...[
                  const SizedBox(height: 12),
                  Text(_notice!, key: const Key('partner-apply-notice')),
                ],
              ],
            ),
    );
  }

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required String label,
    required int maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        key: key,
        controller: controller,
        maxLength: maxLength,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _Readonly extends StatelessWidget {
  const _Readonly({required this.application});

  final PartnerApplication application;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const Key('partner-apply-readonly'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.partnerApplyShop}: ${application.shopName}'),
        Text('${l10n.partnerApplyContact}: ${application.contactName}'),
        Text('${l10n.partnerApplyPhone}: ${application.phone}'),
        Text('${l10n.partnerApplyRegion}: ${application.region}'),
        Text('${l10n.partnerApplyIntro}: ${application.intro}'),
        if (application.link.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(l10n.partnerApplyLink),
          PartnerApplicationLinkLine(link: application.link),
        ],
      ],
    );
  }
}
