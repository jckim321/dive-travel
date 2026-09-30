import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/passport_stamps.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Shared admin + partner travel-product registration form.
class TravelProductRegistrationScreen extends StatefulWidget {
  const TravelProductRegistrationScreen({
    super.key,
    this.lockedShopId,
    this.partnerMode = false,
    this.existing,
  });

  final String? lockedShopId;
  final bool partnerMode;
  final ShopProduct? existing;

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
  final _photoPicker = const DivePhotoPicker();
  final _options = <_OptionEditors>[];
  PickedPhoto? _photo;
  late String _shopId;
  late String _continent;
  late ProductListingKind _kind;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _shopId = widget.lockedShopId ??
        existing?.shopId ??
        DiveShopCatalog.shops.first.id;
    final shop = DiveShopCatalog.byId(_shopId);
    _continent = existing?.continent.isNotEmpty == true
        ? existing!.continent
        : (shop?.continent ?? ContinentId.asia);
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
      final filtered = _shopsForContinent;
      if (filtered.isEmpty) {
        return;
      }
      if (!filtered.any((shop) => shop.id == _shopId)) {
        _shopId = filtered.first.id;
      }
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final options = [
        for (final draft in _options)
          if (draft.name.text.trim().isNotEmpty) draft.toOption(),
      ];
      await DiverStoreScope.of(context).saveShopProduct(
        shopId: _shopId,
        product: ShopProduct(
          id: widget.existing?.id ??
              'p-${DateTime.now().millisecondsSinceEpoch}',
          shopId: _shopId,
          name: name,
          consumerPrice: int.tryParse(_consumer.text) ?? 0,
          professionalPrice: int.tryParse(_pro.text) ?? 0,
          blurb: _blurb.text.trim(),
          durationLabel: _duration.text.trim(),
          coverUrl: widget.existing?.coverUrl ?? '',
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
          listingKind: _kind,
        ),
        photoBytes: _photo?.bytes,
        photoFileName: _photo?.fileName,
        photoContentType: _photo?.contentType,
        useAsResortCover: widget.existing == null,
      );
      if (!mounted) {
        return;
      }
      final store = DiverStoreScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            store.stats.isAdmin
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
      final message = error.toString();
      final partial = message.contains('정보는 저장했지만');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(partial ? message : '${l10n.exploreSaveFail}\n$error'),
        ),
      );
      if (partial) {
        Navigator.of(context).pop();
      }
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
    if (!shopLocked &&
        shops.isNotEmpty &&
        !shops.any((shop) => shop.id == _shopId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _shopId = shops.first.id);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        title: Text(l10n.adminProductsTitle),
        backgroundColor: AppTheme.canvas,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _HeroBanner(
            title: l10n.productFormHeroTitle,
            body: widget.partnerMode
                ? l10n.partnerProductPendingHint
                : l10n.productFormHeroBody,
          ),
          const SizedBox(height: 16),
          _FormSection(
            icon: Icons.public_outlined,
            title: l10n.productFormSectionLocation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
            icon: Icons.place_outlined,
            title: l10n.productFormSectionListing,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in ProductListingKind.values)
                  ChoiceChip(
                    key: Key('product-kind-${kind.name}'),
                    label: Text(_kindLabel(l10n, kind)),
                    selected: _kind == kind,
                    selectedColor: AppTheme.goldSoft,
                    onSelected: (_) => setState(() => _kind = kind),
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
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      final photo = await _photoPicker.pick();
                      if (photo == null || !mounted) {
                        return;
                      }
                      setState(() => _photo = photo);
                    },
                    child: _photo == null
                        ? SizedBox(
                            height: 148,
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
                            borderRadius: BorderRadius.circular(14),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.memory(
                                _photo!.bytes,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                  ),
                ),
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
          _FormSection(
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
          _FormSection(
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
          _FormSection(
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

String _kindLabel(AppLocalizations l10n, ProductListingKind kind) {
  switch (kind) {
    case ProductListingKind.diveStar:
      return l10n.productListingDiveStar;
    case ProductListingKind.favorites:
      return l10n.productListingFavorites;
    case ProductListingKind.popular:
      return l10n.productListingPopular;
    case ProductListingKind.nextDeparture:
      return l10n.productListingNextDeparture;
    case ProductListingKind.curated:
      return l10n.productListingCurated;
  }
}
