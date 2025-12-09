import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:medisukham/screens/prescription_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _imageFile;

  Future<CroppedFile?> _cropImage(String imgPath) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imgPath,
      uiSettings: [
        AndroidUiSettings(toolbarTitle: 'Crop image', lockAspectRatio: false),
        IOSUiSettings(title: 'Crop image', aspectRatioLockEnabled: false),
      ],
    );

    return croppedFile;
  }

  Future<void> _pickImage(BuildContext context, ImageSource imageSource) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: imageSource);

    if (image != null) {
      setState(() => _imageFile = File(image.path));

      CroppedFile? croppedFile = await _cropImage(image.path);

      setState(() => _imageFile = File(croppedFile!.path));

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PrescriptionScreen(imageFile: _imageFile),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a Photo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 20.0,
          children: [
            _imageFile != null
                ? Image.file(_imageFile!, height: 300)
                : const Text('No image captured yet.'),
            ElevatedButton.icon(
              onPressed: () => _pickImage(context, ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Capture from camera'),
            ),
            ElevatedButton.icon(
              onPressed: () => _pickImage(context, ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Pick from gallery'),
            ),
          ],
        ),
      ),
    );
  }
}
