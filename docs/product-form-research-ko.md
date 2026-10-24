# 다이브트래블 — 상품 등록 양식 개편 사전 조사

- **작성:** 코드 읽기 전용 (수정 없음)
- **기준:** workbench 가격 UX 이후 (`65d15fe` 근처 main)
- **옆창 캔버스:** [product-form-research.canvas.tsx](C:/Users/user/.cursor/projects/c-Users-user-Documents-Dive-Travel/canvases/product-form-research.canvas.tsx)

## 한 줄 요약

- 등록 화면은 **한 페이지 + 시각적 5구역** (진짜 위저드 아님)
- 상품은 별도 컬렉션이 아니라 `shops/{id}` 문서의 `products[]` 배열
- **지도 SDK / 샵 좌표 없음** (주소 텍스트 + 외부 Google Maps 링크만)
- **단독(개별) 상품 ≠ 추가 옵션** → 지금은 합치면 안 됨
- 파트너는 **계정당 샵 1개** (`users.owned_shop_id`)

---

## 1. 상품 등록/수정 화면

### 주요 파일

- `lib/features/admin/presentation/ops_product_workbench.dart`
- `lib/core/models/shop_product.dart`
- 저장: `shops/{shopId}` 문서의 `products` 배열 (merge)

### 화면 구조

| 구분 | 내용 |
|------|------|
| 한 화면? | 예. 스크롤 한 장 |
| 단계 나눔? | 시각적 5구역만 (페이지 전환 위저드 아님). 저장 실패 시 `_reveal`로 스크롤 |
| 구역 | ① 표지 ② 목적지 ③ 상세 ④ 예약(가격·옵션) ⑤ 같은배 빈자리 |

### 필수 입력 (저장 전 막음)

| 화면 항목 | 필수 | Firestore |
|-----------|------|----------|
| 상품명 (`_name`) | 예 | `products[].name` + `options` 중 `kind=base_package` 의 name |
| 다이버 소비자가 | 예 (>0) | `products[].consumer_price`, `guest_rates`, `base_package` 가격 |
| 직접입력 샵 리조트명 | 조건부 | `shops.name` (`saveShopProfile`) |
| 이름 있는 옵션 가격 | 조건부 | 해당 `options[].consumer_price` |
| 같은배 필드 | 조건부 | `SameBoatSeatOpenController.validate` |

### 선택/기타 입력

| 화면 항목 | Firestore 필드 |
|-----------|----------------|
| 카테고리 | `category` (`resort_package` / `liveaboard` / `fun_dive` / `course` / `day_trip`) |
| 사진 | `photo_urls`, `cover_url` (R2 URL) |
| 샵 선택 | 문서 id = shopId |
| 대륙 | `continent` |
| 한 줄 소개 (`_blurb`) | `blurb` (+ base_package `description`) |
| 주소·집결 (`_meeting`) | `meeting_point` (직접 샵이면 `shops.address`에도 복사) |
| 국가/지역(직접 샵) | `shops.country`, `shops.location` |
| 일정 본문 | `schedule` (옛 `itinerary_days`는 열 때 합치고 저장 시 `[]`) |
| 포함/불포함 | `includes`, `excludes` |
| 취소 안내 | `cancellation_note` |
| 비다이버·아동 가격 | `guest_rates[]` |
| 추가 옵션 (`_addons`) | `options[]` `kind=addon`, `parent_option_id` 비움 |
| 개별 상품 (`_individuals`) | `options[]` `kind=individual` |
| 개별의 하위 옵션 | `options[]` `kind=addon` + `parent_option_id` |
| 기간 라벨 | `duration_label` |
| 같은배 | `open_empty_seats`, `capacity`, `booked_seats`, `flag_holds`, `departure_start`, `flag_closes_at`, `same_boat_status` |
| 게시/선반 | `publish_status`, `listing_kind`, `submitted_*`, `reviewed_*`, `review_note` 등 |

**폼에 없는 레거시 (지우면 안 됨):** `min_guests` / `max_guests`, FOC 필드, `mergePersistedMap`이 보존하는 비폼 키.

### 「기본 패키지 / 추가 옵션 / 단독 상품」

| 말 | 코드 | 뜻 |
|----|------|-----|
| 기본 패키지 | `ProductOptionKind.basePackage` | 상품명·다이버가로 자동 생성. 체크아웃의 “패키지” |
| 추가 옵션 | `_addons` → `kind=addon`, parent 없음 | 패키지에 덧붙이는 구성 |
| 단독=개별 상품 | `_individuals` → `kind=individual` | 패키지 **대신** 고르는 별도 SKU (교육·원데이 등). 자기 가격·포함/불포함·자기 addons |

체크아웃 (`tour_checkout_sheet.dart`): **기본 패키지 또는 개별 중 하나** 선택 → 그에 맞는 addon만 표시.

**단독을 추가 옵션으로 합쳐도 되나?** → **지금은 안 됨.**  
이유: `kind` / `parent_option_id` / 체크아웃 선택 / 같은배 “개별 상품 빈자리”가 다름. 합치려면 마이그레이션 + 체크아웃·같은배 전면 수정 필요.

```
ShopProduct
  ├─ base_package
  ├─ addons (parent 없음)     ← 기본 패키지용
  ├─ individual A
  │    └─ addons (parent=A)
  └─ individual B
       └─ addons (parent=B)
```

---

## 2. 샵 정보 (`shops/{id}`)

파서: `ShopLiveStats.fromDocument` · 저장: `saveShopProfile`

| 필드 | 있음? | 비고 |
|------|-------|------|
| name, location, country, continent | 예 | |
| address | 예 | 문자열만 |
| intro | 예 | 리조트 소개 |
| amenities | 예 | 고객 화면 칩 (부대/관광 구분 없음) |
| cover_url, gallery_urls | 예 | |
| products[] | 예 | 상품 전부 여기 |
| dive_star_*, review avg, plaque, commission | 예 | |
| **lat / lng / GeoPoint** | **없음** | |
| **오시는 길(별도)** | **없음** | address / meeting만 |
| **부대시설 vs 주변관광 구분** | **없음** | amenities (+ catalog sites)만 |

**파트너 샵 수정 화면:** 있음  
→ `lib/features/explore/presentation/resort_desk_screen.dart`  
(이름·위치·주소·소개·amenities·대표상품명·가격·갤러리)  
관리자: `admin_shops_screen.dart` → 데스크 연결.

---

## 3. 지도

| 항목 | 현재 |
|------|------|
| 지도 패키지 | **없음** |
| 앱 안 지도 | 가짜 카드 (`_MapCard`) — 주소 텍스트만 |
| 동작 | 주소로 외부 Google Maps 검색 URL (`url_launcher`) |
| API 키 | 지도용 **불필요(현재)** |

### 지오코딩 후보

| 후보 | 비용(대략) | 설정 | GitHub Pages |
|------|------------|------|--------------|
| Google Geocoding / Places | SKU당 월 ~1만 무료 후 유료 (결제·키 필수) | 중~상 | 가능 (키 노출 주의, 프록시 권장) |
| OSM Nominatim 공용 | 무료, 앱 합산 1 req/s, User-Agent·캐시·대량 금지 | 하 | 가능하나 상용·자동완성 **비권장** |
| OpenCage | 시험 2,500/일(테스트). 상용 유료 | 하~중 | 가능 (키는 백엔드 권장) |

**의견:** 파트너가 가끔 주소 확정할 때만 지오코딩 1회 → 좌표를 shops에 캐시. 표시는 당분간 외부 링크.

---

## 4. 사용자 ↔ 샵

| 질문 | 답 |
|------|-----|
| 연결 | `users.is_business` + `owned_shop_id` **하나**. rules `ownsShop`이 이 값과 비교 |
| 여러 샵? | **구조상 1계정 1샵** |
| `operator_id` 추가 | merge만이면 표시는 비교적 안전. **영향 큼:** owned_shop_id 비교(store/데스크/파트너), rules, 예약 `shop_id`, 좌석 트랜잭션 |

참고: `partner_uid`는 제출자 추적용. “샵 주인” 게이트의 중심은 `owned_shop_id`.

---

## 5. 고객 화면

### 리조트 상세 — `resort_detail_screen.dart`

탭 **없음**. 한 스크롤:

1. 사진  
2. Dive Star·평점·날씨환불·같은배 칩  
3. 리조트 소개 (`intro`)  
4. 지도 카드 (주소 텍스트)  
5. 편의시설·특징 (`amenities` + catalog `sites`)  
6. 상품 박스 → `tour_checkout_sheet`  
7. 리뷰  

데이터: `listingsOnHull` + `liveStatsFor(hullId).products`

### 바우처 — `booking_voucher_screen.dart`

샵 문서 **재조회 없음**. `TourBooking` 스냅샷만: `shopName`, `productLabel`, 일정, 인원, 금액, `quoteLines`.  
주소·지도·amenities **없음**.

---

## 6. 위험 요소

| 위험 | 왜 |
|------|-----|
| `options[].kind` / `parent_option_id` | 체크아웃·견적·같은배 깨짐 |
| `products` 배열 통째 덮어쓰기 | `booked_seats` / `flag_holds` 유실 |
| Firestore 트랜잭션 | 예약·깃발·리뷰가 `products`를 같이 씀 |
| `publish_status` / `same_boat_status` | 공개·보드 노출 |
| `mergePersistedMap` | 빈 값으로 폼 키 삭제 |
| `firestore.rules` | 권한 모델 바꾸면 테스트 필수 |
| 결제·바우처 | 과거 예약은 스냅샷 — 상품 개편과 분리 유지 |

**기존 상품 깨질 가능성:** UI만 나누고 같은 필드명 → 낮음. individual→addon 통합·좌표 필수화·저장 구조 분리 → 높음.

**양식 개편과 섞지 말 것:** 결제/체크아웃 견적, 좌석 트랜잭션, 같은배 승인, `firestore.rules`.

---

## 7. 안전한 개편 순서 (3단계 이하)

### Build 1 — 양식 UX만 (스키마 유지)

- 워크벤치를 진짜 스텝/접기로 나누기, 카피·검증 UX  
- 필드명·options kind·좌석 키 그대로  
- 샵 새 필드는 아직 넣지 않거나 amenities/intro에만 선택 텍스트  

### Build 2 — 샵 프로필 확장 (상품과 분리)

- `ResortDeskScreen`에 오시는 길·부대/관광 텍스트  
- `shops`에 **새 키만 merge** (기존 키 삭제 금지)  
- 고객 상세에 섹션만 추가 → `products[]`·트랜잭션 손대지 않음  

### Build 3 — 지도/좌표 (마지막)

- `lat`/`lng`(또는 GeoPoint)를 샵에 옵션 필드로  
- 저장 시 지오코딩 1회 → 좌표 캐시  
- 표시는 외부 링크 유지 → 이후 임베드 지도  

**초기 금지:** 개별↔옵션 통합 · 멀티샵/`operator_id` 강제 · 좌석·결제를 양식과 한 커밋에 섞기.

---

## 참고 파일

| 파일 | 역할 |
|------|------|
| `ops_product_workbench.dart` | 상품 등록/수정 UI |
| `shop_product.dart` | 상품·옵션 모델 |
| `dive_star.dart` | ShopLiveStats (shops 파서) |
| `firestore_diver_repository.dart` | saveShopProfile / saveShopProduct / 트랜잭션 |
| `resort_desk_screen.dart` | 샵 프로필 편집 |
| `resort_detail_screen.dart` | 고객 상세 |
| `tour_checkout_sheet.dart` | 예약 옵션 선택 |
| `booking_voucher_screen.dart` | 바우처 |
| `firebase/firestore.rules` | ownsShop / shops 권한 |
| `pubspec.yaml` | 지도 패키지 없음 |

끝.
