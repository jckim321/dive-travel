import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/core/auth/pending_profile.dart';
import 'package:dive_travel_app/core/models/partner_meeting_report.dart';
import 'package:dive_travel_app/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  pendingProfileWrites = PrefsPendingProfileStore();

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

  runApp(
    DiveTravelApp(
      firebaseReady: firebaseReady,
      initialReportId: meetingReportIdFromFragment(Uri.base.fragment),
    ),
  );
}
