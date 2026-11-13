import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/partner_contract_terms.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Shop-level contract terms under the partner product form. Read-only.
class PartnerContractBox extends StatefulWidget {
  const PartnerContractBox({super.key, required this.shopId});

  final String shopId;

  @override
  State<PartnerContractBox> createState() => _PartnerContractBoxState();
}

class _PartnerContractBoxState extends State<PartnerContractBox> {
  static const _card = Color(0xFFFFFFFF);
  static const _line = Color(0xFFDDE3EA);
  static const _ink = Color(0xFF0B1F33);
  static const _muted = Color(0xFF52606D);

  var _started = false;
  var _loading = true;
  var _failed = false;
  PartnerContractTerms? _terms;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    final store = DiverStoreScope.of(context);
    unawaited(_load(store));
  }

  Future<void> _load(DiverStore store) async {
    try {
      final terms = await store.getPartnerContractTerms(widget.shopId);
      if (!mounted) {
        return;
      }
      setState(() {
        _terms = terms;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final terms = _terms;
    final empty = terms == null || _fourEmpty(terms);
    final filled = terms;
    return Material(
      key: const Key('partner-regular-contract'),
      color: _card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '계약 조건',
              style: TextStyle(
                color: _ink,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '운영팀이 관리하는 값이라 여기서는 볼 수만 있어요.',
              style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 18),
            if (_loading)
              const LinearProgressIndicator(minHeight: 2)
            else if (empty)
              const Text(
                '아직 계약 조건이 입력되지 않았어요. 운영팀에 문의해 주세요.',
                style: TextStyle(color: _ink, fontSize: 14, height: 1.45),
              )
            else if (filled != null)
              _rows(l10n, filled),
          ],
        ),
      ),
    );
  }

  Widget _rows(AppLocalizations l10n, PartnerContractTerms terms) {
    final note = _endNote(terms.validUntil);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _row(l10n.adminTermsPeriod, _period(l10n, terms)),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Text(
              note,
              style: const TextStyle(color: _muted, fontSize: 12, height: 1.35),
            ),
          ),
        _row(l10n.adminTermsParty, _percent(l10n, terms.partyDiscountPercent)),
        _row(
          l10n.adminTermsSeason,
          _percent(l10n, terms.seasonDiscountPercent),
        ),
        _row(l10n.adminTermsFoc, _foc(l10n, terms)),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: _muted, fontSize: 14)),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  bool _fourEmpty(PartnerContractTerms terms) {
    return formatPartnerTermNumber(terms.partyDiscountPercent).isEmpty &&
        formatPartnerTermNumber(terms.seasonDiscountPercent).isEmpty &&
        (terms.instructorFocPay == null || terms.instructorFocFree == null) &&
        formatPartnerTermDay(terms.validFrom).isEmpty &&
        formatPartnerTermDay(terms.validUntil).isEmpty;
  }

  String _percent(AppLocalizations l10n, double? value) {
    final text = formatPartnerTermNumber(value);
    if (text.isEmpty) {
      return l10n.adminTermsMissing;
    }
    return '$text%';
  }

  String _foc(AppLocalizations l10n, PartnerContractTerms terms) {
    if (terms.instructorFocPay == null || terms.instructorFocFree == null) {
      return l10n.adminTermsMissing;
    }
    return '${terms.instructorFocPay}+${terms.instructorFocFree}';
  }

  String _period(AppLocalizations l10n, PartnerContractTerms terms) {
    final start = formatPartnerTermDay(terms.validFrom);
    final end = formatPartnerTermDay(terms.validUntil);
    if (start.isEmpty && end.isEmpty) {
      return l10n.adminTermsMissing;
    }
    return '${start.isEmpty ? l10n.adminTermsMissing : start} ~ ${end.isEmpty ? l10n.adminTermsMissing : end}';
  }

  String? _endNote(DateTime? until) {
    if (until == null) {
      return null;
    }
    final local = until.toLocal();
    final end = DateTime(local.year, local.month, local.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = end.difference(today).inDays;
    if (days < 0) {
      return '계약 기간이 끝났어요';
    }
    if (days <= 30) {
      return '계약 종료까지 $days일 남았어요';
    }
    return null;
  }
}
