import 'package:dive_travel_app/core/models/product_content_fingerprint.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/workbench_price_validation.dart';

/// Shared publish approve/reject guards (API + UI).
abstract final class ProductPublishGuard {
  /// Shown when admin tries to approve a product with no diver price.
  static const missingPriceMessage = '가격을 입력한 상품만 승인할 수 있어요';

  /// Shown when any unit price is above the workbench cap.
  static const overCapPriceMessage = '1억 원을 넘는 가격이 있어 승인할 수 없어요';

  /// Shown when reject is attempted without a note.
  static const emptyRejectNoteMessage = '반려 사유를 입력해 주세요';

  static bool hasDiverPrice(ShopProduct product) => product.consumerPrice > 0;

  /// Diver price present and within the 1억 unit cap; no option over the cap.
  static bool hasValidPricesForApprove(ShopProduct product) {
    if (!isWorkbenchUnitPriceAllowed(product.consumerPrice)) {
      return false;
    }
    for (final option in product.options) {
      if (option.consumerPrice > kWorkbenchPriceMaxValue ||
          option.professionalPrice > kWorkbenchPriceMaxValue) {
        return false;
      }
    }
    return true;
  }

  static void ensureCanApprove(ShopProduct product) {
    if (!hasDiverPrice(product)) {
      throw StateError(missingPriceMessage);
    }
    if (!hasValidPricesForApprove(product)) {
      throw StateError(overCapPriceMessage);
    }
  }

  static void ensureRejectNote(String reviewNote) {
    if (reviewNote.trim().isEmpty) {
      throw StateError(emptyRejectNoteMessage);
    }
  }

  /// Apply approve/reject side effects used by repository status updates.
  static ShopProduct applyStatusChange({
    required ShopProduct product,
    required ProductPublishStatus status,
    String reviewNote = '',
  }) {
    final now = DateTime.now();
    switch (status) {
      case ProductPublishStatus.approved:
        ensureCanApprove(product);
        return product.copyWith(
          publishStatus: status,
          active: true,
          reviewedAt: now,
          reviewNote: '',
          rejectedContentHash: '',
          resubmitCount: 0,
          resubmitNote: '',
        );
      case ProductPublishStatus.rejected:
        ensureRejectNote(reviewNote);
        return product.copyWith(
          publishStatus: status,
          active: false,
          reviewedAt: now,
          reviewNote: reviewNote.trim(),
          rejectedContentHash: productContentFingerprint(product),
          resubmitNote: '',
        );
      case ProductPublishStatus.pending:
      case ProductPublishStatus.draft:
        return product.copyWith(
          publishStatus: status,
          active: false,
          reviewedAt: now,
        );
    }
  }
}
