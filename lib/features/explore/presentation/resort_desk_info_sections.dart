import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/shop_resort_info.dart';
import 'package:dive_travel_app/core/widgets/booking_gallery_editor.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
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
  final featureBlurb = TextEditingController();
  final localContact = TextEditingController();
  final checkIn = TextEditingController();
  final checkOut = TextEditingController();
  final businessHours = TextEditingController();
  final amenityCustom = TextEditingController();
  final featureTagCustom = TextEditingController();

  final amenities = <String>[];
  final featureTags = <String>[];
  final accessRoutes = <_AccessRouteDraft>[];
  final nearbySpots = <_NearbySpotDraft>[];

  void seed({
    required String mapUrl,
    required String nearestHub,
    required String featureBlurb,
    required String localContact,
    required String checkIn,
    required String checkOut,
    required String businessHours,
    required List<String> amenities,
    required List<String> featureTags,
    required List<AccessRoute> accessRoutes,
    required List<NearbySpot> nearbySpots,
  }) {
    this.mapUrl.text = mapUrl;
    this.nearestHub.text = nearestHub;
    this.featureBlurb.text = featureBlurb;
    this.localContact.text = localContact;
    this.checkIn.text = checkIn;
    this.checkOut.text = checkOut;
    this.businessHours.text = businessHours;
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

  void dispose() {
    mapUrl.dispose();
    nearestHub.dispose();
    featureBlurb.dispose();
    localContact.dispose();
    checkIn.dispose();
    checkOut.dispose();
    businessHours.dispose();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BookingFormSection(
          step: '7',
          title: '연락·운영',
          subtitle: '현지 연락처는 저장만 됩니다. 고객 상세에는 아직 보이지 않습니다.',
          child: Column(
            children: [
              TextField(
                controller: draft.localContact,
                maxLength: kMaxShortLine,
                decoration: _deskDeco(context, 
                  label: '현지 연락처 (저장만 · 상세 비공개)',
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
    required this.slots,
    required this.photos,
    required this.saving,
    required this.onTempSave,
    required this.onSave,
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
  final List<BookingGalleryItem> slots;
  final Widget photos;
  final bool saving;
  final VoidCallback? onTempSave;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cover = slots.isEmpty ? null : slots.first;
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
                cursorColor: PartnerTheme.accent,
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
                cursorColor: PartnerTheme.accent,
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
                      cursorColor: PartnerTheme.accent,
                      decoration: _field(l10n.exploreResortAddress),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    key: const Key('partner-resort-map-search'),
                    onPressed: onMapSearch,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PartnerTheme.accent,
                      side: const BorderSide(color: PartnerTheme.borderStrong),
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
                  color: PartnerTheme.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _CoverPreview(item: cover, keyed: true),
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
            cursorColor: PartnerTheme.accent,
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
                cursorColor: PartnerTheme.accent,
                maxLength: kMaxShortLine,
                maxLines: 2,
                decoration: _field('가장 가까운 도시·공항'),
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
                      cursorColor: PartnerTheme.accent,
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
                cursorColor: PartnerTheme.accent,
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
                      cursorColor: PartnerTheme.accent,
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
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('partner-resort-temp-save'),
                onPressed: saving ? null : onTempSave,
                style: OutlinedButton.styleFrom(
                  foregroundColor: PartnerTheme.text,
                  side: const BorderSide(color: PartnerTheme.borderStrong),
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
                  backgroundColor: PartnerTheme.accent,
                  foregroundColor: PartnerTheme.bg,
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
  });

  final ResortDeskInfoDraft draft;
  final int index;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final route = draft.accessRoutes[index];
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: PartnerTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('경로 ${index + 1}')),
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
            TextField(
              controller: route.from,
              decoration: _field('출발지'),
            ),
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
}

class _PartnerSpotCard extends StatelessWidget {
  const _PartnerSpotCard({
    required this.draft,
    required this.index,
    required this.onChanged,
  });

  final ResortDeskInfoDraft draft;
  final int index;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final spot = draft.nearbySpots[index];
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: PartnerTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('장소 ${index + 1}')),
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
            TextField(
              controller: spot.name,
              decoration: _field('장소 이름'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: spot.distance,
              decoration: _field('거리'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverPreview extends StatelessWidget {
  const _CoverPreview({required this.item, this.keyed = false});

  final BookingGalleryItem? item;
  final bool keyed;

  @override
  Widget build(BuildContext context) {
    final photo = item?.photo;
    final url = item?.url;
    Widget child = const Icon(Icons.image_outlined, color: PartnerTheme.textDim);
    if (photo != null && photo.bytes.isNotEmpty) {
      child = Image.memory(photo.bytes, fit: BoxFit.cover);
    } else if (url != null && url.startsWith('http')) {
      child = Image.network(url, fit: BoxFit.cover);
    }
    return ClipRRect(
      key: keyed ? const Key('partner-resort-cover-preview') : null,
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: PartnerTheme.bg,
        child: SizedBox(width: 96, height: 72, child: child),
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
  });

  final String name;
  final String country;
  final String region;
  final BookingGalleryItem? cover;

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
            style: const TextStyle(
              color: PartnerTheme.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            place,
            key: const Key('partner-resort-preview-place'),
            style: const TextStyle(color: PartnerTheme.textDim),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('partner-resort-preview-book'),
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: PartnerTheme.accent,
            foregroundColor: PartnerTheme.bg,
            minimumSize: const Size.fromHeight(44),
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
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Material(
      key: boxKey,
      color: PartnerTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: PartnerTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: PartnerTheme.text,
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

InputDecoration _field(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: PartnerTheme.bg,
    labelStyle: const TextStyle(color: PartnerTheme.textDim),
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
  );
}
