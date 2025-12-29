import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  SettingsService._internal();
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SharedPreferencesAsync sharedPrefs = SharedPreferencesAsync();

  static const String _keyTimingsMap = 'timings_map';
  static const String _keyAutoCleanup = 'auto_cleanup';
  static const String _keyVibrate = 'vibrate';
  static const String _keyVolume = 'volume';

  final Map<String, int> _defaultTimings = {
    'Morning': 480,
    'Afternoon': 720,
    'Evening': 1080,
    'Night': 1260,
  };

  // Timings:
  Future<Map<String, int>> getAllTimings() async {
    final String? jsonString = await sharedPrefs.getString(_keyTimingsMap);
    if (jsonString == null) return Map.from(_defaultTimings);

    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return Map.from(_defaultTimings);
    }
  }

  Future<void> updateTiming(String label, TimeOfDay time) async {
    final timings = await getAllTimings();
    timings[label] = time.hour * 60 + time.minute;

    await sharedPrefs.setString(_keyTimingsMap, jsonEncode(timings));
    notifyListeners();
  }

  Future<TimeOfDay> getTiming(String label) async {
    final timings = await getAllTimings();
    final minutes = timings[label] ?? _defaultTimings[label] ?? 480;
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  // Auto-Cleanup:
  Future<bool> getAutoCleanup() async {
    return await sharedPrefs.getBool(_keyAutoCleanup) ?? true;
  }

  Future<void> setAutoCleanup(bool value) async {
    await sharedPrefs.setBool(_keyAutoCleanup, value);
    notifyListeners();
  }

  // Vibrate:
  Future<bool> getVibrate() async {
    return await sharedPrefs.getBool(_keyVibrate) ?? true;
  }

  Future<void> setVibrate(bool value) async {
    await sharedPrefs.setBool(_keyVibrate, value);
    notifyListeners();
  }

  // Volume:
  Future<double> getVolume() async {
    return await sharedPrefs.getDouble(_keyVolume) ?? 0.8;
  }

  Future<void> setVolume(double value) async {
    await sharedPrefs.setDouble(_keyVolume, value);
    notifyListeners();
  }
}
