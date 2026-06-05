// ignore_for_file: file_names
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'report_service_platform.dart';
import '../../api_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_downloader/flutter_downloader.dart';

class ReportService {
  Future<String> getDownloadPath() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      if (await dir.exists()) {
        return dir.path;
      }
    }

    // fallback
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<void> handleFileSave(BuildContext context, String path) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('File saved to Downloads'),
        action: SnackBarAction(
          label: 'OPEN',
          onPressed: () {
            OpenFile.open(path);
          },
        ),
      ),
    );
  }

  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userName') ?? '';
    return userName;
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

  final indianCurrencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '',
    decimalDigits: 2,
  );

  // ---------------- PDF GENERATOR ----------------
  Future<void> generatePDF({
    BuildContext? context,
    required String title,
    required List<String> headers,
    required List<List<dynamic>> rows,
    required String fileName,
    List<int>?
    amountColumns, // optional: 1-based column indices for numeric formatting
  }) async {
    try {
      final pdf = pw.Document();
      final userName = await getUserName();
      // -------- Table Page --------

      final columnTotals = List<double>.filled(headers.length, 0);

      for (var row in rows) {
        for (int i = 0; i < row.length; i++) {
          final numValue = double.tryParse(row[i].toString());
          if (numValue != null) {
            columnTotals[i] += numValue;
          }
        }
      }

      final totalRow = List.generate(headers.length, (i) {
        if (i == 0) return "Total";
        final total = columnTotals[i];
        if (total == 0) return "";
        return total.toStringAsFixed(2);
      });

      // -------- Table Page --------
      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            buildBackground: (context) => pw.Center(
              child: pw.Transform.rotate(
                angle: -0.5,
                child: pw.Opacity(
                  opacity: 0.03,
                  child: pw.Text(
                    "Optima CRM\n$userName",
                    style: pw.TextStyle(
                      fontSize: 40,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          header: (context) {
            final now = DateTime.now();

            final formattedDate =
                "${now.day.toString().padLeft(2, '0')}/"
                "${now.month.toString().padLeft(2, '0')}/"
                "${now.year} "
                "${now.hour.toString().padLeft(2, '0')}:"
                "${now.minute.toString().padLeft(2, '0')}";

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    // LEFT: Title
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),

                    // RIGHT: Date Time
                    pw.Text(
                      "Created: $formattedDate",
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
              ],
            );
          },
          build: (context) => [
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                // Header
                pw.TableRow(
                  children: List.generate(headers.length, (i) {
                    final isNumeric = amountColumns?.contains(i + 1) ?? false;

                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Align(
                        alignment: isNumeric
                            ? pw.Alignment.centerRight
                            : pw.Alignment.centerLeft,
                        child: pw.Text(
                          headers[i],
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    );
                  }),
                ),

                // Rows
                ...rows.map((row) {
                  return pw.TableRow(
                    children: row.asMap().entries.map((entry) {
                      final cell = entry.value;

                      final text = cell.toString().trim();
                      final isAmountColumn =
                          amountColumns?.contains(entry.key + 1) ?? false;

                      final isNumeric = RegExp(
                        r'^-?\d+(\.\d+)?$',
                      ).hasMatch(text);

                      final numValue = isNumeric ? double.parse(text) : null;

                      return pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Align(
                          alignment: isNumeric
                              ? pw.Alignment.centerRight
                              : pw.Alignment.centerLeft,
                          child: pw.Text(
                            (isNumeric && numValue != null)
                                ? (isAmountColumn
                                      ? indianCurrencyFormatter.format(numValue)
                                      : numValue.toStringAsFixed(2))
                                : cell.toString(),
                            style: pw.TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),

                // TOTAL ROW
                pw.TableRow(
                  children: totalRow.asMap().entries.map((entry) {
                    final index = entry.key;
                    final cell = entry.value;

                    final isNumeric =
                        amountColumns?.contains(index + 1) ?? false;
                    final numValue = double.tryParse(cell.toString());

                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Align(
                        alignment: isNumeric
                            ? pw.Alignment.centerRight
                            : pw.Alignment.centerLeft,
                        child: pw.Text(
                          (isNumeric && numValue != null)
                              ? indianCurrencyFormatter.format(numValue)
                              : cell.toString(),
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      );

      final bytes = await pdf.save();

      if (kIsWeb) {
        downloadPDFWeb(fileName, bytes);
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

    List<String>? secondSheetHeaders,
    List<List<dynamic>>? secondSheetRows,
    String? secondSheetName,

    List<int>?
    amountColumns, // optional: 1-based column indices for numeric formatting
    bool addTotalRow = false, // optional
    String reportTitle = "", // optional
    bool enableStyling = false, // optional
    bool highlightSections = false, // optional
    bool highlightProfitability = false, // optional
    bool highlightNegative = false, // optional

    List<List<dynamic>>? footerRows,
  }) async {
    try {
      final userName = await getUserName();
      final now = DateTime.now();
      final formattedDate =
          "${now.day.toString().padLeft(2, '0')}/"
          "${now.month.toString().padLeft(2, '0')}/"
          "${now.year} "
          "${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}";

      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];
      sheet.name = sheetName;

      Worksheet? secondSheet;

      if (secondSheetHeaders != null &&
          secondSheetRows != null &&
          secondSheetName != null) {
        secondSheet = workbook.worksheets.addWithName(secondSheetName);
      }
      // -------- REPORT HEADER --------
      // 'assets/images/${ApiHelper.projectName}/logo.png'
      // Row 1 → Title (Left)
      final int lastColumn = sheet.getLastColumn() > 1
          ? sheet.getLastColumn()
          : headers.length - 1;

      final range = sheet.getRangeByIndex(1, 1, 1, lastColumn);
      range.merge();
      final text =
          "${ApiHelper.companyName}\nOptima CRM${reportTitle.isNotEmpty ? " - $reportTitle" : ""}";

      range.setText(text);

      final lines = text.split('\n');
      final longestLine = lines.reduce((a, b) => a.length > b.length ? a : b);
      double width =
          longestLine.length *
          (longestLine.length < 40 ? 1.8 : 5); // add padding

      range.cellStyle.wrapText = true;
      range.cellStyle.bold = true;
      range.cellStyle.fontSize = 14;
      sheet.getRangeByIndex(1, 1, 1, sheet.getLastColumn()).rowHeight = 53;
      sheet.getRangeByIndex(1, 1).columnWidth = width;

      // Row 1 → Date (Right)
      sheet
          .getRangeByIndex(1, headers.length)
          .setText("Created: $formattedDate");

      // Row 2 → Username
      sheet.getRangeByIndex(2, 1).setText("User: $userName");

      sheet.getRangeByIndex(1, headers.length).cellStyle.hAlign =
          xlsio.HAlignType.right;
      sheet.getRangeByIndex(1, headers.length).cellStyle.bold = true;
      sheet.getRangeByIndex(2, 1).cellStyle.fontSize = 12;

      // ---------------- HEADER ----------------
      for (int col = 0; col < headers.length; col++) {
        sheet.getRangeByIndex(4, col + 1).setText(headers[col]);
      }

      if (secondSheet != null) {
        for (int col = 0; col < secondSheetHeaders!.length; col++) {
          secondSheet
              .getRangeByIndex(4, col + 1)
              .setText(secondSheetHeaders[col]);
        }

        final headerRange = secondSheet.getRangeByIndex(
          4,
          1,
          4,
          secondSheetHeaders.length,
        );

        headerRange.cellStyle.bold = true;
        headerRange.cellStyle.backColor = "#E7F3FF";
        headerRange.cellStyle.hAlign = xlsio.HAlignType.center;
      }

      final headerRange = sheet.getRangeByIndex(4, 1, 4, headers.length);

      headerRange.cellStyle.bold = true;
      headerRange.cellStyle.backColor = "#E7F3FF";
      headerRange.cellStyle.hAlign = xlsio.HAlignType.center;

      headerRange.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

      // ---------------- DATA ----------------
      for (int i = 0; i < rows.length; i++) {
        final rowIndex = i + 5;
        final row = rows[i];

        // -------- Detect row types (SAFE - only if enabled) --------
        final isSectionRow =
            highlightSections &&
            row.sublist(1).every((e) => e == "" || e == null);

        final isSpacerRow =
            highlightSections &&
            row.sublist(0).every((e) => e == "" || e == null);

        final title = row[0]?.toString().toLowerCase() ?? "";

        final isProfitability =
            highlightProfitability &&
            (title.contains("ebitda") ||
                title.contains("pbt") ||
                title.contains("pat"));

        final isTotalRow = title.startsWith("total");

        for (int j = 0; j < row.length; j++) {
          final cell = sheet.getRangeByIndex(rowIndex, j + 1);
          final value = row[j];

          // -------- VALUE HANDLING (IMPROVED) --------
          if (value is num) {
            cell.setNumber(value.toDouble());
            cell.cellStyle.hAlign = xlsio.HAlignType.right;
          } else {
            final numValue = double.tryParse(value.toString());
            if (numValue != null) {
              cell.setNumber(numValue);
              cell.cellStyle.hAlign = xlsio.HAlignType.right;
            } else {
              cell.setText(value?.toString() ?? "");
            }
          }

          // -------- SECTION STYLE --------
          if (isSectionRow && !isSpacerRow) {
            cell.cellStyle.bold = true;
            if (enableStyling) {
              cell.cellStyle.fontSize = 13;
              cell.cellStyle.backColor = "#D9E1F2";
            }
          }
          // -------- SPACER ROW --------
          if (isSpacerRow) {
            if (enableStyling) {
              cell.cellStyle.backColor = "#EEEEEE";
            }
          }

          // -------- PROFITABILITY STYLE --------
          if (isProfitability) {
            cell.cellStyle.bold = true;
            if (enableStyling) {
              cell.cellStyle.backColor = "#E2EFDA";
            }
          }

          // -------- NEGATIVE VALUES --------
          if (highlightNegative) {
            final numValue = value is num
                ? value
                : double.tryParse(value.toString());

            if (numValue != null && numValue < 0) {
              cell.cellStyle.fontColor = "#FF0000";
            }
          }

          if (isTotalRow) {
            cell.cellStyle.bold = true;
            if (enableStyling) {
              cell.cellStyle.backColor = "#FFF2CC"; // light yellow
            }
          }
        }
      }

      if (secondSheet != null) {
        for (int i = 0; i < secondSheetRows!.length; i++) {
          final rowIndex = i + 5;
          final row = secondSheetRows[i];

          for (int j = 0; j < row.length; j++) {
            final cell = secondSheet.getRangeByIndex(rowIndex, j + 1);

            final value = row[j];

            if (value is num) {
              cell.setNumber(value.toDouble());
            } else {
              final numValue = double.tryParse(value.toString());

              if (numValue != null) {
                cell.setNumber(numValue);
              } else {
                cell.setText(value.toString());
              }
            }
          }
        }
      }
      int totalRows = rows.length + 4;
      if (addTotalRow) {
        totalRows += 1;
      }
      if (footerRows != null) {
        totalRows += footerRows.length + 1;
      }
      final totalCols = headers.length;

      if (amountColumns != null) {
        for (final col in amountColumns) {
          final range = sheet.getRangeByIndex(5, col, totalRows, col);

          range.numberFormat = r'#,##,##0.00';

          range.cellStyle.hAlign = xlsio.HAlignType.right;
        }
      }

      // -------- INNER GRID (much cheaper than 'all') --------
      // Vertical lines: draw RIGHT border for all columns except last

      for (int col = 1; col < totalCols; col++) {
        sheet
                .getRangeByIndex(4, col, totalRows, col)
                .cellStyle
                .borders
                .right
                .lineStyle =
            xlsio.LineStyle.thin;
      }

      // Horizontal lines: draw BOTTOM border for all rows except last
      for (int row = 4; row < totalRows; row++) {
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
              .getRangeByIndex(4, 1, 4, totalCols)
              .cellStyle
              .borders
              .top
              .lineStyle =
          xlsio.LineStyle.medium;

      // LEFT BORDER
      sheet
              .getRangeByIndex(4, 1, totalRows, 1)
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
              .getRangeByIndex(4, totalCols, totalRows, totalCols)
              .cellStyle
              .borders
              .right
              .lineStyle =
          xlsio.LineStyle.thin;

      // ---------------- COLUMN WIDTH ----------------
      for (int col = 1; col <= headers.length; col++) {
        sheet.autoFitColumn(col);
      }

      if (secondSheet != null) {
        for (int col = 1; col <= secondSheetHeaders!.length; col++) {
          secondSheet.autoFitColumn(col);
        }
      }

      if (addTotalRow && amountColumns != null) {
        final totalRowIndex = rows.length + 5;

        final totalLabelCell = sheet.getRangeByIndex(totalRowIndex, 1);
        totalLabelCell.setText("Total");
        totalLabelCell.cellStyle.bold = true;

        for (final col in amountColumns) {
          final columnLetter = _getExcelColumnName(col);

          final formula =
              'SUM(${columnLetter}5:$columnLetter${rows.length + 4})';

          final cell = sheet.getRangeByIndex(totalRowIndex, col);

          cell.setFormula(formula);
          cell.cellStyle.hAlign = xlsio.HAlignType.right;
          cell.cellStyle.bold = true;
        }
        sheet
                .getRangeByIndex(totalRowIndex, 1, totalRowIndex, totalCols)
                .cellStyle
                .backColor =
            "#FFF2CC";
        for (int col = 1; col <= totalCols; col++) {
          final cell = sheet.getRangeByIndex(totalRowIndex, col);

          cell.cellStyle.borders.left.lineStyle = xlsio.LineStyle.thin;
          cell.cellStyle.borders.right.lineStyle = xlsio.LineStyle.thin;
          cell.cellStyle.borders.top.lineStyle = xlsio.LineStyle.thin;
          cell.cellStyle.borders.bottom.lineStyle = xlsio.LineStyle.thin;
        }
      }

      // ---------------- FOOTER ROWS ----------------
      if (footerRows != null && footerRows.isNotEmpty) {
        int footerStartRow = rows.length + 5 + (addTotalRow ? 2 : 1);

        for (int i = 0; i < footerRows.length; i++) {
          final footerRow = footerRows[i];

          for (int j = 0; j < footerRow.length; j++) {
            final cell = sheet.getRangeByIndex(footerStartRow + i, j + 1);

            final value = footerRow[j];

            if (value is num) {
              cell.setNumber(value.toDouble());
            } else {
              final numValue = double.tryParse(value.toString());

              if (numValue != null) {
                cell.setNumber(numValue);
              } else {
                cell.setText(value.toString());
              }
            }
          }

          // Style footer labels
          sheet.getRangeByIndex(footerStartRow + i, 1).cellStyle.bold = true;
        }
      }

      if (secondSheet != null) {
        final totalRowIndex = secondSheetRows!.length + 5;

        secondSheet.getRangeByIndex(totalRowIndex, 1).setText("Total");

        secondSheet.getRangeByIndex(totalRowIndex, 1).cellStyle.bold = true;

        final amountCols = [8, 9, 10, 11, 12, 13, 14, 15, 16];

        for (final col in amountCols) {
          final letter = _getExcelColumnName(col);

          secondSheet
              .getRangeByIndex(totalRowIndex, col)
              .setFormula(
                'SUM(${letter}5:$letter${secondSheetRows.length + 4})',
              );
        }
      }

      // ---------------- SAVE ----------------
      final bytes = List<int>.from(workbook.saveAsStream());
      workbook.dispose();

      if (kIsWeb) {
        downloadExcelWeb(fileName, bytes);
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

  Future<String?> uploadPDF(Uint8List bytes, String fileName) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiHelper.baseUrl}upload-report'),
    );

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final jsonData = jsonDecode(respStr);

      return jsonData['url'];
    }

    return null;
  }

  Future<void> downloadFile(String url, String fileName) async {
    await FlutterDownloader.enqueue(
      url: url,
      savedDir: '/storage/emulated/0/Download',
      fileName: fileName,
      showNotification: true,
      openFileFromNotification: true,
    );
  }
}
