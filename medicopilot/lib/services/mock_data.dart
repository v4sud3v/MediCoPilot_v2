import '../models/models.dart';

/// Mock data for MVP demonstration
class MockData {
  static final List<Patient> patients = [
    const Patient(id: 'P001', name: 'John Smith', age: 45, gender: 'Male'),
    const Patient(id: 'P002', name: 'Sarah Johnson', age: 32, gender: 'Female'),
    const Patient(id: 'P003', name: 'Michael Brown', age: 58, gender: 'Male'),
    const Patient(id: 'P004', name: 'Emily Davis', age: 28, gender: 'Female'),
    const Patient(id: 'P005', name: 'Robert Wilson', age: 67, gender: 'Male'),
  ];

  static final List<Encounter> encounters = [
    Encounter(
      id: 'E001',
      patientId: 'P001',
      patientName: 'John Smith',
      age: 45,
      gender: 'Male',
      encounterDate: DateTime(2025, 10, 18, 10, 30),
      chiefComplaint: 'Persistent cough and fever for 3 days',
      historyOfPresentIllness:
          'Patient reports dry cough, fever up to 101°F, mild shortness of breath. No recent travel. No known COVID exposure.',
      examinationFindings: 'Bilateral wheezing on auscultation, mild tachypnea',
      vitals: const Vitals(
        temperature: 101.2,
        heartRate: 88,
        spO2: 94,
        bloodPressureSystolic: 130,
        bloodPressureDiastolic: 85,
        respiratoryRate: 22,
      ),
      provisionalDiagnosis: 'Acute bronchitis, rule out pneumonia',
      medications: 'Amoxicillin 500mg TID x 7 days, Albuterol inhaler PRN',
      testsOrdered: 'Chest X-ray, CBC with differential',
      status: EncounterStatus.pendingReview,
      createdAt: DateTime(2025, 10, 18, 10, 30),
    ),
    Encounter(
      id: 'E002',
      patientId: 'P002',
      patientName: 'Sarah Johnson',
      age: 32,
      gender: 'Female',
      encounterDate: DateTime(2025, 10, 17, 14, 15),
      chiefComplaint: 'Migraine headache',
      historyOfPresentIllness:
          'Recurrent headaches, photophobia, nausea. Similar episodes in the past.',
      examinationFindings: 'Neurological exam normal, no focal deficits',
      vitals: const Vitals(
        temperature: 98.6,
        heartRate: 72,
        spO2: 98,
        bloodPressureSystolic: 118,
        bloodPressureDiastolic: 76,
      ),
      provisionalDiagnosis: 'Migraine without aura',
      medications: 'Sumatriptan 50mg PRN, Ibuprofen 400mg TID PRN',
      testsOrdered: 'None',
      status: EncounterStatus.finalized,
      createdAt: DateTime(2025, 10, 17, 14, 15),
    ),
    Encounter(
      id: 'E003',
      patientId: 'P005',
      patientName: 'Robert Wilson',
      age: 67,
      gender: 'Male',
      encounterDate: DateTime(2025, 10, 16, 9, 0),
      chiefComplaint: 'Follow-up for hypertension',
      historyOfPresentIllness:
          'Patient on antihypertensive medication. Reports good compliance. Occasional dizziness.',
      examinationFindings: 'Cardiovascular exam unremarkable',
      vitals: const Vitals(
        temperature: 98.4,
        heartRate: 68,
        spO2: 97,
        bloodPressureSystolic: 145,
        bloodPressureDiastolic: 92,
      ),
      provisionalDiagnosis: 'Hypertension, suboptimal control',
      medications:
          'Lisinopril 20mg daily (increased from 10mg), HCTZ 12.5mg daily',
      testsOrdered: 'Renal function panel, Lipid panel',
      status: EncounterStatus.finalized,
      createdAt: DateTime(2025, 10, 16, 9, 0),
    ),
  ];

  static final List<AISuggestion> suggestions = [
    AISuggestion(
      id: 'S001',
      encounterId: 'E001',
      category: SuggestionCategory.redFlag,
      suggestion:
          'SpO2 of 94% with respiratory symptoms - consider oxygen therapy and closer monitoring',
      rationale:
          'Low oxygen saturation (94%) combined with respiratory complaints and tachypnea',
      urgency: SuggestionUrgency.high,
      status: SuggestionStatus.pending,
      createdAt: DateTime(2025, 10, 18, 10, 35),
    ),
    AISuggestion(
      id: 'S002',
      encounterId: 'E001',
      category: SuggestionCategory.documentationGap,
      suggestion: 'Document smoking history and pack-years',
      rationale: 'Respiratory complaint without documented smoking history',
      urgency: SuggestionUrgency.medium,
      status: SuggestionStatus.pending,
      createdAt: DateTime(2025, 10, 18, 10, 35),
    ),
    AISuggestion(
      id: 'S003',
      encounterId: 'E002',
      category: SuggestionCategory.missedVital,
      suggestion: 'Respiratory rate not documented',
      rationale: 'Vital sign missing from standard set',
      urgency: SuggestionUrgency.low,
      status: SuggestionStatus.ignored,
      createdAt: DateTime(2025, 10, 17, 14, 20),
    ),
    AISuggestion(
      id: 'S004',
      encounterId: 'E003',
      category: SuggestionCategory.recheckValue,
      suggestion:
          'Blood pressure remains elevated (145/92) - consider medication adjustment',
      rationale: 'BP above target for hypertensive patient',
      urgency: SuggestionUrgency.medium,
      status: SuggestionStatus.accepted,
      createdAt: DateTime(2025, 10, 16, 9, 15),
    ),
  ];

  static final List<UploadedFile> uploadedFiles = [
    UploadedFile(
      id: 'F001',
      encounterId: 'E001',
      patientId: 'P001',
      fileName: 'chest_xray_20251018.pdf',
      fileType: FileType.pdf,
      uploadDate: DateTime(2025, 10, 18, 11, 0),
      status: FileStatus.uploaded,
    ),
    UploadedFile(
      id: 'F002',
      encounterId: 'E001',
      patientId: 'P001',
      fileName: 'lab_results_cbc.pdf',
      fileType: FileType.pdf,
      uploadDate: DateTime(2025, 10, 18, 11, 15),
      status: FileStatus.uploaded,
    ),
    UploadedFile(
      id: 'F003',
      encounterId: 'E003',
      patientId: 'P005',
      fileName: 'renal_panel_results.pdf',
      fileType: FileType.pdf,
      uploadDate: DateTime(2025, 10, 16, 10, 0),
      status: FileStatus.uploaded,
    ),
  ];

  static final List<Reminder> reminders = [
    Reminder(
      id: 'R001',
      patientId: 'P001',
      patientName: 'John Smith',
      eventType: ReminderEventType.followUp,
      date: DateTime(2025, 10, 25),
      time: '10:00',
      notes: 'Review chest X-ray results and CBC',
      completed: false,
    ),
    Reminder(
      id: 'R002',
      patientId: 'P005',
      patientName: 'Robert Wilson',
      eventType: ReminderEventType.test,
      date: DateTime(2025, 10, 30),
      time: '09:00',
      notes: 'Fasting blood work - renal and lipid panel',
      completed: false,
    ),
    Reminder(
      id: 'R003',
      patientId: 'P002',
      patientName: 'Sarah Johnson',
      eventType: ReminderEventType.followUp,
      date: DateTime(2025, 11, 1),
      time: '14:00',
      notes: 'Check on migraine medication effectiveness',
      completed: false,
    ),
  ];
}
