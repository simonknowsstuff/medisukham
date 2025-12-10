import 'package:flutter/material.dart';
import '../models/prescription_node.dart';

class PrescriptionNodeWidget extends StatefulWidget {
  final PrescriptionNode node;
  final VoidCallback onDelete;

  const PrescriptionNodeWidget({
    super.key,
    required this.node,
    required this.onDelete,
  });

  @override
  State<PrescriptionNodeWidget> createState() => _PrescriptionNodeWidgetState();
}

class _PrescriptionNodeWidgetState extends State<PrescriptionNodeWidget> {
  late TextEditingController _nameController;
  late TextEditingController _daysController;

  Future<void> _selectTime(DosageTiming timingToEdit) async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: timingToEdit.toTimeOfDay(),
    );

    if (newTime != null) {
      setState(() {
        timingToEdit.minutesPastMidnight = newTime.hour * 60 + newTime.minute;
      });
    }
  }

  void _deleteTiming(DosageTiming timingToDelete) {
    setState(() {
      widget.node.timings.remove(timingToDelete);
    });
  }

  void _addTiming() async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );

    if (newTime != null) {
      setState(() {
        final newMinutes = newTime.hour * 60 + newTime.minute;
        widget.node.timings.add(DosageTiming(minutesPastMidnight: newMinutes));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.node.medicineName);
    _daysController = TextEditingController(text: widget.node.days.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Medicine Name Input
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medicine Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  widget.node.medicineName = value, // Update node directly
            ),
            const SizedBox(height: 12),

            // 2. Days and Start Date (in a Row)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _daysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duration (Days)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => widget.node.days =
                        int.tryParse(value) ?? widget.node.days,
                  ),
                ),
                const SizedBox(width: 16),

                GestureDetector(
                  onTap: () async {
                    final newDate = await showDatePicker(
                      context: context,
                      initialDate: widget.node.startDate,
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2030),
                    );
                    if (newDate != null) {
                      setState(() {
                        widget.node.startDate = newDate;
                      });
                    }
                  },
                  child: Chip(
                    label: Text(
                      'Start Date: ${widget.node.startDate.toLocal().toString().split(' ')[0]}',
                    ),
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 3. Dynamic Timings List and Actions
            const Text(
              'Scheduled Times:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            ...widget.node.timings.map((timing) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.alarm),

                // Display the explicit time
                title: Text(
                  timing.toTimeOfDay().format(context),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),

                // Actions: Edit and Delete
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _selectTime(timing),
                      tooltip: 'Edit Time',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.red,
                      ),
                      onPressed: () => _deleteTiming(timing),
                      tooltip: 'Delete Time',
                    ),
                  ],
                ),
              );
            }),

            // Add new time:
            TextButton.icon(
              onPressed: _addTiming,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add New Time'),
            ),

            const SizedBox(height: 12),
            const Divider(),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text("Delete"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: widget.onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _daysController.dispose();
    super.dispose();
  }
}
