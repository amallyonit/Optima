import 'package:intl/intl.dart';
import '../../../ReportService.dart';

final reportService = ReportService();

class ManpowerExcelExporter {
  static Future<void> exportManpowerExcel(
    List<String> particulars,
    List<List<String>> rows,
  ) async {
    String monthYear = DateFormat('MMMM yyyy').format(DateTime.now());
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
    await reportService.generateExcel(
      sheetName: 'Manpower Costing',
      headers: headers,
      rows: rows.asMap().entries.map((entry) {
        final index = entry.key;
        final rowData = entry.value;

        return [particulars[index], ...rowData];
      }).toList(),
      fileName: 'manpower_costing_report.xlsx',
      amountColumns: [2, 3, 4, 5, 6, 7, 8, 9],
      addTotalRow: true,
      reportTitle: 'Production[MIS] - Working for the Month of $monthYear',
    );
  }
}
