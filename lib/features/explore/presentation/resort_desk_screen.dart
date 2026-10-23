import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/constants/gallery_limits.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/booking_gallery_editor.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
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
  final _product = TextEditingController();
  final _consumer = TextEditingController();
  final _pro = TextEditingController();
  final _amenities = TextEditingController();
  final _photoPicker = const DivePhotoPicker();
  final List<BookingGalleryItem> _slots = [];
  var _seeded = false;
  var _galleryTouched = false;
  var _gallerySeedDone = false;
  var _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) {
      return;
    }
    _seeded = true;
    final store = DiverStoreScope.of(context);
    final hull = store.listingsOnHull(widget.shopId).firstOrNull ??
        DiveShopCatalog.byId(widget.shopId);
    final live = store.liveStatsFor(widget.shopId);
    _name.text = live?.name ?? hull?.name ?? '';
    _location.text = live?.location ?? hull?.location ?? '';
    _address.text = live?.address ?? hull?.address ?? '';
    _intro.text = live?.intro ?? hull?.intro ?? '';
    _product.text = live?.productName ?? hull?.productName ?? '';
    _consumer.text = '${live?.consumerPrice ?? hull?.consumerPrice ?? 0}';
    _pro.text = '${live?.professionalPrice ?? hull?.professionalPrice ?? 0}';
    final amenitySource = (live?.amenities.isNotEmpty ?? false)
        ? live!.amenities
        : (hull?.amenities ?? const <String>[]);
    _amenities.text = amenitySource.join(', ');
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
    _name.dispose();
    _location.dispose();
    _address.dispose();
    _intro.dispose();
    _product.dispose();
    _consumer.dispose();
    _pro.dispose();
    _amenities.dispose();
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

    setState(() => _saving = true);
    try {
      await DiverStoreScope.of(context).saveShopProfile(
        shopId: widget.shopId,
        name: name,
        location: _location.text,
        productName: _product.text,
        consumerPrice: int.tryParse(_consumer.text) ?? 0,
        professionalPrice: int.tryParse(_pro.text) ?? 0,
        intro: _intro.text,
        address: _address.text,
        amenities: [
          for (final part in _amenities.text.split(RegExp(r'[,，\n]')))
            if (part.trim().isNotEmpty) part.trim(),
        ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exploreSaveOk)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$error'),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _openPreview() => openResortDetail(context, widget.shopId);

  ShopProduct _primaryProduct(ShopLiveStats? live) {
    final products = live?.products ?? const <ShopProduct>[];
    if (products.isNotEmpty) {
      return products.first;
    }
    final fallbackName = _product.text.trim().isNotEmpty
        ? _product.text.trim()
        : (_name.text.trim().isEmpty ? '기본 상품' : _name.text.trim());
    return ShopProduct(
      id: 'p-${widget.shopId}-default',
      shopId: widget.shopId,
      name: fallbackName,
      consumerPrice: int.tryParse(_consumer.text) ?? 0,
      professionalPrice: int.tryParse(_pro.text) ?? 0,
    );
  }

  Future<void> _persistPrimaryProduct(ShopProduct product) async {
    final l10n = AppLocalizations.of(context);
    try {
      await DiverStoreScope.of(context).saveShopProduct(
        shopId: widget.shopId,
        product: product,
        useAsResortCover: false,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exploreSaveOk)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  Future<void> _editOption({
    required ShopProduct product,
    ShopProductOption? existing,
  }) async {
    final result = await showDialog<ShopProductOption>(
      context: context,
      builder: (context) => _ProductOptionEditorDialog(existing: existing),
    );
    if (result == null || !mounted) {
      return;
    }
    final nextOptions = [
      for (final option in product.options)
        if (option.id != result.id) option,
      result,
    ];
    await _persistPrimaryProduct(product.copyWith(options: nextOptions));
  }

  Future<void> _deleteOption({
    required ShopProduct product,
    required ShopProductOption option,
  }) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.productFormRemoveOption),
        content: Text(option.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.navy),
            child: Text(l10n.adminDeletePost),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await _persistPrimaryProduct(
      product.copyWith(
        options: [
          for (final item in product.options)
            if (item.id != option.id) item,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final live = store.liveStatsFor(widget.shopId);
    final hull = store.listingsOnHull(widget.shopId).firstOrNull ??
        DiveShopCatalog.byId(widget.shopId);
    // Live stats can arrive after first frame — fill empty gallery once.
    if (!_gallerySeedDone && !_galleryTouched && _slots.isEmpty && live != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _gallerySeedDone || _galleryTouched) {
          return;
        }
        setState(() => _seedGallery(store, live, hull, markDone: true));
      });
    }
    final primary = _primaryProduct(live);

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          final main = _DeskMainColumn(
            hint: l10n.exploreDeskHint,
            name: _name,
            location: _location,
            address: _address,
            intro: _intro,
            amenities: _amenities,
            product: _product,
            slots: _slots,
            onAddPhotos: _addPhotos,
            onTestPhoto: _useTestPhoto,
            onRemovePhoto: _removeAt,
            onMakeCover: _makeCover,
            primaryProduct: primary,
            onAddOption: () => _editOption(product: primary),
            onEditOption: (option) =>
                _editOption(product: primary, existing: option),
            onDeleteOption: (option) =>
                _deleteOption(product: primary, option: option),
          );
          final side = _DeskStickySidebar(
            saving: _saving,
            consumer: _consumer,
            pro: _pro,
            onSave: _saveProfile,
            onPreview: _openPreview,
          );
          if (!wide) {
            return ListView(
              key: const Key('resort-desk'),
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
                  padding: const EdgeInsets.fromLTRB(20, 20, 12, 40),
                  child: main,
                ),
              ),
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(8, 20, 20, 40),
                  child: side,
                ),
              ),
            ],
          );
        },
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
    required this.consumer,
    required this.pro,
    required this.onSave,
    required this.onPreview,
  });

  final bool saving;
  final TextEditingController consumer;
  final TextEditingController pro;
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
              '핵심 금액',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '손님에게 먼저 보이는 대표 가격입니다.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.muted,
                  ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: consumer,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _deskInputDecoration(
                label: l10n.exploreConsumerPrice,
                required: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pro,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _deskInputDecoration(
                label: l10n.exploreProPrice,
                required: true,
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
    required this.amenities,
    required this.product,
    required this.slots,
    required this.onAddPhotos,
    required this.onTestPhoto,
    required this.onRemovePhoto,
    required this.onMakeCover,
    required this.primaryProduct,
    required this.onAddOption,
    required this.onEditOption,
    required this.onDeleteOption,
  });

  final String hint;
  final TextEditingController name;
  final TextEditingController location;
  final TextEditingController address;
  final TextEditingController intro;
  final TextEditingController amenities;
  final TextEditingController product;
  final List<BookingGalleryItem> slots;
  final VoidCallback onAddPhotos;
  final VoidCallback onTestPhoto;
  final ValueChanged<int> onRemovePhoto;
  final ValueChanged<int> onMakeCover;
  final ShopProduct primaryProduct;
  final VoidCallback onAddOption;
  final ValueChanged<ShopProductOption> onEditOption;
  final ValueChanged<ShopProductOption> onDeleteOption;

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
                decoration: _deskInputDecoration(
                  label: l10n.exploreResortIntro,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('resort-amenities-field'),
                controller: amenities,
                maxLines: 2,
                decoration: _deskInputDecoration(
                  label: l10n.exploreResortTraits,
                  hint: l10n.exploreAmenitiesHint,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: product,
                decoration: _deskInputDecoration(
                  label: l10n.partnerDefaultProduct,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BookingFormSection(
          step: '2',
          title: '미디어 (사진)',
          subtitle: l10n.exploreCoverPhotoHint,
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
        const SizedBox(height: 16),
        BookingFormSection(
          step: '3',
          title: '상품 옵션',
          subtitle: '룸·탱크·장비 등 선택 옵션을 이 창에서 바로 추가·수정합니다.',
          trailing: FilledButton.tonalIcon(
            key: const Key('partner-product-form'),
            onPressed: onAddOption,
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.productFormAddOption),
          ),
          child: _OptionAdminTable(
            options: primaryProduct.options,
            onEdit: onEditOption,
            onDelete: onDeleteOption,
            onAdd: onAddOption,
          ),
        ),
      ],
    );
  }
}

class _OptionAdminTable extends StatelessWidget {
  const _OptionAdminTable({
    required this.options,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  final List<ShopProductOption> options;
  final ValueChanged<ShopProductOption> onEdit;
  final ValueChanged<ShopProductOption> onDelete;
  final VoidCallback onAdd;

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
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text(l10n.productFormAddOption),
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
                const SizedBox(width: 72),
              ],
            ),
          ),
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _OptionAdminRow(
              option: options[i],
              price: _price,
              onEdit: () => onEdit(options[i]),
              onDelete: () => onDelete(options[i]),
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
    required this.onEdit,
    required this.onDelete,
  });

  final ShopProductOption option;
  final NumberFormat price;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
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
              SizedBox(
                width: 72,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Tooltip(
                      message: '수정',
                      child: InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.edit_outlined, size: 18),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: '삭제',
                      child: InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.delete_outline, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductOptionEditorDialog extends StatefulWidget {
  const _ProductOptionEditorDialog({this.existing});

  final ShopProductOption? existing;

  @override
  State<_ProductOptionEditorDialog> createState() =>
      _ProductOptionEditorDialogState();
}

class _ProductOptionEditorDialogState extends State<_ProductOptionEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _consumer;
  late final TextEditingController _professional;
  late final String _id;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _id = existing?.id ?? 'opt-${DateTime.now().microsecondsSinceEpoch}';
    _name = TextEditingController(text: existing?.name ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    _consumer = TextEditingController(
      text: (existing?.consumerPrice ?? 0) > 0 ? '${existing!.consumerPrice}' : '',
    );
    _professional = TextEditingController(
      text: (existing?.professionalPrice ?? 0) > 0
          ? '${existing!.professionalPrice}'
          : '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _consumer.dispose();
    _professional.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final editing = widget.existing != null;
    return AlertDialog(
      title: Text(editing ? '옵션 수정' : l10n.productFormAddOption),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: _deskInputDecoration(
                  label: '옵션명',
                  required: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLines: 2,
                decoration: _deskInputDecoration(label: '설명'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _consumer,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _deskInputDecoration(
                  label: l10n.exploreConsumerPrice,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _professional,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _deskInputDecoration(label: l10n.exploreProPrice),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) {
              return;
            }
            final existing = widget.existing;
            final edited = ShopProductOption(
              id: _id,
              name: name,
              description: _description.text.trim(),
              consumerPrice: int.tryParse(_consumer.text) ?? 0,
              professionalPrice: int.tryParse(_professional.text) ?? 0,
            );
            // Preserve same-boat / seat fields the dialog does not edit.
            Navigator.pop(
              context,
              existing == null
                  ? edited
                  : edited.copyWith(
                      kind: existing.kind,
                      bookable: existing.bookable,
                      guestRole: existing.guestRole,
                      openEmptySeats: existing.openEmptySeats,
                      capacity: existing.capacity,
                      bookedSeats: existing.bookedSeats,
                      flagHolds: existing.flagHolds,
                      departureStart: existing.departureStart,
                      flagClosesAt: existing.flagClosesAt,
                      parentOptionId: existing.parentOptionId,
                      sameBoatStatus: existing.sameBoatStatus,
                    ),
            );
          },
          style: FilledButton.styleFrom(backgroundColor: AppTheme.navy),
          child: Text(l10n.partnerSave),
        ),
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
