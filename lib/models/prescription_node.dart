import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class DosageTiming {
  int minutesPastMidnight;
  DosageTiming({required this.minutesPastMidnight});

  TimeOfDay toTimeOfDay() {
    return TimeOfDay(
        hour: minutesPastMidnight ~/ 60,
        minute: minutesPastMidnight % 60,
    );
  }

  static int toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  factory DosageTiming.fromJson(Map<String, dynamic> json) {
    final int timeInt = json['minutesPastMidnight'] as int ?? 0;
    return DosageTiming(minutesPastMidnight: timeInt);
  }

  Map<String, dynamic> toJson() {
    return {'minutesPastMidnight': minutesPastMidnight };
  }
}

class PrescriptionNode {
  final String id;
  String medicineName;
  int days;
  List<DosageTiming> timings;
  DateTime startDate;

  PrescriptionNode({
    String? id,
    required this.medicineName,
    required this.startDate,
    required this.days,
    required this.timings,
  }) : id = id ?? const Uuid().v4();

  static TimeOfDay _getGlobalTimeForContext(String context) {
    switch (context) {
      case 'Morning':
        return const TimeOfDay(hour: 8, minute: 0);
      case 'Afternoon':
        return const TimeOfDay(hour: 12, minute: 0);
      case 'Evening':
        return const TimeOfDay(hour: 18, minute: 0);
      case 'Night':
        return const TimeOfDay(hour: 21, minute: 0);
      default:
        return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  factory PrescriptionNode.fromJsonLocal(Map<String, dynamic> json) {
    final rawDays = json['days'] as int?;
    final rawStartDate = json['startDate'] as String?;
    final rawTimingsList = json['timings'] as List? ?? [];

    final id = json['id'] as String?;

    final medicineName = json['medicineName'] as String?;
    if (medicineName == null || medicineName.isEmpty) {
      throw FormatException("Medicine name is missing");
    }

    final timingsList = rawTimingsList
        .whereType<Map<String, dynamic>>()
        .map((t) => DosageTiming.fromJson(t))
        .toList();

    return PrescriptionNode(
      id: id,
      medicineName: medicineName,
      startDate: DateTime.parse(rawStartDate ?? '2000-01-01'),
      days: rawDays ?? 1, // Keep 1 as default
      timings: timingsList,
    );
  }

  factory PrescriptionNode.fromJsonGemini(Map<String, dynamic> json) {
    final Map<String, dynamic>? dosageJson = json['dosages'] is Map
        ? json['dosages'] as Map<String, dynamic>
        : null;
    final Map<String, dynamic> safeDosageJson = dosageJson ?? {};

    final rawDays = safeDosageJson['days'] as int?;
    final rawStartDate = safeDosageJson['startDate'] as String?;
    final rawTimingsList = safeDosageJson['timings'] as List? ?? [];

    final medicineName = json['medicineName'] as String?;
    if (medicineName == null || medicineName.isEmpty) {
      throw FormatException('Medicine name is missing');
    }

    final List<DosageTiming> timingsList = rawTimingsList
        .whereType<Map<String, dynamic>>()
        .map((t) {
          final contextString = t['context'] as String ?? 'Morning';
          final defaultTime = PrescriptionNode._getGlobalTimeForContext(contextString);
          final minutes = defaultTime.hour * 60 + defaultTime.minute;
          return DosageTiming(minutesPastMidnight: minutes);
        })
        .toList();

    return PrescriptionNode(
      medicineName: medicineName,
      startDate: DateTime.parse(rawStartDate ?? '2000-01-01'),
      days: rawDays ?? 1, // Keep 1 as default
      timings: timingsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineName': medicineName,
      'startDate': startDate.toIso8601String(),
      'days': days,
      'timings': timings.map((t) => t.toJson()).toList(),
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}
