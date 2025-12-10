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
            spacing: 25.0,
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
                    leading: Icon(Icons.camera_alt, size: 36.0),
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
                    leading: Icon(Icons.photo_library, size: 36.0),
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
              const PrivacyWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

class PrivacyWidget extends StatelessWidget {
  const PrivacyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.redAccent.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.privacy_tip_outlined, color: Colors.redAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Important Privacy Notice',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'You will be prompted to crop the image you select. '
                    'Please remove any personally identifiable information.\n\n'
                    'By selecting one of the above options, you consent to your '
                    'prescription being sent to Google Gemini for OCR and data extraction.',
                    style: TextStyle(
                      fontSize: 15.5,
                      height: 1.4,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
