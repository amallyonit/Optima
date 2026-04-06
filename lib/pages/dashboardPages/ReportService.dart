// ignore_for_file: file_names

import 'dart:io';

// import 'package:excel/excel.dart' as xl;
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:optima/pages/dashboardPages/excel_helper_other.dart';
import 'package:optima/pages/dashboardPages/pdf_helper_other.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
// import '../../excel_helper.dart';

class ReportService {
  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  String _getExcelColumnName(int colIndex) {
    String colName = '';
    while (colIndex > 0) {
      int remainder = (colIndex - 1) % 26;
      colName = String.fromCharCode(65 + remainder) + colName;
      colIndex = (colIndex - 1) ~/ 26;
    }
    return colName;
  }

  // ---------------- PDF GENERATOR ----------------
  Future<void> generatePDF({
    required String title,
    required List<String> headers,
    required List<List<dynamic>> rows,
    required String fileName,
  }) async {
    try {
      final pdf = pw.Document();

      // -------- Title Page --------
      pdf.addPage(
        pw.Page(
          build: (_) => pw.Center(
            child: pw.Text(
              title,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
      );

      // -------- Table Page --------
      pdf.addPage(
        pw.Page(
          build: (_) => pw.Table(
            border: pw.TableBorder.all(),
            children: [
              // Header
              pw.TableRow(
                children: headers.map((h) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      h,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),

              // Rows
              ...rows.map((row) {
                return pw.TableRow(
                  children: row.map((cell) {
                    final isNumber = cell is num;

                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Align(
                        alignment: isNumber
                            ? pw.Alignment.centerRight
                            : pw.Alignment.centerLeft,
                        child: pw.Text(
                          cell.toString(),
                          style: pw.TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      );

      final bytes = await pdf.save();

      if (kIsWeb) {
        saveAndOpenPDF(bytes);
      } else {
        final dir = await getStorageDirectory();
        final file = File('$dir/$fileName');
        await file.writeAsBytes(bytes);
        OpenFile.open(file.path);
      }
    } catch (e) {
      debugPrint("PDF Error: $e");
    }
  }

  // ---------------- EXCEL GENERATOR ----------------
  Future<void> generateExcel({
    required String sheetName,
    required List<String> headers,
    required List<List<dynamic>> rows,
    required String fileName,
    List<int>? amountColumns, // 👈 optional
    bool addTotalRow = false, // 👈 optional
  }) async {
    try {
      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];

      sheet.name = sheetName;

      // ---------------- HEADER ----------------
      for (int col = 0; col < headers.length; col++) {
        sheet.getRangeByIndex(1, col + 1).setText(headers[col]);
      }

      final headerRange = sheet.getRangeByIndex(1, 1, 1, headers.length);

      headerRange.cellStyle.bold = true;
      headerRange.cellStyle.backColor = "#E7F3FF";
      headerRange.cellStyle.hAlign = xlsio.HAlignType.center;

      headerRange.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

      // ---------------- DATA ----------------
      for (int i = 0; i < rows.length; i++) {
        final rowIndex = i + 2;

        for (int j = 0; j < rows[i].length; j++) {
          final cell = sheet.getRangeByIndex(rowIndex, j + 1);

          final value = rows[i][j];

          // Try to convert numeric strings → number
          final numValue = double.tryParse(value.toString());

          if (numValue != null) {
            cell.setNumber(numValue);
            cell.cellStyle.hAlign = xlsio.HAlignType.right;
          } else {
            cell.setText(value.toString());
          }
        }
      }

      final totalRows = rows.length + 1;
      final totalCols = headers.length;

      if (amountColumns != null) {
        for (final col in amountColumns) {
          sheet.getRangeByIndex(2, col, totalRows, col).numberFormat = '0.00';
        }
      }

      // -------- INNER GRID (much cheaper than 'all') --------
      // Vertical lines: draw RIGHT border for all columns except last

      for (int col = 1; col < totalCols; col++) {
        sheet
                .getRangeByIndex(1, col, totalRows, col)
                .cellStyle
                .borders
                .right
                .lineStyle =
            xlsio.LineStyle.thin;
      }

      // Horizontal lines: draw BOTTOM border for all rows except last
      for (int row = 1; row < totalRows; row++) {
        sheet
                .getRangeByIndex(row, 1, row, totalCols)
                .cellStyle
                .borders
                .bottom
                .lineStyle =
            xlsio.LineStyle.thin;
      }

      // -------- OUTER BORDER (FAST & REQUIRED) --------

      // TOP BORDER
      sheet
              .getRangeByIndex(1, 1, 1, totalCols)
              .cellStyle
              .borders
              .top
              .lineStyle =
          xlsio.LineStyle.medium;

      // LEFT BORDER
      sheet
              .getRangeByIndex(1, 1, totalRows, 1)
              .cellStyle
              .borders
              .left
              .lineStyle =
          xlsio.LineStyle.medium;

      // BOTTOM BORDER
      sheet
              .getRangeByIndex(totalRows, 1, totalRows, totalCols)
              .cellStyle
              .borders
              .bottom
              .lineStyle =
          xlsio.LineStyle.thin;

      // RIGHT BORDER
      sheet
              .getRangeByIndex(1, totalCols, totalRows, totalCols)
              .cellStyle
              .borders
              .right
              .lineStyle =
          xlsio.LineStyle.thin;

      // ---------------- COLUMN WIDTH ----------------
      for (int col = 1; col <= headers.length; col++) {
        sheet.autoFitColumn(col);
      }

      if (addTotalRow && amountColumns != null) {
        final totalRowIndex = rows.length + 2;

        sheet.getRangeByIndex(totalRowIndex, 1).setText("Total");

        for (final col in amountColumns) {
          final columnLetter = _getExcelColumnName(col);

          final formula =
              'SUM(${columnLetter}2:$columnLetter${rows.length + 1})';

          final cell = sheet.getRangeByIndex(totalRowIndex, col);

          cell.setFormula(formula);
          cell.cellStyle.hAlign = xlsio.HAlignType.right;
          cell.cellStyle.bold = true;
        }
      }

      // ---------------- SAVE ----------------
      final bytes = workbook.saveAsStream();
      workbook.dispose();

      if (kIsWeb) {
        saveAndOpenExcel(fileName, bytes);
      } else {
        final dir = await getStorageDirectory();
        final file = File('$dir/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        OpenFile.open(file.path);
      }
    } catch (e) {
      debugPrint("Excel Error: $e");
    }
  }
}
