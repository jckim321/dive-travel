import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Top of My: name, exploration count, optional next departure.
class DepartureDeskHeader extends StatelessWidget {
  const DepartureDeskHeader({
    super.key,
    required this.displayName,
    required this.regionsCount,
    this.nextDepartureLabel,
  });

  final String displayName;
  final int regionsCount;
  final String? nextDepartureLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      key: const Key('departure-desk-header'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.oceanDeep,
            Color(0xFF0B3A4F),
            AppTheme.seaMist,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.profileDepartureDeskKicker,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppTheme.goldSoft,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayName,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.profileRegions(regionsCount),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          if (nextDepartureLabel != null && nextDepartureLabel!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusTight),
                border: Border.all(
                  color: AppTheme.gold.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.flight_takeoff_outlined,
                    size: 18,
                    color: AppTheme.goldSoft,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nextDepartureLabel!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
