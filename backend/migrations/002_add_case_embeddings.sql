-- Migration 002: Remove case_embeddings table
-- Embeddings are now stored in ChromaDB (local vector database), not Supabase.
-- Run this in the Supabase SQL editor to clean up.

DROP TABLE IF EXISTS public.case_embeddings;

-- The case similarity system now uses:
--   * sentence-transformers (BERT) for vectorisation
--   * ChromaDB for persistent vector storage and cosine-similarity queries
-- No Supabase tables are needed for similarity search.
