import 'package:optima/classes/dashBoard.dart';

class ProductionTotals {
  double currentMonthQty = 0;
  double currentMonthBoxes = 0;

  double percentTarget = 0;
  double lastMonthQty = 0;
  double lastMonthBoxes = 0;

  double last3MonthQty = 0;
  double last3MonthBoxes = 0;

  double financialYearQty = 0;
  double financialYearBoxes = 0;
}

class ProductionTargets {
  double qtyTarget = 0;
  double boxTarget = 0;

  double qtyAchievementPercent = 0;
  double boxAchievementPercent = 0;
}

class ChartData {
  List<MonthlyProductionData> monthlyBar = [];
  List<MonthlyProductionData> monthlyLine = [];

  List<DailyProductionData> dailyBar = [];
  List<DailyProductionData> dailyLine = [];
}

class TableDataModel {
  List<String> particulars = [];
  List<List<String>> rows = [];
}
