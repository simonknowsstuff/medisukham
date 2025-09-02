import AsyncStorage from '@react-native-async-storage/async-storage';
import { Prescription } from '../types/prescription';

const PRESCRIPTIONS_KEY = 'prescriptions';

export class StorageService {
  static async savePrescription(prescription: Prescription): Promise<void> {
    try {
      const existingPrescriptions = await this.getAllPrescriptions();
      const updatedPrescriptions = [...existingPrescriptions, prescription];
      await AsyncStorage.setItem(PRESCRIPTIONS_KEY, JSON.stringify(updatedPrescriptions));
    } catch (error) {
      console.error('Error saving prescription:', error);
      throw error;
    }
  }

  static async getAllPrescriptions(): Promise<Prescription[]> {
    try {
      const prescriptionsJson = await AsyncStorage.getItem(PRESCRIPTIONS_KEY);
      return prescriptionsJson ? JSON.parse(prescriptionsJson) : [];
    } catch (error) {
      console.error('Error loading prescriptions:', error);
      return [];
    }
  }

  static async deletePrescription(id: string): Promise<void> {
    try {
      const prescriptions = await this.getAllPrescriptions();
      const filteredPrescriptions = prescriptions.filter(p => p.id !== id);
      await AsyncStorage.setItem(PRESCRIPTIONS_KEY, JSON.stringify(filteredPrescriptions));
    } catch (error) {
      console.error('Error deleting prescription:', error);
      throw error;
    }
  }

  static async updatePrescription(updatedPrescription: Prescription): Promise<void> {
    try {
      const prescriptions = await this.getAllPrescriptions();
      const index = prescriptions.findIndex(p => p.id === updatedPrescription.id);
      
      if (index !== -1) {
        prescriptions[index] = updatedPrescription;
        await AsyncStorage.setItem(PRESCRIPTIONS_KEY, JSON.stringify(prescriptions));
      }
    } catch (error) {
      console.error('Error updating prescription:', error);
      throw error;
    }
  }
}