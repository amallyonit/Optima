import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

Future<void> saveAndOpenPDF(List<int> bytes) async {
  final directory = await getTemporaryDirectory();
  final filePath = '${directory.path}/sales_report.pdf';
  final file = File(filePath);

  await file.writeAsBytes(bytes);

  // Open the PDF using the default viewer on the device
  OpenFile.open(filePath);
}
