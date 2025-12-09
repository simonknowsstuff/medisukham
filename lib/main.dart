import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'app.dart';
import 'firebase_options.dart';
import 'debug_secret.dart'; // File contains debug key for cloud functions.

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // For testing, Functions Emulator hosted at 5001, Auth Emulator hosted at 9099
  // if (kDebugMode) {
  //   const host = '10.0.2.2';
  //   FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
  //   await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  // }

  // Local notifications setup:
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();
  const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitializationSettings,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Timezone Initialisation:
  tz.initializeTimeZones();

  runApp(const MyApp());
}
