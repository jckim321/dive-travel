import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
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
  int _stars = 5;
  final _comment = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _shopId = widget.shopId ?? DiveShopCatalog.shops.first.id;
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  String? _resolveProductId(DiverStore store) {
    final passed = widget.productId?.trim();
    if (passed != null && passed.isNotEmpty) {
      return passed;
    }
    final bookingId = widget.bookingId;
    if (bookingId == null || bookingId.isEmpty) {
      return null;
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
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    try {
      // Same score on all Dive Star axes so shop aggregates stay consistent.
      await store.submitOperationReview(
        shopId: _shopId,
        safety: _stars,
        guide: _stars,
        boat: _stars,
        bookingId: widget.bookingId,
        logId: widget.logId,
        productId: _resolveProductId(store),
        comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reviewSaved)),
      );
      Navigator.of(context).pop();
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final shops = DiveShopCatalog.shops;

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
            onChanged: widget.shopId == null
                ? (value) {
                    if (value != null) {
                      setState(() => _shopId = value);
                    }
                  }
                : null,
          ),
          const SizedBox(height: 24),
          Text(l10n.reviewStarsLabel, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  key: Key('review-star-$i'),
                  onPressed: () => setState(() => _stars = i),
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
            decoration: InputDecoration(
              labelText: l10n.reviewComment,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('review-submit'),
            onPressed: _saving ? null : _submit,
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
