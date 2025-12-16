import 'package:flutter/material.dart';
import '../../components/common/common.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/mock_data.dart';

/// Intake form page for creating new encounters
class IntakeFormPage extends StatefulWidget {
  final Function(Encounter) onSubmit;

  const IntakeFormPage({
    super.key,
    required this.onSubmit,
  });

  @override
  State<IntakeFormPage> createState() => _IntakeFormPageState();
}

class _IntakeFormPageState extends State<IntakeFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedPatientId;
  final _chiefComplaintController = TextEditingController();
  final _historyController = TextEditingController();
  final _examinationController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _spO2Controller = TextEditingController();
  final _bpSystolicController = TextEditingController();
  final _bpDiastolicController = TextEditingController();
  final _respiratoryRateController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _testsController = TextEditingController();

  @override
  void dispose() {
    _chiefComplaintController.dispose();
    _historyController.dispose();
    _examinationController.dispose();
    _temperatureController.dispose();
    _heartRateController.dispose();
    _spO2Controller.dispose();
    _bpSystolicController.dispose();
    _bpDiastolicController.dispose();
    _respiratoryRateController.dispose();
    _diagnosisController.dispose();
    _medicationsController.dispose();
    _testsController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedPatientId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a patient'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      final patient = MockData.patients.firstWhere((p) => p.id == _selectedPatientId);
      
      final encounter = Encounter(
        id: 'E${DateTime.now().millisecondsSinceEpoch}',
        patientId: patient.id,
        patientName: patient.name,
        age: patient.age,
        gender: patient.gender,
        encounterDate: DateTime.now(),
        chiefComplaint: _chiefComplaintController.text,
        historyOfPresentIllness: _historyController.text,
        examinationFindings: _examinationController.text,
        vitals: Vitals(
          temperature: double.tryParse(_temperatureController.text),
          heartRate: int.tryParse(_heartRateController.text),
          spO2: int.tryParse(_spO2Controller.text),
          bloodPressureSystolic: int.tryParse(_bpSystolicController.text),
          bloodPressureDiastolic: int.tryParse(_bpDiastolicController.text),
          respiratoryRate: int.tryParse(_respiratoryRateController.text),
        ),
        provisionalDiagnosis: _diagnosisController.text,
        medications: _medicationsController.text,
        testsOrdered: _testsController.text,
        status: EncounterStatus.inProgress,
        createdAt: DateTime.now(),
      );

      widget.onSubmit(encounter);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Encounter submitted successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'New Encounter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Create a new patient encounter',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),

            // Patient Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconBox.blue(Icons.person_outline, size: 40, iconSize: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Patient Information',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Patient',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedPatientId,
                          decoration: const InputDecoration(
                            hintText: 'Choose a patient',
                          ),
                          items: MockData.patients.map((patient) {
                            return DropdownMenuItem(
                              value: patient.id,
                              child: Text('${patient.name} - ${patient.age}y, ${patient.gender}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPatientId = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Clinical Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconBox.purple(Icons.description_outlined, size: 40, iconSize: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Clinical Information',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Chief Complaint *',
                      hint: 'Enter the main reason for visit',
                      controller: _chiefComplaintController,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'History of Present Illness',
                      hint: 'Describe the history of current illness',
                      controller: _historyController,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Examination Findings',
                      hint: 'Document physical examination findings',
                      controller: _examinationController,
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Vital Signs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconBox.amber(Icons.favorite_outline, size: 40, iconSize: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Vital Signs',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: (constraints.maxWidth - 16 * (crossAxisCount - 1)) / crossAxisCount,
                              child: AppTextField(
                                label: 'Temperature (°F)',
                                hint: '98.6',
                                controller: _temperatureController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            SizedBox(
                              width: (constraints.maxWidth - 16 * (crossAxisCount - 1)) / crossAxisCount,
                              child: AppTextField(
                                label: 'Heart Rate (bpm)',
                                hint: '72',
                                controller: _heartRateController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            SizedBox(
                              width: (constraints.maxWidth - 16 * (crossAxisCount - 1)) / crossAxisCount,
                              child: AppTextField(
                                label: 'SpO₂ (%)',
                                hint: '98',
                                controller: _spO2Controller,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            SizedBox(
                              width: (constraints.maxWidth - 16 * (crossAxisCount - 1)) / crossAxisCount,
                              child: AppTextField(
                                label: 'BP Systolic (mmHg)',
                                hint: '120',
                                controller: _bpSystolicController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            SizedBox(
                              width: (constraints.maxWidth - 16 * (crossAxisCount - 1)) / crossAxisCount,
                              child: AppTextField(
                                label: 'BP Diastolic (mmHg)',
                                hint: '80',
                                controller: _bpDiastolicController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            SizedBox(
                              width: (constraints.maxWidth - 16 * (crossAxisCount - 1)) / crossAxisCount,
                              child: AppTextField(
                                label: 'Respiratory Rate (rpm)',
                                hint: '16',
                                controller: _respiratoryRateController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Assessment & Plan
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconBox.green(Icons.medical_services_outlined, size: 40, iconSize: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Assessment & Plan',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Provisional Diagnosis',
                      hint: 'Enter diagnosis',
                      controller: _diagnosisController,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Medications',
                      hint: 'List prescribed medications',
                      controller: _medicationsController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Tests Ordered / Notes',
                      hint: 'Enter any tests ordered or additional notes',
                      controller: _testsController,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Submit Encounter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
