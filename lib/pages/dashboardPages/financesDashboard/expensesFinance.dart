// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference
import 'package:optima/excel_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:http/http.dart' as http;
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/classes/leads.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;
import '../../../api_helper.dart';

import 'package:optima/pages/dashboardPages/excel_helper_web.dart';
import 'package:optima/pages/dashboardPages/pdf_helper_web.dart';

class ExpensesFinance extends StatefulWidget {
  const ExpensesFinance({super.key});

  @override
  State<ExpensesFinance> createState() => _ExpensesFinanceState();
}

late Future<void> loadDataFuture;
List<Users> usersList = [];
List<Users> childUsers = [];
List<Map<String, dynamic>> userList = [];
bool noUserList = false;
String UserLevel = "0";
bool chartDataLoadedExpenses = false;

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

List<ExpensesList> expensesList = [];
List<ExpensesList> expensesListTemp = [];
GroupWiseAnalysisExpensesList groupList = GroupWiseAnalysisExpensesList(
  groupData: [],
);
SubGroupWiseAnalysisExpensesList subGroupList =
    SubGroupWiseAnalysisExpensesList(subGroupData: []);
DailyAnalysisExpensesList dailyData = DailyAnalysisExpensesList(dailyData: []);

String touchedSubGroup = "";
String touchedGroup = "";

String touchedMonth = "";
int touchedMonthIndex = 0;
double selectedChart = 0;

String fromDateForFilter = '';
String toDateForFilter = '';

DateTime? fromDateFilter;
DateTime? toDateFilter;
bool dateFilterFlag = false;

class FinanceExpensesBIProvider with ChangeNotifier {
  List<ExpensesList> _collectionList = [];
  List<ExpensesList> get collectionList => _collectionList;
  void updateCollectionList(List<ExpensesList> newCollectionList) {
    _collectionList = newCollectionList;
    notifyListeners();
  }
}

class _ExpensesFinanceState extends State<ExpensesFinance> {
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  int touchedIndex = -1;
  bool showDrillDownChart = false;

  double roundUpTo50Lakhs(double value) {
    const step = 5000000; // 50 lakhs
    return (value / step).ceil() * step.toDouble();
  }

  double roundDownTo50Lakhs(double value) {
    const step = 5000000;
    return (value / step).floor() * step.toDouble();
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
    toDateFilter = currentDate;
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

  String formatAmount(double amount) {
    bool isNegative = amount < 0;

    double positiveAmount = amount.abs();

    if (positiveAmount >= 10000000) {
      String formattedAmount =
          '${(positiveAmount / 10000000).toStringAsFixed(2)} Cr';
      return isNegative ? '-$formattedAmount' : formattedAmount;
    } else if (positiveAmount >= 100000) {
      String formattedAmount =
          '${(positiveAmount / 100000).toStringAsFixed(2)} L';
      return isNegative ? '-$formattedAmount' : formattedAmount;
    } else {
      String formattedAmount =
          '${(positiveAmount / 1000).toStringAsFixed(2)} K';
      return isNegative ? '-$formattedAmount' : formattedAmount;
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

  Widget getEmptyTopTitle(double val, TitleMeta meta) {
    return const Text("");
  }

  SideTitles get _bottomTitlesGroupWiseAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<GroupWiseAnalysisExpensesData> mData = groupList.groupData;
      text = mData.elementAt(value.toInt()).groupName;
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

  SideTitles get _bottomTitlesSubGroupWiseAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<SubGroupWiseAnalysisExpensesData> mData = subGroupList.subGroupData;
      text = mData.elementAt(value.toInt()).subGroupName;
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

  SideTitles get _bottomTitlesDailyAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<DailyAnalysisExpensesData> mData = dailyData.dailyData;
      text = mData.elementAt(value.toInt()).date;
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

  List<BarChartGroupData> _groupWiseAnalysisChartData(
    List<GroupWiseAnalysisExpensesData> data,
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
                width: 20,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _subGroupWiseAnalysisChartData(
    List<SubGroupWiseAnalysisExpensesData> data,
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
                width: 20,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _monthlyAnalysisChartData(
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
                width: 20,
              ),
            ],
          ),
        )
        .toList();
  }

  Future<void> _loadExpenses(String userName, String userLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<ExpensesList> tmpTrialBalanceList = [];
    try {
      do {
        var body = {
          "FromDate": formatDate(currentDate!),
          "ToDate": formatDate(currentDate!),
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
            List<ExpensesList> newTrialBalanceList =
                (responseJson['responseData'] as List)
                    .map((item) => ExpensesList.fromJson(item))
                    .toList();
            tmpTrialBalanceList.addAll(newTrialBalanceList);
            fetchedCount = newTrialBalanceList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else if (response.statusCode == 504) {
          await _loadExpenses(userName, userLevel);
        } else if (response.statusCode == 502) {
          await _loadExpenses(userName, userLevel);
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        final fromYM =
            fiscalYearStartDate!.year * 100 + fiscalYearStartDate!.month;
        final toYM = currentDate!.year * 100 + currentDate!.month;
        tmpTrialBalanceList = tmpTrialBalanceList.where((target) {
          final parts = target.monthYear.split('/');
          final month = int.parse(parts[0]);
          final year = int.parse(parts[1]);
          final targetYM = year * 100 + month;
          return targetYM >= fromYM && targetYM <= toYM;
        }).toList();
        context.read<FinanceExpensesBIProvider>().updateCollectionList(
          tmpTrialBalanceList,
        );
        if (expensesList.isEmpty) {
          expensesList = tmpTrialBalanceList.toList();
          expensesListTemp = tmpTrialBalanceList.toList();
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

  Future<void> _loadGroupWiseAnalysis(
    int monthIndex,
    String? group,
    String? subGroup,
  ) async {
    List<GroupWiseAnalysisExpensesData> groupWiseDataList = [];
    var customerTargetList = const Iterable.empty();
    double balance = 0.0;
    String groupName = "";
    Set<String> processedGroupCodes = {};

    // Use fallback if fromDateFilter or toDateFilter is null
    final from = fromDateFilter ?? fiscalYearStartDate;
    final to = toDateFilter ?? DateTime.now(); // Optional fallback

    var fromYM = from!.year * 100 + from.month;
    var toYM = to.year * 100 + to.month;

    if (monthIndex == 0) {
      customerTargetList = expensesList.where((target) {
        final parts = target.monthYear.split('/');
        final month = int.parse(parts[0]);
        final year = int.parse(parts[1]);
        final targetYM = year * 100 + month;

        return targetYM >= fromYM && targetYM <= toYM;
      }).toList();

      customerTargetList = filterExpensesList(
        customerTargetList.cast<ExpensesList>().toList(),
        group: group,
        subGroup: subGroup,
      );

      for (var customer
          in customerTargetList
              .where((customer) => customer.group == "Expenditure")
              .toList()) {
        if (!processedGroupCodes.contains(customer.group)) {
          groupName = customer.group;
          for (var sales in customerTargetList.where(
            (saleelement) => saleelement.group == groupName,
          )) {
            balance += double.tryParse(sales.balance) ?? 0;
          }

          groupWiseDataList.add(
            GroupWiseAnalysisExpensesData(
              groupName: groupName,
              balance: balance.abs(),
            ),
          );
          balance = 0;
          processedGroupCodes.add(groupName);
        }
      }
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      fromYM = currentDate!.year * 100 + monthDates['end']!.month;
      toYM = currentDate!.year * 100 + monthDates['end']!.month;
      customerTargetList = expensesList.where((target) {
        final parts = target.monthYear.split('/');
        final month = int.parse(parts[0]);
        final year = int.parse(parts[1]);
        final targetYM = year * 100 + month;

        return targetYM >= fromYM && targetYM <= toYM;
      }).toList();

      customerTargetList = filterExpensesList(
        customerTargetList.cast<ExpensesList>().toList(),
        group: group,
        subGroup: subGroup,
      );

      for (var customer
          in customerTargetList
              .where((customer) => customer.group == "Expenditure")
              .toList()) {
        if (!processedGroupCodes.contains(customer.group)) {
          groupName = customer.group;
          for (var sales in customerTargetList.where(
            (saleelement) => saleelement.group == groupName,
          )) {
            balance += double.tryParse(sales.balance) ?? 0;
          }

          groupWiseDataList.add(
            GroupWiseAnalysisExpensesData(
              groupName: groupName,
              balance: balance.abs(),
            ),
          );
          balance = 0;
          processedGroupCodes.add(groupName);
        }
      }
    }

    groupWiseDataList.sort(
      (a, b) => b.balance.abs().compareTo(a.balance.abs()),
    );
    groupList = GroupWiseAnalysisExpensesList(groupData: groupWiseDataList);
  }

  // Future<void> _loadSubGroupWiseAnalysis(
  //     String? touchedMonth,
  //   int monthIndex,
  //   String? group,
  //   String? subGroup,
  // ) async {
  //   List<SubGroupWiseAnalysisExpensesData> subGroupWiseDataList = [];
  //   var customerTargetList = const Iterable.empty();
  //   double balance = 0.0;
  //   String subGroupName = "";
  //
  //   // Use fallback if fromDateFilter or toDateFilter is null
  //   final from = fromDateFilter ?? fiscalYearStartDate;
  //   final to = toDateFilter ?? DateTime.now(); // Optional fallback
  //
  //   var fromYM = from!.year * 100 + from.month;
  //   var toYM = to.year * 100 + to.month;
  //
  //   if (monthIndex == 0) {
  //     customerTargetList = expensesList.where((target) {
  //       final parts = target.monthYear.split('/');
  //       final month = int.parse(parts[0]);
  //       final year = int.parse(parts[1]);
  //       final targetYM = year * 100 + month;
  //
  //       return targetYM >= fromYM && targetYM <= toYM;
  //     }).toList();
  //
  //     customerTargetList = filterExpensesList(
  //       customerTargetList.cast<ExpensesList>().toList(),
  //       group: group,
  //       subGroup: subGroup,
  //     );
  //
  //     Set<String> processedSubGroupCodes = {};
  //
  //     for (var customer in customerTargetList
  //         .where((customer) => customer.group == "Expenditure")
  //         .toList()) {
  //       if (!processedSubGroupCodes.contains(customer.subGroup)) {
  //         subGroupName = customer.subGroup;
  //         for (var sales in customerTargetList
  //             .where((saleelement) => saleelement.subGroup == subGroupName)) {
  //           balance += double.tryParse(sales.balance) ?? 0;
  //         }
  //
  //         subGroupWiseDataList.add(SubGroupWiseAnalysisExpensesData(
  //           subGroupName: subGroupName,
  //           balance: balance,
  //         ));
  //         balance = 0;
  //         processedSubGroupCodes.add(subGroupName);
  //       }
  //     }
  //   } else {
  //     Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
  //     fromYM = currentDate!.year * 100 + monthDates['end']!.month;
  //     toYM = currentDate!.year * 100 + monthDates['end']!.month;
  //     customerTargetList = expensesList.where((target) {
  //       final parts = target.monthYear.split('/');
  //       final month = int.parse(parts[0]);
  //       final year = int.parse(parts[1]);
  //       final targetYM = year * 100 + month;
  //
  //       return targetYM >= fromYM && targetYM <= toYM;
  //     }).toList();
  //
  //     customerTargetList = filterExpensesList(
  //       customerTargetList.cast<ExpensesList>().toList(),
  //       group: group,
  //       subGroup: subGroup,
  //     );
  //
  //     Set<String> processedSubGroupCodes = {};
  //
  //     for (var customer in customerTargetList
  //         .where((customer) => customer.group == "Expenditure")
  //         .toList()) {
  //       if (!processedSubGroupCodes.contains(customer.subGroup)) {
  //         subGroupName = customer.subGroup;
  //         for (var sales in customerTargetList
  //             .where((saleelement) => saleelement.subGroup == subGroupName)) {
  //           balance += double.tryParse(sales.balance) ?? 0;
  //         }
  //
  //         subGroupWiseDataList.add(SubGroupWiseAnalysisExpensesData(
  //           subGroupName: subGroupName,
  //           balance: balance,
  //         ));
  //         balance = 0;
  //         processedSubGroupCodes.add(subGroupName);
  //       }
  //     }
  //   }
  //
  //   subGroupWiseDataList
  //       .sort((a, b) => b.balance.abs().compareTo(a.balance.abs()));
  //   subGroupList =
  //       SubGroupWiseAnalysisExpensesList(subGroupData: subGroupWiseDataList);
  // }

  Future<void> _loadSubGroupWiseAnalysis(
    String? touchedMonth,
    int monthIndex,
    String? group,
    String? subGroup,
  ) async {
    List<SubGroupWiseAnalysisExpensesData> subGroupWiseDataList = [];
    Iterable<ExpensesList> customerTargetList = const Iterable.empty();
    double balance = 0.0;
    String subGroupName = "";

    // Use fallback if from/to filters are null
    final from = fromDateFilter ?? fiscalYearStartDate;
    final to = toDateFilter ?? DateTime.now();

    // Parse touchedMonth if provided (expects "MM/YYYY")
    if (touchedMonth != null && touchedMonth.isNotEmpty) {
      final parts = touchedMonth.split('/');
      final month = int.parse(parts[0]);
      final year = int.parse(parts[1]);

      customerTargetList = expensesList.where((target) {
        final p = target.monthYear.split('/');
        final m = int.parse(p[0]);
        final y = int.parse(p[1]);
        return y == year && m == month;
      }).cast<ExpensesList>();
    } else if (monthIndex == 0) {
      // full range between from and to
      final fromYM = from!.year * 100 + from.month;
      final toYM = to.year * 100 + to.month;

      customerTargetList = expensesList.where((target) {
        final parts = target.monthYear.split('/');
        final m = int.parse(parts[0]);
        final y = int.parse(parts[1]);
        final targetYM = y * 100 + m;
        return targetYM >= fromYM && targetYM <= toYM;
      }).cast<ExpensesList>();
    } else {
      // single selected month via monthIndex
      final monthDates = getMonthStartEndDates(monthIndex);
      final targetMonth = monthDates['end']!;
      final YM = targetMonth.year * 100 + targetMonth.month;

      customerTargetList = expensesList.where((target) {
        final parts = target.monthYear.split('/');
        final m = int.parse(parts[0]);
        final y = int.parse(parts[1]);
        final targetYM = y * 100 + m;
        return targetYM == YM;
      }).cast<ExpensesList>();
    }

    // apply group/subGroup filters
    final filtered = filterExpensesList(
      customerTargetList.toList(),
      group: group,
      subGroup: subGroup,
    );

    // aggregate by subGroup
    final processed = <String>{};
    for (var item in filtered.where((e) => e.group == "Expenditure")) {
      if (!processed.contains(item.subGroup)) {
        subGroupName = item.subGroup;
        balance = filtered
            .where((e) => e.subGroup == subGroupName)
            .fold<double>(
              0.0,
              (sum, e) => sum + (double.tryParse(e.balance) ?? 0.0),
            );
        subGroupWiseDataList.add(
          SubGroupWiseAnalysisExpensesData(
            subGroupName: subGroupName,
            balance: balance,
          ),
        );
        processed.add(subGroupName);
      }
    }

    // sort and assign
    subGroupWiseDataList.sort(
      (a, b) => b.balance.abs().compareTo(a.balance.abs()),
    );
    subGroupList = SubGroupWiseAnalysisExpensesList(
      subGroupData: subGroupWiseDataList,
    );
  }

  Future<void> _loadMonthlyAnalysis(String? subgroup) async {
    List<DailyAnalysisExpensesData> groupWiseDataList = [];

    final from = fromDateFilter ?? fiscalYearStartDate;
    final to = toDateFilter ?? DateTime.now();
    final fromYM = from!.year * 100 + from.month;
    final toYM = to.year * 100 + to.month;

    final filtered = expensesList.where((target) {
      final parts = target.monthYear.split('/');
      final month = int.parse(parts[0]);
      final year = int.parse(parts[1]);
      final targetYM = year * 100 + month;

      final inDateRange = targetYM >= fromYM && targetYM <= toYM;
      final inSubgroup =
          subgroup == null || subgroup.isEmpty || target.subGroup == subgroup;

      return inDateRange && inSubgroup;
    }).toList();

    final seen = <String>{};
    for (var entry in filtered) {
      final ym = entry.monthYear;
      if (seen.add(ym)) {
        final sumForMonth = filtered
            .where((e) => e.monthYear == ym)
            .map((e) => double.tryParse(e.balance) ?? 0)
            .fold<double>(0, (prev, b) => prev + b.abs());

        groupWiseDataList.add(
          DailyAnalysisExpensesData(balance: sumForMonth, date: ym),
        );
      }
    }

    dailyData = DailyAnalysisExpensesList(dailyData: groupWiseDataList);
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    UserLevel = userLevel;
    await _loadExpenses(userName, userLevel);
    await _loadGroupWiseAnalysis(0, "", "");
    await _loadSubGroupWiseAnalysis("", 0, "", "");
    await _loadMonthlyAnalysis("");
    chartDataLoadedExpenses = true;
  }

  int filterFunction() {
    return 0;
  }

  List<ExpensesList> filterExpensesList(
    List<ExpensesList> payableList, {
    String? group,
    String? subGroup,
  }) {
    List<ExpensesList> filteredCollectionTargetList = [];
    for (var target in payableList) {
      if ((group == null || group.isEmpty || target.group == group) &&
          (subGroup == null ||
              subGroup.isEmpty ||
              target.subGroup == subGroup)) {
        filteredCollectionTargetList.add(target);
      }
    }
    return filteredCollectionTargetList;
  }

  Future<void> loadDataWithFilter(
    String? touchedMonth,
    int monthIndex,
    String? group,
    String? subGroup,
  ) async {
    clearVariablesForFilter();
    LoadDates();
    await _loadGroupWiseAnalysis(monthIndex, group, subGroup);
    await _loadSubGroupWiseAnalysis(touchedMonth, monthIndex, group, subGroup);
    _loadMonthlyAnalysis(subGroup);

    chartDataLoadedExpenses = true;
  }

  Future<void> removeFilter() async {
    clearVariables();
    LoadDates();
    await _loadGroupWiseAnalysis(0, "", "");

    await _loadSubGroupWiseAnalysis("", 0, "", "");
    await _loadMonthlyAnalysis("");

    chartDataLoadedExpenses = true;
  }

  void clearVariables() {
    setState(() {
      chartDataLoadedExpenses = false;
      groupList = GroupWiseAnalysisExpensesList(groupData: []);
      subGroupList = SubGroupWiseAnalysisExpensesList(subGroupData: []);
      dailyData = DailyAnalysisExpensesList(dailyData: []);
      touchedSubGroup = "";
      touchedGroup = "";
      // touchedMonth = "";
      fromDateForFilter = '';
      toDateForFilter = '';
      fromDateFilter = null;
      _fromDateController.clear();
      _toDateController.clear();
    });
  }

  void clearVariablesForFilter() {
    setState(() {
      chartDataLoadedExpenses = false;
      groupList = GroupWiseAnalysisExpensesList(groupData: []);
      subGroupList = SubGroupWiseAnalysisExpensesList(subGroupData: []);
      dailyData = DailyAnalysisExpensesList(dailyData: []);
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

  Future<void> generateGroupWiseExcel(
    GroupWiseAnalysisExpensesList list,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Group', 'Total']));
      for (var data in list.groupData) {
        sheet.appendRow(toCellRow([data.groupName, data.balance]));
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('groupWiseAnalysis.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/groupWiseAnalysis.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateGroupWisePDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Group Wise Analysis',
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
                      'Group',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Total',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var data in groupList.groupData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        data.groupName,
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
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/groupWiseAnalysis.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSubGroupWiseExcel(
    SubGroupWiseAnalysisExpensesList list,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['SubGroup', 'Total']));
      for (var data in list.subGroupData) {
        sheet.appendRow(toCellRow([data.subGroupName, data.balance]));
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('SubGroupWiseAnalysis.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/SubGroupWiseAnalysis.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSubGroupWisePDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Sub Group Wise Analysis',
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
                      'Sub Group',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Total',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var data in subGroupList.subGroupData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        data.subGroupName,
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
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/SubGroupWiseAnalysis.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateMonthlyAnalysisExcel(
    DailyAnalysisExpensesList list,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Month', 'Total']));
      for (var data in list.dailyData) {
        sheet.appendRow(toCellRow([data.date, data.balance]));
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('monthlyAnalysis.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/monthlyAnalysis.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateMonthlyAnalysisPDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Sub Group Wise Analysis',
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
                      'Sub Group',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Total',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var data in subGroupList.subGroupData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        data.subGroupName,
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
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/SubGroupWiseAnalysis.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void toggleCheckbox() {
    setState(() {
      chartDataLoadedExpenses = false;
      loadData("");
      // selectedCheckbox = index;
    });
  }

  // Future<void> _dateFilterTargetOld() async {
  //   expensesList = expensesListTemp;
  //   DateFormat formatter = DateFormat('dd/MM/yyyy');

  //   setState(() {
  //     context
  //         .read<FinanceExpensesBIProvider>()
  //         .updateCollectionList(expensesList);

  //     expensesList = expensesList.where((target) {
  //       DateTime toDt = formatter.parse('31/${target.monthYear}');
  //       return (toDt.isAtLeast(fromDateFilter!) &&
  //           toDt.isAtMost(toDateFilter!));
  //     }).toList();
  //   });
  // }

  Future<void> _dateFilterTarget() async {
    expensesList = expensesListTemp;

    setState(() {
      context.read<FinanceExpensesBIProvider>().updateCollectionList(
        expensesList,
      );

      // Convert from and to date to YYYYMM for month-level comparison
      final fromYM = fromDateFilter!.year * 100 + fromDateFilter!.month;
      final toYM = toDateFilter!.year * 100 + toDateFilter!.month;

      expensesList = expensesList.where((target) {
        final parts = target.monthYear.split('/');
        final month = int.parse(parts[0]);
        final year = int.parse(parts[1]);
        final targetYM = year * 100 + month;

        return targetYM >= fromYM && targetYM <= toYM;
      }).toList();
    });
  }

  Future<void> filterDateFunction() async {
    chartDataLoadedExpenses = false;

    _dateFilterTarget();
    await _loadGroupWiseAnalysis(0, "", "");
    await _loadSubGroupWiseAnalysis("", 0, "", "");
    await _loadMonthlyAnalysis("");
    setState(() {
      chartDataLoadedExpenses = true;

      // selectedCheckbox = index;
    });
  }

  String formatDateString(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  @override
  void initState() {
    super.initState();
    LoadDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
    }
  }

  @override
  void dispose() {
    _toDateController.dispose();
    _fromDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DateTime currentDate = DateTime.now();
    String formattedDateFirstOfThisMonth = DateFormat(
      'dd/MM/yy',
    ).format(DateTime(currentDate.year, currentDate.month, 1));
    String formattedDateNow = DateFormat('dd/MM/yy').format(currentDate);
    return chartDataLoadedExpenses == true
        ? SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 15),
                        Text(
                          "$formattedDateFirstOfThisMonth - $formattedDateNow",
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
                        // IconButton(
                        //     onPressed: () {
                        //       showPopupMenu();
                        //     },
                        //     icon: const Icon(Icons.filter_alt_outlined)),
                        const SizedBox(width: 5),
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
                          "Group Wise Analysis",
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
                                    generateGroupWiseExcel(groupList);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateGroupWisePDF();
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
                  child: _groupWiseAnalysis(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Sub-Group Wise Analysis",
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
                                    generateSubGroupWiseExcel(subGroupList);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateSubGroupWisePDF();
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
                  child: _subGroupAnalysis(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
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
                      children: [
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateMonthlyAnalysisExcel(dailyData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateMonthlyAnalysisPDF();
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
                  child: _monthlyAnalysis(),
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
        setState(() {
          loadDataFuture = removeFilter();
        });
      }
    });
  }

  Widget _groupWiseAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = groupList.groupData.length;
    if (groupList.groupData.length > 5) {
      chartWidth = screenWidth + (40 * len);
    } else {
      chartWidth = screenWidth;
    }

    double maxGroupWiseAmount = len > 0
        ? groupList.groupData
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
            maxY: getMaxValue(maxGroupWiseAmount),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesGroupWiseAnalysis,
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
            barGroups: _groupWiseAnalysisChartData(groupList.groupData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedGroup = touchedGroup == ""
                          ? groupList
                                .groupData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .groupName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonth,
                        touchedMonthIndex,
                        touchedGroup,
                        touchedSubGroup,
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
                    "${groupList.groupData[grpIndex].groupName}\n",
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: formatAmount(
                          groupList.groupData[grpIndex].balance,
                        ),
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

  Widget _subGroupAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = subGroupList.subGroupData.length;
    if (subGroupList.subGroupData.length > 5) {
      chartWidth = screenWidth + (35 * len);
    } else {
      chartWidth = screenWidth;
    }

    final amounts = subGroupList.subGroupData
        .map((e) => e.balance)
        .whereType<double>()
        .toList();

    final hasPositive = amounts.any((a) => a > 0);
    final hasNegative = amounts.any((a) => a < 0);

    double chartMinY = 0;
    double chartMaxY = 0;

    if (hasPositive && hasNegative) {
      double maxPositive = amounts
          .where((a) => a > 0)
          .reduce((a, b) => a > b ? a : b);
      double maxNegative = amounts
          .where((a) => a < 0)
          .reduce((a, b) => a < b ? a : b);
      chartMaxY = roundUpTo50Lakhs(maxPositive);
      chartMinY = roundDownTo50Lakhs(maxNegative);
    } else if (hasPositive) {
      double maxPositive = amounts.reduce((a, b) => a > b ? a : b);
      chartMaxY = roundUpTo50Lakhs(maxPositive);
      chartMinY = 0;
    } else if (hasNegative) {
      double maxNegative = amounts.reduce((a, b) => a < b ? a : b);
      chartMaxY = 0;
      chartMinY = roundDownTo50Lakhs(maxNegative);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: chartMaxY,
            minY: chartMinY,
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesSubGroupWiseAnalysis,
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
            barGroups: _subGroupWiseAnalysisChartData(
              subGroupList.subGroupData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedSubGroup = touchedSubGroup == ""
                          ? subGroupList
                                .subGroupData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .subGroupName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonth,
                        touchedMonthIndex,
                        touchedGroup,
                        touchedSubGroup,
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
                    "${subGroupList.subGroupData[grpIndex].subGroupName}\n",
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: formatAmount(
                          subGroupList.subGroupData[grpIndex].balance,
                        ),
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
    int len = dailyData.dailyData.length;
    if (dailyData.dailyData.length > 5) {
      chartWidth = screenWidth + (10 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? dailyData.dailyData
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
                sideTitles: _bottomTitlesDailyAnalysis,
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
            barGroups: _monthlyAnalysisChartData(dailyData.dailyData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      List months = [
                        '01/2024',
                        '02/2024',
                        '03/2024',
                        '04/2024',
                        '05/2024',
                        '06/2024',
                        '07/2024',
                        '08/2024',
                        '09/2024',
                        '10/2024',
                        '11/2024',
                        '12/2024',
                      ];
                      touchedMonth = touchedMonth == ""
                          ? dailyData
                                .dailyData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .date
                          : "";
                      touchedMonthIndex = (touchedMonthIndex == 0
                          ? months.indexOf(touchedMonth) + 1
                          : 0);
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedMonth,
                        touchedMonthIndex,
                        touchedGroup,
                        touchedSubGroup,
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
                    "${dailyData.dailyData[grpIndex].date}\n",
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: formatAmount(
                          dailyData.dailyData[grpIndex].balance,
                        ),
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

  void showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Options - Expenses',
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
                        const SizedBox(
                          width: 150,
                          child: ListTile(title: Text("Date")),
                        ),
                        const VerticalDivider(width: 1),
                        // Right side: Filter options as checkboxes
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: Column(
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
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: fiscalYearStartDate,
                                          firstDate: fiscalYearStartDate!,
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
                                            : formatDateString(currentDate!),
                                      ),
                                      trailing: const Icon(
                                        Icons.calendar_today,
                                      ),
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              toDateFilter ?? DateTime.now(),
                                          firstDate: fiscalYearStartDate!,
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
                                      // toggleCheckbox();
                                      filterDateFunction();
                                      setState(() {});
                                      Navigator.pop(context);
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
                                      chartDataLoadedExpenses = false;
                                      setState(() {
                                        chartDataLoadedExpenses = false;
                                        expensesList = expensesListTemp;
                                        loadDataFuture = removeFilter();
                                        Navigator.pop(context);
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
