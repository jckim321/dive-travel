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
      AuthIdentity.toAuthEmail('Jong_01'),
      'jong_01@${AuthIdentity.syntheticDomain}',
    );
    expect(
      AuthIdentity.toAuthEmail('jckim321@gmail.com'),
      'jckim321@gmail.com',
    );
  });

  test('한글 이름표는 u_ 로 시작하는 ASCII 로컬파트가 된다', () {
    expect(
      AuthIdentity.toAuthEmail('가'),
      'u_eab080@${AuthIdentity.syntheticDomain}',
    );
    expect(
      AuthIdentity.toAuthEmail('바다'),
      'u_ebb094eb8ba4@${AuthIdentity.syntheticDomain}',
    );
    final local = AuthIdentity.toAuthEmail('바다거북').split('@').first;
    expect(local.startsWith('u_'), isTrue);
    expect(RegExp(r'^u_[0-9a-f]+$').hasMatch(local), isTrue);
    expect(AuthIdentity.storedLoginId('바다거북'), '바다거북');
    expect(AuthIdentity.storedLoginId('Jong_01'), 'jong_01');
    expect(AuthIdentity.nameTagIssue('admin'), NameTagIssue.reserved);
    expect(AuthIdentity.nameTagIssue('바다!'), NameTagIssue.format);
    expect(AuthIdentity.nameTagIssue('가' * 11), NameTagIssue.tooLong);
    expect(
      AuthIdentity.nameTagIssue('owner@dive.test', allowEmail: true),
      isNull,
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
