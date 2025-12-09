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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 20.0,
            children: [
              Card(
                child: InkWell(
                  onTap: () {
                    _pickImage(context, ImageSource.camera);
                  },
                  child: const ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 20.0,
                      horizontal: 16.0,
                    ),
                    leading: Icon(Icons.camera_alt),
                    title: Text(
                      'Capture from Camera',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Read prescription image directly from your camera.',
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16.0),
                  ),
                ),
              ),
              Card(
                child: InkWell(
                  onTap: () {
                    _pickImage(context, ImageSource.gallery);
                  },
                  child: const ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 20.0,
                      horizontal: 16.0,
                    ),
                    leading: Icon(Icons.photo_library),
                    title: Text(
                      'Open from Gallery',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Read prescription image from your gallery.',
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16.0),
                  ),
                ),
              ),
              const Text(
                'WARNING: You will be prompted to crop the image you select. '
                'Make sure you crop out personally identifiable information from your image. '
                'By selecting one of the above options, '
                'you consent to your prescription being sent to Google Gemini for OCR and data extraction purposes.',
                style: TextStyle(color: Colors.redAccent, fontSize: 18.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
