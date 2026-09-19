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
    final size = widget.isGolden ? 16.0 : 12.0;
    final marker = ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.3).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color,
                blurRadius: widget.isGolden ? 14 : 8,
                spreadRadius: widget.isGolden ? 4 : 2,
              ),
            ],
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
