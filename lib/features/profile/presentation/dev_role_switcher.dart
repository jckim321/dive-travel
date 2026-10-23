import 'package:flutter/material.dart';

import 'package:dive_travel_app/features/profile/presentation/owner_dev_role_quick_bar.dart';

/// Thin wrapper kept for older imports; use [OwnerDevRoleQuickBar].
class DevRoleSwitcher extends StatelessWidget {
  const DevRoleSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return const OwnerDevRoleQuickBar();
  }
}
