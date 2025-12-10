import 'package:flutter/material.dart';
import 'package:medisukham/models/prescription_node.dart';
import 'package:medisukham/screens/settings_screen.dart';
import 'package:medisukham/services/alarm_persistence_service.dart';
import 'screens/home_screen.dart';
import 'screens/alarms_screen.dart';
import 'widgets/bottom_nav_bar.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medisukham',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  final int initialIndex;
  final List<PrescriptionNode>? nodesToMerge;

  const MainPage({
    super.key,
    this.initialIndex = 0, // Default to home page
    this.nodesToMerge,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _selectedIndex;
  bool _isMerging = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    if (widget.nodesToMerge != null && widget.nodesToMerge!.isNotEmpty) {
      _startInitialMerge(widget.nodesToMerge!);
    }
  }

  void _startInitialMerge(List <PrescriptionNode> newNodes) async {
    setState(() => _isMerging = true);

    try {
      await _handleIncomingMerge(newNodes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during merge: ${e.toString()}')),
        );
      }
    }

    setState(() => _isMerging = false);
  }

  Future<void> _handleIncomingMerge(List<PrescriptionNode> newNodes) async {
    final List<PrescriptionNode> currentNodes = await AlarmPersistenceService.instance.loadPrescriptions();
    final List<PrescriptionNode> mergedList = [...currentNodes, ...newNodes];
    
    await AlarmPersistenceService.instance.savePrescriptions(mergedList);
    await AlarmPersistenceService.instance.scheduleAllReminders(mergedList);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescriptions merged and saved successfully!')),
      );
    }
  }

  void _onTap(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_isMerging) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final List<Widget> barScreens = [
      const HomeScreen(),
      const AlarmScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: barScreens[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onTap,
      ),
    );
  }
}
