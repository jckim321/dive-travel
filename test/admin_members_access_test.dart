import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';

void main() {
  test('로그인하면 users 목록에 계정이 생기고, 탈퇴·차단은 바로 로그아웃된다', () async {
    final repo = MemoryDiverRepository();
    await repo.signIn(email: 'sea@dive.test', password: 'secret12');
    final user = await repo.currentAuthUser();
    expect(user, isNotNull);
    final members = await repo.fetchMembers();
    expect(members.map((m) => m.uid), contains(user!.uid));

    await repo.withdrawMember(user.uid);
    expect((await repo.fetchMembers()).single.displayName, isEmpty);
    await repo.signOut();

    final session = SessionController(repo);
    addTearDown(session.dispose);
    await expectLater(
      session.signIn(email: 'sea@dive.test', password: 'secret12'),
      throwsA(isA<StateError>()),
    );
    expect(session.isSignedIn, isFalse);

    final again = MemoryDiverRepository();
    await again.signIn(email: 'wave@dive.test', password: 'secret12');
    final uid = (await again.currentAuthUser())!.uid;
    await again.setAccountBlocked(uid: uid, blocked: true);
    await again.signOut();
    final blocked = SessionController(again);
    addTearDown(blocked.dispose);
    await expectLater(
      blocked.signIn(email: 'wave@dive.test', password: 'secret12'),
      throwsA(isA<StateError>()),
    );
    expect(blocked.isSignedIn, isFalse);
  });

  test('본인과 마지막 관리자는 해제할 수 없다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final self = (await repo.currentAuthUser())!.uid;
    await expectLater(
      repo.setMemberAdmin(uid: self, admin: false, actorUid: self),
      throwsA(isA<StateError>()),
    );

    await repo.signIn(email: 'other@dive.test', password: 'secret12');
    final other = (await repo.currentAuthUser())!.uid;
    await repo.setMemberAdmin(uid: other, admin: true, actorUid: self);
    await repo.setMemberAdmin(uid: other, admin: false, actorUid: self);
    final members = await repo.fetchMembers();
    expect(members.singleWhere((m) => m.uid == other).isAdmin, isFalse);
    expect(members.singleWhere((m) => m.uid == self).isAdmin, isTrue);
    await expectLater(
      repo.setMemberAdmin(uid: self, admin: false, actorUid: other),
      throwsA(
        predicate((Object e) => e is StateError && e.message == 'ADMIN_LAST'),
      ),
    );
  });
}
