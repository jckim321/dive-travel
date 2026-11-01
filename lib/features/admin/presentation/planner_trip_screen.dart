import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/features/admin/presentation/shop_product_box.dart';
import 'package:dive_travel_app/features/admin/presentation/workbench_price_validation.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Calendar day from `2026.11.18`, `2026-11-18`, or the same text with a weekday.
DateTime? parsePlannerDay(String raw) {
  var text = raw.trim();
  if (text.isEmpty) {
    return null;
  }
  text = text.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  text = text.replaceAll('.', '-').replaceAll('/', '-');
  final parsed = DateTime.tryParse(text);
  if (parsed == null) {
    return null;
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// `12박 13일` from the two date fields. Empty until both days are in order.
String plannerDurationLabel(String startText, String endText) {
  final start = parsePlannerDay(startText);
  final end = parsePlannerDay(endText);
  if (start == null || end == null || end.isBefore(start)) {
    return '';
  }
  final nights = end.difference(start).inDays;
  if (nights <= 0) {
    return '1일';
  }
  return '$nights박 ${nights + 1}일';
}

/// New planned trip. Saving writes one hidden `curated-` shop and its product
/// document. Opening it from a menu, and publishing it, come later.
class PlannerTripScreen extends StatefulWidget {
  const PlannerTripScreen({super.key, this.pickCover});

  /// Test hook. Null uses the device photo picker.
  final Future<PickedPhoto?> Function()? pickCover;

  @override
  State<PlannerTripScreen> createState() => _PlannerTripScreenState();
}

class _PlannerTripScreenState extends State<PlannerTripScreen> {
  final _title = TextEditingController();
  final _region = TextEditingController();
  final _blurb = TextEditingController();
  final _story = TextEditingController();
  final _productName = TextEditingController();
  final _price = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _includes = TextEditingController();
  final _excludes = TextEditingController();
  final List<_PlannerOption> _options = [];
  final _photoPicker = const DivePhotoPicker();

  PickedPhoto? _cover;
  var _saving = false;
  String? _shopId;
  String? _productId;

  @override
  void initState() {
    super.initState();
    _start.addListener(_onDates);
    _end.addListener(_onDates);
  }

  void _onDates() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _region.dispose();
    _blurb.dispose();
    _story.dispose();
    _productName.dispose();
    _price.dispose();
    _start.dispose();
    _end.dispose();
    _includes.dispose();
    _excludes.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCover() async {
    final picked = widget.pickCover != null
        ? await widget.pickCover!()
        : await _photoPicker.pick();
    if (!mounted || picked == null) {
      return;
    }
    setState(() => _cover = picked);
  }

  Future<void> _save({required bool temp}) async {
    if (_saving) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('여행 제목을 입력하세요.')),
      );
      return;
    }
    final price = parsePositivePrice(_price.text) ?? 0;
    if (!temp && price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.briefTempSaveNeedPrice)),
      );
      return;
    }
    setState(() => _saving = true);
    final store = DiverStoreScope.of(context);
    final shopId = _shopId ??= 'curated-${DateTime.now().millisecondsSinceEpoch}';
    final productId = _productId ??= 'p-$shopId';
    final region = _region.text.trim();
    final productName = _productName.text.trim().isEmpty
        ? title
        : _productName.text.trim();
    final duration = plannerDurationLabel(_start.text, _end.text);
    final departure = parsePlannerDay(_start.text);
    try {
      await store.saveShopProfile(
        shopId: shopId,
        name: title,
        location: region,
        country: region,
        productName: productName,
        consumerPrice: price,
        professionalPrice: price,
        intro: _blurb.text.trim(),
        curated: true,
        coverBytes: _cover?.bytes,
        coverFileName: _cover?.fileName,
        coverContentType: _cover?.contentType,
      );
      await store.saveShopProduct(
        shopId: shopId,
        product: ShopProduct(
          id: productId,
          shopId: shopId,
          name: productName,
          consumerPrice: price,
          professionalPrice: price,
          active: false,
          blurb: _blurb.text.trim(),
          durationLabel: duration,
          schedule: _story.text.trim(),
          includes: _includes.text.trim(),
          excludes: _excludes.text.trim(),
          departureStart: departure,
          listingKind: ProductListingKind.curated,
          publishStatus: ProductPublishStatus.draft,
          options: [
            for (final option in _options)
              if (option.name.text.trim().isNotEmpty)
                ShopProductOption(
                  id: option.id,
                  name: option.name.text.trim(),
                  consumerPrice: parsePositivePrice(option.price.text) ?? 0,
                  professionalPrice: parsePositivePrice(option.price.text) ?? 0,
                ),
          ],
        ),
        // keepEditing leaves departure_start off the write (it is a seat key).
        // preserveListing stores the dates and leaves this draft hidden.
        intent: ProductSaveIntent.preserveListing,
        photoBytes: _cover?.bytes,
        photoFileName: _cover?.fileName,
        photoContentType: _cover?.contentType,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            temp
                ? '임시 저장했습니다. 손님 화면에는 아직 나오지 않습니다.'
                : '저장했습니다. 손님 화면에는 아직 나오지 않습니다.',
          ),
        ),
      );
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
    final duration = plannerDurationLabel(_start.text, _end.text);
    return Theme(
      data: PartnerTheme.dark,
      child: Scaffold(
        key: const Key('planner-trip-screen'),
        backgroundColor: PartnerTheme.bg,
        appBar: AppBar(
          backgroundColor: PartnerTheme.bg,
          foregroundColor: PartnerTheme.text,
          title: const Text('기획 여행 만들기'),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '제목·지역·이야기·상품을 적습니다.',
                        key: Key('planner-trip-subtitle'),
                        style: TextStyle(color: PartnerTheme.textDim, height: 1.4),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '저장해도 손님 화면에는 아직 나오지 않습니다.',
                        style: TextStyle(color: PartnerTheme.textDim, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      _section(
                        sectionKey: const Key('planner-section-basics'),
                        step: '1',
                        title: '기본사항',
                        children: [
                          _pair(
                            wide: wide,
                            a: _text(
                              key: const Key('planner-trip-title'),
                              controller: _title,
                              label: '여행 제목',
                            ),
                            b: _text(
                              key: const Key('planner-trip-region'),
                              controller: _region,
                              label: '지역',
                              hint: '몰디브 · 아리환',
                            ),
                          ),
                          const SizedBox(height: 10),
                          _text(
                            key: const Key('planner-trip-blurb'),
                            controller: _blurb,
                            label: '한 줄 소개',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            duration.isEmpty ? '기간은 날짜로 자동' : duration,
                            key: const Key('planner-trip-duration'),
                            style: const TextStyle(color: PartnerTheme.textDim),
                          ),
                          const SizedBox(height: 12),
                          _coverBox(),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _section(
                        sectionKey: const Key('planner-section-story'),
                        step: '2',
                        title: '여행 이야기',
                        children: [
                          TextField(
                            key: const Key('planner-trip-story'),
                            controller: _story,
                            minLines: 6,
                            maxLines: 12,
                            style: const TextStyle(
                              color: PartnerTheme.text,
                              height: 1.45,
                            ),
                            cursorColor: PartnerTheme.accent,
                            decoration: _field('여행 이야기를 적어 주세요'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _section(
                        sectionKey: const Key('planner-section-product'),
                        step: '3',
                        title: '여행 상품 구성',
                        badge: '상품 박스 하나',
                        children: [
                          ShopProductBox(
                            showDate: true,
                            dateController: _start,
                            endDateController: _end,
                            dateSectionTitle: '날짜',
                            endDateLabel: '종료일',
                            priceTitle: '판매가',
                            optionsTitle: l10n.partnerFormBoxOptions,
                            includesTitle: l10n.partnerFormBoxIncludes,
                            priceAndPhotos: _priceBlock(),
                            options: _optionsBlock(l10n),
                            includes: _includesBlock(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              key: const Key('planner-trip-temp-save'),
                              onPressed: _saving ? null : () => _save(temp: true),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: PartnerTheme.text,
                                minimumSize: const Size.fromHeight(48),
                                side: const BorderSide(color: PartnerTheme.border),
                              ),
                              child: Text(l10n.briefTempSave),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              key: const Key('planner-trip-save'),
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
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _priceBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _text(
          key: const Key('planner-product-name'),
          controller: _productName,
          label: '상품 이름',
        ),
        const SizedBox(height: 10),
        _text(
          key: const Key('planner-product-price'),
          controller: _price,
          label: '판매가',
          number: true,
        ),
      ],
    );
  }

  Widget _optionsBlock(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in _options) ...[
          _optionRow(option),
          const SizedBox(height: 8),
        ],
        OutlinedButton(
          key: const Key('planner-add-option'),
          onPressed: _saving
              ? null
              : () => setState(() => _options.add(_PlannerOption())),
          style: OutlinedButton.styleFrom(foregroundColor: PartnerTheme.text),
          child: Text(l10n.partnerFormAddOption),
        ),
      ],
    );
  }

  Widget _optionRow(_PlannerOption option) {
    return Material(
      color: PartnerTheme.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: PartnerTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _text(
                    key: Key('planner-option-name-${option.id}'),
                    controller: option.name,
                    label: '옵션 이름',
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _options.remove(option);
                    option.dispose();
                  }),
                  icon: const Icon(Icons.close, color: PartnerTheme.textDim),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _text(
              key: Key('planner-option-price-${option.id}'),
              controller: option.price,
              label: '가격',
              number: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _includesBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _text(
          key: const Key('planner-includes'),
          controller: _includes,
          label: '포함',
          lines: 3,
        ),
        const SizedBox(height: 8),
        _text(
          key: const Key('planner-excludes'),
          controller: _excludes,
          label: '불포함',
          lines: 3,
        ),
      ],
    );
  }

  Widget _coverBox() {
    final cover = _cover;
    return Material(
      key: const Key('planner-trip-cover'),
      color: PartnerTheme.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: PartnerTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          children: [
            const Icon(Icons.photo_outlined, color: PartnerTheme.textDim),
            const SizedBox(height: 8),
            Text(
              cover == null ? '사진을 여기에 놓으세요' : cover.fileName,
              key: const Key('planner-trip-cover-name'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: PartnerTheme.text),
            ),
            const SizedBox(height: 4),
            const Text(
              '대표 사진',
              style: TextStyle(color: PartnerTheme.textDim, fontSize: 12),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              key: const Key('planner-trip-cover-pick'),
              onPressed: _saving ? null : _pickCover,
              style: OutlinedButton.styleFrom(foregroundColor: PartnerTheme.text),
              child: const Text('파일 선택'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pair({required bool wide, required Widget a, required Widget b}) {
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [a, const SizedBox(height: 10), b],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    );
  }

  Widget _text({
    required Key key,
    required TextEditingController controller,
    required String label,
    String? hint,
    bool number = false,
    int lines = 1,
  }) {
    return TextField(
      key: key,
      controller: controller,
      minLines: lines,
      maxLines: lines,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      inputFormatters: [
        if (number) FilteringTextInputFormatter.digitsOnly,
      ],
      style: const TextStyle(color: PartnerTheme.text),
      cursorColor: PartnerTheme.accent,
      decoration: _field(label, hint: hint),
    );
  }
}

Widget _section({
  required Key sectionKey,
  required String step,
  required String title,
  String? badge,
  required List<Widget> children,
}) {
  return Material(
    key: sectionKey,
    color: PartnerTheme.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: PartnerTheme.border),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: PartnerTheme.accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  step,
                  style: const TextStyle(
                    color: PartnerTheme.bg,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: PartnerTheme.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: PartnerTheme.badgeGreenBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: PartnerTheme.badgeGreenFg,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    ),
  );
}

InputDecoration _field(String label, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: PartnerTheme.bg,
    labelStyle: const TextStyle(color: PartnerTheme.textDim),
    hintStyle: const TextStyle(color: PartnerTheme.textDim),
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

class _PlannerOption {
  _PlannerOption()
      : id = 'opt-${DateTime.now().microsecondsSinceEpoch}',
        name = TextEditingController(),
        price = TextEditingController();

  final String id;
  final TextEditingController name;
  final TextEditingController price;

  void dispose() {
    name.dispose();
    price.dispose();
  }
}
