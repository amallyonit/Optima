// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference
import 'package:optima/excel_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/classes/leads.dart';
import 'package:optima/login_screen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:optima/pages/dashboardPages/pdf_helper_other.dart';
import '../platform_excel_helper.dart';

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

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    userLevel = prefs.getString('userLevel') ?? '';
    await _loadTrialBalance(userName, userLevel);
    await _loadPurchasePrice(userName, userLevel);
    await _loadInventory(userName, userLevel);
    await _loadInventoryClosing(userName, userLevel);
    await _loadSales(userName, userLevel);
    await _loadGRN(userName, userLevel);
    await _loadSalesTarget(userName, userLevel);
    await loadMonthlyInventory(userName, userLevel);
    monthlyMap = buildMonthlyTargets(salesTarget);

    _loadSubGroupWiseAnalysis(0, "", "");
    _loadMonthlyAnalysisExpenditure();
    _loadMonthlyAnalysisPurchase();
    _loadMonthlySalesBarChartData();
    _loadMonthlyAnalysisRevenue();
    _loadMonthlyAnalysisInventory();
    _loadMonthlyAnalysisInventoryClosing();
    _loadSubGroupMonthWiseAnalysisExpenditure();
    _loadSubGroupMonthWiseAnalysisRevenue();
    _loadOtherIncomeMonthWiseAnalysisRevenue();
    _loadForeignNameMonthWiseAnalysisRevenue();
    setState(() {
      chartDataLoadedMonthlyPl = true;
    });
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
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> _loadInventory(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<InventoryList> salesList = [];
    try {
      do {
        var body = {
          "ToDate": dateFilterFlag
              ? formatDate(toDateFilter!)
              : formatDate(lastMonthToDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}BicxoInventoryAgeingList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            // HttpHeaders.authorizationHeader:
            // 'Bearer    ${DataManager.readSapToken()}'
          },
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<InventoryList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => InventoryList.fromJson(item))
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
        context.read<InventoryMonthlyPLProvider>().updateInventoryList(
          salesList,
        );
        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();
        menuNames.insert(0, UserName);
        if (int.parse(UserLevel) == 5) {
          inventory = salesList.toList();
        } else if (int.parse(UserLevel) == 4) {
          inventory = salesList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          inventory = salesList.toList();
        } else {
          inventory = salesList.toList();
        }
      });
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

  Future<void> _loadInventoryClosing(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<InventoryList> salesList = [];
    try {
      do {
        var body = {
          "ToDate": dateFilterFlag
              ? formatDate(toDateFilter!)
              : formatDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}BicxoInventoryAgeingList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            // HttpHeaders.authorizationHeader:
            // 'Bearer    ${DataManager.readSapToken()}'
          },
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<InventoryList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => InventoryList.fromJson(item))
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
        context.read<InventoryClosingMonthlyPLProvider>().updateInventoryList(
          salesList,
        );
        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();
        menuNames.insert(0, UserName);
        if (int.parse(UserLevel) == 5) {
          inventoryClosing = salesList.toList();
        } else if (int.parse(UserLevel) == 4) {
          inventoryClosing = salesList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          inventoryClosing = salesList.toList();
        } else {
          inventoryClosing = salesList.toList();
        }
      });
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
        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();
        menuNames.insert(0, UserName);
        if (int.parse(UserLevel) == 5) {
          salesTemp = salesList.toList();
          sales = salesList.toList();
        } else if (int.parse(UserLevel) == 4) {
          salesTemp = salesList.toList();
          sales = salesList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          salesTemp = salesList.toList();
          sales = salesList.toList();
        } else {
          salesTemp = salesList.toList();
          sales = salesList.toList();
        }
      });
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (mounted) {
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
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            navigateToLoginScreen();
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

  int _lastDayOfMonth(int year, int month) {
    final nextMonth = (month < 12)
        ? DateTime(year, month + 1, 1)
        : DateTime(year + 1, 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  Future<List<InventoryList>> _fetchInventoryForDate(
    DateTime toDate,
    String userName,
    String userLevel,
  ) async {
    int index = 0, limit = 10000, fetchedCount = 0;
    List<InventoryList> allItems = [];

    final formattedToDate = DateFormat('yyyyMMdd').format(toDate);

    do {
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

  Future<List<MonthlyInventoryData>> loadMonthlyInventory(
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
      final monthData = await _fetchInventoryForDate(
        cursor,
        userName,
        userLevel,
      );
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

  // List<MonthlyCogsData> calculateMonthlyCogs({
  //   required List<MonthlyInventoryData> inventoryList,
  //   required List<DailyAnalysisExpensesData> purchaseMonthlyData,
  // }) {
  //   List<MonthlyCogsData> cogsList = [];
  //
  //   for (int i = 1; i < inventoryList.length; i++) {
  //     final String monthYear = inventoryList[i].monthYear;
  //
  //     final double openingStock = inventoryList[i - 1]
  //         .inventory
  //         .fold(0.0, (sum, item) => sum + (double.parse(item.totalValue)));
  //
  //     final double closingStock = inventoryList[i]
  //         .inventory
  //         .fold(0.0, (sum, item) => sum + (double.parse(item.totalValue)));
  //
  //     double purchases = 0.0;
  //     if (i - 1 < purchaseMonthlyData.length) {
  //       purchases = purchaseMonthlyData[i - 1].balance;
  //     }
  //
  //     final double cogs = openingStock + purchases - closingStock;
  //
  //     cogsList.add(MonthlyCogsData(
  //       monthYear: monthYear,
  //       openingStock: openingStock,
  //       purchases: purchases,
  //       closingStock: closingStock,
  //       cogs: cogs,
  //       cogsTarget: 0,
  //       inventoryTarget: 0
  //     ));
  //   }
  //
  //   return cogsList;
  // }

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

  /// Given your raw [monthlyCogsList] (with cogs but no targets),
  /// this returns a new list where each entry’s cogsTarget & inventoryTarget
  /// are filled in from your SalesTargetList data.

  // Future<void> _loadMonthlySalesBarChartData() async {
  //   List<MonthlySalesData> monthlyDataList = [];
  //   prevYearMonthList = PrevYearMonthList(prevYearMonthData: []);
  //   int currentYear = DateTime.now().year;
  //   DateTime startDate;
  //   DateTime endDate;
  //   for (int i = 4; i <= 15; i++) {
  //     String monthName = getMonthName(i);
  //     double monthlyTarget = 0.00;
  //     double monthlySales = 0.00;
  //
  //     List<SalesList> monthlySalesList = [];
  //     if (i >= 4 && i <= 12) {
  //       Map<String, DateTime> monthDates = getMonthStartEndDates(i);
  //       monthlySalesList = sales.where((target) {
  //         DateTime invoiceDate =
  //             DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
  //         return invoiceDate.isAtLeast(monthDates['start']!) &&
  //             invoiceDate.isAtMost(monthDates['end']!);
  //       }).toList();
  //     } else {
  //       startDate = DateTime(currentYear + 1, i - 12, 1);
  //       endDate = DateTime(currentYear + 1, (i - 12) + 1, 0);
  //       monthlySalesList = sales.where((target) {
  //         DateTime invoiceDate =
  //             DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
  //         return invoiceDate.isAtLeast(startDate) &&
  //             invoiceDate.isAtMost(endDate);
  //       }).toList();
  //     }
  //     double salesAmt = 0;
  //     for (var target in monthlySalesList) {
  //       if (target.invoiceType != "Sales Return") {
  //         salesAmt = double.tryParse(target.rowTotal) ?? 0;
  //       } else {
  //         salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
  //       }
  //       monthlySales += salesAmt;
  //     }
  //     monthlyDataList.add(MonthlySalesData(
  //       monthName: monthName,
  //       salesAmount: monthlySales,
  //       salesTarget: monthlyTarget,
  //     ));
  //     monthlySales = 0;
  //     monthlyTarget = 0;
  //   }
  //   monthlySalesList = MonthlySalesList(monthlyData: monthlyDataList);
  // }

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
      DateTime startDate, endDate;
      if (i <= 12) {
        var md = getMonthStartEndDates(i);
        startDate = md['start']!;
        endDate = md['end']!;
      } else {
        startDate = DateTime(currentYear + 1, i - 12, 1);
        endDate = DateTime(currentYear + 1, i - 12 + 1, 0);
      }

      var monthSalesRows = sales.where((row) {
        final dt = DateFormat('dd/MM/yyyy').parse(row.invoiceDate);
        return dt.isAtLeast(startDate) && dt.isAtMost(endDate);
      });

      for (var row in monthSalesRows) {
        var amt = double.tryParse(row.rowTotal) ?? 0.0;
        monthlySales += (row.invoiceType != "Sales Return") ? amt : -amt;
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

    // customerTargetList = expenseRecords.where((record) {
    //   // Split the monthYear string into its components:
    //   final parts = record.monthYear.split('/');
    //   // Expecting two parts: [month, year]. Use int.parse to convert to integers.
    //   int month = int.parse(parts[0]);
    //   int year = int.parse(parts[1]);
    //
    //   // The first day of the month:
    //   DateTime fromDt = DateTime(year, month, 1);
    //   // To safely get the last day of the month, create a date for the first day of the next month,
    //   // then subtract one day. Note: DateTime(year, month + 1, 0) returns the last day of the month.
    //   DateTime toDt = DateTime(year, month + 1, 0);
    //
    //   // Now check if the month/date range falls within the fiscal period.
    //   // If you have a defined fiscalYearEndDate, use that.
    //   // Here, fiscalYearStartDate and currentDate (or fiscalYearEndDate) are assumed to be non-null.
    //   bool startsAfterOrOnFiscalStart = fromDt.isAfter(fiscalYearStartDate!);
    //   bool endsBeforeOrOnCurrentDate = toDt.isBefore(currentDate!);
    //
    //   return startsAfterOrOnFiscalStart && endsBeforeOrOnCurrentDate;
    // }).toList();

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

  // Future<void> _loadForeignNameMonthWiseAnalysisRevenue() async {
  //   // List to hold month-wise expense data for each subgroup.
  //   List<SubGroupMonthWiseRevenueExpensesData> subGroupMonthWiseDataList = [];
  //
  //   DateFormat formatter = DateFormat('dd/MM/yyyy');
  //
  //   // Filter records that are part of "Expenditure".
  //   List<TrialBalance> expenseRecords = trialBalanceList;
  //
  //   List<TrialBalance> customerTargetList = [];
  //
  //   customerTargetList = expenseRecords.where((record) {
  //     // Split the monthYear string into its components:
  //     final parts = record.monthYear.split('/');
  //     // Expecting two parts: [month, year]. Use int.parse to convert to integers.
  //     int month = int.parse(parts[0]);
  //     int year = int.parse(parts[1]);
  //
  //     // The first day of the month:
  //     DateTime fromDt = DateTime(year, month, 1);
  //     // To safely get the last day of the month, create a date for the first day of the next month,
  //     // then subtract one day. Note: DateTime(year, month + 1, 0) returns the last day of the month.
  //
  //     // Now check if the month/date range falls within the fiscal period.
  //     // If you have a defined fiscalYearEndDate, use that.
  //     // Here, fiscalYearStartDate and currentDate (or fiscalYearEndDate) are assumed to be non-null.
  //     bool startsAfterOrOnFiscalStart = !fromDt.isBefore(fiscalYearStartDate!);
  //     bool endsBeforeOrOnCurrentDate = !fromDt.isAfter(currentDate!);
  //
  //     return startsAfterOrOnFiscalStart && endsBeforeOrOnCurrentDate;
  //   }).toList();
  //
  //   // Process each expense record.
  //   for (var record in customerTargetList) {
  //     // Parse the record's month-year by
  //     // prepending a day (here "01").
  //     DateTime recordDate = formatter.parse('01/${record.monthYear}');
  //     int month = recordDate.month;
  //     // Convert the balance string to a double.
  //     double recordBalance = double.tryParse(record.balance) ?? 0.0;
  //
  //     // Find an existing entry for this subgroup using try/catch.
  //     SubGroupMonthWiseRevenueExpensesData? subgroupData;
  //     try {
  //       subgroupData = subGroupMonthWiseDataList.firstWhere(
  //         (element) => element.subGroupName == record.foreignName,
  //       );
  //     } catch (e) {
  //       subgroupData = null;
  //     }
  //
  //     // If no entry exists, create a new one with all balances initialized to 0.0.
  //     if (subgroupData == null) {
  //       subgroupData = SubGroupMonthWiseRevenueExpensesData(
  //         subGroupName: record.foreignName,
  //         aprBalance: 0.0,
  //         mayBalance: 0.0,
  //         junBalance: 0.0,
  //         julBalance: 0.0,
  //         augBalance: 0.0,
  //         septBalance: 0.0,
  //         octBalance: 0.0,
  //         novBalance: 0.0,
  //         decBalance: 0.0,
  //         janBalance: 0.0,
  //         febBalance: 0.0,
  //         marBalance: 0.0,
  //       );
  //       subGroupMonthWiseDataList.add(subgroupData);
  //     }
  //
  //     // Update the corresponding month balance based on the record's month.
  //     // Assuming a financial year from April to March.
  //     if (month == 4) {
  //       subgroupData.aprBalance += recordBalance;
  //     } else if (month == 5) {
  //       subgroupData.mayBalance += recordBalance;
  //     } else if (month == 6) {
  //       subgroupData.junBalance += recordBalance;
  //     } else if (month == 7) {
  //       subgroupData.julBalance += recordBalance;
  //     } else if (month == 8) {
  //       subgroupData.augBalance += recordBalance;
  //     } else if (month == 9) {
  //       subgroupData.septBalance += recordBalance;
  //     } else if (month == 10) {
  //       subgroupData.octBalance += recordBalance;
  //     } else if (month == 11) {
  //       subgroupData.novBalance += recordBalance;
  //     } else if (month == 12) {
  //       subgroupData.decBalance += recordBalance;
  //     } else if (month == 1) {
  //       subgroupData.janBalance += recordBalance;
  //     } else if (month == 2) {
  //       subgroupData.febBalance += recordBalance;
  //     } else if (month == 3) {
  //       subgroupData.marBalance += recordBalance;
  //     }
  //   }
  //
  //   // Inject the data into your SubGroupMonthWiseExpensesList.
  //   foreignNameMonthExpenseWiseList = SubGroupMonthWiseRevenueExpensesList(
  //     subGroupData: subGroupMonthWiseDataList,
  //   );
  // }

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

          // if (balanceAmount.toString().contains('e')) {
          //   print("Exponential detected: $balanceAmount");
          //   balanceAmount = double.parse(balanceAmount.toStringAsFixed(2));
          //   print("Converted to fixed-point: $balanceAmount");
          // }

          // balanceAmount = double.parse(balanceAmount.toStringAsFixed(1));
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

          // if (balanceAmount.toString().contains('e')) {
          //   print("Exponential detected: $balanceAmount");
          //   balanceAmount = double.parse(balanceAmount.toStringAsFixed(2));
          //   print("Converted to fixed-point: $balanceAmount");
          // }

          // balanceAmount = double.parse(balanceAmount.toStringAsFixed(1));
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

  // Future<void> _loadMonthlyAnalysisPurchase() async {
  //   List<DailyAnalysisExpensesData> groupWiseDataList = [];
  //
  //   List<GRNList> purchaseRecords =
  //       grnList /*.where((test) => test. == "Item Purchase").toList()*/;
  //
  //   // Filter records based on the invoice date falling within the specified fiscal year.
  //   List<GRNList> filteredRecords = purchaseRecords.where((record) {
  //     DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(record.grnDate);
  //     return invoiceDate.isAtLeast(
  //             dateFilterFlag ? fromDateFilter! : fiscalYearStartDate!) &&
  //         invoiceDate.isAtMost(dateFilterFlag ? toDateFilter! : currentDate!);
  //   }).toList();
  //
  //   // Create a Map to group balances by month-year.
  //   // Key: month-year string (e.g. "08/2024")
  //   // Value: accumulated balance for that month.
  //   Map<String, double> monthlyBalanceMap = {};
  //
  //   // Iterate over the filtered records to group and sum balances.
  //   for (var record in filteredRecords) {
  //     DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(record.grnDate);
  //     String monthYearKey = DateFormat('MM/yyyy').format(invoiceDate);
  //
  //     double balance = double.tryParse(record.rowTotal) ?? 0.0;
  //     // Sum the absolute value of balances.
  //     monthlyBalanceMap[monthYearKey] =
  //         (monthlyBalanceMap[monthYearKey] ?? 0.0) + balance.abs();
  //   }
  //
  //   // Convert each group into DailyAnalysisExpensesData.
  //   monthlyBalanceMap.forEach((monthYear, totalBalance) {
  //     groupWiseDataList.add(DailyAnalysisExpensesData(
  //       balance: totalBalance,
  //       date: monthYear,
  //       target: 0
  //     ));
  //   });
  //
  //   // Assign the calculated data to the revenueMonthlyData.
  //   purchaseMonthlyData =
  //       DailyAnalysisExpensesList(dailyData: groupWiseDataList);
  //   monthlyCogsList = calculateMonthlyCogs(
  //     inventoryList: monthWiseInventory,
  //     purchaseMonthlyData: purchaseMonthlyData.dailyData,
  //   );
  // }

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

    // for (var target in filteredRecords) {
    //   // if (target.ageingBrackets == "<30 Days") {
    //   //   lessThan30DaysValue += (double.tryParse(target.totalValue) ?? 0);
    //   // }
    //   // if (target.ageingBrackets == "31-45 Days" ||
    //   //     target.ageingBrackets == "31-45 Days") {
    //   //   a30to60DaysValue += (double.tryParse(target.totalValue) ?? 0);
    //   // }
    //   // if (target.ageingBrackets == "61-90 Days") {
    //   //   a60to90DaysValue += (double.tryParse(target.totalValue) ?? 0);
    //   // }
    //   // if (target.ageingBrackets == "91-120 Days" ||
    //   //     target.ageingBrackets == "121-150 Days" ||
    //   //     target.ageingBrackets == "151-180 Days" ||
    //   //     target.ageingBrackets == "181-365 Days" ||
    //   //     target.ageingBrackets == "366-730 Days" ||
    //   //     target.ageingBrackets == ">730 Days") {
    //   //   a91DaysValue += (double.tryParse(target.totalValue) ?? 0);
    //   // }
    //   // if (target.ageingBrackets == "91-120 Days" ||
    //   //     target.ageingBrackets == "121-150 Days" ||
    //   //     target.ageingBrackets == "151-180 Days") {
    //   //   nearExpiryValue += (double.tryParse(target.totalValue) ?? 0);
    //   // }
    //   // if (target.ageingBrackets == "181-365 Days" ||
    //   //     target.ageingBrackets == "366-730 Days" ||
    //   //     target.ageingBrackets == ">730 Days") {
    //   //   expiredValue += (double.tryParse(target.totalValue) ?? 0);
    //   // }
    //   //
    //   // inventoryOpeningValue += (double.parse(target.totalValue));
    // }

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

  // Future<void> generateSalesAnalysisYTDExcel() async {
  //   final excel = xl.Excel.createExcel();
  //   final sheet = excel['Sheet1'];
  //   sheet.getColAutoFits;
  //   sheet.appendRow(toCellRow([
  //     'Particulars',
  //     'Target',
  //     'Apr 25',
  //     'May 25',
  //     'Jun 25',
  //     'Jul 25',
  //     'Aug 25',
  //     'Sep 25',
  //     'Oct 25',
  //     'Nov 25',
  //     'Dec 25',
  //     'Jan 26',
  //     'Feb 26',
  //     'Mar 26',
  //   ]);
  //
  //   for (int column = 0; column < 11; column++) {
  //     var cell = sheet.cell(
  //         xl.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0));
  //     cell.cellStyle = xl.CellStyle(
  //       bold: true,
  //       fontSize: 14,
  //     );
  //
  //     sheet.setColAutoFit(column);
  //   }
  //
  //   for (var ytdData in productMarginList.productMarginData) {
  //     sheet.appendRow(toCellRow([
  //       ytdData.itemNo,
  //       ytdData.itemDescription,
  //       ytdData.itemSubGroup,
  //       ytdData.quantity,
  //       ytdData.saleAmt,
  //       ytdData.avgSellingPrice,
  //       ytdData.bomCost,
  //       ytdData.perUnitMarginAmount,
  //       ytdData.totalMarginAmount,
  //       ytdData.marginPercent,
  //     ]);
  //   }
  //
  //   xl.CellStyle centerCellStyle = xl.CellStyle(
  //     verticalAlign: xl.VerticalAlign.Center,
  //     horizontalAlign: xl.HorizontalAlign.Center,
  //   );
  //
  //   int numberOfRows = productMarginList.productMarginData.length;
  //
  //   for (int rowIndex = 0; rowIndex <= numberOfRows; rowIndex++) {
  //     for (int colIndex = 0; colIndex < 10; colIndex++) {
  //       var cell = sheet.cell(xl.CellIndex.indexByColumnRow(
  //           columnIndex: colIndex, rowIndex: rowIndex));
  //       if (rowIndex != 0) {
  //         cell.cellStyle = centerCellStyle;
  //       }
  //     }
  //   }
  //
  //   setState(() {
  //     YtdSalesBarChartData = true;
  //   });
  //
  //   if (kIsWeb) {
  //     // var fileBytes = excel.save(fileName: 'sales_analysis_ytd_report.xlsx');
  //
  //     final excelBytes = excel.encode()!;
  //     saveAndOpenExcel('sales_analysis_ytd_report.xlsx', excelBytes);
  //
  //     // var fileBytes = excel.encode();
  //     //
  //     // final blob = html.Blob([fileBytes]);
  //     // final url = html.Url.createObjectUrlFromBlob(blob);
  //     // final anchor = html.AnchorElement()
  //     //   ..href = url
  //     //   ..download = 'monthly_sales_report.xlsx'
  //     //   ..style.display = 'none';
  //     // html.document.body!.append(anchor);
  //     // anchor.click();
  //     // anchor.remove();
  //     // html.Url.revokeObjectUrl(url);
  //   } else {
  //     String storageDir = await getStorageDirectory();
  //     final file = File('$storageDir/sales_analysis_ytd_report.xlsx');
  //     await file.writeAsBytes(excel.encode()!);
  //     OpenFile.open(file.path);
  //   }
  // }

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

  // Future<void> generateSalesAnalysisYTDExcel() async {
  //   final excel = xl.Excel.createExcel();
  //   final sheet = excel['Sheet1'];
  //   sheet.getColAutoFits;
  //
  //
  //   cogsValue = (inventoryOpeningValue + purchaseMonthlyData.dailyData[getCurrentFinancialMonthIndex()].balance) -
  //       (lessThan30DaysValue +
  //           a30to60DaysValue +
  //           a60to90DaysValue +
  //           nearExpiryValue +
  //           expiredValue);
  //
  //   sheet.appendRow(toCellRow([
  //     'Particulars',
  //     'Target',
  //     'Apr',
  //     'May',
  //     'Jun',
  //     'Jul',
  //     'Aug',
  //     'Sep',
  //     'Oct',
  //     'Nov',
  //     'Dec',
  //     'Jan',
  //     'Feb',
  //     'Mar',
  //   ]);
  //
  //   sheet.appendRow(toCellRow([
  //     "Revenue",
  //     revenueTarget,
  //     monthlySalesList.monthlyData.isNotEmpty
  //         ? monthlySalesList.monthlyData[0].salesAmount
  //         : 0,
  //     monthlySalesList.monthlyData.length == 12
  //         ? monthlySalesList.monthlyData[1].salesAmount
  //         : 0,
  //     monthlySalesList.monthlyData.length == 12
  //         ? monthlySalesList.monthlyData[2].salesAmount
  //         : 0,
  //     monthlySalesList.monthlyData.length == 12
  //         ? monthlySalesList.monthlyData[3].salesAmount
  //         : 0,
  //     monthlySalesList.monthlyData.length == 12
  //         ? monthlySalesList.monthlyData[4].salesAmount
  //         : 0,
  //     monthlySalesList.monthlyData.length == 12
  //         ? monthlySalesList.monthlyData[5].salesAmount
  //         : 0,
  //     monthlySalesList.monthlyData.length == 12
  //         ? monthlySalesList.monthlyData[6].salesAmount
  //         : 0,
  //     monthlySalesList.monthlyData.length == 12
  //         ? monthlySalesList.monthlyData[7].salesAmount
  //         : 0,
  //     monthlySalesList.monthlyData.length == 12
  //         ? monthlySalesList.monthlyData[8].salesAmount
  //         : 0,
  //     monthlySalesList.monthlyData.length == 12
  //         ? monthlySalesList.monthlyData[9].salesAmount
  //         : 0,
  //     monthlySalesList.monthlyData.length == 12
  //         ? monthlySalesList.monthlyData[10].salesAmount
  //         : 0,
  //     monthlySalesList.monthlyData.length == 12
  //         ? monthlySalesList.monthlyData[11].salesAmount
  //         : 0,
  //   ]);
  //   sheet.appendRow(toCellRow([
  //     "Other Income",
  //     "",
  //     otherIncomeList.subGroupData.isNotEmpty
  //         ? otherIncomeList.subGroupData[0].aprBalance
  //         : 0,
  //     otherIncomeList.subGroupData.length == 2
  //         ? otherIncomeList.subGroupData[1].mayBalance
  //         : 0,
  //     otherIncomeList.subGroupData.length == 3
  //         ? otherIncomeList.subGroupData[2].junBalance
  //         : 0,
  //     otherIncomeList.subGroupData.length == 4
  //         ? otherIncomeList.subGroupData[3].julBalance
  //         : 0,
  //     otherIncomeList.subGroupData.length == 5
  //         ? otherIncomeList.subGroupData[4].augBalance
  //         : 0,
  //     otherIncomeList.subGroupData.length == 6
  //         ? otherIncomeList.subGroupData[5].septBalance
  //         : 0,
  //     otherIncomeList.subGroupData.length == 7
  //         ? otherIncomeList.subGroupData[6].octBalance
  //         : 0,
  //     otherIncomeList.subGroupData.length == 8
  //         ? otherIncomeList.subGroupData[7].novBalance
  //         : 0,
  //     otherIncomeList.subGroupData.length == 9
  //         ? otherIncomeList.subGroupData[8].decBalance
  //         : 0,
  //     otherIncomeList.subGroupData.length == 10
  //         ? otherIncomeList.subGroupData[9].janBalance
  //         : 0,
  //     otherIncomeList.subGroupData.length == 11
  //         ? otherIncomeList.subGroupData[10].febBalance
  //         : 0,
  //     otherIncomeList.subGroupData.length == 12
  //         ? otherIncomeList.subGroupData[11].marBalance
  //         : 0,
  //   ]);
  //   sheet.appendRow(toCellRow([
  //     "Total Revenue",
  //     "",
  //     otherIncomeList.subGroupData.isNotEmpty
  //         ? otherIncomeList.subGroupData[0].aprBalance + monthlySalesList.monthlyData[0].salesAmount
  //         : 0,
  //     otherIncomeList.subGroupData.length == 2
  //         ? otherIncomeList.subGroupData[1].mayBalance + monthlySalesList.monthlyData[1].salesAmount
  //         : 0,
  //     otherIncomeList.subGroupData.length == 3
  //         ? otherIncomeList.subGroupData[2].junBalance + monthlySalesList.monthlyData[2].salesAmount
  //         : 0,
  //     otherIncomeList.subGroupData.length == 4
  //         ? otherIncomeList.subGroupData[3].julBalance + monthlySalesList.monthlyData[3].salesAmount
  //         : 0,
  //     otherIncomeList.subGroupData.length == 5
  //         ? otherIncomeList.subGroupData[4].augBalance+ monthlySalesList.monthlyData[4].salesAmount
  //         : 0,
  //     otherIncomeList.subGroupData.length == 6
  //         ? otherIncomeList.subGroupData[5].septBalance+ monthlySalesList.monthlyData[5].salesAmount
  //         : 0,
  //     otherIncomeList.subGroupData.length == 7
  //         ? otherIncomeList.subGroupData[6].octBalance+ monthlySalesList.monthlyData[6].salesAmount
  //         : 0,
  //     otherIncomeList.subGroupData.length == 8
  //         ? otherIncomeList.subGroupData[7].novBalance+ monthlySalesList.monthlyData[7].salesAmount
  //         : 0,
  //     otherIncomeList.subGroupData.length == 9
  //         ? otherIncomeList.subGroupData[8].decBalance+ monthlySalesList.monthlyData[8].salesAmount
  //         : 0,
  //     otherIncomeList.subGroupData.length == 10
  //         ? otherIncomeList.subGroupData[9].janBalance+ monthlySalesList.monthlyData[9].salesAmount
  //         : 0,
  //     otherIncomeList.subGroupData.length == 11
  //         ? otherIncomeList.subGroupData[10].febBalance+ monthlySalesList.monthlyData[10].salesAmount
  //         : 0,
  //     otherIncomeList.subGroupData.length == 12
  //         ? otherIncomeList.subGroupData[11].marBalance+ monthlySalesList.monthlyData[11].salesAmount
  //         : 0,
  //   ]);
  //
  //
  //   sheet.appendRow(toCellRow([""]);
  //
  //   sheet.appendRow(toCellRow([
  //     "Purchases",
  //     purchaseTarget,
  //     purchaseMonthlyData.dailyData.isNotEmpty
  //         ? purchaseMonthlyData.dailyData[0].balance
  //         : 0,
  //     purchaseMonthlyData.dailyData.length == 2
  //         ? purchaseMonthlyData.dailyData[1].balance
  //         : 0,
  //     purchaseMonthlyData.dailyData.length == 3
  //         ? purchaseMonthlyData.dailyData[2].balance
  //         : 0,
  //     purchaseMonthlyData.dailyData.length == 4
  //         ? purchaseMonthlyData.dailyData[3].balance
  //         : 0,
  //     purchaseMonthlyData.dailyData.length == 5
  //         ? purchaseMonthlyData.dailyData[4].balance
  //         : 0,
  //     purchaseMonthlyData.dailyData.length == 6
  //         ? purchaseMonthlyData.dailyData[5].balance
  //         : 0,
  //     purchaseMonthlyData.dailyData.length == 7
  //         ? purchaseMonthlyData.dailyData[6].balance
  //         : 0,
  //     purchaseMonthlyData.dailyData.length == 8
  //         ? purchaseMonthlyData.dailyData[7].balance
  //         : 0,
  //     purchaseMonthlyData.dailyData.length == 9
  //         ? purchaseMonthlyData.dailyData[8].balance
  //         : 0,
  //     purchaseMonthlyData.dailyData.length == 10
  //         ? purchaseMonthlyData.dailyData[9].balance
  //         : 0,
  //     purchaseMonthlyData.dailyData.length == 11
  //         ? purchaseMonthlyData.dailyData[10].balance
  //         : 0,
  //     purchaseMonthlyData.dailyData.length == 12
  //         ? purchaseMonthlyData.dailyData[11].balance
  //         : 0,
  //   ]);
  //   sheet.appendRow(toCellRow([
  //     "Opening Stock",
  //     "",
  //     "",
  //     "",
  //     inventoryOpeningValue
  //   ]);
  //   sheet.appendRow(toCellRow([
  //     "Closing Stock",
  //     "",
  //     "",
  //     "",
  //     inventoryClosingValue,
  //   ]);
  //   sheet.appendRow(toCellRow([
  //     "Cost of Materials Consumed",
  //     "",
  //     "",
  //     "",
  //     ((cogsValue))
  //   ]);
  //   sheet.appendRow(toCellRow([""]);
  //
  //   for (var ytdData in subGroupMonthExpenseWiseList.subGroupData) {
  //     sheet.appendRow(toCellRow([
  //       ytdData.subGroupName,
  //       "",
  //       ytdData.aprBalance,
  //       ytdData.mayBalance,
  //       ytdData.junBalance,
  //       ytdData.julBalance,
  //       ytdData.augBalance,
  //       ytdData.septBalance,
  //       ytdData.octBalance,
  //       ytdData.novBalance,
  //       ytdData.decBalance,
  //       ytdData.janBalance,
  //       ytdData.febBalance,
  //       ytdData.marBalance,
  //     ]);
  //   }
  //   sheet.appendRow(toCellRow([""]);
  //
  //   // for (int column = 0; column < 13; column++) {
  //   //   var cell = sheet.cell(
  //   //       xl.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0));
  //   //   cell.cellStyle = xl.CellStyle(
  //   //     bold: true,
  //   //     fontSize: 14,
  //   //   );
  //   //
  //   //   sheet.setColAutoFit(column);
  //   // }
  //   sheet.appendRow(toCellRow([
  //     "Expenditure",
  //     "",
  //     expenditureMonthlyData.dailyData.isNotEmpty
  //         ? expenditureMonthlyData.dailyData[0].balance
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 2
  //         ? expenditureMonthlyData.dailyData[1].balance
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 3
  //         ? expenditureMonthlyData.dailyData[2].balance
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 4
  //         ? expenditureMonthlyData.dailyData[3].balance
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 5
  //         ? expenditureMonthlyData.dailyData[4].balance
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 6
  //         ? expenditureMonthlyData.dailyData[5].balance
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 7
  //         ? expenditureMonthlyData.dailyData[6].balance
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 8
  //         ? expenditureMonthlyData.dailyData[7].balance
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 9
  //         ? expenditureMonthlyData.dailyData[8].balance
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 10
  //         ? expenditureMonthlyData.dailyData[9].balance
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 11
  //         ? expenditureMonthlyData.dailyData[10].balance
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 12
  //         ? expenditureMonthlyData.dailyData[11].balance
  //         : 0,
  //   ]);
  //   sheet.appendRow(toCellRow([""]);
  //
  //   // int numberOfRows = expenditureMonthlyData.dailyData.length;
  //
  //   // for (int rowIndex = 0; rowIndex <= numberOfRows+1; rowIndex++) {
  //   //   for (int colIndex = 0; colIndex < 10; colIndex++) {
  //   //     var cell = sheet.cell(xl.CellIndex.indexByColumnRow(
  //   //         columnIndex: colIndex, rowIndex: rowIndex));
  //   //     if (rowIndex != 0) {
  //   //       cell.cellStyle = centerCellStyle;
  //   //     }
  //   //   }
  //   // }
  //   sheet.appendRow(toCellRow(["Direct Expenses"]);
  //   for (var ytdData in directExpensesList.subGroupData) {
  //     sheet.appendRow(toCellRow([
  //       ytdData.subGroupName,
  //       "",
  //       ytdData.aprBalance,
  //       ytdData.mayBalance,
  //       ytdData.junBalance,
  //       ytdData.julBalance,
  //       ytdData.augBalance,
  //       ytdData.septBalance,
  //       ytdData.octBalance,
  //       ytdData.novBalance,
  //       ytdData.decBalance,
  //       ytdData.janBalance,
  //       ytdData.febBalance,
  //       ytdData.marBalance,
  //     ]);
  //   }
  //   for (var ytdData in sumOfDirectExpensesList.subGroupData) {
  //     sheet.appendRow(toCellRow([
  //       "Total Direct Expenses",
  //       "",
  //       ytdData.aprBalance,
  //       ytdData.mayBalance,
  //       ytdData.junBalance,
  //       ytdData.julBalance,
  //       ytdData.augBalance,
  //       ytdData.septBalance,
  //       ytdData.octBalance,
  //       ytdData.novBalance,
  //       ytdData.decBalance,
  //       ytdData.janBalance,
  //       ytdData.febBalance,
  //       ytdData.marBalance,
  //     ]);
  //   }
  //   sheet.appendRow(toCellRow([""]);
  //   sheet.appendRow(toCellRow(["Indirect Expenses"]);
  //   for (var ytdData in otherIndirectExpensesList.subGroupData) {
  //     sheet.appendRow(toCellRow([
  //       ytdData.subGroupName,
  //       "",
  //       ytdData.aprBalance,
  //       ytdData.mayBalance,
  //       ytdData.junBalance,
  //       ytdData.julBalance,
  //       ytdData.augBalance,
  //       ytdData.septBalance,
  //       ytdData.octBalance,
  //       ytdData.novBalance,
  //       ytdData.decBalance,
  //       ytdData.janBalance,
  //       ytdData.febBalance,
  //       ytdData.marBalance,
  //     ]);
  //   }
  //   for (var ytdData in foreignNameMonthExpenseWiseList.subGroupData) {
  //     sheet.appendRow(toCellRow([
  //       ytdData.subGroupName,
  //       "",
  //       ytdData.aprBalance,
  //       ytdData.mayBalance,
  //       ytdData.junBalance,
  //       ytdData.julBalance,
  //       ytdData.augBalance,
  //       ytdData.septBalance,
  //       ytdData.octBalance,
  //       ytdData.novBalance,
  //       ytdData.decBalance,
  //       ytdData.janBalance,
  //       ytdData.febBalance,
  //       ytdData.marBalance,
  //     ]);
  //   }
  //   for (var ytdData in totalIndirectExpensesList.subGroupData) {
  //     sheet.appendRow(toCellRow([
  //       "Total Indirect Expenses",
  //       "",
  //       ytdData.aprBalance,
  //       ytdData.mayBalance,
  //       ytdData.junBalance,
  //       ytdData.julBalance,
  //       ytdData.augBalance,
  //       ytdData.septBalance,
  //       ytdData.octBalance,
  //       ytdData.novBalance,
  //       ytdData.decBalance,
  //       ytdData.janBalance,
  //       ytdData.febBalance,
  //       ytdData.marBalance,
  //     ]);
  //   }
  //   sheet.appendRow(toCellRow([""]);
  //
  //   // for (var ytdData in subGroupMonthWiseList.subGroupData) {
  //   //   sheet.appendRow(toCellRow([
  //   //     ytdData.subGroupName,
  //   //     ytdData.aprBalance,
  //   //     ytdData.mayBalance,
  //   //     ytdData.junBalance,
  //   //     ytdData.julBalance,
  //   //     ytdData.augBalance,
  //   //     ytdData.septBalance,
  //   //     ytdData.octBalance,
  //   //     ytdData.novBalance,
  //   //     ytdData.decBalance,
  //   //     ytdData.janBalance,
  //   //     ytdData.febBalance,
  //   //     ytdData.marBalance,
  //   //   ]);
  //   // }
  //   // sheet.appendRow(toCellRow([""]);
  //   sheet.appendRow(toCellRow(["EBITDA"]);
  //   sheet.appendRow(toCellRow(["PBT"]);
  //   sheet.appendRow(toCellRow([
  //     'PAT',
  //     "",
  //     expenditureMonthlyData.dailyData.isNotEmpty
  //         ? expenditureMonthlyData.dailyData[0].balance -
  //             revenueMonthlyData.dailyData[0].balance
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 2
  //         ? expenditureMonthlyData.dailyData[1].balance -
  //             monthlySalesList.monthlyData[1].salesAmount
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 3
  //         ? expenditureMonthlyData.dailyData[2].balance -
  //             monthlySalesList.monthlyData[2].salesAmount
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 4
  //         ? expenditureMonthlyData.dailyData[3].balance -
  //             monthlySalesList.monthlyData[3].salesAmount
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 5
  //         ? expenditureMonthlyData.dailyData[4].balance -
  //             monthlySalesList.monthlyData[4].salesAmount
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 6
  //         ? expenditureMonthlyData.dailyData[5].balance -
  //             monthlySalesList.monthlyData[5].salesAmount
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 7
  //         ? expenditureMonthlyData.dailyData[6].balance -
  //             monthlySalesList.monthlyData[6].salesAmount
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 8
  //         ? expenditureMonthlyData.dailyData[7].balance -
  //             monthlySalesList.monthlyData[7].salesAmount
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 9
  //         ? expenditureMonthlyData.dailyData[8].balance -
  //             monthlySalesList.monthlyData[8].salesAmount
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 10
  //         ? expenditureMonthlyData.dailyData[9].balance -
  //             monthlySalesList.monthlyData[9].salesAmount
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 11
  //         ? expenditureMonthlyData.dailyData[10].balance -
  //             monthlySalesList.monthlyData[10].salesAmount
  //         : 0,
  //     expenditureMonthlyData.dailyData.length == 12
  //         ? expenditureMonthlyData.dailyData[11].balance -
  //             monthlySalesList.monthlyData[11].salesAmount
  //         : 0,
  //   ]);
  //
  //   setState(() {
  //     // YtdSalesBarChartData = true;
  //   });
  //
  //   if (kIsWeb) {
  //     // var fileBytes = excel.save(fileName: 'sales_analysis_ytd_report.xlsx');
  //
  //     final excelBytes = excel.encode()!;
  //     saveAndOpenExcel('monthlyPL.xlsx', excelBytes);
  //
  //     // var fileBytes = excel.encode();
  //     //
  //     // final blob = html.Blob([fileBytes]);
  //     // final url = html.Url.createObjectUrlFromBlob(blob);
  //     // final anchor = html.AnchorElement()
  //     //   ..href = url
  //     //   ..download = 'monthly_sales_report.xlsx'
  //     //   ..style.display = 'none';
  //     // html.document.body!.append(anchor);
  //     // anchor.click();
  //     // anchor.remove();
  //     // html.Url.revokeObjectUrl(url);
  //   } else {
  //     String storageDir = await getStorageDirectory();
  //     final file = File('$storageDir/monthlyPL.xlsx');
  //     await file.writeAsBytes(excel.encode()!);
  //     OpenFile.open(file.path);
  //   }
  //   Future<void> generateSalesAnalysisYTDExcel2() async {
  //     final excel = xl.Excel.createExcel();
  //     final sheet = excel['Sheet1'];
  //     sheet.getColAutoFits;
  //
  //     cogsValue = (inventoryOpeningValue +
  //             purchaseMonthlyData
  //                 .dailyData[getCurrentFinancialMonthIndex()].balance) -
  //         (lessThan30DaysValue +
  //             a30to60DaysValue +
  //             a60to90DaysValue +
  //             nearExpiryValue +
  //             expiredValue);
  //
  //     sheet.appendRow(toCellRow([
  //       'Particulars',
  //       'Target',
  //       'Apr',
  //       '%',
  //       'May',
  //       '%',
  //       'Jun',
  //       '%',
  //       'Jul',
  //       '%',
  //       'Aug',
  //       '%',
  //       'Sep',
  //       '%',
  //       'Oct',
  //       '%',
  //       'Nov',
  //       '%',
  //       'Dec',
  //       '%',
  //       'Jan',
  //       '%',
  //       'Feb',
  //       '%',
  //       'Mar',
  //       '%'
  //     ]);
  //
  //     sheet.appendRow(toCellRow([
  //       "Revenue",
  //       revenueTarget,
  //       monthlySalesList.monthlyData.isNotEmpty
  //           ? monthlySalesList.monthlyData[0].salesAmount
  //           : 0,
  //       "",
  //       monthlySalesList.monthlyData.length >= 2
  //           ? monthlySalesList.monthlyData[1].salesAmount
  //           : 0,
  //       "",
  //       monthlySalesList.monthlyData.length >= 3
  //           ? monthlySalesList.monthlyData[2].salesAmount
  //           : 0,
  //       "",
  //       monthlySalesList.monthlyData.length >= 4
  //           ? monthlySalesList.monthlyData[3].salesAmount
  //           : 0,
  //       "",
  //       monthlySalesList.monthlyData.length >= 5
  //           ? monthlySalesList.monthlyData[4].salesAmount
  //           : 0,
  //       "",
  //       monthlySalesList.monthlyData.length >= 6
  //           ? monthlySalesList.monthlyData[5].salesAmount
  //           : 0,
  //       "",
  //       monthlySalesList.monthlyData.length >= 7
  //           ? monthlySalesList.monthlyData[6].salesAmount
  //           : 0,
  //       "",
  //       monthlySalesList.monthlyData.length >= 8
  //           ? monthlySalesList.monthlyData[7].salesAmount
  //           : 0,
  //       "",
  //       monthlySalesList.monthlyData.length >= 9
  //           ? monthlySalesList.monthlyData[8].salesAmount
  //           : 0,
  //       "",
  //       monthlySalesList.monthlyData.length >= 10
  //           ? monthlySalesList.monthlyData[9].salesAmount
  //           : 0,
  //       "",
  //       monthlySalesList.monthlyData.length >= 11
  //           ? monthlySalesList.monthlyData[10].salesAmount
  //           : 0,
  //       "",
  //       monthlySalesList.monthlyData.length == 12
  //           ? monthlySalesList.monthlyData[11].salesAmount
  //           : 0,
  //       "",
  //     ]);
  //
  //     sheet.appendRow(toCellRow([
  //       "Other Income",
  //       "",
  //       otherIncomeList.subGroupData.isNotEmpty
  //           ? otherIncomeList.subGroupData[0].aprBalance
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length >= 2
  //           ? otherIncomeList.subGroupData[1].mayBalance
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length >= 3
  //           ? otherIncomeList.subGroupData[2].junBalance
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length >= 4
  //           ? otherIncomeList.subGroupData[3].julBalance
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length >= 5
  //           ? otherIncomeList.subGroupData[4].augBalance
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length >= 6
  //           ? otherIncomeList.subGroupData[5].septBalance
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length >= 7
  //           ? otherIncomeList.subGroupData[6].octBalance
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length >= 8
  //           ? otherIncomeList.subGroupData[7].novBalance
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length >= 9
  //           ? otherIncomeList.subGroupData[8].decBalance
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length >= 10
  //           ? otherIncomeList.subGroupData[9].janBalance
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length >= 11
  //           ? otherIncomeList.subGroupData[10].febBalance
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length == 12
  //           ? otherIncomeList.subGroupData[11].marBalance
  //           : 0,
  //       "",
  //     ]);
  //
  //     sheet.appendRow(toCellRow([
  //       "Total Revenue",
  //       "",
  //       otherIncomeList.subGroupData.isNotEmpty
  //           ? otherIncomeList.subGroupData[0].aprBalance +
  //               monthlySalesList.monthlyData[0].salesAmount
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length >= 2
  //           ? otherIncomeList.subGroupData[1].mayBalance +
  //               monthlySalesList.monthlyData[1].salesAmount
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length >= 3
  //           ? otherIncomeList.subGroupData[2].junBalance +
  //               monthlySalesList.monthlyData[2].salesAmount
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length >= 4
  //           ? otherIncomeList.subGroupData[3].julBalance +
  //               monthlySalesList.monthlyData[3].salesAmount
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length >= 5
  //           ? otherIncomeList.subGroupData[4].augBalance +
  //               monthlySalesList.monthlyData[4].salesAmount
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length >= 6
  //           ? otherIncomeList.subGroupData[5].septBalance +
  //               monthlySalesList.monthlyData[5].salesAmount
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length >= 7
  //           ? otherIncomeList.subGroupData[6].octBalance +
  //               monthlySalesList.monthlyData[6].salesAmount
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length >= 8
  //           ? otherIncomeList.subGroupData[7].novBalance +
  //               monthlySalesList.monthlyData[7].salesAmount
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length >= 9
  //           ? otherIncomeList.subGroupData[8].decBalance +
  //               monthlySalesList.monthlyData[8].salesAmount
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length >= 10
  //           ? otherIncomeList.subGroupData[9].janBalance +
  //               monthlySalesList.monthlyData[9].salesAmount
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length >= 11
  //           ? otherIncomeList.subGroupData[10].febBalance +
  //               monthlySalesList.monthlyData[10].salesAmount
  //           : 0,
  //       "",
  //       otherIncomeList.subGroupData.length == 12
  //           ? otherIncomeList.subGroupData[11].marBalance +
  //               monthlySalesList.monthlyData[11].salesAmount
  //           : 0,
  //       "",
  //     ]);
  //
  //     sheet.appendRow(toCellRow([""]);
  //
  //     sheet.appendRow(toCellRow([
  //       "Opening Stock",
  //       "",
  //       monthlyCogsList.isNotEmpty ? monthlyCogsList[0].openingStock : 0,
  //       "",
  //       monthlyCogsList.length >= 2 ? monthlyCogsList[1].openingStock : 0,
  //       "",
  //       monthlyCogsList.length >= 3 ? monthlyCogsList[2].openingStock : 0,
  //       "",
  //       monthlyCogsList.length >= 4 ? monthlyCogsList[3].openingStock : 0,
  //       "",
  //       monthlyCogsList.length >= 5 ? monthlyCogsList[4].openingStock : 0,
  //       "",
  //       monthlyCogsList.length >= 6 ? monthlyCogsList[5].openingStock : 0,
  //       "",
  //       monthlyCogsList.length >= 7 ? monthlyCogsList[6].openingStock : 0,
  //       "",
  //       monthlyCogsList.length >= 8 ? monthlyCogsList[7].openingStock : 0,
  //       "",
  //       monthlyCogsList.length >= 9 ? monthlyCogsList[8].openingStock : 0,
  //       "",
  //       monthlyCogsList.length >= 10 ? monthlyCogsList[9].openingStock : 0,
  //       "",
  //       monthlyCogsList.length >= 11 ? monthlyCogsList[10].openingStock : 0,
  //       "",
  //       monthlyCogsList.length == 12 ? monthlyCogsList[11].openingStock : 0,
  //       ""
  //     ]);
  //     sheet.appendRow(toCellRow([
  //       "Add: Purchases",
  //       "",
  //       monthlyCogsList.isNotEmpty ? monthlyCogsList[0].purchases : 0,
  //       "",
  //       monthlyCogsList.length >= 2 ? monthlyCogsList[1].purchases : 0,
  //       "",
  //       monthlyCogsList.length >= 3 ? monthlyCogsList[2].purchases : 0,
  //       "",
  //       monthlyCogsList.length >= 4 ? monthlyCogsList[3].purchases : 0,
  //       "",
  //       monthlyCogsList.length >= 5 ? monthlyCogsList[4].purchases : 0,
  //       "",
  //       monthlyCogsList.length >= 6 ? monthlyCogsList[5].purchases : 0,
  //       "",
  //       monthlyCogsList.length >= 7 ? monthlyCogsList[6].purchases : 0,
  //       "",
  //       monthlyCogsList.length >= 8 ? monthlyCogsList[7].purchases : 0,
  //       "",
  //       monthlyCogsList.length >= 9 ? monthlyCogsList[8].purchases : 0,
  //       "",
  //       monthlyCogsList.length >= 10 ? monthlyCogsList[9].purchases : 0,
  //       "",
  //       monthlyCogsList.length >= 11 ? monthlyCogsList[10].purchases : 0,
  //       "",
  //       monthlyCogsList.length == 12 ? monthlyCogsList[11].purchases : 0,
  //       ""
  //     ]);
  //     sheet.appendRow(toCellRow([
  //       "Less: Closing Stock",
  //       "",
  //       monthlyCogsList.isNotEmpty ? monthlyCogsList[0].closingStock : 0,
  //       "",
  //       monthlyCogsList.length >= 2 ? monthlyCogsList[1].closingStock : 0,
  //       "",
  //       monthlyCogsList.length >= 3 ? monthlyCogsList[2].closingStock : 0,
  //       "",
  //       monthlyCogsList.length >= 4 ? monthlyCogsList[3].closingStock : 0,
  //       "",
  //       monthlyCogsList.length >= 5 ? monthlyCogsList[4].closingStock : 0,
  //       "",
  //       monthlyCogsList.length >= 6 ? monthlyCogsList[5].closingStock : 0,
  //       "",
  //       monthlyCogsList.length >= 7 ? monthlyCogsList[6].closingStock : 0,
  //       "",
  //       monthlyCogsList.length >= 8 ? monthlyCogsList[7].closingStock : 0,
  //       "",
  //       monthlyCogsList.length >= 9 ? monthlyCogsList[8].closingStock : 0,
  //       "",
  //       monthlyCogsList.length >= 10 ? monthlyCogsList[9].closingStock : 0,
  //       "",
  //       monthlyCogsList.length >= 11 ? monthlyCogsList[10].closingStock : 0,
  //       "",
  //       monthlyCogsList.length == 12 ? monthlyCogsList[11].closingStock : 0,
  //       ""
  //     ]);
  //     sheet.appendRow(toCellRow([
  //       "Cost of Materials Consumed",
  //       "",
  //       monthlyCogsList.isNotEmpty ? monthlyCogsList[0].cogs : 0,
  //       "",
  //       monthlyCogsList.length >= 2 ? monthlyCogsList[1].cogs : 0,
  //       "",
  //       monthlyCogsList.length >= 3 ? monthlyCogsList[2].cogs : 0,
  //       "",
  //       monthlyCogsList.length >= 4 ? monthlyCogsList[3].cogs : 0,
  //       "",
  //       monthlyCogsList.length >= 5 ? monthlyCogsList[4].cogs : 0,
  //       "",
  //       monthlyCogsList.length >= 6 ? monthlyCogsList[5].cogs : 0,
  //       "",
  //       monthlyCogsList.length >= 7 ? monthlyCogsList[6].cogs : 0,
  //       "",
  //       monthlyCogsList.length >= 8 ? monthlyCogsList[7].cogs : 0,
  //       "",
  //       monthlyCogsList.length >= 9 ? monthlyCogsList[8].cogs : 0,
  //       "",
  //       monthlyCogsList.length >= 10 ? monthlyCogsList[9].cogs : 0,
  //       "",
  //       monthlyCogsList.length >= 11 ? monthlyCogsList[10].cogs : 0,
  //       "",
  //       monthlyCogsList.length == 12 ? monthlyCogsList[11].cogs : 0,
  //       ""
  //     ]);
  //     sheet.appendRow(toCellRow([""]);
  //
  //     for (var ytdData in subGroupMonthExpenseWiseList.subGroupData) {
  //       sheet.appendRow(toCellRow([
  //         ytdData.subGroupName,
  //         "",
  //         ytdData.aprBalance,
  //         "",
  //         ytdData.mayBalance,
  //         "",
  //         ytdData.junBalance,
  //         "",
  //         ytdData.julBalance,
  //         "",
  //         ytdData.augBalance,
  //         "",
  //         ytdData.septBalance,
  //         "",
  //         ytdData.octBalance,
  //         "",
  //         ytdData.novBalance,
  //         "",
  //         ytdData.decBalance,
  //         "",
  //         ytdData.janBalance,
  //         "",
  //         ytdData.febBalance,
  //         "",
  //         ytdData.marBalance,
  //         "",
  //       ]);
  //     }
  //     sheet.appendRow(toCellRow([""]);
  //
  //     sheet.appendRow(toCellRow([
  //       "Expenditure",
  //       "",
  //       expenditureMonthlyData.dailyData.isNotEmpty
  //           ? expenditureMonthlyData.dailyData[0].balance
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length >= 2
  //           ? expenditureMonthlyData.dailyData[1].balance
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length >= 3
  //           ? expenditureMonthlyData.dailyData[2].balance
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length >= 4
  //           ? expenditureMonthlyData.dailyData[3].balance
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length >= 5
  //           ? expenditureMonthlyData.dailyData[4].balance
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length >= 6
  //           ? expenditureMonthlyData.dailyData[5].balance
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length >= 7
  //           ? expenditureMonthlyData.dailyData[6].balance
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length >= 8
  //           ? expenditureMonthlyData.dailyData[7].balance
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length >= 9
  //           ? expenditureMonthlyData.dailyData[8].balance
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length >= 10
  //           ? expenditureMonthlyData.dailyData[9].balance
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length >= 11
  //           ? expenditureMonthlyData.dailyData[10].balance
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length == 12
  //           ? expenditureMonthlyData.dailyData[11].balance
  //           : 0,
  //       "",
  //     ]);
  //     sheet.appendRow(toCellRow([""]);
  //
  //     sheet.appendRow(toCellRow(["Direct Expenses"]);
  //     for (var ytdData in directExpensesList.subGroupData) {
  //       sheet.appendRow(toCellRow([
  //         ytdData.subGroupName,
  //         "",
  //         ytdData.aprBalance,
  //         getPercentage(
  //             ytdData.aprBalance, monthlySalesList.monthlyData[0].salesAmount),
  //         ytdData.mayBalance,
  //         getPercentage(
  //             ytdData.mayBalance, monthlySalesList.monthlyData[1].salesAmount),
  //         ytdData.junBalance,
  //         getPercentage(
  //             ytdData.junBalance, monthlySalesList.monthlyData[2].salesAmount),
  //         ytdData.julBalance,
  //         getPercentage(
  //             ytdData.julBalance, monthlySalesList.monthlyData[3].salesAmount),
  //         ytdData.augBalance,
  //         getPercentage(
  //             ytdData.augBalance, monthlySalesList.monthlyData[4].salesAmount),
  //         ytdData.septBalance,
  //         getPercentage(
  //             ytdData.septBalance, monthlySalesList.monthlyData[5].salesAmount),
  //         ytdData.octBalance,
  //         getPercentage(
  //             ytdData.octBalance, monthlySalesList.monthlyData[6].salesAmount),
  //         ytdData.novBalance,
  //         getPercentage(
  //             ytdData.novBalance, monthlySalesList.monthlyData[7].salesAmount),
  //         ytdData.decBalance,
  //         getPercentage(
  //             ytdData.decBalance, monthlySalesList.monthlyData[8].salesAmount),
  //         ytdData.janBalance,
  //         getPercentage(
  //             ytdData.janBalance, monthlySalesList.monthlyData[9].salesAmount),
  //         ytdData.febBalance,
  //         getPercentage(
  //             ytdData.febBalance, monthlySalesList.monthlyData[10].salesAmount),
  //         ytdData.marBalance,
  //         getPercentage(
  //             ytdData.marBalance, monthlySalesList.monthlyData[11].salesAmount),
  //       ]);
  //     }
  //     for (var ytdData in sumOfDirectExpensesList.subGroupData) {
  //       sheet.appendRow(toCellRow([
  //         "Total Direct Expenses",
  //         "",
  //         ytdData.aprBalance,
  //         getPercentage(
  //             ytdData.aprBalance, monthlySalesList.monthlyData[0].salesAmount),
  //         ytdData.mayBalance,
  //         getPercentage(
  //             ytdData.mayBalance, monthlySalesList.monthlyData[1].salesAmount),
  //         ytdData.junBalance,
  //         getPercentage(
  //             ytdData.junBalance, monthlySalesList.monthlyData[2].salesAmount),
  //         ytdData.julBalance,
  //         getPercentage(
  //             ytdData.julBalance, monthlySalesList.monthlyData[3].salesAmount),
  //         ytdData.augBalance,
  //         getPercentage(
  //             ytdData.augBalance, monthlySalesList.monthlyData[4].salesAmount),
  //         ytdData.septBalance,
  //         getPercentage(
  //             ytdData.septBalance, monthlySalesList.monthlyData[5].salesAmount),
  //         ytdData.octBalance,
  //         getPercentage(
  //             ytdData.octBalance, monthlySalesList.monthlyData[6].salesAmount),
  //         ytdData.novBalance,
  //         getPercentage(
  //             ytdData.novBalance, monthlySalesList.monthlyData[7].salesAmount),
  //         ytdData.decBalance,
  //         getPercentage(
  //             ytdData.decBalance, monthlySalesList.monthlyData[8].salesAmount),
  //         ytdData.janBalance,
  //         getPercentage(
  //             ytdData.janBalance, monthlySalesList.monthlyData[9].salesAmount),
  //         ytdData.febBalance,
  //         getPercentage(
  //             ytdData.febBalance, monthlySalesList.monthlyData[10].salesAmount),
  //         ytdData.marBalance,
  //         getPercentage(
  //             ytdData.marBalance, monthlySalesList.monthlyData[11].salesAmount),
  //       ]);
  //     }
  //     sheet.appendRow(toCellRow([""]);
  //     sheet.appendRow(toCellRow(["Indirect Expenses"]);
  //     for (var ytdData in otherIndirectExpensesList.subGroupData) {
  //       sheet.appendRow(toCellRow([
  //         ytdData.subGroupName,
  //         "",
  //         ytdData.aprBalance,
  //         getPercentage(
  //             ytdData.aprBalance, monthlySalesList.monthlyData[0].salesAmount),
  //         ytdData.mayBalance,
  //         getPercentage(
  //             ytdData.mayBalance, monthlySalesList.monthlyData[1].salesAmount),
  //         ytdData.junBalance,
  //         getPercentage(
  //             ytdData.junBalance, monthlySalesList.monthlyData[2].salesAmount),
  //         ytdData.julBalance,
  //         getPercentage(
  //             ytdData.julBalance, monthlySalesList.monthlyData[3].salesAmount),
  //         ytdData.augBalance,
  //         getPercentage(
  //             ytdData.augBalance, monthlySalesList.monthlyData[4].salesAmount),
  //         ytdData.septBalance,
  //         getPercentage(
  //             ytdData.septBalance, monthlySalesList.monthlyData[5].salesAmount),
  //         ytdData.octBalance,
  //         getPercentage(
  //             ytdData.octBalance, monthlySalesList.monthlyData[6].salesAmount),
  //         ytdData.novBalance,
  //         getPercentage(
  //             ytdData.novBalance, monthlySalesList.monthlyData[7].salesAmount),
  //         ytdData.decBalance,
  //         getPercentage(
  //             ytdData.decBalance, monthlySalesList.monthlyData[8].salesAmount),
  //         ytdData.janBalance,
  //         getPercentage(
  //             ytdData.janBalance, monthlySalesList.monthlyData[9].salesAmount),
  //         ytdData.febBalance,
  //         getPercentage(
  //             ytdData.febBalance, monthlySalesList.monthlyData[10].salesAmount),
  //         ytdData.marBalance,
  //         getPercentage(
  //             ytdData.marBalance, monthlySalesList.monthlyData[11].salesAmount),
  //       ]);
  //     }
  //     for (var ytdData in foreignNameMonthExpenseWiseList.subGroupData) {
  //       sheet.appendRow(toCellRow([
  //         ytdData.subGroupName,
  //         "",
  //         ytdData.aprBalance,
  //         getPercentage(
  //             ytdData.aprBalance, monthlySalesList.monthlyData[0].salesAmount),
  //         ytdData.mayBalance,
  //         getPercentage(
  //             ytdData.mayBalance, monthlySalesList.monthlyData[1].salesAmount),
  //         ytdData.junBalance,
  //         getPercentage(
  //             ytdData.junBalance, monthlySalesList.monthlyData[2].salesAmount),
  //         ytdData.julBalance,
  //         getPercentage(
  //             ytdData.julBalance, monthlySalesList.monthlyData[3].salesAmount),
  //         ytdData.augBalance,
  //         getPercentage(
  //             ytdData.augBalance, monthlySalesList.monthlyData[4].salesAmount),
  //         ytdData.septBalance,
  //         getPercentage(
  //             ytdData.septBalance, monthlySalesList.monthlyData[5].salesAmount),
  //         ytdData.octBalance,
  //         getPercentage(
  //             ytdData.octBalance, monthlySalesList.monthlyData[6].salesAmount),
  //         ytdData.novBalance,
  //         getPercentage(
  //             ytdData.novBalance, monthlySalesList.monthlyData[7].salesAmount),
  //         ytdData.decBalance,
  //         getPercentage(
  //             ytdData.decBalance, monthlySalesList.monthlyData[8].salesAmount),
  //         ytdData.janBalance,
  //         getPercentage(
  //             ytdData.janBalance, monthlySalesList.monthlyData[9].salesAmount),
  //         ytdData.febBalance,
  //         getPercentage(
  //             ytdData.febBalance, monthlySalesList.monthlyData[10].salesAmount),
  //         ytdData.marBalance,
  //         getPercentage(
  //             ytdData.marBalance, monthlySalesList.monthlyData[11].salesAmount),
  //       ]);
  //     }
  //     for (var ytdData in totalIndirectExpensesList.subGroupData) {
  //       sheet.appendRow(toCellRow([
  //         "Total Indirect Expenses",
  //         "",
  //         ytdData.aprBalance,
  //         getPercentage(
  //             ytdData.aprBalance, monthlySalesList.monthlyData[0].salesAmount),
  //         ytdData.mayBalance,
  //         getPercentage(
  //             ytdData.mayBalance, monthlySalesList.monthlyData[1].salesAmount),
  //         ytdData.junBalance,
  //         getPercentage(
  //             ytdData.junBalance, monthlySalesList.monthlyData[2].salesAmount),
  //         ytdData.julBalance,
  //         getPercentage(
  //             ytdData.julBalance, monthlySalesList.monthlyData[3].salesAmount),
  //         ytdData.augBalance,
  //         getPercentage(
  //             ytdData.augBalance, monthlySalesList.monthlyData[4].salesAmount),
  //         ytdData.septBalance,
  //         getPercentage(
  //             ytdData.septBalance, monthlySalesList.monthlyData[5].salesAmount),
  //         ytdData.octBalance,
  //         getPercentage(
  //             ytdData.octBalance, monthlySalesList.monthlyData[6].salesAmount),
  //         ytdData.novBalance,
  //         getPercentage(
  //             ytdData.novBalance, monthlySalesList.monthlyData[7].salesAmount),
  //         ytdData.decBalance,
  //         getPercentage(
  //             ytdData.decBalance, monthlySalesList.monthlyData[8].salesAmount),
  //         ytdData.janBalance,
  //         getPercentage(
  //             ytdData.janBalance, monthlySalesList.monthlyData[9].salesAmount),
  //         ytdData.febBalance,
  //         getPercentage(
  //             ytdData.febBalance, monthlySalesList.monthlyData[10].salesAmount),
  //         ytdData.marBalance,
  //         getPercentage(
  //             ytdData.marBalance, monthlySalesList.monthlyData[11].salesAmount),
  //       ]);
  //     }
  //     sheet.appendRow(toCellRow([""]);
  //
  //     final now = DateTime.now();
  //     final fiscalIndex = now.month >= 4 ? now.month - 4 : now.month + 8;
  //     final completedMonths = fiscalIndex + 1;
  //
  //     final financeCosts = foreignNameMonthExpenseWiseList.subGroupData
  //         .firstWhere((e) => e.subGroupName == 'Finance Costs',
  //             orElse: () => throw Exception('No Finance Costs subgroup'));
  //     final otherIncome = otherIncomeList.subGroupData.isNotEmpty
  //         ? otherIncomeList.subGroupData.first
  //         : throw Exception('No Other Income subgroup');
  //     final directExpenses = sumOfDirectExpensesList.subGroupData.isNotEmpty
  //         ? sumOfDirectExpensesList.subGroupData.first
  //         : throw Exception('No Direct Expenses subgroup');
  //     final indirectExpenses = totalIndirectExpensesList.subGroupData.isNotEmpty
  //         ? totalIndirectExpensesList.subGroupData.first
  //         : throw Exception('No Indirect Expenses subgroup');
  //
  // // 2. Build month‐balance arrays:
  //     final financeVals = [
  //       financeCosts.aprBalance,
  //       financeCosts.mayBalance,
  //       financeCosts.junBalance,
  //       financeCosts.julBalance,
  //       financeCosts.augBalance,
  //       financeCosts.septBalance,
  //       financeCosts.octBalance,
  //       financeCosts.novBalance,
  //       financeCosts.decBalance,
  //       financeCosts.janBalance,
  //       financeCosts.febBalance,
  //       financeCosts.marBalance,
  //     ];
  //     final otherVals = [
  //       otherIncome.aprBalance,
  //       otherIncome.mayBalance,
  //       otherIncome.junBalance,
  //       otherIncome.julBalance,
  //       otherIncome.augBalance,
  //       otherIncome.septBalance,
  //       otherIncome.octBalance,
  //       otherIncome.novBalance,
  //       otherIncome.decBalance,
  //       otherIncome.janBalance,
  //       otherIncome.febBalance,
  //       otherIncome.marBalance,
  //     ];
  //     final directVals = [
  //       directExpenses.aprBalance,
  //       directExpenses.mayBalance,
  //       directExpenses.junBalance,
  //       directExpenses.julBalance,
  //       directExpenses.augBalance,
  //       directExpenses.septBalance,
  //       directExpenses.octBalance,
  //       directExpenses.novBalance,
  //       directExpenses.decBalance,
  //       directExpenses.janBalance,
  //       directExpenses.febBalance,
  //       directExpenses.marBalance,
  //     ];
  //     final indirectVals = [
  //       indirectExpenses.aprBalance,
  //       indirectExpenses.mayBalance,
  //       indirectExpenses.junBalance,
  //       indirectExpenses.julBalance,
  //       indirectExpenses.augBalance,
  //       indirectExpenses.septBalance,
  //       indirectExpenses.octBalance,
  //       indirectExpenses.novBalance,
  //       indirectExpenses.decBalance,
  //       indirectExpenses.janBalance,
  //       indirectExpenses.febBalance,
  //       indirectExpenses.marBalance,
  //     ];
  //
  //     final rowEbitda = <dynamic>['EBITDA', ''];
  //     final rowPbt = <dynamic>['PBT', ''];
  //
  //     for (var i = 0; i < completedMonths; i++) {
  //       final sales = (i < monthlySalesList.monthlyData.length)
  //           ? monthlySalesList.monthlyData[i].salesAmount
  //           : 0.0;
  //       final cogs = (i < monthlyCogsList.length) ? monthlyCogsList[i].cogs : 0.0;
  //
  //       final fin = financeVals[i];
  //       final oth = otherVals[i];
  //       final dir = directVals[i];
  //       final ind = indirectVals[i];
  //
  //       final ebitda = fin + ((oth + sales) - cogs - dir - ind) + 25000;
  //       final ePct = sales != 0 ? getPercentage(ebitda, sales) : 0.0;
  //       rowEbitda
  //         ..add(ebitda)
  //         ..add(ePct);
  //
  //       final pbt = (oth + sales) - cogs - dir - ind;
  //       final pPct = sales != 0 ? getPercentage(pbt, sales) : 0.0;
  //       rowPbt
  //         ..add(pbt)
  //         ..add(pPct);
  //     }
  //
  //     sheet
  //       ..appendRow(rowEbitda)
  //       ..appendRow(rowPbt);
  //
  //     sheet.appendRow(toCellRow([
  //       'PAT',
  //       "",
  //       expenditureMonthlyData.dailyData.isNotEmpty
  //           ? expenditureMonthlyData.dailyData[0].balance -
  //               revenueMonthlyData.dailyData[0].balance
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length >= 2
  //           ? expenditureMonthlyData.dailyData[1].balance -
  //               monthlySalesList.monthlyData[1].salesAmount
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length >= 3
  //           ? expenditureMonthlyData.dailyData[2].balance -
  //               monthlySalesList.monthlyData[2].salesAmount
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length >= 4
  //           ? expenditureMonthlyData.dailyData[3].balance -
  //               monthlySalesList.monthlyData[3].salesAmount
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length >= 5
  //           ? expenditureMonthlyData.dailyData[4].balance -
  //               monthlySalesList.monthlyData[4].salesAmount
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length >= 6
  //           ? expenditureMonthlyData.dailyData[5].balance -
  //               monthlySalesList.monthlyData[5].salesAmount
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length >= 7
  //           ? expenditureMonthlyData.dailyData[6].balance -
  //               monthlySalesList.monthlyData[6].salesAmount
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length >= 8
  //           ? expenditureMonthlyData.dailyData[7].balance -
  //               monthlySalesList.monthlyData[7].salesAmount
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length >= 9
  //           ? expenditureMonthlyData.dailyData[8].balance -
  //               monthlySalesList.monthlyData[8].salesAmount
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length >= 10
  //           ? expenditureMonthlyData.dailyData[9].balance -
  //               monthlySalesList.monthlyData[9].salesAmount
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length >= 11
  //           ? expenditureMonthlyData.dailyData[10].balance -
  //               monthlySalesList.monthlyData[10].salesAmount
  //           : 0,
  //       "",
  //       expenditureMonthlyData.dailyData.length == 12
  //           ? expenditureMonthlyData.dailyData[11].balance -
  //               monthlySalesList.monthlyData[11].salesAmount
  //           : 0,
  //       "",
  //     ]);
  //
  //     setState(() {
  //       // YtdSalesBarChartData = true;
  //     });
  //
  //     if (kIsWeb) {
  //       final excelBytes = excel.encode()!;
  //       saveAndOpenExcel('monthlyPL.xlsx', excelBytes);
  //     } else {
  //       String storageDir = await getStorageDirectory();
  //       final file = File('$storageDir/monthlyPL.xlsx');
  //       await file.writeAsBytes(excel.encode()!);
  //       OpenFile.open(file.path);
  //     }
  //   }

  Future<void> generateSalesAnalysisYTDExcel() async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Sheet1'];
    // sheet.getColAutoFits;

    sheet.appendRow(
      toCellRow([
        'Particulars',
        'Target - Apr',
        'Apr',
        '%',
        'Target - May',
        'May',
        '%',
        'Target - Jun',
        'Jun',
        '%',
        'Target - Jul',
        'Jul',
        '%',
        'Target - Aug',
        'Aug',
        '%',
        'Target - Sep',
        'Sep',
        '%',
        'Target - Oct',
        'Oct',
        '%',
        'Target - Nov',
        'Nov',
        '%',
        'Target - Dec',
        'Dec',
        '%',
        'Target - Jan',
        'Jan',
        '%',
        'Target - Feb',
        'Feb',
        '%',
        'Target - Mar',
        'Mar',
        '%',
        'YTD',
      ]),
    );

    double calculateYTD(List<dynamic> values) {
      return values.fold(0.0, (sum, item) {
        if (item is num) {
          return sum + item;
        }
        return sum;
      });
    }

    // --- Revenue Row ---
    final List<dynamic> revenueRowData = [
      "Revenue",
      (monthlyMap["IPD SALES TARGET"]?[3] ?? 0) +
          (monthlyMap["MD SALES TARGET"]?[3] ?? 0),
      monthlySalesList.monthlyData.isNotEmpty
          ? monthlySalesList.monthlyData[0].salesAmount
          : 0,
      "",
      (monthlyMap["IPD SALES TARGET"]?[4] ?? 0) +
          (monthlyMap["MD SALES TARGET"]?[4] ?? 0),
      monthlySalesList.monthlyData.length >= 2
          ? monthlySalesList.monthlyData[1].salesAmount
          : 0,
      "",
      (monthlyMap["IPD SALES TARGET"]?[5] ?? 0) +
          (monthlyMap["MD SALES TARGET"]?[5] ?? 0),
      monthlySalesList.monthlyData.length >= 3
          ? monthlySalesList.monthlyData[2].salesAmount
          : 0,
      "",
      (monthlyMap["IPD SALES TARGET"]?[6] ?? 0) +
          (monthlyMap["MD SALES TARGET"]?[6] ?? 0),
      monthlySalesList.monthlyData.length >= 4
          ? monthlySalesList.monthlyData[3].salesAmount
          : 0,
      "",
      (monthlyMap["IPD SALES TARGET"]?[7] ?? 0) +
          (monthlyMap["MD SALES TARGET"]?[7] ?? 0),
      monthlySalesList.monthlyData.length >= 5
          ? monthlySalesList.monthlyData[4].salesAmount
          : 0,
      "",
      (monthlyMap["IPD SALES TARGET"]?[8] ?? 0) +
          (monthlyMap["MD SALES TARGET"]?[8] ?? 0),
      monthlySalesList.monthlyData.length >= 6
          ? monthlySalesList.monthlyData[5].salesAmount
          : 0,
      "",
      (monthlyMap["IPD SALES TARGET"]?[9] ?? 0) +
          (monthlyMap["MD SALES TARGET"]?[9] ?? 0),
      monthlySalesList.monthlyData.length >= 7
          ? monthlySalesList.monthlyData[6].salesAmount
          : 0,
      "",
      (monthlyMap["IPD SALES TARGET"]?[10] ?? 0) +
          (monthlyMap["MD SALES TARGET"]?[10] ?? 0),
      monthlySalesList.monthlyData.length >= 8
          ? monthlySalesList.monthlyData[7].salesAmount
          : 0,
      "",
      (monthlyMap["IPD SALES TARGET"]?[11] ?? 0) +
          (monthlyMap["MD SALES TARGET"]?[11] ?? 0),
      monthlySalesList.monthlyData.length >= 9
          ? monthlySalesList.monthlyData[8].salesAmount
          : 0,
      "",
      (monthlyMap["IPD SALES TARGET"]?[0] ?? 0) +
          (monthlyMap["MD SALES TARGET"]?[0] ?? 0),
      monthlySalesList.monthlyData.length >= 10
          ? monthlySalesList.monthlyData[9].salesAmount
          : 0,
      "",
      (monthlyMap["IPD SALES TARGET"]?[1] ?? 0) +
          (monthlyMap["MD SALES TARGET"]?[1] ?? 0),
      monthlySalesList.monthlyData.length >= 11
          ? monthlySalesList.monthlyData[10].salesAmount
          : 0,
      "",
      (monthlyMap["IPD SALES TARGET"]?[2] ?? 0) +
          (monthlyMap["MD SALES TARGET"]?[2] ?? 0),
      monthlySalesList.monthlyData.length == 12
          ? monthlySalesList.monthlyData[11].salesAmount
          : 0,
      "",
    ];
    revenueRowData.add(
      calculateYTD(revenueRowData.sublist(2).whereType<num>().toList()),
    );
    sheet.appendRow(toCellRow(revenueRowData));

    final List<dynamic> otherIncomeRowData = [
      "Other Income",
      "",
      otherIncomeList.subGroupData.isNotEmpty
          ? otherIncomeList.subGroupData[0].aprBalance
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length >= 2
          ? otherIncomeList.subGroupData[1].mayBalance
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length >= 3
          ? otherIncomeList.subGroupData[2].junBalance
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length >= 4
          ? otherIncomeList.subGroupData[3].julBalance
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length >= 5
          ? otherIncomeList.subGroupData[4].augBalance
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length >= 6
          ? otherIncomeList.subGroupData[5].septBalance
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length >= 7
          ? otherIncomeList.subGroupData[6].octBalance
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length >= 8
          ? otherIncomeList.subGroupData[7].novBalance
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length >= 9
          ? otherIncomeList.subGroupData[8].decBalance
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length >= 10
          ? otherIncomeList.subGroupData[9].janBalance
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length >= 11
          ? otherIncomeList.subGroupData[10].febBalance
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length == 12
          ? otherIncomeList.subGroupData[11].marBalance
          : 0,
      "",
    ];
    otherIncomeRowData.add(
      calculateYTD(otherIncomeRowData.sublist(2).whereType<num>().toList()),
    );
    sheet.appendRow(toCellRow(otherIncomeRowData));

    final List<dynamic> totalRevenueRowData = [
      "Total Revenue",
      "",
      otherIncomeList.subGroupData.isNotEmpty
          ? otherIncomeList.subGroupData[0].aprBalance +
                monthlySalesList.monthlyData[0].salesAmount
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length >= 2
          ? otherIncomeList.subGroupData[1].mayBalance +
                monthlySalesList.monthlyData[1].salesAmount
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length >= 3
          ? otherIncomeList.subGroupData[2].junBalance +
                monthlySalesList.monthlyData[2].salesAmount
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length >= 4
          ? otherIncomeList.subGroupData[3].julBalance +
                monthlySalesList.monthlyData[3].salesAmount
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length >= 5
          ? otherIncomeList.subGroupData[4].augBalance +
                monthlySalesList.monthlyData[4].salesAmount
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length >= 6
          ? otherIncomeList.subGroupData[5].septBalance +
                monthlySalesList.monthlyData[5].salesAmount
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length >= 7
          ? otherIncomeList.subGroupData[6].octBalance +
                monthlySalesList.monthlyData[6].salesAmount
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length >= 8
          ? otherIncomeList.subGroupData[7].novBalance +
                monthlySalesList.monthlyData[7].salesAmount
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length >= 9
          ? otherIncomeList.subGroupData[8].decBalance +
                monthlySalesList.monthlyData[8].salesAmount
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length >= 10
          ? otherIncomeList.subGroupData[9].janBalance +
                monthlySalesList.monthlyData[9].salesAmount
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length >= 11
          ? otherIncomeList.subGroupData[10].febBalance +
                monthlySalesList.monthlyData[10].salesAmount
          : 0,
      "",
      "",
      otherIncomeList.subGroupData.length == 12
          ? otherIncomeList.subGroupData[11].marBalance +
                monthlySalesList.monthlyData[11].salesAmount
          : 0,
      "",
    ];
    totalRevenueRowData.add(
      calculateYTD(totalRevenueRowData.sublist(2).whereType<num>().toList()),
    );
    sheet.appendRow(toCellRow(totalRevenueRowData));

    sheet.appendRow(toCellRow([""]));

    // --- Opening Stock Row ---
    final List<dynamic> openingStockRowData = [
      "Opening Stock",
      (monthlyMap["INVENTORY TARGET"]?[3] ?? 0),
      monthlyCogsList.isNotEmpty ? monthlyCogsList[0].openingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[4] ?? 0),
      monthlyCogsList.length >= 2 ? monthlyCogsList[1].openingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[5] ?? 0),
      monthlyCogsList.length >= 3 ? monthlyCogsList[2].openingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[6] ?? 0),
      monthlyCogsList.length >= 4 ? monthlyCogsList[3].openingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[7] ?? 0),
      monthlyCogsList.length >= 5 ? monthlyCogsList[4].openingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[8] ?? 0),
      monthlyCogsList.length >= 6 ? monthlyCogsList[5].openingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[9] ?? 0),
      monthlyCogsList.length >= 7 ? monthlyCogsList[6].openingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[10] ?? 0),
      monthlyCogsList.length >= 8 ? monthlyCogsList[7].openingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[11] ?? 0),
      monthlyCogsList.length >= 9 ? monthlyCogsList[8].openingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[0] ?? 0),
      monthlyCogsList.length >= 10 ? monthlyCogsList[9].openingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[1] ?? 0),
      monthlyCogsList.length >= 11 ? monthlyCogsList[10].openingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[2] ?? 0),
      monthlyCogsList.length == 12 ? monthlyCogsList[11].openingStock : 0,
      "",
    ];
    openingStockRowData.add(
      calculateYTD(openingStockRowData.sublist(2).whereType<num>().toList()),
    );
    sheet.appendRow(toCellRow(openingStockRowData));

    final List<dynamic> purchasesRowData = [
      "Add: Purchases",
      (monthlyMap["PURCHASE TARGET"]?[3] ?? 0),
      monthlyCogsList.isNotEmpty ? monthlyCogsList[0].purchases : 0,
      "",
      (monthlyMap["PURCHASE TARGET"]?[4] ?? 0),
      monthlyCogsList.length >= 2 ? monthlyCogsList[1].purchases : 0,
      "",
      (monthlyMap["PURCHASE TARGET"]?[5] ?? 0),
      monthlyCogsList.length >= 3 ? monthlyCogsList[2].purchases : 0,
      "",
      (monthlyMap["PURCHASE TARGET"]?[6] ?? 0),
      monthlyCogsList.length >= 4 ? monthlyCogsList[3].purchases : 0,
      "",
      (monthlyMap["PURCHASE TARGET"]?[7] ?? 0),
      monthlyCogsList.length >= 5 ? monthlyCogsList[4].purchases : 0,
      "",
      (monthlyMap["PURCHASE TARGET"]?[8] ?? 0),
      monthlyCogsList.length >= 6 ? monthlyCogsList[5].purchases : 0,
      "",
      (monthlyMap["PURCHASE TARGET"]?[9] ?? 0),
      monthlyCogsList.length >= 7 ? monthlyCogsList[6].purchases : 0,
      "",
      (monthlyMap["PURCHASE TARGET"]?[10] ?? 0),
      monthlyCogsList.length >= 8 ? monthlyCogsList[7].purchases : 0,
      "",
      (monthlyMap["PURCHASE TARGET"]?[11] ?? 0),
      monthlyCogsList.length >= 9 ? monthlyCogsList[8].purchases : 0,
      "",
      (monthlyMap["PURCHASE TARGET"]?[0] ?? 0),
      monthlyCogsList.length >= 10 ? monthlyCogsList[9].purchases : 0,
      "",
      (monthlyMap["PURCHASE TARGET"]?[1] ?? 0),
      monthlyCogsList.length >= 11 ? monthlyCogsList[10].purchases : 0,
      "",
      (monthlyMap["PURCHASE TARGET"]?[2] ?? 0),
      monthlyCogsList.length == 12 ? monthlyCogsList[11].purchases : 0,
      "",
    ];
    purchasesRowData.add(
      calculateYTD(purchasesRowData.sublist(2).whereType<num>().toList()),
    );
    sheet.appendRow(toCellRow(purchasesRowData));

    final List<dynamic> closingStockRowData = [
      "Less: Closing Stock",
      (monthlyMap["INVENTORY TARGET"]?[3] ?? 0),
      monthlyCogsList.isNotEmpty ? monthlyCogsList[0].closingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[4] ?? 0),
      monthlyCogsList.length >= 2 ? monthlyCogsList[1].closingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[5] ?? 0),
      monthlyCogsList.length >= 3 ? monthlyCogsList[2].closingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[6] ?? 0),
      monthlyCogsList.length >= 4 ? monthlyCogsList[3].closingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[7] ?? 0),
      monthlyCogsList.length >= 5 ? monthlyCogsList[4].closingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[8] ?? 0),
      monthlyCogsList.length >= 6 ? monthlyCogsList[5].closingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[9] ?? 0),
      monthlyCogsList.length >= 7 ? monthlyCogsList[6].closingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[10] ?? 0),
      monthlyCogsList.length >= 8 ? monthlyCogsList[7].closingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[11] ?? 0),
      monthlyCogsList.length >= 9 ? monthlyCogsList[8].closingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[0] ?? 0),
      monthlyCogsList.length >= 10 ? monthlyCogsList[9].closingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[1] ?? 0),
      monthlyCogsList.length >= 11 ? monthlyCogsList[10].closingStock : 0,
      "",
      (monthlyMap["INVENTORY TARGET"]?[2] ?? 0),
      monthlyCogsList.length == 12 ? monthlyCogsList[11].closingStock : 0,
      "",
    ];
    closingStockRowData.add(
      calculateYTD(closingStockRowData.sublist(2).whereType<num>().toList()),
    );
    sheet.appendRow(toCellRow(closingStockRowData));

    final List<dynamic> cogsRowData = [
      "Cost of Materials Consumed",
      (monthlyMap["COGS TARGET"]?[3] ?? 0),
      monthlyCogsList.isNotEmpty ? monthlyCogsList[0].cogs : 0,
      "",
      (monthlyMap["COGS TARGET"]?[4] ?? 0),
      monthlyCogsList.length >= 2 ? monthlyCogsList[1].cogs : 0,
      "",
      (monthlyMap["COGS TARGET"]?[5] ?? 0),
      monthlyCogsList.length >= 3 ? monthlyCogsList[2].cogs : 0,
      "",
      (monthlyMap["COGS TARGET"]?[6] ?? 0),
      monthlyCogsList.length >= 4 ? monthlyCogsList[3].cogs : 0,
      "",
      (monthlyMap["COGS TARGET"]?[7] ?? 0),
      monthlyCogsList.length >= 5 ? monthlyCogsList[4].cogs : 0,
      "",
      (monthlyMap["COGS TARGET"]?[8] ?? 0),
      monthlyCogsList.length >= 6 ? monthlyCogsList[5].cogs : 0,
      "",
      (monthlyMap["COGS TARGET"]?[9] ?? 0),
      monthlyCogsList.length >= 7 ? monthlyCogsList[6].cogs : 0,
      "",
      (monthlyMap["COGS TARGET"]?[10] ?? 0),
      monthlyCogsList.length >= 8 ? monthlyCogsList[7].cogs : 0,
      "",
      (monthlyMap["COGS TARGET"]?[11] ?? 0),
      monthlyCogsList.length >= 9 ? monthlyCogsList[8].cogs : 0,
      "",
      (monthlyMap["COGS TARGET"]?[0] ?? 0),
      monthlyCogsList.length >= 10 ? monthlyCogsList[9].cogs : 0,
      "",
      (monthlyMap["COGS TARGET"]?[1] ?? 0),
      monthlyCogsList.length >= 11 ? monthlyCogsList[10].cogs : 0,
      "",
      (monthlyMap["COGS TARGET"]?[2] ?? 0),
      monthlyCogsList.length == 12 ? monthlyCogsList[11].cogs : 0,
      "",
    ];
    cogsRowData.add(
      calculateYTD(cogsRowData.sublist(2).whereType<num>().toList()),
    );
    sheet.appendRow(toCellRow(cogsRowData));
    sheet.appendRow(
      toCellRow([
        "COGS %",
        "",
        "",
        getPercentage(
          monthlyCogsList.isNotEmpty ? monthlyCogsList[0].cogs : 0,
          otherIncomeList.subGroupData.isNotEmpty
              ? otherIncomeList.subGroupData[0].aprBalance +
                    monthlySalesList.monthlyData[0].salesAmount
              : 0,
        ),
        "",
        getPercentage(
          monthlyCogsList.length >= 2 ? monthlyCogsList[1].cogs : 0,
          otherIncomeList.subGroupData.length >= 2
              ? otherIncomeList.subGroupData[0].mayBalance +
                    monthlySalesList.monthlyData[1].salesAmount
              : 0,
        ),
        "",
        getPercentage(
          monthlyCogsList.length >= 3 ? monthlyCogsList[2].cogs : 0,
          otherIncomeList.subGroupData.length >= 3
              ? otherIncomeList.subGroupData[0].junBalance +
                    monthlySalesList.monthlyData[2].salesAmount
              : 0,
        ),
        "",
        getPercentage(
          monthlyCogsList.length >= 4 ? monthlyCogsList[3].cogs : 0,
          otherIncomeList.subGroupData.length >= 4
              ? otherIncomeList.subGroupData[0].julBalance +
                    monthlySalesList.monthlyData[3].salesAmount
              : 0,
        ),
        "",
        getPercentage(
          monthlyCogsList.length >= 5 ? monthlyCogsList[4].cogs : 0,
          otherIncomeList.subGroupData.length >= 5
              ? otherIncomeList.subGroupData[0].augBalance +
                    monthlySalesList.monthlyData[4].salesAmount
              : 0,
        ),
        "",
        getPercentage(
          monthlyCogsList.length >= 6 ? monthlyCogsList[5].cogs : 0,
          otherIncomeList.subGroupData.length >= 6
              ? otherIncomeList.subGroupData[0].septBalance +
                    monthlySalesList.monthlyData[5].salesAmount
              : 0,
        ),
        "",
        getPercentage(
          monthlyCogsList.length >= 7 ? monthlyCogsList[6].cogs : 0,
          otherIncomeList.subGroupData.length >= 7
              ? otherIncomeList.subGroupData[0].octBalance +
                    monthlySalesList.monthlyData[6].salesAmount
              : 0,
        ),
        "",
        getPercentage(
          monthlyCogsList.length >= 8 ? monthlyCogsList[7].cogs : 0,
          otherIncomeList.subGroupData.length >= 8
              ? otherIncomeList.subGroupData[0].novBalance +
                    monthlySalesList.monthlyData[7].salesAmount
              : 0,
        ),
        "",
        getPercentage(
          monthlyCogsList.length >= 9 ? monthlyCogsList[8].cogs : 0,
          otherIncomeList.subGroupData.length >= 9
              ? otherIncomeList.subGroupData[0].decBalance +
                    monthlySalesList.monthlyData[8].salesAmount
              : 0,
        ),
        "",
        getPercentage(
          monthlyCogsList.length >= 10 ? monthlyCogsList[9].cogs : 0,
          otherIncomeList.subGroupData.length >= 10
              ? otherIncomeList.subGroupData[0].janBalance +
                    monthlySalesList.monthlyData[9].salesAmount
              : 0,
        ),
        "",
        getPercentage(
          monthlyCogsList.length >= 11 ? monthlyCogsList[10].cogs : 0,
          otherIncomeList.subGroupData.length >= 11
              ? otherIncomeList.subGroupData[0].febBalance +
                    monthlySalesList.monthlyData[10].salesAmount
              : 0,
        ),
        "",
        getPercentage(
          monthlyCogsList.length >= 12 ? monthlyCogsList[11].cogs : 0,
          otherIncomeList.subGroupData.length >= 12
              ? otherIncomeList.subGroupData[0].marBalance +
                    monthlySalesList.monthlyData[11].salesAmount
              : 0,
        ),
      ]),
    );

    sheet.appendRow(toCellRow([""]));

    // --- SubGroup Month Expense Wise List ---
    for (var ytdData in subGroupMonthExpenseWiseList.subGroupData) {
      final List<dynamic> row = [
        ytdData.subGroupName,
        "",
        ytdData.aprBalance,
        "",
        "",
        ytdData.mayBalance,
        "",
        "",
        ytdData.junBalance,
        "",
        "",
        ytdData.julBalance,
        "",
        "",
        ytdData.augBalance,
        "",
        "",
        ytdData.septBalance,
        "",
        "",
        ytdData.octBalance,
        "",
        "",
        ytdData.novBalance,
        "",
        "",
        ytdData.decBalance,
        "",
        "",
        ytdData.janBalance,
        "",
        "",
        ytdData.febBalance,
        "",
        "",
        ytdData.marBalance,
        "",
      ];
      row.add(calculateYTD(row.sublist(2).whereType<num>().toList()));
      sheet.appendRow(toCellRow(row));
    }
    sheet.appendRow(toCellRow([""]));

    // --- Expenditure Row ---
    final List<dynamic> expenditureRowData = [
      "Expenditure",
      "",
      expenditureMonthlyData.dailyData.isNotEmpty
          ? expenditureMonthlyData.dailyData[0].balance
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length >= 2
          ? expenditureMonthlyData.dailyData[1].balance
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length >= 3
          ? expenditureMonthlyData.dailyData[2].balance
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length >= 4
          ? expenditureMonthlyData.dailyData[3].balance
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length >= 5
          ? expenditureMonthlyData.dailyData[4].balance
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length >= 6
          ? expenditureMonthlyData.dailyData[5].balance
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length >= 7
          ? expenditureMonthlyData.dailyData[6].balance
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length >= 8
          ? expenditureMonthlyData.dailyData[7].balance
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length >= 9
          ? expenditureMonthlyData.dailyData[8].balance
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length >= 10
          ? expenditureMonthlyData.dailyData[9].balance
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length >= 11
          ? expenditureMonthlyData.dailyData[10].balance
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length == 12
          ? expenditureMonthlyData.dailyData[11].balance
          : 0,
      "",
    ];

    expenditureRowData.add(
      calculateYTD(expenditureRowData.sublist(2).whereType<num>().toList()),
    );
    sheet.appendRow(toCellRow(expenditureRowData));
    sheet.appendRow(toCellRow([""]));

    sheet.appendRow(toCellRow(["Direct Expenses"]));
    for (var ytdData in directExpensesList.subGroupData) {
      final List<dynamic> row = [
        ytdData.subGroupName,
        "",
        ytdData.aprBalance,
        getPercentage(
          ytdData.aprBalance,
          monthlySalesList.monthlyData[0].salesAmount,
        ),
        "",
        ytdData.mayBalance,
        getPercentage(
          ytdData.mayBalance,
          monthlySalesList.monthlyData[1].salesAmount,
        ),
        "",
        ytdData.junBalance,
        getPercentage(
          ytdData.junBalance,
          monthlySalesList.monthlyData[2].salesAmount,
        ),
        "",
        ytdData.julBalance,
        getPercentage(
          ytdData.julBalance,
          monthlySalesList.monthlyData[3].salesAmount,
        ),
        "",
        ytdData.augBalance,
        getPercentage(
          ytdData.augBalance,
          monthlySalesList.monthlyData[4].salesAmount,
        ),
        "",
        ytdData.septBalance,
        getPercentage(
          ytdData.septBalance,
          monthlySalesList.monthlyData[5].salesAmount,
        ),
        "",
        ytdData.octBalance,
        getPercentage(
          ytdData.octBalance,
          monthlySalesList.monthlyData[6].salesAmount,
        ),
        "",
        ytdData.novBalance,
        getPercentage(
          ytdData.novBalance,
          monthlySalesList.monthlyData[7].salesAmount,
        ),
        "",
        ytdData.decBalance,
        getPercentage(
          ytdData.decBalance,
          monthlySalesList.monthlyData[8].salesAmount,
        ),
        "",
        ytdData.janBalance,
        getPercentage(
          ytdData.janBalance,
          monthlySalesList.monthlyData[9].salesAmount,
        ),
        "",
        ytdData.febBalance,
        getPercentage(
          ytdData.febBalance,
          monthlySalesList.monthlyData[10].salesAmount,
        ),
        "",
        ytdData.marBalance,
        getPercentage(
          ytdData.marBalance,
          monthlySalesList.monthlyData[11].salesAmount,
        ),
      ];
      row.add(
        calculateYTD(row.sublist(2).whereType<num>().toList()),
      ); // YTD for direct expenses
      sheet.appendRow(toCellRow(row));
    }

    for (var ytdData in sumOfDirectExpensesList.subGroupData) {
      final List<dynamic> row = [
        "Total Direct Expenses",
        "",
        ytdData.aprBalance,
        getPercentage(
          ytdData.aprBalance,
          monthlySalesList.monthlyData[0].salesAmount,
        ),
        "",
        ytdData.mayBalance,
        getPercentage(
          ytdData.mayBalance,
          monthlySalesList.monthlyData[1].salesAmount,
        ),
        "",
        ytdData.junBalance,
        getPercentage(
          ytdData.junBalance,
          monthlySalesList.monthlyData[2].salesAmount,
        ),
        "",
        ytdData.julBalance,
        getPercentage(
          ytdData.julBalance,
          monthlySalesList.monthlyData[3].salesAmount,
        ),
        "",
        ytdData.augBalance,
        getPercentage(
          ytdData.augBalance,
          monthlySalesList.monthlyData[4].salesAmount,
        ),
        "",
        ytdData.septBalance,
        getPercentage(
          ytdData.septBalance,
          monthlySalesList.monthlyData[5].salesAmount,
        ),
        "",
        ytdData.octBalance,
        getPercentage(
          ytdData.octBalance,
          monthlySalesList.monthlyData[6].salesAmount,
        ),
        "",
        ytdData.novBalance,
        getPercentage(
          ytdData.novBalance,
          monthlySalesList.monthlyData[7].salesAmount,
        ),
        "",
        ytdData.decBalance,
        getPercentage(
          ytdData.decBalance,
          monthlySalesList.monthlyData[8].salesAmount,
        ),
        "",
        ytdData.janBalance,
        getPercentage(
          ytdData.janBalance,
          monthlySalesList.monthlyData[9].salesAmount,
        ),
        "",
        ytdData.febBalance,
        getPercentage(
          ytdData.febBalance,
          monthlySalesList.monthlyData[10].salesAmount,
        ),
        "",
        ytdData.marBalance,
        getPercentage(
          ytdData.marBalance,
          monthlySalesList.monthlyData[11].salesAmount,
        ),
      ];
      row.add(
        calculateYTD(row.sublist(2).whereType<num>().toList()),
      ); // YTD for total direct expenses
      sheet.appendRow(toCellRow(row));
    }
    sheet.appendRow(toCellRow([""]));

    sheet.appendRow(toCellRow(["Indirect Expenses"]));
    for (var ytdData in otherIndirectExpensesList.subGroupData) {
      final List<dynamic> row = [
        ytdData.subGroupName,
        "",
        ytdData.aprBalance,
        getPercentage(
          ytdData.aprBalance,
          monthlySalesList.monthlyData[0].salesAmount,
        ),
        "",
        ytdData.mayBalance,
        getPercentage(
          ytdData.mayBalance,
          monthlySalesList.monthlyData[1].salesAmount,
        ),
        "",
        ytdData.junBalance,
        getPercentage(
          ytdData.junBalance,
          monthlySalesList.monthlyData[2].salesAmount,
        ),
        "",
        ytdData.julBalance,
        getPercentage(
          ytdData.julBalance,
          monthlySalesList.monthlyData[3].salesAmount,
        ),
        "",
        ytdData.augBalance,
        getPercentage(
          ytdData.augBalance,
          monthlySalesList.monthlyData[4].salesAmount,
        ),
        "",
        ytdData.septBalance,
        getPercentage(
          ytdData.septBalance,
          monthlySalesList.monthlyData[5].salesAmount,
        ),
        "",
        ytdData.octBalance,
        getPercentage(
          ytdData.octBalance,
          monthlySalesList.monthlyData[6].salesAmount,
        ),
        "",
        ytdData.novBalance,
        getPercentage(
          ytdData.novBalance,
          monthlySalesList.monthlyData[7].salesAmount,
        ),
        "",
        ytdData.decBalance,
        getPercentage(
          ytdData.decBalance,
          monthlySalesList.monthlyData[8].salesAmount,
        ),
        "",
        ytdData.janBalance,
        getPercentage(
          ytdData.janBalance,
          monthlySalesList.monthlyData[9].salesAmount,
        ),
        "",
        ytdData.febBalance,
        getPercentage(
          ytdData.febBalance,
          monthlySalesList.monthlyData[10].salesAmount,
        ),
        "",
        ytdData.marBalance,
        getPercentage(
          ytdData.marBalance,
          monthlySalesList.monthlyData[11].salesAmount,
        ),
      ];
      row.add(
        calculateYTD(row.sublist(2).whereType<num>().toList()),
      ); // YTD for other indirect expenses
      sheet.appendRow(toCellRow(row));
    }

    for (var ytdData in foreignNameMonthExpenseWiseList.subGroupData) {
      final List<dynamic> row = [
        ytdData.subGroupName,
        "",
        ytdData.aprBalance,
        getPercentage(
          ytdData.aprBalance,
          monthlySalesList.monthlyData[0].salesAmount,
        ),
        "",
        ytdData.mayBalance,
        getPercentage(
          ytdData.mayBalance,
          monthlySalesList.monthlyData[1].salesAmount,
        ),
        "",
        ytdData.junBalance,
        getPercentage(
          ytdData.junBalance,
          monthlySalesList.monthlyData[2].salesAmount,
        ),
        "",
        ytdData.julBalance,
        getPercentage(
          ytdData.julBalance,
          monthlySalesList.monthlyData[3].salesAmount,
        ),
        "",
        ytdData.augBalance,
        getPercentage(
          ytdData.augBalance,
          monthlySalesList.monthlyData[4].salesAmount,
        ),
        "",
        ytdData.septBalance,
        getPercentage(
          ytdData.septBalance,
          monthlySalesList.monthlyData[5].salesAmount,
        ),
        "",
        ytdData.octBalance,
        getPercentage(
          ytdData.octBalance,
          monthlySalesList.monthlyData[6].salesAmount,
        ),
        "",
        ytdData.novBalance,
        getPercentage(
          ytdData.novBalance,
          monthlySalesList.monthlyData[7].salesAmount,
        ),
        "",
        ytdData.decBalance,
        getPercentage(
          ytdData.decBalance,
          monthlySalesList.monthlyData[8].salesAmount,
        ),
        "",
        ytdData.janBalance,
        getPercentage(
          ytdData.janBalance,
          monthlySalesList.monthlyData[9].salesAmount,
        ),
        "",
        ytdData.febBalance,
        getPercentage(
          ytdData.febBalance,
          monthlySalesList.monthlyData[10].salesAmount,
        ),
        "",
        ytdData.marBalance,
        getPercentage(
          ytdData.marBalance,
          monthlySalesList.monthlyData[11].salesAmount,
        ),
      ];
      row.add(
        calculateYTD(row.sublist(2).whereType<num>().toList()),
      ); // YTD for foreign name expenses
      sheet.appendRow(toCellRow(row));
    }

    for (var ytdData in totalIndirectExpensesList.subGroupData) {
      final List<dynamic> row = [
        "Total Indirect Expenses",
        "",
        ytdData.aprBalance,
        getPercentage(
          ytdData.aprBalance,
          monthlySalesList.monthlyData[0].salesAmount,
        ),
        "",
        ytdData.mayBalance,
        getPercentage(
          ytdData.mayBalance,
          monthlySalesList.monthlyData[1].salesAmount,
        ),
        "",
        ytdData.junBalance,
        getPercentage(
          ytdData.junBalance,
          monthlySalesList.monthlyData[2].salesAmount,
        ),
        "",
        ytdData.julBalance,
        getPercentage(
          ytdData.julBalance,
          monthlySalesList.monthlyData[3].salesAmount,
        ),
        "",
        ytdData.augBalance,
        getPercentage(
          ytdData.augBalance,
          monthlySalesList.monthlyData[4].salesAmount,
        ),
        "",
        ytdData.septBalance,
        getPercentage(
          ytdData.septBalance,
          monthlySalesList.monthlyData[5].salesAmount,
        ),
        "",
        ytdData.octBalance,
        getPercentage(
          ytdData.octBalance,
          monthlySalesList.monthlyData[6].salesAmount,
        ),
        "",
        ytdData.novBalance,
        getPercentage(
          ytdData.novBalance,
          monthlySalesList.monthlyData[7].salesAmount,
        ),
        "",
        ytdData.decBalance,
        getPercentage(
          ytdData.decBalance,
          monthlySalesList.monthlyData[8].salesAmount,
        ),
        "",
        ytdData.janBalance,
        getPercentage(
          ytdData.janBalance,
          monthlySalesList.monthlyData[9].salesAmount,
        ),
        "",
        ytdData.febBalance,
        getPercentage(
          ytdData.febBalance,
          monthlySalesList.monthlyData[10].salesAmount,
        ),
        "",
        ytdData.marBalance,
        getPercentage(
          ytdData.marBalance,
          monthlySalesList.monthlyData[11].salesAmount,
        ),
      ];
      row.add(
        calculateYTD(row.sublist(2).whereType<num>().toList()),
      ); // YTD for total indirect expenses
      sheet.appendRow(toCellRow(row));
    }
    sheet.appendRow(toCellRow([""]));

    final now = DateTime.now();
    final fiscalIndex = now.month >= 4 ? now.month - 4 : now.month + 8;
    final completedMonths = fiscalIndex + 1;

    final financeCosts = foreignNameMonthExpenseWiseList.subGroupData
        .firstWhere(
          (e) => e.subGroupName == 'Finance Costs',
          orElse: () => throw Exception('No Finance Costs subgroup'),
        );
    final otherIncome = otherIncomeList.subGroupData.isNotEmpty
        ? otherIncomeList.subGroupData.first
        : throw Exception('No Other Income subgroup');
    final directExpenses = sumOfDirectExpensesList.subGroupData.isNotEmpty
        ? sumOfDirectExpensesList.subGroupData.first
        : throw Exception('No Direct Expenses subgroup');
    final indirectExpenses = totalIndirectExpensesList.subGroupData.isNotEmpty
        ? totalIndirectExpensesList.subGroupData.first
        : throw Exception('No Indirect Expenses subgroup');

    // 2. Build month‐balance arrays:
    final financeVals = [
      financeCosts.aprBalance,
      financeCosts.mayBalance,
      financeCosts.junBalance,
      financeCosts.julBalance,
      financeCosts.augBalance,
      financeCosts.septBalance,
      financeCosts.octBalance,
      financeCosts.novBalance,
      financeCosts.decBalance,
      financeCosts.janBalance,
      financeCosts.febBalance,
      financeCosts.marBalance,
    ];
    final otherVals = [
      otherIncome.aprBalance,
      otherIncome.mayBalance,
      otherIncome.junBalance,
      otherIncome.julBalance,
      otherIncome.augBalance,
      otherIncome.septBalance,
      otherIncome.octBalance,
      otherIncome.novBalance,
      otherIncome.decBalance,
      otherIncome.janBalance,
      otherIncome.febBalance,
      otherIncome.marBalance,
    ];
    final directVals = [
      directExpenses.aprBalance,
      directExpenses.mayBalance,
      directExpenses.junBalance,
      directExpenses.julBalance,
      directExpenses.augBalance,
      directExpenses.septBalance,
      directExpenses.octBalance,
      directExpenses.novBalance,
      directExpenses.decBalance,
      directExpenses.janBalance,
      directExpenses.febBalance,
      directExpenses.marBalance,
    ];
    final indirectVals = [
      indirectExpenses.aprBalance,
      indirectExpenses.mayBalance,
      indirectExpenses.junBalance,
      indirectExpenses.julBalance,
      indirectExpenses.augBalance,
      indirectExpenses.septBalance,
      indirectExpenses.octBalance,
      indirectExpenses.novBalance,
      indirectExpenses.decBalance,
      indirectExpenses.janBalance,
      indirectExpenses.febBalance,
      indirectExpenses.marBalance,
    ];

    final rowEbitda = <dynamic>['EBITDA', ''];
    final rowPbt = <dynamic>['PBT', ''];

    double totalEbitda = 0.0;
    double totalPbt = 0.0;
    double totalSalesForPercentage = 0.0;

    for (var i = 0; i < completedMonths; i++) {
      final sales = (i < monthlySalesList.monthlyData.length)
          ? monthlySalesList.monthlyData[i].salesAmount
          : 0.0;
      final cogs = (i < monthlyCogsList.length) ? monthlyCogsList[i].cogs : 0.0;

      final fin = financeVals[i];
      final oth = otherVals[i];
      final dir = directVals[i];
      final ind = indirectVals[i];

      final ebitda = fin + ((oth + sales) - cogs - dir - ind) + 25000;
      final ePct = sales != 0 ? getPercentage(ebitda, sales) : 0.0;
      rowEbitda
        ..add(ebitda)
        ..add(ePct)
        ..add('');

      totalEbitda += ebitda;
      totalSalesForPercentage += sales;

      final pbt = (oth + sales) - cogs - dir - ind;
      final pPct = sales != 0 ? getPercentage(pbt, sales) : 0.0;
      rowPbt
        ..add(pbt)
        ..add(pPct)
        ..add('');
      totalPbt += pbt;
    }

    // Add YTD for EBITDA
    rowEbitda.add(totalEbitda);
    rowEbitda.add(
      totalSalesForPercentage != 0
          ? getPercentage(totalEbitda, totalSalesForPercentage)
          : 0.0,
    );

    // Add YTD for PBT
    rowPbt.add(totalPbt);
    rowPbt.add(
      totalSalesForPercentage != 0
          ? getPercentage(totalPbt, totalSalesForPercentage)
          : 0.0,
    );

    sheet
      ..appendRow(toCellRowList(rowEbitda))
      ..appendRow(toCellRowList(rowPbt));

    // --- PAT Row ---
    final List<dynamic> patRowData = [
      'PAT',
      "",
      expenditureMonthlyData.dailyData.isNotEmpty
          ? expenditureMonthlyData.dailyData[0].balance -
                revenueMonthlyData.dailyData[0].balance
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length >= 2
          ? expenditureMonthlyData.dailyData[1].balance -
                monthlySalesList.monthlyData[1].salesAmount
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length >= 3
          ? expenditureMonthlyData.dailyData[2].balance -
                monthlySalesList.monthlyData[2].salesAmount
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length >= 4
          ? expenditureMonthlyData.dailyData[3].balance -
                monthlySalesList.monthlyData[3].salesAmount
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length >= 5
          ? expenditureMonthlyData.dailyData[4].balance -
                monthlySalesList.monthlyData[4].salesAmount
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length >= 6
          ? expenditureMonthlyData.dailyData[5].balance -
                monthlySalesList.monthlyData[5].salesAmount
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length >= 7
          ? expenditureMonthlyData.dailyData[6].balance -
                monthlySalesList.monthlyData[6].salesAmount
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length >= 8
          ? expenditureMonthlyData.dailyData[7].balance -
                monthlySalesList.monthlyData[7].salesAmount
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length >= 9
          ? expenditureMonthlyData.dailyData[8].balance -
                monthlySalesList.monthlyData[8].salesAmount
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length >= 10
          ? expenditureMonthlyData.dailyData[9].balance -
                monthlySalesList.monthlyData[9].salesAmount
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length >= 11
          ? expenditureMonthlyData.dailyData[10].balance -
                monthlySalesList.monthlyData[10].salesAmount
          : 0,
      "",
      "",
      expenditureMonthlyData.dailyData.length == 12
          ? expenditureMonthlyData.dailyData[11].balance -
                monthlySalesList.monthlyData[11].salesAmount
          : 0,
      "",
    ];
    patRowData.add(
      calculateYTD(patRowData.sublist(2).whereType<num>().toList()),
    ); // YTD for PAT
    sheet.appendRow(toCellRow(patRowData));

    setState(() {
      // YtdSalesBarChartData = true;
    });

    if (kIsWeb) {
      final excelBytes = excel.encode()!;
      saveAndOpenExcel('monthlyPL.xlsx', excelBytes);
    } else {
      String storageDir = await getStorageDirectory();
      final file = File('$storageDir/monthlyPL.xlsx');
      await file.writeAsBytes(excel.encode()!);
      OpenFile.open(file.path);
    }
  }

  // Future<void> generateSummarySalesAnalysisYTDExcel() async {
  //   final excel = xl.Excel.createExcel();
  //   final sheet = excel['Sheet1'];
  //   // sheet.getColAutoFits;
  //
  //   sheet.appendRow(
  //     toCellRow([
  //       'Particulars',
  //       'Target',
  //       'Actual',
  //       'Target % vs Target',
  //     ]),
  //   );
  //
  //   double calculateYTD(List<dynamic> values) {
  //     return values.fold(0.0, (sum, item) {
  //       if (item is num) {
  //         return sum + item;
  //       }
  //       return sum;
  //     });
  //   }
  //
  //   // --- Revenue Row ---
  //   final List<dynamic> revenueRowData = [
  //     "Net Sales",
  //     (monthlyMap["IPD SALES TARGET"]?[3] ?? 0) +
  //         (monthlyMap["MD SALES TARGET"]?[3] ?? 0),
  //     monthlySalesList.monthlyData.length == 12
  //         ? monthlySalesList.monthlyData[11].salesAmount
  //         : 0,
  //     "",
  //   ];
  //   sheet.appendRow(toCellRow(revenueRowData));
  //
  //   final List<dynamic> cogsRowData = [
  //     "COGS",
  //     (monthlyMap["COGS TARGET"]![3] ),
  //     monthlyCogsList.isNotEmpty ? monthlyCogsList[0].cogs : 0,
  //     "",
  //   ];
  //   sheet.appendRow(toCellRow(cogsRowData));
  //
  //   sheet.appendRow(toCellRow([""]));
  //
  //   final List<dynamic> grossProfitData = [
  //     "Gross Profit",
  //     (((monthlyMap["IPD SALES TARGET"]?[3] ?? 0) +
  //         (monthlyMap["MD SALES TARGET"]?[3] ?? 0)) - monthlyMap["COGS TARGET"]![3]),
  //     monthlyCogsList.isNotEmpty ? monthlySalesList.monthlyData[0].salesAmount - monthlyCogsList[0].cogs : 0,
  //     "",
  //   ];
  //   sheet.appendRow(toCellRow(grossProfitData));
  //
  //   final List<dynamic> totalExpensesData = [
  //     "Total in Operating Expenses",
  //     "",
  //     sumOfDirectExpensesList.subGroupData.first.aprBalance + totalIndirectExpensesList.subGroupData.first.aprBalance,
  //     "",
  //   ];
  //   sheet.appendRow(toCellRow(totalExpensesData));
  //
  //   sheet.appendRow(toCellRow([""]));
  //
  //
  //
  //   sheet.appendRow(toCellRow([""]));
  //
  //   final now = DateTime.now();
  //   final fiscalIndex = now.month >= 4 ? now.month - 4 : now.month + 8;
  //   final completedMonths = fiscalIndex + 1;
  //
  //   final financeCosts = foreignNameMonthExpenseWiseList.subGroupData
  //       .firstWhere(
  //         (e) => e.subGroupName == 'Finance Costs',
  //         orElse: () => throw Exception('No Finance Costs subgroup'),
  //       );
  //   final otherIncome = otherIncomeList.subGroupData.isNotEmpty
  //       ? otherIncomeList.subGroupData.first
  //       : throw Exception('No Other Income subgroup');
  //   final directExpenses = sumOfDirectExpensesList.subGroupData.isNotEmpty
  //       ? sumOfDirectExpensesList.subGroupData.first
  //       : throw Exception('No Direct Expenses subgroup');
  //   final indirectExpenses = totalIndirectExpensesList.subGroupData.isNotEmpty
  //       ? totalIndirectExpensesList.subGroupData.first
  //       : throw Exception('No Indirect Expenses subgroup');
  //
  //   final financeVals = [
  //     financeCosts.aprBalance,
  //     financeCosts.mayBalance,
  //     financeCosts.junBalance,
  //     financeCosts.julBalance,
  //     financeCosts.augBalance,
  //     financeCosts.septBalance,
  //     financeCosts.octBalance,
  //     financeCosts.novBalance,
  //     financeCosts.decBalance,
  //     financeCosts.janBalance,
  //     financeCosts.febBalance,
  //     financeCosts.marBalance,
  //   ];
  //   final otherVals = [
  //     otherIncome.aprBalance,
  //     otherIncome.mayBalance,
  //     otherIncome.junBalance,
  //     otherIncome.julBalance,
  //     otherIncome.augBalance,
  //     otherIncome.septBalance,
  //     otherIncome.octBalance,
  //     otherIncome.novBalance,
  //     otherIncome.decBalance,
  //     otherIncome.janBalance,
  //     otherIncome.febBalance,
  //     otherIncome.marBalance,
  //   ];
  //   final directVals = [
  //     directExpenses.aprBalance,
  //     directExpenses.mayBalance,
  //     directExpenses.junBalance,
  //     directExpenses.julBalance,
  //     directExpenses.augBalance,
  //     directExpenses.septBalance,
  //     directExpenses.octBalance,
  //     directExpenses.novBalance,
  //     directExpenses.decBalance,
  //     directExpenses.janBalance,
  //     directExpenses.febBalance,
  //     directExpenses.marBalance,
  //   ];
  //   final indirectVals = [
  //     indirectExpenses.aprBalance,
  //     indirectExpenses.mayBalance,
  //     indirectExpenses.junBalance,
  //     indirectExpenses.julBalance,
  //     indirectExpenses.augBalance,
  //     indirectExpenses.septBalance,
  //     indirectExpenses.octBalance,
  //     indirectExpenses.novBalance,
  //     indirectExpenses.decBalance,
  //     indirectExpenses.janBalance,
  //     indirectExpenses.febBalance,
  //     indirectExpenses.marBalance,
  //   ];
  //
  //   final rowEbitda = <dynamic>['EBITDA', ''];
  //
  //   double totalEbitda = 0.0;
  //   double totalSalesForPercentage = 0.0;
  //
  //   for (var i = 0; i < completedMonths; i++) {
  //     final sales = (i < monthlySalesList.monthlyData.length)
  //         ? monthlySalesList.monthlyData[i].salesAmount
  //         : 0.0;
  //     final cogs = (i < monthlyCogsList.length) ? monthlyCogsList[i].cogs : 0.0;
  //
  //     final fin = financeVals[i];
  //     final oth = otherVals[i];
  //     final dir = directVals[i];
  //     final ind = indirectVals[i];
  //
  //     final ebitda = fin + ((oth + sales) - cogs - dir - ind) + 25000;
  //     final ePct = sales != 0 ? getPercentage(ebitda, sales) : 0.0;
  //     rowEbitda
  //       ..add(ebitda)
  //       ..add(ePct)
  //       ..add('');
  //
  //     totalEbitda += ebitda;
  //     totalSalesForPercentage += sales;
  //
  //   }
  //
  //   rowEbitda.add(totalEbitda);
  //   rowEbitda.add(
  //     totalSalesForPercentage != 0
  //         ? getPercentage(totalEbitda, totalSalesForPercentage)
  //         : 0.0,
  //   );
  //
  //   sheet.appendRow(toCellRowList(rowEbitda));
  //
  //   final List<dynamic> ebitdaData = [
  //     "EBITDA",
  //     "",
  //     sumOfDirectExpensesList.subGroupData.first.aprBalance + totalIndirectExpensesList.subGroupData.first.aprBalance,
  //     "",
  //   ];
  //   sheet.appendRow(toCellRow(ebitdaData));
  //
  //
  //   setState(() {
  //     // YtdSalesBarChartData = true;
  //   });
  //
  //   if (kIsWeb) {
  //     final excelBytes = excel.encode()!;
  //     saveAndOpenExcel('monthlyPL.xlsx', excelBytes);
  //   } else {
  //     String storageDir = await getStorageDirectory();
  //     final file = File('$storageDir/monthlyPL.xlsx');
  //     await file.writeAsBytes(excel.encode()!);
  //     OpenFile.open(file.path);
  //   }
  // }

  // Future<void> generateSummarySalesAnalysisYTDExcel() async {
  //   final excel = xl.Excel.createExcel();
  //   final sheet = excel['Sheet1'];
  //
  //   // 1. Define Headers
  //   sheet.appendRow(
  //     toCellRow([
  //       'Particulars',
  //       'Target',
  //       'Actual',
  //       'Target % vs Target',
  //     ]),
  //   );
  //
  //   // 2. Determine Current Fiscal Month Index
  //   // If April (4) -> Index 0. If March (3) -> Index 11.
  //   final now = DateTime.now();
  //   final int fiscalMonthIndex = now.month >= 4 ? now.month - 4 : now.month + 8;
  //
  //   // The map index starts at 3 for April (based on your snippet: monthlyMap["..."]?[3])
  //   final int mapTargetIndex = 3 + fiscalMonthIndex;
  //
  //   // 3. Helper to get balance from your specific class based on index
  //   double getBalanceForMonth(SubGroupMonthWiseRevenueExpensesData data, int index) {
  //     switch (index) {
  //       case 0: return data.aprBalance;
  //       case 1: return data.mayBalance;
  //       case 2: return data.junBalance;
  //       case 3: return data.julBalance;
  //       case 4: return data.augBalance;
  //       case 5: return data.septBalance;
  //       case 6: return data.octBalance;
  //       case 7: return data.novBalance;
  //       case 8: return data.decBalance;
  //       case 9: return data.janBalance;
  //       case 10: return data.febBalance;
  //       case 11: return data.marBalance;
  //       default: return 0.0;
  //     }
  //   }
  //
  //   // 4. Helper for Percentage Calculation
  //   double calculatePercentage(double actual, double target) {
  //     if (target == 0) return 0.0;
  //     return (actual / target) * 100;
  //   }
  //
  //   // --- PREPARE DATA ---
  //
  //   // A. Net Sales
  //   // Target: Sum of IPD and MD at the specific column index
  //   double salesTarget = (monthlyMap["IPD SALES TARGET"]?[mapTargetIndex] ?? 0) +
  //       (monthlyMap["MD SALES TARGET"]?[mapTargetIndex] ?? 0);
  //
  //   // Actual: Check if data exists for this month index
  //   double salesActual = (fiscalMonthIndex < monthlySalesList.monthlyData.length)
  //       ? monthlySalesList.monthlyData[fiscalMonthIndex].salesAmount
  //       : 0.0;
  //
  //   // B. COGS
  //   double cogsTarget = (monthlyMap["COGS TARGET"]?[mapTargetIndex] ?? 0);
  //   double cogsActual = (fiscalMonthIndex < monthlyCogsList.length)
  //       ? monthlyCogsList[fiscalMonthIndex].cogs
  //       : 0.0;
  //
  //   // C. Gross Profit
  //   double gpTarget = salesTarget - cogsTarget;
  //   double gpActual = salesActual - cogsActual;
  //
  //   // D. Expenses (Actuals Only)
  //   // We use the helper function to get the correct month's balance
  //   double directExpActual = 0.0;
  //   if (sumOfDirectExpensesList.subGroupData.isNotEmpty) {
  //     directExpActual = getBalanceForMonth(sumOfDirectExpensesList.subGroupData.first, fiscalMonthIndex);
  //   }
  //
  //   double indirectExpActual = 0.0;
  //   if (totalIndirectExpensesList.subGroupData.isNotEmpty) {
  //     indirectExpActual = getBalanceForMonth(totalIndirectExpensesList.subGroupData.first, fiscalMonthIndex);
  //   }
  //
  //   double totalOpExpActual = directExpActual + indirectExpActual;
  //
  //   // E. EBITDA (Optional: Based on your previous logic)
  //   // You didn't specify target/actual logic for EBITDA in the prompt,
  //   // but usually it is GP - OpExp.
  //   // If you need Finance/Other Income included as per previous code:
  //   double financeActual = 0.0;
  //   if (foreignNameMonthExpenseWiseList.subGroupData.isNotEmpty) {
  //     // Assuming 'Finance Costs' is found
  //     try {
  //       final financeData = foreignNameMonthExpenseWiseList.subGroupData.firstWhere((e) => e.subGroupName == 'Finance Costs');
  //       financeActual = getBalanceForMonth(financeData, fiscalMonthIndex);
  //     } catch (e) {
  //       financeActual = 0;
  //     }
  //   }
  //
  //   double otherIncomeActual = 0.0;
  //   if (otherIncomeList.subGroupData.isNotEmpty) {
  //     otherIncomeActual = getBalanceForMonth(otherIncomeList.subGroupData.first, fiscalMonthIndex);
  //   }
  //
  //   // Formula from previous code: (Other + Sales) - Cogs - Direct - Indirect + Finance(??) + 25000
  //   // Adjust this formula if Finance should be subtracted or added.
  //   // Usually EBITDA = Gross Profit - OpEx + Other Income.
  //   // Below is strictly following your previous logic flow:
  //   double ebitdaActual = financeActual + ((otherIncomeActual + salesActual) - cogsActual - directExpActual - indirectExpActual) + 25000;
  //
  //
  //   // --- APPEND ROWS TO EXCEL ---
  //
  //   // 1. Net Sales Row
  //   sheet.appendRow(toCellRow([
  //     "Net Sales",
  //     salesTarget,
  //     salesActual,
  //     calculatePercentage(salesActual, salesTarget).toStringAsFixed(2) + "%",
  //   ]));
  //
  //   // 2. COGS Row
  //   sheet.appendRow(toCellRow([
  //     "COGS",
  //     cogsTarget,
  //     cogsActual,
  //     calculatePercentage(cogsActual, cogsTarget).toStringAsFixed(2) + "%",
  //   ]));
  //
  //   sheet.appendRow(toCellRow([""])); // Spacer
  //
  //   // 3. Gross Profit Row
  //   sheet.appendRow(toCellRow([
  //     "Gross Profit",
  //     gpTarget,
  //     gpActual,
  //     calculatePercentage(gpActual, gpTarget).toStringAsFixed(2) + "%",
  //   ]));
  //
  //   // 4. Total Operating Expenses Row
  //   // Usually Targets are not defined for OpEx in your map, leaving blank
  //   sheet.appendRow(toCellRow([
  //     "Total in Operating Expenses",
  //     "",
  //     totalOpExpActual,
  //     "",
  //   ]));
  //
  //   sheet.appendRow(toCellRow([""])); // Spacer
  //
  //   // 5. EBITDA Row
  //   sheet.appendRow(toCellRow([
  //     "EBITDA",
  //     "", // No target calculated
  //     ebitdaActual,
  //     "",
  //   ]));
  //
  //   // --- SAVE FILE ---
  //   if (kIsWeb) {
  //     final excelBytes = excel.encode()!;
  //     saveAndOpenExcel('CurrentMonth_PL.xlsx', excelBytes);
  //   } else {
  //     String storageDir = await getStorageDirectory();
  //     final file = File('$storageDir/CurrentMonth_PL.xlsx');
  //     await file.writeAsBytes(excel.encode()!);
  //     OpenFile.open(file.path);
  //   }
  // }

  Future<void> generateSummarySalesAnalysisYTDExcel() async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Sheet1'];

    // 1. Define Headers
    sheet.appendRow(
      toCellRow([
        'Particulars',
        'Target (in Lakhs)',
        'Actual (in Lakhs)',
        'Target % vs Target',
      ]),
    );

    // 2. Determine Current Fiscal Month Index
    final now = DateTime.now();
    final int fiscalMonthIndex = now.month >= 4 ? now.month - 4 : now.month + 8;

    // Map index offset (starts at 3 for April in your map structure)
    final int mapTargetIndex = 3 + fiscalMonthIndex;

    // --- HELPERS ---

    // Helper: Get balance from SubGroupMonthWiseRevenueExpensesData
    double getBalanceForMonth(
      SubGroupMonthWiseRevenueExpensesData data,
      int index,
    ) {
      switch (index) {
        case 0:
          return data.aprBalance;
        case 1:
          return data.mayBalance;
        case 2:
          return data.junBalance;
        case 3:
          return data.julBalance;
        case 4:
          return data.augBalance;
        case 5:
          return data.septBalance;
        case 6:
          return data.octBalance;
        case 7:
          return data.novBalance;
        case 8:
          return data.decBalance;
        case 9:
          return data.janBalance;
        case 10:
          return data.febBalance;
        case 11:
          return data.marBalance;
        default:
          return 0.0;
      }
    }

    // Helper: Calculate Percentage safely
    double calculatePercentage(double numerator, double denominator) {
      if (denominator == 0) return 0.0;
      return (numerator / denominator) * 100;
    }

    // Helper: Convert to Lakhs
    double toLakhs(double value) {
      return value / 100000;
    }

    // --- PREPARE DATA (Raw Values) ---

    // A. Net Sales
    double salesTarget =
        (monthlyMap["IPD SALES TARGET"]?[mapTargetIndex] ?? 0) +
        (monthlyMap["MD SALES TARGET"]?[mapTargetIndex] ?? 0);

    double salesActual =
        (fiscalMonthIndex < monthlySalesList.monthlyData.length)
        ? monthlySalesList.monthlyData[fiscalMonthIndex].salesAmount
        : 0.0;

    // B. COGS
    double cogsTarget = (monthlyMap["COGS TARGET"]?[mapTargetIndex] ?? 0);
    double cogsActual = (fiscalMonthIndex < monthlyCogsList.length)
        ? monthlyCogsList[fiscalMonthIndex].cogs
        : 0.0;

    // C. Gross Profit
    double gpTarget = salesTarget - cogsTarget;
    double gpActual = salesActual - cogsActual;

    // D. Expenses (Actuals Only)
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

    // E. EBITDA (Actual Only)
    // Assuming 'Finance Costs' and 'Other Income' logic exists as per previous context
    double financeActual = 0.0;
    if (foreignNameMonthExpenseWiseList.subGroupData.isNotEmpty) {
      try {
        final financeData = foreignNameMonthExpenseWiseList.subGroupData
            .firstWhere((e) => e.subGroupName == 'Finance Costs');
        financeActual = getBalanceForMonth(financeData, fiscalMonthIndex);
      } catch (e) {
        financeActual = 0;
      }
    }

    double otherIncomeActual = 0.0;
    if (otherIncomeList.subGroupData.isNotEmpty) {
      otherIncomeActual = getBalanceForMonth(
        otherIncomeList.subGroupData.first,
        fiscalMonthIndex,
      );
    }

    // Formula: (Other Income + Sales) - COGS - Direct Exp - Indirect Exp + Finance + 25000
    double ebitdaActual =
        financeActual +
        ((otherIncomeActual + salesActual) -
            cogsActual -
            directExpActual -
            indirectExpActual) +
        25000;

    // --- APPEND ROWS (Values converted to Lakhs) ---

    // 1. Net Sales
    sheet.appendRow(
      toCellRow([
        "Net Sales",
        toLakhs(salesTarget).toStringAsFixed(2),
        toLakhs(salesActual).toStringAsFixed(2),
        "${calculatePercentage(salesActual, salesTarget).toStringAsFixed(2)}%",
      ]),
    );

    // 2. COGS
    sheet.appendRow(
      toCellRow([
        "COGS",
        toLakhs(cogsTarget).toStringAsFixed(2),
        toLakhs(cogsActual).toStringAsFixed(2),
        "${calculatePercentage(cogsActual, cogsTarget).toStringAsFixed(2)}%",
      ]),
    );

    sheet.appendRow(toCellRow([""]));

    // 3. Gross Profit
    sheet.appendRow(
      toCellRow([
        "Gross Profit",
        toLakhs(gpTarget).toStringAsFixed(2),
        toLakhs(gpActual).toStringAsFixed(2),
        "${calculatePercentage(gpActual, gpTarget).toStringAsFixed(2)}%",
      ]),
    );

    // 4. GP% Row (New)
    // Target: GP Target % of Sales Target
    // Actual: GP Actual % of Sales Actual

    // 5. Total Operating Expenses
    sheet.appendRow(
      toCellRow([
        "Total in Operating Expenses",
        "",
        toLakhs(totalOpExpActual).toStringAsFixed(2),
        "",
      ]),
    );

    sheet.appendRow(toCellRow([""]));

    // 6. EBITDA
    sheet.appendRow(
      toCellRow(["EBITDA", "", toLakhs(ebitdaActual).toStringAsFixed(2), ""]),
    );

    sheet.appendRow(
      toCellRow([
        "GP%",
        "${calculatePercentage(gpTarget, salesTarget).toStringAsFixed(2)}%",
        "${calculatePercentage(gpActual, salesActual).toStringAsFixed(2)}%",
        "", // No "Target vs Target" for percentage rows usually
      ]),
    );

    // 7. EBITDA% Row (New)
    // Actual: EBITDA Actual % of Sales Actual
    sheet.appendRow(
      toCellRow([
        "EBITDA%",
        "",
        "${calculatePercentage(ebitdaActual, salesActual).toStringAsFixed(2)}%",
        "",
      ]),
    );

    // --- SAVE FILE ---
    if (kIsWeb) {
      final excelBytes = excel.encode()!;
      saveAndOpenExcel('CurrentMonth_PL.xlsx', excelBytes);
    } else {
      String storageDir = await getStorageDirectory();
      final file = File('$storageDir/CurrentMonth_PL.xlsx');
      await file.writeAsBytes(excel.encode()!);
      OpenFile.open(file.path);
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
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
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
    _dateFilterTarget();
    _loadSubGroupWiseAnalysis(0, "", "");
    _loadMonthlyAnalysisExpenditure();
    _loadMonthlySalesBarChartData();
    _loadMonthlyAnalysisRevenue();
    _loadMonthlyAnalysisPurchase();
    _loadMonthlyAnalysisInventory();
    _loadMonthlyAnalysisInventoryClosing();
    _loadSubGroupMonthWiseAnalysisExpenditure();
    _loadSubGroupMonthWiseAnalysisRevenue();
    _loadOtherIncomeMonthWiseAnalysisRevenue();
    _loadForeignNameMonthWiseAnalysisRevenue();
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

  Future<void> generateMonthlyRevenueExcel(MonthlySalesList list) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Month', 'Revenue', 'Target']));
      for (var data in list.monthlyData) {
        sheet.appendRow(
          toCellRow([data.monthName, data.salesAmount, data.salesTarget]),
        );
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('monthlyRevenue.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthlyRevenue.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateMonthlyRevenuePDF(MonthlySalesList list) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Monthly Revenue',
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
                      'Revenue',
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
                for (var data in monthlySalesList.monthlyData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        data.monthName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.salesAmount.toString(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.salesTarget.toString(),
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
        // final bytes = await pdf.save();
        // final blob = html.Blob([bytes], 'application/pdf');
        // final url = html.Url.createObjectUrlFromBlob(blob);
        //
        // html.window.open(url, '_blank');

        // Generate bytes
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthlyRevenue.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateMonthlyPurchaseExcel(
    DailyAnalysisExpensesList list,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Month', 'Purchase', 'Target']));
      for (var data in list.dailyData) {
        sheet.appendRow(toCellRow([data.date, data.balance, data.target]));
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('monthlyPurchase.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthlyPurchase.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateMonthlyPurchasePDF(
    DailyAnalysisExpensesList list,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Monthly Purchase',
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
                      'Purchase',
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
                for (var data in purchaseMonthlyData.dailyData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        data.date,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.balance.toString(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.target.toString(),
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
        // final bytes = await pdf.save();
        // final blob = html.Blob([bytes], 'application/pdf');
        // final url = html.Url.createObjectUrlFromBlob(blob);
        //
        // html.window.open(url, '_blank');

        // Generate bytes
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthlyPurchase.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateMonthlyExpenditureExcel(
    DailyAnalysisExpensesList list,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Month', 'Expenditure']));
      for (var data in list.dailyData) {
        sheet.appendRow(toCellRow([data.date, data.balance]));
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('monthlyExpenditure.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthlyExpenditure.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateMonthlyExpenditurePDF(
    DailyAnalysisExpensesList list,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Monthly Expenditure',
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
                      'Expenditure',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var data in expenditureMonthlyData.dailyData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        data.date,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.balance.toString(),
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
        // final bytes = await pdf.save();
        // final blob = html.Blob([bytes], 'application/pdf');
        // final url = html.Url.createObjectUrlFromBlob(blob);
        //
        // html.window.open(url, '_blank');

        // Generate bytes
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthlyExpenditure.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateMonthlyInventoryExcel(MonthlyCogsList list) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow(['Month', 'Opening Stock', 'Closing Stock', 'Target']),
      );
      for (var data in list.monthlyData) {
        sheet.appendRow(
          toCellRow([
            data.monthYear,
            data.openingStock,
            data.closingStock,
            data.inventoryTarget,
          ]),
        );
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('monthlyInventory.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthlyInventory.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateMonthlyInventoryPDF(MonthlyCogsList list) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Monthly Inventory',
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
                      'Opening Stock',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Closing Stock',
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
                for (var data in monthlyCOGS.monthlyData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        data.monthYear,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.openingStock.toString(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.closingStock.toString(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.inventoryTarget.toString(),
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
        // final bytes = await pdf.save();
        // final blob = html.Blob([bytes], 'application/pdf');
        // final url = html.Url.createObjectUrlFromBlob(blob);
        //
        // html.window.open(url, '_blank');

        // Generate bytes
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthlyInventory.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateMonthlyCOGSExcel(MonthlyCogsList list) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Month', 'COGS', 'Target']));
      for (var data in list.monthlyData) {
        sheet.appendRow(
          toCellRow([data.monthYear, data.cogs, data.cogsTarget]),
        );
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('monthlyCOGS.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthlyCOGS.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateMonthlyCOGSPDF(MonthlyCogsList list) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Monthly COGS',
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
                      'Opening Stock',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Closing Stock',
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
                for (var data in monthlyCOGS.monthlyData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        data.monthYear,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.openingStock.toString(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.closingStock.toString(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.inventoryTarget.toString(),
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
        // final bytes = await pdf.save();
        // final blob = html.Blob([bytes], 'application/pdf');
        // final url = html.Url.createObjectUrlFromBlob(blob);
        //
        // html.window.open(url, '_blank');

        // Generate bytes
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthlyCOGS.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
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
