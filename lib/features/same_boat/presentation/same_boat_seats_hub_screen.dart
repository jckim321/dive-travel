import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_products_screen.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

enum SameBoatHubStatusFilter { all, closed, pending, live, rejected }

enum SameBoatHubSourceFilter { all, partner, diy, special }

/// Filters public products for the leftover-seat apply hub.
List<ShopProduct> filterSameBoatHubProducts({
  required Iterable<ShopProduct> products,
  String? shopId,
  String? creatorUid,
  SameBoatHubStatusFilter status = SameBoatHubStatusFilter.all,
  SameBoatHubSourceFilter source = SameBoatHubSourceFilter.all,
  String query = '',
}) {
  final q = query.trim().toLowerCase();
  return [
    for (final product in products)
      if ((shopId == null || product.shopId == shopId) &&
          (creatorUid == null || product.submittedByUid == creatorUid) &&
          product.isListedPublicly &&
          _matchesStatus(product, status) &&
          _matchesSource(product, source) &&
          (q.isEmpty || product.name.toLowerCase().contains(q)))
        product,
  ];
}

bool _matchesStatus(ShopProduct product, SameBoatHubStatusFilter filter) {
  return switch (filter) {
    SameBoatHubStatusFilter.all => true,
    SameBoatHubStatusFilter.closed =>
      product.sameBoatStatus == SameBoatStatus.closed &&
          !product.hasPendingSameBoat &&
          !product.listsOnSameBoat,
    SameBoatHubStatusFilter.pending => product.hasPendingSameBoat,
    SameBoatHubStatusFilter.live => product.listsOnSameBoat,
    SameBoatHubStatusFilter.rejected =>
      product.sameBoatStatus == SameBoatStatus.rejected,
  };
}

bool _matchesSource(ShopProduct product, SameBoatHubSourceFilter filter) {
  final source = classifyAdminProductSource(product);
  return switch (filter) {
    SameBoatHubSourceFilter.all => true,
    SameBoatHubSourceFilter.partner => source == AdminProductSource.partner,
    SameBoatHubSourceFilter.diy => source == AdminProductSource.diverDiy,
    SameBoatHubSourceFilter.special =>
      source == AdminProductSource.curatedSpecial,
  };
}

/// Pick a product then open leftover seats (partner / admin apply hub).
class SameBoatSeatsHubScreen extends StatefulWidget {
  const SameBoatSeatsHubScreen({
    super.key,
    this.shopId,
    this.creatorUid,
    this.adminBypassApproval = false,
    this.embedded = false,
    this.showSourceFilter = false,
  });

  final String? shopId;
  final String? creatorUid;
  final bool adminBypassApproval;
  final bool embedded;

  /// Admin hub shows partner / DIY / curated source chips.
  final bool showSourceFilter;

  @override
  State<SameBoatSeatsHubScreen> createState() => _SameBoatSeatsHubScreenState();
}

class _SameBoatSeatsHubScreenState extends State<SameBoatSeatsHubScreen> {
  SameBoatHubStatusFilter _status = SameBoatHubStatusFilter.all;
  SameBoatHubSourceFilter _source = SameBoatHubSourceFilter.all;
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final dayFmt = DateFormat('yyyy.MM.dd');

    final body = ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final products = filterSameBoatHubProducts(
          products: store.allShopProducts,
          shopId: widget.shopId,
          creatorUid: widget.creatorUid,
          status: _status,
          source: widget.showSourceFilter
              ? _source
              : SameBoatHubSourceFilter.all,
          query: _query.text,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                l10n.sameBoatSeatsHubHint,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                key: const Key('same-boat-hub-search'),
                controller: _query,
                decoration: InputDecoration(
                  hintText: l10n.sameBoatHubSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  for (final entry in <(SameBoatHubStatusFilter, String)>[
                    (SameBoatHubStatusFilter.all, l10n.communityFilterAll),
                    (
                      SameBoatHubStatusFilter.closed,
                      l10n.adminSameBoatClosedBadge,
                    ),
                    (
                      SameBoatHubStatusFilter.pending,
                      l10n.adminSameBoatPendingBadge,
                    ),
                    (
                      SameBoatHubStatusFilter.live,
                      l10n.adminSameBoatLiveBadge,
                    ),
                    (
                      SameBoatHubStatusFilter.rejected,
                      l10n.adminSameBoatRejectedBadge,
                    ),
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        key: Key('same-boat-hub-status-${entry.$1.name}'),
                        label: Text(entry.$2),
                        selected: _status == entry.$1,
                        onSelected: (_) => setState(() => _status = entry.$1),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.showSourceFilter) ...[
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    for (final entry in <(SameBoatHubSourceFilter, String)>[
                      (SameBoatHubSourceFilter.all, l10n.adminProductSourceAll),
                      (
                        SameBoatHubSourceFilter.partner,
                        l10n.adminProductSourcePartner,
                      ),
                      (
                        SameBoatHubSourceFilter.diy,
                        l10n.adminProductSourceDiy,
                      ),
                      (
                        SameBoatHubSourceFilter.special,
                        l10n.adminProductSourceSpecial,
                      ),
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          key: Key('same-boat-hub-source-${entry.$1.name}'),
                          label: Text(entry.$2),
                          selected: _source == entry.$1,
                          onSelected: (_) =>
                              setState(() => _source = entry.$1),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: products.isEmpty
                  ? Center(child: Text(l10n.sameBoatSeatsNoProducts))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      itemCount: products.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _HubProductTile(
                          product: product,
                          dayFmt: dayFmt,
                          adminBypass: widget.adminBypassApproval,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );

    if (widget.embedded) {
      return Material(
        key: const Key('same-boat-seats-hub'),
        color: Colors.transparent,
        child: body,
      );
    }

    return Scaffold(
      key: const Key('same-boat-seats-hub'),
      appBar: AppBar(title: Text(l10n.sameBoatApplyTitle)),
      body: body,
    );
  }
}

class _HubProductTile extends StatelessWidget {
  const _HubProductTile({
    required this.product,
    required this.dayFmt,
    required this.adminBypass,
  });

  final ShopProduct product;
  final DateFormat dayFmt;
  final bool adminBypass;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final statusLabel = switch (product.sameBoatStatus) {
      SameBoatStatus.pending => l10n.adminSameBoatPendingBadge,
      SameBoatStatus.approved => l10n.adminSameBoatLiveBadge,
      SameBoatStatus.rejected => l10n.adminSameBoatRejectedBadge,
      SameBoatStatus.closed => l10n.adminSameBoatClosedBadge,
    };
    final bits = <String>[statusLabel];
    if (product.openEmptySeats && product.capacity > 0) {
      final left = product.capacity - product.bookedSeats;
      bits.add(l10n.communitySeatsLeft(left < 0 ? 0 : left));
    }
    if (product.departureStart != null) {
      bits.add(
        '${l10n.workbenchDepartureDate} ${dayFmt.format(product.departureStart!)}',
      );
    }
    if (product.flagClosesAt != null) {
      bits.add(
        '${l10n.workbenchFlagDeadline} ${dayFmt.format(product.flagClosesAt!)}',
      );
    }
    return Card(
      child: ListTile(
        key: Key('same-boat-hub-${product.id}'),
        title: Text(product.name),
        subtitle: Text(bits.join(' · ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SameBoatSeatsScreen(
                product: product,
                adminBypassApproval: adminBypass,
              ),
            ),
          );
        },
      ),
    );
  }
}
