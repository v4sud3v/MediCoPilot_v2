from pydantic import BaseModel
from typing import Optional, List, Literal
from uuid import UUID


class VitalSigns(BaseModel):
    temperature: Optional[float] = None
    blood_pressure: Optional[str] = None
    heart_rate: Optional[float] = None
    respiratory_rate: Optional[float] = None
    oxygen_saturation: Optional[float] = None
    weight: Optional[float] = None
    height: Optional[float] = None


class AnalyzeEncounterRequest(BaseModel):
    diagnosis: str
    patient_id: str
    symptoms: str
    vital_signs: VitalSigns
    examination_findings: Optional[str] = None
    medications: Optional[str] = None


class MissedDiagnosis(BaseModel):
    title: str
    description: str
    confidence: Literal["High", "Medium", "Low"]


class PotentialIssue(BaseModel):
    title: str
    description: str
    severity: Literal["High", "Medium", "Low"]


class RecommendedTest(BaseModel):
    title: str
    description: str
    priority: Literal["High", "Medium", "Low"]


class AnalyzeEncounterResponse(BaseModel):
    missedDiagnoses: List[MissedDiagnosis]
    potentialIssues: List[PotentialIssue]
    recommendedTests: List[RecommendedTest]


# Save Encounter Models
class SaveEncounterRequest(BaseModel):
    patient_id: str  # UUID of the existing patient
    case_id: Optional[str] = None  # If provided, creates follow-up; if None, creates new encounter
    chief_complaint: Optional[str] = None
    history_of_illness: Optional[str] = None
    vital_signs: VitalSigns
    physical_exam: Optional[str] = None
    diagnosis: Optional[str] = None
    medications: Optional[str] = None
    doctor_id: str  # UUID of the logged-in doctor


class SaveEncounterResponse(BaseModel):
    success: bool
    encounter_id: str
    patient_id: str
    case_id: str
    visit_number: int
    message: str
