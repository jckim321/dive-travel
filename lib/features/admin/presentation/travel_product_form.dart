import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/config/r2_config.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/listing_cover.dart';
import 'package:dive_travel_app/core/widgets/passport_stamps.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Shared admin + partner + diver-creator travel-product registration form.
class TravelProductRegistrationScreen extends StatefulWidget {
  const TravelProductRegistrationScreen({
    super.key,
    this.lockedShopId,
    this.partnerMode = false,
    this.creatorMode = false,
    this.existing,
  });

  final String? lockedShopId;
  final bool partnerMode;
  /// Diver "craft a trip" from My — always submits as pending.
  final bool creatorMode;
  final ShopProduct? existing;

  static const notInListShopId = '__not_in_list__';

  @override
  State<TravelProductRegistrationScreen> createState() =>
      _TravelProductRegistrationScreenState();
}

class _OptionEditors {
  _OptionEditors({
    String? id,
    String name = '',
    String description = '',
    String consumer = '',
    String professional = '',
  }) : id = id ?? 'opt-${DateTime.now().microsecondsSinceEpoch}',
       name = TextEditingController(text: name),
       description = TextEditingController(text: description),
       consumer = TextEditingController(text: consumer),
       professional = TextEditingController(text: professional);

  final String id;
  final TextEditingController name;
  final TextEditingController description;
  final TextEditingController consumer;
  final TextEditingController professional;

  void dispose() {
    name.dispose();
    description.dispose();
    consumer.dispose();
    professional.dispose();
  }

  ShopProductOption toOption() {
    return ShopProductOption(
      id: id,
      name: name.text.trim(),
      description: description.text.trim(),
      consumerPrice: int.tryParse(consumer.text) ?? 0,
      professionalPrice: int.tryParse(professional.text) ?? 0,
    );
  }
}

class _TravelProductRegistrationScreenState
    extends State<TravelProductRegistrationScreen> {
  late final TextEditingController _name;
  late final TextEditingController _consumer;
  late final TextEditingController _pro;
  late final TextEditingController _blurb;
  late final TextEditingController _duration;
  late final TextEditingController _meeting;
  late final TextEditingController _schedule;
  late final TextEditingController _includes;
  late final TextEditingController _excludes;
  late final TextEditingController _difficulty;
  late final TextEditingController _minGuests;
  late final TextEditingController _maxGuests;
  late final TextEditingController _cancelNote;
  late final TextEditingController _customResort;
  late final TextEditingController _customLocation;
  late final TextEditingController _customCountry;
  final _photoPicker = const DivePhotoPicker();
  final _options = <_OptionEditors>[];
  PickedPhoto? _photo;
  var _removeExistingCover = false;
  late String _shopId;
  late String _continent;
  var _curatedMode = false;
  var _saving = false;

  String get _existingCoverUrl {
    final url = widget.existing?.coverUrl.trim() ?? '';
    if (_removeExistingCover || url.isEmpty) {
      return '';
    }
    return url;
  }

  bool get _hasCoverPreview => _photo != null || _existingCoverUrl.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _shopId = widget.lockedShopId ??
        existing?.shopId ??
        DiveShopCatalog.shops.first.id;
    final shop = DiveShopCatalog.byId(_shopId);
    final existingCurated = existing?.shopId.startsWith('curated-') == true ||
        (shop == null && existing != null);
    _curatedMode = widget.creatorMode
        ? existingCurated
        : widget.lockedShopId == null && existingCurated;
    _continent = existing?.continent.isNotEmpty == true
        ? existing!.continent
        : (shop?.continent ?? ContinentId.asia);
    _name = TextEditingController(text: existing?.name ?? '');
    _consumer = TextEditingController(
      text: existing == null ? '' : '${existing.consumerPrice}',
    );
    _pro = TextEditingController(
      text: existing == null ? '' : '${existing.professionalPrice}',
    );
    _blurb = TextEditingController(text: existing?.blurb ?? '');
    _duration = TextEditingController(text: existing?.durationLabel ?? '');
    _meeting = TextEditingController(text: existing?.meetingPoint ?? '');
    _schedule = TextEditingController(text: existing?.schedule ?? '');
    _includes = TextEditingController(text: existing?.includes ?? '');
    _excludes = TextEditingController(text: existing?.excludes ?? '');
    _difficulty = TextEditingController(text: existing?.difficulty ?? '');
    _minGuests = TextEditingController(
      text: (existing?.minGuests ?? 0) > 0 ? '${existing!.minGuests}' : '',
    );
    _maxGuests = TextEditingController(
      text: (existing?.maxGuests ?? 0) > 0 ? '${existing!.maxGuests}' : '',
    );
    _cancelNote = TextEditingController(text: existing?.cancellationNote ?? '');
    _customResort = TextEditingController(text: shop?.name ?? '');
    _customLocation = TextEditingController(text: shop?.location ?? '');
    _customCountry = TextEditingController(text: shop?.country ?? '');
    final seedOptions = existing?.options ?? const <ShopProductOption>[];
    if (seedOptions.isEmpty) {
      _options.add(_OptionEditors());
    } else {
      for (final option in seedOptions) {
        _options.add(
          _OptionEditors(
            id: option.id,
            name: option.name,
            description: option.description,
            consumer: option.consumerPrice > 0 ? '${option.consumerPrice}' : '',
            professional:
                option.professionalPrice > 0 ? '${option.professionalPrice}' : '',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _consumer.dispose();
    _pro.dispose();
    _blurb.dispose();
    _duration.dispose();
    _meeting.dispose();
    _schedule.dispose();
    _includes.dispose();
    _excludes.dispose();
    _difficulty.dispose();
    _minGuests.dispose();
    _maxGuests.dispose();
    _cancelNote.dispose();
    _customResort.dispose();
    _customLocation.dispose();
    _customCountry.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  List<DiveShop> get _shopsForContinent {
    final all = DiveShopCatalog.shops;
    return [
      for (final shop in all)
        if (shop.continent == _continent) shop,
    ];
  }

  void _onContinentChanged(String? value) {
    if (value == null) {
      return;
    }
    setState(() {
      _continent = value;
      if (widget.lockedShopId != null) {
        return;
      }
      if (_curatedMode) {
        return;
      }
      final filtered = _shopsForContinent;
      if (filtered.isEmpty) {
        return;
      }
      if (!filtered.any((shop) => shop.id == _shopId)) {
        _shopId = filtered.first.id;
      }
    });
  }

  void _onCreatorShopChanged(String? value) {
    if (value == null) {
      return;
    }
    setState(() {
      final notInList =
          value == TravelProductRegistrationScreen.notInListShopId;
      _curatedMode = notInList;
      if (notInList) {
        final existingId = widget.existing?.shopId ?? '';
        _shopId = existingId.startsWith('curated-')
            ? existingId
            : TravelProductRegistrationScreen.notInListShopId;
      } else {
        _shopId = value;
        _customResort.clear();
        _customLocation.clear();
        _customCountry.clear();
      }
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty || _saving) {
      return;
    }
    final useCurated = _curatedMode ||
        _shopId == TravelProductRegistrationScreen.notInListShopId;
    if (useCurated && _customResort.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.productFormCuratedResort)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final store = DiverStoreScope.of(context);
      var shopId = _shopId;
      if (useCurated) {
        if (!shopId.startsWith('curated-')) {
          shopId = 'curated-${DateTime.now().millisecondsSinceEpoch}';
        }
        await store.saveShopProfile(
          shopId: shopId,
          name: _customResort.text.trim(),
          location: _customLocation.text.trim().isEmpty
              ? _customResort.text.trim()
              : _customLocation.text.trim(),
          productName: name,
          consumerPrice: int.tryParse(_consumer.text) ?? 0,
          professionalPrice: int.tryParse(_pro.text) ?? 0,
          country: _customCountry.text.trim(),
          continent: _continent,
          curated: true,
          intro: _blurb.text.trim(),
          address: _meeting.text.trim(),
        );
      }

      final options = [
        for (final draft in _options)
          if (draft.name.text.trim().isNotEmpty) draft.toOption(),
      ];
      final keptCover = _removeExistingCover ? '' : (widget.existing?.coverUrl ?? '');
      final sessionUid = store.uid ?? '';
      await store.saveShopProduct(
        shopId: shopId,
        product: ShopProduct(
          id: widget.existing?.id ??
              'p-${DateTime.now().millisecondsSinceEpoch}',
          shopId: shopId,
          name: name,
          consumerPrice: int.tryParse(_consumer.text) ?? 0,
          professionalPrice: int.tryParse(_pro.text) ?? 0,
          blurb: _blurb.text.trim(),
          durationLabel: _duration.text.trim(),
          coverUrl: keptCover,
          continent: _continent,
          meetingPoint: _meeting.text.trim(),
          schedule: _schedule.text.trim(),
          includes: _includes.text.trim(),
          excludes: _excludes.text.trim(),
          difficulty: _difficulty.text.trim(),
          minGuests: int.tryParse(_minGuests.text) ?? 0,
          maxGuests: int.tryParse(_maxGuests.text) ?? 0,
          cancellationNote: _cancelNote.text.trim(),
          options: options,
          // New products stay Explore-only until admin home curation.
          listingKind: widget.existing?.listingKind ??
              ProductListingKind.exploreOnly,
          featuredAt: widget.existing?.featuredAt,
          submittedAt: widget.existing?.submittedAt,
          submittedByUid: widget.existing?.submittedByUid.isNotEmpty == true
              ? widget.existing!.submittedByUid
              : sessionUid,
        ),
        photoBytes: _photo?.bytes,
        photoFileName: _photo?.fileName,
        photoContentType: _photo?.contentType,
        useAsResortCover: widget.existing == null || _photo != null,
        creatorSubmission: widget.creatorMode,
        submitterUid: sessionUid,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            store.stats.isAdmin && !widget.creatorMode
                ? l10n.adminProductApproved
                : l10n.adminProductSubmitted,
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$error'),
          duration: const Duration(seconds: 8),
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
    final theme = Theme.of(context);
    final shopLocked = widget.lockedShopId != null;
    final shops = shopLocked
        ? [
            DiveShopCatalog.byId(_shopId) ?? DiveShopCatalog.shops.first,
          ]
        : _shopsForContinent;
    if (!_curatedMode &&
        !shopLocked &&
        shops.isNotEmpty &&
        !shops.any((shop) => shop.id == _shopId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _shopId = shops.first.id);
        }
      });
    }

    if (_curatedMode &&
        _customResort.text.isEmpty &&
        widget.existing != null) {
      final live = DiverStoreScope.of(context).liveStatsFor(_shopId);
      if (live?.name != null && live!.name!.trim().isNotEmpty) {
        _customResort.text = live.name!.trim();
        if (_customLocation.text.isEmpty) {
          _customLocation.text = live.location?.trim() ?? '';
        }
        if (_customCountry.text.isEmpty) {
          _customCountry.text = live.country?.trim() ?? '';
        }
      }
    }

    final creatorNotInList = widget.creatorMode && _curatedMode;
    final showCuratedFields =
        (_curatedMode && !shopLocked && !widget.creatorMode) ||
        creatorNotInList;

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        title: Text(
          widget.creatorMode
              ? l10n.profileCraftNewTrip
              : l10n.adminProductsTitle,
        ),
        backgroundColor: AppTheme.canvas,
        actions: [
          TextButton(
            key: const Key('product-form-appbar-save'),
            onPressed: _saving ? null : _save,
            child: Text(_saving ? l10n.exploreSaving : l10n.partnerSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _HeroBanner(
            title: widget.creatorMode
                ? l10n.profileCraftNewTrip
                : l10n.productFormHeroTitle,
            body: widget.creatorMode || widget.partnerMode
                ? l10n.partnerProductPendingHint
                : l10n.productFormHeroBody,
          ),
          if (!R2Config.canPersistListingPhotos) ...[
            const SizedBox(height: 12),
            _R2SetupBanner(
              missingPublicBase: R2Config.isReady && !R2Config.hasPublicBase,
            ),
          ],
          const SizedBox(height: 16),
          _FormSection(
            icon: Icons.public_outlined,
            title: l10n.productFormSectionLocation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!shopLocked && !widget.creatorMode) ...[
                  Text(
                    l10n.productFormSourceHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(l10n.productFormSourcePartner),
                        icon: const Icon(Icons.storefront_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(l10n.productFormSourceCurated),
                        icon: const Icon(Icons.auto_awesome_outlined, size: 16),
                      ),
                    ],
                    selected: {_curatedMode},
                    onSelectionChanged: (value) {
                      setState(() => _curatedMode = value.first);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                if (widget.creatorMode) ...[
                  Text(
                    l10n.productFormCreatorShopHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  l10n.productFormContinentHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.muted,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('product-continent-$_continent'),
                  initialValue: _continent,
                  decoration: InputDecoration(
                    labelText: l10n.productFormContinent,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    for (final id in ContinentId.all)
                      DropdownMenuItem(
                        value: id,
                        child: Text(continentLabel(l10n, id)),
                      ),
                  ],
                  onChanged: shopLocked ? null : _onContinentChanged,
                ),
                const SizedBox(height: 12),
                if (widget.creatorMode && !shopLocked) ...[
                  DropdownButtonFormField<String>(
                    key: ValueKey('creator-product-shop-$_shopId'),
                    initialValue: creatorNotInList
                        ? TravelProductRegistrationScreen.notInListShopId
                        : (shops.any((s) => s.id == _shopId)
                            ? _shopId
                            : (shops.isEmpty
                                ? TravelProductRegistrationScreen
                                    .notInListShopId
                                : shops.first.id)),
                    decoration: InputDecoration(
                      labelText: l10n.partnerShopName,
                      helperText: l10n.productFormShopHint,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: [
                      for (final shop in shops)
                        DropdownMenuItem(
                          value: shop.id,
                          child: Text(shop.name),
                        ),
                      DropdownMenuItem(
                        value:
                            TravelProductRegistrationScreen.notInListShopId,
                        child: Text(l10n.productFormNotInList),
                      ),
                    ],
                    onChanged: _onCreatorShopChanged,
                  ),
                  if (showCuratedFields) ...[
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('product-curated-resort'),
                      controller: _customResort,
                      decoration: InputDecoration(
                        labelText: l10n.productFormCuratedResort,
                        hintText: l10n.productFormCuratedResortHint,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customLocation,
                      decoration: InputDecoration(
                        labelText: l10n.productFormCuratedLocation,
                        hintText: l10n.productFormCuratedLocationHint,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customCountry,
                      decoration: InputDecoration(
                        labelText: l10n.productFormCuratedCountry,
                        hintText: l10n.productFormCuratedCountryHint,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ] else if (showCuratedFields) ...[
                  TextField(
                    key: const Key('product-curated-resort'),
                    controller: _customResort,
                    decoration: InputDecoration(
                      labelText: l10n.productFormCuratedResort,
                      hintText: l10n.productFormCuratedResortHint,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customLocation,
                    decoration: InputDecoration(
                      labelText: l10n.productFormCuratedLocation,
                      hintText: l10n.productFormCuratedLocationHint,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customCountry,
                    decoration: InputDecoration(
                      labelText: l10n.productFormCuratedCountry,
                      hintText: l10n.productFormCuratedCountryHint,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ] else
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.partnerShopName,
                      helperText: l10n.productFormShopHint,
                      filled: true,
                      fillColor: Colors.white,
                      border: const OutlineInputBorder(),
                    ),
                    child: shopLocked
                        ? Text(
                            DiveShopCatalog.byId(_shopId)?.name ?? _shopId,
                            style: theme.textTheme.titleMedium,
                          )
                        : DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              key: const Key('admin-product-shop'),
                              isExpanded: true,
                              value: shops.any((s) => s.id == _shopId)
                                  ? _shopId
                                  : (shops.isEmpty ? null : shops.first.id),
                              hint: Text(l10n.productFormShopHint),
                              items: [
                                for (final shop in shops)
                                  DropdownMenuItem(
                                    value: shop.id,
                                    child: Text(shop.name),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() => _shopId = value);
                              },
                            ),
                          ),
                  ),
              ],
            ),
          ),
          _FormSection(
            icon: Icons.photo_camera_outlined,
            title: l10n.productFormSectionMedia,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.productFormPhotoHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.muted,
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: const Color(0xFFF0F4F7),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final photo = await _photoPicker.pick();
                      if (photo == null || !mounted) {
                        return;
                      }
                      setState(() {
                        _photo = photo;
                        _removeExistingCover = false;
                      });
                    },
                    child: !_hasCoverPreview
                        ? SizedBox(
                            height: 168,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 36,
                                  color: AppTheme.ocean,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.exploreAttachPhoto,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: AppTheme.navy,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: AspectRatio(
                              aspectRatio: ListingCover.aspectRatio,
                              child: _photo != null
                                  ? Image.memory(
                                      _photo!.bytes,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      _existingCoverUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const ColoredBox(
                                        color: AppTheme.oceanDeep,
                                        child: Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                  ),
                ),
                if (_hasCoverPreview) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final photo = await _photoPicker.pick();
                          if (photo == null || !mounted) {
                            return;
                          }
                          setState(() {
                            _photo = photo;
                            _removeExistingCover = false;
                          });
                        },
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: Text(l10n.exploreAttachPhoto),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _photo = null;
                            _removeExistingCover = true;
                          });
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text(l10n.exploreCoverRemove),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          _FormSection(
            icon: Icons.edit_note_outlined,
            title: l10n.productFormSectionBasics,
            child: Column(
              children: [
                TextField(
                  key: Key(
                    widget.partnerMode
                        ? 'partner-product-name'
                        : 'admin-product-name',
                  ),
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: l10n.partnerDefaultProduct,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _blurb,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n.productFormSubtitle,
                    hintText: l10n.productFormSubtitleHint,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _duration,
                  decoration: InputDecoration(
                    labelText: l10n.exploreProductDuration,
                    hintText: l10n.productFormDurationHint,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          _FormSection(
            icon: Icons.payments_outlined,
            title: l10n.productFormSectionPricing,
            child: Column(
              children: [
                TextField(
                  controller: _consumer,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.exploreConsumerPrice,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pro,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.exploreProPrice,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          _CollapsibleFormSection(
            icon: Icons.schedule_outlined,
            title: l10n.productFormSectionItinerary,
            child: Column(
              children: [
                TextField(
                  controller: _meeting,
                  decoration: InputDecoration(
                    labelText: l10n.productFormMeetingPoint,
                    hintText: l10n.productFormMeetingHint,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _schedule,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.productFormSchedule,
                    hintText: l10n.productFormScheduleHint,
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          _CollapsibleFormSection(
            icon: Icons.checklist_outlined,
            title: l10n.productFormSectionIncludes,
            child: Column(
              children: [
                TextField(
                  controller: _includes,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.productFormIncludes,
                    hintText: l10n.productFormIncludesHint,
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _excludes,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.productFormExcludes,
                    hintText: l10n.productFormExcludesHint,
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cancelNote,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n.productFormCancelNote,
                    hintText: l10n.productFormCancelHint,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          _CollapsibleFormSection(
            icon: Icons.groups_outlined,
            title: l10n.productFormSectionCapacity,
            child: Column(
              children: [
                TextField(
                  controller: _difficulty,
                  decoration: InputDecoration(
                    labelText: l10n.productFormDifficulty,
                    hintText: l10n.productFormDifficultyHint,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minGuests,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: l10n.productFormMinGuests,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxGuests,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: l10n.productFormMaxGuests,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _CollapsibleFormSection(
            icon: Icons.tune_outlined,
            title: l10n.productFormSectionOptions,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.productFormOptionsHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.muted,
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < _options.length; i++) ...[
                  _OptionCard(
                    index: i,
                    editors: _options[i],
                    canRemove: _options.length > 1,
                    onRemove: () {
                      setState(() {
                        _options.removeAt(i).dispose();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                OutlinedButton.icon(
                  key: const Key('product-add-option'),
                  onPressed: () {
                    setState(() => _options.add(_OptionEditors()));
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.productFormAddOption),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: Key(
              widget.partnerMode
                  ? 'partner-product-save'
                  : 'admin-product-submit',
            ),
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppTheme.navy,
            ),
            child: Text(
              _saving ? l10n.exploreSaving : l10n.partnerSave,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1F33),
            Color(0xFF0A4A73),
            Color(0xFF156A96),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _R2SetupBanner extends StatelessWidget {
  const _R2SetupBanner({required this.missingPublicBase});

  final bool missingPublicBase;

  @override
  Widget build(BuildContext context) {
    final body = missingPublicBase
        ? '상품 사진을 유지하려면 R2_PUBLIC_BASE_URL(공개 버킷 URL)이 필요합니다. '
            '지금은 비어 있어 저장이 막히거나 새로고침 후 사진이 사라집니다.'
        : 'Cloudflare R2 키가 비어 있습니다. 로컬은 r2_secrets.dart, '
            '배포는 GitHub Secrets를 확인하세요.';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8A54B)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                body,
                style: const TextStyle(
                  color: Color(0xFF7C2D12),
                  height: 1.35,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollapsibleFormSection extends StatelessWidget {
  const _CollapsibleFormSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            leading: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.goldSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppTheme.navy),
            ),
            title: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            children: [child],
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.goldSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: AppTheme.navy),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.index,
    required this.editors,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _OptionEditors editors;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8EE)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  '${l10n.productFormSectionOptions} ${index + 1}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.ocean,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                if (canRemove)
                  IconButton(
                    tooltip: l10n.productFormRemoveOption,
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline, size: 20),
                  ),
              ],
            ),
            TextField(
              key: Key('product-option-name-$index'),
              controller: editors.name,
              decoration: InputDecoration(
                labelText: l10n.productFormOptionName,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: editors.description,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.productFormOptionDesc,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: editors.consumer,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.productFormOptionConsumer,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: editors.professional,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.productFormOptionPro,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

