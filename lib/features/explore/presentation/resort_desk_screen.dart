import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/widgets/listing_cover.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

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
  final _photoPicker = const DivePhotoPicker();
  PickedPhoto? _cover;
  var _removeCover = false;
  var _seeded = false;

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
    super.dispose();
  }

  Future<void> _pickCover() async {
    final photo = await _photoPicker.pick();
    if (photo == null || !mounted) {
      return;
    }
    setState(() {
      _cover = photo;
      _removeCover = false;
    });
  }

  Future<void> _useTestCover() async {
    final data = await rootBundle.load('assets/images/test_dive_photo.png');
    if (!mounted) {
      return;
    }
    setState(() {
      _cover = PickedPhoto(
        bytes: data.buffer.asUint8List(),
        fileName: 'test_dive_photo.png',
        contentType: 'image/png',
      );
      _removeCover = false;
    });
  }

  Future<void> _saveProfile() async {
    await DiverStoreScope.of(context).saveShopProfile(
      shopId: widget.shopId,
      name: _name.text,
      location: _location.text,
      productName: _product.text,
      consumerPrice: int.tryParse(_consumer.text) ?? 0,
      professionalPrice: int.tryParse(_pro.text) ?? 0,
      intro: _intro.text,
      address: _address.text,
      coverBytes: _cover?.bytes,
      coverFileName: _cover?.fileName,
      coverContentType: _cover?.contentType,
      removeCover: _removeCover && _cover == null,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).partnerSave)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final live = store.liveStatsFor(widget.shopId);
    final listings = store.listingsOnHull(widget.shopId);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exploreEditResort),
      ),
      body: ListView(
        key: const Key('resort-desk'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(l10n.exploreDeskHint, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          _CoverEditor(
            fieldKey: 'resort-cover-field',
            bytes: _cover?.bytes ??
                store.coverBytesFor(widget.shopId),
            imageUrl: _removeCover ? '' : (live?.coverUrl ?? listings.firstOrNull?.coverUrl),
            onPick: _pickCover,
            onTest: _useTestCover,
            onRemove: () => setState(() {
              _cover = null;
              _removeCover = true;
            }),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saveProfile,
            child: Text(l10n.partnerSave),
          ),
          const SizedBox(height: 28),
          Text(l10n.partnerProductForm, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(l10n.partnerProductFormHint, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          for (final shop in listings)
            Card(
              child: ListTile(
                title: Text(shop.productName),
                subtitle: Text(shop.blurb.isEmpty ? shop.durationLabel : shop.blurb),
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
              if (!listings.any((shop) =>
                  shop.id.endsWith(product.id) || shop.productName == product.name))
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

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
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
          Text(l10n.partnerProductFormHint),
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
                ),
                photoBytes: _photo?.bytes,
                photoFileName: _photo?.fileName,
                photoContentType: _photo?.contentType,
                useAsResortCover: _useAsCover,
              );
              if (context.mounted) {
                Navigator.of(context).pop();
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
        Text(l10n.exploreCoverPhoto, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Text(l10n.exploreCoverPhotoHint, style: Theme.of(context).textTheme.bodySmall),
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
