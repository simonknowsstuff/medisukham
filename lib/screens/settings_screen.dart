import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medisukham/services/permission_service.dart';
import 'package:medisukham/services/settings_service.dart';
import 'package:alarm/alarm.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final int alarmTestID = 9999;

  @override
  void initState() {
    super.initState();
  }

  void _toggleAutoCleanup(bool newValue) async {
    await _settingsService.setAutoCleanup(newValue);
  }

  void _toggleVibrate(bool newValue) async {
    await _settingsService.setVibrate(newValue);
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
      listenable: _settingsService,
      builder: (context, child) {
        return Column(
          children: labels.map((label) {
            final TimeOfDay currentTime = _settingsService.getTiming(label);

            return ListTile(
              title: Text('$label Dose'),
              subtitle: Text(currentTime.format(context)),
              trailing: const Icon(Icons.edit, size: 20),
              onTap: () => _selectAndSaveTime(context, label, currentTime),
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
      body: ListenableBuilder(
        listenable: _settingsService,
        builder: (context, _) {
          return ListView(
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
                      PermissionService.instance.ensureExactAlarmPermission(context);
                    },
                  );
                },
              ),

              // Auto-Cleanup Switch
              SwitchListTile(
                title: const Text('Automatic Prescription Cleanup'),
                subtitle: const Text(
                  'Remove expired medication after treatment days end.',
                ),
                secondary: const Icon(Icons.cleaning_services),
                value: _settingsService.getAutoCleanup(),
                onChanged: _toggleAutoCleanup,
              ),

              // Alarm Volume Slider
              ListTile(
                leading: Icon(
                  _settingsService.getVolume() == 0
                      ? Icons.volume_off
                      : _settingsService.getVolume() < 0.5
                          ? Icons.volume_down
                          : Icons.volume_up,
                ),
                title: const Text('Alarm Volume'),
                subtitle: Slider(
                  value: _settingsService.getVolume(),
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: '${(_settingsService.getVolume() * 100).round()}%',
                  onChanged: (double newValue) async {
                    await _settingsService.setVolume(newValue);
                  },
                ),
              ),

              // Vibrate Switch
              SwitchListTile(
                title: const Text('Vibrate'),
                subtitle: const Text('Vibrate device when alarm rings.'),
                secondary: const Icon(Icons.vibration),
                value: _settingsService.getVibrate(),
                onChanged: _toggleVibrate,
              ),

              // Alarm Tester
              ListTile(
                leading: const Icon(Icons.play_circle_fill),
                title: const Text('Test Alarm'),
                subtitle: const Text('Play a 5-second sample at current volume'),
                onTap: () async {
                  final volume = _settingsService.getVolume();
                  final hasVibrate = _settingsService.getVibrate();

                  final alarmSettings = AlarmSettings(
                    id: alarmTestID,
                    dateTime: DateTime.now().add(const Duration(seconds: 1)),
                    assetAudioPath: 'assets/alarm.wav',
                    loopAudio: false,
                    vibrate: hasVibrate,
                    volumeSettings: VolumeSettings.fixed(
                      volume: volume,
                      volumeEnforced: true,
                    ),
                    androidFullScreenIntent: false,
                    notificationSettings: NotificationSettings(
                      title: 'Test Alarm',
                      body: 'Testing your medication reminder sound.',
                      stopButton: 'Stop the alarm',
                    ),
                    warningNotificationOnKill: true,
                  );

                  try {
                    await Alarm.set(alarmSettings: alarmSettings);
                    if (kDebugMode) {
                      print('Test alarm triggered!');
                    }
                  } catch (e) {
                    if (kDebugMode) {
                      print('Error triggering alarm: $e');
                    }
                    rethrow;
                  }

                  // Automatically dismiss alarm
                  Future.delayed(const Duration(seconds: 5), () {
                    Alarm.stop(alarmTestID);
                  });
                },
              ),

              // Alarm Troubleshoot Help
              ListTile(
                leading: const Icon(Icons.alarm),
                title: const Text('Troubleshoot'),
                subtitle: const Text('Troubleshoot alarms.'),
                onTap: () async {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Alert'),
                        content: const SingleChildScrollView(
                          child: ListBody(
                            children: <Text>[
                              Text(
                                'If you do not hear any alarms, ensure you have proper alarm permissions granted.',
                              ),
                              Text(
                                'If no alarms are triggered in the specified dosage times while the app is closed, '
                                'ensure you have battery optimisations disabled for this app '
                                '(Refer https://dontkillmyapp.com/)',
                              ),
                            ],
                          ),
                        ),
                        actions: <TextButton>[
                          TextButton(
                            child: const Text('Grant alarm permissions'),
                            onPressed: () {
                              PermissionService.instance.ensureExactAlarmPermission(
                                context,
                              );
                            },
                          ),
                          TextButton(
                            child: const Text('Ignore battery optimisation'),
                            onPressed: () {
                              PermissionService.instance
                                  .ensureBatteryExemptionPermission(context);
                            },
                          ),
                          TextButton(
                            child: const Text('Close'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
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

              _buildTimingsList(),

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
          );
        },
      ),
    );
  }
}