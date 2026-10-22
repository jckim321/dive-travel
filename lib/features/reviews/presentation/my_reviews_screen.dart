import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/guest_review.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/reviews/presentation/operation_review_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Lists the signed-in diver's submitted trip reviews (newest first).
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  bool _loading = true;
  Object? _error;
  List<GuestReview> _reviews = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final store = DiverStoreScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reviews = await store.listMyReviews();
      if (!mounted) {
        return;
      }
      setState(() {
        _reviews = reviews;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  String _shopName(DiverStore store, String shopId) {
    for (final stats in store.shopStats) {
      if (stats.shopId == shopId && (stats.name?.isNotEmpty ?? false)) {
        return stats.name!;
      }
    }
    return DiveShopCatalog.byId(shopId)?.name ?? shopId;
  }

  String _productLabel(
    DiverStore store,
    GuestReview review,
    AppLocalizations l10n,
  ) {
    if (review.productId.isEmpty) {
      return l10n.myReviewNoProduct;
    }
    for (final stats in store.shopStats) {
      if (stats.shopId != review.shopId) {
        continue;
      }
      for (final product in stats.products) {
        if (product.id == review.productId) {
          return product.name;
        }
      }
    }
    return review.productId;
  }

  Future<void> _openEdit(GuestReview review) async {
    final changed = await openOperationReview(
      context,
      existingReview: review,
    );
    if (changed == true && mounted) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final dateFmt = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myReviewsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$_error', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _reload,
                          child: Text(l10n.adminDiveStarAssessmentRetry),
                        ),
                      ],
                    ),
                  ),
                )
              : _reviews.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.myReviewsEmpty,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AdminConsoleTheme.muted,
                              ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _reload,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: _reviews.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final review = _reviews[index];
                          final stars = '★' * review.stars;
                          return Card(
                            child: ListTile(
                              title: Text(_shopName(store, review.shopId)),
                              subtitle: Text(
                                [
                                  _productLabel(store, review, l10n),
                                  stars,
                                  dateFmt.format(review.createdAt.toLocal()),
                                  if (review.wasEdited) l10n.myReviewEditedBadge,
                                ].join(' · '),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _openEdit(review),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

void openMyReviews(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const MyReviewsScreen()),
  );
}
