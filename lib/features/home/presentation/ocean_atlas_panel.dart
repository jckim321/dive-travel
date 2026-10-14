import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Stylized living ocean map: open continents glow gold, next ocean pulses.
class OceanAtlasPanel extends StatefulWidget {
  const OceanAtlasPanel({
    super.key,
    required this.stampedContinents,
    required this.nextContinent,
    required this.styleTitle,
    required this.styleBody,
    required this.nextOceanBody,
    required this.shopButtonLabel,
    required this.onOpenShop,
    required this.stampsLabel,
    required this.stampsValue,
    required this.badgeLabel,
    required this.badgeValue,
    required this.checklistLabel,
    required this.checklistValue,
    required this.checklistHighlight,
    required this.onOpenStamps,
    required this.onOpenBadge,
    required this.onOpenChecklist,
  });

  final Set<String> stampedContinents;
  final String nextContinent;
  final String styleTitle;
  final String styleBody;
  final String nextOceanBody;
  final String? shopButtonLabel;
  final VoidCallback? onOpenShop;
  final String stampsLabel;
  final String stampsValue;
  final String badgeLabel;
  final String badgeValue;
  final String checklistLabel;
  final String checklistValue;
  final bool checklistHighlight;
  final VoidCallback onOpenStamps;
  final VoidCallback onOpenBadge;
  final VoidCallback onOpenChecklist;

  @override
  State<OceanAtlasPanel> createState() => _OceanAtlasPanelState();
}

class _OceanAtlasPanelState extends State<OceanAtlasPanel>
    with TickerProviderStateMixin {
  late final AnimationController _breathe;
  late final AnimationController _pulse;
  late final AnimationController _cta;

  /// Soft world layout (stylized, not geographic exact).
  static const _nodes = <(String, double, double)>[
    (ContinentId.americas, 0.18, 0.40),
    (ContinentId.europe, 0.46, 0.24),
    (ContinentId.africa, 0.50, 0.48),
    (ContinentId.asia, 0.72, 0.34),
    (ContinentId.oceania, 0.80, 0.58),
    (ContinentId.polar, 0.48, 0.76),
  ];

  /// Infinite tickers break widget tests that call [WidgetTester.pumpAndSettle].
  static bool get _inWidgetTest =>
      WidgetsBinding.instance.runtimeType
          .toString()
          .contains('TestWidgetsFlutterBinding');

  @override
  void initState() {
    super.initState();
    final inTest = _inWidgetTest;
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
      value: inTest ? 0.55 : 0,
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      value: inTest ? 0.4 : 0,
    );
    if (!inTest) {
      _breathe.repeat(reverse: true);
      _pulse.repeat(reverse: true);
    }
    _cta = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
  }

  @override
  void dispose() {
    _breathe.dispose();
    _pulse.dispose();
    _cta.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: AppTheme.oceanDeep,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 268,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.28),
                      BlendMode.darken,
                    ),
                    child: Image.asset(
                      'assets/images/for_you_next_ocean.png',
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.12),
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: AppTheme.oceanDeep,
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x99052A4A),
                          Color(0x440B1F33),
                          Color(0xBB052A4A),
                        ],
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: Listenable.merge([_breathe, _pulse]),
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _OceanAtlasPainter(
                          nodes: _nodes,
                          stamped: widget.stampedContinents,
                          nextId: widget.nextContinent,
                          breathe: _breathe.value,
                          pulse: _pulse.value,
                        ),
                      );
                    },
                  ),
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _breathe,
                      builder: (context, _) {
                        final t = _breathe.value;
                        return Opacity(
                          opacity: 0.08 + t * 0.06,
                          child: Align(
                            alignment: Alignment(0, -0.42 + t * 0.08),
                            child: Container(
                              height: 28,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withValues(alpha: 0.35),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: Column(
                      children: [
                        const Spacer(flex: 3),
                        Text(
                          widget.styleTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            shadows: const [
                              Shadow(
                                color: Color(0x66000000),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.styleBody,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                            height: 1.35,
                            shadows: const [
                              Shadow(
                                color: Color(0x66000000),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(flex: 2),
                        Text(
                          l10n.homeNextOceanTitle,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppTheme.goldSoft,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.nextOceanBody,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.94),
                            height: 1.35,
                          ),
                        ),
                        if (widget.shopButtonLabel != null &&
                            widget.onOpenShop != null) ...[
                          const SizedBox(height: 10),
                          FadeTransition(
                            opacity: CurvedAnimation(
                              parent: _cta,
                              curve: Curves.easeOut,
                            ),
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.18),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _cta,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                              child: FilledButton(
                                key: const Key('for-you-shop'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.navy,
                                  minimumSize: const Size(0, 42),
                                ),
                                onPressed: widget.onOpenShop,
                                child: Text(widget.shopButtonLabel!),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _WaterlineMetrics(
                stampsLabel: widget.stampsLabel,
                stampsValue: widget.stampsValue,
                badgeLabel: widget.badgeLabel,
                badgeValue: widget.badgeValue,
                checklistLabel: widget.checklistLabel,
                checklistValue: widget.checklistValue,
                checklistHighlight: widget.checklistHighlight,
                onOpenStamps: widget.onOpenStamps,
                onOpenBadge: widget.onOpenBadge,
                onOpenChecklist: widget.onOpenChecklist,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterlineMetrics extends StatelessWidget {
  const _WaterlineMetrics({
    required this.stampsLabel,
    required this.stampsValue,
    required this.badgeLabel,
    required this.badgeValue,
    required this.checklistLabel,
    required this.checklistValue,
    required this.checklistHighlight,
    required this.onOpenStamps,
    required this.onOpenBadge,
    required this.onOpenChecklist,
  });

  final String stampsLabel;
  final String stampsValue;
  final String badgeLabel;
  final String badgeValue;
  final String checklistLabel;
  final String checklistValue;
  final bool checklistHighlight;
  final VoidCallback onOpenStamps;
  final VoidCallback onOpenBadge;
  final VoidCallback onOpenChecklist;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 1,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppTheme.gold.withValues(alpha: 0.55),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _WaterlineMark(
                key: const Key('for-you-stamps'),
                icon: Icons.approval_outlined,
                label: stampsLabel,
                value: stampsValue,
                onTap: onOpenStamps,
              ),
            ),
            const _WaterlineDivider(),
            Expanded(
              child: _WaterlineMark(
                key: const Key('for-you-badge'),
                icon: Icons.workspace_premium_outlined,
                label: badgeLabel,
                value: badgeValue,
                onTap: onOpenBadge,
              ),
            ),
            const _WaterlineDivider(),
            Expanded(
              child: _WaterlineMark(
                key: const Key('for-you-checklist'),
                icon: Icons.checklist_outlined,
                label: checklistLabel,
                value: checklistValue,
                highlight: checklistHighlight,
                onTap: onOpenChecklist,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WaterlineDivider extends StatelessWidget {
  const _WaterlineDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withValues(alpha: 0.18),
    );
  }
}

class _WaterlineMark extends StatelessWidget {
  const _WaterlineMark({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final accent = highlight ? AppTheme.goldSoft : Colors.white;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          children: [
            Icon(icon, size: 14, color: accent.withValues(alpha: 0.9)),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: accent.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: accent.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OceanAtlasPainter extends CustomPainter {
  _OceanAtlasPainter({
    required this.nodes,
    required this.stamped,
    required this.nextId,
    required this.breathe,
    required this.pulse,
  });

  final List<(String, double, double)> nodes;
  final Set<String> stamped;
  final String nextId;
  final double breathe;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final opened = [
      for (final n in nodes)
        if (stamped.contains(n.$1))
          Offset(n.$2 * size.width, n.$3 * size.height),
    ];
    if (opened.length >= 2) {
      final line = Paint()
        ..color = AppTheme.gold.withValues(alpha: 0.18 + breathe * 0.1)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(opened.first.dx, opened.first.dy);
      for (var i = 1; i < opened.length; i++) {
        path.lineTo(opened[i].dx, opened[i].dy);
      }
      canvas.drawPath(path, line);
    }

    for (final node in nodes) {
      final (id, nx, ny) = node;
      final center = Offset(nx * size.width, ny * size.height);
      final isOpen = stamped.contains(id);
      final isNext = id == nextId;

      if (isOpen) {
        final glowR = 10 + breathe * 4;
        canvas.drawCircle(
          center,
          glowR,
          Paint()
            ..color = AppTheme.gold.withValues(alpha: 0.22 + breathe * 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        canvas.drawCircle(
          center,
          4.5,
          Paint()..color = AppTheme.gold,
        );
        canvas.drawCircle(
          center,
          4.5,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      } else {
        canvas.drawCircle(
          center,
          5.5,
          Paint()
            ..color = const Color(0xFF8AA4B8).withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        canvas.drawCircle(
          center,
          2,
          Paint()..color = const Color(0xFF8AA4B8).withValues(alpha: 0.45),
        );
      }

      if (isNext) {
        final ring = 8 + pulse * 10;
        canvas.drawCircle(
          center,
          ring,
          Paint()
            ..color = AppTheme.goldSoft.withValues(alpha: 0.35 - pulse * 0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
        canvas.drawCircle(
          center,
          6,
          Paint()..color = AppTheme.goldSoft,
        );
        final tip = Path()
          ..moveTo(center.dx, center.dy + 11)
          ..lineTo(center.dx - 4, center.dy + 5)
          ..lineTo(center.dx + 4, center.dy + 5)
          ..close();
        canvas.drawPath(tip, Paint()..color = AppTheme.goldSoft);
      }
    }

    final rng = math.Random(7);
    final speck = Paint()
      ..color = Colors.white.withValues(alpha: 0.07 + breathe * 0.04);
    for (var i = 0; i < 18; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        0.8 + rng.nextDouble(),
        speck,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OceanAtlasPainter oldDelegate) {
    return oldDelegate.breathe != breathe ||
        oldDelegate.pulse != pulse ||
        oldDelegate.nextId != nextId ||
        oldDelegate.stamped != stamped;
  }
}
