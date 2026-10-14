import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/region_catalog.dart';
import 'package:dive_travel_app/core/data/travel_style.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/diver_stats.dart';
import 'package:dive_travel_app/core/widgets/app_card.dart';
import 'package:dive_travel_app/core/widgets/passport_stamps.dart';
import 'package:dive_travel_app/features/home/presentation/ocean_atlas_panel.dart';
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
    final remaining = DiverStats.masterLogTarget - store.stats.totalLogCount;
    final style = _styleCopy(l10n, insight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: l10n.homeForYouTitle),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: const Key('for-you-panel'),
          child: Column(
            children: [
              OceanAtlasPanel(
                stampedContinents: insight.stampedContinents,
                nextContinent: insight.nextContinent,
                styleTitle: style.$1,
                styleBody: style.$2,
                nextOceanBody: l10n.homeNextOceanBody(
                  continentLabel(l10n, insight.nextContinent),
                ),
                shopButtonLabel: insight.suggestedShop == null
                    ? null
                    : l10n.homeOpenShop(insight.suggestedShop!.name),
                onOpenShop: insight.suggestedShop == null
                    ? null
                    : () => onOpenShop(insight.suggestedShop!),
                stampsLabel: l10n.homeStampsLabel,
                stampsValue: l10n.homeStampsProgress(
                  insight.stampCount,
                  RegionCatalog.passportCountries.length,
                ),
                badgeLabel: l10n.homeBadgeLabel,
                badgeValue: remaining <= 0
                    ? l10n.homeBadgeDone
                    : l10n.homeBadgeLeft(remaining),
                checklistLabel: l10n.homeChecklistLabel,
                checklistValue: trip == null
                    ? l10n.homeChecklistIdle
                    : l10n.homeChecklistSoon(days ?? 0, trip.shopName),
                checklistHighlight: trip != null && (days ?? 99) <= 21,
                onOpenStamps: onOpenProfile,
                onOpenBadge: onOpenProfile,
                onOpenChecklist: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ChecklistScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _PassportPeek(
                stamped: insight.stampedCountries,
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

class _PassportPeek extends StatefulWidget {
  const _PassportPeek({required this.stamped});

  final Set<String> stamped;

  @override
  State<_PassportPeek> createState() => _PassportPeekState();
}

class _PassportPeekState extends State<_PassportPeek> {
  var _pressed = false;

  Future<void> _openPassport() async {
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x99052A4A),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 28,
          ),
          child: PassportStamps(
            stamped: widget.stamped,
            initiallyOpen: true,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('for-you-passport-peek'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: _openPassport,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _pressed ? -6 : 0, 0),
        width: double.infinity,
        child: IgnorePointer(
          child: PassportStamps(
            stamped: widget.stamped,
            compact: true,
          ),
        ),
      ),
    );
  }
}
