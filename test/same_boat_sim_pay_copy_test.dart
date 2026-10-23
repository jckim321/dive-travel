import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  test('(a) same-boat SimPay keys differ from Explore request copy', () {
    final ko = lookupAppLocalizations(const Locale('ko'));
    final en = lookupAppLocalizations(const Locale('en'));

    expect(ko.simPaySameBoatTitle, isNot(equals(ko.simPayTitle)));
    expect(ko.simPaySameBoatAction, isNot(equals(ko.simPayAction)));
    expect(ko.simPaySameBoatNotice, isNot(equals(ko.simPayNotice)));
    expect(ko.simPaySameBoatTitle, '결제 확인');
    expect(ko.simPaySameBoatAction, '결제하기');
    expect(en.simPaySameBoatTitle.toLowerCase(), contains('payment'));
    expect(en.simPaySameBoatAction.toLowerCase(), 'pay');
  });

  test('(b) general product notice stays request-style', () {
    final ko = lookupAppLocalizations(const Locale('ko'));
    final en = lookupAppLocalizations(const Locale('en'));
    expect(ko.simPayNotice, contains('지금은 결제하지 않습니다'));
    expect(ko.simPayTitle, contains('예약 요청'));
    expect(ko.simPayAction, '예약 요청');
    expect(en.simPayNotice.toLowerCase(), contains('no charge'));
  });

  test('(c) same-boat notice mentions test payment and seat confirm', () {
    final ko = lookupAppLocalizations(const Locale('ko'));
    final en = lookupAppLocalizations(const Locale('en'));
    expect(ko.simPaySameBoatNotice, contains('테스트 결제'));
    expect(ko.simPaySameBoatNotice, contains('확정'));
    expect(ko.sameBoatSeatConfirmed, contains('테스트 결제'));
    expect(en.simPaySameBoatNotice.toLowerCase(), contains('test payment'));
    expect(en.sameBoatSeatConfirmed.toLowerCase(), contains('test payment'));
  });
}
