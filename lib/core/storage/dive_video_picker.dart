import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// One mp4 chosen for a story video block.
class PickedVideo {
  const PickedVideo({
    required this.bytes,
    required this.fileName,
    this.declaredSize,
  });

  final Uint8List bytes;
  final String fileName;

  /// Test hook for a file larger than the bytes kept in memory.
  final int? declaredSize;

  int get size {
    final fromBytes = bytes.length;
    final declared = declaredSize;
    if (declared == null || declared < fromBytes) {
      return fromBytes;
    }
    return declared;
  }
}

class DiveVideoPicker {
  const DiveVideoPicker();

  Future<PickedVideo?> pick() async {
    final useImagePicker = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (useImagePicker) {
      final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (file == null) {
        return null;
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return null;
      }
      return PickedVideo(bytes: bytes, fileName: file.name);
    }
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp4'],
    );
    if (files.isEmpty) {
      return null;
    }
    final file = files.first;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      return null;
    }
    return PickedVideo(bytes: bytes, fileName: file.name);
  }
}
