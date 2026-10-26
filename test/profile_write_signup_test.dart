import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/auth/pending_profile.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/member_profile_repair.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/models/app_user.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/features/auth/presentation/profile_write_debug_footer.dart';

void main() {
  late PendingProfileStore previous;

  setUp(() {
    previous = pendingProfileWrites;
    pendingProfileWrites = MemoryPendingProfileStore();
  });

  tearDown(() {
    pendingProfileWrites = previous;
  });

  test('등급이 없으면 읽을 때 실버다', () {
    expect(MemberGrade.parse(null), MemberGrade.silver);
    expect(
      memberProfileRepairPatch(
        gradeMissing: true,
        existingEmail: '',
        existingName: '',
        email: 'reef@dive.test',
        displayName: '리프',
        uid: 'uid-1',
      ),
      {
        'member_grade': 'silver',
        'email': 'reef@dive.test',
        'display_name': '리프',
      },
    );
    expect(
      memberProfileRepairPatch(
        gradeMissing: false,
        existingEmail: 'reef@dive.test',
        existingName: '리프',
        email: 'other@dive.test',
        displayName: '다른',
        uid: 'uid-1',
      ),
      isEmpty,
    );
  });

  test('가입 중에는 로그인 감지가 프로필을 다시 쓰지 않는다', () async {
    final repo = MemoryDiverRepository();
    final session = SessionController(repo);
    addTearDown(session.dispose);
    await session.signUp(
      email: 'once@dive.test',
      password: 'secret12',
      displayName: '한 번',
      loginId: 'onceid',
    );
    await pumpEventQueue();
    expect(repo.debugEnsureCount, 2);
    expect(session.error, isNull);
    expect(session.isSignedIn, isTrue);
  });

  test('프로필 쓰기가 실패해도 가입은 끝나고, 다음 로그인에서 채운다', () async {
    final repo = MemoryDiverRepository();
    repo.debugFailSignupProfile = true;
    final session = SessionController(repo);
    addTearDown(session.dispose);
    const email = 'later@dive.test';
    await session.signUp(
      email: email,
      password: 'secret12',
      displayName: '나중',
      loginId: 'laterid',
      nationality: 'KR',
      birthDate: '1992-03-04',
      phone: '01011112222',
      termsAccepted: true,
      privacyAccepted: true,
    );
    await pumpEventQueue();

    expect(session.error, isNull);
    expect(session.isSignedIn, isTrue);
    expect(session.profileWriteNote, '(permission-denied / users/memory-${email.hashCode})');
    final uid = session.user!.uid;
    expect((await repo.watchDiver(uid).first).stats.phone, isEmpty);

    await session.signOut();
    await session.signIn(email: email, password: 'secret12');
    final filled = await repo.watchDiver(uid).first;
    expect(filled.stats.phone, '01011112222');
    expect(filled.stats.birthDate, '1992-03-04');
    expect(filled.stats.nationality, 'KR');
    expect(filled.stats.nationalityConsentAt, isNotNull);
  });

  test('프로필 만들기는 빈 등급·이메일·이름만 채운다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.ensureUserDocument(
      const AppUser(uid: 'blank', email: '', displayName: ''),
    );
    repo.debugMissingGradeUids.add('blank');
    await repo.adminRepairMemberProfile(
      uid: 'blank',
      email: 'blank@dive.test',
      displayName: '블랭크',
    );
    expect(repo.debugLastRepair, {
      'member_grade': 'silver',
      'email': 'blank@dive.test',
      'display_name': '블랭크',
    });
    final filled = (await repo.fetchMembers()).firstWhere((item) => item.uid == 'blank');
    expect(filled.email, 'blank@dive.test');
    expect(filled.displayName, '블랭크');
    expect(filled.grade, MemberGrade.silver);

    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await pumpEventQueue();
    await store.ensureMemberProfile(filled);
    expect(repo.debugLastRepair, isEmpty);
    expect(
      (await repo.fetchMembers()).firstWhere((item) => item.uid == 'blank').displayName,
      '블랭크',
    );
  });

  testWidgets('숨긴 오류 코드는 관리자 화면 하단에만 보인다', (tester) async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    repo.debugFailSignupProfile = true;
    final session = SessionController(repo);
    final store = DiverStore(repo);
    addTearDown(session.dispose);
    addTearDown(store.dispose);
    await session.signUp(
      email: 'admin-new@dive.test',
      password: 'secret12',
      displayName: '관리',
    );

    await tester.pumpWidget(
      SessionScope(
        session: session,
        child: DiverStoreScope(
          store: store,
          child: const MaterialApp(
            home: ProfileWriteDebugFooter(child: Scaffold(body: SizedBox.expand())),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('profile-write-debug')), findsOneWidget);
    expect(find.textContaining('permission-denied / users/'), findsOneWidget);
    expect(find.textContaining('프로필을 쓰지'), findsNothing);

    final customer = MemoryDiverRepository();
    customer.debugFailSignupProfile = true;
    final customerSession = SessionController(customer);
    final customerStore = DiverStore(customer);
    addTearDown(customerSession.dispose);
    addTearDown(customerStore.dispose);
    await customerSession.signUp(
      email: 'guest@dive.test',
      password: 'secret12',
      displayName: '손님',
    );
    await tester.pumpWidget(
      SessionScope(
        session: customerSession,
        child: DiverStoreScope(
          store: customerStore,
          child: const MaterialApp(
            home: ProfileWriteDebugFooter(child: Scaffold(body: SizedBox.expand())),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(customerSession.profileWriteNote, isNotNull);
    expect(find.byKey(const Key('profile-write-debug')), findsNothing);
  });
}
