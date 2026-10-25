import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/partner_contract_terms.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class AdminContractTermsScreen extends StatefulWidget {
  const AdminContractTermsScreen({
    super.key,
    this.embedded = false,
    this.initialShopId,
  });

  final bool embedded;
  final String? initialShopId;

  @override
  State<AdminContractTermsScreen> createState() =>
      _AdminContractTermsScreenState();
}

class _AdminContractTermsScreenState extends State<AdminContractTermsScreen> {
  String? _shopId;
  var _loading = false;
  var _busy = false;
  String? _notice;
  List<PartnerContractTermRevision> _history = const [];
  DateTime? _from;
  DateTime? _until;
  final _commission = TextEditingController();
  final _party = TextEditingController();
  final _season = TextEditingController();
  final _focPay = TextEditingController();
  final _focFree = TextEditingController();

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
  void dispose() {
    _commission.dispose();
    _party.dispose();
    _season.dispose();
    _focPay.dispose();
    _focFree.dispose();
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
      final terms = await store.getPartnerContractTerms(shopId);
      final history = await store.listPartnerContractTermRevisions(shopId);
      if (!mounted) {
        return;
      }
      _apply(terms);
      setState(() {
        _history = history;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _snack('$error');
    }
  }

  void _apply(PartnerContractTerms? terms) {
    final current = terms ?? PartnerContractTerms.empty;
    _commission.text = formatPartnerTermNumber(current.commissionRatePercent);
    _party.text = formatPartnerTermNumber(current.partyDiscountPercent);
    _season.text = formatPartnerTermNumber(current.seasonDiscountPercent);
    _focPay.text = formatPartnerTermNumber(current.instructorFocPay);
    _focFree.text = formatPartnerTermNumber(current.instructorFocFree);
    _from = current.validFrom;
    _until = current.validUntil;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final shopId = _shopId;
    if (shopId == null || _busy) {
      return;
    }
    final store = DiverStoreScope.of(context);
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final next = parsePartnerContractTerms(
        commission: _commission.text,
        party: _party.text,
        season: _season.text,
        focPay: _focPay.text,
        focFree: _focFree.text,
        validFrom: _from,
        validUntil: _until,
      );
      await store.savePartnerContractTerms(shopId: shopId, next: next);
      if (!mounted) {
        return;
      }
      setState(() => _notice = l10n.adminTermsSaved);
      await _reload();
    } on PartnerContractTermsUnchanged {
      if (mounted) {
        setState(() => _notice = l10n.adminTermsUnchanged);
      }
    } on PartnerContractTermsInvalid catch (error) {
      if (mounted) {
        setState(() {
          _notice = switch (error.code) {
            'foc' => l10n.adminTermsFocPair,
            'period' => l10n.adminTermsBadPeriod,
            _ => l10n.adminTermsBadNumber,
          };
        });
      }
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

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDay({required bool start}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (start ? _from : _until) ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      if (start) {
        _from = picked;
      } else {
        _until = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final shops = store.shops;
    final day = DateFormat('yyyy-MM-dd HH:mm');

    final body = ListView(
      key: const Key('admin-contract-terms'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('admin-terms-shop-$_shopId'),
          initialValue: _shopId,
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
          if (_loading)
            const LinearProgressIndicator()
          else ...[
            _percentField(
              keyName: 'admin-terms-commission',
              label: l10n.adminTermsCommission,
              controller: _commission,
            ),
            _percentField(
              keyName: 'admin-terms-party',
              label: l10n.adminTermsParty,
              controller: _party,
            ),
            _percentField(
              keyName: 'admin-terms-season',
              label: l10n.adminTermsSeason,
              controller: _season,
            ),
            Text(
              l10n.adminTermsFoc,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Row(
              children: [
                Expanded(
                  child: _percentField(
                    keyName: 'admin-terms-foc-pay',
                    label: l10n.adminTermsFocPay,
                    controller: _focPay,
                    integer: true,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('+'),
                ),
                Expanded(
                  child: _percentField(
                    keyName: 'admin-terms-foc-free',
                    label: l10n.adminTermsFocFree,
                    controller: _focFree,
                    integer: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.adminTermsPeriod),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('admin-terms-from'),
                    onPressed: () => _pickDay(start: true),
                    child: Text(
                      _from == null
                          ? l10n.adminTermsFrom
                          : formatPartnerTermDay(_from),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('admin-terms-until'),
                    onPressed: () => _pickDay(start: false),
                    child: Text(
                      _until == null
                          ? l10n.adminTermsUntil
                          : formatPartnerTermDay(_until),
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() {
                  _from = null;
                  _until = null;
                }),
                child: Text(l10n.adminTermsClear),
              ),
            ),
            FilledButton(
              key: const Key('admin-terms-save'),
              onPressed: _busy ? null : _save,
              child: Text(l10n.adminTermsSave),
            ),
            if (_notice != null) ...[
              const SizedBox(height: 8),
              Text(_notice!, key: const Key('admin-terms-notice')),
            ],
            const SizedBox(height: 20),
            Text(
              l10n.adminTermsHistory,
              key: const Key('admin-terms-history'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (_history.isEmpty)
              Text(
                l10n.adminTermsHistoryEmpty,
                style: const TextStyle(color: AdminConsoleTheme.muted),
              )
            else
              for (final revision in _history)
                for (final change in revision.changes)
                  Padding(
                    key: Key('admin-terms-change-${revision.id}-${change.field}'),
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${day.format(revision.at.toLocal())}  ${revision.actorName}  ${_label(l10n, change.field)}  ${_shown(l10n, change.field, change.before)} → ${_shown(l10n, change.field, change.after)}',
                      style: const TextStyle(color: AdminConsoleTheme.text),
                    ),
                  ),
          ],
        ],
      ],
    );

    if (widget.embedded) {
      return body;
    }
    return Theme(
      data: AdminConsoleTheme.dark,
      child: Scaffold(
        backgroundColor: AdminConsoleTheme.bg,
        appBar: AppBar(title: Text(l10n.adminContractsSubTerms)),
        body: body,
      ),
    );
  }

  Widget _percentField({
    required String keyName,
    required String label,
    required TextEditingController controller,
    bool integer = false,
  }) {
    return TextField(
      key: Key(keyName),
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          integer ? RegExp(r'[0-9]') : RegExp(r'[0-9.]'),
        ),
      ],
      decoration: InputDecoration(labelText: label),
    );
  }

  String _label(AppLocalizations l10n, String field) {
    return switch (field) {
      PartnerContractTermFields.commission => l10n.adminTermsCommission,
      PartnerContractTermFields.party => l10n.adminTermsParty,
      PartnerContractTermFields.season => l10n.adminTermsSeason,
      PartnerContractTermFields.focPay => l10n.adminTermsFocPay,
      PartnerContractTermFields.focFree => l10n.adminTermsFocFree,
      PartnerContractTermFields.validFrom => l10n.adminTermsFrom,
      PartnerContractTermFields.validUntil => l10n.adminTermsUntil,
      _ => field,
    };
  }

  String _shown(AppLocalizations l10n, String field, String value) {
    if (value.trim().isEmpty) {
      return l10n.adminTermsMissing;
    }
    if (field == PartnerContractTermFields.commission ||
        field == PartnerContractTermFields.party ||
        field == PartnerContractTermFields.season) {
      return '$value%';
    }
    return value;
  }
}
