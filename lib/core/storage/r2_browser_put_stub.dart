import 'dart:typed_data';

/// VM and tests keep the signed AWS client. Web replaces this file.
Future<int?> putSignedBytes({
  required Uri uri,
  required Map<String, String> headers,
  required Uint8List bytes,
  void Function(int sent, int total)? onProgress,
}) async {
  return null;
}
