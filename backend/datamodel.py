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
    patient_education_id: Optional[str] = None
    patient_summary_id: Optional[str] = None


# Patient Education Models
class MedicineDetail(BaseModel):
    """Details about a single medicine"""
    name: str
    dosage: str
    frequency: str
    instructions: str
    indication: Optional[str] = None
    side_effects: Optional[str] = None
    precautions: Optional[str] = None
    duration: Optional[str] = None


class PatientEducation(BaseModel):
    id: str
    encounter_id: str
    patient_id: str
    doctor_id: str
    title: str
    description: Optional[str] = None
    content: str
    medicines: Optional[List[MedicineDetail]] = None  # Separated medicine information
    medicines_pdf_id: Optional[str] = None  # ID reference to separate medicine PDF
    status: str = "pending"
    sent_at: Optional[str] = None
    viewed_at: Optional[str] = None
    created_at: str
    # Additional fields from joins
    patient_name: Optional[str] = None
    patient_age: Optional[int] = None
    patient_gender: Optional[str] = None
    encounter_diagnosis: Optional[str] = None
    encounter_chief_complaint: Optional[str] = None
    visit_number: Optional[int] = None


class PatientEducationListResponse(BaseModel):
    education_list: List[PatientEducation]
    total: int


class UpdateEducationRequest(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    content: Optional[str] = None
    status: Optional[str] = None


class UpdateEducationResponse(BaseModel):
    success: bool
    message: str


class MedicinePDFResponse(BaseModel):
    """Response for medicine PDF download endpoints"""
    success: bool
    filename: str
    pdf_base64: Optional[str] = None  # Base64 encoded PDF for transmission
    message: str


class GenerateMedicinePDFRequest(BaseModel):
    """Request to generate medicine PDF"""
    encounter_id: str
    patient_name: str = "Patient"
    doctor_name: str = "Your Doctor"


# Patient Summary Models
class PatientSummary(BaseModel):
    id: str
    encounter_id: str
    patient_id: str
    doctor_id: str
    summary_text: str
    key_findings: Optional[str] = None
    important_changes: Optional[str] = None
    follow_up_notes: Optional[str] = None
    created_at: str
    updated_at: str
    # Additional fields from joins
    patient_name: Optional[str] = None
    encounter_diagnosis: Optional[str] = None
    visit_number: Optional[int] = None


class PatientSummaryListResponse(BaseModel):
    summaries: List[PatientSummary]
    total: int


# X-ray Analysis Models
class XrayAnalysisRequest(BaseModel):
    image_base64: str
    image_type: Literal["X-Ray", "Lab Notes"]
    body_region: Literal["chest", "head", "spine", "limb", "abdomen", "pelvis", "other"]
    patient_context: Optional[str] = None


class SpecialistFinding(BaseModel):
    title: str
    description: str
    severity: Literal["High", "Medium", "Low"]
    is_red_flag: bool = False


class SpecialistAnalysis(BaseModel):
    specialist: Literal["Cardiologist", "Neurologist", "Orthopedist"]
    has_findings: bool
    findings: List[SpecialistFinding]
    overlooked_warnings: List[str]
    recommended_actions: List[str]


class XrayAnalysisResponse(BaseModel):
    analyses: List[SpecialistAnalysis]
    primary_specialist: Optional[str] = None
    overall_summary: str
