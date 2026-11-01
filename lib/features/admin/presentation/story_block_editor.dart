import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/story_block.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/storage/dive_video_picker.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';

/// Block editor for a planned-trip story.
/// Wide screens show the full toolbar. Narrow screens show bold, heading,
/// and list, and keep the rest behind 더보기.
class StoryBlockEditor extends StatefulWidget {
  const StoryBlockEditor({
    super.key,
    required this.initial,
    required this.onChanged,
    this.pickPhoto,
    this.uploadPhoto,
    this.pickVideo,
    this.uploadVideo,
  });

  final List<StoryBlock> initial;
  final ValueChanged<List<StoryBlock>> onChanged;

  /// Null uses the device photo picker.
  final Future<PickedPhoto?> Function()? pickPhoto;

  /// Uploads one photo the same way the shop gallery does, and returns its URL.
  final Future<String> Function(PickedPhoto photo)? uploadPhoto;

  /// Null uses the device video picker.
  final Future<PickedVideo?> Function()? pickVideo;

  /// Uploads one mp4 the same way R2 photos go up. [onProgress] is 0 to 1.
  final Future<String> Function(
    PickedVideo video,
    void Function(double progress) onProgress,
  )? uploadVideo;

  @override
  State<StoryBlockEditor> createState() => _StoryBlockEditorState();
}

class _StoryBlockEditorState extends State<StoryBlockEditor> {
  late List<StoryBlock> _blocks;
  late List<TextEditingController> _controllers;
  var _focus = 0;
  var _busy = false;
  double? _videoProgress;

  @override
  void initState() {
    super.initState();
    _blocks = [
      for (final block in widget.initial)
        StoryBlock(kind: block.kind, text: block.text, url: block.url),
    ];
    if (_blocks.isEmpty) {
      _blocks = const [StoryBlock(kind: StoryBlockKind.paragraph)];
    }
    _controllers = [
      for (final block in _blocks) TextEditingController(text: block.text),
    ];
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _emit() {
    widget.onChanged([
      for (var i = 0; i < _blocks.length; i++)
        StoryBlock(
          kind: _blocks[i].kind,
          text: _controllers[i].text,
          url: _blocks[i].url,
        ),
    ]);
  }

  void _applyKind(StoryBlockKind kind) {
    final index = _focus.clamp(0, _blocks.length - 1);
    final text = _controllers[index].text;
    final current = _blocks[index].kind;
    if (current == kind || StoryBlock.isMedia(current)) {
      if (StoryBlock.isMedia(current) && current != kind) {
        setState(() {
          _blocks.insert(index + 1, StoryBlock(kind: kind));
          _controllers.insert(index + 1, TextEditingController());
          _focus = index + 1;
        });
        _emit();
      }
      return;
    }
    setState(() {
      if (text.trim().isEmpty || current == StoryBlockKind.divider) {
        _blocks[index] = StoryBlock(kind: kind, text: text);
      } else {
        _blocks.insert(index + 1, const StoryBlock(kind: StoryBlockKind.paragraph));
        _blocks[index + 1] = StoryBlock(kind: kind);
        _controllers.insert(index + 1, TextEditingController());
        _focus = index + 1;
      }
    });
    _emit();
  }

  void _toggleMark(String marker) {
    final index = _focus.clamp(0, _controllers.length - 1);
    if (StoryBlock.isMedia(_blocks[index].kind)) {
      return;
    }
    final controller = _controllers[index];
    final text = controller.text;
    var start = controller.selection.start;
    var end = controller.selection.end;
    if (start < 0 || end < 0 || start == end) {
      start = 0;
      end = text.length;
    }
    if (end < start) {
      final swap = start;
      start = end;
      end = swap;
    }
    final selected = text.substring(start, end);
    final String next;
    if (selected.startsWith(marker) &&
        selected.endsWith(marker) &&
        selected.length >= marker.length * 2) {
      next = selected.substring(marker.length, selected.length - marker.length);
    } else {
      next = '$marker$selected$marker';
    }
    final updated = text.replaceRange(start, end, next);
    controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + next.length),
    );
    _emit();
  }

  void _soon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('준비 중')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        return Column(
          key: const Key('planner-story-editor'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _toolbar(compact),
            const SizedBox(height: 8),
            if (_videoProgress != null) ...[
              LinearProgressIndicator(
                key: const Key('planner-story-video-progress'),
                value: _videoProgress,
                minHeight: 6,
                color: PartnerTheme.accent,
                backgroundColor: PartnerTheme.border,
              ),
              const SizedBox(height: 4),
              Text(
                '올리는 중 ${(_videoProgress! * 100).round()}%',
                key: const Key('planner-story-video-progress-label'),
                style: const TextStyle(color: PartnerTheme.textDim, fontSize: 12),
              ),
              const SizedBox(height: 8),
            ],
            for (var i = 0; i < _blocks.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _block(i),
            ],
          ],
        );
      },
    );
  }

  Widget _toolbar(bool compact) {
    return Wrap(
      key: const Key('planner-story-toolbar'),
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (!compact)
          PopupMenuButton<StoryBlockKind>(
            key: const Key('planner-story-kind'),
            tooltip: '본문',
            onSelected: _applyKind,
            itemBuilder: (context) => const [
              PopupMenuItem(value: StoryBlockKind.paragraph, child: Text('문단')),
              PopupMenuItem(value: StoryBlockKind.heading, child: Text('제목')),
              PopupMenuItem(value: StoryBlockKind.quote, child: Text('인용')),
              PopupMenuItem(value: StoryBlockKind.list, child: Text('목록')),
              PopupMenuItem(value: StoryBlockKind.divider, child: Text('구분선')),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text('본문', style: TextStyle(color: PartnerTheme.text)),
            ),
          ),
        _icon(const Key('planner-story-bold'), Icons.format_bold, '굵게', () => _toggleMark('**')),
        if (compact)
          _icon(
            const Key('planner-story-heading'),
            Icons.title,
            '제목',
            () => _applyKind(StoryBlockKind.heading),
          ),
        if (!compact) ...[
          _icon(const Key('planner-story-italic'), Icons.format_italic, '기울임', () => _toggleMark('*')),
          _icon(
            const Key('planner-story-underline'),
            Icons.format_underline,
            '밑줄',
            () => _toggleMark('++'),
          ),
        ],
        _icon(
          const Key('planner-story-list'),
          Icons.format_list_bulleted,
          '목록',
          () => _applyKind(StoryBlockKind.list),
        ),
        if (!compact) ...[
          _icon(
            const Key('planner-story-quote'),
            Icons.format_quote,
            '인용',
            () => _applyKind(StoryBlockKind.quote),
          ),
          _icon(
            const Key('planner-story-divider'),
            Icons.horizontal_rule,
            '구분선',
            () => _applyKind(StoryBlockKind.divider),
          ),
          _icon(const Key('planner-story-photo'), Icons.image_outlined, '사진', () {
            _addPhoto();
          }),
          _icon(const Key('planner-story-video'), Icons.videocam_outlined, '동영상', () {
            _addVideo();
          }),
          _icon(const Key('planner-story-map'), Icons.map_outlined, '지도', _soon),
        ],
        if (compact)
          PopupMenuButton<String>(
            key: const Key('planner-story-more'),
            tooltip: '더보기',
            onSelected: _moreSelected,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'italic', child: Text('기울임')),
              PopupMenuItem(value: 'underline', child: Text('밑줄')),
              PopupMenuItem(value: 'quote', child: Text('인용')),
              PopupMenuItem(value: 'divider', child: Text('구분선')),
              PopupMenuItem(value: 'paragraph', child: Text('문단')),
              PopupMenuItem(value: 'photo', child: Text('사진')),
              PopupMenuItem(value: 'video', child: Text('동영상')),
              PopupMenuItem(value: 'map', child: Text('지도')),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text('더보기', style: TextStyle(color: PartnerTheme.text)),
            ),
          ),
      ],
    );
  }

  void _moreSelected(String value) {
    switch (value) {
      case 'italic':
        _toggleMark('*');
      case 'underline':
        _toggleMark('++');
      case 'quote':
        _applyKind(StoryBlockKind.quote);
      case 'divider':
        _applyKind(StoryBlockKind.divider);
      case 'paragraph':
        _applyKind(StoryBlockKind.paragraph);
      case 'photo':
        _addPhoto();
      case 'video':
        _addVideo();
      case 'map':
        _soon();
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addPhoto() async {
    if (_busy) {
      return;
    }
    if (StoryBlock.photoCount(_blocks) >= StoryBlock.maxPhotos) {
      _snack('사진은 30장까지 올릴 수 있습니다.');
      return;
    }
    final pick = widget.pickPhoto ?? const DivePhotoPicker().pick;
    final picked = await pick();
    if (!mounted || picked == null) {
      return;
    }
    if (StoryBlock.photoCount(_blocks) >= StoryBlock.maxPhotos) {
      _snack('사진은 30장까지 올릴 수 있습니다.');
      return;
    }
    final upload = widget.uploadPhoto;
    if (upload == null) {
      _snack('사진을 올리지 못했습니다.');
      return;
    }
    setState(() => _busy = true);
    try {
      final url = (await upload(picked)).trim();
      if (!mounted) {
        return;
      }
      if (url.isEmpty) {
        _snack('사진을 올리지 못했습니다.');
        return;
      }
      _insertPhoto(url);
    } catch (error) {
      if (mounted) {
        _snack('$error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _insertPhoto(String url) {
    _insertMedia(StoryBlockKind.photo, url);
  }

  Future<void> _addVideo() async {
    if (_busy) {
      return;
    }
    if (StoryBlock.videoCount(_blocks) >= StoryBlock.maxVideos) {
      _snack('동영상은 3개까지 올릴 수 있습니다.');
      return;
    }
    final pick = widget.pickVideo ?? const DiveVideoPicker().pick;
    final picked = await pick();
    if (!mounted || picked == null) {
      return;
    }
    if (StoryBlock.videoCount(_blocks) >= StoryBlock.maxVideos) {
      _snack('동영상은 3개까지 올릴 수 있습니다.');
      return;
    }
    final reason = StoryBlock.videoRejectReason(
      name: picked.fileName,
      size: picked.size,
    );
    if (reason != null) {
      _snack(reason);
      return;
    }
    final upload = widget.uploadVideo;
    if (upload == null) {
      _snack('동영상을 올리지 못했습니다.');
      return;
    }
    setState(() {
      _busy = true;
      _videoProgress = 0;
    });
    try {
      final url = (await upload(picked, (progress) {
        if (!mounted) {
          return;
        }
        setState(() => _videoProgress = progress.clamp(0, 1).toDouble());
      })).trim();
      if (!mounted) {
        return;
      }
      if (url.isEmpty) {
        _snack('동영상을 올리지 못했습니다.');
        return;
      }
      _insertMedia(StoryBlockKind.video, url);
    } catch (error) {
      if (mounted) {
        _snack('$error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _videoProgress = null;
        });
      }
    }
  }

  void _insertMedia(StoryBlockKind kind, String url) {
    final index = _blocks.isEmpty ? -1 : _focus.clamp(0, _blocks.length - 1);
    final at = index + 1;
    setState(() {
      _blocks.insert(at, StoryBlock(kind: kind, url: url));
      _controllers.insert(at, TextEditingController());
      _focus = at;
    });
    _emit();
  }

  void _movePhoto(int index, int delta) {
    _moveMedia(index, delta);
  }

  void _moveMedia(int index, int delta) {
    final next = index + delta;
    if (!StoryBlock.isMedia(_blocks[index].kind)) {
      return;
    }
    if (next < 0 || next >= _blocks.length) {
      return;
    }
    setState(() {
      final block = _blocks.removeAt(index);
      final controller = _controllers.removeAt(index);
      _blocks.insert(next, block);
      _controllers.insert(next, controller);
      _focus = next;
    });
    _emit();
  }

  void _removePhoto(int index) {
    _removeMedia(index);
  }

  void _removeMedia(int index) {
    if (!StoryBlock.isMedia(_blocks[index].kind)) {
      return;
    }
    setState(() {
      _controllers.removeAt(index).dispose();
      _blocks.removeAt(index);
      if (_blocks.isEmpty) {
        _blocks.add(const StoryBlock(kind: StoryBlockKind.paragraph));
        _controllers.add(TextEditingController());
      }
      _focus = index.clamp(0, _blocks.length - 1);
    });
    _emit();
  }

  Widget _icon(Key key, IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      key: key,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
      icon: Icon(icon, color: PartnerTheme.text, size: 20),
    );
  }

  Widget _block(int index) {
    final block = _blocks[index];
    if (block.kind == StoryBlockKind.divider) {
      return const Divider(color: PartnerTheme.border, height: 24);
    }
    if (block.kind == StoryBlockKind.photo) {
      return _photoBlock(index);
    }
    if (block.kind == StoryBlockKind.video) {
      return _videoBlock(index);
    }
    final style = TextStyle(
      color: PartnerTheme.text,
      height: 1.45,
      fontSize: block.kind == StoryBlockKind.heading ? 20 : 15,
      fontWeight: block.kind == StoryBlockKind.heading ? FontWeight.w800 : FontWeight.w500,
      fontStyle: block.kind == StoryBlockKind.quote ? FontStyle.italic : FontStyle.normal,
    );
    final firstText = _blocks.indexWhere(
      (block) =>
          block.kind != StoryBlockKind.divider &&
          !StoryBlock.isMedia(block.kind),
    );
    return TextField(
      key: Key(
        index == firstText ? 'planner-trip-story' : 'planner-story-block-$index',
      ),
      controller: _controllers[index],
      minLines: block.kind == StoryBlockKind.heading ? 1 : 2,
      maxLines: 8,
      style: style,
      cursorColor: PartnerTheme.accent,
      onTap: () => _focus = index,
      onChanged: (_) => _emit(),
      decoration: InputDecoration(
        hintText: index == firstText ? '여행 이야기를 적어 주세요' : null,
        filled: true,
        fillColor: PartnerTheme.bg,
        hintStyle: const TextStyle(color: PartnerTheme.textDim),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        prefixIcon: block.kind == StoryBlockKind.quote
            ? const Icon(Icons.format_quote, color: PartnerTheme.textDim, size: 18)
            : block.kind == StoryBlockKind.list
                ? const Icon(Icons.circle, color: PartnerTheme.textDim, size: 8)
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: PartnerTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: block.kind == StoryBlockKind.quote
                ? PartnerTheme.accent
                : PartnerTheme.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: PartnerTheme.accent),
        ),
      ),
    );
  }

  Widget _photoBlock(int index) {
    final url = _blocks[index].url;
    return Column(
      key: Key('planner-story-photo-block-$index'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (url.startsWith('memory://') || url.isEmpty)
          const SizedBox(
            height: 160,
            width: double.infinity,
            child: ColoredBox(color: Color(0xFF12324A)),
          )
        else
          Image.network(
            url,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox(
              height: 160,
              width: double.infinity,
              child: ColoredBox(color: Color(0xFF12324A)),
            ),
          ),
        const SizedBox(height: 6),
        TextField(
          key: Key('planner-story-photo-caption-$index'),
          controller: _controllers[index],
          maxLines: 1,
          style: const TextStyle(color: PartnerTheme.text, fontSize: 14),
          cursorColor: PartnerTheme.accent,
          onTap: () => _focus = index,
          onChanged: (_) => _emit(),
          decoration: InputDecoration(
            hintText: '한 줄 설명',
            filled: true,
            fillColor: PartnerTheme.bg,
            hintStyle: const TextStyle(color: PartnerTheme.textDim),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: PartnerTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: PartnerTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: PartnerTheme.accent),
            ),
          ),
        ),
        Row(
          children: [
            IconButton(
              key: Key('planner-story-photo-up-$index'),
              tooltip: '위로',
              onPressed: index == 0 ? null : () => _movePhoto(index, -1),
              icon: const Icon(Icons.arrow_upward, color: PartnerTheme.text, size: 18),
            ),
            IconButton(
              key: Key('planner-story-photo-down-$index'),
              tooltip: '아래로',
              onPressed: index == _blocks.length - 1
                  ? null
                  : () => _movePhoto(index, 1),
              icon: const Icon(Icons.arrow_downward, color: PartnerTheme.text, size: 18),
            ),
            IconButton(
              key: Key('planner-story-photo-delete-$index'),
              tooltip: '지우기',
              onPressed: () => _removePhoto(index),
              icon: const Icon(Icons.delete_outline, color: PartnerTheme.text, size: 18),
            ),
          ],
        ),
      ],
    );
  }

  Widget _videoBlock(int index) {
    return Column(
      key: Key('planner-story-video-block-$index'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(
          height: 160,
          width: double.infinity,
          child: ColoredBox(
            color: Color(0xFF12324A),
            child: Center(
              child: Icon(Icons.play_circle_outline, color: Colors.white, size: 48),
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: Key('planner-story-video-caption-$index'),
          controller: _controllers[index],
          maxLines: 1,
          style: const TextStyle(color: PartnerTheme.text, fontSize: 14),
          cursorColor: PartnerTheme.accent,
          onTap: () => _focus = index,
          onChanged: (_) => _emit(),
          decoration: InputDecoration(
            hintText: '한 줄 설명',
            filled: true,
            fillColor: PartnerTheme.bg,
            hintStyle: const TextStyle(color: PartnerTheme.textDim),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: PartnerTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: PartnerTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: PartnerTheme.accent),
            ),
          ),
        ),
        Row(
          children: [
            IconButton(
              key: Key('planner-story-video-up-$index'),
              tooltip: '위로',
              onPressed: index == 0 ? null : () => _moveMedia(index, -1),
              icon: const Icon(Icons.arrow_upward, color: PartnerTheme.text, size: 18),
            ),
            IconButton(
              key: Key('planner-story-video-down-$index'),
              tooltip: '아래로',
              onPressed: index == _blocks.length - 1
                  ? null
                  : () => _moveMedia(index, 1),
              icon: const Icon(Icons.arrow_downward, color: PartnerTheme.text, size: 18),
            ),
            IconButton(
              key: Key('planner-story-video-delete-$index'),
              tooltip: '지우기',
              onPressed: () => _removeMedia(index),
              icon: const Icon(Icons.delete_outline, color: PartnerTheme.text, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}
