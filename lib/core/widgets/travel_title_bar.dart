import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/bilingual_rotator.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_gate.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_gate.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// 항공 보딩패스를 살짝 얹은 홈 히어로. 홀로그램은 기울인 포일처럼 정적으로 입힙니다.
class TravelPosterHeader extends StatelessWidget {
  const TravelPosterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final english = lookupAppLocalizations(const Locale('en'));
    final session = SessionScope.of(context);
    final stats = DiverStoreScope.of(context).stats;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3E8C8),
              Color(0xFFE8D7B0),
              Color(0x00F6F7F9),
            ],
            stops: [0.0, 0.72, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x330B1F33),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Color(0x140B1F33),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: ClipPath(
              clipper: const _BoardingTicketClipper(),
              child: Stack(
                children: [
                  const Positioned.fill(child: _TicketPaper()),
                  const Positioned.fill(child: _HologramFoil()),
                  const Positioned.fill(child: _TicketGuides()),
                  const Positioned(
                    right: 8,
                    top: 58,
                    bottom: 18,
                    child: IgnorePointer(child: _TicketBarcode()),
                  ),
                  const Positioned(
                    left: 8,
                    bottom: 6,
                    child: IgnorePointer(child: _LuggageTag()),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 34, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _StampIcon(),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                english.appTitle.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.6,
                                  height: 1.1,
                                  color: AppTheme.navy,
                                ),
                              ),
                            ),
                            if (stats.isAdmin)
                              IconButton(
                                key: const Key('open-admin-mode-home'),
                                tooltip: l10n.adminMode,
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.admin_panel_settings_outlined,
                                  color: AppTheme.navy,
                                ),
                                onPressed: () => openAdminMode(context),
                              ),
                            if (stats.isBusiness)
                              IconButton(
                                key: const Key('open-partner-mode-home'),
                                tooltip: l10n.partnerTitle,
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.storefront_outlined,
                                  color: AppTheme.navy,
                                ),
                                onPressed: () => openPartnerMode(context),
                              ),
                            TextButton(
                              key: const Key('home-auth-button'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.navy,
                                minimumSize: const Size(0, 32),
                                padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6,
                                  height: 1,
                                ),
                              ),
                              onPressed: session.isSignedIn
                                  ? () => session.signOut()
                                  : null,
                              child: Text(
                                session.isSignedIn
                                    ? l10n.profileSignOut
                                    : l10n.authLogin,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const _FlightMeta(),
                        const SizedBox(height: 14),
                        Center(
                          child: BilingualRotator(
                            english: _SloganBlock(
                              title: english.homeWelcome,
                              subtitle: english.homeSubtitle,
                            ),
                            localized: _SloganBlock(
                              title: l10n.homeWelcome,
                              subtitle: l10n.homeSubtitle,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Center(child: _BoardingStub()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _TicketPaper extends StatelessWidget {
  const _TicketPaper();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD7B45C),
            Color(0xFFC4A35A),
            Color(0xFF8E7340),
            Color(0xFF3E6A78),
          ],
          stops: [0.0, 0.38, 0.78, 1.0],
        ),
      ),
    );
  }
}

class _HologramFoil extends StatelessWidget {
  const _HologramFoil();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: SweepGradient(
                center: Alignment(0.1, -0.35),
                colors: [
                  Color(0x00000000),
                  Color(0x6622B8D4),
                  Color(0x55C86AA8),
                  Color(0x88E8C15A),
                  Color(0x5528A888),
                  Color(0x443888B8),
                  Color(0x00000000),
                ],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1.0, -1.0),
                end: Alignment(0.6, 0.8),
                colors: [
                  Color(0x55FFFFFF),
                  Color(0x18FFFFFF),
                  Color(0x00000000),
                  Color(0x4422B8D4),
                  Color(0x33C86AA8),
                  Color(0x00000000),
                ],
                stops: [0.0, 0.14, 0.36, 0.58, 0.8, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardingTicketClipper extends CustomClipper<Path> {
  const _BoardingTicketClipper();

  static const _radius = 16.0;
  static const _notch = 9.0;
  static const _notchY = 64.0;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final y = math.min(_notchY, h * 0.36);
    final path = Path()
      ..moveTo(_radius, 0)
      ..lineTo(w - _radius, 0)
      ..arcToPoint(Offset(w, _radius), radius: const Radius.circular(_radius))
      ..lineTo(w, y - _notch)
      ..arcToPoint(
        Offset(w, y + _notch),
        radius: const Radius.circular(_notch),
        clockwise: false,
      )
      ..lineTo(w, h - _radius)
      ..arcToPoint(Offset(w - _radius, h), radius: const Radius.circular(_radius))
      ..lineTo(_radius, h)
      ..arcToPoint(Offset(0, h - _radius), radius: const Radius.circular(_radius))
      ..lineTo(0, y + _notch)
      ..arcToPoint(
        Offset(0, y - _notch),
        radius: const Radius.circular(_notch),
        clockwise: false,
      )
      ..lineTo(0, _radius)
      ..arcToPoint(const Offset(_radius, 0), radius: const Radius.circular(_radius))
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TicketGuides extends StatelessWidget {
  const _TicketGuides();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _TicketGuidesPainter());
  }
}

class _TicketGuidesPainter extends CustomPainter {
  const _TicketGuidesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final y = math.min(64.0, size.height * 0.36);
    final dash = Paint()
      ..color = const Color(0x590B1F33)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    var x = 16.0;
    while (x < size.width - 16) {
      canvas.drawLine(Offset(x, y), Offset(x + 5, y), dash);
      x += 9;
    }

    final edge = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1.2, 1.2, size.width - 2.4, size.height - 2.4),
        const Radius.circular(15),
      ),
      edge,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TicketBarcode extends StatelessWidget {
  const _TicketBarcode();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      child: CustomPaint(painter: _BarcodePainter()),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  const _BarcodePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7);
    final paint = Paint()..color = AppTheme.navy.withValues(alpha: 0.55);
    var x = 0.0;
    while (x < size.width - 1.5) {
      final width = rng.nextBool() ? 1.2 : 2.1;
      if (rng.nextDouble() > 0.28) {
        canvas.drawRect(Rect.fromLTWH(x, 0, width, size.height), paint);
      }
      x += width + 1.1;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FlightMeta extends StatelessWidget {
  const _FlightMeta();

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(
      fontSize: 8,
      letterSpacing: 1.3,
      fontWeight: FontWeight.w700,
      color: Color(0x990B1F33),
      height: 1,
    );
    const value = TextStyle(
      fontSize: 12,
      letterSpacing: 0.6,
      fontWeight: FontWeight.w800,
      color: AppTheme.navy,
      height: 1.15,
    );
    return const Row(
      children: [
        _MetaCell(caption: 'FROM', value: 'SURFACE', labelStyle: label, valueStyle: value),
        _MetaCell(caption: 'TO', value: 'ABYSS', labelStyle: label, valueStyle: value),
        _MetaCell(caption: 'FLT', value: 'DT 07', labelStyle: label, valueStyle: value),
        _MetaCell(caption: 'GATE', value: '∞', labelStyle: label, valueStyle: value),
      ],
    );
  }
}

class _MetaCell extends StatelessWidget {
  const _MetaCell({
    required this.caption,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  final String caption;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(caption, style: labelStyle),
          const SizedBox(height: 3),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}

class _StampIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xF2FFF6DC),
        border: Border.all(color: AppTheme.navy, width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330B1F33),
            blurRadius: 0,
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/icons/app_icon.png',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(
            Icons.scuba_diving,
            color: AppTheme.navy,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _SloganBlock extends StatelessWidget {
  const _SloganBlock({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              height: 1.2,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.3,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: AppTheme.navy.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardingStub extends StatelessWidget {
  const _BoardingStub();

  @override
  Widget build(BuildContext context) {
    return Text(
      'BOARDING PASS  ·  SEVEN SEAS',
      style: TextStyle(
        fontSize: 9,
        letterSpacing: 1.8,
        fontWeight: FontWeight.w700,
        color: AppTheme.navy.withValues(alpha: 0.45),
      ),
    );
  }
}

class _LuggageTag extends StatelessWidget {
  const _LuggageTag();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.28,
      child: CustomPaint(
        size: const Size(54, 78),
        painter: _LuggageTagPainter(),
      ),
    );
  }
}

class _LuggageTagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, 10, size.width - 12, size.height - 12),
      const Radius.circular(6),
    );
    final fill = Paint()..color = const Color(0xF2FBF4DE);
    final ink = Paint()
      ..color = AppTheme.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(body, fill);
    canvas.drawRRect(body, ink);

    final stripe = Paint()..color = const Color(0xFFB42318);
    canvas.drawRect(Rect.fromLTWH(6, 28, size.width - 12, 11), stripe);

    final hole = Offset(size.width / 2, 18);
    canvas.drawCircle(hole, 4.2, Paint()..color = const Color(0xFFD4A84A));
    canvas.drawCircle(
      hole,
      4.2,
      Paint()
        ..color = AppTheme.navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final dash = Paint()
      ..color = const Color(0x660B1F33)
      ..strokeWidth = 1;
    var x = 10.0;
    while (x < size.width - 10) {
      canvas.drawLine(Offset(x, 42), Offset(x + 3, 42), dash);
      x += 6;
    }

    final title = TextPainter(
      text: const TextSpan(
        text: 'DIVE',
        style: TextStyle(
          color: AppTheme.navy,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    title.paint(canvas, Offset((size.width - title.width) / 2, 46));

    final code = TextPainter(
      text: const TextSpan(
        text: 'SS-07',
        style: TextStyle(
          color: AppTheme.navy,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    code.paint(canvas, Offset((size.width - code.width) / 2, 58));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
