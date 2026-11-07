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
    this.height = 360,
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

  /// Minimum / initial iframe height. Grows with editor content via postMessage.
  final double height;

  @override
  State<TipTapStoryFrame> createState() => _TipTapStoryFrameState();
}

class _TipTapStoryFrameState extends State<TipTapStoryFrame> {
  static var _seq = 0;
  static const _minHeight = 360.0;

  late final String _viewType;
  html.IFrameElement? _iframe;
  StreamSubscription<html.MessageEvent>? _messages;
  var _ready = false;
  var _pickingPhoto = false;
  var _pickingVideo = false;
  var _pickingMap = false;
  late double _frameHeight;
  final _uploadingIds = <String>{};
  /// Editor selection saved with pick*; echoed on insert* after the picker/dialog.
  int? _pendingPhotoFrom;
  int? _pendingPhotoTo;
  int? _pendingVideoFrom;
  int? _pendingVideoTo;
  String? _pendingVideoId;
  int? _pendingMapFrom;
  int? _pendingMapTo;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _frameHeight =
        widget.height < _minHeight ? _minHeight : widget.height;
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
    if (type == 'editorHeight') {
      final height = _readMessageDouble(data, 'height');
      if (height == null || !mounted) {
        return;
      }
      final next = height < _minHeight ? _minHeight : height;
      if ((next - _frameHeight).abs() < 1) {
        return;
      }
      setState(() => _frameHeight = next);
      return;
    }
    if (type == 'editorWheel') {
      final deltaY = _readMessageDouble(data, 'deltaY');
      if (deltaY == null || !mounted) {
        return;
      }
      final scrollable = Scrollable.maybeOf(context);
      if (scrollable == null) {
        return;
      }
      final position = scrollable.position;
      final next = (position.pixels + deltaY).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (next != position.pixels) {
        position.jumpTo(next);
      }
      return;
    }
    if (type == 'pickPhoto') {
      _pendingPhotoFrom = _readMessageInt(data, 'from');
      _pendingPhotoTo = _readMessageInt(data, 'to');
      unawaited(_handlePickPhoto());
      return;
    }
    if (type == 'uploadPhoto') {
      unawaited(_handleUploadPhoto(data));
      return;
    }
    if (type == 'pickVideo') {
      _pendingVideoFrom = _readMessageInt(data, 'from');
      _pendingVideoTo = _readMessageInt(data, 'to');
      try {
        _pendingVideoId = (data['id'] as String?)?.trim();
        if (_pendingVideoId != null && _pendingVideoId!.isEmpty) {
          _pendingVideoId = null;
        }
      } catch (_) {
        _pendingVideoId = null;
      }
      unawaited(_handlePickVideo());
      return;
    }
    if (type == 'pickMap') {
      _pendingMapFrom = _readMessageInt(data, 'from');
      _pendingMapTo = _readMessageInt(data, 'to');
      unawaited(_handlePickMap());
    }
  }

  int? _readMessageInt(dynamic data, String key) {
    try {
      final value = data[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
    } catch (_) {}
    return null;
  }

  double? _readMessageDouble(dynamic data, String key) {
    try {
      final value = data[key];
      if (value is double) {
        return value;
      }
      if (value is num) {
        return value.toDouble();
      }
    } catch (_) {}
    return null;
  }

  /// Blur iframe focus and block pointer/keyboard capture while app pickers run.
  void _lockIframeInput() {
    final iframe = _iframe;
    if (iframe == null) {
      return;
    }
    iframe.tabIndex = -1;
    iframe.style.pointerEvents = 'none';
    iframe.blur();
    final win = iframe.contentWindow;
    if (win != null) {
      win.postMessage(
        {
          'source': _appSource,
          'type': 'blurEditor',
        },
        '*',
      );
    }
  }

  void _unlockIframeInput() {
    final iframe = _iframe;
    if (iframe == null) {
      return;
    }
    iframe.style.pointerEvents = '';
    iframe.tabIndex = 0;
  }

  Future<void> _handlePickPhoto() async {
    if (_pickingPhoto) {
      return;
    }
    final pick = widget.onPickPhoto;
    if (pick == null) {
      _pendingPhotoFrom = null;
      _pendingPhotoTo = null;
      return;
    }
    _pickingPhoto = true;
    _lockIframeInput();
    try {
      final url = (await pick())?.trim() ?? '';
      if (!mounted || url.isEmpty) {
        _pendingPhotoFrom = null;
        _pendingPhotoTo = null;
        return;
      }
      _postInsertPhoto(url);
    } finally {
      _unlockIframeInput();
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
      _postInsertVideo('');
      return;
    }
    _pickingVideo = true;
    _lockIframeInput();
    try {
      final url = (await pick())?.trim() ?? '';
      // Empty url still posts so the editor can remove the 「올리는 중」 placeholder.
      _postInsertVideo(url);
    } finally {
      _unlockIframeInput();
      _pickingVideo = false;
    }
  }

  Future<void> _handlePickMap() async {
    if (_pickingMap) {
      return;
    }
    final pick = widget.onPickMap;
    if (pick == null) {
      _clearPendingMap();
      return;
    }
    _pickingMap = true;
    _lockIframeInput();
    try {
      final place = await pick();
      if (!mounted || place == null) {
        _clearPendingMap();
        return;
      }
      final href = place.href.trim();
      if (href.isEmpty) {
        _clearPendingMap();
        return;
      }
      _postInsertMap(place);
    } finally {
      _unlockIframeInput();
      _pickingMap = false;
    }
  }

  void _clearPendingVideo() {
    _pendingVideoFrom = null;
    _pendingVideoTo = null;
    _pendingVideoId = null;
  }

  void _clearPendingMap() {
    _pendingMapFrom = null;
    _pendingMapTo = null;
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
      _pendingPhotoFrom = null;
      _pendingPhotoTo = null;
      return;
    }
    final from = _pendingPhotoFrom;
    final to = _pendingPhotoTo;
    _pendingPhotoFrom = null;
    _pendingPhotoTo = null;
    win.postMessage(
      {
        'source': _appSource,
        'type': 'insertPhoto',
        'url': url,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
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
      _clearPendingVideo();
      return;
    }
    final from = _pendingVideoFrom;
    final to = _pendingVideoTo;
    final id = _pendingVideoId;
    _clearPendingVideo();
    win.postMessage(
      {
        'source': _appSource,
        'type': 'insertVideo',
        'url': url,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (id != null) 'id': id,
      },
      '*',
    );
  }

  void _postInsertMap(TipTapMapPlace place) {
    final win = _iframe?.contentWindow;
    if (win == null) {
      _clearPendingMap();
      return;
    }
    final from = _pendingMapFrom;
    final to = _pendingMapTo;
    _clearPendingMap();
    win.postMessage(
      {
        'source': _appSource,
        'type': 'insertMap',
        'name': place.name,
        'address': place.address,
        'href': place.href,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
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
      height: _frameHeight,
      width: double.infinity,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
