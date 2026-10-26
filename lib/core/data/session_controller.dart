import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/auth/guest_browse_store.dart';
import 'package:dive_travel_app/core/data/diver_repository.dart';
import 'package:dive_travel_app/core/models/app_user.dart';

class SessionController extends ChangeNotifier {
  SessionController(this._repository) {
    _readyTimer = Timer(const Duration(seconds: 8), () {
      if (_ready) {
        return;
      }
      _ready = true;
      notifyListeners();
    });
    _subscription = _repository.authState().listen(
      (user) {
        _user = user;
        _ready = true;
        _readyTimer?.cancel();
        notifyListeners();
        if (user == null) {
          return;
        }
        unawaited(_syncProfile(user));
      },
      onError: (Object error) {
        _error = error.toString();
        _ready = true;
        _readyTimer?.cancel();
        notifyListeners();
      },
    );
  }

  final DiverRepository _repository;
  StreamSubscription<AppUser?>? _subscription;
  Timer? _readyTimer;
  AppUser? _user;
  bool _ready = false;
  String? _error;
  bool _busy = false;

  AppUser? get user => _user;
  bool get ready => _ready;
  bool get isSignedIn => _user != null;
  bool get busy => _busy;
  String? get error => _error;
  DiverRepository get repository => _repository;

  Future<void> signIn({
    required String email,
    required String password,
  }) {
    return _run(() async {
      await _repository.signIn(email: email, password: password);
      await _ensureProfileAndGate();
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
    String? loginId,
    String? nationality,
    String? birthDate,
    String? phone,
    bool termsAccepted = false,
    bool privacyAccepted = false,
    bool marketingOptIn = false,
  }) {
    return _run(
      () => _repository.signUp(
        email: email,
        password: password,
        displayName: displayName,
        loginId: loginId,
        nationality: nationality,
        birthDate: birthDate,
        phone: phone,
        termsAccepted: termsAccepted,
        privacyAccepted: privacyAccepted,
        marketingOptIn: marketingOptIn,
      ),
    );
  }

  Future<void> signOut() async {
    guestBrowse.clear();
    await _repository.signOut();
  }

  Future<void> sendPasswordReset(String email) {
    return _run(() => _repository.sendPasswordReset(email));
  }

  Future<void> _syncProfile(AppUser user) async {
    try {
      await _ensureProfileAndGate();
    } catch (error) {
      _error = error.toString();
      notifyListeners();
    }
  }

  /// 로그인·세션 복원마다 users 문서를 만들고, 차단·탈퇴면 바로 로그아웃합니다.
  Future<void> _ensureProfileAndGate() async {
    final user = await _repository.currentAuthUser();
    if (user == null) {
      return;
    }
    await _repository.ensureUserDocument(user).timeout(
      const Duration(seconds: 8),
    );
    if (!await _repository.isLoginBlocked(user.uid)) {
      return;
    }
    await signOut();
    _error = 'ACCOUNT_CLOSED';
    notifyListeners();
    throw StateError('ACCOUNT_CLOSED');
  }

  Future<void> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _readyTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}

class SessionScope extends InheritedNotifier<SessionController> {
  const SessionScope({
    super.key,
    required SessionController session,
    required super.child,
  }) : super(notifier: session);

  static SessionController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope가 위젯 트리에 없습니다.');
    return scope!.notifier!;
  }
}
