// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dive Travel';

  @override
  String get homeWelcome => 'How wide is your ocean?';

  @override
  String get homeSubtitle => 'All seven seas in your palm.';

  @override
  String get homeProWelcome => 'Hello, PRO instructor!';

  @override
  String get homeMapTitle => 'My global ocean map';

  @override
  String homeMapExplored(int count) {
    return 'Exploring $count regions so far';
  }

  @override
  String get homeMapTip =>
      'Dive more in one region and the neon light turns gold.';

  @override
  String get homeDiveStarTitle => 'Dive Star picks';

  @override
  String get homeFavoritesTitle => 'Your favorites';

  @override
  String get homePopularTitle => 'Most booked';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeFavoritesEmpty =>
      'Tap a heart or log a dive to collect your regular resorts.';

  @override
  String get homeChipAll => 'All';

  @override
  String get homeChipRecommended => 'Picks';

  @override
  String get homeChipFavorites => 'Saved';

  @override
  String get homeChipPopular => 'Popular';

  @override
  String get homeChipLastMinute => 'Last call';

  @override
  String get homeNextDepartures => 'This departure';

  @override
  String get homeLastMinuteTitle => 'Last-call departures';

  @override
  String get homeLastMinuteCrew => 'Dahab 3-day social crew';

  @override
  String get homeLastMinuteSeat =>
      'Closes tomorrow · 1 seat left · no single supplement';

  @override
  String get homeForYouTitle => 'Your next ocean';

  @override
  String get homeStyleFirstOcean => 'A diver opening a first ocean';

  @override
  String get homeStyleFirstOceanBody =>
      'No stamps yet. Start in Asia so a log and a trip line up.';

  @override
  String get homeStyleHomeContinent => 'A diver going deep in one ocean';

  @override
  String get homeStyleHomeContinentBody =>
      'You have a home sea. Open another continent to widen the map.';

  @override
  String get homeStyleCollector => 'An explorer collecting oceans';

  @override
  String get homeStyleCollectorBody =>
      'Several continents are already stamped. Fill the empty pages.';

  @override
  String get homeStyleDeepLocal => 'A diver who returns to one site';

  @override
  String get homeStyleDeepLocalBody =>
      'A region turned gold from repeat dives. Widen the view next.';

  @override
  String get homeStylePro => 'A pro-route instructor';

  @override
  String get homeStyleProBody =>
      'Open a new continent on pro pricing and stack teaching with travel.';

  @override
  String get homeNextOceanTitle => 'Next ocean to open';

  @override
  String homeNextOceanBody(String continent) {
    return 'No logs in $continent yet. Start with this trip.';
  }

  @override
  String homeOpenShop(String name) {
    return 'See $name';
  }

  @override
  String get homeStampsLabel => 'Passport stamps';

  @override
  String homeStampsProgress(int stamped, int total) {
    return '$stamped/$total countries';
  }

  @override
  String get homeBadgeLabel => 'Next badge';

  @override
  String homeBadgeLeft(int count) {
    return '$count logs to metal card';
  }

  @override
  String get homeBadgeDone => 'Metal card ready';

  @override
  String get homeChecklistLabel => 'Departure check';

  @override
  String homeChecklistSoon(int days, String shop) {
    return '$days days · $shop';
  }

  @override
  String get homeChecklistIdle => 'Open gear list';

  @override
  String get passportCoverNation => 'Republic of the Ocean';

  @override
  String get passportCoverType => 'PASSPORT';

  @override
  String get passportOpenHint => 'Tap the cover to open your passport.';

  @override
  String get passportCloseHint => 'Tap again to close the cover.';

  @override
  String get passportVisaTitle => 'Entry stamps';

  @override
  String get passportEntryGranted => 'Entered';

  @override
  String get passportAwaiting => 'Blank';

  @override
  String passportPageIndex(int current, int total) {
    return 'Page $current / $total';
  }

  @override
  String get passportEmptyPage =>
      'This page is still blank. A log will ink the first stamp.';

  @override
  String get profilePassportHint =>
      'Tap the cover to open it. A stamp lands on each country you have logged.';

  @override
  String get navHome => 'Home';

  @override
  String get navLogbook => 'Logbook';

  @override
  String get navExplore => 'Trips';

  @override
  String get navCommunity => 'Same Tide';

  @override
  String get navProfile => 'Me';

  @override
  String get logbookTitle => 'Digital logbook';

  @override
  String get logbookAdd => 'Add log';

  @override
  String get logbookEmpty => 'No dives logged yet.';

  @override
  String get logbookChecklist => 'Gear checklist';

  @override
  String get logbookSiteLabel => 'Dive site';

  @override
  String get logbookDateLabel => 'Date and time';

  @override
  String get logbookMemoLabel => 'One-line note';

  @override
  String get logbookSelfRegisterHint =>
      'Save without an instructor signature. It registers as your travel journal.';

  @override
  String get logbookSelfRegistered => 'Travel journal · self-registered';

  @override
  String get logbookBriefEmpty => 'Site only';

  @override
  String get logbookSlipTitle => 'New log slip';

  @override
  String get logbookTankRackTitle => 'Ten tanks to the metal card';

  @override
  String get logbookTankRackHint =>
      'Each tank is 10 logs. Depth is a record, not a contest.';

  @override
  String get logbookCenturyTitle => '100 to 1,000 · next chapter';

  @override
  String get logbookCenturyHint =>
      'Divers unlock the metal card at 100. Instructors keep filling, in new colors, to 1,000.';

  @override
  String logbookCenturyLeft(int count, int target) {
    return '$count logs to $target';
  }

  @override
  String get logbookCenturyMastered => '1,000-log master';

  @override
  String get logbookJournalTitle => 'Travel journal';

  @override
  String get logbookStatDives => 'Total dives';

  @override
  String get logbookStatDiveUnit => 'dives';

  @override
  String get logbookStatTime => 'Bottom time';

  @override
  String get logbookStatRegions => 'Regions';

  @override
  String get logbookStatRegionUnit => 'spots';

  @override
  String get logbookMaxDepth => 'Max depth';

  @override
  String get logbookAvgDepth => 'Avg depth';

  @override
  String get logbookMinutes => 'Time';

  @override
  String get logbookMinUnit => 'min';

  @override
  String get logbookSac => 'SAC';

  @override
  String get logbookSacHint =>
      'SAC uses average depth, time, used bar, and tank size. Max depth fills in if average is empty.';

  @override
  String get logbookMix => 'Gas mix';

  @override
  String get logbookMixAir => '21% AIR';

  @override
  String get logbookMixNx32 => '32% NITROX';

  @override
  String get logbookMixNx36 => '36% NITROX';

  @override
  String get logbookPressure => 'Pressure';

  @override
  String get logbookStartBar => 'Start bar';

  @override
  String get logbookEndBar => 'End bar';

  @override
  String get logbookTankLiters => 'Tank (L)';

  @override
  String get logbookTemp => 'Temp';

  @override
  String get logbookAirLeft => 'Air left';

  @override
  String get logbookSave => 'Save';

  @override
  String get logbookEdit => 'Edit';

  @override
  String get logbookUpdated => 'Log updated. The map and journal refresh.';

  @override
  String get logbookSaved => 'Log saved. The map and tank gauge will update.';

  @override
  String get logbookPhotoSection => 'Test underwater photo';

  @override
  String get logbookPhotoHint =>
      'Pick from your gallery or computer, or use the built-in test photo.';

  @override
  String get logbookAttachPhoto => 'Choose from device';

  @override
  String get logbookUseTestPhoto => 'Use test photo';

  @override
  String logbookPhotoPicked(String fileName) {
    return 'Attached: $fileName';
  }

  @override
  String get logbookPhotoRemove => 'Remove photo';

  @override
  String get logbookPhotoMissingConfig =>
      'Add Cloudflare R2 keys in lib/core/config/r2_config.dart to upload photos.';

  @override
  String get logbookUploading => 'Uploading...';

  @override
  String get checklistTitle => 'Pre-trip gear checklist';

  @override
  String get exploreTitle => 'Travel products';

  @override
  String get exploreConsumerPrice => 'Guest price';

  @override
  String get exploreProPrice => 'Pro price';

  @override
  String get exploreSearchHint => 'Search resorts, sites, countries';

  @override
  String get exploreFilterAll => 'All';

  @override
  String get exploreContinentAsia => 'Asia';

  @override
  String get exploreContinentAfrica => 'Africa';

  @override
  String get exploreContinentOceania => 'Oceania';

  @override
  String get exploreContinentAmericas => 'Americas';

  @override
  String get exploreContinentEurope => 'Europe';

  @override
  String get exploreContinentPolar => 'Polar';

  @override
  String get exploreProBanner =>
      'Instructor verified · every shop shows the professional price';

  @override
  String get exploreConsumerBanner =>
      'Guest pricing · request a seat, pay after the shop confirms';

  @override
  String get exploreBook => 'Book';

  @override
  String get explorePay => 'Request a seat';

  @override
  String exploreDepartureLine(String window, int seats) {
    return '$window · $seats berths left';
  }

  @override
  String exploreDepartureBody(int empty, int capacity) {
    return '$empty of $capacity berths are still open on this departure. Flag it to board the same boat.';
  }

  @override
  String get exploreWeatherRefundTitle => 'Weather cancel = 100% refund';

  @override
  String get exploreWeatherRefundBody =>
      'If the shop cancels for weather, you get a full refund. That is a product term, not a slogan.';

  @override
  String exploreHostedBy(String shop) {
    return 'Hosted by $shop';
  }

  @override
  String get exploreListingSites => 'Dive sites in this ocean';

  @override
  String get exploreListingAmenities => 'What this trip offers';

  @override
  String get exploreListingSafetyTitle => 'Safety first, always';

  @override
  String get exploreListingSafetyBody =>
      'Depth is a record, not a boast. Guide, boat, and gear come first.';

  @override
  String get exploreRareFind => 'A rare Dive Star resort';

  @override
  String get exploreRareFindBody =>
      'Stars come from operation reviews. Popular sites go fast — pick a date.';

  @override
  String get exploreWontChargeYet =>
      'You set the date now. Payment continues after the shop confirms.';

  @override
  String get exploreListingGuests => 'Guests';

  @override
  String get exploreListingGuestOne => '1 diver';

  @override
  String get explorePerTrip => ' / trip';

  @override
  String get exploreCheckoutTitle => 'Checkout';

  @override
  String exploreCheckoutBody(String shop, String product) {
    return '$shop · $product';
  }

  @override
  String exploreCheckoutDone(String label, String price) {
    return 'Seat request sent for $label $price.';
  }

  @override
  String get exploreConsumerPayHint =>
      'This is the shop\'s listed guest price.';

  @override
  String get exploreNoResults => 'No shops match that search.';

  @override
  String exploreDiveStar(int stars) {
    return 'Dive Star $stars';
  }

  @override
  String exploreRating(String rating, int count) {
    return '$rating · $count reviews';
  }

  @override
  String explorePriceWon(String price) {
    return '$price KRW';
  }

  @override
  String exploreOriginalPrice(String price) {
    return 'Guest $price KRW';
  }

  @override
  String get exploreStarPending => 'No reviews yet';

  @override
  String get exploreListingNew => 'New';

  @override
  String get exploreListingPendingReview => 'Pending review';

  @override
  String get exploreDiveStarCertified => 'Dive Star certified';

  @override
  String get exploreViewListing => 'View resort';

  @override
  String get exploreBuyNow => 'Choose a trip';

  @override
  String exploreResortCardLine(String location, int count) {
    return '$location · $count trips';
  }

  @override
  String get exploreMyBookings => 'My bookings';

  @override
  String get reviewTitle => 'Operations review';

  @override
  String get reviewIntro =>
      'Rate safety, the guide, and the boat so Dive Star can update.';

  @override
  String get reviewShopLabel => 'Resort / dive shop';

  @override
  String get reviewSafety => '1. Safety and gear';

  @override
  String get reviewGuide => '2. Guide professionalism';

  @override
  String get reviewBoat => '3. Boat and facilities';

  @override
  String get reviewComment => 'Optional note';

  @override
  String get reviewSubmit => 'Submit review';

  @override
  String get reviewWrite => 'Write review';

  @override
  String get reviewDone => 'Reviewed';

  @override
  String get reviewSaved => 'Review saved. Dive Star will refresh.';

  @override
  String get reviewSaveFailed => 'Could not save the review.';

  @override
  String homeDiveStarSubtitle(String rating, int count) {
    return 'Ops average $rating · $count reviews';
  }

  @override
  String get proTitle => 'Instructor C-Card verification';

  @override
  String get proBody =>
      'Upload a PADI/SSI instructor C-Card. Admin approval later unlocks pro pricing.';

  @override
  String get proAgency => 'Certifying agency';

  @override
  String get proPickPhoto => 'Attach C-Card photo';

  @override
  String get proSubmit => 'Apply for PRO';

  @override
  String get proSubmitDone => 'C-Card uploaded. Status is pending.';

  @override
  String get proSubmitFailed => 'Could not submit verification.';

  @override
  String get proStatusNone => 'Not submitted';

  @override
  String get proStatusPending => 'Pending';

  @override
  String get proStatusRejected => 'Rejected';

  @override
  String get communityTitle => 'Same Tide';

  @override
  String get communityHostMileage =>
      'When a flagged crew books, the host earns mileage.';

  @override
  String get profileTitle => 'My page';

  @override
  String get profileProBadge => 'PRO instructor verified';

  @override
  String get profileMasterChallenge => '100-log master challenge';

  @override
  String profileLogsProgress(int current, int target) {
    return '$current / $target';
  }

  @override
  String get profileMetalCard => 'Request a metal card';

  @override
  String get profileMetalCardHint =>
      'Reach 100 logs to request a physical metal card.';

  @override
  String get profileRadarTitle => 'Passport stamps';

  @override
  String profileRegions(int count) {
    return '$count regions explored';
  }

  @override
  String get metalCardDialogTitle => '100-log master';

  @override
  String get metalCardDialogBody =>
      'Free metal card shipping will connect in stage 2. This is a celebration screen for now.';

  @override
  String get metalCardDialogClose => 'OK';

  @override
  String get authLogin => 'Log in';

  @override
  String get authSignup => 'Sign up';

  @override
  String get authWelcome =>
      'After you sign up you can use logs, Same Tide, and bookings right away. An admin adjusts your grade based on activity.';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordHint => 'At least 6 characters';

  @override
  String get authDisplayName => 'Name';

  @override
  String get authNoAccount => 'No account? Sign up';

  @override
  String get authHaveAccount => 'Already have an account? Log in';

  @override
  String get authErrorInvalidEmail => 'Enter a valid email address.';

  @override
  String get authErrorInvalidCredential =>
      'That email is already registered. Sign in with the original password.';

  @override
  String get authResetPassword => 'Send password reset email';

  @override
  String get authResetPasswordSent =>
      'Password reset email sent. Check your inbox.';

  @override
  String get authErrorEmailInUse => 'That email is already registered.';

  @override
  String get authErrorWeakPassword => 'Password must be at least 6 characters.';

  @override
  String get authErrorNetwork => 'Check your network connection.';

  @override
  String get authErrorGeneric => 'Sign-in failed. Please try again.';

  @override
  String get authErrorOperationNotAllowed =>
      'Email/password sign-in is disabled. Enable it in Firebase Authentication.';

  @override
  String get authErrorFirestore =>
      'Account created, but the Firestore profile could not be saved. Create Firestore and paste the rules.';

  @override
  String get profileSignOut => 'Log out';

  @override
  String get logbookSaveFailed =>
      'Could not save the log. Check the network and Firebase rules.';

  @override
  String get firebaseSetupTitle => 'Firebase setup required';

  @override
  String get firebaseSetupBody =>
      'Create a DiveTravelApp Firebase project, enable Email/Password auth and Firestore, then run flutterfire configure.';

  @override
  String get adminMode => 'Admin mode';

  @override
  String get adminPinTitle => 'Admin PIN';

  @override
  String get adminPinHint => '4-digit PIN';

  @override
  String get adminPinConfirm => 'Enter';

  @override
  String get adminPinWrong => 'Incorrect PIN.';

  @override
  String get adminAccessDenied => 'This account does not have admin access.';

  @override
  String get adminDashboardTitle => 'Admin dashboard';

  @override
  String get adminDashboardSubtitle =>
      'Control instructor verification, Dive Star shops, and listings in one place.';

  @override
  String get adminHqTitle => 'Dive Travel HQ';

  @override
  String get adminHqSubtitle => 'Chief admin console';

  @override
  String get adminHqClose => 'Close';

  @override
  String get adminTabOverview => 'Overview';

  @override
  String get adminTabMembers => 'Members';

  @override
  String get adminTabCertify => 'Certify';

  @override
  String get adminTabShops => 'Shops';

  @override
  String get adminTabOps => 'Ops';

  @override
  String get adminMetricMembers => 'Members';

  @override
  String get adminMetricPendingCert => 'Pending certs';

  @override
  String get adminMetricPlaques => 'Plaque queue';

  @override
  String get adminMetricPosts => 'Posts';

  @override
  String adminMetricHidden(int count) {
    return '$count hidden';
  }

  @override
  String adminMetricShops(int count) {
    return '$count partner shops';
  }

  @override
  String get adminAttentionTitle => 'Needs attention';

  @override
  String get adminAttentionClear => 'No urgent items in the queue.';

  @override
  String adminAttentionCertify(int count) {
    return '$count instructor cards awaiting approval';
  }

  @override
  String adminAttentionPlaque(int count) {
    return '$count plaque shipments to review';
  }

  @override
  String adminAttentionHidden(int count) {
    return '$count hidden posts';
  }

  @override
  String get adminGradeMixTitle => 'Member grade mix';

  @override
  String get adminQuickActions => 'Quick actions';

  @override
  String get adminMembersTitle => 'Members';

  @override
  String get adminMembersSubtitle =>
      'Look up members and set Member, Special, VIP, or Instructor grade.';

  @override
  String get adminMembersSearch => 'Search name or email';

  @override
  String get adminMembersEmpty => 'No members match.';

  @override
  String get adminMembersGrade => 'Member grade';

  @override
  String adminMembersActivity(int logs, int regions) {
    return '$logs logs · $regions regions';
  }

  @override
  String adminMembersSuggested(String grade) {
    return 'Activity hint · $grade';
  }

  @override
  String get memberGradeMember => 'Member';

  @override
  String get memberGradeSpecial => 'Special';

  @override
  String get memberGradeVip => 'VIP';

  @override
  String get memberGradeInstructor => 'Instructor';

  @override
  String get adminInstructorsTitle => 'Instructor certificate review';

  @override
  String get adminInstructorsSubtitle =>
      'Review C-Cards on R2. Approval unlocks pro pricing.';

  @override
  String adminInstructorAgency(String agency) {
    return 'Agency · $agency';
  }

  @override
  String get adminApprove => 'Approve';

  @override
  String get adminReject => 'Reject';

  @override
  String get adminNoPending => 'No pending certificate requests.';

  @override
  String get adminShopsTitle => 'Dive Star · partner shops';

  @override
  String get adminShopsSubtitle =>
      'Monitor operation ratings, star grades, and plaque shipping.';

  @override
  String get adminProductsTitle => 'Travel product registration';

  @override
  String get adminProductsSubtitle =>
      'Pick a listing kind and submit. Products go live only after owner approval.';

  @override
  String get adminProductsTab => 'Products';

  @override
  String get adminProductPendingQueue => 'Pending approval';

  @override
  String get adminProductPendingEmpty => 'No products waiting for approval.';

  @override
  String get adminProductApproved => 'Product approved and published.';

  @override
  String get adminProductRejected => 'Product registration rejected.';

  @override
  String get adminProductSubmitHint =>
      'Saving sends the product to the approval queue. It stays hidden until approved.';

  @override
  String get adminProductSubmitted => 'Submitted for approval.';

  @override
  String get productListingKind => 'Listing kind';

  @override
  String get productListingDiveStar => 'Dive Star picks';

  @override
  String get productListingFavorites => 'Favorites';

  @override
  String get productListingPopular => 'Popular';

  @override
  String get productListingNextDeparture => 'Departing soon';

  @override
  String get productListingCurated => 'Curated offer';

  @override
  String get productStatusPending => 'Pending';

  @override
  String get productStatusApproved => 'Published';

  @override
  String get productStatusRejected => 'Rejected';

  @override
  String get productStatusDraft => 'Draft';

  @override
  String get partnerOwnProductsOnly =>
      'Partners can only manage products for their own shop.';

  @override
  String get partnerProductPendingHint =>
      'After you submit, the product appears once an admin approves it.';

  @override
  String get adminPlaqueQueue => 'Physical plaque shipping list';

  @override
  String get adminPlaqueEmpty => 'No shops have reached a star grade yet.';

  @override
  String get adminPlaqueRequest => 'Request plaque';

  @override
  String get adminPlaqueQueued => 'Shipping requested';

  @override
  String get adminPlaqueShipped => 'Shipped';

  @override
  String get adminPlaqueNone => 'Plaque pending';

  @override
  String get adminPlaqueMarkShipped => 'Mark shipped';

  @override
  String get adminShopMonitor => 'Worldwide partner shop monitor';

  @override
  String get adminPricingTitle => 'Instructor discount';

  @override
  String get adminPricingSubtitle =>
      'Guests see the listed price. Instructors get the percent or amount you set here.';

  @override
  String get adminPricingPercent => 'Percent off';

  @override
  String get adminPricingAmount => 'Amount off';

  @override
  String get adminPricingPercentHint => 'Discount percent (%)';

  @override
  String get adminPricingAmountHint => 'Discount amount (KRW)';

  @override
  String get adminPricingSave => 'Save discount';

  @override
  String get adminPricingSaved => 'Instructor discount saved.';

  @override
  String adminPricingPreview(String consumer, String pro) {
    return 'Guest $consumer KRW → instructor $pro KRW';
  }

  @override
  String get adminPostsTitle => 'Tours & buddy posts';

  @override
  String get adminPostsSubtitle =>
      'Review shop products and buddy posts. Hide or delete fake or illegal listings.';

  @override
  String get adminHidePost => 'Hide';

  @override
  String get adminUnhidePost => 'Unhide';

  @override
  String get adminDeletePost => 'Delete';

  @override
  String get adminEmptyPosts => 'No posts yet.';

  @override
  String get adminPostTypeBuddy => 'Buddy crew';

  @override
  String get adminPostTypeTour => 'Shop tour';

  @override
  String get adminPostHidden => 'Hidden';

  @override
  String get partnerTitle => 'Partner mode';

  @override
  String get partnerSubtitle =>
      'Edit your shop, list tours, and track this month\'s payout.';

  @override
  String get partnerAccessDenied => 'This account is not a Business partner.';

  @override
  String get partnerShopEdit => 'Edit shop profile';

  @override
  String get partnerShopEditHint =>
      'Save name, location, default product, and both prices.';

  @override
  String get partnerProductForm => 'Add product';

  @override
  String get partnerProductFormHint =>
      'Enter a consumer price and a professional price separately.';

  @override
  String get partnerSettlementTitle => 'This month\'s settlement';

  @override
  String get partnerCommissionRange =>
      'Net of the 10–15% platform fee (default 12%).';

  @override
  String get partnerGross => 'Booking revenue';

  @override
  String get partnerFee => 'Fee';

  @override
  String get partnerNet => 'Net payout';

  @override
  String get partnerBookingsTitle => 'Live bookings';

  @override
  String get partnerNoBookings => 'No bookings for this shop yet.';

  @override
  String get partnerShopName => 'Shop name';

  @override
  String get partnerShopLocation => 'Location';

  @override
  String get partnerDefaultProduct => 'Product name';

  @override
  String get partnerSave => 'Save';

  @override
  String get translateAction => '🌐 Translate';

  @override
  String get translateLoading => 'Translating…';

  @override
  String get translateShowOriginal => 'Show original';

  @override
  String get communityCompose => 'Raise a flag';

  @override
  String get communityPostTitle => 'One-line intent';

  @override
  String get communityPostBody => 'Why this boat';

  @override
  String get communityPostSubmit => 'Add to manifest';

  @override
  String get communityComments => 'Manifest notes';

  @override
  String get communityNoComments => 'No flags yet.';

  @override
  String get communityCommentHint => 'Leave a short note';

  @override
  String get communityTideKicker => 'SAME TIDE';

  @override
  String get communityTideHeadline => 'Open berths this week';

  @override
  String get communityTideBody =>
      'Pick by place, date, and empty seats. The shop assigns the water buddy.';

  @override
  String get communityTideSafety =>
      'The shop assigns the water buddy. This tab shares the van, the table, and the bed of a trip you already booked.';

  @override
  String get communityStatOpenSeats => 'Open seats';

  @override
  String communityUrgentBanner(int count) {
    return '$count last-call departures · view now';
  }

  @override
  String get communityBoardList => 'Departure board';

  @override
  String get communityBoardListHint =>
      'Open a card to raise a flag or continue to booking.';

  @override
  String get communityViewSeats => 'View seats';

  @override
  String get communityWindowOpen => 'Dates TBD';

  @override
  String get communityPlantFlag => 'Plant a flag';

  @override
  String get communityPlantFlagAsk =>
      'Put this booking on Same Tide so friends or a club can join?';

  @override
  String get communityPlantFlagLater => 'Later';

  @override
  String get communityNeedBooking =>
      'Plant a flag after you book. Pick a resort in Travel first.';

  @override
  String get communityRoomOpened => 'Your booked trip is now a room.';

  @override
  String get exploreChooseRoom => 'This resort\'s trips';

  @override
  String get exploreChooseRoomHint =>
      'Like choosing a room in a hotel, pick the dive product you want.';

  @override
  String get exploreResortTraits => 'Facilities & features';

  @override
  String get exploreAmenitiesHint =>
      'Comma-separated (e.g. Wi-Fi, pool, nitrox, airport pickup)';

  @override
  String get exploreRecommended => 'Recommended';

  @override
  String get exploreLightest => 'Lightest schedule';

  @override
  String exploreProductRooms(int count) {
    return '$count open rooms on this trip';
  }

  @override
  String get exploreResortIntro => 'About the resort';

  @override
  String get exploreResortMap => 'LOCATION';

  @override
  String get exploreResortAddress => 'Address';

  @override
  String get exploreEditResort => 'Edit resort page';

  @override
  String get exploreDeskHint =>
      'The local shop and the admin edit the same page. Saves show on the public listing immediately.';

  @override
  String exploreOpenRooms(int count) {
    return '$count open rooms';
  }

  @override
  String get exploreProductDuration => 'Duration';

  @override
  String get exploreProductBlurb => 'One-line pitch';

  @override
  String get exploreCoverPhoto => 'Cover photo';

  @override
  String get exploreCoverPhotoHint =>
      'Shown like Agoda: one large cover plus a photo grid. The first photo is the cover.';

  @override
  String get exploreGalleryTitle => 'Resort photos';

  @override
  String get exploreGalleryHint =>
      'Up to 12 photos. The first becomes the cover on listings and the detail page.';

  @override
  String get exploreGalleryAdd => 'Add photos';

  @override
  String get exploreGalleryAddMore => 'Add more photos';

  @override
  String get exploreGalleryEmpty =>
      'Attach photos to show an Agoda-style gallery.';

  @override
  String exploreGalleryCount(int count) {
    return '$count photos';
  }

  @override
  String get exploreGalleryViewAll => 'View all photos';

  @override
  String get exploreGalleryMakeCover => 'Set as cover';

  @override
  String get exploreSaveOk => 'Resort details saved.';

  @override
  String get exploreSaveFail =>
      'Could not save. Check permissions and network, then try again.';

  @override
  String get exploreSaving => 'Saving…';

  @override
  String get exploreAttachPhoto => 'Attach photo';

  @override
  String get exploreUseAsCover => 'Use this photo as the resort cover';

  @override
  String get exploreCoverRemove => 'Remove photo';

  @override
  String get communityFilterAll => 'All';

  @override
  String get communityFilterLastCall => 'Last call';

  @override
  String get communityFilterSolo => 'Solo';

  @override
  String get communityFilterShop => 'Shop';

  @override
  String communityBerths(int booked, int capacity) {
    return 'Berths $booked/$capacity';
  }

  @override
  String communityLooking(int count) {
    return 'Flags $count';
  }

  @override
  String communitySeatsLeft(int count) {
    return '$count empty';
  }

  @override
  String get communityRaiseFlag => 'Flag this boat';

  @override
  String get communityRaiseFlagDone => 'Your intent is on the manifest.';

  @override
  String get communityRaiseFlagMessage =>
      'I\'ll board this departure. See you at the shop briefing.';

  @override
  String get communityOpenTrip => 'Open this trip';

  @override
  String get communityWindowLabel => 'Window';

  @override
  String get communityPickShop => 'Shop to board';

  @override
  String get communityEmpty => 'No tides on the board yet.';

  @override
  String get communityKindShop => 'Shop crew';

  @override
  String get communityKindSolo => 'Solo share';

  @override
  String get communityKindLast => 'Last call';

  @override
  String get communityFrom => 'FROM';

  @override
  String get communityTo => 'TIDE';

  @override
  String get communityManifest => 'Manifest';

  @override
  String get weatherCancel => 'Weather cancel';

  @override
  String get weatherAdminTitle => 'Weather cancellation rights';

  @override
  String get weatherAdminBody =>
      'Mark that day\'s bookings as weather_cancelled and guarantee a 100% refund.';

  @override
  String get weatherTourDate => 'Tour date';

  @override
  String get weatherCancelDone =>
      'Weather cancellation and full refund applied.';

  @override
  String get weatherRefundTitle => '100% refund for weather';

  @override
  String weatherRefundBody(String shop, String product) {
    return '$shop · $product was cancelled for weather. Payment/points are fully refunded.';
  }

  @override
  String get weatherRefundAck => 'OK';

  @override
  String get bookingConfirmed => 'Confirmed';

  @override
  String get bookingCancelled => 'Cancelled';

  @override
  String get bookingWeatherCancelled => 'Weather cancelled · 100% refund';

  @override
  String get bookingCancel => 'Cancel booking';

  @override
  String bookingCancelledRefund(int percent) {
    return 'Cancelled · $percent% refund';
  }

  @override
  String refundPolicyHint(int percent) {
    return 'Cancel now for a $percent% refund';
  }
}
