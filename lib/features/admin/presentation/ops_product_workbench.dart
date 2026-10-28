import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:dive_travel_app/core/constants/gallery_limits.dart';
import 'package:dive_travel_app/core/constants/option_group.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/crafted_trip_seats.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/partner_product_form_fields.dart';
import 'package:dive_travel_app/core/models/price_revision.dart'
    show optionHasSeatCommitment;
import 'package:dive_travel_app/core/models/product_price_swing.dart';
import 'package:dive_travel_app/core/models/product_publish_guard.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/booking_gallery_editor.dart';
import 'package:dive_travel_app/features/admin/presentation/product_reject_dialog.dart';
import 'package:dive_travel_app/features/admin/presentation/workbench_gallery_preserve.dart';
import 'package:dive_travel_app/features/admin/presentation/workbench_price_validation.dart';
import 'package:dive_travel_app/features/explore/presentation/product_offer_box.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_back_button.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_form_focus.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seat_open_fields.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_screen.dart';
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

class _OfferDetailParts {
  const _OfferDetailParts({
    required this.lead,
    required this.includes,
    required this.excludes,
    required this.hasMarkers,
  });

  final String lead;
  final String includes;
  final String excludes;
  final bool hasMarkers;
}

_OfferDetailParts _splitOfferDetail(String raw) {
  final text = raw.trim();
  final marker = RegExp(r'(?:포함|불포함)\s*[:：]?');
  final hit = marker.firstMatch(text);
  if (hit == null) {
    return _OfferDetailParts(
      lead: text,
      includes: '',
      excludes: '',
      hasMarkers: false,
    );
  }
  final includeMatch = RegExp(
    r'포함\s*[:：]?\s*([\s\S]*?)(?=불포함\s*[:：]|$)',
  ).firstMatch(text);
  final excludeMatch = RegExp(r'불포함\s*[:：]?\s*([\s\S]*)$').firstMatch(text);
  return _OfferDetailParts(
    lead: text.substring(0, hit.start).trim(),
    includes: includeMatch?.group(1)?.trim() ?? '',
    excludes: excludeMatch?.group(1)?.trim() ?? '',
    hasMarkers: true,
  );
}

String _packOfferDetail(String lead, String includes, String excludes) {
  final head = lead.trim();
  final inc = includes.trim();
  final exc = excludes.trim();
  if (inc.isEmpty && exc.isEmpty) {
    return head;
  }
  return [
    if (head.isNotEmpty) head,
    if (inc.isNotEmpty) '포함:\n$inc',
    if (exc.isNotEmpty) '불포함:\n$exc',
  ].join('\n\n');
}

class _LineEditors {
  _LineEditors({
    String? id,
    String name = '',
    String description = '',
    String includes = '',
    String excludes = '',
    String consumer = '',
    String professional = '',
    this.kind = ProductOptionKind.addon,
    this.bookable = true,
    this.group = '',
  }) : id = id ?? 'opt-${DateTime.now().microsecondsSinceEpoch}',
       name = TextEditingController(text: name),
       description = TextEditingController(text: description),
       includes = TextEditingController(text: includes),
       excludes = TextEditingController(text: excludes),
       consumer = TextEditingController(text: consumer),
       professional = TextEditingController(text: professional),
       consumerFocus = FocusNode(),
       priceKey = GlobalKey();

  final String id;
  final TextEditingController name;
  final TextEditingController description;
  final TextEditingController includes;
  final TextEditingController excludes;
  final TextEditingController consumer;
  final TextEditingController professional;
  final FocusNode consumerFocus;
  final GlobalKey priceKey;
  String? priceError;
  ProductOptionKind kind;
  bool bookable;
  String group;

  void dispose() {
    name.dispose();
    description.dispose();
    includes.dispose();
    excludes.dispose();
    consumer.dispose();
    professional.dispose();
    consumerFocus.dispose();
  }

  ShopProductOption toOption() {
    final price = parsePositivePrice(consumer.text) ?? 0;
    return ShopProductOption(
      id: id,
      name: name.text.trim(),
      description: _packOfferDetail(
        description.text,
        includes.text,
        excludes.text,
      ),
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
    String lead = '',
    String consumer = '',
    String includes = '',
    String excludes = '',
    this.bookable = true,
    this.group = '',
    this.plainDescription = false,
  }) : id = id ?? 'ind-${DateTime.now().microsecondsSinceEpoch}',
       name = TextEditingController(text: name),
       lead = TextEditingController(text: lead),
       consumer = TextEditingController(text: consumer),
       includes = TextEditingController(text: includes),
       excludes = TextEditingController(text: excludes),
       consumerFocus = FocusNode(),
       priceKey = GlobalKey();

  factory _IndividualTicket.fromOption(ShopProductOption option) {
    final raw = option.description.trim();
    final parts = _splitOfferDetail(raw);
    return _IndividualTicket(
      id: option.id,
      name: option.name,
      lead: parts.hasMarkers ? parts.lead : '',
      consumer: option.consumerPrice > 0 ? '${option.consumerPrice}' : '',
      includes: parts.hasMarkers ? parts.includes : raw,
      excludes: parts.excludes,
      bookable: option.bookable,
      group: option.group,
      plainDescription: !parts.hasMarkers && raw.isNotEmpty,
    );
  }

  final String id;
  final TextEditingController name;
  final TextEditingController lead;
  final TextEditingController consumer;
  final TextEditingController includes;
  final TextEditingController excludes;
  final bool plainDescription;
  final FocusNode consumerFocus;
  final GlobalKey priceKey;
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

  String get descriptionText =>
      _packOfferDetail(lead.text, includes.text, excludes.text);

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
    lead.dispose();
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
  final _creatorOfferIds = <String>[];
  final _creatorDetailsOpen = <String>{};
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
  final _autosaveControllers = <TextEditingController>[];
  Timer? _creatorAutosaveTimer;
  var _autosaveSuspended = false;
  var _autosaveQueued = false;
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
  final _adminShopKey = GlobalKey();
  final _resortNameKey = GlobalKey();
  final _resortCountryKey = GlobalKey();
  final _resortRegionKey = GlobalKey();
  final _partnerAddonsKey = GlobalKey();
  final _partnerIndividualsKey = GlobalKey();
  ProductSaveIntent? _savingIntent;
  var _hasNondivers = false;
  final _addonQty = <String, int>{};
  var _namedResort = false;
  /// Creator shop picker: the single "내가 짜는 여행" choice was selected.
  var _creatorShopPicked = false;
  /// Creator resort fields fold only when the user taps 완료.
  var _creatorResortExpanded = true;
  /// Creator wizard step. 1 intro, 2 schedule, 3 price, 4–5 empty for now.
  var _creatorStep = 1;
  var _seededCreatorShop = false;
  DateTime? _departureStart;
  var _packageNights = 0;
  late bool _editing;
  late final SameBoatSeatOpenController _seats;
  /// After first temp-save of a new product, reuse this id on later saves.
  String? _persistedProductId;
  /// Form fingerprint after load / successful save (dirty detection).
  String? _baselineSignature;
  static final _priceInputFormatters = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[0-9,\s원]')),
    LengthLimitingTextInputFormatter(kWorkbenchPriceInputMaxLength),
  ];
  static final _wonPriceInputFormatters = <TextInputFormatter>[
    const WorkbenchWonInputFormatter(),
    LengthLimitingTextInputFormatter(kWorkbenchWonInputMaxLength),
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

  @override
  void initState() {
    super.initState();
    // H1a: ignore legacy price_revision / pending_options (do not overlay).
    final existing = widget.existing;
    _shopId = widget.lockedShopId ?? existing?.shopId ?? '';
    final shop = DiveShopCatalog.byId(_shopId);
    _continent = existing?.continent.isNotEmpty == true
        ? existing!.continent
        : (shop?.continent ?? ContinentId.asia);
    // Preserve stored category (funDive/course/…) until a chip is tapped (H1b).
    _category = existing?.category ?? ProductCategory.resortPackage;
    _categoryChipTouched = false;
    _namedResort = _shopId.startsWith('curated-');
    _creatorShopPicked = widget.creatorMode && _namedResort;
    _persistedProductId =
        existing?.id.isNotEmpty == true ? existing!.id : null;
    _name = TextEditingController(text: existing?.name ?? '');
    _resortName = TextEditingController(text: shop?.name ?? '');
    _resortCountry = TextEditingController(text: shop?.country ?? '');
    _resortRegion = TextEditingController(text: shop?.location ?? '');
    if (widget.creatorMode &&
        _resortName.text.trim().isEmpty &&
        (existing?.name ?? '').trim().isNotEmpty) {
      _resortName.text = existing!.name.trim();
    }
    _creatorResortExpanded = !_creatorResortComplete;
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
    if (widget.creatorMode) {
      for (final role in const [
        GuestRole.diver,
        GuestRole.nondiver,
        GuestRole.child,
      ]) {
        final controller = _rateConsumer[role]!;
        final formatted = formatWorkbenchWon(controller.text);
        if (formatted.isNotEmpty) {
          controller.text = formatted;
        }
      }
    }
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
    if (_addons.isEmpty && !widget.creatorMode) {
      _addons.add(_LineEditors(kind: ProductOptionKind.addon));
    }
    for (final line in _addons) {
      _addonQty.putIfAbsent(line.id, () => 0);
    }
    for (final ticket in _individuals) {
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
        ticket.addons.add(line);
        ticket.addonQty[line.id] = 0;
      }
    }
    if (widget.creatorMode) {
      for (final line in _addons) {
        final parts = _splitOfferDetail(line.description.text);
        if (parts.hasMarkers) {
          line.description.text = parts.lead;
          line.includes.text = parts.includes;
          line.excludes.text = parts.excludes;
        }
        final formatted = formatWorkbenchWon(line.consumer.text);
        if (formatted.isNotEmpty) {
          line.consumer.text = formatted;
        }
        _creatorOfferIds.add(line.id);
      }
      for (final ticket in _individuals) {
        if (ticket.plainDescription) {
          ticket.lead.text = ticket.includes.text;
          ticket.includes.clear();
        }
        final formatted = formatWorkbenchWon(ticket.consumer.text);
        if (formatted.isNotEmpty) {
          ticket.consumer.text = formatted;
        }
        for (final nested in ticket.addons) {
          final nestedPrice = formatWorkbenchWon(nested.consumer.text);
          if (nestedPrice.isNotEmpty) {
            nested.consumer.text = nestedPrice;
          }
        }
        _creatorOfferIds.add(ticket.id);
      }
    }
    _trackDraft(_name);
    _trackDraft(_blurb);
    _trackDraft(_detailBody);
    _trackDraft(_includes);
    _trackDraft(_excludes);
    _trackDraft(_resortName);
    _trackDraft(_rateConsumer[GuestRole.diver]!);
    _trackDraft(_rateConsumer[GuestRole.nondiver]!);
    _trackDraft(_rateConsumer[GuestRole.child]!);
    if (widget.creatorMode) {
      for (final controller in [
        _resortCountry,
        _resortRegion,
        _meeting,
        _cancel,
        _nightsField,
        _daysField,
      ]) {
        _bindCreatorAutosave(controller);
      }
      for (final line in _addons) {
        _bindCreatorLine(line);
      }
      for (final ticket in _individuals) {
        _bindCreatorTicket(ticket);
      }
    }
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

  bool get _creatorResortComplete =>
      _resortName.text.trim().isNotEmpty &&
      _resortCountry.text.trim().isNotEmpty &&
      _resortRegion.text.trim().isNotEmpty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seededCreatorShop || !widget.creatorMode || !_creatorShopPicked) {
      return;
    }
    _seededCreatorShop = true;
    final live = DiverStoreScope.of(context).liveStatsFor(_shopId);
    if (live == null) {
      return;
    }
    void fill(TextEditingController controller, String? value) {
      final next = (value ?? '').trim();
      if (controller.text.trim().isEmpty && next.isNotEmpty) {
        controller.text = next;
      }
    }

    final typedBeforeSeed =
        _resortName.text.trim().isNotEmpty ||
        _resortCountry.text.trim().isNotEmpty ||
        _resortRegion.text.trim().isNotEmpty;
    fill(_resortName, live.name);
    fill(_resortCountry, live.country);
    fill(_resortRegion, live.location);
    if (_name.text != _resortName.text) {
      _name.text = _resortName.text;
    }
    if (_creatorResortComplete && !typedBeforeSeed) {
      _creatorResortExpanded = false;
    }
  }

  void _collapseCreatorResort() {
    _name.text = _resortName.text;
    if (!_creatorResortComplete) {
      return;
    }
    setState(() => _creatorResortExpanded = false);
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
      for (final a in _addons)
        '${a.name.text}|${a.consumer.text}|${a.description.text}|${a.includes.text}|${a.excludes.text}',
    ].join(';');
    final ticketSig = [
      for (final t in _individuals)
        '${t.name.text}|${t.consumer.text}|${t.lead.text}|${t.includes.text}|${t.excludes.text}|${[
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
      _scrollToPartnerKey(_diverPriceFieldKey);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.briefTempSaveNeedPhoto)),
      );
      return false;
    }
    if (_name.text.trim().isEmpty) {
      _scrollToPartnerKey(_nameFieldKey);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.creatorMode
                ? l10n.productFormCuratedResort
                : l10n.workbenchNeedName,
          ),
        ),
      );
      return false;
    }
    if (_diverPriceValue <= 0) {
      _scrollToPartnerKey(_diverPriceFieldKey);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.briefTempSaveNeedPrice)),
      );
      return false;
    }
    return true;
  }

  /// Korean object particle so 「가격을」「국가를」 both read naturally.
  String _pleaseEnter(AppLocalizations l10n, String label) {
    final code = label.runes.isEmpty ? 0 : label.runes.last;
    final hangul = code >= 0xAC00 && code <= 0xD7A3;
    final hasBatchim = hangul && (code - 0xAC00) % 28 != 0;
    final particle = Localizations.localeOf(context).languageCode == 'ko'
        ? (!hangul || hasBatchim ? '을' : '를')
        : '';
    return l10n.productFormPleaseEnter(label, particle);
  }

  ButtonStyle _readableFilledStyle({double height = 48}) {
    return FilledButton.styleFrom(
      minimumSize: Size.fromHeight(height),
      backgroundColor: PartnerTheme.accent,
      foregroundColor: PartnerTheme.bg,
      disabledBackgroundColor: PartnerTheme.borderStrong,
      disabledForegroundColor: PartnerTheme.text,
    );
  }

  /// Partner H1b: name + base price only (photo optional) for temp and publish.
  bool _validatePartnerRequired(AppLocalizations l10n) {
    if (_name.text.trim().isEmpty) {
      _scrollToPartnerKey(_nameFieldKey);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_pleaseEnter(l10n, l10n.partnerDefaultProduct))),
      );
      return false;
    }
    if (_diverPriceValue <= 0) {
      _scrollToPartnerKey(_diverPriceFieldKey);
      final message = _pleaseEnter(l10n, l10n.partnerFormBasePrice);
      setState(() {
        _diverPriceError = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return false;
    }
    return true;
  }

  void _scrollToPartnerKey(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final target = key.currentContext;
      if (target == null) {
        return;
      }
      Scrollable.ensureVisible(
        target,
        duration: Duration.zero,
        alignment: 0.15,
      );
    });
  }

  String get _durationLabelForSave {
    final nights = int.tryParse(_nightsField.text.trim());
    final days = int.tryParse(_daysField.text.trim());
    return durationLabelForPartnerSave(
      originalLabel: _originalDurationLabel,
      userEditedFields: _durationFieldsTouched,
      nights: nights,
      days: days,
    );
  }

  ProductCategory get _categoryForSave {
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

  void _trackDraft(TextEditingController controller) {
    if (widget.creatorMode) {
      _bindCreatorAutosave(controller);
      return;
    }
    _listen(controller);
  }

  void _bindCreatorAutosave(TextEditingController controller) {
    if (!widget.creatorMode || _autosaveControllers.contains(controller)) {
      return;
    }
    controller.addListener(_armCreatorAutosave);
    _autosaveControllers.add(controller);
  }

  void _unbindCreatorAutosave(TextEditingController controller) {
    controller.removeListener(_armCreatorAutosave);
    _autosaveControllers.remove(controller);
  }

  void _bindCreatorLine(_LineEditors line) {
    _bindCreatorAutosave(line.name);
    _bindCreatorAutosave(line.description);
    _bindCreatorAutosave(line.includes);
    _bindCreatorAutosave(line.excludes);
    _bindCreatorAutosave(line.consumer);
    _bindCreatorAutosave(line.professional);
  }

  void _unbindCreatorLine(_LineEditors line) {
    _unbindCreatorAutosave(line.name);
    _unbindCreatorAutosave(line.description);
    _unbindCreatorAutosave(line.includes);
    _unbindCreatorAutosave(line.excludes);
    _unbindCreatorAutosave(line.consumer);
    _unbindCreatorAutosave(line.professional);
  }

  void _bindCreatorTicket(_IndividualTicket ticket) {
    _bindCreatorAutosave(ticket.name);
    _bindCreatorAutosave(ticket.lead);
    _bindCreatorAutosave(ticket.consumer);
    _bindCreatorAutosave(ticket.includes);
    _bindCreatorAutosave(ticket.excludes);
    for (final line in ticket.addons) {
      _bindCreatorLine(line);
    }
  }

  void _unbindCreatorTicket(_IndividualTicket ticket) {
    _unbindCreatorAutosave(ticket.name);
    _unbindCreatorAutosave(ticket.lead);
    _unbindCreatorAutosave(ticket.consumer);
    _unbindCreatorAutosave(ticket.includes);
    _unbindCreatorAutosave(ticket.excludes);
    for (final line in ticket.addons) {
      _unbindCreatorLine(line);
    }
  }

  void _onDraftChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Resets the 2s draft timer. Does not rebuild, so Hangul composing stays.
  void _armCreatorAutosave() {
    if (!widget.creatorMode) {
      return;
    }
    if (_autosaveSuspended) {
      _autosaveQueued = true;
      return;
    }
    _creatorAutosaveTimer?.cancel();
    _creatorAutosaveTimer = Timer(const Duration(seconds: 2), () {
      unawaited(_creatorAutosave());
    });
  }

  bool _creatorAutosaveReady() {
    if (!widget.creatorMode || !mounted || !_editing) {
      return false;
    }
    if (_savingIntent != null || !_canTempSave || !_isDirty) {
      return false;
    }
    if (!_creatorShopPicked || _resortName.text.trim().isEmpty) {
      return false;
    }
    if (widget.existing?.publishStatus == ProductPublishStatus.pending &&
        (!_hasPhotosForSave || _diverPriceValue <= 0)) {
      return false;
    }
    return true;
  }

  Future<void> _creatorAutosave() async {
    _creatorAutosaveTimer?.cancel();
    if (!_creatorAutosaveReady()) {
      return;
    }
    _autosaveSuspended = true;
    try {
      await _save(ProductSaveIntent.keepEditing, quiet: true);
    } finally {
      _autosaveSuspended = false;
      if (_autosaveQueued) {
        _autosaveQueued = false;
        if (_isDirty) {
          _armCreatorAutosave();
        }
      }
    }
  }

  @override
  void dispose() {
    _creatorAutosaveTimer?.cancel();
    for (final line in _addons) {
      _unbindCreatorLine(line);
    }
    for (final ticket in _individuals) {
      _unbindCreatorTicket(ticket);
    }
    for (final controller in List<TextEditingController>.of(
      _autosaveControllers,
    )) {
      _unbindCreatorAutosave(controller);
    }
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
    setState(() {
      _individuals.add(ticket);
      _syncSeatSlots();
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
  ({FocusNode focus, GlobalKey key, String label, void Function(String?) setError})?
  _findFailedOptionTarget(String optionName) {
    for (final draft in _addons) {
      if (draft.name.text.trim() == optionName &&
          parsePositivePrice(draft.consumer.text) == null) {
        return (
          focus: draft.consumerFocus,
          key: draft.priceKey,
          label: _optionPriceLabel(individual: false),
          setError: (e) => draft.priceError = e,
        );
      }
    }
    for (final ticket in _individuals) {
      if (ticket.name.text.trim() == optionName &&
          parsePositivePrice(ticket.consumer.text) == null) {
        return (
          focus: ticket.consumerFocus,
          key: ticket.priceKey,
          label: _optionPriceLabel(individual: true),
          setError: (e) => ticket.priceError = e,
        );
      }
      for (final draft in ticket.addons) {
        if (draft.name.text.trim() == optionName &&
            parsePositivePrice(draft.consumer.text) == null) {
          return (
            focus: draft.consumerFocus,
            key: draft.priceKey,
            label: _optionPriceLabel(individual: false),
            setError: (e) => draft.priceError = e,
          );
        }
      }
    }
    return null;
  }

  String _optionPriceLabel({required bool individual}) {
    final l10n = AppLocalizations.of(context);
    return individual ? l10n.partnerFormBasePrice : l10n.productFormOptionConsumer;
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
    final optionTarget = target == WorkbenchPriceTarget.option &&
            optionName.isNotEmpty
        ? _findFailedOptionTarget(optionName)
        : null;
    final message = overCap
        ? (target == WorkbenchPriceTarget.option && optionName.isNotEmpty
            ? l10n.workbenchPriceOverCapNamed(optionName)
            : l10n.workbenchPriceOverCap)
        : switch (target) {
            WorkbenchPriceTarget.diver =>
              _pleaseEnter(l10n, l10n.partnerFormBasePrice),
            WorkbenchPriceTarget.nondiver || WorkbenchPriceTarget.child =>
              l10n.workbenchNeedGuestPrice,
            WorkbenchPriceTarget.option => _pleaseEnter(
                l10n,
                optionTarget?.label ?? l10n.productFormOptionConsumer,
              ),
          };
    final focus = switch (target) {
      WorkbenchPriceTarget.diver => _diverPriceFocus,
      WorkbenchPriceTarget.nondiver => _nondiverPriceFocus,
      WorkbenchPriceTarget.child => _childPriceFocus,
      WorkbenchPriceTarget.option =>
        optionTarget?.focus ?? _diverPriceFocus,
    };
    setState(() {
      _clearPriceErrors();
      if (widget.creatorMode) {
        _creatorStep = target == WorkbenchPriceTarget.option ? 4 : 3;
      }
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
    if (optionTarget != null) {
      _scrollToPartnerKey(optionTarget.key);
    }
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

  void _classifyCreatorGroups() {
    if (!widget.creatorMode) {
      return;
    }
    for (final draft in _addons) {
      if (draft.name.text.trim().isEmpty) {
        continue;
      }
      draft.group = classifyOptionGroup(draft.name.text);
    }
    for (final ticket in _individuals) {
      if (ticket.name.text.trim().isEmpty) {
        continue;
      }
      ticket.group = classifyOptionGroup(ticket.name.text);
      for (final nested in ticket.addons) {
        if (nested.name.text.trim().isEmpty) {
          continue;
        }
        nested.group = classifyOptionGroup(nested.name.text);
      }
    }
  }

  List<ShopProductOption> _assembledOptions({
    required String name,
    required int diverPrice,
  }) {
    return [
      ShopProductOption(
        id: _baseOptionId,
        name: name,
        description: _blurb.text.trim(),
        consumerPrice: diverPrice,
        professionalPrice: diverPrice,
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
  }

  /// Returns true when Firestore/local save finished successfully.
  /// [quiet] is the creator draft timer and 「다음」: no snack, stay on the form.
  Future<bool> _save(ProductSaveIntent intent, {bool quiet = false}) async {
    final l10n = AppLocalizations.of(context);
    if (quiet && !_creatorAutosaveReady()) {
      return false;
    }
    if (widget.creatorMode) {
      final resort = _resortName.text.trim();
      if (_name.text != resort) {
        _name.text = resort;
      }
    }
    final name = _name.text.trim();
    if (_savingIntent != null) {
      return false;
    }
    if (!widget.partnerMode &&
        widget.lockedShopId == null &&
        !_namedResort &&
        _shopId.trim().isEmpty) {
      _scrollToPartnerKey(widget.creatorMode ? _nameFieldKey : _adminShopKey);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.productFormPickShop)),
      );
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
          _focusCreatorStep(1);
          _scrollToPartnerKey(
            widget.creatorMode ? _resortNameKey : _nameFieldKey,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _pleaseEnter(
                  l10n,
                  widget.creatorMode
                      ? l10n.productFormCuratedResort
                      : l10n.partnerDefaultProduct,
                ),
              ),
            ),
          );
          return false;
        }
        if (_namedResort && _resortName.text.trim().isEmpty) {
          _focusCreatorStep(1);
          _scrollToPartnerKey(_resortNameKey);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_pleaseEnter(l10n, l10n.productFormCuratedResort)),
            ),
          );
          return false;
        }
        if (widget.creatorMode && _resortCountry.text.trim().isEmpty) {
          _focusCreatorStep(1);
          _scrollToPartnerKey(_resortCountryKey);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_pleaseEnter(l10n, l10n.productFormCuratedCountry)),
            ),
          );
          return false;
        }
        if (widget.creatorMode && _resortRegion.text.trim().isEmpty) {
          _focusCreatorStep(1);
          _scrollToPartnerKey(_resortRegionKey);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_pleaseEnter(l10n, l10n.productFormCuratedLocation)),
            ),
          );
          return false;
        }
        if (!_validatePricesBeforeSave(l10n)) {
          return false;
        }
      }
    }
    final store = DiverStoreScope.of(context);
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
      _classifyCreatorGroups();
      final options = _assembledOptions(
        name: name,
        diverPrice: diverRate.consumer,
      );
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
          creatorProposal: widget.creatorMode,
          creatorUid: widget.creatorMode ? store.uid : null,
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
        // Seat fields are not sent. mergePersistedMap keeps the document's.
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
      var product = drafted;
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
      if (!quiet) {
        final savedText = _savedMessage(
          l10n,
          effectiveIntent,
          partnerLive: widget.partnerMode && !widget.creatorMode,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(savedText)),
        );
      }
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
      if (!quiet) {
        final raw = '$error';
        final message = raw.contains('SHOP_STAT_REFRESH_FAILED')
            ? l10n.shopStatRefreshFailed
            : (raw.contains('R2') || raw.contains('업로드')
                ? l10n.workbenchPhotoUploadFailed
                : raw
                    .replaceFirst('Bad state: ', '')
                    .replaceFirst('StateError: ', ''));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 8),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _savingIntent = null);
      }
    }
  }

  void _focusCreatorStep(int step) {
    if (!widget.creatorMode || _creatorStep == step) {
      return;
    }
    setState(() => _creatorStep = step);
  }

  void _creatorGo(int step) {
    if (step < 1 || step > 5 || step == _creatorStep) {
      return;
    }
    setState(() => _creatorStep = step);
  }

  void _creatorAdvance(int step) {
    if (step > _creatorStep) {
      unawaited(_creatorAutosave());
    }
    _creatorGo(step);
  }

  Future<void> _handleSystemBack() async {
    if (_savingIntent != null) {
      return;
    }
    if (widget.creatorMode && _creatorStep > 1) {
      _creatorGo(_creatorStep - 1);
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
              cursorColor: PartnerTheme.accent,
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
    return Theme(
      data: PartnerTheme.dark.copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: PartnerTheme.accent,
          selectionHandleColor: PartnerTheme.accent,
        ),
      ),
      child: _buildPartnerScaffold(l10n, store),
    );
  }

  Widget _buildPartnerScaffold(AppLocalizations l10n, DiverStore store) {
    final busy = _savingIntent != null;
    final approved =
        widget.existing?.publishStatus == ProductPublishStatus.approved;
    final primaryLabel = approved ? l10n.briefSave : l10n.partnerProductPublishCta;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final partnerChrome = widget.partnerMode;
    final canPublish =
        store.stats.isAdmin && !widget.partnerMode && !widget.creatorMode;
    final rejectNote = widget.existing?.reviewNote.trim() ?? '';
    final rejectTags = widget.existing?.rejectedReasonTags ?? const <String>[];
    final showRejectBanner = widget.creatorMode &&
        widget.existing?.publishStatus == ProductPublishStatus.rejected &&
        (rejectNote.isNotEmpty || rejectTags.isNotEmpty);
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
          leading: partnerChrome
              ? PartnerBackButton(
                  onPressed: () => unawaited(_handleSystemBack()),
                )
              : null,
          title: Text(
            widget.creatorMode ? l10n.profileCraftNewTrip : l10n.briefTitle,
          ),
          backgroundColor: PartnerTheme.bg,
          foregroundColor: PartnerTheme.text,
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
                        key: const Key('ops-product-view-hint'),
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
                        if (showRejectBanner)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RejectReasonBanner(
                              note: rejectNote,
                              tags: rejectTags,
                              l10n: l10n,
                            ),
                          ),
                        if (widget.creatorMode) ...[
                          _creatorProgress(l10n),
                          _creatorStepBody(l10n, store),
                        ] else ...[
                          _shopLine(l10n, store),
                          const SizedBox(height: 16),
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
                      ],
                    ),
                  ),
                  ..._openSeatsTail(l10n),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: partnerChrome
                  ? Padding(
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
                        style: _readableFilledStyle(),
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
              )
                  : _saveBar(l10n, canPublish: canPublish),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shopLine(AppLocalizations l10n, DiverStore store) {
    if (widget.creatorMode) {
      return KeyedSubtree(
        key: _nameFieldKey,
        child: _creatorShopLine(l10n),
      );
    }
    final locked = widget.partnerMode || widget.lockedShopId != null;
    final shop = DiveShopCatalog.byId(_shopId);
    if (locked) {
      return Text(
        shop?.name ?? _shopId,
        key: const Key('partner-product-shop'),
        style: const TextStyle(
          color: PartnerTheme.text,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      );
    }
    final shops = DiveShopCatalog.shops;
    final String? shopValue = _namedResort
        ? _kDirectShop
        : (shops.any((item) => item.id == _shopId)
              ? _shopId
              : (widget.existing == null
                    ? null
                    : (shops.isNotEmpty ? shops.first.id : _kDirectShop)));
    return KeyedSubtree(
      key: _adminShopKey,
      child: KeyedSubtree(
      key: const Key('admin-product-shop'),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('admin-product-shop-$_namedResort-$shopValue'),
          initialValue: shopValue,
          hint: Text(l10n.productFormPickShop),
          decoration: _field(l10n.productFormShopHint),
          items: [
            DropdownMenuItem(
              value: _kDirectShop,
              child: Text(l10n.productFormDirectSelect),
            ),
            for (final item in shops)
              DropdownMenuItem(value: item.id, child: Text(item.name)),
          ],
          onChanged: (value) {
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
        if (_namedResort) ...[
          const SizedBox(height: 12),
          KeyedSubtree(
            key: _resortNameKey,
            child: TextField(
              key: const Key('product-curated-resort'),
              controller: _resortName,
              decoration: _field(
                l10n.productFormCuratedResort,
                hint: l10n.productFormCuratedResortHint,
              ),
            ),
          ),
          const SizedBox(height: 12),
          KeyedSubtree(
            key: _resortCountryKey,
            child: TextField(
              controller: _resortCountry,
              decoration: _field(
                l10n.productFormCuratedCountry,
                hint: l10n.productFormCuratedCountryHint,
              ),
            ),
          ),
          const SizedBox(height: 12),
          KeyedSubtree(
            key: _resortRegionKey,
            child: TextField(
              controller: _resortRegion,
              decoration: _field(
                l10n.productFormCuratedLocation,
                hint: l10n.productFormCuratedLocationHint,
              ),
            ),
          ),
        ],
      ],
      ),
      ),
    );
  }

  Widget _creatorShopLine(AppLocalizations l10n) {
    final resortOpen = _creatorResortExpanded || !_creatorResortComplete;
    return KeyedSubtree(
      key: const Key('admin-product-shop'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_creatorShopPicked)
            DropdownButtonFormField<String>(
              key: const Key('creator-product-shop'),
              initialValue: null,
              hint: Text(l10n.productFormPickShop),
              decoration: _partnerField(l10n.productFormShopHint),
              dropdownColor: PartnerTheme.card,
              style: const TextStyle(color: PartnerTheme.text, fontSize: 16),
              items: [
                DropdownMenuItem(
                  value: _kDirectShop,
                  child: Text(l10n.productFormCreatorShop),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _creatorShopPicked = true;
                  _namedResort = true;
                  _creatorResortExpanded = true;
                });
              },
            )
          else
            Text(
              l10n.productFormCreatorShop,
              key: const Key('creator-shop-picked'),
              style: const TextStyle(
                color: PartnerTheme.text,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          if (_creatorShopPicked) ...[
            const SizedBox(height: 12),
            if (resortOpen)
              _creatorResortFields(l10n)
            else
              Material(
                key: const Key('creator-resort-summary'),
                color: PartnerTheme.card,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => setState(() => _creatorResortExpanded = true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Text(
                      '${_resortName.text.trim()} · ${_resortCountry.text.trim()} · ${_resortRegion.text.trim()}',
                      style: const TextStyle(
                        color: PartnerTheme.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _creatorResortFields(AppLocalizations l10n) {
    Widget field({
      required Key key,
      required GlobalKey scrollKey,
      required TextEditingController controller,
      required String label,
      required String hint,
    }) {
      return KeyedSubtree(
        key: scrollKey,
        child: _StableField(
          stamp: key,
          buildField: () => TextField(
            key: key,
            controller: controller,
            style: const TextStyle(color: PartnerTheme.text),
            cursorColor: PartnerTheme.accent,
            decoration: _partnerField(label, hint: hint),
            onChanged: (_) {
              final resort = _resortName.text;
              if (_name.text != resort) {
                _name.text = resort;
              }
            },
          ),
        ),
      );
    }

    return Column(
      key: const Key('creator-resort-fields'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field(
          key: const Key('product-curated-resort'),
          scrollKey: _resortNameKey,
          controller: _resortName,
          label: l10n.productFormCuratedResort,
          hint: l10n.productFormCuratedResortHint,
        ),
        const SizedBox(height: 12),
        field(
          key: const Key('product-curated-country'),
          scrollKey: _resortCountryKey,
          controller: _resortCountry,
          label: l10n.productFormCuratedCountry,
          hint: l10n.productFormCuratedCountryHint,
        ),
        const SizedBox(height: 12),
        field(
          key: const Key('product-curated-region'),
          scrollKey: _resortRegionKey,
          controller: _resortRegion,
          label: l10n.productFormCuratedLocation,
          hint: l10n.productFormCuratedLocationHint,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            key: const Key('creator-resort-done'),
            onPressed: _collapseCreatorResort,
            child: Text(l10n.productFormCreatorResortDone),
          ),
        ),
      ],
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

  Widget _creatorProgress(AppLocalizations l10n) {
    final title = switch (_creatorStep) {
      1 => l10n.creatorWizardStepIntro,
      2 => l10n.creatorWizardStepSchedule,
      3 => l10n.creatorWizardStepPrice,
      4 => l10n.creatorWizardStepExtras,
      5 => l10n.creatorWizardStepReview,
      _ => '',
    };
    return Column(
      key: const Key('creator-wizard-progress'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.creatorWizardProgress(_creatorStep),
          style: const TextStyle(
            color: PartnerTheme.text,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        if (title.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: PartnerTheme.text,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _creatorStep / 5,
          minHeight: 4,
          color: PartnerTheme.accent,
          backgroundColor: PartnerTheme.border,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _creatorStepNav(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: const Key('creator-wizard-prev'),
            onPressed: _creatorStep <= 1
                ? null
                : () => _creatorGo(_creatorStep - 1),
            style: OutlinedButton.styleFrom(
              foregroundColor: PartnerTheme.text,
              minimumSize: const Size.fromHeight(44),
            ),
            child: Text(l10n.creatorWizardBack),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            key: const Key('creator-wizard-next'),
            onPressed: _creatorStep >= 5
                ? null
                : () => _creatorAdvance(_creatorStep + 1),
            style: _readableFilledStyle(height: 44),
            child: Text(
              _creatorStep == 4 && _creatorOfferIds.isEmpty
                  ? l10n.creatorWizardSkip
                  : l10n.creatorWizardNext,
            ),
          ),
        ),
      ],
    );
  }

  Widget _creatorStepBody(AppLocalizations l10n, DiverStore store) {
    return switch (_creatorStep) {
      1 => _creatorStepIntro(l10n, store),
      2 => _creatorStepSchedule(l10n),
      3 => _creatorStepPrice(l10n),
      4 => _creatorStepExtras(l10n),
      5 => _creatorStepReview(l10n),
      _ => SizedBox(
          key: Key('creator-wizard-step-$_creatorStep'),
          height: 8,
        ),
    };
  }

  Widget _creatorStepIntro(AppLocalizations l10n, DiverStore store) {
    return Column(
      key: const Key('creator-wizard-step-1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _shopLine(l10n, store),
        const SizedBox(height: 12),
        TextField(
          key: const Key('creator-wizard-blurb'),
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
          compact: true,
        ),
      ],
    );
  }

  Widget _creatorStepSchedule(AppLocalizations l10n) {
    final chip = selectedPartnerCategoryChip(_category);
    return Column(
      key: const Key('creator-wizard-step-2'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        _ProductDetailComposer(
          controller: _detailBody,
          decoration: _partnerField(
            l10n.briefSectionDays,
            hint: l10n.detailComposerHint,
            lines: 10,
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

  Widget _creatorPriceField({
    required Key key,
    required FocusNode focusNode,
    required TextEditingController controller,
    required String label,
    required String? errorText,
    required VoidCallback onChanged,
  }) {
    return TextField(
      key: key,
      focusNode: focusNode,
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: kWorkbenchWonInputMaxLength,
      inputFormatters: _wonPriceInputFormatters,
      style: const TextStyle(color: PartnerTheme.text, fontSize: 15),
      cursorColor: PartnerTheme.accent,
      decoration: _partnerField(label, errorText: errorText).copyWith(
        counterText: '',
      ),
      onChanged: (_) => onChanged(),
    );
  }

  Widget _creatorStepPrice(AppLocalizations l10n) {
    return Column(
      key: const Key('creator-wizard-step-3'),
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
          child: _creatorPriceField(
            key: const Key('workbench-diver-price'),
            focusNode: _diverPriceFocus,
            controller: _rateConsumer[GuestRole.diver]!,
            label: l10n.partnerFormBasePrice,
            errorText: _diverPriceError,
            onChanged: () => setState(() => _diverPriceError = null),
          ),
        ),
        const SizedBox(height: 12),
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
          _creatorPriceField(
            key: const Key('creator-wizard-nondiver-price'),
            focusNode: _nondiverPriceFocus,
            controller: _rateConsumer[GuestRole.nondiver]!,
            label: l10n.workbenchGuestNondiver,
            errorText: _nondiverPriceError,
            onChanged: () => setState(() => _nondiverPriceError = null),
          ),
          const SizedBox(height: 8),
          _creatorPriceField(
            key: const Key('creator-wizard-child-price'),
            focusNode: _childPriceFocus,
            controller: _rateConsumer[GuestRole.child]!,
            label: l10n.workbenchGuestChild,
            errorText: _childPriceError,
            onChanged: () => setState(() => _childPriceError = null),
          ),
        ],
      ],
    );
  }

  Widget _creatorStepExtras(AppLocalizations l10n) {
    return Column(
      key: const Key('creator-wizard-step-4'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final id in _creatorOfferIds) ...[
          _creatorOfferCard(l10n, id),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          key: const Key('creator-offer-add'),
          onPressed: _addCreatorOffer,
          style: OutlinedButton.styleFrom(
            foregroundColor: PartnerTheme.text,
            minimumSize: const Size.fromHeight(44),
          ),
          icon: const Icon(Icons.add),
          label: Text(l10n.creatorWizardAddCard),
        ),
      ],
    );
  }

  _LineEditors? _creatorAddon(String id) {
    for (final line in _addons) {
      if (line.id == id) {
        return line;
      }
    }
    return null;
  }

  _IndividualTicket? _creatorTicket(String id) {
    for (final ticket in _individuals) {
      if (ticket.id == id) {
        return ticket;
      }
    }
    return null;
  }

  void _addCreatorOffer() {
    final line = _LineEditors(kind: ProductOptionKind.addon);
    _bindCreatorLine(line);
    setState(() {
      _addons.add(line);
      _addonQty[line.id] = 0;
      _creatorOfferIds.add(line.id);
    });
  }

  void _removeCreatorOffer(String id) {
    _LineEditors? line;
    _IndividualTicket? ticket;
    setState(() {
      _creatorOfferIds.remove(id);
      _creatorDetailsOpen.remove(id);
      final addonIndex = _addons.indexWhere((item) => item.id == id);
      if (addonIndex >= 0) {
        line = _addons.removeAt(addonIndex);
        _addonQty.remove(id);
        return;
      }
      final ticketIndex = _individuals.indexWhere((item) => item.id == id);
      if (ticketIndex >= 0) {
        ticket = _individuals.removeAt(ticketIndex);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final removed = line;
      if (removed != null) {
        _unbindCreatorLine(removed);
        removed.dispose();
      }
      final dropped = ticket;
      if (dropped != null) {
        _unbindCreatorTicket(dropped);
        _dropIndividual(dropped);
      }
    });
  }

  void _setCreatorOfferSeparate(String id, bool separate) {
    final currentSeparate = _creatorTicket(id) != null;
    if (currentSeparate == separate) {
      return;
    }
    _LineEditors? dropLine;
    _IndividualTicket? dropTicket;
    setState(() {
      if (separate) {
        final index = _addons.indexWhere((item) => item.id == id);
        if (index < 0) {
          return;
        }
        final line = _addons.removeAt(index);
        _addonQty.remove(id);
        final ticket = _IndividualTicket(
          id: line.id,
          name: line.name.text,
          lead: line.description.text,
          consumer: line.consumer.text,
          includes: line.includes.text,
          excludes: line.excludes.text,
          bookable: line.bookable,
          group: line.group,
        );
        _individuals.add(ticket);
        _bindCreatorTicket(ticket);
        dropLine = line;
        return;
      }
      final index = _individuals.indexWhere((item) => item.id == id);
      if (index < 0) {
        return;
      }
      final ticket = _individuals.removeAt(index);
      final line = _LineEditors(
        id: ticket.id,
        name: ticket.name.text,
        description: ticket.lead.text,
        includes: ticket.includes.text,
        excludes: ticket.excludes.text,
        consumer: ticket.consumer.text,
        bookable: ticket.bookable,
        group: ticket.group,
        kind: ProductOptionKind.addon,
      );
      _bindCreatorLine(line);
      _addons.add(line);
      _addonQty[line.id] = 0;
      final at = _creatorOfferIds.indexOf(ticket.id);
      var cursor = at < 0 ? _creatorOfferIds.length : at + 1;
      for (final nested in ticket.addons) {
        nested.kind = ProductOptionKind.addon;
        _addons.add(nested);
        _addonQty[nested.id] = 0;
        if (!_creatorOfferIds.contains(nested.id)) {
          _creatorOfferIds.insert(cursor, nested.id);
          cursor += 1;
        }
      }
      ticket.addons.clear();
      dropTicket = ticket;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final removed = dropLine;
      if (removed != null) {
        _unbindCreatorLine(removed);
        removed.dispose();
      }
      final dropped = dropTicket;
      if (dropped != null) {
        _unbindCreatorTicket(dropped);
        dropped.dispose();
      }
    });
  }

  void _addCreatorNested(String ticketId) {
    final ticket = _creatorTicket(ticketId);
    if (ticket == null) {
      return;
    }
    final line = _LineEditors(kind: ProductOptionKind.addon);
    _bindCreatorLine(line);
    setState(() {
      ticket.addons.add(line);
      ticket.addonQty[line.id] = 0;
    });
  }

  void _removeCreatorNested(String ticketId, String nestedId) {
    final ticket = _creatorTicket(ticketId);
    if (ticket == null) {
      return;
    }
    _LineEditors? line;
    setState(() {
      final index = ticket.addons.indexWhere((item) => item.id == nestedId);
      if (index < 0) {
        return;
      }
      line = ticket.addons.removeAt(index);
      ticket.addonQty.remove(nestedId);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final removed = line;
      if (removed != null) {
        _unbindCreatorLine(removed);
        removed.dispose();
      }
    });
  }

  Widget _creatorOfferText({
    required String stamp,
    required TextEditingController controller,
    required String label,
    int lines = 1,
  }) {
    return _StableField(
      key: ValueKey(stamp),
      stamp: stamp,
      buildField: () => TextField(
        controller: controller,
        minLines: lines,
        maxLines: lines,
        style: const TextStyle(color: PartnerTheme.text, fontSize: 15),
        cursorColor: PartnerTheme.accent,
        decoration: _partnerField(label, lines: lines),
      ),
    );
  }

  Widget _creatorOfferCard(AppLocalizations l10n, String id) {
    final ticket = _creatorTicket(id);
    final addon = ticket == null ? _creatorAddon(id) : null;
    if (ticket == null && addon == null) {
      return const SizedBox.shrink();
    }
    final separate = ticket != null;
    final name = separate ? ticket.name : addon!.name;
    final price = separate ? ticket.consumer : addon!.consumer;
    final priceError = separate ? ticket.priceError : addon!.priceError;
    final priceFocus = separate ? ticket.consumerFocus : addon!.consumerFocus;
    final priceKey = separate ? ticket.priceKey : addon!.priceKey;
    final open = _creatorDetailsOpen.contains(id);
    final mode = separate ? 'separate' : 'addon';
    return DecoratedBox(
      key: Key('creator-offer-card-$id'),
      decoration: BoxDecoration(
        color: PartnerTheme.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PartnerTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _creatorOfferText(
                    stamp: 'offer-name-$id-$mode',
                    controller: name,
                    label: l10n.creatorWizardOfferName,
                  ),
                ),
                IconButton(
                  key: Key('creator-offer-remove-$id'),
                  tooltip: l10n.creatorWizardRemove,
                  onPressed: () => _removeCreatorOffer(id),
                  icon: const Icon(Icons.close, color: PartnerTheme.textDim),
                ),
              ],
            ),
            const SizedBox(height: 8),
            KeyedSubtree(
              key: priceKey,
              child: _creatorPriceField(
                key: Key('creator-offer-price-$id'),
                focusNode: priceFocus,
                controller: price,
                label: l10n.partnerFormBasePrice,
                errorText: priceError,
                onChanged: () {
                  if (priceError != null) {
                    setState(() {
                      if (separate) {
                        ticket.priceError = null;
                      } else {
                        addon!.priceError = null;
                      }
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _creatorModeButton(
                    key: Key('creator-offer-addon-$id'),
                    label: l10n.creatorWizardAddToTrip,
                    selected: !separate,
                    onPressed: () => _setCreatorOfferSeparate(id, false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _creatorModeButton(
                    key: Key('creator-offer-individual-$id'),
                    label: l10n.creatorWizardBuySeparate,
                    selected: separate,
                    onPressed: () => _setCreatorOfferSeparate(id, true),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: Key('creator-offer-details-$id'),
                onPressed: () => setState(() {
                  if (open) {
                    _creatorDetailsOpen.remove(id);
                  } else {
                    _creatorDetailsOpen.add(id);
                  }
                }),
                child: Text(l10n.creatorWizardDetails),
              ),
            ),
            if (open) ...[
              _creatorOfferText(
                stamp: 'offer-lead-$id-$mode',
                controller: separate ? ticket.lead : addon!.description,
                label: l10n.creatorWizardDescription,
                lines: 3,
              ),
              const SizedBox(height: 8),
              _creatorOfferText(
                stamp: 'offer-includes-$id-$mode',
                controller: separate ? ticket.includes : addon!.includes,
                label: l10n.productFormIncludes,
                lines: 3,
              ),
              const SizedBox(height: 8),
              _creatorOfferText(
                stamp: 'offer-excludes-$id-$mode',
                controller: separate ? ticket.excludes : addon!.excludes,
                label: l10n.productFormExcludes,
                lines: 3,
              ),
              if (separate) ...[
                const SizedBox(height: 8),
                for (final nested in ticket.addons) ...[
                  _creatorNestedRow(l10n, ticket.id, nested),
                  const SizedBox(height: 8),
                ],
                OutlinedButton.icon(
                  key: Key('creator-offer-nested-add-$id'),
                  onPressed: () => _addCreatorNested(id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PartnerTheme.text,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.creatorWizardNestedAdd),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _creatorModeButton({
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return FilledButton(
      key: key,
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: selected ? PartnerTheme.accent : PartnerTheme.card,
        foregroundColor: selected ? PartnerTheme.bg : PartnerTheme.text,
        minimumSize: const Size.fromHeight(40),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }

  Widget _creatorNestedRow(
    AppLocalizations l10n,
    String ticketId,
    _LineEditors nested,
  ) {
    return Column(
      key: Key('creator-offer-nested-${nested.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _creatorOfferText(
                stamp: 'nested-name-${nested.id}',
                controller: nested.name,
                label: l10n.creatorWizardOfferName,
              ),
            ),
            IconButton(
              key: Key('creator-offer-nested-remove-${nested.id}'),
              tooltip: l10n.creatorWizardRemove,
              onPressed: () => _removeCreatorNested(ticketId, nested.id),
              icon: const Icon(Icons.close, color: PartnerTheme.textDim),
            ),
          ],
        ),
        KeyedSubtree(
          key: nested.priceKey,
          child: _creatorPriceField(
            key: Key('creator-offer-nested-price-${nested.id}'),
            focusNode: nested.consumerFocus,
            controller: nested.consumer,
            label: l10n.partnerFormBasePrice,
            errorText: nested.priceError,
            onChanged: () {
              if (nested.priceError != null) {
                setState(() => nested.priceError = null);
              }
            },
          ),
        ),
      ],
    );
  }

  List<({String id, String label, int step})> _creatorGaps(
    AppLocalizations l10n,
  ) {
    final gaps = <({String id, String label, int step})>[];
    if (_resortName.text.trim().isEmpty) {
      gaps.add((
        id: 'resort',
        label: l10n.productFormCuratedResort,
        step: 1,
      ));
    }
    if (_resortCountry.text.trim().isEmpty) {
      gaps.add((
        id: 'country',
        label: l10n.productFormCuratedCountry,
        step: 1,
      ));
    }
    if (_resortRegion.text.trim().isEmpty) {
      gaps.add((
        id: 'region',
        label: l10n.productFormCuratedLocation,
        step: 1,
      ));
    }
    if (_diverPriceValue <= 0) {
      gaps.add((id: 'diver', label: l10n.partnerFormBasePrice, step: 3));
    }
    if (_hasNondivers) {
      if (parsePositivePrice(_rateConsumer[GuestRole.nondiver]!.text) ==
          null) {
        gaps.add((
          id: 'nondiver',
          label: l10n.workbenchGuestNondiver,
          step: 3,
        ));
      }
      if (parsePositivePrice(_rateConsumer[GuestRole.child]!.text) == null) {
        gaps.add((id: 'child', label: l10n.workbenchGuestChild, step: 3));
      }
    }
    for (final id in _creatorOfferIds) {
      final addon = _creatorAddon(id);
      if (addon != null) {
        if (addon.name.text.trim().isNotEmpty &&
            parsePositivePrice(addon.consumer.text) == null) {
          gaps.add((
            id: 'offer-$id',
            label: addon.name.text.trim(),
            step: 4,
          ));
        }
        continue;
      }
      final ticket = _creatorTicket(id);
      if (ticket == null) {
        continue;
      }
      if (ticket.name.text.trim().isNotEmpty &&
          parsePositivePrice(ticket.consumer.text) == null) {
        gaps.add((
          id: 'offer-$id',
          label: ticket.name.text.trim(),
          step: 4,
        ));
      }
      for (final nested in ticket.addons) {
        if (nested.name.text.trim().isNotEmpty &&
            parsePositivePrice(nested.consumer.text) == null) {
          gaps.add((
            id: 'offer-${nested.id}',
            label: nested.name.text.trim(),
            step: 4,
          ));
        }
      }
    }
    return gaps;
  }

  Widget _creatorStepReview(AppLocalizations l10n) {
    final gaps = _creatorGaps(l10n);
    final name = _resortName.text.trim().isNotEmpty
        ? _resortName.text.trim()
        : _name.text.trim();
    final price = _diverPriceValue;
    final shopId = _shopId.trim().isEmpty ? 'creator-preview' : _shopId.trim();
    final product = ShopProduct(
      id: widget.existing?.id ?? 'creator-preview-product',
      shopId: shopId,
      name: name,
      consumerPrice: price,
      professionalPrice: price,
      blurb: _blurb.text.trim(),
      durationLabel: _durationLabelForSave,
      coverUrl: _galleryCoverUrl,
      continent: _continent,
      meetingPoint: _meeting.text.trim(),
      includes: _includes.text.trim(),
      excludes: _excludes.text.trim(),
      cancellationNote: _cancel.text.trim(),
      options: _assembledOptions(name: name, diverPrice: price),
      category: _categoryForSave,
    );
    final shop = DiveShop(
      id: shopId,
      name: name.isEmpty ? l10n.creatorWizardStepReview : name,
      location: _resortRegion.text.trim(),
      country: _resortCountry.text.trim(),
      continent: _continent,
      sites: const [],
      productName: name,
      stars: 0,
      rating: 0,
      reviewCount: 0,
      amenities: const [],
      consumerPrice: price,
      professionalPrice: price,
      blurb: _blurb.text.trim(),
      durationLabel: _durationLabelForSave,
      coverUrl: _galleryCoverUrl,
    );
    Uint8List? coverBytes;
    for (final item in _gallery) {
      final data = item.photo?.bytes;
      if (data != null && data.isNotEmpty) {
        coverBytes = data;
        break;
      }
    }
    return Column(
      key: const Key('creator-wizard-step-5'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: const Key('creator-wizard-preview'),
          child: ProductOfferPreview(
            shop: shop,
            product: product,
            quote: TourPriceQuote(amount: price, isProfessional: false),
            coverBytes: coverBytes,
          ),
        ),
        if (gaps.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.creatorWizardMissing,
            style: const TextStyle(
              color: PartnerTheme.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          for (final gap in gaps)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: Key('creator-wizard-gap-${gap.id}'),
                onPressed: () => _creatorGo(gap.step),
                child: Text(gap.label),
              ),
            ),
        ],
      ],
    );
  }

  Widget _partnerBasicsSection(AppLocalizations l10n) {
    final chip = selectedPartnerCategoryChip(_category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.creatorMode) ...[
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
              key: Key(
                widget.partnerMode
                    ? 'partner-product-name'
                    : 'admin-product-name',
              ),
              controller: _name,
              style: const TextStyle(color: PartnerTheme.text),
              cursorColor: PartnerTheme.accent,
              decoration: _partnerField(
                l10n.partnerDefaultProduct,
                hint: l10n.partnerFormNameHint,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 12),
        ],
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
        _ProductDetailComposer(
          controller: _detailBody,
          decoration: _partnerField(
            l10n.briefSectionDays,
            hint: l10n.detailComposerHint,
            lines: 10,
          ),
          onChanged: () => setState(() {}),
        ),
        if (widget.partnerMode) ...[
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
        const SizedBox(height: 12),
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
          compact: true,
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
      key: ValueKey('addon-row-${draft.id}'),
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
                  child: _StableField(
                    key: ValueKey('addon-name-slot-${draft.id}'),
                    stamp: 0,
                    buildField: () => TextField(
                      key: ValueKey('addon-name-${draft.id}'),
                      controller: draft.name,
                      cursorColor: PartnerTheme.accent,
                      style: const TextStyle(color: PartnerTheme.text),
                      decoration: _partnerField(l10n.productFormOptionName),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: KeyedSubtree(
                    key: draft.priceKey,
                    child: _StableField(
                      key: ValueKey('addon-price-slot-${draft.id}'),
                      stamp: draft.priceError,
                      buildField: () => TextField(
                        key: ValueKey('addon-price-${draft.id}'),
                        focusNode: draft.consumerFocus,
                        controller: draft.consumer,
                        keyboardType: TextInputType.number,
                        inputFormatters: _priceInputFormatters,
                        cursorColor: PartnerTheme.accent,
                        style: const TextStyle(color: PartnerTheme.text),
                        decoration: _partnerField(
                          l10n.productFormOptionConsumer,
                          errorText: draft.priceError,
                        ),
                        onChanged: (_) {
                          if (draft.priceError != null) {
                            setState(() => draft.priceError = null);
                          }
                        },
                      ),
                    ),
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
      key: ValueKey('individual-row-${ticket.id}'),
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
                  child: _StableField(
                    key: ValueKey('individual-name-slot-${ticket.id}'),
                    stamp: 0,
                    buildField: () => TextField(
                      key: ValueKey('individual-name-${ticket.id}'),
                      controller: ticket.name,
                      cursorColor: PartnerTheme.accent,
                      style: const TextStyle(color: PartnerTheme.text),
                      decoration: _partnerField(l10n.bookingEntryIndividualName),
                    ),
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
            KeyedSubtree(
              key: ticket.priceKey,
              child: _StableField(
                key: ValueKey('individual-price-slot-${ticket.id}'),
                stamp: ticket.priceError,
                buildField: () => TextField(
                  key: ValueKey('partner-form-individual-price-${ticket.id}'),
                  focusNode: ticket.consumerFocus,
                  controller: ticket.consumer,
                  keyboardType: TextInputType.number,
                  inputFormatters: _priceInputFormatters,
                  cursorColor: PartnerTheme.accent,
                  style: const TextStyle(color: PartnerTheme.text),
                  decoration: _partnerField(
                    l10n.partnerFormBasePrice,
                    errorText: ticket.priceError,
                  ),
                  onChanged: (_) {
                    if (ticket.priceError != null) {
                      setState(() => ticket.priceError = null);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            _StableField(
              key: ValueKey('individual-includes-slot-${ticket.id}'),
              stamp: 0,
              buildField: () => TextField(
                key: ValueKey('partner-form-individual-includes-${ticket.id}'),
                controller: ticket.includes,
                minLines: 2,
                maxLines: 3,
                cursorColor: PartnerTheme.accent,
                style: const TextStyle(color: PartnerTheme.text),
                decoration: _partnerField(
                  l10n.productFormIncludes,
                  lines: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _StableField(
              key: ValueKey('individual-excludes-slot-${ticket.id}'),
              stamp: 0,
              buildField: () => TextField(
                key: ValueKey('partner-form-individual-excludes-${ticket.id}'),
                controller: ticket.excludes,
                minLines: 2,
                maxLines: 3,
                cursorColor: PartnerTheme.accent,
                style: const TextStyle(color: PartnerTheme.text),
                decoration: _partnerField(
                  l10n.productFormExcludes,
                  lines: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (var j = 0; j < ticket.addons.length; j++) ...[
              _nestedAddonRow(l10n, ticket, j),
              const SizedBox(height: 6),
            ],
            TextButton(
              onPressed: () {
                final line = _LineEditors(kind: ProductOptionKind.addon);
                setState(() => ticket.addons.add(line));
              },
              child: Text(l10n.partnerFormIndividualOptions),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nestedAddonRow(
    AppLocalizations l10n,
    _IndividualTicket ticket,
    int index,
  ) {
    final draft = ticket.addons[index];
    return Column(
      key: ValueKey('nested-addon-row-${draft.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _StableField(
                key: ValueKey('nested-addon-name-slot-${draft.id}'),
                stamp: 0,
                buildField: () => TextField(
                  key: ValueKey('nested-addon-name-${draft.id}'),
                  controller: draft.name,
                  cursorColor: PartnerTheme.accent,
                  style: const TextStyle(color: PartnerTheme.text),
                  decoration: _partnerField(l10n.productFormOptionName),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: KeyedSubtree(
                key: draft.priceKey,
                child: _StableField(
                  key: ValueKey('nested-addon-price-slot-${draft.id}'),
                  stamp: draft.priceError,
                  buildField: () => TextField(
                    key: ValueKey('nested-addon-price-${draft.id}'),
                    focusNode: draft.consumerFocus,
                    controller: draft.consumer,
                    keyboardType: TextInputType.number,
                    inputFormatters: _priceInputFormatters,
                    cursorColor: PartnerTheme.accent,
                    style: const TextStyle(color: PartnerTheme.text),
                    decoration: _partnerField(
                      l10n.productFormOptionConsumer,
                      errorText: draft.priceError,
                    ),
                    onChanged: (_) {
                      if (draft.priceError != null) {
                        setState(() => draft.priceError = null);
                      }
                    },
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  draft.dispose();
                  ticket.addons.removeAt(index);
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
          id: draft.id,
          value: draft.group,
          partner: true,
          onChanged: (next) => setState(() => draft.group = next),
        ),
      ],
    );
  }

  List<Widget> _openSeatsTail(AppLocalizations l10n) {
    if (widget.creatorMode && _creatorStep != 5) {
      return const [];
    }
    final entry = _openSeatsEntry(l10n);
    if (entry == null) {
      return const [];
    }
    return [
      const SizedBox(height: 16),
      entry,
    ];
  }

  /// Creator wizard keeps [craftedTripCanOpenSeats]. The one-screen form
  /// shows the button for an admin on any approved product, or for a partner
  /// on an approved product of [DiverStats.ownedShopId].
  Widget? _openSeatsEntry(AppLocalizations l10n) {
    if (widget.creatorMode) {
      return _creatorOpenSeatsEntry(l10n);
    }
    return _staffOpenSeatsEntry(l10n);
  }

  Widget? _creatorOpenSeatsEntry(AppLocalizations l10n) {
    final store = DiverStoreScope.of(context);
    final uid = store.uid ?? '';
    final grade = store.stats.memberGrade;
    if (uid.isEmpty || grade.rank < MemberGrade.gold.rank) {
      return null;
    }
    final existing = widget.existing;
    if (existing != null && existing.submittedByUid != uid) {
      return null;
    }
    final gate = existing ??
        ShopProduct(
          id: 'new',
          shopId: 'new',
          name: '',
          consumerPrice: 0,
          professionalPrice: 0,
          submittedByUid: uid,
          publishStatus: ProductPublishStatus.pending,
        );
    if (craftedTripCanOpenSeats(
      grade: grade,
      viewerUid: uid,
      product: gate,
    )) {
      return _openSeatsButton(l10n, existing!);
    }
    return _openSeatsHint(l10n);
  }

  Widget? _staffOpenSeatsEntry(AppLocalizations l10n) {
    final store = DiverStoreScope.of(context);
    if ((store.uid ?? '').isEmpty) {
      return null;
    }
    final existing = widget.existing;
    final ownsShop = _partnerOwnsListedShop(store.stats.ownedShopId, existing);
    if (!store.stats.isAdmin && !ownsShop) {
      return null;
    }
    if (existing != null &&
        existing.publishStatus == ProductPublishStatus.approved) {
      return _openSeatsButton(l10n, existing);
    }
    return _openSeatsHint(l10n);
  }

  bool _partnerOwnsListedShop(String? ownedShopId, ShopProduct? existing) {
    final owned = ownedShopId?.trim() ?? '';
    if (owned.isEmpty) {
      return false;
    }
    if (existing == null) {
      return true;
    }
    return existing.shopId.trim() == owned;
  }

  Widget _openSeatsButton(AppLocalizations l10n, ShopProduct product) {
    return FilledButton(
      key: const Key('workbench-open-seats'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: AppTheme.ocean,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      onPressed: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => SameBoatSeatsScreen(product: product),
          ),
        );
      },
      child: Text(l10n.sameBoatSeatsTitle),
    );
  }

  Widget _openSeatsHint(AppLocalizations l10n) {
    return Text(
      l10n.workbenchOpenSeatsAfterApproval,
      key: const Key('workbench-open-seats-hint'),
      style: const TextStyle(
        color: PartnerTheme.text,
        fontWeight: FontWeight.w700,
        height: 1.35,
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
            if (widget.creatorMode) ...[
              _creatorStepNav(l10n),
              const SizedBox(height: 8),
            ],
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
                style: _readableFilledStyle(),
                child: Text(l10n.briefEdit),
              )
            else if (!widget.creatorMode || _creatorStep == 5)
              FilledButton(
                key: canPublish
                    ? const Key('admin-product-submit')
                    : const Key('partner-product-save'),
                onPressed: busy ? null : () => _save(submitIntent),
                style: _readableFilledStyle(),
                child: Text(
                  busy &&
                          _savingIntent != null &&
                          _savingIntent != ProductSaveIntent.keepEditing
                      ? l10n.exploreSaving
                      : (canPublish
                          ? l10n.briefSave
                          : (widget.partnerMode
                              ? partnerSaveLabel
                              : l10n.briefSubmit)),
                ),
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

}

/// Darker than [PartnerTheme.accent] so the same teal reads on the white bar.
const _kDetailToolbarTeal = Color(0xFF0F766E);

final _detailInkIconStyle = IconButton.styleFrom(
  foregroundColor: AppTheme.navy,
  disabledForegroundColor: AppTheme.navy.withValues(alpha: 0.38),
  minimumSize: const Size(36, 36),
  padding: EdgeInsets.zero,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  visualDensity: VisualDensity.compact,
);

final _detailTealButtonStyle = TextButton.styleFrom(
  foregroundColor: _kDetailToolbarTeal,
  disabledForegroundColor: _kDetailToolbarTeal.withValues(alpha: 0.45),
  minimumSize: const Size(0, 36),
  padding: const EdgeInsets.symmetric(horizontal: 8),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  visualDensity: VisualDensity.compact,
  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
);

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
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: SizedBox(
              height: 36,
              child: SingleChildScrollView(
                key: const Key('product-detail-toolbar'),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('product-detail-bold'),
                      tooltip: l10n.detailComposerBold,
                      onPressed: _preview
                          ? null
                          : () => _wrapSelection('**', '**'),
                      style: _detailInkIconStyle,
                      icon: const Icon(Icons.format_bold, size: 18),
                    ),
                    IconButton(
                      key: const Key('product-detail-heading'),
                      tooltip: l10n.detailComposerHeading,
                      onPressed: _preview ? null : () => _prefixLine('### '),
                      style: _detailInkIconStyle,
                      icon: const Icon(Icons.title, size: 18),
                    ),
                    IconButton(
                      key: const Key('product-detail-list'),
                      tooltip: l10n.detailComposerList,
                      onPressed: _preview ? null : () => _prefixLine('- '),
                      style: _detailInkIconStyle,
                      icon: const Icon(Icons.format_list_bulleted, size: 18),
                    ),
                    PopupMenuButton<String>(
                      key: const Key('product-detail-table'),
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
                              size: 18,
                              color: _preview
                                  ? AppTheme.navy.withValues(alpha: 0.38)
                                  : AppTheme.navy,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.detailComposerTable,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _preview
                                    ? AppTheme.navy.withValues(alpha: 0.38)
                                    : AppTheme.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      key: const Key('product-detail-day'),
                      style: _detailTealButtonStyle,
                      onPressed: _preview
                          ? null
                          : () {
                              final day = _nextDayNumber();
                              final block =
                                  widget.controller.text.trim().isEmpty
                                  ? '### $day일차 — \n'
                                  : '\n### $day일차 — \n';
                              _insert(block, cursorOffset: block.length);
                            },
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(
                        l10n.detailComposerDay,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      key: const Key('product-detail-preview'),
                      style: _detailTealButtonStyle,
                      onPressed: () => setState(() => _preview = !_preview),
                      child: Text(
                        _preview
                            ? l10n.detailComposerEdit
                            : l10n.detailComposerPreview,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                softLineBreak: true,
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
            key: const Key('product-detail-editor'),
            controller: widget.controller,
            focusNode: _focus,
            cursorColor: PartnerTheme.accent,
            minLines: 10,
            maxLines: 24,
            onChanged: (_) => _notify(),
            decoration: widget.decoration.copyWith(alignLabelWithHint: true),
          ),
      ],
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

/// Keeps one [TextField] instance so a parent rebuild does not replace the
/// field the phone keyboard is editing.
class _StableField extends StatefulWidget {
  const _StableField({
    super.key,
    required this.stamp,
    required this.buildField,
  });

  final Object? stamp;
  final TextField Function() buildField;

  @override
  State<_StableField> createState() => _StableFieldState();
}

class _StableFieldState extends State<_StableField> {
  TextField? _field;
  Object? _stamp;

  @override
  Widget build(BuildContext context) {
    if (_field == null || _stamp != widget.stamp) {
      _stamp = widget.stamp;
      _field = widget.buildField();
    }
    return _field!;
  }
}
