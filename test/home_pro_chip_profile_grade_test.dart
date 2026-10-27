import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/widgets/exploration_map.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/features/home/presentation/home_screen.dart';
import 'package:dive_travel_app/features/profile/presentation/profile_screen.dart';
import 'package:dive_travel_app/features/profile/presentation/pro_verification_card.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('승인된 강사 홈에는 PRO 칩이 없다', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    final repo = MemoryDiverRepository.forTest(isInstructor: true);
    final store = DiverStore(repo);
    final session = SessionController(repo);
    addTearDown(store.dispose);
    addTearDown(session.dispose);
    _wide(tester);

    await tester.pumpWidget(
      _app(store, session: session, home: const HomeScreen()),
    );
    await tester.pump();
    await tester.pump();

    expect(store.stats.isVerifiedPro, isTrue);
    expect(find.text(l10n.profileProBadge), findsNothing);
    expect(find.byType(ExplorationMap), findsOneWidget);
  });

  testWidgets('승인된 강사의 마이 등급은 강사다', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    final repo = MemoryDiverRepository.forTest(isInstructor: true);
    final store = DiverStore(repo);
    final session = SessionController(repo);
    addTearDown(store.dispose);
    addTearDown(session.dispose);
    _wide(tester);

    await tester.pumpWidget(
      _app(store, session: session, home: const ProfileScreen()),
    );
    await tester.pump();
    await tester.pump();

    expect(store.stats.isVerifiedPro, isTrue);
    expect(store.stats.memberGrade.name, 'silver');
    final header = find.byKey(const Key('departure-desk-header'));
    expect(header, findsOneWidget);
    expect(
      find.descendant(
        of: header,
        matching: find.text('🎓 ${l10n.profileGradeInstructor}'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: header,
        matching: find.textContaining(l10n.profileGradeSilver),
      ),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('open-profile-settings')));
    await tester.pump();
    await tester.pump();

    expect(find.byType(ProVerificationCard), findsOneWidget);
    expect(find.text(l10n.profileProBadge), findsOneWidget);
  });
}

void _wide(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(
  DiverStore store, {
  required SessionController session,
  required Widget home,
}) {
  return DiverStoreScope(
    store: store,
    child: SessionScope(
      session: session,
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
}
