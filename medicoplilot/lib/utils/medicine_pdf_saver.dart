import 'dart:typed_data';

import 'medicine_pdf_saver_io.dart'
    if (dart.library.html) 'medicine_pdf_saver_web.dart' as impl;

Future<void> saveMedicinePdf(Uint8List pdfBytes, String fileName) {
  return impl.saveMedicinePdf(pdfBytes, fileName);
}
