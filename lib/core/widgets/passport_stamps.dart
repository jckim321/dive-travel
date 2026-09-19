import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/region_catalog.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class PassportStamps extends StatefulWidget {
  const PassportStamps({
    super.key,
    required this.stamped,
    this.compact = false,
    this.initiallyOpen = false,
  });

  final Set<String> stamped;
  final bool compact;
  final bool initiallyOpen;

  @override
  State<PassportStamps> createState() => _PassportStampsState();
}

class _PassportStampsState extends State<PassportStamps>
    with SingleTickerProviderStateMixin {
  late final AnimationController _open;

  @override
  void initState() {
    super.initState();
    _open = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    if (widget.initiallyOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _open.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (widget.compact && _open.value == 0) {
      await showDialog<void>(
        context: context,
        barrierColor: const Color(0x99052A4A),
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 28,
            ),
            child: PassportStamps(
              stamped: widget.stamped,
              initiallyOpen: true,
            ),
          );
        },
      );
      return;
    }
    if (_open.isDismissed) {
      await _open.forward();
      return;
    }
    await _open.reverse();
    if (!mounted || !widget.initiallyOpen) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final coverH = widget.compact ? 118.0 : 196.0;
    final coverW = widget.compact ? 86.0 : 148.0;
    final spreadH = widget.compact ? 118.0 : 312.0;

    return AnimatedBuilder(
      animation: _open,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_open.value);
        return Column(
          children: [
            SizedBox(
              height: lerpDouble(coverH, spreadH, t),
              width: double.infinity,
              child: t < 0.04
                  ? Center(
                      child: _PassportCover(
                        width: coverW,
                        height: coverH,
                        stampedCount: widget.stamped.length,
                        total: RegionCatalog.passportCountries.length,
                        compact: widget.compact,
                        onTap: _toggle,
                      ),
                    )
                  : _UnfoldingBook(
                      t: t,
                      stamped: widget.stamped,
                      onToggle: _toggle,
                    ),
            ),
            if (!widget.compact) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: _toggle,
                child: Text(
                  t < 0.5 ? l10n.passportOpenHint : l10n.passportCloseHint,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _UnfoldingBook extends StatelessWidget {
  const _UnfoldingBook({
    required this.t,
    required this.stamped,
    required this.onToggle,
  });

  final double t;
  final Set<String> stamped;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final coverOpacity = t < 0.52 ? 1.0 : (1 - (t - 0.52) / 0.48).clamp(0.0, 1.0);
    final pageOpacity = Interval(0.28, 0.85, curve: Curves.easeOut).transform(t);

    return LayoutBuilder(
      builder: (context, box) {
        final coverW = math.max(120.0, box.maxWidth * 0.48);
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: pageOpacity,
              child: _PassportSpread(
                stamped: stamped,
                onFold: onToggle,
              ),
            ),
            if (coverOpacity > 0)
              IgnorePointer(
                ignoring: t > 0.45,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Transform(
                    alignment: Alignment.centerLeft,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.00115)
                      ..rotateY(-math.pi * t),
                    child: Opacity(
                      opacity: coverOpacity,
                      child: _PassportCover(
                        width: coverW,
                        height: box.maxHeight,
                        stampedCount: stamped.length,
                        total: RegionCatalog.passportCountries.length,
                        compact: false,
                        onTap: onToggle,
                      ),
                    ),
                  ),
                ),
              ),
            if (t > 0.35)
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: IconButton(
                    key: const Key('passport-fold'),
                    tooltip: AppLocalizations.of(context).passportCloseHint,
                    onPressed: onToggle,
                    icon: const Icon(Icons.close, color: AppTheme.navy),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PassportCover extends StatelessWidget {
  const _PassportCover({
    required this.width,
    required this.height,
    required this.stampedCount,
    required this.total,
    required this.compact,
    required this.onTap,
  });

  final double width;
  final double height;
  final int stampedCount;
  final int total;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        key: Key(compact ? 'passport-cover-compact' : 'passport-cover'),
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -5,
              top: 6,
              bottom: 6,
              width: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFE8D9B8),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: const Color(0xFFC4B48A)),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF16344A),
                    AppTheme.navy,
                    Color(0xFF071421),
                  ],
                ),
                border: Border.all(color: AppTheme.gold, width: 1.6),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x590B1F33),
                    blurRadius: 16,
                    offset: Offset(4, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(compact ? 8 : 14),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.gold.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 6 : 10,
                      vertical: compact ? 8 : 12,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.passportCoverNation,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.goldSoft,
                              fontSize: compact ? 8 : 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                          SizedBox(height: compact ? 8 : 16),
                          Icon(
                            Icons.public,
                            color: AppTheme.gold,
                            size: compact ? 22 : 32,
                          ),
                          SizedBox(height: compact ? 6 : 10),
                          Text(
                            l10n.passportCoverType,
                            style: TextStyle(
                              color: AppTheme.gold,
                              fontSize: compact ? 11 : 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                          SizedBox(height: compact ? 8 : 16),
                          Text(
                            '$stampedCount / $total',
                            style: TextStyle(
                              color: AppTheme.gold,
                              fontSize: compact ? 10 : 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassportSpread extends StatefulWidget {
  const _PassportSpread({
    required this.stamped,
    required this.onFold,
  });

  final Set<String> stamped;
  final VoidCallback onFold;

  @override
  State<_PassportSpread> createState() => _PassportSpreadState();
}

class _PassportSpreadState extends State<_PassportSpread> {
  static const _pairs = <List<String>>[
    [ContinentId.asia, ContinentId.africa],
    [ContinentId.oceania, ContinentId.americas],
    [ContinentId.europe, ContinentId.polar],
  ];

  var _page = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pair = _pairs[_page];
    return DecoratedBox(
      key: const Key('passport-spread'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330B1F33),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ColoredBox(
          color: const Color(0xFFF7EFDF),
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onFold,
                  child: Row(
                    children: [
                      Expanded(
                        child: _PaperPage(
                          title: continentLabel(l10n, pair[0]),
                          countries: _countriesOn(pair[0]),
                          stamped: widget.stamped,
                        ),
                      ),
                      Container(
                        width: 12,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0x33251A0C),
                              Color(0x88C4A35A),
                              Color(0x33251A0C),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: _PaperPage(
                          title: continentLabel(l10n, pair[1]),
                          countries: _countriesOn(pair[1]),
                          stamped: widget.stamped,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    key: const Key('passport-prev'),
                    onPressed: _page == 0
                        ? null
                        : () => setState(() => _page -= 1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      l10n.passportPageIndex(_page + 1, _pairs.length),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.navy,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('passport-next'),
                    onPressed: _page >= _pairs.length - 1
                        ? null
                        : () => setState(() => _page += 1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PassportCountry> _countriesOn(String continent) {
    return [
      for (final country in RegionCatalog.passportCountries)
        if (country.continent == continent) country,
    ];
  }
}

class _PaperPage extends StatelessWidget {
  const _PaperPage({
    required this.title,
    required this.countries,
    required this.stamped,
  });

  final String title;
  final List<PassportCountry> countries;
  final Set<String> stamped;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.navy,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: countries.isEmpty
                ? Center(
                    child: Text(
                      l10n.passportEmptyPage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF8A939C),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final country in countries)
                          _VisaStamp(
                            label: country.name,
                            stamped: stamped.contains(country.name),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

String continentLabel(AppLocalizations l10n, String id) {
  return switch (id) {
    ContinentId.asia => l10n.exploreContinentAsia,
    ContinentId.africa => l10n.exploreContinentAfrica,
    ContinentId.oceania => l10n.exploreContinentOceania,
    ContinentId.americas => l10n.exploreContinentAmericas,
    ContinentId.europe => l10n.exploreContinentEurope,
    ContinentId.polar => l10n.exploreContinentPolar,
    _ => id,
  };
}

class _VisaStamp extends StatelessWidget {
  const _VisaStamp({
    required this.label,
    required this.stamped,
  });

  final String label;
  final bool stamped;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ink = stamped ? const Color(0xFF8A2E24) : const Color(0xFFC5CDD4);
    final tilt = stamped ? ((label.hashCode % 7) - 3) * 0.035 : 0.0;
    return Transform.rotate(
      angle: tilt,
      child: Container(
        width: 78,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: ink, width: stamped ? 2.2 : 1.2),
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: ink.withValues(alpha: 0.7)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                stamped ? l10n.passportEntryGranted : l10n.passportAwaiting,
                style: TextStyle(
                  color: ink,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
