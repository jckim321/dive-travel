import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/guest_review.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/reviews/presentation/operation_review_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

Future<void> openMyReviews(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => const MyReviewsScreen(),
    ),
  );
}

/// Lists the signed-in diver's submitted trip reviews (newest first).
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  var _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  Future<void> _ensureLoaded() async {
    final store = DiverStoreScope.of(context);
    if (store.myReviewsLoaded) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await store.ensureMyReviewsLoaded();
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
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

  Future<void> _reload() async {
    final store = DiverStoreScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await store.refreshMyReviews();
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
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
    await openOperationReview(
      context,
      existingReview: review,
    );
    // Store already refreshed myReviews after edit/delete.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final dateFmt = DateFormat.yMMMd();

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final reviews = store.myReviews;
        final showSpinner = _loading && !store.myReviewsLoaded;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.myReviewsTitle)),
          body: showSpinner
              ? const Center(child: CircularProgressIndicator())
              : _error != null && reviews.isEmpty
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
                  : reviews.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              l10n.myReviewsEmpty,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: AdminConsoleTheme.muted,
                                  ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _reload,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                            itemCount: reviews.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final review = reviews[index];
                              final stars = '★' * review.stars;
                              return Card(
                                child: ListTile(
                                  title: Text(
                                    _shopName(store, review.shopId),
                                  ),
                                  subtitle: Text(
                                    [
                                      _productLabel(store, review, l10n),
                                      stars,
                                      dateFmt.format(
                                        review.createdAt.toLocal(),
                                      ),
                                      if (review.wasEdited)
                                        l10n.myReviewEditedBadge,
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
      },
    );
  }
}
