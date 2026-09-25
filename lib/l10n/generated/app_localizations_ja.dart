// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'ダイブトラベル';

  @override
  String get homeWelcome => 'あなたの海はどこまで広がった？';

  @override
  String get homeSubtitle => '世界の海を、手のひらに。';

  @override
  String get homeProWelcome => 'こんにちは、PROインストラクター！';

  @override
  String get homeMapTitle => 'マイ・グローバル海洋マップ';

  @override
  String homeMapExplored(int count) {
    return 'これまでに$countエリアを探検中';
  }

  @override
  String get homeMapTip => '同じエリアのログが増えると、ネオンがゴールドに進化します。';

  @override
  String get homeDiveStarTitle => '今月のDive Starリゾート';

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
  String get homeNextDepartures => '今出港';

  @override
  String get homeLastMinuteTitle => '締め切り間近のソーシャルツアー';

  @override
  String get homeLastMinuteCrew => '다합 사흘 소셜 크루';

  @override
  String get homeLastMinuteSeat => '내일 마감 · 남은 자리 1명 · 싱글차지 없음';

  @override
  String get homeForYouTitle => 'あなたのための次の海';

  @override
  String get homeStyleFirstOcean => '最初の海を開くダイバー';

  @override
  String get homeStyleFirstOceanBody => 'まだスタンプがありません。アジアから始めるとログと旅がつながります。';

  @override
  String get homeStyleHomeContinent => '一つの海を深く潜るダイバー';

  @override
  String get homeStyleHomeContinentBody => 'ホームの海ができました。次は別の大陸を開いて地図を広げましょう。';

  @override
  String get homeStyleCollector => '大洋を集める探検家';

  @override
  String get homeStyleCollectorBody => 'すでに複数の大陸に足跡があります。空のスタンプを埋めましょう。';

  @override
  String get homeStyleDeepLocal => '同じポイントを深く潜るダイバー';

  @override
  String get homeStyleDeepLocalBody => '繰り返し潜ってゴールド地域になりました。次は視野を広げましょう。';

  @override
  String get homeStylePro => 'プロルートのインストラクター';

  @override
  String get homeStyleProBody => '優待価格で新しい大陸を開き、指導と探検を重ねましょう。';

  @override
  String get homeNextOceanTitle => '次に開く海';

  @override
  String homeNextOceanBody(String continent) {
    return '$continentにはまだログがありません。この商品から始めましょう。';
  }

  @override
  String homeOpenShop(String name) {
    return '$nameを見る';
  }

  @override
  String get homeStampsLabel => 'スタンプ';

  @override
  String homeStampsProgress(int stamped, int total) {
    return '$stamped/$total大陸';
  }

  @override
  String get homeBadgeLabel => '次のバッジ';

  @override
  String homeBadgeLeft(int count) {
    return 'メタルカードまで$countログ';
  }

  @override
  String get homeBadgeDone => 'メタルカード申請可';

  @override
  String get homeChecklistLabel => '出発チェック';

  @override
  String homeChecklistSoon(int days, String shop) {
    return '$days日前 · $shop';
  }

  @override
  String get homeChecklistIdle => '器材リストを開く';

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
  String get profilePassportHint => 'ログがある大陸にスタンプが押されます。';

  @override
  String get navHome => 'ホーム';

  @override
  String get navLogbook => 'ログブック';

  @override
  String get navExplore => 'ツアー予約';

  @override
  String get navCommunity => '同じ便';

  @override
  String get navProfile => 'マイページ';

  @override
  String get logbookTitle => 'デジタルログブック';

  @override
  String get logbookAdd => 'ログを追加';

  @override
  String get logbookEmpty => 'まだログがありません。';

  @override
  String get logbookChecklist => '器材チェックリスト';

  @override
  String get logbookSiteLabel => 'ダイビングした場所';

  @override
  String get logbookDateLabel => '日時';

  @override
  String get logbookMemoLabel => '一言メモ';

  @override
  String get logbookSelfRegisterHint => 'インストラクター署名なしで保存すると旅行日誌として登録されます。';

  @override
  String get logbookSelfRegistered => '旅行日誌 · 自己登録';

  @override
  String get logbookBriefEmpty => 'ポイントのみ';

  @override
  String get logbookSlipTitle => '新しいログスリップ';

  @override
  String get logbookTankRackTitle => 'メタルカードまでタンク10本';

  @override
  String get logbookTankRackHint => 'タンク1本が10ログ。水深は記録であり競争ではありません。';

  @override
  String get logbookCenturyTitle => '100から1,000 · 次の区間';

  @override
  String get logbookCenturyHint => '100でメタルカード。その先は色を変えて1,000まで続きます。';

  @override
  String logbookCenturyLeft(int count, int target) {
    return '次の$targetまで$countログ';
  }

  @override
  String get logbookCenturyMastered => '1,000ログマスター';

  @override
  String get logbookJournalTitle => '旅行日誌';

  @override
  String get logbookStatDives => '総ダイブ';

  @override
  String get logbookStatDiveUnit => '回';

  @override
  String get logbookStatTime => '累計時間';

  @override
  String get logbookStatRegions => '探検エリア';

  @override
  String get logbookStatRegionUnit => '箇所';

  @override
  String get logbookMaxDepth => '最大水深';

  @override
  String get logbookAvgDepth => '平均水深';

  @override
  String get logbookMinutes => '潜水時間';

  @override
  String get logbookMinUnit => '分';

  @override
  String get logbookSac => 'BMV';

  @override
  String get logbookSacHint => 'BMVは平均水深・時間・使用残圧・タンク容量から計算します。';

  @override
  String get logbookMix => '呼吸ガス';

  @override
  String get logbookMixAir => '21% AIR';

  @override
  String get logbookMixNx32 => '32% NITROX';

  @override
  String get logbookMixNx36 => '36% NITROX';

  @override
  String get logbookPressure => '残圧';

  @override
  String get logbookStartBar => '開始残圧 (bar)';

  @override
  String get logbookEndBar => '終了残圧 (bar)';

  @override
  String get logbookTankLiters => 'タンク容量 (L)';

  @override
  String get logbookTemp => '水温';

  @override
  String get logbookAirLeft => '残気';

  @override
  String get logbookSave => '保存';

  @override
  String get logbookEdit => '編集';

  @override
  String get logbookUpdated => 'ログを更新しました。';

  @override
  String get logbookSaved => 'ログを保存しました。地図とタンクゲージが更新されます。';

  @override
  String get logbookPhotoSection => 'テスト用水中写真';

  @override
  String get logbookPhotoHint => 'ギャラリーやパソコンから選ぶか、テスト写真を使えます。';

  @override
  String get logbookAttachPhoto => '端末から選ぶ';

  @override
  String get logbookUseTestPhoto => 'テスト写真を使う';

  @override
  String logbookPhotoPicked(String fileName) {
    return '添付: $fileName';
  }

  @override
  String get logbookPhotoRemove => '写真を外す';

  @override
  String get logbookPhotoMissingConfig =>
      '写真を上げるには r2_config.dart に Cloudflare R2 キーを入れてください。';

  @override
  String get logbookUploading => 'アップロード中...';

  @override
  String get checklistTitle => '出発前の器材チェックリスト';

  @override
  String get exploreTitle => 'ツアー予約';

  @override
  String get exploreConsumerPrice => '一般価格';

  @override
  String get exploreProPrice => 'インストラクター価格';

  @override
  String get exploreSearchHint => 'リゾート・ポイント・国を検索';

  @override
  String get exploreFilterAll => 'すべて';

  @override
  String get exploreContinentAsia => 'アジア';

  @override
  String get exploreContinentAfrica => 'アフリカ';

  @override
  String get exploreContinentOceania => 'オセアニア';

  @override
  String get exploreContinentAmericas => 'アメリカ';

  @override
  String get exploreContinentEurope => 'ヨーロッパ';

  @override
  String get exploreContinentPolar => '極地';

  @override
  String get exploreProBanner => 'インストラクター確認済み · 全商品が優待価格です';

  @override
  String get exploreConsumerBanner => '一般価格 · アプリ内決済で予約します';

  @override
  String get exploreBook => '予約する';

  @override
  String get explorePay => '座席をリクエスト';

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
    return '$shopがホストです';
  }

  @override
  String get exploreListingSites => 'この海のポイント';

  @override
  String get exploreListingAmenities => 'この旅が提供するもの';

  @override
  String get exploreListingSafetyTitle => '安全が先の海';

  @override
  String get exploreListingSafetyBody => '水深は自慢ではありません。ガイド・ボート・器材が先です。';

  @override
  String get exploreRareFind => '珍しいDive Starリゾート';

  @override
  String get exploreRareFindBody => 'オペ評価で星が付いた場所です。日付を先に押さえましょう。';

  @override
  String get exploreWontChargeYet => '今は日程だけ。支払いはショップ確定後です。';

  @override
  String get exploreListingGuests => '人数';

  @override
  String get exploreListingGuestOne => 'ダイバー1名';

  @override
  String get explorePerTrip => ' / 回';

  @override
  String get exploreCheckoutTitle => '予約決済';

  @override
  String exploreCheckoutBody(String shop, String product) {
    return '$shop · $product';
  }

  @override
  String exploreCheckoutDone(String label, String price) {
    return '$label $price円のアプリ内決済を開始します。';
  }

  @override
  String get exploreConsumerPayHint => 'ショップ登録の通常価格です。';

  @override
  String get exploreNoResults => '一致するショップがありません。';

  @override
  String exploreDiveStar(int stars) {
    return 'Dive Star $stars';
  }

  @override
  String exploreRating(String rating, int count) {
    return '$rating · 口コミ $count';
  }

  @override
  String explorePriceWon(String price) {
    return '$price원';
  }

  @override
  String exploreOriginalPrice(String price) {
    return '一般価格 $price원';
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
  String get communityTitle => 'バディ募集';

  @override
  String get communityHostMileage => 'クルーを集めて予約するとホストにマイルが入ります。';

  @override
  String get profileTitle => 'マイページ';

  @override
  String get profileProBadge => 'PROインストラクター認証済み';

  @override
  String get profileMasterChallenge => '100ログマスターチャレンジ';

  @override
  String profileLogsProgress(int current, int target) {
    return '$current / $target';
  }

  @override
  String get profileMetalCard => 'メタルカードを申請';

  @override
  String get profileMetalCardHint => '100ログで実物メタル認証カードを申請できます。';

  @override
  String get profileRadarTitle => 'パスポートスタンプ';

  @override
  String profileRegions(int count) {
    return '探検エリア $countか所';
  }

  @override
  String get metalCardDialogTitle => '100ログマスター達成';

  @override
  String get metalCardDialogBody => '実物カードの無料配送はステージ2で接続します。今は達成お祝い画面です。';

  @override
  String get metalCardDialogClose => 'OK';

  @override
  String get authLogin => 'ログイン';

  @override
  String get authSignup => '新規登録';

  @override
  String get authWelcome => '登録するとログ・同じ船・予約がすぐ使えます。等級は活動に応じて管理者が調整します。';

  @override
  String get authEmail => 'メール';

  @override
  String get authPassword => 'パスワード';

  @override
  String get authPasswordHint => '6文字以上';

  @override
  String get authDisplayName => '名前';

  @override
  String get authNoAccount => 'アカウントがない方は新規登録';

  @override
  String get authHaveAccount => 'すでにアカウントがある方はログイン';

  @override
  String get authErrorInvalidEmail => 'メール形式が正しくありません。';

  @override
  String get authErrorInvalidCredential => 'メールまたはパスワードが正しくありません。';

  @override
  String get authResetPassword => 'パスワード再設定メールを送る';

  @override
  String get authResetPasswordSent => 'パスワード再設定メールを送りました。';

  @override
  String get authErrorEmailInUse => 'すでに登録されたメールです。';

  @override
  String get authErrorWeakPassword => 'パスワードは6文字以上にしてください。';

  @override
  String get authErrorNetwork => 'ネットワーク接続を確認してください。';

  @override
  String get authErrorGeneric => 'ログインに失敗しました。';

  @override
  String get authErrorOperationNotAllowed =>
      'メール/パスワードログインが無効です。Firebase Authenticationで有効にしてください。';

  @override
  String get authErrorFirestore => 'アカウントは作成されましたが、Firestoreプロフィールを保存できませんでした。';

  @override
  String get profileSignOut => 'ログアウト';

  @override
  String get logbookSaveFailed => 'ログの保存に失敗しました。';

  @override
  String get firebaseSetupTitle => 'Firebaseの接続が必要です';

  @override
  String get firebaseSetupBody =>
      'DiveTravelAppプロジェクトを作り、Email/PasswordとFirestoreを有効にして flutterfire configure を実行してください。';

  @override
  String get adminMode => '管理者モード';

  @override
  String get adminPinTitle => '管理者PIN';

  @override
  String get adminPinHint => '4桁PIN';

  @override
  String get adminPinConfirm => '入る';

  @override
  String get adminPinWrong => 'PINが正しくありません。';

  @override
  String get adminAccessDenied => '管理者権限がありません。';

  @override
  String get adminDashboardTitle => '管理者ダッシュボード';

  @override
  String get adminDashboardSubtitle => 'インストラクター認証、Dive Starショップ、投稿を一括管理します。';

  @override
  String get adminHqTitle => 'Dive Travel HQ';

  @override
  String get adminHqSubtitle => '総括管理者コンソール';

  @override
  String get adminHqClose => '閉じる';

  @override
  String get adminTabOverview => '概況';

  @override
  String get adminTabMembers => '会員';

  @override
  String get adminTabCertify => '認証';

  @override
  String get adminTabShops => 'ショップ';

  @override
  String get adminTabOps => '運営';

  @override
  String get adminMetricMembers => '会員数';

  @override
  String get adminMetricPendingCert => '認証待ち';

  @override
  String get adminMetricPlaques => '看板待ち';

  @override
  String get adminMetricPosts => '投稿';

  @override
  String adminMetricHidden(int count) {
    return '非表示 $count';
  }

  @override
  String adminMetricShops(int count) {
    return '提携ショップ $count';
  }

  @override
  String get adminAttentionTitle => '要対応';

  @override
  String get adminAttentionClear => '緊急の待ち作業はありません。';

  @override
  String adminAttentionCertify(int count) {
    return '資格証 $count件が承認待ち';
  }

  @override
  String adminAttentionPlaque(int count) {
    return '看板発送 $count件を確認';
  }

  @override
  String adminAttentionHidden(int count) {
    return '非表示投稿 $count件';
  }

  @override
  String get adminGradeMixTitle => '会員等級の分布';

  @override
  String get adminQuickActions => 'クイック操作';

  @override
  String get adminMembersTitle => '会員管理';

  @override
  String get adminMembersSubtitle => '会員を検索し、会員・特別会員・VIP・インストラクター会員の等級を調整します。';

  @override
  String get adminMembersSearch => '名前またはメールで検索';

  @override
  String get adminMembersEmpty => '該当する会員がいません。';

  @override
  String get adminMembersGrade => '会員等級';

  @override
  String adminMembersActivity(int logs, int regions) {
    return 'ログ $logs回 · 地域 $regionsか所';
  }

  @override
  String adminMembersSuggested(String grade) {
    return '活動の参考等級 · $grade';
  }

  @override
  String get memberGradeMember => '会員';

  @override
  String get memberGradeSpecial => '特別会員';

  @override
  String get memberGradeVip => 'VIP';

  @override
  String get memberGradeInstructor => 'インストラクター会員';

  @override
  String get adminInstructorsTitle => 'インストラクター資格の承認';

  @override
  String get adminInstructorsSubtitle => 'R2のC-Cardを確認し、承認するとプロ料金が開きます。';

  @override
  String adminInstructorAgency(String agency) {
    return '発行機関 · $agency';
  }

  @override
  String get adminApprove => '承認';

  @override
  String get adminReject => '却下';

  @override
  String get adminNoPending => '承認待ちの申請はありません。';

  @override
  String get adminShopsTitle => 'Dive Star · 提携ショップ';

  @override
  String get adminShopsSubtitle => 'オペレーション評価とスター、銘板発送を監視します。';

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
  String get adminPlaqueQueue => '実物銘板の発送リスト';

  @override
  String get adminPlaqueEmpty => 'スター基準を満たしたショップはまだありません。';

  @override
  String get adminPlaqueRequest => '銘板発送を依頼';

  @override
  String get adminPlaqueQueued => '発送依頼済み';

  @override
  String get adminPlaqueShipped => '発送完了';

  @override
  String get adminPlaqueNone => '銘板待ち';

  @override
  String get adminPlaqueMarkShipped => '発送完了にする';

  @override
  String get adminShopMonitor => '世界の提携ショップ監視';

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
  String get adminPostsTitle => '商品・グループツアー検証';

  @override
  String get adminPostsSubtitle => 'ショップ商品とバディ募集を審査し、虚偽・違法投稿を非表示または削除します。';

  @override
  String get adminHidePost => '非表示';

  @override
  String get adminUnhidePost => '再表示';

  @override
  String get adminDeletePost => '削除';

  @override
  String get adminEmptyPosts => '投稿がありません。';

  @override
  String get adminPostTypeBuddy => 'バディ募集';

  @override
  String get adminPostTypeTour => 'ショップツアー';

  @override
  String get adminPostHidden => '非表示';

  @override
  String get partnerTitle => 'パートナーモード';

  @override
  String get partnerSubtitle => 'ショップ情報、ツアー商品、今月の精算を管理します。';

  @override
  String get partnerAccessDenied => 'Business権限がありません。';

  @override
  String get partnerShopEdit => 'ショップ情報を編集';

  @override
  String get partnerShopEditHint => '名前、場所、基本商品と2つの価格を保存します。';

  @override
  String get partnerProductForm => '商品登録';

  @override
  String get partnerProductFormHint => '通常価格とプロ特価を別々に入力してください。';

  @override
  String get partnerSettlementTitle => '今月の精算予定';

  @override
  String get partnerCommissionRange => '手数料10〜15%（既定12%）を除いた金額です。';

  @override
  String get partnerGross => '予約売上';

  @override
  String get partnerFee => '手数料';

  @override
  String get partnerNet => '精算予定';

  @override
  String get partnerBookingsTitle => 'リアルタイム予約';

  @override
  String get partnerNoBookings => 'このショップの予約はまだありません。';

  @override
  String get partnerShopName => 'ショップ名';

  @override
  String get partnerShopLocation => '場所';

  @override
  String get partnerDefaultProduct => '商品名';

  @override
  String get partnerSave => '保存';

  @override
  String get translateAction => '🌐 翻訳を見る';

  @override
  String get translateLoading => '翻訳中…';

  @override
  String get translateShowOriginal => '原文を見る';

  @override
  String get communityCompose => 'バディ投稿';

  @override
  String get communityPostTitle => 'タイトル';

  @override
  String get communityPostBody => '本文';

  @override
  String get communityPostSubmit => '投稿';

  @override
  String get communityComments => 'コメント';

  @override
  String get communityNoComments => 'まだコメントがありません。';

  @override
  String get communityCommentHint => 'コメントを書く';

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
  String get weatherCancel => '悪天候キャンセル';

  @override
  String get weatherAdminTitle => '悪天候キャンセル権限';

  @override
  String get weatherAdminBody => 'その日の予約を weather_cancelled にし、100%返金を保証します。';

  @override
  String get weatherTourDate => 'ツアー日';

  @override
  String get weatherCancelDone => '悪天候キャンセルと全額返金を反映しました。';

  @override
  String get weatherRefundTitle => '悪天候のため100%返金';

  @override
  String weatherRefundBody(String shop, String product) {
    return '$shop · $product は悪天候でキャンセルされ、支払い/ポイントが全額返金されます。';
  }

  @override
  String get weatherRefundAck => 'OK';

  @override
  String get bookingConfirmed => '予約確定';

  @override
  String get bookingCancelled => 'キャンセル済み';

  @override
  String get bookingWeatherCancelled => '悪天候キャンセル · 100%返金';

  @override
  String get bookingCancel => '予約キャンセル';

  @override
  String bookingCancelledRefund(int percent) {
    return 'キャンセル · 返金 $percent%';
  }

  @override
  String refundPolicyHint(int percent) {
    return '今キャンセルすると返金 $percent%';
  }
}
