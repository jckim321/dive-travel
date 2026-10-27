import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Hide or reopen leftover seats, and monitor live same-boat inventory.
class AdminSameBoatMonitorScreen extends StatelessWidget {
  const AdminSameBoatMonitorScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final live = [
          for (final product in store.allShopProducts)
            if (_hasLiveSeats(product)) product,
        ]..sort(_byDeparture);
        final concealed = [
          for (final product in store.allShopProducts)
            if (_hasConcealedSeats(product)) product,
        ]..sort(_byDeparture);

        final body = ListView(
          key: const Key('admin-same-boat-monitor'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const _SeatLifeSweepOnce(),
            Text(
              l10n.adminSameBoatLiveTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (live.isEmpty)
              Card(
                color: embedded ? AdminConsoleTheme.surfaceHigh : null,
                child: ListTile(
                  title: Text(
                    l10n.adminSameBoatEmpty,
                    style: TextStyle(
                      color: embedded ? AdminConsoleTheme.muted : null,
                    ),
                  ),
                ),
              )
            else
              for (final product in live) ...[
                _SameBoatTile(
                  product: product,
                  embedded: embedded,
                  reopen: false,
                ),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 20),
            Text(
              l10n.adminSameBoatHiddenTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (concealed.isEmpty)
              Card(
                color: embedded ? AdminConsoleTheme.surfaceHigh : null,
                child: ListTile(
                  title: Text(
                    l10n.adminSameBoatHiddenEmpty,
                    style: TextStyle(
                      color: embedded ? AdminConsoleTheme.muted : null,
                    ),
                  ),
                ),
              )
            else
              for (final product in concealed) ...[
                _SameBoatTile(
                  product: product,
                  embedded: embedded,
                  reopen: true,
                ),
                const SizedBox(height: 8),
              ],
          ],
        );

        return adminScreenShell(
          embedded: embedded,
          title: l10n.adminSameBoatTitle,
          body: body,
        );
      },
    );
  }
}

class _SeatLifeSweepOnce extends StatefulWidget {
  const _SeatLifeSweepOnce();

  @override
  State<_SeatLifeSweepOnce> createState() => _SeatLifeSweepOnceState();
}

class _SeatLifeSweepOnceState extends State<_SeatLifeSweepOnce> {
  var _done = false;
  var _listening = false;
  var _scheduled = false;
  DiverStore? _store;

  @override
  void dispose() {
    _store?.removeListener(_whenReady);
    super.dispose();
  }

  void _whenReady() {
    if (!mounted || _done) {
      return;
    }
    final store = DiverStoreScope.of(context);
    _store = store;
    if (!store.stats.isAdmin) {
      _done = true;
      return;
    }
    if (!store.shopStatsLoaded) {
      if (!_listening) {
        _listening = true;
        store.addListener(_whenReady);
      }
      return;
    }
    _done = true;
    if (_listening) {
      store.removeListener(_whenReady);
      _listening = false;
    }
    unawaited(store.sweepSeatLives());
  }

  @override
  Widget build(BuildContext context) {
    if (!_done && !_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _whenReady());
    }
    return const SizedBox.shrink();
  }
}

int _byDeparture(ShopProduct a, ShopProduct b) {
  final aStart = a.departureStart ?? DateTime(9999);
  final bStart = b.departureStart ?? DateTime(9999);
  return aStart.compareTo(bStart);
}

bool _hasLiveSeats(ShopProduct product) {
  if (product.listsOnSameBoat) {
    return true;
  }
  for (final option in product.options) {
    if (option.listsOnSameBoat) {
      return true;
    }
  }
  return false;
}

/// Calendar days from [openedAt] through [today]. Null when the time was never stored.
int? sameBoatZeroBookingOpenDays(DateTime? openedAt, DateTime today) {
  if (openedAt == null) {
    return null;
  }
  final start = DateTime(openedAt.year, openedAt.month, openedAt.day);
  final day = DateTime(today.year, today.month, today.day);
  final days = day.difference(start).inDays;
  return days < 0 ? 0 : days;
}

/// Hidden or rejected, and nothing still on the live board.
bool _hasConcealedSeats(ShopProduct product) {
  if (_hasLiveSeats(product)) {
    return false;
  }
  if (product.sameBoatStatus.isPartnerLocked) {
    return true;
  }
  for (final option in product.options) {
    if (option.sameBoatStatus.isPartnerLocked) {
      return true;
    }
  }
  return false;
}

class _SameBoatTile extends StatelessWidget {
  const _SameBoatTile({
    required this.product,
    required this.embedded,
    required this.reopen,
  });

  final ShopProduct product;
  final bool embedded;
  final bool reopen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shopName =
        DiveShopCatalog.byId(product.shopId)?.name ?? product.shopId;
    final remaining = product.remainingSeats;
    final flagged = product.flaggedSeats;
    final departure = product.departureStart;
    final deadline = product.flagClosesAt;
    final dayFmt = DateFormat('yyyy.MM.dd');

    final store = DiverStoreScope.of(context);
    final muted = embedded ? AdminConsoleTheme.muted : null;
    return Card(
      color: embedded ? AdminConsoleTheme.surfaceHigh : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TravelProductRegistrationScreen(
                      lockedShopId: product.shopId,
                      existing: product,
                      startEditing: true,
                    ),
                  ),
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.directions_boat_outlined,
                    color: embedded ? AdminConsoleTheme.aqua : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            color: embedded ? Colors.white : null,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            shopName,
                            l10n.adminSameBoatRemaining(remaining),
                            l10n.adminSameBoatFlagged(flagged),
                            if (departure != null) dayFmt.format(departure),
                            if (deadline != null)
                              '${l10n.workbenchFlagDeadline} ${dayFmt.format(deadline)}',
                          ].join(' · '),
                          style: TextStyle(fontSize: 12, color: muted),
                        ),
                        if (!reopen && product.bookedSeats == 0) ...[
                          const SizedBox(height: 6),
                          _ZeroBookingBadge(product: product),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SameBoatSeatsScreen(
                            product: product,
                            adminBypassApproval: true,
                          ),
                        ),
                      );
                    },
                  ),
                  TextButton(
                    key: Key(
                      reopen
                          ? 'admin-same-boat-reopen-${product.id}'
                          : 'admin-same-boat-hide-${product.id}',
                    ),
                    onPressed: () async {
                      await store.setSameBoatStatus(
                        shopId: product.shopId,
                        productId: product.id,
                        status: reopen
                            ? SameBoatStatus.approved
                            : SameBoatStatus.hidden,
                      );
                    },
                    child: Text(
                      reopen
                          ? l10n.adminSameBoatReopen
                          : l10n.adminSameBoatHide,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZeroBookingBadge extends StatelessWidget {
  const _ZeroBookingBadge({required this.product});

  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final days = sameBoatZeroBookingOpenDays(
      product.sameBoatOpenedAt,
      DateTime.now(),
    );
    final label = days == null
        ? l10n.adminSameBoatZeroBookings
        : l10n.adminSameBoatZeroBookingsForDays(days);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: Key('admin-same-boat-zero-badge-${product.id}'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFB45309).withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFFB45309),
          ),
        ),
      ),
    );
  }
}
