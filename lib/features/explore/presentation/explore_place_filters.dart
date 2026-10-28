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
        constraints: const BoxConstraints(maxHeight: 188),
        child: ListView(
          key: const Key('explore-country-menu'),
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          children: [
            if (pacific)
              for (final zone in _zoneOrder) ...[
                Padding(
                  key: Key('explore-zone-$zone'),
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                  child: Text(
                    travelZoneLabel(l10n, zone),
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                for (final country in countries)
                  if (country.zone == zone)
                    _CountryTile(
                      country: country,
                      selected: selectedCountryId == country.id,
                      enabled: countryIdsWithProducts.contains(country.id),
                      onCountry: onCountry,
                    ),
              ]
            else
              for (final country in countries)
                _CountryTile(
                  country: country,
                  selected: selectedCountryId == country.id,
                  enabled: countryIdsWithProducts.contains(country.id),
                  onCountry: onCountry,
                ),
          ],
        ),
      ),
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({
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
    return Opacity(
      key: Key('explore-country-dim-${country.id}'),
      opacity: enabled ? 1 : 0.38,
      child: InkWell(
        key: Key('explore-country-${country.id}'),
        onTap: enabled ? () => onCountry(country.id) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            country.name,
            style: TextStyle(
              color: selected ? AppTheme.navy : AppTheme.muted,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 14,
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
      height: 48,
      child: ListView.separated(
        key: const Key('explore-sea-rail'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        itemCount: seas.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final id = seas[index];
          final selected = selectedSeaId == id;
          return FilterChip(
            key: Key('explore-sea-$id'),
            label: Text(travelSeaLabel(l10n, id)),
            selected: selected,
            showCheckmark: false,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppTheme.navy,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            selectedColor: AppTheme.navy,
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppTheme.navyMid),
            onSelected: (_) => onSelected(id),
          );
        },
      ),
    );
  }
}
