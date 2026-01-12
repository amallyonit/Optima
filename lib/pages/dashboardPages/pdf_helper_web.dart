// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;

void saveAndOpenPDF(List<int> bytes) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Automatically open the PDF in a new tab
  html.window.open(url, '_blank');
}
