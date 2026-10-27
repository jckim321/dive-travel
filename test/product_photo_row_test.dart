import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/widgets/booking_gallery_editor.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('썸네일을 누르면 대표 지정과 삭제를 고른다', (tester) async {
    final removed = <int>[];
    final covers = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BookingGalleryEditor(
            compact: true,
            items: [
              BookingGalleryItem.local(_photo('a.png')),
              BookingGalleryItem.local(_photo('b.png')),
            ],
            onAdd: () {},
            onRemove: removed.add,
            onMakeCover: covers.add,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('대표'), findsOneWidget);
    expect(find.text('+ 사진 추가'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('product-photo-strip'))).height,
      72,
    );

    await tester.tap(find.byKey(const Key('product-photo-thumb-0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('product-photo-make-cover')), findsNothing);
    expect(find.byKey(const Key('product-photo-delete')), findsOneWidget);
    await tester.tap(find.byKey(const Key('product-photo-delete')));
    await tester.pump();
    expect(removed, [0]);

    await tester.tap(find.byKey(const Key('product-photo-thumb-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('대표로'), findsOneWidget);
    await tester.tap(find.byKey(const Key('product-photo-make-cover')));
    await tester.pump();
    expect(covers, [1]);
  });

  testWidgets('사진이 없어도 사진 칸은 한 줄이다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BookingGalleryEditor(
            compact: true,
            items: const [],
            onAdd: () {},
            onRemove: (_) {},
            onMakeCover: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('product-photo-thumb-0')), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('product-photo-strip'))).height,
      72,
    );
    expect(find.byType(AspectRatio), findsNothing);
  });
}

PickedPhoto _photo(String name) {
  return PickedPhoto(
    bytes: Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      ),
    ),
    fileName: name,
    contentType: 'image/png',
  );
}
