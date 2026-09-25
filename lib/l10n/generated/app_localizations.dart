import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_th.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ko'),
    Locale('en'),
    Locale('es'),
    Locale('id'),
    Locale('ja'),
    Locale('th'),
    Locale('zh'),
  ];

  /// 앱 이름. 앱바와 작업 전환기에 표시됩니다.
  ///
  /// In ko, this message translates to:
  /// **'다이브 트래블'**
  String get appTitle;

  /// 홈 화면 슬로건입니다.
  ///
  /// In ko, this message translates to:
  /// **'너의 바다는 어디까지 넓어졌니?'**
  String get homeWelcome;

  /// 슬로건 아래 보조 문구입니다.
  ///
  /// In ko, this message translates to:
  /// **'전 세계 바다를 내 손안에.'**
  String get homeSubtitle;

  /// 강사 인증 유저에게 보이는 홈 인포바 문구입니다.
  ///
  /// In ko, this message translates to:
  /// **'안녕하세요, PRO 강사님!'**
  String get homeProWelcome;

  /// 홈 화면 지도 영역 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'나의 글로벌 바다 개척 지도'**
  String get homeMapTitle;

  /// 방문한 고유 지역 수 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'현재까지 총 {count}개 지역 탐험 중'**
  String homeMapExplored(int count);

  /// 단골 지역 황금 마커 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'한 지역에서 다이빙 횟수가 늘어날수록 지도 위의 네온 불빛이 황금빛으로 진화합니다.'**
  String get homeMapTip;

  /// 홈 화면 다이브 스타 섹션 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'Dive Star 추천 리조트'**
  String get homeDiveStarTitle;

  /// 홈 화면 즐겨찾기·단골 섹션 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'즐겨 찾는 곳'**
  String get homeFavoritesTitle;

  /// 홈 화면 인기 리조트 섹션 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'많이 가는 곳'**
  String get homePopularTitle;

  /// 홈 섹션 우측 더보기입니다.
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get homeSeeAll;

  /// 즐겨찾기 섹션이 비었을 때 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'하트를 누르거나 로그를 남기면 단골 리조트가 여기에 모여요.'**
  String get homeFavoritesEmpty;

  /// 홈 분류 칩의 전체입니다.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get homeChipAll;

  /// 홈 분류 칩의 추천입니다.
  ///
  /// In ko, this message translates to:
  /// **'추천'**
  String get homeChipRecommended;

  /// 홈 분류 칩의 즐겨찾기입니다.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기'**
  String get homeChipFavorites;

  /// 홈 분류 칩의 인기입니다.
  ///
  /// In ko, this message translates to:
  /// **'인기'**
  String get homeChipPopular;

  /// 홈 분류 칩의 마감 임박입니다.
  ///
  /// In ko, this message translates to:
  /// **'마감임박'**
  String get homeChipLastMinute;

  /// 홈에서 빈자리가 얼마 안 남은 출발 목록 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'이번 출발'**
  String get homeNextDepartures;

  /// 홈 화면 마감 임박 피드 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'마감 임박 출발'**
  String get homeLastMinuteTitle;

  /// 마감 임박 배너 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'다합 사흘 소셜 크루'**
  String get homeLastMinuteCrew;

  /// 마감 임박 배너 보조 문구입니다.
  ///
  /// In ko, this message translates to:
  /// **'내일 마감 · 남은 자리 1명 · 싱글차지 없음'**
  String get homeLastMinuteSeat;

  /// 로그 기반 맞춤 추천 섹션 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'나를 위한 다음 바다'**
  String get homeForYouTitle;

  /// No description provided for @homeStyleFirstOcean.
  ///
  /// In ko, this message translates to:
  /// **'첫 바다를 여는 다이버'**
  String get homeStyleFirstOcean;

  /// No description provided for @homeStyleFirstOceanBody.
  ///
  /// In ko, this message translates to:
  /// **'아직 스탬프가 없습니다. 아시아부터 열면 로그와 여행이 바로 이어집니다.'**
  String get homeStyleFirstOceanBody;

  /// No description provided for @homeStyleHomeContinent.
  ///
  /// In ko, this message translates to:
  /// **'한 대륙을 깊게 파는 다이버'**
  String get homeStyleHomeContinent;

  /// No description provided for @homeStyleHomeContinentBody.
  ///
  /// In ko, this message translates to:
  /// **'단골 바다가 생겼습니다. 다음엔 다른 대륙을 열어 지도를 넓혀 보세요.'**
  String get homeStyleHomeContinentBody;

  /// No description provided for @homeStyleCollector.
  ///
  /// In ko, this message translates to:
  /// **'대양을 모으는 탐험가'**
  String get homeStyleCollector;

  /// No description provided for @homeStyleCollectorBody.
  ///
  /// In ko, this message translates to:
  /// **'이미 여러 대륙을 밟았습니다. 빈 스탬프를 채우면 여권 페이지가 완성됩니다.'**
  String get homeStyleCollectorBody;

  /// No description provided for @homeStyleDeepLocal.
  ///
  /// In ko, this message translates to:
  /// **'한 포인트를 깊게 파는 다이버'**
  String get homeStyleDeepLocal;

  /// No description provided for @homeStyleDeepLocalBody.
  ///
  /// In ko, this message translates to:
  /// **'같은 바다를 반복해 골든 지역이 됐습니다. 다음 대륙으로 시야를 넓혀 보세요.'**
  String get homeStyleDeepLocalBody;

  /// No description provided for @homeStylePro.
  ///
  /// In ko, this message translates to:
  /// **'프로 루트의 강사'**
  String get homeStylePro;

  /// No description provided for @homeStyleProBody.
  ///
  /// In ko, this message translates to:
  /// **'우대 단가로 새 대륙을 열어 보세요. 수업과 탐험을 같이 쌓을 수 있습니다.'**
  String get homeStyleProBody;

  /// No description provided for @homeNextOceanTitle.
  ///
  /// In ko, this message translates to:
  /// **'다음에 열 바다'**
  String get homeNextOceanTitle;

  /// No description provided for @homeNextOceanBody.
  ///
  /// In ko, this message translates to:
  /// **'{continent}에 아직 로그가 없습니다. 이 상품부터 열어 보세요.'**
  String homeNextOceanBody(String continent);

  /// No description provided for @homeOpenShop.
  ///
  /// In ko, this message translates to:
  /// **'{name} 상품 보기'**
  String homeOpenShop(String name);

  /// No description provided for @homeStampsLabel.
  ///
  /// In ko, this message translates to:
  /// **'여권 스탬프'**
  String get homeStampsLabel;

  /// No description provided for @homeStampsProgress.
  ///
  /// In ko, this message translates to:
  /// **'{stamped}/{total} 나라'**
  String homeStampsProgress(int stamped, int total);

  /// No description provided for @homeBadgeLabel.
  ///
  /// In ko, this message translates to:
  /// **'다음 뱃지'**
  String get homeBadgeLabel;

  /// No description provided for @homeBadgeLeft.
  ///
  /// In ko, this message translates to:
  /// **'메탈 카드까지 {count}로그'**
  String homeBadgeLeft(int count);

  /// No description provided for @homeBadgeDone.
  ///
  /// In ko, this message translates to:
  /// **'메탈 카드 신청 가능'**
  String get homeBadgeDone;

  /// No description provided for @homeChecklistLabel.
  ///
  /// In ko, this message translates to:
  /// **'출국 체크'**
  String get homeChecklistLabel;

  /// No description provided for @homeChecklistSoon.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 전 · {shop}'**
  String homeChecklistSoon(int days, String shop);

  /// No description provided for @homeChecklistIdle.
  ///
  /// In ko, this message translates to:
  /// **'장비 리스트 열어보기'**
  String get homeChecklistIdle;

  /// No description provided for @passportCoverNation.
  ///
  /// In ko, this message translates to:
  /// **'오션 공화국'**
  String get passportCoverNation;

  /// No description provided for @passportCoverType.
  ///
  /// In ko, this message translates to:
  /// **'여권'**
  String get passportCoverType;

  /// No description provided for @passportOpenHint.
  ///
  /// In ko, this message translates to:
  /// **'표지를 눌러 여권을 펼치세요.'**
  String get passportOpenHint;

  /// No description provided for @passportCloseHint.
  ///
  /// In ko, this message translates to:
  /// **'다시 누르면 표지가 닫힙니다.'**
  String get passportCloseHint;

  /// No description provided for @passportVisaTitle.
  ///
  /// In ko, this message translates to:
  /// **'입국 스탬프'**
  String get passportVisaTitle;

  /// No description provided for @passportEntryGranted.
  ///
  /// In ko, this message translates to:
  /// **'입국'**
  String get passportEntryGranted;

  /// No description provided for @passportAwaiting.
  ///
  /// In ko, this message translates to:
  /// **'미입국'**
  String get passportAwaiting;

  /// No description provided for @passportPageIndex.
  ///
  /// In ko, this message translates to:
  /// **'{current} / {total} 페이지'**
  String passportPageIndex(int current, int total);

  /// No description provided for @passportEmptyPage.
  ///
  /// In ko, this message translates to:
  /// **'이 페이지는 아직 비어 있습니다. 로그가 쌓이면 스탬프가 생깁니다.'**
  String get passportEmptyPage;

  /// No description provided for @profilePassportHint.
  ///
  /// In ko, this message translates to:
  /// **'표지를 누르면 여권이 펼쳐지고, 로그가 있는 나라에 스탬프가 찍힙니다.'**
  String get profilePassportHint;

  /// 하단 내비게이션의 홈 탭 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get navHome;

  /// 하단 내비게이션의 로그북 탭 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'로그북'**
  String get navLogbook;

  /// 하단 내비게이션의 여행상품 탭 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'여행상품'**
  String get navExplore;

  /// 하단 내비게이션의 같은배 탭 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'같은배'**
  String get navCommunity;

  /// 하단 내비게이션의 마이페이지 탭 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'마이'**
  String get navProfile;

  /// 로그북 화면 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'디지털 로그북'**
  String get logbookTitle;

  /// 로그북 추가 버튼 문구입니다.
  ///
  /// In ko, this message translates to:
  /// **'로그 추가'**
  String get logbookAdd;

  /// 로그 목록이 비었을 때 문구입니다.
  ///
  /// In ko, this message translates to:
  /// **'아직 기록한 로그가 없습니다.'**
  String get logbookEmpty;

  /// 장비 체크리스트 화면 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'장비 체크리스트'**
  String get logbookChecklist;

  /// 로그 입력 폼의 장소 필드 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'다이빙한 장소'**
  String get logbookSiteLabel;

  /// 로그 입력 폼의 날짜 필드 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'다이빙 날짜와 시간'**
  String get logbookDateLabel;

  /// 로그 입력 폼의 메모 필드 이름입니다.
  ///
  /// In ko, this message translates to:
  /// **'한 줄 메모'**
  String get logbookMemoLabel;

  /// No description provided for @logbookSelfRegisterHint.
  ///
  /// In ko, this message translates to:
  /// **'강사 서명 없이 저장하면 여행 일지로 바로 자체 등록됩니다.'**
  String get logbookSelfRegisterHint;

  /// No description provided for @logbookSelfRegistered.
  ///
  /// In ko, this message translates to:
  /// **'여행 일지 · 자체 등록'**
  String get logbookSelfRegistered;

  /// No description provided for @logbookBriefEmpty.
  ///
  /// In ko, this message translates to:
  /// **'장소만 기록됨'**
  String get logbookBriefEmpty;

  /// No description provided for @logbookSlipTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 로그 슬립'**
  String get logbookSlipTitle;

  /// No description provided for @logbookTankRackTitle.
  ///
  /// In ko, this message translates to:
  /// **'메탈 카드까지, 탱크 10개'**
  String get logbookTankRackTitle;

  /// No description provided for @logbookTankRackHint.
  ///
  /// In ko, this message translates to:
  /// **'탱크 하나당 10로그. 수심 경쟁이 아니라 기록이 차오릅니다.'**
  String get logbookTankRackHint;

  /// No description provided for @logbookCenturyTitle.
  ///
  /// In ko, this message translates to:
  /// **'100부터 1,000 · 다음 구간'**
  String get logbookCenturyTitle;

  /// No description provided for @logbookCenturyHint.
  ///
  /// In ko, this message translates to:
  /// **'다이버는 100에서 메탈 카드, 강사 코스는 색이 바뀌며 1,000까지 이어집니다.'**
  String get logbookCenturyHint;

  /// No description provided for @logbookCenturyLeft.
  ///
  /// In ko, this message translates to:
  /// **'다음 {target}까지 {count}로그'**
  String logbookCenturyLeft(int count, int target);

  /// No description provided for @logbookCenturyMastered.
  ///
  /// In ko, this message translates to:
  /// **'1,000로그 마스터'**
  String get logbookCenturyMastered;

  /// No description provided for @logbookJournalTitle.
  ///
  /// In ko, this message translates to:
  /// **'여행 일지'**
  String get logbookJournalTitle;

  /// No description provided for @logbookStatDives.
  ///
  /// In ko, this message translates to:
  /// **'총 다이빙'**
  String get logbookStatDives;

  /// No description provided for @logbookStatDiveUnit.
  ///
  /// In ko, this message translates to:
  /// **'회'**
  String get logbookStatDiveUnit;

  /// No description provided for @logbookStatTime.
  ///
  /// In ko, this message translates to:
  /// **'누적 시간'**
  String get logbookStatTime;

  /// No description provided for @logbookStatRegions.
  ///
  /// In ko, this message translates to:
  /// **'탐험 지역'**
  String get logbookStatRegions;

  /// No description provided for @logbookStatRegionUnit.
  ///
  /// In ko, this message translates to:
  /// **'곳'**
  String get logbookStatRegionUnit;

  /// No description provided for @logbookMaxDepth.
  ///
  /// In ko, this message translates to:
  /// **'최대 수심'**
  String get logbookMaxDepth;

  /// No description provided for @logbookAvgDepth.
  ///
  /// In ko, this message translates to:
  /// **'평균 수심'**
  String get logbookAvgDepth;

  /// No description provided for @logbookMinutes.
  ///
  /// In ko, this message translates to:
  /// **'잠수 시간'**
  String get logbookMinutes;

  /// No description provided for @logbookMinUnit.
  ///
  /// In ko, this message translates to:
  /// **'분'**
  String get logbookMinUnit;

  /// No description provided for @logbookSac.
  ///
  /// In ko, this message translates to:
  /// **'BMV'**
  String get logbookSac;

  /// No description provided for @logbookSacHint.
  ///
  /// In ko, this message translates to:
  /// **'BMV는 평균수심·시간·사용잔압·탱크용량으로 계산합니다. 평균이 비면 최대수심을 씁니다. 수심은 기록이니 깊게 갈 필요는 없습니다.'**
  String get logbookSacHint;

  /// No description provided for @logbookMix.
  ///
  /// In ko, this message translates to:
  /// **'호흡 기체'**
  String get logbookMix;

  /// No description provided for @logbookMixAir.
  ///
  /// In ko, this message translates to:
  /// **'21% AIR'**
  String get logbookMixAir;

  /// No description provided for @logbookMixNx32.
  ///
  /// In ko, this message translates to:
  /// **'32% NITROX'**
  String get logbookMixNx32;

  /// No description provided for @logbookMixNx36.
  ///
  /// In ko, this message translates to:
  /// **'36% NITROX'**
  String get logbookMixNx36;

  /// No description provided for @logbookPressure.
  ///
  /// In ko, this message translates to:
  /// **'잔압'**
  String get logbookPressure;

  /// No description provided for @logbookStartBar.
  ///
  /// In ko, this message translates to:
  /// **'시작 잔압 (bar)'**
  String get logbookStartBar;

  /// No description provided for @logbookEndBar.
  ///
  /// In ko, this message translates to:
  /// **'종료 잔압 (bar)'**
  String get logbookEndBar;

  /// No description provided for @logbookTankLiters.
  ///
  /// In ko, this message translates to:
  /// **'탱크 용량 (L)'**
  String get logbookTankLiters;

  /// No description provided for @logbookTemp.
  ///
  /// In ko, this message translates to:
  /// **'수온'**
  String get logbookTemp;

  /// No description provided for @logbookAirLeft.
  ///
  /// In ko, this message translates to:
  /// **'남은 공기'**
  String get logbookAirLeft;

  /// 로그 저장 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get logbookSave;

  /// No description provided for @logbookEdit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get logbookEdit;

  /// No description provided for @logbookUpdated.
  ///
  /// In ko, this message translates to:
  /// **'로그를 수정했습니다. 지도와 일지가 갱신됩니다.'**
  String get logbookUpdated;

  /// 로그 저장 성공 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'로그를 저장했습니다. 지도와 산소통이 갱신됩니다.'**
  String get logbookSaved;

  /// 로그 작성 화면의 사진 첨부 영역 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'테스트용 수중 사진'**
  String get logbookPhotoSection;

  /// 사진 첨부 안내 문구입니다.
  ///
  /// In ko, this message translates to:
  /// **'갤러리·컴퓨터에서 고르거나, 테스트 사진을 바로 넣을 수 있습니다.'**
  String get logbookPhotoHint;

  /// 로그 작성 화면의 갤러리/파일 사진 첨부 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'기기에서 사진 고르기'**
  String get logbookAttachPhoto;

  /// 앱에 들어 있는 샘플 사진을 첨부하는 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'테스트 사진 사용'**
  String get logbookUseTestPhoto;

  /// 선택한 사진 파일 이름 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'첨부됨: {fileName}'**
  String logbookPhotoPicked(String fileName);

  /// 첨부한 사진을 제거하는 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'사진 제거'**
  String get logbookPhotoRemove;

  /// R2 인증값이 비어 있을 때 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'Cloudflare R2 Access Key 또는 Account ID가 없습니다. lib/core/config/r2_secrets.dart를 확인해 주세요.'**
  String get logbookPhotoMissingConfig;

  /// 사진 업로드와 로그 저장이 진행 중일 때 버튼 문구입니다.
  ///
  /// In ko, this message translates to:
  /// **'업로드 중...'**
  String get logbookUploading;

  /// 체크리스트 화면 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'출국 전 장비 체크리스트'**
  String get checklistTitle;

  /// 여행상품 화면 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'여행상품'**
  String get exploreTitle;

  /// 일반 다이버에게 보이는 가격 라벨입니다.
  ///
  /// In ko, this message translates to:
  /// **'소비자가'**
  String get exploreConsumerPrice;

  /// 강사에게 보이는 가격 라벨입니다.
  ///
  /// In ko, this message translates to:
  /// **'강사 우대가'**
  String get exploreProPrice;

  /// 투어 예약 검색 필드 힌트입니다.
  ///
  /// In ko, this message translates to:
  /// **'리조트, 포인트, 국가 검색'**
  String get exploreSearchHint;

  /// 대륙 필터의 전체 칩입니다.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get exploreFilterAll;

  /// No description provided for @exploreContinentAsia.
  ///
  /// In ko, this message translates to:
  /// **'아시아'**
  String get exploreContinentAsia;

  /// No description provided for @exploreContinentAfrica.
  ///
  /// In ko, this message translates to:
  /// **'아프리카'**
  String get exploreContinentAfrica;

  /// No description provided for @exploreContinentOceania.
  ///
  /// In ko, this message translates to:
  /// **'오세아니아'**
  String get exploreContinentOceania;

  /// No description provided for @exploreContinentAmericas.
  ///
  /// In ko, this message translates to:
  /// **'아메리카'**
  String get exploreContinentAmericas;

  /// No description provided for @exploreContinentEurope.
  ///
  /// In ko, this message translates to:
  /// **'유럽'**
  String get exploreContinentEurope;

  /// No description provided for @exploreContinentPolar.
  ///
  /// In ko, this message translates to:
  /// **'극지'**
  String get exploreContinentPolar;

  /// 강사 세션에서 예약 화면에 보이는 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'강사 자격 확인됨 · 모든 상품이 강사 우대가로 표시됩니다'**
  String get exploreProBanner;

  /// 일반 다이버 세션에서 예약 화면에 보이는 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'일반 다이버 가격 · 자리를 요청하면 샵 확정 후 결제합니다'**
  String get exploreConsumerBanner;

  /// 샵 카드의 예약 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'예약하기'**
  String get exploreBook;

  /// 체크아웃 시트의 자리 요청 버튼입니다. 결제는 샵 확정 후입니다.
  ///
  /// In ko, this message translates to:
  /// **'자리 요청'**
  String get explorePay;

  /// No description provided for @exploreDepartureLine.
  ///
  /// In ko, this message translates to:
  /// **'{window} · 빈자리 {seats}'**
  String exploreDepartureLine(String window, int seats);

  /// No description provided for @exploreDepartureBody.
  ///
  /// In ko, this message translates to:
  /// **'이 출발에 빈자리 {empty} / 정원 {capacity}입니다. 깃발을 올리면 같은 배에 탑니다.'**
  String exploreDepartureBody(int empty, int capacity);

  /// No description provided for @exploreWeatherRefundTitle.
  ///
  /// In ko, this message translates to:
  /// **'기상 취소 전액 환불'**
  String get exploreWeatherRefundTitle;

  /// No description provided for @exploreWeatherRefundBody.
  ///
  /// In ko, this message translates to:
  /// **'샵이 날씨로 출항을 취소하면 결제한 금액 전액을 돌려드립니다. 이건 마케팅 문구가 아니라 상품 조건입니다.'**
  String get exploreWeatherRefundBody;

  /// No description provided for @exploreHostedBy.
  ///
  /// In ko, this message translates to:
  /// **'{shop}가 운영합니다'**
  String exploreHostedBy(String shop);

  /// No description provided for @exploreListingSites.
  ///
  /// In ko, this message translates to:
  /// **'이 바다의 다이브 포인트'**
  String get exploreListingSites;

  /// No description provided for @exploreListingAmenities.
  ///
  /// In ko, this message translates to:
  /// **'이 상품이 제공하는 것'**
  String get exploreListingAmenities;

  /// No description provided for @exploreListingSafetyTitle.
  ///
  /// In ko, this message translates to:
  /// **'안전이 먼저인 바다'**
  String get exploreListingSafetyTitle;

  /// No description provided for @exploreListingSafetyBody.
  ///
  /// In ko, this message translates to:
  /// **'수심은 자랑이 아닙니다. 가이드·보트·장비가 먼저이고, 깊이 경쟁은 하지 않습니다.'**
  String get exploreListingSafetyBody;

  /// No description provided for @exploreRareFind.
  ///
  /// In ko, this message translates to:
  /// **'흔치 않은 Dive Star 리조트'**
  String get exploreRareFind;

  /// No description provided for @exploreRareFindBody.
  ///
  /// In ko, this message translates to:
  /// **'오퍼레이션 후기로 별이 붙은 곳입니다. 인기 포인트는 날짜를 먼저 잡아 두세요.'**
  String get exploreRareFindBody;

  /// No description provided for @exploreWontChargeYet.
  ///
  /// In ko, this message translates to:
  /// **'지금은 일정을 잡고, 결제는 샵 확정 후 진행됩니다.'**
  String get exploreWontChargeYet;

  /// No description provided for @exploreListingGuests.
  ///
  /// In ko, this message translates to:
  /// **'인원'**
  String get exploreListingGuests;

  /// No description provided for @exploreListingGuestOne.
  ///
  /// In ko, this message translates to:
  /// **'다이버 1명'**
  String get exploreListingGuestOne;

  /// No description provided for @explorePerTrip.
  ///
  /// In ko, this message translates to:
  /// **' / 회'**
  String get explorePerTrip;

  /// 인앱 결제 시트 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'예약 결제'**
  String get exploreCheckoutTitle;

  /// 결제 시트에 보이는 상품 요약입니다.
  ///
  /// In ko, this message translates to:
  /// **'{shop} · {product}'**
  String exploreCheckoutBody(String shop, String product);

  /// 결제 버튼을 눌렀을 때 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'{label} {price}원 자리 요청을 샵에 전달했습니다.'**
  String exploreCheckoutDone(String label, String price);

  /// 일반 다이버 결제 시트 보조 문구입니다.
  ///
  /// In ko, this message translates to:
  /// **'샵이 등록한 정상 소비자가입니다.'**
  String get exploreConsumerPayHint;

  /// 검색 결과가 없을 때 문구입니다.
  ///
  /// In ko, this message translates to:
  /// **'검색과 일치하는 샵이 없습니다.'**
  String get exploreNoResults;

  /// 샵 카드의 Dive Star 배지입니다.
  ///
  /// In ko, this message translates to:
  /// **'Dive Star {stars}'**
  String exploreDiveStar(int stars);

  /// 샵 평점과 후기 수입니다.
  ///
  /// In ko, this message translates to:
  /// **'{rating} · 후기 {count}'**
  String exploreRating(String rating, int count);

  /// 원화 가격 표시입니다.
  ///
  /// In ko, this message translates to:
  /// **'{price}원'**
  String explorePriceWon(String price);

  /// 강사 우대가일 때 그어 보이는 소비자가입니다.
  ///
  /// In ko, this message translates to:
  /// **'소비자가 {price}원'**
  String exploreOriginalPrice(String price);

  /// 오퍼레이션 리뷰가 아직 없을 때 Dive Star 자리 표시입니다.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 집계 전'**
  String get exploreStarPending;

  /// 리뷰가 없는 여행상품 이미지 뱃지입니다.
  ///
  /// In ko, this message translates to:
  /// **'신규'**
  String get exploreListingNew;

  /// 리뷰는 있으나 Dive Star 인증 전인 상품 뱃지입니다.
  ///
  /// In ko, this message translates to:
  /// **'리뷰평가전'**
  String get exploreListingPendingReview;

  /// Dive Star를 받은 상품 이미지 표식입니다.
  ///
  /// In ko, this message translates to:
  /// **'다이브스타 인증'**
  String get exploreDiveStarCertified;

  /// 리조트 카드에서 상세로 들어가는 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'리조트 보기'**
  String get exploreViewListing;

  /// 리조트 카드에서 상품 목록으로 들어가는 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'상품 고르기'**
  String get exploreBuyNow;

  /// No description provided for @exploreResortCardLine.
  ///
  /// In ko, this message translates to:
  /// **'{location} · 상품 {count}개'**
  String exploreResortCardLine(String location, int count);

  /// 투어 탭의 결제 완료 예약 목록 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'내 예약'**
  String get exploreMyBookings;

  /// 3대 항목 별점 화면 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'오퍼레이션 리뷰'**
  String get reviewTitle;

  /// No description provided for @reviewIntro.
  ///
  /// In ko, this message translates to:
  /// **'다녀온 샵의 안전·가이드·보트를 평가하면 Dive Star가 다시 계산됩니다.'**
  String get reviewIntro;

  /// No description provided for @reviewShopLabel.
  ///
  /// In ko, this message translates to:
  /// **'리조트 / 다이브샵'**
  String get reviewShopLabel;

  /// No description provided for @reviewSafety.
  ///
  /// In ko, this message translates to:
  /// **'① 안전 및 장비 관리'**
  String get reviewSafety;

  /// No description provided for @reviewGuide.
  ///
  /// In ko, this message translates to:
  /// **'② 가이드 전문성'**
  String get reviewGuide;

  /// No description provided for @reviewBoat.
  ///
  /// In ko, this message translates to:
  /// **'③ 보트 및 편의시설'**
  String get reviewBoat;

  /// No description provided for @reviewComment.
  ///
  /// In ko, this message translates to:
  /// **'한 줄 후기 (선택)'**
  String get reviewComment;

  /// No description provided for @reviewSubmit.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 등록'**
  String get reviewSubmit;

  /// No description provided for @reviewWrite.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 작성'**
  String get reviewWrite;

  /// No description provided for @reviewDone.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 완료'**
  String get reviewDone;

  /// No description provided for @reviewSaved.
  ///
  /// In ko, this message translates to:
  /// **'리뷰가 반영되었습니다. Dive Star가 갱신됩니다.'**
  String get reviewSaved;

  /// No description provided for @reviewSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 저장에 실패했습니다.'**
  String get reviewSaveFailed;

  /// 홈 추천 리조트 서브타이틀입니다.
  ///
  /// In ko, this message translates to:
  /// **'오퍼레이션 평균 {rating} · 리뷰 {count}건'**
  String homeDiveStarSubtitle(String rating, int count);

  /// 마이페이지 C-Card 인증 섹션 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'강사 프로 자격증 인증'**
  String get proTitle;

  /// No description provided for @proBody.
  ///
  /// In ko, this message translates to:
  /// **'PADI/SSI 등 강사 C-Card 사진을 올리면 관리자 검토를 기다립니다. 승인되면 예약 단가가 강사 우대가로 바뀝니다.'**
  String get proBody;

  /// No description provided for @proAgency.
  ///
  /// In ko, this message translates to:
  /// **'자격 발행 기관'**
  String get proAgency;

  /// No description provided for @proPickPhoto.
  ///
  /// In ko, this message translates to:
  /// **'C-Card 사진 첨부'**
  String get proPickPhoto;

  /// No description provided for @proSubmit.
  ///
  /// In ko, this message translates to:
  /// **'프로 인증 신청'**
  String get proSubmit;

  /// No description provided for @proSubmitDone.
  ///
  /// In ko, this message translates to:
  /// **'자격증을 올렸습니다. 인증 상태가 대기중(pending)입니다.'**
  String get proSubmitDone;

  /// No description provided for @proSubmitFailed.
  ///
  /// In ko, this message translates to:
  /// **'프로 인증 신청에 실패했습니다.'**
  String get proSubmitFailed;

  /// No description provided for @proStatusNone.
  ///
  /// In ko, this message translates to:
  /// **'미신청'**
  String get proStatusNone;

  /// No description provided for @proStatusPending.
  ///
  /// In ko, this message translates to:
  /// **'대기중 (pending)'**
  String get proStatusPending;

  /// No description provided for @proStatusRejected.
  ///
  /// In ko, this message translates to:
  /// **'반려됨'**
  String get proStatusRejected;

  /// 같은배 화면 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'같은 밀물'**
  String get communityTitle;

  /// 방장 마일리지 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'깃발을 올린 크루가 예약하면 방장에게 마일리지가 적립됩니다.'**
  String get communityHostMileage;

  /// 마이페이지 화면 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'마이페이지'**
  String get profileTitle;

  /// 강사 인증 배지 문구입니다.
  ///
  /// In ko, this message translates to:
  /// **'PRO 강사 인증됨'**
  String get profileProBadge;

  /// 산소통 게이지 섹션 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'100로그 마스터 챌린지'**
  String get profileMasterChallenge;

  /// 누적 로그 대비 목표 표시입니다.
  ///
  /// In ko, this message translates to:
  /// **'{current} / {target}'**
  String profileLogsProgress(int current, int target);

  /// 100로그 달성 시 메탈 카드 신청 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'실물 메탈 카드 신청하기'**
  String get profileMetalCard;

  /// 100로그 미만일 때 메탈 카드 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'100로그를 채우면 실물 메탈 인증 카드를 신청할 수 있습니다.'**
  String get profileMetalCardHint;

  /// 마이페이지 대륙 스탬프 섹션 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'여권 스탬프'**
  String get profileRadarTitle;

  /// 마이페이지의 고유 지역 수 표시입니다.
  ///
  /// In ko, this message translates to:
  /// **'탐험 지역 {count}곳'**
  String profileRegions(int count);

  /// 메탈 카드 팝업 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'100로그 마스터 달성'**
  String get metalCardDialogTitle;

  /// 메탈 카드 팝업 본문입니다.
  ///
  /// In ko, this message translates to:
  /// **'실물 메탈 인증 카드 무료 배송 신청은 2단계에서 연결됩니다. 지금은 달성 축하 화면입니다.'**
  String get metalCardDialogBody;

  /// 메탈 카드 팝업 닫기 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get metalCardDialogClose;

  /// 로그인 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get authLogin;

  /// 회원가입 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get authSignup;

  /// No description provided for @authWelcome.
  ///
  /// In ko, this message translates to:
  /// **'가입하면 로그, 같은배, 예약 등 기본 기능을 바로 쓸 수 있습니다. 등급은 활동에 따라 관리자가 조정합니다.'**
  String get authWelcome;

  /// 로그인 이메일 필드입니다.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get authEmail;

  /// 로그인 비밀번호 필드입니다.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get authPassword;

  /// 비밀번호 최소 길이 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'6자 이상'**
  String get authPasswordHint;

  /// 회원가입 이름 필드입니다.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get authDisplayName;

  /// 회원가입 화면으로 전환하는 문구입니다.
  ///
  /// In ko, this message translates to:
  /// **'계정이 없나요? 회원가입'**
  String get authNoAccount;

  /// 로그인 화면으로 전환하는 문구입니다.
  ///
  /// In ko, this message translates to:
  /// **'이미 계정이 있나요? 로그인'**
  String get authHaveAccount;

  /// 잘못된 이메일 오류입니다.
  ///
  /// In ko, this message translates to:
  /// **'이메일 형식이 올바르지 않습니다.'**
  String get authErrorInvalidEmail;

  /// 이미 가입된 계정인데 비밀번호가 다를 때 오류입니다.
  ///
  /// In ko, this message translates to:
  /// **'이미 가입된 이메일입니다. 처음 만든 비밀번호로 로그인해 주세요.'**
  String get authErrorInvalidCredential;

  /// 비밀번호 재설정 메일 발송 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 재설정 메일 보내기'**
  String get authResetPassword;

  /// 재설정 메일 발송 성공 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 재설정 메일을 보냈습니다. Gmail 받은편지함을 확인하세요.'**
  String get authResetPasswordSent;

  /// 중복 이메일 오류입니다.
  ///
  /// In ko, this message translates to:
  /// **'이미 가입된 이메일입니다.'**
  String get authErrorEmailInUse;

  /// 약한 비밀번호 오류입니다.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호는 6자 이상이어야 합니다.'**
  String get authErrorWeakPassword;

  /// 네트워크 오류입니다.
  ///
  /// In ko, this message translates to:
  /// **'네트워크 연결을 확인해 주세요.'**
  String get authErrorNetwork;

  /// 기타 인증 오류입니다.
  ///
  /// In ko, this message translates to:
  /// **'로그인에 실패했습니다. 잠시 후 다시 시도해 주세요.'**
  String get authErrorGeneric;

  /// Email/Password provider가 꺼져 있을 때 오류입니다.
  ///
  /// In ko, this message translates to:
  /// **'이메일/비밀번호 로그인이 아직 꺼져 있습니다. Firebase Authentication에서 사용 설정해 주세요.'**
  String get authErrorOperationNotAllowed;

  /// 가입 후 Firestore 문서 생성 실패 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'계정은 만들어졌지만 Firestore에 프로필을 쓰지 못했습니다. 콘솔에서 Firestore Database를 만들고 규칙을 붙여 주세요.'**
  String get authErrorFirestore;

  /// 로그아웃 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get profileSignOut;

  /// Firestore 로그 저장 실패 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'로그 저장에 실패했습니다. 네트워크와 Firebase 규칙을 확인해 주세요.'**
  String get logbookSaveFailed;

  /// Firebase 옵션이 없을 때 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'Firebase 연결이 필요합니다'**
  String get firebaseSetupTitle;

  /// Firebase 콘솔 설정 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'1. Firebase 콘솔에서 DiveTravelApp 프로젝트를 만듭니다.\n2. Authentication > Email/Password를 켭니다.\n3. Firestore Database를 테스트 모드로 생성합니다.\n4. 터미널에서 dart pub global activate flutterfire_cli 후 flutterfire configure 를 실행합니다.\n5. 생성된 firebase_options.dart가 들어오면 앱을 다시 실행하세요.'**
  String get firebaseSetupBody;

  /// 마이페이지·홈에서 관리자 대시보드로 들어가는 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'관리자 모드'**
  String get adminMode;

  /// 관리자 모드 PIN 입력 창 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'관리자 PIN'**
  String get adminPinTitle;

  /// No description provided for @adminPinHint.
  ///
  /// In ko, this message translates to:
  /// **'4자리 PIN'**
  String get adminPinHint;

  /// No description provided for @adminPinConfirm.
  ///
  /// In ko, this message translates to:
  /// **'입장'**
  String get adminPinConfirm;

  /// No description provided for @adminPinWrong.
  ///
  /// In ko, this message translates to:
  /// **'PIN이 올바르지 않습니다.'**
  String get adminPinWrong;

  /// No description provided for @adminAccessDenied.
  ///
  /// In ko, this message translates to:
  /// **'관리자 권한이 없는 계정입니다.'**
  String get adminAccessDenied;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In ko, this message translates to:
  /// **'관리자 대시보드'**
  String get adminDashboardTitle;

  /// No description provided for @adminDashboardSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'전 세계 강사 인증, Dive Star 샵, 게시글을 한곳에서 통제합니다.'**
  String get adminDashboardSubtitle;

  /// No description provided for @adminHqTitle.
  ///
  /// In ko, this message translates to:
  /// **'다이브 트래블 HQ'**
  String get adminHqTitle;

  /// No description provided for @adminHqSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'총괄 관리자 콘솔'**
  String get adminHqSubtitle;

  /// No description provided for @adminHqClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get adminHqClose;

  /// No description provided for @adminTabOverview.
  ///
  /// In ko, this message translates to:
  /// **'현황'**
  String get adminTabOverview;

  /// No description provided for @adminTabMembers.
  ///
  /// In ko, this message translates to:
  /// **'회원'**
  String get adminTabMembers;

  /// No description provided for @adminTabCertify.
  ///
  /// In ko, this message translates to:
  /// **'인증'**
  String get adminTabCertify;

  /// No description provided for @adminTabShops.
  ///
  /// In ko, this message translates to:
  /// **'샵'**
  String get adminTabShops;

  /// No description provided for @adminTabOps.
  ///
  /// In ko, this message translates to:
  /// **'운영'**
  String get adminTabOps;

  /// No description provided for @adminMetricMembers.
  ///
  /// In ko, this message translates to:
  /// **'전체 회원'**
  String get adminMetricMembers;

  /// No description provided for @adminMetricPendingCert.
  ///
  /// In ko, this message translates to:
  /// **'인증 대기'**
  String get adminMetricPendingCert;

  /// No description provided for @adminMetricPlaques.
  ///
  /// In ko, this message translates to:
  /// **'현판 대기'**
  String get adminMetricPlaques;

  /// No description provided for @adminMetricPosts.
  ///
  /// In ko, this message translates to:
  /// **'게시글'**
  String get adminMetricPosts;

  /// No description provided for @adminMetricHidden.
  ///
  /// In ko, this message translates to:
  /// **'숨김 {count}'**
  String adminMetricHidden(int count);

  /// No description provided for @adminMetricShops.
  ///
  /// In ko, this message translates to:
  /// **'제휴 샵 {count}곳'**
  String adminMetricShops(int count);

  /// No description provided for @adminAttentionTitle.
  ///
  /// In ko, this message translates to:
  /// **'지금 처리할 일'**
  String get adminAttentionTitle;

  /// No description provided for @adminAttentionClear.
  ///
  /// In ko, this message translates to:
  /// **'대기 중인 긴급 작업이 없습니다.'**
  String get adminAttentionClear;

  /// No description provided for @adminAttentionCertify.
  ///
  /// In ko, this message translates to:
  /// **'강사 자격증 {count}건 승인 대기'**
  String adminAttentionCertify(int count);

  /// No description provided for @adminAttentionPlaque.
  ///
  /// In ko, this message translates to:
  /// **'현판 발송 {count}건 확인 필요'**
  String adminAttentionPlaque(int count);

  /// No description provided for @adminAttentionHidden.
  ///
  /// In ko, this message translates to:
  /// **'숨긴 게시글 {count}건'**
  String adminAttentionHidden(int count);

  /// No description provided for @adminGradeMixTitle.
  ///
  /// In ko, this message translates to:
  /// **'회원 등급 분포'**
  String get adminGradeMixTitle;

  /// No description provided for @adminQuickActions.
  ///
  /// In ko, this message translates to:
  /// **'빠른 실행'**
  String get adminQuickActions;

  /// No description provided for @adminMembersTitle.
  ///
  /// In ko, this message translates to:
  /// **'회원 관리'**
  String get adminMembersTitle;

  /// No description provided for @adminMembersSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'회원을 조회하고 회원·특별회원·VIP·강사회원 등급을 조정합니다.'**
  String get adminMembersSubtitle;

  /// No description provided for @adminMembersSearch.
  ///
  /// In ko, this message translates to:
  /// **'이름 또는 이메일 검색'**
  String get adminMembersSearch;

  /// No description provided for @adminMembersEmpty.
  ///
  /// In ko, this message translates to:
  /// **'조건에 맞는 회원이 없습니다.'**
  String get adminMembersEmpty;

  /// No description provided for @adminMembersGrade.
  ///
  /// In ko, this message translates to:
  /// **'회원 등급'**
  String get adminMembersGrade;

  /// No description provided for @adminMembersActivity.
  ///
  /// In ko, this message translates to:
  /// **'로그 {logs}회 · 지역 {regions}곳'**
  String adminMembersActivity(int logs, int regions);

  /// No description provided for @adminMembersSuggested.
  ///
  /// In ko, this message translates to:
  /// **'활동 참고 등급 · {grade}'**
  String adminMembersSuggested(String grade);

  /// No description provided for @memberGradeMember.
  ///
  /// In ko, this message translates to:
  /// **'회원'**
  String get memberGradeMember;

  /// No description provided for @memberGradeSpecial.
  ///
  /// In ko, this message translates to:
  /// **'특별회원'**
  String get memberGradeSpecial;

  /// No description provided for @memberGradeVip.
  ///
  /// In ko, this message translates to:
  /// **'VIP'**
  String get memberGradeVip;

  /// No description provided for @memberGradeInstructor.
  ///
  /// In ko, this message translates to:
  /// **'강사회원'**
  String get memberGradeInstructor;

  /// No description provided for @adminInstructorsTitle.
  ///
  /// In ko, this message translates to:
  /// **'강사 자격증 승인'**
  String get adminInstructorsTitle;

  /// No description provided for @adminInstructorsSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'R2에 올라온 C-Card를 확인하고 승인하면 강사 우대가가 열립니다.'**
  String get adminInstructorsSubtitle;

  /// 대기 강사의 자격 발행 기관입니다.
  ///
  /// In ko, this message translates to:
  /// **'발행 기관 · {agency}'**
  String adminInstructorAgency(String agency);

  /// No description provided for @adminApprove.
  ///
  /// In ko, this message translates to:
  /// **'승인'**
  String get adminApprove;

  /// No description provided for @adminReject.
  ///
  /// In ko, this message translates to:
  /// **'거절'**
  String get adminReject;

  /// No description provided for @adminNoPending.
  ///
  /// In ko, this message translates to:
  /// **'대기 중인 자격증 신청이 없습니다.'**
  String get adminNoPending;

  /// No description provided for @adminShopsTitle.
  ///
  /// In ko, this message translates to:
  /// **'다이브 스타 · 제휴 샵'**
  String get adminShopsTitle;

  /// No description provided for @adminShopsSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'오퍼레이션 평점과 스타 등급, 실물 현판 발송을 모니터링합니다.'**
  String get adminShopsSubtitle;

  /// No description provided for @adminPlaqueQueue.
  ///
  /// In ko, this message translates to:
  /// **'실물 현판 발송 요청 리스트'**
  String get adminPlaqueQueue;

  /// No description provided for @adminPlaqueEmpty.
  ///
  /// In ko, this message translates to:
  /// **'스타 등급을 충족한 샵이 아직 없습니다.'**
  String get adminPlaqueEmpty;

  /// No description provided for @adminPlaqueRequest.
  ///
  /// In ko, this message translates to:
  /// **'현판 발송 요청'**
  String get adminPlaqueRequest;

  /// No description provided for @adminPlaqueQueued.
  ///
  /// In ko, this message translates to:
  /// **'발송 요청됨'**
  String get adminPlaqueQueued;

  /// No description provided for @adminPlaqueShipped.
  ///
  /// In ko, this message translates to:
  /// **'발송 완료'**
  String get adminPlaqueShipped;

  /// No description provided for @adminPlaqueNone.
  ///
  /// In ko, this message translates to:
  /// **'현판 대기'**
  String get adminPlaqueNone;

  /// No description provided for @adminPlaqueMarkShipped.
  ///
  /// In ko, this message translates to:
  /// **'발송 완료 처리'**
  String get adminPlaqueMarkShipped;

  /// No description provided for @adminShopMonitor.
  ///
  /// In ko, this message translates to:
  /// **'전 세계 제휴 샵 모니터링'**
  String get adminShopMonitor;

  /// No description provided for @adminPricingTitle.
  ///
  /// In ko, this message translates to:
  /// **'강사 할인가'**
  String get adminPricingTitle;

  /// No description provided for @adminPricingSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'일반 다이버는 소비자가, 강사는 여기서 정한 할인율 또는 정액이 적용됩니다.'**
  String get adminPricingSubtitle;

  /// No description provided for @adminPricingPercent.
  ///
  /// In ko, this message translates to:
  /// **'할인율'**
  String get adminPricingPercent;

  /// No description provided for @adminPricingAmount.
  ///
  /// In ko, this message translates to:
  /// **'할인 금액'**
  String get adminPricingAmount;

  /// No description provided for @adminPricingPercentHint.
  ///
  /// In ko, this message translates to:
  /// **'할인율 (%)'**
  String get adminPricingPercentHint;

  /// No description provided for @adminPricingAmountHint.
  ///
  /// In ko, this message translates to:
  /// **'할인 금액 (원)'**
  String get adminPricingAmountHint;

  /// No description provided for @adminPricingSave.
  ///
  /// In ko, this message translates to:
  /// **'할인가 저장'**
  String get adminPricingSave;

  /// No description provided for @adminPricingSaved.
  ///
  /// In ko, this message translates to:
  /// **'강사 할인가가 저장되었습니다.'**
  String get adminPricingSaved;

  /// No description provided for @adminPricingPreview.
  ///
  /// In ko, this message translates to:
  /// **'소비자가 {consumer}원 → 강사 {pro}원'**
  String adminPricingPreview(String consumer, String pro);

  /// No description provided for @adminPostsTitle.
  ///
  /// In ko, this message translates to:
  /// **'상품 · 그룹 투어 검증'**
  String get adminPostsTitle;

  /// No description provided for @adminPostsSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'샵 상품과 버디 모집 글을 검수하고 허위·불법 게시글을 숨기거나 삭제합니다.'**
  String get adminPostsSubtitle;

  /// No description provided for @adminHidePost.
  ///
  /// In ko, this message translates to:
  /// **'숨김'**
  String get adminHidePost;

  /// No description provided for @adminUnhidePost.
  ///
  /// In ko, this message translates to:
  /// **'숨김 해제'**
  String get adminUnhidePost;

  /// No description provided for @adminDeletePost.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get adminDeletePost;

  /// No description provided for @adminEmptyPosts.
  ///
  /// In ko, this message translates to:
  /// **'등록된 게시글이 없습니다.'**
  String get adminEmptyPosts;

  /// No description provided for @adminPostTypeBuddy.
  ///
  /// In ko, this message translates to:
  /// **'버디 모집'**
  String get adminPostTypeBuddy;

  /// No description provided for @adminPostTypeTour.
  ///
  /// In ko, this message translates to:
  /// **'샵 투어 상품'**
  String get adminPostTypeTour;

  /// No description provided for @adminPostHidden.
  ///
  /// In ko, this message translates to:
  /// **'숨김 처리됨'**
  String get adminPostHidden;

  /// 샵 사장님 전용 대시보드 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'파트너 모드'**
  String get partnerTitle;

  /// No description provided for @partnerSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'샵 정보, 투어 상품, 이번 달 예약과 정산을 한곳에서 관리합니다.'**
  String get partnerSubtitle;

  /// No description provided for @partnerAccessDenied.
  ///
  /// In ko, this message translates to:
  /// **'파트너(Business) 권한이 없는 계정입니다.'**
  String get partnerAccessDenied;

  /// No description provided for @partnerShopEdit.
  ///
  /// In ko, this message translates to:
  /// **'샵 정보 수정'**
  String get partnerShopEdit;

  /// No description provided for @partnerShopEditHint.
  ///
  /// In ko, this message translates to:
  /// **'이름, 위치, 기본 상품과 두 가지 가격을 저장합니다.'**
  String get partnerShopEditHint;

  /// No description provided for @partnerProductForm.
  ///
  /// In ko, this message translates to:
  /// **'상품 등록'**
  String get partnerProductForm;

  /// No description provided for @partnerProductFormHint.
  ///
  /// In ko, this message translates to:
  /// **'일반 소비자가와 강사 우대 특가를 따로 입력하세요.'**
  String get partnerProductFormHint;

  /// No description provided for @partnerSettlementTitle.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 정산 예정'**
  String get partnerSettlementTitle;

  /// No description provided for @partnerCommissionRange.
  ///
  /// In ko, this message translates to:
  /// **'플랫폼 수수료 10~15%(기본 12%)를 제외한 금액입니다.'**
  String get partnerCommissionRange;

  /// No description provided for @partnerGross.
  ///
  /// In ko, this message translates to:
  /// **'예약 매출'**
  String get partnerGross;

  /// No description provided for @partnerFee.
  ///
  /// In ko, this message translates to:
  /// **'수수료'**
  String get partnerFee;

  /// No description provided for @partnerNet.
  ///
  /// In ko, this message translates to:
  /// **'정산 예정'**
  String get partnerNet;

  /// No description provided for @partnerBookingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'실시간 예약 현황'**
  String get partnerBookingsTitle;

  /// No description provided for @partnerNoBookings.
  ///
  /// In ko, this message translates to:
  /// **'이번 샵으로 들어온 예약이 없습니다.'**
  String get partnerNoBookings;

  /// No description provided for @partnerShopName.
  ///
  /// In ko, this message translates to:
  /// **'샵 이름'**
  String get partnerShopName;

  /// No description provided for @partnerShopLocation.
  ///
  /// In ko, this message translates to:
  /// **'위치'**
  String get partnerShopLocation;

  /// No description provided for @partnerDefaultProduct.
  ///
  /// In ko, this message translates to:
  /// **'상품명'**
  String get partnerDefaultProduct;

  /// No description provided for @partnerSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get partnerSave;

  /// No description provided for @translateAction.
  ///
  /// In ko, this message translates to:
  /// **'🌐 번역 보기'**
  String get translateAction;

  /// No description provided for @translateLoading.
  ///
  /// In ko, this message translates to:
  /// **'번역 중…'**
  String get translateLoading;

  /// No description provided for @translateShowOriginal.
  ///
  /// In ko, this message translates to:
  /// **'원문 보기'**
  String get translateShowOriginal;

  /// No description provided for @communityCompose.
  ///
  /// In ko, this message translates to:
  /// **'깃발 올리기'**
  String get communityCompose;

  /// No description provided for @communityPostTitle.
  ///
  /// In ko, this message translates to:
  /// **'한 줄 의도'**
  String get communityPostTitle;

  /// No description provided for @communityPostBody.
  ///
  /// In ko, this message translates to:
  /// **'이 배에 타고 싶은 이유'**
  String get communityPostBody;

  /// No description provided for @communityPostSubmit.
  ///
  /// In ko, this message translates to:
  /// **'명부에 올리기'**
  String get communityPostSubmit;

  /// No description provided for @communityComments.
  ///
  /// In ko, this message translates to:
  /// **'승선 메모'**
  String get communityComments;

  /// No description provided for @communityNoComments.
  ///
  /// In ko, this message translates to:
  /// **'아직 깃발이 없습니다.'**
  String get communityNoComments;

  /// No description provided for @communityCommentHint.
  ///
  /// In ko, this message translates to:
  /// **'짧게 남기세요'**
  String get communityCommentHint;

  /// No description provided for @communityTideKicker.
  ///
  /// In ko, this message translates to:
  /// **'출발 보드'**
  String get communityTideKicker;

  /// No description provided for @communityTideHeadline.
  ///
  /// In ko, this message translates to:
  /// **'이번 주, 빈자리가 열린 배'**
  String get communityTideHeadline;

  /// No description provided for @communityTideBody.
  ///
  /// In ko, this message translates to:
  /// **'목적지·날짜·빈자리만 보고 고르세요. 물속 버디는 샵이 배정합니다.'**
  String get communityTideBody;

  /// No description provided for @communityTideSafety.
  ///
  /// In ko, this message translates to:
  /// **'물속 버디는 샵이 배정합니다. 이 탭은 이미 예약한 여행의 밴·식탁·침대를 나눕니다.'**
  String get communityTideSafety;

  /// No description provided for @communityStatOpenSeats.
  ///
  /// In ko, this message translates to:
  /// **'빈자리'**
  String get communityStatOpenSeats;

  /// No description provided for @communityUrgentBanner.
  ///
  /// In ko, this message translates to:
  /// **'마감 임박 {count}건 · 바로 보기'**
  String communityUrgentBanner(int count);

  /// No description provided for @communityBoardList.
  ///
  /// In ko, this message translates to:
  /// **'출발 명부'**
  String get communityBoardList;

  /// No description provided for @communityBoardListHint.
  ///
  /// In ko, this message translates to:
  /// **'카드를 누르면 승선 의사와 예약을 이어갈 수 있습니다.'**
  String get communityBoardListHint;

  /// No description provided for @communityViewSeats.
  ///
  /// In ko, this message translates to:
  /// **'자리 보기'**
  String get communityViewSeats;

  /// No description provided for @communityWindowOpen.
  ///
  /// In ko, this message translates to:
  /// **'일정 미정'**
  String get communityWindowOpen;

  /// No description provided for @communityPlantFlag.
  ///
  /// In ko, this message translates to:
  /// **'깃발 꽂기'**
  String get communityPlantFlag;

  /// No description provided for @communityPlantFlagAsk.
  ///
  /// In ko, this message translates to:
  /// **'이 예약을 같은배에 올려 지인이나 동호회가 조인하게 할까요?'**
  String get communityPlantFlagAsk;

  /// No description provided for @communityPlantFlagLater.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get communityPlantFlagLater;

  /// No description provided for @communityNeedBooking.
  ///
  /// In ko, this message translates to:
  /// **'깃발은 예약한 뒤에 꽂습니다. 여행상품에서 리조트를 먼저 고르세요.'**
  String get communityNeedBooking;

  /// No description provided for @communityRoomOpened.
  ///
  /// In ko, this message translates to:
  /// **'예약한 여행에 방을 열었습니다.'**
  String get communityRoomOpened;

  /// No description provided for @exploreChooseRoom.
  ///
  /// In ko, this message translates to:
  /// **'이 리조트의 상품'**
  String get exploreChooseRoom;

  /// No description provided for @exploreChooseRoomHint.
  ///
  /// In ko, this message translates to:
  /// **'호텔에서 객실을 고르듯, 원하는 다이브 상품을 고르세요.'**
  String get exploreChooseRoomHint;

  /// No description provided for @exploreResortTraits.
  ///
  /// In ko, this message translates to:
  /// **'편의시설 · 특징'**
  String get exploreResortTraits;

  /// No description provided for @exploreAmenitiesHint.
  ///
  /// In ko, this message translates to:
  /// **'쉼표로 구분 (예: Wi-Fi, 수영장, 나이트록스, 공항 픽업)'**
  String get exploreAmenitiesHint;

  /// No description provided for @exploreRecommended.
  ///
  /// In ko, this message translates to:
  /// **'추천'**
  String get exploreRecommended;

  /// No description provided for @exploreLightest.
  ///
  /// In ko, this message translates to:
  /// **'가벼운 일정'**
  String get exploreLightest;

  /// No description provided for @exploreProductRooms.
  ///
  /// In ko, this message translates to:
  /// **'이 상품에 열린 방 {count}'**
  String exploreProductRooms(int count);

  /// No description provided for @exploreResortIntro.
  ///
  /// In ko, this message translates to:
  /// **'리조트 소개'**
  String get exploreResortIntro;

  /// No description provided for @exploreResortMap.
  ///
  /// In ko, this message translates to:
  /// **'LOCATION'**
  String get exploreResortMap;

  /// No description provided for @exploreResortAddress.
  ///
  /// In ko, this message translates to:
  /// **'주소'**
  String get exploreResortAddress;

  /// No description provided for @exploreEditResort.
  ///
  /// In ko, this message translates to:
  /// **'리조트 글 수정'**
  String get exploreEditResort;

  /// No description provided for @exploreDeskHint.
  ///
  /// In ko, this message translates to:
  /// **'현지 샵과 관리자가 같은 글을 고칩니다. 저장하면 여행상품 상세에 바로 반영됩니다.'**
  String get exploreDeskHint;

  /// No description provided for @exploreOpenRooms.
  ///
  /// In ko, this message translates to:
  /// **'열린 방 {count}'**
  String exploreOpenRooms(int count);

  /// No description provided for @exploreProductDuration.
  ///
  /// In ko, this message translates to:
  /// **'소요 시간'**
  String get exploreProductDuration;

  /// No description provided for @exploreProductBlurb.
  ///
  /// In ko, this message translates to:
  /// **'상품 한 줄 소개'**
  String get exploreProductBlurb;

  /// No description provided for @exploreCoverPhoto.
  ///
  /// In ko, this message translates to:
  /// **'대표 이미지'**
  String get exploreCoverPhoto;

  /// No description provided for @exploreCoverPhotoHint.
  ///
  /// In ko, this message translates to:
  /// **'Booking.com·아고다처럼 큰 대표컷 + 작은 사진 격자로 보여 줍니다. 첫 장이 대표 이미지입니다.'**
  String get exploreCoverPhotoHint;

  /// No description provided for @exploreGalleryTitle.
  ///
  /// In ko, this message translates to:
  /// **'리조트 사진'**
  String get exploreGalleryTitle;

  /// No description provided for @exploreGalleryHint.
  ///
  /// In ko, this message translates to:
  /// **'최대 12장. 첫 장이 목록·상세의 대표 사진이 됩니다.'**
  String get exploreGalleryHint;

  /// No description provided for @exploreGalleryAdd.
  ///
  /// In ko, this message translates to:
  /// **'사진 추가'**
  String get exploreGalleryAdd;

  /// No description provided for @exploreGalleryAddMore.
  ///
  /// In ko, this message translates to:
  /// **'사진 더 추가'**
  String get exploreGalleryAddMore;

  /// No description provided for @exploreGalleryEmpty.
  ///
  /// In ko, this message translates to:
  /// **'사진을 첨부하면 아고다처럼 갤러리로 보여 줍니다.'**
  String get exploreGalleryEmpty;

  /// No description provided for @exploreGalleryCount.
  ///
  /// In ko, this message translates to:
  /// **'사진 {count}장'**
  String exploreGalleryCount(int count);

  /// No description provided for @exploreGalleryViewAll.
  ///
  /// In ko, this message translates to:
  /// **'모든 사진 보기'**
  String get exploreGalleryViewAll;

  /// No description provided for @exploreGalleryMakeCover.
  ///
  /// In ko, this message translates to:
  /// **'대표로'**
  String get exploreGalleryMakeCover;

  /// No description provided for @exploreSaveOk.
  ///
  /// In ko, this message translates to:
  /// **'리조트 정보가 저장되었습니다.'**
  String get exploreSaveOk;

  /// No description provided for @exploreSaveFail.
  ///
  /// In ko, this message translates to:
  /// **'저장에 실패했습니다. 권한과 네트워크를 확인한 뒤 다시 시도해 주세요.'**
  String get exploreSaveFail;

  /// No description provided for @exploreSaving.
  ///
  /// In ko, this message translates to:
  /// **'저장 중…'**
  String get exploreSaving;

  /// No description provided for @exploreAttachPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 첨부'**
  String get exploreAttachPhoto;

  /// No description provided for @exploreUseAsCover.
  ///
  /// In ko, this message translates to:
  /// **'이 사진을 리조트 대표 이미지로'**
  String get exploreUseAsCover;

  /// No description provided for @exploreCoverRemove.
  ///
  /// In ko, this message translates to:
  /// **'이미지 삭제'**
  String get exploreCoverRemove;

  /// No description provided for @communityFilterAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get communityFilterAll;

  /// No description provided for @communityFilterLastCall.
  ///
  /// In ko, this message translates to:
  /// **'마감'**
  String get communityFilterLastCall;

  /// No description provided for @communityFilterSolo.
  ///
  /// In ko, this message translates to:
  /// **'싱글'**
  String get communityFilterSolo;

  /// No description provided for @communityFilterShop.
  ///
  /// In ko, this message translates to:
  /// **'샵'**
  String get communityFilterShop;

  /// No description provided for @communityBerths.
  ///
  /// In ko, this message translates to:
  /// **'자리 {booked}/{capacity}'**
  String communityBerths(int booked, int capacity);

  /// No description provided for @communityLooking.
  ///
  /// In ko, this message translates to:
  /// **'깃발 {count}'**
  String communityLooking(int count);

  /// No description provided for @communitySeatsLeft.
  ///
  /// In ko, this message translates to:
  /// **'빈자리 {count}'**
  String communitySeatsLeft(int count);

  /// No description provided for @communityRaiseFlag.
  ///
  /// In ko, this message translates to:
  /// **'이 배에 깃발'**
  String get communityRaiseFlag;

  /// No description provided for @communityRaiseFlagDone.
  ///
  /// In ko, this message translates to:
  /// **'승선 의사를 명부에 남겼습니다.'**
  String get communityRaiseFlagDone;

  /// No description provided for @communityRaiseFlagMessage.
  ///
  /// In ko, this message translates to:
  /// **'같은 출발에 타겠습니다. 샵 브리핑에서 뵙겠습니다.'**
  String get communityRaiseFlagMessage;

  /// No description provided for @communityOpenTrip.
  ///
  /// In ko, this message translates to:
  /// **'이 상품 열기'**
  String get communityOpenTrip;

  /// No description provided for @communityWindowLabel.
  ///
  /// In ko, this message translates to:
  /// **'출발 구간'**
  String get communityWindowLabel;

  /// No description provided for @communityPickShop.
  ///
  /// In ko, this message translates to:
  /// **'탈 샵'**
  String get communityPickShop;

  /// No description provided for @communityEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 떠 있는 밀물이 없습니다.'**
  String get communityEmpty;

  /// No description provided for @communityKindShop.
  ///
  /// In ko, this message translates to:
  /// **'샵 크루'**
  String get communityKindShop;

  /// No description provided for @communityKindSolo.
  ///
  /// In ko, this message translates to:
  /// **'싱글쉐어'**
  String get communityKindSolo;

  /// No description provided for @communityKindLast.
  ///
  /// In ko, this message translates to:
  /// **'마감'**
  String get communityKindLast;

  /// No description provided for @communityFrom.
  ///
  /// In ko, this message translates to:
  /// **'FROM'**
  String get communityFrom;

  /// No description provided for @communityTo.
  ///
  /// In ko, this message translates to:
  /// **'TIDE'**
  String get communityTo;

  /// No description provided for @communityManifest.
  ///
  /// In ko, this message translates to:
  /// **'승선 명부'**
  String get communityManifest;

  /// No description provided for @weatherCancel.
  ///
  /// In ko, this message translates to:
  /// **'기상 악화 취소'**
  String get weatherCancel;

  /// No description provided for @weatherAdminTitle.
  ///
  /// In ko, this message translates to:
  /// **'기상 악화 취소 권한'**
  String get weatherAdminTitle;

  /// No description provided for @weatherAdminBody.
  ///
  /// In ko, this message translates to:
  /// **'해당 날짜 예약을 weather_cancelled로 바꾸고 100% 환불을 보장합니다.'**
  String get weatherAdminBody;

  /// No description provided for @weatherTourDate.
  ///
  /// In ko, this message translates to:
  /// **'투어 날짜'**
  String get weatherTourDate;

  /// No description provided for @weatherCancelDone.
  ///
  /// In ko, this message translates to:
  /// **'기상 취소와 전액 환불을 반영했습니다.'**
  String get weatherCancelDone;

  /// No description provided for @weatherRefundTitle.
  ///
  /// In ko, this message translates to:
  /// **'기상 악화로 100% 환불됩니다'**
  String get weatherRefundTitle;

  /// No description provided for @weatherRefundBody.
  ///
  /// In ko, this message translates to:
  /// **'{shop} · {product} 예약이 기상 악화로 취소되어 결제/포인트가 전액 환불됩니다.'**
  String weatherRefundBody(String shop, String product);

  /// No description provided for @weatherRefundAck.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get weatherRefundAck;

  /// No description provided for @bookingConfirmed.
  ///
  /// In ko, this message translates to:
  /// **'예약 확정'**
  String get bookingConfirmed;

  /// No description provided for @bookingCancelled.
  ///
  /// In ko, this message translates to:
  /// **'취소됨'**
  String get bookingCancelled;

  /// No description provided for @bookingWeatherCancelled.
  ///
  /// In ko, this message translates to:
  /// **'기상 악화 취소 · 100% 환불'**
  String get bookingWeatherCancelled;

  /// No description provided for @bookingCancel.
  ///
  /// In ko, this message translates to:
  /// **'예약 취소'**
  String get bookingCancel;

  /// No description provided for @bookingCancelledRefund.
  ///
  /// In ko, this message translates to:
  /// **'취소 · 환불 {percent}%'**
  String bookingCancelledRefund(int percent);

  /// No description provided for @refundPolicyHint.
  ///
  /// In ko, this message translates to:
  /// **'지금 취소 시 환불 {percent}%'**
  String refundPolicyHint(int percent);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'es',
    'id',
    'ja',
    'ko',
    'th',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'th':
      return AppLocalizationsTh();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
