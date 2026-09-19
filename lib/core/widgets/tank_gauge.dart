import 'package:flutter/material.dart';

class TankGauge extends StatelessWidget {
  const TankGauge({
    super.key,
    required this.progress,
    required this.isComplete,
    this.label,
    this.width = 88,
    this.bodyHeight = 200,
    this.neckWidth = 36,
    this.neckHeight = 18,
    this.borderWidth = 4,
    this.duration = const Duration(milliseconds: 1800),
    this.curve = Curves.elasticOut,
    this.fillColor,
    this.borderColor,
  });

  final double progress;
  final bool isComplete;
  final String? label;
  final double width;
  final double bodyHeight;
  final double neckWidth;
  final double neckHeight;
  final double borderWidth;
  final Duration duration;
  final Curve curve;
  final Color? fillColor;
  final Color? borderColor;

  factory TankGauge.compact({
    Key? key,
    required double progress,
    required bool isComplete,
    Color? fillColor,
    Color? borderColor,
  }) {
    return TankGauge(
      key: key,
      progress: progress,
      isComplete: isComplete,
      width: 28,
      bodyHeight: 56,
      neckWidth: 12,
      neckHeight: 7,
      borderWidth: 2,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      fillColor: fillColor,
      borderColor: borderColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ink = borderColor ?? Theme.of(context).colorScheme.primary;
    final fill = fillColor ??
        (isComplete
            ? const Color(0xFFC4A35A)
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.75));

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return SizedBox(
          width: width,
          height: neckHeight + bodyHeight,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                top: 0,
                child: Container(
                  width: neckWidth,
                  height: neckHeight,
                  decoration: BoxDecoration(
                    color: ink,
                    borderRadius: BorderRadius.circular(neckHeight / 3),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  width: width - 8,
                  height: bodyHeight,
                  decoration: BoxDecoration(
                    border: Border.all(color: ink, width: borderWidth),
                    borderRadius: BorderRadius.circular(bodyHeight / 5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(bodyHeight / 5 - 2),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: value,
                        widthFactor: 1,
                        child: ColoredBox(color: fill),
                      ),
                    ),
                  ),
                ),
              ),
              if (label != null)
                Positioned(
                  top: neckHeight + bodyHeight * 0.42,
                  child: Text(
                    label!,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
