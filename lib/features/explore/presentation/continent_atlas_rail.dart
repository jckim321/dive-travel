import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/travel_country_master.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Horizontal ocean-atlas continent filter with full readable labels.
class ContinentAtlasRail extends StatelessWidget {
  const ContinentAtlasRail({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      height: 92,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF052A4A),
              Color(0xFF0B3A4F),
              Color(0xFF164A5C),
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _AtlasWashPainter()),
            ),
            ListView.separated(
              key: const Key('continent-atlas-rail'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              itemCount: TravelRegionId.menu.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final id = TravelRegionId.menu[index];
                return _AtlasNode(
                  id: id,
                  label: travelRegionLabel(l10n, id),
                  selected: selectedId == id,
                  onTap: () => onSelected(id),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

String travelRegionLabel(AppLocalizations l10n, String id) {
  return switch (id) {
    TravelRegionId.all => l10n.exploreFilterAll,
    TravelRegionId.asia => l10n.exploreContinentAsia,
    TravelRegionId.pacific => l10n.exploreRegionPacific,
    TravelRegionId.europe => l10n.exploreContinentEurope,
    TravelRegionId.africa => l10n.exploreRegionAfricaRed,
    TravelRegionId.northAmerica => l10n.exploreRegionNorthAmerica,
    TravelRegionId.southAmerica => l10n.exploreRegionSouthAmerica,
    _ => id,
  };
}

class _AtlasNode extends StatelessWidget {
  const _AtlasNode({
    required this.id,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = selected ? AppTheme.gold : const Color(0xFF8AA4B8);
    final fill = selected
        ? AppTheme.gold.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.06);

    return InkWell(
      key: Key('continent-filter-$id'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: Border.all(color: ring, width: selected ? 2 : 1.2),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppTheme.gold.withValues(alpha: 0.45),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                _iconFor(id),
                size: 18,
                color: selected ? AppTheme.goldSoft : const Color(0xFFB8CDD8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              softWrap: false,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppTheme.goldSoft : Colors.white.withValues(alpha: 0.88),
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String id) {
    return switch (id) {
      TravelRegionId.all => Icons.public,
      TravelRegionId.asia => Icons.waves_outlined,
      TravelRegionId.pacific => Icons.scuba_diving,
      TravelRegionId.europe => Icons.explore_outlined,
      TravelRegionId.africa => Icons.wb_sunny_outlined,
      TravelRegionId.northAmerica => Icons.terrain_outlined,
      TravelRegionId.southAmerica => Icons.landscape_outlined,
      _ => Icons.circle_outlined,
    };
  }
}

class _AtlasWashPainter extends CustomPainter {
  const _AtlasWashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.18 + i * 0.16);
      final path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(
          size.width * 0.35,
          y + (i.isEven ? 6 : -5),
          size.width * 0.7,
          y,
        )
        ..quadraticBezierTo(
          size.width * 0.88,
          y + (i.isEven ? -4 : 5),
          size.width,
          y + 1,
        );
      canvas.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
