import 'package:flutter/material.dart';
import '../../components/common/common.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';

/// Encounters list page showing all encounters
class EncountersListPage extends StatefulWidget {
  final List<Encounter> encounters;
  final Function(Encounter) onViewEncounter;

  const EncountersListPage({
    super.key,
    required this.encounters,
    required this.onViewEncounter,
  });

  @override
  State<EncountersListPage> createState() => _EncountersListPageState();
}

class _EncountersListPageState extends State<EncountersListPage> {
  String _searchTerm = '';
  String _statusFilter = 'all';

  List<Encounter> get _filteredEncounters {
    return widget.encounters.where((encounter) {
      final matchesSearch = encounter.patientName
              .toLowerCase()
              .contains(_searchTerm.toLowerCase()) ||
          encounter.chiefComplaint
              .toLowerCase()
              .contains(_searchTerm.toLowerCase());

      final matchesStatus =
          _statusFilter == 'all' || encounter.status.displayName == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
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
            'All Encounters',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'View and manage patient encounters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),

          // Filters
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Search and filter row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchTerm = value;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search by patient name or complaint...',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<String>(
                          value: _statusFilter,
                          decoration: const InputDecoration(
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('All Status'),
                            ),
                            DropdownMenuItem(
                              value: 'in progress',
                              child: Text('In Progress'),
                            ),
                            DropdownMenuItem(
                              value: 'pending review',
                              child: Text('Pending Review'),
                            ),
                            DropdownMenuItem(
                              value: 'finalized',
                              child: Text('Finalized'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _statusFilter = value ?? 'all';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Encounters list
                  if (_filteredEncounters.isEmpty)
                    const EmptyState(
                      icon: Icons.description_outlined,
                      title: 'No encounters found',
                      subtitle: 'Try adjusting your search or filters',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredEncounters.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final encounter = _filteredEncounters[index];
                        return _EncounterListItem(
                          encounter: encounter,
                          onTap: () => widget.onViewEncounter(encounter),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Encounter list item widget
class _EncounterListItem extends StatelessWidget {
  final Encounter encounter;
  final VoidCallback onTap;

  const _EncounterListItem({
    required this.encounter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient name and status
                Row(
                  children: [
                    Text(
                      encounter.patientName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 12),
                    StatusBadge.encounterStatus(encounter.status.displayName),
                  ],
                ),
                const SizedBox(height: 8),

                // Age/Gender and Date
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Age/Gender: ',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                            TextSpan(
                              text: '${encounter.age}y, ${encounter.gender}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Date: ',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                            TextSpan(
                              text: _formatDateTime(encounter.encounterDate),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Chief complaint
                Text(
                  'Chief Complaint:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                Text(
                  encounter.chiefComplaint,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                // Diagnosis if available
                if (encounter.provisionalDiagnosis.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Diagnosis:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  Text(
                    encounter.provisionalDiagnosis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],

                // Vitals
                if (encounter.vitals.hasData) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (encounter.vitals.temperature != null)
                        Text(
                          'Temp: ${encounter.vitals.temperature}°F',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      if (encounter.vitals.heartRate != null)
                        Text(
                          'HR: ${encounter.vitals.heartRate} bpm',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      if (encounter.vitals.spO2 != null)
                        Text(
                          'SpO₂: ${encounter.vitals.spO2}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      if (encounter.vitals.bloodPressureSystolic != null &&
                          encounter.vitals.bloodPressureDiastolic != null)
                        Text(
                          'BP: ${encounter.vitals.bloodPressureSystolic}/${encounter.vitals.bloodPressureDiastolic} mmHg',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('View'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.month}/${date.day}/${date.year} at $hour:${date.minute.toString().padLeft(2, '0')} $period';
  }
}
