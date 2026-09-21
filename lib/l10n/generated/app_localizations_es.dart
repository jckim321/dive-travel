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
  String get explorePay => 'Pedir plaza';

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
  String refundPolicyHint(int percent) {
    return 'Cancelar ahora: $percent% reembolso';
  }
}
