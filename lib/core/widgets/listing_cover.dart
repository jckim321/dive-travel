import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';

/// 홈·탐색 카드 대표컷. 2열 그리드에서 여행 사진이 돋보이도록 1:1로 자릅니다.
abstract final class ListingCover {
  static const double aspectRatio = 1;

  /// Prefer full opacity; dimming makes uploaded photos look soft/washed out.
  static const double photoOpacity = 1;

  static double cardExtent(BuildContext context, {double horizontal = 52}) {
    final cellW = (MediaQuery.sizeOf(context).width - horizontal) / 2;
    // Image + shop name + guest rating line.
    return cellW / aspectRatio + 54;
  }
}

class ListingCoverPhoto extends StatelessWidget {
  const ListingCoverPhoto({
    super.key,
    required this.shop,
    this.bytes,
    this.opacity = ListingCover.photoOpacity,
    this.radius = 0,
  });

  final DiveShop shop;
  final Uint8List? bytes;
  final double opacity;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final store = DiverStoreScope.of(context);
    final data = bytes ??
        store.coverBytesFor(shop.id) ??
        store.coverBytesFor(shop.hullId);
    final url = shop.coverUrl;
    final accent = Color(shop.accentColor);
    final dpr = MediaQuery.devicePixelRatioOf(context);

    Widget image;
    if (data != null && data.isNotEmpty) {
      image = Image.memory(
        data,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        isAntiAlias: true,
      );
    } else if (url.isNotEmpty && !url.startsWith('memory://')) {
      image = Image.network(
        url,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        isAntiAlias: true,
        // Decode near device density so OTA covers stay sharp on retina.
        cacheWidth: (900 * dpr).round().clamp(600, 1800),
        errorBuilder: (_, _, _) => Image.asset(
          'assets/images/test_dive_photo.png',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      );
    } else {
      image = Image.asset(
        'assets/images/test_dive_photo.png',
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }

    final photo = opacity >= 0.999
        ? image
        : Opacity(opacity: opacity, child: image);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, AppTheme.ocean, AppTheme.oceanDeep],
        ),
      ),
      child: photo,
    );
  }
}
