"""
Case-Based Similarity API

Uses BERT (bert-base-uncased) to embed encounter text locally — no external
API calls.  Embeddings are stored in the Supabase `case_embeddings` table and
cosine similarity is computed in-process with scikit-learn.

Endpoints:
  POST /case-similarity/embed/{encounter_id}     – embed one encounter
  POST /case-similarity/embed-all/{doctor_id}     – batch embed all encounters for a doctor
  GET  /case-similarity/similar/{encounter_id}    – find similar past cases
  POST /case-similarity/search                    – search by free-text query
"""

import json
import os
import uuid
from typing import List, Optional

import numpy as np
import torch
from transformers import AutoTokenizer, AutoModel
from sklearn.metrics.pairwise import cosine_similarity
from fastapi import APIRouter, HTTPException, Query
from supabase import create_client, Client
from datamodel import (
    SimilarCaseResult,
    SimilarCasesResponse,
    EmbedEncounterResponse,
    FreeTextSearchRequest,
)

router = APIRouter(prefix="/case-similarity", tags=["Case Similarity"])

# Initialize Supabase client
supabase: Client = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_SECRET_KEY"),
)


# ---------------------------------------------------------------------------
# BERT model loading (lazy singleton so import is cheap)
# ---------------------------------------------------------------------------
_tokenizer = None
_model = None


def _load_model():
    """Load BERT model and tokenizer once. Uses bert-base-uncased (768-dim)."""
    global _tokenizer, _model
    if _tokenizer is None or _model is None:
        model_name = "bert-base-uncased"
        print(f"[CaseSimilarity] Loading BERT model: {model_name} ...")
        _tokenizer = AutoTokenizer.from_pretrained(model_name)
        _model = AutoModel.from_pretrained(model_name)
        _model.eval()  # inference mode
        print("[CaseSimilarity] BERT model loaded.")
    return _tokenizer, _model


# ---------------------------------------------------------------------------
# Text helpers
# ---------------------------------------------------------------------------

def build_case_text(encounter: dict) -> str:
    """
    Build a single text string from encounter fields for embedding.
    Only includes non-empty fields.
    """
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


# ---------------------------------------------------------------------------
# Embedding
# ---------------------------------------------------------------------------

def embed_text(text: str) -> np.ndarray:
    """
    Produce a 768-dim embedding for *text* using BERT mean-pooling.

    Steps:
      1. Tokenize (truncate at 512 tokens).
      2. Forward pass through BERT -> last_hidden_state.
      3. Mean-pool across non-padding tokens.
      4. L2-normalize for cosine similarity.

    Returns a 1-D numpy array of shape (768,).
    """
    tokenizer, model = _load_model()

    encoded = tokenizer(
        text,
        padding=True,
        truncation=True,
        max_length=512,
        return_tensors="pt",
    )

    with torch.no_grad():
        outputs = model(**encoded)

    attention_mask = encoded["attention_mask"]
    token_embeddings = outputs.last_hidden_state
    mask_expanded = attention_mask.unsqueeze(-1).float()
    sum_embeddings = (token_embeddings * mask_expanded).sum(dim=1)
    sum_mask = mask_expanded.sum(dim=1).clamp(min=1e-9)
    mean_pooled = sum_embeddings / sum_mask

    vec = mean_pooled.squeeze(0).numpy()
    norm = np.linalg.norm(vec)
    if norm > 0:
        vec = vec / norm
    return vec


def embed_text_batch(texts: List[str], batch_size: int = 16) -> np.ndarray:
    """
    Embed multiple texts efficiently in batches.
    Returns shape (N, 768).
    """
    tokenizer, model = _load_model()
    all_vecs = []

    for i in range(0, len(texts), batch_size):
        batch = texts[i : i + batch_size]
        encoded = tokenizer(
            batch,
            padding=True,
            truncation=True,
            max_length=512,
            return_tensors="pt",
        )
        with torch.no_grad():
            outputs = model(**encoded)

        attention_mask = encoded["attention_mask"]
        token_embeddings = outputs.last_hidden_state
        mask_expanded = attention_mask.unsqueeze(-1).float()
        sum_embeddings = (token_embeddings * mask_expanded).sum(dim=1)
        sum_mask = mask_expanded.sum(dim=1).clamp(min=1e-9)
        mean_pooled = sum_embeddings / sum_mask

        vecs = mean_pooled.numpy()
        norms = np.linalg.norm(vecs, axis=1, keepdims=True)
        norms = np.where(norms > 0, norms, 1e-9)
        vecs = vecs / norms
        all_vecs.append(vecs)

    return np.vstack(all_vecs)


# ---------------------------------------------------------------------------
# Similarity search (in-memory cosine similarity)
# ---------------------------------------------------------------------------

def find_similar(
    query_vec: np.ndarray,
    stored_embeddings: List[dict],
    top_k: int = 5,
    exclude_encounter_id: Optional[str] = None,
) -> List[dict]:
    """
    Return top_k most similar cases from *stored_embeddings*.
    Each dict must have an "embedding" key (JSON string or list of floats).
    """
    if not stored_embeddings:
        return []

    matrix_rows = []
    meta = []

    for row in stored_embeddings:
        eid = row.get("encounter_id")
        if exclude_encounter_id and eid == exclude_encounter_id:
            continue
        emb = row.get("embedding")
        if isinstance(emb, str):
            emb = json.loads(emb)
        if emb is None:
            continue
        matrix_rows.append(emb)
        meta.append(row)

    if not matrix_rows:
        return []

    matrix = np.array(matrix_rows, dtype=np.float32)
    sims = cosine_similarity(query_vec.reshape(1, -1), matrix)[0]

    top_idx = sims.argsort()[::-1][:top_k]

    results = []
    for idx in top_idx:
        entry = {**meta[idx]}
        entry["similarity_score"] = round(float(sims[idx]), 4)
        entry.pop("embedding", None)
        results.append(entry)

    return results


# ---------------------------------------------------------------------------
# Supabase helpers
# ---------------------------------------------------------------------------

def store_embedding(encounter_id: str, doctor_id: str,
                    patient_id: str, case_summary: str, embedding: np.ndarray,
                    diagnosis: str = "", chief_complaint: str = "",
                    treatments: str = ""):
    """Insert or upsert an embedding row into the case_embeddings table."""
    vec_list = embedding.tolist()

    existing = supabase.table("case_embeddings").select("id").eq(
        "encounter_id", encounter_id
    ).execute()

    row = {
        "encounter_id": encounter_id,
        "doctor_id": doctor_id,
        "patient_id": patient_id,
        "case_summary": case_summary,
        "embedding": json.dumps(vec_list),
        "diagnosis": diagnosis or "",
        "chief_complaint": chief_complaint or "",
        "treatments": treatments or "",
    }

    if existing.data:
        supabase.table("case_embeddings").update(row).eq(
            "encounter_id", encounter_id
        ).execute()
    else:
        supabase.table("case_embeddings").insert(row).execute()


def fetch_all_embeddings(doctor_id: Optional[str] = None) -> List[dict]:
    """Fetch stored embeddings, optionally filtered by doctor_id."""
    query = supabase.table("case_embeddings").select(
        "encounter_id, doctor_id, patient_id, case_summary, embedding, "
        "diagnosis, chief_complaint, treatments, created_at"
    )
    if doctor_id:
        query = query.eq("doctor_id", doctor_id)
    return query.execute().data or []


def fetch_all_embeddings_all_doctors() -> List[dict]:
    """Fetch embeddings from ALL doctors for cross-doctor similarity."""
    return supabase.table("case_embeddings").select(
        "encounter_id, doctor_id, patient_id, case_summary, embedding, "
        "diagnosis, chief_complaint, treatments, created_at"
    ).execute().data or []


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _fetch_encounter(encounter_id: str) -> dict:
    """Fetch a single encounter row from Supabase."""
    resp = supabase.table("encounters").select("*").eq("id", encounter_id).maybe_single().execute()
    if not resp.data:
        raise HTTPException(status_code=404, detail=f"Encounter {encounter_id} not found")
    return resp.data


# ------------------------------------------------------------------ routes


@router.post("/embed/{encounter_id}", response_model=EmbedEncounterResponse)
async def embed_encounter(encounter_id: str):
    """
    Generate a BERT embedding for a single encounter and store it.
    Call this after saving / updating an encounter.
    """
    try:
        uuid.UUID(encounter_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid encounter ID format")

    encounter = _fetch_encounter(encounter_id)
    case_text = build_case_text(encounter)
    if not case_text:
        raise HTTPException(status_code=400, detail="Encounter has no text fields to embed")

    vec = embed_text(case_text)
    store_embedding(
        encounter_id=encounter_id,
        doctor_id=encounter.get("doctor_id", ""),
        patient_id=encounter.get("patient_id", ""),
        case_summary=case_text,
        embedding=vec,
        diagnosis=encounter.get("diagnosis", ""),
        chief_complaint=encounter.get("chief_complaint", ""),
        treatments=encounter.get("medications", ""),
    )

    return EmbedEncounterResponse(
        success=True,
        encounter_id=encounter_id,
        message="Encounter embedded successfully",
        embedding_dim=len(vec),
    )


@router.post("/embed-all/{doctor_id}", response_model=dict)
async def embed_all_encounters(doctor_id: str):
    """
    Batch-embed ALL encounters for a given doctor.
    Useful for initial backfill.
    """
    try:
        uuid.UUID(doctor_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid doctor ID format")

    # Fetch all encounters for this doctor
    resp = supabase.table("encounters").select("*").eq("doctor_id", doctor_id).execute()
    encounters = resp.data or []
    if not encounters:
        return {"success": True, "embedded": 0, "message": "No encounters found for this doctor"}

    texts = []
    valid_encounters = []
    for enc in encounters:
        t = build_case_text(enc)
        if t:
            texts.append(t)
            valid_encounters.append(enc)

    if not texts:
        return {"success": True, "embedded": 0, "message": "No encounters with text to embed"}

    # Batch embed
    vecs = embed_text_batch(texts, batch_size=16)

    # Store each
    for enc, vec, text in zip(valid_encounters, vecs, texts):
        store_embedding(
            encounter_id=enc["id"],
            doctor_id=enc.get("doctor_id", ""),
            patient_id=enc.get("patient_id", ""),
            case_summary=text,
            embedding=vec,
            diagnosis=enc.get("diagnosis", ""),
            chief_complaint=enc.get("chief_complaint", ""),
            treatments=enc.get("medications", ""),
        )

    return {
        "success": True,
        "embedded": len(valid_encounters),
        "message": f"Embedded {len(valid_encounters)} encounters for doctor {doctor_id}",
    }


@router.get("/similar/{encounter_id}", response_model=SimilarCasesResponse)
async def get_similar_cases(
    encounter_id: str,
    top_k: int = Query(5, ge=1, le=20, description="Number of similar cases to return"),
    same_doctor_only: bool = Query(False, description="Only search within same doctor's cases"),
):
    """
    Find the top-K most similar past cases for a given encounter.

    Returns similar cases with their treatments, diagnosis, and similarity score
    so the clinician can compare treatment approaches and outcomes.
    """
    try:
        uuid.UUID(encounter_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid encounter ID format")

    encounter = _fetch_encounter(encounter_id)

    # Build query embedding
    case_text = build_case_text(encounter)
    if not case_text:
        raise HTTPException(status_code=400, detail="Encounter has no text fields to compare")

    query_vec = embed_text(case_text)

    # Fetch stored embeddings
    all_embeddings = fetch_all_embeddings_all_doctors()
    if not all_embeddings:
        return SimilarCasesResponse(
            encounter_id=encounter_id,
            query_summary=case_text,
            similar_cases=[],
            total_cases_searched=0,
        )

    # Optionally filter to same doctor
    if same_doctor_only:
        doctor_id = encounter.get("doctor_id")
        all_embeddings = [e for e in all_embeddings if e.get("doctor_id") == doctor_id]

    results = find_similar(
        query_vec=query_vec,
        stored_embeddings=all_embeddings,
        top_k=top_k,
        exclude_encounter_id=encounter_id,
    )

    # Enrich results with doctor name
    for r in results:
        did = r.get("doctor_id")
        if did:
            doc_resp = supabase.table("doctors").select("name").eq("id", did).maybe_single().execute()
            r["doctor_name"] = doc_resp.data.get("name", "Unknown") if doc_resp.data else "Unknown"
        else:
            r["doctor_name"] = "Unknown"

    similar = [
        SimilarCaseResult(
            encounter_id=r["encounter_id"],
            doctor_id=r.get("doctor_id", ""),
            doctor_name=r.get("doctor_name", ""),
            patient_id=r.get("patient_id", ""),
            diagnosis=r.get("diagnosis", ""),
            chief_complaint=r.get("chief_complaint", ""),
            treatments=r.get("treatments", ""),
            case_summary=r.get("case_summary", ""),
            similarity_score=r["similarity_score"],
            created_at=r.get("created_at", ""),
        )
        for r in results
    ]

    return SimilarCasesResponse(
        encounter_id=encounter_id,
        query_summary=case_text,
        similar_cases=similar,
        total_cases_searched=len(all_embeddings),
    )


@router.post("/search", response_model=SimilarCasesResponse)
async def search_by_text(request: FreeTextSearchRequest):
    """
    Search for similar cases using free-text input (e.g. symptoms, diagnosis).
    Useful when a clinician wants to search without an existing encounter.
    """
    if not request.query.strip():
        raise HTTPException(status_code=400, detail="Query text is required")

    query_vec = embed_text(request.query)

    all_embeddings = fetch_all_embeddings_all_doctors()
    if not all_embeddings:
        return SimilarCasesResponse(
            encounter_id="",
            query_summary=request.query,
            similar_cases=[],
            total_cases_searched=0,
        )

    results = find_similar(
        query_vec=query_vec,
        stored_embeddings=all_embeddings,
        top_k=request.top_k,
    )

    for r in results:
        did = r.get("doctor_id")
        if did:
            doc_resp = supabase.table("doctors").select("name").eq("id", did).maybe_single().execute()
            r["doctor_name"] = doc_resp.data.get("name", "Unknown") if doc_resp.data else "Unknown"
        else:
            r["doctor_name"] = "Unknown"

    similar = [
        SimilarCaseResult(
            encounter_id=r["encounter_id"],
            doctor_id=r.get("doctor_id", ""),
            doctor_name=r.get("doctor_name", ""),
            patient_id=r.get("patient_id", ""),
            diagnosis=r.get("diagnosis", ""),
            chief_complaint=r.get("chief_complaint", ""),
            treatments=r.get("treatments", ""),
            case_summary=r.get("case_summary", ""),
            similarity_score=r["similarity_score"],
            created_at=r.get("created_at", ""),
        )
        for r in results
    ]

    return SimilarCasesResponse(
        encounter_id="",
        query_summary=request.query,
        similar_cases=similar,
        total_cases_searched=len(all_embeddings),
    )
