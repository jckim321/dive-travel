import 'package:dive_travel_app/core/models/story_block.dart';

/// Allowed tags for planned-trip `story_html` (TipTap trial path).
const storyHtmlAllowedTags = <String>{
  'p',
  'h1',
  'h2',
  'h3',
  'strong',
  'em',
  'u',
  's',
  'a',
  'ul',
  'ol',
  'li',
  'blockquote',
  'hr',
  'br',
  'span',
};

const _alignTags = <String>{'p', 'h1', 'h2', 'h3'};

final _tagPattern = RegExp(
  r'<!--.*?-->|</?([a-zA-Z0-9]+)(\s[^>]*)?>',
  dotAll: true,
);

final _hrefPattern = RegExp(
  r'''href\s*=\s*(["'])(.*?)\1''',
  caseSensitive: false,
);

final _stylePattern = RegExp(
  r'''style\s*=\s*(["'])(.*?)\1''',
  caseSensitive: false,
);

final _safeHexColor = RegExp(
  r'^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$',
);

final _colorInStyle = RegExp(
  r'color\s*:\s*(#[0-9a-fA-F]{3,8})\b',
  caseSensitive: false,
);

final _alignInStyle = RegExp(
  r'text-align\s*:\s*(left|center|right|justify)\b',
  caseSensitive: false,
);

/// Keep only the allow-listed tags. `a` keeps http(s) href only.
/// `span` keeps a safe `#` color; `p`/`h1`–`h3` keep text-align.
String sanitizeStoryHtml(String raw) {
  if (raw.trim().isEmpty) {
    return '';
  }
  final out = StringBuffer();
  var index = 0;
  for (final match in _tagPattern.allMatches(raw)) {
    if (match.start > index) {
      // TipTap already encoded text nodes; copy them unchanged.
      out.write(raw.substring(index, match.start));
    }
    index = match.end;
    final full = match.group(0)!;
    if (full.startsWith('<!--')) {
      continue;
    }
    final name = (match.group(1) ?? '').toLowerCase();
    final closing = full.startsWith('</');
    final attrs = match.group(2) ?? '';
    if (!storyHtmlAllowedTags.contains(name)) {
      continue;
    }
    if (name == 'br' || name == 'hr') {
      out.write('<$name>');
      continue;
    }
    if (closing) {
      out.write('</$name>');
      continue;
    }
    if (name == 'a') {
      final hrefMatch = _hrefPattern.firstMatch(attrs);
      final href = hrefMatch?.group(2)?.trim() ?? '';
      if (!isAllowedStoryLinkUrl(href)) {
        continue;
      }
      out.write('<a href="${_escapeAttr(href)}">');
      continue;
    }
    if (name == 'span') {
      final color = _safeColorFromStyle(attrs);
      if (color == null) {
        continue;
      }
      out.write('<span style="color: $color">');
      continue;
    }
    if (_alignTags.contains(name)) {
      final align = _safeAlignFromStyle(attrs);
      if (align != null) {
        out.write('<$name style="text-align: $align">');
      } else {
        out.write('<$name>');
      }
      continue;
    }
    out.write('<$name>');
  }
  if (index < raw.length) {
    out.write(raw.substring(index));
  }
  return out.toString().trim();
}

String? _safeColorFromStyle(String attrs) {
  final styleMatch = _stylePattern.firstMatch(attrs);
  final style = styleMatch?.group(2) ?? '';
  final colorMatch = _colorInStyle.firstMatch(style);
  final color = colorMatch?.group(1)?.trim() ?? '';
  if (!_safeHexColor.hasMatch(color)) {
    return null;
  }
  return color;
}

String? _safeAlignFromStyle(String attrs) {
  final styleMatch = _stylePattern.firstMatch(attrs);
  final style = styleMatch?.group(2) ?? '';
  final alignMatch = _alignInStyle.firstMatch(style);
  return alignMatch?.group(1)?.toLowerCase();
}

/// Convert legacy [StoryBlock]s into TipTap-friendly HTML.
String storyBlocksToHtml(List<StoryBlock> blocks) {
  final out = StringBuffer();
  for (final block in blocks) {
    switch (block.kind) {
      case StoryBlockKind.heading:
        out.writeln('<h2>${_inlineMarkupToHtml(block.text)}</h2>');
      case StoryBlockKind.paragraph:
        out.writeln('<p>${_inlineMarkupToHtml(block.text)}</p>');
      case StoryBlockKind.quote:
        out.writeln(
          '<blockquote><p>${_inlineMarkupToHtml(block.text)}</p></blockquote>',
        );
      case StoryBlockKind.list:
        out.writeln(_listHtml(block.text, ordered: false));
      case StoryBlockKind.numbered:
        out.writeln(_listHtml(block.text, ordered: true));
      case StoryBlockKind.divider:
        out.writeln('<hr>');
      case StoryBlockKind.photo:
      case StoryBlockKind.video:
        final caption = block.text.trim();
        if (caption.isNotEmpty) {
          out.writeln('<p>${_escapeText(caption)}</p>');
        }
      case StoryBlockKind.map:
        final label = [
          block.placeName.trim(),
          block.text.trim(),
        ].where((part) => part.isNotEmpty).join(' · ');
        if (label.isNotEmpty) {
          out.writeln('<p>${_escapeText(label)}</p>');
        }
    }
  }
  final html = out.toString().trim();
  return html.isEmpty ? '<p></p>' : html;
}

/// True when the block list has photo, video, or map nodes.
bool storyBlocksHaveMedia(List<StoryBlock> blocks) {
  for (final block in blocks) {
    if (block.kind == StoryBlockKind.photo ||
        block.kind == StoryBlockKind.video ||
        block.kind == StoryBlockKind.map) {
      return true;
    }
  }
  return false;
}

String _listHtml(String raw, {required bool ordered}) {
  final lines = raw.split('\n');
  final tag = ordered ? 'ol' : 'ul';
  final buf = StringBuffer('<$tag>');
  for (final line in lines) {
    final text = line.trim();
    if (text.isEmpty) {
      continue;
    }
    buf.write('<li>${_inlineMarkupToHtml(text)}</li>');
  }
  buf.write('</$tag>');
  return buf.toString();
}

String _inlineMarkupToHtml(String input) {
  final out = StringBuffer();
  var bold = false;
  var italic = false;
  var underline = false;
  var index = 0;
  while (index < input.length) {
    final colorOpen = RegExp(r'\{\{(빨강|주황|초록|파랑|보라|회색):')
        .matchAsPrefix(input, index);
    if (colorOpen != null) {
      final closeAt = _findColorClose(input, colorOpen.end);
      if (closeAt != null) {
        final inner = input.substring(colorOpen.end, closeAt - 2);
        out.write(_inlineMarkupToHtml(inner));
        index = closeAt;
        continue;
      }
    }
    if (input.startsWith('**', index)) {
      out.write(bold ? '</strong>' : '<strong>');
      bold = !bold;
      index += 2;
      continue;
    }
    if (input.startsWith('++', index)) {
      out.write(underline ? '</u>' : '<u>');
      underline = !underline;
      index += 2;
      continue;
    }
    if (input.startsWith('*', index)) {
      out.write(italic ? '</em>' : '<em>');
      italic = !italic;
      index += 1;
      continue;
    }
    final link = RegExp(r'\[([^\]]*)\]\((https?://[^)\s]+)\)')
        .matchAsPrefix(input, index);
    if (link != null && isAllowedStoryLinkUrl(link.group(2)!)) {
      final label = link.group(1)!;
      final url = link.group(2)!;
      final body = label.isEmpty ? url : label;
      out.write('<a href="${_escapeAttr(url)}">${_escapeText(body)}</a>');
      index = link.end;
      continue;
    }
    out.write(_escapeText(input[index]));
    index += 1;
  }
  if (bold) {
    out.write('</strong>');
  }
  if (italic) {
    out.write('</em>');
  }
  if (underline) {
    out.write('</u>');
  }
  return out.toString();
}

int? _findColorClose(String input, int from) {
  var depth = 1;
  var i = from;
  while (i < input.length) {
    if (input.startsWith('}}', i)) {
      depth -= 1;
      if (depth == 0) {
        return i + 2;
      }
      i += 2;
      continue;
    }
    if (RegExp(r'\{\{(빨강|주황|초록|파랑|보라|회색):').matchAsPrefix(input, i) !=
        null) {
      depth += 1;
      final again =
          RegExp(r'\{\{(빨강|주황|초록|파랑|보라|회색):').matchAsPrefix(input, i)!;
      i = again.end;
      continue;
    }
    i += 1;
  }
  return null;
}

String _escapeText(String raw) {
  return raw
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

String _escapeAttr(String raw) {
  return raw
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
