import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/partner_provision.dart';
import 'package:dive_travel_app/core/models/app_user.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_members_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  test('a generated password is 12 characters', () {
    expect(generatePartnerPassword().length, 12);
  });

  test('fixPartnerShopHull keeps the partner and drops the product suffix', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.promoteMemberToPartner(
      uid: 'guest',
      shopId: 'foo--bar',
      actorUid: 'admin',
      actorName: 'Admin',
    );
    await repo.fixPartnerShopHull(
      uid: 'guest',
      shopId: 'foo--bar',
      actorUid: 'admin',
      actorName: 'Admin',
    );
    final member = (await repo.fetchMembers()).firstWhere((item) => item.uid == 'guest');
    expect(member.isBusiness, isTrue);
    expect(member.ownedShopId, 'foo');
    expect(member.ownedShopId.contains('--'), isFalse);
    final last = repo.roleHistoryFor('guest').last;
    expect(last['action'], 'fix_shop_hull');
    expect(last['shop_id'], 'foo');
  });

  testWidgets('empty create form cannot submit, then the card shows the password', (tester) async {
    final harness = await _pumpMembers(tester);
    await tester.tap(find.byKey(const Key('admin-create-partner')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      tester.widget<FilledButton>(find.byKey(const Key('admin-create-partner-submit'))).onPressed,
      isNull,
    );

    await tester.enterText(find.byKey(const Key('admin-create-partner-shop')), 'Ocean Dive');
    await tester.enterText(find.byKey(const Key('admin-create-partner-login')), 'ocean01');
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('admin-create-partner-submit'))).onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('admin-create-partner-generate')));
    await tester.pump();
    final password = tester
        .widget<TextField>(find.byKey(const Key('admin-create-partner-password')))
        .controller!
        .text;
    expect(password.length, 12);

    await tester.tap(find.byKey(const Key('admin-create-partner-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('admin-create-partner-card')), findsOneWidget);
    expect(find.text('아이디 ocean01'), findsOneWidget);
    expect(find.text('임시 비밀번호 $password'), findsOneWidget);
    expect(find.byKey(const Key('admin-create-partner-copy')), findsOneWidget);
    expect(find.text('이미 있는 아이디예요, 비밀번호는 바뀌지 않아요'), findsNothing);

    await tester.tap(find.text('닫기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('admin-create-partner-card')), findsNothing);
    expect(find.text('임시 비밀번호 $password'), findsNothing);

    harness.dispose();
  });

  testWidgets('an existing login says the password does not change', (tester) async {
    final harness = await _pumpMembers(tester);
    await harness.repo.ensureUserDocument(
      const AppUser(uid: 'ocean-user', email: 'ocean01@users.dive-travel.app', displayName: '바다'),
      loginId: 'ocean01',
    );
    await harness.store.ensureAdminInboxLoaded();
    await tester.pump();

    await tester.tap(find.byKey(const Key('admin-create-partner')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const Key('admin-create-partner-shop')), 'Ocean Dive');
    await tester.enterText(find.byKey(const Key('admin-create-partner-login')), 'ocean01');
    await tester.enterText(find.byKey(const Key('admin-create-partner-password')), 'wave-pass-1');
    await tester.pump();
    await tester.tap(find.byKey(const Key('admin-create-partner-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('이미 있는 아이디예요, 비밀번호는 바뀌지 않아요'), findsOneWidget);
    expect(find.text('임시 비밀번호 wave-pass-1'), findsNothing);
    harness.dispose();
  });

  testWidgets('a failed promote still shows the new password once', (tester) async {
    final harness = await _pumpMembers(tester);
    harness.repo.debugFailNextPartnerPromote = true;
    await tester.tap(find.byKey(const Key('admin-create-partner')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const Key('admin-create-partner-shop')), 'Ocean Dive');
    await tester.enterText(find.byKey(const Key('admin-create-partner-login')), 'ocean02');
    await tester.enterText(find.byKey(const Key('admin-create-partner-password')), 'wave-pass-2');
    await tester.pump();
    await tester.tap(find.byKey(const Key('admin-create-partner-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('admin-create-partner-failure')), findsOneWidget);
    expect(find.textContaining('계정은 만들어졌어요'), findsOneWidget);
    expect(find.text('임시 비밀번호 wave-pass-2'), findsOneWidget);
    harness.dispose();
  });

  testWidgets('several shops ask for a choice before creating', (tester) async {
    final harness = await _pumpMembers(tester);
    harness.repo.seedShopName('blue', 'Blue');
    harness.repo.seedShopName('blue-west', 'Blue');
    await tester.tap(find.byKey(const Key('admin-create-partner')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const Key('admin-create-partner-shop')), 'Blue');
    await tester.enterText(find.byKey(const Key('admin-create-partner-login')), 'blue01');
    await tester.enterText(find.byKey(const Key('admin-create-partner-password')), 'wave-pass-1');
    await tester.pump();
    await tester.tap(find.byKey(const Key('admin-create-partner-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('admin-partner-choice-blue')), findsOneWidget);
    expect(find.byKey(const Key('admin-partner-choice-blue-west')), findsOneWidget);
    expect(harness.repo.partnerAuthCreateCount, 0);

    await tester.tap(find.byKey(const Key('admin-partner-choice-blue')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('admin-create-partner-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('admin-create-partner-card')), findsOneWidget);
    expect(harness.repo.partnerAuthCreateCount, 1);
    final member = (await harness.repo.fetchMembers()).firstWhere(
      (item) => item.loginId == 'blue01',
    );
    expect(member.ownedShopId, 'blue');
    harness.dispose();
  });

  testWidgets('a listing shop id can be corrected to its hull', (tester) async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.promoteMemberToPartner(
      uid: 'guest',
      shopId: 'foo--bar',
      actorUid: 'admin',
      actorName: 'Admin',
    );
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await tester.pumpWidget(_app(store, const AdminMemberDetailScreen(uid: 'guest')));
    await tester.pump();
    await store.ensureAdminInboxLoaded();
    await tester.pump();

    expect(find.byKey(const Key('admin-member-fix-hull-guest')), findsOneWidget);
    await tester.tap(find.byKey(const Key('admin-member-fix-hull-guest')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('admin-fix-hull-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('admin-member-fix-hull-guest')), findsNothing);
    final member = (await repo.fetchMembers()).firstWhere((item) => item.uid == 'guest');
    expect(member.ownedShopId, 'foo');
  });
}

class _Harness {
  _Harness(this.repo, this.store);
  final MemoryDiverRepository repo;
  final DiverStore store;
  void dispose() => store.dispose();
}

Future<_Harness> _pumpMembers(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repo = MemoryDiverRepository.forTest(isAdmin: true);
  final store = DiverStore(repo);
  await tester.pumpWidget(_app(store, const AdminMembersScreen()));
  await tester.pump();
  await store.ensureAdminInboxLoaded();
  await tester.pump();
  return _Harness(repo, store);
}

Widget _app(DiverStore store, Widget home) {
  return DiverStoreScope(
    store: store,
    child: MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AdminConsoleTheme.dark,
      home: home,
    ),
  );
}
