import 'package:flutter/material.dart';
import 'package:medisukham/screens/camera.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 250,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 20.0,
            children: [
              CameraCard(),
              CreateManualCard(),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Text('Home',),
      ),
    );
  }
}

class CreateManualCard extends StatelessWidget {
  const CreateManualCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: () {},
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0,),
          child: Column(
            children: [
              Icon(
                Icons.create,
                size: 80,
              ),
              Text(
                'Enter manually',
                style: TextStyle(fontSize: 20.0,),
              ),
            ],
          )
        )
      )
    );
  }
}

class CameraCard extends StatelessWidget {
  const CameraCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CameraScreen()),
        );
      },
      child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32.0,),
            child: Column(
              children: [
                Icon(
                  Icons.camera_alt_rounded,
                  size: 80,
                ),
                Text(
                  'Scan prescription',
                  style: TextStyle(fontSize: 20.0,),
                ),
              ],
            ),
          )
      ),
    );
  }
}