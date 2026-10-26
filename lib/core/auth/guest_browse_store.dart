import 'package:flutter/foundation.dart';

/// Session flag: unsigned users may skip the full-screen auth gate.
class GuestBrowseStore extends ChangeNotifier {
  var _browsing = false;

  bool get browsing => _browsing;

  void enable() {
    if (_browsing) return;
    _browsing = true;
    notifyListeners();
  }

  /// Clears guest browse (e.g. after sign-out so AuthGate returns).
  void clear() {
    if (!_browsing) return;
    _browsing = false;
    notifyListeners();
  }

  @visibleForTesting
  void reset() => clear();
}

/// App-wide guest-browse flag (AuthGate + 「먼저 둘러보기」).
GuestBrowseStore guestBrowse = GuestBrowseStore();
