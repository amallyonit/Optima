// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;

void saveAndOpenExcel(String fileName, List<int> bytes) {
  final blob = html.Blob([bytes],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Create a downloadable link
  final anchor = html.AnchorElement(href: url)
    ..target = 'blank'
    ..download = fileName; // Set the file name for the download
  anchor.click();

  // Release the object URL to free up memory
  html.Url.revokeObjectUrl(url);
}
