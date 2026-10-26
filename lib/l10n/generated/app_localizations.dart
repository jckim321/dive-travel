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

  /// No description provided for @checkoutGuestName.
  ///
  /// In ko, this message translates to:
  /// **'예약자 이름'**
  String get checkoutGuestName;

  /// No description provided for @checkoutGuestBirth.
  ///
  /// In ko, this message translates to:
  /// **'생년월일'**
  String get checkoutGuestBirth;

  /// No description provided for @checkoutGuestContact.
  ///
  /// In ko, this message translates to:
  /// **'연락처'**
  String get checkoutGuestContact;

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

  /// No description provided for @simPaySameBoatTitle.
  ///
  /// In ko, this message translates to:
  /// **'결제 확인'**
  String get simPaySameBoatTitle;

  /// No description provided for @simPaySameBoatNotice.
  ///
  /// In ko, this message translates to:
  /// **'테스트 결제입니다. 실제 결제는 아직 연결되지 않았습니다. 결제 완료 시 자리가 확정됩니다.'**
  String get simPaySameBoatNotice;

  /// No description provided for @simPaySameBoatAction.
  ///
  /// In ko, this message translates to:
  /// **'결제하기'**
  String get simPaySameBoatAction;

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
  /// **'결제가 완료되어 자리가 확정되었습니다(테스트 결제).'**
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

  /// No description provided for @myReviewsTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 후기'**
  String get myReviewsTitle;

  /// No description provided for @myReviewsMenu.
  ///
  /// In ko, this message translates to:
  /// **'내가 쓴 후기 보기·수정'**
  String get myReviewsMenu;

  /// No description provided for @myReviewsMenuHint.
  ///
  /// In ko, this message translates to:
  /// **'작성한 후기를 확인하고 수정하거나 삭제할 수 있습니다.'**
  String get myReviewsMenuHint;

  /// No description provided for @myReviewsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 작성한 후기가 없습니다. 여행이 끝난 예약에서 후기를 남겨 보세요.'**
  String get myReviewsEmpty;

  /// No description provided for @myReviewNoProduct.
  ///
  /// In ko, this message translates to:
  /// **'상품 미연결'**
  String get myReviewNoProduct;

  /// No description provided for @myReviewEditedBadge.
  ///
  /// In ko, this message translates to:
  /// **'수정됨'**
  String get myReviewEditedBadge;

  /// No description provided for @myReviewEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'후기 수정'**
  String get myReviewEditTitle;

  /// No description provided for @myReviewEditHint.
  ///
  /// In ko, this message translates to:
  /// **'별점·글·상세만 바꿀 수 있습니다. 리조트·상품·예약은 고정입니다.'**
  String get myReviewEditHint;

  /// No description provided for @myReviewSaveEdit.
  ///
  /// In ko, this message translates to:
  /// **'수정 저장'**
  String get myReviewSaveEdit;

  /// No description provided for @myReviewUpdated.
  ///
  /// In ko, this message translates to:
  /// **'후기를 수정했습니다.'**
  String get myReviewUpdated;

  /// No description provided for @myReviewDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'후기를 삭제할까요?'**
  String get myReviewDeleteTitle;

  /// No description provided for @myReviewDeleteBody.
  ///
  /// In ko, this message translates to:
  /// **'삭제하면 리조트·상품 별점에서 이 후기가 빠지고, 같은 예약에 후기를 다시 쓸 수 있습니다.'**
  String get myReviewDeleteBody;

  /// No description provided for @myReviewDeleteAction.
  ///
  /// In ko, this message translates to:
  /// **'후기 삭제'**
  String get myReviewDeleteAction;

  /// No description provided for @myReviewDeleted.
  ///
  /// In ko, this message translates to:
  /// **'후기를 삭제했습니다.'**
  String get myReviewDeleted;

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

  /// No description provided for @profileGradeShownAsInstructor.
  ///
  /// In ko, this message translates to:
  /// **'화면에는 강사로 보입니다. 저장된 등급은 그대로입니다.'**
  String get profileGradeShownAsInstructor;

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

  /// No description provided for @devRolesTitle.
  ///
  /// In ko, this message translates to:
  /// **'테스트 역할 전환'**
  String get devRolesTitle;

  /// No description provided for @devRolesHint.
  ///
  /// In ko, this message translates to:
  /// **'소유자 계정 전용. Firestore is_admin은 유지하고, 화면만 일반·파트너·관리자로 바꿉니다.'**
  String get devRolesHint;

  /// No description provided for @devRolesDiver.
  ///
  /// In ko, this message translates to:
  /// **'일반 회원'**
  String get devRolesDiver;

  /// No description provided for @devRolesPartner.
  ///
  /// In ko, this message translates to:
  /// **'파트너'**
  String get devRolesPartner;

  /// No description provided for @devRolesAdmin.
  ///
  /// In ko, this message translates to:
  /// **'관리자'**
  String get devRolesAdmin;

  /// No description provided for @devRolesShop.
  ///
  /// In ko, this message translates to:
  /// **'파트너 샵'**
  String get devRolesShop;

  /// No description provided for @devRolesApply.
  ///
  /// In ko, this message translates to:
  /// **'적용'**
  String get devRolesApply;

  /// No description provided for @devRolesApplied.
  ///
  /// In ko, this message translates to:
  /// **'테스트 역할을 적용했습니다.'**
  String get devRolesApplied;

  /// No description provided for @devRolesNeedShop.
  ///
  /// In ko, this message translates to:
  /// **'파트너 역할을 쓰려면 샵을 고르세요.'**
  String get devRolesNeedShop;

  /// No description provided for @devRolesTrialCaption.
  ///
  /// In ko, this message translates to:
  /// **'시험용, 출시 전 제거'**
  String get devRolesTrialCaption;

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

  /// No description provided for @authFirstVisit.
  ///
  /// In ko, this message translates to:
  /// **'처음이에요'**
  String get authFirstVisit;

  /// No description provided for @authWelcomeBack.
  ///
  /// In ko, this message translates to:
  /// **'다시 왔어요'**
  String get authWelcomeBack;

  /// No description provided for @authHeroTitle.
  ///
  /// In ko, this message translates to:
  /// **'다이빙 여행,\n같이 가요'**
  String get authHeroTitle;

  /// No description provided for @authHeroSignupHint.
  ///
  /// In ko, this message translates to:
  /// **'아이디와 비밀번호만 있으면 시작할 수 있어요'**
  String get authHeroSignupHint;

  /// No description provided for @authHeroLoginHint.
  ///
  /// In ko, this message translates to:
  /// **'아이디와 비밀번호로 다시 들어와요'**
  String get authHeroLoginHint;

  /// No description provided for @authSignupPanelTitle.
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get authSignupPanelTitle;

  /// No description provided for @authSignupPanelBody.
  ///
  /// In ko, this message translates to:
  /// **'로그·같은배·예약을 바로 쓸 수 있어요'**
  String get authSignupPanelBody;

  /// No description provided for @authLoginPanelTitle.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get authLoginPanelTitle;

  /// No description provided for @authLoginPanelBody.
  ///
  /// In ko, this message translates to:
  /// **'저장해 둔 여정으로 다시 들어와요'**
  String get authLoginPanelBody;

  /// No description provided for @authNameTag.
  ///
  /// In ko, this message translates to:
  /// **'아이디'**
  String get authNameTag;

  /// No description provided for @authIdRuleHint.
  ///
  /// In ko, this message translates to:
  /// **'한글·영문·숫자·_ 가능'**
  String get authIdRuleHint;

  /// No description provided for @authIdRuleHintLong.
  ///
  /// In ko, this message translates to:
  /// **'앱에서 보이는 이름 · 한글·영문·숫자 모두 가능'**
  String get authIdRuleHintLong;

  /// No description provided for @authIdFieldHint.
  ///
  /// In ko, this message translates to:
  /// **'아이디를 입력하세요'**
  String get authIdFieldHint;

  /// No description provided for @authIdExampleHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 바다거북'**
  String get authIdExampleHint;

  /// No description provided for @authPasswordRuleHint.
  ///
  /// In ko, this message translates to:
  /// **'6자 이상'**
  String get authPasswordRuleHint;

  /// No description provided for @authPasswordFieldHint.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 입력하세요'**
  String get authPasswordFieldHint;

  /// No description provided for @authKeepSignedIn.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서는 계속 로그인해 두기'**
  String get authKeepSignedIn;

  /// No description provided for @authKeepSignedInShort.
  ///
  /// In ko, this message translates to:
  /// **'로그인 상태 유지'**
  String get authKeepSignedInShort;

  /// No description provided for @authWelcomeBanner.
  ///
  /// In ko, this message translates to:
  /// **'다이브 트래블에 오신 것을 환영합니다'**
  String get authWelcomeBanner;

  /// No description provided for @authBrowseFirst.
  ///
  /// In ko, this message translates to:
  /// **'먼저 둘러보기'**
  String get authBrowseFirst;

  /// No description provided for @authFooterCheer.
  ///
  /// In ko, this message translates to:
  /// **'다이브 트래블은 당신의 다음 바다를 응원합니다'**
  String get authFooterCheer;

  /// No description provided for @authFooterContact.
  ///
  /// In ko, this message translates to:
  /// **'문의 | help@divetravel.com'**
  String get authFooterContact;

  /// No description provided for @authSignupHeroBody.
  ///
  /// In ko, this message translates to:
  /// **'30초면 끝나요. 필요한 것만 받을게요.'**
  String get authSignupHeroBody;

  /// No description provided for @authSignupMoreAbout.
  ///
  /// In ko, this message translates to:
  /// **'나를 더 소개하기 (선택)'**
  String get authSignupMoreAbout;

  /// No description provided for @authSignupMoreAboutHint.
  ///
  /// In ko, this message translates to:
  /// **'이름·생년월일·연락처·국적 · 결제 때 자동으로 채워져요'**
  String get authSignupMoreAboutHint;

  /// No description provided for @authSignupLegalName.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get authSignupLegalName;

  /// No description provided for @authSignupLegalNameHint.
  ///
  /// In ko, this message translates to:
  /// **'결제·예약에 쓸 이름'**
  String get authSignupLegalNameHint;

  /// No description provided for @authSignupBirthDate.
  ///
  /// In ko, this message translates to:
  /// **'생년월일'**
  String get authSignupBirthDate;

  /// No description provided for @authSignupPhone.
  ///
  /// In ko, this message translates to:
  /// **'연락처'**
  String get authSignupPhone;

  /// No description provided for @authSignupPhoneHint.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 번호'**
  String get authSignupPhoneHint;

  /// No description provided for @authConsentAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 동의하기'**
  String get authConsentAll;

  /// No description provided for @authConsentTerms.
  ///
  /// In ko, this message translates to:
  /// **'이용약관 동의 (필수)'**
  String get authConsentTerms;

  /// No description provided for @authConsentPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 수집·이용 동의 (필수)'**
  String get authConsentPrivacy;

  /// No description provided for @authConsentMarketing.
  ///
  /// In ko, this message translates to:
  /// **'이벤트·소식 알림 받기 (선택)'**
  String get authConsentMarketing;

  /// No description provided for @authTermsView.
  ///
  /// In ko, this message translates to:
  /// **'보기'**
  String get authTermsView;

  /// No description provided for @authTermsClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get authTermsClose;

  /// No description provided for @authSignupAndBrowse.
  ///
  /// In ko, this message translates to:
  /// **'가입하고 여행 둘러보기'**
  String get authSignupAndBrowse;

  /// No description provided for @authHaveAccountPrompt.
  ///
  /// In ko, this message translates to:
  /// **'이미 계정이 있나요?'**
  String get authHaveAccountPrompt;

  /// No description provided for @authErrorTermsRequired.
  ///
  /// In ko, this message translates to:
  /// **'필수 약관에 동의해 주세요.'**
  String get authErrorTermsRequired;

  /// No description provided for @authStart.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get authStart;

  /// No description provided for @authForgotPasswordNote.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 잊었다면 → 「운영팀에 알려 주세요」 (출시 전 임시)'**
  String get authForgotPasswordNote;

  /// No description provided for @authTrialNote.
  ///
  /// In ko, this message translates to:
  /// **'출시 전 시험용 · 가입과 로그인을 한 화면에서, 입력은 두 칸'**
  String get authTrialNote;

  /// No description provided for @authErrorNameTagRequired.
  ///
  /// In ko, this message translates to:
  /// **'아이디를 적어 주세요.'**
  String get authErrorNameTagRequired;

  /// No description provided for @authErrorNameTagTooLong.
  ///
  /// In ko, this message translates to:
  /// **'아이디가 너무 길어요. 조금 짧게 적어 주세요.'**
  String get authErrorNameTagTooLong;

  /// No description provided for @authNationality.
  ///
  /// In ko, this message translates to:
  /// **'국적(선택)'**
  String get authNationality;

  /// No description provided for @authNationalityNone.
  ///
  /// In ko, this message translates to:
  /// **'선택 안 함'**
  String get authNationalityNone;

  /// No description provided for @profileNationality.
  ///
  /// In ko, this message translates to:
  /// **'국적'**
  String get profileNationality;

  /// No description provided for @profileNationalityEmpty.
  ///
  /// In ko, this message translates to:
  /// **'미입력'**
  String get profileNationalityEmpty;

  /// No description provided for @profileNationalitySave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get profileNationalitySave;

  /// No description provided for @profileNationalityClear.
  ///
  /// In ko, this message translates to:
  /// **'지우기'**
  String get profileNationalityClear;

  /// No description provided for @profileNationalityNeedConsent.
  ///
  /// In ko, this message translates to:
  /// **'국적을 저장하려면 동의가 필요해요'**
  String get profileNationalityNeedConsent;

  /// No description provided for @authWelcome.
  ///
  /// In ko, this message translates to:
  /// **'아이디와 비밀번호로 가입하면 로그·같은배·예약을 바로 쓸 수 있습니다. 제휴 파트너는 관리자가 승격합니다.'**
  String get authWelcome;

  /// 레거시 이메일 라벨(호환).
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get authEmail;

  /// 회원가입 아이디 필드입니다.
  ///
  /// In ko, this message translates to:
  /// **'아이디'**
  String get authLoginId;

  /// 로그인 입력란(아이디 또는 이메일).
  ///
  /// In ko, this message translates to:
  /// **'아이디 또는 이메일'**
  String get authLoginIdOrEmail;

  /// 아이디 형식 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'영문 소문자·숫자·_ 4~20자'**
  String get authLoginIdHint;

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

  /// 로그인 실패 통합 메시지입니다.
  ///
  /// In ko, this message translates to:
  /// **'아이디(또는 이메일)나 비밀번호를 확인해 주세요.'**
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

  /// 비밀번호 찾기 숨김 안내입니다.
  ///
  /// In ko, this message translates to:
  /// **'출시 전까지 비밀번호 찾기는 제공하지 않습니다. 필요하면 관리자에게 문의해 주세요.'**
  String get authPasswordResetHiddenHint;

  /// 중복 이메일 오류입니다.
  ///
  /// In ko, this message translates to:
  /// **'이미 가입된 이메일입니다.'**
  String get authErrorEmailInUse;

  /// 아이디 중복 오류입니다.
  ///
  /// In ko, this message translates to:
  /// **'이 아이디는 이미 쓰이고 있어요. 다른 아이디를 골라 주세요.'**
  String get authErrorLoginIdInUse;

  /// 아이디 형식 오류입니다.
  ///
  /// In ko, this message translates to:
  /// **'아이디는 한글, 영문, 숫자, _만 쓸 수 있어요.'**
  String get authErrorLoginIdFormat;

  /// 예약어 아이디 오류입니다.
  ///
  /// In ko, this message translates to:
  /// **'이 아이디는 쓸 수 없어요. 다른 아이디를 골라 주세요.'**
  String get authErrorLoginIdReserved;

  /// 표시 이름 필수 오류입니다.
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력해 주세요.'**
  String get authErrorDisplayNameRequired;

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

  /// 제휴파트너·관리자가 이 기기용 4자리 핀을 처음 정할 때 제목입니다.
  ///
  /// In ko, this message translates to:
  /// **'기기 핀 정하기'**
  String get devicePinSetupTitle;

  /// No description provided for @devicePinSetupBody.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서만 쓰는 4자리 핀입니다. 서버에는 저장되지 않습니다.'**
  String get devicePinSetupBody;

  /// No description provided for @devicePinUnlockTitle.
  ///
  /// In ko, this message translates to:
  /// **'기기 핀 잠금 해제'**
  String get devicePinUnlockTitle;

  /// No description provided for @devicePinUnlockBody.
  ///
  /// In ko, this message translates to:
  /// **'계정은 로그인된 상태입니다. 핀 4자리로 잠금을 풀어 주세요.'**
  String get devicePinUnlockBody;

  /// No description provided for @devicePinHint.
  ///
  /// In ko, this message translates to:
  /// **'4자리 숫자'**
  String get devicePinHint;

  /// No description provided for @devicePinConfirmHint.
  ///
  /// In ko, this message translates to:
  /// **'한 번 더 입력'**
  String get devicePinConfirmHint;

  /// No description provided for @devicePinSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get devicePinSave;

  /// No description provided for @devicePinMismatch.
  ///
  /// In ko, this message translates to:
  /// **'두 번 입력한 핀이 서로 다릅니다.'**
  String get devicePinMismatch;

  /// No description provided for @devicePinWrong.
  ///
  /// In ko, this message translates to:
  /// **'핀이 올바르지 않습니다. {remain}번 남았습니다.'**
  String devicePinWrong(int remain);

  /// No description provided for @devicePinLockedOut.
  ///
  /// In ko, this message translates to:
  /// **'핀을 5번 틀려 지웠습니다. 아이디와 비밀번호로 다시 로그인해 주세요.'**
  String get devicePinLockedOut;

  /// No description provided for @devicePinSettingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'기기 핀'**
  String get devicePinSettingsTitle;

  /// No description provided for @devicePinSettingsSet.
  ///
  /// In ko, this message translates to:
  /// **'기기 핀 정하기'**
  String get devicePinSettingsSet;

  /// No description provided for @devicePinSettingsChange.
  ///
  /// In ko, this message translates to:
  /// **'기기 핀 바꾸기'**
  String get devicePinSettingsChange;

  /// No description provided for @devicePinSettingsHint.
  ///
  /// In ko, this message translates to:
  /// **'앱을 다시 열 때 이 기기의 핀으로 잠금을 풉니다.'**
  String get devicePinSettingsHint;

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

  /// No description provided for @adminTabDiveStar.
  ///
  /// In ko, this message translates to:
  /// **'다이브스타'**
  String get adminTabDiveStar;

  /// No description provided for @adminTabProducts.
  ///
  /// In ko, this message translates to:
  /// **'상품관리'**
  String get adminTabProducts;

  /// No description provided for @adminTabBookings.
  ///
  /// In ko, this message translates to:
  /// **'예약관리'**
  String get adminTabBookings;

  /// No description provided for @adminTabSettlement.
  ///
  /// In ko, this message translates to:
  /// **'파트너 정산'**
  String get adminTabSettlement;

  /// No description provided for @adminTabSales.
  ///
  /// In ko, this message translates to:
  /// **'판매현황'**
  String get adminTabSales;

  /// No description provided for @adminTabStats.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get adminTabStats;

  /// No description provided for @adminTabReports.
  ///
  /// In ko, this message translates to:
  /// **'경영보고서'**
  String get adminTabReports;

  /// No description provided for @adminNavMore.
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get adminNavMore;

  /// No description provided for @adminNavToolsSection.
  ///
  /// In ko, this message translates to:
  /// **'도구'**
  String get adminNavToolsSection;

  /// No description provided for @adminFilterMore.
  ///
  /// In ko, this message translates to:
  /// **'더 보기'**
  String get adminFilterMore;

  /// No description provided for @adminMembersSubGeneral.
  ///
  /// In ko, this message translates to:
  /// **'일반회원'**
  String get adminMembersSubGeneral;

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

  /// No description provided for @adminPartnersSearch.
  ///
  /// In ko, this message translates to:
  /// **'파트너·샵 검색'**
  String get adminPartnersSearch;

  /// No description provided for @adminProductsSearch.
  ///
  /// In ko, this message translates to:
  /// **'상품 검색'**
  String get adminProductsSearch;

  /// No description provided for @adminProductSourceFilter.
  ///
  /// In ko, this message translates to:
  /// **'출처'**
  String get adminProductSourceFilter;

  /// No description provided for @adminDiveStarSubApplications.
  ///
  /// In ko, this message translates to:
  /// **'신청'**
  String get adminDiveStarSubApplications;

  /// No description provided for @adminDiveStarSubReview.
  ///
  /// In ko, this message translates to:
  /// **'심사·등급'**
  String get adminDiveStarSubReview;

  /// No description provided for @adminDiveStarSubForms.
  ///
  /// In ko, this message translates to:
  /// **'양식'**
  String get adminDiveStarSubForms;

  /// No description provided for @adminDiveStarReviewSearch.
  ///
  /// In ko, this message translates to:
  /// **'샵 이름 검색'**
  String get adminDiveStarReviewSearch;

  /// No description provided for @adminDiveStarReviewPending.
  ///
  /// In ko, this message translates to:
  /// **'심사 대기'**
  String get adminDiveStarReviewPending;

  /// No description provided for @adminDiveStarReviewEmpty.
  ///
  /// In ko, this message translates to:
  /// **'조건에 맞는 파트너가 없습니다.'**
  String get adminDiveStarReviewEmpty;

  /// No description provided for @adminBookingsSubList.
  ///
  /// In ko, this message translates to:
  /// **'예약'**
  String get adminBookingsSubList;

  /// No description provided for @adminBookingsSubPayment.
  ///
  /// In ko, this message translates to:
  /// **'결제 모니터링'**
  String get adminBookingsSubPayment;

  /// No description provided for @adminBookingsSubCustomers.
  ///
  /// In ko, this message translates to:
  /// **'고객 조회'**
  String get adminBookingsSubCustomers;

  /// No description provided for @adminBookingsSubCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소·환불'**
  String get adminBookingsSubCancel;

  /// No description provided for @adminSettlementSubPricing.
  ///
  /// In ko, this message translates to:
  /// **'할인 · 정산 조건'**
  String get adminSettlementSubPricing;

  /// No description provided for @adminSettlementSubHistory.
  ///
  /// In ko, this message translates to:
  /// **'정산 내역'**
  String get adminSettlementSubHistory;

  /// No description provided for @adminPostsCommunityShort.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 글'**
  String get adminPostsCommunityShort;

  /// No description provided for @adminGradeMixInstructorNote.
  ///
  /// In ko, this message translates to:
  /// **'강사 인증이 된 회원은 강사로 보입니다. 저장된 등급은 그대로입니다.'**
  String get adminGradeMixInstructorNote;

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

  /// No description provided for @adminMembersBadgeAdmin.
  ///
  /// In ko, this message translates to:
  /// **'관리자'**
  String get adminMembersBadgeAdmin;

  /// No description provided for @adminMembersLoginId.
  ///
  /// In ko, this message translates to:
  /// **'아이디 · {id}'**
  String adminMembersLoginId(String id);

  /// No description provided for @adminMembersRoleStatus.
  ///
  /// In ko, this message translates to:
  /// **'역할 · {kind} · user_role={role} · 샵={shop}'**
  String adminMembersRoleStatus(String kind, String role, String shop);

  /// No description provided for @adminMembersRoleAdmin.
  ///
  /// In ko, this message translates to:
  /// **'앱 대표관리자'**
  String get adminMembersRoleAdmin;

  /// No description provided for @adminMembersRolePartner.
  ///
  /// In ko, this message translates to:
  /// **'제휴파트너'**
  String get adminMembersRolePartner;

  /// No description provided for @adminMembersRoleDiver.
  ///
  /// In ko, this message translates to:
  /// **'일반회원'**
  String get adminMembersRoleDiver;

  /// No description provided for @adminMembersLeftoverPartnerHint.
  ///
  /// In ko, this message translates to:
  /// **'관리자인데 파트너 플래그가 남아 있습니다. 「파트너 해제」로 정리하세요.'**
  String get adminMembersLeftoverPartnerHint;

  /// No description provided for @adminMembersPromotePartner.
  ///
  /// In ko, this message translates to:
  /// **'파트너로 승격'**
  String get adminMembersPromotePartner;

  /// No description provided for @adminMembersDemotePartner.
  ///
  /// In ko, this message translates to:
  /// **'파트너 해제'**
  String get adminMembersDemotePartner;

  /// No description provided for @adminMembersPromoteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님을 제휴파트너로 승격합니다. 연결할 샵을 고르거나 새 샵을 만드세요.'**
  String adminMembersPromoteConfirm(String name);

  /// No description provided for @adminMembersDemoteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님의 파트너를 해제할까요? (샵 {shop} 연결이 끊깁니다. 샵 자체는 남습니다.)'**
  String adminMembersDemoteConfirm(String name, String shop);

  /// No description provided for @adminMembersPromotePickShop.
  ///
  /// In ko, this message translates to:
  /// **'기존 샵 연결'**
  String get adminMembersPromotePickShop;

  /// No description provided for @adminMembersPromoteNewShop.
  ///
  /// In ko, this message translates to:
  /// **'새 샵 만들기'**
  String get adminMembersPromoteNewShop;

  /// No description provided for @adminMembersNewShopName.
  ///
  /// In ko, this message translates to:
  /// **'새 샵 이름'**
  String get adminMembersNewShopName;

  /// No description provided for @adminMembersNoUnownedShops.
  ///
  /// In ko, this message translates to:
  /// **'주인이 없는 샵이 없습니다. 새 샵을 만드세요.'**
  String get adminMembersNoUnownedShops;

  /// No description provided for @adminMembersAlreadyPartner.
  ///
  /// In ko, this message translates to:
  /// **'이미 파트너인 회원입니다.'**
  String get adminMembersAlreadyPartner;

  /// No description provided for @adminMembersShopOwned.
  ///
  /// In ko, this message translates to:
  /// **'이미 주인이 있는 샵입니다.'**
  String get adminMembersShopOwned;

  /// No description provided for @adminMembersPromoteDone.
  ///
  /// In ko, this message translates to:
  /// **'파트너로 승격했습니다.'**
  String get adminMembersPromoteDone;

  /// No description provided for @adminMembersDemoteDone.
  ///
  /// In ko, this message translates to:
  /// **'파트너를 해제했습니다.'**
  String get adminMembersDemoteDone;

  /// No description provided for @adminMembersPromoteFailed.
  ///
  /// In ko, this message translates to:
  /// **'승격에 실패했습니다.'**
  String get adminMembersPromoteFailed;

  /// No description provided for @adminMembersDemoteFailed.
  ///
  /// In ko, this message translates to:
  /// **'파트너 해제에 실패했습니다.'**
  String get adminMembersDemoteFailed;

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

  /// No description provided for @adminTabContracts.
  ///
  /// In ko, this message translates to:
  /// **'제휴 계약'**
  String get adminTabContracts;

  /// No description provided for @adminTabOps.
  ///
  /// In ko, this message translates to:
  /// **'운영'**
  String get adminTabOps;

  /// No description provided for @adminContractsSubOverview.
  ///
  /// In ko, this message translates to:
  /// **'계약 현황'**
  String get adminContractsSubOverview;

  /// No description provided for @adminContractsSubVault.
  ///
  /// In ko, this message translates to:
  /// **'서류함'**
  String get adminContractsSubVault;

  /// No description provided for @adminContractsSubTerms.
  ///
  /// In ko, this message translates to:
  /// **'계약 조건'**
  String get adminContractsSubTerms;

  /// No description provided for @adminContractsSubInbox.
  ///
  /// In ko, this message translates to:
  /// **'제안 받은편지함'**
  String get adminContractsSubInbox;

  /// No description provided for @adminTermsMissing.
  ///
  /// In ko, this message translates to:
  /// **'미입력'**
  String get adminTermsMissing;

  /// No description provided for @adminTermsCommission.
  ///
  /// In ko, this message translates to:
  /// **'수수료율'**
  String get adminTermsCommission;

  /// No description provided for @adminTermsParty.
  ///
  /// In ko, this message translates to:
  /// **'인원 할인'**
  String get adminTermsParty;

  /// No description provided for @adminTermsSeason.
  ///
  /// In ko, this message translates to:
  /// **'계절 가격할인'**
  String get adminTermsSeason;

  /// No description provided for @adminTermsFoc.
  ///
  /// In ko, this message translates to:
  /// **'강사 FOC'**
  String get adminTermsFoc;

  /// No description provided for @adminTermsFocPay.
  ///
  /// In ko, this message translates to:
  /// **'유료 인원'**
  String get adminTermsFocPay;

  /// No description provided for @adminTermsFocFree.
  ///
  /// In ko, this message translates to:
  /// **'무료 인원'**
  String get adminTermsFocFree;

  /// No description provided for @adminTermsPeriod.
  ///
  /// In ko, this message translates to:
  /// **'계약 기간'**
  String get adminTermsPeriod;

  /// No description provided for @adminTermsFrom.
  ///
  /// In ko, this message translates to:
  /// **'시작일'**
  String get adminTermsFrom;

  /// No description provided for @adminTermsUntil.
  ///
  /// In ko, this message translates to:
  /// **'종료일'**
  String get adminTermsUntil;

  /// No description provided for @adminTermsClear.
  ///
  /// In ko, this message translates to:
  /// **'지우기'**
  String get adminTermsClear;

  /// No description provided for @adminTermsSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get adminTermsSave;

  /// No description provided for @adminTermsSaved.
  ///
  /// In ko, this message translates to:
  /// **'저장했어요'**
  String get adminTermsSaved;

  /// No description provided for @adminTermsUnchanged.
  ///
  /// In ko, this message translates to:
  /// **'바뀐 게 없어요'**
  String get adminTermsUnchanged;

  /// No description provided for @adminTermsHistory.
  ///
  /// In ko, this message translates to:
  /// **'변경 이력'**
  String get adminTermsHistory;

  /// No description provided for @adminTermsHistoryEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 변경 이력이 없어요.'**
  String get adminTermsHistoryEmpty;

  /// No description provided for @adminTermsBadNumber.
  ///
  /// In ko, this message translates to:
  /// **'숫자를 허용 범위 안에서 적어 주세요.'**
  String get adminTermsBadNumber;

  /// No description provided for @adminTermsFocPair.
  ///
  /// In ko, this message translates to:
  /// **'강사 FOC는 10+1처럼 둘 다 적거나 둘 다 비워 주세요.'**
  String get adminTermsFocPair;

  /// No description provided for @adminTermsBadPeriod.
  ///
  /// In ko, this message translates to:
  /// **'끝나는 날은 시작하는 날과 같거나 이후여야 해요.'**
  String get adminTermsBadPeriod;

  /// No description provided for @partnerPromoChip.
  ///
  /// In ko, this message translates to:
  /// **'프로모션'**
  String get partnerPromoChip;

  /// No description provided for @partnerPromoSend.
  ///
  /// In ko, this message translates to:
  /// **'보내기'**
  String get partnerPromoSend;

  /// No description provided for @partnerPromoSent.
  ///
  /// In ko, this message translates to:
  /// **'보냈어요'**
  String get partnerPromoSent;

  /// No description provided for @partnerPromoNote.
  ///
  /// In ko, this message translates to:
  /// **'한 줄 설명'**
  String get partnerPromoNote;

  /// No description provided for @partnerPromoKind.
  ///
  /// In ko, this message translates to:
  /// **'종류'**
  String get partnerPromoKind;

  /// No description provided for @partnerPromoBadNote.
  ///
  /// In ko, this message translates to:
  /// **'설명을 1자에서 80자 사이로 적어 주세요.'**
  String get partnerPromoBadNote;

  /// No description provided for @partnerPromoBadPeriod.
  ///
  /// In ko, this message translates to:
  /// **'기간은 시작일부터 1년 안으로 적어 주세요.'**
  String get partnerPromoBadPeriod;

  /// No description provided for @partnerPromoBadKind.
  ///
  /// In ko, this message translates to:
  /// **'종류를 골라 주세요.'**
  String get partnerPromoBadKind;

  /// No description provided for @partnerPromoBadDay.
  ///
  /// In ko, this message translates to:
  /// **'날짜는 2026-10-01처럼 적어 주세요.'**
  String get partnerPromoBadDay;

  /// No description provided for @adminPromoNew.
  ///
  /// In ko, this message translates to:
  /// **'새 제안'**
  String get adminPromoNew;

  /// No description provided for @adminPromoHandled.
  ///
  /// In ko, this message translates to:
  /// **'처리함'**
  String get adminPromoHandled;

  /// No description provided for @adminPromoMark.
  ///
  /// In ko, this message translates to:
  /// **'처리함으로 표시'**
  String get adminPromoMark;

  /// No description provided for @adminPromoEmpty.
  ///
  /// In ko, this message translates to:
  /// **'도착한 제안이 없어요.'**
  String get adminPromoEmpty;

  /// No description provided for @adminContractsComingSoon.
  ///
  /// In ko, this message translates to:
  /// **'준비 중'**
  String get adminContractsComingSoon;

  /// No description provided for @adminContractStatusNone.
  ///
  /// In ko, this message translates to:
  /// **'미체결'**
  String get adminContractStatusNone;

  /// No description provided for @adminContractStatusAwaiting.
  ///
  /// In ko, this message translates to:
  /// **'서명 대기'**
  String get adminContractStatusAwaiting;

  /// No description provided for @adminContractStatusExecuted.
  ///
  /// In ko, this message translates to:
  /// **'체결'**
  String get adminContractStatusExecuted;

  /// No description provided for @adminContractStatusExpiring.
  ///
  /// In ko, this message translates to:
  /// **'만료 임박'**
  String get adminContractStatusExpiring;

  /// No description provided for @adminVaultUpload.
  ///
  /// In ko, this message translates to:
  /// **'PDF 올리기'**
  String get adminVaultUpload;

  /// No description provided for @adminVaultSend.
  ///
  /// In ko, this message translates to:
  /// **'파트너에게 발송'**
  String get adminVaultSend;

  /// No description provided for @adminVaultVoid.
  ///
  /// In ko, this message translates to:
  /// **'폐기'**
  String get adminVaultVoid;

  /// No description provided for @adminVaultDownload.
  ///
  /// In ko, this message translates to:
  /// **'체결본 받기'**
  String get adminVaultDownload;

  /// No description provided for @adminVaultPickShop.
  ///
  /// In ko, this message translates to:
  /// **'제휴파트너를 선택하세요'**
  String get adminVaultPickShop;

  /// No description provided for @adminVaultTitleHint.
  ///
  /// In ko, this message translates to:
  /// **'문서 제목'**
  String get adminVaultTitleHint;

  /// No description provided for @adminVaultVersionHint.
  ///
  /// In ko, this message translates to:
  /// **'버전'**
  String get adminVaultVersionHint;

  /// No description provided for @adminVaultKindMaster.
  ///
  /// In ko, this message translates to:
  /// **'기본계약'**
  String get adminVaultKindMaster;

  /// No description provided for @adminVaultKindAnnex.
  ///
  /// In ko, this message translates to:
  /// **'부속 약정서'**
  String get adminVaultKindAnnex;

  /// No description provided for @adminVaultEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이 파트너 서류함이 비어 있어요.'**
  String get adminVaultEmpty;

  /// No description provided for @partnerVaultTitle.
  ///
  /// In ko, this message translates to:
  /// **'서류함'**
  String get partnerVaultTitle;

  /// No description provided for @partnerVaultAwaiting.
  ///
  /// In ko, this message translates to:
  /// **'서명 대기'**
  String get partnerVaultAwaiting;

  /// No description provided for @partnerVaultExecuted.
  ///
  /// In ko, this message translates to:
  /// **'체결'**
  String get partnerVaultExecuted;

  /// No description provided for @partnerVaultEmpty.
  ///
  /// In ko, this message translates to:
  /// **'도착한 계약 서류가 없어요.'**
  String get partnerVaultEmpty;

  /// No description provided for @partnerVaultOpen.
  ///
  /// In ko, this message translates to:
  /// **'열람·서명'**
  String get partnerVaultOpen;

  /// No description provided for @partnerVaultSign.
  ///
  /// In ko, this message translates to:
  /// **'서명하여 체결'**
  String get partnerVaultSign;

  /// No description provided for @partnerVaultRevision.
  ///
  /// In ko, this message translates to:
  /// **'수정 요청'**
  String get partnerVaultRevision;

  /// No description provided for @partnerVaultRevisionHint.
  ///
  /// In ko, this message translates to:
  /// **'수정이 필요한 내용을 적어 주세요'**
  String get partnerVaultRevisionHint;

  /// No description provided for @partnerVaultShaMismatch.
  ///
  /// In ko, this message translates to:
  /// **'파일이 바뀌었습니다. 서명을 중단했어요. 운영팀에 문의해 주세요.'**
  String get partnerVaultShaMismatch;

  /// No description provided for @partnerVaultAckView.
  ///
  /// In ko, this message translates to:
  /// **'문서를 열람했습니다'**
  String get partnerVaultAckView;

  /// No description provided for @partnerVaultAgree.
  ///
  /// In ko, this message translates to:
  /// **'계약 내용에 동의합니다'**
  String get partnerVaultAgree;

  /// No description provided for @partnerVaultSignerName.
  ///
  /// In ko, this message translates to:
  /// **'서명자 이름'**
  String get partnerVaultSignerName;

  /// No description provided for @partnerVaultSignature.
  ///
  /// In ko, this message translates to:
  /// **'손글씨 서명'**
  String get partnerVaultSignature;

  /// No description provided for @partnerVaultDownload.
  ///
  /// In ko, this message translates to:
  /// **'원본·서명 정보 받기'**
  String get partnerVaultDownload;

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
  /// **'이름·아이디·이메일·샵 검색'**
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
  /// **'반려'**
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
  /// **'다이브스타 등급은 관리자가 심사 양식으로 점수·게이트를 입력한 뒤 「등급 확정」할 때 부여됩니다. 수동 「등급 수정」도 가능합니다.'**
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

  /// No description provided for @adminSameBoatHide.
  ///
  /// In ko, this message translates to:
  /// **'숨김'**
  String get adminSameBoatHide;

  /// No description provided for @adminSameBoatReopen.
  ///
  /// In ko, this message translates to:
  /// **'다시 열기'**
  String get adminSameBoatReopen;

  /// No description provided for @adminSameBoatHiddenTitle.
  ///
  /// In ko, this message translates to:
  /// **'숨긴 자리'**
  String get adminSameBoatHiddenTitle;

  /// No description provided for @adminSameBoatHiddenEmpty.
  ///
  /// In ko, this message translates to:
  /// **'숨긴 빈자리가 없습니다.'**
  String get adminSameBoatHiddenEmpty;

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
  /// **'빈자리를 열 수 있는 승인된 상품이 없습니다. 관리자가 상품을 승인한 뒤 빈자리를 열 수 있습니다.'**
  String get sameBoatSeatsNoProducts;

  /// No description provided for @sameBoatHubAwaitingPublishTitle.
  ///
  /// In ko, this message translates to:
  /// **'상품 승인 대기'**
  String get sameBoatHubAwaitingPublishTitle;

  /// No description provided for @sameBoatHubAwaitingPublishHint.
  ///
  /// In ko, this message translates to:
  /// **'아직 공개되지 않은 상품입니다. 좌석 신청은 승인된 상품만 가능합니다.'**
  String get sameBoatHubAwaitingPublishHint;

  /// No description provided for @sameBoatHubAwaitingPublishEmpty.
  ///
  /// In ko, this message translates to:
  /// **'승인 대기 중인 상품이 없습니다.'**
  String get sameBoatHubAwaitingPublishEmpty;

  /// No description provided for @partnerProductListEmpty.
  ///
  /// In ko, this message translates to:
  /// **'등록한 상품이 없습니다. 저장하면 이 목록에 「승인 대기」로 나타납니다.'**
  String get partnerProductListEmpty;

  /// No description provided for @shopStatRefreshFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장은 됐지만 목록을 새로고치지 못했습니다. 당겨서 새로고침하거나 화면을 다시 열어 주세요.'**
  String get shopStatRefreshFailed;

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

  /// No description provided for @sameBoatSeatsWaiting.
  ///
  /// In ko, this message translates to:
  /// **'승인 대기 중'**
  String get sameBoatSeatsWaiting;

  /// No description provided for @sameBoatSeatsAlreadyPending.
  ///
  /// In ko, this message translates to:
  /// **'이미 승인 대기 중인 요청이 있습니다.'**
  String get sameBoatSeatsAlreadyPending;

  /// No description provided for @sameBoatSeatsAlreadyLive.
  ///
  /// In ko, this message translates to:
  /// **'이미 같은배에 게시된 상품입니다.'**
  String get sameBoatSeatsAlreadyLive;

  /// No description provided for @sameBoatApproveIncomplete.
  ///
  /// In ko, this message translates to:
  /// **'좌석·출발일 정보가 부족해 승인할 수 없습니다.'**
  String get sameBoatApproveIncomplete;

  /// No description provided for @sameBoatHubApprove.
  ///
  /// In ko, this message translates to:
  /// **'승인'**
  String get sameBoatHubApprove;

  /// No description provided for @sameBoatHubOpenSeats.
  ///
  /// In ko, this message translates to:
  /// **'빈자리 열기'**
  String get sameBoatHubOpenSeats;

  /// No description provided for @partnerSameBoatRequestsTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 같은배 요청'**
  String get partnerSameBoatRequestsTitle;

  /// No description provided for @partnerSameBoatRequestsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'요청한 빈자리가 없습니다.'**
  String get partnerSameBoatRequestsEmpty;

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

  /// No description provided for @adminDiveStarAssessmentMenu.
  ///
  /// In ko, this message translates to:
  /// **'다이브스타 심사'**
  String get adminDiveStarAssessmentMenu;

  /// No description provided for @adminDiveStarAssessmentTitle.
  ///
  /// In ko, this message translates to:
  /// **'다이브스타 심사'**
  String get adminDiveStarAssessmentTitle;

  /// No description provided for @adminDiveStarAssessmentHint.
  ///
  /// In ko, this message translates to:
  /// **'저장하면 합계와 후보 등급만 계산됩니다. 손님 화면에 보이는 별은 「등급 확정」을 눌러야 바뀝니다.'**
  String get adminDiveStarAssessmentHint;

  /// No description provided for @adminDiveStarAssessmentFormSection.
  ///
  /// In ko, this message translates to:
  /// **'새 심사 입력'**
  String get adminDiveStarAssessmentFormSection;

  /// No description provided for @adminDiveStarAssessmentType.
  ///
  /// In ko, this message translates to:
  /// **'심사 유형'**
  String get adminDiveStarAssessmentType;

  /// No description provided for @adminDiveStarTypeOnsite.
  ///
  /// In ko, this message translates to:
  /// **'현장 심사'**
  String get adminDiveStarTypeOnsite;

  /// No description provided for @adminDiveStarTypeMystery.
  ///
  /// In ko, this message translates to:
  /// **'미스터리 심사'**
  String get adminDiveStarTypeMystery;

  /// No description provided for @adminDiveStarTypeDocument.
  ///
  /// In ko, this message translates to:
  /// **'서류 심사'**
  String get adminDiveStarTypeDocument;

  /// No description provided for @adminDiveStarTrialMenu.
  ///
  /// In ko, this message translates to:
  /// **'v2 시험 심사'**
  String get adminDiveStarTrialMenu;

  /// No description provided for @adminDiveStarTrialTitle.
  ///
  /// In ko, this message translates to:
  /// **'다이브스타 심사 (v2 시험)'**
  String get adminDiveStarTrialTitle;

  /// No description provided for @adminDiveStarTrialHint.
  ///
  /// In ko, this message translates to:
  /// **'초안 v2 양식으로 미리보기만 합니다. 저장은 3단계에서 됩니다. 지금 활성 양식은 v1로 유지됩니다.'**
  String get adminDiveStarTrialHint;

  /// No description provided for @adminDiveStarTrialNoDraft.
  ///
  /// In ko, this message translates to:
  /// **'항목이 있는 v2 초안 양식이 없습니다. 먼저 「심사 양식 가져오기」로 저장하세요.'**
  String get adminDiveStarTrialNoDraft;

  /// No description provided for @adminDiveStarTrialSaveLocked.
  ///
  /// In ko, this message translates to:
  /// **'시험 모드에서는 저장할 수 없습니다. 3단계에서 저장됩니다.'**
  String get adminDiveStarTrialSaveLocked;

  /// No description provided for @adminDiveStarFillMaxScores.
  ///
  /// In ko, this message translates to:
  /// **'모든 항목 만점으로 채우기'**
  String get adminDiveStarFillMaxScores;

  /// No description provided for @adminDiveStarGatesSection.
  ///
  /// In ko, this message translates to:
  /// **'필수 게이트 (하나라도 탈락이면 별 부여 불가)'**
  String get adminDiveStarGatesSection;

  /// No description provided for @adminDiveStarCountryGatesSection.
  ///
  /// In ko, this message translates to:
  /// **'국가별 게이트 (최대 {max}개)'**
  String adminDiveStarCountryGatesSection(int max);

  /// No description provided for @adminDiveStarCountryGateName.
  ///
  /// In ko, this message translates to:
  /// **'게이트 이름'**
  String get adminDiveStarCountryGateName;

  /// No description provided for @adminDiveStarCountryGateCriteria.
  ///
  /// In ko, this message translates to:
  /// **'기준'**
  String get adminDiveStarCountryGateCriteria;

  /// No description provided for @adminDiveStarCountryGateAdd.
  ///
  /// In ko, this message translates to:
  /// **'국가 게이트 추가'**
  String get adminDiveStarCountryGateAdd;

  /// No description provided for @adminDiveStarAreaApplicable.
  ///
  /// In ko, this message translates to:
  /// **'적용'**
  String get adminDiveStarAreaApplicable;

  /// No description provided for @adminDiveStarAreaNotApplicable.
  ///
  /// In ko, this message translates to:
  /// **'해당없음'**
  String get adminDiveStarAreaNotApplicable;

  /// No description provided for @adminDiveStarAreaNaBlocked.
  ///
  /// In ko, this message translates to:
  /// **'안전 영역은 해당없음으로 둘 수 없습니다.'**
  String get adminDiveStarAreaNaBlocked;

  /// No description provided for @adminDiveStarItemsSection.
  ///
  /// In ko, this message translates to:
  /// **'항목별 채점'**
  String get adminDiveStarItemsSection;

  /// No description provided for @adminDiveStarItemScore.
  ///
  /// In ko, this message translates to:
  /// **'득점 (0–{max})'**
  String adminDiveStarItemScore(int max);

  /// No description provided for @adminDiveStarItemGuidance.
  ///
  /// In ko, this message translates to:
  /// **'채점 기준·증빙·근거'**
  String get adminDiveStarItemGuidance;

  /// No description provided for @adminDiveStarItemCriteria.
  ///
  /// In ko, this message translates to:
  /// **'기준'**
  String get adminDiveStarItemCriteria;

  /// No description provided for @adminDiveStarItemEvidence.
  ///
  /// In ko, this message translates to:
  /// **'증빙'**
  String get adminDiveStarItemEvidence;

  /// No description provided for @adminDiveStarItemBasis.
  ///
  /// In ko, this message translates to:
  /// **'근거'**
  String get adminDiveStarItemBasis;

  /// No description provided for @adminDiveStarAreaProgress.
  ///
  /// In ko, this message translates to:
  /// **'입력 {filled}/{total}'**
  String adminDiveStarAreaProgress(int filled, int total);

  /// No description provided for @adminDiveStarItemUnscored.
  ///
  /// In ko, this message translates to:
  /// **'미입력'**
  String get adminDiveStarItemUnscored;

  /// No description provided for @adminDiveStarMysteryVisits.
  ///
  /// In ko, this message translates to:
  /// **'미스터리 방문 횟수 (0–20)'**
  String get adminDiveStarMysteryVisits;

  /// No description provided for @adminDiveStarAuditor1.
  ///
  /// In ko, this message translates to:
  /// **'심사관 1'**
  String get adminDiveStarAuditor1;

  /// No description provided for @adminDiveStarAuditor2.
  ///
  /// In ko, this message translates to:
  /// **'심사관 2'**
  String get adminDiveStarAuditor2;

  /// No description provided for @adminDiveStarAreaRateLine.
  ///
  /// In ko, this message translates to:
  /// **'{area}: {earned}/{max} ({pct}%)'**
  String adminDiveStarAreaRateLine(String area, int earned, int max, int pct);

  /// No description provided for @adminDiveStarReasonGateFailed.
  ///
  /// In ko, this message translates to:
  /// **'게이트 미통과로 후보 등급 0'**
  String get adminDiveStarReasonGateFailed;

  /// No description provided for @adminDiveStarReasonBelowStar1.
  ///
  /// In ko, this message translates to:
  /// **'1스타 기준 점수 미달'**
  String get adminDiveStarReasonBelowStar1;

  /// No description provided for @adminDiveStarReasonStar1.
  ///
  /// In ko, this message translates to:
  /// **'1스타 기준 충족'**
  String get adminDiveStarReasonStar1;

  /// No description provided for @adminDiveStarReasonStar2.
  ///
  /// In ko, this message translates to:
  /// **'2스타 기준 충족'**
  String get adminDiveStarReasonStar2;

  /// No description provided for @adminDiveStarReasonStar3.
  ///
  /// In ko, this message translates to:
  /// **'3스타 기준 충족'**
  String get adminDiveStarReasonStar3;

  /// No description provided for @adminDiveStarReasonSafety.
  ///
  /// In ko, this message translates to:
  /// **'총점은 충분하나 안전 영역 비율 미달'**
  String get adminDiveStarReasonSafety;

  /// No description provided for @adminDiveStarReasonAreaRatio.
  ///
  /// In ko, this message translates to:
  /// **'3스타용 영역별 최소 비율 미달'**
  String get adminDiveStarReasonAreaRatio;

  /// No description provided for @adminDiveStarReasonMystery.
  ///
  /// In ko, this message translates to:
  /// **'3스타용 미스터리 방문 횟수 미달'**
  String get adminDiveStarReasonMystery;

  /// No description provided for @adminDiveStarReasonOther.
  ///
  /// In ko, this message translates to:
  /// **'후보 등급 사유: {code}'**
  String adminDiveStarReasonOther(String code);

  /// No description provided for @adminDiveStarGatePass.
  ///
  /// In ko, this message translates to:
  /// **'통과'**
  String get adminDiveStarGatePass;

  /// No description provided for @adminDiveStarGateFail.
  ///
  /// In ko, this message translates to:
  /// **'탈락'**
  String get adminDiveStarGateFail;

  /// No description provided for @adminDiveStarAreasSection.
  ///
  /// In ko, this message translates to:
  /// **'영역별 점수'**
  String get adminDiveStarAreasSection;

  /// No description provided for @adminDiveStarAreaComment.
  ///
  /// In ko, this message translates to:
  /// **'코멘트 (선택)'**
  String get adminDiveStarAreaComment;

  /// No description provided for @adminDiveStarAssessmentSave.
  ///
  /// In ko, this message translates to:
  /// **'심사 저장'**
  String get adminDiveStarAssessmentSave;

  /// No description provided for @adminDiveStarAssessmentSaved.
  ///
  /// In ko, this message translates to:
  /// **'심사를 저장했습니다. 아직 샵 등급은 바뀌지 않았습니다.'**
  String get adminDiveStarAssessmentSaved;

  /// No description provided for @adminDiveStarAssessmentRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get adminDiveStarAssessmentRetry;

  /// No description provided for @adminDiveStarPreview.
  ///
  /// In ko, this message translates to:
  /// **'합계 {score}점 · 후보 {grade}스타'**
  String adminDiveStarPreview(int score, int grade);

  /// No description provided for @adminDiveStarGatesOk.
  ///
  /// In ko, this message translates to:
  /// **'게이트 전부 통과'**
  String get adminDiveStarGatesOk;

  /// No description provided for @adminDiveStarGatesBlocked.
  ///
  /// In ko, this message translates to:
  /// **'게이트 미통과 — 후보 등급 0'**
  String get adminDiveStarGatesBlocked;

  /// No description provided for @adminDiveStarConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'등급 확정'**
  String get adminDiveStarConfirmTitle;

  /// No description provided for @adminDiveStarConfirmBody.
  ///
  /// In ko, this message translates to:
  /// **'후보 {grade}스타(합계 {score}점)를 이 샵에 반영할까요?'**
  String adminDiveStarConfirmBody(int grade, int score);

  /// No description provided for @adminDiveStarConfirmAction.
  ///
  /// In ko, this message translates to:
  /// **'등급 확정'**
  String get adminDiveStarConfirmAction;

  /// No description provided for @adminDiveStarConfirmed.
  ///
  /// In ko, this message translates to:
  /// **'샵 다이브스타 등급을 확정했습니다.'**
  String get adminDiveStarConfirmed;

  /// No description provided for @adminDiveStarAlreadyConfirmed.
  ///
  /// In ko, this message translates to:
  /// **'이미 확정됨'**
  String get adminDiveStarAlreadyConfirmed;

  /// No description provided for @adminDiveStarHistorySection.
  ///
  /// In ko, this message translates to:
  /// **'심사 이력'**
  String get adminDiveStarHistorySection;

  /// No description provided for @adminDiveStarHistoryEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 저장된 심사가 없습니다.'**
  String get adminDiveStarHistoryEmpty;

  /// No description provided for @adminDiveStarHistoryLine.
  ///
  /// In ko, this message translates to:
  /// **'{date} · {score}점 · 후보 {grade}스타'**
  String adminDiveStarHistoryLine(String date, int score, int grade);

  /// No description provided for @adminDiveStarStatusConfirmed.
  ///
  /// In ko, this message translates to:
  /// **'확정'**
  String get adminDiveStarStatusConfirmed;

  /// No description provided for @adminDiveStarStatusDraft.
  ///
  /// In ko, this message translates to:
  /// **'미확정'**
  String get adminDiveStarStatusDraft;

  /// No description provided for @adminDiveStarModeNew.
  ///
  /// In ko, this message translates to:
  /// **'새 심사'**
  String get adminDiveStarModeNew;

  /// No description provided for @adminDiveStarModeEditing.
  ///
  /// In ko, this message translates to:
  /// **'수정 중 · 미확정'**
  String get adminDiveStarModeEditing;

  /// No description provided for @adminDiveStarModeReadonly.
  ///
  /// In ko, this message translates to:
  /// **'확정됨 · 읽기 전용'**
  String get adminDiveStarModeReadonly;

  /// No description provided for @adminDiveStarStartNew.
  ///
  /// In ko, this message translates to:
  /// **'새 심사 시작'**
  String get adminDiveStarStartNew;

  /// No description provided for @adminDiveStarCopyAsNew.
  ///
  /// In ko, this message translates to:
  /// **'이 기록을 복사해서 새 심사 만들기'**
  String get adminDiveStarCopyAsNew;

  /// No description provided for @adminDiveStarCopySameDateTitle.
  ///
  /// In ko, this message translates to:
  /// **'심사일 확인'**
  String get adminDiveStarCopySameDateTitle;

  /// No description provided for @adminDiveStarCopySameDateBody.
  ///
  /// In ko, this message translates to:
  /// **'재심사 날짜가 원본과 같습니다. 이대로 저장할까요?'**
  String get adminDiveStarCopySameDateBody;

  /// No description provided for @adminDiveStarDeleteDraft.
  ///
  /// In ko, this message translates to:
  /// **'미확정 심사 삭제'**
  String get adminDiveStarDeleteDraft;

  /// No description provided for @adminDiveStarDeleteConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'심사를 삭제할까요?'**
  String get adminDiveStarDeleteConfirmTitle;

  /// No description provided for @adminDiveStarDeleteConfirmBody.
  ///
  /// In ko, this message translates to:
  /// **'이 미확정 기록을 삭제합니다. 되돌릴 수 없습니다.'**
  String get adminDiveStarDeleteConfirmBody;

  /// No description provided for @adminDiveStarDeleted.
  ///
  /// In ko, this message translates to:
  /// **'심사를 삭제했습니다.'**
  String get adminDiveStarDeleted;

  /// No description provided for @adminDiveStarAssessmentUpdated.
  ///
  /// In ko, this message translates to:
  /// **'심사를 덮어써서 저장했습니다.'**
  String get adminDiveStarAssessmentUpdated;

  /// No description provided for @adminDiveStarFormImportMenu.
  ///
  /// In ko, this message translates to:
  /// **'심사 양식 가져오기'**
  String get adminDiveStarFormImportMenu;

  /// No description provided for @adminDiveStarFormImportTitle.
  ///
  /// In ko, this message translates to:
  /// **'다이브스타 양식 가져오기'**
  String get adminDiveStarFormImportTitle;

  /// No description provided for @adminDiveStarFormImportHint.
  ///
  /// In ko, this message translates to:
  /// **'양식 JSON을 붙여넣어 초안(비활성)으로 저장합니다. 준비가 되면 「사용 중으로 전환」으로 활성 양식을 바꿀 수 있습니다.'**
  String get adminDiveStarFormImportHint;

  /// No description provided for @adminDiveStarFormImportPasteLabel.
  ///
  /// In ko, this message translates to:
  /// **'양식 JSON'**
  String get adminDiveStarFormImportPasteLabel;

  /// No description provided for @adminDiveStarFormImportAction.
  ///
  /// In ko, this message translates to:
  /// **'검사 후 초안 저장'**
  String get adminDiveStarFormImportAction;

  /// No description provided for @adminDiveStarFormImportEmpty.
  ///
  /// In ko, this message translates to:
  /// **'JSON을 먼저 붙여넣어 주세요.'**
  String get adminDiveStarFormImportEmpty;

  /// No description provided for @adminDiveStarFormImportInvalidJson.
  ///
  /// In ko, this message translates to:
  /// **'JSON을 읽을 수 없습니다.'**
  String get adminDiveStarFormImportInvalidJson;

  /// No description provided for @adminDiveStarFormImportMissingVersion.
  ///
  /// In ko, this message translates to:
  /// **'version 필드가 필요합니다.'**
  String get adminDiveStarFormImportMissingVersion;

  /// No description provided for @adminDiveStarFormImportAreaSum.
  ///
  /// In ko, this message translates to:
  /// **'영역 배점 합계가 100이어야 합니다.'**
  String get adminDiveStarFormImportAreaSum;

  /// No description provided for @adminDiveStarFormImportItemSum.
  ///
  /// In ko, this message translates to:
  /// **'항목 배점 합계가 각 영역 배점과 같아야 합니다.'**
  String get adminDiveStarFormImportItemSum;

  /// No description provided for @adminDiveStarFormImportDuplicateId.
  ///
  /// In ko, this message translates to:
  /// **'중복된 ID가 있습니다(영역·게이트·항목).'**
  String get adminDiveStarFormImportDuplicateId;

  /// No description provided for @adminDiveStarFormImportInvalid.
  ///
  /// In ko, this message translates to:
  /// **'가져오기 실패: {code}'**
  String adminDiveStarFormImportInvalid(String code);

  /// No description provided for @adminDiveStarFormImportExists.
  ///
  /// In ko, this message translates to:
  /// **'같은 버전이 이미 있습니다. 덮어쓰지 않습니다.'**
  String get adminDiveStarFormImportExists;

  /// No description provided for @adminDiveStarFormImportSaved.
  ///
  /// In ko, this message translates to:
  /// **'{version}을(를) 초안(비활성)으로 저장했습니다.'**
  String adminDiveStarFormImportSaved(String version);

  /// No description provided for @adminDiveStarFormListSection.
  ///
  /// In ko, this message translates to:
  /// **'저장된 양식'**
  String get adminDiveStarFormListSection;

  /// No description provided for @adminDiveStarFormListEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 Firestore에 양식이 없습니다(심사를 열면 v1이 시드됩니다).'**
  String get adminDiveStarFormListEmpty;

  /// No description provided for @adminDiveStarFormListLoadError.
  ///
  /// In ko, this message translates to:
  /// **'양식 목록을 불러오지 못했습니다. 아래 JSON 붙여넣기는 그대로 쓸 수 있습니다. ({detail})'**
  String adminDiveStarFormListLoadError(String detail);

  /// No description provided for @adminDiveStarFormStatusActive.
  ///
  /// In ko, this message translates to:
  /// **'사용 중'**
  String get adminDiveStarFormStatusActive;

  /// No description provided for @adminDiveStarFormStatusDraft.
  ///
  /// In ko, this message translates to:
  /// **'초안'**
  String get adminDiveStarFormStatusDraft;

  /// No description provided for @adminDiveStarFormActivate.
  ///
  /// In ko, this message translates to:
  /// **'이 양식을 사용 중으로 전환'**
  String get adminDiveStarFormActivate;

  /// No description provided for @adminDiveStarFormActivateLockedHint.
  ///
  /// In ko, this message translates to:
  /// **'3단계 완료 후 사용 가능합니다. 지금은 활성 양식이 v1로 유지됩니다.'**
  String get adminDiveStarFormActivateLockedHint;

  /// No description provided for @adminDiveStarFormActivated.
  ///
  /// In ko, this message translates to:
  /// **'{version}을(를) 사용 중으로 전환했습니다.'**
  String adminDiveStarFormActivated(String version);

  /// No description provided for @adminDiveStarFormMissingForHistory.
  ///
  /// In ko, this message translates to:
  /// **'이 기록의 양식({version})을 찾지 못해 사용 중 양식으로 엽니다.'**
  String adminDiveStarFormMissingForHistory(String version);

  /// No description provided for @adminDocsTitle.
  ///
  /// In ko, this message translates to:
  /// **'문서·양식'**
  String get adminDocsTitle;

  /// No description provided for @adminTrialDataTab.
  ///
  /// In ko, this message translates to:
  /// **'시험 데이터 · 출시 전 제거'**
  String get adminTrialDataTab;

  /// No description provided for @adminTrialDataTitle.
  ///
  /// In ko, this message translates to:
  /// **'시험 데이터 점검·정리'**
  String get adminTrialDataTitle;

  /// No description provided for @adminTrialPrelaunchBanner.
  ///
  /// In ko, this message translates to:
  /// **'출시 전 삭제 예정 기능 — 운영 데이터가 아닙니다. 백업 후 사용하세요.'**
  String get adminTrialPrelaunchBanner;

  /// No description provided for @adminTrialLimitsBody.
  ///
  /// In ko, this message translates to:
  /// **'한계: Firebase Auth 로그인 계정은 앱에서 못 지웁니다(Console → Authentication → Users). users 문서만 지우면 같은 아이디로 다시 로그인할 때 빈 회원 문서가 생길 수 있으니, 시험 계정은 Firestore 삭제 후 Console에서 Auth도 지우세요. R2·Storage 사진 파일은 문서와 별개로 남을 수 있습니다. 서류함(partner_contracts)은 규칙상 앱 삭제 불가 — Console에서 수동 삭제하세요. 하위 컬렉션은 부모와 함께 자동 삭제되지 않습니다.'**
  String get adminTrialLimitsBody;

  /// No description provided for @adminTrialRefresh.
  ///
  /// In ko, this message translates to:
  /// **'건수 새로고침'**
  String get adminTrialRefresh;

  /// No description provided for @adminTrialCountsTitle.
  ///
  /// In ko, this message translates to:
  /// **'경로별 건수'**
  String get adminTrialCountsTitle;

  /// No description provided for @adminTrialUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'앱에서 확인 불가'**
  String get adminTrialUnavailable;

  /// No description provided for @adminTrialCountError.
  ///
  /// In ko, this message translates to:
  /// **'조회 실패'**
  String get adminTrialCountError;

  /// No description provided for @adminTrialFlagProtected.
  ///
  /// In ko, this message translates to:
  /// **'보호'**
  String get adminTrialFlagProtected;

  /// No description provided for @adminTrialFlagDeletable.
  ///
  /// In ko, this message translates to:
  /// **'삭제 가능'**
  String get adminTrialFlagDeletable;

  /// No description provided for @adminTrialJejuProtected.
  ///
  /// In ko, this message translates to:
  /// **'보호 샵: {name} · id={id} (상품·예약·후기·서류함·소유 회원 포함)'**
  String adminTrialJejuProtected(String name, String id);

  /// No description provided for @adminTrialJejuMissing.
  ///
  /// In ko, this message translates to:
  /// **'「제주 오렌지」 샵을 찾지 못했습니다. 보호 샵 없이 시험 삭제가 가능하니 주의하세요.'**
  String get adminTrialJejuMissing;

  /// No description provided for @adminTrialJejuAmbiguous.
  ///
  /// In ko, this message translates to:
  /// **'「제주 오렌지」와 비슷한 샵이 여러 개입니다. 목록을 확인한 뒤 Console에서 정리하고 다시 열어 주세요. 삭제를 잠갔습니다.'**
  String get adminTrialJejuAmbiguous;

  /// No description provided for @adminTrialDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'선택 삭제'**
  String get adminTrialDeleteTitle;

  /// No description provided for @adminTrialDeleteHint.
  ///
  /// In ko, this message translates to:
  /// **'보호 항목은 체크할 수 없습니다. 실행 전 건수를 다시 읽고, 확인 문구를 정확히 입력하세요.'**
  String get adminTrialDeleteHint;

  /// No description provided for @adminTrialBackupCheck.
  ///
  /// In ko, this message translates to:
  /// **'백업(또는 Export)은 했습니다'**
  String get adminTrialBackupCheck;

  /// No description provided for @adminTrialConfirmLabel.
  ///
  /// In ko, this message translates to:
  /// **'확인 문구 입력'**
  String get adminTrialConfirmLabel;

  /// No description provided for @adminTrialConfirmMismatch.
  ///
  /// In ko, this message translates to:
  /// **'확인 문구가 「삭제합니다」와 같지 않습니다.'**
  String get adminTrialConfirmMismatch;

  /// No description provided for @adminTrialBackupRequired.
  ///
  /// In ko, this message translates to:
  /// **'백업 확인에 체크해 주세요.'**
  String get adminTrialBackupRequired;

  /// No description provided for @adminTrialRunDelete.
  ///
  /// In ko, this message translates to:
  /// **'선택 항목 삭제 실행'**
  String get adminTrialRunDelete;

  /// No description provided for @adminTrialResult.
  ///
  /// In ko, this message translates to:
  /// **'결과 · 성공 {ok} · 실패 {fail}'**
  String adminTrialResult(int ok, int fail);

  /// No description provided for @adminTrialSelOutbox.
  ///
  /// In ko, this message translates to:
  /// **'파트너 메일 큐'**
  String get adminTrialSelOutbox;

  /// No description provided for @adminTrialSelLoi.
  ///
  /// In ko, this message translates to:
  /// **'LOI 신청'**
  String get adminTrialSelLoi;

  /// No description provided for @adminTrialSelPosts.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 글·댓글'**
  String get adminTrialSelPosts;

  /// No description provided for @adminTrialSelReviews.
  ///
  /// In ko, this message translates to:
  /// **'후기(제주 오렌지 제외)'**
  String get adminTrialSelReviews;

  /// No description provided for @adminTrialSelUserBookings.
  ///
  /// In ko, this message translates to:
  /// **'회원 쪽 예약 복사본'**
  String get adminTrialSelUserBookings;

  /// No description provided for @adminTrialSelUserLogs.
  ///
  /// In ko, this message translates to:
  /// **'회원 로그'**
  String get adminTrialSelUserLogs;

  /// No description provided for @adminTrialSelAssessments.
  ///
  /// In ko, this message translates to:
  /// **'미확정 다이브스타 평가'**
  String get adminTrialSelAssessments;

  /// No description provided for @adminTrialSelShopBookings.
  ///
  /// In ko, this message translates to:
  /// **'시험 샵 예약'**
  String get adminTrialSelShopBookings;

  /// No description provided for @adminTrialSelProducts.
  ///
  /// In ko, this message translates to:
  /// **'시험 샵 상품 배열 비우기'**
  String get adminTrialSelProducts;

  /// No description provided for @adminTrialSelShops.
  ///
  /// In ko, this message translates to:
  /// **'시험 샵 문서 삭제(주인 해제→하위→샵)'**
  String get adminTrialSelShops;

  /// No description provided for @adminTrialSelUsers.
  ///
  /// In ko, this message translates to:
  /// **'시험 회원 문서(사장님·본인·제주오렌지 주인 제외)'**
  String get adminTrialSelUsers;

  /// No description provided for @adminDocsHint.
  ///
  /// In ko, this message translates to:
  /// **'파트너에게 보낼 공개 안내서·신청서를 보관하고 공유합니다. 내부용 파일은 여기에 넣지 마세요.'**
  String get adminDocsHint;

  /// No description provided for @adminDocsListSection.
  ///
  /// In ko, this message translates to:
  /// **'문서 목록'**
  String get adminDocsListSection;

  /// No description provided for @adminDocsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'등록된 문서가 없습니다.'**
  String get adminDocsEmpty;

  /// No description provided for @adminDocsShareHistory.
  ///
  /// In ko, this message translates to:
  /// **'발송 기록'**
  String get adminDocsShareHistory;

  /// No description provided for @adminDocsShareHistoryEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 발송 기록이 없습니다.'**
  String get adminDocsShareHistoryEmpty;

  /// No description provided for @adminDocFilterAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get adminDocFilterAll;

  /// No description provided for @adminDocCatCriteria.
  ///
  /// In ko, this message translates to:
  /// **'심사 기준'**
  String get adminDocCatCriteria;

  /// No description provided for @adminDocCatPartnerGuide.
  ///
  /// In ko, this message translates to:
  /// **'파트너 안내'**
  String get adminDocCatPartnerGuide;

  /// No description provided for @adminDocCatApplication.
  ///
  /// In ko, this message translates to:
  /// **'신청 양식'**
  String get adminDocCatApplication;

  /// No description provided for @adminDocCatAuditor.
  ///
  /// In ko, this message translates to:
  /// **'심사관용'**
  String get adminDocCatAuditor;

  /// No description provided for @adminDocCatTraining.
  ///
  /// In ko, this message translates to:
  /// **'교육 자료'**
  String get adminDocCatTraining;

  /// No description provided for @adminDocCatContract.
  ///
  /// In ko, this message translates to:
  /// **'계약·약관'**
  String get adminDocCatContract;

  /// No description provided for @adminDocStatusDraft.
  ///
  /// In ko, this message translates to:
  /// **'초안'**
  String get adminDocStatusDraft;

  /// No description provided for @adminDocStatusApproved.
  ///
  /// In ko, this message translates to:
  /// **'승인'**
  String get adminDocStatusApproved;

  /// No description provided for @adminDocAudiencePublic.
  ///
  /// In ko, this message translates to:
  /// **'공개'**
  String get adminDocAudiencePublic;

  /// No description provided for @adminDocAudienceInternal.
  ///
  /// In ko, this message translates to:
  /// **'내부'**
  String get adminDocAudienceInternal;

  /// No description provided for @adminDocActionPrint.
  ///
  /// In ko, this message translates to:
  /// **'인쇄'**
  String get adminDocActionPrint;

  /// No description provided for @adminDocActionDownload.
  ///
  /// In ko, this message translates to:
  /// **'다운로드'**
  String get adminDocActionDownload;

  /// No description provided for @adminDocActionShare.
  ///
  /// In ko, this message translates to:
  /// **'공유'**
  String get adminDocActionShare;

  /// No description provided for @adminDocActionEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get adminDocActionEmail;

  /// No description provided for @adminDocActionCopyLink.
  ///
  /// In ko, this message translates to:
  /// **'링크 복사'**
  String get adminDocActionCopyLink;

  /// No description provided for @adminDocActionQr.
  ///
  /// In ko, this message translates to:
  /// **'QR 코드'**
  String get adminDocActionQr;

  /// No description provided for @adminDocActionFaxPrint.
  ///
  /// In ko, this message translates to:
  /// **'팩스용 출력'**
  String get adminDocActionFaxPrint;

  /// No description provided for @adminDocSendToPartner.
  ///
  /// In ko, this message translates to:
  /// **'파트너에게 보내기'**
  String get adminDocSendToPartner;

  /// No description provided for @adminDocPickPartner.
  ///
  /// In ko, this message translates to:
  /// **'파트너(샵) 선택'**
  String get adminDocPickPartner;

  /// No description provided for @adminDocRecommendedChannels.
  ///
  /// In ko, this message translates to:
  /// **'추천 채널: {channels}'**
  String adminDocRecommendedChannels(String channels);

  /// No description provided for @adminDocDraftWarnTitle.
  ///
  /// In ko, this message translates to:
  /// **'초안 문서입니다'**
  String get adminDocDraftWarnTitle;

  /// No description provided for @adminDocDraftWarnBody.
  ///
  /// In ko, this message translates to:
  /// **'초안입니다. 확정본을 쓰세요. 그래도 보낼까요?'**
  String get adminDocDraftWarnBody;

  /// No description provided for @adminDocDraftWarnContinue.
  ///
  /// In ko, this message translates to:
  /// **'그래도 보내기'**
  String get adminDocDraftWarnContinue;

  /// No description provided for @adminDocShareRecorded.
  ///
  /// In ko, this message translates to:
  /// **'발송 기록을 남겼습니다.'**
  String get adminDocShareRecorded;

  /// No description provided for @adminDocShareFallbackCopy.
  ///
  /// In ko, this message translates to:
  /// **'이 환경에서는 공유 대신 문구·링크를 복사했습니다.'**
  String get adminDocShareFallbackCopy;

  /// No description provided for @adminDocEmailAttachHint.
  ///
  /// In ko, this message translates to:
  /// **'(첨부가 필요하면 공유 버튼으로 PDF를 보내 주세요.)'**
  String get adminDocEmailAttachHint;

  /// No description provided for @adminDocLinkCopied.
  ///
  /// In ko, this message translates to:
  /// **'링크를 복사했습니다.'**
  String get adminDocLinkCopied;

  /// No description provided for @adminDocQrTitle.
  ///
  /// In ko, this message translates to:
  /// **'QR 코드'**
  String get adminDocQrTitle;

  /// No description provided for @adminDocPdfMissing.
  ///
  /// In ko, this message translates to:
  /// **'PDF 파일이 아직 없습니다.'**
  String get adminDocPdfMissing;

  /// No description provided for @adminDocPdfMissingDetail.
  ///
  /// In ko, this message translates to:
  /// **'미리보기를 보려면 프로젝트에 {path} 파일을 넣어 주세요.'**
  String adminDocPdfMissingDetail(String path);

  /// No description provided for @adminDocFaxToBlank.
  ///
  /// In ko, this message translates to:
  /// **'(받는 곳 미지정)'**
  String get adminDocFaxToBlank;

  /// No description provided for @adminDocMarkApproved.
  ///
  /// In ko, this message translates to:
  /// **'승인으로 바꾸기'**
  String get adminDocMarkApproved;

  /// No description provided for @adminDocMarkDraft.
  ///
  /// In ko, this message translates to:
  /// **'초안으로 되돌리기'**
  String get adminDocMarkDraft;

  /// No description provided for @adminDocConfigTitle.
  ///
  /// In ko, this message translates to:
  /// **'채널·문구 설정'**
  String get adminDocConfigTitle;

  /// No description provided for @adminDocConfigChannelsHint.
  ///
  /// In ko, this message translates to:
  /// **'국가별 추천 채널을 쉼표로 적어 주세요. (예: kakao, email, share)'**
  String get adminDocConfigChannelsHint;

  /// No description provided for @adminDocConfigChannelsKr.
  ///
  /// In ko, this message translates to:
  /// **'한국 (KR)'**
  String get adminDocConfigChannelsKr;

  /// No description provided for @adminDocConfigChannelsJp.
  ///
  /// In ko, this message translates to:
  /// **'일본 (JP)'**
  String get adminDocConfigChannelsJp;

  /// No description provided for @adminDocConfigChannelsTh.
  ///
  /// In ko, this message translates to:
  /// **'태국 (TH)'**
  String get adminDocConfigChannelsTh;

  /// No description provided for @adminDocConfigChannelsId.
  ///
  /// In ko, this message translates to:
  /// **'인도네시아 (ID)'**
  String get adminDocConfigChannelsId;

  /// No description provided for @adminDocConfigChannelsDefault.
  ///
  /// In ko, this message translates to:
  /// **'그 외 (DEFAULT)'**
  String get adminDocConfigChannelsDefault;

  /// No description provided for @adminDocConfigTemplatesHint.
  ///
  /// In ko, this message translates to:
  /// **'발송 문구 템플릿. 자리표시자: 파트너명, 링크 (영문 partner_name, link)'**
  String get adminDocConfigTemplatesHint;

  /// No description provided for @adminDocConfigKoSubject.
  ///
  /// In ko, this message translates to:
  /// **'한국어 제목'**
  String get adminDocConfigKoSubject;

  /// No description provided for @adminDocConfigKoBody.
  ///
  /// In ko, this message translates to:
  /// **'한국어 본문'**
  String get adminDocConfigKoBody;

  /// No description provided for @adminDocConfigEnSubject.
  ///
  /// In ko, this message translates to:
  /// **'English subject'**
  String get adminDocConfigEnSubject;

  /// No description provided for @adminDocConfigEnBody.
  ///
  /// In ko, this message translates to:
  /// **'English body'**
  String get adminDocConfigEnBody;

  /// No description provided for @adminDocConfigPlaceholders.
  ///
  /// In ko, this message translates to:
  /// **'자리표시자 예: 중괄호+파트너명, 중괄호+링크, partner_name, link'**
  String get adminDocConfigPlaceholders;

  /// No description provided for @adminDocConfigSaved.
  ///
  /// In ko, this message translates to:
  /// **'채널·문구 설정을 저장했습니다.'**
  String get adminDocConfigSaved;

  /// No description provided for @partnerDocsSection.
  ///
  /// In ko, this message translates to:
  /// **'다이브스타 자료'**
  String get partnerDocsSection;

  /// No description provided for @partnerDocsTitle.
  ///
  /// In ko, this message translates to:
  /// **'안내·신청 문서'**
  String get partnerDocsTitle;

  /// No description provided for @partnerDocsHint.
  ///
  /// In ko, this message translates to:
  /// **'승인된 공개 안내서와 신청서를 확인하고 출력할 수 있습니다.'**
  String get partnerDocsHint;

  /// No description provided for @partnerDocsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 열 수 있는 승인 문서가 없습니다. 관리자 승인을 기다려 주세요.'**
  String get partnerDocsEmpty;

  /// No description provided for @partnerLoiTitle.
  ///
  /// In ko, this message translates to:
  /// **'참여 의향서'**
  String get partnerLoiTitle;

  /// No description provided for @partnerLoiHint.
  ///
  /// In ko, this message translates to:
  /// **'샵 정보를 입력하고 손가락으로 서명한 뒤 제출하세요. PDF가 만들어지고 다이브트래블에 접수됩니다.'**
  String get partnerLoiHint;

  /// No description provided for @partnerLoiCompany.
  ///
  /// In ko, this message translates to:
  /// **'회사·샵 이름'**
  String get partnerLoiCompany;

  /// No description provided for @partnerLoiContact.
  ///
  /// In ko, this message translates to:
  /// **'담당자 이름'**
  String get partnerLoiContact;

  /// No description provided for @partnerLoiEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get partnerLoiEmail;

  /// No description provided for @partnerLoiPhone.
  ///
  /// In ko, this message translates to:
  /// **'전화'**
  String get partnerLoiPhone;

  /// No description provided for @partnerLoiCountry.
  ///
  /// In ko, this message translates to:
  /// **'국가'**
  String get partnerLoiCountry;

  /// No description provided for @partnerLoiNotes.
  ///
  /// In ko, this message translates to:
  /// **'메모 (선택)'**
  String get partnerLoiNotes;

  /// No description provided for @partnerLoiSignature.
  ///
  /// In ko, this message translates to:
  /// **'서명 (아래에 그려 주세요)'**
  String get partnerLoiSignature;

  /// No description provided for @partnerLoiClearSignature.
  ///
  /// In ko, this message translates to:
  /// **'서명 지우기'**
  String get partnerLoiClearSignature;

  /// No description provided for @partnerLoiSubmit.
  ///
  /// In ko, this message translates to:
  /// **'의향서 제출'**
  String get partnerLoiSubmit;

  /// No description provided for @partnerLoiMissingFields.
  ///
  /// In ko, this message translates to:
  /// **'회사명, 담당자, 서명을 입력해 주세요.'**
  String get partnerLoiMissingFields;

  /// No description provided for @partnerLoiSubmitted.
  ///
  /// In ko, this message translates to:
  /// **'의향서를 접수했습니다.'**
  String get partnerLoiSubmitted;

  /// No description provided for @partnerLoiOpenForm.
  ///
  /// In ko, this message translates to:
  /// **'의향서 작성'**
  String get partnerLoiOpenForm;

  /// No description provided for @partnerLoiOpenFormHint.
  ///
  /// In ko, this message translates to:
  /// **'앱에서 작성·터치 서명·PDF 생성'**
  String get partnerLoiOpenFormHint;

  /// No description provided for @partnerLoiStatusSection.
  ///
  /// In ko, this message translates to:
  /// **'내 신청 현황'**
  String get partnerLoiStatusSection;

  /// No description provided for @partnerLoiStatusEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 제출한 의향서가 없습니다.'**
  String get partnerLoiStatusEmpty;

  /// No description provided for @pipelineGuideSent.
  ///
  /// In ko, this message translates to:
  /// **'안내 발송'**
  String get pipelineGuideSent;

  /// No description provided for @pipelineLoiReceived.
  ///
  /// In ko, this message translates to:
  /// **'의향서 접수'**
  String get pipelineLoiReceived;

  /// No description provided for @pipelineDocsSubmitted.
  ///
  /// In ko, this message translates to:
  /// **'서류 제출'**
  String get pipelineDocsSubmitted;

  /// No description provided for @pipelineUnderReview.
  ///
  /// In ko, this message translates to:
  /// **'심사 중'**
  String get pipelineUnderReview;

  /// No description provided for @pipelineResultNotified.
  ///
  /// In ko, this message translates to:
  /// **'결과 통보'**
  String get pipelineResultNotified;

  /// No description provided for @pipelineReminderSubject.
  ///
  /// In ko, this message translates to:
  /// **'다이브스타 안내: {shopName}'**
  String pipelineReminderSubject(String shopName);

  /// No description provided for @pipelineReminderBody.
  ///
  /// In ko, this message translates to:
  /// **'{contactName} 님 안녕하세요.\n\n{shopName} 다이브스타 신청 관련 안내입니다. 남은 서류나 문의가 있으면 회신해 주세요.\n\n감사합니다.\n다이브트래블'**
  String pipelineReminderBody(String shopName, String contactName);

  /// No description provided for @pipelineReminderQueued.
  ///
  /// In ko, this message translates to:
  /// **'이메일 앱을 열고 발송 큐에 기록했습니다.'**
  String get pipelineReminderQueued;

  /// No description provided for @adminAppsTitle.
  ///
  /// In ko, this message translates to:
  /// **'다이브스타 신청'**
  String get adminAppsTitle;

  /// No description provided for @adminAppsHint.
  ///
  /// In ko, this message translates to:
  /// **'의향서 접수와 파트너 진행 상태를 관리합니다. 이메일은 큐에 쌓이며, Cloud Functions 연동 전까지는 mailto로 보냅니다.'**
  String get adminAppsHint;

  /// No description provided for @adminAppsReminderSection.
  ///
  /// In ko, this message translates to:
  /// **'리마인더 대상'**
  String get adminAppsReminderSection;

  /// No description provided for @adminAppsEmailServerNote.
  ///
  /// In ko, this message translates to:
  /// **'서버 메일 발송은 아직 없습니다. 리마인더는 메일 앱을 열고 큐에 기록합니다.'**
  String get adminAppsEmailServerNote;

  /// No description provided for @adminAppsReminderEmpty.
  ///
  /// In ko, this message translates to:
  /// **'기한이 된 리마인더가 없습니다.'**
  String get adminAppsReminderEmpty;

  /// No description provided for @adminAppsListSection.
  ///
  /// In ko, this message translates to:
  /// **'신청 목록'**
  String get adminAppsListSection;

  /// No description provided for @adminAppsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'접수된 신청이 없습니다.'**
  String get adminAppsEmpty;

  /// No description provided for @adminAppsSendReminder.
  ///
  /// In ko, this message translates to:
  /// **'리마인더 보내기'**
  String get adminAppsSendReminder;

  /// No description provided for @adminAppsAdvanceTo.
  ///
  /// In ko, this message translates to:
  /// **'{status}(으)로 진행'**
  String adminAppsAdvanceTo(String status);

  /// No description provided for @adminAppsOutboxSection.
  ///
  /// In ko, this message translates to:
  /// **'이메일 발송 큐'**
  String get adminAppsOutboxSection;

  /// No description provided for @adminAppsOutboxEmpty.
  ///
  /// In ko, this message translates to:
  /// **'발송 큐가 비어 있습니다.'**
  String get adminAppsOutboxEmpty;

  /// No description provided for @adminAppsOpenList.
  ///
  /// In ko, this message translates to:
  /// **'신청·진행 상태'**
  String get adminAppsOpenList;

  /// No description provided for @adminAppsReminderDue.
  ///
  /// In ko, this message translates to:
  /// **'기한 {date}'**
  String adminAppsReminderDue(String date);

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

  /// No description provided for @adminPriceRevisionChip.
  ///
  /// In ko, this message translates to:
  /// **'가격 변경 요청'**
  String get adminPriceRevisionChip;

  /// No description provided for @adminPriceRevisionPendingOptions.
  ///
  /// In ko, this message translates to:
  /// **'승인 대기 신규 옵션: {names}'**
  String adminPriceRevisionPendingOptions(String names);

  /// No description provided for @adminPriceRevisionApproved.
  ///
  /// In ko, this message translates to:
  /// **'가격 변경이 승인되어 반영되었어요.'**
  String get adminPriceRevisionApproved;

  /// No description provided for @adminPriceRevisionRejected.
  ///
  /// In ko, this message translates to:
  /// **'가격 변경 요청이 반려되었어요.'**
  String get adminPriceRevisionRejected;

  /// No description provided for @adminProductApproveNeedsPrice.
  ///
  /// In ko, this message translates to:
  /// **'가격을 입력한 상품만 승인할 수 있어요'**
  String get adminProductApproveNeedsPrice;

  /// No description provided for @adminProductApproveOverCap.
  ///
  /// In ko, this message translates to:
  /// **'1억 원을 넘는 가격이 있어 승인할 수 없어요'**
  String get adminProductApproveOverCap;

  /// No description provided for @adminProductRejectNeedsNote.
  ///
  /// In ko, this message translates to:
  /// **'반려 사유를 입력해 주세요'**
  String get adminProductRejectNeedsNote;

  /// No description provided for @adminProductRejected.
  ///
  /// In ko, this message translates to:
  /// **'상품 등록이 반려되었습니다.'**
  String get adminProductRejected;

  /// No description provided for @partnerRejectReasonBanner.
  ///
  /// In ko, this message translates to:
  /// **'관리자 반려 사유'**
  String get partnerRejectReasonBanner;

  /// No description provided for @partnerRejectReasonExpand.
  ///
  /// In ko, this message translates to:
  /// **'더 보기'**
  String get partnerRejectReasonExpand;

  /// No description provided for @partnerRejectReasonCollapse.
  ///
  /// In ko, this message translates to:
  /// **'접기'**
  String get partnerRejectReasonCollapse;

  /// No description provided for @partnerResubmitNoteTitle.
  ///
  /// In ko, this message translates to:
  /// **'무엇을 고쳤나요?'**
  String get partnerResubmitNoteTitle;

  /// No description provided for @partnerResubmitNoteHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 대표 사진을 바꾸고 가격을 수정했습니다.'**
  String get partnerResubmitNoteHint;

  /// No description provided for @partnerResubmitNoteHelper.
  ///
  /// In ko, this message translates to:
  /// **'5자 이상 200자 이하'**
  String get partnerResubmitNoteHelper;

  /// No description provided for @partnerResubmitCount.
  ///
  /// In ko, this message translates to:
  /// **'재요청 {count}회차'**
  String partnerResubmitCount(int count);

  /// No description provided for @partnerResubmitUnchanged.
  ///
  /// In ko, this message translates to:
  /// **'반려 후 달라진 내용이 없어요. 반려 사유를 확인하고 고친 뒤 다시 요청해 주세요.'**
  String get partnerResubmitUnchanged;

  /// No description provided for @partnerResubmitSoftWarnTitle.
  ///
  /// In ko, this message translates to:
  /// **'관련 항목이 그대로예요'**
  String get partnerResubmitSoftWarnTitle;

  /// No description provided for @partnerResubmitSoftWarnBody.
  ///
  /// In ko, this message translates to:
  /// **'반려 사유와 관련된 {sections} 항목이 아직 바뀌지 않았어요. 그래도 요청할까요?'**
  String partnerResubmitSoftWarnBody(String sections);

  /// No description provided for @partnerResubmitSoftWarnFix.
  ///
  /// In ko, this message translates to:
  /// **'고치러 가기'**
  String get partnerResubmitSoftWarnFix;

  /// No description provided for @partnerResubmitSoftWarnContinue.
  ///
  /// In ko, this message translates to:
  /// **'그래도 요청'**
  String get partnerResubmitSoftWarnContinue;

  /// No description provided for @adminProductRejectTagsHint.
  ///
  /// In ko, this message translates to:
  /// **'해당되는 항목을 고르세요 (선택)'**
  String get adminProductRejectTagsHint;

  /// No description provided for @rejectTagPhotos.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get rejectTagPhotos;

  /// No description provided for @rejectTagPrice.
  ///
  /// In ko, this message translates to:
  /// **'가격'**
  String get rejectTagPrice;

  /// No description provided for @rejectTagOptions.
  ///
  /// In ko, this message translates to:
  /// **'옵션'**
  String get rejectTagOptions;

  /// No description provided for @rejectTagCopy.
  ///
  /// In ko, this message translates to:
  /// **'이름·소개'**
  String get rejectTagCopy;

  /// No description provided for @rejectTagSchedule.
  ///
  /// In ko, this message translates to:
  /// **'일정·집결·포함'**
  String get rejectTagSchedule;

  /// No description provided for @rejectTagCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소 규정'**
  String get rejectTagCancel;

  /// No description provided for @rejectTagOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get rejectTagOther;

  /// No description provided for @adminPendingPreviousReject.
  ///
  /// In ko, this message translates to:
  /// **'직전 반려'**
  String get adminPendingPreviousReject;

  /// No description provided for @adminPendingPartnerNote.
  ///
  /// In ko, this message translates to:
  /// **'파트너 메모'**
  String get adminPendingPartnerNote;

  /// No description provided for @adminPendingChangesTitle.
  ///
  /// In ko, this message translates to:
  /// **'이번 변경'**
  String get adminPendingChangesTitle;

  /// No description provided for @adminPendingChangeUnknown.
  ///
  /// In ko, this message translates to:
  /// **'비교 불가'**
  String get adminPendingChangeUnknown;

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

  /// No description provided for @productFormOptionGroup.
  ///
  /// In ko, this message translates to:
  /// **'그룹'**
  String get productFormOptionGroup;

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

  /// No description provided for @partnerProductBadgePending.
  ///
  /// In ko, this message translates to:
  /// **'승인 대기'**
  String get partnerProductBadgePending;

  /// No description provided for @partnerProductBadgeDrafting.
  ///
  /// In ko, this message translates to:
  /// **'작성 중'**
  String get partnerProductBadgeDrafting;

  /// No description provided for @partnerProductBadgeListed.
  ///
  /// In ko, this message translates to:
  /// **'게시중'**
  String get partnerProductBadgeListed;

  /// No description provided for @partnerProductBadgeRejected.
  ///
  /// In ko, this message translates to:
  /// **'반려'**
  String get partnerProductBadgeRejected;

  /// No description provided for @partnerProductBadgeClosed.
  ///
  /// In ko, this message translates to:
  /// **'닫힘'**
  String get partnerProductBadgeClosed;

  /// No description provided for @partnerProductBadgeMissingPrice.
  ///
  /// In ko, this message translates to:
  /// **'가격 미입력'**
  String get partnerProductBadgeMissingPrice;

  /// No description provided for @partnerProductPublish.
  ///
  /// In ko, this message translates to:
  /// **'게시'**
  String get partnerProductPublish;

  /// No description provided for @partnerProductPublishCta.
  ///
  /// In ko, this message translates to:
  /// **'게시하기'**
  String get partnerProductPublishCta;

  /// No description provided for @partnerProductPublished.
  ///
  /// In ko, this message translates to:
  /// **'상품이 게시되었습니다.'**
  String get partnerProductPublished;

  /// No description provided for @partnerFormSoftGuide.
  ///
  /// In ko, this message translates to:
  /// **'필수 표시만 적으면 저장돼요. 나머지는 비워도 괜찮아요. 운영팀이 함께 채워 드려요.'**
  String get partnerFormSoftGuide;

  /// No description provided for @partnerFormSectionBasics.
  ///
  /// In ko, this message translates to:
  /// **'기본 정보'**
  String get partnerFormSectionBasics;

  /// No description provided for @partnerFormSectionPricing.
  ///
  /// In ko, this message translates to:
  /// **'가격과 옵션'**
  String get partnerFormSectionPricing;

  /// No description provided for @partnerFormSectionPublish.
  ///
  /// In ko, this message translates to:
  /// **'게시'**
  String get partnerFormSectionPublish;

  /// No description provided for @partnerFormRequiredBadge.
  ///
  /// In ko, this message translates to:
  /// **'필수'**
  String get partnerFormRequiredBadge;

  /// No description provided for @partnerFormPhotoOptionalHint.
  ///
  /// In ko, this message translates to:
  /// **'없으면 운영팀이 넣어 드려요. 최대 10장.'**
  String get partnerFormPhotoOptionalHint;

  /// No description provided for @partnerFormPhotoMain.
  ///
  /// In ko, this message translates to:
  /// **'대표'**
  String get partnerFormPhotoMain;

  /// No description provided for @partnerFormNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 보홀 3박 4일 패키지'**
  String get partnerFormNameHint;

  /// No description provided for @partnerFormBlurbHint.
  ///
  /// In ko, this message translates to:
  /// **'고객에게 보이는 한 줄 소개'**
  String get partnerFormBlurbHint;

  /// No description provided for @partnerFormProductType.
  ///
  /// In ko, this message translates to:
  /// **'상품 종류'**
  String get partnerFormProductType;

  /// No description provided for @partnerFormNights.
  ///
  /// In ko, this message translates to:
  /// **'몇 박'**
  String get partnerFormNights;

  /// No description provided for @partnerFormDays.
  ///
  /// In ko, this message translates to:
  /// **'몇 일'**
  String get partnerFormDays;

  /// No description provided for @partnerFormMeeting.
  ///
  /// In ko, this message translates to:
  /// **'집합 장소'**
  String get partnerFormMeeting;

  /// No description provided for @partnerFormShopInfoRow.
  ///
  /// In ko, this message translates to:
  /// **'리조트 위치·시설 정보는 샵 정보에서 관리해요.'**
  String get partnerFormShopInfoRow;

  /// No description provided for @partnerFormShopInfoCta.
  ///
  /// In ko, this message translates to:
  /// **'샵 정보'**
  String get partnerFormShopInfoCta;

  /// No description provided for @partnerFormBasePrice.
  ///
  /// In ko, this message translates to:
  /// **'1인 기준 가격'**
  String get partnerFormBasePrice;

  /// No description provided for @partnerFormBasePriceHint.
  ///
  /// In ko, this message translates to:
  /// **'다이버 1인 기본 요금이에요.'**
  String get partnerFormBasePriceHint;

  /// No description provided for @partnerFormGuestRatesToggle.
  ///
  /// In ko, this message translates to:
  /// **'비다이버·아동 가격을 따로 설정'**
  String get partnerFormGuestRatesToggle;

  /// No description provided for @partnerFormAddOption.
  ///
  /// In ko, this message translates to:
  /// **'+ 옵션 추가'**
  String get partnerFormAddOption;

  /// No description provided for @partnerFormAddIndividual.
  ///
  /// In ko, this message translates to:
  /// **'+ 개별 상품 추가'**
  String get partnerFormAddIndividual;

  /// No description provided for @partnerFormIndividualOptions.
  ///
  /// In ko, this message translates to:
  /// **'이 상품의 옵션'**
  String get partnerFormIndividualOptions;

  /// No description provided for @partnerFormPreviewBadge.
  ///
  /// In ko, this message translates to:
  /// **'게시하면 바로 공개'**
  String get partnerFormPreviewBadge;

  /// No description provided for @partnerFormSameBoatNote.
  ///
  /// In ko, this message translates to:
  /// **'같은배 빈자리는 상품 게시 후 따로 열 수 있어요. 열면 고객 화면에 바로 보여요.'**
  String get partnerFormSameBoatNote;

  /// No description provided for @partnerFormCancelPolicy.
  ///
  /// In ko, this message translates to:
  /// **'취소·환불 규정'**
  String get partnerFormCancelPolicy;

  /// No description provided for @partnerPriceSwingTitle.
  ///
  /// In ko, this message translates to:
  /// **'가격이 크게 바뀌었어요'**
  String get partnerPriceSwingTitle;

  /// No description provided for @partnerPriceSwingBody.
  ///
  /// In ko, this message translates to:
  /// **'기본가·옵션·비다이버·아동·전문가 가격 중 ±30% 이상 변경된 항목이 있습니다. 그대로 반영할까요?'**
  String get partnerPriceSwingBody;

  /// No description provided for @partnerPriceSwingConfirm.
  ///
  /// In ko, this message translates to:
  /// **'반영하기'**
  String get partnerPriceSwingConfirm;

  /// No description provided for @partnerProductsTitle.
  ///
  /// In ko, this message translates to:
  /// **'상품 관리'**
  String get partnerProductsTitle;

  /// No description provided for @partnerProductMenuTitle.
  ///
  /// In ko, this message translates to:
  /// **'상품 관리'**
  String get partnerProductMenuTitle;

  /// No description provided for @partnerProductListTitle.
  ///
  /// In ko, this message translates to:
  /// **'상품 목록'**
  String get partnerProductListTitle;

  /// No description provided for @partnerProductMenuRegister.
  ///
  /// In ko, this message translates to:
  /// **'상품 등록'**
  String get partnerProductMenuRegister;

  /// No description provided for @partnerProductMenuRegisterSub.
  ///
  /// In ko, this message translates to:
  /// **'새 상품을 올려요'**
  String get partnerProductMenuRegisterSub;

  /// No description provided for @partnerProductMenuRegisterDrafting.
  ///
  /// In ko, this message translates to:
  /// **'새 상품을 올려요 · 작성 중 {count}개'**
  String partnerProductMenuRegisterDrafting(int count);

  /// No description provided for @partnerProductMenuList.
  ///
  /// In ko, this message translates to:
  /// **'상품 목록'**
  String get partnerProductMenuList;

  /// No description provided for @partnerProductMenuListSub.
  ///
  /// In ko, this message translates to:
  /// **'고치거나 닫을 수 있어요'**
  String get partnerProductMenuListSub;

  /// No description provided for @partnerProductMenuListListed.
  ///
  /// In ko, this message translates to:
  /// **'게시중 {count}개 · 고치거나 닫을 수 있어요'**
  String partnerProductMenuListListed(int count);

  /// No description provided for @partnerProductMenuSeats.
  ///
  /// In ko, this message translates to:
  /// **'빈자리 열기'**
  String get partnerProductMenuSeats;

  /// No description provided for @partnerProductMenuSeatsSub.
  ///
  /// In ko, this message translates to:
  /// **'같은배 · 기본 상품만 열 수 있어요'**
  String get partnerProductMenuSeatsSub;

  /// No description provided for @partnerProductMenuSeatsOpen.
  ///
  /// In ko, this message translates to:
  /// **'같은배 · 기본 상품만 열 수 있어요 · 열린 자리 {count}석'**
  String partnerProductMenuSeatsOpen(int count);

  /// No description provided for @partnerProductMenuFocNote.
  ///
  /// In ko, this message translates to:
  /// **'할인과 강사 FOC는 계약서 기준으로 앱이 알아서 적용해요.\n바꾸려면 운영팀과 협의해 주세요.'**
  String get partnerProductMenuFocNote;

  /// No description provided for @partnerProductBadgeBasic.
  ///
  /// In ko, this message translates to:
  /// **'기본 상품'**
  String get partnerProductBadgeBasic;

  /// No description provided for @partnerProductClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get partnerProductClose;

  /// No description provided for @partnerProductReopen.
  ///
  /// In ko, this message translates to:
  /// **'다시 열기'**
  String get partnerProductReopen;

  /// No description provided for @partnerProductDiscard.
  ///
  /// In ko, this message translates to:
  /// **'폐기'**
  String get partnerProductDiscard;

  /// No description provided for @partnerProductContinueDraft.
  ///
  /// In ko, this message translates to:
  /// **'이어서 작성'**
  String get partnerProductContinueDraft;

  /// No description provided for @partnerProductDraftHiddenHint.
  ///
  /// In ko, this message translates to:
  /// **'작성 중 상품은 고객 화면에 보이지 않아요.'**
  String get partnerProductDraftHiddenHint;

  /// No description provided for @partnerProductAddOptionIndividual.
  ///
  /// In ko, this message translates to:
  /// **'+ 옵션 · 개별 상품 추가'**
  String get partnerProductAddOptionIndividual;

  /// No description provided for @partnerProductListFooter.
  ///
  /// In ko, this message translates to:
  /// **'기본 상품 한 개 안에 개별 상품과 옵션이 모두 모여 있어요. 줄마다 바로 고치거나 폐기할 수 있어요.'**
  String get partnerProductListFooter;

  /// No description provided for @partnerProductsEmptyH2.
  ///
  /// In ko, this message translates to:
  /// **'아직 등록한 상품이 없어요. 첫 상품을 올리면 고객 화면에 바로 보여요.'**
  String get partnerProductsEmptyH2;

  /// No description provided for @partnerProductsEmptyCtaH2.
  ///
  /// In ko, this message translates to:
  /// **'첫 상품 올리기'**
  String get partnerProductsEmptyCtaH2;

  /// No description provided for @partnerProductCloseSeatTitle.
  ///
  /// In ko, this message translates to:
  /// **'상품을 닫을까요?'**
  String get partnerProductCloseSeatTitle;

  /// No description provided for @partnerProductCloseSeatBody.
  ///
  /// In ko, this message translates to:
  /// **'열린 빈자리 {count}석이 있어요. 닫으면 고객 화면에서 사라져요. 이미 들어온 예약과 진행 중인 결제는 그대로예요.'**
  String partnerProductCloseSeatBody(int count);

  /// No description provided for @partnerProductDiscardConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'이 항목을 폐기할까요?'**
  String get partnerProductDiscardConfirmTitle;

  /// No description provided for @partnerProductDiscardConfirmBody.
  ///
  /// In ko, this message translates to:
  /// **'목록에서 삭제됩니다. 예약·홀드가 있으면 삭제 대신 닫힙니다.'**
  String get partnerProductDiscardConfirmBody;

  /// No description provided for @partnerProductDiscardClosedSnack.
  ///
  /// In ko, this message translates to:
  /// **'예약·홀드가 있어 삭제 대신 닫았습니다.'**
  String get partnerProductDiscardClosedSnack;

  /// No description provided for @partnerProductOptionClosedLabel.
  ///
  /// In ko, this message translates to:
  /// **'닫힘'**
  String get partnerProductOptionClosedLabel;

  /// No description provided for @partnerOpenSeatsTitle.
  ///
  /// In ko, this message translates to:
  /// **'빈자리 열기'**
  String get partnerOpenSeatsTitle;

  /// No description provided for @partnerOpenSeatsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'게시 중인 기본 상품이 없어요. 먼저 상품을 게시해 주세요.'**
  String get partnerOpenSeatsEmpty;

  /// No description provided for @partnerOpenSeatsPickHint.
  ///
  /// In ko, this message translates to:
  /// **'같은배에 열 기본 상품을 고르세요.'**
  String get partnerOpenSeatsPickHint;

  /// No description provided for @partnerSeatsOpenHint.
  ///
  /// In ko, this message translates to:
  /// **'출발일·좌석 수·깃발 마감을 넣고 열면 고객 같은배 화면에 바로 보여요.'**
  String get partnerSeatsOpenHint;

  /// No description provided for @partnerSeatsOpenButton.
  ///
  /// In ko, this message translates to:
  /// **'빈자리 열기'**
  String get partnerSeatsOpenButton;

  /// No description provided for @partnerSeatsOpenedSnack.
  ///
  /// In ko, this message translates to:
  /// **'열렸어요. 고객 같은배 화면에 바로 보여요.'**
  String get partnerSeatsOpenedSnack;

  /// No description provided for @partnerExit.
  ///
  /// In ko, this message translates to:
  /// **'나가기'**
  String get partnerExit;

  /// No description provided for @partnerProductsGuide.
  ///
  /// In ko, this message translates to:
  /// **'저장하면 바로 탐색·같은배에 반영됩니다. 작성 중 상품은 임시 저장할 수 있어요.'**
  String get partnerProductsGuide;

  /// No description provided for @partnerProductFilterAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get partnerProductFilterAll;

  /// No description provided for @partnerProductsEmptyReason.
  ///
  /// In ko, this message translates to:
  /// **'아직 등록한 상품이 없습니다.'**
  String get partnerProductsEmptyReason;

  /// No description provided for @partnerProductsEmptyNext.
  ///
  /// In ko, this message translates to:
  /// **'상품을 등록·게시하면 이 목록에 나타납니다.'**
  String get partnerProductsEmptyNext;

  /// No description provided for @partnerProductsEmptyCta.
  ///
  /// In ko, this message translates to:
  /// **'첫 상품 등록하기'**
  String get partnerProductsEmptyCta;

  /// No description provided for @partnerProductsFilterEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이 필터에 해당하는 상품이 없습니다.'**
  String get partnerProductsFilterEmpty;

  /// No description provided for @partnerProductPriceLine.
  ///
  /// In ko, this message translates to:
  /// **'기본 패키지 · 다이버 {price}원'**
  String partnerProductPriceLine(String price);

  /// No description provided for @partnerProductSameBoatPending.
  ///
  /// In ko, this message translates to:
  /// **'같은배 처리 중'**
  String get partnerProductSameBoatPending;

  /// No description provided for @partnerProductSameBoatLive.
  ///
  /// In ko, this message translates to:
  /// **'빈자리 {seats}석 열림 · 출발 {date}'**
  String partnerProductSameBoatLive(int seats, String date);

  /// No description provided for @partnerProductSameBoatRejected.
  ///
  /// In ko, this message translates to:
  /// **'같은배 반려'**
  String get partnerProductSameBoatRejected;

  /// No description provided for @partnerProductSameBoatNotOpened.
  ///
  /// In ko, this message translates to:
  /// **'아직 안 열림'**
  String get partnerProductSameBoatNotOpened;

  /// No description provided for @partnerProductSeatsManage.
  ///
  /// In ko, this message translates to:
  /// **'빈자리 관리'**
  String get partnerProductSeatsManage;

  /// No description provided for @partnerProductResubmit.
  ///
  /// In ko, this message translates to:
  /// **'고쳐서 다시 요청'**
  String get partnerProductResubmit;

  /// No description provided for @productStatusApproved.
  ///
  /// In ko, this message translates to:
  /// **'공개됨'**
  String get productStatusApproved;

  /// No description provided for @productStatusRejected.
  ///
  /// In ko, this message translates to:
  /// **'반려됨'**
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
  /// **'대기 중에도 목록에서 보고 수정할 수 있고, 같은배 신청과 여행상품 노출은 관리자 승인 후입니다.'**
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
  /// **'제휴파트너 모드'**
  String get partnerTitle;

  /// No description provided for @partnerSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'샵 정보, 투어 상품, 이번 달 예약과 정산을 한곳에서 관리합니다.'**
  String get partnerSubtitle;

  /// No description provided for @partnerAccessDenied.
  ///
  /// In ko, this message translates to:
  /// **'제휴파트너(Business) 권한이 없는 계정입니다.'**
  String get partnerAccessDenied;

  /// No description provided for @partnerHomeShopInfo.
  ///
  /// In ko, this message translates to:
  /// **'샵 정보'**
  String get partnerHomeShopInfo;

  /// No description provided for @partnerHomeMenuSameBoat.
  ///
  /// In ko, this message translates to:
  /// **'같은배 좌석'**
  String get partnerHomeMenuSameBoat;

  /// No description provided for @partnerHomeSameBoatRejectedBanner.
  ///
  /// In ko, this message translates to:
  /// **'같은배 반려 {count}건 — 재신청이 필요해요'**
  String partnerHomeSameBoatRejectedBanner(int count);

  /// No description provided for @partnerQuickProducts.
  ///
  /// In ko, this message translates to:
  /// **'상품 관리'**
  String get partnerQuickProducts;

  /// No description provided for @partnerQuickBookings.
  ///
  /// In ko, this message translates to:
  /// **'예약 바우처'**
  String get partnerQuickBookings;

  /// No description provided for @partnerVouchersTitle.
  ///
  /// In ko, this message translates to:
  /// **'예약 바우처'**
  String get partnerVouchersTitle;

  /// No description provided for @partnerVouchersGuide.
  ///
  /// In ko, this message translates to:
  /// **'예약이 들어오면 여기에 바로 나타나요. 승인하거나 확정할 필요는 없어요.'**
  String get partnerVouchersGuide;

  /// No description provided for @partnerVouchersEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이 목록에 바우처가 없어요.'**
  String get partnerVouchersEmpty;

  /// No description provided for @partnerVoucherTabArrived.
  ///
  /// In ko, this message translates to:
  /// **'도착 [{count}]'**
  String partnerVoucherTabArrived(int count);

  /// No description provided for @partnerVoucherTabPast.
  ///
  /// In ko, this message translates to:
  /// **'지난 예약'**
  String get partnerVoucherTabPast;

  /// No description provided for @partnerVoucherTabCancelled.
  ///
  /// In ko, this message translates to:
  /// **'취소 [{count}]'**
  String partnerVoucherTabCancelled(int count);

  /// No description provided for @partnerVoucherJustArrived.
  ///
  /// In ko, this message translates to:
  /// **'방금 도착'**
  String get partnerVoucherJustArrived;

  /// No description provided for @partnerVoucherStatusAwaiting.
  ///
  /// In ko, this message translates to:
  /// **'확정 대기'**
  String get partnerVoucherStatusAwaiting;

  /// No description provided for @partnerVoucherStatusConfirmed.
  ///
  /// In ko, this message translates to:
  /// **'확정됨'**
  String get partnerVoucherStatusConfirmed;

  /// No description provided for @partnerVoucherStatusCancelled.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get partnerVoucherStatusCancelled;

  /// No description provided for @partnerVoucherTitleLine.
  ///
  /// In ko, this message translates to:
  /// **'바우처 {id} · {product}'**
  String partnerVoucherTitleLine(String id, String product);

  /// No description provided for @partnerVoucherTourDate.
  ///
  /// In ko, this message translates to:
  /// **'이용 날짜'**
  String get partnerVoucherTourDate;

  /// No description provided for @partnerVoucherParty.
  ///
  /// In ko, this message translates to:
  /// **'인원'**
  String get partnerVoucherParty;

  /// No description provided for @partnerVoucherPartyDetail.
  ///
  /// In ko, this message translates to:
  /// **'다이버 {divers} · 비다이버 {nondivers}'**
  String partnerVoucherPartyDetail(int divers, int nondivers);

  /// No description provided for @partnerVoucherOptions.
  ///
  /// In ko, this message translates to:
  /// **'선택 옵션'**
  String get partnerVoucherOptions;

  /// No description provided for @partnerVoucherFoc.
  ///
  /// In ko, this message translates to:
  /// **'강사 FOC'**
  String get partnerVoucherFoc;

  /// No description provided for @partnerVoucherGuestName.
  ///
  /// In ko, this message translates to:
  /// **'예약자'**
  String get partnerVoucherGuestName;

  /// No description provided for @partnerVoucherGuestNameMissing.
  ///
  /// In ko, this message translates to:
  /// **'예약자 이름 없음'**
  String get partnerVoucherGuestNameMissing;

  /// No description provided for @partnerVoucherRequests.
  ///
  /// In ko, this message translates to:
  /// **'요청 사항'**
  String get partnerVoucherRequests;

  /// No description provided for @partnerVoucherNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get partnerVoucherNone;

  /// No description provided for @partnerVoucherCreatedStamp.
  ///
  /// In ko, this message translates to:
  /// **'{time} · 도착'**
  String partnerVoucherCreatedStamp(String time);

  /// No description provided for @partnerVoucherAck.
  ///
  /// In ko, this message translates to:
  /// **'확인했어요'**
  String get partnerVoucherAck;

  /// No description provided for @partnerVoucherSavePrint.
  ///
  /// In ko, this message translates to:
  /// **'바우처 저장·인쇄'**
  String get partnerVoucherSavePrint;

  /// No description provided for @partnerVoucherView.
  ///
  /// In ko, this message translates to:
  /// **'바우처 보기'**
  String get partnerVoucherView;

  /// No description provided for @partnerVoucherCopied.
  ///
  /// In ko, this message translates to:
  /// **'바우처 내용을 복사했어요. 붙여넣어 저장·인쇄할 수 있어요.'**
  String get partnerVoucherCopied;

  /// No description provided for @partnerVoucherTempConfirm.
  ///
  /// In ko, this message translates to:
  /// **'예약 확정(임시)'**
  String get partnerVoucherTempConfirm;

  /// No description provided for @partnerVoucherCancelCardBody.
  ///
  /// In ko, this message translates to:
  /// **'{product} · {date} · 고객이 취소했어요 · 다이버 {divers}명'**
  String partnerVoucherCancelCardBody(String product, String date, int divers);

  /// No description provided for @partnerVoucherCancelOpsNote.
  ///
  /// In ko, this message translates to:
  /// **'취소·환불 처리와 고객 문의는 운영팀이 맡아요.'**
  String get partnerVoucherCancelOpsNote;

  /// No description provided for @partnerVoucherSettlementTitle.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 정산'**
  String get partnerVoucherSettlementTitle;

  /// No description provided for @partnerVoucherSettlementSub.
  ///
  /// In ko, this message translates to:
  /// **'총 매출 · 수수료 · 정산 예정 금액 보기'**
  String get partnerVoucherSettlementSub;

  /// No description provided for @partnerQuickStats.
  ///
  /// In ko, this message translates to:
  /// **'통계 보기'**
  String get partnerQuickStats;

  /// No description provided for @partnerQuickDocs.
  ///
  /// In ko, this message translates to:
  /// **'제휴 계약서'**
  String get partnerQuickDocs;

  /// No description provided for @partnerQuickSettlement.
  ///
  /// In ko, this message translates to:
  /// **'매출 정산'**
  String get partnerQuickSettlement;

  /// No description provided for @partnerComingSoonBody.
  ///
  /// In ko, this message translates to:
  /// **'이 기능은 준비 중이에요. 곧 만나 보세요.'**
  String get partnerComingSoonBody;

  /// No description provided for @partnerBusinessHighlightTitle.
  ///
  /// In ko, this message translates to:
  /// **'Business Highlight (비즈니스 하이라이트)'**
  String get partnerBusinessHighlightTitle;

  /// No description provided for @partnerHighlightJourney.
  ///
  /// In ko, this message translates to:
  /// **'다이버 여정'**
  String get partnerHighlightJourney;

  /// No description provided for @partnerHighlightBookingHits.
  ///
  /// In ko, this message translates to:
  /// **'예약 Hits'**
  String get partnerHighlightBookingHits;

  /// No description provided for @partnerHighlightPromoHits.
  ///
  /// In ko, this message translates to:
  /// **'프로모션 Hits'**
  String get partnerHighlightPromoHits;

  /// No description provided for @partnerHighlightEmptyMetrics.
  ///
  /// In ko, this message translates to:
  /// **'아직 표시할 데이터가 없어요'**
  String get partnerHighlightEmptyMetrics;

  /// No description provided for @partnerHighlightMilestoneTitle.
  ///
  /// In ko, this message translates to:
  /// **'리조트 이정표 · 다이브스타 진행'**
  String get partnerHighlightMilestoneTitle;

  /// No description provided for @partnerMilestoneGeneral.
  ///
  /// In ko, this message translates to:
  /// **'일반'**
  String get partnerMilestoneGeneral;

  /// No description provided for @partnerMilestonePreReview.
  ///
  /// In ko, this message translates to:
  /// **'심사 전'**
  String get partnerMilestonePreReview;

  /// No description provided for @partnerMilestoneOneStar.
  ///
  /// In ko, this message translates to:
  /// **'원스타'**
  String get partnerMilestoneOneStar;

  /// No description provided for @partnerMilestoneTwoStar.
  ///
  /// In ko, this message translates to:
  /// **'투스타'**
  String get partnerMilestoneTwoStar;

  /// No description provided for @partnerMilestoneThreeStar.
  ///
  /// In ko, this message translates to:
  /// **'쓰리스타'**
  String get partnerMilestoneThreeStar;

  /// No description provided for @partnerHighlightReviewsTitle.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 평점'**
  String get partnerHighlightReviewsTitle;

  /// No description provided for @partnerHighlightNoReviews.
  ///
  /// In ko, this message translates to:
  /// **'아직 리뷰가 없어요'**
  String get partnerHighlightNoReviews;

  /// No description provided for @partnerHighlightReviewCount.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 {count}개'**
  String partnerHighlightReviewCount(int count);

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

  /// No description provided for @partnerStatsPeriodWeek.
  ///
  /// In ko, this message translates to:
  /// **'이번 주'**
  String get partnerStatsPeriodWeek;

  /// No description provided for @partnerStatsPeriodMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달'**
  String get partnerStatsPeriodMonth;

  /// No description provided for @partnerStatsPeriodThreeMonths.
  ///
  /// In ko, this message translates to:
  /// **'3개월'**
  String get partnerStatsPeriodThreeMonths;

  /// No description provided for @partnerStatsAnchorVisit.
  ///
  /// In ko, this message translates to:
  /// **'방문'**
  String get partnerStatsAnchorVisit;

  /// No description provided for @partnerStatsAnchorAudience.
  ///
  /// In ko, this message translates to:
  /// **'방문자'**
  String get partnerStatsAnchorAudience;

  /// No description provided for @partnerStatsAnchorDwell.
  ///
  /// In ko, this message translates to:
  /// **'체류'**
  String get partnerStatsAnchorDwell;

  /// No description provided for @partnerStatsAnchorStrike.
  ///
  /// In ko, this message translates to:
  /// **'스트라이크율'**
  String get partnerStatsAnchorStrike;

  /// No description provided for @partnerStatsAnchorResult.
  ///
  /// In ko, this message translates to:
  /// **'결과'**
  String get partnerStatsAnchorResult;

  /// No description provided for @partnerStatsCatInApp.
  ///
  /// In ko, this message translates to:
  /// **'앱 안에서 일어난 일'**
  String get partnerStatsCatInApp;

  /// No description provided for @partnerStatsCatResults.
  ///
  /// In ko, this message translates to:
  /// **'예약으로 이어진 결과'**
  String get partnerStatsCatResults;

  /// No description provided for @partnerStatsSecVisit.
  ///
  /// In ko, this message translates to:
  /// **'앱 방문'**
  String get partnerStatsSecVisit;

  /// No description provided for @partnerStatsSecAudience.
  ///
  /// In ko, this message translates to:
  /// **'누가 보고 가나요'**
  String get partnerStatsSecAudience;

  /// No description provided for @partnerStatsSecDwell.
  ///
  /// In ko, this message translates to:
  /// **'얼마나 머무나요'**
  String get partnerStatsSecDwell;

  /// No description provided for @partnerStatsSecStrike.
  ///
  /// In ko, this message translates to:
  /// **'스트라이크율'**
  String get partnerStatsSecStrike;

  /// No description provided for @partnerStatsSecJourney.
  ///
  /// In ko, this message translates to:
  /// **'다이버 여정'**
  String get partnerStatsSecJourney;

  /// No description provided for @partnerStatsSecProducts.
  ///
  /// In ko, this message translates to:
  /// **'상품별 예약'**
  String get partnerStatsSecProducts;

  /// No description provided for @partnerStatsSecPromo.
  ///
  /// In ko, this message translates to:
  /// **'프로모션 효과'**
  String get partnerStatsSecPromo;

  /// No description provided for @partnerStatsKpiAppVisits.
  ///
  /// In ko, this message translates to:
  /// **'앱 방문'**
  String get partnerStatsKpiAppVisits;

  /// No description provided for @partnerStatsKpiProductViews.
  ///
  /// In ko, this message translates to:
  /// **'내 상품을 본 사람'**
  String get partnerStatsKpiProductViews;

  /// No description provided for @partnerStatsCmpAppAvg.
  ///
  /// In ko, this message translates to:
  /// **'앱 평균'**
  String get partnerStatsCmpAppAvg;

  /// No description provided for @partnerStatsCmpPeers.
  ///
  /// In ko, this message translates to:
  /// **'동종 샵'**
  String get partnerStatsCmpPeers;

  /// No description provided for @partnerStatsFunnelDetail.
  ///
  /// In ko, this message translates to:
  /// **'상세 조회'**
  String get partnerStatsFunnelDetail;

  /// No description provided for @partnerStatsFunnelInterest.
  ///
  /// In ko, this message translates to:
  /// **'관심'**
  String get partnerStatsFunnelInterest;

  /// No description provided for @partnerStatsFunnelAttempt.
  ///
  /// In ko, this message translates to:
  /// **'예약 시도'**
  String get partnerStatsFunnelAttempt;

  /// No description provided for @partnerStatsFunnelPaid.
  ///
  /// In ko, this message translates to:
  /// **'결제 완료'**
  String get partnerStatsFunnelPaid;

  /// No description provided for @partnerStatsCollecting.
  ///
  /// In ko, this message translates to:
  /// **'데이터 모으는 중'**
  String get partnerStatsCollecting;

  /// No description provided for @partnerStatsProductsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이 기간에 집계할 예약이 없어요'**
  String get partnerStatsProductsEmpty;

  /// No description provided for @partnerStatsColProduct.
  ///
  /// In ko, this message translates to:
  /// **'상품'**
  String get partnerStatsColProduct;

  /// No description provided for @partnerStatsColBookings.
  ///
  /// In ko, this message translates to:
  /// **'예약'**
  String get partnerStatsColBookings;

  /// No description provided for @partnerStatsColGuests.
  ///
  /// In ko, this message translates to:
  /// **'인원'**
  String get partnerStatsColGuests;

  /// No description provided for @partnerStatsColChange.
  ///
  /// In ko, this message translates to:
  /// **'전기간 대비'**
  String get partnerStatsColChange;

  /// No description provided for @partnerStatsPrivacyNote.
  ///
  /// In ko, this message translates to:
  /// **'개인을 식별할 수 없는 집계만 보여 줍니다.'**
  String get partnerStatsPrivacyNote;

  /// No description provided for @partnerSettlementSimPayNote.
  ///
  /// In ko, this message translates to:
  /// **'지금은 모의결제(SimPay) 기준 금액입니다. 실결제 연동 후 정산액이 확정됩니다.'**
  String get partnerSettlementSimPayNote;

  /// No description provided for @partnerSettlementMonthLabel.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 {month}월'**
  String partnerSettlementMonthLabel(int year, int month);

  /// No description provided for @partnerSettlementByReceiveDate.
  ///
  /// In ko, this message translates to:
  /// **'예약 접수일 기준'**
  String get partnerSettlementByReceiveDate;

  /// No description provided for @partnerSettlementValidCount.
  ///
  /// In ko, this message translates to:
  /// **'유효 예약'**
  String get partnerSettlementValidCount;

  /// No description provided for @partnerSettlementCancelledCount.
  ///
  /// In ko, this message translates to:
  /// **'취소 건수'**
  String get partnerSettlementCancelledCount;

  /// No description provided for @partnerSettlementCountValue.
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String partnerSettlementCountValue(int count);

  /// No description provided for @partnerSettlementGross.
  ///
  /// In ko, this message translates to:
  /// **'총 예약금액'**
  String get partnerSettlementGross;

  /// No description provided for @partnerSettlementRefunds.
  ///
  /// In ko, this message translates to:
  /// **'환불 금액'**
  String get partnerSettlementRefunds;

  /// No description provided for @partnerSettlementNet.
  ///
  /// In ko, this message translates to:
  /// **'순매출'**
  String get partnerSettlementNet;

  /// No description provided for @partnerSettlementFeePending.
  ///
  /// In ko, this message translates to:
  /// **'계약 조건 연동 예정'**
  String get partnerSettlementFeePending;

  /// No description provided for @partnerSettlementRateMissing.
  ///
  /// In ko, this message translates to:
  /// **'수수료율 미입력'**
  String get partnerSettlementRateMissing;

  /// No description provided for @partnerStatsDwellLine.
  ///
  /// In ko, this message translates to:
  /// **'총 {total}분 · 평균 {average}분'**
  String partnerStatsDwellLine(int total, int average);

  /// No description provided for @partnerStatsStrikeNoViews.
  ///
  /// In ko, this message translates to:
  /// **'상품 조회가 없습니다'**
  String get partnerStatsStrikeNoViews;

  /// No description provided for @partnerSettlementListTitle.
  ///
  /// In ko, this message translates to:
  /// **'예약 내역'**
  String get partnerSettlementListTitle;

  /// No description provided for @partnerSettlementEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이 달에 접수된 결제 완료 예약이 없어요'**
  String get partnerSettlementEmpty;

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
  /// **'같은배 동승하기'**
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
  /// **'새로 올라온 순입니다. 빈자리를 잡으면 예약으로 이어집니다.'**
  String get communityBoardListHint;

  /// No description provided for @communitySameBoatResults.
  ///
  /// In ko, this message translates to:
  /// **'종료된 빈자리'**
  String get communitySameBoatResults;

  /// No description provided for @communitySameBoatResultDeparted.
  ///
  /// In ko, this message translates to:
  /// **'출발 종료'**
  String get communitySameBoatResultDeparted;

  /// No description provided for @communitySameBoatResultSoldOut.
  ///
  /// In ko, this message translates to:
  /// **'매진'**
  String get communitySameBoatResultSoldOut;

  /// No description provided for @communitySameBoatResultClosed.
  ///
  /// In ko, this message translates to:
  /// **'마감'**
  String get communitySameBoatResultClosed;

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

  /// No description provided for @communityFlagButton.
  ///
  /// In ko, this message translates to:
  /// **'🚩 깃발 꽂기'**
  String get communityFlagButton;

  /// No description provided for @communityFlagPlantAndPay.
  ///
  /// In ko, this message translates to:
  /// **'🚩 깃발 꽂고 결제하러 가기'**
  String get communityFlagPlantAndPay;

  /// No description provided for @communitySeeProduct.
  ///
  /// In ko, this message translates to:
  /// **'상품 자세히 보기'**
  String get communitySeeProduct;

  /// No description provided for @communityFlagPartyTotal.
  ///
  /// In ko, this message translates to:
  /// **'합계 {amount}'**
  String communityFlagPartyTotal(String amount);

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

  /// No description provided for @exploreOpenMap.
  ///
  /// In ko, this message translates to:
  /// **'지도 열기'**
  String get exploreOpenMap;

  /// No description provided for @exploreAccessRoutes.
  ///
  /// In ko, this message translates to:
  /// **'오시는 길'**
  String get exploreAccessRoutes;

  /// No description provided for @exploreResortFeatures.
  ///
  /// In ko, this message translates to:
  /// **'리조트 특징'**
  String get exploreResortFeatures;

  /// No description provided for @exploreNearbySpots.
  ///
  /// In ko, this message translates to:
  /// **'주변 관광'**
  String get exploreNearbySpots;

  /// No description provided for @exploreOpsHours.
  ///
  /// In ko, this message translates to:
  /// **'운영 안내'**
  String get exploreOpsHours;

  /// No description provided for @exploreCheckInLabel.
  ///
  /// In ko, this message translates to:
  /// **'체크인'**
  String get exploreCheckInLabel;

  /// No description provided for @exploreCheckOutLabel.
  ///
  /// In ko, this message translates to:
  /// **'체크아웃'**
  String get exploreCheckOutLabel;

  /// No description provided for @exploreBusinessHoursLabel.
  ///
  /// In ko, this message translates to:
  /// **'영업시간'**
  String get exploreBusinessHoursLabel;

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

  /// No description provided for @sameBoatSearchWhen.
  ///
  /// In ko, this message translates to:
  /// **'언제'**
  String get sameBoatSearchWhen;

  /// No description provided for @sameBoatSearchWhere.
  ///
  /// In ko, this message translates to:
  /// **'어디'**
  String get sameBoatSearchWhere;

  /// No description provided for @sameBoatSearchParty.
  ///
  /// In ko, this message translates to:
  /// **'몇 명'**
  String get sameBoatSearchParty;

  /// No description provided for @sameBoatSearchBudget.
  ///
  /// In ko, this message translates to:
  /// **'예산'**
  String get sameBoatSearchBudget;

  /// No description provided for @sameBoatSearchMore.
  ///
  /// In ko, this message translates to:
  /// **'더 보기'**
  String get sameBoatSearchMore;

  /// No description provided for @sameBoatSearchThisMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달'**
  String get sameBoatSearchThisMonth;

  /// No description provided for @sameBoatSearchNextMonth.
  ///
  /// In ko, this message translates to:
  /// **'다음 달'**
  String get sameBoatSearchNextMonth;

  /// No description provided for @sameBoatSearchThreeMonths.
  ///
  /// In ko, this message translates to:
  /// **'3개월 이내'**
  String get sameBoatSearchThreeMonths;

  /// No description provided for @sameBoatSearchPartyCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}명'**
  String sameBoatSearchPartyCount(int count);

  /// No description provided for @sameBoatSearchPartyFivePlus.
  ///
  /// In ko, this message translates to:
  /// **'5명+'**
  String get sameBoatSearchPartyFivePlus;

  /// No description provided for @sameBoatSearchBudget50.
  ///
  /// In ko, this message translates to:
  /// **'50만 이하'**
  String get sameBoatSearchBudget50;

  /// No description provided for @sameBoatSearchBudget100.
  ///
  /// In ko, this message translates to:
  /// **'100만 이하'**
  String get sameBoatSearchBudget100;

  /// No description provided for @sameBoatSearchBudget200.
  ///
  /// In ko, this message translates to:
  /// **'200만 이하'**
  String get sameBoatSearchBudget200;

  /// No description provided for @sameBoatSearchBudgetAny.
  ///
  /// In ko, this message translates to:
  /// **'제한 없음'**
  String get sameBoatSearchBudgetAny;

  /// No description provided for @sameBoatSearchLastCall.
  ///
  /// In ko, this message translates to:
  /// **'마감 임박'**
  String get sameBoatSearchLastCall;

  /// No description provided for @sameBoatSearchDeparting.
  ///
  /// In ko, this message translates to:
  /// **'곧 출발'**
  String get sameBoatSearchDeparting;

  /// No description provided for @sameBoatSearchReset.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get sameBoatSearchReset;

  /// No description provided for @sameBoatSearchApply.
  ///
  /// In ko, this message translates to:
  /// **'빈자리 {count}개 보기'**
  String sameBoatSearchApply(int count);

  /// No description provided for @sameBoatSearchOpenCount.
  ///
  /// In ko, this message translates to:
  /// **'빈자리 {count}개'**
  String sameBoatSearchOpenCount(int count);

  /// No description provided for @sameBoatSearchSortNewest.
  ///
  /// In ko, this message translates to:
  /// **'새로 올라온 순'**
  String get sameBoatSearchSortNewest;

  /// No description provided for @sameBoatSearchAllSeats.
  ///
  /// In ko, this message translates to:
  /// **'전체 빈자리'**
  String get sameBoatSearchAllSeats;

  /// No description provided for @sameBoatEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'조건에 맞는 빈자리가 아직 없어요'**
  String get sameBoatEmptyTitle;

  /// No description provided for @sameBoatEmptySave.
  ///
  /// In ko, this message translates to:
  /// **'알림 저장'**
  String get sameBoatEmptySave;

  /// No description provided for @sameBoatEmptySaved.
  ///
  /// In ko, this message translates to:
  /// **'이미 저장됨'**
  String get sameBoatEmptySaved;

  /// No description provided for @sameBoatEmptyWiden.
  ///
  /// In ko, this message translates to:
  /// **'조건 넓히기'**
  String get sameBoatEmptyWiden;

  /// No description provided for @sameBoatEmptyWidenHint.
  ///
  /// In ko, this message translates to:
  /// **'이렇게 바꾸면 있어요'**
  String get sameBoatEmptyWidenHint;

  /// No description provided for @sameBoatUnlockLine.
  ///
  /// In ko, this message translates to:
  /// **'{name} 조건을 빼고 보여드려요'**
  String sameBoatUnlockLine(String name);

  /// No description provided for @sameBoatUnlockBudget.
  ///
  /// In ko, this message translates to:
  /// **'예산'**
  String get sameBoatUnlockBudget;

  /// No description provided for @sameBoatUnlockParty.
  ///
  /// In ko, this message translates to:
  /// **'인원'**
  String get sameBoatUnlockParty;

  /// No description provided for @sameBoatUnlockWhen.
  ///
  /// In ko, this message translates to:
  /// **'언제'**
  String get sameBoatUnlockWhen;

  /// No description provided for @sameBoatUnlockWhere.
  ///
  /// In ko, this message translates to:
  /// **'어디'**
  String get sameBoatUnlockWhere;

  /// No description provided for @sameBoatUnlockMore.
  ///
  /// In ko, this message translates to:
  /// **'더 보기'**
  String get sameBoatUnlockMore;

  /// No description provided for @mySeatAlertsTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 알림'**
  String get mySeatAlertsTitle;

  /// No description provided for @mySeatAlertsHint.
  ///
  /// In ko, this message translates to:
  /// **'저장한 조건에 맞는 빈자리가 생기면 여기와 마이 탭에 표시돼요'**
  String get mySeatAlertsHint;

  /// No description provided for @mySeatAlertsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'저장한 알림이 없어요'**
  String get mySeatAlertsEmpty;

  /// No description provided for @sameBoatAlertNone.
  ///
  /// In ko, this message translates to:
  /// **'맞는 빈자리 없음 · 자리가 나면 표시돼요'**
  String get sameBoatAlertNone;

  /// No description provided for @sameBoatAlertMatchCount.
  ///
  /// In ko, this message translates to:
  /// **'맞는 빈자리 {count}개'**
  String sameBoatAlertMatchCount(int count);

  /// No description provided for @sameBoatAlertMonth.
  ///
  /// In ko, this message translates to:
  /// **'{month}월'**
  String sameBoatAlertMonth(int month);

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

  /// No description provided for @communityFlagContinuePayAsk.
  ///
  /// In ko, this message translates to:
  /// **'이미 깃발이 있어요. 결제를 이어갈까요?'**
  String get communityFlagContinuePayAsk;

  /// No description provided for @communityFlagContinuePay.
  ///
  /// In ko, this message translates to:
  /// **'결제 이어가기'**
  String get communityFlagContinuePay;

  /// No description provided for @communityFlagTaken.
  ///
  /// In ko, this message translates to:
  /// **'방금 다른 분이 먼저 잡았어요'**
  String get communityFlagTaken;

  /// No description provided for @communityFlagTooLate.
  ///
  /// In ko, this message translates to:
  /// **'깃발 마감이 임박해 새로 꽂을 수 없습니다.'**
  String get communityFlagTooLate;

  /// No description provided for @communityFlagLimitReached.
  ///
  /// In ko, this message translates to:
  /// **'동시에 가질 수 있는 깃발은 최대 3개입니다.'**
  String get communityFlagLimitReached;

  /// No description provided for @communitySeatsShort.
  ///
  /// In ko, this message translates to:
  /// **'이 옵션의 남은 자리가 부족합니다.'**
  String get communitySeatsShort;

  /// No description provided for @profileFlagCancelCta.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get profileFlagCancelCta;

  /// No description provided for @profileFlagCancelConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 깃발을 취소하면 자리가 바로 풀립니다. 취소할까요?'**
  String get profileFlagCancelConfirm;

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
  /// **'샘플 카드예요. 제휴파트너가 빈자리를 열면 여기서 깃발을 꽂을 수 있어요'**
  String get communityDesignPreviewFlag;

  /// 비로그인 마이페이지에서 로그인을 권하는 카드 문구입니다.
  ///
  /// In ko, this message translates to:
  /// **'로그인하고 내 여행을 확인해요'**
  String get profileGuestLoginPrompt;

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
  /// **'예약'**
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

  /// No description provided for @workbenchNeedDiverPrice.
  ///
  /// In ko, this message translates to:
  /// **'다이버 가격을 0보다 큰 금액으로 입력한 뒤 저장합니다.'**
  String get workbenchNeedDiverPrice;

  /// No description provided for @workbenchPriceOverCap.
  ///
  /// In ko, this message translates to:
  /// **'가격은 1억 원 이하로 입력해 주세요.'**
  String get workbenchPriceOverCap;

  /// No description provided for @workbenchPriceOverCapNamed.
  ///
  /// In ko, this message translates to:
  /// **'옵션 \'{name}\'의 가격은 1억 원 이하로 입력해 주세요.'**
  String workbenchPriceOverCapNamed(String name);

  /// No description provided for @workbenchUnitPriceRequired.
  ///
  /// In ko, this message translates to:
  /// **'1인 기준 가격 (필수)'**
  String get workbenchUnitPriceRequired;

  /// No description provided for @workbenchCurrencyWon.
  ///
  /// In ko, this message translates to:
  /// **'원'**
  String get workbenchCurrencyWon;

  /// No description provided for @workbenchGuestPreviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'고객 구매 화면 예시'**
  String get workbenchGuestPreviewTitle;

  /// No description provided for @workbenchGuestPreviewHint.
  ///
  /// In ko, this message translates to:
  /// **'저장되지 않는 예시입니다. 실제 인원은 고객이 구매할 때 고릅니다.'**
  String get workbenchGuestPreviewHint;

  /// No description provided for @workbenchPriceRevisionPendingBanner.
  ///
  /// In ko, this message translates to:
  /// **'가격·신규 옵션 변경은 관리자 승인을 기다리는 중이에요. 그 외 수정은 이미 공개 상품에 반영되었어요.'**
  String get workbenchPriceRevisionPendingBanner;

  /// No description provided for @workbenchPriceRevisionRejectedBanner.
  ///
  /// In ko, this message translates to:
  /// **'관리자가 가격 변경을 반려했어요: {note}'**
  String workbenchPriceRevisionRejectedBanner(String note);

  /// No description provided for @workbenchPriceRevisionStaged.
  ///
  /// In ko, this message translates to:
  /// **'가격·새 옵션은 관리자 승인 뒤에 반영돼요. 나머지는 바로 반영되었어요'**
  String get workbenchPriceRevisionStaged;

  /// No description provided for @workbenchOptionClosedNotDeleted.
  ///
  /// In ko, this message translates to:
  /// **'예약·홀드가 있는 옵션이라 삭제 대신 예약 마감 처리했어요.'**
  String get workbenchOptionClosedNotDeleted;

  /// No description provided for @workbenchPhotoUploadFailed.
  ///
  /// In ko, this message translates to:
  /// **'사진 업로드에 실패했습니다. 연결·R2 설정을 확인한 뒤 다시 저장하세요. 상품은 저장되지 않았습니다.'**
  String get workbenchPhotoUploadFailed;

  /// No description provided for @workbenchPhotoLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'사진을 불러오지 못했어요'**
  String get workbenchPhotoLoadFailed;

  /// No description provided for @workbenchNeedGuestPrice.
  ///
  /// In ko, this message translates to:
  /// **'비다이버·아동 가격을 0보다 큰 금액으로 입력한 뒤 저장합니다.'**
  String get workbenchNeedGuestPrice;

  /// No description provided for @workbenchNeedOptionPrice.
  ///
  /// In ko, this message translates to:
  /// **'옵션 이름을 적었다면 가격도 0보다 크게 입력합니다.'**
  String get workbenchNeedOptionPrice;

  /// No description provided for @workbenchNeedOptionPriceNamed.
  ///
  /// In ko, this message translates to:
  /// **'옵션 \'{name}\'의 가격을 입력하세요'**
  String workbenchNeedOptionPriceNamed(String name);

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
  /// **'데이 투어'**
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
  /// **'총 인원'**
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
  /// **'빈자리를 열려면 총 인원·출발일·깃발 마감을 넣으세요.'**
  String get workbenchOpenSeatsNeedFields;

  /// No description provided for @sameBoatAlreadyBooked.
  ///
  /// In ko, this message translates to:
  /// **'이미 모집된 인원'**
  String get sameBoatAlreadyBooked;

  /// No description provided for @sameBoatSeatOpenPreview.
  ///
  /// In ko, this message translates to:
  /// **'총 {capacity}칸 중 검정 {booked} + 빈자리 {open}'**
  String sameBoatSeatOpenPreview(int capacity, int booked, int open);

  /// No description provided for @sameBoatCapacityBelowOccupied.
  ///
  /// In ko, this message translates to:
  /// **'총 인원은 확정({booked})+가확정({holds})보다 작을 수 없습니다.'**
  String sameBoatCapacityBelowOccupied(int booked, int holds);

  /// No description provided for @sameBoatAskAdminToChange.
  ///
  /// In ko, this message translates to:
  /// **'변경은 관리자에게 문의하세요.'**
  String get sameBoatAskAdminToChange;

  /// No description provided for @sameBoatPendingAfterSave.
  ///
  /// In ko, this message translates to:
  /// **'같은배 노출은 관리자 승인 후입니다. (관리자 → 샵 → 같은배 모니터)'**
  String get sameBoatPendingAfterSave;

  /// No description provided for @briefSectionSameBoat.
  ///
  /// In ko, this message translates to:
  /// **'같은배 빈자리'**
  String get briefSectionSameBoat;

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

  /// No description provided for @briefStepBasics.
  ///
  /// In ko, this message translates to:
  /// **'기본 정보'**
  String get briefStepBasics;

  /// No description provided for @briefStepPricing.
  ///
  /// In ko, this message translates to:
  /// **'가격·옵션'**
  String get briefStepPricing;

  /// No description provided for @briefStepReview.
  ///
  /// In ko, this message translates to:
  /// **'확인·제출'**
  String get briefStepReview;

  /// No description provided for @briefStepNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get briefStepNext;

  /// No description provided for @briefStepBack.
  ///
  /// In ko, this message translates to:
  /// **'이전'**
  String get briefStepBack;

  /// No description provided for @briefTempSave.
  ///
  /// In ko, this message translates to:
  /// **'임시 저장'**
  String get briefTempSave;

  /// No description provided for @briefSubmit.
  ///
  /// In ko, this message translates to:
  /// **'승인 요청'**
  String get briefSubmit;

  /// No description provided for @briefChecklistTitle.
  ///
  /// In ko, this message translates to:
  /// **'제출 전 확인'**
  String get briefChecklistTitle;

  /// No description provided for @briefChecklistHint.
  ///
  /// In ko, this message translates to:
  /// **'아래를 확인한 뒤 제출해 주세요.'**
  String get briefChecklistHint;

  /// No description provided for @briefChecklistPhotos.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get briefChecklistPhotos;

  /// No description provided for @briefChecklistCopy.
  ///
  /// In ko, this message translates to:
  /// **'이름·소개'**
  String get briefChecklistCopy;

  /// No description provided for @briefChecklistPrice.
  ///
  /// In ko, this message translates to:
  /// **'기본 가격'**
  String get briefChecklistPrice;

  /// No description provided for @briefChecklistOptions.
  ///
  /// In ko, this message translates to:
  /// **'옵션 가격'**
  String get briefChecklistOptions;

  /// No description provided for @briefChecklistIncludes.
  ///
  /// In ko, this message translates to:
  /// **'포함·불포함'**
  String get briefChecklistIncludes;

  /// No description provided for @briefChecklistCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소 규정'**
  String get briefChecklistCancel;

  /// No description provided for @briefShopInfoTitle.
  ///
  /// In ko, this message translates to:
  /// **'샵·리조트 정보'**
  String get briefShopInfoTitle;

  /// No description provided for @briefShopInfoBody.
  ///
  /// In ko, this message translates to:
  /// **'상호·위치·소개는 리조트 소개 화면에서 관리합니다.'**
  String get briefShopInfoBody;

  /// No description provided for @briefShopInfoOpen.
  ///
  /// In ko, this message translates to:
  /// **'리조트 소개 열기'**
  String get briefShopInfoOpen;

  /// No description provided for @briefSameBoatPartnerHint.
  ///
  /// In ko, this message translates to:
  /// **'같은배 빈자리는 상품을 게시한 뒤, 상품 관리에서 바로 열 수 있어요.'**
  String get briefSameBoatPartnerHint;

  /// No description provided for @briefTempSaveNeedPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진을 한 장 이상 넣어 주세요.'**
  String get briefTempSaveNeedPhoto;

  /// No description provided for @briefTempSaveNeedPrice.
  ///
  /// In ko, this message translates to:
  /// **'기본 가격을 0원보다 크게 입력해 주세요.'**
  String get briefTempSaveNeedPrice;

  /// No description provided for @briefLeaveTitle.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 않고 나갈까요?'**
  String get briefLeaveTitle;

  /// No description provided for @briefLeaveBody.
  ///
  /// In ko, this message translates to:
  /// **'수정한 내용이 아직 저장되지 않았어요.'**
  String get briefLeaveBody;

  /// No description provided for @briefLeaveTempSave.
  ///
  /// In ko, this message translates to:
  /// **'임시 저장하고 나가기'**
  String get briefLeaveTempSave;

  /// No description provided for @briefLeaveDiscard.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 않고 나가기'**
  String get briefLeaveDiscard;

  /// No description provided for @briefLeaveStay.
  ///
  /// In ko, this message translates to:
  /// **'계속 작성'**
  String get briefLeaveStay;

  /// No description provided for @briefViewModeHint.
  ///
  /// In ko, this message translates to:
  /// **'수정을 누르면 편집할 수 있습니다.'**
  String get briefViewModeHint;

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
  /// **'반려 사유'**
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

  /// No description provided for @adminOverviewBasis.
  ///
  /// In ko, this message translates to:
  /// **'접수일 기준 · 순매출 = 결제 총액 − 환불'**
  String get adminOverviewBasis;

  /// No description provided for @adminOverviewTodayBookings.
  ///
  /// In ko, this message translates to:
  /// **'오늘 예약'**
  String get adminOverviewTodayBookings;

  /// No description provided for @adminOverviewTodayPaid.
  ///
  /// In ko, this message translates to:
  /// **'오늘 결제 금액'**
  String get adminOverviewTodayPaid;

  /// No description provided for @adminOverviewTodayCancel.
  ///
  /// In ko, this message translates to:
  /// **'오늘 취소·환불'**
  String get adminOverviewTodayCancel;

  /// No description provided for @adminOverviewMonthSales.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 매출'**
  String get adminOverviewMonthSales;

  /// No description provided for @adminOverviewVsYesterday.
  ///
  /// In ko, this message translates to:
  /// **'어제보다'**
  String get adminOverviewVsYesterday;

  /// No description provided for @adminOverviewSameAsYesterday.
  ///
  /// In ko, this message translates to:
  /// **'어제와 같음'**
  String get adminOverviewSameAsYesterday;

  /// No description provided for @adminOverviewVsMonth.
  ///
  /// In ko, this message translates to:
  /// **'전월 대비'**
  String get adminOverviewVsMonth;

  /// No description provided for @adminOverviewVsYear.
  ///
  /// In ko, this message translates to:
  /// **'전년 동월 대비'**
  String get adminOverviewVsYear;

  /// No description provided for @adminOverviewNoCompare.
  ///
  /// In ko, this message translates to:
  /// **'비교 데이터 없음'**
  String get adminOverviewNoCompare;

  /// No description provided for @adminOverviewQueueTitle.
  ///
  /// In ko, this message translates to:
  /// **'처리 대기'**
  String get adminOverviewQueueTitle;

  /// No description provided for @adminOverviewQueueCertify.
  ///
  /// In ko, this message translates to:
  /// **'강사 인증'**
  String get adminOverviewQueueCertify;

  /// No description provided for @adminOverviewQueueSign.
  ///
  /// In ko, this message translates to:
  /// **'서명 대기'**
  String get adminOverviewQueueSign;

  /// No description provided for @adminOverviewQueueDiveStar.
  ///
  /// In ko, this message translates to:
  /// **'다이브스타 심사'**
  String get adminOverviewQueueDiveStar;

  /// No description provided for @adminOverviewQueueProposal.
  ///
  /// In ko, this message translates to:
  /// **'파트너 제안'**
  String get adminOverviewQueueProposal;

  /// No description provided for @adminOverviewQueueApply.
  ///
  /// In ko, this message translates to:
  /// **'승격 신청'**
  String get adminOverviewQueueApply;

  /// No description provided for @adminOverviewQueueProducts.
  ///
  /// In ko, this message translates to:
  /// **'상품 검증'**
  String get adminOverviewQueueProducts;

  /// No description provided for @adminOverviewComingSoon.
  ///
  /// In ko, this message translates to:
  /// **'준비 중'**
  String get adminOverviewComingSoon;

  /// No description provided for @adminOverviewChart14.
  ///
  /// In ko, this message translates to:
  /// **'최근 14일 매출'**
  String get adminOverviewChart14;

  /// No description provided for @adminOverviewChart30.
  ///
  /// In ko, this message translates to:
  /// **'일별 매출 · 최근 30일'**
  String get adminOverviewChart30;

  /// No description provided for @adminOverviewPriorYear.
  ///
  /// In ko, this message translates to:
  /// **'전년 동기'**
  String get adminOverviewPriorYear;

  /// No description provided for @adminOverviewLive.
  ///
  /// In ko, this message translates to:
  /// **'예약 · 결제 실시간'**
  String get adminOverviewLive;

  /// No description provided for @adminOverviewSeeAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 보기'**
  String get adminOverviewSeeAll;

  /// No description provided for @adminOverviewLiveEmpty.
  ///
  /// In ko, this message translates to:
  /// **'최근 예약이 없습니다.'**
  String get adminOverviewLiveEmpty;

  /// No description provided for @adminOverviewActivity.
  ///
  /// In ko, this message translates to:
  /// **'변동사항'**
  String get adminOverviewActivity;

  /// No description provided for @adminOverviewActivityEmpty.
  ///
  /// In ko, this message translates to:
  /// **'최근 변동이 없습니다.'**
  String get adminOverviewActivityEmpty;

  /// No description provided for @adminOverviewActivityGap.
  ///
  /// In ko, this message translates to:
  /// **'가격 변경, 좌석 변경은 준비 중입니다.'**
  String get adminOverviewActivityGap;

  /// No description provided for @adminOverviewChangeConsumer.
  ///
  /// In ko, this message translates to:
  /// **'소비자가'**
  String get adminOverviewChangeConsumer;

  /// No description provided for @adminOverviewChangePro.
  ///
  /// In ko, this message translates to:
  /// **'프로가'**
  String get adminOverviewChangePro;

  /// No description provided for @adminOverviewChangeCapacity.
  ///
  /// In ko, this message translates to:
  /// **'좌석'**
  String get adminOverviewChangeCapacity;

  /// No description provided for @adminOverviewChangeLine.
  ///
  /// In ko, this message translates to:
  /// **'{name} {label} {before}→{after}'**
  String adminOverviewChangeLine(
    String name,
    String label,
    int before,
    int after,
  );

  /// No description provided for @adminOverviewPaid.
  ///
  /// In ko, this message translates to:
  /// **'결제완료'**
  String get adminOverviewPaid;

  /// No description provided for @adminOverviewCancelled.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get adminOverviewCancelled;

  /// No description provided for @adminOverviewPartial.
  ///
  /// In ko, this message translates to:
  /// **'부분환불'**
  String get adminOverviewPartial;

  /// No description provided for @adminOverviewNoName.
  ///
  /// In ko, this message translates to:
  /// **'이름 없음'**
  String get adminOverviewNoName;

  /// No description provided for @adminOverviewJoin.
  ///
  /// In ko, this message translates to:
  /// **'가입'**
  String get adminOverviewJoin;

  /// No description provided for @adminOverviewRefund.
  ///
  /// In ko, this message translates to:
  /// **'환불'**
  String get adminOverviewRefund;

  /// No description provided for @adminOverviewSigned.
  ///
  /// In ko, this message translates to:
  /// **'서명'**
  String get adminOverviewSigned;

  /// No description provided for @adminOverviewApplied.
  ///
  /// In ko, this message translates to:
  /// **'심사 신청'**
  String get adminOverviewApplied;

  /// No description provided for @adminOverviewCancelSpike.
  ///
  /// In ko, this message translates to:
  /// **'오늘 취소가 최근 28일 하루 평균의 2배 이상입니다.'**
  String get adminOverviewCancelSpike;

  /// No description provided for @adminOverviewWeekDrop.
  ///
  /// In ko, this message translates to:
  /// **'이번 주 매출이 지난주보다 30% 이상 낮은 파트너'**
  String get adminOverviewWeekDrop;

  /// No description provided for @adminOverviewMoreThanUsual.
  ///
  /// In ko, this message translates to:
  /// **'평소보다 많음'**
  String get adminOverviewMoreThanUsual;

  /// No description provided for @adminOverviewCountUnit.
  ///
  /// In ko, this message translates to:
  /// **'건'**
  String get adminOverviewCountUnit;

  /// No description provided for @adminSalesGross.
  ///
  /// In ko, this message translates to:
  /// **'총 결제'**
  String get adminSalesGross;

  /// No description provided for @adminSalesRefund.
  ///
  /// In ko, this message translates to:
  /// **'환불'**
  String get adminSalesRefund;

  /// No description provided for @adminSalesNet.
  ///
  /// In ko, this message translates to:
  /// **'순매출'**
  String get adminSalesNet;

  /// No description provided for @adminSalesAverage.
  ///
  /// In ko, this message translates to:
  /// **'평균 결제액'**
  String get adminSalesAverage;

  /// No description provided for @adminSalesActivePartners.
  ///
  /// In ko, this message translates to:
  /// **'활성 파트너'**
  String get adminSalesActivePartners;

  /// No description provided for @adminSalesActiveHint.
  ///
  /// In ko, this message translates to:
  /// **'이 기간에 예약이 있음'**
  String get adminSalesActiveHint;

  /// No description provided for @adminSalesPresetToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get adminSalesPresetToday;

  /// No description provided for @adminSalesPresetWeek.
  ///
  /// In ko, this message translates to:
  /// **'이번 주'**
  String get adminSalesPresetWeek;

  /// No description provided for @adminSalesPresetMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달'**
  String get adminSalesPresetMonth;

  /// No description provided for @adminSalesPresetQuarter.
  ///
  /// In ko, this message translates to:
  /// **'3개월'**
  String get adminSalesPresetQuarter;

  /// No description provided for @adminSalesPresetCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접 지정'**
  String get adminSalesPresetCustom;

  /// No description provided for @adminSalesComparePrev.
  ///
  /// In ko, this message translates to:
  /// **'전월'**
  String get adminSalesComparePrev;

  /// No description provided for @adminSalesCompareYear.
  ///
  /// In ko, this message translates to:
  /// **'전년 동기'**
  String get adminSalesCompareYear;

  /// No description provided for @adminSalesPartners.
  ///
  /// In ko, this message translates to:
  /// **'파트너별 성과'**
  String get adminSalesPartners;

  /// No description provided for @adminSalesColRank.
  ///
  /// In ko, this message translates to:
  /// **'#'**
  String get adminSalesColRank;

  /// No description provided for @adminSalesColPartner.
  ///
  /// In ko, this message translates to:
  /// **'파트너'**
  String get adminSalesColPartner;

  /// No description provided for @adminSalesColBookings.
  ///
  /// In ko, this message translates to:
  /// **'예약'**
  String get adminSalesColBookings;

  /// No description provided for @adminSalesColGross.
  ///
  /// In ko, this message translates to:
  /// **'총액'**
  String get adminSalesColGross;

  /// No description provided for @adminSalesColRefund.
  ///
  /// In ko, this message translates to:
  /// **'환불'**
  String get adminSalesColRefund;

  /// No description provided for @adminSalesColNet.
  ///
  /// In ko, this message translates to:
  /// **'순매출'**
  String get adminSalesColNet;

  /// No description provided for @adminSalesColDelta.
  ///
  /// In ko, this message translates to:
  /// **'대비'**
  String get adminSalesColDelta;

  /// No description provided for @adminSalesColCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소율'**
  String get adminSalesColCancel;

  /// No description provided for @adminSalesColShare.
  ///
  /// In ko, this message translates to:
  /// **'비중'**
  String get adminSalesColShare;

  /// No description provided for @adminSalesTotalRow.
  ///
  /// In ko, this message translates to:
  /// **'합계'**
  String get adminSalesTotalRow;

  /// No description provided for @adminSalesCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별 순매출 비중'**
  String get adminSalesCategory;

  /// No description provided for @adminSalesCatTour.
  ///
  /// In ko, this message translates to:
  /// **'투어·리브어보드'**
  String get adminSalesCatTour;

  /// No description provided for @adminSalesCatCourse.
  ///
  /// In ko, this message translates to:
  /// **'교육'**
  String get adminSalesCatCourse;

  /// No description provided for @adminSalesCatFun.
  ///
  /// In ko, this message translates to:
  /// **'체험 다이빙'**
  String get adminSalesCatFun;

  /// No description provided for @adminSalesCatFlag.
  ///
  /// In ko, this message translates to:
  /// **'갈은배'**
  String get adminSalesCatFlag;

  /// No description provided for @adminSalesCatUnknown.
  ///
  /// In ko, this message translates to:
  /// **'분류 없음'**
  String get adminSalesCatUnknown;

  /// No description provided for @adminSalesTop.
  ///
  /// In ko, this message translates to:
  /// **'상품 순위 TOP 5'**
  String get adminSalesTop;

  /// No description provided for @adminSalesBasis.
  ///
  /// In ko, this message translates to:
  /// **'접수일 기준 · 순매출 = 총 결제 − 환불'**
  String get adminSalesBasis;

  /// No description provided for @adminSalesEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이 기간의 예약이 없습니다.'**
  String get adminSalesEmpty;

  /// No description provided for @adminSalesClamped.
  ///
  /// In ko, this message translates to:
  /// **'기간은 최대 12개월까지입니다.'**
  String get adminSalesClamped;

  /// No description provided for @adminSalesNew.
  ///
  /// In ko, this message translates to:
  /// **'신규'**
  String get adminSalesNew;

  /// No description provided for @adminSalesMine.
  ///
  /// In ko, this message translates to:
  /// **'내 샵'**
  String get adminSalesMine;

  /// No description provided for @adminSalesOpenContract.
  ///
  /// In ko, this message translates to:
  /// **'계약 보관함'**
  String get adminSalesOpenContract;

  /// No description provided for @adminSalesOpenDocs.
  ///
  /// In ko, this message translates to:
  /// **'서류함'**
  String get adminSalesOpenDocs;

  /// No description provided for @adminSalesOpenPartners.
  ///
  /// In ko, this message translates to:
  /// **'파트너 명단'**
  String get adminSalesOpenPartners;

  /// No description provided for @adminSalesRowHint.
  ///
  /// In ko, this message translates to:
  /// **'행을 누르면 계약 · 서류함 · 파트너 명단으로 이동합니다.'**
  String get adminSalesRowHint;

  /// No description provided for @adminStatsPresetWeek.
  ///
  /// In ko, this message translates to:
  /// **'이번 주'**
  String get adminStatsPresetWeek;

  /// No description provided for @adminStatsPresetMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달'**
  String get adminStatsPresetMonth;

  /// No description provided for @adminStatsPresetQuarter.
  ///
  /// In ko, this message translates to:
  /// **'3개월'**
  String get adminStatsPresetQuarter;

  /// No description provided for @adminStatsPresetYear.
  ///
  /// In ko, this message translates to:
  /// **'올해'**
  String get adminStatsPresetYear;

  /// No description provided for @adminStatsFlow.
  ///
  /// In ko, this message translates to:
  /// **'매출 흐름'**
  String get adminStatsFlow;

  /// No description provided for @adminStatsFlowHint.
  ///
  /// In ko, this message translates to:
  /// **'일별 · 전년 동기 비교'**
  String get adminStatsFlowHint;

  /// No description provided for @adminStatsWho.
  ///
  /// In ko, this message translates to:
  /// **'누가 사나'**
  String get adminStatsWho;

  /// No description provided for @adminStatsWhat.
  ///
  /// In ko, this message translates to:
  /// **'무엇이 팔리나'**
  String get adminStatsWhat;

  /// No description provided for @adminStatsResort.
  ///
  /// In ko, this message translates to:
  /// **'리조트 순위'**
  String get adminStatsResort;

  /// No description provided for @adminStatsOptions.
  ///
  /// In ko, this message translates to:
  /// **'옵션별 선택 비율'**
  String get adminStatsOptions;

  /// No description provided for @adminStatsOptionsHint.
  ///
  /// In ko, this message translates to:
  /// **'옵션을 그룹으로 나누면 더 자세히 볼 수 있어요'**
  String get adminStatsOptionsHint;

  /// No description provided for @adminStatsMost.
  ///
  /// In ko, this message translates to:
  /// **'가장 많이 선택한 옵션'**
  String get adminStatsMost;

  /// No description provided for @adminStatsPartner.
  ///
  /// In ko, this message translates to:
  /// **'파트너 성과'**
  String get adminStatsPartner;

  /// No description provided for @adminStatsPartnerHint.
  ///
  /// In ko, this message translates to:
  /// **'순매출 × 취소율'**
  String get adminStatsPartnerHint;

  /// No description provided for @adminStatsCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소·환불'**
  String get adminStatsCancel;

  /// No description provided for @adminStatsCancelHint.
  ///
  /// In ko, this message translates to:
  /// **'월별 취소 건수'**
  String get adminStatsCancelHint;

  /// No description provided for @adminStatsTopCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소가 많은 상품'**
  String get adminStatsTopCancel;

  /// No description provided for @adminStatsDiveStar.
  ///
  /// In ko, this message translates to:
  /// **'다이브스타'**
  String get adminStatsDiveStar;

  /// No description provided for @adminStatsDiveNote.
  ///
  /// In ko, this message translates to:
  /// **'심사 전은 최근 신청 50건 기준입니다.'**
  String get adminStatsDiveNote;

  /// No description provided for @adminStatsLead.
  ///
  /// In ko, this message translates to:
  /// **'예약 시점'**
  String get adminStatsLead;

  /// No description provided for @adminStatsLeadHint.
  ///
  /// In ko, this message translates to:
  /// **'출발 며칠 전에 예약하나'**
  String get adminStatsLeadHint;

  /// No description provided for @adminStatsLeadNote.
  ///
  /// In ko, this message translates to:
  /// **'출발일이 비어 접수일로 저장된 건은 당일에 섞일 수 있습니다.'**
  String get adminStatsLeadNote;

  /// No description provided for @adminStatsSeason.
  ///
  /// In ko, this message translates to:
  /// **'시즌'**
  String get adminStatsSeason;

  /// No description provided for @adminStatsSeasonHint.
  ///
  /// In ko, this message translates to:
  /// **'월별 예약 수'**
  String get adminStatsSeasonHint;

  /// No description provided for @adminStatsGathering.
  ///
  /// In ko, this message translates to:
  /// **'데이터 모으는 중'**
  String get adminStatsGathering;

  /// No description provided for @adminStatsCountry.
  ///
  /// In ko, this message translates to:
  /// **'국가'**
  String get adminStatsCountry;

  /// No description provided for @adminStatsCountryUnknown.
  ///
  /// In ko, this message translates to:
  /// **'미입력'**
  String get adminStatsCountryUnknown;

  /// No description provided for @adminStatsReturn.
  ///
  /// In ko, this message translates to:
  /// **'재구매'**
  String get adminStatsReturn;

  /// No description provided for @adminStatsBuyerNote.
  ///
  /// In ko, this message translates to:
  /// **'재구매는 지금 누적 구매 수로 구분합니다.'**
  String get adminStatsBuyerNote;

  /// No description provided for @adminStatsGradeUnknown.
  ///
  /// In ko, this message translates to:
  /// **'등급 없음'**
  String get adminStatsGradeUnknown;

  /// No description provided for @adminStatsBasis.
  ///
  /// In ko, this message translates to:
  /// **'접수일 기준 · 그래프 위에 마우스를 올리면 숫자가 나와요'**
  String get adminStatsBasis;

  /// No description provided for @adminStatsLead0.
  ///
  /// In ko, this message translates to:
  /// **'당일'**
  String get adminStatsLead0;

  /// No description provided for @adminStatsLead3.
  ///
  /// In ko, this message translates to:
  /// **'3일'**
  String get adminStatsLead3;

  /// No description provided for @adminStatsLead7.
  ///
  /// In ko, this message translates to:
  /// **'7일'**
  String get adminStatsLead7;

  /// No description provided for @adminStatsLead14.
  ///
  /// In ko, this message translates to:
  /// **'14일'**
  String get adminStatsLead14;

  /// No description provided for @adminStatsLead30.
  ///
  /// In ko, this message translates to:
  /// **'30일'**
  String get adminStatsLead30;

  /// No description provided for @adminStatsLead30p.
  ///
  /// In ko, this message translates to:
  /// **'30일+'**
  String get adminStatsLead30p;

  /// No description provided for @adminReportMake.
  ///
  /// In ko, this message translates to:
  /// **'보고서 만들기'**
  String get adminReportMake;

  /// No description provided for @adminReportPrint.
  ///
  /// In ko, this message translates to:
  /// **'인쇄 · PDF'**
  String get adminReportPrint;

  /// No description provided for @adminReportSettings.
  ///
  /// In ko, this message translates to:
  /// **'보고서 설정'**
  String get adminReportSettings;

  /// No description provided for @adminReportPeriod.
  ///
  /// In ko, this message translates to:
  /// **'기간'**
  String get adminReportPeriod;

  /// No description provided for @adminReportPeriodMonth.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get adminReportPeriodMonth;

  /// No description provided for @adminReportPeriodQuarter.
  ///
  /// In ko, this message translates to:
  /// **'분기'**
  String get adminReportPeriodQuarter;

  /// No description provided for @adminReportPeriodYear.
  ///
  /// In ko, this message translates to:
  /// **'연'**
  String get adminReportPeriodYear;

  /// No description provided for @adminReportPeriodCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접'**
  String get adminReportPeriodCustom;

  /// No description provided for @adminReportCompare.
  ///
  /// In ko, this message translates to:
  /// **'비교 기준'**
  String get adminReportCompare;

  /// No description provided for @adminReportCompareNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get adminReportCompareNone;

  /// No description provided for @adminReportCategories.
  ///
  /// In ko, this message translates to:
  /// **'카테고리'**
  String get adminReportCategories;

  /// No description provided for @adminReportPartners.
  ///
  /// In ko, this message translates to:
  /// **'파트너'**
  String get adminReportPartners;

  /// No description provided for @adminReportProducts.
  ///
  /// In ko, this message translates to:
  /// **'품목(상품)'**
  String get adminReportProducts;

  /// No description provided for @adminReportAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get adminReportAll;

  /// No description provided for @adminReportInclude.
  ///
  /// In ko, this message translates to:
  /// **'포함할 내용'**
  String get adminReportInclude;

  /// No description provided for @adminReportSummary.
  ///
  /// In ko, this message translates to:
  /// **'요약 숫자'**
  String get adminReportSummary;

  /// No description provided for @adminReportTrend.
  ///
  /// In ko, this message translates to:
  /// **'매출 추이'**
  String get adminReportTrend;

  /// No description provided for @adminReportPartnerTable.
  ///
  /// In ko, this message translates to:
  /// **'파트너별 표'**
  String get adminReportPartnerTable;

  /// No description provided for @adminReportProductRank.
  ///
  /// In ko, this message translates to:
  /// **'상품 순위'**
  String get adminReportProductRank;

  /// No description provided for @adminReportOptions.
  ///
  /// In ko, this message translates to:
  /// **'옵션 선택 현황'**
  String get adminReportOptions;

  /// No description provided for @adminReportCancels.
  ///
  /// In ko, this message translates to:
  /// **'취소·환불'**
  String get adminReportCancels;

  /// No description provided for @adminReportBasis.
  ///
  /// In ko, this message translates to:
  /// **'계산 기준 설명'**
  String get adminReportBasis;

  /// No description provided for @adminReportEmpty.
  ///
  /// In ko, this message translates to:
  /// **'보고서 만들기를 누르면 미리보기가 채워집니다.'**
  String get adminReportEmpty;

  /// No description provided for @adminReportHeading.
  ///
  /// In ko, this message translates to:
  /// **'경영보고서'**
  String get adminReportHeading;

  /// No description provided for @adminReportBasisBody.
  ///
  /// In ko, this message translates to:
  /// **'계산 기준: 접수일. 총 결제는 결제된 건 전체(이후 취소 포함)이고, 환불은 취소·기상취소의 환불액입니다. 순매출 = 총 결제 − 환불. 지금은 모의결제(SimPay) 기간입니다.'**
  String get adminReportBasisBody;

  /// No description provided for @adminReportFontLicense.
  ///
  /// In ko, this message translates to:
  /// **'Noto Sans KR는 SIL Open Font License(OFL)입니다.'**
  String get adminReportFontLicense;

  /// No description provided for @adminReportPrinting.
  ///
  /// In ko, this message translates to:
  /// **'PDF를 준비하고 있습니다.'**
  String get adminReportPrinting;

  /// No description provided for @partnerApplyTitle.
  ///
  /// In ko, this message translates to:
  /// **'제휴 신청'**
  String get partnerApplyTitle;

  /// No description provided for @partnerApplyShop.
  ///
  /// In ko, this message translates to:
  /// **'리조트·샵 이름'**
  String get partnerApplyShop;

  /// No description provided for @partnerApplyContact.
  ///
  /// In ko, this message translates to:
  /// **'담당자 이름'**
  String get partnerApplyContact;

  /// No description provided for @partnerApplyPhone.
  ///
  /// In ko, this message translates to:
  /// **'연락처'**
  String get partnerApplyPhone;

  /// No description provided for @partnerApplyRegion.
  ///
  /// In ko, this message translates to:
  /// **'지역'**
  String get partnerApplyRegion;

  /// No description provided for @partnerApplyIntro.
  ///
  /// In ko, this message translates to:
  /// **'한 줄 소개'**
  String get partnerApplyIntro;

  /// No description provided for @partnerApplyLink.
  ///
  /// In ko, this message translates to:
  /// **'홈페이지/SNS (선택)'**
  String get partnerApplyLink;

  /// No description provided for @partnerApplyConsent.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 수집·이용에 동의합니다'**
  String get partnerApplyConsent;

  /// No description provided for @partnerApplySend.
  ///
  /// In ko, this message translates to:
  /// **'신청 보내기'**
  String get partnerApplySend;

  /// No description provided for @partnerApplySent.
  ///
  /// In ko, this message translates to:
  /// **'신청이 접수됐어요'**
  String get partnerApplySent;

  /// No description provided for @partnerApplyCopy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get partnerApplyCopy;

  /// No description provided for @partnerApplyBadField.
  ///
  /// In ko, this message translates to:
  /// **'칸을 채워 주세요'**
  String get partnerApplyBadField;

  /// No description provided for @partnerApplyBadLink.
  ///
  /// In ko, this message translates to:
  /// **'링크는 200자 안으로 적어 주세요'**
  String get partnerApplyBadLink;

  /// No description provided for @partnerApplyNeedConsent.
  ///
  /// In ko, this message translates to:
  /// **'동의한 뒤에 보낼 수 있어요'**
  String get partnerApplyNeedConsent;

  /// No description provided for @adminApplyEmpty.
  ///
  /// In ko, this message translates to:
  /// **'도착한 신청이 없어요.'**
  String get adminApplyEmpty;

  /// No description provided for @adminApplyNew.
  ///
  /// In ko, this message translates to:
  /// **'새 신청'**
  String get adminApplyNew;

  /// No description provided for @adminApplyHandled.
  ///
  /// In ko, this message translates to:
  /// **'처리함'**
  String get adminApplyHandled;

  /// No description provided for @adminApplyMark.
  ///
  /// In ko, this message translates to:
  /// **'처리함으로 표시'**
  String get adminApplyMark;

  /// No description provided for @adminApplyOpenMember.
  ///
  /// In ko, this message translates to:
  /// **'이 회원 보기'**
  String get adminApplyOpenMember;

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
