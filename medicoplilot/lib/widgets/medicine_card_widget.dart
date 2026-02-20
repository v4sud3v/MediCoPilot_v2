import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/medicine_pdf_saver.dart';

class MedicineCardWidget extends StatelessWidget {
  final String encounterId;
  final String patientName;
  final String doctorName;
  final String? patientEmail;
  final VoidCallback onSuccess;
  final Function(String error) onError;

  const MedicineCardWidget({
    super.key,
    required this.encounterId,
    required this.patientName,
    required this.doctorName,
    this.patientEmail,
    required this.onSuccess,
    required this.onError,
  });

  Future<void> _downloadMedicinePdf(BuildContext context) async {
    final apiService = ApiService();
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating medicine PDF...'),
          duration: Duration(seconds: 2),
        ),
      );

      final pdfBytes = await apiService.downloadMedicinePdf(
        encounterId: encounterId,
        patientName: patientName,
        doctorName: doctorName,
      );

      final fileName = 'medicine_${encounterId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await saveMedicinePdf(Uint8List.fromList(pdfBytes), fileName);
      onSuccess();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicine PDF downloaded successfully!'),
            backgroundColor: Color(0xFF16A34A),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      onError(e.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendMedicinePdfEmail(BuildContext context) async {
    if (patientEmail == null || patientEmail!.isEmpty) {
      onError('Patient email not available');
      return;
    }

    final apiService = ApiService();
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sending medicine PDF...'),
          duration: Duration(seconds: 2),
        ),
      );

      await apiService.sendMedicinePdfEmail(
        encounterId: encounterId,
        patientEmail: patientEmail!,
        patientName: patientName,
        doctorName: doctorName,
      );

      onSuccess();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicine PDF sent to patient via email!'),
            backgroundColor: Color(0xFF16A34A),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      onError(e.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Medication Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Detailed medicine information (shareable without diagnosis)',
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
            const SizedBox(height: 16),
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
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'A separate PDF with medicine details only - can be safely shared without revealing medical conditions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _downloadMedicinePdf(context),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      side: BorderSide(color: Colors.blue.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (patientEmail != null && patientEmail!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _sendMedicinePdfEmail(context),
                      icon: const Icon(Icons.mail_outline, size: 18),
                      label: const Text('Email to Patient'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
