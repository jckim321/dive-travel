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
  String get homeDiveStarTitle => 'Dive Star verified';

  @override
  String get homeDiveStarShelfHint => 'Seas the association checked itself';

  @override
  String get homeFavoritesTitle => 'I\'m the captain';

  @override
  String get homeDiverPlannedSubtitle => 'A trip just for us, with the crew';

  @override
  String get homeCaptainNeedsGold => 'Gold members can become captains.';

  @override
  String get homeBecomeCaptain => 'Become a captain';

  @override
  String get homePopularTitle => 'Spots heating up';

  @override
  String get homeHotSpotSubtitle => 'Divers are gathering here lately';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeFavoritesEmpty =>
      'Tap a heart or log a dive to collect your regular resorts.';

  @override
  String get homeShelfEmpty => 'Nothing on this shelf yet — it will fill soon.';

  @override
  String get homeCuratedTitle => 'Editor specials';

  @override
  String get homeCuratedSubtitle => 'Trips Dive Travel put together';

  @override
  String get homeLastCallSubtitle => 'Fill a seat and share the boat';

  @override
  String get homeChipAll => 'All';

  @override
  String get homeChipRecommended => 'Picks';

  @override
  String get homeChipFavorites => 'Saved';

  @override
  String get homeChipLastMinute => 'Last call';

  @override
  String get homeMapEmptyPrompt => 'Open your first ocean';

  @override
  String get homeApdiSpecial => 'APDI SPECIAL';

  @override
  String get homeCrewRecruiting => 'Recruiting a crew';

  @override
  String homeSameBoatCountdown(int days, int seats) {
    return 'D-$days · $seats seats left';
  }

  @override
  String homeSameBoatSeatsLeft(int seats) {
    return '$seats seats left';
  }

  @override
  String homeBoardingUntil(int days) {
    return 'D-$days until departure';
  }

  @override
  String get homeNextDepartures => 'Same boat · last call';

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
  String get exploreSeeMore => 'See more ›';

  @override
  String get exploreOtherRegion => 'Other';

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
  String get exploreRegionPacific => 'Pacific & Oceania';

  @override
  String get exploreRegionAfricaRed => 'Africa & Red Sea';

  @override
  String get exploreRegionNorthAmerica => 'North & Central America';

  @override
  String get exploreRegionSouthAmerica => 'South America';

  @override
  String get exploreZoneMicronesia => 'Micronesia';

  @override
  String get exploreZoneMelanesia => 'Melanesia';

  @override
  String get exploreZonePolynesia => 'Polynesia';

  @override
  String get exploreZoneOther => 'Other areas';

  @override
  String get exploreSeaIndian => 'Indian Ocean';

  @override
  String get exploreSeaRed => 'Red Sea';

  @override
  String get exploreSeaCaribbean => 'Caribbean';

  @override
  String get exploreSeaSouthPacific => 'South Pacific';

  @override
  String get exploreProBanner =>
      'Instructor verified · every shop shows the professional price';

  @override
  String get exploreConsumerBanner =>
      'Guest pricing · request a seat, pay after the shop confirms';

  @override
  String get exploreBook => 'Book';

  @override
  String get optionBookPackage => 'Book this trip';

  @override
  String get optionBookAddon => 'Add this and book';

  @override
  String get optionBookIndividual => 'Book this only';

  @override
  String get explorePay => 'Pay';

  @override
  String explorePayAmount(String price) {
    return 'Pay $price KRW';
  }

  @override
  String get checkoutGuestName => 'Booker name';

  @override
  String get checkoutGuestBirth => 'Date of birth';

  @override
  String get checkoutGuestContact => 'Contact';

  @override
  String get simPayTitle => 'Confirm booking request';

  @override
  String get simPayNotice =>
      'No charge yet. Payment continues after the shop confirms.';

  @override
  String get simPaySameBoatTitle => 'Confirm payment';

  @override
  String get simPaySameBoatNotice =>
      'This is a test payment. Real payments are not connected yet. Completing payment confirms your seat.';

  @override
  String get simPaySameBoatAction => 'Pay';

  @override
  String get simPayAction => 'Request booking';

  @override
  String get simPayProcessing => 'Submitting request';

  @override
  String get simPayDoneTitle => 'Request submitted';

  @override
  String get simPayDoneBody =>
      'Your booking request will be saved as unpaid until the shop confirms.';

  @override
  String get simPayClose => 'OK';

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
  String get exploreBookingNotSaved =>
      'The booking was not saved because the seats could not be held. Check the open seats and try again.';

  @override
  String exploreCheckoutDone(String label, String price) {
    return 'Booking sent for $label $price.';
  }

  @override
  String get sameBoatSeatConfirmed =>
      'Payment completed and your seat is confirmed (test payment).';

  @override
  String get exploreConsumerPayHint =>
      'This is the shop\'s listed guest price.';

  @override
  String get exploreNoResults => 'No shops match that search.';

  @override
  String get exploreCountryEmpty => 'No trips listed here yet';

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
  String exploreCardDiveStar(String marks) {
    return 'Dive Star $marks';
  }

  @override
  String get exploreCardDiveStarRenew => 'Dive Star renewal needed';

  @override
  String get exploreCardPartner => 'Partner';

  @override
  String get exploreDiveStarRenewalNeeded => 'Renewal needed';

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
  String exploreDepartureBanner(int days, String shop) {
    return 'Departure D-$days · $shop';
  }

  @override
  String get reviewTitle => 'Trip review';

  @override
  String get reviewIntro => 'Pick a star rating and leave a short note.';

  @override
  String get reviewShopLabel => 'Resort / dive shop';

  @override
  String get reviewStarsLabel => 'Rating';

  @override
  String get reviewNoReviewsYet => 'No reviews yet';

  @override
  String reviewCountLabel(String rating, int count) {
    return '★ $rating ($count reviews)';
  }

  @override
  String get reviewSectionTitle => 'Diver reviews';

  @override
  String reviewSectionSummary(String rating, int count) {
    return '★ $rating · $count reviews';
  }

  @override
  String get reviewSectionEmpty => 'No reviews yet. Be the first to leave one.';

  @override
  String get reviewLoadMore => 'Load more';

  @override
  String get reviewAuthorFallback => 'Diver';

  @override
  String get reviewSafety => '1. Safety and gear';

  @override
  String get reviewGuide => '2. Guide professionalism';

  @override
  String get reviewBoat => '3. Boat and facilities';

  @override
  String get reviewComment => 'Review (optional)';

  @override
  String get reviewSubmit => 'Save';

  @override
  String get reviewWrite => 'Write review';

  @override
  String get reviewDone => 'Reviewed';

  @override
  String get reviewSaved => 'Review saved.';

  @override
  String get reviewSavedProductIdMissing =>
      'This booking has no product id, so the product card rating was not updated.';

  @override
  String get reviewSavedProductNotFound =>
      'Could not find that product on the shop, so the product card rating was not updated.';

  @override
  String get reviewSaveFailed => 'Could not save the review.';

  @override
  String get reviewAlreadySubmitted =>
      'You already left a review for this trip.';

  @override
  String get reviewBookingRequired =>
      'You can leave a review only for a completed booking.';

  @override
  String get reviewInvalidStars => 'Ratings must be between 1 and 5.';

  @override
  String get reviewCommentTooLong => 'Reviews can be up to 2,000 characters.';

  @override
  String get reviewDetailsExpand => 'Add more trip details';

  @override
  String get reviewDetailLevel => 'Diver level';

  @override
  String get reviewDetailDives => 'Total dives';

  @override
  String get reviewDetailVisibility => 'Visibility';

  @override
  String get reviewDetailCurrent => 'Current';

  @override
  String get reviewDetailWaterTemp => 'Water temp (°C)';

  @override
  String get reviewDetailCrowd => 'Divers per guide';

  @override
  String get reviewDetailAudience => 'Best for';

  @override
  String get reviewDetailRevisit => 'Would visit again';

  @override
  String get reviewDetailOptionalHint => 'All fields are optional';

  @override
  String get reviewDetailOpenWater => 'Open Water';

  @override
  String get reviewDetailAdvanced => 'Advanced';

  @override
  String get reviewDetailRescuePlus => 'Rescue+';

  @override
  String get reviewDetailInstructor => 'Instructor';

  @override
  String get reviewDetailFreediver => 'Freediver';

  @override
  String get reviewDetailDivesUnder50 => 'Under 50';

  @override
  String get reviewDetailDives50to200 => '50–200';

  @override
  String get reviewDetailDives200Plus => '200+';

  @override
  String get reviewDetailVisPoor => 'Poor';

  @override
  String get reviewDetailVisOk => 'OK';

  @override
  String get reviewDetailVisGood => 'Good';

  @override
  String get reviewDetailVisExcellent => 'Excellent';

  @override
  String get reviewDetailCurrentMild => 'Mild';

  @override
  String get reviewDetailCurrentOk => 'Moderate';

  @override
  String get reviewDetailCurrentStrong => 'Strong';

  @override
  String get reviewDetailCrowdRelaxed => 'Relaxed';

  @override
  String get reviewDetailCrowdOk => 'OK';

  @override
  String get reviewDetailCrowdBusy => 'Busy';

  @override
  String get reviewDetailAudienceBeginner => 'Beginners';

  @override
  String get reviewDetailAudienceExperienced => 'Experienced';

  @override
  String get reviewDetailAudienceCouple => 'Couples';

  @override
  String get reviewDetailAudienceFamily => 'Families';

  @override
  String get reviewDetailAudiencePhoto => 'Photo divers';

  @override
  String get reviewDetailAudienceFreediver => 'Freedivers';

  @override
  String get reviewDetailAudienceTech => 'Technical';

  @override
  String get reviewDetailRevisitYes => 'Yes';

  @override
  String get reviewDetailRevisitNo => 'No';

  @override
  String get reviewDetailRevisitUnsure => 'Not sure';

  @override
  String reviewDetailWaterTempChip(String temp) {
    return '$temp°C';
  }

  @override
  String get reviewInvalidDetails => 'One of the detail options is invalid.';

  @override
  String get reviewInvalidWaterTemp =>
      'Water temp must be between -2°C and 40°C.';

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
  String get profileDepartureDeskKicker => 'Departure desk';

  @override
  String get profileCraftedTripsTitle => 'I\'m the captain';

  @override
  String get profileCraftedTripsHint =>
      'Pick a resort, draft the trip, and it goes live after admin approval.';

  @override
  String get profileCraftNewTrip => 'Craft a new trip';

  @override
  String get profileCaptainTripTitle => 'A captain\'s new trip';

  @override
  String get profileCraftNeedsGold =>
      'Gold and above can craft a trip. Pay for your first trip to reach Gold.';

  @override
  String get profileCraftStatusPending => 'Pending';

  @override
  String get profileCraftStatusLive => 'Live';

  @override
  String get profileCraftStatusRejected => 'Rejected';

  @override
  String get profileDeskToolsTitle => 'Desk tools';

  @override
  String get profileDeskToolsHint =>
      'Admin, partner, instructor verification, and sign-out live here.';

  @override
  String get productFormNotInList => 'Resort not in list';

  @override
  String get productFormCreatorShopHint =>
      'Choose a continent, then a resort. If it is missing, type the name yourself.';

  @override
  String get profileMyOceanKicker => 'MY OCEAN';

  @override
  String get profileGradeSilver => 'Silver';

  @override
  String get profileGradeGold => 'Gold';

  @override
  String get profileGradeDiamond => 'Diamond';

  @override
  String get profileGradePlatinum => 'Platinum';

  @override
  String get profileGradeInstructor => 'Instructor';

  @override
  String get profileViewMyInfo => 'View my info';

  @override
  String get profileNextOceanTitle => 'Your next ocean';

  @override
  String get profileNoUpcomingTrip => 'Your next ocean is still open';

  @override
  String get profileNoUpcomingTripHint =>
      'Start with a place you saved for later.';

  @override
  String get profileSavedOceansTitle => 'Oceans I’m waiting for';

  @override
  String get profileSavedOceansEmpty =>
      'No saved oceans yet. Tap the heart on any travel product.';

  @override
  String get profileOceanRecordTitle => 'My ocean record';

  @override
  String get profileTotalDives => 'Total dives';

  @override
  String get profileExploredSeas => 'Seas explored';

  @override
  String profileNextMilestone(int count) {
    return '$count logs to the next milestone';
  }

  @override
  String get profileActivityTitle => 'My activity';

  @override
  String get profileBookingHistory => 'Booking history';

  @override
  String get profileTripScheduleTitle => 'My trip schedule';

  @override
  String get profileTripScheduleEmpty => 'No confirmed trips yet.';

  @override
  String get profileFlaggedSeatsTitle => 'Flagged leftover seats';

  @override
  String get profileFlaggedSeatsEmpty => 'No seats on hold.';

  @override
  String get profileFlagPayCta => 'Pay now';

  @override
  String get profileWishlistTitle => 'Places I want to go';

  @override
  String get profileReviewRecommendTitle => 'Recommended by reviews';

  @override
  String get myReviewsTitle => 'My reviews';

  @override
  String get myReviewsMenu => 'View and edit my reviews';

  @override
  String get myReviewsMenuHint =>
      'Open reviews you wrote to edit or delete them.';

  @override
  String get myReviewsEmpty =>
      'You have not written a review yet. Leave one after a finished trip.';

  @override
  String get myReviewNoProduct => 'No product linked';

  @override
  String get myReviewEditedBadge => 'Edited';

  @override
  String get myReviewEditTitle => 'Edit review';

  @override
  String get myReviewEditHint =>
      'You can change stars, text, and details. Resort, product, and booking stay fixed.';

  @override
  String get myReviewSaveEdit => 'Save changes';

  @override
  String get myReviewUpdated => 'Review updated.';

  @override
  String get myReviewDeleteTitle => 'Delete this review?';

  @override
  String get myReviewDeleteBody =>
      'Deleting removes it from resort and product ratings. You can write a new review for the same booking afterward.';

  @override
  String get myReviewDeleteAction => 'Delete review';

  @override
  String get myReviewDeleted => 'Review deleted.';

  @override
  String get profileWriteReviewTitle => 'Write a review of a trip I took';

  @override
  String get profileCharmsTitle => 'My ocean charms';

  @override
  String get profileDivingPassportTitle => 'My diving passport';

  @override
  String profileDivingPassportRegions(int count) {
    return '$count regions';
  }

  @override
  String profileDivingPassportDives(String count) {
    return '$count dives';
  }

  @override
  String profileDivingPassportShowAll(int count) {
    return 'Show all stamps ($count)';
  }

  @override
  String get profileDivingPassportShowLess => 'Show fewer stamps';

  @override
  String get bookingVoucherOpen => 'Travel voucher';

  @override
  String get bookingVoucherTitle => 'Travel voucher';

  @override
  String get bookingVoucherSave => 'Save to phone';

  @override
  String get bookingVoucherSaved =>
      'Opened the share sheet so you can save the voucher.';

  @override
  String get bookingVoucherId => 'Booking ID';

  @override
  String get bookingVoucherShop => 'Shop';

  @override
  String get profileBookingStatus => 'My bookings';

  @override
  String get profilePaidBookingsEmpty => 'No paid bookings yet.';

  @override
  String get profileRequestedBookingsEmpty => 'No booking requests yet.';

  @override
  String get profileBookingFilterAll => 'All';

  @override
  String get profileBookingFilterRequested => 'Requested';

  @override
  String get profileBookingFilterHolding => 'Holding';

  @override
  String get profileBookingFilterPaid => 'Paid';

  @override
  String get profileLiveFlagsTitle => 'Flags I planted';

  @override
  String get profileLiveFlagsEmpty => 'No live flags.';

  @override
  String get profileAfterTripTitle => 'After the trip';

  @override
  String get profileAfterTripEmpty => 'Nothing to review.';

  @override
  String get profileNextTripSuggest => 'A sea to try next';

  @override
  String profileBookingCount(int count) {
    return '$count bookings';
  }

  @override
  String profileCraftedCount(int count) {
    return '$count trips crafted';
  }

  @override
  String get profileSettingsTitle => 'Settings';

  @override
  String get profileMembershipTitle => 'Membership';

  @override
  String get profileGradeFirstTide =>
      'Pay for your first trip and you cross into Gold.';

  @override
  String profileGradeStepsLeft(String next, int count) {
    return '$count more trips until $next.';
  }

  @override
  String get profileGradeDeepest =>
      'You are already at the deepest grade, Platinum.';

  @override
  String get profileGradeShownAsInstructor =>
      'You are shown as Instructor. The stored grade stays as it is.';

  @override
  String get profileCredentialsTitle => 'Certification & grade';

  @override
  String get profileWorkModeTitle => 'Work mode';

  @override
  String get devRolesTitle => 'Test role switcher';

  @override
  String get devRolesHint =>
      'Owner account only. Keeps Firestore is_admin; overlays diver / partner / admin in the app.';

  @override
  String get devRolesDiver => 'Guest';

  @override
  String get devRolesPartner => 'Partner';

  @override
  String get devRolesAdmin => 'Admin';

  @override
  String get devRolesShop => 'Partner shop';

  @override
  String get devRolesApply => 'Apply';

  @override
  String get devRolesApplied => 'Test role applied.';

  @override
  String get devRolesNeedShop => 'Pick a shop for the partner role.';

  @override
  String get devRolesTrialCaption => 'Trial only — remove before launch.';

  @override
  String profileUpcomingConfirmed(String date) {
    return 'Confirmed · $date';
  }

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
  String get authFirstVisit => 'I\'m new';

  @override
  String get authWelcomeBack => 'I\'m back';

  @override
  String get authHeroTitle => 'Dive travel,\ntogether';

  @override
  String get authHeroSignupHint =>
      'An ID and password are enough to get started';

  @override
  String get authHeroLoginHint => 'Come back in with your ID and password';

  @override
  String get authSignupPanelTitle => 'Sign up';

  @override
  String get authSignupPanelBody =>
      'Use logs, Same Tide, and bookings right away';

  @override
  String get authLoginPanelTitle => 'Log in';

  @override
  String get authLoginPanelBody => 'Pick up where you left your trip';

  @override
  String get authNameTag => 'ID';

  @override
  String get authIdRuleHint => 'Korean, English, digits, or _';

  @override
  String get authIdRuleHintLong =>
      'Shown in the app · Korean, English, or digits';

  @override
  String get authIdFieldHint => 'Enter your ID';

  @override
  String get authIdExampleHint => 'e.g. sea_turtle';

  @override
  String get authPasswordRuleHint => 'At least 6 characters';

  @override
  String get authPasswordFieldHint => 'Enter your password';

  @override
  String get authKeepSignedIn => 'Stay signed in on this device';

  @override
  String get authKeepSignedInShort => 'Keep me signed in';

  @override
  String get authWelcomeBanner => 'Welcome to Dive Travel';

  @override
  String get authBrowseFirst => 'Browse first';

  @override
  String get authFooterCheer => 'Dive Travel cheers for your next ocean';

  @override
  String get authFooterContact => 'Help | help@divetravel.com';

  @override
  String get authSignupHeroBody => 'About 30 seconds. Only what we need.';

  @override
  String get authSignupMoreAbout => 'Tell us more (optional)';

  @override
  String get authSignupMoreAboutHint =>
      'Name, birthday, contact, nationality — autofill at checkout';

  @override
  String get authSignupLegalName => 'Name';

  @override
  String get authSignupLegalNameHint => 'Name for booking and payment';

  @override
  String get authSignupBirthDate => 'Birthday';

  @override
  String get authSignupPhone => 'Contact';

  @override
  String get authSignupPhoneHint => 'Mobile number';

  @override
  String get authConsentAll => 'Agree to all';

  @override
  String get authConsentTerms => 'Terms of use (required)';

  @override
  String get authConsentPrivacy => 'Privacy collection & use (required)';

  @override
  String get authConsentMarketing => 'Event & news alerts (optional)';

  @override
  String get authTermsView => 'View';

  @override
  String get authTermsClose => 'Close';

  @override
  String get authSignupAndBrowse => 'Sign up and browse trips';

  @override
  String get authHaveAccountPrompt => 'Already have an account?';

  @override
  String get authErrorTermsRequired => 'Please accept the required terms.';

  @override
  String get authStart => 'Get started';

  @override
  String get authForgotPasswordNote =>
      'Forgot your password? Tell the crew (temporary, before launch)';

  @override
  String get authTrialNote =>
      'Pre-launch trial · sign-up and sign-in on one screen, two fields';

  @override
  String get authErrorNameTagRequired => 'Enter an ID.';

  @override
  String get authErrorNameTagTooLong =>
      'That ID is too long. Try a shorter one.';

  @override
  String get authNationality => 'Nationality (optional)';

  @override
  String get authNationalityNone => 'Skip';

  @override
  String get profileNationality => 'Nationality';

  @override
  String get profileNationalityEmpty => 'Not set';

  @override
  String get profileNationalitySave => 'Save';

  @override
  String get profileNationalityClear => 'Clear';

  @override
  String get profileNationalityNeedConsent =>
      'Consent is required to save a nationality';

  @override
  String get authWelcome =>
      'Sign up with a username and password to use logs, Same Tide, and bookings. Admins promote affiliate partners.';

  @override
  String get authEmail => 'Email';

  @override
  String get authLoginId => 'Username';

  @override
  String get authLoginIdOrEmail => 'Username or email';

  @override
  String get authLoginIdHint => 'lowercase letters, digits, _ · 4–20 chars';

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
      'Check your username (or email) and password.';

  @override
  String get authResetPassword => 'Send password reset email';

  @override
  String get authResetPasswordSent =>
      'Password reset email sent. Check your inbox.';

  @override
  String get authPasswordResetHiddenHint =>
      'Password reset is hidden until launch. Contact an admin if you need help.';

  @override
  String get authErrorEmailInUse => 'That email is already registered.';

  @override
  String get authErrorLoginIdInUse =>
      'That ID is already taken. Pick another one.';

  @override
  String get authErrorLoginIdFormat =>
      'ID can only use Korean, English letters, digits, or _.';

  @override
  String get authErrorLoginIdReserved =>
      'That ID can\'t be used. Pick another one.';

  @override
  String get authErrorDisplayNameRequired => 'Enter your name.';

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
  String get profilePasswordTitle => 'Change password';

  @override
  String get profilePasswordCurrent => 'Current password';

  @override
  String get profilePasswordNew => 'New password';

  @override
  String get profilePasswordConfirm => 'Confirm new password';

  @override
  String get profilePasswordSave => 'Change password';

  @override
  String get profilePasswordSaved => 'Password changed.';

  @override
  String get profilePasswordWrong => 'Current password is wrong.';

  @override
  String get profilePasswordTooShort =>
      'New password must be at least 6 characters.';

  @override
  String get profilePasswordMismatch => 'The new passwords do not match.';

  @override
  String get profilePasswordRelogin => 'Please sign in again.';

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
  String get devicePinSetupTitle => 'Set device PIN';

  @override
  String get devicePinSetupBody =>
      'A 4-digit PIN for this device only. It is never sent to the server.';

  @override
  String get devicePinUnlockTitle => 'Unlock with device PIN';

  @override
  String get devicePinUnlockBody =>
      'You stay signed in. Enter your 4-digit device PIN to unlock.';

  @override
  String get devicePinHint => '4 digits';

  @override
  String get devicePinConfirmHint => 'Enter again';

  @override
  String get devicePinSave => 'Save';

  @override
  String get devicePinMismatch => 'The two PINs do not match.';

  @override
  String devicePinWrong(int remain) {
    return 'Incorrect PIN. $remain tries left.';
  }

  @override
  String get devicePinLockedOut =>
      'PIN cleared after 5 wrong tries. Sign in again with your ID and password.';

  @override
  String get devicePinSettingsTitle => 'Device PIN';

  @override
  String get devicePinSettingsSet => 'Set device PIN';

  @override
  String get devicePinSettingsChange => 'Change device PIN';

  @override
  String get devicePinSettingsHint =>
      'Unlock this device with a PIN when you reopen the app.';

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
  String get adminTabDiveStar => 'Dive Star';

  @override
  String get adminTabProducts => 'Products';

  @override
  String get adminTabBookings => 'Bookings';

  @override
  String get adminTabSettlement => 'Partner settlement';

  @override
  String get adminTabSales => 'Sales';

  @override
  String get adminTabStats => 'Stats';

  @override
  String get adminTabReports => 'Business reports';

  @override
  String get adminNavMore => 'More';

  @override
  String get adminNavToolsSection => 'Tools';

  @override
  String get adminFilterMore => 'More filters';

  @override
  String get adminMembersSubGeneral => 'Members';

  @override
  String get adminMembersSubDivers => 'Divers';

  @override
  String get adminMembersSubInstructors => 'Instructor review';

  @override
  String get adminMembersSubPartners => 'Partners';

  @override
  String get adminPartnersSearch => 'Search partners / shops';

  @override
  String get adminProductsSearch => 'Search products';

  @override
  String get adminProductSourceFilter => 'Source';

  @override
  String get adminDiveStarSubApplications => 'Applications';

  @override
  String get adminDiveStarSubReview => 'Review & grade';

  @override
  String get adminDiveStarSubForms => 'Forms';

  @override
  String get adminDiveStarReviewSearch => 'Search shop name';

  @override
  String get adminDiveStarReviewPending => 'Awaiting review';

  @override
  String get adminDiveStarReviewEmpty => 'No partners match.';

  @override
  String get adminBookingsSubList => 'Bookings';

  @override
  String get adminBookingsSubPayment => 'Payment monitoring';

  @override
  String get adminBookingsSubCustomers => 'Customer lookup';

  @override
  String get adminBookingsSubCancel => 'Cancel & refund';

  @override
  String get adminSettlementSubPricing => 'Discount & terms';

  @override
  String get adminSettlementSubHistory => 'Settlement history';

  @override
  String get adminPostsCommunityShort => 'Community posts';

  @override
  String get adminGradeMixInstructorNote =>
      'Certified instructors are shown as Instructor. The stored grade stays as it is.';

  @override
  String get adminMembersGradeAll => 'All';

  @override
  String get adminMembersNeedsAction => 'Needs action';

  @override
  String adminMembersNeedsActionHint(int count) {
    return '$count instructor approvals waiting — open Instructor review.';
  }

  @override
  String adminMembersPurchasesReviews(int purchases, int reviews) {
    return '$purchases purchases · $reviews reviews';
  }

  @override
  String get adminMembersGradeLocked => 'Manually set · auto-upgrade locked.';

  @override
  String get adminMembersUnlockAuto => 'Allow auto-upgrade';

  @override
  String get adminPulseTitle => 'Pulse';

  @override
  String get adminPulseSalesMonth => 'Sales this month';

  @override
  String get adminPulseConversion => 'Paid conversion';

  @override
  String adminPulseFunnelHint(int paid, int requested) {
    return 'Paid $paid · requested $requested';
  }

  @override
  String get adminPulseNewWeek => 'New this week';

  @override
  String get adminVisitsTitle => 'Visit frequency';

  @override
  String get adminVisitsDau => 'Today (DAU)';

  @override
  String get adminVisitsWau => '7-day (WAU)';

  @override
  String get adminVisitsMau => '30-day (MAU)';

  @override
  String get adminVisitsDormant => 'Dormant (30d+)';

  @override
  String get adminNewMembersTitle => 'New members';

  @override
  String get adminNewMembersToday => 'Joined today';

  @override
  String get adminNewMembersWeek => 'Joined in 7d';

  @override
  String get adminNewMembersMonth => 'Joined in 30d';

  @override
  String get adminNewMembersPaid => 'New→first pay (30d)';

  @override
  String get adminFunnelTitle => 'Booking funnel';

  @override
  String get adminFunnelRequested => 'Requested (unpaid)';

  @override
  String get adminFunnelPaid => 'Paid / confirmed';

  @override
  String get adminFunnelCancelled => 'Cancelled / closed';

  @override
  String get adminFunnelUnreviewed => 'Paid, no review';

  @override
  String get adminNearUpgradeTitle => 'Near upgrade';

  @override
  String adminNearUpgradeHint(int purchases) {
    return '$purchases purchases to the next grade';
  }

  @override
  String get adminProductSignalTitle => 'Product signals';

  @override
  String get adminProductSignalPublic => 'Public products';

  @override
  String get adminProductSignalPending => 'Pending approval';

  @override
  String get adminProductSignalShops => 'Partner shops';

  @override
  String gradeCelebrationTitle(String grade) {
    return 'You reached $grade!';
  }

  @override
  String gradeCelebrationBody(String grade) {
    return 'Thank you for diving with us. Dive Travel cheers your $grade journey.';
  }

  @override
  String get gradeCelebrationThanks => 'Thanks';

  @override
  String get adminMembersBadgeInstructor => 'Instructor';

  @override
  String get adminMembersBadgePartner => 'Partner';

  @override
  String get adminMembersBadgeAdmin => 'Admin';

  @override
  String adminMembersLoginId(String id) {
    return 'Username · $id';
  }

  @override
  String adminMembersRoleStatus(String kind, String role, String shop) {
    return 'Role · $kind · user_role=$role · shop=$shop';
  }

  @override
  String get adminMembersRoleAdmin => 'App owner admin';

  @override
  String get adminMembersRolePartner => 'Affiliate partner';

  @override
  String get adminMembersRoleDiver => 'Member';

  @override
  String get adminMembersLeftoverPartnerHint =>
      'Admin still has partner flags. Use Demote partner to clear them.';

  @override
  String get adminMembersPromotePartner => 'Promote to partner';

  @override
  String get adminMembersDemotePartner => 'Demote partner';

  @override
  String adminMembersPromoteConfirm(String name) {
    return 'Promote $name to affiliate partner. Pick an unowned shop or create one.';
  }

  @override
  String adminMembersDemoteConfirm(String name, String shop) {
    return 'Demote $name? Shop link $shop will be cleared (the shop stays).';
  }

  @override
  String get adminMembersPromotePickShop => 'Link existing shop';

  @override
  String get adminMembersPromoteNewShop => 'Create new shop';

  @override
  String get adminMembersNewShopName => 'New shop name';

  @override
  String get adminMembersNoUnownedShops =>
      'No unowned shops. Create a new one.';

  @override
  String get adminMembersAlreadyPartner => 'This member is already a partner.';

  @override
  String get adminMembersShopOwned => 'That shop already has an owner.';

  @override
  String get adminMembersPromoteDone => 'Promoted to partner.';

  @override
  String get adminMembersDemoteDone => 'Partner demoted.';

  @override
  String get adminMembersPromoteFailed => 'Promotion failed.';

  @override
  String get adminMembersDemoteFailed => 'Demotion failed.';

  @override
  String get adminPartnerTierAll => 'All';

  @override
  String get adminPartnerTierReviewPending => 'Pre-review';

  @override
  String get adminPartnerTierStar1 => 'Dive Star 1';

  @override
  String get adminPartnerTierStar2 => 'Dive Star 2';

  @override
  String get adminPartnerTierStar3 => 'Dive Star 3';

  @override
  String get adminPartnerTierEmpty => 'No partners in this tier.';

  @override
  String get adminPartnerOpenInstructors => 'Open instructor review';

  @override
  String get adminTabCertify => 'Certify';

  @override
  String get adminTabShops => 'Partners';

  @override
  String get adminTabContracts => 'Partner contracts';

  @override
  String get adminTabOps => 'Ops';

  @override
  String get adminContractsSubOverview => 'Contract status';

  @override
  String get adminContractsSubVault => 'Document vault';

  @override
  String get adminContractsSubTerms => 'Contract terms';

  @override
  String get adminContractsSubInbox => 'Proposal inbox';

  @override
  String get adminTermsMissing => 'Not entered';

  @override
  String get adminTermsCommission => 'Commission rate';

  @override
  String get adminTermsParty => 'Group discount';

  @override
  String get adminTermsSeason => 'Seasonal discount';

  @override
  String get adminTermsFoc => 'Instructor FOC';

  @override
  String get adminTermsFocPay => 'Paid guests';

  @override
  String get adminTermsFocFree => 'Free guests';

  @override
  String get adminTermsPeriod => 'Contract period';

  @override
  String get adminTermsFrom => 'Start';

  @override
  String get adminTermsUntil => 'End';

  @override
  String get adminTermsClear => 'Clear';

  @override
  String get adminTermsSave => 'Save';

  @override
  String get adminTermsSaved => 'Saved';

  @override
  String get adminTermsUnchanged => 'Nothing changed';

  @override
  String get adminTermsHistory => 'Change history';

  @override
  String get adminTermsHistoryEmpty => 'No changes yet.';

  @override
  String get adminTermsBadNumber => 'Enter a number inside the allowed range.';

  @override
  String get adminTermsFocPair =>
      'Enter both FOC numbers, like 10+1, or leave both empty.';

  @override
  String get adminTermsBadPeriod =>
      'The end date must be on or after the start date.';

  @override
  String get partnerPromoChip => 'Promotion';

  @override
  String get partnerPromoSend => 'Send';

  @override
  String get partnerPromoSent => 'Sent';

  @override
  String get partnerPromoNote => 'One-line note';

  @override
  String get partnerPromoKind => 'Kind';

  @override
  String get partnerPromoBadNote => 'Write a note between 1 and 80 characters.';

  @override
  String get partnerPromoBadPeriod =>
      'Keep the period within one year of the start date.';

  @override
  String get partnerPromoBadKind => 'Choose a kind.';

  @override
  String get partnerPromoBadDay => 'Enter a date like 2026-10-01.';

  @override
  String get adminPromoNew => 'New';

  @override
  String get adminPromoHandled => 'Handled';

  @override
  String get adminPromoMark => 'Mark handled';

  @override
  String get adminPromoEmpty => 'No proposals yet.';

  @override
  String get adminContractsComingSoon => 'Coming soon';

  @override
  String get adminContractStatusNone => 'Not signed';

  @override
  String get adminContractStatusAwaiting => 'Awaiting signature';

  @override
  String get adminContractStatusExecuted => 'Executed';

  @override
  String get adminContractStatusExpiring => 'Expiring soon';

  @override
  String get adminVaultUpload => 'Upload PDF';

  @override
  String get adminVaultSend => 'Send to partner';

  @override
  String get adminVaultVoid => 'Void';

  @override
  String get adminVaultDownload => 'Download executed pack';

  @override
  String get adminVaultPickShop => 'Select a partner shop';

  @override
  String get adminVaultTitleHint => 'Document title';

  @override
  String get adminVaultVersionHint => 'Version';

  @override
  String get adminVaultKindMaster => 'Master agreement';

  @override
  String get adminVaultKindAnnex => 'Annex';

  @override
  String get adminVaultEmpty => 'No documents in this vault.';

  @override
  String get partnerVaultTitle => 'Document vault';

  @override
  String get partnerVaultAwaiting => 'Awaiting signature';

  @override
  String get partnerVaultExecuted => 'Executed';

  @override
  String get partnerVaultEmpty => 'No contract documents yet.';

  @override
  String get partnerVaultOpen => 'Review & sign';

  @override
  String get partnerVaultSign => 'Sign and execute';

  @override
  String get partnerVaultRevision => 'Request revision';

  @override
  String get partnerVaultRevisionHint => 'Describe what needs to change';

  @override
  String get partnerVaultShaMismatch =>
      'The file changed. Signing stopped. Contact ops.';

  @override
  String get partnerVaultAckView => 'I have reviewed this document';

  @override
  String get partnerVaultAgree => 'I agree to the contract terms';

  @override
  String get partnerVaultSignerName => 'Signer name';

  @override
  String get partnerVaultSignature => 'Handwritten signature';

  @override
  String get partnerVaultDownload => 'Download original + signature';

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
  String get adminSalesTitle => 'Sales this month';

  @override
  String adminSalesTotal(String amount) {
    return 'Total $amount KRW';
  }

  @override
  String get adminSalesExplore => 'Regular trips';

  @override
  String get adminSalesFlag => 'Flag holds';

  @override
  String get adminSalesDiverPlanned => 'Diver-crafted';

  @override
  String get adminSalesCurated => 'Curated specials';

  @override
  String get adminSalesDiveStar => 'Dive Star';

  @override
  String get adminSalesHotSpot => 'Hot spots';

  @override
  String get adminSalesNextDeparture => 'Last call';

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
      'Look up members and set Silver, Gold, Diamond, or Platinum grade.';

  @override
  String get adminMembersSearch => 'Search name, username, email, or shop';

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
  String get memberGradeSilver => 'Silver member';

  @override
  String get memberGradeGold => 'Gold member';

  @override
  String get memberGradeDiamond => 'Diamond member';

  @override
  String get memberGradePlatinum => 'Platinum member';

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
  String get adminReject => 'Return';

  @override
  String get adminNoPending => 'No pending certificate requests.';

  @override
  String get adminShopsTitle => 'Partners';

  @override
  String get adminPartnersGradeHint =>
      'Dive Star grades are set when an admin confirms an audit (form scores and gates). Manual grade edit is still available.';

  @override
  String get adminShopsSubtitle =>
      'Monitor operation ratings, star grades, and plaque shipping.';

  @override
  String get adminProductsTitle => 'Travel product registration';

  @override
  String get adminProductsSubtitle =>
      'New products appear on Explore by newest first. Home placement is chosen in Home curation.';

  @override
  String get adminProductsTab => 'Products';

  @override
  String get adminSameBoatTab => 'Same-boat monitor';

  @override
  String get adminSameBoatBriefTab => 'Same-boat brief';

  @override
  String get seatBriefToday => 'Today';

  @override
  String get seatBriefSeven => '7 days';

  @override
  String get seatBriefThirty => '30 days';

  @override
  String get seatBriefYear => 'This year';

  @override
  String get seatBriefCustom => 'Custom';

  @override
  String get seatBriefCompare => 'Compare with the previous period';

  @override
  String get seatBriefFunnelTitle => 'Open to paid';

  @override
  String get seatBriefOpens => 'Open seats';

  @override
  String get seatBriefViews => 'Views';

  @override
  String get seatBriefFlags => 'Flags';

  @override
  String get seatBriefPays => 'Paid';

  @override
  String seatBriefViewsPerOpen(String count) {
    return 'Open → view, $count per seat';
  }

  @override
  String seatBriefConclusionPrice(String who, int views, int flags, int pays) {
    return '$who: $views views · $flags flags · $pays paid. Price looks like the blocker';
  }

  @override
  String seatBriefConclusionSelling(
    String who,
    int views,
    int flags,
    int pays,
  ) {
    return '$who: $views views · $flags flags · $pays paid. This one is selling';
  }

  @override
  String seatBriefConclusionQuiet(String who, int views, int flags, int pays) {
    return '$who: $views views · $flags flags · $pays paid. Still quiet';
  }

  @override
  String get seatBriefConclusionWait => 'More records will make this clearer';

  @override
  String get seatBriefScoreTitle => 'Seat scorecard';

  @override
  String get seatBriefScoreHint => 'By region and product';

  @override
  String get seatBriefScoreRegion => 'Region';

  @override
  String get seatBriefScoreProduct => 'Product';

  @override
  String seatBriefScoreCounts(int views, int flags, int pays) {
    return '$views views  $flags flags  $pays paid';
  }

  @override
  String seatBriefScoreFill(int percent) {
    return 'Filled $percent%';
  }

  @override
  String get seatBriefBadgeSelling => 'Selling';

  @override
  String get seatBriefBadgeViews => 'Views only';

  @override
  String get seatBriefBadgeQuiet => 'Quiet';

  @override
  String get seatBriefBadgeOrdinary => 'Steady';

  @override
  String seatBriefFlagRate(int percent) {
    return 'View → flag $percent%';
  }

  @override
  String seatBriefPayRate(int percent) {
    return 'Flag → paid $percent%';
  }

  @override
  String get seatBriefBeforeRecording =>
      'Before recording started, counts come from bookings';

  @override
  String get seatBriefMissedTitle => 'Missed demand';

  @override
  String get seatBriefMissedHint => 'Zero-result searches';

  @override
  String get seatBriefMissedTop => 'Searched often, nothing open';

  @override
  String seatBriefMissedCount(int count) {
    return '$count times';
  }

  @override
  String get seatBriefMissedWall => 'What was in the way';

  @override
  String get seatBriefMissedWallHint =>
      'How often dropping one condition opened results';

  @override
  String get seatBriefMissedEmpty => 'No records yet';

  @override
  String get partnerMeetingOpen => 'Create a meeting report';

  @override
  String get partnerMeetingTitle => 'Partner meeting report';

  @override
  String get partnerMeetingHint =>
      'Pick the conditions and the report is filled in';

  @override
  String get partnerMeetingPartner => 'Partner';

  @override
  String get partnerMeetingScope => 'Product and region';

  @override
  String partnerMeetingScopeAll(int count) {
    return 'All ($count products)';
  }

  @override
  String partnerMeetingScopeRegion(String name, int count) {
    return 'All of $name ($count products)';
  }

  @override
  String get partnerMeetingPreview => 'Preview report';

  @override
  String get partnerMeetingPreviewTitle => 'Preview';

  @override
  String get partnerMeetingPreviewHint =>
      'A4, 1–2 pages · partner meeting report';

  @override
  String partnerMeetingPaperKicker(String shop) {
    return 'Dive Travel × $shop · meeting notes';
  }

  @override
  String get partnerMeetingPaperTitle => 'Same-boat open seat report';

  @override
  String get partnerMeetingCompareNote => 'Versus the previous period';

  @override
  String get partnerMeetingConclusion => 'One-line conclusion';

  @override
  String get partnerMeetingConclusionHint => 'The one thing that mattered';

  @override
  String get partnerMeetingFunnel => 'How it sold';

  @override
  String get partnerMeetingFunnelHint => 'Funnel';

  @override
  String get partnerMeetingScoreHint => 'This partner\'s seats only';

  @override
  String get partnerMeetingDemandHint =>
      'Searches in this region that found nothing';

  @override
  String get partnerMeetingProposals => 'Seats to open together';

  @override
  String get partnerMeetingProposalsHint =>
      'Price, party, and dates from demand';

  @override
  String get partnerMeetingOpens => 'Open';

  @override
  String get partnerMeetingPrint => 'Print / PDF';

  @override
  String get partnerMeetingSave => 'Save';

  @override
  String get partnerMeetingSend => 'Send';

  @override
  String get partnerMeetingLock =>
      'Other partners\' names and numbers are left out. Member names and contacts are never included';

  @override
  String get partnerMeetingNoShop => 'No partner shop to choose';

  @override
  String get partnerMeetingArchive => 'Saved reports';

  @override
  String get partnerMeetingArchiveEmpty => 'No saved reports yet';

  @override
  String get partnerMeetingSaved => 'Saved';

  @override
  String get partnerMeetingAgain => 'Build again with the same conditions';

  @override
  String get partnerMeetingUnsend => 'Cancel send';

  @override
  String get partnerMeetingSent => 'Sent';

  @override
  String get partnerMeetingUnsent => 'Send cancelled';

  @override
  String get partnerMeetingDraft => 'Not sent';

  @override
  String get partnerMeetingSentBadge => 'Sent';

  @override
  String get partnerMeetingInbox => 'Received reports';

  @override
  String partnerMeetingInboxNew(int count) {
    return '$count new';
  }

  @override
  String get partnerMeetingInboxEmpty => 'No reports yet';

  @override
  String get partnerMeetingCopyLink => 'Copy link';

  @override
  String get partnerMeetingLinkCopied => 'Link copied.';

  @override
  String get partnerMeetingDenied => 'You can\'t view this report';

  @override
  String partnerMeetingPrevious(int opens, int views, int flags, int pays) {
    return 'Previous period: open $opens · views $views · flags $flags · paid $pays';
  }

  @override
  String get adminSameBoatTitle => 'Same-boat · open seats';

  @override
  String get adminSameBoatHint =>
      'Only seats opened by product registrants. Flag planting is not done here.';

  @override
  String get adminSameBoatApproveHint =>
      'Approving a leftover-seat request publishes it to Same-boat. A planted flag locks the seat until the pay deadline.';

  @override
  String get adminSameBoatPendingQueue => 'Pending leftover seats';

  @override
  String get adminSameBoatPendingEmpty => 'No leftover-seat requests waiting.';

  @override
  String get adminSameBoatLiveTitle => 'Live on Same-boat';

  @override
  String get adminSameBoatApprove => 'Approve · publish';

  @override
  String get adminSameBoatReject => 'Reject';

  @override
  String get adminSameBoatPendingBadge => 'Pending';

  @override
  String get adminSameBoatLiveBadge => 'Live on board';

  @override
  String get adminSameBoatRejectedBadge => 'Rejected';

  @override
  String get adminSameBoatClosedBadge => 'Closed';

  @override
  String get adminSameBoatEmpty => 'No products with open leftover seats.';

  @override
  String get adminSameBoatZeroBookings => '0 bookings';

  @override
  String adminSameBoatZeroBookingsForDays(int days) {
    return 'Open $days days with 0 bookings';
  }

  @override
  String get adminSameBoatHide => 'Hide';

  @override
  String get adminSameBoatReopen => 'Reopen';

  @override
  String get adminSameBoatHiddenTitle => 'Hidden seats';

  @override
  String get adminSameBoatHiddenEmpty => 'No hidden leftover seats.';

  @override
  String get sameBoatSeatsTitle => 'Open leftover seats';

  @override
  String get sameBoatApplyTitle => 'Apply to Same-boat';

  @override
  String get sameBoatAskCreateSeats => 'Create leftover seats on this trip?';

  @override
  String get sameBoatAskCreateSeatsYes => 'Create';

  @override
  String get sameBoatAskCreateSeatsNo => 'Cancel';

  @override
  String get sameBoatHubSearchHint => 'Search product name';

  @override
  String get sameBoatSeatsHint =>
      'Open seats on the base package and individual SKUs, set departure and flag deadline, then request admin approval.';

  @override
  String get sameBoatSeatsHubHint =>
      'Pick a product, set seat count, departure, and flag deadline, then apply to Same-boat.';

  @override
  String get sameBoatSeatsNoProducts =>
      'No approved products to open seats on yet. You can open leftover seats after an admin approves the product.';

  @override
  String get sameBoatHubAwaitingPublishTitle => 'Awaiting product approval';

  @override
  String get sameBoatHubAwaitingPublishHint =>
      'These products are not public yet. Seat apply is available only after approval.';

  @override
  String get sameBoatHubAwaitingPublishEmpty =>
      'No products waiting for admin approval.';

  @override
  String get partnerProductListEmpty =>
      'No products yet. Register one to see it here as pending approval.';

  @override
  String get shopStatRefreshFailed =>
      'Saved, but the product list could not refresh. Pull to refresh or reopen this screen.';

  @override
  String get sameBoatSeatsSubmit => 'Request approval';

  @override
  String get sameBoatSeatsPublish => 'Publish to Same-boat';

  @override
  String get sameBoatSeatsSubmitted => 'Leftover-seat request sent.';

  @override
  String get creatorOpenSeatsButton => 'Open seats';

  @override
  String get creatorOpenSeatsSnack =>
      'Seats are open. They show on Same-boat right away.';

  @override
  String get sameBoatSeatsPublished => 'Leftover seats published to Same-boat.';

  @override
  String get sameBoatSeatsEdit => 'Edit seats';

  @override
  String get sameBoatSeatsWaiting => 'Awaiting approval';

  @override
  String get sameBoatSeatsAlreadyPending =>
      'A request is already awaiting approval.';

  @override
  String get sameBoatSeatsAlreadyLive =>
      'This product is already on Same-boat.';

  @override
  String get sameBoatApproveIncomplete =>
      'Cannot approve: seat or departure fields are incomplete.';

  @override
  String get sameBoatHubApprove => 'Approve';

  @override
  String get sameBoatHubOpenSeats => 'Open seats';

  @override
  String get partnerSameBoatRequestsTitle => 'My Same-boat requests';

  @override
  String get partnerSameBoatRequestsEmpty => 'No seat requests yet.';

  @override
  String get adminSameBoatApplyTab => 'Open seats';

  @override
  String get adminSameBoatApplyHint =>
      'Pick a public product, open leftover seats, and publish straight to Same-boat.';

  @override
  String get partnerSectionShopProducts => 'Shop · products';

  @override
  String get partnerSectionSameBoat => 'Same-boat apply';

  @override
  String get partnerSectionOps => 'Bookings · settlement';

  @override
  String get partnerSameBoatApplyHint =>
      'Filter your products, set seats and dates, then apply to Same-boat.';

  @override
  String get sameBoatIndividualSeats => 'Individual SKU seats';

  @override
  String get sameBoatHoldPriorityHint =>
      'A diver’s flag locks seats until the sooner of this flag deadline and 24 hours after planting. Unpaid holds reopen when that time passes.';

  @override
  String get workbenchFlagDeadlineRequired => 'Set a flag deadline.';

  @override
  String communityFlagPayBy(String deadline) {
    return 'Pay by: $deadline';
  }

  @override
  String get communityFlagPayByShortened =>
      'Shorter because the boat flag deadline is sooner.';

  @override
  String get checkoutFlagPayBy => 'Pay by';

  @override
  String get adminProductSourceAll => 'All';

  @override
  String get adminProductSourcePartner => 'Partners';

  @override
  String get adminProductSourceDiy => 'DIY trips';

  @override
  String get adminProductSourceSpecial => 'Curated specials';

  @override
  String get adminProductSourceUnknown => 'Unclassified';

  @override
  String adminProductFilterShop(String name) {
    return 'Shop filter · $name';
  }

  @override
  String get adminProductClearShopFilter => 'Clear filter';

  @override
  String get adminOpenSeatsBadge => 'Open seats';

  @override
  String get adminInternalScore => 'Internal score';

  @override
  String get adminInternalScoreHint => '0–100';

  @override
  String get adminInternalScoreEdit => 'Edit internal score';

  @override
  String get adminInternalScoreSaved => 'Internal score saved.';

  @override
  String get adminDiveStarGrade => 'Dive Star grade';

  @override
  String get adminDiveStarGradeHint => '0–3 (0 = none)';

  @override
  String get adminDiveStarReviewedAt => 'Review date';

  @override
  String get adminDiveStarExpiresAt => 'Expires';

  @override
  String get adminDiveStarGradeEdit => 'Edit Dive Star grade';

  @override
  String get adminDiveStarGradeSaved => 'Dive Star grade saved.';

  @override
  String get adminDiveStarAssessmentMenu => 'Dive Star audit';

  @override
  String get adminDiveStarAssessmentTitle => 'Dive Star audit';

  @override
  String get adminDiveStarAssessmentHint =>
      'Saving computes total and candidate grade only. The guest-facing stars change after you tap Confirm grade.';

  @override
  String get adminDiveStarAssessmentFormSection => 'New audit';

  @override
  String get adminDiveStarAssessmentType => 'Audit type';

  @override
  String get adminDiveStarTypeOnsite => 'On-site';

  @override
  String get adminDiveStarTypeMystery => 'Mystery';

  @override
  String get adminDiveStarTypeDocument => 'Document';

  @override
  String get adminDiveStarTrialMenu => 'v2 trial audit';

  @override
  String get adminDiveStarTrialTitle => 'Dive Star audit (v2 trial)';

  @override
  String get adminDiveStarTrialHint =>
      'Preview only with a draft v2 form. Saving comes in phase 3. The active form stays v1 for now.';

  @override
  String get adminDiveStarTrialNoDraft =>
      'No draft v2 form with items found. Import a form first.';

  @override
  String get adminDiveStarTrialSaveLocked =>
      'Saving is disabled in trial mode. Phase 3 will persist answers.';

  @override
  String get adminDiveStarFillMaxScores => 'Fill all items with max scores';

  @override
  String get adminDiveStarGatesSection =>
      'Required gates (any fail blocks stars)';

  @override
  String adminDiveStarCountryGatesSection(int max) {
    return 'Country gates (up to $max)';
  }

  @override
  String get adminDiveStarCountryGateName => 'Gate name';

  @override
  String get adminDiveStarCountryGateCriteria => 'Criteria';

  @override
  String get adminDiveStarCountryGateAdd => 'Add country gate';

  @override
  String get adminDiveStarAreaApplicable => 'Applies';

  @override
  String get adminDiveStarAreaNotApplicable => 'N/A';

  @override
  String get adminDiveStarAreaNaBlocked =>
      'The safety area cannot be marked N/A.';

  @override
  String get adminDiveStarItemsSection => 'Item scores';

  @override
  String adminDiveStarItemScore(int max) {
    return 'Score (0–$max)';
  }

  @override
  String get adminDiveStarItemGuidance => 'Criteria, evidence, basis';

  @override
  String get adminDiveStarItemCriteria => 'Criteria';

  @override
  String get adminDiveStarItemEvidence => 'Evidence';

  @override
  String get adminDiveStarItemBasis => 'Basis';

  @override
  String adminDiveStarAreaProgress(int filled, int total) {
    return 'Filled $filled/$total';
  }

  @override
  String get adminDiveStarItemUnscored => 'Not scored';

  @override
  String get adminDiveStarMysteryVisits => 'Mystery visits (0–20)';

  @override
  String get adminDiveStarAuditor1 => 'Auditor 1';

  @override
  String get adminDiveStarAuditor2 => 'Auditor 2';

  @override
  String adminDiveStarAreaRateLine(String area, int earned, int max, int pct) {
    return '$area: $earned/$max ($pct%)';
  }

  @override
  String get adminDiveStarReasonGateFailed =>
      'Gates failed — candidate grade 0';

  @override
  String get adminDiveStarReasonBelowStar1 => 'Below 1-star score';

  @override
  String get adminDiveStarReasonStar1 => 'Meets 1-star criteria';

  @override
  String get adminDiveStarReasonStar2 => 'Meets 2-star criteria';

  @override
  String get adminDiveStarReasonStar3 => 'Meets 3-star criteria';

  @override
  String get adminDiveStarReasonSafety =>
      'Score OK but safety area ratio too low';

  @override
  String get adminDiveStarReasonAreaRatio => 'Area ratios below 3-star minimum';

  @override
  String get adminDiveStarReasonMystery =>
      'Mystery visits below 3-star minimum';

  @override
  String adminDiveStarReasonOther(String code) {
    return 'Grade reason: $code';
  }

  @override
  String get adminDiveStarGatePass => 'Pass';

  @override
  String get adminDiveStarGateFail => 'Fail';

  @override
  String get adminDiveStarAreasSection => 'Area scores';

  @override
  String get adminDiveStarAreaComment => 'Comment (optional)';

  @override
  String get adminDiveStarAssessmentSave => 'Save audit';

  @override
  String get adminDiveStarAssessmentSaved =>
      'Audit saved. Shop grade is unchanged until confirmed.';

  @override
  String get adminDiveStarAssessmentRetry => 'Retry';

  @override
  String adminDiveStarPreview(int score, int grade) {
    return 'Total $score · candidate $grade★';
  }

  @override
  String get adminDiveStarGatesOk => 'All gates passed';

  @override
  String get adminDiveStarGatesBlocked => 'Gate failed — candidate grade 0';

  @override
  String get adminDiveStarConfirmTitle => 'Confirm grade';

  @override
  String adminDiveStarConfirmBody(int grade, int score) {
    return 'Apply candidate $grade★ (total $score) to this shop?';
  }

  @override
  String get adminDiveStarConfirmAction => 'Confirm grade';

  @override
  String get adminDiveStarConfirmed => 'Dive Star grade confirmed on the shop.';

  @override
  String get adminDiveStarAlreadyConfirmed => 'Already confirmed';

  @override
  String get adminDiveStarHistorySection => 'Audit history';

  @override
  String get adminDiveStarHistoryEmpty => 'No audits saved yet.';

  @override
  String adminDiveStarHistoryLine(String date, int score, int grade) {
    return '$date · $score pts · candidate $grade★';
  }

  @override
  String get adminDiveStarStatusConfirmed => 'Confirmed';

  @override
  String get adminDiveStarStatusDraft => 'Draft';

  @override
  String get adminDiveStarModeNew => 'New audit';

  @override
  String get adminDiveStarModeEditing => 'Editing · draft';

  @override
  String get adminDiveStarModeReadonly => 'Confirmed · read-only';

  @override
  String get adminDiveStarStartNew => 'Start new audit';

  @override
  String get adminDiveStarCopyAsNew => 'Copy this record into a new audit';

  @override
  String get adminDiveStarCopySameDateTitle => 'Review date';

  @override
  String get adminDiveStarCopySameDateBody =>
      'The re-audit date matches the original. Save anyway?';

  @override
  String get adminDiveStarDeleteDraft => 'Delete draft';

  @override
  String get adminDiveStarDeleteConfirmTitle => 'Delete this audit?';

  @override
  String get adminDiveStarDeleteConfirmBody =>
      'This draft will be deleted. This cannot be undone.';

  @override
  String get adminDiveStarDeleted => 'Audit deleted.';

  @override
  String get adminDiveStarAssessmentUpdated => 'Draft overwritten and saved.';

  @override
  String get adminDiveStarFormImportMenu => 'Import audit form';

  @override
  String get adminDiveStarFormImportTitle => 'Import Dive Star form';

  @override
  String get adminDiveStarFormImportHint =>
      'Paste form JSON to save as a draft (inactive). Use Activate when ready to switch the live form.';

  @override
  String get adminDiveStarFormImportPasteLabel => 'Form JSON';

  @override
  String get adminDiveStarFormImportAction => 'Validate and save draft';

  @override
  String get adminDiveStarFormImportEmpty => 'Paste the JSON first.';

  @override
  String get adminDiveStarFormImportInvalidJson => 'JSON could not be read.';

  @override
  String get adminDiveStarFormImportMissingVersion =>
      'version field is required.';

  @override
  String get adminDiveStarFormImportAreaSum =>
      'Area max points must add up to 100.';

  @override
  String get adminDiveStarFormImportItemSum =>
      'Item max points must match each area max.';

  @override
  String get adminDiveStarFormImportDuplicateId =>
      'Duplicate id found (area, gate, or item).';

  @override
  String adminDiveStarFormImportInvalid(String code) {
    return 'Import failed: $code';
  }

  @override
  String get adminDiveStarFormImportExists =>
      'That version already exists. Import is blocked.';

  @override
  String adminDiveStarFormImportSaved(String version) {
    return 'Saved $version as draft (not active).';
  }

  @override
  String get adminDiveStarFormListSection => 'Saved forms';

  @override
  String get adminDiveStarFormListEmpty =>
      'No forms in Firestore yet (v1 is seeded when you open an audit).';

  @override
  String adminDiveStarFormListLoadError(String detail) {
    return 'Could not load the form list. You can still paste JSON below. ($detail)';
  }

  @override
  String get adminDiveStarFormStatusActive => 'In use';

  @override
  String get adminDiveStarFormStatusDraft => 'Draft';

  @override
  String get adminDiveStarFormActivate => 'Make this form active';

  @override
  String get adminDiveStarFormActivateLockedHint =>
      'Available after phase 3. Active form stays v1 for now.';

  @override
  String adminDiveStarFormActivated(String version) {
    return '$version is now the active form.';
  }

  @override
  String adminDiveStarFormMissingForHistory(String version) {
    return 'Form $version for this record was not found; opening with the active form.';
  }

  @override
  String get adminDocsTitle => 'Documents';

  @override
  String get adminTrialDataTab => 'Trial data · remove before launch';

  @override
  String get adminTrialDataTitle => 'Trial data inspect & clean';

  @override
  String get adminTrialPrelaunchBanner =>
      'Pre-launch cleanup tool — not production data. Back up first.';

  @override
  String get adminTrialLimitsBody =>
      'Limits: Firebase Auth users cannot be deleted in-app (Console → Authentication → Users). Deleting only the Firestore users doc may recreate an empty profile on next login — delete Auth after Firestore for trial accounts. R2/Storage files may remain. partner_contracts cannot be deleted in-app (rules) — use Console. Subcollections are not auto-deleted with parents.';

  @override
  String get adminTrialRefresh => 'Refresh counts';

  @override
  String get adminTrialCountsTitle => 'Counts by path';

  @override
  String get adminTrialUnavailable => 'Not available in app';

  @override
  String get adminTrialCountError => 'Count failed';

  @override
  String get adminTrialFlagProtected => 'Protected';

  @override
  String get adminTrialFlagDeletable => 'Deletable';

  @override
  String adminTrialJejuProtected(String name, String id) {
    return 'Protected shop: $name · id=$id (products, bookings, reviews, vault, owners)';
  }

  @override
  String get adminTrialJejuMissing =>
      '「제주 오렌지」 shop not found. Trial deletes have no shop protection — be careful.';

  @override
  String get adminTrialJejuAmbiguous =>
      'Multiple shops look like 「제주 오렌지」. Review the list, clean in Console, reopen. Deletes are locked.';

  @override
  String get adminTrialDeleteTitle => 'Selective delete';

  @override
  String get adminTrialDeleteHint =>
      'Protected rows cannot be checked. Counts are re-read before run; type the confirm phrase exactly.';

  @override
  String get adminTrialBackupCheck => 'I backed up (or exported) first';

  @override
  String get adminTrialConfirmLabel => 'Type confirm phrase';

  @override
  String get adminTrialConfirmMismatch =>
      'Confirm phrase must be exactly 「삭제합니다」.';

  @override
  String get adminTrialBackupRequired => 'Check the backup acknowledgement.';

  @override
  String get adminTrialRunDelete => 'Run selected deletes';

  @override
  String adminTrialResult(int ok, int fail) {
    return 'Result · ok $ok · fail $fail';
  }

  @override
  String get adminTrialSelOutbox => 'Partner email outbox';

  @override
  String get adminTrialSelLoi => 'LOI applications';

  @override
  String get adminTrialSelPosts => 'Community posts & comments';

  @override
  String get adminTrialSelReviews => 'Reviews (except Jeju Orange)';

  @override
  String get adminTrialSelUserBookings => 'User booking copies';

  @override
  String get adminTrialSelUserLogs => 'User dive logs';

  @override
  String get adminTrialSelAssessments => 'Unconfirmed Dive Star assessments';

  @override
  String get adminTrialSelShopBookings => 'Trial shop bookings';

  @override
  String get adminTrialSelProducts => 'Clear trial shop products arrays';

  @override
  String get adminTrialSelShops =>
      'Delete trial shops (demote owners → children → shop)';

  @override
  String get adminTrialSelUsers =>
      'Trial user docs (except owner/self/Jeju Orange owners)';

  @override
  String get adminDocsHint =>
      'Store public partner guides and forms for sharing. Do not put internal files here.';

  @override
  String get adminDocsListSection => 'Documents';

  @override
  String get adminDocsEmpty => 'No documents yet.';

  @override
  String get adminDocsShareHistory => 'Send history';

  @override
  String get adminDocsShareHistoryEmpty => 'No sends recorded yet.';

  @override
  String get adminDocFilterAll => 'All';

  @override
  String get adminDocCatCriteria => 'Criteria';

  @override
  String get adminDocCatPartnerGuide => 'Partner guide';

  @override
  String get adminDocCatApplication => 'Application';

  @override
  String get adminDocCatAuditor => 'Auditor';

  @override
  String get adminDocCatTraining => 'Training';

  @override
  String get adminDocCatContract => 'Contract';

  @override
  String get adminDocStatusDraft => 'Draft';

  @override
  String get adminDocStatusApproved => 'Approved';

  @override
  String get adminDocAudiencePublic => 'Public';

  @override
  String get adminDocAudienceInternal => 'Internal';

  @override
  String get adminDocActionPrint => 'Print';

  @override
  String get adminDocActionDownload => 'Download';

  @override
  String get adminDocActionShare => 'Share';

  @override
  String get adminDocActionEmail => 'Email';

  @override
  String get adminDocActionCopyLink => 'Copy link';

  @override
  String get adminDocActionQr => 'QR code';

  @override
  String get adminDocActionFaxPrint => 'Fax-ready print';

  @override
  String get adminDocSendToPartner => 'Send to partner';

  @override
  String get adminDocPickPartner => 'Choose partner (shop)';

  @override
  String adminDocRecommendedChannels(String channels) {
    return 'Recommended: $channels';
  }

  @override
  String get adminDocDraftWarnTitle => 'Draft document';

  @override
  String get adminDocDraftWarnBody =>
      'This is a draft. Prefer the approved version. Send anyway?';

  @override
  String get adminDocDraftWarnContinue => 'Send anyway';

  @override
  String get adminDocShareRecorded => 'Send recorded.';

  @override
  String get adminDocShareFallbackCopy =>
      'Share is limited here; copied text and link instead.';

  @override
  String get adminDocEmailAttachHint =>
      '(To attach the PDF, use the Share button.)';

  @override
  String get adminDocLinkCopied => 'Link copied.';

  @override
  String get adminDocQrTitle => 'QR code';

  @override
  String get adminDocPdfMissing => 'PDF file is not available yet.';

  @override
  String adminDocPdfMissingDetail(String path) {
    return 'Add $path to the project to enable preview.';
  }

  @override
  String get adminDocFaxToBlank => '(recipient blank)';

  @override
  String get adminDocMarkApproved => 'Mark approved';

  @override
  String get adminDocMarkDraft => 'Revert to draft';

  @override
  String get adminDocConfigTitle => 'Channels & templates';

  @override
  String get adminDocConfigChannelsHint =>
      'Comma-separated channels per country (e.g. kakao, email, share).';

  @override
  String get adminDocConfigChannelsKr => 'Korea (KR)';

  @override
  String get adminDocConfigChannelsJp => 'Japan (JP)';

  @override
  String get adminDocConfigChannelsTh => 'Thailand (TH)';

  @override
  String get adminDocConfigChannelsId => 'Indonesia (ID)';

  @override
  String get adminDocConfigChannelsDefault => 'Other (DEFAULT)';

  @override
  String get adminDocConfigTemplatesHint =>
      'Message templates. Placeholders: partner_name, link (and Korean equivalents).';

  @override
  String get adminDocConfigKoSubject => 'Korean subject';

  @override
  String get adminDocConfigKoBody => 'Korean body';

  @override
  String get adminDocConfigEnSubject => 'English subject';

  @override
  String get adminDocConfigEnBody => 'English body';

  @override
  String get adminDocConfigPlaceholders =>
      'Placeholder examples: partner_name, link (wrap in curly braces in the template text).';

  @override
  String get adminDocConfigSaved => 'Channel and template settings saved.';

  @override
  String get partnerDocsSection => 'Dive Star materials';

  @override
  String get partnerDocsTitle => 'Guides & forms';

  @override
  String get partnerDocsHint =>
      'View and print approved public guides and application forms.';

  @override
  String get partnerDocsEmpty =>
      'No approved documents yet. Please wait for admin approval.';

  @override
  String get partnerLoiTitle => 'Letter of intent';

  @override
  String get partnerLoiHint =>
      'Fill in your shop details and sign with your finger. We will generate a PDF and notify Dive Travel.';

  @override
  String get partnerLoiCompany => 'Company / shop name';

  @override
  String get partnerLoiContact => 'Contact name';

  @override
  String get partnerLoiEmail => 'Email';

  @override
  String get partnerLoiPhone => 'Phone';

  @override
  String get partnerLoiCountry => 'Country';

  @override
  String get partnerLoiNotes => 'Notes (optional)';

  @override
  String get partnerLoiSignature => 'Signature (draw below)';

  @override
  String get partnerLoiClearSignature => 'Clear signature';

  @override
  String get partnerLoiSubmit => 'Submit letter of intent';

  @override
  String get partnerLoiMissingFields =>
      'Enter company, contact, and a signature.';

  @override
  String get partnerLoiSubmitted => 'Letter of intent submitted.';

  @override
  String get partnerLoiOpenForm => 'Write letter of intent';

  @override
  String get partnerLoiOpenFormHint =>
      'In-app form with touch signature and PDF.';

  @override
  String get partnerLoiStatusSection => 'My applications';

  @override
  String get partnerLoiStatusEmpty => 'No letter of intent submitted yet.';

  @override
  String get pipelineGuideSent => 'Guide sent';

  @override
  String get pipelineLoiReceived => 'LOI received';

  @override
  String get pipelineDocsSubmitted => 'Docs submitted';

  @override
  String get pipelineUnderReview => 'Under review';

  @override
  String get pipelineResultNotified => 'Result notified';

  @override
  String pipelineReminderSubject(String shopName) {
    return 'Dive Star follow-up: $shopName';
  }

  @override
  String pipelineReminderBody(String shopName, String contactName) {
    return 'Hello $contactName,\n\nThis is a reminder about the Dive Star application for $shopName. Please reply with any remaining documents or questions.\n\nThank you,\nDive Travel';
  }

  @override
  String get pipelineReminderQueued => 'Reminder opened in email and queued.';

  @override
  String get adminAppsTitle => 'Dive Star applications';

  @override
  String get adminAppsHint =>
      'Track letters of intent and advance the partner pipeline. Email is queued here; use mailto until Cloud Functions send mail.';

  @override
  String get adminAppsReminderSection => 'Reminders due';

  @override
  String get adminAppsEmailServerNote =>
      'Server email is not connected yet. Reminder opens your mail app and records a queue entry.';

  @override
  String get adminAppsReminderEmpty => 'No reminders due.';

  @override
  String get adminAppsListSection => 'Applications';

  @override
  String get adminAppsEmpty => 'No applications yet.';

  @override
  String get adminAppsSendReminder => 'Send reminder';

  @override
  String adminAppsAdvanceTo(String status) {
    return 'Advance to $status';
  }

  @override
  String get adminAppsOutboxSection => 'Email outbox';

  @override
  String get adminAppsOutboxEmpty => 'Outbox is empty.';

  @override
  String get adminAppsOpenList => 'Applications & pipeline';

  @override
  String adminAppsReminderDue(String date) {
    return 'Due $date';
  }

  @override
  String get adminViewShopProducts => 'View products';

  @override
  String adminSameBoatRemaining(int count) {
    return '$count left';
  }

  @override
  String adminSameBoatFlagged(int count) {
    return '$count flagged';
  }

  @override
  String get adminHomeCurationTab => 'Home curation';

  @override
  String get adminHomeCurationTitle => 'Home shelf curation';

  @override
  String get adminHomeCurationSubtitle =>
      'Pick approved products for each home shelf — up to 10 each.';

  @override
  String get adminHomeCurationPool => 'Unplaced (Explore only)';

  @override
  String get adminHomeCurationOnShelf => 'On this shelf';

  @override
  String adminHomeCurationCount(int count, int limit) {
    return '$count/$limit';
  }

  @override
  String get adminHomeCurationSend => 'Send to shelf';

  @override
  String get adminHomeCurationRemove => 'Remove from home';

  @override
  String get adminHomeCurationFull =>
      'This shelf already has 10. Remove one before adding.';

  @override
  String get adminHomeCurationEmptyPool => 'No unplaced public products.';

  @override
  String get adminHomeCurationEmptyShelf => 'Nothing on this shelf yet.';

  @override
  String get adminHomeCurationMoved => 'Home shelf updated.';

  @override
  String get adminHomeCurationCleared => 'Removed from home.';

  @override
  String get adminProductPendingQueue => 'Pending approval';

  @override
  String get adminProductPendingEmpty => 'No products waiting for approval.';

  @override
  String get adminAllProducts => 'Registered products';

  @override
  String get adminProductSpecial =>
      'Publish on the home shelf as a planned special';

  @override
  String get adminProductApproved => 'Product approved and published.';

  @override
  String get adminPriceRevisionChip => 'Price change request';

  @override
  String adminPriceRevisionPendingOptions(String names) {
    return 'New options pending approval: $names';
  }

  @override
  String get adminPriceRevisionApproved => 'Price changes approved and live.';

  @override
  String get adminPriceRevisionRejected => 'Price change request returned.';

  @override
  String get adminProductApproveNeedsPrice =>
      'Only products with a diver price can be approved.';

  @override
  String get adminProductApproveOverCap =>
      'Cannot approve: a unit price is over 100 million won.';

  @override
  String get adminProductRejectNeedsNote => 'Please enter a rejection reason.';

  @override
  String get adminProductRejected => 'Product registration returned.';

  @override
  String get partnerRejectReasonBanner => 'Admin return reason';

  @override
  String get partnerRejectReasonExpand => 'Show more';

  @override
  String get partnerRejectReasonCollapse => 'Show less';

  @override
  String get partnerResubmitNoteTitle => 'What did you fix?';

  @override
  String get partnerResubmitNoteHint => 'e.g. Updated cover photo and price.';

  @override
  String get partnerResubmitNoteHelper => '5–200 characters';

  @override
  String partnerResubmitCount(int count) {
    return 'Resubmit #$count';
  }

  @override
  String get partnerResubmitUnchanged =>
      'Nothing changed since the return. Fix the noted issues, then request again.';

  @override
  String get partnerResubmitSoftWarnTitle => 'Related items are unchanged';

  @override
  String partnerResubmitSoftWarnBody(String sections) {
    return 'The return noted $sections, and those items still look the same. Request approval anyway?';
  }

  @override
  String get partnerResubmitSoftWarnFix => 'Keep editing';

  @override
  String get partnerResubmitSoftWarnContinue => 'Request anyway';

  @override
  String get adminProductRejectTagsHint => 'Select related items (optional)';

  @override
  String get rejectTagPhotos => 'Photos';

  @override
  String get rejectTagPrice => 'Price';

  @override
  String get rejectTagOptions => 'Options';

  @override
  String get rejectTagCopy => 'Name & intro';

  @override
  String get rejectTagSchedule => 'Schedule & includes';

  @override
  String get rejectTagCancel => 'Cancellation';

  @override
  String get rejectTagOther => 'Other';

  @override
  String get adminPendingPreviousReject => 'Previous return';

  @override
  String get adminPendingPartnerNote => 'Partner note';

  @override
  String get adminPendingChangesTitle => 'This change';

  @override
  String get adminPendingChangeUnknown => 'Cannot compare';

  @override
  String get adminProductSubmitHint =>
      'Saving sends the product to the approval queue. It stays hidden until approved.';

  @override
  String get adminProductSubmitted => 'Submitted for approval.';

  @override
  String get productFormHeroTitle => 'Register a travel product';

  @override
  String get productFormHeroBody =>
      'Continent → shop → itinerary → package options. Guests see this on home and explore.';

  @override
  String get productFormSectionLocation => 'Location';

  @override
  String get productFormSectionListing => 'Where it appears';

  @override
  String get productFormSectionMedia => 'Cover photo';

  @override
  String get productFormSectionBasics => 'Basics';

  @override
  String get productFormSectionItinerary => 'Schedule & meetup';

  @override
  String get productFormSectionIncludes => 'Includes & excludes';

  @override
  String get productFormSectionCapacity => 'Group & level';

  @override
  String get productFormSectionPricing => 'Pricing';

  @override
  String get productFormSectionOptions => 'Package options';

  @override
  String get productFormContinent => 'Continent';

  @override
  String get productFormContinentHint =>
      'Pick a continent first to filter shops.';

  @override
  String get productFormShopHint => 'Partner resort';

  @override
  String get productFormPickShop => 'Select a shop';

  @override
  String get productFormDirectSelect =>
      'Planned special (resort not in the app)';

  @override
  String get productFormCreatorShop => 'A trip I plan (my own)';

  @override
  String get productFormCreatorResortDone => 'Done';

  @override
  String creatorWizardProgress(int step) {
    return '$step/5';
  }

  @override
  String get creatorWizardBack => 'Back';

  @override
  String get creatorWizardNext => 'Next';

  @override
  String get creatorWizardStepIntro => 'Intro';

  @override
  String get creatorWizardStepSchedule => 'Schedule';

  @override
  String get creatorWizardStepPrice => 'Price';

  @override
  String get creatorWizardStepExtras => 'Sold with the trip';

  @override
  String get creatorWizardStepReview => 'Review';

  @override
  String get creatorWizardReviewHint =>
      'Press request approval to save. After an admin approves it, open leftover seats from My > your captain card to set the date and headcount.';

  @override
  String get creatorWizardSubmitted =>
      'Approval request sent. After it is approved you can open leftover seats from My.';

  @override
  String get creatorWizardSkip => 'Skip';

  @override
  String get creatorWizardAddToTrip => 'Add to the trip';

  @override
  String get creatorWizardBuySeparate => 'Buy separately';

  @override
  String get creatorWizardDetails => 'Details';

  @override
  String get creatorWizardAddCard => 'Add an item';

  @override
  String get creatorWizardOfferName => 'Name';

  @override
  String get creatorWizardRemove => 'Remove';

  @override
  String get creatorWizardDescription => 'Description';

  @override
  String get creatorWizardMissing => 'Still empty';

  @override
  String get creatorWizardNestedAdd => 'Add a nested option';

  @override
  String productFormPleaseEnter(String label, String particle) {
    return 'Please enter $label$particle';
  }

  @override
  String get productFormSubtitle => 'One-line pitch';

  @override
  String get productOfferDetails => 'View details';

  @override
  String get productOfferNights => 'Nights and days';

  @override
  String get productFormSubtitleHint =>
      'e.g. Check dive then 2 tanks, same van';

  @override
  String get productFormDurationHint => 'e.g. 2 nights / half-day morning';

  @override
  String get productFormMeetingPoint => 'Meeting point';

  @override
  String get productFormMeetingHint => 'e.g. Panglao lobby 07:30';

  @override
  String get productFormSchedule => 'Itinerary summary';

  @override
  String get productFormScheduleHint =>
      'Departure, dives, and return in order.';

  @override
  String get productFormIncludes => 'Includes';

  @override
  String get productFormIncludesHint =>
      'Boat, tanks, guide, pickup — one per line';

  @override
  String get productFormExcludes => 'Excludes';

  @override
  String get productFormExcludesHint => 'Gear rental, park fees, etc.';

  @override
  String get productFormDifficulty => 'Required cert / level';

  @override
  String get productFormDifficultyHint => 'e.g. OW+ · beginner–intermediate';

  @override
  String get productFormMinGuests => 'Min guests';

  @override
  String get productFormMaxGuests => 'Max guests';

  @override
  String get productFormCancelNote => 'Cancellation note';

  @override
  String get productFormCancelHint => 'Rules N days before departure';

  @override
  String get productFormOptionsHint =>
      'Add chooseable lines: room type, tanks, gear, transfer.';

  @override
  String get productFormOptionName => 'Option name';

  @override
  String get productFormOptionGroup => 'Group';

  @override
  String get productFormOptionDesc => 'Option details';

  @override
  String get productFormOptionConsumer => 'Guest price';

  @override
  String get productFormOptionPro => 'Pro price';

  @override
  String get productFormAddOption => 'Add option';

  @override
  String get productFormRemoveOption => 'Remove option';

  @override
  String get productFormPhotoHint =>
      'Square (1:1) preferred for cards and detail.';

  @override
  String get productFormSourcePartner => 'Partner resort';

  @override
  String get productFormSourceCurated => 'Curated by us';

  @override
  String get productFormSourceHint =>
      'Partner resorts come from the catalog. Curated lets you type any resort name even before a shop contract.';

  @override
  String get productFormCuratedResort => 'Resort / shop name';

  @override
  String get productFormCuratedResortHint => 'e.g. Bohol private villa dive';

  @override
  String get productFormCuratedLocation => 'Area';

  @override
  String get productFormCuratedLocationHint =>
      'e.g. Panglao, Bohol, Philippines';

  @override
  String get productFormCuratedCountry => 'Country';

  @override
  String get productFormCuratedCountryHint => 'e.g. Philippines';

  @override
  String get productFormCountryOther => 'Other (type it in)';

  @override
  String get productFormCountryNoSea => 'No sea';

  @override
  String get productListingKind => 'Home shelf';

  @override
  String get productListingExploreOnly => 'Unplaced (Explore only)';

  @override
  String get productListingDiveStar => 'Dive Star verified';

  @override
  String get productListingFavorites => 'My real trip';

  @override
  String get productListingPopular => 'Spots heating up';

  @override
  String get productListingNextDeparture => 'Same boat · last call';

  @override
  String get productListingCurated => 'Editor specials';

  @override
  String get productStatusPending => 'Pending';

  @override
  String get partnerProductBadgePending => 'Pending approval';

  @override
  String get partnerProductBadgeDrafting => 'Drafting';

  @override
  String get partnerProductBadgeListed => 'Listed';

  @override
  String get partnerProductBadgeRejected => 'Rejected';

  @override
  String get partnerProductBadgeClosed => 'Closed';

  @override
  String get partnerProductBadgeMissingPrice => 'Price missing';

  @override
  String get partnerProductPublish => 'Publish';

  @override
  String get partnerProductPublishCta => 'Publish';

  @override
  String get partnerProductPublished => 'Product published.';

  @override
  String get partnerFormSoftGuide =>
      'Only required fields are needed to save. Leave the rest blank — ops can help fill them in.';

  @override
  String get partnerFormSectionBasics => 'Basics';

  @override
  String get partnerFormSectionPricing => 'Prices & options';

  @override
  String get partnerFormSectionPublish => 'Publish';

  @override
  String get partnerFormRequiredBadge => 'Required';

  @override
  String get partnerFormPhotoOptionalHint =>
      'If empty, ops can add photos. Max 10.';

  @override
  String get partnerFormPhotoMain => 'Main';

  @override
  String get partnerFormNameHint => 'e.g. Bohol 3D2N package';

  @override
  String get partnerFormBlurbHint => 'One-line pitch customers see';

  @override
  String get partnerFormProductType => 'Product type';

  @override
  String get partnerFormNights => 'Nights';

  @override
  String get partnerFormDays => 'Days';

  @override
  String get partnerFormMeeting => 'Meeting point';

  @override
  String get partnerFormShopInfoRow =>
      'Resort location and amenities are managed in shop info.';

  @override
  String get partnerFormShopInfoCta => 'Shop info';

  @override
  String get partnerFormBasePrice => 'Base price per person';

  @override
  String get partnerFormBasePriceHint => 'Standard diver rate for one person.';

  @override
  String get partnerFormGuestRatesToggle =>
      'Set non-diver / child prices separately';

  @override
  String get partnerFormAddOption => '+ Add option';

  @override
  String get partnerFormAddIndividual => '+ Add individual product';

  @override
  String get partnerFormIndividualOptions => 'Options for this product';

  @override
  String get partnerFormPreviewBadge => 'Goes live on publish';

  @override
  String get partnerFormSameBoatNote =>
      'Open leftover seats after the product is listed. Once open, they appear to guests right away.';

  @override
  String get partnerFormCancelPolicy => 'Cancellation / refund policy';

  @override
  String get partnerPriceSwingTitle => 'Large price change';

  @override
  String get partnerPriceSwingBody =>
      'One or more prices (base, options, non-diver/child, professional) moved by ±30% or more. Apply these changes?';

  @override
  String get partnerPriceSwingConfirm => 'Apply';

  @override
  String get partnerProductsTitle => 'Manage products';

  @override
  String get partnerProductMenuTitle => 'Products';

  @override
  String get partnerProductListTitle => 'Product list';

  @override
  String get partnerProductMenuRegister => 'Register product';

  @override
  String get partnerProductMenuRegisterSub => 'List a new product';

  @override
  String partnerProductMenuRegisterDrafting(int count) {
    return 'List a new product · $count drafting';
  }

  @override
  String get partnerProductMenuList => 'Product list';

  @override
  String get partnerProductMenuListSub => 'Edit or close listings';

  @override
  String partnerProductMenuListListed(int count) {
    return '$count listed · edit or close anytime';
  }

  @override
  String get partnerProductMenuSeats => 'Open seats';

  @override
  String get partnerProductMenuSeatsSub => 'Same-boat · base products only';

  @override
  String partnerProductMenuSeatsOpen(int count) {
    return 'Same-boat · base products only · $count seats open';
  }

  @override
  String get partnerProductMenuFocNote =>
      'Discounts and instructor FOC follow your contract automatically.\nAsk ops if you need changes.';

  @override
  String get partnerProductBadgeBasic => 'Base product';

  @override
  String get partnerProductClose => 'Close';

  @override
  String get partnerProductReopen => 'Reopen';

  @override
  String get partnerProductDiscard => 'Discard';

  @override
  String get partnerProductContinueDraft => 'Continue';

  @override
  String get partnerProductDraftHiddenHint =>
      'Draft products are hidden from guests.';

  @override
  String get partnerProductAddOptionIndividual =>
      '+ Add option or individual item';

  @override
  String get partnerProductListFooter =>
      'Individuals and options live inside one base product. Edit or discard each row here.';

  @override
  String get partnerProductsEmptyH2 =>
      'No products yet. Publish one and guests can see it right away.';

  @override
  String get partnerProductsEmptyCtaH2 => 'Publish your first product';

  @override
  String get partnerProductCloseSeatTitle => 'Close this product?';

  @override
  String partnerProductCloseSeatBody(int count) {
    return '$count open seat(s) will leave the guest board. Existing bookings and in-progress checkouts stay.';
  }

  @override
  String get partnerProductDiscardConfirmTitle => 'Discard this line?';

  @override
  String get partnerProductDiscardConfirmBody =>
      'It will be removed. If it has bookings or holds, it will be closed instead.';

  @override
  String get partnerProductDiscardClosedSnack =>
      'Closed instead of deleted because of bookings or holds.';

  @override
  String get partnerProductOptionClosedLabel => 'Closed';

  @override
  String get partnerOpenSeatsTitle => 'Open seats';

  @override
  String get partnerOpenSeatsEmpty =>
      'No listed base products yet. Publish a product first.';

  @override
  String get partnerOpenSeatsPickHint =>
      'Choose a base product to open on Same-boat.';

  @override
  String get partnerSeatsOpenHint =>
      'Set departure, seats, and flag deadline — guests see it on Same-boat right away.';

  @override
  String get partnerSeatsOpenButton => 'Open seats';

  @override
  String get partnerSeatsOpenedSnack =>
      'Opened. Guests can see it on Same-boat right away.';

  @override
  String get partnerExit => 'Exit';

  @override
  String get partnerProductsGuide =>
      'Saving publishes to Explore and Same-boat right away. Draft products can use temp save.';

  @override
  String get partnerProductFilterAll => 'All';

  @override
  String get partnerProductsEmptyReason => 'No products yet.';

  @override
  String get partnerProductsEmptyNext =>
      'Register and publish a product to see it here.';

  @override
  String get partnerProductsEmptyCta => 'Register your first product';

  @override
  String get partnerProductsFilterEmpty => 'No products match this filter.';

  @override
  String partnerProductPriceLine(String price) {
    return 'Base package · diver $price KRW';
  }

  @override
  String get partnerProductSameBoatPending => 'Same-boat processing';

  @override
  String partnerProductSameBoatLive(int seats, String date) {
    return '$seats seats open · departs $date';
  }

  @override
  String get partnerProductSameBoatRejected => 'Same-boat rejected';

  @override
  String get partnerProductSameBoatNotOpened => 'Not opened yet';

  @override
  String get partnerProductSeatsManage => 'Manage seats';

  @override
  String get partnerProductResubmit => 'Fix and resubmit';

  @override
  String get productStatusApproved => 'Published';

  @override
  String get productStatusRejected => 'Returned';

  @override
  String get productStatusDraft => 'Draft';

  @override
  String get partnerOwnProductsOnly =>
      'Partners can only manage products for their own shop.';

  @override
  String get partnerProductPendingHint =>
      'You can view and edit pending products in this list. Same-boat apply and Explore listing appear after admin approval.';

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
  String get adminShopMonitor => 'Affiliate partner monitor';

  @override
  String get adminPricingTitle => 'Settlement & discounts';

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
  String get partnerTitle => 'Affiliate partner mode';

  @override
  String get partnerSubtitle =>
      'Edit your shop, list tours, and track this month\'s payout.';

  @override
  String get partnerAccessDenied =>
      'This account is not an affiliate partner (Business).';

  @override
  String get partnerHomeShopInfo => 'Shop info';

  @override
  String get partnerHomeMenuSameBoat => 'Same-boat seats';

  @override
  String partnerHomeSameBoatRejectedBanner(int count) {
    return '$count same-boat rejection(s) — please re-apply';
  }

  @override
  String get partnerQuickProducts => 'Products';

  @override
  String get partnerQuickBookings => 'Booking vouchers';

  @override
  String get partnerVouchersTitle => 'Reservation vouchers';

  @override
  String get partnerVouchersGuide =>
      'New bookings show up here right away. You do not need to approve or confirm.';

  @override
  String get partnerVouchersEmpty => 'No vouchers in this list.';

  @override
  String partnerVoucherTabArrived(int count) {
    return 'Arrived [$count]';
  }

  @override
  String get partnerVoucherTabPast => 'Past';

  @override
  String partnerVoucherTabCancelled(int count) {
    return 'Cancelled [$count]';
  }

  @override
  String get partnerVoucherJustArrived => 'Just arrived';

  @override
  String get partnerVoucherStatusAwaiting => 'Awaiting confirm';

  @override
  String get partnerVoucherStatusConfirmed => 'Confirmed';

  @override
  String get partnerVoucherStatusCancelled => 'Cancelled';

  @override
  String partnerVoucherTitleLine(String id, String product) {
    return 'Voucher $id · $product';
  }

  @override
  String get partnerVoucherTourDate => 'Tour dates';

  @override
  String get partnerVoucherParty => 'Guests';

  @override
  String partnerVoucherPartyDetail(int divers, int nondivers) {
    return 'Divers $divers · Non-divers $nondivers';
  }

  @override
  String get partnerVoucherOptions => 'Options';

  @override
  String get partnerVoucherFoc => 'Instructor FOC';

  @override
  String get partnerVoucherGuestName => 'Guest';

  @override
  String get partnerVoucherGuestNameMissing => 'Guest name unavailable';

  @override
  String get partnerVoucherRequests => 'Requests';

  @override
  String get partnerVoucherNone => 'None';

  @override
  String partnerVoucherCreatedStamp(String time) {
    return '$time · arrived';
  }

  @override
  String get partnerVoucherAck => 'Got it';

  @override
  String get partnerVoucherSavePrint => 'Save / print voucher';

  @override
  String get partnerVoucherView => 'View voucher';

  @override
  String get partnerVoucherCopied =>
      'Voucher text copied. Paste to save or print.';

  @override
  String get partnerVoucherTempConfirm => 'Confirm booking (temporary)';

  @override
  String partnerVoucherCancelCardBody(String product, String date, int divers) {
    return '$product · $date · Guest cancelled · $divers divers';
  }

  @override
  String get partnerVoucherCancelOpsNote =>
      'Refunds and guest support are handled by ops.';

  @override
  String get partnerVoucherSettlementTitle => 'This month\'s settlement';

  @override
  String get partnerVoucherSettlementSub => 'View sales, fees, and payout';

  @override
  String get partnerQuickStats => 'Stats';

  @override
  String get partnerQuickDocs => 'Partnership docs';

  @override
  String get partnerQuickSettlement => 'Settlement';

  @override
  String get partnerComingSoonBody => 'This feature is coming soon.';

  @override
  String get partnerBusinessHighlightTitle => 'Business Highlight';

  @override
  String get partnerHighlightJourney => 'Diver journey';

  @override
  String get partnerHighlightBookingHits => 'Booking hits';

  @override
  String get partnerHighlightPromoHits => 'Promotion hits';

  @override
  String get partnerHighlightEmptyMetrics => 'No data to show yet';

  @override
  String get partnerHighlightMilestoneTitle => 'Resort milestones · Dive Star';

  @override
  String get partnerMilestoneGeneral => 'General';

  @override
  String get partnerMilestonePreReview => 'Pre-review';

  @override
  String get partnerMilestoneOneStar => '1★';

  @override
  String get partnerMilestoneTwoStar => '2★';

  @override
  String get partnerMilestoneThreeStar => '3★';

  @override
  String get partnerHighlightReviewsTitle => 'Reviews';

  @override
  String get partnerHighlightNoReviews => 'No reviews yet';

  @override
  String partnerHighlightReviewCount(int count) {
    return '$count reviews';
  }

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
  String get partnerStatsPeriodWeek => 'This week';

  @override
  String get partnerStatsPeriodMonth => 'This month';

  @override
  String get partnerStatsPeriodThreeMonths => '3 months';

  @override
  String get partnerStatsAnchorVisit => 'Visits';

  @override
  String get partnerStatsAnchorAudience => 'Audience';

  @override
  String get partnerStatsAnchorDwell => 'Dwell';

  @override
  String get partnerStatsAnchorStrike => 'Strike rate';

  @override
  String get partnerStatsAnchorResult => 'Results';

  @override
  String get partnerStatsCatInApp => 'What happened in the app';

  @override
  String get partnerStatsCatResults => 'What led to bookings';

  @override
  String get partnerStatsSecVisit => 'App visits';

  @override
  String get partnerStatsSecAudience => 'Who\'s looking';

  @override
  String get partnerStatsSecDwell => 'How long they stay';

  @override
  String get partnerStatsSecStrike => 'Strike rate';

  @override
  String get partnerStatsSecJourney => 'Diver journey';

  @override
  String get partnerStatsSecProducts => 'Bookings by product';

  @override
  String get partnerStatsSecPromo => 'Promotion impact';

  @override
  String get partnerStatsKpiAppVisits => 'App visits';

  @override
  String get partnerStatsKpiProductViews => 'Product viewers';

  @override
  String get partnerStatsCmpAppAvg => 'App average';

  @override
  String get partnerStatsCmpPeers => 'Similar shops';

  @override
  String get partnerStatsFunnelDetail => 'Detail views';

  @override
  String get partnerStatsFunnelInterest => 'Interest';

  @override
  String get partnerStatsFunnelAttempt => 'Booking attempts';

  @override
  String get partnerStatsFunnelPaid => 'Paid';

  @override
  String get partnerStatsCollecting => 'Collecting data';

  @override
  String get partnerStatsProductsEmpty => 'No bookings in this period';

  @override
  String get partnerStatsColProduct => 'Product';

  @override
  String get partnerStatsColBookings => 'Bookings';

  @override
  String get partnerStatsColGuests => 'Guests';

  @override
  String get partnerStatsColChange => 'vs prior';

  @override
  String get partnerStatsPrivacyNote =>
      'Only non-identifying aggregates are shown.';

  @override
  String get partnerSettlementSimPayNote =>
      'Amounts are based on mock payments (SimPay). Final settlement is set after real payments connect.';

  @override
  String partnerSettlementMonthLabel(int year, int month) {
    return '$year.$month';
  }

  @override
  String get partnerSettlementByReceiveDate => 'By booking receive date';

  @override
  String get partnerSettlementValidCount => 'Valid bookings';

  @override
  String get partnerSettlementCancelledCount => 'Cancellations';

  @override
  String partnerSettlementCountValue(int count) {
    return '$count';
  }

  @override
  String get partnerSettlementGross => 'Gross bookings';

  @override
  String get partnerSettlementRefunds => 'Refunds';

  @override
  String get partnerSettlementNet => 'Net sales';

  @override
  String get partnerSettlementFeePending => 'Contract terms coming soon';

  @override
  String get partnerSettlementRateMissing => 'Commission rate not set';

  @override
  String partnerStatsDwellLine(int total, int average) {
    return 'Total $total min · average $average min';
  }

  @override
  String get partnerStatsStrikeNoViews => 'No product views';

  @override
  String get partnerSettlementListTitle => 'Bookings';

  @override
  String get partnerSettlementEmpty => 'No paid bookings received this month';

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
  String get communityTideHeadline => 'Leftover seats on trips already going';

  @override
  String get communityTideBody =>
      'Only products that opened leftover seats for an existing team. Everything else stays on Explore.';

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
      'Newest open seats first. Take a leftover seat to book.';

  @override
  String get communitySameBoatResults => 'Finished seats';

  @override
  String get communitySameBoatResultDeparted => 'Departed';

  @override
  String get communitySameBoatResultSoldOut => 'Sold out';

  @override
  String get communitySameBoatResultClosed => 'Closed';

  @override
  String get communityViewSeats => 'View seats';

  @override
  String get communityWindowOpen => 'Dates TBD';

  @override
  String get communityPlantFlag => 'Plant a flag';

  @override
  String get communityFlagButton => '🚩 Plant a flag';

  @override
  String get communityFlagPlantAndPay => '🚩 Plant a flag and pay';

  @override
  String get staffCannotBuy =>
      'Partner and admin accounts can\'t buy. Please sign up as a personal member.';

  @override
  String get communitySeeProduct => 'View product';

  @override
  String communityFlagPartyTotal(String amount) {
    return 'Total $amount';
  }

  @override
  String get communityFlagOneSeat =>
      'A flag locks as many seats as you choose until the pay deadline. Party size is fixed at checkout.';

  @override
  String communityFlagPartyAsk(int open) {
    return 'How many seats should we lock? ($open open)';
  }

  @override
  String communityFlagPartyLocked(int count) {
    return '$count seats locked by your flag — priority until the pay deadline';
  }

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
  String get exploreOpenMap => 'Open map';

  @override
  String get exploreAccessRoutes => 'Getting there';

  @override
  String get exploreResortFeatures => 'Resort highlights';

  @override
  String get exploreNearbySpots => 'Nearby places';

  @override
  String get exploreOpsHours => 'Hours';

  @override
  String get exploreCheckInLabel => 'Check-in';

  @override
  String get exploreCheckOutLabel => 'Check-out';

  @override
  String get exploreBusinessHoursLabel => 'Business hours';

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
      'Shown like Booking.com: one large cover plus a photo grid. The first photo is the cover.';

  @override
  String get exploreGalleryTitle => 'Resort photos';

  @override
  String get exploreGalleryHint =>
      'Up to 30 photos. The first becomes the cover on listings and the detail page.';

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
  String get communityFilterDeparting => 'Departing';

  @override
  String get sameBoatSearchWhen => 'When';

  @override
  String get sameBoatSearchWhere => 'Where';

  @override
  String get sameBoatSearchParty => 'Party';

  @override
  String get sameBoatSearchBudget => 'Budget';

  @override
  String get sameBoatSearchMore => 'More';

  @override
  String get sameBoatSearchThisMonth => 'This month';

  @override
  String get sameBoatSearchNextMonth => 'Next month';

  @override
  String get sameBoatSearchThreeMonths => 'Within 3 months';

  @override
  String sameBoatSearchPartyCount(int count) {
    return '$count';
  }

  @override
  String get sameBoatSearchPartyFivePlus => '5+';

  @override
  String get sameBoatSearchBudget50 => 'Up to 500k';

  @override
  String get sameBoatSearchBudget100 => 'Up to 1M';

  @override
  String get sameBoatSearchBudget200 => 'Up to 2M';

  @override
  String get sameBoatSearchBudgetAny => 'Any budget';

  @override
  String get sameBoatSearchLastCall => 'Last call';

  @override
  String get sameBoatSearchDeparting => 'Departing soon';

  @override
  String get sameBoatSearchReset => 'Reset';

  @override
  String sameBoatSearchApply(int count) {
    return 'Show $count seats';
  }

  @override
  String sameBoatSearchOpenCount(int count) {
    return '$count open';
  }

  @override
  String get sameBoatSearchSortNewest => 'Newest first';

  @override
  String get sameBoatSearchAllSeats => 'All open seats';

  @override
  String get sameBoatEmptyTitle => 'No open seats match these filters yet';

  @override
  String get sameBoatEmptySave => 'Save alert';

  @override
  String get sameBoatEmptySaved => 'Already saved';

  @override
  String get sameBoatEmptyWiden => 'Widen filters';

  @override
  String get sameBoatEmptyWidenHint => 'Try one step wider';

  @override
  String sameBoatUnlockLine(String name) {
    return 'Showing seats without the $name filter';
  }

  @override
  String get sameBoatUnlockBudget => 'budget';

  @override
  String get sameBoatUnlockParty => 'party size';

  @override
  String get sameBoatUnlockWhen => 'dates';

  @override
  String get sameBoatUnlockWhere => 'place';

  @override
  String get sameBoatUnlockMore => 'extra';

  @override
  String get mySeatAlertsTitle => 'My alerts';

  @override
  String get mySeatAlertsHint =>
      'When an open seat matches a saved filter, it shows here and on the My tab.';

  @override
  String get mySeatAlertsEmpty => 'No saved alerts';

  @override
  String get sameBoatAlertNone => 'No matching seats · shown when one opens';

  @override
  String sameBoatAlertMatchCount(int count) {
    return '$count matching seats';
  }

  @override
  String sameBoatAlertMonth(int month) {
    return '$month';
  }

  @override
  String get communityTakeSeat => 'Take a seat';

  @override
  String communityFlagHoldAsk(String deadline) {
    return 'Planting a flag locks your chosen seats until $deadline (provisional / orange) with first-holder priority. Pay to confirm (navy); if the deadline passes, the seats open again.';
  }

  @override
  String communityBerths(int booked, int capacity) {
    return 'Berths $booked/$capacity';
  }

  @override
  String communityLooking(int count) {
    return 'Flags $count';
  }

  @override
  String communitySeatPaid(int count) {
    return 'Paid $count';
  }

  @override
  String communitySeatHeld(int count) {
    return 'Hold $count';
  }

  @override
  String communitySeatOpen(int count) {
    return 'Open $count';
  }

  @override
  String get communityDateToday => 'Today';

  @override
  String get communityNeedSignIn => 'Sign in to plant a flag.';

  @override
  String get communityFlagAlready => 'You already hold this seat.';

  @override
  String get communityFlagContinuePayAsk =>
      'You already have a flag. Continue to payment?';

  @override
  String get communityFlagContinuePay => 'Continue to pay';

  @override
  String communityFlagResizeAsk(int from, int to) {
    return 'Change your flag from $from to $to?';
  }

  @override
  String get communityFlagResizeConfirm => 'Change';

  @override
  String get communityFlagTaken => 'Someone just took that seat.';

  @override
  String get communityFlagTooLate =>
      'Too close to the flag deadline to plant a new one.';

  @override
  String get communityFlagLimitReached =>
      'You can hold at most 3 flags at once.';

  @override
  String get communitySeatsShort => 'Not enough seats left on this option.';

  @override
  String get profileFlagCancelCta => 'Cancel';

  @override
  String get profileFlagCancelConfirm =>
      'Canceling this flag frees the seats immediately. Cancel it?';

  @override
  String get communityOfferDetail => 'This berth';

  @override
  String get workbenchSeatOption => 'Option opening seats';

  @override
  String get workbenchSeatBase => 'Base product';

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
  String get communityEmpty =>
      'No leftover-seat trips yet. Regular products stay on Explore.';

  @override
  String get communityDesignPreview => 'Design preview';

  @override
  String get communityDesignPreviewFlag =>
      'This is a sample card. When a partner opens empty seats, you can plant a flag here.';

  @override
  String get profileGuestLoginPrompt => 'Sign in to see your trips';

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
  String get bookingRequested => 'Requested';

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
  String get bookingPaymentUnpaid => 'Unpaid';

  @override
  String get bookingPaymentCaptured => 'Paid';

  @override
  String get bookingPaymentRefunded => 'Refunded';

  @override
  String get bookingListEmpty => 'No bookings yet. Book a trip from Explore.';

  @override
  String get bookingQuoteBreakdown => 'Price breakdown';

  @override
  String get bookingConfirmAndCapture => 'Confirm · mark paid';

  @override
  String get bookingConfirmDone => 'Booking confirmed and marked as paid.';

  @override
  String get bookingConfirmFailed => 'This booking cannot be confirmed.';

  @override
  String get bookingDetailCta => 'Details';

  @override
  String get bookingDetailTitle => 'Booking details';

  @override
  String get bookingCreatedAt => 'Requested';

  @override
  String get adminBookingsTitle => 'Bookings';

  @override
  String get adminBookingsEmpty => 'No bookings to review yet.';

  @override
  String get workbenchTitle => 'Departure desk';

  @override
  String get workbenchDeckHull => 'Hull';

  @override
  String get workbenchDeckStory => 'Story';

  @override
  String get workbenchDeckRates => 'Rates';

  @override
  String get workbenchDeckOptions => 'Options';

  @override
  String get workbenchNext => 'Next';

  @override
  String get workbenchNeedName => 'Enter a product name before saving.';

  @override
  String get workbenchNeedDiverPrice =>
      'Enter a diver package price greater than 0 before saving.';

  @override
  String get workbenchPriceOverCap =>
      'Enter a price of 100 million won or less.';

  @override
  String workbenchPriceOverCapNamed(String name) {
    return 'Option \'$name\' price must be 100 million won or less.';
  }

  @override
  String get workbenchUnitPriceRequired => 'Price per person (required)';

  @override
  String get workbenchCurrencyWon => 'KRW';

  @override
  String get workbenchGuestPreviewTitle => 'Guest checkout preview';

  @override
  String get workbenchGuestPreviewHint =>
      'Example only — guest counts here are not saved.';

  @override
  String get workbenchPriceRevisionPendingBanner =>
      'Price or new-option changes are waiting for admin approval. Other edits are already saved on the live listing.';

  @override
  String workbenchPriceRevisionRejectedBanner(String note) {
    return 'Admin returned the price change request: $note';
  }

  @override
  String get workbenchPriceRevisionStaged =>
      'Prices and new options will go live after admin approval. Everything else was saved right away.';

  @override
  String get workbenchOptionClosedNotDeleted =>
      'This option has bookings or holds, so it was closed instead of removed.';

  @override
  String get workbenchPhotoUploadFailed =>
      'Photo upload failed. Fix the connection or R2 settings, then save again. Nothing was saved.';

  @override
  String get workbenchPhotoLoadFailed => 'Couldn\'t load this photo';

  @override
  String get workbenchNeedGuestPrice =>
      'Enter non-diver and child prices greater than 0 before saving.';

  @override
  String get workbenchNeedOptionPrice =>
      'If an option has a name, enter a price greater than 0.';

  @override
  String workbenchNeedOptionPriceNamed(String name) {
    return 'Enter a price for option \'$name\'';
  }

  @override
  String get workbenchCategory => 'Category';

  @override
  String get workbenchCatResort => 'Resort';

  @override
  String get workbenchCatLiveaboard => 'Liveaboard';

  @override
  String get workbenchCatFun => 'Fun dive';

  @override
  String get workbenchCatCourse => 'Course';

  @override
  String get workbenchCatDay => 'Day trip';

  @override
  String get workbenchHullFromShop => 'From the resort hull';

  @override
  String get workbenchOpenMap => 'Open in maps';

  @override
  String get workbenchOpenSeats => 'Open leftover seats on Same boat';

  @override
  String get workbenchOpenSeatsHint =>
      'Turn on only to fill an existing team for the same dates. Off = a regular listing.';

  @override
  String get workbenchSeatCount => 'Total seats';

  @override
  String get workbenchDepartureDate => 'Departure date';

  @override
  String get workbenchFlagDeadline => 'Flag deadline';

  @override
  String get workbenchOpenSeatsNeedFields =>
      'People needed, a departure date, and a flag deadline are required to open leftover seats.';

  @override
  String get workbenchOpenSeatsAfterApproval =>
      'You can open leftover seats after this trip is approved.';

  @override
  String get sameBoatRequiredHeadcount => 'People needed to depart';

  @override
  String sameBoatBookedReference(int count) {
    return '$count booked on this date';
  }

  @override
  String sameBoatSeatsToFill(int count) {
    return '$count seats to fill';
  }

  @override
  String get sameBoatAlreadyBooked => 'Already recruited';

  @override
  String sameBoatSeatOpenPreview(int capacity, int booked, int open) {
    return '$capacity seats · $booked confirmed · $open open';
  }

  @override
  String sameBoatCapacityBelowOccupied(int booked, int holds) {
    return 'Total seats cannot be below confirmed ($booked) + provisional ($holds).';
  }

  @override
  String get sameBoatAskAdminToChange => 'Ask an admin to change this.';

  @override
  String get sameBoatPendingAfterSave =>
      'Same-boat listing waits for admin approval. (Admin → Shop → Same-boat monitor)';

  @override
  String get briefSectionSameBoat => 'Same-boat leftover seats';

  @override
  String get workbenchDetail => 'Full description';

  @override
  String get workbenchItinerary => 'Standard itinerary';

  @override
  String get workbenchAddDay => 'Add day';

  @override
  String workbenchDayTitle(int day) {
    return 'Day $day title';
  }

  @override
  String get workbenchDayBody => 'Details';

  @override
  String get workbenchGuestDiver => 'Diver';

  @override
  String get workbenchGuestNondiver => 'Non-diver';

  @override
  String get workbenchGuestChild => 'Child';

  @override
  String get workbenchGuestInfant => 'Infant';

  @override
  String get workbenchGuestEnabled => 'Offer';

  @override
  String get workbenchFoc => 'FOC';

  @override
  String get workbenchFocPay => 'Pay for';

  @override
  String get workbenchFocFree => 'Free';

  @override
  String get workbenchBasePackage => 'Base package';

  @override
  String get workbenchBasePackageHint =>
      'The story and itinerary become option 1, selected by default.';

  @override
  String get workbenchAddons => 'Add-ons · only with the package';

  @override
  String get workbenchIndividuals => 'A la carte · instead of the package';

  @override
  String get workbenchBookable => 'Show at checkout';

  @override
  String get workbenchGuestPreview => 'Guest booking';

  @override
  String get briefTitle => 'Product registration';

  @override
  String get briefSectionCover => 'Cover';

  @override
  String get briefSectionPlace => 'Destination';

  @override
  String get briefSectionDays => 'Product details';

  @override
  String get detailComposerHint =>
      'Write the trip story, daily plan, and tables in one place.';

  @override
  String get detailComposerBold => 'Bold';

  @override
  String get detailComposerHeading => 'Heading';

  @override
  String get detailComposerList => 'List';

  @override
  String get detailComposerTable => 'Insert table';

  @override
  String get detailComposerTableSchedule => 'Time · activity';

  @override
  String get detailComposerTableInclude => 'Includes · excludes';

  @override
  String get detailComposerDay => 'Day template';

  @override
  String get detailComposerPreview => 'Preview';

  @override
  String get detailComposerEdit => 'Edit';

  @override
  String get briefSectionTerms => 'Start booking';

  @override
  String get bookingEntryBasePackage => 'Base package';

  @override
  String get bookingEntryDiverPrice => 'Package price (1 diver)';

  @override
  String get bookingEntryHasNondivers => 'Any non-divers joining?';

  @override
  String get bookingEntryAdultNondiver => 'Adult non-diver';

  @override
  String get bookingEntryChildInfant => 'Child / infant';

  @override
  String get bookingEntryUnitPrice => 'Price per person';

  @override
  String get bookingEntryPreviewSnack =>
      'Preview only — guests will pay from the live listing.';

  @override
  String get bookingEntryAddons => 'Add-on options';

  @override
  String get bookingEntryAddOption => 'Add option';

  @override
  String get bookingEntryOptionName => 'Option name';

  @override
  String get bookingEntryOptionPrice => 'Unit price';

  @override
  String get bookingEntryTermsToggle => 'Includes & excludes';

  @override
  String get bookingEntryIndividuals => 'A la carte';

  @override
  String get bookingEntryIndividualsHint =>
      'Courses, day dives, and other items sold separately from the package.';

  @override
  String get bookingEntryAddIndividual => 'Add a la carte item';

  @override
  String get bookingEntryIndividualName => 'Item name';

  @override
  String get bookingEntryStayLength => 'Trip length';

  @override
  String bookingEntryNights(int nights) {
    return '$nights nights';
  }

  @override
  String bookingEntryDays(int days) {
    return '$days days';
  }

  @override
  String get bookingEntryCheckIn => 'Check-in';

  @override
  String get bookingEntryCheckOut => 'Check-out';

  @override
  String get bookingEntryChangeDates => 'Change dates';

  @override
  String get bookingEntryPickDate => 'Pick a date';

  @override
  String bookingEntryStayRange(String checkIn, String checkOut) {
    return '$checkIn – $checkOut';
  }

  @override
  String get briefSectionPrice => 'Price';

  @override
  String get briefSectionSeats => 'Open seats';

  @override
  String get briefSourceCatalog => 'Resort from the list';

  @override
  String get briefSourceNamed => 'Resort you name';

  @override
  String get briefAddLine => 'Add a line';

  @override
  String get briefRemoveLine => 'Remove line';

  @override
  String get briefOpenSeats => 'Open leftover seats on this trip?';

  @override
  String get briefFocApplies => 'Applies to';

  @override
  String get briefStartPrice => 'Diver starting price';

  @override
  String get briefGuestCard => 'Guest card';

  @override
  String get briefKeepEditing => 'Keep editing';

  @override
  String get briefSubmitReview => 'Submit for review';

  @override
  String get briefPublishNow => 'Publish now';

  @override
  String get briefTakeDown => 'Take down';

  @override
  String get briefKept => 'Saved so you can keep writing.';

  @override
  String get briefTakenDown => 'The trip is hidden from guests.';

  @override
  String get briefSave => 'Save';

  @override
  String get briefEdit => 'Edit';

  @override
  String get briefStepBasics => 'Basics';

  @override
  String get briefStepPricing => 'Price';

  @override
  String get briefStepReview => 'Review';

  @override
  String get briefStepNext => 'Next';

  @override
  String get briefStepBack => 'Back';

  @override
  String get briefTempSave => 'Save draft';

  @override
  String get briefSubmit => 'Submit for review';

  @override
  String get briefChecklistTitle => 'Before you submit';

  @override
  String get briefChecklistHint => 'Check these, then submit.';

  @override
  String get briefChecklistPhotos => 'Photos';

  @override
  String get briefChecklistCopy => 'Name & intro';

  @override
  String get briefChecklistPrice => 'Base price';

  @override
  String get briefChecklistOptions => 'Option prices';

  @override
  String get briefChecklistIncludes => 'Includes & excludes';

  @override
  String get briefChecklistCancel => 'Cancellation';

  @override
  String get briefShopInfoTitle => 'Shop & resort info';

  @override
  String get briefShopInfoBody =>
      'Name, location, and intro are managed on the resort desk.';

  @override
  String get briefShopInfoOpen => 'Open resort desk';

  @override
  String get briefSameBoatPartnerHint =>
      'Open same-boat leftover seats from product management after you publish.';

  @override
  String get briefTempSaveNeedPhoto => 'Add at least one photo.';

  @override
  String get briefTempSaveNeedPrice => 'Enter a base price greater than 0.';

  @override
  String get briefLeaveTitle => 'Leave without saving?';

  @override
  String get briefLeaveBody => 'You have unsaved changes.';

  @override
  String get briefLeaveTempSave => 'Save draft and leave';

  @override
  String get briefLeaveDiscard => 'Leave without saving';

  @override
  String get briefLeaveStay => 'Keep editing';

  @override
  String get briefViewModeHint => 'Tap Edit to make changes.';

  @override
  String get adminProductDelete => 'Delete';

  @override
  String adminProductDeleteBody(String name) {
    return 'Delete \"$name\" from the product list.';
  }

  @override
  String get adminProductDeleted => 'Product deleted.';

  @override
  String get adminProductRejectNote => 'Reason for return';

  @override
  String get adminProductRejectNoteHint => 'The partner will see this note.';

  @override
  String get checkoutStepSelect => 'Choose';

  @override
  String get checkoutStepReview => 'Your booking';

  @override
  String get checkoutStepPay => 'Pay';

  @override
  String get checkoutReviewCta => 'Review booking';

  @override
  String get checkoutReviewDetailHint =>
      'Review the details below, then edit or confirm your booking.';

  @override
  String get checkoutBack => 'Back';

  @override
  String get checkoutEditBooking => 'Edit booking';

  @override
  String get checkoutConfirm => 'Confirm booking';

  @override
  String get checkoutNeedChoice =>
      'Select the base package or an a la carte item.';

  @override
  String get checkoutGuests => 'Guests';

  @override
  String get checkoutPackageOn => 'Base package';

  @override
  String checkoutTotal(String amount) {
    return 'Total $amount won';
  }

  @override
  String checkoutFocLine(int pay, int free, int count) {
    return 'FOC $pay+$free · $count complimentary divers';
  }

  @override
  String checkoutGuestsBelowMin(int min) {
    return 'At least $min guests are required for this trip.';
  }

  @override
  String checkoutGuestsAboveMax(int max) {
    return 'This trip allows up to $max guests.';
  }

  @override
  String get checkoutSignInRequired => 'Sign in to complete this booking.';

  @override
  String bookingPartySummary(int diver, int nondiver, int child, int infant) {
    return '$diver diver · $nondiver non-diver · $child child · $infant infant';
  }

  @override
  String get adminOverviewBasis =>
      'By receive date · net = paid total − refunds';

  @override
  String get adminOverviewTodayBookings => 'Bookings today';

  @override
  String get adminOverviewTodayPaid => 'Paid today';

  @override
  String get adminOverviewTodayCancel => 'Cancels and refunds today';

  @override
  String get adminOverviewMonthSales => 'Sales this month';

  @override
  String get adminOverviewVsYesterday => 'vs yesterday';

  @override
  String get adminOverviewSameAsYesterday => 'Same as yesterday';

  @override
  String get adminOverviewVsMonth => 'vs last month';

  @override
  String get adminOverviewVsYear => 'vs last year';

  @override
  String get adminOverviewNoCompare => 'No comparison data';

  @override
  String get adminOverviewQueueTitle => 'Waiting';

  @override
  String get adminOverviewQueueCertify => 'Instructor check';

  @override
  String get adminOverviewQueueSign => 'Awaiting signature';

  @override
  String get adminOverviewQueueDiveStar => 'Dive Star review';

  @override
  String get adminOverviewQueueProposal => 'Partner proposal';

  @override
  String get adminOverviewQueueApply => 'Partner applications';

  @override
  String get adminOverviewQueueProducts => 'Product check';

  @override
  String get adminOverviewComingSoon => 'Not ready';

  @override
  String get adminOverviewChart14 => 'Sales, last 14 days';

  @override
  String get adminOverviewChart30 => 'Daily sales, last 30 days';

  @override
  String get adminOverviewPriorYear => 'Same days last year';

  @override
  String get adminOverviewLive => 'Bookings and payments';

  @override
  String get adminOverviewSeeAll => 'See all';

  @override
  String get adminOverviewLiveEmpty => 'No recent bookings.';

  @override
  String get adminOverviewActivity => 'Changes';

  @override
  String get adminOverviewActivityEmpty => 'No recent changes.';

  @override
  String get adminOverviewActivityGap =>
      'Price changes and seat changes are not ready.';

  @override
  String get adminOverviewChangeConsumer => 'Guest price';

  @override
  String get adminOverviewChangePro => 'Pro price';

  @override
  String get adminOverviewChangeCapacity => 'Seats';

  @override
  String adminOverviewChangeLine(
    String name,
    String label,
    int before,
    int after,
  ) {
    return '$name $label $before→$after';
  }

  @override
  String get adminOverviewPaid => 'Paid';

  @override
  String get adminOverviewCancelled => 'Cancelled';

  @override
  String get adminOverviewPartial => 'Partial refund';

  @override
  String get adminOverviewNoName => 'No name';

  @override
  String get adminOverviewJoin => 'Joined';

  @override
  String get adminOverviewRefund => 'Refund';

  @override
  String get adminOverviewSigned => 'Signed';

  @override
  String get adminOverviewApplied => 'Review request';

  @override
  String get adminOverviewCancelSpike =>
      'Today\'s cancels are at least twice the 28-day daily average.';

  @override
  String get adminOverviewWeekDrop =>
      'Partners whose sales this week are at least 30% below last week';

  @override
  String get adminOverviewMoreThanUsual => 'Higher than usual';

  @override
  String get adminOverviewCountUnit => '';

  @override
  String get adminSalesGross => 'Paid total';

  @override
  String get adminSalesRefund => 'Refunds';

  @override
  String get adminSalesNet => 'Net sales';

  @override
  String get adminSalesAverage => 'Average payment';

  @override
  String get adminSalesActivePartners => 'Active partners';

  @override
  String get adminSalesActiveHint => 'Has a booking in this period';

  @override
  String get adminSalesPresetToday => 'Today';

  @override
  String get adminSalesPresetWeek => 'This week';

  @override
  String get adminSalesPresetMonth => 'This month';

  @override
  String get adminSalesPresetQuarter => '3 months';

  @override
  String get adminSalesPresetCustom => 'Custom';

  @override
  String get adminSalesComparePrev => 'Prior period';

  @override
  String get adminSalesCompareYear => 'Last year';

  @override
  String get adminSalesPartners => 'Partner results';

  @override
  String get adminSalesColRank => '#';

  @override
  String get adminSalesColPartner => 'Partner';

  @override
  String get adminSalesColBookings => 'Bookings';

  @override
  String get adminSalesColGross => 'Gross';

  @override
  String get adminSalesColRefund => 'Refunds';

  @override
  String get adminSalesColNet => 'Net';

  @override
  String get adminSalesColDelta => 'Change';

  @override
  String get adminSalesColCancel => 'Cancel rate';

  @override
  String get adminSalesColShare => 'Share';

  @override
  String get adminSalesTotalRow => 'Total';

  @override
  String get adminSalesCategory => 'Net sales by category';

  @override
  String get adminSalesCatTour => 'Tours and liveaboards';

  @override
  String get adminSalesCatCourse => 'Courses';

  @override
  String get adminSalesCatFun => 'Fun dives';

  @override
  String get adminSalesCatFlag => 'Same boat';

  @override
  String get adminSalesCatUnknown => 'Unclassified';

  @override
  String get adminSalesTop => 'Top 5 products';

  @override
  String get adminSalesBasis => 'By receive date · net = paid total − refunds';

  @override
  String get adminSalesEmpty => 'No bookings in this period.';

  @override
  String get adminSalesClamped => 'The range is limited to 12 months.';

  @override
  String get adminSalesNew => 'New';

  @override
  String get adminSalesMine => 'My shop';

  @override
  String get adminSalesOpenContract => 'Contract vault';

  @override
  String get adminSalesOpenDocs => 'Documents';

  @override
  String get adminSalesOpenPartners => 'Partner list';

  @override
  String get adminSalesRowHint =>
      'A row opens the contract vault, documents, or partner list.';

  @override
  String get adminStatsPresetWeek => 'This week';

  @override
  String get adminStatsPresetMonth => 'This month';

  @override
  String get adminStatsPresetQuarter => '3 months';

  @override
  String get adminStatsPresetYear => 'This year';

  @override
  String get adminStatsFlow => 'Sales flow';

  @override
  String get adminStatsFlowHint => 'Daily, compared with last year';

  @override
  String get adminStatsWho => 'Who buys';

  @override
  String get adminStatsWhat => 'What sells';

  @override
  String get adminStatsResort => 'Resort rank';

  @override
  String get adminStatsOptions => 'Option pick rate';

  @override
  String get adminStatsOptionsHint => 'Grouping options would show more detail';

  @override
  String get adminStatsMost => 'Most picked option';

  @override
  String get adminStatsPartner => 'Partner results';

  @override
  String get adminStatsPartnerHint => 'Net sales × cancel rate';

  @override
  String get adminStatsCancel => 'Cancels and refunds';

  @override
  String get adminStatsCancelHint => 'Cancels by month';

  @override
  String get adminStatsTopCancel => 'Most cancelled products';

  @override
  String get adminStatsDiveStar => 'Dive Star';

  @override
  String get adminStatsDiveNote =>
      'Pre-review uses the latest 50 applications.';

  @override
  String get adminStatsLead => 'When people book';

  @override
  String get adminStatsLeadHint => 'Days before departure';

  @override
  String get adminStatsLeadNote =>
      'Bookings saved without a departure date can land in same-day.';

  @override
  String get adminStatsSeason => 'Season';

  @override
  String get adminStatsSeasonHint => 'Bookings by month';

  @override
  String get adminStatsGathering => 'Still collecting';

  @override
  String get adminStatsCountry => 'Country';

  @override
  String get adminStatsCountryUnknown => 'Not set';

  @override
  String get adminStatsReturn => 'Returning';

  @override
  String get adminStatsBuyerNote =>
      'Returning uses the current lifetime purchase count.';

  @override
  String get adminStatsGradeUnknown => 'No grade';

  @override
  String get adminStatsBasis => 'By receive date';

  @override
  String get adminStatsLead0 => 'Same day';

  @override
  String get adminStatsLead3 => '3 days';

  @override
  String get adminStatsLead7 => '7 days';

  @override
  String get adminStatsLead14 => '14 days';

  @override
  String get adminStatsLead30 => '30 days';

  @override
  String get adminStatsLead30p => '30+ days';

  @override
  String get adminReportMake => 'Build report';

  @override
  String get adminReportPrint => 'Print · PDF';

  @override
  String get adminReportSettings => 'Report settings';

  @override
  String get adminReportPeriod => 'Period';

  @override
  String get adminReportPeriodMonth => 'Month';

  @override
  String get adminReportPeriodQuarter => 'Quarter';

  @override
  String get adminReportPeriodYear => 'Year';

  @override
  String get adminReportPeriodCustom => 'Custom';

  @override
  String get adminReportCompare => 'Compare';

  @override
  String get adminReportCompareNone => 'None';

  @override
  String get adminReportCategories => 'Categories';

  @override
  String get adminReportPartners => 'Partners';

  @override
  String get adminReportProducts => 'Products';

  @override
  String get adminReportAll => 'All';

  @override
  String get adminReportInclude => 'Include';

  @override
  String get adminReportSummary => 'Summary';

  @override
  String get adminReportTrend => 'Sales trend';

  @override
  String get adminReportPartnerTable => 'Partner table';

  @override
  String get adminReportProductRank => 'Product rank';

  @override
  String get adminReportOptions => 'Option picks';

  @override
  String get adminReportCancels => 'Cancels and refunds';

  @override
  String get adminReportBasis => 'How the numbers are calculated';

  @override
  String get adminReportEmpty => 'Press Build report to fill the preview.';

  @override
  String get adminReportHeading => 'Management report';

  @override
  String get adminReportBasisBody =>
      'By receive date. Paid total includes later cancels. Refunds are cancel and weather-cancel amounts. Net = paid total − refunds. Payments are simulated (SimPay) for now.';

  @override
  String get adminReportFontLicense =>
      'Noto Sans KR is under the SIL Open Font License (OFL).';

  @override
  String get adminReportPrinting => 'Preparing the PDF.';

  @override
  String get partnerApplyTitle => 'Apply to partner';

  @override
  String get partnerApplyShop => 'Resort or shop name';

  @override
  String get partnerApplyContact => 'Contact name';

  @override
  String get partnerApplyPhone => 'Phone';

  @override
  String get partnerApplyRegion => 'Region';

  @override
  String get partnerApplyIntro => 'One-line intro';

  @override
  String get partnerApplyLink => 'Website or social link (optional)';

  @override
  String get partnerApplyConsent => 'I agree to the privacy notice';

  @override
  String get partnerApplySend => 'Send application';

  @override
  String get partnerApplySent => 'Application received';

  @override
  String get partnerApplyCopy => 'Copy';

  @override
  String get partnerApplyBadField => 'Please fill in the fields';

  @override
  String get partnerApplyBadLink => 'Keep the link within 200 characters';

  @override
  String get partnerApplyNeedConsent => 'Agree before sending';

  @override
  String get adminApplyEmpty => 'No applications yet.';

  @override
  String get adminApplyNew => 'New';

  @override
  String get adminApplyHandled => 'Handled';

  @override
  String get adminApplyMark => 'Mark handled';

  @override
  String get adminApplyOpenMember => 'View this member';

  @override
  String refundPolicyHint(int percent) {
    return 'Cancel now for a $percent% refund';
  }
}
