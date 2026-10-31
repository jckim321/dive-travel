import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/shop_product_box.dart';
import 'package:dive_travel_app/features/admin/presentation/workbench_price_validation.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Optional empty-seat products under the regular product boxes.
///
/// A product is in this section only when `open_empty_seats` is true.
/// The return day is departure plus nights read from `duration_label`.
/// It is not stored.
class PartnerEmptySeatProducts extends StatefulWidget {
  const PartnerEmptySeatProducts({super.key, required this.shopId});

  final String shopId;

  @override
  State<PartnerEmptySeatProducts> createState() =>
      _PartnerEmptySeatProductsState();
}

class _PartnerEmptySeatProductsState extends State<PartnerEmptySeatProducts> {
  final _boxes = <_EmptySeatDraft>[];
  final _expanded = <String>{};
  var _saving = false;
  var _loaded = false;

  static final _day = DateFormat('yyyy-MM-dd');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) {
      return;
    }
    _loaded = true;
    final products =
        DiverStoreScope.of(context).liveStatsFor(widget.shopId)?.products ??
        const <ShopProduct>[];
    _boxes.addAll([
      for (final product in products)
        if (product.openEmptySeats)
          _EmptySeatDraft.fromProduct(
            product,
            _day,
            onDeparture: _onDeparture,
          ),
    ]);
  }

  @override
  void dispose() {
    for (final box in _boxes) {
      box.dispose();
    }
    super.dispose();
  }

  void _replaceFromStore() {
    final products =
        DiverStoreScope.of(context).liveStatsFor(widget.shopId)?.products ??
        const <ShopProduct>[];
    final previous = List<_EmptySeatDraft>.of(_boxes);
    _boxes
      ..clear()
      ..addAll([
        for (final product in products)
          if (product.openEmptySeats)
            _EmptySeatDraft.fromProduct(
              product,
              _day,
              onDeparture: _onDeparture,
            ),
      ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final box in previous) {
        box.dispose();
      }
    });
  }

  void _onDeparture() {
    if (mounted) {
      setState(() {});
    }
  }

  void _addBox() {
    final draft = _EmptySeatDraft.empty(onDeparture: _onDeparture);
    setState(() {
      _boxes.add(draft);
      _expanded.add(draft.id);
    });
  }

  Future<void> _save({required bool temp}) async {
    if (_saving) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    for (final box in _boxes) {
      if (box.isUntouchedNew) {
        continue;
      }
      if (box.name.text.trim().isEmpty) {
        setState(() => _expanded.add(box.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상품 이름을 입력하세요.')),
        );
        return;
      }
      if (box.departure.text.trim().isNotEmpty &&
          DateTime.tryParse(box.departure.text.trim()) == null) {
        setState(() => _expanded.add(box.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('출발일은 2026-11-01처럼 입력하세요.')),
        );
        return;
      }
      if (!temp && (parsePositivePrice(box.consumer.text) ?? 0) <= 0) {
        setState(() => _expanded.add(box.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.briefTempSaveNeedPrice)),
        );
        return;
      }
    }
    setState(() => _saving = true);
    final store = DiverStoreScope.of(context);
    try {
      for (final box in _boxes) {
        if (box.isUntouchedNew) {
          continue;
        }
        var product = box.toProduct(widget.shopId);
        final keepLive =
            !temp ||
            box.source?.publishStatus == ProductPublishStatus.approved;
        product = product.copyWith(
          publishStatus: keepLive
              ? ProductPublishStatus.approved
              : ProductPublishStatus.draft,
          active: keepLive,
        );
        await store.saveShopProduct(
          shopId: widget.shopId,
          product: product,
          intent: ProductSaveIntent.preserveListing,
        );
      }
      if (!mounted) {
        return;
      }
      setState(_replaceFromStore);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const Key('partner-empty-seat-products'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '③ 빈자리 상품 (선택)',
          style: TextStyle(
            color: PartnerTheme.text,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        for (final box in _boxes) ...[
          _card(l10n, box),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          key: const Key('partner-empty-add'),
          onPressed: _saving ? null : _addBox,
          icon: const Icon(Icons.add),
          label: const Text('빈자리 상품 추가'),
          style: OutlinedButton.styleFrom(
            foregroundColor: PartnerTheme.text,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('partner-empty-temp-save'),
                onPressed: _saving ? null : () => _save(temp: true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PartnerTheme.text,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(_saving ? l10n.exploreSaving : l10n.briefTempSave),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                key: const Key('partner-empty-save'),
                onPressed: _saving ? null : () => _save(temp: false),
                style: FilledButton.styleFrom(
                  backgroundColor: PartnerTheme.accent,
                  foregroundColor: PartnerTheme.bg,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  _saving ? l10n.exploreSaving : l10n.partnerSave,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _card(AppLocalizations l10n, _EmptySeatDraft box) {
    final open = _expanded.contains(box.id);
    return Material(
      key: Key('partner-empty-card-${box.id}'),
      color: PartnerTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: PartnerTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: Key('partner-empty-expand-${box.id}'),
              onTap: () => setState(() {
                if (open) {
                  _expanded.remove(box.id);
                } else {
                  _expanded.add(box.id);
                }
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  box.name.text.trim().isEmpty ? '이름 없음' : box.name.text.trim(),
                  style: const TextStyle(
                    color: PartnerTheme.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (open) ...[
              SwitchListTile.adaptive(
                key: Key('partner-empty-open-${box.id}'),
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '열림(같은배에 올리기)',
                  style: TextStyle(color: PartnerTheme.text, fontSize: 14),
                ),
                value: box.listOnSameBoat,
                activeThumbColor: PartnerTheme.accent,
                onChanged: _saving || box.sameBoatLocked
                    ? null
                    : (value) => setState(() => box.listOnSameBoat = value),
              ),
              TextField(
                key: Key('partner-empty-remaining-${box.id}'),
                controller: box.remaining,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: PartnerTheme.text),
                cursorColor: PartnerTheme.accent,
                decoration: _field('남은 자리'),
              ),
              const SizedBox(height: 10),
              _returnReadout(box),
              const SizedBox(height: 10),
              ShopProductBox(
                keyPrefix: 'empty-${box.id}',
                showDate: true,
                dateController: box.departure,
                priceTitle: l10n.partnerFormBoxPricePhoto,
                optionsTitle: l10n.partnerFormBoxOptions,
                includesTitle: l10n.partnerFormBoxIncludes,
                priceAndPhotos: _priceBlock(l10n, box),
                options: _optionsBlock(l10n, box),
                includes: _includesBlock(l10n, box),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _returnReadout(_EmptySeatDraft box) {
    final nights = nightsInDurationLabel(box.source?.durationLabel ?? '');
    if (nights == null) {
      return Text(
        '기간을 먼저 입력하세요',
        key: Key('partner-empty-return-${box.id}'),
        style: const TextStyle(color: PartnerTheme.textDim, fontSize: 14),
      );
    }
    final back = returnDayFromDeparture(
      departureText: box.departure.text,
      nights: nights,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '돌아오는 날',
          style: TextStyle(color: PartnerTheme.textDim, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          back == null ? '' : _day.format(back),
          key: Key('partner-empty-return-${box.id}'),
          style: const TextStyle(
            color: PartnerTheme.text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _priceBlock(AppLocalizations l10n, _EmptySeatDraft box) {
    return Column(
      children: [
        TextField(
          key: Key('partner-empty-name-${box.id}'),
          controller: box.name,
          style: const TextStyle(color: PartnerTheme.text),
          cursorColor: PartnerTheme.accent,
          decoration: _field('상품 이름'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        TextField(
          key: Key('partner-empty-price-${box.id}'),
          controller: box.consumer,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: PartnerTheme.text),
          cursorColor: PartnerTheme.accent,
          decoration: _field(l10n.partnerFormBasePrice),
        ),
      ],
    );
  }

  Widget _optionsBlock(AppLocalizations l10n, _EmptySeatDraft box) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final addon in box.addons) ...[
          TextField(
            key: Key('partner-empty-option-${addon.id}'),
            controller: addon.name,
            style: const TextStyle(color: PartnerTheme.text),
            cursorColor: PartnerTheme.accent,
            decoration: _field('옵션 이름'),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton(
          key: Key('partner-empty-add-option-${box.id}'),
          onPressed: () => setState(() {
            box.addons.add(_SeatOptionDraft());
          }),
          child: Text(l10n.partnerFormAddOption),
        ),
      ],
    );
  }

  Widget _includesBlock(AppLocalizations l10n, _EmptySeatDraft box) {
    return TextField(
      key: Key('partner-empty-includes-${box.id}'),
      controller: box.includes,
      minLines: 2,
      maxLines: 4,
      style: const TextStyle(color: PartnerTheme.text),
      cursorColor: PartnerTheme.accent,
      decoration: _field(l10n.productFormIncludes),
    );
  }
}

InputDecoration _field(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: PartnerTheme.bg,
    labelStyle: const TextStyle(color: PartnerTheme.textDim),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: PartnerTheme.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: PartnerTheme.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: PartnerTheme.accent, width: 1.4),
    ),
  );
}

/// Nights written in a duration label, such as `3박 4일`.
/// Days-only or freeform text has no night count.
int? nightsInDurationLabel(String? label) {
  final match = RegExp(r'(\d+)\s*박').firstMatch((label ?? '').trim());
  if (match == null) {
    return null;
  }
  return int.tryParse(match.group(1)!);
}

DateTime calendarDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Today when [preferred] is missing or already past. Later days stay.
DateTime buyerDepartureDay({required DateTime now, DateTime? preferred}) {
  final today = calendarDay(now);
  if (preferred == null) return today;
  final day = calendarDay(preferred);
  return day.isBefore(today) ? today : day;
}

/// Calendar day [nights] after [departure]. Null when the label has no 박.
DateTime? buyerReturnDay({
  required DateTime departure,
  required String? durationLabel,
}) {
  final nights = nightsInDurationLabel(durationLabel);
  if (nights == null) return null;
  return calendarDay(departure).add(Duration(days: nights));
}

/// Calendar day [nights] after the departure text. Not a stored field.
DateTime? returnDayFromDeparture({
  required String departureText,
  required int nights,
}) {
  final start = DateTime.tryParse(departureText.trim());
  if (start == null) {
    return null;
  }
  final day = DateTime(start.year, start.month, start.day);
  return day.add(Duration(days: nights));
}

class _EmptySeatDraft {
  _EmptySeatDraft({
    required this.id,
    required this.source,
    required this.name,
    required this.consumer,
    required this.includes,
    required this.departure,
    required this.remaining,
    required this.addons,
    required this.individuals,
    required this.listOnSameBoat,
    required this.sameBoatLocked,
    required this.onDeparture,
  }) {
    departure.addListener(onDeparture);
  }

  factory _EmptySeatDraft.fromProduct(
    ShopProduct product,
    DateFormat day, {
    required VoidCallback onDeparture,
  }) {
    final departure = product.departureStart;
    final booked = product.bookedSeats;
    final left = product.capacity > booked ? product.capacity - booked : 0;
    return _EmptySeatDraft(
      id: product.id,
      source: product,
      name: TextEditingController(text: product.name),
      consumer: TextEditingController(
        text: product.consumerPrice > 0 ? '${product.consumerPrice}' : '',
      ),
      includes: TextEditingController(text: product.includes),
      departure: TextEditingController(
        text: departure == null ? '' : day.format(departure.toLocal()),
      ),
      remaining: TextEditingController(text: left > 0 ? '$left' : ''),
      onDeparture: onDeparture,
      addons: [
        for (final option in product.options)
          if (option.kind != ProductOptionKind.individual)
            _SeatOptionDraft.fromOption(option),
      ],
      individuals: [
        for (final option in product.options)
          if (option.kind == ProductOptionKind.individual) option,
      ],
      listOnSameBoat: product.sameBoatStatus.isBoardLive,
      sameBoatLocked: product.sameBoatStatus.isPartnerLocked,
    );
  }

  factory _EmptySeatDraft.empty({required VoidCallback onDeparture}) {
    return _EmptySeatDraft(
      id: 'p-${DateTime.now().microsecondsSinceEpoch}',
      source: null,
      name: TextEditingController(),
      consumer: TextEditingController(),
      includes: TextEditingController(),
      departure: TextEditingController(),
      remaining: TextEditingController(),
      addons: [],
      individuals: const [],
      listOnSameBoat: false,
      sameBoatLocked: false,
      onDeparture: onDeparture,
    );
  }

  final String id;
  final ShopProduct? source;
  final TextEditingController name;
  final TextEditingController consumer;
  final TextEditingController includes;
  final TextEditingController departure;
  final TextEditingController remaining;
  final List<_SeatOptionDraft> addons;
  final List<ShopProductOption> individuals;
  bool listOnSameBoat;
  final bool sameBoatLocked;
  final VoidCallback onDeparture;

  bool get isUntouchedNew =>
      source == null &&
      name.text.trim().isEmpty &&
      (parsePositivePrice(consumer.text) ?? 0) <= 0;

  void dispose() {
    name.dispose();
    consumer.dispose();
    includes.dispose();
    departure.removeListener(onDeparture);
    departure.dispose();
    remaining.dispose();
    for (final addon in addons) {
      addon.dispose();
    }
  }

  ShopProduct toProduct(String shopId) {
    final consumerPrice = parsePositivePrice(consumer.text) ?? 0;
    final seatsLeft = int.tryParse(remaining.text.trim()) ?? 0;
    final booked = source?.bookedSeats ?? 0;
    final departureAt = DateTime.tryParse(departure.text.trim());
    final status = sameBoatLocked
        ? source!.sameBoatStatus
        : (listOnSameBoat ? SameBoatStatus.approved : SameBoatStatus.closed);
    final options = <ShopProductOption>[
      for (final addon in addons)
        if (addon.keep) addon.toOption(),
      ...individuals,
    ];
    final existing = source;
    if (existing == null) {
      return ShopProduct(
        id: id,
        shopId: shopId,
        name: name.text.trim(),
        consumerPrice: consumerPrice,
        professionalPrice: consumerPrice,
        includes: includes.text.trim(),
        options: options,
        openEmptySeats: true,
        capacity: booked + seatsLeft,
        departureStart: departureAt,
        sameBoatStatus: status,
        publishStatus: ProductPublishStatus.draft,
      );
    }
    return existing.copyWith(
      name: name.text.trim(),
      consumerPrice: consumerPrice,
      professionalPrice: existing.professionalPrice > 0
          ? existing.professionalPrice
          : consumerPrice,
      includes: includes.text.trim(),
      options: options,
      openEmptySeats: true,
      capacity: booked + seatsLeft,
      departureStart: departureAt,
      sameBoatStatus: status,
    );
  }
}

class _SeatOptionDraft {
  _SeatOptionDraft({ShopProductOption? source})
    : id = source?.id ?? 'opt-${DateTime.now().microsecondsSinceEpoch}',
      source = source,
      name = TextEditingController(text: source?.name ?? '');

  factory _SeatOptionDraft.fromOption(ShopProductOption option) {
    return _SeatOptionDraft(source: option);
  }

  final String id;
  final ShopProductOption? source;
  final TextEditingController name;

  bool get keep => source != null || name.text.trim().isNotEmpty;

  void dispose() {
    name.dispose();
  }

  ShopProductOption toOption() {
    final existing = source;
    if (existing == null) {
      return ShopProductOption(
        id: id,
        name: name.text.trim(),
        kind: ProductOptionKind.addon,
      );
    }
    return existing.copyWith(name: name.text.trim());
  }
}
