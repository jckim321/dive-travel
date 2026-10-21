// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '潜水旅行';

  @override
  String get homeWelcome => '你的海洋拓展到多远了？';

  @override
  String get homeSubtitle => '把全世界的海放进掌心。';

  @override
  String get homeProWelcome => '你好，PRO 教练！';

  @override
  String get homeMapTitle => '我的全球海洋开拓地图';

  @override
  String homeMapExplored(int count) {
    return '目前已探索 $count 个地区';
  }

  @override
  String get homeMapTip => '同一地区的潜水次数增加后，霓虹会变成金色。';

  @override
  String get homeDiveStarTitle => '本月 Dive Star 推荐度假村';

  @override
  String get homeDiveStarShelfHint => '다이버가 직접 검증한 리조트';

  @override
  String get homeFavoritesTitle => '내가 만드는 찐 여행';

  @override
  String get homeDiverPlannedSubtitle => '다이버가 직접 꾸민 진짜 일정';

  @override
  String get homePopularTitle => '지금 뜨는 스팟';

  @override
  String get homeHotSpotSubtitle => '다이버들이 몰리는 핫 다이빙';

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
  String get homeChipPopular => '인기';

  @override
  String get homeChipLastMinute => '마감임박';

  @override
  String get homeNextDepartures => '本班出发';

  @override
  String get homeLastMinuteTitle => '即将截止的社交团游';

  @override
  String get homeLastMinuteCrew => '다합 사흘 소셜 크루';

  @override
  String get homeLastMinuteSeat => '내일 마감 · 남은 자리 1명 · 싱글차지 없음';

  @override
  String get homeForYouTitle => '为你推荐的下一片海';

  @override
  String get homeStyleFirstOcean => '正在打开第一片海的潜水员';

  @override
  String get homeStyleFirstOceanBody => '还没有印章。从亚洲开始，日志和行程就能连上。';

  @override
  String get homeStyleHomeContinent => '深耕一片海的潜水员';

  @override
  String get homeStyleHomeContinentBody => '你已有常去的海。下一站打开另一大洲，把地图变宽。';

  @override
  String get homeStyleCollector => '收集大洋的探险者';

  @override
  String get homeStyleCollectorBody => '已经踏过多个大洲。把空白印章填满吧。';

  @override
  String get homeStyleDeepLocal => '反复深潜同一点的潜水员';

  @override
  String get homeStyleDeepLocalBody => '重复潜水让该区域变成金色。下一步扩大视野。';

  @override
  String get homeStylePro => '职业路线教练';

  @override
  String get homeStyleProBody => '用优惠价打开新的大洲，把教学和探索一起积累。';

  @override
  String get homeNextOceanTitle => '下一片要打开的海';

  @override
  String homeNextOceanBody(String continent) {
    return '$continent还没有日志。从这趟行程开始。';
  }

  @override
  String homeOpenShop(String name) {
    return '查看 $name';
  }

  @override
  String get homeStampsLabel => '护照印章';

  @override
  String homeStampsProgress(int stamped, int total) {
    return '$stamped/$total 大洲';
  }

  @override
  String get homeBadgeLabel => '下一枚徽章';

  @override
  String homeBadgeLeft(int count) {
    return '距金属卡还差 $count 潜次';
  }

  @override
  String get homeBadgeDone => '可申请金属卡';

  @override
  String get homeChecklistLabel => '出发检查';

  @override
  String homeChecklistSoon(int days, String shop) {
    return '$days 天 · $shop';
  }

  @override
  String get homeChecklistIdle => '打开装备清单';

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
  String get profilePassportHint => '有日志的大洲会盖上印章。';

  @override
  String get navHome => '首页';

  @override
  String get navLogbook => '日志';

  @override
  String get navExplore => '行程预订';

  @override
  String get navCommunity => '同船';

  @override
  String get navProfile => '我的';

  @override
  String get logbookTitle => '数字潜水日志';

  @override
  String get logbookAdd => '添加日志';

  @override
  String get logbookEmpty => '还没有潜水记录。';

  @override
  String get logbookChecklist => '装备清单';

  @override
  String get logbookSiteLabel => '潜水地点';

  @override
  String get logbookDateLabel => '日期和时间';

  @override
  String get logbookMemoLabel => '一句话备注';

  @override
  String get logbookSelfRegisterHint => '无需教练签名，保存后即记入旅行日志。';

  @override
  String get logbookSelfRegistered => '旅行日志 · 自行登记';

  @override
  String get logbookBriefEmpty => '仅记录地点';

  @override
  String get logbookSlipTitle => '新日志条';

  @override
  String get logbookTankRackTitle => '通往金属卡的十只气瓶';

  @override
  String get logbookTankRackHint => '每只气瓶 10 潜次。深度只是记录，不是比赛。';

  @override
  String get logbookCenturyTitle => '100 到 1,000 · 下一程';

  @override
  String get logbookCenturyHint => '100 潜次可申请金属卡。之后换色继续记到 1,000。';

  @override
  String logbookCenturyLeft(int count, int target) {
    return '距 $target 还差 $count 潜次';
  }

  @override
  String get logbookCenturyMastered => '1,000 潜次大师';

  @override
  String get logbookJournalTitle => '旅行日志';

  @override
  String get logbookStatDives => '总潜次';

  @override
  String get logbookStatDiveUnit => '次';

  @override
  String get logbookStatTime => '累计时间';

  @override
  String get logbookStatRegions => '探索地区';

  @override
  String get logbookStatRegionUnit => '处';

  @override
  String get logbookMaxDepth => '最大深度';

  @override
  String get logbookAvgDepth => '平均深度';

  @override
  String get logbookMinutes => '潜水时间';

  @override
  String get logbookMinUnit => '分';

  @override
  String get logbookSac => 'BMV';

  @override
  String get logbookSacHint => 'BMV 用平均深度、时间、用气和气瓶容量计算。';

  @override
  String get logbookMix => '呼吸气体';

  @override
  String get logbookMixAir => '21% AIR';

  @override
  String get logbookMixNx32 => '32% NITROX';

  @override
  String get logbookMixNx36 => '36% NITROX';

  @override
  String get logbookPressure => '残压';

  @override
  String get logbookStartBar => '开始残压 (bar)';

  @override
  String get logbookEndBar => '结束残压 (bar)';

  @override
  String get logbookTankLiters => '气瓶容量 (L)';

  @override
  String get logbookTemp => '水温';

  @override
  String get logbookAirLeft => '剩余气体';

  @override
  String get logbookSave => '保存';

  @override
  String get logbookEdit => '编辑';

  @override
  String get logbookUpdated => '日志已更新。';

  @override
  String get logbookSaved => '已保存日志。地图和气瓶进度会更新。';

  @override
  String get logbookPhotoSection => '测试用水下照片';

  @override
  String get logbookPhotoHint => '可从相册或电脑选择，也可使用内置测试照片。';

  @override
  String get logbookAttachPhoto => '从设备选择';

  @override
  String get logbookUseTestPhoto => '使用测试照片';

  @override
  String logbookPhotoPicked(String fileName) {
    return '已附加：$fileName';
  }

  @override
  String get logbookPhotoRemove => '移除照片';

  @override
  String get logbookPhotoMissingConfig =>
      '请在 r2_config.dart 填入 Cloudflare R2 密钥后再上传照片。';

  @override
  String get logbookUploading => '上传中...';

  @override
  String get checklistTitle => '出发前装备清单';

  @override
  String get exploreTitle => '预订行程';

  @override
  String get exploreConsumerPrice => '消费者价';

  @override
  String get exploreProPrice => '教练优惠价';

  @override
  String get exploreSearchHint => '搜索度假村、潜点、国家';

  @override
  String get exploreFilterAll => '全部';

  @override
  String get exploreContinentAsia => '亚洲';

  @override
  String get exploreContinentAfrica => '非洲';

  @override
  String get exploreContinentOceania => '大洋洲';

  @override
  String get exploreContinentAmericas => '美洲';

  @override
  String get exploreContinentEurope => '欧洲';

  @override
  String get exploreContinentPolar => '极地';

  @override
  String get exploreProBanner => '教练已验证 · 全部商品显示优惠价';

  @override
  String get exploreConsumerBanner => '消费者价 · 应用内支付预订';

  @override
  String get exploreBook => '预订';

  @override
  String get optionBookPackage => '이 상품 예약';

  @override
  String get optionBookAddon => '이 구성 더해 예약';

  @override
  String get optionBookIndividual => '이 구성만 예약';

  @override
  String get explorePay => '申请席位';

  @override
  String get simPayTitle => '예약 요청 확인';

  @override
  String get simPayNotice => '지금은 결제하지 않습니다. 샵 확정 후 결제가 이어집니다.';

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
    return '由 $shop 接待';
  }

  @override
  String get exploreListingSites => '这片海的潜点';

  @override
  String get exploreListingAmenities => '此行程提供';

  @override
  String get exploreListingSafetyTitle => '安全优先的海';

  @override
  String get exploreListingSafetyBody => '深度不是炫耀。向导、船和装备优先。';

  @override
  String get exploreRareFind => '少见的 Dive Star 度假村';

  @override
  String get exploreRareFindBody => '星级来自运营评价。热门点请先锁定日期。';

  @override
  String get exploreWontChargeYet => '现在先定日期，店家确认后再付款。';

  @override
  String get exploreListingGuests => '人数';

  @override
  String get exploreListingGuestOne => '1 位潜水员';

  @override
  String get explorePerTrip => ' / 次';

  @override
  String get exploreCheckoutTitle => '预订支付';

  @override
  String exploreCheckoutBody(String shop, String product) {
    return '$shop · $product';
  }

  @override
  String get exploreBookingNotSaved =>
      '자리를 확보하지 못해 예약을 만들지 않았습니다. 빈자리를 다시 확인해 주세요.';

  @override
  String exploreCheckoutDone(String label, String price) {
    return '开始支付 $label $price。';
  }

  @override
  String get sameBoatSeatConfirmed => '가확정 좌석이 확정되었습니다. 결제가 완료된 예약입니다.';

  @override
  String get exploreConsumerPayHint => '店铺登记的消费者价。';

  @override
  String get exploreNoResults => '没有匹配的店铺。';

  @override
  String exploreDiveStar(int stars) {
    return 'Dive Star $stars';
  }

  @override
  String exploreRating(String rating, int count) {
    return '$rating · $count 条评价';
  }

  @override
  String explorePriceWon(String price) {
    return '$price원';
  }

  @override
  String exploreOriginalPrice(String price) {
    return '消费者价 $price원';
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
    return '出发 D-$days · $shop';
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
  String get communityTitle => '找潜伴';

  @override
  String get communityHostMileage => '组满队伍并成功预订后，队长可获得里程。';

  @override
  String get profileTitle => '我的页面';

  @override
  String get profileDepartureDeskKicker => '출항 데스크';

  @override
  String get profileCraftedTripsTitle => '내가 직접 짠 여행';

  @override
  String get profileCraftedTripsHint => '리조트를 골라 일정을 짜면 관리자 승인 후 여행상품에 올라갑니다.';

  @override
  String get profileCraftNewTrip => '새 여행 짜기';

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
  String get profileWriteReviewTitle => '내가 다녀온 여행 리뷰쓰기';

  @override
  String get profileCharmsTitle => '나의 바다 뱃지';

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
  String get profileCredentialsTitle => '자격증 및 등급';

  @override
  String get profileWorkModeTitle => '업무용 전환';

  @override
  String profileUpcomingConfirmed(String date) {
    return '예약 확정 · $date';
  }

  @override
  String get profileProBadge => '已认证 PRO 教练';

  @override
  String get profileMasterChallenge => '100 潜次大师挑战';

  @override
  String profileLogsProgress(int current, int target) {
    return '$current / $target';
  }

  @override
  String get profileMetalCard => '申请实体金属卡';

  @override
  String get profileMetalCardHint => '达到 100 潜次后可申请实体金属认证卡。';

  @override
  String get profileRadarTitle => '护照印章';

  @override
  String profileRegions(int count) {
    return '已探索 $count 个地区';
  }

  @override
  String get metalCardDialogTitle => '达成 100 潜次大师';

  @override
  String get metalCardDialogBody => '实体金属卡免费配送将在第 2 阶段接入。现在只是庆祝画面。';

  @override
  String get metalCardDialogClose => '确定';

  @override
  String get authLogin => '登录';

  @override
  String get authSignup => '注册';

  @override
  String get authWelcome => '注册后即可使用日志、同船和预约。管理员会按活跃度调整等级。';

  @override
  String get authEmail => '邮箱';

  @override
  String get authPassword => '密码';

  @override
  String get authPasswordHint => '至少 6 个字符';

  @override
  String get authDisplayName => '姓名';

  @override
  String get authNoAccount => '没有账号？去注册';

  @override
  String get authHaveAccount => '已有账号？去登录';

  @override
  String get authErrorInvalidEmail => '邮箱格式不正确。';

  @override
  String get authErrorInvalidCredential => '邮箱或密码不正确。';

  @override
  String get authResetPassword => '发送密码重置邮件';

  @override
  String get authResetPasswordSent => '已发送密码重置邮件。';

  @override
  String get authErrorEmailInUse => '该邮箱已注册。';

  @override
  String get authErrorWeakPassword => '密码至少 6 个字符。';

  @override
  String get authErrorNetwork => '请检查网络连接。';

  @override
  String get authErrorGeneric => '登录失败，请稍后重试。';

  @override
  String get authErrorOperationNotAllowed =>
      '邮箱密码登录尚未开启。请在 Firebase Authentication 中启用。';

  @override
  String get authErrorFirestore => '账号已创建，但无法写入 Firestore 资料。请创建数据库并粘贴规则。';

  @override
  String get profileSignOut => '退出登录';

  @override
  String get logbookSaveFailed => '保存日志失败。';

  @override
  String get firebaseSetupTitle => '需要连接 Firebase';

  @override
  String get firebaseSetupBody =>
      '请创建 DiveTravelApp 项目，开启邮箱登录和 Firestore，然后运行 flutterfire configure。';

  @override
  String get adminMode => '管理员模式';

  @override
  String get adminPinTitle => '管理员 PIN';

  @override
  String get adminPinHint => '4 位 PIN';

  @override
  String get adminPinConfirm => '进入';

  @override
  String get adminPinWrong => 'PIN 不正确。';

  @override
  String get adminAccessDenied => '此账号没有管理员权限。';

  @override
  String get adminDashboardTitle => '管理员控制台';

  @override
  String get adminDashboardSubtitle => '统一管理教练认证、Dive Star 潜店和帖子。';

  @override
  String get adminHqTitle => 'Dive Travel HQ';

  @override
  String get adminHqSubtitle => '总管理员控制台';

  @override
  String get adminHqClose => '关闭';

  @override
  String get adminTabOverview => '概况';

  @override
  String get adminTabMembers => '会员';

  @override
  String get adminMembersSubDivers => '다이버';

  @override
  String get adminMembersSubInstructors => '강사인증';

  @override
  String get adminMembersSubPartners => '제휴파트너';

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
  String adminNearUpgradeHint(int purchases, int reviews) {
    return '다음 등급까지 구매 $purchases · 리뷰 $reviews';
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
  String get adminTabCertify => '认证';

  @override
  String get adminTabShops => '潜店';

  @override
  String get adminTabOps => '运营';

  @override
  String get adminMetricMembers => '全部会员';

  @override
  String get adminMetricPendingCert => '待认证';

  @override
  String get adminMetricPlaques => '牌匾队列';

  @override
  String get adminMetricPosts => '帖子';

  @override
  String adminMetricHidden(int count) {
    return '已隐藏 $count';
  }

  @override
  String adminMetricShops(int count) {
    return '合作潜店 $count';
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
  String get adminAttentionTitle => '待处理';

  @override
  String get adminAttentionClear => '暂无紧急事项。';

  @override
  String adminAttentionCertify(int count) {
    return '$count 份教练证待审';
  }

  @override
  String adminAttentionPlaque(int count) {
    return '$count 块牌匾待处理';
  }

  @override
  String adminAttentionHidden(int count) {
    return '$count 条隐藏帖';
  }

  @override
  String get adminGradeMixTitle => '会员等级分布';

  @override
  String get adminQuickActions => '快捷操作';

  @override
  String get adminMembersTitle => '会员管理';

  @override
  String get adminMembersSubtitle => '查询会员并调整等级：银、金、钻石、白金。';

  @override
  String get adminMembersSearch => '搜索姓名或邮箱';

  @override
  String get adminMembersEmpty => '没有匹配的会员。';

  @override
  String get adminMembersGrade => '会员等级';

  @override
  String adminMembersActivity(int logs, int regions) {
    return '日志 $logs · 地区 $regions';
  }

  @override
  String adminMembersSuggested(String grade) {
    return '活跃参考等级 · $grade';
  }

  @override
  String get memberGradeSilver => '银会员';

  @override
  String get memberGradeGold => '金会员';

  @override
  String get memberGradeDiamond => '钻石会员';

  @override
  String get memberGradePlatinum => '白金会员';

  @override
  String get adminInstructorsTitle => '教练证书审批';

  @override
  String get adminInstructorsSubtitle => '核对 R2 上的 C-Card，通过后开放专业价。';

  @override
  String adminInstructorAgency(String agency) {
    return '发证机构 · $agency';
  }

  @override
  String get adminApprove => '通过';

  @override
  String get adminReject => '拒绝';

  @override
  String get adminNoPending => '暂无待审申请。';

  @override
  String get adminShopsTitle => 'Dive Star · 合作潜店';

  @override
  String get adminPartnersGradeHint => '다이브스타 제휴는 리뷰와 내부심사로 등급을 봅니다.';

  @override
  String get adminShopsSubtitle => '监控运营评分、星级和牌匾发货。';

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
      '조건에 맞는 공개 상품이 없습니다. 상품을 등록·승인했는지 확인하세요.';

  @override
  String get sameBoatSeatsSubmit => '승인 요청';

  @override
  String get sameBoatSeatsPublish => '같은배에 바로 게시';

  @override
  String get sameBoatSeatsSubmitted => '빈자리 승인 요청을 보냈습니다.';

  @override
  String get sameBoatSeatsPublished => '같은배에 빈자리를 게시했습니다.';

  @override
  String get sameBoatSeatsEdit => '빈자리 수정';

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
  String get adminProductRejected => '상품 등록이 거절되었습니다.';

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
  String get productFormDirectSelect => '직접선택';

  @override
  String get productFormSubtitle => '한 줄 소개';

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
  String get adminPlaqueQueue => '实体牌匾发货名单';

  @override
  String get adminPlaqueEmpty => '尚无达到星级的潜店。';

  @override
  String get adminPlaqueRequest => '申请发牌匾';

  @override
  String get adminPlaqueQueued => '已申请发货';

  @override
  String get adminPlaqueShipped => '已发货';

  @override
  String get adminPlaqueNone => '牌匾待处理';

  @override
  String get adminPlaqueMarkShipped => '标记已发货';

  @override
  String get adminShopMonitor => '全球合作潜店监控';

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
  String get adminPostsTitle => '商品与团游审核';

  @override
  String get adminPostsSubtitle => '审核潜店商品和潜伴招募，可隐藏或删除虚假/违法帖。';

  @override
  String get adminHidePost => '隐藏';

  @override
  String get adminUnhidePost => '取消隐藏';

  @override
  String get adminDeletePost => '删除';

  @override
  String get adminEmptyPosts => '暂无帖子。';

  @override
  String get adminPostTypeBuddy => '潜伴招募';

  @override
  String get adminPostTypeTour => '潜店行程';

  @override
  String get adminPostHidden => '已隐藏';

  @override
  String get partnerTitle => '合作伙伴模式';

  @override
  String get partnerSubtitle => '编辑潜店、上架行程并查看本月结算。';

  @override
  String get partnerAccessDenied => '此账号不是 Business 合作伙伴。';

  @override
  String get partnerShopEdit => '编辑潜店资料';

  @override
  String get partnerShopEditHint => '保存名称、位置、默认商品和两种价格。';

  @override
  String get partnerProductForm => '登记商品';

  @override
  String get partnerProductFormHint => '请分别填写消费者价和教练特价。';

  @override
  String get partnerSettlementTitle => '本月结算';

  @override
  String get partnerCommissionRange => '已扣除 10–15% 平台费（默认 12%）。';

  @override
  String get partnerGross => '预约营收';

  @override
  String get partnerFee => '手续费';

  @override
  String get partnerNet => '预计结算';

  @override
  String get partnerBookingsTitle => '实时预约';

  @override
  String get partnerNoBookings => '该潜店暂无预约。';

  @override
  String get partnerShopName => '潜店名称';

  @override
  String get partnerShopLocation => '位置';

  @override
  String get partnerDefaultProduct => '商品名';

  @override
  String get partnerSave => '保存';

  @override
  String get translateAction => '🌐 查看翻译';

  @override
  String get translateLoading => '翻译中…';

  @override
  String get translateShowOriginal => '查看原文';

  @override
  String get communityCompose => '写潜伴帖';

  @override
  String get communityPostTitle => '标题';

  @override
  String get communityPostBody => '内容';

  @override
  String get communityPostSubmit => '发布';

  @override
  String get communityComments => '评论';

  @override
  String get communityNoComments => '暂无评论。';

  @override
  String get communityCommentHint => '写评论';

  @override
  String get communityTideKicker => '출발 보드';

  @override
  String get communityTideHeadline => '이미 나가는 배의 남은 자리';

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
  String get communityBoardListHint =>
      '출발일과 깃발 마감 중 더 빠른 날 순입니다. 빈자리를 잡으면 예약으로 이어집니다.';

  @override
  String get communityViewSeats => '자리 보기';

  @override
  String get communityWindowOpen => '일정 미정';

  @override
  String get communityPlantFlag => '깃발 꽂기';

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
  String get communitySeatsShort => '이 옵션의 남은 자리가 부족합니다.';

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
  String get communityDesignPreviewFlag => '확인용 카드라 자리는 잡지 않습니다.';

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
  String get weatherCancel => '天气取消';

  @override
  String get weatherAdminTitle => '天气取消权限';

  @override
  String get weatherAdminBody => '将该日预约标为 weather_cancelled 并保证 100% 退款。';

  @override
  String get weatherTourDate => '行程日期';

  @override
  String get weatherCancelDone => '已应用天气取消与全额退款。';

  @override
  String get weatherRefundTitle => '天气原因 100% 退款';

  @override
  String weatherRefundBody(String shop, String product) {
    return '$shop · $product 因天气取消，支付/积分将全额退还。';
  }

  @override
  String get weatherRefundAck => '确定';

  @override
  String get bookingConfirmed => '已确认';

  @override
  String get bookingRequested => '예약 요청';

  @override
  String get bookingCancelled => '已取消';

  @override
  String get bookingWeatherCancelled => '天气取消 · 100% 退款';

  @override
  String get bookingCancel => '取消预约';

  @override
  String bookingCancelledRefund(int percent) {
    return '已取消 · 退款 $percent%';
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
  String get adminBookingsTitle => '예약 확정';

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
  String get workbenchCatDay => '데이트립';

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
  String get workbenchSeatCount => '자리 수';

  @override
  String get workbenchDepartureDate => '출발일';

  @override
  String get workbenchFlagDeadline => '깃발 마감일';

  @override
  String get workbenchOpenSeatsNeedFields => '빈자리를 열려면 자리 수·출발일·깃발 마감을 넣으세요.';

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
  String get adminProductDelete => '삭제';

  @override
  String adminProductDeleteBody(String name) {
    return '「$name」을 삭제하면 상품 목록에서 빠집니다.';
  }

  @override
  String get adminProductDeleted => '상품을 삭제했습니다.';

  @override
  String get adminProductRejectNote => '거절 사유';

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
  String refundPolicyHint(int percent) {
    return '现在取消可退 $percent%';
  }
}
