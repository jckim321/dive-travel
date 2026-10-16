import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/config/r2_config.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class OpsProductWorkbench extends StatefulWidget {
  const OpsProductWorkbench({
    super.key,
    this.lockedShopId,
    this.partnerMode = false,
    this.existing,
  });

  final String? lockedShopId;
  final bool partnerMode;
  final ShopProduct? existing;

  @override
  State<OpsProductWorkbench> createState() => _OpsProductWorkbenchState();
}

class _LineEditors {
  _LineEditors({
    String? id,
    String name = '',
    String description = '',
    String consumer = '',
    String professional = '',
    this.kind = ProductOptionKind.addon,
    this.bookable = true,
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
  ProductOptionKind kind;
  bool bookable;

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
      kind: kind,
      bookable: bookable,
    );
  }
}

class _DayEditors {
  _DayEditors({required this.day, String title = '', String body = ''})
    : title = TextEditingController(text: title),
      body = TextEditingController(text: body);

  int day;
  final TextEditingController title;
  final TextEditingController body;

  void dispose() {
    title.dispose();
    body.dispose();
  }
}

class _OpsProductWorkbenchState extends State<OpsProductWorkbench> {
  late final TextEditingController _name;
  late final TextEditingController _blurb;
  late final TextEditingController _detail;
  late final TextEditingController _focPay;
  late final TextEditingController _focFree;
  final _rateEnabled = <GuestRole, bool>{};
  final _rateConsumer = <GuestRole, TextEditingController>{};
  final _ratePro = <GuestRole, TextEditingController>{};
  final _addons = <_LineEditors>[];
  final _individuals = <_LineEditors>[];
  final _days = <_DayEditors>[];
  final _photoPicker = const DivePhotoPicker();
  PickedPhoto? _photo;
  var _removeExistingCover = false;
  late String _shopId;
  late String _continent;
  late ProductCategory _category;
  var _deck = 0;
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
    _category = existing?.category ?? ProductCategory.resortPackage;
    _name = TextEditingController(text: existing?.name ?? '');
    _blurb = TextEditingController(text: existing?.blurb ?? '');
    _detail = TextEditingController(text: existing?.detail ?? '');
    _focPay = TextEditingController(
      text: (existing?.focPayCount ?? 0) > 0 ? '${existing!.focPayCount}' : '',
    );
    _focFree = TextEditingController(
      text: (existing?.focFreeCount ?? 0) > 0 ? '${existing!.focFreeCount}' : '',
    );
    for (final role in GuestRole.values) {
      GuestRate? found;
      for (final rate in existing?.guestRates ?? const <GuestRate>[]) {
        if (rate.role == role) {
          found = rate;
          break;
        }
      }
      final fallbackDiver = role == GuestRole.diver;
      _rateEnabled[role] = found?.enabled ?? fallbackDiver;
      _rateConsumer[role] = TextEditingController(
        text: found != null
            ? '${found.consumer}'
            : (fallbackDiver && existing != null
                ? '${existing.consumerPrice}'
                : ''),
      );
      _ratePro[role] = TextEditingController(
        text: found != null
            ? '${found.professional}'
            : (fallbackDiver && existing != null
                ? '${existing.professionalPrice}'
                : ''),
      );
    }
    final days = existing?.itineraryDays ?? const <ItineraryDay>[];
    if (days.isEmpty) {
      _days.add(_DayEditors(day: 1));
    } else {
      for (final day in days) {
        _days.add(
          _DayEditors(day: day.day, title: day.title, body: day.body),
        );
      }
    }
    for (final option in existing?.options ?? const <ShopProductOption>[]) {
      final line = _LineEditors(
        id: option.id,
        name: option.name,
        description: option.description,
        consumer: option.consumerPrice > 0 ? '${option.consumerPrice}' : '',
        professional:
            option.professionalPrice > 0 ? '${option.professionalPrice}' : '',
        kind: option.kind,
        bookable: option.bookable,
      );
      if (option.kind == ProductOptionKind.individual) {
        _individuals.add(line);
      } else if (option.kind != ProductOptionKind.basePackage) {
        _addons.add(line);
      }
    }
    if (_addons.isEmpty) {
      _addons.add(_LineEditors(kind: ProductOptionKind.addon));
    }
    if (_individuals.isEmpty) {
      _individuals.add(_LineEditors(kind: ProductOptionKind.individual));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _blurb.dispose();
    _detail.dispose();
    _focPay.dispose();
    _focFree.dispose();
    for (final c in _rateConsumer.values) {
      c.dispose();
    }
    for (final c in _ratePro.values) {
      c.dispose();
    }
    for (final item in _addons) {
      item.dispose();
    }
    for (final item in _individuals) {
      item.dispose();
    }
    for (final day in _days) {
      day.dispose();
    }
    super.dispose();
  }

  List<DiveShop> get _shopsForContinent {
    return [
      for (final shop in DiveShopCatalog.shops)
        if (shop.continent == _continent) shop,
    ];
  }

  String get _existingCoverUrl {
    final url = widget.existing?.coverUrl.trim() ?? '';
    if (_removeExistingCover || url.isEmpty) {
      return '';
    }
    return url;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final store = DiverStoreScope.of(context);
      final sessionUid = store.uid ?? '';
      final diverRate = GuestRate(
        role: GuestRole.diver,
        enabled: _rateEnabled[GuestRole.diver] ?? true,
        consumer: int.tryParse(_rateConsumer[GuestRole.diver]!.text) ?? 0,
        professional: int.tryParse(_ratePro[GuestRole.diver]!.text) ?? 0,
      );
      final guestRates = [
        for (final role in GuestRole.values)
          GuestRate(
            role: role,
            enabled: _rateEnabled[role] ?? role == GuestRole.diver,
            consumer: int.tryParse(_rateConsumer[role]!.text) ?? 0,
            professional: int.tryParse(_ratePro[role]!.text) ?? 0,
          ),
      ];
      final itinerary = <ItineraryDay>[];
      for (var i = 0; i < _days.length; i++) {
        final day = _days[i];
        final title = day.title.text.trim();
        final body = day.body.text.trim();
        if (title.isEmpty && body.isEmpty) {
          continue;
        }
        itinerary.add(ItineraryDay(day: i + 1, title: title, body: body));
      }
      final options = <ShopProductOption>[
        ShopProductOption(
          id: widget.existing?.id ?? 'base',
          name: name,
          description: _blurb.text.trim(),
          consumerPrice: diverRate.consumer,
          professionalPrice: diverRate.professional,
          kind: ProductOptionKind.basePackage,
        ),
        for (final draft in _addons)
          if (draft.name.text.trim().isNotEmpty)
            draft.toOption().copyWith(kind: ProductOptionKind.addon),
        for (final draft in _individuals)
          if (draft.name.text.trim().isNotEmpty)
            draft.toOption().copyWith(kind: ProductOptionKind.individual),
      ];
      final nightsLabel = itinerary.isEmpty
          ? ''
          : itinerary.length <= 1
          ? '1일'
          : '${itinerary.length - 1}박 ${itinerary.length}일';
      await store.saveShopProduct(
        shopId: _shopId,
        product: ShopProduct(
          id:
              widget.existing?.id ??
              'p-${DateTime.now().millisecondsSinceEpoch}',
          shopId: _shopId,
          name: name,
          consumerPrice: diverRate.consumer,
          professionalPrice: diverRate.professional,
          blurb: _blurb.text.trim(),
          durationLabel: nightsLabel,
          coverUrl: _existingCoverUrl,
          continent: _continent,
          category: _category,
          detail: _detail.text.trim(),
          photoUrls: widget.existing?.photoUrls ?? const [],
          itineraryDays: itinerary,
          guestRates: guestRates,
          focPayCount: int.tryParse(_focPay.text) ?? 0,
          focFreeCount: int.tryParse(_focFree.text) ?? 0,
          options: options,
          listingKind:
              widget.existing?.listingKind ?? ProductListingKind.exploreOnly,
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
        creatorSubmission: false,
        submitterUid: sessionUid,
      );
      if (!mounted) {
        return;
      }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), duration: const Duration(seconds: 8)),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickPhoto() async {
    final photo = await _photoPicker.pick();
    if (photo == null || !mounted) {
      return;
    }
    setState(() {
      _photo = photo;
      _removeExistingCover = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shopLocked = widget.lockedShopId != null;
    final shops = shopLocked
        ? [DiveShopCatalog.byId(_shopId) ?? DiveShopCatalog.shops.first]
        : _shopsForContinent;
    final hull = DiveShopCatalog.byId(_shopId);
    final live = DiverStoreScope.of(context).liveStatsFor(_shopId);

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        title: Text(l10n.workbenchTitle),
        backgroundColor: AppTheme.canvas,
        actions: [
          TextButton(
            key: const Key('product-form-appbar-save'),
            onPressed: _saving ? null : _save,
            child: Text(_saving ? l10n.exploreSaving : l10n.partnerSave),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final editor = _editor(l10n, shops, shopLocked, hull, live);
          if (!wide) {
            return Column(
              children: [
                _deckChips(l10n),
                Expanded(child: editor),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: FilledButton(
                      key: Key(
                        widget.partnerMode
                            ? 'partner-product-save'
                            : 'admin-product-submit',
                      ),
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppTheme.navy,
                      ),
                      child: Text(
                        _saving ? l10n.exploreSaving : l10n.partnerSave,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 168, child: _deckRail(l10n)),
              Expanded(child: editor),
              SizedBox(
                width: 280,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 16, 16),
                  child: _guestCard(l10n, hull),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _deckRail(AppLocalizations l10n) {
    final labels = [
      l10n.workbenchDeckHull,
      l10n.workbenchDeckStory,
      l10n.workbenchDeckRates,
      l10n.workbenchDeckOptions,
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: FilledButton.tonal(
              onPressed: () => setState(() => _deck = i),
              style: FilledButton.styleFrom(
                backgroundColor: _deck == i ? AppTheme.navy : AppTheme.seaMist,
                foregroundColor: _deck == i ? Colors.white : AppTheme.navy,
              ),
              child: Text(labels[i]),
            ),
          ),
      ],
    );
  }

  Widget _deckChips(AppLocalizations l10n) {
    final labels = [
      l10n.workbenchDeckHull,
      l10n.workbenchDeckStory,
      l10n.workbenchDeckRates,
      l10n.workbenchDeckOptions,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            ChoiceChip(
              label: Text(labels[i]),
              selected: _deck == i,
              onSelected: (_) => setState(() => _deck = i),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _editor(
    AppLocalizations l10n,
    List<DiveShop> shops,
    bool shopLocked,
    DiveShop? hull,
    ShopLiveStats? live,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        if (_deck == 0) _hullDeck(l10n, shops, shopLocked, hull, live),
        if (_deck == 1) _storyDeck(l10n),
        if (_deck == 2) _ratesDeck(l10n),
        if (_deck == 3) _optionsDeck(l10n),
      ],
    );
  }

  Widget _hullDeck(
    AppLocalizations l10n,
    List<DiveShop> shops,
    bool shopLocked,
    DiveShop? hull,
    ShopLiveStats? live,
  ) {
    final cats = <ProductCategory, String>{
      ProductCategory.resortPackage: l10n.workbenchCatResort,
      ProductCategory.liveaboard: l10n.workbenchCatLiveaboard,
      ProductCategory.funDive: l10n.workbenchCatFun,
      ProductCategory.course: l10n.workbenchCatCourse,
      ProductCategory.dayTrip: l10n.workbenchCatDay,
    };
    final address = (live?.address ?? hull?.address ?? '').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.workbenchCategory),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in cats.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: _category == entry.key,
                onSelected: (_) => setState(() => _category = entry.key),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: Key(
            widget.partnerMode ? 'partner-product-name' : 'admin-product-name',
          ),
          controller: _name,
          decoration: InputDecoration(
            labelText: l10n.partnerDefaultProduct,
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _continent,
          decoration: InputDecoration(
            labelText: l10n.productFormContinent,
            filled: true,
            fillColor: Colors.white,
          ),
          items: [
            for (final id in ContinentId.all)
              DropdownMenuItem(value: id, child: Text(id)),
          ],
          onChanged: shopLocked
              ? null
              : (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _continent = value;
                    final filtered = _shopsForContinent;
                    if (filtered.isNotEmpty &&
                        !filtered.any((shop) => shop.id == _shopId)) {
                      _shopId = filtered.first.id;
                    }
                  });
                },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: shops.any((shop) => shop.id == _shopId)
              ? _shopId
              : (shops.isEmpty ? null : shops.first.id),
          decoration: InputDecoration(
            labelText: l10n.productFormShopHint,
            filled: true,
            fillColor: Colors.white,
          ),
          items: [
            for (final shop in shops)
              DropdownMenuItem(value: shop.id, child: Text(shop.name)),
          ],
          onChanged: shopLocked
              ? null
              : (value) {
                  if (value != null) {
                    setState(() => _shopId = value);
                  }
                },
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8EE)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.workbenchHullFromShop,
                  style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  hull?.name ?? live?.name ?? _shopId,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${hull?.country ?? ''} · ${hull?.location ?? live?.location ?? ''}',
                ),
                if (address.isNotEmpty) Text(address),
                if (address.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'https://maps.google.com/?q=${Uri.encodeComponent(address)}',
                          ),
                        ),
                      );
                    },
                    child: Text(l10n.workbenchOpenMap),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _storyDeck(AppLocalizations l10n) {
    final cover = _photo != null || _existingCoverUrl.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _blurb,
          decoration: InputDecoration(
            labelText: l10n.productFormSubtitle,
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _detail,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: l10n.workbenchDetail,
            alignLabelWithHint: true,
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        if (cover)
          SizedBox(
            height: 120,
            width: double.infinity,
            child: _photo != null
                ? Image.memory(_photo!.bytes, fit: BoxFit.cover)
                : Image.network(_existingCoverUrl, fit: BoxFit.cover),
          ),
        Row(
          children: [
            TextButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(l10n.exploreAttachPhoto),
            ),
            if (cover)
              TextButton(
                onPressed: () {
                  setState(() {
                    _photo = null;
                    _removeExistingCover = true;
                  });
                },
                child: Text(l10n.exploreCoverRemove),
              ),
          ],
        ),
        if (!R2Config.canPersistListingPhotos)
          Text(
            l10n.productFormPhotoHint,
            style: const TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
        const SizedBox(height: 16),
        Text(
          l10n.workbenchItinerary,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        Text(
          _days.length <= 1 ? '1일' : '${_days.length - 1}박 ${_days.length}일',
          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _days.length; i++) ...[
          TextField(
            controller: _days[i].title,
            decoration: InputDecoration(
              labelText: l10n.workbenchDayTitle(i + 1),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _days[i].body,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.workbenchDayBody,
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _days.length == 1
                  ? null
                  : () {
                      setState(() => _days.removeAt(i).dispose());
                    },
              child: Text(l10n.productFormRemoveOption),
            ),
          ),
        ],
        OutlinedButton.icon(
          onPressed: () {
            setState(() => _days.add(_DayEditors(day: _days.length + 1)));
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.workbenchAddDay),
        ),
      ],
    );
  }

  Widget _ratesDeck(AppLocalizations l10n) {
    final labels = {
      GuestRole.diver: l10n.workbenchGuestDiver,
      GuestRole.nondiver: l10n.workbenchGuestNondiver,
      GuestRole.child: l10n.workbenchGuestChild,
      GuestRole.infant: l10n.workbenchGuestInfant,
    };
    return Column(
      children: [
        for (final role in GuestRole.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(labels[role]!),
                      subtitle: Text(l10n.workbenchGuestEnabled),
                      value: _rateEnabled[role] ?? false,
                      onChanged: (value) =>
                          setState(() => _rateEnabled[role] = value),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _rateConsumer[role],
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: l10n.exploreConsumerPrice,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _ratePro[role],
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: l10n.exploreProPrice,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        Text(
          l10n.workbenchFoc,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _focPay,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.workbenchFocPay,
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _focFree,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.workbenchFocFree,
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _optionsDeck(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.workbenchBasePackage,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(l10n.workbenchBasePackageHint),
        Text(_name.text.trim().isEmpty ? '—' : _name.text.trim()),
        const SizedBox(height: 16),
        Text(
          l10n.workbenchAddons,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        for (var i = 0; i < _addons.length; i++)
          _lineCard(l10n, _addons, i),
        OutlinedButton(
          onPressed: () {
            setState(() => _addons.add(_LineEditors()));
          },
          child: Text(l10n.productFormAddOption),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.workbenchIndividuals,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        for (var i = 0; i < _individuals.length; i++)
          _lineCard(l10n, _individuals, i),
        OutlinedButton(
          onPressed: () {
            setState(
              () => _individuals.add(
                _LineEditors(kind: ProductOptionKind.individual),
              ),
            );
          },
          child: Text(l10n.productFormAddOption),
        ),
      ],
    );
  }

  Widget _lineCard(
    AppLocalizations l10n,
    List<_LineEditors> list,
    int index,
  ) {
    final editors = list[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: editors.name,
                decoration: InputDecoration(labelText: l10n.productFormOptionName),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: editors.consumer,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.productFormOptionConsumer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: editors.professional,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.productFormOptionPro,
                      ),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.workbenchBookable),
                value: editors.bookable,
                onChanged: (value) => setState(() => editors.bookable = value),
              ),
              if (list.length > 1)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() => list.removeAt(index).dispose());
                    },
                    child: Text(l10n.productFormRemoveOption),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guestCard(AppLocalizations l10n, DiveShop? hull) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8EE)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.workbenchGuestPreview,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(_name.text.trim().isEmpty ? '—' : _name.text.trim()),
            Text(
              hull?.name ?? '',
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
            Text(_blurb.text.trim()),
            Text(
              _days.length <= 1 ? '1일' : '${_days.length - 1}박 ${_days.length}일',
            ),
          ],
        ),
      ),
    );
  }
}
