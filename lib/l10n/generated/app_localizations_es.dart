// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Dive Travel';

  @override
  String get homeWelcome => '¿Hasta dónde se ha ensanchado tu océano?';

  @override
  String get homeSubtitle => 'Los océanos del mundo en tu mano.';

  @override
  String get homeProWelcome => '¡Hola, instructor PRO!';

  @override
  String get homeMapTitle => 'Mi mapa oceánico global';

  @override
  String homeMapExplored(int count) {
    return 'Explorando $count regiones hasta ahora';
  }

  @override
  String get homeMapTip =>
      'Más inmersiones en una región convierten la luz en dorado.';

  @override
  String get homeDiveStarTitle => 'Resorts Dive Star de este mes';

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
  String get homeNextDepartures => 'Esta salida';

  @override
  String get homeLastMinuteTitle => 'Tours grupales a punto de cerrar';

  @override
  String get homeLastMinuteCrew => '다합 사흘 소셜 크루';

  @override
  String get homeLastMinuteSeat => '내일 마감 · 남은 자리 1명 · 싱글차지 없음';

  @override
  String get homeForYouTitle => 'Tu próximo océano';

  @override
  String get homeStyleFirstOcean => 'Un buceador que abre su primer océano';

  @override
  String get homeStyleFirstOceanBody =>
      'Aún no hay sellos. Empieza en Asia para unir el log y el viaje.';

  @override
  String get homeStyleHomeContinent => 'Un buceador que profundiza un océano';

  @override
  String get homeStyleHomeContinentBody =>
      'Ya tienes un mar de casa. Abre otro continente y ensancha el mapa.';

  @override
  String get homeStyleCollector => 'Un explorador que colecciona océanos';

  @override
  String get homeStyleCollectorBody =>
      'Ya pisaste varios continentes. Llena las páginas vacías.';

  @override
  String get homeStyleDeepLocal => 'Un buceador que vuelve al mismo sitio';

  @override
  String get homeStyleDeepLocalBody =>
      'Una región se volvió oro por inmersiones repetidas. Amplía la vista.';

  @override
  String get homeStylePro => 'Instructor de ruta PRO';

  @override
  String get homeStyleProBody =>
      'Abre un continente nuevo con precio pro y suma enseñanza y viaje.';

  @override
  String get homeNextOceanTitle => 'Próximo océano a abrir';

  @override
  String homeNextOceanBody(String continent) {
    return 'Aún no hay logs en $continent. Empieza con este viaje.';
  }

  @override
  String homeOpenShop(String name) {
    return 'Ver $name';
  }

  @override
  String get homeStampsLabel => 'Sellos';

  @override
  String homeStampsProgress(int stamped, int total) {
    return '$stamped/$total continentes';
  }

  @override
  String get homeBadgeLabel => 'Siguiente insignia';

  @override
  String homeBadgeLeft(int count) {
    return '$count logs para la tarjeta metal';
  }

  @override
  String get homeBadgeDone => 'Tarjeta metal lista';

  @override
  String get homeChecklistLabel => 'Check de salida';

  @override
  String homeChecklistSoon(int days, String shop) {
    return '$days días · $shop';
  }

  @override
  String get homeChecklistIdle => 'Abrir lista de equipo';

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
  String get profilePassportHint => 'Cada continente con logs recibe un sello.';

  @override
  String get navHome => 'Inicio';

  @override
  String get navLogbook => 'Logbook';

  @override
  String get navExplore => 'Tours';

  @override
  String get navCommunity => 'Marea';

  @override
  String get navProfile => 'Perfil';

  @override
  String get logbookTitle => 'Logbook digital';

  @override
  String get logbookAdd => 'Añadir log';

  @override
  String get logbookEmpty => 'Aún no hay inmersiones.';

  @override
  String get logbookChecklist => 'Lista de equipo';

  @override
  String get logbookSiteLabel => 'Sitio de buceo';

  @override
  String get logbookDateLabel => 'Fecha y hora';

  @override
  String get logbookMemoLabel => 'Nota corta';

  @override
  String get logbookSelfRegisterHint =>
      'Guarda sin firma de instructor. Queda como diario de viaje.';

  @override
  String get logbookSelfRegistered => 'Diario de viaje · auto registrado';

  @override
  String get logbookBriefEmpty => 'Solo el sitio';

  @override
  String get logbookSlipTitle => 'Nueva ficha de log';

  @override
  String get logbookTankRackTitle => 'Diez tanques hasta la tarjeta metal';

  @override
  String get logbookTankRackHint =>
      'Cada tanque son 10 logs. La profundidad es un dato, no una carrera.';

  @override
  String get logbookCenturyTitle => 'De 100 a 1.000 · siguiente tramo';

  @override
  String get logbookCenturyHint =>
      'A 100 logs, la tarjeta metal. Luego el color cambia hasta 1.000.';

  @override
  String logbookCenturyLeft(int count, int target) {
    return '$count logs hasta $target';
  }

  @override
  String get logbookCenturyMastered => 'Maestro 1.000 logs';

  @override
  String get logbookJournalTitle => 'Diario de viaje';

  @override
  String get logbookStatDives => 'Inmersiones';

  @override
  String get logbookStatDiveUnit => 'dives';

  @override
  String get logbookStatTime => 'Tiempo';

  @override
  String get logbookStatRegions => 'Regiones';

  @override
  String get logbookStatRegionUnit => 'sitios';

  @override
  String get logbookMaxDepth => 'Prof. máx.';

  @override
  String get logbookAvgDepth => 'Prof. media';

  @override
  String get logbookMinutes => 'Tiempo';

  @override
  String get logbookMinUnit => 'min';

  @override
  String get logbookSac => 'SAC';

  @override
  String get logbookSacHint =>
      'El SAC usa profundidad media, tiempo, bares usados y volumen del tanque.';

  @override
  String get logbookMix => 'Mezcla';

  @override
  String get logbookMixAir => '21% AIR';

  @override
  String get logbookMixNx32 => '32% NITROX';

  @override
  String get logbookMixNx36 => '36% NITROX';

  @override
  String get logbookPressure => 'Presión';

  @override
  String get logbookStartBar => 'Inicio (bar)';

  @override
  String get logbookEndBar => 'Final (bar)';

  @override
  String get logbookTankLiters => 'Tanque (L)';

  @override
  String get logbookTemp => 'Temp.';

  @override
  String get logbookAirLeft => 'Aire restante';

  @override
  String get logbookSave => 'Guardar';

  @override
  String get logbookEdit => 'Editar';

  @override
  String get logbookUpdated => 'Log actualizado.';

  @override
  String get logbookSaved =>
      'Log guardado. El mapa y el tanque se actualizarán.';

  @override
  String get logbookPhotoSection => 'Foto de prueba';

  @override
  String get logbookPhotoHint =>
      'Elige de la galería o el ordenador, o usa la foto de prueba.';

  @override
  String get logbookAttachPhoto => 'Elegir del dispositivo';

  @override
  String get logbookUseTestPhoto => 'Usar foto de prueba';

  @override
  String logbookPhotoPicked(String fileName) {
    return 'Adjunto: $fileName';
  }

  @override
  String get logbookPhotoRemove => 'Quitar foto';

  @override
  String get logbookPhotoMissingConfig =>
      'Añade las claves de Cloudflare R2 en r2_config.dart para subir fotos.';

  @override
  String get logbookUploading => 'Subiendo...';

  @override
  String get checklistTitle => 'Lista de equipo antes del viaje';

  @override
  String get exploreTitle => 'Reservar tour';

  @override
  String get exploreConsumerPrice => 'Precio general';

  @override
  String get exploreProPrice => 'Precio pro';

  @override
  String get exploreSearchHint => 'Buscar resorts, puntos, países';

  @override
  String get exploreFilterAll => 'Todos';

  @override
  String get exploreContinentAsia => 'Asia';

  @override
  String get exploreContinentAfrica => 'África';

  @override
  String get exploreContinentOceania => 'Oceanía';

  @override
  String get exploreContinentAmericas => 'Américas';

  @override
  String get exploreContinentEurope => 'Europa';

  @override
  String get exploreContinentPolar => 'Polar';

  @override
  String get exploreProBanner =>
      'Instructor verificado · todos los precios son profesionales';

  @override
  String get exploreConsumerBanner =>
      'Precio de huésped · reserva con pago in-app';

  @override
  String get exploreBook => 'Reservar';

  @override
  String get optionBookPackage => '이 상품 예약';

  @override
  String get optionBookAddon => '이 구성 더해 예약';

  @override
  String get optionBookIndividual => '이 구성만 예약';

  @override
  String get explorePay => 'Pedir plaza';

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
    return 'Anfitrión: $shop';
  }

  @override
  String get exploreListingSites => 'Puntos de buceo';

  @override
  String get exploreListingAmenities => 'Qué incluye este viaje';

  @override
  String get exploreListingSafetyTitle => 'El mar, con seguridad primero';

  @override
  String get exploreListingSafetyBody =>
      'La profundidad no es un trofeo. Guía, barco y equipo van primero.';

  @override
  String get exploreRareFind => 'Un resort Dive Star poco común';

  @override
  String get exploreRareFindBody =>
      'Las estrellas salen de reseñas de operación. Reserva fecha.';

  @override
  String get exploreWontChargeYet =>
      'Ahora eliges la fecha. El pago sigue tras confirmar el shop.';

  @override
  String get exploreListingGuests => 'Huéspedes';

  @override
  String get exploreListingGuestOne => '1 buceador';

  @override
  String get explorePerTrip => ' / viaje';

  @override
  String get exploreCheckoutTitle => 'Pago';

  @override
  String exploreCheckoutBody(String shop, String product) {
    return '$shop · $product';
  }

  @override
  String get exploreBookingNotSaved =>
      '자리를 확보하지 못해 예약을 만들지 않았습니다. 빈자리를 다시 확인해 주세요.';

  @override
  String exploreCheckoutDone(String label, String price) {
    return 'Iniciando pago in-app de $label $price.';
  }

  @override
  String get exploreConsumerPayHint =>
      'Precio de consumidor registrado por el shop.';

  @override
  String get exploreNoResults => 'No hay shops que coincidan.';

  @override
  String exploreDiveStar(int stars) {
    return 'Dive Star $stars';
  }

  @override
  String exploreRating(String rating, int count) {
    return '$rating · $count reseñas';
  }

  @override
  String explorePriceWon(String price) {
    return '$price KRW';
  }

  @override
  String exploreOriginalPrice(String price) {
    return 'Huésped $price KRW';
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
  String exploreDepartureBanner(int days, String shop) {
    return 'Salida D-$days · $shop';
  }

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
  String get communityTitle => 'Buscar buddy';

  @override
  String get communityHostMileage =>
      'Si llenas el grupo, el anfitrión gana millas.';

  @override
  String get profileTitle => 'Mi página';

  @override
  String get profileDepartureDeskKicker => '출항 데스크';

  @override
  String get profileCraftedTripsTitle => '내가 짠 여행';

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
  String get profileProBadge => 'Instructor PRO verificado';

  @override
  String get profileMasterChallenge => 'Reto maestro de 100 logs';

  @override
  String profileLogsProgress(int current, int target) {
    return '$current / $target';
  }

  @override
  String get profileMetalCard => 'Solicitar tarjeta metal';

  @override
  String get profileMetalCardHint =>
      'Al llegar a 100 logs puedes pedir la tarjeta física.';

  @override
  String get profileRadarTitle => 'Sellos de pasaporte';

  @override
  String profileRegions(int count) {
    return '$count regiones exploradas';
  }

  @override
  String get metalCardDialogTitle => 'Maestro de 100 logs';

  @override
  String get metalCardDialogBody =>
      'El envío gratis de la tarjeta se conectará en la etapa 2. Ahora es una pantalla de celebración.';

  @override
  String get metalCardDialogClose => 'OK';

  @override
  String get authLogin => 'Iniciar sesión';

  @override
  String get authSignup => 'Registrarse';

  @override
  String get authWelcome =>
      'Al registrarte puedes usar logs, Same Tide y reservas. El administrador ajusta el nivel según la actividad.';

  @override
  String get authEmail => 'Correo';

  @override
  String get authPassword => 'Contraseña';

  @override
  String get authPasswordHint => 'Mínimo 6 caracteres';

  @override
  String get authDisplayName => 'Nombre';

  @override
  String get authNoAccount => '¿No tienes cuenta? Regístrate';

  @override
  String get authHaveAccount => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get authErrorInvalidEmail => 'El correo no es válido.';

  @override
  String get authErrorInvalidCredential => 'Correo o contraseña incorrectos.';

  @override
  String get authResetPassword => 'Enviar correo para restablecer contraseña';

  @override
  String get authResetPasswordSent => 'Correo de restablecimiento enviado.';

  @override
  String get authErrorEmailInUse => 'Ese correo ya está registrado.';

  @override
  String get authErrorWeakPassword =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get authErrorNetwork => 'Revisa la conexión de red.';

  @override
  String get authErrorGeneric => 'No se pudo iniciar sesión.';

  @override
  String get authErrorOperationNotAllowed =>
      'El inicio con email/contraseña está desactivado. Actívalo en Firebase Authentication.';

  @override
  String get authErrorFirestore =>
      'La cuenta se creó, pero no se pudo guardar el perfil en Firestore.';

  @override
  String get profileSignOut => 'Cerrar sesión';

  @override
  String get logbookSaveFailed => 'No se pudo guardar el log.';

  @override
  String get firebaseSetupTitle => 'Hace falta conectar Firebase';

  @override
  String get firebaseSetupBody =>
      'Crea el proyecto DiveTravelApp, activa Email/Password y Firestore, y ejecuta flutterfire configure.';

  @override
  String get adminMode => 'Modo admin';

  @override
  String get adminPinTitle => 'PIN de admin';

  @override
  String get adminPinHint => 'PIN de 4 dígitos';

  @override
  String get adminPinConfirm => 'Entrar';

  @override
  String get adminPinWrong => 'PIN incorrecto.';

  @override
  String get adminAccessDenied => 'Esta cuenta no tiene acceso de admin.';

  @override
  String get adminDashboardTitle => 'Panel de admin';

  @override
  String get adminDashboardSubtitle =>
      'Controla certificaciones, Dive Star y publicaciones.';

  @override
  String get adminHqTitle => 'Dive Travel HQ';

  @override
  String get adminHqSubtitle => 'Consola de administrador';

  @override
  String get adminHqClose => 'Cerrar';

  @override
  String get adminTabOverview => 'Resumen';

  @override
  String get adminTabMembers => 'Miembros';

  @override
  String get adminTabCertify => 'Certificar';

  @override
  String get adminTabShops => 'Tiendas';

  @override
  String get adminTabOps => 'Ops';

  @override
  String get adminMetricMembers => 'Miembros';

  @override
  String get adminMetricPendingCert => 'Cert. pendientes';

  @override
  String get adminMetricPlaques => 'Placas';

  @override
  String get adminMetricPosts => 'Posts';

  @override
  String adminMetricHidden(int count) {
    return '$count ocultos';
  }

  @override
  String adminMetricShops(int count) {
    return '$count tiendas';
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
  String get adminAttentionTitle => 'Atención';

  @override
  String get adminAttentionClear => 'No hay tareas urgentes.';

  @override
  String adminAttentionCertify(int count) {
    return '$count certificados pendientes';
  }

  @override
  String adminAttentionPlaque(int count) {
    return '$count placas por revisar';
  }

  @override
  String adminAttentionHidden(int count) {
    return '$count posts ocultos';
  }

  @override
  String get adminGradeMixTitle => 'Distribución de niveles';

  @override
  String get adminQuickActions => 'Acciones rápidas';

  @override
  String get adminMembersTitle => 'Miembros';

  @override
  String get adminMembersSubtitle =>
      'Consulta miembros y ajusta el nivel: miembro, especial, VIP o instructor.';

  @override
  String get adminMembersSearch => 'Buscar nombre o correo';

  @override
  String get adminMembersEmpty => 'No hay miembros.';

  @override
  String get adminMembersGrade => 'Nivel';

  @override
  String adminMembersActivity(int logs, int regions) {
    return '$logs logs · $regions regiones';
  }

  @override
  String adminMembersSuggested(String grade) {
    return 'Sugerido por actividad · $grade';
  }

  @override
  String get memberGradeMember => 'Miembro';

  @override
  String get memberGradeSpecial => 'Especial';

  @override
  String get memberGradeVip => 'VIP';

  @override
  String get memberGradeInstructor => 'Instructor';

  @override
  String get adminInstructorsTitle => 'Aprobar certificados';

  @override
  String get adminInstructorsSubtitle =>
      'Revisa C-Cards en R2. La aprobación abre precios pro.';

  @override
  String adminInstructorAgency(String agency) {
    return 'Agencia · $agency';
  }

  @override
  String get adminApprove => 'Aprobar';

  @override
  String get adminReject => 'Rechazar';

  @override
  String get adminNoPending => 'No hay solicitudes pendientes.';

  @override
  String get adminShopsTitle => 'Dive Star · tiendas';

  @override
  String get adminShopsSubtitle =>
      'Monitorea valoraciones, estrellas y envío de placas.';

  @override
  String get adminProductsTitle => '여행상품 등록';

  @override
  String get adminProductsSubtitle =>
      '등록하면 여행상품 메뉴에 최근순으로 올라갑니다. 홈 노출은 홈 큐레이션에서 고릅니다.';

  @override
  String get adminProductsTab => '상품 등록';

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
  String get productFormShopHint => '등록할 리조트(샵)를 선택하세요.';

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
  String get adminPlaqueQueue => 'Lista de envío de placas';

  @override
  String get adminPlaqueEmpty => 'Aún no hay tiendas con estrella.';

  @override
  String get adminPlaqueRequest => 'Pedir placa';

  @override
  String get adminPlaqueQueued => 'Envío solicitado';

  @override
  String get adminPlaqueShipped => 'Enviado';

  @override
  String get adminPlaqueNone => 'Placa pendiente';

  @override
  String get adminPlaqueMarkShipped => 'Marcar enviado';

  @override
  String get adminShopMonitor => 'Monitor de tiendas asociadas';

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
  String get adminPostsTitle => 'Tours y posts de buddy';

  @override
  String get adminPostsSubtitle =>
      'Revisa productos y posts. Oculta o elimina listados falsos.';

  @override
  String get adminHidePost => 'Ocultar';

  @override
  String get adminUnhidePost => 'Mostrar';

  @override
  String get adminDeletePost => 'Eliminar';

  @override
  String get adminEmptyPosts => 'No hay publicaciones.';

  @override
  String get adminPostTypeBuddy => 'Buddy';

  @override
  String get adminPostTypeTour => 'Tour de tienda';

  @override
  String get adminPostHidden => 'Oculto';

  @override
  String get partnerTitle => 'Modo partner';

  @override
  String get partnerSubtitle =>
      'Edita tu tienda, publica tours y revisa el pago del mes.';

  @override
  String get partnerAccessDenied => 'Esta cuenta no es partner Business.';

  @override
  String get partnerShopEdit => 'Editar tienda';

  @override
  String get partnerShopEditHint =>
      'Guarda nombre, ubicación, producto y ambos precios.';

  @override
  String get partnerProductForm => 'Añadir producto';

  @override
  String get partnerProductFormHint =>
      'Introduce precio de consumidor y precio profesional.';

  @override
  String get partnerSettlementTitle => 'Liquidación del mes';

  @override
  String get partnerCommissionRange =>
      'Neto de la comisión 10–15% (12% por defecto).';

  @override
  String get partnerGross => 'Ingresos';

  @override
  String get partnerFee => 'Comisión';

  @override
  String get partnerNet => 'Pago neto';

  @override
  String get partnerBookingsTitle => 'Reservas en vivo';

  @override
  String get partnerNoBookings => 'Aún no hay reservas.';

  @override
  String get partnerShopName => 'Nombre de la tienda';

  @override
  String get partnerShopLocation => 'Ubicación';

  @override
  String get partnerDefaultProduct => 'Producto';

  @override
  String get partnerSave => 'Guardar';

  @override
  String get translateAction => '🌐 Traducir';

  @override
  String get translateLoading => 'Traduciendo…';

  @override
  String get translateShowOriginal => 'Ver original';

  @override
  String get communityCompose => 'Escribir post buddy';

  @override
  String get communityPostTitle => 'Título';

  @override
  String get communityPostBody => 'Detalle';

  @override
  String get communityPostSubmit => 'Publicar';

  @override
  String get communityComments => 'Comentarios';

  @override
  String get communityNoComments => 'Sin comentarios.';

  @override
  String get communityCommentHint => 'Escribe un comentario';

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
  String get communityFlagOneSeat => '깃발은 1자리입니다. 동행은 결제에서 고릅니다.';

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
    return '이 자리는 $deadline까지 가확정입니다. 그 안에 결제하지 않으면 자리가 다시 열립니다.';
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
  String get weatherCancel => 'Cancelar por clima';

  @override
  String get weatherAdminTitle => 'Cancelación por clima';

  @override
  String get weatherAdminBody =>
      'Marca las reservas del día como weather_cancelled y reembolso 100%.';

  @override
  String get weatherTourDate => 'Fecha del tour';

  @override
  String get weatherCancelDone =>
      'Cancelación por clima y reembolso total aplicados.';

  @override
  String get weatherRefundTitle => 'Reembolso 100% por clima';

  @override
  String weatherRefundBody(String shop, String product) {
    return '$shop · $product se canceló por clima. El pago se reembolsa por completo.';
  }

  @override
  String get weatherRefundAck => 'OK';

  @override
  String get bookingConfirmed => 'Confirmada';

  @override
  String get bookingRequested => '예약 요청';

  @override
  String get bookingCancelled => 'Cancelada';

  @override
  String get bookingWeatherCancelled => 'Clima · 100% reembolso';

  @override
  String get bookingCancel => 'Cancelar reserva';

  @override
  String bookingCancelledRefund(int percent) {
    return 'Cancelada · $percent% reembolso';
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
  String get workbenchOpenSeatsNeedFields => '빈자리를 열려면 자리 수와 출발일을 넣으세요.';

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
  String get briefSectionPlace => '가는 곳';

  @override
  String get briefSectionDays => '일정';

  @override
  String get briefSectionTerms => '조건';

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
  String get checkoutBack => '이전으로';

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
    return 'Cancelar ahora: $percent% reembolso';
  }
}
