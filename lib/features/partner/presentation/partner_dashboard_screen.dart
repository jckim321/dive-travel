import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_products_screen.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class PartnerDashboardScreen extends StatelessWidget {
  const PartnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final shopId =
        store.stats.ownedShopId ?? AppConstants.defaultPartnerShopId;
    final shop = DiveShopCatalog.byId(shopId);
    final live = store.liveStatsFor(shopId);
    final theme = Theme.of(context);
    final money = NumberFormat('#,###', 'en_US');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.partnerTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(l10n.partnerSubtitle, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 8),
          Chip(
            avatar: const Icon(Icons.storefront, size: 18),
            label: Text(live?.name ?? shop?.name ?? shopId),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.edit_note),
              title: Text(l10n.partnerShopEdit),
              subtitle: Text(l10n.partnerShopEditHint),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ResortDeskScreen(shopId: shopId),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              key: const Key('partner-product-form'),
              leading: const Icon(Icons.add_box_outlined),
              title: Text(l10n.partnerProductForm),
              subtitle: Text(l10n.partnerProductPendingHint),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AdminProductsScreen(partnerMode: true),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.partnerSettlementTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            l10n.partnerCommissionRange,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _MoneyRow(
                    label: l10n.partnerGross,
                    value: l10n.explorePriceWon(money.format(store.partnerGrossThisMonth)),
                  ),
                  _MoneyRow(
                    label: l10n.partnerFee,
                    value: l10n.explorePriceWon(
                      money.format(store.partnerCommissionThisMonth),
                    ),
                  ),
                  const Divider(),
                  _MoneyRow(
                    label: l10n.partnerNet,
                    value: l10n.explorePriceWon(money.format(store.partnerNetThisMonth)),
                    emphasize: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.partnerBookingsTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (store.shopBookings.isEmpty)
            Card(child: ListTile(title: Text(l10n.partnerNoBookings)))
          else
            for (final booking in store.shopBookings) ...[
              Card(
                child: ListTile(
                  title: Text(booking.productName),
                  subtitle: Text(
                    '${booking.shopName} · ${DateFormat('yyyy.MM.dd').format(booking.scheduledFor)}\n'
                    '${_statusLabel(l10n, booking)} · ${l10n.explorePriceWon(money.format(booking.price))}',
                  ),
                  isThreeLine: true,
                  trailing: booking.isActive
                      ? TextButton(
                          onPressed: () => store.cancelBookingsForWeather(
                            shopId: shopId,
                            tourDate: booking.scheduledFor,
                          ),
                          child: Text(l10n.weatherCancel),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, TourBooking booking) {
    switch (booking.status) {
      case BookingStatus.cancelled:
        return l10n.bookingCancelled;
      case BookingStatus.weatherCancelled:
        return l10n.bookingWeatherCancelled;
      case BookingStatus.confirmed:
        return l10n.bookingConfirmed;
    }
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
