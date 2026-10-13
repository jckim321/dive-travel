import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/config/r2_config.dart';

void main() {
  test('R2 버킷과 리전이 프로젝트 설정과 같다', () {
    expect(R2Config.bucketName, 'dive-travel-app-storage');
    expect(R2Config.region, 'auto');
  });

  test('S3 API 호스트와 객체 경로를 만든다', () {
    expect(R2Config.endpointHost, contains('r2.cloudflarestorage.com'));
    expect(
      R2Config.publicUrlFor('logs/uid/log1.jpg'),
      endsWith('logs/uid/log1.jpg'),
    );
  });

  test('공개 base URL 플래그는 자격증명과 함께 영속 저장 가능 여부를 결정한다', () {
    expect(
      R2Config.canPersistListingPhotos,
      R2Config.isReady && R2Config.hasPublicBase,
    );
  });
}
