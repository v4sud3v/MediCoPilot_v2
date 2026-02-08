// Full-page Encounter Detail View
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/encounter_service.dart';
import '../services/api_service.dart';
import 'new_encounter_page.dart';

class EncounterDetailPage extends StatefulWidget {
  final Map<String, dynamic> encounter;
  final List<Map<String, String>> initialEncounterFiles;
  final Future<Map<String, String>?> Function() onUploadFile;
  final Future<bool> Function(int) onDeleteFile;
  final Function(Map<String, String>) onViewFile;

  const EncounterDetailPage({
    super.key,
    required this.encounter,
    required this.initialEncounterFiles,
    required this.onUploadFile,
    required this.onDeleteFile,
    required this.onViewFile,
  });

  @override
  State<EncounterDetailPage> createState() => EncounterDetailPageState();
}

class EncounterDetailPageState extends State<EncounterDetailPage> {
  late List<Map<String, String>> _files;
  final _encounterService = EncounterService();
  List<Map<String, dynamic>> _caseVisits = [];
  bool _isLoadingVisits = false;

  @override
  void initState() {
    super.initState();
    _files = List.from(widget.initialEncounterFiles);
    _loadCaseVisits();
  }

  Future<void> _loadCaseVisits() async {
    final caseId = widget.encounter['case_id'];
    if (caseId == null) return;

    setState(() {
      _isLoadingVisits = true;
    });

    try {
      final visits = await _encounterService.getVisitsInCase(caseId);
      if (mounted) {
        setState(() {
          _caseVisits = visits;
          _isLoadingVisits = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading case visits: $e');
      if (mounted) {
        setState(() {
          _isLoadingVisits = false;
        });
      }
    }
  }

  String _formatDateTime(dynamic date) {
    DateTime dateTime;

    if (date is String) {
      try {
        dateTime = DateTime.parse(date);
      } catch (e) {
        return 'Invalid date';
      }
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return 'Invalid date';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _handleUpload() async {
    final newFile = await widget.onUploadFile();
    if (newFile != null && mounted) {
      setState(() {
        _files.add(newFile);
      });
    }
  }

  void _handleDelete(int index) async {
    final success = await widget.onDeleteFile(index);
    if (success && mounted) {
      setState(() {
        _files.removeAt(index);
      });
    }
  }

  bool _isFollowUpVisit() {
    final visitNumber = widget.encounter['visit_number'] ?? 1;
    return visitNumber > 1;
  }

  Widget _buildReasonForVisitCard() {
    return _buildInfoCard(
      'Reason for Visit',
      Icons.assignment_turned_in_outlined,
      const Color(0xFF2563EB),
      [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            widget.encounter['chief_complaint'] ?? 'Regular follow-up visit',
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresentConditionCard() {
    return _buildInfoCard(
      'Present Condition',
      Icons.health_and_safety_outlined,
      const Color(0xFF059669),
      [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            widget.encounter['physical_exam'] ?? 'No condition notes recorded',
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionChangeCard() {
    return _buildInfoCard(
      'Change in Condition',
      Icons.trending_up_outlined,
      const Color(0xFFD97706),
      [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.trending_up,
                        color: Colors.green.shade700,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            _getConditionStatus(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Observations:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.encounter['history_of_illness'] ??
                    'No observations recorded',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getConditionStatus() {
    // Try to infer condition status from diagnosis or history
    final diagnosis = (widget.encounter['diagnosis'] ?? '')
        .toString()
        .toLowerCase();
    final history = (widget.encounter['history_of_illness'] ?? '')
        .toString()
        .toLowerCase();
    final combined = '$diagnosis $history';

    if (combined.contains('improv') ||
        combined.contains('better') ||
        combined.contains('resolved')) {
      return '✓ Improving';
    } else if (combined.contains('worse') ||
        combined.contains('deteriorat') ||
        combined.contains('declin')) {
      return '⚠ Worsening';
    } else if (combined.contains('stable') || combined.contains('unchanged')) {
      return '→ Stable';
    }
    return '→ No significant change';
  }

  Widget _buildMedicationChangesCard() {
    return _buildInfoCard(
      'Medication Changes',
      Icons.medication_outlined,
      const Color(0xFF7C3AED),
      [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.medication,
                        color: Colors.blue.shade700,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Medications',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            widget.encounter['medication'] ??
                                'No medication information',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Notes:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Medication adjustments and changes based on current condition',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Custom App Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(25),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Back to encounters',
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.description,
                    color: Color(0xFF2563EB),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Encounter #${widget.encounter['id']}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Completed',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(widget.encounter['created_at']),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _navigateToAddFollowup,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Follow-up'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column - Main Info
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // Visit Timeline Card (if multiple visits in case)
                        if (_caseVisits.length > 1) ...[
                          _buildVisitTimelineCard(),
                          const SizedBox(height: 20),
                        ],
                        _buildInfoCard(
                          'Patient Information',
                          Icons.person_outline,
                          const Color(0xFF2563EB),
                          [
                            _buildInfoRow(
                              'Patient Name',
                              widget.encounter['patient_name'] ?? 'Unknown',
                            ),
                            _buildInfoRow(
                              'Date & Time',
                              _formatDateTime(widget.encounter['created_at']),
                            ),
                            _buildInfoRow(
                              'Visit',
                              'Visit ${widget.encounter['visit_number']} of ${_caseVisits.length}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_isFollowUpVisit()) ...[
                          // Follow-up Visit Badge
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade50,
                                  Colors.cyan.shade50,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.shade300,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.repeat_outlined,
                                    color: Colors.blue.shade700,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Follow-up Visit',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Monitoring patient progress and response to treatment',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildReasonForVisitCard(),
                          const SizedBox(height: 20),
                          _buildPresentConditionCard(),
                          const SizedBox(height: 20),
                          _buildConditionChangeCard(),
                          const SizedBox(height: 20),
                          _buildMedicationChangesCard(),
                          const SizedBox(height: 20),
                        ] else ...[
                          _buildInfoCard(
                            'Chief Complaint',
                            Icons.healing_outlined,
                            const Color(0xFFDC2626),
                            [
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  widget.encounter['chief_complaint'] ??
                                      'No complaint',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.6,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                        _buildInfoCard(
                          'Diagnosis & Treatment',
                          Icons.medical_information_outlined,
                          const Color(0xFF059669),
                          [
                            _buildInfoRow(
                              'Diagnosis',
                              widget.encounter['diagnosis'] ?? 'Not specified',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Treatment Plan',
                              widget.encounter['physical_exam'] ??
                                  'Not recorded',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right Column - Vitals & Documents
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildVitalsCard(),
                        const SizedBox(height: 20),
                        _buildDocumentsCard(context),
                      ],
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

  Widget _buildVisitTimelineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.timeline,
                      color: Colors.purple.shade700,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Visit History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _navigateToAddFollowup,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Follow-up'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoadingVisits)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else
            ..._caseVisits.asMap().entries.map((entry) {
              final index = entry.key;
              final visit = entry.value;
              final isCurrentVisit = visit['id'] == widget.encounter['id'];

              return Container(
                margin: EdgeInsets.only(
                  bottom: index < _caseVisits.length - 1 ? 12 : 0,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCurrentVisit
                      ? Colors.blue.shade50
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrentVisit
                        ? Colors.blue.shade200
                        : Colors.grey.shade200,
                    width: isCurrentVisit ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCurrentVisit
                            ? Colors.blue.shade100
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrentVisit
                              ? Colors.blue.shade400
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${visit['visit_number']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCurrentVisit
                                ? Colors.blue.shade700
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visit['chief_complaint'] ?? 'No complaint recorded',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isCurrentVisit
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateTime(visit['created_at']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrentVisit)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Current',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  void _navigateToAddFollowup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewEncounterPage(
          selectedPatientId: widget.encounter['patient_id'],
          selectedPatientName: widget.encounter['patient_name'],
          parentCaseId: widget.encounter['case_id'],
          parentEncounter: widget.encounter,
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    IconData icon,
    Color accentColor,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  color: Color(0xFFD97706),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Vital Signs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildVitalItem(
            Icons.thermostat_outlined,
            'Temperature',
            '${widget.encounter['temperature'] ?? 'N/A'}°F',
            const Color(0xFFDC2626),
          ),
          const SizedBox(height: 16),
          _buildVitalItem(
            Icons.favorite_outline,
            'Blood Pressure',
            '${widget.encounter['blood_pressure'] ?? 'N/A'} mmHg',
            const Color(0xFF2563EB),
          ),
          const SizedBox(height: 16),
          _buildVitalItem(
            Icons.monitor_heart_outlined,
            'Heart Rate',
            '${widget.encounter['heart_rate'] ?? 'N/A'} bpm',
            const Color(0xFFDC2626),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.folder_outlined,
                  color: Color(0xFF7C3AED),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleUpload,
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Upload Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_files.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No documents yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._files.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return _buildFileCard(context, index, file);
            }),
        ],
      ),
    );
  }

  Widget _buildFileCard(
    BuildContext context,
    int index,
    Map<String, String> file,
  ) {
    IconData fileIcon;
    Color fileColor;

    switch (file['type']) {
      case 'X-Ray':
        fileIcon = Icons.medical_services;
        fileColor = const Color(0xFFDC2626);
        break;
      case 'Lab Notes':
        fileIcon = Icons.science;
        fileColor = const Color(0xFF059669);
        break;
      default:
        fileIcon = Icons.insert_drive_file;
        fileColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: fileColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(fileIcon, size: 18, color: fileColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file['name']!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      file['type']!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onViewFile(file),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAnalyzeDialog(context, file),
                  icon: const Icon(Icons.analytics_outlined, size: 16),
                  label: const Text('Analyze'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF059669),
                    side: const BorderSide(color: Color(0xFF059669)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _handleDelete(index),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Icon(Icons.delete_outline, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAnalyzeDialog(BuildContext context, Map<String, String> file) {
    showDialog(
      context: context,
      builder: (context) => _XrayAnalyzeDialog(
        file: file,
        patientContext: widget.encounter['diagnosis'] ?? '',
      ),
    );
  }
}

/// Stateful dialog for X-ray analysis with body region selection and results display
class _XrayAnalyzeDialog extends StatefulWidget {
  final Map<String, String> file;
  final String patientContext;

  const _XrayAnalyzeDialog({required this.file, required this.patientContext});

  @override
  State<_XrayAnalyzeDialog> createState() => _XrayAnalyzeDialogState();
}

class _XrayAnalyzeDialogState extends State<_XrayAnalyzeDialog> {
  final ApiService _apiService = ApiService();
  String _selectedBodyRegion = 'chest';
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  String? _error;

  final List<Map<String, String>> _bodyRegions = [
    {'value': 'chest', 'label': 'Chest'},
    {'value': 'head', 'label': 'Head / Brain'},
    {'value': 'spine', 'label': 'Spine'},
    {'value': 'limb', 'label': 'Limbs / Extremities'},
    {'value': 'abdomen', 'label': 'Abdomen'},
    {'value': 'pelvis', 'label': 'Pelvis'},
    {'value': 'other', 'label': 'Other'},
  ];

  Future<void> _startAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _error = null;
      _analysisResult = null;
    });

    try {
      // Read the file and convert to base64
      final filePath = widget.file['path'];
      if (filePath == null) {
        throw Exception('File path not found');
      }

      final uri = Uri.tryParse(filePath);
      final isRemote =
          uri != null &&
          uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https');

      List<int> bytes;
      if (isRemote) {
        // Use backend proxy download if we have a document ID (avoids Supabase bucket auth issues)
        final docId = widget.file['id'];
        final Uri downloadUri;
        if (docId != null &&
            docId.isNotEmpty &&
            filePath.contains('supabase')) {
          downloadUri = Uri.parse(_apiService.getDownloadUrl(docId));
        } else {
          downloadUri = uri;
        }

        final response = await http
            .get(downloadUri)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw Exception(
                'Download timed out. Check your network connection.',
              ),
            );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception(
            'Failed to download file from cloud storage (HTTP ${response.statusCode})',
          );
        }
        bytes = response.bodyBytes;
        if (bytes.isEmpty) {
          throw Exception('Downloaded file is empty');
        }
      } else {
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception(
            'File not found locally. It may have been moved or deleted.',
          );
        }
        bytes = await file.readAsBytes();
      }
      final base64Image = base64Encode(bytes);

      // Call the API
      final result = await _apiService.analyzeXray(
        imageBase64: base64Image,
        imageType: widget.file['type'] ?? 'X-Ray',
        bodyRegion: _selectedBodyRegion,
        patientContext: widget.patientContext,
      );

      if (mounted) {
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: Color(0xFF059669),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text('AI Medical Analysis'),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: _analysisResult != null
            ? _buildResultsView()
            : _buildConfigView(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_analysisResult != null ? 'Close' : 'Cancel'),
        ),
        if (_analysisResult == null)
          ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : _startAnalysis,
            icon: _isAnalyzing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.play_arrow, size: 18),
            label: Text(_isAnalyzing ? 'Analyzing...' : 'Start Analysis'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF059669).withAlpha(150),
              disabledForegroundColor: Colors.white70,
            ),
          ),
      ],
    );
  }

  Widget _buildConfigView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI analysis from 3 specialist perspectives: Cardiologist, Neurologist, and Orthopedist.',
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // File info
          Text(
            'Document: ${widget.file['name']}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Type: ${widget.file['type']}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          // Body region selector
          const Text(
            'Select Body Region:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _bodyRegions.map((region) {
              final isSelected = _selectedBodyRegion == region['value'];
              return ChoiceChip(
                label: Text(region['label']!),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedBodyRegion = region['value']!);
                  }
                },
                selectedColor: const Color(0xFF2563EB).withAlpha(50),
                labelStyle: TextStyle(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),

          if (_error != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    final analyses = _analysisResult!['analyses'] as List<dynamic>? ?? [];
    final primarySpecialist = _analysisResult!['primary_specialist'] as String?;
    final overallSummary = _analysisResult!['overall_summary'] as String? ?? '';

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.cyan.shade50],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.summarize, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    overallSummary,
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          ),

          if (primarySpecialist != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withAlpha(25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Primary: $primarySpecialist',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF059669),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Specialist tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade700,
              indicator: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                _buildTab('Cardio', Icons.favorite, analyses, 'Cardiologist'),
                _buildTab('Neuro', Icons.psychology, analyses, 'Neurologist'),
                _buildTab(
                  'Ortho',
                  Icons.accessibility_new,
                  analyses,
                  'Orthopedist',
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tab content
          Expanded(
            child: TabBarView(
              children: [
                _buildSpecialistContent(analyses, 'Cardiologist'),
                _buildSpecialistContent(analyses, 'Neurologist'),
                _buildSpecialistContent(analyses, 'Orthopedist'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    String label,
    IconData icon,
    List<dynamic> analyses,
    String specialist,
  ) {
    final analysis = analyses.firstWhere(
      (a) => a['specialist'] == specialist,
      orElse: () => null,
    );
    final hasFindings = analysis?['has_findings'] ?? false;

    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
          if (hasFindings) ...[
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecialistContent(List<dynamic> analyses, String specialist) {
    final analysis = analyses.firstWhere(
      (a) => a['specialist'] == specialist,
      orElse: () => null,
    );

    if (analysis == null) {
      return const Center(child: Text('No analysis available'));
    }

    final hasFindings = analysis['has_findings'] ?? false;
    final findings = analysis['findings'] as List<dynamic>? ?? [];
    final warnings = analysis['overlooked_warnings'] as List<dynamic>? ?? [];
    final actions = analysis['recommended_actions'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasFindings)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No significant $specialist findings detected.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Findings
            const Text(
              'Findings:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...findings.map((f) => _buildFindingCard(f)),
          ],

          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              '⚠️ Things to Watch For:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        w.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              '✅ Recommended Actions:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...actions.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_right,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade800,
                        ),
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

  Widget _buildFindingCard(dynamic finding) {
    final title = finding['title'] ?? 'Unknown';
    final description = finding['description'] ?? '';
    final severity = finding['severity'] ?? 'Medium';
    final isRedFlag = finding['is_red_flag'] ?? false;

    Color severityColor;
    switch (severity) {
      case 'High':
        severityColor = Colors.red;
        break;
      case 'Medium':
        severityColor = Colors.orange;
        break;
      default:
        severityColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRedFlag ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isRedFlag ? Colors.red.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isRedFlag) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '🚨 RED FLAG',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: severityColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  severity,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: severityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
