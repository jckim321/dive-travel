import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_products_screen.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_documents_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_loi_form_screen.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_hub_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

List<Widget> _partnerSameBoatRequestTiles({
  required BuildContext context,
  required AppLocalizations l10n,
  required List<ShopProduct> products,
}) {
  if (products.isEmpty) {
    return [
      Card(
        key: const Key('partner-same-boat-requests-empty'),
        child: ListTile(
          title: Text(l10n.partnerSameBoatRequestsEmpty),
        ),
      ),
    ];
  }
  return [
    for (final product in products)
      Card(
        key: Key('partner-same-boat-request-${product.id}'),
        child: ListTile(
          title: Text(product.name),
          subtitle: Text(_partnerSameBoatRequestStatus(l10n, product)),
        ),
      ),
  ];
}

String _partnerSameBoatRequestStatus(
  AppLocalizations l10n,
  ShopProduct product,
) {
  if (product.hasPendingSameBoat) {
    return l10n.adminSameBoatPendingBadge;
  }
  if (product.hasLiveSameBoatOffer) {
    return l10n.adminSameBoatLiveBadge;
  }
  if (product.hasRejectedSameBoat) {
    return l10n.adminSameBoatRejectedBadge;
  }
  return l10n.adminSameBoatClosedBadge;
}

class PartnerDashboardScreen extends StatelessWidget {
  const PartnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.partnerTitle)),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final shopId = store.partnerOwnedShopId;
          final shop = DiveShopCatalog.byId(shopId);
          final live = store.liveStatsFor(shopId);
          final theme = Theme.of(context);
          final money = NumberFormat('#,###', 'en_US');

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(l10n.partnerSubtitle, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              Chip(
                avatar: const Icon(Icons.storefront, size: 18),
                label: Text(live?.name ?? shop?.name ?? shopId),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.partnerSectionShopProducts,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
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
                      builder: (_) =>
                          const AdminProductsScreen(partnerMode: true),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.partnerSectionSameBoat,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  key: const Key('partner-same-boat-seats'),
                  leading: const Icon(Icons.directions_boat_outlined),
                  title: Text(l10n.sameBoatApplyTitle),
                  subtitle: Text(l10n.partnerSameBoatApplyHint),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SameBoatSeatsHubScreen(shopId: shopId),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.partnerSameBoatRequestsTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ..._partnerSameBoatRequestTiles(
                context: context,
                l10n: l10n,
                products: [
                  for (final product in store.allShopProducts)
                    if (product.shopId == shopId &&
                        (product.hasPendingSameBoat ||
                            product.hasLiveSameBoatOffer ||
                            product.hasRejectedSameBoat))
                      product,
                ],
              ),
              const SizedBox(height: 24),
              Text(
                l10n.partnerDocsSection,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  key: const Key('partner-documents'),
                  leading: const Icon(Icons.description_outlined),
                  title: Text(l10n.partnerDocsTitle),
                  subtitle: Text(l10n.partnerDocsHint),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PartnerDocumentsScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  key: const Key('partner-loi-form'),
                  leading: const Icon(Icons.draw_outlined),
                  title: Text(l10n.partnerLoiOpenForm),
                  subtitle: Text(l10n.partnerLoiOpenFormHint),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PartnerLoiFormScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.partnerSectionOps,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.partnerSettlementTitle,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
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
                        value: l10n.explorePriceWon(
                          money.format(store.partnerGrossThisMonth),
                        ),
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
                        value: l10n.explorePriceWon(
                          money.format(store.partnerNetThisMonth),
                        ),
                        emphasize: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.partnerBookingsTitle,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (store.shopBookings.isEmpty)
                Card(child: ListTile(title: Text(l10n.partnerNoBookings)))
              else
                for (final booking in store.shopBookings) ...[
                  _PartnerBookingCard(
                    booking: booking,
                    shopId: shopId,
                    money: money,
                  ),
                  const SizedBox(height: 8),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _PartnerBookingCard extends StatelessWidget {
  const _PartnerBookingCard({
    required this.booking,
    required this.shopId,
    required this.money,
  });

  final TourBooking booking;
  final String shopId;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.displayTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('yyyy.MM.dd').format(booking.scheduledFor)}\n'
              '${_partyLabel(l10n, booking)}'
              '${_statusLabel(l10n, booking)} · '
              '${l10n.explorePriceWon(money.format(booking.price))}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (booking.isActive) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (booking.awaitsShopConfirm)
                    FilledButton(
                      key: Key('partner-confirm-${booking.id}'),
                      onPressed: () async {
                        final ok = await store.confirmShopBooking(
                          shopId: shopId,
                          bookingId: booking.id,
                        );
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? l10n.bookingConfirmDone
                                  : l10n.bookingConfirmFailed,
                            ),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.navy,
                      ),
                      child: Text(l10n.bookingConfirmAndCapture),
                    ),
                  TextButton(
                    onPressed: () => store.cancelBookingsForWeather(
                      shopId: shopId,
                      tourDate: booking.scheduledFor,
                    ),
                    child: Text(l10n.weatherCancel),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _partyLabel(AppLocalizations l10n, TourBooking booking) {
    if (booking.hasPartyDetail) {
      return '${l10n.bookingPartySummary(
        booking.divers,
        booking.nondivers,
        booking.children,
        booking.infants,
      )}\n';
    }
    if (booking.partySize > 0) {
      return '${l10n.checkoutGuests} ${booking.partySize}\n';
    }
    return '';
  }

  String _statusLabel(AppLocalizations l10n, TourBooking booking) {
    final bookingLabel = switch (booking.status) {
      BookingStatus.requested => l10n.bookingRequested,
      BookingStatus.cancelled => l10n.bookingCancelled,
      BookingStatus.weatherCancelled => l10n.bookingWeatherCancelled,
      BookingStatus.confirmed => l10n.bookingConfirmed,
    };
    final paymentLabel = switch (booking.paymentStatus) {
      PaymentStatus.unpaid => l10n.bookingPaymentUnpaid,
      PaymentStatus.captured => l10n.bookingPaymentCaptured,
      PaymentStatus.refunded => l10n.bookingPaymentRefunded,
    };
    return '$bookingLabel · $paymentLabel';
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
