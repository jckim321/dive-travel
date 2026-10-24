import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Pre-submit confirmation checklist (step 3). Does not gate save by itself.
class ProductSubmitChecklist extends StatelessWidget {
  const ProductSubmitChecklist({
    super.key,
    required this.checked,
    required this.onChanged,
  });

  final Map<String, bool> checked;
  final void Function(String id, bool value) onChanged;

  static const ids = <String>[
    'photos',
    'copy',
    'price',
    'options',
    'includes',
    'cancel',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = <String, String>{
      'photos': l10n.briefChecklistPhotos,
      'copy': l10n.briefChecklistCopy,
      'price': l10n.briefChecklistPrice,
      'options': l10n.briefChecklistOptions,
      'includes': l10n.briefChecklistIncludes,
      'cancel': l10n.briefChecklistCancel,
    };
    return Material(
      key: const Key('brief-submit-checklist'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.briefChecklistTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.briefChecklistHint,
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            for (final id in ids)
              CheckboxListTile(
                key: Key('brief-checklist-$id'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: checked[id] ?? false,
                onChanged: (v) => onChanged(id, v ?? false),
                title: Text(labels[id] ?? id, style: const TextStyle(fontSize: 14)),
              ),
          ],
        ),
      ),
    );
  }
}
