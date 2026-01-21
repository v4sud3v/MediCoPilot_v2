-- MediCoPilot Database Schema
-- Created: 2026-01-21

-- Doctors Table
CREATE TABLE public.doctors (
  id uuid NOT NULL,
  name text NOT NULL,
  email text NOT NULL UNIQUE,
  specialization text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT doctors_pkey PRIMARY KEY (id),
  CONSTRAINT doctors_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);

-- Patients Table
CREATE TABLE public.patients (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  doctor_id uuid,
  name text NOT NULL,
  age integer,
  gender text,
  allergies text,
  contact_info text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT patients_pkey PRIMARY KEY (id),
  CONSTRAINT patients_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(id)
);

-- Encounters Table
CREATE TABLE public.encounters (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  patient_id uuid,
  doctor_id uuid,
  case_id uuid NOT NULL,
  visit_number integer NOT NULL,
  chief_complaint text,
  history_of_illness text,
  temperature double precision,
  blood_pressure text,
  heart_rate integer,
  respiratory_rate integer,
  oxygen_saturation integer,
  weight double precision,
  height double precision,
  physical_exam text,
  diagnosis text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT encounters_pkey PRIMARY KEY (id),
  CONSTRAINT encounters_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id),
  CONSTRAINT encounters_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(id)
);

-- Documents Table
CREATE TABLE public.documents (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  encounter_id uuid,
  file_url text NOT NULL,
  document_type text CHECK (document_type = ANY (ARRAY['REPORT'::text, 'XRAY'::text])),
  extracted_text text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT documents_pkey PRIMARY KEY (id),
  CONSTRAINT documents_encounter_id_fkey FOREIGN KEY (encounter_id) REFERENCES public.encounters(id)
);

-- History Table
CREATE TABLE public.history (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  patient_id uuid,
  encounter_id uuid,
  summary_text text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT history_pkey PRIMARY KEY (id),
  CONSTRAINT history_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id),
  CONSTRAINT history_encounter_id_fkey FOREIGN KEY (encounter_id) REFERENCES public.encounters(id)
);

-- Medications Table
CREATE TABLE public.medications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  encounter_id uuid,
  medication_name text NOT NULL,
  dosage text,
  frequency text,
  duration text,
  instructions text,
  prescribed_at timestamp with time zone DEFAULT now(),
  CONSTRAINT medications_pkey PRIMARY KEY (id),
  CONSTRAINT medications_encounter_id_fkey FOREIGN KEY (encounter_id) REFERENCES public.encounters(id)
);
