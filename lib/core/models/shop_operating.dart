/// Partner resort operating state. A missing or unknown value stays active
/// so shops saved before this field keep their current public listings.
enum ShopOperatingStatus {
  active,
  paused,
  contractEnded,
  closed;

  /// Home, trips, same-boat, new bookings, and new flags.
  bool get acceptsCustomers => this == active;

  static ShopOperatingStatus parse(Object? raw) {
    switch (raw) {
      case 'paused':
        return ShopOperatingStatus.paused;
      case 'contract_ended':
        return ShopOperatingStatus.contractEnded;
      case 'closed':
        return ShopOperatingStatus.closed;
      default:
        return ShopOperatingStatus.active;
    }
  }

  String get firestoreValue => switch (this) {
        ShopOperatingStatus.active => 'active',
        ShopOperatingStatus.paused => 'paused',
        ShopOperatingStatus.contractEnded => 'contract_ended',
        ShopOperatingStatus.closed => 'closed',
      };
}

/// Shop document field. Absent means [ShopOperatingStatus.active].
bool shopAcceptsNewBusiness(Map<String, dynamic>? data) {
  return ShopOperatingStatus.parse(data?['operating_status']).acceptsCustomers;
}

/// Reason memo stored on the shop and copied onto a status event.
String clampOperatingNote(String note) {
  final trimmed = note.trim();
  if (trimmed.length <= 500) {
    return trimmed;
  }
  return trimmed.substring(0, 500);
}

/// Written as `from_owner_id` when a shop has no previous owner.
/// Rules require that field to be 1–80 characters, so the first link
/// cannot store an empty id.
const String operatingOwnerNoneId = '(없음)';

/// Login id shown in an owner event. Falls back to the email local-part, then uid.
/// Rules require 1–80 characters.
String operatingOwnerHandle({
  required String uid,
  String loginId = '',
  String email = '',
}) {
  var value = loginId.trim();
  if (value.isEmpty) {
    final mail = email.trim();
    final at = mail.indexOf('@');
    value = (at <= 0 ? mail : mail.substring(0, at)).trim();
  }
  if (value.isEmpty) {
    value = uid.trim();
  }
  if (value.length > 80) {
    value = value.substring(0, 80);
  }
  if (value.isEmpty) {
    throw StateError('OWNER_ID_EMPTY');
  }
  return value;
}

/// Shop names copied onto an owner event are limited to 120 characters.
String clampOperatingShopName(String name) {
  final trimmed = name.trim();
  if (trimmed.length <= 120) {
    return trimmed;
  }
  return trimmed.substring(0, 120);
}

/// Result of moving `owned_shop_id` from one member to another.
class ShopOwnerTransfer {
  const ShopOwnerTransfer({
    required this.fromUid,
    required this.toUid,
    required this.fromOwnerId,
    required this.toOwnerId,
    this.fromName = '',
    this.toName = '',
    this.appliedName = '',
  });

  final String fromUid;
  final String toUid;
  final String fromOwnerId;
  final String toOwnerId;
  final String fromName;
  final String toName;

  /// Full shop name written on the shop document. Empty when the name stays.
  final String appliedName;

  bool get renamed => appliedName.isNotEmpty;
}

/// Event `by_name` must be 1–80 characters.
String clampOperatingByName(String name, String uid) {
  var value = name.trim();
  if (value.isEmpty) {
    value = uid.trim();
  }
  if (value.isEmpty) {
    value = 'admin';
  }
  if (value.length > 80) {
    return value.substring(0, 80);
  }
  return value;
}

/// One row in `shops/{shopId}/operating_events`.
class ShopOperatingEvent {
  const ShopOperatingEvent({
    required this.id,
    required this.at,
    required this.byUid,
    required this.byName,
    required this.kind,
    this.fromStatus,
    this.toStatus,
    this.note = '',
    this.fromOwnerId = '',
    this.toOwnerId = '',
    this.fromName = '',
    this.toName = '',
  });

  final String id;
  final DateTime at;
  final String byUid;
  final String byName;

  /// `status` or `owner`.
  final String kind;
  final ShopOperatingStatus? fromStatus;
  final ShopOperatingStatus? toStatus;
  final String note;
  final String fromOwnerId;
  final String toOwnerId;
  final String fromName;
  final String toName;

  factory ShopOperatingEvent.fromMap(
    String id,
    Map<String, dynamic> data, {
    required DateTime at,
  }) {
    ShopOperatingStatus? statusOf(Object? raw) {
      if (raw is! String || raw.isEmpty) {
        return null;
      }
      return ShopOperatingStatus.parse(raw);
    }

    return ShopOperatingEvent(
      id: id,
      at: at.toUtc(),
      byUid: (data['by_uid'] as String?)?.trim() ?? '',
      byName: (data['by_name'] as String?)?.trim() ?? '',
      kind: (data['kind'] as String?)?.trim() ?? '',
      fromStatus: statusOf(data['from_status']),
      toStatus: statusOf(data['to_status']),
      note: (data['note'] as String?) ?? '',
      fromOwnerId: (data['from_owner_id'] as String?)?.trim() ?? '',
      toOwnerId: (data['to_owner_id'] as String?)?.trim() ?? '',
      fromName: (data['from_name'] as String?)?.trim() ?? '',
      toName: (data['to_name'] as String?)?.trim() ?? '',
    );
  }
}
