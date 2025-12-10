import 'package:flutter/material.dart';
import 'package:medisukham/models/prescription_node.dart';
import 'package:medisukham/services/alarm_persistence_service.dart';
import 'package:medisukham/widgets/prescription_node_widget.dart';
import 'package:medisukham/services/permission_service.dart';
import 'package:medisukham/app.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  List<PrescriptionNode> _allMedications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoading = true);
    final List<PrescriptionNode> loadedNodes = await AlarmPersistenceService
        .instance
        .loadPrescriptions();
    setState(() {
      _allMedications = loadedNodes;
      _isLoading = false;
    });
  }

  void _handleNodeDeletion(PrescriptionNode nodeToDelete) async {
    setState(() {
      _allMedications.remove(nodeToDelete);
    });

    // Update alarm persistence service:
    await AlarmPersistenceService.instance.savePrescriptions(_allMedications);
    await AlarmPersistenceService.instance.scheduleAllReminders(
      _allMedications,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${nodeToDelete.medicineName} deleted and alarms updated.',
          ),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  int _getDaysRemaining(PrescriptionNode node) {
    final endDate = node.startDate.add(Duration(days: node.days));
    final today = DateTime.now();

    final remaining = endDate
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    return remaining > 0 ? remaining : 0; // To prevent negative numbers.
  }

  void _saveAllChangesAndSchedule() async {
    bool canScheduleAlarms = true;
    if (_allMedications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No medications to save or schedule.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (!(await PermissionService.instance.ensureExactAlarmPermission(
      context,
    ))) {
      canScheduleAlarms = false;
    }

    try {
      // Save data:
      await AlarmPersistenceService.instance.savePrescriptions(_allMedications);

      if (canScheduleAlarms) {
        // Schedule alarms:
        await AlarmPersistenceService.instance.scheduleAllReminders(
          _allMedications,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All changes saved and alarms updated.'),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Data saved, but alarms skipped due to permission denial.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save changes or schedule: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _goBackHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainPage(initialIndex: 0)),
      // Stop removing routes only when stack is empty:
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('All Medication Reminders')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_allMedications.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('All Medication Reminders')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning, size: 40),
              const SizedBox(height: 40),
              const Text('No active prescriptions found'),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _goBackHome,
                child: const Text('Go back to home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('All Medication Reminders')),
      body: ListView.builder(
        padding: const EdgeInsets.only(
          top: 16.0,
          left: 16.0,
          right: 16.0,
          bottom: 60.0,
        ),
        itemCount: _allMedications.length,
        itemBuilder: (context, index) {
          final node = _allMedications[index];
          final daysRemaining = _getDaysRemaining(node);

          return Column(
            children: [
              // Add in a chip indicating number of days left:
              Chip(
                label: Text(
                  '${node.days} Day Treatment: $daysRemaining Days Remaining',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: daysRemaining > 3
                    ? Colors.green.shade100
                    : Colors.red.shade100,
              ),
              // Use the existing prescription node widget:
              PrescriptionNodeWidget(
                key: ValueKey(node.id),
                node: node,
                onDelete: () => _handleNodeDeletion(node),
              ),
              const SizedBox(height: 10.0),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveAllChangesAndSchedule,
        label: Text(_isLoading ? 'Saving...' : 'Save all changes'),
        icon: const Icon(Icons.save),
        tooltip: 'Save All Changes and Update Alarms',
      ),
    );
  }
}
