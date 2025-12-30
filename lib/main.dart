import 'package:alarm/alarm.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:medisukham/services/gemini_api_service.dart';
import 'package:medisukham/services/settings_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'app.dart';
import 'firebase_options.dart';
import 'debug_secret.dart'; // File contains debug key for cloud functions.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise settings
  final settingsService = SettingsService();

  // Initialise Gemini API Service
  GeminiApiService.initialize(settingsService);

  // Initialising Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialising Firebase App Check
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kReleaseMode
        ? const AndroidPlayIntegrityProvider()
        : const AndroidDebugProvider(debugToken: STATIC_DEBUG_SECRET),
    providerApple: kReleaseMode
        ? const AppleDeviceCheckProvider()
        : const AppleDebugProvider(debugToken: STATIC_DEBUG_SECRET),
  );
  FirebaseAppCheck.instance.getToken(true).then((token) {
    if (kDebugMode) {
      print("Current App Check Token: $token");
    }
  });

  // Initialise alarms
  await Alarm.init();

  // Timezone Initialisation:
  tz.initializeTimeZones();

  runApp(const MyApp());
}
