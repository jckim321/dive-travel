import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_product_entry.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_back_button.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_product_list_logic.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/features/partner/presentation/widgets/partner_product_card.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

const _ink = Color(0xFF0B1F33);
const _muted = Color(0xFF52606D);
const _line = Color(0xFFDDE3EA);
const _teal = Color(0xFF0A6B64);
const _tealBg = Color(0xFFE3F4F1);
const _page = Color(0xFFF4F6F9);
const _navy = Color(0xFF0B2A3C);
const _chipBorder = Color(0xFF8A98A8);

enum _ProductListFilter { all, selling, reviewing, paused }

/// Partner product list (시안 20): master cards with individuals / add-ons.
class PartnerProductsScreen extends StatefulWidget {
  const PartnerProductsScreen({
    super.key,
    this.embedded = false,
    this.shopId,
  });

  final bool embedded;

  /// When set, the list is this resort. Empty uses the signed-in shop.
  final String? shopId;

  @override
  State<PartnerProductsScreen> createState() => _PartnerProductsScreenState();
}

class _PartnerProductsScreenState extends State<PartnerProductsScreen> {
  var _filter = _ProductListFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return PartnerTheme.wrap(
      Theme(
        data: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: _page,
          colorScheme: ColorScheme.fromSeed(
            seedColor: _teal,
            brightness: Brightness.light,
          ),
        ),
        child: Scaffold(
          backgroundColor: _page,
          appBar: widget.embedded
              ? null
              : AppBar(
                  backgroundColor: Colors.white,
                  foregroundColor: _ink,
                  surfaceTintColor: Colors.white,
                  leading: const PartnerBackButton(),
                  title: Text(l10n.partnerProductListTitle),
                ),
          body: ListenableBuilder(
            listenable: store,
            builder: (context, _) {
              final passed = widget.shopId?.trim() ?? '';
              final managedShopId = passed.isNotEmpty
                  ? passed
                  : store.partnerOwnedShopId;
              final products = store.productsForShop(managedShopId);
              final place = _placeFor(store, managedShopId);
              final selling = _count(
                products,
                (product) =>
                    partnerPublishBadgeKind(product) ==
                    PartnerPublishBadgeKind.listed,
              );
              final reviewing = _count(
                products,
                (product) => product.hasPendingPriceRevision,
              );
              final sameBoatOpen = _count(
                products,
                (product) =>
                    partnerSameBoatLineKind(product) ==
                    PartnerSameBoatLineKind.liveOpen,
              );
              final visible = [
                for (final product in products)
                  if (_matches(product, _filter)) product,
              ];

              return ListView(
                key: const Key('partner-products'),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  FilledButton(
                    key: const Key('partner-products-register'),
                    onPressed: () => _openRegister(context, managedShopId),
                    style: FilledButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('+ 상품 등록'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _countBox('판매 중', '$selling'),
                      const SizedBox(width: 8),
                      _countBox('확인 중', '$reviewing'),
                      const SizedBox(width: 8),
                      _countBox(
                        '같은배 열림',
                        '$sameBoatOpen',
                        valueColor: _teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('전체', _ProductListFilter.all),
                        const SizedBox(width: 8),
                        _filterChip('판매 중', _ProductListFilter.selling),
                        const SizedBox(width: 8),
                        _filterChip('확인 중', _ProductListFilter.reviewing),
                        const SizedBox(width: 8),
                        _filterChip('일시중지', _ProductListFilter.paused),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (products.isEmpty)
                    _EmptyProductsCard(
                      onRegister: () => _openRegister(context, managedShopId),
                    )
                  else if (visible.isEmpty)
                    Text(
                      key: const Key('partner-products-filter-empty'),
                      l10n.partnerProductsFilterEmpty,
                      style: const TextStyle(color: _muted, fontSize: 13),
                    )
                  else ...[
                    for (final product in visible) ...[
                      PartnerProductCard(
                        product: product,
                        shopId: managedShopId,
                        place: place,
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      key: const Key('partner-products-footer'),
                      l10n.partnerProductListFooter,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  bool _matches(ShopProduct product, _ProductListFilter filter) {
    return switch (filter) {
      _ProductListFilter.all => true,
      _ProductListFilter.selling =>
        partnerPublishBadgeKind(product) == PartnerPublishBadgeKind.listed,
      _ProductListFilter.reviewing => product.hasPendingPriceRevision,
      _ProductListFilter.paused =>
        partnerPublishBadgeKind(product) == PartnerPublishBadgeKind.closed,
    };
  }

  int _count(List<ShopProduct> products, bool Function(ShopProduct) test) {
    var total = 0;
    for (final product in products) {
      if (test(product)) {
        total += 1;
      }
    }
    return total;
  }

  String _placeFor(DiverStore store, String shopId) {
    for (final shop in store.shops) {
      if (shop.id != shopId && shop.hullId != shopId) {
        continue;
      }
      final country = shop.country.trim();
      final location = shop.location.trim();
      if (country.isEmpty) {
        return location;
      }
      if (location.isEmpty || location == country) {
        return country;
      }
      return '$country $location';
    }
    return '';
  }

  Widget _countBox(String label, String value, {Color valueColor = _ink}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, _ProductListFilter filter) {
    final selected = _filter == filter;
    return ChoiceChip(
      key: Key('partner-products-filter-${filter.name}'),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _filter = filter),
      labelStyle: TextStyle(
        color: selected ? _teal : _ink,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: _tealBg,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? _teal : _chipBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _openRegister(BuildContext context, String shopId) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => resortRegistrationEntry(
          shopId: shopId,
          partnerMode: true,
        ),
      ),
    );
  }
}

class _EmptyProductsCard extends StatelessWidget {
  const _EmptyProductsCard({required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      key: const Key('partner-products-empty'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.partnerProductsEmptyH2,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('partner-products-empty-cta'),
            onPressed: onRegister,
            style: FilledButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.partnerProductsEmptyCtaH2),
          ),
        ],
      ),
    );
  }
}
