"""
Case-Based Similarity API  —  BERT + ChromaDB Edition
=====================================================

Uses **sentence-transformers** (BERT) to encode clinical encounter text
into dense vectors and **ChromaDB** (local, persistent vector DB) for
fast cosine-similarity search.

Pipeline:
  1. **Vectorisation** — encode encounter text with a BERT sentence model
     (default ``all-MiniLM-L6-v2``, 384-dim).
  2. **Storage** — upsert the vector + metadata into ChromaDB (no Supabase
     storage of embeddings / entities).
  3. **Retrieval** — query ChromaDB with the source encounter (or free text)
     and return the top-K most similar past cases ranked by cosine similarity.

Endpoints:
  POST /case-similarity/index/{encounter_id}      – index one encounter
  POST /case-similarity/index-all/{doctor_id}      – batch-index all for a doctor
  GET  /case-similarity/similar/{encounter_id}     – find similar past cases
  POST /case-similarity/search                     – search by free-text query
  GET  /case-similarity/stats                      – vector DB statistics
"""

import os
import uuid
from typing import Optional

from fastapi import APIRouter, HTTPException, Query
from supabase import create_client, Client

from datamodel import (
    SimilarCaseResult,
    SimilarCasesResponse,
    EmbedEncounterResponse,
    FreeTextSearchRequest,
)
from vector_service import VectorService

router = APIRouter(prefix="/case-similarity", tags=["Case Similarity"])

# Supabase client  (still used to read encounters / doctors — NOT for vectors)
supabase: Client = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_SECRET_KEY"),
)

# Lazy-initialised vector service (model loads on first use)
_vs: Optional[VectorService] = None


def _get_vs() -> VectorService:
    global _vs
    if _vs is None:
        _vs = VectorService.get_instance()
    return _vs


# ---------------------------------------------------------------------------
# Text helpers
# ---------------------------------------------------------------------------

def build_case_text(encounter: dict) -> str:
    """Build a single text string from encounter fields."""
    fields = [
        ("Chief Complaint", encounter.get("chief_complaint")),
        ("Diagnosis", encounter.get("diagnosis")),
        ("History", encounter.get("history_of_illness")),
        ("Physical Exam", encounter.get("physical_exam")),
        ("Medications", encounter.get("medications")),
        ("Allergies", encounter.get("allergies")),
    ]
    parts = [f"{label}: {value}" for label, value in fields if value]
    return " | ".join(parts) if parts else ""


def _fetch_encounter(encounter_id: str) -> dict:
    resp = (
        supabase.table("encounters")
        .select("*")
        .eq("id", encounter_id)
        .maybe_single()
        .execute()
    )
    if not resp.data:
        raise HTTPException(status_code=404, detail=f"Encounter {encounter_id} not found")
    return resp.data


def _doctor_name(doctor_id: str) -> str:
    if not doctor_id:
        return "Unknown"
    doc_resp = (
        supabase.table("doctors")
        .select("name")
        .eq("id", doctor_id)
        .maybe_single()
        .execute()
    )
    return doc_resp.data.get("name", "Unknown") if doc_resp.data else "Unknown"


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@router.post("/index/{encounter_id}", response_model=EmbedEncounterResponse)
async def index_encounter(encounter_id: str):
    """
    Index a single encounter for BERT-based similarity search.

    Encodes the clinical text with a sentence-transformer model and stores
    the resulting vector in ChromaDB.
    """
    try:
        uuid.UUID(encounter_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid encounter ID format")

    encounter = _fetch_encounter(encounter_id)
    case_text = build_case_text(encounter)
    if not case_text:
        raise HTTPException(status_code=400, detail="Encounter has no text fields to index")

    vs = _get_vs()
    dim = vs.index_encounter(
        encounter_id=encounter_id,
        case_text=case_text,
        doctor_id=encounter.get("doctor_id", ""),
        patient_id=encounter.get("patient_id", ""),
        diagnosis=encounter.get("diagnosis", ""),
        chief_complaint=encounter.get("chief_complaint", ""),
        treatments=encounter.get("medications", ""),
    )

    return EmbedEncounterResponse(
        success=True,
        encounter_id=encounter_id,
        message=f"Encounter indexed with BERT ({dim}-dim vector stored in ChromaDB)",
        embedding_dim=dim,
    )


@router.post("/index-all/{doctor_id}", response_model=dict)
async def index_all_encounters(doctor_id: str):
    """Batch-index ALL encounters for a given doctor using BERT."""
    try:
        uuid.UUID(doctor_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid doctor ID format")

    resp = supabase.table("encounters").select("*").eq("doctor_id", doctor_id).execute()
    encounters = resp.data or []
    if not encounters:
        return {"success": True, "indexed": 0, "message": "No encounters found for this doctor"}

    vs = _get_vs()
    batch = []
    for enc in encounters:
        text = build_case_text(enc)
        if not text:
            continue
        batch.append({
            "encounter_id": enc["id"],
            "case_text": text,
            "doctor_id": enc.get("doctor_id", ""),
            "patient_id": enc.get("patient_id", ""),
            "diagnosis": enc.get("diagnosis", ""),
            "chief_complaint": enc.get("chief_complaint", ""),
            "treatments": enc.get("medications", ""),
        })

    count = vs.index_encounters_batch(batch)

    return {
        "success": True,
        "indexed": count,
        "embedding_dim": vs.stats["embedding_dim"],
        "message": f"Indexed {count} encounters for doctor {doctor_id} (BERT + ChromaDB)",
    }


@router.get("/similar/{encounter_id}", response_model=SimilarCasesResponse)
async def get_similar_cases(
    encounter_id: str,
    top_k: int = Query(5, ge=1, le=20, description="Number of similar cases to return"),
    same_doctor_only: bool = Query(False, description="Only search within same doctor's cases"),
):
    """
    Find the top-K most similar past cases using BERT cosine similarity.

    Pipeline:
      1. Encode the query encounter text with BERT
      2. Query ChromaDB for nearest neighbours (cosine)
      3. Return ranked results
    """
    try:
        uuid.UUID(encounter_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid encounter ID format")

    encounter = _fetch_encounter(encounter_id)
    case_text = build_case_text(encounter)
    if not case_text:
        raise HTTPException(status_code=400, detail="Encounter has no text fields to compare")

    vs = _get_vs()

    doctor_id_filter = encounter.get("doctor_id") if same_doctor_only else None

    results = vs.query_similar(
        text=case_text,
        top_k=top_k,
        exclude_id=encounter_id,
        doctor_id=doctor_id_filter,
    )

    similar = [
        SimilarCaseResult(
            encounter_id=r["encounter_id"],
            doctor_id=r.get("doctor_id", ""),
            doctor_name=_doctor_name(r.get("doctor_id", "")),
            patient_id=r.get("patient_id", ""),
            diagnosis=r.get("diagnosis", ""),
            chief_complaint=r.get("chief_complaint", ""),
            treatments=r.get("treatments", ""),
            case_summary=r.get("case_summary", ""),
            similarity_score=r["similarity_score"],
            similarity_method="bert-cosine",
        )
        for r in results
    ]

    return SimilarCasesResponse(
        encounter_id=encounter_id,
        query_summary=case_text,
        similar_cases=similar,
        total_cases_searched=vs.total_indexed,
        similarity_method="BERT + ChromaDB",
    )


@router.post("/search", response_model=SimilarCasesResponse)
async def search_by_text(request: FreeTextSearchRequest):
    """
    Search for similar cases using free-text input (symptoms, diagnosis, etc.).

    Encodes the query with BERT and searches ChromaDB for the nearest cases.
    """
    if not request.query.strip():
        raise HTTPException(status_code=400, detail="Query text is required")

    vs = _get_vs()

    results = vs.query_similar(
        text=request.query,
        top_k=request.top_k,
    )

    similar = [
        SimilarCaseResult(
            encounter_id=r["encounter_id"],
            doctor_id=r.get("doctor_id", ""),
            doctor_name=_doctor_name(r.get("doctor_id", "")),
            patient_id=r.get("patient_id", ""),
            diagnosis=r.get("diagnosis", ""),
            chief_complaint=r.get("chief_complaint", ""),
            treatments=r.get("treatments", ""),
            case_summary=r.get("case_summary", ""),
            similarity_score=r["similarity_score"],
            similarity_method="bert-cosine",
        )
        for r in results
    ]

    return SimilarCasesResponse(
        encounter_id="",
        query_summary=request.query,
        similar_cases=similar,
        total_cases_searched=vs.total_indexed,
        similarity_method="BERT + ChromaDB",
    )


@router.get("/stats")
async def get_stats():
    """Return statistics about the BERT vector service and ChromaDB."""
    vs = _get_vs()
    return {
        "success": True,
        "vector_service": vs.stats,
        "description": (
            "Case similarity uses sentence-transformers (BERT) to encode "
            "clinical text into dense vectors and ChromaDB for fast "
            "cosine-similarity retrieval."
        ),
    }
