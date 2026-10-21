import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/operation_review_policy.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class OperationReviewScreen extends StatefulWidget {
  const OperationReviewScreen({
    super.key,
    this.shopId,
    this.bookingId,
    this.logId,
    this.productId,
  });

  final String? shopId;
  final String? bookingId;
  final String? logId;
  final String? productId;

  @override
  State<OperationReviewScreen> createState() => _OperationReviewScreenState();
}

class _OperationReviewScreenState extends State<OperationReviewScreen> {
  late String _shopId;
  String? _bookingId;
  int _stars = 5;
  final _comment = TextEditingController();
  bool _saving = false;
  String? _gateMessage;

  @override
  void initState() {
    super.initState();
    _shopId = widget.shopId ?? DiveShopCatalog.shops.first.id;
    _bookingId = widget.bookingId?.trim();
    if (_bookingId != null && _bookingId!.isEmpty) {
      _bookingId = null;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _resolveBookingGate();
      }
    });
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _resolveBookingGate() {
    final store = DiverStoreScope.of(context);
    final l10n = AppLocalizations.of(context);
    final existingId = _bookingId;
    if (existingId != null && existingId.isNotEmpty) {
      try {
        OperationReviewPolicy.requireEligibleBooking(
          bookingId: existingId,
          bookings: store.bookings,
          uid: store.uid ?? '',
          shopId: _shopId,
        );
        if (_gateMessage != null) {
          setState(() => _gateMessage = null);
        }
      } on ReviewValidationException catch (error) {
        final message = _messageFor(error.code, l10n);
        if (_gateMessage != message) {
          setState(() => _gateMessage = message);
        }
      }
      return;
    }

    final match = OperationReviewPolicy.findEligibleBookingForShop(
      bookings: store.bookings,
      shopId: _shopId,
      uid: store.uid,
    );
    if (match != null) {
      setState(() {
        _bookingId = match.id;
        _gateMessage = null;
        if (widget.shopId == null) {
          _shopId = match.shopId;
        }
      });
      return;
    }

    final already = _alreadyReviewedForShop(store.bookings);
    final message = already
        ? l10n.reviewAlreadySubmitted
        : l10n.reviewBookingRequired;
    if (_gateMessage != message) {
      setState(() => _gateMessage = message);
    }
  }

  bool _alreadyReviewedForShop(List<TourBooking> bookings) {
    for (final booking in bookings) {
      if (booking.shopId == _shopId &&
          booking.reviewed &&
          booking.isActive &&
          booking.scheduledFor.isBefore(DateTime.now())) {
        return true;
      }
    }
    return false;
  }

  String _messageFor(ReviewValidationCode code, AppLocalizations l10n) {
    switch (code) {
      case ReviewValidationCode.alreadyReviewed:
        return l10n.reviewAlreadySubmitted;
      case ReviewValidationCode.bookingRequired:
      case ReviewValidationCode.bookingNotFound:
      case ReviewValidationCode.tripNotEnded:
      case ReviewValidationCode.bookingNotActive:
      case ReviewValidationCode.shopMismatch:
      case ReviewValidationCode.notOwnBooking:
        return l10n.reviewBookingRequired;
      case ReviewValidationCode.invalidStars:
        return l10n.reviewInvalidStars;
      case ReviewValidationCode.commentTooLong:
        return l10n.reviewCommentTooLong;
    }
  }

  String? _resolveProductId(DiverStore store, String bookingId) {
    final passed = widget.productId?.trim();
    if (passed != null && passed.isNotEmpty) {
      return passed;
    }
    for (final booking in store.bookings) {
      if (booking.id == bookingId && booking.productId.isNotEmpty) {
        return booking.productId;
      }
    }
    return null;
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final bookingId = _bookingId;
    if (bookingId == null || bookingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_gateMessage ?? l10n.reviewBookingRequired)),
      );
      return;
    }
    if (_gateMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_gateMessage!)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final stars = OperationReviewPolicy.clampStars(_stars);
      final comment = OperationReviewPolicy.normalizeComment(_comment.text);
      await store.submitOperationReview(
        shopId: _shopId,
        safety: stars,
        guide: stars,
        boat: stars,
        bookingId: bookingId,
        logId: widget.logId,
        productId: _resolveProductId(store, bookingId),
        comment: comment,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reviewSaved)),
      );
      Navigator.of(context).pop();
    } on ReviewValidationException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageFor(error.code, l10n))),
      );
      if (error.code == ReviewValidationCode.alreadyReviewed) {
        setState(() => _gateMessage = l10n.reviewAlreadySubmitted);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      final text = '$error';
      if (text.contains('alreadyReviewed') ||
          text.contains('ReviewValidationException')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reviewAlreadySubmitted)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.reviewSaveFailed} ($error)')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final shops = DiveShopCatalog.shops;
    final blocked = _gateMessage != null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(l10n.reviewIntro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: const Key('review-shop'),
            initialValue: _shopId,
            decoration: InputDecoration(
              labelText: l10n.reviewShopLabel,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final shop in shops)
                DropdownMenuItem(value: shop.id, child: Text(shop.name)),
            ],
            onChanged: widget.shopId == null && widget.bookingId == null
                ? (value) {
                    if (value != null) {
                      setState(() {
                        _shopId = value;
                        _bookingId = null;
                      });
                      _resolveBookingGate();
                    }
                  }
                : null,
          ),
          if (_gateMessage != null) ...[
            const SizedBox(height: 16),
            Material(
              color: const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  _gateMessage!,
                  key: const Key('review-gate-message'),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(l10n.reviewStarsLabel, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  key: Key('review-star-$i'),
                  onPressed: blocked ? null : () => setState(() => _stars = i),
                  iconSize: 36,
                  icon: Icon(
                    i <= _stars ? Icons.star : Icons.star_border,
                    color: const Color(0xFFC4A35A),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _comment,
            maxLines: 4,
            maxLength: OperationReviewPolicy.maxCommentLength,
            enabled: !blocked,
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                OperationReviewPolicy.maxCommentLength,
              ),
            ],
            decoration: InputDecoration(
              labelText: l10n.reviewComment,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('review-submit'),
            onPressed: (_saving || blocked) ? null : _submit,
            child: Text(_saving ? l10n.logbookUploading : l10n.reviewSubmit),
          ),
        ],
      ),
    );
  }
}

void openOperationReview(
  BuildContext context, {
  String? shopId,
  String? bookingId,
  String? logId,
  String? productId,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => OperationReviewScreen(
        shopId: shopId,
        bookingId: bookingId,
        logId: logId,
        productId: productId,
      ),
    ),
  );
}

DiveShop? shopForSite(String siteName) {
  final hits = DiveShopCatalog.search(
    query: siteName,
    continent: ContinentFilter.all,
  );
  return hits.isEmpty ? null : hits.first;
}
