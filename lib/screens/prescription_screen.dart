import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medisukham/widgets/prescription_node_widget.dart';
import 'package:medisukham/models/prescription_node.dart';
import 'package:medisukham/services/gemini_api_service.dart';
import 'package:medisukham/services/alarm_persistence_service.dart';
import 'package:medisukham/services/permission_service.dart';
import 'package:medisukham/app.dart';

class PrescriptionScreen extends StatefulWidget {
  final File? imageFile;

  const PrescriptionScreen({super.key, this.imageFile});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  bool _isLoading = false;
  List<PrescriptionNode> _medicationNodes = [];
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _progressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.imageFile != null) {
      _processImage(widget.imageFile!);
    } else {
      _addPrescriptionNode();
    }
  }

  Future<String> _processImage(File image) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    PrescriptionAnalysisResult result = await GeminiApiService.instance
        .scanPrescription(image);

    setState(() {
      _isLoading = false;
      if (result.isSuccess) {
        _medicationNodes = result.nodes!;
      } else {
        _errorMessage = result.errorMessage;
        _medicationNodes = [];
      }
    });
    return '';
  }

  PrescriptionNode _createNewPrescriptionNode() {
    return PrescriptionNode(
      medicineName: 'Sample Medicine',
      startDate: DateTime.now(),
      days: 1,
      timings: [],
    );
  }

  void _addPrescriptionNode() {
    setState(() {
      _medicationNodes.add(_createNewPrescriptionNode());
    });
    // Scroll down only after new prescription node widget is added:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollDown();
    });
  }

  void _deletePrescriptionNode(PrescriptionNode nodeToDelete) {
    setState(() {
      _medicationNodes.remove(nodeToDelete);
    });
  }

  void _scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(seconds: 1),
      curve: Curves.fastEaseInToSlowEaseOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prescription')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child:
                  _isLoading // If loading,
                  ? Center(
                      child: CircularProgressIndicator(),
                    ) // Display indicator, else
                  : _errorMessage !=
                        null // If there's an error message
                  ? Center(
                      // Display error message, else
                      child: Text(
                        'Error: $_errorMessage',
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  : _medicationNodes
                        .isEmpty // If there's no medication nodes
                  ? Center(
                      child: Text('No prescriptions here.'),
                    ) // Display error, else
                  : ListView.builder(
                      // Display all prescription nodes
                      controller: _scrollController,
                      padding: EdgeInsets.zero,
                      itemCount: _medicationNodes.length,
                      itemBuilder: (context, index) {
                        final node = _medicationNodes[index];
                        return PrescriptionNodeWidget(
                          node: node,
                          onDelete: () => _deletePrescriptionNode(node),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _savePrescription,
              child: const Text('Save Prescription'),
            ),
          ],
        ),
      ),
      floatingActionButton: !_isLoading
          ? FloatingActionButton(
              onPressed: _addPrescriptionNode,
              tooltip: 'Add new prescription',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _savePrescription() async {
    bool canScheduleAlarms = true;
    if (_medicationNodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('There are no prescriptions to save.')),
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
      await AlarmPersistenceService.instance.savePrescriptions(
        _medicationNodes,
      );

      if (canScheduleAlarms) {
        // Schedule alarms:
        await AlarmPersistenceService.instance.scheduleAllReminders(
          _medicationNodes,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prescriptions and alarms set!')),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const MainPage(initialIndex: 1),
            ),
            // Stop removing routes only when stack is empty:
            (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save data or set alarms: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }
}
