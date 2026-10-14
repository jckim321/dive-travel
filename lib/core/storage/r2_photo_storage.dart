import 'dart:typed_data';

import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';

import 'package:dive_travel_app/core/config/r2_config.dart';

class R2UploadException implements Exception {
  const R2UploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Cloudflare R2에 S3 호환 SigV4로 사진을 올립니다.
class R2PhotoStorage {
  const R2PhotoStorage();

  AWSSigV4Signer get _signer => AWSSigV4Signer(
    credentialsProvider: AWSCredentialsProvider(
      AWSCredentials(R2Config.accessKeyId, R2Config.secretAccessKey),
    ),
  );

  AWSCredentialScope get _scope => AWSCredentialScope(
    region: R2Config.region,
    service: AWSService.s3,
  );

  Future<String> upload({
    required String objectKey,
    required Uint8List bytes,
    required String contentType,
    bool requirePublicUrl = false,
  }) async {
    if (!R2Config.isReady) {
      final missing = <String>[
        if (R2Config.accessKeyId.isEmpty) 'Access Key ID',
        if (R2Config.secretAccessKey.isEmpty) 'Secret Access Key',
        if (R2Config.accountId.isEmpty) 'Account ID',
      ];
      throw R2UploadException(
        'Cloudflare R2 설정이 비어 있습니다 (${missing.join(', ')}). '
        '로컬은 lib/core/config/r2_secrets.dart에, '
        '배포본은 GitHub Secrets(R2_ACCESS_KEY_ID 등)에 넣어 주세요.',
      );
    }
    if (requirePublicUrl && !R2Config.hasPublicBase) {
      throw const R2UploadException(
        'R2_PUBLIC_BASE_URL이 비어 있습니다. '
        '공개 버킷/커스텀 도메인 URL을 넣어야 상품 사진이 새로고침 후에도 유지됩니다. '
        '로컬은 r2_secrets.dart, 배포는 GitHub Secret R2_PUBLIC_BASE_URL을 설정하세요.',
      );
    }

    try {
      final host = R2Config.endpointHost;
      final path = '/${R2Config.bucketName}/$objectKey';
      final request = AWSHttpRequest.put(
        Uri.https(host, path),
        headers: {
          AWSHeaders.host: host,
          AWSHeaders.contentType: contentType,
          AWSHeaders.contentLength: '${bytes.length}',
        },
        body: bytes,
      );
      final signed = await _signer.sign(
        request,
        credentialScope: _scope,
        serviceConfiguration: S3ServiceConfiguration(),
      );
      final response = await signed.send().response;
      if (response.statusCode != 200 && response.statusCode != 204) {
        final decoded = response.decodeBody();
        final body = decoded is String ? decoded : await decoded;
        throw R2UploadException(
          'R2 업로드 실패 (${response.statusCode}): $body. '
          '웹에서는 버킷 CORS에 GitHub Pages 출처(PUT)가 허용돼 있어야 합니다.',
        );
      }
      // Persist the stable public/object path in Firestore. Display may swap
      // to a signed GET when the r2.dev public bucket returns 401.
      if (R2Config.hasPublicBase) {
        return R2Config.publicUrlFor(objectKey);
      }
      // Private fallback for logbook-style assets only.
      return await _presignedGetUrl(host: host, path: path);
    } on R2UploadException {
      rethrow;
    } catch (error) {
      throw R2UploadException(
        'R2 업로드 실패: $error. '
        '웹에서는 버킷 CORS에 현재 사이트 출처가 허용돼 있는지 확인하세요.',
      );
    }
  }

  /// Turns a stored R2 public URL into a short-lived signed GET when the
  /// public r2.dev host is locked down (401). Non-R2 URLs pass through.
  Future<String> readableUrl(String storedUrl) async {
    final trimmed = storedUrl.trim();
    if (trimmed.isEmpty || trimmed.startsWith('memory://')) {
      return trimmed;
    }
    if (!R2Config.isReady) {
      return trimmed;
    }
    final key = objectKeyFromStoredUrl(trimmed);
    if (key == null || key.isEmpty) {
      return trimmed;
    }
    try {
      return await _presignedGetUrl(
        host: R2Config.endpointHost,
        path: '/${R2Config.bucketName}/$key',
      );
    } catch (_) {
      return trimmed;
    }
  }

  /// Extracts the object key from a durable public or S3-style R2 URL.
  static String? objectKeyFromStoredUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || trimmed.startsWith('memory://')) {
      return null;
    }
    final public = R2Config.publicBaseUrl.replaceAll(RegExp(r'/+$'), '');
    if (public.isNotEmpty && trimmed.startsWith('$public/')) {
      return Uri.decodeFull(trimmed.substring(public.length + 1));
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.pathSegments.isEmpty) {
      return null;
    }
    final host = uri.host;
    final segments = [
      for (final part in uri.pathSegments)
        if (part.isNotEmpty) part,
    ];
    if (host == R2Config.endpointHost ||
        host.endsWith('.r2.cloudflarestorage.com')) {
      if (segments.length >= 2 && segments.first == R2Config.bucketName) {
        return segments.skip(1).join('/');
      }
    }
    if (host.endsWith('.r2.dev') && segments.isNotEmpty) {
      return segments.join('/');
    }
    return null;
  }

  Future<String> _presignedGetUrl({
    required String host,
    required String path,
  }) async {
    final urlRequest = AWSHttpRequest.get(
      Uri.https(host, path),
      headers: {AWSHeaders.host: host},
    );
    final signedUrl = await _signer.presign(
      urlRequest,
      credentialScope: _scope,
      serviceConfiguration: S3ServiceConfiguration(),
      expiresIn: const Duration(days: 7),
    );
    return signedUrl.toString();
  }
}
