import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/models/story_block.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/storage/dive_video_picker.dart';
import 'package:dive_travel_app/features/admin/presentation/shop_product_box.dart';
import 'package:dive_travel_app/features/admin/presentation/story_block_editor.dart';
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

/// `2026.11.18 (수)` for the planner date fields.
String formatPlannerDay(DateTime day) {
  final local = day.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final date = local.day.toString().padLeft(2, '0');
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  final weekday = weekdays[local.weekday - 1];
  return '${local.year}.$month.$date ($weekday)';
}

int? _nightsInLabel(String label) {
  final match = RegExp(r'(\d+)\s*박').firstMatch(label);
  if (match == null) {
    return null;
  }
  return int.tryParse(match.group(1)!);
}

String _nextShopId(ShopProduct? existing) {
  final shopId = existing?.shopId.trim() ?? '';
  if (shopId.startsWith('curated-')) {
    return shopId;
  }
  return 'curated-${DateTime.now().millisecondsSinceEpoch}';
}

/// New or existing planned trip. Saving a new trip writes one hidden
/// `curated-` shop and its product document. An existing `curated-` trip
/// keeps that shop and its open or hidden state.
class PlannerTripScreen extends StatefulWidget {
  const PlannerTripScreen({
    super.key,
    this.pickCover,
    this.pickStoryPhoto,
    this.pickStoryVideo,
    this.existing,
  });

  /// Test hook. Null uses the device photo picker.
  final Future<PickedPhoto?> Function()? pickCover;

  /// Test hook for a story photo. Null uses the device photo picker.
  final Future<PickedPhoto?> Function()? pickStoryPhoto;

  /// Test hook for a story video. Null uses the device video picker.
  final Future<PickedVideo?> Function()? pickStoryVideo;

  /// Opens that trip for editing when it already has a shop and product.
  final ShopProduct? existing;

  @override
  State<PlannerTripScreen> createState() => _PlannerTripScreenState();
}

class _PlannerTripScreenState extends State<PlannerTripScreen> {
  final _title = TextEditingController();
  final _region = TextEditingController();
  final _blurb = TextEditingController();
  final _productName = TextEditingController();
  final _price = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _includes = TextEditingController();
  final _excludes = TextEditingController();
  final List<_PlannerOption> _options = [];
  final _photoPicker = const DivePhotoPicker();
  List<StoryBlock> _blocks = const [StoryBlock(kind: StoryBlockKind.paragraph)];

  PickedPhoto? _cover;
  var _saving = false;
  var _open = false;
  var _adminHidden = false;
  String? _shopId;
  String? _productId;
  var _placeSeeded = false;

  /// Last known product on this screen. Starts as [widget.existing] and is
  /// refreshed after each save so a second save keeps seats and listing.
  ShopProduct? _live;
  String _cleanFingerprint = '';

  ShopProduct? get _source => _live ?? widget.existing;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _live = existing;
      final shopId = existing.shopId.trim();
      if (shopId.startsWith('curated-')) {
        _shopId = shopId;
        _productId = existing.id;
      }
      _title.text = existing.name;
      _blurb.text = existing.blurb;
      _blocks = StoryBlock.seed(
        stored: existing.storyBlocks,
        legacySchedule: existing.schedule,
      );
      _productName.text = existing.name;
      if (existing.consumerPrice > 0) {
        _price.text = '${existing.consumerPrice}';
      }
      final start = existing.departureStart?.toLocal();
      if (start != null) {
        _start.text = formatPlannerDay(start);
        final nights = _nightsInLabel(existing.durationLabel);
        if (nights != null && nights > 0) {
          _end.text = formatPlannerDay(start.add(Duration(days: nights)));
        } else if (existing.durationLabel.trim() == '1일') {
          _end.text = _start.text;
        }
      }
      _includes.text = existing.includes;
      _excludes.text = existing.excludes;
      for (final option in existing.options) {
        if (option.kind == ProductOptionKind.individual) {
          continue;
        }
        _options.add(_PlannerOption.fromOption(option));
      }
      _adminHidden = existing.sameBoatStatus == SameBoatStatus.hidden;
      _open = existing.isListedPublicly && !_adminHidden;
    }
    _start.addListener(_onDates);
    _end.addListener(_onDates);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _markClean();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final existing = widget.existing;
    if (existing == null || _placeSeeded) {
      return;
    }
    final live = DiverStoreScope.of(context).liveStatsFor(existing.shopId);
    if (live == null) {
      return;
    }
    _placeSeeded = true;
    final shopName = (live.name ?? '').trim();
    if (shopName.isNotEmpty) {
      _title.text = shopName;
    }
    final location = (live.location ?? '').trim();
    final country = (live.country ?? '').trim();
    final region = location.isNotEmpty ? location : country;
    if (region.isNotEmpty) {
      _region.text = region;
    }
    _markClean();
  }

  void _onDates() {
    if (mounted) {
      setState(() {});
    }
  }

  String _fingerprint() {
    return [
      _title.text,
      _region.text,
      _blurb.text,
      _productName.text,
      _price.text,
      _start.text,
      _end.text,
      _includes.text,
      _excludes.text,
      _open ? '1' : '0',
      _cover == null ? '' : 'cover',
      for (final block in _blocks)
        '${block.kind.name}|${block.url}|${block.placeName}|${block.text}',
      for (final option in _options)
        '${option.id}|${option.name.text}|${option.price.text}',
    ].join('\u001f');
  }

  void _markClean() {
    _cleanFingerprint = _fingerprint();
  }

  bool get _isDirty => _fingerprint() != _cleanFingerprint;

  String get _statusLabel {
    if (_adminHidden) {
      return '관리자가 잠시 숨김';
    }
    final source = _source;
    if (source != null && source.isListedPublicly) {
      return '열림';
    }
    return '임시저장';
  }

  Future<bool> _confirmLeave() async {
    if (!_isDirty) {
      return true;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          key: const Key('planner-trip-leave-dialog'),
          title: const Text('나가기'),
          content: const Text('바꾼 내용이 저장되지 않았습니다. 나가시겠습니까?'),
          actions: [
            TextButton(
              key: const Key('planner-trip-leave-stay'),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('머무르기'),
            ),
            TextButton(
              key: const Key('planner-trip-leave-go'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('나가기'),
            ),
          ],
        );
      },
    );
    return leave == true;
  }

  ShopProduct? _productFromStore(DiverStore store, String shopId, String productId) {
    for (final product in store.productsForShop(shopId)) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _title.dispose();
    _region.dispose();
    _blurb.dispose();
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

  List<StoryBlock> _savedBlocks() {
    return [
      for (final block in _blocks)
        if (block.kind == StoryBlockKind.map &&
            (block.placeName.trim().isNotEmpty || block.text.trim().isNotEmpty))
          StoryBlock(
            kind: StoryBlockKind.map,
            placeName: block.placeName.trim(),
            text: block.text.trim(),
          )
        else if (StoryBlock.isMedia(block.kind) && block.url.trim().isNotEmpty)
          StoryBlock(
            kind: block.kind,
            url: block.url.trim(),
            text: block.text.trim(),
          )
        else if (!StoryBlock.isAtomic(block.kind) &&
            (block.kind == StoryBlockKind.divider || block.text.trim().isNotEmpty))
          StoryBlock(
            kind: block.kind,
            text: block.kind == StoryBlockKind.divider ? '' : block.text.trim(),
          ),
    ];
  }

  Future<String> _uploadStoryPhoto(PickedPhoto photo) {
    final store = DiverStoreScope.of(context);
    final shopId = _shopId ??= _nextShopId(widget.existing);
    return store.uploadStoryPhoto(
      shopId: shopId,
      bytes: photo.bytes,
      fileName: photo.fileName,
      contentType: photo.contentType,
    );
  }

  Future<String> _uploadStoryVideo(
    PickedVideo video,
    void Function(double progress) onProgress,
  ) {
    final store = DiverStoreScope.of(context);
    final shopId = _shopId ??= _nextShopId(widget.existing);
    return store.uploadStoryVideo(
      shopId: shopId,
      bytes: video.bytes,
      fileName: video.fileName,
      onProgress: (sent, total) {
        if (total <= 0) {
          return;
        }
        onProgress(sent / total);
      },
    );
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
    final storeForLock = DiverStoreScope.of(context);
    final locked = _adminHidden && !storeForLock.stats.isAdmin;
    // Temp save always closes. Full save follows the open switch.
    final wantOpen = temp ? false : (_open && !locked);
    if (wantOpen && price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.briefTempSaveNeedPrice)),
      );
      return;
    }
    if (!temp && price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.briefTempSaveNeedPrice)),
      );
      return;
    }
    final departure = parsePlannerDay(_start.text);
    final returnDay = parsePlannerDay(_end.text);
    final needDates = wantOpen || !temp;
    if (needDates && (departure == null || returnDay == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('출발일과 종료일을 모두 선택하세요.')),
      );
      return;
    }
    if (departure != null && returnDay != null && returnDay.isBefore(departure)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료일은 출발일 이후여야 합니다.')),
      );
      return;
    }
    setState(() => _saving = true);
    final store = DiverStoreScope.of(context);
    final existing = _source;
    final shopId = _shopId ??= _nextShopId(existing);
    final productId = _productId ??=
        existing != null && existing.shopId.trim() == shopId
            ? existing.id
            : 'p-$shopId';
    final region = _region.text.trim();
    final productName = _productName.text.trim().isEmpty
        ? title
        : _productName.text.trim();
    final duration = plannerDurationLabel(_start.text, _end.text);
    final admin = store.stats.isAdmin;
    final keptKind = existing == null
        ? ProductListingKind.curated
        : existing.listingKind == ProductListingKind.diverPlanned ||
                existing.listingKind == ProductListingKind.curated
            ? existing.listingKind
            : ProductListingKind.curated;
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
        creatorProposal: !admin,
        creatorUid: !admin ? store.uid : null,
      );
      await store.saveShopProduct(
        shopId: shopId,
        product: ShopProduct(
          id: productId,
          shopId: shopId,
          name: productName,
          consumerPrice: price,
          professionalPrice: price,
          active: existing?.active ?? false,
          blurb: _blurb.text.trim(),
          durationLabel: duration,
          schedule: StoryBlock.plainText(_savedBlocks()),
          storyBlocks: _savedBlocks(),
          includes: _includes.text.trim(),
          excludes: _excludes.text.trim(),
          departureStart: departure,
          listingKind: keptKind,
          publishStatus: existing?.publishStatus ?? ProductPublishStatus.draft,
          sameBoatStatus: existing?.sameBoatStatus ?? SameBoatStatus.closed,
          openEmptySeats: existing?.openEmptySeats ?? false,
          capacity: existing?.capacity ?? 0,
          bookedSeats: existing?.bookedSeats ?? 0,
          flagHolds: existing?.flagHolds ?? const [],
          sameBoatOpenedAt: existing?.sameBoatOpenedAt,
          featuredAt: existing?.featuredAt,
          submittedByUid: (existing?.submittedByUid.isNotEmpty ?? false)
              ? existing!.submittedByUid
              : (store.uid ?? ''),
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
        // preserveListing stores the dates and leaves an existing trip's
        // open or hidden state as it was.
        intent: ProductSaveIntent.preserveListing,
        creatorSubmission: !admin,
        submitterUid: store.uid,
        photoBytes: _cover?.bytes,
        photoFileName: _cover?.fileName,
        photoContentType: _cover?.contentType,
      );
      final keepHidden = _adminHidden && !wantOpen;
      if (!keepHidden) {
        await store.setPlannedTripOpen(
          shopId: shopId,
          productId: productId,
          open: wantOpen,
        );
      }
      if (!mounted) {
        return;
      }
      final refreshed = _productFromStore(store, shopId, productId);
      setState(() {
        if (refreshed != null) {
          _live = refreshed;
          _adminHidden = refreshed.sameBoatStatus == SameBoatStatus.hidden;
        }
        _cover = null;
        _saving = false;
        _markClean();
      });
      final shown = wantOpen && !keepHidden;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shown
                ? '저장했습니다. 손님 목록·홈·같은배에 나옵니다.'
                : (temp
                    ? '임시 저장했습니다. 손님 화면에는 아직 나오지 않습니다.'
                    : '저장했습니다. 손님 화면에는 아직 나오지 않습니다.'),
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
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final duration = plannerDurationLabel(_start.text, _end.text);
    final admin = DiverStoreScope.of(context).stats.isAdmin;
    final locked = _adminHidden && !admin;
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        if (await _confirmLeave() && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Theme(
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
                        _statusAndOpen(locked),
                        const SizedBox(height: 12),
                        const Text(
                          '제목·지역·이야기·상품을 적습니다.',
                          key: Key('planner-trip-subtitle'),
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
                            StoryBlockEditor(
                              initial: _blocks,
                              onChanged: (blocks) => _blocks = blocks,
                              pickPhoto: widget.pickStoryPhoto,
                              uploadPhoto: _uploadStoryPhoto,
                              pickVideo: widget.pickStoryVideo,
                              uploadVideo: _uploadStoryVideo,
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
                            _plannerDateSection(wide),
                            const SizedBox(height: 12),
                            ShopProductBox(
                              showDate: false,
                              priceTitle: '판매가',
                              optionsTitle: l10n.partnerFormBoxOptions,
                              includesTitle: l10n.partnerFormBoxIncludes,
                              priceAndPhotos: _priceBlock(),
                              options: _optionsBlock(l10n),
                              includes: _includesBlock(),
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
          bottomNavigationBar: Material(
            color: PartnerTheme.bg,
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusAndOpen(bool locked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _statusLabel,
          key: Key(
            _adminHidden ? 'planner-trip-admin-hidden' : 'planner-trip-status',
          ),
          style: const TextStyle(
            color: PartnerTheme.text,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          key: const Key('planner-trip-open'),
          contentPadding: EdgeInsets.zero,
          title: const Text('열림'),
          subtitle: const Text('켜고 저장하면 손님 목록·홈·같은배에 바로 나옵니다.'),
          value: locked ? false : _open,
          onChanged: locked || _saving
              ? null
              : (value) => setState(() => _open = value),
        ),
      ],
    );
  }

  DateTime get _today {
    final now = DateTime.now().toLocal();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickDateRange() async {
    if (_saving) {
      return;
    }
    final today = _today;
    final start = parsePlannerDay(_start.text);
    final end = parsePlannerDay(_end.text);
    DateTimeRange? initial;
    if (start != null && end != null && !end.isBefore(start)) {
      final safeStart = start.isBefore(today) ? today : start;
      final safeEnd = end.isBefore(safeStart) ? safeStart : end;
      initial = DateTimeRange(start: safeStart, end: safeEnd);
    }
    final picked = await showDateRangePicker(
      context: context,
      locale: const Locale('ko'),
      firstDate: today,
      lastDate: DateTime(today.year + 5, 12, 31),
      initialDateRange: initial,
      helpText: '기간 선택',
      cancelText: '취소',
      confirmText: '확인',
      saveText: '확인',
      fieldStartLabelText: '출발일',
      fieldEndLabelText: '종료일',
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _start.text = formatPlannerDay(picked.start);
      _end.text = formatPlannerDay(picked.end);
    });
  }

  Widget _plannerDateSection(bool wide) {
    final startField = _plannerDateField(
      key: const Key('shop-product-box-date'),
      controller: _start,
      label: '출발일',
    );
    final endField = _plannerDateField(
      key: const Key('shop-product-box-end-date'),
      controller: _end,
      label: '종료일',
    );
    return Material(
      key: const Key('shop-product-box-date-section'),
      color: PartnerTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: PartnerTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '날짜',
              style: TextStyle(
                color: PartnerTheme.text,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            if (!wide)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  startField,
                  const SizedBox(height: 10),
                  endField,
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: startField),
                  const SizedBox(width: 10),
                  Expanded(child: endField),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _plannerDateField({
    required Key key,
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      key: key,
      controller: controller,
      readOnly: true,
      enableInteractiveSelection: false,
      onTap: _pickDateRange,
      style: const TextStyle(color: PartnerTheme.text, fontSize: 15),
      cursorColor: PartnerTheme.accent,
      decoration: InputDecoration(
        labelText: label,
        hintText: '달력에서 선택',
        filled: true,
        fillColor: PartnerTheme.bg,
        labelStyle: const TextStyle(color: PartnerTheme.textDim),
        hintStyle: const TextStyle(color: PartnerTheme.textDim),
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
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
  _PlannerOption({String? id, String name = '', int price = 0})
      : id = id ?? 'opt-${DateTime.now().microsecondsSinceEpoch}',
        name = TextEditingController(text: name),
        price = TextEditingController(text: price > 0 ? '$price' : '');

  factory _PlannerOption.fromOption(ShopProductOption option) {
    return _PlannerOption(
      id: option.id,
      name: option.name,
      price: option.consumerPrice,
    );
  }

  final String id;
  final TextEditingController name;
  final TextEditingController price;

  void dispose() {
    name.dispose();
    price.dispose();
  }
}
