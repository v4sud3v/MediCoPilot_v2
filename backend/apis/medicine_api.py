import os
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from supabase import create_client, Client
from datamodel import MedicinePDFResponse, GenerateMedicinePDFRequest
from medicine_pdf_generator import generate_medicine_pdf_from_string
from config import settings
import uuid
from datetime import datetime
import base64
from io import BytesIO

router = APIRouter(prefix="/medicines", tags=["Medicines"])

# Initialize Supabase client
supabase: Client = create_client(
    settings.SUPABASE_URL,
    settings.SUPABASE_SECRET_KEY
)


@router.post("/generate-pdf", response_model=MedicinePDFResponse)
async def generate_medicine_pdf_endpoint(request: GenerateMedicinePDFRequest):
    """
    Generate a medicine PDF for an encounter.
    
    This creates a shareable PDF containing only medicine information without
    revealing patient conditions or medical diagnosis.
    
    Args:
        request: GenerateMedicinePDFRequest containing encounter_id, patient_name, doctor_name
    
    Returns:
        MedicinePDFResponse with base64-encoded PDF
    """
    try:
        uuid.UUID(request.encounter_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid encounter ID format")
    
    try:
        # Fetch encounter to get medications
        encounter_response = supabase.table('encounters').select(
            'id, medications, patient_id, doctor_id'
        ).eq('id', request.encounter_id).single().execute()
        
        if not encounter_response.data:
            raise HTTPException(status_code=404, detail="Encounter not found")
        
        encounter = encounter_response.data
        medications_str = encounter.get('medications', '')
        
        if not medications_str or medications_str.strip() == '':
            raise HTTPException(
                status_code=400,
                detail="No medications found for this encounter"
            )
        
        # Generate PDF
        pdf_bytes = generate_medicine_pdf_from_string(
            medications_str,
            patient_name=request.patient_name,
            doctor_name=request.doctor_name
        )
        
        # Encode to base64 for transmission
        pdf_base64 = base64.b64encode(pdf_bytes).decode('utf-8')
        
        filename = f"medicines_{request.encounter_id[:8]}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        
        return MedicinePDFResponse(
            success=True,
            filename=filename,
            pdf_base64=pdf_base64,
            message="Medicine PDF generated successfully"
        )
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error generating medicine PDF: {e}")
        raise HTTPException(status_code=500, detail=f"Error generating PDF: {str(e)}")


@router.get("/encounter/{encounter_id}/pdf")
async def download_medicine_pdf(
    encounter_id: str,
    patient_name: str = "Patient",
    doctor_name: str = "Your Doctor"
):
    """
    Download medicine PDF for an encounter directly.
    
    Returns the PDF file for download without revealing patient conditions.
    
    Args:
        encounter_id: UUID of the encounter
        patient_name: Name of the patient (optional, defaults to "Patient")
        doctor_name: Name of the doctor (optional, defaults to "Your Doctor")
    
    Returns:
        PDF file
    """
    try:
        uuid.UUID(encounter_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid encounter ID format")
    
    try:
        # Fetch encounter to get medications
        encounter_response = supabase.table('encounters').select(
            'id, medications'
        ).eq('id', encounter_id).single().execute()
        
        if not encounter_response.data:
            raise HTTPException(status_code=404, detail="Encounter not found")
        
        encounter = encounter_response.data
        medications_str = encounter.get('medications', '')
        
        if not medications_str or medications_str.strip() == '':
            raise HTTPException(
                status_code=400,
                detail="No medications found for this encounter"
            )
        
        # Generate PDF
        pdf_bytes = generate_medicine_pdf_from_string(
            medications_str,
            patient_name=patient_name,
            doctor_name=doctor_name
        )
        
        filename = f"medicines_{encounter_id[:8]}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        
        # Return as file download
        pdf_stream = BytesIO(pdf_bytes)
        pdf_stream.seek(0)
        return StreamingResponse(
            pdf_stream,
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename={filename}"}
        )
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error downloading medicine PDF: {e}")
        raise HTTPException(status_code=500, detail=f"Error generating PDF: {str(e)}")


@router.post("/encounter/{encounter_id}/send-pdf")
async def send_medicine_pdf_email(
    encounter_id: str,
    patient_email: str,
    patient_name: str = "Patient",
    doctor_name: str = "Your Doctor"
):
    """
    Generate and email medicine PDF to patient.
    
    This allows sharing medicine information via email without revealing
    the patient's medical conditions.
    
    Args:
        encounter_id: UUID of the encounter
        patient_email: Email address to send to
        patient_name: Name of the patient
        doctor_name: Name of the doctor
    
    Returns:
        Success message
    """
    try:
        uuid.UUID(encounter_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid encounter ID format")
    
    try:
        # Validate email
        if '@' not in patient_email:
            raise HTTPException(status_code=400, detail="Invalid email address")
        
        # Fetch encounter
        encounter_response = supabase.table('encounters').select(
            'id, medications'
        ).eq('id', encounter_id).single().execute()
        
        if not encounter_response.data:
            raise HTTPException(status_code=404, detail="Encounter not found")
        
        encounter = encounter_response.data
        medications_str = encounter.get('medications', '')
        
        if not medications_str or medications_str.strip() == '':
            raise HTTPException(
                status_code=400,
                detail="No medications found for this encounter"
            )
        
        # Generate PDF
        pdf_bytes = generate_medicine_pdf_from_string(
            medications_str,
            patient_name=patient_name,
            doctor_name=doctor_name
        )
        
        # Send email
        import smtplib
        from email.mime.text import MIMEText
        from email.mime.multipart import MIMEMultipart
        from email.mime.base import MIMEBase
        from email import encoders
        
        smtp_email = os.getenv("SMTP_EMAIL")
        smtp_password = os.getenv("SMTP_APP_PASSWORD")
        
        if not smtp_email or not smtp_password:
            raise HTTPException(status_code=500, detail="SMTP email credentials not configured")
        
        # Build email
        msg = MIMEMultipart()
        msg["Subject"] = "MediCoPilot - Your Medication Information"
        msg["From"] = smtp_email
        msg["To"] = patient_email
        
        # Email body
        body = f"""Dear {patient_name},

Your healthcare provider has shared your medication information with you in a secure PDF format.

This document contains details about your prescribed medications including:
- What each medication is for
- How to take it (dosage and frequency)
- Important precautions and side effects
- Storage instructions

This PDF can be safely shared with pharmacists, other healthcare providers, or anyone you choose without revealing your medical diagnosis or conditions.

Please review this information carefully and contact your doctor if you have any questions.

Best regards,
MediCoPilot Medical Assistant
"""
        
        msg.attach(MIMEText(body, "plain"))
        
        # Attach PDF
        filename = f"medicines_{encounter_id[:8]}.pdf"
        attachment = MIMEBase("application", "octet-stream")
        attachment.set_payload(pdf_bytes)
        encoders.encode_base64(attachment)
        attachment.add_header("Content-Disposition", f"attachment; filename= {filename}")
        msg.attach(attachment)
        
        # Send email
        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(smtp_email, smtp_password)
            server.sendmail(smtp_email, patient_email, msg.as_string())
        
        return {
            "success": True,
            "message": f"Medicine PDF sent successfully to {patient_email}"
        }
    
    except HTTPException:
        raise
    except smtplib.SMTPAuthenticationError:
        raise HTTPException(status_code=500, detail="SMTP authentication failed. Check app password.")
    except smtplib.SMTPException as e:
        print(f"SMTP error sending medicine PDF: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to send email: {str(e)}")
    except Exception as e:
        print(f"Error sending medicine PDF: {e}")
        raise HTTPException(status_code=500, detail=f"Error sending medicine PDF: {str(e)}")
