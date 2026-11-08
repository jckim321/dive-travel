import 'package:flutter/material.dart';

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

/// No-op on non-web. Matches the web controller API.
class TipTapStoryFrameController {
  void setStorageKey(String? key) {}

  void notifySaveSucceeded(String html) {}

  void suspendInput() {}

  void resumeInput() {}
}

/// Non-web placeholder. The trial Tiptap frame only runs in the browser.
class TipTapStoryFrame extends StatelessWidget {
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
  final String? storageKey;
  final String initialHtml;
  final ValueChanged<String>? onHtmlChanged;
  final Future<String?> Function()? onPickPhoto;
  final Future<String?> Function(TipTapPhotoUploadRequest request)? onUploadPhoto;
  final Future<String?> Function()? onPickVideo;
  final Future<TipTapMapPlace?> Function()? onPickMap;
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
