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
