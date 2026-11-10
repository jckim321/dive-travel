import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/constants/gallery_limits.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/models/story_html.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/widgets/booking_gallery_editor.dart';
import 'package:dive_travel_app/features/admin/presentation/shop_product_box.dart';
import 'package:dive_travel_app/features/admin/presentation/tiptap_story_frame.dart';
import 'package:dive_travel_app/features/admin/presentation/workbench_price_validation.dart';
import 'package:dive_travel_app/features/admin/presentation/planner_palette.dart';
import 'package:dive_travel_app/features/explore/presentation/partner_story_editor.dart';
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
    if (product.openEmptySeats) {
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
          style: const TextStyle(
            color: PlannerPalette.text,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '구매자가 예약할 때 정해요',
          key: Key('partner-regular-date-hint'),
          style: TextStyle(color: PlannerPalette.textDim, height: 1.35),
        ),
        const SizedBox(height: 12),
        for (final box in _boxes) ...[
          _productCard(l10n, box),
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
                  foregroundColor: PlannerPalette.text,
                  minimumSize: const Size.fromHeight(48),
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
                  backgroundColor: PlannerPalette.accent,
                  foregroundColor: PlannerPalette.onAccent,
                  minimumSize: const Size.fromHeight(48),
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
                color: PlannerPalette.textDim,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: PlannerPalette.border),
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
                          color: PlannerPalette.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      key: Key('partner-regular-shop-info-$boxId'),
                      onPressed: _openShopInfo,
                      child: const Text('샵 정보 ›'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '이름·지역·주소·소개는 샵 정보에서 불러와요. 여기서 다시 쓰지 않아요.',
              style: TextStyle(
                color: PlannerPalette.textDim,
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
            color: const Color(0xFFF4F6F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PlannerPalette.border),
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
                          color: PlannerPalette.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '한 번에 1개만 열 수 있어요. 출발이 끝나면 다음 일정을 올릴 수 있어요.',
                        style: TextStyle(
                          color: PlannerPalette.textDim,
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
                  child: const Text('빈자리 만들기 ›'),
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
            const Text(
              '구매자가 예약할 때 정해요',
              style: TextStyle(color: PlannerPalette.textDim, fontSize: 12),
            ),
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
                        style: const TextStyle(
                          color: PlannerPalette.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${_price.format(price)}원',
                      style: const TextStyle(color: PlannerPalette.text),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '옵션 $optionCount',
                      key: Key('partner-regular-option-count-${box.id}'),
                      style: const TextStyle(color: PlannerPalette.textDim),
                    ),
                    Icon(
                      open ? Icons.expand_less : Icons.expand_more,
                      color: PlannerPalette.textDim,
                    ),
                  ],
                ),
              ),
            ),
            if (open) ...[
              if (widget.partnerLabels) ...[
                _shopInfoRow(box.id),
                const SizedBox(height: 8),
              ],
              SwitchListTile.adaptive(
                key: Key('partner-regular-visible-${box.id}'),
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '예약하러 가기에 보이기',
                  style: TextStyle(color: PlannerPalette.text, fontSize: 14),
                ),
                value: box.showOnBooking,
                activeThumbColor: PlannerPalette.accent,
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
                    color: PlannerPalette.textDim,
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
              if (widget.partnerLabels) ...[
                const SizedBox(height: 8),
                _openSeatsRow(box),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _partnerSections(AppLocalizations l10n, _RegularProductDraft box) {
    return Column(
      key: Key('regular-${box.id}-shop-product-box'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionCard(
          boxKey: Key('regular-${box.id}-partner-form-section-price'),
          title: l10n.partnerFormBoxPricePhoto,
          child: _priceBlock(l10n, box),
        ),
        if (_mountsStoryEditor(box))
          _sectionCard(
            boxKey: Key('partner-product-story-${box.id}'),
            title: '상품 소개글',
            child: _storyBody(box),
          ),
        _sectionCard(
          boxKey: Key('regular-${box.id}-partner-form-section-options'),
          title: l10n.partnerFormBoxOptions,
          child: _optionsBlock(l10n, box),
        ),
        _sectionCard(
          boxKey: Key('regular-${box.id}-partner-form-section-includes'),
          title: l10n.partnerFormBoxIncludes,
          child: _includesBlock(l10n, box),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required Key boxKey,
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        key: boxKey,
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
              Text(
                title,
                style: const TextStyle(
                  color: PlannerPalette.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
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

  Widget _priceBlock(AppLocalizations l10n, _RegularProductDraft box) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: Key('partner-regular-name-${box.id}'),
          controller: box.name,
          style: const TextStyle(color: PlannerPalette.text),
          cursorColor: PlannerPalette.accent,
          decoration: _field('상품 이름'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: Key('partner-regular-price-${box.id}'),
                controller: box.consumer,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: PlannerPalette.text),
                cursorColor: PlannerPalette.accent,
                decoration: _field(
                  widget.partnerLabels ? '다이버' : l10n.partnerFormBasePrice,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: box.professional,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: PlannerPalette.text),
                cursorColor: PlannerPalette.accent,
                decoration: _field(l10n.exploreProPrice),
              ),
            ),
          ],
        ),
        if (widget.partnerLabels) ...[
          const SizedBox(height: 10),
          _guestPriceBlock(box),
        ],
        const SizedBox(height: 10),
        BookingGalleryEditor(
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
        ),
      ],
    );
  }

  Widget _guestPriceBlock(_RegularProductDraft box) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final tier in box.guestTiers) ...[
          _guestTierRow(box, tier),
          const SizedBox(height: 8),
        ],
        OutlinedButton(
          key: Key('partner-regular-add-tier-${box.id}'),
          onPressed: () => setState(() {
            box.guestTiers.add(_GuestTierDraft());
          }),
          child: const Text('인원 유형 추가'),
        ),
        const SizedBox(height: 10),
        TextField(
          key: Key('partner-regular-nights-${box.id}'),
          controller: box.nights,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: PlannerPalette.text),
          cursorColor: PlannerPalette.accent,
          decoration: _field('숙박 박 수 (예: 2박 3일이면 2)'),
        ),
        const SizedBox(height: 10),
        TextField(
          key: Key('partner-regular-single-supplement-${box.id}'),
          controller: box.singleSupplement,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: PlannerPalette.text),
          cursorColor: PlannerPalette.accent,
          decoration: _field('1인 1실 추가 요금(1박당)'),
        ),
        const SizedBox(height: 16),
        _saleRulesBlock(box),
      ],
    );
  }

  Widget _saleRulesBlock(_RegularProductDraft box) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    final lead = box.minLeadDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '예약 가능 조건',
          style: TextStyle(
            color: PlannerPalette.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '예약 가능 요일',
          style: TextStyle(color: PlannerPalette.textDim),
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
        DropdownButtonFormField<int>(
          key: Key('partner-regular-lead-${box.id}-$lead'),
          initialValue: lead,
          decoration: _field('최소 사전 예약'),
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
        const SizedBox(height: 10),
        const Text(
          '예약 막을 날짜',
          style: TextStyle(color: PlannerPalette.textDim),
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
      decoration: _field('유형 이름'),
    );
    final condition = TextField(
      controller: tier.condition,
      style: const TextStyle(color: PlannerPalette.text),
      cursorColor: PlannerPalette.accent,
      decoration: _field('조건 문구'),
    );
    final price = TextField(
      controller: tier.price,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: PlannerPalette.text),
      cursorColor: PlannerPalette.accent,
      decoration: _field('가격'),
    );
    final remove = IconButton(
      onPressed: () => setState(() => box.guestTiers.remove(tier)),
      icon: const Icon(Icons.close, color: PlannerPalette.textDim),
    );
    if (MediaQuery.sizeOf(context).width >= 720) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: label),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: condition),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: price),
          remove,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [Expanded(child: label), remove]),
        const SizedBox(height: 8),
        condition,
        const SizedBox(height: 8),
        price,
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
          child: Text(l10n.partnerFormAddOption),
        ),
      ],
    );
  }

  Widget _addonRow(_RegularProductDraft box, _AddonDraft addon) {
    return Material(
      color: PlannerPalette.card,
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
                  child: TextField(
                    key: Key('partner-regular-option-name-${addon.id}'),
                    controller: addon.name,
                    style: const TextStyle(color: PlannerPalette.text),
                    cursorColor: PlannerPalette.accent,
                    decoration: _field('옵션 이름'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => box.addons.remove(addon)),
                  icon: const Icon(Icons.close, color: PlannerPalette.textDim),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: addon.consumer,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: PlannerPalette.text),
              cursorColor: PlannerPalette.accent,
              decoration: _field('소비자가'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: addon.professional,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: PlannerPalette.text),
              cursorColor: PlannerPalette.accent,
              decoration: _field('강사 우대가'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _includesBlock(AppLocalizations l10n, _RegularProductDraft box) {
    return Column(
      children: [
        TextField(
          key: Key('partner-regular-includes-${box.id}'),
          controller: box.includes,
          minLines: 2,
          maxLines: 4,
          style: const TextStyle(color: PlannerPalette.text),
          cursorColor: PlannerPalette.accent,
          decoration: _field(l10n.productFormIncludes),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: box.excludes,
          minLines: 2,
          maxLines: 4,
          style: const TextStyle(color: PlannerPalette.text),
          cursorColor: PlannerPalette.accent,
          decoration: _field(l10n.productFormExcludes),
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
    List<SaleBlockedRange>? blockedDates,
  }) : guestTiers = guestTiers ?? <_GuestTierDraft>[],
       singleSupplement = singleSupplement ?? TextEditingController(),
       nights = nights ?? TextEditingController(),
       saleWeekdays = saleWeekdays ?? {1, 2, 3, 4, 5, 6, 7},
       blockedDates = blockedDates ?? <SaleBlockedRange>[];

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
      blockedDates: [...product.blockedDates],
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
  final List<SaleBlockedRange> blockedDates;

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

  int _stayNights() => int.tryParse(nights.text.trim()) ?? 0;

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
