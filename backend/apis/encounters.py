from fastapi import APIRouter, HTTPException, Query
from supabase import create_client, Client
import os
import uuid

router = APIRouter(prefix="/encounters", tags=["Encounters"])

# Initialize Supabase client
supabase: Client = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_SECRET_KEY")
)

ENCOUNTER_FIELDS = (
    'id, patient_id, doctor_id, case_id, visit_number, chief_complaint, '
    'history_of_illness, temperature, blood_pressure, heart_rate, '
    'respiratory_rate, oxygen_saturation, weight, height, physical_exam, '
    'diagnosis, medications, created_at'
)

PATIENT_FIELDS = 'id, name, age, gender, contact_info, allergies'


def _fetch_patients_by_ids(patient_ids: list[str]) -> dict[str, dict]:
    unique_ids = list({patient_id for patient_id in patient_ids if patient_id})
    if not unique_ids:
        return {}

    response = supabase.table('patients').select(
        PATIENT_FIELDS
    ).in_(
        'id', unique_ids
    ).execute()

    return {
        patient['id']: patient
        for patient in (response.data or [])
        if patient.get('id')
    }


def _attach_patient_data(encounters: list[dict]) -> list[dict]:
    patients_by_id = _fetch_patients_by_ids(
        [encounter.get('patient_id') for encounter in encounters]
    )

    encounters_with_patients = []
    for encounter in encounters:
        patient = patients_by_id.get(encounter.get('patient_id'), {})
        encounter['patient_name'] = patient.get('name', 'Unknown')
        encounter['patient_age'] = patient.get('age')
        encounter['patient_gender'] = patient.get('gender')
        encounter['patient_contact'] = patient.get('contact_info')
        encounter['patient_allergies'] = patient.get('allergies')
        encounters_with_patients.append(encounter)

    return encounters_with_patients


@router.get("/all", tags=["Encounters"])
async def get_all_encounters(
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
):
    """
    Fetch all encounters across all doctors.
    
    Args:
        limit: Maximum number of encounters to return (default: 100)
        offset: Pagination offset (default: 0)
    
    Returns:
        List of all encounters with patient information
    """
    try:
        response = supabase.table('encounters').select(
            ENCOUNTER_FIELDS
        ).order(
            'created_at', desc=True
        ).range(
            offset, offset + limit - 1
        ).execute()

        if not response.data:
            return []

        return _attach_patient_data(response.data)

    except Exception as e:
        print(f"Error fetching all encounters: {e}")
        raise HTTPException(status_code=500, detail=f"Error fetching all encounters: {str(e)}")


@router.get("/doctor/{doctor_id}", tags=["Encounters"])
async def get_encounters_for_doctor(
    doctor_id: str,
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
):
    """
    Fetch all encounters for patients linked to this doctor (via doctor_patients),
    regardless of which doctor recorded the encounter.
    
    Args:
        doctor_id: UUID of the doctor
        limit: Maximum number of encounters to return (default: 100)
        offset: Pagination offset (default: 0)
    
    Returns:
        List of encounters with patient and case information
    """
    try:
        # Validate doctor_id format
        try:
            uuid.UUID(doctor_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid doctor ID format")

        # Step 1: Get patient IDs linked to this doctor.
        dp_response = supabase.table('doctor_patients').select(
            'patient_id'
        ).eq('doctor_id', doctor_id).execute()

        linked_patient_ids = {
            row['patient_id']
            for row in (dp_response.data or [])
            if row.get('patient_id')
        }

        # Backfill support for older encounter data created before doctor_patients
        # links were enforced during encounter saves.
        own_encounter_response = supabase.table('encounters').select(
            'patient_id'
        ).eq(
            'doctor_id', doctor_id
        ).execute()

        own_patient_ids = {
            row['patient_id']
            for row in (own_encounter_response.data or [])
            if row.get('patient_id')
        }

        patient_ids = list(linked_patient_ids | own_patient_ids)

        if not patient_ids:
            return []

        # Step 2: Fetch encounters for all those patients (from ANY doctor)
        response = supabase.table('encounters').select(
            ENCOUNTER_FIELDS
        ).in_(
            'patient_id', patient_ids
        ).order(
            'created_at', desc=True
        ).range(
            offset, offset + limit - 1
        ).execute()

        if not response.data:
            return []

        return _attach_patient_data(response.data)

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error fetching encounters: {e}")
        raise HTTPException(status_code=500, detail=f"Error fetching encounters: {str(e)}")


@router.get("/case/{case_id}", tags=["Encounters"])
async def get_encounters_by_case(case_id: str):
    """
    Fetch all visits/encounters for a specific case.
    Useful for viewing the full history of a patient's case.
    
    Args:
        case_id: UUID of the case
    
    Returns:
        List of encounters (visits) in the case, sorted by visit_number
    """
    try:
        # Validate case_id format
        try:
            uuid.UUID(case_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid case ID format")

        # Fetch all encounters for this case
        response = supabase.table('encounters').select(
            ENCOUNTER_FIELDS
        ).eq(
            'case_id', case_id
        ).order(
            'visit_number', desc=False
        ).execute()

        if not response.data:
            raise HTTPException(status_code=404, detail="Case not found")

        # Fetch patient details
        patient_id = response.data[0]['patient_id']
        patient_response = supabase.table('patients').select(
            'id, name, age, gender, contact_info, allergies'
        ).eq('id', patient_id).maybe_single().execute()

        patient_data = patient_response.data if patient_response.data else {}
        
        # Add patient info to each encounter
        encounters_with_patients = []
        for encounter in response.data:
            encounter['patient_name'] = patient_data.get('name', 'Unknown')
            encounter['patient_age'] = patient_data.get('age')
            encounter['patient_gender'] = patient_data.get('gender')
            encounter['patient_contact'] = patient_data.get('contact_info')
            encounter['patient_allergies'] = patient_data.get('allergies')
            encounters_with_patients.append(encounter)

        return encounters_with_patients

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error fetching case encounters: {e}")
        raise HTTPException(status_code=500, detail=f"Error fetching case encounters: {str(e)}")


@router.get("/{encounter_id}", tags=["Encounters"])
async def get_encounter_details(encounter_id: str):
    """
    Fetch details of a specific encounter.
    
    Args:
        encounter_id: UUID of the encounter
    
    Returns:
        Encounter details with patient information
    """
    try:
        # Validate encounter_id format
        try:
            uuid.UUID(encounter_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid encounter ID format")

        # Fetch encounter
        response = supabase.table('encounters').select(
            ENCOUNTER_FIELDS
        ).eq('id', encounter_id).single().execute()

        if not response.data:
            raise HTTPException(status_code=404, detail="Encounter not found")

        encounter = response.data

        # Fetch patient details
        patient_response = supabase.table('patients').select(
            'id, name, age, gender, contact_info, allergies'
        ).eq('id', encounter['patient_id']).maybe_single().execute()

        if patient_response.data:
            patient = patient_response.data
            encounter['patient_name'] = patient.get('name', 'Unknown')
            encounter['patient_age'] = patient.get('age')
            encounter['patient_gender'] = patient.get('gender')
            encounter['patient_contact'] = patient.get('contact_info')
            encounter['patient_allergies'] = patient.get('allergies')

        return encounter

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error fetching encounter details: {e}")
        raise HTTPException(status_code=500, detail=f"Error fetching encounter details: {str(e)}")
