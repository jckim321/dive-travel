import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/constants/gallery_limits.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/travel_country_master.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/models/shop_resort_info.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/features/admin/presentation/planner_palette.dart';
import 'package:dive_travel_app/features/admin/presentation/tiptap_story_frame.dart';
import 'package:dive_travel_app/core/widgets/booking_gallery_editor.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_country_field.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/explore/presentation/partner_empty_seat_products.dart';
import 'package:dive_travel_app/features/explore/presentation/partner_regular_products.dart';
import 'package:dive_travel_app/features/explore/presentation/partner_story_editor.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_info_sections.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_detail_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

const _kMaxGallery = GalleryLimits.maxProductPhotos;

const _kPartnerBg = Color(0xFFF4F6F9);
const _kPartnerCard = Color(0xFFFFFFFF);
const _kPartnerLine = Color(0xFFDDE3EA);
const _kPartnerInk = Color(0xFF0B1F33);
const _kPartnerMuted = Color(0xFF52606D);
const _kPartnerTeal = Color(0xFF0A6B64);
const _kPartnerNavy = Color(0xFF0B2A3C);
const _kPartnerInput = Color(0xFF8A98A8);

class _DeskPalette {
  const _DeskPalette(this.partnerMode);

  final bool partnerMode;

  Color get bg => partnerMode ? _kPartnerBg : PlannerPalette.bg;
  Color get surface => partnerMode ? _kPartnerCard : PlannerPalette.card;
  Color get primary => partnerMode ? _kPartnerNavy : PlannerPalette.accent;
  Color get onPrimary => partnerMode ? Colors.white : PlannerPalette.onAccent;
  Color get muted => partnerMode ? _kPartnerMuted : PlannerPalette.textDim;
  Color get border => partnerMode ? _kPartnerLine : PlannerPalette.border;
  Color get softFill => partnerMode ? _kPartnerBg : PlannerPalette.bg;
  Color get softBorder => partnerMode ? _kPartnerLine : PlannerPalette.border;
  Color get inputBorder =>
      partnerMode ? _kPartnerInput : PlannerPalette.borderStrong;
  Color get text => partnerMode ? _kPartnerInk : PlannerPalette.text;
  Color get link => partnerMode ? _kPartnerTeal : PlannerPalette.accent;

  TextStyle get fieldStyle => TextStyle(
        color: text,
        fontSize: partnerMode ? 15 : 16,
        fontWeight: FontWeight.w600,
      );
}

class ResortDeskScreen extends StatefulWidget {
  const ResortDeskScreen({
    super.key,
    required this.shopId,
    this.partnerMode = false,
    this.focusProduct,
    this.creatingProduct = false,
  });

  final String shopId;

  /// Partner stack hides the admin sidebar. Both modes use [PlannerPalette].
  final bool partnerMode;

  /// Partner product edit. Ignored unless [partnerMode]. Shop info leaves this null.
  final ShopProduct? focusProduct;

  /// Partner new-product screen. Ignored unless [partnerMode].
  final bool creatingProduct;

  @override
  State<ResortDeskScreen> createState() => _ResortDeskScreenState();
}

class _ResortDeskScreenState extends State<ResortDeskScreen> {
  final _name = TextEditingController();
  final _country = TextEditingController();
  final _location = TextEditingController();
  final _address = TextEditingController();
  final _intro = TextEditingController();
  String? _continent;
  TravelCountry? _pickedCountry;
  final _info = ResortDeskInfoDraft();
  final _mainScroll = ScrollController();
  final _storyController = TipTapStoryFrameController();
  final _sideScroll = ScrollController();
  /// Preserved listing scalars — desk no longer edits product name/prices.
  var _listingProductName = '';
  var _listingConsumerPrice = 0;
  var _listingProfessionalPrice = 0;
  final _photoPicker = const DivePhotoPicker();
  final List<BookingGalleryItem> _slots = [];
  var _seeded = false;
  var _askedStats = false;
  var _nameTouched = false;
  var _countryTouched = false;
  var _regionTouched = false;
  var _galleryTouched = false;
  var _gallerySeedDone = false;
  var _saving = false;
  DiverStore? _store;
  var _storeListening = false;

  /// Read store without registering an InheritedNotifier dependency (avoids
  /// full-scaffold rebuild on every [refreshShopStat] after profile save).
  DiverStore _storeRead(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<DiverStoreScope>();
    assert(scope != null, 'DiverStoreScope가 위젯 트리에 없습니다.');
    return scope!.notifier!;
  }

  void _handleStoreTick() {
    if (!mounted || _store == null) {
      return;
    }
    final store = _store!;
    final live = store.liveStatsFor(widget.shopId);
    final hull = store.listingsOnHull(widget.shopId).firstOrNull ??
        DiveShopCatalog.byId(widget.shopId);
    final placeChanged = _applySavedPlace(live, hull);
    if (!_gallerySeedDone &&
        !_galleryTouched &&
        _slots.isEmpty &&
        live != null) {
      setState(() => _seedGallery(store, live, hull, markDone: true));
      return;
    }
    if (placeChanged) {
      setState(() {});
    }
  }

  /// Fills shop name, country, and region once the saved shop is available.
  /// A field the user already edited stays as they left it.
  bool _applySavedPlace(ShopLiveStats? live, DiveShop? hull) {
    String saved(String? primary, String? fallback) {
      final first = (primary ?? '').trim();
      if (first.isNotEmpty) {
        return first;
      }
      final second = (fallback ?? '').trim();
      if (second.isEmpty || second == widget.shopId) {
        return '';
      }
      return second;
    }

    var changed = false;
    if (!_nameTouched && _name.text.trim().isEmpty) {
      final name = saved(live?.name, hull?.name);
      if (name.isNotEmpty) {
        _name.text = name;
        changed = true;
      }
    }
    if (!_countryTouched && _country.text.trim().isEmpty) {
      final country = saved(live?.country, hull?.country);
      if (country.isNotEmpty) {
        _country.text = country;
        _pickedCountry = TravelCountryMaster.match(country);
        changed = true;
      }
    }
    if (!_regionTouched && _location.text.trim().isEmpty) {
      final region = saved(live?.location, hull?.location);
      if (region.isNotEmpty) {
        _location.text = region;
        changed = true;
      }
    }
    if ((_continent ?? '').trim().isEmpty) {
      final continent =
          (_pickedCountry?.regionId ?? live?.continent ?? hull?.continent)
              ?.trim();
      if (continent != null && continent.isNotEmpty) {
        _continent = continent;
      }
    }
    return changed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = _storeRead(context);
    _store = store;
    if (!_storeListening) {
      _storeListening = true;
      store.addListener(_handleStoreTick);
    }
    if (!_askedStats) {
      _askedStats = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(store.ensureShopStatsLoaded());
        }
      });
    }
    if (_seeded) {
      return;
    }
    _seeded = true;
    final hull = store.listingsOnHull(widget.shopId).firstOrNull ??
        DiveShopCatalog.byId(widget.shopId);
    final live = store.liveStatsFor(widget.shopId);
    _applySavedPlace(live, hull);
    _address.text = live?.address ?? hull?.address ?? '';
    _intro.text = live?.intro ?? hull?.intro ?? '';
    _listingProductName = live?.productName ?? hull?.productName ?? '';
    _listingConsumerPrice = live?.consumerPrice ?? hull?.consumerPrice ?? 0;
    _listingProfessionalPrice =
        live?.professionalPrice ?? hull?.professionalPrice ?? 0;
    final amenitySource = (live?.amenities.isNotEmpty ?? false)
        ? live!.amenities
        : (hull?.amenities ?? const <String>[]);
    _info.seed(
      mapUrl: live?.mapUrl ?? '',
      nearestHub: live?.nearestHub ?? '',
      featureBlurb: live?.featureBlurb ?? '',
      localContact: live?.localContact ?? '',
      checkIn: live?.checkIn ?? '',
      checkOut: live?.checkOut ?? '',
      businessHours: live?.businessHours ?? '',
      amenities: amenitySource,
      featureTags: live?.featureTags ?? const [],
      accessRoutes: live?.accessRoutes ?? const [],
      nearbySpots: live?.nearbySpots ?? const [],
    );
    _seedGallery(store, live, hull);
  }

  void _seedGallery(
    DiverStore store,
    ShopLiveStats? live,
    DiveShop? hull, {
    bool markDone = false,
  }) {
    if (_galleryTouched || _slots.isNotEmpty) {
      if (markDone) {
        _gallerySeedDone = true;
      }
      return;
    }
    final urls = live?.displayGallery ??
        (hull == null ? const <String>[] : hull.displayGallery);
    final localBytes = store.galleryBytesFor(widget.shopId);
    if (localBytes.isNotEmpty && urls.isEmpty) {
      for (final bytes in localBytes) {
        _slots.add(
          BookingGalleryItem.local(
            PickedPhoto(
              bytes: bytes,
              fileName: 'gallery.jpg',
              contentType: 'image/jpeg',
            ),
          ),
        );
      }
    } else {
      for (final url in urls) {
        if (url.isEmpty || url.startsWith('memory://')) {
          continue;
        }
        _slots.add(BookingGalleryItem.remote(url));
      }
      final coverBytes = store.coverBytesFor(widget.shopId);
      if (_slots.isEmpty && coverBytes != null && coverBytes.isNotEmpty) {
        _slots.add(
          BookingGalleryItem.local(
            PickedPhoto(
              bytes: coverBytes,
              fileName: 'cover.jpg',
              contentType: 'image/jpeg',
            ),
          ),
        );
      }
    }
    if (markDone || _slots.isNotEmpty || live != null) {
      _gallerySeedDone = true;
    }
  }

  @override
  void dispose() {
    if (_storeListening) {
      _store?.removeListener(_handleStoreTick);
      _storeListening = false;
    }
    _mainScroll.dispose();
    _sideScroll.dispose();
    _name.dispose();
    _country.dispose();
    _location.dispose();
    _address.dispose();
    _intro.dispose();
    _info.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final remaining = _kMaxGallery - _slots.length;
    if (remaining <= 0) {
      return;
    }
    try {
      final photos = await _photoPicker.pickMultiple(max: remaining);
      if (photos.isEmpty || !mounted) {
        return;
      }
      setState(() {
        _galleryTouched = true;
        for (final photo in photos) {
          if (_slots.length >= _kMaxGallery) {
            break;
          }
          _slots.add(BookingGalleryItem.local(photo));
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

  Future<void> _useTestPhoto() async {
    if (_slots.length >= _kMaxGallery) {
      return;
    }
    final data = await rootBundle.load('assets/images/test_dive_photo.png');
    if (!mounted) {
      return;
    }
    setState(() {
      _galleryTouched = true;
      _slots.add(
        BookingGalleryItem.local(
          PickedPhoto(
            bytes: data.buffer.asUint8List(),
            fileName: 'test_dive_photo.png',
            contentType: 'image/png',
          ),
        ),
      );
    });
  }

  void _removeAt(int index) {
    setState(() {
      _galleryTouched = true;
      _slots.removeAt(index);
    });
  }

  void _makeCover(int index) {
    if (index <= 0 || index >= _slots.length) {
      return;
    }
    setState(() {
      _galleryTouched = true;
      final item = _slots.removeAt(index);
      _slots.insert(0, item);
    });
  }

  Future<void> _saveProfile() async {
    if (_saving) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.partnerShopName} *')),
      );
      return;
    }

    setState(() => _saving = true);
    final store = _store ?? _storeRead(context);
    final typedCountry = _country.text.trim();
    final matched = TravelCountryMaster.match(typedCountry);
    final savedCountry = matched?.name ?? typedCountry;
    final region = matched?.regionId ?? '';
    _pickedCountry = matched;
    _continent = region.isEmpty ? null : region;
    if (matched != null && typedCountry != matched.name) {
      _country.text = matched.name;
    }
    try {
      final probe = await store.saveShopProfile(
        shopId: widget.shopId,
        name: name,
        location: _location.text,
        country: savedCountry,
        continent: region,
        productName: _listingProductName,
        consumerPrice: _listingConsumerPrice,
        professionalPrice: _listingProfessionalPrice,
        intro: _intro.text,
        address: _address.text,
        amenities: [
          for (final item in _info.amenities.take(kMaxAmenities))
            if (item.trim().isNotEmpty) clampShort(item),
        ],
        mapUrl: null,
        nearestHub: clampShort(_info.nearestHub.text),
        accessRoutes: _info.builtRoutes(),
        featureBlurb: clampShort(_info.featureBlurb.text, kMaxShortLine * 2),
        featureTags: [
          for (final tag in _info.featureTags.take(kMaxFeatureTags))
            clampShort(tag),
        ],
        nearbySpots: _info.builtSpots(),
        localContact: clampShort(_info.localContact.text),
        checkIn: clampShort(_info.checkIn.text),
        checkOut: clampShort(_info.checkOut.text),
        businessHours: clampShort(_info.businessHours.text),
        // Only rewrite gallery/cover when the user edited photos. An empty
        // _slots from a race before live stats loaded used to wipe cover_url.
        gallery: _galleryTouched
            ? [
                for (final slot in _slots)
                  ShopGallerySlot(
                    url: slot.url,
                    bytes: slot.photo?.bytes,
                    fileName: slot.photo?.fileName,
                    contentType: slot.photo?.contentType,
                  ),
              ]
            : null,
        removeCover: _galleryTouched && _slots.isEmpty,
      );
      if (!mounted) {
        return;
      }
      // Unblock UI as soon as the write + local patch finish.
      setState(() => _saving = false);
      // Controllers already hold saved values; local store patch ran in save.
      final showTiming = widget.partnerMode
          ? store.stats.isAdmin
          : _canSeeSaveProbe(store);
      if (showTiming) {
        // TODO(a1-desk-save-timing): remove owner timing snackbar after probe.
        final write = probe.write;
        final read = await probe.readFuture;
        if (!mounted) {
          return;
        }
        final total = write + read;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '쓰기 ${_formatSaveSeconds(write)}초 / '
              '읽기 ${_formatSaveSeconds(read)}초 / '
              '전체 ${_formatSaveSeconds(total)}초',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      } else {
        unawaited(probe.readFuture);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.partnerMode ? '샵 정보를 저장했습니다' : l10n.exploreSaveOk,
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      final raw = '$error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            raw.contains('INVALID_MAP_URL')
                ? '구글·네이버·카카오 지도 https 링크만 저장할 수 있어요.'
                : raw,
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted && _saving) {
        setState(() => _saving = false);
      }
    }
  }

  /// Partner shop info is the default partner screen. Product entry sets the rest.
  bool get _partnerProductOnly =>
      widget.partnerMode &&
      (widget.creatingProduct || widget.focusProduct != null);

  bool get _partnerShopOnly => widget.partnerMode && !_partnerProductOnly;

  /// Admin-only temporary save probe.
  bool _canSeeSaveProbe(DiverStore store) {
    final s = store.stats;
    return s.isAdmin ||
        (s.isBusiness && s.ownedShopId == widget.shopId);
  }

  // TODO(a1-desk-save-timing): remove with owner timing snackbar.
  static String _formatSaveSeconds(Duration d) =>
      (d.inMilliseconds / 1000).toStringAsFixed(1);

  Future<void> _openMapSearch() async {
    final query = _address.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주소를 입력한 뒤 지도 검색을 누르세요.')),
      );
      return;
    }
    final uri = googleMapsSearchUri(query);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _pauseStoryEditor(Future<void> Function() action) {
    return pausePartnerStoryInput(_storyController, action);
  }

  void _openPreview() {
    if (!_partnerProductOnly) {
      openResortDetail(context, widget.shopId);
      return;
    }
    unawaited(_pauseStoryEditor(_openPartnerPreviewSheet));
  }

  /// Same sheet as [openResortDetail]. Awaited so the story iframe stays
  /// paused until the preview closes. The shared helper does not return
  /// that future.
  Future<void> _openPartnerPreviewSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height;
        return SizedBox(
          height: height * 0.94,
          child: ResortDetailScreen(hullId: widget.shopId, asSheet: true),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = _DeskPalette(widget.partnerMode);

    final scaffold = Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.surface,
        foregroundColor: palette.text,
        surfaceTintColor: Colors.transparent,
        leading: widget.partnerMode
            ? IconButton(
                key: const Key('partner-back'),
                tooltip: l10n.partnerExit,
                icon: Icon(Icons.arrow_back, color: palette.text),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(
          _partnerShopOnly
              ? '샵 정보'
              : _partnerProductOnly
                  ? (widget.creatingProduct ? '상품 등록' : '상품 수정')
                  : l10n.exploreEditResort,
        ),
        actions: [
          TextButton.icon(
            onPressed: _openPreview,
            icon: Icon(
              Icons.visibility_outlined,
              size: 18,
              color: palette.link,
            ),
            label: Text(
              '미리보기',
              style: TextStyle(
                color: palette.link,
              ),
            ),
          ),
          if (!widget.partnerMode) ...[
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                key: const Key('resort-save'),
                onPressed: _saving ? null : _saveProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: palette.onPrimary,
                  minimumSize: const Size(88, 40),
                ),
                child: Text(_saving ? l10n.exploreSaving : l10n.partnerSave),
              ),
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final main = _DeskMainColumn(
                palette: palette,
                name: _name,
                onNameEdited: () => _nameTouched = true,
                country: _country,
                countryField: TravelCountryField(
                  controller: _country,
                  fieldKey: const Key('resort-country-field'),
                  picked: _pickedCountry,
                  style: palette.fieldStyle,
                  cursorColor: palette.link,
                  decoration: _deskInputDecoration(
                    palette: palette,
                    label: l10n.productFormCuratedCountry,
                    required: true,
                  ),
                  onEdited: () => _countryTouched = true,
                  onPicked: (country) {
                    _countryTouched = true;
                    setState(() {
                      _pickedCountry = country;
                      _continent = country.regionId;
                    });
                  },
                  onCustom: () {
                    _countryTouched = true;
                    setState(() => _pickedCountry = null);
                  },
                  showAssignment: false,
                ),
                location: _location,
                onRegionEdited: () => _regionTouched = true,
                address: _address,
                intro: _intro,
                info: _info,
                onInfoChanged: () => setState(() {}),
                onMapSearch: () => unawaited(_openMapSearch()),
                onTempSave: _saving ? null : () => unawaited(_saveProfile()),
                saving: _saving,
                slots: _slots,
                onAddPhotos: _addPhotos,
                onTestPhoto: _useTestPhoto,
                onRemovePhoto: _removeAt,
                onMakeCover: _makeCover,
                shopId: widget.shopId,
                showShop: !_partnerProductOnly,
                showShopActions: !_partnerShopOnly,
                showProducts: !_partnerShopOnly,
                partnerProductLabels: _partnerProductOnly,
                focusProductId: _partnerProductOnly
                    ? widget.focusProduct?.id
                    : null,
                creatingProduct: _partnerProductOnly && widget.creatingProduct,
                storyController:
                    _partnerProductOnly ? _storyController : null,
                pauseEditorInput:
                    _partnerProductOnly ? _pauseStoryEditor : null,
              );
              final side = _DeskStickySidebar(
                palette: palette,
                saving: _saving,
                onSave: _saveProfile,
                onPreview: _openPreview,
              );
              if (widget.partnerMode) {
                return ListView(
                  key: const Key('resort-desk'),
                  controller: _mainScroll,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [main],
                );
              }
              if (!wide) {
                return ListView(
                  key: const Key('resort-desk'),
                  controller: _mainScroll,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    side,
                    const SizedBox(height: 16),
                    main,
                  ],
                );
              }
              return Row(
                key: const Key('resort-desk'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: SingleChildScrollView(
                      controller: _mainScroll,
                      padding: const EdgeInsets.fromLTRB(20, 20, 12, 40),
                      child: main,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      controller: _sideScroll,
                      padding: const EdgeInsets.fromLTRB(8, 20, 20, 40),
                      child: side,
                    ),
                  ),
                ],
              );
            },
          ),
          if (_saving) ...[
            const ModalBarrier(
              dismissible: false,
              color: Color(0x66000000),
            ),
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: palette.primary),
                      const SizedBox(height: 16),
                      Text(
                        l10n.exploreSaving,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: palette.text,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: _partnerShopOnly
          ? Material(
              color: palette.bg,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: FilledButton(
                    key: const Key('partner-resort-save'),
                    onPressed: _saving ? null : _saveProfile,
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: palette.onPrimary,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _saving ? l10n.exploreSaving : l10n.partnerSave,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );

    return Theme(
      data: widget.partnerMode ? _partnerDeskTheme : PlannerPalette.theme,
      child: scaffold,
    );
  }
}

ThemeData get _partnerDeskTheme {
  final base = PlannerPalette.theme;
  const ink = _kPartnerInk;
  const teal = _kPartnerTeal;
  return base.copyWith(
    scaffoldBackgroundColor: _kPartnerBg,
    colorScheme: base.colorScheme.copyWith(
      primary: teal,
      onPrimary: Colors.white,
      surface: _kPartnerCard,
      onSurface: ink,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF0A7C74),
      checkmarkColor: Colors.white,
      side: const BorderSide(color: _kPartnerInput),
      labelStyle: const TextStyle(
        color: ink,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
  );
}

InputDecoration _deskInputDecoration({
  required _DeskPalette palette,
  required String label,
  String? hint,
  bool required = false,
}) {
  final radius = palette.partnerMode ? 10.0 : 4.0;
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: BorderSide(color: palette.inputBorder),
  );
  final labelColor = palette.partnerMode ? palette.muted : PlannerPalette.textDim;
  return InputDecoration(
    label: required
        ? _RequiredLabel(label, color: labelColor)
        : Text(
            label,
            style: TextStyle(color: labelColor, fontWeight: FontWeight.w600),
          ),
    hintText: hint,
    labelStyle: TextStyle(
      color: labelColor,
      fontWeight: FontWeight.w600,
    ),
    hintStyle: TextStyle(color: palette.muted),
    filled: true,
    fillColor: palette.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(
        color: palette.partnerMode ? palette.link : palette.primary,
        width: 1.6,
      ),
    ),
  );
}

class _RequiredLabel extends StatelessWidget {
  const _RequiredLabel(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
        children: [
          TextSpan(text: text),
          const TextSpan(
            text: ' *',
            style: TextStyle(
              color: Color(0xFFB42318),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeskStickySidebar extends StatelessWidget {
  const _DeskStickySidebar({
    required this.palette,
    required this.saving,
    required this.onSave,
    required this.onPreview,
  });

  final _DeskPalette palette;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
        boxShadow: palette.partnerMode
            ? const []
            : const [
                BoxShadow(
                  color: Color(0x0F0B1F33),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '게시 설정',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: saving ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: palette.onPrimary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              icon: const Icon(Icons.save_outlined, size: 18),
              label: Text(saving ? l10n.exploreSaving : l10n.partnerSave),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onPreview,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: palette.primary,
                side: BorderSide(color: palette.inputBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('미리보기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeskMainColumn extends StatelessWidget {
  const _DeskMainColumn({
    required this.palette,
    required this.name,
    required this.onNameEdited,
    required this.country,
    required this.countryField,
    required this.location,
    required this.onRegionEdited,
    required this.address,
    required this.intro,
    required this.info,
    required this.onInfoChanged,
    required this.onMapSearch,
    required this.onTempSave,
    required this.saving,
    required this.slots,
    required this.onAddPhotos,
    required this.onTestPhoto,
    required this.onRemovePhoto,
    required this.onMakeCover,
    required this.shopId,
    required this.showShop,
    required this.showShopActions,
    required this.showProducts,
    required this.partnerProductLabels,
    required this.creatingProduct,
    this.focusProductId,
    this.storyController,
    this.pauseEditorInput,
  });

  final _DeskPalette palette;
  final TextEditingController name;
  final VoidCallback onNameEdited;
  final TextEditingController country;
  final Widget countryField;
  final TextEditingController location;
  final VoidCallback onRegionEdited;
  final TextEditingController address;
  final TextEditingController intro;
  final ResortDeskInfoDraft info;
  final VoidCallback onInfoChanged;
  final VoidCallback onMapSearch;
  final VoidCallback? onTempSave;
  final bool saving;
  final List<BookingGalleryItem> slots;
  final VoidCallback onAddPhotos;
  final VoidCallback onTestPhoto;
  final ValueChanged<int> onRemovePhoto;
  final ValueChanged<int> onMakeCover;
  final String shopId;
  final bool showShop;
  final bool showShopActions;
  final bool showProducts;
  final bool partnerProductLabels;
  final bool creatingProduct;
  final String? focusProductId;
  final TipTapStoryFrameController? storyController;
  final Future<void> Function(Future<void> Function() action)? pauseEditorInput;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showShop)
        PartnerResortInfoForm(
            fieldStyle: palette.fieldStyle,
            name: name,
            onNameEdited: onNameEdited,
            countryField: countryField,
            country: country,
            location: location,
            onRegionEdited: onRegionEdited,
            address: address,
            onMapSearch: onMapSearch,
            intro: intro,
            info: info,
            onInfoChanged: onInfoChanged,
            onCoverTap: onAddPhotos,
            slots: slots,
            photos: RepaintBoundary(
              child: BookingGalleryEditor(
                items: slots,
                onAdd: onAddPhotos,
                onTest: palette.partnerMode &&
                        !DiverStoreScope.of(context).stats.isAdmin
                    ? null
                    : onTestPhoto,
                onRemove: onRemovePhoto,
                onMakeCover: onMakeCover,
                maxItems: _kMaxGallery,
                fieldKey: const Key('resort-cover-field'),
                attachKey: const Key('resort-cover-field-attach'),
                testKey: const Key('resort-cover-field-test'),
              ),
            ),
            saving: saving,
            onTempSave: onTempSave,
            onSave: onTempSave,
            showActions: showShopActions,
            partnerChrome: palette.partnerMode,
          ),
        if (!palette.partnerMode) ...[
          const SizedBox(height: 16),
          ResortDeskInfoSections(draft: info, onChanged: onInfoChanged),
        ],
        if (showProducts) ...[
          const SizedBox(height: 16),
          PartnerRegularProducts(
            shopId: shopId,
            partnerLabels: partnerProductLabels,
            onlyProductId: focusProductId,
            singleNew: creatingProduct,
            storyController: storyController,
          ),
          if (!partnerProductLabels) ...[
            const SizedBox(height: 16),
            PartnerEmptySeatProducts(
              shopId: shopId,
              partnerLabels: partnerProductLabels,
              onlyProductId: focusProductId,
              singleNew: creatingProduct,
              pauseEditorInput: pauseEditorInput,
            ),
          ],
        ],
      ],
    );
  }
}

class PartnerProductFormScreen extends StatelessWidget {
  const PartnerProductFormScreen({
    super.key,
    required this.shopId,
    this.existing,
  });

  final String shopId;
  final ShopProduct? existing;

  @override
  Widget build(BuildContext context) {
    return TravelProductRegistrationScreen(
      lockedShopId: shopId,
      partnerMode: true,
      existing: existing,
      startEditing: existing != null,
    );
  }
}
