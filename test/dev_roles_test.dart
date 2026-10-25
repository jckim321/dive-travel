import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/models/same_boat_seat_open.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

void main() {
  test('grants stay off', () {
    expect(AppConstants.grantAdminToCurrentSession, isFalse);
    expect(AppConstants.grantBusinessToCurrentSession, isFalse);
  });

  test('same-boat statusWhenOpen goes live; legacy pending stays for partner', () {
    expect(
      SameBoatSeatOpenLogic.statusWhenOpen(
        isAdmin: false,
        previous: SameBoatStatus.closed,
      ),
      SameBoatStatus.approved,
    );
    expect(
      SameBoatSeatOpenLogic.statusWhenOpen(
        isAdmin: true,
        previous: SameBoatStatus.closed,
      ),
      SameBoatStatus.approved,
    );
    expect(
      SameBoatSeatOpenLogic.statusWhenOpen(
        isAdmin: false,
        previous: SameBoatStatus.pending,
      ),
      SameBoatStatus.pending,
    );
    expect(
      SameBoatSeatOpenLogic.statusWhenOpen(
        isAdmin: true,
        previous: SameBoatStatus.pending,
      ),
      SameBoatStatus.approved,
    );
  });
}
