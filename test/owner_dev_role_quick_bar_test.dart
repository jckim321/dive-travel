import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/dev/dev_roles.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  test('DevRoles.canUse requires enabled and owner email', () {
    expect(DevRoles.enabled, isTrue);
    expect(DevRoles.canUse(AppOwner.email), isTrue);
    expect(DevRoles.canUse('other@example.com'), isFalse);
    expect(DevRoles.canUse(null), isFalse);
  });

  test('owner canUseDevRoles; guest cannot', () async {
    final ownerRepo = MemoryDiverRepository.forTest(isAdmin: true);
    final ownerStore = DiverStore(ownerRepo);
    await ownerRepo.signIn(email: AppOwner.email, password: 'test');
    await pumpEventQueue();
    expect(ownerStore.canUseDevRoles, isTrue);

    final guestRepo = MemoryDiverRepository.forTest(isAdmin: true);
    final guestStore = DiverStore(guestRepo);
    await guestRepo.signIn(email: 'guest@example.com', password: 'test');
    await pumpEventQueue();
    expect(guestStore.canUseDevRoles, isFalse);
  });

  test('trial caption strings exist in en and ko', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final ko = lookupAppLocalizations(const Locale('ko'));
    expect(en.devRolesTrialCaption.toLowerCase(), contains('trial'));
    expect(ko.devRolesTrialCaption, contains('시험용'));
  });
}
