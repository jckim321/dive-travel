// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'ไดฟ์ทราเวล';

  @override
  String get homeWelcome => 'มหาสมุทรของคุณกว้างแค่ไหนแล้ว?';

  @override
  String get homeSubtitle => 'มหาสมุทรทั้งโลกอยู่ในมือคุณ';

  @override
  String get homeProWelcome => 'สวัสดีครับ/ค่ะ PRO อินสตรักเตอร์!';

  @override
  String get homeMapTitle => 'แผนที่มหาสมุทรของฉัน';

  @override
  String homeMapExplored(int count) {
    return 'สำรวจแล้ว $count พื้นที่';
  }

  @override
  String get homeMapTip => 'ดำน้ำซ้ำในที่เดิมมากเท่าไร แสงนีออนจะกลายเป็นสีทอง';

  @override
  String get homeDiveStarTitle => 'รีสอร์ต Dive Star ประจำเดือน';

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
  String get homeNextDepartures => 'รอบออกเดินทางนี้';

  @override
  String get homeLastMinuteTitle => 'ทัวร์กลุ่มใกล้ปิดรอบ';

  @override
  String get homeLastMinuteCrew => '다합 사흘 소셜 크루';

  @override
  String get homeLastMinuteSeat => '내일 마감 · 남은 자리 1명 · 싱글차지 없음';

  @override
  String get homeForYouTitle => 'ทะเลถัดไปสำหรับคุณ';

  @override
  String get homeStyleFirstOcean => 'นักดำน้ำที่กำลังเปิดทะเลแรก';

  @override
  String get homeStyleFirstOceanBody =>
      'ยังไม่มีแสตมป์ เริ่มที่เอเชียแล้วล็อกกับทริปจะต่อกัน';

  @override
  String get homeStyleHomeContinent => 'นักดำน้ำที่ลงลึกในทะเลเดียว';

  @override
  String get homeStyleHomeContinentBody =>
      'มีทะเลประจำแล้ว เปิดทวีปอื่นเพื่อขยายแผนที่';

  @override
  String get homeStyleCollector => 'นักสำรวจที่สะสมมหาสมุทร';

  @override
  String get homeStyleCollectorBody => 'เหยียบหลายทวีปแล้ว เติมแสตมป์ที่ว่าง';

  @override
  String get homeStyleDeepLocal => 'นักดำน้ำที่กลับจุดเดิม';

  @override
  String get homeStyleDeepLocalBody => 'ดำซ้ำจนกลายเป็นโซนทอง ต่อไปขยายมุมมอง';

  @override
  String get homeStylePro => 'อินสตรักเตอร์สายโปร';

  @override
  String get homeStyleProBody =>
      'เปิดทวีปใหม่ด้วยราคาโปร ซ้อนการสอนกับการเดินทาง';

  @override
  String get homeNextOceanTitle => 'ทะเลที่จะเปิดต่อไป';

  @override
  String homeNextOceanBody(String continent) {
    return 'ยังไม่มีล็อกใน $continent เริ่มจากทริปนี้';
  }

  @override
  String homeOpenShop(String name) {
    return 'ดู $name';
  }

  @override
  String get homeStampsLabel => 'แสตมป์';

  @override
  String homeStampsProgress(int stamped, int total) {
    return '$stamped/$total ทวีป';
  }

  @override
  String get homeBadgeLabel => 'แบดจ์ถัดไป';

  @override
  String homeBadgeLeft(int count) {
    return 'อีก $count ล็อกถึงบัตรเมทัล';
  }

  @override
  String get homeBadgeDone => 'ขอบัตรเมทัลได้';

  @override
  String get homeChecklistLabel => 'เช็กก่อนออกเดินทาง';

  @override
  String homeChecklistSoon(int days, String shop) {
    return '$days วัน · $shop';
  }

  @override
  String get homeChecklistIdle => 'เปิดรายการอุปกรณ์';

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
  String get profilePassportHint => 'ทวีปที่มีล็อกจะได้แสตมป์';

  @override
  String get navHome => 'หน้าหลัก';

  @override
  String get navLogbook => 'ล็อกบุ๊ก';

  @override
  String get navExplore => 'จองทัวร์';

  @override
  String get navCommunity => 'เรือเดียวกัน';

  @override
  String get navProfile => 'ของฉัน';

  @override
  String get logbookTitle => 'ล็อกบุ๊กดิจิทัล';

  @override
  String get logbookAdd => 'เพิ่มล็อก';

  @override
  String get logbookEmpty => 'ยังไม่มีบันทึกการดำน้ำ';

  @override
  String get logbookChecklist => 'เช็คลิสต์อุปกรณ์';

  @override
  String get logbookSiteLabel => 'สถานที่ดำน้ำ';

  @override
  String get logbookDateLabel => 'วันและเวลา';

  @override
  String get logbookMemoLabel => 'บันทึกสั้น ๆ';

  @override
  String get logbookSelfRegisterHint =>
      'บันทึกโดยไม่ต้องลายเซ็นครู เป็นบันทึกการเดินทางทันที';

  @override
  String get logbookSelfRegistered => 'บันทึกเดินทาง · ลงทะเบียนเอง';

  @override
  String get logbookBriefEmpty => 'บันทึกเฉพาะจุด';

  @override
  String get logbookSlipTitle => 'สลิปบันทึกใหม่';

  @override
  String get logbookTankRackTitle => 'ถัง 10 ใบสู่การ์ดเมทัล';

  @override
  String get logbookTankRackHint =>
      'ถังละ 10 ล็อก ความลึกคือบันทึก ไม่ใช่การแข่ง';

  @override
  String get logbookCenturyTitle => '100 ถึง 1,000 · ช่วงถัดไป';

  @override
  String get logbookCenturyHint =>
      'ครบ 100 ได้บัตรเมทัล ต่อไปเปลี่ยนสีถึง 1,000';

  @override
  String logbookCenturyLeft(int count, int target) {
    return 'อีก $count ล็อกถึง $target';
  }

  @override
  String get logbookCenturyMastered => 'มาสเตอร์ 1,000 ล็อก';

  @override
  String get logbookJournalTitle => 'บันทึกการเดินทาง';

  @override
  String get logbookStatDives => 'ไดฟ์ทั้งหมด';

  @override
  String get logbookStatDiveUnit => 'ครั้ง';

  @override
  String get logbookStatTime => 'เวลารวม';

  @override
  String get logbookStatRegions => 'พื้นที่สำรวจ';

  @override
  String get logbookStatRegionUnit => 'แห่ง';

  @override
  String get logbookMaxDepth => 'ความลึกสูงสุด';

  @override
  String get logbookAvgDepth => 'ความลึกเฉลี่ย';

  @override
  String get logbookMinutes => 'เวลาดำ';

  @override
  String get logbookMinUnit => 'นาที';

  @override
  String get logbookSac => 'BMV';

  @override
  String get logbookSacHint =>
      'BMV คำนวณจากความลึกเฉลี่ย เวลา แรงดันที่ใช้ และขนาดถัง';

  @override
  String get logbookMix => 'แก๊ส';

  @override
  String get logbookMixAir => '21% AIR';

  @override
  String get logbookMixNx32 => '32% NITROX';

  @override
  String get logbookMixNx36 => '36% NITROX';

  @override
  String get logbookPressure => 'แรงดัน';

  @override
  String get logbookStartBar => 'เริ่ม (bar)';

  @override
  String get logbookEndBar => 'จบ (bar)';

  @override
  String get logbookTankLiters => 'ถัง (L)';

  @override
  String get logbookTemp => 'อุณหภูมิน้ำ';

  @override
  String get logbookAirLeft => 'อากาศเหลือ';

  @override
  String get logbookSave => 'บันทึก';

  @override
  String get logbookEdit => 'แก้ไข';

  @override
  String get logbookUpdated => 'อัปเดตบันทึกแล้ว';

  @override
  String get logbookSaved => 'บันทึกล็อกแล้ว แผนที่และเกจถังจะอัปเดต';

  @override
  String get logbookPhotoSection => 'รูปทดสอบใต้น้ำ';

  @override
  String get logbookPhotoHint =>
      'เลือกจากแกลเลอรีหรือคอมพิวเตอร์ หรือใช้รูปทดสอบ';

  @override
  String get logbookAttachPhoto => 'เลือกจากเครื่อง';

  @override
  String get logbookUseTestPhoto => 'ใช้รูปทดสอบ';

  @override
  String logbookPhotoPicked(String fileName) {
    return 'แนบแล้ว: $fileName';
  }

  @override
  String get logbookPhotoRemove => 'ลบรูป';

  @override
  String get logbookPhotoMissingConfig =>
      'ใส่คีย์ Cloudflare R2 ใน r2_config.dart ก่อนอัปโหลดรูป';

  @override
  String get logbookUploading => 'กำลังอัปโหลด...';

  @override
  String get checklistTitle => 'เช็คลิสต์อุปกรณ์ก่อนเดินทาง';

  @override
  String get exploreTitle => 'จองทัวร์';

  @override
  String get exploreConsumerPrice => 'ราคาทั่วไป';

  @override
  String get exploreProPrice => 'ราคาโปร';

  @override
  String get exploreSearchHint => 'ค้นหารีสอร์ต จุดดำน้ำ ประเทศ';

  @override
  String get exploreFilterAll => 'ทั้งหมด';

  @override
  String get exploreContinentAsia => 'เอเชีย';

  @override
  String get exploreContinentAfrica => 'แอฟริกา';

  @override
  String get exploreContinentOceania => 'โอเชียเนีย';

  @override
  String get exploreContinentAmericas => 'อเมริกา';

  @override
  String get exploreContinentEurope => 'ยุโรป';

  @override
  String get exploreContinentPolar => 'ขั้วโลก';

  @override
  String get exploreProBanner =>
      'ยืนยันอินสตรักเตอร์แล้ว · แสดงราคาโปรทุกสินค้า';

  @override
  String get exploreConsumerBanner => 'ราคาทั่วไป · จองด้วยชำระในแอป';

  @override
  String get exploreBook => 'จอง';

  @override
  String get explorePay => 'ขอที่นั่ง';

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
    return 'โฮสต์โดย $shop';
  }

  @override
  String get exploreListingSites => 'จุดดำน้ำในทะเลนี้';

  @override
  String get exploreListingAmenities => 'ทริปนี้มีอะไร';

  @override
  String get exploreListingSafetyTitle => 'ทะเลที่ปลอดภัยก่อน';

  @override
  String get exploreListingSafetyBody =>
      'ความลึกไม่ใช่ของโอ้อวด ไกด์ เรือ อุปกรณ์มาก่อน';

  @override
  String get exploreRareFind => 'รีสอร์ต Dive Star ที่หาได้ยาก';

  @override
  String get exploreRareFindBody => 'ดาวมาจากรีวิวการปฏิบัติงาน จองวันไว้ก่อน';

  @override
  String get exploreWontChargeYet => 'ตอนนี้เลือกวัน จ่ายหลังร้านยืนยัน';

  @override
  String get exploreListingGuests => 'ผู้เข้าพัก';

  @override
  String get exploreListingGuestOne => 'นักดำน้ำ 1 คน';

  @override
  String get explorePerTrip => ' / ครั้ง';

  @override
  String get exploreCheckoutTitle => 'ชำระเงิน';

  @override
  String exploreCheckoutBody(String shop, String product) {
    return '$shop · $product';
  }

  @override
  String exploreCheckoutDone(String label, String price) {
    return 'เริ่มชำระในแอป $label $price';
  }

  @override
  String get exploreConsumerPayHint => 'ราคาผู้บริโภคที่ร้านลงทะเบียน';

  @override
  String get exploreNoResults => 'ไม่พบร้านที่ตรงกัน';

  @override
  String exploreDiveStar(int stars) {
    return 'Dive Star $stars';
  }

  @override
  String exploreRating(String rating, int count) {
    return '$rating · $count รีวิว';
  }

  @override
  String explorePriceWon(String price) {
    return '$price원';
  }

  @override
  String exploreOriginalPrice(String price) {
    return 'ราคาทั่วไป $price원';
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
  String get communityTitle => 'หาบัดดี้';

  @override
  String get communityHostMileage =>
      'รวบรวมครูแล้วจองสำเร็จ หัวหน้าทริปได้ไมล์';

  @override
  String get profileTitle => 'หน้าของฉัน';

  @override
  String get profileProBadge => 'ยืนยันอินสตรักเตอร์ PRO แล้ว';

  @override
  String get profileMasterChallenge => 'ชาเลนจ์มาสเตอร์ 100 ล็อก';

  @override
  String profileLogsProgress(int current, int target) {
    return '$current / $target';
  }

  @override
  String get profileMetalCard => 'ขอการ์ดโลหะ';

  @override
  String get profileMetalCardHint => 'ครบ 100 ล็อกแล้วขอการ์ดโลหะจริงได้';

  @override
  String get profileRadarTitle => 'แสตมป์พาสปอร์ต';

  @override
  String profileRegions(int count) {
    return 'สำรวจแล้ว $count พื้นที่';
  }

  @override
  String get metalCardDialogTitle => 'มาสเตอร์ 100 ล็อก';

  @override
  String get metalCardDialogBody =>
      'การจัดส่งการ์ดฟรีจะเชื่อมในขั้นที่ 2 ตอนนี้เป็นหน้าฉลอง';

  @override
  String get metalCardDialogClose => 'ตกลง';

  @override
  String get authLogin => 'เข้าสู่ระบบ';

  @override
  String get authSignup => 'สมัครสมาชิก';

  @override
  String get authWelcome =>
      'สมัครแล้วใช้ล็อก Same Tide และการจองได้ทันที ผู้ดูแลปรับระดับตามกิจกรรม';

  @override
  String get authEmail => 'อีเมล';

  @override
  String get authPassword => 'รหัสผ่าน';

  @override
  String get authPasswordHint => 'อย่างน้อย 6 ตัว';

  @override
  String get authDisplayName => 'ชื่อ';

  @override
  String get authNoAccount => 'ยังไม่มีบัญชี? สมัครสมาชิก';

  @override
  String get authHaveAccount => 'มีบัญชีแล้ว? เข้าสู่ระบบ';

  @override
  String get authErrorInvalidEmail => 'รูปแบบอีเมลไม่ถูกต้อง';

  @override
  String get authErrorInvalidCredential => 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';

  @override
  String get authResetPassword => 'ส่งอีเมลรีเซ็ตรหัสผ่าน';

  @override
  String get authResetPasswordSent => 'ส่งอีเมลรีเซ็ตรหัสผ่านแล้ว';

  @override
  String get authErrorEmailInUse => 'อีเมลนี้ถูกใช้แล้ว';

  @override
  String get authErrorWeakPassword => 'รหัสผ่านต้องมีอย่างน้อย 6 ตัว';

  @override
  String get authErrorNetwork => 'โปรดตรวจสอบเครือข่าย';

  @override
  String get authErrorGeneric => 'เข้าสู่ระบบไม่สำเร็จ';

  @override
  String get authErrorOperationNotAllowed =>
      'ยังไม่ได้เปิดอีเมล/รหัสผ่าน ใน Firebase Authentication';

  @override
  String get authErrorFirestore =>
      'สร้างบัญชีแล้ว แต่บันทึกโปรไฟล์ Firestore ไม่ได้';

  @override
  String get profileSignOut => 'ออกจากระบบ';

  @override
  String get logbookSaveFailed => 'บันทึกล็อกล้มเหลว';

  @override
  String get firebaseSetupTitle => 'ต้องเชื่อม Firebase';

  @override
  String get firebaseSetupBody =>
      'สร้างโปรเจกต์ DiveTravelApp เปิด Email/Password และ Firestore แล้วรัน flutterfire configure';

  @override
  String get adminMode => 'โหมดผู้ดูแล';

  @override
  String get adminPinTitle => 'PIN ผู้ดูแล';

  @override
  String get adminPinHint => 'PIN 4 หลัก';

  @override
  String get adminPinConfirm => 'เข้า';

  @override
  String get adminPinWrong => 'PIN ไม่ถูกต้อง';

  @override
  String get adminAccessDenied => 'บัญชีนี้ไม่มีสิทธิ์ผู้ดูแล';

  @override
  String get adminDashboardTitle => 'แดชบอร์ดผู้ดูแล';

  @override
  String get adminDashboardSubtitle =>
      'ควบคุมการยืนยันอินสตรักเตอร์, Dive Star และโพสต์';

  @override
  String get adminHqTitle => 'Dive Travel HQ';

  @override
  String get adminHqSubtitle => 'คอนโซลผู้ดูแลสูงสุด';

  @override
  String get adminHqClose => 'ปิด';

  @override
  String get adminTabOverview => 'ภาพรวม';

  @override
  String get adminTabMembers => 'สมาชิก';

  @override
  String get adminTabCertify => 'รับรอง';

  @override
  String get adminTabShops => 'ร้าน';

  @override
  String get adminTabOps => 'ปฏิบัติการ';

  @override
  String get adminMetricMembers => 'สมาชิกทั้งหมด';

  @override
  String get adminMetricPendingCert => 'รอรับรอง';

  @override
  String get adminMetricPlaques => 'คิวป้าย';

  @override
  String get adminMetricPosts => 'โพสต์';

  @override
  String adminMetricHidden(int count) {
    return 'ซ่อน $count';
  }

  @override
  String adminMetricShops(int count) {
    return 'ร้านพันธมิตร $count';
  }

  @override
  String get adminAttentionTitle => 'ต้องจัดการ';

  @override
  String get adminAttentionClear => 'ไม่มีงานเร่งด่วน';

  @override
  String adminAttentionCertify(int count) {
    return 'รออนุมัติใบรับรอง $count';
  }

  @override
  String adminAttentionPlaque(int count) {
    return 'ตรวจป้าย $count รายการ';
  }

  @override
  String adminAttentionHidden(int count) {
    return 'โพสต์ที่ซ่อน $count';
  }

  @override
  String get adminGradeMixTitle => 'สัดส่วนระดับสมาชิก';

  @override
  String get adminQuickActions => 'ทางลัด';

  @override
  String get adminMembersTitle => 'สมาชิก';

  @override
  String get adminMembersSubtitle =>
      'ค้นหาสมาชิกและปรับระดับ สมาชิก / พิเศษ / VIP / อินสตรักเตอร์';

  @override
  String get adminMembersSearch => 'ค้นหาชื่อหรืออีเมล';

  @override
  String get adminMembersEmpty => 'ไม่พบสมาชิก';

  @override
  String get adminMembersGrade => 'ระดับสมาชิก';

  @override
  String adminMembersActivity(int logs, int regions) {
    return 'ล็อก $logs · พื้นที่ $regions';
  }

  @override
  String adminMembersSuggested(String grade) {
    return 'ระดับจากกิจกรรม · $grade';
  }

  @override
  String get memberGradeMember => 'สมาชิก';

  @override
  String get memberGradeSpecial => 'สมาชิกพิเศษ';

  @override
  String get memberGradeVip => 'VIP';

  @override
  String get memberGradeInstructor => 'อินสตรักเตอร์';

  @override
  String get adminInstructorsTitle => 'อนุมัติใบรับรอง';

  @override
  String get adminInstructorsSubtitle =>
      'ตรวจ C-Card บน R2 เมื่ออนุมัติจะเปิดราคาโปร';

  @override
  String adminInstructorAgency(String agency) {
    return 'หน่วยงาน · $agency';
  }

  @override
  String get adminApprove => 'อนุมัติ';

  @override
  String get adminReject => 'ปฏิเสธ';

  @override
  String get adminNoPending => 'ไม่มีคำขอที่รออยู่';

  @override
  String get adminShopsTitle => 'Dive Star · ร้านพันธมิตร';

  @override
  String get adminShopsSubtitle => 'ติดตามคะแนนปฏิบัติการ ดาว และการส่งป้าย';

  @override
  String get adminPlaqueQueue => 'รายการส่งป้ายจริง';

  @override
  String get adminPlaqueEmpty => 'ยังไม่มีร้านที่ถึงเกรดดาว';

  @override
  String get adminPlaqueRequest => 'ขอส่งป้าย';

  @override
  String get adminPlaqueQueued => 'ขอส่งแล้ว';

  @override
  String get adminPlaqueShipped => 'ส่งแล้ว';

  @override
  String get adminPlaqueNone => 'รอป้าย';

  @override
  String get adminPlaqueMarkShipped => 'ทำเครื่องหมายว่าส่งแล้ว';

  @override
  String get adminShopMonitor => 'มอนิเตอร์ร้านพันธมิตรทั่วโลก';

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
  String get adminPostsTitle => 'ทัวร์และโพสต์บัดดี้';

  @override
  String get adminPostsSubtitle =>
      'ตรวจสินค้าและโพสต์บัดดี้ ซ่อนหรือลบโพสต์ปลอม/ผิดกฎหมาย';

  @override
  String get adminHidePost => 'ซ่อน';

  @override
  String get adminUnhidePost => 'เลิกซ่อน';

  @override
  String get adminDeletePost => 'ลบ';

  @override
  String get adminEmptyPosts => 'ยังไม่มีโพสต์';

  @override
  String get adminPostTypeBuddy => 'บัดดี้';

  @override
  String get adminPostTypeTour => 'ทัวร์ร้าน';

  @override
  String get adminPostHidden => 'ถูกซ่อน';

  @override
  String get partnerTitle => 'โหมดพาร์ทเนอร์';

  @override
  String get partnerSubtitle => 'แก้ร้าน ลงทัวร์ และดูยอดเดือนนี้';

  @override
  String get partnerAccessDenied => 'บัญชีนี้ไม่ใช่พาร์ทเนอร์ Business';

  @override
  String get partnerShopEdit => 'แก้ไขร้าน';

  @override
  String get partnerShopEditHint => 'บันทึกชื่อ ที่ตั้ง สินค้า และราคาทั้งสอง';

  @override
  String get partnerProductForm => 'ลงสินค้า';

  @override
  String get partnerProductFormHint => 'กรอกราคาทั่วไปและราคาโปรแยกกัน';

  @override
  String get partnerSettlementTitle => 'ยอดเดือนนี้';

  @override
  String get partnerCommissionRange => 'หักค่าธรรมเนียม 10–15% (ค่าเริ่ม 12%)';

  @override
  String get partnerGross => 'ยอดจอง';

  @override
  String get partnerFee => 'ค่าธรรมเนียม';

  @override
  String get partnerNet => 'ยอดรับสุทธิ';

  @override
  String get partnerBookingsTitle => 'จองแบบเรียลไทม์';

  @override
  String get partnerNoBookings => 'ยังไม่มีการจอง';

  @override
  String get partnerShopName => 'ชื่อร้าน';

  @override
  String get partnerShopLocation => 'ที่ตั้ง';

  @override
  String get partnerDefaultProduct => 'ชื่อสินค้า';

  @override
  String get partnerSave => 'บันทึก';

  @override
  String get translateAction => '🌐 ดูคำแปล';

  @override
  String get translateLoading => 'กำลังแปล…';

  @override
  String get translateShowOriginal => 'ดูต้นฉบับ';

  @override
  String get communityCompose => 'เขียนโพสต์บัดดี้';

  @override
  String get communityPostTitle => 'หัวข้อ';

  @override
  String get communityPostBody => 'รายละเอียด';

  @override
  String get communityPostSubmit => 'โพสต์';

  @override
  String get communityComments => 'ความคิดเห็น';

  @override
  String get communityNoComments => 'ยังไม่มีความคิดเห็น';

  @override
  String get communityCommentHint => 'เขียนความคิดเห็น';

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
  String get weatherCancel => 'ยกเลิกอากาศ';

  @override
  String get weatherAdminTitle => 'สิทธิ์ยกเลิกอากาศ';

  @override
  String get weatherAdminBody =>
      'ตั้งสถานะวันนั้นเป็น weather_cancelled และคืนเงิน 100%';

  @override
  String get weatherTourDate => 'วันทัวร์';

  @override
  String get weatherCancelDone => 'ยกเลิกอากาศและคืนเงินเต็มจำนวนแล้ว';

  @override
  String get weatherRefundTitle => 'คืนเงิน 100% จากอากาศ';

  @override
  String weatherRefundBody(String shop, String product) {
    return '$shop · $product ถูกยกเลิกเพราะอากาศ การชำระเงินจะคืนเต็มจำนวน';
  }

  @override
  String get weatherRefundAck => 'ตกลง';

  @override
  String get bookingConfirmed => 'ยืนยันแล้ว';

  @override
  String get bookingCancelled => 'ยกเลิกแล้ว';

  @override
  String get bookingWeatherCancelled => 'อากาศ · คืน 100%';

  @override
  String get bookingCancel => 'ยกเลิกการจอง';

  @override
  String bookingCancelledRefund(int percent) {
    return 'ยกเลิก · คืน $percent%';
  }

  @override
  String refundPolicyHint(int percent) {
    return 'ยกเลิกตอนนี้คืน $percent%';
  }
}
