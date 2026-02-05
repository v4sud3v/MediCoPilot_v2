import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:medicoplilot/pages/encounter_details_page.dart';
import 'package:medicoplilot/services/encounter_service.dart';
import 'package:medicoplilot/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

class AllEncountersPage extends StatefulWidget {
  const AllEncountersPage({super.key});

  @override
  State<AllEncountersPage> createState() => _AllEncountersPageState();
}

class _AllEncountersPageState extends State<AllEncountersPage> {
  DateTime? _selectedDate;
  String? _selectedPatientFilter;
  final Map<String, bool> _expandedCases = {}; // Track expanded cases

  // Store uploaded files for each encounter
  final Map<String, List<Map<String, String>>> _encounterFiles = {};

  // Services
  final _encounterService = EncounterService();

  // API data
  List<Map<String, dynamic>> _allEncounters = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEncounters();
  }

  Future<void> _loadEncounters() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get current user (doctor)
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'You must be logged in to view encounters';
          });
        }
        return;
      }

      // Fetch encounters for the logged-in doctor
      final encounters = await _encounterService.getEncountersForDoctor(
        currentUser.id,
      );

      if (mounted) {
        setState(() {
          _allEncounters = encounters;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading encounters: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load encounters: ${e.toString()}';
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredEncounters {
    var filtered = _allEncounters;

    if (_selectedDate != null) {
      filtered = filtered.where((encounter) {
        final createdAt = encounter['created_at'];
        DateTime date;
        if (createdAt is String) {
          date = DateTime.parse(createdAt);
        } else if (createdAt is DateTime) {
          date = createdAt;
        } else {
          return false;
        }
        return date.year == _selectedDate!.year &&
            date.month == _selectedDate!.month &&
            date.day == _selectedDate!.day;
      }).toList();
    }

    if (_selectedPatientFilter != null) {
      filtered = filtered.where((encounter) {
        final patientName =
            encounter['patient_name']?.toString().toLowerCase() ?? '';
        return patientName.contains(_selectedPatientFilter!.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  // Group encounters by case_id
  Map<String, List<Map<String, dynamic>>> get _groupedEncounters {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var encounter in _filteredEncounters) {
      final caseId = encounter['case_id'] ?? 'UNKNOWN';
      if (!grouped.containsKey(caseId)) {
        grouped[caseId] = [];
      }
      grouped[caseId]!.add(encounter);
    }

    // Sort visits within each case
    grouped.forEach((caseId, visits) {
      visits.sort(
        (a, b) => (a['visit_number'] ?? 0).compareTo(b['visit_number'] ?? 0),
      );
    });

    return grouped;
  }

  Future<Map<String, String>?> _uploadFile(String encounterId) async {
    String selectedType = 'X-Ray';
    String? selectedFilePath;
    String? selectedFileName;

    // Pick file first
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      selectedFilePath = result.files.single.path;
      selectedFileName = result.files.single.name;

      if (!mounted) return null;

      // Show dialog to select document type and wait for result
      final uploadedFile = await showDialog<Map<String, String>?>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.upload_file, color: Color(0xFF2563EB)),
                SizedBox(width: 12),
                Text('Categorize Document'),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
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
                          Icons.check_circle,
                          size: 20,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'File selected: $selectedFileName',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Document Type',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'X-Ray', child: Text('X-Ray')),
                      DropdownMenuItem(
                        value: 'Lab Notes',
                        child: Text('Lab Notes'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  // Save file to app directory
                  try {
                    final appDir = await getApplicationDocumentsDirectory();
                    final encounterDir = Directory(
                      '${appDir.path}/encounters/$encounterId',
                    );

                    if (!await encounterDir.exists()) {
                      await encounterDir.create(recursive: true);
                    }

                    final timestamp = DateTime.now().millisecondsSinceEpoch;
                    final newFileName = '${timestamp}_$selectedFileName';
                    final newFilePath = '${encounterDir.path}/$newFileName';

                    // Copy file to app directory
                    await File(selectedFilePath!).copy(newFilePath);

                    // Save document to Supabase
                    final apiService = ApiService();
                    final documentType = selectedType == 'X-Ray' ? 'XRAY' : 'REPORT';
                    
                    try {
                      final response = await apiService.uploadDocument(
                        encounterId: encounterId,
                        fileUrl: newFilePath,
                        documentType: documentType,
                      );
                      
                      final newFile = {
                        'id': response['document']?['id'] ?? '',
                        'name': selectedFileName!,
                        'type': selectedType,
                        'path': newFilePath,
                        'uploadDate': DateTime.now().toString(),
                      };

                      if (!context.mounted) return;
                      Navigator.pop(context, newFile);
                    } catch (apiError) {
                      // File saved locally but failed to save to database
                      debugPrint('Error saving document to database: $apiError');
                      final newFile = {
                        'name': selectedFileName!,
                        'type': selectedType,
                        'path': newFilePath,
                        'uploadDate': DateTime.now().toString(),
                      };
                      if (!context.mounted) return;
                      Navigator.pop(context, newFile);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('File saved locally. Database sync failed: $apiError'),
                          backgroundColor: const Color(0xFFD97706),
                        ),
                      );
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    Navigator.pop(context, null);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error uploading file: $e'),
                        backgroundColor: const Color(0xFFDC2626),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.upload),
                label: const Text('Upload'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );

      if (uploadedFile != null) {
        // Update parent state
        setState(() {
          if (!_encounterFiles.containsKey(encounterId)) {
            _encounterFiles[encounterId] = [];
          }
          _encounterFiles[encounterId]!.add(uploadedFile);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${uploadedFile['type']} uploaded successfully'),
              backgroundColor: const Color(0xFF059669),
            ),
          );
        }

        return uploadedFile;
      }
    }
    return null;
  }

  void _viewFile(Map<String, String> file) async {
    final filePath = file['path'];
    if (filePath == null || filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File path not found'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final fileExists = await File(filePath).exists();
    if (!fileExists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File not found on device'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    // Open file with default application
    final uri = Uri.file(filePath);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback: show file info dialog
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.insert_drive_file, color: Color(0xFF2563EB)),
                const SizedBox(width: 12),
                Expanded(child: Text(file['name'] ?? 'Document')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFileInfoRow('Type', file['type'] ?? 'Unknown'),
                _buildFileInfoRow('Location', filePath),
                _buildFileInfoRow('Uploaded', file['uploadDate'] ?? 'Unknown'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  // Try to open with system file manager
                  final directory = Directory(filePath).parent;
                  final dirUri = Uri.directory(directory.path);
                  if (await canLaunchUrl(dirUri)) {
                    await launchUrl(dirUri);
                  }
                },
                icon: const Icon(Icons.folder_open),
                label: const Text('Open Folder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Widget _buildFileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  Future<bool> _deleteFile(String encounterId, int fileIndex) async {
    final file = _encounterFiles[encounterId]?[fileIndex];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Delete physical file
              if (file?['path'] != null) {
                try {
                  final fileToDelete = File(file!['path']!);
                  if (await fileToDelete.exists()) {
                    await fileToDelete.delete();
                  }
                } catch (e) {
                  // File deletion failed, but continue to remove from list
                }
              }

              // Delete from Supabase if document has an ID
              if (file?['id'] != null && file!['id']!.isNotEmpty) {
                try {
                  final apiService = ApiService();
                  await apiService.deleteDocument(file['id']!);
                } catch (e) {
                  debugPrint('Error deleting document from database: $e');
                }
              }

              if (!context.mounted) return;
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Update parent state
      setState(() {
        _encounterFiles[encounterId]?.removeAt(fileIndex);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document deleted'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
      return true;
    }
    return false;
  }

  Future<List<Map<String, String>>> _loadDocumentsFromSupabase(String encounterId) async {
    try {
      final apiService = ApiService();
      final response = await apiService.getDocumentsForEncounter(encounterId);
      
      if (response is List) {
        return response.map<Map<String, String>>((doc) {
          return {
            'id': doc['id']?.toString() ?? '',
            'name': doc['file_url']?.toString().split('/').last ?? 'Unknown',
            'type': doc['document_type'] == 'XRAY' ? 'X-Ray' : 'Lab Notes',
            'path': doc['file_url']?.toString() ?? '',
            'uploadDate': doc['created_at']?.toString() ?? '',
          };
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error loading documents: $e');
      return [];
    }
  }

  void _showEncounterDetails(Map<String, dynamic> encounter) async {
    // Load documents from Supabase first
    final encounterId = encounter['id'];
    if (!_encounterFiles.containsKey(encounterId)) {
      final docs = await _loadDocumentsFromSupabase(encounterId);
      if (docs.isNotEmpty) {
        setState(() {
          _encounterFiles[encounterId] = docs;
        });
      }
    }

    if (!mounted) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EncounterDetailPage(
          encounter: encounter,
          initialEncounterFiles: _encounterFiles[encounter['id']] ?? [],
          onUploadFile: () => _uploadFile(encounter['id']),
          onDeleteFile: (index) => _deleteFile(encounter['id'], index),
          onViewFile: (file) => _viewFile(file),
        ),
      ),
    );
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'All Encounters',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'View and manage all patient encounters',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Filters
            Container(
              padding: const EdgeInsets.all(16),
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
                      const Icon(
                        Icons.filter_list,
                        size: 20,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Date Filter
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _selectedDate = date;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedDate != null
                                        ? _formatDate(_selectedDate!)
                                        : 'Filter by date',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _selectedDate != null
                                          ? Colors.black87
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                if (_selectedDate != null)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedDate = null;
                                      });
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Patient Filter
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Filter by patient name',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.person_search,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                            suffixIcon: _selectedPatientFilter != null
                                ? IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _selectedPatientFilter = null;
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _selectedPatientFilter = value.isEmpty
                                  ? null
                                  : value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Encounters List
            Expanded(
              child: Container(
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
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loading encounters...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadEncounters,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _groupedEncounters.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No encounters found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _groupedEncounters.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final caseId = _groupedEncounters.keys
                              .toList()[index];
                          final visits = _groupedEncounters[caseId]!;
                          return _buildCaseCard(caseId, visits);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseCard(String caseId, List<Map<String, dynamic>> visits) {
    final isExpanded = _expandedCases[caseId] ?? false;
    final firstVisit = visits.first;
    final visitCount = visits.length;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Case Header (always visible)
          InkWell(
            onTap: () {
              setState(() {
                _expandedCases[caseId] = !isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: const Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Case: $caseId',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$visitCount visit${visitCount > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              firstVisit['patient_name'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          firstVisit['chief_complaint'] ?? 'No complaint',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Arrow indicator
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
          // Sub-encounters (visits) - shown when expanded
          if (isExpanded) ...[
            Container(height: 1, color: Colors.grey.shade200),
            ...visits.asMap().entries.map((entry) {
              final visitIndex = entry.key;
              final visit = entry.value;
              return _buildVisitTile(visit, visitIndex, visits);
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildVisitTile(
    Map<String, dynamic> visit,
    int visitIndex,
    List<Map<String, dynamic>> allVisits,
  ) {
    return InkWell(
      onTap: () => _showEncounterDetails(visit),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: visitIndex < allVisits.length - 1
              ? Border(bottom: BorderSide(color: Colors.grey.shade200))
              : null,
        ),
        child: Row(
          children: [
            // Visit Number Badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withAlpha(25),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Center(
                child: Text(
                  'V${visit['visit_number'] ?? visitIndex + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Visit Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Visit #${visit['visit_number'] ?? 1}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDateTime(visit['created_at']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Diagnosis: ${visit['diagnosis'] ?? 'Not specified'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
