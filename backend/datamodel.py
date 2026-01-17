from pydantic import BaseModel
from typing import Optional, List, Literal


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
