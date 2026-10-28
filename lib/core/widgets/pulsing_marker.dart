import 'package:flutter/material.dart';

class PulsingMarker extends StatefulWidget {
  const PulsingMarker({
    super.key,
    required this.color,
    this.isGolden = false,
    this.tooltip,
  });

  final Color color;
  final bool isGolden;
  final String? tooltip;

  @override
  State<PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<PulsingMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.isGolden ? 22.0 : 16.0;
    final core = widget.isGolden ? 9.0 : 7.0;
    final marker = SizedBox(
      width: glow,
      height: glow,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pulse = 0.82 + (_controller.value * 0.18);
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: glow * pulse,
                height: glow * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.42),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.95),
                      blurRadius: widget.isGolden ? 8 : 5,
                      spreadRadius: widget.isGolden ? 1.5 : 0.4,
                    ),
                  ],
                ),
              ),
              child!,
            ],
          );
        },
        child: Container(
          width: core,
          height: core,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFF6E4),
            border: Border.all(
              color: widget.isGolden
                  ? const Color(0xFF8C6424)
                  : const Color(0xFFD4AF57),
              width: 1.3,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip == null) {
      return marker;
    }

    return Tooltip(message: widget.tooltip!, child: marker);
  }
}
