import 'package:flutter/material.dart';
import '../../components/common/common.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/mock_data.dart';

/// File upload page for uploading lab results and imaging
class FileUploadPage extends StatefulWidget {
  final List<UploadedFile> uploadedFiles;
  final Function(UploadedFile) onFileUpload;
  final Function(String) onFileDelete;

  const FileUploadPage({
    super.key,
    required this.uploadedFiles,
    required this.onFileUpload,
    required this.onFileDelete,
  });

  @override
  State<FileUploadPage> createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  String? _selectedPatientId;
  final _descriptionController = TextEditingController();
  final _textInputController = TextEditingController();

  void _handleTextSubmit() {
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient first'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (_textInputController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some text'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final textFile = UploadedFile(
      id: 'F${DateTime.now().millisecondsSinceEpoch}',
      encounterId: 'E001',
      patientId: _selectedPatientId!,
      fileName: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : 'Lab Results Text',
      fileType: FileType.text,
      uploadDate: DateTime.now(),
      status: FileStatus.uploaded,
    );

    widget.onFileUpload(textFile);
    _descriptionController.clear();
    _textInputController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Text data saved successfully'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _simulateFileUpload() {
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient first'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final uploadedFile = UploadedFile(
      id: 'F${DateTime.now().millisecondsSinceEpoch}',
      encounterId: 'E001',
      patientId: _selectedPatientId!,
      fileName: 'sample_upload_${DateTime.now().millisecondsSinceEpoch}.pdf',
      fileType: FileType.pdf,
      uploadDate: DateTime.now(),
      status: FileStatus.uploaded,
    );

    widget.onFileUpload(uploadedFile);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File uploaded successfully'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _textInputController.dispose();
    super.dispose();
  }

  IconData _getFileIcon(FileType type) {
    switch (type) {
      case FileType.pdf:
        return Icons.picture_as_pdf;
      case FileType.jpg:
      case FileType.png:
        return Icons.image;
      default:
        return Icons.description;
    }
  }

  Color _getFileIconColor(FileType type) {
    switch (type) {
      case FileType.pdf:
        return AppTheme.red;
      case FileType.jpg:
      case FileType.png:
        return AppTheme.blue;
      default:
        return AppTheme.textSecondary;
    }
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
            'Lab & Imaging Upload',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Upload lab results, X-rays, and other medical documents',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),

          // Upload section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload Files',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  // Patient selection
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
                            child: Text(
                                '${patient.name} - ${patient.age}y, ${patient.gender}'),
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
                  const SizedBox(height: 24),

                  // File drop zone (simulated)
                  InkWell(
                    onTap: _simulateFileUpload,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.border,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 48,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Click to upload files',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'PDF, JPG, PNG files accepted',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _simulateFileUpload,
                            child: const Text('Choose Files'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Text input section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paste Lab Results / Imaging Notes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Description',
                    hint: 'e.g., CBC Results, Chest X-Ray Impression',
                    controller: _descriptionController,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Results / Notes',
                    hint: 'Paste lab results or imaging impressions here...',
                    controller: _textInputController,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _handleTextSubmit,
                    icon: const Icon(Icons.upload),
                    label: const Text('Save Text Data'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Uploaded files list
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Uploaded Files',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  if (widget.uploadedFiles.isEmpty)
                    const EmptyState(
                      icon: Icons.folder_open,
                      title: 'No files uploaded yet',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.uploadedFiles.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final file = widget.uploadedFiles[index];
                        return ListTile(
                          leading: Icon(
                            _getFileIcon(file.fileType),
                            color: _getFileIconColor(file.fileType),
                          ),
                          title: Text(file.fileName),
                          subtitle: Text(
                            'Uploaded: ${_formatDate(file.uploadDate)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                file.status == FileStatus.uploaded
                                    ? Icons.check_circle
                                    : Icons.warning,
                                color: file.status == FileStatus.uploaded
                                    ? AppTheme.success
                                    : AppTheme.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => widget.onFileDelete(file.id),
                                icon: const Icon(Icons.delete_outline,
                                    color: AppTheme.red),
                              ),
                            ],
                          ),
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
