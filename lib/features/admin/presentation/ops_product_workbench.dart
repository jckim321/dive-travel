import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dive_travel_app/core/config/r2_config.dart';
import 'package:dive_travel_app/core/constants/gallery_limits.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/booking_quote.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/booking_gallery_editor.dart';
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

class _OpsProductWorkbenchState extends State<OpsProductWorkbench> {
  static const _sectionCount = 6;
  static const _kBoxRadius = 2.0;
  static const _kDirectShop = '__direct__';

  late final TextEditingController _name;
  late final TextEditingController _resortName;
  late final TextEditingController _resortCountry;
  late final TextEditingController _resortRegion;
  late final TextEditingController _blurb;
  late final TextEditingController _meeting;
  late final TextEditingController _detailBody;
  late final TextEditingController _includes;
  late final TextEditingController _excludes;
  late final TextEditingController _cancel;
  late final TextEditingController _focPay;
  late final TextEditingController _focFree;
  final _rateEnabled = <GuestRole, bool>{};
  final _rateConsumer = <GuestRole, TextEditingController>{};
  final _ratePro = <GuestRole, TextEditingController>{};
  final _addons = <_LineEditors>[];
  final _individuals = <_LineEditors>[];
  final _photoPicker = const DivePhotoPicker();
  final _gallery = <BookingGalleryItem>[];
  var _galleryTouched = false;
  final _sectionKeys = List<GlobalKey>.generate(
    _sectionCount,
    (_) => GlobalKey(),
  );
  final _draftListeners = <TextEditingController>[];
  static const _maxGallery = GalleryLimits.maxProductPhotos;
  late String _shopId;
  late String _continent;
  late ProductCategory _category;
  ProductSaveIntent? _savingIntent;
  var _previewDiver = 1;
  var _previewNondiver = 0;
  var _previewChild = 0;
  var _hasNondivers = false;
  var _openEmptySeats = false;
  var _seatOptionId = '';
  var _namedResort = false;
  var _focAppliesTo = GuestRole.diver;
  late final TextEditingController _capacity;
  DateTime? _departureStart;
  DateTime? _flagClosesAt;
  var _packageNights = 0;
  var _datesManual = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _shopId =
        widget.lockedShopId ??
        existing?.shopId ??
        DiveShopCatalog.shops.first.id;
    final shop = DiveShopCatalog.byId(_shopId);
    _continent = existing?.continent.isNotEmpty == true
        ? existing!.continent
        : (shop?.continent ?? ContinentId.asia);
    final rawCategory = existing?.category ?? ProductCategory.resortPackage;
    _category = rawCategory == ProductCategory.liveaboard
        ? ProductCategory.liveaboard
        : ProductCategory.resortPackage;
    _namedResort = _shopId.startsWith('curated-');
    _name = TextEditingController(text: existing?.name ?? '');
    _resortName = TextEditingController(text: shop?.name ?? '');
    _resortCountry = TextEditingController(text: shop?.country ?? '');
    _resortRegion = TextEditingController(text: shop?.location ?? '');
    _blurb = TextEditingController(text: existing?.blurb ?? '');
    final meetingSeed = (existing?.meetingPoint ?? '').trim();
    final addressSeed = (shop?.address ?? '').trim();
    _meeting = TextEditingController(
      text: meetingSeed.isNotEmpty ? meetingSeed : addressSeed,
    );
    _detailBody = TextEditingController(text: _seedDetailBody(existing));
    _cancel = TextEditingController(text: existing?.cancellationNote ?? '');
    _includes = TextEditingController(text: existing?.includes ?? '');
    _excludes = TextEditingController(text: existing?.excludes ?? '');
    _focAppliesTo = existing?.focAppliesTo ?? GuestRole.diver;
    _focPay = TextEditingController(
      text: (existing?.focPayCount ?? 0) > 0 ? '${existing!.focPayCount}' : '',
    );
    _focFree = TextEditingController(
      text: (existing?.focFreeCount ?? 0) > 0
          ? '${existing!.focFreeCount}'
          : '',
    );
    _openEmptySeats = existing?.openEmptySeats ?? false;
    for (final option in existing?.options ?? const <ShopProductOption>[]) {
      if (option.openEmptySeats) {
        _openEmptySeats = true;
        _seatOptionId = option.id;
      }
    }
    _capacity = TextEditingController(
      text: (existing?.capacity ?? 0) > 0 ? '${existing!.capacity}' : '',
    );
    _departureStart = existing?.departureStart;
    _flagClosesAt = existing?.flagClosesAt;
    _packageNights = _parsePackageNights(existing?.durationLabel);
    if (_seatOptionId.isNotEmpty) {
      for (final option in existing?.options ?? const <ShopProductOption>[]) {
        if (option.id == _seatOptionId) {
          _capacity.text = option.capacity > 0 ? '${option.capacity}' : '';
          _departureStart = option.departureStart ?? _departureStart;
          _flagClosesAt = option.flagClosesAt;
        }
      }
    }
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
    _hasNondivers =
        (_rateEnabled[GuestRole.nondiver] ?? false) ||
        (_rateEnabled[GuestRole.child] ?? false);
    for (final option in existing?.options ?? const <ShopProductOption>[]) {
      final line = _LineEditors(
        id: option.id,
        name: option.name,
        description: option.description,
        consumer: option.consumerPrice > 0 ? '${option.consumerPrice}' : '',
        professional: option.professionalPrice > 0
            ? '${option.professionalPrice}'
            : '',
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
    for (final line in [..._addons, ..._individuals]) {
      _watchLine(line);
    }
    _listen(_name);
    _listen(_blurb);
    _listen(_detailBody);
    _listen(_includes);
    _listen(_excludes);
    _listen(_resortName);
    _listen(_rateConsumer[GuestRole.diver]!);
    _listen(_rateConsumer[GuestRole.nondiver]!);
    _listen(_rateConsumer[GuestRole.child]!);
    _seedGallery(existing);
  }

  void _seedGallery(ShopProduct? existing) {
    final urls = [
      for (final url in existing?.photoUrls ?? const <String>[])
        if (url.trim().isNotEmpty) url.trim(),
    ];
    if (urls.isNotEmpty) {
      _gallery.addAll([
        for (final url in urls.take(_maxGallery))
          BookingGalleryItem.remote(url),
      ]);
      return;
    }
    final cover = existing?.coverUrl.trim() ?? '';
    if (cover.isNotEmpty) {
      _gallery.add(BookingGalleryItem.remote(cover));
    }
  }

  void _listen(TextEditingController controller) {
    controller.addListener(_onDraftChanged);
    _draftListeners.add(controller);
  }

  void _watchLine(_LineEditors line) {
    _listen(line.name);
  }

  void _dropLine(_LineEditors line) {
    line.name.removeListener(_onDraftChanged);
    _draftListeners.remove(line.name);
    line.dispose();
  }

  void _onDraftChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (final controller in _draftListeners) {
      controller.removeListener(_onDraftChanged);
    }
    _name.dispose();
    _resortName.dispose();
    _resortCountry.dispose();
    _resortRegion.dispose();
    _blurb.dispose();
    _meeting.dispose();
    _detailBody.dispose();
    _includes.dispose();
    _excludes.dispose();
    _cancel.dispose();
    _focPay.dispose();
    _focFree.dispose();
    _capacity.dispose();
    for (final controller in _rateConsumer.values) {
      controller.dispose();
    }
    for (final controller in _ratePro.values) {
      controller.dispose();
    }
    for (final item in _addons) {
      item.dispose();
    }
    for (final item in _individuals) {
      item.dispose();
    }
    super.dispose();
  }

  static String _seedDetailBody(ShopProduct? existing) {
    final schedule = (existing?.schedule ?? '').trim();
    final days = existing?.itineraryDays ?? const <ItineraryDay>[];
    if (days.isEmpty) {
      return schedule;
    }
    final buf = StringBuffer();
    if (schedule.isNotEmpty) {
      buf.writeln(schedule);
      buf.writeln();
    }
    for (final day in days) {
      final title = day.title.trim();
      final body = day.body.trim();
      if (title.isEmpty && body.isEmpty) {
        continue;
      }
      final heading = title.isEmpty
          ? '### ${day.day}일차'
          : '### ${day.day}일차 — $title';
      buf.writeln(heading);
      if (body.isNotEmpty) {
        buf.writeln(body);
      }
      buf.writeln();
    }
    return buf.toString().trimRight();
  }

  ShopProductOption _withSeatOption(ShopProductOption option) {
    ShopProductOption? previous;
    for (final item
        in widget.existing?.options ?? const <ShopProductOption>[]) {
      if (item.id == option.id) {
        previous = item;
      }
    }
    final chosen = _openEmptySeats && option.id == _resolvedSeatOptionId;
    final carried = previous == null
        ? option
        : option.copyWith(guestRole: previous.guestRole);
    return carried.copyWith(
      openEmptySeats: chosen,
      capacity: chosen ? (int.tryParse(_capacity.text) ?? 0) : 0,
      bookedSeats: previous?.bookedSeats ?? 0,
      flagHolds: previous?.flagHolds ?? const [],
      departureStart: chosen ? _departureStart : null,
      flagClosesAt: chosen ? (_flagClosesAt ?? _departureStart) : null,
      clearDates: !chosen,
    );
  }

  List<DiveShop> get _shopsForContinent {
    return [
      for (final shop in DiveShopCatalog.shops)
        if (shop.continent == _continent) shop,
    ];
  }

  List<ShopGallerySlot> get _gallerySlots => [
    for (final item in _gallery)
      if (item.photo != null)
        ShopGallerySlot(
          bytes: item.photo!.bytes,
          fileName: item.photo!.fileName,
          contentType: item.photo!.contentType,
        )
      else if (item.url != null && item.url!.trim().isNotEmpty)
        ShopGallerySlot(url: item.url),
  ];

  String get _galleryCoverUrl {
    if (_gallery.isEmpty) {
      return '';
    }
    return _gallery.first.url?.trim() ?? '';
  }

  Future<void> _addPhotos() async {
    final remaining = _maxGallery - _gallery.length;
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
          if (_gallery.length >= _maxGallery) {
            break;
          }
          _gallery.add(BookingGalleryItem.local(photo));
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

  void _removePhoto(int index) {
    if (index < 0 || index >= _gallery.length) {
      return;
    }
    setState(() {
      _galleryTouched = true;
      _gallery.removeAt(index);
    });
  }

  void _makeCover(int index) {
    if (index <= 0 || index >= _gallery.length) {
      return;
    }
    setState(() {
      _galleryTouched = true;
      final item = _gallery.removeAt(index);
      _gallery.insert(0, item);
    });
  }

  String get _baseOptionId {
    for (final option
        in widget.existing?.options ?? const <ShopProductOption>[]) {
      if (option.kind == ProductOptionKind.basePackage &&
          option.id.isNotEmpty) {
        return option.id;
      }
    }
    final productId = widget.existing?.id;
    if (productId != null && productId.isNotEmpty) {
      return productId;
    }
    return 'base';
  }

  String get _resolvedSeatOptionId {
    if (_seatOptionId.isEmpty) {
      return '';
    }
    for (final draft in [..._addons, ..._individuals]) {
      if (draft.id == _seatOptionId && draft.name.text.trim().isNotEmpty) {
        return draft.id;
      }
    }
    return '';
  }

  bool get _seatsOnProduct => _openEmptySeats && _resolvedSeatOptionId.isEmpty;

  String get _nightsLabel {
    if (_packageNights <= 0) {
      return '1일';
    }
    return '$_packageNights박 ${_packageNights + 1}일';
  }

  DateTime? get _checkOut {
    final start = _departureStart;
    if (start == null) {
      return null;
    }
    return DateTime(
      start.year,
      start.month,
      start.day,
    ).add(Duration(days: _packageNights));
  }

  static int _parsePackageNights(String? label) {
    final raw = (label ?? '').trim();
    if (raw.isEmpty) {
      return 0;
    }
    final nightsMatch = RegExp(r'(\d+)\s*박').firstMatch(raw);
    if (nightsMatch != null) {
      return int.tryParse(nightsMatch.group(1)!) ?? 0;
    }
    final daysMatch = RegExp(r'(\d+)\s*일').firstMatch(raw);
    if (daysMatch != null) {
      final days = int.tryParse(daysMatch.group(1)!) ?? 1;
      return days <= 1 ? 0 : days - 1;
    }
    return 0;
  }

  void _setPackageNights(int nights) {
    setState(() {
      _packageNights = nights < 0 ? 0 : nights;
      _datesManual = false;
    });
  }

  void _setCheckIn(DateTime day) {
    setState(() {
      _departureStart = DateTime(day.year, day.month, day.day);
      _datesManual = false;
    });
  }

  void _setCheckOut(DateTime day) {
    final start = _departureStart;
    if (start == null) {
      setState(() {
        _departureStart = DateTime(day.year, day.month, day.day);
        _packageNights = 0;
        _datesManual = true;
      });
      return;
    }
    final checkIn = DateTime(start.year, start.month, start.day);
    final checkOut = DateTime(day.year, day.month, day.day);
    var nights = checkOut.difference(checkIn).inDays;
    if (nights < 0) {
      nights = 0;
    }
    setState(() {
      _packageNights = nights;
      _datesManual = true;
    });
  }

  Future<void> _pickStayDate({required bool checkout}) async {
    final initial = checkout
        ? (_checkOut ?? _departureStart ?? DateTime.now())
        : (_departureStart ?? DateTime.now());
    final first = checkout && _departureStart != null
        ? _departureStart!
        : DateTime.now().subtract(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null) {
      return;
    }
    if (checkout) {
      _setCheckOut(picked);
    } else {
      _setCheckIn(picked);
    }
  }

  String _fmtDay(DateTime? day) {
    if (day == null) {
      return '—';
    }
    return DateFormat('yyyy.MM.dd').format(day);
  }

  String _continentLabel(AppLocalizations l10n, String id) {
    return switch (id) {
      ContinentId.asia => l10n.exploreContinentAsia,
      ContinentId.africa => l10n.exploreContinentAfrica,
      ContinentId.oceania => l10n.exploreContinentOceania,
      ContinentId.americas => l10n.exploreContinentAmericas,
      ContinentId.europe => l10n.exploreContinentEurope,
      ContinentId.polar => l10n.exploreContinentPolar,
      _ => id,
    };
  }

  String _roleLabel(AppLocalizations l10n, GuestRole role) {
    return switch (role) {
      GuestRole.diver => l10n.workbenchGuestDiver,
      GuestRole.nondiver => l10n.workbenchGuestNondiver,
      GuestRole.child => l10n.workbenchGuestChild,
      GuestRole.infant => l10n.workbenchGuestInfant,
    };
  }

  void _reveal(int index) {
    final target = _sectionKeys[index].currentContext;
    if (target == null) {
      return;
    }
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 280),
      alignment: 0.04,
    );
  }

  ProductListingKind _shelfKindForSave(ShopProduct? existing) {
    final current = existing?.listingKind;
    if (current != null && current != ProductListingKind.exploreOnly) {
      return current;
    }
    if (_namedResort) {
      return ProductListingKind.curated;
    }
    return ProductListingKind.exploreOnly;
  }

  DateTime? _featuredAtForSave(ShopProduct? existing) {
    final kind = _shelfKindForSave(existing);
    if (!kind.isHomeShelf) {
      return existing?.featuredAt;
    }
    return existing?.featuredAt ?? DateTime.now();
  }

  Future<void> _save(ProductSaveIntent intent) async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (_savingIntent != null) {
      return;
    }
    if (name.isEmpty) {
      _reveal(0);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.workbenchNeedName)));
      return;
    }
    if (_namedResort && _resortName.text.trim().isEmpty) {
      _reveal(1);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.productFormCuratedResort)));
      return;
    }
    if (_openEmptySeats &&
        ((int.tryParse(_capacity.text) ?? 0) <= 0 || _departureStart == null)) {
      _reveal(5);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.workbenchOpenSeatsNeedFields)),
      );
      return;
    }
    setState(() => _savingIntent = intent);
    try {
      final store = DiverStoreScope.of(context);
      final sessionUid = store.uid ?? '';
      final existing = widget.existing;
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
            enabled: switch (role) {
              GuestRole.diver => true,
              GuestRole.nondiver || GuestRole.child => _hasNondivers,
              GuestRole.infant => false,
            },
            consumer: int.tryParse(_rateConsumer[role]!.text) ?? 0,
            professional: int.tryParse(_ratePro[role]!.text) ?? 0,
          ),
      ];
      final options = <ShopProductOption>[
        ShopProductOption(
          id: _baseOptionId,
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
      var shopId = _shopId;
      if (_namedResort) {
        if (!shopId.startsWith('curated-')) {
          shopId = 'curated-${DateTime.now().millisecondsSinceEpoch}';
          _shopId = shopId;
        }
        final region = _resortRegion.text.trim();
        await store.saveShopProfile(
          shopId: shopId,
          name: _resortName.text.trim(),
          location: region.isEmpty ? _resortName.text.trim() : region,
          productName: name,
          consumerPrice: diverRate.consumer,
          professionalPrice: diverRate.professional,
          continent: _continent,
          country: _resortCountry.text.trim(),
          address: _meeting.text.trim(),
          curated: true,
          intro: _blurb.text.trim(),
        );
      }
      await store.saveShopProduct(
        shopId: shopId,
        product: ShopProduct(
          id: existing?.id ?? 'p-${DateTime.now().millisecondsSinceEpoch}',
          shopId: shopId,
          name: name,
          consumerPrice: diverRate.consumer,
          professionalPrice: diverRate.professional,
          active: existing?.active ?? true,
          blurb: _blurb.text.trim(),
          durationLabel: _nightsLabel,
          coverUrl: _galleryCoverUrl,
          continent: _continent,
          meetingPoint: _meeting.text.trim(),
          schedule: _detailBody.text.trim(),
          includes: _includes.text.trim(),
          excludes: _excludes.text.trim(),
          difficulty: '',
          minGuests: 0,
          maxGuests: 0,
          cancellationNote: _cancel.text.trim(),
          category: _category,
          detail: existing?.detail ?? '',
          photoUrls: [
            for (final item in _gallery)
              if (item.url != null && item.url!.isNotEmpty) item.url!,
          ],
          itineraryDays: const [],
          guestRates: guestRates,
          focPayCount: int.tryParse(_focPay.text) ?? 0,
          focFreeCount: int.tryParse(_focFree.text) ?? 0,
          focAppliesTo: _focAppliesTo,
          openEmptySeats: _seatsOnProduct,
          capacity: _seatsOnProduct ? (int.tryParse(_capacity.text) ?? 0) : 0,
          bookedSeats: existing?.bookedSeats ?? 0,
          flagHolds: existing?.flagHolds ?? const [],
          departureStart: _departureStart,
          flagClosesAt: _seatsOnProduct
              ? (_flagClosesAt ?? _departureStart)
              : null,
          options: [for (final option in options) _withSeatOption(option)],
          listingKind: _shelfKindForSave(existing),
          featuredAt: _featuredAtForSave(existing),
          publishStatus:
              existing?.publishStatus ?? ProductPublishStatus.approved,
          submittedAt: existing?.submittedAt,
          reviewedAt: existing?.reviewedAt,
          reviewNote: existing?.reviewNote ?? '',
          submittedByUid: existing?.submittedByUid.isNotEmpty == true
              ? existing!.submittedByUid
              : sessionUid,
        ),
        gallery: _gallerySlots,
        useAsResortCover: existing == null || _galleryTouched,
        creatorSubmission: false,
        submitterUid: sessionUid,
        intent: intent,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_savedMessage(l10n, intent))));
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
        setState(() => _savingIntent = null);
      }
    }
  }

  Future<void> _pickDay({required bool isFlag}) async {
    final initial = isFlag
        ? (_flagClosesAt ?? _departureStart ?? DateTime.now())
        : (_departureStart ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isFlag) {
        _flagClosesAt = picked;
      } else {
        _departureStart = picked;
      }
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
    final store = DiverStoreScope.of(context);
    final canPublish = store.stats.isAdmin && !widget.partnerMode;
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        title: Text(l10n.briefTitle),
        backgroundColor: AppTheme.canvas,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final brief = _brief(l10n, shops, shopLocked);
          return Column(
            children: [
              Expanded(
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: brief),
                          SizedBox(
                            width: 280,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 12, 16, 12),
                              child: _guestCard(l10n, hull),
                            ),
                          ),
                        ],
                      )
                    : brief,
              ),
              _saveBar(l10n, canPublish: canPublish),
            ],
          );
        },
      ),
    );
  }

  String _savedMessage(AppLocalizations l10n, ProductSaveIntent intent) {
    return switch (intent) {
      ProductSaveIntent.keepEditing => l10n.briefKept,
      ProductSaveIntent.submitForReview => l10n.adminProductSubmitted,
      ProductSaveIntent.publish => l10n.adminProductApproved,
      ProductSaveIntent.takeDown => l10n.briefTakenDown,
    };
  }

  String _intentLabel(AppLocalizations l10n, ProductSaveIntent intent) {
    return switch (intent) {
      ProductSaveIntent.keepEditing => l10n.briefKeepEditing,
      ProductSaveIntent.submitForReview => l10n.briefSubmitReview,
      ProductSaveIntent.publish => l10n.briefPublishNow,
      ProductSaveIntent.takeDown => l10n.briefTakeDown,
    };
  }

  Widget _saveBar(AppLocalizations l10n, {required bool canPublish}) {
    final intents = <ProductSaveIntent>[
      ProductSaveIntent.keepEditing,
      ProductSaveIntent.submitForReview,
      if (canPublish) ProductSaveIntent.publish,
      if (widget.existing != null) ProductSaveIntent.takeDown,
    ];
    final primary = canPublish
        ? ProductSaveIntent.publish
        : ProductSaveIntent.submitForReview;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final intent in intents) ...[
              _intentButton(l10n, intent, filled: intent == primary),
              if (intent != intents.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _intentButton(
    AppLocalizations l10n,
    ProductSaveIntent intent, {
    required bool filled,
  }) {
    final busy = _savingIntent != null;
    final label = _savingIntent == intent
        ? l10n.exploreSaving
        : _intentLabel(l10n, intent);
    final onPressed = busy ? null : () => _save(intent);
    final key = switch (intent) {
      ProductSaveIntent.publish => const Key('admin-product-submit'),
      ProductSaveIntent.submitForReview => const Key('partner-product-save'),
      ProductSaveIntent.keepEditing => const Key('brief-keep-editing'),
      ProductSaveIntent.takeDown => const Key('brief-take-down'),
    };
    if (filled) {
      return FilledButton(
        key: key,
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: AppTheme.navy,
        ),
        child: Text(label),
      );
    }
    return OutlinedButton(
      key: key,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      child: Text(label),
    );
  }

  Widget _brief(
    AppLocalizations l10n,
    List<DiveShop> shops,
    bool shopLocked,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _block(0, l10n.briefSectionCover, [_coverBlock(l10n)]),
        _block(1, l10n.briefSectionPlace, [
          _placeBlock(l10n, shops, shopLocked),
        ]),
        _block(2, l10n.briefSectionDays, [_detailBlock(l10n)]),
        _block(3, l10n.briefSectionTerms, [_bookingEntryBlock(l10n)]),
        _block(4, l10n.briefSectionPrice, [_priceBlock(l10n)]),
        _block(5, l10n.briefSectionSeats, [_seatsBlock(l10n)]),
      ],
    );
  }

  Widget _block(int index, String title, List<Widget> children) {
    return KeyedSubtree(
      key: _sectionKeys[index],
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: BookingFormSection(
          step: '${index + 1}',
          title: title,
          borderRadius: _kBoxRadius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }

  InputDecoration _field(String label, {String? hint, int? lines}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kBoxRadius),
      borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: (lines ?? 1) > 1,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kBoxRadius),
        borderSide: const BorderSide(color: AppTheme.navy, width: 1.6),
      ),
    );
  }

  Widget _coverBlock(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.workbenchCategory),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _CategoryPick(
                label: l10n.workbenchCatResort,
                icon: Icons.apartment_outlined,
                selected: _category == ProductCategory.resortPackage,
                onTap: () => setState(
                  () => _category = ProductCategory.resortPackage,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CategoryPick(
                label: l10n.workbenchCatLiveaboard,
                icon: Icons.directions_boat_outlined,
                selected: _category == ProductCategory.liveaboard,
                onTap: () => setState(
                  () => _category = ProductCategory.liveaboard,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _photoBlock(l10n),
      ],
    );
  }

  Widget _photoBlock(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.exploreCoverPhotoHint,
          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
        if (!R2Config.canPersistListingPhotos)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.productFormPhotoHint,
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
          ),
        const SizedBox(height: 12),
        BookingGalleryEditor(
          items: _gallery,
          onAdd: _addPhotos,
          onRemove: _removePhoto,
          onMakeCover: _makeCover,
          maxItems: _maxGallery,
          cornerRadius: _kBoxRadius,
          attachKey: const Key('brief-gallery-add'),
        ),
      ],
    );
  }

  void _applyCatalogShop(String shopId, {required DiverStore store}) {
    final next = DiveShopCatalog.byId(shopId);
    final live = store.liveStatsFor(shopId);
    _shopId = shopId;
    _namedResort = false;
    if (next != null) {
      _continent = next.continent;
      if (_resortName.text.trim().isEmpty) {
        _resortName.text = next.name;
      }
      if (_resortCountry.text.trim().isEmpty) {
        _resortCountry.text = next.country;
      }
      if (_resortRegion.text.trim().isEmpty) {
        _resortRegion.text = next.location;
      }
    }
    final address = (live?.address ?? next?.address ?? '').trim();
    if (address.isNotEmpty) {
      _meeting.text = address;
    }
  }

  Future<void> _openDestinationMap(AppLocalizations l10n) async {
    final query = _meeting.text.trim();
    if (query.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exploreResortAddress)),
      );
      return;
    }
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(query)}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.workbenchOpenMap)),
      );
    }
  }

  Widget _destinationMapCard(AppLocalizations l10n) {
    final address = _meeting.text.trim();
    final location = [
      if (_resortRegion.text.trim().isNotEmpty) _resortRegion.text.trim(),
      if (_resortCountry.text.trim().isNotEmpty) _resortCountry.text.trim(),
    ].join(', ');
    final label = address.isNotEmpty
        ? address
        : (location.isNotEmpty ? location : l10n.exploreResortAddress);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.oceanDeep,
        borderRadius: BorderRadius.circular(_kBoxRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place_outlined, color: AppTheme.gold, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: address.isEmpty
                    ? null
                    : () => _openDestinationMap(l10n),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFF4EBD3),
                  disabledForegroundColor: Colors.white38,
                ),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: Text(l10n.workbenchOpenMap),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeBlock(
    AppLocalizations l10n,
    List<DiveShop> shops,
    bool shopLocked,
  ) {
    final store = DiverStoreScope.of(context);
    final shopValue = shopLocked
        ? _shopId
        : (_namedResort
              ? _kDirectShop
              : (shops.any((shop) => shop.id == _shopId)
                    ? _shopId
                    : (shops.isNotEmpty ? shops.first.id : _kDirectShop)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(
            shopLocked
                ? 'shop-locked-$_shopId'
                : 'shop-$_continent-$_namedResort-$_shopId',
          ),
          initialValue: shopValue,
          decoration: _field(l10n.productFormShopHint),
          items: [
            if (!shopLocked)
              DropdownMenuItem(
                value: _kDirectShop,
                child: Text(l10n.productFormDirectSelect),
              ),
            for (final shop in shops)
              DropdownMenuItem(value: shop.id, child: Text(shop.name)),
          ],
          onChanged: shopLocked
              ? null
              : (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    if (value == _kDirectShop) {
                      final current = DiveShopCatalog.byId(_shopId);
                      _namedResort = true;
                      if (_resortName.text.trim().isEmpty) {
                        _resortName.text = current?.name ?? '';
                      }
                      if (_resortCountry.text.trim().isEmpty) {
                        _resortCountry.text = current?.country ?? '';
                      }
                      if (_resortRegion.text.trim().isEmpty) {
                        _resortRegion.text = current?.location ?? '';
                      }
                      return;
                    }
                    _applyCatalogShop(value, store: store);
                  });
                },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _continent,
          decoration: _field(l10n.productFormContinent),
          items: [
            for (final id in ContinentId.all)
              DropdownMenuItem(
                value: id,
                child: Text(_continentLabel(l10n, id)),
              ),
          ],
          onChanged: shopLocked
              ? null
              : (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _continent = value;
                    if (_namedResort) {
                      return;
                    }
                    final filtered = _shopsForContinent;
                    if (filtered.isNotEmpty &&
                        !filtered.any((shop) => shop.id == _shopId)) {
                      _applyCatalogShop(filtered.first.id, store: store);
                    }
                  });
                },
        ),
        const SizedBox(height: 12),
        TextField(
          key: Key(
            widget.partnerMode ? 'partner-product-name' : 'admin-product-name',
          ),
          controller: _name,
          decoration: _field(l10n.partnerDefaultProduct),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _blurb,
          decoration: _field(
            l10n.productFormSubtitle,
            hint: l10n.productFormSubtitleHint,
          ),
        ),
        if (_namedResort) ...[
          const SizedBox(height: 12),
          TextField(
            key: const Key('product-curated-resort'),
            controller: _resortName,
            decoration: _field(
              l10n.productFormCuratedResort,
              hint: l10n.productFormCuratedResortHint,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _resortCountry,
            decoration: _field(
              l10n.productFormCuratedCountry,
              hint: l10n.productFormCuratedCountryHint,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _resortRegion,
            decoration: _field(
              l10n.productFormCuratedLocation,
              hint: l10n.productFormCuratedLocationHint,
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _meeting,
          onChanged: (_) => setState(() {}),
          decoration: _field(
            l10n.exploreResortAddress,
            hint: l10n.productFormMeetingHint,
          ),
        ),
        const SizedBox(height: 12),
        _destinationMapCard(l10n),
      ],
    );
  }

  Widget _detailBlock(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _nightsLabel,
          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        _ProductDetailComposer(
          controller: _detailBody,
          decoration: _field(
            l10n.briefSectionDays,
            hint: l10n.detailComposerHint,
            lines: 10,
          ),
          onChanged: () => setState(() {}),
        ),
      ],
    );
  }

  BookingQuote get _previewQuote {
    return BookingQuote.compute(
      product: _draftProduct,
      professional: false,
      divers: _previewDiver,
      nondivers: _hasNondivers ? _previewNondiver : 0,
      children: _hasNondivers ? _previewChild : 0,
      infants: 0,
      bookPackage: true,
      selectedOptionIds: const {},
    );
  }

  void _setHasNondivers(bool value) {
    setState(() {
      _hasNondivers = value;
      _rateEnabled[GuestRole.nondiver] = value;
      _rateEnabled[GuestRole.child] = value;
      _rateEnabled[GuestRole.infant] = false;
      if (!value) {
        _previewNondiver = 0;
        _previewChild = 0;
      }
    });
  }

  Widget _bookingEntryBlock(AppLocalizations l10n) {
    final packageName = _name.text.trim().isEmpty ? '—' : _name.text.trim();
    final quote = _previewQuote;
    final days = _packageNights + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.bookingEntryBasePackage,
          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          packageName,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.bookingEntryStayLength,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _stayStepper(
                label: l10n.bookingEntryNights(_packageNights),
                value: _packageNights,
                min: 0,
                onChanged: _setPackageNights,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.bookingEntryDays(days),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        Text(
          _nightsLabel,
          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.bookingEntryCheckIn),
          subtitle: Text(
            _departureStart == null
                ? l10n.bookingEntryPickDate
                : _fmtDay(_departureStart),
          ),
          trailing: const Icon(Icons.calendar_today_outlined),
          onTap: () => _pickStayDate(checkout: false),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          enabled: _departureStart != null,
          title: Text(l10n.bookingEntryCheckOut),
          subtitle: Text(
            _checkOut == null
                ? l10n.bookingEntryPickDate
                : _fmtDay(_checkOut),
          ),
          trailing: Icon(
            _datesManual ? Icons.edit_calendar_outlined : Icons.event_available_outlined,
          ),
          onTap: _departureStart == null
              ? null
              : () => _pickStayDate(checkout: true),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () {
              setState(() {
                _datesManual = !_datesManual;
                if (!_datesManual && _departureStart != null) {
                  // snap checkout back to nights rule (already derived)
                }
              });
            },
            child: Text(
              _datesManual
                  ? '$_nightsLabel · ${l10n.bookingEntryChangeDates}'
                  : l10n.bookingEntryChangeDates,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _rateConsumer[GuestRole.diver],
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _field(l10n.bookingEntryDiverPrice),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _includes,
          minLines: 3,
          maxLines: 6,
          decoration: _field(
            l10n.productFormIncludes,
            hint: l10n.productFormIncludesHint,
            lines: 3,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _excludes,
          minLines: 3,
          maxLines: 6,
          decoration: _field(
            l10n.productFormExcludes,
            hint: l10n.productFormExcludesHint,
            lines: 3,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.checkoutGuests,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        _guestStepperRow(
          label: l10n.workbenchGuestDiver,
          value: _previewDiver,
          onChanged: (v) => setState(() => _previewDiver = v < 1 ? 1 : v),
          priceLabel: l10n.bookingEntryUnitPrice,
          priceText:
              _rateConsumer[GuestRole.diver]!.text.trim().isEmpty
              ? '—'
              : _rateConsumer[GuestRole.diver]!.text.trim(),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_kBoxRadius),
            border: Border.all(color: const Color(0xFFE2E8EE)),
          ),
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                title: Text(l10n.bookingEntryHasNondivers),
                value: _hasNondivers,
                onChanged: _setHasNondivers,
              ),
              if (_hasNondivers) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    children: [
                      _guestStepperRow(
                        label: l10n.bookingEntryAdultNondiver,
                        value: _previewNondiver,
                        onChanged: (v) =>
                            setState(() => _previewNondiver = v),
                        priceField: _rateConsumer[GuestRole.nondiver],
                        priceLabel: l10n.bookingEntryUnitPrice,
                      ),
                      const SizedBox(height: 10),
                      _guestStepperRow(
                        label: l10n.bookingEntryChildInfant,
                        value: _previewChild,
                        onChanged: (v) => setState(() => _previewChild = v),
                        priceField: _rateConsumer[GuestRole.child],
                        priceLabel: l10n.bookingEntryUnitPrice,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.checkoutTotal('${quote.total}'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.bookingEntryPreviewSnack)),
              );
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppTheme.navy,
            ),
            child: Text(l10n.exploreBook),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _cancel,
          maxLines: 2,
          decoration: _field(
            l10n.productFormCancelNote,
            hint: l10n.productFormCancelHint,
            lines: 2,
          ),
        ),
      ],
    );
  }

  Widget _stayStepper({
    required String label,
    required int value,
    required int min,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        IconButton(
          onPressed: value <= min ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove_circle_outline, size: 22),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline, size: 22),
        ),
      ],
    );
  }

  Widget _guestStepperRow({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    String? priceLabel,
    String? priceText,
    TextEditingController? priceField,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        IconButton(
          onPressed: value <= 0 ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove_circle_outline, size: 22),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline, size: 22),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: priceField != null
              ? TextField(
                  controller: priceField,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: priceLabel,
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (_) => setState(() {}),
                )
              : Text(
                  priceText ?? '',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.muted,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _priceBlock(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final role in GuestRole.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_kBoxRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_roleLabel(l10n, role)),
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
                decoration: _field(l10n.workbenchFocPay),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _focFree,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _field(l10n.workbenchFocFree),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<GuestRole>(
          key: ValueKey('foc-$_focAppliesTo'),
          initialValue: _focAppliesTo,
          decoration: _field(l10n.briefFocApplies),
          items: [
            for (final role in GuestRole.values)
              DropdownMenuItem(
                value: role,
                child: Text(_roleLabel(l10n, role)),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _focAppliesTo = value);
            }
          },
        ),
        const SizedBox(height: 16),
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
        for (var i = 0; i < _addons.length; i++) _lineCard(l10n, _addons, i),
        OutlinedButton(
          onPressed: () {
            final line = _LineEditors(kind: ProductOptionKind.addon);
            _watchLine(line);
            setState(() => _addons.add(line));
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
            final line = _LineEditors(kind: ProductOptionKind.individual);
            _watchLine(line);
            setState(() => _individuals.add(line));
          },
          child: Text(l10n.productFormAddOption),
        ),
      ],
    );
  }

  Widget _lineCard(AppLocalizations l10n, List<_LineEditors> list, int index) {
    final editors = list[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_kBoxRadius),
          border: Border.all(color: const Color(0xFFE7E7E7)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: editors.name,
                decoration: InputDecoration(
                  labelText: l10n.productFormOptionName,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: editors.description,
                decoration: InputDecoration(
                  labelText: l10n.productFormOptionDesc,
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
                      final line = list.removeAt(index);
                      setState(() => _dropLine(line));
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

  Widget _seatsBlock(AppLocalizations l10n) {
    final named = [
      for (final draft in [..._addons, ..._individuals])
        if (draft.name.text.trim().isNotEmpty) draft,
    ];
    final seatValue = _resolvedSeatOptionId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          key: const Key('product-open-empty-seats'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.briefOpenSeats),
          subtitle: Text(l10n.workbenchOpenSeatsHint),
          value: _openEmptySeats,
          onChanged: (value) => setState(() => _openEmptySeats = value),
        ),
        if (_openEmptySeats) ...[
          DropdownButtonFormField<String>(
            key: ValueKey(
              'seat-$seatValue-${named.map((d) => d.id).join(',')}',
            ),
            initialValue: seatValue,
            decoration: _field(l10n.workbenchSeatOption),
            items: [
              DropdownMenuItem(value: '', child: Text(l10n.workbenchSeatBase)),
              for (final draft in named)
                DropdownMenuItem(
                  value: draft.id,
                  child: Text(draft.name.text.trim()),
                ),
            ],
            onChanged: (value) => setState(() => _seatOptionId = value ?? ''),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _capacity,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _field(l10n.workbenchSeatCount),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.workbenchDepartureDate),
            subtitle: Text(
              _departureStart == null
                  ? '—'
                  : DateFormat('yyyy.MM.dd').format(_departureStart!),
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () => _pickDay(isFlag: false),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.workbenchFlagDeadline),
            subtitle: Text(
              _flagClosesAt == null
                  ? '—'
                  : DateFormat('yyyy.MM.dd').format(_flagClosesAt!),
            ),
            trailing: const Icon(Icons.flag_outlined),
            onTap: () => _pickDay(isFlag: true),
          ),
        ],
      ],
    );
  }

  ShopProduct get _draftProduct {
    return ShopProduct(
      id: 'draft',
      shopId: _shopId,
      name: _name.text.trim().isEmpty ? '—' : _name.text.trim(),
      consumerPrice: int.tryParse(_rateConsumer[GuestRole.diver]!.text) ?? 0,
      professionalPrice: int.tryParse(_ratePro[GuestRole.diver]!.text) ?? 0,
      blurb: _blurb.text.trim(),
      durationLabel: _nightsLabel,
      guestRates: [
        for (final role in GuestRole.values)
          GuestRate(
            role: role,
            enabled: switch (role) {
              GuestRole.diver => true,
              GuestRole.nondiver || GuestRole.child => _hasNondivers,
              GuestRole.infant => false,
            },
            consumer: int.tryParse(_rateConsumer[role]!.text) ?? 0,
            professional: int.tryParse(_ratePro[role]!.text) ?? 0,
          ),
      ],
      focPayCount: int.tryParse(_focPay.text) ?? 0,
      focFreeCount: int.tryParse(_focFree.text) ?? 0,
      focAppliesTo: _focAppliesTo,
    );
  }

  Widget _guestCard(AppLocalizations l10n, DiveShop? hull) {
    final quote = _previewQuote;
    final resort = _namedResort
        ? (_resortName.text.trim().isEmpty ? '—' : _resortName.text.trim())
        : (hull?.name ?? '');
    final start = int.tryParse(_rateConsumer[GuestRole.diver]!.text) ?? 0;
    final cover = _gallery.isEmpty ? null : _gallery.first;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kBoxRadius),
        border: Border.all(color: const Color(0xFFE2E8EE)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.briefGuestCard,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (cover != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(_kBoxRadius),
                child: SizedBox(
                  height: 96,
                  width: double.infinity,
                  child: cover.photo != null
                      ? Image.memory(cover.photo!.bytes, fit: BoxFit.cover)
                      : Image.network(cover.url!, fit: BoxFit.cover),
                ),
              ),
            if (cover != null) const SizedBox(height: 8),
            Text(_name.text.trim().isEmpty ? '—' : _name.text.trim()),
            Text(
              resort,
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
            Text(_nightsLabel),
            if (_departureStart != null)
              Text(
                l10n.bookingEntryStayRange(
                  _fmtDay(_departureStart),
                  _fmtDay(_checkOut),
                ),
                style: const TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
            if (_blurb.text.trim().isNotEmpty) Text(_blurb.text.trim()),
            const SizedBox(height: 8),
            Text(
              '${l10n.briefStartPrice} $start',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.workbenchGuestDiver} $_previewDiver'
              '${_hasNondivers && _previewNondiver > 0 ? ' · ${l10n.workbenchGuestNondiver} $_previewNondiver' : ''}'
              '${_hasNondivers && _previewChild > 0 ? ' · ${l10n.bookingEntryChildInfant} $_previewChild' : ''}',
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.checkoutTotal('${quote.total}'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.briefSectionTerms,
              style: const TextStyle(color: AppTheme.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductDetailComposer extends StatefulWidget {
  const _ProductDetailComposer({
    required this.controller,
    required this.decoration,
    this.onChanged,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final VoidCallback? onChanged;

  @override
  State<_ProductDetailComposer> createState() => _ProductDetailComposerState();
}

class _ProductDetailComposerState extends State<_ProductDetailComposer> {
  final _focus = FocusNode();
  var _preview = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged?.call();
    setState(() {});
  }

  void _insert(String snippet, {int? cursorOffset}) {
    final value = widget.controller.value;
    final text = value.text;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final next = text.replaceRange(start, end, snippet);
    final caret = start + (cursorOffset ?? snippet.length);
    widget.controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: caret.clamp(0, next.length)),
    );
    _focus.requestFocus();
    _notify();
  }

  void _wrapSelection(String left, String right) {
    final value = widget.controller.value;
    final selection = value.selection;
    if (!selection.isValid) {
      _insert('$left$right', cursorOffset: left.length);
      return;
    }
    final selected = selection.textInside(value.text);
    if (selected.isEmpty) {
      _insert('$left$right', cursorOffset: left.length);
      return;
    }
    final wrapped = '$left$selected$right';
    final start = selection.start;
    final next = value.text.replaceRange(selection.start, selection.end, wrapped);
    widget.controller.value = TextEditingValue(
      text: next,
      selection: TextSelection(
        baseOffset: start,
        extentOffset: start + wrapped.length,
      ),
    );
    _focus.requestFocus();
    _notify();
  }

  void _prefixLine(String prefix) {
    final value = widget.controller.value;
    final text = value.text;
    final selection = value.selection;
    final offset = selection.isValid ? selection.start : text.length;
    final lineStart = text.lastIndexOf('\n', offset <= 0 ? 0 : offset - 1) + 1;
    final next = text.replaceRange(lineStart, lineStart, prefix);
    final caret = offset + prefix.length;
    widget.controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: caret.clamp(0, next.length)),
    );
    _focus.requestFocus();
    _notify();
  }

  int _nextDayNumber() {
    var maxDay = 0;
    for (final match in RegExp(
      r'^###\s+(\d+)',
      multiLine: true,
    ).allMatches(widget.controller.text)) {
      final n = int.tryParse(match.group(1) ?? '') ?? 0;
      if (n > maxDay) {
        maxDay = n;
      }
    }
    return maxDay + 1;
  }

  static const _tableSchedule = '| 시간 | 내용 |\n| --- | --- |\n|  |  |\n|  |  |\n';
  static const _tableInclude =
      '| 포함 | 불포함 |\n| --- | --- |\n|  |  |\n|  |  |\n';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(
              _OpsProductWorkbenchState._kBoxRadius,
            ),
            border: Border.all(color: const Color(0xFFE2E8EE)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Wrap(
              spacing: 2,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  tooltip: l10n.detailComposerBold,
                  onPressed: _preview
                      ? null
                      : () => _wrapSelection('**', '**'),
                  icon: const Icon(Icons.format_bold, size: 20),
                ),
                IconButton(
                  tooltip: l10n.detailComposerHeading,
                  onPressed: _preview ? null : () => _prefixLine('### '),
                  icon: const Icon(Icons.title, size: 20),
                ),
                IconButton(
                  tooltip: l10n.detailComposerList,
                  onPressed: _preview ? null : () => _prefixLine('- '),
                  icon: const Icon(Icons.format_list_bulleted, size: 20),
                ),
                PopupMenuButton<String>(
                  tooltip: l10n.detailComposerTable,
                  enabled: !_preview,
                  onSelected: (value) {
                    if (value == 'schedule') {
                      _insert('\n$_tableSchedule\n');
                    } else {
                      _insert('\n$_tableInclude\n');
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'schedule',
                      child: Text(l10n.detailComposerTableSchedule),
                    ),
                    PopupMenuItem(
                      value: 'include',
                      child: Text(l10n.detailComposerTableInclude),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.table_chart_outlined,
                          size: 20,
                          color: _preview ? Colors.black26 : null,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.detailComposerTable,
                          style: TextStyle(
                            fontSize: 12,
                            color: _preview ? Colors.black26 : AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _preview
                      ? null
                      : () {
                          final day = _nextDayNumber();
                          final block = widget.controller.text.trim().isEmpty
                              ? '### $day일차 — \n'
                              : '\n### $day일차 — \n';
                          _insert(block, cursorOffset: block.length);
                        },
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(l10n.detailComposerDay),
                ),
                TextButton(
                  onPressed: () => setState(() => _preview = !_preview),
                  child: Text(
                    _preview
                        ? l10n.detailComposerEdit
                        : l10n.detailComposerPreview,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_preview)
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                _OpsProductWorkbenchState._kBoxRadius,
              ),
              border: Border.all(color: const Color(0xFFE2E8EE)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: MarkdownBody(
                data: widget.controller.text.trim().isEmpty
                    ? l10n.detailComposerHint
                    : widget.controller.text,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                    .copyWith(
                      p: const TextStyle(
                        color: Color(0xFF344054),
                        height: 1.45,
                        fontSize: 14,
                      ),
                    ),
              ),
            ),
          )
        else
          TextField(
            controller: widget.controller,
            focusNode: _focus,
            minLines: 10,
            maxLines: 24,
            onChanged: (_) => _notify(),
            decoration: widget.decoration.copyWith(
              alignLabelWithHint: true,
            ),
          ),
      ],
    );
  }
}

class _CategoryPick extends StatelessWidget {
  const _CategoryPick({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? const BorderSide(color: AppTheme.navy, width: 1.8)
        : const BorderSide(color: Color(0xFFD0D5DD));
    final bg = selected ? const Color(0xFFEEF2F7) : Colors.white;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(
        _OpsProductWorkbenchState._kBoxRadius,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          _OpsProductWorkbenchState._kBoxRadius,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              _OpsProductWorkbenchState._kBoxRadius,
            ),
            border: Border.fromBorderSide(border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: selected ? AppTheme.navy : AppTheme.muted,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: selected ? AppTheme.navy : const Color(0xFF344054),
                ),
              ),
              if (selected) ...[
                const SizedBox(height: 6),
                const Icon(Icons.check_circle, size: 16, color: AppTheme.navy),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

