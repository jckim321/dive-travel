import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/partner_contract.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_back_button.dart';
import 'package:dive_travel_app/core/models/partner_contract_terms.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_contract_sign_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_contract_terms_view.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_promotion_form.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Partner-facing contract vault (awaiting / executed).
class PartnerContractVaultScreen extends StatefulWidget {
  const PartnerContractVaultScreen({super.key, required this.shopId});

  final String shopId;

  @override
  State<PartnerContractVaultScreen> createState() =>
      _PartnerContractVaultScreenState();
}

class _PartnerContractVaultScreenState
    extends State<PartnerContractVaultScreen> {
  var _loading = true;
  Object? _error;
  List<PartnerContract> _docs = const [];
  var _showTerms = false;
  var _showPromo = false;
  var _termsLoading = false;
  PartnerContractTerms? _terms;

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
      final all = sortPartnerContractsByUploadedAt(
        await store.listPartnerContracts(widget.shopId, forPartner: true),
      );
      final visible = [
        for (final d in all)
          if (d.status != PartnerContractStatus.drafting &&
              d.status != PartnerContractStatus.voided)
            d,
      ];
      if (!mounted) {
        return;
      }
      setState(() {
        _docs = visible;
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
    final awaiting = [
      for (final d in _docs)
        if (d.status == PartnerContractStatus.awaitingSignature) d,
    ];
    final executed = [
      for (final d in _docs)
        if (d.status == PartnerContractStatus.executed) d,
    ];

    return PartnerTheme.wrap(
      Scaffold(
        appBar: AppBar(
          leading: const PartnerBackButton(),
          title: Text(l10n.partnerVaultTitle),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('$_error'))
                : RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView(
                      key: const Key('partner-contract-vault'),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              key: const Key('partner-terms-chip'),
                              label: Text(l10n.adminContractsSubTerms),
                              selected: _showTerms,
                              onSelected: (_) => _toggleTerms(),
                            ),
                            ChoiceChip(
                              key: const Key('partner-promo-chip'),
                              label: Text(l10n.partnerPromoChip),
                              selected: _showPromo,
                              onSelected: (_) => _togglePromo(),
                            ),
                          ],
                        ),
                        if (_showTerms) ...[
                          const SizedBox(height: 12),
                          if (_termsLoading)
                            const LinearProgressIndicator()
                          else
                            PartnerContractTermsReadout(terms: _terms),
                          const SizedBox(height: 16),
                        ],
                        if (_showPromo) ...[
                          const SizedBox(height: 12),
                          PartnerPromotionForm(shopId: widget.shopId),
                          const SizedBox(height: 16),
                        ],
                        if (_docs.isEmpty)
                          Text(
                            l10n.partnerVaultEmpty,
                            style: const TextStyle(color: PartnerTheme.textDim),
                          ),
                        if (awaiting.isNotEmpty) ...[
                          Text(
                            l10n.partnerVaultAwaiting,
                            style: const TextStyle(
                              color: PartnerTheme.orange,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final doc in awaiting)
                            _ContractTile(
                              doc: doc,
                              highlight: true,
                              onOpen: () => _open(doc),
                            ),
                          const SizedBox(height: 16),
                        ],
                        if (executed.isNotEmpty) ...[
                          Text(
                            l10n.partnerVaultExecuted,
                            style: const TextStyle(
                              color: PartnerTheme.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final doc in executed)
                            _ContractTile(
                              doc: doc,
                              highlight: false,
                              onOpen: () => _open(doc),
                            ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }

  Future<void> _toggleTerms() async {
    if (_showTerms) {
      setState(() => _showTerms = false);
      return;
    }
    final store = DiverStoreScope.of(context);
    setState(() {
      _showTerms = true;
      _showPromo = false;
      _termsLoading = true;
    });
    try {
      final terms = await store.getPartnerContractTerms(widget.shopId);
      if (!mounted) {
        return;
      }
      setState(() {
        _terms = terms;
        _termsLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _termsLoading = false);
    }
  }

  void _togglePromo() {
    setState(() {
      _showPromo = !_showPromo;
      if (_showPromo) {
        _showTerms = false;
      }
    });
  }

  Future<void> _open(PartnerContract doc) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PartnerContractSignScreen(
          shopId: widget.shopId,
          contractId: doc.id,
        ),
      ),
    );
    if (mounted) {
      await _reload();
    }
  }
}

class _ContractTile extends StatelessWidget {
  const _ContractTile({
    required this.doc,
    required this.highlight,
    required this.onOpen,
  });

  final PartnerContract doc;
  final bool highlight;
  final VoidCallback onOpen;

  static final _day = DateFormat('yyyy.MM.dd');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      key: Key('partner-contract-${doc.id}'),
      color: PartnerTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: highlight ? PartnerTheme.orange : PartnerTheme.border,
          width: highlight ? 1.6 : 1,
        ),
      ),
      child: ListTile(
        title: Text(
          doc.title,
          style: const TextStyle(
            color: PartnerTheme.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${doc.kind == PartnerContractKind.master ? l10n.adminVaultKindMaster : l10n.adminVaultKindAnnex}'
          ' · v${doc.version} · ${_day.format(doc.uploadedAt)}',
          style: const TextStyle(color: PartnerTheme.textDim, fontSize: 12),
        ),
        trailing: TextButton(
          onPressed: onOpen,
          child: Text(l10n.partnerVaultOpen),
        ),
      ),
    );
  }
}
