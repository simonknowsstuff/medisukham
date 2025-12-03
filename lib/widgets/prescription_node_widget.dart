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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.node.medicineName);
    _daysController = TextEditingController(text: widget.node.days.toString());
  }

  Widget _buildTimingsChips() {
    return Wrap(
      spacing: 8.0,
      children: DosageContext.values.map((context) {
        final isSelected = widget.node.timings.any((t) => t.context == context);
        return ChoiceChip(
          label: Text(context.toString().split('.').last),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                widget.node.timings.add(DosageTiming(context: context));
              } else {
                widget.node.timings.removeWhere((t) => t.context == context);
              }
            });
          },
        );
      }).toList(),
    );
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

            // 3. Timings/Context Chips
            const Text(
              'Dosage Timings:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _buildTimingsChips(),

            // 4. Delete button
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
