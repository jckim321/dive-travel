import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Pick a product (base or with individual SKUs) then open leftover seats.
class SameBoatSeatsHubScreen extends StatelessWidget {
  const SameBoatSeatsHubScreen({
    super.key,
    this.shopId,
    this.creatorUid,
    this.adminBypassApproval = false,
  });

  final String? shopId;
  final String? creatorUid;
  final bool adminBypassApproval;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sameBoatSeatsTitle)),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final products = [
            for (final product in store.allShopProducts)
              if ((shopId == null || product.shopId == shopId) &&
                  (creatorUid == null ||
                      product.submittedByUid == creatorUid) &&
                  product.isListedPublicly)
                product,
          ];
          if (products.isEmpty) {
            return Center(child: Text(l10n.sameBoatSeatsNoProducts));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final product = products[index];
              final statusLabel = switch (product.sameBoatStatus) {
                SameBoatStatus.pending => l10n.adminSameBoatPendingBadge,
                SameBoatStatus.approved => l10n.adminSameBoatLiveBadge,
                SameBoatStatus.rejected => l10n.adminSameBoatRejectedBadge,
                SameBoatStatus.closed => l10n.adminSameBoatClosedBadge,
              };
              return Card(
                child: ListTile(
                  key: Key('same-boat-hub-${product.id}'),
                  title: Text(product.name),
                  subtitle: Text(statusLabel),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SameBoatSeatsScreen(
                          product: product,
                          adminBypassApproval: adminBypassApproval,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
