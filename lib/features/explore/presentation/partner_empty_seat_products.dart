import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/planner_date_range.dart';
import 'package:dive_travel_app/features/admin/presentation/planner_trip_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/shop_product_box.dart';
import 'package:dive_travel_app/features/admin/presentation/workbench_price_validation.dart';
import 'package:dive_travel_app/features/admin/presentation/planner_palette.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Optional empty-seat products under the regular product boxes.
///
/// A product is in this section only when `open_empty_seats` is true.
/// The return day is chosen with the departure calendar and stored only as
/// `duration_label` (same as the planner screen).
class PartnerEmptySeatProducts extends StatefulWidget {
  const PartnerEmptySeatProducts({
    super.key,
    required this.shopId,
    this.partnerLabels = false,
    this.onlyProductId,
    this.singleNew = false,
  });

  final String shopId;

  /// Partner product screen copy. The admin desk keeps the original labels.
  final bool partnerLabels;

  /// When set, only this product is shown.
  final String? onlyProductId;

  /// One empty draft, without the shop's other products.
  final bool singleNew;

  @override
  State<PartnerEmptySeatProducts> createState() =>
      _PartnerEmptySeatProductsState();
}

class _PartnerEmptySeatProductsState extends State<PartnerEmptySeatProducts> {
  final _boxes = <_EmptySeatDraft>[];
  final _expanded = <String>{};
  var _saving = false;
  var _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) {
      return;
    }
    _loaded = true;
    if (widget.singleNew) {
      final draft = _EmptySeatDraft.empty(onDates: _onDates);
      _boxes.add(draft);
      _expanded.add(draft.id);
      return;
    }
    final products =
        DiverStoreScope.of(context).liveStatsFor(widget.shopId)?.products ??
        const <ShopProduct>[];
    _boxes.addAll([
      for (final product in products)
        if (_shows(product))
          _EmptySeatDraft.fromProduct(
            product,
            onDates: _onDates,
          ),
    ]);
    _expandSingle();
  }

  bool _shows(ShopProduct product) {
    if (!product.openEmptySeats) {
      return false;
    }
    final only = widget.onlyProductId;
    return only == null || product.id == only;
  }

  void _expandSingle() {
    if ((widget.singleNew || widget.onlyProductId != null) &&
        _boxes.length == 1) {
      _expanded.add(_boxes.single.id);
    }
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
    final pinned = widget.singleNew ? {for (final box in previous) box.id} : null;
    _boxes
      ..clear()
      ..addAll([
        for (final product in products)
          if (_shows(product) && (pinned == null || pinned.contains(product.id)))
            _EmptySeatDraft.fromProduct(
              product,
              onDates: _onDates,
            ),
      ]);
    _expandSingle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final box in previous) {
        box.dispose();
      }
    });
  }

  void _onDates() {
    if (mounted) {
      setState(() {});
    }
  }

  void _addBox() {
    final draft = _EmptySeatDraft.empty(onDates: _onDates);
    setState(() {
      _boxes.add(draft);
      _expanded.add(draft.id);
    });
  }

  DateTime get _today {
    final now = DateTime.now().toLocal();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickDateRange(_EmptySeatDraft box) async {
    if (_saving) {
      return;
    }
    final picked = await pickPlannerDateRange(
      context: context,
      previousStart: parsePlannerDay(box.departure.text),
      previousEnd: parsePlannerDay(box.end.text),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      box.departure.text = formatPlannerDay(picked.start);
      box.end.text = formatPlannerDay(picked.end);
      box.syncFlagCloseDefault(_today);
    });
  }

  Future<void> _pickFlagClose(_EmptySeatDraft box) async {
    if (_saving) {
      return;
    }
    final departure = parsePlannerDay(box.departure.text);
    if (departure == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('출발일을 먼저 선택하세요.')),
      );
      return;
    }
    final today = _today;
    final last = departure.subtract(const Duration(days: 1));
    if (last.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택할 수 있는 깃발 마감일이 없습니다.')),
      );
      return;
    }
    final current = parsePlannerDay(box.flagClose.text);
    var initial = current ?? box.defaultFlagCloseDay(departure, today) ?? today;
    if (initial.isBefore(today)) {
      initial = today;
    }
    if (initial.isAfter(last)) {
      initial = last;
    }
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('ko'),
      firstDate: today,
      lastDate: last,
      initialDate: initial,
      helpText: '깃발 마감일',
      cancelText: '취소',
      confirmText: '확인',
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      box.flagCloseManual = true;
      box.flagClose.text = formatPlannerDay(
        DateTime(picked.year, picked.month, picked.day),
      );
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
      final departure = parsePlannerDay(box.departure.text);
      final returnDay = parsePlannerDay(box.end.text);
      final flagClose = parsePlannerDay(box.flagClose.text);
      final wantOpen = box.listOnSameBoat && !box.sameBoatLocked;
      final needDates = wantOpen || !temp;
      if (needDates && (departure == null || returnDay == null)) {
        setState(() => _expanded.add(box.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('출발일과 종료일을 모두 선택하세요.')),
        );
        return;
      }
      if (departure != null &&
          returnDay != null &&
          returnDay.isBefore(departure)) {
        setState(() => _expanded.add(box.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('종료일은 출발일 이후여야 합니다.')),
        );
        return;
      }
      if (wantOpen && flagClose == null) {
        setState(() => _expanded.add(box.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.workbenchFlagDeadlineRequired)),
        );
        return;
      }
      if (wantOpen &&
          departure != null &&
          flagClose != null &&
          !flagClose.isBefore(departure)) {
        setState(() => _expanded.add(box.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('깃발 마감일은 출발일 이전이어야 합니다.')),
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
      if (widget.partnerLabels) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('같은배 설정을 저장했습니다')),
        );
      }
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
        Text(
          widget.partnerLabels ? '② 같은배 열기 (선택)' : '③ 빈자리 상품 (선택)',
          style: const TextStyle(
            color: PlannerPalette.text,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        for (final box in _boxes) ...[
          _card(l10n, box),
          const SizedBox(height: 12),
        ],
        if (!widget.singleNew && widget.onlyProductId == null) ...[
          OutlinedButton.icon(
            key: const Key('partner-empty-add'),
            onPressed: _saving ? null : _addBox,
            icon: const Icon(Icons.add),
            label: const Text('빈자리 상품 추가'),
            style: OutlinedButton.styleFrom(
              foregroundColor: PlannerPalette.text,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('partner-empty-temp-save'),
                onPressed: _saving ? null : () => _save(temp: true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PlannerPalette.text,
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
                  backgroundColor: PlannerPalette.accent,
                  foregroundColor: PlannerPalette.onAccent,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  _saving
                      ? l10n.exploreSaving
                      : (widget.partnerLabels ? '같은배 저장' : l10n.partnerSave),
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
      color: PlannerPalette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: PlannerPalette.border),
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
                    color: PlannerPalette.text,
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
                  style: TextStyle(color: PlannerPalette.text, fontSize: 14),
                ),
                value: box.listOnSameBoat,
                activeThumbColor: PlannerPalette.accent,
                onChanged: _saving || box.sameBoatLocked
                    ? null
                    : (value) => setState(() => box.listOnSameBoat = value),
              ),
              if (widget.partnerLabels)
                Text(
                  box.listOnSameBoat
                      ? '저장하면 같은배에 올라갑니다'
                      : '저장하면 같은배에서 내려갑니다',
                  style: const TextStyle(
                    color: PlannerPalette.textDim,
                    fontSize: 12,
                  ),
                ),
              TextField(
                key: Key('partner-empty-remaining-${box.id}'),
                controller: box.remaining,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: PlannerPalette.text),
                cursorColor: PlannerPalette.accent,
                decoration: _field('남은 자리'),
              ),
              const SizedBox(height: 10),
              ShopProductBox(
                keyPrefix: 'empty-${box.id}',
                palette: PlannerPaletteColors.plannerLight,
                showDate: true,
                dateController: box.departure,
                endDateController: box.end,
                endDateLabel: '귀국일',
                dateSectionTitle: '날짜',
                onDateTap: () => _pickDateRange(box),
                dateExtra: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _durationReadout(box),
                    const SizedBox(height: 10),
                    _flagCloseField(box),
                  ],
                ),
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

  Widget _durationReadout(_EmptySeatDraft box) {
    final label = plannerDurationLabel(box.departure.text, box.end.text);
    return Text(
      label.isEmpty ? '기간을 달력에서 선택하세요' : label,
      key: Key('partner-empty-duration-${box.id}'),
      style: TextStyle(
        color: label.isEmpty ? PlannerPalette.textDim : PlannerPalette.text,
        fontSize: 14,
        fontWeight: label.isEmpty ? FontWeight.w400 : FontWeight.w700,
      ),
    );
  }

  Widget _flagCloseField(_EmptySeatDraft box) {
    return TextField(
      key: Key('partner-empty-flag-close-${box.id}'),
      controller: box.flagClose,
      readOnly: true,
      enableInteractiveSelection: false,
      enabled: !_saving,
      onTap: _saving ? null : () => _pickFlagClose(box),
      style: const TextStyle(color: PlannerPalette.text, fontSize: 15),
      cursorColor: PlannerPalette.accent,
      decoration: _field('깃발 마감일').copyWith(
        hintText: '달력에서 선택',
        hintStyle: const TextStyle(color: PlannerPalette.textDim),
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
      ),
    );
  }

  Widget _priceBlock(AppLocalizations l10n, _EmptySeatDraft box) {
    return Column(
      children: [
        TextField(
          key: Key('partner-empty-name-${box.id}'),
          controller: box.name,
          style: const TextStyle(color: PlannerPalette.text),
          cursorColor: PlannerPalette.accent,
          decoration: _field('상품 이름'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        TextField(
          key: Key('partner-empty-price-${box.id}'),
          controller: box.consumer,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: PlannerPalette.text),
          cursorColor: PlannerPalette.accent,
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
            style: const TextStyle(color: PlannerPalette.text),
            cursorColor: PlannerPalette.accent,
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
      style: const TextStyle(color: PlannerPalette.text),
      cursorColor: PlannerPalette.accent,
      decoration: _field(l10n.productFormIncludes),
    );
  }
}

InputDecoration _field(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: PlannerPalette.card,
    labelStyle: const TextStyle(color: PlannerPalette.textDim),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: PlannerPalette.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: PlannerPalette.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: PlannerPalette.accent, width: 1.4),
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
    required this.end,
    required this.flagClose,
    required this.remaining,
    required this.addons,
    required this.individuals,
    required this.listOnSameBoat,
    required this.sameBoatLocked,
    required this.onDates,
    this.flagCloseManual = false,
  }) {
    departure.addListener(_handleDates);
    end.addListener(_handleDates);
  }

  factory _EmptySeatDraft.fromProduct(
    ShopProduct product, {
    required VoidCallback onDates,
  }) {
    final departureAt = product.departureStart?.toLocal();
    final booked = product.bookedSeats;
    final left = product.capacity > booked ? product.capacity - booked : 0;
    final departure = TextEditingController(
      text: departureAt == null ? '' : formatPlannerDay(departureAt),
    );
    final end = TextEditingController();
    if (departureAt != null) {
      final nights = nightsInDurationLabel(product.durationLabel);
      if (nights != null && nights > 0) {
        end.text = formatPlannerDay(
          departureAt.add(Duration(days: nights)),
        );
      } else if (product.durationLabel.trim() == '1일') {
        end.text = departure.text;
      }
    }
    final flagAt = product.flagClosesAt?.toLocal();
    final flagClose = TextEditingController(
      text: flagAt == null ? '' : formatPlannerDay(flagAt),
    );
    final draft = _EmptySeatDraft(
      id: product.id,
      source: product,
      name: TextEditingController(text: product.name),
      consumer: TextEditingController(
        text: product.consumerPrice > 0 ? '${product.consumerPrice}' : '',
      ),
      includes: TextEditingController(text: product.includes),
      departure: departure,
      end: end,
      flagClose: flagClose,
      remaining: TextEditingController(text: left > 0 ? '$left' : ''),
      onDates: onDates,
      flagCloseManual: flagAt != null,
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
    if (flagAt == null) {
      final now = DateTime.now().toLocal();
      draft.syncFlagCloseDefault(
        DateTime(now.year, now.month, now.day),
      );
    }
    return draft;
  }

  factory _EmptySeatDraft.empty({required VoidCallback onDates}) {
    return _EmptySeatDraft(
      id: 'p-${DateTime.now().microsecondsSinceEpoch}',
      source: null,
      name: TextEditingController(),
      consumer: TextEditingController(),
      includes: TextEditingController(),
      departure: TextEditingController(),
      end: TextEditingController(),
      flagClose: TextEditingController(),
      remaining: TextEditingController(),
      addons: [],
      individuals: const [],
      listOnSameBoat: false,
      sameBoatLocked: false,
      onDates: onDates,
    );
  }

  final String id;
  final ShopProduct? source;
  final TextEditingController name;
  final TextEditingController consumer;
  final TextEditingController includes;
  final TextEditingController departure;
  final TextEditingController end;
  final TextEditingController flagClose;
  final TextEditingController remaining;
  final List<_SeatOptionDraft> addons;
  final List<ShopProductOption> individuals;
  bool listOnSameBoat;
  final bool sameBoatLocked;
  final VoidCallback onDates;
  bool flagCloseManual;

  bool get isUntouchedNew =>
      source == null &&
      name.text.trim().isEmpty &&
      (parsePositivePrice(consumer.text) ?? 0) <= 0;

  void _handleDates() {
    final now = DateTime.now().toLocal();
    syncFlagCloseDefault(DateTime(now.year, now.month, now.day));
    onDates();
  }

  /// Departure minus 7 days, floored to today.
  DateTime? defaultFlagCloseDay(DateTime departure, DateTime today) {
    final raw = departure.subtract(const Duration(days: 7));
    final day = DateTime(raw.year, raw.month, raw.day);
    if (day.isBefore(today)) {
      return today;
    }
    return day;
  }

  void syncFlagCloseDefault(DateTime today) {
    if (flagCloseManual) {
      return;
    }
    final departureAt = parsePlannerDay(departure.text);
    if (departureAt == null) {
      if (flagClose.text.isNotEmpty) {
        flagClose.clear();
      }
      return;
    }
    final def = defaultFlagCloseDay(departureAt, today);
    if (def == null) {
      return;
    }
    final text = formatPlannerDay(def);
    if (flagClose.text != text) {
      flagClose.text = text;
    }
  }

  void dispose() {
    name.dispose();
    consumer.dispose();
    includes.dispose();
    departure.removeListener(_handleDates);
    end.removeListener(_handleDates);
    departure.dispose();
    end.dispose();
    flagClose.dispose();
    remaining.dispose();
    for (final addon in addons) {
      addon.dispose();
    }
  }

  ShopProduct toProduct(String shopId) {
    final consumerPrice = parsePositivePrice(consumer.text) ?? 0;
    final seatsLeft = int.tryParse(remaining.text.trim()) ?? 0;
    final booked = source?.bookedSeats ?? 0;
    final departureAt = parsePlannerDay(departure.text);
    final duration = plannerDurationLabel(departure.text, end.text);
    final flagCloseAt = parsePlannerDay(flagClose.text);
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
        durationLabel: duration,
        options: options,
        openEmptySeats: true,
        capacity: booked + seatsLeft,
        departureStart: departureAt,
        flagClosesAt: flagCloseAt,
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
      durationLabel: duration,
      options: options,
      openEmptySeats: true,
      capacity: booked + seatsLeft,
      departureStart: departureAt,
      flagClosesAt: flagCloseAt,
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
