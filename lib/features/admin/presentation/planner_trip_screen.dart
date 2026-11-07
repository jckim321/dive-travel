import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/travel_country_master.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/models/story_block.dart';
import 'package:dive_travel_app/core/models/story_html.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/storage/dive_video_picker.dart';
import 'package:dive_travel_app/features/admin/presentation/planner_palette.dart';
import 'package:dive_travel_app/features/admin/presentation/shop_product_box.dart';
import 'package:dive_travel_app/features/admin/presentation/story_block_editor.dart';
import 'package:dive_travel_app/features/admin/presentation/tiptap_story_frame.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_country_field.dart';
import 'package:dive_travel_app/features/admin/presentation/workbench_price_validation.dart';
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
  final _country = TextEditingController();
  final _region = TextEditingController();
  final _blurb = TextEditingController();
  final _price = TextEditingController();
  final _proPrice = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _capacity = TextEditingController();
  final _booked = TextEditingController(text: '0');
  final _flagClose = TextEditingController();
  final _includes = TextEditingController();
  final _excludes = TextEditingController();
  final List<_PlannerOption> _options = [];
  final _photoPicker = const DivePhotoPicker();
  List<StoryBlock> _blocks = const [StoryBlock(kind: StoryBlockKind.paragraph)];

  TravelCountry? _pickedCountry;
  PickedPhoto? _cover;
  var _saving = false;
  var _storySaving = false;
  var _open = false;
  var _adminHidden = false;
  var _bookedLocked = false;
  /// False keeps the flag-close field tied to departure − 7 days (or today).
  var _flagCloseManual = false;
  /// Admin-only trial host for the Tiptap iframe editor.
  var _useNewStoryEditor = false;
  String _draftStoryHtml = '';
  Timer? _storyHtmlAutosaveTimer;
  String? _shopId;
  String? _productId;
  var _placeSeeded = false;
  DateTime? _lastStorySavedAt;

  /// Last known product on this screen. Starts as [widget.existing] and is
  /// refreshed after each save so a second save keeps seats and listing.
  ShopProduct? _live;
  String _cleanFingerprint = '';
  String _cleanStoryFingerprint = '';

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
      if (existing.consumerPrice > 0) {
        _price.text = '${existing.consumerPrice}';
      }
      if (existing.professionalPrice > 0) {
        _proPrice.text = '${existing.professionalPrice}';
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
      final flagClose = existing.flagClosesAt?.toLocal();
      if (flagClose != null) {
        _flagClose.text = formatPlannerDay(flagClose);
        _flagCloseManual = true;
      } else {
        _syncFlagCloseDefault();
      }
      if (existing.capacity > 0) {
        _capacity.text = '${existing.capacity}';
      }
      _booked.text = '${existing.bookedSeats < 0 ? 0 : existing.bookedSeats}';
      _bookedLocked = existing.bookedSeats > 0;
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
    _capacity.addListener(_onDates);
    _booked.addListener(_onDates);
    if (existing == null) {
      _syncFlagCloseDefault();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _markClean();
        unawaited(_hydrateStoryHtmlFromDoc());
      }
    });
  }

  Future<void> _hydrateStoryHtmlFromDoc() async {
    final source = _source;
    if (source == null || source.storyHtml.trim().isNotEmpty) {
      return;
    }
    final shopId = (_shopId ?? source.shopId).trim();
    final productId = (_productId ?? source.id).trim();
    if (shopId.isEmpty || productId.isEmpty) {
      return;
    }
    final store = DiverStoreScope.of(context);
    String? docHtml;
    try {
      docHtml = await store.fetchShopProductStoryHtml(
        shopId: shopId,
        productId: productId,
      );
    } catch (_) {
      return;
    }
    final html = docHtml?.trim() ?? '';
    if (!mounted || html.isEmpty) {
      return;
    }
    setState(() {
      _live = source.copyWith(storyHtml: html);
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
    if (country.isNotEmpty) {
      _country.text = country;
      _pickedCountry = TravelCountryMaster.match(country);
    }
    if (location.isNotEmpty) {
      _region.text = location;
    }
    _markClean();
  }

  void _onDates() {
    _syncFlagCloseDefault();
    if (mounted) {
      setState(() {});
    }
  }

  /// Departure minus 7 days, floored to today.
  DateTime? _defaultFlagCloseDay(DateTime departure) {
    final today = _today;
    final raw = departure.subtract(const Duration(days: 7));
    final day = DateTime(raw.year, raw.month, raw.day);
    if (day.isBefore(today)) {
      return today;
    }
    return day;
  }

  void _syncFlagCloseDefault() {
    if (_flagCloseManual) {
      return;
    }
    final departure = parsePlannerDay(_start.text);
    if (departure == null) {
      if (_flagClose.text.isNotEmpty) {
        _flagClose.clear();
      }
      return;
    }
    final def = _defaultFlagCloseDay(departure);
    if (def == null) {
      return;
    }
    final text = formatPlannerDay(def);
    if (_flagClose.text != text) {
      _flagClose.text = text;
    }
  }

  String _storyFingerprint() {
    return [
      for (final block in _blocks)
        '${block.kind.name}|${block.url}|${block.placeName}|${block.text}',
    ].join('\u001f');
  }

  String _formFingerprint() {
    return [
      _title.text,
      _country.text,
      _region.text,
      _blurb.text,
      _price.text,
      _proPrice.text,
      _start.text,
      _end.text,
      _capacity.text,
      _booked.text,
      _flagClose.text,
      _includes.text,
      _excludes.text,
      _open ? '1' : '0',
      _cover == null ? '' : 'cover',
      for (final option in _options)
        '${option.id}|${option.name.text}|${option.price.text}',
    ].join('\u001f');
  }

  void _markClean() {
    _cleanFingerprint = _formFingerprint();
    _cleanStoryFingerprint = _storyFingerprint();
  }

  void _markStoryClean() {
    _cleanStoryFingerprint = _storyFingerprint();
  }

  bool get _isDirty =>
      _formFingerprint() != _cleanFingerprint ||
      _storyFingerprint() != _cleanStoryFingerprint;

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
    _country.dispose();
    _region.dispose();
    _blurb.dispose();
    _price.dispose();
    _proPrice.dispose();
    _start.dispose();
    _end.dispose();
    _capacity.dispose();
    _booked.dispose();
    _flagClose.dispose();
    _includes.dispose();
    _excludes.dispose();
    for (final option in _options) {
      option.dispose();
    }
    _storyHtmlAutosaveTimer?.cancel();
    super.dispose();
  }

  void _onStoryHtmlChanged(String html) {
    _draftStoryHtml = html;
    _storyHtmlAutosaveTimer?.cancel();
    if (!_useNewStoryEditor) {
      return;
    }
    _storyHtmlAutosaveTimer = Timer(const Duration(seconds: 30), () {
      unawaited(_saveStoryBody(fromAutosave: true));
    });
  }

  Future<void> _toggleNewStoryEditor(bool value) async {
    if (!value) {
      setState(() {
        _useNewStoryEditor = false;
        _storyHtmlAutosaveTimer?.cancel();
      });
      return;
    }
    final store = DiverStoreScope.of(context);
    final shopId = (_shopId ?? _source?.shopId ?? '').trim();
    final productId = (_productId ?? _source?.id ?? '').trim();
    String docHtml = '';
    if (shopId.isNotEmpty && productId.isNotEmpty) {
      try {
        docHtml =
            (await store.fetchShopProductStoryHtml(
              shopId: shopId,
              productId: productId,
            ))
                ?.trim() ??
            '';
      } catch (_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('글을 불러오지 못했습니다. 잠시 뒤 다시 시도하세요'),
          ),
        );
        return;
      }
    }
    if (!mounted) {
      return;
    }
    if (docHtml.isNotEmpty) {
      setState(() {
        _draftStoryHtml = docHtml;
        _useNewStoryEditor = true;
        final live = _source;
        if (live != null) {
          _live = live.copyWith(storyHtml: docHtml);
        }
      });
      return;
    }
    if (storyBlocksHaveMedia(_blocks)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '사진·동영상·지도가 있는 글은 기존 편집기로 수정하세요. 곧 지원됩니다',
          ),
        ),
      );
      return;
    }
    setState(() {
      _draftStoryHtml = storyBlocksToHtml(_blocks);
      _useNewStoryEditor = true;
    });
  }

  int _parseNonNegativeInt(String raw) {
    final value = int.tryParse(raw.trim());
    if (value == null || value < 0) {
      return 0;
    }
    return value;
  }

  int get _capacityValue => _parseNonNegativeInt(_capacity.text);

  int get _bookedValue => _parseNonNegativeInt(_booked.text);

  int get _seatsLeft {
    final left = _capacityValue - _bookedValue;
    return left < 0 ? 0 : left;
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

  String _formatStorySavedAt(DateTime at) {
    final local = at.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '마지막 저장 $month.$day $hour:$minute';
  }

  Future<bool?> _saveStoryBody({required bool fromAutosave}) async {
    if (_saving || _storySaving) {
      return null;
    }
    final title = _title.text.trim();
    final existing = _source;
    final firstSave = existing == null;
    if (firstSave && title.isEmpty) {
      if (!fromAutosave && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('여행 제목을 입력하세요.')),
        );
      }
      return null;
    }
    setState(() => _storySaving = true);
    final store = DiverStoreScope.of(context);
    final admin = store.stats.isAdmin;
    final useHtml = admin && _useNewStoryEditor;
    final blocks = _savedBlocks();
    final schedule = StoryBlock.plainText(blocks);
    final cleanedHtml =
        useHtml ? sanitizeStoryHtml(_draftStoryHtml) : '';
    try {
      if (firstSave) {
        final shopId = _shopId ??= _nextShopId(null);
        final productId = _productId ??= 'p-$shopId';
        final country = _country.text.trim();
        final region = _region.text.trim();
        await store.saveShopProfile(
          shopId: shopId,
          name: title,
          location: region,
          country: country,
          productName: title,
          consumerPrice: 0,
          professionalPrice: 0,
          curated: true,
          creatorProposal: !admin,
          creatorUid: !admin ? store.uid : null,
        );
        await store.saveShopProduct(
          shopId: shopId,
          product: ShopProduct(
            id: productId,
            shopId: shopId,
            name: title,
            consumerPrice: 0,
            professionalPrice: 0,
            schedule: useHtml ? '' : schedule,
            storyBlocks: useHtml ? const [] : blocks,
            listingKind: ProductListingKind.curated,
            publishStatus: ProductPublishStatus.draft,
            active: false,
            openEmptySeats: false,
            sameBoatStatus: SameBoatStatus.closed,
            submittedByUid: store.uid ?? '',
          ),
          intent: ProductSaveIntent.preserveListing,
          creatorSubmission: !admin,
          submitterUid: store.uid,
        );
        if (useHtml) {
          await store.updateShopProductStory(
            shopId: shopId,
            productId: productId,
            storyHtml: cleanedHtml,
          );
        }
      } else {
        final source = existing;
        final shopId = _shopId ??= source.shopId;
        final productId = _productId ??= source.id;
        if (useHtml) {
          await store.updateShopProductStory(
            shopId: shopId,
            productId: productId,
            storyHtml: cleanedHtml,
          );
        } else {
          await store.updateShopProductStory(
            shopId: shopId,
            productId: productId,
            storyBlocks: blocks,
            schedule: schedule,
          );
        }
      }
      if (!mounted) {
        return false;
      }
      final shopId = _shopId!;
      final productId = _productId!;
      final refreshed = _productFromStore(store, shopId, productId);
      setState(() {
        if (refreshed != null) {
          _live = refreshed;
        }
        if (useHtml) {
          _draftStoryHtml = cleanedHtml;
        }
        _lastStorySavedAt = DateTime.now();
        _storySaving = false;
        _markStoryClean();
      });
      return true;
    } catch (_) {
      if (mounted) {
        setState(() => _storySaving = false);
      }
      return false;
    }
  }

  Future<void> _previewStory() async {
    final blocks = _savedBlocks();
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          key: const Key('planner-story-preview-dialog'),
          title: const Text('미리보기'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: blocks.isEmpty
                  ? const Text(
                      '아직 본문이 없습니다.',
                      style: TextStyle(color: PlannerPalette.textDim),
                    )
                  : StoryBlockView(
                      key: const Key('planner-story-preview-view'),
                      blocks: blocks,
                    ),
            ),
          ),
          actions: [
            TextButton(
              key: const Key('planner-story-preview-close'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  Widget _storySectionTrailing() {
    final saved = _lastStorySavedAt;
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        Text(
          key: const Key('planner-story-last-saved'),
          saved == null ? '아직 본문 저장 없음' : _formatStorySavedAt(saved),
          style: const TextStyle(
            color: PlannerPalette.textDim,
            fontSize: 12,
          ),
        ),
        TextButton(
          key: const Key('planner-story-preview'),
          onPressed: _storySaving || _saving ? null : _previewStory,
          child: const Text('미리보기'),
        ),
        FilledButton(
          key: const Key('planner-story-save-body'),
          onPressed: _storySaving || _saving
              ? null
              : () {
                  unawaited(() async {
                    final ok = await _saveStoryBody(fromAutosave: false);
                    if (ok == false && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('본문을 저장하지 못했습니다. 다시 시도합니다.'),
                        ),
                      );
                    }
                  }());
                },
          style: FilledButton.styleFrom(
            backgroundColor: PlannerPalette.accent,
            foregroundColor: PlannerPalette.onAccent,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Text(_storySaving ? '저장 중…' : '본문 저장'),
        ),
      ],
    );
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
    final country = _country.text.trim();
    if (country.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('국가를 입력하세요.')),
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
    final proRaw = _proPrice.text.trim();
    late final int professionalPrice;
    if (proRaw.isEmpty) {
      professionalPrice = price;
    } else {
      final parsedPro = parsePositivePrice(proRaw);
      if (parsedPro == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('강사 우대가를 숫자로 입력하세요.')),
        );
        return;
      }
      if (parsedPro > price) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('강사 우대가는 판매가보다 클 수 없습니다.')),
        );
        return;
      }
      professionalPrice = parsedPro;
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
    final capacity = _capacityValue;
    if (wantOpen && capacity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모집 정원을 1명 이상 입력하세요.')),
      );
      return;
    }
    final flagClose = parsePlannerDay(_flagClose.text);
    if (wantOpen && flagClose == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.workbenchFlagDeadlineRequired)),
      );
      return;
    }
    if (wantOpen &&
        departure != null &&
        flagClose != null &&
        !flagClose.isBefore(departure)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('깃발 마감일은 출발일 이전이어야 합니다.')),
      );
      return;
    }
    final existing = _source;
    final existingBooked = existing?.bookedSeats ?? 0;
    final booked = existingBooked > 0 ? existingBooked : _bookedValue;
    if (capacity > 0 && booked > capacity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('확정 인원은 모집 정원을 넘을 수 없습니다.')),
      );
      return;
    }
    setState(() => _saving = true);
    final store = DiverStoreScope.of(context);
    final shopId = _shopId ??= _nextShopId(existing);
    final productId = _productId ??=
        existing != null && existing.shopId.trim() == shopId
            ? existing.id
            : 'p-$shopId';
    final region = _region.text.trim();
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
        country: country,
        productName: title,
        consumerPrice: price,
        professionalPrice: professionalPrice,
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
          name: title,
          consumerPrice: price,
          professionalPrice: professionalPrice,
          active: existing?.active ?? false,
          blurb: _blurb.text.trim(),
          durationLabel: duration,
          schedule: StoryBlock.plainText(_savedBlocks()),
          storyBlocks: _savedBlocks(),
          includes: _includes.text.trim(),
          excludes: _excludes.text.trim(),
          departureStart: departure,
          flagClosesAt: flagClose,
          listingKind: keptKind,
          publishStatus: existing?.publishStatus ?? ProductPublishStatus.draft,
          sameBoatStatus: existing?.sameBoatStatus ?? SameBoatStatus.closed,
          openEmptySeats: existing?.openEmptySeats ?? false,
          capacity: capacity,
          bookedSeats: booked,
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
          if (refreshed.capacity > 0) {
            _capacity.text = '${refreshed.capacity}';
          }
          _booked.text =
              '${refreshed.bookedSeats < 0 ? 0 : refreshed.bookedSeats}';
          _bookedLocked = refreshed.bookedSeats > 0;
        }
        _cover = null;
        _saving = false;
        _lastStorySavedAt = DateTime.now();
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
        data: PlannerPalette.theme,
        child: Scaffold(
          key: const Key('planner-trip-screen'),
          backgroundColor: PlannerPalette.bg,
          appBar: AppBar(
            backgroundColor: PlannerPalette.bg,
            foregroundColor: PlannerPalette.text,
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
                          style: TextStyle(color: PlannerPalette.textDim, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        _section(
                          sectionKey: const Key('planner-section-basics'),
                          step: '1',
                          title: '기본사항',
                          children: [
                            _text(
                              key: const Key('planner-trip-title'),
                              controller: _title,
                              label: '여행 제목',
                            ),
                            const SizedBox(height: 10),
                            _pair(
                              wide: wide,
                              a: TravelCountryField(
                                controller: _country,
                                fieldKey: const Key('planner-trip-country'),
                                picked: _pickedCountry,
                                style: const TextStyle(color: PlannerPalette.text),
                                cursorColor: PlannerPalette.text,
                                decoration: _field('국가'),
                                showAssignment: false,
                                onEdited: () => setState(() {}),
                                onPicked: (picked) {
                                  setState(() => _pickedCountry = picked);
                                },
                                onCustom: () {
                                  setState(() => _pickedCountry = null);
                                },
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
                              style: const TextStyle(color: PlannerPalette.textDim),
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
                          trailing: _storySectionTrailing(),
                          children: [
                            if (admin) ...[
                              SwitchListTile(
                                key: const Key('planner-new-editor-switch'),
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  '새 편집기(시험)',
                                  style: TextStyle(
                                    color: PlannerPalette.text,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                value: _useNewStoryEditor,
                                onChanged: _saving
                                    ? null
                                    : (value) {
                                        unawaited(_toggleNewStoryEditor(value));
                                      },
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (admin && _useNewStoryEditor)
                              TipTapStoryFrame(
                                initialHtml: _draftStoryHtml,
                                onHtmlChanged: _onStoryHtmlChanged,
                              )
                            else if ((_source?.storyHtml ?? '')
                                .trim()
                                .isNotEmpty)
                              const Padding(
                                key: Key('planner-story-html-locked'),
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  '이 글은 새 편집기로 수정하세요',
                                  style: TextStyle(
                                    color: PlannerPalette.textDim,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            else
                              StoryBlockEditor(
                                initial: _blocks,
                                onChanged: (blocks) => _blocks = blocks,
                                pickPhoto: widget.pickStoryPhoto,
                                uploadPhoto: _uploadStoryPhoto,
                                pickVideo: widget.pickStoryVideo,
                                uploadVideo: _uploadStoryVideo,
                                onAutosave: () =>
                                    _saveStoryBody(fromAutosave: true),
                                lastSavedAt: _lastStorySavedAt,
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
                            _plannerSameBoatSection(wide),
                            const SizedBox(height: 12),
                            ShopProductBox(
                              showDate: false,
                              priceTitle: '판매가',
                              optionsTitle: l10n.partnerFormBoxOptions,
                              includesTitle: l10n.partnerFormBoxIncludes,
                              priceAndPhotos: _priceBlock(),
                              options: _optionsBlock(l10n),
                              includes: _includesBlock(),
                              palette: PlannerPaletteColors.plannerLight,
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
            color: PlannerPalette.bg,
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
                          foregroundColor: PlannerPalette.text,
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: PlannerPalette.border),
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
                          backgroundColor: PlannerPalette.accent,
                          foregroundColor: PlannerPalette.onAccent,
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
            color: PlannerPalette.text,
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

  Future<void> _pickFlagClose() async {
    if (_saving) {
      return;
    }
    final departure = parsePlannerDay(_start.text);
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
    final current = parsePlannerDay(_flagClose.text);
    var initial = current ?? _defaultFlagCloseDay(departure) ?? today;
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
      _flagCloseManual = true;
      _flagClose.text = formatPlannerDay(
        DateTime(picked.year, picked.month, picked.day),
      );
    });
  }

  InputDecoration _plannerFieldDecoration({
    required String label,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      filled: true,
      fillColor: PlannerPalette.bg,
      labelStyle: const TextStyle(color: PlannerPalette.textDim),
      hintStyle: const TextStyle(color: PlannerPalette.textDim),
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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: PlannerPalette.border),
      ),
    );
  }

  Widget _plannerSameBoatSection(bool wide) {
    final capacityField = TextField(
      key: const Key('planner-same-boat-capacity'),
      controller: _capacity,
      enabled: !_saving,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: PlannerPalette.text, fontSize: 15),
      cursorColor: PlannerPalette.text,
      decoration: _plannerFieldDecoration(label: '모집 정원(총 인원)'),
    );
    final bookedField = TextField(
      key: const Key('planner-same-boat-booked'),
      controller: _booked,
      enabled: !_saving && !_bookedLocked,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: PlannerPalette.text, fontSize: 15),
      cursorColor: PlannerPalette.text,
      decoration: _plannerFieldDecoration(
        label: '이미 확정된 인원',
        hintText: '0',
      ),
    );
    final leftLabel = Text(
      key: const Key('planner-same-boat-left'),
      '남은 자리 $_seatsLeft명',
      style: const TextStyle(
        color: PlannerPalette.text,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    );
    final flagCloseField = TextField(
      key: const Key('planner-same-boat-flag-close'),
      controller: _flagClose,
      readOnly: true,
      enableInteractiveSelection: false,
      enabled: !_saving,
      onTap: _saving ? null : _pickFlagClose,
      style: const TextStyle(color: PlannerPalette.text, fontSize: 15),
      cursorColor: PlannerPalette.text,
      decoration: _plannerFieldDecoration(label: '깃발 마감일').copyWith(
        hintText: '달력에서 선택',
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
      ),
    );
    return Material(
      key: const Key('planner-same-boat-section'),
      color: PlannerPalette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: PlannerPalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '같은배 모집',
              style: TextStyle(
                color: PlannerPalette.text,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            if (!wide)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  capacityField,
                  const SizedBox(height: 10),
                  bookedField,
                  const SizedBox(height: 10),
                  leftLabel,
                  const SizedBox(height: 10),
                  flagCloseField,
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: capacityField),
                      const SizedBox(width: 10),
                      Expanded(child: bookedField),
                    ],
                  ),
                  const SizedBox(height: 10),
                  leftLabel,
                  const SizedBox(height: 10),
                  flagCloseField,
                ],
              ),
          ],
        ),
      ),
    );
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
      color: PlannerPalette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: PlannerPalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '날짜',
              style: TextStyle(
                color: PlannerPalette.text,
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
      style: const TextStyle(color: PlannerPalette.text, fontSize: 15),
      cursorColor: PlannerPalette.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: '달력에서 선택',
        filled: true,
        fillColor: PlannerPalette.bg,
        labelStyle: const TextStyle(color: PlannerPalette.textDim),
        hintStyle: const TextStyle(color: PlannerPalette.textDim),
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
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
      ),
    );
  }

  Widget _priceBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _text(
          key: const Key('planner-product-price'),
          controller: _price,
          label: '판매가',
          number: true,
        ),
        const SizedBox(height: 10),
        _text(
          key: const Key('planner-product-pro-price'),
          controller: _proPrice,
          label: '강사 우대가(선택)',
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
          style: OutlinedButton.styleFrom(foregroundColor: PlannerPalette.text),
          child: Text(l10n.partnerFormAddOption),
        ),
      ],
    );
  }

  Widget _optionRow(_PlannerOption option) {
    return Material(
      color: PlannerPalette.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: PlannerPalette.border),
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
                  icon: const Icon(Icons.close, color: PlannerPalette.textDim),
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

  String _existingCoverUrl() {
    final productCover = (_source?.coverUrl ?? '').trim();
    if (productCover.isNotEmpty) {
      return productCover;
    }
    final shopId = (_shopId ?? _source?.shopId ?? '').trim();
    if (shopId.isEmpty) {
      return '';
    }
    final live = DiverStoreScope.of(context).liveStatsFor(shopId);
    return (live?.coverUrl ?? '').trim();
  }

  Widget _coverBox() {
    final cover = _cover;
    final existingUrl = cover == null ? _existingCoverUrl() : '';
    final hasPreview = cover != null || existingUrl.isNotEmpty;
    return Material(
      key: const Key('planner-trip-cover'),
      color: PlannerPalette.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: PlannerPalette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '대표 사진',
              style: TextStyle(
                color: PlannerPalette.text,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            if (hasPreview)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  key: const Key('planner-trip-cover-preview'),
                  height: 180,
                  width: double.infinity,
                  child: cover != null
                      ? Image.memory(
                          cover.bytes,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          existingUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: PlannerPalette.disabledFill,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: PlannerPalette.textDim,
                            ),
                          ),
                        ),
                ),
              )
            else
              const SizedBox(
                height: 120,
                width: double.infinity,
                child: ColoredBox(
                  color: PlannerPalette.disabledFill,
                  child: Icon(
                    Icons.photo_outlined,
                    color: PlannerPalette.textDim,
                  ),
                ),
              ),
            if (cover != null) ...[
              const SizedBox(height: 8),
              Text(
                cover.fileName,
                key: const Key('planner-trip-cover-name'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PlannerPalette.textDim,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 10),
            OutlinedButton(
              key: const Key('planner-trip-cover-pick'),
              onPressed: _saving ? null : _pickCover,
              style: OutlinedButton.styleFrom(
                foregroundColor: PlannerPalette.text,
              ),
              child: const Text('사진 바꾸기'),
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
      style: const TextStyle(color: PlannerPalette.text),
      cursorColor: PlannerPalette.text,
      decoration: _field(label, hint: hint),
    );
  }
}

Widget _section({
  required Key sectionKey,
  required String step,
  required String title,
  String? badge,
  Widget? trailing,
  required List<Widget> children,
}) {
  return Material(
    key: sectionKey,
    color: PlannerPalette.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: PlannerPalette.border),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: PlannerPalette.accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  step,
                  style: const TextStyle(
                    color: PlannerPalette.onAccent,
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
                    color: PlannerPalette.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Flexible(child: trailing),
              ],
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: PlannerPalette.badgeGreenBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: PlannerPalette.badgeGreenFg,
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
    fillColor: PlannerPalette.bg,
    labelStyle: const TextStyle(color: PlannerPalette.textDim),
    hintStyle: const TextStyle(color: PlannerPalette.textDim),
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
