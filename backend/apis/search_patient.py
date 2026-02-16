from fastapi import APIRouter, HTTPException
from supabase import create_client
import os
from typing import List, Optional
from pydantic import BaseModel

router = APIRouter(prefix="/search", tags=["Search"])

# Initialize Supabase
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SECRET_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise ValueError("SUPABASE_URL or SUPABASE_SECRET_KEY not set")

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)


class UpdateAllergiesRequest(BaseModel):
    allergies: Optional[str] = None


class PatientSearchResult:
    def __init__(self, patient_id: str, name: str, age: Optional[int], gender: Optional[str], contact_info: Optional[str]):
        self.patient_id = patient_id
        self.name = name
        self.age = age
        self.gender = gender
        self.contact_info = contact_info

    def to_dict(self):
        return {
            "patient_id": self.patient_id,
            "name": self.name,
            "age": self.age,
            "gender": self.gender,
            "contact_info": self.contact_info,
        }


@router.get("/patients", tags=["Search"])
async def search_patients(query: str = "", limit: int = 10, doctor_id: str = None) -> List[dict]:
    """
    Search for patients by name or contact info.
    If doctor_id is provided, only return patients linked to that doctor
    via doctor_patients table.
    
    Args:
        query: Search term (patient name or contact info)
        limit: Maximum number of results to return (default: 10)
        doctor_id: Optional doctor UUID to scope results to that doctor's patients
    
    Returns:
        List of matching patient records
    """
    
    # If doctor_id is given, resolve linked patient IDs first
    linked_patient_ids = None
    if doctor_id and doctor_id.strip():
        try:
            dp_response = supabase.table("doctor_patients").select(
                "patient_id"
            ).eq("doctor_id", doctor_id.strip()).execute()
            linked_patient_ids = [row["patient_id"] for row in (dp_response.data or [])]
            if not linked_patient_ids:
                return []  # Doctor has no linked patients yet
        except Exception as e:
            print(f"Error fetching doctor_patients: {e}")
            # Fall through to unscoped search
    
    if not query or query.strip() == "":
        # Return recent patients (optionally scoped to doctor)
        try:
            q = supabase.table("patients").select(
                "id, name, age, gender, contact_info"
            )
            if linked_patient_ids is not None:
                q = q.in_("id", linked_patient_ids)
            response = q.order("created_at", desc=True).limit(limit).execute()
            
            return [patient for patient in response.data]
        except Exception as e:
            print(f"Error fetching recent patients: {e}")
            raise HTTPException(status_code=500, detail=str(e))
    
    # Search by name or contact info
    try:
        query_lower = query.lower().strip()
        
        # Search for patients where name contains query (case-insensitive)
        q = supabase.table("patients").select(
            "id, name, age, gender, contact_info"
        ).ilike("name", f"%{query_lower}%")
        if linked_patient_ids is not None:
            q = q.in_("id", linked_patient_ids)
        response = q.limit(limit).execute()
        
        results = response.data if response.data else []
        
        # If results are less than limit, also search by contact info
        if len(results) < limit:
            remaining = limit - len(results)
            cq = supabase.table("patients").select(
                "id, name, age, gender, contact_info"
            ).ilike("contact_info", f"%{query_lower}%")
            if linked_patient_ids is not None:
                cq = cq.in_("id", linked_patient_ids)
            contact_response = cq.limit(remaining).execute()
            
            if contact_response.data:
                # Avoid duplicates
                existing_ids = {p["id"] for p in results}
                for patient in contact_response.data:
                    if patient["id"] not in existing_ids:
                        results.append(patient)
        
        return results
    except Exception as e:
        print(f"Error searching patients: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/patients/{patient_id}", tags=["Search"])
async def get_patient_details(patient_id: str) -> dict:
    """
    Get full details of a patient by ID.
    
    Args:
        patient_id: The patient ID (UUID)
    
    Returns:
        Patient record with all details
    """
    
    try:
        response = supabase.table("patients").select("*").eq("id", patient_id).single().execute()
        
        if not response.data:
            raise HTTPException(status_code=404, detail="Patient not found")
        
        return response.data
    except Exception as e:
        print(f"Error fetching patient: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.patch("/patients/{patient_id}/allergies", tags=["Search"])
async def update_patient_allergies(patient_id: str, request: UpdateAllergiesRequest) -> dict:
    """
    Update patient allergies by ID.
    
    Args:
        patient_id: The patient ID (UUID)
        request: UpdateAllergiesRequest with allergies text
    
    Returns:
        Updated patient record
    """
    
    try:
        update_data = {"allergies": request.allergies}
        
        response = supabase.table("patients").update(
            update_data
        ).eq("id", patient_id).execute()
        
        if not response.data:
            raise HTTPException(status_code=404, detail="Patient not found")
        
        return {
            "success": True,
            "message": "Allergies updated successfully",
            "patient_id": patient_id,
        }
    except Exception as e:
        print(f"Error updating patient allergies: {e}")
        raise HTTPException(status_code=500, detail=str(e))