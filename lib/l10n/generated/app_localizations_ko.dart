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
  String get homeDiveStarTitle => 'Dive Star 추천 리조트';

  @override
  String get homeFavoritesTitle => '즐겨 찾는 곳';

  @override
  String get homePopularTitle => '많이 가는 곳';

  @override
  String get homeSeeAll => '더보기';

  @override
  String get homeFavoritesEmpty => '하트를 누르거나 로그를 남기면 단골 리조트가 여기에 모여요.';

  @override
  String get homeChipAll => '전체';

  @override
  String get homeChipRecommended => '추천';

  @override
  String get homeChipFavorites => '즐겨찾기';

  @override
  String get homeChipPopular => '인기';

  @override
  String get homeChipLastMinute => '마감임박';

  @override
  String get homeNextDepartures => '이번 출발';

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
  String get exploreProBanner => '강사 자격 확인됨 · 모든 상품이 강사 우대가로 표시됩니다';

  @override
  String get exploreConsumerBanner => '일반 다이버 가격 · 자리를 요청하면 샵 확정 후 결제합니다';

  @override
  String get exploreBook => '예약하기';

  @override
  String get explorePay => '자리 요청';

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
  String exploreCheckoutDone(String label, String price) {
    return '$label $price원 자리 요청을 샵에 전달했습니다.';
  }

  @override
  String get exploreConsumerPayHint => '샵이 등록한 정상 소비자가입니다.';

  @override
  String get exploreNoResults => '검색과 일치하는 샵이 없습니다.';

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
  String get reviewTitle => '오퍼레이션 리뷰';

  @override
  String get reviewIntro => '다녀온 샵의 안전·가이드·보트를 평가하면 Dive Star가 다시 계산됩니다.';

  @override
  String get reviewShopLabel => '리조트 / 다이브샵';

  @override
  String get reviewSafety => '① 안전 및 장비 관리';

  @override
  String get reviewGuide => '② 가이드 전문성';

  @override
  String get reviewBoat => '③ 보트 및 편의시설';

  @override
  String get reviewComment => '한 줄 후기 (선택)';

  @override
  String get reviewSubmit => '리뷰 등록';

  @override
  String get reviewWrite => '리뷰 작성';

  @override
  String get reviewDone => '리뷰 완료';

  @override
  String get reviewSaved => '리뷰가 반영되었습니다. Dive Star가 갱신됩니다.';

  @override
  String get reviewSaveFailed => '리뷰 저장에 실패했습니다.';

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
  String get authWelcome =>
      '가입하면 로그, 같은배, 예약 등 기본 기능을 바로 쓸 수 있습니다. 등급은 활동에 따라 관리자가 조정합니다.';

  @override
  String get authEmail => '이메일';

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
  String get authErrorInvalidCredential =>
      '이미 가입된 이메일입니다. 처음 만든 비밀번호로 로그인해 주세요.';

  @override
  String get authResetPassword => '비밀번호 재설정 메일 보내기';

  @override
  String get authResetPasswordSent => '비밀번호 재설정 메일을 보냈습니다. Gmail 받은편지함을 확인하세요.';

  @override
  String get authErrorEmailInUse => '이미 가입된 이메일입니다.';

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
  String get adminTabCertify => '인증';

  @override
  String get adminTabShops => '샵';

  @override
  String get adminTabOps => '운영';

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
  String get adminMembersSubtitle => '회원을 조회하고 회원·특별회원·VIP·강사회원 등급을 조정합니다.';

  @override
  String get adminMembersSearch => '이름 또는 이메일 검색';

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
  String get memberGradeMember => '회원';

  @override
  String get memberGradeSpecial => '특별회원';

  @override
  String get memberGradeVip => 'VIP';

  @override
  String get memberGradeInstructor => '강사회원';

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
  String get adminReject => '거절';

  @override
  String get adminNoPending => '대기 중인 자격증 신청이 없습니다.';

  @override
  String get adminShopsTitle => '다이브 스타 · 제휴 샵';

  @override
  String get adminShopsSubtitle => '오퍼레이션 평점과 스타 등급, 실물 현판 발송을 모니터링합니다.';

  @override
  String get adminProductsTitle => '여행상품 등록';

  @override
  String get adminProductsSubtitle =>
      '상품 종류를 고르고 등록하면, 최종 공개는 승인 결재 후에만 반영됩니다.';

  @override
  String get adminProductsTab => '상품 등록';

  @override
  String get adminProductPendingQueue => '승인 대기 상품';

  @override
  String get adminProductPendingEmpty => '승인 대기 중인 상품이 없습니다.';

  @override
  String get adminProductApproved => '상품이 승인되어 공개되었습니다.';

  @override
  String get adminProductRejected => '상품 등록이 거절되었습니다.';

  @override
  String get adminProductSubmitHint =>
      '저장하면 승인 대기열로 올라갑니다. 최종 노출은 관리자 승인 후입니다.';

  @override
  String get adminProductSubmitted => '승인 요청이 접수되었습니다.';

  @override
  String get productListingKind => '상품 종류 (노출 위치)';

  @override
  String get productListingDiveStar => 'Dive Star 추천';

  @override
  String get productListingFavorites => '즐겨찾는 곳';

  @override
  String get productListingPopular => '많이 가는 곳';

  @override
  String get productListingNextDeparture => '이번 출발';

  @override
  String get productListingCurated => '기획 상품';

  @override
  String get productStatusPending => '승인 대기';

  @override
  String get productStatusApproved => '공개됨';

  @override
  String get productStatusRejected => '거절됨';

  @override
  String get productStatusDraft => '임시저장';

  @override
  String get partnerOwnProductsOnly => '파트너는 본인 샵 상품만 등록·수정할 수 있습니다.';

  @override
  String get partnerProductPendingHint => '등록 후 관리자 승인이 완료되면 여행상품에 노출됩니다.';

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
  String get adminShopMonitor => '전 세계 제휴 샵 모니터링';

  @override
  String get adminPricingTitle => '강사 할인가';

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
  String get partnerTitle => '파트너 모드';

  @override
  String get partnerSubtitle => '샵 정보, 투어 상품, 이번 달 예약과 정산을 한곳에서 관리합니다.';

  @override
  String get partnerAccessDenied => '파트너(Business) 권한이 없는 계정입니다.';

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
  String get communityTideHeadline => '이번 주, 빈자리가 열린 배';

  @override
  String get communityTideBody => '목적지·날짜·빈자리만 보고 고르세요. 물속 버디는 샵이 배정합니다.';

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
  String get communityBoardListHint => '카드를 누르면 승선 의사와 예약을 이어갈 수 있습니다.';

  @override
  String get communityViewSeats => '자리 보기';

  @override
  String get communityWindowOpen => '일정 미정';

  @override
  String get communityPlantFlag => '깃발 꽂기';

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
  String get exploreGalleryHint => '최대 12장. 첫 장이 목록·상세의 대표 사진이 됩니다.';

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
  String communityBerths(int booked, int capacity) {
    return '자리 $booked/$capacity';
  }

  @override
  String communityLooking(int count) {
    return '깃발 $count';
  }

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
  String get communityEmpty => '아직 떠 있는 밀물이 없습니다.';

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
  String refundPolicyHint(int percent) {
    return '지금 취소 시 환불 $percent%';
  }
}
