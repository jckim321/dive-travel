import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Quiet identity header for the immersive My Ocean page.
class DepartureDeskHeader extends StatelessWidget {
  const DepartureDeskHeader({
    super.key,
    required this.displayName,
    required this.regionsCount,
    required this.logCount,
    required this.onSettings,
  });

  final String displayName;
  final int regionsCount;
  final int logCount;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      key: const Key('departure-desk-header'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6F4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EBEE)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3C8FB6), Color(0xFF0A4A73)],
              ),
              border: Border.all(color: const Color(0xFFC5C1BA)),
            ),
            child: const Icon(
              Icons.scuba_diving_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileMyOceanKicker,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.ocean,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${l10n.profileRegions(regionsCount)} · '
                  '${l10n.profileTotalDives} $logCount',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('open-profile-settings'),
            tooltip: l10n.profileSettingsTitle,
            onPressed: onSettings,
            style: IconButton.styleFrom(
              foregroundColor: AppTheme.navy,
              backgroundColor: const Color(0xFFE8EBEE),
            ),
            icon: const Icon(Icons.tune_rounded, size: 21),
          ),
        ],
      ),
    );
  }
}
