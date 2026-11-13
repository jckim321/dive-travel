import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/models/shop_resort_info.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/explore/presentation/partner_empty_seat_products.dart';
import 'package:dive_travel_app/features/profile/presentation/flight_link_sheet.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

const _stubHeight = 78.0;

/// Ticket on My. The diving passport widget stays in the app and is not shown here.
class BoardingPassCard extends StatelessWidget {
  const BoardingPassCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final next = _nextTrip(store.bookings, today);
    final trip = next == null ? null : _tripFacts(store, next);
    final soon = trip != null && trip.daysUntil <= 7;
    return _SoonGlow(
      active: soon,
      child: _Ticket(
        l10n: l10n,
        trip: trip,
        onOpen: () {
          showFlightLinkSheet(
            context,
            arrivalAirport: trip?.arrival,
            depart: trip?.depart,
            ret: trip?.ret,
          );
        },
      ),
    );
  }
}

class _TripFacts {
  const _TripFacts({
    required this.arrival,
    required this.place,
    required this.depart,
    required this.ret,
    required this.daysUntil,
  });

  final String? arrival;
  final String place;
  final DateTime depart;
  final DateTime? ret;
  final int daysUntil;
}

TourBooking? _nextTrip(List<TourBooking> bookings, DateTime today) {
  TourBooking? next;
  for (final booking in bookings) {
    final start = DateTime(
      booking.scheduledFor.year,
      booking.scheduledFor.month,
      booking.scheduledFor.day,
    );
    if (!booking.isActive || start.isBefore(today)) {
      continue;
    }
    if (next == null || booking.scheduledFor.isBefore(next.scheduledFor)) {
      next = booking;
    }
  }
  return next;
}

_TripFacts _tripFacts(DiverStore store, TourBooking booking) {
  final live = store.liveStatsFor(booking.shopId);
  final code = normalizeNearestAirport(live?.nearestAirport ?? '');
  final hub = (live?.nearestHub ?? '').trim();
  final location = (live?.location ?? '').trim();
  ShopProduct? product;
  if (live != null && booking.productId.isNotEmpty) {
    for (final item in live.readerProducts) {
      if (item.id == booking.productId) {
        product = item;
        break;
      }
    }
  }
  final depart = DateTime(
    booking.scheduledFor.year,
    booking.scheduledFor.month,
    booking.scheduledFor.day,
  );
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return _TripFacts(
    arrival: code.isEmpty ? null : code,
    place: hub.isNotEmpty ? hub : location,
    depart: depart,
    ret: product == null
        ? null
        : buyerReturnDay(
            departure: depart,
            durationLabel: product.durationLabel,
          ),
    daysUntil: depart.difference(today).inDays,
  );
}

class _SoonGlow extends StatefulWidget {
  const _SoonGlow({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_SoonGlow> createState() => _SoonGlowState();
}

class _SoonGlowState extends State<_SoonGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_SoonGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (widget.active && !reduce) {
      if (!_breath.isAnimating) {
        _breath.repeat();
      }
    } else {
      _breath.stop();
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return widget.child;
    }
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      return _glow(0.35, widget.child);
    }
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final wave = math.sin(_breath.value * math.pi);
        return _glow(wave, child!);
      },
      child: widget.child,
    );
  }

  Widget _glow(double wave, Widget child) {
    final teal = 0.10 + (0.12 * wave);
    final gold = 0.06 + (0.08 * wave);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.oceanLight.withValues(alpha: teal),
            blurRadius: 16 + (8 * wave),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppTheme.gold.withValues(alpha: gold),
            blurRadius: 20 + (6 * wave),
            spreadRadius: -2,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Ticket extends StatelessWidget {
  const _Ticket({
    required this.l10n,
    required this.trip,
    required this.onOpen,
  });

  final AppLocalizations l10n;
  final _TripFacts? trip;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final booked = trip;
    final dest = booked?.arrival ?? '???';
    final destLabel = booked == null
        ? '다음 바다는 어디예요?'
        : booked.place;
    final when = booked == null ? 'NEXT OCEAN' : _when(booked);
    return GestureDetector(
      key: const Key('profile-boarding-pass'),
      onTap: onOpen,
      child: Stack(
        children: [
          CustomPaint(
            painter: const _TicketPainter(),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text(
                        'BOARDING PASS',
                        style: TextStyle(
                          color: AppTheme.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        when,
                        key: const Key('profile-boarding-when'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(child: _CodeBlock(code: 'ICN', label: '인천')),
                      if (booked != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            children: [
                              Text(
                                booked.daysUntil <= 0
                                    ? l10n.profileTripDdayToday
                                    : l10n.profileTripDday(booked.daysUntil),
                                key: const Key('profile-boarding-dday'),
                                style: const TextStyle(
                                  color: AppTheme.gold,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '출발까지',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: _CodeBlock(
                          code: dest,
                          label: destLabel,
                          alignEnd: true,
                          codeKey: const Key('profile-boarding-dest'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: _stubHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${l10n.profileFlightSearch} / 결제는 연결 앱에서',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      key: const Key('profile-boarding-open'),
                      onPressed: onOpen,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.goldSoft,
                        side: const BorderSide(color: AppTheme.gold),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        '열기',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: _stubHeight - 9,
            height: 18,
            child: IgnorePointer(
              child: Icon(Icons.flight, size: 16, color: AppTheme.goldSoft),
            ),
          ),
        ],
      ),
    );
  }

  String _when(_TripFacts trip) {
    final start = _md(trip.depart);
    final end = trip.ret;
    if (end == null) {
      return start;
    }
    return '$start – ${_md(end)}';
  }

  String _md(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '$month.$date';
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({
    required this.code,
    required this.label,
    this.alignEnd = false,
    this.codeKey,
  });

  final String code;
  final String label;
  final bool alignEnd;
  final Key? codeKey;

  @override
  Widget build(BuildContext context) {
    final align = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = alignEnd ? TextAlign.end : TextAlign.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          code,
          key: codeKey,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            height: 1,
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: textAlign,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}

class _TicketPainter extends CustomPainter {
  const _TicketPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = _path(size);
    final bounds = Offset.zero & size;
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF052A4A),
          Color(0xFF0B3A4F),
          AppTheme.navy,
        ],
      ).createShader(bounds);
    canvas.drawPath(path, fill);
    final line = size.height - _stubHeight;
    _dash(canvas, size.width, line);
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = AppTheme.gold.withValues(alpha: 0.85);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant _TicketPainter oldDelegate) => false;

  Path _path(Size size) {
    const radius = 18.0;
    const notch = 11.0;
    final y = size.height - _stubHeight;
    final path = Path()
      ..moveTo(radius, 0)
      ..lineTo(size.width - radius, 0)
      ..arcToPoint(
        Offset(size.width, radius),
        radius: const Radius.circular(radius),
      )
      ..lineTo(size.width, y - notch)
      ..arcToPoint(
        Offset(size.width, y + notch),
        radius: const Radius.circular(notch),
        clockwise: false,
      )
      ..lineTo(size.width, size.height - radius)
      ..arcToPoint(
        Offset(size.width - radius, size.height),
        radius: const Radius.circular(radius),
      )
      ..lineTo(radius, size.height)
      ..arcToPoint(
        Offset(0, size.height - radius),
        radius: const Radius.circular(radius),
      )
      ..lineTo(0, y + notch)
      ..arcToPoint(
        Offset(0, y - notch),
        radius: const Radius.circular(notch),
        clockwise: false,
      )
      ..lineTo(0, radius)
      ..arcToPoint(
        Offset(radius, 0),
        radius: const Radius.circular(radius),
      )
      ..close();
    return path;
  }

  void _dash(Canvas canvas, double width, double y) {
    final paint = Paint()
      ..color = AppTheme.gold.withValues(alpha: 0.7)
      ..strokeWidth = 1.1;
    const dash = 5.0;
    const gap = 4.0;
    const edge = 18.0;
    const hole = 14.0;
    final mid = width / 2;
    var x = edge;
    while (x < width - edge) {
      final end = math.min(x + dash, width - edge);
      if (end <= mid - hole || x >= mid + hole) {
        canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      }
      x += dash + gap;
    }
  }
}
