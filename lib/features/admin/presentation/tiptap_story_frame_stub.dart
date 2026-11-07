import 'package:flutter/material.dart';

/// Non-web placeholder. The trial Tiptap frame only runs in the browser.
class TipTapStoryFrame extends StatelessWidget {
  const TipTapStoryFrame({
    super.key,
    this.initialHtml = '',
    this.onHtmlChanged,
    this.height = 420,
  });

  final String initialHtml;
  final ValueChanged<String>? onHtmlChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('planner-tiptap-frame'),
      height: height,
      child: const Center(
        child: Text('새 편집기는 웹에서만 열립니다.'),
      ),
    );
  }
}
