import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/story_block.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';

/// Block editor for a planned-trip story.
/// Wide screens show the full toolbar. Narrow screens show bold, heading,
/// and list, and keep the rest behind 더보기.
class StoryBlockEditor extends StatefulWidget {
  const StoryBlockEditor({super.key, required this.initial, required this.onChanged});

  final List<StoryBlock> initial;
  final ValueChanged<List<StoryBlock>> onChanged;

  @override
  State<StoryBlockEditor> createState() => _StoryBlockEditorState();
}

class _StoryBlockEditorState extends State<StoryBlockEditor> {
  late List<StoryBlock> _blocks;
  late List<TextEditingController> _controllers;
  var _focus = 0;

  @override
  void initState() {
    super.initState();
    _blocks = [
      for (final block in widget.initial)
        StoryBlock(kind: block.kind, text: block.text),
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
        StoryBlock(kind: _blocks[i].kind, text: _controllers[i].text),
    ]);
  }

  void _applyKind(StoryBlockKind kind) {
    final index = _focus.clamp(0, _blocks.length - 1);
    final text = _controllers[index].text;
    final current = _blocks[index].kind;
    if (current == kind) {
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
    final controller = _controllers[_focus.clamp(0, _controllers.length - 1)];
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
          _icon(const Key('planner-story-photo'), Icons.image_outlined, '사진', _soon),
          _icon(const Key('planner-story-video'), Icons.videocam_outlined, '동영상', _soon),
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
      case 'video':
      case 'map':
        _soon();
    }
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
    final style = TextStyle(
      color: PartnerTheme.text,
      height: 1.45,
      fontSize: block.kind == StoryBlockKind.heading ? 20 : 15,
      fontWeight: block.kind == StoryBlockKind.heading ? FontWeight.w800 : FontWeight.w500,
      fontStyle: block.kind == StoryBlockKind.quote ? FontStyle.italic : FontStyle.normal,
    );
    return TextField(
      key: Key(index == 0 ? 'planner-trip-story' : 'planner-story-block-$index'),
      controller: _controllers[index],
      minLines: block.kind == StoryBlockKind.heading ? 1 : 2,
      maxLines: 8,
      style: style,
      cursorColor: PartnerTheme.accent,
      onTap: () => _focus = index,
      onChanged: (_) => _emit(),
      decoration: InputDecoration(
        hintText: index == 0 ? '여행 이야기를 적어 주세요' : null,
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
}
