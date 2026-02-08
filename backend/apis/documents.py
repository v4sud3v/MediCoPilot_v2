from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from fastapi.responses import StreamingResponse
from supabase import create_client, Client
from pydantic import BaseModel
from typing import Optional, List, Literal
import os
import uuid
import io
import httpx
from datetime import datetime

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


@router.post("/upload-file", response_model=DocumentUploadResponse)
async def upload_file_to_storage(
    file: UploadFile = File(...),
    encounter_id: str = Form(...),
    document_type: str = Form(...),
    extracted_text: Optional[str] = Form(None)
):
    """
    Upload a file to Supabase Storage and save document record.

    Args:
        file: The file to upload
        encounter_id: UUID of the encounter this document belongs to
        document_type: Type of document (XRAY or REPORT)
        extracted_text: Optional OCR or extracted text from the document

    Returns:
        Success status and the created document record with Supabase Storage URL
    """
    try:
        # Validate encounter_id format
        try:
            uuid.UUID(encounter_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid encounter ID format")

        # Verify encounter exists
        try:
            encounter_check = supabase.table('encounters').select('id').eq(
                'id', encounter_id
            ).maybe_single().execute()

            if not encounter_check.data:
                raise HTTPException(status_code=404, detail="Encounter not found")
        except Exception as e:
            print(f"Error checking encounter: {e}")
            raise HTTPException(status_code=500, detail=f"Error verifying encounter: {str(e)}")

        # Validate document type
        if document_type not in ["XRAY", "REPORT"]:
            raise HTTPException(status_code=400, detail="Invalid document type. Must be XRAY or REPORT")

        # Read file content
        file_content = await file.read()

        # Generate unique filename
        file_extension = os.path.splitext(file.filename)[1]
        unique_filename = f"{encounter_id}/{datetime.now().strftime('%Y%m%d_%H%M%S')}_{uuid.uuid4().hex[:8]}{file_extension}"

        # Upload to Supabase Storage
        bucket_name = "files"

        try:
            storage_response = supabase.storage.from_(bucket_name).upload(
                path=unique_filename,
                file=file_content,
                file_options={"content-type": file.content_type}
            )

            # Get public URL
            public_url = supabase.storage.from_(bucket_name).get_public_url(unique_filename)

        except Exception as storage_error:
            print(f"Storage upload error: {storage_error}")
            raise HTTPException(status_code=500, detail=f"Failed to upload file to storage: {str(storage_error)}")

        # Create document record with Supabase Storage URL
        document_data = {
            'encounter_id': encounter_id,
            'file_url': public_url,
            'document_type': document_type,
            'extracted_text': extracted_text
        }

        response = supabase.table('documents').insert(document_data).execute()

        if not response.data:
            raise HTTPException(status_code=500, detail="Failed to create document record")

        created_doc = response.data[0]

        print(f"Document uploaded to storage and saved: {created_doc['id']} for encounter {encounter_id}")

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


@router.post("/upload", response_model=DocumentUploadResponse)
async def upload_document(request: DocumentUploadRequest):
    """
    Save a document record to Supabase (legacy endpoint for local file paths).

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
        try:
            encounter_check = supabase.table('encounters').select('id').eq(
                'id', request.encounter_id
            ).maybe_single().execute()

            if not encounter_check.data:
                raise HTTPException(status_code=404, detail="Encounter not found")
        except Exception as e:
            print(f"Error checking encounter: {e}")
            raise HTTPException(status_code=500, detail=f"Error verifying encounter: {str(e)}")

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
    Delete a document record and its file from Supabase Storage.

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

        # Check if document exists and get file_url
        try:
            check_response = supabase.table('documents').select('id, file_url').eq(
                'id', document_id
            ).maybe_single().execute()

            if not check_response.data:
                raise HTTPException(status_code=404, detail="Document not found")
        except Exception as e:
            print(f"Error checking document: {e}")
            raise HTTPException(status_code=500, detail=f"Error verifying document: {str(e)}")

        file_url = check_response.data.get('file_url', '')

        # Delete from Supabase Storage if URL is from Supabase
        if file_url and 'supabase' in file_url:
            try:
                # Extract the file path from the public URL
                # Format: https://{project}.supabase.co/storage/v1/object/public/{bucket}/{path}
                bucket_name = "files"

                # Extract path after the bucket name
                if f'/object/public/{bucket_name}/' in file_url:
                    file_path = file_url.split(f'/object/public/{bucket_name}/')[1]

                    # Delete from storage
                    supabase.storage.from_(bucket_name).remove([file_path])
                    print(f"Deleted file from storage: {file_path}")
            except Exception as storage_error:
                print(f"Warning: Could not delete file from storage: {storage_error}")
                # Continue with database deletion even if storage deletion fails

        # Delete the document record
        supabase.table('documents').delete().eq('id', document_id).execute()

        return {"success": True, "message": "Document deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error deleting document: {e}")
        raise HTTPException(status_code=500, detail=f"Error deleting document: {str(e)}")


def _extract_storage_path(file_url: str) -> Optional[str]:
    """Extract the storage path from a Supabase public or signed URL."""
    bucket_name = "files"
    if f'/object/public/{bucket_name}/' in file_url:
        return file_url.split(f'/object/public/{bucket_name}/')[1].split('?')[0]
    if f'/object/sign/{bucket_name}/' in file_url:
        return file_url.split(f'/object/sign/{bucket_name}/')[1].split('?')[0]
    # Fallback: try to find anything after /files/
    if f'/{bucket_name}/' in file_url:
        return file_url.split(f'/{bucket_name}/')[-1].split('?')[0]
    return None


@router.get("/{document_id}/signed-url")
async def get_signed_url(document_id: str):
    """
    Generate a signed URL for a document stored in Supabase Storage.
    The signed URL is valid for 1 hour (3600 seconds).
    """
    try:
        try:
            uuid.UUID(document_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid document ID format")

        # Fetch the document record
        response = supabase.table('documents').select('id, file_url').eq(
            'id', document_id
        ).maybe_single().execute()

        if not response.data:
            raise HTTPException(status_code=404, detail="Document not found")

        file_url = response.data.get('file_url', '')

        if not file_url or 'supabase' not in file_url:
            # Not a Supabase Storage URL, return as-is
            return {"signed_url": file_url}

        # Extract the storage path
        file_path = _extract_storage_path(file_url)
        if not file_path:
            raise HTTPException(status_code=400, detail="Could not extract storage path from URL")

        # Generate signed URL (valid for 1 hour)
        bucket_name = "files"
        signed = supabase.storage.from_(bucket_name).create_signed_url(
            file_path, 3600  # 1 hour
        )

        if not signed or 'signedURL' not in signed:
            raise HTTPException(status_code=500, detail="Failed to generate signed URL")

        return {"signed_url": signed['signedURL']}

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error generating signed URL: {e}")
        raise HTTPException(status_code=500, detail=f"Error generating signed URL: {str(e)}")


@router.get("/{document_id}/download")
async def download_document(document_id: str):
    """
    Download a document's file content by proxying through the backend.
    This works regardless of bucket public/private settings.
    Returns the raw file bytes with appropriate content type.
    """
    try:
        try:
            uuid.UUID(document_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid document ID format")

        # Fetch the document record
        response = supabase.table('documents').select('id, file_url, document_type').eq(
            'id', document_id
        ).maybe_single().execute()

        if not response.data:
            raise HTTPException(status_code=404, detail="Document not found")

        file_url = response.data.get('file_url', '')

        if not file_url:
            raise HTTPException(status_code=400, detail="No file URL found for this document")

        # If it's a Supabase URL, download via storage API
        if 'supabase' in file_url:
            file_path = _extract_storage_path(file_url)
            if not file_path:
                raise HTTPException(status_code=400, detail="Could not extract storage path")

            bucket_name = "files"
            try:
                file_bytes = supabase.storage.from_(bucket_name).download(file_path)
            except Exception as storage_error:
                print(f"Storage download error: {storage_error}")
                raise HTTPException(
                    status_code=500,
                    detail=f"Failed to download from storage: {str(storage_error)}"
                )
        else:
            # For non-Supabase URLs, fetch directly
            async with httpx.AsyncClient() as client:
                resp = await client.get(file_url, timeout=30.0)
                if resp.status_code != 200:
                    raise HTTPException(
                        status_code=resp.status_code,
                        detail=f"Failed to download file (HTTP {resp.status_code})"
                    )
                file_bytes = resp.content

        # Determine content type
        lower_url = file_url.lower()
        if lower_url.endswith('.png'):
            content_type = 'image/png'
        elif lower_url.endswith('.jpg') or lower_url.endswith('.jpeg'):
            content_type = 'image/jpeg'
        elif lower_url.endswith('.gif'):
            content_type = 'image/gif'
        elif lower_url.endswith('.pdf'):
            content_type = 'application/pdf'
        elif lower_url.endswith('.webp'):
            content_type = 'image/webp'
        else:
            content_type = 'application/octet-stream'

        return StreamingResponse(
            io.BytesIO(file_bytes),
            media_type=content_type,
            headers={"Content-Disposition": f"inline"}
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error downloading document: {e}")
        raise HTTPException(status_code=500, detail=f"Error downloading document: {str(e)}")
