import 'package:flutter/material.dart';

import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Dark 「준비 중」 placeholder for affiliate-partner routes without a real screen yet.
class PartnerComingSoonScreen extends StatelessWidget {
  const PartnerComingSoonScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PartnerTheme.wrap(
      Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.partnerComingSoonBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PartnerTheme.textDim,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
