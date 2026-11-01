import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// Browser PUT so a large video can report real upload progress.
Future<int?> putSignedBytes({
  required Uri uri,
  required Map<String, String> headers,
  required Uint8List bytes,
  void Function(int sent, int total)? onProgress,
}) {
  final completer = Completer<int?>();
  final request = html.HttpRequest();
  request.open('PUT', uri.toString());
  headers.forEach((name, value) {
    final lower = name.toLowerCase();
    if (lower == 'host' || lower == 'content-length') {
      return;
    }
    request.setRequestHeader(name, value);
  });
  request.upload.onProgress.listen((html.ProgressEvent event) {
    final total = event.lengthComputable ? (event.total ?? bytes.length) : bytes.length;
    final sent = event.loaded ?? 0;
    onProgress?.call(sent, total <= 0 ? bytes.length : total);
  });
  request.onLoad.listen((_) {
    if (!completer.isCompleted) {
      completer.complete(request.status);
    }
  });
  request.onError.listen((_) {
    if (!completer.isCompleted) {
      completer.complete(request.status ?? 0);
    }
  });
  request.send(bytes);
  return completer.future;
}
