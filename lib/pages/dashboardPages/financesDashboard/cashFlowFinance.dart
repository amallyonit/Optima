// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference
import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
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
import 'package:http/http.dart' as http;

import 'finance_chart_ui.dart';
import '../ReportService.dart';

final reportService = ReportService();

late Future<void> loadDataFuture;
List<Users> usersList = [];
List<Users> childUsers = [];
List<Map<String, dynamic>> userList = [];
bool noUserList = false;
String UserLevel = "0";
List<CollectionList> collection = [];
List<DebtorsAgingList> target = [];
List<CashFlowList> cashFlowList = [];
List<CashFlowList> cashFlowListTemp = [];

double Collections = 0;
String CollectionsStr = "";
String CollectionsGoalStr = "";
int CollectionPercentage = 0;
String CollectionPercentageStr = "";
String CurrentMonthCollectionsStr = "";
double CurrentMonthCollections = 0;
double CollectionGoal = 0;
double LastMonthCollections = 0;
String LastMonthCollectionsStr = "";
double LastMonthTarget = 0;
String LastMonthTargetStr = "";
int LastMonthPercentage = 0;
double CurrentQtrCollections = 0;
String CurrentQtrCollectionsStr = "";
double CurrentQtrTarget = 0;
String CurrentQtrTargetStr = "";
int CurrentQtrPercentage = 0;
double YtdCollections = 0;
String YtdCollectionsStr = "";
double YtdTarget = 0;
String YtdTargetStr = "";
int YtdPercentage = 0;
double CurrentMonthCollectionsPercentage = 0;
String CurrentMonthCollectionsPercentageStr = "";
String LastMonthPercentageStr = "";
String CurrentQtrPercentageStr = "";
String YtdPercentageStr = "";

double bankBalanceClosing = 0.0;
double bankBalanceOpening = 0.0;
String bankBalance = '';
String inflow = '';
String outflow = '';

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

String touchedDailyDate = "";
String touchedMonth = "";
int touchedMonthIndex = 0;
String touchedLedger = "";
double selectedChart = 0;

bool chartDataLoadedCashFlow = false;

MonthlyAnalysisCashFlowList monthlyAnalysisData = MonthlyAnalysisCashFlowList(
  monthData: [],
);
LedgerAnalysisCashFlowList ledgerAnalysisData = LedgerAnalysisCashFlowList(
  ledgerData: [],
);
DailyMovementCashFlowList dailyData = DailyMovementCashFlowList(dailyData: []);

List<String> selectedSalesData = [];

final List<String> categories = ['Bank Account', 'Loan Account', 'Date'];

List<List<String>> filterOptions = [listOfLedgers, listOfLoanAccounts, []];

Map<String, Map<String, bool>> allCategoriesState = {};

List<List<bool>> selectedFinanceReceivablesOptions = [];

List<List<bool>> savedFinanceReceivablesOptions = filterOptions
    .map((options) => List<bool>.filled(options.length, false))
    .toList();

List<CashFlowList> targetListTemp = cashFlowList;

List<String> listOfLedgers = [];
List<String> listOfLoanAccounts = [];

List<List<bool>> savedFinanceReceivablesOptionsTemp = [];

bool fromFilter = false;

DateTime? fromDateFilter;
DateTime? toDateFilter;
bool dateFilterFlag = false;

class CashFlowFinance extends StatefulWidget {
  const CashFlowFinance({super.key});

  @override
  State<CashFlowFinance> createState() => _CashFlowFinanceState();
}

class FinanceCashFlowBIProvider with ChangeNotifier {
  List<CashFlowList> _targetList = [];
  List<CashFlowList> get targetList => _targetList;
  void updateTargetList(List<CashFlowList> newTargetList) {
    _targetList = newTargetList;
    notifyListeners();
  }
}

class _CashFlowFinanceState extends State<CashFlowFinance> {
  bool showDrillDownChart = false;
  int touchedIndex = -1;

  Color getCategoryColor(int categoryId) {
    switch (categoryId) {
      case 0:
        return const Color(0xFF97D7F3);
      case 1:
        return const Color(0xFFF49136);
      case 2:
        return const Color(0xFF6CCC3F);
      default:
        return const Color(0xFF6CCC3F);
    }
  }

  DateTime addMonth(DateTime date, int addMonth) {
    int currentMonth = date.month;
    int currentYear = date.year;
    int nextMonth = currentMonth + addMonth;
    int nextYear = currentYear;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }

    int lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
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

  String getMonthName(int month) {
    final formatter = DateFormat('MMMM');
    return formatter.format(DateTime(2000, month));
  }

  SideTitles get _bottomTitlesDailyMovement => SideTitles(
    reservedSize: 40,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<DailyMovementCashFlowData> mData = dailyData.dailyData;
      text = mData.elementAt(value.toInt()).date;
      return Padding(
        padding: const EdgeInsets.only(top: 13.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesMonthlyAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<MonthlyAnalysisCashFlowData> mData = monthlyAnalysisData.monthData;
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

  SideTitles get _bottomTitlesLedgerAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<LedgerAnalysisCashFlowData> mData = ledgerAnalysisData.ledgerData;
      text = mData.elementAt(value.toInt()).ledgerName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(
            '${text.length > 5 ? text.substring(0, 5) : text}...',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
    },
  );

  List<BarChartGroupData> _dailyMovementChartData(
    List<DailyMovementCashFlowData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.sumOfCr,
                width: 20,
              ),
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.sumOfDr,
                width: 20,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _monthlyAnalysisChartData(
    List<MonthlyAnalysisCashFlowData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.sumOfCr,
                width: 20,
              ),
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.sumOfDr,
                width: 20,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _ledgerWiseAnalysisChartData(
    List<LedgerAnalysisCashFlowData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.sumOfCr!,
                width: 20,
              ),
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.sumOfDr!,
                width: 20,
              ),
            ],
          ),
        )
        .toList();
  }

  Future<void> _loadCashFlowList(
    String userName,
    String userLevel,
    String daily,
    String ledgerData,
    bool fromFilter,
  ) async {
    int index = 0;
    const int limit = 10000;
    int fetchedCount = 0;
    List<CashFlowList> cashFlow = [];
    int monthIndex = currentDate!.month;
    DateTime startDate = monthIndex == 4
        ? lastMonthFromDate!
        : fiscalYearStartDate!;
    DateTime endDate = currentDate!;
    bankBalanceClosing = 0;
    try {
      final body = {
        "FromDate": dateFilterFlag
            ? formatDate(fromDateFilter!)
            : formatDate(startDate),
        "ToDate": dateFilterFlag
            ? formatDate(toDateFilter!)
            : formatDate(endDate),
        "Limit": limit.toString(),
        "sapToken": DataManager.readSapToken(),
      };

      const apiUrl = '${ApiHelper.baseUrl}BicxoCashflowList';
      final headers = {HttpHeaders.contentTypeHeader: 'application/json'};

      do {
        body["Index"] = index.toString(); // update the current index
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: headers,
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<CashFlowList> newList = (responseJson['responseData'] as List)
                .map((item) {
                  final obj = CashFlowList.fromJson(item);
                  final postingDate = DateFormat(
                    'dd/MM/yyyy',
                  ).parse(obj.postingDate);
                  obj.postingDateParsed = postingDate;
                  return obj;
                })
                .toList();

            cashFlow.addAll(newList);
            fetchedCount = newList.length;
            index++;
          } else {
            fetchedCount = 0; // stop fetching if no more data
          }
        } else {
          fetchedCount = 0; // stop if response is not successful
        }
      } while (fetchedCount == limit);

      double sumOfCredit = 0, sumOfDebit = 0;

      var todayTarget = cashFlow.where((target) {
        DateTime dueOn = target.postingDateParsed;
        return dueOn.isAtLeast(fiscalYearStartDate!) &&
            dueOn.isAtMost(currentDate!);
      });

      for (var target in todayTarget) {
        sumOfCredit += double.tryParse(target.creditAmount) ?? 0;
        sumOfDebit += double.tryParse(target.debitAmount) ?? 0;
      }

      setState(() {
        inflow = formatAmount(sumOfDebit);
        outflow = formatAmount(sumOfCredit);

        cashFlowList = cashFlow;
        cashFlowListTemp = cashFlow;

        List<String> trueCategoryOptions =
            (allCategoriesState['Bank Account'] ?? {}).entries
                .where((entry) => entry.value)
                .map((entry) => entry.key)
                .toList();

        List<String> trueLoanOptions =
            (allCategoriesState['Loan Account'] ?? {}).entries
                .where((entry) => entry.value)
                .map((entry) => entry.key)
                .toList();

        List<CashFlowList> filteredList = [];

        if (trueCategoryOptions.isNotEmpty) {
          filteredList = cashFlowList
              .where(
                (person) => trueCategoryOptions.contains(person.accountName),
              )
              .toList();
          cashFlowList = filteredList;
        }

        if (trueLoanOptions.isNotEmpty) {
          filteredList = cashFlowList
              .where((person) => trueLoanOptions.contains(person.accountName))
              .toList();
          cashFlowList = filteredList;
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

  Future<void> _loadLedgerWiseAnalysis(
    String touchedDailyDate,
    String monthIndex,
    String selectedAccountName,
  ) async {
    bankBalanceClosing = 0;
    bankBalanceOpening = 0;
    var groupedByAccount = <String, List<CashFlowList>>{};
    List<LedgerAnalysisCashFlowData> ledgerAnalysisCashFlowDataList = [];

    DateTimeRange range;
    if (touchedDailyDate.isNotEmpty) {
      final parts = touchedDailyDate.split('/');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = DateTime.now().year;
      final single = DateTime(year, month, day);
      range = DateTimeRange(start: single, end: single);
    } else if (monthIndex.isNotEmpty) {
      final month = int.parse(monthIndex);
      final year = DateTime.now().year;
      final start = DateTime(year, month, 1);
      final end = DateTime(
        year,
        month + 1,
        1,
      ).subtract(const Duration(days: 1));
      range = DateTimeRange(start: start, end: end);
    } else {
      range = DateTimeRange(start: fiscalYearStartDate!, end: currentDate!);
    }

    var targets = cashFlowList.where((cf) {
      final dt = cf.postingDateParsed;
      return !dt.isBefore(range.start) && !dt.isAfter(range.end);
    });

    if (selectedAccountName.isNotEmpty) {
      targets = targets.where((cf) => cf.accountName == selectedAccountName);
    }

    for (var cf in targets) {
      groupedByAccount.putIfAbsent(cf.accountName, () => []).add(cf);
    }

    double runningOpening = 0;
    double runningClosing = 0;

    groupedByAccount.forEach((account, flows) {
      flows.sort((a, b) => a.postingDateParsed.compareTo(b.postingDateParsed));

      double sumCr = 0;
      double sumDr = 0;
      for (var item in flows) {
        sumCr += double.tryParse(item.creditAmount) ?? 0;
        sumDr += double.tryParse(item.debitAmount) ?? 0;
      }
      final opening = double.tryParse(flows.first.obBalance) ?? 0;
      final closing = double.tryParse(flows.last.clBalance) ?? 0;

      if (account.isNotEmpty) {
        ledgerAnalysisCashFlowDataList.add(
          LedgerAnalysisCashFlowData(
            ledgerName: account,
            ledgerType: flows.last.category,
            ledgerBalance: closing.abs(),
            sumOfCr: sumCr,
            sumOfDr: sumDr,
            openingBal: opening,
            closingBal: closing,
          ),
        );
      }

      runningOpening += opening;
      runningClosing += closing;
    });

    ledgerAnalysisCashFlowDataList.sort(
      (a, b) => b.sumOfCr!.compareTo(a.sumOfCr!),
    );

    if (mounted) {
      setState(() {
        bankBalanceOpening = runningOpening;
        bankBalanceClosing = runningClosing;
        bankBalance = formatAmount(runningClosing);
      });
    }

    ledgerAnalysisData = LedgerAnalysisCashFlowList(
      ledgerData: ledgerAnalysisCashFlowDataList,
    );

    if (listOfLedgers.isEmpty) {
      listOfLedgers = ledgerAnalysisData.ledgerData
          .where((d) => d.ledgerType == 'Bank Account')
          .map((d) => d.ledgerName)
          .toList();
      listOfLoanAccounts = ledgerAnalysisData.ledgerData
          .where((d) => d.ledgerType == 'Loan Account')
          .map((d) => d.ledgerName)
          .toList();
    }
  }

  Future<void> _loadDailyMovementBarChartData(
    int monthIndex,
    String daily,
    String ledgerData,
  ) async {
    List<DailyMovementCashFlowData> groupWiseDataList = [];
    int currentYear = DateTime.now().year;

    var todayTarget = cashFlowList.where((target) {
      DateTime dueOn = target.postingDateParsed;
      return dueOn.isAtLeast(
            dateFilterFlag ? fromDateFilter! : currentMonthFromDate!,
          ) &&
          dueOn.isAtMost(dateFilterFlag ? toDateFilter! : currentMonthToDate!);
    });

    todayTarget = filterCashFlowList(
      todayTarget.cast<CashFlowList>().toList(),
      dailyData: daily,
      ledgerData: ledgerData,
    );

    if (ledgerData.isNotEmpty) {
      todayTarget = todayTarget.where((t) => t.accountName == ledgerData);
    }

    if (monthIndex == 0) {
      todayTarget = cashFlowList.where((target) {
        DateTime dueOn = target.postingDateParsed;
        return dueOn.isAtLeast(
              dateFilterFlag ? fromDateFilter! : currentMonthFromDate!,
            ) &&
            dueOn.isAtMost(
              dateFilterFlag ? toDateFilter! : currentMonthToDate!,
            );
      });
      if (ledgerData.isNotEmpty) {
        todayTarget = todayTarget.where((t) => t.accountName == ledgerData);
      }
    } else if (monthIndex >= 4 && monthIndex <= 12) {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      todayTarget = cashFlowList.where((target) {
        DateTime dueOn = target.postingDateParsed;
        return dueOn.isAtLeast(monthDates['start']!) &&
            dueOn.isAtMost(monthDates['end']!);
      });
      if (ledgerData.isNotEmpty) {
        todayTarget = todayTarget.where((t) => t.accountName == ledgerData);
      }
    } else {
      DateTime startDate = DateTime(currentYear + 1, monthIndex, 1);
      DateTime endDate = DateTime(currentYear + 1, monthIndex + 1, 0);
      todayTarget = cashFlowList.where((target) {
        DateTime dueOn = target.postingDateParsed;
        return dueOn.isAtLeast(startDate) && dueOn.isAtMost(endDate);
      });
      if (ledgerData.isNotEmpty) {
        todayTarget = todayTarget.where((t) => t.accountName == ledgerData);
      }
    }

    Set<String> processedDates = {};
    for (var entry in todayTarget) {
      final dateKey = entry.postingDate;
      if (processedDates.contains(dateKey)) continue;

      double sumCr = 0, sumDr = 0;
      final uniqClosings = <double>{};
      final uniqOpenings = <double>{};

      for (var tx in todayTarget.where((e) => e.postingDate == dateKey)) {
        sumCr += double.tryParse(tx.creditAmount) ?? 0;
        sumDr += double.tryParse(tx.debitAmount) ?? 0;
        uniqClosings.add(double.tryParse(tx.clBalance) ?? 0);
        uniqOpenings.add(double.tryParse(tx.obBalance) ?? 0);
      }

      double totalClosing = uniqClosings.fold(0.0, (a, b) => a + b);
      double totalOpening = uniqOpenings.fold(0.0, (a, b) => a + b);

      if (sumCr == 0 && sumDr == 0 && totalClosing == 0 && totalOpening == 0) {
        processedDates.add(dateKey);
        continue;
      }

      groupWiseDataList.add(
        DailyMovementCashFlowData(
          date: dateKey.substring(0, 5),
          sumOfCr: sumCr.abs(),
          sumOfDr: sumDr.abs(),
          closingBalance: totalClosing,
          openingBalance: totalOpening,
        ),
      );

      processedDates.add(dateKey);
    }

    dailyData = DailyMovementCashFlowList(dailyData: groupWiseDataList);
  }

  Future<void> _loadMonthlySalesBarChartData(String ledgerData) async {
    List<MonthlyAnalysisCashFlowData> soDataList = [];

    DateTime startDate;
    DateTime endDate;

    for (int i = 4; i <= 15; i++) {
      String monthName = getMonthName(i);
      List<CashFlowList> monthlyCollectionList = [];

      if (i >= 4 && i <= 12) {
        Map<String, DateTime> monthDates = getMonthStartEndDates(i);
        monthlyCollectionList = cashFlowList.where((target) {
          DateTime d = target.postingDateParsed;
          return d.isAtLeast(monthDates['start']!) &&
              d.isAtMost(monthDates['end']!);
        }).toList();
      } else {
        int year = DateTime.now().month < 4
            ? DateTime.now().year
            : DateTime.now().year - 1;
        startDate = DateTime(year, i - 12, 1);
        endDate = DateTime(year, (i - 12) + 1, 0);
        monthlyCollectionList = cashFlowList.where((target) {
          DateTime d = target.postingDateParsed;
          return d.isAtLeast(startDate) && d.isAtMost(endDate);
        }).toList();
      }

      if (ledgerData.isNotEmpty) {
        monthlyCollectionList = monthlyCollectionList
            .where((t) => t.accountName == ledgerData)
            .toList();
      }

      double sumOfCredit = 0;
      double sumOfDebit = 0;
      double totalOpeningBalance = 0;
      double totalClosingBalance = 0;

      // Sum credits and debits
      for (var target in monthlyCollectionList) {
        sumOfCredit += double.tryParse(target.creditAmount) ?? 0;
        sumOfDebit += double.tryParse(target.debitAmount) ?? 0;
      }

      // Compute opening/closing balances per ledger
      final uniqueLedgers = monthlyCollectionList
          .map((e) => e.accountName)
          .toSet();

      for (var ledger in uniqueLedgers) {
        final entries =
            monthlyCollectionList.where((e) => e.accountName == ledger).toList()
              ..sort(
                (a, b) => a.postingDateParsed.compareTo(b.postingDateParsed),
              );

        if (entries.isNotEmpty) {
          totalOpeningBalance += double.tryParse(entries.first.obBalance) ?? 0;
          totalClosingBalance += double.tryParse(entries.last.clBalance) ?? 0;
        }
      }

      // Skip this month if all aggregates are zero
      if (sumOfCredit == 0 &&
          sumOfDebit == 0 &&
          totalOpeningBalance == 0 &&
          totalClosingBalance == 0) {
        continue;
      }

      soDataList.add(
        MonthlyAnalysisCashFlowData(
          openingBalance: totalOpeningBalance,
          closingBalance: totalClosingBalance,
          monthName: monthName,
          sumOfCr: sumOfCredit,
          sumOfDr: sumOfDebit,
        ),
      );
    }

    monthlyAnalysisData = MonthlyAnalysisCashFlowList(monthData: soDataList);
  }

  Future<void> loadData(String selectedUser) async {
    if (!mounted) return;
    setState(() {
      chartDataLoadedCashFlow = false;
    });
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    UserLevel = userLevel;
    await _loadCashFlowList(userName, userLevel, "", "", fromFilter);
    await Future.wait([
      _loadMonthlySalesBarChartData(""),
      _loadDailyMovementBarChartData(0, "", ""),
      _loadLedgerWiseAnalysis("", "", ""),
    ]);
    filterOptions = [listOfLedgers, listOfLoanAccounts];

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
    if (!mounted) return;
    setState(() {
      chartDataLoadedCashFlow = true;
    });
  }

  List<CashFlowList> filterCashFlowList(
    List<CashFlowList> cashFlowList, {
    String? dailyData,
    String? ledgerData,
  }) {
    List<CashFlowList> filteredCollectionTargetList = [];
    List<CashFlowList> cashFlowList = [];

    for (var target in cashFlowList) {
      if ((dailyData == null ||
              dailyData.isEmpty ||
              target.postingDate == dailyData) &&
          (ledgerData == null ||
              ledgerData.isEmpty ||
              target.accountName == ledgerData)) {
        filteredCollectionTargetList.add(target);
      }
    }
    return filteredCollectionTargetList;
  }

  Future<void> loadDataWithFilter(
    int monthIndex,
    String? dailyData,
    String? ledgerData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userLevel = prefs.getString('userLevel') ?? '';
    UserLevel = userLevel;
    clearVariablesForFilter();
    LoadDates();
    final monthParam = monthIndex == 0 ? "" : monthIndex.toString();
    await Future.wait([
      _loadMonthlySalesBarChartData(ledgerData!),
      _loadDailyMovementBarChartData(monthIndex, dailyData!, ledgerData),
      _loadLedgerWiseAnalysis(dailyData, monthParam, ledgerData),
    ]);
    chartDataLoadedCashFlow = true;
  }

  Future<void> removeFilter() async {
    setState(() {
      chartDataLoadedCashFlow = false;
    });
    clearVariables();
    LoadDates();
    allCategoriesState.forEach((category, options) {
      options.updateAll((key, value) => false);
    });
    loadDataFuture = loadData("");
  }

  void clearVariables() {
    setState(() {
      chartDataLoadedCashFlow = false;
      monthlyAnalysisData = MonthlyAnalysisCashFlowList(monthData: []);
      ledgerAnalysisData = LedgerAnalysisCashFlowList(ledgerData: []);
      dailyData = DailyMovementCashFlowList(dailyData: []);
      touchedDailyDate = "";
      touchedMonth = "";
      touchedLedger = "";
    });
  }

  void clearVariablesForFilter() {
    setState(() {
      chartDataLoadedCashFlow = false;
      monthlyAnalysisData = MonthlyAnalysisCashFlowList(monthData: []);
      ledgerAnalysisData = LedgerAnalysisCashFlowList(ledgerData: []);
      dailyData = DailyMovementCashFlowList(dailyData: []);
    });
  }

  void toggleCheckbox() {
    setState(() {
      bankBalanceClosing = 0;
      inflow = '';
      outflow = '';
      chartDataLoadedCashFlow = false;
      loadDataFuture = loadData("");
    });
  }

  Future<void> _dateFilterTarget() async {
    cashFlowList = cashFlowListTemp;

    setState(() {
      context.read<FinanceCashFlowBIProvider>().updateTargetList(cashFlowList);

      cashFlowList = cashFlowList.where((target) {
        DateTime dueon = target.postingDateParsed;
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();

      List<String> trueCategoryOptions =
          (allCategoriesState['Bank Account'] ?? {}).entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList();

      List<String> trueLoanOptions = (allCategoriesState['Loan Account'] ?? {})
          .entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      List<CashFlowList> filteredList = [];

      if (trueCategoryOptions.isNotEmpty) {
        filteredList = cashFlowList
            .where((person) => trueCategoryOptions.contains(person.accountName))
            .toList();
        cashFlowList = filteredList;
      }

      if (trueLoanOptions.isNotEmpty) {
        filteredList = cashFlowList
            .where((person) => trueLoanOptions.contains(person.accountName))
            .toList();
        cashFlowList = filteredList;
      }

      double sumOfCredit = 0, sumOfDebit = 0;

      var todayTarget = cashFlowList.where((target) {
        DateTime dueOn = target.postingDateParsed;
        return dueOn.isAtLeast(fiscalYearStartDate!) &&
            dueOn.isAtMost(currentDate!);
      });

      for (var target in todayTarget) {
        sumOfCredit += double.tryParse(target.creditAmount) ?? 0;
        sumOfDebit += double.tryParse(target.debitAmount) ?? 0;
      }

      inflow = formatAmount(sumOfDebit);
      outflow = formatAmount(sumOfCredit);
    });
  }

  Future<void> filterDateFunction() async {
    setState(() {
      chartDataLoadedCashFlow = false;
    });
    cashFlowList = cashFlowListTemp;
    _dateFilterTarget();
    await Future.wait([
      _loadMonthlySalesBarChartData(""),
      _loadDailyMovementBarChartData(0, "", ""),
      _loadLedgerWiseAnalysis("", "", ""),
    ]);
    setState(() {
      bankBalanceClosing = 0;
      inflow = '';
      outflow = '';

      filterOptions = [listOfLedgers, listOfLoanAccounts, []];

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

      double sumOfCredit = 0, sumOfDebit = 0;

      var todayTarget = cashFlowList.where((target) {
        DateTime dueOn = target.postingDateParsed;
        return dueOn.isAtLeast(fiscalYearStartDate!) &&
            dueOn.isAtMost(currentDate!);
      });

      for (var target in todayTarget) {
        sumOfCredit += double.tryParse(target.creditAmount) ?? 0;
        sumOfDebit += double.tryParse(target.debitAmount) ?? 0;
      }

      inflow = formatAmount(sumOfDebit);
      outflow = formatAmount(sumOfCredit);
    });
    setState(() {
      chartDataLoadedCashFlow = true;
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

  Future<void> generateDailyMovementExcel(
    DailyMovementCashFlowList list,
  ) async {
    await reportService.generateExcel(
      sheetName: 'CFSDailyMovement',
      headers: ['Date', 'Debit Total', 'Credit Total'],
      rows: list.dailyData.map((e) => [e.date, e.sumOfDr, e.sumOfCr]).toList(),
      fileName: 'CFS_Daily_Movement.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'CFS - Daily Movement',
    );
  }

  Future<void> generateDailyMovementPDF(DailyMovementCashFlowList list) async {
    await reportService.generatePDF(
      title: 'CFS Daily Movement',
      headers: ['Date', 'Debit Total', 'Credit Total'],
      rows: list.dailyData.map((e) => [e.date, e.sumOfDr, e.sumOfCr]).toList(),
      fileName: 'CFS_Daily_Movement.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateMonthlyAnalysisExcel(
    MonthlyAnalysisCashFlowList list,
  ) async {
    await reportService.generateExcel(
      sheetName: 'CFSMonthlyAnalysis',
      headers: ['Month', 'Debit Total', 'Credit Total'],
      rows: list.monthData
          .map((e) => [e.monthName, e.sumOfDr, e.sumOfCr])
          .toList(),
      fileName: 'CFS_Monthly_Analysis.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'CFS - Monthly Analysis',
    );
  }

  Future<void> generateMonthlyAnalysisPDF(
    MonthlyAnalysisCashFlowList list,
  ) async {
    await reportService.generatePDF(
      title: 'CFS Monthly Analysis',
      headers: ['Month', 'Debit Total', 'Credit Total'],
      rows: list.monthData
          .map((e) => [e.monthName, e.sumOfDr, e.sumOfCr])
          .toList(),
      fileName: 'CFS_Monthly_Analysis.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateLedgerWiseAnalysisExcel(
    LedgerAnalysisCashFlowList list,
  ) async {
    await reportService.generateExcel(
      sheetName: 'CFSLedgerAnalysis',
      headers: ['Operating Activities', 'Balance Amount'],
      rows: list.ledgerData
          .map((e) => [e.ledgerName, e.ledgerBalance])
          .toList(),
      fileName: 'CFS_Ledger_Analysis.xlsx',
      amountColumns: [2],
      addTotalRow: true,
      reportTitle: 'CFS - Ledger Analysis',
    );
  }

  Future<void> generateLedgerWiseAnalysisPDF(
    LedgerAnalysisCashFlowList list,
  ) async {
    await reportService.generatePDF(
      title: 'CFS Ledger Analysis',
      headers: ['Operating Activities', 'Balance Amount'],
      rows: list.ledgerData
          .map((e) => [e.ledgerName, e.ledgerBalance])
          .toList(),
      fileName: 'CFS_Ledger_Analysis.pdf',
      amountColumns: [2],
    );
  }

  String getSelectedFiltersText(
    Map<String, Map<String, bool>> allCategoriesState,
  ) {
    List<String> selectedFilters = [];
    allCategoriesState.forEach((category, options) {
      options.forEach((option, isSelected) {
        if (isSelected) {
          // If you want to include the category as well, you could do:
          // selectedFilters.add('$category: $option');
          selectedFilters.add(option);
        }
      });
    });
    return selectedFilters.join(', ');
  }

  String formatDateString(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
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

    filterOptions = [listOfLedgers, listOfLoanAccounts];

    selectedFinanceReceivablesOptions = filterOptions
        .map((options) => List<bool>.filled(options.length, false))
        .toList();

    toDateFilter = currentDate;
    fromDateFilter = fiscalYearStartDate;
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _dailyMovementHorizontalController.dispose();
    _monthlyAnalysisHorizontalController.dispose();
    _ledgerWiseHorizontalController.dispose();
    bankBalance = '';
    super.dispose();
  }

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _dailyMovementHorizontalController =
      ScrollController();
  final ScrollController _monthlyAnalysisHorizontalController =
      ScrollController();
  final ScrollController _ledgerWiseHorizontalController = ScrollController();

  @override
  Widget build(BuildContext context) {
    DateTime currentDate = DateTime.now();
    selectedFinanceReceivablesOptions = savedFinanceReceivablesOptions;
    return chartDataLoadedCashFlow == true
        ? FinanceVerticalScroll(
            controller: _verticalScrollController,
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
                                "${formatDateString(fiscalYearStartDate!)} - ${formatDateString(currentDate)}",
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
                Visibility(
                  visible: getSelectedFiltersText(allCategoriesState) != "",
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        "Selected Filters: ${getSelectedFiltersText(allCategoriesState)}",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          formatAmount(bankBalanceOpening),
                          style: const TextStyle(
                            fontSize: 20,
                            color: Color(0xFFF49136),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          "OP Bal",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8F8F8F),
                            fontWeight: FontWeight.w100,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          inflow,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Color(0xFFF49136),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          "Inflow",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8F8F8F),
                            fontWeight: FontWeight.w100,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          outflow,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Color(0xFFF49136),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          "Outflow",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8F8F8F),
                            fontWeight: FontWeight.w100,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          bankBalance,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Color(0xFFF49136),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          "CL Bal",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8F8F8F),
                            fontWeight: FontWeight.w100,
                          ),
                        ),
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
                          "Daily Movement",
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
                          color: const Color(0xFFFF9F47),
                        ),
                        const SizedBox(width: 5),
                        const Text("Sum of Cr", style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFF97D7F3),
                        ),
                        const SizedBox(width: 5),
                        const Text("Sum of Dr", style: TextStyle(fontSize: 12)),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateDailyMovementExcel(dailyData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateDailyMovementPDF(dailyData);
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
                  child: FinanceChartCard(child: _dailyMovement()),
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
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFFFF9F47),
                        ),
                        const SizedBox(width: 5),
                        const Text("Sum of Cr", style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFF97D7F3),
                        ),
                        const SizedBox(width: 5),
                        const Text("Sum of Dr", style: TextStyle(fontSize: 12)),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateMonthlyAnalysisExcel(
                                      monthlyAnalysisData,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateMonthlyAnalysisPDF(
                                      monthlyAnalysisData,
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
                  child: FinanceChartCard(child: _monthlyAnalysis()),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Ledger-wise\nAnalysis",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFFFF9F47),
                        ),
                        const SizedBox(width: 5),
                        const Text("Sum of Cr", style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFF97D7F3),
                        ),
                        const SizedBox(width: 5),
                        const Text("Sum of Dr", style: TextStyle(fontSize: 12)),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateLedgerWiseAnalysisExcel(
                                      ledgerAnalysisData,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateLedgerWiseAnalysisPDF(
                                      ledgerAnalysisData,
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
                  child: FinanceChartCard(child: _ledgerWiseAnalysis()),
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

  Widget _dailyMovement() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = dailyData.dailyData.length;
    chartWidth = screenWidth + (55 * len);
    if (len > 5) {
    } else {
      chartWidth = screenWidth;
    }

    double maxAmount = len > 0
        ? dailyData.dailyData
              .map((data) => data.sumOfDr)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return FinanceHorizontalChartScroll(
      controller: _dailyMovementHorizontalController,
      verticalController: _verticalScrollController,
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
                sideTitles: _bottomTitlesDailyMovement,
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
            barGroups: _dailyMovementChartData(dailyData.dailyData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedDailyDate = touchedDailyDate == ""
                          ? dailyData
                                .dailyData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .date
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedDailyDate,
                        touchedLedger,
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
                    '${dailyData.dailyData[grpIndex].date}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            'Opening Balance : ${formatAmount(dailyData.dailyData[grpIndex].openingBalance)}\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Closing Balance : ${formatAmount(dailyData.dailyData[grpIndex].closingBalance)}\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Sum of Cr : ${formatAmount(dailyData.dailyData[grpIndex].sumOfCr)}\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Sum of Dr : ${formatAmount(dailyData.dailyData[grpIndex].sumOfDr)}\n',
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

  Widget _monthlyAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = monthlyAnalysisData.monthData.length;
    if (len > 5) {
      chartWidth = screenWidth + (35 * len);
    } else {
      chartWidth = screenWidth;
    }

    double maxAmount = len > 0
        ? monthlyAnalysisData.monthData
              .map((data) => data.sumOfDr)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return FinanceHorizontalChartScroll(
      controller: _monthlyAnalysisHorizontalController,
      verticalController: _verticalScrollController,
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
                      if (touchedMonth == "") {
                        touchedMonthIndex = 0;
                      } else {
                        touchedMonthIndex =
                            months.indexOf(touchedMonth.substring(0, 3)) + 1;
                      }
                      touchedDailyDate = "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;

                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedDailyDate,
                        touchedLedger,
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
                    '${monthlyAnalysisData.monthData[grpIndex].monthName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            'Opening Balance: ${formatAmount(monthlyAnalysisData.monthData[grpIndex].openingBalance)}\n',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Closing Balance: ${formatAmount(monthlyAnalysisData.monthData[grpIndex].closingBalance)}\n',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Sum of Cr: ${formatAmount(monthlyAnalysisData.monthData[grpIndex].sumOfCr)}\n',
                        style: const TextStyle(
                          color: Color(0xFFFF9F47), //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Sum of Dr : ${formatAmount(monthlyAnalysisData.monthData[grpIndex].sumOfDr)}\n',
                        style: const TextStyle(
                          color: Color(0xFF97D7F3), //widget.touchedBarColor,
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

  Widget _ledgerWiseAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = ledgerAnalysisData.ledgerData.length;
    if (ledgerAnalysisData.ledgerData.length > 5) {
      chartWidth = screenWidth + (35 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? ledgerAnalysisData.ledgerData
              .map((data) => data.sumOfDr ?? 0)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return FinanceHorizontalChartScroll(
      controller: _ledgerWiseHorizontalController,
      verticalController: _verticalScrollController,
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
                sideTitles: _bottomTitlesLedgerAnalysis,
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
            barGroups: _ledgerWiseAnalysisChartData(
              ledgerAnalysisData.ledgerData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedLedger = touchedLedger == ""
                          ? ledgerAnalysisData
                                .ledgerData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .ledgerName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonthIndex,
                        touchedDailyDate,
                        touchedLedger,
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
                    '${ledgerAnalysisData.ledgerData[grpIndex].ledgerName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            'Opening Balance: ${formatAmount(ledgerAnalysisData.ledgerData[grpIndex].openingBal!)}\n',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Closing Balance: ${formatAmount(ledgerAnalysisData.ledgerData[grpIndex].closingBal!)}\n',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Sum of Cr: ${formatAmount(ledgerAnalysisData.ledgerData[grpIndex].sumOfCr!)}\n',
                        style: const TextStyle(
                          color: Color(0xFFFF9F47), //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Sum of Dr : ${formatAmount(ledgerAnalysisData.ledgerData[grpIndex].sumOfDr!)}\n',
                        style: const TextStyle(
                          color: Color(0xFF97D7F3), //widget.touchedBarColor,
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
                        'Filter Options - Cash Flow',
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
                                              setState(() {
                                                if (value == true) {
                                                  selectedFinanceReceivablesOptions[selectedCategoryIndex][index] =
                                                      true;
                                                } else {
                                                  selectedFinanceReceivablesOptions[selectedCategoryIndex][index] =
                                                      false;
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
                                      List<List<String>> filterOptions = [
                                        listOfLedgers,
                                        listOfLoanAccounts,
                                        [],
                                      ];
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
                                      Navigator.pop(context);

                                      for (
                                        int catIndex = 0;
                                        catIndex < categories.length;
                                        catIndex++
                                      ) {
                                        String categoryName =
                                            categories[catIndex];
                                        Map<String, bool> optionsState = {};

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

                                      selectedSalesData = selectedFilterOptions;

                                      savedFinanceReceivablesOptionsTemp =
                                          savedFinanceReceivablesOptions;

                                      fromFilter = true;

                                      // toggleCheckbox();
                                      loadDataFuture = filterDateFunction();
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
                                      chartDataLoadedCashFlow = false;
                                      fromFilter = false;
                                      savedFinanceReceivablesOptionsTemp
                                          .clear();
                                      setState(() {
                                        chartDataLoadedCashFlow = false;
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
