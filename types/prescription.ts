export interface Prescription {
  id: string;
  photoUri: string;
  medicationName: string;
  dosage: string;
  frequency: string;
  startDate: string;
  endDate: string;
  instructions: string;
  alarmTimes: string[];
  createdAt: string;
}

export interface AlarmSchedule {
  id: string;
  prescriptionId: string;
  time: string;
  isActive: boolean;
}