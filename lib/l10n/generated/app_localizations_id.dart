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
  String get explorePay => 'Minta kursi';

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
  String exploreCheckoutDone(String label, String price) {
    return 'Memulai pembayaran in-app $label $price.';
  }

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
  String get communityTitle => 'Cari buddy';

  @override
  String get communityHostMileage =>
      'Jika kru terisi dan reservasi sukses, host mendapat mil.';

  @override
  String get profileTitle => 'Halaman saya';

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
      'Cari anggota dan atur tingkat: anggota, khusus, VIP, atau instruktur.';

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
  String get memberGradeMember => 'Anggota';

  @override
  String get memberGradeSpecial => 'Khusus';

  @override
  String get memberGradeVip => 'VIP';

  @override
  String get memberGradeInstructor => 'Instruktur';

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
  String get adminShopsSubtitle =>
      'Pantau rating, bintang, dan pengiriman plakat.';

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
  String refundPolicyHint(int percent) {
    return 'Batalkan sekarang: refund $percent%';
  }
}
