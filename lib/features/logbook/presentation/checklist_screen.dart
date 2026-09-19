import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final categories = store.gear.map((item) => item.category).toSet().toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checklistTitle)),
      body: ListView(
        children: [
          for (final category in categories) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                category,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            for (final item in store.gear.where((gear) => gear.category == category))
              CheckboxListTile(
                value: item.packed,
                title: Text(item.name),
                onChanged: (_) => store.toggleGear(item.id),
              ),
          ],
        ],
      ),
    );
  }
}
