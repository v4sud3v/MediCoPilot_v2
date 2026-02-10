import 'package:flutter/material.dart';
import '../services/encounter_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewEncounterPage extends StatefulWidget {
  final String? selectedPatientId;
  final String? selectedPatientName;
  final PatientDetails? selectedPatientDetails;
  final String? parentCaseId; // If provided, this is a follow-up encounter
  final Map<String, dynamic>?
  parentEncounter; // Parent encounter data for inheritance

  const NewEncounterPage({
    super.key,
    this.selectedPatientId,
    this.selectedPatientName,
    this.selectedPatientDetails,
    this.parentCaseId,
    this.parentEncounter,
  });

  @override
  State<NewEncounterPage> createState() => _NewEncounterPageState();
}

class _NewEncounterPageState extends State<NewEncounterPage> {
  final _formKey = GlobalKey<FormState>();

  // Encounter fields controllers
  final _complaintController = TextEditingController();
  final _historyController = TextEditingController();
  final _examinationController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicationController = TextEditingController();

  // Vital signs controllers
  final _temperatureController = TextEditingController();
  final _bloodPressureController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _respiratoryRateController = TextEditingController();
  final _oxygenSaturationController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  // Services
  final _encounterService = EncounterService();

  // Analysis state
  bool _isAnalyzing = false;
  bool _hasAnalyzed = false;
  AnalysisResponse? _analysisResults;
  bool _hasDiagnosisText = false;

  // Timeline state
  List<Map<String, dynamic>> _caseVisits = [];
  bool _isLoadingVisits = false;
  int _selectedPanelTab = 0; // 0 for AI Suggestions, 1 for Timeline

  bool get _isFollowUp => widget.parentCaseId != null;

  @override
  void initState() {
    super.initState();
    _diagnosisController.addListener(() {
      setState(() {
        _hasDiagnosisText = _diagnosisController.text.trim().isNotEmpty;
      });
    });

    // Populate allergies from patient details if available
    if (widget.selectedPatientDetails?.allergies != null) {
      _allergiesController.text = widget.selectedPatientDetails!.allergies!;
    }

    // If this is a follow-up, inherit data from parent
    if (_isFollowUp && widget.parentEncounter != null) {
      final parentHistory = widget.parentEncounter!['history_of_illness'];
      if (parentHistory != null && parentHistory.toString().isNotEmpty) {
        _historyController.text = parentHistory.toString();
      }

      // Also fetch allergies from parent encounter if not already set
      final parentAllergies = widget.parentEncounter!['allergies'];
      if (parentAllergies != null && parentAllergies.toString().isNotEmpty) {
        if (_allergiesController.text.isEmpty) {
          _allergiesController.text = parentAllergies.toString();
        }
      }

      // Load case visits for timeline display
      _loadCaseVisits();
    }
  }

  Future<void> _loadCaseVisits() async {
    if (widget.parentCaseId == null) return;

    setState(() {
      _isLoadingVisits = true;
    });

    try {
      final visits = await _encounterService.getVisitsInCase(
        widget.parentCaseId!,
      );
      if (mounted) {
        setState(() {
          _caseVisits = visits;
          _isLoadingVisits = false;
        });
      }
    } catch (e) {
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

  @override
  void didUpdateWidget(NewEncounterPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update allergies field when patient details change
    if (widget.selectedPatientDetails?.allergies !=
        oldWidget.selectedPatientDetails?.allergies) {
      if (widget.selectedPatientDetails?.allergies != null) {
        _allergiesController.text = widget.selectedPatientDetails!.allergies!;
      } else {
        _allergiesController.clear();
      }
    }
  }

  @override
  void dispose() {
    _complaintController.dispose();
    _historyController.dispose();
    _examinationController.dispose();
    _diagnosisController.dispose();
    _allergiesController.dispose();
    _medicationController.dispose();
    _temperatureController.dispose();
    _bloodPressureController.dispose();
    _heartRateController.dispose();
    _respiratoryRateController.dispose();
    _oxygenSaturationController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Main content area (left side)
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Go back',
                      ),
                      const SizedBox(width: 8),
                      if (_isFollowUp)
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: const Text(
                            'FOLLOW-UP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      Text(
                        _isFollowUp ? 'Add Follow-up Visit' : 'New Encounter',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  const Text(
                    'Start a new patient encounter',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // Patient Details Section
                  Container(
                    width: double.infinity,
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
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section Title
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF2563EB,
                                    ).withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline,
                                    color: Color(0xFF2563EB),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Patient Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Display Patient Information (Read-only)
                            if (widget.selectedPatientDetails != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withAlpha(13),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF2563EB,
                                    ).withAlpha(51),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.selectedPatientDetails!.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (widget
                                                .selectedPatientDetails!
                                                .age !=
                                            null) ...[
                                          Text(
                                            'Age: ${widget.selectedPatientDetails!.age} years',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                        ],
                                        if (widget
                                                .selectedPatientDetails!
                                                .gender !=
                                            null) ...[
                                          Text(
                                            'Gender: ${widget.selectedPatientDetails!.gender}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (widget
                                            .selectedPatientDetails!
                                            .contactInfo !=
                                        null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Contact: ${widget.selectedPatientDetails!.contactInfo}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Allergies (Editable)
                            _buildTextField(
                              controller: _allergiesController,
                              label: 'Allergies',
                              hint:
                                  'List known allergies (e.g., Penicillin, Peanuts)',
                              icon: Icons.warning_amber_outlined,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 20),

                            // Chief Complaint
                            _buildTextField(
                              controller: _complaintController,
                              label: 'Chief Complaint',
                              hint:
                                  'Describe the main complaint or reason for visit',
                              icon: Icons.healing_outlined,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 20),

                            // History of Illness
                            _buildTextField(
                              controller: _historyController,
                              label: 'History of Illness',
                              hint:
                                  'Document the history of present illness, past medical history, medications, allergies, etc.',
                              icon: Icons.history_outlined,
                              maxLines: 4,
                            ),
                            const SizedBox(height: 20),

                            // Vital Signs Section
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF059669,
                                    ).withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.monitor_heart_outlined,
                                    color: Color(0xFF059669),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Vital Signs',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Vital Signs Grid
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _temperatureController,
                                    label: 'Temperature',
                                    hint: '°F',
                                    icon: Icons.thermostat_outlined,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _bloodPressureController,
                                    label: 'Blood Pressure',
                                    hint: 'mmHg',
                                    icon: Icons.favorite_outline,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _heartRateController,
                                    label: 'Heart Rate',
                                    hint: 'bpm',
                                    icon: Icons.monitor_heart_outlined,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _respiratoryRateController,
                                    label: 'Respiratory Rate',
                                    hint: 'breaths/min',
                                    icon: Icons.air_outlined,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _oxygenSaturationController,
                                    label: 'O₂ Saturation',
                                    hint: '%',
                                    icon: Icons.water_drop_outlined,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _weightController,
                                    label: 'Weight',
                                    hint: 'kg',
                                    icon: Icons.scale_outlined,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            _buildTextField(
                              controller: _heightController,
                              label: 'Height',
                              hint: 'cm',
                              icon: Icons.height_outlined,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 20),

                            // Examination Findings
                            _buildTextField(
                              controller: _examinationController,
                              label: 'Physical Examination',
                              hint:
                                  'Record physical examination findings and observations',
                              icon: Icons.medical_services_outlined,
                              maxLines: 4,
                            ),
                            const SizedBox(height: 20),

                            // Medications
                            _buildTextField(
                              controller: _medicationController,
                              label: 'Medications',
                              hint:
                                  'List current medications (e.g., Aspirin 500mg daily, Lisinopril 10mg)',
                              icon: Icons.medical_information,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 24),

                            // Initial Diagnosis and Treatment Plan
                            _buildTextField(
                              controller: _diagnosisController,
                              label: 'Initial Diagnosis and Treatment Plan',
                              hint:
                                  'Enter your initial diagnosis based on the examination and findings',
                              icon: Icons.medical_information_outlined,
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your initial diagnosis';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Analyze Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _hasDiagnosisText && !_isAnalyzing
                                    ? _analyzeDiagnosis
                                    : null,
                                icon: _isAnalyzing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF059669),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.analytics_outlined,
                                        size: 18,
                                      ),
                                label: Text(
                                  _isAnalyzing
                                      ? 'AI is analyzing... (may take 2-3 minutes)'
                                      : 'Analyze Diagnosis with AI',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF059669),
                                  side: const BorderSide(
                                    color: Color(0xFF059669),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  disabledForegroundColor: Colors.grey.shade400,
                                  disabledBackgroundColor: Colors.grey.shade50,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Save Encounter',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // AI Suggestions Panel (right side)
          ),
          Expanded(flex: 1, child: _buildAISuggestionsPanel()),
        ],
      ),
    );
  }

  Widget _buildAISuggestionsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tabbed Panel Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Tab 1: AI Suggestions
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPanelTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedPanelTab == 0
                                    ? const Color(0xFF2563EB)
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 18,
                                color: _selectedPanelTab == 0
                                    ? const Color(0xFF2563EB)
                                    : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AI Suggestions',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedPanelTab == 0
                                      ? const Color(0xFF2563EB)
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Divider
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.grey.shade200,
                    ),
                    // Tab 2: Timeline (only show if follow-up)
                    if (_isFollowUp)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPanelTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _selectedPanelTab == 1
                                      ? Colors.purple.shade700
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.timeline,
                                  size: 18,
                                  color: _selectedPanelTab == 1
                                      ? Colors.purple.shade700
                                      : Colors.grey.shade500,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Visit Timeline',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedPanelTab == 1
                                        ? Colors.purple.shade700
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: _selectedPanelTab == 0
                ? _buildAISuggestionsContent()
                : _buildTimelineContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildAISuggestionsContent() {
    return _isAnalyzing
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'AI is analyzing your diagnosis...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This may take 2-3 minutes\nusing local AI model (Microsoft Phi-2)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          )
        : _hasAnalyzed && _analysisResults != null
        ? SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildAnalysisResultsContent(),
          )
        : Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Analysis Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your initial diagnosis and click "Analyze" to get AI-powered suggestions',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildTimelineContent() {
    return _isLoadingVisits
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading timeline...',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        : _caseVisits.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_outlined,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No visits found',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ..._caseVisits.asMap().entries.map((entry) {
                  final index = entry.key;
                  final visit = entry.value;
                  final isLastVisit = index == _caseVisits.length - 1;

                  return Column(
                    children: [
                      _buildTimelineVisitCard(visit, index),
                      if (!isLastVisit)
                        Container(
                          height: 16,
                          alignment: Alignment.center,
                          child: Container(
                            width: 2,
                            height: 12,
                            color: Colors.grey.shade300,
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
          );
  }

  Widget _buildTimelineVisitCard(Map<String, dynamic> visit, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.purple.shade300, width: 2),
            ),
            child: Center(
              child: Text(
                '${visit['visit_number'] ?? index + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Visit details
          Expanded(
            child: Container(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        visit['chief_complaint'] ?? 'No complaint',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Visit ${visit['visit_number'] ?? index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDateTime(visit['created_at']),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (visit['diagnosis'] != null &&
                      visit['diagnosis'].toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Diagnosis: ${visit['diagnosis']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(icon, color: Colors.grey[500], size: 20),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    

    if (widget.selectedPatientId == null || widget.selectedPatientId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please select a patient first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get current user (doctor)
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ You must be logged in to save encounters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💾 Saving encounter...'),
        backgroundColor: Color(0xFF2563EB),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Prepare vital signs
      final vitalSigns = VitalSigns(
        temperature: _temperatureController.text.isNotEmpty
            ? double.tryParse(_temperatureController.text)
            : null,
        bloodPressure: _bloodPressureController.text.isNotEmpty
            ? _bloodPressureController.text
            : null,
        heartRate: _heartRateController.text.isNotEmpty
            ? double.tryParse(_heartRateController.text)
            : null,
        respiratoryRate: _respiratoryRateController.text.isNotEmpty
            ? double.tryParse(_respiratoryRateController.text)
            : null,
        oxygenSaturation: _oxygenSaturationController.text.isNotEmpty
            ? double.tryParse(_oxygenSaturationController.text)
            : null,
        weight: _weightController.text.isNotEmpty
            ? double.tryParse(_weightController.text)
            : null,
        height: _heightController.text.isNotEmpty
            ? double.tryParse(_heightController.text)
            : null,
      );

      // Save encounter
      final response = await _encounterService.saveEncounter(
        doctorId: currentUser.id,
        patientId: widget.selectedPatientId!,
        caseId: widget.parentCaseId, // Pass parent case_id if follow-up
        chiefComplaint: _complaintController.text.trim(),
        historyOfIllness: _historyController.text.trim(),
        allergies: _allergiesController.text.trim(),
        vitalSigns: vitalSigns,
        physicalExam: _examinationController.text.trim(),
        diagnosis: _diagnosisController.text.trim(),
        medications: _medicationController.text.trim(),
      );

      // Save allergies if they were modified
      if (_allergiesController.text.trim() !=
          (widget.selectedPatientDetails?.allergies ?? '')) {
        try {
          await _encounterService.updatePatientAllergies(
            patientId: widget.selectedPatientId!,
            allergies: _allergiesController.text.trim(),
          );
        } catch (e) {
          // Don't stop the flow if allergies update fails
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${response.message}'),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 3),
          ),
        );

        // Optionally clear form or navigate away
        // Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error saving encounter: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to save: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _analyzeDiagnosis() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Prepare vital signs
      final vitalSigns = VitalSigns(
        temperature: _temperatureController.text.isNotEmpty
            ? double.tryParse(_temperatureController.text)
            : null,
        bloodPressure: _bloodPressureController.text.isNotEmpty
            ? _bloodPressureController.text
            : null,
        heartRate: _heartRateController.text.isNotEmpty
            ? double.tryParse(_heartRateController.text)
            : null,
        respiratoryRate: _respiratoryRateController.text.isNotEmpty
            ? double.tryParse(_respiratoryRateController.text)
            : null,
        oxygenSaturation: _oxygenSaturationController.text.isNotEmpty
            ? double.tryParse(_oxygenSaturationController.text)
            : null,
        weight: _weightController.text.isNotEmpty
            ? double.tryParse(_weightController.text)
            : null,
        height: _heightController.text.isNotEmpty
            ? double.tryParse(_heightController.text)
            : null,
      );

      // Call API
      final response = await _encounterService.analyzeEncounter(
        patientId: widget.selectedPatientName ?? 'Unknown Patient',
        diagnosis: _diagnosisController.text,
        symptoms: _complaintController.text.isNotEmpty
            ? _complaintController.text
            : 'No symptoms provided',
        vitalSigns: vitalSigns,
        examinationFindings: _examinationController.text.isNotEmpty
            ? _examinationController.text
            : null,
        medications: _medicationController.text.isNotEmpty
            ? _medicationController.text
            : null,
      );

      setState(() {
        _analysisResults = response;
        _hasAnalyzed = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Analysis completed successfully!'),
            backgroundColor: Color(0xFF059669),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error analyzing diagnosis: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Analysis failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _addToDiagnosis(String text) {
    setState(() {
      final currentDiagnosis = _diagnosisController.text;
      if (currentDiagnosis.isEmpty) {
        _diagnosisController.text = text;
      } else {
        _diagnosisController.text = '$currentDiagnosis\n• $text';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to diagnosis: $text'),
        backgroundColor: const Color(0xFF059669),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildAnalysisResultsContent() {
    if (_analysisResults == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Missed Diagnoses
        if (_analysisResults!.missedDiagnoses.isNotEmpty) ...[
          const Text(
            'Potential Missed Diagnoses',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          ..._analysisResults!.missedDiagnoses.map(
            (diagnosis) => _buildSuggestionCard(
              title: diagnosis.title,
              description: diagnosis.description,
              badge: diagnosis.confidence,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Potential Issues
        if (_analysisResults!.potentialIssues.isNotEmpty) ...[
          const Text(
            'Potential Issues',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          ..._analysisResults!.potentialIssues.map(
            (issue) => _buildSuggestionCard(
              title: issue.title,
              description: issue.description,
              badge: issue.severity,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Recommended Tests
        if (_analysisResults!.recommendedTests.isNotEmpty) ...[
          const Text(
            'Recommended Tests',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          ..._analysisResults!.recommendedTests.map(
            (test) => _buildSuggestionCard(
              title: test.title,
              description: test.description,
              badge: test.priority,
              color: Colors.blue,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuggestionCard({
    required String title,
    required String description,
    required String badge,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.lightbulb_outline, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _addToDiagnosis(title),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Add', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
