import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/region_catalog.dart';
import 'package:dive_travel_app/core/data/travel_style.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/theme/century_tank_colors.dart';
import 'package:dive_travel_app/core/widgets/listing_cover.dart';
import 'package:dive_travel_app/core/widgets/passport_stamps.dart';
import 'package:dive_travel_app/core/widgets/tank_gauge.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/bookings/presentation/my_bookings_section.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_detail_screen.dart';
import 'package:dive_travel_app/features/reviews/presentation/operation_review_screen.dart';
import 'package:dive_travel_app/features/profile/presentation/departure_desk_header.dart';
import 'package:dive_travel_app/features/profile/presentation/my_crafted_trips_section.dart';
import 'package:dive_travel_app/features/profile/presentation/profile_settings_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final stats = store.stats;
          final crafted = store.craftedProductsFor(store.uid ?? '');
          final favorites = store.favoriteShops;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final paid = [
            for (final booking in store.bookings)
              if (booking.isActive) booking,
          ]..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
          final flags = store.myLiveFlags(now: now);
          final insight = TravelStyleAnalyzer.analyze(
            regions: store.regions,
            stats: stats,
            shops: store.resortHulls,
          );
          final suggested = favorites.isNotEmpty
              ? favorites.first
              : insight.suggestedShop;
          final toReview = [
            for (final booking in store.bookings)
              if (booking.isActive &&
                  !booking.reviewed &&
                  booking.scheduledFor.isBefore(today))
                booking,
          ];

          return ListView(
              key: const Key('profile-departure-desk'),
              padding: EdgeInsets.zero,
              children: [
                SafeArea(
                  bottom: false,
                  child: DepartureDeskHeader(
                    displayName: stats.displayName,
                    regionsCount: stats.uniqueRegionsCount,
                    logCount: stats.totalLogCount,
                    paidBookings: paid.length,
                    isInstructor: stats.isInstructor,
                    onSettings: () => _openSettings(context),
                  ),
                ),
                if (store.loading) const LinearProgressIndicator(minHeight: 2),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _OceanSectionTitle(title: l10n.profileBookingStatus),
                      const SizedBox(height: 12),
                      _HintOrList(
                        plate: 0,
                        empty: l10n.profilePaidBookingsEmpty,
                        onTap: paid.isEmpty
                            ? null
                            : () => _openBookings(context, store),
                        children: [
                          for (final booking in paid.take(3))
                            _Line(
                              title: booking.productName,
                              detail:
                                  '${booking.shopName} · ${DateFormat('yyyy.MM.dd').format(booking.scheduledFor)}',
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _OceanSectionTitle(title: l10n.profileLiveFlagsTitle),
                      const SizedBox(height: 8),
                      _HintOrList(
                        plate: 1,
                        empty: l10n.profileLiveFlagsEmpty,
                        children: [
                          for (final offer in flags)
                            _Line(
                              title: offer.optionName.isEmpty
                                  ? offer.product.name
                                  : '${offer.product.name} / ${offer.optionName}',
                              detail: _flagDetail(offer, now),
                            ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      _OceanSectionTitle(
                        title: l10n.profileSavedOceansTitle,
                        count: favorites.length,
                      ),
                      const SizedBox(height: 12),
                      _SavedOceansRail(
                        plate: 2,
                        shops: favorites,
                        onOpen: (shop) =>
                            openResortDetail(context, shop.hullId),
                        onRemove: store.removeFavoriteShop,
                      ),
                      const SizedBox(height: 30),
                      _OceanSectionTitle(title: l10n.profileNextTripSuggest),
                      const SizedBox(height: 12),
                      _HintOrList(
                        plate: 3,
                        empty: l10n.profileNoUpcomingTrip,
                        onTap: suggested == null
                            ? null
                            : () => openResortDetail(context, suggested.hullId),
                        children: [
                          if (suggested != null)
                            _Line(
                              title: suggested.name,
                              detail: suggested.location,
                            ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      _OceanSectionTitle(title: l10n.profileCraftedTripsTitle),
                      const SizedBox(height: 12),
                      if (crafted.isEmpty)
                        _HintOrList(
                          plate: 0,
                          empty: l10n.profileCraftedTripsHint,
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const TravelProductRegistrationScreen(
                                    creatorMode: true,
                                  ),
                            ),
                          ),
                          tapKey: const Key('profile-crafted-trips-link'),
                          children: const [],
                        )
                      else
                        _LightPanel(
                          plate: 0,
                          child: MyCraftedTripsSection(products: crafted),
                        ),
                      const SizedBox(height: 30),
                      _OceanSectionTitle(title: l10n.profileOceanRecordTitle),
                      const SizedBox(height: 12),
                      _OceanRecordCard(
                        plate: 1,
                        totalLogs: stats.totalLogCount,
                        regions: stats.uniqueRegionsCount,
                        progress: stats.centuryProgress,
                        logsToNext: stats.logsToNextCentury,
                        target: stats.currentCenturyTarget,
                        stamped: {
                          for (final region in store.regions)
                            RegionCatalog.countryOf(region),
                        },
                      ),
                      const SizedBox(height: 30),
                      _OceanSectionTitle(title: l10n.profileAfterTripTitle),
                      const SizedBox(height: 12),
                      _HintOrList(
                        plate: 2,
                        empty: l10n.profileAfterTripEmpty,
                        children: [
                          for (final booking in toReview)
                            _Line(
                              title: booking.productName,
                              detail: booking.shopName,
                              onTap: () => openOperationReview(
                                context,
                                shopId: booking.shopId,
                                bookingId: booking.id,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
          );
        },
      ),
    );
  }

  DiveShop? _shopFor(DiverStore store, String shopId) {
    for (final shop in store.resortHulls) {
      if (shop.hullId == shopId.split('--').first) {
        return shop;
      }
    }
    return null;
  }

  Future<void> _openSettings(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ProfileSettingsScreen()),
    );
  }

  Future<void> _openBookings(BuildContext context, DiverStore store) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.45,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
          child: MyBookingsSection(bookings: store.bookings),
        ),
      ),
    );
  }
}

String _flagDetail(SameBoatOffer offer, DateTime now) {
  final holds = offer.option?.flagHolds ?? offer.product.flagHolds;
  DateTime? until;
  for (final hold in holds) {
    if (!hold.expiresAt.isAfter(now)) {
      continue;
    }
    if (until == null || hold.expiresAt.isBefore(until)) {
      until = hold.expiresAt;
    }
  }
  if (until == null) {
    return '';
  }
  return DateFormat('M.d HH:mm').format(until);
}

class _HintOrList extends StatelessWidget {
  const _HintOrList({
    required this.plate,
    required this.empty,
    required this.children,
    this.onTap,
    this.tapKey,
  });

  final int plate;
  final String empty;
  final List<Widget> children;
  final VoidCallback? onTap;
  final Key? tapKey;

  @override
  Widget build(BuildContext context) {
    final body = children.isEmpty
        ? Text(empty, style: Theme.of(context).textTheme.bodyMedium)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          );
    return _LightPanel(
      plate: plate,
      child: InkWell(key: tapKey, onTap: onTap, child: body),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.title, required this.detail, this.onTap});

  final String title;
  final String detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
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
              ),
            ),
            if (detail.isNotEmpty)
              Text(detail, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _OceanSectionTitle extends StatelessWidget {
  const _OceanSectionTitle({required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: AppTheme.navy, fontWeight: FontWeight.w800),
          ),
        ),
        if (count != null)
          Text(
            '$count',
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: AppTheme.muted),
          ),
      ],
    );
  }
}

class _NextOceanCard extends StatelessWidget {
  const _NextOceanCard({
    required this.plate,
    required this.booking,
    required this.shop,
    required this.onTap,
  });

  final int plate;
  final TourBooking? booking;
  final DiveShop? shop;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final days = booking == null
        ? null
        : TravelStyleAnalyzer.daysUntil(booking!.scheduledFor);

    return _MetalPlate(
      plate: plate,
      child: InkWell(
        key: const Key('profile-next-ocean'),
        onTap: onTap,
        child: SizedBox(
          height: 188,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (shop != null)
                ListingCoverPhoto(shop: shop!)
              else
                const ColoredBox(color: Color(0xFF123F57)),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x22000000), Color(0xE6051D30)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (days != null)
                      _Pill(label: days == 0 ? 'D-DAY' : 'D-$days'),
                    const Spacer(),
                    Text(
                      booking?.shopName ?? l10n.profileNoUpcomingTrip,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      booking == null
                          ? l10n.profileNoUpcomingTripHint
                          : '${booking!.productName} · '
                                '${l10n.profileUpcomingConfirmed(DateFormat('yyyy.MM.dd').format(booking!.scheduledFor))}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedOceansRail extends StatelessWidget {
  const _SavedOceansRail({
    required this.plate,
    required this.shops,
    required this.onOpen,
    required this.onRemove,
  });

  final int plate;
  final List<DiveShop> shops;
  final ValueChanged<DiveShop> onOpen;
  final Future<void> Function(String shopId) onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (shops.isEmpty) {
      return _LightPanel(
        plate: plate,
        child: Row(
          children: [
            const Icon(Icons.favorite_border_rounded, color: AppTheme.ocean),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.profileSavedOceansEmpty,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      height: 176,
      child: ListView.separated(
        key: const Key('profile-saved-oceans'),
        scrollDirection: Axis.horizontal,
        itemCount: shops.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final shop = shops[index];
          return _MetalPlate(
            plate: (plate + index) % _metalPlates.length,
            child: InkWell(
              onTap: () => onOpen(shop),
              child: SizedBox(
                width: 156,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ListingCoverPhoto(shop: shop),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              key: Key('remove-favorite-${shop.hullId}'),
                              onPressed: () => onRemove(shop.hullId),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.9,
                                ),
                                foregroundColor: const Color(0xFFE11D48),
                              ),
                              icon: const Icon(Icons.favorite, size: 17),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            shop.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OceanRecordCard extends StatelessWidget {
  const _OceanRecordCard({
    required this.plate,
    required this.totalLogs,
    required this.regions,
    required this.progress,
    required this.logsToNext,
    required this.target,
    required this.stamped,
  });

  final int plate;
  final int totalLogs;
  final int regions;
  final double progress;
  final int logsToNext;
  final int target;
  final Set<String> stamped;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _LightPanel(
      plate: plate,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 92,
            child: PassportStamps(stamped: stamped, compact: true),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        value: '$totalLogs',
                        label: l10n.profileTotalDives,
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        value: '$regions',
                        label: l10n.profileExploredSeas,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.profileLogsProgress(totalLogs, target),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.profileNextMilestone(logsToNext),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TankGauge(
            key: const Key('profile-tank-gauge'),
            progress: progress,
            isComplete: progress >= 1 && totalLogs > 0,
            label: '$totalLogs',
            width: 64,
            bodyHeight: 126,
            neckWidth: 26,
            neckHeight: 12,
            borderWidth: 3,
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            fillColor: CenturyTankColors.ofLogs(totalLogs),
            borderColor: CenturyTankColors.ofLogs(totalLogs),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: AppTheme.navy, fontWeight: FontWeight.w900),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.plate,
    required this.bookingsCount,
    required this.craftedCount,
    required this.proStatus,
    required this.onBookings,
    required this.onSettings,
    required this.onCraft,
  });

  final int plate;
  final int bookingsCount;
  final int craftedCount;
  final ProVerificationStatus proStatus;
  final VoidCallback? onBookings;
  final VoidCallback onSettings;
  final VoidCallback onCraft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _LightPanel(
      plate: plate,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _ActivityRow(
            key: const Key('profile-booking-history'),
            icon: Icons.airplane_ticket_outlined,
            title: l10n.profileBookingHistory,
            value: l10n.profileBookingCount(bookingsCount),
            onTap: onBookings,
          ),
          const Divider(height: 1),
          _ActivityRow(
            key: const Key('profile-crafted-trips-link'),
            icon: Icons.route_outlined,
            title: l10n.profileCraftedTripsTitle,
            value: craftedCount > 0
                ? l10n.profileCraftedCount(craftedCount)
                : l10n.profileCraftNewTrip,
            onTap: onCraft,
          ),
          const Divider(height: 1),
          _ActivityRow(
            key: const Key('profile-credentials-link'),
            icon: Icons.badge_outlined,
            title: l10n.profileCredentialsTitle,
            value: proStatus == ProVerificationStatus.approved
                ? l10n.profileProBadge
                : l10n.proStatusNone,
            onTap: onSettings,
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2F5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: AppTheme.ocean, size: 19),
      ),
      title: Text(title),
      subtitle: Text(value),
      trailing: onTap == null
          ? null
          : const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
    );
  }
}

class _LightPanel extends StatelessWidget {
  const _LightPanel({
    required this.plate,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final int plate;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return _MetalPlate(
      plate: plate,
      child: Padding(padding: padding, child: child),
    );
  }
}

const _metalPlates = [
  (fill: Color(0xFFF7F6F4), edge: Color(0xFFC5C1BA)),
  (fill: Color(0xFFF3F5F7), edge: Color(0xFFB7C0C8)),
  (fill: Color(0xFFF4F2EE), edge: Color(0xFFC4BDB4)),
  (fill: Color(0xFFF6F4EF), edge: Color(0xFFC9C2B4)),
];

class _MetalPlate extends StatelessWidget {
  const _MetalPlate({required this.plate, required this.child});

  final int plate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final metal = _metalPlates[plate % _metalPlates.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
      color: metal.fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE8EBEE)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: metal.edge),
              Expanded(child: child),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.navy,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
