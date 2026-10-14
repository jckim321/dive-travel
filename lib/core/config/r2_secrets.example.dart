/// git에 올리는 빈 템플릿입니다. 복사해서 r2_secrets.dart 로 저장한 뒤 값을 넣으세요.
///
/// publicBaseUrl 예: https://pub-xxxx.r2.dev 또는 커스텀 도메인.
/// Cloudflare 대시보드에서 해당 버킷 Settings → Public Development URL 을
/// Allow 로 켜 두세요. CI는 GitHub Secret CLOUDFLARE_API_TOKEN 이 있으면
/// 배포 후 scripts/ensure_r2_public.sh 로 r2.dev 공개를 다시 켭니다.
/// (S3 업로드 키만으로는 버킷 Public Access 를 바꿀 수 없습니다.)
abstract final class R2Secrets {
  static const String accessKeyId = '';
  static const String secretAccessKey = '';
  static const String accountId = '';
  static const String s3ApiUrl = '';
  static const String publicBaseUrl = '';
  static const String bucketName = 'dive-travel-app-storage';
  static const String region = 'auto';
}
