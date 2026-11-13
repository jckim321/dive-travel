import 'package:dive_travel_app/core/data/refund_policy.dart';
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
    this.singleRooms = 0,
    this.quoteLines = const [],
    this.partyLines = const [],
    this.seatsHeld = 0,
    this.seatOptionId = '',
    this.guestDisplayName = '',
    this.guestBirthDate = '',
    this.guestContact = '',
    this.publicCode = '',
    this.partnerAckedAt,
    this.cancelledAt,
    this.arrivalFlight = '',
    this.arrivalAt,
    this.returnFlight = '',
    this.returnAt,
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

  /// Single-occupancy rooms chosen at checkout. Missing docs read as 0.
  final int singleRooms;
  final List<BookingLine> quoteLines;
  final List<BookingPartyLine> partyLines;
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

  /// Spoken booking number (`DT-MMDD-XXXX`). Empty on rows saved before this field.
  final String publicCode;

  /// Partner 「확인했어요」 read receipt (shop booking doc only).
  final DateTime? partnerAckedAt;

  /// When the shop copy was cancelled or weather-cancelled.
  /// Read from the existing `cancelled_at` field. Overview uses this only.
  final DateTime? cancelledAt;

  /// Guest-told inbound flight number. Empty on older bookings.
  final String arrivalFlight;

  /// Arrival clock on the departure day. Null when the guest has not set one.
  final DateTime? arrivalAt;

  /// Guest-told return flight number. Empty on older bookings.
  final String returnFlight;

  /// Return-flight departure. Null when the guest has not set one.
  final DateTime? returnAt;

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
    String? arrivalFlight,
    DateTime? arrivalAt,
    bool clearArrivalAt = false,
    String? returnFlight,
    DateTime? returnAt,
    bool clearReturnAt = false,
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
      singleRooms: singleRooms,
      quoteLines: quoteLines,
      partyLines: partyLines,
      seatsHeld: seatsHeld ?? this.seatsHeld,
      seatOptionId: seatOptionId ?? this.seatOptionId,
      guestDisplayName: guestDisplayName ?? this.guestDisplayName,
      guestBirthDate: guestBirthDate ?? this.guestBirthDate,
      guestContact: guestContact ?? this.guestContact,
      publicCode: publicCode,
      partnerAckedAt: clearPartnerAckedAt
          ? null
          : (partnerAckedAt ?? this.partnerAckedAt),
      cancelledAt: clearCancelledAt ? null : (cancelledAt ?? this.cancelledAt),
      arrivalFlight: arrivalFlight ?? this.arrivalFlight,
      arrivalAt: clearArrivalAt ? null : (arrivalAt ?? this.arrivalAt),
      returnFlight: returnFlight ?? this.returnFlight,
      returnAt: clearReturnAt ? null : (returnAt ?? this.returnAt),
    );
  }

  factory TourBooking.fromMap(String id, Map<String, dynamic> data) {
    return TourBooking(
      id: id,
      uid: data['uid'] as String? ?? '',
      shopId: data['shop_id'] as String? ?? '',
      shopName: data['shop_name'] as String? ?? '',
      productName: data['product_name'] as String? ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      createdAt: _bookingDate(data['created_at']),
      tourDate: data['tour_date'] == null ? null : _bookingDate(data['tour_date']),
      reviewed: data['reviewed'] == true,
      status: BookingStatus.parse(data['status']),
      refundPercent: (data['refund_percent'] as num?)?.toInt() ?? 0,
      refundAmount: (data['refund_amount'] as num?)?.toInt() ?? 0,
      refundNoticeSeen: data['refund_notice_seen'] == true,
      commissionRate:
          (data['commission_rate'] as num?)?.toDouble() ??
          RefundPolicy.defaultCommissionRate,
      paymentStatus: PaymentStatus.parse(data['payment_status']),
      productId: data['product_id'] as String? ?? '',
      optionId: data['option_id'] as String? ?? '',
      optionName: data['option_name'] as String? ?? '',
      listingKind: data.containsKey('listing_kind')
          ? ProductListingKind.parse(data['listing_kind'])
          : ProductListingKind.exploreOnly,
      fromFlag: data['from_flag'] == true,
      partySize: (data['party_size'] as num?)?.toInt() ?? 0,
      divers: (data['divers'] as num?)?.toInt() ?? 0,
      nondivers: (data['nondivers'] as num?)?.toInt() ?? 0,
      children: (data['children'] as num?)?.toInt() ?? 0,
      infants: (data['infants'] as num?)?.toInt() ?? 0,
      singleRooms: (data['single_rooms'] as num?)?.toInt() ?? 0,
      quoteLines: BookingLine.listFrom(data['quote_lines']),
      partyLines: BookingPartyLine.listFrom(data['party_lines']),
      seatsHeld: (data['seats_held'] as num?)?.toInt() ?? 0,
      seatOptionId: data['seat_option_id'] as String? ?? '',
      guestDisplayName: data['guest_display_name'] as String? ?? '',
      guestBirthDate: data['guest_birth_date'] as String? ?? '',
      guestContact: data['guest_contact'] as String? ?? '',
      publicCode: data['public_code'] as String? ?? '',
      partnerAckedAt: data['partner_acked_at'] == null
          ? null
          : _bookingDate(data['partner_acked_at']),
      cancelledAt: data['cancelled_at'] == null
          ? null
          : _bookingDate(data['cancelled_at']),
      arrivalFlight: (data['arrival_flight'] as String? ?? '').trim(),
      arrivalAt: _optionalBookingDate(data['arrival_at']),
      returnFlight: (data['return_flight'] as String? ?? '').trim(),
      returnAt: _optionalBookingDate(data['return_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'shop_id': shopId,
      'shop_name': shopName,
      'product_name': productName,
      'price': price,
      'reviewed': reviewed,
      'status': status.firestoreValue,
      'refund_percent': refundPercent,
      'refund_amount': refundAmount,
      'refund_notice_seen': refundNoticeSeen,
      'commission_rate': commissionRate,
      'payment_status': paymentStatus.firestoreValue,
      'product_id': productId,
      'option_id': optionId,
      'option_name': optionName,
      'listing_kind': listingKind.firestoreValue,
      'from_flag': fromFlag,
      'party_size': partySize,
      'divers': divers,
      'nondivers': nondivers,
      'children': children,
      'infants': infants,
      'single_rooms': singleRooms,
      'seats_held': seatsHeld,
      'seat_option_id': seatOptionId,
      'guest_display_name': guestDisplayName,
      'public_code': publicCode,
      'arrival_flight': arrivalFlight,
      'arrival_at': arrivalAt?.toIso8601String() ?? '',
      'return_flight': returnFlight,
      'return_at': returnAt?.toIso8601String() ?? '',
      'tour_date': scheduledFor.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Inventory option id used when restoring seats.
  String get seatsOptionKey =>
      seatOptionId.isNotEmpty ? seatOptionId : optionId;
}

DateTime? _optionalBookingDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String && value.trim().isEmpty) {
    return null;
  }
  return _bookingDate(value);
}

DateTime _bookingDate(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  try {
    final date = (value as dynamic).toDate();
    if (date is DateTime) {
      return date;
    }
  } catch (_) {}
  return DateTime.now();
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
