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
        final products = store.sameBoatProducts(filter, now: now);
        final all = store.sameBoatProducts(SameBoatFilter.all, now: now);
        final lastCallCount = SameBoatBoard.filtered(
          all,
          SameBoatFilter.lastCall,
          now,
        ).length;
        final openSeats = all.fold<int>(
          0,
          (sum, product) => sum + product.remainingSeats,
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
                if (products.isEmpty)
                  AppCard(
                    child: Text(
                      l10n.communityEmpty,
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                else
                  for (final product in products) ...[
                    _SeatCard(
                      product: product,
                      shopName: store.shopLabelFor(product.shopId),
                      onTake: () => _takeSeat(context, store, product),
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
    ShopProduct product,
  ) async {
    final l10n = AppLocalizations.of(context);
    final until = ShopProduct.personalFlagUntil(
      DateTime.now(),
      product.flagClosesAt,
    );
    final deadline = DateFormat('M.d HH:mm').format(until);
    final plant = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          content: Text(l10n.communityFlagHoldAsk(deadline)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.communityPlantFlagLater),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.communityPlantFlag),
            ),
          ],
        );
      },
    );
    if (plant != true || !context.mounted) {
      return;
    }
    await store.plantSeatFlag(
      shopId: product.shopId,
      productId: product.id,
      partySize: 1,
    );
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
      quote: TourPriceQuote(
        amount: product.consumerPrice,
        isProfessional: false,
      ),
      product: product,
    );
  }
}

DiveShop? _shopForProduct(DiverStore store, ShopProduct product) {
  final listings = store.listingsOnHull(product.shopId);
  for (final shop in listings) {
    if (shop.productName == product.name || shop.id == product.shopId) {
      return shop.copyWith(
        productName: product.name,
        consumerPrice: product.consumerPrice,
        professionalPrice: product.professionalPrice,
      );
    }
  }
  if (listings.isEmpty) {
    return null;
  }
  return listings.first.copyWith(
    productName: product.name,
    consumerPrice: product.consumerPrice,
    professionalPrice: product.professionalPrice,
  );
}

class _SeatCard extends StatelessWidget {
  const _SeatCard({
    required this.product,
    required this.shopName,
    required this.onTake,
  });

  final ShopProduct product;
  final String shopName;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final departure = product.departureStart;
    final flag = product.flagClosesAt;
    final title = shopName.isEmpty ? product.name : shopName;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('same-boat-${product.id}'),
        onTap: onTake,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EBEE)),
            boxShadow: AppTheme.cardShadow,
          ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
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
                _SeatMeter(product: product),
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
  const _SeatMeter({required this.product});

  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    final capacity = product.capacity;
    if (capacity <= 0) {
      return const SizedBox.shrink();
    }
    final paid = product.bookedSeats.clamp(0, capacity).toInt();
    final held = product.flaggedSeats.clamp(0, capacity - paid).toInt();
    Color tone(int index) {
      if (index < paid) {
        return AppTheme.navy;
      }
      if (index < paid + held) {
        return const Color(0xFFE8A54B);
      }
      return const Color(0xFFE4E7EB);
    }
    final l10n = AppLocalizations.of(context);
    final open = capacity - paid - held;
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
          '${l10n.communitySeatPaid(paid)} · ${l10n.communitySeatHeld(held)} · ${l10n.communitySeatOpen(open)}',
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


