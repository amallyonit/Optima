// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference
import 'package:optima/excel_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
// import 'package:optima/pages/dashboardPages/productionDashboardBI/jobCardEntryForAlternateMaterials.dart';
import 'package:optima/pages/dashboardPages/platform_excel_helper.dart';
import 'package:optima/pages/dashboardPages/platform_pdf_helper.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;
import 'package:open_file/open_file.dart';

class ProcurementAnalysis extends StatefulWidget {
  const ProcurementAnalysis({super.key});

  @override
  State<ProcurementAnalysis> createState() => _ProcurementAnalysisState();
}

late Future<void> loadDataFuture;
bool chartDataLoaded = false;
int _touchedIndex = -1;

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

ReceivablesFinanceList receivablesFinanceList = ReceivablesFinanceList(
  agingData: [],
);

List<PurchaseList> purchase = [];
List<Users> usersList = [];
String UserLevel = "0";

MonthlyPurchaseList monthData = MonthlyPurchaseList(monthlyData: []);
PurchaseItemAnalysisList itemData = PurchaseItemAnalysisList(productData: []);
PurchaseItemGroupWiseAnalysisList itemGroupData =
    PurchaseItemGroupWiseAnalysisList(productGroupData: []);
PurchaseItemSubGroupWiseAnalysisList itemSubGroupData =
    PurchaseItemSubGroupWiseAnalysisList(productSubGroupData: []);
PurchaseBranchAnalysisList branchData = PurchaseBranchAnalysisList(
  branchData: [],
);
PurchaseSupplierAnalysisList supplierList = PurchaseSupplierAnalysisList(
  supplierData: [],
);
PurchaseSupplierStateWiseAnalysisList supplierStateList =
    PurchaseSupplierStateWiseAnalysisList(supplierStateData: []);
PurchaseSupplierCityWiseAnalysisList supplierCityList =
    PurchaseSupplierCityWiseAnalysisList(supplierCityData: []);
PurchaseSupplierCategoryWiseAnalysisList supplierCategoryList =
    PurchaseSupplierCategoryWiseAnalysisList(supplierCategoryData: []);
PurchaseWarehouseAnalysisList warehouseData = PurchaseWarehouseAnalysisList(
  warehouseData: [],
);
int touchedMonthIndex = 0;
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

final List<String> categories = [
  'Date',
];

List<List<String>> filterOptions = [

  [],
];

List<List<bool>> selectedFinanceReceivablesOptions = [];

List<List<bool>> savedFinanceReceivablesOptionsTemp = [];

List<List<bool>> savedFinanceReceivablesOptions = filterOptions
    .map((options) => List<bool>.filled(options.length, false))
    .toList();

List<String> listOfRSM = [];
List<String> listOfASM = [];
List<String> listOfTSM = [];

double sumOfCustomerCategoryWise = 0;

Map<String, Map<String, bool>> allCategoriesState = {};

int selectedCategoryIndex = 0;

bool fromFilter = false;
List<String> selectedSalesData = [];

DateTime? fromDateFilter;
DateTime? toDateFilter;
bool dateFilterFlag = false;

class PurchaseProcurementAnalysisProvider with ChangeNotifier {
  List<PurchaseList> _salesList = [];
  List<PurchaseList> get salesList => _salesList;
  void updatePurchaseList(List<PurchaseList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class _ProcurementAnalysisState extends State<ProcurementAnalysis> {
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

  Color getCategoryColor(String category) {
    switch (category) {
      case const ("Crs. - Raw Material"):
        return const Color(0xFF97D7F3);
      case const ("Crs. - Medical Devices"):
        return const Color(0xFFF49136);
      case const ("Crs. - Expenses"):
        return const Color(0xFF6CCC3F);
      case const ("Crs. - Traded Material"):
        return const Color(0xFFFF4A4C);
      case const ("Crs. - Packing Material"):
        return const Color(0xFF8F8F8F);
      case const ("Sundry Creditors"):
        return Colors.purple;
      case const ("Crs. - Others"):
        return Colors.pink;
      case const ("Crs. - Capital Goods"):
        return Colors.brown;
      default:
        return Colors.yellowAccent;
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

  SideTitles get _monthlyBottomTitles =>
      SideTitles(showTitles: true, getTitlesWidget: getMonthwiseBottomTitles);

  Widget getMonthwiseBottomTitles(double val, TitleMeta meta) {
    String text = '';
    MonthlyPurchaseData monthlyPurchaseData = monthData.monthlyData.elementAt(
      val.toInt(),
    );
    text = monthlyPurchaseData.monthName;
    return Text(text.length > 3 ? text.substring(0, 3) : text);
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

  SideTitles get _bottomTitlesItemAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<PurchaseItemAnalysisData> mData = itemData.productData;
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
      List<PurchaseItemGroupWiseAnalysisData> mData =
          itemGroupData.productGroupData;
      text = mData.elementAt(value.toInt()).groupName;
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
      List<PurchaseItemSubGroupWiseAnalysisData> mData =
          itemSubGroupData.productSubGroupData;
      text = mData.elementAt(value.toInt()).itemSubGroup;
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
      List<PurchaseBranchAnalysisData> mData = branchData.branchData;
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
      List<PurchaseWarehouseAnalysisData> mData = warehouseData.warehouseData;
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
      List<PurchaseSupplierAnalysisData> mData = supplierList.supplierData;
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
      List<PurchaseSupplierStateWiseAnalysisData> mData =
          supplierStateList.supplierStateData;
      text = mData.elementAt(value.toInt()).vendorState;
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
      List<PurchaseSupplierCityWiseAnalysisData> mData =
          supplierCityList.supplierCityData;
      text = mData.elementAt(value.toInt()).vendorCity;
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

  List<BarChartGroupData> _monthWisePurchaseAnalysisChartData(
    List<MonthlyPurchaseData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
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
    List<PurchaseItemAnalysisData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  color: const Color(0xFF97D7F3),
                  toY: chartData.salesAmount,
                  fromY: 0,
                  show: true,
                ),
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.monthsAvg,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _itemGroupWiseAnalysisChartData(
    List<PurchaseItemGroupWiseAnalysisData> data,
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
    List<PurchaseItemSubGroupWiseAnalysisData> data,
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

  List<BarChartGroupData> _branchAnalysisChartData(
    List<PurchaseBranchAnalysisData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  color: const Color(0xFF97D7F3),
                  toY: chartData.rowTotal,
                  fromY: 0,
                  show: true,
                ),
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.monthAvg,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _warehouseWiseAnalysisChartData(
    List<PurchaseWarehouseAnalysisData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  color: const Color(0xFF97D7F3),
                  toY: chartData.rowTotal,
                  fromY: 0,
                  show: true,
                ),
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.monthAvg,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _supplierAnalysisChartData(
    List<PurchaseSupplierAnalysisData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  color: const Color(0xFF97D7F3),
                  toY: chartData.rowTotal,
                  fromY: 0,
                  show: true,
                ),
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.monthAvg,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _supplierStateWiseAnalysisChartData(
    List<PurchaseSupplierStateWiseAnalysisData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  color: const Color(0xFF97D7F3),
                  toY: chartData.rowTotal,
                  fromY: 0,
                  show: true,
                ),
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.monthAvg,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _supplierCityWiseAnalysisChartData(
    List<PurchaseSupplierCityWiseAnalysisData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  color: const Color(0xFF97D7F3),
                  toY: chartData.rowTotal,
                  fromY: 0,
                  show: true,
                ),
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.monthAvg,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<PieChartSectionData> showingSectionsSupplierCategory() {
    final List<PieChartSectionData> sections = [];
    for (final categoryData in supplierCategoryList.supplierCategoryData) {
      final radius =
          supplierCategoryList.supplierCategoryData.indexOf(categoryData) >= 1
          ? 80.0
          : 75.0;
      final sectionData = PieChartSectionData(
        badgePositionPercentageOffset: 0,
        color: getCategoryColor(categoryData.supplierCategory),
        value: categoryData.percentage,
        badgeWidget:
            _touchedIndex ==
                supplierCategoryList.supplierCategoryData.indexOf(categoryData)
            ? Container(
                color: Colors.white,
                child: Text(
                  '${categoryData.supplierCategory} '
                  '\n${categoryData.percentage}%  \n${formatAmount(categoryData.amount)}',
                  style: const TextStyle(fontSize: 10),
                ),
              )
            : const SizedBox(height: 1),
        // title: _touchedIndex ==
        //         supplierCategoryList.supplierCategoryData.indexOf(categoryData)
        //     ? '${categoryData.supplierCategory} \n${categoryData.percentage}%'
        //     : "",
        radius: radius,
        title: "",
        // titleStyle: TextStyle(
        //   fontSize: fontSize,
        //   color: Colors.black,
        //   shadows: shadows,
        // ),
      );
      sections.add(sectionData);
    }
    return sections;
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

  int monthDifference(DateTime startDate, DateTime endDate) {
    int years = endDate.year - startDate.year;
    int months = endDate.month - startDate.month;
    int differenceInMonths = (years * 12) + months;
    return differenceInMonths;
  }

  Future<void> _loadEachQtrValues() async {
    double sum = 0;
    int MonthDiffs = 0;
    for (int i = 1; i <= getCurrentQuarter(); i++) {
      switch (i) {
        case 1:
          sum = 0;
          MonthDiffs = monthDifference(q1FromDate!, currentDate!) == 0
              ? 1
              : monthDifference(q1FromDate!, currentDate!);

          Q1Target = 75000000;
          Q1TargetStr = "${(Q1Target / 100000).toStringAsFixed(2)} L";
          var curQtrSales = purchase.where((target) {
            DateTime invoiceDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.invoiceDate);
            return invoiceDate.isAtLeast(q1FromDate!) &&
                invoiceDate.isAtMost(q1ToDate!);
          });
          sum = 0;
          double salesAmt = 0;
          for (var target in curQtrSales.toList()) {
            if (target.invoiceType != "Sales Return") {
              salesAmt = double.tryParse(target.rowTotal) ?? 0;
            } else {
              salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
            }
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
          sum = 0;
          MonthDiffs = monthDifference(q2FromDate!, currentDate!) == 0
              ? 1
              : monthDifference(q2FromDate!, currentDate!);

          Q2Target = 75000000;
          Q2TargetStr = "${(Q2Target / 100000).toStringAsFixed(2)} L";
          var curQtrSales = purchase.where((target) {
            DateTime invoiceDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.invoiceDate);
            return invoiceDate.isAtLeast(q2FromDate!) &&
                invoiceDate.isAtMost(q2ToDate!);
          });
          sum = 0;
          double salesAmt = 0;
          for (var target in curQtrSales.toList()) {
            if (target.invoiceType != "Sales Return") {
              salesAmt = double.tryParse(target.rowTotal) ?? 0;
            } else {
              salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
            }
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
          sum = 0;
          MonthDiffs = monthDifference(q3FromDate!, currentDate!) == 0
              ? 1
              : monthDifference(q3FromDate!, currentDate!);
          Q3Target = 75000000;
          Q3TargetStr = "${(Q3Target / 100000).toStringAsFixed(2)} L";
          var curQtrSales = purchase.where((target) {
            DateTime invoiceDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.invoiceDate);
            return invoiceDate.isAtLeast(q3FromDate!) &&
                invoiceDate.isAtMost(q3ToDate!);
          });
          sum = 0;
          double salesAmt = 0;
          for (var target in curQtrSales.toList()) {
            if (target.invoiceType != "Sales Return") {
              salesAmt = double.tryParse(target.rowTotal) ?? 0;
            } else {
              salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
            }
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
          sum = 0;
          MonthDiffs = monthDifference(q4FromDate!, currentDate!) == 0
              ? 1
              : monthDifference(q4FromDate!, currentDate!);

          Q4Target = 75000000;
          Q4TargetStr = "${(Q4Target / 100000).toStringAsFixed(2)} L";
          var curQtrSales = purchase.where((target) {
            DateTime invoiceDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.invoiceDate);
            return invoiceDate.isAtLeast(q4FromDate!) &&
                invoiceDate.isAtMost(q4ToDate!);
          });
          sum = 0;
          double salesAmt = 0;
          for (var target in curQtrSales.toList()) {
            if (target.invoiceType != "Sales Return") {
              salesAmt = double.tryParse(target.rowTotal) ?? 0;
            } else {
              salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
            }
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

  Future<void> _loadPurchase(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000; // Maximum limit to fetch all data
    int fetchedCount = 0;
    List<PurchaseList> salesList = [];
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
        const apiUrl = '${ApiHelper.baseUrl}BicxoPurchaseList';
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
            List<PurchaseList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => PurchaseList.fromJson(item))
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
        purchase = salesList;
        context.read<PurchaseProcurementAnalysisProvider>().updatePurchaseList(
          salesList,
        );

        purchase = salesList
            .where((sale) => sale.type == "Item Purchase")
            .toList();

        purchase = purchase
            .where((sale) => sale.itemGroup != "Fixed Assets")
            .toList();

        purchase = purchase
            .where((sale) => sale.invoiceType == "Purchase")
            .toList();

        purchase = purchase.where((target) {
          DateTime invoiceDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.invoiceDate);

          return invoiceDate.isAtLeast(fiscalYearStartDate!) &&
              invoiceDate.isAtMost(currentDate!);
        }).toList(); // salesList.toList();
      });

      var currentMonthSales = purchase.where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);

        return invoiceDate.isAtLeast(currentMonthFromDate!) &&
            invoiceDate.isAtMost(currentDate!);
      });
      double sum = 0;
      double salesAmt = 0;
      for (var target in currentMonthSales.toList()) {
        if (target.invoiceType != "Purchase Return") {
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
        } else {
          salesAmt = (double.tryParse(target.rowTotal) ?? 0)
          /** -1*/
          ;
        }
        sum += salesAmt;
      }
      SalesGoal = 25000000;
      SalesGoalStr = "2.5 Cr";
      CurrentMonthSales = sum;
      CurrentMonthSalesStr =
          "${(CurrentMonthSales / 100000).toStringAsFixed(2)} L";
      if (CurrentMonthSales == 0) {
        CurrentMonthSalesPercentage = 0;
      } else {
        CurrentMonthSalesPercentage =
            double.tryParse(
              ((CurrentMonthSales / SalesGoal) * 100).toStringAsFixed(0),
            )?.ceil() ??
            0;
      }
      CurrentMonthSalesPercentageStr =
          "${CurrentMonthSalesPercentage.toString()} %";

      if (CurrentMonthSalesPercentage > 100) {
        CurrentMonthSalesPercentage = 100;
      }

      var lastMonthSales = purchase.where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);

        return invoiceDate.isAtLeast(lastMonthFromDate!) &&
            invoiceDate.isAtMost(lastMonthToDate!);
      });

      sum = 0;
      salesAmt = 0;
      for (var target in lastMonthSales.toList()) {
        if (target.invoiceType != "Purchase Return") {
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
        } else {
          salesAmt = (double.tryParse(target.rowTotal) ?? 0)
          /** -1*/
          ;
        }
        sum += salesAmt;
      }

      LastMonthTarget = 25000000;
      LastMonthTargetStr = "2.5 Cr";
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

      var curQtrSales = purchase.where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        return invoiceDate.isAtLeast(currentQuarterFromDate!) &&
            invoiceDate.isAtMost(currentQuarterToDate!);
      });

      sum = 0;
      salesAmt = 0;
      for (var target in curQtrSales.toList()) {
        if (target.invoiceType != "Purchase Return") {
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
        } else {
          salesAmt = (double.tryParse(target.rowTotal) ?? 0)
          /** -1*/
          ;
        }
        sum += salesAmt;
      }

      CurrentQtrTarget = 75000000;
      CurrentQtrTargetStr = "7.5 Cr";
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

      var ytdSales = purchase.where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        return invoiceDate.isAtLeast(fiscalYearStartDate!) &&
            invoiceDate.isAtMost(currentDate!);
      });

      sum = 0;
      salesAmt = 0;
      for (var target in ytdSales.toList()) {
        if (target.invoiceType != "Purchase Return") {
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
        } else {
          salesAmt = (double.tryParse(target.rowTotal) ?? 0)
          /** -1*/
          ;
        }
        sum += salesAmt;
      }

      int getMonthsDifference(int currentMonth, int financialYearStartMonth) {
        DateTime currentDate = DateTime.now();
        DateTime financialYearStartDate = DateTime(
          currentDate.year,
          financialYearStartMonth,
          1,
        );

        if (currentDate.month < financialYearStartMonth) {
          financialYearStartDate = financialYearStartDate.subtract(
            const Duration(days: 365),
          );
        }

        int monthsDifference =
            (currentDate.year - financialYearStartDate.year) * 12 +
            currentDate.month -
            financialYearStartDate.month;

        return monthsDifference;
      }

      YtdTarget =
          25000000 *
          (getMonthsDifference(DateTime.now().month, 4).toDouble() + 1);
      YtdTargetStr = "${(YtdTarget / 10000000).toString()} Cr";
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
    }
  }

  Future<void> _loadMonthWisePurchaseAnalysis() async {
    List<MonthlyPurchaseData> monthlyDataList = [];
    for (int i = 4; i <= 15; i++) {
      String monthName = getMonthName(i);
      double monthlySales = 0.00;

      var monthlySalesList = const Iterable.empty();
      if (i >= 4 && i <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(i);
        monthlySalesList = purchase.where((target) {
          DateTime invoiceDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.invoiceDate);
          return invoiceDate.isAtLeast(monthDates['start']!) &&
              invoiceDate.isAtMost(monthDates['end']!);
        });
      } else {
        // int currentYear = DateTime.now().month < 4
        //     ? DateTime.now().year
        //     : DateTime.now().year - 1 ;
        //
        // startDate = DateTime(currentYear, i - 12, 1);
        // endDate = DateTime(currentYear, (i - 12) + 1, 0);

        Map<String, DateTime> monthDates = getMonthStartEndDates(i - 12);

        monthlySalesList = purchase.where((target) {
          DateTime invoiceDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.invoiceDate);
          return invoiceDate.isAtLeast(monthDates['start']!) &&
              invoiceDate.isAtMost(monthDates['end']!);
        });
      }
      double salesAmt = 0;
      List tempList = monthlySalesList.toList();
      for (var target in tempList) {
        salesAmt = (double.tryParse(target.rowTotal) ?? 0);
        monthlySales += salesAmt;
      }
      monthlyDataList.add(
        MonthlyPurchaseData(
          monthName: monthName,
          collectionAmount: monthlySales,
        ),
      );
      monthlySales = 0;
    }
    monthData = MonthlyPurchaseList(monthlyData: monthlyDataList);
  }

  Future<void> _loadItemAnalysis(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String branchName,
    String warehouseName,
    String supplierCode,
    String supplierState,
    String supplierCity,
    String supplierCategory,
  ) async {
    List<PurchaseItemAnalysisData> productwiseDataList = [];
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
      curMthSalesTarget = purchase.toList().where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        return (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate));
      });

      productSalesList = purchase.toList().where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
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

      curMthSalesTarget = purchase.where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        return invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate);
      });

      productSalesList = purchase.where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }
    saleList = filterPurchaseList(
      productSalesList.cast<PurchaseList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
      supplierCategory: supplierCategory,
    );
    saleList3Months = filterPurchaseList(
      curMthSalesTarget.cast<PurchaseList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
      supplierCategory: supplierCategory,
    );

    Set<String> processedProductCodes = {};
    for (var product in saleList.toList().toList()) {
      if (!processedProductCodes.contains(product.description)) {
        itemName = product.description;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.description == itemName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
          productSales += salesAmt;
        }
        for (var target in saleList3Months.toList().where(
          (element) => element.description == itemName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
          productTarget += salesAmt;
        }

        productwiseDataList.add(
          PurchaseItemAnalysisData(
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
    itemData = PurchaseItemAnalysisList(productData: productwiseDataList);
  }

  Future<void> _loadItemGroupWiseAnalysis(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String branchName,
    String warehouseName,
    String supplierCode,
    String supplierState,
    String supplierCity,
    String supplierCategory,
  ) async {
    List<PurchaseItemGroupWiseAnalysisData> productwiseDataList = [];
    String itemGroup = "";
    double productSales = 0.00;
    var productSalesList = const Iterable.empty();
    var saleList = const Iterable.empty();
    DateTime startDate;
    DateTime endDate;

    if (monthIndex == 0) {
      startDate = fiscalYearStartDate!;
      endDate = currentDate!;
      productSalesList = purchase.toList().where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        return (invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate));
      });
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      productSalesList = purchase.where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }

    saleList = filterPurchaseList(
      productSalesList.cast<PurchaseList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
      supplierCategory: supplierCategory,
    );

    Set<String> processedGroupNames = {};
    for (var product in saleList.toList().toList()) {
      if (!processedGroupNames.contains(product.itemGroup)) {
        itemGroup = product.itemGroup;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.itemGroup == itemGroup,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
          productSales += salesAmt;
        }
        productwiseDataList.add(
          PurchaseItemGroupWiseAnalysisData(
            groupName: itemGroup,
            salesAmount: productSales,
          ),
        );
        processedGroupNames.add(product.itemGroup);
      }
      productSales = 0;
      itemGroup = "";
    }
    productwiseDataList.sort((a, b) => b.salesAmount.compareTo(a.salesAmount));

    itemGroupData = PurchaseItemGroupWiseAnalysisList(
      productGroupData: productwiseDataList,
    );
  }

  Future<void> _loadItemSubGroupWiseAnalysis(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String branchName,
    String warehouseName,
    String supplierCode,
    String supplierState,
    String supplierCity,
    String supplierCategory,
  ) async {
    List<PurchaseItemSubGroupWiseAnalysisData> productwiseDataList = [];
    var tempList = purchase;
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
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        return (invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate));
      });
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      productSalesList = tempList.where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }
    saleList = filterPurchaseList(
      productSalesList.cast<PurchaseList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
      supplierCategory: supplierCategory,
    );

    Set<String> processedSubGroups = {};
    for (var product in saleList.toList().toList()) {
      if (!processedSubGroups.contains(product.itemSubGroup)) {
        itemSubGroup = product.itemSubGroup;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.itemSubGroup == itemSubGroup,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
          productSales += salesAmt;
        }

        productwiseDataList.add(
          PurchaseItemSubGroupWiseAnalysisData(
            itemSubGroup: itemSubGroup,
            salesAmount: productSales,
          ),
        );
        processedSubGroups.add(product.itemSubGroup);
      }
      productSales = 0;
      itemSubGroup = "";
    }
    productwiseDataList.sort((a, b) => b.salesAmount.compareTo(a.salesAmount));

    itemSubGroupData = PurchaseItemSubGroupWiseAnalysisList(
      productSubGroupData: productwiseDataList,
    );
  }

  Future<void> _loadBranchAnalysis(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String branchName,
    String warehouseName,
    String supplierCode,
    String supplierState,
    String supplierCity,
    String supplierCategory,
  ) async {
    List<PurchaseBranchAnalysisData> branchDetail = [];
    var tempList = purchase;
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
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        return (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate));
      });

      productSalesList = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
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
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        return invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate);
      });

      productSalesList = tempList.where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }
    saleList = filterPurchaseList(
      productSalesList.cast<PurchaseList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
      supplierCategory: supplierCategory,
    );
    saleList3Months = filterPurchaseList(
      curMthSalesTarget.cast<PurchaseList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
      supplierCategory: supplierCategory,
    );

    Set<String> processedBranches = {};
    for (var product in saleList.toList().toList()) {
      if (!processedBranches.contains(product.branchName)) {
        branchName = product.branchName;
        for (var target in productSalesList.toList().where(
          (prdelement) => prdelement.branchName == branchName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
          productSales += salesAmt;
        }
        for (var target in saleList3Months.toList().where(
          (element) => element.branchName == branchName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
          productTarget += salesAmt;
        }

        branchDetail.add(
          PurchaseBranchAnalysisData(
            branchName: branchName,
            rowTotal: productSales,
            monthAvg: productTarget / 3,
          ),
        );
        processedBranches.add(product.branchName);
      }
      productSales = 0;
      productTarget = 0;
      branchName = "";
    }
    branchDetail.sort((a, b) => b.rowTotal.compareTo(a.rowTotal));

    branchData = PurchaseBranchAnalysisList(branchData: branchDetail);
  }

  Future<void> _loadSupplierAnalysis(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String branchName,
    String warehouseName,
    String supplierCode,
    String supplierState,
    String supplierCity,
    String supplierCategory,
  ) async {
    List<PurchaseSupplierAnalysisData> branchDetail = [];

    var tempList = filterPurchaseList(
      purchase.cast<PurchaseList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
      supplierCategory: supplierCategory,
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
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        if (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate)) {
          double salesAmt = double.tryParse(target.rowTotal) ?? 0;
          vendorTargetMap.update(
            target.vendorName,
            (existingTarget) => existingTarget + salesAmt,
            ifAbsent: () => salesAmt,
          );
        }
      }
      for (var target in tempList) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        if (invoiceDate.isAtLeast(startDate) && invoiceDate.isAtMost(endDate)) {
          double salesAmt = double.tryParse(target.rowTotal) ?? 0;
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
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        if (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate)) {
          double salesAmt = double.tryParse(target.rowTotal) ?? 0;
          vendorTargetMap.update(
            target.vendorName,
            (existingTarget) => existingTarget + salesAmt,
            ifAbsent: () => salesAmt,
          );
        }
      }
      for (var target in tempList) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        if (invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!)) {
          double salesAmt = double.tryParse(target.rowTotal) ?? 0;
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
      branchDetail.add(
        PurchaseSupplierAnalysisData(
          supplierName: vendorName,
          rowTotal: productSales,
          monthAvg: productTarget / 3,
        ),
      );
    });

    branchDetail.sort((a, b) => b.rowTotal.compareTo(a.rowTotal));
    supplierList = PurchaseSupplierAnalysisList(supplierData: branchDetail);
  }

  Future<void> _loadSupplierStateAnalysis(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String branchName,
    String warehouseName,
    String supplierCode,
    String supplierState,
    String supplierCity,
    String supplierCategory,
  ) async {
    List<PurchaseSupplierStateWiseAnalysisData> branchDetail = [];
    var tempList = filterPurchaseList(
      purchase.cast<PurchaseList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
      supplierCategory: supplierCategory,
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
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        if (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate)) {
          double salesAmt = double.tryParse(target.rowTotal) ?? 0;
          vendorTargetMap.update(
            target.vendorState,
            (existingTarget) => existingTarget + salesAmt,
            ifAbsent: () => salesAmt,
          );
        }
      }
      for (var target in tempList) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        if (invoiceDate.isAtLeast(startDate) && invoiceDate.isAtMost(endDate)) {
          double salesAmt = double.tryParse(target.rowTotal) ?? 0;
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
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        if (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate)) {
          double salesAmt = double.tryParse(target.rowTotal) ?? 0;
          vendorTargetMap.update(
            target.vendorState,
            (existingTarget) => existingTarget + salesAmt,
            ifAbsent: () => salesAmt,
          );
        }
      }
      for (var target in tempList) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        if (invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!)) {
          double salesAmt = double.tryParse(target.rowTotal) ?? 0;
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
      branchDetail.add(
        PurchaseSupplierStateWiseAnalysisData(
          vendorState: vendorState,
          rowTotal: productSales,
          monthAvg: productTarget / 3,
        ),
      );
    });

    branchDetail.sort((a, b) => b.rowTotal.compareTo(a.rowTotal));
    supplierStateList = PurchaseSupplierStateWiseAnalysisList(
      supplierStateData: branchDetail,
    );
  }

  Future<void> _loadSupplierCityAnalysis(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String branchName,
    String warehouseName,
    String supplierCode,
    String supplierState,
    String supplierCity,
    String supplierCategory,
  ) async {
    List<PurchaseSupplierCityWiseAnalysisData> branchDetail = [];
    var tempList = filterPurchaseList(
      purchase.cast<PurchaseList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
      supplierCategory: supplierCategory,
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
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        if (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate)) {
          double salesAmt = double.tryParse(target.rowTotal) ?? 0;
          cityTargetMap.update(
            target.vendorCity,
            (existingTarget) => existingTarget + salesAmt,
            ifAbsent: () => salesAmt,
          );
        }
      }
      for (var target in tempList) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        if (invoiceDate.isAtLeast(startDate) && invoiceDate.isAtMost(endDate)) {
          double salesAmt = double.tryParse(target.rowTotal) ?? 0;
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
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        if (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate)) {
          double salesAmt = double.tryParse(target.rowTotal) ?? 0;
          cityTargetMap.update(
            target.vendorCity,
            (existingTarget) => existingTarget + salesAmt,
            ifAbsent: () => salesAmt,
          );
        }
      }
      for (var target in tempList) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        if (invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!)) {
          double salesAmt = double.tryParse(target.rowTotal) ?? 0;
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
      branchDetail.add(
        PurchaseSupplierCityWiseAnalysisData(
          vendorCity: vendorCity,
          rowTotal: productSales,
          monthAvg: productTarget / 3,
        ),
      );
    });

    // Sort the result by total sales
    branchDetail.sort((a, b) => b.rowTotal.compareTo(a.rowTotal));

    supplierCityList = PurchaseSupplierCityWiseAnalysisList(
      supplierCityData: branchDetail,
    );
  }

  Future<void> _loadSupplierCategoryAnalysis(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String branchName,
    String warehouseName,
    String supplierCode,
    String supplierState,
    String supplierCity,
    String supplierCategory,
  ) async {
    List<PurchaseSupplierCategoryWiseAnalysisData> branchDetail = [];
    var tempList = purchase;
    String vendorGroup = "";
    double productSales = 0.00;
    int categoryId = 0;

    var productSalesList = const Iterable.empty();
    var saleList = const Iterable.empty();
    DateTime startDate;
    DateTime endDate;

    if (monthIndex == 0) {
      startDate = fiscalYearStartDate!;
      endDate = currentDate!;
      productSalesList = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        return (invoiceDate.isAtLeast(startDate) &&
            invoiceDate.isAtMost(endDate));
      });
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      productSalesList = tempList.where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }

    saleList = filterPurchaseList(
      productSalesList.cast<PurchaseList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
      supplierCategory: supplierCategory,
    );
    Set<String> processedVendorGroup = {};

    List vendorGroupList = saleList.toList();

    for (var product in vendorGroupList) {
      if (!processedVendorGroup.contains(product.vendorGroup)) {
        vendorGroup = product.vendorGroup;
        for (var target in productSalesList.toList().where(
          (prdelement) => prdelement.vendorGroup == vendorGroup,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
          productSales += salesAmt;
        }

        branchDetail.add(
          PurchaseSupplierCategoryWiseAnalysisData(
            categoryId: categoryId++,
            supplierCategory: vendorGroup,
            amount: productSales,
            percentage: 0,
          ),
        );
        processedVendorGroup.add(product.vendorGroup);
      }
      productSales = 0;
      vendorGroup = "";
    }

    // branchDetail.removeWhere((ele) =>
    //     ele.supplierCategory != "Company" &&
    //     ele.supplierCategory != "Distributor");

    double totalAmount = branchDetail.fold(
      0,
      (
        double previousValue,
        PurchaseSupplierCategoryWiseAnalysisData element,
      ) => previousValue + element.amount,
    );
    for (PurchaseSupplierCategoryWiseAnalysisData categoryData
        in branchDetail) {
      categoryData.percentage =
          double.tryParse(
            ((categoryData.amount / totalAmount) * 100).toStringAsFixed(2),
          ) ??
          0;
    }

    supplierCategoryList = PurchaseSupplierCategoryWiseAnalysisList(
      supplierCategoryData: branchDetail,
    );
  }

  Future<void> _loadWarehouseAnalysis(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String branchName,
    String warehouseName,
    String supplierCode,
    String supplierState,
    String supplierCity,
    String supplierCategory,
  ) async {
    List<PurchaseWarehouseAnalysisData> warehouseDetail = [];
    var tempList = purchase;
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
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        return (invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate));
      });

      productSalesList = tempList.toList().where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
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
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        return invoiceDate.isAtLeast(prevThreethFromDate) &&
            invoiceDate.isAtMost(prevThreeMthToDate);
      });

      productSalesList = tempList.where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.invoiceDate);
        return invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!);
      });
    }

    saleList = filterPurchaseList(
      productSalesList.cast<PurchaseList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
      supplierCategory: supplierCategory,
    );
    saleList3Months = filterPurchaseList(
      curMthSalesTarget.cast<PurchaseList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      branchName: branchName,
      warehouseName: warehouseName,
      supplierCode: supplierCode,
      supplierState: supplierState,
      supplierCity: supplierCity,
      supplierCategory: supplierCategory,
    );

    Set<String> processedBranches = {};
    for (var product in saleList.toList().toList()) {
      if (!processedBranches.contains(product.whsCode)) {
        warehouseCode = product.whsCode;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.whsCode == warehouseCode,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
          productSales += salesAmt;
        }
        for (var target in saleList3Months.toList().where(
          (element) => element.whsCode == warehouseCode,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.rowTotal) ?? 0;
          productTarget += salesAmt;
        }

        warehouseDetail.add(
          PurchaseWarehouseAnalysisData(
            warehouseName: warehouseCode,
            rowTotal: productSales,
            monthAvg: productTarget / 3,
          ),
        );
        processedBranches.add(product.whsCode);
      }
      productSales = 0;
      productTarget = 0;
      warehouseCode = "";
    }
    warehouseDetail.sort((a, b) => b.rowTotal.compareTo(a.rowTotal));

    warehouseData = PurchaseWarehouseAnalysisList(
      warehouseData: warehouseDetail,
    );
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadPurchase(userName, userLevel);
    await _loadEachQtrValues();
    await _loadMonthWisePurchaseAnalysis();
    await _loadItemAnalysis(0, "", "", "", "", "", "", "", "", "");
    await _loadItemGroupWiseAnalysis(0, "", "", "", "", "", "", "", "", "");
    await _loadItemSubGroupWiseAnalysis(0, "", "", "", "", "", "", "", "", "");
    await _loadBranchAnalysis(0, "", "", "", "", "", "", "", "", "");
    await _loadWarehouseAnalysis(0, "", "", "", "", "", "", "", "", "");
    await _loadSupplierAnalysis(0, "", "", "", "", "", "", "", "", "");
    await _loadSupplierStateAnalysis(0, "", "", "", "", "", "", "", "", "");
    await _loadSupplierCityAnalysis(0, "", "", "", "", "", "", "", "", "");
    await _loadSupplierCategoryAnalysis(0, "", "", "", "", "", "", "", "", "");
    chartDataLoaded = true;
  }

  List<PurchaseList> filterPurchaseList(
    List<PurchaseList> purchaseList, {
    String? itemCode,
    String? itemGroup,
    String? itemSubGroup,
    String? branchName,
    String? warehouseName,
    String? supplierCode,
    String? supplierState,
    String? supplierCity,
    String? supplierCategory,
  }) {
    List<PurchaseList> filteredPurchaseList = [];
    for (var purchase in purchaseList) {
      if ((itemCode == null ||
              itemCode.isEmpty ||
              purchase.description == itemCode) &&
          (itemGroup == null ||
              itemGroup.isEmpty ||
              purchase.itemGroup == itemGroup) &&
          (itemSubGroup == null ||
              itemSubGroup.isEmpty ||
              purchase.itemSubGroup == itemSubGroup) &&
          (branchName == null ||
              branchName.isEmpty ||
              purchase.branchName == branchName) &&
          (warehouseName == null ||
              warehouseName.isEmpty ||
              purchase.whsCode == warehouseName) &&
          (supplierCode == null ||
              supplierCode.isEmpty ||
              purchase.vendorCode == supplierCode) &&
          (supplierState == null ||
              supplierState.isEmpty ||
              purchase.vendorState == supplierState) &&
          (supplierCity == null ||
              supplierCity.isEmpty ||
              purchase.vendorCity == supplierCity) &&
          (supplierCategory == null ||
              supplierCategory.isEmpty ||
              purchase.vendorGroup == supplierCategory)) {
        filteredPurchaseList.add(purchase);
      }
    }

    return filteredPurchaseList;
  }

  Future<void> removeFilter() async {
    touchedMonthIndex = 0;
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
    LoadAllQuarterFromToDates();
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
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String branchName,
    String warehouseName,
    String supplierCode,
    String supplierState,
    String supplierCity,
    String supplierCategory,
  ) async {
    clearVariablesForFilter();
    LoadDates();
    LoadAllQuarterFromToDates();
    await _loadItemAnalysis(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      branchName,
      warehouseName,
      supplierCode,
      supplierState,
      supplierCity,
      supplierCategory,
    );
    await _loadItemGroupWiseAnalysis(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      branchName,
      warehouseName,
      supplierCode,
      supplierState,
      supplierCity,
      supplierCategory,
    );
    await _loadItemSubGroupWiseAnalysis(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      branchName,
      warehouseName,
      supplierCode,
      supplierState,
      supplierCity,
      supplierCategory,
    );
    await _loadBranchAnalysis(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      branchName,
      warehouseName,
      supplierCode,
      supplierState,
      supplierCity,
      supplierCategory,
    );
    await _loadWarehouseAnalysis(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      branchName,
      warehouseName,
      supplierCode,
      supplierState,
      supplierCity,
      supplierCategory,
    );
    await _loadSupplierAnalysis(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      branchName,
      warehouseName,
      supplierCode,
      supplierState,
      supplierCity,
      supplierCategory,
    );
    await _loadSupplierStateAnalysis(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      branchName,
      warehouseName,
      supplierCode,
      supplierState,
      supplierCity,
      supplierCategory,
    );
    await _loadSupplierCityAnalysis(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      branchName,
      warehouseName,
      supplierCode,
      supplierState,
      supplierCity,
      supplierCategory,
    );
    await _loadSupplierCategoryAnalysis(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      branchName,
      warehouseName,
      supplierCode,
      supplierState,
      supplierCity,
      supplierCategory,
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
      itemData = PurchaseItemAnalysisList(productData: []);
      itemGroupData = PurchaseItemGroupWiseAnalysisList(productGroupData: []);
      itemSubGroupData = PurchaseItemSubGroupWiseAnalysisList(
        productSubGroupData: [],
      );
      branchData = PurchaseBranchAnalysisList(branchData: []);
      supplierList = PurchaseSupplierAnalysisList(supplierData: []);
      supplierStateList = PurchaseSupplierStateWiseAnalysisList(
        supplierStateData: [],
      );
      supplierCityList = PurchaseSupplierCityWiseAnalysisList(
        supplierCityData: [],
      );
      supplierCategoryList = PurchaseSupplierCategoryWiseAnalysisList(
        supplierCategoryData: [],
      );
      warehouseData = PurchaseWarehouseAnalysisList(warehouseData: []);
      touchedMonthIndex = 0;
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
      itemData = PurchaseItemAnalysisList(productData: []);
      itemGroupData = PurchaseItemGroupWiseAnalysisList(productGroupData: []);
      itemSubGroupData = PurchaseItemSubGroupWiseAnalysisList(
        productSubGroupData: [],
      );
      branchData = PurchaseBranchAnalysisList(branchData: []);
      supplierList = PurchaseSupplierAnalysisList(supplierData: []);
      supplierStateList = PurchaseSupplierStateWiseAnalysisList(
        supplierStateData: [],
      );
      supplierCityList = PurchaseSupplierCityWiseAnalysisList(
        supplierCityData: [],
      );
      supplierCategoryList = PurchaseSupplierCategoryWiseAnalysisList(
        supplierCategoryData: [],
      );
      warehouseData = PurchaseWarehouseAnalysisList(warehouseData: []);
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

  Future<void> generatePurchaseExcel(
    MonthlyPurchaseList monthlyPurchaseList,
  ) async {
    double totalPurchaseAmount = 0;
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Month', 'Purchase Amount']));
      for (var monthlyData in monthlyPurchaseList.monthlyData) {
        sheet.appendRow(
          toCellRow([monthlyData.monthName, monthlyData.collectionAmount]),
        );
        totalPurchaseAmount += monthlyData.collectionAmount;
      }
      sheet.appendRow(toCellRow(["", totalPurchaseAmount]));

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('monthly_purchase_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthly_purchase_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generatePurchasePDF(
    MonthlyPurchaseList monthlyPurchaseList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Monthly Purchase Report',
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
                      'Purchase Amount',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var monthlyData in monthlyPurchaseList.monthlyData)
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
        final file = File('$storageDir/monthly_purchase_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemPurchaseExcel(
    PurchaseItemAnalysisList purchaseItemAnalysisList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'Product Name',
          'Actual',
          'Monthly Avg.',
          'Difference',
          'Percentage',
        ]),
      );
      for (var itemData in purchaseItemAnalysisList.productData) {
        sheet.appendRow(
          toCellRow([
            itemData.productName,
            itemData.salesAmount.toStringAsFixed(2),
            itemData.monthsAvg.toStringAsFixed(2),
            ((itemData.salesAmount - itemData.monthsAvg) / 100000)
                .toStringAsFixed(0),
            itemData.monthsAvg != 0
                ? ((itemData.salesAmount / itemData.monthsAvg) * 100)
                      .ceil()
                      .toStringAsFixed(0)
                : 0,
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('item_purchase_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/item_purchase_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemPurchasePDF(
    PurchaseItemAnalysisList purchaseItemAnalysisList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Productwise Purchase Report',
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
          (purchaseItemAnalysisList.productData.length / rowsPerPage).ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage > purchaseItemAnalysisList.productData.length
            ? purchaseItemAnalysisList.productData.length
            : start + rowsPerPage;
        final tableData = purchaseItemAnalysisList.productData.sublist(
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
                        'Actual',
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
                      pw.Text(
                        'Difference',
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
                        pw.Text(
                          monthlyData.monthsAvg.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          ((monthlyData.salesAmount - monthlyData.monthsAvg) /
                                  100000)
                              .toStringAsFixed(0),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          (monthlyData.monthsAvg != 0
                              ? (((monthlyData.salesAmount /
                                            monthlyData.monthsAvg) *
                                        100)
                                    .ceil()
                                    .toStringAsFixed(0))
                              : "0"),
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
        final file = File('$storageDir/monthly_purchase_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemGroupPurchaseExcel(
    PurchaseItemGroupWiseAnalysisList purchaseItemGroupWiseAnalysisList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Product Group Name', 'Purchase Amount']));
      for (var itemData in purchaseItemGroupWiseAnalysisList.productGroupData) {
        sheet.appendRow(
          toCellRow([
            itemData.groupName,
            itemData.salesAmount.toStringAsFixed(2),
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('itemgroup_purchase_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/itemgroup_purchase_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemGroupPurchasePDF(
    PurchaseItemGroupWiseAnalysisList purchaseItemGroupWiseAnalysisList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Product Group Wise Purchase Report',
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
          (purchaseItemGroupWiseAnalysisList.productGroupData.length /
                  rowsPerPage)
              .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage >
                purchaseItemGroupWiseAnalysisList.productGroupData.length
            ? purchaseItemGroupWiseAnalysisList.productGroupData.length
            : start + rowsPerPage;
        final tableData = purchaseItemGroupWiseAnalysisList.productGroupData
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
                        'Group Name',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Purchase Amount',
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
                          monthlyData.groupName,
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
        final file = File('$storageDir/itemgroup_purchase_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemSubGroupPurchaseExcel(
    PurchaseItemSubGroupWiseAnalysisList purchaseItemSubGroupWiseAnalysisList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Product Sub Group Name', 'Purchase Amount']));
      for (var itemData
          in purchaseItemSubGroupWiseAnalysisList.productSubGroupData) {
        sheet.appendRow(
          toCellRow([
            itemData.itemSubGroup,
            itemData.salesAmount.toStringAsFixed(2),
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('itemsubgroup_purchase_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/itemsubgroup_purchase_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateItemSubGroupPurchasePDF(
    PurchaseItemSubGroupWiseAnalysisList purchaseItemSubGroupWiseAnalysisList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Product Sub Group Wise Purchase Report',
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
          (purchaseItemSubGroupWiseAnalysisList.productSubGroupData.length /
                  rowsPerPage)
              .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage >
                purchaseItemSubGroupWiseAnalysisList.productSubGroupData.length
            ? purchaseItemSubGroupWiseAnalysisList.productSubGroupData.length
            : start + rowsPerPage;
        final tableData = purchaseItemSubGroupWiseAnalysisList
            .productSubGroupData
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
                        'Purchase Amount',
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
                          monthlyData.itemSubGroup,
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
        final file = File('$storageDir/itemsubgroup_purchase_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateBranchPurchaseExcel(
    PurchaseBranchAnalysisList purchaseBranchAnalysisList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'Branch Name',
          'Actual',
          'Monthly Avg.',
          'Difference',
          'Percentage',
        ]),
      );
      for (var itemData in purchaseBranchAnalysisList.branchData) {
        sheet.appendRow(
          toCellRow([
            itemData.branchName,
            itemData.rowTotal.toStringAsFixed(2),
            itemData.monthAvg.toStringAsFixed(2),
            ((itemData.rowTotal - itemData.monthAvg) / 100000).toStringAsFixed(
              0,
            ),
            itemData.monthAvg != 0
                ? ((itemData.rowTotal / itemData.monthAvg) * 100)
                      .ceil()
                      .toStringAsFixed(0)
                : 0,
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('branch_purchase_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/branch_purchase_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateBranchPurchasePDF(
    PurchaseBranchAnalysisList purchaseBranchAnalysisList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Branch Wise Purchase Report',
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
          (purchaseBranchAnalysisList.branchData.length / rowsPerPage).ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage > purchaseBranchAnalysisList.branchData.length
            ? purchaseBranchAnalysisList.branchData.length
            : start + rowsPerPage;
        final tableData = purchaseBranchAnalysisList.branchData.sublist(
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
                        'Actual',
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
                      pw.Text(
                        'Difference',
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
                          monthlyData.branchName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.rowTotal.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.monthAvg.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          ((monthlyData.rowTotal - monthlyData.monthAvg) /
                                  100000)
                              .toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          (monthlyData.monthAvg != 0
                              ? (((monthlyData.rowTotal /
                                            monthlyData.monthAvg) *
                                        100)
                                    .ceil()
                                    .toStringAsFixed(0))
                              : "0"),
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
        final file = File('$storageDir/branch_purchase_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateWarehousePurchaseExcel(
    PurchaseWarehouseAnalysisList purchaseWarehouseAnalysisList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'Warehouse Name',
          'Actual',
          'Monthly Avg.',
          'Difference',
          'Percentage',
        ]),
      );
      for (var itemData in purchaseWarehouseAnalysisList.warehouseData) {
        sheet.appendRow(
          toCellRow([
            itemData.warehouseName,
            itemData.rowTotal.toStringAsFixed(2),
            itemData.monthAvg.toStringAsFixed(2),
            ((itemData.rowTotal - itemData.monthAvg) / 100000).toStringAsFixed(
              2,
            ),
            itemData.monthAvg != 0
                ? ((itemData.rowTotal / itemData.monthAvg) * 100)
                      .ceil()
                      .toStringAsFixed(0)
                : 0,
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('Warehouse_purchase_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/Warehouse_purchase_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateWarehousePurchasePDF(
    PurchaseWarehouseAnalysisList purchaseWarehouseAnalysisList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Warehouse Wise Purchase Report',
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
          (purchaseWarehouseAnalysisList.warehouseData.length / rowsPerPage)
              .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage >
                purchaseWarehouseAnalysisList.warehouseData.length
            ? purchaseWarehouseAnalysisList.warehouseData.length
            : start + rowsPerPage;
        final tableData = purchaseWarehouseAnalysisList.warehouseData.sublist(
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
                      pw.Text(
                        'Monthly Avg.',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Difference',
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
                          monthlyData.warehouseName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.rowTotal.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.monthAvg.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          ((monthlyData.rowTotal - monthlyData.monthAvg) /
                                  100000)
                              .toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          (monthlyData.monthAvg != 0
                              ? (((monthlyData.rowTotal /
                                            monthlyData.monthAvg) *
                                        100)
                                    .ceil()
                                    .toStringAsFixed(0))
                              : "0"),
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
        final file = File('$storageDir/warehouse_purchase_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierPurchaseExcel(
    PurchaseSupplierAnalysisList purchaseSupplierAnalysisList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'Supplier Name',
          'Actual',
          'Monthly Avg.',
          'Difference',
          'Percentage',
        ]),
      );
      for (var itemData in purchaseSupplierAnalysisList.supplierData) {
        sheet.appendRow(
          toCellRow([
            itemData.supplierName,
            itemData.rowTotal.toStringAsFixed(2),
            itemData.monthAvg.toStringAsFixed(2),
            ((itemData.rowTotal - itemData.monthAvg) / 100000).toStringAsFixed(
              2,
            ),
            itemData.monthAvg != 0
                ? ((itemData.rowTotal / itemData.monthAvg) * 100)
                      .ceil()
                      .toStringAsFixed(0)
                : 0,
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('Supplier_purchase_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/Supplier_purchase_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierPurchasePDF(
    PurchaseSupplierAnalysisList purchaseSupplierAnalysisList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Supplier Wise Purchase Report',
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
          (purchaseSupplierAnalysisList.supplierData.length / rowsPerPage)
              .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage >
                purchaseSupplierAnalysisList.supplierData.length
            ? purchaseSupplierAnalysisList.supplierData.length
            : start + rowsPerPage;
        final tableData = purchaseSupplierAnalysisList.supplierData.sublist(
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
                      pw.Text(
                        'Monthly Avg.',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Difference',
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
                          monthlyData.supplierName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.rowTotal.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.monthAvg.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          ((monthlyData.rowTotal - monthlyData.monthAvg) /
                                  100000)
                              .toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          (monthlyData.monthAvg != 0
                              ? (((monthlyData.rowTotal /
                                            monthlyData.monthAvg) *
                                        100)
                                    .ceil()
                                    .toStringAsFixed(0))
                              : "0"),
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
        final file = File('$storageDir/supplier_purchase_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierStatePurchaseExcel(
    PurchaseSupplierStateWiseAnalysisList purchaseSupplierStateWiseAnalysisList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'State Name',
          'Actual',
          'Monthly Avg.',
          'Difference',
          'Percentage',
        ]),
      );
      for (var itemData
          in purchaseSupplierStateWiseAnalysisList.supplierStateData) {
        sheet.appendRow(
          toCellRow([
            itemData.vendorState,
            itemData.rowTotal.toStringAsFixed(2),
            itemData.monthAvg.toStringAsFixed(2),
            ((itemData.rowTotal - itemData.monthAvg) / 100000).toStringAsFixed(
              2,
            ),
            itemData.monthAvg != 0
                ? ((itemData.rowTotal / itemData.monthAvg) * 100)
                      .ceil()
                      .toStringAsFixed(0)
                : 0,
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('SupplierState_purchase_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/SupplierState_purchase_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierStatePurchasePDF(
    PurchaseSupplierStateWiseAnalysisList purchaseSupplierStateWiseAnalysisList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Supplier State Wise Purchase Report',
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
          (purchaseSupplierStateWiseAnalysisList.supplierStateData.length /
                  rowsPerPage)
              .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage >
                purchaseSupplierStateWiseAnalysisList.supplierStateData.length
            ? purchaseSupplierStateWiseAnalysisList.supplierStateData.length
            : start + rowsPerPage;
        final tableData = purchaseSupplierStateWiseAnalysisList
            .supplierStateData
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
                      pw.Text(
                        'Monthly Avg.',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Difference',
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
                          monthlyData.vendorState,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.rowTotal.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.monthAvg.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          ((monthlyData.rowTotal - monthlyData.monthAvg) /
                                  100000)
                              .toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          (monthlyData.monthAvg != 0
                              ? (((monthlyData.rowTotal /
                                            monthlyData.monthAvg) *
                                        100)
                                    .ceil()
                                    .toStringAsFixed(0))
                              : "0"),
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
        final file = File('$storageDir/supplierstate_purchase_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierCityPurchaseExcel(
    PurchaseSupplierCityWiseAnalysisList purchaseSupplierCityWiseAnalysisList,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'State Name',
          'Actual',
          'Monthly Avg.',
          'Difference',
          'Percentage',
        ]),
      );
      for (var itemData
          in purchaseSupplierCityWiseAnalysisList.supplierCityData) {
        sheet.appendRow(
          toCellRow([
            itemData.vendorCity,
            itemData.rowTotal.toStringAsFixed(2),
            itemData.monthAvg.toStringAsFixed(2),
            ((itemData.rowTotal - itemData.monthAvg) / 100000).toStringAsFixed(
              2,
            ),
            itemData.monthAvg != 0
                ? ((itemData.rowTotal / itemData.monthAvg) * 100)
                      .ceil()
                      .toStringAsFixed(0)
                : 0,
          ]),
        );
      }
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('Supplier_city_purchase_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/Supplier_city_purchase_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSupplierCityPurchasePDF(
    PurchaseSupplierCityWiseAnalysisList purchaseSupplierCityWiseAnalysisList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Supplier City Wise Purchase Report',
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
          (purchaseSupplierCityWiseAnalysisList.supplierCityData.length /
                  rowsPerPage)
              .ceil();

      for (int page = 0; page < totalPages; page++) {
        final start = page * rowsPerPage;
        final end =
            start + rowsPerPage >
                purchaseSupplierCityWiseAnalysisList.supplierCityData.length
            ? purchaseSupplierCityWiseAnalysisList.supplierCityData.length
            : start + rowsPerPage;
        final tableData = purchaseSupplierCityWiseAnalysisList.supplierCityData
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
                      pw.Text(
                        'Monthly Avg.',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Difference',
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
                          monthlyData.vendorCity,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.rowTotal.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          monthlyData.monthAvg.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          ((monthlyData.rowTotal - monthlyData.monthAvg) /
                                  100000)
                              .toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                        pw.Text(
                          (monthlyData.monthAvg != 0
                              ? (((monthlyData.rowTotal /
                                            monthlyData.monthAvg) *
                                        100)
                                    .ceil()
                                    .toStringAsFixed(0))
                              : "0"),
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
        final file = File('$storageDir/supplier_city_purchase_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  String formatDateString(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  Future<void> _dateFilterTarget(
      String UserName, String UserLevel, bool FromFilter) async {
    setState(() {
      List<String> menuNames = usersList
          .where((element) => element.parentMenuId == 0)
          .map((user) => user.menuName)
          .toList();
      menuNames.insert(0, UserName);
      context
          .read<PurchaseProcurementAnalysisProvider>()
          .updatePurchaseList(purchase);

      purchase = purchase.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
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
    final userName =
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    UserLevel = userLevel;
    setState(() async {
      await _loadPurchase(userName, userLevel);
      await _dateFilterTarget(userName, userLevel, true);
      await _loadEachQtrValues();
      await _loadMonthWisePurchaseAnalysis();
      await _loadItemAnalysis(0, "", "", "", "", "", "", "", "", "");
      await _loadItemGroupWiseAnalysis(0, "", "", "", "", "", "", "", "", "");
      await _loadItemSubGroupWiseAnalysis(0, "", "", "", "", "", "", "", "", "");
      await _loadBranchAnalysis(0, "", "", "", "", "", "", "", "", "");
      await _loadWarehouseAnalysis(0, "", "", "", "", "", "", "", "", "");
      await _loadSupplierAnalysis(0, "", "", "", "", "", "", "", "", "");
      await _loadSupplierStateAnalysis(0, "", "", "", "", "", "", "", "", "");
      await _loadSupplierCityAnalysis(0, "", "", "", "", "", "", "", "", "");
      await _loadSupplierCategoryAnalysis(0, "", "", "", "", "", "", "", "", "");

      chartDataLoaded = true;

      setState(() {
        filterOptions = [
          listOfRSM,
          listOfASM,
          listOfTSM,
          []
        ];

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

  void resetFinanceReceivablesOptions() {
    setState(() {
      savedFinanceReceivablesOptions =
          List.from(selectedFinanceReceivablesOptions);
    });
  }

  @override
  void initState() {
    super.initState();
    LoadDates();
    LoadAllQuarterFromToDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
      toDateFilter = currentDate;
      fromDateFilter = fiscalYearStartDate;
    }

    filterOptions = [
      [],
    ];

    selectedFinanceReceivablesOptions = filterOptions
        .map((options) => List<bool>.filled(options.length, false))
        .toList();

    selectedFinanceReceivablesOptions = savedFinanceReceivablesOptions;
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
                            showFilterBottomSheet(context);
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
                          "Monthly Analysis",
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
                                    generatePurchaseExcel(monthData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generatePurchasePDF(monthData);
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
                                "${getMonthName(currentDate!.month)} Goal - $SalesGoalStr",
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
                                            "${getMonthName(currentDate!.month - 1)} Purchase \n($LastMonthTargetStr)",
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
                                          "Q$currentQuarter Purchase \n($CurrentQtrTargetStr)",
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
                          "Month Wise Purchase Analysis",
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
                                    generatePurchaseExcel(monthData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generatePurchasePDF(monthData);
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
                  child: _monthWisePurchaseAnalysis(),
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
                                    generateItemPurchaseExcel(itemData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateItemPurchasePDF(itemData);
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
                                    generateItemGroupPurchaseExcel(
                                      itemGroupData,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateItemGroupPurchasePDF(itemGroupData);
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
                                    generateItemSubGroupPurchaseExcel(
                                      itemSubGroupData,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateItemSubGroupPurchasePDF(
                                      itemSubGroupData,
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
                          "Branch Analysis",
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
                                    generateBranchPurchaseExcel(branchData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateBranchPurchasePDF(branchData);
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
                          "Warehouse Wise\nAnalysis",
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
                                    generateWarehousePurchaseExcel(
                                      warehouseData,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateWarehousePurchasePDF(warehouseData);
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
                                    generateSupplierPurchaseExcel(supplierList);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateSupplierPurchasePDF(supplierList);
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
                          "Supplier State\nWise Analysis",
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
                                    generateSupplierStatePurchaseExcel(
                                      supplierStateList,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateSupplierStatePurchasePDF(
                                      supplierStateList,
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
                          "Supplier City\nWise Analysis",
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
                                    generateSupplierCityPurchaseExcel(
                                      supplierCityList,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateSupplierCityPurchasePDF(
                                      supplierCityList,
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
                  child: _supplierCityWiseAnalysis(),
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
                          "Supplier Category Wise Analysis",
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
                                  setState(() {});
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {});
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
                                  (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection ==
                                              null) {
                                        _touchedIndex = -1;
                                        return;
                                      }
                                      _touchedIndex = pieTouchResponse
                                          .touchedSection!
                                          .touchedSectionIndex;
                                    });
                                  },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 1,
                            centerSpaceRadius: 0,
                            startDegreeOffset: 180,
                            sections: showingSectionsSupplierCategory(),
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
                                for (final categoryData
                                    in supplierCategoryList
                                        .supplierCategoryData)
                                  Column(
                                    children: [
                                      Container(
                                        height: 8,
                                        width: 16,
                                        color: getCategoryColor(
                                          categoryData.supplierCategory,
                                        ),
                                        // color: getCategoryColor(categoryData.categoryId),
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final categoryData
                                  in supplierCategoryList.supplierCategoryData)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    categoryData.supplierCategory,
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(fontSize: 10),
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

  Widget _monthWisePurchaseAnalysis() {
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
            barGroups: _monthWisePurchaseAnalysisChartData(
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
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedBranchName,
                        touchedWarehouse,
                        touchedSupplierCode,
                        touchedSupplierState,
                        touchedSupplierCity,
                        touchedSupplierCategory,
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
                    "${monthData.monthlyData[grpIndex].monthName} ${DateTime.now().year}\n",
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "${(monthData.monthlyData[grpIndex].collectionAmount / 100000).toStringAsFixed(2)} L\n",
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
    double chartWidth = 0.0;
    int len = itemData.productData.length;
    if (itemData.productData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    double maxPurchaseAmount = len > 0
        ? itemData.productData
              .map(
                (data) => data.salesAmount > data.monthsAvg
                    ? data.salesAmount
                    : data.monthsAvg,
              ) // Compare salesAmount and monthsAvg
              .reduce((a, b) => a > b ? a : b) // Find the max value
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
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedBranchName,
                        touchedWarehouse,
                        touchedSupplierCode,
                        touchedSupplierState,
                        touchedSupplierCity,
                        touchedSupplierCategory,
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
                            "\nActual : ${formatAmount(itemData.productData[grpIndex].salesAmount)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nMonthly Avg. : ${formatAmount(itemData.productData[grpIndex].monthsAvg)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nDifference : ${formatAmount((itemData.productData[grpIndex].salesAmount - itemData.productData[grpIndex].monthsAvg) / 100000)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nPercentage : ${(itemData.productData[grpIndex].monthsAvg != 0 ? ((itemData.productData[grpIndex].salesAmount / itemData.productData[grpIndex].monthsAvg) * 100).ceil().toStringAsFixed(0) : "N/A" // Or use "0" or any default value you'd like
                                  )}",
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
    int len = itemGroupData.productGroupData.length;
    if (itemGroupData.productGroupData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxPurchaseAmount = len > 0
        ? itemGroupData.productGroupData
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
              itemGroupData.productGroupData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedItemGroup = touchedItemGroup == ""
                          ? itemGroupData
                                .productGroupData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .groupName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedBranchName,
                        touchedWarehouse,
                        touchedSupplierCode,
                        touchedSupplierState,
                        touchedSupplierCity,
                        touchedSupplierCategory,
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
                    itemGroupData.productGroupData[grpIndex].groupName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\n${formatAmount(itemGroupData.productGroupData[grpIndex].salesAmount)}",
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
    int len = itemSubGroupData.productSubGroupData.length;
    if (itemSubGroupData.productSubGroupData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxPurchaseAmount = len > 0
        ? itemSubGroupData.productSubGroupData
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
              itemSubGroupData.productSubGroupData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedItemSubGroup = touchedItemSubGroup == ""
                          ? itemSubGroupData
                                .productSubGroupData[barTouchResponse
                                    .spot!
                                    .spot
                                    .x
                                    .toInt()]
                                .itemSubGroup
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedBranchName,
                        touchedWarehouse,
                        touchedSupplierCode,
                        touchedSupplierState,
                        touchedSupplierCity,
                        touchedSupplierCategory,
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
                    itemSubGroupData.productSubGroupData[grpIndex].itemSubGroup,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\n${formatAmount(itemSubGroupData.productSubGroupData[grpIndex].salesAmount)}",
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
              .map(
                (data) => data.rowTotal > data.monthAvg
                    ? data.rowTotal
                    : data.monthAvg,
              ) // Compare salesAmount and monthsAvg
              .reduce((a, b) => a > b ? a : b) // Find the max value
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
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedBranchName,
                        touchedWarehouse,
                        touchedSupplierCode,
                        touchedSupplierState,
                        touchedSupplierCity,
                        touchedSupplierCategory,
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
                            "\nActual : ${formatAmount(branchData.branchData[grpIndex].rowTotal)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nMonthly Avg. : ${formatAmount(branchData.branchData[grpIndex].monthAvg)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nDifference : ${formatAmount((branchData.branchData[grpIndex].rowTotal - branchData.branchData[grpIndex].monthAvg) / 100000)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nPercentage : ${((branchData.branchData[grpIndex].rowTotal / branchData.branchData[grpIndex].monthAvg) * 100).ceil().toStringAsFixed(0)}",
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
              .map(
                (data) => data.rowTotal > data.monthAvg
                    ? data.rowTotal
                    : data.monthAvg,
              ) // Compare salesAmount and monthsAvg
              .reduce((a, b) => a > b ? a : b) // Find the max value
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
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedBranchName,
                        touchedWarehouse,
                        touchedSupplierCode,
                        touchedSupplierState,
                        touchedSupplierCity,
                        touchedSupplierCategory,
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
                    '${warehouseData.warehouseData[grpIndex].warehouseName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\nActual : ${formatAmount(warehouseData.warehouseData[grpIndex].rowTotal)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nMonthly Avg. : ${formatAmount(warehouseData.warehouseData[grpIndex].monthAvg)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nDifference : ${formatAmount((warehouseData.warehouseData[grpIndex].rowTotal - warehouseData.warehouseData[grpIndex].monthAvg) / 100000)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nPercentage : ${((warehouseData.warehouseData[grpIndex].rowTotal / warehouseData.warehouseData[grpIndex].monthAvg) * 100).ceil().toStringAsFixed(0)}",
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
    int len = supplierList.supplierData.length;
    if (supplierList.supplierData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    double maxPurchaseAmount = len > 0
        ? supplierList.supplierData
              .map(
                (data) => data.rowTotal > data.monthAvg
                    ? data.rowTotal
                    : data.monthAvg,
              ) // Compare salesAmount and monthsAvg
              .reduce((a, b) => a > b ? a : b) // Find the max value
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
            barGroups: _supplierAnalysisChartData(supplierList.supplierData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedSupplierCode = touchedSupplierCode == ""
                          ? supplierList
                                .supplierData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .supplierName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedBranchName,
                        touchedWarehouse,
                        touchedSupplierCode,
                        touchedSupplierState,
                        touchedSupplierCity,
                        touchedSupplierCategory,
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
                    supplierList.supplierData[grpIndex].supplierName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\nActual : ${formatAmount(supplierList.supplierData[grpIndex].rowTotal)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nMonthly Avg. : ${formatAmount(supplierList.supplierData[grpIndex].monthAvg)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nDifference : ${formatAmount((supplierList.supplierData[grpIndex].rowTotal - supplierList.supplierData[grpIndex].monthAvg) / 100000)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nPercentage : ${((supplierList.supplierData[grpIndex].rowTotal / supplierList.supplierData[grpIndex].monthAvg) * 100).ceil().toStringAsFixed(0)}",
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
    int len = supplierStateList.supplierStateData.length;
    if (supplierStateList.supplierStateData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    double maxPurchaseAmount = len > 0
        ? supplierStateList.supplierStateData
              .map(
                (data) => data.rowTotal > data.monthAvg
                    ? data.rowTotal
                    : data.monthAvg,
              ) // Compare salesAmount and monthsAvg
              .reduce((a, b) => a > b ? a : b) // Find the max value
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
              supplierStateList.supplierStateData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedSupplierState = touchedSupplierState == ""
                          ? supplierStateList
                                .supplierStateData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .vendorState
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedBranchName,
                        touchedWarehouse,
                        touchedSupplierCode,
                        touchedSupplierState,
                        touchedSupplierCity,
                        touchedSupplierCategory,
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
                    supplierStateList.supplierStateData[grpIndex].vendorState,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Actual : ${formatAmount(supplierStateList.supplierStateData[grpIndex].rowTotal)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nMonthly Avg. : ${formatAmount(supplierStateList.supplierStateData[grpIndex].monthAvg)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nDifference : ${formatAmount((supplierStateList.supplierStateData[grpIndex].rowTotal - supplierStateList.supplierStateData[grpIndex].monthAvg) / 100000)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nPercentage : ${((supplierStateList.supplierStateData[grpIndex].rowTotal / supplierStateList.supplierStateData[grpIndex].monthAvg) * 100).ceil().toStringAsFixed(0)}",
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
    int len = supplierCityList.supplierCityData.length;
    if (supplierCityList.supplierCityData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    double maxPurchaseAmount = len > 0
        ? supplierCityList.supplierCityData
              .map(
                (data) => data.rowTotal > data.monthAvg
                    ? data.rowTotal
                    : data.monthAvg,
              ) // Compare salesAmount and monthsAvg
              .reduce((a, b) => a > b ? a : b) // Find the max value
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
              supplierCityList.supplierCityData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedSupplierCity = touchedSupplierCity == ""
                          ? supplierCityList
                                .supplierCityData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .vendorCity
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedBranchName,
                        touchedWarehouse,
                        touchedSupplierCode,
                        touchedSupplierState,
                        touchedSupplierCity,
                        touchedSupplierCategory,
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
                    supplierCityList.supplierCityData[grpIndex].vendorCity,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\nActual : ${formatAmount(supplierCityList.supplierCityData[grpIndex].rowTotal)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nMonthly Avg. : ${formatAmount(supplierCityList.supplierCityData[grpIndex].monthAvg)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nDifference : ${formatAmount((supplierCityList.supplierCityData[grpIndex].rowTotal - supplierCityList.supplierCityData[grpIndex].monthAvg) / 100000)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nPercentage : ${((supplierCityList.supplierCityData[grpIndex].rowTotal / supplierCityList.supplierCityData[grpIndex].monthAvg) * 100).ceil().toStringAsFixed(0)}",
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
                            fontSize: 18, fontWeight: FontWeight.bold),
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
                                child: selectedCategoryIndex ==
                                    categories.length - 1 // "Date" index
                                    ? Column(
                                  children: [
                                    ListTile(
                                      title: const Text("From Date"),
                                      subtitle: Text(fromDateFilter !=
                                          null
                                          ? "${fromDateFilter!.day}/${fromDateFilter!.month}/${fromDateFilter!.year}"
                                          : formatDateString(
                                          fiscalYearStartDate!)),
                                      trailing: const Icon(
                                          Icons.calendar_today),
                                      onTap: () async {
                                        final picked =
                                        await showDatePicker(
                                          context: context,
                                          initialDate: fromDateFilter ??
                                              DateTime.now(),
                                          firstDate: fiscalYearStartDate!,
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
                                      subtitle: Text(toDateFilter != null
                                          ? "${toDateFilter!.day}/${toDateFilter!.month}/${toDateFilter!.year}"
                                          : formatDateString(
                                          currentDate!)),
                                      trailing: const Icon(
                                          Icons.calendar_today),
                                      onTap: () async {
                                        final picked =
                                        await showDatePicker(
                                          context: context,
                                          initialDate: toDateFilter ??
                                              DateTime.now(),
                                          firstDate: fiscalYearStartDate!,
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
                                      title: Text(filterOptions[
                                      selectedCategoryIndex][index]),
                                      value:
                                      savedFinanceReceivablesOptions[
                                      selectedCategoryIndex]
                                      [index],
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            selectedFinanceReceivablesOptions[
                                            selectedCategoryIndex]
                                            [index] = true;
                                          } else {
                                            selectedFinanceReceivablesOptions[
                                            selectedCategoryIndex]
                                            [index] = false;
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
                                      for (int i = 0;
                                      i <
                                          filterOptions[
                                          selectedCategoryIndex]
                                              .length;
                                      i++) {
                                        if (selectedFinanceReceivablesOptions[
                                        selectedCategoryIndex][i]) {
                                          selectedFilterOptions.add(
                                              filterOptions[
                                              selectedCategoryIndex][i]);
                                        }
                                      }
                                      for (int catIndex = 0;
                                      catIndex < categories.length;
                                      catIndex++) {
                                        String categoryName =
                                        categories[catIndex];
                                        Map<String, bool> optionsState = {};

                                        // Ensure the lengths match for your filterOptions and selectedFinanceReceivablesOptions lists
                                        for (int optionIndex = 0;
                                        optionIndex <
                                            filterOptions[catIndex].length;
                                        optionIndex++) {
                                          optionsState[filterOptions[catIndex]
                                          [optionIndex]] =
                                          selectedFinanceReceivablesOptions[
                                          catIndex][optionIndex];
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
                                  const SizedBox(
                                    width: 15,
                                  ),
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
                                        style:
                                        TextStyle(color: Color(0xff2ca9df)),
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
