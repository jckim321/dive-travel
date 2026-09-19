// Generated from android/app/google-services.json (project dive-travel-9dcf7).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions는 이 플랫폼을 아직 지원하지 않습니다.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCeMEzjIqpTu9kReuKVGvfVdYreo3sxN4g',
    appId: '1:996020953462:android:4683f429bd96582e335a57',
    messagingSenderId: '996020953462',
    projectId: 'dive-travel-9dcf7',
    storageBucket: 'dive-travel-9dcf7.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCeMEzjIqpTu9kReuKVGvfVdYreo3sxN4g',
    appId: '1:996020953462:android:b8246e7a21eee74d335a57',
    messagingSenderId: '996020953462',
    projectId: 'dive-travel-9dcf7',
    authDomain: 'dive-travel-9dcf7.firebaseapp.com',
    storageBucket: 'dive-travel-9dcf7.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBDHkZAAjeAf4hS18CBvor0WszBe1EPfFM',
    appId: '1:996020953462:ios:310cedbbf79bf783335a57',
    messagingSenderId: '996020953462',
    projectId: 'dive-travel-9dcf7',
    storageBucket: 'dive-travel-9dcf7.firebasestorage.app',
    iosBundleId: 'com.jongcheol.divetravel',
  );

  static const FirebaseOptions macos = ios;
  static const FirebaseOptions web = windows;
}
