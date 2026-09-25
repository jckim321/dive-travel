import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/refund_policy.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/ccard_product_frame.dart';
import 'package:dive_travel_app/core/widgets/listing_cover.dart';
import 'package:dive_travel_app/features/community/presentation/open_tide_room.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

Future<void> showTourCheckoutSheet({
  required BuildContext context,
  required DiveShop shop,
  required TourPriceQuote quote,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => TourCheckoutSheet(shop: shop, quote: quote),
  );
}

class TourCheckoutSheet extends StatefulWidget {
  const TourCheckoutSheet({
    super.key,
    required this.shop,
    required this.quote,
  });

  final DiveShop shop;
  final TourPriceQuote quote;

  @override
  State<TourCheckoutSheet> createState() => _TourCheckoutSheetState();
}

class _TourCheckoutSheetState extends State<TourCheckoutSheet> {
  static final _priceFormat = NumberFormat('#,###', 'en_US');
  DateTime _tourDate = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    final start = widget.shop.departure?.start;
    if (start != null) {
      _tourDate = start;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tourDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null) {
      setState(() => _tourDate = picked);
    }
  }

  Future<void> _pay() async {
    final l10n = AppLocalizations.of(context);
    final quote = widget.quote;
    final label = quote.isProfessional
        ? l10n.exploreProPrice
        : l10n.exploreConsumerPrice;
    final formatted = _priceFormat.format(quote.amount);
    await DiverStoreScope.of(context).createBooking(
      shop: widget.shop,
      price: quote.amount,
      tourDate: _tourDate,
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.exploreCheckoutDone(label, formatted))),
    );
    if (!mounted) {
      return;
    }
    await offerOpenTideRoom(
      context: context,
      shop: widget.shop,
      tourDate: _tourDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final shop = widget.shop;
    final quote = widget.quote;
    final store = DiverStoreScope.of(context);
    final saved = store.isFavoriteShop(shop.id);
    final refund = RefundPolicy.forUserCancel(tourDate: _tourDate);
    final formatted = _priceFormat.format(quote.amount);
    final label = quote.isProfessional
        ? l10n.exploreProPrice
        : l10n.exploreConsumerPrice;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.94,
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: CCardProductFrame(
                      child: _PhotoMosaic(
                        shop: shop,
                        saved: saved,
                        badgeLabel: shop.isDiveStarCertified
                            ? l10n.exploreDiveStarCertified
                            : shop.isNewListing
                                ? l10n.exploreListingNew
                                : l10n.exploreListingPendingReview,
                        certified: shop.isDiveStarCertified,
                        onClose: () => Navigator.of(context).pop(),
                        onFavorite: () => store.toggleFavoriteShop(shop.id),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  sliver: SliverList.list(
                    children: [
                      Text(
                        shop.productName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.exploreCheckoutBody(shop.name, shop.location),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${shop.country} · ${shop.location}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.muted,
                        ),
                      ),
                      if (shop.departure != null) ...[
                        const SizedBox(height: 16),
                        _HighlightCard(
                          icon: Icons.sailing_outlined,
                          title: shop.departure!.windowLabel,
                          body: l10n.exploreDepartureBody(
                            shop.departure!.emptySeats,
                            shop.departure!.capacity,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _HighlightCard(
                          icon: Icons.cloud_off_outlined,
                          title: l10n.exploreWeatherRefundTitle,
                          body: l10n.exploreWeatherRefundBody,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 16, color: AppTheme.navy),
                          Text(
                            shop.reviewCount > 0
                                ? l10n.exploreRating(
                                    shop.rating.toStringAsFixed(2),
                                    shop.reviewCount,
                                  )
                                : l10n.exploreStarPending,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          if (shop.stars > 0)
                            Text(
                              '· ${l10n.exploreDiveStar(shop.stars)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Divider(),
                      const SizedBox(height: 14),
                      _HostRow(shop: shop, l10n: l10n),
                      if (shop.stars > 0) ...[
                        const SizedBox(height: 16),
                        _HighlightCard(
                          icon: Icons.workspace_premium_outlined,
                          title: l10n.exploreRareFind,
                          body: l10n.exploreRareFindBody,
                        ),
                      ],
                      const SizedBox(height: 16),
                      _HighlightCard(
                        icon: Icons.health_and_safety_outlined,
                        title: l10n.exploreListingSafetyTitle,
                        body: l10n.exploreListingSafetyBody,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        l10n.exploreListingSites,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final site in shop.sites)
                            Chip(
                              avatar: const Icon(Icons.waves_outlined, size: 16),
                              label: Text(site),
                              backgroundColor: const Color(0xFFF7F4EE),
                              side: const BorderSide(color: Color(0xFFE8E1D4)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        l10n.exploreListingAmenities,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final amenity in shop.amenities)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.check, size: 18, color: AppTheme.navy),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  amenity,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.exploreCheckoutTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _DateBox(
                              label: l10n.weatherTourDate,
                              value: DateFormat('yyyy.MM.dd').format(_tourDate),
                              onTap: shop.departure == null ? _pickDate : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DateBox(
                              label: l10n.exploreListingGuests,
                              value: l10n.exploreListingGuestOne,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.refundPolicyHint(refund.percent),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.exploreWontChargeYet,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.muted,
                        ),
                      ),
                      const SizedBox(height: 88),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Material(
            elevation: 12,
            shadowColor: const Color(0x330B1F33),
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              l10n.explorePriceWon(formatted),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              l10n.explorePerTrip,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: quote.isProfessional
                                ? AppTheme.gold
                                : AppTheme.navy,
                          ),
                        ),
                        if (quote.hasDiscount)
                          Text(
                            l10n.exploreOriginalPrice(
                              _priceFormat.format(quote.compareAtAmount!),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ),
                  FilledButton(
                    key: const Key('explore-checkout-pay'),
                    onPressed: _pay,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.navy,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                    ),
                    child: Text(l10n.explorePay),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoMosaic extends StatelessWidget {
  const _PhotoMosaic({
    required this.shop,
    required this.saved,
    required this.badgeLabel,
    required this.certified,
    required this.onClose,
    required this.onFavorite,
  });

  final DiveShop shop;
  final bool saved;
  final String badgeLabel;
  final bool certified;
  final VoidCallback onClose;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 248,
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(flex: 3, child: _PhotoTile(shop: shop, radius: 0)),
              const SizedBox(width: 4),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Expanded(child: _PhotoTile(shop: shop, shift: 0.2)),
                    const SizedBox(height: 4),
                    Expanded(child: _PhotoTile(shop: shop, shift: 0.45)),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RoundIcon(
                  icon: Icons.close,
                  onPressed: onClose,
                ),
                const SizedBox(height: 8),
                ListingCertBadge(
                  label: badgeLabel,
                  certified: certified,
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: _RoundIcon(
              icon: saved ? Icons.favorite : Icons.favorite_border,
              color: saved ? const Color(0xFFE11D48) : AppTheme.navy,
              onPressed: onFavorite,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.shop,
    this.shift = 0,
    this.radius = 0,
  });

  final DiveShop shop;
  final double shift;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final accent = Color(shop.accentColor);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent, AppTheme.ocean, AppTheme.oceanDeep],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FractionalTranslation(
              translation: Offset(shift, 0),
              child: ListingCoverPhoto(shop: shop),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x11000000), Color(0x66052A4A)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.onPressed,
    this.color = AppTheme.navy,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class _HostRow extends StatelessWidget {
  const _HostRow({required this.shop, required this.l10n});

  final DiveShop shop;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppTheme.goldSoft,
          child: Icon(Icons.scuba_diving, color: Color(shop.accentColor)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.exploreHostedBy(shop.name),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                shop.location,
                style: const TextStyle(color: AppTheme.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.navy),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  color: AppTheme.muted,
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF222222), width: 1.2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
