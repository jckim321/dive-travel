import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// One piece of a planned-trip story. Kind plus the written text.
enum StoryBlockKind {
  heading,
  paragraph,
  quote,
  list,
  divider,
  photo,
  video;

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
  const StoryBlock({required this.kind, this.text = '', this.url = ''});

  /// One story holds at most this many photo blocks.
  static const maxPhotos = 30;

  /// One story holds at most this many video blocks.
  static const maxVideos = 3;

  /// One video file must be this size or smaller.
  static const maxVideoBytes = 100 * 1024 * 1024;

  final StoryBlockKind kind;
  final String text;

  /// Public photo or video URL.
  final String url;

  /// Caption for a photo or video. Other blocks keep their words in [text].
  String get caption => text;

  static bool isMedia(StoryBlockKind kind) =>
      kind == StoryBlockKind.photo || kind == StoryBlockKind.video;

  /// Null when an mp4 of an allowed size can be uploaded.
  static String? videoRejectReason({required String name, required int size}) {
    if (!name.trim().toLowerCase().endsWith('.mp4')) {
      return 'mp4 파일만 올릴 수 있습니다.';
    }
    if (size > maxVideoBytes) {
      return '동영상은 100MB 이하만 올릴 수 있습니다.';
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    if (isMedia(kind)) {
      return {
        'kind': kind.name,
        'url': url,
        'caption': text,
      };
    }
    return {
      'kind': kind.name,
      'text': text,
    };
  }

  static StoryBlock fromMap(Map<String, dynamic> data) {
    final kind = StoryBlockKind.parse(data['kind']);
    final caption = data['caption'] as String?;
    return StoryBlock(
      kind: kind,
      text: caption ?? (data['text'] as String? ?? ''),
      url: data['url'] as String? ?? '',
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
        if (block.kind != StoryBlockKind.divider &&
            !isMedia(block.kind) &&
            block.text.trim().isNotEmpty)
          block.text.trim()
        else if (isMedia(block.kind) && block.text.trim().isNotEmpty)
          block.text.trim(),
    ].join('\n');
  }

  static int photoCount(List<StoryBlock> blocks) => _mediaCount(
        blocks,
        StoryBlockKind.photo,
      );

  static int videoCount(List<StoryBlock> blocks) => _mediaCount(
        blocks,
        StoryBlockKind.video,
      );

  static int _mediaCount(List<StoryBlock> blocks, StoryBlockKind kind) {
    var count = 0;
    for (final block in blocks) {
      if (block.kind == kind && block.url.trim().isNotEmpty) {
        count += 1;
      }
    }
    return count;
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
        for (var i = 0; i < blocks.length; i++) ...[
          const SizedBox(height: 8),
          switch (blocks[i].kind) {
            StoryBlockKind.heading => Text.rich(
                TextSpan(
                  children: storyInlineSpans(
                    blocks[i].text,
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
                      blocks[i].text,
                      body.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              ),
            StoryBlockKind.photo => _StoryPhoto(block: blocks[i], index: i),
            StoryBlockKind.video => _StoryVideo(block: blocks[i], index: i),
            StoryBlockKind.list => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in blocks[i].text.split('\n'))
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
                TextSpan(children: storyInlineSpans(blocks[i].text, body)),
              ),
          },
        ],
      ],
    );
  }
}

class _StoryPhoto extends StatelessWidget {
  const _StoryPhoto({required this.block, required this.index});

  final StoryBlock block;
  final int index;

  @override
  Widget build(BuildContext context) {
    final caption = block.caption.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _frame(block.url),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(caption),
        ],
      ],
    );
  }

  Widget _frame(String url) {
    final key = Key('story-photo-$index');
    if (url.isEmpty || url.startsWith('memory://')) {
      return SizedBox(
        key: key,
        height: 180,
        width: double.infinity,
        child: const ColoredBox(color: Color(0xFF12324A)),
      );
    }
    return Image.network(
      url,
      key: key,
      height: 220,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const SizedBox(
        height: 180,
        width: double.infinity,
        child: ColoredBox(color: Color(0xFF12324A)),
      ),
    );
  }
}

class _StoryVideo extends StatefulWidget {
  const _StoryVideo({required this.block, required this.index});

  final StoryBlock block;
  final int index;

  @override
  State<_StoryVideo> createState() => _StoryVideoState();
}

class _StoryVideoState extends State<_StoryVideo> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final url = widget.block.url.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return;
    }
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;
    controller.initialize().then((_) {
      if (mounted) {
        setState(() {});
      }
    }).catchError((_) {
      if (mounted) {
        setState(() {});
      }
    });
    controller.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.block.caption.trim();
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          key: Key('story-video-${widget.index}'),
          height: 220,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF12324A)),
              if (ready) VideoPlayer(controller),
              Center(
                child: IconButton(
                  key: Key('story-video-play-${widget.index}'),
                  onPressed: ready
                      ? () {
                          if (controller.value.isPlaying) {
                            controller.pause();
                          } else {
                            controller.play();
                          }
                        }
                      : null,
                  icon: Icon(
                    ready && controller.value.isPlaying
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(caption),
        ],
      ],
    );
  }
}
