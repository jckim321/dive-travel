import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/travel_style.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/app_card.dart';
import 'package:dive_travel_app/core/widgets/passport_stamps.dart';
import 'package:dive_travel_app/features/logbook/presentation/checklist_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Personal next-ocean card. Hidden for brand-new divers with no upcoming trip.
class ForYouSection extends StatelessWidget {
  const ForYouSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final insight = store.travelStyle;
    final trip = store.nextTrip;
    final hide =
        insight.kind == TravelStyleKind.firstOcean && trip == null;
    if (hide) {
      return const SizedBox.shrink();
    }

    final days = trip == null
        ? null
        : TravelStyleAnalyzer.daysUntil(trip.scheduledFor);
    final style = _styleCopy(l10n, insight);
    final checklistHighlight = trip != null && (days ?? 99) <= 21;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        AppSectionHeader(title: l10n.homeForYouTitle),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: const Key('for-you-panel'),
          child: AppCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  style.$1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppTheme.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  style.$2,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.homeNextOceanTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppTheme.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.homeNextOceanBody(
                    continentLabel(l10n, insight.nextContinent),
                  ),
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                if (trip != null) ...[
                  const SizedBox(height: 12),
                  Material(
                    color: checklistHighlight
                        ? AppTheme.goldSoft
                        : const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    child: InkWell(
                      key: const Key('for-you-checklist'),
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ChecklistScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.checklist_outlined,
                              size: 18,
                              color: AppTheme.navy,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${l10n.homeChecklistLabel} · '
                                '${l10n.homeChecklistSoon(days ?? 0, trip.shopName)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppTheme.navy,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: AppTheme.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  (String, String) _styleCopy(
    AppLocalizations l10n,
    TravelStyleInsight insight,
  ) {
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
