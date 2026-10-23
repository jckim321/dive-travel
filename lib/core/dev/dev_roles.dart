import 'package:dive_travel_app/core/constants/app_constants.dart';

/// Owner-only test role switcher (visible on Pages release for AppOwner email).
enum DevRoleKind { diver, partner, admin }

abstract final class DevRoles {
  /// Flip to `false` before public launch to hide and disable the whole switcher.
  static const bool enabled = true;

  /// Menu / API gate — owner email only when [enabled].
  static bool canUse(String? email) =>
      enabled && AppOwner.isOwnerEmail(email);
}

/// Session overlay so UI can look like diver/partner without clearing Firestore
/// `is_admin` (rules would block self-re-promotion).
class DevRoleOverlay {
  const DevRoleOverlay({required this.kind, this.ownedShopId});

  final DevRoleKind kind;
  final String? ownedShopId;

  bool get effectiveIsAdmin => kind == DevRoleKind.admin;

  bool get effectiveIsBusiness => kind == DevRoleKind.partner;

  String? get effectiveOwnedShopId =>
      kind == DevRoleKind.partner ? ownedShopId : null;
}
