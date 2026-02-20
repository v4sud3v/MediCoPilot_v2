from fastapi import APIRouter, HTTPException, Query
from supabase import create_client, Client
from datamodel import (
    PatientEducation,
    PatientEducationListResponse,
    UpdateEducationRequest,
    UpdateEducationResponse,
    PatientSummary,
    PatientSummaryListResponse
)
import os
import re
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Optional
from datetime import datetime
import uuid


def markdown_to_html(text: str) -> str:
    """Convert markdown bold (**text**) and italic (*text*) to HTML tags."""
    # Convert **bold** to <strong>bold</strong> (must be done before italic)
    text = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', text)
    # Convert *italic* to <em>italic</em>
    text = re.sub(r'\*(.+?)\*', r'<em>\1</em>', text)
    # Convert newlines to <br>
    text = text.replace('\n', '<br>\n')
    return text

router = APIRouter(prefix="/patient-education", tags=["Patient Education"])

# Initialize Supabase client
supabase: Client = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_SECRET_KEY")
)


@router.get("/doctor/{doctor_id}", response_model=PatientEducationListResponse)
async def get_education_for_doctor(
    doctor_id: str,
    status: Optional[str] = Query(None, description="Filter by status: pending, sent, viewed"),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
):
    """
    Fetch all patient education materials for a specific doctor.
    
    Args:
        doctor_id: UUID of the doctor
        status: Optional filter by status (pending, sent, viewed)
        limit: Maximum number of results to return
        offset: Pagination offset
    
    Returns:
        List of patient education materials with patient and encounter info
    """
    try:
        # Validate doctor_id format
        try:
            uuid.UUID(doctor_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid doctor ID format")

        # Build query
        query = supabase.table('patient_education').select('*').eq('doctor_id', doctor_id)
        
        if status:
            query = query.eq('status', status)
        
        response = query.order(
            'created_at', desc=True
        ).range(
            offset, offset + limit - 1
        ).execute()

        if not response.data:
            return PatientEducationListResponse(education_list=[], total=0)

        # Enrich with patient and encounter data
        education_list = []
        for edu in response.data:
            # Get patient info
            patient_response = supabase.table('patients').select(
                'name, age, gender'
            ).eq('id', edu['patient_id']).single().execute()
            
            # Get encounter info
            encounter_response = supabase.table('encounters').select(
                'diagnosis, chief_complaint, visit_number'
            ).eq('id', edu['encounter_id']).single().execute()
            
            education_item = PatientEducation(
                id=edu['id'],
                encounter_id=edu['encounter_id'],
                patient_id=edu['patient_id'],
                doctor_id=edu['doctor_id'],
                title=edu['title'],
                description=edu.get('description'),
                content=edu['content'],
                status=edu['status'],
                sent_at=edu.get('sent_at'),
                viewed_at=edu.get('viewed_at'),
                created_at=edu['created_at'],
                patient_name=patient_response.data.get('name') if patient_response.data else None,
                patient_age=patient_response.data.get('age') if patient_response.data else None,
                patient_gender=patient_response.data.get('gender') if patient_response.data else None,
                encounter_diagnosis=encounter_response.data.get('diagnosis') if encounter_response.data else None,
                encounter_chief_complaint=encounter_response.data.get('chief_complaint') if encounter_response.data else None,
                visit_number=encounter_response.data.get('visit_number') if encounter_response.data else None
            )
            education_list.append(education_item)

        # Get total count
        count_query = supabase.table('patient_education').select('id', count='exact').eq('doctor_id', doctor_id)
        if status:
            count_query = count_query.eq('status', status)
        count_response = count_query.execute()
        total = count_response.count if count_response.count else len(education_list)

        return PatientEducationListResponse(education_list=education_list, total=total)

    except Exception as e:
        print(f"Error fetching patient education: {e}")
        raise HTTPException(status_code=500, detail=f"Error fetching patient education: {str(e)}")


@router.get("/encounter/{encounter_id}", response_model=PatientEducation)
async def get_education_by_encounter(encounter_id: str):
    """
    Get patient education for a specific encounter.
    """
    try:
        uuid.UUID(encounter_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid encounter ID format")

    try:
        response = supabase.table('patient_education').select('*').eq(
            'encounter_id', encounter_id
        ).single().execute()

        if not response.data:
            raise HTTPException(status_code=404, detail="Patient education not found for this encounter")

        edu = response.data
        
        # Get patient info
        patient_response = supabase.table('patients').select(
            'name, age, gender'
        ).eq('id', edu['patient_id']).single().execute()
        
        # Get encounter info
        encounter_response = supabase.table('encounters').select(
            'diagnosis, chief_complaint, visit_number'
        ).eq('id', edu['encounter_id']).single().execute()

        return PatientEducation(
            id=edu['id'],
            encounter_id=edu['encounter_id'],
            patient_id=edu['patient_id'],
            doctor_id=edu['doctor_id'],
            title=edu['title'],
            description=edu.get('description'),
            content=edu['content'],
            status=edu['status'],
            sent_at=edu.get('sent_at'),
            viewed_at=edu.get('viewed_at'),
            created_at=edu['created_at'],
            patient_name=patient_response.data.get('name') if patient_response.data else None,
            patient_age=patient_response.data.get('age') if patient_response.data else None,
            patient_gender=patient_response.data.get('gender') if patient_response.data else None,
            encounter_diagnosis=encounter_response.data.get('diagnosis') if encounter_response.data else None,
            encounter_chief_complaint=encounter_response.data.get('chief_complaint') if encounter_response.data else None,
            visit_number=encounter_response.data.get('visit_number') if encounter_response.data else None
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error fetching patient education: {e}")
        raise HTTPException(status_code=500, detail=f"Error fetching patient education: {str(e)}")


@router.get("/{education_id}", response_model=PatientEducation)
async def get_education_by_id(education_id: str):
    """
    Get a specific patient education by ID.
    """
    try:
        uuid.UUID(education_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid education ID format")

    try:
        response = supabase.table('patient_education').select('*').eq(
            'id', education_id
        ).single().execute()

        if not response.data:
            raise HTTPException(status_code=404, detail="Patient education not found")

        edu = response.data
        
        # Get patient info
        patient_response = supabase.table('patients').select(
            'name, age, gender'
        ).eq('id', edu['patient_id']).single().execute()
        
        # Get encounter info
        encounter_response = supabase.table('encounters').select(
            'diagnosis, chief_complaint, visit_number'
        ).eq('id', edu['encounter_id']).single().execute()

        return PatientEducation(
            id=edu['id'],
            encounter_id=edu['encounter_id'],
            patient_id=edu['patient_id'],
            doctor_id=edu['doctor_id'],
            title=edu['title'],
            description=edu.get('description'),
            content=edu['content'],
            status=edu['status'],
            sent_at=edu.get('sent_at'),
            viewed_at=edu.get('viewed_at'),
            created_at=edu['created_at'],
            patient_name=patient_response.data.get('name') if patient_response.data else None,
            patient_age=patient_response.data.get('age') if patient_response.data else None,
            patient_gender=patient_response.data.get('gender') if patient_response.data else None,
            encounter_diagnosis=encounter_response.data.get('diagnosis') if encounter_response.data else None,
            encounter_chief_complaint=encounter_response.data.get('chief_complaint') if encounter_response.data else None,
            visit_number=encounter_response.data.get('visit_number') if encounter_response.data else None
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error fetching patient education: {e}")
        raise HTTPException(status_code=500, detail=f"Error fetching patient education: {str(e)}")


@router.put("/{education_id}", response_model=UpdateEducationResponse)
async def update_education(education_id: str, request: UpdateEducationRequest):
    """
    Update a patient education document (title, description, content, or status).
    """
    try:
        uuid.UUID(education_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid education ID format")

    try:
        # Build update data
        update_data = {}
        if request.title is not None:
            update_data['title'] = request.title
        if request.description is not None:
            update_data['description'] = request.description
        if request.content is not None:
            update_data['content'] = request.content
        if request.status is not None:
            update_data['status'] = request.status
            if request.status == 'sent':
                update_data['sent_at'] = datetime.utcnow().isoformat()
            elif request.status == 'viewed':
                update_data['viewed_at'] = datetime.utcnow().isoformat()

        if not update_data:
            raise HTTPException(status_code=400, detail="No update data provided")

        response = supabase.table('patient_education').update(
            update_data
        ).eq('id', education_id).execute()

        if not response.data:
            raise HTTPException(status_code=404, detail="Patient education not found")

        return UpdateEducationResponse(success=True, message="Patient education updated successfully")

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error updating patient education: {e}")
        raise HTTPException(status_code=500, detail=f"Error updating patient education: {str(e)}")


@router.post("/{education_id}/send", response_model=UpdateEducationResponse)
async def send_education(education_id: str):
    """
    Mark a patient education document as sent and email it to the patient.
    """
    try:
        uuid.UUID(education_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid education ID format")

    try:
        # Fetch the education record
        edu_response = supabase.table('patient_education').select('*').eq(
            'id', education_id
        ).single().execute()

        if not edu_response.data:
            raise HTTPException(status_code=404, detail="Patient education not found")

        edu = edu_response.data

        # Fetch patient email from patients table
        patient_response = supabase.table('patients').select(
            'name, email'
        ).eq('id', edu['patient_id']).single().execute()

        if not patient_response.data or not patient_response.data.get('email'):
            raise HTTPException(status_code=400, detail="Patient email not found. Cannot send education.")

        patient_email = patient_response.data['email']
        patient_name = patient_response.data.get('name', 'Patient')

        # Send email via SMTP (Gmail)
        smtp_email = os.getenv("SMTP_EMAIL")
        smtp_password = os.getenv("SMTP_APP_PASSWORD")

        if not smtp_email or not smtp_password:
            raise HTTPException(status_code=500, detail="SMTP email credentials not configured")

        # Build email
        msg = MIMEMultipart("alternative")
        # Sanitize title: remove newlines/tabs that break email headers
        safe_title = ' '.join(edu['title'].replace('\n', ' ').replace('\r', ' ').replace('\t', ' ').split())
        msg["Subject"] = f"MediCoPilot - {safe_title}"
        msg["From"] = smtp_email
        msg["To"] = patient_email

        # Plain text version
        plain_text = f"""Dear {patient_name},

Your doctor has shared the following health education material with you:

{edu['title']}

{edu.get('description', '')}

{edu['content']}

---
This email was sent via MediCoPilot. Please consult your doctor for any questions.
"""

        # HTML version
        html_content = f"""
<html>
<body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; border-radius: 10px 10px 0 0;">
        <h1 style="color: white; margin: 0;">MediCoPilot</h1>
        <p style="color: #e0e0e0; margin: 5px 0 0 0;">Patient Health Education</p>
    </div>
    <div style="background: #ffffff; padding: 25px; border: 1px solid #e0e0e0; border-top: none; border-radius: 0 0 10px 10px;">
        <p>Dear <strong>{patient_name}</strong>,</p>
        <p>Your doctor has shared the following health education material with you:</p>
        <h2 style="color: #333;">{edu['title']}</h2>
        {f'<p style="color: #666; font-style: italic;">{edu.get("description", "")}</p>' if edu.get('description') else ''}
        <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; border-left: 4px solid #667eea; margin: 15px 0; white-space: pre-wrap;">
{markdown_to_html(edu['content'])}
        </div>
        <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;">
        <p style="color: #999; font-size: 12px;">This email was sent via MediCoPilot. Please consult your doctor for any questions.</p>
    </div>
</body>
</html>
"""

        msg.attach(MIMEText(plain_text, "plain"))
        msg.attach(MIMEText(html_content, "html"))

        # Send via Gmail SMTP
        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(smtp_email, smtp_password)
            server.sendmail(smtp_email, patient_email, msg.as_string())

        # Update status to 'sent' in database
        supabase.table('patient_education').update({
            'status': 'sent',
            'sent_at': datetime.utcnow().isoformat()
        }).eq('id', education_id).execute()

        return UpdateEducationResponse(
            success=True,
            message=f"Patient education sent successfully to {patient_email}"
        )

    except HTTPException:
        raise
    except smtplib.SMTPAuthenticationError:
        raise HTTPException(status_code=500, detail="SMTP authentication failed. Check app password.")
    except smtplib.SMTPException as e:
        print(f"SMTP error sending patient education: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to send email: {str(e)}")
    except Exception as e:
        print(f"Error sending patient education: {e}")
        raise HTTPException(status_code=500, detail=f"Error sending patient education: {str(e)}")


# Patient Summary endpoints
@router.get("/summary/doctor/{doctor_id}", response_model=PatientSummaryListResponse)
async def get_summaries_for_doctor(
    doctor_id: str,
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
):
    """
    Fetch all patient summaries for a specific doctor.
    """
    try:
        uuid.UUID(doctor_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid doctor ID format")

    try:
        response = supabase.table('patient_summary').select('*').eq(
            'doctor_id', doctor_id
        ).order(
            'created_at', desc=True
        ).range(
            offset, offset + limit - 1
        ).execute()

        if not response.data:
            return PatientSummaryListResponse(summaries=[], total=0)

        summaries = []
        for summary in response.data:
            # Get patient info
            patient_response = supabase.table('patients').select(
                'name'
            ).eq('id', summary['patient_id']).single().execute()
            
            # Get encounter info
            encounter_response = supabase.table('encounters').select(
                'diagnosis, visit_number'
            ).eq('id', summary['encounter_id']).single().execute()

            summary_item = PatientSummary(
                id=summary['id'],
                encounter_id=summary['encounter_id'],
                patient_id=summary['patient_id'],
                doctor_id=summary['doctor_id'],
                summary_text=summary['summary_text'],
                key_findings=summary.get('key_findings'),
                important_changes=summary.get('important_changes'),
                follow_up_notes=summary.get('follow_up_notes'),
                created_at=summary['created_at'],
                updated_at=summary['updated_at'],
                patient_name=patient_response.data.get('name') if patient_response.data else None,
                encounter_diagnosis=encounter_response.data.get('diagnosis') if encounter_response.data else None,
                visit_number=encounter_response.data.get('visit_number') if encounter_response.data else None
            )
            summaries.append(summary_item)

        # Get total count
        count_response = supabase.table('patient_summary').select('id', count='exact').eq(
            'doctor_id', doctor_id
        ).execute()
        total = count_response.count if count_response.count else len(summaries)

        return PatientSummaryListResponse(summaries=summaries, total=total)

    except Exception as e:
        print(f"Error fetching patient summaries: {e}")
        raise HTTPException(status_code=500, detail=f"Error fetching patient summaries: {str(e)}")


@router.get("/summary/encounter/{encounter_id}", response_model=PatientSummary)
async def get_summary_by_encounter(encounter_id: str):
    """
    Get patient summary for a specific encounter.
    """
    try:
        uuid.UUID(encounter_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid encounter ID format")

    try:
        response = supabase.table('patient_summary').select('*').eq(
            'encounter_id', encounter_id
        ).single().execute()

        if not response.data:
            raise HTTPException(status_code=404, detail="Patient summary not found for this encounter")

        summary = response.data
        
        # Get patient info
        patient_response = supabase.table('patients').select(
            'name'
        ).eq('id', summary['patient_id']).single().execute()
        
        # Get encounter info
        encounter_response = supabase.table('encounters').select(
            'diagnosis, visit_number'
        ).eq('id', summary['encounter_id']).single().execute()

        return PatientSummary(
            id=summary['id'],
            encounter_id=summary['encounter_id'],
            patient_id=summary['patient_id'],
            doctor_id=summary['doctor_id'],
            summary_text=summary['summary_text'],
            key_findings=summary.get('key_findings'),
            important_changes=summary.get('important_changes'),
            follow_up_notes=summary.get('follow_up_notes'),
            created_at=summary['created_at'],
            updated_at=summary['updated_at'],
            patient_name=patient_response.data.get('name') if patient_response.data else None,
            encounter_diagnosis=encounter_response.data.get('diagnosis') if encounter_response.data else None,
            visit_number=encounter_response.data.get('visit_number') if encounter_response.data else None
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error fetching patient summary: {e}")
        raise HTTPException(status_code=500, detail=f"Error fetching patient summary: {str(e)}")


@router.get("/summary/patient/{patient_id}", response_model=PatientSummaryListResponse)
async def get_summaries_for_patient(
    patient_id: str,
    limit: int = Query(50, ge=1, le=100),
):
    """
    Get all summaries for a specific patient (useful for viewing patient history).
    """
    try:
        uuid.UUID(patient_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid patient ID format")

    try:
        response = supabase.table('patient_summary').select('*').eq(
            'patient_id', patient_id
        ).order(
            'created_at', desc=True
        ).limit(limit).execute()

        if not response.data:
            return PatientSummaryListResponse(summaries=[], total=0)

        # Get patient info once
        patient_response = supabase.table('patients').select(
            'name'
        ).eq('id', patient_id).single().execute()
        patient_name = patient_response.data.get('name') if patient_response.data else None

        summaries = []
        for summary in response.data:
            # Get encounter info
            encounter_response = supabase.table('encounters').select(
                'diagnosis, visit_number'
            ).eq('id', summary['encounter_id']).single().execute()

            summary_item = PatientSummary(
                id=summary['id'],
                encounter_id=summary['encounter_id'],
                patient_id=summary['patient_id'],
                doctor_id=summary['doctor_id'],
                summary_text=summary['summary_text'],
                key_findings=summary.get('key_findings'),
                important_changes=summary.get('important_changes'),
                follow_up_notes=summary.get('follow_up_notes'),
                created_at=summary['created_at'],
                updated_at=summary['updated_at'],
                patient_name=patient_name,
                encounter_diagnosis=encounter_response.data.get('diagnosis') if encounter_response.data else None,
                visit_number=encounter_response.data.get('visit_number') if encounter_response.data else None
            )
            summaries.append(summary_item)

        return PatientSummaryListResponse(summaries=summaries, total=len(summaries))

    except Exception as e:
        print(f"Error fetching patient summaries: {e}")
        raise HTTPException(status_code=500, detail=f"Error fetching patient summaries: {str(e)}")
