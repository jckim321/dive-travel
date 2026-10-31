import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/payments/payment_gateway.dart';
import 'package:dive_travel_app/core/data/refund_policy.dart';
import 'package:dive_travel_app/core/models/booking_quote.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/ccard_product_frame.dart';
import 'package:dive_travel_app/core/widgets/listing_cover.dart';
import 'package:dive_travel_app/features/auth/presentation/auth_sign_in_sheet.dart';
import 'package:dive_travel_app/features/bookings/presentation/booking_voucher_screen.dart';
import 'package:dive_travel_app/features/explore/presentation/partner_empty_seat_products.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

Future<void> showTourCheckoutSheet({
  required BuildContext context,
  required DiveShop shop,
  required TourPriceQuote quote,
  ShopProduct? product,
  String lockedOptionId = '',
  String presetOptionId = '',
  bool fromFlag = false,
  int lockedPartySize = 0,
  DateTime? flagPayBy,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (context) => TourCheckoutSheet(
        shop: shop,
        quote: quote,
        product: product,
        lockedOptionId: lockedOptionId,
        presetOptionId: presetOptionId,
        fromFlag: fromFlag,
        lockedPartySize: lockedPartySize,
        flagPayBy: flagPayBy,
      ),
    ),
  );
}

bool accountCannotBuy(DiverStore store) =>
    store.stats.isAdmin || store.stats.isBusiness;

class StaffCannotBuyNote extends StatelessWidget {
  const StaffCannotBuyNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        AppLocalizations.of(context).staffCannotBuy,
        key: const Key('staff-cannot-buy'),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.muted,
        ),
      ),
    );
  }
}

class TourCheckoutSheet extends StatefulWidget {
  const TourCheckoutSheet({
    super.key,
    required this.shop,
    required this.quote,
    this.product,
    this.lockedOptionId = '',
    this.presetOptionId = '',
    this.fromFlag = false,
    this.lockedPartySize = 0,
    this.flagPayBy,
  });

  final DiveShop shop;
  final TourPriceQuote quote;
  final ShopProduct? product;
  final String lockedOptionId;
  final String presetOptionId;
  final bool fromFlag;

  /// When > 0 (flag hold), guest total is fixed to this count until pay.
  final int lockedPartySize;

  /// Absolute personal flag pay deadline shown at plant time.
  final DateTime? flagPayBy;

  @override
  State<TourCheckoutSheet> createState() => _TourCheckoutSheetState();
}

class _TourCheckoutSheetState extends State<TourCheckoutSheet> {
  static final _priceFormat = NumberFormat('#,###', 'en_US');
  DateTime _tourDate = DateTime.now().add(const Duration(days: 7));
  var _qtyDiver = 1;
  var _qtyNondiver = 0;
  var _qtyChild = 0;
  var _qtyInfant = 0;
  var _bookPackage = true;
  final _selected = <String>{};
  var _paying = false;
  var _guestSeeded = false;
  var _profileName = '';
  var _profileBirth = '';
  var _profileContact = '';
  final _guestName = TextEditingController();
  final _guestBirth = TextEditingController();
  final _guestContact = TextEditingController();

  bool get _hasProduct => widget.product != null;

  bool get _workbench {
    final product = widget.product;
    if (product == null) {
      return false;
    }
    if (product.usesBookingWorkbench) {
      return true;
    }
    return product.options.any(
      (option) => option.bookable && option.kind == ProductOptionKind.addon,
    );
  }

  BookingQuote get _booking {
    final product = widget.product;
    if (product == null) {
      return const BookingQuote(lines: [], total: 0, freeDivers: 0);
    }
    return BookingQuote.compute(
      product: product,
      professional: widget.quote.isProfessional,
      divers: _qtyDiver,
      nondivers: _qtyNondiver,
      children: _qtyChild,
      infants: _qtyInfant,
      bookPackage: _bookPackage,
      selectedOptionIds: _selected,
    );
  }

  @override
  void initState() {
    super.initState();
    final start = widget.shop.departure?.start;
    if (start != null) {
      _tourDate = start;
    }
    _applyOption(widget.presetOptionId);
    _applyOption(widget.lockedOptionId);
    final departure = widget.product?.departureStart;
    if (departure != null) {
      _tourDate = departure;
    }
    if (_buyerPicksDeparture) {
      _tourDate = buyerDepartureDay(now: DateTime.now(), preferred: _tourDate);
    }
    if (widget.lockedPartySize > 0) {
      _qtyDiver = widget.lockedPartySize;
      _qtyNondiver = 0;
      _qtyChild = 0;
      _qtyInfant = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_guestSeeded) return;
    final store = DiverStoreScope.of(context);
    if (store.uid == null || store.loading) return;
    _guestSeeded = true;
    _profileName = store.profileGuestName.trim();
    _profileBirth = store.stats.birthDate.trim();
    _profileContact = store.stats.phone.trim();
    if (_profileName.isNotEmpty) _guestName.text = _profileName;
    if (_profileBirth.isNotEmpty) _guestBirth.text = _profileBirth;
    if (_profileContact.isNotEmpty) _guestContact.text = _profileContact;
  }

  @override
  void dispose() {
    _guestName.dispose();
    _guestBirth.dispose();
    _guestContact.dispose();
    super.dispose();
  }

  bool get _guestReady =>
      _guestName.text.trim().isNotEmpty &&
      _guestBirth.text.trim().isNotEmpty &&
      _guestContact.text.trim().isNotEmpty;

  bool get _choiceReady =>
      !_workbench || _bookPackage || _selected.isNotEmpty;

  bool get _partyLocked =>
      widget.fromFlag && widget.lockedPartySize > 0;

  /// Flag payment uses the price captured at plant time. Older holds with no
  /// snapshot, and every normal checkout, keep the live quote.
  int _payable(BuildContext context) {
    return CheckoutCharge.resolve(
      fromFlag: widget.fromFlag,
      lockedPartySize: widget.lockedPartySize,
      lockedPrice: _flagLockedPrice(context) ?? 0,
      divers: _qtyDiver,
      nondivers: _qtyNondiver,
      children: _qtyChild,
      infants: _qtyInfant,
      product: widget.product,
      professional: widget.quote.isProfessional,
      bookPackage: _bookPackage,
      selectedOptionIds: _selected,
      quoteAmount: widget.quote.amount,
    ).total;
  }

  int? _flagLockedPrice(BuildContext context) {
    if (!widget.fromFlag) {
      return null;
    }
    final product = widget.product;
    if (product == null) {
      return null;
    }
    final uid = DiverStoreScope.of(context).uid ?? '';
    if (uid.isEmpty) {
      return null;
    }
    final hold = product.liveFlagFor(
      uid,
      DateTime.now(),
      optionId: widget.lockedOptionId,
    );
    if (hold == null || hold.lockedPrice <= 0) {
      return null;
    }
    return hold.lockedPrice;
  }

  void _applyOption(String id) {
    final product = widget.product;
    if (id.isEmpty || product == null) {
      return;
    }
    ShopProductOption? option;
    for (final item in product.options) {
      if (item.id == id) {
        option = item;
      }
    }
    if (option == null) {
      return;
    }
    if (option.kind == ProductOptionKind.individual) {
      _bookPackage = false;
      _selected
        ..clear()
        ..add(option.id);
    } else {
      _bookPackage = true;
      _selected.add(option.id);
    }
  }

  ShopProductOption? _findOption(String id) {
    final product = widget.product;
    if (product == null || id.isEmpty) {
      return null;
    }
    for (final option in product.options) {
      if (option.id == id) {
        return option;
      }
    }
    return null;
  }

  /// Seat inventory id. An add-on chosen on the product card is a price line,
  /// not the berth the party occupies.
  String get _seatOptionId {
    if (widget.lockedOptionId.isNotEmpty) {
      return widget.lockedOptionId;
    }
    if (!_bookPackage) {
      for (final id in _selected) {
        final option = _findOption(id);
        if (option != null &&
            option.kind == ProductOptionKind.individual &&
            option.openEmptySeats) {
          return id;
        }
      }
    }
    return '';
  }

  bool get _checksSeats {
    final product = widget.product;
    if (product == null) {
      return false;
    }
    if (widget.lockedOptionId.isNotEmpty) {
      return true;
    }
    if (_seatOptionId.isNotEmpty) {
      return true;
    }
    return product.openEmptySeats && _bookPackage;
  }

  Future<void> _pickDate() async {
    final today = calendarDay(DateTime.now());
    var initial = calendarDay(_tourDate);
    if (initial.isBefore(today)) initial = today;
    final last = today.add(const Duration(days: 180));
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: last,
    );
    if (picked != null && mounted) {
      setState(() => _tourDate = calendarDay(picked));
    }
  }

  int get _partySize => _qtyDiver + _qtyNondiver + _qtyChild + _qtyInfant;

  bool get _buyerPicksDeparture {
    final product = widget.product;
    if (product == null || widget.fromFlag) return false;
    return !product.openEmptySeats;
  }

  DateTime? get _buyerReturn {
    if (!_buyerPicksDeparture) return null;
    return buyerReturnDay(
      departure: _tourDate,
      durationLabel: widget.product?.durationLabel,
    );
  }

  bool get _dateLocked {
    if (_buyerPicksDeparture) return false;
    if (widget.product?.departureStart != null) return true;
    if (widget.product != null) return false;
    return widget.shop.departure != null;
  }

  DiveShop get _displayShop {
    final product = widget.product;
    if (product == null) {
      return widget.shop;
    }
    final photos = [
      for (final url in product.photoUrls)
        if (url.trim().isNotEmpty) url.trim(),
    ];
    final cover = product.coverUrl.trim().isNotEmpty
        ? product.coverUrl.trim()
        : (photos.isNotEmpty ? photos.first : widget.shop.coverUrl);
    return widget.shop.copyWith(
      productName: product.name,
      consumerPrice: product.consumerPrice,
      professionalPrice: product.professionalPrice,
      blurb: product.blurb.isNotEmpty ? product.blurb : widget.shop.blurb,
      coverUrl: cover,
      galleryUrls: photos.isNotEmpty ? photos : widget.shop.galleryUrls,
    );
  }

  Future<void> _pay() async {
    if (_paying || !_guestReady) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    if (accountCannotBuy(store)) {
      return;
    }
    setState(() => _paying = true);
    try {
      if (!await ensureSignedIn(context)) {
        return;
      }
      if (!mounted || store.uid == null) {
        return;
      }
      final amount = _payable(context);
      final product = widget.product;
      final party = _hasProduct ? _partySize : 1;
      if (product != null) {
        // min_guests is legacy / unused by the product form — do not block checkout.
        if (product.maxGuests > 0 && party > product.maxGuests) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.checkoutGuestsAboveMax(product.maxGuests))),
          );
          return;
        }
      }
      final seatOption = _seatOptionId;
      final opensSeats = _checksSeats;
      if (opensSeats && product != null) {
        final room = product.bookableSeatsFor(
          store.uid ?? '',
          DateTime.now(),
          optionId: seatOption,
        );
        if (party > room) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.communitySeatsShort)));
          return;
        }
      }
      final paid = await const SimPayGateway().pay(
        amountWon: amount,
        title: _hasProduct ? _chosenLabels() : widget.shop.name,
      );
      if (!paid || !mounted) {
        return;
      }
      final recordOption = seatOption.isNotEmpty
          ? seatOption
          : (widget.presetOptionId.isNotEmpty
                ? widget.presetOptionId
                : (_selected.isEmpty ? '' : _selected.first));
      final saved = await store.createBooking(
        shop: widget.shop,
        price: amount,
        tourDate: _tourDate,
        productId: product?.id,
        productName: _hasProduct
            ? (product?.name ?? widget.shop.productName)
            : widget.shop.productName,
        optionName: _optionLabelsOnly(),
        partySize: party,
        optionId: recordOption,
        seatOptionId: seatOption,
        listingKind: product?.listingKind ?? ProductListingKind.exploreOnly,
        fromFlag: widget.fromFlag,
        divers: _hasProduct ? _qtyDiver : 1,
        nondivers: _hasProduct ? _qtyNondiver : 0,
        children: _hasProduct ? _qtyChild : 0,
        infants: _hasProduct ? _qtyInfant : 0,
        quoteLines: _hasProduct ? _booking.lines : const [],
        // Paid SimPay checkout: auto-confirm; defaults stay requested/unpaid elsewhere.
        status: BookingStatus.confirmed,
        paymentStatus: PaymentStatus.captured,
        guestDisplayName: _guestName.text,
        guestBirthDate: _guestBirth.text,
        guestContact: _guestContact.text,
      );
      if (!mounted) {
        return;
      }
      if (saved == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exploreBookingNotSaved)),
        );
        return;
      }
      final navigator = Navigator.of(context);
      final overlayContext = navigator.overlay?.context;
      navigator.pop();
      if (overlayContext != null && overlayContext.mounted) {
        await openBookingVoucher(overlayContext, saved);
      }
    } finally {
      _paying = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Widget _payButtonChild(String label) {
    if (!_paying) {
      return Text(label);
    }
    return const SizedBox(
      key: Key('checkout-pay-progress'),
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final shop = _displayShop;
    final product = widget.product;
    final quote = widget.quote;
    final store = DiverStoreScope.of(context);
    final cannotBuy = accountCannotBuy(store);
    final saved = store.isFavoriteShop(widget.shop.id);
    final refund = RefundPolicy.forUserCancel(tourDate: _tourDate);
    final payAmount = _payable(context);
    final formatted = _priceFormat.format(payAmount);
    final label = quote.isProfessional
        ? l10n.exploreProPrice
        : l10n.exploreConsumerPrice;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final cancelNote = product?.cancellationNote.trim() ?? '';
    final diveStarLine = () {
      if (!shop.showsDiveStarBadge) {
        return '';
      }
      if (shop.isDiveStarExpired) {
        return '· ${l10n.exploreDiveStarRenewalNeeded}';
      }
      final marks = diveStarGradeMarks(shop.stars);
      return marks.isEmpty
          ? '· ${l10n.exploreDiveStarCertified}'
          : '· ${l10n.exploreDiveStarCertified} $marks';
    }();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.exploreCheckoutTitle),
      ),
      body: Column(
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
                              badgeLabel: shop.isDiveStarExpired
                                  ? l10n.exploreDiveStarRenewalNeeded
                                  : l10n.exploreDiveStarCertified,
                              certified: shop.isDiveStarCertified,
                              showBadge: shop.showsDiveStarBadge,
                              badgeFaded: shop.isDiveStarExpired,
                              badgeGrade: shop.isDiveStarExpired
                                  ? 0
                                  : shop.stars,
                              onClose: () => Navigator.of(context).pop(),
                              onFavorite: () async {
                                if (!await ensureSignedIn(context)) return;
                                if (!context.mounted) return;
                                await store.toggleFavoriteShop(widget.shop.id);
                              },
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
                              l10n.exploreCheckoutBody(
                                shop.name,
                                shop.location,
                              ),
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
                            if (product != null &&
                                product.blurb.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                product.blurb.trim(),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
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
                                const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: AppTheme.navy,
                                ),
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
                                if (diveStarLine.isNotEmpty)
                                  Opacity(
                                    opacity: shop.isDiveStarExpired ? 0.45 : 1,
                                    child: Text(
                                      diveStarLine,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const Divider(),
                            const SizedBox(height: 14),
                            _HostRow(shop: shop, l10n: l10n),
                            if (shop.isDiveStarCertified) ...[
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
                            if (product != null) ...[
                              ..._productDetailCards(l10n, theme, product),
                            ],
                            if (shop.sites.isNotEmpty) ...[
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
                                      avatar: const Icon(
                                        Icons.waves_outlined,
                                        size: 16,
                                      ),
                                      label: Text(site),
                                      backgroundColor: const Color(0xFFF7F4EE),
                                      side: const BorderSide(
                                        color: Color(0xFFE8E1D4),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                            if (shop.amenities.isNotEmpty) ...[
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check,
                                        size: 18,
                                        color: AppTheme.navy,
                                      ),
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
                            ],
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
                                    key: Key(
                                      _buyerPicksDeparture
                                          ? 'checkout-departure-date'
                                          : 'checkout-tour-date',
                                    ),
                                    label: _buyerPicksDeparture
                                        ? '출발일'
                                        : l10n.weatherTourDate,
                                    value: DateFormat(
                                      'yyyy.MM.dd',
                                    ).format(_tourDate),
                                    valueKey: const Key(
                                      'checkout-departure-value',
                                    ),
                                    onTap: _dateLocked ? null : _pickDate,
                                  ),
                                ),
                                if (_buyerReturn != null) ...[
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _DateBox(
                                      key: const Key('checkout-return-date'),
                                      label: '돌아오는 날',
                                      value: DateFormat(
                                        'yyyy.MM.dd',
                                      ).format(_buyerReturn!),
                                      valueKey: const Key(
                                        'checkout-return-value',
                                      ),
                                    ),
                                  ),
                                ],
                                if (!_hasProduct) ...[
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _DateBox(
                                      label: l10n.exploreListingGuests,
                                      value: l10n.exploreListingGuestOne,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_hasProduct) ...[
                              _guestQtyBlock(l10n, theme),
                              const SizedBox(height: 12),
                            ],
                            if (_workbench) ...[
                              _bookingPanel(l10n, theme),
                              const SizedBox(height: 12),
                            ],
                            _guestIdentityFields(l10n),
                            const SizedBox(height: 24),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (cannotBuy) const StaffCannotBuyNote(),
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
                  const SizedBox(height: 8),
                  Text(
                    cancelNote.isNotEmpty
                        ? cancelNote
                        : l10n.refundPolicyHint(refund.percent),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const Key('explore-checkout-pay'),
                    onPressed: cannotBuy ||
                            !_guestReady ||
                            !_choiceReady ||
                            _paying
                        ? null
                        : _pay,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.navy,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                    ),
                    child: _payButtonChild(l10n.explorePayAmount(formatted)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _guestIdentityFields(AppLocalizations l10n) {
    final rows = <Widget>[
      if (_profileName.isNotEmpty)
        _guestShown(l10n.checkoutGuestName, _profileName)
      else
        TextField(
          key: const Key('checkout-guest-name'),
          controller: _guestName,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.checkoutGuestName,
            isDense: true,
          ),
        ),
      if (_profileBirth.isNotEmpty)
        _guestShown(l10n.checkoutGuestBirth, _profileBirth)
      else
        TextField(
          key: const Key('checkout-guest-birth'),
          controller: _guestBirth,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.datetime,
          decoration: InputDecoration(
            labelText: l10n.checkoutGuestBirth,
            hintText: 'YYYY-MM-DD',
            isDense: true,
          ),
        ),
      if (_profileContact.isNotEmpty)
        _guestShown(l10n.checkoutGuestContact, _profileContact)
      else
        TextField(
          key: const Key('checkout-guest-contact'),
          controller: _guestContact,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: l10n.checkoutGuestContact,
            isDense: true,
          ),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          rows[i],
        ],
      ],
    );
  }

  Widget _guestShown(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.muted,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }

  String? _flagPayByLabel() {
    if (!widget.fromFlag) {
      return null;
    }
    final payBy = widget.flagPayBy ??
        ShopProduct.personalFlagUntil(
          DateTime.now(),
          _findOption(_seatOptionId)?.flagClosesAt ??
              widget.product?.flagClosesAt,
        );
    return DateFormat('yyyy.MM.dd HH:mm').format(payBy);
  }

  String _chosenLabels() {
    final product = widget.product;
    if (product == null) {
      return widget.shop.productName;
    }
    final options = _optionLabelsOnly();
    if (options.isEmpty) {
      return product.name;
    }
    if (_bookPackage) {
      return '${product.name} · $options';
    }
    return options;
  }

  /// Option / add-on names only (no package product name).
  String _optionLabelsOnly() {
    final product = widget.product;
    if (product == null) {
      return '';
    }
    if (_bookPackage) {
      return [
        for (final id in _selected)
          if (_findOption(id)?.kind == ProductOptionKind.addon &&
              (_findOption(id)?.parentOptionId.isEmpty ?? true))
            _findOption(id)!.name,
      ].join(' · ');
    }
    return [
      for (final id in _selected)
        if (_findOption(id)?.kind == ProductOptionKind.individual ||
            _findOption(id)?.kind == ProductOptionKind.addon)
          _findOption(id)!.name,
    ].join(' · ');
  }

  String? get _selectedIndividualId {
    for (final id in _selected) {
      final option = _findOption(id);
      if (option != null && option.kind == ProductOptionKind.individual) {
        return option.id;
      }
    }
    return null;
  }

  List<Widget> _productDetailCards(
    AppLocalizations l10n,
    ThemeData theme,
    ShopProduct product,
  ) {
    final cards = <Widget>[];
    void addCard(IconData icon, String title, String body) {
      if (body.trim().isEmpty) {
        return;
      }
      cards.add(const SizedBox(height: 16));
      cards.add(
        _HighlightCard(icon: icon, title: title, body: body.trim()),
      );
    }

    addCard(
      Icons.nights_stay_outlined,
      l10n.productOfferNights,
      product.derivedDurationLabel,
    );
    addCard(
      Icons.place_outlined,
      l10n.productFormMeetingPoint,
      product.meetingPoint,
    );
    if (product.schedule.trim().isNotEmpty) {
      cards.add(const SizedBox(height: 16));
      cards.add(
        _MarkdownDetailCard(
          icon: Icons.route_outlined,
          title: l10n.briefSectionDays,
          markdown: product.schedule.trim(),
        ),
      );
    }
    addCard(
      Icons.check_circle_outline,
      l10n.productFormIncludes,
      product.includes,
    );
    addCard(
      Icons.remove_circle_outline,
      l10n.productFormExcludes,
      product.excludes,
    );
    addCard(
      Icons.event_busy_outlined,
      l10n.productFormCancelNote,
      product.cancellationNote,
    );
    addCard(
      Icons.school_outlined,
      l10n.productFormDifficulty,
      product.difficulty,
    );
    if (product.maxGuests > 0) {
      addCard(
        Icons.groups_outlined,
        l10n.checkoutGuests,
        '${l10n.productFormMaxGuests} ${product.maxGuests}',
      );
    }
    return cards;
  }

  Widget _bookingPanel(AppLocalizations l10n, ThemeData theme) {
    final product = widget.product!;
    if (!_bookPackage) {
      final parentId = _selectedIndividualId ?? '';
      final addons = [
        for (final option in product.options)
          if (option.kind == ProductOptionKind.addon &&
              option.bookable &&
              parentId.isNotEmpty &&
              option.parentOptionId == parentId)
            option,
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _chosenLabels(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          for (final option in addons)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _selected.contains(option.id),
              title: Text(option.name),
              subtitle: option.description.trim().isEmpty
                  ? null
                  : Text(option.description.trim()),
              enabled: widget.lockedOptionId != option.id,
              onChanged: widget.lockedOptionId == option.id
                  ? null
                  : (value) {
                      setState(() {
                        if (value ?? false) {
                          _selected.add(option.id);
                        } else {
                          _selected.remove(option.id);
                        }
                      });
                    },
            ),
          const SizedBox(height: 8),
          _compositionAmounts(),
        ],
      );
    }
    final addons = [
      for (final option in product.options)
        if (option.kind == ProductOptionKind.addon &&
            option.bookable &&
            option.parentOptionId.isEmpty)
          option,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.checkoutPackageOn} · ${product.name}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        for (final option in addons)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _selected.contains(option.id),
            title: Text(option.name),
            subtitle: option.description.trim().isEmpty
                ? null
                : Text(option.description.trim()),
            enabled: widget.lockedOptionId != option.id,
            onChanged: widget.lockedOptionId == option.id
                ? null
                : (value) {
                    setState(() {
                      if (value ?? false) {
                        _selected.add(option.id);
                      } else {
                        _selected.remove(option.id);
                      }
                    });
                  },
          ),
        _compositionAmounts(),
      ],
    );
  }

  Widget _compositionAmounts() {
    final lines = _booking.lines;
    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(child: Text(line.label)),
                Text(_priceFormat.format(line.amount)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _guestQtyBlock(AppLocalizations l10n, ThemeData theme) {
    final product = widget.product!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.checkoutGuests, style: theme.textTheme.titleSmall),
        if (_partyLocked) ...[
          const SizedBox(height: 6),
          Text(
            l10n.communityFlagPartyLocked(widget.lockedPartySize),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_flagPayByLabel() != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.communityFlagPayBy(_flagPayByLabel()!),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
        for (final rate in product.resolvedGuestRates)
          if (rate.enabled) _qtyRow(l10n, rate.role),
      ],
    );
  }

  Widget _qtyRow(AppLocalizations l10n, GuestRole role) {
    final label = switch (role) {
      GuestRole.diver => l10n.workbenchGuestDiver,
      GuestRole.nondiver => l10n.workbenchGuestNondiver,
      GuestRole.child => l10n.workbenchGuestChild,
      GuestRole.infant => l10n.workbenchGuestInfant,
    };
    final value = switch (role) {
      GuestRole.diver => _qtyDiver,
      GuestRole.nondiver => _qtyNondiver,
      GuestRole.child => _qtyChild,
      GuestRole.infant => _qtyInfant,
    };
    final locked = _partyLocked;
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          onPressed: locked || value == 0
              ? null
              : () => setState(() => _setQty(role, value - 1)),
          icon: const Icon(Icons.remove),
        ),
        Text('$value'),
        IconButton(
          onPressed: locked
              ? null
              : () => setState(() => _setQty(role, value + 1)),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  void _setQty(GuestRole role, int value) {
    if (_partyLocked) {
      return;
    }
    switch (role) {
      case GuestRole.diver:
        _qtyDiver = value;
      case GuestRole.nondiver:
        _qtyNondiver = value;
      case GuestRole.child:
        _qtyChild = value;
      case GuestRole.infant:
        _qtyInfant = value;
    }
  }
}

class _PhotoMosaic extends StatelessWidget {
  const _PhotoMosaic({
    required this.shop,
    required this.saved,
    required this.badgeLabel,
    required this.certified,
    this.showBadge = true,
    this.badgeFaded = false,
    this.badgeGrade = 0,
    required this.onClose,
    required this.onFavorite,
  });

  final DiveShop shop;
  final bool saved;
  final String badgeLabel;
  final bool certified;
  final bool showBadge;
  final bool badgeFaded;
  final int badgeGrade;
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
                _RoundIcon(icon: Icons.close, onPressed: onClose),
                if (showBadge) ...[
                  const SizedBox(height: 8),
                  ListingCertBadge(
                    label: badgeLabel,
                    certified: certified,
                    faded: badgeFaded,
                    grade: badgeGrade,
                  ),
                ],
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
  const _PhotoTile({required this.shop, this.shift = 0, this.radius = 0});

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

class _MarkdownDetailCard extends StatelessWidget {
  const _MarkdownDetailCard({
    required this.icon,
    required this.title,
    required this.markdown,
  });

  final IconData icon;
  final String title;
  final String markdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              MarkdownBody(
                data: markdown,
                shrinkWrap: true,
                softLineBreak: true,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: const TextStyle(
                    color: AppTheme.muted,
                    height: 1.4,
                    fontSize: 13,
                  ),
                  h3: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF344054),
                  ),
                  tableBody: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                  tableHead: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFF344054),
                  ),
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
    super.key,
    required this.label,
    required this.value,
    this.valueKey,
    this.onTap,
  });

  final String label;
  final String value;
  final Key? valueKey;
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
                key: valueKey,
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
