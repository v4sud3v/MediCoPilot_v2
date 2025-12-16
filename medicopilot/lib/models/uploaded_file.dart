/// File type enum
enum FileType {
  pdf,
  jpg,
  png,
  text;

  static FileType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pdf':
        return FileType.pdf;
      case 'jpg':
      case 'jpeg':
        return FileType.jpg;
      case 'png':
        return FileType.png;
      default:
        return FileType.text;
    }
  }
}

/// File upload status
enum FileStatus {
  uploaded,
  processing,
  error;
}

/// Uploaded file model
class UploadedFile {
  final String id;
  final String encounterId;
  final String patientId;
  final String fileName;
  final FileType fileType;
  final DateTime uploadDate;
  final FileStatus status;
  final String? fileUrl;

  const UploadedFile({
    required this.id,
    required this.encounterId,
    required this.patientId,
    required this.fileName,
    required this.fileType,
    required this.uploadDate,
    required this.status,
    this.fileUrl,
  });

  factory UploadedFile.fromJson(Map<String, dynamic> json) {
    return UploadedFile(
      id: json['id'] as String,
      encounterId: json['encounterId'] as String,
      patientId: json['patientId'] as String,
      fileName: json['fileName'] as String,
      fileType: FileType.fromString(json['fileType'] as String),
      uploadDate: DateTime.parse(json['uploadDate'] as String),
      status: FileStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => FileStatus.uploaded,
      ),
      fileUrl: json['fileUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'encounterId': encounterId,
      'patientId': patientId,
      'fileName': fileName,
      'fileType': fileType.name,
      'uploadDate': uploadDate.toIso8601String(),
      'status': status.name,
      'fileUrl': fileUrl,
    };
  }
}
