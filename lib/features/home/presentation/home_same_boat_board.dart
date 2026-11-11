import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/home/presentation/home_stay_card.dart';
import 'package:dive_travel_app/features/shell/presentation/main_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Open same-boat seats, soonest departure first. Past departures are left out.
/// Uses the same public offer list as the same-boat tab.
List<SameBoatOffer> homeOpenSameBoatOffers(
  DiverStore store, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final today = DateTime(clock.year, clock.month, clock.day);
  final open = [
    for (final offer in store.sameBoatOffers(SameBoatFilter.all, now: clock))
      if (!_departed(offer, today)) offer,
  ];
  open.sort((a, b) {
    final ad = a.departureStart;
    final bd = b.departureStart;
    if (ad == null && bd == null) {
      return 0;
    }
    if (ad == null) {
      return 1;
    }
    if (bd == null) {
      return -1;
    }
    return ad.compareTo(bd);
  });
  return open;
}

bool _departed(SameBoatOffer offer, DateTime today) {
  final departure = offer.departureStart;
  if (departure == null) {
    return false;
  }
  final start = DateTime(departure.year, departure.month, departure.day);
  return start.isBefore(today);
}

/// Home "같은 배 · 마감 임박" as a departure board. Hidden when [offers] is empty.
class HomeSameBoatBoard extends StatelessWidget {
  const HomeSameBoatBoard({
    super.key,
    required this.offers,
  });

  final List<SameBoatOffer> offers;

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final store = DiverStoreScope.of(context);
    final now = DateTime.now();
    final rows = offers.take(2).toList();
    var openSeats = 0;
    for (final offer in offers) {
      openSeats += offer.remainingSeatsAt(now);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.homeNextDepartures, style: theme.textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(
          l10n.homeSameBoatBoardSummary(offers.length, openSeats),
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: _BoardHeading(),
                      ),
                    ),
                  ),
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const _DottedDivider(),
                    _BoardRow(
                      offer: rows[i],
                      shopName: _shopName(store, rows[i]),
                      onOpen: () => MainShell.goToTab(context, 2),
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

String _shopName(DiverStore store, SameBoatOffer offer) {
  final hullId = offer.product.shopId.split('--').first;
  for (final shop in store.shops) {
    if (shop.hullId == hullId && shop.name.trim().isNotEmpty) {
      return shop.name.trim();
    }
  }
  final fromStats = store.liveStatsFor(hullId)?.name?.trim() ?? '';
  if (fromStats.isNotEmpty) {
    return fromStats;
  }
  return '';
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
  const _BoardRow({
    required this.offer,
    required this.shopName,
    required this.onOpen,
  });

  final SameBoatOffer offer;
  final String shopName;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final productName = offer.product.name.trim();
    final optionName = offer.optionName.trim();
    final title = optionName.isEmpty
        ? productName
        : (productName.isEmpty ? optionName : '$productName · $optionName');
    final left = offer.remainingSeats;
    final capacity = offer.capacity;
    final showDots = capacity > 0 && capacity <= 8;
    final openDots = left.clamp(0, capacity);
    final filled = capacity - openDots;
    final departure = offer.departureStart;

    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Text(
                departure == null ? '' : homeDayLabel(departure),
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
                    shopName,
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
                      for (var i = 0; i < capacity; i++)
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
            ),
          ],
        ),
      ),
    );
  }
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
