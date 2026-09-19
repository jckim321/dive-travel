import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/diver_stats.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/theme/century_tank_colors.dart';
import 'package:dive_travel_app/core/widgets/tank_gauge.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class TankRack extends StatelessWidget {
  const TankRack({super.key, required this.totalLogs});

  final int totalLogs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stats = DiverStats(
      displayName: '',
      totalLogCount: totalLogs,
      uniqueRegionsCount: 0,
      isInstructor: false,
    );
    final firstRemaining =
        (DiverStats.masterLogTarget - totalLogs).clamp(0, DiverStats.masterLogTarget);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1F33), Color(0xFF16344A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.scuba_diving, color: AppTheme.gold, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.logbookTankRackTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                firstRemaining == 0
                    ? l10n.homeBadgeDone
                    : l10n.homeBadgeLeft(firstRemaining),
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.logbookTankRackHint,
            style: const TextStyle(color: Color(0xFFC5D0D8), fontSize: 11),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < DiverStats.tankRackCount; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: _RackSlot(
                    fill: stats.tankFill(i),
                    label: '${(i + 1) * DiverStats.logsPerTank}',
                    completeColor: AppTheme.gold,
                    activeColor: i < 6
                        ? AppTheme.oceanLight
                        : const Color(0xFF1B6F8A),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0x33C4A35A)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.workspace_premium_outlined,
                  color: AppTheme.gold, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.logbookCenturyTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                stats.hasReachedLegend
                    ? l10n.logbookCenturyMastered
                    : l10n.logbookCenturyLeft(
                        stats.logsToNextCentury,
                        stats.currentCenturyTarget,
                      ),
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.logbookCenturyHint,
            style: const TextStyle(color: Color(0xFFC5D0D8), fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < DiverStats.centuryRackCount; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: _RackSlot(
                    fill: stats.centuryFill(i),
                    label: '${(i + 1) * DiverStats.centuryLogs}',
                    completeColor: CenturyTankColors.ofIndex(i),
                    activeColor: CenturyTankColors.ofIndex(i),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RackSlot extends StatelessWidget {
  const _RackSlot({
    required this.fill,
    required this.label,
    required this.completeColor,
    required this.activeColor,
  });

  final double fill;
  final String label;
  final Color completeColor;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final complete = fill >= 1;
    final active = fill > 0 && fill < 1;
    final fillColor = complete ? completeColor : activeColor;
    final border = complete
        ? completeColor
        : (active ? activeColor : const Color(0xFF4A6273));

    return Column(
      children: [
        TankGauge.compact(
          progress: fill,
          isComplete: complete,
          fillColor: fillColor,
          borderColor: border,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: complete ? completeColor : const Color(0xFF9AA8B2),
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
