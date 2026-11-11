import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_product_entry.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_form_focus.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_product_list_logic.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/features/partner/presentation/widgets/missing_price_badge.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

const _ink = Color(0xFF0B1F33);
const _muted = Color(0xFF52606D);
const _line = Color(0xFFDDE3EA);
const _teal = Color(0xFF0A6B64);
const _tealBg = Color(0xFFE3F4F1);
const _amberFg = Color(0xFF7A4E00);
const _amberBg = Color(0xFFFFF3D6);
const _chipBg = Color(0xFFEEF2F6);
const _border = Color(0xFF8A98A8);

/// Partner master product card (시안 20): base + individuals + add-ons.
class PartnerProductCard extends StatelessWidget {
  const PartnerProductCard({
    super.key,
    required this.product,
    required this.shopId,
    this.place = '',
  });

  final ShopProduct product;
  final String shopId;

  /// Shop country and area, already joined. Empty hides the place.
  final String place;

  static final _priceFormat = NumberFormat('#,###', 'en_US');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final badge = partnerPublishBadgeKind(product);
    final drafting = badge == PartnerPublishBadgeKind.drafting;
    final pending = badge == PartnerPublishBadgeKind.pending;
    final closed = badge == PartnerPublishBadgeKind.closed;
    final listed = badge == PartnerPublishBadgeKind.listed;
    final seatsEnabled = partnerSeatsActionEnabled(product);
    final seatsManage = partnerSeatsIsManage(product);
    final sameBoatKind = partnerSameBoatLineKind(product);
    final individuals = partnerIndividualOptions(product);
    final addons = partnerCommonAddons(product);
    final pricePending = product.hasPendingPriceRevision;
    final price = '1인 ₩${_priceFormat.format(product.consumerPrice)}~';
    final placeLine = place.trim().isEmpty ? price : '${place.trim()} · $price';
    final photo = product.coverUrl.trim().isNotEmpty
        ? product.coverUrl.trim()
        : (product.photoUrls.isEmpty ? '' : product.photoUrls.first.trim());

    return Container(
      key: Key('partner-product-${product.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _thumb(photo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      key: Key('partner-product-price-${product.id}'),
                      placeLine,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _pill(
                          key: Key('partner-product-status-${product.id}'),
                          label: pricePending
                              ? '가격 변경 확인 중'
                              : _statusLabel(l10n, badge),
                          fg: pricePending || closed || drafting || pending
                              ? (pricePending ? _amberFg : _muted)
                              : _teal,
                          bg: pricePending
                              ? _amberBg
                              : (listed ? _tealBg : _chipBg),
                        ),
                        _pill(
                          key: Key('partner-product-same-boat-${product.id}'),
                          label: _sameBoatLabel(sameBoatKind),
                          fg: sameBoatKind == PartnerSameBoatLineKind.liveOpen
                              ? _amberFg
                              : _muted,
                          bg: sameBoatKind == PartnerSameBoatLineKind.liveOpen
                              ? _amberBg
                              : _chipBg,
                        ),
                        MissingPriceBadge(product: product),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _action(
                key: Key('partner-product-edit-${product.id}'),
                label: '가격·옵션',
                onPressed: () => _openEdit(
                  context,
                  focus: PartnerFormFocus.none,
                ),
              ),
              const SizedBox(width: 8),
              _action(
                key: Key('partner-product-seats-${product.id}'),
                label: seatsManage ? '빈자리 관리' : '빈자리 열기',
                accent: seatsEnabled,
                onPressed: seatsEnabled
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PartnerTheme.wrap(
                              SameBoatSeatsScreen(
                                product: product,
                                basePackageOnly: true,
                                partnerLiveCopy: true,
                              ),
                            ),
                          ),
                        )
                    : null,
              ),
              if (listed || closed) ...[
                const SizedBox(width: 8),
                _action(
                  key: Key(
                    closed
                        ? 'partner-product-reopen-${product.id}'
                        : 'partner-product-close-${product.id}',
                  ),
                  label: closed ? l10n.partnerProductReopen : '일시중지',
                  onPressed: () =>
                      closed ? _reopen(context) : _close(context),
                ),
              ],
            ],
          ),
          if (drafting || listed) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              key: Key('partner-product-add-lines-${product.id}'),
              onPressed: () => _openEdit(
                context,
                focus: PartnerFormFocus.addAddon,
              ),
              style: _buttonStyle(accent: false),
              child: Text(l10n.partnerProductAddOptionIndividual),
            ),
          ],
          if (individuals.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              key: Key('partner-product-individuals-title-${product.id}'),
              l10n.bookingEntryIndividuals,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            for (final option in individuals)
              _OptionLine(
                productId: product.id,
                option: option,
                onEdit: () => _openEdit(
                  context,
                  focus: PartnerFormFocus.individuals,
                ),
                onDiscard: () => _discardOption(context, option),
              ),
          ],
          if (addons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              key: Key('partner-product-addons-title-${product.id}'),
              l10n.productFormSectionOptions,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            for (final option in addons)
              _OptionLine(
                productId: product.id,
                option: option,
                onEdit: () => _openEdit(
                  context,
                  focus: PartnerFormFocus.addons,
                ),
                onDiscard: () => _discardOption(context, option),
              ),
          ],
          if (pricePending) ...[
            const SizedBox(height: 8),
            Text(
              key: Key('partner-product-price-review-${product.id}'),
              '가격을 바꾸면 본사 확인 후 반영돼요. 그동안은 이전 가격으로 판매돼요.',
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _statusLabel(
    AppLocalizations l10n,
    PartnerPublishBadgeKind kind,
  ) {
    return switch (kind) {
      PartnerPublishBadgeKind.listed => '판매 중',
      PartnerPublishBadgeKind.drafting => l10n.partnerProductCardBadgeDraft,
      PartnerPublishBadgeKind.pending => l10n.partnerProductCardBadgePending,
      PartnerPublishBadgeKind.closed => '닫힘',
    };
  }

  static String _sameBoatLabel(PartnerSameBoatLineKind kind) {
    return switch (kind) {
      PartnerSameBoatLineKind.liveOpen => '같은배 열림',
      PartnerSameBoatLineKind.notOpened => '같은배 열지 않음',
      PartnerSameBoatLineKind.pendingReview => '같은배 확인 중',
      PartnerSameBoatLineKind.rejected => '같은배 반려',
    };
  }

  Widget _thumb(String url) {
    final placeholder = Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF27C2D1), Color(0xFF0B4F6E)],
        ),
      ),
    );
    if (url.isEmpty) {
      return placeholder;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: 76,
        height: 76,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }

  Widget _pill({
    required Key key,
    required String label,
    required Color fg,
    required Color bg,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _action({
    required Key key,
    required String label,
    required VoidCallback? onPressed,
    bool accent = false,
  }) {
    return Expanded(
      child: OutlinedButton(
        key: key,
        onPressed: onPressed,
        style: _buttonStyle(accent: accent && onPressed != null),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle({required bool accent}) {
    return OutlinedButton.styleFrom(
      foregroundColor: accent ? _teal : _ink,
      disabledForegroundColor: _border,
      backgroundColor: Colors.white,
      side: BorderSide(color: accent ? _teal : _border),
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: TextStyle(
        fontSize: 13,
        fontWeight: accent ? FontWeight.w800 : FontWeight.w700,
      ),
    );
  }

  Future<void> _openEdit(
    BuildContext context, {
    required PartnerFormFocus focus,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => resortRegistrationEntry(
          shopId: shopId,
          partnerMode: true,
          existing: product,
          startEditing: true,
          partnerFocus: focus,
        ),
      ),
    );
  }

  Future<void> _close(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    if (partnerNeedsCloseSeatWarning(product)) {
      final seats = partnerCloseWarningSeatCount(product);
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => PartnerTheme.wrap(
          AlertDialog(
            key: Key('partner-product-close-confirm-${product.id}'),
            title: Text(l10n.partnerProductCloseSeatTitle),
            content: Text(l10n.partnerProductCloseSeatBody(seats)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.adminHqClose),
              ),
              FilledButton(
                key: Key('partner-product-close-confirm-ok-${product.id}'),
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.partnerProductClose),
              ),
            ],
          ),
        ),
      );
      if (ok != true || !context.mounted) {
        return;
      }
    }
    try {
      await store.setPartnerProductActive(
        shopId: shopId,
        productId: product.id,
        active: false,
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _reopen(BuildContext context) async {
    final store = DiverStoreScope.of(context);
    try {
      await store.setPartnerProductActive(
        shopId: shopId,
        productId: product.id,
        active: true,
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _discardOption(
    BuildContext context,
    ShopProductOption option,
  ) async {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => PartnerTheme.wrap(
        AlertDialog(
          key: Key('partner-option-discard-confirm-${option.id}'),
          title: Text(l10n.partnerProductDiscardConfirmTitle),
          content: Text(l10n.partnerProductDiscardConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.adminHqClose),
            ),
            FilledButton(
              key: Key('partner-option-discard-ok-${option.id}'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.partnerProductDiscard),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      final result = await store.discardPartnerOption(
        shopId: shopId,
        productId: product.id,
        optionId: option.id,
      );
      if (!context.mounted) {
        return;
      }
      if (result == PartnerOptionDiscardResult.closed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.partnerProductDiscardClosedSnack)),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}

class _OptionLine extends StatelessWidget {
  const _OptionLine({
    required this.productId,
    required this.option,
    required this.onEdit,
    required this.onDiscard,
  });

  final String productId;
  final ShopProductOption option;
  final VoidCallback onEdit;
  final VoidCallback onDiscard;

  static final _priceFormat = NumberFormat('#,###', 'en_US');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final closed = !option.bookable;
    return Padding(
      key: Key('partner-option-line-${option.id}'),
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.name,
                  style: TextStyle(
                    color: closed ? _muted : _ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  closed
                      ? l10n.partnerProductOptionClosedLabel
                      : '${_priceFormat.format(option.consumerPrice)}원',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            key: Key('partner-option-edit-${option.id}'),
            onPressed: onEdit,
            child: Text(l10n.briefEdit),
          ),
          TextButton(
            key: Key('partner-option-discard-${option.id}'),
            onPressed: closed ? null : onDiscard,
            child: Text(l10n.partnerProductDiscard),
          ),
        ],
      ),
    );
  }
}
