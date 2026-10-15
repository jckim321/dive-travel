import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/region_catalog.dart';
import 'package:dive_travel_app/core/data/travel_style.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/theme/century_tank_colors.dart';
import 'package:dive_travel_app/core/widgets/listing_cover.dart';
import 'package:dive_travel_app/core/widgets/passport_stamps.dart';
import 'package:dive_travel_app/core/widgets/tank_gauge.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/bookings/presentation/my_bookings_section.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_detail_screen.dart';
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
      backgroundColor: AppTheme.oceanDeep,
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final stats = store.stats;
          final nextTrip = TravelStyleAnalyzer.nextTrip(store.bookings);
          final nextShop = nextTrip == null
              ? null
              : _shopFor(store, nextTrip.shopId);
          final crafted = store.craftedProductsFor(store.uid ?? '');
          final favorites = store.favoriteShops;

          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF061B2E),
                  AppTheme.oceanDeep,
                  Color(0xFF0A3B55),
                ],
              ),
            ),
            child: ListView(
              key: const Key('profile-departure-desk'),
              padding: EdgeInsets.zero,
              children: [
                SafeArea(
                  bottom: false,
                  child: DepartureDeskHeader(
                    displayName: stats.displayName,
                    regionsCount: stats.uniqueRegionsCount,
                    logCount: stats.totalLogCount,
                    onSettings: () => _openSettings(context),
                  ),
                ),
                if (store.loading) const LinearProgressIndicator(minHeight: 2),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _OceanSectionTitle(title: l10n.profileNextOceanTitle),
                      const SizedBox(height: 12),
                      _NextOceanCard(
                        booking: nextTrip,
                        shop: nextShop,
                        onTap: nextShop == null
                            ? null
                            : () => openResortDetail(context, nextShop.hullId),
                      ),
                      const SizedBox(height: 30),
                      _OceanSectionTitle(
                        title: l10n.profileSavedOceansTitle,
                        count: favorites.length,
                      ),
                      const SizedBox(height: 12),
                      _SavedOceansRail(
                        shops: favorites,
                        onOpen: (shop) =>
                            openResortDetail(context, shop.hullId),
                        onRemove: store.removeFavoriteShop,
                      ),
                      const SizedBox(height: 30),
                      _OceanSectionTitle(title: l10n.profileOceanRecordTitle),
                      const SizedBox(height: 12),
                      _OceanRecordCard(
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
                      _OceanSectionTitle(title: l10n.profileActivityTitle),
                      const SizedBox(height: 12),
                      _ActivityCard(
                        bookingsCount: store.bookings.length,
                        craftedCount: crafted.length,
                        proStatus: stats.proStatus,
                        onBookings: store.bookings.isEmpty
                            ? null
                            : () => _openBookings(context, store),
                        onSettings: () => _openSettings(context),
                        onCraft: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const TravelProductRegistrationScreen(
                                  creatorMode: true,
                                ),
                          ),
                        ),
                      ),
                      if (crafted.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _LightPanel(
                          child: MyCraftedTripsSection(products: crafted),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
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
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ),
        if (count != null)
          Text(
            '$count',
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: AppTheme.goldSoft),
          ),
      ],
    );
  }
}

class _NextOceanCard extends StatelessWidget {
  const _NextOceanCard({
    required this.booking,
    required this.shop,
    required this.onTap,
  });

  final TourBooking? booking;
  final DiveShop? shop;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final days = booking == null
        ? null
        : TravelStyleAnalyzer.daysUntil(booking!.scheduledFor);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
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
    required this.shops,
    required this.onOpen,
    required this.onRemove,
  });

  final List<DiveShop> shops;
  final ValueChanged<DiveShop> onOpen;
  final Future<void> Function(String shopId) onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (shops.isEmpty) {
      return _LightPanel(
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
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
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
    required this.totalLogs,
    required this.regions,
    required this.progress,
    required this.logsToNext,
    required this.target,
    required this.stamped,
  });

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
    required this.bookingsCount,
    required this.craftedCount,
    required this.proStatus,
    required this.onBookings,
    required this.onSettings,
    required this.onCraft,
  });

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
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      elevation: 3,
      shadowColor: const Color(0x66001424),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
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
