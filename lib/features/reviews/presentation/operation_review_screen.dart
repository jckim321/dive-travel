import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/operation_review_policy.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/guest_review.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/review_detail_options.dart';
import 'package:dive_travel_app/features/reviews/presentation/review_detail_labels.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class OperationReviewScreen extends StatefulWidget {
  const OperationReviewScreen({
    super.key,
    this.shopId,
    this.bookingId,
    this.logId,
    this.productId,
    this.existingReview,
  });

  final String? shopId;
  final String? bookingId;
  final String? logId;
  final String? productId;

  /// When set, screen edits this review (shop/booking/product locked).
  final GuestReview? existingReview;

  @override
  State<OperationReviewScreen> createState() => _OperationReviewScreenState();
}

class _OperationReviewScreenState extends State<OperationReviewScreen> {
  late String _shopId;
  String? _bookingId;
  int _stars = 5;
  final _comment = TextEditingController();
  final _waterTemp = TextEditingController();
  bool _saving = false;
  String? _gateMessage;
  String? _diverLevel;
  String? _diveCountBand;
  String? _visibility;
  String? _current;
  String? _guideCrowd;
  String? _revisitIntent;
  final _audiences = <String>{};
  var _detailsOpen = false;

  bool get _isEditing => widget.existingReview != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingReview;
    if (existing != null) {
      _shopId = existing.shopId;
      _bookingId = existing.bookingId.isEmpty ? null : existing.bookingId;
      _stars = existing.stars.clamp(1, 5);
      _comment.text = existing.comment;
      _diverLevel = existing.details.diverLevel;
      _diveCountBand = existing.details.diveCountBand;
      _visibility = existing.details.visibility;
      _current = existing.details.current;
      _guideCrowd = existing.details.guideCrowd;
      _revisitIntent = existing.details.revisitIntent;
      _audiences.addAll(existing.details.recommendFor);
      if (existing.details.waterTempC != null) {
        _waterTemp.text = '${existing.details.waterTempC}';
      }
    } else {
      _shopId = widget.shopId ?? '';
      _bookingId = widget.bookingId?.trim();
      if (_bookingId != null && _bookingId!.isEmpty) {
        _bookingId = null;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isEditing) {
        _resolveBookingGate();
      }
    });
  }

  @override
  void dispose() {
    _comment.dispose();
    _waterTemp.dispose();
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
      case ReviewValidationCode.invalidDetails:
        return l10n.reviewInvalidDetails;
      case ReviewValidationCode.invalidWaterTemp:
        return l10n.reviewInvalidWaterTemp;
    }
  }

  ReviewDetails _collectDetails() {
    double? temp;
    final rawTemp = _waterTemp.text.trim();
    if (rawTemp.isNotEmpty) {
      temp = double.tryParse(rawTemp.replaceAll(',', '.'));
    }
    return ReviewDetails(
      diverLevel: _diverLevel,
      diveCountBand: _diveCountBand,
      visibility: _visibility,
      current: _current,
      waterTempC: temp,
      guideCrowd: _guideCrowd,
      recommendFor: _audiences.toList(),
      revisitIntent: _revisitIntent,
    );
  }

  ({String? productId, String? optionId}) _resolveProductLink(
    DiverStore store,
    String bookingId,
  ) {
    final passed = widget.productId?.trim();
    for (final booking in store.bookings) {
      if (booking.id != bookingId) {
        continue;
      }
      final productId = (passed != null && passed.isNotEmpty)
          ? passed
          : (booking.productId.isNotEmpty ? booking.productId : null);
      final optionId =
          booking.optionId.isNotEmpty ? booking.optionId : null;
      return (productId: productId, optionId: optionId);
    }
    if (passed != null && passed.isNotEmpty) {
      return (productId: passed, optionId: null);
    }
    return (productId: null, optionId: null);
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final existing = widget.existingReview;
    if (existing != null) {
      setState(() => _saving = true);
      try {
        final stars = OperationReviewPolicy.clampStars(_stars);
        final comment = OperationReviewPolicy.normalizeComment(_comment.text);
        final details =
            OperationReviewPolicy.normalizeDetails(_collectDetails());
        await store.updateOperationReview(
          shopId: existing.shopId,
          reviewId: existing.id,
          safety: stars,
          guide: stars,
          boat: stars,
          comment: comment,
          details: details,
        );
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.myReviewUpdated)),
        );
        Navigator.of(context).pop(true);
      } catch (error) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.reviewSaveFailed} ($error)')),
        );
      } finally {
        if (mounted) {
          setState(() => _saving = false);
        }
      }
      return;
    }

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
      final details = OperationReviewPolicy.normalizeDetails(_collectDetails());
      final link = _resolveProductLink(store, bookingId);
      final outcome = await store.submitOperationReview(
        shopId: _shopId,
        safety: stars,
        guide: stars,
        boat: stars,
        bookingId: bookingId,
        logId: widget.logId,
        productId: link.productId,
        optionId: link.optionId,
        comment: comment,
        details: details,
      );
      if (!mounted) {
        return;
      }
      final notice = switch (outcome.productLink) {
        ReviewProductLinkStatus.missingProductId =>
          l10n.reviewSavedProductIdMissing,
        ReviewProductLinkStatus.productNotFound =>
          l10n.reviewSavedProductNotFound,
        ReviewProductLinkStatus.linked => null,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            notice == null
                ? l10n.reviewSaved
                : '${l10n.reviewSaved} $notice',
          ),
        ),
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

  Future<void> _delete() async {
    final existing = widget.existingReview;
    if (existing == null || _saving) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.myReviewDeleteTitle),
        content: Text(l10n.myReviewDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.adminHqClose),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.myReviewDeleteAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    final store = DiverStoreScope.of(context);
    setState(() => _saving = true);
    try {
      await store.deleteOperationReview(
        shopId: existing.shopId,
        reviewId: existing.id,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.myReviewDeleted)),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
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
    final store = DiverStoreScope.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
    final shops = store.shopStats;
    final selected = shops.any((shop) => shop.shopId == _shopId)
        ? _shopId
        : null;
    final blocked = !_isEditing && _gateMessage != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.myReviewEditTitle : l10n.reviewTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            _isEditing ? l10n.myReviewEditHint : l10n.reviewIntro,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (shops.isEmpty)
            Text(
              l10n.shopPickerEmpty,
              key: const Key('review-shop-empty'),
            )
          else
            DropdownButtonFormField<String>(
            key: const Key('review-shop'),
            initialValue: selected,
            decoration: InputDecoration(
              labelText: l10n.reviewShopLabel,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final shop in shops)
                DropdownMenuItem(
                  value: shop.shopId,
                  child: Text(_shopStatsLabel(shop)),
                ),
            ],
            onChanged: _isEditing ||
                    widget.shopId != null ||
                    widget.bookingId != null
                ? null
                : (value) {
                    if (value != null) {
                      setState(() {
                        _shopId = value;
                        _bookingId = null;
                      });
                      _resolveBookingGate();
                    }
                  },
          ),
          if (!_isEditing && _gateMessage != null) ...[
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
          const SizedBox(height: 12),
          Material(
            color: const Color(0xFFF7F9FB),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                ListTile(
                  key: const Key('review-details-expand'),
                  title: Text(l10n.reviewDetailsExpand),
                  subtitle: Text(l10n.reviewDetailOptionalHint),
                  trailing: Icon(
                    _detailsOpen ? Icons.expand_less : Icons.expand_more,
                  ),
                  onTap: blocked
                      ? null
                      : () => setState(() => _detailsOpen = !_detailsOpen),
                ),
                if (_detailsOpen)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ChoiceSection(
                          label: l10n.reviewDetailLevel,
                          values: ReviewDetailOptions.diverLevels,
                          selected: _diverLevel,
                          enabled: !blocked,
                          l10n: l10n,
                          onSelected: (value) =>
                              setState(() => _diverLevel = value),
                        ),
                        _ChoiceSection(
                          label: l10n.reviewDetailDives,
                          values: ReviewDetailOptions.diveCountBands,
                          selected: _diveCountBand,
                          enabled: !blocked,
                          l10n: l10n,
                          onSelected: (value) =>
                              setState(() => _diveCountBand = value),
                        ),
                        _ChoiceSection(
                          label: l10n.reviewDetailVisibility,
                          values: ReviewDetailOptions.visibility,
                          selected: _visibility,
                          enabled: !blocked,
                          l10n: l10n,
                          onSelected: (value) =>
                              setState(() => _visibility = value),
                        ),
                        _ChoiceSection(
                          label: l10n.reviewDetailCurrent,
                          values: ReviewDetailOptions.currents,
                          selected: _current,
                          enabled: !blocked,
                          l10n: l10n,
                          onSelected: (value) =>
                              setState(() => _current = value),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextField(
                            controller: _waterTemp,
                            enabled: !blocked,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: InputDecoration(
                              labelText: l10n.reviewDetailWaterTemp,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        _ChoiceSection(
                          label: l10n.reviewDetailCrowd,
                          values: ReviewDetailOptions.guideCrowds,
                          selected: _guideCrowd,
                          enabled: !blocked,
                          l10n: l10n,
                          onSelected: (value) =>
                              setState(() => _guideCrowd = value),
                        ),
                        _MultiChoiceSection(
                          label: l10n.reviewDetailAudience,
                          values: ReviewDetailOptions.audiences,
                          selected: _audiences,
                          enabled: !blocked,
                          l10n: l10n,
                          onToggle: (value) {
                            setState(() {
                              if (_audiences.contains(value)) {
                                _audiences.remove(value);
                              } else {
                                _audiences.add(value);
                              }
                            });
                          },
                        ),
                        _ChoiceSection(
                          label: l10n.reviewDetailRevisit,
                          values: ReviewDetailOptions.revisitIntents,
                          selected: _revisitIntent,
                          enabled: !blocked,
                          l10n: l10n,
                          onSelected: (value) =>
                              setState(() => _revisitIntent = value),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('review-submit'),
            onPressed: (_saving || blocked) ? null : _submit,
            child: Text(
              _saving
                  ? l10n.logbookUploading
                  : (_isEditing ? l10n.myReviewSaveEdit : l10n.reviewSubmit),
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('review-delete'),
              onPressed: _saving ? null : _delete,
              child: Text(l10n.myReviewDeleteAction),
            ),
          ],
        ],
      ),
    );
      },
    );
  }
}

class _ChoiceSection extends StatelessWidget {
  const _ChoiceSection({
    required this.label,
    required this.values,
    required this.selected,
    required this.enabled,
    required this.l10n,
    required this.onSelected,
  });

  final String label;
  final List<String> values;
  final String? selected;
  final bool enabled;
  final AppLocalizations l10n;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in values)
                ChoiceChip(
                  label: Text(reviewDetailLabel(l10n, value) ?? value),
                  selected: selected == value,
                  onSelected: enabled
                      ? (picked) => onSelected(picked ? value : null)
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MultiChoiceSection extends StatelessWidget {
  const _MultiChoiceSection({
    required this.label,
    required this.values,
    required this.selected,
    required this.enabled,
    required this.l10n,
    required this.onToggle,
  });

  final String label;
  final List<String> values;
  final Set<String> selected;
  final bool enabled;
  final AppLocalizations l10n;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in values)
                FilterChip(
                  label: Text(reviewDetailLabel(l10n, value) ?? value),
                  selected: selected.contains(value),
                  onSelected: enabled ? (_) => onToggle(value) : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<bool?> openOperationReview(
  BuildContext context, {
  String? shopId,
  String? bookingId,
  String? logId,
  String? productId,
  GuestReview? existingReview,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => OperationReviewScreen(
        shopId: shopId,
        bookingId: bookingId,
        logId: logId,
        productId: productId,
        existingReview: existingReview,
      ),
    ),
  );
}

DiveShop? shopForSite(String siteName, Iterable<DiveShop> shops) {
  final needle = siteName.trim().toLowerCase();
  if (needle.isEmpty) {
    return null;
  }
  for (final shop in shops) {
    final named = shop.name.toLowerCase().contains(needle) ||
        shop.sites.any((site) => site.toLowerCase().contains(needle));
    if (named) {
      return shop;
    }
  }
  return null;
}

String _shopStatsLabel(ShopLiveStats stats) {
  final name = stats.name?.trim() ?? '';
  return name.isEmpty ? stats.shopId : name;
}
