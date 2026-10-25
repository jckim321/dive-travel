import 'package:flutter/material.dart';

import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Dark-theme AppBar back control with explicit [PartnerTheme.text] contrast.
class PartnerBackButton extends StatelessWidget {
  const PartnerBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      key: const Key('partner-back'),
      icon: const Icon(Icons.arrow_back, color: PartnerTheme.text),
      tooltip: l10n.partnerExit,
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    );
  }
}
