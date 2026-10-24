import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:dive_travel_app/core/models/shop_product.dart';

/// Status of a staged price / new-option request on an approved listing.
enum PriceRevisionStatus {
  pending,
  rejected;

  static PriceRevisionStatus? parse(Object? raw) {
    final value = '$raw'.trim().toLowerCase();
    return switch (value) {
      'pending' => PriceRevisionStatus.pending,
      'rejected' => PriceRevisionStatus.rejected,
      _ => null,
    };
  }

  String get firestoreValue => name;
}

/// Price change for an option that already exists on the live listing.
class OptionPriceUpdate {
  const OptionPriceUpdate({
    required this.id,
    required this.consumerPrice,
    required this.professionalPrice,
  });

  final String id;
  final int consumerPrice;
  final int professionalPrice;

  factory OptionPriceUpdate.fromMap(Map<String, dynamic> data) {
    return OptionPriceUpdate(
      id: data['id'] as String? ?? '',
      consumerPrice: (data['consumer_price'] as num?)?.toInt() ?? 0,
      professionalPrice: (data['professional_price'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'consumer_price': consumerPrice,
        'professional_price': professionalPrice,
      };
}

/// Staged partner price / new-option request. Guests never read this map.
class PriceRevision {
  const PriceRevision({
    required this.status,
    this.submittedAt,
    this.reviewNote = '',
    this.resubmitCount = 0,
    this.resubmitNote = '',
    this.consumerPrice,
    this.professionalPrice,
    this.guestRates = const [],
    this.optionPriceUpdates = const [],
    this.pendingOptions = const [],
  });

  final PriceRevisionStatus status;
  final DateTime? submittedAt;
  final String reviewNote;
  final int resubmitCount;
  final String resubmitNote;
  final int? consumerPrice;
  final int? professionalPrice;
  final List<GuestRate> guestRates;
  final List<OptionPriceUpdate> optionPriceUpdates;
  final List<ShopProductOption> pendingOptions;

  bool get isPending => status == PriceRevisionStatus.pending;
  bool get isRejected => status == PriceRevisionStatus.rejected;

  /// Token sent with admin approve/reject to detect concurrent partner edits.
  String get freshnessToken {
    final at = submittedAt?.toUtc().toIso8601String() ?? '';
    return at.isEmpty ? fingerprint : at;
  }

  /// Stable content fingerprint (fallback when [submittedAt] is missing).
  String get fingerprint {
    final payload = jsonEncode({
      'status': status.firestoreValue,
      'consumer_price': consumerPrice,
      'professional_price': professionalPrice,
      'guest_rates': [
        for (final rate in [...guestRates]
          ..sort(
            (a, b) => a.role.firestoreValue.compareTo(b.role.firestoreValue),
          ))
          rate.toMap(),
      ],
      'option_price_updates': [
        for (final item in [...optionPriceUpdates]
          ..sort((a, b) => a.id.compareTo(b.id)))
          item.toMap(),
      ],
      'pending_options': [
        for (final option in [...pendingOptions]
          ..sort((a, b) => a.id.compareTo(b.id)))
          option.toMap(),
      ],
      'resubmit_count': resubmitCount,
      'review_note': reviewNote,
    });
    return sha256.convert(utf8.encode(payload)).toString();
  }

  factory PriceRevision.fromMap(Map<String, dynamic> data) {
    final status =
        PriceRevisionStatus.parse(data['status']) ?? PriceRevisionStatus.pending;
    final rawRates = data['guest_rates'];
    final rates = <GuestRate>[];
    if (rawRates is List) {
      for (final item in rawRates) {
        if (item is Map<String, dynamic>) {
          rates.add(GuestRate.fromMap(item));
        } else if (item is Map) {
          rates.add(GuestRate.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    final rawUpdates = data['option_price_updates'];
    final updates = <OptionPriceUpdate>[];
    if (rawUpdates is List) {
      for (final item in rawUpdates) {
        final map = item is Map<String, dynamic>
            ? item
            : (item is Map ? Map<String, dynamic>.from(item) : null);
        if (map == null) {
          continue;
        }
        final update = OptionPriceUpdate.fromMap(map);
        if (update.id.isNotEmpty) {
          updates.add(update);
        }
      }
    }
    final rawPending = data['pending_options'];
    final pending = <ShopProductOption>[];
    if (rawPending is List) {
      for (final item in rawPending) {
        final map = item is Map<String, dynamic>
            ? item
            : (item is Map ? Map<String, dynamic>.from(item) : null);
        if (map == null) {
          continue;
        }
        final option = ShopProductOption.fromMap(map);
        if (option.id.isNotEmpty) {
          pending.add(option);
        }
      }
    }
    final submittedRaw = data['submitted_at'];
    DateTime? submittedAt;
    if (submittedRaw is String) {
      submittedAt = DateTime.tryParse(submittedRaw);
    }
    return PriceRevision(
      status: status,
      submittedAt: submittedAt,
      reviewNote: data['review_note'] as String? ?? '',
      resubmitCount: (data['resubmit_count'] as num?)?.toInt() ?? 0,
      resubmitNote: data['resubmit_note'] as String? ?? '',
      consumerPrice: (data['consumer_price'] as num?)?.toInt(),
      professionalPrice: (data['professional_price'] as num?)?.toInt(),
      guestRates: rates,
      optionPriceUpdates: updates,
      pendingOptions: pending,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.firestoreValue,
      if (submittedAt != null) 'submitted_at': submittedAt!.toIso8601String(),
      if (reviewNote.isNotEmpty) 'review_note': reviewNote,
      if (resubmitCount > 0) 'resubmit_count': resubmitCount,
      if (resubmitNote.isNotEmpty) 'resubmit_note': resubmitNote,
      if (consumerPrice != null) 'consumer_price': consumerPrice,
      if (professionalPrice != null) 'professional_price': professionalPrice,
      if (guestRates.isNotEmpty)
        'guest_rates': [for (final rate in guestRates) rate.toMap()],
      if (optionPriceUpdates.isNotEmpty)
        'option_price_updates': [
          for (final item in optionPriceUpdates) item.toMap(),
        ],
      if (pendingOptions.isNotEmpty)
        'pending_options': [
          for (final option in pendingOptions) option.toMap(),
        ],
    };
  }

  PriceRevision copyWith({
    PriceRevisionStatus? status,
    DateTime? submittedAt,
    String? reviewNote,
    int? resubmitCount,
    String? resubmitNote,
    int? consumerPrice,
    int? professionalPrice,
    List<GuestRate>? guestRates,
    List<OptionPriceUpdate>? optionPriceUpdates,
    List<ShopProductOption>? pendingOptions,
  }) {
    return PriceRevision(
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewNote: reviewNote ?? this.reviewNote,
      resubmitCount: resubmitCount ?? this.resubmitCount,
      resubmitNote: resubmitNote ?? this.resubmitNote,
      consumerPrice: consumerPrice ?? this.consumerPrice,
      professionalPrice: professionalPrice ?? this.professionalPrice,
      guestRates: guestRates ?? this.guestRates,
      optionPriceUpdates: optionPriceUpdates ?? this.optionPriceUpdates,
      pendingOptions: pendingOptions ?? this.pendingOptions,
    );
  }
}

/// Result of staging an approved-product partner save.
class ApprovedPartnerSaveResult {
  const ApprovedPartnerSaveResult({
    required this.product,
    required this.stagedPriceOrNewOptions,
    required this.cancelledRevision,
  });

  final ShopProduct product;
  final bool stagedPriceOrNewOptions;
  final bool cancelledRevision;
}

/// True when [option] still has booked seats or a non-expired flag hold.
bool optionHasSeatCommitment(ShopProductOption option, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  if (option.bookedSeats > 0) {
    return true;
  }
  for (final hold in option.flagHolds) {
    if (hold.expiresAt.isAfter(clock)) {
      return true;
    }
  }
  return false;
}

/// Drop pending options whose parent was removed from live and is not pending.
List<ShopProductOption> pruneOrphanPendingOptions({
  required Iterable<String> liveOptionIds,
  required List<ShopProductOption> pendingOptions,
}) {
  final pendingIds = {
    for (final option in pendingOptions)
      if (option.id.isNotEmpty) option.id,
  };
  final known = {...liveOptionIds, ...pendingIds};
  return [
    for (final option in pendingOptions)
      if (option.parentOptionId.trim().isEmpty ||
          known.contains(option.parentOptionId.trim()))
        option,
  ];
}

/// Sha256 of product + option unit prices (id-keyed). Order-independent.
String productPriceFingerprint(ShopProduct product) {
  final rates = [
    for (final rate in [...product.guestRates]
      ..sort((a, b) => a.role.firestoreValue.compareTo(b.role.firestoreValue)))
      {
        'role': rate.role.firestoreValue,
        'enabled': rate.enabled,
        'consumer': rate.consumer,
        'professional': rate.professional,
      },
  ];
  final options = [
    for (final option in [...product.options]..sort((a, b) => a.id.compareTo(b.id)))
      {
        'id': option.id,
        'consumer_price': option.consumerPrice,
        'professional_price': option.professionalPrice,
      },
  ];
  final payload = jsonEncode({
    'consumer_price': product.consumerPrice,
    'professional_price': product.professionalPrice,
    'guest_rates': rates,
    'options': options,
  });
  return sha256.convert(utf8.encode(payload)).toString();
}

ShopProductOption _closedOption(ShopProductOption option) {
  return option.copyWith(
    bookable: false,
    openEmptySeats: false,
    sameBoatStatus: SameBoatStatus.closed,
  );
}

ShopProductOption _mergeNonPrice(
  ShopProductOption live,
  ShopProductOption draft,
) {
  return live.copyWith(
    name: draft.name,
    description: draft.description,
    bookable: draft.bookable,
    kind: draft.kind,
    guestRole: draft.guestRole,
    parentOptionId: draft.parentOptionId,
    // Keep live prices / seats / holds / same-boat inventory.
  );
}

/// Overlay revision prices and pending options onto [live] for the edit form.
ShopProduct productWithRevisionFormValues(ShopProduct live) {
  final revision = live.priceRevision;
  if (revision == null) {
    return live;
  }
  final updates = {
    for (final item in revision.optionPriceUpdates) item.id: item,
  };
  final options = <ShopProductOption>[
    for (final option in live.options)
      if (updates.containsKey(option.id))
        option.copyWith(
          consumerPrice: updates[option.id]!.consumerPrice,
          professionalPrice: updates[option.id]!.professionalPrice,
        )
      else if (option.kind == ProductOptionKind.basePackage &&
          (revision.consumerPrice != null ||
              revision.professionalPrice != null))
        option.copyWith(
          consumerPrice: revision.consumerPrice ?? option.consumerPrice,
          professionalPrice:
              revision.professionalPrice ?? option.professionalPrice,
        )
      else
        option,
    ...revision.pendingOptions,
  ];
  return live.copyWith(
    consumerPrice: revision.consumerPrice ?? live.consumerPrice,
    professionalPrice: revision.professionalPrice ?? live.professionalPrice,
    guestRates:
        revision.guestRates.isNotEmpty ? revision.guestRates : live.guestRates,
    options: options,
  );
}

/// Sync `base_package` option prices to the product base prices.
ShopProduct syncBasePackagePrices(ShopProduct product) {
  return product.copyWith(
    options: [
      for (final option in product.options)
        if (option.kind == ProductOptionKind.basePackage)
          option.copyWith(
            consumerPrice: product.consumerPrice,
            professionalPrice: product.professionalPrice,
            name: option.name.isEmpty ? product.name : option.name,
          )
        else
          option,
    ],
  );
}

/// Apply staged revision onto live listing. Skips missing option ids.
ShopProduct applyPriceRevisionToLive(ShopProduct live) {
  final revision = live.priceRevision;
  if (revision == null) {
    return live;
  }
  final updates = {
    for (final item in revision.optionPriceUpdates)
      if (item.id.isNotEmpty) item.id: item,
  };
  final nextOptions = <ShopProductOption>[
    for (final option in live.options)
      if (updates.containsKey(option.id))
        option.copyWith(
          consumerPrice: updates[option.id]!.consumerPrice,
          professionalPrice: updates[option.id]!.professionalPrice,
        )
      else
        option,
    ...pruneOrphanPendingOptions(
      liveOptionIds: live.options.map((o) => o.id),
      pendingOptions: revision.pendingOptions,
    ),
  ];
  var next = live.copyWith(
    consumerPrice: revision.consumerPrice ?? live.consumerPrice,
    professionalPrice: revision.professionalPrice ?? live.professionalPrice,
    guestRates:
        revision.guestRates.isNotEmpty ? revision.guestRates : live.guestRates,
    options: nextOptions,
    priceRevision: null,
  );
  return syncBasePackagePrices(next);
}

/// Partner save on an already-approved listing: stage prices / new options.
ApprovedPartnerSaveResult stageApprovedPartnerSave({
  required ShopProduct previous,
  required ShopProduct draft,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final previousIds = {
    for (final option in previous.options)
      if (option.id.isNotEmpty) option.id,
  };
  final draftById = <String, ShopProductOption>{
    for (final option in draft.options)
      if (option.id.isNotEmpty) option.id: option,
  };
  final added = [
    for (final option in draft.options)
      if (option.id.isNotEmpty && !previousIds.contains(option.id)) option,
  ];
  final draftExisting = draft.copyWith(
    options: [
      for (final option in draft.options)
        if (previousIds.contains(option.id)) option,
    ],
  );
  final pricesDiffer =
      productPriceFingerprint(draftExisting) != productPriceFingerprint(previous);
  final needsRevision = pricesDiffer || added.isNotEmpty;

  final liveOptions = <ShopProductOption>[];
  for (final live in previous.options) {
    final draftOption = draftById[live.id];
    if (draftOption == null) {
      if (optionHasSeatCommitment(live, now: clock)) {
        liveOptions.add(_closedOption(live));
      }
      // else: hard delete (omit)
      continue;
    }
    if (needsRevision) {
      liveOptions.add(_mergeNonPrice(live, draftOption));
    } else {
      // Full apply including prices; preserve seats/holds from live.
      liveOptions.add(
        draftOption.copyWith(
          bookedSeats: live.bookedSeats,
          flagHolds: live.flagHolds,
          capacity: live.capacity,
          openEmptySeats: live.openEmptySeats,
          departureStart: live.departureStart,
          flagClosesAt: live.flagClosesAt,
          sameBoatStatus: live.sameBoatStatus,
          guestRating: live.guestRating,
          guestReviewCount: live.guestReviewCount,
        ),
      );
    }
  }

  final liveIds = {for (final o in liveOptions) o.id};
  final prunedPending = pruneOrphanPendingOptions(
    liveOptionIds: liveIds,
    pendingOptions: added,
  );

  if (!needsRevision) {
    final cleared = previous.priceRevision != null;
    var next = draft.copyWith(
      options: liveOptions,
      publishStatus: ProductPublishStatus.approved,
      active: true,
      // Keep seat inventory from previous at product level.
      bookedSeats: previous.bookedSeats,
      flagHolds: previous.flagHolds,
      capacity: previous.capacity,
      openEmptySeats: previous.openEmptySeats,
      sameBoatStatus: previous.sameBoatStatus,
      departureStart: previous.departureStart,
      flagClosesAt: previous.flagClosesAt,
      priceRevision: null,
      reviewNote: previous.reviewNote,
      rejectedContentHash: previous.rejectedContentHash,
      rejectedReasonTags: previous.rejectedReasonTags,
      rejectedSectionHashes: previous.rejectedSectionHashes,
      resubmitCount: previous.resubmitCount,
      resubmitNote: previous.resubmitNote,
      submittedByUid: draft.submittedByUid.isNotEmpty
          ? draft.submittedByUid
          : previous.submittedByUid,
    );
    next = syncBasePackagePrices(next);
    return ApprovedPartnerSaveResult(
      product: next,
      stagedPriceOrNewOptions: false,
      cancelledRevision: cleared,
    );
  }

  final optionUpdates = <OptionPriceUpdate>[
    for (final live in previous.options)
      if (draftById.containsKey(live.id) &&
          (draftById[live.id]!.consumerPrice != live.consumerPrice ||
              draftById[live.id]!.professionalPrice != live.professionalPrice))
        OptionPriceUpdate(
          id: live.id,
          consumerPrice: draftById[live.id]!.consumerPrice,
          professionalPrice: draftById[live.id]!.professionalPrice,
        ),
  ];

  final prior = previous.priceRevision;
  final resubmitCount = prior == null
      ? 0
      : (prior.isRejected || prior.isPending ? prior.resubmitCount + 1 : 0);

  final revision = PriceRevision(
    status: PriceRevisionStatus.pending,
    submittedAt: clock,
    reviewNote: '',
    resubmitCount: resubmitCount,
    resubmitNote: draft.resubmitNote,
    consumerPrice: draft.consumerPrice,
    professionalPrice: draft.professionalPrice,
    guestRates: draft.guestRates,
    optionPriceUpdates: optionUpdates,
    pendingOptions: prunedPending,
  );

  var next = draft.copyWith(
    consumerPrice: previous.consumerPrice,
    professionalPrice: previous.professionalPrice,
    guestRates: previous.guestRates,
    options: liveOptions,
    publishStatus: ProductPublishStatus.approved,
    active: true,
    bookedSeats: previous.bookedSeats,
    flagHolds: previous.flagHolds,
    capacity: previous.capacity,
    openEmptySeats: previous.openEmptySeats,
    sameBoatStatus: previous.sameBoatStatus,
    departureStart: previous.departureStart,
    flagClosesAt: previous.flagClosesAt,
    priceRevision: revision,
    submittedAt: previous.submittedAt,
    reviewedAt: previous.reviewedAt,
    reviewNote: previous.reviewNote,
    rejectedContentHash: previous.rejectedContentHash,
    rejectedReasonTags: previous.rejectedReasonTags,
    rejectedSectionHashes: previous.rejectedSectionHashes,
    resubmitCount: previous.resubmitCount,
    resubmitNote: previous.resubmitNote,
    submittedByUid: draft.submittedByUid.isNotEmpty
        ? draft.submittedByUid
        : previous.submittedByUid,
  );
  // Live base_package stays on previous prices while revision is pending.
  next = next.copyWith(
    options: [
      for (final option in next.options)
        if (option.kind == ProductOptionKind.basePackage)
          option.copyWith(
            consumerPrice: previous.consumerPrice,
            professionalPrice: previous.professionalPrice,
          )
        else
          option,
    ],
  );
  return ApprovedPartnerSaveResult(
    product: next,
    stagedPriceOrNewOptions: true,
    cancelledRevision: false,
  );
}

/// Messages for price-revision admin actions.
abstract final class PriceRevisionGuard {
  static const staleRevisionMessage =
      '요청이 방금 바뀌었어요. 새로고침 후 다시 확인해 주세요';
  static const missingRevisionMessage = '대기 중인 가격 변경 요청이 없어요';
  static const notPendingMessage = '이미 처리되었거나 취소된 요청이에요';

  static void ensureFreshPending({
    required PriceRevision? revision,
    required String expectedFreshness,
  }) {
    if (revision == null) {
      throw StateError(missingRevisionMessage);
    }
    if (!revision.isPending) {
      throw StateError(notPendingMessage);
    }
    final expected = expectedFreshness.trim();
    if (expected.isEmpty) {
      return;
    }
    if (revision.freshnessToken != expected &&
        revision.fingerprint != expected) {
      throw StateError(staleRevisionMessage);
    }
  }
}
