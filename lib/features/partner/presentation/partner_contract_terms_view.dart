import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/partner_contract_terms.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Read-only contract values. A missing document shows every row as unset.
class PartnerContractTermsReadout extends StatelessWidget {
  const PartnerContractTermsReadout({super.key, required this.terms});

  final PartnerContractTerms? terms;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = terms ?? PartnerContractTerms.empty;
    final foc = _foc(l10n, current);
    final period = _period(l10n, current);
    return Column(
      key: const Key('partner-terms-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _row(
          l10n.adminTermsCommission,
          _percent(l10n, current.commissionRatePercent),
          const Key('partner-terms-commission'),
        ),
        _row(
          l10n.adminTermsParty,
          _percent(l10n, current.partyDiscountPercent),
          const Key('partner-terms-party'),
        ),
        _row(
          l10n.adminTermsSeason,
          _percent(l10n, current.seasonDiscountPercent),
          const Key('partner-terms-season'),
        ),
        _row(l10n.adminTermsFoc, foc, const Key('partner-terms-foc')),
        _row(l10n.adminTermsPeriod, period, const Key('partner-terms-period')),
      ],
    );
  }

  Widget _row(String label, String value, Key key) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: PartnerTheme.textDim),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: PartnerTheme.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
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
}
