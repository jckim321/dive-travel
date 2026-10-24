import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/partner/presentation/widgets/partner_product_card.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

ShopProduct _product({
  required String id,
  String name = '상품',
  ProductPublishStatus publish = ProductPublishStatus.approved,
  bool active = true,
  int consumerPrice = 150000,
  SameBoatStatus sameBoat = SameBoatStatus.closed,
  bool openEmptySeats = false,
  int capacity = 0,
  int bookedSeats = 0,
  DateTime? departure,
  String reviewNote = '',
  int resubmitCount = 0,
}) {
  return ShopProduct(
    id: id,
    shopId: 'shop-a',
    name: name,
    consumerPrice: consumerPrice,
    professionalPrice: consumerPrice,
    active: active,
    publishStatus: publish,
    sameBoatStatus: sameBoat,
    openEmptySeats: openEmptySeats,
    capacity: capacity,
    bookedSeats: bookedSeats,
    departureStart: departure,
    reviewNote: reviewNote,
    resubmitCount: resubmitCount,
  );
}

Future<AppLocalizations> _pumpCard(
  WidgetTester tester,
  ShopProduct product,
) async {
  final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: AppConstants.defaultLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: PartnerProductCard(
            product: product,
            shopId: product.shopId,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return l10n;
}

void main() {
  testWidgets('게시중: 가격 천단위·빈자리 버튼 활성·힌트 없음', (tester) async {
    final l10n = await _pumpCard(
      tester,
      _product(id: 'live-1', consumerPrice: 150000),
    );

    expect(find.byKey(const Key('partner-product-live-1')), findsOneWidget);
    expect(
      find.byKey(const Key('partner-product-status-live-1')),
      findsOneWidget,
    );
    expect(find.text(l10n.partnerProductBadgeListed), findsOneWidget);
    expect(
      find.text(l10n.partnerProductPriceLine('150,000')),
      findsOneWidget,
    );
    expect(find.text(l10n.partnerProductSameBoatNotOpened), findsOneWidget);

    final seats = tester.widget<FilledButton>(
      find.byKey(const Key('partner-product-seats-live-1')),
    );
    expect(seats.onPressed, isNotNull);
    expect(find.text(l10n.sameBoatSeatsTitle), findsOneWidget);
    expect(
      find.byKey(const Key('partner-product-seats-hint-live-1')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('partner-product-delete-live-1')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('partner-product-resubmit-live-1')),
      findsNothing,
    );
  });

  testWidgets('승인 대기: 빈자리 비활성 + 이유, 삭제/재요청 없음', (tester) async {
    final l10n = await _pumpCard(
      tester,
      _product(
        id: 'pend-1',
        publish: ProductPublishStatus.pending,
        active: false,
      ),
    );

    expect(find.text(l10n.partnerProductBadgePending), findsOneWidget);
    final seats = tester.widget<FilledButton>(
      find.byKey(const Key('partner-product-seats-pend-1')),
    );
    expect(seats.onPressed, isNull);
    expect(
      find.byKey(const Key('partner-product-seats-hint-pend-1')),
      findsOneWidget,
    );
    expect(find.text(l10n.sameBoatSeatsNoProducts), findsOneWidget);
    expect(
      find.byKey(const Key('partner-product-delete-pend-1')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('partner-product-resubmit-pend-1')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('partner-product-edit-pend-1')),
      findsOneWidget,
    );
  });

  testWidgets('반려: 사유·재요청·삭제 표시, 빈자리 비활성', (tester) async {
    final l10n = await _pumpCard(
      tester,
      _product(
        id: 'rej-1',
        publish: ProductPublishStatus.rejected,
        active: false,
        reviewNote: '사진이 부족합니다',
      ),
    );

    expect(find.text(l10n.partnerProductBadgeRejected), findsOneWidget);
    expect(
      find.byKey(const Key('partner-product-review-note-rej-1')),
      findsOneWidget,
    );
    expect(find.text('사진이 부족합니다'), findsOneWidget);
    expect(
      find.byKey(const Key('partner-product-resubmit-rej-1')),
      findsOneWidget,
    );
    expect(find.text(l10n.partnerProductResubmit), findsOneWidget);
    expect(
      find.byKey(const Key('partner-product-delete-rej-1')),
      findsOneWidget,
    );
    final seats = tester.widget<FilledButton>(
      find.byKey(const Key('partner-product-seats-rej-1')),
    );
    expect(seats.onPressed, isNull);
  });

  testWidgets('재요청 회차 표시', (tester) async {
    final l10n = await _pumpCard(
      tester,
      _product(
        id: 'resub-1',
        publish: ProductPublishStatus.pending,
        active: false,
        resubmitCount: 2,
      ),
    );

    expect(
      find.byKey(const Key('partner-product-resubmit-count-resub-1')),
      findsOneWidget,
    );
    expect(find.text(l10n.partnerResubmitCount(2)), findsOneWidget);
  });

  testWidgets('닫힘: 빈자리 비활성', (tester) async {
    final l10n = await _pumpCard(
      tester,
      _product(id: 'closed-1', active: false),
    );

    expect(find.text(l10n.partnerProductBadgeClosed), findsOneWidget);
    final seats = tester.widget<FilledButton>(
      find.byKey(const Key('partner-product-seats-closed-1')),
    );
    expect(seats.onPressed, isNull);
    expect(
      find.byKey(const Key('partner-product-seats-hint-closed-1')),
      findsOneWidget,
    );
  });

  testWidgets('가격 0원이면 미입력 뱃지', (tester) async {
    final l10n = await _pumpCard(
      tester,
      _product(id: 'zero-1', consumerPrice: 0),
    );

    expect(
      find.byKey(const Key('partner-product-missing-price-zero-1')),
      findsOneWidget,
    );
    expect(find.text(l10n.partnerProductBadgeMissingPrice), findsOneWidget);
    expect(find.text(l10n.partnerProductPriceLine('0')), findsOneWidget);
  });

  testWidgets('게시중 + 같은배 승인 대기 동시 표시, 빈자리 버튼은 활성(관리)', (
    tester,
  ) async {
    final l10n = await _pumpCard(
      tester,
      _product(
        id: 'mix-1',
        sameBoat: SameBoatStatus.pending,
        openEmptySeats: true,
        capacity: 8,
        departure: DateTime(2026, 12, 1),
      ),
    );

    expect(find.text(l10n.partnerProductBadgeListed), findsOneWidget);
    expect(find.text(l10n.partnerProductSameBoatPending), findsOneWidget);
    final seats = tester.widget<FilledButton>(
      find.byKey(const Key('partner-product-seats-mix-1')),
    );
    expect(seats.onPressed, isNotNull);
    expect(find.text(l10n.partnerProductSeatsManage), findsOneWidget);
    expect(
      find.byKey(const Key('partner-product-seats-hint-mix-1')),
      findsNothing,
    );
  });

  testWidgets('같은배 라이브 줄: 빈자리·출발일', (tester) async {
    final l10n = await _pumpCard(
      tester,
      _product(
        id: 'live-sb',
        sameBoat: SameBoatStatus.approved,
        openEmptySeats: true,
        capacity: 10,
        bookedSeats: 3,
        departure: DateTime(2026, 11, 15),
      ),
    );

    expect(
      find.text(l10n.partnerProductSameBoatLive(7, '2026.11.15')),
      findsOneWidget,
    );
    expect(find.text(l10n.partnerProductSeatsManage), findsOneWidget);
  });
}
