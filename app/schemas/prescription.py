from pydantic import BaseModel
from typing import List

class MedicineData(BaseModel):
    medicine: str
    dosage: str
    times_per_day: str

class PrescriptionResponse(BaseModel):
    items: List[MedicineData]