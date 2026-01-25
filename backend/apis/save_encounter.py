from fastapi import APIRouter, HTTPException
from supabase import create_client, Client
from datamodel import SaveEncounterRequest, SaveEncounterResponse
from openai import OpenAI
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

# Configure Groq API (OpenAI-compatible)
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
ai_client = None
if GROQ_API_KEY:
    ai_client = OpenAI(
        api_key=GROQ_API_KEY,
        base_url="https://api.groq.com/openai/v1",
    )


def generate_patient_education(encounter_data: dict, patient_data: dict) -> dict:
    """
    Generate patient education content using AI based on the encounter.
    """
    if not ai_client:
        return None
    
    prompt = f"""You are a medical educator. Create a patient education document based on this encounter:

Patient Name: {patient_data.get('name', 'Patient')}
Age: {patient_data.get('age', 'N/A')}
Gender: {patient_data.get('gender', 'N/A')}
Allergies: {patient_data.get('allergies', 'None reported')}

Chief Complaint: {encounter_data.get('chief_complaint', 'N/A')}
Diagnosis: {encounter_data.get('diagnosis', 'N/A')}
Medications Prescribed: {encounter_data.get('medications', 'None')}
Physical Exam Findings: {encounter_data.get('physical_exam', 'N/A')}

Generate a patient-friendly education document that includes:
1. An explanation of their condition in simple terms
2. What each prescribed medication is for and how to take it
3. Important care instructions and lifestyle recommendations
4. Warning signs that require immediate medical attention
5. Expected recovery timeline and follow-up recommendations

Format the content clearly with sections and bullet points where appropriate.
Write in a caring, reassuring tone that patients can easily understand.
"""

    try:
        response = ai_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": "You are a compassionate medical educator creating patient-friendly educational materials."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7,
            max_tokens=2048
        )
        content = response.choices[0].message.content
        
        # Generate a title based on diagnosis
        diagnosis = encounter_data.get('diagnosis', 'Your Health')
        title = f"Understanding Your Diagnosis: {diagnosis[:50]}" if diagnosis else "Your Health Care Guide"
        description = f"Educational material about your recent visit for {encounter_data.get('chief_complaint', 'your condition')}"
        
        return {
            "title": title,
            "description": description,
            "content": content
        }
    except Exception as e:
        print(f"Error generating patient education: {e}")
        return None


def generate_patient_summary(encounter_data: dict, patient_data: dict, previous_summary: str = None) -> dict:
    """
    Generate a summary of the encounter highlighting important details and changes.
    """
    if not ai_client:
        return None
    
    previous_context = ""
    if previous_summary:
        previous_context = f"\nPrevious Patient Summary:\n{previous_summary}\n\nNote any changes from the previous summary."
    
    prompt = f"""You are a medical documentation specialist. Create a concise clinical summary for this patient encounter:

Patient Name: {patient_data.get('name', 'Patient')}
Age: {patient_data.get('age', 'N/A')}
Gender: {patient_data.get('gender', 'N/A')}
Known Allergies: {patient_data.get('allergies', 'None reported')}

Visit Details:
- Chief Complaint: {encounter_data.get('chief_complaint', 'N/A')}
- History of Illness: {encounter_data.get('history_of_illness', 'N/A')}
- Diagnosis: {encounter_data.get('diagnosis', 'N/A')}
- Medications: {encounter_data.get('medications', 'None')}
- Physical Exam: {encounter_data.get('physical_exam', 'N/A')}

Vital Signs:
- Temperature: {encounter_data.get('temperature', 'N/A')}°F
- Blood Pressure: {encounter_data.get('blood_pressure', 'N/A')}
- Heart Rate: {encounter_data.get('heart_rate', 'N/A')} bpm
- Respiratory Rate: {encounter_data.get('respiratory_rate', 'N/A')} breaths/min
- O2 Saturation: {encounter_data.get('oxygen_saturation', 'N/A')}%
- Weight: {encounter_data.get('weight', 'N/A')} kg
- Height: {encounter_data.get('height', 'N/A')} cm
{previous_context}

Generate a structured summary with:
1. SUMMARY_TEXT: A brief 2-3 sentence overall summary of the encounter
2. KEY_FINDINGS: Important clinical findings from this visit (bullet points)
3. IMPORTANT_CHANGES: Any significant changes in patient condition or treatment (bullet points)
4. FOLLOW_UP_NOTES: Recommended follow-up actions and monitoring requirements

Format each section with clear headers.
"""

    try:
        response = ai_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": "You are a medical documentation specialist creating concise clinical summaries."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.5,
            max_tokens=1500
        )
        content = response.choices[0].message.content
        
        # Parse the response into structured fields
        summary_text = ""
        key_findings = ""
        important_changes = ""
        follow_up_notes = ""
        
        current_section = None
        lines = content.split('\n')
        
        for line in lines:
            line_upper = line.upper().strip()
            if 'SUMMARY_TEXT' in line_upper or 'SUMMARY:' in line_upper or 'OVERALL SUMMARY' in line_upper:
                current_section = 'summary'
                continue
            elif 'KEY_FINDINGS' in line_upper or 'KEY FINDINGS' in line_upper:
                current_section = 'findings'
                continue
            elif 'IMPORTANT_CHANGES' in line_upper or 'IMPORTANT CHANGES' in line_upper:
                current_section = 'changes'
                continue
            elif 'FOLLOW_UP' in line_upper or 'FOLLOW UP' in line_upper:
                current_section = 'followup'
                continue
            
            if current_section == 'summary':
                summary_text += line + '\n'
            elif current_section == 'findings':
                key_findings += line + '\n'
            elif current_section == 'changes':
                important_changes += line + '\n'
            elif current_section == 'followup':
                follow_up_notes += line + '\n'
        
        # If parsing failed, use the whole content as summary
        if not summary_text.strip():
            summary_text = content[:500]
        
        return {
            "summary_text": summary_text.strip(),
            "key_findings": key_findings.strip() or None,
            "important_changes": important_changes.strip() or None,
            "follow_up_notes": follow_up_notes.strip() or None
        }
    except Exception as e:
        print(f"Error generating patient summary: {e}")
        return None


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
        
        # Generate AI content after saving encounter
        patient_education_id = None
        patient_summary_id = None
        
        patient_data = patient_result.data[0]
        
        # Get previous summary for this patient if exists (for tracking changes)
        previous_summary = None
        try:
            prev_summary_result = supabase.table('patient_summary').select(
                'summary_text'
            ).eq('patient_id', patient_id).order(
                'created_at', desc=True
            ).limit(1).execute()
            
            if prev_summary_result.data and len(prev_summary_result.data) > 0:
                previous_summary = prev_summary_result.data[0].get('summary_text')
        except Exception as e:
            print(f"Could not fetch previous summary: {e}")
        
        # Generate patient education
        education_content = generate_patient_education(encounter_data, patient_data)
        if education_content:
            try:
                education_data = {
                    'encounter_id': encounter_id,
                    'patient_id': patient_id,
                    'doctor_id': request.doctor_id,
                    'title': education_content['title'],
                    'description': education_content['description'],
                    'content': education_content['content'],
                    'status': 'pending'
                }
                education_result = supabase.table('patient_education').insert(
                    education_data
                ).execute()
                if education_result.data:
                    patient_education_id = education_result.data[0]['id']
            except Exception as e:
                print(f"Error saving patient education: {e}")
        
        # Generate patient summary
        summary_content = generate_patient_summary(encounter_data, patient_data, previous_summary)
        if summary_content:
            try:
                summary_data = {
                    'encounter_id': encounter_id,
                    'patient_id': patient_id,
                    'doctor_id': request.doctor_id,
                    'summary_text': summary_content['summary_text'],
                    'key_findings': summary_content['key_findings'],
                    'important_changes': summary_content['important_changes'],
                    'follow_up_notes': summary_content['follow_up_notes']
                }
                summary_result = supabase.table('patient_summary').insert(
                    summary_data
                ).execute()
                if summary_result.data:
                    patient_summary_id = summary_result.data[0]['id']
            except Exception as e:
                print(f"Error saving patient summary: {e}")
        
        return SaveEncounterResponse(
            success=True,
            encounter_id=encounter_id,
            patient_id=patient_id,
            case_id=case_id,
            visit_number=visit_number,
            message=f"Encounter saved successfully (Visit #{visit_number})",
            patient_education_id=patient_education_id,
            patient_summary_id=patient_summary_id
        )
        
    except Exception as e:
        print(f"Error saving encounter: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to save encounter: {str(e)}")
