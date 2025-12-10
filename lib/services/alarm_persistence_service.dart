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

  Future<void> savePrescriptions(List<PrescriptionNode> nodes) async {
    final List<Map<String, dynamic>> jsonList = nodes
        .map((node) => node.toJson())
        .toList();
    final String jsonString = jsonEncode(jsonList);

    final prefs = SharedPreferencesAsync();
    await prefs.setString(_prescriptionsKey, jsonString);

    if (kDebugMode) {
      print('Saved prescriptions!');
    }
  }

  Future<List<PrescriptionNode>> loadPrescriptions() async {
    final prefs = SharedPreferencesAsync();
    final String? jsonString = await prefs.getString(_prescriptionsKey);

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

  Future<void> scheduleAllReminders(List<PrescriptionNode> medications) async {
    final FlutterLocalNotificationsPlugin plugin =
        FlutterLocalNotificationsPlugin();
    await plugin.cancelAll();

    int notificationId = 0;

    for (var node in medications) {
      if (node.days <= 0) continue;

      final initialDate = DateTime(
        node.startDate.year,
        node.startDate.month,
        node.startDate.day,
      );

      for (var timing in node.timings) {
        final int minutes = timing.minutesPastMidnight;
        final int hour = minutes ~/ 60;
        final int minute = minutes % 60;
        final now = DateTime.now();

        DateTime scheduledTime = DateTime(
          initialDate.year,
          initialDate.month,
          initialDate.day,
          hour,
          minute,
          0,
        );

        if (scheduledTime.isBefore(now)) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }

        final tz.TZDateTime scheduledTimeTZ = tz.TZDateTime.from(
          scheduledTime,
          tz.local, // Use the device's current time zone
        );

        await plugin.zonedSchedule(
          notificationId++,
          'Medication time: ${node.medicineName}',
          'Take your dose now.',
          scheduledTimeTZ,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'medisukham_alarms', // Channel ID
              'Medication Reminders',
              channelDescription: 'Reminders for scheduled doses.',
              importance: Importance.max,
              priority: Priority.max,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,

        );
      }
    }
  }
}
