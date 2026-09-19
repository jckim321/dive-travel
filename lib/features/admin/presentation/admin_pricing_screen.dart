import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/instructor_discount.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class AdminPricingScreen extends StatefulWidget {
  const AdminPricingScreen({super.key});

  @override
  State<AdminPricingScreen> createState() => _AdminPricingScreenState();
}

class _AdminPricingScreenState extends State<AdminPricingScreen> {
  static final _won = NumberFormat('#,###');
  InstructorDiscountKind _kind = InstructorDiscountKind.percent;
  final _value = TextEditingController(
    text: '${InstructorDiscount.defaultPercent}',
  );
  var _hydrated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) {
      return;
    }
    _hydrated = true;
    final current = DiverStoreScope.of(context).instructorDiscount;
    _kind = current.kind;
    _value.text = '${current.value}';
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  InstructorDiscount get _draft {
    return InstructorDiscount(
      kind: _kind,
      value: int.tryParse(_value.text.trim()) ?? 0,
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    await DiverStoreScope.of(context).saveInstructorDiscount(_draft);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.adminPricingSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sample = DiveShopCatalog.shops.first.consumerPrice;
    final preview = _draft.apply(sample);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminPricingTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(l10n.adminPricingSubtitle, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          SegmentedButton<InstructorDiscountKind>(
            key: const Key('admin-discount-kind'),
            segments: [
              ButtonSegment(
                value: InstructorDiscountKind.percent,
                label: Text(l10n.adminPricingPercent),
              ),
              ButtonSegment(
                value: InstructorDiscountKind.amount,
                label: Text(l10n.adminPricingAmount),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (next) {
              setState(() => _kind = next.first);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('admin-discount-value'),
            controller: _value,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: _kind == InstructorDiscountKind.percent
                  ? l10n.adminPricingPercentHint
                  : l10n.adminPricingAmountHint,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.adminPricingPreview(
              _won.format(sample),
              _won.format(preview),
            ),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('admin-discount-save'),
            onPressed: _save,
            child: Text(l10n.adminPricingSave),
          ),
        ],
      ),
    );
  }
}
