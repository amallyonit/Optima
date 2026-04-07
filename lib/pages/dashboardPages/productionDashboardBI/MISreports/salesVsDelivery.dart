// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:open_file/open_file.dart';
import 'package:optima/excel_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:excel/excel.dart' as xl;

import 'package:optima/pages/dashboardPages/excel_helper_web.dart';

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

bool chartDataLoaded = false;

List<InventoryLevelList> stockData = [];
List<SalesVsProductionMIS> deliveryData = [];
List<SalesVsProductionMIS> deliveryDataTemp = [];
List<InventoryLevelList> stockDataTemp = [];

StockItemList stockStatementData = StockItemList(stockData: []);

double completedOrders = 0;
double completedOrdersPercent = 0;
double completedOrdersPercentage = 0;
double pendingOrders = 0;
double pendingOrdersPercent = 0;
double pendingOrdersPercentage = 0;

SalesVsProductionPieChartList receivablesCategoryList =
    SalesVsProductionPieChartList(categoryData: []);
MonthlySalesVsProductionList monthlyData = MonthlySalesVsProductionList(
  monthlyData: [],
);

String selectedBranch = "";

class SalesVsDeliveryDetailsMISProvider with ChangeNotifier {
  List<SalesVsProductionMIS> _salesList = [];
  List<SalesVsProductionMIS> get salesList => _salesList;
  void updateInventoryLevelList(List<SalesVsProductionMIS> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class SalesVsDeliveryPage extends StatefulWidget {
  const SalesVsDeliveryPage({super.key});

  @override
  State<SalesVsDeliveryPage> createState() => _SalesVsDeliveryPageState();
}

class _SalesVsDeliveryPageState extends State<SalesVsDeliveryPage> {
  DateTime? selectedDate = DateTime.now();

  void LoadAllQuarterFromToDates() {
    DateTime now = DateTime.now();

    int financialYearStart = (now.month >= 4) ? now.year : now.year - 1;

    q1FromDate = DateTime(financialYearStart, 4, 1);
    q1ToDate = DateTime(financialYearStart, 7, 0);

    q2FromDate = DateTime(financialYearStart, 7, 1);
    q2ToDate = DateTime(financialYearStart, 10, 0);

    q3FromDate = DateTime(financialYearStart, 10, 1);
    q3ToDate = DateTime(financialYearStart + 1, 1, 0); // December 31

    q4FromDate = DateTime(financialYearStart + 1, 1, 1);
    q4ToDate = DateTime(financialYearStart + 1, 4, 0); // March 31
  }

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
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

  SideTitles get _bottomTitlesMonthlyInventory => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<MonthlySalesVsProductionData> mData = monthlyData.monthlyData;
      text = mData.elementAt(value.toInt()).monthName;
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

  List<BarChartGroupData> _MonthlyChartData(
    List<MonthlySalesVsProductionData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.noOfOrders,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  Map<String, DateTime> getMonthStartEndDates(int month) {
    DateTime now = DateTime.now();

    int currentYear = now.year;

    int yearForMonth;
    if (now.month >= 1 && now.month <= 3) {
      yearForMonth = (month >= 4 && month <= 12)
          ? currentYear - 1
          : currentYear;
    } else {
      yearForMonth = (month >= 4 && month <= 12)
          ? currentYear
          : currentYear + 1;
    }

    DateTime firstDayOfMonth = DateTime(yearForMonth, month, 1);
    DateTime lastDayOfMonth = DateTime(yearForMonth, month + 1, 0);

    return {'start': firstDayOfMonth, 'end': lastDayOfMonth};
  }

  Future<void> _loadDeliveryDetails(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<SalesVsProductionMIS> salesList = [];
    try {
      do {
        var body = {
          "FromDate": formatDate(fiscalYearStartDate!),
          "ToDate": formatDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}BicxoDeliveryReportList';
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
            List<SalesVsProductionMIS> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => SalesVsProductionMIS.fromJson(item))
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
        context
            .read<SalesVsDeliveryDetailsMISProvider>()
            .updateInventoryLevelList(salesList);

        deliveryData = salesList.toList();
        deliveryDataTemp = salesList.toList();
        deliveryData = deliveryData
            .where((test) => test.branchName == "Karnataka State")
            .toList();
      });
      // var currentMonthSales = inventory.where((target) {
      //   DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
      //
      //   return invoiceDate.isAtLeast(currentMonthFromDate!) &&
      //       invoiceDate.isAtMost(currentDate!);
      // });

      // double salesAmt = 0;
      // for (var target in currentMonthSales.toList()) {
      //   if (target.invoiceType != "Sales Return") {
      //     salesAmt = double.tryParse(target.rowTotal) ?? 0;
      //   } else {
      //     salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
      //   }
      //   sum += salesAmt;
      // }

      // CurrentMonthSales = sum;
      // CurrentMonthSalesStr =
      // "${(CurrentMonthSales / 100000).toStringAsFixed(2)} L";
      // if (CurrentMonthSales == 0) {
      //   CurrentMonthSalesPercentage = 0;
      // } else {
      //   CurrentMonthSalesPercentage = double.tryParse(
      //       ((CurrentMonthSales / SalesGoal) * 100).toStringAsFixed(0))
      //       ?.ceil() ??
      //       0;
      // }
      // CurrentMonthSalesPercentageStr =
      // "${CurrentMonthSalesPercentage.toString()} %";
      //
      // if (CurrentMonthSalesPercentage > 100) {
      //   CurrentMonthSalesPercentage = 100;
      // }

      // var lastMonthSales = sales.where((target) {
      //   DateTime invoiceDate =
      //   DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
      //
      //   return invoiceDate.isAtLeast(lastMonthFromDate!) &&
      //       invoiceDate.isAtMost(lastMonthToDate!);
      // });

      // sum = 0;
      // salesAmt = 0;
      // for (var target in lastMonthSales.toList()) {
      //   if (target.invoiceType != "Sales Return") {
      //     salesAmt = double.tryParse(target.rowTotal) ?? 0;
      //   } else {
      //     salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
      //   }
      //   sum += salesAmt;
      // }

      // LastMonthSales = sum;
      // LastMonthSalesStr = "${(LastMonthSales / 100000).toStringAsFixed(2)} L";
      // if (LastMonthSales == 0) {
      //   LastMonthPercentage = 0;
      // } else {
      //   LastMonthPercentage = double.tryParse(
      //       ((LastMonthSales / LastMonthTarget) * 100)
      //           .toStringAsFixed(2))
      //       ?.ceil() ??
      //       0;
      // }
      // LastMonthPercentageStr = "${LastMonthPercentage.toString()} %";
      // if (LastMonthPercentage > 100) {
      //   LastMonthPercentage = 100;
      // }
      //
      // var curQtrSales = sales.where((target) {
      //   DateTime invoiceDate =
      //   DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
      //   return invoiceDate.isAtLeast(currentQuarterFromDate!) &&
      //       invoiceDate.isAtMost(currentQuarterToDate!);
      // });

      // sum = 0;
      // salesAmt = 0;
      // for (var target in curQtrSales.toList()) {
      //   if (target.invoiceType != "Sales Return") {
      //     salesAmt = double.tryParse(target.rowTotal) ?? 0;
      //   } else {
      //     salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
      //   }
      //   sum += salesAmt;
      // }

      // CurrentQtrSales = sum;
      // CurrentQtrSalesStr = "${(CurrentQtrSales / 100000).toStringAsFixed(2)} L";
      // if (CurrentQtrSales == 0) {
      //   CurrentQtrPercentage = 0;
      // } else {
      //   CurrentQtrPercentage = double.tryParse(
      //       ((CurrentQtrSales / CurrentQtrTarget) * 100)
      //           .toStringAsFixed(2))
      //       ?.ceil() ??
      //       0;
      // }
      // CurrentQtrPercentageStr = "${CurrentQtrPercentage.toString()} %";
      // if (CurrentQtrPercentage > 100) {
      //   CurrentQtrPercentage = 100;
      // }
      //
      // var ytdSales = sales.where((target) {
      //   DateTime invoiceDate =
      //   DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
      //   return invoiceDate.isAtLeast(fiscalYearStartDate!) &&
      //       invoiceDate.isAtMost(currentDate!);
      // });
      //
      // sum = 0;
      // salesAmt = 0;
      // for (var target in ytdSales.toList()) {
      //   if (target.invoiceType != "Sales Return") {
      //     salesAmt = double.tryParse(target.rowTotal) ?? 0;
      //   } else {
      //     salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
      //   }
      //   sum += salesAmt;
      // }
      //
      // YtdSales = sum;
      // YtdSalesStr = "${(YtdSales / 100000).toStringAsFixed(2)} L";
      // if (YtdSales == 0) {
      //   YtdPercentage = 0;
      // } else {
      //   YtdPercentage =
      //       double.tryParse(((YtdSales / YtdTarget) * 100).toStringAsFixed(2))
      //           ?.ceil() ??
      //           0;
      // }
      // YtdPercentageStr = "${YtdPercentage.toString()} %";
      //
      // if (YtdPercentage > 100) {
      //   YtdPercentage = 100;
      // }zs
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Error: $e'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  // Future<void> _loadSalesVsProduction() async {
  //   var inventoryList = deliveryData;
  //   List<SalesVsProductionMIS> customerTargetList = [];
  //
  //   Map<String, DateTime> monthDates = getMonthStartEndDates(selectedDate!.month);
  //
  //   customerTargetList = inventoryList.where((target) {
  //     DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.soDate);
  //     return dueon.isAtLeast(monthDates["start"]!) && dueon.isAtMost(monthDates['end']!);
  //   }).toList();
  //
  //   final int closedCount = customerTargetList
  //       .where((t) => (t.soStatus ?? '').toLowerCase() == 'close')
  //       .length;
  //
  //   final int notClosedCount = customerTargetList.length - closedCount;
  //   final int totalCount = customerTargetList.length;
  //
  //   completedOrders = closedCount.toDouble();
  //   pendingOrders = notClosedCount.toDouble();
  //
  //   completedOrdersPercent = completedOrders == 0 ? 0.0 : (pendingOrders * 100.0) / completedOrders;
  //
  //   completedOrdersPercentage = totalCount == 0 ? 0.0 : (closedCount * 100.0) / totalCount;
  //   pendingOrdersPercentage = totalCount == 0 ? 0.0 : (notClosedCount * 100.0) / totalCount;
  //   // [Delayed, On Time]
  // }

  // Future<void> _loadSalesVsProduction() async {
  //   var inventoryList = deliveryData;
  //   List<SalesVsProductionMIS> customerTargetList = [];
  //
  //   Map<String, DateTime> monthDates = getMonthStartEndDates(selectedDate!.month);
  //
  //   customerTargetList = inventoryList.where((target) {
  //     DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.soDate);
  //     return dueon.isAtLeast(monthDates["start"]!) && dueon.isAtMost(monthDates['end']!);
  //   }).toList();
  //
  //   final int closedCount = customerTargetList
  //       .where((t) => (t.soStatus ?? '').toLowerCase() == 'close')
  //       .length;
  //
  //   final int notClosedCount = customerTargetList.length - closedCount;
  //   final int totalCount = customerTargetList.length;
  //
  //   completedOrders = closedCount.toDouble();
  //   pendingOrders = notClosedCount.toDouble();
  //
  //   completedOrdersPercent = completedOrders == 0 ? 0.0 : (pendingOrders * 100.0) / completedOrders;
  //
  //   completedOrdersPercentage = totalCount == 0 ? 0.0 : (closedCount * 100.0) / totalCount;
  //   pendingOrdersPercentage = totalCount == 0 ? 0.0 : (notClosedCount * 100.0) / totalCount;
  //
  //   final receivablesCategoryListLocal = SalesVsProductionPieChartList(categoryData: [
  //     SalesVsProductionPieChartData(
  //         categoryId: 1, categoryName: 'On Time', noOfOrders: 0.0),
  //     SalesVsProductionPieChartData(
  //         categoryId: 2, categoryName: 'Orders delayed by 1 to 5 Days', noOfOrders: 0.0),
  //     SalesVsProductionPieChartData(
  //         categoryId: 3, categoryName: 'Orders delayed by 6 to 10 Days', noOfOrders: 0.0),
  //     SalesVsProductionPieChartData(
  //         categoryId: 4, categoryName: 'Orders delayed > 10 Days', noOfOrders: 0.0),
  //   ]);
  //
  //   void _inc(int categoryId, double inc) {
  //     final item = receivablesCategoryListLocal.categoryData
  //         .firstWhere((c) => c.categoryId == categoryId, orElse: () => throw Exception('Category $categoryId not found'));
  //     item.noOfOrders += inc;
  //   }
  //
  //   for (var t in customerTargetList) {
  //     final status = (t.status ?? '').toLowerCase().trim();
  //
  //     if (status == 'on time' || status == 'ontime') {
  //       _inc(1, 1.0);
  //     } else if (status == 'delay' || status == 'delayed') {
  //       final leadtimeStr = t.sOtoDDLeadtime ?? '';
  //       final match = RegExp(r'(-?\d+)').firstMatch(leadtimeStr);
  //       final int days = match != null ? (int.tryParse(match.group(0)!) ?? 0) : 0;
  //
  //       if (days >= 1 && days <= 5) {
  //         _inc(2, 1.0);
  //       } else if (days >= 6 && days <= 10) {
  //         _inc(3, 1.0);
  //       } else if (days > 10) {
  //         _inc(4, 1.0);
  //       } else {
  //         _inc(2, 1.0);
  //       }
  //     }
  //   }
  //
  //   if (mounted) {
  //     setState(() {
  //       receivablesCategoryList = receivablesCategoryListLocal;
  //     });
  //   }
  //
  // }

  Future<void> _loadSalesVsProduction() async {
    var inventoryList = deliveryData;
    List<SalesVsProductionMIS> customerTargetList = [];

    Map<String, DateTime> monthDates = getMonthStartEndDates(
      selectedDate!.month,
    );

    customerTargetList = inventoryList.where((target) {
      DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.soDate);
      return dueon.isAtLeast(monthDates["start"]!) &&
          dueon.isAtMost(monthDates['end']!);
    }).toList();

    final int closedCount = customerTargetList
        .where((t) => (t.soStatus).toLowerCase() == 'close')
        .length;

    final int notClosedCount = customerTargetList.length - closedCount;
    final int totalCount = customerTargetList.length;

    completedOrders = closedCount.toDouble();
    pendingOrders = notClosedCount.toDouble();

    completedOrdersPercent = completedOrders == 0
        ? 0.0
        : (pendingOrders * 100.0) / totalCount;

    completedOrdersPercentage = totalCount == 0
        ? 0.0
        : (closedCount * 100.0) / totalCount;
    pendingOrdersPercentage = totalCount == 0
        ? 0.0
        : (notClosedCount * 100.0) / totalCount;

    if (completedOrdersPercentage >= 100) {
      completedOrdersPercentage = 100;
    }
    if (completedOrdersPercent >= 100) {
      completedOrdersPercent = 100;
    }

    final receivablesCategoryListLocal = SalesVsProductionPieChartList(
      categoryData: [
        SalesVsProductionPieChartData(
          categoryId: 1,
          categoryName: 'On Time',
          noOfOrders: 0.0,
        ),
        SalesVsProductionPieChartData(
          categoryId: 2,
          categoryName: 'Orders delayed by 1 to 5 Days',
          noOfOrders: 0.0,
        ),
        SalesVsProductionPieChartData(
          categoryId: 3,
          categoryName: 'Orders delayed by 6 to 10 Days',
          noOfOrders: 0.0,
        ),
        SalesVsProductionPieChartData(
          categoryId: 4,
          categoryName: 'Orders delayed > 10 Days',
          noOfOrders: 0.0,
        ),
      ],
    );

    void incSafe(int categoryId, String categoryName, double inc) {
      final idx = receivablesCategoryListLocal.categoryData.indexWhere(
        (c) => c.categoryId == categoryId,
      );
      if (idx >= 0) {
        receivablesCategoryListLocal.categoryData[idx].noOfOrders += inc;
      } else {
        receivablesCategoryListLocal.categoryData.add(
          SalesVsProductionPieChartData(
            categoryId: categoryId,
            categoryName: categoryName,
            noOfOrders: inc,
          ),
        );
      }
    }

    for (var t in customerTargetList) {
      final rawStatus = (t.status).toString();
      final status = rawStatus.toLowerCase().trim();

      final isOnTime =
          status == 'on time' ||
          status == 'ontime' ||
          (status.contains('on') && status.contains('time'));
      final isDelay =
          status == 'delay' || status == 'delayed' || status.contains('delay');

      if (isOnTime) {
        incSafe(1, 'On Time', 1.0);
        continue;
      }

      if (isDelay) {
        final leadtimeStr = (t.sOtoDDLeadtime).toString();
        final match = RegExp(r'(-?\d+)').firstMatch(leadtimeStr);
        final int days = match != null
            ? (int.tryParse(match.group(0)!) ?? 0)
            : 0;

        if (days >= 1 && days <= 5) {
          incSafe(2, 'Orders delayed by 1 to 5 Days', 1.0);
        } else if (days >= 6 && days <= 10) {
          incSafe(3, 'Orders delayed by 6 to 10 Days', 1.0);
        } else if (days > 10) {
          incSafe(4, 'Orders delayed > 10 Days', 1.0);
        } else {
          incSafe(2, 'Orders delayed by 1 to 5 Days', 1.0);
        }
        continue;
      }
    }

    final double totalOrders = receivablesCategoryListLocal.categoryData.fold(
      0.0,
      (prev, elem) => prev + (elem.noOfOrders),
    );

    if (totalOrders <= 0.0) {
      for (var c in receivablesCategoryListLocal.categoryData) {
        c.noOfOrdersPercentage = 0.0;
      }
    } else {
      for (var c in receivablesCategoryListLocal.categoryData) {
        c.noOfOrdersPercentage = (c.noOfOrders / totalOrders) * 100.0;
      }
    }

    if (mounted) {
      setState(() {
        receivablesCategoryList = receivablesCategoryListLocal;
      });
    } else {
      receivablesCategoryList = receivablesCategoryListLocal;
    }
  }

  Future<void> _loadMonthlySalesVsProduction() async {
    final inventoryList = deliveryData;
    final int year = selectedDate?.year ?? DateTime.now().year;

    List<MonthlySalesVsProductionData> months = [];

    DateTime? tryParseDate(String? input) {
      if (input == null || input.trim().isEmpty) return null;
      try {
        return DateFormat('dd/MM/yyyy').parseStrict(input);
      } catch (_) {
        try {
          return DateTime.tryParse(input);
        } catch (_) {
          return null;
        }
      }
    }

    for (int m = 1; m <= 12; m++) {
      final DateTime monthStart = DateTime(year, m, 1);
      final DateTime monthEnd = DateTime(
        year,
        m + 1,
        1,
      ).subtract(const Duration(days: 1));

      final monthItems = inventoryList.where((target) {
        final DateTime? dueOn = tryParseDate(target.soDate);
        if (dueOn == null) return false;
        return !dueOn.isBefore(monthStart) && !dueOn.isAfter(monthEnd);
      }).toList();

      final int totalCount = monthItems.length;
      if (totalCount == 0) {
        continue;
      }

      final int closedCount = monthItems
          .where(
            (t) => ((t.soStatus).toString().toLowerCase().trim() == 'close'),
          )
          .length;
      final int pendingCount = totalCount - closedCount;

      months.add(
        MonthlySalesVsProductionData(
          monthName: DateFormat('MMMM').format(monthStart),
          noOfOrders: totalCount.toDouble(),
          completed: closedCount.toDouble(),
          pending: pendingCount.toDouble(),
        ),
      );
    }

    final result = MonthlySalesVsProductionList(monthlyData: months);

    if (mounted) {
      setState(() {
        monthlyData = result;
      });
    } else {
      monthlyData = result;
    }
  }

  int touchedIndex = -1;

  Color getCategoryColor(int categoryId) {
    switch (categoryId) {
      case 1:
        return Colors.green;
      case 2:
        return const Color(0xFFF49136);
      case 3:
        return Colors.grey;
      case 4:
        return Colors.lightBlue;
      default:
        return const Color(0xFF6CCC3F);
    }
  }

  List<PieChartSectionData> _receivablesCategoryChart() {
    final List<PieChartSectionData> sections = [];
    for (final categoryData in receivablesCategoryList.categoryData) {
      final isTouched = (categoryData.categoryId) == touchedIndex;
      final fontSize = touchedIndex >= 1 ? 12.0 : 11.0;
      final radius = touchedIndex >= 1 ? 80.0 : 75.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      final sectionData = PieChartSectionData(
        color: getCategoryColor(categoryData.categoryId),
        value: categoryData.noOfOrdersPercentage,
        title: '${categoryData.noOfOrdersPercentage?.toStringAsFixed(2)} %',
        radius: radius,
        badgeWidget: isTouched
            ? Visibility(
                visible: isTouched,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Text(""),
                ),
              )
            : null,
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

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadDeliveryDetails(userName, userLevel);
    await _loadSalesVsProduction();
    await _loadMonthlySalesVsProduction();
    chartDataLoaded = true;
  }

  Future<void> loadDataWithBranchFilter(String branch) async {
    completedOrders = 0;
    completedOrdersPercent = 0;
    completedOrdersPercentage = 0;
    pendingOrders = 0;
    pendingOrdersPercent = 0;
    pendingOrdersPercentage = 0;
    chartDataLoaded = false;
    deliveryData = deliveryDataTemp;
    deliveryData = deliveryData
        .where((test) => test.branchName == branch)
        .toList();
    await _loadSalesVsProduction();
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> loadDataWithDateFilter(DateTime date) async {
    completedOrders = 0;
    completedOrdersPercent = 0;
    completedOrdersPercentage = 0;
    pendingOrders = 0;
    pendingOrdersPercent = 0;
    pendingOrdersPercentage = 0;
    chartDataLoaded = false;
    deliveryData = deliveryDataTemp;
    deliveryData = deliveryData
        .where((test) => test.branchName == selectedBranch)
        .toList();
    await _loadSalesVsProduction();
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> loadDataClearFilter() async {
    chartDataLoaded = false;
    stockData = stockDataTemp;
    await _loadSalesVsProduction();

    setState(() {});
  }

  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  Future<void> generateSalesVsProduction(BuildContext context) async {
    try {
      final excel = xl.Excel.createExcel();

      final sheet = excel['Aging Report'];
      try {
        if (excel.sheets.containsKey('Sheet1')) {
          excel.delete('Sheet1');
        }
      } catch (_) {}

      sheet.appendRow(
        toCellRow([
          'Summary of Sale Order punched vs sale orders of $selectedBranch',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
        ]),
      );
      sheet.appendRow(toCellRow(["Description", "Total Order", "%"])); // spacer
      sheet.appendRow(
        toCellRow([
          "Total Order Received in the month",
          completedOrders + pendingOrders,
          "100%",
        ]),
      ); // spacer
      sheet.appendRow(
        toCellRow([
          "Total No. of Orders Completed in the Month",
          completedOrders,
          "$completedOrdersPercentage %",
        ]),
      ); // spacer
      sheet.appendRow(
        toCellRow([
          "Pending sales orders",
          pendingOrders,
          "$pendingOrdersPercentage %",
        ]),
      ); // spacer
      sheet.appendRow(
        toCellRow([
          "No. orders cleared before /on time",
          receivablesCategoryList.categoryData[0].noOfOrders,
          "${receivablesCategoryList.categoryData[0].noOfOrdersPercentage} %",
        ]),
      );
      sheet.appendRow(
        toCellRow([
          "No. of orders delayed by 1 to 5 days",
          receivablesCategoryList.categoryData[1].noOfOrders,
          "${receivablesCategoryList.categoryData[1].noOfOrdersPercentage} %",
        ]),
      );
      sheet.appendRow(
        toCellRow([
          "No. of orders delayed by 6 to 10 days",
          receivablesCategoryList.categoryData[2].noOfOrders,
          "${receivablesCategoryList.categoryData[2].noOfOrdersPercentage} %",
        ]),
      );
      sheet.appendRow(
        toCellRow([
          "No. of orders delayed above 10 days",
          receivablesCategoryList.categoryData[3].noOfOrders,
          "${receivablesCategoryList.categoryData[3].noOfOrdersPercentage} %",
        ]),
      );

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('salesVsProduction.xlsx', excelBytes);
      } else {
        final storageDir = await getStorageDirectory();
        final file = File('$storageDir/salesVsProduction.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error exporting Excel: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> selectMonth(BuildContext context) async {
    final DateTime? picked = await showMonthPicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2027),
    );
    if (picked != null &&
        (picked.month != selectedDate!.month ||
            picked.year != selectedDate!.year)) {
      setState(() {
        selectedDate = picked;
        loadDataWithDateFilter(picked);
      });
    }
  }

  @override
  void initState() {
    selectedDate = DateTime.now();
    super.initState();
    LoadDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedFiscalYearStartDate = DateFormat(
      'dd/MM/yy',
    ).format(fiscalYearStartDate!);
    String formattedDateNow = DateFormat('dd/MM/yy').format(currentDate!);
    return chartDataLoaded == true
        ? SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 15),
                        Text(
                          "$formattedFiscalYearStartDate - $formattedDateNow",
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            selectMonth(context);
                          },
                          icon: const Icon(Icons.filter_alt_outlined),
                        ),
                        const SizedBox(width: 5),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Sales Vs Delivery",
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
                                    generateSalesVsProduction(context);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    // generateMonthlyProductionPDF(monthData);
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ItemSubGroupDropdown(
                      production: deliveryDataTemp,
                      onChanged: (newValue) {
                        selectedBranch = newValue ?? "Karnataka State";
                        loadDataWithBranchFilter(newValue!);
                      },
                    ),
                    const SizedBox(width: 5),
                  ],
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4.0,
                                right: 4.0,
                              ),
                              child: CircularPercentIndicator(
                                arcType: ArcType.HALF,
                                radius: 70.0,
                                lineWidth: 27.0,
                                animation: true,
                                percent: completedOrdersPercent / 100,
                                curve: Curves.linear,
                                circularStrokeCap: CircularStrokeCap.butt,
                                progressColor: Colors.green,
                                arcBackgroundColor: Colors.red,
                                center: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 45),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Completed: $completedOrders",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.0,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Pending: $pendingOrders",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 10.0,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 30),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4.0,
                                right: 4.0,
                              ),
                              child: CircularPercentIndicator(
                                arcType: ArcType.HALF,
                                radius: 70.0,
                                lineWidth: 27.0,
                                animation: true,
                                percent: completedOrdersPercentage / 100,
                                curve: Curves.linear,
                                circularStrokeCap: CircularStrokeCap.butt,
                                progressColor: Colors.green,
                                arcBackgroundColor: Colors.red,
                                center: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 45),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Completed: ${completedOrdersPercentage.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.0,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Pending: ${pendingOrdersPercentage.toStringAsFixed(2)}",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 10.0,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                        height: 150,
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
                                        touchedIndex = -1;
                                        return;
                                      }
                                      touchedIndex = pieTouchResponse
                                          .touchedSection!
                                          .touchedSectionIndex;
                                    });
                                  },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 1,
                            centerSpaceRadius: 0,
                            startDegreeOffset: 180,
                            sections: _receivablesCategoryChart(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 75.0),
                  child: Row(
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
                                  color: Colors.green,
                                  // color: getCategoryColor(categoryData.categoryId),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 8,
                                  width: 16,
                                  color: Colors.orange,
                                  // color: getCategoryColor(categoryData.categoryId),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 8,
                                  width: 16,
                                  color: Colors.grey,
                                  // color: getCategoryColor(categoryData.categoryId),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 8,
                                  width: 16,
                                  color: Colors.lightBlue,
                                  // color: getCategoryColor(categoryData.categoryId),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              "No. orders cleared before/on time: ${receivablesCategoryList.categoryData[0].noOfOrders}",
                              textAlign: TextAlign.left,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              "No. of orders delayed by 1 to 5 days: ${receivablesCategoryList.categoryData[1].noOfOrders} ",
                              textAlign: TextAlign.left,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              "No. of orders delayed by 6 to 10 days:  ${receivablesCategoryList.categoryData[2].noOfOrders}",
                              textAlign: TextAlign.left,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              "No. of orders delayed > 10 days: ${receivablesCategoryList.categoryData[3].noOfOrders}",
                              textAlign: TextAlign.left,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _itemSubGroupGraph(),
                ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  Widget _itemSubGroupGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = monthlyData.monthlyData.length;
    if (monthlyData.monthlyData.length > 5) {
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
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesMonthlyInventory,
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
            barGroups: _MonthlyChartData(monthlyData.monthlyData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      // touchedWarehouseLocation = touchedWarehouseLocation == ""
                      //     ? warehouseLocationList
                      //     .warehouseData[
                      // barTouchResponse.spot!.spot.x.toInt()]
                      //     .warehouseName
                      //     : "";
                      // selectedChart = barTouchResponse.spot!.spot.x;
                      // showDrillDownChart = true;
                      // loadDataWithFilter(
                      //   touchedAging,
                      //   touchedWarehouseLocation,
                      //   touchedItemGroup,
                      //   touchedItemSubGroup,
                      // );
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
                    monthlyData.monthlyData[grpIndex].monthName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\nTotal Orders: ${monthlyData.monthlyData[grpIndex].noOfOrders}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nCompleted: ${monthlyData.monthlyData[grpIndex].completed}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nPending : ${monthlyData.monthlyData[grpIndex].pending}",
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

class ItemSubGroupDropdown extends StatefulWidget {
  final List production;
  final ValueChanged<String?> onChanged;
  final String placeholder;

  const ItemSubGroupDropdown({
    super.key,
    required this.production,
    required this.onChanged,
    this.placeholder = 'Kits/Gowns',
  });

  @override
  State<ItemSubGroupDropdown> createState() => _ItemSubGroupDropdownState();
}

class _ItemSubGroupDropdownState extends State<ItemSubGroupDropdown> {
  late final List<String> _items;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _items = _extractItemSubGroups(widget.production);
    _selected = _items.isNotEmpty ? _items.first : null;
  }

  List<String> _extractItemSubGroups(List list) {
    final seen = <String>{};
    final out = <String>[];
    for (var e in list) {
      String val = '';
      try {
        val = (e.branchName ?? '').toString().trim();
      } catch (_) {
        if (e is Map && e.containsKey('branchName')) {
          val = (e['branchName'] ?? '').toString();
        }
      }
      if (val.trim().isEmpty) continue;
      if (!seen.contains(val)) {
        seen.add(val);
        out.add(val);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selected,
              hint: const SizedBox.shrink(),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              items: _items.map((s) {
                return DropdownMenuItem<String>(
                  value: s,
                  child: Text(s, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selected = val;
                });
                widget.onChanged(val);
              },
              isDense: true,
              isExpanded: false,
            ),
          ),
        ],
      ),
      onTap: () {},
    );
  }
}
