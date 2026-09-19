import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/instructor_discount.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  Future<AppLocalizations> loadKo() {
    return AppLocalizations.delegate.load(const Locale('ko'));
  }

  test('승인하면 해당 유저의 강사 자격과 프로 인증이 완료된다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    expect(await repo.watchPendingInstructors().first, isNotEmpty);

    await repo.approveInstructor('test-user');
    final snapshot = await repo.watchDiver('test-user').first;
    expect(snapshot.stats.isInstructor, isTrue);
    expect(snapshot.stats.proStatus, ProVerificationStatus.approved);
  });

  test('게시글을 숨기면 공개 목록에서 빠진다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final before = await repo.watchCommunityPosts().first;
    expect(before.any((post) => !post.hidden), isTrue);

    await repo.setPostHidden(postId: 'seed-shop-bohol', hidden: true);
    final after = await repo.watchCommunityPosts().first;
    expect(
      after.firstWhere((post) => post.id == 'seed-shop-bohol').hidden,
      isTrue,
    );
  });

  test('관리자는 강사 할인을 비율 또는 금액으로 저장한다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.saveInstructorDiscount(
      const InstructorDiscount(
        kind: InstructorDiscountKind.amount,
        value: 15000,
      ),
    );
    final saved = await repo.watchInstructorDiscount().first;
    expect(saved.kind, InstructorDiscountKind.amount);
    expect(saved.value, 15000);
  });

  test('스타 충족 샵은 현판 발송 요청 상태로 바꿀 수 있다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.setPlaqueStatus(
      shopId: 'bohol-hideout',
      status: PlaqueStatus.queued,
    );
    final stats = await repo.watchShopStats().first;
    expect(
      stats.firstWhere((item) => item.shopId == 'bohol-hideout').plaqueStatus,
      PlaqueStatus.queued,
    );
  });

  testWidgets('마이페이지에서 PIN 9118으로 관리자 대시보드에 들어간다', (tester) async {
    await tester.pumpWidget(
      DiveTravelApp(
        firebaseReady: true,
        repository: MemoryDiverRepository.forTest(isAdmin: true),
      ),
    );
    await tester.pump();
    await tester.pump();
    final l10n = await loadKo();

    await tester.tap(find.text(l10n.navProfile));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('open-admin-mode')), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-admin-mode')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('admin-pin-field')),
      AppConstants.adminPin,
    );
    await tester.tap(find.byKey(const Key('admin-pin-submit')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.adminDashboardTitle), findsOneWidget);
    expect(find.byKey(const Key('admin-menu-instructors')), findsOneWidget);
    expect(find.byKey(const Key('admin-menu-shops')), findsOneWidget);
    expect(find.byKey(const Key('admin-menu-pricing')), findsOneWidget);
    expect(find.byKey(const Key('admin-menu-posts')), findsOneWidget);
  });
}
