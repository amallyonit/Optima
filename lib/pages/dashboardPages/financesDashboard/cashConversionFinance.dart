// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference

import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:http/http.dart' as http;
import 'package:optima/classes/leads.dart';
import '../ReportService.dart';

final reportService = ReportService();
late Future<void> loadDataFuture;

List<Users> usersList = [];
String userLevel = "0";
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

List<DebtorsAgingList> target = [];
List<SalesList> sales = [];
List<CollectionList> collection = [];
List<PaymentAnalysisList> payables = [];
List<GRNList> purchasePrice = [];
List<InventoryList> inventory = [];
List<InventoryList> inventoryClosing = [];
List<ModeOfPaymentList> modeOfPayment = [];
List<MonthlyInventoryData> monthWiseInventory = [];

CashConversionGraphList monthlyAnalysisData = CashConversionGraphList(
  monthData: [],
);

DSOGraphList graphData = DSOGraphList(monthData: []);
DailyAnalysisExpensesList purchaseMonthlyData = DailyAnalysisExpensesList(
  dailyData: [],
);
List<MonthlyCogsData> monthlyCogsList = [];

bool chartDataLoadedCCC = false;
double selectedChart = 0;
int touchedMonthIndex = 0;
String touchedMonth = "";

bool showDrillDownChart = true;

Map<String, Map<String, bool>> allCategoriesState = {};

final List<String> categories = ['Date'];

List<List<String>> filterOptions = [[]];

List<String> selectedSalesData = [];

DateTime? fromDateFilter;
DateTime? toDateFilter;
bool dateFilterFlag = false;

List<List<bool>> selectedFinanceReceivablesOptions = [];

List<List<bool>> savedFinanceReceivablesOptions = filterOptions
    .map((options) => List<bool>.filled(options.length, false))
    .toList();

class CashConversionFinance extends StatefulWidget {
  const CashConversionFinance({super.key});

  @override
  State<CashConversionFinance> createState() => _CashConversionFinanceState();
}

class CashConversionReceivablesProvider with ChangeNotifier {
  List<DebtorsAgingList> _targetList = [];
  List<DebtorsAgingList> get targetList => _targetList;
  void updateTargetList(List<DebtorsAgingList> newTargetList) {
    _targetList = newTargetList;
    notifyListeners();
  }
}

class CashConversionSalesProvider with ChangeNotifier {
  List<SalesList> _salesList = [];
  List<SalesList> get salesList => _salesList;
  void updateSalesList(List<SalesList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class CashConversionActualPayableProvider with ChangeNotifier {
  List<ModeOfPaymentList> _targetList = [];
  List<ModeOfPaymentList> get targetList => _targetList;
  void updateTargetList(List<ModeOfPaymentList> newTargetList) {
    _targetList = newTargetList;
    notifyListeners();
  }
}

class CashConversionCollectionProvider with ChangeNotifier {
  List<CollectionList> _collectionList = [];
  List<CollectionList> get collectionList => _collectionList;
  void updateCollectionList(List<CollectionList> newCollectionList) {
    _collectionList = newCollectionList;
    notifyListeners();
  }
}

class CashConversionPayableProvider with ChangeNotifier {
  List<PaymentAnalysisList> _salesList = [];
  List<PaymentAnalysisList> get salesList => _salesList;
  void updatePOList(List<PaymentAnalysisList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class PurchaseCashConversionProvider with ChangeNotifier {
  List<PurchaseList> _purchaseList = [];
  List<PurchaseList> get purchaseList => _purchaseList;
  void updatePurchaseList(List<PurchaseList> newList) {
    _purchaseList = newList;
    notifyListeners();
  }
}

class InventoryCashConversionProvider with ChangeNotifier {
  List<InventoryList> _inventoryList = [];
  List<InventoryList> get inventoryList => _inventoryList;
  void updateInventoryList(List<InventoryList> newList) {
    _inventoryList = newList;
    notifyListeners();
  }
}

class GRNCashConversionProvider with ChangeNotifier {
  List<GRNList> _purchaseList = [];
  List<GRNList> get purchaseList => _purchaseList;
  void updatePurchaseList(List<GRNList> newList) {
    _purchaseList = newList;
    notifyListeners();
  }
}

class InventoryClosingCashConversionProvider with ChangeNotifier {
  List<InventoryList> _inventoryList = [];
  List<InventoryList> get inventoryList => _inventoryList;
  void updateInventoryList(List<InventoryList> newList) {
    _inventoryList = newList;
    notifyListeners();
  }
}

class _CashConversionFinanceState extends State<CashConversionFinance> {
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
        break;
      case 2:
        currentQuarterFromDate = DateTime(now.year, 7, 1);
        currentQuarterToDate = DateTime(now.year, 9, 30);
        break;
      case 3:
        currentQuarterFromDate = DateTime(now.year, 10, 1);
        currentQuarterToDate = DateTime(now.year, 12, 31);
        break;
      case 4:
        currentQuarterFromDate = DateTime(now.year, 1, 1);
        currentQuarterToDate = DateTime(now.year, 3, 31);
        break;
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

  String getMonthName(int month) {
    final formatter = DateFormat('MMMM');
    return formatter.format(DateTime(2000, month));
  }

  Map<String, DateTime> getMonthStartEndDatesOld(int month) {
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

  Map<String, DateTime> getMonthStartEndDates(int month) {
    DateTime now = DateTime.now();

    int currentYear = now.year;

    /// Normalize 13,14,15 => 1,2,3
    int actualMonth = month > 12 ? month - 12 : month;

    int yearForMonth;

    if (now.month >= 1 && now.month <= 3) {
      yearForMonth = (actualMonth >= 4 && actualMonth <= 12)
          ? currentYear - 1
          : currentYear;
    } else {
      yearForMonth = (actualMonth >= 4 && actualMonth <= 12)
          ? currentYear
          : currentYear + 1;
    }

    DateTime firstDayOfMonth = DateTime(yearForMonth, actualMonth, 1);

    DateTime lastDayOfMonth = DateTime(yearForMonth, actualMonth + 1, 0);

    return {'start': firstDayOfMonth, 'end': lastDayOfMonth};
  }

  SideTitles get _leftTitles => SideTitles(
    reservedSize: 50,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String leftDouble = "";
      leftDouble = value.toStringAsFixed(0);
      return Text(leftDouble, style: const TextStyle(fontSize: 12));
    },
  );

  SideTitles get _emptyTitlesTop =>
      SideTitles(showTitles: true, getTitlesWidget: getEmptyTopTitle);

  Widget getEmptyTopTitle(double val, TitleMeta meta) {
    return const Text("");
  }

  SideTitles get _bottomTitlesMonthlyAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<CashConversionGraphData> mData = monthlyAnalysisData.monthData;
      text = mData.elementAt(value.toInt()).monthName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesCCC => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<DSOGraphData> mData = graphData.monthData;
      text = mData.elementAt(value.toInt()).name;
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

  double getCompletedDaysInMonth(int year, int monthNumber) {
    DateTime now = DateTime.now();
    bool isCurrentMonth = (now.year == year && now.month == monthNumber);

    if (isCurrentMonth) {
      // Return the number of completed days in current month (excluding today if needed)
      return now.day
          .toDouble(); // or (now.day - 1).toDouble() if you mean "completed" as excluding today
    } else {
      // Return the full number of days in the given month
      return DateTime(year, monthNumber + 1, 0).day.toDouble();
    }
  }

  List<BarChartGroupData> _monthlyAnalysisChartData(
    List<CashConversionGraphData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.dsoDaysSales,
                width: 15,
              ),
              BarChartRodData(
                color: const Color(0xFF2CA9DF),
                borderRadius: BorderRadius.zero,
                toY: chartData.dsoDaysNH,
                width: 15,
              ),
              BarChartRodData(
                color: const Color(0xFF78E25D),
                borderRadius: BorderRadius.zero,
                toY: chartData.dsoDaysOffice,
                width: 15,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _CCCChartData(List<DSOGraphData> data) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.target,
                width: 15,
              ),
              BarChartRodData(
                color: const Color(0xFF2CA9DF),
                borderRadius: BorderRadius.zero,
                toY: chartData.achievement,
                width: 15,
              ),
            ],
          ),
        )
        .toList();
  }

  Future<void> _loadCollectionTarget(String UserName, String UserLevel) async {
    int index = 0;
    const int limit = 10000;
    List<DebtorsAgingList> targetList = [];

    try {
      while (true) {
        final body = {
          "FromDate": dateFilterFlag
              ? formatDate(fromDateFilter!)
              : formatDate(fiscalYearStartDate!),
          "ToDate": dateFilterFlag
              ? formatDate(toDateFilter!)
              : formatDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        const apiUrl = '${ApiHelper.baseUrl}Bicxo_DebtorsAgingList';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode != 200) break;

        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        final data = responseJson['responseData'] as List?;

        if (data == null || data.isEmpty) break;

        final newList = data
            .map((item) => DebtorsAgingList.fromJson(item))
            .toList();

        targetList.addAll(newList);

        if (newList.length < limit) break;

        index++;
      }

      if (!mounted) return;

      setState(() {
        context.read<CashConversionReceivablesProvider>().updateTargetList(
          targetList,
        );

        target = targetList;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Error: $e'),
        ),
      );
    }
  }

  Future<void> _loadSales(String UserName, String UserLevel) async {
    int index = 0;
    const int limit = 10000;

    List<SalesList> salesList = [];

    try {
      final fromDate = dateFilterFlag
          ? formatDate(fromDateFilter!)
          : formatDate(fiscalYearStartDate!);

      final toDate = dateFilterFlag
          ? formatDate(toDateFilter!)
          : formatDate(currentDate!);

      while (true) {
        final body = {
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        const apiUrl = '${ApiHelper.baseUrl}Crm_SalesList';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode != 200) break;

        final responseJson = jsonDecode(response.body);
        final data = responseJson['responseData'] as List?;

        if (data == null || data.isEmpty) break;

        final newList = data.map((item) => SalesList.fromJson(item)).toList();

        salesList.addAll(newList);

        if (newList.length < limit) break;

        index++;
      }

      if (!mounted) return;

      setState(() {
        context.read<CashConversionSalesProvider>().updateSalesList(salesList);

        sales = salesList;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Error: $e'),
        ),
      );
    }
  }

  Future<void> _loadCollection(String UserName, String UserLevel) async {
    int index = 0;
    const int limit = 10000;

    List<CollectionList> collectionList = [];

    try {
      // final fromDate = dateFilterFlag
      //     ? formatDate(fromDateFilter!)
      //     : formatDate(fiscalYearStartDate!);
      final DateTime fromDate = dateFilterFlag
          ? fromDateFilter!
          : fiscalYearStartDate!;
      final prevDate = DateTime(fromDate.year, fromDate.month - 1, 1);

      final prevStart = DateTime(prevDate.year, prevDate.month, 1);

      final toDate = dateFilterFlag
          ? formatDate(toDateFilter!)
          : formatDate(currentDate!);

      while (true) {
        final body = {
          "FromDate": formatDate(prevStart),
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        const apiUrl = '${ApiHelper.baseUrl}CRMCollectionAnalysisList';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode != 200) break;

        final responseJson = jsonDecode(response.body);
        final data = responseJson['responseData'] as List?;

        if (data == null || data.isEmpty) break;

        final newList = data
            .map((item) => CollectionList.fromJson(item))
            .toList();

        collectionList.addAll(newList);

        if (newList.length < limit) break;

        index++;
      }

      if (!mounted) return;

      setState(() {
        context.read<CashConversionCollectionProvider>().updateCollectionList(
          collectionList,
        );

        collection = collectionList;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Error: $e'),
        ),
      );
    }
  }

  Future<void> _loadPayables(String UserName, String UserLevel) async {
    int index = 0;
    const int limit = 10000;

    List<PaymentAnalysisList> payablesList = [];

    try {
      final fromDate = dateFilterFlag
          ? formatDate(fromDateFilter!)
          : formatDate(fiscalYearStartDate!);

      final toDate = dateFilterFlag
          ? formatDate(toDateFilter!)
          : formatDate(currentDate!);

      while (true) {
        final body = {
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        const apiUrl = '${ApiHelper.baseUrl}BicxoCreditorsAgingList';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode != 200) break;

        final responseJson = jsonDecode(response.body);
        final data = responseJson['responseData'] as List?;

        if (data == null || data.isEmpty) break;

        final newList = data
            .map((item) => PaymentAnalysisList.fromJson(item))
            .toList();

        payablesList.addAll(newList);

        if (newList.length < limit) break;

        index++;
      }

      if (!mounted) return;

      setState(() {
        context.read<CashConversionPayableProvider>().updatePOList(
          payablesList,
        );

        payables = payablesList;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Error: $e'),
        ),
      );
    }
  }

  Future<void> _loadModeOfPayment(String UserName, String UserLevel) async {
    int index = 0;
    const int limit = 10000;

    List<ModeOfPaymentList> modeOfPaymentList = [];

    try {
      final fromDate = dateFilterFlag
          ? formatDate(fromDateFilter!)
          : formatDate(fiscalYearStartDate!);

      final toDate = dateFilterFlag
          ? formatDate(toDateFilter!)
          : formatDate(currentDate!);

      while (true) {
        final body = {
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        const apiUrl = '${ApiHelper.baseUrl}BicxoPaymentAnalysisList';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode != 200) break;

        final responseJson = jsonDecode(response.body);
        final data = responseJson['responseData'] as List?;

        if (data == null || data.isEmpty) break;

        final newList = data
            .map((item) => ModeOfPaymentList.fromJson(item))
            .where((e) => e.vendorGroup.isNotEmpty)
            .toList();

        modeOfPaymentList.addAll(newList);

        if (newList.length < limit) break;

        index++;
      }

      if (!mounted) return;

      setState(() {
        context.read<CashConversionActualPayableProvider>().updateTargetList(
          modeOfPaymentList,
        );

        modeOfPayment = modeOfPaymentList;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Error: $e'),
        ),
      );
    }
  }

  Future<void> _loadInventory(String UserName, String UserLevel) async {
    int index = 0;
    const int limit = 10000;

    List<InventoryList> inventoryList = [];

    try {
      final fromDate = dateFilterFlag
          ? formatDate(fromDateFilter!)
          : formatDate(fiscalYearStartDate!);

      final toDate = dateFilterFlag
          ? formatDate(toDateFilter!)
          : formatDate(currentDate!);

      while (true) {
        final body = {
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        const apiUrl = '${ApiHelper.baseUrl}BicxoInventoryAgeingList';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode != 200) break;

        final responseJson = jsonDecode(response.body);
        final data = responseJson['responseData'] as List?;

        if (data == null || data.isEmpty) break;

        final newList = data
            .map((item) => InventoryList.fromJson(item))
            .toList();

        inventoryList.addAll(newList);

        if (newList.length < limit) break;

        index++;
      }

      if (!mounted) return;

      setState(() {
        context.read<InventoryCashConversionProvider>().updateInventoryList(
          inventoryList,
        );

        inventory = inventoryList;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Error: $e'),
        ),
      );
    }
  }

  Future<void> _loadInventoryClosing(String UserName, String UserLevel) async {
    int index = 0;
    const int limit = 10000;

    List<InventoryList> inventoryList = [];

    try {
      final fromDate = dateFilterFlag
          ? formatDate(fromDateFilter!)
          : formatDate(fiscalYearStartDate!);

      final toDate = dateFilterFlag
          ? formatDate(toDateFilter!)
          : formatDate(currentDate!);

      while (true) {
        final body = {
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        const apiUrl = '${ApiHelper.baseUrl}BicxoInventoryAgeingList';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode != 200) break;

        final responseJson = jsonDecode(response.body);
        final data = responseJson['responseData'] as List?;

        if (data == null || data.isEmpty) break;

        final newList = data
            .map((item) => InventoryList.fromJson(item))
            .toList();

        inventoryList.addAll(newList);

        if (newList.length < limit) break;

        index++;
      }

      if (!mounted) return;

      setState(() {
        context
            .read<InventoryClosingCashConversionProvider>()
            .updateInventoryList(inventoryList);

        inventoryClosing = inventoryList;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Error: $e'),
        ),
      );
    }
  }

  Future<void> _loadGRN(String UserName, String UserLevel) async {
    int index = 0;
    const int limit = 10000;

    List<GRNList> grnList = [];

    try {
      final fromDate = dateFilterFlag
          ? formatDate(fromDateFilter!)
          : formatDate(fiscalYearStartDate!);

      final toDate = dateFilterFlag
          ? formatDate(toDateFilter!)
          : formatDate(currentDate!);

      int retryCount = 0;
      const maxRetry = 2;

      while (true) {
        final body = {
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        const apiUrl = '${ApiHelper.baseUrl}BicxoGoodsReceiptNoteList';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 504 && retryCount < maxRetry) {
          retryCount++;
          await Future.delayed(const Duration(seconds: 1));
          continue; // retry same page
        }

        if (response.statusCode != 200) break;

        retryCount = 0;

        final responseJson = jsonDecode(response.body);
        final data = responseJson['responseData'] as List?;

        if (data == null || data.isEmpty) break;

        final newList = data.map((item) => GRNList.fromJson(item)).toList();

        grnList.addAll(newList);

        if (newList.length < limit) break;

        index++;
      }

      if (!mounted) return;

      setState(() {
        context.read<GRNCashConversionProvider>().updatePurchaseList(grnList);

        purchasePrice = grnList;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Error: $e'),
        ),
      );
    }
  }

  int _lastDayOfMonth(int year, int month) {
    final nextMonth = (month < 12)
        ? DateTime(year, month + 1, 1)
        : DateTime(year + 1, 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  Future<List<InventoryList>> _fetchInventoryForDate(DateTime toDate) async {
    int index = 0;
    const int limit = 10000;

    List<InventoryList> allItems = [];

    final formattedToDate = DateFormat('yyyyMMdd').format(toDate);

    int retryCount = 0;
    const maxRetry = 2;

    while (true) {
      final body = {
        "ToDate": formattedToDate,
        "Index": index.toString(),
        "Limit": limit.toString(),
        "sapToken": DataManager.readSapToken(),
      };

      const apiUrl = '${ApiHelper.baseUrl}BicxoInventoryAgeingList';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode(body),
      );

      // 🔁 retry logic (safe)
      if (response.statusCode == 504 && retryCount < maxRetry) {
        retryCount++;
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }

      if (response.statusCode != 200) break;

      retryCount = 0;

      final responseJson = jsonDecode(response.body);
      final data = responseJson['responseData'] as List?;

      if (data == null || data.isEmpty) break;

      final items = data.map((e) => InventoryList.fromJson(e)).toList();

      allItems.addAll(items);

      if (items.length < limit) break;

      index++;
    }

    return allItems;
  }

  Future<List<MonthlyInventoryData>> _loadMonthlyInventory(
    String userName,
    String userLevel,
  ) async {
    final now = DateTime.now();
    final fyStartYear = (now.month >= 4) ? now.year : now.year - 1;
    final marchDate = DateTime(fyStartYear, 3, _lastDayOfMonth(fyStartYear, 3));
    final endDate = DateTime(
      now.year,
      now.month,
      _lastDayOfMonth(now.year, now.month),
    );

    List<MonthlyInventoryData> result = [];
    DateTime cursor = marchDate;

    while (!cursor.isAfter(endDate)) {
      final monthData = await _fetchInventoryForDate(cursor);
      final label = DateFormat('MMM yyyy').format(cursor);
      result.add(MonthlyInventoryData(monthYear: label, inventory: monthData));

      final nextMonth = cursor.month < 12
          ? DateTime(cursor.year, cursor.month + 1, 1)
          : DateTime(cursor.year + 1, 1, 1);
      cursor = DateTime(
        nextMonth.year,
        nextMonth.month,
        _lastDayOfMonth(nextMonth.year, nextMonth.month),
      );
    }
    monthWiseInventory = result;
    return result;
  }

  Future<void> _loadMonthlySalesBarCashConversionChartData(
    String? touchedMonth,
  ) async {
    List<CashConversionGraphData> soDataList = [];
    List<DSOGraphData> dataList = [];

    final now = DateTime.now();
    final int fiscalIndex = (now.month < 4) ? now.month + 12 : now.month;

    final dateFormat = DateFormat('dd/MM/yyyy');

    DateTime parseDate(String d) => dateFormat.parse(d);

    /// STEP 1: Pre-group (NO repeated where)
    final salesMap = {
      "NH": <SalesList>[],
      "OFFICE": <SalesList>[],
      "SALES": <SalesList>[],
    };

    for (var s in sales) {
      if (s.salesManager == "NH GROUP. - Drs.") {
        salesMap["NH"]!.add(s);
      } else if (s.salesManager == "OFFICE - Drs.") {
        salesMap["OFFICE"]!.add(s);
      } else {
        salesMap["SALES"]!.add(s);
      }
    }

    List filterByManager(List list, String key) {
      return list.where((e) {
        if (key == "NH") return e.salesManager == "NH GROUP. - Drs.";
        if (key == "OFFICE") return e.salesManager == "OFFICE - Drs.";
        return e.salesManager != "NH GROUP. - Drs." &&
            e.salesManager != "OFFICE - Drs.";
      }).toList();
    }

    final receivablesMap = {
      "NH": filterByManager(target, "NH"),
      "OFFICE": filterByManager(target, "OFFICE"),
      "SALES": filterByManager(target, "SALES"),
    };

    final collectionMap = {
      "NH": filterByManager(collection, "NH"),
      "OFFICE": filterByManager(collection, "OFFICE"),
      "SALES": filterByManager(collection, "SALES"),
    };

    /// STEP 2: Month Loop
    for (int i = 4; i <= 15; i++) {
      final monthName = getMonthName(i);

      if (i > fiscalIndex) {
        soDataList.add(
          CashConversionGraphData(
            monthName: monthName,
            dsoDaysSales: 0,
            dsoDaysNH: 0,
            dsoDaysOffice: 0,
            dsoAllDays: 0,
            payableDays: 0,
            inventoryDays: 0,
          ),
        );
        continue;
      }

      var dates = getMonthStartEndDates(i);
      final curStart = dates['start']!;
      final curEnd = dates['end']!;

      /// Previous month directly from current month
      final prevDate = DateTime(curStart.year, curStart.month - 1, 1);
      final prevStart = DateTime(prevDate.year, prevDate.month, 1);
      final prevEnd = DateTime(prevDate.year, prevDate.month + 1, 0);

      double calcDSO(
        List<SalesList> salesList,
        List receivableList,
        List collectionList,
      ) {
        double salesTotal = 0;
        double receivableTotal = 0;
        double collectionTotal = 0;

        /// SALES
        for (var s in salesList) {
          if (s.invoiceDate.isAtLeast(curStart) &&
              s.invoiceDate.isAtMost(curEnd)) {
            salesTotal += double.tryParse(s.rowTotal) ?? 0;
          }
        }
        double prevMthReceivableTotal = 0;
        double prevMthCollectionTotal = 0;

        /// RECEIVABLE
        for (var r in receivableList) {
          final d = parseDate(r.postingDate);
          final balance = double.tryParse(r.balance) ?? 0;

          /// Current Month
          if (d.isAtMost(curEnd)) {
            receivableTotal += balance;
          }

          /// Previous Month
          if (d.isAtMost(prevEnd)) {
            prevMthReceivableTotal += balance;
          }
        }

        /// COLLECTION
        for (var c in collectionList) {
          final d = parseDate(c.postingDate);
          final total = double.tryParse(c.total) ?? 0;

          /// Current Month
          if (d.isAtLeast(curStart) && d.isAtMost(curEnd)) {
            collectionTotal += total;
          }

          /// Previous Month
          if (d.isAtLeast(prevStart) && d.isAtMost(prevEnd)) {
            prevMthCollectionTotal += total;
          }
        }

        // /// RECEIVABLE
        // for (var r in receivableList) {
        //   final d = parseDate(r.postingDate);
        //   if (d.isAtMost(curEnd)) {
        //     receivableTotal += double.tryParse(r.balance) ?? 0;
        //   }
        // }

        // /// COLLECTION
        // for (var c in collectionList) {
        //   final d = parseDate(c.postingDate);
        //   if (d.isAtLeast(curStart) && d.isAtMost(curEnd)) {
        //     collectionTotal += double.tryParse(c.total) ?? 0;
        //   }
        // }

        final avg =
            (prevMthReceivableTotal +
                prevMthCollectionTotal +
                receivableTotal +
                collectionTotal) /
            2;
        final days = getCompletedDaysInMonth(DateTime.now().year, i);

        return salesTotal != 0 ? (avg / salesTotal) * days : 0;
      }

      /// STEP 3: Calculate DSO
      final dsoNH = calcDSO(
        salesMap["NH"]!,
        receivablesMap["NH"]!,
        collectionMap["NH"]!,
      );

      final dsoOffice = calcDSO(
        salesMap["OFFICE"]!,
        receivablesMap["OFFICE"]!,
        collectionMap["OFFICE"]!,
      );

      final dsoSales = calcDSO(
        salesMap["SALES"]!,
        receivablesMap["SALES"]!,
        collectionMap["SALES"]!,
      );

      /// STEP 4: Payables & Paid
      double paid = 0;
      for (var c in modeOfPayment) {
        final d = parseDate(c.postingDate);
        if (d.isAtLeast(curStart) && d.isAtMost(curEnd)) {
          paid += double.tryParse(c.total) ?? 0;
        }
      }
      double payable = 0;
      for (var p in payables) {
        final d = parseDate(p.postingDate);
        if (d.isAtMost(curEnd)) {
          payable += double.tryParse(p.balance) ?? 0;
        }
      }

      /// STEP 5: Inventory
      final cogsIndex = i - 4;

      final cogsData = (cogsIndex >= 0 && cogsIndex < monthlyCogsList.length)
          ? monthlyCogsList[cogsIndex]
          : MonthlyCogsData(
              monthYear: monthName,
              openingStock: 0,
              purchases: 0,
              closingStock: 0,
              cogs: 0,
            );

      double avgInventory = (cogsData.openingStock + cogsData.closingStock) / 2;

      double inventoryDays = cogsData.cogs != 0
          ? (avgInventory / cogsData.cogs) *
                getCompletedDaysInMonth(DateTime.now().year, i)
          : 0;

      payable = payable.abs();
      final avg = (payable + paid) / 2;
      final days = getCompletedDaysInMonth(DateTime.now().year, i);

      payable = payable != 0 ? (avg / cogsData.cogs) * days : 0;

      final totalDSO = dsoNH + dsoSales + dsoOffice;

      soDataList.add(
        CashConversionGraphData(
          monthName: monthName,
          dsoDaysSales: dsoSales.roundToDouble(),
          dsoDaysNH: dsoNH.roundToDouble(),
          dsoDaysOffice: dsoOffice.roundToDouble(),
          dsoAllDays: totalDSO.roundToDouble(),
          payableDays: payable.abs().roundToDouble(),
          inventoryDays: inventoryDays.roundToDouble(),
        ),
      );
    }

    /// STEP 6: Graph Selection
    monthlyAnalysisData = CashConversionGraphList(monthData: soDataList);

    int displayIndex;

    if (touchedMonth != null) {
      displayIndex = soDataList.indexWhere((e) => e.monthName == touchedMonth);

      if (displayIndex == -1) {
        displayIndex = DateTime.now().month - 4;
      }
    } else {
      displayIndex = DateTime.now().month - 4;
    }

    displayIndex = displayIndex.clamp(0, soDataList.length - 1);

    dataList.add(
      DSOGraphData(
        monthname: soDataList[displayIndex].monthName,
        name: "Receivables Days Outstanding",
        target: 60,
        achievement: soDataList[displayIndex].dsoAllDays,
      ),
    );

    dataList.add(
      DSOGraphData(
        monthname: soDataList[displayIndex].monthName,
        name: "Inventory Days Outstanding",
        target: 60,
        achievement: soDataList[displayIndex].inventoryDays,
      ),
    );

    dataList.add(
      DSOGraphData(
        monthname: soDataList[displayIndex].monthName,
        name: "Payable Days Outstanding",
        target: 75,
        achievement: soDataList[displayIndex].payableDays,
      ),
    );

    graphData = DSOGraphList(monthData: dataList);
    if (!mounted) return;
    setState(() {
      chartDataLoadedCCC = true;
    });
  }

  Future<void> loadDataWithFilter(String? touchedMonth) async {
    setState(() {
      chartDataLoadedCCC = false;
    });
    clearVariablesForFilter();
    LoadDates();
    await _loadMonthlySalesBarCashConversionChartData(touchedMonth);
    setState(() {
      chartDataLoadedCCC = true;
    });
  }

  void clearVariablesForFilter() {
    setState(() {
      chartDataLoadedCCC = false;
      graphData = DSOGraphList(monthData: []);
    });
  }

  List<MonthlyCogsData> calculateMonthlyCogs({
    required List<MonthlyInventoryData> inventoryList,
    required List<DailyAnalysisExpensesData> purchaseMonthlyData,
  }) {
    final List<MonthlyCogsData> cogsList = [];

    if (inventoryList.length < 2) return cogsList;

    double sumInventory(List inventory) {
      return inventory.fold<double>(
        0.0,
        (sum, item) => sum + (double.tryParse(item.totalValue) ?? 0.0),
      );
    }

    for (int i = 1; i < inventoryList.length; i++) {
      final current = inventoryList[i];
      final previous = inventoryList[i - 1];

      final String monthYear = current.monthYear;

      final double openingStock = sumInventory(previous.inventory);
      final double closingStock = sumInventory(current.inventory);

      double purchases = 0.0;
      if (i - 1 < purchaseMonthlyData.length) {
        purchases = purchaseMonthlyData[i - 1].balance;
      }

      final double cogs = openingStock + purchases - closingStock;

      cogsList.add(
        MonthlyCogsData(
          monthYear: monthYear,
          openingStock: openingStock,
          purchases: purchases,
          closingStock: closingStock,
          cogs: cogs,
        ),
      );
    }

    return cogsList;
  }

  Future<void> _loadMonthlyAnalysisPurchase() async {
    final List<DailyAnalysisExpensesData> groupWiseDataList = [];

    final records = purchasePrice;

    final startDate = dateFilterFlag ? fromDateFilter! : fiscalYearStartDate!;
    final endDate = dateFilterFlag ? toDateFilter! : currentDate!;

    final dateFormat = DateFormat('dd/MM/yyyy');
    final monthFormat = DateFormat('MM/yyyy');

    /// Single pass: filter + group
    final Map<String, double> monthlyBalanceMap = {};

    for (var record in records) {
      final invoiceDate = dateFormat.parse(record.grnDate);

      if (!invoiceDate.isAtLeast(startDate) || !invoiceDate.isAtMost(endDate)) {
        continue;
      }

      final key = monthFormat.format(invoiceDate);

      final balance = double.tryParse(record.rowTotal) ?? 0.0;

      monthlyBalanceMap[key] = (monthlyBalanceMap[key] ?? 0.0) + balance;
    }

    /// Ensure chronological order (important)
    final sortedKeys = monthlyBalanceMap.keys.toList()
      ..sort((a, b) {
        final d1 = DateFormat('MM/yyyy').parse(a);
        final d2 = DateFormat('MM/yyyy').parse(b);
        return d1.compareTo(d2);
      });

    for (var key in sortedKeys) {
      groupWiseDataList.add(
        DailyAnalysisExpensesData(balance: monthlyBalanceMap[key]!, date: key),
      );
    }

    purchaseMonthlyData = DailyAnalysisExpensesList(
      dailyData: groupWiseDataList,
    );

    monthlyCogsList = calculateMonthlyCogs(
      inventoryList: monthWiseInventory,
      purchaseMonthlyData: purchaseMonthlyData.dailyData,
    );
  }

  Future<void> generateCashConversionExcel() async {
    await reportService.generateExcel(
      sheetName: 'CashConversion',
      headers: [
        'Cash Conversion Cycle',
        'Target',
        'April',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
        'Jan',
        'Feb',
        'Mar',
      ],
      rows: [
        [
          "Receivable Days Outstanding Sales Team",
          "",
          monthlyAnalysisData.monthData[0].dsoDaysSales,
          monthlyAnalysisData.monthData[1].dsoDaysSales,
          monthlyAnalysisData.monthData[2].dsoDaysSales,
          monthlyAnalysisData.monthData[3].dsoDaysSales,
          monthlyAnalysisData.monthData[4].dsoDaysSales,
          monthlyAnalysisData.monthData[5].dsoDaysSales,
          monthlyAnalysisData.monthData[6].dsoDaysSales,
          monthlyAnalysisData.monthData[7].dsoDaysSales,
          monthlyAnalysisData.monthData[8].dsoDaysSales,
          monthlyAnalysisData.monthData[9].dsoDaysSales,
          monthlyAnalysisData.monthData[10].dsoDaysSales,
          monthlyAnalysisData.monthData[11].dsoDaysSales,
        ],
        [
          "Receivable Days Outstanding NH",
          "",
          ...monthlyAnalysisData.monthData.map((e) => e.dsoDaysNH),
        ],
        [
          "Receivable Days Outstanding Office",
          "",
          ...monthlyAnalysisData.monthData.map((e) => e.dsoDaysOffice),
        ],
        [""], // spacer row
        [
          "Receivable Outstanding Days",
          60,
          ...monthlyAnalysisData.monthData.map((e) => e.dsoAllDays),
        ],
        [
          "Add: Inventory Days Outstanding",
          60,
          ...monthlyAnalysisData.monthData.map(
            (e) => double.parse(e.inventoryDays.toStringAsFixed(0)),
          ),
        ],
        [
          "Less: Payable Days Outstanding",
          75,
          ...monthlyAnalysisData.monthData.map((e) => e.payableDays),
        ],
        [
          "",
          45,
          ...monthlyAnalysisData.monthData.map(
            (e) => double.parse(
              ((e.dsoAllDays + e.inventoryDays) - e.payableDays)
                  .toStringAsFixed(0),
            ),
          ),
        ],
      ],
      fileName: 'cashConversionCycle.xlsx',
      reportTitle: 'Cash Conversion Cycle',
      amountColumns: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
      addTotalRow: true,
    );
  }

  Future<void> generateMonthlyCCExcel(DSOGraphList list) async {
    await reportService.generateExcel(
      sheetName: 'CashConversionMonthlyAnalysis',
      headers: ['Category', 'Achievement', 'Target'],
      rows: list.monthData
          .map(
            (data) => [
              data.name,
              double.tryParse(data.achievement.toStringAsFixed(2)) ?? 0.0,
              double.tryParse(data.target.toStringAsFixed(2)) ?? 0.0,
            ],
          )
          .toList(),
      fileName: 'cash_conversion_monthly_analysis.xlsx',
      amountColumns: [2, 3], // Achievement & Target columns
      addTotalRow: true,
      reportTitle:
          'Cash Conversion Monthly Analysis - ${list.monthData.first.monthname}',
    );
  }

  Future<void> generateMonthlyCCPDF(DSOGraphList list) async {
    await reportService.generatePDF(
      title:
          'Cash Conversion Monthly Analysis - ${list.monthData.first.monthname}',
      headers: ['Category', 'Achievement', 'Target'],
      rows: list.monthData
          .map(
            (data) => [
              data.name,
              double.tryParse(data.achievement.toStringAsFixed(2)) ?? 0.0,
              double.tryParse(data.target.toStringAsFixed(2)) ?? 0.0,
            ],
          )
          .toList(),
      fileName: 'cash_conversion_monthly_analysis.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> loadData(String selectedUser) async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadCollectionTarget(userName, userLevel);
    await _loadSales(userName, userLevel);
    await _loadCollection(userName, userLevel);
    await _loadPayables(userName, userLevel);
    await _loadModeOfPayment(userName, userLevel);
    await _loadGRN(userName, userLevel);
    await _loadInventory(userName, userLevel);
    await _loadInventoryClosing(userName, userLevel);
    await _loadMonthlyInventory(userName, userLevel);
    await _loadMonthlyAnalysisPurchase();
    await _loadMonthlySalesBarCashConversionChartData("");
    chartDataLoadedCCC = true;
  }

  String formatDateString(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  Future<void> removeFilter() async {
    clearVariables();
    LoadDates();
    allCategoriesState.forEach((category, options) {
      options.updateAll((key, value) => false);
    });
    loadData("");
    chartDataLoadedCCC = true;
  }

  void clearVariables() {
    setState(() {
      chartDataLoadedCCC = false;
      monthlyAnalysisData = CashConversionGraphList(monthData: []);
      graphData = DSOGraphList(monthData: []);
      purchaseMonthlyData = DailyAnalysisExpensesList(dailyData: []);
    });
  }

  void toggleCheckbox() async {
    setState(() {
      chartDataLoadedCCC = false;
    });
    await loadData("");
  }

  Future<void> _dateFilterTarget() async {
    setState(() {
      context.read<CashConversionReceivablesProvider>().updateTargetList(
        target,
      );
      context.read<CashConversionSalesProvider>().updateSalesList(sales);
      context.read<CashConversionActualPayableProvider>().updateTargetList(
        modeOfPayment,
      );
      context.read<CashConversionCollectionProvider>().updateCollectionList(
        collection,
      );
      context.read<CashConversionPayableProvider>().updatePOList(payables);
      context.read<InventoryCashConversionProvider>().updateInventoryList(
        inventory,
      );
      context
          .read<InventoryClosingCashConversionProvider>()
          .updateInventoryList(inventoryClosing);
      context.read<GRNCashConversionProvider>().updatePurchaseList(
        purchasePrice,
      );

      target = target.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.postingDate);
        // DateTime toDt = formatter.parse('31/${target.monthYear}');
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();

      sales = sales.where((target) {
        DateTime dueon = target.invoiceDate;
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();

      modeOfPayment = modeOfPayment.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.postingDate);
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();

      collection = collection.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.postingDate);
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();

      payables = payables.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.postingDate);
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();

      purchasePrice = purchasePrice.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.grnDate);
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();
    });
  }

  Future<void> filterDateFunction() async {
    _dateFilterTarget();
    await _loadMonthlyAnalysisPurchase();
    await _loadMonthlySalesBarCashConversionChartData("");
    setState(() {});
    chartDataLoadedCCC = true;
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

  @override
  void initState() {
    super.initState();
    LoadDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
    }
    toDateFilter = currentDate;
    fromDateFilter = fiscalYearStartDate;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return chartDataLoadedCCC
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
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "CCC - Monthly Analysis",
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
                                  generateCashConversionExcel();
                                },
                                child: const Row(
                                  children: [Text("Download Excel")],
                                ),
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
                  child: _monthlyAnalysis(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "CCC - Days Outstanding",
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
                                    generateMonthlyCCExcel(graphData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateMonthlyCCPDF(graphData);
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
                  child: _monthlyAnalysisGraph(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                // Center(
                //   child: ElevatedButton(
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor:
                //       const Color(0xff2ca9df),
                //       shape: RoundedRectangleBorder(
                //         borderRadius:
                //         BorderRadius.circular(5.0),
                //       ),
                //     ),
                //     onPressed: () {},
                //     child: const SizedBox(
                //       width: 400,
                //       child: Center(
                //         child: Text(
                //           "Download Reports",
                //           style: TextStyle(
                //               fontSize: 14,
                //               color: Colors.white),
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  Widget _monthlyAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = monthlyAnalysisData.monthData.length;
    if (len > 5) {
      chartWidth = screenWidth + (80 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? monthlyAnalysisData.monthData
              .map((data) => data.dsoDaysOffice)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(maxAmount),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesMonthlyAnalysis,
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
            barGroups: _monthlyAnalysisChartData(monthlyAnalysisData.monthData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedMonth = touchedMonth == ""
                          ? monthlyAnalysisData
                                .monthData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .monthName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(touchedMonth);
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
                    '${monthlyAnalysisData.monthData[grpIndex].monthName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            'DSO NH: ${monthlyAnalysisData.monthData[grpIndex].dsoDaysNH}\n',
                        style: const TextStyle(
                          color: Color(0xFF2CA9DF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            'DSO Sales: ${monthlyAnalysisData.monthData[grpIndex].dsoDaysSales}\n',
                        style: const TextStyle(
                          color: Color(0xFFFF9F47),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            'DSO Office: ${monthlyAnalysisData.monthData[grpIndex].dsoDaysOffice}\n',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF78E25D),
                          fontWeight: FontWeight.bold,
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

  Widget _monthlyAnalysisGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = graphData.monthData.length;
    if (len > 5) {
      chartWidth = screenWidth + (80 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? graphData.monthData
              .map((data) => data.achievement)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(maxAmount),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesCCC,
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
            barGroups: _CCCChartData(graphData.monthData),
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
                    '${graphData.monthData[grpIndex].monthname}\n${graphData.monthData[grpIndex].name}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            'Target: ${graphData.monthData[grpIndex].target.toStringAsFixed(0)}\n',
                        style: const TextStyle(
                          color: Color(0xFFFF9F47),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Days: ${graphData.monthData[grpIndex].achievement.toStringAsFixed(0)}\n',
                        style: const TextStyle(
                          color: Color(0xFF2CA9DF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
        setState(() {});
      }
    });
  }

  void showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        int selectedCategoryIndex = 0;

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Options - Cash\nConversion Cycle',
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
                  // Filter UI
                  Expanded(
                    child: Row(
                      children: [
                        // Left side: Categories
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

                                        // Ensure the lengths match for your filterOptions and selectedFinanceReceivablesOptions lists
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

                                      // toggleCheckbox();
                                      filterDateFunction();
                                      setState(() {});
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
                                      chartDataLoadedCCC = false;
                                      setState(() {
                                        chartDataLoadedCCC = false;
                                        loadDataFuture = removeFilter();
                                        Navigator.pop(context);
                                        chartDataLoadedCCC = true;
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
