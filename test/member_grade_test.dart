import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/core/auth/device_pin_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

import 'support/device_pin_test_helpers.dart';

void main() {
  test('구매 횟수만으로 등급이 정해진다', () {
    expect(MemberGrade.parse(null), MemberGrade.silver);
    expect(
      MemberGrade.fromActivity(paidPurchases: 2, reviews: 99),
      MemberGrade.silver,
    );
    expect(
      MemberGrade.fromActivity(paidPurchases: 3, reviews: 0),
      MemberGrade.gold,
    );
    expect(
      MemberGrade.fromActivity(paidPurchases: 9, reviews: 0),
      MemberGrade.gold,
    );
    expect(
      MemberGrade.fromActivity(paidPurchases: 10, reviews: 0),
      MemberGrade.diamond,
    );
    expect(
      MemberGrade.fromActivity(paidPurchases: 19, reviews: 0),
      MemberGrade.diamond,
    );
    expect(
      MemberGrade.fromActivity(paidPurchases: 20, reviews: 0),
      MemberGrade.platinum,
    );
    expect(
      MemberGrade.deficitToNext(
        current: MemberGrade.silver,
        paidPurchases: 1,
        reviews: 4,
      ),
      (2, 0),
    );
    expect(
      MemberGrade.deficitToNext(
        current: MemberGrade.diamond,
        paidPurchases: 10,
        reviews: 0,
      ),
      (10, 0),
    );
  });

  test('관리자는 회원 등급만 바꾼다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final before = await repo.watchMembers().first;
    expect(before, isNotEmpty);

    await repo.setMemberGrade(
      uid: 'pending-instructor',
      grade: MemberGrade.diamond,
    );
    final after = await repo.watchMembers().first;
    final member = after.firstWhere((item) => item.uid == 'pending-instructor');
    expect(member.grade, MemberGrade.diamond);
    expect(member.gradeLocked, isTrue);
  });

  test('결제 1건만 등급을 올리고 후기와 잠금은 등급을 건드리지 않는다', () async {
    final repo = MemoryDiverRepository.forTest();
    final past = DateTime.now().subtract(const Duration(days: 3));
    Future<void> pay() {
      return repo.createBooking(
        uid: 'test-user',
        shopId: 'grade-shop',
        shopName: '샵',
        productName: '펀다이빙',
        price: 1000,
        tourDate: past,
        status: BookingStatus.confirmed,
        paymentStatus: PaymentStatus.captured,
      );
    }

    await pay();
    await pay();
    var member = (await repo.fetchMembers()).firstWhere((m) => m.uid == 'test-user');
    expect(member.grade, MemberGrade.silver);
    expect(member.paidPurchaseCount, 2);

    final booking = (await repo.watchBookings('test-user').first).first;
    await repo.submitOperationReview(
      uid: 'test-user',
      shopId: booking.shopId,
      bookingId: booking.id,
      safety: 5,
      guide: 5,
      boat: 5,
    );
    member = (await repo.fetchMembers()).firstWhere((m) => m.uid == 'test-user');
    expect(member.grade, MemberGrade.silver);
    expect(member.reviewCount, 1);
    expect(member.isInstructor, isFalse);

    await pay();
    member = (await repo.fetchMembers()).firstWhere((m) => m.uid == 'test-user');
    expect(member.grade, MemberGrade.gold);
    expect(member.paidPurchaseCount, 3);

    final review = (await repo.listMyReviews('test-user')).first;
    await repo.deleteOperationReview(
      uid: 'test-user',
      shopId: booking.shopId,
      reviewId: review.id,
    );
    member = (await repo.fetchMembers()).firstWhere((m) => m.uid == 'test-user');
    expect(member.grade, MemberGrade.gold);
    expect(member.reviewCount, 0);

    await repo.approveInstructor('test-user');
    member = (await repo.fetchMembers()).firstWhere((m) => m.uid == 'test-user');
    expect(member.isInstructor, isTrue);
    expect(member.grade, MemberGrade.gold);

    final locked = MemoryDiverRepository.forTest();
    await locked.setMemberGrade(uid: 'test-user', grade: MemberGrade.silver);
    await locked.createBooking(
      uid: 'test-user',
      shopId: 'grade-shop',
      shopName: '샵',
      productName: '펀다이빙',
      price: 1000,
      tourDate: past,
      status: BookingStatus.confirmed,
      paymentStatus: PaymentStatus.captured,
    );
    await locked.createBooking(
      uid: 'test-user',
      shopId: 'grade-shop',
      shopName: '샵',
      productName: '펀다이빙',
      price: 1000,
      tourDate: past,
      status: BookingStatus.confirmed,
      paymentStatus: PaymentStatus.captured,
    );
    await locked.createBooking(
      uid: 'test-user',
      shopId: 'grade-shop',
      shopName: '샵',
      productName: '펀다이빙',
      price: 1000,
      tourDate: past,
      status: BookingStatus.confirmed,
      paymentStatus: PaymentStatus.captured,
    );
    final held = (await locked.fetchMembers()).firstWhere((m) => m.uid == 'test-user');
    expect(held.gradeLocked, isTrue);
    expect(held.grade, MemberGrade.silver);
    expect(held.paidPurchaseCount, 3);
  });

  testWidgets('관리자 대시보드에 회원 관리 메뉴가 있다', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      DiveTravelApp(
        firebaseReady: true,
        repository: MemoryDiverRepository.forTest(isAdmin: true),
        devicePinStore: MemoryDevicePinStore(),
      ),
    );
    await tester.pump();
    await tester.pump();
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tester.tap(find.text(l10n.navProfile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-profile-settings')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('profile-settings-scroll')),
      const Offset(0, -560),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open-admin-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-admin-mode')));
    await tester.pumpAndSettle();
    await completeDevicePinIfAsked(tester);

    expect(find.byKey(const Key('admin-menu-members')), findsOneWidget);
    await tester.tap(find.byKey(const Key('admin-menu-members')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.adminMembersTitle), findsWidgets);
    expect(find.text('대기 강사'), findsOneWidget);
  });

  test('표시 등급은 저장된 회원 등급을 따른다', () {
    expect(
      ProfileDisplayGrade.fromMember(
        grade: MemberGrade.silver,
        isInstructor: false,
      ),
      ProfileDisplayGrade.silver,
    );
    expect(
      ProfileDisplayGrade.fromMember(
        grade: MemberGrade.gold,
        isInstructor: false,
      ),
      ProfileDisplayGrade.gold,
    );
    expect(
      ProfileDisplayGrade.fromMember(
        grade: MemberGrade.silver,
        isInstructor: true,
      ),
      ProfileDisplayGrade.instructor,
    );
  });

  test('강사는 저장 등급 칸에서 빠지고 다섯 칸 합은 전체 인원과 같다', () {
    final counts = countDisplayGrades(const [
      (grade: MemberGrade.silver, isInstructor: true),
      (grade: MemberGrade.platinum, isInstructor: true),
      (grade: MemberGrade.gold, isInstructor: false),
      (grade: MemberGrade.platinum, isInstructor: false),
    ]);
    expect(counts[ProfileDisplayGrade.silver], 0);
    expect(counts[ProfileDisplayGrade.gold], 1);
    expect(counts[ProfileDisplayGrade.diamond], 0);
    expect(counts[ProfileDisplayGrade.platinum], 1);
    expect(counts[ProfileDisplayGrade.instructor], 2);
    final total = counts.values.fold<int>(0, (sum, value) => sum + value);
    expect(total, 4);
    expect(counts.length, ProfileDisplayGrade.values.length);
  });
}
