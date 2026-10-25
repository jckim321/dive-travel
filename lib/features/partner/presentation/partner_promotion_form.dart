import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/partner_promotion.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class PartnerPromotionForm extends StatefulWidget {
  const PartnerPromotionForm({super.key, required this.shopId});

  final String shopId;

  @override
  State<PartnerPromotionForm> createState() => _PartnerPromotionFormState();
}

class _PartnerPromotionFormState extends State<PartnerPromotionForm> {
  final _note = TextEditingController();
  final _from = TextEditingController();
  final _until = TextEditingController();
  String _kind = partnerPromotionKinds.first.id;
  var _busy = false;
  String? _notice;

  @override
  void dispose() {
    _note.dispose();
    _from.dispose();
    _until.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    if (_busy) {
      return;
    }
    final start = parsePartnerPromotionDay(_from.text);
    final end = parsePartnerPromotionDay(_until.text);
    if (start == null || end == null) {
      setState(() => _notice = l10n.partnerPromoBadDay);
      return;
    }
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      await DiverStoreScope.of(context).sendPartnerPromotion(
        shopId: widget.shopId,
        kind: _kind,
        startsOn: start,
        endsOn: end,
        note: _note.text,
      );
      if (!mounted) {
        return;
      }
      _note.clear();
      _from.clear();
      _until.clear();
      setState(() => _notice = l10n.partnerPromoSent);
    } on PartnerPromotionInvalid catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _notice = switch (error.code) {
          'note' => l10n.partnerPromoBadNote,
          'period' => l10n.partnerPromoBadPeriod,
          _ => l10n.partnerPromoBadKind,
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
    final language = Localizations.localeOf(context).languageCode;
    return Column(
      key: const Key('partner-promo-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('partner-promo-kind-$_kind'),
          initialValue: _kind,
          decoration: InputDecoration(labelText: l10n.partnerPromoKind),
          items: [
            for (final kind in partnerPromotionKinds)
              DropdownMenuItem(
                value: kind.id,
                child: Text(kind.labelFor(language)),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _kind = value);
            }
          },
        ),
        TextField(
          key: const Key('partner-promo-from'),
          controller: _from,
          decoration: InputDecoration(
            labelText: l10n.adminTermsFrom,
            hintText: '2026-10-01',
          ),
        ),
        TextField(
          key: const Key('partner-promo-until'),
          controller: _until,
          decoration: InputDecoration(
            labelText: l10n.adminTermsUntil,
            hintText: '2026-10-31',
          ),
        ),
        TextField(
          key: const Key('partner-promo-note'),
          controller: _note,
          maxLength: 80,
          inputFormatters: [LengthLimitingTextInputFormatter(80)],
          decoration: InputDecoration(labelText: l10n.partnerPromoNote),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('partner-promo-send'),
          onPressed: _busy ? null : _send,
          child: Text(l10n.partnerPromoSend),
        ),
        if (_notice != null) ...[
          const SizedBox(height: 8),
          Text(
            _notice!,
            key: const Key('partner-promo-notice'),
            style: const TextStyle(color: PartnerTheme.text),
          ),
        ],
      ],
    );
  }
}
