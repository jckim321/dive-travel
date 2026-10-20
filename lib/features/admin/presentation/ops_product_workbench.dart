import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/config/r2_config.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/booking_quote.dart';
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

class _TextLines {
  _TextLines(String raw) {
    final parts = [
      for (final line in raw.split('\n'))
        if (line.trim().isNotEmpty) line.trim(),
    ];
    if (parts.isEmpty) {
      items.add(TextEditingController());
    } else {
      for (final part in parts) {
        items.add(TextEditingController(text: part));
      }
    }
  }

  final items = <TextEditingController>[];

  String join() {
    return [
      for (final item in items)
        if (item.text.trim().isNotEmpty) item.text.trim(),
    ].join('\n');
  }

  void dispose() {
    for (final item in items) {
      item.dispose();
    }
  }
}

class _OpsProductWorkbenchState extends State<OpsProductWorkbench> {
  static const _sectionCount = 6;

  late final TextEditingController _name;
  late final TextEditingController _resortName;
  late final TextEditingController _resortCountry;
  late final TextEditingController _resortRegion;
  late final TextEditingController _blurb;
  late final TextEditingController _meeting;
  late final TextEditingController _schedule;
  late final TextEditingController _difficulty;
  late final TextEditingController _minGuests;
  late final TextEditingController _maxGuests;
  late final TextEditingController _cancel;
  late final TextEditingController _focPay;
  late final TextEditingController _focFree;
  late final _TextLines _includes;
  late final _TextLines _excludes;
  final _rateEnabled = <GuestRole, bool>{};
  final _rateConsumer = <GuestRole, TextEditingController>{};
  final _ratePro = <GuestRole, TextEditingController>{};
  final _addons = <_LineEditors>[];
  final _individuals = <_LineEditors>[];
  final _days = <_DayEditors>[];
  final _photoPicker = const DivePhotoPicker();
  final _sectionKeys = List<GlobalKey>.generate(
    _sectionCount,
    (_) => GlobalKey(),
  );
  final _briefKey = GlobalKey();
  final _draftListeners = <TextEditingController>[];
  PickedPhoto? _photo;
  var _removeExistingCover = false;
  late String _shopId;
  late String _continent;
  late ProductCategory _category;
  var _section = 0;
  var _saving = false;
  var _previewDiver = 1;
  var _previewNondiver = 0;
  var _previewChild = 0;
  var _openEmptySeats = false;
  var _seatOptionId = '';
  var _namedResort = false;
  var _focAppliesTo = GuestRole.diver;
  late final TextEditingController _capacity;
  DateTime? _departureStart;
  DateTime? _flagClosesAt;

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
    _category = existing?.category ?? ProductCategory.resortPackage;
    _namedResort = _shopId.startsWith('curated-');
    _name = TextEditingController(text: existing?.name ?? '');
    _resortName = TextEditingController(text: shop?.name ?? '');
    _resortCountry = TextEditingController(text: shop?.country ?? '');
    _resortRegion = TextEditingController(text: shop?.location ?? '');
    _blurb = TextEditingController(text: existing?.blurb ?? '');
    _meeting = TextEditingController(text: existing?.meetingPoint ?? '');
    _schedule = TextEditingController(text: existing?.schedule ?? '');
    _difficulty = TextEditingController(text: existing?.difficulty ?? '');
    _minGuests = TextEditingController(
      text: (existing?.minGuests ?? 0) > 0 ? '${existing!.minGuests}' : '',
    );
    _maxGuests = TextEditingController(
      text: (existing?.maxGuests ?? 0) > 0 ? '${existing!.maxGuests}' : '',
    );
    _cancel = TextEditingController(text: existing?.cancellationNote ?? '');
    _includes = _TextLines(existing?.includes ?? '');
    _excludes = _TextLines(existing?.excludes ?? '');
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
    if (_seatOptionId.isNotEmpty) {
      for (final option in existing?.options ?? const <ShopProductOption>[]) {
        if (option.id == _seatOptionId) {
          _capacity.text = option.capacity > 0 ? '${option.capacity}' : '';
          _departureStart = option.departureStart;
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
    final days = existing?.itineraryDays ?? const <ItineraryDay>[];
    if (days.isEmpty) {
      _days.add(_DayEditors(day: 1));
    } else {
      for (final day in days) {
        _days.add(_DayEditors(day: day.day, title: day.title, body: day.body));
      }
    }
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
    _listen(_resortName);
    _listen(_rateConsumer[GuestRole.diver]!);
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
    _schedule.dispose();
    _difficulty.dispose();
    _minGuests.dispose();
    _maxGuests.dispose();
    _cancel.dispose();
    _focPay.dispose();
    _focFree.dispose();
    _capacity.dispose();
    _includes.dispose();
    _excludes.dispose();
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
    for (final day in _days) {
      day.dispose();
    }
    super.dispose();
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

  String get _existingCoverUrl {
    final url = widget.existing?.coverUrl.trim() ?? '';
    if (_removeExistingCover || url.isEmpty) {
      return '';
    }
    return url;
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
    final n = _days.length;
    if (n <= 1) {
      return '1일';
    }
    return '${n - 1}박 $n일';
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
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 280),
        alignment: 0.04,
      );
    }
    setState(() => _section = index);
  }

  bool _onBriefScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final briefContext = _briefKey.currentContext;
    if (briefContext == null) {
      return false;
    }
    final briefBox = briefContext.findRenderObject() as RenderBox?;
    if (briefBox == null || !briefBox.hasSize) {
      return false;
    }
    final top = briefBox.localToGlobal(Offset.zero).dy;
    var current = 0;
    for (var i = 0; i < _sectionKeys.length; i++) {
      final ctx = _sectionKeys[i].currentContext;
      if (ctx == null) {
        continue;
      }
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        continue;
      }
      if (box.localToGlobal(Offset.zero).dy - top <= 72) {
        current = i;
      }
    }
    if (current != _section) {
      final next = current;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && next != _section) {
          setState(() => _section = next);
        }
      });
    }
    return false;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (_saving) {
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
    setState(() => _saving = true);
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
          coverUrl: _existingCoverUrl,
          continent: _continent,
          meetingPoint: _meeting.text.trim(),
          schedule: _schedule.text.trim(),
          includes: _includes.join(),
          excludes: _excludes.join(),
          difficulty: _difficulty.text.trim(),
          minGuests: int.tryParse(_minGuests.text) ?? 0,
          maxGuests: int.tryParse(_maxGuests.text) ?? 0,
          cancellationNote: _cancel.text.trim(),
          category: _category,
          detail: existing?.detail ?? '',
          photoUrls: existing?.photoUrls ?? const [],
          itineraryDays: itinerary,
          guestRates: guestRates,
          focPayCount: int.tryParse(_focPay.text) ?? 0,
          focFreeCount: int.tryParse(_focFree.text) ?? 0,
          focAppliesTo: _focAppliesTo,
          openEmptySeats: _seatsOnProduct,
          capacity: _seatsOnProduct ? (int.tryParse(_capacity.text) ?? 0) : 0,
          bookedSeats: existing?.bookedSeats ?? 0,
          flagHolds: existing?.flagHolds ?? const [],
          departureStart: _seatsOnProduct ? _departureStart : null,
          flagClosesAt: _seatsOnProduct
              ? (_flagClosesAt ?? _departureStart)
              : null,
          options: [for (final option in options) _withSeatOption(option)],
          listingKind: existing?.listingKind ?? ProductListingKind.exploreOnly,
          publishStatus:
              existing?.publishStatus ?? ProductPublishStatus.approved,
          featuredAt: existing?.featuredAt,
          submittedAt: existing?.submittedAt,
          reviewedAt: existing?.reviewedAt,
          reviewNote: existing?.reviewNote ?? '',
          submittedByUid: existing?.submittedByUid.isNotEmpty == true
              ? existing!.submittedByUid
              : sessionUid,
        ),
        photoBytes: _photo?.bytes,
        photoFileName: _photo?.fileName,
        photoContentType: _photo?.contentType,
        useAsResortCover: existing == null || _photo != null,
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
    final live = DiverStoreScope.of(context).liveStatsFor(_shopId);
    final labels = _sectionLabels(l10n);

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        title: Text(l10n.briefTitle),
        backgroundColor: AppTheme.canvas,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final brief = _brief(l10n, shops, shopLocked, hull, live);
          return Column(
            children: [
              if (!wide) _sectionChips(labels),
              Expanded(
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 168, child: _sectionRail(labels)),
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
              _saveBar(l10n),
            ],
          );
        },
      ),
    );
  }

  List<String> _sectionLabels(AppLocalizations l10n) {
    return [
      l10n.briefSectionCover,
      l10n.briefSectionPlace,
      l10n.briefSectionDays,
      l10n.briefSectionTerms,
      l10n.briefSectionPrice,
      l10n.briefSectionSeats,
    ];
  }

  Widget _sectionRail(List<String> labels) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: FilledButton.tonal(
              onPressed: () => _reveal(i),
              style: FilledButton.styleFrom(
                backgroundColor: _section == i
                    ? AppTheme.navy
                    : AppTheme.seaMist,
                foregroundColor: _section == i ? Colors.white : AppTheme.navy,
              ),
              child: Text(labels[i]),
            ),
          ),
      ],
    );
  }

  Widget _sectionChips(List<String> labels) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            ChoiceChip(
              label: Text(labels[i]),
              selected: _section == i,
              onSelected: (_) => _reveal(i),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _saveBar(AppLocalizations l10n) {
    return SafeArea(
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
          child: Text(_saving ? l10n.exploreSaving : l10n.partnerSave),
        ),
      ),
    );
  }

  Widget _brief(
    AppLocalizations l10n,
    List<DiveShop> shops,
    bool shopLocked,
    DiveShop? hull,
    ShopLiveStats? live,
  ) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onBriefScroll,
      child: ListView(
        key: _briefKey,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _block(0, l10n.briefSectionCover, [_coverBlock(l10n)]),
          _block(1, l10n.briefSectionPlace, [
            _placeBlock(l10n, shops, shopLocked, hull, live),
          ]),
          _block(2, l10n.briefSectionDays, [_daysBlock(l10n)]),
          _block(3, l10n.briefSectionTerms, [_termsBlock(l10n)]),
          _block(4, l10n.briefSectionPrice, [_priceBlock(l10n)]),
          _block(5, l10n.briefSectionSeats, [_seatsBlock(l10n)]),
        ],
      ),
    );
  }

  Widget _block(int index, String title, List<Widget> children) {
    return KeyedSubtree(
      key: _sectionKeys[index],
      child: Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  InputDecoration _field(String label, {String? hint, int? lines}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: (lines ?? 1) > 1,
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _coverBlock(AppLocalizations l10n) {
    final cats = <ProductCategory, String>{
      ProductCategory.resortPackage: l10n.workbenchCatResort,
      ProductCategory.liveaboard: l10n.workbenchCatLiveaboard,
      ProductCategory.funDive: l10n.workbenchCatFun,
      ProductCategory.course: l10n.workbenchCatCourse,
      ProductCategory.dayTrip: l10n.workbenchCatDay,
    };
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
        _photoBlock(l10n),
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
      ],
    );
  }

  Widget _photoBlock(AppLocalizations l10n) {
    final cover =
        _photo != null ||
        (!_removeExistingCover && _existingCoverUrl.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!R2Config.canPersistListingPhotos)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.productFormPhotoHint,
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
          ),
        if (cover)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: _photo != null
                  ? Image.memory(_photo!.bytes, fit: BoxFit.cover)
                  : Image.network(_existingCoverUrl, fit: BoxFit.cover),
            ),
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
      ],
    );
  }

  Widget _placeBlock(
    AppLocalizations l10n,
    List<DiveShop> shops,
    bool shopLocked,
    DiveShop? hull,
    ShopLiveStats? live,
  ) {
    final address = (live?.address ?? hull?.address ?? '').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!shopLocked) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.briefSourceCatalog),
                selected: !_namedResort,
                onSelected: (selected) {
                  if (!selected) {
                    return;
                  }
                  setState(() {
                    _namedResort = false;
                    final filtered = _shopsForContinent;
                    final stillListed = filtered.any(
                      (shop) => shop.id == _shopId,
                    );
                    if (!stillListed && filtered.isNotEmpty) {
                      _shopId = filtered.first.id;
                    }
                  });
                },
              ),
              ChoiceChip(
                label: Text(l10n.briefSourceNamed),
                selected: _namedResort,
                onSelected: (selected) {
                  if (!selected) {
                    return;
                  }
                  final current = DiveShopCatalog.byId(_shopId);
                  setState(() {
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
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
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
                      _shopId = filtered.first.id;
                    }
                  });
                },
        ),
        const SizedBox(height: 12),
        if (_namedResort) ...[
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
        ] else ...[
          DropdownButtonFormField<String>(
            key: ValueKey('shop-$_continent-$_shopId'),
            initialValue: shops.any((shop) => shop.id == _shopId)
                ? _shopId
                : null,
            decoration: _field(l10n.productFormShopHint),
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
                    hull?.name ?? live?.name ?? _shopId,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${hull?.country ?? ''} · ${hull?.location ?? live?.location ?? ''}',
                  ),
                  if (address.isNotEmpty) Text(address),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _meeting,
          decoration: _field(
            l10n.productFormMeetingPoint,
            hint: l10n.productFormMeetingHint,
          ),
        ),
      ],
    );
  }

  Widget _daysBlock(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _nightsLabel,
          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _schedule,
          maxLines: 3,
          decoration: _field(
            l10n.productFormSchedule,
            hint: l10n.productFormScheduleHint,
            lines: 3,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.workbenchItinerary,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _days.length; i++) ...[
          TextField(
            controller: _days[i].title,
            decoration: _field(l10n.workbenchDayTitle(i + 1)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _days[i].body,
            maxLines: 3,
            decoration: _field(l10n.workbenchDayBody, lines: 3),
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

  Widget _termsBlock(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _linesEditor(
          l10n,
          l10n.productFormIncludes,
          l10n.productFormIncludesHint,
          _includes,
        ),
        const SizedBox(height: 16),
        _linesEditor(
          l10n,
          l10n.productFormExcludes,
          l10n.productFormExcludesHint,
          _excludes,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _difficulty,
          decoration: _field(
            l10n.productFormDifficulty,
            hint: l10n.productFormDifficultyHint,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minGuests,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _field(l10n.productFormMinGuests),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _maxGuests,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _field(l10n.productFormMaxGuests),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cancel,
          maxLines: 3,
          decoration: _field(
            l10n.productFormCancelNote,
            hint: l10n.productFormCancelHint,
            lines: 3,
          ),
        ),
      ],
    );
  }

  Widget _linesEditor(
    AppLocalizations l10n,
    String label,
    String hint,
    _TextLines lines,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (var i = 0; i < lines.items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: lines.items[i],
                    decoration: InputDecoration(
                      hintText: hint,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.briefRemoveLine,
                  onPressed: () {
                    setState(() => lines.items.removeAt(i).dispose());
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: () {
            setState(() => lines.items.add(TextEditingController()));
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.briefAddLine),
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
                borderRadius: BorderRadius.circular(8),
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
          borderRadius: BorderRadius.circular(8),
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
            enabled: _rateEnabled[role] ?? role != GuestRole.infant,
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
    final quote = BookingQuote.compute(
      product: _draftProduct,
      professional: false,
      divers: _previewDiver,
      nondivers: _previewNondiver,
      children: _previewChild,
      infants: 0,
      bookPackage: true,
      selectedOptionIds: const {},
    );
    final resort = _namedResort
        ? (_resortName.text.trim().isEmpty ? '—' : _resortName.text.trim())
        : (hull?.name ?? '');
    final start = int.tryParse(_rateConsumer[GuestRole.diver]!.text) ?? 0;
    final cover =
        _photo != null ||
        (!_removeExistingCover && _existingCoverUrl.isNotEmpty);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
            if (cover)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 96,
                  width: double.infinity,
                  child: _photo != null
                      ? Image.memory(_photo!.bytes, fit: BoxFit.cover)
                      : Image.network(_existingCoverUrl, fit: BoxFit.cover),
                ),
              ),
            if (cover) const SizedBox(height: 8),
            Text(_name.text.trim().isEmpty ? '—' : _name.text.trim()),
            Text(
              resort,
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
            Text(_nightsLabel),
            Text(_blurb.text.trim()),
            const SizedBox(height: 8),
            Text(
              '${l10n.briefStartPrice} $start',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(l10n.checkoutGuests),
            _previewQty(
              l10n.workbenchGuestDiver,
              _previewDiver,
              (value) => setState(() => _previewDiver = value),
            ),
            _previewQty(
              l10n.workbenchGuestNondiver,
              _previewNondiver,
              (value) => setState(() => _previewNondiver = value),
            ),
            _previewQty(
              l10n.workbenchGuestChild,
              _previewChild,
              (value) => setState(() => _previewChild = value),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.checkoutTotal('${quote.total}'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewQty(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        IconButton(
          onPressed: value == 0 ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove, size: 18),
        ),
        Text('$value'),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add, size: 18),
        ),
      ],
    );
  }
}
