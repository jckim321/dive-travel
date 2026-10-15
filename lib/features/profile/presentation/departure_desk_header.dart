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
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
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
              border: Border.all(color: Colors.white24),
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
                    color: AppTheme.goldSoft,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${l10n.profileRegions(regionsCount)} · '
                  '${l10n.profileTotalDives} $logCount',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
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
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
            icon: const Icon(Icons.tune_rounded, size: 21),
          ),
        ],
      ),
    );
  }
}
