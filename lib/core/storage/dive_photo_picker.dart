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
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2400,
      );
      if (file == null) {
        return null;
      }
      final bytes = await file.readAsBytes();
      return PickedPhoto(
        bytes: bytes,
        fileName: file.name,
        contentType: _contentType(file.name, file.mimeType),
      );
    }

    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) {
      return null;
    }
    final bytes = await file.readAsBytes();
    return PickedPhoto(
      bytes: bytes,
      fileName: file.name,
      contentType: _contentType(file.name, file.extension),
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
