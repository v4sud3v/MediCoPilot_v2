import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';

/// Patient summary page for generating patient-friendly summaries
class PatientSummaryPage extends StatefulWidget {
  final List<Encounter> encounters;

  const PatientSummaryPage({
    super.key,
    required this.encounters,
  });

  @override
  State<PatientSummaryPage> createState() => _PatientSummaryPageState();
}

class _PatientSummaryPageState extends State<PatientSummaryPage> {
  String? _selectedEncounterId;
  bool _isEditing = false;
  bool _summaryGenerated = false;

  final _diagnosisController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _homeCareController = TextEditingController();
  final _warningSignsController = TextEditingController();
  final _notesController = TextEditingController();

  Encounter? get _selectedEncounter {
    if (_selectedEncounterId == null) return null;
    try {
      return widget.encounters.firstWhere((e) => e.id == _selectedEncounterId);
    } catch (e) {
      return null;
    }
  }

  void _generateSummary() {
    final encounter = _selectedEncounter;
    if (encounter == null) return;

    _diagnosisController.text =
        'Your healthcare provider has diagnosed you with: ${encounter.provisionalDiagnosis}. '
        'This means that based on your symptoms and examination, this is the condition identified.';

    _medicationsController.text = encounter.medications.isNotEmpty
        ? 'You have been prescribed: ${encounter.medications}. '
            'Please take these medications as directed. If you have any questions about your medications, '
            'please contact your pharmacy or our office.'
        : 'No medications prescribed at this time.';

    _homeCareController.text =
        'Rest and stay hydrated. Monitor your symptoms and follow up as directed. '
        'Avoid strenuous activities until you feel better.';

    _warningSignsController.text =
        'Contact your doctor immediately if you experience: severe difficulty breathing, '
        'chest pain, high fever that doesn\'t respond to medication, confusion, or symptoms that worsen significantly.';

    _notesController.text = encounter.testsOrdered.isNotEmpty
        ? 'Additional tests ordered: ${encounter.testsOrdered}. We will contact you with results.'
        : '';

    setState(() {
      _summaryGenerated = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Summary generated successfully'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _handleDownload() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF downloaded successfully'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _handleSend() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Summary sent to patient'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _medicationsController.dispose();
    _homeCareController.dispose();
    _warningSignsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Patient Summaries',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Generate and edit patient-friendly summaries',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),

          // Encounter selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Encounter',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedEncounterId,
                    decoration: const InputDecoration(
                      hintText: 'Choose an encounter...',
                    ),
                    items: widget.encounters.map((encounter) {
                      return DropdownMenuItem(
                        value: encounter.id,
                        child: Text(
                          '${encounter.patientName} - ${_formatDate(encounter.encounterDate)} - ${encounter.chiefComplaint}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedEncounterId = value;
                        _summaryGenerated = false;
                      });
                    },
                  ),
                  if (_selectedEncounterId != null && !_summaryGenerated) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _generateSummary,
                      child: const Text('Generate Patient Summary'),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Summary content
          if (_summaryGenerated && _selectedEncounter != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Patient Summary for ${_selectedEncounter!.patientName}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Plain language summary for patient',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _isEditing = !_isEditing),
                          icon: Icon(_isEditing ? Icons.visibility : Icons.edit,
                              size: 18),
                          label: Text(_isEditing ? 'Preview' : 'Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Diagnosis
                    _SummarySection(
                      title: 'Your Diagnosis',
                      controller: _diagnosisController,
                      isEditing: _isEditing,
                    ),
                    const SizedBox(height: 16),

                    // Medications
                    _SummarySection(
                      title: 'Your Medications',
                      controller: _medicationsController,
                      isEditing: _isEditing,
                    ),
                    const SizedBox(height: 16),

                    // Home Care
                    _SummarySection(
                      title: 'Home Care Instructions',
                      controller: _homeCareController,
                      isEditing: _isEditing,
                    ),
                    const SizedBox(height: 16),

                    // Warning Signs
                    _SummarySection(
                      title: 'Warning Signs - When to Seek Help',
                      controller: _warningSignsController,
                      isEditing: _isEditing,
                      isWarning: true,
                    ),

                    // Notes
                    if (_notesController.text.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SummarySection(
                        title: 'Additional Notes',
                        controller: _notesController,
                        isEditing: _isEditing,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleDownload,
                        icon: const Icon(Icons.download),
                        label: const Text('Download PDF'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _handleSend,
                        icon: const Icon(Icons.send),
                        label: const Text('Send to Patient'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// Summary section widget
class _SummarySection extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final bool isEditing;
  final bool isWarning;

  const _SummarySection({
    required this.title,
    required this.controller,
    required this.isEditing,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (isEditing)
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isWarning ? AppTheme.redLight : AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: isWarning ? Border.all(color: AppTheme.red.withValues(alpha: 0.3)) : null,
            ),
            child: Text(
              controller.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
      ],
    );
  }
}
