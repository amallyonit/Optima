// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference
import 'package:optima/excel_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:pdf/widgets.dart' as pw;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
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
import 'package:http/http.dart' as http;
import 'package:optima/classes/leads.dart';
import 'package:optima/pages/dashboardPages/excel_helper_web.dart';
import 'package:optima/pages/dashboardPages/pdf_helper_web.dart';
import 'package:excel/excel.dart' hide Border, BorderStyle, TextSpan;

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
List<GRNList> grnList = [];
List<MonthlyInventoryData> monthWiseInventory = [];

CashConversionGraphList monthlyAnalysisData = CashConversionGraphList(
  monthData: [],
);
CashConversionGraphList cashConversionData = CashConversionGraphList(
  monthData: [],
);
DSOGraphList graphData = DSOGraphList(monthData: []);
DailyAnalysisExpensesList purchaseMonthlyData = DailyAnalysisExpensesList(
  dailyData: [],
);
DailyAnalysisExpensesList inventoryMonthlyData = DailyAnalysisExpensesList(
  dailyData: [],
);
DailyAnalysisExpensesList inventoryClosingMonthlyData =
    DailyAnalysisExpensesList(dailyData: []);
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

bool fromFilter = false;

List<List<bool>> selectedFinanceReceivablesOptions = [];

List<List<bool>> savedFinanceReceivablesOptionsTemp = [];

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
    int limit = 10000;
    int fetchedCount = 0;
    List<DebtorsAgingList> targetList = [];
    try {
      do {
        var body = {
          // "FromDate": formatDate(fiscalYearStartDate!),
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
            List<DebtorsAgingList> newTargetList =
                (responseJson['responseData'] as List)
                    .map((item) => DebtorsAgingList.fromJson(item))
                    .toList();
            targetList.addAll(newTargetList);
            fetchedCount = newTargetList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();
        menuNames.insert(0, UserName);
        context.read<CashConversionReceivablesProvider>().updateTargetList(
          targetList,
        );

        if (int.parse(UserLevel) == 5) {
          target = targetList.toList();
        } else if (int.parse(UserLevel) == 4) {
          target = targetList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          target = targetList.toList();
        } else {
          target = targetList.toList();
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

  Future<void> _loadSales(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<SalesList> salesList = [];
    try {
      do {
        var body = {
          // "FromDate": formatDate(monthIndex == 4 ? lastMonthFromDate! : fiscalYearStartDate!),
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
        context.read<CashConversionSalesProvider>().updateSalesList(salesList);
        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();
        menuNames.insert(0, UserName);
        if (int.parse(UserLevel) == 5) {
          sales = salesList.toList();
        } else if (int.parse(UserLevel) == 4) {
          sales = salesList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          sales = salesList.toList();
        } else {
          sales = salesList.toList();
        }
      });
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadCollection(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<CollectionList> collectionList = [];
    try {
      do {
        var body = {
          // "FromDate": formatDate(monthIndex == 4 ? lastMonthFromDate! : fiscalYearStartDate!),
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
        const apiUrl = '${ApiHelper.baseUrl}CRMCollectionAnalysisList';
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
            List<CollectionList> newCollectionList =
                (responseJson['responseData'] as List)
                    .map((item) => CollectionList.fromJson(item))
                    .toList();

            collectionList.addAll(newCollectionList);
            fetchedCount = newCollectionList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        context.read<CashConversionCollectionProvider>().updateCollectionList(
          collectionList,
        );

        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();
        menuNames.insert(0, UserName);

        if (int.parse(UserLevel) == 5) {
          collection = collectionList.toList();
        } else if (int.parse(UserLevel) == 4) {
          collection = collectionList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          collection = collectionList.toList();
        } else {
          collection = collectionList.toList();
        }
      });
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadPayables(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000; // Maximum limit to fetch all data
    int fetchedCount = 0;
    List<PaymentAnalysisList> salesList = [];
    try {
      do {
        var body = {
          // "FromDate": formatDate(monthIndex == 4 ? lastMonthFromDate! : fiscalYearStartDate!),
          // "ToDate": formatDate(currentDate!),
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
        const apiUrl = '${ApiHelper.baseUrl}BicxoCreditorsAgingList';
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
            List<PaymentAnalysisList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => PaymentAnalysisList.fromJson(item))
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
        context.read<CashConversionPayableProvider>().updatePOList(salesList);
        if (int.parse(UserLevel) == 5) {
          payables = salesList.toList();
        } else if (int.parse(UserLevel) == 4) {
          payables = salesList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          payables = salesList.toList();
        } else {
          payables = salesList.toList();
        }
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

  Future<void> _loadModeOfPayment(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000; // Maximum limit to fetch all data
    int fetchedCount = 0;
    List<ModeOfPaymentList> salesList = [];
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
        const apiUrl = '${ApiHelper.baseUrl}BicxoPaymentAnalysisList';
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
            List<ModeOfPaymentList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => ModeOfPaymentList.fromJson(item))
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
        context.read<CashConversionActualPayableProvider>().updateTargetList(
          salesList,
        );
        if (int.parse(UserLevel) == 5) {
          modeOfPayment = salesList
              .where((element) => element.vendorGroup != "")
              .toList();
        } else if (int.parse(UserLevel) == 4) {
          modeOfPayment = salesList
              .where((element) => element.vendorGroup != "")
              .toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          modeOfPayment = salesList
              .where((element) => element.vendorGroup != "")
              .toList();
        } else {
          modeOfPayment = salesList
              .where((element) => element.vendorGroup != "")
              .toList();
        }
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

  Future<void> _loadInventory(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<InventoryList> salesList = [];
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
        context.read<InventoryCashConversionProvider>().updateInventoryList(
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
        if (!mounted) return;
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
        context
            .read<InventoryClosingCashConversionProvider>()
            .updateInventoryList(salesList);
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
        if (purchasePrice.isEmpty) {
          purchasePrice = salesList.toList();
        }
        context.read<GRNCashConversionProvider>().updatePurchaseList(salesList);

        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();
        menuNames.insert(0, UserName);
        if (int.parse(UserLevel) == 5) {
          if (purchasePrice.isEmpty) {
            purchasePrice = salesList.toList();
          }
        } else if (int.parse(UserLevel) == 4) {
          if (purchasePrice.isEmpty) {
            purchasePrice = salesList.toList();
          }
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          if (purchasePrice.isEmpty) {
            purchasePrice = salesList.toList();
          }
        } else {
          if (purchasePrice.isEmpty) {
            purchasePrice = salesList.toList();
          }
        }
        if (purchasePrice.isEmpty) {
          purchasePrice = salesList.toList();
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
      if (mounted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
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

  Map<String, DateTime> getLastMonthStartEndDates(
    String monthName, {
    int? year,
  }) {
    year ??= DateTime.now().year;
    // Define the list of month names.
    List<String> monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    // Find the current month index (1-based).
    int currentMonthIndex = monthNames.indexOf(monthName) + 1;

    // Determine last month's index and adjust the year if necessary.
    int lastMonthIndex = currentMonthIndex - 1;
    int lastMonthYear = year;
    if (lastMonthIndex < 1) {
      lastMonthIndex = 12;
      lastMonthYear -= 1;
    }

    // Calculate the start and end dates of last month.
    DateTime lastMonthStart = DateTime(lastMonthYear, lastMonthIndex, 1);
    // Using day 0 of the next month gives the last day of the last month.
    DateTime lastMonthEnd = DateTime(lastMonthYear, lastMonthIndex + 1, 0);

    return {'start': lastMonthStart, 'end': lastMonthEnd};
  }

  Future<void> _loadMonthlySalesBarCashConversionChartData(
    String? touchedMonth,
  ) async {
    List<CashConversionGraphData> soDataList = [];
    List<DSOGraphData> dataList = [];

    final now = DateTime.now();
    final int fiscalIndex = (now.month < 4) ? now.month + 12 : now.month;

    double avgAccountsReceivableNH = 0;
    double netCreditSalesNH = 0;
    double daySalesOutstandingNH = 0;

    double avgAccountsReceivableSales = 0;
    double daySalesOutstandingSales = 0;

    double avgAccountsReceivableOffice = 0;
    double daySalesOutstandingOffice = 0;

    double allReceivableOutstandingDays = 0;

    double payableOutstandingDays = 0;

    double inventoryOutstandingDays = 0;

    // int currentYear = DateTime.now().month < 4
    //     ? DateTime.now().year - 1
    //     : DateTime.now().year;

    DateTime startDate;
    DateTime endDate;

    double lastMonthBalanceNH = 0;
    double currentMonthBalanceNH = 0;
    double currentMonthRowTotalNH = 0;

    double lastMonthBalanceSales = 0;
    double currentMonthBalanceSales = 0;

    double lastMonthBalanceOffice = 0;
    double currentMonthBalanceOffice = 0;

    double lastMonthBalancePayable = 0;
    double currentMonthBalancePayable = 0;
    double avgPayables = 0;
    double costOfGoodsSold = 0;

    double totalSalesNetCrediSales = 0;

    double netCreditSales = 0;
    double netCreditNH = 0;
    double netCreditOffice = 0;

    double salesDebtLastMonth = 0;
    double salesDebtThisMonth = 0;
    double salesCollectionThisMonth = 0;
    double salesCollectionLastMonth = 0;

    double officeDebtLastMonth = 0;
    double officeDebtThisMonth = 0;
    double officeCollectionThisMonth = 0;
    double officeCollectionLastMonth = 0;

    double nhDebtLastMonth = 0;
    double nhDebtThisMonth = 0;
    double nhCollectionThisMonth = 0;
    double nhCollectionLastMonth = 0;

    for (int i = 4; i <= 15; i++) {
      final String monthName = getMonthName(i);

      final int cogsIndex = i - 4;
      final MonthlyCogsData cogsData =
          (cogsIndex >= 0 && cogsIndex < monthlyCogsList.length)
          ? monthlyCogsList[cogsIndex]
          : MonthlyCogsData(
              monthYear: monthName,
              openingStock: 0,
              purchases: 0,
              closingStock: 0,
              cogs: 0,
            );

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
      List<SalesList> currentMonthSalesListNH = [];
      List<DebtorsAgingList> monthlyCollectionListNH = [];
      List<DebtorsAgingList> lastMonthlyCollectionListNH = [];
      List<CollectionList> collectionCurrentMonthNH = [];
      List<CollectionList> collectionLastMonthNH = [];

      List<SalesList> currentMonthSalesListSales = [];
      List<DebtorsAgingList> monthlyCollectionListSales = [];
      List<DebtorsAgingList> lastMonthlyCollectionListSales = [];
      List<CollectionList> collectionCurrentMonthSales = [];
      List<CollectionList> collectionLastMonthSales = [];

      List<SalesList> currentMonthSalesListOffice = [];
      List<DebtorsAgingList> monthlyCollectionListOffice = [];
      List<DebtorsAgingList> lastMonthlyCollectionListOffice = [];
      List<CollectionList> collectionCurrentMonthOffice = [];
      List<CollectionList> collectionLastMonthOffice = [];

      List<SalesList> totalSales = [];
      List<DebtorsAgingList> totalTargetLastMonth = [];

      List<PaymentAnalysisList> lastMonthPayables = [];
      List<PaymentAnalysisList> currentMonthPayables = [];

      List<ModeOfPaymentList> lastMonthTotalPayables = [];
      List<ModeOfPaymentList> currentMonthTotalPayables = [];

      List<SalesList> salesNHList = sales.where((person) {
        return person.salesManager == "NH GROUP. - Drs.";
      }).toList();
      List<DebtorsAgingList> receivablesNHList = target.where((person) {
        return person.salesManager == "NH GROUP. - Drs.";
      }).toList();
      List<CollectionList> collectionNHList = collection.where((person) {
        return person.salesManager == "NH GROUP. - Drs.";
      }).toList();

      List<SalesList> salesSalesTeamList = sales.where((person) {
        return person.salesManager != "NH GROUP. - Drs." &&
            person.salesManager != "OFFICE - Drs.";
      }).toList();
      List<DebtorsAgingList> receivablesSalesTeamList = target.where((person) {
        return person.salesManager != "NH GROUP. - Drs." &&
            person.salesManager != "OFFICE - Drs.";
      }).toList();
      List<CollectionList> collectionSalesList = collection.where((person) {
        return person.salesManager != "NH GROUP. - Drs." &&
            person.salesManager != "OFFICE - Drs.";
      }).toList();

      List<SalesList> salesOfficeList = sales.where((person) {
        return person.salesManager == "OFFICE - Drs.";
      }).toList();
      List<DebtorsAgingList> receivablesOfficeList = target.where((person) {
        return person.salesManager == "OFFICE - Drs.";
      }).toList();
      List<CollectionList> collectionOfficeList = collection.where((person) {
        return person.salesManager == "OFFICE - Drs.";
      }).toList();

      if (i >= 4 && i <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(i);
        Map<String, DateTime> lastMonthDates = getLastMonthStartEndDates(
          monthName,
          year: DateTime.now().year,
        );

        currentMonthSalesListNH = salesNHList.where((target) {
          DateTime postingDate = target.invoiceDate;
          return postingDate.isAtLeast(monthDates['start']!) &&
              postingDate.isAtMost(monthDates['end']!);
        }).toList();
        monthlyCollectionListNH = receivablesNHList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return /*postingDate.isAtLeast(monthDates['start']!) &&*/ postingDate
              .isAtMost(monthDates['end']!);
        }).toList();
        lastMonthlyCollectionListNH = receivablesNHList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return /* postingDate.isAtLeast(lastMonthDates['start']!) &&
                */ postingDate.isAtMost(lastMonthDates['end']!);
        }).toList();
        collectionCurrentMonthNH = collectionNHList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(monthDates['start']!) &&
              postingDate.isAtMost(monthDates['end']!);
        }).toList();
        collectionLastMonthNH = collectionNHList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(lastMonthDates['start']!) &&
              postingDate.isAtMost(lastMonthDates['end']!);
        }).toList();

        currentMonthSalesListSales = salesSalesTeamList.where((target) {
          DateTime postingDate = target.invoiceDate;
          return postingDate.isAtLeast(monthDates['start']!) &&
              postingDate.isAtMost(monthDates['end']!);
        }).toList();
        monthlyCollectionListSales = receivablesSalesTeamList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return /*postingDate.isAtLeast(monthDates['start']!) &&*/ postingDate
              .isAtMost(monthDates['end']!);
        }).toList();
        lastMonthlyCollectionListSales = receivablesSalesTeamList.where((
          target,
        ) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return /* postingDate.isAtLeast(lastMonthDates['start']!) &&
                */ postingDate.isAtMost(lastMonthDates['end']!);
        }).toList();
        collectionCurrentMonthSales = collectionSalesList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(monthDates['start']!) &&
              postingDate.isAtMost(monthDates['end']!);
        }).toList();
        collectionLastMonthSales = collectionSalesList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(lastMonthDates['start']!) &&
              postingDate.isAtMost(lastMonthDates['end']!);
        }).toList();

        currentMonthSalesListOffice = salesOfficeList.where((target) {
          DateTime postingDate = target.invoiceDate;

          return postingDate.isAtLeast(monthDates['start']!) &&
              postingDate.isAtMost(monthDates['end']!);
        }).toList();
        monthlyCollectionListOffice = receivablesOfficeList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return /*postingDate.isAtLeast(monthDates['start']!) &&
                */ postingDate.isAtMost(monthDates['end']!);
        }).toList();
        lastMonthlyCollectionListOffice = receivablesOfficeList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return /*postingDate.isAtLeast(lastMonthDates['start']!) &&
                */ postingDate.isAtMost(lastMonthDates['end']!);
        }).toList();
        collectionCurrentMonthOffice = collectionOfficeList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(monthDates['start']!) &&
              postingDate.isAtMost(monthDates['end']!);
        }).toList();
        collectionLastMonthOffice = collectionOfficeList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(lastMonthDates['start']!) &&
              postingDate.isAtMost(lastMonthDates['end']!);
        }).toList();

        totalSales = sales.where((target) {
          DateTime postingDate = target.invoiceDate;
          return postingDate.isAtLeast(monthDates['start']!) &&
              postingDate.isAtMost(monthDates['end']!);
        }).toList();

        totalTargetLastMonth = target.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(monthDates['start']!) &&
              postingDate.isAtMost(monthDates['end']!);
        }).toList();

        lastMonthPayables = payables.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return /*postingDate.isAtLeast(monthDates['start']!) && */ postingDate
              .isAtMost(lastMonthDates['end']!);
        }).toList();

        currentMonthPayables = payables.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return /* postingDate.isAtLeast(lastMonthDates['start']!) &&
                */ postingDate.isAtMost(monthDates['end']!);
        }).toList();

        currentMonthTotalPayables = modeOfPayment.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(monthDates['start']!) &&
              postingDate.isAtMost(monthDates['end']!);
        }).toList();
        lastMonthTotalPayables = modeOfPayment.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(lastMonthDates['start']!) &&
              postingDate.isAtMost(lastMonthDates['end']!);
        }).toList();
      } else {
        int currentYear = DateTime.now().month < 4
            ? DateTime.now().year
            : DateTime.now().year + 1;
        startDate = DateTime(currentYear, (i - 12), 1);
        endDate = DateTime(currentYear, (i - 12) + 1, 0);
        Map<String, DateTime> lastMonthDates = getLastMonthStartEndDates(
          monthName,
          year: DateTime.now().year + 1,
        );

        currentMonthSalesListNH = salesNHList.where((target) {
          DateTime postingDate = target.invoiceDate;

          return postingDate.isAtLeast(startDate) &&
              postingDate.isAtMost(endDate);
        }).toList();
        monthlyCollectionListNH = receivablesNHList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return /*postingDate.isAtLeast(startDate) &&
                */ postingDate.isAtMost(endDate);
        }).toList();
        lastMonthlyCollectionListNH = receivablesNHList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return /* postingDate.isAtLeast(lastMonthDates['start']!) &&
                */ postingDate.isAtMost(lastMonthDates['end']!);
        }).toList();
        collectionCurrentMonthNH = collectionNHList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(startDate) &&
              postingDate.isAtMost(endDate);
        }).toList();
        collectionLastMonthNH = collectionNHList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(lastMonthDates['start']!) &&
              postingDate.isAtMost(lastMonthDates['end']!);
        }).toList();

        currentMonthSalesListSales = salesSalesTeamList.where((target) {
          DateTime postingDate = target.invoiceDate;
          return postingDate.isAtLeast(startDate) &&
              postingDate.isAtMost(endDate);
        }).toList();
        monthlyCollectionListSales = receivablesSalesTeamList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return /*postingDate.isAtLeast(startDate) &&
                */ postingDate.isAtMost(endDate);
        }).toList();
        lastMonthlyCollectionListSales = receivablesSalesTeamList.where((
          target,
        ) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return /*postingDate.isAtLeast(lastMonthDates['start']!) &&
                */ postingDate.isAtMost(lastMonthDates['end']!);
        }).toList();
        collectionCurrentMonthSales = collectionSalesList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(startDate) &&
              postingDate.isAtMost(endDate);
        }).toList();
        collectionLastMonthSales = collectionSalesList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(lastMonthDates['start']!) &&
              postingDate.isAtMost(lastMonthDates['end']!);
        }).toList();

        currentMonthSalesListOffice = salesOfficeList.where((target) {
          DateTime postingDate = target.invoiceDate;
          return postingDate.isAtLeast(startDate) &&
              postingDate.isAtMost(endDate);
        }).toList();
        monthlyCollectionListOffice = receivablesOfficeList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return /*postingDate.isAtLeast(startDate) &&
                */ postingDate.isAtMost(endDate);
        }).toList();
        lastMonthlyCollectionListOffice = receivablesOfficeList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return /* postingDate.isAtLeast(lastMonthDates['start']!) &&
               */ postingDate.isAtMost(lastMonthDates['end']!);
        }).toList();
        collectionCurrentMonthOffice = collectionOfficeList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(startDate) &&
              postingDate.isAtMost(endDate);
        }).toList();
        collectionLastMonthOffice = collectionOfficeList.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(lastMonthDates['start']!) &&
              postingDate.isAtMost(lastMonthDates['end']!);
        }).toList();

        totalSales = sales.where((target) {
          DateTime postingDate = target.invoiceDate;
          return postingDate.isAtLeast(startDate) &&
              postingDate.isAtMost(endDate);
        }).toList();

        totalTargetLastMonth = target.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(startDate) &&
              postingDate.isAtMost(endDate);
        }).toList();

        lastMonthPayables = payables.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return /* postingDate.isAtLeast(startDate) &&*/ postingDate.isAtMost(
            lastMonthDates['end']!,
          );
        }).toList();

        currentMonthPayables = payables.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return /*postingDate.isAtLeast(lastMonthDates['start']!) &&*/ postingDate
              .isAtMost(endDate);
        }).toList();

        currentMonthTotalPayables = modeOfPayment.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(startDate) &&
              postingDate.isAtMost(endDate);
        }).toList();
        lastMonthTotalPayables = modeOfPayment.where((target) {
          DateTime postingDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(target.postingDate);
          return postingDate.isAtLeast(lastMonthDates['start']!) &&
              postingDate.isAtMost(lastMonthDates['end']!);
        }).toList();
      }

      for (var target in lastMonthPayables) {
        double credit = double.tryParse(target.balance) ?? 0;
        if (credit < 0) {
          lastMonthBalancePayable += credit;
        }
      }

      for (var target in currentMonthPayables) {
        double credit = double.tryParse(target.balance) ?? 0;
        if (credit < 0) {
          currentMonthBalancePayable += credit;
        }
      }

      for (var target in currentMonthTotalPayables) {
        double credit = double.tryParse(target.total) ?? 0;
        lastMonthBalancePayable += credit;
      }
      for (var target in lastMonthTotalPayables) {
        double credit = double.tryParse(target.total) ?? 0;
        currentMonthBalancePayable += credit;
      }

      for (var target in monthlyCollectionListNH) {
        double credit = double.tryParse(target.balance) ?? 0;
        currentMonthBalanceNH += credit.abs();
      }
      for (var target in lastMonthlyCollectionListNH) {
        double credit = double.tryParse(target.balance) ?? 0;
        lastMonthBalanceNH += credit.abs();
        nhDebtLastMonth += credit;
      }
      for (var target in currentMonthSalesListNH) {
        double credit = double.tryParse(target.rowTotal) ?? 0;
        currentMonthRowTotalNH += credit /*.abs()*/;
        netCreditNH += credit;
        nhDebtThisMonth += credit;
      }
      for (var target in collectionCurrentMonthNH) {
        double credit = double.tryParse(target.total) ?? 0;
        currentMonthBalanceNH += credit.abs();
        nhCollectionThisMonth += credit;
      }
      for (var target in collectionLastMonthNH) {
        double credit = double.tryParse(target.total) ?? 0;
        lastMonthBalanceNH += credit.abs();
        nhCollectionLastMonth += credit;
      }

      for (var target in currentMonthSalesListSales) {
        double credit = double.tryParse(target.rowTotal) ?? 0;
        currentMonthBalanceSales += credit;
        netCreditSales += credit;
      }
      for (var target in monthlyCollectionListSales) {
        double credit = double.tryParse(target.balance) ?? 0;
        lastMonthBalanceSales += credit;
        salesDebtThisMonth += credit;
      }
      for (var target in lastMonthlyCollectionListSales) {
        double credit = double.tryParse(target.balance) ?? 0;
        salesDebtLastMonth += credit;
      }
      for (var target in collectionCurrentMonthSales) {
        double credit = double.tryParse(target.total) ?? 0;
        currentMonthBalanceSales += credit;
        salesCollectionThisMonth += credit;
      }
      for (var target in collectionLastMonthSales) {
        double credit = double.tryParse(target.total) ?? 0;
        lastMonthBalanceSales += credit.abs();
        salesCollectionLastMonth += credit;
      }

      for (var target in currentMonthSalesListOffice) {
        double credit = double.tryParse(target.rowTotal) ?? 0;
        currentMonthBalanceOffice += credit.abs();
        netCreditOffice += credit;
      }
      for (var target in monthlyCollectionListOffice) {
        double credit = double.tryParse(target.balance) ?? 0;
        lastMonthBalanceOffice += credit.abs();
        officeDebtThisMonth += credit;
      }
      for (var target in lastMonthlyCollectionListOffice) {
        double credit = double.tryParse(target.balance) ?? 0;
        officeDebtLastMonth += credit;
      }
      for (var target in collectionCurrentMonthOffice) {
        double credit = double.tryParse(target.total) ?? 0;
        currentMonthBalanceOffice += credit.abs();
        officeCollectionThisMonth += credit;
      }
      for (var target in collectionLastMonthOffice) {
        double credit = double.tryParse(target.total) ?? 0;
        lastMonthBalanceOffice += credit.abs();
        officeCollectionLastMonth += credit;
      }

      for (var target in totalSales) {
        double credit = double.tryParse(target.rowTotal) ?? 0;
        totalSalesNetCrediSales += credit;
      }

      for (var target in totalTargetLastMonth) {
        double credit = double.tryParse(target.balance) ?? 0;
        totalSalesNetCrediSales += credit;
      }

      avgAccountsReceivableNH =
          (lastMonthBalanceNH + currentMonthBalanceNH) / 2;
      avgAccountsReceivableSales =
          (lastMonthBalanceSales + currentMonthBalanceSales) / 2;
      avgAccountsReceivableOffice =
          (lastMonthBalanceOffice + currentMonthBalanceOffice) / 2;

      avgPayables =
          (currentMonthBalancePayable.abs() + lastMonthBalancePayable.abs()) /
          2;
      netCreditSalesNH = currentMonthRowTotalNH;

      // costOfGoodsSold = (inventoryClosingMonthlyData.dailyData.first.balance +
      //         purchaseMonthlyData.dailyData[i - 4].balance) -
      //     inventoryMonthlyData.dailyData.first.balance;

      double avgInventory = (cogsData.openingStock + cogsData.closingStock) / 2;
      costOfGoodsSold = cogsData.cogs;

      int currentYear = DateTime.now().month < 4
          ? DateTime.now().year
          : DateTime.now().year - 1;
      int monthNumber = i > 12 ? i - 12 : i;

      double noOfDays = DateTime(
        currentYear,
        monthNumber + 1,
        0,
      ).day.toDouble();

      noOfDays = getCompletedDaysInMonth(currentYear, i);
      double days = getCompletedDaysInMonth(DateTime.now().year, i);

      // double avgInventory = (inventoryMonthlyData.dailyData.first.balance +
      //         inventoryClosingMonthlyData.dailyData.first.balance) /
      //     2;

      double avgSales =
          ((salesCollectionLastMonth + salesDebtLastMonth) +
              (salesCollectionThisMonth + salesDebtThisMonth)) /
          2;
      double avgOffice =
          ((officeCollectionLastMonth + officeDebtLastMonth) +
              (officeCollectionThisMonth + officeDebtThisMonth)) /
          2;
      double avgNH =
          ((nhCollectionLastMonth + nhDebtLastMonth) +
              (nhCollectionThisMonth + nhDebtThisMonth)) /
          2;

      allReceivableOutstandingDays = (netCreditSalesNH != 0)
          ? ((avgAccountsReceivableOffice +
                        avgAccountsReceivableNH +
                        avgAccountsReceivableSales) /
                    (totalSalesNetCrediSales)) *
                noOfDays
          : 0;

      payableOutstandingDays = (costOfGoodsSold != 0)
          ? (avgPayables / costOfGoodsSold) * days
          : 0;

      inventoryOutstandingDays = (costOfGoodsSold != 0)
          ? (avgInventory / costOfGoodsSold) * days
          : 0;

      daySalesOutstandingNH = (netCreditNH != 0)
          ? ((avgNH) / netCreditNH) * days
          : 0;

      daySalesOutstandingSales = (netCreditSales != 0)
          ? (avgSales / netCreditSales) * days
          : 0;

      daySalesOutstandingOffice = (netCreditOffice != 0)
          ? ((avgOffice) / netCreditOffice) * days
          : 0;

      allReceivableOutstandingDays = allReceivableOutstandingDays.isFinite
          ? double.parse(allReceivableOutstandingDays.toStringAsFixed(0))
          : 0;
      payableOutstandingDays = payableOutstandingDays.isFinite
          ? double.parse(payableOutstandingDays.toStringAsFixed(0))
          : 0;
      daySalesOutstandingNH = daySalesOutstandingNH.isFinite
          ? double.parse(daySalesOutstandingNH.toStringAsFixed(0))
          : 0;
      daySalesOutstandingSales = daySalesOutstandingSales.isFinite
          ? double.parse(daySalesOutstandingSales.toStringAsFixed(0))
          : 0;
      daySalesOutstandingOffice = daySalesOutstandingOffice.isFinite
          ? double.parse(daySalesOutstandingOffice.toStringAsFixed(0))
          : 0;

      soDataList.add(
        CashConversionGraphData(
          monthName: monthName,
          dsoDaysSales: daySalesOutstandingSales,
          dsoDaysNH: daySalesOutstandingNH,
          dsoDaysOffice: daySalesOutstandingOffice,
          dsoAllDays: allReceivableOutstandingDays,
          payableDays: payableOutstandingDays,
          inventoryDays: inventoryOutstandingDays,
        ),
      );

      daySalesOutstandingNH = 0;
      avgAccountsReceivableNH = 0;
      netCreditSalesNH = 0;
      noOfDays = 0;
      lastMonthBalanceNH = 0;
      currentMonthBalanceNH = 0;
      currentMonthRowTotalNH = 0;
      avgAccountsReceivableNH = 0;
      netCreditSalesNH = 0;
      daySalesOutstandingNH = 0;
      avgAccountsReceivableSales = 0;
      daySalesOutstandingSales = 0;
      avgAccountsReceivableOffice = 0;
      daySalesOutstandingOffice = 0;
      lastMonthBalanceNH = 0;
      currentMonthBalanceNH = 0;
      currentMonthRowTotalNH = 0;
      lastMonthBalanceSales = 0;
      currentMonthBalanceSales = 0;
      lastMonthBalanceOffice = 0;
      currentMonthBalanceOffice = 0;
      inventoryOutstandingDays = 0;
      allReceivableOutstandingDays = 0;
      payableOutstandingDays = 0;
      costOfGoodsSold = 0;
      avgPayables = 0;
      lastMonthBalancePayable = 0;
      netCreditSales = 0;
      netCreditNH = 0;
      netCreditOffice = 0;
      currentMonthBalancePayable = 0;
      totalSalesNetCrediSales = 0;
      salesDebtThisMonth = 0;
      salesDebtLastMonth = 0;
      salesCollectionLastMonth = 0;
      salesCollectionThisMonth = 0;
      officeDebtLastMonth = 0;
      officeDebtThisMonth = 0;
      officeCollectionThisMonth = 0;
      officeCollectionLastMonth = 0;
      nhDebtLastMonth = 0;
      nhDebtThisMonth = 0;
      nhCollectionThisMonth = 0;
      nhCollectionLastMonth = 0;
      currentMonthSalesListNH = [];
      monthlyCollectionListNH = [];
      lastMonthlyCollectionListNH = [];
      currentMonthSalesListSales = [];
      monthlyCollectionListSales = [];
      lastMonthlyCollectionListSales = [];
      currentMonthSalesListOffice = [];
      monthlyCollectionListOffice = [];
      lastMonthlyCollectionListOffice = [];
      lastMonthPayables = [];
      currentMonthPayables = [];
      collectionCurrentMonthNH = [];
      collectionLastMonthNH = [];
      collectionLastMonthSales = [];
      collectionCurrentMonthSales = [];
      collectionCurrentMonthOffice = [];
      collectionLastMonthOffice = [];
    }
    monthlyAnalysisData = CashConversionGraphList(monthData: soDataList);

    int displayIndex;
    if (touchedMonth != null) {
      displayIndex = soDataList.indexWhere((e) => e.monthName == touchedMonth);
      if (displayIndex == -1) {
        // touchedMonth not found in the current fiscal year; fall back
        displayIndex = DateTime.now().month - 4;
      }
    } else {
      displayIndex = DateTime.now().month - 4;
    }
    displayIndex = displayIndex.clamp(0, soDataList.length - 1);

    // Now add DSO bars for either touchedMonth or current month
    dataList.add(
      DSOGraphData(
        name: "Receivables Days Outstanding",
        target: 60,
        achievement: soDataList[displayIndex].dsoAllDays,
      ),
    );
    dataList.add(
      DSOGraphData(
        name: "Inventory Days Outstanding",
        target: 60,
        achievement: soDataList[displayIndex].inventoryDays,
      ),
    );
    dataList.add(
      DSOGraphData(
        name: "Payable Days Outstanding",
        target: 75,
        achievement: soDataList[displayIndex].payableDays,
      ),
    );

    graphData = DSOGraphList(monthData: dataList);
    setState(() {
      chartDataLoadedCCC = true;
    });
  }

  Future<void> loadDataWithFilter(String? touchedMonth) async {
    clearVariablesForFilter();
    LoadDates();
    _loadMonthlySalesBarCashConversionChartData(touchedMonth);

    chartDataLoadedCCC = true;
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
    List<MonthlyCogsData> cogsList = [];

    for (int i = 1; i < inventoryList.length; i++) {
      final String monthYear = inventoryList[i].monthYear;

      final double openingStock = inventoryList[i - 1].inventory.fold(
        0.0,
        (sum, item) => sum + (double.parse(item.totalValue)),
      );

      final double closingStock = inventoryList[i].inventory.fold(
        0.0,
        (sum, item) => sum + (double.parse(item.totalValue)),
      );

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
    List<DailyAnalysisExpensesData> groupWiseDataList = [];

    List<GRNList> purchaseRecords =
        purchasePrice /*.where((test) => test. == "Item Purchase").toList()*/;

    // Filter records based on the invoice date falling within the specified fiscal year.
    List<GRNList> filteredRecords = purchaseRecords.where((record) {
      DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(record.grnDate);
      return invoiceDate.isAtLeast(
            dateFilterFlag ? fromDateFilter! : fiscalYearStartDate!,
          ) &&
          invoiceDate.isAtMost(dateFilterFlag ? toDateFilter! : currentDate!);
    }).toList();

    // Create a Map to group balances by month-year.
    // Key: month-year string (e.g. "08/2024")
    // Value: accumulated balance for that month.
    Map<String, double> monthlyBalanceMap = {};

    // Iterate over the filtered records to group and sum balances.
    for (var record in filteredRecords) {
      DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(record.grnDate);
      String monthYearKey = DateFormat('MM/yyyy').format(invoiceDate);

      double balance = double.tryParse(record.rowTotal) ?? 0.0;
      // Sum the absolute value of balances.
      monthlyBalanceMap[monthYearKey] =
          (monthlyBalanceMap[monthYearKey] ?? 0.0) + balance.abs();
    }

    // Convert each group into DailyAnalysisExpensesData.
    monthlyBalanceMap.forEach((monthYear, totalBalance) {
      groupWiseDataList.add(
        DailyAnalysisExpensesData(balance: totalBalance, date: monthYear),
      );
    });

    // Assign the calculated data to the revenueMonthlyData.
    purchaseMonthlyData = DailyAnalysisExpensesList(
      dailyData: groupWiseDataList,
    );
    monthlyCogsList = calculateMonthlyCogs(
      inventoryList: monthWiseInventory,
      purchaseMonthlyData: purchaseMonthlyData.dailyData,
    );
  }

  Future<void> _loadMonthlyAnalysisInventory() async {
    List<DailyAnalysisExpensesData> groupWiseDataList = [];

    // Filter records based on the invoice date falling within the specified fiscal year.
    List<InventoryList> filteredRecords = inventory;

    double balance = 0;

    // Iterate over the filtered records to group and sum balances.
    for (var record in filteredRecords) {
      balance += double.tryParse(record.totalValue) ?? 0.0;
      // Sum the absolute value of balances.
    }

    // Convert each group into DailyAnalysisExpensesData.
    groupWiseDataList.add(
      DailyAnalysisExpensesData(balance: balance, date: "May"),
    );

    // Assign the calculated data to the revenueMonthlyData.
    inventoryMonthlyData = DailyAnalysisExpensesList(
      dailyData: groupWiseDataList,
    );
  }

  Future<void> _loadMonthlyAnalysisInventoryClosing() async {
    List<DailyAnalysisExpensesData> groupWiseDataList = [];

    // Filter records based on the invoice date falling within the specified fiscal year.
    List<InventoryList> filteredRecords = inventoryClosing;

    double balance = 0;

    // Iterate over the filtered records to group and sum balances.
    for (var record in filteredRecords) {
      balance += double.tryParse(record.totalValue) ?? 0.0;
      // Sum the absolute value of balances.
    }

    // Convert each group into DailyAnalysisExpensesData.
    groupWiseDataList.add(
      DailyAnalysisExpensesData(balance: balance, date: "May"),
    );

    // Assign the calculated data to the revenueMonthlyData.
    inventoryClosingMonthlyData = DailyAnalysisExpensesList(
      dailyData: groupWiseDataList,
    );
  }

  Future<void> generateCashConversionExcel() async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Sheet1'];
    // sheet.getColAutoFits;
    sheet.appendRow(
      toCellRow([
        'Cash Conversion Cycle',
        "Target",
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
      ]),
    );

    sheet.appendRow(
      toCellRow([
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
      ]),
    );
    sheet.appendRow(
      toCellRow([
        "Receivable Days Outstanding NH",
        "",
        monthlyAnalysisData.monthData[0].dsoDaysNH,
        monthlyAnalysisData.monthData[1].dsoDaysNH,
        monthlyAnalysisData.monthData[2].dsoDaysNH,
        monthlyAnalysisData.monthData[3].dsoDaysNH,
        monthlyAnalysisData.monthData[4].dsoDaysNH,
        monthlyAnalysisData.monthData[5].dsoDaysNH,
        monthlyAnalysisData.monthData[6].dsoDaysNH,
        monthlyAnalysisData.monthData[7].dsoDaysNH,
        monthlyAnalysisData.monthData[8].dsoDaysNH,
        monthlyAnalysisData.monthData[9].dsoDaysNH,
        monthlyAnalysisData.monthData[10].dsoDaysNH,
        monthlyAnalysisData.monthData[11].dsoDaysNH,
      ]),
    );
    sheet.appendRow(
      toCellRow([
        "Receivable Days Outstanding Office",
        "",
        monthlyAnalysisData.monthData[0].dsoDaysOffice,
        monthlyAnalysisData.monthData[1].dsoDaysOffice,
        monthlyAnalysisData.monthData[2].dsoDaysOffice,
        monthlyAnalysisData.monthData[3].dsoDaysOffice,
        monthlyAnalysisData.monthData[4].dsoDaysOffice,
        monthlyAnalysisData.monthData[5].dsoDaysOffice,
        monthlyAnalysisData.monthData[6].dsoDaysOffice,
        monthlyAnalysisData.monthData[7].dsoDaysOffice,
        monthlyAnalysisData.monthData[8].dsoDaysOffice,
        monthlyAnalysisData.monthData[9].dsoDaysOffice,
        monthlyAnalysisData.monthData[10].dsoDaysOffice,
        monthlyAnalysisData.monthData[11].dsoDaysOffice,
      ]),
    );
    sheet.appendRow(toCellRow([""]));
    sheet.appendRow(
      toCellRow([
        "Receivable Outstanding Days",
        60,
        monthlyAnalysisData.monthData[0].dsoAllDays,
        monthlyAnalysisData.monthData[1].dsoAllDays,
        monthlyAnalysisData.monthData[2].dsoAllDays,
        monthlyAnalysisData.monthData[3].dsoAllDays,
        monthlyAnalysisData.monthData[4].dsoAllDays,
        monthlyAnalysisData.monthData[5].dsoAllDays,
        monthlyAnalysisData.monthData[6].dsoAllDays,
        monthlyAnalysisData.monthData[7].dsoAllDays,
        monthlyAnalysisData.monthData[8].dsoAllDays,
        monthlyAnalysisData.monthData[9].dsoAllDays,
        monthlyAnalysisData.monthData[10].dsoAllDays,
        monthlyAnalysisData.monthData[11].dsoAllDays,
      ]),
    );
    sheet.appendRow(
      toCellRow([
        "Add: Inventory Days Outstanding",
        60,
        double.parse(
          monthlyAnalysisData.monthData[0].inventoryDays.toStringAsFixed(0),
        ),
        double.parse(
          monthlyAnalysisData.monthData[1].inventoryDays.toStringAsFixed(0),
        ),
        double.parse(
          monthlyAnalysisData.monthData[2].inventoryDays.toStringAsFixed(0),
        ),
        double.parse(
          monthlyAnalysisData.monthData[3].inventoryDays.toStringAsFixed(0),
        ),
        double.parse(
          monthlyAnalysisData.monthData[4].inventoryDays.toStringAsFixed(0),
        ),
        double.parse(
          monthlyAnalysisData.monthData[5].inventoryDays.toStringAsFixed(0),
        ),
        double.parse(
          monthlyAnalysisData.monthData[6].inventoryDays.toStringAsFixed(0),
        ),
        double.parse(
          monthlyAnalysisData.monthData[7].inventoryDays.toStringAsFixed(0),
        ),
        double.parse(
          monthlyAnalysisData.monthData[8].inventoryDays.toStringAsFixed(0),
        ),
        double.parse(
          monthlyAnalysisData.monthData[9].inventoryDays.toStringAsFixed(0),
        ),
        double.parse(
          monthlyAnalysisData.monthData[10].inventoryDays.toStringAsFixed(0),
        ),
        double.parse(
          monthlyAnalysisData.monthData[11].inventoryDays.toStringAsFixed(0),
        ),
      ]),
    );
    sheet.appendRow(
      toCellRow([
        "Less: Payable Days Outstanding",
        75,
        monthlyAnalysisData.monthData[0].payableDays,
        monthlyAnalysisData.monthData[1].payableDays,
        monthlyAnalysisData.monthData[2].payableDays,
        monthlyAnalysisData.monthData[3].payableDays,
        monthlyAnalysisData.monthData[4].payableDays,
        monthlyAnalysisData.monthData[5].payableDays,
        monthlyAnalysisData.monthData[6].payableDays,
        monthlyAnalysisData.monthData[7].payableDays,
        monthlyAnalysisData.monthData[8].payableDays,
        monthlyAnalysisData.monthData[9].payableDays,
        monthlyAnalysisData.monthData[10].payableDays,
        monthlyAnalysisData.monthData[11].payableDays,
      ]),
    );
    sheet.appendRow(
      toCellRow([
        "",
        45,
        double.parse(
          ((monthlyAnalysisData.monthData[0].dsoAllDays +
                      monthlyAnalysisData.monthData[0].inventoryDays) -
                  monthlyAnalysisData.monthData[0].payableDays)
              .toStringAsFixed(0),
        ),
        double.parse(
          ((monthlyAnalysisData.monthData[1].dsoAllDays +
                      monthlyAnalysisData.monthData[1].inventoryDays) -
                  monthlyAnalysisData.monthData[1].payableDays)
              .toStringAsFixed(0),
        ),
        double.parse(
          ((monthlyAnalysisData.monthData[2].dsoAllDays +
                      monthlyAnalysisData.monthData[2].inventoryDays) -
                  monthlyAnalysisData.monthData[2].payableDays)
              .toStringAsFixed(0),
        ),
        double.parse(
          ((monthlyAnalysisData.monthData[3].dsoAllDays +
                      monthlyAnalysisData.monthData[3].inventoryDays) -
                  monthlyAnalysisData.monthData[3].payableDays)
              .toStringAsFixed(0),
        ),
        double.parse(
          ((monthlyAnalysisData.monthData[4].dsoAllDays +
                      monthlyAnalysisData.monthData[4].inventoryDays) -
                  monthlyAnalysisData.monthData[4].payableDays)
              .toStringAsFixed(0),
        ),
        double.parse(
          ((monthlyAnalysisData.monthData[5].dsoAllDays +
                      monthlyAnalysisData.monthData[5].inventoryDays) -
                  monthlyAnalysisData.monthData[5].payableDays)
              .toStringAsFixed(0),
        ),
        double.parse(
          ((monthlyAnalysisData.monthData[6].dsoAllDays +
                      monthlyAnalysisData.monthData[6].inventoryDays) -
                  monthlyAnalysisData.monthData[6].payableDays)
              .toStringAsFixed(0),
        ),
        double.parse(
          ((monthlyAnalysisData.monthData[7].dsoAllDays +
                      monthlyAnalysisData.monthData[7].inventoryDays) -
                  monthlyAnalysisData.monthData[7].payableDays)
              .toStringAsFixed(0),
        ),
        double.parse(
          ((monthlyAnalysisData.monthData[8].dsoAllDays +
                      monthlyAnalysisData.monthData[8].inventoryDays) -
                  monthlyAnalysisData.monthData[8].payableDays)
              .toStringAsFixed(0),
        ),
        double.parse(
          ((monthlyAnalysisData.monthData[9].dsoAllDays +
                      monthlyAnalysisData.monthData[9].inventoryDays) -
                  monthlyAnalysisData.monthData[9].payableDays)
              .toStringAsFixed(0),
        ),
        double.parse(
          ((monthlyAnalysisData.monthData[10].dsoAllDays +
                      monthlyAnalysisData.monthData[10].inventoryDays) -
                  monthlyAnalysisData.monthData[10].payableDays)
              .toStringAsFixed(0),
        ),
        double.parse(
          ((monthlyAnalysisData.monthData[11].dsoAllDays +
                      monthlyAnalysisData.monthData[11].inventoryDays) -
                  monthlyAnalysisData.monthData[11].payableDays)
              .toStringAsFixed(0),
        ),
      ]),
    );

    setState(() {
      // YtdSalesBarChartData = true;
    });

    if (kIsWeb) {
      // var fileBytes = excel.save(fileName: 'sales_analysis_ytd_report.xlsx');

      final excelBytes = excel.encode()!;
      saveAndOpenExcel('cashConversionCycle.xlsx', excelBytes);

      // var fileBytes = excel.encode();
      //
      // final blob = html.Blob([fileBytes]);
      // final url = html.Url.createObjectUrlFromBlob(blob);
      // final anchor = html.AnchorElement()
      //   ..href = url
      //   ..download = 'monthly_sales_report.xlsx'
      //   ..style.display = 'none';
      // html.document.body!.append(anchor);
      // anchor.click();
      // anchor.remove();
      // html.Url.revokeObjectUrl(url);
    } else {
      String storageDir = await getStorageDirectory();
      final file = File('$storageDir/cashConversionCycle.xlsx');
      await file.writeAsBytes(excel.encode()!);
      OpenFile.open(file.path);
    }
  }

  Future<void> generateDaysOutstandingExcel(DSOGraphList list) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      // sheet.appendRow([
      //   'Month',
      //   'Expenditure',
      // ]);
      for (var data in list.monthData) {
        sheet.appendRow([
          TextCellValue(data.name),
          DoubleCellValue(
            double.tryParse(data.achievement.toStringAsFixed(2)) ?? 0,
          ),
          DoubleCellValue(data.target),
        ]);
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('daysOutstandingExcel.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthlyExpenditure.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateDaysOutstandingPDF(DSOGraphList list) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Days Outstanding',
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
                for (var data in graphData.monthData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        data.name,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.achievement.toString(),
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
        final file = File('$storageDir/daysOutstanding.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
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

  Future<void> loadData(String selectedUser) async {
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
    await loadMonthlyInventory(userName, userLevel);
    await _loadMonthlyAnalysisPurchase();
    await _loadMonthlyAnalysisInventory();
    await _loadMonthlyAnalysisInventoryClosing();
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
      cashConversionData = CashConversionGraphList(monthData: []);
      graphData = DSOGraphList(monthData: []);
      purchaseMonthlyData = DailyAnalysisExpensesList(dailyData: []);
      inventoryMonthlyData = DailyAnalysisExpensesList(dailyData: []);
      inventoryClosingMonthlyData = DailyAnalysisExpensesList(dailyData: []);
    });
  }

  void toggleCheckbox() {
    setState(() {
      chartDataLoadedCCC = false;
      loadData("");
    });
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
    await _loadMonthlyAnalysisInventory();
    await _loadMonthlyAnalysisInventoryClosing();
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
                    // Row(
                    //   children: [
                    //     IconButton(
                    //       onPressed: () {
                    //         showFilterBottomSheet(context);
                    //       },
                    //       icon: const Icon(Icons.filter_alt_outlined),
                    //     ),
                    //   ],
                    // ),
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
                                  // generateVendorPaymentProjectionReport();
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
                                    generateDaysOutstandingExcel(graphData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateDaysOutstandingPDF(graphData);
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
                  setState(() {
                    // touchedMonth = monthlyAnalysisData
                    //     .monthData[barTouchResponse.spot!.spot.x.toInt()]
                    //     .monthName;
                    // List months = [
                    //   'Jan',
                    //   'Feb',
                    //   'Mar',
                    //   'Apr',
                    //   'May',
                    //   'Jun',
                    //   'Jul',
                    //   'Aug',
                    //   'Sep',
                    //   'Oct',
                    //   'Nov',
                    //   'Dec'
                    // ];
                    // if (flTouchEvent is FlTapUpEvent) {
                    //   touchedMonthIndex = touchedMonthIndex == 0
                    //       ? months.indexOf(touchedMonth.substring(0, 3)) + 1
                    //       : 0;
                    //   selectedChart = barTouchResponse.spot!.spot.x;
                    //   showDrillDownChart = true;
                    //   // loadDataWithFilter(
                    //   //   touchedMonthIndex,
                    //   //   touchedDailyDate,
                    //   //   touchedLedger,
                    //   // );
                    // }
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
                    '${graphData.monthData[grpIndex].name}\n',
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
                                      chartDataLoadedCCC = false;
                                      fromFilter = false;
                                      savedFinanceReceivablesOptionsTemp
                                          .clear();
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
