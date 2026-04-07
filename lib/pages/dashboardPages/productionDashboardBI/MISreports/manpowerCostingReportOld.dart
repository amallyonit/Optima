// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, no_leading_underscores_for_local_identifiers, use_super_parameters
import 'package:optima/excel_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:excel/excel.dart' as xl;
import '../../../../api_helper.dart';

import 'package:optima/pages/dashboardPages/excel_helper_web.dart';

class ManpowerCostingReportOld extends StatefulWidget {
  const ManpowerCostingReportOld({super.key});

  @override
  State<ManpowerCostingReportOld> createState() =>
      _ManpowerCostingReportOldState();
}

class DailyProductionData {
  final DateTime date;
  final String dayLabel; // e.g. "01 Aug"
  final double production; // sum of completedQty for that day
  final int boxNo; // summed boxes for that day (rounded)

  DailyProductionData({
    required this.date,
    required this.dayLabel,
    required this.production,
    required this.boxNo,
  });
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
List<ProductionOrderList> productionTemp = [];
List<RCPList> rcpList = [];
List<MonthlyCTCList> ctcList = [];
List<SalesTargetList> salesTarget = [];

bool chartDataLoaded = false;

MonthlyProductionList monthData = MonthlyProductionList(monthlyData: []);
MonthlyProductionList monthLineData = MonthlyProductionList(monthlyData: []);
// MonthlyProductionList currentMonthDailyData = MonthlyProductionList(monthlyData: []);

List<DailyProductionData> currentMonthDailyData = [];
List<DailyProductionData> currentMonthDailyLineData = [];
double currentMonthAverageBoxes = 0.0;

String producedQty = '';
String boxesProduced = '';
String totalWorkforce = '';

List<String> row0 = [];
List<String> row1 = [];

double producedQtyTotal = 0;
double producedQtyTotalPercentage = 0;
double producedQtyBoxPercentage = 0;
double producedQtyLastMonthTotal = 0;
double producedQtyLast3MonthTotal = 0;
double producedQtyFinYearTotal = 0;
double producedQtyTotalBox = 0;
double producedQtyLastMonthTotalBox = 0;
double producedQtyLast3MonthTotalBox = 0;
double producedQtyFinYearTotalBox = 0;
double targetProductionQty = 0;
double targetProductionQtyBox = 0;

String getMonthName(int month) {
  final formatter = DateFormat('MMMM');
  return formatter.format(DateTime(2000, month));
}

class ManpowerCostingProductionProvider with ChangeNotifier {
  List<ProductionOrderList> _salesList = [];
  List<ProductionOrderList> get salesList => _salesList;
  void updatePurchaseList(List<ProductionOrderList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class ManpowerCostingRCPProvider with ChangeNotifier {
  List<RCPList> _salesList = [];
  List<RCPList> get salesList => _salesList;
  void updatePurchaseList(List<RCPList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class ManpowerCostingCTCProvider with ChangeNotifier {
  List<MonthlyCTCList> _salesList = [];
  List<MonthlyCTCList> get salesList => _salesList;
  void updatePurchaseList(List<MonthlyCTCList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class ManpowerCostingTargetProvider with ChangeNotifier {
  List<SalesTargetList> _salesTargetList = [];
  List<SalesTargetList> get salesTargetList => _salesTargetList;
  void updateSalesTargetList(List<SalesTargetList> newSalesTargetList) {
    _salesTargetList = newSalesTargetList;
    notifyListeners();
  }
}

class _ManpowerCostingReportOldState extends State<ManpowerCostingReportOld> {
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
          "FromDate": formatDate(fiscalYearStartDate!),
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
        final allowed = {
          'Wrap Sheet',
          'Packs',
          'Gowns',
          'Safety Packs',
          'Drapes',
        };
        production = salesList
            .where((test) => allowed.contains(test.itemSubGroup))
            .toList();
        productionTemp = salesList
            .where((test) => allowed.contains(test.itemSubGroup))
            .toList();
        context.read<ManpowerCostingProductionProvider>().updatePurchaseList(
          salesList,
        );
        production = salesList
            .where((test) => allowed.contains(test.itemSubGroup))
            .toList();
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

      dateRange = getLastThreeMonthsRange(lastMonthFromDate!.month);
      prevThreethFromDate = dateRange['fromDate']!;
      prevThreeMthToDate = dateRange['toDate']!;

      var currentMonthProduction = production.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);

        return invoiceDate.isAtLeast(currentMonthFromDate!) &&
            invoiceDate.isAtMost(currentMonthToDate!);
      });
      var lastMonthProduction = production.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);

        return invoiceDate.isAtLeast(lastMonthFromDate!) &&
            invoiceDate.isAtMost(lastMonthToDate!);
      });
      var last3MonthProduction = production.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);

        return invoiceDate.isAtLeast(prevThreethFromDate!) &&
            invoiceDate.isAtMost(prevThreeMthToDate!);
      });
      var finYearProduction = production.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.orderDate);

        return invoiceDate.isAtLeast(fiscalYearStartDate!) &&
            invoiceDate.isAtMost(currentDate!);
      });

      double tempTotalThisMonth = 0;
      double tempTotalThisMonthBoxes = 0;
      double totalProdThisMonth = 0;
      double tempTotalLastMonth = 0;
      double tempTotalLastMonthBoxes = 0;
      double totalProdLastMonth = 0;
      double tempTotalLast3Month = 0;
      double tempTotalLast3MonthBoxes = 0;
      double totalProdLast3Month = 0;
      double tempTotalFinYear = 0;
      double tempTotalFinYearBoxes = 0;
      double totalProdFinYear = 0;
      for (var target in currentMonthProduction.toList()) {
        tempTotalThisMonth = double.tryParse(target.completedQty) ?? 0;
        totalProdThisMonth += tempTotalThisMonth;
        tempTotalThisMonthBoxes =
            totalProdThisMonth / (double.parse(target.boxQty));
      }
      for (var target in lastMonthProduction.toList()) {
        tempTotalLastMonth = double.tryParse(target.completedQty) ?? 0;
        totalProdLastMonth += tempTotalLastMonth;
        tempTotalLastMonthBoxes =
            totalProdLastMonth / (double.parse(target.boxQty));
      }
      for (var target in last3MonthProduction.toList()) {
        tempTotalLast3Month = double.tryParse(target.completedQty) ?? 0;
        totalProdLast3Month += tempTotalLast3Month;
        tempTotalLast3MonthBoxes =
            totalProdLast3Month / (double.parse(target.boxQty));
      }
      for (var target in finYearProduction.toList()) {
        tempTotalFinYear = double.tryParse(target.completedQty) ?? 0;
        totalProdFinYear += tempTotalFinYear;
        tempTotalFinYearBoxes =
            totalProdFinYear / (double.parse(target.boxQty));
      }
      producedQtyTotal = totalProdThisMonth;
      producedQtyLastMonthTotal = totalProdLastMonth;
      producedQtyLast3MonthTotal = totalProdLast3Month;
      producedQtyFinYearTotal = totalProdFinYear;

      producedQtyTotalBox = tempTotalThisMonthBoxes;
      producedQtyLastMonthTotalBox = tempTotalLastMonthBoxes;
      producedQtyLast3MonthTotalBox = tempTotalLast3MonthBoxes;
      producedQtyFinYearTotalBox = tempTotalFinYearBoxes;

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
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> _loadRCPList(String UserName, String UserLevel) async {
    LoadAllQuarterFromToDates();
    int index = 0;
    int limit = 10000; // Maximum limit to fetch all data
    int fetchedCount = 0;
    List<RCPList> salesList = [];

    try {
      do {
        var body = {
          "FromDate": formatDate(fiscalYearStartDate!),
          "ToDate": formatDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}BicxoRCPList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<RCPList> newSalesList = (responseJson['responseData'] as List)
                .map((item) => RCPList.fromJson(item))
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
        rcpList = salesList;
        context.read<ManpowerCostingRCPProvider>().updatePurchaseList(
          salesList,
        );
        rcpList = salesList.toList();
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
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  String toYearMonth(DateTime dt) {
    final year = dt.year.toString();
    final month = dt.month.toString().padLeft(2, '0');
    return '$year-$month';
  }

  Future<void> _loadMonthlyCTCList(String UserName, String UserLevel) async {
    LoadAllQuarterFromToDates();
    int limit = 10000;
    int fetchedCount = 0;
    List<MonthlyCTCList> salesList = [];
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';

    try {
      do {
        var body = {
          "UsermailID": userMailID,
          "UserJwtToken": userJwtToken,
          "MonthYear": DateFormat('yyyy-MM').format(currentDate!),
        };
        const apiUrl = '${ApiHelper.baseUrl}selectmonthlyctcdetails';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["Status"] == true &&
              responseJson["Data"] != null &&
              (responseJson["Data"] as List).isNotEmpty) {
            List<MonthlyCTCList> newSalesList = (responseJson['Data'] as List)
                .map((item) => MonthlyCTCList.fromJson(item))
                .toList();

            salesList.addAll(newSalesList);
            fetchedCount = newSalesList.length;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        ctcList = salesList;
        context.read<ManpowerCostingCTCProvider>().updatePurchaseList(
          salesList,
        );
        ctcList = salesList.toList();
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
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> _loadTarget(String UserName, String UserLevel) async {
    final body = {
      "FromDate": formatDate(fiscalYearStartDate!),
      "ToDate": formatDate(currentDate!),
      "Index": 0,
      "Limit": 0,
      "sapToken": DataManager.readSapToken(),
    };
    const apiUrl = '${ApiHelper.baseUrl}BicxoSalesTargetList';
    var headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      // HttpHeaders.authorizationHeader: 'Bearer    ${DataManager.readSapToken()}'
    };
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(body),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        if (responseJson["responseData"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['responseData'];
          if (data.isNotEmpty) {
            List<SalesTargetList> newSalesTargetList = (data)
                .map((item) => SalesTargetList.fromJson(item))
                .toList();
            setState(() {
              context
                  .read<ManpowerCostingTargetProvider>()
                  .updateSalesTargetList(newSalesTargetList);
              if (int.parse(UserLevel) == 5) {
                salesTarget = newSalesTargetList;
              } else if (int.parse(UserLevel) == 4) {
                salesTarget = newSalesTargetList;
              } else if (int.parse(UserLevel) <= 3 &&
                  int.parse(UserLevel) >= 2) {
                salesTarget = newSalesTargetList;
              } else {
                salesTarget = newSalesTargetList;
              }
              int monthIndex = currentDate!.month;
              String Month = getMonthName(monthIndex);
              for (var target in salesTarget.where(
                (element) => element.salesRep == "PRODUCTION QTY TARGET",
              )) {
                targetProductionQty =
                    double.tryParse(target.getTargetForMonth(Month)) ?? 0;
              }
              for (var target in salesTarget.where(
                (element) => element.salesRep == "PRODUCTION BOX QTY TARGET",
              )) {
                targetProductionQtyBox =
                    double.tryParse(target.getTargetForMonth(Month)) ?? 0;
              }

              producedQtyTotalPercentage = producedQtyTotal == 0
                  ? 0.0
                  : (producedQtyTotal * 100.0) / targetProductionQty;
              producedQtyBoxPercentage = producedQtyTotalBox == 0
                  ? 0.0
                  : (producedQtyTotalBox * 100.0) / targetProductionQtyBox;

              if (producedQtyTotalPercentage >= 100) {
                producedQtyTotalPercentage = 100;
              }
              if (producedQtyBoxPercentage >= 100) {
                producedQtyBoxPercentage = 100;
              }
            });
          }
        } else {
          if (responseJson.containsKey("Error") &&
              responseJson["Error"].toString() == "Invalid or Expired Token") {
            final snackBar = SnackBar(
              duration: const Duration(seconds: 1),
              content: Text(
                responseJson["Error"].toString(),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          } else {
            final snackBar = SnackBar(
              content: Text(responseJson["Error"].toString()),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      } else {
        const snackBar = SnackBar(
          content: Text('Sales target details not found.'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      const snackBar = SnackBar(
        content: Text('SAP Server down, Please try again after some time.'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
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

  SideTitles get _bottomTitles =>
      SideTitles(showTitles: true, getTitlesWidget: getBottomTitles);

  SideTitles get _bottomTitlesPayables => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<DailyProductionData> mData = currentMonthDailyData;
      text = mData.elementAt(value.toInt()).dayLabel;
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

  String getMonthName(int month) {
    final formatter = DateFormat('MMMM');
    return formatter.format(DateTime(2000, month));
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

  List<BarChartGroupData> _monthWiseProductionAnalysisDailyChartData(
    List<DailyProductionData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: chartData.production,
                  show: true,
                  color: const Color(0xFFF49136),
                ),
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.boxNo.toDouble(),
                width: 30,
              ),
            ],
          ),
        )
        .toList();
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

    for (int i = 4; i <= 15; i++) {
      monthName = getMonthName(i);
      if (i >= 4 && i <= 12) {
        // For months 4..12 we use getLastThreeMonthsRange for actual period for productionActual
        Map<String, DateTime> monthDates = getMonthStartEndDates(i);
        monthlyProductionActual = production.where((target) {
          DateTime invoiceDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.orderDate);
          return invoiceDate.isAtLeast(monthDates['start']!) &&
              invoiceDate.isAtMost(monthDates['end']!);
        });
      } else {
        // Wrap-around months (13..15) -> months 1..3 of next year
        monthName = getMonthName(i - 12);
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

      // --- NEW: get monthlyTarget from salesTarget for this monthName ---
      monthlyTarget = 0;
      String Month = monthName; // matches your snippet's 'Month'
      for (var target in salesTarget.where(
        (element) => element.salesRep == "PRODUCTION QTY TARGET",
      )) {
        monthlyTarget = double.tryParse(target.getTargetForMonth(Month)) ?? 0;
        // if multiple rows exist, this will take the last one — change if you need sum instead
      }

      double actualAmt = 0;
      double boxCountSum = 0;
      monthlyProduction = 0; // reset before accumulating

      for (var target in monthlyProductionActual.toList()) {
        actualAmt = (double.tryParse(target.completedQty) ?? 0);
        monthlyProduction += actualAmt;

        double completed = double.tryParse(target.completedQty) ?? 0;
        double boxQty = 0;
        try {
          boxQty = double.tryParse(target.boxQty?.toString() ?? '') ?? 0;
        } catch (e) {
          boxQty = 0;
        }
        double boxesForThisRecord = boxQty > 0 ? (completed / boxQty) : 0;
        boxCountSum += boxesForThisRecord;
      }

      int boxNoForMonth = boxCountSum.round();

      if (monthlyProduction > 0) {
        month.add(
          MonthlyProductionData(
            monthName: monthName,
            target: monthlyTarget,
            production: monthlyProduction,
            boxNo: boxNoForMonth,
          ),
        );
      }

      // prepare for next iteration
      monthlyProduction = 0;
      monthlyTarget = 0;
      monthData = MonthlyProductionList(monthlyData: month);
    }

    monthData = MonthlyProductionList(monthlyData: month);
  }

  Future<void> _loadMonthlyProductionLineChartData() async {
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

      double boxCountSum = 0;
      for (var target in monthlyProductionActual.toList()) {
        actualAmt = (double.tryParse(target.completedQty) ?? 0);
        monthlyProduction += actualAmt;

        double completed = double.tryParse(target.completedQty) ?? 0;
        double boxQty = 0;
        try {
          boxQty = double.tryParse(target.boxQty?.toString() ?? '') ?? 0;
        } catch (e) {
          boxQty = 0;
        }
        double boxesForThisRecord = boxQty > 0 ? (completed / boxQty) : 0;
        boxCountSum += boxesForThisRecord;
      }

      int boxNoForMonth = boxCountSum.round();

      if (monthlyProduction > 0) {
        month.add(
          MonthlyProductionData(
            monthName: monthName,
            target: monthlyTarget,
            production: monthlyProduction,
            boxNo: boxNoForMonth,
          ),
        );
      }

      monthlyProduction = 0;
      monthlyTarget = 0;
      monthLineData = MonthlyProductionList(monthlyData: month);
    }

    monthLineData = MonthlyProductionList(monthlyData: month);
  }

  Future<void> _loadCurrentMonthDailyProductionData() async {
    final List<DailyProductionData> dailyList = [];
    final now = DateTime.now();
    final int year = now.year;
    final int month = now.month;

    final DateFormat df = DateFormat('dd/MM/yyyy');

    final DateTime endDate = DateTime(year, month + 1, 0);
    final int daysInMonth = endDate.day;

    double monthTotalProduction = 0.0;
    for (int d = 1; d <= daysInMonth; d++) {
      final DateTime dayDate = DateTime(year, month, d);
      final String dayLabel = DateFormat('dd MMM').format(dayDate);

      double dailyProduction = 0.0;
      double dailyBoxSum = 0.0;

      final dayRecords = production.where((rec) {
        try {
          final DateTime invoiceDate = df.parse(rec.orderDate);
          return invoiceDate.year == year &&
              invoiceDate.month == month &&
              invoiceDate.day == d;
        } catch (e) {
          return false;
        }
      }).toList();

      for (final rec in dayRecords) {
        final double completed = double.tryParse(rec.completedQty) ?? 0.0;
        dailyProduction += completed;

        double boxQty = 0.0;
        try {
          boxQty = double.tryParse(rec.boxQty.toString()) ?? 0.0;
        } catch (e) {
          boxQty = 0.0;
        }
        final double boxesForRec = boxQty > 0 ? (completed / boxQty) : 0.0;
        dailyBoxSum += boxesForRec;
      }

      final int boxNoForDay = dailyBoxSum.round();

      dailyList.add(
        DailyProductionData(
          date: dayDate,
          dayLabel: dayLabel,
          production: dailyProduction,
          boxNo: boxNoForDay,
        ),
      );

      monthTotalProduction += dailyProduction;
    }

    final double avgBoxesPerWorkingDay = monthTotalProduction / 26.0;

    currentMonthDailyData = dailyList;
    currentMonthAverageBoxes = avgBoxesPerWorkingDay;
  }

  Future<void> _loadCurrentMonthDailyLineProductionData() async {
    final List<DailyProductionData> dailyList = [];
    final now = DateTime.now();
    final int year = now.year;
    final int month = now.month;

    final DateFormat df = DateFormat('dd/MM/yyyy');

    final DateTime endDate = DateTime(year, month + 1, 0);
    final int daysInMonth = endDate.day;

    double monthTotalProduction = 0.0;
    for (int d = 1; d <= daysInMonth; d++) {
      final DateTime dayDate = DateTime(year, month, d);
      final String dayLabel = DateFormat('dd MMM').format(dayDate);

      double dailyProduction = 0.0;
      double dailyBoxSum = 0.0;

      final dayRecords = production.where((rec) {
        try {
          final DateTime invoiceDate = df.parse(rec.orderDate);
          return invoiceDate.year == year &&
              invoiceDate.month == month &&
              invoiceDate.day == d;
        } catch (e) {
          return false;
        }
      }).toList();

      for (final rec in dayRecords) {
        final double completed = double.tryParse(rec.completedQty) ?? 0.0;
        dailyProduction += completed;

        double boxQty = 0.0;
        try {
          boxQty = double.tryParse(rec.boxQty.toString()) ?? 0.0;
        } catch (e) {
          boxQty = 0.0;
        }
        final double boxesForRec = boxQty > 0 ? (completed / boxQty) : 0.0;
        dailyBoxSum += boxesForRec;
      }

      final int boxNoForDay = dailyBoxSum.round();

      dailyList.add(
        DailyProductionData(
          date: dayDate,
          dayLabel: dayLabel,
          production: dailyProduction,
          boxNo: boxNoForDay,
        ),
      );

      monthTotalProduction += dailyProduction;
    }

    final double avgBoxesPerWorkingDay = monthTotalProduction / 26.0;

    currentMonthDailyLineData = dailyList;
    currentMonthAverageBoxes = avgBoxesPerWorkingDay;
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    production = productionTemp;
    await _loadProductionOrderTargetAnalysis(userName, userLevel);
    await _loadRCPList(userName, userLevel);
    await _loadMonthlyCTCList(userName, userLevel);
    await _loadTarget(userName, userLevel);
    await _loadMonthlyProductionBarChartData();
    await _loadMonthlyProductionLineChartData();
    await _loadCurrentMonthDailyProductionData();
    await _loadCurrentMonthDailyLineProductionData();
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> loadDataWithBranchFilter(String branch) async {
    chartDataLoaded = false;
    production = productionTemp;
    production = production.where((test) => test.branch == branch).toList();
    await _loadMonthlyProductionBarChartData();
    await _loadMonthlyProductionLineChartData();
    await _loadCurrentMonthDailyProductionData();
    await _loadCurrentMonthDailyLineProductionData();
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> loadDataClearFilter() async {
    chartDataLoaded = false;
    production = productionTemp;
    await _loadMonthlyProductionBarChartData();
    await _loadMonthlyProductionLineChartData();
    await _loadCurrentMonthDailyProductionData();
    await _loadCurrentMonthDailyLineProductionData();
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> loadDataWithItemSubGroupFilter(String subGroup) async {
    chartDataLoaded = false;
    production = productionTemp;
    final allowedForKits = {'packs', 'gowns', 'safety packs', 'drapes'};
    String? _getItemSubGroup(dynamic test) {
      try {
        final raw = (test.itemSubGroup ?? '').toString();
        return raw.trim();
      } catch (_) {
        if (test is Map && test.containsKey('itemSubGroup')) {
          final raw = (test['itemSubGroup'] ?? '').toString();
          return raw.trim();
        }
      }
      return null;
    }

    final sel = subGroup.trim().toLowerCase();
    production = production.where((test) {
      final val = _getItemSubGroup(test)?.toLowerCase();
      if (val == null || val.isEmpty) return false;

      if (sel == 'kits/gowns') {
        return allowedForKits.contains(val);
      }
      return val == sel;
    }).toList();
    await _loadMonthlyProductionLineChartData();
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> loadDataWithItemSubGroupDailyFilter(String subGroup) async {
    chartDataLoaded = false;
    production = productionTemp;
    final allowedForKits = {'packs', 'gowns', 'safety packs', 'drapes'};
    String? _getItemSubGroup(dynamic test) {
      try {
        final raw = (test.itemSubGroup ?? '').toString();
        return raw.trim();
      } catch (_) {
        if (test is Map && test.containsKey('itemSubGroup')) {
          final raw = (test['itemSubGroup'] ?? '').toString();
          return raw.trim();
        }
      }
      return null;
    }

    final sel = subGroup.trim().toLowerCase();
    production = production.where((test) {
      final val = _getItemSubGroup(test)?.toLowerCase();
      if (val == null || val.isEmpty) return false;

      if (sel == 'kits/gowns') {
        return allowedForKits.contains(val);
      }
      return val == sel;
    }).toList();
    await _loadMonthlyProductionLineChartData();
    setState(() {
      chartDataLoaded = true;
    });
  }

  String producedQty = '789483';
  String boxesProduced = '9856';
  String totalWorkforce = '8450';

  List<List<String>> tableData = [];

  List<String> particulars = [
    'Produced Qty',
    'No.of Boxes Produced',
    'Total Present Workforce',
    'Total Present Labour',
    'Avg no of workforce/ Box /month',
    'Avg no of Labour/ Box /month',
    'Avg Monthly CTC of Total Workforce',
    'Avg Monthly CTC of Total Labour',
    'Avg. Boxes/Day',
    'No. of Working Days',
    'Avg Workforce',
    'Avg Labour',
    'Total Manpower Cost/box /day',
    'Total Labour Cost/box /day',
  ];

  List<String> random = [];

  Future<void> generateManpowerExcel(BuildContext context) async {
    try {
      final excel = xl.Excel.createExcel();

      final sheet = excel['Manpower'];
      try {
        if (excel.sheets.containsKey('Sheet1')) {
          excel.delete('Sheet1');
        }
      } catch (_) {}

      sheet.appendRow(
        toCellRow([
          'Manpower Cost of BLR Plant Per Carton Per Day - 2024-25',
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

      sheet.appendRow(toCellRow([])); // spacer

      final headers = [
        'Particulars',
        'KPI/Target',
        'Wrap Sheets',
        'Kits & Gowns',
        'Total',
        'Increase/Decrease\nease with Target',
        'Remarks',
        'Dec-24\nTotal',
        '% w.r.t.\nCurrent Month',
        'Last 3 months\nTotal',
        '% w.r.t.\nCurrent Month',
        'Last 12 Months\nTotal',
        '% w.r.t.\nCurrent Month',
      ];
      sheet.appendRow(toCellRow(headers));

      final List<String> rowLabels = [
        'Produced Qty',
        'No. of Boxes Produced',
        'Total Present Workforce',
        'Total Present Labour',
        'Avg no of workforce/ Box /month',
        'Avg no of Labour/ Box /month',
        'Avg Monthly CTC of Total Workforce',
        'Avg Monthly CTC of Total Labour',
        'Avg. Boxes/Day',
        'No. of Working Days',
        'Avg Workforce',
        'Avg Labour',
        'Total Manpower Cost/box /day',
        'Total Labour Cost/box /day',
        'Total Box Quantity decreased by',
        'Wrap sheet production increased by',
        'Kit Gown decreased by',
        'Average box per day increased by',
        'Man Power cost/box decreased by (Total Workforce)',
        'Man Power cost/box decreased by (Total Labour)',
      ];

      for (var label in rowLabels) {
        final row = <Object?>[label];
        for (int i = 0; i < headers.length - 1; i++) {
          row.add('');
        }
        sheet.appendRow(toCellRow(row));
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('manpower_report.xlsx', excelBytes);
      } else {
        final storageDir = await getStorageDirectory();
        final file = File('$storageDir/manpower_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error exporting Excel: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  double getPercentage(double part, double total) {
    if (total == 0) return 0;
    return (part / total) * 100;
  }

  @override
  void initState() {
    super.initState();
    LoadDates();
    currentMonthAverageBoxes = 0;
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
    }
    row0 = [
      "$producedQtyTotal",
      "${getPercentage(producedQtyTotal, targetProductionQty)}",
      "$producedQtyLastMonthTotal",
      "${getPercentage(producedQtyLastMonthTotal, producedQtyTotal)}",
      "$producedQtyLast3MonthTotal",
      "${getPercentage(producedQtyLast3MonthTotal, producedQtyTotal)}",
      "$producedQtyFinYearTotal",
      "${getPercentage(producedQtyFinYearTotal, producedQtyTotal)}",
    ];
    tableData = [
      row0,
      [
        producedQty,
        '-29.60%',
        '780133',
        '1.20%',
        '904551',
        '-12.72%',
        '982228',
        '-19.62%',
      ],
      [boxesProduced, '', '12016', '-17.98%', '', '', '', ''],
      [totalWorkforce, '', '', '', '', '', '', ''],
    ];
  }

  @override
  Widget build(BuildContext context) {
    String formattedFiscalYearStartDate = DateFormat(
      'dd/MM/yy',
    ).format(fiscalYearStartDate!);
    String formattedDateNow = DateFormat('dd/MM/yy').format(currentDate!);
    row0 = [
      (producedQtyTotal.toStringAsFixed(2)),
      (getPercentage(producedQtyTotal, targetProductionQty).toStringAsFixed(2)),
      (producedQtyLastMonthTotal.toStringAsFixed(2)),
      (getPercentage(
        producedQtyLastMonthTotal,
        producedQtyTotal,
      ).toStringAsFixed(2)),
      (producedQtyLast3MonthTotal.toStringAsFixed(2)),
      (getPercentage(
        producedQtyLast3MonthTotal,
        producedQtyTotal,
      )).toStringAsFixed(2),
      (producedQtyFinYearTotal).toStringAsFixed(2),
      (getPercentage(
        producedQtyFinYearTotal,
        producedQtyTotal,
      ).toStringAsFixed(2)),
    ];
    row1 = [
      (producedQtyTotalBox.toStringAsFixed(2)),
      (getPercentage(
        producedQtyTotalBox,
        targetProductionQtyBox,
      ).toStringAsFixed(2)),
      (producedQtyLastMonthTotalBox.toStringAsFixed(2)),
      (getPercentage(
        producedQtyLastMonthTotalBox,
        targetProductionQtyBox,
      ).toStringAsFixed(2)),
      (producedQtyLast3MonthTotalBox.toStringAsFixed(2)),
      (getPercentage(
        producedQtyLast3MonthTotalBox,
        targetProductionQtyBox,
      )).toStringAsFixed(2),
      (producedQtyFinYearTotalBox).toStringAsFixed(2),
      (getPercentage(
        producedQtyFinYearTotalBox,
        targetProductionQtyBox,
      ).toStringAsFixed(2)),
    ];
    tableData = [
      row0,
      row1,
      [
        producedQty,
        '-29.60%',
        '780133',
        '1.20%',
        '904551',
        '-12.72%',
        '982228',
        '-19.62%',
      ],
      [boxesProduced, '', '12016', '-17.98%', '', '', '', ''],
      [totalWorkforce, '', '', '', '', '', '', ''],
    ];
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
                    const Row(children: [SizedBox(width: 5)]),
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
                          "Manpower Costing Report",
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
                                    // generateMonthlyProductionExcel(monthData);
                                    generateManpowerExcel(context);
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
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: BranchPicker(
                    production: production,
                    onChanged: (b) {
                      if (b != null) {
                        loadDataWithBranchFilter(b);
                      }
                    },
                    onClear: () {
                      loadDataClearFilter();
                    },
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text("Target vs Achievement"),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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
                                percent: producedQtyTotalPercentage / 100,
                                curve: Curves.linear,
                                circularStrokeCap: CircularStrokeCap.butt,
                                progressColor: const Color(0xFF2CA9DF),
                                arcBackgroundColor: const Color(0xFFB8ECFF),
                                center: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          producedQtyTotalPercentage
                                              .toStringAsFixed(2),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.0,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          producedQtyTotal.toStringAsFixed(2),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 10.0,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Produced Qty",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
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
                                percent: producedQtyBoxPercentage / 100,
                                curve: Curves.linear,
                                circularStrokeCap: CircularStrokeCap.butt,
                                progressColor: const Color(0xFF2CA9DF),
                                arcBackgroundColor: const Color(0xFFB8ECFF),
                                center: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          producedQtyBoxPercentage
                                              .toStringAsFixed(2),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.0,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          producedQtyTotalBox.toStringAsFixed(
                                            2,
                                          ),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 10.0,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(width: 5),
                                        Text(
                                          "No. of Boxes Produced",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
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
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFFFF9F47),
                        ),
                        const SizedBox(width: 5),
                        const Text("Target", style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFF97D7F3),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "Achievement",
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 15),
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
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ItemSubGroupDropdown(
                      production: production,
                      onChanged: (newValue) {
                        loadDataWithItemSubGroupFilter(newValue!);
                      },
                    ),
                    const SizedBox(width: 5),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF97D7F3),
                            border: Border.all(color: Colors.transparent),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Kits/Gowns Produced\nQuantity:'
                                  ' ${formatAmount(monthData.monthlyData.last.production)}',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF97D7F3),
                            border: Border.all(color: Colors.transparent),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Kits/Gowns Produced\nBox Quantity:'
                                  ' ${formatAmount(monthData.monthlyData.last.boxNo!.toDouble())}',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _monthlyProductionLineGraph(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF97D7F3),
                            border: Border.all(color: Colors.transparent),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Average Boxes\nper Month:'
                                  ' ${formatAmount(currentMonthAverageBoxes)}',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF97D7F3),
                            border: Border.all(color: Colors.transparent),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Boxes Produced\nper Month:'
                                  ' ${formatAmount(currentMonthDailyData.last.boxNo.toDouble())}',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _dailyProductionAnalysis(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ItemSubGroupDropdown(
                      production: production,
                      onChanged: (newValue) {
                        loadDataWithItemSubGroupDailyFilter(newValue!);
                      },
                    ),
                    const SizedBox(width: 5),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF97D7F3),
                            border: Border.all(color: Colors.transparent),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Average Boxes(Kits/Gowns)\nper Month:'
                                  ' ${formatAmount(currentMonthAverageBoxes)}',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF97D7F3),
                            border: Border.all(color: Colors.transparent),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Boxes Produced(Kits/Gowns)\nper Month:'
                                  ' ${formatAmount(currentMonthDailyData.last.boxNo.toDouble())}',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _dailyProductionLineGraph(),
                ),

                ProductionDataTable(particulars: particulars, data: tableData),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
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

  Widget _dailyProductionAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = currentMonthDailyData.length;
    if (currentMonthDailyData.length > 5) {
      chartWidth = screenWidth + (40 * len);
    } else {
      chartWidth = screenWidth;
    }
    // int len = currentMonthDailyData.length;
    // double maxPurchaseAmount = len > 0
    //     ? currentMonthDailyData.
    //     .map((data) =>
    // data.production > data.target ? data.production : data.target)
    //     .reduce((a, b) => a > b ? a : b)
    //     : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            // maxY: getMaxValue(maxPurchaseAmount),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesPayables,
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
            barGroups: _monthWiseProductionAnalysisDailyChartData(
              currentMonthDailyData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {});
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
                    '${currentMonthDailyData[grpIndex].dayLabel}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Avg Box : ${formatAmount(currentMonthAverageBoxes)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Actual Boxes : ${formatAmount(currentMonthDailyData[grpIndex].boxNo.toDouble())}\n",
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

  Widget _monthlyProductionLineGraph() {
    final screenWidth = MediaQuery.of(context).size.width;

    final dataList = monthLineData.monthlyData;
    final int len = dataList.length;

    if (len == 0) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    double chartWidth;
    if (len > 5) {
      chartWidth = screenWidth + (40 * len);
    } else {
      chartWidth = screenWidth;
    }

    final List<FlSpot> productionSpots = [];
    final List<FlSpot> boxNoSpots = [];

    for (int i = 0; i < len; i++) {
      final item = dataList[i];
      final x = i.toDouble();

      final double prod = (item.production).toDouble();
      final double boxes = (item.boxNo ?? 0).toDouble();

      productionSpots.add(FlSpot(x, prod));
      boxNoSpots.add(FlSpot(x, boxes));
    }

    double? minY;
    double? maxY;
    void consider(double v) {
      if (v.isNaN) return;
      if (minY == null || v < minY!) minY = v;
      if (maxY == null || v > maxY!) maxY = v;
    }

    for (final s in productionSpots) {
      consider(s.y);
    }
    for (final s in boxNoSpots) {
      consider(s.y);
    }

    double computedMaxY;
    if (minY == null || maxY == null) {
      computedMaxY = 1;
    } else if (minY == maxY) {
      computedMaxY = maxY! + (maxY!.abs() * 0.2) + 1;
    } else {
      final range = maxY! - minY!;
      computedMaxY = maxY! + range * 0.1;
    }

    // colors and lines (order matters -> barIndex 0 = production, 1 = boxNo)
    const productionColor = Colors.orange;
    const boxColor = Colors.blue;

    final List<LineChartBarData> lines = [
      LineChartBarData(
        spots: productionSpots,
        isCurved: true,
        color: productionColor,
        barWidth: 3,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: 4,
            color: productionColor,
            strokeWidth: 1.5,
            strokeColor: Colors.white,
          ),
        ),
        isStrokeCapRound: true,
      ),
      LineChartBarData(
        spots: boxNoSpots,
        isCurved: true,
        color: boxColor,
        barWidth: 3,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: 4,
            color: boxColor,
            strokeWidth: 1.5,
            strokeColor: Colors.white,
          ),
        ),
        isStrokeCapRound: true,
      ),
    ];

    Widget bottomTitleWidgets(double value, TitleMeta meta) {
      final int i = value.toInt();
      if (i < 0 || i >= len) return const Text('');
      final name = dataList[i].monthName;
      return SideTitleWidget(
        meta: meta,
        child: SizedBox(
          width: 60,
          child: Text(
            name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );
    }

    Widget legend = Row(
      children: [
        _legendItem(productionColor, 'Production'),
        const SizedBox(width: 8),
        _legendItem(boxColor, 'BoxNo'),
      ],
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 400,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              legend,
              const SizedBox(height: 15),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (len - 1).toDouble(),
                    minY: 0,
                    maxY: computedMaxY,
                    lineTouchData: LineTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (group) => Colors.black87,
                        tooltipBorderRadius: BorderRadius.circular(8),
                        tooltipPadding: const EdgeInsets.all(8),
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          if (touchedSpots.isEmpty) return [];

                          final int xIndex = touchedSpots.first.x.toInt();
                          // sanity check
                          if (xIndex < 0 || xIndex >= dataList.length) {
                            // still return an entry per touched spot (empty text)
                            return List.generate(
                              touchedSpots.length,
                              (_) => const LineTooltipItem('', TextStyle()),
                            );
                          }

                          final item = dataList[xIndex];

                          const prodStyle = TextStyle(
                            color: productionColor,
                            fontSize: 12,
                          );
                          const boxStyle = TextStyle(
                            color: boxColor,
                            fontSize: 12,
                          );
                          const fallbackStyle = TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          );

                          final List<LineTooltipItem> items = [];

                          for (int i = 0; i < touchedSpots.length; i++) {
                            final spot = touchedSpots[i];
                            final barIndex = spot.barIndex;

                            // Compose header only on first tooltip item
                            final header = i == 0 ? '${item.monthName}\n' : '';

                            String seriesText;
                            TextStyle style;

                            if (barIndex == 0) {
                              // production line
                              seriesText =
                                  'Production: ${(formatAmount(item.production))}';
                              style = prodStyle;
                            } else if (barIndex == 1) {
                              double? boxNo = item.boxNo?.toDouble();
                              // boxNo line
                              seriesText = 'BoxNo: ${(formatAmount(boxNo!))}';
                              style = boxStyle;
                            } else {
                              // unexpected barIndex — produce safe placeholder
                              seriesText = '';
                              style = fallbackStyle;
                            }

                            final text = '$header$seriesText';
                            items.add(LineTooltipItem(text, style));
                          }

                          return items;
                        },
                      ),
                      getTouchedSpotIndicator:
                          (LineChartBarData barData, List<int> indicators) {
                            return indicators.map((index) {
                              return TouchedSpotIndicatorData(
                                const FlLine(
                                  color: Colors.black26,
                                  strokeWidth: 1.5,
                                ),
                                FlDotData(
                                  getDotPainter: (spot, percent, bar, idx) {
                                    final Color dotColor =
                                        barData.color ?? Colors.blue;
                                    return FlDotCirclePainter(
                                      radius: 6,
                                      color: dotColor,
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    );
                                  },
                                ),
                              );
                            }).toList();
                          },
                      touchCallback: (event, response) {},
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 1,
                          getTitlesWidget: bottomTitleWidgets,
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.black12),
                    ),
                    lineBarsData: lines,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dailyProductionLineGraph() {
    final screenWidth = MediaQuery.of(context).size.width;

    final dataList = currentMonthDailyLineData;
    final int len = dataList.length;

    if (len == 0) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    double chartWidth;
    if (len > 5) {
      chartWidth = screenWidth + (40 * len);
    } else {
      chartWidth = screenWidth;
    }

    final List<FlSpot> productionSpots = [];
    final List<FlSpot> boxNoSpots = [];

    for (int i = 0; i < len; i++) {
      final item = dataList[i];
      final x = i.toDouble();

      final double prod = (item.production).toDouble();
      final double boxes = (item.boxNo).toDouble();

      productionSpots.add(FlSpot(x, prod));
      boxNoSpots.add(FlSpot(x, boxes));
    }

    double? minY;
    double? maxY;
    void consider(double v) {
      if (v.isNaN) return;
      if (minY == null || v < minY!) minY = v;
      if (maxY == null || v > maxY!) maxY = v;
    }

    for (final s in productionSpots) {
      consider(s.y);
    }
    for (final s in boxNoSpots) {
      consider(s.y);
    }

    double computedMaxY;
    if (minY == null || maxY == null) {
      computedMaxY = 1;
    } else if (minY == maxY) {
      computedMaxY = maxY! + (maxY!.abs() * 0.2) + 1;
    } else {
      final range = maxY! - minY!;
      computedMaxY = maxY! + range * 0.1;
    }

    // colors and lines (order matters -> barIndex 0 = production, 1 = boxNo)
    const productionColor = Colors.orange;
    const boxColor = Colors.blue;

    final List<LineChartBarData> lines = [
      LineChartBarData(
        spots: productionSpots,
        isCurved: true,
        color: productionColor,
        barWidth: 3,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: 4,
            color: productionColor,
            strokeWidth: 1.5,
            strokeColor: Colors.white,
          ),
        ),
        isStrokeCapRound: true,
      ),
      LineChartBarData(
        spots: boxNoSpots,
        isCurved: true,
        color: boxColor,
        barWidth: 3,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: 4,
            color: boxColor,
            strokeWidth: 1.5,
            strokeColor: Colors.white,
          ),
        ),
        isStrokeCapRound: true,
      ),
    ];

    Widget bottomTitleWidgets(double value, TitleMeta meta) {
      final int i = value.toInt();
      if (i < 0 || i >= len) return const Text('');
      final name = dataList[i].dayLabel;
      return SideTitleWidget(
        meta: meta,
        child: SizedBox(
          width: 60,
          child: Text(
            name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );
    }

    Widget legend = Row(
      children: [
        _legendItem(productionColor, 'Production'),
        const SizedBox(width: 8),
        _legendItem(boxColor, 'BoxNo'),
      ],
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 400,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              legend,
              const SizedBox(height: 15),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (len - 1).toDouble(),
                    minY: 0,
                    maxY: computedMaxY,
                    lineTouchData: LineTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (group) => Colors.black87,
                        tooltipBorderRadius: BorderRadius.circular(8),
                        tooltipPadding: const EdgeInsets.all(8),
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          if (touchedSpots.isEmpty) return [];

                          final int xIndex = touchedSpots.first.x.toInt();
                          // sanity check
                          if (xIndex < 0 || xIndex >= dataList.length) {
                            // still return an entry per touched spot (empty text)
                            return List.generate(
                              touchedSpots.length,
                              (_) => const LineTooltipItem('', TextStyle()),
                            );
                          }

                          final item = dataList[xIndex];

                          const prodStyle = TextStyle(
                            color: productionColor,
                            fontSize: 12,
                          );
                          const boxStyle = TextStyle(
                            color: boxColor,
                            fontSize: 12,
                          );
                          const fallbackStyle = TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          );

                          final List<LineTooltipItem> items = [];

                          for (int i = 0; i < touchedSpots.length; i++) {
                            final spot = touchedSpots[i];
                            final barIndex = spot.barIndex;

                            // Compose header only on first tooltip item
                            final header = i == 0 ? '${item.dayLabel}\n' : '';

                            String seriesText;
                            TextStyle style;

                            if (barIndex == 0) {
                              // production line
                              seriesText =
                                  'Production: ${(formatAmount(item.production))}';
                              style = prodStyle;
                            } else if (barIndex == 1) {
                              double? boxNo = item.boxNo.toDouble();
                              // boxNo line
                              seriesText = 'BoxNo: ${(formatAmount(boxNo))}';
                              style = boxStyle;
                            } else {
                              // unexpected barIndex — produce safe placeholder
                              seriesText = '';
                              style = fallbackStyle;
                            }

                            final text = '$header$seriesText';
                            items.add(LineTooltipItem(text, style));
                          }

                          return items;
                        },
                      ),
                      getTouchedSpotIndicator:
                          (LineChartBarData barData, List<int> indicators) {
                            return indicators.map((index) {
                              return TouchedSpotIndicatorData(
                                const FlLine(
                                  color: Colors.black26,
                                  strokeWidth: 1.5,
                                ),
                                FlDotData(
                                  getDotPainter: (spot, percent, bar, idx) {
                                    final Color dotColor =
                                        barData.color ?? Colors.blue;
                                    return FlDotCirclePainter(
                                      radius: 6,
                                      color: dotColor,
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    );
                                  },
                                ),
                              );
                            }).toList();
                          },
                      touchCallback: (event, response) {},
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 1,
                          getTitlesWidget: bottomTitleWidgets,
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.black12),
                    ),
                    lineBarsData: lines,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Color c, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: c),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class BranchPicker extends StatefulWidget {
  final List<ProductionOrderList> production;
  final ValueChanged<String?>? onChanged;
  final VoidCallback? onClear; // called when the cross is pressed
  final VoidCallback? onSearchPressed; // optional override for search button
  final String title;

  const BranchPicker({
    Key? key,
    required this.production,
    this.onChanged,
    this.onClear,
    this.onSearchPressed,
    this.title = 'Manpower Costing Report',
  }) : super(key: key);

  @override
  State<BranchPicker> createState() => _BranchPickerState();
}

class _BranchPickerState extends State<BranchPicker> {
  late final List<String> _branches;
  String? _selectedBranch;

  @override
  void initState() {
    super.initState();
    _branches = _extractBranches(widget.production);
    _selectedBranch = null; // show "Select Branch" hint initially
  }

  List<String> _extractBranches(List<ProductionOrderList> list) {
    final s = list
        .map((p) => (p.branch).toString())
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList();
    s.sort((a, b) => a.compareTo(b));
    return s;
  }

  // Default search behavior: open a simple dialog to pick branch
  Future<void> _defaultOpenSearchDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        String filter = '';
        return StatefulBuilder(
          builder: (c, setStateDialog) {
            final filtered = _branches
                .where((b) => b.toLowerCase().contains(filter.toLowerCase()))
                .toList();
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: 320,
                height: 420,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search branches',
                          isDense: true,
                        ),
                        onChanged: (v) => setStateDialog(() => filter = v),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No branches found'))
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final b = filtered[i];
                                return ListTile(
                                  title: Text(b),
                                  onTap: () => Navigator.of(context).pop(b),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _selectedBranch = result);
      widget.onChanged?.call(result);
    }
  }

  void _onSearchPressed() {
    if (widget.onSearchPressed != null) {
      widget.onSearchPressed!();
    } else {
      _defaultOpenSearchDialog();
    }
  }

  void _onClearPressed() {
    setState(() => _selectedBranch = null);
    // call both onChanged (with null) and onClear if provided
    widget.onChanged?.call(null);
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(6.0);
    final borderSide = BorderSide(color: Colors.grey.shade300, width: 1.0);

    // Build the circular icon widget (search or clear) shown inside the field
    Widget _buildCircularAction() {
      final bool hasSelection = _selectedBranch != null;
      final icon = hasSelection ? Icons.close : Icons.search;
      final onPressed = hasSelection ? _onClearPressed : _onSearchPressed;
      final iconColor = hasSelection ? Colors.black54 : Colors.blueAccent;
      final borderColor = hasSelection
          ? Colors.grey.shade300
          : Colors.blueAccent;

      return Container(
        margin: const EdgeInsets.only(right: 8),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          splashRadius: 18,
          icon: Icon(icon, size: 18, color: iconColor),
          onPressed: _branches.isEmpty ? null : onPressed,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Wrap field and circular icon in a row so the icon appears inside-right visually.
        // We use Expanded for the Dropdown so it fills available space.
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedBranch,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                decoration: InputDecoration(
                  hintText: null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(borderRadius: borderRadius),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: borderSide,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  // Put a small right padding to avoid overlap with our manual circular icon
                  // (suffixIcon could be used but this approach gives consistent circular look)
                ),
                hint: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Branch',
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ),
                items: _branches
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedBranch = val);
                  widget.onChanged?.call(val);
                },
              ),
            ),

            // small spacing between field and circular icon
            const SizedBox(width: 8),

            // the circular search/clear icon
            _buildCircularAction(),
          ],
        ),
      ],
    );
  }
}

class ItemSubGroupDropdown extends StatefulWidget {
  final List production; // List<ProductionOrderList> or List<Map>
  final ValueChanged<String?> onChanged;
  final String placeholder; // shown when no items available

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

  // These are the subgroups that should be shown as "Kits/Gowns"
  static const _grouped = {'packs', 'gowns', 'safety packs', 'drapes'};

  @override
  void initState() {
    super.initState();
    _items = _extractItemSubGroups(widget.production);
    _selected = _items.isNotEmpty ? _items.first : null;
  }

  String _displayNameFor(String raw) {
    final low = raw.trim().toLowerCase();
    if (_grouped.contains(low)) return 'Kits/Gowns';
    return raw.trim();
  }

  List<String> _extractItemSubGroups(List list) {
    final seen = <String>{};
    final out = <String>[];
    for (var e in list) {
      String val = '';
      try {
        val = (e.itemSubGroup ?? '').toString().trim();
      } catch (_) {
        if (e is Map && e.containsKey('itemSubGroup')) {
          val = (e['itemSubGroup'] ?? '').toString().trim();
        }
      }
      if (val.isEmpty) continue;

      final display = _displayNameFor(val);
      // Use display value for uniqueness so grouped items collapse into one entry.
      if (!seen.contains(display)) {
        seen.add(display);
        out.add(display);
      }
    }

    // If nothing found, optionally return the placeholder as a single disabled item
    if (out.isEmpty) {
      out.add(widget.placeholder);
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

class ProductionDataTable extends StatefulWidget {
  // Left column labels (Particulars)
  final List<String> particulars;

  // Data rows: each inner list must contain values for the remaining columns
  // (Total, Increase/Decrease..., Dec-24 Total, Dec-24 %..., Last 3 months Total, Last 3 months %..., Last 12 Months Total, Last 12 Months %...)
  // If an inner list is shorter we'll show empty cells for missing columns.
  final List<List<String>> data;

  const ProductionDataTable({
    super.key,
    required this.particulars,
    required this.data,
  }) : assert(
         particulars.length >= data.length,
         'particulars should be at least as many as data rows',
       );

  @override
  State<ProductionDataTable> createState() => _ProductionDataTableState();
}

class _ProductionDataTableState extends State<ProductionDataTable> {
  // Fixed headers matching the screenshot (first is Particulars)
  List<String> headers = [
    'Particulars',
    'Total',
    'Increase/Decrease with Target',
    '${getMonthName(DateTime.now().month)} ${DateTime.now().year}\nTotal',
    '${getMonthName(DateTime.now().month)} ${DateTime.now().year}\n% w.r.t Current Month',
    'Last 3 months\nTotal',
    'Last 3 months\n% w.r.t Current Month',
    'Last 12 Months\nTotal',
    'Last 12 Months\n% w.r.t Current Month',
  ];

  @override
  Widget build(BuildContext context) {
    final int editableCols = headers.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top yellow title bar
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          color: Colors.yellow[700],
          child: const Text(
            'Working for the Month of January 2025',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),

        // Table with horizontal scroll
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width,
            ),
            child: SingleChildScrollView(
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                columnWidths: {
                  0: const FixedColumnWidth(260),
                  for (int i = 1; i < headers.length; i++)
                    i: const FixedColumnWidth(140),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  // Header row
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey[200]),
                    children: headers
                        .map(
                          (h) => Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            child: Text(
                              h,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  // Data rows
                  for (int r = 0; r < widget.particulars.length; r++)
                    TableRow(
                      children: [
                        // Particulars left cell
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          child: Text(widget.particulars[r]),
                        ),

                        // For each editable column show the corresponding value or empty
                        for (int c = 0; c < editableCols; c++)
                          Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            alignment: Alignment.centerRight,
                            child: Text(
                              // try to get data[r][c] if present, else empty string
                              (r < widget.data.length &&
                                      c < widget.data[r].length)
                                  ? (widget.data[r][c])
                                  : '',
                              textAlign: TextAlign.right,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
