import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/features/shell/presentation/main_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

Future<void> offerOpenTideRoom({
  required BuildContext context,
  required DiveShop shop,
  required DateTime tourDate,
}) async {
  final l10n = AppLocalizations.of(context);
  final open = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.communityPlantFlag),
        content: Text(l10n.communityPlantFlagAsk),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.communityPlantFlagLater),
          ),
          FilledButton(
            key: const Key('open-tide-room'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.communityPlantFlag),
          ),
        ],
      );
    },
  );
  if (open != true || !context.mounted) {
    return;
  }
  await openTideRoom(context: context, shop: shop, tourDate: tourDate);
}

Future<void> openTideRoom({
  required BuildContext context,
  required DiveShop shop,
  required DateTime tourDate,
}) async {
  final l10n = AppLocalizations.of(context);
  final window = shop.departure?.windowLabel.isNotEmpty == true
      ? shop.departure!.windowLabel
      : DateFormat('MM.dd').format(tourDate);
  await DiverStoreScope.of(context).addCommunityPost(
    title: shop.name,
    subtitle: shop.productName,
    type: CommunityPostType.buddy,
    language: Localizations.localeOf(context).languageCode,
    shopId: shop.hullId,
    destination: shop.location,
    windowLabel: window,
    bookedSeats: 1,
    lookingSeats: 0,
    kind: TideKind.shopCrew,
  );
  if (!context.mounted) {
    return;
  }
  MainShell.goToTab(context, 2);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.communityRoomOpened)),
  );
}

Future<void> openTideRoomForBooking({
  required BuildContext context,
  required TourBooking booking,
}) async {
  final store = DiverStoreScope.of(context);
  final shop = store.listingsOnHull(booking.shopId.split('--').first).where((
    item,
  ) {
    return item.id == booking.shopId || item.productName == booking.productName;
  }).firstOrNull;
  final hull = store.listingsOnHull(booking.shopId.split('--').first);
  final target = shop ?? hull.firstOrNull;
  if (target == null) {
    return;
  }
  await openTideRoom(
    context: context,
    shop: target.copyWith(productName: booking.productName),
    tourDate: booking.scheduledFor,
  );
}
