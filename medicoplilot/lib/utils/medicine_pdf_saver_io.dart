import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<void> saveMedicinePdf(Uint8List pdfBytes, String fileName) async {
  // Let the user choose where to save the PDF
  String? outputPath = await FilePicker.platform.saveFile(
    dialogTitle: 'Save Medicine PDF',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );

  // If user cancelled the dialog, fall back to Downloads directory
  if (outputPath == null) {
    final directory =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    outputPath = '${directory.path}/$fileName';
  }

  // Ensure .pdf extension
  if (!outputPath.toLowerCase().endsWith('.pdf')) {
    outputPath = '$outputPath.pdf';
  }

  final file = File(outputPath);
  await file.writeAsBytes(pdfBytes, flush: true);
}
