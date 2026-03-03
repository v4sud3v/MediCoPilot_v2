"""
BERT + ChromaDB Vector Service
==============================

Provides semantic vectorisation of clinical encounter text using
sentence-transformers (a BERT-based model) and stores / queries
embeddings in a local ChromaDB persistent vector database.

This replaces the previous Knowledge Graph entity-based approach
and the Supabase case_embeddings table.

Model: ``all-MiniLM-L6-v2``  (384-dim, fast, good quality)
       — swap for ``dmis-lab/biobert-base-cased-v1.2`` or
         ``pritamdeka/BioBERT-mnli-snli-scinli-scitail-mednli-stsb``
         if you want a biomedical-domain model at the cost of speed.

ChromaDB collection schema (metadata per document):
  - encounter_id   (str)
  - doctor_id      (str)
  - patient_id     (str)
  - diagnosis      (str)
  - chief_complaint(str)
  - treatments     (str)
"""

from __future__ import annotations

import os
import logging
from typing import List, Optional, Dict, Any

import chromadb
from chromadb.config import Settings as ChromaSettings
from sentence_transformers import SentenceTransformer

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# BERT model — change to a biomedical model for domain-specific accuracy
BERT_MODEL_NAME = os.getenv(
    "BERT_MODEL_NAME",
    "all-MiniLM-L6-v2",
)

# Where ChromaDB persists data on disk
CHROMA_PERSIST_DIR = os.getenv(
    "CHROMA_PERSIST_DIR",
    os.path.join(os.path.dirname(__file__), ".chromadb"),
)

# ChromaDB collection name
CHROMA_COLLECTION = os.getenv("CHROMA_COLLECTION", "case_embeddings")


# ---------------------------------------------------------------------------
# Singleton service
# ---------------------------------------------------------------------------

class VectorService:
    """Singleton: load model + ChromaDB once, reuse everywhere."""

    _instance: Optional["VectorService"] = None

    def __init__(self) -> None:
        logger.info("Loading BERT model '%s' …", BERT_MODEL_NAME)
        self._model = SentenceTransformer(BERT_MODEL_NAME)
        self._embedding_dim = self._model.get_sentence_embedding_dimension()
        logger.info(
            "BERT model loaded  (dim=%d, persist=%s)",
            self._embedding_dim,
            CHROMA_PERSIST_DIR,
        )

        # Persistent ChromaDB client
        self._chroma = chromadb.Client(
            ChromaSettings(
                persist_directory=CHROMA_PERSIST_DIR,
                anonymized_telemetry=False,
                is_persistent=True,
            )
        )
        self._collection = self._chroma.get_or_create_collection(
            name=CHROMA_COLLECTION,
            metadata={"hnsw:space": "cosine"},   # cosine similarity
        )
        logger.info(
            "ChromaDB collection '%s' ready  (%d documents)",
            CHROMA_COLLECTION,
            self._collection.count(),
        )

    # ---- class-level singleton accessor -----------------------------------

    @classmethod
    def get_instance(cls) -> "VectorService":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    # ---- encoding ---------------------------------------------------------

    def encode(self, text: str) -> List[float]:
        """Return a BERT embedding for *text* (list of floats)."""
        return self._model.encode(text, normalize_embeddings=True).tolist()

    def encode_batch(self, texts: List[str]) -> List[List[float]]:
        """Batch-encode multiple strings."""
        return self._model.encode(texts, normalize_embeddings=True).tolist()

    # ---- indexing ---------------------------------------------------------

    def index_encounter(
        self,
        encounter_id: str,
        case_text: str,
        doctor_id: str = "",
        patient_id: str = "",
        diagnosis: str = "",
        chief_complaint: str = "",
        treatments: str = "",
    ) -> int:
        """
        Index (upsert) a single encounter into ChromaDB.

        Returns the embedding dimensionality.
        """
        embedding = self.encode(case_text)

        metadata: Dict[str, Any] = {
            "doctor_id": doctor_id or "",
            "patient_id": patient_id or "",
            "diagnosis": diagnosis or "",
            "chief_complaint": chief_complaint or "",
            "treatments": treatments or "",
        }

        # Upsert — ChromaDB uses the `ids` list as unique keys
        self._collection.upsert(
            ids=[encounter_id],
            embeddings=[embedding],
            documents=[case_text],
            metadatas=[metadata],
        )
        return self._embedding_dim

    def index_encounters_batch(
        self,
        encounters: List[Dict[str, Any]],
    ) -> int:
        """
        Batch-upsert many encounters.  Each dict must contain at least
        ``encounter_id`` and ``case_text`` keys.

        Returns the number of successfully indexed encounters.
        """
        if not encounters:
            return 0

        ids = [e["encounter_id"] for e in encounters]
        texts = [e["case_text"] for e in encounters]
        metas = [
            {
                "doctor_id": e.get("doctor_id", ""),
                "patient_id": e.get("patient_id", ""),
                "diagnosis": e.get("diagnosis", ""),
                "chief_complaint": e.get("chief_complaint", ""),
                "treatments": e.get("treatments", ""),
            }
            for e in encounters
        ]
        embeddings = self.encode_batch(texts)

        self._collection.upsert(
            ids=ids,
            embeddings=embeddings,
            documents=texts,
            metadatas=metas,
        )
        return len(ids)

    # ---- querying ---------------------------------------------------------

    def query_similar(
        self,
        text: str,
        top_k: int = 5,
        exclude_id: Optional[str] = None,
        doctor_id: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """
        Find top-K similar cases to *text*.

        Returns a list of dicts, each with:
          encounter_id, similarity_score, case_summary, + all metadata fields.
        """
        # Request extra results so we can filter and still return top_k
        n_results = top_k + (2 if exclude_id else 0)

        where_filter = None
        if doctor_id:
            where_filter = {"doctor_id": doctor_id}

        results = self._collection.query(
            query_embeddings=[self.encode(text)],
            n_results=min(n_results, self._collection.count() or 1),
            where=where_filter,
            include=["documents", "metadatas", "distances"],
        )

        # Unpack ChromaDB response (lists of lists — one inner list per query)
        ids = results.get("ids", [[]])[0]
        docs = results.get("documents", [[]])[0]
        metas = results.get("metadatas", [[]])[0]
        distances = results.get("distances", [[]])[0]

        output: List[Dict[str, Any]] = []
        for i, eid in enumerate(ids):
            if exclude_id and eid == exclude_id:
                continue

            # ChromaDB cosine distance = 1 - cosine_sim  →  convert back
            cosine_sim = 1.0 - distances[i]

            output.append({
                "encounter_id": eid,
                "similarity_score": round(cosine_sim, 4),
                "case_summary": docs[i] if docs else "",
                **(metas[i] if metas else {}),
            })

            if len(output) >= top_k:
                break

        return output

    # ---- collection stats -------------------------------------------------

    @property
    def stats(self) -> Dict[str, Any]:
        return {
            "model": BERT_MODEL_NAME,
            "embedding_dim": self._embedding_dim,
            "total_indexed": self._collection.count(),
            "persist_dir": CHROMA_PERSIST_DIR,
            "collection": CHROMA_COLLECTION,
        }

    @property
    def total_indexed(self) -> int:
        return self._collection.count()

    # ---- admin ------------------------------------------------------------

    def delete_encounter(self, encounter_id: str) -> None:
        """Remove a single encounter from the index."""
        self._collection.delete(ids=[encounter_id])

    def reset_collection(self) -> None:
        """Drop and re-create the collection (destructive!)."""
        self._chroma.delete_collection(CHROMA_COLLECTION)
        self._collection = self._chroma.get_or_create_collection(
            name=CHROMA_COLLECTION,
            metadata={"hnsw:space": "cosine"},
        )
