import 'dart:async';

import 'package:flutter/material.dart';

/// 영어를 먼저 보여 주고, 이후 번역과 자리 이동 없이 교차 페이드합니다.
class BilingualRotator extends StatefulWidget {
  const BilingualRotator({
    super.key,
    required this.english,
    required this.localized,
    this.interval = const Duration(milliseconds: 2200),
    this.alignment = Alignment.center,
  });

  final Widget english;
  final Widget localized;
  final Duration interval;
  final Alignment alignment;

  @override
  State<BilingualRotator> createState() => _BilingualRotatorState();
}

class _BilingualRotatorState extends State<BilingualRotator> {
  var _showEnglish = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) {
        return;
      }
      setState(() => _showEnglish = !_showEnglish);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: widget.alignment,
      children: [
        IgnorePointer(
          ignoring: !_showEnglish,
          child: AnimatedOpacity(
            opacity: _showEnglish ? 1 : 0,
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeInOut,
            child: widget.english,
          ),
        ),
        IgnorePointer(
          ignoring: _showEnglish,
          child: AnimatedOpacity(
            opacity: _showEnglish ? 0 : 1,
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeInOut,
            child: widget.localized,
          ),
        ),
      ],
    );
  }
}
