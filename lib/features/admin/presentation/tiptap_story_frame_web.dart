// IFrame host for Flutter web. Conditional export keeps this off other platforms.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

const _appSource = 'dive-travel-app';
const _editorSource = 'dive-travel-editor';

/// Result of the TipTap map place dialog.
class TipTapMapPlace {
  const TipTapMapPlace({
    required this.name,
    required this.address,
    required this.href,
  });

  final String name;
  final String address;
  final String href;
}

/// One pasted or dropped image the editor asks the app to upload.
class TipTapPhotoUploadRequest {
  const TipTapPhotoUploadRequest({
    required this.id,
    required this.dataUrl,
    required this.fileName,
    required this.contentType,
  });

  final String id;
  final String dataUrl;
  final String fileName;
  final String contentType;
}

/// Lets the planner tell the iframe about a successful body save.
class TipTapStoryFrameController {
  _TipTapStoryFrameState? _state;

  void setStorageKey(String? key) {
    _state?._postStorageKey(key);
  }

  void notifySaveSucceeded(String html) {
    _state?._postSaveSucceeded(html);
  }
}

/// IFrame host for [web/editor/index.html]. Read/write HTML via postMessage.
class TipTapStoryFrame extends StatefulWidget {
  const TipTapStoryFrame({
    super.key,
    this.controller,
    this.storageKey,
    this.initialHtml = '',
    this.onHtmlChanged,
    this.onPickPhoto,
    this.onUploadPhoto,
    this.onPickVideo,
    this.onPickMap,
    this.height = 420,
  });

  final TipTapStoryFrameController? controller;

  /// Product-scoped browser storage key. Empty/null skips IndexedDB.
  final String? storageKey;
  final String initialHtml;
  final ValueChanged<String>? onHtmlChanged;

  /// App picks a photo, uploads with [uploadStoryPhoto], returns the https URL.
  final Future<String?> Function()? onPickPhoto;

  /// App uploads pasted/dropped image bytes via [uploadStoryPhoto].
  final Future<String?> Function(TipTapPhotoUploadRequest request)? onUploadPhoto;

  /// App picks an mp4, uploads with [uploadStoryVideo], returns the https URL.
  final Future<String?> Function()? onPickVideo;

  /// App collects place name/address and returns a Google Maps search card.
  final Future<TipTapMapPlace?> Function()? onPickMap;
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
  var _pickingPhoto = false;
  var _pickingVideo = false;
  var _pickingMap = false;
  final _uploadingIds = <String>{};

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
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
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }
    if (oldWidget.storageKey != widget.storageKey && _ready) {
      _postStorageKey(widget.storageKey);
    }
    if (oldWidget.initialHtml != widget.initialHtml && _ready) {
      _postSetContent(widget.initialHtml);
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) {
      widget.controller?._state = null;
    }
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
      _postStorageKey(widget.storageKey);
      _postSetContent(widget.initialHtml);
      return;
    }
    if (type == 'content' || type == 'contentChanged') {
      widget.onHtmlChanged?.call(htmlText);
      return;
    }
    if (type == 'pickPhoto') {
      unawaited(_handlePickPhoto());
      return;
    }
    if (type == 'uploadPhoto') {
      unawaited(_handleUploadPhoto(data));
      return;
    }
    if (type == 'pickVideo') {
      unawaited(_handlePickVideo());
      return;
    }
    if (type == 'pickMap') {
      unawaited(_handlePickMap());
    }
  }

  Future<void> _handlePickPhoto() async {
    if (_pickingPhoto) {
      return;
    }
    final pick = widget.onPickPhoto;
    if (pick == null) {
      return;
    }
    _pickingPhoto = true;
    try {
      final url = (await pick())?.trim() ?? '';
      if (!mounted || url.isEmpty) {
        return;
      }
      _postInsertPhoto(url);
    } finally {
      _pickingPhoto = false;
    }
  }

  Future<void> _handleUploadPhoto(dynamic data) async {
    final upload = widget.onUploadPhoto;
    String id = '';
    try {
      id = (data['id'] as String?)?.trim() ?? '';
      if (upload == null || id.isEmpty || _uploadingIds.contains(id)) {
        if (id.isNotEmpty) {
          _postUploadPhotoResult(id: id, url: null);
        }
        return;
      }
      final dataUrl = (data['dataUrl'] as String?)?.trim() ?? '';
      final fileName = (data['fileName'] as String?)?.trim() ?? 'paste.jpg';
      final contentType =
          (data['contentType'] as String?)?.trim() ?? 'image/jpeg';
      if (dataUrl.isEmpty) {
        _postUploadPhotoResult(id: id, url: null);
        return;
      }
      _uploadingIds.add(id);
      final url = (await upload(
        TipTapPhotoUploadRequest(
          id: id,
          dataUrl: dataUrl,
          fileName: fileName,
          contentType: contentType,
        ),
      ))
          ?.trim();
      if (!mounted) {
        return;
      }
      _postUploadPhotoResult(
        id: id,
        url: (url != null && url.isNotEmpty) ? url : null,
      );
    } catch (_) {
      if (id.isNotEmpty && mounted) {
        _postUploadPhotoResult(id: id, url: null);
      }
    } finally {
      if (id.isNotEmpty) {
        _uploadingIds.remove(id);
      }
    }
  }

  Future<void> _handlePickVideo() async {
    if (_pickingVideo) {
      return;
    }
    final pick = widget.onPickVideo;
    if (pick == null) {
      return;
    }
    _pickingVideo = true;
    try {
      final url = (await pick())?.trim() ?? '';
      if (!mounted || url.isEmpty) {
        return;
      }
      _postInsertVideo(url);
    } finally {
      _pickingVideo = false;
    }
  }

  Future<void> _handlePickMap() async {
    if (_pickingMap) {
      return;
    }
    final pick = widget.onPickMap;
    if (pick == null) {
      return;
    }
    _pickingMap = true;
    try {
      final place = await pick();
      if (!mounted || place == null) {
        return;
      }
      final href = place.href.trim();
      if (href.isEmpty) {
        return;
      }
      _postInsertMap(place);
    } finally {
      _pickingMap = false;
    }
  }

  void _postStorageKey(String? key) {
    final win = _iframe?.contentWindow;
    if (win == null) {
      return;
    }
    win.postMessage(
      {
        'source': _appSource,
        'type': 'setStorageKey',
        'key': (key ?? '').trim(),
      },
      '*',
    );
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

  void _postSaveSucceeded(String htmlText) {
    final win = _iframe?.contentWindow;
    if (win == null) {
      return;
    }
    win.postMessage(
      {
        'source': _appSource,
        'type': 'saveSucceeded',
        'html': htmlText,
      },
      '*',
    );
  }

  void _postInsertPhoto(String url) {
    final win = _iframe?.contentWindow;
    if (win == null) {
      return;
    }
    win.postMessage(
      {
        'source': _appSource,
        'type': 'insertPhoto',
        'url': url,
      },
      '*',
    );
  }

  void _postUploadPhotoResult({required String id, required String? url}) {
    final win = _iframe?.contentWindow;
    if (win == null) {
      return;
    }
    win.postMessage(
      {
        'source': _appSource,
        'type': 'uploadPhotoResult',
        'id': id,
        'url': ?url,
      },
      '*',
    );
  }

  void _postInsertVideo(String url) {
    final win = _iframe?.contentWindow;
    if (win == null) {
      return;
    }
    win.postMessage(
      {
        'source': _appSource,
        'type': 'insertVideo',
        'url': url,
      },
      '*',
    );
  }

  void _postInsertMap(TipTapMapPlace place) {
    final win = _iframe?.contentWindow;
    if (win == null) {
      return;
    }
    win.postMessage(
      {
        'source': _appSource,
        'type': 'insertMap',
        'name': place.name,
        'address': place.address,
        'href': place.href,
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
