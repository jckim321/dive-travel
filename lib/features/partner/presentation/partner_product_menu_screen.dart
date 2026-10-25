import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_open_seats_picker_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_product_list_logic.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_products_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Partner product hub (시안 19): register / list / open seats.
class PartnerProductMenuScreen extends StatelessWidget {
  const PartnerProductMenuScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return PartnerTheme.wrap(
      Scaffold(
        appBar: embedded
            ? null
            : AppBar(title: Text(l10n.partnerProductMenuTitle)),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: store,
            builder: (context, _) {
              final shopId = store.partnerOwnedShopId;
              final products = store.productsForShop(shopId);
              final counts = partnerProductFilterCounts(products);
              final openSeats = partnerOpenSameBoatSeatTotal(products);

              return ListView(
                key: const Key('partner-product-menu'),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _MenuCard(
                    keyName: 'partner-menu-register',
                    title: l10n.partnerProductMenuRegister,
                    subtitle: counts.drafting > 0
                        ? l10n.partnerProductMenuRegisterDrafting(
                            counts.drafting,
                          )
                        : l10n.partnerProductMenuRegisterSub,
                    icon: Icons.add_box_outlined,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TravelProductRegistrationScreen(
                          lockedShopId: shopId,
                          partnerMode: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MenuCard(
                    keyName: 'partner-menu-list',
                    title: l10n.partnerProductMenuList,
                    subtitle: counts.listed > 0
                        ? l10n.partnerProductMenuListListed(counts.listed)
                        : l10n.partnerProductMenuListSub,
                    icon: Icons.list_alt_outlined,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PartnerProductsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MenuCard(
                    keyName: 'partner-menu-seats',
                    title: l10n.partnerProductMenuSeats,
                    subtitle: openSeats > 0
                        ? l10n.partnerProductMenuSeatsOpen(openSeats)
                        : l10n.partnerProductMenuSeatsSub,
                    icon: Icons.airline_seat_recline_normal_outlined,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            PartnerOpenSeatsPickerScreen(shopId: shopId),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    key: const Key('partner-menu-foc-note'),
                    l10n.partnerProductMenuFocNote,
                    style: const TextStyle(
                      color: PartnerTheme.textDim,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.keyName,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String keyName;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key(keyName),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          child: Row(
            children: [
              Icon(icon, color: PartnerTheme.accent, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: PartnerTheme.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: PartnerTheme.textDim,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: PartnerTheme.textDim),
            ],
          ),
        ),
      ),
    );
  }
}
