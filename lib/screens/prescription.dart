import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medisukham/widgets/prescription_node_widget.dart';
import 'package:medisukham/models/prescription_node.dart';
import 'package:medisukham/services/gemini_api_service.dart';

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

  final TextEditingController _progressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.imageFile != null) {
      _processImage(widget.imageFile!);
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
  }

  void _deletePrescriptionNode(PrescriptionNode nodeToDelete) {
    setState(() {
      _medicationNodes.remove(nodeToDelete);
    });
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
                      child: Text('No prescriptions found in the image'),
                    ) // Display error, else
                  : ListView.builder(
                      // Display all prescription nodes
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

  void _savePrescription() {
    // TODO: Implement prescription saving
    throw UnimplementedError();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }
}
