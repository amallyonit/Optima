// ignore_for_file: non_constant_identifier_names, file_names, use_build_context_synchronously, strict_top_level_inference
import 'package:optima/excel_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
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

class POAnalysis extends StatefulWidget {
  const POAnalysis({super.key});

  @override
  State<POAnalysis> createState() => _POAnalysisState();
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

bool chartDataLoaded = false;

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
String selectedUser = '';
String UserLevel = '';

String currentMonthHalfPieStr = "";
String lastMonthHalfPieStr = "";
String ytdHalfPieStr = "";
int currentMonthPercentage = 0;
int lastMonthPercentage = 0;
int ytdPercentage = 0;

ReceivablesFinanceList receivablesFinanceList = ReceivablesFinanceList(
  agingData: [],
);

List<POList> poList = [];
List<POList> poListOpen = [];
List<Users> usersList = [];

POMonthWiseList monthData = POMonthWiseList(monthlyData: []);
OpenPOAgingList openPoAgingData = OpenPOAgingList(soAgingData: []);
POItemAnalysisList itemData = POItemAnalysisList(productData: []);
POItemGroupWiseAnalysisList itemGroupData = POItemGroupWiseAnalysisList(
  productData: [],
);
POItemSubGroupWiseAnalysisList itemSubGroupData =
    POItemSubGroupWiseAnalysisList(productData: []);
POBranchAnalysisList branchData = POBranchAnalysisList(branchData: []);
POWarehouseWiseAnalysisList warehouseData = POWarehouseWiseAnalysisList(
  warehouseData: [],
);
POSupplierAnalysisList supplierData = POSupplierAnalysisList(supplierData: []);
POSupplierStateWiseAnalysisList supplierStateData =
    POSupplierStateWiseAnalysisList(supplierStateData: []);
POSupplierCityWiseAnalysisList supplierCityData =
    POSupplierCityWiseAnalysisList(supplierCityData: []);

int touchedMonthIndex = 0;
String touchedAgingCatg = "";
String touchedMonth = "";
String touchedItemCode = "";
String touchedItemGroup = "";
String touchedItemSubGroup = "";
String touchedBranchName = "";
String touchedWarehouse = "";
String touchedSupplierCode = "";
String touchedSupplierState = "";
String touchedSupplierCity = "";
String touchedSupplierCategory = "";
double selectedChart = 0;

final List<String> categories = ['Status', 'Date'];

List<List<String>> filterOptions = [listOfString, []];

List<String> listOfRSM = [];
List<String> listOfASM = [];
List<String> listOfTSM = [];
List<String> listOfString = [];

bool fromFilter = false;

int selectedCategoryIndex = 0;

List<List<bool>> selectedFinanceReceivablesOptions = [];

List<List<bool>> savedFinanceReceivablesOptionsTemp = [];

List<List<bool>> savedFinanceReceivablesOptions = filterOptions
    .map((options) => List<bool>.filled(options.length, false))
    .toList();

Map<String, Map<String, bool>> allCategoriesState = {};

List<String> selectedSalesData = [];

DateTime? fromDateFilter;
DateTime? toDateFilter;
bool dateFilterFlag = false;

class PurchasePOAnalysisProvider with ChangeNotifier {
  List<POList> _salesList = [];
  List<POList> get salesList => _salesList;
  void updatePOList(List<POList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class _POAnalysisState extends State<POAnalysis> {
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

  SideTitles get _monthlyBottomTitles =>
      SideTitles(showTitles: true, getTitlesWidget: getMonthwiseBottomTitles);

  Widget getMonthwiseBottomTitles(double val, TitleMeta meta) {
    String text = '';
    POMonthWiseData monthlyPoData = monthData.monthlyData.elementAt(
      val.toInt(),
    );
    text = monthlyPoData.monthName;
    return Text(text.length > 3 ? text.substring(0, 3) : text);
  }

  SideTitles get _leftTitles => SideTitles(
    reservedSize: 60,
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

  SideTitles get _bottomTitlesOpenPOAging => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<OpenPOAgingData> mData = openPoAgingData.soAgingData;
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

  SideTitles get _bottomTitlesItemAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<POItemAnalysisData> mData = itemData.productData;
      text = mData.elementAt(value.toInt()).productName;
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
      List<POItemGroupWiseAnalysisData> mData = itemGroupData.productData;
      text = mData.elementAt(value.toInt()).productGroupName;
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
      List<POItemSubGroupWiseAnalysisData> mData = itemSubGroupData.productData;
      text = mData.elementAt(value.toInt()).productSubGroupName;
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

  SideTitles get _bottomTitlesBranchAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<POBranchAnalysisData> mData = branchData.branchData;
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

  SideTitles get _bottomTitlesWarehouseWiseAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<POWarehouseWiseAnalysisData> mData = warehouseData.warehouseData;
      text = mData.elementAt(value.toInt()).warehouseName;
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

  SideTitles get _bottomTitlesSupplierAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<POSupplierAnalysisData> mData = supplierData.supplierData;
      text = mData.elementAt(value.toInt()).supplierName;
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

  SideTitles get _bottomTitlesSupplierStateWiseAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<POSupplierStateWiseAnalysisData> mData =
          supplierStateData.supplierStateData;
      text = mData.elementAt(value.toInt()).supplierStateName;
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

  SideTitles get _bottomTitlesSupplierCityWiseAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<POSupplierCityWiseAnalysisData> mData =
          supplierCityData.supplierCityData;
      text = mData.elementAt(value.toInt()).supplierCityName;
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

  List<BarChartGroupData> _openPOAgingChartData(List<OpenPOAgingData> data) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.receivableAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _monthWisePOAnalysisChartData(
    List<POMonthWiseData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.collectionAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _itemAnalysisChartData(
    List<POItemAnalysisData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _itemGroupWiseAnalysisChartData(
    List<POItemGroupWiseAnalysisData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _itemSubGroupWiseAnalysisChartData(
    List<POItemSubGroupWiseAnalysisData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _branchAnalysisChartData(
    List<POBranchAnalysisData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _warehouseWiseAnalysisChartData(
    List<POWarehouseWiseAnalysisData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _supplierAnalysisChartData(
    List<POSupplierAnalysisData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _supplierStateWiseAnalysisChartData(
    List<POSupplierStateWiseAnalysisData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _supplierCityWiseAnalysisChartData(
    List<POSupplierCityWiseAnalysisData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.salesAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  Future<void> _loadPOList(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000; // Maximum limit to fetch all data
    int fetchedCount = 0;
    List<POList> salesList = [];
    int monthIndex = currentDate!.month;
    try {
      do {
        var body = {
          "FromDate": formatDate(
            monthIndex == 4 ? lastMonthFromDate! : fiscalYearStartDate!,
          ),
          "ToDate": formatDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}BicxoPOList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            // HttpHeaders.authorizationHeader:
            //     'Bearer    ${DataManager.readSapToken()}'
          },
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<POList> newSalesList = (responseJson['responseData'] as List)
                .map((item) => POList.fromJson(item))
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
        poList = salesList;
        context.read<PurchasePOAnalysisProvider>().updatePOList(salesList);
        poList = salesList
            .where((sale) => sale.type == "Item Purchase")
            .toList();
        poListOpen = salesList
            .where(
              (sale) => sale.type == "Item Purchase" && sale.poStatus == "Open",
            )
            .toList();

        if (listOfString.isEmpty) {
          listOfString = List<String>.from(
            poList.map((e) => e.poStatus).toSet(),
          );
        }
      });

      List<POList> filteredList = [];

      List<String> trueStatusOptions = (allCategoriesState['Status'] ?? {})
          .entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      if (trueStatusOptions.isNotEmpty) {
        filteredList = poList
            .where((person) => trueStatusOptions.contains(person.poStatus))
            .toList();
        poList = filteredList;
      }

      var currentMonthSales = poListOpen.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return invoiceDate.isAtLeast(currentMonthFromDate!) &&
            invoiceDate.isAtMost(currentDate!);
      });

      var lastMonthSales = poListOpen.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return invoiceDate.isAtLeast(lastMonthFromDate!) &&
            invoiceDate.isAtMost(lastMonthToDate!);
      });

      var ytdSales = poListOpen.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return invoiceDate.isAtLeast(fiscalYearStartDate!) &&
            invoiceDate.isAtMost(currentDate!);
      });

      double currentMonthHalfPie = 0;
      double lastMonthHalfPie = 0;
      double ytdHalfPie = 0;

      for (var target in currentMonthSales.toList()) {
        double balance = double.tryParse(target.pendingValue) ?? 0;
        double balanceAbs = balance.abs();
        currentMonthHalfPie += balanceAbs;
      }

      for (var target in lastMonthSales.toList()) {
        double balance = double.tryParse(target.pendingValue) ?? 0;
        double balanceAbs = balance.abs();
        lastMonthHalfPie += balanceAbs;
      }

      for (var target in ytdSales.toList()) {
        double balance = double.tryParse(target.pendingValue) ?? 0;
        double balanceAbs = balance.abs();
        ytdHalfPie += balanceAbs;
      }

      currentMonthHalfPieStr = formatAmount(currentMonthHalfPie);
      lastMonthHalfPieStr = formatAmount(lastMonthHalfPie);
      ytdHalfPieStr = formatAmount(ytdHalfPie);

      currentMonthPercentage =
          double.tryParse(
            ((currentMonthHalfPie / (1000000)) * 100).toStringAsFixed(2),
          )?.ceil() ??
          0;
      if (currentMonthPercentage > 100) {
        currentMonthPercentage = 100;
      }

      lastMonthPercentage =
          double.tryParse(
            ((lastMonthHalfPie / (1000000)) * 100).toStringAsFixed(2),
          )?.ceil() ??
          0;
      if (lastMonthPercentage > 100) {
        lastMonthPercentage = 100;
      }

      ytdPercentage =
          double.tryParse(
            ((ytdHalfPie / (1000000)) * 100).toStringAsFixed(2),
          )?.ceil() ??
          0;
      if (ytdPercentage > 100) {
        ytdPercentage = 100;
      }
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadOpenPOAging(
    int monthIndex,
    String agingCatg,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String branchName,
    String warehouseName,
    String supplierCode,
    String supplierState,
    String supplierCity,
  ) async {
    List<OpenPOAgingData> openPOAgingDataList = [];
    var soAgingList = poListOpen;
    double amount0to30 = 0.0;
    double amount31to60 = 0.0;
    double amount61to120 = 0.0;
    double amount121to180 = 0.0;
    double amount181a = 0.0;
    double maxY = 0;
    var productSalesList = const Iterable.empty();
    var saleList = const Iterable.empty();
    DateTime startDate;
    DateTime endDate;

    if (monthIndex == 0) {
      startDate = fiscalYearStartDate!;
      endDate = currentDate!;
      productSalesList = soAgingList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return (invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate));
      });
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      productSalesList = soAgingList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }

    saleList = filterPurchaseList(
      productSalesList.cast<POList>().toList(),
      agingCatg: agingCatg,
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
    );

    for (var product in saleList.toList()) {
      var overDueDays = product.overDueDays;
      var orderValue = product.pendingValue;

      var parsedOverDueDays = double.tryParse(overDueDays) ?? 0;
      var parsedOrderValue = double.tryParse(orderValue) ?? 0;
      if (parsedOverDueDays <= 30) {
        amount0to30 += parsedOrderValue;
      } else if (parsedOverDueDays >= 31 && parsedOverDueDays <= 60) {
        amount31to60 += parsedOrderValue;
      } else if (parsedOverDueDays >= 61 && parsedOverDueDays <= 120) {
        amount61to120 += parsedOrderValue;
      } else if (parsedOverDueDays >= 121 && parsedOverDueDays <= 180) {
        amount121to180 += parsedOrderValue;
      } else if (parsedOverDueDays >= 181) {
        amount181a += parsedOrderValue;
      }
    }
    if (amount0to30 > maxY) {
      maxY = amount0to30;
    }
    if (amount31to60 > maxY) {
      maxY = amount31to60;
    }
    if (amount61to120 > maxY) {
      maxY = amount61to120;
    }
    if (amount121to180 > maxY) {
      maxY = amount121to180;
    }
    if (amount181a > maxY) {
      maxY = amount181a;
    }

    maxY = ((maxY ~/ 100000) + 1) * 100000;
    openPOAgingDataList.add(
      OpenPOAgingData(
        receivableAmount: amount0to30,
        percentage: 0,
        group: "0-30",
        maxY: maxY,
      ),
    );
    openPOAgingDataList.add(
      OpenPOAgingData(
        receivableAmount: amount31to60,
        percentage: 0,
        group: "31-60",
        maxY: maxY,
      ),
    );
    openPOAgingDataList.add(
      OpenPOAgingData(
        receivableAmount: amount61to120,
        percentage: 0,
        group: "61-120",
        maxY: maxY,
      ),
    );
    openPOAgingDataList.add(
      OpenPOAgingData(
        receivableAmount: amount121to180,
        percentage: 0,
        group: "121-180",
        maxY: maxY,
      ),
    );
    openPOAgingDataList.add(
      OpenPOAgingData(
        receivableAmount: amount181a,
        percentage: 0,
        group: "181+",
        maxY: maxY,
      ),
    );

    openPoAgingData = OpenPOAgingList(soAgingData: openPOAgingDataList);
  }

  Future<void> _loadMonthWisePOAnalysis() async {
    List<POMonthWiseData> monthlyDataList = [];
    var inventoryList = poList;
    int currentYear = DateTime.now().year;
    DateTime startDate;
    DateTime endDate;
    for (int i = 4; i <= 15; i++) {
      String monthName = getMonthName(i);
      double monthlySales = 0.00;

      var monthlySalesList = const Iterable.empty();
      if (i >= 4 && i <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(i);
        monthlySalesList = inventoryList.where((target) {
          DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
          return invoiceDate.isAtLeast(monthDates['start']!) &&
              invoiceDate.isAtMost(monthDates['end']!);
        });
      } else {
        startDate = DateTime(currentYear, i - 12, 1);
        endDate = DateTime(currentYear, (i - 12) + 1, 0);
        monthlySalesList = inventoryList.where((target) {
          DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
          return invoiceDate.isAtLeast(startDate) &&
              invoiceDate.isAtMost(endDate);
        });
      }
      double salesAmt = 0;
      for (var target in monthlySalesList.toList()) {
        salesAmt = (double.tryParse(target.orderValue) ?? 0);
        monthlySales += salesAmt;
      }
      monthlyDataList.add(
        POMonthWiseData(monthName: monthName, collectionAmount: monthlySales),
      );
      monthlySales = 0;
    }
    monthData = POMonthWiseList(monthlyData: monthlyDataList);
  }

  Future<void> _loadItemAnalysis(
    int monthIndex,
    String agingCatg,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String branchName,
    String warehouseName,
    String supplierCode,
    String supplierState,
    String supplierCity,
  ) async {
    List<POItemAnalysisData> productwiseDataList = [];
    var tempList = poList;
    var productSalesList = const Iterable.empty();
    var curMthSalesTarget = const Iterable.empty();
    var saleList = const Iterable.empty();
    var saleList3Months = const Iterable.empty();
    DateTime startDate;
    DateTime endDate;
    String itemName = "";
    double productSales = 0.00;
    double productTarget = 0.00;
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

    if (monthIndex == 0) {
      startDate = fiscalYearStartDate!;
      endDate = currentDate!;
      curMthSalesTarget = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate));
      });

      productSalesList = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
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

      curMthSalesTarget = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate);
      });

      productSalesList = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }
    saleList = filterPurchaseList(
      productSalesList.cast<POList>().toList(),
      agingCatg: agingCatg,
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
    );
    saleList3Months = filterPurchaseList(
      curMthSalesTarget.cast<POList>().toList(),
      agingCatg: agingCatg,
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
    );

    Set<String> processedProductCodes = {};
    for (var product in saleList.toList().toList()) {
      if (!processedProductCodes.contains(product.description)) {
        itemName = product.description;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.description == itemName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.orderValue) ?? 0;
          productSales += salesAmt;
        }
        for (var target in saleList3Months.toList().where(
          (element) => element.description == itemName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.orderValue) ?? 0;
          productTarget += salesAmt;
        }

        productwiseDataList.add(
          POItemAnalysisData(
            productName: itemName,
            salesAmount: productSales,
            monthsAvg: productTarget / 3,
          ),
        );
        processedProductCodes.add(product.description);
      }
      productSales = 0;
      productTarget = 0;
      itemName = "";
    }
    productwiseDataList.sort((a, b) => b.salesAmount.compareTo(a.salesAmount));
    itemData = POItemAnalysisList(productData: productwiseDataList);
  }

  Future<void> _loadItemGroupWiseAnalysis(
    int monthIndex,
    String agingCatg,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String branchName,
    String warehouseName,
    String supplierCode,
    String supplierState,
    String supplierCity,
  ) async {
    List<POItemGroupWiseAnalysisData> productwiseDataList = [];
    var tempList = poList;
    String groupName = "";
    double productSales = 0.00;
    var productSalesList = const Iterable.empty();
    var saleList = const Iterable.empty();
    DateTime startDate;
    DateTime endDate;

    if (monthIndex == 0) {
      startDate = fiscalYearStartDate!;
      endDate = currentDate!;
      productSalesList = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return (invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate));
      });
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      productSalesList = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }

    saleList = filterPurchaseList(
      productSalesList.cast<POList>().toList(),
      agingCatg: agingCatg,
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
    );

    Set<String> processedGroups = {};
    for (var product in saleList.toList()) {
      if (!processedGroups.contains(product.groupName)) {
        groupName = product.groupName;
        for (var target in productSalesList.toList().where(
          (prdelement) => prdelement.groupName == groupName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.orderValue) ?? 0;
          productSales += salesAmt;
        }

        productwiseDataList.add(
          POItemGroupWiseAnalysisData(
            productGroupName: groupName,
            salesAmount: productSales,
            monthsAvg: productSales / 3,
          ),
        );
        processedGroups.add(product.groupName);
      }
      productSales = 0;
      groupName = "";
    }
    productwiseDataList.sort((a, b) => b.salesAmount.compareTo(a.salesAmount));

    itemGroupData = POItemGroupWiseAnalysisList(
      productData: productwiseDataList,
    );
  }

  Future<void> _loadItemSubGroupWiseAnalysis(
    int monthIndex,
    String agingCatg,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String branchName,
    String warehouseName,
    String supplierCode,
    String supplierState,
    String supplierCity,
  ) async {
    List<POItemSubGroupWiseAnalysisData> productwiseDataList = [];
    var tempList = poList;
    String itemSubGroup = "";
    double productSales = 0.00;

    var productSalesList = const Iterable.empty();
    var saleList = const Iterable.empty();
    DateTime startDate;
    DateTime endDate;

    if (monthIndex == 0) {
      startDate = fiscalYearStartDate!;
      endDate = currentDate!;
      productSalesList = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return (invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate));
      });
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      productSalesList = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }
    saleList = filterPurchaseList(
      productSalesList.cast<POList>().toList(),
      agingCatg: agingCatg,
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
    );

    Set<String> processedSubGroups = {};
    for (var product in saleList.toList().toList()) {
      if (!processedSubGroups.contains(product.itemSubGroup)) {
        itemSubGroup = product.itemSubGroup;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.itemSubGroup == itemSubGroup,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.orderValue) ?? 0;
          productSales += salesAmt;
        }

        productwiseDataList.add(
          POItemSubGroupWiseAnalysisData(
            productSubGroupName: itemSubGroup,
            salesAmount: productSales,
            monthsAvg: productSales / 3,
          ),
        );
        processedSubGroups.add(product.itemSubGroup);
      }
      productSales = 0;
      itemSubGroup = "";
    }
    productwiseDataList.sort((a, b) => b.salesAmount.compareTo(a.salesAmount));

    itemSubGroupData = POItemSubGroupWiseAnalysisList(
      productData: productwiseDataList,
    );
  }

  Future<void> _loadBranch(
    int monthIndex,
    String agingCatg,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String branchName,
    String warehouseName,
    String supplierCode,
    String supplierState,
    String supplierCity,
  ) async {
    List<POBranchAnalysisData> branchDetail = [];
    var tempList = poList;
    String branchName = "";
    var productSalesList = const Iterable.empty();
    var curMthSalesTarget = const Iterable.empty();
    var saleList = const Iterable.empty();
    var saleList3Months = const Iterable.empty();
    DateTime startDate;
    DateTime endDate;
    double productSales = 0.00;
    double productTarget = 0.00;
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

    if (monthIndex == 0) {
      startDate = fiscalYearStartDate!;
      endDate = currentDate!;
      curMthSalesTarget = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate));
      });

      productSalesList = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
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
      curMthSalesTarget = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate);
      });

      productSalesList = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }
    saleList = filterPurchaseList(
      productSalesList.cast<POList>().toList(),
      agingCatg: agingCatg,
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
    );
    saleList3Months = filterPurchaseList(
      curMthSalesTarget.cast<POList>().toList(),
      agingCatg: agingCatg,
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
    );

    Set<String> processedBranches = {};
    for (var product in saleList.toList().toList()) {
      if (!processedBranches.contains(product.branchName)) {
        branchName = product.branchName;
        for (var target in productSalesList.toList().where(
          (prdelement) => prdelement.branchName == branchName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.orderValue) ?? 0;
          productSales += salesAmt;
        }
        for (var target in saleList3Months.toList().where(
          (element) => element.branchName == branchName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.orderValue) ?? 0;
          productTarget += salesAmt;
        }

        branchDetail.add(
          POBranchAnalysisData(
            branchName: branchName,
            salesAmount: productSales,
            monthsAvg: productTarget / 3,
          ),
        );
        processedBranches.add(product.branchName);
      }
      productSales = 0;
      productTarget = 0;
      branchName = "";
    }
    branchDetail.sort((a, b) => b.salesAmount.compareTo(a.salesAmount));
    branchData = POBranchAnalysisList(branchData: branchDetail);
  }

  Future<void> _loadWarehouseAnalysis(
    int monthIndex,
    String agingCatg,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String branchName,
    String warehouseName,
    String supplierCode,
    String supplierState,
    String supplierCity,
  ) async {
    List<POWarehouseWiseAnalysisData> warehouseDetail = [];
    var tempList = poList;
    String warehouseCode = "";
    var productSalesList = const Iterable.empty();
    var curMthSalesTarget = const Iterable.empty();
    var saleList = const Iterable.empty();
    var saleList3Months = const Iterable.empty();
    DateTime startDate;
    DateTime endDate;
    double productSales = 0.00;
    double productTarget = 0.00;
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

    if (monthIndex == 0) {
      startDate = fiscalYearStartDate!;
      endDate = currentDate!;
      curMthSalesTarget = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate));
      });

      productSalesList = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
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
      curMthSalesTarget = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate);
      });

      productSalesList = tempList.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }

    saleList = filterPurchaseList(
      productSalesList.cast<POList>().toList(),
      agingCatg: agingCatg,
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
    );
    saleList3Months = filterPurchaseList(
      curMthSalesTarget.cast<POList>().toList(),
      agingCatg: agingCatg,
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
    );

    Set<String> processedBranches = {};
    for (var product in saleList.toList().toList()) {
      if (!processedBranches.contains(product.warehouse)) {
        warehouseCode = product.warehouse;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.warehouse == warehouseCode,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.orderValue) ?? 0;
          productSales += salesAmt;
        }
        for (var target in saleList3Months.toList().where(
          (element) => element.warehouse == warehouseCode,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.orderValue) ?? 0;
          productTarget += salesAmt;
        }

        warehouseDetail.add(
          POWarehouseWiseAnalysisData(
            warehouseName: warehouseCode,
            salesAmount: productSales,
            monthsAvg: productTarget / 3,
          ),
        );
        processedBranches.add(product.warehouse);
      }
      productSales = 0;
      productTarget = 0;
      warehouseCode = "";
    }
    warehouseDetail.sort((a, b) => b.salesAmount.compareTo(a.salesAmount));
    warehouseData = POWarehouseWiseAnalysisList(warehouseData: warehouseDetail);
  }

  Future<void> _loadSupplierAnalysis(
    int monthIndex,
    String agingCatg,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String branchName,
    String warehouseName,
    String supplierCode,
    String supplierState,
    String supplierCity,
  ) async {
    List<POSupplierAnalysisData> productwiseDataList = [];

    var tempList = filterPurchaseList(
      poList.cast<POList>().toList(),
      agingCatg: agingCatg,
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
    );
    DateTime startDate;
    DateTime endDate;
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

    Map<String, double> vendorSalesMap = {};
    Map<String, double> vendorTargetMap = {};
    if (monthIndex == 0) {
      startDate = fiscalYearStartDate!;
      endDate = currentDate!;
      for (var target in tempList) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        if (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate)) {
          double salesAmt = double.tryParse(target.orderValue) ?? 0;
          vendorTargetMap.update(
            target.vendorName,
            (existingTarget) => existingTarget + salesAmt,
            ifAbsent: () => salesAmt,
          );
        }
      }
      for (var target in tempList) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        if (invoiceDate.isAtLeast(startDate) && invoiceDate.isAtMost(endDate)) {
          double salesAmt = double.tryParse(target.orderValue) ?? 0;
          vendorSalesMap.update(
            target.vendorName,
            (existingSales) => existingSales + salesAmt,
            ifAbsent: () => salesAmt,
          );
        }
      }
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      prevThreethFromDate = addMonth(monthDates['start']!, -3);
      prevThreeMthToDate = addMonth(
        prevThreethFromDate,
        3,
      ).add(const Duration(days: -1));
      for (var target in tempList) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        if (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate)) {
          double salesAmt = double.tryParse(target.orderValue) ?? 0;
          vendorTargetMap.update(
            target.vendorName,
            (existingTarget) => existingTarget + salesAmt,
            ifAbsent: () => salesAmt,
          );
        }
      }
      for (var target in tempList) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        if (invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!)) {
          double salesAmt = double.tryParse(target.orderValue) ?? 0;
          vendorSalesMap.update(
            target.vendorName,
            (existingSales) => existingSales + salesAmt,
            ifAbsent: () => salesAmt,
          );
        }
      }
    }

    vendorSalesMap.forEach((vendorName, productSales) {
      double productTarget = vendorTargetMap[vendorName] ?? 0.0;
      productwiseDataList.add(
        POSupplierAnalysisData(
          supplierName: vendorName,
          salesAmount: productSales,
          monthsAvg: productTarget / 3,
        ),
      );
    });

    productwiseDataList.sort((a, b) => b.salesAmount.compareTo(a.salesAmount));
    supplierData = POSupplierAnalysisList(supplierData: productwiseDataList);
  }

  Future<void> _loadSupplierStateWiseAnalysis(
    int monthIndex,
    String agingCatg,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String branchName,
    String warehouseName,
    String supplierCode,
    String supplierState,
    String supplierCity,
  ) async {
    List<POSupplierStateWiseAnalysisData> productwiseDataList = [];
    var tempList = filterPurchaseList(
      poList.cast<POList>().toList(),
      agingCatg: agingCatg,
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
    );

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

    Map<String, double> vendorSalesMap = {};
    Map<String, double> vendorTargetMap = {};
    DateTime startDate;
    DateTime endDate;

    if (monthIndex == 0) {
      startDate = fiscalYearStartDate!;
      endDate = currentDate!;
      for (var target in tempList) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        if (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate)) {
          double salesAmt = double.tryParse(target.orderValue) ?? 0;
          vendorTargetMap.update(
            target.vendorState,
            (existingTarget) => existingTarget + salesAmt,
            ifAbsent: () => salesAmt,
          );
        }
      }
      for (var target in tempList) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        if (invoiceDate.isAtLeast(startDate) && invoiceDate.isAtMost(endDate)) {
          double salesAmt = double.tryParse(target.orderValue) ?? 0;
          vendorSalesMap.update(
            target.vendorState,
            (existingSales) => existingSales + salesAmt,
            ifAbsent: () => salesAmt,
          );
        }
      }
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      prevThreethFromDate = addMonth(monthDates['start']!, -3);
      prevThreeMthToDate = addMonth(
        prevThreethFromDate,
        3,
      ).add(const Duration(days: -1));
      for (var target in tempList) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        if (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate)) {
          double salesAmt = double.tryParse(target.orderValue) ?? 0;
          vendorTargetMap.update(
            target.vendorState,
            (existingTarget) => existingTarget + salesAmt,
            ifAbsent: () => salesAmt,
          );
        }
      }
      for (var target in tempList) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        if (invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!)) {
          double salesAmt = double.tryParse(target.orderValue) ?? 0;
          vendorSalesMap.update(
            target.vendorState,
            (existingSales) => existingSales + salesAmt,
            ifAbsent: () => salesAmt,
          );
        }
      }
    }

    vendorSalesMap.forEach((vendorState, productSales) {
      double productTarget = vendorTargetMap[vendorState] ?? 0.0;
      productwiseDataList.add(
        POSupplierStateWiseAnalysisData(
          supplierStateName: vendorState,
          salesAmount: productSales,
          monthsAvg: productTarget / 3,
        ),
      );
    });

    productwiseDataList.sort((a, b) => b.salesAmount.compareTo(a.salesAmount));
    supplierStateData = POSupplierStateWiseAnalysisList(
      supplierStateData: productwiseDataList,
    );
  }

  Future<void> _loadSupplierCityWiseAnalysis(
    int monthIndex,
    String agingCatg,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String branchName,
    String warehouseName,
    String supplierCode,
    String supplierState,
    String supplierCity,
  ) async {
    List<POSupplierCityWiseAnalysisData> productwiseDataList = [];
    var tempList = filterPurchaseList(
      poList.cast<POList>().toList(),
      agingCatg: agingCatg,
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
    );

    // Define the date range
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

    // Create maps to store the sales and target data for each city
    Map<String, double> citySalesMap = {};
    Map<String, double> cityTargetMap = {};

    DateTime startDate;
    DateTime endDate;

    if (monthIndex == 0) {
      startDate = fiscalYearStartDate!;
      endDate = currentDate!;
      for (var target in tempList) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        if (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate)) {
          double salesAmt = double.tryParse(target.orderValue) ?? 0;
          cityTargetMap.update(
            target.vendorCity,
            (existingTarget) => existingTarget + salesAmt,
            ifAbsent: () => salesAmt,
          );
        }
      }
      for (var target in tempList) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        if (invoiceDate.isAtLeast(startDate) && invoiceDate.isAtMost(endDate)) {
          double salesAmt = double.tryParse(target.orderValue) ?? 0;
          citySalesMap.update(
            target.vendorCity,
            (existingSales) => existingSales + salesAmt,
            ifAbsent: () => salesAmt,
          );
        }
      }
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      prevThreethFromDate = addMonth(monthDates['start']!, -3);
      prevThreeMthToDate = addMonth(
        prevThreethFromDate,
        3,
      ).add(const Duration(days: -1));
      for (var target in tempList) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        if (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate)) {
          double salesAmt = double.tryParse(target.orderValue) ?? 0;
          cityTargetMap.update(
            target.vendorCity,
            (existingTarget) => existingTarget + salesAmt,
            ifAbsent: () => salesAmt,
          );
        }
      }
      for (var target in tempList) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        if (invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!)) {
          double salesAmt = double.tryParse(target.orderValue) ?? 0;
          citySalesMap.update(
            target.vendorCity,
            (existingSales) => existingSales + salesAmt,
            ifAbsent: () => salesAmt,
          );
        }
      }
    }

    citySalesMap.forEach((vendorCity, productSales) {
      double productTarget = cityTargetMap[vendorCity] ?? 0.0;
      productwiseDataList.add(
        POSupplierCityWiseAnalysisData(
          supplierCityName: vendorCity,
          salesAmount: productSales,
          monthsAvg: productTarget / 3,
        ),
      );
    });

    // Sort the result by total sales
    productwiseDataList.sort((a, b) => b.salesAmount.compareTo(a.salesAmount));

    supplierCityData = POSupplierCityWiseAnalysisList(
      supplierCityData: productwiseDataList,
    );
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadPOList(userName, userLevel);
    await _loadOpenPOAging(0, "", "", "", "", "", "", "", "", "");
    await _loadMonthWisePOAnalysis();
    await _loadItemAnalysis(0, "", "", "", "", "", "", "", "", "");
    await _loadItemGroupWiseAnalysis(0, "", "", "", "", "", "", "", "", "");
    await _loadItemSubGroupWiseAnalysis(0, "", "", "", "", "", "", "", "", "");
    await _loadBranch(0, "", "", "", "", "", "", "", "", "");
    await _loadWarehouseAnalysis(0, "", "", "", "", "", "", "", "", "");
    await _loadSupplierAnalysis(0, "", "", "", "", "", "", "", "", "");
    await _loadSupplierStateWiseAnalysis(0, "", "", "", "", "", "", "", "", "");
    await _loadSupplierCityWiseAnalysis(0, "", "", "", "", "", "", "", "", "");
    setState(() {
      filterOptions = [listOfString, []];

      savedFinanceReceivablesOptions = filterOptions
          .map((options) => List<bool>.filled(options.length, false))
          .toList();

      if (savedFinanceReceivablesOptionsTemp.isEmpty) {
        savedFinanceReceivablesOptions = filterOptions
            .map((options) => List<bool>.filled(options.length, false))
            .toList();
      } else {
        savedFinanceReceivablesOptions = savedFinanceReceivablesOptionsTemp;
      }
      chartDataLoaded = true;
    });
  }

  List<POList> filterPurchaseList(
    List<POList> poList, {
    String? agingCatg,
    String? itemCode,
    String? itemGroup,
    String? itemSubGroup,
    String? branchName,
    String? warehouseName,
    String? supplierCode,
    String? supplierState,
    String? supplierCity,
  }) {
    List<POList> filteredPoList = [];
    double dueFrom = 0.0;
    double dueTo = double.infinity;
    if (agingCatg != null || agingCatg != "") {
      if (agingCatg == "0-30") {
        dueFrom = 0;
        dueTo = 30;
      } else if (agingCatg == "31-60") {
        dueFrom = 31;
        dueTo = 60;
      } else if (agingCatg == "61-120") {
        dueFrom = 61;
        dueTo = 120;
      } else if (agingCatg == "121-180") {
        dueFrom = 121;
        dueTo = 180;
      } else if (agingCatg == "181+") {
        dueFrom = 181;
        dueTo = double.infinity;
      }
    }
    for (var purchase in poList) {
      double overDueDays = double.tryParse(purchase.overDueDays) ?? 0;
      if ((agingCatg == null ||
              agingCatg.isEmpty ||
              (overDueDays >= dueFrom && overDueDays <= dueTo)) &&
          (itemCode == null ||
              itemCode.isEmpty ||
              purchase.description == itemCode) &&
          (itemGroup == null ||
              itemGroup.isEmpty ||
              purchase.groupName == itemGroup) &&
          (itemSubGroup == null ||
              itemSubGroup.isEmpty ||
              purchase.itemSubGroup == itemSubGroup) &&
          (branchName == null ||
              branchName.isEmpty ||
              purchase.branchName == branchName) &&
          (warehouseName == null ||
              warehouseName.isEmpty ||
              purchase.warehouse == warehouseName) &&
          (supplierCode == null ||
              supplierCode.isEmpty ||
              purchase.vendorCode == supplierCode) &&
          (supplierState == null ||
              supplierState.isEmpty ||
              purchase.vendorState == supplierState) &&
          (supplierCity == null ||
              supplierCity.isEmpty ||
              purchase.vendorCity == supplierCity)) {
        filteredPoList.add(purchase);
      }
    }
    return filteredPoList;
  }

  Future<void> removeFilter() async {
    touchedMonthIndex = 0;
    touchedAgingCatg = "";
    touchedItemCode = "";
    touchedItemGroup = "";
    touchedItemSubGroup = "";
    touchedBranchName = "";
    touchedWarehouse = "";
    touchedSupplierCode = "";
    touchedSupplierState = "";
    touchedSupplierCity = "";
    touchedSupplierCategory = "";
    touchedMonthGoals = false;
    touchedQuarterGoals = false;
    touchedYTDGoals = false;
    clearVariables();
    LoadDates();
    setState(() {
      setState(() {
        chartDataLoaded = false;
      });
      clearVariables();
      LoadDates();
      allCategoriesState.forEach((category, options) {
        options.updateAll((key, value) => false);
      });
      allCategoriesState.clear();
      loadDataFuture = loadData("");
      setState(() {
        chartDataLoaded = false;
      });
    });
    chartDataLoaded = true;
  }

  Future<void> loadDataWithFilter(
    int monthIndex,
    String agingCatg,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String branchName,
    String warehouseName,
    String supplierCode,
    String supplierState,
    String supplierCity,
  ) async {
    clearVariablesForFilter();
    LoadDates();
    await _loadOpenPOAging(
      monthIndex,
      agingCatg,
      itemCode,
      itemGroup,
      itemSubGroup,
      branchName,
      warehouseName,
      supplierCode,
      supplierState,
      supplierCity,
    );
    await _loadItemAnalysis(
      monthIndex,
      agingCatg,
      itemCode,
      itemGroup,
      itemSubGroup,
      branchName,
      warehouseName,
      supplierCode,
      supplierState,
      supplierCity,
    );
    await _loadItemGroupWiseAnalysis(
      monthIndex,
      agingCatg,
      itemCode,
      itemGroup,
      itemSubGroup,
      branchName,
      warehouseName,
      supplierCode,
      supplierState,
      supplierCity,
    );
    await _loadItemSubGroupWiseAnalysis(
      monthIndex,
      agingCatg,
      itemCode,
      itemGroup,
      itemSubGroup,
      branchName,
      warehouseName,
      supplierCode,
      supplierState,
      supplierCity,
    );
    await _loadBranch(
      monthIndex,
      agingCatg,
      itemCode,
      itemGroup,
      itemSubGroup,
      branchName,
      warehouseName,
      supplierCode,
      supplierState,
      supplierCity,
    );
    await _loadWarehouseAnalysis(
      monthIndex,
      agingCatg,
      itemCode,
      itemGroup,
      itemSubGroup,
      branchName,
      warehouseName,
      supplierCode,
      supplierState,
      supplierCity,
    );
    await _loadSupplierAnalysis(
      monthIndex,
      agingCatg,
      itemCode,
      itemGroup,
      itemSubGroup,
      branchName,
      warehouseName,
      supplierCode,
      supplierState,
      supplierCity,
    );
    await _loadSupplierStateWiseAnalysis(
      monthIndex,
      agingCatg,
      itemCode,
      itemGroup,
      itemSubGroup,
      branchName,
      warehouseName,
      supplierCode,
      supplierState,
      supplierCity,
    );
    await _loadSupplierCityWiseAnalysis(
      monthIndex,
      agingCatg,
      itemCode,
      itemGroup,
      itemSubGroup,
      branchName,
      warehouseName,
      supplierCode,
      supplierState,
      supplierCity,
    );

    chartDataLoaded = true;
  }

  void clearVariables() {
    setState(() {
      chartDataLoaded = false;
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
      openPoAgingData = OpenPOAgingList(soAgingData: []);
      itemData = POItemAnalysisList(productData: []);
      itemGroupData = POItemGroupWiseAnalysisList(productData: []);
      itemSubGroupData = POItemSubGroupWiseAnalysisList(productData: []);
      branchData = POBranchAnalysisList(branchData: []);
      warehouseData = POWarehouseWiseAnalysisList(warehouseData: []);
      supplierData = POSupplierAnalysisList(supplierData: []);
      supplierStateData = POSupplierStateWiseAnalysisList(
        supplierStateData: [],
      );
      supplierCityData = POSupplierCityWiseAnalysisList(supplierCityData: []);
      touchedMonthIndex = 0;
      touchedAgingCatg = "";
      touchedItemCode = "";
      touchedItemGroup = "";
      touchedItemSubGroup = "";
      touchedBranchName = "";
      touchedWarehouse = "";
      touchedSupplierCode = "";
      touchedSupplierState = "";
      touchedSupplierCity = "";
      touchedSupplierCategory = "";
    });
  }

  void clearVariablesForFilter() {
    setState(() {
      chartDataLoaded = false;
      openPoAgingData = OpenPOAgingList(soAgingData: []);
      itemData = POItemAnalysisList(productData: []);
      itemGroupData = POItemGroupWiseAnalysisList(productData: []);
      itemSubGroupData = POItemSubGroupWiseAnalysisList(productData: []);
      branchData = POBranchAnalysisList(branchData: []);
      warehouseData = POWarehouseWiseAnalysisList(warehouseData: []);
      supplierData = POSupplierAnalysisList(supplierData: []);
      supplierStateData = POSupplierStateWiseAnalysisList(
        supplierStateData: [],
      );
      supplierCityData = POSupplierCityWiseAnalysisList(supplierCityData: []);
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

  Future<void> generatePOAgingExcel(OpenPOAgingList openPOAgingList) async {
    double totalPurchaseAmount = 0;
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Aging', 'PO Amount']));
      for (var monthlyData in openPOAgingList.soAgingData) {
        sheet.appendRow(
          toCellRow([monthlyData.group, monthlyData.receivableAmount]),
        );
        totalPurchaseAmount += monthlyData.receivableAmount;
      }
      sheet.appendRow(toCellRow(["", totalPurchaseAmount]));

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('aging_po_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/aging_po_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generatePOAgingPDF(OpenPOAgingList openPOAgingList) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'PO Aging Report',
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
                      'Aging',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'PO Amount',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var monthlyData in openPOAgingList.soAgingData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        monthlyData.group,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        monthlyData.receivableAmount.toStringAsFixed(2),
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
        final file = File('$storageDir/po_aging_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateMonthwisePOExcel(POMonthWiseList poMonthWiseList) async {
    double totalPurchaseAmount = 0;
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Month', 'PO Amount']));
      for (var monthlyData in poMonthWiseList.monthlyData) {
        sheet.appendRow(
          toCellRow([monthlyData.monthName, monthlyData.collectionAmount]),
        );
        totalPurchaseAmount += monthlyData.collectionAmount;
      }
      sheet.appendRow(toCellRow(["", totalPurchaseAmount]));

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('monthly_po_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthly_po_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateMonthwisePOPDF(POMonthWiseList poMonthWiseList) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Monthly PO Report',
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
                      'PO Amount',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var monthlyData in poMonthWiseList.monthlyData)
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
                        monthlyData.collectionAmount.toStringAsFixed(2),
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
        final file = File('$storageDir/monthly_po_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemPOExcel(
    POItemAnalysisList poItemAnalysisList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'Product Name',
          'Actual',
          // 'Monthly Avg.',
          // 'Difference',
          // 'Percentage'
        ]),
      );
      for (var itemData in poItemAnalysisList.productData) {
        sheet.appendRow(
          toCellRow([
            itemData.productName,
            itemData.salesAmount.toStringAsFixed(2),
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('item_po_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/item_po_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemPOPDF(POItemAnalysisList poItemAnalysisList) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Productwise PO Report',
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
      final totalPages = (poItemAnalysisList.productData.length / rowsPerPage)
          .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end = start + rowsPerPage > poItemAnalysisList.productData.length
            ? poItemAnalysisList.productData.length
            : start + rowsPerPage;
        final tableData = poItemAnalysisList.productData.sublist(start, end);

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
                        'Actual',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      // pw.Text('Monthly Avg.',
                      //     style: pw.TextStyle(
                      //         fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      // pw.Text('Difference',
                      //     style: pw.TextStyle(
                      //         fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      // pw.Text('Percentage',
                      //     style: pw.TextStyle(
                      //         fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  // Table data rows
                  for (var monthlyData in tableData)
                    pw.TableRow(
                      children: [
                        pw.Text(
                          monthlyData.productName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.salesAmount.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        // pw.Text(monthlyData.monthsAvg.toStringAsFixed(2),
                        //     style: pw.TextStyle(
                        //         fontSize: 14, fontWeight: pw.FontWeight.normal)),
                        // pw.Text(
                        //     ((monthlyData.salesAmount - monthlyData.monthsAvg) /
                        //             100000)
                        //         .toStringAsFixed(0),
                        //     style: pw.TextStyle(
                        //         fontSize: 14, fontWeight: pw.FontWeight.normal)),
                        // pw.Text(
                        //     (monthlyData.monthsAvg != 0
                        //         ? (((monthlyData.salesAmount /
                        //                     monthlyData.monthsAvg) *
                        //                 100)
                        //             .ceil()
                        //             .toStringAsFixed(0))
                        //         : "0"),
                        //     style: pw.TextStyle(
                        //         fontSize: 14, fontWeight: pw.FontWeight.normal)),
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
        final file = File('$storageDir/monthly_po_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemGroupPOExcel(
    POItemGroupWiseAnalysisList poItemGroupWiseAnalysisList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Product Group Name', 'PO Amount']));
      for (var itemData in poItemGroupWiseAnalysisList.productData) {
        sheet.appendRow(
          toCellRow([
            itemData.productGroupName,
            itemData.salesAmount.toStringAsFixed(2),
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('itemgroup_po_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/itemgroup_po_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemGroupPOPDF(
    POItemGroupWiseAnalysisList poItemGroupWiseAnalysisList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Product Group Wise PO Report',
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
          (poItemGroupWiseAnalysisList.productData.length / rowsPerPage).ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage > poItemGroupWiseAnalysisList.productData.length
            ? poItemGroupWiseAnalysisList.productData.length
            : start + rowsPerPage;
        final tableData = poItemGroupWiseAnalysisList.productData.sublist(
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
                        'PO Amount',
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
                          monthlyData.productGroupName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.salesAmount.toStringAsFixed(2),
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
        final file = File('$storageDir/itemgroup_po_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemSubGroupPOExcel(
    POItemSubGroupWiseAnalysisList poItemSubGroupWiseAnalysisList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Product Sub Group Name', 'PO Amount']));
      for (var itemData in poItemSubGroupWiseAnalysisList.productData) {
        sheet.appendRow(
          toCellRow([
            itemData.productSubGroupName,
            itemData.salesAmount.toStringAsFixed(2),
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('itemsubgroup_po_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/itemsubgroup_po_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemSubGroupPOPDF(
    POItemSubGroupWiseAnalysisList poItemSubGroupWiseAnalysisList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Product Sub Group Wise PO Report',
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
          (poItemSubGroupWiseAnalysisList.productData.length / rowsPerPage)
              .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage >
                poItemSubGroupWiseAnalysisList.productData.length
            ? poItemSubGroupWiseAnalysisList.productData.length
            : start + rowsPerPage;
        final tableData = poItemSubGroupWiseAnalysisList.productData.sublist(
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
                        'Sub Group Name',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'PO Amount',
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
                          monthlyData.productSubGroupName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.salesAmount.toStringAsFixed(2),
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
        final file = File('$storageDir/itemsubgroup_po_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateBranchPOExcel(
    POBranchAnalysisList poBranchAnalysisList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Branch Name', 'Actual']));
      for (var itemData in poBranchAnalysisList.branchData) {
        sheet.appendRow(
          toCellRow([
            itemData.branchName,
            itemData.salesAmount.toStringAsFixed(2),
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('branch_po_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/branch_po_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateBranchPOPDF(
    POBranchAnalysisList poBranchAnalysisList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Branch Wise PO Report',
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
      final totalPages = (poBranchAnalysisList.branchData.length / rowsPerPage)
          .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end = start + rowsPerPage > poBranchAnalysisList.branchData.length
            ? poBranchAnalysisList.branchData.length
            : start + rowsPerPage;
        final tableData = poBranchAnalysisList.branchData.sublist(start, end);

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
                        'Actual',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      // pw.Text('Monthly Avg.',
                      //     style: pw.TextStyle(
                      //         fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      // pw.Text('Difference',
                      //     style: pw.TextStyle(
                      //         fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      // pw.Text('Percentage',
                      //     style: pw.TextStyle(
                      //         fontSize: 14, fontWeight: pw.FontWeight.bold)),
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
                          monthlyData.salesAmount.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        // pw.Text(monthlyData.monthsAvg.toStringAsFixed(2),
                        //     style: pw.TextStyle(
                        //         fontSize: 14, fontWeight: pw.FontWeight.normal)),
                        // pw.Text(
                        //     ((monthlyData.salesAmount - monthlyData.monthsAvg) /
                        //             100000)
                        //         .toStringAsFixed(2),
                        //     style: pw.TextStyle(
                        //         fontSize: 14, fontWeight: pw.FontWeight.normal)),
                        // pw.Text(
                        //     (monthlyData.monthsAvg != 0
                        //         ? (((monthlyData.salesAmount /
                        //                     monthlyData.monthsAvg) *
                        //                 100)
                        //             .ceil()
                        //             .toStringAsFixed(0))
                        //         : "0"),
                        //     style: pw.TextStyle(
                        //         fontSize: 14, fontWeight: pw.FontWeight.normal)),
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
        final file = File('$storageDir/branch_po_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateWarehousePOExcel(
    POWarehouseWiseAnalysisList poWarehouseWiseAnalysisList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Warehouse Name', 'Actual']));
      for (var itemData in poWarehouseWiseAnalysisList.warehouseData) {
        sheet.appendRow(
          toCellRow([
            itemData.warehouseName,
            itemData.salesAmount.toStringAsFixed(2),
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('Warehouse_po_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/Warehouse_po_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateWarehousePOPDF(
    POWarehouseWiseAnalysisList poWarehouseWiseAnalysisList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Warehouse Wise PO Report',
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
          (poWarehouseWiseAnalysisList.warehouseData.length / rowsPerPage)
              .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage >
                poWarehouseWiseAnalysisList.warehouseData.length
            ? poWarehouseWiseAnalysisList.warehouseData.length
            : start + rowsPerPage;
        final tableData = poWarehouseWiseAnalysisList.warehouseData.sublist(
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
                        'Warehouse Name',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Actual',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      // pw.Text('Monthly Avg.',
                      //     style: pw.TextStyle(
                      //         fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      // pw.Text('Difference',
                      //     style: pw.TextStyle(
                      //         fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      // pw.Text('Percentage',
                      //     style: pw.TextStyle(
                      //         fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  // Table data rows
                  for (var monthlyData in tableData)
                    pw.TableRow(
                      children: [
                        pw.Text(
                          monthlyData.warehouseName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.salesAmount.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        // pw.Text(monthlyData.monthsAvg.toStringAsFixed(2),
                        //     style: pw.TextStyle(
                        //         fontSize: 14, fontWeight: pw.FontWeight.normal)),
                        // pw.Text(
                        //     ((monthlyData.salesAmount - monthlyData.monthsAvg) /
                        //             100000)
                        //         .toStringAsFixed(2),
                        //     style: pw.TextStyle(
                        //         fontSize: 14, fontWeight: pw.FontWeight.normal)),
                        // pw.Text(
                        //     (monthlyData.monthsAvg != 0
                        //         ? (((monthlyData.salesAmount /
                        //                     monthlyData.monthsAvg) *
                        //                 100)
                        //             .ceil()
                        //             .toStringAsFixed(0))
                        //         : "0"),
                        //     style: pw.TextStyle(
                        //         fontSize: 14, fontWeight: pw.FontWeight.normal)),
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
        final file = File('$storageDir/warehouse_po_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierPOExcel(
    POSupplierAnalysisList poSupplierAnalysisList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'Supplier Name',
          'Actual',
          // 'Monthly Avg.',
          // 'Difference',
          // 'Percentage'
        ]),
      );
      for (var itemData in poSupplierAnalysisList.supplierData) {
        sheet.appendRow(
          toCellRow([
            itemData.supplierName,
            itemData.salesAmount.toStringAsFixed(2),
            // itemData.monthsAvg.toStringAsFixed(2),
            // ((itemData.salesAmount - itemData.monthsAvg) / 100000)
            //     .toStringAsFixed(2),
            // itemData.monthsAvg != 0
            //     ? ((itemData.salesAmount / itemData.monthsAvg) * 100)
            //         .ceil()
            //         .toStringAsFixed(0)
            //     : 0
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('Supplier_po_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/Supplier_po_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierPOPDF(
    POSupplierAnalysisList poSupplierAnalysisList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Supplier Wise PO Report',
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
          (poSupplierAnalysisList.supplierData.length / rowsPerPage).ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage > poSupplierAnalysisList.supplierData.length
            ? poSupplierAnalysisList.supplierData.length
            : start + rowsPerPage;
        final tableData = poSupplierAnalysisList.supplierData.sublist(
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
                        'Supplier Name',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Actual',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      // pw.Text('Monthly Avg.',
                      //     style: pw.TextStyle(
                      //         fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      // pw.Text('Difference',
                      //     style: pw.TextStyle(
                      //         fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      // pw.Text('Percentage',
                      //     style: pw.TextStyle(
                      //         fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  // Table data rows
                  for (var monthlyData in tableData)
                    pw.TableRow(
                      children: [
                        pw.Text(
                          monthlyData.supplierName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.salesAmount.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        // pw.Text(monthlyData.monthsAvg.toStringAsFixed(2),
                        //     style: pw.TextStyle(
                        //         fontSize: 14, fontWeight: pw.FontWeight.normal)),
                        // pw.Text(
                        //     ((monthlyData.salesAmount - monthlyData.monthsAvg) /
                        //             100000)
                        //         .toStringAsFixed(2),
                        //     style: pw.TextStyle(
                        //         fontSize: 14, fontWeight: pw.FontWeight.normal)),
                        // pw.Text(
                        //     (monthlyData.monthsAvg != 0
                        //         ? (((monthlyData.salesAmount /
                        //                     monthlyData.monthsAvg) *
                        //                 100)
                        //             .ceil()
                        //             .toStringAsFixed(0))
                        //         : "0"),
                        //     style: pw.TextStyle(
                        //         fontSize: 14, fontWeight: pw.FontWeight.normal)),
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
        final file = File('$storageDir/supplier_po_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierStatePOExcel(
    POSupplierStateWiseAnalysisList poSupplierStateWiseAnalysisList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'State Name',
          'Actual',
          // 'Monthly Avg.',
          // 'Difference',
          // 'Percentage'
        ]),
      );
      for (var itemData in poSupplierStateWiseAnalysisList.supplierStateData) {
        sheet.appendRow(
          toCellRow([
            itemData.supplierStateName,
            itemData.salesAmount.toStringAsFixed(2),
            // itemData.monthsAvg.toStringAsFixed(2),
            // ((itemData.salesAmount - itemData.monthsAvg) / 100000).toStringAsFixed(2),
            // itemData.monthsAvg != 0
            //     ? ((itemData.salesAmount / itemData.monthsAvg) * 100)
            //         .ceil()
            //         .toStringAsFixed(0)
            //     : 0
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('SupplierState_po_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/SupplierState_po_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierStatePOPDF(
    POSupplierStateWiseAnalysisList poSupplierStateWiseAnalysisList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Supplier State Wise PO Report',
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
          (poSupplierStateWiseAnalysisList.supplierStateData.length /
                  rowsPerPage)
              .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage >
                poSupplierStateWiseAnalysisList.supplierStateData.length
            ? poSupplierStateWiseAnalysisList.supplierStateData.length
            : start + rowsPerPage;
        final tableData = poSupplierStateWiseAnalysisList.supplierStateData
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
                        'State Name',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Actual',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      // pw.Text('Monthly Avg.',
                      //     style: pw.TextStyle(
                      //         fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      // pw.Text('Difference',
                      //     style: pw.TextStyle(
                      //         fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      // pw.Text('Percentage',
                      //     style: pw.TextStyle(
                      //         fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  // Table data rows
                  for (var monthlyData in tableData)
                    pw.TableRow(
                      children: [
                        pw.Text(
                          monthlyData.supplierStateName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.salesAmount.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        // pw.Text(monthlyData.monthsAvg.toStringAsFixed(2),
                        //     style: pw.TextStyle(
                        //         fontSize: 14, fontWeight: pw.FontWeight.normal)),
                        // pw.Text(
                        //     ((monthlyData.salesAmount - monthlyData.monthsAvg) /
                        //             100000)
                        //         .toStringAsFixed(2),
                        //     style: pw.TextStyle(
                        //         fontSize: 14, fontWeight: pw.FontWeight.normal)),
                        // pw.Text(
                        //     (monthlyData.monthsAvg != 0
                        //         ? (((monthlyData.salesAmount /
                        //                     monthlyData.monthsAvg) *
                        //                 100)
                        //             .ceil()
                        //             .toStringAsFixed(0))
                        //         : "0"),
                        //     style: pw.TextStyle(
                        //         fontSize: 14, fontWeight: pw.FontWeight.normal)),
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
        final file = File('$storageDir/supplierstate_purchase_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierCityPOExcel(
    POSupplierCityWiseAnalysisList poSupplierCityWiseAnalysisList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'State Name',
          'Actual',
          // 'Monthly Avg.',
          // 'Difference',
          // 'Percentage'
        ]),
      );
      for (var itemData in poSupplierCityWiseAnalysisList.supplierCityData) {
        sheet.appendRow(
          toCellRow([
            itemData.supplierCityName,
            itemData.salesAmount.toStringAsFixed(2),
            // itemData.monthsAvg.toStringAsFixed(2),
            // ((itemData.salesAmount - itemData.monthsAvg) / 100000)
            //     .toStringAsFixed(2),
            // itemData.monthsAvg != 0
            //     ? ((itemData.salesAmount / itemData.monthsAvg) * 100)
            //         .ceil()
            //         .toStringAsFixed(0)
            //     : 0
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('Supplier_city_po_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/Supplier_city_po_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierCityPOPDF(
    POSupplierCityWiseAnalysisList poSupplierCityWiseAnalysisList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Supplier City Wise PO Report',
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
          (poSupplierCityWiseAnalysisList.supplierCityData.length / rowsPerPage)
              .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage >
                poSupplierCityWiseAnalysisList.supplierCityData.length
            ? poSupplierCityWiseAnalysisList.supplierCityData.length
            : start + rowsPerPage;
        final tableData = poSupplierCityWiseAnalysisList.supplierCityData
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
                        'City Name',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Actual',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      // pw.Text('Monthly Avg.',
                      //     style: pw.TextStyle(
                      //         fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      // pw.Text('Difference',
                      //     style: pw.TextStyle(
                      //         fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      // pw.Text('Percentage',
                      //     style: pw.TextStyle(
                      //         fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  // Table data rows
                  for (var monthlyData in tableData)
                    pw.TableRow(
                      children: [
                        pw.Text(
                          monthlyData.supplierCityName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.salesAmount.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        // pw.Text(monthlyData.monthsAvg.toStringAsFixed(2),
                        //     style: pw.TextStyle(
                        //         fontSize: 14, fontWeight: pw.FontWeight.normal)),
                        // pw.Text(
                        //     ((monthlyData.salesAmount - monthlyData.monthsAvg) /
                        //             100000)
                        //         .toStringAsFixed(2),
                        //     style: pw.TextStyle(
                        //         fontSize: 14, fontWeight: pw.FontWeight.normal)),
                        // pw.Text(
                        //     (monthlyData.monthsAvg != 0
                        //         ? (((monthlyData.salesAmount /
                        //                     monthlyData.monthsAvg) *
                        //                 100)
                        //             .ceil()
                        //             .toStringAsFixed(0))
                        //         : "0"),
                        //     style: pw.TextStyle(
                        //         fontSize: 14, fontWeight: pw.FontWeight.normal)),
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
        final file = File('$storageDir/supplier_city_po_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  String formatDateString(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  void resetFinanceReceivablesOptions() {
    setState(() {
      savedFinanceReceivablesOptions = List.from(
        selectedFinanceReceivablesOptions,
      );
    });
  }

  Future<void> _dateFilterTarget(
    String UserName,
    String UserLevel,
    bool FromFilter,
  ) async {
    setState(() {
      List<String> menuNames = usersList
          .where((element) => element.parentMenuId == 0)
          .map((user) => user.menuName)
          .toList();
      menuNames.insert(0, UserName);
      context.read<PurchasePOAnalysisProvider>().updatePOList(poList);

      poList = poList.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();
    });
  }

  Future<void> filterFunction() async {
    setState(() {
      chartDataLoaded = false;
    });
    String selectedUser = '';
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    UserLevel = userLevel;
    setState(() async {
      await _loadPOList(userName, userLevel);
      await _dateFilterTarget(userName, userLevel, true);
      await _loadOpenPOAging(0, "", "", "", "", "", "", "", "", "");
      await _loadMonthWisePOAnalysis();
      await _loadItemAnalysis(0, "", "", "", "", "", "", "", "", "");
      await _loadItemGroupWiseAnalysis(0, "", "", "", "", "", "", "", "", "");
      await _loadItemSubGroupWiseAnalysis(
        0,
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
      );
      await _loadBranch(0, "", "", "", "", "", "", "", "", "");
      await _loadWarehouseAnalysis(0, "", "", "", "", "", "", "", "", "");
      await _loadSupplierAnalysis(0, "", "", "", "", "", "", "", "", "");
      await _loadSupplierStateWiseAnalysis(
        0,
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
      );
      await _loadSupplierCityWiseAnalysis(
        0,
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
      );

      List<String> trueStatusOptions = (allCategoriesState['Status'] ?? {})
          .entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      List<POList> filteredList = [];

      if (trueStatusOptions.isNotEmpty) {
        filteredList = poList
            .where((person) => trueStatusOptions.contains(person.poStatus))
            .toList();
        poList = filteredList;
      }

      // var currentMonthTarget = sales.where((target) {
      //   DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
      //   return (dueon.isAtMost(currentDate!));
      // });
      // for (var target in currentMonthTarget.toList()) {
      //   double balance = double.tryParse(target.rowTotal) ?? 0;
      //   if (balance > 0) {
      //     sum += balance;
      //   } else {
      //     double balanceAbs = balance.abs();
      //     advanceSum += balanceAbs;
      //   }
      // }
      // var currentOverDue = sales.where((target) {
      //   DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
      //   return dueon.isAtMost(currentDate!);
      // }).toSet();
      // for (var target in currentOverDue.toList()) {
      //   double balance = double.tryParse(target.rowTotal) ?? 0;
      //   overDueSum += balance;
      // }
      //
      // notDue = 0;
      //
      // var notOverDue = target;
      // for (var target in notOverDue.toList()) {
      //   double balance = double.tryParse(target.balance) ?? 0;
      //   String future = target.ageingBrackets;
      //   if (future == 'Future') {
      //     notDue += balance;
      //   }
      // }
      //
      // receivablesAmount = notDue + overDueSum;
      // receivablesAmountStr = "";
      // receivablesAmountStr = formatAmount(receivablesAmount.abs());
      // overDue = overDueSum;
      // overDueStr = formatAmount(overDue.abs());
      // notDueStr = formatAmount(notDue.abs());
      //
      // advance = advanceSum;
      //
      // advance = advanceCustomerList.agingData
      //     .fold(0, (t, e) => t + e.agingGroupTotal);
      //
      // advanceStr = formatAmount(advance.abs());
      // netReceivables = sum - advance;
      // netReceivablesStr = formatAmount(netReceivables.abs());
      //
      // grossReceivables = sum;
      // grossReceivablesStr = formatAmount(grossReceivables.abs());
      //
      // if (overDue == 0 || receivablesAmount == 0) {
      //   receivablePercentage = 0;
      // } else {
      //   receivablePercentage = double.tryParse(
      //       ((overDue / (receivablesAmount)) * 100).toStringAsFixed(2))
      //       ?.ceil() ??
      //       0;
      // }
      //
      // if (receivablePercentage > 100) {
      //   receivablePercentage = 100;
      // }
      //
      // if (advance == 0 || netReceivables == 0) {
      //   netReceivablePercentage = 0;
      // } else {
      //   netReceivablePercentage = double.tryParse(
      //       ((advance / (netReceivables)) * 100).toStringAsFixed(2))
      //       ?.ceil() ??
      //       0;
      // }
      //
      // if (netReceivablePercentage > 100) {
      //   netReceivablePercentage = 100;
      // }
      // if (netReceivablePercentage.isNegative) {
      //   netReceivablePercentage = 0;
      // }
      chartDataLoaded = true;

      setState(() {
        filterOptions = [listOfRSM, listOfASM, listOfTSM, listOfString, []];

        savedFinanceReceivablesOptions = filterOptions
            .map((options) => List<bool>.filled(options.length, false))
            .toList();

        if (savedFinanceReceivablesOptionsTemp.isEmpty) {
          savedFinanceReceivablesOptions = filterOptions
              .map((options) => List<bool>.filled(options.length, false))
              .toList();
        } else {
          savedFinanceReceivablesOptions = savedFinanceReceivablesOptionsTemp;
        }

        // selectedFinanceReceivablesOptions = savedFinanceReceivablesOptions;
      });

      setState(() {
        chartDataLoaded = true;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    LoadDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
      toDateFilter = currentDate;
      fromDateFilter = fiscalYearStartDate;
    }

    filterOptions = [listOfString, []];

    selectedFinanceReceivablesOptions = filterOptions
        .map((options) => List<bool>.filled(options.length, false))
        .toList();

    selectedFinanceReceivablesOptions = savedFinanceReceivablesOptions;
  }

  @override
  Widget build(BuildContext context) {
    selectedFinanceReceivablesOptions = savedFinanceReceivablesOptions;
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
                        dateFilterFlag
                            ? Text(
                                "${formatDateString(fromDateFilter!)} - ${formatDateString(toDateFilter!)}",
                              )
                            : Text(
                                "${formatDateString(fiscalYearStartDate!)} - ${formatDateString(currentDate!)}",
                              ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            showFilterBottomSheet(context);
                          },
                          icon: const Icon(Icons.filter_alt_outlined),
                        ),
                        const SizedBox(width: 5),
                      ],
                    ),
                  ],
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Open Purchase Order",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.end,
                    //   children: [
                    //     PopupMenuButton(
                    //       onSelected: (value) {},
                    //       itemBuilder: (BuildContext bc) {
                    //         return [
                    //           PopupMenuItem(
                    //             onTap: () {
                    //               setState(() {});
                    //             },
                    //             child: const Text("Download Excel"),
                    //           ),
                    //           PopupMenuItem(
                    //             onTap: () {
                    //               setState(() {});
                    //             },
                    //             child: const Text("Download PDF"),
                    //           ),
                    //         ];
                    //       },
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, right: 4.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {});
                          },
                          child: CircularPercentIndicator(
                            arcType: ArcType.HALF,
                            radius: 55.0,
                            lineWidth: 20.0,
                            animation: true,
                            percent: lastMonthPercentage / 100,
                            center: Column(
                              children: [
                                const SizedBox(height: 30),
                                Text(
                                  lastMonthPercentage.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: touchedMonthGoals ? 13.0 : 12.0,
                                    color: touchedMonthGoals
                                        ? Colors.cyan
                                        : Colors.black,
                                  ),
                                ),
                                Text(
                                  lastMonthHalfPieStr,
                                  style: TextStyle(
                                    fontSize: touchedMonthGoals ? 11.0 : 10.0,
                                    color: touchedMonthGoals
                                        ? Colors.cyan
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Center(
                                  child: Text(
                                    "${getMonthName(currentDate!.month - 1)}\n($lastMonthHalfPieStr)",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: touchedMonthGoals ? 11.0 : 10.0,
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
                            percent: currentMonthPercentage / 100,
                            center: Column(
                              children: [
                                const SizedBox(height: 30),
                                Text(
                                  currentMonthPercentage.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: touchedQuarterGoals ? 13.0 : 12.0,
                                    color: touchedQuarterGoals
                                        ? Colors.cyan
                                        : Colors.black,
                                  ),
                                ),
                                Text(
                                  currentMonthHalfPieStr,
                                  style: TextStyle(
                                    fontSize: touchedQuarterGoals ? 11.0 : 10.0,
                                    color: touchedQuarterGoals
                                        ? Colors.cyan
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Center(
                                  child: Text(
                                    "${getMonthName(currentDate!.month)}\n($currentMonthHalfPieStr)",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: touchedMonthGoals ? 11.0 : 10.0,
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
                            percent: ytdPercentage / 100,
                            center: Column(
                              children: [
                                const SizedBox(height: 30),
                                Text(
                                  ytdPercentage.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: touchedYTDGoals ? 13.0 : 12.0,
                                    color: touchedYTDGoals
                                        ? Colors.cyan
                                        : Colors.black,
                                  ),
                                ),
                                Text(
                                  ytdHalfPieStr,
                                  style: TextStyle(
                                    fontSize: touchedYTDGoals ? 11.0 : 10.0,
                                    color: touchedYTDGoals
                                        ? Colors.cyan
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "YTD \n($ytdHalfPieStr)",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: touchedYTDGoals ? 11.0 : 10.0,
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
                          "Open PO Aging",
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
                                    generatePOAgingExcel(openPoAgingData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generatePOAgingPDF(openPoAgingData);
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
                  child: _openPOAging(),
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
                          "Month Wise PO Analysis",
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
                                    generateMonthwisePOExcel(monthData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateMonthwisePOPDF(monthData);
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
                  child: _monthWisePOAnalysis(),
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
                          "Item Analysis",
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
                                    generateItemPOExcel(itemData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateItemPOPDF(itemData);
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
                  child: _itemAnalysis(),
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
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateItemGroupPOExcel(itemGroupData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateItemGroupPOPDF(itemGroupData);
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
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateItemSubGroupPOExcel(
                                      itemSubGroupData,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateItemSubGroupPOPDF(itemSubGroupData);
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
                          "Branch Analysis",
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
                                    generateBranchPOExcel(branchData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateBranchPOPDF(branchData);
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
                  child: _branchAnalysis(),
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
                          "Warehouse Wise Analysis",
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
                                    generateWarehousePOExcel(warehouseData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateWarehousePOPDF(warehouseData);
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
                  child: _warehouseWiseAnalysis(),
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
                          "Supplier Analysis",
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
                                    generateSupplierPOExcel(supplierData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateSupplierPOPDF(supplierData);
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
                  child: _supplierAnalysis(),
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
                          "Supplier State Wise Analysis",
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
                                    generateSupplierStatePOExcel(
                                      supplierStateData,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateSupplierStatePOPDF(
                                      supplierStateData,
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
                  child: _supplierStateWiseAnalysis(),
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
                          "Supplier City Wise Analysis",
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
                                    generateSupplierCityPOExcel(
                                      supplierCityData,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateSupplierCityPOPDF(supplierCityData);
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
                  child: _supplierCityWiseAnalysis(),
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

  Widget _openPOAging() {
    final screenWidth = MediaQuery.of(context).size.width;
    int len = openPoAgingData.soAgingData.length;
    double barChartWidth = 0.0;
    openPoAgingData.soAgingData.length > 6
        ? barChartWidth = screenWidth * 1.4
        : barChartWidth = screenWidth;

    double maxPurchaseAmount = len > 0
        ? openPoAgingData.soAgingData
              .map((data) => data.receivableAmount)
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
                sideTitles: _bottomTitlesOpenPOAging,
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
            barGroups: _openPOAgingChartData(openPoAgingData.soAgingData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedAgingCatg = touchedAgingCatg == ""
                          ? openPoAgingData
                                .soAgingData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .group
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedAgingCatg,
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedBranchName,
                        touchedWarehouse,
                        touchedSupplierCode,
                        touchedSupplierState,
                        touchedSupplierCity,
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
                    openPoAgingData.soAgingData[grpIndex].group,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\n${formatAmount(openPoAgingData.soAgingData[grpIndex].receivableAmount)}",
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

  Widget _monthWisePOAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    int len = monthData.monthlyData.length;
    double barChartWidth = 0.0;
    monthData.monthlyData.length > 6
        ? barChartWidth = screenWidth * 1.4
        : barChartWidth = screenWidth;

    double maxPurchaseAmount = len > 0
        ? monthData.monthlyData
              .map((data) => data.collectionAmount)
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
                sideTitles: _monthlyBottomTitles,
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
            barGroups: _monthWisePOAnalysisChartData(monthData.monthlyData),
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
                        touchedAgingCatg,
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedBranchName,
                        touchedWarehouse,
                        touchedSupplierCode,
                        touchedSupplierState,
                        touchedSupplierCity,
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
                    monthData.monthlyData[grpIndex].monthName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\n${formatAmount(monthData.monthlyData[grpIndex].collectionAmount)}",
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

  Widget _itemAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    int len = itemData.productData.length;
    double barChartWidth = 0.0;
    if (itemData.productData.length > 5) {
      barChartWidth = screenWidth + (50 * len);
    } else {
      barChartWidth = screenWidth;
    }

    double maxPurchaseAmount = len > 0
        ? itemData.productData
              .map((data) => data.salesAmount)
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
                sideTitles: _bottomTitlesItemAnalysis,
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
            barGroups: _itemAnalysisChartData(itemData.productData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedItemCode = touchedItemCode == ""
                          ? itemData
                                .productData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .productName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedAgingCatg,
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedBranchName,
                        touchedWarehouse,
                        touchedSupplierCode,
                        touchedSupplierState,
                        touchedSupplierCity,
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
                    itemData.productData[grpIndex].productName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\n${formatAmount(itemData.productData[grpIndex].salesAmount)}",
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
    int len = itemGroupData.productData.length;
    double barChartWidth = 0.0;
    itemGroupData.productData.length > 6
        ? barChartWidth = screenWidth * 1.4
        : barChartWidth = screenWidth;

    double maxPurchaseAmount = len > 0
        ? itemGroupData.productData
              .map((data) => data.salesAmount)
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
              itemGroupData.productData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedItemGroup = touchedItemGroup == ""
                          ? itemGroupData
                                .productData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .productGroupName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedAgingCatg,
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedBranchName,
                        touchedWarehouse,
                        touchedSupplierCode,
                        touchedSupplierState,
                        touchedSupplierCity,
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
                    itemGroupData.productData[grpIndex].productGroupName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\n ${formatAmount(itemGroupData.productData[grpIndex].salesAmount)}",
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
    int len = itemSubGroupData.productData.length;
    if (itemSubGroupData.productData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxPurchaseAmount = len > 0
        ? itemSubGroupData.productData
              .map((data) => data.salesAmount)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
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
              itemSubGroupData.productData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedItemSubGroup = touchedItemSubGroup == ""
                          ? itemSubGroupData
                                .productData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .productSubGroupName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedAgingCatg,
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedBranchName,
                        touchedWarehouse,
                        touchedSupplierCode,
                        touchedSupplierState,
                        touchedSupplierCity,
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
                    itemSubGroupData.productData[grpIndex].productSubGroupName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\n ${formatAmount(itemSubGroupData.productData[grpIndex].salesAmount)}",
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

  Widget _branchAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = branchData.branchData.length;
    if (branchData.branchData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxPurchaseAmount = len > 0
        ? branchData.branchData
              .map((data) => data.salesAmount)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
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
                sideTitles: _bottomTitlesBranchAnalysis,
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
            barGroups: _branchAnalysisChartData(branchData.branchData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedBranchName = touchedBranchName == ""
                          ? branchData
                                .branchData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .branchName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedAgingCatg,
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedBranchName,
                        touchedWarehouse,
                        touchedSupplierCode,
                        touchedSupplierState,
                        touchedSupplierCity,
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
                    branchData.branchData[grpIndex].branchName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\n ${formatAmount(branchData.branchData[grpIndex].salesAmount)}",
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

  Widget _warehouseWiseAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = warehouseData.warehouseData.length;
    if (warehouseData.warehouseData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxPurchaseAmount = len > 0
        ? warehouseData.warehouseData
              .map((data) => data.salesAmount)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
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
                sideTitles: _bottomTitlesWarehouseWiseAnalysis,
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
            barGroups: _warehouseWiseAnalysisChartData(
              warehouseData.warehouseData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedWarehouse = touchedWarehouse == ""
                          ? warehouseData
                                .warehouseData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .warehouseName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedAgingCatg,
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedBranchName,
                        touchedWarehouse,
                        touchedSupplierCode,
                        touchedSupplierState,
                        touchedSupplierCity,
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
                    warehouseData.warehouseData[grpIndex].warehouseName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\n ${formatAmount(warehouseData.warehouseData[grpIndex].salesAmount)}",
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

  Widget _supplierAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = supplierData.supplierData.length;
    if (supplierData.supplierData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxPurchaseAmount = len > 0
        ? supplierData.supplierData
              .map((data) => data.salesAmount)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
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
                sideTitles: _bottomTitlesSupplierAnalysis,
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
            barGroups: _supplierAnalysisChartData(supplierData.supplierData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedSupplierCode = touchedSupplierCode == ""
                          ? supplierData
                                .supplierData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .supplierName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedAgingCatg,
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedBranchName,
                        touchedWarehouse,
                        touchedSupplierCode,
                        touchedSupplierState,
                        touchedSupplierCity,
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
                    supplierData.supplierData[grpIndex].supplierName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\n ${formatAmount(supplierData.supplierData[grpIndex].salesAmount)}",
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

  Widget _supplierStateWiseAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = supplierStateData.supplierStateData.length;
    if (supplierStateData.supplierStateData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxPurchaseAmount = len > 0
        ? supplierStateData.supplierStateData
              .map((data) => data.salesAmount)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
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
                sideTitles: _bottomTitlesSupplierStateWiseAnalysis,
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
            barGroups: _supplierStateWiseAnalysisChartData(
              supplierStateData.supplierStateData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedSupplierState = touchedSupplierState == ""
                          ? supplierStateData
                                .supplierStateData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .supplierStateName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedAgingCatg,
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedBranchName,
                        touchedWarehouse,
                        touchedSupplierCode,
                        touchedSupplierState,
                        touchedSupplierCity,
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
                    supplierStateData
                        .supplierStateData[grpIndex]
                        .supplierStateName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\n${formatAmount(supplierStateData.supplierStateData[grpIndex].salesAmount)}",
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

  Widget _supplierCityWiseAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = supplierCityData.supplierCityData.length;
    if (supplierCityData.supplierCityData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxPurchaseAmount = len > 0
        ? supplierCityData.supplierCityData
              .map((data) => data.salesAmount)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
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
                sideTitles: _bottomTitlesSupplierCityWiseAnalysis,
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
            barGroups: _supplierCityWiseAnalysisChartData(
              supplierCityData.supplierCityData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedSupplierCity = touchedSupplierCity == ""
                          ? supplierCityData
                                .supplierCityData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .supplierCityName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedAgingCatg,
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedBranchName,
                        touchedWarehouse,
                        touchedSupplierCode,
                        touchedSupplierState,
                        touchedSupplierCity,
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
                    supplierCityData
                        .supplierCityData[grpIndex]
                        .supplierCityName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\n${formatAmount(supplierCityData.supplierCityData[grpIndex].salesAmount)}",
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

  void showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Options',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 150,
                          child: ListView.builder(
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(categories[index]),
                                selected: selectedCategoryIndex == index,
                                onTap: () {
                                  setState(() {
                                    selectedCategoryIndex = index;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        // Right side: Filter options as checkboxes
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child:
                                    selectedCategoryIndex ==
                                        categories.length -
                                            1 // "Date" index
                                    ? Column(
                                        children: [
                                          ListTile(
                                            title: const Text("From Date"),
                                            subtitle: Text(
                                              fromDateFilter != null
                                                  ? "${fromDateFilter!.day}/${fromDateFilter!.month}/${fromDateFilter!.year}"
                                                  : formatDateString(
                                                      fiscalYearStartDate!,
                                                    ),
                                            ),
                                            trailing: const Icon(
                                              Icons.calendar_today,
                                            ),
                                            onTap: () async {
                                              final picked =
                                                  await showDatePicker(
                                                    context: context,
                                                    initialDate:
                                                        fromDateFilter ??
                                                        DateTime.now(),
                                                    firstDate:
                                                        fiscalYearStartDate!,
                                                    lastDate: currentDate!,
                                                  );
                                              if (picked != null) {
                                                setState(() {
                                                  fromDateFilter = picked;
                                                  dateFilterFlag = true;
                                                });
                                              }
                                            },
                                          ),
                                          ListTile(
                                            title: const Text("To Date"),
                                            subtitle: Text(
                                              toDateFilter != null
                                                  ? "${toDateFilter!.day}/${toDateFilter!.month}/${toDateFilter!.year}"
                                                  : formatDateString(
                                                      currentDate!,
                                                    ),
                                            ),
                                            trailing: const Icon(
                                              Icons.calendar_today,
                                            ),
                                            onTap: () async {
                                              final picked =
                                                  await showDatePicker(
                                                    context: context,
                                                    initialDate:
                                                        toDateFilter ??
                                                        DateTime.now(),
                                                    firstDate:
                                                        fiscalYearStartDate!,
                                                    lastDate: currentDate!,
                                                  );
                                              if (picked != null) {
                                                setState(() {
                                                  toDateFilter = picked;
                                                  dateFilterFlag = true;
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      )
                                    : ListView.builder(
                                        itemCount:
                                            filterOptions[selectedCategoryIndex]
                                                .length,
                                        itemBuilder: (context, index) {
                                          return CheckboxListTile(
                                            title: Text(
                                              filterOptions[selectedCategoryIndex][index],
                                            ),
                                            value:
                                                savedFinanceReceivablesOptions[selectedCategoryIndex][index],
                                            onChanged: (bool? value) {
                                              setState(() {
                                                if (value == true) {
                                                  selectedFinanceReceivablesOptions[selectedCategoryIndex][index] =
                                                      true;
                                                } else {
                                                  selectedFinanceReceivablesOptions[selectedCategoryIndex][index] =
                                                      false;
                                                }
                                                savedFinanceReceivablesOptionsTemp =
                                                    savedFinanceReceivablesOptions;
                                                if (savedFinanceReceivablesOptions
                                                    .isEmpty) {
                                                  savedFinanceReceivablesOptionsTemp =
                                                      savedFinanceReceivablesOptions;
                                                }
                                                savedFinanceReceivablesOptions =
                                                    selectedFinanceReceivablesOptions;
                                              });
                                              // your checkbox logic
                                            },
                                          );
                                        },
                                      ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff2ca9df),
                                      minimumSize: const Size(10, 10),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () {
                                      List<String> selectedFilterOptions = [];
                                      for (
                                        int i = 0;
                                        i <
                                            filterOptions[selectedCategoryIndex]
                                                .length;
                                        i++
                                      ) {
                                        if (selectedFinanceReceivablesOptions[selectedCategoryIndex][i]) {
                                          selectedFilterOptions.add(
                                            filterOptions[selectedCategoryIndex][i],
                                          );
                                        }
                                      }
                                      for (
                                        int catIndex = 0;
                                        catIndex < categories.length;
                                        catIndex++
                                      ) {
                                        String categoryName =
                                            categories[catIndex];
                                        Map<String, bool> optionsState = {};

                                        for (
                                          int optionIndex = 0;
                                          optionIndex <
                                              filterOptions[catIndex].length;
                                          optionIndex++
                                        ) {
                                          optionsState[filterOptions[catIndex][optionIndex]] =
                                              selectedFinanceReceivablesOptions[catIndex][optionIndex];
                                        }

                                        allCategoriesState[categoryName] =
                                            optionsState;
                                      }

                                      Navigator.pop(context);

                                      selectedSalesData = selectedFilterOptions;

                                      fromFilter = false;

                                      savedFinanceReceivablesOptionsTemp =
                                          savedFinanceReceivablesOptions;

                                      // toggleCheckbox();
                                      loadDataFuture = filterFunction();

                                      setState(() {
                                        resetFinanceReceivablesOptions();
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Apply Filter',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      minimumSize: const Size(10, 10),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        chartDataLoaded = false;
                                      });
                                      fromFilter = false;
                                      savedFinanceReceivablesOptionsTemp
                                          .clear();
                                      setState(() {
                                        fromDateFilter = null;
                                        toDateFilter = null;
                                        dateFilterFlag = false;
                                        chartDataLoaded = false;
                                        chartDataLoaded = false;
                                        setState(() {
                                          chartDataLoaded = false;
                                        });
                                        loadDataFuture = removeFilter();
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Clear Filter',
                                        style: TextStyle(
                                          color: Color(0xff2ca9df),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
