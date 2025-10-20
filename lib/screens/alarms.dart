import 'package:flutter/material.dart';

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("Alarm Screen!",),
      ),
      appBar: AppBar(
        title: Text('Alarms',),
      ),
    );
  }
}