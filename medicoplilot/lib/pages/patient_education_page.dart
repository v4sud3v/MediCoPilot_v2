import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class PatientEducationPage extends StatefulWidget {
  const PatientEducationPage({super.key});

  @override
  State<PatientEducationPage> createState() => _PatientEducationPageState();
}

class _PatientEducationPageState extends State<PatientEducationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _pendingEducation = [];
  List<Map<String, dynamic>> _sentEducation = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEducationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEducationData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final doctorId = _authService.currentUser?.id;
      if (doctorId == null) {
        setState(() {
          _errorMessage = 'Please log in to view education materials';
          _isLoading = false;
        });
        return;
      }

      // Fetch pending education materials
      final pendingResponse = await _apiService.getPatientEducationForDoctor(
        doctorId,
        status: 'pending',
      );

      // Fetch sent education materials
      final sentResponse = await _apiService.getPatientEducationForDoctor(
        doctorId,
        status: 'sent',
      );

      setState(() {
        _pendingEducation = _parseEducationList(pendingResponse);
        _sentEducation = _parseEducationList(sentResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load education materials: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _parseEducationList(dynamic response) {
    if (response == null || response['education_list'] == null) {
      return [];
    }

    final List educationList = response['education_list'] as List;
    return educationList.map((edu) {
      return {
        'id': edu['id'],
        'encounter_id': edu['encounter_id'],
        'patient_id': edu['patient_id'],
        'patient':
            '${edu['patient_name'] ?? 'Unknown'} - ${edu['patient_age'] ?? 'N/A'} years, ${edu['patient_gender'] ?? 'N/A'}',
        'encounter':
            'Visit #${edu['visit_number'] ?? 1} - ${edu['encounter_chief_complaint'] ?? 'N/A'}',
        'title': edu['title'] ?? 'Education Material',
        'description': edu['description'] ?? 'AI-generated education material',
        'content': edu['content'] ?? '',
        'status': edu['status'] ?? 'pending',
        'generatedAt': _parseDateTime(edu['created_at']),
        'sentAt': edu['sent_at'] != null
            ? _parseDateTime(edu['sent_at'])
            : null,
      };
    }).toList();
  }

  DateTime _parseDateTime(String? dateStr) {
    if (dateStr == null) return DateTime.now();
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime.now();
    }
  }

  Future<void> _sendEducation(Map<String, dynamic> education) async {
    try {
      await _apiService.sendPatientEducation(education['id']);

      // Refresh the list
      await _loadEducationData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Education material sent to patient successfully!'),
            backgroundColor: Color(0xFF16A34A),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send education: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateEducation(
    String educationId, {
    String? title,
    String? description,
    String? content,
  }) async {
    try {
      await _apiService.updatePatientEducation(
        educationId,
        title: title,
        description: description,
        content: content,
      );

      // Refresh the list
      await _loadEducationData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Changes saved successfully!'),
            backgroundColor: Color(0xFF7C3AED),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school_outlined,
                        color: Color(0xFF7C3AED),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Patient Education Module',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AI-generated educational materials for patients',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _loadEducationData,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF7C3AED),
              labelColor: const Color(0xFF7C3AED),
              unselectedLabelColor: Colors.grey.shade600,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pending_actions, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Pending (${_pendingEducation.length})',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Sent (${_sentEducation.length})',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorState()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Pending Tab
                      _buildEducationList(_pendingEducation, isPending: true),
                      // Sent Tab
                      _buildEducationList(_sentEducation, isPending: false),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An error occurred',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadEducationData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationList(
    List<Map<String, dynamic>> educationList, {
    required bool isPending,
  }) {
    if (educationList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.inbox_outlined : Icons.done_all_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isPending
                  ? 'No pending education materials'
                  : 'No sent education materials',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPending
                  ? 'Education materials will appear here after saving encounters'
                  : 'Sent materials will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEducationData,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: educationList.length,
        itemBuilder: (context, index) {
          final education = educationList[index];
          return _buildEducationCard(education, isPending);
        },
      ),
    );
  }

  Widget _buildEducationCard(Map<String, dynamic> education, bool isPending) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPending
                  ? const Color(0xFFFEF08A).withAlpha(128)
                  : const Color(0xFFDCFCE7).withAlpha(128),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isPending
                            ? const Color(0xFFEAB308).withAlpha(25)
                            : const Color(0xFF16A34A).withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isPending ? Icons.pending_actions : Icons.check_circle,
                        color: isPending
                            ? const Color(0xFFEAB308)
                            : const Color(0xFF16A34A),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            education['title'] ?? 'Education Material',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            education['description'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Patient', education['patient']),
                const SizedBox(height: 12),
                _buildInfoRow('Encounter', education['encounter']),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Generated',
                  _formatDateTime(education['generatedAt']),
                ),
                if (!isPending && education['sentAt'] != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow('Sent', _formatDateTime(education['sentAt'])),
                ],
                const SizedBox(height: 16),
                // Preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Content Preview:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        education['content']
                            .toString()
                            .replaceAll('\n', ' ')
                            .substring(
                              0,
                              (education['content'].toString().length > 200)
                                  ? 200
                                  : education['content'].toString().length,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showFullContent(context, education),
                    icon: const Icon(Icons.preview, size: 18),
                    label: const Text('View Full'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (isPending) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditDialog(context, education),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7C3AED),
                        side: const BorderSide(color: Color(0xFF7C3AED)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showSendDialog(context, education),
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Send'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ] else
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showResendDialog(context, education),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Resend'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF059669),
                        side: const BorderSide(color: Color(0xFF059669)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showFullContent(BuildContext context, Map<String, dynamic> education) {
    final bool isPending = education['status'] == 'pending';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Color(0xFF7C3AED),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                education['title'] ?? 'Education Material',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Text(
              education['content'] ?? '',
              style: const TextStyle(fontSize: 13, height: 1.6),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (isPending)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showEditDialog(context, education);
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7C3AED),
                side: const BorderSide(color: Color(0xFF7C3AED)),
              ),
            ),
          if (isPending)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showSendDialog(context, education);
              },
              icon: const Icon(Icons.send, size: 18),
              label: const Text('Send to Patient'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> education) {
    final titleController = TextEditingController(text: education['title']);
    final descriptionController = TextEditingController(
      text: education['description'],
    );
    final contentController = TextEditingController(text: education['content']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit, color: Color(0xFF7C3AED), size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Edit Education Material'),
          ],
        ),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.amber.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Review and edit the AI-generated content before sending to the patient.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Patient: ${education['patient']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Encounter: ${education['encounter']}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Title',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Enter title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Enter description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Content',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    hintText: 'Enter content',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: const TextStyle(fontSize: 13, height: 1.6),
                  maxLines: 15,
                  minLines: 10,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              titleController.dispose();
              descriptionController.dispose();
              contentController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              // Save changes
              await _updateEducation(
                education['id'],
                title: titleController.text,
                description: descriptionController.text,
                content: contentController.text,
              );
              titleController.dispose();
              descriptionController.dispose();
              contentController.dispose();
              if (mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save Changes'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7C3AED),
              side: const BorderSide(color: Color(0xFF7C3AED)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              // Save and send
              await _updateEducation(
                education['id'],
                title: titleController.text,
                description: descriptionController.text,
                content: contentController.text,
              );
              titleController.dispose();
              descriptionController.dispose();
              contentController.dispose();
              if (mounted) {
                Navigator.pop(context);
                _showSendDialog(context, education);
              }
            },
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Save & Send'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showSendDialog(BuildContext context, Map<String, dynamic> education) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF16A34A)),
            SizedBox(width: 12),
            Text('Send Education Material'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This will send the education material to the patient via their patient portal.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Patient: ${education['patient']}',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Material: ${education['title']}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sendEducation(education);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Now'),
          ),
        ],
      ),
    );
  }

  void _showResendDialog(BuildContext context, Map<String, dynamic> education) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.refresh, color: Color(0xFF059669)),
            SizedBox(width: 12),
            Text('Resend Education Material'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
                  Icon(
                    Icons.info_outline,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This will resend the education material to the patient.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Patient: ${education['patient']}',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Previously sent: ${_formatDateTime(education['sentAt'] ?? DateTime.now())}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sendEducation(education);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('Resend Now'),
          ),
        ],
      ),
    );
  }
}
