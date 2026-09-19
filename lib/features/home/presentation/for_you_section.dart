import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/region_catalog.dart';
import 'package:dive_travel_app/core/data/travel_style.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/diver_stats.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/app_card.dart';
import 'package:dive_travel_app/core/widgets/passport_stamps.dart';
import 'package:dive_travel_app/features/logbook/presentation/checklist_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class ForYouSection extends StatelessWidget {
  const ForYouSection({
    super.key,
    required this.onOpenShop,
    required this.onOpenProfile,
  });

  final ValueChanged<DiveShop> onOpenShop;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final insight = store.travelStyle;
    final trip = store.nextTrip;
    final days = trip == null
        ? null
        : TravelStyleAnalyzer.daysUntil(trip.scheduledFor);
    final theme = Theme.of(context);
    final remaining = DiverStats.masterLogTarget - store.stats.totalLogCount;
    final style = _styleCopy(l10n, insight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: l10n.homeForYouTitle),
        const SizedBox(height: 12),
        AppCard(
          key: const Key('for-you-panel'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                style.$1,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(style.$2, style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.canvas,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeNextOceanTitle,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppTheme.ocean,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.homeNextOceanBody(
                        continentLabel(l10n, insight.nextContinent),
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (insight.suggestedShop != null) ...[
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        key: const Key('for-you-shop'),
                        onPressed: () => onOpenShop(insight.suggestedShop!),
                        child: Text(
                          l10n.homeOpenShop(insight.suggestedShop!.name),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _InsightTile(
                      key: const Key('for-you-stamps'),
                      icon: Icons.approval_outlined,
                      label: l10n.homeStampsLabel,
                      value: l10n.homeStampsProgress(
                        insight.stampCount,
                        RegionCatalog.passportCountries.length,
                      ),
                      onTap: onOpenProfile,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InsightTile(
                      key: const Key('for-you-badge'),
                      icon: Icons.workspace_premium_outlined,
                      label: l10n.homeBadgeLabel,
                      value: remaining <= 0
                          ? l10n.homeBadgeDone
                          : l10n.homeBadgeLeft(remaining),
                      onTap: onOpenProfile,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InsightTile(
                      key: const Key('for-you-checklist'),
                      icon: Icons.checklist_outlined,
                      label: l10n.homeChecklistLabel,
                      value: trip == null
                          ? l10n.homeChecklistIdle
                          : l10n.homeChecklistSoon(days ?? 0, trip.shopName),
                      highlight: trip != null && (days ?? 99) <= 21,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ChecklistScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PassportStamps(
                stamped: insight.stampedCountries,
                compact: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  (String, String) _styleCopy(AppLocalizations l10n, TravelStyleInsight insight) {
    return switch (insight.kind) {
      TravelStyleKind.firstOcean => (
          l10n.homeStyleFirstOcean,
          l10n.homeStyleFirstOceanBody,
        ),
      TravelStyleKind.homeContinent => (
          l10n.homeStyleHomeContinent,
          l10n.homeStyleHomeContinentBody,
        ),
      TravelStyleKind.collector => (
          l10n.homeStyleCollector,
          l10n.homeStyleCollectorBody,
        ),
      TravelStyleKind.deepLocal => (
          l10n.homeStyleDeepLocal,
          l10n.homeStyleDeepLocalBody,
        ),
      TravelStyleKind.pro => (l10n.homeStylePro, l10n.homeStyleProBody),
    };
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlight ? AppTheme.goldSoft : const Color(0xFFF7F4EE),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Column(
            children: [
              Icon(icon, size: 18, color: AppTheme.navy),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.25,
                  color: Color(0xFF4A5560),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
