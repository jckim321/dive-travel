import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/models/shop_resort_info.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/booking_gallery_editor.dart';

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

InputDecoration _deskDeco({required String label, String? hint}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    filled: true,
    fillColor: Colors.white,
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.navy, width: 1.6),
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
          step: '2',
          title: '위치·지도',
          subtitle: '주소와 지도 링크(선택). https 지도 링크만 저장됩니다.',
          child: Column(
            children: [
              TextField(
                controller: draft.mapUrl,
                maxLength: kMaxMapUrl,
                decoration: _deskDeco(
                  label: '구글·네이버·카카오 지도 링크',
                  hint: 'https://maps.google.com/...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: draft.nearestHub,
                maxLength: kMaxShortLine,
                maxLines: 2,
                decoration: _deskDeco(
                  label: '가장 가까운 도시·공항',
                  hint: '예: 세부 막탄 공항에서 차량 1시간',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BookingFormSection(
          step: '3',
          title: '오시는 길',
          subtitle: '출발지별로 최대 $kMaxAccessRoutes개까지 추가할 수 있습니다.',
          child: Column(
            children: [
              for (var i = 0; i < draft.accessRoutes.length; i++) ...[
                _accessCard(i),
                const SizedBox(height: 10),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: draft.accessRoutes.length >= kMaxAccessRoutes
                      ? null
                      : () {
                          draft.accessRoutes.add(_AccessRouteDraft());
                          onChanged();
                        },
                  icon: const Icon(Icons.add),
                  label: Text(
                    draft.accessRoutes.length >= kMaxAccessRoutes
                        ? '오시는 길은 최대 $kMaxAccessRoutes개입니다'
                        : '경로 추가',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BookingFormSection(
          step: '4',
          title: '리조트 특징',
          subtitle: '한두 문장과 태그(최대 $kMaxFeatureTags개).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: draft.featureBlurb,
                maxLength: kMaxShortLine * 2,
                maxLines: 3,
                decoration: _deskDeco(
                  label: '특징 소개',
                  hint: '소규모·하우스리프·한국어 안내 등',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in draft.featureTags)
                    InputChip(
                      label: Text(tag),
                      onDeleted: () {
                        draft.featureTags.remove(tag);
                        onChanged();
                      },
                    ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: draft.featureTagCustom,
                      maxLength: kMaxShortLine,
                      decoration: _deskDeco(label: '태그 추가'),
                      onSubmitted: (_) => _addFeatureTag(),
                    ),
                  ),
                  IconButton(
                    onPressed: _addFeatureTag,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BookingFormSection(
          step: '5',
          title: '부대시설',
          subtitle: '칩을 고르거나 직접 추가합니다.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final preset in _kAmenityPresets)
                    FilterChip(
                      label: Text(preset),
                      selected: draft.amenities.contains(preset),
                      onSelected: (selected) {
                        if (selected) {
                          if (draft.amenities.length >= kMaxAmenities) {
                            return;
                          }
                          if (!draft.amenities.contains(preset)) {
                            draft.amenities.add(preset);
                          }
                        } else {
                          draft.amenities.remove(preset);
                        }
                        onChanged();
                      },
                    ),
                  for (final item in draft.amenities)
                    if (!_kAmenityPresets.contains(item))
                      InputChip(
                        label: Text(item),
                        onDeleted: () {
                          draft.amenities.remove(item);
                          onChanged();
                        },
                      ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: draft.amenityCustom,
                      maxLength: kMaxShortLine,
                      decoration: _deskDeco(label: '직접 추가'),
                      onSubmitted: (_) => _addAmenity(),
                    ),
                  ),
                  IconButton(
                    onPressed: _addAmenity,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BookingFormSection(
          step: '6',
          title: '주변 관광',
          subtitle: '최대 $kMaxNearbySpots곳까지 안내할 수 있습니다.',
          child: Column(
            children: [
              for (var i = 0; i < draft.nearbySpots.length; i++) ...[
                _spotCard(i),
                const SizedBox(height: 10),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: draft.nearbySpots.length >= kMaxNearbySpots
                      ? null
                      : () {
                          draft.nearbySpots.add(_NearbySpotDraft());
                          onChanged();
                        },
                  icon: const Icon(Icons.add),
                  label: Text(
                    draft.nearbySpots.length >= kMaxNearbySpots
                        ? '주변 관광은 최대 $kMaxNearbySpots개입니다'
                        : '장소 추가',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BookingFormSection(
          step: '7',
          title: '연락·운영',
          subtitle: '현지 연락처는 저장만 됩니다. 고객 상세에는 아직 보이지 않습니다.',
          child: Column(
            children: [
              TextField(
                controller: draft.localContact,
                maxLength: kMaxShortLine,
                decoration: _deskDeco(
                  label: '현지 연락처 (저장만 · 상세 비공개)',
                  hint: '전화·WhatsApp 등',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: draft.checkIn,
                maxLength: kMaxShortLine,
                decoration: _deskDeco(label: '체크인', hint: '예: 14:00'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: draft.checkOut,
                maxLength: kMaxShortLine,
                decoration: _deskDeco(label: '체크아웃', hint: '예: 11:00'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: draft.businessHours,
                maxLength: kMaxShortLine,
                maxLines: 2,
                decoration: _deskDeco(
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

  void _addFeatureTag() {
    final tag = clampShort(draft.featureTagCustom.text);
    if (tag.isEmpty) {
      return;
    }
    if (draft.featureTags.length >= kMaxFeatureTags) {
      return;
    }
    if (!draft.featureTags.contains(tag)) {
      draft.featureTags.add(tag);
    }
    draft.featureTagCustom.clear();
    onChanged();
  }

  void _addAmenity() {
    final item = clampShort(draft.amenityCustom.text);
    if (item.isEmpty) {
      return;
    }
    if (draft.amenities.length >= kMaxAmenities) {
      return;
    }
    if (!draft.amenities.contains(item)) {
      draft.amenities.add(item);
    }
    draft.amenityCustom.clear();
    onChanged();
  }

  Widget _accessCard(int index) {
    final route = draft.accessRoutes[index];
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8EE)),
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
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
            TextField(
              controller: route.from,
              maxLength: kMaxShortLine,
              decoration: _deskDeco(label: '출발지', hint: '예: 공항에서'),
              inputFormatters: [
                LengthLimitingTextInputFormatter(kMaxShortLine),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
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
            const SizedBox(height: 8),
            TextField(
              controller: route.duration,
              maxLength: kMaxShortLine,
              decoration: _deskDeco(label: '걸리는 시간'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: route.cost,
              maxLength: kMaxShortLine,
              decoration: _deskDeco(label: '비용'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: route.tips,
              maxLength: kMaxTipsBody,
              maxLines: 3,
              decoration: _deskDeco(label: '자세한 안내와 팁'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _spotCard(int index) {
    final spot = draft.nearbySpots[index];
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8EE)),
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
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
            TextField(
              controller: spot.name,
              maxLength: kMaxShortLine,
              decoration: _deskDeco(label: '장소 이름'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: spot.distance,
              maxLength: kMaxShortLine,
              decoration: _deskDeco(label: '리조트에서 거리'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: spot.blurb,
              maxLength: kMaxShortLine,
              decoration: _deskDeco(label: '한 줄 설명'),
            ),
          ],
        ),
      ),
    );
  }
}
