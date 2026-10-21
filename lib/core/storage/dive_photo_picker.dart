import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import 'package:dive_travel_app/core/constants/gallery_limits.dart';

class PickedPhoto {
  const PickedPhoto({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;

  String get extension {
    final name = fileName.toLowerCase();
    if (name.endsWith('.png')) {
      return '.png';
    }
    if (name.endsWith('.webp')) {
      return '.webp';
    }
    if (name.endsWith('.gif')) {
      return '.gif';
    }
    if (name.endsWith('.heic') || name.endsWith('.heif')) {
      return '.heic';
    }
    return '.jpg';
  }
}

class DivePhotoPicker {
  const DivePhotoPicker();

  Future<PickedPhoto?> pick() async {
    final many = await pickMultiple(max: 1);
    return many.isEmpty ? null : many.first;
  }

  Future<List<PickedPhoto>> pickMultiple({
    int max = GalleryLimits.maxProductPhotos,
  }) async {
    // Web + mobile: ImagePicker. FilePicker on web often returns empty
    // because cancelUploadOnWindowBlur races the file-dialog focus cycle.
    final useImagePicker = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (useImagePicker) {
      try {
        final edge = GalleryLimits.maxEdgePx.toDouble();
        final files = await ImagePicker().pickMultiImage(
          imageQuality: GalleryLimits.jpegQuality,
          maxWidth: edge,
          maxHeight: edge,
          limit: max,
        );
        if (files.isEmpty) {
          return const [];
        }
        final out = <PickedPhoto>[];
        for (final file in files.take(max)) {
          final bytes = await file.readAsBytes();
          if (bytes.isEmpty) {
            continue;
          }
          out.add(
            await _compressIfNeeded(
              PickedPhoto(
                bytes: bytes,
                fileName: file.name,
                contentType: _contentType(file.name, file.mimeType),
              ),
            ),
          );
        }
        return out;
      } catch (error, stack) {
        debugPrint('DivePhotoPicker ImagePicker failed: $error\n$stack');
        rethrow;
      }
    }

    try {
      final files = await FilePicker.pickFiles(type: FileType.image);
      if (files.isEmpty) {
        return const [];
      }
      final out = <PickedPhoto>[];
      for (final file in files.take(max)) {
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) {
          continue;
        }
        out.add(
          await _compressIfNeeded(
            PickedPhoto(
              bytes: bytes,
              fileName: file.name,
              contentType: _contentType(file.name, file.extension),
            ),
          ),
        );
      }
      return out;
    } catch (error, stack) {
      debugPrint('DivePhotoPicker FilePicker failed: $error\n$stack');
      rethrow;
    }
  }

  /// Downscale long edge and re-encode as JPEG so large galleries fit in memory.
  ///
  /// Skips only when the decoded long edge is already within [GalleryLimits.maxEdgePx]
  /// and the payload is a small JPEG. Oversized images always get resized.
  static Future<PickedPhoto> _compressIfNeeded(PickedPhoto photo) async {
    try {
      final compressed = await compute(_compressIsolate, photo.bytes);
      if (compressed == null || compressed.isEmpty) {
        return photo;
      }
      final base = photo.fileName.contains('.')
          ? photo.fileName.substring(0, photo.fileName.lastIndexOf('.'))
          : photo.fileName;
      return PickedPhoto(
        bytes: compressed,
        fileName: '$base.jpg',
        contentType: 'image/jpeg',
      );
    } catch (_) {
      return photo;
    }
  }

  /// Returns null when the original bytes should be kept (small + within edge).
  static Uint8List? _compressIsolate(Uint8List raw) {
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      return null;
    }
    final longest =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    final withinEdge = longest <= GalleryLimits.maxEdgePx;
    final isJpeg = raw.length >= 2 && raw[0] == 0xFF && raw[1] == 0xD8;
    // Keep already-sharp JPEGs that fit the edge so we don't re-encode twice.
    if (withinEdge && isJpeg && raw.lengthInBytes <= 1.5 * 1024 * 1024) {
      return null;
    }
    final sized = withinEdge
        ? decoded
        : img.copyResize(
            decoded,
            width: decoded.width >= decoded.height
                ? GalleryLimits.maxEdgePx
                : null,
            height: decoded.height > decoded.width
                ? GalleryLimits.maxEdgePx
                : null,
            interpolation: img.Interpolation.cubic,
          );
    return Uint8List.fromList(
      img.encodeJpg(sized, quality: GalleryLimits.jpegQuality),
    );
  }

  static String _contentType(String fileName, String? hint) {
    final lower = '${fileName.toLowerCase()} ${hint ?? ''}';
    if (lower.contains('png')) {
      return 'image/png';
    }
    if (lower.contains('webp')) {
      return 'image/webp';
    }
    if (lower.contains('gif')) {
      return 'image/gif';
    }
    if (lower.contains('heic') || lower.contains('heif')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }
}
