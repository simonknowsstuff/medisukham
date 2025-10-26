import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PrescriptionScreen extends StatefulWidget {
  final File? imageFile;

  const PrescriptionScreen({super.key, this.imageFile});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  bool _isLoading = false;
  String _recognizedText = 'No text detected yet.';

  final TextEditingController _medicineNameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.imageFile != null) {
      _processImage(widget.imageFile!);
    }
  }

  Future<void> _processImage(File image) async {
    // TODO: LLM pipeline
    // This is responsible for handling the OCR + LLM pipeline on the image
    // and reflecting those results on the editable text fields
    setState(() => _isLoading = true);

    final InputImage inputImage = InputImage.fromFile(image);
    final TextRecognizer textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );

    String text = recognizedText.text;
    _medicineNameController.text = 'Still to be processed :P';
    _dosageController.text = 'Still to be processed :P';
    _recognizedText = recognizedText.text;

    textRecognizer.close();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prescription')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  if (widget.imageFile != null)
                    Image.file(widget.imageFile!, height: 200),
                  TextField(
                    controller: _medicineNameController,
                    decoration: const InputDecoration(
                      labelText: 'Medicine Name',
                    ),
                  ),
                  TextField(
                    controller: _dosageController,
                    decoration: const InputDecoration(labelText: 'Dosage'),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(
                          _recognizedText,
                          style: const TextStyle(fontSize: 16),
                      ),
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
    );
  }

  void _savePrescription() {
    // TODO: Implement prescription saving
    throw UnimplementedError();
  }
}
