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
    );
  }
}
