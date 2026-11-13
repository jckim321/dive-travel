import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/models/shop_resort_info.dart';
import 'package:dive_travel_app/core/widgets/booking_gallery_editor.dart';
import 'package:dive_travel_app/features/admin/presentation/planner_palette.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_country_field.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

const _kAmenityPresets = <String>[
  '풀장',
  '와이파이',
  '식당',
  '장비 렌탈',
  '나이트록스',
  '쇼어 다이빙',
  '스피드보트',
  '세탁',
];

const _kPartnerAmenityPresets = <String>[
  ..._kAmenityPresets,
  '주차',
  '에어컨',
  '공항 픽업',
  '장비 세척장',
  '짐 보관',
];

const _kAmenityEmoji = <String, String>{
  '풀장': '🏊',
  '와이파이': '📶',
  '식당': '🍽️',
  '장비 렌탈': '🤿',
  '나이트록스': '🫧',
  '쇼어 다이빙': '🏖️',
  '스피드보트': '🚤',
  '세탁': '🧺',
  '주차': '🅿️',
  '에어컨': '❄️',
  '공항 픽업': '🚐',
  '장비 세척장': '🚿',
  '짐 보관': '🧳',
};

const _kTransportLabels = <String, String>{
  'pickup': '리조트 픽업',
  'taxi': '택시',
  'bus': '버스',
  'rental_car': '렌터카',
  'boat': '보트',
};

/// Controllers + list drafts for shop resort-info fields on the desk.
class ResortDeskInfoDraft {
  ResortDeskInfoDraft();

  final mapUrl = TextEditingController();
  final nearestHub = TextEditingController();
  final nearestAirport = TextEditingController();
  final featureBlurb = TextEditingController();
  final localContact = TextEditingController();
  final checkIn = TextEditingController();
  final checkOut = TextEditingController();
  final businessHours = TextEditingController();
  final spokenLanguages = <String>[];
  final operatingMonths = <int>[];
  var regularClosedNone = false;
  final regularClosedDays = <int>[];
  final regularClosedNote = TextEditingController();
  final amenityCustom = TextEditingController();
  final featureTagCustom = TextEditingController();

  final amenities = <String>[];
  final featureTags = <String>[];
  final accessRoutes = <_AccessRouteDraft>[];
  final nearbySpots = <_NearbySpotDraft>[];

  void seed({
    required String mapUrl,
    required String nearestHub,
    required String nearestAirport,
    required String featureBlurb,
    required String localContact,
    required String checkIn,
    required String checkOut,
    required String businessHours,
    List<String> spokenLanguages = const [],
    List<int> operatingMonths = const [],
    bool regularClosedNone = false,
    List<int> regularClosedDays = const [],
    String regularClosedNote = '',
    required List<String> amenities,
    required List<String> featureTags,
    required List<AccessRoute> accessRoutes,
    required List<NearbySpot> nearbySpots,
  }) {
    this.mapUrl.text = mapUrl;
    this.nearestHub.text = nearestHub;
    this.nearestAirport.text = nearestAirport;
    this.featureBlurb.text = featureBlurb;
    this.localContact.text = localContact;
    this.checkIn.text = checkIn;
    this.checkOut.text = checkOut;
    this.businessHours.text = businessHours;
    this.spokenLanguages
      ..clear()
      ..addAll(shopLanguageCodesFrom(spokenLanguages));
    this.operatingMonths
      ..clear()
      ..addAll(shopMonthsFrom(operatingMonths));
    this.regularClosedNone = regularClosedNone;
    this.regularClosedDays
      ..clear()
      ..addAll(shopClosedDaysFrom(regularClosedDays));
    this.regularClosedNote.text = regularClosedNote;
    this.amenities
      ..clear()
      ..addAll(amenities.take(kMaxAmenities));
    this.featureTags
      ..clear()
      ..addAll(featureTags.take(kMaxFeatureTags));
    this.accessRoutes
      ..clear()
      ..addAll([
        for (final route in accessRoutes.take(kMaxAccessRoutes))
          _AccessRouteDraft.fromRoute(route),
      ]);
    this.nearbySpots
      ..clear()
      ..addAll([
        for (final spot in nearbySpots.take(kMaxNearbySpots))
          _NearbySpotDraft.fromSpot(spot),
      ]);
  }

  void toggleLanguage(String code) {
    if (!kShopLanguageCodes.contains(code)) {
      return;
    }
    if (spokenLanguages.contains(code)) {
      spokenLanguages.remove(code);
    } else {
      spokenLanguages.add(code);
    }
  }

  void toggleMonth(int month) {
    if (month < 1 || month > 12) {
      return;
    }
    if (operatingMonths.contains(month)) {
      operatingMonths.remove(month);
    } else {
      operatingMonths.add(month);
    }
    operatingMonths.sort();
  }

  void chooseClosedNone() {
    regularClosedNone = !regularClosedNone;
    if (regularClosedNone) {
      regularClosedDays.clear();
    }
  }

  void toggleClosedDay(int day) {
    if (day < 1 || day > 7) {
      return;
    }
    regularClosedNone = false;
    if (regularClosedDays.contains(day)) {
      regularClosedDays.remove(day);
    } else {
      regularClosedDays.add(day);
    }
    regularClosedDays.sort();
  }

  void dispose() {
    mapUrl.dispose();
    nearestHub.dispose();
    nearestAirport.dispose();
    featureBlurb.dispose();
    localContact.dispose();
    checkIn.dispose();
    checkOut.dispose();
    businessHours.dispose();
    regularClosedNote.dispose();
    amenityCustom.dispose();
    featureTagCustom.dispose();
    for (final route in accessRoutes) {
      route.dispose();
    }
    for (final spot in nearbySpots) {
      spot.dispose();
    }
  }

  List<AccessRoute> builtRoutes() => [
        for (final draft in accessRoutes)
          if (!draft.toRoute().isEmpty) draft.toRoute(),
      ].take(kMaxAccessRoutes).toList();

  List<NearbySpot> builtSpots() => [
        for (final draft in nearbySpots)
          if (!draft.toSpot().isEmpty) draft.toSpot(),
      ].take(kMaxNearbySpots).toList();
}

class _AccessRouteDraft {
  _AccessRouteDraft()
      : from = TextEditingController(),
        duration = TextEditingController(),
        cost = TextEditingController(),
        tips = TextEditingController(),
        transport = <String>{};

  factory _AccessRouteDraft.fromRoute(AccessRoute route) {
    final draft = _AccessRouteDraft();
    draft.from.text = route.from;
    draft.duration.text = route.duration;
    draft.cost.text = route.cost;
    draft.tips.text = route.tips;
    draft.transport.addAll(route.transport);
    return draft;
  }

  final TextEditingController from;
  final TextEditingController duration;
  final TextEditingController cost;
  final TextEditingController tips;
  final Set<String> transport;

  AccessRoute toRoute() => AccessRoute(
        from: clampShort(from.text),
        transport: [
          for (final code in kAccessTransportCodes)
            if (transport.contains(code)) code,
        ],
        duration: clampShort(duration.text),
        cost: clampShort(cost.text),
        tips: clampTips(tips.text),
      );

  void dispose() {
    from.dispose();
    duration.dispose();
    cost.dispose();
    tips.dispose();
  }
}

class _NearbySpotDraft {
  _NearbySpotDraft()
      : name = TextEditingController(),
        distance = TextEditingController(),
        blurb = TextEditingController();

  factory _NearbySpotDraft.fromSpot(NearbySpot spot) {
    final draft = _NearbySpotDraft();
    draft.name.text = spot.name;
    draft.distance.text = spot.distance;
    draft.blurb.text = spot.blurb;
    return draft;
  }

  final TextEditingController name;
  final TextEditingController distance;
  final TextEditingController blurb;

  NearbySpot toSpot() => NearbySpot(
        name: clampShort(name.text),
        distance: clampShort(distance.text),
        blurb: clampShort(blurb.text),
      );

  void dispose() {
    name.dispose();
    distance.dispose();
    blurb.dispose();
  }
}

InputDecoration _deskDeco(
  BuildContext context, {
  required String label,
  String? hint,
}) {
  final scheme = Theme.of(context).colorScheme;
  final dark = Theme.of(context).brightness == Brightness.dark;
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: dark ? scheme.outline : const Color(0xFFBDBDBD),
    ),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    filled: true,
    fillColor: dark ? scheme.surface : Colors.white,
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: scheme.primary, width: 1.6),
    ),
  );
}

String shopLanguageLabel(AppLocalizations l10n, String code) {
  return switch (code) {
    'ko' => l10n.exploreShopLanguageKo,
    'en' => l10n.exploreShopLanguageEn,
    'ja' => l10n.exploreShopLanguageJa,
    'zh' => l10n.exploreShopLanguageZh,
    'th' => l10n.exploreShopLanguageTh,
    'id' => l10n.exploreShopLanguageId,
    'es' => l10n.exploreShopLanguageEs,
    _ => code,
  };
}

String shopWeekdayShort(AppLocalizations l10n, int day) {
  return switch (day) {
    1 => l10n.exploreShopDayMon,
    2 => l10n.exploreShopDayTue,
    3 => l10n.exploreShopDayWed,
    4 => l10n.exploreShopDayThu,
    5 => l10n.exploreShopDayFri,
    6 => l10n.exploreShopDaySat,
    7 => l10n.exploreShopDaySun,
    _ => '',
  };
}

String shopWeekdayFull(AppLocalizations l10n, int day) {
  return switch (day) {
    1 => l10n.exploreShopWeekMon,
    2 => l10n.exploreShopWeekTue,
    3 => l10n.exploreShopWeekWed,
    4 => l10n.exploreShopWeekThu,
    5 => l10n.exploreShopWeekFri,
    6 => l10n.exploreShopWeekSat,
    7 => l10n.exploreShopWeekSun,
    _ => '',
  };
}

/// Guest line for a saved closed-day choice. Empty when nothing was chosen.
String shopClosedGuestLine(AppLocalizations l10n, ShopLiveStatsFacts facts) {
  if (facts.regularClosedNone) {
    return l10n.exploreShopClosedNone;
  }
  final names = [
    for (final day in facts.regularClosedDays) shopWeekdayFull(l10n, day),
  ].where((name) => name.isNotEmpty);
  final days = names.join(', ');
  final note = facts.regularClosedNote.trim();
  if (days.isEmpty) {
    return note;
  }
  final weekly = l10n.exploreShopClosedWeekly(days);
  if (note.isEmpty) {
    return weekly;
  }
  return '$weekly · $note';
}

class ShopLiveStatsFacts {
  const ShopLiveStatsFacts({
    required this.regularClosedNone,
    required this.regularClosedDays,
    required this.regularClosedNote,
  });

  final bool regularClosedNone;
  final List<int> regularClosedDays;
  final String regularClosedNote;
}

class ShopProfileFactsEditor extends StatelessWidget {
  const ShopProfileFactsEditor({
    super.key,
    required this.draft,
    required this.onChanged,
    this.partnerChrome = false,
  });

  final ResortDeskInfoDraft draft;
  final VoidCallback onChanged;
  final bool partnerChrome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = const Color(0xFF0A7C74);
    final idleBorder = const Color(0xFF8A98A8);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${l10n.exploreShopLanguages} (${l10n.exploreShopPickMany})',
          style: TextStyle(
            color: partnerChrome ? const Color(0xFF0B1F33) : null,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final code in kShopLanguageCodes)
              FilterChip(
                key: Key('shop-language-$code'),
                label: Text(shopLanguageLabel(l10n, code)),
                selected: draft.spokenLanguages.contains(code),
                showCheckmark: false,
                selectedColor: selected,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: draft.spokenLanguages.contains(code)
                      ? selected
                      : idleBorder,
                ),
                labelStyle: TextStyle(
                  color: draft.spokenLanguages.contains(code)
                      ? Colors.white
                      : const Color(0xFF0B1F33),
                  fontWeight: FontWeight.w700,
                ),
                shape: const StadiumBorder(),
                onSelected: (_) {
                  draft.toggleLanguage(code);
                  onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.exploreShopSeason,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var month = 1; month <= 12; month++)
              FilterChip(
                key: Key('shop-month-$month'),
                label: Text('$month'),
                selected: draft.operatingMonths.contains(month),
                showCheckmark: false,
                selectedColor: selected,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: draft.operatingMonths.contains(month)
                      ? selected
                      : idleBorder,
                ),
                labelStyle: TextStyle(
                  color: draft.operatingMonths.contains(month)
                      ? Colors.white
                      : const Color(0xFF0B1F33),
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onSelected: (_) {
                  draft.toggleMonth(month);
                  onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          l10n.exploreShopSeasonHint,
          style: const TextStyle(color: Color(0xFF52606D), fontSize: 12),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.exploreShopClosed,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              key: const Key('shop-closed-none'),
              label: Text(l10n.exploreShopClosedNone),
              selected: draft.regularClosedNone,
              showCheckmark: false,
              selectedColor: selected,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: draft.regularClosedNone ? selected : idleBorder,
              ),
              labelStyle: TextStyle(
                color: draft.regularClosedNone
                    ? Colors.white
                    : const Color(0xFF0B1F33),
                fontWeight: FontWeight.w700,
              ),
              shape: const StadiumBorder(),
              onSelected: (_) {
                draft.chooseClosedNone();
                onChanged();
              },
            ),
            for (var day = 1; day <= 7; day++)
              FilterChip(
                key: Key('shop-closed-day-$day'),
                label: Text(shopWeekdayShort(l10n, day)),
                selected: draft.regularClosedDays.contains(day),
                showCheckmark: false,
                selectedColor: selected,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: draft.regularClosedDays.contains(day)
                      ? selected
                      : idleBorder,
                ),
                labelStyle: TextStyle(
                  color: draft.regularClosedDays.contains(day)
                      ? Colors.white
                      : const Color(0xFF0B1F33),
                  fontWeight: FontWeight.w700,
                ),
                shape: const StadiumBorder(),
                onSelected: (_) {
                  draft.toggleClosedDay(day);
                  onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          key: const Key('shop-closed-note'),
          controller: draft.regularClosedNote,
          maxLength: kMaxShortLine,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: l10n.exploreShopClosedNote,
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF8A98A8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF8A98A8)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Expandable resort-info blocks for [ResortDeskScreen].
class ResortDeskInfoSections extends StatelessWidget {
  const ResortDeskInfoSections({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final ResortDeskInfoDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BookingFormSection(
          step: '7',
          title: '연락·운영',
          subtitle:
              '결제를 마친 손님의 바우처에만 보여요. 상품 상세에는 나오지 않아요.',
          child: Column(
            children: [
              TextField(
                controller: draft.localContact,
                maxLength: kMaxShortLine,
                decoration: _deskDeco(context, 
                  label: '현지 연락처',
                  hint: '전화·WhatsApp 등',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: draft.checkIn,
                maxLength: kMaxShortLine,
                decoration: _deskDeco(context, label: '체크인', hint: '예: 14:00'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: draft.checkOut,
                maxLength: kMaxShortLine,
                decoration: _deskDeco(context, label: '체크아웃', hint: '예: 11:00'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: draft.businessHours,
                maxLength: kMaxShortLine,
                maxLines: 2,
                decoration: _deskDeco(context, 
                  label: '영업시간',
                  hint: '예: 매일 08:00–18:00',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BookingFormSection(
          step: '8',
          title: l10n.exploreShopInfoTitle,
          subtitle: '비어 있는 항목은 손님 화면에서 줄째로 숨깁니다.',
          child: ShopProfileFactsEditor(draft: draft, onChanged: onChanged),
        ),
      ],
    );
  }
}

/// Partner resort-info block. Product fields stay outside this widget.
class PartnerResortInfoForm extends StatelessWidget {
  const PartnerResortInfoForm({
    super.key,
    required this.fieldStyle,
    required this.name,
    required this.onNameEdited,
    required this.countryField,
    required this.country,
    required this.location,
    required this.onRegionEdited,
    required this.address,
    required this.onMapSearch,
    required this.intro,
    required this.info,
    required this.onInfoChanged,
    required this.onCoverTap,
    required this.slots,
    required this.photos,
    required this.saving,
    required this.onTempSave,
    required this.onSave,
    this.showActions = true,
    this.partnerChrome = false,
  });

  final TextStyle fieldStyle;
  final TextEditingController name;
  final VoidCallback onNameEdited;
  final Widget countryField;
  final TextEditingController country;
  final TextEditingController location;
  final VoidCallback onRegionEdited;
  final TextEditingController address;
  final VoidCallback onMapSearch;
  final TextEditingController intro;
  final ResortDeskInfoDraft info;
  final VoidCallback onInfoChanged;
  final VoidCallback onCoverTap;
  final List<BookingGalleryItem> slots;
  final Widget photos;
  final bool saving;
  final VoidCallback? onTempSave;
  final VoidCallback? onSave;

  /// Partner shop info uses a fixed bottom save button instead of this row.
  final bool showActions;

  /// Light mockup cards. Admin keeps the previous chrome.
  final bool partnerChrome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cover = slots.isEmpty ? null : slots.first;
    if (partnerChrome) {
      return _mockupColumn(l10n, cover);
    }
    return Column(
      key: const Key('partner-resort-info'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _box(
          boxKey: const Key('partner-resort-section-basics'),
          title: '기본정보',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('resort-name-field'),
                controller: name,
                style: fieldStyle,
                cursorColor: PlannerPalette.accent,
                onChanged: (_) {
                  onNameEdited();
                  onInfoChanged();
                },
                decoration: _field(l10n.partnerShopName),
              ),
              const SizedBox(height: 12),
              countryField,
              const SizedBox(height: 12),
              TextField(
                key: const Key('resort-region-field'),
                controller: location,
                style: fieldStyle,
                cursorColor: PlannerPalette.accent,
                onChanged: (_) {
                  onRegionEdited();
                  onInfoChanged();
                },
                decoration: _field('지역'),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('resort-address-field'),
                      controller: address,
                      style: fieldStyle,
                      cursorColor: PlannerPalette.accent,
                      decoration: _field(l10n.exploreResortAddress),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    key: const Key('partner-resort-map-search'),
                    onPressed: onMapSearch,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PlannerPalette.accent,
                      side: const BorderSide(color: PlannerPalette.borderStrong),
                      minimumSize: const Size(96, 52),
                    ),
                    child: const Text('지도 검색'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '대표 이미지',
                style: const TextStyle(
                  color: PlannerPalette.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _CoverPreview(item: cover, keyed: true, onTap: onCoverTap),
            ],
          ),
        ),
        _box(
          boxKey: const Key('partner-resort-section-intro'),
          title: '소개',
          child: TextField(
            key: const Key('resort-intro-field'),
            controller: intro,
            style: fieldStyle,
            cursorColor: PlannerPalette.accent,
            maxLines: 5,
            maxLength: kMaxIntroBody,
            decoration: _field(l10n.exploreResortIntro),
          ),
        ),
        _box(
          boxKey: const Key('partner-resort-section-transport'),
          title: '교통편',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: info.nearestHub,
                style: fieldStyle,
                cursorColor: PlannerPalette.accent,
                maxLength: kMaxShortLine,
                maxLines: 2,
                decoration: _field('가장 가까운 도시·공항').copyWith(
                  helperText: '손님에게 보이는 설명 문구',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('resort-nearest-airport'),
                controller: info.nearestAirport,
                style: fieldStyle,
                cursorColor: PlannerPalette.accent,
                maxLength: 3,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[A-Za-z]')),
                ],
                decoration: _field('가까운 공항(3글자 코드)').copyWith(
                  helperText: '현지 공항 3글자 코드 (예: 발리 DPS) — 항공권 링크에 쓰여요',
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < info.accessRoutes.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PartnerRouteCard(
                    draft: info,
                    index: i,
                    onChanged: onInfoChanged,
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: info.accessRoutes.length >= kMaxAccessRoutes
                      ? null
                      : () {
                          info.accessRoutes.add(_AccessRouteDraft());
                          onInfoChanged();
                        },
                  icon: const Icon(Icons.add),
                  label: Text(
                    info.accessRoutes.length >= kMaxAccessRoutes
                        ? '교통편은 최대 $kMaxAccessRoutes개입니다'
                        : '경로 추가',
                  ),
                ),
              ),
            ],
          ),
        ),
        _box(
          boxKey: const Key('partner-resort-section-amenities'),
          title: '편의시설',
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final preset in _kPartnerAmenityPresets)
                FilterChip(
                  label: Text('${_kAmenityEmoji[preset] ?? ''} $preset'),
                  selected: info.amenities.contains(preset),
                  onSelected: (selected) {
                    if (selected) {
                      if (info.amenities.length >= kMaxAmenities) {
                        return;
                      }
                      if (!info.amenities.contains(preset)) {
                        info.amenities.add(preset);
                      }
                    } else {
                      info.amenities.remove(preset);
                    }
                    onInfoChanged();
                  },
                ),
            ],
          ),
        ),
        _box(
          boxKey: const Key('partner-resort-section-facilities'),
          title: '부대시설',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final item in info.amenities)
                    if (!_kPartnerAmenityPresets.contains(item))
                      InputChip(
                        label: Text(item),
                        onDeleted: () {
                          info.amenities.remove(item);
                          onInfoChanged();
                        },
                      ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('partner-resort-facility-add'),
                      controller: info.amenityCustom,
                      style: fieldStyle,
                      cursorColor: PlannerPalette.accent,
                      maxLength: kMaxShortLine,
                      decoration: _field('직접 추가'),
                      onSubmitted: (_) => _addCustomAmenity(),
                    ),
                  ),
                  IconButton(
                    onPressed: _addCustomAmenity,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
        _box(
          boxKey: const Key('partner-resort-section-nearby'),
          title: '주변 관광',
          child: Column(
            children: [
              for (var i = 0; i < info.nearbySpots.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PartnerSpotCard(
                    draft: info,
                    index: i,
                    onChanged: onInfoChanged,
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: info.nearbySpots.length >= kMaxNearbySpots
                      ? null
                      : () {
                          info.nearbySpots.add(_NearbySpotDraft());
                          onInfoChanged();
                        },
                  icon: const Icon(Icons.add),
                  label: Text(
                    info.nearbySpots.length >= kMaxNearbySpots
                        ? '주변 관광은 최대 $kMaxNearbySpots개입니다'
                        : '장소 추가',
                  ),
                ),
              ),
            ],
          ),
        ),
        _box(
          boxKey: const Key('partner-resort-section-dive'),
          title: '다이빙 환경과 조건',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('partner-resort-dive-blurb'),
                controller: info.featureBlurb,
                style: fieldStyle,
                cursorColor: PlannerPalette.accent,
                maxLength: kMaxShortLine * 2,
                maxLines: 3,
                decoration: _field('환경·조건'),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in info.featureTags)
                    InputChip(
                      label: Text(tag),
                      onDeleted: () {
                        info.featureTags.remove(tag);
                        onInfoChanged();
                      },
                    ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: info.featureTagCustom,
                      style: fieldStyle,
                      cursorColor: PlannerPalette.accent,
                      maxLength: kMaxShortLine,
                      decoration: _field('조건 태그'),
                      onSubmitted: (_) => _addDiveTag(),
                    ),
                  ),
                  IconButton(
                    onPressed: _addDiveTag,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
        _box(
          boxKey: const Key('partner-resort-section-photos'),
          title: '사진',
          child: photos,
        ),
        _box(
          boxKey: const Key('partner-resort-list-preview'),
          title: '목록 미리보기',
          child: _ListPreview(
            name: name.text.trim(),
            country: country.text.trim(),
            region: location.text.trim(),
            cover: cover,
          ),
        ),
        if (showActions)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('partner-resort-temp-save'),
                  onPressed: saving ? null : onTempSave,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PlannerPalette.text,
                    side: const BorderSide(color: PlannerPalette.borderStrong),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(saving ? l10n.exploreSaving : l10n.briefTempSave),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  key: const Key('partner-resort-save'),
                  onPressed: saving ? null : onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: PlannerPalette.accent,
                    foregroundColor: PlannerPalette.onAccent,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(saving ? l10n.exploreSaving : l10n.partnerSave),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _mockupColumn(AppLocalizations l10n, BookingGalleryItem? cover) {
    return Column(
      key: const Key('partner-resort-info'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _box(
          mockup: true,
          boxKey: const Key('partner-resort-section-photos'),
          title: '대표 사진',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              photos,
              const SizedBox(height: 8),
              _CoverPreview(item: cover, keyed: true, onTap: onCoverTap),
              _mockTip('리조트 전경, 객실, 보트, 식당 순으로 올리면 좋아요. 사진을 눌러 대표로 바꿀 수 있어요.'),
            ],
          ),
        ),
        _box(
          mockup: true,
          boxKey: const Key('partner-resort-section-basics'),
          title: '기본 정보',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _mockLabel(
                l10n.partnerShopName,
                TextField(
                  key: const Key('resort-name-field'),
                  controller: name,
                  style: fieldStyle,
                  cursorColor: const Color(0xFF0A6B64),
                  onChanged: (_) {
                    onNameEdited();
                    onInfoChanged();
                  },
                  decoration: _field(l10n.partnerShopName, mockup: true),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _mockLabel(
                      '국가',
                      TravelCountryPlainScope(child: countryField),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _mockLabel(
                      '지역',
                      TextField(
                        key: const Key('resort-region-field'),
                        controller: location,
                        style: fieldStyle,
                        cursorColor: const Color(0xFF0A6B64),
                        onChanged: (_) {
                          onRegionEdited();
                          onInfoChanged();
                        },
                        decoration: _field('지역', mockup: true),
                      ),
                    ),
                  ),
                ],
              ),
              _mockLabel(
                l10n.exploreResortAddress,
                TextField(
                  key: const Key('resort-address-field'),
                  controller: address,
                  style: fieldStyle,
                  cursorColor: const Color(0xFF0A6B64),
                  decoration: _field(l10n.exploreResortAddress, mockup: true),
                ),
              ),
              OutlinedButton(
                key: const Key('partner-resort-map-search'),
                onPressed: onMapSearch,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0A6B64),
                  side: const BorderSide(color: Color(0xFF8A98A8), width: 1.5),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '지도에서 위치 찍기',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        _box(
          mockup: true,
          boxKey: const Key('partner-resort-section-intro'),
          title: '소개',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('resort-intro-field'),
                controller: intro,
                style: fieldStyle,
                cursorColor: const Color(0xFF0A6B64),
                maxLines: 5,
                maxLength: kMaxIntroBody,
                decoration: _field(l10n.exploreResortIntro, mockup: true),
              ),
              _mockTip('상품이 아니라 샵을 소개해 주세요. 상품 소개는 상품 등록에서 따로 써요.'),
            ],
          ),
        ),
        _box(
          mockup: true,
          boxKey: const Key('partner-resort-section-amenities'),
          title: '시설 · 서비스',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in _kPartnerAmenityPresets)
                    FilterChip(
                      label: Text('${_kAmenityEmoji[preset] ?? ''} $preset'),
                      selected: info.amenities.contains(preset),
                      showCheckmark: false,
                      selectedColor: const Color(0xFF0A7C74),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: info.amenities.contains(preset)
                            ? const Color(0xFF0A7C74)
                            : const Color(0xFF8A98A8),
                      ),
                      labelStyle: TextStyle(
                        color: info.amenities.contains(preset)
                            ? Colors.white
                            : const Color(0xFF0B1F33),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      shape: const StadiumBorder(),
                      onSelected: (selected) {
                        if (selected) {
                          if (info.amenities.length >= kMaxAmenities) {
                            return;
                          }
                          if (!info.amenities.contains(preset)) {
                            info.amenities.add(preset);
                          }
                        } else {
                          info.amenities.remove(preset);
                        }
                        onInfoChanged();
                      },
                    ),
                ],
              ),
              KeyedSubtree(
                key: const Key('partner-resort-section-facilities'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final item in info.amenities)
                          if (!_kPartnerAmenityPresets.contains(item))
                            InputChip(
                              label: Text(item),
                              onDeleted: () {
                                info.amenities.remove(item);
                                onInfoChanged();
                              },
                            ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _mockLabel(
                            '직접 추가',
                            TextField(
                              key: const Key('partner-resort-facility-add'),
                              controller: info.amenityCustom,
                              style: fieldStyle,
                              cursorColor: const Color(0xFF0A6B64),
                              maxLength: kMaxShortLine,
                              decoration: _field('직접 추가', mockup: true),
                              onSubmitted: (_) => _addCustomAmenity(),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _addCustomAmenity,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _box(
          mockup: true,
          boxKey: const Key('partner-resort-section-shop-facts'),
          title: l10n.exploreShopInfoTitle,
          child: ShopProfileFactsEditor(
            draft: info,
            onChanged: onInfoChanged,
            partnerChrome: true,
          ),
        ),
        _box(
          mockup: true,
          boxKey: const Key('partner-resort-section-local-contact'),
          title: l10n.bookingVoucherLocalContact,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('partner-resort-local-contact'),
                controller: info.localContact,
                style: fieldStyle,
                cursorColor: const Color(0xFF0A6B64),
                maxLength: kMaxShortLine,
                decoration: _field(
                  l10n.exploreShopLocalContactHint,
                  mockup: true,
                ).copyWith(hintText: l10n.exploreShopLocalContactHint),
              ),
              _mockTip(l10n.exploreShopLocalContactNote),
            ],
          ),
        ),
        _box(
          mockup: true,
          boxKey: const Key('partner-resort-section-transport'),
          title: '오시는 길',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _mockLabel(
                '가장 가까운 도시·공항',
                TextField(
                  controller: info.nearestHub,
                  style: fieldStyle,
                  cursorColor: const Color(0xFF0A6B64),
                  maxLength: kMaxShortLine,
                  maxLines: 2,
                  decoration: _field('가장 가까운 도시·공항', mockup: true).copyWith(
                    helperText: '손님에게 보이는 설명 문구',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _mockLabel(
                '가까운 공항(3글자 코드)',
                TextField(
                  key: const Key('partner-resort-nearest-airport'),
                  controller: info.nearestAirport,
                  style: fieldStyle,
                  cursorColor: const Color(0xFF0A6B64),
                  maxLength: 3,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z]')),
                  ],
                  decoration: _field(
                    '가까운 공항(3글자 코드)',
                    mockup: true,
                  ).copyWith(
                    helperText:
                        '현지 공항 3글자 코드 (예: 발리 DPS) — 항공권 링크에 쓰여요',
                    helperMaxLines: 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < info.accessRoutes.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PartnerRouteCard(
                    draft: info,
                    index: i,
                    onChanged: onInfoChanged,
                    mockup: true,
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: info.accessRoutes.length >= kMaxAccessRoutes
                      ? null
                      : () {
                          info.accessRoutes.add(_AccessRouteDraft());
                          onInfoChanged();
                        },
                  icon: const Icon(Icons.add),
                  label: Text(
                    info.accessRoutes.length >= kMaxAccessRoutes
                        ? '교통편은 최대 $kMaxAccessRoutes개입니다'
                        : '경로 추가',
                  ),
                ),
              ),
            ],
          ),
        ),
        _box(
          mockup: true,
          boxKey: const Key('partner-resort-section-nearby'),
          title: '주변 관광',
          child: Column(
            children: [
              for (var i = 0; i < info.nearbySpots.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PartnerSpotCard(
                    draft: info,
                    index: i,
                    onChanged: onInfoChanged,
                    mockup: true,
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: info.nearbySpots.length >= kMaxNearbySpots
                      ? null
                      : () {
                          info.nearbySpots.add(_NearbySpotDraft());
                          onInfoChanged();
                        },
                  icon: const Icon(Icons.add),
                  label: Text(
                    info.nearbySpots.length >= kMaxNearbySpots
                        ? '주변 관광은 최대 $kMaxNearbySpots개입니다'
                        : '장소 추가',
                  ),
                ),
              ),
            ],
          ),
        ),
        _box(
          mockup: true,
          boxKey: const Key('partner-resort-section-dive'),
          title: '다이빙 환경과 조건',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _mockLabel(
                '환경·조건',
                TextField(
                  key: const Key('partner-resort-dive-blurb'),
                  controller: info.featureBlurb,
                  style: fieldStyle,
                  cursorColor: const Color(0xFF0A6B64),
                  maxLength: kMaxShortLine * 2,
                  maxLines: 3,
                  decoration: _field('환경·조건', mockup: true),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in info.featureTags)
                    InputChip(
                      label: Text(tag),
                      onDeleted: () {
                        info.featureTags.remove(tag);
                        onInfoChanged();
                      },
                    ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _mockLabel(
                      '조건 태그',
                      TextField(
                        controller: info.featureTagCustom,
                        style: fieldStyle,
                        cursorColor: const Color(0xFF0A6B64),
                        maxLength: kMaxShortLine,
                        decoration: _field('조건 태그', mockup: true),
                        onSubmitted: (_) => _addDiveTag(),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _addDiveTag,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
        _box(
          mockup: true,
          boxKey: const Key('partner-resort-list-preview'),
          title: '목록 미리보기',
          child: _ListPreview(
            name: name.text.trim(),
            country: country.text.trim(),
            region: location.text.trim(),
            cover: cover,
            mockup: true,
          ),
        ),
        if (showActions)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('partner-resort-temp-save'),
                  onPressed: saving ? null : onTempSave,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0B1F33),
                    side: const BorderSide(color: Color(0xFF8A98A8)),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(saving ? l10n.exploreSaving : l10n.briefTempSave),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  key: const Key('partner-resort-save'),
                  onPressed: saving ? null : onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0B2A3C),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(saving ? l10n.exploreSaving : l10n.partnerSave),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _addCustomAmenity() {
    final item = clampShort(info.amenityCustom.text);
    if (item.isEmpty || info.amenities.length >= kMaxAmenities) {
      return;
    }
    if (!info.amenities.contains(item)) {
      info.amenities.add(item);
    }
    info.amenityCustom.clear();
    onInfoChanged();
  }

  void _addDiveTag() {
    final tag = clampShort(info.featureTagCustom.text);
    if (tag.isEmpty || info.featureTags.length >= kMaxFeatureTags) {
      return;
    }
    if (!info.featureTags.contains(tag)) {
      info.featureTags.add(tag);
    }
    info.featureTagCustom.clear();
    onInfoChanged();
  }
}

class _PartnerRouteCard extends StatelessWidget {
  const _PartnerRouteCard({
    required this.draft,
    required this.index,
    required this.onChanged,
    this.mockup = false,
  });

  final ResortDeskInfoDraft draft;
  final int index;
  final VoidCallback onChanged;
  final bool mockup;

  @override
  Widget build(BuildContext context) {
    final route = draft.accessRoutes[index];
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: mockup ? const Color(0xFFDDE3EA) : PlannerPalette.border,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '경로 ${index + 1}',
                    style: mockup
                        ? const TextStyle(
                            color: Color(0xFF0B1F33),
                            fontWeight: FontWeight.w800,
                          )
                        : null,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    route.dispose();
                    draft.accessRoutes.removeAt(index);
                    onChanged();
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            _routeFrom(route),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                for (final code in kAccessTransportCodes)
                  FilterChip(
                    label: Text(_kTransportLabels[code] ?? code),
                    selected: route.transport.contains(code),
                    onSelected: (selected) {
                      if (selected) {
                        route.transport.add(code);
                      } else {
                        route.transport.remove(code);
                      }
                      onChanged();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeFrom(_AccessRouteDraft route) {
    final field = TextField(
      controller: route.from,
      style: TextStyle(
        color: mockup ? const Color(0xFF0B1F33) : null,
      ),
      cursorColor: mockup ? const Color(0xFF0A6B64) : null,
      decoration: _field('출발지', mockup: mockup),
    );
    if (!mockup) {
      return field;
    }
    return _mockLabel('출발지', field);
  }
}

class _PartnerSpotCard extends StatelessWidget {
  const _PartnerSpotCard({
    required this.draft,
    required this.index,
    required this.onChanged,
    this.mockup = false,
  });

  final ResortDeskInfoDraft draft;
  final int index;
  final VoidCallback onChanged;
  final bool mockup;

  @override
  Widget build(BuildContext context) {
    final spot = draft.nearbySpots[index];
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: mockup ? const Color(0xFFDDE3EA) : PlannerPalette.border,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '장소 ${index + 1}',
                    style: mockup
                        ? const TextStyle(
                            color: Color(0xFF0B1F33),
                            fontWeight: FontWeight.w800,
                          )
                        : null,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    spot.dispose();
                    draft.nearbySpots.removeAt(index);
                    onChanged();
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            _spotField(spot.name, '장소 이름'),
            if (!mockup) const SizedBox(height: 8),
            _spotField(spot.distance, '거리'),
          ],
        ),
      ),
    );
  }

  Widget _spotField(TextEditingController controller, String label) {
    final field = TextField(
      controller: controller,
      style: TextStyle(
        color: mockup ? const Color(0xFF0B1F33) : null,
      ),
      cursorColor: mockup ? const Color(0xFF0A6B64) : null,
      decoration: _field(label, mockup: mockup),
    );
    if (!mockup) {
      return field;
    }
    return _mockLabel(label, field);
  }
}

class _CoverPreview extends StatelessWidget {
  const _CoverPreview({required this.item, this.keyed = false, this.onTap});

  final BookingGalleryItem? item;
  final bool keyed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final photo = item?.photo;
    final url = item?.url;
    Widget child = const Icon(Icons.image_outlined, color: PlannerPalette.textDim);
    if (photo != null && photo.bytes.isNotEmpty) {
      child = Image.memory(photo.bytes, fit: BoxFit.cover);
    } else if (url != null && url.startsWith('http')) {
      child = Image.network(url, fit: BoxFit.cover);
    }
    return Material(
      color: PlannerPalette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: PlannerPalette.border),
      ),
      child: InkWell(
        key: keyed ? const Key('partner-resort-cover-preview') : null,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 96, height: 72, child: child),
        ),
      ),
    );
  }
}

class _ListPreview extends StatelessWidget {
  const _ListPreview({
    required this.name,
    required this.country,
    required this.region,
    required this.cover,
    this.mockup = false,
  });

  final String name;
  final String country;
  final String region;
  final BookingGalleryItem? cover;
  final bool mockup;

  @override
  Widget build(BuildContext context) {
    final place = partnerPreviewPlace(country, region);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: _CoverPreview(item: cover),
          title: Text(
            name.isEmpty ? '리조트 이름' : name,
            style: TextStyle(
              color: mockup ? const Color(0xFF0B1F33) : PlannerPalette.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            place,
            key: const Key('partner-resort-preview-place'),
            style: TextStyle(
              color: mockup ? const Color(0xFF52606D) : PlannerPalette.textDim,
            ),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('partner-resort-preview-book'),
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor:
                mockup ? const Color(0xFF0B2A3C) : PlannerPalette.accent,
            foregroundColor: mockup ? Colors.white : PlannerPalette.onAccent,
            minimumSize: const Size.fromHeight(44),
            shape: mockup
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  )
                : null,
          ),
          child: const Text('이 리조트 예약하러 가기'),
        ),
      ],
    );
  }
}

/// Country and region share one line. The same phrase is written once.
String partnerPreviewPlace(String country, String region) {
  final left = country.trim();
  final right = region.trim();
  if (left.isEmpty && right.isEmpty) {
    return '국가 · 지역';
  }
  if (left.isEmpty) {
    return right;
  }
  if (right.isEmpty) {
    return left;
  }
  if (left == right || right.contains(left) || left.contains(right)) {
    return left.length >= right.length ? left : right;
  }
  return '$left · $right';
}

Widget _box({
  required Key boxKey,
  required String title,
  required Widget child,
  bool mockup = false,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Material(
      key: boxKey,
      color: mockup ? Colors.white : PlannerPalette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mockup ? 16 : 14),
        side: BorderSide(
          color: mockup ? const Color(0xFFDDE3EA) : PlannerPalette.border,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(mockup ? 16 : 14, mockup ? 16 : 12, mockup ? 16 : 14, mockup ? 16 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                color: mockup ? const Color(0xFF0B1F33) : PlannerPalette.text,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    ),
  );
}

InputDecoration _field(String label, {bool mockup = false}) {
  final borderColor = mockup ? const Color(0xFF8A98A8) : PlannerPalette.border;
  final radius = BorderRadius.circular(10);
  return InputDecoration(
    labelText: mockup ? null : label,
    filled: true,
    fillColor: Colors.white,
    labelStyle: TextStyle(
      color: mockup ? const Color(0xFF52606D) : PlannerPalette.textDim,
      fontWeight: mockup ? FontWeight.w700 : FontWeight.w400,
    ),
    constraints: mockup ? const BoxConstraints(minHeight: 48) : null,
    contentPadding: EdgeInsets.symmetric(
      horizontal: mockup ? 12 : 14,
      vertical: 14,
    ),
    border: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(
        color: mockup ? const Color(0xFF0A6B64) : PlannerPalette.accent,
        width: 1.4,
      ),
    ),
  );
}

Widget _mockLabel(String label, Widget field) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0B1F33),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    ),
  );
}

Widget _mockTip(String text) {
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF52606D),
        fontSize: 12,
        height: 1.55,
      ),
    ),
  );
}
