import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:intl/intl.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/app_card.dart';
import 'package:dive_travel_app/features/explore/presentation/tour_checkout_sheet.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

enum _TideFilter { all, lastCall, departing }

class _DesignPreview {
  const _DesignPreview({required this.offer, required this.shopName});

  final SameBoatOffer offer;
  final String shopName;
}

List<_DesignPreview> _designPreviews(DateTime now) {
  final soon = now.add(const Duration(days: 4));
  final later = now.add(const Duration(days: 18));
  final earlyDeparture = now.add(const Duration(days: 3));
  final lateFlag = now.add(const Duration(days: 12));
  return [
    _DesignPreview(
      shopName: '블루홀 다이브',
      offer: SameBoatOffer(
        product: ShopProduct(
          id: 'preview-blue-hole',
          shopId: 'preview-blue-hole',
          name: '블루홀 라이브어보드',
          consumerPrice: 890000,
          professionalPrice: 790000,
          blurb: '팀이 잡힌 3박 4일 일정에 캐빈 한 자리가 남았습니다.',
          options: [
            ShopProductOption(
              id: 'deluxe',
              name: '디럭스 캐빈',
              description: '2인실, 전용 욕실.',
              kind: ProductOptionKind.individual,
              openEmptySeats: true,
              capacity: 8,
              bookedSeats: 3,
              flagHolds: [
                SeatHold(
                  seats: 2,
                  expiresAt: now.add(const Duration(hours: 20)),
                ),
              ],
              departureStart: later,
              flagClosesAt: soon,
            ),
          ],
        ),
        option: ShopProductOption(
          id: 'deluxe',
          name: '디럭스 캐빈',
          description: '2인실, 전용 욕실.',
          kind: ProductOptionKind.individual,
          openEmptySeats: true,
          capacity: 8,
          bookedSeats: 3,
          flagHolds: [
            SeatHold(
              seats: 2,
              expiresAt: now.add(const Duration(hours: 20)),
            ),
          ],
          departureStart: later,
          flagClosesAt: soon,
        ),
      ),
    ),
    _DesignPreview(
      shopName: '케라마 보트',
      offer: SameBoatOffer(
        product: ShopProduct(
          id: 'preview-kerama',
          shopId: 'preview-kerama',
          name: '케라마 당일 보트',
          consumerPrice: 180000,
          professionalPrice: 150000,
          openEmptySeats: true,
          capacity: 6,
          bookedSeats: 4,
          departureStart: later,
          flagClosesAt: soon,
        ),
      ),
    ),
    _DesignPreview(
      shopName: '팔라우 어젠다',
      offer: SameBoatOffer(
        product: ShopProduct(
          id: 'preview-palau',
          shopId: 'preview-palau',
          name: '저먼 채널 데이 트립',
          consumerPrice: 240000,
          professionalPrice: 210000,
          detail: '오전 출항, 오후 귀항.',
          openEmptySeats: true,
          capacity: 5,
          bookedSeats: 1,
          departureStart: earlyDeparture,
          flagClosesAt: lateFlag,
        ),
      ),
    ),
  ];
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  _TideFilter _filter = _TideFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final now = DateTime.now();
        final filter = switch (_filter) {
          _TideFilter.all => SameBoatFilter.all,
          _TideFilter.lastCall => SameBoatFilter.lastCall,
          _TideFilter.departing => SameBoatFilter.departing,
        };
        final offers = store.sameBoatOffers(filter, now: now);
        final all = store.sameBoatOffers(SameBoatFilter.all, now: now);
        final lastCallCount = store
            .sameBoatOffers(SameBoatFilter.lastCall, now: now)
            .length;
        final openSeats = all.fold<int>(
          0,
          (sum, offer) => sum + offer.remainingSeatsAt(now),
        );

        return Scaffold(
          backgroundColor: AppTheme.canvas,
          body: SafeArea(
            bottom: false,
            child: ListView(
              key: const Key('tide-board'),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 108),
              children: [
                _TideHeader(
                  openSeats: openSeats,
                  departureCount: all.length,
                  lastCallCount: lastCallCount,
                ),
                if (lastCallCount > 0) ...[
                  const SizedBox(height: 14),
                  _UrgentStrip(
                    count: lastCallCount,
                    onTap: () => setState(() => _filter = _TideFilter.lastCall),
                  ),
                ],
                const SizedBox(height: 16),
                _TideSegmentFilter(
                  value: _filter,
                  onChanged: (next) => setState(() => _filter = next),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.communityBoardList,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.communityBoardListHint,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (all.isEmpty) ...[
                  Text(
                    l10n.communityDesignPreview,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  for (final entry in _designPreviews(now).indexed) ...[
                    _SeatCard(
                      offer: entry.$2.offer,
                      plate: entry.$1,
                      shopName: entry.$2.shopName,
                      onTake: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.communityDesignPreviewFlag),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ] else if (offers.isEmpty)
                  AppCard(
                    child: Text(
                      l10n.communityEmpty,
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                else
                  for (var i = 0; i < offers.length; i++) ...[
                    _SeatCard(
                      offer: offers[i],
                      plate: i,
                      shopName: store.shopLabelFor(offers[i].product.shopId),
                      onTake: () => _takeSeat(context, store, offers[i]),
                    ),
                    const SizedBox(height: 12),
                  ],
                const SizedBox(height: 8),
                Text(
                  l10n.communityHostMileage,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _takeSeat(
    BuildContext context,
    DiverStore store,
    SameBoatOffer offer,
  ) async {
    final l10n = AppLocalizations.of(context);
    final product = offer.product;
    if (store.uid == null || store.uid!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communityNeedSignIn)),
      );
      return;
    }
    final now = DateTime.now();
    final open = offer.remainingSeatsAt(now);
    if (open <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communitySeatsShort)),
      );
      return;
    }
    final until = ShopProduct.personalFlagUntil(now, offer.flagClosesAt);
    final deadline = DateFormat('yyyy.MM.dd HH:mm').format(until);
    final shortened = offer.flagClosesAt != null &&
        offer.flagClosesAt!.isBefore(now.add(const Duration(hours: 24)));
    final partySize = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        var seats = 1;
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.communityFlagPayBy(deadline),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (shortened) ...[
                    const SizedBox(height: 6),
                    Text(l10n.communityFlagPayByShortened),
                  ],
                  const SizedBox(height: 12),
                  Text(l10n.communityFlagHoldAsk(deadline)),
                  const SizedBox(height: 16),
                  Text(l10n.communityFlagPartyAsk(open)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: seats <= 1
                            ? null
                            : () => setLocal(() => seats -= 1),
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        '$seats',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        onPressed: seats >= open
                            ? null
                            : () => setLocal(() => seats += 1),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l10n.communityPlantFlagLater),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, seats),
                  child: Text(l10n.communityPlantFlag),
                ),
              ],
            );
          },
        );
      },
    );
    if (partySize == null || partySize <= 0 || !context.mounted) {
      return;
    }
    final planted = await store.plantSeatFlag(
      shopId: product.shopId,
      productId: product.id,
      partySize: partySize,
      optionId: offer.optionId,
    );
    if (!context.mounted) {
      return;
    }
    if (planted == SeatFlagPlant.alreadyHeld) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communityFlagAlready)),
      );
    }
    if (planted == SeatFlagPlant.unavailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communitySeatsShort)),
      );
      return;
    }
    if (!context.mounted) {
      return;
    }
    final shop = _shopForProduct(store, product);
    if (shop == null) {
      return;
    }
    await showTourCheckoutSheet(
      context: context,
      shop: shop,
      quote: store.quoteFor(shop),
      product: product,
      lockedOptionId: offer.optionId,
      fromFlag: true,
      lockedPartySize: partySize,
      flagPayBy: until,
    );
  }
}

DiveShop? _shopForProduct(DiverStore store, ShopProduct product) {
  final hullId = product.shopId.split('--').first;
  final listings = store.listingsOnHull(hullId);
  DiveShop? hull;
  for (final shop in listings) {
    if (shop.listingProductId == product.id) {
      return store.listingCardForProduct(shop, product);
    }
    hull ??= shop;
  }
  if (hull == null) {
    for (final shop in store.shops) {
      if (shop.hullId == hullId) {
        hull = shop;
        break;
      }
    }
  }
  if (hull == null) {
    return null;
  }
  return store.listingCardForProduct(hull, product);
}

class _SeatCard extends StatelessWidget {
  const _SeatCard({
    required this.offer,
    required this.plate,
    required this.shopName,
    required this.onTake,
  });

  final SameBoatOffer offer;
  final int plate;
  final String shopName;
  final VoidCallback onTake;

  static const _plates = [
    (fill: Color(0xFFF7F6F4), edge: Color(0xFFC5C1BA)),
    (fill: Color(0xFFF3F5F7), edge: Color(0xFFB7C0C8)),
    (fill: Color(0xFFF4F2EE), edge: Color(0xFFC4BDB4)),
    (fill: Color(0xFFF6F4EF), edge: Color(0xFFC9C2B4)),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final product = offer.product;
    final departure = offer.departureStart;
    final flag = offer.flagClosesAt;
    final title = shopName.isEmpty ? product.name : shopName;
    final metal = _plates[plate % _plates.length];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('same-boat-${product.id}-${offer.optionId}'),
        onTap: onTake,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: metal.fill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EBEE)),
            boxShadow: AppTheme.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: IntrinsicHeight(
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: metal.edge),
                Expanded(
                  child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (offer.optionName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: metal.edge.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      offer.optionName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.navy,
                      ),
                    ),
                  ),
                ],
                if (product.detail.isNotEmpty ||
                    product.blurb.isNotEmpty ||
                    offer.optionDescription.isNotEmpty)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(l10n.communityOfferDetail),
                    children: [
                      if (product.blurb.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(product.blurb),
                        ),
                      if (product.detail.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(product.detail),
                        ),
                      if (offer.optionDescription.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(offer.optionDescription),
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
                _DateLine(
                  departure: departure,
                  flagClose: flag,
                  todayLabel: l10n.communityDateToday,
                  flagLabel: l10n.workbenchFlagDeadline,
                  departureLabel: l10n.workbenchDepartureDate,
                ),
                const SizedBox(height: 14),
                _SeatMeter(
                  capacity: offer.capacity,
                  paid: offer.bookedSeats,
                  held: offer.flaggedSeatsAt(DateTime.now()),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.communityFlagOneSeat,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.muted,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: onTake,
                    child: Text(l10n.communityPlantFlag),
                  ),
                ),
              ],
            ),
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateLine extends StatelessWidget {
  const _DateLine({
    required this.departure,
    required this.flagClose,
    required this.todayLabel,
    required this.flagLabel,
    required this.departureLabel,
  });

  final DateTime? departure;
  final DateTime? flagClose;
  final String todayLabel;
  final String flagLabel;
  final String departureLabel;

  @override
  Widget build(BuildContext context) {
    final marks = <({DateTime at, String label, Color color})>[
      (
        at: DateTime.now(),
        label: todayLabel,
        color: AppTheme.muted,
      ),
      if (flagClose != null)
        (
          at: flagClose!,
          label: flagLabel,
          color: const Color(0xFFE8A54B),
        ),
      if (departure != null)
        (
          at: departure!,
          label: departureLabel,
          color: AppTheme.ocean,
        ),
    ]..sort((a, b) => a.at.compareTo(b.at));
    final day = DateFormat('M.d');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < marks.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(top: 5),
                color: const Color(0xFFE4E7EB),
              ),
            ),
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: marks[i].color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                marks[i].label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.navy,
                ),
              ),
              Text(
                day.format(marks[i].at),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.muted,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SeatMeter extends StatelessWidget {
  const _SeatMeter({
    required this.capacity,
    required this.paid,
    required this.held,
  });

  final int capacity;
  final int paid;
  final int held;

  @override
  Widget build(BuildContext context) {
    if (capacity <= 0) {
      return const SizedBox.shrink();
    }
    final paidSeats = paid.clamp(0, capacity).toInt();
    final heldSeats = held.clamp(0, capacity - paidSeats).toInt();
    Color tone(int index) {
      if (index < paidSeats) {
        return AppTheme.navy;
      }
      if (index < paidSeats + heldSeats) {
        return const Color(0xFFE8A54B);
      }
      return const Color(0xFFE4E7EB);
    }
    final l10n = AppLocalizations.of(context);
    final open = capacity - paidSeats - heldSeats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < capacity; i++)
              Container(
                width: 22,
                height: 28,
                decoration: BoxDecoration(
                  color: tone(i),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${l10n.communitySeatPaid(paidSeats)} · ${l10n.communitySeatHeld(heldSeats)} · ${l10n.communitySeatOpen(open)}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.muted,
          ),
        ),
      ],
    );
  }
}

class _TideHeader extends StatelessWidget {
  const _TideHeader({
    required this.openSeats,
    required this.departureCount,
    required this.lastCallCount,
  });

  final int openSeats;
  final int departureCount;
  final int lastCallCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.communityTideKicker,
          style: const TextStyle(
            color: AppTheme.ocean,
            fontSize: 11,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.communityTideHeadline,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                height: 1.2,
                color: AppTheme.navy,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.communityTideBody,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                value: '$openSeats',
                label: l10n.communityStatOpenSeats,
                accent: AppTheme.ocean,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStat(
                value: '$departureCount',
                label: l10n.communityFilterAll,
                accent: AppTheme.navy,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStat(
                value: '$lastCallCount',
                label: l10n.communityFilterLastCall,
                accent: lastCallCount > 0
                    ? const Color(0xFFB42318)
                    : AppTheme.muted,
                warn: lastCallCount > 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.accent,
    this.warn = false,
  });

  final String value;
  final String label;
  final Color accent;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: warn ? const Color(0xFFFBE9E7) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: warn ? const Color(0xFFF2C4BE) : const Color(0xFFE8EBEE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: accent,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgentStrip extends StatelessWidget {
  const _UrgentStrip({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: const Color(0xFFFBE9E7),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.local_fire_department_outlined,
                color: Color(0xFFB42318),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.communityUrgentBanner(count),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB42318),
                    fontSize: 13,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFB42318)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TideSegmentFilter extends StatelessWidget {
  const _TideSegmentFilter({
    required this.value,
    required this.onChanged,
  });

  final _TideFilter value;
  final ValueChanged<_TideFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EBEE)),
      ),
      child: Row(
        children: [
          for (final entry in [
            (_TideFilter.all, l10n.communityFilterAll),
            (_TideFilter.lastCall, l10n.communityFilterLastCall),
            (_TideFilter.departing, l10n.communityFilterDeparting),
          ])
            Expanded(
              child: _SegmentCell(
                label: entry.$2,
                selected: value == entry.$1,
                onTap: () => onChanged(entry.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentCell extends StatelessWidget {
  const _SegmentCell({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.navy : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : AppTheme.muted,
            ),
          ),
        ),
      ),
    );
  }
}


