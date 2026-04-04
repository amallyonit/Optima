// ignore_for_file: file_names

import 'dart:io';

import 'package:excel/excel.dart' as xl;
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:optima/pages/dashboardPages/excel_helper_other.dart';
import 'package:optima/pages/dashboardPages/pdf_helper_other.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import '../../excel_helper.dart';

class ReportService {
  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
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
  Future<void> generateExcelOld({
    required String sheetName,
    required List<String> headers,
    required List<List<dynamic>> rows,
    required String fileName,
  }) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel[sheetName];
      final borderStyle = xl.Border(borderStyle: xl.BorderStyle.Thin);

      int totalRows = rows.length + 1; // +1 for header
      int totalCols = headers.length;

      // ---------------- HEADER ----------------
      sheet.appendRow(toCellRow(headers));

      for (int col = 0; col < headers.length; col++) {
        final cell = sheet.cell(
          xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        );

        cell.cellStyle = xl.CellStyle(
          bold: true,
          backgroundColorHex: xl.ExcelColor.fromHexString("#E7F3FF"),
          horizontalAlign: xl.HorizontalAlign.Center,

          // Force ALL borders
          leftBorder: borderStyle,
          rightBorder: borderStyle,
          topBorder: borderStyle,
          bottomBorder: borderStyle,
        );
      }

      // ---------------- DATA ----------------
      int rowIndex = 1;

      for (var row in rows) {
        sheet.appendRow(toCellRow(row));

        for (int col = 0; col < row.length; col++) {
          final cell = sheet.cell(
            xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
          );

          cell.cellStyle = xl.CellStyle(
            horizontalAlign: row[col] is num
                ? xl.HorizontalAlign.Right
                : xl.HorizontalAlign.Left,

            // Force ALL borders again
            leftBorder: borderStyle,
            rightBorder: borderStyle,
            topBorder: borderStyle,
            bottomBorder: borderStyle,
          );
        }

        rowIndex++;
      }

      // Fix TOP border of header
      for (int col = 0; col < totalCols; col++) {
        final cell = sheet.cell(
          xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        );

        cell.cellStyle = xl.CellStyle(
          bold: true,
          horizontalAlign: xl.HorizontalAlign.Center,
          topBorder: borderStyle,
          leftBorder: borderStyle,
          rightBorder: borderStyle,
          bottomBorder: borderStyle,
        );
      }

      // Fix LEFT OUTER border (first column)
      for (int row = 0; row < totalRows; row++) {
        final cell = sheet.cell(
          xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        );

        cell.cellStyle = xl.CellStyle(
          horizontalAlign: row == 0
              ? xl.HorizontalAlign.Center
              : xl.HorizontalAlign.Left,
          leftBorder: borderStyle,
          rightBorder: borderStyle,
          topBorder: borderStyle,
          bottomBorder: borderStyle,
        );
      }
      // ---------------- SAVE ----------------
      if (kIsWeb) {
        final bytes = excel.encode()!;
        saveAndOpenExcel(fileName, bytes);
      } else {
        final dir = await getStorageDirectory();
        final file = File('$dir/$fileName');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      debugPrint("Excel Error: $e");
    }
  }

  Future<void> generateExcel({
    required String sheetName,
    required List<String> headers,
    required List<List<dynamic>> rows,
    required String fileName,
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

          if (value is num) {
            cell.setNumber(value.toDouble());
            cell.cellStyle.hAlign = xlsio.HAlignType.right;
          } else {
            cell.setText(value.toString());
          }
        }

        final totalRows = rows.length + 1;
        final totalCols = headers.length;

        final fullRange = sheet.getRangeByIndex(1, 1, totalRows, totalCols);

        // THIS is the key line
        fullRange.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

        // OUTER BORDER (thick = visible on mobile)
        final outerRange = sheet.getRangeByIndex(1, 1, totalRows, totalCols);
        outerRange.cellStyle.borders.top.lineStyle = xlsio.LineStyle.medium;
        outerRange.cellStyle.borders.bottom.lineStyle = xlsio.LineStyle.medium;
        outerRange.cellStyle.borders.left.lineStyle = xlsio.LineStyle.medium;
        outerRange.cellStyle.borders.right.lineStyle = xlsio.LineStyle.medium;
      }

      // ---------------- COLUMN WIDTH ----------------
      for (int col = 1; col <= headers.length; col++) {
        sheet.autoFitColumn(col);
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
