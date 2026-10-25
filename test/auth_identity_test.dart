import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/auth/auth_identity.dart';

void main() {
  test('login id pattern and reserved words', () {
    expect(AuthIdentity.isValidLoginId('jong_01'), isTrue);
    expect(AuthIdentity.isValidLoginId('ab'), isFalse);
    expect(AuthIdentity.isValidLoginId('Admin'), isFalse);
    expect(AuthIdentity.isReservedLoginId('admin'), isTrue);
    expect(AuthIdentity.isReservedLoginId('divetravel'), isTrue);
    expect(AuthIdentity.isReservedLoginId('apdi'), isTrue);
    expect(AuthIdentity.isValidLoginId('partner1'), isTrue);
  });

  test('toAuthEmail maps username and passes through email', () {
    expect(
      AuthIdentity.toAuthEmail('jong_01'),
      'jong_01@${AuthIdentity.syntheticDomain}',
    );
    expect(
      AuthIdentity.toAuthEmail('jckim321@gmail.com'),
      'jckim321@gmail.com',
    );
  });

  test('loginIdFromAuthEmail only for synthetic domain', () {
    expect(
      AuthIdentity.loginIdFromAuthEmail(
        'jong_01@${AuthIdentity.syntheticDomain}',
      ),
      'jong_01',
    );
    expect(AuthIdentity.loginIdFromAuthEmail('jckim321@gmail.com'), isNull);
  });
}
