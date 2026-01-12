// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously
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

import '../platform_excel_helper.dart';

class MonthlyCollectionReport extends StatefulWidget {
  const MonthlyCollectionReport({super.key});

  @override
  State<MonthlyCollectionReport> createState() =>
      _MonthlyCollectionReportState();
}

late Future<void> loadDataFuture;
String userLevel = "0";
List<Users> usersList = [];
bool chartDataLoadedMonthlyCollection = false;

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

List<DebtorsAgingList> debtorsList = [];
List<DebtorsAgingList> debtorsListTemp = [];
List<CollectionList> collection = [];
List<CollectionList> collectionTemp = [];
List<SalesList> sales = [];
List<SalesList> salesTemp = [];
List<SODetailsList> soList = [];
List<PurchaseList> purchasePrice = [];
List<POList> poListOpen = [];
List<InventoryList> inventory = [];

double monthlySales = 0;
double lowVal = 0;
double mediumVal = 0;
double highVal = 0;
double monthlySOvalue = 0;
double monthlyPurchasePriceSum = 0;
double monthlyPOSum = 0;
double lessThan30DaysValue = 0;
double a30to60DaysValue = 0;
double a60to90DaysValue = 0;
double nearExpiryValue = 0;
double expiredValue = 0;

MonthlyCollectionReportList weeklyData = MonthlyCollectionReportList(
  weeklyData: [],
);

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

class MonthlyDebtorAgingProvider with ChangeNotifier {
  List<DebtorsAgingList> _trialBalance = [];
  List<DebtorsAgingList> get trialBalanceList => _trialBalance;
  void updateMonthlyDebtorAgingList(
    List<DebtorsAgingList> newTrialBalanceList,
  ) {
    _trialBalance = newTrialBalanceList;
    notifyListeners();
  }
}

class MonthlyCollectionListProvider with ChangeNotifier {
  List<CollectionList> _collectionList = [];
  List<CollectionList> get trialBalanceList => _collectionList;
  void updateMonthlyDebtorAgingList(List<CollectionList> newList) {
    _collectionList = newList;
    notifyListeners();
  }
}

class _MonthlyCollectionReportState extends State<MonthlyCollectionReport> {
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

    int currentYear = now.year - 1;

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

    DateTime firstDayOfMonth = DateTime(yearForMonth, month, 1);
    DateTime lastDayOfMonth = DateTime(yearForMonth, month + 1, 0);

    return {'start': firstDayOfMonth, 'end': lastDayOfMonth};
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
    userLevel = prefs.getString('userLevel') ?? '';
    await _loadCollectionTarget(userName, userLevel);
    await _loadCollection(userName, userLevel);
    await _loadASMCollectionBarChartData();
    chartDataLoadedMonthlyCollection = true;
  }

  Future<void> _loadCollectionTarget(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<DebtorsAgingList> targetList = [];
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
        context.read<MonthlyDebtorAgingProvider>().updateMonthlyDebtorAgingList(
          targetList,
        );
        debtorsListTemp = targetList.toList();
        if (int.parse(UserLevel) == 5) {
          debtorsList = targetList.toList();
        } else if (int.parse(UserLevel) == 4) {
          debtorsList = targetList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          debtorsList = targetList.toList();
        } else {
          debtorsList = targetList.toList();
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

  Future<void> _loadCollection(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<CollectionList> collectionList = [];
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
        context
            .read<MonthlyCollectionListProvider>()
            .updateMonthlyDebtorAgingList(collectionList);

        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();
        menuNames.insert(0, UserName);
        if (int.parse(UserLevel) == 5) {
          collection = collectionList.toList();
          collectionTemp = collectionList.toList();
        } else if (int.parse(UserLevel) == 4) {
          collection = collectionList.toList();
          collectionTemp = collectionList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          collection = collectionList.toList();
          collectionTemp = collectionList.toList();
        } else {
          collection = collectionList.toList();
          collectionTemp = collectionList.toList();
        }
      });
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  List<Map<String, DateTime>> getWeeksOfCurrentMonth() {
    DateTime now = DateTime.now();
    int year = now.year;
    int month = now.month;

    // Get the first and last day of the month
    DateTime firstDay = DateTime(year, month, 1);
    DateTime lastDay = DateTime(year, month + 1, 0); // Last day of the month

    List<Map<String, DateTime>> weeks = [];

    DateTime startOfWeek = firstDay;
    while (startOfWeek.isBefore(lastDay) ||
        startOfWeek.isAtSameMomentAs(lastDay)) {
      DateTime endOfWeek = startOfWeek.add(
        Duration(days: 6 - startOfWeek.weekday + 1),
      );
      if (endOfWeek.isAfter(lastDay)) {
        endOfWeek = lastDay;
      }

      weeks.add({"start": startOfWeek, "end": endOfWeek});

      startOfWeek = endOfWeek.add(const Duration(days: 1));
    }

    return weeks;
  }

  double getPercentage(double? value, double? total) {
    if (value == null || value == 0 || total == null || total == 0) {
      return 0.0;
    }

    double rawPercentage = (value / total) * 100;

    double roundedPercentage = (rawPercentage * 100).round() / 100.0;

    return roundedPercentage;
  }

  Future<void> _loadASMCollectionBarChartData() async {
    List<MonthlyCollectionReportData> asmwiseDataList = [];
    DateTime startDate;
    DateTime endDate;
    DateTime monthEndDate;
    String asmName = "";
    double salesAmount = 0.00;

    double weekOneTotal = 0.0;
    double weekOneBalance = 0.0;
    double weekTwoTotal = 0.0;
    double weekTwoBalance = 0.0;
    double weekThreeTotal = 0.0;
    double weekThreeBalance = 0.0;
    double weekFourTotal = 0.0;
    double weekFourBalance = 0.0;
    double weekFiveTotal = 0.0;
    double weekFiveBalance = 0.0;

    List<DebtorsAgingList> asmCollectionList = [];
    List<DebtorsAgingList> asmCollectionListTarget = [];
    List<CollectionList> weekOneListCollection = [];
    List<CollectionList> weekTwoListCollection = [];
    List<CollectionList> weekThreeListCollection = [];
    List<CollectionList> weekFourListCollection = [];
    List<CollectionList> weekFiveListCollection = [];

    List<DebtorsAgingList> weekOneDebtors = [];
    List<DebtorsAgingList> weekTwoDebtors = [];
    List<DebtorsAgingList> weekThreeDebtors = [];
    List<DebtorsAgingList> weekFourDebtors = [];
    List<DebtorsAgingList> weekFiveDebtors = [];

    List<Map<String, DateTime>> weeks = getWeeksOfCurrentMonth();

    weekOneDebtors = debtorsList.where((target) {
      DateTime postingDate = DateFormat('dd/MM/yyyy').parse(target.dueon);
      return postingDate.isAtLeast(weeks[0]['start']!) &&
          postingDate.isAtMost(weeks[0]['end']!);
    }).toList();

    weekTwoDebtors = debtorsList.where((target) {
      DateTime postingDate = DateFormat('dd/MM/yyyy').parse(target.dueon);
      return postingDate.isAtLeast(weeks[1]['start']!) &&
          postingDate.isAtMost(weeks[1]['end']!);
    }).toList();
    weekThreeDebtors = debtorsList.where((target) {
      DateTime postingDate = DateFormat('dd/MM/yyyy').parse(target.dueon);
      return postingDate.isAtLeast(weeks[2]['start']!) &&
          postingDate.isAtMost(weeks[2]['end']!);
    }).toList();
    weekFourDebtors = debtorsList.where((target) {
      DateTime postingDate = DateFormat('dd/MM/yyyy').parse(target.dueon);
      return postingDate.isAtLeast(weeks[3]['start']!) &&
          postingDate.isAtMost(weeks[3]['end']!);
    }).toList();
    weekFourDebtors = debtorsList.where((target) {
      DateTime postingDate = DateFormat('dd/MM/yyyy').parse(target.dueon);
      return postingDate.isAtLeast(weeks[4]['start']!) &&
          postingDate.isAtMost(weeks[4]['end']!);
    }).toList();

    weekOneListCollection = collection.where((target) {
      DateTime postingDate = DateFormat('dd/MM/yyyy').parse(target.postingDate);
      return postingDate.isAtLeast(weeks[0]['start']!) &&
          postingDate.isAtMost(weeks[0]['end']!);
    }).toList();
    weekTwoListCollection = collection.where((target) {
      DateTime postingDate = DateFormat('dd/MM/yyyy').parse(target.postingDate);
      return postingDate.isAtLeast(weeks[1]['start']!) &&
          postingDate.isAtMost(weeks[1]['end']!);
    }).toList();
    weekThreeListCollection = collection.where((target) {
      DateTime postingDate = DateFormat('dd/MM/yyyy').parse(target.postingDate);
      return postingDate.isAtLeast(weeks[2]['start']!) &&
          postingDate.isAtMost(weeks[2]['end']!);
    }).toList();
    weekFourListCollection = collection.where((target) {
      DateTime postingDate = DateFormat('dd/MM/yyyy').parse(target.postingDate);
      return postingDate.isAtLeast(weeks[3]['start']!) &&
          postingDate.isAtMost(weeks[3]['end']!);
    }).toList();
    weekFiveListCollection = collection.where((target) {
      DateTime postingDate = DateFormat('dd/MM/yyyy').parse(target.postingDate);
      return postingDate.isAtLeast(weeks[4]['start']!) &&
          postingDate.isAtMost(weeks[4]['end']!);
    }).toList();

    startDate = currentMonthFromDate!;
    endDate = currentDate!;
    monthEndDate = currentMonthToDate!;

    asmCollectionList = debtorsList.where((target) {
      DateTime postingDate = DateFormat('dd/MM/yyyy').parse(target.dueon);
      return postingDate.isAtLeast(startDate) && postingDate.isAtMost(endDate);
    }).toList();
    asmCollectionListTarget = debtorsList.where((target) {
      DateTime postingDate = DateFormat('dd/MM/yyyy').parse(target.dueon);
      return postingDate.isAtMost(monthEndDate);
    }).toList();

    Set<String> processedAsmNames = {};
    for (var tsm in asmCollectionList) {
      if (!processedAsmNames.contains(tsm.salesManager)) {
        asmName = tsm.salesManager;
        for (var collection in asmCollectionList.where(
          (tsmelement) => tsmelement.salesManager == asmName,
        )) {
          salesAmount += double.tryParse(collection.commitment) ?? 0;
        }

        for (var collection in asmCollectionListTarget.where(
          (tsmelement) => tsmelement.salesManager == asmName,
        )) {
          salesAmount += double.tryParse(collection.balance) ?? 0;
        }

        for (var collection in weekOneListCollection.where(
          (tsmelement) => tsmelement.salesManager == asmName,
        )) {
          weekOneTotal += double.tryParse(collection.total) ?? 0;
        }
        for (var collection in weekOneDebtors.where(
          (tsmelement) => tsmelement.salesManager == asmName,
        )) {
          weekOneBalance += double.tryParse(collection.commitment) ?? 0;
        }
        for (var collection in weekTwoListCollection.where(
          (tsmelement) => tsmelement.salesManager == asmName,
        )) {
          weekTwoTotal += double.tryParse(collection.total) ?? 0;
        }
        for (var collection in weekTwoDebtors.where(
          (tsmelement) => tsmelement.salesManager == asmName,
        )) {
          weekTwoBalance += double.tryParse(collection.commitment) ?? 0;
        }
        for (var collection in weekThreeListCollection.where(
          (tsmelement) => tsmelement.salesManager == asmName,
        )) {
          weekThreeTotal += double.tryParse(collection.total) ?? 0;
        }
        for (var collection in weekThreeDebtors.where(
          (tsmelement) => tsmelement.salesManager == asmName,
        )) {
          weekThreeBalance += double.tryParse(collection.commitment) ?? 0;
        }
        for (var collection in weekFourListCollection.where(
          (tsmelement) => tsmelement.salesManager == asmName,
        )) {
          weekFourTotal += double.tryParse(collection.total) ?? 0;
        }
        for (var collection in weekFourDebtors.where(
          (tsmelement) => tsmelement.salesManager == asmName,
        )) {
          weekFourBalance += double.tryParse(collection.commitment) ?? 0;
        }
        for (var collection in weekFiveListCollection.where(
          (tsmelement) => tsmelement.salesManager == asmName,
        )) {
          weekFiveTotal += double.tryParse(collection.total) ?? 0;
        }
        for (var collection in weekFiveDebtors.where(
          (tsmelement) => tsmelement.salesManager == asmName,
        )) {
          weekFiveBalance += double.tryParse(collection.commitment) ?? 0;
        }

        asmwiseDataList.add(
          MonthlyCollectionReportData(
            salesManager: asmName,
            targetMonth:
                salesAmount +
                weekOneTotal +
                weekTwoTotal +
                weekThreeTotal +
                weekFourTotal +
                weekFiveTotal,
            weekOneCommitted: weekOneBalance,
            weekOneReceived: weekOneTotal,
            weekTwoCommitted: weekTwoBalance,
            weekTwoReceived: weekTwoTotal,
            weekThreeCommitted: weekThreeBalance,
            weekThreeReceived: weekThreeTotal,
            weekFourCommitted: weekFourBalance,
            weekFourReceived: weekFourTotal,
            weekFiveCommitted: weekFiveBalance,
            weekFiveReceived: weekFiveTotal,
          ),
        );
        processedAsmNames.add(asmName);
      }
      salesAmount = 0;
      asmName = "";
      weekOneTotal = 0.0;
      weekOneBalance = 0.0;
      weekTwoTotal = 0.0;
      weekTwoBalance = 0.0;
      weekThreeTotal = 0.0;
      weekThreeBalance = 0.0;
      weekFourTotal = 0.0;
      weekFourBalance = 0.0;
      weekFiveTotal = 0.0;
      weekFiveBalance = 0.0;
    }

    weeklyData = MonthlyCollectionReportList(weeklyData: asmwiseDataList);
  }

  Future<void> generateSalesAnalysisYTDExcel() async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Sheet1'];
    // sheet.getColAutoFits;
    sheet.appendRow(
      toCellRow([
        'Sales Manager',
        'Month Target',
        'Total Committed',
        'Total Received',
        'Week One Committed',
        'Week One Received',
        'Week One % Received',
        'Week Two Committed',
        'Week Two Received',
        'Week Two % Received',
        'Week Three Committed',
        'Week Three Received',
        'Week Three % Received',
        'Week Four Committed',
        'Week Four Received',
        'Week Four % Received',
        'Week Five Committed',
        'Week Five Received',
        'Week Five % Received',
      ]),
    );

    for (var weekly in weeklyData.weeklyData) {
      sheet.appendRow(
        toCellRow([
          weekly.salesManager,
          weekly.targetMonth,
          weekly.weekOneCommitted +
              weekly.weekTwoCommitted +
              weekly.weekThreeCommitted +
              weekly.weekFourCommitted +
              weekly.weekFiveCommitted,
          weekly.weekOneReceived +
              weekly.weekTwoReceived +
              weekly.weekThreeReceived +
              weekly.weekFourReceived +
              weekly.weekFiveReceived,
          weekly.weekOneCommitted,
          weekly.weekOneReceived,
          getPercentage(weekly.weekOneCommitted, weekly.weekOneReceived),
          weekly.weekTwoCommitted,
          weekly.weekTwoReceived,
          getPercentage(weekly.weekTwoCommitted, weekly.weekTwoReceived),
          weekly.weekThreeCommitted,
          weekly.weekThreeReceived,
          getPercentage(weekly.weekThreeCommitted, weekly.weekThreeReceived),
          weekly.weekFourCommitted,
          weekly.weekFourReceived,
          getPercentage(weekly.weekFourCommitted, weekly.weekFourReceived),
          weekly.weekFiveCommitted,
          weekly.weekFiveReceived,
          getPercentage(weekly.weekFiveCommitted, weekly.weekFiveReceived),
        ]),
      );
    }

    setState(() {
      // YtdSalesBarChartData = true;
    });

    if (kIsWeb) {
      // var fileBytes = excel.save(fileName: 'sales_analysis_ytd_report.xlsx');

      final excelBytes = excel.encode()!;
      saveAndOpenExcel('monthlyCollectionReport.xlsx', excelBytes);

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
      final file = File('$storageDir/monthlyCollectionReport.xlsx');
      await file.writeAsBytes(excel.encode()!);
      OpenFile.open(file.path);
    }
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

  SideTitles get _bottomTitlesMonthlyAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<MonthlyCollectionReportData> mData = weeklyData.weeklyData;
      text = mData.elementAt(value.toInt()).salesManager;
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
    List<MonthlyCollectionReportData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF2CA9DF),
                borderRadius: BorderRadius.zero,
                toY:
                    chartData.weekOneReceived +
                    chartData.weekTwoReceived +
                    chartData.weekThreeReceived +
                    chartData.weekFourReceived +
                    chartData.weekFiveReceived,
                width: 15,
              ),
              BarChartRodData(
                color: Colors.green,
                borderRadius: BorderRadius.zero,
                toY: chartData.targetMonth,
                width: 15,
              ),
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY:
                    chartData.weekOneCommitted +
                    chartData.weekTwoCommitted +
                    chartData.weekThreeCommitted +
                    chartData.weekFourCommitted +
                    chartData.weekFiveCommitted,
                width: 15,
              ),
            ],
          ),
        )
        .toList();
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
    chartDataLoadedMonthlyCollection = true;
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
      chartDataLoadedMonthlyCollection = false;
      weeklyData = MonthlyCollectionReportList(weeklyData: []);
    });
  }

  void toggleCheckbox() {
    setState(() {
      chartDataLoadedMonthlyCollection = false;
      loadData("");
      // selectedCheckbox = index;
    });
  }

  Future<void> _dateFilterTarget() async {
    setState(() {
      context
          .read<MonthlyCollectionListProvider>()
          .updateMonthlyDebtorAgingList(collection);
      context.read<MonthlyDebtorAgingProvider>().updateMonthlyDebtorAgingList(
        debtorsList,
      );

      collection = collection.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.postingDate);
        // DateTime toDt = formatter.parse('31/${target.monthYear}');
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();

      sales = sales.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();

      debtorsList = debtorsList.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.postingDate);
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();
    });
  }

  Future<void> filterDateFunction() async {
    collection = collectionTemp;
    debtorsList = debtorsListTemp;
    _dateFilterTarget();
    await _loadASMCollectionBarChartData();
    setState(() {});
    chartDataLoadedMonthlyCollection = true;
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
  Widget build(BuildContext context) {
    return chartDataLoadedMonthlyCollection == true
        ? SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                //   Center(
                //   child: ElevatedButton
                //     (
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: const Color(0xff2ca9df),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(5.0),
                //       ),
                //     ),
                //     onPressed: () {
                //       generateSalesAnalysisYTDExcel();
                //     },
                //     child: const SizedBox(
                //       width: 400,
                //       child: Center(
                //         child: Text(
                //           "Download Reports",
                //           style: TextStyle(fontSize: 14, color: Colors.white),
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
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
                                "${formatDateString(currentMonthFromDate!)} - ${formatDateString(currentDate!)}",
                              ),
                      ],
                    ),
                    Row(
                      children: [
                        // IconButton(
                        //   onPressed: () {
                        //     showFilterBottomSheet(context);
                        //   },
                        //   icon: const Icon(Icons.filter_alt_outlined),
                        // ),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  generateSalesAnalysisYTDExcel();
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
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  Widget _monthlyAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = weeklyData.weeklyData.length;
    if (len > 5) {
      chartWidth = screenWidth + (80 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? weeklyData.weeklyData
              .map((data) => (data.targetMonth))
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
            barGroups: _monthlyAnalysisChartData(weeklyData.weeklyData),
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
                    '${weeklyData.weeklyData[grpIndex].salesManager}-'
                    '${getMonthName(DateTime.now().month)}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            'Monthly Received: ${formatAmount(weeklyData.weeklyData[grpIndex].weekOneReceived + weeklyData.weeklyData[grpIndex].weekTwoReceived + weeklyData.weeklyData[grpIndex].weekThreeReceived + weeklyData.weeklyData[grpIndex].weekFourReceived + weeklyData.weeklyData[grpIndex].weekFiveReceived)}\n',
                        style: const TextStyle(
                          color: Color(0xFF2CA9DF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Monthly Committed: ${formatAmount(weeklyData.weeklyData[grpIndex].weekOneCommitted + weeklyData.weeklyData[grpIndex].weekTwoCommitted + weeklyData.weeklyData[grpIndex].weekThreeCommitted + weeklyData.weeklyData[grpIndex].weekFourCommitted + weeklyData.weeklyData[grpIndex].weekFiveCommitted)}\n',
                        style: const TextStyle(
                          color: Color(0xFFFF9F47),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Target: ${formatAmount(weeklyData.weeklyData[grpIndex].targetMonth)}',
                        style: const TextStyle(
                          color: Colors.green,
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
                                      chartDataLoadedMonthlyCollection = false;
                                      fromFilter = false;
                                      savedFinanceReceivablesOptionsTemp
                                          .clear();
                                      setState(() {
                                        chartDataLoadedMonthlyCollection =
                                            false;
                                        loadDataFuture = removeFilter();
                                        Navigator.pop(context);
                                        chartDataLoadedMonthlyCollection = true;
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
