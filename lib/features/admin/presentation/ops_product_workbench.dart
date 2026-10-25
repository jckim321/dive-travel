import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dive_travel_app/core/config/r2_config.dart';
import 'package:dive_travel_app/core/constants/gallery_limits.dart';
import 'package:dive_travel_app/core/constants/option_group.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/booking_quote.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/partner_product_form_fields.dart';
import 'package:dive_travel_app/core/models/price_revision.dart'
    show optionHasSeatCommitment;
import 'package:dive_travel_app/core/models/product_price_swing.dart';
import 'package:dive_travel_app/core/models/product_publish_guard.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/booking_gallery_editor.dart';
import 'package:dive_travel_app/features/admin/presentation/product_brief_stepper.dart';
import 'package:dive_travel_app/features/admin/presentation/product_reject_dialog.dart';
import 'package:dive_travel_app/features/admin/presentation/product_submit_checklist.dart';
import 'package:dive_travel_app/features/admin/presentation/workbench_gallery_preserve.dart';
import 'package:dive_travel_app/features/admin/presentation/workbench_price_validation.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_back_button.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_form_focus.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seat_open_fields.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class OpsProductWorkbench extends StatefulWidget {
  const OpsProductWorkbench({
    super.key,
    this.lockedShopId,
    this.partnerMode = false,
    this.creatorMode = false,
    this.existing,
    this.startEditing = false,
    this.partnerFocus = PartnerFormFocus.none,
  });

  final String? lockedShopId;
  final bool partnerMode;

  /// Diver "craft a trip" — always submits for review as diverPlanned.
  final bool creatorMode;
  final ShopProduct? existing;

  /// Open in edit mode when revisiting an existing product (partner/admin edit).
  final bool startEditing;

  /// Partner list deep-link (H2). Ignored when [partnerMode] is false.
  final PartnerFormFocus partnerFocus;

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
    this.group = '',
  }) : id = id ?? 'opt-${DateTime.now().microsecondsSinceEpoch}',
       name = TextEditingController(text: name),
       description = TextEditingController(text: description),
       consumer = TextEditingController(text: consumer),
       professional = TextEditingController(text: professional),
       consumerFocus = FocusNode();

  final String id;
  final TextEditingController name;
  final TextEditingController description;
  final TextEditingController consumer;
  final TextEditingController professional;
  final FocusNode consumerFocus;
  String? priceError;
  ProductOptionKind kind;
  bool bookable;
  String group;

  void dispose() {
    name.dispose();
    description.dispose();
    consumer.dispose();
    professional.dispose();
    consumerFocus.dispose();
  }

  ShopProductOption toOption() {
    final price = parsePositivePrice(consumer.text) ?? 0;
    return ShopProductOption(
      id: id,
      name: name.text.trim(),
      description: description.text.trim(),
      consumerPrice: price,
      professionalPrice: parsePositivePrice(professional.text) ?? price,
      kind: kind,
      bookable: bookable,
      group: normalizeOptionGroup(group),
    );
  }
}

class _IndividualTicket {
  _IndividualTicket({
    String? id,
    String name = '',
    String consumer = '',
    String includes = '',
    String excludes = '',
    this.bookable = true,
    this.group = '',
  }) : id = id ?? 'ind-${DateTime.now().microsecondsSinceEpoch}',
       name = TextEditingController(text: name),
       consumer = TextEditingController(text: consumer),
       includes = TextEditingController(text: includes),
       excludes = TextEditingController(text: excludes),
       consumerFocus = FocusNode();

  factory _IndividualTicket.fromOption(ShopProductOption option) {
    final raw = option.description.trim();
    var includes = '';
    var excludes = '';
    final includeMatch = RegExp(r'포함\s*[:：]?\s*([\s\S]*?)(?=불포함\s*[:：]|$)')
        .firstMatch(raw);
    final excludeMatch = RegExp(r'불포함\s*[:：]?\s*([\s\S]*)$').firstMatch(raw);
    if (includeMatch != null || excludeMatch != null) {
      includes = includeMatch?.group(1)?.trim() ?? '';
      excludes = excludeMatch?.group(1)?.trim() ?? '';
    } else {
      includes = raw;
    }
    return _IndividualTicket(
      id: option.id,
      name: option.name,
      consumer: option.consumerPrice > 0 ? '${option.consumerPrice}' : '',
      includes: includes,
      excludes: excludes,
      bookable: option.bookable,
      group: option.group,
    );
  }

  final String id;
  final TextEditingController name;
  final TextEditingController consumer;
  final TextEditingController includes;
  final TextEditingController excludes;
  final FocusNode consumerFocus;
  String? priceError;
  final addons = <_LineEditors>[];
  final addonQty = <String, int>{};
  int nights = 0;
  DateTime? checkIn;
  int guests = 1;
  bool bookable;
  String group;
  bool hasNondivers = false;
  int nondivers = 0;
  int children = 0;

  String get nightsLabel {
    if (nights <= 0) {
      return '1일';
    }
    return '$nights박 ${nights + 1}일';
  }

  DateTime? get checkOut {
    final start = checkIn;
    if (start == null) {
      return null;
    }
    return DateTime(
      start.year,
      start.month,
      start.day,
    ).add(Duration(days: nights));
  }

  int get previewHeads {
    final extra = hasNondivers ? (nondivers + children) : 0;
    return guests + extra;
  }

  String get descriptionText {
    final inc = includes.text.trim();
    final exc = excludes.text.trim();
    return [
      if (inc.isNotEmpty) '포함:\n$inc',
      if (exc.isNotEmpty) '불포함:\n$exc',
    ].join('\n\n');
  }

  ShopProductOption toOption() {
    final price = parsePositivePrice(consumer.text) ?? 0;
    return ShopProductOption(
      id: id,
      name: name.text.trim(),
      description: descriptionText,
      consumerPrice: price,
      professionalPrice: price,
      kind: ProductOptionKind.individual,
      bookable: bookable,
      group: normalizeOptionGroup(group),
    );
  }

  List<ShopProductOption> addonOptions() {
    return [
      for (final draft in addons)
        if (draft.name.text.trim().isNotEmpty)
          draft.toOption().copyWith(
            kind: ProductOptionKind.addon,
            parentOptionId: id,
          ),
    ];
  }

  void dispose() {
    name.dispose();
    consumer.dispose();
    includes.dispose();
    excludes.dispose();
    consumerFocus.dispose();
    for (final draft in addons) {
      draft.dispose();
    }
  }
}

class _OpsProductWorkbenchState extends State<OpsProductWorkbench> {
  /// Scroll targets: 0 cover, 1 place, 2 detail, 3 booking, 4 same-boat.
  static const _sectionCount = 5;
  static const _kBoxRadius = 2.0;
  static const _kDirectShop = '__direct__';
  static const _stepCount = 3;

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
  final _rateEnabled = <GuestRole, bool>{};
  final _rateConsumer = <GuestRole, TextEditingController>{};
  final _addons = <_LineEditors>[];
  final _individuals = <_IndividualTicket>[];
  final _photoPicker = const DivePhotoPicker();
  final _gallery = <BookingGalleryItem>[];
  var _galleryTouched = false;
  /// User removed every photo on purpose; empty gallery may clear Firestore.
  var _galleryClearedByUser = false;
  final _sectionKeys = List<GlobalKey>.generate(
    _sectionCount,
    (_) => GlobalKey(),
  );
  final _draftListeners = <TextEditingController>[];
  static const _maxGallery = GalleryLimits.maxProductPhotos;
  late String _shopId;
  late String _continent;
  late ProductCategory _category;
  /// Partner chips only; false keeps funDive/course/etc. on save (H1b).
  var _categoryChipTouched = false;
  /// Snapshot of durationLabel at load; kept until partner edits 박/일 (H1b).
  var _originalDurationLabel = '';
  var _durationFieldsTouched = false;
  late final TextEditingController _nightsField;
  late final TextEditingController _daysField;
  final _partnerScrollController = ScrollController();
  final _nameFieldKey = GlobalKey();
  final _diverPriceFieldKey = GlobalKey();
  final _partnerAddonsKey = GlobalKey();
  final _partnerIndividualsKey = GlobalKey();
  ProductSaveIntent? _savingIntent;
  var _previewDiver = 1;
  var _previewNondiver = 0;
  var _previewChild = 0;
  var _hasNondivers = false;
  final _addonQty = <String, int>{};
  var _namedResort = false;
  DateTime? _departureStart;
  var _packageNights = 0;
  late bool _editing;
  late final SameBoatSeatOpenController _seats;
  /// 0 basics · 1 pricing · 2 review/submit (admin/creator only).
  var _stepIndex = 0;
  /// After first temp-save of a new product, reuse this id on later saves.
  String? _persistedProductId;
  /// Form fingerprint after load / successful save (dirty detection).
  String? _baselineSignature;
  final _checklist = <String, bool>{
    for (final id in ProductSubmitChecklist.ids) id: false,
  };
  static final _priceInputFormatters = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[0-9,\s원]')),
    LengthLimitingTextInputFormatter(kWorkbenchPriceInputMaxLength),
  ];

  final _diverPriceFocus = FocusNode();
  final _nondiverPriceFocus = FocusNode();
  final _childPriceFocus = FocusNode();
  String? _diverPriceError;
  String? _nondiverPriceError;
  String? _childPriceError;

  /// Temp-save (keepEditing) only for drafts. Approved listings use live 「저장」.
  /// Creators may still temp-save pending/rejected; partners may not.
  bool get _canTempSave {
    if (!_editing) {
      return false;
    }
    final status = widget.existing?.publishStatus;
    if (status == ProductPublishStatus.approved) {
      return false;
    }
    if (widget.partnerMode) {
      return status == null || status == ProductPublishStatus.draft;
    }
    return true;
  }

  bool _adminSameBoatFields(DiverStore store) {
    return store.stats.isAdmin && !widget.partnerMode && !widget.creatorMode;
  }

  void _goToStep(int step, {int? revealSection}) {
    final next = step.clamp(0, _stepCount - 1);
    setState(() => _stepIndex = next);
    if (revealSection != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _reveal(revealSection);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // H1a: ignore legacy price_revision / pending_options (do not overlay).
    final existing = widget.existing;
    _shopId =
        widget.lockedShopId ??
        existing?.shopId ??
        DiveShopCatalog.shops.first.id;
    final shop = DiveShopCatalog.byId(_shopId);
    _continent = existing?.continent.isNotEmpty == true
        ? existing!.continent
        : (shop?.continent ?? ContinentId.asia);
    // Preserve stored category (funDive/course/…) until a chip is tapped (H1b).
    _category = existing?.category ?? ProductCategory.resortPackage;
    _categoryChipTouched = false;
    _namedResort = _shopId.startsWith('curated-');
    _persistedProductId =
        existing?.id.isNotEmpty == true ? existing!.id : null;
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
    _departureStart = existing?.departureStart;
    _originalDurationLabel = existing?.durationLabel ?? '';
    final durationParts = parseDurationLabelParts(_originalDurationLabel);
    if (durationParts.parsed) {
      _packageNights = durationParts.nights ?? 0;
      _nightsField = TextEditingController(
        text: durationParts.nights?.toString() ?? '',
      );
      _daysField = TextEditingController(
        text: durationParts.days?.toString() ?? '',
      );
    } else {
      // Unparsed freeform: leave 박/일 empty; keep original string on save.
      _packageNights = widget.partnerMode
          ? 0
          : _parsePackageNights(_originalDurationLabel);
      _nightsField = TextEditingController();
      _daysField = TextEditingController();
    }
    _durationFieldsTouched = false;
    _editing = existing == null || widget.startEditing;
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
    }
    _hasNondivers =
        (_rateEnabled[GuestRole.nondiver] ?? false) ||
        (_rateEnabled[GuestRole.child] ?? false);
    final existingOptions =
        existing?.options ?? const <ShopProductOption>[];
    final childAddons = <String, List<ShopProductOption>>{};
    for (final option in existingOptions) {
      if (option.kind == ProductOptionKind.individual) {
        _individuals.add(_IndividualTicket.fromOption(option));
        continue;
      }
      if (option.kind == ProductOptionKind.basePackage) {
        continue;
      }
      if (option.kind == ProductOptionKind.addon &&
          option.parentOptionId.isNotEmpty) {
        childAddons
            .putIfAbsent(option.parentOptionId, () => <ShopProductOption>[])
            .add(option);
        continue;
      }
      _addons.add(
        _LineEditors(
          id: option.id,
          name: option.name,
          description: option.description,
          consumer: option.consumerPrice > 0 ? '${option.consumerPrice}' : '',
          professional: option.professionalPrice > 0
              ? '${option.professionalPrice}'
              : '',
          kind: option.kind,
          bookable: option.bookable,
          group: option.group,
        ),
      );
    }
    if (_addons.isEmpty) {
      _addons.add(_LineEditors(kind: ProductOptionKind.addon));
    }
    for (final line in _addons) {
      _watchLine(line);
      _listen(line.consumer);
      _addonQty.putIfAbsent(line.id, () => 0);
    }
    for (final ticket in _individuals) {
      _listen(ticket.name);
      _listen(ticket.consumer);
      _listen(ticket.includes);
      _listen(ticket.excludes);
      for (final option in childAddons[ticket.id] ?? const <ShopProductOption>[]) {
        final line = _LineEditors(
          id: option.id,
          name: option.name,
          description: option.description,
          consumer: option.consumerPrice > 0 ? '${option.consumerPrice}' : '',
          professional: option.professionalPrice > 0
              ? '${option.professionalPrice}'
              : '',
          kind: ProductOptionKind.addon,
          bookable: option.bookable,
          group: option.group,
        );
        _watchLine(line);
        _listen(line.consumer);
        ticket.addons.add(line);
        ticket.addonQty[line.id] = 0;
      }
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
    _seats = SameBoatSeatOpenController(
      existing: widget.existing,
      optionSlots: _seatOptionSlots(),
      isAdmin: false,
      packageDeparture: _departureStart,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _baselineSignature = _formSignature();
      _applyPartnerFocus();
    });
  }

  void _applyPartnerFocus() {
    if (!widget.partnerMode) {
      return;
    }
    switch (widget.partnerFocus) {
      case PartnerFormFocus.none:
        return;
      case PartnerFormFocus.addAddon:
        final line = _LineEditors(kind: ProductOptionKind.addon);
        _listen(line.name);
        _listen(line.consumer);
        setState(() => _addons.add(line));
        _scrollToPartnerKey(_partnerAddonsKey);
      case PartnerFormFocus.addons:
        _scrollToPartnerKey(_partnerAddonsKey);
      case PartnerFormFocus.addIndividual:
        _addIndividualTicket();
        _scrollToPartnerKey(_partnerIndividualsKey);
      case PartnerFormFocus.individuals:
        _scrollToPartnerKey(_partnerIndividualsKey);
    }
  }

  ShopProductOption? _existingOption(String id) {
    for (final option in widget.existing?.options ?? const <ShopProductOption>[]) {
      if (option.id == id) {
        return option;
      }
    }
    return null;
  }

  bool _closeOptionInsteadOfRemove(_LineEditors draft) {
    final existing = _existingOption(draft.id);
    if (existing == null || !optionHasSeatCommitment(existing)) {
      return false;
    }
    draft.bookable = false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).workbenchOptionClosedNotDeleted,
        ),
      ),
    );
    return true;
  }

  bool get _hasPhotosForSave =>
      _gallery.isNotEmpty || _preserveExistingPhotos;

  int get _diverPriceValue =>
      parsePositivePrice(_rateConsumer[GuestRole.diver]?.text ?? '') ?? 0;

  /// Effective status for temp-save rules (pending needs min fields).
  ProductPublishStatus? get _editingPublishStatus =>
      widget.existing?.publishStatus;

  bool get _isDirty {
    final baseline = _baselineSignature;
    if (baseline == null) {
      return false;
    }
    return _formSignature() != baseline;
  }

  String _formSignature() {
    final gallerySig = [
      for (final item in _gallery)
        if (item.url != null && item.url!.isNotEmpty)
          'u:${item.url}'
        else if (item.photo != null)
          'b:${item.photo!.bytes.length}:${item.photo!.fileName}',
    ].join('|');
    final addonSig = [
      for (final a in _addons) '${a.name.text}|${a.consumer.text}',
    ].join(';');
    final ticketSig = [
      for (final t in _individuals)
        '${t.name.text}|${t.consumer.text}|${[
          for (final a in t.addons) '${a.name.text}|${a.consumer.text}',
        ].join(',')}',
    ].join(';');
    return [
      _name.text,
      _blurb.text,
      _meeting.text,
      _detailBody.text,
      _includes.text,
      _excludes.text,
      _cancel.text,
      _shopId,
      _continent,
      _category.firestoreValue,
      _packageNights,
      _departureStart?.toIso8601String() ?? '',
      _hasNondivers,
      _rateConsumer[GuestRole.diver]?.text ?? '',
      _rateConsumer[GuestRole.nondiver]?.text ?? '',
      _rateConsumer[GuestRole.child]?.text ?? '',
      _namedResort,
      _resortName.text,
      _resortCountry.text,
      _resortRegion.text,
      _galleryTouched,
      _galleryClearedByUser,
      gallerySig,
      addonSig,
      ticketSig,
    ].join('\u001f');
  }

  /// Pending temp-save (creator/admin): photo + name + price > 0.
  bool _validatePendingTempSave(AppLocalizations l10n) {
    if (!_hasPhotosForSave) {
      _reveal(0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.briefTempSaveNeedPhoto)),
      );
      return false;
    }
    if (_name.text.trim().isEmpty) {
      _reveal(0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.workbenchNeedName)),
      );
      return false;
    }
    if (_diverPriceValue <= 0) {
      _reveal(3);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.briefTempSaveNeedPrice)),
      );
      return false;
    }
    return true;
  }

  /// Partner H1b: name + base price only (photo optional) for temp and publish.
  bool _validatePartnerRequired(AppLocalizations l10n) {
    if (_name.text.trim().isEmpty) {
      _scrollToPartnerKey(_nameFieldKey);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.workbenchNeedName)),
      );
      return false;
    }
    if (_diverPriceValue <= 0) {
      _scrollToPartnerKey(_diverPriceFieldKey);
      setState(() {
        _diverPriceError = l10n.workbenchNeedDiverPrice;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.workbenchNeedDiverPrice)),
      );
      return false;
    }
    return true;
  }

  void _scrollToPartnerKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 280),
        alignment: 0.1,
        curve: Curves.easeOut,
      );
    });
  }

  String get _durationLabelForSave {
    if (widget.partnerMode) {
      final nights = int.tryParse(_nightsField.text.trim());
      final days = int.tryParse(_daysField.text.trim());
      return durationLabelForPartnerSave(
        originalLabel: _originalDurationLabel,
        userEditedFields: _durationFieldsTouched,
        nights: nights,
        days: days,
      );
    }
    return _nightsLabel;
  }

  ProductCategory get _categoryForSave {
    if (!widget.partnerMode) {
      return _category;
    }
    return categoryForPartnerSave(
      stored: widget.existing?.category ?? ProductCategory.resortPackage,
      userSelectedChip: _categoryChipTouched,
      chipValue: _category,
    );
  }

  void _onPartnerCategoryChip(ProductCategory next) {
    setState(() {
      _categoryChipTouched = true;
      _category = next;
    });
  }

  void _onPartnerDurationEdited() {
    if (!_durationFieldsTouched) {
      setState(() => _durationFieldsTouched = true);
    } else {
      setState(() {});
    }
    final nights = int.tryParse(_nightsField.text.trim()) ?? 0;
    _packageNights = nights < 0 ? 0 : nights;
  }

  List<SameBoatOptionSeatSlot> _seatOptionSlots() {
    return [
      for (final ticket in _individuals)
        if (ticket.name.text.trim().isNotEmpty ||
            (widget.existing?.options.any((o) => o.id == ticket.id) ?? false))
          SameBoatOptionSeatSlot(
            id: ticket.id,
            name: ticket.name.text.trim().isEmpty
                ? ticket.id
                : ticket.name.text.trim(),
          ),
    ];
  }

  void _syncSeatSlots() {
    _seats.syncOptionSlots(_seatOptionSlots(), existing: widget.existing);
    _seats.syncPackageDeparture(_departureStart);
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
    line.consumer.removeListener(_onDraftChanged);
    _draftListeners.remove(line.consumer);
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
    _nightsField.dispose();
    _daysField.dispose();
    _partnerScrollController.dispose();
    for (final controller in _rateConsumer.values) {
      controller.dispose();
    }
    for (final item in _addons) {
      item.dispose();
    }
    for (final item in _individuals) {
      item.dispose();
    }
    _diverPriceFocus.dispose();
    _nondiverPriceFocus.dispose();
    _childPriceFocus.dispose();
    _seats.dispose();
    super.dispose();
  }

  void _dropIndividual(_IndividualTicket ticket) {
    ticket.name.removeListener(_onDraftChanged);
    ticket.consumer.removeListener(_onDraftChanged);
    ticket.includes.removeListener(_onDraftChanged);
    ticket.excludes.removeListener(_onDraftChanged);
    _draftListeners.remove(ticket.name);
    _draftListeners.remove(ticket.consumer);
    _draftListeners.remove(ticket.includes);
    _draftListeners.remove(ticket.excludes);
    for (final line in ticket.addons) {
      line.name.removeListener(_onDraftChanged);
      line.consumer.removeListener(_onDraftChanged);
      _draftListeners.remove(line.name);
      _draftListeners.remove(line.consumer);
    }
    ticket.dispose();
  }

  void _addIndividualTicket() {
    final ticket = _IndividualTicket();
    _listen(ticket.name);
    _listen(ticket.consumer);
    _listen(ticket.includes);
    _listen(ticket.excludes);
    setState(() {
      _individuals.add(ticket);
      _syncSeatSlots();
    });
  }

  BookingQuote _individualQuote(_IndividualTicket ticket) {
    final option = ticket.toOption();
    final addonOpts = ticket.addonOptions();
    final heads = ticket.previewHeads < 1 ? 1 : ticket.previewHeads;
    final price = option.consumerPrice;
    final selected = <String>{
      option.id,
      for (final addon in addonOpts)
        if ((ticket.addonQty[addon.id] ?? 0) > 0) addon.id,
    };
    return BookingQuote.compute(
      product: ShopProduct(
        id: 'draft-ind',
        shopId: _shopId,
        name: option.name.isEmpty ? '—' : option.name,
        consumerPrice: price,
        professionalPrice: price,
        options: [option, ...addonOpts],
      ),
      professional: false,
      divers: 0,
      nondivers: 0,
      children: 0,
      infants: 0,
      bookPackage: false,
      selectedOptionIds: selected,
      optionQuantities: {
        option.id: heads,
        for (final addon in addonOpts)
          addon.id: ticket.addonQty[addon.id] ?? 0,
      },
    );
  }

  Future<void> _pickIndividualDate(
    _IndividualTicket ticket, {
    required bool checkout,
  }) async {
    final initial = checkout
        ? (ticket.checkOut ?? ticket.checkIn ?? DateTime.now())
        : (ticket.checkIn ?? DateTime.now());
    final first = checkout && ticket.checkIn != null
        ? ticket.checkIn!
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
    setState(() {
      if (checkout) {
        final start = ticket.checkIn;
        if (start == null) {
          ticket.checkIn = DateTime(picked.year, picked.month, picked.day);
          ticket.nights = 0;
        } else {
          final checkIn = DateTime(start.year, start.month, start.day);
          final checkOut = DateTime(picked.year, picked.month, picked.day);
          var nights = checkOut.difference(checkIn).inDays;
          if (nights < 0) {
            nights = 0;
          }
          ticket.nights = nights;
        }
      } else {
        ticket.checkIn = DateTime(picked.year, picked.month, picked.day);
      }
    });
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

  /// Keep same-boat / flag fields from the existing option (set outside this form).
  ShopProductOption _withSeatOption(ShopProductOption option) {
    ShopProductOption? previous;
    for (final item
        in widget.existing?.options ?? const <ShopProductOption>[]) {
      if (item.id == option.id) {
        previous = item;
        break;
      }
    }
    if (previous == null) {
      return option;
    }
    return option.copyWith(
      guestRole: previous.guestRole,
      openEmptySeats: previous.openEmptySeats,
      sameBoatStatus: previous.sameBoatStatus,
      capacity: previous.capacity,
      bookedSeats: previous.bookedSeats,
      flagHolds: previous.flagHolds,
      departureStart: previous.departureStart,
      flagClosesAt: previous.flagClosesAt,
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
        _galleryClearedByUser = false;
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('사진 선택 실패: $error')));
    }
  }

  void _removePhoto(int index) {
    if (index < 0 || index >= _gallery.length) {
      return;
    }
    setState(() {
      _galleryTouched = true;
      _gallery.removeAt(index);
      if (_gallery.isEmpty) {
        _galleryClearedByUser = true;
      }
    });
  }

  bool get _existingHasPhotos {
    final existing = widget.existing;
    if (existing == null) {
      return false;
    }
    return existingProductHasPhotos(
      photoUrls: existing.photoUrls,
      coverUrl: existing.coverUrl,
    );
  }

  bool get _preserveExistingPhotos => shouldPreserveExistingPhotos(
        galleryEmpty: _gallery.isEmpty,
        userClearedGallery: _galleryClearedByUser,
        existingHasPhotos: _existingHasPhotos,
      );

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
    });
  }

  void _setCheckIn(DateTime day) {
    setState(() {
      _departureStart = DateTime(day.year, day.month, day.day);
      _seats.syncPackageDeparture(_departureStart);
    });
  }

  void _setCheckOut(DateTime day) {
    final start = _departureStart;
    if (start == null) {
      setState(() {
        _departureStart = DateTime(day.year, day.month, day.day);
        _packageNights = 0;
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

  void _reveal(int index) {
    final step = briefStepForSection(index);
    if (_stepIndex != step) {
      _goToStep(step, revealSection: index);
      return;
    }
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

  void _clearPriceErrors() {
    _diverPriceError = null;
    _nondiverPriceError = null;
    _childPriceError = null;
    for (final draft in _addons) {
      draft.priceError = null;
    }
    for (final ticket in _individuals) {
      ticket.priceError = null;
      for (final draft in ticket.addons) {
        draft.priceError = null;
      }
    }
  }

  List<WorkbenchNamedOptionPrice> _namedOptionPrices() {
    return [
      for (final draft in _addons)
        if (draft.name.text.trim().isNotEmpty)
          WorkbenchNamedOptionPrice(
            name: draft.name.text.trim(),
            priceRaw: draft.consumer.text,
          ),
      for (final ticket in _individuals) ...[
        if (ticket.name.text.trim().isNotEmpty)
          WorkbenchNamedOptionPrice(
            name: ticket.name.text.trim(),
            priceRaw: ticket.consumer.text,
          ),
        for (final draft in ticket.addons)
          if (draft.name.text.trim().isNotEmpty)
            WorkbenchNamedOptionPrice(
              name: draft.name.text.trim(),
              priceRaw: draft.consumer.text,
            ),
      ],
    ];
  }

  /// First named option row that fails price parse (addons → individuals → ticket addons).
  ({FocusNode focus, void Function(String?) setError})? _findFailedOptionTarget(
    String optionName,
  ) {
    for (final draft in _addons) {
      if (draft.name.text.trim() == optionName &&
          parsePositivePrice(draft.consumer.text) == null) {
        return (focus: draft.consumerFocus, setError: (e) => draft.priceError = e);
      }
    }
    for (final ticket in _individuals) {
      if (ticket.name.text.trim() == optionName &&
          parsePositivePrice(ticket.consumer.text) == null) {
        return (
          focus: ticket.consumerFocus,
          setError: (e) => ticket.priceError = e,
        );
      }
      for (final draft in ticket.addons) {
        if (draft.name.text.trim() == optionName &&
            parsePositivePrice(draft.consumer.text) == null) {
          return (
            focus: draft.consumerFocus,
            setError: (e) => draft.priceError = e,
          );
        }
      }
    }
    return null;
  }

  void _focusPriceField(FocusNode focus) {
    focus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = focus.context;
      if (target == null || !mounted) {
        return;
      }
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 280),
        alignment: 0.15,
      );
    });
  }

  /// Blocks save when diver (always) / nondiver·child (switch on) / named
  /// option prices are empty, zero, negative, or over the 1억 unit cap.
  /// Edit screen still opens for legacy bad prices — only save is refused.
  bool _validatePricesBeforeSave(AppLocalizations l10n) {
    final check = checkWorkbenchPrices(
      diverRaw: _rateConsumer[GuestRole.diver]!.text,
      hasNondivers: _hasNondivers,
      nondiverRaw: _rateConsumer[GuestRole.nondiver]!.text,
      childRaw: _rateConsumer[GuestRole.child]!.text,
      namedOptions: _namedOptionPrices(),
    );
    if (check.isOk) {
      setState(_clearPriceErrors);
      return true;
    }
    final target = check.target!;
    final optionName = check.optionName?.trim() ?? '';
    final overCap = check.failure == WorkbenchPriceParseFailure.overCap;
    final message = overCap
        ? (target == WorkbenchPriceTarget.option && optionName.isNotEmpty
            ? l10n.workbenchPriceOverCapNamed(optionName)
            : l10n.workbenchPriceOverCap)
        : switch (target) {
            WorkbenchPriceTarget.diver => l10n.workbenchNeedDiverPrice,
            WorkbenchPriceTarget.nondiver || WorkbenchPriceTarget.child =>
              l10n.workbenchNeedGuestPrice,
            WorkbenchPriceTarget.option => optionName.isEmpty
                ? l10n.workbenchNeedOptionPrice
                : l10n.workbenchNeedOptionPriceNamed(optionName),
          };
    final optionTarget = target == WorkbenchPriceTarget.option &&
            optionName.isNotEmpty
        ? _findFailedOptionTarget(optionName)
        : null;
    final focus = switch (target) {
      WorkbenchPriceTarget.diver => _diverPriceFocus,
      WorkbenchPriceTarget.nondiver => _nondiverPriceFocus,
      WorkbenchPriceTarget.child => _childPriceFocus,
      WorkbenchPriceTarget.option =>
        optionTarget?.focus ?? _diverPriceFocus,
    };
    setState(() {
      _clearPriceErrors();
      switch (target) {
        case WorkbenchPriceTarget.diver:
          _diverPriceError = message;
        case WorkbenchPriceTarget.nondiver:
          _nondiverPriceError = message;
        case WorkbenchPriceTarget.child:
          _childPriceError = message;
        case WorkbenchPriceTarget.option:
          optionTarget?.setError(message);
      }
    });
    _reveal(3);
    _focusPriceField(focus);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    return false;
  }

  ProductListingKind _shelfKindForSave(ShopProduct? existing) {
    final current = existing?.listingKind;
    if (current != null && current != ProductListingKind.exploreOnly) {
      return current;
    }
    if (widget.creatorMode) {
      return ProductListingKind.diverPlanned;
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

  /// Returns true when Firestore/local save finished successfully.
  Future<bool> _save(ProductSaveIntent intent) async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (_savingIntent != null) {
      return false;
    }
    final isTemp = intent == ProductSaveIntent.keepEditing;
    if (widget.partnerMode) {
      // H1b: name + base price for both temp and publish; photos optional.
      // Named option/individual rows still need prices (same as before).
      if (!_validatePartnerRequired(l10n)) {
        return false;
      }
      if (!_validatePricesBeforeSave(l10n)) {
        return false;
      }
    } else {
      final pendingTemp = isTemp &&
          _editingPublishStatus == ProductPublishStatus.pending;
      if (pendingTemp) {
        if (!_validatePendingTempSave(l10n)) {
          return false;
        }
      } else if (!isTemp) {
        if (name.isEmpty) {
          _reveal(0);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.workbenchNeedName)));
          return false;
        }
        if (_namedResort && _resortName.text.trim().isEmpty) {
          _reveal(1);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.productFormCuratedResort)),
          );
          return false;
        }
        if (!_validatePricesBeforeSave(l10n)) {
          return false;
        }
      }
    }
    final store = DiverStoreScope.of(context);
    _seats.isAdmin = store.stats.isAdmin;
    _syncSeatSlots();
    final validateSeats = !isTemp &&
        (_adminSameBoatFields(store) ||
            widget.existing?.openEmptySeats == true);
    if (validateSeats) {
      final seatError = _seats.validate(l10n, now: DateTime.now());
      if (seatError != null) {
        _reveal(4);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(seatError)));
        return false;
      }
    }
    final existing = widget.existing;
    // Creator rejected → resubmit gate only. Partners publish immediately (H1a).
    final isResubmit = widget.creatorMode &&
        existing?.publishStatus == ProductPublishStatus.rejected &&
        intent != ProductSaveIntent.keepEditing;
    setState(() => _savingIntent = intent);
    try {
      final sessionUid = store.uid ?? '';
      final diverConsumer =
          parsePositivePrice(_rateConsumer[GuestRole.diver]!.text) ?? 0;
      final diverRate = GuestRate(
        role: GuestRole.diver,
        enabled: _rateEnabled[GuestRole.diver] ?? true,
        consumer: diverConsumer,
        professional: diverConsumer,
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
            consumer: parsePositivePrice(_rateConsumer[role]!.text) ?? 0,
            professional: parsePositivePrice(_rateConsumer[role]!.text) ?? 0,
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
        for (final ticket in _individuals)
          if (ticket.name.text.trim().isNotEmpty) ...[
            ticket.toOption(),
            ...ticket.addonOptions(),
          ],
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
      final productId = existing?.id.isNotEmpty == true
          ? existing!.id
          : (_persistedProductId ??
              'p-${DateTime.now().millisecondsSinceEpoch}');
      final drafted = ShopProduct(
        id: productId,
        shopId: shopId,
        name: name,
        consumerPrice: diverRate.consumer,
        professionalPrice: diverRate.professional,
        active: existing?.active ?? true,
        blurb: _blurb.text.trim(),
        durationLabel: _durationLabelForSave,
        coverUrl: _preserveExistingPhotos
            ? (existing?.coverUrl ?? '')
            : _galleryCoverUrl,
        continent: _continent,
        meetingPoint: _meeting.text.trim(),
        schedule: _detailBody.text.trim(),
        includes: _includes.text.trim(),
        excludes: _excludes.text.trim(),
        difficulty: '',
        // min/max guests are not on the form; leave defaults so merge keeps
        // any legacy min_guests on the document (checkout ignores min).
        cancellationNote: _cancel.text.trim(),
        category: _categoryForSave,
        detail: existing?.detail ?? '',
        photoUrls: _preserveExistingPhotos
            ? (existing?.photoUrls ?? const <String>[])
            : [
                for (final item in _gallery)
                  if (item.url != null && item.url!.isNotEmpty) item.url!,
              ],
        // Folded into schedule on open; clear so detail/duration stay in sync.
        itineraryDays: const [],
        guestRates: guestRates,
        focPayCount: existing?.focPayCount ?? 0,
        focFreeCount: existing?.focFreeCount ?? 0,
        focAppliesTo: existing?.focAppliesTo ?? GuestRole.diver,
        openEmptySeats: existing?.openEmptySeats ?? false,
        capacity: existing?.capacity ?? 0,
        bookedSeats: existing?.bookedSeats ?? 0,
        flagHolds: existing?.flagHolds ?? const [],
        departureStart: _departureStart,
        flagClosesAt: existing?.flagClosesAt,
        sameBoatStatus: existing?.sameBoatStatus ?? SameBoatStatus.closed,
        options: [for (final option in options) _withSeatOption(option)],
        listingKind: _shelfKindForSave(existing),
        featuredAt: _featuredAtForSave(existing),
        publishStatus:
            existing?.publishStatus ?? ProductPublishStatus.approved,
        submittedAt: existing?.submittedAt,
        reviewedAt: existing?.reviewedAt,
        reviewNote: existing?.reviewNote ?? '',
        rejectedContentHash: existing?.rejectedContentHash ?? '',
        rejectedReasonTags: existing?.rejectedReasonTags ?? const [],
        rejectedSectionHashes: existing?.rejectedSectionHashes ?? const {},
        resubmitCount: existing?.resubmitCount ?? 0,
        resubmitNote: existing?.resubmitNote ?? '',
        submittedByUid: existing?.submittedByUid.isNotEmpty == true
            ? existing!.submittedByUid
            : sessionUid,
      );
      var product = _seats.applyToProduct(drafted);
      // null gallery = leave Firestore photo_urls/cover_url unchanged.
      // Empty list = user cleared photos. Non-empty = upload/keep listed URLs.
      final List<ShopGallerySlot>? galleryArg = _preserveExistingPhotos
          ? null
          : _gallerySlots;
      if (isResubmit) {
        // 1) Hard gate (build 2) → 2) soft warn (build 3B) → 3) fix note.
        ProductPublishGuard.assertChangedSinceReject(
          previous: existing!,
          next: product,
          pendingGallery: galleryArg,
        );
        if (ProductPublishGuard.shouldWarnUntouchedTaggedSections(
          previous: existing,
          next: product,
          pendingGallery: galleryArg,
        )) {
          final untouched = ProductPublishGuard.untouchedTaggedSections(
            previous: existing,
            next: product,
            pendingGallery: galleryArg,
          );
          final proceed = await _confirmUntouchedTaggedSections(
            l10n,
            untouched,
          );
          if (proceed != true) {
            return false;
          }
        }
        final note = await _askResubmitNote(l10n);
        if (note == null) {
          return false;
        }
        product = product.copyWith(resubmitNote: note);
      }
      final effectiveIntent =
          widget.creatorMode && intent != ProductSaveIntent.keepEditing
              ? ProductSaveIntent.submitForReview
              : intent;

      // Partner live save: confirm when any unit price swings ±30%+.
      if (widget.partnerMode &&
          !widget.creatorMode &&
          effectiveIntent != ProductSaveIntent.keepEditing &&
          existing?.publishStatus == ProductPublishStatus.approved &&
          ProductPriceSwingGate.needsConfirm(
            previous: existing!,
            next: product,
          )) {
        final swings = ProductPriceSwingGate.findSwings(
          previous: existing,
          next: product,
        );
        final ok = await _confirmPriceSwing(l10n, swings);
        if (ok != true) {
          return false;
        }
      }

      await store.saveShopProduct(
        shopId: shopId,
        product: product,
        gallery: galleryArg,
        useAsResortCover: existing == null || _galleryTouched,
        creatorSubmission: widget.creatorMode,
        submitterUid: sessionUid,
        intent: effectiveIntent,
      );
      if (!mounted) {
        return false;
      }
      _persistedProductId = product.id;
      _baselineSignature = _formSignature();
      final savedText = _savedMessage(
        l10n,
        effectiveIntent,
        partnerLive: widget.partnerMode && !widget.creatorMode,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(savedText)),
      );
      // Temp save stays on the form; submit/publish leaves.
      if (effectiveIntent != ProductSaveIntent.keepEditing) {
        Navigator.of(context).pop();
      }
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      // Stay on the edit screen so partner inputs are preserved.
      final raw = '$error';
      final message = raw.contains('SHOP_STAT_REFRESH_FAILED')
          ? l10n.shopStatRefreshFailed
          : (raw.contains('R2') || raw.contains('업로드')
              ? l10n.workbenchPhotoUploadFailed
              : raw
                  .replaceFirst('Bad state: ', '')
                  .replaceFirst('StateError: ', ''));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 8)),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() => _savingIntent = null);
      }
    }
  }

  Future<void> _handleSystemBack() async {
    if (_savingIntent != null) {
      return;
    }
    if (!_editing || !_isDirty) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }
    final l10n = AppLocalizations.of(context);
    final allowTemp = _canTempSave;
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          key: const Key('brief-leave-dialog'),
          title: Text(l10n.briefLeaveTitle),
          content: Text(l10n.briefLeaveBody),
          actions: [
            TextButton(
              key: const Key('brief-leave-stay'),
              onPressed: () => Navigator.pop(dialogContext, 'stay'),
              child: Text(l10n.briefLeaveStay),
            ),
            TextButton(
              key: const Key('brief-leave-discard'),
              onPressed: () => Navigator.pop(dialogContext, 'discard'),
              child: Text(l10n.briefLeaveDiscard),
            ),
            if (allowTemp)
              FilledButton(
                key: const Key('brief-leave-temp-save'),
                onPressed: () => Navigator.pop(dialogContext, 'temp'),
                child: Text(l10n.briefLeaveTempSave),
              ),
          ],
        );
      },
    );
    if (!mounted) {
      return;
    }
    if (choice == 'discard') {
      Navigator.of(context).pop();
      return;
    }
    if (choice == 'temp') {
      final ok = await _save(ProductSaveIntent.keepEditing);
      if (ok && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Soft confirm when tagged reject sections are all still unchanged.
  /// Returns true to continue, false/null to stay editing.
  Future<bool?> _confirmUntouchedTaggedSections(
    AppLocalizations l10n,
    List<String> untouchedTags,
  ) {
    final sections = [
      for (final tag in untouchedTags) productRejectTagLabel(l10n, tag),
    ].join(' · ');
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          key: const Key('partner-resubmit-soft-warn'),
          title: Text(l10n.partnerResubmitSoftWarnTitle),
          content: Text(l10n.partnerResubmitSoftWarnBody(sections)),
          actions: [
            TextButton(
              key: const Key('partner-resubmit-soft-warn-fix'),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.partnerResubmitSoftWarnFix),
            ),
            FilledButton(
              key: const Key('partner-resubmit-soft-warn-continue'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.partnerResubmitSoftWarnContinue),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _askResubmitNote(AppLocalizations l10n) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(l10n.partnerResubmitNoteTitle),
            content: TextField(
              key: const Key('partner-resubmit-note-field'),
              controller: controller,
              maxLength: ProductPublishGuard.resubmitNoteMaxLength,
              maxLines: 4,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.partnerResubmitNoteHint,
                helperText: l10n.partnerResubmitNoteHelper,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  MaterialLocalizations.of(dialogContext).cancelButtonLabel,
                ),
              ),
              FilledButton(
                key: const Key('partner-resubmit-note-submit'),
                onPressed: () {
                  final note = controller.text.trim();
                  if (note.length < ProductPublishGuard.resubmitNoteMinLength) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ProductPublishGuard.resubmitNoteTooShortMessage,
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, note);
                },
                child: Text(l10n.partnerProductResubmit),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    _seats.isAdmin = store.stats.isAdmin;
    if (widget.partnerMode) {
      return PartnerTheme.wrap(_buildPartnerScaffold(l10n, store));
    }
    final shopLocked = widget.lockedShopId != null;
    final shops = shopLocked
        ? [DiveShopCatalog.byId(_shopId) ?? DiveShopCatalog.shops.first]
        : _shopsForContinent;
    final hull = DiveShopCatalog.byId(_shopId);
    final canPublish = store.stats.isAdmin &&
        !widget.partnerMode &&
        !widget.creatorMode;
    final busy = _savingIntent != null;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        unawaited(_handleSystemBack());
      },
      child: Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        title: Text(
          widget.creatorMode ? l10n.profileCraftNewTrip : l10n.briefTitle,
        ),
        backgroundColor: AppTheme.canvas,
        actions: [
          if (_editing && _canTempSave)
            TextButton(
              key: const Key('brief-temp-save'),
              onPressed: busy
                  ? null
                  : () => unawaited(_save(ProductSaveIntent.keepEditing)),
              child: Text(
                busy && _savingIntent == ProductSaveIntent.keepEditing
                    ? l10n.exploreSaving
                    : l10n.briefTempSave,
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final showSidePreview = wide;
          final showMobilePreview = !wide && _stepIndex == 2;
          // IgnorePointer is applied to scroll *children* in _brief / _guestCard
          // so view mode can still scroll while blocking field taps.
          final brief = Opacity(
            opacity: _editing ? 1 : 0.92,
            child: _brief(
              l10n,
              shops,
              shopLocked,
              showMobilePreview: showMobilePreview,
              hull: hull,
              adminSameBoat: _adminSameBoatFields(store),
            ),
          );
          final guest = Opacity(
            opacity: _editing ? 1 : 0.92,
            child: _guestCard(l10n, hull),
          );
          return Column(
            children: [
              ProductBriefStepper(
                stepIndex: _stepIndex,
                // Allow browsing steps in view mode; fields stay IgnorePointer.
                enabled: true,
                onStepTap: (i) => _goToStep(i),
              ),
              Expanded(
                child: showSidePreview
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: brief),
                          SizedBox(
                            width: 280,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 12, 16, 12),
                              child: guest,
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
    ),
    );
  }

  Widget _buildPartnerScaffold(AppLocalizations l10n, DiverStore _) {
    final busy = _savingIntent != null;
    final approved =
        widget.existing?.publishStatus == ProductPublishStatus.approved;
    final primaryLabel = approved ? l10n.briefSave : l10n.partnerProductPublishCta;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        unawaited(_handleSystemBack());
      },
      child: Scaffold(
        backgroundColor: PartnerTheme.bg,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          leading: PartnerBackButton(onPressed: () => unawaited(_handleSystemBack())),
          title: Text(l10n.briefTitle),
          actions: [
            if (_editing && _canTempSave)
              TextButton(
                key: const Key('brief-temp-save'),
                onPressed: busy
                    ? null
                    : () => unawaited(_save(ProductSaveIntent.keepEditing)),
                child: Text(
                  busy && _savingIntent == ProductSaveIntent.keepEditing
                      ? l10n.exploreSaving
                      : l10n.briefTempSave,
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                key: const Key('partner-product-form-scroll'),
                controller: _partnerScrollController,
                padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + keyboard),
                children: [
                  if (!_editing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        l10n.briefViewModeHint,
                        style: const TextStyle(
                          color: PartnerTheme.textDim,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  IgnorePointer(
                    ignoring: !_editing,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _partnerGuideBanner(l10n),
                        const SizedBox(height: 16),
                        _partnerSectionHeader(1, l10n.partnerFormSectionBasics),
                        const SizedBox(height: 10),
                        _partnerBasicsSection(l10n),
                        const SizedBox(height: 20),
                        _partnerSectionHeader(2, l10n.partnerFormSectionPricing),
                        const SizedBox(height: 10),
                        _partnerPricingSection(l10n),
                        const SizedBox(height: 20),
                        _partnerSectionHeader(3, l10n.partnerFormSectionPublish),
                        const SizedBox(height: 10),
                        _partnerPublishSection(l10n),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    if (_canTempSave) ...[
                      Expanded(
                        child: OutlinedButton(
                          key: const Key('partner-form-temp-save'),
                          onPressed: busy
                              ? null
                              : () => unawaited(
                                    _save(ProductSaveIntent.keepEditing),
                                  ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(
                            busy &&
                                    _savingIntent ==
                                        ProductSaveIntent.keepEditing
                                ? l10n.exploreSaving
                                : l10n.briefTempSave,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: _canTempSave ? 2 : 1,
                      child: FilledButton(
                        key: const Key('partner-product-save'),
                        onPressed: !_editing || busy
                            ? (_editing
                                ? null
                                : () => setState(() => _editing = true))
                            : () => unawaited(
                                  _save(ProductSaveIntent.submitForReview),
                                ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: PartnerTheme.accent,
                          foregroundColor: PartnerTheme.bg,
                        ),
                        child: Text(
                          !_editing
                              ? l10n.briefEdit
                              : (busy &&
                                      _savingIntent != null &&
                                      _savingIntent !=
                                          ProductSaveIntent.keepEditing
                                  ? l10n.exploreSaving
                                  : primaryLabel),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _partnerGuideBanner(AppLocalizations l10n) {
    return Material(
      key: const Key('partner-form-soft-guide'),
      color: PartnerTheme.badgeBlueBg,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Text(
          l10n.partnerFormSoftGuide,
          style: const TextStyle(
            color: PartnerTheme.badgeBlueFg,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _partnerSectionHeader(int index, String title) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: PartnerTheme.accent,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              color: PartnerTheme.bg,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: PartnerTheme.text,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _partnerRequiredBadge(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: PartnerTheme.badgeOrangeBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        l10n.partnerFormRequiredBadge,
        style: const TextStyle(
          color: PartnerTheme.badgeOrangeFg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  InputDecoration _partnerField(
    String label, {
    String? hint,
    String? errorText,
    int lines = 1,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      alignLabelWithHint: lines > 1,
      filled: true,
      fillColor: PartnerTheme.bg,
      labelStyle: const TextStyle(color: PartnerTheme.textDim),
      hintStyle: const TextStyle(color: PartnerTheme.textDim),
      errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: PartnerTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: PartnerTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: PartnerTheme.accent, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
      ),
    );
  }

  Widget _partnerBasicsSection(AppLocalizations l10n) {
    final chip = selectedPartnerCategoryChip(_category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.partnerFormPhotoOptionalHint,
          style: const TextStyle(color: PartnerTheme.textDim, fontSize: 12),
        ),
        const SizedBox(height: 8),
        BookingGalleryEditor(
          items: _gallery,
          onAdd: _addPhotos,
          onRemove: _removePhoto,
          onMakeCover: _makeCover,
          maxItems: _maxGallery,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              l10n.partnerDefaultProduct,
              style: const TextStyle(
                color: PartnerTheme.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            _partnerRequiredBadge(l10n),
          ],
        ),
        const SizedBox(height: 6),
        KeyedSubtree(
          key: _nameFieldKey,
          child: TextField(
            key: const Key('partner-product-name'),
            controller: _name,
            style: const TextStyle(color: PartnerTheme.text),
            cursorColor: PartnerTheme.accent,
            decoration: _partnerField(
              l10n.partnerDefaultProduct,
              hint: l10n.partnerFormNameHint,
              errorText: _name.text.trim().isEmpty && _diverPriceError != null
                  ? null
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _blurb,
          style: const TextStyle(color: PartnerTheme.text),
          cursorColor: PartnerTheme.accent,
          decoration: _partnerField(
            l10n.productFormSubtitle,
            hint: l10n.partnerFormBlurbHint,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.partnerFormProductType,
          style: const TextStyle(
            color: PartnerTheme.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _partnerTypeChip(
              key: 'partner-cat-resort',
              label: l10n.workbenchCatResort,
              selected: chip == ProductCategory.resortPackage,
              onTap: () => _onPartnerCategoryChip(ProductCategory.resortPackage),
            ),
            _partnerTypeChip(
              key: 'partner-cat-day',
              label: l10n.workbenchCatDay,
              selected: chip == ProductCategory.dayTrip,
              onTap: () => _onPartnerCategoryChip(ProductCategory.dayTrip),
            ),
            _partnerTypeChip(
              key: 'partner-cat-liveaboard',
              label: l10n.workbenchCatLiveaboard,
              selected: chip == ProductCategory.liveaboard,
              onTap: () => _onPartnerCategoryChip(ProductCategory.liveaboard),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('partner-form-nights'),
                controller: _nightsField,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: PartnerTheme.text),
                cursorColor: PartnerTheme.accent,
                decoration: _partnerField(l10n.partnerFormNights),
                onChanged: (_) => _onPartnerDurationEdited(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: const Key('partner-form-days'),
                controller: _daysField,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: PartnerTheme.text),
                cursorColor: PartnerTheme.accent,
                decoration: _partnerField(l10n.partnerFormDays),
                onChanged: (_) => _onPartnerDurationEdited(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _meeting,
          style: const TextStyle(color: PartnerTheme.text),
          cursorColor: PartnerTheme.accent,
          decoration: _partnerField(
            l10n.partnerFormMeeting,
            hint: l10n.productFormMeetingHint,
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: PartnerTheme.card,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.partnerFormShopInfoRow,
                    style: const TextStyle(
                      color: PartnerTheme.textDim,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('partner-form-shop-info'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ResortDeskScreen(
                          shopId: _shopId,
                          partnerMode: true,
                        ),
                      ),
                    );
                  },
                  child: Text(l10n.partnerFormShopInfoCta),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _partnerTypeChip({
    required String key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      key: Key(key),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: PartnerTheme.accent.withValues(alpha: 0.25),
      checkmarkColor: PartnerTheme.accent,
      labelStyle: TextStyle(
        color: selected ? PartnerTheme.accent : PartnerTheme.text,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      side: BorderSide(
        color: selected ? PartnerTheme.accent : PartnerTheme.borderStrong,
      ),
      backgroundColor: PartnerTheme.card,
    );
  }

  Widget _partnerPricingSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              l10n.partnerFormBasePrice,
              style: const TextStyle(
                color: PartnerTheme.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            _partnerRequiredBadge(l10n),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.partnerFormBasePriceHint,
          style: const TextStyle(color: PartnerTheme.textDim, fontSize: 12),
        ),
        const SizedBox(height: 8),
        KeyedSubtree(
          key: _diverPriceFieldKey,
          child: TextField(
            key: const Key('workbench-diver-price'),
            focusNode: _diverPriceFocus,
            controller: _rateConsumer[GuestRole.diver],
            keyboardType: TextInputType.number,
            maxLength: kWorkbenchPriceInputMaxLength,
            inputFormatters: _priceInputFormatters,
            style: const TextStyle(color: PartnerTheme.text, fontSize: 15),
            cursorColor: PartnerTheme.accent,
            decoration: _partnerField(
              l10n.partnerFormBasePrice,
              errorText: _diverPriceError,
            ).copyWith(counterText: ''),
            onChanged: (_) => setState(() => _diverPriceError = null),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          key: const Key('partner-form-guest-rates'),
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.partnerFormGuestRatesToggle,
            style: const TextStyle(color: PartnerTheme.text, fontSize: 13),
          ),
          value: _hasNondivers,
          activeThumbColor: PartnerTheme.accent,
          onChanged: (v) => setState(() => _hasNondivers = v),
        ),
        if (_hasNondivers) ...[
          TextField(
            focusNode: _nondiverPriceFocus,
            controller: _rateConsumer[GuestRole.nondiver],
            keyboardType: TextInputType.number,
            inputFormatters: _priceInputFormatters,
            style: const TextStyle(color: PartnerTheme.text),
            decoration: _partnerField(
              l10n.workbenchGuestNondiver,
              errorText: _nondiverPriceError,
            ),
            onChanged: (_) => setState(() => _nondiverPriceError = null),
          ),
          const SizedBox(height: 8),
          TextField(
            focusNode: _childPriceFocus,
            controller: _rateConsumer[GuestRole.child],
            keyboardType: TextInputType.number,
            inputFormatters: _priceInputFormatters,
            style: const TextStyle(color: PartnerTheme.text),
            decoration: _partnerField(
              l10n.workbenchGuestChild,
              errorText: _childPriceError,
            ),
            onChanged: (_) => setState(() => _childPriceError = null),
          ),
        ],
        const SizedBox(height: 14),
        KeyedSubtree(
          key: _partnerAddonsKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.productFormSectionOptions,
                style: const TextStyle(
                  color: PartnerTheme.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < _addons.length; i++) ...[
                _partnerAddonRow(l10n, i),
                const SizedBox(height: 8),
              ],
              OutlinedButton(
                key: const Key('partner-form-add-option'),
                onPressed: () {
                  final line = _LineEditors(kind: ProductOptionKind.addon);
                  _listen(line.name);
                  _listen(line.consumer);
                  setState(() => _addons.add(line));
                },
                child: Text(l10n.partnerFormAddOption),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        KeyedSubtree(
          key: _partnerIndividualsKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.bookingEntryIndividuals,
                style: const TextStyle(
                  color: PartnerTheme.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < _individuals.length; i++) ...[
                _partnerIndividualCard(l10n, i),
                const SizedBox(height: 8),
              ],
              OutlinedButton(
                key: const Key('partner-form-add-individual'),
                onPressed: _addIndividualTicket,
                child: Text(l10n.partnerFormAddIndividual),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _includes,
          minLines: 2,
          maxLines: 4,
          style: const TextStyle(color: PartnerTheme.text),
          decoration: _partnerField(
            l10n.productFormIncludes,
            hint: l10n.productFormIncludesHint,
            lines: 2,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _excludes,
          minLines: 2,
          maxLines: 4,
          style: const TextStyle(color: PartnerTheme.text),
          decoration: _partnerField(
            l10n.productFormExcludes,
            hint: l10n.productFormExcludesHint,
            lines: 2,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _cancel,
          minLines: 2,
          maxLines: 4,
          style: const TextStyle(color: PartnerTheme.text),
          decoration: _partnerField(
            l10n.partnerFormCancelPolicy,
            hint: l10n.productFormCancelHint,
            lines: 2,
          ),
        ),
      ],
    );
  }

  Widget _optionGroupMenu({
    required String id,
    required String value,
    required ValueChanged<String> onChanged,
    required bool partner,
  }) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<String>(
      key: Key('option-group-$id'),
      initialValue: normalizeOptionGroup(value),
      isExpanded: true,
      decoration: partner
          ? _partnerField(l10n.productFormOptionGroup)
          : _bookingDense(l10n.productFormOptionGroup),
      items: [
        const DropdownMenuItem(
          value: '',
          child: Text(optionGroupUnsetLabel),
        ),
        for (final group in optionGroups)
          DropdownMenuItem(
            value: group.id,
            child: Text(group.nameKo),
          ),
      ],
      onChanged: (next) => onChanged(normalizeOptionGroup(next)),
    );
  }

  Widget _partnerAddonRow(AppLocalizations l10n, int index) {
    final draft = _addons[index];
    return Material(
      color: PartnerTheme.card,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: draft.name,
                    style: const TextStyle(color: PartnerTheme.text),
                    decoration: _partnerField(l10n.productFormOptionName),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    focusNode: draft.consumerFocus,
                    controller: draft.consumer,
                    keyboardType: TextInputType.number,
                    inputFormatters: _priceInputFormatters,
                    style: const TextStyle(color: PartnerTheme.text),
                    decoration: _partnerField(
                      l10n.productFormOptionConsumer,
                      errorText: draft.priceError,
                    ),
                    onChanged: (_) => setState(() => draft.priceError = null),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_closeOptionInsteadOfRemove(draft)) {
                      setState(() {});
                      return;
                    }
                    setState(() {
                      draft.dispose();
                      _addons.removeAt(index);
                    });
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: PartnerTheme.textDim,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _optionGroupMenu(
              id: draft.id,
              value: draft.group,
              partner: true,
              onChanged: (next) => setState(() => draft.group = next),
            ),
          ],
        ),
      ),
    );
  }

  Widget _partnerIndividualCard(AppLocalizations l10n, int index) {
    final ticket = _individuals[index];
    return Material(
      color: PartnerTheme.card,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ticket.name,
                    style: const TextStyle(color: PartnerTheme.text),
                    decoration: _partnerField(l10n.bookingEntryIndividualName),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _dropIndividual(ticket);
                      _individuals.removeAt(index);
                      _syncSeatSlots();
                    });
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: PartnerTheme.textDim,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _optionGroupMenu(
              id: ticket.id,
              value: ticket.group,
              partner: true,
              onChanged: (next) => setState(() => ticket.group = next),
            ),
            const SizedBox(height: 8),
            TextField(
              focusNode: ticket.consumerFocus,
              controller: ticket.consumer,
              keyboardType: TextInputType.number,
              inputFormatters: _priceInputFormatters,
              style: const TextStyle(color: PartnerTheme.text),
              decoration: _partnerField(
                l10n.partnerFormBasePrice,
                errorText: ticket.priceError,
              ),
              onChanged: (_) => setState(() => ticket.priceError = null),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ticket.includes,
              minLines: 2,
              maxLines: 3,
              style: const TextStyle(color: PartnerTheme.text),
              decoration: _partnerField(
                l10n.productFormIncludes,
                lines: 2,
              ),
            ),
            const SizedBox(height: 8),
            for (var j = 0; j < ticket.addons.length; j++) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ticket.addons[j].name,
                          style: const TextStyle(color: PartnerTheme.text),
                          decoration: _partnerField(l10n.productFormOptionName),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          focusNode: ticket.addons[j].consumerFocus,
                          controller: ticket.addons[j].consumer,
                          keyboardType: TextInputType.number,
                          inputFormatters: _priceInputFormatters,
                          style: const TextStyle(color: PartnerTheme.text),
                          decoration: _partnerField(
                            l10n.productFormOptionConsumer,
                            errorText: ticket.addons[j].priceError,
                          ),
                          onChanged: (_) =>
                              setState(() => ticket.addons[j].priceError = null),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            ticket.addons[j].dispose();
                            ticket.addons.removeAt(j);
                          });
                        },
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: PartnerTheme.textDim,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _optionGroupMenu(
                    id: ticket.addons[j].id,
                    value: ticket.addons[j].group,
                    partner: true,
                    onChanged: (next) =>
                        setState(() => ticket.addons[j].group = next),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            TextButton(
              onPressed: () {
                final line = _LineEditors(kind: ProductOptionKind.addon);
                _listen(line.name);
                _listen(line.consumer);
                setState(() => ticket.addons.add(line));
              },
              child: Text(l10n.partnerFormIndividualOptions),
            ),
          ],
        ),
      ),
    );
  }

  Widget _partnerPublishSection(AppLocalizations l10n) {
    final name = _name.text.trim().isEmpty ? '—' : _name.text.trim();
    final blurb = _blurb.text.trim();
    final price = _diverPriceValue > 0 ? '$_diverPriceValue' : '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          key: const Key('partner-form-preview-card'),
          color: PartnerTheme.card,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: PartnerTheme.badgeGreenBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.partnerFormPreviewBadge,
                      style: const TextStyle(
                        color: PartnerTheme.badgeGreenFg,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: const TextStyle(
                    color: PartnerTheme.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (blurb.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    blurb,
                    style: const TextStyle(
                      color: PartnerTheme.textDim,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '${l10n.exploreConsumerPrice} $price',
                  style: const TextStyle(
                    color: PartnerTheme.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.partnerFormSameBoatNote,
          style: const TextStyle(
            color: PartnerTheme.textDim,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  String _savedMessage(
    AppLocalizations l10n,
    ProductSaveIntent intent, {
    bool partnerLive = false,
  }) {
    if (partnerLive && intent == ProductSaveIntent.submitForReview) {
      return l10n.partnerProductPublished;
    }
    return switch (intent) {
      ProductSaveIntent.keepEditing => l10n.briefKept,
      ProductSaveIntent.submitForReview => l10n.adminProductSubmitted,
      ProductSaveIntent.publish => l10n.adminProductApproved,
      ProductSaveIntent.takeDown => l10n.briefTakenDown,
      ProductSaveIntent.preserveListing => l10n.adminProductApproved,
    };
  }

  Future<bool?> _confirmPriceSwing(
    AppLocalizations l10n,
    List<ProductPriceSwing> swings,
  ) {
    final lines = swings
        .take(6)
        .map(
          (s) =>
              '${s.oldPrice} → ${s.newPrice} (${s.percent.isFinite ? s.percent.toStringAsFixed(0) : "—"}%)',
        )
        .join('\n');
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.partnerPriceSwingTitle),
        content: Text(
          '${l10n.partnerPriceSwingBody}\n\n$lines',
          style: const TextStyle(height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.profileFlagCancelCta),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.partnerPriceSwingConfirm),
          ),
        ],
      ),
    );
  }

  Widget _saveBar(AppLocalizations l10n, {required bool canPublish}) {
    final submitIntent = widget.creatorMode
        ? ProductSaveIntent.submitForReview
        : (canPublish
            ? ProductSaveIntent.publish
            : ProductSaveIntent.submitForReview);
    final busy = _savingIntent != null;
    final pending = canPublish &&
        (widget.existing?.publishStatus == ProductPublishStatus.pending);
    final onLastStep = _stepIndex >= _stepCount - 1;
    final partnerSaveLabel = widget.existing?.publishStatus ==
            ProductPublishStatus.approved
        ? l10n.briefSave
        : l10n.partnerProductPublish;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pending) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      key: Key('approve-product-${widget.existing!.id}'),
                      onPressed: busy ? null : () => _approveExisting(l10n),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        backgroundColor: AppTheme.navy,
                      ),
                      child: Text(l10n.adminApprove),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      key: Key('reject-product-${widget.existing!.id}'),
                      onPressed: busy ? null : () => _rejectExisting(l10n),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: Text(l10n.adminReject),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (!_editing)
              FilledButton(
                key: const Key('brief-edit'),
                onPressed: () => setState(() => _editing = true),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppTheme.navy,
                ),
                child: Text(l10n.briefEdit),
              )
            else
              Row(
                children: [
                  if (_stepIndex > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('brief-step-back'),
                        onPressed: busy
                            ? null
                            : () => _goToStep(_stepIndex - 1),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(l10n.briefStepBack),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      key: onLastStep
                          ? (canPublish
                              ? const Key('admin-product-submit')
                              : const Key('partner-product-save'))
                          : const Key('brief-step-next'),
                      onPressed: busy
                          ? null
                          : () {
                              if (onLastStep) {
                                _save(submitIntent);
                              } else {
                                _goToStep(_stepIndex + 1);
                              }
                            },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppTheme.navy,
                      ),
                      child: Text(
                        busy &&
                                _savingIntent != null &&
                                _savingIntent != ProductSaveIntent.keepEditing
                            ? l10n.exploreSaving
                            : (onLastStep
                                ? (canPublish
                                    ? l10n.briefSave
                                    : (widget.partnerMode
                                        ? partnerSaveLabel
                                        : l10n.briefSubmit))
                                : l10n.briefStepNext),
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

  Future<void> _approveExisting(AppLocalizations l10n) async {
    final existing = widget.existing;
    if (existing == null) {
      return;
    }
    if (!ProductPublishGuard.hasDiverPrice(existing)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminProductApproveNeedsPrice)),
      );
      return;
    }
    if (!ProductPublishGuard.hasValidPricesForApprove(existing)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminProductApproveOverCap)),
      );
      return;
    }
    setState(() => _savingIntent = ProductSaveIntent.publish);
    try {
      final probe = await DiverStoreScope.of(context).approveShopProduct(
        shopId: existing.shopId,
        productId: existing.id,
      );
      unawaited(probe.readFuture);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminProductApproved)),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) {
        setState(() => _savingIntent = null);
      }
    }
  }

  Future<void> _rejectExisting(AppLocalizations l10n) async {
    final existing = widget.existing;
    if (existing == null) {
      return;
    }
    final result = await showProductRejectDialog(context);
    if (result == null || !mounted) {
      return;
    }
    setState(() => _savingIntent = ProductSaveIntent.takeDown);
    try {
      final probe = await DiverStoreScope.of(context).rejectShopProduct(
        shopId: existing.shopId,
        productId: existing.id,
        reviewNote: result.note,
        reasonTags: result.reasonTags,
      );
      unawaited(probe.readFuture);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminProductRejected)),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) {
        setState(() => _savingIntent = null);
      }
    }
  }

  Widget _brief(
    AppLocalizations l10n,
    List<DiveShop> shops,
    bool shopLocked, {
    required bool showMobilePreview,
    required DiveShop? hull,
    required bool adminSameBoat,
  }) {
    final rejectNote = widget.existing?.reviewNote.trim() ?? '';
    final rejectTags = widget.existing?.rejectedReasonTags ?? const <String>[];
    // Creator-only reject banner (partners have no approval flow — H1a).
    final showRejectBanner = widget.creatorMode &&
        widget.existing?.publishStatus == ProductPublishStatus.rejected &&
        (rejectNote.isNotEmpty || rejectTags.isNotEmpty);
    return ListView(
      key: const Key('ops-product-brief-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (showRejectBanner)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RejectReasonBanner(
              note: rejectNote,
              tags: rejectTags,
              l10n: l10n,
            ),
          ),
        if (!_editing) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.briefViewModeHint,
              key: const Key('ops-product-view-hint'),
              style: const TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
          ),
        ],
        IgnorePointer(
          ignoring: !_editing,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_stepIndex == 0) ...[
                _shopInfoCard(l10n),
                _block(0, l10n.briefSectionCover, [_coverBlock(l10n)]),
                _block(1, l10n.briefSectionPlace, [
                  _placeBlock(l10n, shops, shopLocked),
                ]),
                _block(2, l10n.briefSectionDays, [_detailBlock(l10n)]),
              ] else if (_stepIndex == 1) ...[
                _block(3, l10n.briefSectionTerms, [_bookingEntryBlock(l10n)]),
              ] else ...[
                ProductSubmitChecklist(
                  checked: _checklist,
                  onChanged: (id, value) {
                    setState(() => _checklist[id] = value);
                  },
                ),
                const SizedBox(height: 12),
                if (showMobilePreview) ...[
                  _guestCard(l10n, hull),
                  const SizedBox(height: 12),
                ],
                if (adminSameBoat ||
                    widget.existing?.openEmptySeats == true)
                  _block(
                    4,
                    l10n.briefSectionSameBoat,
                    [_sameBoatSeatBlock(l10n)],
                  )
                else
                  _sameBoatPartnerHint(l10n),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _shopInfoCard(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        key: const Key('brief-shop-info-card'),
        color: const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.briefShopInfoTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.briefShopInfoBody,
                style: const TextStyle(color: AppTheme.muted, fontSize: 13),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('brief-shop-info-open'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ResortDeskScreen(shopId: _shopId),
                      ),
                    );
                  },
                  child: Text(l10n.briefShopInfoOpen),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sameBoatPartnerHint(AppLocalizations l10n) {
    return Material(
      key: const Key('brief-same-boat-partner-hint'),
      color: const Color(0xFFF3F6FA),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          l10n.briefSameBoatPartnerHint,
          style: const TextStyle(color: AppTheme.muted, fontSize: 13, height: 1.4),
        ),
      ),
    );
  }

  Widget _sameBoatSeatBlock(AppLocalizations l10n) {
    _syncSeatSlots();
    return SameBoatSeatOpenFields(
      controller: _seats,
      showPackageDeparturePicker: false,
      onChanged: () => setState(() {}),
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
                onTap: () =>
                    setState(() => _category = ProductCategory.resortPackage),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CategoryPick(
                label: l10n.workbenchCatLiveaboard,
                icon: Icons.directions_boat_outlined,
                selected: _category == ProductCategory.liveaboard,
                onTap: () =>
                    setState(() => _category = ProductCategory.liveaboard),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.exploreResortAddress)));
      return;
    }
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(query)}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.workbenchOpenMap)));
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
                const Icon(
                  Icons.place_outlined,
                  color: AppTheme.gold,
                  size: 20,
                ),
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

  Set<String> get _previewAddonIds {
    return {
      for (final draft in _addons)
        if (draft.name.text.trim().isNotEmpty && (_addonQty[draft.id] ?? 0) > 0)
          draft.id,
    };
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
      selectedOptionIds: _previewAddonIds,
      optionQuantities: {
        for (final draft in _addons)
          if (draft.name.text.trim().isNotEmpty)
            draft.id: _addonQty[draft.id] ?? 0,
      },
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

  /// White filled fields on the booking step — dark text for contrast.
  static const TextStyle _bookingFieldStyle = TextStyle(
    color: AppTheme.navy,
    fontWeight: FontWeight.w700,
    fontSize: 14,
  );

  InputDecoration _bookingDense(
    String label, {
    String? hint,
    int lines = 1,
    String? errorText,
    String? suffixText,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kBoxRadius),
      borderSide: const BorderSide(color: Color(0xFF94A3B8), width: 1.2),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kBoxRadius),
      borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.6),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      suffixText: suffixText,
      isDense: true,
      alignLabelWithHint: lines > 1,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: AppTheme.muted, fontSize: 12),
      hintStyle: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kBoxRadius),
        borderSide: const BorderSide(color: AppTheme.navy, width: 1.6),
      ),
      errorBorder: errorBorder,
      focusedErrorBorder: errorBorder,
    );
  }

  InputDecoration _priceFieldDecoration(
    AppLocalizations l10n, {
    String? errorText,
  }) {
    return _bookingDense(
      l10n.workbenchUnitPriceRequired,
      errorText: errorText,
      suffixText: l10n.workbenchCurrencyWon,
    );
  }

  Widget _bookingEntryBlock(AppLocalizations l10n) {
    final emptyName = _name.text.trim().isEmpty;
    final packageName = emptyName
        ? l10n.partnerDefaultProduct
        : _name.text.trim();
    final quote = _previewQuote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_kBoxRadius),
            border: Border.all(color: const Color(0xFFE2E8EE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.oceanDeep,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(_kBoxRadius),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.bookingEntryBasePackage,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        packageName,
                        style: TextStyle(
                          color: emptyName
                              ? Colors.white.withValues(alpha: 0.45)
                              : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.goldSoft,
                              borderRadius: BorderRadius.circular(_kBoxRadius),
                            ),
                            child: Text(
                              _nightsLabel,
                              style: const TextStyle(
                                color: AppTheme.navy,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const Key('workbench-diver-price'),
                      focusNode: _diverPriceFocus,
                      controller: _rateConsumer[GuestRole.diver],
                      keyboardType: TextInputType.number,
                      maxLength: kWorkbenchPriceInputMaxLength,
                      inputFormatters: _priceInputFormatters,
                      style: _bookingFieldStyle.copyWith(fontSize: 15),
                      cursorColor: AppTheme.navy,
                      decoration: _priceFieldDecoration(
                        l10n,
                        errorText: _diverPriceError,
                      ).copyWith(
                        counterText: '',
                        errorStyle: const TextStyle(
                          color: Color(0xFFE53935),
                          fontSize: 11,
                        ),
                      ),
                      onChanged: (_) => setState(() {
                        _diverPriceError = null;
                      }),
                    ),
                    const SizedBox(height: 10),
                    _stayDateStrip(l10n),
                    const SizedBox(height: 8),
                    Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 4),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text(
                          l10n.bookingEntryTermsToggle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        children: [
                          TextField(
                            controller: _includes,
                            minLines: 2,
                            maxLines: 4,
                            style: _bookingFieldStyle.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: _bookingDense(
                              l10n.productFormIncludes,
                              hint: l10n.productFormIncludesHint,
                              lines: 2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _excludes,
                            minLines: 2,
                            maxLines: 4,
                            style: _bookingFieldStyle.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: _bookingDense(
                              l10n.productFormExcludes,
                              hint: l10n.productFormExcludesHint,
                              lines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.workbenchGuestPreviewTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.workbenchGuestPreviewHint,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _guestStepperRow(
                      label: l10n.workbenchGuestDiver,
                      value: _previewDiver,
                      onChanged: (v) =>
                          setState(() => _previewDiver = v < 1 ? 1 : v),
                      priceLabel: l10n.workbenchUnitPriceRequired,
                      priceText:
                          _rateConsumer[GuestRole.diver]!.text.trim().isEmpty
                          ? '—'
                          : _rateConsumer[GuestRole.diver]!.text.trim(),
                    ),
                    const SizedBox(height: 4),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(_kBoxRadius),
                        border: Border.all(color: const Color(0xFFE2E8EE)),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: Text(
                              l10n.bookingEntryHasNondivers,
                              style: const TextStyle(fontSize: 13),
                            ),
                            value: _hasNondivers,
                            onChanged: _setHasNondivers,
                          ),
                          if (_hasNondivers) ...[
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                              child: Column(
                                children: [
                                  _guestStepperRow(
                                    label: l10n.bookingEntryAdultNondiver,
                                    value: _previewNondiver,
                                    onChanged: (v) =>
                                        setState(() => _previewNondiver = v),
                                    priceField:
                                        _rateConsumer[GuestRole.nondiver],
                                    priceLabel: l10n.workbenchUnitPriceRequired,
                                    priceFocus: _nondiverPriceFocus,
                                    priceError: _nondiverPriceError,
                                    onPriceChanged: () => setState(() {
                                      _nondiverPriceError = null;
                                    }),
                                  ),
                                  const SizedBox(height: 4),
                                  _guestStepperRow(
                                    label: l10n.bookingEntryChildInfant,
                                    value: _previewChild,
                                    onChanged: (v) =>
                                        setState(() => _previewChild = v),
                                    priceField: _rateConsumer[GuestRole.child],
                                    priceLabel: l10n.workbenchUnitPriceRequired,
                                    priceFocus: _childPriceFocus,
                                    priceError: _childPriceError,
                                    onPriceChanged: () => setState(() {
                                      _childPriceError = null;
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.bookingEntryAddons,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (var i = 0; i < _addons.length; i++) ...[
                      _bookingAddonRow(
                        l10n,
                        list: _addons,
                        qtyMap: _addonQty,
                        index: i,
                      ),
                      const SizedBox(height: 4),
                    ],
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          final line = _LineEditors(
                            kind: ProductOptionKind.addon,
                          );
                          _watchLine(line);
                          _listen(line.consumer);
                          setState(() {
                            _addons.add(line);
                            _addonQty[line.id] = 0;
                          });
                        },
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l10n.bookingEntryAddOption),
                      ),
                    ),
                  ],
                ),
              ),
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppTheme.navy,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(_kBoxRadius),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.checkoutTotal('${quote.total}'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.bookingEntryPreviewSnack),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.gold,
                          foregroundColor: AppTheme.navy,
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(l10n.exploreBook),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: TextField(
                  controller: _cancel,
                  maxLines: 1,
                  decoration: _bookingDense(
                    l10n.productFormCancelNote,
                    hint: l10n.productFormCancelHint,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.bookingEntryIndividuals,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.bookingEntryIndividualsHint,
          style: const TextStyle(
            color: AppTheme.muted,
            fontSize: 12,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _individuals.length; i++) ...[
          _individualTicketCard(l10n, i),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          onPressed: _addIndividualTicket,
          icon: const Icon(Icons.add),
          label: Text(l10n.bookingEntryAddIndividual),
        ),
      ],
    );
  }

  Widget _individualTicketCard(AppLocalizations l10n, int index) {
    final ticket = _individuals[index];
    final emptyName = ticket.name.text.trim().isEmpty;
    final quote = _individualQuote(ticket);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kBoxRadius),
        border: Border.all(color: const Color(0xFFE2E8EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppTheme.navyMid,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(_kBoxRadius),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.bookingEntryIndividuals,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        color: Colors.white70,
                        onPressed: () {
                          final existingOpt = _existingOption(ticket.id);
                          if (existingOpt != null &&
                              optionHasSeatCommitment(existingOpt)) {
                            setState(() => ticket.bookable = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.workbenchOptionClosedNotDeleted,
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _dropIndividual(ticket);
                            _individuals.removeAt(index);
                            _syncSeatSlots();
                          });
                        },
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                  TextField(
                    controller: ticket.name,
                    style: TextStyle(
                      color: emptyName
                          ? AppTheme.muted
                          : AppTheme.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                    cursorColor: AppTheme.navy,
                    decoration: InputDecoration(
                      hintText: l10n.bookingEntryIndividualName,
                      hintStyle: const TextStyle(
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w400,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_kBoxRadius),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_kBoxRadius),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_kBoxRadius),
                        borderSide: const BorderSide(
                          color: AppTheme.gold,
                          width: 1.4,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  _optionGroupMenu(
                    id: ticket.id,
                    value: ticket.group,
                    partner: false,
                    onChanged: (next) => setState(() => ticket.group = next),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.goldSoft,
                          borderRadius: BorderRadius.circular(_kBoxRadius),
                        ),
                        child: Text(
                          ticket.nightsLabel,
                          style: const TextStyle(
                            color: AppTheme.navy,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          focusNode: ticket.consumerFocus,
                          controller: ticket.consumer,
                          keyboardType: TextInputType.number,
                          maxLength: kWorkbenchPriceInputMaxLength,
                          inputFormatters: _priceInputFormatters,
                          style: _bookingFieldStyle,
                          cursorColor: AppTheme.navy,
                          decoration: InputDecoration(
                            labelText: l10n.bookingEntryDiverPrice,
                            labelStyle: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 12,
                            ),
                            errorText: ticket.priceError,
                            counterText: '',
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(_kBoxRadius),
                              borderSide: const BorderSide(
                                color: Color(0xFF94A3B8),
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(_kBoxRadius),
                              borderSide: const BorderSide(
                                color: AppTheme.navy,
                                width: 1.4,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(_kBoxRadius),
                              borderSide: const BorderSide(
                                color: Color(0xFFE53935),
                                width: 1.4,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(_kBoxRadius),
                              borderSide: const BorderSide(
                                color: Color(0xFFE53935),
                                width: 1.4,
                              ),
                            ),
                          ),
                          onChanged: (_) => setState(() {
                            ticket.priceError = null;
                          }),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _individualDateStrip(l10n, ticket),
                const SizedBox(height: 6),
                Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 4),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: Text(
                      l10n.bookingEntryTermsToggle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    children: [
                      TextField(
                        controller: ticket.includes,
                        minLines: 2,
                        maxLines: 4,
                        style: _bookingFieldStyle.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _bookingDense(
                          l10n.productFormIncludes,
                          hint: l10n.productFormIncludesHint,
                          lines: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: ticket.excludes,
                        minLines: 2,
                        maxLines: 4,
                        style: _bookingFieldStyle.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _bookingDense(
                          l10n.productFormExcludes,
                          hint: l10n.productFormExcludesHint,
                          lines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.checkoutGuests,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                _guestStepperRow(
                  label: l10n.workbenchGuestDiver,
                  value: ticket.guests,
                  onChanged: (v) =>
                      setState(() => ticket.guests = v < 1 ? 1 : v),
                  priceText: ticket.consumer.text.trim().isEmpty
                      ? '—'
                      : ticket.consumer.text.trim(),
                ),
                const SizedBox(height: 4),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(_kBoxRadius),
                    border: Border.all(color: const Color(0xFFE2E8EE)),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text(
                          l10n.bookingEntryHasNondivers,
                          style: const TextStyle(fontSize: 13),
                        ),
                        value: ticket.hasNondivers,
                        onChanged: (value) {
                          setState(() {
                            ticket.hasNondivers = value;
                            if (!value) {
                              ticket.nondivers = 0;
                              ticket.children = 0;
                            }
                          });
                        },
                      ),
                      if (ticket.hasNondivers) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                          child: Column(
                            children: [
                              _guestStepperRow(
                                label: l10n.bookingEntryAdultNondiver,
                                value: ticket.nondivers,
                                onChanged: (v) =>
                                    setState(() => ticket.nondivers = v),
                                priceText: ticket.consumer.text.trim().isEmpty
                                    ? '—'
                                    : ticket.consumer.text.trim(),
                              ),
                              const SizedBox(height: 4),
                              _guestStepperRow(
                                label: l10n.bookingEntryChildInfant,
                                value: ticket.children,
                                onChanged: (v) =>
                                    setState(() => ticket.children = v),
                                priceText: ticket.consumer.text.trim().isEmpty
                                    ? '—'
                                    : ticket.consumer.text.trim(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.bookingEntryAddons,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                for (var i = 0; i < ticket.addons.length; i++) ...[
                  _bookingAddonRow(
                    l10n,
                    list: ticket.addons,
                    qtyMap: ticket.addonQty,
                    index: i,
                    allowRemoveLast: true,
                  ),
                  const SizedBox(height: 4),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      final line = _LineEditors(kind: ProductOptionKind.addon);
                      _watchLine(line);
                      _listen(line.consumer);
                      setState(() {
                        ticket.addons.add(line);
                        ticket.addonQty[line.id] = 0;
                      });
                    },
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.bookingEntryAddOption),
                  ),
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppTheme.navy,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(_kBoxRadius),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.checkoutTotal('${quote.total}'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.bookingEntryPreviewSnack)),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: AppTheme.navy,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(l10n.exploreBook),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _individualDateStrip(AppLocalizations l10n, _IndividualTicket ticket) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(_kBoxRadius),
        border: Border.all(color: const Color(0xFFE2E8EE)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _dateCell(
                label: l10n.bookingEntryCheckIn,
                value: ticket.checkIn == null
                    ? l10n.bookingEntryPickDate
                    : _fmtDay(ticket.checkIn),
                onTap: () => _pickIndividualDate(ticket, checkout: false),
              ),
            ),
            Container(width: 1, color: const Color(0xFFE2E8EE)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: ticket.nights <= 0
                        ? null
                        : () => setState(() => ticket.nights -= 1),
                    icon: const Icon(Icons.remove, size: 16),
                  ),
                  Text(
                    ticket.nightsLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: AppTheme.navy,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: () => setState(() => ticket.nights += 1),
                    icon: const Icon(Icons.add, size: 16),
                  ),
                ],
              ),
            ),
            Container(width: 1, color: const Color(0xFFE2E8EE)),
            Expanded(
              child: _dateCell(
                label: l10n.bookingEntryCheckOut,
                value: ticket.checkOut == null
                    ? l10n.bookingEntryPickDate
                    : _fmtDay(ticket.checkOut),
                onTap: ticket.checkIn == null
                    ? null
                    : () => _pickIndividualDate(ticket, checkout: true),
                muted: ticket.checkIn == null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stayDateStrip(AppLocalizations l10n) {
    final stayLocked = _seats.packageScheduleLocked;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(_kBoxRadius),
        border: Border.all(color: const Color(0xFFE2E8EE)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _dateCell(
                label: l10n.bookingEntryCheckIn,
                value: _departureStart == null
                    ? l10n.bookingEntryPickDate
                    : _fmtDay(_departureStart),
                onTap: stayLocked ? null : () => _pickStayDate(checkout: false),
                muted: stayLocked,
              ),
            ),
            Container(width: 1, color: const Color(0xFFE2E8EE)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: _packageNights <= 0
                            ? null
                            : () => _setPackageNights(_packageNights - 1),
                        icon: const Icon(Icons.remove, size: 16),
                      ),
                      Text(
                        _nightsLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: AppTheme.navy,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: () => _setPackageNights(_packageNights + 1),
                        icon: const Icon(Icons.add, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(width: 1, color: const Color(0xFFE2E8EE)),
            Expanded(
              child: _dateCell(
                label: l10n.bookingEntryCheckOut,
                value: _checkOut == null
                    ? l10n.bookingEntryPickDate
                    : _fmtDay(_checkOut),
                onTap: stayLocked || _departureStart == null
                    ? null
                    : () => _pickStayDate(checkout: true),
                muted: stayLocked || _departureStart == null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateCell({
    required String label,
    required String value,
    VoidCallback? onTap,
    bool muted = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: muted ? AppTheme.muted : const Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: muted ? AppTheme.muted : AppTheme.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookingAddonRow(
    AppLocalizations l10n, {
    required List<_LineEditors> list,
    required Map<String, int> qtyMap,
    required int index,
    bool allowRemoveLast = false,
  }) {
    final draft = list[index];
    final qty = qtyMap[draft.id] ?? 0;
    final canRemove = allowRemoveLast || list.length > 1;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(_kBoxRadius),
        border: Border.all(color: const Color(0xFFE2E8EE)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: draft.name,
                style: _bookingFieldStyle.copyWith(fontWeight: FontWeight.w600),
                decoration: _bookingDense(l10n.bookingEntryOptionName),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 88,
              child: TextField(
                focusNode: draft.consumerFocus,
                controller: draft.consumer,
                keyboardType: TextInputType.number,
                maxLength: kWorkbenchPriceInputMaxLength,
                inputFormatters: _priceInputFormatters,
                style: _bookingFieldStyle,
                decoration: _bookingDense(
                  l10n.bookingEntryOptionPrice,
                  errorText: draft.priceError,
                ).copyWith(counterText: ''),
                onChanged: (_) => setState(() {
                  draft.priceError = null;
                }),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: qty <= 0
                  ? null
                  : () => setState(() => qtyMap[draft.id] = qty - 1),
              icon: const Icon(Icons.remove_circle_outline, size: 18),
            ),
            Text(
              '$qty',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => qtyMap[draft.id] = qty + 1),
              icon: const Icon(Icons.add_circle_outline, size: 18),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: l10n.productFormRemoveOption,
              onPressed: !canRemove
                  ? null
                  : () {
                      if (_closeOptionInsteadOfRemove(draft)) {
                        setState(() {});
                        return;
                      }
                      setState(() {
                        qtyMap.remove(draft.id);
                        _dropLine(draft);
                        list.removeAt(index);
                      });
                    },
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
            const SizedBox(height: 4),
            _optionGroupMenu(
              id: draft.id,
              value: draft.group,
              partner: false,
              onChanged: (next) => setState(() => draft.group = next),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guestStepperRow({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    String? priceLabel,
    String? priceText,
    TextEditingController? priceField,
    FocusNode? priceFocus,
    String? priceError,
    VoidCallback? onPriceChanged,
  }) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: value <= 0 ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove_circle_outline, size: 18),
        ),
        SizedBox(
          width: 22,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline, size: 18),
        ),
        const SizedBox(width: 4),
        Expanded(
          flex: 2,
          child: priceField != null
              ? TextField(
                  focusNode: priceFocus,
                  controller: priceField,
                  keyboardType: TextInputType.number,
                  maxLength: kWorkbenchPriceInputMaxLength,
                  inputFormatters: _priceInputFormatters,
                  decoration: _bookingDense(
                    priceLabel ?? '',
                    errorText: priceError,
                    suffixText: l10n.workbenchCurrencyWon,
                  ).copyWith(counterText: ''),
                  style: _bookingFieldStyle,
                  onChanged: (_) {
                    onPriceChanged?.call();
                    setState(() {});
                  },
                )
              : Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    priceText ?? '',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  ShopProduct get _draftProduct {
    final existing = widget.existing;
    final diverPrice =
        parsePositivePrice(_rateConsumer[GuestRole.diver]!.text) ?? 0;
    return ShopProduct(
      id: 'draft',
      shopId: _shopId,
      name: _name.text.trim().isEmpty ? '—' : _name.text.trim(),
      consumerPrice: diverPrice,
      professionalPrice: diverPrice,
      blurb: _blurb.text.trim(),
      durationLabel: _durationLabelForSave,
      guestRates: [
        for (final role in GuestRole.values)
          GuestRate(
            role: role,
            enabled: switch (role) {
              GuestRole.diver => true,
              GuestRole.nondiver || GuestRole.child => _hasNondivers,
              GuestRole.infant => false,
            },
            consumer: parsePositivePrice(_rateConsumer[role]!.text) ?? 0,
            professional: parsePositivePrice(_rateConsumer[role]!.text) ?? 0,
          ),
      ],
      options: [
        for (final draft in _addons)
          if (draft.name.text.trim().isNotEmpty)
            draft.toOption().copyWith(kind: ProductOptionKind.addon),
      ],
      focPayCount: existing?.focPayCount ?? 0,
      focFreeCount: existing?.focFreeCount ?? 0,
      focAppliesTo: existing?.focAppliesTo ?? GuestRole.diver,
    );
  }

  Widget _guestCard(AppLocalizations l10n, DiveShop? hull) {
    final quote = _previewQuote;
    final resort = _namedResort
        ? (_resortName.text.trim().isEmpty ? '—' : _resortName.text.trim())
        : (hull?.name ?? '');
    final diverRaw = _rateConsumer[GuestRole.diver]!.text.trim();
    final diverParsed = parseWorkbenchPrice(diverRaw);
    final startLabel = diverParsed.isOk
        ? '${diverParsed.value}'
        : (diverRaw.isEmpty ? '—' : diverRaw);
    final cover = _gallery.isEmpty ? null : _gallery.first;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kBoxRadius),
        border: Border.all(color: const Color(0xFFE2E8EE)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: IgnorePointer(
          ignoring: !_editing,
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
                '${l10n.briefStartPrice} $startLabel',
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
    final next = value.text.replaceRange(
      selection.start,
      selection.end,
      wrapped,
    );
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

  static const _tableSchedule =
      '| 시간 | 내용 |\n| --- | --- |\n|  |  |\n|  |  |\n';
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
                  onPressed: _preview ? null : () => _wrapSelection('**', '**'),
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
            decoration: widget.decoration.copyWith(alignLabelWithHint: true),
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

class _RejectReasonBanner extends StatefulWidget {
  const _RejectReasonBanner({
    required this.note,
    required this.l10n,
    this.tags = const [],
  });

  final String note;
  final List<String> tags;
  final AppLocalizations l10n;

  @override
  State<_RejectReasonBanner> createState() => _RejectReasonBannerState();
}

class _RejectReasonBannerState extends State<_RejectReasonBanner> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final long = widget.note.length > 120 || widget.note.contains('\n');
    return Material(
      key: const Key('partner-reject-reason-banner'),
      color: const Color(0xFFFFF1F0),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.l10n.partnerRejectReasonBanner,
              style: const TextStyle(
                color: Color(0xFF8B1A1A),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            if (widget.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final tag in widget.tags)
                    Chip(
                      key: Key('reject-banner-tag-$tag'),
                      label: Text(productRejectTagLabel(widget.l10n, tag)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8B1A1A),
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                ],
              ),
            ],
            if (widget.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                widget.note,
                maxLines: (!_expanded && long) ? 3 : null,
                overflow: (!_expanded && long)
                    ? TextOverflow.ellipsis
                    : TextOverflow.visible,
                style: const TextStyle(
                  color: Color(0xFF5C1A1A),
                  height: 1.4,
                ),
              ),
              if (long)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      _expanded
                          ? widget.l10n.partnerRejectReasonCollapse
                          : widget.l10n.partnerRejectReasonExpand,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
