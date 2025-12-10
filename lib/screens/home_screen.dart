import 'package:flutter/material.dart';
import 'package:medisukham/screens/camera_screen.dart';
import 'package:medisukham/screens/prescription_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              CameraCard(),
              SizedBox(height: 20.0),
              CreateManualCard(),
            ],
          ),
        ),
      ),
    );
  }
}

// Camera card:
class CameraCard extends StatelessWidget {
  const CameraCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CameraScreen()),
          );
        },
        // ListTile provides the standard layout for an item in a list
        child: const ListTile(
          contentPadding: EdgeInsets.symmetric(
            vertical: 20.0,
            horizontal: 16.0,
          ),
          leading: Icon(
            Icons.camera_alt_rounded,
            size: 40.0,
            color: Colors.deepOrange,
          ),
          title: Text(
            'Scan New Prescription',
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
          subtitle: Text('Capture an image of your prescription.'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16.0),
        ),
      ),
    );
  }
}

// Create prescription manually card:
class CreateManualCard extends StatelessWidget {
  const CreateManualCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PrescriptionScreen(imageFile: null),
            ),
          );
        },
        child: const ListTile(
          contentPadding: EdgeInsets.symmetric(
            vertical: 20.0,
            horizontal: 16.0,
          ),
          leading: Icon(Icons.create, size: 40.0, color: Colors.deepOrange),
          title: Text(
            'Enter Manually',
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
          subtitle: Text('Create a prescription entry from scratch.'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16.0),
        ),
      ),
    );
  }
}
