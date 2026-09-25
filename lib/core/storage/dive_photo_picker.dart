import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<List<PickedPhoto>> pickMultiple({int max = 12}) async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      final files = await ImagePicker().pickMultiImage(
        // Keep near-original resolution for OTA gallery sharpness.
        imageQuality: 98,
        maxWidth: 4096,
        limit: max,
      );
      if (files.isEmpty) {
        return const [];
      }
      final out = <PickedPhoto>[];
      for (final file in files.take(max)) {
        final bytes = await file.readAsBytes();
        out.add(
          PickedPhoto(
            bytes: bytes,
            fileName: file.name,
            contentType: _contentType(file.name, file.mimeType),
          ),
        );
      }
      return out;
    }

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
        PickedPhoto(
          bytes: bytes,
          fileName: file.name,
          contentType: _contentType(file.name, file.extension),
        ),
      );
    }
    return out;
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
