// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Dive Travel';

  @override
  String get homeWelcome => 'Sejauh mana lautmu sudah melebar?';

  @override
  String get homeSubtitle => 'Samudra dunia di genggamanmu.';

  @override
  String get homeProWelcome => 'Halo, instruktur PRO!';

  @override
  String get homeMapTitle => 'Peta laut globalku';

  @override
  String homeMapExplored(int count) {
    return 'Sudah menjelajah $count wilayah';
  }

  @override
  String get homeMapTip =>
      'Makin sering di satu wilayah, cahaya neon berubah emas.';

  @override
  String get homeDiveStarTitle => 'Resor Dive Star bulan ini';

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
  String get homeNextDepartures => 'Keberangkatan ini';

  @override
  String get homeLastMinuteTitle => 'Tur grup yang hampir ditutup';

  @override
  String get homeLastMinuteCrew => '다합 사흘 소셜 크루';

  @override
  String get homeLastMinuteSeat => '내일 마감 · 남은 자리 1명 · 싱글차지 없음';

  @override
  String get homeForYouTitle => 'Laut berikutnya untukmu';

  @override
  String get homeStyleFirstOcean => 'Penyelam yang membuka laut pertama';

  @override
  String get homeStyleFirstOceanBody =>
      'Belum ada stempel. Mulai dari Asia agar log dan trip nyambung.';

  @override
  String get homeStyleHomeContinent => 'Penyelam yang mendalami satu laut';

  @override
  String get homeStyleHomeContinentBody =>
      'Sudah punya laut langganan. Buka benua lain untuk melebarkan peta.';

  @override
  String get homeStyleCollector => 'Penjelajah yang mengumpulkan samudra';

  @override
  String get homeStyleCollectorBody =>
      'Sudah menginjak beberapa benua. Isi stempel yang kosong.';

  @override
  String get homeStyleDeepLocal => 'Penyelam yang kembali ke satu titik';

  @override
  String get homeStyleDeepLocalBody =>
      'Wilayah jadi emas karena penyelaman berulang. Perlebar pandangan.';

  @override
  String get homeStylePro => 'Instruktur jalur pro';

  @override
  String get homeStyleProBody =>
      'Buka benua baru dengan harga pro, tumpuk mengajar dan traveling.';

  @override
  String get homeNextOceanTitle => 'Laut yang akan dibuka';

  @override
  String homeNextOceanBody(String continent) {
    return 'Belum ada log di $continent. Mulai dari trip ini.';
  }

  @override
  String homeOpenShop(String name) {
    return 'Lihat $name';
  }

  @override
  String get homeStampsLabel => 'Stempel';

  @override
  String homeStampsProgress(int stamped, int total) {
    return '$stamped/$total benua';
  }

  @override
  String get homeBadgeLabel => 'Lencana berikutnya';

  @override
  String homeBadgeLeft(int count) {
    return '$count log lagi ke kartu metal';
  }

  @override
  String get homeBadgeDone => 'Kartu metal siap';

  @override
  String get homeChecklistLabel => 'Cek keberangkatan';

  @override
  String homeChecklistSoon(int days, String shop) {
    return '$days hari · $shop';
  }

  @override
  String get homeChecklistIdle => 'Buka daftar peralatan';

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
  String get profilePassportHint => 'Benua yang punya log mendapat stempel.';

  @override
  String get navHome => 'Beranda';

  @override
  String get navLogbook => 'Logbook';

  @override
  String get navExplore => 'Tur';

  @override
  String get navCommunity => 'Kapal sama';

  @override
  String get navProfile => 'Saya';

  @override
  String get logbookTitle => 'Logbook digital';

  @override
  String get logbookAdd => 'Tambah log';

  @override
  String get logbookEmpty => 'Belum ada catatan diving.';

  @override
  String get logbookChecklist => 'Daftar peralatan';

  @override
  String get logbookSiteLabel => 'Lokasi diving';

  @override
  String get logbookDateLabel => 'Tanggal dan waktu';

  @override
  String get logbookMemoLabel => 'Catatan singkat';

  @override
  String get logbookSelfRegisterHint =>
      'Simpan tanpa tanda tangan instruktur. Langsung jadi jurnal perjalanan.';

  @override
  String get logbookSelfRegistered => 'Jurnal perjalanan · terdaftar sendiri';

  @override
  String get logbookBriefEmpty => 'Hanya titik';

  @override
  String get logbookSlipTitle => 'Slip log baru';

  @override
  String get logbookTankRackTitle => 'Sepuluh tabung menuju kartu metal';

  @override
  String get logbookTankRackHint =>
      'Satu tabung = 10 log. Kedalaman adalah catatan, bukan lomba.';

  @override
  String get logbookCenturyTitle => '100 sampai 1.000 · bab berikutnya';

  @override
  String get logbookCenturyHint =>
      'Di 100 log, kartu metal. Warnanya berganti sampai 1.000.';

  @override
  String logbookCenturyLeft(int count, int target) {
    return '$count log lagi ke $target';
  }

  @override
  String get logbookCenturyMastered => 'Master 1.000 log';

  @override
  String get logbookJournalTitle => 'Jurnal perjalanan';

  @override
  String get logbookStatDives => 'Total dive';

  @override
  String get logbookStatDiveUnit => 'kali';

  @override
  String get logbookStatTime => 'Waktu';

  @override
  String get logbookStatRegions => 'Wilayah';

  @override
  String get logbookStatRegionUnit => 'titik';

  @override
  String get logbookMaxDepth => 'Kedalaman maks';

  @override
  String get logbookAvgDepth => 'Kedalaman rata';

  @override
  String get logbookMinutes => 'Waktu';

  @override
  String get logbookMinUnit => 'mnt';

  @override
  String get logbookSac => 'SAC';

  @override
  String get logbookSacHint =>
      'SAC memakai kedalaman rata-rata, waktu, bar terpakai, dan volume tabung.';

  @override
  String get logbookMix => 'Gas';

  @override
  String get logbookMixAir => '21% AIR';

  @override
  String get logbookMixNx32 => '32% NITROX';

  @override
  String get logbookMixNx36 => '36% NITROX';

  @override
  String get logbookPressure => 'Tekanan';

  @override
  String get logbookStartBar => 'Awal (bar)';

  @override
  String get logbookEndBar => 'Akhir (bar)';

  @override
  String get logbookTankLiters => 'Tabung (L)';

  @override
  String get logbookTemp => 'Suhu';

  @override
  String get logbookAirLeft => 'Sisa udara';

  @override
  String get logbookSave => 'Simpan';

  @override
  String get logbookEdit => 'Ubah';

  @override
  String get logbookUpdated => 'Log diperbarui.';

  @override
  String get logbookSaved =>
      'Log tersimpan. Peta dan gauge tabung akan diperbarui.';

  @override
  String get logbookPhotoSection => 'Foto tes bawah laut';

  @override
  String get logbookPhotoHint =>
      'Pilih dari galeri atau komputer, atau pakai foto tes.';

  @override
  String get logbookAttachPhoto => 'Pilih dari perangkat';

  @override
  String get logbookUseTestPhoto => 'Pakai foto tes';

  @override
  String logbookPhotoPicked(String fileName) {
    return 'Dilampirkan: $fileName';
  }

  @override
  String get logbookPhotoRemove => 'Hapus foto';

  @override
  String get logbookPhotoMissingConfig =>
      'Isi kunci Cloudflare R2 di r2_config.dart untuk mengunggah foto.';

  @override
  String get logbookUploading => 'Mengunggah...';

  @override
  String get checklistTitle => 'Daftar peralatan sebelum berangkat';

  @override
  String get exploreTitle => 'Pesan tur';

  @override
  String get exploreConsumerPrice => 'Harga umum';

  @override
  String get exploreProPrice => 'Harga pro';

  @override
  String get exploreSearchHint => 'Cari resor, situs, negara';

  @override
  String get exploreFilterAll => 'Semua';

  @override
  String get exploreContinentAsia => 'Asia';

  @override
  String get exploreContinentAfrica => 'Afrika';

  @override
  String get exploreContinentOceania => 'Oseania';

  @override
  String get exploreContinentAmericas => 'Amerika';

  @override
  String get exploreContinentEurope => 'Eropa';

  @override
  String get exploreContinentPolar => 'Kutub';

  @override
  String get exploreProBanner =>
      'Instruktur terverifikasi · semua harga profesional';

  @override
  String get exploreConsumerBanner => 'Harga tamu · pesan dengan bayar in-app';

  @override
  String get exploreBook => 'Pesan';

  @override
  String get optionBookPackage => '이 상품 예약';

  @override
  String get optionBookAddon => '이 구성 더해 예약';

  @override
  String get optionBookIndividual => '이 구성만 예약';

  @override
  String get explorePay => 'Minta kursi';

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
    return 'Dihost $shop';
  }

  @override
  String get exploreListingSites => 'Titik selam di laut ini';

  @override
  String get exploreListingAmenities => 'Yang ditawarkan trip ini';

  @override
  String get exploreListingSafetyTitle => 'Laut yang mengutamakan keselamatan';

  @override
  String get exploreListingSafetyBody =>
      'Kedalaman bukan pamer. Guide, kapal, dan alat dulu.';

  @override
  String get exploreRareFind => 'Resor Dive Star yang langka';

  @override
  String get exploreRareFindBody =>
      'Bintang dari ulasan operasi. Kunci tanggal dulu.';

  @override
  String get exploreWontChargeYet =>
      'Sekarang pilih tanggal. Bayar setelah shop konfirmasi.';

  @override
  String get exploreListingGuests => 'Tamu';

  @override
  String get exploreListingGuestOne => '1 penyelam';

  @override
  String get explorePerTrip => ' / trip';

  @override
  String get exploreCheckoutTitle => 'Pembayaran';

  @override
  String exploreCheckoutBody(String shop, String product) {
    return '$shop · $product';
  }

  @override
  String get exploreBookingNotSaved =>
      '자리를 확보하지 못해 예약을 만들지 않았습니다. 빈자리를 다시 확인해 주세요.';

  @override
  String exploreCheckoutDone(String label, String price) {
    return 'Memulai pembayaran in-app $label $price.';
  }

  @override
  String get sameBoatSeatConfirmed => '결제가 완료되어 자리가 확정되었습니다(테스트 결제).';

  @override
  String get exploreConsumerPayHint => 'Harga konsumen yang didaftarkan toko.';

  @override
  String get exploreNoResults => 'Tidak ada toko yang cocok.';

  @override
  String exploreDiveStar(int stars) {
    return 'Dive Star $stars';
  }

  @override
  String exploreRating(String rating, int count) {
    return '$rating · $count ulasan';
  }

  @override
  String explorePriceWon(String price) {
    return '$price KRW';
  }

  @override
  String exploreOriginalPrice(String price) {
    return 'Tamu $price KRW';
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
    return 'Keberangkatan D-$days · $shop';
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
  String get communityTitle => 'Cari buddy';

  @override
  String get communityHostMileage =>
      'Jika kru terisi dan reservasi sukses, host mendapat mil.';

  @override
  String get profileTitle => 'Halaman saya';

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
  String profileUpcomingConfirmed(String date) {
    return '예약 확정 · $date';
  }

  @override
  String get profileProBadge => 'Instruktur PRO terverifikasi';

  @override
  String get profileMasterChallenge => 'Tantangan master 100 log';

  @override
  String profileLogsProgress(int current, int target) {
    return '$current / $target';
  }

  @override
  String get profileMetalCard => 'Ajukan kartu metal';

  @override
  String get profileMetalCardHint =>
      'Capai 100 log untuk mengajukan kartu metal fisik.';

  @override
  String get profileRadarTitle => 'Stempel paspor';

  @override
  String profileRegions(int count) {
    return '$count wilayah dijelajahi';
  }

  @override
  String get metalCardDialogTitle => 'Master 100 log';

  @override
  String get metalCardDialogBody =>
      'Pengiriman kartu gratis akan terhubung di tahap 2. Ini layar perayaan untuk sekarang.';

  @override
  String get metalCardDialogClose => 'OK';

  @override
  String get authLogin => 'Masuk';

  @override
  String get authSignup => 'Daftar';

  @override
  String get authWelcome =>
      'Setelah daftar, log, Same Tide, dan booking bisa dipakai. Admin menyesuaikan tingkat sesuai aktivitas.';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Kata sandi';

  @override
  String get authPasswordHint => 'Minimal 6 karakter';

  @override
  String get authDisplayName => 'Nama';

  @override
  String get authNoAccount => 'Belum punya akun? Daftar';

  @override
  String get authHaveAccount => 'Sudah punya akun? Masuk';

  @override
  String get authErrorInvalidEmail => 'Format email tidak valid.';

  @override
  String get authErrorInvalidCredential => 'Email atau kata sandi salah.';

  @override
  String get authResetPassword => 'Kirim email reset kata sandi';

  @override
  String get authResetPasswordSent => 'Email reset kata sandi sudah dikirim.';

  @override
  String get authErrorEmailInUse => 'Email itu sudah terdaftar.';

  @override
  String get authErrorWeakPassword => 'Kata sandi minimal 6 karakter.';

  @override
  String get authErrorNetwork => 'Periksa koneksi jaringan.';

  @override
  String get authErrorGeneric => 'Gagal masuk. Coba lagi.';

  @override
  String get authErrorOperationNotAllowed =>
      'Login email/kata sandi masih mati. Aktifkan di Firebase Authentication.';

  @override
  String get authErrorFirestore =>
      'Akun dibuat, tetapi profil Firestore gagal disimpan.';

  @override
  String get profileSignOut => 'Keluar';

  @override
  String get logbookSaveFailed => 'Gagal menyimpan log.';

  @override
  String get firebaseSetupTitle => 'Firebase perlu dihubungkan';

  @override
  String get firebaseSetupBody =>
      'Buat proyek DiveTravelApp, aktifkan Email/Password dan Firestore, lalu jalankan flutterfire configure.';

  @override
  String get adminMode => 'Mode admin';

  @override
  String get adminPinTitle => 'PIN admin';

  @override
  String get adminPinHint => 'PIN 4 digit';

  @override
  String get adminPinConfirm => 'Masuk';

  @override
  String get adminPinWrong => 'PIN salah.';

  @override
  String get adminAccessDenied => 'Akun ini tidak punya akses admin.';

  @override
  String get adminDashboardTitle => 'Dasbor admin';

  @override
  String get adminDashboardSubtitle =>
      'Kendalikan verifikasi instruktur, Dive Star, dan postingan.';

  @override
  String get adminHqTitle => 'Dive Travel HQ';

  @override
  String get adminHqSubtitle => 'Konsol admin pusat';

  @override
  String get adminHqClose => 'Tutup';

  @override
  String get adminTabOverview => 'Ringkasan';

  @override
  String get adminTabMembers => 'Anggota';

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
  String get adminTabCertify => 'Sertifikasi';

  @override
  String get adminTabShops => 'Toko';

  @override
  String get adminTabOps => 'Ops';

  @override
  String get adminMetricMembers => 'Anggota';

  @override
  String get adminMetricPendingCert => 'Menunggu sertifikasi';

  @override
  String get adminMetricPlaques => 'Antrian plakat';

  @override
  String get adminMetricPosts => 'Postingan';

  @override
  String adminMetricHidden(int count) {
    return '$count disembunyikan';
  }

  @override
  String adminMetricShops(int count) {
    return '$count toko mitra';
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
  String get adminAttentionTitle => 'Perlu perhatian';

  @override
  String get adminAttentionClear => 'Tidak ada tugas mendesak.';

  @override
  String adminAttentionCertify(int count) {
    return '$count kartu instruktur menunggu';
  }

  @override
  String adminAttentionPlaque(int count) {
    return '$count plakat perlu dicek';
  }

  @override
  String adminAttentionHidden(int count) {
    return '$count postingan tersembunyi';
  }

  @override
  String get adminGradeMixTitle => 'Sebaran tingkat anggota';

  @override
  String get adminQuickActions => 'Aksi cepat';

  @override
  String get adminMembersTitle => 'Anggota';

  @override
  String get adminMembersSubtitle =>
      'Cari anggota dan atur tingkat: Silver, Gold, Diamond, atau Platinum.';

  @override
  String get adminMembersSearch => 'Cari nama atau email';

  @override
  String get adminMembersEmpty => 'Tidak ada anggota.';

  @override
  String get adminMembersGrade => 'Tingkat anggota';

  @override
  String adminMembersActivity(int logs, int regions) {
    return '$logs log · $regions wilayah';
  }

  @override
  String adminMembersSuggested(String grade) {
    return 'Saran aktivitas · $grade';
  }

  @override
  String get memberGradeSilver => 'Anggota Silver';

  @override
  String get memberGradeGold => 'Anggota Gold';

  @override
  String get memberGradeDiamond => 'Anggota Diamond';

  @override
  String get memberGradePlatinum => 'Anggota Platinum';

  @override
  String get adminInstructorsTitle => 'Persetujuan sertifikat';

  @override
  String get adminInstructorsSubtitle =>
      'Tinjau C-Card di R2. Persetujuan membuka harga pro.';

  @override
  String adminInstructorAgency(String agency) {
    return 'Lembaga · $agency';
  }

  @override
  String get adminApprove => 'Setujui';

  @override
  String get adminReject => 'Tolak';

  @override
  String get adminNoPending => 'Tidak ada pengajuan menunggu.';

  @override
  String get adminShopsTitle => 'Dive Star · toko mitra';

  @override
  String get adminPartnersGradeHint =>
      '다이브스타 등급은 관리자가 심사 양식으로 점수·게이트를 입력한 뒤 「등급 확정」할 때 부여됩니다. 수동 「등급 수정」도 가능합니다.';

  @override
  String get adminShopsSubtitle =>
      'Pantau rating, bintang, dan pengiriman plakat.';

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
  String get partnerProductPendingHint =>
      '대기 중에도 목록에서 보고 수정할 수 있고, 같은배 신청과 여행상품 노출은 관리자 승인 후입니다.';

  @override
  String get adminPlaqueQueue => 'Daftar kirim plakat fisik';

  @override
  String get adminPlaqueEmpty => 'Belum ada toko yang mencapai bintang.';

  @override
  String get adminPlaqueRequest => 'Minta plakat';

  @override
  String get adminPlaqueQueued => 'Pengiriman diminta';

  @override
  String get adminPlaqueShipped => 'Terkirim';

  @override
  String get adminPlaqueNone => 'Plakat menunggu';

  @override
  String get adminPlaqueMarkShipped => 'Tandai terkirim';

  @override
  String get adminShopMonitor => 'Monitor toko mitra dunia';

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
  String get adminPostsTitle => 'Tur & postingan buddy';

  @override
  String get adminPostsSubtitle =>
      'Tinjau produk toko dan postingan buddy. Sembunyikan atau hapus yang palsu.';

  @override
  String get adminHidePost => 'Sembunyikan';

  @override
  String get adminUnhidePost => 'Tampilkan';

  @override
  String get adminDeletePost => 'Hapus';

  @override
  String get adminEmptyPosts => 'Belum ada postingan.';

  @override
  String get adminPostTypeBuddy => 'Buddy';

  @override
  String get adminPostTypeTour => 'Tur toko';

  @override
  String get adminPostHidden => 'Tersembunyi';

  @override
  String get partnerTitle => 'Mode partner';

  @override
  String get partnerSubtitle =>
      'Edit toko, daftar tur, dan pantau pembayaran bulan ini.';

  @override
  String get partnerAccessDenied => 'Akun ini bukan partner Business.';

  @override
  String get partnerShopEdit => 'Edit profil toko';

  @override
  String get partnerShopEditHint =>
      'Simpan nama, lokasi, produk, dan kedua harga.';

  @override
  String get partnerProductForm => 'Tambah produk';

  @override
  String get partnerProductFormHint =>
      'Isi harga konsumen dan harga profesional terpisah.';

  @override
  String get partnerSettlementTitle => 'Penyelesaian bulan ini';

  @override
  String get partnerCommissionRange =>
      'Setelah biaya platform 10–15% (default 12%).';

  @override
  String get partnerGross => 'Pendapatan';

  @override
  String get partnerFee => 'Biaya';

  @override
  String get partnerNet => 'Pembayaran bersih';

  @override
  String get partnerBookingsTitle => 'Reservasi live';

  @override
  String get partnerNoBookings => 'Belum ada reservasi.';

  @override
  String get partnerShopName => 'Nama toko';

  @override
  String get partnerShopLocation => 'Lokasi';

  @override
  String get partnerDefaultProduct => 'Nama produk';

  @override
  String get partnerSave => 'Simpan';

  @override
  String get translateAction => '🌐 Terjemahkan';

  @override
  String get translateLoading => 'Menerjemahkan…';

  @override
  String get translateShowOriginal => 'Lihat asli';

  @override
  String get communityCompose => 'Tulis postingan buddy';

  @override
  String get communityPostTitle => 'Judul';

  @override
  String get communityPostBody => 'Isi';

  @override
  String get communityPostSubmit => 'Kirim';

  @override
  String get communityComments => 'Komentar';

  @override
  String get communityNoComments => 'Belum ada komentar.';

  @override
  String get communityCommentHint => 'Tulis komentar';

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
  String get communityFlagContinuePayAsk => '이미 깃발이 있어요. 결제를 이어갈까요?';

  @override
  String get communityFlagContinuePay => '결제 이어가기';

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
  String get weatherCancel => 'Batal cuaca';

  @override
  String get weatherAdminTitle => 'Hak batal cuaca';

  @override
  String get weatherAdminBody =>
      'Tandai reservasi hari itu weather_cancelled dan refund 100%.';

  @override
  String get weatherTourDate => 'Tanggal tur';

  @override
  String get weatherCancelDone =>
      'Pembatalan cuaca dan refund penuh diterapkan.';

  @override
  String get weatherRefundTitle => 'Refund 100% karena cuaca';

  @override
  String weatherRefundBody(String shop, String product) {
    return '$shop · $product dibatalkan karena cuaca. Pembayaran dikembalikan penuh.';
  }

  @override
  String get weatherRefundAck => 'OK';

  @override
  String get bookingConfirmed => 'Terkonfirmasi';

  @override
  String get bookingRequested => '예약 요청';

  @override
  String get bookingCancelled => 'Dibatalkan';

  @override
  String get bookingWeatherCancelled => 'Cuaca · refund 100%';

  @override
  String get bookingCancel => 'Batalkan reservasi';

  @override
  String bookingCancelledRefund(int percent) {
    return 'Dibatalkan · refund $percent%';
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
  String get workbenchSeatCount => '총 인원';

  @override
  String get workbenchDepartureDate => '출발일';

  @override
  String get workbenchFlagDeadline => '깃발 마감일';

  @override
  String get workbenchOpenSeatsNeedFields => '빈자리를 열려면 총 인원·출발일·깃발 마감을 넣으세요.';

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
    return 'Batalkan sekarang: refund $percent%';
  }
}
