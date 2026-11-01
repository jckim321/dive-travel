import 'package:flutter/material.dart';

/// One piece of a planned-trip story. Kind plus the written text.
enum StoryBlockKind {
  heading,
  paragraph,
  quote,
  list,
  divider;

  static StoryBlockKind parse(Object? raw) {
    final name = raw?.toString() ?? '';
    for (final kind in StoryBlockKind.values) {
      if (kind.name == name) {
        return kind;
      }
    }
    return StoryBlockKind.paragraph;
  }
}

class StoryBlock {
  const StoryBlock({required this.kind, this.text = ''});

  final StoryBlockKind kind;
  final String text;

  Map<String, dynamic> toMap() => {
        'kind': kind.name,
        'text': text,
      };

  static StoryBlock fromMap(Map<String, dynamic> data) {
    return StoryBlock(
      kind: StoryBlockKind.parse(data['kind']),
      text: data['text'] as String? ?? '',
    );
  }

  static List<StoryBlock> listFrom(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (item is Map<String, dynamic>)
          StoryBlock.fromMap(item)
        else if (item is Map)
          StoryBlock.fromMap(Map<String, dynamic>.from(item)),
    ];
  }

  /// Editor seed. Stored blocks win. An older schedule string becomes one paragraph.
  static List<StoryBlock> seed({
    required List<StoryBlock> stored,
    required String legacySchedule,
  }) {
    if (stored.isNotEmpty) {
      return [for (final block in stored) block];
    }
    final text = legacySchedule.trim();
    if (text.isNotEmpty) {
      return [StoryBlock(kind: StoryBlockKind.paragraph, text: text)];
    }
    return const [StoryBlock(kind: StoryBlockKind.paragraph)];
  }

  /// Plain text kept on `schedule` so older readers still have the words.
  static String plainText(List<StoryBlock> blocks) {
    return [
      for (final block in blocks)
        if (block.kind != StoryBlockKind.divider && block.text.trim().isNotEmpty)
          block.text.trim(),
    ].join('\n');
  }
}

/// Bold `**`, italic `*`, underline `++` inside a block's text.
List<InlineSpan> storyInlineSpans(String input, TextStyle style) {
  final spans = <InlineSpan>[];
  final buffer = StringBuffer();
  var bold = false;
  var italic = false;
  var underline = false;
  var index = 0;

  void flush() {
    if (buffer.isEmpty) {
      return;
    }
    spans.add(
      TextSpan(
        text: buffer.toString(),
        style: style.copyWith(
          fontWeight: bold ? FontWeight.w800 : style.fontWeight,
          fontStyle: italic ? FontStyle.italic : style.fontStyle,
          decoration: underline ? TextDecoration.underline : style.decoration,
        ),
      ),
    );
    buffer.clear();
  }

  while (index < input.length) {
    if (input.startsWith('**', index)) {
      flush();
      bold = !bold;
      index += 2;
      continue;
    }
    if (input.startsWith('++', index)) {
      flush();
      underline = !underline;
      index += 2;
      continue;
    }
    if (input.startsWith('*', index)) {
      flush();
      italic = !italic;
      index += 1;
      continue;
    }
    buffer.write(input[index]);
    index += 1;
  }
  flush();
  if (spans.isEmpty) {
    spans.add(TextSpan(text: '', style: style));
  }
  return spans;
}

/// Guest view of [story_blocks].
class StoryBlockView extends StatelessWidget {
  const StoryBlockView({super.key, required this.blocks});

  final List<StoryBlock> blocks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodySmall ?? const TextStyle(fontSize: 13);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in blocks) ...[
          const SizedBox(height: 8),
          switch (block.kind) {
            StoryBlockKind.heading => Text.rich(
                TextSpan(
                  children: storyInlineSpans(
                    block.text,
                    (theme.textTheme.titleMedium ?? body).copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            StoryBlockKind.quote => Container(
                padding: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 3,
                    ),
                  ),
                ),
                child: Text.rich(
                  TextSpan(
                    children: storyInlineSpans(
                      block.text,
                      body.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              ),
            StoryBlockKind.list => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in block.text.split('\n'))
                    if (line.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: '• '),
                              ...storyInlineSpans(line.trim(), body),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            StoryBlockKind.divider => const Divider(height: 16),
            StoryBlockKind.paragraph => Text.rich(
                TextSpan(children: storyInlineSpans(block.text, body)),
              ),
          },
        ],
      ],
    );
  }
}
