import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/travel_country_master.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/explore/presentation/explore_shop_query.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

const _zoneOrder = <String>[
  TravelZone.micronesia,
  TravelZone.melanesia,
  TravelZone.polynesia,
  TravelZone.other,
];

String travelZoneLabel(AppLocalizations l10n, String zone) {
  return switch (zone) {
    TravelZone.micronesia => l10n.exploreZoneMicronesia,
    TravelZone.melanesia => l10n.exploreZoneMelanesia,
    TravelZone.polynesia => l10n.exploreZonePolynesia,
    TravelZone.other => l10n.exploreZoneOther,
    _ => zone,
  };
}

String travelSeaLabel(AppLocalizations l10n, String seaId) {
  return switch (seaId) {
    TravelSea.indian => l10n.exploreSeaIndian,
    TravelSea.red => l10n.exploreSeaRed,
    TravelSea.caribbean => l10n.exploreSeaCaribbean,
    TravelSea.southPacific => l10n.exploreSeaSouthPacific,
    exploreSeaUnmatched => l10n.exploreOtherRegion,
    _ => seaId,
  };
}

/// Country list for the open region. Pacific rows keep their zone titles.
class ExploreCountryMenu extends StatelessWidget {
  const ExploreCountryMenu({
    super.key,
    required this.regionId,
    required this.selectedCountryId,
    required this.countryIdsWithProducts,
    required this.onCountry,
  });

  final String regionId;
  final String? selectedCountryId;
  final Set<String> countryIdsWithProducts;
  final ValueChanged<String> onCountry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final countries = [
      for (final country in TravelCountryMaster.countries)
        if (country.regionId == regionId) country,
    ];
    final pacific = regionId == TravelRegionId.pacific;

    return Material(
      color: AppTheme.seaMist,
      child: ConstrainedBox(
        key: const Key('explore-country-menu'),
        constraints: const BoxConstraints(maxHeight: 240),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (pacific)
                for (final zone in _zoneOrder) ...[
                  Padding(
                    key: Key('explore-zone-$zone'),
                    padding: const EdgeInsets.only(top: 8, bottom: 6),
                    child: Text(
                      travelZoneLabel(l10n, zone),
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final country in countries)
                        if (country.zone == zone)
                          _CountryChip(
                            country: country,
                            selected: selectedCountryId == country.id,
                            enabled: countryIdsWithProducts.contains(country.id),
                            onCountry: onCountry,
                          ),
                    ],
                  ),
                ]
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final country in countries)
                      _CountryChip(
                        country: country,
                        selected: selectedCountryId == country.id,
                        enabled: countryIdsWithProducts.contains(country.id),
                        onCountry: onCountry,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryChip extends StatelessWidget {
  const _CountryChip({
    required this.country,
    required this.selected,
    required this.enabled,
    required this.onCountry,
  });

  final TravelCountry country;
  final bool selected;
  final bool enabled;
  final ValueChanged<String> onCountry;

  @override
  Widget build(BuildContext context) {
    final fill = selected ? AppTheme.navy : Colors.white;
    final ink = selected ? Colors.white : AppTheme.navy;
    return Opacity(
      key: Key('explore-country-dim-${country.id}'),
      opacity: enabled ? 1 : 0.38,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: selected ? AppTheme.navy : AppTheme.navyMid),
        ),
        child: InkWell(
          key: Key('explore-country-${country.id}'),
          onTap: enabled ? () => onCountry(country.id) : null,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              country.name,
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

/// Indian Ocean, Red Sea, Caribbean, South Pacific, and unmatched.
class ExploreSeaRail extends StatelessWidget {
  const ExploreSeaRail({
    super.key,
    required this.selectedSeaId,
    required this.onSelected,
  });

  final String? selectedSeaId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final seas = [...TravelSea.all, exploreSeaUnmatched];

    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        key: const Key('explore-sea-rail'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (var index = 0; index < seas.length; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              _SeaChip(
                id: seas[index],
                label: travelSeaLabel(l10n, seas[index]),
                selected: selectedSeaId == seas[index],
                onSelected: () => onSelected(seas[index]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeaChip extends StatelessWidget {
  const _SeaChip({
    required this.id,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String id;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: Key('explore-sea-$id'),
      color: selected ? AppTheme.navy : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: selected ? AppTheme.navy : AppTheme.navyMid),
      ),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            softWrap: false,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.navy,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
