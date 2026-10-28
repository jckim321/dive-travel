import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/travel_country_master.dart';
import 'package:dive_travel_app/features/explore/presentation/continent_atlas_rail.dart';
import 'package:dive_travel_app/features/explore/presentation/explore_place_filters.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Search-select for a travel country. Typing filters names and aliases.
/// Choosing a row reports that country. 「기타」 keeps the typed text.
class TravelCountryField extends StatefulWidget {
  const TravelCountryField({
    super.key,
    required this.controller,
    required this.fieldKey,
    required this.decoration,
    required this.onPicked,
    required this.onCustom,
    this.onEdited,
    this.picked,
    this.style,
    this.cursorColor,
  });

  final TextEditingController controller;
  final Key fieldKey;
  final InputDecoration decoration;
  final ValueChanged<TravelCountry> onPicked;
  final VoidCallback onCustom;
  final VoidCallback? onEdited;
  final TravelCountry? picked;
  final TextStyle? style;
  final Color? cursorColor;

  @override
  State<TravelCountryField> createState() => _TravelCountryFieldState();
}

class _TravelCountryFieldState extends State<TravelCountryField> {
  final _focus = FocusNode();
  var _open = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onController);
  }

  @override
  void didUpdateWidget(TravelCountryField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onController);
      widget.controller.addListener(_onController);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onController);
    _focus.dispose();
    super.dispose();
  }

  void _onController() {
    if (!mounted) {
      return;
    }
    setState(() {
      if (_focus.hasFocus) {
        _open = true;
      }
    });
  }

  void _pick(TravelCountry country) {
    widget.controller.value = TextEditingValue(
      text: country.name,
      selection: TextSelection.collapsed(offset: country.name.length),
    );
    setState(() => _open = false);
    widget.onPicked(country);
    _focus.unfocus();
  }

  void _custom() {
    setState(() => _open = false);
    widget.onCustom();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = widget.controller.text;
    final matches = TravelCountryMaster.search(query);
    final picked = widget.picked;
    final assignment = picked == null
        ? null
        : _assignmentLabel(l10n, picked);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: widget.fieldKey,
          controller: widget.controller,
          focusNode: _focus,
          style: widget.style,
          cursorColor: widget.cursorColor,
          decoration: widget.decoration,
          onTap: () => setState(() => _open = true),
          onChanged: (_) {
            widget.onEdited?.call();
            setState(() => _open = true);
          },
          onTapOutside: (_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _open) {
                setState(() => _open = false);
              }
            });
          },
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Material(
              key: const Key('product-country-menu'),
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Color(0xFFBDBDBD)),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final country in matches)
                      ListTile(
                        key: Key('product-country-option-${country.id}'),
                        dense: true,
                        title: Text(
                          country.name,
                          style: const TextStyle(color: Color(0xFF111111)),
                        ),
                        subtitle: _aliasLabel(country, query),
                        onTap: () => _pick(country),
                      ),
                    ListTile(
                      key: const Key('product-country-other'),
                      dense: true,
                      title: Text(
                        l10n.productFormCountryOther,
                        style: const TextStyle(
                          color: Color(0xFF111111),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: _custom,
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (assignment != null) ...[
          const SizedBox(height: 6),
          Text(
            assignment,
            key: const Key('product-country-assignment'),
            style: TextStyle(
              color: widget.style?.color ?? const Color(0xFF5C6770),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Widget? _aliasLabel(TravelCountry country, String query) {
    final alias = TravelCountryMaster.aliasHit(country, query);
    if (alias == null) {
      return null;
    }
    return Text(
      alias,
      style: const TextStyle(color: Color(0xFF5C6770)),
    );
  }

  String _assignmentLabel(AppLocalizations l10n, TravelCountry country) {
    final region = travelRegionLabel(l10n, country.regionId);
    final sea = country.sea;
    if (sea == null) {
      return '$region · ${l10n.productFormCountryNoSea}';
    }
    return '$region · ${travelSeaLabel(l10n, sea)}';
  }
}
