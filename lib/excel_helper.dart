import 'package:excel/excel.dart';

/// Converts a list of mixed types (String, int, double, bool, etc.)
// ignore: unintended_html_in_doc_comment
/// into a List<CellValue?> compatible with the new `excel` package.
List<CellValue?> toCellRow(List<dynamic> values) {
  return values.map<CellValue?>((value) {
    if (value == null) return null;

    if (value is num) {
      return DoubleCellValue(value.toDouble());
    } else if (value is bool) {
      return TextCellValue(value ? 'TRUE' : 'FALSE');
    } else if (value is DateTime) {
      return TextCellValue(value.toIso8601String());
    } else {
      return TextCellValue(value.toString());
    }
  }).toList();
}

List<CellValue?> toCellRowList(List<dynamic> values) {
  return values.map<CellValue?>((v) {
    if (v == null) return null;
    if (v is num) return DoubleCellValue(v.toDouble());
    return TextCellValue(v.toString());
  }).toList();
}
