import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
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
  List<ShopProductOption> options = const [],
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
    options: options,
  );
}

Future<AppLocalizations> _pumpCard(
  WidgetTester tester,
  ShopProduct product,
) async {
  final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
  await tester.pumpWidget(
    PartnerTheme.wrap(
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
    ),
  );
  await tester.pump();
  return l10n;
}

void main() {
  testWidgets('게시중: 가격·닫기·빈자리 활성', (tester) async {
    final l10n = await _pumpCard(
      tester,
      _product(id: 'live-1', consumerPrice: 150000),
    );

    expect(find.byKey(const Key('partner-product-live-1')), findsOneWidget);
    expect(find.text(l10n.partnerProductBadgeBasic), findsOneWidget);
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
    expect(find.text(l10n.partnerProductMenuSeats), findsOneWidget);
    expect(find.byKey(const Key('partner-product-close-live-1')), findsOneWidget);
    expect(
      find.byKey(const Key('partner-product-seats-hint-live-1')),
      findsNothing,
    );
  });

  testWidgets('작성 중: 이어서 작성·빈자리 비활성·초안 안내', (tester) async {
    final l10n = await _pumpCard(
      tester,
      _product(
        id: 'pend-1',
        publish: ProductPublishStatus.pending,
        active: false,
      ),
    );

    expect(find.text(l10n.partnerProductBadgeDrafting), findsOneWidget);
    expect(find.text(l10n.partnerProductContinueDraft), findsOneWidget);
    expect(find.text(l10n.partnerProductDraftHiddenHint), findsOneWidget);
    final seats = tester.widget<FilledButton>(
      find.byKey(const Key('partner-product-seats-pend-1')),
    );
    expect(seats.onPressed, isNull);
    expect(
      find.byKey(const Key('partner-product-close-pend-1')),
      findsNothing,
    );
  });

  testWidgets('닫힘: 다시 열기·빈자리 비활성', (tester) async {
    final l10n = await _pumpCard(
      tester,
      _product(id: 'closed-1', active: false),
    );

    expect(find.text(l10n.partnerProductBadgeClosed), findsOneWidget);
    expect(find.text(l10n.partnerProductReopen), findsOneWidget);
    final seats = tester.widget<FilledButton>(
      find.byKey(const Key('partner-product-seats-closed-1')),
    );
    expect(seats.onPressed, isNull);
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
  });

  testWidgets('개별·옵션 줄과 폐기 버튼', (tester) async {
    final l10n = await _pumpCard(
      tester,
      _product(
        id: 'lines-1',
        options: [
          ShopProductOption(
            id: 'ind-1',
            name: '원데이',
            kind: ProductOptionKind.individual,
            consumerPrice: 80000,
            professionalPrice: 80000,
          ),
          ShopProductOption(
            id: 'add-1',
            name: '픽업',
            kind: ProductOptionKind.addon,
            consumerPrice: 20000,
            professionalPrice: 20000,
          ),
        ],
      ),
    );

    expect(find.text(l10n.bookingEntryIndividuals), findsOneWidget);
    expect(find.text(l10n.productFormSectionOptions), findsOneWidget);
    expect(find.byKey(const Key('partner-option-line-ind-1')), findsOneWidget);
    expect(find.byKey(const Key('partner-option-line-add-1')), findsOneWidget);
    expect(find.byKey(const Key('partner-option-discard-ind-1')), findsOneWidget);
    expect(find.text(l10n.partnerProductDiscard), findsNWidgets(2));
  });

  testWidgets('같은배 라이브 줄 + 빈자리 관리', (tester) async {
    final l10n = await _pumpCard(
      tester,
      _product(
        id: 'live-sb',
        sameBoat: SameBoatStatus.approved,
        openEmptySeats: true,
        capacity: 10,
        bookedSeats: 3,
        departure: DateTime(2026, 11, 20),
      ),
    );

    expect(
      find.text(l10n.partnerProductSameBoatLive(7, '2026.11.20')),
      findsOneWidget,
    );
    expect(find.text(l10n.partnerProductSeatsManage), findsOneWidget);
  });
}
