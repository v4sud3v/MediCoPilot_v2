import 'package:flutter/material.dart';

class PatientEducationPage extends StatefulWidget {
  const PatientEducationPage({super.key});

  @override
  State<PatientEducationPage> createState() => _PatientEducationPageState();
}

class _PatientEducationPageState extends State<PatientEducationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample education data - replace with your actual data source
  final List<Map<String, dynamic>> _pendingEducation = [
    {
      'id': '001',
      'patient': 'John Doe - MRN: 12345',
      'encounter': 'Encounter #001',
      'title': 'Understanding Acute Bronchitis',
      'description': 'AI-generated education material about your diagnosis',
      'generatedAt': DateTime(2025, 12, 18, 10, 30),
      'content': '''
Acute Bronchitis - Patient Education

What is Acute Bronchitis?
Acute bronchitis is an inflammation of the airways in the lungs, typically caused by viral infections. It's characterized by persistent coughing and respiratory discomfort.

Symptoms:
- Persistent cough (may last 2-3 weeks)
- Production of mucus (clear, white, or yellow)
- Fatigue and weakness
- Shortness of breath
- Low-grade fever
- Chest discomfort

Recommended Care:
1. Get plenty of rest
2. Stay hydrated - drink plenty of water
3. Use a humidifier to ease congestion
4. Avoid smoking and smoke exposure
5. Use over-the-counter pain relievers as directed
6. Follow prescribed antibiotic regimen

When to Seek Medical Attention:
- If fever persists beyond 3 days
- If you experience severe shortness of breath
- If cough worsens or persists beyond 3 weeks
- If you cough up blood

Recovery Timeline:
Most cases resolve within 2-3 weeks with proper care and rest.
      ''',
    },
    {
      'id': '002',
      'patient': 'Jane Smith - MRN: 12346',
      'encounter': 'Encounter #002',
      'title': 'Managing Migraine Headaches',
      'description': 'Comprehensive guide for migraine management',
      'generatedAt': DateTime(2025, 12, 17, 14, 15),
      'content': '''
Migraine Management - Patient Education

What is a Migraine?
A migraine is a neurological condition characterized by intense, debilitating headaches often accompanied by other symptoms.

Migraine Symptoms:
- Severe throbbing pain on one or both sides of the head
- Sensitivity to light and sound
- Nausea or vomiting
- Visual disturbances or aura
- Numbness or tingling

Triggers to Avoid:
- Stress and anxiety
- Certain foods (chocolate, cheese, MSG)
- Changes in sleep patterns
- Hormonal changes
- Weather changes
- Excessive caffeine

Management Strategies:
1. Maintain a consistent sleep schedule
2. Stay well-hydrated
3. Identify and avoid triggers
4. Use prescribed medications as directed
5. Practice relaxation techniques
6. Apply cold/warm compresses

When to Seek Emergency Care:
- Sudden severe headache unlike previous migraines
- Headache accompanied by fever, stiff neck
- Headache with vision changes or weakness
      ''',
    },
    {
      'id': '003',
      'patient': 'Robert Johnson - MRN: 12347',
      'encounter': 'Encounter #003',
      'title': 'Heart Health and Anxiety Management',
      'description': 'Educational resource for anxiety-related chest pain',
      'generatedAt': DateTime(2025, 12, 16, 9, 0),
      'content': '''
Anxiety and Heart Health - Patient Education

Understanding Anxiety-Related Chest Pain
While your chest pain was evaluated as anxiety-related, it's important to understand the connection between mental health and physical symptoms.

How Anxiety Causes Chest Pain:
- Muscle tension in the chest
- Rapid heartbeat and hyperventilation
- Increased adrenaline release
- Heightened sensitivity to body sensations

Recommended Coping Strategies:
1. Deep breathing exercises (4-7-8 technique)
2. Progressive muscle relaxation
3. Mindfulness meditation
4. Regular physical activity (with clearance)
5. Adequate sleep and rest
6. Limiting caffeine and alcohol
7. Keeping a stress diary

When to Seek Help:
- If symptoms persist or worsen
- If anxiety is affecting daily functioning
- If you need professional mental health support

Cardiology Follow-up:
Please continue with your scheduled cardiology evaluation as recommended.
      ''',
    },
  ];

  final List<Map<String, dynamic>> _sentEducation = [
    {
      'id': '501',
      'patient': 'Emily Davis - MRN: 12348',
      'encounter': 'Encounter #004',
      'title': 'Managing Seasonal Allergies',
      'description': 'AI-generated allergy management guide',
      'generatedAt': DateTime(2025, 12, 15, 16, 45),
      'sentAt': DateTime(2025, 12, 15, 17, 30),
      'status': 'Sent',
      'content': '''
Seasonal Allergies - Patient Education

Understanding Seasonal Allergies
Seasonal allergies occur when your immune system overreacts to pollen and other environmental triggers.

Common Symptoms:
- Sneezing and nasal congestion
- Itchy eyes and throat
- Runny nose
- Post-nasal drip

Effective Management:
1. Take prescribed antihistamines
2. Avoid outdoor activities during high pollen times
3. Keep windows closed during allergy season
4. Use air filters in home and car
5. Wash hands and change clothes after outdoor time
6. Use saline nasal rinse

Additional Tips:
- Monitor pollen counts
- Consider wearing sunglasses outdoors
- Shower before bed to remove pollen

When to Contact Your Doctor:
- If symptoms worsen despite medication
- If new symptoms develop
      ''',
    },
    {
      'id': '502',
      'patient': 'Michael Brown - MRN: 12349',
      'encounter': 'Encounter #005',
      'title': 'Back Pain Prevention and Treatment',
      'description': 'Physical therapy and lifestyle modifications',
      'generatedAt': DateTime(2025, 12, 14, 11, 20),
      'sentAt': DateTime(2025, 12, 14, 12, 45),
      'status': 'Sent',
      'content': '''
Back Pain Management - Patient Education

Understanding Muscle Strain
Muscle strain in the back is a common condition that responds well to proper treatment and prevention strategies.

Pain Management:
1. Apply ice for first 48 hours
2. Switch to heat therapy after 48 hours
3. Take prescribed pain relievers
4. Avoid heavy lifting and strenuous activity

Physical Therapy Exercises:
- Gentle stretching
- Core strengthening exercises
- Low-impact aerobic activity
- Proper posture practice

Prevention Tips:
1. Maintain proper posture
2. Use correct lifting techniques
3. Take regular breaks if sitting for long periods
4. Stay physically active
5. Maintain healthy weight
6. Use ergonomic furniture

Expected Recovery:
Most muscle strains improve within 2-6 weeks with proper treatment and rest.
      ''',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            child: TabBarView(
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
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: educationList.length,
      itemBuilder: (context, index) {
        final education = educationList[index];
        return _buildEducationCard(education, isPending);
      },
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
                if (isPending)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showSendDialog(context, education),
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Send to Patient'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  )
                else
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Education material sent to patient successfully!',
                  ),
                  backgroundColor: const Color(0xFF16A34A),
                  duration: const Duration(seconds: 3),
                ),
              );
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
              'Previously sent: ${_formatDateTime(education['sentAt'])}',
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Education material resent to patient successfully!',
                  ),
                  backgroundColor: const Color(0xFF059669),
                  duration: const Duration(seconds: 3),
                ),
              );
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
