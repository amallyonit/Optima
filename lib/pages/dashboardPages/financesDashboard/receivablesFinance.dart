// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference
import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/login_screen.dart';
import '../../../api_helper.dart';
import '../../../classes/dashBoard.dart';
import '../../../classes/dataManager.dart';
import '../../../classes/globals.dart';
import '../../../classes/leads.dart';
import 'package:path_provider/path_provider.dart';
import '../ReportService.dart';

class ReceivablesFinance extends StatefulWidget {
  const ReceivablesFinance({super.key});

  @override
  State<ReceivablesFinance> createState() => _ReceivablesFinanceState();
}

late Future<void> loadDataFuture;
List<Users> usersList = [];
List<Users> childUsers = [];
List<Map<String, dynamic>> userList = [];
bool noUserList = false;
String UserLevel = "0";
List<CollectionList> collection = [];
List<DebtorsAgingList> target = [];
List<DebtorsAgingList> targetAPIData = [];

List<Users> usersListForFilter = [];
AllReceivablesFinanceList allReceivablesFinanceList = AllReceivablesFinanceList(
  agingData: [],
);
ReceivablesFinanceList receivablesFinanceList = ReceivablesFinanceList(
  agingData: [],
);
AdvanceFromCustomersList advanceCustomerList = AdvanceFromCustomersList(
  agingData: [],
);
CustomerAnalysisFinanceList customerAnalysisFinanceList =
    CustomerAnalysisFinanceList(customerData: []);
ReceivablesCategoryList receivablesCategoryList = ReceivablesCategoryList(
  categoryData: [],
);
TsmwiseCollectionList tsmwiseCollectionList = TsmwiseCollectionList(
  tsmwiseData: [],
);
AsmwiseCollectionList asmwiseCollectionList = AsmwiseCollectionList(
  asmwiseData: [],
);
RsmwiseCollectionList rsmwiseCollectionList = RsmwiseCollectionList(
  rsmwiseData: [],
);

final reportService = ReportService();

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

double receivablesAmount = 0;
String receivablesAmountStr = "";
double overDue = 0;
String overDueStr = "";
double due = 0;
String dueStr = '';
double advance = 0;
String advanceStr = '';
double netReceivables = 0;
String netReceivablesStr = "";
double grossReceivables = 0;
String grossReceivablesStr = "";
double receivablePercentage = 0;
double netReceivablePercentage = 0;
double netReceivablePercentageLocal = 0;
String notDueStr = "";
double notDue = 0.0;

double otherPercent = 0.0;
double distributorPercent = 0.0;
double hospitalPercent = 0.0;
bool chartDataLoadedReceivables = false;

String touchedReceivables = "";
String touchedNetReceivables = "";
String touchedAdvance = "";
String touchedCustomer = "";
String touchedRegionalManager = "";
String touchedSalesManager = "";
String touchedSalesPerson = "";
double selectedChart = 0;

bool showingAllData = true;
bool showingNHData = true;
bool showingSalesData = true;
bool showingOfficeData = true;

int selectedCheckbox = 1;

List<String> selectedSalesData = [];

final List<String> categories = [
  'Sales Data',
  'Category',
  'Dimension',
  'RSM',
  'ASM',
  'TSM',
  'Due/Overdue',
  'Advance/Receivables',
  'Date',
];

List<List<String>> filterOptions = [
  ['OFFICE - Drs.', 'NH GROUP. - Drs.', 'Sales Team'],
  ['Hospital', 'Distributor', 'Other'],
  ['Credit Note', 'Invoice', 'Journal', 'Receipt'],
  listOfRSM,
  listOfASM,
  listOfTSM,
  ['Not Dues', 'Overdue'],
  ['Advance', 'Receivables'],
  [],
];

List<List<bool>> selectedFinanceReceivablesOptions = [];

List<List<bool>> savedFinanceReceivablesOptionsTemp = [];

List<List<bool>> savedFinanceReceivablesOptions = filterOptions
    .map((options) => List<bool>.filled(options.length, false))
    .toList();

List<DebtorsAgingList> targetListTemp = target;

List<String> listOfRSM = [];
List<String> listOfASM = [];
List<String> listOfTSM = [];

double sumOfCustomerCategoryWise = 0;

Map<String, Map<String, bool>> allCategoriesState = {};

int selectedCategoryIndex = 0;

bool fromFilter = false;

List<SalesList> sales = [];
List<ItemCostList> itemCostList = [];
YTDSalesList ytdSalesList = YTDSalesList(ytdData: []);
ProductMarginList productMarginList = ProductMarginList(productMarginData: []);
bool YtdSalesBarChartData = false;

DateTime? fromDateFilter;
DateTime? toDateFilter;
bool dateFilterFlag = false;

class FinanceReceivablesCollectionBIProvider with ChangeNotifier {
  List<CollectionList> _collectionList = [];
  List<CollectionList> get collectionList => _collectionList;
  void updateCollectionList(List<CollectionList> newCollectionList) {
    _collectionList = newCollectionList;
    notifyListeners();
  }
}

class FinanceReceivablesTargetCollectionBIProvider with ChangeNotifier {
  List<DebtorsAgingList> _targetList = [];
  List<DebtorsAgingList> get targetList => _targetList;
  void updateTargetList(List<DebtorsAgingList> newTargetList) {
    _targetList = newTargetList;
    notifyListeners();
  }
}

class _ReceivablesFinanceState extends State<ReceivablesFinance> {
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
        if (maxValue >= 300000) {
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

  double convertAmount(double amount) {
    if (amount >= 10000000) {
      // Amount in crores
      return double.parse((amount / 10000000).toStringAsFixed(2));
    } else if (amount >= 100000) {
      // Amount in lakhs
      return double.parse((amount / 100000).toStringAsFixed(2));
    } else {
      // Amount in thousands
      return double.parse((amount / 1000).toStringAsFixed(2));
    }
  }

  int touchedIndex = -1;

  String formatAmount(double amount) {
    final isNegative = amount < 0;
    final positiveAmount = amount.abs();
    String formatted;

    if (positiveAmount < 1000) {
      formatted = positiveAmount.toStringAsFixed(2);
    } else if (positiveAmount < 100000) {
      formatted = '${(positiveAmount / 1000).toStringAsFixed(2)} K';
    } else if (positiveAmount < 10000000) {
      formatted = '${(positiveAmount / 100000).toStringAsFixed(2)} L';
    } else {
      formatted = '${(positiveAmount / 10000000).toStringAsFixed(2)} Cr';
    }

    return isNegative ? '-$formatted' : formatted;
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

  String formatFinanceAmount(double amount) {
    if (amount >= 1000000000) {
      return "${(amount / 1000000000).toStringAsFixed(2)} B";
    } else if (amount >= 1000000) {
      return "${(amount / 1000000).toStringAsFixed(2)} M";
    } else {
      return '${(amount / 1000).toStringAsFixed(2)} K';
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

  String formatDateString(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  SideTitles get _leftTitles => SideTitles(
    reservedSize: 50,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      return Text(formatAmount(value), style: const TextStyle(fontSize: 12));
    },
  );

  SideTitles get _emptyTitlesTop =>
      SideTitles(showTitles: true, getTitlesWidget: getEmptyTopTitle);

  SideTitles get _bottomTitlesReceivableAging => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<AllReceivablesFinanceData> mData =
          allReceivablesFinanceList.agingData;
      text = mData.elementAt(value.toInt()).agingGroup;
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

  SideTitles get _bottomTitlesNetReceivableAging => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<ReceivablesFinanceData> mData = receivablesFinanceList.agingData;
      text = mData.elementAt(value.toInt()).agingGroup;
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

  SideTitles get _bottomTitlesAdvanceFromCustomer => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<AdvanceFromCustomersData> mData = advanceCustomerList.agingData;
      text = mData.elementAt(value.toInt()).agingGroup;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: text.length > 5
              ? Text(
                  '${text.substring(0, 5)}...',
                  style: const TextStyle(fontSize: 12),
                )
              : Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesCustomerAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<CustomerAnalysisFinanceData> mData =
          customerAnalysisFinanceList.customerData;
      text = mData.elementAt(value.toInt()).customerName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: text.length > 5
              ? Text(
                  '${text.substring(0, 5)}...',
                  style: const TextStyle(fontSize: 12),
                )
              : Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesRegionalManager => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<RsmwiseCollectionData> mData = rsmwiseCollectionList.rsmwiseData;
      text = mData.elementAt(value.toInt()).rsmName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: text.length > 5
              ? Text(
                  '${text.substring(0, 5)}...',
                  style: const TextStyle(fontSize: 12),
                )
              : Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesSalesManager => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<AsmwiseCollectionData> mData = asmwiseCollectionList.asmwiseData;
      text = mData.elementAt(value.toInt()).asmName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: text.length > 5
              ? Text(
                  '${text.substring(0, 5)}...',
                  style: const TextStyle(fontSize: 12),
                )
              : Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesSalesPerson => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<TsmwiseCollectionData> mData = tsmwiseCollectionList.tsmwiseData;
      text = mData.elementAt(value.toInt()).tsmName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: text.length > 5
              ? Text(
                  '${text.substring(0, 5)}...',
                  style: const TextStyle(fontSize: 12),
                )
              : Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  List<PieChartSectionData> _receivablesCategoryChart() {
    final List<PieChartSectionData> sections = [];
    for (final categoryData in receivablesCategoryList.categoryData) {
      final fontSize = touchedIndex >= 0 ? 12.0 : 11.0;
      final radius = touchedIndex >= 0 ? 80.0 : 75.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      final sectionData = PieChartSectionData(
        color: getCategoryColor(categoryData.categoryId),
        value: categoryData.categoryPercentage.abs(),
        title: '${categoryData.categoryPercentage.abs().toStringAsFixed(2)} %',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          color: Colors.black,
          shadows: shadows,
        ),
      );
      sections.add(sectionData);
    }
    return sections;
  }

  List<BarChartGroupData> _AllReceivableAgingChartData(
    List<AllReceivablesFinanceData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.agingGroupTotal,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _netReceivableAgingChartData(
    List<ReceivablesFinanceData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.agingGroupTotal,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _advanceFromCustomerChartData(
    List<AdvanceFromCustomersData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.agingGroupTotal,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _customerAnalysisChartData(
    List<CustomerAnalysisFinanceData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.collectionAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _regionalManagerAnalysisChartData(
    List<RsmwiseCollectionData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.collectionAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _salesManagerAnalysisChartData(
    List<AsmwiseCollectionData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.collectionAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _salesPersonAnalysisChartData(
    List<TsmwiseCollectionData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.collectionAmount,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  Widget getEmptyTopTitle(double val, TitleMeta meta) {
    return const Text("");
  }

  AgingSummary summarizeReceivables(
    Iterable<DebtorsAgingList> collectionTargetList,
  ) {
    AgingSummary summary = AgingSummary();
    var overDueDays = 0;
    for (var element
        in collectionTargetList /*.where((element) => double.tryParse(element.future)! <= 0)*/ ) {
      overDueDays = int.tryParse(element.dueDays.replaceAll(' Days', '')) ?? 0;

      if (overDueDays <= 30) {
        // summary.a0to30DaysTotal += (future);
        summary.a0to30DaysTotal += double.tryParse(element.a0to30Days)!;
      } else if (overDueDays >= 31 && overDueDays <= 60) {
        // summary.a31to60DaysTotal += future;
        summary.a31to60DaysTotal += double.tryParse(element.a31to60Days)!;
      } else if (overDueDays >= 61 && overDueDays <= 90) {
        // summary.a61to90DaysTotal += future;
        summary.a61to90DaysTotal += double.tryParse(element.a61to90Days)!;
      } else if (overDueDays >= 91 && overDueDays <= 180) {
        // summary.a91to180DaysTotal += future;
        summary.a91to180DaysTotal += double.tryParse(element.a91to180Days)!;
      } else if (overDueDays >= 181) {
        // summary.a181DaysTotal += future;
        summary.a181DaysTotal += double.tryParse(element.a181Days)!;
      }
      // summary.afutureTotal += future;
      summary.afutureTotal += double.tryParse(element.future)!;
    }
    return summary;
  }

  AgingSummary summarizeCollectionTargets(
    Iterable<DebtorsAgingList> collectionTargetList,
  ) {
    AgingSummary summary = AgingSummary();
    double balance = 0;
    var overDueDays = 0;
    for (var element in collectionTargetList.where(
      (element) => double.tryParse(element.future)! <= 0,
    )) {
      overDueDays = int.tryParse(element.dueDays.replaceAll(' Days', '')) ?? 0;
      balance = double.tryParse(element.balance) ?? 0;
      if (balance < 0) {
        // balance = 0; // If balance is negative, set it to zero
      }
      if (overDueDays <= 30) {
        // summary.a0to30DaysTotal += (balance);
        summary.a0to30DaysTotal += double.tryParse(element.a0to30Days)!;
      } else if (overDueDays >= 31 && overDueDays <= 60) {
        // summary.a31to60DaysTotal += balance;
        summary.a31to60DaysTotal += double.tryParse(element.a31to60Days)!;
      } else if (overDueDays >= 61 && overDueDays <= 90) {
        // summary.a61to90DaysTotal += balance;
        summary.a61to90DaysTotal += double.tryParse(element.a61to90Days)!;
      } else if (overDueDays >= 91 && overDueDays <= 180) {
        // summary.a91to180DaysTotal += balance;
        summary.a91to180DaysTotal += double.tryParse(element.a91to180Days)!;
      } else if (overDueDays >= 181) {
        // summary.a181DaysTotal += balance;
        summary.a181DaysTotal += double.tryParse(element.a181Days)!;
      }
      // summary.afutureTotal += balance;
      summary.afutureTotal += double.tryParse(element.future)!;
    }
    return summary;
  }

  AgingSummary summarizeAdvanceFromCustomers(
    Iterable<DebtorsAgingList> collectionTargetList,
  ) {
    AgingSummary summary = AgingSummary();
    int? overDueDays = 0;
    for (var element in collectionTargetList.where(
      (element) => double.tryParse(element.balance)! <= 0,
    )) {
      overDueDays = int.tryParse(element.dueDays.replaceAll(' Days', '')) ?? 0;

      if (overDueDays <= 30) {
        summary.a0to30DaysTotal += double.tryParse(element.a0to30Days)!;
      } else if (overDueDays >= 31 && overDueDays <= 60) {
        // summary.a31to60DaysTotal += balance;
        summary.a31to60DaysTotal += double.tryParse(element.a31to60Days)!;
      } else if (overDueDays >= 61 && overDueDays <= 90) {
        // summary.a61to90DaysTotal += balance;
        summary.a61to90DaysTotal += double.tryParse(element.a61to90Days)!;
      } else if (overDueDays >= 91 && overDueDays <= 180) {
        // summary.a91to180DaysTotal += balance;
        summary.a91to180DaysTotal += double.tryParse(element.a91to180Days)!;
      } else if (overDueDays >= 181) {
        // summary.a181DaysTotal += balance;
        summary.a181DaysTotal += double.tryParse(element.a181Days)!;
      }

      summary.afutureTotal += double.tryParse(element.future)!;
    }
    return summary;
  }

  Future<void> _loadCustomerCategoryWise() async {
    final parsed = target
        .map((t) {
          final due = DateFormat('dd/MM/yyyy').parse(t.dueon);
          final bal = double.tryParse(t.balance) ?? 0.0;
          return (due: due, group: t.customerGroup, balance: bal);
        })
        .where((e) => e.due.isAtMost(currentDate!))
        .toList();

    final double overallTotal = parsed.fold(0.0, (sum, e) => sum + e.balance);

    final double hospitalSum = parsed
        .where((e) => e.group == 'Hospital')
        .fold(0.0, (sum, e) => sum + e.balance);

    final double distributorSum = parsed
        .where((e) => e.group == 'Distributor')
        .fold(0.0, (sum, e) => sum + e.balance);

    final double otherSum = parsed
        .where((e) => e.group != 'Hospital' && e.group != 'Distributor')
        .fold(0.0, (sum, e) => sum + e.balance);

    double hospitalPercent = 0;
    double distributorPercent = 0;
    double otherPercent = 0;

    if (overallTotal > 0) {
      hospitalPercent = (hospitalSum / overallTotal) * 100;
      distributorPercent = (distributorSum / overallTotal) * 100;
      otherPercent = (otherSum / overallTotal) * 100;
    }

    receivablesCategoryList = ReceivablesCategoryList(
      categoryData: [
        ReceivablesCategoryData(
          categoryId: 0,
          categoryName: 'Hospital',
          categoryAmount: hospitalSum,
          categoryPercentage: hospitalPercent,
        ),
        ReceivablesCategoryData(
          categoryId: 1,
          categoryName: 'Distributor',
          categoryAmount: distributorSum,
          categoryPercentage: distributorPercent,
        ),
        ReceivablesCategoryData(
          categoryId: 2,
          categoryName: 'Other',
          categoryAmount: otherSum,
          categoryPercentage: otherPercent,
        ),
      ],
    );
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

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _loadReceivablesData(
    String receivableId,
    String netReceivableId,
    String advanceId,
    String customer,
    String regionalManager,
    String salesManager,
    String salesPerson,
  ) async {
    var list = target.where((t) {
      DateTime dueOn = t.parsedPostingDate;
      return dueOn.isAtMost(currentDate!);
    }).cast<DebtorsAgingList>();

    if (customer.isNotEmpty) {
      list = list.where((e) => e.customerName == customer);
    }
    if (regionalManager.isNotEmpty) {
      list = list.where((e) => e.regionalManager == regionalManager);
    }
    if (salesManager.isNotEmpty) {
      list = list.where((e) => e.salesManager == salesManager);
    }
    if (salesPerson.isNotEmpty) {
      list = list.where((e) => e.salesRep == salesPerson);
    }

    String? bracketFilter;
    String bracketLabel = "";
    if (receivableId.isNotEmpty) {
      bracketFilter = receivableId == "Future"
          ? "Future"
          : "$receivableId Days";
      bracketLabel = receivableId;
    } else if (netReceivableId.isNotEmpty) {
      bracketFilter = netReceivableId == "Future"
          ? "Future"
          : "$netReceivableId Days";
      bracketLabel = netReceivableId;
    } else if (advanceId.isNotEmpty) {
      bracketFilter = advanceId == "Future" ? "Future" : "$advanceId Days";
      bracketLabel = advanceId;
    }

    final List<AllReceivablesFinanceData> dataList = [];
    double totalDue = 0;

    Map<String, double> buckets = {
      "Future": 0,
      "0-30": 0,
      "31-60": 0,
      "61-90": 0,
      "91-180": 0,
      "180+": 0,
    };

    if (bracketFilter != null) {
      final sum = list
          .where((e) => e.ageingBrackets == bracketFilter)
          .fold<double>(0, (s, e) => s + (double.tryParse(e.balance) ?? 0));
      buckets[bracketLabel] = sum;
    } else {
      final summary = summarizeReceivables(list.toList());
      buckets["Future"] = summary.afutureTotal;
      buckets["0-30"] = summary.a0to30DaysTotal;
      buckets["31-60"] = summary.a31to60DaysTotal;
      buckets["61-90"] = summary.a61to90DaysTotal;
      buckets["91-180"] = summary.a91to180DaysTotal;
      buckets["180+"] = summary.a181DaysTotal;
    }

    totalDue = buckets.values.fold(0.0, (sum, v) => sum + v);

    buckets.forEach((label, amt) {
      dataList.add(
        AllReceivablesFinanceData(
          agingGroup: label,
          agingGroupTotal: amt.abs(),
          agingPercentage: totalDue > 0
              ? double.parse(((amt.abs() / totalDue) * 100).toStringAsFixed(2))
              : 0,
          agingTotal: totalDue.abs(),
        ),
      );
    });

    allReceivablesFinanceList = AllReceivablesFinanceList(agingData: dataList);
  }

  Future<void> _loadNetReceivablesData(
    String receivableId,
    String netReceivableId,
    String advanceId,
    String customer,
    String regionalManager,
    String salesManager,
    String salesPerson,
  ) async {
    var list = target.where((t) {
      DateTime dueOn = t.parsedDueDate;
      return dueOn.isAtMost(currentDate!);
    }).cast<DebtorsAgingList>();

    if (customer.isNotEmpty) {
      list = list.where((e) => e.customerName == customer);
    }
    if (regionalManager.isNotEmpty) {
      list = list.where((e) => e.regionalManager == regionalManager);
    }
    if (salesManager.isNotEmpty) {
      list = list.where((e) => e.salesManager == salesManager);
    }
    if (salesPerson.isNotEmpty) {
      list = list.where((e) => e.salesRep == salesPerson);
    }

    String? bracketFilter;
    String bracketLabel = "";
    if (receivableId.isNotEmpty) {
      bracketFilter = receivableId == "Future"
          ? "Future"
          : "$receivableId Days";
      bracketLabel = receivableId;
    } else if (netReceivableId.isNotEmpty) {
      bracketFilter = netReceivableId == "Future"
          ? "Future"
          : "$netReceivableId Days";
      bracketLabel = netReceivableId;
    } else if (advanceId.isNotEmpty) {
      bracketFilter = advanceId == "Future" ? "Future" : "$advanceId Days";
      bracketLabel = advanceId;
    }

    final buckets = <String, double>{
      "Future": 0,
      "0-30": 0,
      "31-60": 0,
      "61-90": 0,
      "91-180": 0,
      "180+": 0,
    };

    if (bracketFilter != null) {
      final sum = list
          .where((e) => e.ageingBrackets == bracketFilter)
          .fold<double>(0, (s, e) => s + (double.tryParse(e.balance) ?? 0));
      buckets[bracketLabel] = sum;
    } else {
      final summary = summarizeCollectionTargets(list.toList());
      buckets["Future"] = summary.afutureTotal;
      buckets["0-30"] = summary.a0to30DaysTotal;
      buckets["31-60"] = summary.a31to60DaysTotal;
      buckets["61-90"] = summary.a61to90DaysTotal;
      buckets["91-180"] = summary.a91to180DaysTotal;
      buckets["180+"] = summary.a181DaysTotal;
    }

    final totalDue = buckets.values.fold(0.0, (sum, v) => sum + v);

    final receivablesAgingDataList = <ReceivablesFinanceData>[];
    buckets.forEach((label, amt) {
      final absAmt = amt.abs();
      receivablesAgingDataList.add(
        ReceivablesFinanceData(
          agingGroup: label,
          agingGroupTotal: absAmt,
          agingPercentage: totalDue > 0
              ? double.parse((absAmt / totalDue * 100).toStringAsFixed(2))
              : 0,
          agingTotal: totalDue.abs(),
        ),
      );
    });

    receivablesFinanceList = ReceivablesFinanceList(
      agingData: receivablesAgingDataList,
    );
  }

  Future<void> _loadAdvanceFromCustomers(
    String receivableId,
    String netReceivableId,
    String advanceId,
    String customer,
    String regionalManager,
    String salesManager,
    String salesPerson,
  ) async {
    List<AdvanceFromCustomersData> advanceList = [];

    // ---------- Step 1: Get filtered customers ONLY ----------
    var filteredCustomers = target.where((t) {
      DateTime dueOn = t.parsedPostingDate;
      return dueOn.isAtMost(currentDate!);
    }).cast<DebtorsAgingList>();

    filteredCustomers = filterCollectionTargetList(
      filteredCustomers.toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesPerson,
      customer: customer,
      receivableCatg: receivableId,
      netReceivableCatg: netReceivableId,
      advanceCatg: advanceId,
    );

    // Unique customers
    final customerNames = filteredCustomers.map((e) => e.customerName).toSet();

    // ---------- Step 2: Initialize buckets ----------
    final buckets = <String, double>{
      'Future': 0,
      '0-30 Days': 0,
      '31-60 Days': 0,
      '61-90 Days': 0,
      '91-180 Days': 0,
      '180+ Days': 0,
    };

    // ---------- Step 3: Advance logic ----------
    for (var custName in customerNames) {
      // FULL data (NOT filtered)
      final fullRows = target.where((e) => e.customerName == custName);

      double totalBalance = 0;

      for (var r in fullRows) {
        totalBalance += double.tryParse(r.balance) ?? 0;
      }

      // Only ADVANCE customers
      if (totalBalance >= 0) continue;

      // ---------- Step 4: Bucket distribution ----------
      for (var r in fullRows) {
        final bucket = r.ageingBrackets;
        final amount = double.tryParse(r.balance) ?? 0;

        if (buckets.containsKey(bucket)) {
          buckets[bucket] = buckets[bucket]! + amount;
        } else {
          buckets['180+ Days'] = buckets['180+ Days']! + amount;
        }
      }
    }

    // ---------- Step 5: Total ----------
    final totalDue = buckets.values.fold(0.0, (sum, v) => sum + v);

    // ---------- Step 6: Output ----------
    advanceList.clear();

    buckets.forEach((label, amt) {
      final absAmt = amt.abs();

      advanceList.add(
        AdvanceFromCustomersData(
          agingGroup: label,
          agingGroupTotal: absAmt,
          agingPercentage: totalDue > 0
              ? double.parse((absAmt / totalDue * 100).toStringAsFixed(2))
              : 0,
          agingTotal: totalDue.abs(),
        ),
      );
    });

    advanceCustomerList = AdvanceFromCustomersList(agingData: advanceList);
  }

  Future<void> _loadCustomerAnalysis(
    String receivableId,
    String netReceivableId,
    String advanceId,
    String customer,
    String regionalManager,
    String salesManager,
    String salesPerson,
  ) async {
    List<CustomerAnalysisFinanceData> customerWiseDataList = [];
    var customerTargetList = const Iterable.empty();
    String custCode = "";
    String customerName = "";
    double balance = 0.0;
    advance = 0;
    customerTargetList = target.where((target) {
      DateTime dueon = target.parsedDueDate;
      return dueon.isAtMost(currentDate!);
    });

    customerTargetList = filterCollectionTargetList(
      customerTargetList.cast<DebtorsAgingList>().toList(),
      usersListForFilter,
      regionalManager: regionalManager,
      salesManager: salesManager,
      salesRep: salesPerson,
      customer: customer,
      receivableCatg: receivableId,
      netReceivableCatg: netReceivableId,
      advanceCatg: advanceId,
    );

    Set<String> processedCustomer = {};
    double balancAmount = 0;
    double tmpAdvance = 0;
    for (var customerRow in customerTargetList) {
      if (!processedCustomer.contains(customerRow.customerName)) {
        custCode = customerRow.customerCode;
        customerName = customerRow.customerName;

        for (var ele in target.toList().where(
          (element) => element.customerName == customerName,
        )) {
          bool shouldInclude = true;

          if (receivableId.isNotEmpty) {
            final tag = receivableId == "Future"
                ? "Future"
                : "$receivableId Days";
            shouldInclude = ele.ageingBrackets == tag;
          } else if (netReceivableId.isNotEmpty) {
            final tag = netReceivableId == "Future"
                ? "Future"
                : "$netReceivableId Days";
            shouldInclude = ele.ageingBrackets == tag;
          } else if (advanceId.isNotEmpty) {
            final tag = advanceId == "Future" ? "Future" : "$advanceId Days";
            shouldInclude = ele.ageingBrackets == tag;
          }

          if (shouldInclude) {
            balance = double.tryParse(ele.balance) ?? 0;
            balancAmount += balance;
            tmpAdvance += balance;
          }
        }

        customerWiseDataList.add(
          CustomerAnalysisFinanceData(
            customerCode: custCode,
            customerName: customerName,
            collectionAmount: balancAmount,
          ),
        );
        if (tmpAdvance < 0) {
          advance += tmpAdvance;
        }
        processedCustomer.add(customerName);
      }

      custCode = "";
      customerName = "";
      balancAmount = 0;
      tmpAdvance = 0;
    }

    customerWiseDataList.sort(
      (a, b) => b.collectionAmount.compareTo(a.collectionAmount),
    );
    customerAnalysisFinanceList = CustomerAnalysisFinanceList(
      customerData: customerWiseDataList,
    );
  }

  Future<void> _loadTSMCollectionBarChartData(
    String receivableId,
    String netReceivableId,
    String advanceId,
    String customer,
    String regionalManager,
    String salesManager,
    String salesPerson,
  ) async {
    List<TsmwiseCollectionData> tsmwiseDataList = [];
    final int currentYear = DateTime.now().year;
    double targetAmount = 0.0;
    const int monthIndex = 0;

    final allowedBrackets = <String>{
      if (receivableId.isNotEmpty)
        (receivableId == "Future" ? "Future" : "$receivableId Days"),
      if (netReceivableId.isNotEmpty)
        (netReceivableId == "Future" ? "Future" : "$netReceivableId Days"),
      if (advanceId.isNotEmpty)
        (advanceId == "Future" ? "Future" : "$advanceId Days"),
    };

    final allTsmNames = target.map((e) => e.salesRep).toSet();
    for (final tsmName in allTsmNames) {
      if (salesPerson.isNotEmpty && tsmName != salesPerson) continue;

      final tsmEntries = target.where((t) => t.salesRep == tsmName);
      double salesAmount = 0.0;

      for (final ele in tsmEntries) {
        if (regionalManager.isNotEmpty &&
            ele.regionalManager != regionalManager) {
          continue;
        }
        if (salesManager.isNotEmpty && ele.salesManager != salesManager) {
          continue;
        }
        if (customer.isNotEmpty && ele.customerName != customer) continue;

        final dueOn = DateFormat('dd/MM/yyyy').parse(ele.dueon);

        final bool isFutureSelected =
            receivableId == "Future" ||
            netReceivableId == "Future" ||
            advanceId == "Future";

        if (monthIndex == 0) {
          if (dueOn.isAfter(currentDate!) && !isFutureSelected) {
            continue;
          }
        } else if (monthIndex >= 4 && monthIndex <= 12) {
          final monthDates = getMonthStartEndDates(monthIndex);
          if (dueOn.isAfter(monthDates['end']!)) continue;
        } else {
          final endDate = DateTime(currentYear, monthIndex + 1, 0);
          if (dueOn.isAfter(endDate)) continue;
        }

        if (allowedBrackets.isNotEmpty &&
            !allowedBrackets.contains(ele.ageingBrackets)) {
          continue;
        }

        salesAmount += double.tryParse(ele.balance) ?? 0.0;
      }

      if (salesAmount != 0.0) {
        tsmwiseDataList.add(
          TsmwiseCollectionData(
            tsmName: tsmName,
            collectionAmount: salesAmount,
            targetAmount: targetAmount,
          ),
        );
      }
    }

    tsmwiseDataList.sort(
      (a, b) => b.collectionAmount.compareTo(a.collectionAmount),
    );
    tsmwiseCollectionList = TsmwiseCollectionList(tsmwiseData: tsmwiseDataList);

    if (listOfTSM.isEmpty) {
      listOfTSM = allTsmNames.toList();
    }
  }

  Future<void> _loadASMCollectionBarChartData(
    String receivableId,
    String netReceivableId,
    String advanceId,
    String customer,
    String regionalManager,
    String salesManager,
    String salesPerson,
  ) async {
    List<AsmwiseCollectionData> asmwiseDataList = [];
    final int currentYear = DateTime.now().year;
    double targetAmount = 0.0;
    const int monthIndex = 0;

    final allowedBrackets = <String>{
      if (receivableId.isNotEmpty)
        (receivableId == "Future" ? "Future" : "$receivableId Days"),
      if (netReceivableId.isNotEmpty)
        (netReceivableId == "Future" ? "Future" : "$netReceivableId Days"),
      if (advanceId.isNotEmpty)
        (advanceId == "Future" ? "Future" : "$advanceId Days"),
    };

    final allAsmNames = target.map((e) => e.salesManager).toSet();
    for (final asmName in allAsmNames) {
      if (salesManager.isNotEmpty && asmName != salesManager) continue;

      final asmEntries = target.where((t) => t.salesManager == asmName);
      double salesAmount = 0.0;

      for (final ele in asmEntries) {
        if (regionalManager.isNotEmpty &&
            ele.regionalManager != regionalManager) {
          continue;
        }
        if (salesPerson.isNotEmpty && ele.salesRep != salesPerson) continue;
        if (customer.isNotEmpty && ele.customerName != customer) continue;

        final dueOn = DateFormat('dd/MM/yyyy').parse(ele.dueon);

        final bool isFutureSelected =
            receivableId == "Future" ||
            netReceivableId == "Future" ||
            advanceId == "Future";

        if (monthIndex == 0) {
          if (dueOn.isAfter(currentDate!) && !isFutureSelected) {
            continue;
          }
        } else if (monthIndex >= 4 && monthIndex <= 12) {
          final monthDates = getMonthStartEndDates(monthIndex);
          if (dueOn.isAfter(monthDates['end']!)) continue;
        } else {
          final endDate = DateTime(currentYear, monthIndex + 1, 0);
          if (dueOn.isAfter(endDate)) continue;
        }

        if (allowedBrackets.isNotEmpty &&
            !allowedBrackets.contains(ele.ageingBrackets)) {
          continue;
        }

        salesAmount += double.tryParse(ele.balance) ?? 0.0;
      }

      if (salesAmount != 0.0) {
        asmwiseDataList.add(
          AsmwiseCollectionData(
            asmName: asmName,
            collectionAmount: salesAmount,
            targetAmount: targetAmount,
          ),
        );
      }
    }

    asmwiseDataList.sort(
      (a, b) => b.collectionAmount.compareTo(a.collectionAmount),
    );
    asmwiseCollectionList = AsmwiseCollectionList(asmwiseData: asmwiseDataList);

    if (listOfASM.isEmpty) {
      listOfASM = allAsmNames.toList();
    }
  }

  Future<void> _loadRSMCollectionBarChartData(
    String receivableId,
    String netReceivableId,
    String advanceId,
    String customer,
    String regionalManager,
    String salesManager,
    String salesPerson,
  ) async {
    final List<String> bracketFilters = [];
    if (receivableId.isNotEmpty) {
      bracketFilters.add(
        receivableId == "Future" ? "Future" : "$receivableId Days",
      );
    }
    if (netReceivableId.isNotEmpty) {
      bracketFilters.add(
        netReceivableId == "Future" ? "Future" : "$netReceivableId Days",
      );
    }
    if (advanceId.isNotEmpty) {
      bracketFilters.add(advanceId == "Future" ? "Future" : "$advanceId Days");
    }

    final bool isFutureSelected =
        receivableId == "Future" ||
        netReceivableId == "Future" ||
        advanceId == "Future";

    int monthIndex = 0;
    Iterable<DebtorsAgingList> dateFiltered = _filterByDate(
      target,
      monthIndex,
      currentDate,
      isFutureSelected: isFutureSelected,
    );

    final Iterable<DebtorsAgingList> filteredList = dateFiltered.where((t) {
      if (regionalManager.isNotEmpty && t.regionalManager != regionalManager) {
        return false;
      }
      if (salesManager.isNotEmpty && t.salesManager != salesManager) {
        return false;
      }
      if (salesPerson.isNotEmpty && t.salesRep != salesPerson) return false;
      if (customer.isNotEmpty && t.customerName != customer) return false;
      return true;
    });

    final Map<String, double> sumsByRSM = {};
    for (final t in filteredList) {
      final bracket = t.ageingBrackets;
      if (bracketFilters.isNotEmpty && !bracketFilters.contains(bracket)) {
        continue;
      }
      final amt = double.tryParse(t.balance) ?? 0.0;
      sumsByRSM[t.regionalManager] =
          (sumsByRSM[t.regionalManager] ?? 0.0) + amt;
    }

    final List<RsmwiseCollectionData> rsmwiseDataList = [];
    const double targetAmount = 0.0;
    for (final entry in sumsByRSM.entries) {
      rsmwiseDataList.add(
        RsmwiseCollectionData(
          rsmName: entry.key,
          collectionAmount: entry.value,
          targetAmount: targetAmount,
        ),
      );
    }

    rsmwiseDataList.sort(
      (a, b) => b.collectionAmount.compareTo(a.collectionAmount),
    );
    rsmwiseCollectionList = RsmwiseCollectionList(rsmwiseData: rsmwiseDataList);

    if (listOfRSM.isEmpty) {
      listOfRSM = rsmwiseDataList.map((e) => e.rsmName).toList();
    }
  }

  Iterable<DebtorsAgingList> _filterByDate(
    Iterable<DebtorsAgingList> sourceData,
    int monthIndex,
    DateTime? currentDate, {
    required bool isFutureSelected,
  }) {
    final int currentYear = DateTime.now().year;

    return sourceData.where((element) {
      final dueOn = DateFormat('dd/MM/yyyy').parse(element.dueon);

      if (monthIndex == 0) {
        if (dueOn.isAfter(currentDate!)) {
          return isFutureSelected;
        }
      } else if (monthIndex >= 4 && monthIndex <= 12) {
        final monthDates = getMonthStartEndDates(monthIndex);
        if (dueOn.isAfter(monthDates['end']!)) {
          return false;
        }
      } else {
        final endDate = DateTime(currentYear, monthIndex + 1, 0);
        if (dueOn.isAfter(endDate)) {
          return false;
        }
      }

      return true;
    });
  }

  Future<void> _loadUserList(
    String userId,
    String userJwtToken,
    String userMailID,
    int userLevel,
  ) async {
    final body = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'UserId': userId,
    };
    const apiUrl = '${ApiHelper.baseUrl}getuserlist';
    var headers = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(body),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['Data'];
          List<Map<String, dynamic>> newUserList = [];
          if (data.isNotEmpty) {
            setState(() {
              usersList = (data).map((item) => Users.fromJson(item)).toList();
              childUsers = usersList
                  .where((element) => element.parentMenuId != 0)
                  .toList();
            });
          }
          for (var parent in usersList.where(
            (element) =>
                element.parentMenuId == 0 &&
                (element.userLevel == (userLevel > 3 ? 3 : 2)),
          )) {
            final rsm = {
              "MenuId": parent.menuId,
              "MenuName": parent.menuName,
              "SubMenuId": parent.subMenuId,
              "ParentMenuId": parent.parentMenuId,
              "UserLevel": parent.userLevel,
            };
            newUserList.add(rsm);
            for (var child in childUsers.where(
              (element) =>
                  element.parentMenuId == parent.menuId &&
                  (element.userLevel == (userLevel > 3 ? 2 : 1)),
            )) {
              final asm = {
                "MenuId": child.menuId,
                "MenuName": child.menuName,
                "SubMenuId": child.subMenuId,
                "ParentMenuId": child.parentMenuId,
                "UserLevel": child.userLevel,
              };
              newUserList.add(asm);
              for (var subChild in childUsers.where(
                (element) => element.parentMenuId == child.menuId,
              )) {
                final tsm = {
                  "MenuId": subChild.menuId,
                  "MenuName": subChild.menuName,
                  "SubMenuId": subChild.subMenuId,
                  "ParentMenuId": subChild.parentMenuId,
                  "UserLevel": subChild.userLevel,
                };
                newUserList.add(tsm);
              }
            }
          }
          setState(() {
            userList = newUserList;
            noUserList = true;
          });
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
          }
        }
      } else {
        const snackBar = SnackBar(content: Text('User list not found.'));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadUserListForFilter(
    String userId,
    String userJwtToken,
    String userMailID,
    int userLevel,
  ) async {
    final body = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'UserId': userId,
    };
    const apiUrl = '${ApiHelper.baseUrl}getusersforfilter';
    var headers = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(body),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['Data'];
          if (data.isNotEmpty) {
            setState(() {
              usersListForFilter = (data)
                  .map((item) => Users.fromJson(item))
                  .toList();
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
          }
        }
      } else {
        const snackBar = SnackBar(content: Text('User list not found.'));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadCollectionTarget(
    String userName,
    String userLevel,
    bool fromFilter,
  ) async {
    int index = 0;
    const int limit = 10000;
    int fetchedCount = 0;

    final List<DebtorsAgingList> targetList = [];

    try {
      // -------------------------------
      // 1. API Pagination
      // -------------------------------
      if (!fromFilter) {
        do {
          final body = {
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

          if (response.statusCode == 200) {
            final responseJson = jsonDecode(response.body);

            final data = responseJson["responseData"];

            if (data != null && data is List && data.isNotEmpty) {
              final List<DebtorsAgingList> newTargetList = data
                  .map<DebtorsAgingList>((item) {
                    final obj = DebtorsAgingList.fromJson(item);

                    // Parse date once (correct approach)
                    obj.parsedDueDate = DateFormat(
                      'dd/MM/yyyy',
                    ).parse(obj.dueon);

                    obj.parsedPostingDate = DateFormat(
                      'dd/MM/yyyy',
                    ).parse(obj.postingDate);

                    return obj;
                  })
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
        } while (fetchedCount == limit && fetchedCount > 0);
      }

      // -------------------------------
      // 2. Prepare filter selections
      // -------------------------------
      Map<String, bool> getCategory(String key) =>
          allCategoriesState[key] ?? {};

      final trueSalesDataOptions = getCategory(
        'Sales Data',
      ).entries.where((e) => e.value).map((e) => e.key).toList();

      final trueCategoryOptions = getCategory(
        'Category',
      ).entries.where((e) => e.value).map((e) => e.key).toList();

      final trueDimensionOptions = getCategory(
        'Dimension',
      ).entries.where((e) => e.value).map((e) => e.key).toList();

      final trueRSMOptions = getCategory(
        'RSM',
      ).entries.where((e) => e.value).map((e) => e.key).toList();

      final trueASMOptions = getCategory(
        'ASM',
      ).entries.where((e) => e.value).map((e) => e.key).toList();

      final trueTSMOptions = getCategory(
        'TSM',
      ).entries.where((e) => e.value).map((e) => e.key).toList();

      final trueDueOptions = getCategory(
        'Due/Overdue',
      ).entries.where((e) => e.value).map((e) => e.key).toList();

      final trueAdvanceOptions = getCategory(
        'Advance/Receivables',
      ).entries.where((e) => e.value).map((e) => e.key).toList();

      // -------------------------------
      // 3. Single-pass filtering (FAST)
      // -------------------------------
      final List<DebtorsAgingList> filtered = [];

      for (final person in targetList) {
        // Sales Data
        if (trueSalesDataOptions.isNotEmpty) {
          if (trueSalesDataOptions.contains("Sales Team")) {
            if (person.salesManager == "NH GROUP. - Drs." ||
                person.salesManager == "OFFICE - Drs.") {
              continue;
            }
          } else if (!trueSalesDataOptions.contains(person.salesManager)) {
            continue;
          }
        }

        // Category
        if (trueCategoryOptions.isNotEmpty &&
            !trueCategoryOptions.contains(person.customerGroup)) {
          continue;
        }

        // Dimension
        if (trueDimensionOptions.isNotEmpty &&
            !trueDimensionOptions.contains(person.documentType)) {
          continue;
        }

        // RSM
        if (trueRSMOptions.isNotEmpty &&
            !trueRSMOptions.contains(person.regionalManager)) {
          continue;
        }

        // ASM
        if (trueASMOptions.isNotEmpty &&
            !trueASMOptions.contains(person.salesManager)) {
          continue;
        }

        // TSM
        if (trueTSMOptions.isNotEmpty &&
            !trueTSMOptions.contains(person.salesRep)) {
          continue;
        }

        // Due / Overdue
        if (trueDueOptions.isNotEmpty) {
          if (trueDueOptions.contains("Not Dues") && person.future != "0") {
            continue;
          }

          if (trueDueOptions.contains("Overdue") && person.future == "0") {
            continue;
          }
        }

        // Advance / Receivables
        if (trueAdvanceOptions.isNotEmpty) {
          if (trueAdvanceOptions.contains("Advance") &&
              person.paymentTerms != "Advance") {
            continue;
          }

          if (trueAdvanceOptions.contains("Receivables") &&
              person.paymentTerms == "Advance") {
            continue;
          }
        }

        filtered.add(person);
      }

      // -------------------------------
      // 4. Update UI (lightweight)
      // -------------------------------
      if (!mounted) return;

      setState(() {
        context
            .read<FinanceReceivablesTargetCollectionBIProvider>()
            .updateTargetList(targetList);

        target = filtered;
        targetAPIData = filtered;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }

  Future<void> generateReceivablesExcel(AllReceivablesFinanceList list) async {
    await reportService.generateExcel(
      sheetName: 'Receivables',
      headers: ['Ageing Group', 'Ageing Group Total'],
      rows: list.agingData
          .map((e) => [e.agingGroup, e.agingGroupTotal])
          .toList(),
      fileName: 'receivables.xlsx',
      amountColumns: [2],
      addTotalRow: true,
      reportTitle: 'Finance - Receivables',
    );
  }

  Future<void> generateReceivablesPDF(AllReceivablesFinanceList list) async {
    reportService.generatePDF(
      title: 'Receivables',
      headers: ['Ageing Group', 'Ageing Group Total'],
      rows: list.agingData
          .map((e) => [e.agingGroup, e.agingGroupTotal])
          .toList(),
      fileName: 'receivables.pdf',
      amountColumns: [2],
    );
  }

  Future<void> generateAllReceivablesExcel() async {
    try {
      final rows = _prepareAllReceivablesRows(target);
      await reportService.generateExcel(
        sheetName: 'AllReceivablesExcel',
        headers: [
          'Sales Manager',
          'Regional Manager',
          'Sales Rep',
          'Customer Group',
          'BP Group',
          'Customer Code',
          'Customer Name',
          'Credit Limit',
          'Posting Date',
          'Document Number',
          'Document Ref No',
          'Account Balance',
          'Invoice Issues',
          'Expected Payment',
          'Expected Payment Remarks',
          'Last Receipt Date',
          'Document Type',
          'Payment Terms Days',
          'Payment Terms',
          'Due On',
          'Due Days',
          'Balance',
          'Ageing Brackets',
          'Future',
          '0 - 30',
          '31 - 60',
          '61 - 90',
          '91 - 180',
          '180+',
          'eKart No.',
          'Commitment',
        ],
        rows: rows,
        fileName: 'AllReceivablesExcel.xlsx',
        amountColumns: [8, 12, 22, 24, 25, 26, 27, 28, 29],
        addTotalRow: false,
        reportTitle: 'Finance - Gross Receivables',
      );
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  List<List<dynamic>> _prepareAllReceivablesRows(
    List<DebtorsAgingList> target,
  ) {
    return List.generate(target.length, (i) {
      final e = target[i];

      return [
        e.salesManager,
        e.regionalManager,
        e.salesRep,
        e.customerGroup,
        e.bpGroup,
        e.customerCode,
        e.customerName,
        (double.tryParse(e.creditLimit) ?? 0.0).toStringAsFixed(2),
        e.postingDate,
        e.documentNumber,
        e.documentRefNo,
        (double.tryParse(e.accountBalance) ?? 0.0).toStringAsFixed(2),
        e.invoiceIssues,
        e.expectedPayment,
        e.expectedPaymentRemarks,
        e.lastReceiptDate,
        e.documentType,
        e.paymentTermsDays,
        e.paymentTerms,
        e.dueon,
        e.dueDays,
        (double.tryParse(e.balance) ?? 0.0).toStringAsFixed(2),
        e.ageingBrackets,
        (double.tryParse(e.future) ?? 0.0).toStringAsFixed(2),
        (double.tryParse(e.a0to30Days) ?? 0.0).toStringAsFixed(2),
        (double.tryParse(e.a31to60Days) ?? 0.0).toStringAsFixed(2),
        (double.tryParse(e.a61to90Days) ?? 0.0).toStringAsFixed(2),
        (double.tryParse(e.a91to180Days) ?? 0.0).toStringAsFixed(2),
        (double.tryParse(e.a181Days) ?? 0.0).toStringAsFixed(2),
        e.eKartNo,
        e.commitment,
      ];
    });
  }

  Future<void> generateNetReceivablesExcel(ReceivablesFinanceList list) async {
    try {
      await reportService.generateExcel(
        sheetName: 'NetReceivables',
        headers: ['Ageing Group', 'Ageing Group Total'],
        rows: list.agingData
            .map((e) => [e.agingGroup, e.agingGroupTotal])
            .toList(),
        fileName: 'NetReceivables.xlsx',
        amountColumns: [2],
        addTotalRow: true,
        reportTitle: 'Finance - Net Receivables',
      );
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateNetReceivablesPDF(ReceivablesFinanceList list) async {
    try {
      await reportService.generatePDF(
        title: 'Net Receivables',
        headers: ['Ageing Group', 'Ageing Group Total'],
        rows: list.agingData
            .map((e) => [e.agingGroup, e.agingGroupTotal])
            .toList(),
        fileName: 'NetReceivables.pdf',
        amountColumns: [2],
      );
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateAdvanceExcel(AdvanceFromCustomersList list) async {
    try {
      await reportService.generateExcel(
        sheetName: 'AdvanceFromCustomers',
        headers: ['Ageing Group', 'Ageing Group Total'],
        rows: list.agingData
            .map((e) => [e.agingGroup, e.agingGroupTotal])
            .toList(),
        fileName: 'AdvanceFromCustomers.xlsx',
        amountColumns: [2],
        addTotalRow: true,
        reportTitle: 'Finance - Advance From Customers',
      );
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateAdvancePDF(AdvanceFromCustomersList list) async {
    try {
      await reportService.generatePDF(
        title: 'Advance From Customers',
        headers: ['Ageing Group', 'Ageing Group Total'],
        rows: list.agingData
            .map((e) => [e.agingGroup, e.agingGroupTotal])
            .toList(),
        fileName: 'AdvanceFromCustomers.pdf',
        amountColumns: [2],
      );
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateCustomerAnalysisExcel(
    CustomerAnalysisFinanceList list,
  ) async {
    try {
      await reportService.generateExcel(
        sheetName: 'CustomerAnalysis',
        headers: ['Customer Name', 'Customer Code', 'Collection Amount'],
        rows: list.customerData
            .map(
              (e) => [
                e.customerName,
                e.customerCode,
                e.collectionAmount.toStringAsFixed(2),
              ],
            )
            .toList(),
        fileName: 'CustomerAnalysis.xlsx',
        amountColumns: [3],
        addTotalRow: true,
        reportTitle: 'Finance - Customer Analysis',
      );
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateCustomerAnalysisPDF(
    CustomerAnalysisFinanceList list,
  ) async {
    try {
      await reportService.generatePDF(
        title: 'Customer Analysis',
        headers: ['Customer Name', 'Customer Code', 'Collection Amount'],
        rows: list.customerData
            .map(
              (e) => [
                e.customerName,
                e.customerCode,
                e.collectionAmount.toStringAsFixed(2),
              ],
            )
            .toList(),
        fileName: 'CustomerAnalysis.pdf',
        amountColumns: [2],
      );
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateRegionalManagerExcel(RsmwiseCollectionList list) async {
    try {
      await reportService.generateExcel(
        sheetName: 'RegionalManagerReceivables',
        headers: ['Regional Manager', 'Amount'],
        rows: list.rsmwiseData
            .map((e) => [e.rsmName, e.collectionAmount.toStringAsFixed(2)])
            .toList(),
        fileName: 'RegionalManagerReceivables.xlsx',
        amountColumns: [2],
        addTotalRow: true,
        reportTitle: 'Finance - RSM Analysis',
      );
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateRegionalManagerPDF(RsmwiseCollectionList list) async {
    try {
      await reportService.generatePDF(
        title: 'Regional Manager Receivables',
        headers: ['Regional Manager', 'Amount'],
        rows: list.rsmwiseData
            .map((e) => [e.rsmName, e.collectionAmount.toStringAsFixed(2)])
            .toList(),
        fileName: 'RegionalManagerReceivables.pdf',
        amountColumns: [2],
      );
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSalesManagerExcel(AsmwiseCollectionList list) async {
    try {
      await reportService.generateExcel(
        sheetName: 'SalesManagerReceivables',
        headers: ['Sales Manager', 'Amount'],
        rows: list.asmwiseData
            .map((e) => [e.asmName, e.collectionAmount.toStringAsFixed(2)])
            .toList(),
        fileName: 'SalesManagerReceivables.xlsx',
        amountColumns: [2],
        addTotalRow: true,
        reportTitle: 'Finance - ASM Analysis',
      );
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSalesManagerPDF(AsmwiseCollectionList list) async {
    try {
      await reportService.generatePDF(
        title: 'Sales Manager Receivables',
        headers: ['Sales Manager', 'Amount'],
        rows: list.asmwiseData
            .map((e) => [e.asmName, e.collectionAmount.toStringAsFixed(2)])
            .toList(),
        fileName: 'SalesManagerReceivables.pdf',
        amountColumns: [2],
      );
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSalesPersonExcel(TsmwiseCollectionList list) async {
    try {
      await reportService.generateExcel(
        sheetName: 'TSMReceivables',
        headers: ['TSM Name', 'Amount'],
        rows: list.tsmwiseData
            .map((e) => [e.tsmName, e.collectionAmount.toStringAsFixed(2)])
            .toList(),
        fileName: 'TSMReceivables.xlsx',
        amountColumns: [2],
        addTotalRow: true,
        reportTitle: 'Finance - TSM Analysis',
      );
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateSalesPersonPDF(TsmwiseCollectionList list) async {
    try {
      await reportService.generatePDF(
        title: 'TSM Receivables',
        headers: ['TSM Name', 'Amount'],
        rows: list.tsmwiseData
            .map((e) => [e.tsmName, e.collectionAmount.toStringAsFixed(2)])
            .toList(),
        fileName: 'TSMReceivables.pdf',
        amountColumns: [2],
      );
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _dateFilterTarget(String UserName, String UserLevel) async {
    setState(() {
      target = target.where((target) {
        DateTime dueon = target.parsedDueDate;
        return (dueon.isAtMost(toDateFilter!));
      }).toList();
      context
          .read<FinanceReceivablesTargetCollectionBIProvider>()
          .updateTargetList(target);
    });
  }

  Future<void> loadData(String selectedUser) async {
    if (!mounted) return;
    setState(() {
      chartDataLoadedReceivables = false;
    });

    // -------------------------------
    // 1. Load preferences (once)
    // -------------------------------

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final userLevel = prefs.getString('userLevel') ?? '';
    final parsedUserLevel = int.tryParse(userLevel) ?? 0;

    final userName = selectedUser.isEmpty
        ? (prefs.getString('userName') ?? '')
        : selectedUser;

    UserLevel = userLevel;

    // -------------------------------
    // 2. Run API calls in parallel
    // -------------------------------
    await _loadUserList(userId, userJwtToken, userMailID, parsedUserLevel);
    await _loadUserListForFilter(
      userId,
      userJwtToken,
      userMailID,
      parsedUserLevel,
    );
    await _loadCollectionTarget(userName, userLevel, fromFilter);
    await Future.wait([
      _loadReceivablesData("", "", "", "", "", "", ""),
      _loadNetReceivablesData("", "", "", "", "", "", ""),
      _loadAdvanceFromCustomers("", "", "", "", "", "", ""),
      _loadCustomerAnalysis("", "", "", "", "", "", ""),
      _loadTSMCollectionBarChartData("", "", "", "", "", "", ""),
      _loadASMCollectionBarChartData("", "", "", "", "", "", ""),
      _loadRSMCollectionBarChartData("", "", "", "", "", "", ""),
    ]);

    if (receivablesCategoryList.categoryData.isEmpty) {
      await _loadCustomerCategoryWise();
    }
    await applyFinanceReceivablesVariables();
  }

  Future<void> applyFinanceReceivablesVariables() async {
    // -------------------------------
    // 1. Initialize variables
    // -------------------------------
    double sum = 0;
    double overDueSum = 0;
    double notDue = 0;
    DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);

    final currentDateLocal = normalize(currentDate!);
    // -------------------------------
    // 2. Single loop calculation
    // -------------------------------

    for (var t in target) {
      final postingDate = normalize(t.parsedPostingDate);
      if (postingDate.isAfter(currentDateLocal)) continue;

      final dueOn = normalize(t.parsedDueDate);

      double balance = double.tryParse(t.balance) ?? 0;

      // Overdue
      if (!dueOn.isAfter(currentDateLocal)) {
        sum += balance;
        overDueSum += balance;
      }

      if (t.ageingBrackets == 'Future') {
        notDue += balance;
      }
    }

    // -------------------------------
    // 3. Compute values
    // -------------------------------
    double receivablesAmount = notDue + overDueSum;
    double overDue = overDueSum;

    double netReceivables = sum - advance;
    double grossReceivables = sum;

    // -------------------------------
    // 4. Percentages
    // -------------------------------
    receivablePercentage = 0;
    if (overDue != 0 && receivablesAmount != 0) {
      receivablePercentage = double.parse(
        ((overDue / receivablesAmount) * 100).toStringAsFixed(2),
      ).ceilToDouble();
    }
    if (receivablePercentage > 100) receivablePercentage = 100;

    netReceivablePercentage = 0;
    if (advance != 0 && netReceivables != 0) {
      netReceivablePercentageLocal = double.parse(
        ((advance / netReceivables) * 100).toStringAsFixed(2),
      ).ceilToDouble();
    }
    if (netReceivablePercentageLocal > 100) netReceivablePercentageLocal = 100;
    if (netReceivablePercentageLocal.isNegative) {
      netReceivablePercentageLocal = netReceivablePercentageLocal.abs();
    }
    // -------------------------------
    // 5. Update UI
    // -------------------------------
    if (!mounted) return;
    setState(() {
      netReceivablePercentage = netReceivablePercentageLocal;

      receivablesAmountStr = formatAmount(receivablesAmount.abs());

      overDueStr = formatAmount(overDue.abs());

      notDueStr = formatAmount(notDue.abs());

      advanceStr = formatAmount(advance.abs());

      netReceivablesStr = formatAmount(netReceivables.abs());

      grossReceivablesStr = formatAmount(grossReceivables.abs());

      filterOptions = [
        ['OFFICE - Drs.', 'NH GROUP. - Drs.', 'Sales Team'],
        ['Hospital', 'Distributor', 'Other'],
        ['Credit Note', 'Invoice', 'Journal', 'Receipt'],
        listOfRSM,
        listOfASM,
        listOfTSM,
        ['Not Dues', 'Overdue'],
        ['Advance', 'Receivables'],
        [],
      ];

      savedFinanceReceivablesOptions =
          savedFinanceReceivablesOptionsTemp.isEmpty
          ? filterOptions
                .map((options) => List<bool>.filled(options.length, false))
                .toList()
          : savedFinanceReceivablesOptionsTemp;

      chartDataLoadedReceivables = true;
    });
  }

  void resetFinanceReceivablesOptions() {
    setState(() {
      savedFinanceReceivablesOptions = List.from(
        selectedFinanceReceivablesOptions,
      );
    });
  }

  List<DebtorsAgingList> filterCollectionTargetList(
    List<DebtorsAgingList> collectionTargetList,
    List<Users> userNames, {
    String? regionalManager,
    String? salesManager,
    String? salesRep,
    String? customer,
    String? receivableCatg,
    String? netReceivableCatg,
    String? advanceCatg,
  }) {
    bool regionalManagerCondition = true;
    bool salesManagerCondition = true;
    List<DebtorsAgingList> filteredCollectionTargetList = [];
    double dueFromReceivable = 0.0;
    double dueToReceivable = double.infinity;
    double dueFromNetReceivable = 0.0;
    double dueToNetReceivable = double.infinity;
    double dueFromAdvance = 0.0;
    double dueToAdvance = double.infinity;
    if (receivableCatg != null && receivableCatg != "") {
      if (receivableCatg == "0-30") {
        dueFromReceivable = 0;
        dueToReceivable = 30;
      } else if (receivableCatg == "31-60") {
        dueFromReceivable = 31;
        dueToReceivable = 60;
      } else if (receivableCatg == "61-90") {
        dueFromReceivable = 61;
        dueToReceivable = 90;
      } else if (receivableCatg == "91-180") {
        dueFromReceivable = 91;
        dueToReceivable = 180;
      } else if (receivableCatg == "180+") {
        dueFromReceivable = 181;
        dueToReceivable = double.infinity;
      }
    }
    if (netReceivableCatg != null && netReceivableCatg != "") {
      if (netReceivableCatg == "0-30") {
        dueFromNetReceivable = 0;
        dueToNetReceivable = 30;
      } else if (netReceivableCatg == "31-60") {
        dueFromNetReceivable = 31;
        dueToNetReceivable = 60;
      } else if (netReceivableCatg == "61-90") {
        dueFromNetReceivable = 61;
        dueToNetReceivable = 90;
      } else if (netReceivableCatg == "91-180") {
        dueFromNetReceivable = 91;
        dueToNetReceivable = 180;
      } else if (netReceivableCatg == "180+") {
        dueFromNetReceivable = 181;
        dueToNetReceivable = double.infinity;
      }
    }
    if (advanceCatg != null && advanceCatg != "") {
      if (advanceCatg == "0-30") {
        dueFromAdvance = 0;
        dueToAdvance = 30;
      } else if (advanceCatg == "31-60") {
        dueFromAdvance = 31;
        dueToAdvance = 60;
      } else if (advanceCatg == "61-90") {
        dueFromAdvance = 61;
        dueToAdvance = 90;
      } else if (advanceCatg == "91-180") {
        dueFromAdvance = 91;
        dueToAdvance = 180;
      } else if (advanceCatg == "180+") {
        dueFromAdvance = 181;
        dueToAdvance = double.infinity;
      }
    }
    for (var target in collectionTargetList) {
      double overDueDayReceivables =
          double.tryParse(target.dueDays.replaceAll(' Days', '')) ?? 0;
      if (regionalManager != null && regionalManager.isNotEmpty) {
        int? regionalManagerMenuId = userNames
            .firstWhere(
              (element) => element.menuName == regionalManager,
              orElse: () => Users(
                menuId: -1,
                menuName: '',
                subMenuId: -1,
                parentMenuId: -1,
                userLevel: -1,
              ),
            )
            .menuId;
        List<String> childMenuNames = userNames
            .where((element) => element.parentMenuId == regionalManagerMenuId)
            .map((user) => user.menuName)
            .toList();
        regionalManagerCondition =
            regionalManagerMenuId != -1 &&
            childMenuNames.contains(target.salesManager);
      }

      if (salesManager != null && salesManager.isNotEmpty) {
        int? salesManagerMenuId = userNames
            .firstWhere(
              (element) => element.menuName == salesManager,
              orElse: () => Users(
                menuId: -1,
                menuName: '',
                subMenuId: -1,
                parentMenuId: -1,
                userLevel: -1,
              ),
            )
            .menuId;
        List<String> childMenuNames = userNames
            .where((element) => element.parentMenuId == salesManagerMenuId)
            .map((user) => user.menuName)
            .toList();
        salesManagerCondition =
            salesManagerMenuId != -1 &&
            childMenuNames.contains(target.salesRep);
      }
      if (!regionalManagerCondition || !salesManagerCondition) {
        continue;
      }
      if ((regionalManager == null ||
              regionalManager.isEmpty ||
              target.regionalManager == regionalManager) &&
          (salesManager == null ||
              salesManager.isEmpty ||
              target.salesManager == salesManager) &&
          (salesRep == null ||
              salesRep.isEmpty ||
              target.salesRep == salesRep) &&
          (customer == null ||
              customer.isEmpty ||
              target.customerName == customer) &&
          (receivableCatg == null ||
              receivableCatg.isEmpty ||
              (overDueDayReceivables >= dueFromReceivable &&
                  overDueDayReceivables <= dueToReceivable)) &&
          (netReceivableCatg == null ||
              netReceivableCatg.isEmpty ||
              (overDueDayReceivables >= dueFromNetReceivable &&
                  overDueDayReceivables <= dueToNetReceivable)) &&
          (advanceCatg == null ||
              advanceCatg.isEmpty ||
              (overDueDayReceivables >= dueFromAdvance &&
                  overDueDayReceivables <= dueToAdvance))) {
        filteredCollectionTargetList.add(target);
      }
    }
    return filteredCollectionTargetList;
  }

  Future<void> loadDataWithFilter(
    String? receivableId,
    String netReceivableId,
    String? advanceId,
    String? customer,
    String? regionalManager,
    String? salesManager,
    String? salesPerson,
  ) async {
    clearVariablesForFilter();
    setState(() {
      chartDataLoadedReceivables = false;
    });
    LoadDates();
    await applyDetailedFilterFunction();
    await Future.wait([
      _loadReceivablesData(
        receivableId!,
        netReceivableId,
        advanceId!,
        customer!,
        regionalManager!,
        salesManager!,
        salesPerson!,
      ),
      _loadNetReceivablesData(
        receivableId,
        netReceivableId,
        advanceId,
        customer,
        regionalManager,
        salesManager,
        salesPerson,
      ),
      _loadAdvanceFromCustomers(
        receivableId,
        netReceivableId,
        advanceId,
        customer,
        regionalManager,
        salesManager,
        salesPerson,
      ),
      _loadCustomerAnalysis(
        receivableId,
        netReceivableId,
        advanceId,
        customer,
        regionalManager,
        salesManager,
        salesPerson,
      ),
      _loadTSMCollectionBarChartData(
        receivableId,
        netReceivableId,
        advanceId,
        customer,
        regionalManager,
        salesManager,
        salesPerson,
      ),
      _loadASMCollectionBarChartData(
        receivableId,
        netReceivableId,
        advanceId,
        customer,
        regionalManager,
        salesManager,
        salesPerson,
      ),
      _loadRSMCollectionBarChartData(
        receivableId,
        netReceivableId,
        advanceId,
        customer,
        regionalManager,
        salesManager,
        salesPerson,
      ),
    ]);
    if (receivablesCategoryList.categoryData.isEmpty) {
      await _loadCustomerCategoryWise();
    }

    await applyFinanceReceivablesVariables();
    setState(() {
      chartDataLoadedReceivables = true;
    });
  }

  void clearVariables() {
    setState(() {
      chartDataLoadedReceivables = false;
      receivablesFinanceList = ReceivablesFinanceList(agingData: []);
      allReceivablesFinanceList = AllReceivablesFinanceList(agingData: []);
      advanceCustomerList = AdvanceFromCustomersList(agingData: []);
      customerAnalysisFinanceList = CustomerAnalysisFinanceList(
        customerData: [],
      );
      tsmwiseCollectionList = TsmwiseCollectionList(tsmwiseData: []);
      asmwiseCollectionList = AsmwiseCollectionList(asmwiseData: []);
      rsmwiseCollectionList = RsmwiseCollectionList(rsmwiseData: []);
      touchedReceivables = "";
      touchedNetReceivables = "";
      touchedAdvance = "";
      touchedCustomer = "";
      touchedRegionalManager = "";
      touchedSalesManager = "";
      touchedSalesPerson = "";
      toDateFilter = currentDate;
      fromDateFilter = fiscalYearStartDate;
    });
  }

  void clearVariablesForFilter() {
    setState(() {
      chartDataLoadedReceivables = false;
      receivablesFinanceList = ReceivablesFinanceList(agingData: []);
      allReceivablesFinanceList = AllReceivablesFinanceList(agingData: []);
      advanceCustomerList = AdvanceFromCustomersList(agingData: []);
      customerAnalysisFinanceList = CustomerAnalysisFinanceList(
        customerData: [],
      );
      tsmwiseCollectionList = TsmwiseCollectionList(tsmwiseData: []);
      asmwiseCollectionList = AsmwiseCollectionList(asmwiseData: []);
      rsmwiseCollectionList = RsmwiseCollectionList(rsmwiseData: []);
    });
  }

  void toggleCheckbox() {
    setState(() {
      receivablesAmount = 0;
      overDue = 0;
      notDue = 0;
      netReceivables = 0;
      advance = 0;
      grossReceivables = 0;
      chartDataLoadedReceivables = false;
      receivablesAmountStr = "";
      loadData("");
    });
  }

  Future<void> applyDetailedFilterFunction() async {
    final prefs = await SharedPreferences.getInstance();
    final userLevel = prefs.getString('userLevel') ?? '';
    UserLevel = userLevel;
    receivablesAmount = 0;
    overDue = 0;
    notDue = 0;
    netReceivables = 0;
    advance = 0;
    grossReceivables = 0;
    receivablesAmountStr = "";
    target = targetAPIData;

    await _dateFilterTarget("", "");

    // -------------------------------
    // 1. Prepare filter selections
    // -------------------------------
    Map<String, bool> getCategory(String key) => allCategoriesState[key] ?? {};

    final trueSalesDataOptions = getCategory(
      'Sales Data',
    ).entries.where((e) => e.value).map((e) => e.key).toList();

    final trueCategoryOptions = getCategory(
      'Category',
    ).entries.where((e) => e.value).map((e) => e.key).toList();

    final trueDimensionOptions = getCategory(
      'Dimension',
    ).entries.where((e) => e.value).map((e) => e.key).toList();

    final trueRSMOptions = getCategory(
      'RSM',
    ).entries.where((e) => e.value).map((e) => e.key).toList();

    final trueASMOptions = getCategory(
      'ASM',
    ).entries.where((e) => e.value).map((e) => e.key).toList();

    final trueTSMOptions = getCategory(
      'TSM',
    ).entries.where((e) => e.value).map((e) => e.key).toList();

    final trueDueOptions = getCategory(
      'Due/Overdue',
    ).entries.where((e) => e.value).map((e) => e.key).toList();

    final trueAdvanceOptions = getCategory(
      'Advance/Receivables',
    ).entries.where((e) => e.value).map((e) => e.key).toList();

    // -------------------------------
    // 2. Single-pass filtering (FAST)
    // -------------------------------
    final List<DebtorsAgingList> filtered = [];

    for (final trgt in targetAPIData) {
      // Sales Data
      if (trueSalesDataOptions.isNotEmpty) {
        if (trueSalesDataOptions.contains("Sales Team")) {
          if (trgt.salesManager == "NH GROUP. - Drs." ||
              trgt.salesManager == "OFFICE - Drs.") {
            continue;
          }
        } else if (!trueSalesDataOptions.contains(trgt.salesManager)) {
          continue;
        }
      }

      // Category
      if (trueCategoryOptions.isNotEmpty &&
          !trueCategoryOptions.contains(trgt.customerGroup)) {
        continue;
      }

      // Dimension
      if (trueDimensionOptions.isNotEmpty &&
          !trueDimensionOptions.contains(trgt.documentType)) {
        continue;
      }

      // RSM
      if (trueRSMOptions.isNotEmpty &&
          !trueRSMOptions.contains(trgt.regionalManager)) {
        continue;
      }

      // ASM
      if (trueASMOptions.isNotEmpty &&
          !trueASMOptions.contains(trgt.salesManager)) {
        continue;
      }

      // TSM
      if (trueTSMOptions.isNotEmpty &&
          !trueTSMOptions.contains(trgt.salesRep)) {
        continue;
      }

      // Due / Overdue
      if (trueDueOptions.isNotEmpty) {
        if (trueDueOptions.contains("Not Dues") && trgt.future != "0") {
          continue;
        }

        if (trueDueOptions.contains("Overdue") && trgt.future == "0") {
          continue;
        }
      }

      // Advance / Receivables
      if (trueAdvanceOptions.isNotEmpty) {
        if (trueAdvanceOptions.contains("Advance") &&
            trgt.paymentTerms != "Advance") {
          continue;
        }

        if (trueAdvanceOptions.contains("Receivables") &&
            trgt.paymentTerms == "Advance") {
          continue;
        }
      }

      filtered.add(trgt);
    }
    target = filtered;
  }

  Future<void> removeFilter() async {
    setState(() {
      chartDataLoadedReceivables = false;
    });
    clearVariables();
    LoadDates();
    receivablesAmountStr = "";
    receivablesAmount = 0;
    allCategoriesState.forEach((category, options) {
      options.updateAll((key, value) => false);
    });
    allCategoriesState.clear();
    await loadData("");
    setState(() {
      chartDataLoadedReceivables = true;
    });
  }

  Widget buildCheckbox(int index) {
    return GestureDetector(
      onTap: () => toggleCheckbox(),
      child: Checkbox(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.0)),
        side: WidgetStateBorderSide.resolveWith(
          (states) => const BorderSide(width: 1.0, color: Color(0xFF8F8F8F)),
        ),
        value: selectedCheckbox == index,
        onChanged: (_) => toggleCheckbox(),
      ),
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

  @override
  void initState() {
    super.initState();
    LoadDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
      toDateFilter = currentDate;
      fromDateFilter = fiscalYearStartDate;
    }

    filterOptions = [
      ['OFFICE - Drs.', 'NH GROUP. - Drs.', 'Sales Team'],
      ['Hospital', 'Distributor', 'Other'],
      ['Credit Note', 'Invoice', 'Journal', 'Receipt'],
      listOfRSM,
      listOfASM,
      listOfTSM,
      ['Not Dues', 'Overdue'],
      ['Advance', 'Receivables'],
      [],
    ];

    selectedFinanceReceivablesOptions = filterOptions
        .map((options) => List<bool>.filled(options.length, false))
        .toList();

    selectedFinanceReceivablesOptions = savedFinanceReceivablesOptions;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DateTime currentDate = DateTime.now();
    selectedFinanceReceivablesOptions = savedFinanceReceivablesOptions;
    return chartDataLoadedReceivables
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
                        Row(
                          children: [
                            PopupMenuButton(
                              onSelected: (value) {},
                              itemBuilder: (BuildContext bc) {
                                return [
                                  PopupMenuItem(
                                    onTap: () {
                                      setState(() {
                                        generateAllReceivablesExcel();
                                      });
                                    },
                                    child: const Text("Download Excel"),
                                  ),
                                ];
                              },
                            ),
                          ],
                        ),
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
                const SizedBox(height: 20),
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
                                radius: 75.0,
                                lineWidth: 30.0,
                                animation: true,
                                percent: receivablePercentage / 100,
                                curve: Curves.linear,
                                circularStrokeCap: CircularStrokeCap.butt,
                                progressColor: const Color(0xFF2CA9DF),
                                arcBackgroundColor: const Color(0xFF97D7F3),
                                center: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 70),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Receivables: $receivablesAmountStr",
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
                                        Container(
                                          height: 10,
                                          width: 10,
                                          color: const Color(0xFF2CA9DF),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "Over Due $overDueStr",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 10.0,
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
                                        Container(
                                          height: 10,
                                          width: 10,
                                          color: const Color(0xFFB8ECFF),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "Not Due $notDueStr",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
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
                                radius: 75.0,
                                lineWidth: 30.0,
                                animation: true,
                                percent: netReceivablePercentage / 100,
                                curve: Curves.linear,
                                circularStrokeCap: CircularStrokeCap.butt,
                                progressColor: const Color(0xFF2CA9DF),
                                arcBackgroundColor: const Color(0xFF97D7F3),
                                center: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 70),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Net Receivables: $netReceivablesStr",
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
                                        Container(
                                          height: 10,
                                          width: 10,
                                          color: const Color(0xFF2CA9DF),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "Advance $advanceStr",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 10.0,
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
                                        Container(
                                          height: 10,
                                          width: 10,
                                          color: const Color(0xFF97D7F3),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "Receivables $grossReceivablesStr",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
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
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),

                Visibility(
                  visible: allReceivablesFinanceList.agingData.isNotEmpty,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(width: 15),
                              Text(
                                "Receivables",
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
                                      onTap: () async {
                                        await generateReceivablesExcel(
                                          allReceivablesFinanceList,
                                        );
                                      },
                                      child: const Text("Download Excel"),
                                    ),
                                    PopupMenuItem(
                                      onTap: () async {
                                        await generateReceivablesPDF(
                                          allReceivablesFinanceList,
                                        );
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
                        child: _receivables(),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0, right: 16.0),
                        child: Divider(thickness: 2),
                      ),
                    ],
                  ),
                ),

                Visibility(
                  visible: receivablesFinanceList.agingData.isNotEmpty,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(width: 15),
                              Text(
                                "Net Receivables",
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
                                      onTap: () async {
                                        await generateNetReceivablesExcel(
                                          receivablesFinanceList,
                                        );
                                      },
                                      child: const Text("Download Excel"),
                                    ),
                                    PopupMenuItem(
                                      onTap: () async {
                                        await generateNetReceivablesPDF(
                                          receivablesFinanceList,
                                        );
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
                        child: _netReceivables(),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0, right: 16.0),
                        child: Divider(thickness: 2),
                      ),
                    ],
                  ),
                ),

                Visibility(
                  visible: advanceCustomerList.agingData.isNotEmpty,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(width: 15),
                              Text(
                                "Advance From Customers",
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
                                      onTap: () async {
                                        await generateAdvanceExcel(
                                          advanceCustomerList,
                                        );
                                      },
                                      child: const Text("Download Excel"),
                                    ),
                                    PopupMenuItem(
                                      onTap: () async {
                                        await generateAdvancePDF(
                                          advanceCustomerList,
                                        );
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
                        child: _advanceFromCustomers(),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0, right: 16.0),
                        child: Divider(thickness: 2),
                      ),
                    ],
                  ),
                ),

                Visibility(
                  visible: customerAnalysisFinanceList.customerData.isNotEmpty,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(width: 15),
                              Text(
                                "Customer Analysis",
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
                                      onTap: () async {
                                        await generateCustomerAnalysisExcel(
                                          customerAnalysisFinanceList,
                                        );
                                      },
                                      child: const Text("Download Excel"),
                                    ),
                                    PopupMenuItem(
                                      onTap: () async {
                                        await generateCustomerAnalysisPDF(
                                          customerAnalysisFinanceList,
                                        );
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
                        child: _customerAnalysis(),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0, right: 16.0),
                        child: Divider(thickness: 2),
                      ),
                    ],
                  ),
                ),

                Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(width: 15),
                            Text(
                              "Customer Category wise Analysis",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        bottom: 16.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(
                            height: 250,
                            width: 100,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback:
                                      (FlTouchEvent event, pieTouchResponse) {},
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 1,
                                centerSpaceRadius: 0,
                                startDegreeOffset: 360,
                                sections: _receivablesCategoryChart(),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          height: 8,
                                          width: 16,
                                          color: const Color(0xFFFF9F47),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          height: 8,
                                          width: 16,
                                          color: const Color(0xFF97D7F3),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          height: 8,
                                          width: 16,
                                          color: const Color(0xFF78E25D),
                                        ),
                                        const SizedBox(height: 6),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // for (final categoryData
                                  // in receivablesCategoryList.categoryData)
                                  Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      "Distributor",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      "Hospital",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      "Other",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0, right: 16.0),
                      child: Divider(thickness: 2),
                    ),
                  ],
                ),

                Visibility(
                  visible: rsmwiseCollectionList.rsmwiseData.isNotEmpty,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(width: 15),
                              Text(
                                "Regional Manager Analysis",
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
                                      onTap: () async {
                                        await generateRegionalManagerExcel(
                                          rsmwiseCollectionList,
                                        );
                                      },
                                      child: const Text("Download Excel"),
                                    ),
                                    PopupMenuItem(
                                      onTap: () async {
                                        await generateRegionalManagerPDF(
                                          rsmwiseCollectionList,
                                        );
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
                        child: _regionalManagerAnalysis(),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0, right: 16.0),
                        child: Divider(thickness: 2),
                      ),
                    ],
                  ),
                ),

                Visibility(
                  visible: asmwiseCollectionList.asmwiseData.isNotEmpty,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(width: 15),
                              Text(
                                "Sales Manager Analysis",
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
                                      onTap: () async {
                                        await generateSalesManagerExcel(
                                          asmwiseCollectionList,
                                        );
                                      },
                                      child: const Text("Download Excel"),
                                    ),
                                    PopupMenuItem(
                                      onTap: () async {
                                        await generateSalesManagerPDF(
                                          asmwiseCollectionList,
                                        );
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
                        child: _salesManagerAnalysis(),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0, right: 16.0),
                        child: Divider(thickness: 2),
                      ),
                    ],
                  ),
                ),

                Visibility(
                  visible: tsmwiseCollectionList.tsmwiseData.isNotEmpty,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(width: 15),
                              Text(
                                "Sales Person Analysis",
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
                                      onTap: () async {
                                        await generateSalesPersonExcel(
                                          tsmwiseCollectionList,
                                        );
                                      },
                                      child: const Text("Download Excel"),
                                    ),
                                    PopupMenuItem(
                                      onTap: () async {
                                        await generateSalesPersonPDF(
                                          tsmwiseCollectionList,
                                        );
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
                        child: _salesPersonAnalysis(),
                      ),
                    ],
                  ),
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

  Widget _receivables() {
    final screenWidth = MediaQuery.of(context).size.width;
    int len = allReceivablesFinanceList.agingData.length;
    double maxAmount = len > 0
        ? allReceivablesFinanceList.agingData
              .map((data) => data.agingGroupTotal)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: screenWidth,
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
                sideTitles: _bottomTitlesReceivableAging,
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
            barGroups: _AllReceivableAgingChartData(
              allReceivablesFinanceList.agingData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedReceivables = touchedReceivables == ""
                          ? allReceivablesFinanceList
                                .agingData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .agingGroup
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedReceivables,
                        touchedNetReceivables,
                        touchedAdvance,
                        touchedCustomer,
                        touchedRegionalManager,
                        touchedSalesManager,
                        touchedSalesPerson,
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
                    '',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            '${allReceivablesFinanceList.agingData[0].agingGroup} :'
                            ' ${(formatAmount(allReceivablesFinanceList.agingData[0].agingGroupTotal))} \n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${allReceivablesFinanceList.agingData[1].agingGroup} '
                            ': ${(formatAmount(allReceivablesFinanceList.agingData[1].agingGroupTotal))}\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${allReceivablesFinanceList.agingData[2].agingGroup} '
                            ': ${(formatAmount(allReceivablesFinanceList.agingData[2].agingGroupTotal))} \n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${allReceivablesFinanceList.agingData[3].agingGroup} '
                            ':${(formatAmount(allReceivablesFinanceList.agingData[3].agingGroupTotal))}\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${allReceivablesFinanceList.agingData[4].agingGroup} '
                            ': ${(formatAmount(allReceivablesFinanceList.agingData[4].agingGroupTotal))}\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${allReceivablesFinanceList.agingData[5].agingGroup} '
                            ': ${(formatAmount(allReceivablesFinanceList.agingData[5].agingGroupTotal))}\n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Total'
                            ': ${formatAmount((allReceivablesFinanceList.agingData[5].agingGroupTotal + allReceivablesFinanceList.agingData[4].agingGroupTotal + allReceivablesFinanceList.agingData[3].agingGroupTotal + allReceivablesFinanceList.agingData[2].agingGroupTotal + allReceivablesFinanceList.agingData[1].agingGroupTotal + allReceivablesFinanceList.agingData[0].agingGroupTotal))} ',
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

  Widget _netReceivables() {
    final screenWidth = MediaQuery.of(context).size.width;
    int len = receivablesFinanceList.agingData.length;
    double maxAmount = len > 0
        ? receivablesFinanceList.agingData
              .map((data) => data.agingGroupTotal)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: screenWidth,
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
                sideTitles: _bottomTitlesNetReceivableAging,
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
            barGroups: _netReceivableAgingChartData(
              receivablesFinanceList.agingData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedNetReceivables = touchedNetReceivables == ""
                          ? receivablesFinanceList
                                .agingData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .agingGroup
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedReceivables,
                        touchedNetReceivables,
                        touchedAdvance,
                        touchedCustomer,
                        touchedRegionalManager,
                        touchedSalesManager,
                        touchedSalesPerson,
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
                    '',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            '${receivablesFinanceList.agingData[0].agingGroup} :'
                            ' ${formatAmount(receivablesFinanceList.agingData[0].agingGroupTotal)} \n ',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${receivablesFinanceList.agingData[1].agingGroup} '
                            ': ${formatAmount(receivablesFinanceList.agingData[1].agingGroupTotal)} \n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${receivablesFinanceList.agingData[2].agingGroup} '
                            ':  ${formatAmount(receivablesFinanceList.agingData[2].agingGroupTotal)} \n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${receivablesFinanceList.agingData[3].agingGroup} '
                            ':  ${formatAmount(receivablesFinanceList.agingData[3].agingGroupTotal)} \n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${receivablesFinanceList.agingData[4].agingGroup} '
                            ':  ${formatAmount(receivablesFinanceList.agingData[4].agingGroupTotal)} \n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${receivablesFinanceList.agingData[5].agingGroup} '
                            ':  ${formatAmount(receivablesFinanceList.agingData[5].agingGroupTotal)} \n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Total'
                            ': ${(formatAmount(receivablesFinanceList.agingData[5].agingGroupTotal + receivablesFinanceList.agingData[4].agingGroupTotal + receivablesFinanceList.agingData[3].agingGroupTotal + receivablesFinanceList.agingData[2].agingGroupTotal + receivablesFinanceList.agingData[1].agingGroupTotal + receivablesFinanceList.agingData[0].agingGroupTotal))} ',
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

  Widget _advanceFromCustomers() {
    final screenWidth = MediaQuery.of(context).size.width;
    int len = advanceCustomerList.agingData.length;
    double maxAmount = len > 0
        ? advanceCustomerList.agingData
              .map((data) => data.agingGroupTotal)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: screenWidth,
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
                sideTitles: _bottomTitlesAdvanceFromCustomer,
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
            barGroups: _advanceFromCustomerChartData(
              advanceCustomerList.agingData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedAdvance = touchedAdvance == ""
                          ? advanceCustomerList
                                .agingData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .agingGroup
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedReceivables,
                        touchedNetReceivables,
                        touchedAdvance,
                        touchedCustomer,
                        touchedRegionalManager,
                        touchedSalesManager,
                        touchedSalesPerson,
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
                    '',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            '${advanceCustomerList.agingData[0].agingGroup} :'
                            ' ${formatAmount(advanceCustomerList.agingData[0].agingGroupTotal)} \n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${advanceCustomerList.agingData[1].agingGroup} '
                            ': ${formatAmount(advanceCustomerList.agingData[1].agingGroupTotal)} \n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${advanceCustomerList.agingData[2].agingGroup} '
                            ': ${formatAmount(advanceCustomerList.agingData[2].agingGroupTotal)} \n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${advanceCustomerList.agingData[3].agingGroup} '
                            ': ${formatAmount(advanceCustomerList.agingData[3].agingGroupTotal)} \n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${advanceCustomerList.agingData[4].agingGroup} '
                            ': ${formatAmount(advanceCustomerList.agingData[4].agingGroupTotal)} \n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${advanceCustomerList.agingData[5].agingGroup} '
                            ': ${formatAmount(advanceCustomerList.agingData[5].agingGroupTotal)} \n',
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Total'
                            ': ${(formatAmount(advanceCustomerList.agingData[5].agingTotal))} ',
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

  Widget _customerAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double barChartWidth = 0.0;
    int length = customerAnalysisFinanceList.customerData.length;
    length > 6
        ? barChartWidth = screenWidth + (35 * length)
        : barChartWidth = screenWidth;

    final amounts = customerAnalysisFinanceList.customerData
        .map((e) => e.collectionAmount)
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
        width: barChartWidth,
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
                sideTitles: _bottomTitlesCustomerAnalysis,
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
            barGroups: _customerAnalysisChartData(
              customerAnalysisFinanceList.customerData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedCustomer = touchedCustomer == ""
                          ? customerAnalysisFinanceList
                                .customerData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .customerName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedReceivables,
                        touchedNetReceivables,
                        touchedAdvance,
                        touchedCustomer,
                        touchedRegionalManager,
                        touchedSalesManager,
                        touchedSalesPerson,
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
                    '${customerAnalysisFinanceList.customerData[grpIndex].customerName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: formatAmount(
                          customerAnalysisFinanceList
                              .customerData[grpIndex]
                              .collectionAmount,
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

  Widget _regionalManagerAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = rsmwiseCollectionList.rsmwiseData.length;
    if (rsmwiseCollectionList.rsmwiseData.length > 5) {
      chartWidth = screenWidth + (35 * len);
    } else {
      chartWidth = screenWidth;
    }

    final amounts = rsmwiseCollectionList.rsmwiseData
        .map((e) => e.collectionAmount)
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
                sideTitles: _bottomTitlesRegionalManager,
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
            barGroups: _regionalManagerAnalysisChartData(
              rsmwiseCollectionList.rsmwiseData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedRegionalManager = touchedRegionalManager == ""
                          ? rsmwiseCollectionList
                                .rsmwiseData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .rsmName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedReceivables,
                        touchedNetReceivables,
                        touchedAdvance,
                        touchedCustomer,
                        touchedRegionalManager,
                        touchedSalesManager,
                        touchedSalesPerson,
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
                    '${rsmwiseCollectionList.rsmwiseData[grpIndex].rsmName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: formatAmount(
                          rsmwiseCollectionList
                              .rsmwiseData[grpIndex]
                              .collectionAmount,
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

  Widget _salesManagerAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = asmwiseCollectionList.asmwiseData.length;
    if (asmwiseCollectionList.asmwiseData.length > 5) {
      chartWidth = screenWidth + (35 * len);
    } else {
      chartWidth = screenWidth;
    }

    final amounts = asmwiseCollectionList.asmwiseData
        .map((e) => e.collectionAmount)
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
                sideTitles: _bottomTitlesSalesManager,
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
            barGroups: _salesManagerAnalysisChartData(
              asmwiseCollectionList.asmwiseData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedSalesManager = touchedSalesManager == ""
                          ? asmwiseCollectionList
                                .asmwiseData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .asmName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedReceivables,
                        touchedNetReceivables,
                        touchedAdvance,
                        touchedCustomer,
                        touchedRegionalManager,
                        touchedSalesManager,
                        touchedSalesPerson,
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
                    '${asmwiseCollectionList.asmwiseData[grpIndex].asmName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: formatAmount(
                          asmwiseCollectionList
                              .asmwiseData[grpIndex]
                              .collectionAmount,
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

  Widget _salesPersonAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = tsmwiseCollectionList.tsmwiseData.length;
    if (tsmwiseCollectionList.tsmwiseData.length > 5) {
      chartWidth = screenWidth + (30 * len);
    } else {
      chartWidth = screenWidth;
    }
    final amounts = tsmwiseCollectionList.tsmwiseData
        .map((e) => e.collectionAmount)
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
                sideTitles: _bottomTitlesSalesPerson,
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
            barGroups: _salesPersonAnalysisChartData(
              tsmwiseCollectionList.tsmwiseData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedSalesPerson = touchedSalesPerson == ""
                          ? tsmwiseCollectionList
                                .tsmwiseData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .tsmName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedReceivables,
                        touchedNetReceivables,
                        touchedAdvance,
                        touchedCustomer,
                        touchedRegionalManager,
                        touchedSalesManager,
                        touchedSalesPerson,
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
                    '${tsmwiseCollectionList.tsmwiseData[grpIndex].tsmName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: formatAmount(
                          tsmwiseCollectionList
                              .tsmwiseData[grpIndex]
                              .collectionAmount,
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
                        'Filter Options - Receivables',
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
                  Expanded(
                    child: Row(
                      children: [
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
                                                (selectedCategoryIndex <
                                                        savedFinanceReceivablesOptions
                                                            .length &&
                                                    index <
                                                        savedFinanceReceivablesOptions[selectedCategoryIndex]
                                                            .length)
                                                ? savedFinanceReceivablesOptions[selectedCategoryIndex][index]
                                                : false,
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

                                      fromFilter = false;

                                      savedFinanceReceivablesOptionsTemp =
                                          savedFinanceReceivablesOptions;

                                      loadDataFuture = loadDataWithFilter(
                                        touchedReceivables,
                                        touchedNetReceivables,
                                        touchedAdvance,
                                        touchedCustomer,
                                        touchedRegionalManager,
                                        touchedSalesManager,
                                        touchedSalesPerson,
                                      );

                                      setState(() {
                                        resetFinanceReceivablesOptions();
                                      });
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

                                      fromFilter = false;
                                      savedFinanceReceivablesOptionsTemp
                                          .clear();
                                      setState(() {
                                        fromDateFilter = null;
                                        toDateFilter = null;
                                        dateFilterFlag = false;
                                      });
                                      loadDataFuture = removeFilter();
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
