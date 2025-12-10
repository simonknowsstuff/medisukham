import 'package:uuid/uuid.dart';

enum DosageContext { Morning, Afternoon, Evening, Night }

class DosageTiming {
  DosageContext context;
  DosageTiming({required this.context});

  factory DosageTiming.fromJson(Map<String, dynamic> json) {
    String contextString = json['context'] as String;
    return DosageTiming(
      context: DosageContext.values.firstWhere(
        (e) => e.toString().split('.').last == contextString,
        orElse: () => DosageContext.Morning,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'context': context.toString().split('.').last};
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

    final timingsList = rawTimingsList
        .whereType<Map<String, dynamic>>()
        .map((t) => DosageTiming.fromJson(t))
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
