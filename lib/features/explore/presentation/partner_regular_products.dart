import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/constants/gallery_limits.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/models/story_html.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/widgets/booking_gallery_editor.dart';
import 'package:dive_travel_app/features/admin/presentation/shop_product_box.dart';
import 'package:dive_travel_app/features/admin/presentation/tiptap_story_frame.dart';
import 'package:dive_travel_app/features/admin/presentation/workbench_price_validation.dart';
import 'package:dive_travel_app/features/admin/presentation/planner_palette.dart';
import 'package:dive_travel_app/features/explore/presentation/partner_contract_box.dart';
import 'package:dive_travel_app/features/explore/presentation/partner_story_editor.dart';
import 'package:dive_travel_app/features/explore/presentation/product_offer_box.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Outcome of a partner story write after the product document save.
class _StoryPersistResult {
  const _StoryPersistResult._({this.failure, this.unconfirmed = false});

  const _StoryPersistResult.skipped() : this._();

  const _StoryPersistResult.saved() : this._();

  const _StoryPersistResult.failed(String reason) : this._(failure: reason);

  /// Loaded story was missing, and the editor has new text. Do not write.
  const _StoryPersistResult.unconfirmed() : this._(unconfirmed: true);

  final String? failure;
  final bool unconfirmed;
}

abstract final class _FormInk {
  static const bg = Color(0xFFF4F6F9);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFDDE3EA);
  static const ink = Color(0xFF0B1F33);
  static const muted = Color(0xFF52606D);
  static const teal = Color(0xFF0A6B64);
  static const chipOn = Color(0xFF0A7C74);
  static const input = Color(0xFF8A98A8);
  static const tagBg = Color(0xFFE3F4F1);
  static const navy = Color(0xFF0B2A3C);
  static const fieldFill = Color(0xFFF7F8F9);
}

/// Regular product boxes on the partner resort screen.
///
/// Empty-seat products are not a section here. Saved individual options stay
/// readable and keep their ids.
class PartnerRegularProducts extends StatefulWidget {
  const PartnerRegularProducts({
    super.key,
    required this.shopId,
    this.partnerLabels = false,
    this.onlyProductId,
    this.singleNew = false,
    this.storyController,
  });

  final String shopId;

  /// Partner product screen copy. The admin desk keeps the original labels.
  final bool partnerLabels;

  /// When set, only this product is shown.
  final String? onlyProductId;

  /// One empty draft, without the shop's other products.
  final bool singleNew;

  /// Partner product screen only. The admin desk leaves this null.
  final TipTapStoryFrameController? storyController;

  @override
  State<PartnerRegularProducts> createState() => _PartnerRegularProductsState();
}

class _PartnerRegularProductsState extends State<PartnerRegularProducts> {
  final _boxes = <_RegularProductDraft>[];
  final _expanded = <String>{};
  final _sectionAnchors = <String, List<GlobalKey>>{};
  final _picker = const DivePhotoPicker();
  var _saving = false;
  var _loaded = false;

  static final _price = NumberFormat('#,###');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) {
      return;
    }
    _loaded = true;
    if (widget.singleNew) {
      final draft = _RegularProductDraft.empty();
      draft.storyReady = true;
      _prepareGuestPrices(draft);
      _boxes.add(draft);
      _expanded.add(draft.id);
      return;
    }
    final store = DiverStoreScope.of(context);
    final products = store.liveStatsFor(widget.shopId)?.products ?? const [];
    _boxes.addAll([
      for (final product in products)
        if (_shows(product)) _RegularProductDraft.fromProduct(product),
    ]);
    for (final box in _boxes) {
      _prepareGuestPrices(box);
    }
    _expandSingle();
    if (widget.partnerLabels) {
      for (final box in _boxes) {
        if (box.source == null) {
          box.storyReady = true;
        }
      }
      unawaited(_loadPartnerStories());
    }
  }

  bool _mountsStoryEditor(_RegularProductDraft box) {
    return widget.partnerLabels &&
        widget.storyController != null &&
        _boxes.isNotEmpty &&
        box.id == _boxes.first.id;
  }

  Future<void> _loadPartnerStories() async {
    if (!widget.partnerLabels || widget.storyController == null) {
      return;
    }
    final store = DiverStoreScope.of(context);
    for (final box in List<_RegularProductDraft>.of(_boxes)) {
      if (box.storyReady || box.source == null || !_mountsStoryEditor(box)) {
        continue;
      }
      try {
        final html = await store.fetchShopProductStoryHtml(
          shopId: widget.shopId,
          productId: box.id,
        );
        if (!mounted) {
          return;
        }
        final text = html ?? '';
        setState(() {
          box.storyInitialHtml = text;
          box.storyDraftHtml = text;
          box.savedStoryHtml = text;
          box.storyReady = true;
          box.storyFetchFailed = false;
        });
      } catch (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          box.storyReady = true;
          box.storyFetchFailed = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장된 소개글을 불러오지 못했습니다: $error')),
        );
      }
    }
  }

  bool _shows(ShopProduct product) {
    final only = widget.onlyProductId;
    final partnerOne = widget.partnerLabels && only != null;
    if (product.openEmptySeats && !partnerOne) {
      return false;
    }
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
    final store = DiverStoreScope.of(context);
    final products = store.liveStatsFor(widget.shopId)?.products ?? const [];
    final previous = List<_RegularProductDraft>.of(_boxes);
    final pinned = widget.singleNew ? {for (final box in previous) box.id} : null;
    final stories = {for (final box in previous) box.id: box};
    _boxes
      ..clear()
      ..addAll([
        for (final product in products)
          if (_shows(product) && (pinned == null || pinned.contains(product.id)))
            _RegularProductDraft.fromProduct(product),
      ]);
    for (final box in _boxes) {
      final old = stories[box.id];
      if (old == null) {
        continue;
      }
      box.storyInitialHtml = old.storyInitialHtml;
      box.storyDraftHtml = old.storyDraftHtml;
      box.savedStoryHtml = old.savedStoryHtml;
      box.storyReady = old.storyReady;
      box.storyFetchFailed = old.storyFetchFailed;
    }
    for (final box in _boxes) {
      _prepareGuestPrices(box);
    }
    _expandSingle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final box in previous) {
        box.dispose();
      }
    });
  }

  void _addBox() {
    final draft = _RegularProductDraft.empty();
    _prepareGuestPrices(draft);
    setState(() {
      _boxes.add(draft);
      _expanded.add(draft.id);
    });
  }

  /// Partner form owns guest prices. Other desks leave the fields off the write.
  void _prepareGuestPrices(_RegularProductDraft box) {
    if (!widget.partnerLabels || box.writeGuestPrices) {
      return;
    }
    box.writeGuestPrices = true;
    if (box.source == null && box.guestTiers.isEmpty) {
      box.seedDefaultGuestTiers();
    }
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
          SnackBar(content: Text(_storyBlockedMessage(box) ?? '상품 이름을 입력하세요.')),
        );
        return;
      }
      if (!temp && (parsePositivePrice(box.consumer.text) ?? 0) <= 0) {
        setState(() => _expanded.add(box.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _storyBlockedMessage(box) ?? l10n.briefTempSaveNeedPrice,
            ),
          ),
        );
        return;
      }
      final peakBlock = box.peakSeasonBlockReason(l10n);
      if (peakBlock != null) {
        setState(() => _expanded.add(box.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(peakBlock)),
        );
        return;
      }
      final saleFrom = _peakDay(box.saleFrom);
      final saleTo = _peakDay(box.saleTo);
      if (saleFrom != null && saleTo != null && saleFrom.isAfter(saleTo)) {
        setState(() => _expanded.add(box.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('출발 가능 기간의 시작일이 종료일보다 늦어요')),
        );
        return;
      }
    }
    setState(() => _saving = true);
    final store = DiverStoreScope.of(context);
    var saved = 0;
    String? storyFailure;
    var storyUnconfirmed = false;
    try {
      for (final box in _boxes) {
        if (box.isUntouchedNew) {
          continue;
        }
        saved++;
        final product = box.toProduct(widget.shopId);
        await store.saveShopProduct(
          shopId: widget.shopId,
          product: product,
          intent: temp
              ? ProductSaveIntent.keepEditing
              : ProductSaveIntent.submitForReview,
          gallery: box.galleryTouched ? box.gallerySlots() : null,
        );
        if (!box.showOnBooking) {
          await store.saveShopProduct(
            shopId: widget.shopId,
            product: product,
            intent: ProductSaveIntent.takeDown,
          );
        }
        final story = await _persistStory(store, box);
        if (story.unconfirmed) {
          storyUnconfirmed = true;
        } else if (story.failure != null) {
          storyFailure ??= story.failure;
        }
      }
      if (!mounted) {
        return;
      }
      if (saved > 0) {
        setState(_replaceFromStore);
      }
      if (widget.partnerLabels) {
        final untouchedStory = saved == 0 &&
            _boxes.any(
              (box) => box.isUntouchedNew && _storyHasContent(box),
            );
        final storyProblem = storyUnconfirmed || storyFailure != null;
        if (saved > 0 && !storyProblem) {
          if (temp) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('임시 저장했습니다 · 손님에게는 아직 보이지 않아요'),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(bottom: 88),
              ),
            );
            await Navigator.of(context).maybePop();
          } else {
            final hidden = _boxes.any(
              (box) => !box.isUntouchedNew && !box.showOnBooking,
            );
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  hidden
                      ? '상품을 저장했습니다 · 손님 예약 화면에서는 숨겨져 있어요'
                      : '상품을 저장했습니다',
                ),
                duration: const Duration(seconds: 4),
              ),
            );
            await Navigator.of(context).maybePop();
          }
        } else {
          final message = storyUnconfirmed
              ? '저장된 소개글을 확인하지 못해 소개글은 저장하지 않았습니다. 새로고침 후 다시 시도해 주세요'
              : storyFailure != null
                  ? '상품은 저장했지만 소개글을 저장하지 못했습니다: $storyFailure'
                  : untouchedStory
                      ? '상품 이름과 가격을 먼저 입력해 주세요'
                      : (saved > 0 ? '상품을 저장했습니다' : '저장할 내용이 없습니다');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
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

  bool _storyHasContent(_RegularProductDraft box) {
    return !partnerStoryBodyIsEmpty(box.storyDraftHtml);
  }

  /// Set when a story is waiting but the existing name or price check stops the save.
  String? _storyBlockedMessage(_RegularProductDraft box) {
    if (!_storyHasContent(box)) {
      return null;
    }
    return '상품 이름과 가격을 먼저 입력해 주세요';
  }

  /// Writes the editor HTML after the product document exists.
  /// Skips the write when the saved story could not be loaded and the editor
  /// has new text, so that text cannot replace an unread document.
  Future<_StoryPersistResult> _persistStory(
    DiverStore store,
    _RegularProductDraft box,
  ) async {
    if (!_mountsStoryEditor(box)) {
      return const _StoryPersistResult.skipped();
    }
    final draft = box.storyDraftHtml;
    if (box.storyFetchFailed) {
      if (partnerStoryBodyIsEmpty(draft)) {
        return const _StoryPersistResult.skipped();
      }
      return const _StoryPersistResult.unconfirmed();
    }
    final cleaned = sanitizeStoryHtml(draft);
    if (partnerStoryBodyIsEmpty(cleaned) &&
        partnerStoryBodyIsEmpty(box.savedStoryHtml)) {
      return const _StoryPersistResult.skipped();
    }
    final stored = partnerStoryBodyIsEmpty(cleaned) ? '' : cleaned;
    try {
      await store.updateShopProductStory(
        shopId: widget.shopId,
        productId: box.id,
        storyHtml: stored,
      );
    } catch (error) {
      return _StoryPersistResult.failed('$error');
    }
    box.storyDraftHtml = stored;
    box.savedStoryHtml = stored;
    box.storyFetchFailed = false;
    final controller = widget.storyController;
    if (controller != null) {
      controller.setStorageKey(partnerStoryStorageKey(widget.shopId, box.id));
      controller.notifySaveSucceeded(stored);
    }
    return const _StoryPersistResult.saved();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const Key('partner-regular-products'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.partnerLabels ? '① 상품' : '일반 상품',
          style: TextStyle(
            color: widget.partnerLabels ? _FormInk.ink : PlannerPalette.text,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '구매자가 예약할 때 정해요',
          key: const Key('partner-regular-date-hint'),
          style: TextStyle(
            color: widget.partnerLabels ? _FormInk.muted : PlannerPalette.textDim,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        for (final box in _boxes) ...[
          _productCard(l10n, box),
          const SizedBox(height: 12),
        ],
        if (widget.partnerLabels) ...[
          PartnerContractBox(shopId: widget.shopId),
          const SizedBox(height: 12),
        ],
        if (!widget.singleNew && widget.onlyProductId == null) ...[
          OutlinedButton.icon(
            key: const Key('partner-regular-add'),
            onPressed: _saving ? null : _addBox,
            icon: const Icon(Icons.add),
            label: const Text('상품 박스 추가'),
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
                key: const Key('partner-regular-temp-save'),
                onPressed: _saving ? null : () => _save(temp: true),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      widget.partnerLabels ? _FormInk.ink : PlannerPalette.text,
                  side: widget.partnerLabels
                      ? const BorderSide(color: _FormInk.input)
                      : null,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      widget.partnerLabels ? 10 : 4,
                    ),
                  ),
                ),
                child: Text(
                  _saving ? l10n.exploreSaving : l10n.briefTempSave,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                key: const Key('partner-regular-save'),
                onPressed: _saving ? null : () => _save(temp: false),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.partnerLabels
                      ? _FormInk.navy
                      : PlannerPalette.accent,
                  foregroundColor: widget.partnerLabels
                      ? Colors.white
                      : PlannerPalette.onAccent,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      widget.partnerLabels ? 10 : 4,
                    ),
                  ),
                ),
                child: Text(
                  _saving
                      ? l10n.exploreSaving
                      : (widget.partnerLabels ? '상품 저장' : l10n.partnerSave),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pushOverForm(Widget page) async {
    final controller = widget.storyController;
    controller?.suspendInput();
    try {
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => page),
      );
    } finally {
      controller?.resumeInput();
    }
  }

  void _openShopInfo() {
    unawaited(
      _pushOverForm(
        ResortDeskScreen(shopId: widget.shopId, partnerMode: true),
      ),
    );
  }

  ShopProduct? _savedProduct(_RegularProductDraft box) {
    final products = DiverStoreScope.of(context).productsForShop(widget.shopId);
    for (final product in products) {
      if (product.id == box.id) {
        return product;
      }
    }
    return box.source;
  }

  void _openEmptySeats(_RegularProductDraft box) {
    final product = _savedProduct(box);
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장된 상품이 없어 빈자리 화면을 열 수 없어요')),
      );
      return;
    }
    unawaited(
      _pushOverForm(
        PartnerTheme.wrap(
          SameBoatSeatsScreen(
            product: product,
            basePackageOnly: true,
            partnerLiveCopy: true,
          ),
        ),
      ),
    );
  }

  Widget _shopInfoRow(String boxId) {
    return ListenableBuilder(
      listenable: DiverStoreScope.of(context),
      builder: (context, _) {
        final store = DiverStoreScope.of(context);
        final liveName = store.liveStatsFor(widget.shopId)?.name?.trim() ?? '';
        final catalogName =
            DiveShopCatalog.byId(widget.shopId)?.name.trim() ?? '';
        final shopName = liveName.isNotEmpty
            ? liveName
            : (catalogName.isNotEmpty ? catalogName : widget.shopId);
        return Column(
          key: Key('partner-regular-shop-$boxId'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '샵',
              style: TextStyle(
                color: _FormInk.muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: _FormInk.fieldFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _FormInk.line),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        shopName,
                        key: Key('partner-regular-shop-name-$boxId'),
                        style: const TextStyle(
                          color: _FormInk.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      key: Key('partner-regular-shop-info-$boxId'),
                      onPressed: _openShopInfo,
                      style: TextButton.styleFrom(
                        foregroundColor: _FormInk.teal,
                      ),
                      child: const Text(
                        '샵 정보 ›',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '이름·지역·주소·소개는 샵 정보에서 불러와요. 여기서 다시 쓰지 않아요.',
              style: TextStyle(
                color: _FormInk.muted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _openSeatsRow(_RegularProductDraft box) {
    return ListenableBuilder(
      listenable: DiverStoreScope.of(context),
      builder: (context, _) {
        final openCount = SameBoatBoard.offers(
          DiverStoreScope.of(context).productsForShop(widget.shopId),
        ).length;
        return DecoratedBox(
          key: Key('partner-regular-seats-${box.id}'),
          decoration: BoxDecoration(
            color: _FormInk.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _FormInk.line),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '열린 빈자리 $openCount / 1',
                        key: Key('partner-regular-seats-count-${box.id}'),
                        style: const TextStyle(
                          color: _FormInk.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '한 번에 1개만 열 수 있어요. 출발이 끝나면 다음 일정을 올릴 수 있어요.',
                        style: TextStyle(
                          color: _FormInk.muted,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  key: Key('partner-regular-seats-open-${box.id}'),
                  onPressed: () => _openEmptySeats(box),
                  style: TextButton.styleFrom(foregroundColor: _FormInk.teal),
                  child: const Text(
                    '빈자리 만들기 ›',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _productCard(AppLocalizations l10n, _RegularProductDraft box) {
    final open = _expanded.contains(box.id);
    final price = parsePositivePrice(box.consumer.text) ?? box.sourcePrice;
    final optionCount = box.optionCount;
    return Material(
      key: Key('partner-regular-card-${box.id}'),
      color: widget.partnerLabels ? Colors.transparent : PlannerPalette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.partnerLabels ? 0 : 14),
        side: BorderSide(
          color: widget.partnerLabels
              ? Colors.transparent
              : PlannerPalette.border,
        ),
      ),
      child: Padding(
        padding: widget.partnerLabels
            ? EdgeInsets.zero
            : const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: Key('partner-regular-expand-${box.id}'),
              onTap: () => setState(() {
                if (open) {
                  _expanded.remove(box.id);
                } else {
                  _expanded.add(box.id);
                }
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        box.name.text.trim().isEmpty
                            ? '이름 없음'
                            : box.name.text.trim(),
                        style: TextStyle(
                          color: widget.partnerLabels
                              ? _FormInk.ink
                              : PlannerPalette.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${_price.format(price)}원',
                      style: TextStyle(
                        color: widget.partnerLabels
                            ? _FormInk.ink
                            : PlannerPalette.text,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (open &&
                        widget.partnerLabels &&
                        MediaQuery.sizeOf(context).width < 1200)
                      TextButton(
                        key: Key('partner-regular-input-preview-${box.id}'),
                        onPressed: () => _openRegularPreviewSheet(l10n, box),
                        style: TextButton.styleFrom(
                          foregroundColor: _FormInk.teal,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.partnerPreviewButton,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    Text(
                      '옵션 $optionCount',
                      key: Key('partner-regular-option-count-${box.id}'),
                      style: TextStyle(
                        color: widget.partnerLabels
                            ? _FormInk.muted
                            : PlannerPalette.textDim,
                      ),
                    ),
                    Icon(
                      open ? Icons.expand_less : Icons.expand_more,
                      color: widget.partnerLabels
                          ? _FormInk.muted
                          : PlannerPalette.textDim,
                    ),
                  ],
                ),
              ),
            ),
            if (open) ...[
              SwitchListTile.adaptive(
                key: Key('partner-regular-visible-${box.id}'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '예약하러 가기에 보이기',
                  style: TextStyle(
                    color: widget.partnerLabels
                        ? _FormInk.ink
                        : PlannerPalette.text,
                    fontSize: 14,
                  ),
                ),
                value: box.showOnBooking,
                activeThumbColor: widget.partnerLabels
                    ? _FormInk.teal
                    : PlannerPalette.accent,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => box.showOnBooking = value),
              ),
              if (widget.partnerLabels)
                Text(
                  box.showOnBooking
                      ? '저장하면 손님 예약 화면에 보입니다'
                      : '저장하면 손님 예약 화면에서 숨겨집니다',
                  style: const TextStyle(
                    color: _FormInk.muted,
                    fontSize: 12,
                  ),
                ),
              if (widget.partnerLabels)
                _partnerSections(l10n, box)
              else
                ShopProductBox(
                  keyPrefix: 'regular-${box.id}',
                  palette: PlannerPaletteColors.plannerLight,
                  priceTitle: l10n.partnerFormBoxPricePhoto,
                  optionsTitle: l10n.partnerFormBoxOptions,
                  includesTitle: l10n.partnerFormBoxIncludes,
                  priceAndPhotos: _priceBlock(l10n, box),
                  options: _optionsBlock(l10n, box),
                  includes: _includesBlock(l10n, box),
                ),
              if (box.individuals.isNotEmpty) _savedIndividuals(box),
            ],
          ],
        ),
      ),
    );
  }

  static const _stepLabels = [
    '기본 정보',
    '사진',
    '핵심 정보',
    '소개 · 일정',
    '가격 · 포함 · 옵션',
    '예약 가능 조건',
    '같은배 빈자리',
    '환불 · 안내',
  ];

  List<GlobalKey> _anchors(String boxId) {
    return _sectionAnchors.putIfAbsent(
      boxId,
      () => [for (var i = 0; i < _stepLabels.length; i++) GlobalKey()],
    );
  }

  void _scrollToSection(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) {
      return;
    }
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 250),
      alignment: 0.08,
    );
  }

  Widget _partnerSections(AppLocalizations l10n, _RegularProductDraft box) {
    final anchors = _anchors(box.id);
    final cards = <Widget>[
      _sectionCard(
        boxKey: Key('partner-regular-section-basic-${box.id}'),
        index: 1,
        title: '기본 정보',
        subtitle: '탐색 목록과 상품 상세의 첫 화면에 쓰여요.',
        tag: '필수',
        child: _basicInfo(l10n, box),
      ),
      _sectionCard(
        boxKey: Key('partner-regular-section-photos-${box.id}'),
        index: 2,
        title: '사진',
        subtitle: '이 상품의 사진이에요. 1번 사진이 탐색 카드와 같은배 카드에 쓰여요.',
        tag: '필수',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _photoEditor(box),
            const SizedBox(height: 10),
            const Text(
              '여러 장을 한 번에 올리고 순서를 바꿔요. 1번이 대표 사진이에요.',
              style: TextStyle(color: _FormInk.muted, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
      _sectionCard(
        boxKey: Key('partner-regular-section-facts-${box.id}'),
        index: 3,
        title: '핵심 정보',
        subtitle: '상품 상세 상단 요약과 검색 필터에 쓰여요.',
        tag: '필수',
        child: _factsBlock(box),
      ),
      _sectionCard(
        boxKey: Key('partner-product-story-${box.id}'),
        index: 4,
        title: '소개 · 일정',
        subtitle: '짧은 소개와 하루 일정을 정해진 칸으로 입력해요.',
        tag: '권장',
        child: _storySchedule(box),
      ),
      _sectionCard(
        boxKey: Key('regular-${box.id}-partner-form-section-price'),
        index: 5,
        title: '가격 · 포함 · 옵션',
        subtitle: '누구와 가는지에 따라 가격이 달라요. 인원 유형별로 가격을 정해요.',
        tag: '필수',
        child: _pricePackage(l10n, box),
      ),
      _sectionCard(
        boxKey: Key('partner-regular-section-sale-${box.id}'),
        index: 6,
        title: '예약 가능 조건',
        subtitle: '날짜를 하나씩 만들지 않고, 규칙으로 늘 열어 두어요.',
        tag: '필수',
        child: _saleRulesBlock(box),
      ),
      _sectionCard(
        boxKey: Key('partner-regular-section-seats-${box.id}'),
        index: 7,
        title: '같은배 빈자리',
        subtitle: '상품은 그대로 두고, 빈자리 화면에서 출발일만 올려요.',
        tag: '선택',
        accent: _FormInk.teal,
        child: _openSeatsRow(box),
      ),
      _sectionCard(
        boxKey: Key('partner-regular-section-refund-${box.id}'),
        index: 8,
        title: '환불 · 안내',
        subtitle: '결제 직전 망설임을 줄이는 구간이에요.',
        tag: '권장',
        child: _refundBlock(box),
      ),
    ];
    final form = Column(
      key: Key('regular-${box.id}-shop-product-box'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < cards.length; i++)
          KeyedSubtree(key: anchors[i], child: cards[i]),
      ],
    );
    if (MediaQuery.sizeOf(context).width < 1000) {
      return form;
    }
    final steps = _PinnedSteps(
      boxId: box.id,
      labels: _stepLabels,
      statuses: const ['필수', '필수', '필수', '권장', '필수', '필수', '선택', '권장'],
      onTap: (index) => _scrollToSection(anchors[index]),
      child: form,
    );
    if (MediaQuery.sizeOf(context).width < 1200) {
      return steps;
    }
    return _StickyPreviewRail(
      preview: _regularOfferPreview(l10n, box),
      child: steps,
    );
  }

  Listenable _regularPreviewListenable(_RegularProductDraft box) {
    return Listenable.merge([
      box.name,
      box.consumer,
      box.professional,
      box.includes,
      box.excludes,
      box.nights,
      box.singleSupplement,
      for (final addon in box.addons) ...[
        addon.name,
        addon.consumer,
        addon.professional,
      ],
      for (final day in box.itinerary) ...[day.day, day.title, day.body],
    ]);
  }

  /// Guest card for one open product box. Shop name and place come from the
  /// same shop lookup the form already uses.
  Widget _regularOfferPreview(AppLocalizations l10n, _RegularProductDraft box) {
    return ListenableBuilder(
      listenable: _regularPreviewListenable(box),
      builder: (context, _) => _regularOfferPreviewBody(l10n, box),
    );
  }

  Widget _regularOfferPreviewBody(
    AppLocalizations l10n,
    _RegularProductDraft box,
  ) {
    final product = box.toProduct(widget.shopId);
    final price = parsePositivePrice(box.consumer.text) ?? 0;
    Uint8List? coverBytes;
    var coverUrl = '';
    var hasPhoto = false;
    if (box.photos.isNotEmpty) {
      final first = box.photos.first;
      final data = first.photo?.bytes;
      if (data != null && data.isNotEmpty) {
        coverBytes = data;
        hasPhoto = true;
      } else {
        coverUrl = first.url?.trim() ?? '';
        hasPhoto = coverUrl.isNotEmpty;
      }
    }
    final en = Localizations.localeOf(context).languageCode == 'en';
    final missing = <String>[
      if (box.name.text.trim().isEmpty) en ? 'product name' : '상품 이름',
      if (price <= 0) en ? 'price' : '가격',
    ];
    const noteStyle = TextStyle(
      color: _FormInk.muted,
      fontSize: 12,
      height: 1.35,
    );
    return Material(
      color: _FormInk.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _FormInk.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.partnerPreviewTitle,
              style: const TextStyle(
                color: _FormInk.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ProductOfferPreview(
              shop: _previewShop(product, coverUrl),
              product: product,
              quote: TourPriceQuote(amount: price, isProfessional: false),
              coverBytes: coverBytes,
            ),
            const SizedBox(height: 8),
            Text(
              missing.isEmpty
                  ? l10n.partnerPreviewReady
                  : l10n.partnerPreviewMissing(missing.join(', ')),
              style: noteStyle,
            ),
            if (!hasPhoto) ...[
              const SizedBox(height: 4),
              Text(l10n.partnerPreviewNoPhoto, style: noteStyle),
            ],
          ],
        ),
      ),
    );
  }

  DiveShop _previewShop(ShopProduct product, String coverUrl) {
    final live = DiverStoreScope.of(context).liveStatsFor(widget.shopId);
    final catalog = DiveShopCatalog.byId(widget.shopId);
    final liveName = live?.name?.trim() ?? '';
    final catalogName = catalog?.name.trim() ?? '';
    final name = liveName.isNotEmpty
        ? liveName
        : (catalogName.isNotEmpty ? catalogName : widget.shopId);
    final liveLocation = live?.location?.trim() ?? '';
    final liveCountry = live?.country?.trim() ?? '';
    final liveContinent = live?.continent?.trim() ?? '';
    return DiveShop(
      id: widget.shopId,
      name: name,
      location: liveLocation.isNotEmpty
          ? liveLocation
          : (catalog?.location ?? ''),
      country: liveCountry.isNotEmpty ? liveCountry : (catalog?.country ?? ''),
      continent: liveContinent.isNotEmpty
          ? liveContinent
          : (catalog?.continent ?? ''),
      sites: const [],
      productName: product.name,
      stars: live?.diveStar ?? catalog?.stars ?? 0,
      rating: live?.avgOverall ?? catalog?.rating ?? 0,
      reviewCount: live?.reviewCount ?? catalog?.reviewCount ?? 0,
      amenities: const [],
      consumerPrice: product.consumerPrice,
      professionalPrice: product.professionalPrice,
      blurb: product.blurb,
      durationLabel: product.durationLabel,
      coverUrl: coverUrl,
    );
  }

  Future<void> _openRegularPreviewSheet(
    AppLocalizations l10n,
    _RegularProductDraft box,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.85;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: _regularOfferPreview(l10n, box),
            ),
          ),
        );
      },
    );
  }

  Widget _basicInfo(AppLocalizations l10n, _RegularProductDraft box) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _shopInfoRow(box.id),
        const SizedBox(height: 12),
        const Text(
          '상품 분류',
          style: TextStyle(color: PlannerPalette.textDim),
        ),
        const SizedBox(height: 6),
        _categoryChips(l10n, box),
        const SizedBox(height: 10),
        _nameField(box),
      ],
    );
  }

  Widget _categoryChips(AppLocalizations l10n, _RegularProductDraft box) {
    final items = <(ProductCategory, String)>[
      (ProductCategory.resortPackage, l10n.workbenchCatResort),
      (ProductCategory.liveaboard, l10n.workbenchCatLiveaboard),
      (ProductCategory.funDive, l10n.workbenchCatFun),
      (ProductCategory.course, l10n.workbenchCatCourse),
      (ProductCategory.dayTrip, l10n.workbenchCatDay),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final item in items)
          FilterChip(
            key: Key(
              'partner-regular-category-${box.id}-${item.$1.firestoreValue}',
            ),
            label: Text(item.$2),
            selected: box.category == item.$1,
            showCheckmark: false,
            selectedColor: _FormInk.chipOn,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: box.category == item.$1 ? Colors.white : _FormInk.ink,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            side: BorderSide(
              color: box.category == item.$1 ? _FormInk.chipOn : _FormInk.input,
            ),
            shape: const StadiumBorder(),
            onSelected: (_) => setState(() => box.category = item.$1),
          ),
      ],
    );
  }

  Widget _factsBlock(_RegularProductDraft box) {
    final nights = _nightsField(box);
    final dives = _numberField(
      controller: box.diveCount,
      keyName: 'partner-regular-dive-count-${box.id}',
      label: '다이빙 횟수',
    );
    final level = _difficultyField(box);
    final guests = _numberField(
      controller: box.maxGuests,
      keyName: 'partner-regular-max-guests-${box.id}',
      label: '하루 최대 인원 (비우면 제한 없음)',
    );
    if (MediaQuery.sizeOf(context).width >= 720) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: nights),
          const SizedBox(width: 10),
          Expanded(child: dives),
          const SizedBox(width: 10),
          Expanded(child: level),
          const SizedBox(width: 10),
          Expanded(child: guests),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        nights,
        dives,
        level,
        guests,
      ],
    );
  }

  Widget _storySchedule(_RegularProductDraft box) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_mountsStoryEditor(box)) _storyBody(box),
        if (_mountsStoryEditor(box)) const SizedBox(height: 12),
        for (final row in box.itinerary) ...[
          _itineraryRow(box, row),
          const SizedBox(height: 8),
        ],
        OutlinedButton(
          key: Key('partner-regular-itinerary-add-${box.id}'),
          onPressed: () => setState(() => box.itinerary.add(_ItineraryDraft())),
          style: OutlinedButton.styleFrom(
            foregroundColor: _FormInk.teal,
            side: const BorderSide(color: _FormInk.input, width: 1.5),
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            '+ 일정 추가',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _itineraryRow(_RegularProductDraft box, _ItineraryDraft row) {
    return Column(
      key: Key('partner-regular-itinerary-${row.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: _labeled(
                '일차',
                TextField(
                  key: Key('partner-regular-itinerary-day-${row.id}'),
                  controller: row.day,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: _ink,
                  cursorColor: _cursor,
                  decoration: _deco('일차'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _labeled(
                '제목',
                TextField(
                  key: Key('partner-regular-itinerary-title-${row.id}'),
                  controller: row.title,
                  style: _ink,
                  cursorColor: _cursor,
                  decoration: _deco('제목'),
                ),
              ),
            ),
            IconButton(
              onPressed: () => setState(() {
                box.itinerary.remove(row);
                row.dispose();
              }),
              icon: const Icon(Icons.close, color: _FormInk.muted),
            ),
          ],
        ),
        _labeled(
          '내용',
          TextField(
            key: Key('partner-regular-itinerary-body-${row.id}'),
            controller: row.body,
            minLines: 2,
            maxLines: 4,
            style: _ink,
            cursorColor: _cursor,
            decoration: _deco('내용'),
          ),
        ),
      ],
    );
  }

  Widget _pricePackage(AppLocalizations l10n, _RegularProductDraft box) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _basePriceRow(l10n, box),
        const SizedBox(height: 10),
        _guestTierList(box),
        const SizedBox(height: 10),
        _supplementField(box),
        const SizedBox(height: 12),
        _peakSeasonBlock(box),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: Key('regular-${box.id}-partner-form-section-includes'),
          child: _includesBlock(l10n, box),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: Key('regular-${box.id}-partner-form-section-options'),
          child: _optionsBlock(l10n, box),
        ),
      ],
    );
  }

  Widget _refundBlock(_RegularProductDraft box) {
    final policy = box.weatherPolicy;
    const known = <String, String>{
      'full_refund': '전액 환불',
      'reschedule_or_refund': '일정 변경 또는 환불',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _numberField(
          controller: box.freeCancelDays,
          keyName: 'partner-regular-free-cancel-${box.id}',
          label: '무료 취소 기한 (출발 며칠 전까지)',
        ),
        const SizedBox(height: 10),
        _labeled(
          '기상 악화로 출항 취소 시',
          DropdownButtonFormField<String>(
          key: Key('partner-regular-weather-${box.id}-$policy'),
          initialValue: policy,
          decoration: _deco('기상 악화로 출항 취소 시'),
          items: [
            if (policy.isNotEmpty && !known.containsKey(policy))
              DropdownMenuItem(value: policy, child: Text(policy)),
            const DropdownMenuItem(value: '', child: Text('선택해 주세요')),
            for (final item in known.entries)
              DropdownMenuItem(value: item.key, child: Text(item.value)),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() => box.weatherPolicy = value);
          },
        ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required Key boxKey,
    required int index,
    required String title,
    required String subtitle,
    required String tag,
    required Widget child,
    Color accent = _FormInk.line,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        key: boxKey,
        color: _FormInk.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accent),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                      color: _FormInk.line,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        color: _FormInk.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: _FormInk.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: _FormInk.muted,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _FormInk.tagBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: _FormInk.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _storyBody(_RegularProductDraft box) {
    if (!kIsWeb) {
      return Text(
        '소개글 편집은 웹에서만 열립니다',
        key: Key('partner-story-web-only-${box.id}'),
      );
    }
    final controller = widget.storyController;
    if (controller == null) {
      return const SizedBox.shrink();
    }
    if (!box.storyReady) {
      return const SizedBox(
        height: 360,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return PartnerStoryEditor(
      key: Key('partner-story-editor-${box.id}'),
      shopId: widget.shopId,
      productId: box.id,
      initialHtml: box.storyInitialHtml,
      controller: controller,
      onHtmlChanged: (html) => box.storyDraftHtml = html,
    );
  }

  TextStyle get _ink => TextStyle(
        color: widget.partnerLabels ? _FormInk.ink : PlannerPalette.text,
        fontSize: 14,
      );

  Color get _cursor =>
      widget.partnerLabels ? _FormInk.teal : PlannerPalette.accent;

  InputDecoration _deco(String label) {
    if (!widget.partnerLabels) {
      return _field(label);
    }
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: _FormInk.input),
    );
    return const InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      constraints: BoxConstraints(minHeight: 44),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: _FormInk.teal, width: 1.6),
      ),
    );
  }

  Widget _labeled(String label, Widget field) {
    if (!widget.partnerLabels) {
      return field;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _FormInk.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          field,
        ],
      ),
    );
  }

  Widget _nameField(_RegularProductDraft box) {
    return _labeled(
      '상품 이름',
      TextField(
        key: Key('partner-regular-name-${box.id}'),
        controller: box.name,
        style: _ink,
        cursorColor: _cursor,
        decoration: _deco('상품 이름'),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _basePriceRow(AppLocalizations l10n, _RegularProductDraft box) {
    final diverLabel = widget.partnerLabels ? '다이버' : l10n.partnerFormBasePrice;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _labeled(
            diverLabel,
            TextField(
              key: Key('partner-regular-price-${box.id}'),
              controller: box.consumer,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: _ink,
              cursorColor: _cursor,
              decoration: _deco(diverLabel),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _labeled(
            l10n.exploreProPrice,
            TextField(
              controller: box.professional,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: _ink,
              cursorColor: _cursor,
              decoration: _deco(l10n.exploreProPrice),
            ),
          ),
        ),
      ],
    );
  }

  Widget _photoEditor(_RegularProductDraft box) {
    return BookingGalleryEditor(
      items: box.photos,
      compact: true,
      maxItems: GalleryLimits.maxProductPhotos,
      onManagerOpening: widget.storyController?.suspendInput,
      onManagerClosed: widget.storyController?.resumeInput,
      onAdd: () => _addPhotos(box),
      onRemove: (index) => setState(() {
        box.galleryTouched = true;
        box.photos.removeAt(index);
      }),
      onMakeCover: (index) => setState(() {
        box.galleryTouched = true;
        final item = box.photos.removeAt(index);
        box.photos.insert(0, item);
      }),
    );
  }

  Widget _nightsField(_RegularProductDraft box) {
    return _labeled(
      '숙박 박 수 (예: 2박 3일이면 2)',
      TextField(
        key: Key('partner-regular-nights-${box.id}'),
        controller: box.nights,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: _ink,
        cursorColor: _cursor,
        decoration: _deco('숙박 박 수 (예: 2박 3일이면 2)'),
      ),
    );
  }

  Widget _supplementField(_RegularProductDraft box) {
    return _labeled(
      '1인 1실 추가 요금 (1박당)',
      TextField(
        key: Key('partner-regular-single-supplement-${box.id}'),
        controller: box.singleSupplement,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: _ink,
        cursorColor: _cursor,
        decoration: _deco('1인 1실 추가 요금(1박당)'),
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String keyName,
    required String label,
  }) {
    return _labeled(
      label,
      TextField(
        key: Key(keyName),
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: _ink,
        cursorColor: _cursor,
        decoration: _deco(label),
      ),
    );
  }

  Widget _difficultyField(_RegularProductDraft box) {
    const known = [
      '오픈워터 이상 (체험 옵션 있음)',
      '자격 불필요',
      '어드밴스드 이상',
    ];
    final current = box.difficulty;
    return _labeled(
      '요구 자격',
      DropdownButtonFormField<String>(
      key: Key('partner-regular-difficulty-${box.id}-$current'),
      initialValue: current,
      decoration: _deco('요구 자격'),
      items: [
        if (current.isNotEmpty && !known.contains(current))
          DropdownMenuItem(value: current, child: Text(current)),
        const DropdownMenuItem(value: '', child: Text('선택해 주세요')),
        for (final label in known)
          DropdownMenuItem(value: label, child: Text(label)),
      ],
      onChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() => box.difficulty = value);
      },
    ),
    );
  }

  Widget _guestTierList(_RegularProductDraft box) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    const head = TextStyle(
      color: _FormInk.muted,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '인원 유형별 가격',
          style: TextStyle(
            color: _FormInk.ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (wide)
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('유형', style: head)),
                SizedBox(width: 8),
                Expanded(flex: 3, child: Text('손님에게 보이는 조건', style: head)),
                SizedBox(width: 8),
                Expanded(flex: 2, child: Text('가격(원)', style: head)),
                SizedBox(
                  width: 48,
                  child: Text('삭제', style: head),
                ),
              ],
            ),
          ),
        for (final tier in box.guestTiers) ...[
          _guestTierRow(box, tier),
          const SizedBox(height: 8),
        ],
        OutlinedButton(
          key: Key('partner-regular-add-tier-${box.id}'),
          onPressed: () => setState(() {
            box.guestTiers.add(_GuestTierDraft());
          }),
          style: OutlinedButton.styleFrom(
            foregroundColor: _FormInk.teal,
            side: const BorderSide(color: _FormInk.input, width: 1.5),
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            '+ 인원 유형 추가',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '다이버 1명 이상 동반 필수 · 소아·유아는 보호자 동반 필수',
          style: TextStyle(color: _FormInk.muted, fontSize: 13, height: 1.45),
        ),
      ],
    );
  }

  Widget _priceBlock(AppLocalizations l10n, _RegularProductDraft box) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _nameField(box),
        const SizedBox(height: 10),
        _basePriceRow(l10n, box),
        if (widget.partnerLabels) ...[
          const SizedBox(height: 10),
          _guestPriceBlock(box),
        ],
        const SizedBox(height: 10),
        _photoEditor(box),
      ],
    );
  }

  Widget _guestPriceBlock(_RegularProductDraft box) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _guestTierList(box),
        const SizedBox(height: 10),
        _nightsField(box),
        const SizedBox(height: 10),
        _supplementField(box),
        const SizedBox(height: 16),
        _peakSeasonBlock(box),
        const SizedBox(height: 16),
        _saleRulesBlock(box),
      ],
    );
  }

  Widget _peakSeasonBlock(_RegularProductDraft box) {
    final l10n = AppLocalizations.of(context);
    const labelStyle = TextStyle(
      color: _FormInk.muted,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );
    String roleName(GuestRole role) {
      return switch (role) {
        GuestRole.diver => l10n.workbenchGuestDiver,
        GuestRole.nondiver => l10n.workbenchGuestNondiver,
        GuestRole.child => l10n.workbenchGuestChild,
        GuestRole.infant => l10n.workbenchGuestInfant,
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.partnerPeakSeasonTitle,
          style: const TextStyle(
            color: _FormInk.ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < box.peakSeasons.length; index++) ...[
          _peakSeasonCard(box, box.peakSeasons[index], index, roleName, labelStyle),
          const SizedBox(height: 8),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: Key('partner-peak-add-${box.id}'),
            onPressed: () => setState(() => box.peakSeasons.add(_PeakSeasonDraft())),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.partnerPeakSeasonAdd),
          ),
        ),
      ],
    );
  }

  Widget _peakSeasonCard(
    _RegularProductDraft box,
    _PeakSeasonDraft row,
    int index,
    String Function(GuestRole role) roleName,
    TextStyle labelStyle,
  ) {
    final l10n = AppLocalizations.of(context);
    Widget money(TextEditingController controller, String key) {
      return TextField(
        key: Key(key),
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(color: PlannerPalette.text),
        cursorColor: PlannerPalette.accent,
        decoration: _deco('일반가'),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _FormInk.input),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _peakDateField(
                    keyName: 'partner-peak-start-${box.id}-$index',
                    controller: row.start,
                    label: l10n.partnerPeakSeasonStart,
                    isEnd: false,
                    startDay: null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _peakDateField(
                    keyName: 'partner-peak-end-${box.id}-$index',
                    controller: row.end,
                    label: l10n.partnerPeakSeasonEnd,
                    isEnd: true,
                    startDay: _peakDay(row.start.text),
                  ),
                ),
                IconButton(
                  key: Key('partner-peak-remove-${box.id}-$index'),
                  onPressed: () => setState(() {
                    box.peakSeasons.remove(row);
                    row.dispose();
                  }),
                  icon: const Icon(Icons.close, color: _FormInk.muted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final role in GuestRole.values) ...[
              Text(roleName(role), style: labelStyle),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _labeled(
                      '일반가',
                      money(
                        row.consumer[role]!,
                        'partner-peak-consumer-${box.id}-$index-${role.firestoreValue}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _labeled(
                      l10n.exploreProPrice,
                      TextField(
                        key: Key(
                          'partner-peak-pro-${box.id}-$index-${role.firestoreValue}',
                        ),
                        controller: row.professional[role],
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(color: PlannerPalette.text),
                        cursorColor: PlannerPalette.accent,
                        decoration: _deco(l10n.exploreProPrice),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _peakDateField({
    required String keyName,
    required TextEditingController controller,
    required String label,
    required bool isEnd,
    required DateTime? startDay,
  }) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      key: Key(keyName),
      controller: controller,
      readOnly: true,
      showCursor: false,
      mouseCursor: SystemMouseCursors.click,
      onTap: () => _pickPeakDay(
        controller: controller,
        isEnd: isEnd,
        startDay: startDay,
      ),
      style: const TextStyle(color: PlannerPalette.text),
      cursorColor: PlannerPalette.accent,
      decoration: _deco(label).copyWith(
        hintText: l10n.partnerPeakSeasonPickDate(label),
        hintStyle: const TextStyle(
          color: Color(0xFF8A98A8),
          fontWeight: FontWeight.w600,
        ),
        suffixIcon: IconButton(
          onPressed: () => _pickPeakDay(
            controller: controller,
            isEnd: isEnd,
            startDay: startDay,
          ),
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          color: const Color(0xFF8A98A8),
        ),
      ),
    );
  }

  Future<void> _pickPeakDay({
    required TextEditingController controller,
    required bool isEnd,
    required DateTime? startDay,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final horizon = DateTime(today.year + 3, today.month, today.day);
    final current = _peakDay(controller.text);
    var first = today;
    var last = horizon;
    if (isEnd && startDay != null) {
      first = startDay;
    }
    if (last.isBefore(first)) {
      last = first;
    }
    if (!isEnd && current != null && current.isBefore(first)) {
      first = current;
    }
    if (current != null && current.isAfter(last)) {
      last = current;
    }
    var initial = current ?? first;
    if (initial.isBefore(first)) {
      initial = first;
    }
    if (initial.isAfter(last)) {
      initial = last;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() => controller.text = _peakDisplay(picked));
  }

  Widget _saleRulesBlock(_RegularProductDraft box) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    final lead = box.minLeadDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '예약 가능 요일',
          style: TextStyle(
            color: _FormInk.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var day = 1; day <= 7; day++)
              FilterChip(
                key: Key('partner-regular-weekday-${box.id}-$day'),
                label: Text(labels[day - 1]),
                selected: box.saleWeekdays.contains(day),
                showCheckmark: false,
                selectedColor: _FormInk.chipOn,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: box.saleWeekdays.contains(day)
                      ? Colors.white
                      : _FormInk.ink,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(
                  color: box.saleWeekdays.contains(day)
                      ? _FormInk.chipOn
                      : _FormInk.input,
                ),
                shape: const StadiumBorder(),
                onSelected: (on) => setState(() {
                  if (on) {
                    box.saleWeekdays.add(day);
                  } else {
                    box.saleWeekdays.remove(day);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _labeled(
          '최소 사전 예약',
          DropdownButtonFormField<int>(
          key: Key('partner-regular-lead-${box.id}-$lead'),
          initialValue: lead,
          decoration: _deco('최소 사전 예약'),
          items: [
            if (lead != 0 && lead != 3 && lead != 7)
              DropdownMenuItem(value: lead, child: Text('출발 $lead일 전까지')),
            const DropdownMenuItem(value: 0, child: Text('당일까지')),
            const DropdownMenuItem(value: 3, child: Text('출발 3일 전까지')),
            const DropdownMenuItem(value: 7, child: Text('출발 7일 전까지')),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() => box.minLeadDays = value);
          },
        ),
        ),
        const SizedBox(height: 10),
        const Text(
          '출발 가능 기간',
          style: TextStyle(
            color: _FormInk.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '이 기간에 출발하는 날짜만 손님이 고를 수 있어요.',
          style: TextStyle(color: _FormInk.muted, fontSize: 12, height: 1.35),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _saleBoundField(box, isEnd: false)),
            const SizedBox(width: 8),
            Expanded(child: _saleBoundField(box, isEnd: true)),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          '예약 막을 날짜',
          style: TextStyle(
            color: _FormInk.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final range in box.blockedDates)
              InputChip(
                label: Text('${range.start}–${range.end}'),
                onDeleted: () => setState(() => box.blockedDates.remove(range)),
              ),
            ActionChip(
              key: Key('partner-regular-block-add-${box.id}'),
              label: const Text('+ 날짜 추가'),
              onPressed: () => unawaited(_addBlockedRange(box)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _saleBoundField(_RegularProductDraft box, {required bool isEnd}) {
    final value = isEnd ? box.saleTo : box.saleFrom;
    final label = isEnd ? '종료일' : '시작일';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _FormInk.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: _FormInk.fieldFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _FormInk.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  key: Key(
                    isEnd
                        ? 'partner-regular-sale-to-${box.id}'
                        : 'partner-regular-sale-from-${box.id}',
                  ),
                  onTap: () => unawaited(_pickSaleBound(box, isEnd: isEnd)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: Text(
                      value.isEmpty ? '제한 없음' : value,
                      style: TextStyle(
                        color: value.isEmpty ? _FormInk.muted : _FormInk.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              if (value.isNotEmpty)
                IconButton(
                  key: Key(
                    isEnd
                        ? 'partner-regular-sale-to-clear-${box.id}'
                        : 'partner-regular-sale-from-clear-${box.id}',
                  ),
                  onPressed: () => setState(() {
                    if (isEnd) {
                      box.saleTo = '';
                    } else {
                      box.saleFrom = '';
                    }
                  }),
                  icon: const Icon(Icons.close, color: _FormInk.muted),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickSaleBound(
    _RegularProductDraft box, {
    required bool isEnd,
  }) async {
    final controller = widget.storyController;
    controller?.suspendInput();
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final current = _peakDay(isEnd ? box.saleTo : box.saleFrom);
      final first = DateTime(2020);
      final last = DateTime(2100);
      var initial = current ?? today;
      if (initial.isBefore(first)) {
        initial = first;
      }
      if (initial.isAfter(last)) {
        initial = last;
      }
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: first,
        lastDate: last,
      );
      if (picked == null || !mounted) {
        return;
      }
      final text = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        if (isEnd) {
          box.saleTo = text;
        } else {
          box.saleFrom = text;
        }
      });
    } finally {
      controller?.resumeInput();
    }
  }

  Future<void> _addBlockedRange(_RegularProductDraft box) async {
    final controller = widget.storyController;
    controller?.suspendInput();
    try {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (picked == null || !mounted) {
        return;
      }
      final format = DateFormat('yyyy-MM-dd');
      setState(() {
        box.blockedDates.add(
          SaleBlockedRange(
            start: format.format(picked.start),
            end: format.format(picked.end),
          ),
        );
      });
    } finally {
      controller?.resumeInput();
    }
  }

  Widget _guestTierRow(_RegularProductDraft box, _GuestTierDraft tier) {
    final label = TextField(
      key: Key('partner-regular-tier-label-${tier.id}'),
      controller: tier.label,
      style: const TextStyle(color: PlannerPalette.text),
      cursorColor: PlannerPalette.accent,
      decoration: _deco('유형 이름'),
    );
    final condition = TextField(
      controller: tier.condition,
      style: const TextStyle(color: PlannerPalette.text),
      cursorColor: PlannerPalette.accent,
      decoration: _deco('조건 문구'),
    );
    final price = TextField(
      controller: tier.price,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: PlannerPalette.text),
      cursorColor: PlannerPalette.accent,
      decoration: _deco('가격'),
    );
    final remove = IconButton(
      onPressed: () => setState(() => box.guestTiers.remove(tier)),
      icon: Icon(
        Icons.close,
        color: widget.partnerLabels ? _FormInk.muted : PlannerPalette.textDim,
      ),
    );
    final wide = MediaQuery.sizeOf(context).width >= 720;
    Widget cell(String name, Widget field) =>
        wide ? field : _labeled(name, field);
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: cell('유형', label)),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: cell('손님에게 보이는 조건', condition)),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: cell('가격(원)', price)),
          remove,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [Expanded(child: cell('유형', label)), remove]),
        cell('손님에게 보이는 조건', condition),
        cell('가격(원)', price),
      ],
    );
  }

  Widget _optionsBlock(AppLocalizations l10n, _RegularProductDraft box) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < box.addons.length; i++) ...[
          _addonRow(box, box.addons[i]),
          const SizedBox(height: 8),
        ],
        OutlinedButton(
          key: Key('partner-regular-add-option-${box.id}'),
          onPressed: () => setState(() {
            box.addons.add(_AddonDraft());
          }),
          style: widget.partnerLabels
              ? OutlinedButton.styleFrom(
                  foregroundColor: _FormInk.teal,
                  side: const BorderSide(color: _FormInk.input, width: 1.5),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                )
              : null,
          child: Text(
            widget.partnerLabels
                ? '+ ${l10n.partnerFormAddOption}'
                : l10n.partnerFormAddOption,
            style: TextStyle(
              fontWeight: widget.partnerLabels ? FontWeight.w700 : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _addonRow(_RegularProductDraft box, _AddonDraft addon) {
    return Material(
      color: widget.partnerLabels ? _FormInk.card : PlannerPalette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.partnerLabels ? 10 : 12),
        side: BorderSide(
          color: widget.partnerLabels ? _FormInk.line : PlannerPalette.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _labeled(
                    '옵션 이름',
                    TextField(
                      key: Key('partner-regular-option-name-${addon.id}'),
                      controller: addon.name,
                      style: _ink,
                      cursorColor: _cursor,
                      decoration: _deco('옵션 이름'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => box.addons.remove(addon)),
                  icon: Icon(
                    Icons.close,
                    color: widget.partnerLabels
                        ? _FormInk.muted
                        : PlannerPalette.textDim,
                  ),
                ),
              ],
            ),
            _labeled(
              '소비자가',
              TextField(
                controller: addon.consumer,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: _ink,
                cursorColor: _cursor,
                decoration: _deco('소비자가'),
              ),
            ),
            _labeled(
              '강사 우대가',
              TextField(
                controller: addon.professional,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: _ink,
                cursorColor: _cursor,
                decoration: _deco('강사 우대가'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _includesBlock(AppLocalizations l10n, _RegularProductDraft box) {
    return Column(
      children: [
        _labeled(
          l10n.productFormIncludes,
          TextField(
            key: Key('partner-regular-includes-${box.id}'),
            controller: box.includes,
            minLines: 2,
            maxLines: 4,
            style: _ink,
            cursorColor: _cursor,
            decoration: _deco(l10n.productFormIncludes),
          ),
        ),
        _labeled(
          l10n.productFormExcludes,
          TextField(
            controller: box.excludes,
            minLines: 2,
            maxLines: 4,
            style: _ink,
            cursorColor: _cursor,
            decoration: _deco(l10n.productFormExcludes),
          ),
        ),
      ],
    );
  }

  Widget _savedIndividuals(_RegularProductDraft box) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '저장된 개별 상품',
            style: TextStyle(
              color: PlannerPalette.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final option in box.individuals)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${option.name} · ${_price.format(option.consumerPrice)}원',
                key: Key('partner-regular-individual-${option.id}'),
                style: const TextStyle(color: PlannerPalette.text),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addPhotos(_RegularProductDraft box) async {
    final remaining = GalleryLimits.maxProductPhotos - box.photos.length;
    if (remaining <= 0) {
      return;
    }
    try {
      final photos = await _picker.pickMultiple(max: remaining);
      if (photos.isEmpty || !mounted) {
        return;
      }
      setState(() {
        box.galleryTouched = true;
        for (final photo in photos) {
          if (box.photos.length >= GalleryLimits.maxProductPhotos) {
            break;
          }
          box.photos.add(BookingGalleryItem.local(photo));
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진을 불러오지 못했습니다. 다시 시도해 주세요')),
      );
    }
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

String _peakDisplay(DateTime day) {
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '${day.year}.$month.$date';
}

String _peakIsoText(DateTime day) {
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '${day.year}-$month-$date';
}

DateTime? _peakDay(String raw) {
  return PeakSeason.parseDay(raw.trim().replaceAll('.', '-'));
}

String _peakFieldText(String stored) {
  final day = _peakDay(stored);
  if (day == null) {
    return stored;
  }
  return _peakDisplay(day);
}

String? _peakStored(String shown) {
  final day = _peakDay(shown);
  if (day == null) {
    return null;
  }
  return _peakIsoText(day);
}

class _PeakSeasonDraft {
  _PeakSeasonDraft({
    String startText = '',
    String endText = '',
    Map<GuestRole, String>? consumerText,
    Map<GuestRole, String>? professionalText,
  }) : start = TextEditingController(text: startText),
       end = TextEditingController(text: endText),
       consumer = {
         for (final role in GuestRole.values)
           role: TextEditingController(text: consumerText?[role] ?? ''),
       },
       professional = {
         for (final role in GuestRole.values)
           role: TextEditingController(text: professionalText?[role] ?? ''),
       };

  factory _PeakSeasonDraft.fromSeason(PeakSeason season) {
    String textOf(GuestRole role, bool consumer) {
      for (final rate in season.rates) {
        if (rate.role != role) {
          continue;
        }
        return '${consumer ? rate.consumer : rate.professional}';
      }
      return '';
    }

    return _PeakSeasonDraft(
      startText: _peakFieldText(season.start),
      endText: _peakFieldText(season.end),
      consumerText: {
        for (final role in GuestRole.values) role: textOf(role, true),
      },
      professionalText: {
        for (final role in GuestRole.values) role: textOf(role, false),
      },
    );
  }

  final TextEditingController start;
  final TextEditingController end;
  final Map<GuestRole, TextEditingController> consumer;
  final Map<GuestRole, TextEditingController> professional;

  bool get isBlank {
    if (start.text.trim().isNotEmpty || end.text.trim().isNotEmpty) {
      return false;
    }
    for (final role in GuestRole.values) {
      if (consumer[role]!.text.trim().isNotEmpty ||
          professional[role]!.text.trim().isNotEmpty) {
        return false;
      }
    }
    return true;
  }

  void dispose() {
    start.dispose();
    end.dispose();
    for (final controller in consumer.values) {
      controller.dispose();
    }
    for (final controller in professional.values) {
      controller.dispose();
    }
  }
}

class _RegularProductDraft {
  _RegularProductDraft({
    required this.id,
    required this.source,
    required this.name,
    required this.consumer,
    required this.professional,
    required this.includes,
    required this.excludes,
    required this.addons,
    required this.individuals,
    required this.basePackages,
    required this.photos,
    required this.showOnBooking,
    required this.sourcePrice,
    List<_GuestTierDraft>? guestTiers,
    TextEditingController? singleSupplement,
    TextEditingController? nights,
    Set<int>? saleWeekdays,
    this.minLeadDays = 0,
    this.saleFrom = '',
    this.saleTo = '',
    List<SaleBlockedRange>? blockedDates,
    List<_PeakSeasonDraft>? peakSeasons,
    ProductCategory? category,
    this.difficulty = '',
    this.weatherPolicy = '',
    TextEditingController? diveCount,
    TextEditingController? maxGuests,
    TextEditingController? freeCancelDays,
    List<_ItineraryDraft>? itinerary,
  }) : guestTiers = guestTiers ?? <_GuestTierDraft>[],
       singleSupplement = singleSupplement ?? TextEditingController(),
       nights = nights ?? TextEditingController(),
       saleWeekdays = saleWeekdays ?? {1, 2, 3, 4, 5, 6, 7},
       blockedDates = blockedDates ?? <SaleBlockedRange>[],
       peakSeasons = peakSeasons ?? <_PeakSeasonDraft>[],
       category = category ?? ProductCategory.resortPackage,
       diveCount = diveCount ?? TextEditingController(),
       maxGuests = maxGuests ?? TextEditingController(),
       freeCancelDays = freeCancelDays ?? TextEditingController(),
       itinerary = itinerary ?? <_ItineraryDraft>[];

  factory _RegularProductDraft.fromProduct(ShopProduct product) {
    final addons = <_AddonDraft>[];
    final individuals = <ShopProductOption>[];
    final basePackages = <ShopProductOption>[];
    for (final option in product.options) {
      switch (option.kind) {
        case ProductOptionKind.individual:
          individuals.add(option);
        case ProductOptionKind.basePackage:
          basePackages.add(option);
        case ProductOptionKind.addon:
          addons.add(_AddonDraft.fromOption(option));
      }
    }
    final photos = <BookingGalleryItem>[
      for (final url in product.photoUrls)
        if (url.trim().isNotEmpty) BookingGalleryItem.remote(url),
    ];
    if (photos.isEmpty && product.coverUrl.trim().isNotEmpty) {
      photos.add(BookingGalleryItem.remote(product.coverUrl));
    }
    return _RegularProductDraft(
      id: product.id,
      source: product,
      name: TextEditingController(text: product.name),
      consumer: TextEditingController(
        text: product.consumerPrice > 0 ? '${product.consumerPrice}' : '',
      ),
      professional: TextEditingController(
        text: product.professionalPrice > 0
            ? '${product.professionalPrice}'
            : '',
      ),
      includes: TextEditingController(text: product.includes),
      excludes: TextEditingController(text: product.excludes),
      addons: addons,
      individuals: individuals,
      basePackages: basePackages,
      photos: photos,
      showOnBooking: product.active && product.publishStatus.isPublic,
      sourcePrice: product.consumerPrice,
      guestTiers: [
        for (final tier in product.priceTiers) _GuestTierDraft.fromTier(tier),
      ],
      singleSupplement: TextEditingController(
        text: product.singleSupplement > 0 ? '${product.singleSupplement}' : '',
      ),
      nights: TextEditingController(
        text: product.nights > 0 ? '${product.nights}' : '',
      ),
      saleWeekdays: product.saleWeekdays.isEmpty
          ? {1, 2, 3, 4, 5, 6, 7}
          : {...product.saleWeekdays},
      minLeadDays: product.minLeadDays,
      saleFrom: product.saleFrom == null ? '' : _peakIsoText(product.saleFrom!),
      saleTo: product.saleTo == null ? '' : _peakIsoText(product.saleTo!),
      blockedDates: [...product.blockedDates],
      peakSeasons: [
        for (final season in product.peakSeasons)
          _PeakSeasonDraft.fromSeason(season),
      ],
      category: product.category,
      difficulty: product.difficulty,
      weatherPolicy: product.weatherPolicy,
      diveCount: TextEditingController(
        text: product.diveCount > 0 ? '${product.diveCount}' : '',
      ),
      maxGuests: TextEditingController(
        text: product.maxGuests > 0 ? '${product.maxGuests}' : '',
      ),
      freeCancelDays: TextEditingController(
        text: product.freeCancelDays > 0 ? '${product.freeCancelDays}' : '',
      ),
      itinerary: [
        for (final day in product.itineraryDays)
          _ItineraryDraft(
            dayText: day.day > 0 ? '${day.day}' : '',
            titleText: day.title,
            bodyText: day.body,
          ),
      ],
    );
  }

  factory _RegularProductDraft.empty() {
    return _RegularProductDraft(
      id: 'p-${DateTime.now().microsecondsSinceEpoch}',
      source: null,
      name: TextEditingController(),
      consumer: TextEditingController(),
      professional: TextEditingController(),
      includes: TextEditingController(),
      excludes: TextEditingController(),
      addons: [],
      individuals: const [],
      basePackages: const [],
      photos: [],
      showOnBooking: true,
      sourcePrice: 0,
    );
  }

  final String id;
  final ShopProduct? source;
  final TextEditingController name;
  final TextEditingController consumer;
  final TextEditingController professional;
  final TextEditingController includes;
  final TextEditingController excludes;
  final List<_AddonDraft> addons;
  final List<ShopProductOption> individuals;
  final List<ShopProductOption> basePackages;
  final List<BookingGalleryItem> photos;
  bool showOnBooking;
  bool galleryTouched = false;
  final int sourcePrice;

  /// HTML last given to the editor. Stays put so a later rebuild does not
  /// push a new document into the iframe.
  String storyInitialHtml = '';

  /// Latest editor HTML, including text the user has not saved yet.
  String storyDraftHtml = '';

  /// Last story read from or written to the product document.
  String savedStoryHtml = '';

  bool storyReady = false;
  bool storyFetchFailed = false;
  final List<_GuestTierDraft> guestTiers;
  final TextEditingController singleSupplement;
  final TextEditingController nights;
  final Set<int> saleWeekdays;
  int minLeadDays;
  String saleFrom;
  String saleTo;
  final List<SaleBlockedRange> blockedDates;
  final List<_PeakSeasonDraft> peakSeasons;
  ProductCategory category;
  String difficulty;
  String weatherPolicy;
  final TextEditingController diveCount;
  final TextEditingController maxGuests;
  final TextEditingController freeCancelDays;
  final List<_ItineraryDraft> itinerary;

  /// Partner product form. Other saves leave these keys off the document.
  bool writeGuestPrices = false;

  void seedDefaultGuestTiers() {
    guestTiers.addAll([
      _GuestTierDraft(
        labelText: '비다이버',
        conditionText: '다이빙 제외 · 숙박·식사 포함',
        role: 'nondiver',
      ),
      _GuestTierDraft(
        labelText: '소아',
        conditionText: '만 2–11세 · 보호자 동반',
        role: 'child',
      ),
      _GuestTierDraft(
        labelText: '유아',
        conditionText: '만 2세 미만 · 침대 미사용',
        role: 'infant',
      ),
    ]);
  }

  int get optionCount => addons.length + individuals.length;

  bool get isUntouchedNew =>
      source == null &&
      name.text.trim().isEmpty &&
      (parsePositivePrice(consumer.text) ?? 0) <= 0 &&
      addons.every((addon) => addon.name.text.trim().isEmpty);

  void dispose() {
    name.dispose();
    consumer.dispose();
    professional.dispose();
    includes.dispose();
    excludes.dispose();
    for (final addon in addons) {
      addon.dispose();
    }
    for (final tier in guestTiers) {
      tier.dispose();
    }
    singleSupplement.dispose();
    nights.dispose();
    diveCount.dispose();
    maxGuests.dispose();
    freeCancelDays.dispose();
    for (final day in itinerary) {
      day.dispose();
    }
    for (final season in peakSeasons) {
      season.dispose();
    }
  }

  ShopProduct toProduct(String shopId) {
    final consumerPrice = parsePositivePrice(consumer.text) ?? 0;
    final professionalPrice =
        parsePositivePrice(professional.text) ?? consumerPrice;
    final options = <ShopProductOption>[
      ...basePackages,
      for (final addon in addons)
        if (addon.keep) addon.toOption(),
      ...individuals,
    ];
    final guestPrices = writeGuestPrices ? _guestPriceFields() : null;
    final stayNights = writeGuestPrices ? _stayNights() : null;
    final stayLabel = stayNights != null && stayNights >= 1
        ? '$stayNights박 ${stayNights + 1}일'
        : null;
    final existing = source;
    if (existing == null) {
      return ShopProduct(
        id: id,
        shopId: shopId,
        name: name.text.trim(),
        consumerPrice: consumerPrice,
        professionalPrice: professionalPrice,
        active: showOnBooking,
        includes: includes.text.trim(),
        excludes: excludes.text.trim(),
        options: options,
        publishStatus: ProductPublishStatus.draft,
        priceTiers: guestPrices?.tiers ?? const [],
        singleSupplement: guestPrices?.supplement ?? 0,
        includeGuestPriceFields: writeGuestPrices,
        guestRates: writeGuestPrices ? _guestRates(null) : const [],
        nights: stayNights ?? 0,
        durationLabel: stayLabel ?? '',
        saleWeekdays: writeGuestPrices ? _saleWeekdays() : const [],
        minLeadDays: writeGuestPrices ? minLeadDays : 0,
        blockedDates: writeGuestPrices
            ? List<SaleBlockedRange>.of(blockedDates)
            : const [],
        saleFrom: writeGuestPrices ? _peakDay(saleFrom) : null,
        saleTo: writeGuestPrices ? _peakDay(saleTo) : null,
        peakSeasons: writeGuestPrices ? _storedPeakSeasons() : const [],
        category: writeGuestPrices ? category : ProductCategory.resortPackage,
        difficulty: writeGuestPrices ? difficulty : '',
        maxGuests: writeGuestPrices ? _wholeNumber(maxGuests) : 0,
        itineraryDays: writeGuestPrices ? _itineraryDays() : const [],
        diveCount: writeGuestPrices ? _wholeNumber(diveCount) : 0,
        freeCancelDays: writeGuestPrices ? _wholeNumber(freeCancelDays) : 0,
        weatherPolicy: writeGuestPrices ? weatherPolicy : '',
      );
    }
    return existing.copyWith(
      name: name.text.trim(),
      consumerPrice: consumerPrice,
      professionalPrice: professionalPrice,
      active: showOnBooking,
      includes: includes.text.trim(),
      excludes: excludes.text.trim(),
      options: options,
      priceTiers: guestPrices?.tiers,
      singleSupplement: guestPrices?.supplement,
      includeGuestPriceFields: writeGuestPrices ? true : null,
      guestRates: writeGuestPrices ? _guestRates(existing) : null,
      nights: stayNights,
      durationLabel: stayLabel,
      saleWeekdays: writeGuestPrices ? _saleWeekdays() : null,
      minLeadDays: writeGuestPrices ? minLeadDays : null,
      blockedDates: writeGuestPrices
          ? List<SaleBlockedRange>.of(blockedDates)
          : null,
      saleFrom: writeGuestPrices ? _peakDay(saleFrom) : existing.saleFrom,
      saleTo: writeGuestPrices ? _peakDay(saleTo) : existing.saleTo,
      peakSeasons: writeGuestPrices ? _storedPeakSeasons() : null,
      category: writeGuestPrices ? category : null,
      difficulty: writeGuestPrices ? difficulty : null,
      maxGuests: writeGuestPrices ? _wholeNumber(maxGuests) : null,
      itineraryDays: writeGuestPrices ? _itineraryDays() : null,
      diveCount: writeGuestPrices ? _wholeNumber(diveCount) : null,
      freeCancelDays: writeGuestPrices ? _wholeNumber(freeCancelDays) : null,
      weatherPolicy: writeGuestPrices ? weatherPolicy : null,
    );
  }

  /// Nondiver, child, and infant follow the priced rows. An existing diver
  /// rate stays as it was.
  List<GuestRate> _guestRates(ShopProduct? existing) {
    return [
      for (final rate in existing?.guestRates ?? const <GuestRate>[])
        if (rate.role == GuestRole.diver) rate,
      _rateFor(GuestRole.nondiver),
      _rateFor(GuestRole.child),
      _rateFor(GuestRole.infant),
    ];
  }

  GuestRate _rateFor(GuestRole role) {
    final key = role.firestoreValue;
    for (final tier in guestTiers) {
      if (tier.role != key) {
        continue;
      }
      final price = tier.enteredPrice;
      if (price == null) {
        return GuestRate(role: role, enabled: false);
      }
      return GuestRate(
        role: role,
        enabled: true,
        consumer: price,
        professional: price,
      );
    }
    return GuestRate(role: role, enabled: false);
  }

  /// Blank date rows are dropped. An empty price copies the base rate.
  /// A role that is off stays at 0.
  List<PeakSeason> _storedPeakSeasons() {
    final diverConsumer = parsePositivePrice(consumer.text) ?? 0;
    final diverProfessional =
        parsePositivePrice(professional.text) ?? diverConsumer;
    GuestRate base(GuestRole role) {
      if (role == GuestRole.diver) {
        return GuestRate(
          role: role,
          enabled: true,
          consumer: diverConsumer,
          professional: diverProfessional,
        );
      }
      return _rateFor(role);
    }

    int? typed(String raw) {
      if (raw.trim().isEmpty) {
        return null;
      }
      final value = int.tryParse(raw.trim());
      if (value == null || value < 0) {
        return null;
      }
      return value;
    }

    final seasons = <PeakSeason>[];
    for (final row in peakSeasons) {
      if (row.isBlank) {
        continue;
      }
      final rates = <GuestRate>[];
      for (final role in GuestRole.values) {
        final fallback = base(role);
        if (!fallback.enabled) {
          rates.add(GuestRate(role: role, enabled: false));
          continue;
        }
        rates.add(
          GuestRate(
            role: role,
            enabled: true,
            consumer: typed(row.consumer[role]!.text) ?? fallback.consumer,
            professional:
                typed(row.professional[role]!.text) ?? fallback.professional,
          ),
        );
      }
      seasons.add(
        PeakSeason(
          start: _peakStored(row.start.text) ?? row.start.text.trim(),
          end: _peakStored(row.end.text) ?? row.end.text.trim(),
          rates: rates,
        ),
      );
    }
    return seasons;
  }

  String? peakSeasonBlockReason(AppLocalizations l10n) {
    final seasons = <PeakSeason>[];
    for (final row in peakSeasons) {
      if (row.isBlank) {
        continue;
      }
      final startRaw = row.start.text.trim();
      final endRaw = row.end.text.trim();
      final start = _peakDay(startRaw);
      final end = _peakDay(endRaw);
      if (startRaw.isEmpty || endRaw.isEmpty || start == null || end == null) {
        return l10n.partnerPeakSeasonNeedDates;
      }
      if (end.isBefore(start)) {
        return l10n.partnerPeakSeasonBadRange;
      }
      seasons.add(
        PeakSeason(
          start: _peakStored(startRaw)!,
          end: _peakStored(endRaw)!,
        ),
      );
    }
    if (peakSeasonsOverlap(seasons)) {
      return l10n.partnerPeakSeasonOverlap;
    }
    return null;
  }

  ({List<ProductPriceTier> tiers, int supplement}) _guestPriceFields() {
    return (
      tiers: [
        for (final tier in guestTiers)
          if (tier.enteredPrice != null)
            ProductPriceTier(
              label: tier.label.text.trim(),
              condition: tier.condition.text.trim(),
              price: tier.enteredPrice!,
              role: tier.role,
            ),
      ],
      supplement: parsePositivePrice(singleSupplement.text) ?? 0,
    );
  }

  int _stayNights() => _wholeNumber(nights);

  int _wholeNumber(TextEditingController controller) =>
      int.tryParse(controller.text.trim()) ?? 0;

  List<ItineraryDay> _itineraryDays() {
    final days = <ItineraryDay>[];
    for (final row in itinerary) {
      final day = int.tryParse(row.day.text.trim()) ?? 0;
      final title = row.title.text.trim();
      final body = row.body.text.trim();
      if (day == 0 && title.isEmpty && body.isEmpty) {
        continue;
      }
      days.add(ItineraryDay(day: day, title: title, body: body));
    }
    return days;
  }

  /// Seven selected days are stored empty, which means every weekday.
  List<int> _saleWeekdays() {
    final days = [...saleWeekdays.where((day) => day >= 1 && day <= 7)]
      ..sort();
    if (days.length >= 7) {
      return const [];
    }
    return days;
  }

  List<ShopGallerySlot> gallerySlots() {
    return [
      for (final item in photos)
        if (item.photo != null)
          ShopGallerySlot(
            bytes: item.photo!.bytes,
            fileName: item.photo!.fileName,
            contentType: item.photo!.contentType,
          )
        else if (item.url != null && item.url!.trim().isNotEmpty)
          ShopGallerySlot(url: item.url),
    ];
  }
}

class _ItineraryDraft {
  _ItineraryDraft({
    String? id,
    String dayText = '',
    String titleText = '',
    String bodyText = '',
  }) : id = id ?? 'day-${_nextId()}',
       day = TextEditingController(text: dayText),
       title = TextEditingController(text: titleText),
       body = TextEditingController(text: bodyText);

  static int _seq = 0;

  static int _nextId() => _seq++;

  final String id;
  final TextEditingController day;
  final TextEditingController title;
  final TextEditingController body;

  void dispose() {
    day.dispose();
    title.dispose();
    body.dispose();
  }
}

class _PinnedSteps extends StatefulWidget {
  const _PinnedSteps({
    required this.boxId,
    required this.labels,
    required this.statuses,
    required this.onTap,
    required this.child,
  });

  final String boxId;
  final List<String> labels;
  final List<String> statuses;
  final ValueChanged<int> onTap;
  final Widget child;

  @override
  State<_PinnedSteps> createState() => _PinnedStepsState();
}

class _PinnedStepsState extends State<_PinnedSteps> {
  ScrollPosition? _position;
  final _navKey = GlobalKey();
  var _shift = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (identical(_position, next)) {
      return;
    }
    _position?.removeListener(_sync);
    _position = next;
    _position?.addListener(_sync);
  }

  @override
  void dispose() {
    _position?.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    if (!mounted) {
      return;
    }
    final box = context.findRenderObject();
    final viewport = _position?.context.storageContext.findRenderObject();
    if (box is! RenderBox ||
        !box.hasSize ||
        viewport is! RenderBox ||
        !viewport.hasSize) {
      return;
    }
    final nav = _navKey.currentContext?.findRenderObject();
    final navHeight = nav is RenderBox && nav.hasSize ? nav.size.height : 0.0;
    late final double top;
    try {
      top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    } catch (_) {
      return;
    }
    final room = box.size.height - navHeight;
    final maxShift = room > 0 ? room : 0.0;
    final shift = top < 0 ? (-top).clamp(0.0, maxShift) : 0.0;
    if ((shift - _shift).abs() < 0.5) {
      return;
    }
    setState(() => _shift = shift);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 210,
          child: Transform.translate(
            offset: Offset(0, _shift),
            child: Material(
              key: _navKey,
              color: _FormInk.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: _FormInk.line),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
                child: Column(
                  key: Key('partner-regular-steps-${widget.boxId}'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(8, 0, 8, 10),
                      child: Text(
                        '등록 단계 (8)',
                        style: TextStyle(
                          color: _FormInk.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    for (var i = 0; i < widget.labels.length; i++)
                      InkWell(
                        key: Key('partner-regular-step-${widget.boxId}-$i'),
                        onTap: () => widget.onTap(i),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: _FormInk.line,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    color: _FormInk.ink,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.labels[i],
                                  style: const TextStyle(
                                    color: _FormInk.ink,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                widget.statuses[i],
                                style: const TextStyle(
                                  color: _FormInk.muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(8, 12, 8, 4),
                      child: Text(
                        '모든 상품은 먼저 상시 판매로 열려요. 7번에서 같은배 빈자리를 따로 열 수 있어요.',
                        style: TextStyle(
                          color: _FormInk.muted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: widget.child),
      ],
    );
  }
}

/// Keeps the guest preview beside the step list while the form scrolls.
class _StickyPreviewRail extends StatefulWidget {
  const _StickyPreviewRail({required this.preview, required this.child});

  final Widget preview;
  final Widget child;

  @override
  State<_StickyPreviewRail> createState() => _StickyPreviewRailState();
}

class _StickyPreviewRailState extends State<_StickyPreviewRail> {
  ScrollPosition? _position;
  final _previewKey = GlobalKey();
  var _shift = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (identical(_position, next)) {
      return;
    }
    _position?.removeListener(_sync);
    _position = next;
    _position?.addListener(_sync);
  }

  @override
  void dispose() {
    _position?.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    if (!mounted) {
      return;
    }
    final box = context.findRenderObject();
    final viewport = _position?.context.storageContext.findRenderObject();
    if (box is! RenderBox ||
        !box.hasSize ||
        viewport is! RenderBox ||
        !viewport.hasSize) {
      return;
    }
    final preview = _previewKey.currentContext?.findRenderObject();
    final previewHeight =
        preview is RenderBox && preview.hasSize ? preview.size.height : 0.0;
    late final double top;
    try {
      top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    } catch (_) {
      return;
    }
    final room = box.size.height - previewHeight;
    final maxShift = room > 0 ? room : 0.0;
    final shift = top < 0 ? (-top).clamp(0.0, maxShift) : 0.0;
    if ((shift - _shift).abs() < 0.5) {
      return;
    }
    setState(() => _shift = shift);
  }

  @override
  Widget build(BuildContext context) {
    final panelHeight = MediaQuery.sizeOf(context).height * 0.85;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: widget.child),
        const SizedBox(width: 16),
        SizedBox(
          width: 360,
          child: Transform.translate(
            offset: Offset(0, _shift),
            child: SizedBox(
              key: _previewKey,
              height: panelHeight,
              child: SingleChildScrollView(child: widget.preview),
            ),
          ),
        ),
      ],
    );
  }
}

class _GuestTierDraft {
  _GuestTierDraft({
    String? id,
    String labelText = '',
    String conditionText = '',
    String priceText = '',
    this.role = '',
  }) : id = id ?? 'tier-${_nextId()}',
       label = TextEditingController(text: labelText),
       condition = TextEditingController(text: conditionText),
       price = TextEditingController(text: priceText);

  static int _seq = 0;

  static int _nextId() => _seq++;

  factory _GuestTierDraft.fromTier(ProductPriceTier tier) {
    return _GuestTierDraft(
      labelText: tier.label,
      conditionText: tier.condition,
      priceText: '${tier.price}',
      role: tier.role,
    );
  }

  final String id;
  final String role;
  final TextEditingController label;
  final TextEditingController condition;
  final TextEditingController price;

  /// Empty price is omitted. A typed 0 is stored as 0.
  int? get enteredPrice {
    final digits = price.text.trim();
    if (digits.isEmpty) {
      return null;
    }
    return int.tryParse(digits);
  }

  void dispose() {
    label.dispose();
    condition.dispose();
    price.dispose();
  }
}

class _AddonDraft {
  _AddonDraft({String? id, ShopProductOption? source})
    : id = id ?? source?.id ?? 'opt-${DateTime.now().microsecondsSinceEpoch}',
      source = source,
      name = TextEditingController(text: source?.name ?? ''),
      consumer = TextEditingController(
        text: (source?.consumerPrice ?? 0) > 0 ? '${source!.consumerPrice}' : '',
      ),
      professional = TextEditingController(
        text: (source?.professionalPrice ?? 0) > 0
            ? '${source!.professionalPrice}'
            : '',
      );

  factory _AddonDraft.fromOption(ShopProductOption option) {
    return _AddonDraft(source: option);
  }

  final String id;
  final ShopProductOption? source;
  final TextEditingController name;
  final TextEditingController consumer;
  final TextEditingController professional;

  bool get keep => source != null || name.text.trim().isNotEmpty;

  void dispose() {
    name.dispose();
    consumer.dispose();
    professional.dispose();
  }

  ShopProductOption toOption() {
    final price = parsePositivePrice(consumer.text) ?? 0;
    final pro = parsePositivePrice(professional.text) ?? price;
    final existing = source;
    if (existing == null) {
      return ShopProductOption(
        id: id,
        name: name.text.trim(),
        consumerPrice: price,
        professionalPrice: pro,
        kind: ProductOptionKind.addon,
      );
    }
    return existing.copyWith(
      name: name.text.trim(),
      consumerPrice: price,
      professionalPrice: pro,
      kind: ProductOptionKind.addon,
    );
  }
}
