import 'package:dive_travel_app/core/config/r2_secrets.dart';

/// Cloudflare R2 설정. 실제 Access Key는 gitignore된 `r2_secrets.dart`에 둡니다.
abstract final class R2Config {
  static String get accessKeyId => R2Secrets.accessKeyId.trim();
  static String get secretAccessKey =>
      R2Secrets.secretAccessKey.trim().toLowerCase();
  static const String accountId = R2Secrets.accountId;
  static const String s3ApiUrl = R2Secrets.s3ApiUrl;
  static const String publicBaseUrl = R2Secrets.publicBaseUrl;
  static const String bucketName = R2Secrets.bucketName;
  static const String region = R2Secrets.region;

  static bool get hasCredentials =>
      accessKeyId.trim().isNotEmpty && secretAccessKey.trim().isNotEmpty;

  static bool get isReady =>
      hasCredentials && accountId.trim().isNotEmpty;

  static String get endpointHost {
    final api = s3ApiUrl.trim();
    if (api.isNotEmpty) {
      return Uri.parse(api).host;
    }
    return '${accountId.trim()}.r2.cloudflarestorage.com';
  }

  static String publicUrlFor(String objectKey) {
    final key = objectKey.replaceFirst(RegExp(r'^/+'), '');
    final base = publicBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.isNotEmpty) {
      return '$base/$key';
    }
    return 'https://$endpointHost/$bucketName/$key';
  }
}
