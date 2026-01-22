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
    
    Modes:
    - New Encounter: case_id NOT provided → generate new case_id, visit_number = 1
    - Follow-up: case_id provided → use existing case_id, auto-increment visit_number
    
    Steps:
    1. Fetch existing patient by patient_id
    2. Determine case_id and visit_number based on mode
    3. If follow-up, inherit history_of_illness from parent encounter
    4. Create encounter record with appropriate visit_number
    5. Return encounter details
    """
    
    try:
        # Step 1: Fetch existing patient by patient_id
        patient_result = supabase.table('patients').select('*').eq(
            'id', request.patient_id
        ).execute()
        
        if not patient_result.data or len(patient_result.data) == 0:
            raise HTTPException(status_code=404, detail="Patient not found")
        
        patient_id = request.patient_id
        patient_allergies = patient_result.data[0].get('allergies', '')
        
        # Step 2: Determine case_id and visit_number based on mode
        case_id = None
        visit_number = 1
        history_of_illness = request.history_of_illness
        
        if request.case_id:
            # Follow-up mode: use provided case_id and increment visit_number
            case_id = request.case_id
            
            # Get the latest visit in this case
            latest_visit = supabase.table('encounters').select(
                'visit_number, history_of_illness'
            ).eq('case_id', case_id).order(
                'visit_number', desc=True
            ).limit(1).execute()
            
            if latest_visit.data and len(latest_visit.data) > 0:
                visit_number = latest_visit.data[0]['visit_number'] + 1
                # Inherit history_of_illness from parent if not provided
                if not history_of_illness:
                    history_of_illness = latest_visit.data[0].get('history_of_illness', '')
            else:
                raise HTTPException(status_code=404, detail="Parent case not found")
        else:
            # New encounter mode: generate new case_id
            case_id = str(uuid.uuid4())
            visit_number = 1
        
        # Step 3: Create encounter record
        encounter_data = {
            'patient_id': patient_id,
            'doctor_id': request.doctor_id,
            'case_id': case_id,
            'visit_number': visit_number,
            'chief_complaint': request.chief_complaint,
            'history_of_illness': history_of_illness,
            'temperature': request.vital_signs.temperature,
            'blood_pressure': request.vital_signs.blood_pressure,
            'heart_rate': int(request.vital_signs.heart_rate) if request.vital_signs.heart_rate else None,
            'respiratory_rate': int(request.vital_signs.respiratory_rate) if request.vital_signs.respiratory_rate else None,
            'oxygen_saturation': int(request.vital_signs.oxygen_saturation) if request.vital_signs.oxygen_saturation else None,
            'weight': request.vital_signs.weight,
            'height': request.vital_signs.height,
            'physical_exam': request.physical_exam,
            'diagnosis': request.diagnosis,
            'medications': request.medications,
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
