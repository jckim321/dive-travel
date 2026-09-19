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
  String get explorePay => '申请席位';

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
  String exploreCheckoutDone(String label, String price) {
    return '开始支付 $label $price。';
  }

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
  String get communityTitle => '找潜伴';

  @override
  String get communityHostMileage => '组满队伍并成功预订后，队长可获得里程。';

  @override
  String get profileTitle => '我的页面';

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
  String get adminShopsSubtitle => '监控运营评分、星级和牌匾发货。';

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
  String get communityTideKicker => '깃발꽂기';

  @override
  String get communityTideHeadline => '먼저 리조트를 고르세요.\n예약한 뒤에 방을 엽니다.';

  @override
  String get communityTideBody =>
      '혼자 가도, 이미 짠 팀을 데려가도 여행상품에서 예약합니다. 지인·동호회를 같은 일정에 태우고 싶을 때만 깃발을 꽂습니다.';

  @override
  String get communityTideSafety =>
      '물속 버디는 샵이 배정합니다. 이 탭은 이미 예약한 여행의 밴·식탁·침대를 나눕니다.';

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
  String get exploreResortTraits => '리조트 특성';

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
      'Booking.com·아고다처럼 가로 16:9로 보여 줍니다. 세로 사진은 가운데를 잘라 씁니다.';

  @override
  String get exploreAttachPhoto => '사진 첨부';

  @override
  String get exploreUseAsCover => '이 사진을 리조트 대표 이미지로';

  @override
  String get exploreCoverRemove => '이미지 삭제';

  @override
  String get communityFilterAll => '모든 밀물';

  @override
  String get communityFilterLastCall => '마감임박';

  @override
  String get communityFilterSolo => '싱글쉐어';

  @override
  String get communityFilterShop => '샵 크루';

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
  String refundPolicyHint(int percent) {
    return '现在取消可退 $percent%';
  }
}
