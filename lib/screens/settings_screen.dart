import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medisukham/services/permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Example State: This should reflect the current saved preference
  static const String _timeContextSettingsKey = 'time_context_settings';
  static const String _autoCleanUpSettingKey = 'auto_cleanup_settings';
  SharedPreferencesAsync sharedPrefs = SharedPreferencesAsync();

  bool? _isAutoCleanupEnabled = true;

  @override
  void initState() {
    super.initState();
  }

  void _toggleAutoCleanup(bool newValue) {
    setState(() async {
      _isAutoCleanupEnabled = newValue;
      await sharedPrefs.setBool(_autoCleanUpSettingKey, newValue);
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
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
                  PermissionService.instance.ensureExactAlarmPermission(context);
                },
              );
            },
          ),

          // Automatic Cleanup Toggle
          SwitchListTile(
            title: const Text('Automatic Prescription Cleanup'),
            subtitle: const Text('Remove expired medication after treatment days end.'),
            secondary: const Icon(Icons.cleaning_services),
            value: _isAutoCleanupEnabled!,
            onChanged: _toggleAutoCleanup,
          ),

          // Snooze Duration
          ListTile(
            leading: const Icon(Icons.snooze),
            title: const Text('Snooze Duration'),
            subtitle: const Text('Current: 5 minutes'),
            onTap: () {
              // TODO: Implement dialog to change snooze duration
            },
          ),

          const Divider(),

          // SECTION 2: GENERAL & ABOUT
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