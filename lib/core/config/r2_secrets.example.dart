/// git에 올리는 빈 템플릿입니다. 복사해서 r2_secrets.dart 로 저장한 뒤 값을 넣으세요.
///
/// publicBaseUrl 예: https://pub-xxxx.r2.dev 또는 커스텀 도메인.
/// 비어 있으면 상품/리조트 사진은 저장되지 않습니다(새로고침 후 사라짐).
abstract final class R2Secrets {
  static const String accessKeyId = '';
  static const String secretAccessKey = '';
  static const String accountId = '';
  static const String s3ApiUrl = '';
  static const String publicBaseUrl = '';
  static const String bucketName = 'dive-travel-app-storage';
  static const String region = 'auto';
}
