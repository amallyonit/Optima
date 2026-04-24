// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference
import 'package:optima/excel_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/classes/leads.dart';

import 'package:optima/pages/dashboardPages/excel_helper_web.dart';
import 'package:optima/pages/dashboardPages/pdf_helper_web.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;
import 'package:open_file/open_file.dart';

class ProductionOrderAnalysis extends StatefulWidget {
  const ProductionOrderAnalysis({super.key});

  @override
  State<ProductionOrderAnalysis> createState() =>
      _ProductionOrderAnalysisState();
}

late Future<void> loadDataFuture;

DateTime? currentDate;
DateTime? currentMonthFromDate;
DateTime? currentMonthToDate;
DateTime? lastMonthFromDate;
DateTime? lastMonthToDate;
DateTime? currentQuarterFromDate;
DateTime? currentQuarterToDate;
DateTime? lastQuarterFromDate;
DateTime? lastQuarterToDate;
DateTime? fiscalYearStartDate;
DateTime? prevFiscalYearStartDate;
DateTime? prevFiscalYearEndDate;
String financialYear = "";
String prevFinancialYear = "";
int currentQuarter = 0;

int CurrentMonthSalesPercentage = 0;
String CurrentMonthSalesPercentageStr = "";
String CurrentMonthSalesStr = "";
String SalesGoalStr = "";
int LastMonthPercentage = 0;
String LastMonthPercentageStr = "";
double LastMonthSales = 0;
String LastMonthSalesStr = "";
double LastMonthTarget = 0;
String LastMonthTargetStr = "";
double CurrentQtrSales = 0;
String CurrentQtrSalesStr = "";
double CurrentQtrTarget = 0;
String CurrentQtrTargetStr = "";
int CurrentQtrPercentage = 0;
String CurrentQtrPercentageStr = "";
int YtdPercentage = 0;
String YtdPercentageStr = "";
double YtdSales = 0;
String YtdSalesStr = "";
double YtdTarget = 0;
String YtdTargetStr = "";
double CurrentMonthTarget = 0;
String CurrentMonthTargetStr = "";
int CurrentMonthPercentage = 0;
double Q1Sales = 0;
double Q1Target = 0;
double Q1Diff = 0;
int Q1Percentage = 0;
String Q1SalesStr = "";
String Q1TargetStr = "";
String Q1DiffStr = "";
String Q1PercentageStr = "";
double Q2Sales = 0;
double Q2Target = 0;
double Q2Diff = 0;
int Q2Percentage = 0;
String Q2SalesStr = "";
String Q2TargetStr = "";
String Q2DiffStr = "";
String Q2PercentageStr = "";
double Q3Sales = 0;
double Q3Target = 0;
double Q3Diff = 0;
int Q3Percentage = 0;
String Q3SalesStr = "";
String Q3TargetStr = "";
String Q3DiffStr = "";
String Q3PercentageStr = "";
double Q4Sales = 0;
double Q4Target = 0;
double Q4Diff = 0;
int Q4Percentage = 0;
String Q4SalesStr = "";
String Q4TargetStr = "";
String Q4DiffStr = "";
String Q4PercentageStr = "";
double Q1Average = 0;
String Q1AverageStr = "";
double Q2Average = 0;
String Q2AverageStr = "";
double Q3Average = 0;
String Q3AverageStr = "";
double Q4Average = 0;
String Q4AverageStr = "";
DateTime? q1FromDate;
DateTime? q1ToDate;
DateTime? q2FromDate;
DateTime? q2ToDate;
DateTime? q3FromDate;
DateTime? q3ToDate;
DateTime? q4FromDate;
DateTime? q4ToDate;

double CurrentMonthSales = 0;
double SalesGoal = 0;

List<ProductionOrderList> production = [];
List<Users> usersList = [];

MonthlyProductionList monthData = MonthlyProductionList(monthlyData: []);
ItemWiseProductionList itemWiseData = ItemWiseProductionList(itemWiseData: []);
BranchWiseProductionList branchWiseData = BranchWiseProductionList(
  branchWiseData: [],
);
ItemGroupWiseProductionList itemGroupWiseData = ItemGroupWiseProductionList(
  itemGroupWiseData: [],
);
ItemSubGroupWiseProductionList itemSubGroupWiseData =
    ItemSubGroupWiseProductionList(itemSubGroupWiseData: []);
PlantWiseProductionList plantWiseData = PlantWiseProductionList(plantData: []);
UnitWiseProductionList unitWiseData = UnitWiseProductionList(unitData: []);
ShiftWiseProductionList shiftWiseData = ShiftWiseProductionList(shiftData: []);
OrderStatusList statusData = OrderStatusList(statusData: []);

bool chartDataLoaded = false;
int touchedMonthIndex = 0;
String touchedMonth = "";
String touchedItemCode = "";
String touchedBranchName = "";
String touchedItemGroup = "";
String touchedItemSubGroup = "";
String touchedPlant = "";
String touchedUnit = "";
String touchedShift = "";
double selectedChart = 0;

class ProductionOrderAnalysisProvider with ChangeNotifier {
  List<ProductionOrderList> _salesList = [];
  List<ProductionOrderList> get salesList => _salesList;
  void updatePurchaseList(List<ProductionOrderList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class _ProductionOrderAnalysisState extends State<ProductionOrderAnalysis> {
  bool touchedMonthGoals = false;
  bool touchedQuarterGoals = false;
  bool touchedYTDGoals = false;
  bool showDrillDownChart = false;
  int touchedIndex = -1;

  String formatAmount(double amount) {
    if (amount >= 10000000) {
      // Amount in crores
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      // Amount in lakhs
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else {
      // Amount in thousands
      return '${(amount / 1000).toStringAsFixed(2)} K';
    }
  }

  double convertAmount(double amount) {
    if (amount >= 10000000) {
      // Amount in crores
      return double.parse((amount / 10000000).toStringAsFixed(2));
    } else if (amount >= 100000) {
      // Amount in lakhs
      return double.parse((amount / 100000).toStringAsFixed(2));
    } else {
      // Amount in thousands
      return double.parse((amount / 1000).toStringAsFixed(2));
    }
  }

  Color getCategoryColor(int categoryId) {
    switch (categoryId) {
      case 0:
        return const Color(0xFF97D7F3);
      case 1:
        return const Color(0xFFF49136);
      case 2:
        return const Color(0xFF6CCC3F);
      default:
        return const Color(0xFF6CCC3F);
    }
  }

  String formatFinanceAmount(double amount) {
    if (amount >= 1000000000) {
      return "${(amount / 1000000000).toStringAsFixed(2)} B";
    } else if (amount >= 1000000) {
      return "${(amount / 1000000).toStringAsFixed(2)} M";
    } else {
      return '${(amount / 1000).toStringAsFixed(2)} K';
    }
  }

  DateTime addMonth(DateTime date, int addMonth) {
    int currentMonth = date.month;
    int currentYear = date.year;
    int nextMonth = currentMonth + addMonth;
    int nextYear = currentYear;
    // Handle the case when the next month is December
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }

    int lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
    // Handle the case when the original date is at the end of the month
    int originalDay = date.day;
    if (originalDay > lastDayOfNextMonth) {
      originalDay = lastDayOfNextMonth;
    }
    return DateTime(nextYear, nextMonth, originalDay);
  }

  DateTime addDay(DateTime date, int addDays) {
    // Add the specified number of days to the given date
    DateTime newDate = date.add(Duration(days: addDays));

    // Return the resulting date
    return newDate;
  }

  double getMaxValue(double maxValue) {
    double divVal = 0;
    if (maxValue > 1000000000) {
      divVal = 1000000000;
    } else if (maxValue >= 100000000 && maxValue <= 500000000) {
      divVal = 100000000;
    } else if (maxValue > 500000000 && maxValue <= 1000000000) {
      divVal = 250000000;
    } else if (maxValue > 10000000 && maxValue <= 100000000) {
      divVal = 10000000;
    } else if (maxValue > 1000000 && maxValue <= 10000000) {
      divVal = 1000000;
    } else if (maxValue > 100000 && maxValue <= 1000000) {
      if (maxValue <= 200000) {
        divVal = 10000;
      } else {
        if (maxValue >= 200000) {
          divVal = 20000;
        }
        if (maxValue >= 200000) {
          divVal = 30000;
        }
        if (maxValue >= 400000) {
          divVal = 40000;
        }
        if (maxValue >= 500000) {
          divVal = 50000;
        }
      }
    } else if (maxValue >= 10000 && maxValue <= 100000) {
      divVal = 10000;
    } else if (maxValue >= 100 && maxValue <= 1000) {
      divVal = 100;
    } else {
      divVal = 10;
    }
    double maxY = ((maxValue ~/ divVal) + 1) * divVal;
    return maxY;
  }

  int getCurrentQuarter() {
    int monthIndex = DateTime.now().month;
    switch (monthIndex) {
      case 4:
      case 5:
      case 6:
        return 1;
      case 7:
      case 8:
      case 9:
        return 2;
      case 10:
      case 11:
      case 12:
        return 3;
      case 1:
      case 2:
      case 3:
        return 4;
      default:
        throw Error();
    }
  }

  SideTitles get _bottomTitles =>
      SideTitles(showTitles: true, getTitlesWidget: getBottomTitles);

  Widget getBottomTitles(double val, TitleMeta meta) {
    String text = '';
    MonthlyProductionData mthData = monthData.monthlyData[val.toInt()];
    text = mthData.monthName;
    return Text(text.length > 3 ? text.substring(0, 3) : text);
  }

  double getItemMaxValue(ItemWiseProductionList itemData) {
    double maxValue = 0.0;
    for (var itemData in itemData.itemWiseData) {
      maxValue = maxValue > itemData.productionActual
          ? maxValue
          : itemData.productionActual;
      maxValue = maxValue > itemData.production3Month
          ? maxValue
          : itemData.production3Month;
    }
    return ((maxValue ~/ 200000) + 1) * 200000;
  }

  double getBranchMaxValue(BranchWiseProductionList brData) {
    double maxValue = 0.0;
    for (var brData in brData.branchWiseData) {
      maxValue = maxValue > brData.productionActual
          ? maxValue
          : brData.productionActual;
      maxValue = maxValue > brData.production3Month
          ? maxValue
          : brData.production3Month;
    }
    return ((maxValue ~/ 5000000) + 1) * 5000000;
  }

  double getGroupMaxValue(ItemGroupWiseProductionList grpData) {
    double maxValue = 0.0;
    for (var brData in grpData.itemGroupWiseData) {
      maxValue = maxValue > brData.productionActual
          ? maxValue
          : brData.productionActual;
    }
    return ((maxValue ~/ 5000000) + 1) * 5000000;
  }

  double getSubGroupMaxValue(ItemSubGroupWiseProductionList subData) {
    double maxValue = 0.0;
    for (var brData in subData.itemSubGroupWiseData) {
      maxValue = maxValue > brData.productionActual
          ? maxValue
          : brData.productionActual;
    }
    return ((maxValue ~/ 5000000) + 1) * 5000000;
  }

  double getPlantMaxValue(PlantWiseProductionList plantData) {
    double maxValue = 0.0;
    for (var brData in plantData.plantData) {
      maxValue = maxValue > brData.productionActual
          ? maxValue
          : brData.productionActual;
    }
    return ((maxValue ~/ 5000000) + 1) * 5000000;
  }

  double getUnitMaxValue(UnitWiseProductionList unitData) {
    double maxValue = 0.0;
    for (var brData in unitData.unitData) {
      maxValue = maxValue > brData.productionActual
          ? maxValue
          : brData.productionActual;
    }
    return ((maxValue ~/ 5000000) + 1) * 5000000;
  }

  double getShiftMaxValue(ShiftWiseProductionList shiftData) {
    double maxValue = 0.0;
    for (var brData in shiftData.shiftData) {
      maxValue = maxValue > brData.productionActual
          ? maxValue
          : brData.productionActual;
    }
    return ((maxValue ~/ 5000000) + 1) * 5000000;
  }

  String getMonthName(int month) {
    final formatter = DateFormat('MMMM');
    return formatter.format(DateTime(2000, month));
  }

  void getLastQuarterDates() {
    DateTime now = DateTime.now();
    switch (getCurrentQuarter()) {
      case 1:
        lastQuarterFromDate = DateTime(now.year, 1, 1);
        lastQuarterToDate = DateTime(now.year, 3, 31);
        break;
      case 2:
        lastQuarterFromDate = DateTime(now.year, 4, 1);
        lastQuarterToDate = DateTime(now.year, 6, 30);
        break;
      case 3:
        lastQuarterFromDate = DateTime(now.year, 7, 1);
        lastQuarterToDate = DateTime(now.year, 9, 30);
        break;
      case 4:
        lastQuarterFromDate = DateTime(now.year - 1, 10, 1);
        lastQuarterToDate = DateTime(now.year - 1, 12, 31);
        break;
      default:
        throw Error();
    }
  }

  Map<String, DateTime> getLastThreeMonthsRange(int monthIndex) {
    // Ensure the month index is valid (1 to 12)
    if (monthIndex < 1 || monthIndex > 12) {
      throw ArgumentError('Invalid month index. Must be between 1 and 12.');
    }

    DateTime now = DateTime.now();

    // Financial year start (April to March)
    int financialYearStart = (now.month >= 4) ? now.year : now.year - 1;

    // Determine the year for the given month
    int yearForMonth = (monthIndex >= 4)
        ? financialYearStart
        : financialYearStart + 1;

    // Adjust the start month to handle wrapping to the previous year
    int startMonthIndex = monthIndex - 3;
    int startYear = yearForMonth;
    if (startMonthIndex < 1) {
      startMonthIndex += 12; // Wrap to the previous year
      startYear--; // Adjust the year
    }

    // Calculate start and end dates
    DateTime startDate = DateTime(startYear, startMonthIndex, 1);
    DateTime endDate = DateTime(yearForMonth, monthIndex, 0);

    return {'fromDate': startDate, 'toDate': endDate};
  }

  void LoadDates() {
    currentDate = DateTime.now();
    currentMonthFromDate = DateTime(currentDate!.year, currentDate!.month, 1);
    currentMonthToDate = addMonth(
      currentMonthFromDate!,
      1,
    ).add(const Duration(days: -1));
    lastMonthFromDate = DateTime(currentDate!.year, currentDate!.month - 1, 1);
    lastMonthToDate = DateTime(currentDate!.year, currentDate!.month, 0);
    int fiscalYearStartMonth = 4;
    currentQuarter = getCurrentQuarter();
    getLastQuarterDates();
    DateTime now = DateTime.now();
    switch (currentQuarter) {
      case 1:
        currentQuarterFromDate = DateTime(now.year, 4, 1);
        currentQuarterToDate = DateTime(now.year, 6, 30);
      case 2:
        currentQuarterFromDate = DateTime(now.year, 7, 1);
        currentQuarterToDate = DateTime(now.year, 9, 30);
      case 3:
        currentQuarterFromDate = DateTime(now.year, 10, 1);
        currentQuarterToDate = DateTime(now.year, 12, 31);
      case 4:
        currentQuarterFromDate = DateTime(now.year, 1, 1);
        currentQuarterToDate = DateTime(now.year, 3, 31);
      default:
        throw Error();
    }
    int fiscalYear = currentDate!.month >= fiscalYearStartMonth
        ? currentDate!.year
        : currentDate!.year - 1;
    fiscalYearStartDate = DateTime(fiscalYear, fiscalYearStartMonth, 1);
    prevFiscalYearStartDate = addMonth(fiscalYearStartDate!, -12);
    prevFiscalYearEndDate = DateTime(prevFiscalYearStartDate!.year + 1, 4, 0);
    int fiscalYearStartYear = currentDate!.month >= 4
        ? currentDate!.year
        : currentDate!.year - 1;

    int fiscalYearEndYear = fiscalYearStartYear + 1;
    financialYear =
        'FY${fiscalYearStartYear.toString().substring(2)}-${fiscalYearEndYear.toString().substring(2)}';

    int prevFiscalYearStartYear = fiscalYearStartYear - 1;
    int prevFiscalYearEndYear = prevFiscalYearStartYear + 1;
    prevFinancialYear =
        'FY${prevFiscalYearStartYear.toString().substring(2)}-${prevFiscalYearEndYear.toString().substring(2)}';
  }

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
  }

  SideTitles get _leftTitles => SideTitles(
    reservedSize: 50,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String leftDouble = "";
      leftDouble = formatAmount(value);
      return Text(leftDouble, style: const TextStyle(fontSize: 12));
    },
  );

  SideTitles get _emptyTitlesTop =>
      SideTitles(showTitles: true, getTitlesWidget: getEmptyTopTitle);

  Widget getEmptyTopTitle(double val, TitleMeta meta) {
    return const Text("");
  }

  int monthDifference(DateTime startDate, DateTime endDate) {
    int years = endDate.year - startDate.year;
    int months = endDate.month - startDate.month;
    int differenceInMonths = (years * 12) + months;
    return differenceInMonths;
  }

  void LoadAllQuarterFromToDates() {
    DateTime now = DateTime.now();

    // Determine the financial year start
    int financialYearStart = (now.month >= 4) ? now.year : now.year - 1;

    // Define quarters
    q1FromDate = DateTime(financialYearStart, 4, 1);
    q1ToDate = DateTime(financialYearStart, 7, 0);

    q2FromDate = DateTime(financialYearStart, 7, 1);
    q2ToDate = DateTime(financialYearStart, 10, 0);

    q3FromDate = DateTime(financialYearStart, 10, 1);
    q3ToDate = DateTime(financialYearStart + 1, 1, 0); // December 31

    q4FromDate = DateTime(financialYearStart + 1, 1, 1);
    q4ToDate = DateTime(financialYearStart + 1, 4, 0); // March 31
  }

  Future<void> _loadEachQtrValues() async {
    double sum = 0;
    int MonthDiffs = 0;
    DateTime? lastQtrFromDt;
    DateTime? lastQtrToDt;
    for (int i = 1; i <= getCurrentQuarter(); i++) {
      switch (i) {
        case 1:
          lastQtrFromDt = addMonth(q1FromDate!, -3);
          lastQtrToDt = addMonth(
            lastQtrFromDt,
            3,
          ).add(const Duration(days: -1));
          sum = 0;
          var currentMonthSales = production.where((target) {
            DateTime invoiceDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.orderDate);

            return invoiceDate.isAtLeast(lastQtrFromDt!) &&
                invoiceDate.isAtMost(lastQtrToDt!);
          });

          double salesAmt = 0;
          for (var target in currentMonthSales.toList()) {
            salesAmt = double.tryParse(target.completedQty) ?? 0;
            sum += salesAmt;
          }
          Q1Target = sum / 3;

          sum = 0;
          MonthDiffs = monthDifference(q1FromDate!, currentDate!) == 0
              ? 1
              : monthDifference(q1FromDate!, currentDate!);
          Q1TargetStr = "${(Q1Target / 100000).toStringAsFixed(2)} L";
          var curQtrSales = production.where((target) {
            DateTime invoiceDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.orderDate);
            return invoiceDate.isAtLeast(q1FromDate!) &&
                invoiceDate.isAtMost(q1ToDate!);
          });
          sum = 0;
          salesAmt = 0;
          for (var target in curQtrSales.toList()) {
            salesAmt = double.tryParse(target.completedQty) ?? 0;
            sum += salesAmt;
          }

          Q1Sales = sum;
          Q1SalesStr = "${(Q1Sales / 100000).toStringAsFixed(2)} L";
          if (Q1Sales == 0) {
            Q1Percentage = 0;
          } else {
            Q1Percentage =
                double.tryParse(
                  ((Q1Sales / Q1Target) * 100).toStringAsFixed(2),
                )?.ceil() ??
                0;
          }
          Q1PercentageStr = "${Q1Percentage.toString()}%";
          Q1Average = (Q1Sales / MonthDiffs);
          Q1AverageStr = "${(Q1Average / 100000).toStringAsFixed(2)} L";
          Q1DiffStr =
              "${((Q1Target - Q1Sales > 0 ? Q1Target - Q1Sales : 0) / 100000).toStringAsFixed(2)} L";
          break;
        case 2:
          lastQtrFromDt = addMonth(q2FromDate!, -3);
          lastQtrToDt = addMonth(
            lastQtrFromDt,
            3,
          ).add(const Duration(days: -1));
          sum = 0;
          var currentMonthSales = production.where((target) {
            DateTime invoiceDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.orderDate);

            return invoiceDate.isAtLeast(lastQtrFromDt!) &&
                invoiceDate.isAtMost(lastQtrToDt!);
          });

          double salesAmt = 0;
          for (var target in currentMonthSales.toList()) {
            salesAmt = double.tryParse(target.completedQty) ?? 0;
            sum += salesAmt;
          }
          Q2Target = sum / 3;
          sum = 0;
          MonthDiffs = monthDifference(q2FromDate!, currentDate!) == 0
              ? 1
              : monthDifference(q2FromDate!, currentDate!);
          Q2TargetStr = "${(Q2Target / 100000).toStringAsFixed(2)} L";
          var curQtrSales = production.where((target) {
            DateTime invoiceDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.orderDate);
            return invoiceDate.isAtLeast(q2FromDate!) &&
                invoiceDate.isAtMost(q2ToDate!);
          });
          sum = 0;
          salesAmt = 0;
          for (var target in curQtrSales.toList()) {
            salesAmt = double.tryParse(target.completedQty) ?? 0;
            sum += salesAmt;
          }

          Q2Sales = sum;
          Q2SalesStr = "${(Q2Sales / 100000).toStringAsFixed(2)} L";
          if (Q2Sales == 0) {
            Q2Percentage = 0;
          } else {
            Q2Percentage =
                double.tryParse(
                  ((Q2Sales / Q2Target) * 100).toStringAsFixed(2),
                )?.ceil() ??
                0;
          }
          Q2PercentageStr = "${Q2Percentage.toString()}%";
          Q2Average = (Q2Sales / MonthDiffs);
          Q2AverageStr = "${(Q2Average / 100000).toStringAsFixed(2)} L";
          Q2DiffStr =
              "${((Q2Target - Q2Sales > 0 ? Q2Target - Q2Sales : 0) / 100000).toStringAsFixed(2)} L";
          break;
        case 3:
          lastQtrFromDt = addMonth(q3FromDate!, -3);
          lastQtrToDt = addMonth(
            lastQtrFromDt,
            3,
          ).add(const Duration(days: -1));
          sum = 0;
          var currentMonthSales = production.where((target) {
            DateTime invoiceDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.orderDate);

            return invoiceDate.isAtLeast(lastQtrFromDt!) &&
                invoiceDate.isAtMost(lastQtrToDt!);
          });

          double salesAmt = 0;
          for (var target in currentMonthSales.toList()) {
            salesAmt = double.tryParse(target.completedQty) ?? 0;
            sum += salesAmt;
          }
          Q3Target = sum / 3;
          sum = 0;
          MonthDiffs = monthDifference(q3FromDate!, currentDate!) == 0
              ? 1
              : monthDifference(q3FromDate!, currentDate!);
          Q3TargetStr = "${(Q3Target / 100000).toStringAsFixed(2)} L";
          var curQtrSales = production.where((target) {
            DateTime invoiceDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.orderDate);
            return invoiceDate.isAtLeast(q3FromDate!) &&
                invoiceDate.isAtMost(q3ToDate!);
          });
          sum = 0;
          salesAmt = 0;
          for (var target in curQtrSales.toList()) {
            salesAmt = double.tryParse(target.completedQty) ?? 0;
            sum += salesAmt;
          }

          Q3Sales = sum;
          Q3SalesStr = "${(Q3Sales / 100000).toStringAsFixed(2)} L";
          if (Q3Sales == 0) {
            Q3Percentage = 0;
          } else {
            Q3Percentage =
                double.tryParse(
                  ((Q3Sales / Q3Target) * 100).toStringAsFixed(2),
                )?.ceil() ??
                0;
          }
          Q3PercentageStr = "${Q3Percentage.toString()}%";
          Q3Average = (Q3Sales / MonthDiffs);
          Q3AverageStr = "${(Q3Average / 100000).toStringAsFixed(2)} L";
          Q3DiffStr =
              "${((Q3Target - Q3Sales > 0 ? Q3Target - Q3Sales : 0) / 100000).toStringAsFixed(2)} L";
          break;
        case 4:
          lastQtrFromDt = addMonth(q4FromDate!, -3);
          lastQtrToDt = addMonth(
            lastQtrFromDt,
            3,
          ).add(const Duration(days: -1));
          sum = 0;
          var currentMonthSales = production.where((target) {
            DateTime invoiceDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.orderDate);

            return invoiceDate.isAtLeast(lastQtrFromDt!) &&
                invoiceDate.isAtMost(lastQtrToDt!);
          });

          double salesAmt = 0;
          for (var target in currentMonthSales.toList()) {
            salesAmt = double.tryParse(target.completedQty) ?? 0;
            sum += salesAmt;
          }
          Q4Target = sum / 3;
          sum = 0;
          MonthDiffs = monthDifference(q4FromDate!, currentDate!) == 0
              ? 1
              : monthDifference(q4FromDate!, currentDate!);
          Q4TargetStr = "${(Q4Target / 100000).toStringAsFixed(2)} L";
          var curQtrSales = production.where((target) {
            DateTime invoiceDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.orderDate);
            return invoiceDate.isAtLeast(q4FromDate!) &&
                invoiceDate.isAtMost(q4ToDate!);
          });
          sum = 0;
          salesAmt = 0;
          for (var target in curQtrSales.toList()) {
            salesAmt = double.tryParse(target.completedQty) ?? 0;
            sum += salesAmt;
          }
          Q4Sales = sum;
          Q4SalesStr = "${(Q4Sales / 100000).toStringAsFixed(2)} L";
          if (Q4Sales == 0) {
            Q4Percentage = 0;
          } else {
            Q4Percentage =
                double.tryParse(
                  ((Q4Sales / Q4Target) * 100).toStringAsFixed(2),
                )?.ceil() ??
                0;
          }
          Q4PercentageStr = "${Q4Percentage.toString()}%";
          Q4Average = (Q4Sales / MonthDiffs);
          Q4AverageStr = "${(Q4Average / 100000).toStringAsFixed(2)} L";
          Q4DiffStr =
              "${((Q4Target - Q4Sales > 0 ? Q4Target - Q4Sales : 0) / 100000).toStringAsFixed(2)} L";
          break;
        default:
      }
    }
  }

  SideTitles get _bottomTitlesItemWiseProductionOrders => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<ItemWiseProductionData> mData = itemWiseData.itemWiseData;
      text = mData.elementAt(value.toInt()).itemName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: text.length > 7
              ? Text(
                  '${text.substring(0, 5)}...',
                  style: const TextStyle(fontSize: 12),
                )
              : Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesBranchWiseProductionOrders => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<BranchWiseProductionData> mData = branchWiseData.branchWiseData;
      text = mData.elementAt(value.toInt()).branchName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: text.length > 7
              ? Text(
                  '${text.substring(0, 5)}...',
                  style: const TextStyle(fontSize: 12),
                )
              : Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesItemGroupWiseAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<ItemGroupWiseProductionData> mData =
          itemGroupWiseData.itemGroupWiseData;
      text = mData.elementAt(value.toInt()).itemGroupName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: text.length > 7
              ? Text(
                  '${text.substring(0, 5)}...',
                  style: const TextStyle(fontSize: 12),
                )
              : Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesItemSubGroupWiseAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<ItemSubGroupWiseProductionData> mData =
          itemSubGroupWiseData.itemSubGroupWiseData;
      text = mData.elementAt(value.toInt()).itemSubGroupName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: text.length > 7
              ? Text(
                  '${text.substring(0, 5)}...',
                  style: const TextStyle(fontSize: 12),
                )
              : Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesPlantWiseAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<PlantWiseProductionData> mData = plantWiseData.plantData;
      text = mData.elementAt(value.toInt()).plantName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: text.length > 7
              ? Text(
                  '${text.substring(0, 5)}...',
                  style: const TextStyle(fontSize: 12),
                )
              : Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesUnitWiseAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<UnitWiseProductionData> mData = unitWiseData.unitData;
      text = mData.elementAt(value.toInt()).unitName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: text.length > 7
              ? Text(
                  '${text.substring(0, 5)}...',
                  style: const TextStyle(fontSize: 12),
                )
              : Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesShiftWiseAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<ShiftWiseProductionData> mData = shiftWiseData.shiftData;
      text = mData.elementAt(value.toInt()).shiftName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: text.length > 7
              ? Text(
                  '${text.substring(0, 5)}...',
                  style: const TextStyle(fontSize: 12),
                )
              : Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  List<PieChartSectionData> showingSections() {
    final List<PieChartSectionData> sections = [];
    for (final categoryData in statusData.statusData) {
      final fontSize = touchedIndex >= 1 ? 12.0 : 11.0;
      final radius = touchedIndex >= 1 ? 80.0 : 75.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      final sectionData = PieChartSectionData(
        color: getCategoryColor(categoryData.statusId),
        value: categoryData.statusPercentage,
        title: '${categoryData.statusPercentage.toStringAsFixed(2)} %',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          color: Colors.black,
          shadows: shadows,
        ),
      );
      sections.add(sectionData);
    }
    return sections;
  }

  List<BarChartGroupData> _monthWiseProductionAnalysisChartData(
    List<MonthlyProductionData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: chartData.target,
                  show: true,
                  color: const Color(0xFFF49136),
                ),
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.production,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _itemWiseProductionOrdersChartData(
    List<ItemWiseProductionData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: chartData.production3Month,
                  show: true,
                  color: const Color(0xFFFF9F47),
                ),
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.productionActual,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _branchWiseProductionOrdersChartData(
    List<BranchWiseProductionData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: chartData.production3Month,
                  show: true,
                  color: const Color(0xFFFF9F47),
                ),
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.productionActual,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _itemGroupWiseAnalysisChartData(
    List<ItemGroupWiseProductionData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: chartData.production3Month,
                  show: true,
                  color: const Color(0xFFFF9F47),
                ),
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.productionActual,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _itemSubGroupWiseAnalysisChartData(
    List<ItemSubGroupWiseProductionData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: chartData.production3Month,
                  show: true,
                  color: const Color(0xFFFF9F47),
                ),
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.productionActual,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _plantWiseAnalysisChartData(
    List<PlantWiseProductionData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: chartData.production3Month,
                  show: true,
                  color: const Color(0xFFFF9F47),
                ),
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.productionActual,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _unitWiseAnalysisChartData(
    List<UnitWiseProductionData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: chartData.production3Month,
                  show: true,
                  color: const Color(0xFFFF9F47),
                ),
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.productionActual,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _shiftWiseAnalysisChartData(
    List<ShiftWiseProductionData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: chartData.production3Month,
                  show: true,
                  color: const Color(0xFFFF9F47),
                ),
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.productionActual,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  Map<String, DateTime> getMonthStartEndDatesOld(int month) {
    int currentYear = DateTime.now().year;
    if (month >= 4 && month <= 12) {
      currentYear--;
    }
    DateTime firstDayOfMonth = DateTime(currentYear, month, 1);
    DateTime lastDayOfMonth = DateTime(currentYear, month + 1, 0);

    return {'start': firstDayOfMonth, 'end': lastDayOfMonth};
  }

  Map<String, DateTime> getMonthStartEndDates(int month) {
    DateTime now = DateTime.now();

    int currentYear = now.year;

    // Determine the correct year for the given month
    int yearForMonth;
    if (now.month >= 1 && now.month <= 3) {
      // If the call is happening in Jan–Mar
      yearForMonth = (month >= 4 && month <= 12)
          ? currentYear - 1
          : currentYear;
    } else {
      // If the call is happening in Apr–Dec
      yearForMonth = (month >= 4 && month <= 12)
          ? currentYear
          : currentYear + 1;
    }

    // Calculate the first and last days of the given month
    DateTime firstDayOfMonth = DateTime(yearForMonth, month, 1);
    DateTime lastDayOfMonth = DateTime(yearForMonth, month + 1, 0);

    return {'start': firstDayOfMonth, 'end': lastDayOfMonth};
  }

  Future<void> _loadProductionOrderTargetAnalysis(
    String UserName,
    String UserLevel,
  ) async {
    LoadAllQuarterFromToDates();
    int index = 0;
    int limit = 10000; // Maximum limit to fetch all data
    int fetchedCount = 0;
    List<ProductionOrderList> salesList = [];

    try {
      do {
        var body = {
          "FromDate": formatDate(addMonth(fiscalYearStartDate!, -3)),
          "ToDate": formatDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}BicxoProductionAnalysis';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<ProductionOrderList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => ProductionOrderList.fromJson(item))
                    .toList();

            salesList.addAll(newSalesList);
            fetchedCount = newSalesList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        production = salesList;
        context.read<ProductionOrderAnalysisProvider>().updatePurchaseList(
          salesList,
        );
        production = salesList.toList();
      });
      double sum = 0;
      DateTime? prevThreethFromDate;
      DateTime? prevThreeMthToDate;
      // prevThreethFromDate = addMonth(currentMonthFromDate!, -3);
      // prevThreeMthToDate =
      //     addMonth(prevThreethFromDate, 3).add(const Duration(days: -1));

      var dateRange = getLastThreeMonthsRange(currentMonthFromDate!.month);
      prevThreethFromDate = dateRange['fromDate']!;
      prevThreeMthToDate = dateRange['toDate']!;
      var currentMonthSales = production.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);

        return invoiceDate.isAtLeast(prevThreethFromDate!) &&
            invoiceDate.isAtMost(prevThreeMthToDate!);
      });

      double salesAmt = 0;
      for (var target in currentMonthSales.toList()) {
        salesAmt = double.tryParse(target.completedQty) ?? 0;
        sum += salesAmt;
      }

      CurrentMonthTarget = sum / 3;
      CurrentMonthTargetStr =
          "${(CurrentMonthTarget / 100000).toStringAsFixed(2)} L";

      // prevThreethFromDate = addMonth(lastMonthFromDate!, -3);
      // prevThreeMthToDate =
      //     addMonth(prevThreethFromDate, 3).add(const Duration(days: -1));

      dateRange = getLastThreeMonthsRange(lastMonthFromDate!.month);
      prevThreethFromDate = dateRange['fromDate']!;
      prevThreeMthToDate = dateRange['toDate']!;

      var lastMonthSales = production.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);

        return invoiceDate.isAtLeast(prevThreethFromDate!) &&
            invoiceDate.isAtMost(prevThreeMthToDate!);
      });

      sum = 0;
      salesAmt = 0;
      for (var target in lastMonthSales.toList()) {
        salesAmt = double.tryParse(target.completedQty) ?? 0;
        sum += salesAmt;
      }

      LastMonthTarget = sum / 3;
      LastMonthTargetStr = "${(LastMonthTarget / 100000).toStringAsFixed(2)} L";

      var curQtrSales = production.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return invoiceDate.isAtLeast(lastQuarterFromDate!) &&
            invoiceDate.isAtMost(lastQuarterToDate!);
      });

      sum = 0;
      salesAmt = 0;
      for (var target in curQtrSales.toList()) {
        salesAmt = double.tryParse(target.completedQty) ?? 0;
        sum += salesAmt;
      }

      CurrentQtrTarget = sum / 3;
      CurrentQtrTargetStr =
          "${(CurrentQtrTarget / 100000).toStringAsFixed(2)} L";

      var ytdSales = production.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return invoiceDate.isAtLeast(fiscalYearStartDate!) &&
            invoiceDate.isAtMost(currentDate!);
      });

      sum = 0;
      salesAmt = 0;
      for (var target in ytdSales.toList()) {
        salesAmt = double.tryParse(target.completedQty) ?? 0;
        sum += salesAmt;
      }

      YtdTarget = double.parse(
        ((sum / 12) *
                (currentDate!.month <= 12 && currentDate!.month >= 4
                    ? currentDate!.month - 3
                    : currentDate!.month + 9))
            .toStringAsFixed(2),
      );
      YtdTargetStr = "${(YtdTarget / 100000).toStringAsFixed(2)} L";
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      if (mounted) {
        final snackBar = SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Error: $e'),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> _loadProductionOrderAnalysis(
    String UserName,
    String UserLevel,
  ) async {
    LoadAllQuarterFromToDates();
    try {
      double sum = 0;
      var currentMonthSales = production.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);

        return invoiceDate.isAtLeast(currentMonthFromDate!) &&
            invoiceDate.isAtMost(currentDate!);
      });

      double salesAmt = 0;
      for (var target in currentMonthSales.toList()) {
        salesAmt = double.tryParse(target.completedQty) ?? 0;
        sum += salesAmt;
      }

      CurrentMonthSales = sum;
      CurrentMonthSalesStr =
          "${(CurrentMonthSales / 100000).toStringAsFixed(2)} L";
      if (CurrentMonthSales == 0) {
        CurrentMonthSalesPercentage = 0;
      } else {
        CurrentMonthSalesPercentage =
            double.tryParse(
              ((CurrentMonthSales / CurrentMonthTarget) * 100).toStringAsFixed(
                0,
              ),
            )?.ceil() ??
            0;
      }
      CurrentMonthSalesPercentageStr =
          "${CurrentMonthSalesPercentage.toString()} %";

      if (CurrentMonthSalesPercentage > 100) {
        CurrentMonthSalesPercentage = 100;
      }

      var lastMonthSales = production.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);

        return invoiceDate.isAtLeast(lastMonthFromDate!) &&
            invoiceDate.isAtMost(lastMonthToDate!);
      });

      sum = 0;
      salesAmt = 0;
      for (var target in lastMonthSales.toList()) {
        salesAmt = double.tryParse(target.completedQty) ?? 0;
        sum += salesAmt;
      }

      LastMonthSales = sum;
      LastMonthSalesStr = "${(LastMonthSales / 100000).toStringAsFixed(2)} L";
      if (LastMonthSales == 0) {
        LastMonthPercentage = 0;
      } else {
        LastMonthPercentage =
            double.tryParse(
              ((LastMonthSales / LastMonthTarget) * 100).toStringAsFixed(2),
            )?.ceil() ??
            0;
      }
      LastMonthPercentageStr = "${LastMonthPercentage.toString()} %";
      if (LastMonthPercentage > 100) {
        LastMonthPercentage = 100;
      }

      var curQtrSales = production.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return invoiceDate.isAtLeast(currentQuarterFromDate!) &&
            invoiceDate.isAtMost(currentQuarterToDate!);
      });

      sum = 0;
      salesAmt = 0;
      for (var target in curQtrSales.toList()) {
        salesAmt = double.tryParse(target.completedQty) ?? 0;
        sum += salesAmt;
      }

      CurrentQtrSales = sum;
      CurrentQtrSalesStr = "${(CurrentQtrSales / 100000).toStringAsFixed(2)} L";
      if (CurrentQtrSales == 0) {
        CurrentQtrPercentage = 0;
      } else {
        CurrentQtrPercentage =
            double.tryParse(
              ((CurrentQtrSales / CurrentQtrTarget) * 100).toStringAsFixed(2),
            )?.ceil() ??
            0;
      }
      CurrentQtrPercentageStr = "${CurrentQtrPercentage.toString()} %";
      if (CurrentQtrPercentage > 100) {
        CurrentQtrPercentage = 100;
      }

      var ytdSales = production.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return invoiceDate.isAtLeast(fiscalYearStartDate!) &&
            invoiceDate.isAtMost(currentDate!);
      });

      sum = 0;
      salesAmt = 0;
      for (var target in ytdSales.toList()) {
        salesAmt = double.tryParse(target.completedQty) ?? 0;
        sum += salesAmt;
      }

      YtdSales = sum;
      YtdSalesStr = "${(YtdSales / 100000).toStringAsFixed(2)} L";
      if (YtdSales == 0) {
        YtdPercentage = 0;
      } else {
        YtdPercentage =
            double.tryParse(
              ((YtdSales / YtdTarget) * 100).toStringAsFixed(2),
            )?.ceil() ??
            0;
      }
      YtdPercentageStr = "${YtdPercentage.toString()} %";

      if (YtdPercentage > 100) {
        YtdPercentage = 100;
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      if (mounted) {
        final snackBar = SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Error: $e'),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> _loadMonthlyProductionBarChartData() async {
    List<MonthlyProductionData> month = [];
    int currentYear = DateTime.now().year;
    DateTime startDate;
    DateTime endDate;
    String monthName = "";
    double monthlyTarget = 0.00;
    double monthlyProduction = 0.00;
    var monthlyProductionActual = const Iterable.empty();
    var monthlyProductionTarget = const Iterable.empty();
    double sum = 0;

    for (int i = 4; i <= 15; i++) {
      monthName = getMonthName(i);

      if (i >= 4 && i <= 12) {
        var result = getLastThreeMonthsRange(i);
        monthlyProductionTarget = production.where((target) {
          DateTime invoiceDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.orderDate);
          return invoiceDate.isAtLeast(result['fromDate']!) &&
              invoiceDate.isAtMost(result['toDate']!);
        });

        Map<String, DateTime> monthDates = getMonthStartEndDates(i);
        monthlyProductionActual = production.where((target) {
          DateTime invoiceDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.orderDate);
          return invoiceDate.isAtLeast(monthDates['start']!) &&
              invoiceDate.isAtMost(monthDates['end']!);
        });
      } else {
        monthName = getMonthName(i - 12);
        var result = getLastThreeMonthsRange(i - 12);
        monthlyProductionTarget = production.where((target) {
          DateTime invoiceDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.orderDate);
          return invoiceDate.isAtLeast(result['fromDate']!) &&
              invoiceDate.isAtMost(result['toDate']!);
        });

        startDate = DateTime(currentYear, i - 12, 1);
        endDate = DateTime(currentYear, (i - 12) + 1, 0);
        monthlyProductionActual = production.where((target) {
          DateTime invoiceDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.orderDate);
          return invoiceDate.isAtLeast(startDate) &&
              invoiceDate.isAtMost(endDate);
        });
      }
      double targetAmt = 0;
      double actualAmt = 0;
      sum = 0;
      for (var target in monthlyProductionTarget.toList()) {
        targetAmt = double.tryParse(target.completedQty) ?? 0;
        sum += targetAmt;
      }
      monthlyTarget = sum / 3;

      for (var target in monthlyProductionActual.toList()) {
        actualAmt = (double.tryParse(target.completedQty) ?? 0);
        monthlyProduction += actualAmt;
      }
      if (monthlyProduction > 0) {
        month.add(
          MonthlyProductionData(
            monthName: monthName,
            target: monthlyTarget,
            production: monthlyProduction,
          ),
        );
      }
      monthlyProduction = 0;
      monthlyTarget = 0;
      monthData = MonthlyProductionList(monthlyData: month);
    }
    monthData = MonthlyProductionList(monthlyData: month);
  }

  Future<void> _loadItemWiseProductionOrders(
    int monthIndex,
    String itemCode,
    String branchName,
    String itemGroup,
    String itemSubGroup,
    String plantName,
    String unitName,
    String shiftName,
  ) async {
    List<ItemWiseProductionData> productwiseDataList = [];
    var tempList = production;
    String itemName = "";
    double productActual = 0.00;
    double product3Month = 0.00;
    DateTime prevThreethFromDate = DateTime(
      currentDate!.year,
      currentDate!.month - 3,
      1,
    );
    DateTime prevThreeMthToDate = DateTime(
      currentDate!.year,
      currentDate!.month,
      0,
    );

    var productSalesList = const Iterable.empty();
    var saleList = const Iterable.empty();
    var saleList3Months = const Iterable.empty();
    DateTime startDate;
    DateTime endDate;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      saleList3Months = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate));
      });

      productSalesList = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return (invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate));
      });
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      prevThreethFromDate = addMonth(monthDates['start']!, -3);
      prevThreeMthToDate = addMonth(
        prevThreethFromDate,
        3,
      ).add(const Duration(days: -1));

      saleList3Months = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate);
      });

      productSalesList = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }
    saleList = filterProductionList(
      productSalesList.cast<ProductionOrderList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      plantName: plantName,
      unitName: unitName,
      shiftName: shiftName,
    );
    saleList3Months = filterProductionList(
      saleList3Months.cast<ProductionOrderList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      plantName: plantName,
      unitName: unitName,
      shiftName: shiftName,
    );

    Set<String> processedProductCodes = {};
    for (var product in saleList.toList().toList()) {
      if (!processedProductCodes.contains(product.productDescription)) {
        itemName = product.productDescription;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.productDescription == itemName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.completedQty) ?? 0;
          productActual += salesAmt;
        }
        for (var target in saleList3Months.toList().where(
          (element) => element.productDescription == itemName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.completedQty) ?? 0;
          product3Month += salesAmt;
        }
        if (productActual > 0) {
          productwiseDataList.add(
            ItemWiseProductionData(
              itemName: itemName,
              productionActual: productActual,
              production3Month: product3Month / 3,
            ),
          );
        }
        processedProductCodes.add(product.productDescription);
      }
      productActual = 0;
      product3Month = 0;
      itemName = "";
    }
    productwiseDataList.sort(
      (a, b) => b.productionActual.compareTo(a.productionActual),
    );

    itemWiseData = ItemWiseProductionList(itemWiseData: productwiseDataList);
  }

  Future<void> _loadBranchWiseProductionOrders(
    int monthIndex,
    String itemCode,
    String branchName,
    String itemGroup,
    String itemSubGroup,
    String plantName,
    String unitName,
    String shiftName,
  ) async {
    List<BranchWiseProductionData> branchwiseDataList = [];
    var tempList = production;
    String branch = "";
    double productActual = 0.00;
    double product3Month = 0.00;
    DateTime prevThreethFromDate = DateTime(
      currentDate!.year,
      currentDate!.month - 3,
      1,
    );
    DateTime prevThreeMthToDate = DateTime(
      currentDate!.year,
      currentDate!.month,
      0,
    );

    var productSalesList = const Iterable.empty();
    var saleList = const Iterable.empty();
    var saleList3Months = const Iterable.empty();
    DateTime startDate;
    DateTime endDate;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      saleList3Months = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate));
      });

      productSalesList = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return (invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate));
      });
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      prevThreethFromDate = addMonth(monthDates['start']!, -3);
      prevThreeMthToDate = addMonth(
        prevThreethFromDate,
        3,
      ).add(const Duration(days: -1));

      saleList3Months = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate);
      });

      productSalesList = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }
    saleList = filterProductionList(
      productSalesList.cast<ProductionOrderList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      plantName: plantName,
      unitName: unitName,
      shiftName: shiftName,
    );
    saleList3Months = filterProductionList(
      saleList3Months.cast<ProductionOrderList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      plantName: plantName,
      unitName: unitName,
      shiftName: shiftName,
    );

    Set<String> processedProductCodes = {};
    for (var product in saleList.toList().toList()) {
      if (!processedProductCodes.contains(product.branch)) {
        branch = product.branch;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.branch == branch,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.completedQty) ?? 0;
          productActual += salesAmt;
        }
        for (var target in saleList3Months.toList().where(
          (element) => element.branch == branch,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.completedQty) ?? 0;
          product3Month += salesAmt;
        }

        branchwiseDataList.add(
          BranchWiseProductionData(
            branchName: branch,
            productionActual: productActual,
            production3Month: product3Month / 3,
          ),
        );
        processedProductCodes.add(product.branch);
      }
      productActual = 0;
      product3Month = 0;
      branch = "";
    }
    branchwiseDataList.sort(
      (a, b) => b.productionActual.compareTo(a.productionActual),
    );

    branchWiseData = BranchWiseProductionList(
      branchWiseData: branchwiseDataList,
    );
  }

  Future<void> _loadItemGroupWiseProductionOrders(
    int monthIndex,
    String itemCode,
    String branchName,
    String itemGroup,
    String itemSubGroup,
    String plantName,
    String unitName,
    String shiftName,
  ) async {
    List<ItemGroupWiseProductionData> itemGroupWiseDataList = [];
    var tempList = production;
    String group = "";
    double productActual = 0.00;
    double product3Month = 0.00;
    var productSalesList = const Iterable.empty();
    var saleList = const Iterable.empty();
    var saleList3Months = const Iterable.empty();

    DateTime prevThreethFromDate = DateTime(
      currentDate!.year,
      currentDate!.month - 3,
      1,
    );
    DateTime prevThreeMthToDate = DateTime(
      currentDate!.year,
      currentDate!.month,
      0,
    );
    DateTime startDate;
    DateTime endDate;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      saleList3Months = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate));
      });

      productSalesList = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return (invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate));
      });
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      prevThreethFromDate = addMonth(monthDates['start']!, -3);
      prevThreeMthToDate = addMonth(
        prevThreethFromDate,
        3,
      ).add(const Duration(days: -1));

      saleList3Months = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate);
      });

      productSalesList = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }
    saleList = filterProductionList(
      productSalesList.cast<ProductionOrderList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      plantName: plantName,
      unitName: unitName,
      shiftName: shiftName,
    );
    saleList3Months = filterProductionList(
      saleList3Months.cast<ProductionOrderList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      plantName: plantName,
      unitName: unitName,
      shiftName: shiftName,
    );

    Set<String> processedProductCodes = {};
    for (var product in saleList.toList().toList()) {
      if (!processedProductCodes.contains(product.groupName)) {
        group = product.groupName;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.groupName == group,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.completedQty) ?? 0;
          productActual += salesAmt;
        }
        for (var target in saleList3Months.toList().where(
          (element) => element.groupName == group,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.completedQty) ?? 0;
          product3Month += salesAmt;
        }

        itemGroupWiseDataList.add(
          ItemGroupWiseProductionData(
            itemGroupName: group,
            production3Month: product3Month / 3,
            productionActual: productActual,
          ),
        );
        processedProductCodes.add(product.groupName);
      }
      productActual = 0;
      product3Month = 0;
      group = "";
    }
    itemGroupWiseDataList.sort(
      (a, b) => b.productionActual.compareTo(a.productionActual),
    );

    itemGroupWiseData = ItemGroupWiseProductionList(
      itemGroupWiseData: itemGroupWiseDataList,
    );
  }

  Future<void> _loadItemSubGroupWiseProductionOrders(
    int monthIndex,
    String itemCode,
    String branchName,
    String itemGroup,
    String itemSubGroup,
    String plantName,
    String unitName,
    String shiftName,
  ) async {
    List<ItemSubGroupWiseProductionData> itemGroupWiseDataList = [];
    var tempList = production;
    String subGroup = "";
    double productActual = 0.00;
    double product3Month = 0.00;

    var productSalesList = const Iterable.empty();
    var saleList = const Iterable.empty();
    var saleList3Months = const Iterable.empty();

    DateTime prevThreethFromDate = DateTime(
      currentDate!.year,
      currentDate!.month - 3,
      1,
    );
    DateTime prevThreeMthToDate = DateTime(
      currentDate!.year,
      currentDate!.month,
      0,
    );
    DateTime startDate;
    DateTime endDate;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      saleList3Months = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate));
      });

      productSalesList = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return (invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate));
      });
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      prevThreethFromDate = addMonth(monthDates['start']!, -3);
      prevThreeMthToDate = addMonth(
        prevThreethFromDate,
        3,
      ).add(const Duration(days: -1));

      saleList3Months = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate);
      });

      productSalesList = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }
    saleList = filterProductionList(
      productSalesList.cast<ProductionOrderList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      plantName: plantName,
      unitName: unitName,
      shiftName: shiftName,
    );
    saleList3Months = filterProductionList(
      saleList3Months.cast<ProductionOrderList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      plantName: plantName,
      unitName: unitName,
      shiftName: shiftName,
    );

    Set<String> processedProductCodes = {};
    for (var product in saleList.toList().toList()) {
      if (!processedProductCodes.contains(product.itemSubGroup)) {
        subGroup = product.itemSubGroup;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.itemSubGroup == subGroup,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.completedQty) ?? 0;
          productActual += salesAmt;
        }

        for (var target in saleList3Months.toList().where(
          (element) => element.itemSubGroup == subGroup,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.completedQty) ?? 0;
          product3Month += salesAmt;
        }

        itemGroupWiseDataList.add(
          ItemSubGroupWiseProductionData(
            itemSubGroupName: subGroup,
            production3Month: product3Month / 3,
            productionActual: productActual,
          ),
        );
        processedProductCodes.add(product.itemSubGroup);
      }
      productActual = 0;
      product3Month = 0;
      subGroup = "";
    }
    itemGroupWiseDataList.sort(
      (a, b) => b.productionActual.compareTo(a.productionActual),
    );
    itemSubGroupWiseData = ItemSubGroupWiseProductionList(
      itemSubGroupWiseData: itemGroupWiseDataList,
    );
  }

  Future<void> _loadPlantWiseProductionOrders(
    int monthIndex,
    String itemCode,
    String branchName,
    String itemGroup,
    String itemSubGroup,
    String plantName,
    String unitName,
    String shiftName,
  ) async {
    List<PlantWiseProductionData> plantDataList = [];
    var tempList = production;
    String plant = "";
    double productActual = 0.00;
    double product3Month = 0.00;

    var productionList = const Iterable.empty();
    var saleList = const Iterable.empty();
    var production3Months = const Iterable.empty();
    DateTime prevThreethFromDate = DateTime(
      currentDate!.year,
      currentDate!.month - 3,
      1,
    );
    DateTime prevThreeMthToDate = DateTime(
      currentDate!.year,
      currentDate!.month,
      0,
    );
    DateTime startDate;
    DateTime endDate;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      production3Months = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate));
      });

      productionList = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return (invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate));
      });
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      prevThreethFromDate = addMonth(monthDates['start']!, -3);
      prevThreeMthToDate = addMonth(
        prevThreethFromDate,
        3,
      ).add(const Duration(days: -1));

      production3Months = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate);
      });

      productionList = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }
    saleList = filterProductionList(
      productionList.cast<ProductionOrderList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      plantName: plantName,
      unitName: unitName,
      shiftName: shiftName,
    );
    production3Months = filterProductionList(
      production3Months.cast<ProductionOrderList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      plantName: plantName,
      unitName: unitName,
      shiftName: shiftName,
    );

    Set<String> processedProductCodes = {};
    for (var product in saleList.toList().toList()) {
      if (!processedProductCodes.contains(product.plant)) {
        plant = product.plant;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.plant == plant,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.completedQty) ?? 0;
          productActual += salesAmt;
        }
        for (var target in production3Months.toList().where(
          (element) => element.plant == plant,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.completedQty) ?? 0;
          product3Month += salesAmt;
        }

        plantDataList.add(
          PlantWiseProductionData(
            plantName: plant,
            production3Month: product3Month / 3,
            productionActual: productActual,
          ),
        );
        processedProductCodes.add(product.plant);
      }
      productActual = 0;
      product3Month = 0;
      plant = "";
    }
    plantDataList.sort(
      (a, b) => b.productionActual.compareTo(a.productionActual),
    );
    plantWiseData = PlantWiseProductionList(plantData: plantDataList);
  }

  Future<void> _loadUnitWiseProductionOrders(
    int monthIndex,
    String itemCode,
    String branchName,
    String itemGroup,
    String itemSubGroup,
    String plantName,
    String unitName,
    String shiftName,
  ) async {
    List<UnitWiseProductionData> unitDataList = [];
    var tempList = production;
    String unit = "";
    double productActual = 0.00;
    double product3Month = 0.00;

    var productionList = const Iterable.empty();
    var saleList = const Iterable.empty();
    var production3Months = const Iterable.empty();
    DateTime prevThreethFromDate = DateTime(
      currentDate!.year,
      currentDate!.month - 3,
      1,
    );
    DateTime prevThreeMthToDate = DateTime(
      currentDate!.year,
      currentDate!.month,
      0,
    );
    DateTime startDate;
    DateTime endDate;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      production3Months = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate));
      });

      productionList = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return (invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate));
      });
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      prevThreethFromDate = addMonth(monthDates['start']!, -3);
      prevThreeMthToDate = addMonth(
        prevThreethFromDate,
        3,
      ).add(const Duration(days: -1));

      production3Months = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate);
      });

      productionList = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }
    saleList = filterProductionList(
      productionList.cast<ProductionOrderList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      plantName: plantName,
      unitName: unitName,
      shiftName: shiftName,
    );
    production3Months = filterProductionList(
      production3Months.cast<ProductionOrderList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      plantName: plantName,
      unitName: unitName,
      shiftName: shiftName,
    );

    Set<String> processedProductCodes = {};
    for (var product in saleList.toList().toList()) {
      if (!processedProductCodes.contains(product.unit)) {
        unit = product.unit;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.unit == unit,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.completedQty) ?? 0;
          productActual += salesAmt;
        }
        for (var target in production3Months.toList().where(
          (element) => element.unit == unit,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.completedQty) ?? 0;
          product3Month += salesAmt;
        }

        unitDataList.add(
          UnitWiseProductionData(
            unitName: unit,
            production3Month: product3Month / 3,
            productionActual: productActual,
          ),
        );
        processedProductCodes.add(product.unit);
      }
      productActual = 0;
      product3Month = 0;
      unit = "";
    }
    unitDataList.sort(
      (a, b) => b.productionActual.compareTo(a.productionActual),
    );
    unitWiseData = UnitWiseProductionList(unitData: unitDataList);
  }

  Future<void> _loadShiftWiseProductionOrders(
    int monthIndex,
    String itemCode,
    String branchName,
    String itemGroup,
    String itemSubGroup,
    String plantName,
    String unitName,
    String shiftName,
  ) async {
    List<ShiftWiseProductionData> shiftDataList = [];
    var tempList = production;
    String shift = "";
    double productActual = 0.00;
    double product3Month = 0.00;

    var productionList = const Iterable.empty();
    var saleList = const Iterable.empty();
    var production3Months = const Iterable.empty();
    DateTime prevThreethFromDate = DateTime(
      currentDate!.year,
      currentDate!.month - 3,
      1,
    );
    DateTime prevThreeMthToDate = DateTime(
      currentDate!.year,
      currentDate!.month,
      0,
    );
    DateTime startDate;
    DateTime endDate;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
      production3Months = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate));
      });

      productionList = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return (invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate));
      });
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      prevThreethFromDate = addMonth(monthDates['start']!, -3);
      prevThreeMthToDate = addMonth(
        prevThreethFromDate,
        3,
      ).add(const Duration(days: -1));

      production3Months = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate);
      });

      productionList = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }
    saleList = filterProductionList(
      productionList.cast<ProductionOrderList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      plantName: plantName,
      unitName: unitName,
      shiftName: shiftName,
    );
    production3Months = filterProductionList(
      production3Months.cast<ProductionOrderList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      plantName: plantName,
      unitName: unitName,
      shiftName: shiftName,
    );

    Set<String> processedProductCodes = {};
    for (var product in saleList.toList().toList()) {
      if (!processedProductCodes.contains(product.shift)) {
        shift = product.shift;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.shift == shift,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.completedQty) ?? 0;
          productActual += salesAmt;
        }
        for (var target in production3Months.toList().where(
          (element) => element.shift == shift,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.completedQty) ?? 0;
          product3Month += salesAmt;
        }

        shiftDataList.add(
          ShiftWiseProductionData(
            shiftName: shift,
            production3Month: product3Month / 3,
            productionActual: productActual,
          ),
        );
        processedProductCodes.add(product.shift);
      }
      productActual = 0;
      product3Month = 0;
      shift = "";
    }
    shiftDataList.sort(
      (a, b) => b.productionActual.compareTo(a.productionActual),
    );
    shiftWiseData = ShiftWiseProductionList(shiftData: shiftDataList);
  }

  Future<void> _loadOrderStatusProduction(
    int monthIndex,
    String itemCode,
    String branchName,
    String itemGroup,
    String itemSubGroup,
    String plantName,
    String unitName,
    String shiftName,
  ) async {
    List<OrderStatusData> statusList = [];
    var tempList = production;
    String statusName = "";
    double productActual = 0.00;
    int categoryId = 0;

    var saleList = const Iterable.empty();
    var productionList = const Iterable.empty();
    DateTime startDate;
    DateTime endDate;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;

      productionList = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return (invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate));
      });
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);

      productionList = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }
    saleList = filterProductionList(
      productionList.cast<ProductionOrderList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      plantName: plantName,
      unitName: unitName,
      shiftName: shiftName,
    );

    Set<String> processedProductCodes = {};
    for (var product in saleList.toList()) {
      if (!processedProductCodes.contains(product.status)) {
        statusName = product.status;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.status == statusName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.plannedQty) ?? 0;
          productActual += salesAmt;
        }

        statusList.add(
          OrderStatusData(
            statusId: categoryId++,
            statusAmount: productActual,
            statusName: statusName,
            statusPercentage: 0,
          ),
        );
        processedProductCodes.add(product.status);
      }
      productActual = 0;
      statusName = "";
    }

    double totalAmount = statusList.fold(
      0,
      (double previousValue, OrderStatusData element) =>
          previousValue + element.statusAmount,
    );

    for (OrderStatusData categoryData in statusList) {
      categoryData.statusPercentage =
          double.tryParse(
            ((categoryData.statusAmount / totalAmount) * 100).toStringAsFixed(
              2,
            ),
          ) ??
          0;
      categoryData.statusAmount =
          double.tryParse(
            (categoryData.statusAmount / 100000).toStringAsFixed(2),
          ) ??
          0;
    }

    statusData = OrderStatusList(statusData: statusList);
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadProductionOrderTargetAnalysis(userName, userLevel);
    await _loadProductionOrderAnalysis(userName, userLevel);
    await _loadEachQtrValues();
    await _loadMonthlyProductionBarChartData();
    await _loadItemWiseProductionOrders(0, "", "", "", "", "", "", "");
    await _loadBranchWiseProductionOrders(0, "", "", "", "", "", "", "");
    await _loadItemGroupWiseProductionOrders(0, "", "", "", "", "", "", "");
    await _loadItemSubGroupWiseProductionOrders(0, "", "", "", "", "", "", "");
    await _loadPlantWiseProductionOrders(0, "", "", "", "", "", "", "");
    await _loadUnitWiseProductionOrders(0, "", "", "", "", "", "", "");
    await _loadShiftWiseProductionOrders(0, "", "", "", "", "", "", "");
    await _loadOrderStatusProduction(0, "", "", "", "", "", "", "");

    chartDataLoaded = true;
  }

  List<ProductionOrderList> filterProductionList(
    List<ProductionOrderList> productionList, {
    String? itemCode,
    String? itemGroup,
    String? itemSubGroup,
    String? branchName,
    String? plantName,
    String? unitName,
    String? shiftName,
  }) {
    List<ProductionOrderList> filteredProductionList = [];
    for (var production in productionList) {
      if ((itemCode == null ||
              itemCode.isEmpty ||
              production.productDescription == itemCode) &&
          (itemGroup == null ||
              itemGroup.isEmpty ||
              production.groupName == itemGroup) &&
          (itemSubGroup == null ||
              itemSubGroup.isEmpty ||
              production.itemSubGroup == itemSubGroup) &&
          (branchName == null ||
              branchName.isEmpty ||
              production.branch == branchName) &&
          (plantName == null ||
              plantName.isEmpty ||
              production.plant == plantName) &&
          (unitName == null ||
              unitName.isEmpty ||
              production.unit == unitName) &&
          (shiftName == null ||
              shiftName.isEmpty ||
              production.shift == shiftName)) {
        filteredProductionList.add(production);
      }
    }
    return filteredProductionList;
  }

  Future<void> removeFilter() async {
    touchedMonthIndex = 0;
    touchedItemCode = "";
    touchedItemGroup = "";
    touchedItemSubGroup = "";
    touchedBranchName = "";
    touchedPlant = "";
    touchedUnit = "";
    touchedShift = "";

    touchedMonthGoals = false;
    touchedQuarterGoals = false;
    touchedYTDGoals = false;
    clearVariables();
    LoadDates();
    LoadAllQuarterFromToDates();
    await _loadEachQtrValues();
    await _loadItemWiseProductionOrders(0, "", "", "", "", "", "", "");
    await _loadBranchWiseProductionOrders(0, "", "", "", "", "", "", "");
    await _loadItemGroupWiseProductionOrders(0, "", "", "", "", "", "", "");
    await _loadItemSubGroupWiseProductionOrders(0, "", "", "", "", "", "", "");
    await _loadPlantWiseProductionOrders(0, "", "", "", "", "", "", "");
    await _loadUnitWiseProductionOrders(0, "", "", "", "", "", "", "");
    await _loadShiftWiseProductionOrders(0, "", "", "", "", "", "", "");
    await _loadOrderStatusProduction(0, "", "", "", "", "", "", "");
    chartDataLoaded = true;
  }

  Future<void> loadDataWithFilter(
    int monthIndex,
    String itemCode,
    String branchName,
    String itemGroup,
    String itemSubGroup,
    String plantName,
    String unitName,
    String shiftName,
  ) async {
    clearVariablesForFilter();
    LoadDates();
    LoadAllQuarterFromToDates();
    await _loadItemWiseProductionOrders(
      monthIndex,
      itemCode,
      branchName,
      itemGroup,
      itemSubGroup,
      plantName,
      unitName,
      shiftName,
    );
    await _loadBranchWiseProductionOrders(
      monthIndex,
      itemCode,
      branchName,
      itemGroup,
      itemSubGroup,
      plantName,
      unitName,
      shiftName,
    );
    await _loadItemGroupWiseProductionOrders(
      monthIndex,
      itemCode,
      branchName,
      itemGroup,
      itemSubGroup,
      plantName,
      unitName,
      shiftName,
    );
    await _loadItemSubGroupWiseProductionOrders(
      monthIndex,
      itemCode,
      branchName,
      itemGroup,
      itemSubGroup,
      plantName,
      unitName,
      shiftName,
    );
    await _loadPlantWiseProductionOrders(
      monthIndex,
      itemCode,
      branchName,
      itemGroup,
      itemSubGroup,
      plantName,
      unitName,
      shiftName,
    );
    await _loadUnitWiseProductionOrders(
      monthIndex,
      itemCode,
      branchName,
      itemGroup,
      itemSubGroup,
      plantName,
      unitName,
      shiftName,
    );
    await _loadShiftWiseProductionOrders(
      monthIndex,
      itemCode,
      branchName,
      itemGroup,
      itemSubGroup,
      plantName,
      unitName,
      shiftName,
    );
    await _loadOrderStatusProduction(
      monthIndex,
      itemCode,
      branchName,
      itemGroup,
      itemSubGroup,
      plantName,
      unitName,
      shiftName,
    );
    chartDataLoaded = true;
  }

  void clearVariables() {
    setState(() {
      chartDataLoaded = false;
      SalesGoal = 0;
      LastMonthSales = 0;
      LastMonthTarget = 0;
      CurrentQtrSales = 0;
      CurrentQtrTarget = 0;
      YtdSales = 0;
      YtdTarget = 0;
      Q1Sales = 0;
      Q1Target = 0;
      Q1Diff = 0;
      Q1Percentage = 0;
      Q1SalesStr = "";
      Q1TargetStr = "";
      Q1DiffStr = "";
      Q1PercentageStr = "";
      Q2Sales = 0;
      Q2Target = 0;
      Q2Diff = 0;
      Q2Percentage = 0;
      Q2SalesStr = "";
      Q2TargetStr = "";
      Q2DiffStr = "";
      Q2PercentageStr = "";
      Q3Sales = 0;
      Q3Target = 0;
      Q3Diff = 0;
      Q3Percentage = 0;
      Q3SalesStr = "";
      Q3TargetStr = "";
      Q3DiffStr = "";
      Q3PercentageStr = "";
      Q4Sales = 0;
      Q4Target = 0;
      Q4Diff = 0;
      Q4Percentage = 0;
      Q4SalesStr = "";
      Q4TargetStr = "";
      Q4DiffStr = "";
      Q4PercentageStr = "";
      Q1Average = 0;
      Q1AverageStr = "";
      Q2Average = 0;
      Q2AverageStr = "";
      Q3Average = 0;
      Q3AverageStr = "";
      Q4Average = 0;
      Q4AverageStr = "";
      itemWiseData = ItemWiseProductionList(itemWiseData: []);
      branchWiseData = BranchWiseProductionList(branchWiseData: []);
      itemGroupWiseData = ItemGroupWiseProductionList(itemGroupWiseData: []);
      itemSubGroupWiseData = ItemSubGroupWiseProductionList(
        itemSubGroupWiseData: [],
      );
      plantWiseData = PlantWiseProductionList(plantData: []);
      unitWiseData = UnitWiseProductionList(unitData: []);
      shiftWiseData = ShiftWiseProductionList(shiftData: []);
      statusData = OrderStatusList(statusData: []);
      touchedMonthIndex = 0;
      touchedItemCode = "";
      touchedItemGroup = "";
      touchedItemSubGroup = "";
      touchedBranchName = "";
      touchedPlant = "";
      touchedUnit = "";
      touchedShift = "";
    });
  }

  void clearVariablesForFilter() {
    setState(() {
      chartDataLoaded = false;
      itemWiseData = ItemWiseProductionList(itemWiseData: []);
      branchWiseData = BranchWiseProductionList(branchWiseData: []);
      itemGroupWiseData = ItemGroupWiseProductionList(itemGroupWiseData: []);
      itemSubGroupWiseData = ItemSubGroupWiseProductionList(
        itemSubGroupWiseData: [],
      );
      plantWiseData = PlantWiseProductionList(plantData: []);
      unitWiseData = UnitWiseProductionList(unitData: []);
      shiftWiseData = ShiftWiseProductionList(shiftData: []);
      statusData = OrderStatusList(statusData: []);
    });
  }

  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  Future<void> generateMonthlyProductionExcel(
    MonthlyProductionList monthlyProductionList,
  ) async {
    double totalProduction = 0;
    double totalTarget = 0;
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Month', 'Achievement', 'Target']));
      for (var monthlyData in monthlyProductionList.monthlyData) {
        sheet.appendRow(
          toCellRow([
            monthlyData.monthName,
            monthlyData.production,
            monthlyData.target,
          ]),
        );
        totalProduction += monthlyData.production;
        totalTarget += monthlyData.target;
      }
      sheet.appendRow(toCellRow(["", totalProduction, totalTarget]));

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('monthly_production_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthly_production_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateMonthlyProductionPDF(
    MonthlyProductionList monthlyProductionList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Monthly Production Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Table(
              border: pw.TableBorder.all(),
              children: [
                // Table header
                pw.TableRow(
                  children: [
                    pw.Text(
                      'Month',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Achievement',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Target',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var monthlyData in monthlyProductionList.monthlyData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        monthlyData.monthName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        monthlyData.production.toStringAsFixed(2),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        monthlyData.target.toStringAsFixed(2),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      );

      if (kIsWeb) {
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthly_production_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemProductionExcel(
    ItemWiseProductionList itemWiseProductionList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow(['Product Name', 'Production Qty.', 'Monthly Avg.']),
      );
      for (var itemData in itemWiseProductionList.itemWiseData) {
        sheet.appendRow(
          toCellRow([
            itemData.itemName,
            itemData.productionActual.toStringAsFixed(2),
            itemData.production3Month.toStringAsFixed(2),
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('item_production_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/item_production_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemProductionPDF(
    ItemWiseProductionList itemWiseProductionList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Productwise Production Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );

      const int rowsPerPage = 20;
      final totalPages =
          (itemWiseProductionList.itemWiseData.length / rowsPerPage).ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage > itemWiseProductionList.itemWiseData.length
            ? itemWiseProductionList.itemWiseData.length
            : start + rowsPerPage;
        final tableData = itemWiseProductionList.itemWiseData.sublist(
          start,
          end,
        );

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Table header
                  pw.TableRow(
                    children: [
                      pw.Text(
                        'Item Name',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Production Qty.',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Monthly Avg.',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Table data rows
                  for (var monthlyData in tableData)
                    pw.TableRow(
                      children: [
                        pw.Text(
                          monthlyData.itemName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.productionActual.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.production3Month.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        );
      }

      if (kIsWeb) {
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/itemwise_production_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemGroupProductionExcel(
    ItemGroupWiseProductionList itemGroupWiseProductionList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow(['Product Name', 'Production Qty.', 'Monthly Avg.']),
      );
      for (var itemData in itemGroupWiseProductionList.itemGroupWiseData) {
        sheet.appendRow(
          toCellRow([
            itemData.itemGroupName,
            itemData.productionActual.toStringAsFixed(2),
            itemData.production3Month.toStringAsFixed(2),
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('itemgroup_production_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/itemgroup_production_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemGroupProductionPDF(
    ItemGroupWiseProductionList itemGroupWiseProductionList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Product Group Wise Production Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );

      const int rowsPerPage = 20;
      final totalPages =
          (itemGroupWiseProductionList.itemGroupWiseData.length / rowsPerPage)
              .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage >
                itemGroupWiseProductionList.itemGroupWiseData.length
            ? itemGroupWiseProductionList.itemGroupWiseData.length
            : start + rowsPerPage;
        final tableData = itemGroupWiseProductionList.itemGroupWiseData.sublist(
          start,
          end,
        );

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Table header
                  pw.TableRow(
                    children: [
                      pw.Text(
                        'Group Name',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Production Qty.',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Monthly Avg.',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Table data rows
                  for (var monthlyData in tableData)
                    pw.TableRow(
                      children: [
                        pw.Text(
                          monthlyData.itemGroupName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.productionActual.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.production3Month.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        );
      }

      if (kIsWeb) {
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/item_groupwise_production_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemSubGroupProductionExcel(
    ItemSubGroupWiseProductionList itemSubGroupWiseProductionList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow(['Sub Group Name', 'Production Qty.', 'Monthly Avg.']),
      );
      for (var itemData
          in itemSubGroupWiseProductionList.itemSubGroupWiseData) {
        sheet.appendRow(
          toCellRow([
            itemData.itemSubGroupName,
            itemData.productionActual.toStringAsFixed(2),
            itemData.production3Month.toStringAsFixed(2),
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('itemsubgroup_production_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/itemsubgroup_production_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemSubGroupProductionPDF(
    ItemSubGroupWiseProductionList itemSubGroupWiseProductionList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Product Sub Group Wise Production Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );

      const int rowsPerPage = 20;
      final totalPages =
          (itemSubGroupWiseProductionList.itemSubGroupWiseData.length /
                  rowsPerPage)
              .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage >
                itemSubGroupWiseProductionList.itemSubGroupWiseData.length
            ? itemSubGroupWiseProductionList.itemSubGroupWiseData.length
            : start + rowsPerPage;
        final tableData = itemSubGroupWiseProductionList.itemSubGroupWiseData
            .sublist(start, end);

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Table header
                  pw.TableRow(
                    children: [
                      pw.Text(
                        'Sub Group Name',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Production Qty.',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Monthly Avg.',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Table data rows
                  for (var monthlyData in tableData)
                    pw.TableRow(
                      children: [
                        pw.Text(
                          monthlyData.itemSubGroupName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.productionActual.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.production3Month.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        );
      }

      if (kIsWeb) {
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File(
          '$storageDir/item_subgroupwise_production_report.pdf',
        );
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateBranchProductionExcel(
    BranchWiseProductionList branchWiseProductionList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow(['Branch Name', 'Production Qty.', 'Monthly Avg.']),
      );
      for (var itemData in branchWiseProductionList.branchWiseData) {
        sheet.appendRow(
          toCellRow([
            itemData.branchName,
            itemData.productionActual.toStringAsFixed(2),
            itemData.production3Month.toStringAsFixed(2),
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('branch_production_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/branch_production_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateBranchProductionPDF(
    BranchWiseProductionList branchWiseProductionList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Branch Production Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );

      const int rowsPerPage = 20;
      final totalPages =
          (branchWiseProductionList.branchWiseData.length / rowsPerPage).ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage > branchWiseProductionList.branchWiseData.length
            ? branchWiseProductionList.branchWiseData.length
            : start + rowsPerPage;
        final tableData = branchWiseProductionList.branchWiseData.sublist(
          start,
          end,
        );

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Table header
                  pw.TableRow(
                    children: [
                      pw.Text(
                        'Branch Name',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Production Qty.',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Monthly Avg.',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Table data rows
                  for (var monthlyData in tableData)
                    pw.TableRow(
                      children: [
                        pw.Text(
                          monthlyData.branchName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.productionActual.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.production3Month.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        );
      }

      if (kIsWeb) {
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/branch_production_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateOrderStatusProductionExcel(
    OrderStatusList orderStatusList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Status', 'Production Qty.', 'Percentage']));
      for (var itemData in orderStatusList.statusData) {
        sheet.appendRow(
          toCellRow([
            itemData.statusName,
            itemData.statusAmount.toStringAsFixed(2),
            itemData.statusPercentage.toString(),
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('Order_status_production_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/Order_status_production_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateOrderStatusProductionPDF(
    OrderStatusList orderStatusList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Order Status Production Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );

      const int rowsPerPage = 20;
      final totalPages = (orderStatusList.statusData.length / rowsPerPage)
          .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end = start + rowsPerPage > orderStatusList.statusData.length
            ? orderStatusList.statusData.length
            : start + rowsPerPage;
        final tableData = orderStatusList.statusData.sublist(start, end);

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Table header
                  pw.TableRow(
                    children: [
                      pw.Text(
                        'Status',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Production Qty.',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Percentage',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Table data rows
                  for (var monthlyData in tableData)
                    pw.TableRow(
                      children: [
                        pw.Text(
                          monthlyData.statusName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.statusAmount.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.statusPercentage.toString(),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        );
      }

      if (kIsWeb) {
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/orderstatus_production_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generatePlantProductionExcel(
    PlantWiseProductionList plantWiseProductionList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow(['Plant Name', 'Production Qty.', 'Monthly Avg.']),
      );
      for (var itemData in plantWiseProductionList.plantData) {
        sheet.appendRow(
          toCellRow([
            itemData.plantName,
            itemData.productionActual.toStringAsFixed(2),
            itemData.production3Month.toStringAsFixed(2),
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('plant_production_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/plant_production_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generatePlantProductionPDF(
    PlantWiseProductionList plantWiseProductionList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Plantwise Production Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );

      const int rowsPerPage = 20;
      final totalPages =
          (plantWiseProductionList.plantData.length / rowsPerPage).ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage > plantWiseProductionList.plantData.length
            ? plantWiseProductionList.plantData.length
            : start + rowsPerPage;
        final tableData = plantWiseProductionList.plantData.sublist(start, end);

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Table header
                  pw.TableRow(
                    children: [
                      pw.Text(
                        'Plant Name',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Production Qty.',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Monthly Avg.',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Table data rows
                  for (var monthlyData in tableData)
                    pw.TableRow(
                      children: [
                        pw.Text(
                          monthlyData.plantName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.productionActual.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.production3Month.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        );
      }

      if (kIsWeb) {
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/plantwise_production_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateUnitProductionExcel(
    UnitWiseProductionList unitWiseProductionList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow(['Unit Name', 'Production Qty.', 'Monthly Avg.']),
      );
      for (var itemData in unitWiseProductionList.unitData) {
        sheet.appendRow(
          toCellRow([
            itemData.unitName,
            itemData.productionActual.toStringAsFixed(2),
            itemData.production3Month.toStringAsFixed(2),
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('unit_production_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/unit_production_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateUnitProductionPDF(
    UnitWiseProductionList unitWiseProductionList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Unitwise Production Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );

      const int rowsPerPage = 20;
      final totalPages = (unitWiseProductionList.unitData.length / rowsPerPage)
          .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end = start + rowsPerPage > unitWiseProductionList.unitData.length
            ? unitWiseProductionList.unitData.length
            : start + rowsPerPage;
        final tableData = unitWiseProductionList.unitData.sublist(start, end);

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Table header
                  pw.TableRow(
                    children: [
                      pw.Text(
                        'Unit Name',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Production Qty.',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Monthly Avg.',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Table data rows
                  for (var monthlyData in tableData)
                    pw.TableRow(
                      children: [
                        pw.Text(
                          monthlyData.unitName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.productionActual.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.production3Month.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        );
      }

      if (kIsWeb) {
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/unitwise_production_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateShiftProductionExcel(
    ShiftWiseProductionList shiftWiseProductionList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow(['Shift Name', 'Production Qty.', 'Monthly Avg.']),
      );
      for (var itemData in shiftWiseProductionList.shiftData) {
        sheet.appendRow(
          toCellRow([
            itemData.shiftName,
            itemData.productionActual.toStringAsFixed(2),
            itemData.production3Month.toStringAsFixed(2),
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('shift_production_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/shift_production_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateShiftProductionPDF(
    ShiftWiseProductionList shiftWiseProductionList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Shiftwise Production Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );

      const int rowsPerPage = 20;
      final totalPages =
          (shiftWiseProductionList.shiftData.length / rowsPerPage).ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage > shiftWiseProductionList.shiftData.length
            ? shiftWiseProductionList.shiftData.length
            : start + rowsPerPage;
        final tableData = shiftWiseProductionList.shiftData.sublist(start, end);

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Table header
                  pw.TableRow(
                    children: [
                      pw.Text(
                        'Shift Name',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Production Qty.',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Monthly Avg.',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Table data rows
                  for (var monthlyData in tableData)
                    pw.TableRow(
                      children: [
                        pw.Text(
                          monthlyData.shiftName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.productionActual.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.production3Month.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        );
      }

      if (kIsWeb) {
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/shiftwise_production_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  void initState() {
    super.initState();
    LoadDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    String formattedFiscalYearStartDate = DateFormat(
      'dd/MM/yy',
    ).format(fiscalYearStartDate!);
    String formattedQuarterStartDate = DateFormat(
      'dd/MM/yy',
    ).format(currentQuarterFromDate!);
    String formattedQuarterLastDate = DateFormat(
      'dd/MM/yy',
    ).format(currentQuarterToDate!);
    String formattedDateNow = DateFormat('dd/MM/yy').format(currentDate!);
    String formattedDateFirstOfLastMonth = DateFormat(
      'dd/MM/yy',
    ).format(DateTime(currentDate!.year, currentDate!.month - 1, 1));
    String formattedDateLastOfLastMonth = DateFormat(
      'dd/MM/yy',
    ).format(DateTime(currentDate!.year, currentDate!.month, 0));
    String formattedDateFirstOfThisMonth = DateFormat(
      'dd/MM/yy',
    ).format(DateTime(currentDate!.year, currentDate!.month, 1));
    return chartDataLoaded == true
        ? SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 15),
                        touchedMonthGoals == true
                            ? Text(
                                "$formattedDateFirstOfLastMonth - $formattedDateLastOfLastMonth",
                              )
                            : touchedQuarterGoals == true
                            ? Text(
                                "$formattedQuarterStartDate - $formattedQuarterLastDate",
                              )
                            : touchedYTDGoals == true
                            ? Text(
                                "$formattedFiscalYearStartDate - $formattedDateNow",
                              )
                            : Text(
                                "$formattedDateFirstOfThisMonth - $formattedDateNow",
                              ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            showPopupMenu();
                          },
                          icon: const Icon(Icons.filter_alt_outlined),
                        ),
                        const SizedBox(width: 5),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Production Order Analysis",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateMonthlyProductionExcel(monthData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateMonthlyProductionPDF(monthData);
                                  });
                                },
                                child: const Text("Download PDF"),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: screenHeight / 2.67,
                  child: Stack(
                    children: [
                      Center(
                        child: CircularPercentIndicator(
                          arcType: ArcType.HALF,
                          radius: 120.0,
                          lineWidth: 50.0,
                          animation: true,
                          percent: CurrentMonthSalesPercentage / 100,
                          center: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 70.0),
                                child: Text(
                                  CurrentMonthSalesPercentageStr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20.0,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                              Text(
                                CurrentMonthSalesStr,
                                style: const TextStyle(fontSize: 14.0),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "${getMonthName(currentDate!.month)} Goal - $CurrentMonthTargetStr",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.0,
                                ),
                              ),
                            ],
                          ),
                          circularStrokeCap: CircularStrokeCap.butt,
                          progressColor: Colors.red,
                          arcBackgroundColor: Colors.grey.shade200,
                        ),
                      ),
                      Positioned.fill(
                        top: screenHeight / 4.5,
                        left: screenHeight / 35,
                        child: SizedBox(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 4.0,
                                  right: 4.0,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {});
                                  },
                                  child: CircularPercentIndicator(
                                    arcType: ArcType.HALF,
                                    radius: 55.0,
                                    lineWidth: 20.0,
                                    animation: true,
                                    percent: LastMonthPercentage / 100,
                                    center: Column(
                                      children: [
                                        const SizedBox(height: 30),
                                        Text(
                                          LastMonthPercentageStr,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: touchedMonthGoals
                                                ? 13.0
                                                : 12.0,
                                            color: touchedMonthGoals
                                                ? Colors.cyan
                                                : Colors.black,
                                          ),
                                        ),
                                        Text(
                                          LastMonthSalesStr,
                                          style: TextStyle(
                                            fontSize: touchedMonthGoals
                                                ? 11.0
                                                : 10.0,
                                            color: touchedMonthGoals
                                                ? Colors.cyan
                                                : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Center(
                                          child: Text(
                                            "${getMonthName(currentDate!.month - 1)} Production \n($LastMonthTargetStr)",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: touchedMonthGoals
                                                  ? 11.0
                                                  : 10.0,
                                              color: touchedMonthGoals
                                                  ? Colors.cyan
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    curve: Curves.linear,
                                    circularStrokeCap: CircularStrokeCap.butt,
                                    progressColor: Colors.red,
                                    arcBackgroundColor: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {});
                                  },
                                  child: CircularPercentIndicator(
                                    arcType: ArcType.HALF,
                                    radius: 55.0,
                                    lineWidth: 20.0,
                                    animation: true,
                                    percent: CurrentQtrPercentage / 100,
                                    center: Column(
                                      children: [
                                        const SizedBox(height: 30),
                                        Text(
                                          CurrentQtrPercentageStr,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: touchedQuarterGoals
                                                ? 13.0
                                                : 12.0,
                                            color: touchedQuarterGoals
                                                ? Colors.cyan
                                                : Colors.black,
                                          ),
                                        ),
                                        Text(
                                          CurrentQtrSalesStr,
                                          style: TextStyle(
                                            fontSize: touchedQuarterGoals
                                                ? 11.0
                                                : 10.0,
                                            color: touchedQuarterGoals
                                                ? Colors.cyan
                                                : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "Q$currentQuarter Production \n($CurrentQtrTargetStr)",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: touchedQuarterGoals
                                                ? 11.0
                                                : 10.0,
                                            color: touchedQuarterGoals
                                                ? Colors.cyan
                                                : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    curve: Curves.linear,
                                    circularStrokeCap: CircularStrokeCap.butt,
                                    progressColor: Colors.orange,
                                    arcBackgroundColor: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {});
                                  },
                                  child: CircularPercentIndicator(
                                    arcType: ArcType.HALF,
                                    radius: 55.0,
                                    lineWidth: 20.0,
                                    animation: true,
                                    percent: YtdPercentage / 100,
                                    center: Column(
                                      children: [
                                        const SizedBox(height: 30),
                                        Text(
                                          YtdPercentageStr,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: touchedYTDGoals
                                                ? 13.0
                                                : 12.0,
                                            color: touchedYTDGoals
                                                ? Colors.cyan
                                                : Colors.black,
                                          ),
                                        ),
                                        Text(
                                          YtdSalesStr,
                                          style: TextStyle(
                                            fontSize: touchedYTDGoals
                                                ? 11.0
                                                : 10.0,
                                            color: touchedYTDGoals
                                                ? Colors.cyan
                                                : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "YTD \n($YtdTargetStr)",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: touchedYTDGoals
                                                ? 11.0
                                                : 10.0,
                                            color: touchedYTDGoals
                                                ? Colors.cyan
                                                : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    curve: Curves.linear,
                                    circularStrokeCap: CircularStrokeCap.butt,
                                    progressColor: Colors.green,
                                    arcBackgroundColor: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Tooltip(
                        preferBelow: false,
                        richMessage: WidgetSpan(
                          child: Column(
                            children: [
                              const Text(
                                "Quarter 1 Analysis",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Column(
                                children: [
                                  Text("Target : $Q1TargetStr"),
                                  Text("Achieved : $Q1SalesStr"),
                                  Text("Difference : $Q1DiffStr"),
                                  Text("Percentage : $Q1PercentageStr"),
                                  Text("Monthly Avg. : $Q1AverageStr"),
                                ],
                              ),
                            ],
                          ),
                        ),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          color: Colors.white,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(4),
                          ),
                        ),
                        showDuration: const Duration(seconds: 7),
                        triggerMode: TooltipTriggerMode.tap,
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xff6CCC3F,
                                ).withValues(alpha: 0.5),
                                border: const Border(
                                  left: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                  top: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                  bottom: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  "Q1",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                  top: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                  bottom: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Q1PercentageStr != ""
                                    ? Text(Q1PercentageStr)
                                    : const Text("      "),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tooltip(
                        preferBelow: false,
                        richMessage: WidgetSpan(
                          child: Column(
                            children: [
                              const Text(
                                "Quarter 2 Analysis",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Column(
                                children: [
                                  Text("Target : $Q2TargetStr"),
                                  Text("Achieved : $Q2SalesStr"),
                                  Text("Difference : $Q2DiffStr"),
                                  Text("Percentage : $Q2PercentageStr"),
                                  Text("Monthly Avg. : $Q2AverageStr"),
                                ],
                              ),
                            ],
                          ),
                        ),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset: const Offset(
                                0,
                                3,
                              ), // changes position of shadow
                            ),
                          ],
                          color: Colors.white,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(4),
                          ),
                        ),
                        triggerMode: TooltipTriggerMode.tap,
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFF49136,
                                ).withValues(alpha: 0.5),
                                border: const Border(
                                  left: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                  top: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                  bottom: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  "Q2",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                  top: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                  bottom: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Q2PercentageStr != ""
                                    ? Text(Q2PercentageStr)
                                    : const Text("      "),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tooltip(
                        preferBelow: false,
                        richMessage: WidgetSpan(
                          child: Column(
                            children: [
                              const Text(
                                "Quarter 3 Analysis",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Column(
                                children: [
                                  Text("Target : $Q3TargetStr"),
                                  Text("Achieved : $Q3SalesStr"),
                                  Text("Difference : $Q3DiffStr"),
                                  Text("Percentage : $Q3PercentageStr"),
                                  Text("Monthly Avg. : $Q3AverageStr"),
                                ],
                              ),
                            ],
                          ),
                        ),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset: const Offset(
                                0,
                                3,
                              ), // changes position of shadow
                            ),
                          ],
                          color: Colors.white,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(4),
                          ),
                        ),
                        triggerMode: TooltipTriggerMode.tap,
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFE92729,
                                ).withValues(alpha: 0.5),
                                border: const Border(
                                  left: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                  top: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                  bottom: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  "Q3",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                  top: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                  bottom: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Q3PercentageStr != ""
                                    ? Text(Q3PercentageStr)
                                    : const Text("      "),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tooltip(
                        preferBelow: false,
                        richMessage: WidgetSpan(
                          child: Column(
                            children: [
                              const Text(
                                "Quarter 4 Analysis",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Column(
                                children: [
                                  Text("Target : $Q4TargetStr"),
                                  Text("Achieved : $Q4SalesStr"),
                                  Text("Difference : $Q4DiffStr"),
                                  Text("Percentage : $Q4PercentageStr"),
                                  Text("Monthly Avg. : $Q4AverageStr"),
                                ],
                              ),
                            ],
                          ),
                        ),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset: const Offset(
                                0,
                                3,
                              ), // changes position of shadow
                            ),
                          ],
                          color: Colors.white,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(4),
                          ),
                        ),
                        triggerMode: TooltipTriggerMode.tap,
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF6CCC3F,
                                ).withValues(alpha: 0.5),
                                border: const Border(
                                  left: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                  top: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                  bottom: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  "Q4",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                  right: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                  top: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                  bottom: BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Q4PercentageStr != ""
                                    ? Text(Q4PercentageStr)
                                    : const Text("      "),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Month wise\nProduction Analysis",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFF97D7F3),
                        ),
                        const SizedBox(width: 5),
                        const Text("Actual", style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFFFF9F47),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "3 Months Avg.",
                          style: TextStyle(fontSize: 12),
                        ),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateMonthlyProductionExcel(monthData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateMonthlyProductionPDF(monthData);
                                  });
                                },
                                child: const Text("Download PDF"),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _monthWiseProductionAnalysis(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Item-wise\nProduction Orders",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFF97D7F3),
                        ),
                        const SizedBox(width: 5),
                        const Text("Actual", style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFFFF9F47),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "3 Months Avg.",
                          style: TextStyle(fontSize: 12),
                        ),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateItemProductionExcel(itemWiseData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateItemProductionPDF(itemWiseData);
                                  });
                                },
                                child: const Text("Download PDF"),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _itemWiseProductionOrders(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Branch-wise\nProduction Orders",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFF97D7F3),
                        ),
                        const SizedBox(width: 5),
                        const Text("Actual", style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFFFF9F47),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "3 Months Avg.",
                          style: TextStyle(fontSize: 12),
                        ),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateBranchProductionExcel(
                                      branchWiseData,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateBranchProductionPDF(branchWiseData);
                                  });
                                },
                                child: const Text("Download PDF"),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _branchWiseProductionOrders(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Item Group Wise Analysis",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateItemGroupProductionExcel(
                                      itemGroupWiseData,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateItemGroupProductionPDF(
                                      itemGroupWiseData,
                                    );
                                  });
                                },
                                child: const Text("Download PDF"),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _itemGroupWiseAnalysis(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Item Sub Group Wise Analysis",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateItemSubGroupProductionExcel(
                                      itemSubGroupWiseData,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateItemSubGroupProductionPDF(
                                      itemSubGroupWiseData,
                                    );
                                  });
                                },
                                child: const Text("Download PDF"),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _itemSubGroupWiseAnalysis(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Order Status Analysis",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateOrderStatusProductionExcel(
                                      statusData,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateOrderStatusProductionPDF(
                                      statusData,
                                    );
                                  });
                                },
                                child: const Text("Download PDF"),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        height: 250,
                        width: 100,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback:
                                  (FlTouchEvent event, pieTouchResponse) {},
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 1,
                            centerSpaceRadius: 0,
                            startDegreeOffset: 180,
                            sections: showingSections(),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // for (final categoryData in receivablesCategoryList.categoryData)
                                Column(
                                  children: [
                                    Container(
                                      height: 8,
                                      width: 16,
                                      color: const Color(0xFFFF9F47),
                                      // color: getCategoryColor(categoryData.categoryId),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 8,
                                      width: 16,
                                      color: const Color(0xFF97D7F3),
                                      // color: getCategoryColor(categoryData.categoryId),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 8,
                                      width: 16,
                                      color: const Color(0xFF8F8F8F),
                                      // color: getCategoryColor(categoryData.categoryId),
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // for (final categoryData
                              // in receivablesCategoryList.categoryData)
                              Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Text(
                                  "Closed",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Text(
                                  "Open",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Text(
                                  "Cancelled",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Plant wise Analysis",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFF97D7F3),
                        ),
                        const SizedBox(width: 5),
                        const Text("Actual", style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFFFF9F47),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "3 Months Avg.",
                          style: TextStyle(fontSize: 12),
                        ),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generatePlantProductionExcel(plantWiseData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generatePlantProductionPDF(plantWiseData);
                                  });
                                },
                                child: const Text("Download PDF"),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _plantWiseAnalysis(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Unit wise Analysis",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFF97D7F3),
                        ),
                        const SizedBox(width: 5),
                        const Text("Actual", style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFFFF9F47),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "3 Months Avg.",
                          style: TextStyle(fontSize: 12),
                        ),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateUnitProductionExcel(unitWiseData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateUnitProductionPDF(unitWiseData);
                                  });
                                },
                                child: const Text("Download PDF"),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _unitWiseAnalysis(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Shift wise Analysis",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFF97D7F3),
                        ),
                        const SizedBox(width: 5),
                        const Text("Actual", style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFFFF9F47),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "3 Months Avg.",
                          style: TextStyle(fontSize: 12),
                        ),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateShiftProductionExcel(shiftWiseData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateShiftProductionPDF(shiftWiseData);
                                  });
                                },
                                child: const Text("Download PDF"),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _shiftWiseAnalysis(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  showPopupMenu() {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(25.0, 200.0, 0.0, 0.0),
      elevation: 8.0,
      items: [
        const PopupMenuItem<String>(value: '1', child: Text('Remove Filter?')),
      ],
    ).then((value) {
      if (value == '1') {
        setState(() {
          loadDataFuture = removeFilter();
        });
      }
    });
  }

  Widget _monthWiseProductionAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double barChartWidth = 0.0;
    monthData.monthlyData.length > 6
        ? barChartWidth = screenWidth * 1.4
        : barChartWidth = screenWidth;
    int len = monthData.monthlyData.length;
    double maxPurchaseAmount = len > 0
        ? monthData.monthlyData
              .map(
                (data) => data.production > data.target
                    ? data.production
                    : data.target,
              )
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: barChartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(maxPurchaseAmount),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitles,
                axisNameSize: 20,
              ),
            ),
            gridData: FlGridData(
              show: true,
              checkToShowHorizontalLine: (value) => value % 10 == 0,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.grey.shade300, strokeWidth: 1),
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade400, width: 0.7),
                top: BorderSide(color: Colors.grey.shade400, width: 0.7),
              ),
            ),
            barGroups: _monthWiseProductionAnalysisChartData(
              monthData.monthlyData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    touchedMonth = monthData
                        .monthlyData[barTouchResponse.spot!.spot.x.toInt()]
                        .monthName;
                    List months = [
                      'Jan',
                      'Feb',
                      'Mar',
                      'Apr',
                      'May',
                      'Jun',
                      'Jul',
                      'Aug',
                      'Sep',
                      'Oct',
                      'Nov',
                      'Dec',
                    ];
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedMonthIndex = (touchedMonthIndex == 0
                          ? months.indexOf(touchedMonth.substring(0, 3)) + 1
                          : 0);
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedItemCode,
                        touchedBranchName,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedPlant,
                        touchedUnit,
                        touchedShift,
                      );
                    }
                  });
                }
              },
              touchTooltipData: BarTouchTooltipData(
                maxContentWidth: 200,
                tooltipBorder: const BorderSide(
                  width: 2.0,
                  color: Colors.black12,
                  style: BorderStyle.none,
                ),
                getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                  return BarTooltipItem(
                    '${monthData.monthlyData[grpIndex].monthName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Achievement : ${formatAmount(monthData.monthlyData[grpIndex].production)} L\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Target : ${(rodData.backDrawRodData.toY / 100000).toStringAsFixed(2)} L\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    textAlign: TextAlign.start,
                  );
                },
                getTooltipColor: (group) => Colors.white,
                fitInsideVertically: true,
                fitInsideHorizontally: true,
              ),
              handleBuiltInTouches: true,
              touchExtraThreshold: const EdgeInsets.all(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemWiseProductionOrders() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = itemWiseData.itemWiseData.length;
    if (itemWiseData.itemWiseData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getItemMaxValue(itemWiseData),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesItemWiseProductionOrders,
                axisNameSize: 20,
              ),
            ),
            gridData: FlGridData(
              show: true,
              checkToShowHorizontalLine: (value) => value % 10 == 0,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.grey.shade300, strokeWidth: 1),
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade400, width: 0.7),
                top: BorderSide(color: Colors.grey.shade400, width: 0.7),
              ),
            ),
            barGroups: _itemWiseProductionOrdersChartData(
              itemWiseData.itemWiseData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedItemCode = touchedItemCode == ""
                          ? itemWiseData
                                .itemWiseData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .itemName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedItemCode,
                        touchedBranchName,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedPlant,
                        touchedUnit,
                        touchedShift,
                      );
                    }
                  });
                }
              },
              touchTooltipData: BarTouchTooltipData(
                maxContentWidth: 200,
                tooltipBorder: const BorderSide(
                  width: 2.0,
                  color: Colors.black12,
                  style: BorderStyle.none,
                ),
                getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                  return BarTooltipItem(
                    '${itemWiseData.itemWiseData[grpIndex].itemName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Production Qty: ${formatAmount(itemWiseData.itemWiseData[grpIndex].productionActual)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Monthly Avg. : ${formatAmount(itemWiseData.itemWiseData[grpIndex].production3Month)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    textAlign: TextAlign.start,
                  );
                },
                getTooltipColor: (group) => Colors.white,
                fitInsideVertically: true,
                fitInsideHorizontally: true,
              ),
              handleBuiltInTouches: true,
              touchExtraThreshold: const EdgeInsets.all(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _branchWiseProductionOrders() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = branchWiseData.branchWiseData.length;
    if (branchWiseData.branchWiseData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxValue = len > 0
        ? branchWiseData.branchWiseData
              .map(
                (data) => data.productionActual > data.production3Month
                    ? data.productionActual
                    : data.production3Month,
              )
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(maxValue),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesBranchWiseProductionOrders,
                axisNameSize: 20,
              ),
            ),
            gridData: FlGridData(
              show: true,
              checkToShowHorizontalLine: (value) => value % 10 == 0,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.grey.shade300, strokeWidth: 1),
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade400, width: 0.7),
                top: BorderSide(color: Colors.grey.shade400, width: 0.7),
              ),
            ),
            barGroups: _branchWiseProductionOrdersChartData(
              branchWiseData.branchWiseData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedBranchName = touchedBranchName == ""
                          ? branchWiseData
                                .branchWiseData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .branchName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedItemCode,
                        touchedBranchName,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedPlant,
                        touchedUnit,
                        touchedShift,
                      );
                    }
                  });
                }
              },
              touchTooltipData: BarTouchTooltipData(
                maxContentWidth: 200,
                tooltipBorder: const BorderSide(
                  width: 2.0,
                  color: Colors.black12,
                  style: BorderStyle.none,
                ),
                getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                  return BarTooltipItem(
                    '${branchWiseData.branchWiseData[grpIndex].branchName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Production Qty: ${formatAmount(branchWiseData.branchWiseData[grpIndex].productionActual)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Monthly Avg. : ${formatAmount(branchWiseData.branchWiseData[grpIndex].production3Month)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    textAlign: TextAlign.start,
                  );
                },
                getTooltipColor: (group) => Colors.white,
                fitInsideVertically: true,
                fitInsideHorizontally: true,
              ),
              handleBuiltInTouches: true,
              touchExtraThreshold: const EdgeInsets.all(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemGroupWiseAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = itemGroupWiseData.itemGroupWiseData.length;
    if (itemGroupWiseData.itemGroupWiseData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxValue = len > 0
        ? itemGroupWiseData.itemGroupWiseData
              .map(
                (data) => data.productionActual > data.production3Month
                    ? data.productionActual
                    : data.production3Month,
              )
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(maxValue),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesItemGroupWiseAnalysis,
                axisNameSize: 20,
              ),
            ),
            gridData: FlGridData(
              show: true,
              checkToShowHorizontalLine: (value) => value % 10 == 0,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.grey.shade300, strokeWidth: 1),
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade400, width: 0.7),
                top: BorderSide(color: Colors.grey.shade400, width: 0.7),
              ),
            ),
            barGroups: _itemGroupWiseAnalysisChartData(
              itemGroupWiseData.itemGroupWiseData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedItemGroup = touchedItemGroup == ""
                          ? itemGroupWiseData
                                .itemGroupWiseData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .itemGroupName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedItemCode,
                        touchedBranchName,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedPlant,
                        touchedUnit,
                        touchedShift,
                      );
                    }
                  });
                }
              },
              touchTooltipData: BarTouchTooltipData(
                maxContentWidth: 200,
                tooltipBorder: const BorderSide(
                  width: 2.0,
                  color: Colors.black12,
                  style: BorderStyle.none,
                ),
                getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                  return BarTooltipItem(
                    '${itemGroupWiseData.itemGroupWiseData[grpIndex].itemGroupName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Production Qty: ${formatAmount(itemGroupWiseData.itemGroupWiseData[grpIndex].productionActual)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Monthly Avg. : ${formatAmount(itemGroupWiseData.itemGroupWiseData[grpIndex].production3Month)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    textAlign: TextAlign.start,
                  );
                },
                getTooltipColor: (group) => Colors.white,
                fitInsideVertically: true,
                fitInsideHorizontally: true,
              ),
              handleBuiltInTouches: true,
              touchExtraThreshold: const EdgeInsets.all(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemSubGroupWiseAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = itemSubGroupWiseData.itemSubGroupWiseData.length;
    if (itemSubGroupWiseData.itemSubGroupWiseData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxValue = len > 0
        ? itemSubGroupWiseData.itemSubGroupWiseData
              .map(
                (data) => data.productionActual > data.production3Month
                    ? data.productionActual
                    : data.production3Month,
              )
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(maxValue),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesItemSubGroupWiseAnalysis,
                axisNameSize: 20,
              ),
            ),
            gridData: FlGridData(
              show: true,
              checkToShowHorizontalLine: (value) => value % 10 == 0,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.grey.shade300, strokeWidth: 1),
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade400, width: 0.7),
                top: BorderSide(color: Colors.grey.shade400, width: 0.7),
              ),
            ),
            barGroups: _itemSubGroupWiseAnalysisChartData(
              itemSubGroupWiseData.itemSubGroupWiseData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedItemSubGroup = touchedItemSubGroup == ""
                          ? itemSubGroupWiseData
                                .itemSubGroupWiseData[barTouchResponse
                                    .spot!
                                    .spot
                                    .x
                                    .toInt()]
                                .itemSubGroupName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedItemCode,
                        touchedBranchName,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedPlant,
                        touchedUnit,
                        touchedShift,
                      );
                    }
                  });
                }
              },
              touchTooltipData: BarTouchTooltipData(
                maxContentWidth: 200,
                tooltipBorder: const BorderSide(
                  width: 2.0,
                  color: Colors.black12,
                  style: BorderStyle.none,
                ),
                getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                  return BarTooltipItem(
                    '${itemSubGroupWiseData.itemSubGroupWiseData[grpIndex].itemSubGroupName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Production Qty: ${formatAmount(itemSubGroupWiseData.itemSubGroupWiseData[grpIndex].productionActual)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "3 Month : ${formatAmount(itemSubGroupWiseData.itemSubGroupWiseData[grpIndex].production3Month)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    textAlign: TextAlign.start,
                  );
                },
                getTooltipColor: (group) => Colors.white,
                fitInsideVertically: true,
                fitInsideHorizontally: true,
              ),
              handleBuiltInTouches: true,
              touchExtraThreshold: const EdgeInsets.all(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _plantWiseAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = plantWiseData.plantData.length;
    if (plantWiseData.plantData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxValue = len > 0
        ? plantWiseData.plantData
              .map(
                (data) => data.productionActual > data.production3Month
                    ? data.productionActual
                    : data.production3Month,
              )
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(maxValue),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesPlantWiseAnalysis,
                axisNameSize: 20,
              ),
            ),
            gridData: FlGridData(
              show: true,
              checkToShowHorizontalLine: (value) => value % 10 == 0,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.grey.shade300, strokeWidth: 1),
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade400, width: 0.7),
                top: BorderSide(color: Colors.grey.shade400, width: 0.7),
              ),
            ),
            barGroups: _plantWiseAnalysisChartData(plantWiseData.plantData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedPlant = touchedPlant == ""
                          ? plantWiseData
                                .plantData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .plantName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedItemCode,
                        touchedBranchName,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedPlant,
                        touchedUnit,
                        touchedShift,
                      );
                    }
                  });
                }
              },
              touchTooltipData: BarTouchTooltipData(
                maxContentWidth: 200,
                tooltipBorder: const BorderSide(
                  width: 2.0,
                  color: Colors.black12,
                  style: BorderStyle.none,
                ),
                getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                  return BarTooltipItem(
                    '${plantWiseData.plantData[grpIndex].plantName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Production Qty : ${formatAmount(plantWiseData.plantData[grpIndex].productionActual)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "3 Month Avg. : ${formatAmount(plantWiseData.plantData[grpIndex].production3Month)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    textAlign: TextAlign.start,
                  );
                },
                getTooltipColor: (group) => Colors.white,
                fitInsideVertically: true,
                fitInsideHorizontally: true,
              ),
              handleBuiltInTouches: true,
              touchExtraThreshold: const EdgeInsets.all(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _unitWiseAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = unitWiseData.unitData.length;
    if (unitWiseData.unitData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxValue = len > 0
        ? unitWiseData.unitData
              .map(
                (data) => data.productionActual > data.production3Month
                    ? data.productionActual
                    : data.production3Month,
              )
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(maxValue),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesUnitWiseAnalysis,
                axisNameSize: 20,
              ),
            ),
            gridData: FlGridData(
              show: true,
              checkToShowHorizontalLine: (value) => value % 10 == 0,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.grey.shade300, strokeWidth: 1),
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade400, width: 0.7),
                top: BorderSide(color: Colors.grey.shade400, width: 0.7),
              ),
            ),
            barGroups: _unitWiseAnalysisChartData(unitWiseData.unitData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedUnit = touchedUnit == ""
                          ? unitWiseData
                                .unitData[barTouchResponse.spot!.spot.x.toInt()]
                                .unitName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedItemCode,
                        touchedBranchName,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedPlant,
                        touchedUnit,
                        touchedShift,
                      );
                    }
                  });
                }
              },
              touchTooltipData: BarTouchTooltipData(
                maxContentWidth: 200,
                tooltipBorder: const BorderSide(
                  width: 2.0,
                  color: Colors.black12,
                  style: BorderStyle.none,
                ),
                getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                  return BarTooltipItem(
                    '${unitWiseData.unitData[grpIndex].unitName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Production Qty : ${formatAmount(unitWiseData.unitData[grpIndex].productionActual)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "3 Month Avg. : ${formatAmount(unitWiseData.unitData[grpIndex].production3Month)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    textAlign: TextAlign.start,
                  );
                },
                getTooltipColor: (group) => Colors.white,
                fitInsideVertically: true,
                fitInsideHorizontally: true,
              ),
              handleBuiltInTouches: true,
              touchExtraThreshold: const EdgeInsets.all(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _shiftWiseAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = shiftWiseData.shiftData.length;
    if (shiftWiseData.shiftData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxValue = len > 0
        ? shiftWiseData.shiftData
              .map(
                (data) => data.productionActual > data.production3Month
                    ? data.productionActual
                    : data.production3Month,
              )
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(maxValue),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesShiftWiseAnalysis,
                axisNameSize: 20,
              ),
            ),
            gridData: FlGridData(
              show: true,
              checkToShowHorizontalLine: (value) => value % 10 == 0,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.grey.shade300, strokeWidth: 1),
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade400, width: 0.7),
                top: BorderSide(color: Colors.grey.shade400, width: 0.7),
              ),
            ),
            barGroups: _shiftWiseAnalysisChartData(shiftWiseData.shiftData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedShift = touchedShift == ""
                          ? shiftWiseData
                                .shiftData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .shiftName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedItemCode,
                        touchedBranchName,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedPlant,
                        touchedUnit,
                        touchedShift,
                      );
                    }
                  });
                }
              },
              touchTooltipData: BarTouchTooltipData(
                maxContentWidth: 200,
                tooltipBorder: const BorderSide(
                  width: 2.0,
                  color: Colors.black12,
                  style: BorderStyle.none,
                ),
                getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                  return BarTooltipItem(
                    '${shiftWiseData.shiftData[grpIndex].shiftName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Production Qty :${formatAmount(shiftWiseData.shiftData[grpIndex].productionActual)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "3 Month Avg. : ${formatAmount(shiftWiseData.shiftData[grpIndex].production3Month)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    textAlign: TextAlign.start,
                  );
                },
                getTooltipColor: (group) => Colors.white,
                fitInsideVertically: true,
                fitInsideHorizontally: true,
              ),
              handleBuiltInTouches: true,
              touchExtraThreshold: const EdgeInsets.all(10),
            ),
          ),
        ),
      ),
    );
  }
}
