import 'dart:typed_data';
import 'dart:html' as html;

Future<void> saveMedicinePdf(Uint8List pdfBytes, String fileName) async {
  final blob = html.Blob(<dynamic>[pdfBytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
