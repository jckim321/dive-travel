import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/guest_review.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/app_card.dart';
import 'package:dive_travel_app/features/reviews/presentation/review_detail_labels.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Shop detail block: average summary + paginated guest review cards.
class DiverReviewsSection extends StatefulWidget {
  const DiverReviewsSection({
    super.key,
    required this.shopId,
    required this.rating,
    required this.reviewCount,
  });

  final String shopId;
  final double rating;
  final int reviewCount;

  @override
  State<DiverReviewsSection> createState() => _DiverReviewsSectionState();
}

class _DiverReviewsSectionState extends State<DiverReviewsSection> {
  static const _pageSize = 10;

  final _reviews = <GuestReview>[];
  Object? _cursor;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void didUpdateWidget(covariant DiverReviewsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shopId != widget.shopId) {
      _reviews.clear();
      _cursor = null;
      _hasMore = false;
      _error = null;
      _loadInitial();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final store = DiverStoreScope.of(context);
      final page = await store.fetchShopReviewsPage(
        shopId: widget.shopId,
        limit: _pageSize,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _reviews
          ..clear()
          ..addAll(page.reviews);
        _cursor = page.cursor;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) {
      return;
    }
    setState(() => _loadingMore = true);
    try {
      final store = DiverStoreScope.of(context);
      final page = await store.fetchShopReviewsPage(
        shopId: widget.shopId,
        limit: _pageSize,
        cursor: _cursor,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _reviews.addAll(page.reviews);
        _cursor = page.cursor;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingMore = false;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.reviewSectionTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          widget.reviewCount > 0
              ? l10n.reviewSectionSummary(
                  widget.rating.toStringAsFixed(1),
                  widget.reviewCount,
                )
              : l10n.reviewSectionEmpty,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4A5560),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Text(
            _error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFFB42318),
            ),
          )
        else if (_reviews.isEmpty && widget.reviewCount <= 0)
          const SizedBox.shrink()
        else if (_reviews.isEmpty)
          Text(
            l10n.reviewSectionEmpty,
            style: theme.textTheme.bodyMedium,
          )
        else ...[
          for (var i = 0; i < _reviews.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _ReviewCard(review: _reviews[i]),
          ],
          if (_hasMore) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: const Key('review-load-more'),
                onPressed: _loadingMore ? null : _loadMore,
                child: Text(
                  _loadingMore ? l10n.logbookUploading : l10n.reviewLoadMore,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final GuestReview review;

  static final _date = DateFormat.yMMMd();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final author = review.authorDisplayName.isEmpty
        ? l10n.reviewAuthorFallback
        : review.authorDisplayName;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= review.stars ? Icons.star : Icons.star_border,
                  size: 18,
                  color: const Color(0xFFC4A35A),
                ),
              const Spacer(),
              if (review.wasEdited) ...[
                Text(
                  l10n.myReviewEditedBadge,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.muted,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                _date.format(review.createdAt.toLocal()),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.muted,
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.comment, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: author,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF4A5560),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_authorMeta(l10n).isNotEmpty)
                  TextSpan(
                    text: ' · ${_authorMeta(l10n)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.muted,
                    ),
                  ),
              ],
            ),
          ),
          if (_detailChips(l10n).isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final label in _detailChips(l10n))
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(label, style: const TextStyle(fontSize: 12)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _authorMeta(AppLocalizations l10n) {
    final parts = <String>[
      if (reviewDetailLabel(l10n, review.details.diverLevel) case final label?)
        label,
      if (reviewDetailLabel(l10n, review.details.diveCountBand)
          case final label?)
        label,
    ];
    return parts.join(' · ');
  }

  List<String> _detailChips(AppLocalizations l10n) {
    final temp = review.details.waterTempC;
    final tempLabel = temp == null
        ? null
        : l10n.reviewDetailWaterTempChip(
            temp == temp.roundToDouble()
                ? temp.round().toString()
                : temp.toStringAsFixed(1),
          );
    return [
      ?reviewDetailLabel(l10n, review.details.visibility),
      ?reviewDetailLabel(l10n, review.details.current),
      ?tempLabel,
    ];
  }
}
