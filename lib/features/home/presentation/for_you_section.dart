import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/travel_style.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/home/presentation/home_stay_card.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Boarding pass for the signed-in diver's next trip. Hidden with no trip.
class ForYouSection extends StatelessWidget {
  const ForYouSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trip = DiverStoreScope.of(context).nextTrip;
    if (trip == null) {
      return const SizedBox.shrink();
    }
    final days = TravelStyleAnalyzer.daysUntil(trip.scheduledFor);
    final lines = <String>[
      trip.shopName.trim(),
      if (trip.productName.trim().isNotEmpty &&
          trip.productName.trim() != trip.shopName.trim())
        trip.productName.trim(),
      homeDayLabel(trip.scheduledFor),
    ].where((line) => line.isNotEmpty).toList();

    return Column(
      key: const Key('home-for-you'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeForYouTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          key: const Key('for-you-panel'),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E8EE)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < lines.length; i++) ...[
                            if (i > 0) const SizedBox(height: 4),
                            Text(
                              lines[i],
                              style: TextStyle(
                                color: i == 0 ? AppTheme.navy : AppTheme.muted,
                                fontWeight: i == 0
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: i == 0 ? 16 : 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const CustomPaint(
                    painter: _TicketDashPainter(),
                    child: SizedBox(width: 1),
                  ),
                  ColoredBox(
                    color: homeTicketOrange,
                    child: SizedBox(
                      width: 112,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            l10n.homeBoardingUntil(days),
                            key: const Key('for-you-boarding-days'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TicketDashPainter extends CustomPainter {
  const _TicketDashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB7C0C9)
      ..strokeWidth = 1.4;
    const dash = 4.0;
    const gap = 3.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(0, y),
        Offset(0, math.min(y + dash, size.height)),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
