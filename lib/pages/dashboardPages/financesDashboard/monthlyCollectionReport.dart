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
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

class MonthlyCollectionReport extends StatefulWidget {
  const MonthlyCollectionReport({super.key});

  @override
  State<MonthlyCollectionReport> createState() =>
      _MonthlyCollectionReportState();
}

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
  final reportService = ReportService();
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
  List<DebtorsAgingList> debtorsListFiltered = [];
  List<CollectionList> collection = [];
  List<CollectionList> collectionFiltered = [];
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

  String? selectedRsm;
  String? selectedAsm;
  String? selectedTsm;

  MonthlyCollectionReportList customerData = MonthlyCollectionReportList(
    weeklyData: [],
  );

  MonthlyCollectionReportList asmData = MonthlyCollectionReportList(
    weeklyData: [],
  );

  MonthlyCollectionReportList rsmData = MonthlyCollectionReportList(
    weeklyData: [],
  );

  MonthlyCollectionReportList tsmData = MonthlyCollectionReportList(
    weeklyData: [],
  );

  DateTime? fromDateFilter;
  DateTime? toDateFilter;
  DateTime selectedMonth = DateTime.now();
  bool dateFilterFlag = false;

  bool fromFilter = false;

  List<List<String>> filterOptions = [[]];

  List<String> selectedSalesData = [];

  final ScrollController _mainScrollController = ScrollController();

  final ScrollController _horizontalCustomerController = ScrollController();
  final ScrollController _horizontalRsmController = ScrollController();
  final ScrollController _horizontalAsmController = ScrollController();
  final ScrollController _horizontalTsmController = ScrollController();

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
    await applyChartFilters();
    setState(() {
      chartDataLoadedMonthlyCollection = true;
    });
  }

  Future<void> _loadCollectionTarget(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;

    List<DebtorsAgingList> targetList = [];

    try {
      final toDate = dateFilterFlag
          ? formatDate(toDateFilter!)
          : formatDate(currentMonthToDate!);

      do {
        final body = {
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
                .where((item) => (double.tryParse(item.balance) ?? 0) > 0)
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

        debtorsListFiltered = targetList;
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
        collectionFiltered = collectionList;
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

  Future<void> applyChartFilters() async {
    //Apply filters to collection and debtors list
    collectionFiltered = collection.where((e) {
      bool match = true;

      if (selectedRsm != null) {
        match = match && e.regionalManager == selectedRsm;
      }

      if (selectedAsm != null) {
        match = match && e.salesManager == selectedAsm;
      }

      if (selectedTsm != null) {
        match = match && e.salesRep == selectedTsm;
      }

      return match;
    }).toList();

    debtorsListFiltered = debtorsList.where((e) {
      bool match = true;

      if (selectedRsm != null) {
        match = match && e.regionalManager == selectedRsm;
      }

      if (selectedAsm != null) {
        match = match && e.salesManager == selectedAsm;
      }

      if (selectedTsm != null) {
        match = match && e.salesRep == selectedTsm;
      }

      return match;
    }).toList();

    await _loadTSMCollectionBarChartData();
    await _loadASMCollectionBarChartData();
    await _loadRSMCollectionBarChartData();
    await _loadCustomerCollectionBarChartData();

    setState(() {});
  }

  List<Map<String, DateTime>> getWeeksOfCurrentMonth() {
    DateTime now = selectedMonth;

    int year = now.year;
    int month = now.month;

    DateTime lastDay = DateTime(year, month + 1, 0);

    return [
      {"start": DateTime(year, month, 1), "end": DateTime(year, month, 7)},
      {"start": DateTime(year, month, 8), "end": DateTime(year, month, 15)},
      {"start": DateTime(year, month, 16), "end": DateTime(year, month, 23)},
      {"start": DateTime(year, month, 24), "end": lastDay},
    ];
  }

  double getPercentage(double? value, double? total) {
    if (value == null || value == 0 || total == null || total == 0) {
      return 0.0;
    }

    double rawPercentage = (value / total) * 100;

    double roundedPercentage = (rawPercentage * 100).round() / 100.0;

    return roundedPercentage;
  }

  Future<void> _loadTSMCollectionBarChartData() async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final weeks = getWeeksOfCurrentMonth();

    final Map<String, MonthlyCollectionReportData> tsmMap = {};

    // Process Debtors (commitment + balance)
    for (var d in debtorsListFiltered) {
      final date = dateFormat.parse(d.dueon);
      final tsm = d.salesRep;

      final entry = tsmMap.putIfAbsent(
        tsm,
        () => MonthlyCollectionReportData(
          customerName: "",
          regionalManager: "",
          salesManager: "",
          salesPerson: tsm,
          targetMonth: 0,
          weekOneCommitted: 0,
          weekOneReceived: 0,
          weekTwoCommitted: 0,
          weekTwoReceived: 0,
          weekThreeCommitted: 0,
          weekThreeReceived: 0,
          weekFourCommitted: 0,
          weekFourReceived: 0,
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
          }
        }
      }
    }

    // Process Collections (received)
    for (var c in collectionFiltered) {
      final date = dateFormat.parse(c.postingDate);
      final tsm = c.salesRep;

      final entry = tsmMap[tsm];
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
          }
        }
      }
    }

    final tsmwiseDataList = tsmMap.values.toList()
      ..sort((a, b) {
        final aReceived =
            a.weekOneReceived +
            a.weekTwoReceived +
            a.weekThreeReceived +
            a.weekFourReceived;

        final bReceived =
            b.weekOneReceived +
            b.weekTwoReceived +
            b.weekThreeReceived +
            b.weekFourReceived;

        final aDefault = a.targetMonth - aReceived;
        final bDefault = b.targetMonth - bReceived;

        return bDefault.compareTo(aDefault);
      });

    tsmData = MonthlyCollectionReportList(weeklyData: tsmwiseDataList);
  }

  Future<void> _loadASMCollectionBarChartData() async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final weeks = getWeeksOfCurrentMonth();

    final Map<String, MonthlyCollectionReportData> asmMap = {};

    // Process Debtors (commitment + balance)
    for (var d in debtorsListFiltered) {
      final date = dateFormat.parse(d.dueon);
      final asm = d.salesManager;

      final entry = asmMap.putIfAbsent(
        asm,
        () => MonthlyCollectionReportData(
          customerName: "",
          regionalManager: "",
          salesManager: asm,
          salesPerson: "",
          targetMonth: 0,
          weekOneCommitted: 0,
          weekOneReceived: 0,
          weekTwoCommitted: 0,
          weekTwoReceived: 0,
          weekThreeCommitted: 0,
          weekThreeReceived: 0,
          weekFourCommitted: 0,
          weekFourReceived: 0,
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
          }
        }
      }
    }

    // Process Collections (received)
    for (var c in collectionFiltered) {
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
          }
        }
      }
    }

    final asmwiseDataList = asmMap.values.toList()
      ..sort((a, b) {
        final aReceived =
            a.weekOneReceived +
            a.weekTwoReceived +
            a.weekThreeReceived +
            a.weekFourReceived;

        final bReceived =
            b.weekOneReceived +
            b.weekTwoReceived +
            b.weekThreeReceived +
            b.weekFourReceived;

        final aDefault = a.targetMonth - aReceived;
        final bDefault = b.targetMonth - bReceived;

        return bDefault.compareTo(aDefault);
      });

    asmData = MonthlyCollectionReportList(weeklyData: asmwiseDataList);
  }

  Future<void> _loadRSMCollectionBarChartData() async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final weeks = getWeeksOfCurrentMonth();

    final Map<String, MonthlyCollectionReportData> rsmMap = {};

    // Process Debtors (commitment + balance)

    for (var d in debtorsListFiltered) {
      final date = dateFormat.parse(d.dueon);
      final rsm = d.regionalManager;
      final expPayDate = d.expectedPayment.toString().trim().isNotEmpty
          ? dateFormat.tryParse(d.expectedPayment)
          : null;

      final entry = rsmMap.putIfAbsent(
        rsm,
        () => MonthlyCollectionReportData(
          customerName: "",
          regionalManager: rsm,
          salesManager: "",
          salesPerson: "",
          targetMonth: 0,
          weekOneCommitted: 0,
          weekOneReceived: 0,
          weekTwoCommitted: 0,
          weekTwoReceived: 0,
          weekThreeCommitted: 0,
          weekThreeReceived: 0,
          weekFourCommitted: 0,
          weekFourReceived: 0,
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
      if (expPayDate != null) {
        for (int i = 0; i < weeks.length; i++) {
          if (expPayDate.isAtLeast(weeks[i]['start']!) &&
              expPayDate.isAtMost(weeks[i]['end']!)) {
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
            }
          }
        }
      }
    }

    // Process Collections (received)
    for (var c in collectionFiltered) {
      final date = dateFormat.parse(c.postingDate);
      final rsm = c.regionalManager;

      final entry = rsmMap[rsm];
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
          }
        }
      }
    }

    final rsmwiseDataList = rsmMap.values.toList()
      ..sort((a, b) {
        final aReceived =
            a.weekOneReceived +
            a.weekTwoReceived +
            a.weekThreeReceived +
            a.weekFourReceived;

        final bReceived =
            b.weekOneReceived +
            b.weekTwoReceived +
            b.weekThreeReceived +
            b.weekFourReceived;

        final aDefault = a.targetMonth - aReceived;
        final bDefault = b.targetMonth - bReceived;

        return bDefault.compareTo(aDefault);
      });

    rsmData = MonthlyCollectionReportList(weeklyData: rsmwiseDataList);
  }

  Future<void> _loadCustomerCollectionBarChartData() async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final weeks = getWeeksOfCurrentMonth();

    final Map<String, MonthlyCollectionReportData> customerMap = {};

    // Process Debtors (commitment + balance)

    for (var d in debtorsListFiltered) {
      final date = dateFormat.parse(d.dueon);
      final customer = d.customerName;
      final expPayDate = d.expectedPayment.toString().trim().isNotEmpty
          ? dateFormat.tryParse(d.expectedPayment)
          : null;

      final entry = customerMap.putIfAbsent(
        customer,
        () => MonthlyCollectionReportData(
          customerName: customer,
          regionalManager: "",
          salesManager: "",
          salesPerson: "",
          targetMonth: 0,
          weekOneCommitted: 0,
          weekOneReceived: 0,
          weekTwoCommitted: 0,
          weekTwoReceived: 0,
          weekThreeCommitted: 0,
          weekThreeReceived: 0,
          weekFourCommitted: 0,
          weekFourReceived: 0,
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
      if (expPayDate != null) {
        for (int i = 0; i < weeks.length; i++) {
          if (expPayDate.isAtLeast(weeks[i]['start']!) &&
              expPayDate.isAtMost(weeks[i]['end']!)) {
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
            }
          }
        }
      }
    }

    // Process Collections (received)
    for (var c in collectionFiltered) {
      final date = dateFormat.parse(c.postingDate);
      final customer = c.customerName;

      final entry = customerMap[customer];
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
          }
        }
      }
    }

    final customerwiseDataList = customerMap.values.toList()
      ..sort((a, b) {
        final aReceived =
            a.weekOneReceived +
            a.weekTwoReceived +
            a.weekThreeReceived +
            a.weekFourReceived;

        final bReceived =
            b.weekOneReceived +
            b.weekTwoReceived +
            b.weekThreeReceived +
            b.weekFourReceived;

        final aDefault = a.targetMonth - aReceived;
        final bDefault = b.targetMonth - bReceived;

        return bDefault.compareTo(aDefault);
      });

    customerData = MonthlyCollectionReportList(
      weeklyData: customerwiseDataList,
    );
  }

  Future<void> generateTsmMonthlyCollectionExcel() async {
    final weeks = getWeeksOfCurrentMonth();

    await reportService.generateExcel(
      sheetName: 'TsmMonthlyCollection',
      headers: [
        'Sales Person',
        'Month Target',
        '${DateFormat('dd').format(weeks[0]['start']!)}-${DateFormat('dd MMM').format(weeks[0]['end']!)} Committed',
        '${DateFormat('dd').format(weeks[0]['start']!)}-${DateFormat('dd MMM').format(weeks[0]['end']!)} Received',
        '${DateFormat('dd').format(weeks[0]['start']!)}-${DateFormat('dd MMM').format(weeks[0]['end']!)} % Received',

        '${DateFormat('dd').format(weeks[1]['start']!)}-${DateFormat('dd MMM').format(weeks[1]['end']!)} Committed',
        '${DateFormat('dd').format(weeks[1]['start']!)}-${DateFormat('dd MMM').format(weeks[1]['end']!)} Received',
        '${DateFormat('dd').format(weeks[1]['start']!)}-${DateFormat('dd MMM').format(weeks[1]['end']!)} % Received',

        '${DateFormat('dd').format(weeks[2]['start']!)}-${DateFormat('dd MMM').format(weeks[2]['end']!)} Committed',
        '${DateFormat('dd').format(weeks[2]['start']!)}-${DateFormat('dd MMM').format(weeks[2]['end']!)} Received',
        '${DateFormat('dd').format(weeks[2]['start']!)}-${DateFormat('dd MMM').format(weeks[2]['end']!)} % Received',

        '${DateFormat('dd').format(weeks[3]['start']!)}-${DateFormat('dd MMM').format(weeks[3]['end']!)} Committed',
        '${DateFormat('dd').format(weeks[3]['start']!)}-${DateFormat('dd MMM').format(weeks[3]['end']!)} Received',
        '${DateFormat('dd').format(weeks[3]['start']!)}-${DateFormat('dd MMM').format(weeks[3]['end']!)} % Received',
        'Total Committed',
        'Total Received',
        '${DateFormat('MMM').format(weeks[3]['end']!)} %',
      ],
      rows: tsmData.weeklyData
          .map(
            (e) => [
              e.salesPerson,
              e.targetMonth,
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
              e.weekOneCommitted +
                  e.weekTwoCommitted +
                  e.weekThreeCommitted +
                  e.weekFourCommitted,
              e.weekOneReceived +
                  e.weekTwoReceived +
                  e.weekThreeReceived +
                  e.weekFourReceived,
              getPercentage(
                e.weekOneCommitted +
                    e.weekTwoCommitted +
                    e.weekThreeCommitted +
                    e.weekFourCommitted,
                e.weekOneReceived +
                    e.weekTwoReceived +
                    e.weekThreeReceived +
                    e.weekFourReceived,
              ),
            ],
          )
          .toList(),
      fileName: 'tsm_monthly_collection.xlsx',
      amountColumns: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
      addTotalRow: true,
      reportTitle: 'Finance - TSM Monthly Collection Analysis',
    );
  }

  Future<void> generateAsmMonthlyCollectionExcel() async {
    final weeks = getWeeksOfCurrentMonth();
    await reportService.generateExcel(
      sheetName: 'AsmMonthlyCollection',
      headers: [
        'Sales Manager',
        'Month Target',
        '${DateFormat('dd').format(weeks[0]['start']!)}-${DateFormat('dd MMM').format(weeks[0]['end']!)} Committed',
        '${DateFormat('dd').format(weeks[0]['start']!)}-${DateFormat('dd MMM').format(weeks[0]['end']!)} Received',
        '${DateFormat('dd').format(weeks[0]['start']!)}-${DateFormat('dd MMM').format(weeks[0]['end']!)} % Received',

        '${DateFormat('dd').format(weeks[1]['start']!)}-${DateFormat('dd MMM').format(weeks[1]['end']!)} Committed',
        '${DateFormat('dd').format(weeks[1]['start']!)}-${DateFormat('dd MMM').format(weeks[1]['end']!)} Received',
        '${DateFormat('dd').format(weeks[1]['start']!)}-${DateFormat('dd MMM').format(weeks[1]['end']!)} % Received',

        '${DateFormat('dd').format(weeks[2]['start']!)}-${DateFormat('dd MMM').format(weeks[2]['end']!)} Committed',
        '${DateFormat('dd').format(weeks[2]['start']!)}-${DateFormat('dd MMM').format(weeks[2]['end']!)} Received',
        '${DateFormat('dd').format(weeks[2]['start']!)}-${DateFormat('dd MMM').format(weeks[2]['end']!)} % Received',

        '${DateFormat('dd').format(weeks[3]['start']!)}-${DateFormat('dd MMM').format(weeks[3]['end']!)} Committed',
        '${DateFormat('dd').format(weeks[3]['start']!)}-${DateFormat('dd MMM').format(weeks[3]['end']!)} Received',
        '${DateFormat('dd').format(weeks[3]['start']!)}-${DateFormat('dd MMM').format(weeks[3]['end']!)} % Received',
        'Total Committed',
        'Total Received',
        '${DateFormat('MMM').format(weeks[3]['end']!)} %',
      ],
      rows: asmData.weeklyData
          .map(
            (e) => [
              e.salesManager,
              e.targetMonth,
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
              e.weekOneCommitted +
                  e.weekTwoCommitted +
                  e.weekThreeCommitted +
                  e.weekFourCommitted,
              e.weekOneReceived +
                  e.weekTwoReceived +
                  e.weekThreeReceived +
                  e.weekFourReceived,
              getPercentage(
                e.weekOneCommitted +
                    e.weekTwoCommitted +
                    e.weekThreeCommitted +
                    e.weekFourCommitted,
                e.weekOneReceived +
                    e.weekTwoReceived +
                    e.weekThreeReceived +
                    e.weekFourReceived,
              ),
            ],
          )
          .toList(),
      fileName: 'asm_monthly_collection.xlsx',
      amountColumns: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
      addTotalRow: true,
      reportTitle: 'Finance - ASM Monthly Collection Analysis',
    );
  }

  Future<void> generateRsmMonthlyCollectionExcel() async {
    final weeks = getWeeksOfCurrentMonth();
    await reportService.generateExcel(
      sheetName: 'MonthlyRsmCollection',
      headers: [
        'Regional Manager',
        'Month Target',
        '${DateFormat('dd').format(weeks[0]['start']!)}-${DateFormat('dd MMM').format(weeks[0]['end']!)} Committed',
        '${DateFormat('dd').format(weeks[0]['start']!)}-${DateFormat('dd MMM').format(weeks[0]['end']!)} Received',
        '${DateFormat('dd').format(weeks[0]['start']!)}-${DateFormat('dd MMM').format(weeks[0]['end']!)} % Received',

        '${DateFormat('dd').format(weeks[1]['start']!)}-${DateFormat('dd MMM').format(weeks[1]['end']!)} Committed',
        '${DateFormat('dd').format(weeks[1]['start']!)}-${DateFormat('dd MMM').format(weeks[1]['end']!)} Received',
        '${DateFormat('dd').format(weeks[1]['start']!)}-${DateFormat('dd MMM').format(weeks[1]['end']!)} % Received',

        '${DateFormat('dd').format(weeks[2]['start']!)}-${DateFormat('dd MMM').format(weeks[2]['end']!)} Committed',
        '${DateFormat('dd').format(weeks[2]['start']!)}-${DateFormat('dd MMM').format(weeks[2]['end']!)} Received',
        '${DateFormat('dd').format(weeks[2]['start']!)}-${DateFormat('dd MMM').format(weeks[2]['end']!)} % Received',

        '${DateFormat('dd').format(weeks[3]['start']!)}-${DateFormat('dd MMM').format(weeks[3]['end']!)} Committed',
        '${DateFormat('dd').format(weeks[3]['start']!)}-${DateFormat('dd MMM').format(weeks[3]['end']!)} Received',
        '${DateFormat('dd').format(weeks[3]['start']!)}-${DateFormat('dd MMM').format(weeks[3]['end']!)} % Received',
        'Total Committed',
        'Total Received',
        '${DateFormat('MMM').format(weeks[3]['end']!)} %',
      ],
      rows: rsmData.weeklyData
          .map(
            (e) => [
              e.regionalManager,
              e.targetMonth,
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
              e.weekOneCommitted +
                  e.weekTwoCommitted +
                  e.weekThreeCommitted +
                  e.weekFourCommitted,
              e.weekOneReceived +
                  e.weekTwoReceived +
                  e.weekThreeReceived +
                  e.weekFourReceived,
              getPercentage(
                e.weekOneCommitted +
                    e.weekTwoCommitted +
                    e.weekThreeCommitted +
                    e.weekFourCommitted,
                e.weekOneReceived +
                    e.weekTwoReceived +
                    e.weekThreeReceived +
                    e.weekFourReceived,
              ),
            ],
          )
          .toList(),
      fileName: 'rsm_monthly_collection_.xlsx',
      amountColumns: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
      addTotalRow: true,
      reportTitle: 'Finance - RSM Monthly Collection Analysis',
    );
  }

  Future<void> generateCustomerMonthlyCollectionExcel() async {
    final weeks = getWeeksOfCurrentMonth();
    await reportService.generateExcel(
      sheetName: 'MonthlyCustomerCollection',
      headers: [
        'Customer Name',
        'Month Target',
        '${DateFormat('dd').format(weeks[0]['start']!)}-${DateFormat('dd MMM').format(weeks[0]['end']!)} Committed',
        '${DateFormat('dd').format(weeks[0]['start']!)}-${DateFormat('dd MMM').format(weeks[0]['end']!)} Received',
        '${DateFormat('dd').format(weeks[0]['start']!)}-${DateFormat('dd MMM').format(weeks[0]['end']!)} % Received',

        '${DateFormat('dd').format(weeks[1]['start']!)}-${DateFormat('dd MMM').format(weeks[1]['end']!)} Committed',
        '${DateFormat('dd').format(weeks[1]['start']!)}-${DateFormat('dd MMM').format(weeks[1]['end']!)} Received',
        '${DateFormat('dd').format(weeks[1]['start']!)}-${DateFormat('dd MMM').format(weeks[1]['end']!)} % Received',

        '${DateFormat('dd').format(weeks[2]['start']!)}-${DateFormat('dd MMM').format(weeks[2]['end']!)} Committed',
        '${DateFormat('dd').format(weeks[2]['start']!)}-${DateFormat('dd MMM').format(weeks[2]['end']!)} Received',
        '${DateFormat('dd').format(weeks[2]['start']!)}-${DateFormat('dd MMM').format(weeks[2]['end']!)} % Received',

        '${DateFormat('dd').format(weeks[3]['start']!)}-${DateFormat('dd MMM').format(weeks[3]['end']!)} Committed',
        '${DateFormat('dd').format(weeks[3]['start']!)}-${DateFormat('dd MMM').format(weeks[3]['end']!)} Received',
        '${DateFormat('dd').format(weeks[3]['start']!)}-${DateFormat('dd MMM').format(weeks[3]['end']!)} % Received',
        'Total Committed',
        'Total Received',
        '${DateFormat('MMM').format(weeks[3]['end']!)} %',
      ],
      rows: customerData.weeklyData
          .map(
            (e) => [
              e.customerName,
              e.targetMonth,
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
              e.weekOneCommitted +
                  e.weekTwoCommitted +
                  e.weekThreeCommitted +
                  e.weekFourCommitted,
              e.weekOneReceived +
                  e.weekTwoReceived +
                  e.weekThreeReceived +
                  e.weekFourReceived,
              getPercentage(
                e.weekOneCommitted +
                    e.weekTwoCommitted +
                    e.weekThreeCommitted +
                    e.weekFourCommitted,
                e.weekOneReceived +
                    e.weekTwoReceived +
                    e.weekThreeReceived +
                    e.weekFourReceived,
              ),
            ],
          )
          .toList(),
      fileName: 'customer_monthly_collection_.xlsx',
      amountColumns: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
      addTotalRow: true,
      reportTitle: 'Finance - Customer Monthly Collection Analysis',
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

  SideTitles get _bottomTitlesTsmAnalysis => SideTitles(
    reservedSize: 70,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<MonthlyCollectionReportData> mData = tsmData.weeklyData;
      if (value.toInt() >= mData.length) {
        return const SizedBox();
      }

      text = mData[value.toInt()].salesPerson;
      return Padding(
        padding: const EdgeInsets.only(top: 14.0),
        child: Transform.rotate(
          angle: -0.5,
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesAsmAnalysis => SideTitles(
    reservedSize: 70,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<MonthlyCollectionReportData> mData = asmData.weeklyData;
      if (value.toInt() >= mData.length) {
        return const SizedBox();
      }

      text = mData[value.toInt()].salesManager;
      // text = mData.elementAt(value.toInt()).salesManager;
      return Padding(
        padding: const EdgeInsets.only(top: 14.0),
        child: Transform.rotate(
          angle: -0.5,
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesRsmAnalysis => SideTitles(
    reservedSize: 70,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<MonthlyCollectionReportData> mData = rsmData.weeklyData;
      if (value.toInt() >= mData.length) {
        return const SizedBox();
      }

      text = mData[value.toInt()].regionalManager;
      return Padding(
        padding: const EdgeInsets.only(top: 14.0),
        child: Transform.rotate(
          angle: -0.5,
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesCustomerAnalysis => SideTitles(
    reservedSize: 70,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<MonthlyCollectionReportData> mData = customerData.weeklyData;
      if (value.toInt() >= mData.length) {
        return const SizedBox();
      }

      text = mData[value.toInt()].customerName!;

      return Padding(
        padding: const EdgeInsets.only(top: 14.0),
        child: Transform.rotate(
          angle: -0.5,
          child: SizedBox(
            width: 80,
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      );
    },
  );

  List<BarChartGroupData> _monthlyTsmAnalysisChartData(
    List<MonthlyCollectionReportData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: selectedTsm == chartData.salesPerson
                    ? Colors.red
                    : const Color(0xFF2CA9DF),
                borderRadius: BorderRadius.zero,
                toY:
                    chartData.weekOneReceived +
                    chartData.weekTwoReceived +
                    chartData.weekThreeReceived +
                    chartData.weekFourReceived,
                width: 15,
              ),
              BarChartRodData(
                color: selectedTsm == chartData.salesPerson
                    ? Colors.red.shade300
                    : Colors.green,
                borderRadius: BorderRadius.zero,
                toY: chartData.targetMonth,
                width: 15,
              ),
              BarChartRodData(
                color: selectedTsm == chartData.salesPerson
                    ? Colors.red.shade100
                    : const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY:
                    chartData.weekOneCommitted +
                    chartData.weekTwoCommitted +
                    chartData.weekThreeCommitted +
                    chartData.weekFourCommitted,
                width: 15,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _monthlyAsmAnalysisChartData(
    List<MonthlyCollectionReportData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: selectedAsm == chartData.salesManager
                    ? Colors.red
                    : const Color(0xFF2CA9DF),
                borderRadius: BorderRadius.zero,
                toY:
                    chartData.weekOneReceived +
                    chartData.weekTwoReceived +
                    chartData.weekThreeReceived +
                    chartData.weekFourReceived,
                width: 15,
              ),
              BarChartRodData(
                color: selectedAsm == chartData.salesManager
                    ? Colors.red.shade300
                    : Colors.green,
                borderRadius: BorderRadius.zero,
                toY: chartData.targetMonth,
                width: 15,
              ),
              BarChartRodData(
                color: selectedAsm == chartData.salesManager
                    ? Colors.red.shade100
                    : const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY:
                    chartData.weekOneCommitted +
                    chartData.weekTwoCommitted +
                    chartData.weekThreeCommitted +
                    chartData.weekFourCommitted,
                width: 15,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _monthlyRsmAnalysisChartData(
    List<MonthlyCollectionReportData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: selectedRsm == chartData.regionalManager
                    ? Colors.red
                    : const Color(0xFF2CA9DF),
                borderRadius: BorderRadius.zero,
                toY:
                    chartData.weekOneReceived +
                    chartData.weekTwoReceived +
                    chartData.weekThreeReceived +
                    chartData.weekFourReceived,
                width: 15,
              ),
              BarChartRodData(
                color: selectedRsm == chartData.regionalManager
                    ? Colors.red.shade300
                    : Colors.green,
                borderRadius: BorderRadius.zero,
                toY: chartData.targetMonth,
                width: 15,
              ),
              BarChartRodData(
                color: selectedRsm == chartData.regionalManager
                    ? Colors.red.shade100
                    : const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY:
                    chartData.weekOneCommitted +
                    chartData.weekTwoCommitted +
                    chartData.weekThreeCommitted +
                    chartData.weekFourCommitted,
                width: 15,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _monthlyCustomerAnalysisChartData(
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
                    chartData.weekFourReceived,
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
                    chartData.weekFourCommitted,
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

  bool isCurrentMonth(DateTime date) {
    final now = DateTime.now();

    return now.month == date.month && now.year == date.year;
  }

  DateTime getMonthStartDate(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  DateTime getMonthEndDate(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  Future<void> removeFilter() async {
    clearVariables();
    LoadDates();
    loadData("");
    setState(() {
      chartDataLoadedMonthlyCollection = true;
    });
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
      asmData = MonthlyCollectionReportList(weeklyData: []);
      rsmData = MonthlyCollectionReportList(weeklyData: []);
      tsmData = MonthlyCollectionReportList(weeklyData: []);
    });
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
        if (maxValue >= 200000 && maxValue < 300000) {
          divVal = 20000;
        } else if (maxValue >= 300000 && maxValue < 400000) {
          divVal = 30000;
        } else if (maxValue >= 400000 && maxValue < 500000) {
          divVal = 40000;
        } else if (maxValue >= 500000) {
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
    _horizontalCustomerController.dispose();
    _horizontalRsmController.dispose();
    _mainScrollController.dispose();
    _horizontalAsmController.dispose();
    _horizontalTsmController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return chartDataLoadedMonthlyCollection == true
        ? Scrollbar(
            thumbVisibility: true,
            controller: _mainScrollController,
            child: SingleChildScrollView(
              controller: _mainScrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isCurrentMonth(selectedMonth)
                                ? "${formatDateString(getMonthStartDate(selectedMonth))} - ${formatDateString(DateTime.now())}"
                                : "${formatDateString(getMonthStartDate(selectedMonth))} - ${formatDateString(getMonthEndDate(selectedMonth))}",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            final picked = await showMonthPicker(
                              context: context,
                              initialDate: selectedMonth,
                              firstDate: DateTime(2023),
                              lastDate: DateTime.now(),
                            );

                            if (picked != null) {
                              selectedMonth = picked;

                              fromDateFilter = getMonthStartDate(selectedMonth);

                              toDateFilter = isCurrentMonth(selectedMonth)
                                  ? DateTime.now()
                                  : getMonthEndDate(selectedMonth);

                              dateFilterFlag = true;

                              clearVariables();

                              setState(() {});

                              await loadData("");
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, size: 18),

                                const SizedBox(width: 8),

                                Text(
                                  DateFormat('MMM yyyy').format(selectedMonth),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "RSM Analysis",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                PopupMenuButton(
                                  padding: EdgeInsets.zero,
                                  itemBuilder: (BuildContext bc) {
                                    return [
                                      PopupMenuItem(
                                        onTap: () {
                                          generateRsmMonthlyCollectionExcel();
                                        },
                                        child: const Text("Download Excel"),
                                      ),
                                    ];
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            _monthlyRsmAnalysis(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "ASM Analysis",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                PopupMenuButton(
                                  padding: EdgeInsets.zero,
                                  itemBuilder: (BuildContext bc) {
                                    return [
                                      PopupMenuItem(
                                        onTap: () {
                                          generateAsmMonthlyCollectionExcel();
                                        },
                                        child: const Text("Download Excel"),
                                      ),
                                    ];
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            _monthlyAsmAnalysis(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "TSM Analysis",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                PopupMenuButton(
                                  padding: EdgeInsets.zero,
                                  itemBuilder: (BuildContext bc) {
                                    return [
                                      PopupMenuItem(
                                        onTap: () {
                                          generateTsmMonthlyCollectionExcel();
                                        },
                                        child: const Text("Download Excel"),
                                      ),
                                    ];
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            _monthlyTsmAnalysis(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Customer Analysis",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                PopupMenuButton(
                                  padding: EdgeInsets.zero,
                                  itemBuilder: (BuildContext bc) {
                                    return [
                                      PopupMenuItem(
                                        onTap: () {
                                          generateCustomerMonthlyCollectionExcel();
                                        },
                                        child: const Text("Download Excel"),
                                      ),
                                    ];
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            _monthlyCustomerAnalysis(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  Widget _monthlyTsmAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = tsmData.weeklyData.length;
    final isWebWide = screenWidth > 900;

    final double minBarWidth = isWebWide ? 90 : 70;
    final double horizontalPadding = isWebWide ? 120 : 40;

    chartWidth = math.max(screenWidth, (len * minBarWidth) + horizontalPadding);
    double maxAmount = len > 0
        ? tsmData.weeklyData
              .map((data) => (data.targetMonth))
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          final newOffset =
              _horizontalTsmController.offset + pointerSignal.scrollDelta.dy;

          if (_horizontalTsmController.hasClients) {
            _horizontalTsmController.jumpTo(
              newOffset.clamp(
                0,
                _horizontalTsmController.position.maxScrollExtent,
              ),
            );
          }
        }
      },
      child: Scrollbar(
        thumbVisibility: true,
        controller: _horizontalTsmController,
        child: SingleChildScrollView(
          controller: _horizontalTsmController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            height: screenWidth > 1200
                ? 520
                : screenWidth > 800
                ? 420
                : 350,
            width: chartWidth,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: BarChart(
                BarChartData(
                  groupsSpace: screenWidth > 1000 ? 28 : 16,
                  maxY: getMaxValue(maxAmount),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: _leftTitles,
                      axisNameSize: 14,
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
                    bottomTitles: AxisTitles(
                      sideTitles: _bottomTitlesTsmAnalysis,
                      axisNameSize: 20,
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    checkToShowHorizontalLine: (value) => value % 10 == 0,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade400.withValues(alpha: 0.5),
                      strokeWidth: 1.2,
                    ),
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade400,
                        width: 0.7,
                      ),
                      top: BorderSide(color: Colors.grey.shade400, width: 0.7),
                    ),
                  ),
                  barGroups: _monthlyTsmAnalysisChartData(tsmData.weeklyData),
                  barTouchData: BarTouchData(
                    allowTouchBarBackDraw: true,
                    touchCallback: (FlTouchEvent event, barTouchResponse) {
                      if (event is! FlTapUpEvent) return;

                      final spot = barTouchResponse?.spot;

                      if (spot == null) return;

                      final touchedTsm = tsmData
                          .weeklyData[spot.touchedBarGroupIndex]
                          .salesPerson;

                      setState(() {
                        if (selectedTsm == touchedTsm) {
                          selectedTsm = null;
                        } else {
                          selectedTsm = touchedTsm;
                        }

                        applyChartFilters();
                      });
                    },
                    touchTooltipData: BarTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      tooltipPadding: const EdgeInsets.all(12),
                      maxContentWidth: 200,
                      tooltipBorder: const BorderSide(
                        width: 2.0,
                        color: Colors.black12,
                        style: BorderStyle.none,
                      ),
                      getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                        return BarTooltipItem(
                          '${tsmData.weeklyData[grpIndex].salesPerson}-'
                          '${getMonthName(DateTime.now().month)}\n',
                          const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text:
                                  'Monthly Received: ${formatAmount(tsmData.weeklyData[grpIndex].weekOneReceived + tsmData.weeklyData[grpIndex].weekTwoReceived + tsmData.weeklyData[grpIndex].weekThreeReceived + tsmData.weeklyData[grpIndex].weekFourReceived)}\n',
                              style: const TextStyle(
                                color: Color(0xFF2CA9DF),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Monthly Committed: ${formatAmount(tsmData.weeklyData[grpIndex].weekOneCommitted + tsmData.weeklyData[grpIndex].weekTwoCommitted + tsmData.weeklyData[grpIndex].weekThreeCommitted + tsmData.weeklyData[grpIndex].weekFourCommitted)}\n',
                              style: const TextStyle(
                                color: Color(0xFFFF9F47),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Target: ${formatAmount(tsmData.weeklyData[grpIndex].targetMonth)}',
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
                    ),
                    handleBuiltInTouches: true,
                    touchExtraThreshold: const EdgeInsets.all(10),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _monthlyAsmAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = asmData.weeklyData.length;
    final isWebWide = screenWidth > 900;

    final double minBarWidth = isWebWide ? 90 : 70;
    final double horizontalPadding = isWebWide ? 120 : 40;

    chartWidth = math.max(screenWidth, (len * minBarWidth) + horizontalPadding);
    double maxAmount = len > 0
        ? asmData.weeklyData
              .map((data) => (data.targetMonth))
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          final newOffset =
              _horizontalAsmController.offset + pointerSignal.scrollDelta.dy;

          if (_horizontalAsmController.hasClients) {
            _horizontalAsmController.jumpTo(
              newOffset.clamp(
                0,
                _horizontalAsmController.position.maxScrollExtent,
              ),
            );
          }
        }
      },
      child: Scrollbar(
        thumbVisibility: true,
        controller: _horizontalAsmController,
        child: SingleChildScrollView(
          controller: _horizontalAsmController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            height: screenWidth > 1200
                ? 520
                : screenWidth > 800
                ? 420
                : 350,
            width: chartWidth,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: BarChart(
                BarChartData(
                  groupsSpace: screenWidth > 1000 ? 28 : 16,
                  maxY: getMaxValue(maxAmount),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: _leftTitles,
                      axisNameSize: 14,
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
                    bottomTitles: AxisTitles(
                      sideTitles: _bottomTitlesAsmAnalysis,
                      axisNameSize: 20,
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    checkToShowHorizontalLine: (value) => value % 10 == 0,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade400.withValues(alpha: 0.5),
                      strokeWidth: 1.2,
                    ),
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade400,
                        width: 0.7,
                      ),
                      top: BorderSide(color: Colors.grey.shade400, width: 0.7),
                    ),
                  ),
                  barGroups: _monthlyAsmAnalysisChartData(asmData.weeklyData),
                  barTouchData: BarTouchData(
                    allowTouchBarBackDraw: true,
                    touchCallback: (FlTouchEvent event, barTouchResponse) {
                      if (event is! FlTapUpEvent) return;

                      final spot = barTouchResponse?.spot;

                      if (spot == null) return;

                      final touchedAsm = asmData
                          .weeklyData[spot.touchedBarGroupIndex]
                          .salesManager;

                      setState(() {
                        if (selectedAsm == touchedAsm) {
                          selectedAsm = null;
                        } else {
                          selectedAsm = touchedAsm;
                        }

                        applyChartFilters();
                      });
                    },
                    touchTooltipData: BarTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      tooltipPadding: const EdgeInsets.all(12),
                      maxContentWidth: 200,
                      tooltipBorder: const BorderSide(
                        width: 2.0,
                        color: Colors.black12,
                        style: BorderStyle.none,
                      ),
                      getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                        return BarTooltipItem(
                          '${asmData.weeklyData[grpIndex].salesManager}-'
                          '${getMonthName(DateTime.now().month)}\n',
                          const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text:
                                  'Monthly Received: ${formatAmount(asmData.weeklyData[grpIndex].weekOneReceived + asmData.weeklyData[grpIndex].weekTwoReceived + asmData.weeklyData[grpIndex].weekThreeReceived + asmData.weeklyData[grpIndex].weekFourReceived)}\n',
                              style: const TextStyle(
                                color: Color(0xFF2CA9DF),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Monthly Committed: ${formatAmount(asmData.weeklyData[grpIndex].weekOneCommitted + asmData.weeklyData[grpIndex].weekTwoCommitted + asmData.weeklyData[grpIndex].weekThreeCommitted + asmData.weeklyData[grpIndex].weekFourCommitted)}\n',
                              style: const TextStyle(
                                color: Color(0xFFFF9F47),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Target: ${formatAmount(asmData.weeklyData[grpIndex].targetMonth)}',
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
                    ),
                    handleBuiltInTouches: true,
                    touchExtraThreshold: const EdgeInsets.all(10),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _monthlyRsmAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = rsmData.weeklyData.length;
    final isWebWide = screenWidth > 900;

    final double minBarWidth = isWebWide ? 90 : 70;
    final double horizontalPadding = isWebWide ? 120 : 40;

    chartWidth = math.max(screenWidth, (len * minBarWidth) + horizontalPadding);
    double maxAmount = len > 0
        ? rsmData.weeklyData
              .map((data) => (data.targetMonth))
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          final newOffset =
              _horizontalRsmController.offset + pointerSignal.scrollDelta.dy;

          if (_horizontalRsmController.hasClients) {
            _horizontalRsmController.jumpTo(
              newOffset.clamp(
                0,
                _horizontalRsmController.position.maxScrollExtent,
              ),
            );
          }
        }
      },
      child: Scrollbar(
        thumbVisibility: true,
        controller: _horizontalRsmController,
        child: SingleChildScrollView(
          controller: _horizontalRsmController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            height: screenWidth > 1200
                ? 520
                : screenWidth > 800
                ? 420
                : 350,
            width: chartWidth,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: BarChart(
                BarChartData(
                  groupsSpace: screenWidth > 1000 ? 28 : 16,
                  maxY: getMaxValue(maxAmount),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: _leftTitles,
                      axisNameSize: 14,
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
                    bottomTitles: AxisTitles(
                      sideTitles: _bottomTitlesRsmAnalysis,
                      axisNameSize: 20,
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    checkToShowHorizontalLine: (value) => value % 10 == 0,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade400.withValues(alpha: 0.5),
                      strokeWidth: 1.2,
                    ),
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade400,
                        width: 0.7,
                      ),
                      top: BorderSide(color: Colors.grey.shade400, width: 0.7),
                    ),
                  ),
                  barGroups: _monthlyRsmAnalysisChartData(rsmData.weeklyData),
                  barTouchData: BarTouchData(
                    allowTouchBarBackDraw: true,
                    touchCallback: (FlTouchEvent event, barTouchResponse) {
                      if (event is! FlTapUpEvent) return;

                      final spot = barTouchResponse?.spot;

                      if (spot == null) return;

                      final touchedRsm = rsmData
                          .weeklyData[spot.touchedBarGroupIndex]
                          .regionalManager;

                      setState(() {
                        if (selectedRsm == touchedRsm) {
                          selectedRsm = null;
                        } else {
                          selectedRsm = touchedRsm;
                        }

                        applyChartFilters();
                      });
                    },
                    touchTooltipData: BarTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      tooltipPadding: const EdgeInsets.all(12),
                      maxContentWidth: 200,
                      tooltipBorder: const BorderSide(
                        width: 2.0,
                        color: Colors.black12,
                        style: BorderStyle.none,
                      ),
                      getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                        return BarTooltipItem(
                          '${rsmData.weeklyData[grpIndex].regionalManager}-'
                          '${getMonthName(DateTime.now().month)}\n',
                          const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text:
                                  'Monthly Received: ${formatAmount(rsmData.weeklyData[grpIndex].weekOneReceived + rsmData.weeklyData[grpIndex].weekTwoReceived + rsmData.weeklyData[grpIndex].weekThreeReceived + rsmData.weeklyData[grpIndex].weekFourReceived)}\n',
                              style: const TextStyle(
                                color: Color(0xFF2CA9DF),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Monthly Committed: ${formatAmount(rsmData.weeklyData[grpIndex].weekOneCommitted + rsmData.weeklyData[grpIndex].weekTwoCommitted + rsmData.weeklyData[grpIndex].weekThreeCommitted + rsmData.weeklyData[grpIndex].weekFourCommitted)}\n',
                              style: const TextStyle(
                                color: Color(0xFFFF9F47),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Target: ${formatAmount(rsmData.weeklyData[grpIndex].targetMonth)}',
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
                    ),
                    handleBuiltInTouches: true,
                    touchExtraThreshold: const EdgeInsets.all(10),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _monthlyCustomerAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = customerData.weeklyData.length;
    final isWebWide = screenWidth > 900;

    final double minBarWidth = isWebWide ? 90 : 70;
    final double horizontalPadding = isWebWide ? 120 : 40;

    chartWidth = math.max(screenWidth, (len * minBarWidth) + horizontalPadding);
    double maxAmount = len > 0
        ? customerData.weeklyData
              .map((data) => (data.targetMonth))
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          final newOffset =
              _horizontalCustomerController.offset +
              pointerSignal.scrollDelta.dy;

          if (_horizontalCustomerController.hasClients) {
            _horizontalCustomerController.jumpTo(
              newOffset.clamp(
                0,
                _horizontalCustomerController.position.maxScrollExtent,
              ),
            );
          }
        }
      },
      child: Scrollbar(
        thumbVisibility: true,
        controller: _horizontalCustomerController,
        child: SingleChildScrollView(
          controller: _horizontalCustomerController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            height: screenWidth > 1200
                ? 520
                : screenWidth > 800
                ? 420
                : 350,
            width: chartWidth,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: BarChart(
                BarChartData(
                  groupsSpace: screenWidth > 1000 ? 28 : 16,
                  maxY: getMaxValue(maxAmount),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: _leftTitles,
                      axisNameSize: 14,
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
                    bottomTitles: AxisTitles(
                      sideTitles: _bottomTitlesCustomerAnalysis,
                      axisNameSize: 20,
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    checkToShowHorizontalLine: (value) => value % 10 == 0,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade400.withValues(alpha: 0.5),
                      strokeWidth: 1.2,
                    ),
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade400,
                        width: 0.7,
                      ),
                      top: BorderSide(color: Colors.grey.shade400, width: 0.7),
                    ),
                  ),
                  barGroups: _monthlyCustomerAnalysisChartData(
                    customerData.weeklyData,
                  ),
                  barTouchData: BarTouchData(
                    allowTouchBarBackDraw: true,
                    touchCallback: (flTouchEvent, barTouchResponse) async {
                      if (barTouchResponse != null &&
                          barTouchResponse.spot != null) {}
                    },
                    touchTooltipData: BarTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      tooltipPadding: const EdgeInsets.all(12),
                      maxContentWidth: 200,
                      tooltipBorder: const BorderSide(
                        width: 2.0,
                        color: Colors.black12,
                        style: BorderStyle.none,
                      ),
                      getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                        return BarTooltipItem(
                          '${customerData.weeklyData[grpIndex].customerName}-'
                          '${getMonthName(DateTime.now().month)}\n',
                          const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text:
                                  'Monthly Received: ${formatAmount(customerData.weeklyData[grpIndex].weekOneReceived + rsmData.weeklyData[grpIndex].weekTwoReceived + rsmData.weeklyData[grpIndex].weekThreeReceived + rsmData.weeklyData[grpIndex].weekFourReceived)}\n',
                              style: const TextStyle(
                                color: Color(0xFF2CA9DF),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Monthly Committed: ${formatAmount(customerData.weeklyData[grpIndex].weekOneCommitted + rsmData.weeklyData[grpIndex].weekTwoCommitted + rsmData.weeklyData[grpIndex].weekThreeCommitted + rsmData.weeklyData[grpIndex].weekFourCommitted)}\n',
                              style: const TextStyle(
                                color: Color(0xFFFF9F47),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Target: ${formatAmount(customerData.weeklyData[grpIndex].targetMonth)}',
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
                    ),
                    handleBuiltInTouches: true,
                    touchExtraThreshold: const EdgeInsets.all(10),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
