// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously
import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/classes/leads.dart';
import '../ReportService.dart';

final reportService = ReportService();

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
      // compute once
      final fromDate = dateFilterFlag
          ? formatDate(fromDateFilter!)
          : formatDate(fiscalYearStartDate!);

      final toDate = dateFilterFlag
          ? formatDate(toDateFilter!)
          : formatDate(currentDate!);

      do {
        final body = {
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index,
          "Limit": limit,
          "sapToken": DataManager.readSapToken(),
        };

        const apiUrl = '${ApiHelper.baseUrl}Bicxo_DebtorsAgingList';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final responseJson = jsonDecode(response.body);
          final data = responseJson['responseData'] as List?;

          if (data != null && data.isNotEmpty) {
            final newList = data
                .map((e) => DebtorsAgingList.fromJson(e))
                .toList();

            targetList.addAll(newList);
            fetchedCount = newList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      if (!mounted) return;

      // UI update only
      setState(() {
        context.read<MonthlyDebtorAgingProvider>().updateMonthlyDebtorAgingList(
          targetList,
        );

        debtorsListTemp = targetList;
        debtorsList = targetList;
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
    int limit = 10000;
    int fetchedCount = 0;

    List<CollectionList> collectionList = [];

    try {
      // compute once
      final fromDate = dateFilterFlag
          ? formatDate(fromDateFilter!)
          : formatDate(fiscalYearStartDate!);

      final toDate = dateFilterFlag
          ? formatDate(toDateFilter!)
          : formatDate(currentDate!);

      do {
        final body = {
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index,
          "Limit": limit,
          "sapToken": DataManager.readSapToken(),
        };

        const apiUrl = '${ApiHelper.baseUrl}CRMCollectionAnalysisList';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final responseJson = jsonDecode(response.body);
          final data = responseJson['responseData'] as List?;

          if (data != null && data.isNotEmpty) {
            final newList = data
                .map((e) => CollectionList.fromJson(e))
                .toList();

            collectionList.addAll(newList);
            fetchedCount = newList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      if (!mounted) return;

      setState(() {
        context
            .read<MonthlyCollectionListProvider>()
            .updateMonthlyDebtorAgingList(collectionList);

        collection = collectionList;
        collectionTemp = collectionList;
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
    final dateFormat = DateFormat('dd/MM/yyyy');
    final weeks = getWeeksOfCurrentMonth();

    final Map<String, MonthlyCollectionReportData> asmMap = {};

    // Process Debtors (commitment + balance)
    for (var d in debtorsList) {
      final date = dateFormat.parse(d.dueon);
      final asm = d.salesManager;

      final entry = asmMap.putIfAbsent(
        asm,
        () => MonthlyCollectionReportData(
          salesManager: asm,
          targetMonth: 0,
          weekOneCommitted: 0,
          weekOneReceived: 0,
          weekTwoCommitted: 0,
          weekTwoReceived: 0,
          weekThreeCommitted: 0,
          weekThreeReceived: 0,
          weekFourCommitted: 0,
          weekFourReceived: 0,
          weekFiveCommitted: 0,
          weekFiveReceived: 0,
        ),
      );

      // Target calculation
      if (date.isAtMost(currentDate!)) {
        entry.targetMonth += double.tryParse(d.commitment) ?? 0;
      }
      if (date.isAtMost(currentMonthToDate!)) {
        entry.targetMonth += double.tryParse(d.balance) ?? 0;
      }

      // Weekly commitment
      for (int i = 0; i < weeks.length; i++) {
        if (date.isAtLeast(weeks[i]['start']!) &&
            date.isAtMost(weeks[i]['end']!)) {
          switch (i) {
            case 0:
              entry.weekOneCommitted += double.tryParse(d.commitment) ?? 0;
              break;
            case 1:
              entry.weekTwoCommitted += double.tryParse(d.commitment) ?? 0;
              break;
            case 2:
              entry.weekThreeCommitted += double.tryParse(d.commitment) ?? 0;
              break;
            case 3:
              entry.weekFourCommitted += double.tryParse(d.commitment) ?? 0;
              break;
            case 4:
              entry.weekFiveCommitted += double.tryParse(d.commitment) ?? 0;
              break;
          }
        }
      }
    }

    // Process Collections (received)
    for (var c in collection) {
      final date = dateFormat.parse(c.postingDate);
      final asm = c.salesManager;

      final entry = asmMap[asm];
      if (entry == null) continue;

      for (int i = 0; i < weeks.length; i++) {
        if (date.isAtLeast(weeks[i]['start']!) &&
            date.isAtMost(weeks[i]['end']!)) {
          final value = double.tryParse(c.total) ?? 0;

          switch (i) {
            case 0:
              entry.weekOneReceived += value;
              break;
            case 1:
              entry.weekTwoReceived += value;
              break;
            case 2:
              entry.weekThreeReceived += value;
              break;
            case 3:
              entry.weekFourReceived += value;
              break;
            case 4:
              entry.weekFiveReceived += value;
              break;
          }
        }
      }
    }

    final asmwiseDataList = asmMap.values.toList()
      ..sort((a, b) => a.salesManager.compareTo(b.salesManager));

    weeklyData = MonthlyCollectionReportList(weeklyData: asmwiseDataList);
  }

  Future<void> generateMonthlyCollectionYTDExcel() async {
    await reportService.generateExcel(
      sheetName: 'MonthlyCollectionYTD',
      headers: [
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
      ],
      rows: weeklyData.weeklyData
          .map(
            (e) => [
              e.salesManager,
              e.targetMonth,
              e.weekOneCommitted +
                  e.weekTwoCommitted +
                  e.weekThreeCommitted +
                  e.weekFourCommitted +
                  e.weekFiveCommitted,
              e.weekOneReceived +
                  e.weekTwoReceived +
                  e.weekThreeReceived +
                  e.weekFourReceived +
                  e.weekFiveReceived,
              e.weekOneCommitted,
              e.weekOneReceived,
              getPercentage(e.weekOneCommitted, e.weekOneReceived),
              e.weekTwoCommitted,
              e.weekTwoReceived,
              getPercentage(e.weekTwoCommitted, e.weekTwoReceived),
              e.weekThreeCommitted,
              e.weekThreeReceived,
              getPercentage(e.weekThreeCommitted, e.weekThreeReceived),
              e.weekFourCommitted,
              e.weekFourReceived,
              getPercentage(e.weekFourCommitted, e.weekFourReceived),
              e.weekFiveCommitted,
              e.weekFiveReceived,
              getPercentage(e.weekFiveCommitted, e.weekFiveReceived),
            ],
          )
          .toList(),
      fileName: 'monthly_collection_YTD.xlsx',
      amountColumns: [2],
      addTotalRow: true,
      reportTitle: 'Finance - Monthly Collection YTD Analysis',
    );
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
        DateTime dueon = target.invoiceDate;
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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return chartDataLoadedMonthlyCollection == true
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
                                  generateMonthlyCollectionYTDExcel();
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
