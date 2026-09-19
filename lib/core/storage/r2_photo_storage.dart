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
  }) async {
    if (!R2Config.isReady) {
      throw const R2UploadException(
        'Cloudflare R2 Access Key 또는 Account ID가 비어 있습니다. lib/core/config/r2_secrets.dart를 확인해 주세요.',
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
          'R2 업로드 실패 (${response.statusCode}): $body',
        );
      }
      if (R2Config.publicBaseUrl.trim().isNotEmpty) {
        return R2Config.publicUrlFor(objectKey);
      }
      return await _presignedGetUrl(host: host, path: path);
    } on R2UploadException {
      rethrow;
    } catch (error) {
      throw R2UploadException('R2 업로드 실패: $error');
    }
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
