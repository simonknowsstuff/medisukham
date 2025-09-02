import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Alert,
  SafeAreaView,
  ScrollView,
  Image,
  Platform,
} from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { ArrowLeft, Save, Plus, X } from 'lucide-react-native';
import { StorageService } from '../services/storageService';
import { NotificationService } from '../services/notificationService';
import { Prescription } from '../types/prescription';

export default function PrescriptionForm() {
  const { photoUri } = useLocalSearchParams<{ photoUri: string }>();
  
  const [medicationName, setMedicationName] = useState('');
  const [dosage, setDosage] = useState('');
  const [frequency, setFrequency] = useState('');
  const [startDate, setStartDate] = useState(new Date().toISOString().split('T')[0]);
  const [endDate, setEndDate] = useState('');
  const [instructions, setInstructions] = useState('');
  const [alarmTimes, setAlarmTimes] = useState<string[]>(['08:00']);
  const [isSaving, setIsSaving] = useState(false);

  const addAlarmTime = () => {
    if (alarmTimes.length < 6) {
      setAlarmTimes([...alarmTimes, '12:00']);
    }
  };

  const removeAlarmTime = (index: number) => {
    if (alarmTimes.length > 1) {
      setAlarmTimes(alarmTimes.filter((_, i) => i !== index));
    }
  };

  const updateAlarmTime = (index: number, time: string) => {
    const newTimes = [...alarmTimes];
    newTimes[index] = time;
    setAlarmTimes(newTimes);
  };

  const savePrescription = async () => {
    if (!medicationName.trim() || !dosage.trim()) {
      Alert.alert('Error', 'Please fill in medication name and dosage');
      return;
    }

    setIsSaving(true);

    try {
      const prescription: Prescription = {
        id: Date.now().toString(),
        photoUri: photoUri || '',
        medicationName: medicationName.trim(),
        dosage: dosage.trim(),
        frequency: frequency.trim(),
        startDate,
        endDate,
        instructions: instructions.trim(),
        alarmTimes,
        createdAt: new Date().toISOString(),
      };

      await StorageService.savePrescription(prescription);
      await NotificationService.scheduleAlarm(prescription);

      Alert.alert(
        'Success',
        'Prescription saved and alarms scheduled!',
        [
          {
            text: 'OK',
            onPress: () => router.replace('/(tabs)/prescriptions'),
          },
        ]
      );
    } catch (error) {
      console.error('Error saving prescription:', error);
      Alert.alert('Error', 'Failed to save prescription');
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity 
          style={styles.backButton} 
          onPress={() => router.back()}
        >
          <ArrowLeft size={24} color="#374151" strokeWidth={2} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Add Prescription</Text>
        <View style={styles.placeholder} />
      </View>

      <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
        {photoUri && (
          <View style={styles.photoContainer}>
            <Image source={{ uri: photoUri }} style={styles.photo} />
          </View>
        )}

        <View style={styles.form}>
          <View style={styles.inputGroup}>
            <Text style={styles.label}>Medication Name *</Text>
            <TextInput
              style={styles.input}
              value={medicationName}
              onChangeText={setMedicationName}
              placeholder="e.g., Ibuprofen"
              placeholderTextColor="#9CA3AF"
            />
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>Dosage *</Text>
            <TextInput
              style={styles.input}
              value={dosage}
              onChangeText={setDosage}
              placeholder="e.g., 200mg"
              placeholderTextColor="#9CA3AF"
            />
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>Frequency</Text>
            <TextInput
              style={styles.input}
              value={frequency}
              onChangeText={setFrequency}
              placeholder="e.g., 3 times daily"
              placeholderTextColor="#9CA3AF"
            />
          </View>

          <View style={styles.dateRow}>
            <View style={[styles.inputGroup, styles.dateInput]}>
              <Text style={styles.label}>Start Date</Text>
              <TextInput
                style={styles.input}
                value={startDate}
                onChangeText={setStartDate}
                placeholder="YYYY-MM-DD"
                placeholderTextColor="#9CA3AF"
              />
            </View>

            <View style={[styles.inputGroup, styles.dateInput]}>
              <Text style={styles.label}>End Date</Text>
              <TextInput
                style={styles.input}
                value={endDate}
                onChangeText={setEndDate}
                placeholder="YYYY-MM-DD"
                placeholderTextColor="#9CA3AF"
              />
            </View>
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>Instructions</Text>
            <TextInput
              style={[styles.input, styles.textArea]}
              value={instructions}
              onChangeText={setInstructions}
              placeholder="e.g., Take with food"
              placeholderTextColor="#9CA3AF"
              multiline
              numberOfLines={3}
            />
          </View>

          <View style={styles.inputGroup}>
            <View style={styles.alarmHeader}>
              <Text style={styles.label}>Reminder Times</Text>
              <TouchableOpacity style={styles.addButton} onPress={addAlarmTime}>
                <Plus size={16} color="#2563EB" strokeWidth={2} />
              </TouchableOpacity>
            </View>

            {alarmTimes.map((time, index) => (
              <View key={index} style={styles.alarmRow}>
                <TextInput
                  style={[styles.input, styles.timeInput]}
                  value={time}
                  onChangeText={(text) => updateAlarmTime(index, text)}
                  placeholder="HH:MM"
                  placeholderTextColor="#9CA3AF"
                />
                {alarmTimes.length > 1 && (
                  <TouchableOpacity
                    style={styles.removeButton}
                    onPress={() => removeAlarmTime(index)}
                  >
                    <X size={16} color="#DC2626" strokeWidth={2} />
                  </TouchableOpacity>
                )}
              </View>
            ))}
          </View>
        </View>
      </ScrollView>

      <View style={styles.footer}>
        <TouchableOpacity
          style={[styles.saveButton, isSaving && styles.saveButtonDisabled]}
          onPress={savePrescription}
          disabled={isSaving}
        >
          <Save size={20} color="#FFFFFF" strokeWidth={2} />
          <Text style={styles.saveButtonText}>
            {isSaving ? 'Saving...' : 'Save Prescription'}
          </Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F9FAFB',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#FFFFFF',
    paddingHorizontal: 16,
    paddingVertical: 12,
    paddingTop: Platform.OS === 'ios' ? 60 : 40,
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 8,
    backgroundColor: '#F3F4F6',
    justifyContent: 'center',
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#111827',
  },
  placeholder: {
    width: 40,
  },
  photoContainer: {
    alignItems: 'center',
    paddingVertical: 20,
  },
  photo: {
    width: 200,
    height: 150,
    borderRadius: 12,
    backgroundColor: '#F3F4F6',
  },
  scrollView: {
    flex: 1,
  },
  form: {
    padding: 16,
  },
  inputGroup: {
    marginBottom: 20,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: '#374151',
    marginBottom: 6,
  },
  input: {
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#D1D5DB',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 12,
    fontSize: 16,
    color: '#111827',
  },
  textArea: {
    height: 80,
    textAlignVertical: 'top',
  },
  dateRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  dateInput: {
    flex: 1,
    marginHorizontal: 4,
  },
  alarmHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  addButton: {
    width: 32,
    height: 32,
    borderRadius: 6,
    backgroundColor: '#EBF4FF',
    justifyContent: 'center',
    alignItems: 'center',
  },
  alarmRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  timeInput: {
    flex: 1,
    marginRight: 8,
  },
  removeButton: {
    width: 32,
    height: 32,
    borderRadius: 6,
    backgroundColor: '#FEF2F2',
    justifyContent: 'center',
    alignItems: 'center',
  },
  footer: {
    backgroundColor: '#FFFFFF',
    paddingHorizontal: 16,
    paddingVertical: 16,
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
  },
  saveButton: {
    backgroundColor: '#2563EB',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
    borderRadius: 12,
  },
  saveButtonDisabled: {
    backgroundColor: '#9CA3AF',
  },
  saveButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
    marginLeft: 8,
  },
});