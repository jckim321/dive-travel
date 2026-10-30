import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_operating.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_partners_roster_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

Future<void> _shop(
  MemoryDiverRepository repo,
  String id, {
  int grade = 0,
  ShopOperatingStatus status = ShopOperatingStatus.active,
}) async {
  await repo.saveShopProfile(
    shopId: id,
    name: id,
    location: '세부',
    productName: '펀',
    consumerPrice: 1,
    professionalPrice: 1,
  );
  if (grade > 0) {
    final reviewed = DateTime.utc(2026, 10, 1);
    await repo.setDiveStarGrade(
      shopId: id,
      grade: grade,
      reviewedAt: reviewed,
      expiresAt: reviewed.add(const Duration(days: 365)),
    );
  }
  if (status != ShopOperatingStatus.active) {
    repo.debugSetOperatingStatus(id, status);
  }
}

int _cardCount(WidgetTester tester, String grade) {
  final texts = tester.widgetList<Text>(
    find.descendant(
      of: find.byKey(Key('admin-partner-grade-$grade')),
      matching: find.byType(Text),
    ),
  );
  return int.parse(
    texts.map((text) => text.data).firstWhere((data) => int.tryParse(data ?? '') != null)!,
  );
}

void main() {
  testWidgets('등급 카드 합이 전체와 같고 활동중만 등급 칸에 나온다', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await _shop(repo, 'plain-reef');
    await _shop(repo, 'one-star', grade: 1);
    await _shop(repo, 'two-star', grade: 2);
    await _shop(repo, 'three-star', grade: 3);
    await _shop(repo, 'paused-star', grade: 2, status: ShopOperatingStatus.paused);
    await _shop(repo, 'ended-reef', status: ShopOperatingStatus.contractEnded);
    await _shop(repo, 'closed-star', grade: 1, status: ShopOperatingStatus.closed);

    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await store.refreshShopStats();

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AdminConsoleTheme.dark,
          home: const AdminPartnersRosterScreen(),
        ),
      ),
    );
    await tester.pump();

    final scroll = find.byKey(const Key('admin-partners-scroll'));
    expect(scroll, findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    expect(
      find.descendant(
        of: scroll,
        matching: find.byKey(const Key('admin-partner-grade-all')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: scroll, matching: find.byKey(const Key('admin-partners-search'))),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: scroll,
        matching: find.byKey(const Key('admin-partner-row-plain-reef')),
      ),
      findsOneWidget,
    );

    const grades = ['regular', 'star1', 'star2', 'star3', 'other'];
    final total = _cardCount(tester, 'all');
    final sum = grades.fold<int>(0, (sum, grade) => sum + _cardCount(tester, grade));
    expect(total, 8);
    expect(sum, total);
    expect(_cardCount(tester, 'regular'), 1);
    expect(_cardCount(tester, 'star1'), 1);
    expect(_cardCount(tester, 'star2'), 2);
    expect(_cardCount(tester, 'star3'), 1);
    expect(_cardCount(tester, 'other'), 3);

    const yellow = Color(0xFFFFE14A);
    for (final entry in const {'star1': 1, 'star2': 2, 'star3': 3}.entries) {
      final card = find.byKey(Key('admin-partner-grade-${entry.key}'));
      final icons = tester.widgetList<Icon>(
        find.descendant(of: card, matching: find.byIcon(Icons.star)),
      );
      expect(icons, hasLength(entry.value), reason: entry.key);
      for (final icon in icons) {
        expect(icon.color, yellow);
      }
      expect(
        find.descendant(of: card, matching: find.text('다이브스타')),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(
        of: find.byKey(const Key('admin-partner-grade-regular')),
        matching: find.text('일반파트너'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('admin-partner-grade-other')),
        matching: find.text('기타'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('admin-partner-grade-regular')),
        matching: find.byIcon(Icons.star),
      ),
      findsNothing,
    );

    const expected = {
      'regular': ['plain-reef'],
      'star1': ['one-star'],
      'star2': ['bohol-hideout', 'two-star'],
      'star3': ['three-star'],
      'other': ['paused-star', 'ended-reef', 'closed-star'],
    };
    const all = [
      'bohol-hideout',
      'plain-reef',
      'one-star',
      'two-star',
      'three-star',
      'paused-star',
      'ended-reef',
      'closed-star',
    ];

    for (final entry in expected.entries) {
      await tester.tap(find.byKey(Key('admin-partner-grade-${entry.key}')));
      await tester.pump();
      for (final id in all) {
        expect(
          find.byKey(Key('admin-partner-row-$id')),
          entry.value.contains(id) ? findsOneWidget : findsNothing,
          reason: '${entry.key} / $id',
        );
      }
    }
  });
}
