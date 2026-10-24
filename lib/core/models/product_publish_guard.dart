import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/models/product_content_fingerprint.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/workbench_price_validation.dart';

/// Fixed reject-reason tag codes (admin multi-select).
abstract final class ProductRejectTags {
  static const photos = 'photos';
  static const price = 'price';
  static const copy = 'copy';
  static const schedule = 'schedule';
  static const options = 'options';
  static const other = 'other';

  static const all = <String>[
    photos,
    price,
    copy,
    schedule,
    options,
    other,
  ];

  /// Tags that map to a content section (excludes [other]).
  static const sectionMapped = <String>[
    photos,
    price,
    copy,
    schedule,
    options,
  ];
}

/// Shared publish approve/reject/resubmit guards (API + UI).
abstract final class ProductPublishGuard {
  /// Shown when admin tries to approve a product with no diver price.
  static const missingPriceMessage = '가격을 입력한 상품만 승인할 수 있어요';

  /// Shown when any unit price is above the workbench cap.
  static const overCapPriceMessage = '1억 원을 넘는 가격이 있어 승인할 수 없어요';

  /// Shown when reject is attempted without a note.
  static const emptyRejectNoteMessage = '반려 사유를 입력해 주세요';

  /// Shown when partner resubmits without changing listing content.
  static const unchangedSinceRejectMessage =
      '반려 후 달라진 내용이 없어요. 반려 사유를 확인하고 고친 뒤 다시 요청해 주세요.';

  static const resubmitNoteTooShortMessage = '고친 내용을 5자 이상 적어 주세요.';

  static const resubmitNoteTooLongMessage = '고친 내용은 200자까지 입력할 수 있어요.';

  static const resubmitNoteMinLength = 5;
  static const resubmitNoteMaxLength = 200;

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

  static void ensureResubmitNote(String resubmitNote) {
    final trimmed = resubmitNote.trim();
    if (trimmed.length < resubmitNoteMinLength) {
      throw StateError(resubmitNoteTooShortMessage);
    }
    if (trimmed.length > resubmitNoteMaxLength) {
      throw StateError(resubmitNoteTooLongMessage);
    }
  }

  /// Status after [ProductSaveIntent.keepEditing] (temp save).
  static ProductPublishStatus keepEditingStatus(
    ProductPublishStatus? previous,
  ) {
    return switch (previous) {
      ProductPublishStatus.pending => ProductPublishStatus.pending,
      ProductPublishStatus.rejected => ProductPublishStatus.rejected,
      ProductPublishStatus.approved => ProductPublishStatus.approved,
      ProductPublishStatus.draft || null => ProductPublishStatus.draft,
    };
  }

  /// Normalize admin-selected tags to known codes (order preserved, unique).
  static List<String> normalizeReasonTags(Iterable<String> raw) {
    final seen = <String>{};
    final out = <String>[];
    for (final item in raw) {
      final code = item.trim();
      if (!ProductRejectTags.all.contains(code) || !seen.add(code)) {
        continue;
      }
      out.add(code);
    }
    return out;
  }

  /// Tagged sections (excluding `other`) that are still [SectionChangeFlag.same].
  ///
  /// Used by build 3B soft warn; does not block. Empty tags/hashes → empty list.
  static List<String> untouchedTaggedSections({
    required ShopProduct previous,
    required ShopProduct next,
    List<ShopGallerySlot>? pendingGallery,
  }) {
    final tags = _sectionMappedTags(previous);
    if (tags.isEmpty || previous.rejectedSectionHashes.isEmpty) {
      return const [];
    }
    final flags = sectionChangeFlags(
      previous.rejectedSectionHashes,
      next,
      pendingGallery: pendingGallery,
    );
    return [
      for (final tag in tags)
        if (flags[tag] == SectionChangeFlag.same) tag,
    ];
  }

  /// True when every section-mapped reject tag is still unchanged.
  ///
  /// Soft warn only — never throws. Legacy rejects (no tags/hashes) → false.
  static bool shouldWarnUntouchedTaggedSections({
    required ShopProduct previous,
    required ShopProduct next,
    List<ShopGallerySlot>? pendingGallery,
  }) {
    final tags = _sectionMappedTags(previous);
    if (tags.isEmpty || previous.rejectedSectionHashes.isEmpty) {
      return false;
    }
    final untouched = untouchedTaggedSections(
      previous: previous,
      next: next,
      pendingGallery: pendingGallery,
    );
    return untouched.length == tags.length;
  }

  static List<String> _sectionMappedTags(ShopProduct previous) {
    return [
      for (final tag in previous.rejectedReasonTags)
        if (ProductRejectTags.sectionMapped.contains(tag)) tag,
    ];
  }

  /// When [previous.rejectedContentHash] is set, [next] must differ.
  /// Empty hash (legacy rejects) skips the unchanged check.
  ///
  /// Pass [pendingGallery] on save so local bytes / deletes / cover order are
  /// compared before R2 upload (product.photoUrls alone omit pending bytes).
  static void assertChangedSinceReject({
    required ShopProduct previous,
    required ShopProduct next,
    List<ShopGallerySlot>? pendingGallery,
  }) {
    final hash = previous.rejectedContentHash.trim();
    if (hash.isEmpty) {
      return;
    }
    if (productContentFingerprint(next, pendingGallery: pendingGallery) ==
        hash) {
      throw StateError(unchangedSinceRejectMessage);
    }
  }

  /// Partner/creator resubmit after reject → pending + count/note.
  static ShopProduct applyResubmit({
    required ShopProduct previous,
    required ShopProduct next,
    required String resubmitNote,
    List<ShopGallerySlot>? pendingGallery,
  }) {
    assertChangedSinceReject(
      previous: previous,
      next: next,
      pendingGallery: pendingGallery,
    );
    ensureResubmitNote(resubmitNote);
    final submitter = next.submittedByUid.isNotEmpty
        ? next.submittedByUid
        : previous.submittedByUid;
    return next.copyWith(
      publishStatus: ProductPublishStatus.pending,
      active: false,
      submittedAt: DateTime.now(),
      submittedByUid: submitter,
      reviewNote: previous.reviewNote,
      rejectedContentHash: previous.rejectedContentHash,
      rejectedReasonTags: previous.rejectedReasonTags,
      rejectedSectionHashes: previous.rejectedSectionHashes,
      resubmitCount: previous.resubmitCount + 1,
      resubmitNote: resubmitNote.trim(),
    );
  }

  /// Apply approve/reject side effects used by repository status updates.
  static ShopProduct applyStatusChange({
    required ShopProduct product,
    required ProductPublishStatus status,
    String reviewNote = '',
    List<String> reasonTags = const [],
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
          rejectedReasonTags: const [],
          rejectedSectionHashes: const {},
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
          rejectedReasonTags: normalizeReasonTags(reasonTags),
          rejectedSectionHashes: productSectionFingerprints(product),
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
