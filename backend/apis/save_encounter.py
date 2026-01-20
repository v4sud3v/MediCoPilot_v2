from fastapi import APIRouter, HTTPException
from supabase import create_client, Client
from datamodel import SaveEncounterRequest, SaveEncounterResponse
import os
from dotenv import load_dotenv
import uuid

load_dotenv()

router = APIRouter(prefix="/encounter", tags=["Encounter"])

# Initialize Supabase client
supabase: Client = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_SECRET_KEY")
)


@router.post("/save", response_model=SaveEncounterResponse)
async def save_encounter(request: SaveEncounterRequest) -> SaveEncounterResponse:
    """
    Save a new patient encounter to the database.
    
    Steps:
    1. Check if patient exists (by name and doctor_id)
    2. If not, create new patient
    3. Generate case_id (first visit) or use existing case_id
    4. Create encounter record with visit_number
    5. Return encounter details
    """
    
    try:
        # Step 1: Check if patient exists for this doctor
        existing_patient = supabase.table('patients').select('*').eq(
            'name', request.patient.name
        ).eq('doctor_id', request.doctor_id).execute()
        
        patient_id = None
        case_id = None
        visit_number = 1
        
        if existing_patient.data and len(existing_patient.data) > 0:
            # Patient exists - this is a follow-up visit
            patient_id = existing_patient.data[0]['id']
            
            # Get the latest encounter for this patient to determine case_id and visit_number
            latest_encounter = supabase.table('encounters').select(
                'case_id, visit_number'
            ).eq('patient_id', patient_id).order(
                'visit_number', desc=True
            ).limit(1).execute()
            
            if latest_encounter.data and len(latest_encounter.data) > 0:
                # Continuing existing case
                case_id = latest_encounter.data[0]['case_id']
                visit_number = latest_encounter.data[0]['visit_number'] + 1
            else:
                # First encounter for existing patient
                case_id = str(uuid.uuid4())
                visit_number = 1
        else:
            # Step 2: Create new patient
            new_patient_data = {
                'doctor_id': request.doctor_id,
                'name': request.patient.name,
                'age': request.patient.age,
                'gender': request.patient.gender,
                'allergies': request.patient.allergies,
                'contact_info': request.patient.contact_info,
            }
            
            patient_result = supabase.table('patients').insert(
                new_patient_data
            ).execute()
            
            if not patient_result.data:
                raise HTTPException(status_code=500, detail="Failed to create patient")
            
            patient_id = patient_result.data[0]['id']
            case_id = str(uuid.uuid4())  # New case for new patient
            visit_number = 1
        
        # Step 3: Create encounter record
        encounter_data = {
            'patient_id': patient_id,
            'doctor_id': request.doctor_id,
            'case_id': case_id,
            'visit_number': visit_number,
            'chief_complaint': request.chief_complaint,
            'history_of_illness': request.history_of_illness,
            'temperature': request.vital_signs.temperature,
            'blood_pressure': request.vital_signs.blood_pressure,
            'heart_rate': int(request.vital_signs.heart_rate) if request.vital_signs.heart_rate else None,
            'respiratory_rate': int(request.vital_signs.respiratory_rate) if request.vital_signs.respiratory_rate else None,
            'oxygen_saturation': int(request.vital_signs.oxygen_saturation) if request.vital_signs.oxygen_saturation else None,
            'weight': request.vital_signs.weight,
            'height': request.vital_signs.height,
            'physical_exam': request.physical_exam,
            'diagnosis': request.diagnosis,
        }
        
        encounter_result = supabase.table('encounters').insert(
            encounter_data
        ).execute()
        
        if not encounter_result.data:
            raise HTTPException(status_code=500, detail="Failed to create encounter")
        
        encounter_id = encounter_result.data[0]['id']
        
        return SaveEncounterResponse(
            success=True,
            encounter_id=encounter_id,
            patient_id=patient_id,
            case_id=case_id,
            visit_number=visit_number,
            message=f"Encounter saved successfully (Visit #{visit_number})"
        )
        
    except Exception as e:
        print(f"Error saving encounter: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to save encounter: {str(e)}")
