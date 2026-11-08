import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_resort_info.dart';
import 'package:dive_travel_app/core/models/story_block.dart';
import 'package:dive_travel_app/core/models/story_html.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/storage/dive_video_picker.dart';
import 'package:dive_travel_app/features/admin/presentation/planner_palette.dart';
import 'package:dive_travel_app/features/admin/presentation/tiptap_story_frame.dart';

/// Pauses the partner story iframe while [action] is open, then restores it.
///
/// Copied from the planner screen's editor pause. A controller with no frame
/// (non-web, or the editor not mounted) is a no-op.
Future<void> pausePartnerStoryInput(
  TipTapStoryFrameController controller,
  Future<void> Function() action,
) async {
  controller.suspendInput();
  try {
    await action();
  } finally {
    controller.resumeInput();
  }
}

/// IndexedDB key for one partner product. Never the planner's shared new-product key.
String partnerStoryStorageKey(String shopId, String productId) {
  return 'dive-travel-story:${shopId.trim()}:${productId.trim()}';
}

/// Empty TipTap document (`<p></p>`) counts as no story body.
bool partnerStoryBodyIsEmpty(String raw) {
  final cleaned = sanitizeStoryHtml(raw);
  if (cleaned.isEmpty) {
    return true;
  }
  if (countStoryHtmlImages(cleaned) > 0 ||
      countStoryHtmlVideos(cleaned) > 0 ||
      countStoryHtmlMaps(cleaned) > 0) {
    return false;
  }
  final text = cleaned
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s+'), '')
      .trim();
  return text.isEmpty;
}

/// Partner copy of the planner TipTap photo, video, and map actions.
///
/// Uploads use [shopId], which the store stores under `shops/{shopId}/story`.
class PartnerStoryEditor extends StatefulWidget {
  const PartnerStoryEditor({
    super.key,
    required this.shopId,
    required this.productId,
    required this.initialHtml,
    required this.controller,
    required this.onHtmlChanged,
  });

  final String shopId;
  final String productId;
  final String initialHtml;
  final TipTapStoryFrameController controller;
  final ValueChanged<String> onHtmlChanged;

  @override
  State<PartnerStoryEditor> createState() => _PartnerStoryEditorState();
}

class _PartnerStoryEditorState extends State<PartnerStoryEditor> {
  final _photoPicker = const DivePhotoPicker();
  final _videoPicker = const DiveVideoPicker();
  late String _html;
  double? _videoProgress;

  @override
  void initState() {
    super.initState();
    _html = widget.initialHtml;
  }

  void _onHtmlChanged(String html) {
    _html = html;
    widget.onHtmlChanged(html);
  }

  Future<String> _uploadStoryPhoto(PickedPhoto photo) {
    final store = DiverStoreScope.of(context);
    return store.uploadStoryPhoto(
      shopId: widget.shopId,
      bytes: photo.bytes,
      fileName: photo.fileName,
      contentType: photo.contentType,
    );
  }

  Future<String?> _pickPhoto() async {
    if (countStoryHtmlImages(_html) >= storyHtmlMaxPhotos) {
      if (!mounted) {
        return null;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진은 30장까지 올릴 수 있습니다.')),
      );
      return null;
    }
    final picked = await _photoPicker.pick();
    if (!mounted || picked == null) {
      return null;
    }
    if (picked.bytes.lengthInBytes > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진은 10MB 이하만 올릴 수 있어요')),
      );
      return null;
    }
    if (countStoryHtmlImages(_html) >= storyHtmlMaxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진은 30장까지 올릴 수 있습니다.')),
      );
      return null;
    }
    try {
      final url = (await _uploadStoryPhoto(picked)).trim();
      if (url.isEmpty || !isAllowedStoryImageUrl(url)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사진을 올리지 못했습니다.')),
          );
        }
        return null;
      }
      return url;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
      return null;
    }
  }

  Future<String?> _uploadPhotoBytes(TipTapPhotoUploadRequest request) async {
    if (countStoryHtmlImages(_html) >= storyHtmlMaxPhotos) {
      return null;
    }
    final dataUrl = request.dataUrl.trim();
    if (!dataUrl.startsWith('data:image/')) {
      return null;
    }
    try {
      final data = Uri.parse(dataUrl).data;
      if (data == null) {
        return null;
      }
      final bytes = data.contentAsBytes();
      if (bytes.isEmpty) {
        return null;
      }
      final mime = request.contentType.trim().isNotEmpty
          ? request.contentType.trim()
          : (data.mimeType.isNotEmpty ? data.mimeType : 'image/jpeg');
      final name = request.fileName.trim().isNotEmpty
          ? request.fileName.trim()
          : 'paste.jpg';
      final url = (await _uploadStoryPhoto(
        PickedPhoto(
          bytes: Uint8List.fromList(bytes),
          fileName: name,
          contentType: mime,
        ),
      ))
          .trim();
      if (url.isEmpty || !isAllowedStoryImageUrl(url)) {
        return null;
      }
      return url;
    } catch (_) {
      return null;
    }
  }

  Future<String> _uploadStoryVideo(
    PickedVideo video,
    void Function(double progress) onProgress,
  ) {
    final store = DiverStoreScope.of(context);
    return store.uploadStoryVideo(
      shopId: widget.shopId,
      bytes: video.bytes,
      fileName: video.fileName,
      onProgress: (sent, total) {
        if (total <= 0) {
          return;
        }
        onProgress(sent / total);
      },
    );
  }

  Future<String?> _pickVideo() async {
    if (countStoryHtmlVideos(_html) >= storyHtmlMaxVideos) {
      if (!mounted) {
        return null;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('동영상은 3개까지 올릴 수 있습니다.')),
      );
      return null;
    }
    final picked = await _videoPicker.pick();
    if (!mounted || picked == null) {
      return null;
    }
    if (countStoryHtmlVideos(_html) >= storyHtmlMaxVideos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('동영상은 3개까지 올릴 수 있습니다.')),
      );
      return null;
    }
    final reason = StoryBlock.videoRejectReason(
      name: picked.fileName,
      size: picked.size,
    );
    if (reason != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reason)),
      );
      return null;
    }
    setState(() => _videoProgress = 0);
    try {
      final url = (await _uploadStoryVideo(picked, (progress) {
        if (!mounted) {
          return;
        }
        setState(() => _videoProgress = progress.clamp(0, 1).toDouble());
      }))
          .trim();
      if (!mounted) {
        return null;
      }
      if (url.isEmpty || !isAllowedStoryVideoUrl(url)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('동영상을 올리지 못했습니다.')),
        );
        return null;
      }
      return url;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _videoProgress = null);
      }
    }
  }

  Future<TipTapMapPlace?> _pickMap() async {
    if (countStoryHtmlMaps(_html) >= storyHtmlMaxMaps) {
      if (!mounted) {
        return null;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지도는 5개까지 넣을 수 있습니다.')),
      );
      return null;
    }
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    var confirmed = false;
    await pausePartnerStoryInput(widget.controller, () async {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            key: const Key('partner-story-map-dialog'),
            title: const Text('지도 장소'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  key: Key('partner-story-map-hint'),
                  '본문에 저장되어, 손님이 누르면 구글 지도가 열립니다',
                  style: TextStyle(
                    color: PlannerPalette.textDim,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const Key('partner-story-map-name'),
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: '장소 이름'),
                ),
                TextField(
                  key: const Key('partner-story-map-address'),
                  controller: addressController,
                  decoration: const InputDecoration(labelText: '주소'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('넣기'),
              ),
            ],
          );
        },
      );
      confirmed = result == true;
    });
    final name = nameController.text.trim();
    final address = addressController.text.trim();
    nameController.dispose();
    addressController.dispose();
    if (!mounted || !confirmed) {
      return null;
    }
    if (name.isEmpty && address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장소 이름 또는 주소를 입력하세요.')),
      );
      return null;
    }
    if (countStoryHtmlMaps(_html) >= storyHtmlMaxMaps) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지도는 5개까지 넣을 수 있습니다.')),
      );
      return null;
    }
    final query = [name, address].where((part) => part.isNotEmpty).join(' ');
    final href = googleMapsSearchUri(query).toString();
    return TipTapMapPlace(name: name, address: address, href: href);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _videoProgress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (progress != null) ...[
          LinearProgressIndicator(
            key: const Key('partner-story-video-progress'),
            value: progress,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '올리는 중 ${(progress * 100).round()}%',
              key: const Key('partner-story-video-progress-label'),
              style: const TextStyle(color: PlannerPalette.textDim),
            ),
          ),
          const SizedBox(height: 8),
        ],
        TipTapStoryFrame(
          controller: widget.controller,
          storageKey: partnerStoryStorageKey(widget.shopId, widget.productId),
          initialHtml: widget.initialHtml,
          onHtmlChanged: _onHtmlChanged,
          onPickPhoto: _pickPhoto,
          onUploadPhoto: _uploadPhotoBytes,
          onPickVideo: _pickVideo,
          onPickMap: _pickMap,
        ),
      ],
    );
  }
}
