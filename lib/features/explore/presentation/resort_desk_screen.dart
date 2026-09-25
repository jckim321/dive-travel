import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/widgets/listing_cover.dart';
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
        SnackBar(content: Text(l10n.partnerShopName)),
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
          content: Text('${l10n.exploreSaveFail}\n$error'),
          duration: const Duration(seconds: 5),
        ),
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
    final store = DiverStoreScope.of(context);
    final live = store.liveStatsFor(widget.shopId);
    final listings = store.listingsOnHull(widget.shopId);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exploreEditResort),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveProfile,
            child: Text(_saving ? l10n.exploreSaving : l10n.partnerSave),
          ),
        ],
      ),
      body: ListView(
        key: const Key('resort-desk'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(l10n.exploreDeskHint, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          _AgodaGalleryEditor(
            slots: _slots,
            onAdd: _addPhotos,
            onTest: _useTestPhoto,
            onRemove: _removeAt,
            onMakeCover: _makeCover,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l10n.partnerShopName),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _location,
            decoration: InputDecoration(labelText: l10n.partnerShopLocation),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            decoration: InputDecoration(labelText: l10n.exploreResortAddress),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('resort-intro-field'),
            controller: _intro,
            maxLines: 5,
            decoration: InputDecoration(labelText: l10n.exploreResortIntro),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('resort-amenities-field'),
            controller: _amenities,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.exploreResortTraits,
              hintText: l10n.exploreAmenitiesHint,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _product,
            decoration: InputDecoration(labelText: l10n.partnerDefaultProduct),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _consumer,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.exploreConsumerPrice),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pro,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.exploreProPrice),
          ),
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('resort-save'),
            onPressed: _saving ? null : _saveProfile,
            child: Text(_saving ? l10n.exploreSaving : l10n.partnerSave),
          ),
          const SizedBox(height: 28),
          Text(l10n.partnerProductForm, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(l10n.partnerProductFormHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          for (final shop in listings)
            Card(
              child: ListTile(
                title: Text(shop.productName),
                subtitle: Text(
                  shop.blurb.isEmpty ? shop.durationLabel : shop.blurb,
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PartnerProductFormScreen(
                      shopId: widget.shopId,
                      existing: ShopProduct(
                        id: shop.id.contains('--')
                            ? shop.id.split('--').last
                            : 'default',
                        shopId: widget.shopId,
                        name: shop.productName,
                        consumerPrice: shop.consumerPrice,
                        professionalPrice: shop.professionalPrice,
                        blurb: shop.blurb,
                        durationLabel: shop.durationLabel,
                        coverUrl: shop.coverUrl,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (live != null)
            for (final product in live.products)
              if (!listings.any(
                (shop) =>
                    shop.id.endsWith(product.id) ||
                    shop.productName == product.name,
              ))
                Card(
                  child: ListTile(
                    title: Text(product.name),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PartnerProductFormScreen(
                          shopId: widget.shopId,
                          existing: product,
                        ),
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('partner-product-form'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PartnerProductFormScreen(shopId: widget.shopId),
              ),
            ),
            icon: const Icon(Icons.add),
            label: Text(l10n.partnerProductForm),
          ),
        ],
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
        Text(l10n.exploreGalleryTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(l10n.exploreCoverPhotoHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
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

class PartnerProductFormScreen extends StatefulWidget {
  const PartnerProductFormScreen({
    super.key,
    required this.shopId,
    this.existing,
  });

  final String shopId;
  final ShopProduct? existing;

  @override
  State<PartnerProductFormScreen> createState() =>
      _PartnerProductFormScreenState();
}

class _PartnerProductFormScreenState extends State<PartnerProductFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _consumer;
  late final TextEditingController _pro;
  late final TextEditingController _blurb;
  late final TextEditingController _duration;
  final _photoPicker = const DivePhotoPicker();
  PickedPhoto? _photo;
  var _useAsCover = true;
  late ProductListingKind _kind;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _kind = existing?.listingKind ?? ProductListingKind.diveStar;
    _name = TextEditingController(text: existing?.name ?? '');
    _consumer = TextEditingController(
      text: existing == null ? '' : '${existing.consumerPrice}',
    );
    _pro = TextEditingController(
      text: existing == null ? '' : '${existing.professionalPrice}',
    );
    _blurb = TextEditingController(text: existing?.blurb ?? '');
    _duration = TextEditingController(text: existing?.durationLabel ?? '');
    _useAsCover = existing == null;
  }

  @override
  void dispose() {
    _name.dispose();
    _consumer.dispose();
    _pro.dispose();
    _blurb.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.partnerProductForm)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.partnerProductPendingHint),
          const SizedBox(height: 16),
          Text(l10n.productListingKind, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in ProductListingKind.values)
                ChoiceChip(
                  label: Text(switch (kind) {
                    ProductListingKind.diveStar => l10n.productListingDiveStar,
                    ProductListingKind.favorites => l10n.productListingFavorites,
                    ProductListingKind.popular => l10n.productListingPopular,
                    ProductListingKind.nextDeparture =>
                      l10n.productListingNextDeparture,
                    ProductListingKind.curated => l10n.productListingCurated,
                  }),
                  selected: _kind == kind,
                  onSelected: (_) => setState(() => _kind = kind),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _CoverEditor(
            fieldKey: 'product-cover-field',
            bytes: _photo?.bytes ??
                DiverStoreScope.of(context).coverBytesFor(
                  '${widget.shopId}--${widget.existing?.id ?? ''}',
                ),
            imageUrl: widget.existing?.coverUrl,
            onPick: () async {
              final photo = await _photoPicker.pick();
              if (photo == null || !mounted) {
                return;
              }
              setState(() => _photo = photo);
            },
            onTest: () async {
              final data = await rootBundle.load(
                'assets/images/test_dive_photo.png',
              );
              if (!mounted) {
                return;
              }
              setState(() {
                _photo = PickedPhoto(
                  bytes: data.buffer.asUint8List(),
                  fileName: 'test_dive_photo.png',
                  contentType: 'image/png',
                );
              });
            },
            onRemove: () => setState(() => _photo = null),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            key: const Key('product-use-as-cover'),
            contentPadding: EdgeInsets.zero,
            value: _useAsCover,
            onChanged: (value) => setState(() => _useAsCover = value ?? false),
            title: Text(l10n.exploreUseAsCover),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('partner-product-name'),
            controller: _name,
            decoration: InputDecoration(labelText: l10n.partnerDefaultProduct),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _duration,
            decoration: InputDecoration(labelText: l10n.exploreProductDuration),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _blurb,
            maxLines: 3,
            decoration: InputDecoration(labelText: l10n.exploreProductBlurb),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('partner-consumer-price'),
            controller: _consumer,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.exploreConsumerPrice),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('partner-pro-price'),
            controller: _pro,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.exploreProPrice),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('partner-product-save'),
            onPressed: () async {
              final name = _name.text.trim();
              if (name.isEmpty) {
                return;
              }
              try {
                await DiverStoreScope.of(context).saveShopProduct(
                  shopId: widget.shopId,
                  product: ShopProduct(
                    id: widget.existing?.id ??
                        'p-${DateTime.now().millisecondsSinceEpoch}',
                    shopId: widget.shopId,
                    name: name,
                    consumerPrice: int.tryParse(_consumer.text) ?? 0,
                    professionalPrice: int.tryParse(_pro.text) ?? 0,
                    blurb: _blurb.text.trim(),
                    durationLabel: _duration.text.trim(),
                    coverUrl: widget.existing?.coverUrl ?? '',
                    listingKind: _kind,
                    publishStatus: ProductPublishStatus.pending,
                    submittedAt: DateTime.now(),
                    active: false,
                  ),
                  photoBytes: _photo?.bytes,
                  photoFileName: _photo?.fileName,
                  photoContentType: _photo?.contentType,
                  useAsResortCover: _useAsCover,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context).adminProductSubmitted,
                      ),
                    ),
                  );
                  Navigator.of(context).pop();
                }
              } catch (error) {
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${AppLocalizations.of(context).exploreSaveFail}\n$error',
                    ),
                  ),
                );
              }
            },
            child: Text(l10n.partnerSave),
          ),
        ],
      ),
    );
  }
}

class _CoverEditor extends StatelessWidget {
  const _CoverEditor({
    required this.fieldKey,
    required this.onPick,
    required this.onTest,
    required this.onRemove,
    this.bytes,
    this.imageUrl,
  });

  final String fieldKey;
  final Uint8List? bytes;
  final String? imageUrl;
  final VoidCallback onPick;
  final VoidCallback onTest;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasImage =
        (bytes != null && bytes!.isNotEmpty) ||
        (imageUrl != null &&
            imageUrl!.isNotEmpty &&
            !imageUrl!.startsWith('memory://'));
    return Column(
      key: Key(fieldKey),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.exploreCoverPhoto,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.exploreCoverPhotoHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: ListingCover.aspectRatio,
            child: ColoredBox(
              color: const Color(0xFF0B1F33),
              child: bytes != null && bytes!.isNotEmpty
                  ? Image.memory(bytes!, fit: BoxFit.cover)
                  : imageUrl != null &&
                          imageUrl!.isNotEmpty &&
                          !imageUrl!.startsWith('memory://')
                      ? Image.network(imageUrl!, fit: BoxFit.cover)
                      : Image.asset(
                          'assets/images/test_dive_photo.png',
                          fit: BoxFit.cover,
                          opacity: const AlwaysStoppedAnimation(0.45),
                        ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              key: Key('$fieldKey-attach'),
              onPressed: onPick,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(l10n.exploreAttachPhoto),
            ),
            OutlinedButton(
              key: Key('$fieldKey-test'),
              onPressed: onTest,
              child: Text(l10n.logbookUseTestPhoto),
            ),
            if (hasImage)
              TextButton(
                onPressed: onRemove,
                child: Text(l10n.exploreCoverRemove),
              ),
          ],
        ),
      ],
    );
  }
}
