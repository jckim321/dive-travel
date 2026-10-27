import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/region_catalog.dart';
import 'package:dive_travel_app/core/data/travel_style.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/theme/century_tank_colors.dart';
import 'package:dive_travel_app/core/widgets/listing_cover.dart';
import 'package:dive_travel_app/core/widgets/passport_stamps.dart';
import 'package:dive_travel_app/core/widgets/tank_gauge.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/core/models/same_boat_search.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/auth/presentation/auth_sign_in_sheet.dart';
import 'package:dive_travel_app/features/bookings/presentation/booking_voucher_screen.dart';
import 'package:dive_travel_app/features/bookings/presentation/my_bookings_section.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_detail_screen.dart';
import 'package:dive_travel_app/features/explore/presentation/tour_checkout_sheet.dart';
import 'package:dive_travel_app/features/reviews/presentation/my_reviews_screen.dart';
import 'package:dive_travel_app/features/reviews/presentation/operation_review_screen.dart';
import 'package:dive_travel_app/features/profile/presentation/departure_desk_header.dart';
import 'package:dive_travel_app/features/profile/presentation/my_crafted_trips_section.dart';
import 'package:dive_travel_app/features/community/presentation/community_screen.dart';
import 'package:dive_travel_app/features/community/presentation/same_boat_search_bar.dart';
import 'package:dive_travel_app/features/profile/presentation/profile_settings_screen.dart';
import 'package:dive_travel_app/features/shell/presentation/main_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final session = SessionScope.of(context);

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: ListenableBuilder(
        listenable: Listenable.merge([store, session]),
        builder: (context, _) {
          if (!session.isSignedIn) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                child: Column(
                  key: const Key('profile-guest-login'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.profileGuestLoginPrompt,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 22),
                            FilledButton(
                              key: const Key('profile-guest-login-button'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                backgroundColor: AppTheme.navy,
                              ),
                              onPressed: () => ensureSignedIn(context),
                              child: Text(l10n.authLogin),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          final stats = store.stats;
          final crafted = store.craftedProductsFor(store.uid ?? '');
          final favorites = store.favoriteShops;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final activeBookings = [
            for (final booking in store.bookings)
              if (booking.isActive) booking,
          ]..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
          final paidBookings = [
            for (final booking in activeBookings)
              if (booking.isPaid) booking,
          ];
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
                    memberGrade: stats.memberGrade,
                    isInstructor: stats.isInstructor,
                    onSettings: () => _openSettings(context),
                  ),
                ),
                if (stats.gradeCelebrationPending &&
                    TickerMode.of(context) &&
                    (ModalRoute.of(context)?.isCurrent ?? true))
                  _GradeCelebrationHost(
                    grade: stats.gradeCelebrationTo ?? stats.memberGrade,
                    onDismiss: store.clearGradeCelebration,
                  ),
                if (store.loading) const LinearProgressIndicator(minHeight: 2),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _OceanSectionTitle(title: l10n.profileTripScheduleTitle),
                      const SizedBox(height: 12),
                      _TripScheduleBox(
                        bookings: paidBookings,
                        onOpenVoucher: (booking) =>
                            openBookingVoucher(context, booking),
                        onSeeAll: store.bookings.isEmpty
                            ? null
                            : () => _openBookings(context),
                      ),
                      const SizedBox(height: 28),
                      _OceanSectionTitle(title: l10n.profileFlaggedSeatsTitle),
                      const SizedBox(height: 12),
                      _FlaggedSeatsBox(
                        flags: flags,
                        now: now,
                        onPay: (offer) => _payFlag(context, store, offer),
                        onCancel: (offer) =>
                            _cancelFlag(context, store, offer),
                      ),
                      const SizedBox(height: 28),
                      _OceanSectionTitle(title: l10n.mySeatAlertsTitle),
                      const SizedBox(height: 6),
                      Text(
                        l10n.mySeatAlertsHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SeatAlertsBox(store: store, now: now),
                      const SizedBox(height: 28),
                      _OceanSectionTitle(
                        title: l10n.profileWishlistTitle,
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
                      const SizedBox(height: 28),
                      _OceanSectionTitle(title: l10n.profileCraftedTripsTitle),
                      const SizedBox(height: 12),
                      if (crafted.isEmpty)
                        _HintOrList(
                          plate: 0,
                          empty: l10n.profileCraftedTripsHint,
                          onTap: () {
                            final grade = ProfileDisplayGrade.fromMember(
                              grade: stats.memberGrade,
                              isInstructor: stats.isInstructor,
                            );
                            if (grade == ProfileDisplayGrade.silver) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.profileCraftNeedsGold),
                                ),
                              );
                              return;
                            }
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const TravelProductRegistrationScreen(
                                      creatorMode: true,
                                    ),
                              ),
                            );
                          },
                          tapKey: const Key('profile-crafted-trips-link'),
                          children: const [],
                        )
                      else
                        _LightPanel(
                          plate: 0,
                          child: MyCraftedTripsSection(
                            products: crafted,
                            memberGrade: stats.memberGrade,
                            viewerUid: store.uid ?? '',
                          ),
                        ),
                      const SizedBox(height: 28),
                      _OceanSectionTitle(
                        title: l10n.profileReviewRecommendTitle,
                      ),
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
                      const SizedBox(height: 28),
                      _OceanSectionTitle(title: l10n.myReviewsTitle),
                      const SizedBox(height: 12),
                      Material(
                        color: const Color(0xFFE8F4FC),
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          leading: const Icon(Icons.rate_review_outlined),
                          title: Text(l10n.myReviewsMenu),
                          subtitle: Text(l10n.myReviewsMenuHint),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => openMyReviews(context),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _OceanSectionTitle(title: l10n.profileWriteReviewTitle),
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
                                productId: booking.productId,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _OceanSectionTitle(title: l10n.profileCharmsTitle),
                      const SizedBox(height: 10),
                      _OceanCharmsAccessory(
                        totalLogs: stats.totalLogCount,
                        progress: stats.centuryProgress,
                        stamped: {
                          for (final region in store.regions)
                            RegionCatalog.countryOf(region),
                        },
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

  Future<void> _openSettings(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ProfileSettingsScreen()),
    );
  }

  Future<void> _openBookings(BuildContext context) {
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
          child: const MyBookingsSection(),
        ),
      ),
    );
  }

  Future<void> _payFlag(
    BuildContext context,
    DiverStore store,
    SameBoatOffer offer,
  ) async {
    final product = offer.product;
    final shop = _shopForProduct(store, product);
    if (shop == null) {
      return;
    }
    final uid = store.uid ?? '';
    final now = DateTime.now();
    final holds = offer.option?.flagHolds ?? product.flagHolds;
    var party = 1;
    DateTime? payBy;
    for (final hold in holds) {
      if (hold.uid == uid && hold.expiresAt.isAfter(now)) {
        party = hold.seats;
        payBy = hold.expiresAt;
        break;
      }
    }
    await showTourCheckoutSheet(
      context: context,
      shop: shop,
      quote: store.quoteFor(shop),
      product: product,
      lockedOptionId: offer.optionId,
      fromFlag: true,
      lockedPartySize: party,
      flagPayBy: payBy,
    );
  }

  Future<void> _cancelFlag(
    BuildContext context,
    DiverStore store,
    SameBoatOffer offer,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          content: Text(l10n.profileFlagCancelConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.communityPlantFlagLater),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.profileFlagCancelCta),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await store.cancelSeatFlag(
      shopId: offer.product.shopId,
      productId: offer.product.id,
      optionId: offer.optionId,
    );
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
}

class _TripScheduleBox extends StatelessWidget {
  const _TripScheduleBox({
    required this.bookings,
    required this.onOpenVoucher,
    this.onSeeAll,
  });

  final List<TourBooking> bookings;
  final void Function(TourBooking booking) onOpenVoucher;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _LightPanel(
      plate: 0,
      child: bookings.isEmpty
          ? Text(
              l10n.profileTripScheduleEmpty,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final booking in bookings) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          booking.productLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.navy,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        key: Key('profile-voucher-${booking.id}'),
                        onPressed: () => onOpenVoucher(booking),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Text(l10n.bookingVoucherOpen),
                      ),
                    ],
                  ),
                  if (booking != bookings.last) const SizedBox(height: 12),
                ],
                if (onSeeAll != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onSeeAll,
                      child: Text(l10n.exploreMyBookings),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _FlaggedSeatsBox extends StatelessWidget {
  const _FlaggedSeatsBox({
    required this.flags,
    required this.now,
    required this.onPay,
    required this.onCancel,
  });

  final List<SameBoatOffer> flags;
  final DateTime now;
  final void Function(SameBoatOffer offer) onPay;
  final void Function(SameBoatOffer offer) onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _LightPanel(
      plate: 1,
      child: flags.isEmpty
          ? Text(
              l10n.profileFlaggedSeatsEmpty,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final offer in flags) ...[
                  _BlinkingFlagPayButton(
                    label: offer.optionName.isEmpty
                        ? offer.product.name
                        : '${offer.product.name} · ${offer.optionName}',
                    deadline: _holdUntil(offer),
                    onPay: () => onPay(offer),
                    onCancel: () => onCancel(offer),
                  ),
                  if (offer != flags.last) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }

  DateTime? _holdUntil(SameBoatOffer offer) {
    final holds = offer.option?.flagHolds ?? offer.product.flagHolds;
    DateTime? soonest;
    for (final hold in holds) {
      if (!hold.expiresAt.isAfter(now)) continue;
      if (soonest == null || hold.expiresAt.isBefore(soonest)) {
        soonest = hold.expiresAt;
      }
    }
    return soonest ?? offer.flagClosesAt;
  }
}

class _BlinkingFlagPayButton extends StatefulWidget {
  const _BlinkingFlagPayButton({
    required this.label,
    required this.onPay,
    required this.onCancel,
    this.deadline,
  });

  final String label;
  final DateTime? deadline;
  final VoidCallback onPay;
  final VoidCallback onCancel;

  @override
  State<_BlinkingFlagPayButton> createState() => _BlinkingFlagPayButtonState();
}

class _BlinkingFlagPayButtonState extends State<_BlinkingFlagPayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deadline = widget.deadline == null
        ? null
        : DateFormat('MM.dd HH:mm').format(widget.deadline!);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.55, end: 1).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
      ),
      child: Material(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: const Key('profile-flag-pay'),
          onTap: widget.onPay,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.navy,
                        ),
                      ),
                      if (deadline != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.communityFlagPayBy(deadline),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  key: const Key('profile-flag-cancel'),
                  onPressed: widget.onCancel,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(l10n.profileFlagCancelCta),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: widget.onPay,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE67E22),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(l10n.profileFlagPayCta),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cute accessory strip — stamps + tank as charm badges, not a heavy record block.
class _OceanCharmsAccessory extends StatelessWidget {
  const _OceanCharmsAccessory({
    required this.totalLogs,
    required this.progress,
    required this.stamped,
  });

  final int totalLogs;
  final double progress;
  final Set<String> stamped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBF5), Color(0xFFF0F7FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8D9C8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14C4A484),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.72,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 78,
              child: PassportStamps(stamped: stamped, compact: true),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$totalLogs',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppTheme.navy,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.55,
            alignment: Alignment.centerRight,
            child: TankGauge(
              key: const Key('profile-tank-gauge'),
              progress: progress,
              isComplete: progress >= 1 && totalLogs > 0,
              label: '$totalLogs',
              width: 52,
              bodyHeight: 96,
              neckWidth: 20,
              neckHeight: 10,
              borderWidth: 2.5,
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              fillColor: CenturyTankColors.ofLogs(totalLogs),
              borderColor: CenturyTankColors.ofLogs(totalLogs),
            ),
          ),
        ],
      ),
    );
  }
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


class _SeatAlertsBox extends StatelessWidget {
  const _SeatAlertsBox({required this.store, required this.now});

  final DiverStore store;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final alerts = [...store.seatAlerts]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (alerts.isEmpty) {
      return _HintOrList(
        plate: 1,
        empty: l10n.mySeatAlertsEmpty,
        children: const [],
      );
    }
    return _LightPanel(
      plate: 1,
      child: Column(
        children: [
          for (final alert in alerts) ...[
            if (alert != alerts.first) const Divider(height: 1),
            ListTile(
              key: Key('seat-alert-${alert.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                sameBoatAlertSummary(
                  search: alert.search,
                  l10n: l10n,
                  now: now,
                ),
              ),
              subtitle: Text(_matchLabel(l10n, alert.search)),
              trailing: IconButton(
                key: Key('seat-alert-delete-${alert.id}'),
                icon: const Icon(Icons.close),
                onPressed: () async {
                  try {
                    await store.removeSeatAlert(alert.id);
                  } catch (error, stackTrace) {
                    debugPrint('seat alert delete failed $error');
                    debugPrint('$stackTrace');
                  }
                },
              ),
              onTap: () {
                CommunityScreen.openSavedSearch(alert.search);
                MainShell.goToTab(context, 2);
              },
            ),
          ],
        ],
      ),
    );
  }

  String _matchLabel(AppLocalizations l10n, SameBoatSearch search) {
    final count = sameBoatAlertMatchCount(store, search, now: now);
    if (count == 0) {
      return l10n.sameBoatAlertNone;
    }
    return l10n.sameBoatAlertMatchCount(count);
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


class _LightPanel extends StatelessWidget {
  const _LightPanel({
    required this.plate,
    required this.child,
  });

  final int plate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _MetalPlate(
      plate: plate,
      child: Padding(padding: const EdgeInsets.all(18), child: child),
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

/// Grade celebration overlay + confetti. Show once then [onDismiss] clears pending.
class _GradeCelebrationHost extends StatefulWidget {
  const _GradeCelebrationHost({
    required this.grade,
    required this.onDismiss,
  });

  final MemberGrade grade;
  final Future<void> Function() onDismiss;

  @override
  State<_GradeCelebrationHost> createState() => _GradeCelebrationHostState();
}

class _GradeCelebrationHostState extends State<_GradeCelebrationHost>
    with SingleTickerProviderStateMixin {
  var _shown = false;
  late final AnimationController _burst;

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_shown || !mounted) {
      return;
    }
    _shown = true;
    final l10n = AppLocalizations.of(context);
    final label = switch (widget.grade) {
      MemberGrade.silver => l10n.memberGradeSilver,
      MemberGrade.gold => l10n.memberGradeGold,
      MemberGrade.diamond => l10n.memberGradeDiamond,
      MemberGrade.platinum => l10n.memberGradePlatinum,
    };
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Stack(
          children: [
            AnimatedBuilder(
              animation: _burst,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ConfettiPainter(progress: _burst.value),
                  size: Size.infinite,
                );
              },
            ),
            AlertDialog(
              key: const Key('grade-celebration-dialog'),
              title: Text(l10n.gradeCelebrationTitle(label)),
              content: Text(l10n.gradeCelebrationBody(label)),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.gradeCelebrationThanks),
                ),
              ],
            ),
          ],
        );
      },
    );
    await widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const colors = [
      Color(0xFFFFD54F),
      Color(0xFF4FC3F7),
      Color(0xFFFF8A65),
      Color(0xFF81C784),
      Color(0xFFCE93D8),
    ];
    for (var i = 0; i < 48; i++) {
      final t = (progress + i * 0.017) % 1.0;
      final x = (i * 47 % size.width);
      final y = size.height * 0.15 + t * size.height * 0.7;
      paint.color = colors[i % colors.length].withValues(alpha: 1 - t * 0.6);
      canvas.drawCircle(Offset(x, y), 3 + (i % 3).toDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
