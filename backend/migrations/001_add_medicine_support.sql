-- Migration: Add Medicine Support to Patient Education
-- This script adds columns to support medicine-specific functionality
-- Run this on existing databases to upgrade the schema

-- Add medicines and medicines_pdf_id columns to patient_education table
ALTER TABLE public.patient_education 
ADD COLUMN IF NOT EXISTS medicines jsonb,
ADD COLUMN IF NOT EXISTS medicines_pdf_id uuid;

-- Create Medicine PDFs Table (Store generated medicine PDFs for sharing)
CREATE TABLE IF NOT EXISTS public.medicine_pdfs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  encounter_id uuid NOT NULL,
  patient_id uuid NOT NULL,
  doctor_id uuid NOT NULL,
  pdf_data bytea NOT NULL,
  filename text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT medicine_pdfs_pkey PRIMARY KEY (id),
  CONSTRAINT medicine_pdfs_encounter_id_fkey FOREIGN KEY (encounter_id) REFERENCES public.encounters(id),
  CONSTRAINT medicine_pdfs_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id),
  CONSTRAINT medicine_pdfs_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(id)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_medicine_pdfs_encounter ON public.medicine_pdfs(encounter_id);
CREATE INDEX IF NOT EXISTS idx_medicine_pdfs_patient ON public.medicine_pdfs(patient_id);
CREATE INDEX IF NOT EXISTS idx_patient_education_medicines ON public.patient_education USING GIN(medicines);

-- Add comment to explain the structure
COMMENT ON COLUMN public.patient_education.medicines IS 'JSON array of medicine objects containing {name, dosage, frequency, instructions, indication, side_effects, precautions, duration}';
COMMENT ON COLUMN public.patient_education.medicines_pdf_id IS 'Reference to medicine PDF record if one was generated';
COMMENT ON TABLE public.medicine_pdfs IS 'Stores generated medicine PDFs that can be shared separately from patient education documents';
