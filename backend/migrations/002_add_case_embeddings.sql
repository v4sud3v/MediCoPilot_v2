-- Migration: Add case_embeddings table for case-based similarity
-- Run this in the Supabase SQL editor

CREATE TABLE IF NOT EXISTS public.case_embeddings (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    encounter_id uuid NOT NULL,
    doctor_id uuid,
    patient_id uuid,
    case_summary text,
    embedding text,           -- JSON array of 768 floats (BERT base)
    diagnosis text,
    chief_complaint text,
    treatments text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT case_embeddings_pkey PRIMARY KEY (id),
    CONSTRAINT case_embeddings_encounter_id_fkey
        FOREIGN KEY (encounter_id) REFERENCES public.encounters(id) ON DELETE CASCADE
);

-- Unique index so we only store one embedding per encounter
CREATE UNIQUE INDEX IF NOT EXISTS case_embeddings_encounter_id_idx
    ON public.case_embeddings (encounter_id);

-- Index for filtering by doctor
CREATE INDEX IF NOT EXISTS case_embeddings_doctor_id_idx
    ON public.case_embeddings (doctor_id);
