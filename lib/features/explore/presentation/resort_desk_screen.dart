import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/constants/gallery_limits.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/models/shop_resort_info.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/booking_gallery_editor.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_products_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_info_sections.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_detail_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

const _kMaxGallery = GalleryLimits.maxProductPhotos;

class ResortDeskScreen extends StatefulWidget {
  const ResortDeskScreen({super.key, required this.shopId});

  final String shopId;

  @override
  State<ResortDeskScreen> createState() => _ResortDeskScreenState();
}

class _ResortDeskScreenState extends State<ResortDeskScreen> {
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _address = TextEditingController();
  final _intro = TextEditingController();
  final _info = ResortDeskInfoDraft();
  final _mainScroll = ScrollController();
  final _sideScroll = ScrollController();
  /// Preserved listing scalars — desk no longer edits product name/prices.
  var _listingProductName = '';
  var _listingConsumerPrice = 0;
  var _listingProfessionalPrice = 0;
  final _photoPicker = const DivePhotoPicker();
  final List<BookingGalleryItem> _slots = [];
  var _seeded = false;
  var _galleryTouched = false;
  var _gallerySeedDone = false;
  var _saving = false;
  DiverStore? _store;
  var _storeListening = false;
  /// Cached primary product for the read-only options table.
  ShopProduct? _cachedPrimary;
  int _optionsSig = 0;

  /// Read store without registering an InheritedNotifier dependency (avoids
  /// full-scaffold rebuild on every [refreshShopStat] after profile save).
  DiverStore _storeRead(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<DiverStoreScope>();
    assert(scope != null, 'DiverStoreScope가 위젯 트리에 없습니다.');
    return scope!.notifier!;
  }

  static int _optionsSignature(ShopProduct product) {
    return Object.hashAll([
      product.id,
      product.name,
      product.consumerPrice,
      product.professionalPrice,
      for (final option in product.options)
        Object.hash(
          option.id,
          option.name,
          option.description,
          option.consumerPrice,
          option.professionalPrice,
        ),
    ]);
  }

  void _handleStoreTick() {
    if (!mounted || _store == null) {
      return;
    }
    final store = _store!;
    final live = store.liveStatsFor(widget.shopId);
    final hull = store.listingsOnHull(widget.shopId).firstOrNull ??
        DiveShopCatalog.byId(widget.shopId);
    if (!_gallerySeedDone &&
        !_galleryTouched &&
        _slots.isEmpty &&
        live != null) {
      setState(() => _seedGallery(store, live, hull, markDone: true));
      return;
    }
    final primary = _primaryProduct(live);
    final sig = _optionsSignature(primary);
    if (sig != _optionsSig || _cachedPrimary == null) {
      setState(() {
        _optionsSig = sig;
        _cachedPrimary = primary;
      });
    }
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
    if (_seeded) {
      return;
    }
    _seeded = true;
    final hull = store.listingsOnHull(widget.shopId).firstOrNull ??
        DiveShopCatalog.byId(widget.shopId);
    final live = store.liveStatsFor(widget.shopId);
    _name.text = live?.name ?? hull?.name ?? '';
    _location.text = live?.location ?? hull?.location ?? '';
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
    _cachedPrimary = _primaryProduct(live);
    _optionsSig = _optionsSignature(_cachedPrimary!);
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
        SnackBar(content: Text('사진 선택 실패: $error')),
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

    final mapError = validateShopMapUrl(_info.mapUrl.text);
    if (mapError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mapError == 'map_url_https_only'
                ? '지도 링크는 https로 시작하는 주소만 저장할 수 있어요.'
                : mapError == 'map_url_domain'
                    ? '구글·네이버·카카오 지도 링크만 저장할 수 있어요.'
                    : '지도 링크 형식을 확인해 주세요.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final store = _store ?? _storeRead(context);
    try {
      final probe = await store.saveShopProfile(
        shopId: widget.shopId,
        name: name,
        location: _location.text,
        productName: _listingProductName,
        consumerPrice: _listingConsumerPrice,
        professionalPrice: _listingProfessionalPrice,
        intro: _intro.text,
        address: _address.text,
        amenities: [
          for (final item in _info.amenities.take(kMaxAmenities))
            if (item.trim().isNotEmpty) clampShort(item),
        ],
        mapUrl: _info.mapUrl.text.trim(),
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
      if (_canSeeSaveProbe(store)) {
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
          SnackBar(content: Text(l10n.exploreSaveOk)),
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

  /// Owner / admin (incl. DevRoles overlay) only — for temporary save probe.
  bool _canSeeSaveProbe(DiverStore store) {
    final s = store.stats;
    return s.isAdmin ||
        (s.isBusiness && s.ownedShopId == widget.shopId);
  }

  // TODO(a1-desk-save-timing): remove with owner timing snackbar.
  static String _formatSaveSeconds(Duration d) =>
      (d.inMilliseconds / 1000).toStringAsFixed(1);

  void _openPreview() => openResortDetail(context, widget.shopId);

  void _openProductManagement() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AdminProductsScreen(partnerMode: true),
      ),
    );
  }

  ShopProduct _primaryProduct(ShopLiveStats? live) {
    final products = live?.products ?? const <ShopProduct>[];
    if (products.isNotEmpty) {
      return products.first;
    }
    final fallbackName = _listingProductName.trim().isNotEmpty
        ? _listingProductName.trim()
        : (_name.text.trim().isEmpty ? '기본 상품' : _name.text.trim());
    return ShopProduct(
      id: 'p-${widget.shopId}-default',
      shopId: widget.shopId,
      name: fallbackName,
      consumerPrice: _listingConsumerPrice,
      professionalPrice: _listingProfessionalPrice,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = _cachedPrimary ??
        _primaryProduct((_store ?? _storeRead(context)).liveStatsFor(widget.shopId));

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.exploreEditResort),
        actions: [
          TextButton.icon(
            onPressed: _openPreview,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('미리보기'),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              key: const Key('resort-save'),
              onPressed: _saving ? null : _saveProfile,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.navy,
                minimumSize: const Size(88, 40),
              ),
              child: Text(_saving ? l10n.exploreSaving : l10n.partnerSave),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final main = _DeskMainColumn(
                hint: l10n.exploreDeskHint,
                name: _name,
                location: _location,
                address: _address,
                intro: _intro,
                info: _info,
                onInfoChanged: () => setState(() {}),
                slots: _slots,
                onAddPhotos: _addPhotos,
                onTestPhoto: _useTestPhoto,
                onRemovePhoto: _removeAt,
                onMakeCover: _makeCover,
                primaryProduct: primary,
                onOpenProductManagement: _openProductManagement,
              );
              final side = _DeskStickySidebar(
                saving: _saving,
                onSave: _saveProfile,
                onPreview: _openPreview,
              );
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
                  color: Colors.white,
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
                      const CircularProgressIndicator(color: AppTheme.navy),
                      const SizedBox(height: 16),
                      Text(
                        l10n.exploreSaving,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
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
    );
  }
}

InputDecoration _deskInputDecoration({
  required String label,
  String? hint,
  bool required = false,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(4),
    borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
  );
  return InputDecoration(
    label: required ? _RequiredLabel(label) : Text(label),
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: AppTheme.navy, width: 1.6),
    ),
  );
}

class _RequiredLabel extends StatelessWidget {
  const _RequiredLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
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
    required this.saving,
    required this.onSave,
    required this.onPreview,
  });

  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E7E7)),
        boxShadow: const [
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
                backgroundColor: AppTheme.navy,
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
                foregroundColor: AppTheme.navy,
                side: const BorderSide(color: Color(0xFFBDBDBD)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('미리보기'),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text(
              '상품 가격',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '가격과 옵션은 상품 관리에서 수정하세요. 이 화면은 리조트 소개만 저장합니다.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.muted,
                    height: 1.35,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeskMainColumn extends StatelessWidget {
  const _DeskMainColumn({
    required this.hint,
    required this.name,
    required this.location,
    required this.address,
    required this.intro,
    required this.info,
    required this.onInfoChanged,
    required this.slots,
    required this.onAddPhotos,
    required this.onTestPhoto,
    required this.onRemovePhoto,
    required this.onMakeCover,
    required this.primaryProduct,
    required this.onOpenProductManagement,
  });

  final String hint;
  final TextEditingController name;
  final TextEditingController location;
  final TextEditingController address;
  final TextEditingController intro;
  final ResortDeskInfoDraft info;
  final VoidCallback onInfoChanged;
  final List<BookingGalleryItem> slots;
  final VoidCallback onAddPhotos;
  final VoidCallback onTestPhoto;
  final ValueChanged<int> onRemovePhoto;
  final ValueChanged<int> onMakeCover;
  final ShopProduct primaryProduct;
  final VoidCallback onOpenProductManagement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          hint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.muted,
              ),
        ),
        const SizedBox(height: 16),
        BookingFormSection(
          step: '1',
          title: '기본 정보',
          subtitle: '리조트 이름·위치·소개를 관리합니다.',
          child: Column(
            children: [
              TextField(
                controller: name,
                decoration: _deskInputDecoration(
                  label: l10n.partnerShopName,
                  required: true,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: location,
                decoration: _deskInputDecoration(
                  label: l10n.partnerShopLocation,
                  required: true,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: address,
                decoration: _deskInputDecoration(
                  label: l10n.exploreResortAddress,
                  hint: '국가·도시 예: 괌, 이집트 다합 (홈 지도는 로그 지역에 불이 켜집니다)',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('resort-intro-field'),
                controller: intro,
                maxLines: 5,
                maxLength: kMaxIntroBody,
                decoration: _deskInputDecoration(
                  label: l10n.exploreResortIntro,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BookingFormSection(
          step: '1b',
          title: '미디어 (사진)',
          subtitle: l10n.exploreCoverPhotoHint,
          child: RepaintBoundary(
            child: BookingGalleryEditor(
              items: slots,
              onAdd: onAddPhotos,
              onTest: onTestPhoto,
              onRemove: onRemovePhoto,
              onMakeCover: onMakeCover,
              maxItems: _kMaxGallery,
              fieldKey: const Key('resort-cover-field'),
              attachKey: const Key('resort-cover-field-attach'),
              testKey: const Key('resort-cover-field-test'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ResortDeskInfoSections(draft: info, onChanged: onInfoChanged),
        const SizedBox(height: 16),
        BookingFormSection(
          step: '8',
          title: '상품 가격·옵션',
          subtitle: '가격과 옵션은 상품 관리에서 수정하세요.',
          trailing: FilledButton.tonalIcon(
            key: const Key('partner-product-form'),
            onPressed: onOpenProductManagement,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('상품 관리에서 수정'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE6EBEF)),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    '대표 상품명·가격 칸은 여기서 바꾸지 않습니다. '
                    '상품 관리에서 수정한 내용이 손님 화면에 반영됩니다.',
                    style: TextStyle(color: AppTheme.muted, height: 1.35),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              RepaintBoundary(
                child: _OptionAdminTable(options: primaryProduct.options),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionAdminTable extends StatelessWidget {
  const _OptionAdminTable({required this.options});

  final List<ShopProductOption> options;

  static final _price = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (options.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6EBEF)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: Column(
            children: [
              const Icon(Icons.tune_outlined, color: AppTheme.muted),
              const SizedBox(height: 10),
              Text(
                l10n.productFormOptionsHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.muted,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                '상품 관리에서 옵션을 추가하세요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.muted,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EBEF)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F9FB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    '옵션명',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    l10n.exploreConsumerPrice,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    l10n.exploreProPrice,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _OptionAdminRow(
              option: options[i],
              price: _price,
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionAdminRow extends StatelessWidget {
  const _OptionAdminRow({
    required this.option,
    required this.price,
  });

  final ShopProductOption option;
  final NumberFormat price;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (option.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      option.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.muted,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text('${price.format(option.consumerPrice)}원'),
            ),
            Expanded(
              flex: 2,
              child: Text('${price.format(option.professionalPrice)}원'),
            ),
          ],
        ),
      ),
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
