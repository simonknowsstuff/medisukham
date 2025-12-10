import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._internal();
  static final PermissionService instance = PermissionService._internal();

  Future<bool> checkExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;

    if (status.isGranted) {
      return true;
    }
    return false;
  }

  Future<bool> ensureExactAlarmPermission(BuildContext context) async {
    if (await checkExactAlarmPermission()) {
      return true;
    }

    // If not granted, request permission
    final result = await Permission.scheduleExactAlarm.request();

    if (result.isGranted) {
      return true;
    }

    // Otherwise, just ask the user to set it manually
    if (result.isPermanentlyDenied) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Medication alarms need exact scheduling permission. Please enable it in Settings.',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
            duration: const Duration(seconds: 8),
          ),
        );
      }
      return false;
    }

    return false;
  }
}
