import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/theme/region_neon.dart';

/// One-shot 「NEW SEA」 stamp. The same region id is shown at most once
/// per app session, and the overlay ignores pointers so the page underneath
/// stays usable while it plays.
abstract final class NewSeaStamp {
  static const duration = Duration(milliseconds: 1500);

  static final Set<String> _shownRegionIds = <String>{};

  @visibleForTesting
  static void debugReset() => _shownRegionIds.clear();

  static void show(
    BuildContext context, {
    required String regionId,
    required String regionName,
  }) {
    if (regionId.isEmpty || !_shownRegionIds.add(regionId)) {
      return;
    }
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      _shownRegionIds.remove(regionId);
      return;
    }
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _NewSeaStampOverlay(
        regionName: regionName,
        onDone: () {
          if (entry.mounted) {
            entry.remove();
          }
        },
      ),
    );
    overlay.insert(entry);
  }
}

/// Starts a little large and settles to 1. Holds there, then the overlay
/// removes itself at [NewSeaStamp.duration].
double newSeaStampScale(double t) {
  const settle = 0.28;
  if (t >= settle) {
    return 1;
  }
  final u = Curves.easeOutCubic.transform(t / settle);
  return 1.22 - (0.22 * u);
}

double newSeaStampOpacity(double t) {
  if (t < 0.04) {
    return t / 0.04;
  }
  if (t > 0.9) {
    return ((1 - t) / 0.1).clamp(0.0, 1.0);
  }
  return 1;
}

class _NewSeaStampOverlay extends StatefulWidget {
  const _NewSeaStampOverlay({
    required this.regionName,
    required this.onDone,
  });

  final String regionName;
  final VoidCallback onDone;

  @override
  State<_NewSeaStampOverlay> createState() => _NewSeaStampOverlayState();
}

class _NewSeaStampOverlayState extends State<_NewSeaStampOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Timer _timer;
  var _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: NewSeaStamp.duration,
    );
    _controller.forward();
    // The last vsync can land a fraction short of the duration and leave
    // the status on forward. The clock, not the status, owns dismissal.
    _timer = Timer(NewSeaStamp.duration, _finish);
  }

  void _finish() {
    if (_finished) {
      return;
    }
    _finished = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        key: const Key('new-sea-stamp'),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            return Opacity(
              opacity: newSeaStampOpacity(t),
              child: Center(
                child: Transform.scale(
                  key: const Key('new-sea-stamp-scale'),
                  scale: newSeaStampScale(t),
                  child: child,
                ),
              ),
            );
          },
          child: _NewSeaStampFace(regionName: widget.regionName),
        ),
      ),
    );
  }
}

class _NewSeaStampFace extends StatelessWidget {
  const _NewSeaStampFace({required this.regionName});

  final String regionName;

  @override
  Widget build(BuildContext context) {
    final ink = regionNeonColor(1);
    return SizedBox(
      width: 168,
      height: 168,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xF016344A),
          border: Border.all(color: ink, width: 4),
          boxShadow: [
            BoxShadow(color: ink.withValues(alpha: 0.35), blurRadius: 18),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.goldSoft, width: 1.2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'NEW SEA',
                    key: const Key('new-sea-stamp-mark'),
                    style: TextStyle(
                      color: ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    regionName,
                    key: const Key('new-sea-stamp-name'),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
