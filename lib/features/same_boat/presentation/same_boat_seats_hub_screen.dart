import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/same_boat_seat_open.dart';
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

/// Partner products waiting for Explore publish (not yet seat-applyable).
List<ShopProduct> filterAwaitingPublishProducts({
  required Iterable<ShopProduct> products,
  required String shopId,
}) {
  return [
    for (final product in products)
      if (product.shopId == shopId &&
          !product.isListedPublicly &&
          (product.publishStatus == ProductPublishStatus.pending ||
              product.publishStatus == ProductPublishStatus.draft ||
              product.publishStatus == ProductPublishStatus.rejected))
        product,
  ];
}

bool _matchesStatus(ShopProduct product, SameBoatHubStatusFilter filter) {
  return switch (filter) {
    SameBoatHubStatusFilter.all => true,
    SameBoatHubStatusFilter.closed =>
      product.sameBoatStatus == SameBoatStatus.closed &&
          !product.hasPendingSameBoat &&
          !product.hasLiveSameBoatOffer,
    SameBoatHubStatusFilter.pending => product.hasPendingSameBoat,
    SameBoatHubStatusFilter.live => product.hasLiveSameBoatOffer,
    SameBoatHubStatusFilter.rejected => product.hasRejectedSameBoat,
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
    this.compactFilters = false,
  });

  final String? shopId;
  final String? creatorUid;
  final bool adminBypassApproval;
  final bool embedded;

  /// Admin hub shows partner / DIY / curated source chips.
  final bool showSourceFilter;

  /// Fewer status chips; source / rejected behind "more".
  final bool compactFilters;

  @override
  State<SameBoatSeatsHubScreen> createState() => _SameBoatSeatsHubScreenState();
}

class _SameBoatSeatsHubScreenState extends State<SameBoatSeatsHubScreen> {
  SameBoatHubStatusFilter _status = SameBoatHubStatusFilter.all;
  SameBoatHubSourceFilter _source = SameBoatHubSourceFilter.all;
  bool _showMoreFilters = false;
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
    final partnerShopId = widget.shopId;

    final body = ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final products = filterSameBoatHubProducts(
          products: store.allShopProducts,
          shopId: widget.shopId,
          creatorUid: widget.creatorUid,
          status: _status,
          source: (widget.showSourceFilter || widget.compactFilters)
              ? _source
              : SameBoatHubSourceFilter.all,
          query: _query.text,
        );
        final awaitingPublish = partnerShopId == null ||
                widget.adminBypassApproval
            ? const <ShopProduct>[]
            : filterAwaitingPublishProducts(
                products: store.productsForShop(partnerShopId),
                shopId: partnerShopId,
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
                      SameBoatHubStatusFilter.pending,
                      l10n.adminSameBoatPendingBadge,
                    ),
                    (
                      SameBoatHubStatusFilter.live,
                      l10n.adminSameBoatLiveBadge,
                    ),
                    (
                      SameBoatHubStatusFilter.closed,
                      l10n.adminSameBoatClosedBadge,
                    ),
                    if (!widget.compactFilters)
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
                  if (widget.compactFilters)
                    TextButton(
                      key: const Key('same-boat-hub-filter-more'),
                      onPressed: () =>
                          setState(() => _showMoreFilters = !_showMoreFilters),
                      child: Text(l10n.adminFilterMore),
                    ),
                ],
              ),
            ),
            if (widget.compactFilters && _showMoreFilters) ...[
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    ChoiceChip(
                      key: const Key('same-boat-hub-status-rejected'),
                      label: Text(l10n.adminSameBoatRejectedBadge),
                      selected: _status == SameBoatHubStatusFilter.rejected,
                      onSelected: (_) => setState(
                        () => _status = SameBoatHubStatusFilter.rejected,
                      ),
                    ),
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
            if (!widget.compactFilters && widget.showSourceFilter) ...[
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  if (awaitingPublish.isNotEmpty) ...[
                    Text(
                      l10n.sameBoatHubAwaitingPublishTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.sameBoatHubAwaitingPublishHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    for (final product in awaitingPublish) ...[
                      Card(
                        key: Key('same-boat-hub-awaiting-${product.id}'),
                        child: ListTile(
                          title: Text(product.name),
                          subtitle: Text(
                            product.publishStatus == ProductPublishStatus.rejected
                                ? l10n.productStatusRejected
                                : product.publishStatus ==
                                        ProductPublishStatus.draft
                                    ? l10n.productStatusDraft
                                    : l10n.productStatusPending,
                          ),
                          enabled: false,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 12),
                  ],
                  if (products.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          l10n.sameBoatSeatsNoProducts,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < products.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _HubProductTile(
                        product: products[i],
                        dayFmt: dayFmt,
                        adminBypass: widget.adminBypassApproval,
                      ),
                    ],
                ],
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

  void _openSeatsForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SameBoatSeatsScreen(
          product: product,
          adminBypassApproval: adminBypass,
        ),
      ),
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    SameBoatStatus status,
  ) async {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    if (status == SameBoatStatus.approved &&
        !SameBoatSeatOpenLogic.canApprovePending(product)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.sameBoatApproveIncomplete)),
      );
      return;
    }
    try {
      await store.setSameBoatStatus(
        shopId: product.shopId,
        productId: product.id,
        status: status,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pending = product.hasPendingSameBoat;
    final blocked = SameBoatSeatOpenLogic.blocksPartnerRequest(product);
    final canApprove = SameBoatSeatOpenLogic.canApprovePending(product);
    final statusLabel = pending
        ? l10n.adminSameBoatPendingBadge
        : product.hasLiveSameBoatOffer
            ? l10n.adminSameBoatLiveBadge
            : product.hasRejectedSameBoat
                ? l10n.adminSameBoatRejectedBadge
                : l10n.adminSameBoatClosedBadge;
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

    if (adminBypass && pending) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(bits.join(' · '), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: Key('same-boat-hub-reject-${product.id}'),
                      onPressed: () =>
                          _setStatus(context, SameBoatStatus.rejected),
                      child: Text(l10n.adminSameBoatReject),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      key: Key('same-boat-hub-approve-${product.id}'),
                      onPressed: canApprove
                          ? () =>
                              _setStatus(context, SameBoatStatus.approved)
                          : null,
                      child: Text(l10n.sameBoatHubApprove),
                    ),
                  ),
                ],
              ),
              if (!canApprove)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l10n.sameBoatApproveIncomplete,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (!adminBypass && blocked) {
      return Card(
        child: ListTile(
          key: Key('same-boat-hub-${product.id}'),
          title: Text(product.name),
          subtitle: Text(bits.join(' · ')),
          trailing: Text(
            pending ? l10n.sameBoatSeatsWaiting : l10n.adminSameBoatLiveBadge,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      );
    }

    return Card(
      child: ListTile(
        key: Key('same-boat-hub-${product.id}'),
        title: Text(product.name),
        subtitle: Text(bits.join(' · ')),
        trailing: adminBypass
            ? Text(l10n.sameBoatHubOpenSeats)
            : const Icon(Icons.chevron_right),
        onTap: () => _openSeatsForm(context),
      ),
    );
  }
}
