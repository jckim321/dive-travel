/// Pure rewrite of legacy `*.r2.dev` public URLs onto [publicBaseUrl].
///
/// Path after the host is kept. Non-r2.dev hosts (external CDNs, S3 API) and
/// empty strings are unchanged. When [publicBaseUrl] is empty, no rewrite.
///
/// TODO(launch): Prefer storing object keys only in Firestore and build URLs
/// with [R2Config.publicUrlFor] at display time so host rotates need no migrate.
String normalizeR2PublicUrl(
  String url, {
  required String publicBaseUrl,
}) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  if (trimmed.startsWith('memory://')) {
    return trimmed;
  }
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return trimmed;
  }
  if (!uri.host.endsWith('.r2.dev')) {
    return trimmed;
  }
  final base = publicBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  if (base.isEmpty) {
    return trimmed;
  }
  final key = [
    for (final part in uri.pathSegments)
      if (part.isNotEmpty) part,
  ].join('/');
  if (key.isEmpty) {
    return base;
  }
  return '$base/$key';
}
