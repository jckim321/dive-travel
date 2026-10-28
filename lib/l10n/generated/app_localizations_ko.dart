// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '다이브 트래블';

  @override
  String get homeWelcome => '너의 바다는 어디까지 넓어졌니?';

  @override
  String get homeSubtitle => '전 세계 바다를 내 손안에.';

  @override
  String get homeProWelcome => '안녕하세요, PRO 강사님!';

  @override
  String get homeMapTitle => '나의 글로벌 바다 개척 지도';

  @override
  String homeMapExplored(int count) {
    return '현재까지 총 $count개 지역 탐험 중';
  }

  @override
  String get homeMapTip => '한 지역에서 다이빙 횟수가 늘어날수록 지도 위의 네온 불빛이 황금빛으로 진화합니다.';

  @override
  String get homeDiveStarTitle => 'Dive Star 인증';

  @override
  String get homeDiveStarShelfHint => '협회가 직접 검증한 바다';

  @override
  String get homeFavoritesTitle => '내가 캡틴';

  @override
  String get homeDiverPlannedSubtitle => '크루와 함께 떠나는 우리들만의 여행';

  @override
  String get homeCaptainNeedsGold => '골드 등급부터 캡틴이 될 수 있어요';

  @override
  String get homeBecomeCaptain => '캡틴 되기';

  @override
  String get homePopularTitle => '지금 뜨는 스팟';

  @override
  String get homeHotSpotSubtitle => '요즘 다이버들이 몰려요';

  @override
  String get homeSeeAll => '더보기';

  @override
  String get homeFavoritesEmpty => '하트를 누르거나 로그를 남기면 단골 리조트가 여기에 모여요.';

  @override
  String get homeShelfEmpty => '아직 올라온 여행이 없어요. 곧 채워질 거예요.';

  @override
  String get homeCuratedTitle => '기획 스페셜';

  @override
  String get homeCuratedSubtitle => 'Dive Travel이 꾸민 여행';

  @override
  String get homeLastCallSubtitle => '빈 자리 채우고 함께 출발';

  @override
  String get homeChipAll => '전체';

  @override
  String get homeChipRecommended => '추천';

  @override
  String get homeChipFavorites => '즐겨찾기';

  @override
  String get homeChipLastMinute => '마감임박';

  @override
  String get homeMapEmptyPrompt => '첫 바다를 열어 보세요';

  @override
  String get homeApdiSpecial => 'APDI SPECIAL';

  @override
  String get homeCrewRecruiting => '크루 모집 중';

  @override
  String homeSameBoatCountdown(int days, int seats) {
    return 'D-$days · $seats자리 남음';
  }

  @override
  String homeSameBoatSeatsLeft(int seats) {
    return '$seats자리 남음';
  }

  @override
  String homeBoardingUntil(int days) {
    return '출발까지 D-$days';
  }

  @override
  String get homeNextDepartures => '같은 배 · 마감 임박';

  @override
  String get homeLastMinuteTitle => '마감 임박 출발';

  @override
  String get homeLastMinuteCrew => '다합 사흘 소셜 크루';

  @override
  String get homeLastMinuteSeat => '내일 마감 · 남은 자리 1명 · 싱글차지 없음';

  @override
  String get homeForYouTitle => '나를 위한 다음 바다';

  @override
  String get homeStyleFirstOcean => '첫 바다를 여는 다이버';

  @override
  String get homeStyleFirstOceanBody =>
      '아직 스탬프가 없습니다. 아시아부터 열면 로그와 여행이 바로 이어집니다.';

  @override
  String get homeStyleHomeContinent => '한 대륙을 깊게 파는 다이버';

  @override
  String get homeStyleHomeContinentBody =>
      '단골 바다가 생겼습니다. 다음엔 다른 대륙을 열어 지도를 넓혀 보세요.';

  @override
  String get homeStyleCollector => '대양을 모으는 탐험가';

  @override
  String get homeStyleCollectorBody =>
      '이미 여러 대륙을 밟았습니다. 빈 스탬프를 채우면 여권 페이지가 완성됩니다.';

  @override
  String get homeStyleDeepLocal => '한 포인트를 깊게 파는 다이버';

  @override
  String get homeStyleDeepLocalBody =>
      '같은 바다를 반복해 골든 지역이 됐습니다. 다음 대륙으로 시야를 넓혀 보세요.';

  @override
  String get homeStylePro => '프로 루트의 강사';

  @override
  String get homeStyleProBody => '우대 단가로 새 대륙을 열어 보세요. 수업과 탐험을 같이 쌓을 수 있습니다.';

  @override
  String get homeNextOceanTitle => '다음에 열 바다';

  @override
  String homeNextOceanBody(String continent) {
    return '$continent에 아직 로그가 없습니다. 이 상품부터 열어 보세요.';
  }

  @override
  String homeOpenShop(String name) {
    return '$name 상품 보기';
  }

  @override
  String get homeStampsLabel => '여권 스탬프';

  @override
  String homeStampsProgress(int stamped, int total) {
    return '$stamped/$total 나라';
  }

  @override
  String get homeBadgeLabel => '다음 뱃지';

  @override
  String homeBadgeLeft(int count) {
    return '메탈 카드까지 $count로그';
  }

  @override
  String get homeBadgeDone => '메탈 카드 신청 가능';

  @override
  String get homeChecklistLabel => '출국 체크';

  @override
  String homeChecklistSoon(int days, String shop) {
    return '$days일 전 · $shop';
  }

  @override
  String get homeChecklistIdle => '장비 리스트 열어보기';

  @override
  String get passportCoverNation => '오션 공화국';

  @override
  String get passportCoverType => '여권';

  @override
  String get passportOpenHint => '표지를 눌러 여권을 펼치세요.';

  @override
  String get passportCloseHint => '다시 누르면 표지가 닫힙니다.';

  @override
  String get passportVisaTitle => '입국 스탬프';

  @override
  String get passportEntryGranted => '입국';

  @override
  String get passportAwaiting => '미입국';

  @override
  String passportPageIndex(int current, int total) {
    return '$current / $total 페이지';
  }

  @override
  String get passportEmptyPage => '이 페이지는 아직 비어 있습니다. 로그가 쌓이면 스탬프가 생깁니다.';

  @override
  String get profilePassportHint => '표지를 누르면 여권이 펼쳐지고, 로그가 있는 나라에 스탬프가 찍힙니다.';

  @override
  String get navHome => '홈';

  @override
  String get navLogbook => '로그북';

  @override
  String get navExplore => '여행상품';

  @override
  String get navCommunity => '같은배';

  @override
  String get navProfile => '마이';

  @override
  String get logbookTitle => '디지털 로그북';

  @override
  String get logbookAdd => '로그 추가';

  @override
  String get logbookEmpty => '아직 기록한 로그가 없습니다.';

  @override
  String get logbookChecklist => '장비 체크리스트';

  @override
  String get logbookSiteLabel => '다이빙한 장소';

  @override
  String get logbookDateLabel => '다이빙 날짜와 시간';

  @override
  String get logbookMemoLabel => '한 줄 메모';

  @override
  String get logbookSelfRegisterHint => '강사 서명 없이 저장하면 여행 일지로 바로 자체 등록됩니다.';

  @override
  String get logbookSelfRegistered => '여행 일지 · 자체 등록';

  @override
  String get logbookBriefEmpty => '장소만 기록됨';

  @override
  String get logbookSlipTitle => '새 로그 슬립';

  @override
  String get logbookTankRackTitle => '메탈 카드까지, 탱크 10개';

  @override
  String get logbookTankRackHint => '탱크 하나당 10로그. 수심 경쟁이 아니라 기록이 차오릅니다.';

  @override
  String get logbookCenturyTitle => '100부터 1,000 · 다음 구간';

  @override
  String get logbookCenturyHint =>
      '다이버는 100에서 메탈 카드, 강사 코스는 색이 바뀌며 1,000까지 이어집니다.';

  @override
  String logbookCenturyLeft(int count, int target) {
    return '다음 $target까지 $count로그';
  }

  @override
  String get logbookCenturyMastered => '1,000로그 마스터';

  @override
  String get logbookJournalTitle => '여행 일지';

  @override
  String get logbookStatDives => '총 다이빙';

  @override
  String get logbookStatDiveUnit => '회';

  @override
  String get logbookStatTime => '누적 시간';

  @override
  String get logbookStatRegions => '탐험 지역';

  @override
  String get logbookStatRegionUnit => '곳';

  @override
  String get logbookMaxDepth => '최대 수심';

  @override
  String get logbookAvgDepth => '평균 수심';

  @override
  String get logbookMinutes => '잠수 시간';

  @override
  String get logbookMinUnit => '분';

  @override
  String get logbookSac => 'BMV';

  @override
  String get logbookSacHint =>
      'BMV는 평균수심·시간·사용잔압·탱크용량으로 계산합니다. 평균이 비면 최대수심을 씁니다. 수심은 기록이니 깊게 갈 필요는 없습니다.';

  @override
  String get logbookMix => '호흡 기체';

  @override
  String get logbookMixAir => '21% AIR';

  @override
  String get logbookMixNx32 => '32% NITROX';

  @override
  String get logbookMixNx36 => '36% NITROX';

  @override
  String get logbookPressure => '잔압';

  @override
  String get logbookStartBar => '시작 잔압 (bar)';

  @override
  String get logbookEndBar => '종료 잔압 (bar)';

  @override
  String get logbookTankLiters => '탱크 용량 (L)';

  @override
  String get logbookTemp => '수온';

  @override
  String get logbookAirLeft => '남은 공기';

  @override
  String get logbookSave => '저장';

  @override
  String get logbookEdit => '수정';

  @override
  String get logbookUpdated => '로그를 수정했습니다. 지도와 일지가 갱신됩니다.';

  @override
  String get logbookSaved => '로그를 저장했습니다. 지도와 산소통이 갱신됩니다.';

  @override
  String get logbookPhotoSection => '테스트용 수중 사진';

  @override
  String get logbookPhotoHint => '갤러리·컴퓨터에서 고르거나, 테스트 사진을 바로 넣을 수 있습니다.';

  @override
  String get logbookAttachPhoto => '기기에서 사진 고르기';

  @override
  String get logbookUseTestPhoto => '테스트 사진 사용';

  @override
  String logbookPhotoPicked(String fileName) {
    return '첨부됨: $fileName';
  }

  @override
  String get logbookPhotoRemove => '사진 제거';

  @override
  String get logbookPhotoMissingConfig =>
      'Cloudflare R2 Access Key 또는 Account ID가 없습니다. lib/core/config/r2_secrets.dart를 확인해 주세요.';

  @override
  String get logbookUploading => '업로드 중...';

  @override
  String get checklistTitle => '출국 전 장비 체크리스트';

  @override
  String get exploreTitle => '여행상품';

  @override
  String get exploreConsumerPrice => '소비자가';

  @override
  String get exploreProPrice => '강사 우대가';

  @override
  String get exploreSeeMore => '더보기 ›';

  @override
  String get exploreOtherRegion => '기타';

  @override
  String get exploreSearchHint => '리조트, 포인트, 국가 검색';

  @override
  String get exploreFilterAll => '전체';

  @override
  String get exploreContinentAsia => '아시아';

  @override
  String get exploreContinentAfrica => '아프리카';

  @override
  String get exploreContinentOceania => '오세아니아';

  @override
  String get exploreContinentAmericas => '아메리카';

  @override
  String get exploreContinentEurope => '유럽';

  @override
  String get exploreContinentPolar => '극지';

  @override
  String get exploreRegionPacific => '태평양·오세아니아';

  @override
  String get exploreRegionAfricaRed => '아프리카·홍해';

  @override
  String get exploreRegionNorthAmerica => '북·중미';

  @override
  String get exploreRegionSouthAmerica => '남미';

  @override
  String get exploreZoneMicronesia => '미크로네시아';

  @override
  String get exploreZoneMelanesia => '멜라네시아';

  @override
  String get exploreZonePolynesia => '폴리네시아';

  @override
  String get exploreZoneOther => '그 밖';

  @override
  String get exploreSeaIndian => '인도양';

  @override
  String get exploreSeaRed => '홍해';

  @override
  String get exploreSeaCaribbean => '카리브해';

  @override
  String get exploreSeaSouthPacific => '남태평양';

  @override
  String get exploreProBanner => '강사 자격 확인됨 · 모든 상품이 강사 우대가로 표시됩니다';

  @override
  String get exploreConsumerBanner => '일반 다이버 가격 · 자리를 요청하면 샵 확정 후 결제합니다';

  @override
  String get exploreBook => '예약하기';

  @override
  String get optionBookPackage => '이 상품 예약';

  @override
  String get optionBookAddon => '이 구성 더해 예약';

  @override
  String get optionBookIndividual => '이 구성만 예약';

  @override
  String get explorePay => '결제하기';

  @override
  String explorePayAmount(String price) {
    return '$price원 결제하기';
  }

  @override
  String get checkoutGuestName => '예약자 이름';

  @override
  String get checkoutGuestBirth => '생년월일';

  @override
  String get checkoutGuestContact => '연락처';

  @override
  String get simPayTitle => '예약 요청 확인';

  @override
  String get simPayNotice => '지금은 결제하지 않습니다. 샵 확정 후 결제가 이어집니다.';

  @override
  String get simPaySameBoatTitle => '결제 확인';

  @override
  String get simPaySameBoatNotice =>
      '테스트 결제입니다. 실제 결제는 아직 연결되지 않았습니다. 결제 완료 시 자리가 확정됩니다.';

  @override
  String get simPaySameBoatAction => '결제하기';

  @override
  String get simPayAction => '예약 요청';

  @override
  String get simPayProcessing => '예약 요청 처리 중';

  @override
  String get simPayDoneTitle => '예약 요청 완료';

  @override
  String get simPayDoneBody => '예약 요청이 저장됩니다. 결제 상태는 미결제로 표시됩니다.';

  @override
  String get simPayClose => '확인';

  @override
  String exploreDepartureLine(String window, int seats) {
    return '$window · 빈자리 $seats';
  }

  @override
  String exploreDepartureBody(int empty, int capacity) {
    return '이 출발에 빈자리 $empty / 정원 $capacity입니다. 깃발을 올리면 같은 배에 탑니다.';
  }

  @override
  String get exploreWeatherRefundTitle => '기상 취소 전액 환불';

  @override
  String get exploreWeatherRefundBody =>
      '샵이 날씨로 출항을 취소하면 결제한 금액 전액을 돌려드립니다. 이건 마케팅 문구가 아니라 상품 조건입니다.';

  @override
  String exploreHostedBy(String shop) {
    return '$shop가 운영합니다';
  }

  @override
  String get exploreListingSites => '이 바다의 다이브 포인트';

  @override
  String get exploreListingAmenities => '이 상품이 제공하는 것';

  @override
  String get exploreListingSafetyTitle => '안전이 먼저인 바다';

  @override
  String get exploreListingSafetyBody =>
      '수심은 자랑이 아닙니다. 가이드·보트·장비가 먼저이고, 깊이 경쟁은 하지 않습니다.';

  @override
  String get exploreRareFind => '흔치 않은 Dive Star 리조트';

  @override
  String get exploreRareFindBody =>
      '오퍼레이션 후기로 별이 붙은 곳입니다. 인기 포인트는 날짜를 먼저 잡아 두세요.';

  @override
  String get exploreWontChargeYet => '지금은 일정을 잡고, 결제는 샵 확정 후 진행됩니다.';

  @override
  String get exploreListingGuests => '인원';

  @override
  String get exploreListingGuestOne => '다이버 1명';

  @override
  String get explorePerTrip => ' / 회';

  @override
  String get exploreCheckoutTitle => '예약 결제';

  @override
  String exploreCheckoutBody(String shop, String product) {
    return '$shop · $product';
  }

  @override
  String get exploreBookingNotSaved =>
      '자리를 확보하지 못해 예약을 만들지 않았습니다. 빈자리를 다시 확인해 주세요.';

  @override
  String exploreCheckoutDone(String label, String price) {
    return '$label $price원 예약을 샵에 전달했습니다.';
  }

  @override
  String get sameBoatSeatConfirmed => '결제가 완료되어 자리가 확정되었습니다(테스트 결제).';

  @override
  String get exploreConsumerPayHint => '샵이 등록한 정상 소비자가입니다.';

  @override
  String get exploreNoResults => '검색과 일치하는 샵이 없습니다.';

  @override
  String get exploreCountryEmpty => '아직 등록된 상품이 없어요';

  @override
  String exploreDiveStar(int stars) {
    return 'Dive Star $stars';
  }

  @override
  String exploreRating(String rating, int count) {
    return '$rating · 후기 $count';
  }

  @override
  String explorePriceWon(String price) {
    return '$price원';
  }

  @override
  String exploreOriginalPrice(String price) {
    return '소비자가 $price원';
  }

  @override
  String get exploreStarPending => '리뷰 집계 전';

  @override
  String get exploreListingNew => '신규';

  @override
  String get exploreListingPendingReview => '리뷰평가전';

  @override
  String get exploreDiveStarCertified => '다이브스타 인증';

  @override
  String exploreCardDiveStar(String marks) {
    return 'Dive Star $marks';
  }

  @override
  String get exploreCardDiveStarRenew => 'Dive Star 갱신 필요';

  @override
  String get exploreCardPartner => '제휴 파트너';

  @override
  String get exploreDiveStarRenewalNeeded => '갱신 필요';

  @override
  String get exploreViewListing => '리조트 보기';

  @override
  String get exploreBuyNow => '상품 고르기';

  @override
  String exploreResortCardLine(String location, int count) {
    return '$location · 상품 $count개';
  }

  @override
  String get exploreMyBookings => '내 예약';

  @override
  String exploreDepartureBanner(int days, String shop) {
    return '출국 D-$days · $shop';
  }

  @override
  String get reviewTitle => '여행 후기';

  @override
  String get reviewIntro => '별점을 고르고 짧은 후기를 남겨 주세요.';

  @override
  String get reviewShopLabel => '리조트 / 다이브샵';

  @override
  String get reviewStarsLabel => '별점';

  @override
  String get reviewNoReviewsYet => '아직 후기 없음';

  @override
  String reviewCountLabel(String rating, int count) {
    return '★ $rating (후기 $count개)';
  }

  @override
  String get reviewSectionTitle => '다이버 후기';

  @override
  String reviewSectionSummary(String rating, int count) {
    return '★ $rating · 후기 $count개';
  }

  @override
  String get reviewSectionEmpty => '아직 후기가 없어요. 첫 후기를 남겨 보세요';

  @override
  String get reviewLoadMore => '더 보기';

  @override
  String get reviewAuthorFallback => '다이버';

  @override
  String get reviewSafety => '① 안전 및 장비 관리';

  @override
  String get reviewGuide => '② 가이드 전문성';

  @override
  String get reviewBoat => '③ 보트 및 편의시설';

  @override
  String get reviewComment => '후기 (선택)';

  @override
  String get reviewSubmit => '저장';

  @override
  String get reviewWrite => '리뷰 작성';

  @override
  String get reviewDone => '리뷰 완료';

  @override
  String get reviewSaved => '후기가 저장되었습니다.';

  @override
  String get reviewSavedProductIdMissing =>
      '이 예약에 상품 정보가 없어 상품 카드 별점은 올라가지 않았습니다.';

  @override
  String get reviewSavedProductNotFound =>
      '샵에서 해당 상품을 찾지 못해 상품 카드 별점은 올라가지 않았습니다.';

  @override
  String get reviewSaveFailed => '후기 저장에 실패했습니다.';

  @override
  String get reviewAlreadySubmitted => '이미 후기를 작성했어요';

  @override
  String get reviewBookingRequired => '다녀온 예약이 확인된 경우에만 후기를 남길 수 있어요';

  @override
  String get reviewInvalidStars => '별점은 1부터 5까지만 가능해요';

  @override
  String get reviewCommentTooLong => '후기는 2,000자까지 작성할 수 있어요';

  @override
  String get reviewDetailsExpand => '더 자세히 알려주기';

  @override
  String get reviewDetailLevel => '다이버 레벨';

  @override
  String get reviewDetailDives => '총 다이빙 횟수';

  @override
  String get reviewDetailVisibility => '시야';

  @override
  String get reviewDetailCurrent => '조류';

  @override
  String get reviewDetailWaterTemp => '수온 (°C)';

  @override
  String get reviewDetailCrowd => '가이드 대비 다이버 수';

  @override
  String get reviewDetailAudience => '추천 대상';

  @override
  String get reviewDetailRevisit => '재방문 의사';

  @override
  String get reviewDetailOptionalHint => '모두 선택 사항입니다';

  @override
  String get reviewDetailOpenWater => '오픈워터';

  @override
  String get reviewDetailAdvanced => '어드밴스드';

  @override
  String get reviewDetailRescuePlus => '레스큐 이상';

  @override
  String get reviewDetailInstructor => '강사';

  @override
  String get reviewDetailFreediver => '프리다이버';

  @override
  String get reviewDetailDivesUnder50 => '~50';

  @override
  String get reviewDetailDives50to200 => '50~200';

  @override
  String get reviewDetailDives200Plus => '200 이상';

  @override
  String get reviewDetailVisPoor => '나쁨';

  @override
  String get reviewDetailVisOk => '보통';

  @override
  String get reviewDetailVisGood => '좋음';

  @override
  String get reviewDetailVisExcellent => '아주 좋음';

  @override
  String get reviewDetailCurrentMild => '약함';

  @override
  String get reviewDetailCurrentOk => '보통';

  @override
  String get reviewDetailCurrentStrong => '강함';

  @override
  String get reviewDetailCrowdRelaxed => '여유로움';

  @override
  String get reviewDetailCrowdOk => '보통';

  @override
  String get reviewDetailCrowdBusy => '붐빔';

  @override
  String get reviewDetailAudienceBeginner => '초보';

  @override
  String get reviewDetailAudienceExperienced => '숙련';

  @override
  String get reviewDetailAudienceCouple => '커플';

  @override
  String get reviewDetailAudienceFamily => '가족';

  @override
  String get reviewDetailAudiencePhoto => '사진 다이버';

  @override
  String get reviewDetailAudienceFreediver => '프리다이버';

  @override
  String get reviewDetailAudienceTech => '테크니컬';

  @override
  String get reviewDetailRevisitYes => '예';

  @override
  String get reviewDetailRevisitNo => '아니오';

  @override
  String get reviewDetailRevisitUnsure => '모르겠음';

  @override
  String reviewDetailWaterTempChip(String temp) {
    return '$temp°C';
  }

  @override
  String get reviewInvalidDetails => '세부 항목 값이 올바르지 않아요';

  @override
  String get reviewInvalidWaterTemp => '수온은 -2°C부터 40°C까지 입력할 수 있어요';

  @override
  String homeDiveStarSubtitle(String rating, int count) {
    return '오퍼레이션 평균 $rating · 리뷰 $count건';
  }

  @override
  String get proTitle => '강사 프로 자격증 인증';

  @override
  String get proBody =>
      'PADI/SSI 등 강사 C-Card 사진을 올리면 관리자 검토를 기다립니다. 승인되면 예약 단가가 강사 우대가로 바뀝니다.';

  @override
  String get proAgency => '자격 발행 기관';

  @override
  String get proPickPhoto => 'C-Card 사진 첨부';

  @override
  String get proSubmit => '프로 인증 신청';

  @override
  String get proSubmitDone => '자격증을 올렸습니다. 인증 상태가 대기중(pending)입니다.';

  @override
  String get proSubmitFailed => '프로 인증 신청에 실패했습니다.';

  @override
  String get proStatusNone => '미신청';

  @override
  String get proStatusPending => '대기중 (pending)';

  @override
  String get proStatusRejected => '반려됨';

  @override
  String get communityTitle => '같은 밀물';

  @override
  String get communityHostMileage => '깃발을 올린 크루가 예약하면 방장에게 마일리지가 적립됩니다.';

  @override
  String get profileTitle => '마이페이지';

  @override
  String get profileDepartureDeskKicker => '출항 데스크';

  @override
  String get profileCraftedTripsTitle => '내가 캡틴';

  @override
  String get profileCraftedTripsHint => '리조트를 골라 일정을 짜면 관리자 승인 후 여행상품에 올라갑니다.';

  @override
  String get profileCraftNewTrip => '새 여행 짜기';

  @override
  String get profileCaptainTripTitle => '캡틴의 새 여행';

  @override
  String get profileCraftNeedsGold =>
      '골드 이상부터 여행을 짤 수 있습니다. 첫 여행을 결제하면 골드가 됩니다.';

  @override
  String get profileCraftStatusPending => '승인 대기';

  @override
  String get profileCraftStatusLive => '공개 중';

  @override
  String get profileCraftStatusRejected => '반려';

  @override
  String get profileDeskToolsTitle => '데스크 도구';

  @override
  String get profileDeskToolsHint => '관리자·파트너·강사 인증과 로그아웃은 여기에 모아 두었습니다.';

  @override
  String get productFormNotInList => '목록에 없는 리조트';

  @override
  String get productFormCreatorShopHint =>
      '대륙을 고른 뒤 리조트를 선택하세요. 목록에 없으면 직접 이름을 적을 수 있습니다.';

  @override
  String get profileMyOceanKicker => 'MY OCEAN';

  @override
  String get profileGradeSilver => '실버';

  @override
  String get profileGradeGold => '골드';

  @override
  String get profileGradeDiamond => '다이아몬드';

  @override
  String get profileGradePlatinum => '플래티넘';

  @override
  String get profileGradeInstructor => '강사';

  @override
  String get profileViewMyInfo => '나의 정보 보기';

  @override
  String get profileNextOceanTitle => '다음 바다';

  @override
  String get profileNoUpcomingTrip => '아직 정해진 다음 바다가 없어요';

  @override
  String get profileNoUpcomingTripHint => '마음에 담아둔 바다에서 다음 여정을 시작해 보세요.';

  @override
  String get profileSavedOceansTitle => '내가 기다리는 바다';

  @override
  String get profileSavedOceansEmpty => '아직 기다리는 바다가 없어요. 여행상품에서 하트를 눌러 담아보세요.';

  @override
  String get profileOceanRecordTitle => '나의 바다 기록';

  @override
  String get profileTotalDives => '누적 다이빙';

  @override
  String get profileExploredSeas => '탐험 지역';

  @override
  String profileNextMilestone(int count) {
    return '다음 마일스톤까지 $count로그';
  }

  @override
  String get profileActivityTitle => '내 활동';

  @override
  String get profileBookingHistory => '예약 내역';

  @override
  String get profileTripScheduleTitle => '나의 이번 여행 스케줄';

  @override
  String get profileTripScheduleEmpty => '확정된 여행이 아직 없습니다.';

  @override
  String get profileFlaggedSeatsTitle => '깃발꽂은 빈자리';

  @override
  String get profileFlaggedSeatsEmpty => '잠가 둔 빈자리가 없습니다.';

  @override
  String get profileFlagPayCta => '결제 바로가기';

  @override
  String get profileWishlistTitle => '내가 가고 싶은 곳들';

  @override
  String get profileReviewRecommendTitle => '리뷰가 추천하는 곳';

  @override
  String get myReviewsTitle => '내 후기';

  @override
  String get myReviewsMenu => '내가 쓴 후기 보기·수정';

  @override
  String get myReviewsMenuHint => '작성한 후기를 확인하고 수정하거나 삭제할 수 있습니다.';

  @override
  String get myReviewsEmpty => '아직 작성한 후기가 없습니다. 여행이 끝난 예약에서 후기를 남겨 보세요.';

  @override
  String get myReviewNoProduct => '상품 미연결';

  @override
  String get myReviewEditedBadge => '수정됨';

  @override
  String get myReviewEditTitle => '후기 수정';

  @override
  String get myReviewEditHint => '별점·글·상세만 바꿀 수 있습니다. 리조트·상품·예약은 고정입니다.';

  @override
  String get myReviewSaveEdit => '수정 저장';

  @override
  String get myReviewUpdated => '후기를 수정했습니다.';

  @override
  String get myReviewDeleteTitle => '후기를 삭제할까요?';

  @override
  String get myReviewDeleteBody =>
      '삭제하면 리조트·상품 별점에서 이 후기가 빠지고, 같은 예약에 후기를 다시 쓸 수 있습니다.';

  @override
  String get myReviewDeleteAction => '후기 삭제';

  @override
  String get myReviewDeleted => '후기를 삭제했습니다.';

  @override
  String get profileWriteReviewTitle => '내가 다녀온 여행 리뷰쓰기';

  @override
  String get profileCharmsTitle => '나의 바다 뱃지';

  @override
  String get profileDivingPassportTitle => '나의 다이빙 여권';

  @override
  String profileDivingPassportRegions(int count) {
    return '$count개 지역';
  }

  @override
  String profileDivingPassportDives(String count) {
    return '$count회';
  }

  @override
  String profileDivingPassportShowAll(int count) {
    return '모든 도장 보기 ($count개)';
  }

  @override
  String get profileDivingPassportShowLess => '도장 접기';

  @override
  String get bookingVoucherOpen => '여행 바우처';

  @override
  String get bookingVoucherTitle => '여행 바우처';

  @override
  String get bookingVoucherSave => '폰에 저장·보관';

  @override
  String get bookingVoucherSaved => '바우처를 저장할 수 있는 공유 화면을 열었습니다.';

  @override
  String get bookingVoucherId => '예약번호';

  @override
  String get bookingVoucherShop => '샵';

  @override
  String get profileBookingStatus => '나의 예약';

  @override
  String get profilePaidBookingsEmpty => '결제 완료된 예약이 없습니다.';

  @override
  String get profileRequestedBookingsEmpty => '요청 중인 예약이 없습니다.';

  @override
  String get profileBookingFilterAll => '전체';

  @override
  String get profileBookingFilterRequested => '예약 요청';

  @override
  String get profileBookingFilterHolding => '좌석 홀딩';

  @override
  String get profileBookingFilterPaid => '결제 완료';

  @override
  String get profileLiveFlagsTitle => '꽂아 둔 깃발';

  @override
  String get profileLiveFlagsEmpty => '꽂아 둔 깃발이 없습니다.';

  @override
  String get profileAfterTripTitle => '다녀온 뒤';

  @override
  String get profileAfterTripEmpty => '남길 리뷰가 없습니다.';

  @override
  String get profileNextTripSuggest => '다음에 가볼 바다';

  @override
  String profileBookingCount(int count) {
    return '$count건';
  }

  @override
  String profileCraftedCount(int count) {
    return '내가 만든 여행 $count개';
  }

  @override
  String get profileSettingsTitle => '설정';

  @override
  String get profileMembershipTitle => '멤버십';

  @override
  String get profileGradeFirstTide => '첫 바다를 결제하면 골드로 건너갑니다.';

  @override
  String profileGradeStepsLeft(String next, int count) {
    return '$next까지 $count번의 여행이 남았습니다.';
  }

  @override
  String get profileGradeDeepest => '이미 가장 깊은 등급, 플래티넘입니다.';

  @override
  String get profileGradeShownAsInstructor => '화면에는 강사로 보입니다. 저장된 등급은 그대로입니다.';

  @override
  String get profileCredentialsTitle => '자격증 및 등급';

  @override
  String get profileWorkModeTitle => '업무용 전환';

  @override
  String get devRolesTitle => '테스트 역할 전환';

  @override
  String get devRolesHint =>
      '소유자 계정 전용. Firestore is_admin은 유지하고, 화면만 일반·파트너·관리자로 바꿉니다.';

  @override
  String get devRolesDiver => '일반 회원';

  @override
  String get devRolesPartner => '파트너';

  @override
  String get devRolesAdmin => '관리자';

  @override
  String get devRolesShop => '파트너 샵';

  @override
  String get devRolesApply => '적용';

  @override
  String get devRolesApplied => '테스트 역할을 적용했습니다.';

  @override
  String get devRolesNeedShop => '파트너 역할을 쓰려면 샵을 고르세요.';

  @override
  String get devRolesTrialCaption => '시험용, 출시 전 제거';

  @override
  String profileUpcomingConfirmed(String date) {
    return '예약 확정 · $date';
  }

  @override
  String get profileProBadge => 'PRO 강사 인증됨';

  @override
  String get profileMasterChallenge => '100로그 마스터 챌린지';

  @override
  String profileLogsProgress(int current, int target) {
    return '$current / $target';
  }

  @override
  String get profileMetalCard => '실물 메탈 카드 신청하기';

  @override
  String get profileMetalCardHint => '100로그를 채우면 실물 메탈 인증 카드를 신청할 수 있습니다.';

  @override
  String get profileRadarTitle => '여권 스탬프';

  @override
  String profileRegions(int count) {
    return '탐험 지역 $count곳';
  }

  @override
  String get metalCardDialogTitle => '100로그 마스터 달성';

  @override
  String get metalCardDialogBody =>
      '실물 메탈 인증 카드 무료 배송 신청은 2단계에서 연결됩니다. 지금은 달성 축하 화면입니다.';

  @override
  String get metalCardDialogClose => '확인';

  @override
  String get authLogin => '로그인';

  @override
  String get authSignup => '회원가입';

  @override
  String get authFirstVisit => '처음이에요';

  @override
  String get authWelcomeBack => '다시 왔어요';

  @override
  String get authHeroTitle => '다이빙 여행,\n같이 가요';

  @override
  String get authHeroSignupHint => '아이디와 비밀번호만 있으면 시작할 수 있어요';

  @override
  String get authHeroLoginHint => '아이디와 비밀번호로 다시 들어와요';

  @override
  String get authSignupPanelTitle => '회원가입';

  @override
  String get authSignupPanelBody => '로그·같은배·예약을 바로 쓸 수 있어요';

  @override
  String get authLoginPanelTitle => '로그인';

  @override
  String get authLoginPanelBody => '저장해 둔 여정으로 다시 들어와요';

  @override
  String get authNameTag => '아이디';

  @override
  String get authIdRuleHint => '한글·영문·숫자·_ 가능';

  @override
  String get authIdRuleHintLong => '앱에서 보이는 이름 · 한글·영문·숫자 모두 가능';

  @override
  String get authIdFieldHint => '아이디를 입력하세요';

  @override
  String get authIdExampleHint => '예: 바다거북';

  @override
  String get authPasswordRuleHint => '6자 이상';

  @override
  String get authPasswordFieldHint => '비밀번호를 입력하세요';

  @override
  String get authKeepSignedIn => '이 기기에서는 계속 로그인해 두기';

  @override
  String get authKeepSignedInShort => '로그인 상태 유지';

  @override
  String get authWelcomeBanner => '다이브 트래블에 오신 것을 환영합니다';

  @override
  String get authBrowseFirst => '먼저 둘러보기';

  @override
  String get authFooterCheer => '다이브 트래블은 당신의 다음 바다를 응원합니다';

  @override
  String get authFooterContact => '문의 | help@divetravel.com';

  @override
  String get authSignupHeroBody => '30초면 끝나요. 필요한 것만 받을게요.';

  @override
  String get authSignupMoreAbout => '나를 더 소개하기 (선택)';

  @override
  String get authSignupMoreAboutHint => '이름·생년월일·연락처·국적 · 결제 때 자동으로 채워져요';

  @override
  String get authSignupLegalName => '이름';

  @override
  String get authSignupLegalNameHint => '결제·예약에 쓸 이름';

  @override
  String get authSignupBirthDate => '생년월일';

  @override
  String get authSignupPhone => '연락처';

  @override
  String get authSignupPhoneHint => '휴대폰 번호';

  @override
  String get authConsentAll => '모두 동의하기';

  @override
  String get authConsentTerms => '이용약관 동의 (필수)';

  @override
  String get authConsentPrivacy => '개인정보 수집·이용 동의 (필수)';

  @override
  String get authConsentMarketing => '이벤트·소식 알림 받기 (선택)';

  @override
  String get authTermsView => '보기';

  @override
  String get authTermsClose => '닫기';

  @override
  String get authSignupAndBrowse => '가입하고 여행 둘러보기';

  @override
  String get authHaveAccountPrompt => '이미 계정이 있나요?';

  @override
  String get authErrorTermsRequired => '필수 약관에 동의해 주세요.';

  @override
  String get authStart => '시작하기';

  @override
  String get authForgotPasswordNote => '비밀번호를 잊었다면 → 「운영팀에 알려 주세요」 (출시 전 임시)';

  @override
  String get authTrialNote => '출시 전 시험용 · 가입과 로그인을 한 화면에서, 입력은 두 칸';

  @override
  String get authErrorNameTagRequired => '아이디를 적어 주세요.';

  @override
  String get authErrorNameTagTooLong => '아이디가 너무 길어요. 조금 짧게 적어 주세요.';

  @override
  String get authNationality => '국적(선택)';

  @override
  String get authNationalityNone => '선택 안 함';

  @override
  String get profileNationality => '국적';

  @override
  String get profileNationalityEmpty => '미입력';

  @override
  String get profileNationalitySave => '저장';

  @override
  String get profileNationalityClear => '지우기';

  @override
  String get profileNationalityNeedConsent => '국적을 저장하려면 동의가 필요해요';

  @override
  String get authWelcome =>
      '아이디와 비밀번호로 가입하면 로그·같은배·예약을 바로 쓸 수 있습니다. 제휴 파트너는 관리자가 승격합니다.';

  @override
  String get authEmail => '이메일';

  @override
  String get authLoginId => '아이디';

  @override
  String get authLoginIdOrEmail => '아이디 또는 이메일';

  @override
  String get authLoginIdHint => '영문 소문자·숫자·_ 4~20자';

  @override
  String get authPassword => '비밀번호';

  @override
  String get authPasswordHint => '6자 이상';

  @override
  String get authDisplayName => '이름';

  @override
  String get authNoAccount => '계정이 없나요? 회원가입';

  @override
  String get authHaveAccount => '이미 계정이 있나요? 로그인';

  @override
  String get authErrorInvalidEmail => '이메일 형식이 올바르지 않습니다.';

  @override
  String get authErrorInvalidCredential => '아이디(또는 이메일)나 비밀번호를 확인해 주세요.';

  @override
  String get authResetPassword => '비밀번호 재설정 메일 보내기';

  @override
  String get authResetPasswordSent => '비밀번호 재설정 메일을 보냈습니다. Gmail 받은편지함을 확인하세요.';

  @override
  String get authPasswordResetHiddenHint =>
      '출시 전까지 비밀번호 찾기는 제공하지 않습니다. 필요하면 관리자에게 문의해 주세요.';

  @override
  String get authErrorEmailInUse => '이미 가입된 이메일입니다.';

  @override
  String get authErrorLoginIdInUse => '이 아이디는 이미 쓰이고 있어요. 다른 아이디를 골라 주세요.';

  @override
  String get authErrorLoginIdFormat => '아이디는 한글, 영문, 숫자, _만 쓸 수 있어요.';

  @override
  String get authErrorLoginIdReserved => '이 아이디는 쓸 수 없어요. 다른 아이디를 골라 주세요.';

  @override
  String get authErrorDisplayNameRequired => '이름을 입력해 주세요.';

  @override
  String get authErrorWeakPassword => '비밀번호는 6자 이상이어야 합니다.';

  @override
  String get authErrorNetwork => '네트워크 연결을 확인해 주세요.';

  @override
  String get authErrorGeneric => '로그인에 실패했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get authErrorOperationNotAllowed =>
      '이메일/비밀번호 로그인이 아직 꺼져 있습니다. Firebase Authentication에서 사용 설정해 주세요.';

  @override
  String get authErrorFirestore =>
      '계정은 만들어졌지만 Firestore에 프로필을 쓰지 못했습니다. 콘솔에서 Firestore Database를 만들고 규칙을 붙여 주세요.';

  @override
  String get profilePasswordTitle => '비밀번호 변경';

  @override
  String get profilePasswordCurrent => '현재 비밀번호';

  @override
  String get profilePasswordNew => '새 비밀번호';

  @override
  String get profilePasswordConfirm => '새 비밀번호 확인';

  @override
  String get profilePasswordSave => '비밀번호 변경';

  @override
  String get profilePasswordSaved => '비밀번호를 바꿨어요';

  @override
  String get profilePasswordWrong => '현재 비밀번호가 틀려요';

  @override
  String get profilePasswordTooShort => '새 비밀번호는 6자 이상이어야 해요';

  @override
  String get profilePasswordMismatch => '새 비밀번호가 서로 달라요';

  @override
  String get profilePasswordRelogin => '다시 로그인해 주세요';

  @override
  String get profileSignOut => '로그아웃';

  @override
  String get logbookSaveFailed => '로그 저장에 실패했습니다. 네트워크와 Firebase 규칙을 확인해 주세요.';

  @override
  String get firebaseSetupTitle => 'Firebase 연결이 필요합니다';

  @override
  String get firebaseSetupBody =>
      '1. Firebase 콘솔에서 DiveTravelApp 프로젝트를 만듭니다.\n2. Authentication > Email/Password를 켭니다.\n3. Firestore Database를 테스트 모드로 생성합니다.\n4. 터미널에서 dart pub global activate flutterfire_cli 후 flutterfire configure 를 실행합니다.\n5. 생성된 firebase_options.dart가 들어오면 앱을 다시 실행하세요.';

  @override
  String get adminMode => '관리자 모드';

  @override
  String get adminPinTitle => '관리자 PIN';

  @override
  String get adminPinHint => '4자리 PIN';

  @override
  String get adminPinConfirm => '입장';

  @override
  String get adminPinWrong => 'PIN이 올바르지 않습니다.';

  @override
  String get devicePinSetupTitle => '기기 핀 정하기';

  @override
  String get devicePinSetupBody => '이 기기에서만 쓰는 4자리 핀입니다. 서버에는 저장되지 않습니다.';

  @override
  String get devicePinUnlockTitle => '기기 핀 잠금 해제';

  @override
  String get devicePinUnlockBody => '계정은 로그인된 상태입니다. 핀 4자리로 잠금을 풀어 주세요.';

  @override
  String get devicePinHint => '4자리 숫자';

  @override
  String get devicePinConfirmHint => '한 번 더 입력';

  @override
  String get devicePinSave => '저장';

  @override
  String get devicePinMismatch => '두 번 입력한 핀이 서로 다릅니다.';

  @override
  String devicePinWrong(int remain) {
    return '핀이 올바르지 않습니다. $remain번 남았습니다.';
  }

  @override
  String get devicePinLockedOut => '핀을 5번 틀려 지웠습니다. 아이디와 비밀번호로 다시 로그인해 주세요.';

  @override
  String get devicePinSettingsTitle => '기기 핀';

  @override
  String get devicePinSettingsSet => '기기 핀 정하기';

  @override
  String get devicePinSettingsChange => '기기 핀 바꾸기';

  @override
  String get devicePinSettingsHint => '앱을 다시 열 때 이 기기의 핀으로 잠금을 풉니다.';

  @override
  String get adminAccessDenied => '관리자 권한이 없는 계정입니다.';

  @override
  String get adminDashboardTitle => '관리자 대시보드';

  @override
  String get adminDashboardSubtitle =>
      '전 세계 강사 인증, Dive Star 샵, 게시글을 한곳에서 통제합니다.';

  @override
  String get adminHqTitle => '다이브 트래블 HQ';

  @override
  String get adminHqSubtitle => '총괄 관리자 콘솔';

  @override
  String get adminHqClose => '닫기';

  @override
  String get adminTabOverview => '현황';

  @override
  String get adminTabMembers => '회원';

  @override
  String get adminTabDiveStar => '다이브스타';

  @override
  String get adminTabProducts => '상품관리';

  @override
  String get adminTabBookings => '예약관리';

  @override
  String get adminTabSettlement => '파트너 정산';

  @override
  String get adminTabSales => '판매현황';

  @override
  String get adminTabStats => '통계';

  @override
  String get adminTabReports => '경영보고서';

  @override
  String get adminNavMore => '더보기';

  @override
  String get adminNavToolsSection => '도구';

  @override
  String get adminFilterMore => '더 보기';

  @override
  String get adminMembersSubGeneral => '일반회원';

  @override
  String get adminMembersSubDivers => '다이버';

  @override
  String get adminMembersSubInstructors => '강사인증';

  @override
  String get adminMembersSubPartners => '제휴파트너';

  @override
  String get adminPartnersSearch => '파트너·샵 검색';

  @override
  String get adminProductsSearch => '상품 검색';

  @override
  String get adminProductSourceFilter => '출처';

  @override
  String get adminDiveStarSubApplications => '신청';

  @override
  String get adminDiveStarSubReview => '심사·등급';

  @override
  String get adminDiveStarSubForms => '양식';

  @override
  String get adminDiveStarReviewSearch => '샵 이름 검색';

  @override
  String get adminDiveStarReviewPending => '심사 대기';

  @override
  String get adminDiveStarReviewEmpty => '조건에 맞는 파트너가 없습니다.';

  @override
  String get adminBookingsSubList => '예약';

  @override
  String get adminBookingsSubPayment => '결제 모니터링';

  @override
  String get adminBookingsSubCustomers => '고객 조회';

  @override
  String get adminBookingsSubCancel => '취소·환불';

  @override
  String get adminSettlementSubPricing => '할인 · 정산 조건';

  @override
  String get adminSettlementSubHistory => '정산 내역';

  @override
  String get adminPostsCommunityShort => '커뮤니티 글';

  @override
  String get adminGradeMixInstructorNote =>
      '강사 인증이 된 회원은 강사로 보입니다. 저장된 등급은 그대로입니다.';

  @override
  String get adminMembersGradeAll => '전체';

  @override
  String get adminMembersNeedsAction => '조치 필요';

  @override
  String adminMembersNeedsActionHint(int count) {
    return '강사 승인 대기 $count건 — 강사인증 탭에서 처리하세요.';
  }

  @override
  String adminMembersPurchasesReviews(int purchases, int reviews) {
    return '구매 $purchases회 · 리뷰 $reviews건';
  }

  @override
  String get adminMembersGradeLocked => '수동 조정됨 · 자동 승급이 잠겨 있습니다.';

  @override
  String get adminMembersUnlockAuto => '자동 승급 허용';

  @override
  String get adminPulseTitle => '오늘의 맥박';

  @override
  String get adminPulseSalesMonth => '이번 달 매출';

  @override
  String get adminPulseConversion => '결제 전환율';

  @override
  String adminPulseFunnelHint(int paid, int requested) {
    return '결제 $paid · 요청 $requested';
  }

  @override
  String get adminPulseNewWeek => '이번 주 신규';

  @override
  String get adminVisitsTitle => '방문 빈도';

  @override
  String get adminVisitsDau => '오늘 방문 (DAU)';

  @override
  String get adminVisitsWau => '7일 방문 (WAU)';

  @override
  String get adminVisitsMau => '30일 방문 (MAU)';

  @override
  String get adminVisitsDormant => '휴면 (30일+)';

  @override
  String get adminNewMembersTitle => '신규 회원';

  @override
  String get adminNewMembersToday => '오늘 가입';

  @override
  String get adminNewMembersWeek => '7일 가입';

  @override
  String get adminNewMembersMonth => '30일 가입';

  @override
  String get adminNewMembersPaid => '신규→첫결제 (30일)';

  @override
  String get adminFunnelTitle => '예약 퍼널';

  @override
  String get adminFunnelRequested => '요청(미결제)';

  @override
  String get adminFunnelPaid => '결제·확정';

  @override
  String get adminFunnelCancelled => '취소·종료';

  @override
  String get adminFunnelUnreviewed => '리뷰 미작성 결제';

  @override
  String get adminNearUpgradeTitle => '승급 임박';

  @override
  String adminNearUpgradeHint(int purchases) {
    return '다음 등급까지 구매 $purchases회';
  }

  @override
  String get adminProductSignalTitle => '상품·제휴 신호';

  @override
  String get adminProductSignalPublic => '공개 상품';

  @override
  String get adminProductSignalPending => '승인 대기';

  @override
  String get adminProductSignalShops => '제휴 샵';

  @override
  String gradeCelebrationTitle(String grade) {
    return '$grade으로 승급했습니다!';
  }

  @override
  String gradeCelebrationBody(String grade) {
    return '바다를 함께 채워 주셔서 감사합니다. $grade 여정을 Dive Travel이 응원합니다.';
  }

  @override
  String get gradeCelebrationThanks => '고마워요';

  @override
  String get adminMembersBadgeInstructor => '강사';

  @override
  String get adminMembersBadgePartner => '제휴';

  @override
  String get adminMembersBadgeAdmin => '관리자';

  @override
  String adminMembersLoginId(String id) {
    return '아이디 · $id';
  }

  @override
  String adminMembersRoleStatus(String kind, String role, String shop) {
    return '역할 · $kind · user_role=$role · 샵=$shop';
  }

  @override
  String get adminMembersRoleAdmin => '앱 대표관리자';

  @override
  String get adminMembersRolePartner => '제휴파트너';

  @override
  String get adminMembersRoleDiver => '일반회원';

  @override
  String get adminMembersLeftoverPartnerHint =>
      '관리자인데 파트너 플래그가 남아 있습니다. 「파트너 해제」로 정리하세요.';

  @override
  String get adminMembersPromotePartner => '파트너로 승격';

  @override
  String get adminMembersDemotePartner => '파트너 해제';

  @override
  String adminMembersPromoteConfirm(String name) {
    return '$name 님을 제휴파트너로 승격합니다. 연결할 샵을 고르거나 새 샵을 만드세요.';
  }

  @override
  String adminMembersDemoteConfirm(String name, String shop) {
    return '$name 님의 파트너를 해제할까요? (샵 $shop 연결이 끊깁니다. 샵 자체는 남습니다.)';
  }

  @override
  String get adminMembersPromotePickShop => '기존 샵 연결';

  @override
  String get adminMembersPromoteNewShop => '새 샵 만들기';

  @override
  String get adminMembersNewShopName => '새 샵 이름';

  @override
  String get adminMembersNoUnownedShops => '주인이 없는 샵이 없습니다. 새 샵을 만드세요.';

  @override
  String get adminMembersAlreadyPartner => '이미 파트너인 회원입니다.';

  @override
  String get adminMembersShopOwned => '이미 주인이 있는 샵입니다.';

  @override
  String get adminMembersPromoteDone => '파트너로 승격했습니다.';

  @override
  String get adminMembersDemoteDone => '파트너를 해제했습니다.';

  @override
  String get adminMembersPromoteFailed => '승격에 실패했습니다.';

  @override
  String get adminMembersDemoteFailed => '파트너 해제에 실패했습니다.';

  @override
  String get adminPartnerTierAll => '전체';

  @override
  String get adminPartnerTierReviewPending => '리뷰전';

  @override
  String get adminPartnerTierStar1 => 'Dive Star 1';

  @override
  String get adminPartnerTierStar2 => 'Dive Star 2';

  @override
  String get adminPartnerTierStar3 => 'Dive Star 3';

  @override
  String get adminPartnerTierEmpty => '이 티어에 해당하는 제휴 파트너가 없습니다.';

  @override
  String get adminPartnerOpenInstructors => '강사인증으로';

  @override
  String get adminTabCertify => '인증';

  @override
  String get adminTabShops => '제휴파트너';

  @override
  String get adminTabContracts => '제휴 계약';

  @override
  String get adminTabOps => '운영';

  @override
  String get adminContractsSubOverview => '계약 현황';

  @override
  String get adminContractsSubVault => '서류함';

  @override
  String get adminContractsSubTerms => '계약 조건';

  @override
  String get adminContractsSubInbox => '제안 받은편지함';

  @override
  String get adminTermsMissing => '미입력';

  @override
  String get adminTermsCommission => '수수료율';

  @override
  String get adminTermsParty => '인원 할인';

  @override
  String get adminTermsSeason => '계절 가격할인';

  @override
  String get adminTermsFoc => '강사 FOC';

  @override
  String get adminTermsFocPay => '유료 인원';

  @override
  String get adminTermsFocFree => '무료 인원';

  @override
  String get adminTermsPeriod => '계약 기간';

  @override
  String get adminTermsFrom => '시작일';

  @override
  String get adminTermsUntil => '종료일';

  @override
  String get adminTermsClear => '지우기';

  @override
  String get adminTermsSave => '저장';

  @override
  String get adminTermsSaved => '저장했어요';

  @override
  String get adminTermsUnchanged => '바뀐 게 없어요';

  @override
  String get adminTermsHistory => '변경 이력';

  @override
  String get adminTermsHistoryEmpty => '아직 변경 이력이 없어요.';

  @override
  String get adminTermsBadNumber => '숫자를 허용 범위 안에서 적어 주세요.';

  @override
  String get adminTermsFocPair => '강사 FOC는 10+1처럼 둘 다 적거나 둘 다 비워 주세요.';

  @override
  String get adminTermsBadPeriod => '끝나는 날은 시작하는 날과 같거나 이후여야 해요.';

  @override
  String get partnerPromoChip => '프로모션';

  @override
  String get partnerPromoSend => '보내기';

  @override
  String get partnerPromoSent => '보냈어요';

  @override
  String get partnerPromoNote => '한 줄 설명';

  @override
  String get partnerPromoKind => '종류';

  @override
  String get partnerPromoBadNote => '설명을 1자에서 80자 사이로 적어 주세요.';

  @override
  String get partnerPromoBadPeriod => '기간은 시작일부터 1년 안으로 적어 주세요.';

  @override
  String get partnerPromoBadKind => '종류를 골라 주세요.';

  @override
  String get partnerPromoBadDay => '날짜는 2026-10-01처럼 적어 주세요.';

  @override
  String get adminPromoNew => '새 제안';

  @override
  String get adminPromoHandled => '처리함';

  @override
  String get adminPromoMark => '처리함으로 표시';

  @override
  String get adminPromoEmpty => '도착한 제안이 없어요.';

  @override
  String get adminContractsComingSoon => '준비 중';

  @override
  String get adminContractStatusNone => '미체결';

  @override
  String get adminContractStatusAwaiting => '서명 대기';

  @override
  String get adminContractStatusExecuted => '체결';

  @override
  String get adminContractStatusExpiring => '만료 임박';

  @override
  String get adminVaultUpload => 'PDF 올리기';

  @override
  String get adminVaultSend => '파트너에게 발송';

  @override
  String get adminVaultVoid => '폐기';

  @override
  String get adminVaultDownload => '체결본 받기';

  @override
  String get adminVaultPickShop => '제휴파트너를 선택하세요';

  @override
  String get adminVaultTitleHint => '문서 제목';

  @override
  String get adminVaultVersionHint => '버전';

  @override
  String get adminVaultKindMaster => '기본계약';

  @override
  String get adminVaultKindAnnex => '부속 약정서';

  @override
  String get adminVaultEmpty => '이 파트너 서류함이 비어 있어요.';

  @override
  String get partnerVaultTitle => '서류함';

  @override
  String get partnerVaultAwaiting => '서명 대기';

  @override
  String get partnerVaultExecuted => '체결';

  @override
  String get partnerVaultEmpty => '도착한 계약 서류가 없어요.';

  @override
  String get partnerVaultOpen => '열람·서명';

  @override
  String get partnerVaultSign => '서명하여 체결';

  @override
  String get partnerVaultRevision => '수정 요청';

  @override
  String get partnerVaultRevisionHint => '수정이 필요한 내용을 적어 주세요';

  @override
  String get partnerVaultShaMismatch => '파일이 바뀌었습니다. 서명을 중단했어요. 운영팀에 문의해 주세요.';

  @override
  String get partnerVaultAckView => '문서를 열람했습니다';

  @override
  String get partnerVaultAgree => '계약 내용에 동의합니다';

  @override
  String get partnerVaultSignerName => '서명자 이름';

  @override
  String get partnerVaultSignature => '손글씨 서명';

  @override
  String get partnerVaultDownload => '원본·서명 정보 받기';

  @override
  String get adminMetricMembers => '전체 회원';

  @override
  String get adminMetricPendingCert => '인증 대기';

  @override
  String get adminMetricPlaques => '현판 대기';

  @override
  String get adminMetricPosts => '게시글';

  @override
  String adminMetricHidden(int count) {
    return '숨김 $count';
  }

  @override
  String adminMetricShops(int count) {
    return '제휴 샵 $count곳';
  }

  @override
  String get adminSalesTitle => '이번 달 매출';

  @override
  String adminSalesTotal(String amount) {
    return '합계 $amount원';
  }

  @override
  String get adminSalesExplore => '일반 상품';

  @override
  String get adminSalesFlag => '깃발 꽂기';

  @override
  String get adminSalesDiverPlanned => '내가 짠 상품';

  @override
  String get adminSalesCurated => '기획 스페셜';

  @override
  String get adminSalesDiveStar => '다이브 스타';

  @override
  String get adminSalesHotSpot => '핫스팟';

  @override
  String get adminSalesNextDeparture => '마감 임박';

  @override
  String get adminAttentionTitle => '지금 처리할 일';

  @override
  String get adminAttentionClear => '대기 중인 긴급 작업이 없습니다.';

  @override
  String adminAttentionCertify(int count) {
    return '강사 자격증 $count건 승인 대기';
  }

  @override
  String adminAttentionPlaque(int count) {
    return '현판 발송 $count건 확인 필요';
  }

  @override
  String adminAttentionHidden(int count) {
    return '숨긴 게시글 $count건';
  }

  @override
  String get adminGradeMixTitle => '회원 등급 분포';

  @override
  String get adminQuickActions => '빠른 실행';

  @override
  String get adminMembersTitle => '회원 관리';

  @override
  String get adminMembersSubtitle => '회원을 조회하고 실버·골드·다이아몬드·플래티넘 등급을 조정합니다.';

  @override
  String get adminMembersSearch => '이름·아이디·이메일·샵 검색';

  @override
  String get adminMembersEmpty => '조건에 맞는 회원이 없습니다.';

  @override
  String get adminMembersGrade => '회원 등급';

  @override
  String adminMembersActivity(int logs, int regions) {
    return '로그 $logs회 · 지역 $regions곳';
  }

  @override
  String adminMembersSuggested(String grade) {
    return '활동 참고 등급 · $grade';
  }

  @override
  String get memberGradeSilver => '실버회원';

  @override
  String get memberGradeGold => '골드회원';

  @override
  String get memberGradeDiamond => '다이아몬드회원';

  @override
  String get memberGradePlatinum => '플래티넘회원';

  @override
  String get adminInstructorsTitle => '강사 자격증 승인';

  @override
  String get adminInstructorsSubtitle =>
      'R2에 올라온 C-Card를 확인하고 승인하면 강사 우대가가 열립니다.';

  @override
  String adminInstructorAgency(String agency) {
    return '발행 기관 · $agency';
  }

  @override
  String get adminApprove => '승인';

  @override
  String get adminReject => '반려';

  @override
  String get adminNoPending => '대기 중인 자격증 신청이 없습니다.';

  @override
  String get adminShopsTitle => '파트너';

  @override
  String get adminPartnersGradeHint =>
      '다이브스타 등급은 관리자가 심사 양식으로 점수·게이트를 입력한 뒤 「등급 확정」할 때 부여됩니다. 수동 「등급 수정」도 가능합니다.';

  @override
  String get adminShopsSubtitle => '오퍼레이션 평점과 스타 등급, 실물 현판 발송을 모니터링합니다.';

  @override
  String get adminProductsTitle => '여행상품 등록';

  @override
  String get adminProductsSubtitle =>
      '등록하면 여행상품 메뉴에 최근순으로 올라갑니다. 홈 노출은 홈 큐레이션에서 고릅니다.';

  @override
  String get adminProductsTab => '상품';

  @override
  String get adminSameBoatTab => '같은배 모니터';

  @override
  String get adminSameBoatBriefTab => '같은배 브리프';

  @override
  String get seatBriefToday => '오늘';

  @override
  String get seatBriefSeven => '7일';

  @override
  String get seatBriefThirty => '30일';

  @override
  String get seatBriefYear => '올해';

  @override
  String get seatBriefCustom => '직접';

  @override
  String get seatBriefCompare => '지난 기간과 비교';

  @override
  String get seatBriefFunnelTitle => '자리가 팔리기까지 · 깔때기';

  @override
  String get seatBriefOpens => '열린 자리';

  @override
  String get seatBriefViews => '조회';

  @override
  String get seatBriefFlags => '깃발';

  @override
  String get seatBriefPays => '결제';

  @override
  String seatBriefViewsPerOpen(String count) {
    return '열림 → 조회 자리당 $count회';
  }

  @override
  String seatBriefConclusionPrice(String who, int views, int flags, int pays) {
    return '$who 조회 $views · 깃발 $flags · 결제 $pays. 가격이 막고 있는 것으로 보여요';
  }

  @override
  String seatBriefConclusionSelling(
    String who,
    int views,
    int flags,
    int pays,
  ) {
    return '$who 조회 $views · 깃발 $flags · 결제 $pays. 잘 팔리고 있어요';
  }

  @override
  String seatBriefConclusionQuiet(String who, int views, int flags, int pays) {
    return '$who 조회 $views · 깃발 $flags · 결제 $pays. 아직 조용해요';
  }

  @override
  String get seatBriefConclusionWait => '기록이 더 쌓이면 알려 드릴게요';

  @override
  String get seatBriefScoreTitle => '자리 성적표';

  @override
  String get seatBriefScoreHint => '지역·상품별';

  @override
  String get seatBriefScoreRegion => '지역별';

  @override
  String get seatBriefScoreProduct => '상품별';

  @override
  String seatBriefScoreCounts(int views, int flags, int pays) {
    return '조회 $views  깃발 $flags  결제 $pays';
  }

  @override
  String seatBriefScoreFill(int percent) {
    return '채움 $percent%';
  }

  @override
  String get seatBriefBadgeSelling => '잘 팔림';

  @override
  String get seatBriefBadgeViews => '조회만 많음';

  @override
  String get seatBriefBadgeQuiet => '조용함';

  @override
  String get seatBriefBadgeOrdinary => '보통';

  @override
  String seatBriefFlagRate(int percent) {
    return '조회 → 깃발 $percent%';
  }

  @override
  String seatBriefPayRate(int percent) {
    return '깃발 → 결제 $percent%';
  }

  @override
  String get seatBriefBeforeRecording => '기록 시작일 이전은 예약 기준';

  @override
  String get seatBriefMissedTitle => '놓친 수요';

  @override
  String get seatBriefMissedHint => '0건 검색';

  @override
  String get seatBriefMissedTop => '많이 찾았는데 없던 조건';

  @override
  String seatBriefMissedCount(int count) {
    return '$count회';
  }

  @override
  String get seatBriefMissedWall => '무엇이 막고 있었나요';

  @override
  String get seatBriefMissedWallHint => '조건을 하나 뺐을 때 결과가 열린 횟수';

  @override
  String get seatBriefMissedEmpty => '아직 기록이 없어요';

  @override
  String get partnerMeetingOpen => '미팅 보고서 만들기';

  @override
  String get partnerMeetingTitle => '파트너 미팅 보고서';

  @override
  String get partnerMeetingHint => '조건을 고르면 보고서를 만들어 드려요';

  @override
  String get partnerMeetingPartner => '파트너';

  @override
  String get partnerMeetingScope => '상품 · 지역';

  @override
  String partnerMeetingScopeAll(int count) {
    return '전체 (상품 $count개)';
  }

  @override
  String partnerMeetingScopeRegion(String name, int count) {
    return '$name 전체 (상품 $count개)';
  }

  @override
  String get partnerMeetingPreview => '보고서 미리보기';

  @override
  String get partnerMeetingPreviewTitle => '미리보기';

  @override
  String get partnerMeetingPreviewHint => 'A4 1~2쪽 · 파트너 미팅 보고서';

  @override
  String partnerMeetingPaperKicker(String shop) {
    return '다이브트래블 × $shop · 미팅 자료';
  }

  @override
  String get partnerMeetingPaperTitle => '같은배 빈자리 운영 리포트';

  @override
  String get partnerMeetingCompareNote => '지난 기간 대비';

  @override
  String get partnerMeetingConclusion => '한 줄 결론';

  @override
  String get partnerMeetingConclusionHint => '이번 기간 가장 중요한 한 가지';

  @override
  String get partnerMeetingFunnel => '팔리는 과정';

  @override
  String get partnerMeetingFunnelHint => '깔때기';

  @override
  String get partnerMeetingScoreHint => '이 파트너의 자리만';

  @override
  String get partnerMeetingDemandHint => '이 지역에서 못 찾은 조건';

  @override
  String get partnerMeetingProposals => '함께 만들 자리 제안';

  @override
  String get partnerMeetingProposalsHint => '수요에 맞춘 가격·인원·날짜 아이디어';

  @override
  String get partnerMeetingOpens => '열림';

  @override
  String get partnerMeetingPrint => '출력 / PDF';

  @override
  String get partnerMeetingSave => '저장';

  @override
  String get partnerMeetingSend => '보내기';

  @override
  String get partnerMeetingLock =>
      '다른 파트너의 이름과 숫자는 자동으로 빠져요. 회원 이름·연락처는 들어가지 않아요';

  @override
  String get partnerMeetingNoShop => '선택할 파트너 샵이 없어요';

  @override
  String get partnerMeetingArchive => '보고서 보관함';

  @override
  String get partnerMeetingArchiveEmpty => '저장한 보고서가 없어요';

  @override
  String get partnerMeetingSaved => '저장했어요';

  @override
  String get partnerMeetingAgain => '같은 조건으로 다시 만들기';

  @override
  String get partnerMeetingUnsend => '보내기 취소';

  @override
  String get partnerMeetingSent => '보냈어요';

  @override
  String get partnerMeetingUnsent => '보내기를 취소했어요';

  @override
  String get partnerMeetingDraft => '미발송';

  @override
  String get partnerMeetingSentBadge => '보냄';

  @override
  String get partnerMeetingInbox => '받은 보고서';

  @override
  String partnerMeetingInboxNew(int count) {
    return '새 보고서 $count';
  }

  @override
  String get partnerMeetingInboxEmpty => '받은 보고서가 없어요';

  @override
  String get partnerMeetingCopyLink => '링크 복사';

  @override
  String get partnerMeetingLinkCopied => '링크를 복사했습니다.';

  @override
  String get partnerMeetingDenied => '이 보고서를 볼 수 없어요';

  @override
  String partnerMeetingPrevious(int opens, int views, int flags, int pays) {
    return '지난 기간 열림 $opens · 조회 $views · 깃발 $flags · 결제 $pays';
  }

  @override
  String get adminSameBoatTitle => '같은배 · 빈자리 모니터';

  @override
  String get adminSameBoatHint => '등록자가 연 빈자리만 표시합니다. 깃발 지정은 여기서 하지 않습니다.';

  @override
  String get adminSameBoatApproveHint =>
      '빈자리 신청을 승인하면 같은배 메뉴에 올라갑니다. 깃발을 꽂으면 결제 시한까지 좌석이 잠깁니다.';

  @override
  String get adminSameBoatPendingQueue => '빈자리 승인 대기';

  @override
  String get adminSameBoatPendingEmpty => '대기 중인 빈자리 신청이 없습니다.';

  @override
  String get adminSameBoatLiveTitle => '같은배에 열린 빈자리';

  @override
  String get adminSameBoatApprove => '승인 · 같은배 게시';

  @override
  String get adminSameBoatReject => '반려';

  @override
  String get adminSameBoatPendingBadge => '승인 대기';

  @override
  String get adminSameBoatLiveBadge => '같은배 게시중';

  @override
  String get adminSameBoatRejectedBadge => '반려됨';

  @override
  String get adminSameBoatClosedBadge => '닫힘';

  @override
  String get adminSameBoatEmpty => '열린 빈자리 상품이 없습니다.';

  @override
  String get adminSameBoatZeroBookings => '예약 0';

  @override
  String adminSameBoatZeroBookingsForDays(int days) {
    return '열린 지 $days일째 예약 0';
  }

  @override
  String get adminSameBoatHide => '숨김';

  @override
  String get adminSameBoatReopen => '다시 열기';

  @override
  String get adminSameBoatHiddenTitle => '숨긴 자리';

  @override
  String get adminSameBoatHiddenEmpty => '숨긴 빈자리가 없습니다.';

  @override
  String get sameBoatSeatsTitle => '빈자리 열기';

  @override
  String get sameBoatApplyTitle => '같은배 신청';

  @override
  String get sameBoatAskCreateSeats => '이 상품에 빈자리를 만들겠습니까?';

  @override
  String get sameBoatAskCreateSeatsYes => '만들기';

  @override
  String get sameBoatAskCreateSeatsNo => '취소';

  @override
  String get sameBoatHubSearchHint => '상품 이름 검색';

  @override
  String get sameBoatSeatsHint =>
      '기본 상품과 개별 상품에 빈자리를 열고, 출발일·깃발 마감을 넣은 뒤 관리자 승인을 요청합니다.';

  @override
  String get sameBoatSeatsHubHint => '상품을 고른 뒤 빈자리 수·출발일·깃발 마감을 정해 같은배에 신청합니다.';

  @override
  String get sameBoatSeatsNoProducts =>
      '빈자리를 열 수 있는 승인된 상품이 없습니다. 관리자가 상품을 승인한 뒤 빈자리를 열 수 있습니다.';

  @override
  String get sameBoatHubAwaitingPublishTitle => '상품 승인 대기';

  @override
  String get sameBoatHubAwaitingPublishHint =>
      '아직 공개되지 않은 상품입니다. 좌석 신청은 승인된 상품만 가능합니다.';

  @override
  String get sameBoatHubAwaitingPublishEmpty => '승인 대기 중인 상품이 없습니다.';

  @override
  String get partnerProductListEmpty =>
      '등록한 상품이 없습니다. 저장하면 이 목록에 「승인 대기」로 나타납니다.';

  @override
  String get shopStatRefreshFailed =>
      '저장은 됐지만 목록을 새로고치지 못했습니다. 당겨서 새로고침하거나 화면을 다시 열어 주세요.';

  @override
  String get sameBoatSeatsSubmit => '승인 요청';

  @override
  String get sameBoatSeatsPublish => '같은배에 바로 게시';

  @override
  String get sameBoatSeatsSubmitted => '빈자리 승인 요청을 보냈습니다.';

  @override
  String get creatorOpenSeatsButton => '빈자리 열기';

  @override
  String get creatorOpenSeatsSnack => '빈자리를 열었어요. 같은배에서 바로 보여요';

  @override
  String get sameBoatSeatsPublished => '같은배에 빈자리를 게시했습니다.';

  @override
  String get sameBoatSeatsEdit => '빈자리 수정';

  @override
  String get sameBoatSeatsWaiting => '승인 대기 중';

  @override
  String get sameBoatSeatsAlreadyPending => '이미 승인 대기 중인 요청이 있습니다.';

  @override
  String get sameBoatSeatsAlreadyLive => '이미 같은배에 게시된 상품입니다.';

  @override
  String get sameBoatApproveIncomplete => '좌석·출발일 정보가 부족해 승인할 수 없습니다.';

  @override
  String get sameBoatHubApprove => '승인';

  @override
  String get sameBoatHubOpenSeats => '빈자리 열기';

  @override
  String get partnerSameBoatRequestsTitle => '내 같은배 요청';

  @override
  String get partnerSameBoatRequestsEmpty => '요청한 빈자리가 없습니다.';

  @override
  String get adminSameBoatApplyTab => '빈자리 신청';

  @override
  String get adminSameBoatApplyHint => '공개 상품을 골라 빈자리를 열고 같은배에 바로 게시합니다.';

  @override
  String get partnerSectionShopProducts => '샵 · 상품';

  @override
  String get partnerSectionSameBoat => '같은배 신청';

  @override
  String get partnerSectionOps => '예약 · 정산';

  @override
  String get partnerSameBoatApplyHint => '자기 상품 중 빈자리를 채울 상품을 고르고 신청합니다.';

  @override
  String get sameBoatIndividualSeats => '개별 상품 빈자리';

  @override
  String get sameBoatHoldPriorityHint =>
      '다이버 깃발은 이 깃발 마감과 심은 뒤 24시간 중 더 빠른 시각까지 잠깁니다. 그 안에 결제하지 않으면 자리가 다시 열립니다.';

  @override
  String get workbenchFlagDeadlineRequired => '깃발 마감일을 정해 주세요.';

  @override
  String communityFlagPayBy(String deadline) {
    return '결제 기한: $deadline';
  }

  @override
  String get communityFlagPayByShortened => '배 깃발 마감이 더 빨라서 이 시각까지입니다.';

  @override
  String get checkoutFlagPayBy => '결제 기한';

  @override
  String get adminProductSourceAll => '전체';

  @override
  String get adminProductSourcePartner => '제휴파트너';

  @override
  String get adminProductSourceDiy => '내가짠여행';

  @override
  String get adminProductSourceSpecial => '기획스페셜';

  @override
  String get adminProductSourceUnknown => '미분류';

  @override
  String adminProductFilterShop(String name) {
    return '샵 필터 · $name';
  }

  @override
  String get adminProductClearShopFilter => '필터 해제';

  @override
  String get adminOpenSeatsBadge => '빈자리';

  @override
  String get adminInternalScore => '내부심사';

  @override
  String get adminInternalScoreHint => '0–100';

  @override
  String get adminInternalScoreEdit => '내부점수 수정';

  @override
  String get adminInternalScoreSaved => '내부심사 점수를 저장했습니다.';

  @override
  String get adminDiveStarGrade => '다이브스타 등급';

  @override
  String get adminDiveStarGradeHint => '0–3 (0 = 없음)';

  @override
  String get adminDiveStarReviewedAt => '심사일';

  @override
  String get adminDiveStarExpiresAt => '만료일';

  @override
  String get adminDiveStarGradeEdit => '다이브스타 등급 수정';

  @override
  String get adminDiveStarGradeSaved => '다이브스타 등급을 저장했습니다.';

  @override
  String get adminDiveStarAssessmentMenu => '다이브스타 심사';

  @override
  String get adminDiveStarAssessmentTitle => '다이브스타 심사';

  @override
  String get adminDiveStarAssessmentHint =>
      '저장하면 합계와 후보 등급만 계산됩니다. 손님 화면에 보이는 별은 「등급 확정」을 눌러야 바뀝니다.';

  @override
  String get adminDiveStarAssessmentFormSection => '새 심사 입력';

  @override
  String get adminDiveStarAssessmentType => '심사 유형';

  @override
  String get adminDiveStarTypeOnsite => '현장 심사';

  @override
  String get adminDiveStarTypeMystery => '미스터리 심사';

  @override
  String get adminDiveStarTypeDocument => '서류 심사';

  @override
  String get adminDiveStarTrialMenu => 'v2 시험 심사';

  @override
  String get adminDiveStarTrialTitle => '다이브스타 심사 (v2 시험)';

  @override
  String get adminDiveStarTrialHint =>
      '초안 v2 양식으로 미리보기만 합니다. 저장은 3단계에서 됩니다. 지금 활성 양식은 v1로 유지됩니다.';

  @override
  String get adminDiveStarTrialNoDraft =>
      '항목이 있는 v2 초안 양식이 없습니다. 먼저 「심사 양식 가져오기」로 저장하세요.';

  @override
  String get adminDiveStarTrialSaveLocked =>
      '시험 모드에서는 저장할 수 없습니다. 3단계에서 저장됩니다.';

  @override
  String get adminDiveStarFillMaxScores => '모든 항목 만점으로 채우기';

  @override
  String get adminDiveStarGatesSection => '필수 게이트 (하나라도 탈락이면 별 부여 불가)';

  @override
  String adminDiveStarCountryGatesSection(int max) {
    return '국가별 게이트 (최대 $max개)';
  }

  @override
  String get adminDiveStarCountryGateName => '게이트 이름';

  @override
  String get adminDiveStarCountryGateCriteria => '기준';

  @override
  String get adminDiveStarCountryGateAdd => '국가 게이트 추가';

  @override
  String get adminDiveStarAreaApplicable => '적용';

  @override
  String get adminDiveStarAreaNotApplicable => '해당없음';

  @override
  String get adminDiveStarAreaNaBlocked => '안전 영역은 해당없음으로 둘 수 없습니다.';

  @override
  String get adminDiveStarItemsSection => '항목별 채점';

  @override
  String adminDiveStarItemScore(int max) {
    return '득점 (0–$max)';
  }

  @override
  String get adminDiveStarItemGuidance => '채점 기준·증빙·근거';

  @override
  String get adminDiveStarItemCriteria => '기준';

  @override
  String get adminDiveStarItemEvidence => '증빙';

  @override
  String get adminDiveStarItemBasis => '근거';

  @override
  String adminDiveStarAreaProgress(int filled, int total) {
    return '입력 $filled/$total';
  }

  @override
  String get adminDiveStarItemUnscored => '미입력';

  @override
  String get adminDiveStarMysteryVisits => '미스터리 방문 횟수 (0–20)';

  @override
  String get adminDiveStarAuditor1 => '심사관 1';

  @override
  String get adminDiveStarAuditor2 => '심사관 2';

  @override
  String adminDiveStarAreaRateLine(String area, int earned, int max, int pct) {
    return '$area: $earned/$max ($pct%)';
  }

  @override
  String get adminDiveStarReasonGateFailed => '게이트 미통과로 후보 등급 0';

  @override
  String get adminDiveStarReasonBelowStar1 => '1스타 기준 점수 미달';

  @override
  String get adminDiveStarReasonStar1 => '1스타 기준 충족';

  @override
  String get adminDiveStarReasonStar2 => '2스타 기준 충족';

  @override
  String get adminDiveStarReasonStar3 => '3스타 기준 충족';

  @override
  String get adminDiveStarReasonSafety => '총점은 충분하나 안전 영역 비율 미달';

  @override
  String get adminDiveStarReasonAreaRatio => '3스타용 영역별 최소 비율 미달';

  @override
  String get adminDiveStarReasonMystery => '3스타용 미스터리 방문 횟수 미달';

  @override
  String adminDiveStarReasonOther(String code) {
    return '후보 등급 사유: $code';
  }

  @override
  String get adminDiveStarGatePass => '통과';

  @override
  String get adminDiveStarGateFail => '탈락';

  @override
  String get adminDiveStarAreasSection => '영역별 점수';

  @override
  String get adminDiveStarAreaComment => '코멘트 (선택)';

  @override
  String get adminDiveStarAssessmentSave => '심사 저장';

  @override
  String get adminDiveStarAssessmentSaved => '심사를 저장했습니다. 아직 샵 등급은 바뀌지 않았습니다.';

  @override
  String get adminDiveStarAssessmentRetry => '다시 시도';

  @override
  String adminDiveStarPreview(int score, int grade) {
    return '합계 $score점 · 후보 $grade스타';
  }

  @override
  String get adminDiveStarGatesOk => '게이트 전부 통과';

  @override
  String get adminDiveStarGatesBlocked => '게이트 미통과 — 후보 등급 0';

  @override
  String get adminDiveStarConfirmTitle => '등급 확정';

  @override
  String adminDiveStarConfirmBody(int grade, int score) {
    return '후보 $grade스타(합계 $score점)를 이 샵에 반영할까요?';
  }

  @override
  String get adminDiveStarConfirmAction => '등급 확정';

  @override
  String get adminDiveStarConfirmed => '샵 다이브스타 등급을 확정했습니다.';

  @override
  String get adminDiveStarAlreadyConfirmed => '이미 확정됨';

  @override
  String get adminDiveStarHistorySection => '심사 이력';

  @override
  String get adminDiveStarHistoryEmpty => '아직 저장된 심사가 없습니다.';

  @override
  String adminDiveStarHistoryLine(String date, int score, int grade) {
    return '$date · $score점 · 후보 $grade스타';
  }

  @override
  String get adminDiveStarStatusConfirmed => '확정';

  @override
  String get adminDiveStarStatusDraft => '미확정';

  @override
  String get adminDiveStarModeNew => '새 심사';

  @override
  String get adminDiveStarModeEditing => '수정 중 · 미확정';

  @override
  String get adminDiveStarModeReadonly => '확정됨 · 읽기 전용';

  @override
  String get adminDiveStarStartNew => '새 심사 시작';

  @override
  String get adminDiveStarCopyAsNew => '이 기록을 복사해서 새 심사 만들기';

  @override
  String get adminDiveStarCopySameDateTitle => '심사일 확인';

  @override
  String get adminDiveStarCopySameDateBody => '재심사 날짜가 원본과 같습니다. 이대로 저장할까요?';

  @override
  String get adminDiveStarDeleteDraft => '미확정 심사 삭제';

  @override
  String get adminDiveStarDeleteConfirmTitle => '심사를 삭제할까요?';

  @override
  String get adminDiveStarDeleteConfirmBody => '이 미확정 기록을 삭제합니다. 되돌릴 수 없습니다.';

  @override
  String get adminDiveStarDeleted => '심사를 삭제했습니다.';

  @override
  String get adminDiveStarAssessmentUpdated => '심사를 덮어써서 저장했습니다.';

  @override
  String get adminDiveStarFormImportMenu => '심사 양식 가져오기';

  @override
  String get adminDiveStarFormImportTitle => '다이브스타 양식 가져오기';

  @override
  String get adminDiveStarFormImportHint =>
      '양식 JSON을 붙여넣어 초안(비활성)으로 저장합니다. 준비가 되면 「사용 중으로 전환」으로 활성 양식을 바꿀 수 있습니다.';

  @override
  String get adminDiveStarFormImportPasteLabel => '양식 JSON';

  @override
  String get adminDiveStarFormImportAction => '검사 후 초안 저장';

  @override
  String get adminDiveStarFormImportEmpty => 'JSON을 먼저 붙여넣어 주세요.';

  @override
  String get adminDiveStarFormImportInvalidJson => 'JSON을 읽을 수 없습니다.';

  @override
  String get adminDiveStarFormImportMissingVersion => 'version 필드가 필요합니다.';

  @override
  String get adminDiveStarFormImportAreaSum => '영역 배점 합계가 100이어야 합니다.';

  @override
  String get adminDiveStarFormImportItemSum => '항목 배점 합계가 각 영역 배점과 같아야 합니다.';

  @override
  String get adminDiveStarFormImportDuplicateId => '중복된 ID가 있습니다(영역·게이트·항목).';

  @override
  String adminDiveStarFormImportInvalid(String code) {
    return '가져오기 실패: $code';
  }

  @override
  String get adminDiveStarFormImportExists => '같은 버전이 이미 있습니다. 덮어쓰지 않습니다.';

  @override
  String adminDiveStarFormImportSaved(String version) {
    return '$version을(를) 초안(비활성)으로 저장했습니다.';
  }

  @override
  String get adminDiveStarFormListSection => '저장된 양식';

  @override
  String get adminDiveStarFormListEmpty =>
      '아직 Firestore에 양식이 없습니다(심사를 열면 v1이 시드됩니다).';

  @override
  String adminDiveStarFormListLoadError(String detail) {
    return '양식 목록을 불러오지 못했습니다. 아래 JSON 붙여넣기는 그대로 쓸 수 있습니다. ($detail)';
  }

  @override
  String get adminDiveStarFormStatusActive => '사용 중';

  @override
  String get adminDiveStarFormStatusDraft => '초안';

  @override
  String get adminDiveStarFormActivate => '이 양식을 사용 중으로 전환';

  @override
  String get adminDiveStarFormActivateLockedHint =>
      '3단계 완료 후 사용 가능합니다. 지금은 활성 양식이 v1로 유지됩니다.';

  @override
  String adminDiveStarFormActivated(String version) {
    return '$version을(를) 사용 중으로 전환했습니다.';
  }

  @override
  String adminDiveStarFormMissingForHistory(String version) {
    return '이 기록의 양식($version)을 찾지 못해 사용 중 양식으로 엽니다.';
  }

  @override
  String get adminDocsTitle => '문서·양식';

  @override
  String get adminTrialDataTab => '시험 데이터 · 출시 전 제거';

  @override
  String get adminTrialDataTitle => '시험 데이터 점검·정리';

  @override
  String get adminTrialPrelaunchBanner =>
      '출시 전 삭제 예정 기능 — 운영 데이터가 아닙니다. 백업 후 사용하세요.';

  @override
  String get adminTrialLimitsBody =>
      '한계: Firebase Auth 로그인 계정은 앱에서 못 지웁니다(Console → Authentication → Users). users 문서만 지우면 같은 아이디로 다시 로그인할 때 빈 회원 문서가 생길 수 있으니, 시험 계정은 Firestore 삭제 후 Console에서 Auth도 지우세요. R2·Storage 사진 파일은 문서와 별개로 남을 수 있습니다. 서류함(partner_contracts)은 규칙상 앱 삭제 불가 — Console에서 수동 삭제하세요. 하위 컬렉션은 부모와 함께 자동 삭제되지 않습니다.';

  @override
  String get adminTrialRefresh => '건수 새로고침';

  @override
  String get adminTrialCountsTitle => '경로별 건수';

  @override
  String get adminTrialUnavailable => '앱에서 확인 불가';

  @override
  String get adminTrialCountError => '조회 실패';

  @override
  String get adminTrialFlagProtected => '보호';

  @override
  String get adminTrialFlagDeletable => '삭제 가능';

  @override
  String adminTrialJejuProtected(String name, String id) {
    return '보호 샵: $name · id=$id (상품·예약·후기·서류함·소유 회원 포함)';
  }

  @override
  String get adminTrialJejuMissing =>
      '「제주 오렌지」 샵을 찾지 못했습니다. 보호 샵 없이 시험 삭제가 가능하니 주의하세요.';

  @override
  String get adminTrialJejuAmbiguous =>
      '「제주 오렌지」와 비슷한 샵이 여러 개입니다. 목록을 확인한 뒤 Console에서 정리하고 다시 열어 주세요. 삭제를 잠갔습니다.';

  @override
  String get adminTrialDeleteTitle => '선택 삭제';

  @override
  String get adminTrialDeleteHint =>
      '보호 항목은 체크할 수 없습니다. 실행 전 건수를 다시 읽고, 확인 문구를 정확히 입력하세요.';

  @override
  String get adminTrialBackupCheck => '백업(또는 Export)은 했습니다';

  @override
  String get adminTrialConfirmLabel => '확인 문구 입력';

  @override
  String get adminTrialConfirmMismatch => '확인 문구가 「삭제합니다」와 같지 않습니다.';

  @override
  String get adminTrialBackupRequired => '백업 확인에 체크해 주세요.';

  @override
  String get adminTrialRunDelete => '선택 항목 삭제 실행';

  @override
  String adminTrialResult(int ok, int fail) {
    return '결과 · 성공 $ok · 실패 $fail';
  }

  @override
  String get adminTrialSelOutbox => '파트너 메일 큐';

  @override
  String get adminTrialSelLoi => 'LOI 신청';

  @override
  String get adminTrialSelPosts => '커뮤니티 글·댓글';

  @override
  String get adminTrialSelReviews => '후기(제주 오렌지 제외)';

  @override
  String get adminTrialSelUserBookings => '회원 쪽 예약 복사본';

  @override
  String get adminTrialSelUserLogs => '회원 로그';

  @override
  String get adminTrialSelAssessments => '미확정 다이브스타 평가';

  @override
  String get adminTrialSelShopBookings => '시험 샵 예약';

  @override
  String get adminTrialSelProducts => '시험 샵 상품 배열 비우기';

  @override
  String get adminTrialSelShops => '시험 샵 문서 삭제(주인 해제→하위→샵)';

  @override
  String get adminTrialSelUsers => '시험 회원 문서(사장님·본인·제주오렌지 주인 제외)';

  @override
  String get adminDocsHint =>
      '파트너에게 보낼 공개 안내서·신청서를 보관하고 공유합니다. 내부용 파일은 여기에 넣지 마세요.';

  @override
  String get adminDocsListSection => '문서 목록';

  @override
  String get adminDocsEmpty => '등록된 문서가 없습니다.';

  @override
  String get adminDocsShareHistory => '발송 기록';

  @override
  String get adminDocsShareHistoryEmpty => '아직 발송 기록이 없습니다.';

  @override
  String get adminDocFilterAll => '전체';

  @override
  String get adminDocCatCriteria => '심사 기준';

  @override
  String get adminDocCatPartnerGuide => '파트너 안내';

  @override
  String get adminDocCatApplication => '신청 양식';

  @override
  String get adminDocCatAuditor => '심사관용';

  @override
  String get adminDocCatTraining => '교육 자료';

  @override
  String get adminDocCatContract => '계약·약관';

  @override
  String get adminDocStatusDraft => '초안';

  @override
  String get adminDocStatusApproved => '승인';

  @override
  String get adminDocAudiencePublic => '공개';

  @override
  String get adminDocAudienceInternal => '내부';

  @override
  String get adminDocActionPrint => '인쇄';

  @override
  String get adminDocActionDownload => '다운로드';

  @override
  String get adminDocActionShare => '공유';

  @override
  String get adminDocActionEmail => '이메일';

  @override
  String get adminDocActionCopyLink => '링크 복사';

  @override
  String get adminDocActionQr => 'QR 코드';

  @override
  String get adminDocActionFaxPrint => '팩스용 출력';

  @override
  String get adminDocSendToPartner => '파트너에게 보내기';

  @override
  String get adminDocPickPartner => '파트너(샵) 선택';

  @override
  String adminDocRecommendedChannels(String channels) {
    return '추천 채널: $channels';
  }

  @override
  String get adminDocDraftWarnTitle => '초안 문서입니다';

  @override
  String get adminDocDraftWarnBody => '초안입니다. 확정본을 쓰세요. 그래도 보낼까요?';

  @override
  String get adminDocDraftWarnContinue => '그래도 보내기';

  @override
  String get adminDocShareRecorded => '발송 기록을 남겼습니다.';

  @override
  String get adminDocShareFallbackCopy => '이 환경에서는 공유 대신 문구·링크를 복사했습니다.';

  @override
  String get adminDocEmailAttachHint => '(첨부가 필요하면 공유 버튼으로 PDF를 보내 주세요.)';

  @override
  String get adminDocLinkCopied => '링크를 복사했습니다.';

  @override
  String get adminDocQrTitle => 'QR 코드';

  @override
  String get adminDocPdfMissing => 'PDF 파일이 아직 없습니다.';

  @override
  String adminDocPdfMissingDetail(String path) {
    return '미리보기를 보려면 프로젝트에 $path 파일을 넣어 주세요.';
  }

  @override
  String get adminDocFaxToBlank => '(받는 곳 미지정)';

  @override
  String get adminDocMarkApproved => '승인으로 바꾸기';

  @override
  String get adminDocMarkDraft => '초안으로 되돌리기';

  @override
  String get adminDocConfigTitle => '채널·문구 설정';

  @override
  String get adminDocConfigChannelsHint =>
      '국가별 추천 채널을 쉼표로 적어 주세요. (예: kakao, email, share)';

  @override
  String get adminDocConfigChannelsKr => '한국 (KR)';

  @override
  String get adminDocConfigChannelsJp => '일본 (JP)';

  @override
  String get adminDocConfigChannelsTh => '태국 (TH)';

  @override
  String get adminDocConfigChannelsId => '인도네시아 (ID)';

  @override
  String get adminDocConfigChannelsDefault => '그 외 (DEFAULT)';

  @override
  String get adminDocConfigTemplatesHint =>
      '발송 문구 템플릿. 자리표시자: 파트너명, 링크 (영문 partner_name, link)';

  @override
  String get adminDocConfigKoSubject => '한국어 제목';

  @override
  String get adminDocConfigKoBody => '한국어 본문';

  @override
  String get adminDocConfigEnSubject => 'English subject';

  @override
  String get adminDocConfigEnBody => 'English body';

  @override
  String get adminDocConfigPlaceholders =>
      '자리표시자 예: 중괄호+파트너명, 중괄호+링크, partner_name, link';

  @override
  String get adminDocConfigSaved => '채널·문구 설정을 저장했습니다.';

  @override
  String get partnerDocsSection => '다이브스타 자료';

  @override
  String get partnerDocsTitle => '안내·신청 문서';

  @override
  String get partnerDocsHint => '승인된 공개 안내서와 신청서를 확인하고 출력할 수 있습니다.';

  @override
  String get partnerDocsEmpty => '아직 열 수 있는 승인 문서가 없습니다. 관리자 승인을 기다려 주세요.';

  @override
  String get partnerLoiTitle => '참여 의향서';

  @override
  String get partnerLoiHint =>
      '샵 정보를 입력하고 손가락으로 서명한 뒤 제출하세요. PDF가 만들어지고 다이브트래블에 접수됩니다.';

  @override
  String get partnerLoiCompany => '회사·샵 이름';

  @override
  String get partnerLoiContact => '담당자 이름';

  @override
  String get partnerLoiEmail => '이메일';

  @override
  String get partnerLoiPhone => '전화';

  @override
  String get partnerLoiCountry => '국가';

  @override
  String get partnerLoiNotes => '메모 (선택)';

  @override
  String get partnerLoiSignature => '서명 (아래에 그려 주세요)';

  @override
  String get partnerLoiClearSignature => '서명 지우기';

  @override
  String get partnerLoiSubmit => '의향서 제출';

  @override
  String get partnerLoiMissingFields => '회사명, 담당자, 서명을 입력해 주세요.';

  @override
  String get partnerLoiSubmitted => '의향서를 접수했습니다.';

  @override
  String get partnerLoiOpenForm => '의향서 작성';

  @override
  String get partnerLoiOpenFormHint => '앱에서 작성·터치 서명·PDF 생성';

  @override
  String get partnerLoiStatusSection => '내 신청 현황';

  @override
  String get partnerLoiStatusEmpty => '아직 제출한 의향서가 없습니다.';

  @override
  String get pipelineGuideSent => '안내 발송';

  @override
  String get pipelineLoiReceived => '의향서 접수';

  @override
  String get pipelineDocsSubmitted => '서류 제출';

  @override
  String get pipelineUnderReview => '심사 중';

  @override
  String get pipelineResultNotified => '결과 통보';

  @override
  String pipelineReminderSubject(String shopName) {
    return '다이브스타 안내: $shopName';
  }

  @override
  String pipelineReminderBody(String shopName, String contactName) {
    return '$contactName 님 안녕하세요.\n\n$shopName 다이브스타 신청 관련 안내입니다. 남은 서류나 문의가 있으면 회신해 주세요.\n\n감사합니다.\n다이브트래블';
  }

  @override
  String get pipelineReminderQueued => '이메일 앱을 열고 발송 큐에 기록했습니다.';

  @override
  String get adminAppsTitle => '다이브스타 신청';

  @override
  String get adminAppsHint =>
      '의향서 접수와 파트너 진행 상태를 관리합니다. 이메일은 큐에 쌓이며, Cloud Functions 연동 전까지는 mailto로 보냅니다.';

  @override
  String get adminAppsReminderSection => '리마인더 대상';

  @override
  String get adminAppsEmailServerNote =>
      '서버 메일 발송은 아직 없습니다. 리마인더는 메일 앱을 열고 큐에 기록합니다.';

  @override
  String get adminAppsReminderEmpty => '기한이 된 리마인더가 없습니다.';

  @override
  String get adminAppsListSection => '신청 목록';

  @override
  String get adminAppsEmpty => '접수된 신청이 없습니다.';

  @override
  String get adminAppsSendReminder => '리마인더 보내기';

  @override
  String adminAppsAdvanceTo(String status) {
    return '$status(으)로 진행';
  }

  @override
  String get adminAppsOutboxSection => '이메일 발송 큐';

  @override
  String get adminAppsOutboxEmpty => '발송 큐가 비어 있습니다.';

  @override
  String get adminAppsOpenList => '신청·진행 상태';

  @override
  String adminAppsReminderDue(String date) {
    return '기한 $date';
  }

  @override
  String get adminViewShopProducts => '상품 보기';

  @override
  String adminSameBoatRemaining(int count) {
    return '잔여 $count';
  }

  @override
  String adminSameBoatFlagged(int count) {
    return '깃발 $count';
  }

  @override
  String get adminHomeCurationTab => '홈 큐레이션';

  @override
  String get adminHomeCurationTitle => '홈 화면 큐레이션';

  @override
  String get adminHomeCurationSubtitle => '승인된 상품을 골라 홈 분류별로 최대 10개까지 내보냅니다.';

  @override
  String get adminHomeCurationPool => '미배치 (여행상품만)';

  @override
  String get adminHomeCurationOnShelf => '이 선반에 올린 상품';

  @override
  String adminHomeCurationCount(int count, int limit) {
    return '$count/$limit';
  }

  @override
  String get adminHomeCurationSend => '이 선반으로';

  @override
  String get adminHomeCurationRemove => '홈에서 내리기';

  @override
  String get adminHomeCurationFull => '이 선반은 이미 10개입니다. 하나를 내린 뒤 다시 올려 주세요.';

  @override
  String get adminHomeCurationEmptyPool => '미배치 공개 상품이 없습니다.';

  @override
  String get adminHomeCurationEmptyShelf => '이 선반에 올린 상품이 없습니다.';

  @override
  String get adminHomeCurationMoved => '홈 선반에 반영했습니다.';

  @override
  String get adminHomeCurationCleared => '홈에서 내렸습니다.';

  @override
  String get adminProductPendingQueue => '승인 대기 상품';

  @override
  String get adminProductPendingEmpty => '승인 대기 중인 상품이 없습니다.';

  @override
  String get adminAllProducts => '등록된 상품';

  @override
  String get adminProductSpecial => '기획 스페셜로 첫 화면에 올리기';

  @override
  String get adminProductApproved => '상품이 승인되어 공개되었습니다.';

  @override
  String get adminPriceRevisionChip => '가격 변경 요청';

  @override
  String adminPriceRevisionPendingOptions(String names) {
    return '승인 대기 신규 옵션: $names';
  }

  @override
  String get adminPriceRevisionApproved => '가격 변경이 승인되어 반영되었어요.';

  @override
  String get adminPriceRevisionRejected => '가격 변경 요청이 반려되었어요.';

  @override
  String get adminProductApproveNeedsPrice => '가격을 입력한 상품만 승인할 수 있어요';

  @override
  String get adminProductApproveOverCap => '1억 원을 넘는 가격이 있어 승인할 수 없어요';

  @override
  String get adminProductRejectNeedsNote => '반려 사유를 입력해 주세요';

  @override
  String get adminProductRejected => '상품 등록이 반려되었습니다.';

  @override
  String get partnerRejectReasonBanner => '관리자 반려 사유';

  @override
  String get partnerRejectReasonExpand => '더 보기';

  @override
  String get partnerRejectReasonCollapse => '접기';

  @override
  String get partnerResubmitNoteTitle => '무엇을 고쳤나요?';

  @override
  String get partnerResubmitNoteHint => '예: 대표 사진을 바꾸고 가격을 수정했습니다.';

  @override
  String get partnerResubmitNoteHelper => '5자 이상 200자 이하';

  @override
  String partnerResubmitCount(int count) {
    return '재요청 $count회차';
  }

  @override
  String get partnerResubmitUnchanged =>
      '반려 후 달라진 내용이 없어요. 반려 사유를 확인하고 고친 뒤 다시 요청해 주세요.';

  @override
  String get partnerResubmitSoftWarnTitle => '관련 항목이 그대로예요';

  @override
  String partnerResubmitSoftWarnBody(String sections) {
    return '반려 사유와 관련된 $sections 항목이 아직 바뀌지 않았어요. 그래도 요청할까요?';
  }

  @override
  String get partnerResubmitSoftWarnFix => '고치러 가기';

  @override
  String get partnerResubmitSoftWarnContinue => '그래도 요청';

  @override
  String get adminProductRejectTagsHint => '해당되는 항목을 고르세요 (선택)';

  @override
  String get rejectTagPhotos => '사진';

  @override
  String get rejectTagPrice => '가격';

  @override
  String get rejectTagOptions => '옵션';

  @override
  String get rejectTagCopy => '이름·소개';

  @override
  String get rejectTagSchedule => '일정·집결·포함';

  @override
  String get rejectTagCancel => '취소 규정';

  @override
  String get rejectTagOther => '기타';

  @override
  String get adminPendingPreviousReject => '직전 반려';

  @override
  String get adminPendingPartnerNote => '파트너 메모';

  @override
  String get adminPendingChangesTitle => '이번 변경';

  @override
  String get adminPendingChangeUnknown => '비교 불가';

  @override
  String get adminProductSubmitHint =>
      '저장하면 승인 대기열로 올라갑니다. 최종 노출은 관리자 승인 후입니다.';

  @override
  String get adminProductSubmitted => '승인 요청이 접수되었습니다.';

  @override
  String get productFormHeroTitle => '여행상품을 등록하세요';

  @override
  String get productFormHeroBody =>
      '대륙 → 샵 → 상세 일정 → 구성 옵션 순으로 채우면 손님 화면에 바로 쓸 수 있습니다.';

  @override
  String get productFormSectionLocation => '위치';

  @override
  String get productFormSectionListing => '노출 위치';

  @override
  String get productFormSectionMedia => '대표 사진';

  @override
  String get productFormSectionBasics => '기본 정보';

  @override
  String get productFormSectionItinerary => '일정 · 집결';

  @override
  String get productFormSectionIncludes => '포함 · 불포함';

  @override
  String get productFormSectionCapacity => '인원 · 난이도';

  @override
  String get productFormSectionPricing => '가격';

  @override
  String get productFormSectionOptions => '상품 구성 옵션';

  @override
  String get productFormContinent => '대륙';

  @override
  String get productFormContinentHint => '먼저 대륙을 고르면 해당 지역 샵만 보입니다.';

  @override
  String get productFormShopHint => '제휴리조트';

  @override
  String get productFormPickShop => '샵을 선택하세요';

  @override
  String get productFormDirectSelect => '기획스페셜 (앱에 없는 리조트)';

  @override
  String get productFormCreatorShop => '내가 짜는 여행 (직접 기획)';

  @override
  String get productFormCreatorResortDone => '완료';

  @override
  String creatorWizardProgress(int step) {
    return '$step/5';
  }

  @override
  String get creatorWizardBack => '이전';

  @override
  String get creatorWizardNext => '다음';

  @override
  String get creatorWizardStepIntro => '소개';

  @override
  String get creatorWizardStepSchedule => '일정';

  @override
  String get creatorWizardStepPrice => '가격';

  @override
  String get creatorWizardStepExtras => '함께 파는 것';

  @override
  String get creatorWizardStepReview => '확인';

  @override
  String get creatorWizardReviewHint =>
      '승인 요청을 누르면 저장돼요. 관리자 승인 후 마이 > 내 캡틴 카드에서 『빈자리 열기』로 날짜와 인원을 정할 수 있어요.';

  @override
  String get creatorWizardSubmitted => '승인 요청을 보냈어요. 승인되면 마이에서 빈자리를 열 수 있어요';

  @override
  String get creatorWizardSkip => '건너뛰기';

  @override
  String get creatorWizardAddToTrip => '여행에 더하기';

  @override
  String get creatorWizardBuySeparate => '따로 구매';

  @override
  String get creatorWizardDetails => '자세히';

  @override
  String get creatorWizardAddCard => '항목 추가';

  @override
  String get creatorWizardOfferName => '이름';

  @override
  String get creatorWizardRemove => '삭제';

  @override
  String get creatorWizardDescription => '설명';

  @override
  String get creatorWizardMissing => '아직 비어 있는 항목';

  @override
  String get creatorWizardNestedAdd => '하위 옵션 추가';

  @override
  String productFormPleaseEnter(String label, String particle) {
    return '$label$particle 입력해 주세요';
  }

  @override
  String get productFormSubtitle => '한 줄 소개';

  @override
  String get productOfferDetails => '자세히 보기';

  @override
  String get productOfferNights => '몇 박 며칠';

  @override
  String get productFormSubtitleHint => '예: 체크다이브 후 2탱크, 같은 밴 동행';

  @override
  String get productFormDurationHint => '예: 2박 3일 / 오전 반나절';

  @override
  String get productFormMeetingPoint => '집결 장소';

  @override
  String get productFormMeetingHint => '예: 팡라오 리조트 로비 07:30';

  @override
  String get productFormSchedule => '일정 요약';

  @override
  String get productFormScheduleHint => '출발·다이빙·복귀 시간을 순서대로 적어 주세요.';

  @override
  String get productFormIncludes => '포함 사항';

  @override
  String get productFormIncludesHint => '보트, 탱크, 가이드, 픽업 등 줄바꿈으로 구분';

  @override
  String get productFormExcludes => '불포함 사항';

  @override
  String get productFormExcludesHint => '장비 렌탈, 해양공원 입장료 등';

  @override
  String get productFormDifficulty => '필요 자격 / 난이도';

  @override
  String get productFormDifficultyHint => '예: OW 이상 · 초급~중급';

  @override
  String get productFormMinGuests => '최소 인원';

  @override
  String get productFormMaxGuests => '최대 인원';

  @override
  String get productFormCancelNote => '취소 · 환불 안내';

  @override
  String get productFormCancelHint => '출발 N일 전 규정 등';

  @override
  String get productFormOptionsHint =>
      '룸타입, 탱크 수, 장비, 트랜스퍼처럼 손님이 고르는 구성을 추가하세요.';

  @override
  String get productFormOptionName => '옵션명';

  @override
  String get productFormOptionGroup => '그룹';

  @override
  String get productFormOptionDesc => '옵션 설명';

  @override
  String get productFormOptionConsumer => '옵션 소비자가';

  @override
  String get productFormOptionPro => '옵션 강사 우대가';

  @override
  String get productFormAddOption => '구성 옵션 추가';

  @override
  String get productFormRemoveOption => '옵션 삭제';

  @override
  String get productFormPhotoHint => '정사각(1:1) 권장. 손님 카드·상세 상단에 사용됩니다.';

  @override
  String get productFormSourcePartner => '제휴 리조트';

  @override
  String get productFormSourceCurated => '직접 기획';

  @override
  String get productFormSourceHint =>
      '제휴 리조트는 카탈로그에서 고릅니다. 직접 기획은 계약 전에도 리조트 이름을 직접 적어 상품을 만들 수 있습니다.';

  @override
  String get productFormCuratedResort => '리조트(샵) 이름';

  @override
  String get productFormCuratedResortHint => '예: 보홀 프라이빗 빌라 다이브';

  @override
  String get productFormCuratedLocation => '지역';

  @override
  String get productFormCuratedLocationHint => '예: 필리핀 보홀 팡라오';

  @override
  String get productFormCuratedCountry => '국가';

  @override
  String get productFormCuratedCountryHint => '예: 필리핀';

  @override
  String get productFormCountryOther => '기타(직접 입력)';

  @override
  String get productFormCountryNoSea => '해역 없음';

  @override
  String get productListingKind => '홈 선반';

  @override
  String get productListingExploreOnly => '미배치 (여행상품만)';

  @override
  String get productListingDiveStar => 'Dive Star 인증';

  @override
  String get productListingFavorites => '내가 만드는 찐 여행';

  @override
  String get productListingPopular => '지금 뜨는 스팟';

  @override
  String get productListingNextDeparture => '같은 배 · 마감 임박';

  @override
  String get productListingCurated => '기획 스페셜';

  @override
  String get productStatusPending => '승인 대기';

  @override
  String get partnerProductBadgePending => '승인 대기';

  @override
  String get partnerProductBadgeDrafting => '작성 중';

  @override
  String get partnerProductBadgeListed => '게시중';

  @override
  String get partnerProductBadgeRejected => '반려';

  @override
  String get partnerProductBadgeClosed => '닫힘';

  @override
  String get partnerProductBadgeMissingPrice => '가격 미입력';

  @override
  String get partnerProductPublish => '게시';

  @override
  String get partnerProductPublishCta => '게시하기';

  @override
  String get partnerProductPublished => '상품이 게시되었습니다.';

  @override
  String get partnerFormSoftGuide =>
      '필수 표시만 적으면 저장돼요. 나머지는 비워도 괜찮아요. 운영팀이 함께 채워 드려요.';

  @override
  String get partnerFormSectionBasics => '기본 정보';

  @override
  String get partnerFormSectionPricing => '가격과 옵션';

  @override
  String get partnerFormSectionPublish => '게시';

  @override
  String get partnerFormRequiredBadge => '필수';

  @override
  String get partnerFormPhotoOptionalHint => '없으면 운영팀이 넣어 드려요. 최대 10장.';

  @override
  String get partnerFormPhotoMain => '대표';

  @override
  String get partnerFormNameHint => '예: 보홀 3박 4일 패키지';

  @override
  String get partnerFormBlurbHint => '고객에게 보이는 한 줄 소개';

  @override
  String get partnerFormProductType => '상품 종류';

  @override
  String get partnerFormNights => '몇 박';

  @override
  String get partnerFormDays => '몇 일';

  @override
  String get partnerFormMeeting => '집합 장소';

  @override
  String get partnerFormShopInfoRow => '리조트 위치·시설 정보는 샵 정보에서 관리해요.';

  @override
  String get partnerFormShopInfoCta => '샵 정보';

  @override
  String get partnerFormBasePrice => '1인 기준 가격';

  @override
  String get partnerFormBasePriceHint => '다이버 1인 기본 요금이에요.';

  @override
  String get partnerFormGuestRatesToggle => '비다이버·아동 가격을 따로 설정';

  @override
  String get partnerFormAddOption => '+ 옵션 추가';

  @override
  String get partnerFormAddIndividual => '+ 개별 상품 추가';

  @override
  String get partnerFormIndividualOptions => '이 상품의 옵션';

  @override
  String get partnerFormPreviewBadge => '게시하면 바로 공개';

  @override
  String get partnerFormSameBoatNote =>
      '같은배 빈자리는 상품 게시 후 따로 열 수 있어요. 열면 고객 화면에 바로 보여요.';

  @override
  String get partnerFormCancelPolicy => '취소·환불 규정';

  @override
  String get partnerPriceSwingTitle => '가격이 크게 바뀌었어요';

  @override
  String get partnerPriceSwingBody =>
      '기본가·옵션·비다이버·아동·전문가 가격 중 ±30% 이상 변경된 항목이 있습니다. 그대로 반영할까요?';

  @override
  String get partnerPriceSwingConfirm => '반영하기';

  @override
  String get partnerProductsTitle => '상품 관리';

  @override
  String get partnerProductMenuTitle => '상품 관리';

  @override
  String get partnerProductListTitle => '상품 목록';

  @override
  String get partnerProductMenuRegister => '상품 등록';

  @override
  String get partnerProductMenuRegisterSub => '새 상품을 올려요';

  @override
  String partnerProductMenuRegisterDrafting(int count) {
    return '새 상품을 올려요 · 작성 중 $count개';
  }

  @override
  String get partnerProductMenuList => '상품 목록';

  @override
  String get partnerProductMenuListSub => '고치거나 닫을 수 있어요';

  @override
  String partnerProductMenuListListed(int count) {
    return '게시중 $count개 · 고치거나 닫을 수 있어요';
  }

  @override
  String get partnerProductMenuSeats => '빈자리 열기';

  @override
  String get partnerProductMenuSeatsSub => '같은배 · 기본 상품만 열 수 있어요';

  @override
  String partnerProductMenuSeatsOpen(int count) {
    return '같은배 · 기본 상품만 열 수 있어요 · 열린 자리 $count석';
  }

  @override
  String get partnerProductMenuFocNote =>
      '할인과 강사 FOC는 계약서 기준으로 앱이 알아서 적용해요.\n바꾸려면 운영팀과 협의해 주세요.';

  @override
  String get partnerProductBadgeBasic => '기본 상품';

  @override
  String get partnerProductClose => '닫기';

  @override
  String get partnerProductReopen => '다시 열기';

  @override
  String get partnerProductDiscard => '폐기';

  @override
  String get partnerProductContinueDraft => '이어서 작성';

  @override
  String get partnerProductDraftHiddenHint => '작성 중 상품은 고객 화면에 보이지 않아요.';

  @override
  String get partnerProductAddOptionIndividual => '+ 옵션 · 개별 상품 추가';

  @override
  String get partnerProductListFooter =>
      '기본 상품 한 개 안에 개별 상품과 옵션이 모두 모여 있어요. 줄마다 바로 고치거나 폐기할 수 있어요.';

  @override
  String get partnerProductsEmptyH2 =>
      '아직 등록한 상품이 없어요. 첫 상품을 올리면 고객 화면에 바로 보여요.';

  @override
  String get partnerProductsEmptyCtaH2 => '첫 상품 올리기';

  @override
  String get partnerProductCloseSeatTitle => '상품을 닫을까요?';

  @override
  String partnerProductCloseSeatBody(int count) {
    return '열린 빈자리 $count석이 있어요. 닫으면 고객 화면에서 사라져요. 이미 들어온 예약과 진행 중인 결제는 그대로예요.';
  }

  @override
  String get partnerProductDiscardConfirmTitle => '이 항목을 폐기할까요?';

  @override
  String get partnerProductDiscardConfirmBody =>
      '목록에서 삭제됩니다. 예약·홀드가 있으면 삭제 대신 닫힙니다.';

  @override
  String get partnerProductDiscardClosedSnack => '예약·홀드가 있어 삭제 대신 닫았습니다.';

  @override
  String get partnerProductOptionClosedLabel => '닫힘';

  @override
  String get partnerOpenSeatsTitle => '빈자리 열기';

  @override
  String get partnerOpenSeatsEmpty => '게시 중인 기본 상품이 없어요. 먼저 상품을 게시해 주세요.';

  @override
  String get partnerOpenSeatsPickHint => '같은배에 열 기본 상품을 고르세요.';

  @override
  String get partnerSeatsOpenHint => '출발일·좌석 수·깃발 마감을 넣고 열면 고객 같은배 화면에 바로 보여요.';

  @override
  String get partnerSeatsOpenButton => '빈자리 열기';

  @override
  String get partnerSeatsOpenedSnack => '열렸어요. 고객 같은배 화면에 바로 보여요.';

  @override
  String get partnerExit => '나가기';

  @override
  String get partnerProductsGuide =>
      '저장하면 바로 탐색·같은배에 반영됩니다. 작성 중 상품은 임시 저장할 수 있어요.';

  @override
  String get partnerProductFilterAll => '전체';

  @override
  String get partnerProductsEmptyReason => '아직 등록한 상품이 없습니다.';

  @override
  String get partnerProductsEmptyNext => '상품을 등록·게시하면 이 목록에 나타납니다.';

  @override
  String get partnerProductsEmptyCta => '첫 상품 등록하기';

  @override
  String get partnerProductsFilterEmpty => '이 필터에 해당하는 상품이 없습니다.';

  @override
  String partnerProductPriceLine(String price) {
    return '기본 패키지 · 다이버 $price원';
  }

  @override
  String get partnerProductSameBoatPending => '같은배 처리 중';

  @override
  String partnerProductSameBoatLive(int seats, String date) {
    return '빈자리 $seats석 열림 · 출발 $date';
  }

  @override
  String get partnerProductSameBoatRejected => '같은배 반려';

  @override
  String get partnerProductSameBoatNotOpened => '아직 안 열림';

  @override
  String get partnerProductSeatsManage => '빈자리 관리';

  @override
  String get partnerProductResubmit => '고쳐서 다시 요청';

  @override
  String get productStatusApproved => '공개됨';

  @override
  String get productStatusRejected => '반려됨';

  @override
  String get productStatusDraft => '임시저장';

  @override
  String get partnerOwnProductsOnly => '파트너는 본인 샵 상품만 등록·수정할 수 있습니다.';

  @override
  String get partnerProductPendingHint =>
      '대기 중에도 목록에서 보고 수정할 수 있고, 같은배 신청과 여행상품 노출은 관리자 승인 후입니다.';

  @override
  String get adminPlaqueQueue => '실물 현판 발송 요청 리스트';

  @override
  String get adminPlaqueEmpty => '스타 등급을 충족한 샵이 아직 없습니다.';

  @override
  String get adminPlaqueRequest => '현판 발송 요청';

  @override
  String get adminPlaqueQueued => '발송 요청됨';

  @override
  String get adminPlaqueShipped => '발송 완료';

  @override
  String get adminPlaqueNone => '현판 대기';

  @override
  String get adminPlaqueMarkShipped => '발송 완료 처리';

  @override
  String get adminShopMonitor => '제휴 파트너 모니터';

  @override
  String get adminPricingTitle => '정산·할인';

  @override
  String get adminPricingSubtitle =>
      '일반 다이버는 소비자가, 강사는 여기서 정한 할인율 또는 정액이 적용됩니다.';

  @override
  String get adminPricingPercent => '할인율';

  @override
  String get adminPricingAmount => '할인 금액';

  @override
  String get adminPricingPercentHint => '할인율 (%)';

  @override
  String get adminPricingAmountHint => '할인 금액 (원)';

  @override
  String get adminPricingSave => '할인가 저장';

  @override
  String get adminPricingSaved => '강사 할인가가 저장되었습니다.';

  @override
  String adminPricingPreview(String consumer, String pro) {
    return '소비자가 $consumer원 → 강사 $pro원';
  }

  @override
  String get adminPostsTitle => '상품 · 그룹 투어 검증';

  @override
  String get adminPostsSubtitle => '샵 상품과 버디 모집 글을 검수하고 허위·불법 게시글을 숨기거나 삭제합니다.';

  @override
  String get adminHidePost => '숨김';

  @override
  String get adminUnhidePost => '숨김 해제';

  @override
  String get adminDeletePost => '삭제';

  @override
  String get adminEmptyPosts => '등록된 게시글이 없습니다.';

  @override
  String get adminPostTypeBuddy => '버디 모집';

  @override
  String get adminPostTypeTour => '샵 투어 상품';

  @override
  String get adminPostHidden => '숨김 처리됨';

  @override
  String get partnerTitle => '제휴파트너 모드';

  @override
  String get partnerSubtitle => '샵 정보, 투어 상품, 이번 달 예약과 정산을 한곳에서 관리합니다.';

  @override
  String get partnerAccessDenied => '제휴파트너(Business) 권한이 없는 계정입니다.';

  @override
  String get partnerHomeShopInfo => '샵 정보';

  @override
  String get partnerHomeMenuSameBoat => '같은배 좌석';

  @override
  String partnerHomeSameBoatRejectedBanner(int count) {
    return '같은배 반려 $count건 — 재신청이 필요해요';
  }

  @override
  String get partnerQuickProducts => '상품 관리';

  @override
  String get partnerQuickBookings => '예약 바우처';

  @override
  String get partnerVouchersTitle => '예약 바우처';

  @override
  String get partnerVouchersGuide => '예약이 들어오면 여기에 바로 나타나요. 승인하거나 확정할 필요는 없어요.';

  @override
  String get partnerVouchersEmpty => '이 목록에 바우처가 없어요.';

  @override
  String partnerVoucherTabArrived(int count) {
    return '도착 [$count]';
  }

  @override
  String get partnerVoucherTabPast => '지난 예약';

  @override
  String partnerVoucherTabCancelled(int count) {
    return '취소 [$count]';
  }

  @override
  String get partnerVoucherJustArrived => '방금 도착';

  @override
  String get partnerVoucherStatusAwaiting => '확정 대기';

  @override
  String get partnerVoucherStatusConfirmed => '확정됨';

  @override
  String get partnerVoucherStatusCancelled => '취소';

  @override
  String partnerVoucherTitleLine(String id, String product) {
    return '바우처 $id · $product';
  }

  @override
  String get partnerVoucherTourDate => '이용 날짜';

  @override
  String get partnerVoucherParty => '인원';

  @override
  String partnerVoucherPartyDetail(int divers, int nondivers) {
    return '다이버 $divers · 비다이버 $nondivers';
  }

  @override
  String get partnerVoucherOptions => '선택 옵션';

  @override
  String get partnerVoucherFoc => '강사 FOC';

  @override
  String get partnerVoucherGuestName => '예약자';

  @override
  String get partnerVoucherGuestNameMissing => '예약자 이름 없음';

  @override
  String get partnerVoucherRequests => '요청 사항';

  @override
  String get partnerVoucherNone => '없음';

  @override
  String partnerVoucherCreatedStamp(String time) {
    return '$time · 도착';
  }

  @override
  String get partnerVoucherAck => '확인했어요';

  @override
  String get partnerVoucherSavePrint => '바우처 저장·인쇄';

  @override
  String get partnerVoucherView => '바우처 보기';

  @override
  String get partnerVoucherCopied => '바우처 내용을 복사했어요. 붙여넣어 저장·인쇄할 수 있어요.';

  @override
  String get partnerVoucherTempConfirm => '예약 확정(임시)';

  @override
  String partnerVoucherCancelCardBody(String product, String date, int divers) {
    return '$product · $date · 고객이 취소했어요 · 다이버 $divers명';
  }

  @override
  String get partnerVoucherCancelOpsNote => '취소·환불 처리와 고객 문의는 운영팀이 맡아요.';

  @override
  String get partnerVoucherSettlementTitle => '이번 달 정산';

  @override
  String get partnerVoucherSettlementSub => '총 매출 · 수수료 · 정산 예정 금액 보기';

  @override
  String get partnerQuickStats => '통계 보기';

  @override
  String get partnerQuickDocs => '제휴 계약서';

  @override
  String get partnerQuickSettlement => '매출 정산';

  @override
  String get partnerComingSoonBody => '이 기능은 준비 중이에요. 곧 만나 보세요.';

  @override
  String get partnerBusinessHighlightTitle => 'Business Highlight (비즈니스 하이라이트)';

  @override
  String get partnerHighlightJourney => '다이버 여정';

  @override
  String get partnerHighlightBookingHits => '예약 Hits';

  @override
  String get partnerHighlightPromoHits => '프로모션 Hits';

  @override
  String get partnerHighlightEmptyMetrics => '아직 표시할 데이터가 없어요';

  @override
  String get partnerHighlightMilestoneTitle => '리조트 이정표 · 다이브스타 진행';

  @override
  String get partnerMilestoneGeneral => '일반';

  @override
  String get partnerMilestonePreReview => '심사 전';

  @override
  String get partnerMilestoneOneStar => '원스타';

  @override
  String get partnerMilestoneTwoStar => '투스타';

  @override
  String get partnerMilestoneThreeStar => '쓰리스타';

  @override
  String get partnerHighlightReviewsTitle => '리뷰 평점';

  @override
  String get partnerHighlightNoReviews => '아직 리뷰가 없어요';

  @override
  String partnerHighlightReviewCount(int count) {
    return '리뷰 $count개';
  }

  @override
  String get partnerShopEdit => '샵 정보 수정';

  @override
  String get partnerShopEditHint => '이름, 위치, 기본 상품과 두 가지 가격을 저장합니다.';

  @override
  String get partnerProductForm => '상품 등록';

  @override
  String get partnerProductFormHint => '일반 소비자가와 강사 우대 특가를 따로 입력하세요.';

  @override
  String get partnerSettlementTitle => '이번 달 정산 예정';

  @override
  String get partnerCommissionRange => '플랫폼 수수료 10~15%(기본 12%)를 제외한 금액입니다.';

  @override
  String get partnerGross => '예약 매출';

  @override
  String get partnerFee => '수수료';

  @override
  String get partnerNet => '정산 예정';

  @override
  String get partnerStatsPeriodWeek => '이번 주';

  @override
  String get partnerStatsPeriodMonth => '이번 달';

  @override
  String get partnerStatsPeriodThreeMonths => '3개월';

  @override
  String get partnerStatsAnchorVisit => '방문';

  @override
  String get partnerStatsAnchorAudience => '방문자';

  @override
  String get partnerStatsAnchorDwell => '체류';

  @override
  String get partnerStatsAnchorStrike => '스트라이크율';

  @override
  String get partnerStatsAnchorResult => '결과';

  @override
  String get partnerStatsCatInApp => '앱 안에서 일어난 일';

  @override
  String get partnerStatsCatResults => '예약으로 이어진 결과';

  @override
  String get partnerStatsSecVisit => '앱 방문';

  @override
  String get partnerStatsSecAudience => '누가 보고 가나요';

  @override
  String get partnerStatsSecDwell => '얼마나 머무나요';

  @override
  String get partnerStatsSecStrike => '스트라이크율';

  @override
  String get partnerStatsSecJourney => '다이버 여정';

  @override
  String get partnerStatsSecProducts => '상품별 예약';

  @override
  String get partnerStatsSecPromo => '프로모션 효과';

  @override
  String get partnerStatsKpiAppVisits => '앱 방문';

  @override
  String get partnerStatsKpiProductViews => '내 상품을 본 사람';

  @override
  String get partnerStatsCmpAppAvg => '앱 평균';

  @override
  String get partnerStatsCmpPeers => '동종 샵';

  @override
  String get partnerStatsFunnelDetail => '상세 조회';

  @override
  String get partnerStatsFunnelInterest => '관심';

  @override
  String get partnerStatsFunnelAttempt => '예약 시도';

  @override
  String get partnerStatsFunnelPaid => '결제 완료';

  @override
  String get partnerStatsCollecting => '데이터 모으는 중';

  @override
  String get partnerStatsProductsEmpty => '이 기간에 집계할 예약이 없어요';

  @override
  String get partnerStatsColProduct => '상품';

  @override
  String get partnerStatsColBookings => '예약';

  @override
  String get partnerStatsColGuests => '인원';

  @override
  String get partnerStatsColChange => '전기간 대비';

  @override
  String get partnerStatsPrivacyNote => '개인을 식별할 수 없는 집계만 보여 줍니다.';

  @override
  String get partnerSettlementSimPayNote =>
      '지금은 모의결제(SimPay) 기준 금액입니다. 실결제 연동 후 정산액이 확정됩니다.';

  @override
  String partnerSettlementMonthLabel(int year, int month) {
    return '$year년 $month월';
  }

  @override
  String get partnerSettlementByReceiveDate => '예약 접수일 기준';

  @override
  String get partnerSettlementValidCount => '유효 예약';

  @override
  String get partnerSettlementCancelledCount => '취소 건수';

  @override
  String partnerSettlementCountValue(int count) {
    return '$count건';
  }

  @override
  String get partnerSettlementGross => '총 예약금액';

  @override
  String get partnerSettlementRefunds => '환불 금액';

  @override
  String get partnerSettlementNet => '순매출';

  @override
  String get partnerSettlementFeePending => '계약 조건 연동 예정';

  @override
  String get partnerSettlementRateMissing => '수수료율 미입력';

  @override
  String partnerStatsDwellLine(int total, int average) {
    return '총 $total분 · 평균 $average분';
  }

  @override
  String get partnerStatsStrikeNoViews => '상품 조회가 없습니다';

  @override
  String get partnerSettlementListTitle => '예약 내역';

  @override
  String get partnerSettlementEmpty => '이 달에 접수된 결제 완료 예약이 없어요';

  @override
  String get partnerBookingsTitle => '실시간 예약 현황';

  @override
  String get partnerNoBookings => '이번 샵으로 들어온 예약이 없습니다.';

  @override
  String get partnerShopName => '샵 이름';

  @override
  String get partnerShopLocation => '위치';

  @override
  String get partnerDefaultProduct => '상품명';

  @override
  String get partnerSave => '저장';

  @override
  String get translateAction => '🌐 번역 보기';

  @override
  String get translateLoading => '번역 중…';

  @override
  String get translateShowOriginal => '원문 보기';

  @override
  String get communityCompose => '깃발 올리기';

  @override
  String get communityPostTitle => '한 줄 의도';

  @override
  String get communityPostBody => '이 배에 타고 싶은 이유';

  @override
  String get communityPostSubmit => '명부에 올리기';

  @override
  String get communityComments => '승선 메모';

  @override
  String get communityNoComments => '아직 깃발이 없습니다.';

  @override
  String get communityCommentHint => '짧게 남기세요';

  @override
  String get communityTideKicker => '출발 보드';

  @override
  String get communityTideHeadline => '같은배 동승하기';

  @override
  String get communityTideBody =>
      '팀이 있는 상품만 같은 기간에 빈자리를 엽니다. 빈자리를 열지 않은 상품은 탐색에만 있습니다.';

  @override
  String get communityTideSafety =>
      '물속 버디는 샵이 배정합니다. 이 탭은 이미 예약한 여행의 밴·식탁·침대를 나눕니다.';

  @override
  String get communityStatOpenSeats => '빈자리';

  @override
  String communityUrgentBanner(int count) {
    return '마감 임박 $count건 · 바로 보기';
  }

  @override
  String get communityBoardList => '출발 명부';

  @override
  String get communityBoardListHint => '새로 올라온 순입니다. 빈자리를 잡으면 예약으로 이어집니다.';

  @override
  String get communitySameBoatResults => '종료된 빈자리';

  @override
  String get communitySameBoatResultDeparted => '출발 종료';

  @override
  String get communitySameBoatResultSoldOut => '매진';

  @override
  String get communitySameBoatResultClosed => '마감';

  @override
  String get communityViewSeats => '자리 보기';

  @override
  String get communityWindowOpen => '일정 미정';

  @override
  String get communityPlantFlag => '깃발 꽂기';

  @override
  String get communityFlagButton => '🚩 깃발 꽂기';

  @override
  String get communityFlagPlantAndPay => '🚩 깃발 꽂고 결제하러 가기';

  @override
  String get staffCannotBuy => '제휴파트너·관리자 계정은 구매할 수 없어요. 개인 회원으로 가입해 주세요';

  @override
  String get communitySeeProduct => '상품 자세히 보기';

  @override
  String communityFlagPartyTotal(String amount) {
    return '합계 $amount';
  }

  @override
  String get communityFlagOneSeat =>
      '깃발을 꽂을 인원만큼 결제시한까지 좌석이 잠깁니다. 결제 화면에서 인원은 바꿀 수 없습니다.';

  @override
  String communityFlagPartyAsk(int open) {
    return '몇 자리를 잠글까요? (빈자리 $open)';
  }

  @override
  String communityFlagPartyLocked(int count) {
    return '깃발로 잠근 $count자리 — 결제시한까지 우선권';
  }

  @override
  String get communityPlantFlagAsk => '이 예약을 같은배에 올려 지인이나 동호회가 조인하게 할까요?';

  @override
  String get communityPlantFlagLater => '나중에';

  @override
  String get communityNeedBooking => '깃발은 예약한 뒤에 꽂습니다. 여행상품에서 리조트를 먼저 고르세요.';

  @override
  String get communityRoomOpened => '예약한 여행에 방을 열었습니다.';

  @override
  String get exploreChooseRoom => '이 리조트의 상품';

  @override
  String get exploreChooseRoomHint => '호텔에서 객실을 고르듯, 원하는 다이브 상품을 고르세요.';

  @override
  String get exploreResortTraits => '편의시설 · 특징';

  @override
  String get exploreAmenitiesHint => '쉼표로 구분 (예: Wi-Fi, 수영장, 나이트록스, 공항 픽업)';

  @override
  String get exploreRecommended => '추천';

  @override
  String get exploreLightest => '가벼운 일정';

  @override
  String exploreProductRooms(int count) {
    return '이 상품에 열린 방 $count';
  }

  @override
  String get exploreResortIntro => '리조트 소개';

  @override
  String get exploreResortMap => 'LOCATION';

  @override
  String get exploreOpenMap => '지도 열기';

  @override
  String get exploreAccessRoutes => '오시는 길';

  @override
  String get exploreResortFeatures => '리조트 특징';

  @override
  String get exploreNearbySpots => '주변 관광';

  @override
  String get exploreOpsHours => '운영 안내';

  @override
  String get exploreCheckInLabel => '체크인';

  @override
  String get exploreCheckOutLabel => '체크아웃';

  @override
  String get exploreBusinessHoursLabel => '영업시간';

  @override
  String get exploreResortAddress => '주소';

  @override
  String get exploreEditResort => '리조트 글 수정';

  @override
  String get exploreDeskHint =>
      '현지 샵과 관리자가 같은 글을 고칩니다. 저장하면 여행상품 상세에 바로 반영됩니다.';

  @override
  String exploreOpenRooms(int count) {
    return '열린 방 $count';
  }

  @override
  String get exploreProductDuration => '소요 시간';

  @override
  String get exploreProductBlurb => '상품 한 줄 소개';

  @override
  String get exploreCoverPhoto => '대표 이미지';

  @override
  String get exploreCoverPhotoHint =>
      'Booking.com·아고다처럼 큰 대표컷 + 작은 사진 격자로 보여 줍니다. 첫 장이 대표 이미지입니다.';

  @override
  String get exploreGalleryTitle => '리조트 사진';

  @override
  String get exploreGalleryHint => '최대 30장. 첫 장이 목록·상세의 대표 사진이 됩니다.';

  @override
  String get exploreGalleryAdd => '사진 추가';

  @override
  String get exploreGalleryAddMore => '사진 더 추가';

  @override
  String get exploreGalleryEmpty => '사진을 첨부하면 아고다처럼 갤러리로 보여 줍니다.';

  @override
  String exploreGalleryCount(int count) {
    return '사진 $count장';
  }

  @override
  String get exploreGalleryViewAll => '모든 사진 보기';

  @override
  String get exploreGalleryMakeCover => '대표로';

  @override
  String get exploreSaveOk => '리조트 정보가 저장되었습니다.';

  @override
  String get exploreSaveFail => '저장에 실패했습니다. 권한과 네트워크를 확인한 뒤 다시 시도해 주세요.';

  @override
  String get exploreSaving => '저장 중…';

  @override
  String get exploreAttachPhoto => '사진 첨부';

  @override
  String get exploreUseAsCover => '이 사진을 리조트 대표 이미지로';

  @override
  String get exploreCoverRemove => '이미지 삭제';

  @override
  String get communityFilterAll => '전체';

  @override
  String get communityFilterLastCall => '마감';

  @override
  String get communityFilterSolo => '싱글';

  @override
  String get communityFilterShop => '샵';

  @override
  String get communityFilterDeparting => '출발';

  @override
  String get sameBoatSearchWhen => '언제';

  @override
  String get sameBoatSearchWhere => '어디';

  @override
  String get sameBoatSearchParty => '몇 명';

  @override
  String get sameBoatSearchBudget => '예산';

  @override
  String get sameBoatSearchMore => '더 보기';

  @override
  String get sameBoatSearchThisMonth => '이번 달';

  @override
  String get sameBoatSearchNextMonth => '다음 달';

  @override
  String get sameBoatSearchThreeMonths => '3개월 이내';

  @override
  String sameBoatSearchPartyCount(int count) {
    return '$count명';
  }

  @override
  String get sameBoatSearchPartyFivePlus => '5명+';

  @override
  String get sameBoatSearchBudget50 => '50만 이하';

  @override
  String get sameBoatSearchBudget100 => '100만 이하';

  @override
  String get sameBoatSearchBudget200 => '200만 이하';

  @override
  String get sameBoatSearchBudgetAny => '제한 없음';

  @override
  String get sameBoatSearchLastCall => '마감 임박';

  @override
  String get sameBoatSearchDeparting => '곧 출발';

  @override
  String get sameBoatSearchReset => '초기화';

  @override
  String sameBoatSearchApply(int count) {
    return '빈자리 $count개 보기';
  }

  @override
  String sameBoatSearchOpenCount(int count) {
    return '빈자리 $count개';
  }

  @override
  String get sameBoatSearchSortNewest => '새로 올라온 순';

  @override
  String get sameBoatSearchAllSeats => '전체 빈자리';

  @override
  String get sameBoatEmptyTitle => '조건에 맞는 빈자리가 아직 없어요';

  @override
  String get sameBoatEmptySave => '알림 저장';

  @override
  String get sameBoatEmptySaved => '이미 저장됨';

  @override
  String get sameBoatEmptyWiden => '조건 넓히기';

  @override
  String get sameBoatEmptyWidenHint => '이렇게 바꾸면 있어요';

  @override
  String sameBoatUnlockLine(String name) {
    return '$name 조건을 빼고 보여드려요';
  }

  @override
  String get sameBoatUnlockBudget => '예산';

  @override
  String get sameBoatUnlockParty => '인원';

  @override
  String get sameBoatUnlockWhen => '언제';

  @override
  String get sameBoatUnlockWhere => '어디';

  @override
  String get sameBoatUnlockMore => '더 보기';

  @override
  String get mySeatAlertsTitle => '내 알림';

  @override
  String get mySeatAlertsHint => '저장한 조건에 맞는 빈자리가 생기면 여기와 마이 탭에 표시돼요';

  @override
  String get mySeatAlertsEmpty => '저장한 알림이 없어요';

  @override
  String get sameBoatAlertNone => '맞는 빈자리 없음 · 자리가 나면 표시돼요';

  @override
  String sameBoatAlertMatchCount(int count) {
    return '맞는 빈자리 $count개';
  }

  @override
  String sameBoatAlertMonth(int month) {
    return '$month월';
  }

  @override
  String get communityTakeSeat => '자리 잡기';

  @override
  String communityFlagHoldAsk(String deadline) {
    return '선택한 인원만큼 $deadline까지 좌석이 잠겨 선예약 우선권이 생깁니다(가확정·주황). 그 안에 결제하면 확정(검정)되고, 마감이 지나면 자리가 다시 열립니다.';
  }

  @override
  String communityBerths(int booked, int capacity) {
    return '자리 $booked/$capacity';
  }

  @override
  String communityLooking(int count) {
    return '깃발 $count';
  }

  @override
  String communitySeatPaid(int count) {
    return '결제 $count';
  }

  @override
  String communitySeatHeld(int count) {
    return '가확정 $count';
  }

  @override
  String communitySeatOpen(int count) {
    return '빈자리 $count';
  }

  @override
  String get communityDateToday => '오늘';

  @override
  String get communityNeedSignIn => '깃발을 꽂으려면 로그인하세요.';

  @override
  String get communityFlagAlready => '이미 이 자리를 가확정했습니다.';

  @override
  String get communityFlagContinuePayAsk => '이미 깃발이 있어요. 결제를 이어갈까요?';

  @override
  String get communityFlagContinuePay => '결제 이어가기';

  @override
  String communityFlagResizeAsk(int from, int to) {
    return '기존 깃발 $from명을 $to명으로 바꿀까요?';
  }

  @override
  String get communityFlagResizeConfirm => '바꾸기';

  @override
  String get communityFlagTaken => '방금 다른 분이 먼저 잡았어요';

  @override
  String get communityFlagTooLate => '깃발 마감이 임박해 새로 꽂을 수 없습니다.';

  @override
  String get communityFlagLimitReached => '동시에 가질 수 있는 깃발은 최대 3개입니다.';

  @override
  String get communitySeatsShort => '이 옵션의 남은 자리가 부족합니다.';

  @override
  String get profileFlagCancelCta => '취소';

  @override
  String get profileFlagCancelConfirm => '이 깃발을 취소하면 자리가 바로 풀립니다. 취소할까요?';

  @override
  String get communityOfferDetail => '이 자리 내용';

  @override
  String get workbenchSeatOption => '자리를 열 옵션';

  @override
  String get workbenchSeatBase => '기본 상품';

  @override
  String communitySeatsLeft(int count) {
    return '빈자리 $count';
  }

  @override
  String get communityRaiseFlag => '이 배에 깃발';

  @override
  String get communityRaiseFlagDone => '승선 의사를 명부에 남겼습니다.';

  @override
  String get communityRaiseFlagMessage => '같은 출발에 타겠습니다. 샵 브리핑에서 뵙겠습니다.';

  @override
  String get communityOpenTrip => '이 상품 열기';

  @override
  String get communityWindowLabel => '출발 구간';

  @override
  String get communityPickShop => '탈 샵';

  @override
  String get communityEmpty => '빈자리를 연 상품이 없습니다. 일반 상품은 탐색에서 봅니다.';

  @override
  String get communityDesignPreview => '디자인 확인용';

  @override
  String get communityDesignPreviewFlag =>
      '샘플 카드예요. 제휴파트너가 빈자리를 열면 여기서 깃발을 꽂을 수 있어요';

  @override
  String get profileGuestLoginPrompt => '로그인하고 내 여행을 확인해요';

  @override
  String get communityKindShop => '샵 크루';

  @override
  String get communityKindSolo => '싱글쉐어';

  @override
  String get communityKindLast => '마감';

  @override
  String get communityFrom => 'FROM';

  @override
  String get communityTo => 'TIDE';

  @override
  String get communityManifest => '승선 명부';

  @override
  String get weatherCancel => '기상 악화 취소';

  @override
  String get weatherAdminTitle => '기상 악화 취소 권한';

  @override
  String get weatherAdminBody =>
      '해당 날짜 예약을 weather_cancelled로 바꾸고 100% 환불을 보장합니다.';

  @override
  String get weatherTourDate => '투어 날짜';

  @override
  String get weatherCancelDone => '기상 취소와 전액 환불을 반영했습니다.';

  @override
  String get weatherRefundTitle => '기상 악화로 100% 환불됩니다';

  @override
  String weatherRefundBody(String shop, String product) {
    return '$shop · $product 예약이 기상 악화로 취소되어 결제/포인트가 전액 환불됩니다.';
  }

  @override
  String get weatherRefundAck => '확인';

  @override
  String get bookingConfirmed => '예약 확정';

  @override
  String get bookingRequested => '예약 요청';

  @override
  String get bookingCancelled => '취소됨';

  @override
  String get bookingWeatherCancelled => '기상 악화 취소 · 100% 환불';

  @override
  String get bookingCancel => '예약 취소';

  @override
  String bookingCancelledRefund(int percent) {
    return '취소 · 환불 $percent%';
  }

  @override
  String get bookingPaymentUnpaid => '미결제';

  @override
  String get bookingPaymentCaptured => '결제 완료';

  @override
  String get bookingPaymentRefunded => '환불됨';

  @override
  String get bookingListEmpty => '아직 예약이 없습니다. 탐색에서 상품을 예약해 보세요.';

  @override
  String get bookingQuoteBreakdown => '요금 내역';

  @override
  String get bookingConfirmAndCapture => '확정 · 결제 완료';

  @override
  String get bookingConfirmDone => '예약을 확정하고 결제를 완료 처리했습니다.';

  @override
  String get bookingConfirmFailed => '확정할 수 없는 예약입니다.';

  @override
  String get bookingDetailCta => '상세내역';

  @override
  String get bookingDetailTitle => '예약 상세내역';

  @override
  String get bookingCreatedAt => '요청일';

  @override
  String get adminBookingsTitle => '예약';

  @override
  String get adminBookingsEmpty => '아직 집계할 예약이 없습니다.';

  @override
  String get workbenchTitle => '출항 작업대';

  @override
  String get workbenchDeckHull => '선체';

  @override
  String get workbenchDeckStory => '이야기';

  @override
  String get workbenchDeckRates => '요금';

  @override
  String get workbenchDeckOptions => '옵션';

  @override
  String get workbenchNext => '다음';

  @override
  String get workbenchNeedName => '상품 이름을 적은 뒤에 저장합니다.';

  @override
  String get workbenchNeedDiverPrice => '다이버 가격을 0보다 큰 금액으로 입력한 뒤 저장합니다.';

  @override
  String get workbenchPriceOverCap => '가격은 1억 원 이하로 입력해 주세요.';

  @override
  String workbenchPriceOverCapNamed(String name) {
    return '옵션 \'$name\'의 가격은 1억 원 이하로 입력해 주세요.';
  }

  @override
  String get workbenchUnitPriceRequired => '1인 기준 가격 (필수)';

  @override
  String get workbenchCurrencyWon => '원';

  @override
  String get workbenchGuestPreviewTitle => '고객 구매 화면 예시';

  @override
  String get workbenchGuestPreviewHint =>
      '저장되지 않는 예시입니다. 실제 인원은 고객이 구매할 때 고릅니다.';

  @override
  String get workbenchPriceRevisionPendingBanner =>
      '가격·신규 옵션 변경은 관리자 승인을 기다리는 중이에요. 그 외 수정은 이미 공개 상품에 반영되었어요.';

  @override
  String workbenchPriceRevisionRejectedBanner(String note) {
    return '관리자가 가격 변경을 반려했어요: $note';
  }

  @override
  String get workbenchPriceRevisionStaged =>
      '가격·새 옵션은 관리자 승인 뒤에 반영돼요. 나머지는 바로 반영되었어요';

  @override
  String get workbenchOptionClosedNotDeleted =>
      '예약·홀드가 있는 옵션이라 삭제 대신 예약 마감 처리했어요.';

  @override
  String get workbenchPhotoUploadFailed =>
      '사진 업로드에 실패했습니다. 연결·R2 설정을 확인한 뒤 다시 저장하세요. 상품은 저장되지 않았습니다.';

  @override
  String get workbenchPhotoLoadFailed => '사진을 불러오지 못했어요';

  @override
  String get workbenchNeedGuestPrice => '비다이버·아동 가격을 0보다 큰 금액으로 입력한 뒤 저장합니다.';

  @override
  String get workbenchNeedOptionPrice => '옵션 이름을 적었다면 가격도 0보다 크게 입력합니다.';

  @override
  String workbenchNeedOptionPriceNamed(String name) {
    return '옵션 \'$name\'의 가격을 입력하세요';
  }

  @override
  String get workbenchCategory => '분류';

  @override
  String get workbenchCatResort => '리조트';

  @override
  String get workbenchCatLiveaboard => '리브어보드';

  @override
  String get workbenchCatFun => '펀다이빙';

  @override
  String get workbenchCatCourse => '코스';

  @override
  String get workbenchCatDay => '데이 투어';

  @override
  String get workbenchHullFromShop => '선체에서 가져옴';

  @override
  String get workbenchOpenMap => '지도에서 열기';

  @override
  String get workbenchOpenSeats => '같은배에 빈자리 열기';

  @override
  String get workbenchOpenSeatsHint =>
      '이미 팀이 있는데 같은 기간에 인원을 더 뽑을 때만 켭니다. 끄면 일반 상품입니다.';

  @override
  String get workbenchSeatCount => '총 인원';

  @override
  String get workbenchDepartureDate => '출발일';

  @override
  String get workbenchFlagDeadline => '깃발 마감일';

  @override
  String get workbenchOpenSeatsNeedFields => '빈자리를 열려면 필요 인원·출발일·깃발 마감을 넣으세요.';

  @override
  String get workbenchOpenSeatsAfterApproval => '승인되면 빈자리를 열 수 있어요';

  @override
  String get sameBoatRequiredHeadcount => '출발에 필요한 인원';

  @override
  String sameBoatBookedReference(int count) {
    return '이 날짜 예약 $count명';
  }

  @override
  String sameBoatSeatsToFill(int count) {
    return '채울 자리 $count명';
  }

  @override
  String get sameBoatAlreadyBooked => '이미 모집된 인원';

  @override
  String sameBoatSeatOpenPreview(int capacity, int booked, int open) {
    return '총 $capacity칸 중 검정 $booked + 빈자리 $open';
  }

  @override
  String sameBoatCapacityBelowOccupied(int booked, int holds) {
    return '총 인원은 확정($booked)+가확정($holds)보다 작을 수 없습니다.';
  }

  @override
  String get sameBoatAskAdminToChange => '변경은 관리자에게 문의하세요.';

  @override
  String get sameBoatPendingAfterSave =>
      '같은배 노출은 관리자 승인 후입니다. (관리자 → 샵 → 같은배 모니터)';

  @override
  String get briefSectionSameBoat => '같은배 빈자리';

  @override
  String get workbenchDetail => '상세 설명';

  @override
  String get workbenchItinerary => '표준 일정표';

  @override
  String get workbenchAddDay => '일차 추가';

  @override
  String workbenchDayTitle(int day) {
    return '$day일차 제목';
  }

  @override
  String get workbenchDayBody => '내용';

  @override
  String get workbenchGuestDiver => '다이버';

  @override
  String get workbenchGuestNondiver => '비다이버';

  @override
  String get workbenchGuestChild => '소아';

  @override
  String get workbenchGuestInfant => '유아';

  @override
  String get workbenchGuestEnabled => '노출';

  @override
  String get workbenchFoc => 'FOC';

  @override
  String get workbenchFocPay => '결제 인원';

  @override
  String get workbenchFocFree => '무료 인원';

  @override
  String get workbenchBasePackage => '기본 패키지';

  @override
  String get workbenchBasePackageHint => '이야기·일정 구성이 예약 시 옵션 1로 기본 선택됩니다.';

  @override
  String get workbenchAddons => '추가 옵션 · 패키지 안에서만';

  @override
  String get workbenchIndividuals => '개별 상품 · 패키지 대신';

  @override
  String get workbenchBookable => '예약에 노출';

  @override
  String get workbenchGuestPreview => '손님 예약';

  @override
  String get briefTitle => '상품등록';

  @override
  String get briefSectionCover => '표지';

  @override
  String get briefSectionPlace => '가는 목적지 소개';

  @override
  String get briefSectionDays => '상품 상세 내역';

  @override
  String get detailComposerHint => '상품 이야기·일정·표를 한곳에서 작성하세요.';

  @override
  String get detailComposerBold => '굵게';

  @override
  String get detailComposerHeading => '제목';

  @override
  String get detailComposerList => '목록';

  @override
  String get detailComposerTable => '표 삽입';

  @override
  String get detailComposerTableSchedule => '시간 · 내용';

  @override
  String get detailComposerTableInclude => '포함 · 불포함';

  @override
  String get detailComposerDay => '일차 템플릿';

  @override
  String get detailComposerPreview => '미리보기';

  @override
  String get detailComposerEdit => '편집';

  @override
  String get briefSectionTerms => '상품 예약 들어가기';

  @override
  String get bookingEntryBasePackage => '기본 패키지';

  @override
  String get bookingEntryDiverPrice => '패키지 1인 가격(다이버)';

  @override
  String get bookingEntryHasNondivers => '비다이버가 있나요?';

  @override
  String get bookingEntryAdultNondiver => '성인 비다이버';

  @override
  String get bookingEntryChildInfant => '소아 · 유아';

  @override
  String get bookingEntryUnitPrice => '1인 가격';

  @override
  String get bookingEntryPreviewSnack => '미리보기입니다. 손님은 공개된 상품에서 결제합니다.';

  @override
  String get bookingEntryAddons => '추가 구성 옵션';

  @override
  String get bookingEntryAddOption => '옵션 추가';

  @override
  String get bookingEntryOptionName => '옵션명';

  @override
  String get bookingEntryOptionPrice => '1인 가격';

  @override
  String get bookingEntryTermsToggle => '포함 · 불포함';

  @override
  String get bookingEntryIndividuals => '개별 상품';

  @override
  String get bookingEntryIndividualsHint => '패키지 없이 교육·원데이 다이빙처럼 따로 파는 상품입니다.';

  @override
  String get bookingEntryAddIndividual => '개별 상품 추가';

  @override
  String get bookingEntryIndividualName => '개별 상품명';

  @override
  String get bookingEntryStayLength => '여행 기간';

  @override
  String bookingEntryNights(int nights) {
    return '$nights박';
  }

  @override
  String bookingEntryDays(int days) {
    return '$days일';
  }

  @override
  String get bookingEntryCheckIn => '체크인';

  @override
  String get bookingEntryCheckOut => '체크아웃';

  @override
  String get bookingEntryChangeDates => '날짜 변경';

  @override
  String get bookingEntryPickDate => '날짜 선택';

  @override
  String bookingEntryStayRange(String checkIn, String checkOut) {
    return '$checkIn – $checkOut';
  }

  @override
  String get briefSectionPrice => '가격';

  @override
  String get briefSectionSeats => '빈자리';

  @override
  String get briefSourceCatalog => '목록의 리조트';

  @override
  String get briefSourceNamed => '직접 적은 리조트';

  @override
  String get briefAddLine => '한 줄 추가';

  @override
  String get briefRemoveLine => '줄 삭제';

  @override
  String get briefOpenSeats => '이 일정에 남는 자리를 열까요?';

  @override
  String get briefFocApplies => '적용 대상';

  @override
  String get briefStartPrice => '다이버 시작 가격';

  @override
  String get briefGuestCard => '손님 카드';

  @override
  String get briefKeepEditing => '이어서 두기';

  @override
  String get briefSubmitReview => '승인 대기';

  @override
  String get briefPublishNow => '바로 공개';

  @override
  String get briefTakeDown => '내려두기';

  @override
  String get briefKept => '이어서 쓸 수 있게 저장했습니다.';

  @override
  String get briefTakenDown => '상품을 손님 화면에서 내려 두었습니다.';

  @override
  String get briefSave => '저장';

  @override
  String get briefEdit => '수정';

  @override
  String get briefStepBasics => '기본 정보';

  @override
  String get briefStepPricing => '가격·옵션';

  @override
  String get briefStepReview => '확인·제출';

  @override
  String get briefStepNext => '다음';

  @override
  String get briefStepBack => '이전';

  @override
  String get briefTempSave => '임시 저장';

  @override
  String get briefSubmit => '승인 요청';

  @override
  String get briefChecklistTitle => '제출 전 확인';

  @override
  String get briefChecklistHint => '아래를 확인한 뒤 제출해 주세요.';

  @override
  String get briefChecklistPhotos => '사진';

  @override
  String get briefChecklistCopy => '이름·소개';

  @override
  String get briefChecklistPrice => '기본 가격';

  @override
  String get briefChecklistOptions => '옵션 가격';

  @override
  String get briefChecklistIncludes => '포함·불포함';

  @override
  String get briefChecklistCancel => '취소 규정';

  @override
  String get briefShopInfoTitle => '샵·리조트 정보';

  @override
  String get briefShopInfoBody => '상호·위치·소개는 리조트 소개 화면에서 관리합니다.';

  @override
  String get briefShopInfoOpen => '리조트 소개 열기';

  @override
  String get briefSameBoatPartnerHint =>
      '같은배 빈자리는 상품을 게시한 뒤, 상품 관리에서 바로 열 수 있어요.';

  @override
  String get briefTempSaveNeedPhoto => '사진을 한 장 이상 넣어 주세요.';

  @override
  String get briefTempSaveNeedPrice => '기본 가격을 0원보다 크게 입력해 주세요.';

  @override
  String get briefLeaveTitle => '저장하지 않고 나갈까요?';

  @override
  String get briefLeaveBody => '수정한 내용이 아직 저장되지 않았어요.';

  @override
  String get briefLeaveTempSave => '임시 저장하고 나가기';

  @override
  String get briefLeaveDiscard => '저장하지 않고 나가기';

  @override
  String get briefLeaveStay => '계속 작성';

  @override
  String get briefViewModeHint => '수정을 누르면 편집할 수 있습니다.';

  @override
  String get adminProductDelete => '삭제';

  @override
  String adminProductDeleteBody(String name) {
    return '「$name」을 삭제하면 상품 목록에서 빠집니다.';
  }

  @override
  String get adminProductDeleted => '상품을 삭제했습니다.';

  @override
  String get adminProductRejectNote => '반려 사유';

  @override
  String get adminProductRejectNoteHint => '파트너에게 보이는 이유를 적습니다.';

  @override
  String get checkoutStepSelect => '예약 선택';

  @override
  String get checkoutStepReview => '예약한 사항';

  @override
  String get checkoutStepPay => '구매';

  @override
  String get checkoutReviewCta => '예약 내역 보기';

  @override
  String get checkoutReviewDetailHint => '아래 내용을 확인한 뒤 수정하거나 예약을 확정하세요.';

  @override
  String get checkoutBack => '이전으로';

  @override
  String get checkoutEditBooking => '예약수정(변경)하기';

  @override
  String get checkoutConfirm => '예약 확정';

  @override
  String get checkoutNeedChoice => '기본 패키지 또는 개별 상품을 선택하세요.';

  @override
  String get checkoutGuests => '인원';

  @override
  String get checkoutPackageOn => '기본 패키지';

  @override
  String checkoutTotal(String amount) {
    return '합계 $amount원';
  }

  @override
  String checkoutFocLine(int pay, int free, int count) {
    return 'FOC $pay+$free · 다이버 무료 $count명';
  }

  @override
  String checkoutGuestsBelowMin(int min) {
    return '이 상품은 최소 $min명이 필요합니다.';
  }

  @override
  String checkoutGuestsAboveMax(int max) {
    return '이 상품은 최대 $max명까지 예약할 수 있습니다.';
  }

  @override
  String get checkoutSignInRequired => '예약을 완료하려면 로그인해 주세요.';

  @override
  String bookingPartySummary(int diver, int nondiver, int child, int infant) {
    return '다이버 $diver · 비다이버 $nondiver · 아동 $child · 유아 $infant';
  }

  @override
  String get adminOverviewBasis => '접수일 기준 · 순매출 = 결제 총액 − 환불';

  @override
  String get adminOverviewTodayBookings => '오늘 예약';

  @override
  String get adminOverviewTodayPaid => '오늘 결제 금액';

  @override
  String get adminOverviewTodayCancel => '오늘 취소·환불';

  @override
  String get adminOverviewMonthSales => '이번 달 매출';

  @override
  String get adminOverviewVsYesterday => '어제보다';

  @override
  String get adminOverviewSameAsYesterday => '어제와 같음';

  @override
  String get adminOverviewVsMonth => '전월 대비';

  @override
  String get adminOverviewVsYear => '전년 동월 대비';

  @override
  String get adminOverviewNoCompare => '비교 데이터 없음';

  @override
  String get adminOverviewQueueTitle => '처리 대기';

  @override
  String get adminOverviewQueueCertify => '강사 인증';

  @override
  String get adminOverviewQueueSign => '서명 대기';

  @override
  String get adminOverviewQueueDiveStar => '다이브스타 심사';

  @override
  String get adminOverviewQueueProposal => '파트너 제안';

  @override
  String get adminOverviewQueueApply => '승격 신청';

  @override
  String get adminOverviewQueueProducts => '상품 검증';

  @override
  String get adminOverviewComingSoon => '준비 중';

  @override
  String get adminOverviewChart14 => '최근 14일 매출';

  @override
  String get adminOverviewChart30 => '일별 매출 · 최근 30일';

  @override
  String get adminOverviewPriorYear => '전년 동기';

  @override
  String get adminOverviewLive => '예약 · 결제 실시간';

  @override
  String get adminOverviewSeeAll => '전체 보기';

  @override
  String get adminOverviewLiveEmpty => '최근 예약이 없습니다.';

  @override
  String get adminOverviewActivity => '변동사항';

  @override
  String get adminOverviewActivityEmpty => '최근 변동이 없습니다.';

  @override
  String get adminOverviewActivityGap => '가격 변경, 좌석 변경은 준비 중입니다.';

  @override
  String get adminOverviewChangeConsumer => '소비자가';

  @override
  String get adminOverviewChangePro => '프로가';

  @override
  String get adminOverviewChangeCapacity => '좌석';

  @override
  String adminOverviewChangeLine(
    String name,
    String label,
    int before,
    int after,
  ) {
    return '$name $label $before→$after';
  }

  @override
  String get adminOverviewPaid => '결제완료';

  @override
  String get adminOverviewCancelled => '취소';

  @override
  String get adminOverviewPartial => '부분환불';

  @override
  String get adminOverviewNoName => '이름 없음';

  @override
  String get adminOverviewJoin => '가입';

  @override
  String get adminOverviewRefund => '환불';

  @override
  String get adminOverviewSigned => '서명';

  @override
  String get adminOverviewApplied => '심사 신청';

  @override
  String get adminOverviewCancelSpike => '오늘 취소가 최근 28일 하루 평균의 2배 이상입니다.';

  @override
  String get adminOverviewWeekDrop => '이번 주 매출이 지난주보다 30% 이상 낮은 파트너';

  @override
  String get adminOverviewMoreThanUsual => '평소보다 많음';

  @override
  String get adminOverviewCountUnit => '건';

  @override
  String get adminSalesGross => '총 결제';

  @override
  String get adminSalesRefund => '환불';

  @override
  String get adminSalesNet => '순매출';

  @override
  String get adminSalesAverage => '평균 결제액';

  @override
  String get adminSalesActivePartners => '활성 파트너';

  @override
  String get adminSalesActiveHint => '이 기간에 예약이 있음';

  @override
  String get adminSalesPresetToday => '오늘';

  @override
  String get adminSalesPresetWeek => '이번 주';

  @override
  String get adminSalesPresetMonth => '이번 달';

  @override
  String get adminSalesPresetQuarter => '3개월';

  @override
  String get adminSalesPresetCustom => '직접 지정';

  @override
  String get adminSalesComparePrev => '전월';

  @override
  String get adminSalesCompareYear => '전년 동기';

  @override
  String get adminSalesPartners => '파트너별 성과';

  @override
  String get adminSalesColRank => '#';

  @override
  String get adminSalesColPartner => '파트너';

  @override
  String get adminSalesColBookings => '예약';

  @override
  String get adminSalesColGross => '총액';

  @override
  String get adminSalesColRefund => '환불';

  @override
  String get adminSalesColNet => '순매출';

  @override
  String get adminSalesColDelta => '대비';

  @override
  String get adminSalesColCancel => '취소율';

  @override
  String get adminSalesColShare => '비중';

  @override
  String get adminSalesTotalRow => '합계';

  @override
  String get adminSalesCategory => '카테고리별 순매출 비중';

  @override
  String get adminSalesCatTour => '투어·리브어보드';

  @override
  String get adminSalesCatCourse => '교육';

  @override
  String get adminSalesCatFun => '체험 다이빙';

  @override
  String get adminSalesCatFlag => '갈은배';

  @override
  String get adminSalesCatUnknown => '분류 없음';

  @override
  String get adminSalesTop => '상품 순위 TOP 5';

  @override
  String get adminSalesBasis => '접수일 기준 · 순매출 = 총 결제 − 환불';

  @override
  String get adminSalesEmpty => '이 기간의 예약이 없습니다.';

  @override
  String get adminSalesClamped => '기간은 최대 12개월까지입니다.';

  @override
  String get adminSalesNew => '신규';

  @override
  String get adminSalesMine => '내 샵';

  @override
  String get adminSalesOpenContract => '계약 보관함';

  @override
  String get adminSalesOpenDocs => '서류함';

  @override
  String get adminSalesOpenPartners => '파트너 명단';

  @override
  String get adminSalesRowHint => '행을 누르면 계약 · 서류함 · 파트너 명단으로 이동합니다.';

  @override
  String get adminStatsPresetWeek => '이번 주';

  @override
  String get adminStatsPresetMonth => '이번 달';

  @override
  String get adminStatsPresetQuarter => '3개월';

  @override
  String get adminStatsPresetYear => '올해';

  @override
  String get adminStatsFlow => '매출 흐름';

  @override
  String get adminStatsFlowHint => '일별 · 전년 동기 비교';

  @override
  String get adminStatsWho => '누가 사나';

  @override
  String get adminStatsWhat => '무엇이 팔리나';

  @override
  String get adminStatsResort => '리조트 순위';

  @override
  String get adminStatsOptions => '옵션별 선택 비율';

  @override
  String get adminStatsOptionsHint => '옵션을 그룹으로 나누면 더 자세히 볼 수 있어요';

  @override
  String get adminStatsMost => '가장 많이 선택한 옵션';

  @override
  String get adminStatsPartner => '파트너 성과';

  @override
  String get adminStatsPartnerHint => '순매출 × 취소율';

  @override
  String get adminStatsCancel => '취소·환불';

  @override
  String get adminStatsCancelHint => '월별 취소 건수';

  @override
  String get adminStatsTopCancel => '취소가 많은 상품';

  @override
  String get adminStatsDiveStar => '다이브스타';

  @override
  String get adminStatsDiveNote => '심사 전은 최근 신청 50건 기준입니다.';

  @override
  String get adminStatsLead => '예약 시점';

  @override
  String get adminStatsLeadHint => '출발 며칠 전에 예약하나';

  @override
  String get adminStatsLeadNote => '출발일이 비어 접수일로 저장된 건은 당일에 섞일 수 있습니다.';

  @override
  String get adminStatsSeason => '시즌';

  @override
  String get adminStatsSeasonHint => '월별 예약 수';

  @override
  String get adminStatsGathering => '데이터 모으는 중';

  @override
  String get adminStatsCountry => '국가';

  @override
  String get adminStatsCountryUnknown => '미입력';

  @override
  String get adminStatsReturn => '재구매';

  @override
  String get adminStatsBuyerNote => '재구매는 지금 누적 구매 수로 구분합니다.';

  @override
  String get adminStatsGradeUnknown => '등급 없음';

  @override
  String get adminStatsBasis => '접수일 기준 · 그래프 위에 마우스를 올리면 숫자가 나와요';

  @override
  String get adminStatsLead0 => '당일';

  @override
  String get adminStatsLead3 => '3일';

  @override
  String get adminStatsLead7 => '7일';

  @override
  String get adminStatsLead14 => '14일';

  @override
  String get adminStatsLead30 => '30일';

  @override
  String get adminStatsLead30p => '30일+';

  @override
  String get adminReportMake => '보고서 만들기';

  @override
  String get adminReportPrint => '인쇄 · PDF';

  @override
  String get adminReportSettings => '보고서 설정';

  @override
  String get adminReportPeriod => '기간';

  @override
  String get adminReportPeriodMonth => '월';

  @override
  String get adminReportPeriodQuarter => '분기';

  @override
  String get adminReportPeriodYear => '연';

  @override
  String get adminReportPeriodCustom => '직접';

  @override
  String get adminReportCompare => '비교 기준';

  @override
  String get adminReportCompareNone => '없음';

  @override
  String get adminReportCategories => '카테고리';

  @override
  String get adminReportPartners => '파트너';

  @override
  String get adminReportProducts => '품목(상품)';

  @override
  String get adminReportAll => '전체';

  @override
  String get adminReportInclude => '포함할 내용';

  @override
  String get adminReportSummary => '요약 숫자';

  @override
  String get adminReportTrend => '매출 추이';

  @override
  String get adminReportPartnerTable => '파트너별 표';

  @override
  String get adminReportProductRank => '상품 순위';

  @override
  String get adminReportOptions => '옵션 선택 현황';

  @override
  String get adminReportCancels => '취소·환불';

  @override
  String get adminReportBasis => '계산 기준 설명';

  @override
  String get adminReportEmpty => '보고서 만들기를 누르면 미리보기가 채워집니다.';

  @override
  String get adminReportHeading => '경영보고서';

  @override
  String get adminReportBasisBody =>
      '계산 기준: 접수일. 총 결제는 결제된 건 전체(이후 취소 포함)이고, 환불은 취소·기상취소의 환불액입니다. 순매출 = 총 결제 − 환불. 지금은 모의결제(SimPay) 기간입니다.';

  @override
  String get adminReportFontLicense =>
      'Noto Sans KR는 SIL Open Font License(OFL)입니다.';

  @override
  String get adminReportPrinting => 'PDF를 준비하고 있습니다.';

  @override
  String get partnerApplyTitle => '제휴 신청';

  @override
  String get partnerApplyShop => '리조트·샵 이름';

  @override
  String get partnerApplyContact => '담당자 이름';

  @override
  String get partnerApplyPhone => '연락처';

  @override
  String get partnerApplyRegion => '지역';

  @override
  String get partnerApplyIntro => '한 줄 소개';

  @override
  String get partnerApplyLink => '홈페이지/SNS (선택)';

  @override
  String get partnerApplyConsent => '개인정보 수집·이용에 동의합니다';

  @override
  String get partnerApplySend => '신청 보내기';

  @override
  String get partnerApplySent => '신청이 접수됐어요';

  @override
  String get partnerApplyCopy => '복사';

  @override
  String get partnerApplyBadField => '칸을 채워 주세요';

  @override
  String get partnerApplyBadLink => '링크는 200자 안으로 적어 주세요';

  @override
  String get partnerApplyNeedConsent => '동의한 뒤에 보낼 수 있어요';

  @override
  String get adminApplyEmpty => '도착한 신청이 없어요.';

  @override
  String get adminApplyNew => '새 신청';

  @override
  String get adminApplyHandled => '처리함';

  @override
  String get adminApplyMark => '처리함으로 표시';

  @override
  String get adminApplyOpenMember => '이 회원 보기';

  @override
  String refundPolicyHint(int percent) {
    return '지금 취소 시 환불 $percent%';
  }
}
