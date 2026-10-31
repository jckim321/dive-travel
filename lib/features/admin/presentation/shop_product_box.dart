import 'package:flutter/material.dart';

import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Price, options, included/excluded text, and photos for one product.
///
/// [showDate] adds a departure-date field. It stays off so the current
/// partner form keeps its present layout.
class ShopProductBox extends StatelessWidget {
  const ShopProductBox({
    super.key,
    required this.priceTitle,
    required this.optionsTitle,
    required this.includesTitle,
    required this.priceAndPhotos,
    required this.options,
    required this.includes,
    this.betweenOptionsAndIncludes,
    this.showDate = false,
    this.dateController,
    this.keyPrefix = '',
  });

  final String priceTitle;
  final String optionsTitle;
  final String includesTitle;
  final Widget priceAndPhotos;
  final Widget options;
  final Widget includes;

  /// Kept between the options box and the includes box so the partner form
  /// can leave individual products where they already sit.
  final Widget? betweenOptionsAndIncludes;

  final bool showDate;
  final TextEditingController? dateController;

  /// Empty keeps the original keys. A prefix makes each box unique.
  final String keyPrefix;

  Key _key(String name) =>
      Key(keyPrefix.isEmpty ? name : '$keyPrefix-$name');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: _key('shop-product-box'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDate)
          _sectionBox(
            boxKey: _key('shop-product-box-date-section'),
            title: l10n.workbenchDepartureDate,
            children: [
              TextField(
                key: _key('shop-product-box-date'),
                controller: dateController,
                keyboardType: TextInputType.datetime,
                style: const TextStyle(color: PartnerTheme.text, fontSize: 15),
                cursorColor: PartnerTheme.accent,
                decoration: _dateField(l10n.workbenchDepartureDate),
              ),
            ],
          ),
        _sectionBox(
          boxKey: _key('partner-form-section-price'),
          title: priceTitle,
          children: [priceAndPhotos],
        ),
        _sectionBox(
          boxKey: _key('partner-form-section-options'),
          title: optionsTitle,
          children: [options],
        ),
        ?betweenOptionsAndIncludes,
        _sectionBox(
          boxKey: _key('partner-form-section-includes'),
          title: includesTitle,
          children: [includes],
        ),
      ],
    );
  }
}

Widget _sectionBox({
  required Key boxKey,
  required String title,
  required List<Widget> children,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Material(
      key: boxKey,
      color: PartnerTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: PartnerTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: PartnerTheme.text,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    ),
  );
}

InputDecoration _dateField(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: PartnerTheme.bg,
    labelStyle: const TextStyle(color: PartnerTheme.textDim),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: PartnerTheme.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: PartnerTheme.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: PartnerTheme.accent, width: 1.4),
    ),
  );
}
