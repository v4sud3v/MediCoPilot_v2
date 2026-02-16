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
  name text NOT NULL,
  email text,
  age integer,
  gender text,
  allergies text,
  contact_info text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT patients_pkey PRIMARY KEY (id)
);

-- Doctor-Patient relationship (many-to-many)
-- A patient can consult multiple doctors; a doctor can have many patients.
CREATE TABLE public.doctor_patients (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  doctor_id uuid NOT NULL,
  patient_id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT doctor_patients_pkey PRIMARY KEY (id),
  CONSTRAINT doctor_patients_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(id),
  CONSTRAINT doctor_patients_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id),
  CONSTRAINT doctor_patients_unique UNIQUE (doctor_id, patient_id)
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
  allergies text,
  temperature double precision,
  blood_pressure text,
  heart_rate integer,
  respiratory_rate integer,
  oxygen_saturation integer,
  weight double precision,
  height double precision,
  physical_exam text,
  diagnosis text,
  medications text,
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

-- Patient Education Table (AI-generated educational content for patients)
CREATE TABLE public.patient_education (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  encounter_id uuid NOT NULL,
  patient_id uuid NOT NULL,
  doctor_id uuid NOT NULL,
  title text NOT NULL,
  description text,
  content text NOT NULL,
  status text DEFAULT 'pending' CHECK (status = ANY (ARRAY['pending'::text, 'sent'::text, 'viewed'::text])),
  sent_at timestamp with time zone,
  viewed_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT patient_education_pkey PRIMARY KEY (id),
  CONSTRAINT patient_education_encounter_id_fkey FOREIGN KEY (encounter_id) REFERENCES public.encounters(id),
  CONSTRAINT patient_education_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id),
  CONSTRAINT patient_education_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(id)
);

-- Patient Summary Table (AI-generated summary of important encounter details)
CREATE TABLE public.patient_summary (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  encounter_id uuid NOT NULL,
  patient_id uuid NOT NULL,
  doctor_id uuid NOT NULL,
  summary_text text NOT NULL,
  key_findings text,
  important_changes text,
  follow_up_notes text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT patient_summary_pkey PRIMARY KEY (id),
  CONSTRAINT patient_summary_encounter_id_fkey FOREIGN KEY (encounter_id) REFERENCES public.encounters(id),
  CONSTRAINT patient_summary_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id),
  CONSTRAINT patient_summary_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(id)
);
