import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:medisukham/models/prescription_node.dart';
import 'package:medisukham/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:alarm/alarm.dart';

class AlarmPersistenceService {
  AlarmPersistenceService._internal();
  static final AlarmPersistenceService instance =
      AlarmPersistenceService._internal();
  final SettingsService _settingsService = SettingsService();
  static const String _prescriptionsKey = 'saved_medications';

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
          // if (kDebugMode) {
          //   print('Data: $jsonItem');
          // }
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
    await Alarm.stopAll();

    int alarmId = 1;
    final now = DateTime.now();

    final volume = await _settingsService.getVolume();
    final hasVibrate = await _settingsService.getVibrate();
    bool isAutoCleanup = await _settingsService.getAutoCleanup();

    for (var node in medications) {
      if (node.days <= 0 && isAutoCleanup) continue;

      final initialDate = node.startDate;
      for (var timing in node.timings) {
        final int minutes = timing.minutesPastMidnight;
        final int hour = minutes ~/ 60;
        final int minute = minutes % 60;

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

        final alarmSettings = AlarmSettings(
          id: alarmId++,
          dateTime: scheduledTimeTZ,
          assetAudioPath: 'assets/alarm.wav',
          loopAudio: true,
          vibrate: hasVibrate,
          volumeSettings: VolumeSettings.fade(
            volume: volume,
            fadeDuration: Duration(seconds: 5),
            volumeEnforced: true,
          ),
          androidFullScreenIntent: false,
          notificationSettings: NotificationSettings(
            title: 'Medication Time: ${node.medicineName}',
            body: 'Take your dose now.',
            stopButton: 'Stop the alarm',
          ),
          warningNotificationOnKill: true,
        );

        try {
          await Alarm.set(alarmSettings: alarmSettings);
          if (kDebugMode) {
            print('Alarm set for: ${node.medicineName}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error setting alarms: $e');
          }
          rethrow;
        }
      }
    }
  }
}
