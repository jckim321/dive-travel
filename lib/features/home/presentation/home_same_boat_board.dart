import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/home/presentation/home_stay_card.dart';
import 'package:dive_travel_app/features/shell/presentation/main_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Home "같은 배 · 마감 임박" as a departure board. Hidden when [shops] is empty.
class HomeSameBoatBoard extends StatelessWidget {
  const HomeSameBoatBoard({
    super.key,
    required this.shops,
    required this.onOpen,
  });

  final List<DiveShop> shops;
  final void Function(DiveShop shop) onOpen;

  @override
  Widget build(BuildContext context) {
    if (shops.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rows = shops.take(2).toList();
    var openSeats = 0;
    for (final shop in shops) {
      openSeats += _facts(context, shop).seatsLeft ?? 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.homeNextDepartures, style: theme.textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(
          l10n.homeSameBoatBoardSummary(shops.length, openSeats),
          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.muted),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E8EE)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.white,
              child: Column(
              children: [
                const ColoredBox(
                  color: AppTheme.navy,
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: _BoardHeading(),
                    ),
                  ),
                ),
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const _DottedDivider(),
                  _BoardRow(
                    shop: rows[i],
                    onOpen: () => onOpen(rows[i]),
                  ),
                ],
              ],
            ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => MainShell.goToTab(context, 2),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.gold,
              foregroundColor: AppTheme.navy,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(l10n.homeSameBoatBoardSeeAll),
          ),
        ),
      ],
    );
  }
}

class _BoardHeading extends StatelessWidget {
  const _BoardHeading();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context).homeSameBoatBoardHeading,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _BoardRow extends StatelessWidget {
  const _BoardRow({required this.shop, required this.onOpen});

  final DiveShop shop;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final facts = _facts(context, shop);
    final productName = shop.productName.trim();
    final title = productName.isNotEmpty ? productName : shop.name;
    final left = facts.seatsLeft;
    final showDots = facts.capacity > 0 && facts.capacity <= 8;
    final filled = facts.booked.clamp(0, facts.capacity);

    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Text(
                facts.departure == null ? '' : homeDayLabel(facts.departure!),
                style: const TextStyle(
                  color: AppTheme.ocean,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (showDots)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < facts.capacity; i++)
                        Container(
                          width: 8,
                          height: 8,
                          margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < filled
                                ? const Color(0xFFD5DDE6)
                                : AppTheme.gold,
                          ),
                        ),
                    ],
                  ),
                if (left != null) ...[
                  if (showDots) const SizedBox(height: 4),
                  Text(
                    l10n.homeSameBoatSeatsLeft(left),
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

HomeBoatFacts _facts(BuildContext context, DiveShop shop) {
  final store = DiverStoreScope.of(context);
  final product = homeListingProduct(
    shop,
    store.liveStatsFor(shop.hullId)?.readerProducts ?? const [],
  );
  return homeBoatFacts(shop, product);
}

class _DottedDivider extends StatelessWidget {
  const _DottedDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DotPainter()),
    );
  }
}

class _DotPainter extends CustomPainter {
  const _DotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFD5DDE6);
    const gap = 5.0;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawCircle(Offset(x, y), 1, paint);
      x += gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
