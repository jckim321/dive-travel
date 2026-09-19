import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';

void main() {
  test('소유자 이메일이면 표시 이름을 Jongcheol Kim으로 채운다', () {
    expect(
      AppOwner.resolveDisplayName(
        email: 'jckim321@gmail.com',
        displayName: '',
      ),
      'Jongcheol Kim',
    );
    expect(AppOwner.isOwnerEmail('JCKIM321@gmail.com'), isTrue);
  });
}
