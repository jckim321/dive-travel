import 'package:dive_travel_app/core/config/r2_secrets.dart';

/// Cloudflare R2 설정.
/// 우선순위: `--dart-define` (CI/배포) → gitignore된 `r2_secrets.dart` (로컬).
abstract final class R2Config {
  static String get accessKeyId {
    const fromEnv = String.fromEnvironment('R2_ACCESS_KEY_ID');
    if (fromEnv.trim().isNotEmpty) {
      return fromEnv.trim();
    }
    return R2Secrets.accessKeyId.trim();
  }

  static String get secretAccessKey {
    const fromEnv = String.fromEnvironment('R2_SECRET_ACCESS_KEY');
    if (fromEnv.trim().isNotEmpty) {
      return fromEnv.trim();
    }
    // Never lower-case: SigV4 secrets are case-sensitive.
    return R2Secrets.secretAccessKey.trim();
  }

  static String get accountId {
    const fromEnv = String.fromEnvironment('R2_ACCOUNT_ID');
    if (fromEnv.trim().isNotEmpty) {
      return fromEnv.trim();
    }
    return R2Secrets.accountId.trim();
  }

  static String get s3ApiUrl {
    const fromEnv = String.fromEnvironment('R2_S3_API_URL');
    if (fromEnv.trim().isNotEmpty) {
      return fromEnv.trim();
    }
    return R2Secrets.s3ApiUrl.trim();
  }

  static String get publicBaseUrl {
    const fromEnv = String.fromEnvironment('R2_PUBLIC_BASE_URL');
    if (fromEnv.trim().isNotEmpty) {
      return fromEnv.trim();
    }
    return R2Secrets.publicBaseUrl.trim();
  }

  static String get bucketName {
    const fromEnv = String.fromEnvironment('R2_BUCKET_NAME');
    if (fromEnv.trim().isNotEmpty) {
      return fromEnv.trim();
    }
    final local = R2Secrets.bucketName.trim();
    return local.isEmpty ? 'dive-travel-app-storage' : local;
  }

  static String get region {
    const fromEnv = String.fromEnvironment('R2_REGION');
    if (fromEnv.trim().isNotEmpty) {
      return fromEnv.trim();
    }
    final local = R2Secrets.region.trim();
    return local.isEmpty ? 'auto' : local;
  }

  static bool get hasCredentials =>
      accessKeyId.isNotEmpty && secretAccessKey.isNotEmpty;

  static bool get isReady => hasCredentials && accountId.isNotEmpty;

  static String get endpointHost {
    final api = s3ApiUrl;
    if (api.isNotEmpty) {
      return Uri.parse(api).host;
    }
    return '$accountId.r2.cloudflarestorage.com';
  }

  static String publicUrlFor(String objectKey) {
    final key = objectKey.replaceFirst(RegExp(r'^/+'), '');
    final base = publicBaseUrl.replaceAll(RegExp(r'/+$'), '');
    if (base.isNotEmpty) {
      return '$base/$key';
    }
    return 'https://$endpointHost/$bucketName/$key';
  }
}
