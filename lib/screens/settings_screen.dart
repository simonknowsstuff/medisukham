import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medisukham/services/permission_service.dart';
import 'package:medisukham/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  late Future<Map<String, int>> _initialTimingsFuture;

  @override
  void initState() {
    super.initState();
    _initialTimingsFuture = _settingsService.getAllTimings();
  }

  void _toggleAutoCleanup(bool newValue) async {
    await _settingsService.setAutoCleanup(newValue);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open $url')));
      }
    }
  }

  Future<void> _selectAndSaveTime(
    BuildContext context,
    String label,
    TimeOfDay currentTime,
  ) async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (newTime != null) {
      try {
        await _settingsService.updateTiming(label, newTime);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$label time updated to ${newTime.format(context)}',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving time: $e')));
        }
      }
    }
  }

  Widget _buildTimingsList() {
    const List<String> labels = ['Morning', 'Afternoon', 'Evening', 'Night'];

    return ListenableBuilder(
      listenable: SettingsService(),
      builder: (context, child) {
        return Column(
          children: labels.map((label) {
            return FutureBuilder<TimeOfDay>(
              // Using future builder again because the getter is Future-based:
              future: _settingsService.getTiming(label),
              builder: (context, timeSnapshot) {
                if (!timeSnapshot.hasData) {
                  return const LinearProgressIndicator();
                }
                final currentTime = timeSnapshot.data!;

                return ListTile(
                  title: Text('$label Dose'),
                  subtitle: Text(currentTime.format(context)),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _selectAndSaveTime(context, label, currentTime),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: <Widget>[
          // SECTION 1: NOTIFICATION & ALARM SETTINGS
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Notification & Alarm Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.deepOrange,
              ),
            ),
          ),

          // Alarm Permission Status
          FutureBuilder<bool>(
            future: PermissionService.instance.checkExactAlarmPermission(),
            builder: (context, snapshot) {
              final isEnabled = snapshot.data ?? false;
              return ListTile(
                leading: const Icon(Icons.alarm_on),
                title: const Text('Exact Alarm Permission'),
                subtitle: Text(isEnabled ? 'Enabled' : 'Disabled (Tap to fix)'),
                trailing: isEnabled
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.warning, color: Colors.red),
                onTap: () {
                  // Re-request permission or navigate to settings
                  PermissionService.instance.ensureExactAlarmPermission(
                    context,
                  );
                },
              );
            },
          ),
          
          FutureBuilder<bool>(
              future: _settingsService.getAutoCleanup(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LinearProgressIndicator();
                }
                final isEnabled = snapshot.data!;
                
                return SwitchListTile(
                    title: const Text('Automatic Prescription Cleanup'),
                    subtitle: const Text('Remove expired medication after treatment days end.'),
                    secondary: const Icon(Icons.cleaning_services),
                    value: isEnabled,
                    onChanged: _toggleAutoCleanup,
                );
              }
          ),

          const Divider(),

          // SECTION 2: DEFAULT TIMINGS LIST
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Default Dosage Timings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.deepOrange,
              ),
            ),
          ),

          FutureBuilder<Map<String, int>>(
            future: _initialTimingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error loading timings: ${snapshot.error}'));
              }
              return _buildTimingsList();
            }
          ),

          // SECTION 3: GENERAL & ABOUT
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'General & Support',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.deepOrange,
              ),
            ),
          ),

          // Privacy Policy
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchUrl('https://your-app-privacy-policy.com'),
          ),

          // App Version
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'Medisukham',
            applicationVersion: '1.0.0',
            applicationLegalese: '© 2025 Mediteam',
            child: Text('About Medisukham'),
          ),
        ],
      ),
    );
  }
}
