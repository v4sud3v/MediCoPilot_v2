"""
Case-Based Similarity API

Uses NLTK for text preprocessing (tokenization, stopword removal, stemming)
and scikit-learn TF-IDF vectorization + cosine similarity.
No BERT, no torch, no heavy model downloads.

Pipeline:
  1. build_case_text()  — extract clinical fields into one string
  2. preprocess()       — NLTK tokenize → lowercase → remove stopwords → Porter stem
  3. TfidfVectorizer    — fit on all stored case texts + query at search time
  4. cosine_similarity  — rank and return top-K

Endpoints:
  POST /case-similarity/index/{encounter_id}      – index one encounter
  POST /case-similarity/index-all/{doctor_id}      – batch index all encounters for a doctor
  GET  /case-similarity/similar/{encounter_id}     – find similar past cases
  POST /case-similarity/search                     – search by free-text query
"""

import os
import re
import uuid
from typing import List, Optional

import nltk
from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords
from nltk.stem import PorterStemmer

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

from fastapi import APIRouter, HTTPException, Query
from supabase import create_client, Client
from datamodel import (
    SimilarCaseResult,
    SimilarCasesResponse,
    EmbedEncounterResponse,
    FreeTextSearchRequest,
)

# ---------------------------------------------------------------------------
# NLTK setup (download data files once)
# ---------------------------------------------------------------------------
for _pkg in ("punkt", "punkt_tab", "stopwords"):
    nltk.download(_pkg, quiet=True)

_stemmer = PorterStemmer()
_stop_words = set(stopwords.words("english"))

router = APIRouter(prefix="/case-similarity", tags=["Case Similarity"])

# Initialize Supabase client
supabase: Client = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_SECRET_KEY"),
)


# ---------------------------------------------------------------------------
# Text helpers
# ---------------------------------------------------------------------------

def build_case_text(encounter: dict) -> str:
    """
    Build a single text string from encounter fields.
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


def preprocess(text: str) -> str:
    """
    NLTK preprocessing pipeline:
      1. Lowercase
      2. Remove non-alphabetic characters (keep spaces)
      3. Tokenize with word_tokenize
      4. Remove English stopwords
      5. Apply Porter stemming
    Returns a single cleaned string ready for TF-IDF.
    """
    text = text.lower()
    text = re.sub(r"[^a-z\s]", " ", text)
    tokens = word_tokenize(text)
    tokens = [_stemmer.stem(t) for t in tokens if t not in _stop_words and len(t) > 1]
    return " ".join(tokens)


# ---------------------------------------------------------------------------
# TF-IDF similarity (computed at query time — no stored vectors needed)
# ---------------------------------------------------------------------------

def compute_similarity(
    query_text: str,
    case_rows: List[dict],
    top_k: int = 5,
    exclude_encounter_id: Optional[str] = None,
) -> List[dict]:
    """
    1. Preprocess query + all stored case_summary texts
    2. Fit TfidfVectorizer on the combined corpus
    3. Compute cosine similarity between query vector and each case vector
    4. Return top_k results sorted by score descending

    Parameters
    ----------
    query_text : raw clinical text (not yet preprocessed)
    case_rows  : list of dicts from case_embeddings table
    top_k      : number of results to return
    exclude_encounter_id : skip this encounter (self-match)
    """
    if not case_rows:
        return []

    # Filter out the query encounter itself
    filtered = []
    for row in case_rows:
        if exclude_encounter_id and row.get("encounter_id") == exclude_encounter_id:
            continue
        summary = row.get("case_summary", "")
        if summary:
            filtered.append(row)

    if not filtered:
        return []

    # Preprocess all texts: query first, then each case
    query_clean = preprocess(query_text)
    corpus = [query_clean] + [preprocess(r["case_summary"]) for r in filtered]

    # TF-IDF vectorization with unigrams + bigrams
    vectorizer = TfidfVectorizer(ngram_range=(1, 2), max_features=5000)
    tfidf_matrix = vectorizer.fit_transform(corpus)  # sparse matrix (N+1, features)

    query_vec = tfidf_matrix[0:1]   # first row = query
    case_vecs = tfidf_matrix[1:]    # remaining rows = cases

    # Cosine similarity
    sims = cosine_similarity(query_vec, case_vecs)[0]  # shape (N,)

    # Top-K indices
    top_idx = sims.argsort()[::-1][:top_k]

    results = []
    for idx in top_idx:
        entry = {**filtered[idx]}
        entry["similarity_score"] = round(float(sims[idx]), 4)
        # Don't send the raw embedding/summary blob back
        entry.pop("embedding", None)
        results.append(entry)

    return results


# ---------------------------------------------------------------------------
# Supabase helpers
# ---------------------------------------------------------------------------

def store_case_index(encounter_id: str, doctor_id: str, patient_id: str,
                     case_summary: str, diagnosis: str = "",
                     chief_complaint: str = "", treatments: str = ""):
    """
    Insert or update a row in case_embeddings.
    We store the case_summary text (no vector needed — TF-IDF is computed
    at query time).  The embedding column is left empty.
    """
    existing = supabase.table("case_embeddings").select("id").eq(
        "encounter_id", encounter_id
    ).execute()

    row = {
        "encounter_id": encounter_id,
        "doctor_id": doctor_id,
        "patient_id": patient_id,
        "case_summary": case_summary,
        "embedding": "",
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


def fetch_all_cases(doctor_id: Optional[str] = None) -> List[dict]:
    """Fetch all indexed cases, optionally filtered by doctor."""
    query = supabase.table("case_embeddings").select(
        "encounter_id, doctor_id, patient_id, case_summary, "
        "diagnosis, chief_complaint, treatments, created_at"
    )
    if doctor_id:
        query = query.eq("doctor_id", doctor_id)
    return query.execute().data or []


def fetch_all_cases_all_doctors() -> List[dict]:
    """Fetch indexed cases from ALL doctors."""
    return supabase.table("case_embeddings").select(
        "encounter_id, doctor_id, patient_id, case_summary, "
        "diagnosis, chief_complaint, treatments, created_at"
    ).execute().data or []


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _fetch_encounter(encounter_id: str) -> dict:
    """Fetch a single encounter row from Supabase."""
    resp = supabase.table("encounters").select("*").eq(
        "id", encounter_id
    ).maybe_single().execute()
    if not resp.data:
        raise HTTPException(status_code=404, detail=f"Encounter {encounter_id} not found")
    return resp.data


# ------------------------------------------------------------------ routes


@router.post("/index/{encounter_id}", response_model=EmbedEncounterResponse)
async def index_encounter(encounter_id: str):
    """
    Index a single encounter for similarity search.
    Extracts text, preprocesses it, and stores the summary in case_embeddings.
    """
    try:
        uuid.UUID(encounter_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid encounter ID format")

    encounter = _fetch_encounter(encounter_id)
    case_text = build_case_text(encounter)
    if not case_text:
        raise HTTPException(status_code=400, detail="Encounter has no text fields to index")

    store_case_index(
        encounter_id=encounter_id,
        doctor_id=encounter.get("doctor_id", ""),
        patient_id=encounter.get("patient_id", ""),
        case_summary=case_text,
        diagnosis=encounter.get("diagnosis", ""),
        chief_complaint=encounter.get("chief_complaint", ""),
        treatments=encounter.get("medications", ""),
    )

    # Return the preprocessed token count so caller knows what was indexed
    cleaned = preprocess(case_text)
    token_count = len(cleaned.split())

    return EmbedEncounterResponse(
        success=True,
        encounter_id=encounter_id,
        message=f"Encounter indexed successfully ({token_count} stemmed tokens)",
        embedding_dim=token_count,
    )


@router.post("/index-all/{doctor_id}", response_model=dict)
async def index_all_encounters(doctor_id: str):
    """
    Batch-index ALL encounters for a given doctor.
    Useful for initial backfill.
    """
    try:
        uuid.UUID(doctor_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid doctor ID format")

    resp = supabase.table("encounters").select("*").eq("doctor_id", doctor_id).execute()
    encounters = resp.data or []
    if not encounters:
        return {"success": True, "indexed": 0, "message": "No encounters found for this doctor"}

    count = 0
    for enc in encounters:
        text = build_case_text(enc)
        if not text:
            continue
        store_case_index(
            encounter_id=enc["id"],
            doctor_id=enc.get("doctor_id", ""),
            patient_id=enc.get("patient_id", ""),
            case_summary=text,
            diagnosis=enc.get("diagnosis", ""),
            chief_complaint=enc.get("chief_complaint", ""),
            treatments=enc.get("medications", ""),
        )
        count += 1

    return {
        "success": True,
        "indexed": count,
        "message": f"Indexed {count} encounters for doctor {doctor_id}",
    }


@router.get("/similar/{encounter_id}", response_model=SimilarCasesResponse)
async def get_similar_cases(
    encounter_id: str,
    top_k: int = Query(5, ge=1, le=20, description="Number of similar cases to return"),
    same_doctor_only: bool = Query(False, description="Only search within same doctor's cases"),
):
    """
    Find the top-K most similar past cases for a given encounter.

    Pipeline:
      1. Build query text from encounter fields
      2. Fetch all indexed case summaries from Supabase
      3. Preprocess all texts with NLTK (tokenize → stopwords → stem)
      4. Fit TF-IDF vectorizer on the corpus
      5. Compute cosine similarity
      6. Return top-K with treatments, diagnosis, doctor info
    """
    try:
        uuid.UUID(encounter_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid encounter ID format")

    encounter = _fetch_encounter(encounter_id)
    case_text = build_case_text(encounter)
    if not case_text:
        raise HTTPException(status_code=400, detail="Encounter has no text fields to compare")

    # Fetch all indexed cases
    all_cases = fetch_all_cases_all_doctors()
    if not all_cases:
        return SimilarCasesResponse(
            encounter_id=encounter_id,
            query_summary=case_text,
            similar_cases=[],
            total_cases_searched=0,
        )

    # Optionally filter to same doctor
    if same_doctor_only:
        doctor_id = encounter.get("doctor_id")
        all_cases = [c for c in all_cases if c.get("doctor_id") == doctor_id]

    results = compute_similarity(
        query_text=case_text,
        case_rows=all_cases,
        top_k=top_k,
        exclude_encounter_id=encounter_id,
    )

    # Enrich with doctor name
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
        total_cases_searched=len(all_cases),
    )


@router.post("/search", response_model=SimilarCasesResponse)
async def search_by_text(request: FreeTextSearchRequest):
    """
    Search for similar cases using free-text input (e.g. symptoms, diagnosis).
    Useful when a clinician wants to search without an existing encounter.
    """
    if not request.query.strip():
        raise HTTPException(status_code=400, detail="Query text is required")

    all_cases = fetch_all_cases_all_doctors()
    if not all_cases:
        return SimilarCasesResponse(
            encounter_id="",
            query_summary=request.query,
            similar_cases=[],
            total_cases_searched=0,
        )

    results = compute_similarity(
        query_text=request.query,
        case_rows=all_cases,
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
        total_cases_searched=len(all_cases),
    )
