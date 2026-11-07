// IFrame host for Flutter web. Conditional export keeps this off other platforms.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

const _appSource = 'dive-travel-app';
const _editorSource = 'dive-travel-editor';

/// IFrame host for [web/editor/index.html]. Read/write HTML via postMessage.
class TipTapStoryFrame extends StatefulWidget {
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
  State<TipTapStoryFrame> createState() => _TipTapStoryFrameState();
}

class _TipTapStoryFrameState extends State<TipTapStoryFrame> {
  static var _seq = 0;

  late final String _viewType;
  html.IFrameElement? _iframe;
  StreamSubscription<html.MessageEvent>? _messages;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _seq += 1;
    _viewType = 'dive-travel-tiptap-$_seq';
    final src = Uri.base.resolve('editor/index.html').toString();
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = src
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'clipboard-read; clipboard-write';
      _iframe = iframe;
      return iframe;
    });
    _messages = html.window.onMessage.listen(_onMessage);
  }

  @override
  void didUpdateWidget(TipTapStoryFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialHtml != widget.initialHtml && _ready) {
      _postSetContent(widget.initialHtml);
    }
  }

  @override
  void dispose() {
    _messages?.cancel();
    super.dispose();
  }

  void _onMessage(html.MessageEvent event) {
    final data = event.data;
    if (data == null) {
      return;
    }
    String? source;
    String? type;
    var htmlText = '';
    try {
      source = data['source'] as String?;
      type = data['type'] as String?;
      htmlText = (data['html'] as String?) ?? '';
    } catch (_) {
      return;
    }
    if (source != _editorSource) {
      return;
    }
    if (type == 'ready') {
      _ready = true;
      if (widget.initialHtml.trim().isNotEmpty) {
        _postSetContent(widget.initialHtml);
      }
      return;
    }
    if (type == 'content' || type == 'contentChanged') {
      widget.onHtmlChanged?.call(htmlText);
    }
  }

  void _postSetContent(String htmlText) {
    final win = _iframe?.contentWindow;
    if (win == null) {
      return;
    }
    win.postMessage(
      {
        'source': _appSource,
        'type': 'setContent',
        'html': htmlText,
      },
      '*',
    );
  }

  /// Ask the iframe for the current HTML (reply arrives as `content`).
  void requestContent() {
    final win = _iframe?.contentWindow;
    if (win == null) {
      return;
    }
    win.postMessage(
      {
        'source': _appSource,
        'type': 'getContent',
      },
      '*',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('planner-tiptap-frame'),
      height: widget.height,
      width: double.infinity,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
