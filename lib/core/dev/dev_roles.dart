import 'package:dive_travel_app/core/constants/app_constants.dart';

/// Owner-only test role switcher (visible on Pages release for AppOwner email).
enum DevRoleKind { diver, partner, admin }

abstract final class DevRoles {
  /// Menu / API gate — owner email only (no kDebugMode; works on release web).
  static bool canUse(String? email) => AppOwner.isOwnerEmail(email);
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
