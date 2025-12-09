import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:medisukham/models/prescription_node.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AlarmPersistenceService {
  AlarmPersistenceService._internal();
  static final AlarmPersistenceService instance =
      AlarmPersistenceService._internal();
  static const String _prescriptionsKey = 'saved_medications';

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Map<String, int> _getTimeFromContext(DosageContext context) {
    switch (context) {
      // TODO: Give user option to modify context timings, hardcoded for now.
      case DosageContext.Morning:
        return {'hour': 8, 'minute': 0};
      case DosageContext.Afternoon:
        return {'hour': 12, 'minute': 0};
      case DosageContext.Evening:
        return {'hour': 18, 'minute': 0};
      case DosageContext.Night:
        return {'hour': 21, 'minute': 0};
    }
  }

  Future<void> savePrescriptions(List<PrescriptionNode> nodes) async {
    final List<Map<String, dynamic>> jsonList = nodes
        .map((node) => node.toJson())
        .toList();
    final String jsonString = jsonEncode(jsonList);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prescriptionsKey, jsonString);
    if (kDebugMode) {
      print('Saved prescriptions!');
    }
  }

  Future<List<PrescriptionNode>> loadPrescriptions() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_prescriptionsKey);

    if (jsonString == null) {
      return [];
    }
    try {
      final List<dynamic> rawList = jsonDecode(jsonString);
      List<PrescriptionNode> validNodes = [];

      for (var jsonItem in rawList) {
        if (jsonItem is Map<String, dynamic>) {
          if (kDebugMode) {
            print('Data: $jsonItem');
          }
          try {
            validNodes.add(PrescriptionNode.fromJsonLocal(jsonItem));
          } catch (e) {
            if (kDebugMode) {
              print('Skipping current node item: $e');
              print('Corrupt data: $jsonItem');
            }
          }
        }
      }

      return validNodes;
    } catch (e) {
      if (kDebugMode) {
        print('FATAL: Error decoding entire prescriptions list: $e');
      }
      return [];
    }
  }

  Future<void> scheduleAllReminders(List<PrescriptionNode> nodes) async {
    final FlutterLocalNotificationsPlugin plugin =
        FlutterLocalNotificationsPlugin();
    await plugin.cancelAll();

    int notificationId = 0;

    for (final node in nodes) {
      final timingsToSet = node.timings.isNotEmpty
          ? node.timings
          : [DosageTiming(context: DosageContext.Morning)];
      for (final timing in timingsToSet) {
        final time = _getTimeFromContext(timing.context);
        final hour = time['hour']!;
        final minute = time['minute']!;

        await plugin.zonedSchedule(
          notificationId++,
          'Medication Time: ${node.medicineName}',
          'It is time for your ${timing.context.toString().split('.').last} dose.',
          _nextInstanceOfTime(hour, minute),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'medisukham_channel_id',
              'Medication Reminders',
              channelDescription: 'Reminds for medication from Medisukham.',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }
}
