// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference

import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/classes/leads.dart';
import 'package:optima/login_screen.dart';

import '../ReportService.dart';

final reportService = ReportService();

class MonthlyInventoryData {
  final String monthYear; // e.g. "Mar 2025"
  final List<InventoryList> inventory;
  MonthlyInventoryData({required this.monthYear, required this.inventory});
}

class MonthlyCogsList {
  final List<MonthlyCogsData> monthlyData;
  MonthlyCogsList({required this.monthlyData});
}

class MonthlyCogsData {
  final String monthYear;
  final double openingStock;
  final double purchases;
  final double closingStock;
  final double cogs;
  final double? inventoryTarget;
  final double? cogsTarget;

  MonthlyCogsData({
    required this.monthYear,
    required this.openingStock,
    required this.purchases,
    required this.closingStock,
    required this.cogs,
    this.inventoryTarget,
    this.cogsTarget,
  });
}

class MonthlyPLFinance extends StatefulWidget {
  const MonthlyPLFinance({super.key});

  @override
  State<MonthlyPLFinance> createState() => _MonthlyPLFinanceState();
}

late Future<void> loadDataFuture;
String userLevel = "0";
bool chartDataLoadedMonthlyPl = false;
List<Users> usersList = [];

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

List<TrialBalance> trialBalanceList = [];
List<TrialBalance> trialBalanceListTemp = [];
List<PurchaseList> purchasePrice = [];
List<PurchaseList> purchasePriceTemp = [];
List<InventoryList> inventory = [];
List<InventoryList> inventoryClosing = [];
List<SalesList> sales = [];
List<SalesList> salesTemp = [];
List<SalesTargetList> salesTarget = [];

List<GRNList> grnList = [];
List<MonthlyInventoryData> monthWiseInventory = [];
List<MonthlyCogsData> monthlyCogsList = [];
MonthlyCogsList monthlyCOGS = MonthlyCogsList(monthlyData: []);

double lessThan30DaysValue = 0;
double a30to60DaysValue = 0;
double a60to90DaysValue = 0;
double a91DaysValue = 0;
double nearExpiryValue = 0;
double expiredValue = 0;
double inventoryOpeningValue = 0;
double inventoryClosingValue = 0;

Map<String, List<double>> monthlyMap = {};

double cogsValue = 0;

double revenueTarget = 0;
double purchaseTarget = 0;

String fromDateForFilter = '';
String toDateForFilter = '';
PrevYearMonthList prevYearMonthList = PrevYearMonthList(prevYearMonthData: []);

MonthlySalesList monthlySalesList = MonthlySalesList(monthlyData: []);

GroupWiseAnalysisExpensesList groupList = GroupWiseAnalysisExpensesList(
  groupData: [],
);
SubGroupWiseAnalysisExpensesList subGroupList =
    SubGroupWiseAnalysisExpensesList(subGroupData: []);
DailyAnalysisExpensesList expenditureMonthlyData = DailyAnalysisExpensesList(
  dailyData: [],
);
DailyAnalysisExpensesList revenueMonthlyData = DailyAnalysisExpensesList(
  dailyData: [],
);
DailyAnalysisExpensesList purchaseMonthlyData = DailyAnalysisExpensesList(
  dailyData: [],
);
DailyAnalysisExpensesList inventoryMonthlyData = DailyAnalysisExpensesList(
  dailyData: [],
);
DailyAnalysisExpensesList inventoryClosingMonthlyData =
    DailyAnalysisExpensesList(dailyData: []);
SubGroupMonthWiseExpensesList subGroupMonthWiseList =
    SubGroupMonthWiseExpensesList(subGroupData: []);
SubGroupMonthWiseRevenueExpensesList subGroupMonthExpenseWiseList =
    SubGroupMonthWiseRevenueExpensesList(subGroupData: []);
SubGroupMonthWiseRevenueExpensesList foreignNameMonthExpenseWiseList =
    SubGroupMonthWiseRevenueExpensesList(subGroupData: []);
SubGroupMonthWiseRevenueExpensesList otherIndirectExpensesList =
    SubGroupMonthWiseRevenueExpensesList(subGroupData: []);
SubGroupMonthWiseRevenueExpensesList directExpensesList =
    SubGroupMonthWiseRevenueExpensesList(subGroupData: []);
SubGroupMonthWiseRevenueExpensesList sumOfDirectExpensesList =
    SubGroupMonthWiseRevenueExpensesList(subGroupData: []);
SubGroupMonthWiseRevenueExpensesList totalIndirectExpensesList =
    SubGroupMonthWiseRevenueExpensesList(subGroupData: []);
SubGroupMonthWiseRevenueExpensesList otherIncomeList =
    SubGroupMonthWiseRevenueExpensesList(subGroupData: []);

DateTime? fromDateFilter;
DateTime? toDateFilter;
bool dateFilterFlag = false;

bool fromFilter = false;

Map<String, Map<String, bool>> allCategoriesState = {};

final List<String> categories = ['Date'];

List<List<String>> filterOptions = [[]];

List<String> selectedSalesData = [];

List<List<bool>> selectedFinanceReceivablesOptions = [];

List<List<bool>> savedFinanceReceivablesOptionsTemp = [];

List<List<bool>> savedFinanceReceivablesOptions = filterOptions
    .map((options) => List<bool>.filled(options.length, false))
    .toList();

class TrialBalanceProvider with ChangeNotifier {
  List<TrialBalance> _trialBalance = [];
  List<TrialBalance> get trialBalanceList => _trialBalance;
  void updateTrialBalanceList(List<TrialBalance> newTrialBalanceList) {
    _trialBalance = newTrialBalanceList;
    notifyListeners();
  }
}

class SalesMonthlyPLProvider with ChangeNotifier {
  List<SalesList> _salesList = [];
  List<SalesList> get salesList => _salesList;
  void updateSalesList(List<SalesList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class PurchaseMonthlyPLProvider with ChangeNotifier {
  List<PurchaseList> _purchaseList = [];
  List<PurchaseList> get purchaseList => _purchaseList;
  void updatePurchaseList(List<PurchaseList> newList) {
    _purchaseList = newList;
    notifyListeners();
  }
}

class InventoryMonthlyPLProvider with ChangeNotifier {
  List<InventoryList> _inventoryList = [];
  List<InventoryList> get inventoryList => _inventoryList;
  void updateInventoryList(List<InventoryList> newList) {
    _inventoryList = newList;
    notifyListeners();
  }
}

class InventoryClosingMonthlyPLProvider with ChangeNotifier {
  List<InventoryList> _inventoryList = [];
  List<InventoryList> get inventoryList => _inventoryList;
  void updateInventoryList(List<InventoryList> newList) {
    _inventoryList = newList;
    notifyListeners();
  }
}

class SalesTargetMonthlyPLProvider with ChangeNotifier {
  List<SalesTargetList> _salesTargetList = [];
  List<SalesTargetList> get salesTargetList => _salesTargetList;
  void updateSalesTargetList(List<SalesTargetList> newSalesTargetList) {
    _salesTargetList = newSalesTargetList;
    notifyListeners();
  }
}

class GRNMonthlyPLProvider with ChangeNotifier {
  List<GRNList> _purchaseList = [];
  List<GRNList> get purchaseList => _purchaseList;
  void updatePurchaseList(List<GRNList> newList) {
    _purchaseList = newList;
    notifyListeners();
  }
}

class _MonthlyPLFinanceState extends State<MonthlyPLFinance> {
  @override
  void initState() {
    super.initState();
    loadDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
    }
    toDateFilter = currentDate;
    fromDateFilter = fiscalYearStartDate;
  }

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
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

  String getMonthName(int month) {
    final formatter = DateFormat('MMMM');
    return formatter.format(DateTime(2000, month));
  }

  int _lastDayOfMonth(int year, int month) {
    final nextMonth = (month < 12)
        ? DateTime(year, month + 1, 1)
        : DateTime(year + 1, 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  List<MonthlyCogsData> calculateMonthlyCogs({
    required List<MonthlyInventoryData> inventoryList,
    required List<DailyAnalysisExpensesData> purchaseMonthlyData,
    required Map<String, List<double>> targetMap,
  }) {
    List<MonthlyCogsData> cogsList = [];

    for (int i = 1; i < inventoryList.length; i++) {
      final curr = inventoryList[i];
      final prev = inventoryList[i - 1];
      final monthYear = curr.monthYear; // e.g. "Apr 2025"
      final monthIdx = monthIndexFromString(monthYear);

      final openingStock = prev.inventory.fold(
        0.0,
        (sum, item) => sum + double.parse(item.totalValue),
      );
      final closingStock = curr.inventory.fold(
        0.0,
        (sum, item) => sum + double.parse(item.totalValue),
      );
      final purchases = (i - 1 < purchaseMonthlyData.length)
          ? purchaseMonthlyData[i - 1].balance
          : 0.0;
      final cogs = openingStock + purchases - closingStock;

      final cogsTarget =
          (targetMap['COGS TARGET'] != null &&
              monthIdx < targetMap['COGS TARGET']!.length)
          ? targetMap['COGS TARGET']![monthIdx]
          : 0.0;
      final inventoryTarget =
          (targetMap['INVENTORY TARGET'] != null &&
              monthIdx < targetMap['INVENTORY TARGET']!.length)
          ? targetMap['INVENTORY TARGET']![monthIdx]
          : 0.0;

      cogsList.add(
        MonthlyCogsData(
          monthYear: monthYear,
          openingStock: openingStock,
          purchases: purchases,
          closingStock: closingStock,
          cogs: cogs,
          cogsTarget: cogsTarget,
          inventoryTarget: inventoryTarget,
        ),
      );
    }

    return cogsList;
  }

  int monthIndexFromString(String monthYear) {
    final monthPart = monthYear.split(RegExp(r'[-\s]')).first;

    const monthMap = {
      'Jan': 0,
      'January': 0,
      'Feb': 1,
      'February': 1,
      'Mar': 2,
      'March': 2,
      'Apr': 3,
      'April': 3,
      'May': 4,
      'Jun': 5,
      'June': 5,
      'Jul': 6,
      'July': 6,
      'Aug': 7,
      'August': 7,
      'Sep': 8,
      'September': 8,
      'Oct': 9,
      'October': 9,
      'Nov': 10,
      'November': 10,
      'Dec': 11,
      'December': 11,
    };

    return monthMap[monthPart] ?? 0;
  }

  String getCurrentFinancialYearSuffix() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    int startYear = (month >= 4) ? year : year - 1;
    int endYear = startYear + 1;

    return "FY${startYear % 100}-${endYear % 100}-T";
  }

  Map<String, List<double>> buildMonthlyTargets(List<SalesTargetList> data) {
    const reps = [
      'MD SALES TARGET',
      'IPD SALES TARGET',
      'PURCHASE TARGET',
      'COGS TARGET',
      'INVENTORY TARGET',
      'PRODUCTION TARGET',
    ];

    final result = {for (var rep in reps) rep: List<double>.filled(12, 0.0)};
    final suffix = getCurrentFinancialYearSuffix();

    // Filter API data to current financial year
    final currentYearList = data.where((e) => e.financialYear == suffix);

    // Populate month values
    for (var i = 1; i <= 12; i++) {
      final monthName = getMonthName(i);
      for (var entry in currentYearList) {
        if (!result.containsKey(entry.salesRep)) continue;
        final value = double.tryParse(entry.getTargetForMonth(monthName)) ?? 0;
        result[entry.salesRep]![i - 1] = value;
      }
    }

    return result;
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    userLevel = prefs.getString('userLevel') ?? '';
    await Future.wait([
      _loadTrialBalance(userName, userLevel),
      _loadPurchasePrice(userName, userLevel),
      _loadInventory(userName, userLevel),
      _loadSales(userName, userLevel),
      _loadGRN(userName, userLevel),
      _loadSalesTarget(userName, userLevel),
      loadMonthlyInventory(userName, userLevel),
    ]);
    monthlyMap = buildMonthlyTargets(salesTarget);
    await Future.wait([
      _loadSubGroupWiseAnalysis(0, "", ""),
      _loadMonthlyAnalysisExpenditure(),
      _loadMonthlyAnalysisPurchase(),
      _loadMonthlySalesBarChartData(),
      _loadMonthlyAnalysisRevenue(),
      _loadMonthlyAnalysisInventory(),
      _loadMonthlyAnalysisInventoryClosing(),
      _loadSubGroupMonthWiseAnalysisExpenditure(),
      _loadSubGroupMonthWiseAnalysisRevenue(),
      _loadOtherIncomeMonthWiseAnalysisRevenue(),
      _loadForeignNameMonthWiseAnalysisRevenue(),
    ]);
    if (!mounted) return;
    setState(() {
      chartDataLoadedMonthlyPl = true;
    });
  }

  Future<List<MonthlyInventoryData>> loadMonthlyInventory(
    String userName,
    String userLevel,
  ) async {
    final now = DateTime.now();
    final fyStartYear = (now.month >= 4) ? now.year : now.year - 1;

    List<Future<MonthlyInventoryData>> futures = [];

    DateTime cursor = DateTime(fyStartYear, 3, 31);
    final endDate = DateTime(
      now.year,
      now.month,
      _lastDayOfMonth(now.year, now.month),
    );

    while (!cursor.isAfter(endDate)) {
      final date = cursor;

      futures.add(() async {
        final data = await _fetchInventoryPaged(
          toDate: DateFormat('yyyyMMdd').format(date),
        );

        return MonthlyInventoryData(
          monthYear: DateFormat('MMM yyyy').format(date),
          inventory: data,
        );
      }());

      final nextMonth = date.month < 12
          ? DateTime(date.year, date.month + 1, 1)
          : DateTime(date.year + 1, 1, 1);

      cursor = DateTime(
        nextMonth.year,
        nextMonth.month,
        _lastDayOfMonth(nextMonth.year, nextMonth.month),
      );
    }

    final result = await Future.wait(futures);
    monthWiseInventory = result;

    return result;
  }

  Future<List<InventoryList>> _fetchInventoryPaged({
    required String toDate,
  }) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;

    List<InventoryList> allItems = [];

    do {
      final body = {
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['responseData'] as List?;
        final items = data != null
            ? data.map((e) => InventoryList.fromJson(e)).toList()
            : <InventoryList>[];

        allItems.addAll(items);
        fetchedCount = items.length;
        index++;
      } else {
        fetchedCount = 0;
      }
    } while (fetchedCount == limit);

    return allItems;
  }

  Future<void> _loadTrialBalance(String userName, String userLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<TrialBalance> tmpTrialBalanceList = [];
    try {
      do {
        var body = {
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
        const apiUrl = '${ApiHelper.baseUrl}BicxoTrialBalanceList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<TrialBalance> newTrialBalanceList =
                (responseJson['responseData'] as List)
                    .map((item) => TrialBalance.fromJson(item))
                    .toList();
            tmpTrialBalanceList.addAll(newTrialBalanceList);
            fetchedCount = newTrialBalanceList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else if (response.statusCode == 504) {
          await _loadTrialBalance(userName, userLevel);
        } else if (response.statusCode == 502) {
          await _loadTrialBalance(userName, userLevel);
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        context.read<TrialBalanceProvider>().updateTrialBalanceList(
          tmpTrialBalanceList,
        );
        if (trialBalanceList.isEmpty) {
          trialBalanceList = tmpTrialBalanceList.toList();
          trialBalanceListTemp = tmpTrialBalanceList.toList();
        }
      });
    } catch (e) {
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

  Future<void> _loadPurchasePrice(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<PurchaseList> salesList = [];
    try {
      do {
        var body = {
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
        purchasePrice = salesList;
        context.read<PurchaseMonthlyPLProvider>().updatePurchaseList(salesList);

        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();
        menuNames.insert(0, UserName);
        purchasePriceTemp = salesList.toList();
        if (int.parse(UserLevel) == 5) {
          purchasePrice = salesList.toList();
        } else if (int.parse(UserLevel) == 4) {
          purchasePrice = salesList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          purchasePrice = salesList.toList();
        } else {
          purchasePrice = salesList.toList();
        }
        purchasePrice = salesList.toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (mounted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> _loadInventory(String userName, String userLevel) async {
    try {
      final toDate = dateFilterFlag
          ? formatDate(toDateFilter!)
          : formatDate(lastMonthToDate!);

      final invList = await _fetchInventoryPaged(toDate: toDate);

      if (!mounted) return;

      setState(() {
        context.read<InventoryMonthlyPLProvider>().updateInventoryList(invList);
        context.read<InventoryClosingMonthlyPLProvider>().updateInventoryList(
          invList,
        );
        inventory = invList;
        inventoryClosing = invList;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _loadSales(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<SalesList> salesList = [];
    try {
      do {
        var body = {
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
        const apiUrl = '${ApiHelper.baseUrl}Crm_SalesList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<SalesList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => SalesList.fromJson(item))
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
        context.read<SalesMonthlyPLProvider>().updateSalesList(salesList);
        salesTemp = salesList.toList();
        sales = salesList.toList();
      });
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (mounted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> _loadGRN(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<GRNList> salesList = [];
    final prefs = await SharedPreferences.getInstance();
    String selectedUser = '';
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;

    try {
      do {
        var body = {
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
        const apiUrl = '${ApiHelper.baseUrl}BicxoGoodsReceiptNoteList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<GRNList> newSalesList = (responseJson['responseData'] as List)
                .map((item) => GRNList.fromJson(item))
                .toList();

            salesList.addAll(newSalesList);
            fetchedCount = newSalesList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else if (response.statusCode == 504) {
          await _loadGRN(userName, userLevel);
        } else if (response.statusCode == 504) {
          await _loadGRN(userName, userLevel);
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        if (grnList.isEmpty) {
          grnList = salesList.toList();
        }
        context.read<GRNMonthlyPLProvider>().updatePurchaseList(salesList);

        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();
        menuNames.insert(0, UserName);
        if (int.parse(UserLevel) == 5) {
          if (grnList.isEmpty) {
            grnList = salesList.toList();
          }
        } else if (int.parse(UserLevel) == 4) {
          if (grnList.isEmpty) {
            grnList = salesList.toList();
          }
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          if (grnList.isEmpty) {
            grnList = salesList.toList();
          }
        } else {
          if (grnList.isEmpty) {
            grnList = salesList.toList();
          }
        }
        if (grnList.isEmpty) {
          grnList = salesList.toList();
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadSalesTarget(String UserName, String UserLevel) async {
    final body = {
      "FromDate": dateFilterFlag
          ? formatDate(fromDateFilter!)
          : formatDate(fiscalYearStartDate!),
      "ToDate": dateFilterFlag
          ? formatDate(toDateFilter!)
          : formatDate(currentDate!),
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
              List<String> menuNames = usersList
                  .where((element) => element.parentMenuId == 0)
                  .map((user) => user.menuName)
                  .toList();
              menuNames.insert(0, UserName);
              context
                  .read<SalesTargetMonthlyPLProvider>()
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
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            navigateToLoginScreen();
          } else {
            final snackBar = SnackBar(
              content: Text(responseJson["Error"].toString()),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      } else {
        const snackBar = SnackBar(
          content: Text('Sales target details not found.'),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      const snackBar = SnackBar(
        content: Text('SAP Server down, Please try again after some time.'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadMonthlySalesBarChartData() async {
    // 1. First filter your SalesTargetList once per FY
    List<SalesTargetList> tempTarget = salesTarget
        .where((t) => t.financialYear == getCurrentFinancialYearSuffix())
        .toList();

    List<MonthlySalesData> monthlyDataList = [];
    int currentYear = DateTime.now().year;

    // 2. Iterate months Apr (4) through next-year Mar (15)
    for (int i = 4; i <= 15; i++) {
      String monthName = getMonthName(i);
      double monthlyTarget = 0.0; // ← will accumulate MD + IPD
      double monthlySales = 0.0;

      // 3. Pull your MD & IPD targets for **this** month
      for (var tgt in tempTarget) {
        if (tgt.salesRep == "MD SALES TARGET" ||
            tgt.salesRep == "IPD SALES TARGET") {
          // getTargetForMonth returns the string for that month’s column
          monthlyTarget +=
              double.tryParse(tgt.getTargetForMonth(monthName)) ?? 0.0;
        }
      }

      // 4. Now fetch & sum your actual sales for this month
      // Helper: convert DateTime to milliseconds for fast comparisons
      int curFrom = 0;
      int curTo = 0;
      DateTime startDate, endDate;
      if (i <= 12) {
        var md = getMonthStartEndDates(i);
        startDate = md['start']!;
        endDate = md['end']!;

        curFrom = startDate.millisecondsSinceEpoch;
        curTo = endDate.millisecondsSinceEpoch;
      } else {
        startDate = DateTime(currentYear + 1, i - 12, 1);
        endDate = DateTime(currentYear + 1, i - 12 + 1, 0);

        curFrom = startDate.millisecondsSinceEpoch;
        curTo = endDate.millisecondsSinceEpoch;
      }

      var monthSalesRows = sales.where((row) {
        final ms = row.invoiceDate.millisecondsSinceEpoch;
        return ms >= curFrom && ms <= curTo;
      });

      for (var row in monthSalesRows) {
        var amt = double.tryParse(row.rowTotal) ?? 0.0;
        monthlySales += amt;
      }

      // 5. Add to your chart list
      monthlyDataList.add(
        MonthlySalesData(
          monthName: monthName,
          salesAmount: monthlySales,
          salesTarget: monthlyTarget,
        ),
      );
    }

    // 6. Wrap up
    monthlySalesList = MonthlySalesList(monthlyData: monthlyDataList);
  }

  Future<void> _loadSubGroupMonthWiseAnalysisExpenditure() async {
    // List to hold month-wise expense data for each subgroup.
    List<SubGroupMonthWiseExpensesData> subGroupMonthWiseDataList = [];

    DateFormat formatter = DateFormat('dd/MM/yyyy');

    // Filter records that are part of "Expenditure".
    List<TrialBalance> expenseRecords = trialBalanceList
        .where((record) => record.group == "Expenditure")
        .toList();

    List<TrialBalance> customerTargetList = [];

    // Process each expense record.

    customerTargetList = expenseRecords.where((record) {
      final parts = record.monthYear.split('/');
      int month = int.parse(parts[0]);
      int year = int.parse(parts[1]);

      // First and last day of the record's month
      DateTime fromDt = DateTime(year, month, 1);
      // Include records that start on or after the fiscal year start
      // and end on or before the current date
      bool startsOnOrAfterFiscalStart = !fromDt.isBefore(fiscalYearStartDate!);
      bool endsOnOrBeforeCurrentDate = !fromDt.isAfter(currentDate!);

      return startsOnOrAfterFiscalStart && endsOnOrBeforeCurrentDate;
    }).toList();

    for (var record in customerTargetList) {
      // Parse the record's month-year by
      // prepending a day (here "01").
      DateTime recordDate = formatter.parse('01/${record.monthYear}');
      int month = recordDate.month;
      // Convert the balance string to a double.
      double recordBalance = double.tryParse(record.balance) ?? 0.0;

      // Find an existing entry for this subgroup using try/catch.
      SubGroupMonthWiseExpensesData? subgroupData;
      try {
        subgroupData = subGroupMonthWiseDataList.firstWhere(
          (element) => element.subGroupName == record.subGroup,
        );
      } catch (e) {
        subgroupData = null;
      }

      // If no entry exists, create a new one with all balances initialized to 0.0.
      if (subgroupData == null) {
        subgroupData = SubGroupMonthWiseExpensesData(
          subGroupName: record.subGroup,
          aprBalance: 0.0,
          mayBalance: 0.0,
          junBalance: 0.0,
          julBalance: 0.0,
          augBalance: 0.0,
          septBalance: 0.0,
          octBalance: 0.0,
          novBalance: 0.0,
          decBalance: 0.0,
          janBalance: 0.0,
          febBalance: 0.0,
          marBalance: 0.0,
        );
        subGroupMonthWiseDataList.add(subgroupData);
      }

      // Update the corresponding month balance based on the record's month.
      // Assuming a financial year from April to March.
      if (month == 4) {
        subgroupData.aprBalance += recordBalance;
      } else if (month == 5) {
        subgroupData.mayBalance += recordBalance;
      } else if (month == 6) {
        subgroupData.junBalance += recordBalance;
      } else if (month == 7) {
        subgroupData.julBalance += recordBalance;
      } else if (month == 8) {
        subgroupData.augBalance += recordBalance;
      } else if (month == 9) {
        subgroupData.septBalance += recordBalance;
      } else if (month == 10) {
        subgroupData.octBalance += recordBalance;
      } else if (month == 11) {
        subgroupData.novBalance += recordBalance;
      } else if (month == 12) {
        subgroupData.decBalance += recordBalance;
      } else if (month == 1) {
        subgroupData.janBalance += recordBalance;
      } else if (month == 2) {
        subgroupData.febBalance += recordBalance;
      } else if (month == 3) {
        subgroupData.marBalance += recordBalance;
      }
    }

    // Inject the data into your SubGroupMonthWiseExpensesList.
    subGroupMonthWiseList = SubGroupMonthWiseExpensesList(
      subGroupData: subGroupMonthWiseDataList,
    );
  }

  Future<void> _loadSubGroupMonthWiseAnalysisRevenue() async {
    // List to hold month-wise expense data for each subgroup.
    List<SubGroupMonthWiseRevenueExpensesData> subGroupMonthWiseDataList = [];

    DateFormat formatter = DateFormat('dd/MM/yyyy');

    // Filter records that are part of "Expenditure".
    List<TrialBalance> expenseRecords = trialBalanceList
        .where((record) => record.group == "Revenue")
        .toList();

    List<TrialBalance> customerTargetList = [];

    customerTargetList = expenseRecords.where((record) {
      // Split the monthYear string into its components:
      final parts = record.monthYear.split('/');
      // Expecting two parts: [month, year]. Use int.parse to convert to integers.
      int month = int.parse(parts[0]);
      int year = int.parse(parts[1]);

      // The first day of the month:
      DateTime fromDt = DateTime(year, month, 1);
      // To safely get the last day of the month, create a date for the first day of the next month,
      // then subtract one day. Note: DateTime(year, month + 1, 0) returns the last day of the month.

      // Now check if the month/date range falls within the fiscal period.
      // If you have a defined fiscalYearEndDate, use that.
      // Here, fiscalYearStartDate and currentDate (or fiscalYearEndDate) are assumed to be non-null.
      bool startsAfterOrOnFiscalStart = !fromDt.isBefore(fiscalYearStartDate!);
      bool endsBeforeOrOnCurrentDate = !fromDt.isAfter(currentDate!);

      return startsAfterOrOnFiscalStart && endsBeforeOrOnCurrentDate;
    }).toList();

    // Process each expense record.
    for (var record in customerTargetList) {
      // Parse the record's month-year by
      // prepending a day (here "01").
      DateTime recordDate = formatter.parse('01/${record.monthYear}');
      int month = recordDate.month;
      // Convert the balance string to a double.
      double recordBalance = double.tryParse(record.balance) ?? 0.0;

      // Find an existing entry for this subgroup using try/catch.
      SubGroupMonthWiseRevenueExpensesData? subgroupData;
      try {
        subgroupData = subGroupMonthWiseDataList.firstWhere(
          (element) => element.subGroupName == record.subGroup,
        );
      } catch (e) {
        subgroupData = null;
      }

      // If no entry exists, create a new one with all balances initialized to 0.0.
      if (subgroupData == null) {
        subgroupData = SubGroupMonthWiseRevenueExpensesData(
          subGroupName: record.subGroup,
          aprBalance: 0.0,
          mayBalance: 0.0,
          junBalance: 0.0,
          julBalance: 0.0,
          augBalance: 0.0,
          septBalance: 0.0,
          octBalance: 0.0,
          novBalance: 0.0,
          decBalance: 0.0,
          janBalance: 0.0,
          febBalance: 0.0,
          marBalance: 0.0,
        );
        subGroupMonthWiseDataList.add(subgroupData);
      }

      // Update the corresponding month balance based on the record's month.
      // Assuming a financial year from April to March.
      if (month == 4) {
        subgroupData.aprBalance += recordBalance;
      } else if (month == 5) {
        subgroupData.mayBalance += recordBalance;
      } else if (month == 6) {
        subgroupData.junBalance += recordBalance;
      } else if (month == 7) {
        subgroupData.julBalance += recordBalance;
      } else if (month == 8) {
        subgroupData.augBalance += recordBalance;
      } else if (month == 9) {
        subgroupData.septBalance += recordBalance;
      } else if (month == 10) {
        subgroupData.octBalance += recordBalance;
      } else if (month == 11) {
        subgroupData.novBalance += recordBalance;
      } else if (month == 12) {
        subgroupData.decBalance += recordBalance;
      } else if (month == 1) {
        subgroupData.janBalance += recordBalance;
      } else if (month == 2) {
        subgroupData.febBalance += recordBalance;
      } else if (month == 3) {
        subgroupData.marBalance += recordBalance;
      }
    }

    // Inject the data into your SubGroupMonthWiseExpensesList.
    subGroupMonthExpenseWiseList = SubGroupMonthWiseRevenueExpensesList(
      subGroupData: subGroupMonthWiseDataList,
    );
  }

  Future<void> _loadOtherIncomeMonthWiseAnalysisRevenue() async {
    // List to hold month-wise expense data for each subgroup.
    List<SubGroupMonthWiseRevenueExpensesData> subGroupMonthWiseDataList = [];

    DateFormat formatter = DateFormat('dd/MM/yyyy');

    // Filter records that are part of "Expenditure".
    List<TrialBalance> expenseRecords = trialBalanceList
        .where((record) => record.foreignName == "Other Income")
        .toList();

    List<TrialBalance> customerTargetList = [];

    customerTargetList = expenseRecords.where((record) {
      // Split the monthYear string into its components:
      final parts = record.monthYear.split('/');
      // Expecting two parts: [month, year]. Use int.parse to convert to integers.
      int month = int.parse(parts[0]);
      int year = int.parse(parts[1]);

      // The first day of the month:
      DateTime fromDt = DateTime(year, month, 1);
      // To safely get the last day of the month, create a date for the first day of the next month,
      // then subtract one day. Note: DateTime(year, month + 1, 0) returns the last day of the month.

      // Now check if the month/date range falls within the fiscal period.
      // If you have a defined fiscalYearEndDate, use that.
      // Here, fiscalYearStartDate and currentDate (or fiscalYearEndDate) are assumed to be non-null.
      bool startsAfterOrOnFiscalStart = !fromDt.isBefore(fiscalYearStartDate!);
      bool endsBeforeOrOnCurrentDate = !fromDt.isAfter(currentDate!);

      return startsAfterOrOnFiscalStart && endsBeforeOrOnCurrentDate;
    }).toList();

    // Process each expense record.
    for (var record in customerTargetList) {
      //
      // Parse the record's month-year by
      // prepending a day (here "01").
      DateTime recordDate = formatter.parse('01/${record.monthYear}');
      int month = recordDate.month;
      // Convert the balance string to a double.
      double recordBalance = double.tryParse(record.balance) ?? 0.0;

      // Find an existing entry for this subgroup using try/catch.
      SubGroupMonthWiseRevenueExpensesData? subgroupData;

      // If no entry exists, create a new one with all balances initialized to 0.0.
      subgroupData = SubGroupMonthWiseRevenueExpensesData(
        subGroupName: "Other Income",
        aprBalance: 0.0,
        mayBalance: 0.0,
        junBalance: 0.0,
        julBalance: 0.0,
        augBalance: 0.0,
        septBalance: 0.0,
        octBalance: 0.0,
        novBalance: 0.0,
        decBalance: 0.0,
        janBalance: 0.0,
        febBalance: 0.0,
        marBalance: 0.0,
      );
      subGroupMonthWiseDataList.add(subgroupData);

      // Update the corresponding month balance based on the record's month.
      // Assuming a financial year from April to March.
      if (month == 4) {
        subgroupData.aprBalance += recordBalance;
      } else if (month == 5) {
        subgroupData.mayBalance += recordBalance;
      } else if (month == 6) {
        subgroupData.junBalance += recordBalance;
      } else if (month == 7) {
        subgroupData.julBalance += recordBalance;
      } else if (month == 8) {
        subgroupData.augBalance += recordBalance;
      } else if (month == 9) {
        subgroupData.septBalance += recordBalance;
      } else if (month == 10) {
        subgroupData.octBalance += recordBalance;
      } else if (month == 11) {
        subgroupData.novBalance += recordBalance;
      } else if (month == 12) {
        subgroupData.decBalance += recordBalance;
      } else if (month == 1) {
        subgroupData.janBalance += recordBalance;
      } else if (month == 2) {
        subgroupData.febBalance += recordBalance;
      } else if (month == 3) {
        subgroupData.marBalance += recordBalance;
      }
    }

    // Inject the data into your SubGroupMonthWiseExpensesList.
    otherIncomeList = SubGroupMonthWiseRevenueExpensesList(
      subGroupData: subGroupMonthWiseDataList,
    );
  }

  Future<void> _loadForeignNameMonthWiseAnalysisRevenue() async {
    DateFormat formatter = DateFormat('dd/MM/yyyy');

    // Filter records within fiscal year and up to current date
    List<TrialBalance> validRecords = trialBalanceList.where((record) {
      final parts = record.monthYear.split('/');
      int month = int.parse(parts[0]);
      int year = int.parse(parts[1]);
      DateTime fromDt = DateTime(year, month, 1);
      return !fromDt.isBefore(fiscalYearStartDate!) &&
          !fromDt.isAfter(currentDate!);
    }).toList();

    // Split into two categories
    List<TrialBalance> indirectExpenseRecords = validRecords
        .where((r) => r.category == 'Indirect Expenses')
        .toList();

    List<TrialBalance> otherIndirectExpenseRecords = validRecords
        .where((r) => r.category == 'Other Indirect Expenses')
        .toList();

    List<TrialBalance> directExpenseRecords = validRecords
        .where((r) => r.category == 'Direct Expenses')
        .toList();

    // Helper function to process a list and generate month-wise balances
    SubGroupMonthWiseRevenueExpensesList processExpenseRecords(
      List<TrialBalance> records,
    ) {
      List<SubGroupMonthWiseRevenueExpensesData> dataList = [];

      for (var record in records) {
        DateTime recordDate = formatter.parse('01/${record.monthYear}');
        int month = recordDate.month;
        double recordBalance = double.tryParse(record.balance) ?? 0.0;

        var existing = dataList.firstWhere(
          (e) => e.subGroupName == record.foreignName,
          orElse: () {
            final newEntry = SubGroupMonthWiseRevenueExpensesData(
              subGroupName: record.foreignName,
              aprBalance: 0.0,
              mayBalance: 0.0,
              junBalance: 0.0,
              julBalance: 0.0,
              augBalance: 0.0,
              septBalance: 0.0,
              octBalance: 0.0,
              novBalance: 0.0,
              decBalance: 0.0,
              janBalance: 0.0,
              febBalance: 0.0,
              marBalance: 0.0,
            );
            dataList.add(newEntry);
            return newEntry;
          },
        );

        switch (month) {
          case 4:
            existing.aprBalance += recordBalance;
            break;
          case 5:
            existing.mayBalance += recordBalance;
            break;
          case 6:
            existing.junBalance += recordBalance;
            break;
          case 7:
            existing.julBalance += recordBalance;
            break;
          case 8:
            existing.augBalance += recordBalance;
            break;
          case 9:
            existing.septBalance += recordBalance;
            break;
          case 10:
            existing.octBalance += recordBalance;
            break;
          case 11:
            existing.novBalance += recordBalance;
            break;
          case 12:
            existing.decBalance += recordBalance;
            break;
          case 1:
            existing.janBalance += recordBalance;
            break;
          case 2:
            existing.febBalance += recordBalance;
            break;
          case 3:
            existing.marBalance += recordBalance;
            break;
        }
      }

      return SubGroupMonthWiseRevenueExpensesList(subGroupData: dataList);
    }

    // Generate final lists
    foreignNameMonthExpenseWiseList = processExpenseRecords(
      indirectExpenseRecords,
    );
    otherIndirectExpensesList = processExpenseRecords(
      otherIndirectExpenseRecords,
    );
    directExpensesList = processExpenseRecords(directExpenseRecords);

    // Sum each month's direct expenses
    SubGroupMonthWiseRevenueExpensesData sumOfDirectExpenses =
        SubGroupMonthWiseRevenueExpensesData(
          subGroupName: "Total Direct Expenses",
          aprBalance: 0.0,
          mayBalance: 0.0,
          junBalance: 0.0,
          julBalance: 0.0,
          augBalance: 0.0,
          septBalance: 0.0,
          octBalance: 0.0,
          novBalance: 0.0,
          decBalance: 0.0,
          janBalance: 0.0,
          febBalance: 0.0,
          marBalance: 0.0,
        );

    for (var entry in directExpensesList.subGroupData) {
      sumOfDirectExpenses.aprBalance += entry.aprBalance;
      sumOfDirectExpenses.mayBalance += entry.mayBalance;
      sumOfDirectExpenses.junBalance += entry.junBalance;
      sumOfDirectExpenses.julBalance += entry.julBalance;
      sumOfDirectExpenses.augBalance += entry.augBalance;
      sumOfDirectExpenses.septBalance += entry.septBalance;
      sumOfDirectExpenses.octBalance += entry.octBalance;
      sumOfDirectExpenses.novBalance += entry.novBalance;
      sumOfDirectExpenses.decBalance += entry.decBalance;
      sumOfDirectExpenses.janBalance += entry.janBalance;
      sumOfDirectExpenses.febBalance += entry.febBalance;
      sumOfDirectExpenses.marBalance += entry.marBalance;
    }

    // Now `sumOfDirectExpenses` holds total direct expense per month
    sumOfDirectExpensesList = SubGroupMonthWiseRevenueExpensesList(
      subGroupData: [sumOfDirectExpenses],
    );

    List<TrialBalance> allIndirectRecords = [
      ...indirectExpenseRecords,
      ...otherIndirectExpenseRecords,
    ];

    SubGroupMonthWiseRevenueExpensesList combinedIndirectList =
        processExpenseRecords(allIndirectRecords);

    SubGroupMonthWiseRevenueExpensesData sumOfIndirectExpenses =
        SubGroupMonthWiseRevenueExpensesData(
          subGroupName: "Total Indirect Expenses",
          aprBalance: 0.0,
          mayBalance: 0.0,
          junBalance: 0.0,
          julBalance: 0.0,
          augBalance: 0.0,
          septBalance: 0.0,
          octBalance: 0.0,
          novBalance: 0.0,
          decBalance: 0.0,
          janBalance: 0.0,
          febBalance: 0.0,
          marBalance: 0.0,
        );

    // Sum up all subgroup entries in the combined list
    for (var entry in combinedIndirectList.subGroupData) {
      sumOfIndirectExpenses.aprBalance += entry.aprBalance;
      sumOfIndirectExpenses.mayBalance += entry.mayBalance;
      sumOfIndirectExpenses.junBalance += entry.junBalance;
      sumOfIndirectExpenses.julBalance += entry.julBalance;
      sumOfIndirectExpenses.augBalance += entry.augBalance;
      sumOfIndirectExpenses.septBalance += entry.septBalance;
      sumOfIndirectExpenses.octBalance += entry.octBalance;
      sumOfIndirectExpenses.novBalance += entry.novBalance;
      sumOfIndirectExpenses.decBalance += entry.decBalance;
      sumOfIndirectExpenses.janBalance += entry.janBalance;
      sumOfIndirectExpenses.febBalance += entry.febBalance;
      sumOfIndirectExpenses.marBalance += entry.marBalance;
    }

    // Store as list if needed
    totalIndirectExpensesList = SubGroupMonthWiseRevenueExpensesList(
      subGroupData: [sumOfIndirectExpenses],
    );
  }

  Future<void> _loadSubGroupWiseAnalysis(
    int monthIndex,
    String? group,
    String? subGroup,
  ) async {
    List<SubGroupWiseAnalysisExpensesData> subGroupWiseDataList = [];
    List<TrialBalance> customerTargetList = [];
    double balance = 0.0;
    String subGroupName = "";

    if (monthIndex == 0) {
      DateFormat formatter = DateFormat('dd/MM/yyyy');
      customerTargetList = trialBalanceList.where((target) {
        DateTime fromDt = formatter.parse('01/${target.monthYear}');
        DateTime toDt = formatter.parse('31/${target.monthYear}');
        return fromDt.isAtLeast(fiscalYearStartDate!) &&
            toDt.isAtMost(currentDate!);
      }).toList();

      Set<String> processedSubGroupCodes = {};

      for (var customer
          in customerTargetList
              .where((customer) => customer.group == "Expenditure")
              .toList()) {
        if (!processedSubGroupCodes.contains(customer.subGroup)) {
          subGroupName = customer.subGroup;
          for (var sales in customerTargetList.where(
            (saleelement) => saleelement.subGroup == subGroupName,
          )) {
            balance += double.tryParse(sales.balance) ?? 0;
          }

          subGroupWiseDataList.add(
            SubGroupWiseAnalysisExpensesData(
              subGroupName: subGroupName,
              balance: balance,
            ),
          );
          balance = 0;
          processedSubGroupCodes.add(subGroupName);
        }
      }
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      DateFormat formatter = DateFormat('dd/MM/yyyy');
      customerTargetList = trialBalanceList.where((target) {
        DateTime fromDt = formatter.parse('01/${target.monthYear}');
        DateTime toDt = formatter.parse('31/${target.monthYear}');
        return fromDt.isAtLeast(monthDates['start']!) &&
            toDt.isAtMost(monthDates['end']!);
      }).toList();

      // customerTargetList = filterExpensesList(
      //   customerTargetList.cast<ExpensesList>().toList(),
      //   group: group,
      //   subGroup: subGroup,
      // );

      Set<String> processedSubGroupCodes = {};

      for (var customer
          in customerTargetList
              .where((customer) => customer.group == "Expenditure")
              .toList()) {
        if (!processedSubGroupCodes.contains(customer.subGroup)) {
          subGroupName = customer.subGroup;
          for (var sales in customerTargetList.where(
            (saleelement) => saleelement.subGroup == subGroupName,
          )) {
            balance += double.tryParse(sales.balance) ?? 0;
          }

          subGroupWiseDataList.add(
            SubGroupWiseAnalysisExpensesData(
              subGroupName: subGroupName,
              balance: balance,
            ),
          );
          balance = 0;
          processedSubGroupCodes.add(subGroupName);
        }
      }
    }

    subGroupWiseDataList.sort(
      (a, b) => b.balance.abs().compareTo(a.balance.abs()),
    );
    subGroupList = SubGroupWiseAnalysisExpensesList(
      subGroupData: subGroupWiseDataList,
    );
  }

  Future<void> _loadMonthlyAnalysisExpenditure() async {
    List<DailyAnalysisExpensesData> groupWiseDataList = [];
    List<TrialBalance> customerTargetList = [];
    double balance = 0.0;
    String monthYear = "";
    double balanceAmount = 0.0;

    List<TrialBalance> records = trialBalanceList
        .where(
          (record) =>
              record.group ==
              "Expenditure" /*&& record.monthYear.contains("2025")*/,
        )
        .toList();

    customerTargetList = records.where((record) {
      // Split the monthYear string into its components:
      final parts = record.monthYear.split('/');
      // Expecting two parts: [month, year]. Use int.parse to convert to integers.
      int month = int.parse(parts[0]);
      int year = int.parse(parts[1]);

      // The first day of the month:
      DateTime fromDt = DateTime(year, month, 1);
      // To safely get the last day of the month, create a date for the first day of the next month,
      // then subtract one day. Note: DateTime(year, month + 1, 0) returns the last day of the month.

      // Now check if the month/date range falls within the fiscal period.
      // If you have a defined fiscalYearEndDate, use that.
      // Here, fiscalYearStartDate and currentDate (or fiscalYearEndDate) are assumed to be non-null.
      bool startsAfterOrOnFiscalStart = !fromDt.isBefore(fiscalYearStartDate!);
      bool endsBeforeOrOnCurrentDate = !fromDt.isAfter(currentDate!);

      return startsAfterOrOnFiscalStart && endsBeforeOrOnCurrentDate;
    }).toList();

    List tempList = [];

    tempList = customerTargetList.toList();

    Set<String> processedCustomerCodes = {};
    for (var customer in tempList) {
      if (!processedCustomerCodes.contains(customer.monthYear)) {
        monthYear = customer.monthYear;
        for (var sales in tempList.where(
          (saleelement) => saleelement.monthYear == monthYear,
        )) {
          balance = double.tryParse(sales.balance) ?? 0;
          balanceAmount += balance;
        }
        groupWiseDataList.add(
          DailyAnalysisExpensesData(balance: balanceAmount, date: monthYear),
        );
        processedCustomerCodes.add(monthYear);
      }
      balanceAmount = 0;
    }

    expenditureMonthlyData = DailyAnalysisExpensesList(
      dailyData: groupWiseDataList,
    );
  }

  Future<void> _loadMonthlyAnalysisRevenue() async {
    List<DailyAnalysisExpensesData> groupWiseDataList = [];
    List<TrialBalance> customerTargetList = [];
    double balance = 0.0;
    String monthYear = "";
    double balanceAmount = 0.0;

    List<TrialBalance> records = trialBalanceList
        .where((record) => record.group == "Revenue")
        .toList();

    customerTargetList = records.where((record) {
      // Split the monthYear string into its components:
      final parts = record.monthYear.split('/');
      // Expecting two parts: [month, year]. Use int.parse to convert to integers.
      int month = int.parse(parts[0]);
      int year = int.parse(parts[1]);

      // The first day of the month:
      DateTime fromDt = DateTime(year, month, 1);
      // To safely get the last day of the month, create a date for the first day of the next month,
      // then subtract one day. Note: DateTime(year, month + 1, 0) returns the last day of the month.

      // Now check if the month/date range falls within the fiscal period.
      // If you have a defined fiscalYearEndDate, use that.
      // Here, fiscalYearStartDate and currentDate (or fiscalYearEndDate) are assumed to be non-null.
      bool startsAfterOrOnFiscalStart = fromDt.isAtLeast(fiscalYearStartDate!);
      bool endsBeforeOrOnCurrentDate = fromDt.isAtMost(currentDate!);

      return startsAfterOrOnFiscalStart && endsBeforeOrOnCurrentDate;
    }).toList();

    List tempList = [];

    tempList = customerTargetList.toList();

    Set<String> processedCustomerCodes = {};
    for (var customer in tempList) {
      if (!processedCustomerCodes.contains(customer.monthYear)) {
        monthYear = customer.monthYear;
        for (var sales in tempList.where(
          (saleelement) => saleelement.monthYear == monthYear,
        )) {
          balance = double.tryParse(sales.balance) ?? 0;
          balanceAmount += balance.abs();
        }
        groupWiseDataList.add(
          DailyAnalysisExpensesData(balance: balanceAmount, date: monthYear),
        );
        processedCustomerCodes.add(monthYear);
      }
      balanceAmount = 0;
    }

    revenueMonthlyData = DailyAnalysisExpensesList(
      dailyData: groupWiseDataList,
    );
  }

  Future<void> _loadMonthlyAnalysisPurchase() async {
    final List<SalesTargetList> tempTarget = salesTarget
        .where((t) => t.financialYear == getCurrentFinancialYearSuffix())
        .toList();

    List<DailyAnalysisExpensesData> groupWiseDataList = [];

    List<GRNList> filteredRecords = grnList.where((record) {
      DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(record.grnDate);
      return invoiceDate.isAtLeast(
            dateFilterFlag ? fromDateFilter! : fiscalYearStartDate!,
          ) &&
          invoiceDate.isAtMost(dateFilterFlag ? toDateFilter! : currentDate!);
    }).toList();

    Map<String, double> monthlyBalanceMap = {};
    for (var record in filteredRecords) {
      DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(record.grnDate);
      String monthYearKey = DateFormat('MM/yyyy').format(invoiceDate);
      double balance = double.tryParse(record.rowTotal) ?? 0.0;
      monthlyBalanceMap[monthYearKey] =
          (monthlyBalanceMap[monthYearKey] ?? 0.0) + balance.abs();
    }

    monthlyBalanceMap.forEach((monthYear, totalBalance) {
      // Parse month integer out of "MM/yyyy"
      final parts = monthYear.split('/');
      final int month = int.parse(parts[0]);
      final String monthName = getMonthName(month);

      // Sum up all "PURCHASE TARGET" entries for this month
      double monthlyTarget = tempTarget
          .where((t) => t.salesRep == "PURCHASE TARGET")
          .map((t) => double.tryParse(t.getTargetForMonth(monthName)) ?? 0.0)
          .fold(0.0, (sum, v) => sum + v);

      groupWiseDataList.add(
        DailyAnalysisExpensesData(
          balance: totalBalance,
          date: monthYear,
          target: monthlyTarget,
        ),
      );
    });

    purchaseMonthlyData = DailyAnalysisExpensesList(
      dailyData: groupWiseDataList,
    );

    monthlyCogsList = calculateMonthlyCogs(
      inventoryList: monthWiseInventory,
      purchaseMonthlyData: purchaseMonthlyData.dailyData,
      targetMap: monthlyMap,
    );

    monthlyCOGS = MonthlyCogsList(monthlyData: monthlyCogsList);
  }

  Future<void> _loadMonthlyAnalysisInventory() async {
    List<DailyAnalysisExpensesData> groupWiseDataList = [];

    List<InventoryList> inventoryTemp = [];
    List<InventoryList> inventoryClosingTemp = [];

    inventoryTemp = inventory;
    for (var target in inventoryTemp) {
      if (target.ageingBrackets == "<30 Days") {
        lessThan30DaysValue += (double.tryParse(target.totalValue) ?? 0);
      }
      if (target.ageingBrackets == "31-45 Days" ||
          target.ageingBrackets == "31-45 Days") {
        a30to60DaysValue += (double.tryParse(target.totalValue) ?? 0);
      }
      if (target.ageingBrackets == "61-90 Days") {
        a60to90DaysValue += (double.tryParse(target.totalValue) ?? 0);
      }
      if (target.ageingBrackets == "91-120 Days" ||
          target.ageingBrackets == "121-150 Days" ||
          target.ageingBrackets == "151-180 Days" ||
          target.ageingBrackets == "181-365 Days" ||
          target.ageingBrackets == "366-730 Days" ||
          target.ageingBrackets == ">730 Days") {
        a91DaysValue += (double.tryParse(target.totalValue) ?? 0);
      }
      if (target.ageingBrackets == "91-120 Days" ||
          target.ageingBrackets == "121-150 Days" ||
          target.ageingBrackets == "151-180 Days") {
        nearExpiryValue += (double.tryParse(target.totalValue) ?? 0);
      }
      if (target.ageingBrackets == "181-365 Days" ||
          target.ageingBrackets == "366-730 Days" ||
          target.ageingBrackets == ">730 Days") {
        expiredValue += (double.tryParse(target.totalValue) ?? 0);
      }

      inventoryOpeningValue += (double.parse(target.totalValue));
    }

    inventoryClosingTemp = inventoryClosing;
    for (var target in inventoryClosingTemp) {
      inventoryClosingValue += (double.parse(target.totalValue));
    }

    // Filter records based on the invoice date falling within the specified fiscal year.
    List<InventoryList> filteredRecords = inventory;

    // Create a Map to group balances by month-year.
    // Key: month-year string (e.g. "08/2024")
    // Value: accumulated balance for that month.

    double balance = 0;

    // Iterate over the filtered records to group and sum balances.
    for (var record in filteredRecords) {
      balance += double.tryParse(record.totalValue) ?? 0.0;
      // Sum the absolute value of balances.
    }

    // Convert each group into DailyAnalysisExpensesData.
    groupWiseDataList.add(
      DailyAnalysisExpensesData(balance: balance, date: "Apr"),
    );

    // Assign the calculated data to the revenueMonthlyData.
    inventoryMonthlyData = DailyAnalysisExpensesList(
      dailyData: groupWiseDataList,
    );
  }

  Future<void> _loadMonthlyAnalysisInventoryClosing() async {
    List<DailyAnalysisExpensesData> groupWiseDataList = [];

    // Filter records based on the invoice date falling within the specified fiscal year.
    List<InventoryList> filteredRecords = inventory;

    // Create a Map to group balances by month-year.
    // Key: month-year string (e.g. "08/2024")
    // Value: accumulated balance for that month.
    double balance = 0;

    // Iterate over the filtered records to group and sum balances.
    for (var record in filteredRecords) {
      balance += double.tryParse(record.totalValue) ?? 0.0;
      // Sum the absolute value of balances.
    }

    // Convert each group into DailyAnalysisExpensesData.
    groupWiseDataList.add(
      DailyAnalysisExpensesData(
        balance: balance,
        date: (DateTime.now().month - 1).toString(),
      ),
    );

    // Assign the calculated data to the revenueMonthlyData.
    inventoryClosingMonthlyData = DailyAnalysisExpensesList(
      dailyData: groupWiseDataList,
    );
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

  SideTitles get _emptyTitlesTop =>
      SideTitles(showTitles: true, getTitlesWidget: getEmptyTopTitle);

  SideTitles get _leftTitles => SideTitles(
    reservedSize: 50,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String leftDouble = "";
      leftDouble = value.toString();
      return Text(
        formatAmount(double.parse(leftDouble)),
        style: const TextStyle(fontSize: 12),
      );
    },
  );

  Widget getEmptyTopTitle(double val, TitleMeta meta) {
    return const Text("");
  }

  SideTitles get _bottomTitlesRevenue => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<MonthlySalesData> mData = monthlySalesList.monthlyData;
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

  SideTitles get _bottomTitlesPurchase => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<DailyAnalysisExpensesData> mData = purchaseMonthlyData.dailyData;
      text = mData.elementAt(value.toInt()).date;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesExpenditure => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<DailyAnalysisExpensesData> mData = expenditureMonthlyData.dailyData;
      text = mData.elementAt(value.toInt()).date;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesInventory => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<MonthlyCogsData> mData = monthlyCogsList;
      text = mData.elementAt(value.toInt()).monthYear;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesCogs => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<MonthlyCogsData> mData = monthlyCogsList;
      text = mData.elementAt(value.toInt()).monthYear;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  List<BarChartGroupData> _monthlyAnalysisChartData(
    List<MonthlySalesData> data,
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
                width: 15,
              ),
              BarChartRodData(
                color: Colors.blue,
                borderRadius: BorderRadius.zero,
                toY: chartData.salesTarget,
                width: 15,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _monthlyAnalysisPurchaseChartData(
    List<DailyAnalysisExpensesData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.balance,
                width: 15,
              ),
              BarChartRodData(
                color: Colors.blue,
                borderRadius: BorderRadius.zero,
                toY: chartData.target ?? 0,
                width: 15,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _monthlyAnalysisExpenditureChartData(
    List<DailyAnalysisExpensesData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.balance,
                width: 15,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _monthlyAnalysisInventoryChartData(
    List<MonthlyCogsData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.openingStock,
                width: 10,
              ),
              BarChartRodData(
                color: Colors.green,
                borderRadius: BorderRadius.zero,
                toY: chartData.closingStock,
                width: 10,
              ),
              BarChartRodData(
                color: Colors.blue,
                borderRadius: BorderRadius.zero,
                toY: chartData.inventoryTarget ?? 0,
                width: 10,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _monthlyAnalysisCogsChartData(
    List<MonthlyCogsData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.cogs,
                width: 15,
              ),
              BarChartRodData(
                color: Colors.blue,
                borderRadius: BorderRadius.zero,
                toY: chartData.cogsTarget ?? 0,
                width: 15,
              ),
            ],
          ),
        )
        .toList();
  }

  void loadDates() {
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

  double getPercentage(double? value, double? total) {
    if (value == null || value == 0 || total == null || total == 0) {
      return 0.0;
    }

    double rawPercentage = (value / total) * 100;

    double roundedPercentage = (rawPercentage * 100).round() / 100.0;

    return roundedPercentage;
  }

  int getCurrentFinancialMonthIndex() {
    final now = DateTime.now();
    return (now.month - 4 + 12) % 12;
  }

  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
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
    loadDataFuture = loadData("");
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
        currentQuarterFromDate = DateTime(now.year - 1, 1, 1);
        currentQuarterToDate = DateTime(now.year - 1, 3, 31);
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

  void clearVariables() {
    setState(() {
      dateFilterFlag = false;
      toDateFilter = currentDate;
      fromDateFilter = fiscalYearStartDate;
      chartDataLoadedMonthlyPl = false;
      groupList = GroupWiseAnalysisExpensesList(groupData: []);
      subGroupList = SubGroupWiseAnalysisExpensesList(subGroupData: []);
      expenditureMonthlyData = DailyAnalysisExpensesList(dailyData: []);
      revenueMonthlyData = DailyAnalysisExpensesList(dailyData: []);
      purchaseMonthlyData = DailyAnalysisExpensesList(dailyData: []);
      inventoryMonthlyData = DailyAnalysisExpensesList(dailyData: []);
      inventoryClosingMonthlyData = DailyAnalysisExpensesList(dailyData: []);
      subGroupMonthWiseList = SubGroupMonthWiseExpensesList(subGroupData: []);
      subGroupMonthExpenseWiseList = SubGroupMonthWiseRevenueExpensesList(
        subGroupData: [],
      );
      foreignNameMonthExpenseWiseList = SubGroupMonthWiseRevenueExpensesList(
        subGroupData: [],
      );
      otherIncomeList = SubGroupMonthWiseRevenueExpensesList(subGroupData: []);
    });
  }

  void toggleCheckbox() {
    setState(() {
      chartDataLoadedMonthlyPl = false;
      loadData("");
      // selectedCheckbox = index;
    });
  }

  Future<void> _dateFilterTarget() async {
    sales = salesTemp;
    trialBalanceList = trialBalanceListTemp;
    purchasePrice = purchasePriceTemp;
    DateFormat formatter = DateFormat('dd/MM/yyyy');

    setState(() {
      context.read<TrialBalanceProvider>().updateTrialBalanceList(
        trialBalanceList,
      );
      context.read<SalesMonthlyPLProvider>().updateSalesList(sales);
      context.read<PurchaseMonthlyPLProvider>().updatePurchaseList(
        purchasePrice,
      );
      context.read<InventoryMonthlyPLProvider>().updateInventoryList(inventory);
      context.read<InventoryClosingMonthlyPLProvider>().updateInventoryList(
        inventoryClosing,
      );

      trialBalanceList = trialBalanceList.where((target) {
        DateTime toDt = formatter.parse('31/${target.monthYear}');
        return (toDt.isAtLeast(fromDateFilter!) &&
            toDt.isAtMost(toDateFilter!));
      }).toList();

      sales = sales.where((target) {
        DateTime dueon = target.invoiceDate;
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();

      purchasePrice = purchasePrice.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();
    });
  }

  Future<void> filterDateFunction() async {
    await _dateFilterTarget();
    await Future.wait([
      _loadSubGroupWiseAnalysis(0, "", ""),
      _loadMonthlyAnalysisExpenditure(),
      _loadMonthlySalesBarChartData(),
      _loadMonthlyAnalysisRevenue(),
      _loadMonthlyAnalysisPurchase(),
      _loadMonthlyAnalysisInventory(),
      _loadMonthlyAnalysisInventoryClosing(),
      _loadSubGroupMonthWiseAnalysisExpenditure(),
      _loadSubGroupMonthWiseAnalysisRevenue(),
      _loadOtherIncomeMonthWiseAnalysisRevenue(),
      _loadForeignNameMonthWiseAnalysisRevenue(),
    ]);
    setState(() {});
    chartDataLoadedMonthlyPl = true;
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

  Future<void> generateSalesAnalysisYTDExcel() async {
    try {
      // ---------------- HEADER ----------------
      final months = [
        'Apr',
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
      ];

      List<String> headers = ['Particulars'];
      for (var m in months) {
        headers.addAll(['Target - $m', m, '%']);
      }
      headers.add('YTD');

      List<List<dynamic>> rows = [];

      // ---------------- HELPERS ----------------
      double calcYTD(List<num> values) => values.fold(0.0, (sum, v) => sum + v);

      List<num> getSales() => List.generate(
        12,
        (i) => i < monthlySalesList.monthlyData.length
            ? monthlySalesList.monthlyData[i].salesAmount
            : 0,
      );

      List<num> getTargets(String key) => List.generate(12, (i) {
        final mapIndex = (i + 3) % 12;
        return monthlyMap[key]?[mapIndex] ?? 0;
      });

      List<num> getMonthBalances(dynamic d) => [
        d.aprBalance,
        d.mayBalance,
        d.junBalance,
        d.julBalance,
        d.augBalance,
        d.septBalance,
        d.octBalance,
        d.novBalance,
        d.decBalance,
        d.janBalance,
        d.febBalance,
        d.marBalance,
      ];

      List<dynamic> buildRow({
        required String title,
        required List<num> targets,
        required List<num> values,
        List<num>? percentageBase,
      }) {
        List<dynamic> row = [title];

        for (int i = 0; i < 12; i++) {
          double t = targets[i].toDouble();
          double v = values[i].toDouble();

          final pct = (percentageBase != null && percentageBase[i] != 0)
              ? getPercentage(v, percentageBase[i].toDouble())
              : "";

          row.addAll([t, v, pct]);
        }

        row.add(calcYTD(values));
        return row;
      }

      void addSection(String title) {
        rows.add([title, ...List.filled(headers.length - 1, "")]);
      }

      void addSpacer() {
        rows.add(List.filled(headers.length, ""));
      }

      final sales = getSales();

      // ---------------- REVENUE ----------------
      addSection("Revenue");

      final revenueTargets = List.generate(12, (i) {
        final mapIndex = (i + 3) % 12;

        return (monthlyMap["IPD SALES TARGET"]?[mapIndex] ?? 0) +
            (monthlyMap["MD SALES TARGET"]?[mapIndex] ?? 0);
      });

      rows.add(
        buildRow(
          title: "Revenue",
          targets: revenueTargets,
          values: sales,
          percentageBase: revenueTargets,
        ),
      );

      final otherIncome = otherIncomeList.subGroupData.isNotEmpty
          ? getMonthBalances(otherIncomeList.subGroupData.first)
          : List.filled(12, 0);

      rows.add(
        buildRow(
          title: "Other Income",
          targets: List.filled(12, 0),
          values: otherIncome,
          percentageBase: sales,
        ),
      );

      final totalRevenue = List.generate(12, (i) => sales[i] + otherIncome[i]);

      rows.add(
        buildRow(
          title: "Total Revenue",
          targets: List.filled(12, 0),
          values: totalRevenue,
          percentageBase: sales,
        ),
      );
      addSpacer();
      // ---------------- INVENTORY / COGS ----------------
      addSection("Inventory & COGS");

      final openingStock = List.generate(
        12,
        (i) => i < monthlyCogsList.length ? monthlyCogsList[i].openingStock : 0,
      );

      final purchases = List.generate(
        12,
        (i) => i < monthlyCogsList.length ? monthlyCogsList[i].purchases : 0,
      );

      final closingStock = List.generate(
        12,
        (i) => i < monthlyCogsList.length ? monthlyCogsList[i].closingStock : 0,
      );

      final cogs = List.generate(
        12,
        (i) => i < monthlyCogsList.length ? monthlyCogsList[i].cogs : 0,
      );

      rows.add(
        buildRow(
          title: "Opening Stock",
          targets: getTargets("INVENTORY TARGET"),
          values: openingStock,
        ),
      );

      rows.add(
        buildRow(
          title: "Add: Purchases",
          targets: getTargets("PURCHASE TARGET"),
          values: purchases,
        ),
      );

      rows.add(
        buildRow(
          title: "Less: Closing Stock",
          targets: getTargets("INVENTORY TARGET"),
          values: closingStock,
        ),
      );

      rows.add(
        buildRow(
          title: "COGS",
          targets: getTargets("COGS TARGET"),
          values: cogs,
          percentageBase: totalRevenue,
        ),
      );

      // ---------------- EXPENSES ----------------
      addSection("Expenses");
      addSpacer();

      // ---------------- DIRECT EXPENSES ----------------
      addSection("Direct Expenses");

      for (var item in directExpensesList.subGroupData) {
        final values = getMonthBalances(item);

        rows.add(
          buildRow(
            title: item.subGroupName,
            targets: List.filled(12, 0),
            values: values,
            percentageBase: sales,
          ),
        );
      }

      List<num> direct = sumOfDirectExpensesList.subGroupData.isNotEmpty
          ? getMonthBalances(sumOfDirectExpensesList.subGroupData.first)
          : List.filled(12, 0);

      if (direct.isNotEmpty) {
        rows.add(
          buildRow(
            title: "Total Direct Expenses",
            targets: List.filled(12, 0),
            values: direct,
            percentageBase: sales,
          ),
        );
        addSpacer();
      }

      // ---------------- INDIRECT EXPENSES ----------------
      addSection("Indirect Expenses");

      for (var item in otherIndirectExpensesList.subGroupData) {
        rows.add(
          buildRow(
            title: item.subGroupName,
            targets: List.filled(12, 0),
            values: getMonthBalances(item),
            percentageBase: sales,
          ),
        );
      }

      for (var item in foreignNameMonthExpenseWiseList.subGroupData) {
        rows.add(
          buildRow(
            title: item.subGroupName,
            targets: List.filled(12, 0),
            values: getMonthBalances(item),
            percentageBase: sales,
          ),
        );
      }

      List<num> indirect1 = totalIndirectExpensesList.subGroupData.isNotEmpty
          ? getMonthBalances(totalIndirectExpensesList.subGroupData.first)
          : List.filled(12, 0);

      List<num> indirect2 =
          foreignNameMonthExpenseWiseList.subGroupData.isNotEmpty
          ? getMonthBalances(foreignNameMonthExpenseWiseList.subGroupData.first)
          : List.filled(12, 0);

      // element-wise sum
      List<num> totalIndirect = List.generate(
        12,
        (i) => indirect1[i] + indirect2[i],
      );

      if (totalIndirect.isNotEmpty) {
        rows.add(
          buildRow(
            title: "Total Indirect Expenses",
            targets: List.filled(12, 0),
            values: totalIndirect,
            percentageBase: sales,
          ),
        );
      }

      List<num> totalExpenditure = List.generate(
        12,
        (i) => direct[i] + indirect1[i] + indirect2[i],
      );
      rows.add(
        buildRow(
          title: "Total Operating Expenses",
          targets: List.filled(12, 0),
          values: totalExpenditure,
          percentageBase: sales,
        ),
      );

      addSpacer();
      // ---------------- EBITDA / PBT / PAT ----------------
      addSection("Profitability");

      final finance = foreignNameMonthExpenseWiseList.subGroupData.firstWhere(
        (e) => e.subGroupName == 'Finance Costs',
      );

      final financeVals = getMonthBalances(finance);
      final directVals = sumOfDirectExpensesList.subGroupData.isNotEmpty
          ? getMonthBalances(sumOfDirectExpensesList.subGroupData.first)
          : List.filled(12, 0);

      final indirectVals = totalIndirectExpensesList.subGroupData.isNotEmpty
          ? getMonthBalances(totalIndirectExpensesList.subGroupData.first)
          : List.filled(12, 0);

      List<num> ebitda = [];
      List<num> pbt = [];
      List<num> pat = [];

      for (int i = 0; i < 12; i++) {
        final e =
            financeVals[i] +
            ((totalRevenue[i]) - cogs[i] - directVals[i] - indirectVals[i]) +
            25000;

        final p = totalRevenue[i] - cogs[i] - directVals[i] - indirectVals[i];
        final pa = totalExpenditure[i] - totalRevenue[i];

        ebitda.add(e);
        pbt.add(p);
        pat.add(pa);
      }

      rows.add(
        buildRow(
          title: "EBITDA",
          targets: List.filled(12, 0),
          values: ebitda,
          percentageBase: sales,
        ),
      );

      rows.add(
        buildRow(
          title: "PBT",
          targets: List.filled(12, 0),
          values: pbt,
          percentageBase: sales,
        ),
      );

      rows.add(
        buildRow(
          title: "PAT",
          targets: List.filled(12, 0),
          values: pat,
          percentageBase: sales,
        ),
      );

      // ---------------- EXPORT ----------------
      await reportService.generateExcel(
        sheetName: 'DetailedP&L',
        headers: headers,
        rows: rows,
        fileName: 'detailed_p&l.xlsx',
        amountColumns: List.generate(headers.length, (i) => i + 1),
        reportTitle: 'Finance - Detailed P&L',
        enableStyling: true,
        highlightSections: true,
        highlightProfitability: true,
        highlightNegative: true,
      );
    } catch (e) {
      debugPrint("Excel Error: $e");
    }
  }

  Future<void> generateSummarySalesAnalysisYTDExcel() async {
    try {
      // ---------------- HEADER ----------------
      final headers = [
        'Particulars',
        'Target (Lakhs)',
        'Actual (Lakhs)',
        '% Achieved',
      ];

      List<List<dynamic>> rows = [];

      // ---------------- HELPERS ----------------

      double toLakhs(double value) => value / 100000;

      double calcPct(double actual, double target) {
        if (target == 0) return 0;
        return (actual / target) * 100;
      }

      double getBalanceForMonth(
        SubGroupMonthWiseRevenueExpensesData data,
        int index,
      ) {
        return [
          data.aprBalance,
          data.mayBalance,
          data.junBalance,
          data.julBalance,
          data.augBalance,
          data.septBalance,
          data.octBalance,
          data.novBalance,
          data.decBalance,
          data.janBalance,
          data.febBalance,
          data.marBalance,
        ][index];
      }

      List<dynamic> buildRow({
        required String title,
        double? target,
        double? actual,
        bool isPercentageRow = false,
      }) {
        if (isPercentageRow) {
          return [
            title,
            target != null ? "${target.toStringAsFixed(2)}%" : "",
            actual != null ? "${actual.toStringAsFixed(2)}%" : "",
            "",
          ];
        }

        return [
          title,
          target != null ? toLakhs(target).toStringAsFixed(2) : "",
          actual != null ? toLakhs(actual).toStringAsFixed(2) : "",
          (target != null && actual != null)
              ? "${calcPct(actual, target).toStringAsFixed(2)}%"
              : "",
        ];
      }

      void addSection(String title) {
        rows.add([title, "", "", ""]);
      }

      // ---------------- DATE INDEX ----------------
      final now = DateTime.now();
      final fiscalMonthIndex = now.month >= 4 ? now.month - 4 : now.month + 8;

      final mapTargetIndex = 3 + fiscalMonthIndex;

      // ---------------- SALES ----------------
      addSection("Revenue");

      double salesTarget =
          (monthlyMap["IPD SALES TARGET"]?[mapTargetIndex] ?? 0) +
          (monthlyMap["MD SALES TARGET"]?[mapTargetIndex] ?? 0);

      double salesActual =
          (fiscalMonthIndex < monthlySalesList.monthlyData.length)
          ? monthlySalesList.monthlyData[fiscalMonthIndex].salesAmount
          : 0.0;

      rows.add(
        buildRow(title: "Net Sales", target: salesTarget, actual: salesActual),
      );

      // ---------------- COGS ----------------
      double cogsTarget = (monthlyMap["COGS TARGET"]?[mapTargetIndex] ?? 0);

      double cogsActual = (fiscalMonthIndex < monthlyCogsList.length)
          ? monthlyCogsList[fiscalMonthIndex].cogs
          : 0.0;

      rows.add(buildRow(title: "COGS", target: cogsTarget, actual: cogsActual));

      // ---------------- GROSS PROFIT ----------------
      double gpTarget = salesTarget - cogsTarget;
      double gpActual = salesActual - cogsActual;

      rows.add(
        buildRow(title: "Gross Profit", target: gpTarget, actual: gpActual),
      );

      // ---------------- GP % ----------------
      rows.add(
        buildRow(
          title: "GP%",
          target: calcPct(gpTarget, salesTarget),
          actual: calcPct(gpActual, salesActual),
          isPercentageRow: true,
        ),
      );

      // ---------------- EXPENSES ----------------
      addSection("Expenses");

      double directExpActual = 0.0;
      if (sumOfDirectExpensesList.subGroupData.isNotEmpty) {
        directExpActual = getBalanceForMonth(
          sumOfDirectExpensesList.subGroupData.first,
          fiscalMonthIndex,
        );
      }

      double indirectExpActual = 0.0;
      if (totalIndirectExpensesList.subGroupData.isNotEmpty) {
        indirectExpActual = getBalanceForMonth(
          totalIndirectExpensesList.subGroupData.first,
          fiscalMonthIndex,
        );
      }

      double totalOpExpActual = directExpActual + indirectExpActual;

      rows.add(
        buildRow(title: "Total Operating Expenses", actual: totalOpExpActual),
      );

      // ---------------- OTHER + FINANCE ----------------
      double financeActual = 0.0;
      try {
        final finance = foreignNameMonthExpenseWiseList.subGroupData.firstWhere(
          (e) => e.subGroupName == 'Finance Costs',
        );
        financeActual = getBalanceForMonth(finance, fiscalMonthIndex);
      } catch (_) {}

      double otherIncomeActual = 0.0;
      if (otherIncomeList.subGroupData.isNotEmpty) {
        otherIncomeActual = getBalanceForMonth(
          otherIncomeList.subGroupData.first,
          fiscalMonthIndex,
        );
      }

      // ---------------- EBITDA ----------------
      addSection("Profitability");

      double ebitdaActual =
          financeActual +
          ((otherIncomeActual + salesActual) -
              cogsActual -
              directExpActual -
              indirectExpActual) +
          25000;

      rows.add(buildRow(title: "EBITDA", actual: ebitdaActual));

      rows.add(
        buildRow(
          title: "EBITDA%",
          actual: calcPct(ebitdaActual, salesActual),
          isPercentageRow: true,
        ),
      );

      // ---------------- EXPORT ----------------
      await reportService.generateExcel(
        sheetName: 'SummaryP&L',
        headers: headers,
        rows: rows,
        fileName: 'CurrentMonth_PL.xlsx',
        amountColumns: [2, 3], // only numeric columns
        reportTitle: 'Finance - Current Month P&L Summary',
        enableStyling: true,
        highlightSections: true,
        highlightProfitability: true,
        highlightNegative: true,
      );
    } catch (e) {
      debugPrint("Summary Excel Error: $e");
    }
  }

  Future<void> generateMonthlyRevenueExcel(MonthlySalesList list) async {
    await reportService.generateExcel(
      sheetName: 'MonthlyRevenue',
      headers: ['Month', 'Revenue', 'Target'],
      rows: list.monthlyData
          .map((e) => [e.monthName, e.salesAmount, e.salesTarget])
          .toList(),
      fileName: 'monthlyRevenue.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'P & L - Monthly Revenue',
    );
  }

  Future<void> generateMonthlyRevenuePDF(MonthlySalesList list) async {
    await reportService.generatePDF(
      title: 'Monthly Revenue',
      headers: ['Month', 'Revenue', 'Target'],
      rows: list.monthlyData
          .map((e) => [e.monthName, e.salesAmount, e.salesTarget])
          .toList(),
      fileName: 'monthly_revenue.pdf',
      amountColumns: [2],
    );
  }

  Future<void> generateMonthlyPurchaseExcel(
    DailyAnalysisExpensesList list,
  ) async {
    await reportService.generateExcel(
      sheetName: 'MonthlyPurchase',
      headers: ['Month', 'Purchase', 'Target'],
      rows: list.dailyData.map((e) => [e.date, e.balance, e.target]).toList(),
      fileName: 'monthly_purchase.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'P & L - Monthly Purchase',
    );
  }

  Future<void> generateMonthlyPurchasePDF(
    DailyAnalysisExpensesList list,
  ) async {
    await reportService.generatePDF(
      title: 'Monthly Purchase',
      headers: ['Month', 'Purchase', 'Target'],
      rows: list.dailyData.map((e) => [e.date, e.balance, e.target]).toList(),
      fileName: 'monthly_purchase.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateMonthlyExpenditureExcel(
    DailyAnalysisExpensesList list,
  ) async {
    await reportService.generateExcel(
      sheetName: 'Monthly Expenditure',
      headers: ['Month', 'Expenditure'],
      rows: list.dailyData.map((e) => [e.date, e.balance]).toList(),
      fileName: 'monthly_expenditure.xlsx',
      amountColumns: [2],
      addTotalRow: true,
      reportTitle: 'P & L - Monthly Expenditure',
    );
  }

  Future<void> generateMonthlyExpenditurePDF(
    DailyAnalysisExpensesList list,
  ) async {
    await reportService.generatePDF(
      title: 'Monthly Expenditure',
      headers: ['Month', 'Expenditure'],
      rows: list.dailyData.map((e) => [e.date, e.balance]).toList(),
      fileName: 'monthly_expenditure.pdf',
      amountColumns: [2],
    );
  }

  Future<void> generateMonthlyInventoryExcel(MonthlyCogsList list) async {
    await reportService.generateExcel(
      sheetName: 'Monthly Inventory',
      headers: ['Month', 'Opening Stock', 'Closing Stock', 'Target'],
      rows: list.monthlyData
          .map(
            (e) => [
              e.monthYear,
              e.openingStock,
              e.closingStock,
              e.inventoryTarget,
            ],
          )
          .toList(),
      fileName: 'monthly_inventory.xlsx',
      amountColumns: [2, 3, 4],
      addTotalRow: true,
      reportTitle: 'P & L - Monthly Inventory',
    );
  }

  Future<void> generateMonthlyInventoryPDF(MonthlyCogsList list) async {
    await reportService.generatePDF(
      title: 'Monthly Inventory',
      headers: ['Month', 'Opening Stock', 'Closing Stock', 'Target'],
      rows: list.monthlyData
          .map(
            (e) => [
              e.monthYear,
              e.openingStock,
              e.closingStock,
              e.inventoryTarget,
            ],
          )
          .toList(),
      fileName: 'monthly_inventory.pdf',
      amountColumns: [2, 3, 4],
    );
  }

  Future<void> generateMonthlyCOGSExcel(MonthlyCogsList list) async {
    await reportService.generateExcel(
      sheetName: 'Monthly COGS',
      headers: ['Month', 'COGS', 'Target'],
      rows: list.monthlyData
          .map((e) => [e.monthYear, e.cogs, e.cogsTarget])
          .toList(),
      fileName: 'monthly_COGS.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'P & L - Monthly COGS',
    );
  }

  Future<void> generateMonthlyCOGSPDF(MonthlyCogsList list) async {
    await reportService.generatePDF(
      title: 'Monthly COGS',
      headers: ['Month', 'COGS', 'Target'],
      rows: list.monthlyData
          .map((e) => [e.monthYear, e.cogs, e.cogsTarget])
          .toList(),
      fileName: 'monthly_COGS.pdf',
      amountColumns: [2, 3],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return chartDataLoadedMonthlyPl == true
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
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  generateSalesAnalysisYTDExcel();
                                },
                                child: const Row(
                                  children: [Text("Download Detailed Excel")],
                                ),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  generateSummarySalesAnalysisYTDExcel();
                                },
                                child: const Row(
                                  children: [Text("Download Summary Excel")],
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
                  padding: const EdgeInsets.fromLTRB(10, 16, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Monthly Revenue",
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
                                      generateMonthlyRevenueExcel(
                                        monthlySalesList,
                                      );
                                    });
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      generateMonthlyRevenuePDF(
                                        monthlySalesList,
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
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _revenueGraph(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 16, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Monthly Purchase",
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
                                      generateMonthlyPurchaseExcel(
                                        purchaseMonthlyData,
                                      );
                                    });
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      generateMonthlyPurchasePDF(
                                        purchaseMonthlyData,
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
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _purchaseGraph(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 16, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Monthly Expenditure",
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
                                      generateMonthlyExpenditureExcel(
                                        expenditureMonthlyData,
                                      );
                                    });
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      generateMonthlyExpenditurePDF(
                                        expenditureMonthlyData,
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
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _expenditureGraph(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 16, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Monthly Inventory",
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
                                      generateMonthlyInventoryExcel(
                                        monthlyCOGS,
                                      );
                                    });
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      generateMonthlyInventoryPDF(monthlyCOGS);
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
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _inventoryGraph(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 16, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Monthly COGS",
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
                                      generateMonthlyCOGSExcel(monthlyCOGS);
                                    });
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      generateMonthlyCOGSPDF(monthlyCOGS);
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
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _cogsGraph(),
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
        setState(() {});
      }
    });
  }

  Widget _revenueGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = monthlySalesList.monthlyData.length;
    if (len > 5) {
      chartWidth = screenWidth + (80 * len);
    } else {
      chartWidth = screenWidth;
    }

    double maxAmount = len > 0
        ? monthlySalesList.monthlyData
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
            maxY: getMaxValue(maxAmount),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesRevenue,
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
            barGroups: _monthlyAnalysisChartData(monthlySalesList.monthlyData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {}
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
                    '${monthlySalesList.monthlyData[grpIndex].monthName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            'Value: ${formatAmount(monthlySalesList.monthlyData[grpIndex].salesAmount)}\n',
                        style: const TextStyle(
                          color: Color(0xFFFF9F47),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Target: ${formatAmount(monthlySalesList.monthlyData[grpIndex].salesTarget)}',
                        style: const TextStyle(
                          color: Colors.blue,
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

  Widget _purchaseGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = purchaseMonthlyData.dailyData.length;
    if (len > 5) {
      chartWidth = screenWidth + (80 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? purchaseMonthlyData.dailyData
              .map((data) => data.balance)
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
                sideTitles: _bottomTitlesPurchase,
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
            barGroups: _monthlyAnalysisPurchaseChartData(
              purchaseMonthlyData.dailyData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {}
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
                    '${purchaseMonthlyData.dailyData[grpIndex].date}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            'Value: ${formatAmount(purchaseMonthlyData.dailyData[grpIndex].balance)}\n',
                        style: const TextStyle(
                          color: Color(0xFFFF9F47),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Target: ${formatAmount(purchaseMonthlyData.dailyData[grpIndex].target ?? 0)}\n',
                        style: const TextStyle(
                          color: Colors.blue,
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

  Widget _expenditureGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = expenditureMonthlyData.dailyData.length;
    if (len > 5) {
      chartWidth = screenWidth + (80 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? expenditureMonthlyData.dailyData
              .map((data) => data.balance)
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
                sideTitles: _bottomTitlesExpenditure,
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
            barGroups: _monthlyAnalysisExpenditureChartData(
              expenditureMonthlyData.dailyData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {}
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
                    '${expenditureMonthlyData.dailyData[grpIndex].date}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            'Value: ${formatAmount(expenditureMonthlyData.dailyData[grpIndex].balance)}\n',
                        style: const TextStyle(
                          color: Color(0xFFFF9F47),
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

  Widget _inventoryGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = monthlyCogsList.length;
    if (len > 5) {
      chartWidth = screenWidth + (200 * len);
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
            // maxY: getMaxValue(maxAmount),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesInventory,
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
            barGroups: _monthlyAnalysisInventoryChartData(monthlyCogsList),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {}
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
                    '${monthlyCogsList[grpIndex].monthYear}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            'Opening Stock: ${formatAmount(monthlyCogsList[grpIndex].openingStock)}\n',
                        style: const TextStyle(
                          color: Color(0xFFFF9F47),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Closing Stock: ${formatAmount(monthlyCogsList[grpIndex].closingStock)}\n',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Target: ${formatAmount(monthlyCogsList[grpIndex].inventoryTarget ?? 0)}',
                        style: const TextStyle(
                          color: Colors.blue,
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

  Widget _cogsGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = monthlyCogsList.length;
    if (len > 5) {
      chartWidth = screenWidth + (80 * len);
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
            // maxY: getMaxValue(maxAmount),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesCogs,
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
            barGroups: _monthlyAnalysisCogsChartData(monthlyCogsList),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {}
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
                    '${monthlyCogsList[grpIndex].monthYear}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            'COGS: ${formatAmount(monthlyCogsList[grpIndex].cogs)}\n',
                        style: const TextStyle(
                          color: Color(0xFFFF9F47),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Target: ${formatAmount(monthlyCogsList[grpIndex].cogsTarget ?? 0)}\n',
                        style: const TextStyle(
                          color: Color(0xFFFF9F47),
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

                                      savedFinanceReceivablesOptionsTemp =
                                          savedFinanceReceivablesOptions;

                                      fromFilter = false;

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
                                      Navigator.pop(context);
                                      chartDataLoadedMonthlyPl = false;
                                      fromFilter = false;
                                      savedFinanceReceivablesOptionsTemp
                                          .clear();
                                      setState(() {
                                        chartDataLoadedMonthlyPl = false;
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
