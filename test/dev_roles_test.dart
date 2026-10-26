import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/models/same_boat_seat_open.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

void main() {
  test('grants stay off', () {
    expect(AppConstants.grantAdminToCurrentSession, isFalse);
    expect(AppConstants.grantBusinessToCurrentSession, isFalse);
  });

  test('same-boat open writes approved; partner cannot move hidden or rejected', () {
    expect(
      SameBoatSeatOpenLogic.statusWhenOpen(
        isAdmin: false,
        previous: SameBoatStatus.closed,
      ),
      SameBoatStatus.approved,
    );
    expect(
      SameBoatSeatOpenLogic.statusWhenOpen(
        isAdmin: false,
        previous: SameBoatStatus.pending,
      ),
      SameBoatStatus.approved,
    );
    expect(
      SameBoatSeatOpenLogic.statusWhenOpen(
        isAdmin: false,
        previous: SameBoatStatus.rejected,
      ),
      SameBoatStatus.rejected,
    );
    expect(
      SameBoatSeatOpenLogic.statusWhenClosed(
        isAdmin: false,
        previous: SameBoatStatus.hidden,
      ),
      SameBoatStatus.hidden,
    );
    expect(
      SameBoatSeatOpenLogic.statusWhenOpen(
        isAdmin: true,
        previous: SameBoatStatus.hidden,
      ),
      SameBoatStatus.approved,
    );
  });
}
