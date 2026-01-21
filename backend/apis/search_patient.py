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
async def search_patients(query: str = "", limit: int = 10) -> List[dict]:
    """
    Search for patients by name or contact info.
    
    Args:
        query: Search term (patient name or contact info)
        limit: Maximum number of results to return (default: 10)
    
    Returns:
        List of matching patient records
    """
    
    if not query or query.strip() == "":
        # Return recent patients if no query
        try:
            response = supabase.table("patients").select(
                "id, name, age, gender, contact_info"
            ).order("created_at", desc=True).limit(limit).execute()
            
            return [patient for patient in response.data]
        except Exception as e:
            print(f"Error fetching recent patients: {e}")
            raise HTTPException(status_code=500, detail=str(e))
    
    # Search by name or contact info
    try:
        query_lower = query.lower().strip()
        
        # Search for patients where name contains query (case-insensitive)
        response = supabase.table("patients").select(
            "id, name, age, gender, contact_info"
        ).ilike("name", f"%{query_lower}%").limit(limit).execute()
        
        results = response.data if response.data else []
        
        # If results are less than limit, also search by contact info
        if len(results) < limit:
            remaining = limit - len(results)
            contact_response = supabase.table("patients").select(
                "id, name, age, gender, contact_info"
            ).ilike("contact_info", f"%{query_lower}%").limit(remaining).execute()
            
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