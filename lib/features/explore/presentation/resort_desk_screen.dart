import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/listing_cover.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_detail_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

const _kMaxGallery = 12;

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
  final List<_GallerySlot> _slots = [];
  var _seeded = false;
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

    final urls = live?.displayGallery ??
        (hull == null
            ? const <String>[]
            : hull.displayGallery);
    final localBytes = store.galleryBytesFor(widget.shopId);
    if (localBytes.isNotEmpty && urls.isEmpty) {
      for (final bytes in localBytes) {
        _slots.add(
          _GallerySlot.local(
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
        _slots.add(_GallerySlot.remote(url));
      }
      final coverBytes = store.coverBytesFor(widget.shopId);
      if (_slots.isEmpty && coverBytes != null && coverBytes.isNotEmpty) {
        _slots.add(
          _GallerySlot.local(
            PickedPhoto(
              bytes: coverBytes,
              fileName: 'cover.jpg',
              contentType: 'image/jpeg',
            ),
          ),
        );
      }
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
    final photos = await _photoPicker.pickMultiple(max: remaining);
    if (photos.isEmpty || !mounted) {
      return;
    }
    setState(() {
      for (final photo in photos) {
        if (_slots.length >= _kMaxGallery) {
          break;
        }
        _slots.add(_GallerySlot.local(photo));
      }
    });
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
      _slots.add(
        _GallerySlot.local(
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
    setState(() => _slots.removeAt(index));
  }

  void _makeCover(int index) {
    if (index <= 0 || index >= _slots.length) {
      return;
    }
    setState(() {
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
        gallery: [
          for (final slot in _slots)
            ShopGallerySlot(
              url: slot.url,
              bytes: slot.photo?.bytes,
              fileName: slot.photo?.fileName,
              contentType: slot.photo?.contentType,
            ),
        ],
        removeCover: _slots.isEmpty,
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

  Future<void> _openProductForm([ShopProduct? existing]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PartnerProductFormScreen(
          shopId: widget.shopId,
          existing: existing,
        ),
      ),
    );
  }

  Future<void> _deleteProduct(ShopProduct product) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeletePost),
        content: Text(product.name),
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
    try {
      await DiverStoreScope.of(context).deleteShopProduct(
        shopId: widget.shopId,
        productId: product.id,
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

  List<ShopProduct> _collectProducts(
    ShopLiveStats? live,
    List<DiveShop> listings,
  ) {
    final byId = <String, ShopProduct>{};
    for (final product in live?.products ?? const <ShopProduct>[]) {
      if (product.id.isNotEmpty) {
        byId[product.id] = product;
      }
    }
    for (final shop in listings) {
      final id = shop.id.contains('--')
          ? shop.id.split('--').last
          : byId.entries
              .where((e) => e.value.name == shop.productName)
              .map((e) => e.key)
              .firstOrNull;
      final resolvedId = (id == null || id.isEmpty)
          ? 'listing-${shop.productName.hashCode}'
          : id;
      byId.putIfAbsent(
        resolvedId,
        () => ShopProduct(
          id: resolvedId,
          shopId: widget.shopId,
          name: shop.productName,
          consumerPrice: shop.consumerPrice,
          professionalPrice: shop.professionalPrice,
          blurb: shop.blurb,
          durationLabel: shop.durationLabel,
          coverUrl: shop.coverUrl,
        ),
      );
    }
    return byId.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final live = store.liveStatsFor(widget.shopId);
    final listings = store.listingsOnHull(widget.shopId);
    final products = _collectProducts(live, listings);

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
            products: products,
            onAddProduct: () => _openProductForm(),
            onEditProduct: _openProductForm,
            onDeleteProduct: _deleteProduct,
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
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFD8DEE5)),
  );
  return InputDecoration(
    label: required ? _RequiredLabel(label) : Text(label),
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFFBFCFD),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.ocean, width: 1.4),
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

class _DeskSectionCard extends StatelessWidget {
  const _DeskSectionCard({
    required this.step,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String step;
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EBEF)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.navy,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    step,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.muted,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EBEF)),
        boxShadow: AppTheme.cardShadow,
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
                  borderRadius: BorderRadius.circular(12),
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
                side: const BorderSide(color: Color(0xFFD0D7DE)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
    required this.products,
    required this.onAddProduct,
    required this.onEditProduct,
    required this.onDeleteProduct,
  });

  final String hint;
  final TextEditingController name;
  final TextEditingController location;
  final TextEditingController address;
  final TextEditingController intro;
  final TextEditingController amenities;
  final TextEditingController product;
  final List<_GallerySlot> slots;
  final VoidCallback onAddPhotos;
  final VoidCallback onTestPhoto;
  final ValueChanged<int> onRemovePhoto;
  final ValueChanged<int> onMakeCover;
  final List<ShopProduct> products;
  final VoidCallback onAddProduct;
  final ValueChanged<ShopProduct> onEditProduct;
  final ValueChanged<ShopProduct> onDeleteProduct;

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
        _DeskSectionCard(
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
        _DeskSectionCard(
          step: '2',
          title: '미디어 (사진)',
          subtitle: l10n.exploreCoverPhotoHint,
          child: _AgodaGalleryEditor(
            slots: slots,
            onAdd: onAddPhotos,
            onTest: onTestPhoto,
            onRemove: onRemovePhoto,
            onMakeCover: onMakeCover,
          ),
        ),
        const SizedBox(height: 16),
        _DeskSectionCard(
          step: '3',
          title: '상품 등록',
          subtitle: l10n.partnerProductFormHint,
          trailing: FilledButton.tonalIcon(
            key: const Key('partner-product-form'),
            onPressed: onAddProduct,
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.partnerProductForm),
          ),
          child: _ProductAdminTable(
            products: products,
            onEdit: onEditProduct,
            onDelete: onDeleteProduct,
            onAdd: onAddProduct,
          ),
        ),
      ],
    );
  }
}

class _ProductAdminTable extends StatelessWidget {
  const _ProductAdminTable({
    required this.products,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  final List<ShopProduct> products;
  final ValueChanged<ShopProduct> onEdit;
  final ValueChanged<ShopProduct> onDelete;
  final VoidCallback onAdd;

  static final _price = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (products.isEmpty) {
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
              const Icon(Icons.inventory_2_outlined, color: AppTheme.muted),
              const SizedBox(height: 10),
              Text(
                l10n.partnerProductFormHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.muted,
                    ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text(l10n.partnerProductForm),
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
                    '상품명',
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
                const SizedBox(width: 88),
              ],
            ),
          ),
          for (var i = 0; i < products.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _ProductAdminRow(
              product: products[i],
              price: _price,
              onEdit: () => onEdit(products[i]),
              onDelete: () => onDelete(products[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductAdminRow extends StatelessWidget {
  const _ProductAdminRow({
    required this.product,
    required this.price,
    required this.onEdit,
    required this.onDelete,
  });

  final ShopProduct product;
  final NumberFormat price;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final detail = product.blurb.isNotEmpty
        ? product.blurb
        : product.durationLabel;
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        detail,
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
                child: Text('${price.format(product.consumerPrice)}원'),
              ),
              Expanded(
                flex: 2,
                child: Text('${price.format(product.professionalPrice)}원'),
              ),
              SizedBox(
                width: 88,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: '수정',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                    IconButton(
                      tooltip: '삭제',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 20),
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

class _GallerySlot {
  const _GallerySlot._({this.url, this.photo});

  factory _GallerySlot.remote(String url) => _GallerySlot._(url: url);

  factory _GallerySlot.local(PickedPhoto photo) => _GallerySlot._(photo: photo);

  final String? url;
  final PickedPhoto? photo;

  bool get hasImage =>
      (photo != null && photo!.bytes.isNotEmpty) ||
      (url != null && url!.isNotEmpty && !url!.startsWith('memory://'));
}

class _AgodaGalleryEditor extends StatelessWidget {
  const _AgodaGalleryEditor({
    required this.slots,
    required this.onAdd,
    required this.onTest,
    required this.onRemove,
    required this.onMakeCover,
  });

  final List<_GallerySlot> slots;
  final VoidCallback onAdd;
  final VoidCallback onTest;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onMakeCover;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canAdd = slots.length < _kMaxGallery;

    return Column(
      key: const Key('resort-cover-field'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          slots.isEmpty
              ? l10n.exploreGalleryEmpty
              : l10n.exploreGalleryCount(slots.length),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        if (slots.isEmpty)
          _EmptyGalleryDrop(onAdd: onAdd)
        else
          _AgodaGalleryGrid(
            slots: slots,
            onRemove: onRemove,
            onMakeCover: onMakeCover,
            onAdd: canAdd ? onAdd : null,
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              key: const Key('resort-cover-field-attach'),
              onPressed: canAdd ? onAdd : null,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                slots.isEmpty
                    ? l10n.exploreAttachPhoto
                    : l10n.exploreGalleryAddMore,
              ),
            ),
            OutlinedButton(
              key: const Key('resort-cover-field-test'),
              onPressed: canAdd ? onTest : null,
              child: Text(l10n.logbookUseTestPhoto),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyGalleryDrop extends StatelessWidget {
  const _EmptyGalleryDrop({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      color: const Color(0xFF0B1F33),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: ListingCover.aspectRatio,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_a_photo_outlined,
                  size: 36,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.exploreGalleryAdd,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.exploreGalleryHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AgodaGalleryGrid extends StatelessWidget {
  const _AgodaGalleryGrid({
    required this.slots,
    required this.onRemove,
    required this.onMakeCover,
    this.onAdd,
  });

  final List<_GallerySlot> slots;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onMakeCover;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final extras = slots.length > 1 ? slots.sublist(1) : const <_GallerySlot>[];
    final showTiles = extras.take(4).toList();
    final moreCount = slots.length > 5 ? slots.length - 5 : 0;

    return AspectRatio(
      aspectRatio: 2.05,
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: _GalleryTile(
              slot: slots.first,
              isCover: true,
              label: l10n.exploreCoverPhoto,
              onRemove: () => onRemove(0),
              badge: moreCount > 0
                  ? null
                  : slots.length > 1
                      ? l10n.exploreGalleryViewAll
                      : null,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _smallOrAdd(
                          context,
                          index: 1,
                          showTiles: showTiles,
                          onAdd: onAdd,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _smallOrAdd(
                          context,
                          index: 2,
                          showTiles: showTiles,
                          onAdd: onAdd,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _smallOrAdd(
                          context,
                          index: 3,
                          showTiles: showTiles,
                          onAdd: onAdd,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _smallOrAdd(
                              context,
                              index: 4,
                              showTiles: showTiles,
                              onAdd: onAdd,
                            ),
                            if (moreCount > 0)
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '+$moreCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallOrAdd(
    BuildContext context, {
    required int index,
    required List<_GallerySlot> showTiles,
    required VoidCallback? onAdd,
  }) {
    final slotIndex = index;
    final tileIndex = index - 1;
    if (tileIndex < showTiles.length) {
      return _GalleryTile(
        slot: showTiles[tileIndex],
        onRemove: () => onRemove(slotIndex),
        onMakeCover: () => onMakeCover(slotIndex),
      );
    }
    if (onAdd == null) {
      return const SizedBox.shrink();
    }
    return Material(
      color: const Color(0xFF16324A),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(10),
        child: const Center(
          child: Icon(Icons.add, color: Colors.white70),
        ),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    required this.slot,
    required this.onRemove,
    this.onMakeCover,
    this.isCover = false,
    this.label,
    this.badge,
  });

  final _GallerySlot slot;
  final VoidCallback onRemove;
  final VoidCallback? onMakeCover;
  final bool isCover;
  final String? label;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final radius = BorderRadius.circular(isCover ? 14 : 10);
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: const Color(0xFF0B1F33),
            child: slot.photo != null
                ? Image.memory(slot.photo!.bytes, fit: BoxFit.cover)
                : slot.url != null && slot.url!.isNotEmpty
                    ? Image.network(
                        slot.url!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      )
                    : Image.asset(
                        'assets/images/test_dive_photo.png',
                        fit: BoxFit.cover,
                        opacity: const AlwaysStoppedAnimation(0.45),
                      ),
          ),
          if (label != null)
            Positioned(
              left: 10,
              bottom: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    label!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          if (badge != null)
            Positioned(
              right: 10,
              bottom: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        badge!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: 6,
            right: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onMakeCover != null)
                  _TileAction(
                    tooltip: l10n.exploreGalleryMakeCover,
                    icon: Icons.star_outline,
                    onTap: onMakeCover!,
                  ),
                _TileAction(
                  tooltip: l10n.exploreCoverRemove,
                  icon: Icons.close,
                  onTap: onRemove,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TileAction extends StatelessWidget {
  const _TileAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Material(
        color: Colors.black54,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Tooltip(
            message: tooltip,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
          ),
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
    );
  }
}
