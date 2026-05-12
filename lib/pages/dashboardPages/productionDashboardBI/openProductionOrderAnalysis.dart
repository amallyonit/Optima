// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/classes/leads.dart';

import '../ReportService.dart';

class OpenProductionOrderAnalysis extends StatefulWidget {
  const OpenProductionOrderAnalysis({super.key});

  @override
  State<OpenProductionOrderAnalysis> createState() =>
      _OpenProductionOrderAnalysisState();
}

class _OpenProductionOrderAnalysisState
    extends State<OpenProductionOrderAnalysis> {
  late Future<void> loadDataFuture;
  final reportService = ReportService();
  final http.Client client = http.Client();
  late String formattedFiscalYearStartDate;
  late String formattedQuarterStartDate;
  late String formattedQuarterLastDate;
  late String formattedDateNow;
  late String formattedDateFirstOfLastMonth;
  late String formattedDateLastOfLastMonth;
  late String formattedDateFirstOfThisMonth;

  double ageingMaxY = 0;
  double itemWiseMaxY = 0;
  double branchWiseMaxY = 0;
  double itemGroupMaxY = 0;
  double itemSubGroupMaxY = 0;
  double plantWiseMaxY = 0;
  double unitWiseMaxY = 0;
  double shiftWiseMaxY = 0;

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
  AgeingAnalysisList ageingAnalysisList = AgeingAnalysisList(agingData: []);
  ReceivablesFinanceList receivablesFinanceList = ReceivablesFinanceList(
    agingData: [],
  );
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

  int touchedMonthIndex = 0;
  String touchedAgingCatg = "";
  String touchedItemCode = "";
  String touchedBranchName = "";
  String touchedItemGroup = "";
  String touchedItemSubGroup = "";
  String touchedPlant = "";
  String touchedUnit = "";
  String touchedShift = "";
  double selectedChart = 0;
  bool chartDataLoaded = false;
  bool touchedMonthGoals = false;
  bool touchedQuarterGoals = false;
  bool touchedYTDGoals = false;
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

  int getCurrentQuarter() {
    int month = DateTime.now().month;
    return ((month - 4 + 12) % 12) ~/ 3 + 1;
  }

  SideTitles get _bottomTitlesAgeingAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<AgeingAnalysisData> mData = ageingAnalysisList.agingData;
      text = mData.elementAt(value.toInt()).group;
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

  Widget getBottomTitles(double val, TitleMeta meta) {
    String text = '';
    MonthlyProductionData mthData = monthData.monthlyData[val.toInt()];
    text = mthData.monthName;
    return Text(text.length > 3 ? text.substring(0, 3) : text);
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

  void prepareMaxValues() {
    /// MONTH WISE
    ageingMaxY = ageingAnalysisList.agingData.isNotEmpty
        ? ageingAnalysisList.agingData
              .map((e) => e.receivableAmount)
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
    return ((maxValue ~/ 1000) + 1) * 1000;
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
    return ((maxValue ~/ 1000) + 1) * 1000;
  }

  double getGroupMaxValue(ItemGroupWiseProductionList grpData) {
    double maxValue = 0.0;
    for (var brData in grpData.itemGroupWiseData) {
      maxValue = maxValue > brData.productionActual
          ? maxValue
          : brData.productionActual;
    }
    return ((maxValue ~/ 1000) + 1) * 1000;
  }

  double getSubGroupMaxValue(ItemSubGroupWiseProductionList subData) {
    double maxValue = 0.0;
    for (var brData in subData.itemSubGroupWiseData) {
      maxValue = maxValue > brData.productionActual
          ? maxValue
          : brData.productionActual;
    }
    return ((maxValue ~/ 1000) + 1) * 1000;
  }

  double getPlantMaxValue(PlantWiseProductionList plantData) {
    double maxValue = 0.0;
    for (var brData in plantData.plantData) {
      maxValue = maxValue > brData.productionActual
          ? maxValue
          : brData.productionActual;
    }
    return ((maxValue ~/ 1000) + 1) * 1000;
  }

  double getUnitMaxValue(UnitWiseProductionList unitData) {
    double maxValue = 0.0;
    for (var brData in unitData.unitData) {
      maxValue = maxValue > brData.productionActual
          ? maxValue
          : brData.productionActual;
    }
    return ((maxValue ~/ 1000) + 1) * 1000;
  }

  double getShiftMaxValue(ShiftWiseProductionList shiftData) {
    double maxValue = 0.0;
    for (var brData in shiftData.shiftData) {
      maxValue = maxValue > brData.productionActual
          ? maxValue
          : brData.productionActual;
    }
    return ((maxValue ~/ 1000) + 1) * 1000;
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

  Map<String, DateTime> getLastThreeMonthsRange(int monthIndex, int year) {
    // Ensure the month index is valid (1 to 12)
    if (monthIndex < 1 || monthIndex > 12) {
      throw ArgumentError('Invalid month index. Must be between 1 and 12.');
    }

    // Calculate the start date (3 months ago from the given month index)
    DateTime startDate = DateTime(year, monthIndex - 3, 1);

    // Calculate the end date (last day of the given month)
    DateTime endDate = DateTime(year, monthIndex, 0);

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
    var productionList = const Iterable.empty();

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

          productionList = currentMonthSales
              .where((element) => element.status == "Open")
              .toList();
          double salesAmt = 0;
          for (var target in productionList) {
            salesAmt = double.tryParse(target.plannedQty) ?? 0;
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
          for (var target
              in curQtrSales
                  .where((element) => element.status == "Open")
                  .toList()) {
            salesAmt = double.tryParse(target.plannedQty) ?? 0;
            sum += salesAmt;
          }

          Q1Sales = sum;
          Q1SalesStr = "${(Q1Sales / 100000).toStringAsFixed(2)} L";
          if (Q1Sales == 0) {
            Q1Percentage = 0;
          } else {
            if (Q1Target != 0) {
              Q1Percentage =
                  double.tryParse(
                    ((Q1Sales / Q1Target) * 100).toStringAsFixed(2),
                  )?.ceil() ??
                  0;
            } else {
              Q1Percentage = 0;
            }
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

          productionList = currentMonthSales
              .where((element) => element.status == "Open")
              .toList();
          double salesAmt = 0;
          for (var target in productionList.toList()) {
            salesAmt = double.tryParse(target.plannedQty) ?? 0;
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
          for (var target
              in curQtrSales
                  .where((element) => element.status == "Open")
                  .toList()) {
            salesAmt = double.tryParse(target.plannedQty) ?? 0;
            sum += salesAmt;
          }

          Q2Sales = sum;
          Q2SalesStr = "${(Q2Sales / 100000).toStringAsFixed(2)} L";
          if (Q2Sales == 0) {
            Q2Percentage = 0;
          } else {
            if (Q2Target != 0) {
              Q2Percentage =
                  double.tryParse(
                    ((Q2Sales / Q2Target) * 100).toStringAsFixed(2),
                  )?.ceil() ??
                  0;
            } else {
              Q2Percentage = 0;
            }
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

          productionList = currentMonthSales
              .where((element) => element.status == "Open")
              .toList();
          double salesAmt = 0;
          for (var target in productionList.toList()) {
            salesAmt = double.tryParse(target.plannedQty) ?? 0;
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
          for (var target
              in curQtrSales
                  .where((element) => element.status == "Open")
                  .toList()) {
            salesAmt = double.tryParse(target.plannedQty) ?? 0;
            sum += salesAmt;
          }

          Q3Sales = sum;
          Q3SalesStr = "${(Q3Sales / 100000).toStringAsFixed(2)} L";
          if (Q3Sales == 0) {
            Q3Percentage = 0;
          } else {
            if (Q3Target != 0) {
              Q3Percentage =
                  double.tryParse(
                    ((Q3Sales / Q3Target) * 100).toStringAsFixed(2),
                  )?.ceil() ??
                  0;
            } else {
              Q3Percentage = 0;
            }
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

          productionList = currentMonthSales
              .where((element) => element.status == "Open")
              .toList();
          double salesAmt = 0;
          for (var target in productionList.toList()) {
            salesAmt = double.tryParse(target.plannedQty) ?? 0;
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
          for (var target
              in curQtrSales
                  .where((element) => element.status == "Open")
                  .toList()) {
            salesAmt = double.tryParse(target.plannedQty) ?? 0;
            sum += salesAmt;
          }
          Q4Sales = sum;
          Q4SalesStr = "${(Q4Sales / 100000).toStringAsFixed(2)} L";
          if (Q4Sales == 0) {
            Q4Percentage = 0;
          } else {
            if (Q4Target != 0) {
              Q4Percentage =
                  double.tryParse(
                    ((Q4Sales / Q4Target) * 100).toStringAsFixed(2),
                  )?.ceil() ??
                  0;
            } else {
              Q4Percentage = 0;
            }
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

  int getCurrentFinancialMonthNumber() {
    DateTime now = DateTime.now();
    int currentMonth = now.month;

    const int financialYearStartMonth = 4; // April

    int financialMonthNumber;

    if (currentMonth >= financialYearStartMonth) {
      financialMonthNumber = currentMonth - financialYearStartMonth + 1;
    } else {
      financialMonthNumber = 12 - (financialYearStartMonth - currentMonth) + 1;
    }

    return financialMonthNumber;
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

  List<BarChartGroupData> _ageingAnalysisChartData(
    List<AgeingAnalysisData> data,
  ) {
    return List.generate(data.length, (index) {
      final chartData = data[index];

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            color: const Color(0xFF97D7F3),
            borderRadius: BorderRadius.zero,
            toY: chartData.receivableAmount,
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
              toY: chartData.productionActual,
              show: true,
              color: const Color(0xFF97D7F3),
            ),
            color: const Color(0xFFFF9F47),
            borderRadius: BorderRadius.zero,
            toY: chartData.production3Month,
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

  Future<void> _loadOpenProductionOrderTargetAnalysis(
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
        final response = await client.post(
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

  Future<void> _loadOpenProductionOrderAnalysis(
    String UserName,
    String UserLevel,
  ) async {
    LoadAllQuarterFromToDates();
    try {
      var targetValues = production.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
        return invoiceDate.isAtLeast(currentQuarterFromDate!) &&
            invoiceDate.isAtMost(currentQuarterToDate!);
      });

      double targetSum = 0;
      double targetAmt = 0;
      for (var target
          in targetValues
              .where((element) => element.status == "Open")
              .toList()) {
        targetAmt = double.tryParse(target.plannedQty) ?? 0;
        targetSum += targetAmt;
      }

      double sum = 0;
      var currentMonthSales = production.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);

        return invoiceDate.isAtLeast(currentMonthFromDate!) &&
            invoiceDate.isAtMost(currentDate!);
      });

      double salesAmt = 0;
      for (var target
          in currentMonthSales
              .where((element) => element.status == "Open")
              .toList()) {
        salesAmt = double.tryParse(target.plannedQty) ?? 0;
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
              ((CurrentMonthSales / (targetSum * 3)) * 100).toStringAsFixed(0),
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

      double lastMonthSum = 0;
      double lastMonthSalesAmt = 0;
      for (var target
          in lastMonthSales
              .where((element) => element.status == "Open")
              .toList()) {
        lastMonthSalesAmt = double.tryParse(target.plannedQty) ?? 0;
        lastMonthSum += lastMonthSalesAmt;
      }

      LastMonthSales = lastMonthSum;
      LastMonthSalesStr = "${(LastMonthSales / 100000).toStringAsFixed(2)} L";
      if (LastMonthSales == 0) {
        LastMonthPercentage = 0;
      } else {
        LastMonthPercentage =
            double.tryParse(
              ((LastMonthSales / (targetSum * 3)) * 100).toStringAsFixed(2),
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
      for (var target
          in curQtrSales
              .where((element) => element.status == "Open")
              .toList()) {
        salesAmt = double.tryParse(target.plannedQty) ?? 0;
        sum += salesAmt;
      }

      CurrentQtrSales = sum;
      CurrentQtrSalesStr = "${(CurrentQtrSales / 100000).toStringAsFixed(2)} L";
      if (CurrentQtrSales == 0) {
        CurrentQtrPercentage = 0;
      } else {
        CurrentQtrPercentage =
            double.tryParse(
              ((CurrentQtrSales / (targetSum * 3)) * 100).toStringAsFixed(2),
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
      for (var target
          in ytdSales.where((element) => element.status == "Open").toList()) {
        salesAmt = double.tryParse(target.plannedQty) ?? 0;
        sum += salesAmt;
      }

      YtdSales = sum;
      YtdSalesStr = "${(YtdSales / 100000).toStringAsFixed(2)} L";
      if (YtdSales == 0) {
        YtdPercentage = 0;
      } else {
        YtdPercentage =
            double.tryParse(
              ((YtdSales / (targetSum * getCurrentFinancialMonthNumber())) *
                      100)
                  .toStringAsFixed(2),
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

  Future<void> _loadAgeingAnalysisOpenProduction(
    String dueDays,
    String itemCode,
    String branchName,
    String itemGroup,
    String itemSubGroup,
    String plantName,
    String unitName,
    String shiftName,
  ) async {
    List<AgeingAnalysisData> agingDataList = [];

    var agingList = const Iterable.empty();
    agingList = production
        .where((element) => element.status == "Open")
        .toList();
    double amount0to30 = 0.0;
    double amount31to60 = 0.0;
    double amount61to90 = 0.0;
    double amount91a = 0.0;
    double maxY = 0;

    agingList = filterProductionList(
      agingList.cast<ProductionOrderList>().toList(),
      dueDays: dueDays,
      itemCode: itemCode,
      branchName: branchName,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      plantName: plantName,
      unitName: unitName,
      shiftName: shiftName,
    );

    for (var product in agingList.toList()) {
      var overDueDays = product.agingDays;
      var orderValue = product.plannedQty;

      if (overDueDays != null && orderValue != null) {
        var parsedOverDueDays = double.tryParse(overDueDays) ?? 0;
        var parsedOrderValue = double.tryParse(orderValue) ?? 0;
        if (parsedOverDueDays <= 30) {
          amount0to30 += parsedOrderValue;
        } else if (parsedOverDueDays >= 31 && parsedOverDueDays <= 60) {
          amount31to60 += parsedOrderValue;
        } else if (parsedOverDueDays >= 61 && parsedOverDueDays <= 90) {
          amount61to90 += parsedOrderValue;
        } else if (parsedOverDueDays >= 91) {
          amount91a += parsedOrderValue;
        }
      }
    }
    if (amount0to30 > maxY) {
      maxY = amount0to30;
    }
    if (amount31to60 > maxY) {
      maxY = amount31to60;
    }
    if (amount61to90 > maxY) {
      maxY = amount61to90;
    }
    if (amount91a > maxY) {
      maxY = amount91a;
    }
    maxY = ((maxY ~/ 100000) + 1) * 100000;
    agingDataList.add(
      AgeingAnalysisData(
        receivableAmount: amount0to30,
        percentage: 0,
        group: "0-30",
        maxY: maxY,
      ),
    );
    agingDataList.add(
      AgeingAnalysisData(
        receivableAmount: amount31to60,
        percentage: 0,
        group: "31-60",
        maxY: maxY,
      ),
    );
    agingDataList.add(
      AgeingAnalysisData(
        receivableAmount: amount61to90,
        percentage: 0,
        group: "61-90",
        maxY: maxY,
      ),
    );
    agingDataList.add(
      AgeingAnalysisData(
        receivableAmount: amount91a,
        percentage: 0,
        group: "90+",
        maxY: maxY,
      ),
    );
    ageingAnalysisList = AgeingAnalysisList(agingData: agingDataList);
  }

  Future<void> _loadItemWiseProductionOrders(
    String dueDays,
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
    DateTime? prevThreethFromDate = DateTime(
      currentDate!.year,
      currentDate!.month - 3,
      1,
    );
    DateTime? prevThreeMthToDate = DateTime(
      currentDate!.year,
      currentDate!.month,
      0,
    );

    var productSalesList = const Iterable.empty();
    var saleList = const Iterable.empty();
    var saleList3Months = const Iterable.empty();
    productSalesList = tempList.toList().where((target) {
      DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
      return (invoiceDate.isAtLeast(prevThreethFromDate) &&
          invoiceDate.isAtMost(prevThreeMthToDate));
    });

    saleList = tempList.where((element) => element.status == "Open").toList();
    saleList3Months = productSalesList
        .where((element) => element.status == "Open")
        .toList();

    saleList = filterProductionList(
      saleList.cast<ProductionOrderList>().toList(),
      dueDays: dueDays,
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
      dueDays: dueDays,
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
          salesAmt = double.tryParse(target.plannedQty) ?? 0;
          productActual += salesAmt;
        }
        for (var target in saleList3Months.toList().where(
          (element) => element.productDescription == itemName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.plannedQty) ?? 0;
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
    String dueDays,
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
    String branchName = "";
    double productActual = 0.00;
    double product3Month = 0.00;
    DateTime? prevThreethFromDate = DateTime(
      currentDate!.year,
      currentDate!.month - 3,
      1,
    );
    DateTime? prevThreeMthToDate = DateTime(
      currentDate!.year,
      currentDate!.month,
      0,
    );

    var productSalesList = const Iterable.empty();
    var saleList = const Iterable.empty();
    var saleList3Months = const Iterable.empty();
    productSalesList = tempList.toList().where((target) {
      DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
      return (invoiceDate.isAtLeast(prevThreethFromDate) &&
          invoiceDate.isAtMost(prevThreeMthToDate));
    });

    saleList = tempList.where((element) => element.status == "Open").toList();
    saleList3Months = productSalesList
        .where((element) => element.status == "Open")
        .toList();
    saleList = filterProductionList(
      saleList.cast<ProductionOrderList>().toList(),
      dueDays: dueDays,
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
      dueDays: dueDays,
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
        branchName = product.branch;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.branch == branchName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.plannedQty) ?? 0;
          productActual += salesAmt;
        }
        for (var target in saleList3Months.toList().where(
          (element) => element.branch == branchName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.plannedQty) ?? 0;
          product3Month += salesAmt;
        }

        branchwiseDataList.add(
          BranchWiseProductionData(
            branchName: branchName,
            productionActual: productActual,
            production3Month: product3Month / 3,
          ),
        );
        processedProductCodes.add(product.branch);
      }
      productActual = 0;
      product3Month = 0;
      branchName = "";
    }
    branchwiseDataList.sort(
      (a, b) => b.productionActual.compareTo(a.productionActual),
    );

    branchWiseData = BranchWiseProductionList(
      branchWiseData: branchwiseDataList,
    );
  }

  Future<void> _loadItemGroupWiseProductionOrders(
    String dueDays,
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
    DateTime? prevThreethFromDate = DateTime(
      currentDate!.year,
      currentDate!.month - 3,
      1,
    );
    DateTime? prevThreeMthToDate = DateTime(
      currentDate!.year,
      currentDate!.month,
      0,
    );

    var productSalesList = const Iterable.empty();
    var saleList = const Iterable.empty();
    var saleList3Months = const Iterable.empty();

    productSalesList = tempList.toList().where((target) {
      DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
      return (invoiceDate.isAtLeast(prevThreethFromDate) &&
          invoiceDate.isAtMost(prevThreeMthToDate));
    });

    saleList = tempList.where((element) => element.status == "Open").toList();
    saleList3Months = productSalesList
        .where((element) => element.status == "Open")
        .toList();

    saleList = filterProductionList(
      saleList.cast<ProductionOrderList>().toList(),
      dueDays: dueDays,
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
      dueDays: dueDays,
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
          salesAmt = double.tryParse(target.plannedQty) ?? 0;
          productActual += salesAmt;
        }
        for (var target in saleList3Months.toList().where(
          (element) => element.groupName == group,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.plannedQty) ?? 0;
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
    String dueDays,
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
    DateTime? prevThreethFromDate = DateTime(
      currentDate!.year,
      currentDate!.month - 3,
      1,
    );
    DateTime? prevThreeMthToDate = DateTime(
      currentDate!.year,
      currentDate!.month,
      0,
    );

    var productSalesList = const Iterable.empty();
    var saleList = const Iterable.empty();
    var saleList3Months = const Iterable.empty();

    productSalesList = tempList.toList().where((target) {
      DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
      return (invoiceDate.isAtLeast(prevThreethFromDate) &&
          invoiceDate.isAtMost(prevThreeMthToDate));
    });

    saleList = tempList.where((element) => element.status == "Open").toList();
    saleList3Months = productSalesList
        .where((element) => element.status == "Open")
        .toList();

    saleList = filterProductionList(
      saleList.cast<ProductionOrderList>().toList(),
      dueDays: dueDays,
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
      dueDays: dueDays,
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
          salesAmt = double.tryParse(target.plannedQty) ?? 0;
          productActual += salesAmt;
        }

        for (var target in saleList3Months.toList().where(
          (element) => element.itemSubGroup == subGroup,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.plannedQty) ?? 0;
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
    String dueDays,
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
    String plantName = "";
    double productActual = 0.00;
    double product3Month = 0.00;
    DateTime? prevThreethFromDate = DateTime(
      currentDate!.year,
      currentDate!.month - 3,
      1,
    );
    DateTime? prevThreeMthToDate = DateTime(
      currentDate!.year,
      currentDate!.month,
      0,
    );

    var productionList = const Iterable.empty();
    var saleList = const Iterable.empty();
    var production3Months = const Iterable.empty();
    productionList = tempList.toList().where((target) {
      DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
      return (invoiceDate.isAtLeast(prevThreethFromDate) &&
          invoiceDate.isAtMost(prevThreeMthToDate));
    });

    saleList = tempList.where((element) => element.status == "Open").toList();
    production3Months = productionList
        .where((element) => element.status == "Open")
        .toList();

    saleList = filterProductionList(
      saleList.cast<ProductionOrderList>().toList(),
      dueDays: dueDays,
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
      dueDays: dueDays,
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
        plantName = product.plant;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.plant == plantName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.plannedQty) ?? 0;
          productActual += salesAmt;
        }
        for (var target in production3Months.toList().where(
          (element) => element.plant == plantName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.plannedQty) ?? 0;
          product3Month += salesAmt;
        }

        plantDataList.add(
          PlantWiseProductionData(
            plantName: plantName,
            production3Month: product3Month / 3,
            productionActual: productActual,
          ),
        );
        processedProductCodes.add(product.plant);
      }
      productActual = 0;
      product3Month = 0;
      plantName = "";
    }
    plantDataList.sort(
      (a, b) => b.productionActual.compareTo(a.productionActual),
    );
    plantWiseData = PlantWiseProductionList(plantData: plantDataList);
  }

  Future<void> _loadUnitWiseProductionOrders(
    String dueDays,
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
    String unitName = "";
    double productActual = 0.00;
    double product3Month = 0.00;
    DateTime? prevThreethFromDate = DateTime(
      currentDate!.year,
      currentDate!.month - 3,
      1,
    );
    DateTime? prevThreeMthToDate = DateTime(
      currentDate!.year,
      currentDate!.month,
      0,
    );

    var productionList = const Iterable.empty();
    var saleList = const Iterable.empty();
    var production3Months = const Iterable.empty();
    productionList = tempList.toList().where((target) {
      DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
      return (invoiceDate.isAtLeast(prevThreethFromDate) &&
          invoiceDate.isAtMost(prevThreeMthToDate));
    });

    saleList = tempList.where((element) => element.status == "Open").toList();
    production3Months = productionList
        .where((element) => element.status == "Open")
        .toList();

    saleList = filterProductionList(
      saleList.cast<ProductionOrderList>().toList(),
      dueDays: dueDays,
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
      dueDays: dueDays,
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
        unitName = product.unit;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.unit == unitName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.plannedQty) ?? 0;
          productActual += salesAmt;
        }
        for (var target in production3Months.toList().where(
          (element) => element.unit == unitName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.plannedQty) ?? 0;
          product3Month += salesAmt;
        }

        unitDataList.add(
          UnitWiseProductionData(
            unitName: unitName,
            production3Month: product3Month / 3,
            productionActual: productActual,
          ),
        );
        processedProductCodes.add(product.unit);
      }
      productActual = 0;
      product3Month = 0;
      unitName = "";
    }
    unitDataList.sort(
      (a, b) => b.productionActual.compareTo(a.productionActual),
    );
    unitWiseData = UnitWiseProductionList(unitData: unitDataList);
  }

  Future<void> _loadShiftWiseProductionOrders(
    String dueDays,
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
    String shiftName = "";
    double productActual = 0.00;
    double product3Month = 0.00;
    DateTime? prevThreethFromDate = DateTime(
      currentDate!.year,
      currentDate!.month - 3,
      1,
    );
    DateTime? prevThreeMthToDate = DateTime(
      currentDate!.year,
      currentDate!.month,
      0,
    );

    var productionList = const Iterable.empty();
    var saleList = const Iterable.empty();
    var production3Months = const Iterable.empty();
    productionList = tempList.toList().where((target) {
      DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);
      return (invoiceDate.isAtLeast(prevThreethFromDate) &&
          invoiceDate.isAtMost(prevThreeMthToDate));
    });

    saleList = tempList.where((element) => element.status == "Open").toList();
    production3Months = productionList
        .where((element) => element.status == "Open")
        .toList();

    saleList = filterProductionList(
      saleList.cast<ProductionOrderList>().toList(),
      dueDays: dueDays,
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
      dueDays: dueDays,
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
        shiftName = product.shift;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.shift == shiftName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.plannedQty) ?? 0;
          productActual += salesAmt;
        }
        for (var target in production3Months.toList().where(
          (element) => element.shift == shiftName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.plannedQty) ?? 0;
          product3Month += salesAmt;
        }

        shiftDataList.add(
          ShiftWiseProductionData(
            shiftName: shiftName,
            production3Month: product3Month / 3,
            productionActual: productActual,
          ),
        );
        processedProductCodes.add(product.shift);
      }
      productActual = 0;
      product3Month = 0;
      shiftName = "";
    }
    shiftDataList.sort(
      (a, b) => b.productionActual.compareTo(a.productionActual),
    );
    shiftWiseData = ShiftWiseProductionList(shiftData: shiftDataList);
  }

  Future<void> _loadOrderStatusOpenProduction(
    String dueDays,
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
    saleList = tempList.where((element) => element.status == "Open").toList();

    Set<String> processedProductCodes = {};
    for (var product in saleList.toList().toList()) {
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
      double? percentage = (totalAmount != 0 && categoryData.statusAmount != 0)
          ? double.tryParse(
              ((categoryData.statusAmount / totalAmount) * 100).toStringAsFixed(
                2,
              ),
            )
          : 0;
      categoryData.statusPercentage = percentage!;
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
    await _loadOpenProductionOrderTargetAnalysis(userName, userLevel);
    await _loadOpenProductionOrderAnalysis(userName, userLevel);
    await _loadEachQtrValues();
    await _loadAgeingAnalysisOpenProduction("", "", "", "", "", "", "", "");
    await _loadItemWiseProductionOrders("", "", "", "", "", "", "", "");
    await _loadBranchWiseProductionOrders("", "", "", "", "", "", "", "");
    await _loadItemGroupWiseProductionOrders("", "", "", "", "", "", "", "");
    await _loadItemSubGroupWiseProductionOrders("", "", "", "", "", "", "", "");
    await _loadPlantWiseProductionOrders("", "", "", "", "", "", "", "");
    await _loadUnitWiseProductionOrders("", "", "", "", "", "", "", "");
    await _loadShiftWiseProductionOrders("", "", "", "", "", "", "", "");
    await _loadOrderStatusOpenProduction("", "", "", "", "", "", "", "");
    chartDataLoaded = true;

    prepareMaxValues();

    if (mounted) {
      setState(() {});
    }
  }

  List<ProductionOrderList> filterProductionList(
    List<ProductionOrderList> productionList, {
    String? dueDays,
    String? itemCode,
    String? branchName,
    String? itemGroup,
    String? itemSubGroup,
    String? plantName,
    String? unitName,
    String? shiftName,
  }) {
    List<ProductionOrderList> filteredProductionList = [];
    double dueFrom = 0.0;
    double dueTo = 0.0;
    if (dueDays != null || dueDays != "") {
      if (dueDays == "0-30") {
        dueFrom = 0;
        dueTo = 30;
      } else if (dueDays == "31-60") {
        dueFrom = 31;
        dueTo = 60;
      } else if (dueDays == "61-90") {
        dueFrom = 61;
        dueTo = 90;
      } else if (dueDays == "90+") {
        dueFrom = 91;
        dueTo = double.infinity;
      }
    }
    for (var production in productionList) {
      int overDueDays = int.tryParse(production.agingDays) ?? 0;
      if ((dueDays == null ||
              dueDays.isEmpty ||
              (overDueDays >= dueFrom && overDueDays <= dueTo)) &&
          (itemCode == null ||
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
    touchedAgingCatg = "";
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
    await _loadAgeingAnalysisOpenProduction("", "", "", "", "", "", "", "");
    await _loadItemWiseProductionOrders("", "", "", "", "", "", "", "");
    await _loadBranchWiseProductionOrders("", "", "", "", "", "", "", "");
    await _loadItemGroupWiseProductionOrders("", "", "", "", "", "", "", "");
    await _loadItemSubGroupWiseProductionOrders("", "", "", "", "", "", "", "");
    await _loadPlantWiseProductionOrders("", "", "", "", "", "", "", "");
    await _loadUnitWiseProductionOrders("", "", "", "", "", "", "", "");
    await _loadShiftWiseProductionOrders("", "", "", "", "", "", "", "");
    await _loadOrderStatusOpenProduction("", "", "", "", "", "", "", "");
    chartDataLoaded = true;

    prepareMaxValues();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadDataWithFilter(
    String dueDays,
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
    await _loadAgeingAnalysisOpenProduction(
      dueDays,
      itemCode,
      branchName,
      itemGroup,
      itemSubGroup,
      plantName,
      unitName,
      shiftName,
    );
    await _loadItemWiseProductionOrders(
      dueDays,
      itemCode,
      branchName,
      itemGroup,
      itemSubGroup,
      plantName,
      unitName,
      shiftName,
    );
    await _loadBranchWiseProductionOrders(
      dueDays,
      itemCode,
      branchName,
      itemGroup,
      itemSubGroup,
      plantName,
      unitName,
      shiftName,
    );
    await _loadItemGroupWiseProductionOrders(
      dueDays,
      itemCode,
      branchName,
      itemGroup,
      itemSubGroup,
      plantName,
      unitName,
      shiftName,
    );
    await _loadItemSubGroupWiseProductionOrders(
      dueDays,
      itemCode,
      branchName,
      itemGroup,
      itemSubGroup,
      plantName,
      unitName,
      shiftName,
    );
    await _loadPlantWiseProductionOrders(
      dueDays,
      itemCode,
      branchName,
      itemGroup,
      itemSubGroup,
      plantName,
      unitName,
      shiftName,
    );
    await _loadUnitWiseProductionOrders(
      dueDays,
      itemCode,
      branchName,
      itemGroup,
      itemSubGroup,
      plantName,
      unitName,
      shiftName,
    );
    await _loadShiftWiseProductionOrders(
      dueDays,
      itemCode,
      branchName,
      itemGroup,
      itemSubGroup,
      plantName,
      unitName,
      shiftName,
    );
    await _loadOrderStatusOpenProduction(
      dueDays,
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
      ageingAnalysisList = AgeingAnalysisList(agingData: []);
      receivablesFinanceList = ReceivablesFinanceList(agingData: []);
      monthData = MonthlyProductionList(monthlyData: []);
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
      touchedAgingCatg = "";
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
      ageingAnalysisList = AgeingAnalysisList(agingData: []);
      receivablesFinanceList = ReceivablesFinanceList(agingData: []);
      monthData = MonthlyProductionList(monthlyData: []);
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

  Future<void> generateAgeingOpenProductionExcel(
    AgeingAnalysisList ageingAnalysisList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'AgeingOpenProduction',
      headers: ['Ageing', 'Planned Qty.'],
      rows: ageingAnalysisList.agingData
          .map((e) => [e.group, e.receivableAmount])
          .toList(),
      fileName: 'ageing_openproduction_report.xlsx',
      amountColumns: [2],
      addTotalRow: true,
      reportTitle: 'Production - Open Ageing Analysis',
    );
  }

  Future<void> generateAgeingOpenProductionPDF(
    AgeingAnalysisList ageingAnalysisList,
  ) async {
    await reportService.generatePDF(
      title: 'Production - Open Ageing Analysis',
      headers: ['Ageing', 'Planned Qty.'],
      rows: ageingAnalysisList.agingData
          .map((e) => [e.group, e.receivableAmount])
          .toList(),
      fileName: 'ageing_openproduction_report.pdf',
      amountColumns: [2],
    );
  }

  Future<void> generateItemOpenProductionExcel(
    ItemWiseProductionList itemWiseProductionList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'OpenItemWiseProduction',
      headers: ['Item Name', 'Production Qty.', 'Monthly Avg.'],
      rows: itemWiseProductionList.itemWiseData
          .map((e) => [e.itemName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'item_production_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Open Item Wise Analysis',
    );
  }

  Future<void> generateItemOpenProductionPDF(
    ItemWiseProductionList itemWiseProductionList,
  ) async {
    await reportService.generatePDF(
      title: 'Production - Open Item Wise Analysis',
      headers: ['Item Name', 'Production Qty.', 'Monthly Avg.'],
      rows: itemWiseProductionList.itemWiseData
          .map((e) => [e.itemName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'item_open_production_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateItemGroupOpenProductionExcel(
    ItemGroupWiseProductionList itemGroupWiseProductionList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'OpenItemGroupWiseProduction',
      headers: ['Item Group Name', 'Production Qty.', 'Monthly Avg.'],
      rows: itemGroupWiseProductionList.itemGroupWiseData
          .map((e) => [e.itemGroupName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'itemgroup_open_production_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Open Item Group Wise Analysis',
    );
  }

  Future<void> generateItemGroupOpenProductionPDF(
    ItemGroupWiseProductionList itemGroupWiseProductionList,
  ) async {
    await reportService.generatePDF(
      title: 'Production - Open Item Group Wise Analysis',
      headers: ['Item Group Name', 'Production Qty.', 'Monthly Avg.'],
      rows: itemGroupWiseProductionList.itemGroupWiseData
          .map((e) => [e.itemGroupName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'item_groupwise_open_production_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateItemSubGroupOpenProductionExcel(
    ItemSubGroupWiseProductionList itemSubGroupWiseProductionList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'OpenItemSubGroupWiseProduction',
      headers: ['Item Sub Group Name', 'Production Qty.', 'Monthly Avg.'],
      rows: itemSubGroupWiseProductionList.itemSubGroupWiseData
          .map(
            (e) => [e.itemSubGroupName, e.productionActual, e.production3Month],
          )
          .toList(),
      fileName: 'item_subgroup_open_production_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Open Item Sub Group Wise Analysis',
    );
  }

  Future<void> generateItemSubGroupOpenProductionPDF(
    ItemSubGroupWiseProductionList itemSubGroupWiseProductionList,
  ) async {
    await reportService.generatePDF(
      title: 'Production - Open Item Sub Group Wise Analysis',
      headers: ['Item Sub Group Name', 'Production Qty.', 'Monthly Avg.'],
      rows: itemSubGroupWiseProductionList.itemSubGroupWiseData
          .map(
            (e) => [e.itemSubGroupName, e.productionActual, e.production3Month],
          )
          .toList(),
      fileName: 'item_subgroup_open_production_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateBranchOpenProductionExcel(
    BranchWiseProductionList branchWiseProductionList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'OpenBranchProduction',
      headers: ['Branch Name', 'Production Qty.', 'Monthly Avg.'],
      rows: branchWiseProductionList.branchWiseData
          .map((e) => [e.branchName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'branch_open_production_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Open Branch Wise Analysis',
    );
  }

  Future<void> generateBranchOpenProductionPDF(
    BranchWiseProductionList branchWiseProductionList,
  ) async {
    await reportService.generatePDF(
      title: 'Production - Open Branch Wise Analysis',
      headers: ['Branch Name', 'Production Qty.', 'Monthly Avg.'],
      rows: branchWiseProductionList.branchWiseData
          .map((e) => [e.branchName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'branch_open_production_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generatePlantOpenProductionExcel(
    PlantWiseProductionList plantWiseProductionList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'OpenPlantProduction',
      headers: ['Plant Name', 'Production Qty.', 'Monthly Avg.'],
      rows: plantWiseProductionList.plantData
          .map((e) => [e.plantName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'plant_open_production_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Open Plant Wise Analysis',
    );
  }

  Future<void> generatePlantOpenProductionPDF(
    PlantWiseProductionList plantWiseProductionList,
  ) async {
    await reportService.generatePDF(
      title: 'Production - Open Plant Wise Analysis',
      headers: ['Plant Name', 'Production Qty.', 'Monthly Avg.'],
      rows: plantWiseProductionList.plantData
          .map((e) => [e.plantName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'plant_open_production_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateUnitOpenProductionExcel(
    UnitWiseProductionList unitWiseProductionList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'OpenUnitProduction',
      headers: ['Unit Name', 'Production Qty.', 'Monthly Avg.'],
      rows: unitWiseProductionList.unitData
          .map((e) => [e.unitName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'unit_open_production_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Open Unit Wise Analysis',
    );
  }

  Future<void> generateUnitOpenProductionPDF(
    UnitWiseProductionList unitWiseProductionList,
  ) async {
    await reportService.generatePDF(
      title: 'Production - Open Unit Wise Analysis',
      headers: ['Unit Name', 'Production Qty.', 'Monthly Avg.'],
      rows: unitWiseProductionList.unitData
          .map((e) => [e.unitName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'unit_open _production_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateShiftOpenProductionExcel(
    ShiftWiseProductionList shiftWiseProductionList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'OpenShiftProduction',
      headers: ['Shift Name', 'Production Qty.', 'Monthly Avg.'],
      rows: shiftWiseProductionList.shiftData
          .map((e) => [e.shiftName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'shift_open_production_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Open Shift Wise Analysis',
    );
  }

  Future<void> generateShiftOpenProductionPDF(
    ShiftWiseProductionList shiftWiseProductionList,
  ) async {
    await reportService.generatePDF(
      title: 'Production - Open Shift Wise Analysis',
      headers: ['Shift Name', 'Production Qty.', 'Monthly Avg.'],
      rows: shiftWiseProductionList.shiftData
          .map((e) => [e.shiftName, e.productionActual, e.production3Month])
          .toList(),
      fileName: 'shift_open_production_report.pdf',
      amountColumns: [2, 3],
    );
  }

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
    client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final screenWidth = media.width;

    return chartDataLoaded == true
        ? ListView(
            padding: EdgeInsets.zero,
            children: [
              Column(
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
                            "Ageing Analysis",
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
                                    await generateAgeingOpenProductionExcel(
                                      ageingAnalysisList,
                                    );
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () async {
                                    await generateAgeingOpenProductionPDF(
                                      ageingAnalysisList,
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
                    child: _ageingAnalysis(screenWidth),
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
                                  onTap: () async {
                                    await generateItemOpenProductionExcel(
                                      itemWiseData,
                                    );
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () async {
                                    await generateItemOpenProductionPDF(
                                      itemWiseData,
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
                    child: _itemWiseProductionOrders(screenWidth),
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
                                  onTap: () async {
                                    await generateBranchOpenProductionExcel(
                                      branchWiseData,
                                    );
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () async {
                                    await generateBranchOpenProductionPDF(
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
                    child: _branchWiseProductionOrders(screenWidth),
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
                                  onTap: () async {
                                    await generateItemGroupOpenProductionExcel(
                                      itemGroupWiseData,
                                    );
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () async {
                                    await generateItemGroupOpenProductionPDF(
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
                    child: _itemGroupWiseAnalysis(screenWidth),
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
                                  onTap: () async {
                                    await generateItemSubGroupOpenProductionExcel(
                                      itemSubGroupWiseData,
                                    );
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () async {
                                    await generateItemSubGroupOpenProductionPDF(
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
                    child: _itemSubGroupWiseAnalysis(screenWidth),
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
                                    await generatePlantOpenProductionExcel(
                                      plantWiseData,
                                    );
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () async {
                                    await generatePlantOpenProductionPDF(
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
                    child: _plantWiseAnalysis(screenWidth),
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
                                  onTap: () async {
                                    await generateUnitOpenProductionExcel(
                                      unitWiseData,
                                    );
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () async {
                                    await generateUnitOpenProductionPDF(
                                      unitWiseData,
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
                    child: _unitWiseAnalysis(screenWidth),
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
                                  onTap: () async {
                                    generateShiftOpenProductionExcel(
                                      shiftWiseData,
                                    );
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () async {
                                    await generateShiftOpenProductionPDF(
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
                    child: _shiftWiseAnalysis(screenWidth),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0, right: 16.0),
                    child: Divider(thickness: 2),
                  ),
                ],
              ),
            ],
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
        loadDataFuture = removeFilter();

        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  Widget _ageingAnalysis(double screenWidth) {
    double chartWidth = 0.0;
    int len = ageingAnalysisList.agingData.length;
    if (ageingAnalysisList.agingData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    return RepaintBoundary(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          height: 350,
          width: chartWidth,
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(ageingMaxY),
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
                  sideTitles: _bottomTitlesAgeingAnalysis,
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
              barGroups: _ageingAnalysisChartData(ageingAnalysisList.agingData),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedAgingCatg = touchedAgingCatg == ""
                          ? ageingAnalysisList
                                .agingData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .group
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      loadDataWithFilter(
                        touchedAgingCatg,
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
                      '${ageingAnalysisList.agingData[grpIndex].group}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "Planned Qty. : ${ageingAnalysisList.agingData[grpIndex].receivableAmount}",
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
    return RepaintBoundary(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          height: 350,
          width: chartWidth,
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
                        touchedAgingCatg,
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
                              "Planned Qty. : ${formatAmount(itemWiseData.itemWiseData[grpIndex].productionActual)}\n",
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
    return RepaintBoundary(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          height: 350,
          width: chartWidth,
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
                        touchedAgingCatg,
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
                              "Planned Qty. : ${formatAmount(branchWiseData.branchWiseData[grpIndex].productionActual)}\n",
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
    return RepaintBoundary(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          height: 350,
          width: chartWidth,
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
                        touchedAgingCatg,
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
                              "Planned Qty. : ${formatAmount(itemGroupWiseData.itemGroupWiseData[grpIndex].productionActual)}\n",
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
    return RepaintBoundary(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          height: 350,
          width: chartWidth,
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
                        touchedAgingCatg,
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
                              "Planned Qty. : ${formatAmount(itemSubGroupWiseData.itemSubGroupWiseData[grpIndex].productionActual)}\n",
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
    return RepaintBoundary(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          height: 350,
          width: chartWidth,
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
                        touchedAgingCatg,
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
                              "Planned Qty. : ${formatAmount(plantWiseData.plantData[grpIndex].productionActual)}\n",
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
    return RepaintBoundary(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          height: 350,
          width: chartWidth,
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
                        touchedAgingCatg,
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
                              "Planned Qty. : ${formatAmount(unitWiseData.unitData[grpIndex].productionActual)}\n",
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
    return RepaintBoundary(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          height: 350,
          width: chartWidth,
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
                        touchedAgingCatg,
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
                              "Planned Qty. :${formatAmount(shiftWiseData.shiftData[grpIndex].productionActual)}\n",
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
