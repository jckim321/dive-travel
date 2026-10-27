import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/profile/presentation/my_crafted_trips_section.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  ShopProduct trip({
    String id = 'mine',
    String submittedByUid = 'me',
    ProductPublishStatus status = ProductPublishStatus.approved,
  }) {
    return ShopProduct(
      id: id,
      shopId: 's1',
      name: '내 여행',
      consumerPrice: 100000,
      professionalPrice: 80000,
      submittedByUid: submittedByUid,
      publishStatus: status,
      active: true,
    );
  }

  Future<void> pumpSection(
    WidgetTester tester, {
    required MemberGrade grade,
    String viewerUid = 'me',
    List<ShopProduct>? products,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: AppConstants.defaultLocale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MyCraftedTripsSection(
            products: products ?? [trip()],
            memberGrade: grade,
            viewerUid: viewerUid,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('골드는 본인 승인 여행의 빈자리 버튼이 보인다', (tester) async {
    await pumpSection(tester, grade: MemberGrade.gold);
    expect(find.byKey(const Key('crafted-open-seats-mine')), findsOneWidget);
  });

  testWidgets('실버는 빈자리 버튼이 숨는다', (tester) async {
    await pumpSection(tester, grade: MemberGrade.silver);
    expect(find.byKey(const Key('crafted-open-seats-mine')), findsNothing);
  });

  testWidgets('골드여도 승인 전이나 남의 여행은 빈자리 버튼이 숨는다', (tester) async {
    await pumpSection(
      tester,
      grade: MemberGrade.gold,
      products: [
        trip(id: 'pending', status: ProductPublishStatus.pending),
        trip(id: 'theirs', submittedByUid: 'other'),
      ],
    );
    expect(find.byKey(const Key('crafted-open-seats-pending')), findsNothing);
    expect(find.byKey(const Key('crafted-open-seats-theirs')), findsNothing);
  });
}
