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
  /// **'Dive Star 인증'**
  String get homeDiveStarTitle;

  /// 홈 Dive Star 선반 한 줄 감성 카피입니다.
  ///
  /// In ko, this message translates to:
  /// **'다이버가 직접 검증한 리조트'**
  String get homeDiveStarShelfHint;

  /// 홈 화면 다이버 직접 기획 섹션 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'내가 만드는 찐 여행'**
  String get homeFavoritesTitle;

  /// 내가 만드는 찐 여행 선반 서브카피입니다.
  ///
  /// In ko, this message translates to:
  /// **'다이버가 직접 꾸민 진짜 일정'**
  String get homeDiverPlannedSubtitle;

  /// 홈 화면 핫 다이빙 스팟 섹션 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'지금 뜨는 스팟'**
  String get homePopularTitle;

  /// 지금 뜨는 스팟 선반 서브카피입니다.
  ///
  /// In ko, this message translates to:
  /// **'다이버들이 몰리는 핫 다이빙'**
  String get homeHotSpotSubtitle;

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

  /// 홈 선반이 비었을 때 짧은 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'아직 올라온 여행이 없어요. 곧 채워질 거예요.'**
  String get homeShelfEmpty;

  /// 홈 화면 Dive Travel 기획 스페셜 섹션 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'기획 스페셜'**
  String get homeCuratedTitle;

  /// 기획 스페셜 선반 서브카피입니다.
  ///
  /// In ko, this message translates to:
  /// **'Dive Travel이 꾸민 여행'**
  String get homeCuratedSubtitle;

  /// 같은 배 마감 임박 선반 서브카피입니다.
  ///
  /// In ko, this message translates to:
  /// **'빈 자리 채우고 함께 출발'**
  String get homeLastCallSubtitle;

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

  /// 홈에서 같은 배 마감 임박 목록 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'같은 배 · 마감 임박'**
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

  /// No description provided for @optionBookPackage.
  ///
  /// In ko, this message translates to:
  /// **'이 상품 예약'**
  String get optionBookPackage;

  /// No description provided for @optionBookAddon.
  ///
  /// In ko, this message translates to:
  /// **'이 구성 더해 예약'**
  String get optionBookAddon;

  /// No description provided for @optionBookIndividual.
  ///
  /// In ko, this message translates to:
  /// **'이 구성만 예약'**
  String get optionBookIndividual;

  /// 체크아웃의 결제(예약 요청) 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'결제하기'**
  String get explorePay;

  /// No description provided for @simPayTitle.
  ///
  /// In ko, this message translates to:
  /// **'예약 요청 확인'**
  String get simPayTitle;

  /// No description provided for @simPayNotice.
  ///
  /// In ko, this message translates to:
  /// **'지금은 결제하지 않습니다. 샵 확정 후 결제가 이어집니다.'**
  String get simPayNotice;

  /// No description provided for @simPayAction.
  ///
  /// In ko, this message translates to:
  /// **'예약 요청'**
  String get simPayAction;

  /// No description provided for @simPayProcessing.
  ///
  /// In ko, this message translates to:
  /// **'예약 요청 처리 중'**
  String get simPayProcessing;

  /// No description provided for @simPayDoneTitle.
  ///
  /// In ko, this message translates to:
  /// **'예약 요청 완료'**
  String get simPayDoneTitle;

  /// No description provided for @simPayDoneBody.
  ///
  /// In ko, this message translates to:
  /// **'예약 요청이 저장됩니다. 결제 상태는 미결제로 표시됩니다.'**
  String get simPayDoneBody;

  /// No description provided for @simPayClose.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get simPayClose;

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

  /// 자리 확보가 실패해 결제 예약을 저장하지 않았을 때 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'자리를 확보하지 못해 예약을 만들지 않았습니다. 빈자리를 다시 확인해 주세요.'**
  String get exploreBookingNotSaved;

  /// 결제 버튼을 눌렀을 때 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'{label} {price}원 예약을 샵에 전달했습니다.'**
  String exploreCheckoutDone(String label, String price);

  /// No description provided for @sameBoatSeatConfirmed.
  ///
  /// In ko, this message translates to:
  /// **'가확정 좌석이 확정되었습니다. 결제가 완료된 예약입니다.'**
  String get sameBoatSeatConfirmed;

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

  /// 다이브스타 유효기간이 지났을 때 배지 문구입니다.
  ///
  /// In ko, this message translates to:
  /// **'갱신 필요'**
  String get exploreDiveStarRenewalNeeded;

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

  /// 여행상품 탭의 짧은 출국 임박 배너입니다.
  ///
  /// In ko, this message translates to:
  /// **'출국 D-{days} · {shop}'**
  String exploreDepartureBanner(int days, String shop);

  /// 다녀온 여행 별점·후기 화면 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'여행 후기'**
  String get reviewTitle;

  /// No description provided for @reviewIntro.
  ///
  /// In ko, this message translates to:
  /// **'별점을 고르고 짧은 후기를 남겨 주세요.'**
  String get reviewIntro;

  /// No description provided for @reviewShopLabel.
  ///
  /// In ko, this message translates to:
  /// **'리조트 / 다이브샵'**
  String get reviewShopLabel;

  /// 후기 화면의 별점(1~5) 라벨입니다.
  ///
  /// In ko, this message translates to:
  /// **'별점'**
  String get reviewStarsLabel;

  /// 상품·목록에 후기가 없을 때 표시합니다.
  ///
  /// In ko, this message translates to:
  /// **'아직 후기 없음'**
  String get reviewNoReviewsYet;

  /// 평균 별점과 후기 개수입니다.
  ///
  /// In ko, this message translates to:
  /// **'★ {rating} (후기 {count}개)'**
  String reviewCountLabel(String rating, int count);

  /// 상품 상세 하단의 후기 목록 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'다이버 후기'**
  String get reviewSectionTitle;

  /// 후기 구역 상단의 평균·개수 요약입니다.
  ///
  /// In ko, this message translates to:
  /// **'★ {rating} · 후기 {count}개'**
  String reviewSectionSummary(String rating, int count);

  /// 상세 후기 목록이 비어 있을 때 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'아직 후기가 없어요. 첫 후기를 남겨 보세요'**
  String get reviewSectionEmpty;

  /// 후기를 10개씩 더 불러오는 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'더 보기'**
  String get reviewLoadMore;

  /// 후기 작성자 이름이 없을 때 표시합니다.
  ///
  /// In ko, this message translates to:
  /// **'다이버'**
  String get reviewAuthorFallback;

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
  /// **'후기 (선택)'**
  String get reviewComment;

  /// No description provided for @reviewSubmit.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
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
  /// **'후기가 저장되었습니다.'**
  String get reviewSaved;

  /// 후기는 저장됐지만 예약에 product_id가 없을 때 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'이 예약에 상품 정보가 없어 상품 카드 별점은 올라가지 않았습니다.'**
  String get reviewSavedProductIdMissing;

  /// 후기의 product_id가 products 배열에 없을 때 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'샵에서 해당 상품을 찾지 못해 상품 카드 별점은 올라가지 않았습니다.'**
  String get reviewSavedProductNotFound;

  /// No description provided for @reviewSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'후기 저장에 실패했습니다.'**
  String get reviewSaveFailed;

  /// 같은 예약에 후기를 다시 쓸 때 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'이미 후기를 작성했어요'**
  String get reviewAlreadySubmitted;

  /// 예약 없이 후기를 쓰려 할 때 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'다녀온 예약이 확인된 경우에만 후기를 남길 수 있어요'**
  String get reviewBookingRequired;

  /// No description provided for @reviewInvalidStars.
  ///
  /// In ko, this message translates to:
  /// **'별점은 1부터 5까지만 가능해요'**
  String get reviewInvalidStars;

  /// 후기 글자 수 초과 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'후기는 2,000자까지 작성할 수 있어요'**
  String get reviewCommentTooLong;

  /// 후기 세부 선택 접이식 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'더 자세히 알려주기'**
  String get reviewDetailsExpand;

  /// No description provided for @reviewDetailLevel.
  ///
  /// In ko, this message translates to:
  /// **'다이버 레벨'**
  String get reviewDetailLevel;

  /// No description provided for @reviewDetailDives.
  ///
  /// In ko, this message translates to:
  /// **'총 다이빙 횟수'**
  String get reviewDetailDives;

  /// No description provided for @reviewDetailVisibility.
  ///
  /// In ko, this message translates to:
  /// **'시야'**
  String get reviewDetailVisibility;

  /// No description provided for @reviewDetailCurrent.
  ///
  /// In ko, this message translates to:
  /// **'조류'**
  String get reviewDetailCurrent;

  /// No description provided for @reviewDetailWaterTemp.
  ///
  /// In ko, this message translates to:
  /// **'수온 (°C)'**
  String get reviewDetailWaterTemp;

  /// No description provided for @reviewDetailCrowd.
  ///
  /// In ko, this message translates to:
  /// **'가이드 대비 다이버 수'**
  String get reviewDetailCrowd;

  /// No description provided for @reviewDetailAudience.
  ///
  /// In ko, this message translates to:
  /// **'추천 대상'**
  String get reviewDetailAudience;

  /// No description provided for @reviewDetailRevisit.
  ///
  /// In ko, this message translates to:
  /// **'재방문 의사'**
  String get reviewDetailRevisit;

  /// No description provided for @reviewDetailOptionalHint.
  ///
  /// In ko, this message translates to:
  /// **'모두 선택 사항입니다'**
  String get reviewDetailOptionalHint;

  /// No description provided for @reviewDetailOpenWater.
  ///
  /// In ko, this message translates to:
  /// **'오픈워터'**
  String get reviewDetailOpenWater;

  /// No description provided for @reviewDetailAdvanced.
  ///
  /// In ko, this message translates to:
  /// **'어드밴스드'**
  String get reviewDetailAdvanced;

  /// No description provided for @reviewDetailRescuePlus.
  ///
  /// In ko, this message translates to:
  /// **'레스큐 이상'**
  String get reviewDetailRescuePlus;

  /// No description provided for @reviewDetailInstructor.
  ///
  /// In ko, this message translates to:
  /// **'강사'**
  String get reviewDetailInstructor;

  /// No description provided for @reviewDetailFreediver.
  ///
  /// In ko, this message translates to:
  /// **'프리다이버'**
  String get reviewDetailFreediver;

  /// No description provided for @reviewDetailDivesUnder50.
  ///
  /// In ko, this message translates to:
  /// **'~50'**
  String get reviewDetailDivesUnder50;

  /// No description provided for @reviewDetailDives50to200.
  ///
  /// In ko, this message translates to:
  /// **'50~200'**
  String get reviewDetailDives50to200;

  /// No description provided for @reviewDetailDives200Plus.
  ///
  /// In ko, this message translates to:
  /// **'200 이상'**
  String get reviewDetailDives200Plus;

  /// No description provided for @reviewDetailVisPoor.
  ///
  /// In ko, this message translates to:
  /// **'나쁨'**
  String get reviewDetailVisPoor;

  /// No description provided for @reviewDetailVisOk.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get reviewDetailVisOk;

  /// No description provided for @reviewDetailVisGood.
  ///
  /// In ko, this message translates to:
  /// **'좋음'**
  String get reviewDetailVisGood;

  /// No description provided for @reviewDetailVisExcellent.
  ///
  /// In ko, this message translates to:
  /// **'아주 좋음'**
  String get reviewDetailVisExcellent;

  /// No description provided for @reviewDetailCurrentMild.
  ///
  /// In ko, this message translates to:
  /// **'약함'**
  String get reviewDetailCurrentMild;

  /// No description provided for @reviewDetailCurrentOk.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get reviewDetailCurrentOk;

  /// No description provided for @reviewDetailCurrentStrong.
  ///
  /// In ko, this message translates to:
  /// **'강함'**
  String get reviewDetailCurrentStrong;

  /// No description provided for @reviewDetailCrowdRelaxed.
  ///
  /// In ko, this message translates to:
  /// **'여유로움'**
  String get reviewDetailCrowdRelaxed;

  /// No description provided for @reviewDetailCrowdOk.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get reviewDetailCrowdOk;

  /// No description provided for @reviewDetailCrowdBusy.
  ///
  /// In ko, this message translates to:
  /// **'붐빔'**
  String get reviewDetailCrowdBusy;

  /// No description provided for @reviewDetailAudienceBeginner.
  ///
  /// In ko, this message translates to:
  /// **'초보'**
  String get reviewDetailAudienceBeginner;

  /// No description provided for @reviewDetailAudienceExperienced.
  ///
  /// In ko, this message translates to:
  /// **'숙련'**
  String get reviewDetailAudienceExperienced;

  /// No description provided for @reviewDetailAudienceCouple.
  ///
  /// In ko, this message translates to:
  /// **'커플'**
  String get reviewDetailAudienceCouple;

  /// No description provided for @reviewDetailAudienceFamily.
  ///
  /// In ko, this message translates to:
  /// **'가족'**
  String get reviewDetailAudienceFamily;

  /// No description provided for @reviewDetailAudiencePhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 다이버'**
  String get reviewDetailAudiencePhoto;

  /// No description provided for @reviewDetailAudienceFreediver.
  ///
  /// In ko, this message translates to:
  /// **'프리다이버'**
  String get reviewDetailAudienceFreediver;

  /// No description provided for @reviewDetailAudienceTech.
  ///
  /// In ko, this message translates to:
  /// **'테크니컬'**
  String get reviewDetailAudienceTech;

  /// No description provided for @reviewDetailRevisitYes.
  ///
  /// In ko, this message translates to:
  /// **'예'**
  String get reviewDetailRevisitYes;

  /// No description provided for @reviewDetailRevisitNo.
  ///
  /// In ko, this message translates to:
  /// **'아니오'**
  String get reviewDetailRevisitNo;

  /// No description provided for @reviewDetailRevisitUnsure.
  ///
  /// In ko, this message translates to:
  /// **'모르겠음'**
  String get reviewDetailRevisitUnsure;

  /// No description provided for @reviewDetailWaterTempChip.
  ///
  /// In ko, this message translates to:
  /// **'{temp}°C'**
  String reviewDetailWaterTempChip(String temp);

  /// No description provided for @reviewInvalidDetails.
  ///
  /// In ko, this message translates to:
  /// **'세부 항목 값이 올바르지 않아요'**
  String get reviewInvalidDetails;

  /// No description provided for @reviewInvalidWaterTemp.
  ///
  /// In ko, this message translates to:
  /// **'수온은 -2°C부터 40°C까지 입력할 수 있어요'**
  String get reviewInvalidWaterTemp;

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

  /// 마이페이지 출항 데스크 히어로 키커입니다.
  ///
  /// In ko, this message translates to:
  /// **'출항 데스크'**
  String get profileDepartureDeskKicker;

  /// 다이버가 제안한 DIY 여행 상품 섹션 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'내가 직접 짠 여행'**
  String get profileCraftedTripsTitle;

  /// DIY 여행 상품 섹션 안내 문구입니다.
  ///
  /// In ko, this message translates to:
  /// **'리조트를 골라 일정을 짜면 관리자 승인 후 여행상품에 올라갑니다.'**
  String get profileCraftedTripsHint;

  /// 새 DIY 여행 상품 등록 버튼입니다.
  ///
  /// In ko, this message translates to:
  /// **'새 여행 짜기'**
  String get profileCraftNewTrip;

  /// No description provided for @profileCraftNeedsGold.
  ///
  /// In ko, this message translates to:
  /// **'골드 이상부터 여행을 짤 수 있습니다. 첫 여행을 결제하면 골드가 됩니다.'**
  String get profileCraftNeedsGold;

  /// DIY 상품이 관리자 승인 대기 중일 때 배지입니다.
  ///
  /// In ko, this message translates to:
  /// **'승인 대기'**
  String get profileCraftStatusPending;

  /// DIY 상품이 승인되어 공개된 배지입니다.
  ///
  /// In ko, this message translates to:
  /// **'공개 중'**
  String get profileCraftStatusLive;

  /// DIY 상품이 반려된 배지입니다.
  ///
  /// In ko, this message translates to:
  /// **'반려'**
  String get profileCraftStatusRejected;

  /// 마이페이지 하단 관리·인증·로그아웃 섹션 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'데스크 도구'**
  String get profileDeskToolsTitle;

  /// 데스크 도구 섹션 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'관리자·파트너·강사 인증과 로그아웃은 여기에 모아 두었습니다.'**
  String get profileDeskToolsHint;

  /// 리조트 드롭다운에서 카탈로그에 없을 때 선택하는 항목입니다.
  ///
  /// In ko, this message translates to:
  /// **'목록에 없는 리조트'**
  String get productFormNotInList;

  /// 다이버 DIY 상품 등록 시 리조트 선택 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'대륙을 고른 뒤 리조트를 선택하세요. 목록에 없으면 직접 이름을 적을 수 있습니다.'**
  String get productFormCreatorShopHint;

  /// No description provided for @profileMyOceanKicker.
  ///
  /// In ko, this message translates to:
  /// **'MY OCEAN'**
  String get profileMyOceanKicker;

  /// No description provided for @profileGradeSilver.
  ///
  /// In ko, this message translates to:
  /// **'실버'**
  String get profileGradeSilver;

  /// No description provided for @profileGradeGold.
  ///
  /// In ko, this message translates to:
  /// **'골드'**
  String get profileGradeGold;

  /// No description provided for @profileGradeDiamond.
  ///
  /// In ko, this message translates to:
  /// **'다이아몬드'**
  String get profileGradeDiamond;

  /// No description provided for @profileGradePlatinum.
  ///
  /// In ko, this message translates to:
  /// **'플래티넘'**
  String get profileGradePlatinum;

  /// No description provided for @profileGradeInstructor.
  ///
  /// In ko, this message translates to:
  /// **'강사'**
  String get profileGradeInstructor;

  /// No description provided for @profileViewMyInfo.
  ///
  /// In ko, this message translates to:
  /// **'나의 정보 보기'**
  String get profileViewMyInfo;

  /// No description provided for @profileNextOceanTitle.
  ///
  /// In ko, this message translates to:
  /// **'다음 바다'**
  String get profileNextOceanTitle;

  /// No description provided for @profileNoUpcomingTrip.
  ///
  /// In ko, this message translates to:
  /// **'아직 정해진 다음 바다가 없어요'**
  String get profileNoUpcomingTrip;

  /// No description provided for @profileNoUpcomingTripHint.
  ///
  /// In ko, this message translates to:
  /// **'마음에 담아둔 바다에서 다음 여정을 시작해 보세요.'**
  String get profileNoUpcomingTripHint;

  /// No description provided for @profileSavedOceansTitle.
  ///
  /// In ko, this message translates to:
  /// **'내가 기다리는 바다'**
  String get profileSavedOceansTitle;

  /// No description provided for @profileSavedOceansEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 기다리는 바다가 없어요. 여행상품에서 하트를 눌러 담아보세요.'**
  String get profileSavedOceansEmpty;

  /// No description provided for @profileOceanRecordTitle.
  ///
  /// In ko, this message translates to:
  /// **'나의 바다 기록'**
  String get profileOceanRecordTitle;

  /// No description provided for @profileTotalDives.
  ///
  /// In ko, this message translates to:
  /// **'누적 다이빙'**
  String get profileTotalDives;

  /// No description provided for @profileExploredSeas.
  ///
  /// In ko, this message translates to:
  /// **'탐험 지역'**
  String get profileExploredSeas;

  /// No description provided for @profileNextMilestone.
  ///
  /// In ko, this message translates to:
  /// **'다음 마일스톤까지 {count}로그'**
  String profileNextMilestone(int count);

  /// No description provided for @profileActivityTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 활동'**
  String get profileActivityTitle;

  /// No description provided for @profileBookingHistory.
  ///
  /// In ko, this message translates to:
  /// **'예약 내역'**
  String get profileBookingHistory;

  /// No description provided for @profileTripScheduleTitle.
  ///
  /// In ko, this message translates to:
  /// **'나의 이번 여행 스케줄'**
  String get profileTripScheduleTitle;

  /// No description provided for @profileTripScheduleEmpty.
  ///
  /// In ko, this message translates to:
  /// **'확정된 여행이 아직 없습니다.'**
  String get profileTripScheduleEmpty;

  /// No description provided for @profileFlaggedSeatsTitle.
  ///
  /// In ko, this message translates to:
  /// **'깃발꽂은 빈자리'**
  String get profileFlaggedSeatsTitle;

  /// No description provided for @profileFlaggedSeatsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'잠가 둔 빈자리가 없습니다.'**
  String get profileFlaggedSeatsEmpty;

  /// No description provided for @profileFlagPayCta.
  ///
  /// In ko, this message translates to:
  /// **'결제 바로가기'**
  String get profileFlagPayCta;

  /// No description provided for @profileWishlistTitle.
  ///
  /// In ko, this message translates to:
  /// **'내가 가고 싶은 곳들'**
  String get profileWishlistTitle;

  /// No description provided for @profileReviewRecommendTitle.
  ///
  /// In ko, this message translates to:
  /// **'리뷰가 추천하는 곳'**
  String get profileReviewRecommendTitle;

  /// No description provided for @profileWriteReviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'내가 다녀온 여행 리뷰쓰기'**
  String get profileWriteReviewTitle;

  /// No description provided for @profileCharmsTitle.
  ///
  /// In ko, this message translates to:
  /// **'나의 바다 뱃지'**
  String get profileCharmsTitle;

  /// No description provided for @bookingVoucherOpen.
  ///
  /// In ko, this message translates to:
  /// **'여행 바우처'**
  String get bookingVoucherOpen;

  /// No description provided for @bookingVoucherTitle.
  ///
  /// In ko, this message translates to:
  /// **'여행 바우처'**
  String get bookingVoucherTitle;

  /// No description provided for @bookingVoucherSave.
  ///
  /// In ko, this message translates to:
  /// **'폰에 저장·보관'**
  String get bookingVoucherSave;

  /// No description provided for @bookingVoucherSaved.
  ///
  /// In ko, this message translates to:
  /// **'바우처를 저장할 수 있는 공유 화면을 열었습니다.'**
  String get bookingVoucherSaved;

  /// No description provided for @bookingVoucherId.
  ///
  /// In ko, this message translates to:
  /// **'예약번호'**
  String get bookingVoucherId;

  /// No description provided for @bookingVoucherShop.
  ///
  /// In ko, this message translates to:
  /// **'샵'**
  String get bookingVoucherShop;

  /// No description provided for @profileBookingStatus.
  ///
  /// In ko, this message translates to:
  /// **'나의 예약'**
  String get profileBookingStatus;

  /// No description provided for @profilePaidBookingsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'결제 완료된 예약이 없습니다.'**
  String get profilePaidBookingsEmpty;

  /// No description provided for @profileRequestedBookingsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'요청 중인 예약이 없습니다.'**
  String get profileRequestedBookingsEmpty;

  /// No description provided for @profileBookingFilterAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get profileBookingFilterAll;

  /// No description provided for @profileBookingFilterRequested.
  ///
  /// In ko, this message translates to:
  /// **'예약 요청'**
  String get profileBookingFilterRequested;

  /// No description provided for @profileBookingFilterHolding.
  ///
  /// In ko, this message translates to:
  /// **'좌석 홀딩'**
  String get profileBookingFilterHolding;

  /// No description provided for @profileBookingFilterPaid.
  ///
  /// In ko, this message translates to:
  /// **'결제 완료'**
  String get profileBookingFilterPaid;

  /// No description provided for @profileLiveFlagsTitle.
  ///
  /// In ko, this message translates to:
  /// **'꽂아 둔 깃발'**
  String get profileLiveFlagsTitle;

  /// No description provided for @profileLiveFlagsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'꽂아 둔 깃발이 없습니다.'**
  String get profileLiveFlagsEmpty;

  /// No description provided for @profileAfterTripTitle.
  ///
  /// In ko, this message translates to:
  /// **'다녀온 뒤'**
  String get profileAfterTripTitle;

  /// No description provided for @profileAfterTripEmpty.
  ///
  /// In ko, this message translates to:
  /// **'남길 리뷰가 없습니다.'**
  String get profileAfterTripEmpty;

  /// No description provided for @profileNextTripSuggest.
  ///
  /// In ko, this message translates to:
  /// **'다음에 가볼 바다'**
  String get profileNextTripSuggest;

  /// No description provided for @profileBookingCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String profileBookingCount(int count);

  /// No description provided for @profileCraftedCount.
  ///
  /// In ko, this message translates to:
  /// **'내가 만든 여행 {count}개'**
  String profileCraftedCount(int count);

  /// No description provided for @profileSettingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get profileSettingsTitle;

  /// No description provided for @profileMembershipTitle.
  ///
  /// In ko, this message translates to:
  /// **'멤버십'**
  String get profileMembershipTitle;

  /// No description provided for @profileGradeFirstTide.
  ///
  /// In ko, this message translates to:
  /// **'첫 바다를 결제하면 골드로 건너갑니다.'**
  String get profileGradeFirstTide;

  /// No description provided for @profileGradeStepsLeft.
  ///
  /// In ko, this message translates to:
  /// **'{next}까지 {count}번의 여행이 남았습니다.'**
  String profileGradeStepsLeft(String next, int count);

  /// No description provided for @profileGradeDeepest.
  ///
  /// In ko, this message translates to:
  /// **'이미 가장 깊은 등급, 플래티넘입니다.'**
  String get profileGradeDeepest;

  /// No description provided for @profileCredentialsTitle.
  ///
  /// In ko, this message translates to:
  /// **'자격증 및 등급'**
  String get profileCredentialsTitle;

  /// No description provided for @profileWorkModeTitle.
  ///
  /// In ko, this message translates to:
  /// **'업무용 전환'**
  String get profileWorkModeTitle;

  /// No description provided for @profileUpcomingConfirmed.
  ///
  /// In ko, this message translates to:
  /// **'예약 확정 · {date}'**
  String profileUpcomingConfirmed(String date);

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

  /// No description provided for @adminMembersSubDivers.
  ///
  /// In ko, this message translates to:
  /// **'다이버'**
  String get adminMembersSubDivers;

  /// No description provided for @adminMembersSubInstructors.
  ///
  /// In ko, this message translates to:
  /// **'강사인증'**
  String get adminMembersSubInstructors;

  /// No description provided for @adminMembersSubPartners.
  ///
  /// In ko, this message translates to:
  /// **'제휴파트너'**
  String get adminMembersSubPartners;

  /// No description provided for @adminMembersGradeAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get adminMembersGradeAll;

  /// No description provided for @adminMembersNeedsAction.
  ///
  /// In ko, this message translates to:
  /// **'조치 필요'**
  String get adminMembersNeedsAction;

  /// No description provided for @adminMembersNeedsActionHint.
  ///
  /// In ko, this message translates to:
  /// **'강사 승인 대기 {count}건 — 강사인증 탭에서 처리하세요.'**
  String adminMembersNeedsActionHint(int count);

  /// No description provided for @adminMembersPurchasesReviews.
  ///
  /// In ko, this message translates to:
  /// **'구매 {purchases}회 · 리뷰 {reviews}건'**
  String adminMembersPurchasesReviews(int purchases, int reviews);

  /// No description provided for @adminMembersGradeLocked.
  ///
  /// In ko, this message translates to:
  /// **'수동 조정됨 · 자동 승급이 잠겨 있습니다.'**
  String get adminMembersGradeLocked;

  /// No description provided for @adminMembersUnlockAuto.
  ///
  /// In ko, this message translates to:
  /// **'자동 승급 허용'**
  String get adminMembersUnlockAuto;

  /// No description provided for @adminPulseTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 맥박'**
  String get adminPulseTitle;

  /// No description provided for @adminPulseSalesMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 매출'**
  String get adminPulseSalesMonth;

  /// No description provided for @adminPulseConversion.
  ///
  /// In ko, this message translates to:
  /// **'결제 전환율'**
  String get adminPulseConversion;

  /// No description provided for @adminPulseFunnelHint.
  ///
  /// In ko, this message translates to:
  /// **'결제 {paid} · 요청 {requested}'**
  String adminPulseFunnelHint(int paid, int requested);

  /// No description provided for @adminPulseNewWeek.
  ///
  /// In ko, this message translates to:
  /// **'이번 주 신규'**
  String get adminPulseNewWeek;

  /// No description provided for @adminVisitsTitle.
  ///
  /// In ko, this message translates to:
  /// **'방문 빈도'**
  String get adminVisitsTitle;

  /// No description provided for @adminVisitsDau.
  ///
  /// In ko, this message translates to:
  /// **'오늘 방문 (DAU)'**
  String get adminVisitsDau;

  /// No description provided for @adminVisitsWau.
  ///
  /// In ko, this message translates to:
  /// **'7일 방문 (WAU)'**
  String get adminVisitsWau;

  /// No description provided for @adminVisitsMau.
  ///
  /// In ko, this message translates to:
  /// **'30일 방문 (MAU)'**
  String get adminVisitsMau;

  /// No description provided for @adminVisitsDormant.
  ///
  /// In ko, this message translates to:
  /// **'휴면 (30일+)'**
  String get adminVisitsDormant;

  /// No description provided for @adminNewMembersTitle.
  ///
  /// In ko, this message translates to:
  /// **'신규 회원'**
  String get adminNewMembersTitle;

  /// No description provided for @adminNewMembersToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 가입'**
  String get adminNewMembersToday;

  /// No description provided for @adminNewMembersWeek.
  ///
  /// In ko, this message translates to:
  /// **'7일 가입'**
  String get adminNewMembersWeek;

  /// No description provided for @adminNewMembersMonth.
  ///
  /// In ko, this message translates to:
  /// **'30일 가입'**
  String get adminNewMembersMonth;

  /// No description provided for @adminNewMembersPaid.
  ///
  /// In ko, this message translates to:
  /// **'신규→첫결제 (30일)'**
  String get adminNewMembersPaid;

  /// No description provided for @adminFunnelTitle.
  ///
  /// In ko, this message translates to:
  /// **'예약 퍼널'**
  String get adminFunnelTitle;

  /// No description provided for @adminFunnelRequested.
  ///
  /// In ko, this message translates to:
  /// **'요청(미결제)'**
  String get adminFunnelRequested;

  /// No description provided for @adminFunnelPaid.
  ///
  /// In ko, this message translates to:
  /// **'결제·확정'**
  String get adminFunnelPaid;

  /// No description provided for @adminFunnelCancelled.
  ///
  /// In ko, this message translates to:
  /// **'취소·종료'**
  String get adminFunnelCancelled;

  /// No description provided for @adminFunnelUnreviewed.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 미작성 결제'**
  String get adminFunnelUnreviewed;

  /// No description provided for @adminNearUpgradeTitle.
  ///
  /// In ko, this message translates to:
  /// **'승급 임박'**
  String get adminNearUpgradeTitle;

  /// No description provided for @adminNearUpgradeHint.
  ///
  /// In ko, this message translates to:
  /// **'다음 등급까지 구매 {purchases} · 리뷰 {reviews}'**
  String adminNearUpgradeHint(int purchases, int reviews);

  /// No description provided for @adminProductSignalTitle.
  ///
  /// In ko, this message translates to:
  /// **'상품·제휴 신호'**
  String get adminProductSignalTitle;

  /// No description provided for @adminProductSignalPublic.
  ///
  /// In ko, this message translates to:
  /// **'공개 상품'**
  String get adminProductSignalPublic;

  /// No description provided for @adminProductSignalPending.
  ///
  /// In ko, this message translates to:
  /// **'승인 대기'**
  String get adminProductSignalPending;

  /// No description provided for @adminProductSignalShops.
  ///
  /// In ko, this message translates to:
  /// **'제휴 샵'**
  String get adminProductSignalShops;

  /// No description provided for @gradeCelebrationTitle.
  ///
  /// In ko, this message translates to:
  /// **'{grade}으로 승급했습니다!'**
  String gradeCelebrationTitle(String grade);

  /// No description provided for @gradeCelebrationBody.
  ///
  /// In ko, this message translates to:
  /// **'바다를 함께 채워 주셔서 감사합니다. {grade} 여정을 Dive Travel이 응원합니다.'**
  String gradeCelebrationBody(String grade);

  /// No description provided for @gradeCelebrationThanks.
  ///
  /// In ko, this message translates to:
  /// **'고마워요'**
  String get gradeCelebrationThanks;

  /// No description provided for @adminMembersBadgeInstructor.
  ///
  /// In ko, this message translates to:
  /// **'강사'**
  String get adminMembersBadgeInstructor;

  /// No description provided for @adminMembersBadgePartner.
  ///
  /// In ko, this message translates to:
  /// **'제휴'**
  String get adminMembersBadgePartner;

  /// No description provided for @adminPartnerTierAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get adminPartnerTierAll;

  /// No description provided for @adminPartnerTierReviewPending.
  ///
  /// In ko, this message translates to:
  /// **'리뷰전'**
  String get adminPartnerTierReviewPending;

  /// No description provided for @adminPartnerTierStar1.
  ///
  /// In ko, this message translates to:
  /// **'Dive Star 1'**
  String get adminPartnerTierStar1;

  /// No description provided for @adminPartnerTierStar2.
  ///
  /// In ko, this message translates to:
  /// **'Dive Star 2'**
  String get adminPartnerTierStar2;

  /// No description provided for @adminPartnerTierStar3.
  ///
  /// In ko, this message translates to:
  /// **'Dive Star 3'**
  String get adminPartnerTierStar3;

  /// No description provided for @adminPartnerTierEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이 티어에 해당하는 제휴 파트너가 없습니다.'**
  String get adminPartnerTierEmpty;

  /// No description provided for @adminPartnerOpenInstructors.
  ///
  /// In ko, this message translates to:
  /// **'강사인증으로'**
  String get adminPartnerOpenInstructors;

  /// No description provided for @adminTabCertify.
  ///
  /// In ko, this message translates to:
  /// **'인증'**
  String get adminTabCertify;

  /// No description provided for @adminTabShops.
  ///
  /// In ko, this message translates to:
  /// **'제휴파트너'**
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

  /// No description provided for @adminSalesTitle.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 매출'**
  String get adminSalesTitle;

  /// No description provided for @adminSalesTotal.
  ///
  /// In ko, this message translates to:
  /// **'합계 {amount}원'**
  String adminSalesTotal(String amount);

  /// No description provided for @adminSalesExplore.
  ///
  /// In ko, this message translates to:
  /// **'일반 상품'**
  String get adminSalesExplore;

  /// No description provided for @adminSalesFlag.
  ///
  /// In ko, this message translates to:
  /// **'깃발 꽂기'**
  String get adminSalesFlag;

  /// No description provided for @adminSalesDiverPlanned.
  ///
  /// In ko, this message translates to:
  /// **'내가 짠 상품'**
  String get adminSalesDiverPlanned;

  /// No description provided for @adminSalesCurated.
  ///
  /// In ko, this message translates to:
  /// **'기획 스페셜'**
  String get adminSalesCurated;

  /// No description provided for @adminSalesDiveStar.
  ///
  /// In ko, this message translates to:
  /// **'다이브 스타'**
  String get adminSalesDiveStar;

  /// No description provided for @adminSalesHotSpot.
  ///
  /// In ko, this message translates to:
  /// **'핫스팟'**
  String get adminSalesHotSpot;

  /// No description provided for @adminSalesNextDeparture.
  ///
  /// In ko, this message translates to:
  /// **'마감 임박'**
  String get adminSalesNextDeparture;

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
  /// **'회원을 조회하고 실버·골드·다이아몬드·플래티넘 등급을 조정합니다.'**
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

  /// No description provided for @memberGradeSilver.
  ///
  /// In ko, this message translates to:
  /// **'실버회원'**
  String get memberGradeSilver;

  /// No description provided for @memberGradeGold.
  ///
  /// In ko, this message translates to:
  /// **'골드회원'**
  String get memberGradeGold;

  /// No description provided for @memberGradeDiamond.
  ///
  /// In ko, this message translates to:
  /// **'다이아몬드회원'**
  String get memberGradeDiamond;

  /// No description provided for @memberGradePlatinum.
  ///
  /// In ko, this message translates to:
  /// **'플래티넘회원'**
  String get memberGradePlatinum;

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
  /// **'파트너'**
  String get adminShopsTitle;

  /// No description provided for @adminPartnersGradeHint.
  ///
  /// In ko, this message translates to:
  /// **'다이브스타 제휴는 리뷰와 내부심사로 등급을 봅니다.'**
  String get adminPartnersGradeHint;

  /// No description provided for @adminShopsSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'오퍼레이션 평점과 스타 등급, 실물 현판 발송을 모니터링합니다.'**
  String get adminShopsSubtitle;

  /// No description provided for @adminProductsTitle.
  ///
  /// In ko, this message translates to:
  /// **'여행상품 등록'**
  String get adminProductsTitle;

  /// No description provided for @adminProductsSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'등록하면 여행상품 메뉴에 최근순으로 올라갑니다. 홈 노출은 홈 큐레이션에서 고릅니다.'**
  String get adminProductsSubtitle;

  /// No description provided for @adminProductsTab.
  ///
  /// In ko, this message translates to:
  /// **'상품'**
  String get adminProductsTab;

  /// No description provided for @adminSameBoatTab.
  ///
  /// In ko, this message translates to:
  /// **'같은배 모니터'**
  String get adminSameBoatTab;

  /// No description provided for @adminSameBoatTitle.
  ///
  /// In ko, this message translates to:
  /// **'같은배 · 빈자리 모니터'**
  String get adminSameBoatTitle;

  /// No description provided for @adminSameBoatHint.
  ///
  /// In ko, this message translates to:
  /// **'등록자가 연 빈자리만 표시합니다. 깃발 지정은 여기서 하지 않습니다.'**
  String get adminSameBoatHint;

  /// No description provided for @adminSameBoatApproveHint.
  ///
  /// In ko, this message translates to:
  /// **'빈자리 신청을 승인하면 같은배 메뉴에 올라갑니다. 깃발을 꽂으면 결제 시한까지 좌석이 잠깁니다.'**
  String get adminSameBoatApproveHint;

  /// No description provided for @adminSameBoatPendingQueue.
  ///
  /// In ko, this message translates to:
  /// **'빈자리 승인 대기'**
  String get adminSameBoatPendingQueue;

  /// No description provided for @adminSameBoatPendingEmpty.
  ///
  /// In ko, this message translates to:
  /// **'대기 중인 빈자리 신청이 없습니다.'**
  String get adminSameBoatPendingEmpty;

  /// No description provided for @adminSameBoatLiveTitle.
  ///
  /// In ko, this message translates to:
  /// **'같은배에 열린 빈자리'**
  String get adminSameBoatLiveTitle;

  /// No description provided for @adminSameBoatApprove.
  ///
  /// In ko, this message translates to:
  /// **'승인 · 같은배 게시'**
  String get adminSameBoatApprove;

  /// No description provided for @adminSameBoatReject.
  ///
  /// In ko, this message translates to:
  /// **'반려'**
  String get adminSameBoatReject;

  /// No description provided for @adminSameBoatPendingBadge.
  ///
  /// In ko, this message translates to:
  /// **'승인 대기'**
  String get adminSameBoatPendingBadge;

  /// No description provided for @adminSameBoatLiveBadge.
  ///
  /// In ko, this message translates to:
  /// **'같은배 게시중'**
  String get adminSameBoatLiveBadge;

  /// No description provided for @adminSameBoatRejectedBadge.
  ///
  /// In ko, this message translates to:
  /// **'반려됨'**
  String get adminSameBoatRejectedBadge;

  /// No description provided for @adminSameBoatClosedBadge.
  ///
  /// In ko, this message translates to:
  /// **'닫힘'**
  String get adminSameBoatClosedBadge;

  /// No description provided for @adminSameBoatEmpty.
  ///
  /// In ko, this message translates to:
  /// **'열린 빈자리 상품이 없습니다.'**
  String get adminSameBoatEmpty;

  /// No description provided for @sameBoatSeatsTitle.
  ///
  /// In ko, this message translates to:
  /// **'빈자리 열기'**
  String get sameBoatSeatsTitle;

  /// No description provided for @sameBoatApplyTitle.
  ///
  /// In ko, this message translates to:
  /// **'같은배 신청'**
  String get sameBoatApplyTitle;

  /// No description provided for @sameBoatAskCreateSeats.
  ///
  /// In ko, this message translates to:
  /// **'이 상품에 빈자리를 만들겠습니까?'**
  String get sameBoatAskCreateSeats;

  /// No description provided for @sameBoatAskCreateSeatsYes.
  ///
  /// In ko, this message translates to:
  /// **'만들기'**
  String get sameBoatAskCreateSeatsYes;

  /// No description provided for @sameBoatAskCreateSeatsNo.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get sameBoatAskCreateSeatsNo;

  /// No description provided for @sameBoatHubSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'상품 이름 검색'**
  String get sameBoatHubSearchHint;

  /// No description provided for @sameBoatSeatsHint.
  ///
  /// In ko, this message translates to:
  /// **'기본 상품과 개별 상품에 빈자리를 열고, 출발일·깃발 마감을 넣은 뒤 관리자 승인을 요청합니다.'**
  String get sameBoatSeatsHint;

  /// No description provided for @sameBoatSeatsHubHint.
  ///
  /// In ko, this message translates to:
  /// **'상품을 고른 뒤 빈자리 수·출발일·깃발 마감을 정해 같은배에 신청합니다.'**
  String get sameBoatSeatsHubHint;

  /// No description provided for @sameBoatSeatsNoProducts.
  ///
  /// In ko, this message translates to:
  /// **'조건에 맞는 공개 상품이 없습니다. 상품을 등록·승인했는지 확인하세요.'**
  String get sameBoatSeatsNoProducts;

  /// No description provided for @sameBoatSeatsSubmit.
  ///
  /// In ko, this message translates to:
  /// **'승인 요청'**
  String get sameBoatSeatsSubmit;

  /// No description provided for @sameBoatSeatsPublish.
  ///
  /// In ko, this message translates to:
  /// **'같은배에 바로 게시'**
  String get sameBoatSeatsPublish;

  /// No description provided for @sameBoatSeatsSubmitted.
  ///
  /// In ko, this message translates to:
  /// **'빈자리 승인 요청을 보냈습니다.'**
  String get sameBoatSeatsSubmitted;

  /// No description provided for @sameBoatSeatsPublished.
  ///
  /// In ko, this message translates to:
  /// **'같은배에 빈자리를 게시했습니다.'**
  String get sameBoatSeatsPublished;

  /// No description provided for @sameBoatSeatsEdit.
  ///
  /// In ko, this message translates to:
  /// **'빈자리 수정'**
  String get sameBoatSeatsEdit;

  /// No description provided for @adminSameBoatApplyTab.
  ///
  /// In ko, this message translates to:
  /// **'빈자리 신청'**
  String get adminSameBoatApplyTab;

  /// No description provided for @adminSameBoatApplyHint.
  ///
  /// In ko, this message translates to:
  /// **'공개 상품을 골라 빈자리를 열고 같은배에 바로 게시합니다.'**
  String get adminSameBoatApplyHint;

  /// No description provided for @partnerSectionShopProducts.
  ///
  /// In ko, this message translates to:
  /// **'샵 · 상품'**
  String get partnerSectionShopProducts;

  /// No description provided for @partnerSectionSameBoat.
  ///
  /// In ko, this message translates to:
  /// **'같은배 신청'**
  String get partnerSectionSameBoat;

  /// No description provided for @partnerSectionOps.
  ///
  /// In ko, this message translates to:
  /// **'예약 · 정산'**
  String get partnerSectionOps;

  /// No description provided for @partnerSameBoatApplyHint.
  ///
  /// In ko, this message translates to:
  /// **'자기 상품 중 빈자리를 채울 상품을 고르고 신청합니다.'**
  String get partnerSameBoatApplyHint;

  /// No description provided for @sameBoatIndividualSeats.
  ///
  /// In ko, this message translates to:
  /// **'개별 상품 빈자리'**
  String get sameBoatIndividualSeats;

  /// No description provided for @sameBoatHoldPriorityHint.
  ///
  /// In ko, this message translates to:
  /// **'다이버 깃발은 이 깃발 마감과 심은 뒤 24시간 중 더 빠른 시각까지 잠깁니다. 그 안에 결제하지 않으면 자리가 다시 열립니다.'**
  String get sameBoatHoldPriorityHint;

  /// No description provided for @workbenchFlagDeadlineRequired.
  ///
  /// In ko, this message translates to:
  /// **'깃발 마감일을 정해 주세요.'**
  String get workbenchFlagDeadlineRequired;

  /// No description provided for @communityFlagPayBy.
  ///
  /// In ko, this message translates to:
  /// **'결제 기한: {deadline}'**
  String communityFlagPayBy(String deadline);

  /// No description provided for @communityFlagPayByShortened.
  ///
  /// In ko, this message translates to:
  /// **'배 깃발 마감이 더 빨라서 이 시각까지입니다.'**
  String get communityFlagPayByShortened;

  /// No description provided for @checkoutFlagPayBy.
  ///
  /// In ko, this message translates to:
  /// **'결제 기한'**
  String get checkoutFlagPayBy;

  /// No description provided for @adminProductSourceAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get adminProductSourceAll;

  /// No description provided for @adminProductSourcePartner.
  ///
  /// In ko, this message translates to:
  /// **'제휴파트너'**
  String get adminProductSourcePartner;

  /// No description provided for @adminProductSourceDiy.
  ///
  /// In ko, this message translates to:
  /// **'내가짠여행'**
  String get adminProductSourceDiy;

  /// No description provided for @adminProductSourceSpecial.
  ///
  /// In ko, this message translates to:
  /// **'기획스페셜'**
  String get adminProductSourceSpecial;

  /// No description provided for @adminProductSourceUnknown.
  ///
  /// In ko, this message translates to:
  /// **'미분류'**
  String get adminProductSourceUnknown;

  /// No description provided for @adminProductFilterShop.
  ///
  /// In ko, this message translates to:
  /// **'샵 필터 · {name}'**
  String adminProductFilterShop(String name);

  /// No description provided for @adminProductClearShopFilter.
  ///
  /// In ko, this message translates to:
  /// **'필터 해제'**
  String get adminProductClearShopFilter;

  /// No description provided for @adminOpenSeatsBadge.
  ///
  /// In ko, this message translates to:
  /// **'빈자리'**
  String get adminOpenSeatsBadge;

  /// No description provided for @adminInternalScore.
  ///
  /// In ko, this message translates to:
  /// **'내부심사'**
  String get adminInternalScore;

  /// No description provided for @adminInternalScoreHint.
  ///
  /// In ko, this message translates to:
  /// **'0–100'**
  String get adminInternalScoreHint;

  /// No description provided for @adminInternalScoreEdit.
  ///
  /// In ko, this message translates to:
  /// **'내부점수 수정'**
  String get adminInternalScoreEdit;

  /// No description provided for @adminInternalScoreSaved.
  ///
  /// In ko, this message translates to:
  /// **'내부심사 점수를 저장했습니다.'**
  String get adminInternalScoreSaved;

  /// No description provided for @adminDiveStarGrade.
  ///
  /// In ko, this message translates to:
  /// **'다이브스타 등급'**
  String get adminDiveStarGrade;

  /// No description provided for @adminDiveStarGradeHint.
  ///
  /// In ko, this message translates to:
  /// **'0–3 (0 = 없음)'**
  String get adminDiveStarGradeHint;

  /// No description provided for @adminDiveStarReviewedAt.
  ///
  /// In ko, this message translates to:
  /// **'심사일'**
  String get adminDiveStarReviewedAt;

  /// No description provided for @adminDiveStarExpiresAt.
  ///
  /// In ko, this message translates to:
  /// **'만료일'**
  String get adminDiveStarExpiresAt;

  /// No description provided for @adminDiveStarGradeEdit.
  ///
  /// In ko, this message translates to:
  /// **'다이브스타 등급 수정'**
  String get adminDiveStarGradeEdit;

  /// No description provided for @adminDiveStarGradeSaved.
  ///
  /// In ko, this message translates to:
  /// **'다이브스타 등급을 저장했습니다.'**
  String get adminDiveStarGradeSaved;

  /// No description provided for @adminViewShopProducts.
  ///
  /// In ko, this message translates to:
  /// **'상품 보기'**
  String get adminViewShopProducts;

  /// No description provided for @adminSameBoatRemaining.
  ///
  /// In ko, this message translates to:
  /// **'잔여 {count}'**
  String adminSameBoatRemaining(int count);

  /// No description provided for @adminSameBoatFlagged.
  ///
  /// In ko, this message translates to:
  /// **'깃발 {count}'**
  String adminSameBoatFlagged(int count);

  /// No description provided for @adminHomeCurationTab.
  ///
  /// In ko, this message translates to:
  /// **'홈 큐레이션'**
  String get adminHomeCurationTab;

  /// No description provided for @adminHomeCurationTitle.
  ///
  /// In ko, this message translates to:
  /// **'홈 화면 큐레이션'**
  String get adminHomeCurationTitle;

  /// No description provided for @adminHomeCurationSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'승인된 상품을 골라 홈 분류별로 최대 10개까지 내보냅니다.'**
  String get adminHomeCurationSubtitle;

  /// No description provided for @adminHomeCurationPool.
  ///
  /// In ko, this message translates to:
  /// **'미배치 (여행상품만)'**
  String get adminHomeCurationPool;

  /// No description provided for @adminHomeCurationOnShelf.
  ///
  /// In ko, this message translates to:
  /// **'이 선반에 올린 상품'**
  String get adminHomeCurationOnShelf;

  /// No description provided for @adminHomeCurationCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}/{limit}'**
  String adminHomeCurationCount(int count, int limit);

  /// No description provided for @adminHomeCurationSend.
  ///
  /// In ko, this message translates to:
  /// **'이 선반으로'**
  String get adminHomeCurationSend;

  /// No description provided for @adminHomeCurationRemove.
  ///
  /// In ko, this message translates to:
  /// **'홈에서 내리기'**
  String get adminHomeCurationRemove;

  /// No description provided for @adminHomeCurationFull.
  ///
  /// In ko, this message translates to:
  /// **'이 선반은 이미 10개입니다. 하나를 내린 뒤 다시 올려 주세요.'**
  String get adminHomeCurationFull;

  /// No description provided for @adminHomeCurationEmptyPool.
  ///
  /// In ko, this message translates to:
  /// **'미배치 공개 상품이 없습니다.'**
  String get adminHomeCurationEmptyPool;

  /// No description provided for @adminHomeCurationEmptyShelf.
  ///
  /// In ko, this message translates to:
  /// **'이 선반에 올린 상품이 없습니다.'**
  String get adminHomeCurationEmptyShelf;

  /// No description provided for @adminHomeCurationMoved.
  ///
  /// In ko, this message translates to:
  /// **'홈 선반에 반영했습니다.'**
  String get adminHomeCurationMoved;

  /// No description provided for @adminHomeCurationCleared.
  ///
  /// In ko, this message translates to:
  /// **'홈에서 내렸습니다.'**
  String get adminHomeCurationCleared;

  /// No description provided for @adminProductPendingQueue.
  ///
  /// In ko, this message translates to:
  /// **'승인 대기 상품'**
  String get adminProductPendingQueue;

  /// No description provided for @adminProductPendingEmpty.
  ///
  /// In ko, this message translates to:
  /// **'승인 대기 중인 상품이 없습니다.'**
  String get adminProductPendingEmpty;

  /// No description provided for @adminAllProducts.
  ///
  /// In ko, this message translates to:
  /// **'등록된 상품'**
  String get adminAllProducts;

  /// No description provided for @adminProductSpecial.
  ///
  /// In ko, this message translates to:
  /// **'기획 스페셜로 첫 화면에 올리기'**
  String get adminProductSpecial;

  /// No description provided for @adminProductApproved.
  ///
  /// In ko, this message translates to:
  /// **'상품이 승인되어 공개되었습니다.'**
  String get adminProductApproved;

  /// No description provided for @adminProductRejected.
  ///
  /// In ko, this message translates to:
  /// **'상품 등록이 거절되었습니다.'**
  String get adminProductRejected;

  /// No description provided for @adminProductSubmitHint.
  ///
  /// In ko, this message translates to:
  /// **'저장하면 승인 대기열로 올라갑니다. 최종 노출은 관리자 승인 후입니다.'**
  String get adminProductSubmitHint;

  /// No description provided for @adminProductSubmitted.
  ///
  /// In ko, this message translates to:
  /// **'승인 요청이 접수되었습니다.'**
  String get adminProductSubmitted;

  /// No description provided for @productFormHeroTitle.
  ///
  /// In ko, this message translates to:
  /// **'여행상품을 등록하세요'**
  String get productFormHeroTitle;

  /// No description provided for @productFormHeroBody.
  ///
  /// In ko, this message translates to:
  /// **'대륙 → 샵 → 상세 일정 → 구성 옵션 순으로 채우면 손님 화면에 바로 쓸 수 있습니다.'**
  String get productFormHeroBody;

  /// No description provided for @productFormSectionLocation.
  ///
  /// In ko, this message translates to:
  /// **'위치'**
  String get productFormSectionLocation;

  /// No description provided for @productFormSectionListing.
  ///
  /// In ko, this message translates to:
  /// **'노출 위치'**
  String get productFormSectionListing;

  /// No description provided for @productFormSectionMedia.
  ///
  /// In ko, this message translates to:
  /// **'대표 사진'**
  String get productFormSectionMedia;

  /// No description provided for @productFormSectionBasics.
  ///
  /// In ko, this message translates to:
  /// **'기본 정보'**
  String get productFormSectionBasics;

  /// No description provided for @productFormSectionItinerary.
  ///
  /// In ko, this message translates to:
  /// **'일정 · 집결'**
  String get productFormSectionItinerary;

  /// No description provided for @productFormSectionIncludes.
  ///
  /// In ko, this message translates to:
  /// **'포함 · 불포함'**
  String get productFormSectionIncludes;

  /// No description provided for @productFormSectionCapacity.
  ///
  /// In ko, this message translates to:
  /// **'인원 · 난이도'**
  String get productFormSectionCapacity;

  /// No description provided for @productFormSectionPricing.
  ///
  /// In ko, this message translates to:
  /// **'가격'**
  String get productFormSectionPricing;

  /// No description provided for @productFormSectionOptions.
  ///
  /// In ko, this message translates to:
  /// **'상품 구성 옵션'**
  String get productFormSectionOptions;

  /// No description provided for @productFormContinent.
  ///
  /// In ko, this message translates to:
  /// **'대륙'**
  String get productFormContinent;

  /// No description provided for @productFormContinentHint.
  ///
  /// In ko, this message translates to:
  /// **'먼저 대륙을 고르면 해당 지역 샵만 보입니다.'**
  String get productFormContinentHint;

  /// No description provided for @productFormShopHint.
  ///
  /// In ko, this message translates to:
  /// **'제휴리조트'**
  String get productFormShopHint;

  /// No description provided for @productFormDirectSelect.
  ///
  /// In ko, this message translates to:
  /// **'직접선택'**
  String get productFormDirectSelect;

  /// No description provided for @productFormSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'한 줄 소개'**
  String get productFormSubtitle;

  /// No description provided for @productFormSubtitleHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 체크다이브 후 2탱크, 같은 밴 동행'**
  String get productFormSubtitleHint;

  /// No description provided for @productFormDurationHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 2박 3일 / 오전 반나절'**
  String get productFormDurationHint;

  /// No description provided for @productFormMeetingPoint.
  ///
  /// In ko, this message translates to:
  /// **'집결 장소'**
  String get productFormMeetingPoint;

  /// No description provided for @productFormMeetingHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 팡라오 리조트 로비 07:30'**
  String get productFormMeetingHint;

  /// No description provided for @productFormSchedule.
  ///
  /// In ko, this message translates to:
  /// **'일정 요약'**
  String get productFormSchedule;

  /// No description provided for @productFormScheduleHint.
  ///
  /// In ko, this message translates to:
  /// **'출발·다이빙·복귀 시간을 순서대로 적어 주세요.'**
  String get productFormScheduleHint;

  /// No description provided for @productFormIncludes.
  ///
  /// In ko, this message translates to:
  /// **'포함 사항'**
  String get productFormIncludes;

  /// No description provided for @productFormIncludesHint.
  ///
  /// In ko, this message translates to:
  /// **'보트, 탱크, 가이드, 픽업 등 줄바꿈으로 구분'**
  String get productFormIncludesHint;

  /// No description provided for @productFormExcludes.
  ///
  /// In ko, this message translates to:
  /// **'불포함 사항'**
  String get productFormExcludes;

  /// No description provided for @productFormExcludesHint.
  ///
  /// In ko, this message translates to:
  /// **'장비 렌탈, 해양공원 입장료 등'**
  String get productFormExcludesHint;

  /// No description provided for @productFormDifficulty.
  ///
  /// In ko, this message translates to:
  /// **'필요 자격 / 난이도'**
  String get productFormDifficulty;

  /// No description provided for @productFormDifficultyHint.
  ///
  /// In ko, this message translates to:
  /// **'예: OW 이상 · 초급~중급'**
  String get productFormDifficultyHint;

  /// No description provided for @productFormMinGuests.
  ///
  /// In ko, this message translates to:
  /// **'최소 인원'**
  String get productFormMinGuests;

  /// No description provided for @productFormMaxGuests.
  ///
  /// In ko, this message translates to:
  /// **'최대 인원'**
  String get productFormMaxGuests;

  /// No description provided for @productFormCancelNote.
  ///
  /// In ko, this message translates to:
  /// **'취소 · 환불 안내'**
  String get productFormCancelNote;

  /// No description provided for @productFormCancelHint.
  ///
  /// In ko, this message translates to:
  /// **'출발 N일 전 규정 등'**
  String get productFormCancelHint;

  /// No description provided for @productFormOptionsHint.
  ///
  /// In ko, this message translates to:
  /// **'룸타입, 탱크 수, 장비, 트랜스퍼처럼 손님이 고르는 구성을 추가하세요.'**
  String get productFormOptionsHint;

  /// No description provided for @productFormOptionName.
  ///
  /// In ko, this message translates to:
  /// **'옵션명'**
  String get productFormOptionName;

  /// No description provided for @productFormOptionDesc.
  ///
  /// In ko, this message translates to:
  /// **'옵션 설명'**
  String get productFormOptionDesc;

  /// No description provided for @productFormOptionConsumer.
  ///
  /// In ko, this message translates to:
  /// **'옵션 소비자가'**
  String get productFormOptionConsumer;

  /// No description provided for @productFormOptionPro.
  ///
  /// In ko, this message translates to:
  /// **'옵션 강사 우대가'**
  String get productFormOptionPro;

  /// No description provided for @productFormAddOption.
  ///
  /// In ko, this message translates to:
  /// **'구성 옵션 추가'**
  String get productFormAddOption;

  /// No description provided for @productFormRemoveOption.
  ///
  /// In ko, this message translates to:
  /// **'옵션 삭제'**
  String get productFormRemoveOption;

  /// No description provided for @productFormPhotoHint.
  ///
  /// In ko, this message translates to:
  /// **'정사각(1:1) 권장. 손님 카드·상세 상단에 사용됩니다.'**
  String get productFormPhotoHint;

  /// No description provided for @productFormSourcePartner.
  ///
  /// In ko, this message translates to:
  /// **'제휴 리조트'**
  String get productFormSourcePartner;

  /// No description provided for @productFormSourceCurated.
  ///
  /// In ko, this message translates to:
  /// **'직접 기획'**
  String get productFormSourceCurated;

  /// No description provided for @productFormSourceHint.
  ///
  /// In ko, this message translates to:
  /// **'제휴 리조트는 카탈로그에서 고릅니다. 직접 기획은 계약 전에도 리조트 이름을 직접 적어 상품을 만들 수 있습니다.'**
  String get productFormSourceHint;

  /// No description provided for @productFormCuratedResort.
  ///
  /// In ko, this message translates to:
  /// **'리조트(샵) 이름'**
  String get productFormCuratedResort;

  /// No description provided for @productFormCuratedResortHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 보홀 프라이빗 빌라 다이브'**
  String get productFormCuratedResortHint;

  /// No description provided for @productFormCuratedLocation.
  ///
  /// In ko, this message translates to:
  /// **'지역'**
  String get productFormCuratedLocation;

  /// No description provided for @productFormCuratedLocationHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 필리핀 보홀 팡라오'**
  String get productFormCuratedLocationHint;

  /// No description provided for @productFormCuratedCountry.
  ///
  /// In ko, this message translates to:
  /// **'국가'**
  String get productFormCuratedCountry;

  /// No description provided for @productFormCuratedCountryHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 필리핀'**
  String get productFormCuratedCountryHint;

  /// No description provided for @productListingKind.
  ///
  /// In ko, this message translates to:
  /// **'홈 선반'**
  String get productListingKind;

  /// No description provided for @productListingExploreOnly.
  ///
  /// In ko, this message translates to:
  /// **'미배치 (여행상품만)'**
  String get productListingExploreOnly;

  /// No description provided for @productListingDiveStar.
  ///
  /// In ko, this message translates to:
  /// **'Dive Star 인증'**
  String get productListingDiveStar;

  /// No description provided for @productListingFavorites.
  ///
  /// In ko, this message translates to:
  /// **'내가 만드는 찐 여행'**
  String get productListingFavorites;

  /// No description provided for @productListingPopular.
  ///
  /// In ko, this message translates to:
  /// **'지금 뜨는 스팟'**
  String get productListingPopular;

  /// No description provided for @productListingNextDeparture.
  ///
  /// In ko, this message translates to:
  /// **'같은 배 · 마감 임박'**
  String get productListingNextDeparture;

  /// No description provided for @productListingCurated.
  ///
  /// In ko, this message translates to:
  /// **'기획 스페셜'**
  String get productListingCurated;

  /// No description provided for @productStatusPending.
  ///
  /// In ko, this message translates to:
  /// **'승인 대기'**
  String get productStatusPending;

  /// No description provided for @productStatusApproved.
  ///
  /// In ko, this message translates to:
  /// **'공개됨'**
  String get productStatusApproved;

  /// No description provided for @productStatusRejected.
  ///
  /// In ko, this message translates to:
  /// **'거절됨'**
  String get productStatusRejected;

  /// No description provided for @productStatusDraft.
  ///
  /// In ko, this message translates to:
  /// **'임시저장'**
  String get productStatusDraft;

  /// No description provided for @partnerOwnProductsOnly.
  ///
  /// In ko, this message translates to:
  /// **'파트너는 본인 샵 상품만 등록·수정할 수 있습니다.'**
  String get partnerOwnProductsOnly;

  /// No description provided for @partnerProductPendingHint.
  ///
  /// In ko, this message translates to:
  /// **'등록 후 관리자 승인이 완료되면 여행상품에 노출됩니다.'**
  String get partnerProductPendingHint;

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
  /// **'제휴 파트너 모니터'**
  String get adminShopMonitor;

  /// No description provided for @adminPricingTitle.
  ///
  /// In ko, this message translates to:
  /// **'정산·할인'**
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
  /// **'이미 나가는 배의 남은 자리'**
  String get communityTideHeadline;

  /// No description provided for @communityTideBody.
  ///
  /// In ko, this message translates to:
  /// **'팀이 있는 상품만 같은 기간에 빈자리를 엽니다. 빈자리를 열지 않은 상품은 탐색에만 있습니다.'**
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
  /// **'출발일과 깃발 마감 중 더 빠른 날 순입니다. 빈자리를 잡으면 예약으로 이어집니다.'**
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

  /// No description provided for @communityFlagOneSeat.
  ///
  /// In ko, this message translates to:
  /// **'깃발을 꽂을 인원만큼 결제시한까지 좌석이 잠깁니다. 결제 화면에서 인원은 바꿀 수 없습니다.'**
  String get communityFlagOneSeat;

  /// No description provided for @communityFlagPartyAsk.
  ///
  /// In ko, this message translates to:
  /// **'몇 자리를 잠글까요? (빈자리 {open})'**
  String communityFlagPartyAsk(int open);

  /// No description provided for @communityFlagPartyLocked.
  ///
  /// In ko, this message translates to:
  /// **'깃발로 잠근 {count}자리 — 결제시한까지 우선권'**
  String communityFlagPartyLocked(int count);

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
  /// **'최대 30장. 첫 장이 목록·상세의 대표 사진이 됩니다.'**
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

  /// No description provided for @communityFilterDeparting.
  ///
  /// In ko, this message translates to:
  /// **'출발'**
  String get communityFilterDeparting;

  /// No description provided for @communityTakeSeat.
  ///
  /// In ko, this message translates to:
  /// **'자리 잡기'**
  String get communityTakeSeat;

  /// No description provided for @communityFlagHoldAsk.
  ///
  /// In ko, this message translates to:
  /// **'선택한 인원만큼 {deadline}까지 좌석이 잠겨 선예약 우선권이 생깁니다(가확정·주황). 그 안에 결제하면 확정(검정)되고, 마감이 지나면 자리가 다시 열립니다.'**
  String communityFlagHoldAsk(String deadline);

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

  /// No description provided for @communitySeatPaid.
  ///
  /// In ko, this message translates to:
  /// **'결제 {count}'**
  String communitySeatPaid(int count);

  /// No description provided for @communitySeatHeld.
  ///
  /// In ko, this message translates to:
  /// **'가확정 {count}'**
  String communitySeatHeld(int count);

  /// No description provided for @communitySeatOpen.
  ///
  /// In ko, this message translates to:
  /// **'빈자리 {count}'**
  String communitySeatOpen(int count);

  /// No description provided for @communityDateToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get communityDateToday;

  /// No description provided for @communityNeedSignIn.
  ///
  /// In ko, this message translates to:
  /// **'깃발을 꽂으려면 로그인하세요.'**
  String get communityNeedSignIn;

  /// No description provided for @communityFlagAlready.
  ///
  /// In ko, this message translates to:
  /// **'이미 이 자리를 가확정했습니다.'**
  String get communityFlagAlready;

  /// No description provided for @communitySeatsShort.
  ///
  /// In ko, this message translates to:
  /// **'이 옵션의 남은 자리가 부족합니다.'**
  String get communitySeatsShort;

  /// No description provided for @communityOfferDetail.
  ///
  /// In ko, this message translates to:
  /// **'이 자리 내용'**
  String get communityOfferDetail;

  /// No description provided for @workbenchSeatOption.
  ///
  /// In ko, this message translates to:
  /// **'자리를 열 옵션'**
  String get workbenchSeatOption;

  /// No description provided for @workbenchSeatBase.
  ///
  /// In ko, this message translates to:
  /// **'기본 상품'**
  String get workbenchSeatBase;

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
  /// **'빈자리를 연 상품이 없습니다. 일반 상품은 탐색에서 봅니다.'**
  String get communityEmpty;

  /// No description provided for @communityDesignPreview.
  ///
  /// In ko, this message translates to:
  /// **'디자인 확인용'**
  String get communityDesignPreview;

  /// No description provided for @communityDesignPreviewFlag.
  ///
  /// In ko, this message translates to:
  /// **'확인용 카드라 자리는 잡지 않습니다.'**
  String get communityDesignPreviewFlag;

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

  /// No description provided for @bookingRequested.
  ///
  /// In ko, this message translates to:
  /// **'예약 요청'**
  String get bookingRequested;

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

  /// No description provided for @bookingPaymentUnpaid.
  ///
  /// In ko, this message translates to:
  /// **'미결제'**
  String get bookingPaymentUnpaid;

  /// No description provided for @bookingPaymentCaptured.
  ///
  /// In ko, this message translates to:
  /// **'결제 완료'**
  String get bookingPaymentCaptured;

  /// No description provided for @bookingPaymentRefunded.
  ///
  /// In ko, this message translates to:
  /// **'환불됨'**
  String get bookingPaymentRefunded;

  /// No description provided for @bookingListEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 예약이 없습니다. 탐색에서 상품을 예약해 보세요.'**
  String get bookingListEmpty;

  /// No description provided for @bookingQuoteBreakdown.
  ///
  /// In ko, this message translates to:
  /// **'요금 내역'**
  String get bookingQuoteBreakdown;

  /// No description provided for @bookingConfirmAndCapture.
  ///
  /// In ko, this message translates to:
  /// **'확정 · 결제 완료'**
  String get bookingConfirmAndCapture;

  /// No description provided for @bookingConfirmDone.
  ///
  /// In ko, this message translates to:
  /// **'예약을 확정하고 결제를 완료 처리했습니다.'**
  String get bookingConfirmDone;

  /// No description provided for @bookingConfirmFailed.
  ///
  /// In ko, this message translates to:
  /// **'확정할 수 없는 예약입니다.'**
  String get bookingConfirmFailed;

  /// No description provided for @bookingDetailCta.
  ///
  /// In ko, this message translates to:
  /// **'상세내역'**
  String get bookingDetailCta;

  /// No description provided for @bookingDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'예약 상세내역'**
  String get bookingDetailTitle;

  /// No description provided for @bookingCreatedAt.
  ///
  /// In ko, this message translates to:
  /// **'요청일'**
  String get bookingCreatedAt;

  /// No description provided for @adminBookingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'예약 확정'**
  String get adminBookingsTitle;

  /// No description provided for @adminBookingsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 집계할 예약이 없습니다.'**
  String get adminBookingsEmpty;

  /// No description provided for @workbenchTitle.
  ///
  /// In ko, this message translates to:
  /// **'출항 작업대'**
  String get workbenchTitle;

  /// No description provided for @workbenchDeckHull.
  ///
  /// In ko, this message translates to:
  /// **'선체'**
  String get workbenchDeckHull;

  /// No description provided for @workbenchDeckStory.
  ///
  /// In ko, this message translates to:
  /// **'이야기'**
  String get workbenchDeckStory;

  /// No description provided for @workbenchDeckRates.
  ///
  /// In ko, this message translates to:
  /// **'요금'**
  String get workbenchDeckRates;

  /// No description provided for @workbenchDeckOptions.
  ///
  /// In ko, this message translates to:
  /// **'옵션'**
  String get workbenchDeckOptions;

  /// No description provided for @workbenchNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get workbenchNext;

  /// No description provided for @workbenchNeedName.
  ///
  /// In ko, this message translates to:
  /// **'상품 이름을 적은 뒤에 저장합니다.'**
  String get workbenchNeedName;

  /// No description provided for @workbenchCategory.
  ///
  /// In ko, this message translates to:
  /// **'분류'**
  String get workbenchCategory;

  /// No description provided for @workbenchCatResort.
  ///
  /// In ko, this message translates to:
  /// **'리조트'**
  String get workbenchCatResort;

  /// No description provided for @workbenchCatLiveaboard.
  ///
  /// In ko, this message translates to:
  /// **'리브어보드'**
  String get workbenchCatLiveaboard;

  /// No description provided for @workbenchCatFun.
  ///
  /// In ko, this message translates to:
  /// **'펀다이빙'**
  String get workbenchCatFun;

  /// No description provided for @workbenchCatCourse.
  ///
  /// In ko, this message translates to:
  /// **'코스'**
  String get workbenchCatCourse;

  /// No description provided for @workbenchCatDay.
  ///
  /// In ko, this message translates to:
  /// **'데이트립'**
  String get workbenchCatDay;

  /// No description provided for @workbenchHullFromShop.
  ///
  /// In ko, this message translates to:
  /// **'선체에서 가져옴'**
  String get workbenchHullFromShop;

  /// No description provided for @workbenchOpenMap.
  ///
  /// In ko, this message translates to:
  /// **'지도에서 열기'**
  String get workbenchOpenMap;

  /// No description provided for @workbenchOpenSeats.
  ///
  /// In ko, this message translates to:
  /// **'같은배에 빈자리 열기'**
  String get workbenchOpenSeats;

  /// No description provided for @workbenchOpenSeatsHint.
  ///
  /// In ko, this message translates to:
  /// **'이미 팀이 있는데 같은 기간에 인원을 더 뽑을 때만 켭니다. 끄면 일반 상품입니다.'**
  String get workbenchOpenSeatsHint;

  /// No description provided for @workbenchSeatCount.
  ///
  /// In ko, this message translates to:
  /// **'자리 수'**
  String get workbenchSeatCount;

  /// No description provided for @workbenchDepartureDate.
  ///
  /// In ko, this message translates to:
  /// **'출발일'**
  String get workbenchDepartureDate;

  /// No description provided for @workbenchFlagDeadline.
  ///
  /// In ko, this message translates to:
  /// **'깃발 마감일'**
  String get workbenchFlagDeadline;

  /// No description provided for @workbenchOpenSeatsNeedFields.
  ///
  /// In ko, this message translates to:
  /// **'빈자리를 열려면 자리 수·출발일·깃발 마감을 넣으세요.'**
  String get workbenchOpenSeatsNeedFields;

  /// No description provided for @workbenchDetail.
  ///
  /// In ko, this message translates to:
  /// **'상세 설명'**
  String get workbenchDetail;

  /// No description provided for @workbenchItinerary.
  ///
  /// In ko, this message translates to:
  /// **'표준 일정표'**
  String get workbenchItinerary;

  /// No description provided for @workbenchAddDay.
  ///
  /// In ko, this message translates to:
  /// **'일차 추가'**
  String get workbenchAddDay;

  /// No description provided for @workbenchDayTitle.
  ///
  /// In ko, this message translates to:
  /// **'{day}일차 제목'**
  String workbenchDayTitle(int day);

  /// No description provided for @workbenchDayBody.
  ///
  /// In ko, this message translates to:
  /// **'내용'**
  String get workbenchDayBody;

  /// No description provided for @workbenchGuestDiver.
  ///
  /// In ko, this message translates to:
  /// **'다이버'**
  String get workbenchGuestDiver;

  /// No description provided for @workbenchGuestNondiver.
  ///
  /// In ko, this message translates to:
  /// **'비다이버'**
  String get workbenchGuestNondiver;

  /// No description provided for @workbenchGuestChild.
  ///
  /// In ko, this message translates to:
  /// **'소아'**
  String get workbenchGuestChild;

  /// No description provided for @workbenchGuestInfant.
  ///
  /// In ko, this message translates to:
  /// **'유아'**
  String get workbenchGuestInfant;

  /// No description provided for @workbenchGuestEnabled.
  ///
  /// In ko, this message translates to:
  /// **'노출'**
  String get workbenchGuestEnabled;

  /// No description provided for @workbenchFoc.
  ///
  /// In ko, this message translates to:
  /// **'FOC'**
  String get workbenchFoc;

  /// No description provided for @workbenchFocPay.
  ///
  /// In ko, this message translates to:
  /// **'결제 인원'**
  String get workbenchFocPay;

  /// No description provided for @workbenchFocFree.
  ///
  /// In ko, this message translates to:
  /// **'무료 인원'**
  String get workbenchFocFree;

  /// No description provided for @workbenchBasePackage.
  ///
  /// In ko, this message translates to:
  /// **'기본 패키지'**
  String get workbenchBasePackage;

  /// No description provided for @workbenchBasePackageHint.
  ///
  /// In ko, this message translates to:
  /// **'이야기·일정 구성이 예약 시 옵션 1로 기본 선택됩니다.'**
  String get workbenchBasePackageHint;

  /// No description provided for @workbenchAddons.
  ///
  /// In ko, this message translates to:
  /// **'추가 옵션 · 패키지 안에서만'**
  String get workbenchAddons;

  /// No description provided for @workbenchIndividuals.
  ///
  /// In ko, this message translates to:
  /// **'개별 상품 · 패키지 대신'**
  String get workbenchIndividuals;

  /// No description provided for @workbenchBookable.
  ///
  /// In ko, this message translates to:
  /// **'예약에 노출'**
  String get workbenchBookable;

  /// No description provided for @workbenchGuestPreview.
  ///
  /// In ko, this message translates to:
  /// **'손님 예약'**
  String get workbenchGuestPreview;

  /// No description provided for @briefTitle.
  ///
  /// In ko, this message translates to:
  /// **'상품등록'**
  String get briefTitle;

  /// No description provided for @briefSectionCover.
  ///
  /// In ko, this message translates to:
  /// **'표지'**
  String get briefSectionCover;

  /// No description provided for @briefSectionPlace.
  ///
  /// In ko, this message translates to:
  /// **'가는 목적지 소개'**
  String get briefSectionPlace;

  /// No description provided for @briefSectionDays.
  ///
  /// In ko, this message translates to:
  /// **'상품 상세 내역'**
  String get briefSectionDays;

  /// No description provided for @detailComposerHint.
  ///
  /// In ko, this message translates to:
  /// **'상품 이야기·일정·표를 한곳에서 작성하세요.'**
  String get detailComposerHint;

  /// No description provided for @detailComposerBold.
  ///
  /// In ko, this message translates to:
  /// **'굵게'**
  String get detailComposerBold;

  /// No description provided for @detailComposerHeading.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get detailComposerHeading;

  /// No description provided for @detailComposerList.
  ///
  /// In ko, this message translates to:
  /// **'목록'**
  String get detailComposerList;

  /// No description provided for @detailComposerTable.
  ///
  /// In ko, this message translates to:
  /// **'표 삽입'**
  String get detailComposerTable;

  /// No description provided for @detailComposerTableSchedule.
  ///
  /// In ko, this message translates to:
  /// **'시간 · 내용'**
  String get detailComposerTableSchedule;

  /// No description provided for @detailComposerTableInclude.
  ///
  /// In ko, this message translates to:
  /// **'포함 · 불포함'**
  String get detailComposerTableInclude;

  /// No description provided for @detailComposerDay.
  ///
  /// In ko, this message translates to:
  /// **'일차 템플릿'**
  String get detailComposerDay;

  /// No description provided for @detailComposerPreview.
  ///
  /// In ko, this message translates to:
  /// **'미리보기'**
  String get detailComposerPreview;

  /// No description provided for @detailComposerEdit.
  ///
  /// In ko, this message translates to:
  /// **'편집'**
  String get detailComposerEdit;

  /// No description provided for @briefSectionTerms.
  ///
  /// In ko, this message translates to:
  /// **'상품 예약 들어가기'**
  String get briefSectionTerms;

  /// No description provided for @bookingEntryBasePackage.
  ///
  /// In ko, this message translates to:
  /// **'기본 패키지'**
  String get bookingEntryBasePackage;

  /// No description provided for @bookingEntryDiverPrice.
  ///
  /// In ko, this message translates to:
  /// **'패키지 1인 가격(다이버)'**
  String get bookingEntryDiverPrice;

  /// No description provided for @bookingEntryHasNondivers.
  ///
  /// In ko, this message translates to:
  /// **'비다이버가 있나요?'**
  String get bookingEntryHasNondivers;

  /// No description provided for @bookingEntryAdultNondiver.
  ///
  /// In ko, this message translates to:
  /// **'성인 비다이버'**
  String get bookingEntryAdultNondiver;

  /// No description provided for @bookingEntryChildInfant.
  ///
  /// In ko, this message translates to:
  /// **'소아 · 유아'**
  String get bookingEntryChildInfant;

  /// No description provided for @bookingEntryUnitPrice.
  ///
  /// In ko, this message translates to:
  /// **'1인 가격'**
  String get bookingEntryUnitPrice;

  /// No description provided for @bookingEntryPreviewSnack.
  ///
  /// In ko, this message translates to:
  /// **'미리보기입니다. 손님은 공개된 상품에서 결제합니다.'**
  String get bookingEntryPreviewSnack;

  /// No description provided for @bookingEntryAddons.
  ///
  /// In ko, this message translates to:
  /// **'추가 구성 옵션'**
  String get bookingEntryAddons;

  /// No description provided for @bookingEntryAddOption.
  ///
  /// In ko, this message translates to:
  /// **'옵션 추가'**
  String get bookingEntryAddOption;

  /// No description provided for @bookingEntryOptionName.
  ///
  /// In ko, this message translates to:
  /// **'옵션명'**
  String get bookingEntryOptionName;

  /// No description provided for @bookingEntryOptionPrice.
  ///
  /// In ko, this message translates to:
  /// **'1인 가격'**
  String get bookingEntryOptionPrice;

  /// No description provided for @bookingEntryTermsToggle.
  ///
  /// In ko, this message translates to:
  /// **'포함 · 불포함'**
  String get bookingEntryTermsToggle;

  /// No description provided for @bookingEntryIndividuals.
  ///
  /// In ko, this message translates to:
  /// **'개별 상품'**
  String get bookingEntryIndividuals;

  /// No description provided for @bookingEntryIndividualsHint.
  ///
  /// In ko, this message translates to:
  /// **'패키지 없이 교육·원데이 다이빙처럼 따로 파는 상품입니다.'**
  String get bookingEntryIndividualsHint;

  /// No description provided for @bookingEntryAddIndividual.
  ///
  /// In ko, this message translates to:
  /// **'개별 상품 추가'**
  String get bookingEntryAddIndividual;

  /// No description provided for @bookingEntryIndividualName.
  ///
  /// In ko, this message translates to:
  /// **'개별 상품명'**
  String get bookingEntryIndividualName;

  /// No description provided for @bookingEntryStayLength.
  ///
  /// In ko, this message translates to:
  /// **'여행 기간'**
  String get bookingEntryStayLength;

  /// No description provided for @bookingEntryNights.
  ///
  /// In ko, this message translates to:
  /// **'{nights}박'**
  String bookingEntryNights(int nights);

  /// No description provided for @bookingEntryDays.
  ///
  /// In ko, this message translates to:
  /// **'{days}일'**
  String bookingEntryDays(int days);

  /// No description provided for @bookingEntryCheckIn.
  ///
  /// In ko, this message translates to:
  /// **'체크인'**
  String get bookingEntryCheckIn;

  /// No description provided for @bookingEntryCheckOut.
  ///
  /// In ko, this message translates to:
  /// **'체크아웃'**
  String get bookingEntryCheckOut;

  /// No description provided for @bookingEntryChangeDates.
  ///
  /// In ko, this message translates to:
  /// **'날짜 변경'**
  String get bookingEntryChangeDates;

  /// No description provided for @bookingEntryPickDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜 선택'**
  String get bookingEntryPickDate;

  /// No description provided for @bookingEntryStayRange.
  ///
  /// In ko, this message translates to:
  /// **'{checkIn} – {checkOut}'**
  String bookingEntryStayRange(String checkIn, String checkOut);

  /// No description provided for @briefSectionPrice.
  ///
  /// In ko, this message translates to:
  /// **'가격'**
  String get briefSectionPrice;

  /// No description provided for @briefSectionSeats.
  ///
  /// In ko, this message translates to:
  /// **'빈자리'**
  String get briefSectionSeats;

  /// No description provided for @briefSourceCatalog.
  ///
  /// In ko, this message translates to:
  /// **'목록의 리조트'**
  String get briefSourceCatalog;

  /// No description provided for @briefSourceNamed.
  ///
  /// In ko, this message translates to:
  /// **'직접 적은 리조트'**
  String get briefSourceNamed;

  /// No description provided for @briefAddLine.
  ///
  /// In ko, this message translates to:
  /// **'한 줄 추가'**
  String get briefAddLine;

  /// No description provided for @briefRemoveLine.
  ///
  /// In ko, this message translates to:
  /// **'줄 삭제'**
  String get briefRemoveLine;

  /// No description provided for @briefOpenSeats.
  ///
  /// In ko, this message translates to:
  /// **'이 일정에 남는 자리를 열까요?'**
  String get briefOpenSeats;

  /// No description provided for @briefFocApplies.
  ///
  /// In ko, this message translates to:
  /// **'적용 대상'**
  String get briefFocApplies;

  /// No description provided for @briefStartPrice.
  ///
  /// In ko, this message translates to:
  /// **'다이버 시작 가격'**
  String get briefStartPrice;

  /// No description provided for @briefGuestCard.
  ///
  /// In ko, this message translates to:
  /// **'손님 카드'**
  String get briefGuestCard;

  /// No description provided for @briefKeepEditing.
  ///
  /// In ko, this message translates to:
  /// **'이어서 두기'**
  String get briefKeepEditing;

  /// No description provided for @briefSubmitReview.
  ///
  /// In ko, this message translates to:
  /// **'승인 대기'**
  String get briefSubmitReview;

  /// No description provided for @briefPublishNow.
  ///
  /// In ko, this message translates to:
  /// **'바로 공개'**
  String get briefPublishNow;

  /// No description provided for @briefTakeDown.
  ///
  /// In ko, this message translates to:
  /// **'내려두기'**
  String get briefTakeDown;

  /// No description provided for @briefKept.
  ///
  /// In ko, this message translates to:
  /// **'이어서 쓸 수 있게 저장했습니다.'**
  String get briefKept;

  /// No description provided for @briefTakenDown.
  ///
  /// In ko, this message translates to:
  /// **'상품을 손님 화면에서 내려 두었습니다.'**
  String get briefTakenDown;

  /// No description provided for @briefSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get briefSave;

  /// No description provided for @briefEdit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get briefEdit;

  /// No description provided for @adminProductDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get adminProductDelete;

  /// No description provided for @adminProductDeleteBody.
  ///
  /// In ko, this message translates to:
  /// **'「{name}」을 삭제하면 상품 목록에서 빠집니다.'**
  String adminProductDeleteBody(String name);

  /// No description provided for @adminProductDeleted.
  ///
  /// In ko, this message translates to:
  /// **'상품을 삭제했습니다.'**
  String get adminProductDeleted;

  /// No description provided for @adminProductRejectNote.
  ///
  /// In ko, this message translates to:
  /// **'거절 사유'**
  String get adminProductRejectNote;

  /// No description provided for @adminProductRejectNoteHint.
  ///
  /// In ko, this message translates to:
  /// **'파트너에게 보이는 이유를 적습니다.'**
  String get adminProductRejectNoteHint;

  /// No description provided for @checkoutStepSelect.
  ///
  /// In ko, this message translates to:
  /// **'예약 선택'**
  String get checkoutStepSelect;

  /// No description provided for @checkoutStepReview.
  ///
  /// In ko, this message translates to:
  /// **'예약한 사항'**
  String get checkoutStepReview;

  /// No description provided for @checkoutStepPay.
  ///
  /// In ko, this message translates to:
  /// **'구매'**
  String get checkoutStepPay;

  /// No description provided for @checkoutReviewCta.
  ///
  /// In ko, this message translates to:
  /// **'예약 내역 보기'**
  String get checkoutReviewCta;

  /// No description provided for @checkoutReviewDetailHint.
  ///
  /// In ko, this message translates to:
  /// **'아래 내용을 확인한 뒤 수정하거나 예약을 확정하세요.'**
  String get checkoutReviewDetailHint;

  /// No description provided for @checkoutBack.
  ///
  /// In ko, this message translates to:
  /// **'이전으로'**
  String get checkoutBack;

  /// No description provided for @checkoutEditBooking.
  ///
  /// In ko, this message translates to:
  /// **'예약수정(변경)하기'**
  String get checkoutEditBooking;

  /// No description provided for @checkoutConfirm.
  ///
  /// In ko, this message translates to:
  /// **'예약 확정'**
  String get checkoutConfirm;

  /// No description provided for @checkoutNeedChoice.
  ///
  /// In ko, this message translates to:
  /// **'기본 패키지 또는 개별 상품을 선택하세요.'**
  String get checkoutNeedChoice;

  /// No description provided for @checkoutGuests.
  ///
  /// In ko, this message translates to:
  /// **'인원'**
  String get checkoutGuests;

  /// No description provided for @checkoutPackageOn.
  ///
  /// In ko, this message translates to:
  /// **'기본 패키지'**
  String get checkoutPackageOn;

  /// No description provided for @checkoutTotal.
  ///
  /// In ko, this message translates to:
  /// **'합계 {amount}원'**
  String checkoutTotal(String amount);

  /// No description provided for @checkoutFocLine.
  ///
  /// In ko, this message translates to:
  /// **'FOC {pay}+{free} · 다이버 무료 {count}명'**
  String checkoutFocLine(int pay, int free, int count);

  /// No description provided for @checkoutGuestsBelowMin.
  ///
  /// In ko, this message translates to:
  /// **'이 상품은 최소 {min}명이 필요합니다.'**
  String checkoutGuestsBelowMin(int min);

  /// No description provided for @checkoutGuestsAboveMax.
  ///
  /// In ko, this message translates to:
  /// **'이 상품은 최대 {max}명까지 예약할 수 있습니다.'**
  String checkoutGuestsAboveMax(int max);

  /// No description provided for @checkoutSignInRequired.
  ///
  /// In ko, this message translates to:
  /// **'예약을 완료하려면 로그인해 주세요.'**
  String get checkoutSignInRequired;

  /// No description provided for @bookingPartySummary.
  ///
  /// In ko, this message translates to:
  /// **'다이버 {diver} · 비다이버 {nondiver} · 아동 {child} · 유아 {infant}'**
  String bookingPartySummary(int diver, int nondiver, int child, int infant);

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
