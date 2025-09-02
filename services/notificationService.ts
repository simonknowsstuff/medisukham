import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';
import { Prescription } from '../types/prescription';

// Configure notification handler
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});

export class NotificationService {
  static async requestPermissions(): Promise<boolean> {
    if (Platform.OS === 'web') {
      return true; // Web doesn't need permissions for demo
    }

    const { status: existingStatus } = await Notifications.getPermissionsAsync();
    let finalStatus = existingStatus;

    if (existingStatus !== 'granted') {
      const { status } = await Notifications.requestPermissionsAsync();
      finalStatus = status;
    }

    return finalStatus === 'granted';
  }

  static async scheduleAlarm(prescription: Prescription): Promise<void> {
    if (Platform.OS === 'web') {
      // For web demo, just show console log
      console.log(`Alarm scheduled for ${prescription.medicationName}`);
      return;
    }

    // Cancel existing notifications for this prescription
    await this.cancelAlarms(prescription.id);

    // Schedule new alarms for each time
    for (const timeString of prescription.alarmTimes) {
      const [hours, minutes] = timeString.split(':').map(Number);
      
      await Notifications.scheduleNotificationAsync({
        content: {
          title: 'Medication Reminder',
          body: `Time to take ${prescription.medicationName} - ${prescription.dosage}`,
          data: { prescriptionId: prescription.id },
        },
        trigger: {
          hour: hours,
          minute: minutes,
          repeats: true,
        },
      });
    }
  }

  static async cancelAlarms(prescriptionId: string): Promise<void> {
    if (Platform.OS === 'web') return;

    const scheduledNotifications = await Notifications.getAllScheduledNotificationsAsync();
    
    for (const notification of scheduledNotifications) {
      if (notification.content.data?.prescriptionId === prescriptionId) {
        await Notifications.cancelScheduledNotificationAsync(notification.identifier);
      }
    }
  }

  static async cancelAllAlarms(): Promise<void> {
    if (Platform.OS === 'web') return;
    await Notifications.cancelAllScheduledNotificationsAsync();
  }
}