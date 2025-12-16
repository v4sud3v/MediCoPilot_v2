import 'package:flutter/material.dart';
import '../../components/common/common.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';

/// Encounter detail page showing complete encounter information
class EncounterDetailPage extends StatelessWidget {
  final Encounter encounter;
  final VoidCallback onBack;

  const EncounterDetailPage({
    super.key,
    required this.encounter,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Encounter Details',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      'View complete encounter information',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              StatusBadge.encounterStatus(encounter.status.displayName),
            ],
          ),
          const SizedBox(height: 24),

          // Patient info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.blueLight,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppTheme.blue,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          encounter.patientName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${encounter.age} years old • ${encounter.gender} • ID: ${encounter.patientId}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(encounter.encounterDate),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(encounter.encounterDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Chief Complaint and Vitals row
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildChiefComplaintCard(context)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildVitalsCard(context)),
                  ],
                );
              }
              return Column(
                children: [
                  _buildChiefComplaintCard(context),
                  const SizedBox(height: 24),
                  _buildVitalsCard(context),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // History of Present Illness
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'History of Present Illness',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    encounter.historyOfPresentIllness,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Examination Findings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Examination Findings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    encounter.examinationFindings,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Diagnosis and Medications row
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildDiagnosisCard(context)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildMedicationsCard(context)),
                  ],
                );
              }
              return Column(
                children: [
                  _buildDiagnosisCard(context),
                  const SizedBox(height: 24),
                  _buildMedicationsCard(context),
                ],
              );
            },
          ),

          // Tests Ordered
          if (encounter.testsOrdered.isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconBox.red(Icons.science_outlined, size: 40, iconSize: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Tests Ordered / Notes',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      encounter.testsOrdered,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Footer with encounter info
          Card(
            color: AppTheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Encounter ID: ${encounter.id}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  Text(
                    'Created: ${_formatDateTime(encounter.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChiefComplaintCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBox.blue(Icons.description_outlined, size: 40, iconSize: 20),
                const SizedBox(width: 12),
                Text(
                  'Chief Complaint',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              encounter.chiefComplaint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBox.purple(Icons.favorite_outline, size: 40, iconSize: 20),
                const SizedBox(width: 12),
                Text(
                  'Vital Signs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (encounter.vitals.temperature != null)
                  _VitalItem(
                    label: 'Temperature',
                    value: '${encounter.vitals.temperature}°F',
                  ),
                if (encounter.vitals.heartRate != null)
                  _VitalItem(
                    label: 'Heart Rate',
                    value: '${encounter.vitals.heartRate} bpm',
                  ),
                if (encounter.vitals.spO2 != null)
                  _VitalItem(
                    label: 'SpO₂',
                    value: '${encounter.vitals.spO2}%',
                  ),
                if (encounter.vitals.bloodPressureSystolic != null &&
                    encounter.vitals.bloodPressureDiastolic != null)
                  _VitalItem(
                    label: 'Blood Pressure',
                    value:
                        '${encounter.vitals.bloodPressureSystolic}/${encounter.vitals.bloodPressureDiastolic} mmHg',
                  ),
                if (encounter.vitals.respiratoryRate != null)
                  _VitalItem(
                    label: 'Respiratory Rate',
                    value: '${encounter.vitals.respiratoryRate} rpm',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBox.green(Icons.medical_information_outlined,
                    size: 40, iconSize: 20),
                const SizedBox(width: 12),
                Text(
                  'Provisional Diagnosis',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              encounter.provisionalDiagnosis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBox.amber(Icons.medication_outlined, size: 40, iconSize: 20),
                const SizedBox(width: 12),
                Text(
                  'Medications',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              encounter.medications,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} at ${_formatTime(date)}';
  }
}

/// Vital item widget
class _VitalItem extends StatelessWidget {
  final String label;
  final String value;

  const _VitalItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
