import 'package:excel/excel.dart' as xl;

xl.CellStyle getCellStyle(dynamic value) {
  return xl.CellStyle(
    horizontalAlign: value is num
        ? xl.HorizontalAlign.Right
        : xl.HorizontalAlign.Left,
    verticalAlign: xl.VerticalAlign.Center,

    topBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
    bottomBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
    leftBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
    rightBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
  );
}