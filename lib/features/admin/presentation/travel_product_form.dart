import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/ops_product_workbench.dart';

/// Shared entry for admin, partner, and diver-creator product registration.
///
/// All modes use the same [OpsProductWorkbench] form.
class TravelProductRegistrationScreen extends StatelessWidget {
  const TravelProductRegistrationScreen({
    super.key,
    this.lockedShopId,
    this.partnerMode = false,
    this.creatorMode = false,
    this.existing,
    this.startEditing = false,
  });

  final String? lockedShopId;
  final bool partnerMode;

  /// Diver "craft a trip" from My — always submits as pending / diverPlanned.
  final bool creatorMode;
  final ShopProduct? existing;

  /// When true (and [existing] is set), open the form in edit mode.
  /// Admin approval review keeps the default view mode (`false`).
  final bool startEditing;

  /// Legacy id kept for callers that still reference "not in catalog" shops.
  static const notInListShopId = '__not_in_list__';

  @override
  Widget build(BuildContext context) {
    return OpsProductWorkbench(
      lockedShopId: lockedShopId,
      partnerMode: partnerMode,
      creatorMode: creatorMode,
      existing: existing,
      startEditing: startEditing,
    );
  }
}
