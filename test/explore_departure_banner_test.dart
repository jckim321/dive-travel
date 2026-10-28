import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/data/travel_style.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/bookings/presentation/my_bookings_section.dart';
import 'package:dive_travel_app/features/explore/presentation/explore_screen.dart';
import 'package:dive_travel_app/features/home/presentation/home_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('여행상품 탭에는 출국 띠가 없고 홈 탑승권은 남는다', (tester) async {
    final tour = DateTime.now().add(const Duration(days: 12));
    final repo = MemoryDiverRepository.forTest();
    await repo.createBooking(
      uid: 'test-user',
      shopId: 'bohol-hideout',
      shopName: '보홀 오션 하이드아웃',
      productName: '2탱크 펀다이빙',
      price: 180000,
      tourDate: tour,
    );

    final store = DiverStore(repo);
    final session = SessionController(repo);
    addTearDown(store.dispose);
    addTearDown(session.dispose);

    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ExploreScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final l10n = AppLocalizations.of(tester.element(find.byType(ExploreScreen)));
    expect(find.byKey(const Key('explore-departure-banner')), findsNothing);
    expect(
      find.text(l10n.exploreDepartureBanner(
        TravelStyleAnalyzer.daysUntil(tour),
        '보홀 오션 하이드아웃',
      )),
      findsNothing,
    );
    expect(find.byKey(const Key('explore-search')), findsOneWidget);

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: MyBookingsSection()),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('my-bookings-section')), findsOneWidget);
    expect(find.text('2탱크 펀다이빙'), findsOneWidget);
    expect(find.byKey(const Key('explore-departure-banner')), findsNothing);

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: SessionScope(
          session: session,
          child: MaterialApp(
            theme: AppTheme.light,
            locale: AppConstants.defaultLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('home-for-you')), findsOneWidget);
    expect(find.byKey(const Key('explore-departure-banner')), findsNothing);
  });
}
