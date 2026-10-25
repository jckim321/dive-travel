import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/constants/nationality.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Searchable country picker. Empty selection means "do not store".
class NationalityField extends StatelessWidget {
  const NationalityField({
    super.key,
    required this.value,
    required this.onChanged,
    this.fieldKey = const Key('nationality-field'),
  });

  /// ISO code, or null when the member skips nationality.
  final String? value;
  final ValueChanged<String?> onChanged;
  final Key fieldKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownMenu<String>(
      key: fieldKey,
      initialSelection: value ?? '',
      enableFilter: true,
      enableSearch: true,
      requestFocusOnTap: true,
      expandedInsets: EdgeInsets.zero,
      label: Text(l10n.authNationality),
      dropdownMenuEntries: [
        DropdownMenuEntry<String>(
          value: '',
          label: l10n.authNationalityNone,
        ),
        for (final item in nationalityChoices())
          DropdownMenuEntry<String>(
            value: item.code,
            label: '${item.nameKo} (${item.code})',
          ),
      ],
      onSelected: (selected) => onChanged(normalizeNationalityCode(selected)),
    );
  }
}
