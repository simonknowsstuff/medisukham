import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  Alert,
  SafeAreaView,
  Platform,
  Image,
} from 'react-native';
import { Trash2, Clock, Bell, BellOff } from 'lucide-react-native';
import { StorageService } from '../../services/storageService';
import { NotificationService } from '../../services/notificationService';
import { Prescription } from '../../types/prescription';

export default function PrescriptionsTab() {
  const [prescriptions, setPrescriptions] = useState<Prescription[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadPrescriptions();
    requestNotificationPermissions();
  }, []);

  const requestNotificationPermissions = async () => {
    await NotificationService.requestPermissions();
  };

  const loadPrescriptions = async () => {
    try {
      const savedPrescriptions = await StorageService.getAllPrescriptions();
      setPrescriptions(savedPrescriptions);
    } catch (error) {
      console.error('Error loading prescriptions:', error);
      Alert.alert('Error', 'Failed to load prescriptions');
    } finally {
      setIsLoading(false);
    }
  };

  const deletePrescription = async (prescription: Prescription) => {
    Alert.alert(
      'Delete Prescription',
      `Are you sure you want to delete ${prescription.medicationName}?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              await NotificationService.cancelAlarms(prescription.id);
              await StorageService.deletePrescription(prescription.id);
              await loadPrescriptions();
            } catch (error) {
              Alert.alert('Error', 'Failed to delete prescription');
            }
          },
        },
      ]
    );
  };

  const toggleAlarms = async (prescription: Prescription) => {
    try {
      if (prescription.alarmTimes.length > 0) {
        // Cancel alarms
        await NotificationService.cancelAlarms(prescription.id);
        
        const updatedPrescription = {
          ...prescription,
          alarmTimes: [],
        };
        
        await StorageService.updatePrescription(updatedPrescription);
        await loadPrescriptions();
        
        Alert.alert('Success', 'Medication alarms have been disabled');
      } else {
        // Re-enable alarms (for demo, set default times)
        const defaultTimes = ['08:00', '14:00', '20:00'];
        
        const updatedPrescription = {
          ...prescription,
          alarmTimes: defaultTimes,
        };
        
        await NotificationService.scheduleAlarm(updatedPrescription);
        await StorageService.updatePrescription(updatedPrescription);
        await loadPrescriptions();
        
        Alert.alert('Success', 'Medication alarms have been enabled');
      }
    } catch (error) {
      Alert.alert('Error', 'Failed to update alarms');
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString();
  };

  if (isLoading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.loadingContainer}>
          <Text style={styles.loadingText}>Loading prescriptions...</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>My Prescriptions</Text>
        <Text style={styles.headerSubtitle}>
          {prescriptions.length} medication{prescriptions.length !== 1 ? 's' : ''}
        </Text>
      </View>

      {prescriptions.length === 0 ? (
        <View style={styles.emptyContainer}>
          <Clock size={64} color="#D1D5DB" strokeWidth={1.5} />
          <Text style={styles.emptyTitle}>No Prescriptions Yet</Text>
          <Text style={styles.emptyText}>
            Use the camera tab to capture your first prescription photo
          </Text>
        </View>
      ) : (
        <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
          {prescriptions.map((prescription) => (
            <View key={prescription.id} style={styles.prescriptionCard}>
              <View style={styles.cardHeader}>
                <Image source={{ uri: prescription.photoUri }} style={styles.prescriptionImage} />
                <View style={styles.cardInfo}>
                  <Text style={styles.medicationName}>{prescription.medicationName}</Text>
                  <Text style={styles.dosage}>{prescription.dosage}</Text>
                  <Text style={styles.frequency}>{prescription.frequency}</Text>
                </View>
              </View>

              <View style={styles.cardDetails}>
                <Text style={styles.instructions}>{prescription.instructions}</Text>
                
                <View style={styles.dateRow}>
                  <Text style={styles.dateLabel}>Start:</Text>
                  <Text style={styles.dateValue}>{formatDate(prescription.startDate)}</Text>
                  <Text style={styles.dateLabel}>End:</Text>
                  <Text style={styles.dateValue}>{formatDate(prescription.endDate)}</Text>
                </View>

                {prescription.alarmTimes.length > 0 && (
                  <View style={styles.alarmTimes}>
                    <Text style={styles.alarmLabel}>Reminders:</Text>
                    <Text style={styles.alarmValue}>
                      {prescription.alarmTimes.join(', ')}
                    </Text>
                  </View>
                )}
              </View>

              <View style={styles.cardActions}>
                <TouchableOpacity
                  style={[
                    styles.actionButton,
                    prescription.alarmTimes.length > 0 
                      ? styles.alarmActiveButton 
                      : styles.alarmInactiveButton
                  ]}
                  onPress={() => toggleAlarms(prescription)}
                >
                  {prescription.alarmTimes.length > 0 ? (
                    <BellOff size={18} color="#FFFFFF" strokeWidth={2} />
                  ) : (
                    <Bell size={18} color="#059669" strokeWidth={2} />
                  )}
                  <Text style={[
                    styles.actionButtonText,
                    prescription.alarmTimes.length > 0 
                      ? styles.alarmActiveText 
                      : styles.alarmInactiveText
                  ]}>
                    {prescription.alarmTimes.length > 0 ? 'Disable' : 'Enable'} Alarms
                  </Text>
                </TouchableOpacity>

                <TouchableOpacity
                  style={styles.deleteButton}
                  onPress={() => deletePrescription(prescription)}
                >
                  <Trash2 size={18} color="#DC2626" strokeWidth={2} />
                </TouchableOpacity>
              </View>
            </View>
          ))}
        </ScrollView>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F9FAFB',
  },
  header: {
    backgroundColor: '#FFFFFF',
    paddingHorizontal: 24,
    paddingVertical: 20,
    paddingTop: Platform.OS === 'ios' ? 60 : 40,
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: '700',
    color: '#111827',
    marginBottom: 4,
  },
  headerSubtitle: {
    fontSize: 16,
    color: '#6B7280',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    fontSize: 16,
    color: '#6B7280',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 32,
  },
  emptyTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#374151',
    marginTop: 16,
    marginBottom: 8,
  },
  emptyText: {
    fontSize: 16,
    color: '#6B7280',
    textAlign: 'center',
    lineHeight: 24,
  },
  scrollView: {
    flex: 1,
    paddingHorizontal: 16,
    paddingTop: 16,
  },
  prescriptionCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    marginBottom: 16,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  cardHeader: {
    flexDirection: 'row',
    marginBottom: 12,
  },
  prescriptionImage: {
    width: 80,
    height: 60,
    borderRadius: 8,
    backgroundColor: '#F3F4F6',
  },
  cardInfo: {
    flex: 1,
    marginLeft: 12,
  },
  medicationName: {
    fontSize: 18,
    fontWeight: '700',
    color: '#111827',
    marginBottom: 4,
  },
  dosage: {
    fontSize: 14,
    color: '#2563EB',
    fontWeight: '600',
    marginBottom: 2,
  },
  frequency: {
    fontSize: 14,
    color: '#6B7280',
  },
  cardDetails: {
    marginBottom: 16,
  },
  instructions: {
    fontSize: 14,
    color: '#374151',
    lineHeight: 20,
    marginBottom: 12,
  },
  dateRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  dateLabel: {
    fontSize: 12,
    color: '#6B7280',
    fontWeight: '600',
    marginRight: 8,
  },
  dateValue: {
    fontSize: 12,
    color: '#374151',
    marginRight: 16,
  },
  alarmTimes: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  alarmLabel: {
    fontSize: 12,
    color: '#6B7280',
    fontWeight: '600',
    marginRight: 8,
  },
  alarmValue: {
    fontSize: 12,
    color: '#059669',
    fontWeight: '600',
  },
  cardActions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 8,
    flex: 1,
    marginRight: 12,
  },
  alarmActiveButton: {
    backgroundColor: '#DC2626',
  },
  alarmInactiveButton: {
    backgroundColor: '#F3F4F6',
    borderWidth: 1,
    borderColor: '#059669',
  },
  actionButtonText: {
    fontSize: 14,
    fontWeight: '600',
    marginLeft: 6,
  },
  alarmActiveText: {
    color: '#FFFFFF',
  },
  alarmInactiveText: {
    color: '#059669',
  },
  deleteButton: {
    width: 40,
    height: 40,
    borderRadius: 8,
    backgroundColor: '#FEF2F2',
    justifyContent: 'center',
    alignItems: 'center',
  },
});