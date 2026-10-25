import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Shows an application link as plain text plus a copy button.
/// The text is not tappable and is never launched, including `javascript:`.
class PartnerApplicationLinkLine extends StatelessWidget {
  const PartnerApplicationLinkLine({
    super.key,
    required this.link,
    this.onCopy,
  });

  final String link;
  final ValueChanged<String>? onCopy;

  @override
  Widget build(BuildContext context) {
    final trimmed = link.trim();
    if (trimmed.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            trimmed,
            key: const Key('partner-application-link-text'),
          ),
        ),
        TextButton(
          key: const Key('partner-application-link-copy'),
          onPressed: () {
            final copy = onCopy;
            if (copy != null) {
              copy(trimmed);
              return;
            }
            Clipboard.setData(ClipboardData(text: trimmed));
          },
          child: Text(l10n.partnerApplyCopy),
        ),
      ],
    );
  }
}
