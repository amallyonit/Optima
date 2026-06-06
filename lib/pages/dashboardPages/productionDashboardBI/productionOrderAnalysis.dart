// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/classes/leads.dart';
import '../../../notificationService.dart';
import '../ReportService.dart';
import '../dashboard_card_ui.dart';

final reportService = ReportService();

class ProductionOrderAnalysis extends StatefulWidget {
  const ProductionOrderAnalysis({super.key});

  @override
  State<ProductionOrderAnalysis> createState() =>
      _ProductionOrderAnalysisState();
}

class _ProductionOrderAnalysisState extends State<ProductionOrderAnalysis> {
  late String formattedFiscalYearStartDate;
  late String formattedQuarterStartDate;
  late String formattedQuarterLastDate;
  late String formattedDateNow;
  late String formattedDateFirstOfLastMonth;
  late String formattedDateLastOfLastMonth;
  late String formattedDateFirstOfThisMonth;

  double monthWiseMaxY = 0;
  double itemWiseMaxY = 0;
  double branchWiseMaxY = 0;
  double itemGroupMaxY = 0;
  double itemSubGroupMaxY = 0;
  double plantWiseMaxY = 0;
  double unitWiseMaxY = 0;
  double shiftWiseMaxY = 0;
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
  ItemWiseProductionList itemWiseData = ItemWiseProductionList(
    itemWiseData: [],
  );
  BranchWiseProductionList branchWiseData = BranchWiseProductionList(
    branchWiseData: [],
  );
  ItemGroupWiseProductionList itemGroupWiseData = ItemGroupWiseProductionList(
    itemGroupWiseData: [],
  );
  ItemSubGroupWiseProductionList itemSubGroupWiseData =
      ItemSubGroupWiseProductionList(itemSubGroupWiseData: []);
  PlantWiseProductionList plantWiseData = PlantWiseProductionList(
    plantData: [],
  );
  UnitWiseProductionList unitWiseData = UnitWiseProductionList(unitData: []);
  ShiftWiseProductionList shiftWiseData = ShiftWiseProductionList(
    shiftData: [],
  );
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
  bool touchedMonthGoals = false;
  bool touchedQuarterGoals = false;
  bool touchedYTDGoals = false;
  int touchedIndex = -1;

  void prepareFormattedDates() {
    final formatter = DateFormat('dd/MM/yy');

    formattedFiscalYearStartDate = fiscalYearStartDate != null
        ? formatter.format(fiscalYearStartDate!)
        : '';

    formattedQuarterStartDate = currentQuarterFromDate != null
        ? formatter.format(currentQuarterFromDate!)
        : '';

    formattedQuarterLastDate = currentQuarterToDate != null
        ? formatter.format(currentQuarterToDate!)
        : '';

    formattedDateNow = currentDate != null
        ? formatter.format(currentDate!)
        : '';

    formattedDateFirstOfLastMonth = lastMonthFromDate != null
        ? formatter.format(lastMonthFromDate!)
        : '';

    formattedDateLastOfLastMonth = lastMonthToDate != null
        ? formatter.format(lastMonthToDate!)
        : '';

    formattedDateFirstOfThisMonth = currentMonthFromDate != null
        ? formatter.format(currentMonthFromDate!)
        : '';
  }

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

  Color getCategoryColor(int categoryId) {
    switch (categoryId) {
      case 0:
        return const Color(0xFF6CCC3F);
      case 1:
        return const Color(0xFF97D7F3);
      case 2:
        return const Color.fromARGB(255, 208, 19, 22);
      default:
        return const Color.fromARGB(255, 208, 19, 22);
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

  void prepareMaxValues() {
    /// MONTH WISE
    monthWiseMaxY = monthData.monthlyData.isNotEmpty
        ? monthData.monthlyData
              .map((e) => e.production > e.target ? e.production : e.target)
              .reduce((a, b) => a > b ? a : b)
        : 0;

    /// ITEM WISE
    itemWiseMaxY = itemWiseData.itemWiseData.isNotEmpty
        ? itemWiseData.itemWiseData
              .map(
                (e) => e.productionActual > e.production3Month
                    ? e.productionActual
                    : e.production3Month,
              )
              .reduce((a, b) => a > b ? a : b)
        : 0;

    /// BRANCH WISE
    branchWiseMaxY = branchWiseData.branchWiseData.isNotEmpty
        ? branchWiseData.branchWiseData
              .map(
                (e) => e.productionActual > e.production3Month
                    ? e.productionActual
                    : e.production3Month,
              )
              .reduce((a, b) => a > b ? a : b)
        : 0;

    /// ITEM GROUP WISE
    itemGroupMaxY = itemGroupWiseData.itemGroupWiseData.isNotEmpty
        ? itemGroupWiseData.itemGroupWiseData
              .map(
                (e) => e.productionActual > e.production3Month
                    ? e.productionActual
                    : e.production3Month,
              )
              .reduce((a, b) => a > b ? a : b)
        : 0;

    /// ITEM SUB GROUP WISE
    itemSubGroupMaxY = itemSubGroupWiseData.itemSubGroupWiseData.isNotEmpty
        ? itemSubGroupWiseData.itemSubGroupWiseData
              .map(
                (e) => e.productionActual > e.production3Month
                    ? e.productionActual
                    : e.production3Month,
              )
              .reduce((a, b) => a > b ? a : b)
        : 0;

    /// PLANT WISE
    plantWiseMaxY = plantWiseData.plantData.isNotEmpty
        ? plantWiseData.plantData
              .map(
                (e) => e.productionActual > e.production3Month
                    ? e.productionActual
                    : e.production3Month,
              )
              .reduce((a, b) => a > b ? a : b)
        : 0;

    /// UNIT WISE
    unitWiseMaxY = unitWiseData.unitData.isNotEmpty
        ? unitWiseData.unitData
              .map(
                (e) => e.productionActual > e.production3Month
                    ? e.productionActual
                    : e.production3Month,
              )
              .reduce((a, b) => a > b ? a : b)
        : 0;

    /// SHIFT WISE
    shiftWiseMaxY = shiftWiseData.shiftData.isNotEmpty
        ? shiftWiseData.shiftData
              .map(
                (e) => e.productionActual > e.production3Month
                    ? e.productionActual
                    : e.production3Month,
              )
              .reduce((a, b) => a > b ? a : b)
        : 0;
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
    return List.generate(data.length, (index) {
      final chartData = data[index];

      return BarChartGroupData(
        x: index,
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
      );
    });
  }

  List<BarChartGroupData> _itemWiseProductionOrdersChartData(
    List<ItemWiseProductionData> data,
  ) {
    return List.generate(data.length, (index) {
      final chartData = data[index];

      return BarChartGroupData(
        x: index,
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
      );
    });
  }

  List<BarChartGroupData> _branchWiseProductionOrdersChartData(
    List<BranchWiseProductionData> data,
  ) {
    return List.generate(data.length, (index) {
      final chartData = data[index];

      return BarChartGroupData(
        x: index,
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
      );
    });
  }

  List<BarChartGroupData> _itemGroupWiseAnalysisChartData(
    List<ItemGroupWiseProductionData> data,
  ) {
    return List.generate(data.length, (index) {
      final chartData = data[index];

      return BarChartGroupData(
        x: index,
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
      );
    });
  }

  List<BarChartGroupData> _itemSubGroupWiseAnalysisChartData(
    List<ItemSubGroupWiseProductionData> data,
  ) {
    return List.generate(data.length, (index) {
      final chartData = data[index];

      return BarChartGroupData(
        x: index,
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
      );
    });
  }

  List<BarChartGroupData> _plantWiseAnalysisChartData(
    List<PlantWiseProductionData> data,
  ) {
    return List.generate(data.length, (index) {
      final chartData = data[index];

      return BarChartGroupData(
        x: index,
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
      );
    });
  }

  List<BarChartGroupData> _unitWiseAnalysisChartData(
    List<UnitWiseProductionData> data,
  ) {
    return List.generate(data.length, (index) {
      final chartData = data[index];

      return BarChartGroupData(
        x: index,
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
      );
    });
  }

  List<BarChartGroupData> _shiftWiseAnalysisChartData(
    List<ShiftWiseProductionData> data,
  ) {
    return List.generate(data.length, (index) {
      final chartData = data[index];

      return BarChartGroupData(
        x: index,
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
      );
    });
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
      });
      double sum = 0;
      DateTime? prevThreethFromDate;
      DateTime? prevThreeMthToDate;
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
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message:
            "Error occured while loading production order target analysis.",
      );
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
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading production order analysis.",
      );
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
      final currentMonth = DateTime.now().month;

      /// Convert fiscal loop month
      final actualMonth = i > 12 ? i - 12 : i;

      /// Convert to fiscal sequence
      final fiscalSequence = actualMonth >= 4
          ? actualMonth - 3
          : actualMonth + 9;

      /// Current fiscal sequence
      final currentFiscalSequence = currentMonth >= 4
          ? currentMonth - 3
          : currentMonth + 9;

      final shouldShowMonth =
          /// Show completed FY months
          fiscalSequence <= currentFiscalSequence ||
          /// Show future months only if target exists
          monthlyTarget > 0;

      if (shouldShowMonth) {
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
    prepareMaxValues();

    if (mounted) {
      setState(() {});
    }
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
    prepareFormattedDates();
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
    prepareMaxValues();

    if (mounted) {
      setState(() {});
    }
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
    prepareFormattedDates();
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
    prepareMaxValues();

    if (mounted) {
      setState(() {});
    }
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

  Future<void> generateMonthlyProductionExcel(
    MonthlyProductionList monthlyProductionList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'MonthlyProduction',
      headers: ['Month', 'Achievement', 'Target'],
      rows: monthlyProductionList.monthlyData
          .map((e) => [e.monthName, e.production, e.target])
          .toList(),
      fileName: 'monthly_production_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Monthly Analysis',
    );
  }

  Future<void> generateMonthlyProductionPDF(
    MonthlyProductionList monthlyProductionList,
  ) async {
    await reportService.generatePDF(
      title: 'Production - Monthly Analysis',
      headers: ['Month', 'Achievement', 'Target'],
      rows: monthlyProductionList.monthlyData
          .map((e) => [e.monthName, e.production, e.target])
          .toList(),
      fileName: 'monthly_production_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateItemProductionExcel(
    ItemWiseProductionList itemWiseProductionList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'ItemWiseProduction',
      headers: ['Item Name', 'Production Qty.', 'Monthly Avg.'],
      rows: itemWiseProductionList.itemWiseData
          .map((e) => [e.itemName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'item_production_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Item Wise Analysis',
    );
  }

  Future<void> generateItemProductionPDF(
    ItemWiseProductionList itemWiseProductionList,
  ) async {
    await reportService.generatePDF(
      title: 'Production - Item Wise Analysis',
      headers: ['Item Name', 'Production Qty.', 'Monthly Avg.'],
      rows: itemWiseProductionList.itemWiseData
          .map((e) => [e.itemName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'item_production_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateItemGroupProductionExcel(
    ItemGroupWiseProductionList itemGroupWiseProductionList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'ItemGroupWiseProduction',
      headers: ['Item Group Name', 'Production Qty.', 'Monthly Avg.'],
      rows: itemGroupWiseProductionList.itemGroupWiseData
          .map((e) => [e.itemGroupName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'itemgroup_production_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Item Group Wise Analysis',
    );
  }

  Future<void> generateItemGroupProductionPDF(
    ItemGroupWiseProductionList itemGroupWiseProductionList,
  ) async {
    await reportService.generatePDF(
      title: 'Production - Item Group Wise Analysis',
      headers: ['Item Group Name', 'Production Qty.', 'Monthly Avg.'],
      rows: itemGroupWiseProductionList.itemGroupWiseData
          .map((e) => [e.itemGroupName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'item_groupwise_production_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateItemSubGroupProductionExcel(
    ItemSubGroupWiseProductionList itemSubGroupWiseProductionList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'ItemGroupWiseProduction',
      headers: ['Item Sub Group Name', 'Production Qty.', 'Monthly Avg.'],
      rows: itemSubGroupWiseProductionList.itemSubGroupWiseData
          .map(
            (e) => [e.itemSubGroupName, e.productionActual, e.production3Month],
          )
          .toList(),
      fileName: 'item_subgroup_production_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Item Sub Group Wise Analysis',
    );
  }

  Future<void> generateItemSubGroupProductionPDF(
    ItemSubGroupWiseProductionList itemSubGroupWiseProductionList,
  ) async {
    await reportService.generatePDF(
      title: 'Production - Item Sub Group Wise Analysis',
      headers: ['Item Sub Group Name', 'Production Qty.', 'Monthly Avg.'],
      rows: itemSubGroupWiseProductionList.itemSubGroupWiseData
          .map(
            (e) => [e.itemSubGroupName, e.productionActual, e.production3Month],
          )
          .toList(),
      fileName: 'item_subgroup_production_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateBranchProductionExcel(
    BranchWiseProductionList branchWiseProductionList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'BranchProduction',
      headers: ['Branch Name', 'Production Qty.', 'Monthly Avg.'],
      rows: branchWiseProductionList.branchWiseData
          .map((e) => [e.branchName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'branch_production_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Branch Wise Analysis',
    );
  }

  Future<void> generateBranchProductionPDF(
    BranchWiseProductionList branchWiseProductionList,
  ) async {
    await reportService.generatePDF(
      title: 'Production - Branch Wise Analysis',
      headers: ['Branch Name', 'Production Qty.', 'Monthly Avg.'],
      rows: branchWiseProductionList.branchWiseData
          .map((e) => [e.branchName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'branch_production_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateOrderStatusProductionExcel(
    OrderStatusList orderStatusList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'OrderStatusProduction',
      headers: ['Status', 'Production Qty.', 'Percentage'],
      rows: orderStatusList.statusData
          .map((e) => [e.statusName, e.statusAmount, e.statusPercentage])
          .toList(),
      fileName: 'order_status_production_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Order Status Wise Analysis',
    );
  }

  Future<void> generateOrderStatusProductionPDF(
    OrderStatusList orderStatusList,
  ) async {
    await reportService.generatePDF(
      title: 'Production - Order Status Wise Analysis',
      headers: ['Status', 'Production Qty.', 'Percentage'],
      rows: orderStatusList.statusData
          .map((e) => [e.statusName, e.statusAmount, e.statusPercentage])
          .toList(),
      fileName: 'order_status_production_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generatePlantProductionExcel(
    PlantWiseProductionList plantWiseProductionList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'PlantProduction',
      headers: ['Plant Name', 'Production Qty.', 'Monthly Avg.'],
      rows: plantWiseProductionList.plantData
          .map((e) => [e.plantName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'plant_production_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Plant Wise Analysis',
    );
  }

  Future<void> generatePlantProductionPDF(
    PlantWiseProductionList plantWiseProductionList,
  ) async {
    await reportService.generatePDF(
      title: 'Production - Plant Wise Analysis',
      headers: ['Plant Name', 'Production Qty.', 'Monthly Avg.'],
      rows: plantWiseProductionList.plantData
          .map((e) => [e.plantName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'plant_production_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateUnitProductionExcel(
    UnitWiseProductionList unitWiseProductionList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'UnitProduction',
      headers: ['Unit Name', 'Production Qty.', 'Monthly Avg.'],
      rows: unitWiseProductionList.unitData
          .map((e) => [e.unitName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'unit_production_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Unit Wise Analysis',
    );
  }

  Future<void> generateUnitProductionPDF(
    UnitWiseProductionList unitWiseProductionList,
  ) async {
    await reportService.generatePDF(
      title: 'Production - Unit Wise Analysis',
      headers: ['Unit Name', 'Production Qty.', 'Monthly Avg.'],
      rows: unitWiseProductionList.unitData
          .map((e) => [e.unitName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'unit_production_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateShiftProductionExcel(
    ShiftWiseProductionList shiftWiseProductionList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'ShiftProduction',
      headers: ['Shift Name', 'Production Qty.', 'Monthly Avg.'],
      rows: shiftWiseProductionList.shiftData
          .map((e) => [e.shiftName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'shift_production_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Shift Wise Analysis',
    );
  }

  Future<void> generateShiftProductionPDF(
    ShiftWiseProductionList shiftWiseProductionList,
  ) async {
    await reportService.generatePDF(
      title: 'Production - Shift Wise Analysis',
      headers: ['Shift Name', 'Production Qty.', 'Monthly Avg.'],
      rows: shiftWiseProductionList.shiftData
          .map((e) => [e.shiftName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'shift_production_report.pdf',
      amountColumns: [2, 3],
    );
  }

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _monthWiseHorizontalController = ScrollController();
  final ScrollController _itemWiseHorizontalController = ScrollController();
  final ScrollController _branchWiseHorizontalController = ScrollController();
  final ScrollController _itemGroupWiseHorizontalController =
      ScrollController();
  final ScrollController _itemSubGroupWiseHorizontalController =
      ScrollController();
  final ScrollController _plantWiseHorizontalController = ScrollController();
  final ScrollController _unitWiseHorizontalController = ScrollController();
  final ScrollController _shiftWiseHorizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    LoadDates();
    LoadAllQuarterFromToDates();
    prepareFormattedDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
    }
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _monthWiseHorizontalController.dispose();
    _itemWiseHorizontalController.dispose();
    _branchWiseHorizontalController.dispose();
    _itemGroupWiseHorizontalController.dispose();
    _itemSubGroupWiseHorizontalController.dispose();
    _plantWiseHorizontalController.dispose();
    _unitWiseHorizontalController.dispose();
    _shiftWiseHorizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final screenWidth = media.width;
    final screenHeight = media.height;
    return chartDataLoaded == true
        ? FinanceVerticalScroll(
            controller: _verticalScrollController,
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
                                onTap: () async {
                                  await generateMonthlyProductionExcel(
                                    monthData,
                                  );
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () async {
                                  await generateMonthlyProductionPDF(monthData);
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
                RepaintBoundary(
                  child: SingleChildScrollView(
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
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
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DashboardCardUI(
                    title: 'Month wise\nProduction Analysis',
                    spacing: 20,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFF2CA9DF),
                        ),
                        const SizedBox(width: 5),
                        const Text('Actual', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 10),

                        Container(
                          height: 8,
                          width: 8,
                          color: Color(0xFFFF9F47),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          '3 Months Avg.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    menuItems: [
                      PopupMenuItem(
                        onTap: () async {
                          await generateMonthlyProductionExcel(monthData);
                        },
                        child: const Text('Download Excel'),
                      ),

                      PopupMenuItem(
                        onTap: () async {
                          await generateMonthlyProductionPDF(monthData);
                        },
                        child: const Text("Download PDF"),
                      ),
                    ],
                    child: _monthWiseProductionAnalysis(screenWidth),
                  ),
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
                                onTap: () async {
                                  await generateItemProductionExcel(
                                    itemWiseData,
                                  );
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () async {
                                  await generateItemProductionPDF(itemWiseData);
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
                  child: RepaintBoundary(
                    child: _itemWiseProductionOrders(screenWidth),
                  ),
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
                                onTap: () async {
                                  await generateBranchProductionExcel(
                                    branchWiseData,
                                  );
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () async {
                                  await generateBranchProductionPDF(
                                    branchWiseData,
                                  );
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
                  child: RepaintBoundary(
                    child: _branchWiseProductionOrders(screenWidth),
                  ),
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
                                onTap: () async {
                                  await generateItemGroupProductionExcel(
                                    itemGroupWiseData,
                                  );
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () async {
                                  await generateItemGroupProductionPDF(
                                    itemGroupWiseData,
                                  );
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
                  child: RepaintBoundary(
                    child: _itemGroupWiseAnalysis(screenWidth),
                  ),
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
                                onTap: () async {
                                  await generateItemSubGroupProductionExcel(
                                    itemSubGroupWiseData,
                                  );
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () async {
                                  await generateItemSubGroupProductionPDF(
                                    itemSubGroupWiseData,
                                  );
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
                  child: RepaintBoundary(
                    child: _itemSubGroupWiseAnalysis(screenWidth),
                  ),
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
                                onTap: () async {
                                  await generateOrderStatusProductionExcel(
                                    statusData,
                                  );
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () async {
                                  await generateOrderStatusProductionPDF(
                                    statusData,
                                  );
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
                      RepaintBoundary(
                        child: SizedBox(
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
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      height: 8,
                                      width: 16,
                                      color: getCategoryColor(1),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 8,
                                      width: 16,
                                      color: getCategoryColor(0),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 8,
                                      width: 16,
                                      color: getCategoryColor(2),
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
                                onTap: () async {
                                  await generatePlantProductionExcel(
                                    plantWiseData,
                                  );
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () async {
                                  await generatePlantProductionPDF(
                                    plantWiseData,
                                  );
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
                  child: RepaintBoundary(
                    child: _plantWiseAnalysis(screenWidth),
                  ),
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
                                onTap: () async {
                                  await generateUnitProductionExcel(
                                    unitWiseData,
                                  );
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () async {
                                  await generateUnitProductionPDF(unitWiseData);
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
                  child: RepaintBoundary(child: _unitWiseAnalysis(screenWidth)),
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
                                onTap: () async {
                                  await generateShiftProductionExcel(
                                    shiftWiseData,
                                  );
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () async {
                                  await generateShiftProductionPDF(
                                    shiftWiseData,
                                  );
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
                  child: RepaintBoundary(
                    child: _shiftWiseAnalysis(screenWidth),
                  ),
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

  Widget _monthWiseProductionAnalysis(double screenWidth) {
    double barChartWidth = 0.0;
    monthData.monthlyData.length > 6
        ? barChartWidth = screenWidth * 1.4
        : barChartWidth = screenWidth;

    return FinanceHorizontalChartScroll(
      controller: _monthWiseHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: barChartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(monthWiseMaxY),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
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
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
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
      ),
    );
  }

  Widget _itemWiseProductionOrders(double screenWidth) {
    double chartWidth = 0.0;
    int len = itemWiseData.itemWiseData.length;
    if (itemWiseData.itemWiseData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    return FinanceHorizontalChartScroll(
      controller: _itemWiseHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(itemWiseMaxY),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
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
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedItemCode = touchedItemCode == ""
                          ? itemWiseData
                                .itemWiseData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .itemName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
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
      ),
    );
  }

  Widget _branchWiseProductionOrders(double screenWidth) {
    double chartWidth = 0.0;
    int len = branchWiseData.branchWiseData.length;
    if (branchWiseData.branchWiseData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    return FinanceHorizontalChartScroll(
      controller: _branchWiseHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(branchWiseMaxY),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
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
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedBranchName = touchedBranchName == ""
                          ? branchWiseData
                                .branchWiseData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .branchName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
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
      ),
    );
  }

  Widget _itemGroupWiseAnalysis(double screenWidth) {
    double chartWidth = 0.0;
    int len = itemGroupWiseData.itemGroupWiseData.length;
    if (itemGroupWiseData.itemGroupWiseData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    return FinanceHorizontalChartScroll(
      controller: _itemGroupWiseHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(itemGroupMaxY),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
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
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedItemGroup = touchedItemGroup == ""
                          ? itemGroupWiseData
                                .itemGroupWiseData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .itemGroupName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
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
      ),
    );
  }

  Widget _itemSubGroupWiseAnalysis(double screenWidth) {
    double chartWidth = 0.0;
    int len = itemSubGroupWiseData.itemSubGroupWiseData.length;
    if (itemSubGroupWiseData.itemSubGroupWiseData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    return FinanceHorizontalChartScroll(
      controller: _itemSubGroupWiseHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(itemSubGroupMaxY),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
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
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
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
      ),
    );
  }

  Widget _plantWiseAnalysis(double screenWidth) {
    double chartWidth = 0.0;
    int len = plantWiseData.plantData.length;
    if (plantWiseData.plantData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    return FinanceHorizontalChartScroll(
      controller: _plantWiseHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(plantWiseMaxY),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
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
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedPlant = touchedPlant == ""
                          ? plantWiseData
                                .plantData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .plantName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
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
      ),
    );
  }

  Widget _unitWiseAnalysis(double screenWidth) {
    double chartWidth = 0.0;
    int len = unitWiseData.unitData.length;
    if (unitWiseData.unitData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    return FinanceHorizontalChartScroll(
      controller: _unitWiseHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(unitWiseMaxY),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
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
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedUnit = touchedUnit == ""
                          ? unitWiseData
                                .unitData[barTouchResponse.spot!.spot.x.toInt()]
                                .unitName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
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
      ),
    );
  }

  Widget _shiftWiseAnalysis(double screenWidth) {
    double chartWidth = 0.0;
    int len = shiftWiseData.shiftData.length;
    if (shiftWiseData.shiftData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    return FinanceHorizontalChartScroll(
      controller: _shiftWiseHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(shiftWiseMaxY),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
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
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedShift = touchedShift == ""
                          ? shiftWiseData
                                .shiftData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .shiftName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
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
      ),
    );
  }
}
