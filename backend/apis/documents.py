from fastapi import APIRouter, HTTPException
from supabase import create_client, Client
from pydantic import BaseModel
from typing import Optional, List, Literal
import os
import uuid

router = APIRouter(prefix="/documents", tags=["Documents"])

# Initialize Supabase client
supabase: Client = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_SECRET_KEY")
)


class DocumentUploadRequest(BaseModel):
    encounter_id: str
    file_url: str  # Local path or storage URL
    document_type: Literal["XRAY", "REPORT"]  # XRAY for X-Ray, REPORT for Lab Notes
    extracted_text: Optional[str] = None


class DocumentResponse(BaseModel):
    id: str
    encounter_id: str
    file_url: str
    document_type: str
    extracted_text: Optional[str] = None
    created_at: str


class DocumentUploadResponse(BaseModel):
    success: bool
    message: str
    document: Optional[DocumentResponse] = None


@router.post("/upload", response_model=DocumentUploadResponse)
async def upload_document(request: DocumentUploadRequest):
    """
    Save a document record to Supabase.
    
    Args:
        encounter_id: UUID of the encounter this document belongs to
        file_url: Path or URL where the file is stored
        document_type: Type of document (XRAY or REPORT)
        extracted_text: Optional OCR or extracted text from the document
    
    Returns:
        Success status and the created document record
    """
    try:
        # Validate encounter_id format
        try:
            uuid.UUID(request.encounter_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid encounter ID format")

        # Verify encounter exists
        encounter_check = supabase.table('encounters').select('id').eq(
            'id', request.encounter_id
        ).single().execute()
        
        if not encounter_check.data:
            raise HTTPException(status_code=404, detail="Encounter not found")

        # Create document record
        document_data = {
            'encounter_id': request.encounter_id,
            'file_url': request.file_url,
            'document_type': request.document_type,
            'extracted_text': request.extracted_text
        }

        response = supabase.table('documents').insert(document_data).execute()

        if not response.data:
            raise HTTPException(status_code=500, detail="Failed to create document record")

        created_doc = response.data[0]
        
        print(f"Document saved: {created_doc['id']} for encounter {request.encounter_id}")

        return DocumentUploadResponse(
            success=True,
            message="Document uploaded successfully",
            document=DocumentResponse(
                id=created_doc['id'],
                encounter_id=created_doc['encounter_id'],
                file_url=created_doc['file_url'],
                document_type=created_doc['document_type'],
                extracted_text=created_doc.get('extracted_text'),
                created_at=created_doc['created_at']
            )
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error uploading document: {e}")
        raise HTTPException(status_code=500, detail=f"Error uploading document: {str(e)}")


@router.get("/encounter/{encounter_id}", response_model=List[DocumentResponse])
async def get_documents_for_encounter(encounter_id: str):
    """
    Fetch all documents for a specific encounter.
    
    Args:
        encounter_id: UUID of the encounter
    
    Returns:
        List of documents for the encounter
    """
    try:
        # Validate encounter_id format
        try:
            uuid.UUID(encounter_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid encounter ID format")

        response = supabase.table('documents').select(
            'id, encounter_id, file_url, document_type, extracted_text, created_at'
        ).eq(
            'encounter_id', encounter_id
        ).order(
            'created_at', desc=True
        ).execute()

        if not response.data:
            return []

        return [
            DocumentResponse(
                id=doc['id'],
                encounter_id=doc['encounter_id'],
                file_url=doc['file_url'],
                document_type=doc['document_type'],
                extracted_text=doc.get('extracted_text'),
                created_at=doc['created_at']
            )
            for doc in response.data
        ]

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error fetching documents: {e}")
        raise HTTPException(status_code=500, detail=f"Error fetching documents: {str(e)}")


@router.delete("/{document_id}")
async def delete_document(document_id: str):
    """
    Delete a document record.
    
    Args:
        document_id: UUID of the document to delete
    
    Returns:
        Success status
    """
    try:
        # Validate document_id format
        try:
            uuid.UUID(document_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid document ID format")

        # Check if document exists
        check_response = supabase.table('documents').select('id').eq(
            'id', document_id
        ).single().execute()
        
        if not check_response.data:
            raise HTTPException(status_code=404, detail="Document not found")

        # Delete the document
        supabase.table('documents').delete().eq('id', document_id).execute()

        return {"success": True, "message": "Document deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error deleting document: {e}")
        raise HTTPException(status_code=500, detail=f"Error deleting document: {str(e)}")
