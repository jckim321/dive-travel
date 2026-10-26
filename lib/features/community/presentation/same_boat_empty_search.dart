import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Zero filtered results. Save is a member document write; widen drops one filter.
class SameBoatEmptySearch extends StatelessWidget {
  const SameBoatEmptySearch({
    super.key,
    required this.summary,
    required this.alreadySaved,
    required this.canWiden,
    required this.onSave,
    required this.onWiden,
  });

  final String summary;
  final bool alreadySaved;
  final bool canWiden;
  final VoidCallback onSave;
  final VoidCallback onWiden;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const Icon(Icons.waves, size: 42, color: AppTheme.ocean),
          const SizedBox(height: 12),
          Text(
            l10n.sameBoatEmptyTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              summary,
              key: const Key('same-boat-empty-summary'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('same-boat-alert-save'),
              style: FilledButton.styleFrom(
                backgroundColor: alreadySaved ? AppTheme.muted : AppTheme.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: alreadySaved ? null : onSave,
              icon: Icon(alreadySaved ? Icons.check : Icons.notifications_none),
              label: Text(
                alreadySaved ? l10n.sameBoatEmptySaved : l10n.sameBoatEmptySave,
              ),
            ),
          ),
          if (canWiden) ...[
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.sameBoatEmptyWidenHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.muted,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                key: const Key('same-boat-widen'),
                onPressed: onWiden,
                child: Text(l10n.sameBoatEmptyWiden),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
