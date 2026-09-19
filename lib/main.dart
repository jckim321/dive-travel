import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
    firebaseReady = true;
  } catch (error, stackTrace) {
    debugPrint('Firebase.initializeApp 실패: $error');
    debugPrint('$stackTrace');
  }

  runApp(DiveTravelApp(firebaseReady: firebaseReady));
}
