import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:optima/excel_helper.dart';
import 'package:path_provider/path_provider.dart';
import '../../../excel_helper_other.dart';

class ManpowerExcelExporter {
  static Future<void> exportManpowerExcel(
    List<String> particulars,
    List<List<String>> rows,
  ) async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Manpower Costing'];

    String monthYear = DateFormat('MMMM yyyy').format(DateTime.now());

    /// Caption
    sheet.appendRow(toCellRow(["Working for the Month of $monthYear"]));

    /// Blank row
    sheet.appendRow([]);

    /// Headers
    final headers = [
      'Particulars',
      'Total',
      'Increase/Decrease with Target',
      '$monthYear Total',
      '$monthYear % w.r.t Current Month',
      'Last 3 months Total',
      'Last 3 months % w.r.t Current Month',
      'Last 12 Months Total',
      'Last 12 Months % w.r.t Current Month',
    ];

    sheet.appendRow(toCellRow(headers));

    /// Data rows
    for (int r = 0; r < particulars.length; r++) {
      List<dynamic> row = [particulars[r]];

      for (int c = 0; c < headers.length - 1; c++) {
        if (r < rows.length && c < rows[r].length) {
          row.add(rows[r][c]);
        } else {
          row.add("");
        }
      }

      sheet.appendRow(toCellRow(row));
    }

    /// Save file
    if (kIsWeb) {
      final excelBytes = excel.encode()!;
      saveAndOpenExcel('manpower_costing_report.xlsx', excelBytes);
    } else {
      String storageDir = await getStorageDirectory();
      final file = File('$storageDir/manpower_costing_report.xlsx');

      await file.writeAsBytes(excel.encode()!);

      OpenFile.open(file.path);
    }
  }

  static Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }
}
