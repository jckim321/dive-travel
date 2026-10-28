import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/travel_country_master.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

String travelSeaLabel(AppLocalizations l10n, String seaId) {
  return switch (seaId) {
    TravelSea.indian => l10n.exploreSeaIndian,
    TravelSea.red => l10n.exploreSeaRed,
    TravelSea.caribbean => l10n.exploreSeaCaribbean,
    TravelSea.southPacific => l10n.exploreSeaSouthPacific,
    _ => seaId,
  };
}

/// Featured countries for the region whose chevron is open.
class ExploreFeaturedMenu extends StatelessWidget {
  const ExploreFeaturedMenu({
    super.key,
    required this.regionId,
    required this.selectedCountryId,
    required this.selectedLabel,
    required this.countryIdsWithProducts,
    required this.onPlace,
  });

  final String regionId;
  final String? selectedCountryId;
  final String? selectedLabel;
  final Set<String> countryIdsWithProducts;
  final ValueChanged<TravelFeaturedPlace> onPlace;

  @override
  Widget build(BuildContext context) {
    final places = TravelCountryMaster.featuredIn(regionId);

    return Material(
      color: AppTheme.seaMist,
      child: ConstrainedBox(
        key: const Key('explore-country-menu'),
        constraints: const BoxConstraints(maxHeight: 240),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final place in places)
                _FeaturedChip(
                  place: place,
                  selected: selectedCountryId == place.countryId &&
                      selectedLabel == place.label,
                  enabled: countryIdsWithProducts.contains(place.countryId),
                  onPlace: onPlace,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedChip extends StatelessWidget {
  const _FeaturedChip({
    required this.place,
    required this.selected,
    required this.enabled,
    required this.onPlace,
  });

  final TravelFeaturedPlace place;
  final bool selected;
  final bool enabled;
  final ValueChanged<TravelFeaturedPlace> onPlace;

  @override
  Widget build(BuildContext context) {
    final fill = selected ? AppTheme.navy : Colors.white;
    final ink = selected ? Colors.white : AppTheme.navy;
    final chipKey = '${place.countryId}-${place.label}';
    return Opacity(
      key: Key('explore-featured-dim-$chipKey'),
      opacity: enabled ? 1 : 0.38,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: selected ? AppTheme.navy : AppTheme.navyMid),
        ),
        child: InkWell(
          key: Key('explore-featured-$chipKey'),
          onTap: () => onPlace(place),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              place.label,
              softWrap: false,
              style: TextStyle(
                color: ink,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
