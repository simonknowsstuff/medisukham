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
}

class PrescriptionNode {
  String medicineName;
  int days;
  List<DosageTiming> timings;
  DateTime startDate;

  PrescriptionNode({
    required this.medicineName,
    required this.startDate,
    required this.days,
    required this.timings,
  });

  factory PrescriptionNode.fromJson(Map<String, dynamic> json) {
    final dosageJson =
        json['dosages'] as Map<String, dynamic>? ??
        {}; // Using ?? to prevent null access

    final rawTimingsList =
        dosageJson['timings'] as List? ?? []; // Safely accessing timings

    final medicineName = json['medicine_name'] as String?;
    if (medicineName == null) {
      throw FormatException("Medicine name is missing");
    }

    final timingsList = rawTimingsList
        .whereType<Map<String, dynamic>>()
        .map((t) => DosageTiming.fromJson(t))
        .toList();

    return PrescriptionNode(
      medicineName: medicineName,
      startDate: DateTime.parse(
        dosageJson['start_date'] as String? ?? '2000-01-01',
      ),
      days: dosageJson['days'] as int? ?? 1, // Keep 1 as default
      timings: timingsList,
    );
  }
}
