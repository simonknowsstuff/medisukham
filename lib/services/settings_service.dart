import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  SettingsService._internal();
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

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

  // Cache variables:
  bool _vibrate = true;
  bool _autoCleanup = true;
  double _volume = 0.8;
  Map<String, int> _timings = {};

  // Load everything into memory once (Cached implementation):
  Future<void> init() async {
    _vibrate = await _prefs.getBool(_keyVibrate) ?? true;
    _autoCleanup = await _prefs.getBool(_keyAutoCleanup) ?? true;
    _volume = await _prefs.getDouble(_keyVolume) ?? 0.8;

    final String? jsonString = await _prefs.getString(_keyTimingsMap);
    if (jsonString != null) {
      final dynamic decoded = jsonDecode(jsonString); // Decode as dynamic map

      if (decoded is Map) {
        _timings = decoded.map((key, value) {
          return MapEntry(key.toString(), value as int); // Cast entries to <String, int>
        });
      }
    } else {
      _timings = Map.from(_defaultTimings);
    }
  }

  // Timings:
  Map<String, int> getAllTimings() {
    return _timings;
  }

  Future<void> updateTiming(String label, TimeOfDay time) async {
    final updatedTimings = Map<String, int>.from(_timings); // Create new map instance
    final int updatedMinutes = time.hour * 60 + time.minute;
    updatedTimings[label] = updatedMinutes;
    _timings = updatedTimings;
    notifyListeners();
    await _prefs.setString(_keyTimingsMap, jsonEncode(updatedTimings));
  }

  TimeOfDay getTiming(String label) {
    final timings = getAllTimings();
    final minutes = timings[label] ?? _defaultTimings[label] ?? 480;
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  // Auto-Cleanup:
  bool getAutoCleanup() {
    return _autoCleanup;
  }

  Future<void> setAutoCleanup(bool value) async {
    _autoCleanup = value;
    notifyListeners();
    await _prefs.setBool(_keyAutoCleanup, value);
  }

  // Vibrate:
  bool getVibrate() {
    return _vibrate;
  }

  Future<void> setVibrate(bool value) async {
    _vibrate = value;
    notifyListeners();
    await _prefs.setBool(_keyVibrate, value);
  }

  // Volume:
  double getVolume() {
    return _volume;
  }

  Future<void> setVolume(double value) async {
    _volume = value;
    notifyListeners();
    await _prefs.setDouble(_keyVolume, value);
  }
}
