import 'package:dive_travel_app/core/models/booking_quote.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

enum ProVerificationStatus {
  none,
  pending,
  approved,
  rejected;

  static ProVerificationStatus parse(dynamic value) {
    if (value == true || value == 'true' || value == 'approved') {
      return ProVerificationStatus.approved;
    }
    if (value == 'pending') {
      return ProVerificationStatus.pending;
    }
    if (value == 'rejected') {
      return ProVerificationStatus.rejected;
    }
    return ProVerificationStatus.none;
  }

  /// Firestore `is_verified_pro`에 기록하는 값. 대기 중은 pending 문자열입니다.
  Object get firestoreValue {
    switch (this) {
      case ProVerificationStatus.pending:
        return 'pending';
      case ProVerificationStatus.approved:
        return true;
      case ProVerificationStatus.rejected:
        return 'rejected';
      case ProVerificationStatus.none:
        return false;
    }
  }
}

class TourBooking {
  const TourBooking({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.productName,
    required this.price,
    required this.createdAt,
    this.uid = '',
    this.tourDate,
    this.reviewed = false,
    this.status = BookingStatus.requested,
    this.refundPercent = 0,
    this.refundAmount = 0,
    this.refundNoticeSeen = false,
    this.commissionRate = 0.12,
    this.paymentStatus = PaymentStatus.unpaid,
    this.productId = '',
    this.optionId = '',
    this.optionName = '',
    this.listingKind = ProductListingKind.exploreOnly,
    this.fromFlag = false,
    this.partySize = 0,
    this.divers = 0,
    this.nondivers = 0,
    this.children = 0,
    this.infants = 0,
    this.quoteLines = const [],
    this.seatsHeld = 0,
    this.seatOptionId = '',
    this.guestDisplayName = '',
    this.guestBirthDate = '',
    this.guestContact = '',
    this.partnerAckedAt,
    this.cancelledAt,
  });

  final String id;
  final String uid;
  final String shopId;
  final String shopName;
  final String productName;
  final String productId;
  final String optionId;
  /// Add-on or individual option labels, separate from [productName].
  final String optionName;
  final ProductListingKind listingKind;
  final bool fromFlag;
  final int price;
  final DateTime createdAt;
  final DateTime? tourDate;
  final bool reviewed;
  final BookingStatus status;
  final int refundPercent;
  final int refundAmount;
  final bool refundNoticeSeen;
  final double commissionRate;
  final PaymentStatus paymentStatus;
  final int partySize;
  final int divers;
  final int nondivers;
  final int children;
  final int infants;
  final List<BookingLine> quoteLines;
  /// Seats charged to `booked_seats` at create time; restore only when > 0.
  final int seatsHeld;
  /// Option used for seat inventory (may differ from display [optionId]).
  final String seatOptionId;

  /// Snapshot of the guest's profile/login display name at booking time.
  /// Empty when unset — partners show 「예약자 이름 없음」. Never email local-part.
  final String guestDisplayName;

  /// Booker's own booking only. Shop copies and vouchers stay empty.
  final String guestBirthDate;

  /// Booker's own booking only. Shop copies and vouchers stay empty.
  final String guestContact;

  /// Partner 「확인했어요」 read receipt (shop booking doc only).
  final DateTime? partnerAckedAt;

  /// When the shop copy was cancelled or weather-cancelled.
  /// Read from the existing `cancelled_at` field. Overview uses this only.
  final DateTime? cancelledAt;

  bool get partnerAcked => partnerAckedAt != null;

  DateTime get scheduledFor => tourDate ?? createdAt;

  /// Guest can still cancel / shop can still act on this booking.
  bool get isActive =>
      status == BookingStatus.requested || status == BookingStatus.confirmed;

  bool get isPaid => paymentStatus == PaymentStatus.captured;

  /// Shop/admin can still confirm the request and/or capture payment.
  bool get awaitsShopConfirm =>
      isActive &&
      (status == BookingStatus.requested ||
          paymentStatus == PaymentStatus.unpaid);

  bool get isWeatherCancelled => status == BookingStatus.weatherCancelled;
  bool get needsRefundNotice =>
      isWeatherCancelled && !refundNoticeSeen;

  /// Flag checkouts stay in their own sales bucket.
  String get salesKind =>
      fromFlag ? 'flag' : listingKind.firestoreValue;

  bool get hasPartyDetail =>
      divers > 0 || nondivers > 0 || children > 0 || infants > 0;

  /// Package / product title for list rows.
  String get productLabel {
    final name = productName.trim();
    if (name.isEmpty) {
      return shopName;
    }
    if (optionName.trim().isNotEmpty) {
      return name;
    }
    final parts = name.split(' · ');
    return parts.first.trim().isEmpty ? shopName : parts.first.trim();
  }

  /// Option / add-on line; recovers from quote lines or legacy combined names.
  String get optionLabel {
    final named = optionName.trim();
    if (named.isNotEmpty) {
      return named;
    }
    if (quoteLines.length > 1) {
      return [
        for (final line in quoteLines.skip(1)) line.label.trim(),
      ].where((label) => label.isNotEmpty).join(' · ');
    }
    final parts = productName.split(' · ');
    if (parts.length > 1) {
      return parts.skip(1).join(' · ').trim();
    }
    return '';
  }

  /// Title shown on My Bookings; falls back to shop name when empty.
  String get displayTitle {
    final option = optionLabel;
    if (option.isEmpty) {
      return productLabel;
    }
    return '$productLabel · $option';
  }

  TourBooking copyWith({
    bool? reviewed,
    BookingStatus? status,
    int? refundPercent,
    int? refundAmount,
    bool? refundNoticeSeen,
    PaymentStatus? paymentStatus,
    DateTime? tourDate,
    int? seatsHeld,
    String? seatOptionId,
    String? guestDisplayName,
    String? guestBirthDate,
    String? guestContact,
    DateTime? partnerAckedAt,
    bool clearPartnerAckedAt = false,
    DateTime? cancelledAt,
    bool clearCancelledAt = false,
  }) {
    return TourBooking(
      id: id,
      uid: uid,
      shopId: shopId,
      shopName: shopName,
      productName: productName,
      productId: productId,
      optionId: optionId,
      optionName: optionName,
      listingKind: listingKind,
      fromFlag: fromFlag,
      price: price,
      createdAt: createdAt,
      tourDate: tourDate ?? this.tourDate,
      reviewed: reviewed ?? this.reviewed,
      status: status ?? this.status,
      refundPercent: refundPercent ?? this.refundPercent,
      refundAmount: refundAmount ?? this.refundAmount,
      refundNoticeSeen: refundNoticeSeen ?? this.refundNoticeSeen,
      commissionRate: commissionRate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      partySize: partySize,
      divers: divers,
      nondivers: nondivers,
      children: children,
      infants: infants,
      quoteLines: quoteLines,
      seatsHeld: seatsHeld ?? this.seatsHeld,
      seatOptionId: seatOptionId ?? this.seatOptionId,
      guestDisplayName: guestDisplayName ?? this.guestDisplayName,
      guestBirthDate: guestBirthDate ?? this.guestBirthDate,
      guestContact: guestContact ?? this.guestContact,
      partnerAckedAt: clearPartnerAckedAt
          ? null
          : (partnerAckedAt ?? this.partnerAckedAt),
      cancelledAt: clearCancelledAt ? null : (cancelledAt ?? this.cancelledAt),
    );
  }

  /// Inventory option id used when restoring seats.
  String get seatsOptionKey =>
      seatOptionId.isNotEmpty ? seatOptionId : optionId;
}

/// Real profile/login display name for partner vouchers.
///
/// Returns empty when unset. Never invents a name from [email] local-part.
String resolveGuestDisplayName({
  String? authDisplayName,
  String? profileDisplayName,
  String? email,
}) {
  final emailLocal = () {
    final mail = (email ?? '').trim();
    if (!mail.contains('@')) {
      return '';
    }
    return mail.split('@').first.trim();
  }();

  bool usable(String raw) {
    final name = raw.trim();
    if (name.isEmpty) {
      return false;
    }
    // App unbound placeholder — not a real profile name.
    if (name == '다이버') {
      return false;
    }
    if (emailLocal.isNotEmpty && name == emailLocal) {
      return false;
    }
    return true;
  }

  final profile = (profileDisplayName ?? '').trim();
  if (usable(profile)) {
    return profile;
  }
  final auth = (authDisplayName ?? '').trim();
  if (usable(auth)) {
    return auth;
  }
  return '';
}

/// Guest lifecycle for a tour booking.
///
/// Defaults stay [requested]/[PaymentStatus.unpaid]. Paid checkout writes
/// [confirmed] + captured; legacy unpaid rows still move via shop confirm.
enum BookingStatus {
  requested,
  confirmed,
  cancelled,
  weatherCancelled;

  static BookingStatus parse(dynamic value) {
    switch (value) {
      case 'requested':
        return BookingStatus.requested;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'weather_cancelled':
        return BookingStatus.weatherCancelled;
      case 'confirmed':
        return BookingStatus.confirmed;
      default:
        // Legacy docs without status were treated as already confirmed.
        return BookingStatus.confirmed;
    }
  }

  String get firestoreValue {
    switch (this) {
      case BookingStatus.requested:
        return 'requested';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.weatherCancelled:
        return 'weather_cancelled';
      case BookingStatus.confirmed:
        return 'confirmed';
    }
  }
}

enum PaymentStatus {
  unpaid,
  captured,
  refunded;

  static PaymentStatus parse(dynamic value) {
    switch (value) {
      case 'unpaid':
      case 'pending':
        return PaymentStatus.unpaid;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'captured':
        return PaymentStatus.captured;
      default:
        // Legacy bookings without the field were already paid.
        return PaymentStatus.captured;
    }
  }

  String get firestoreValue {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'unpaid';
      case PaymentStatus.captured:
        return 'captured';
      case PaymentStatus.refunded:
        return 'refunded';
    }
  }
}
