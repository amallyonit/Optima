import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

Future<void> saveAndOpenExcel(String fileName, List<int> bytes) async {
  final directory = await getTemporaryDirectory();
  final filePath = '${directory.path}/$fileName';
  final file = File(filePath);

  await file.writeAsBytes(bytes);

  // Open the Excel file using the default viewer on the device
  OpenFile.open(filePath);
}
