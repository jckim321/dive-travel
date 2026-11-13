import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/locale/app_locale.dart';

/// Two-language pill. The knob shows the short label and slides to the other
/// side. Extra languages, if added later, cycle to the next choice.
class LanguageSwitch extends StatefulWidget {
  const LanguageSwitch({super.key});

  @override
  State<LanguageSwitch> createState() => _LanguageSwitchState();
}

class _LanguageSwitchState extends State<LanguageSwitch>
    with SingleTickerProviderStateMixin {
  static const _width = 96.0;
  static const _height = 38.0;
  static const _knob = 30.0;
  static const _inset = 4.0;
  static const _green = Color(0xFF0F6E56);
  static const _blue = Color(0xFF185FA5);
  static const _ink = Color(0xFF0B1F33);

  static const _bubbles = <_Bubble>[
    _Bubble(dx: -8, size: 6, delay: 0),
    _Bubble(dx: 2, size: 10, delay: 0.06),
    _Bubble(dx: 11, size: 5, delay: 0.14),
    _Bubble(dx: -1, size: 8, delay: 0.1),
  ];

  late final AnimationController _bubblesCtrl;

  @override
  void initState() {
    super.initState();
    _bubblesCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _bubblesCtrl.dispose();
    super.dispose();
  }

  int _indexFor(String languageCode) {
    for (var i = 0; i < kAppLanguageChoices.length; i++) {
      if (kAppLanguageChoices[i].locale.languageCode == languageCode) {
        return i;
      }
    }
    return 0;
  }

  void _toggle(AppLocaleController controller) {
    final choices = kAppLanguageChoices;
    if (choices.isEmpty) {
      return;
    }
    final index = _indexFor(controller.locale.languageCode);
    final next = choices[(index + 1) % choices.length];
    controller.setLocale(next.locale);
    _bubblesCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final choices = kAppLanguageChoices;
    if (choices.isEmpty) {
      return const SizedBox.shrink();
    }
    final controller = AppLocaleScope.of(context);
    final index = _indexFor(controller.locale.languageCode);
    final current = choices[index];
    final span = choices.length <= 1 ? 0.0 : index / (choices.length - 1);
    final knobLeft = _inset + span * (_width - _inset * 2 - _knob);
    final knobOnLeft = span < 0.5;
    final track = Color.lerp(_green, _blue, span)!;

    return Semantics(
      key: const Key('language-switch'),
      button: true,
      label: current.nativeName,
      onTap: () => _toggle(controller),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _toggle(controller),
        child: SizedBox(
          width: _width,
          height: _height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: track,
                    borderRadius: BorderRadius.circular(_height / 2),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: knobOnLeft ? _knob + 2 : 8,
                    right: knobOnLeft ? 8 : _knob + 2,
                  ),
                  child: Align(
                    alignment: knobOnLeft
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Text(
                      current.nativeName,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _bubblesCtrl,
                builder: (context, _) {
                  final t = _bubblesCtrl.value;
                  if (t == 0) {
                    return const SizedBox.shrink();
                  }
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final bubble in _bubbles)
                        _risingBubble(bubble, t, knobLeft),
                    ],
                  );
                },
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                left: knobLeft,
                top: _inset,
                width: _knob,
                height: _knob,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      current.shortLabel,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _risingBubble(_Bubble bubble, double t, double knobLeft) {
    final span = 1 - bubble.delay;
    final progress = ((t - bubble.delay) / span).clamp(0.0, 1.0);
    final rise = Curves.easeOut.transform(progress) * 34;
    final opacity = (1 - progress).clamp(0.0, 1.0);
    final centerY = _inset + _knob / 2;
    return Positioned(
      left: knobLeft + _knob / 2 - bubble.size / 2 + bubble.dx,
      top: centerY - bubble.size / 2 - rise,
      child: IgnorePointer(
        child: Container(
          width: bubble.size,
          height: bubble.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: opacity),
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble {
  const _Bubble({
    required this.dx,
    required this.size,
    required this.delay,
  });

  final double dx;
  final double size;
  final double delay;
}
