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
  });

  final String? shopId;
  final String? bookingId;
  final String? logId;

  @override
  State<OperationReviewScreen> createState() => _OperationReviewScreenState();
}

class _OperationReviewScreenState extends State<OperationReviewScreen> {
  late String _shopId;
  int _safety = 5;
  int _guide = 5;
  int _boat = 5;
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

  Future<void> _submit() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    try {
      await DiverStoreScope.of(context).submitOperationReview(
        shopId: _shopId,
        safety: _safety,
        guide: _guide,
        boat: _boat,
        bookingId: widget.bookingId,
        logId: widget.logId,
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
          _ScoreRow(
            label: l10n.reviewSafety,
            value: _safety,
            onChanged: (value) => setState(() => _safety = value),
          ),
          _ScoreRow(
            label: l10n.reviewGuide,
            value: _guide,
            onChanged: (value) => setState(() => _guide = value),
          ),
          _ScoreRow(
            label: l10n.reviewBoat,
            value: _boat,
            onChanged: (value) => setState(() => _boat = value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _comment,
            maxLines: 3,
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

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => onChanged(i),
                  icon: Icon(
                    i <= value ? Icons.star : Icons.star_border,
                    color: const Color(0xFFC4A35A),
                  ),
                ),
            ],
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
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => OperationReviewScreen(
        shopId: shopId,
        bookingId: bookingId,
        logId: logId,
      ),
    ),
  );
}

DiveShop? shopForSite(String siteName) {
  final hits = DiveShopCatalog.search(query: siteName, continent: ContinentFilter.all);
  return hits.isEmpty ? null : hits.first;
}
