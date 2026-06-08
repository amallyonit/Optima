// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/leads.dart';
import '../../../classes/globals.dart';
import '../dashboard_card_ui.dart';
import '../ReportService.dart';

final reportService = ReportService();

class DayWiseProductionDetails extends StatefulWidget {
  const DayWiseProductionDetails({super.key});

  @override
  State<DayWiseProductionDetails> createState() =>
      _DayWiseProductionDetailsState();
}

late Future<void> loadDataFuture;

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
int currentQuarter = 0;
List<Users> usersList = [];

class _DayWiseProductionDetailsState extends State<DayWiseProductionDetails> {
  bool touchedMonthGoals = false;
  bool touchedQuarterGoals = false;
  bool touchedYTDGoals = false;
  int touchedIndex = -1;
  DateTime? currentDate;
  List<ProductionOrderList> dayWiseProduction = [];
  bool chartDataLoaded = false;

  late List<BarChartGroupData> dailyCompletedChartBars;
  late List<BarChartGroupData> dailyProducedBoxesBars;
  late List<BarChartGroupData> itemWiseChartBars;

  double dailyCompletedMaxY = 0;
  double dailyProducedBoxesMaxY = 0;
  double itemWiseMaxY = 0;

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _dailyCompletedHorizontalController =
      ScrollController();
  final ScrollController _dailyProducedHorizontalController =
      ScrollController();

  double totalPlannedProduction = 0;
  double totalCompletedProduction = 0;
  double totalOpenedProduction = 0;
  String touchedDay = "";
  String touchedItem = "";
  DailyCompletedQtyAnalysisList dailyData = DailyCompletedQtyAnalysisList(
    dailyData: [],
  );
  DailyProducedBoxAnalysisList dailyBoxData = DailyProducedBoxAnalysisList(
    dailyProducedData: [],
  );
  ItemWiseQtyAnalysisList itemWiseData = ItemWiseQtyAnalysisList(
    itemWiseData: [],
  );
  SterileStatusAnalysisList sterileData = SterileStatusAnalysisList(
    sterileData: [],
  );
  final ScrollController _itemWiseQtyHorizontalController = ScrollController();

  late String formattedFiscalYearStartDate;
  late String formattedQuarterStartDate;
  late String formattedQuarterLastDate;
  late String formattedDateNow;
  late String formattedDateFirstOfLastMonth;
  late String formattedDateLastOfLastMonth;
  late String formattedDateFirstOfThisMonth;

  final http.Client client = http.Client();

  void prepareChartData() {
    /// DAILY COMPLETED
    dailyCompletedChartBars = _dailyCompletedQtyAnalysisChartData(
      dailyData.dailyData,
    );

    dailyCompletedMaxY = dailyData.dailyData.isNotEmpty
        ? dailyData.dailyData
              .map((e) => e.completedQty)
              .reduce((a, b) => a > b ? a : b)
        : 0;

    /// DAILY BOXES
    dailyProducedBoxesBars = _dailyProducedBoxesAnalysisChartData(
      dailyBoxData.dailyProducedData,
    );

    dailyProducedBoxesMaxY = dailyBoxData.dailyProducedData.isNotEmpty
        ? dailyBoxData.dailyProducedData
              .map((e) => e.producedQty)
              .reduce((a, b) => a > b ? a : b)
        : 0;

    /// ITEM WISE
    itemWiseChartBars = _itemWiseQtyAnalysisChartData(
      itemWiseData.itemWiseData,
    );

    itemWiseMaxY = itemWiseData.itemWiseData.isNotEmpty
        ? itemWiseData.itemWiseData
              .map(
                (e) => e.plannedQty > e.completedQty
                    ? e.plannedQty
                    : e.completedQty,
              )
              .reduce((a, b) => a > b ? a : b)
        : 0;
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

  String formatAmount(double amount) {
    if (amount >= 10000000) {
      // Amount in crores
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      // Amount in lakhs
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else {
      // Amount in thousands
      return '${(amount / 1000).toStringAsFixed(2)} K';
    }
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
        currentQuarterFromDate = DateTime(now.year - 1, 1, 1);
        currentQuarterToDate = DateTime(now.year - 1, 3, 31);
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

    formattedFiscalYearStartDate = DateFormat(
      'dd/MM/yy',
    ).format(fiscalYearStartDate!);
    formattedQuarterStartDate = DateFormat(
      'dd/MM/yy',
    ).format(currentQuarterFromDate!);
    formattedQuarterLastDate = DateFormat(
      'dd/MM/yy',
    ).format(currentQuarterToDate!);
    formattedDateNow = DateFormat('dd/MM/yy').format(currentDate!);
    formattedDateFirstOfLastMonth = DateFormat(
      'dd/MM/yy',
    ).format(DateTime(currentDate!.year, currentDate!.month - 1, 1));
    formattedDateLastOfLastMonth = DateFormat(
      'dd/MM/yy',
    ).format(DateTime(currentDate!.year, currentDate!.month, 0));
    formattedDateFirstOfThisMonth = DateFormat(
      'dd/MM/yy',
    ).format(DateTime(currentDate!.year, currentDate!.month, 1));
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

  Iterable<ProductionOrderList> getFilteredProductionList(
    String selectedDay,
    String itemCode,
  ) {
    Iterable<ProductionOrderList> productionList = dayWiseProduction;

    if (selectedDay.isEmpty) {
      final monthDates = getMonthStartEndDates(DateTime.now().month);

      productionList = productionList.where((target) {
        if (target.parsedOrderDate == null) return false;

        return target.parsedOrderDate!.isAtLeast(monthDates['start']!) &&
            target.parsedOrderDate!.isAtMost(monthDates['end']!);
      });
    } else {
      final selectedDate = DateFormat('dd/MM/yyyy').parse(selectedDay);

      productionList = productionList.where((target) {
        if (target.parsedOrderDate == null) return false;

        return target.parsedOrderDate!.year == selectedDate.year &&
            target.parsedOrderDate!.month == selectedDate.month &&
            target.parsedOrderDate!.day == selectedDate.day;
      });
    }

    if (itemCode.isNotEmpty) {
      productionList = productionList.where(
        (e) => e.productDescription == itemCode,
      );
    }

    return productionList;
  }

  SideTitles get _leftProducedBoxesTitles => SideTitles(
    reservedSize: 50,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String leftDouble = "";
      leftDouble = value.toStringAsFixed(0);
      return Text(leftDouble, style: const TextStyle(fontSize: 12));
    },
  );

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

  SideTitles get _bottomTitlesDailyCompletedQtyAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<DailyCompletedQtyAnalysisData> mData = dailyData.dailyData;
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

  SideTitles get _bottomTitlesDailyProducedBoxesAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<DailyProducedBoxAnalysisData> mData = dailyBoxData.dailyProducedData;
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

  SideTitles get _bottomTitlesItemWiseQtyAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<ItemWiseQtyAnalysisData> mData = itemWiseData.itemWiseData;
      text = mData.elementAt(value.toInt()).itemName;
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

  List<PieChartSectionData> showingSections() {
    final List<PieChartSectionData> sections = [];
    for (final categoryData in sterileData.sterileData) {
      final fontSize = touchedIndex >= 1 ? 12.0 : 11.0;
      final radius = touchedIndex >= 1 ? 80.0 : 75.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      final sectionData = PieChartSectionData(
        color: getCategoryColor(categoryData.categoryId),
        value: categoryData.percentage,
        title: '${categoryData.percentage.toStringAsFixed(2)} %',
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

  List<BarChartGroupData> _dailyCompletedQtyAnalysisChartData(
    List<DailyCompletedQtyAnalysisData> data,
  ) {
    return List.generate(data.length, (index) {
      final chartData = data[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            color: const Color(0xFF97D7F3),
            borderRadius: BorderRadius.zero,
            toY: chartData.completedQty,
            width: 30,
          ),
        ],
      );
    });
  }

  List<BarChartGroupData> _dailyProducedBoxesAnalysisChartData(
    List<DailyProducedBoxAnalysisData> data,
  ) {
    return List.generate(data.length, (index) {
      final chartData = data[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            color: const Color(0xFF97D7F3),
            borderRadius: BorderRadius.zero,
            toY: chartData.producedQty,
            width: 30,
          ),
        ],
      );
    });
  }

  List<BarChartGroupData> _itemWiseQtyAnalysisChartData(
    List<ItemWiseQtyAnalysisData> data,
  ) {
    return List.generate(data.length, (index) {
      final chartData = data[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            backDrawRodData: BackgroundBarChartRodData(
              fromY: 0,
              show: true,
              toY: chartData.plannedQty,
              color: const Color(0xFFF49136),
            ),
            color: const Color(0xFF97D7F3),
            borderRadius: BorderRadius.zero,
            toY: chartData.completedQty,
            width: 30,
          ),
        ],
      );
    });
  }

  Future<void> _loadProductionOrderAnalysis(
    String UserName,
    String UserLevel,
  ) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<ProductionOrderList> productionList = [];
    int monthIndex = DateTime.now().month;
    try {
      do {
        var body = {
          "FromDate": formatDate(
            monthIndex == 4 ? lastMonthFromDate! : fiscalYearStartDate!,
          ),
          "ToDate": formatDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}BicxoProductionAnalysis';
        final response = await client
            .post(
              Uri.parse(apiUrl),
              headers: {HttpHeaders.contentTypeHeader: 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<ProductionOrderList> newProductionList =
                (responseJson['responseData'] as List)
                    .map((item) => ProductionOrderList.fromJson(item))
                    .toList();

            productionList.addAll(newProductionList);
            fetchedCount = newProductionList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      dayWiseProduction = productionList
          .where((e) => e.status != "Canceled")
          .toList();

      var productSalesList = dayWiseProduction.where((target) {
        try {
          final orderDate = target.parsedOrderDate;
          if (orderDate == null) return false;
          return orderDate.isAtLeast(fiscalYearStartDate!) &&
              orderDate.isAtMost(currentDate!);
        } catch (e) {
          return false;
        }
      }).toList();

      double plannedQty = 0;
      double completedQty = 0;
      double plannedQtyTotal = 0;
      double completedQtyTotal = 0;
      double openQty = 0;
      double openQtyTotal = 0;
      for (var val in productSalesList) {
        plannedQty = double.tryParse(val.plannedQty) ?? 0;
        completedQty = double.tryParse(val.completedQty) ?? 0;
        if (val.status == "Open") {
          openQty = double.tryParse(val.plannedQty) ?? 0;
        }
        plannedQtyTotal += plannedQty;
        completedQtyTotal += completedQty;
        openQtyTotal += openQty;
      }
      totalPlannedProduction = plannedQtyTotal;
      totalCompletedProduction = completedQtyTotal;
      totalOpenedProduction = openQtyTotal;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> _loadDailyOrderQtyAnalysis(
    Iterable<ProductionOrderList> productionList,
  ) async {
    List<DailyCompletedQtyAnalysisData> dataList = [];
    final todayTarget = productionList.toList();
    final Map<String, double> groupedData = {};

    for (final target in todayTarget) {
      groupedData.update(
        target.orderDate,
        (value) => value + (double.tryParse(target.completedQty) ?? 0),
        ifAbsent: () => double.tryParse(target.completedQty) ?? 0,
      );
    }

    dataList = groupedData.entries.map((e) {
      return DailyCompletedQtyAnalysisData(date: e.key, completedQty: e.value);
    }).toList();

    dailyData = DailyCompletedQtyAnalysisList(dailyData: dataList);
  }

  Future<void> _loadDailyProducedBoxAnalysis(
    Iterable<ProductionOrderList> productionList,
  ) async {
    List<DailyProducedBoxAnalysisData> dataList = [];
    final todayTarget = productionList.toList();
    final Map<String, double> groupedBoxes = {};

    for (final target in todayTarget) {
      double ordered = double.tryParse(target.completedQty) ?? 0;
      double boxQty = double.tryParse(target.boxQty) ?? 0;

      double producedQty = boxQty == 0 ? 0 : (ordered ~/ boxQty).toDouble();

      groupedBoxes.update(
        target.orderDate,
        (value) => value + producedQty,
        ifAbsent: () => producedQty,
      );
    }

    dataList = groupedBoxes.entries.map((e) {
      return DailyProducedBoxAnalysisData(date: e.key, producedQty: e.value);
    }).toList();
    dailyBoxData = DailyProducedBoxAnalysisList(dailyProducedData: dataList);
  }

  Future<void> _loadItemWiseProductionAnalysis(
    Iterable<ProductionOrderList> productionList,
  ) async {
    List<ItemWiseQtyAnalysisData> productwiseDataList = [];

    final Map<String, ItemWiseQtyAnalysisData> groupedItems = {};

    for (final target in productionList) {
      final itemName = target.productDescription;

      final planned = double.tryParse(target.plannedQty) ?? 0;
      final rejected = double.tryParse(target.rejectedQty) ?? 0;
      final completed = double.tryParse(target.completedQty) ?? 0;

      if (groupedItems.containsKey(itemName)) {
        final existing = groupedItems[itemName]!;

        groupedItems[itemName] = ItemWiseQtyAnalysisData(
          itemName: itemName,
          plannedQty: existing.plannedQty + planned,
          completedQty: existing.completedQty + completed,
          rejectedQty: existing.rejectedQty + rejected,
        );
      } else {
        groupedItems[itemName] = ItemWiseQtyAnalysisData(
          itemName: itemName,
          plannedQty: planned,
          completedQty: completed,
          rejectedQty: rejected,
        );
      }
    }

    productwiseDataList = groupedItems.values.toList();

    productwiseDataList.sort(
      (a, b) => b.completedQty.compareTo(a.completedQty),
    );
    itemWiseData = ItemWiseQtyAnalysisList(itemWiseData: productwiseDataList);
  }

  Future<void> _loadOrderStatusOpenProduction(
    Iterable<ProductionOrderList> productionList,
  ) async {
    List<SterileStatusAnalysisData> statusList = [];

    final Map<String, double> groupedStatus = {};

    for (final target in productionList) {
      final completedQty = double.tryParse(target.completedQty) ?? 0;

      groupedStatus.update(
        target.sterileStatus,
        (value) => value + completedQty,
        ifAbsent: () => completedQty,
      );
    }

    statusList = groupedStatus.entries.map((e) {
      return SterileStatusAnalysisData(
        categoryId: e.key.toString() == "US" ? 0 : 1,
        sterileStatus: e.key,
        amount: e.value,
        percentage: 0,
      );
    }).toList();

    double totalAmount = statusList.fold(
      0,
      (double previousValue, SterileStatusAnalysisData element) =>
          previousValue + element.amount,
    );

    for (SterileStatusAnalysisData categoryData in statusList) {
      categoryData.percentage =
          double.tryParse(
            ((categoryData.amount / totalAmount) * 100).toStringAsFixed(2),
          ) ??
          0;
    }

    sterileData = SterileStatusAnalysisList(sterileData: statusList);
  }

  Future<void> applyFilter() async {
    chartDataLoaded = false;
    final filteredList = getFilteredProductionList(touchedDay, touchedItem);
    await _loadDailyOrderQtyAnalysis(filteredList);
    await _loadDailyProducedBoxAnalysis(filteredList);
    await _loadItemWiseProductionAnalysis(filteredList);
    await _loadOrderStatusOpenProduction(filteredList);
    prepareChartData();
    if (mounted) {
      setState(() {
        chartDataLoaded = true;
      });
    }
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadProductionOrderAnalysis(userName, userLevel);

    final filteredList = getFilteredProductionList("", "");
    await _loadDailyOrderQtyAnalysis(filteredList);
    await _loadDailyProducedBoxAnalysis(filteredList);
    await _loadItemWiseProductionAnalysis(filteredList);
    await _loadOrderStatusOpenProduction(filteredList);
    prepareChartData();
    chartDataLoaded = true;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> removeFilter() async {
    touchedDay = "";
    touchedItem = "";

    touchedMonthGoals = false;
    touchedQuarterGoals = false;
    touchedYTDGoals = false;
    clearVariables();
    LoadDates();
    await applyFilter();
    prepareChartData();
    chartDataLoaded = true;
    if (mounted) {
      setState(() {});
    }
  }

  void clearVariables() {
    chartDataLoaded = false;
    itemWiseData = ItemWiseQtyAnalysisList(itemWiseData: []);
    sterileData = SterileStatusAnalysisList(sterileData: []);
    touchedDay = "";
    touchedItem = "";
  }

  Future<void> generateDailyCompletedOrderExcel(
    DailyCompletedQtyAnalysisList dailyCompletedQtyAnalysisList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'DailyCompletedOrders',
      headers: ['Date', 'Completed Qty.'],
      rows: dailyCompletedQtyAnalysisList.dailyData
          .map((e) => [e.date, e.completedQty])
          .toList(),
      fileName: 'daily_completed_order_report.xlsx',
      amountColumns: [2],
      addTotalRow: true,
      reportTitle: 'Production - Daily Completed Orders',
    );
  }

  Future<void> generateDailyCompletedOrderPDF(
    DailyCompletedQtyAnalysisList dailyCompletedQtyAnalysisList,
  ) async {
    await reportService.generatePDF(
      title: 'Daily Completed Orders',
      headers: ['Date', 'Completed Qty.'],
      rows: dailyCompletedQtyAnalysisList.dailyData
          .map((e) => [e.date, e.completedQty])
          .toList(),
      fileName: 'daily_completed_order_report.pdf',
      amountColumns: [2],
    );
  }

  Future<void> generateDailyCompletedBoxOrderExcel(
    DailyProducedBoxAnalysisList dailyProducedBoxAnalysisList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'DailyCompletedBoxes',
      headers: ['Date', 'Completed Boxes'],
      rows: dailyProducedBoxAnalysisList.dailyProducedData
          .map((e) => [e.date, e.producedQty])
          .toList(),
      fileName: 'daily_completed_boxes_order_report.xlsx',
      amountColumns: [2],
      addTotalRow: true,
      reportTitle: 'Production - Daily Completed Orders[Boxes]',
    );
  }

  Future<void> generateDailyCompletedBoxOrderPDF(
    DailyProducedBoxAnalysisList dailyProducedBoxAnalysisList,
  ) async {
    await reportService.generatePDF(
      title: 'Daily Completed Boxes Order Report',
      headers: ['Date', 'Completed Boxes'],
      rows: dailyProducedBoxAnalysisList.dailyProducedData
          .map((e) => [e.date, e.producedQty])
          .toList(),
      fileName: 'daily_completed_boxes_order_report.pdf',
      amountColumns: [2],
    );
  }

  Future<void> generateProductwiseOrderExcel(
    ItemWiseQtyAnalysisList itemWiseQtyAnalysisList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'ProductwiseOrders',
      headers: [
        'Product Name',
        'Planned Qty.',
        'Completed Qty.',
        'Rejected Qty.',
      ],
      rows: itemWiseQtyAnalysisList.itemWiseData
          .map((e) => [e.itemName, e.plannedQty, e.completedQty, e.rejectedQty])
          .toList(),
      fileName: 'productwise_order_report.xlsx',
      amountColumns: [2, 3, 4],
      addTotalRow: true,
      reportTitle: 'Production - Productwise Orders',
    );
  }

  Future<void> generateProductwiseOrderPDF(
    ItemWiseQtyAnalysisList itemWiseQtyAnalysisList,
  ) async {
    await reportService.generatePDF(
      title: 'Productwise Order Report',
      headers: [
        'Product Name',
        'Planned Qty.',
        'Completed Qty.',
        'Rejected Qty.',
      ],
      rows: itemWiseQtyAnalysisList.itemWiseData
          .map((e) => [e.itemName, e.plannedQty, e.completedQty, e.rejectedQty])
          .toList(),
      fileName: 'productwise_order_report.pdf',
      amountColumns: [2, 3, 4],
    );
  }

  Future<void> generateSterileStatusExcel(
    SterileStatusAnalysisList sterileStatusAnalysisList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'SterileStatus',
      headers: ['Status', 'Status Qty.', 'Status %.'],
      rows: sterileStatusAnalysisList.sterileData
          .map((e) => [e.sterileStatus, e.amount, e.percentage])
          .toList(),
      fileName: 'sterile_status_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Sterile Status Report',
    );
  }

  Future<void> generateSterileStatusPDF(
    SterileStatusAnalysisList sterileStatusAnalysisList,
  ) async {
    await reportService.generatePDF(
      title: 'Sterile Status Report',
      headers: ['Status', 'Status Qty.', 'Status %.'],
      rows: sterileStatusAnalysisList.sterileData
          .map((e) => [e.sterileStatus, e.amount, e.percentage])
          .toList(),
      fileName: 'sterile_status_report.pdf',
      amountColumns: [2, 3],
    );
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
    client.close();
    _verticalScrollController.dispose();
    _dailyCompletedHorizontalController.dispose();
    _dailyProducedHorizontalController.dispose();
    _itemWiseQtyHorizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return chartDataLoaded == true
        ? FinanceVerticalScroll(
            controller: _verticalScrollController,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 20,
                            color: Color(0xFF2CA9DF),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              touchedMonthGoals
                                  ? "$formattedDateFirstOfLastMonth - $formattedDateLastOfLastMonth"
                                  : touchedQuarterGoals
                                  ? "$formattedQuarterStartDate - $formattedQuarterLastDate"
                                  : touchedYTDGoals
                                  ? "$formattedFiscalYearStartDate - $formattedDateNow"
                                  : "$formattedDateFirstOfThisMonth - $formattedDateNow",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),

                          IconButton(
                            tooltip: "Filter",
                            onPressed: showPopupMenu,
                            icon: const Icon(
                              Icons.filter_alt_outlined,
                              color: Color(0xFF2CA9DF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        buildKpiCard(
                          icon: Icons.assignment_outlined,
                          title: "Total Planned\nProduction",
                          value: formatAmount(totalPlannedProduction),
                        ),
                        buildKpiCard(
                          icon: Icons.check_circle_outline,
                          title: "Total Completed\nProduction",
                          value: formatAmount(totalCompletedProduction),
                        ),
                        buildKpiCard(
                          icon: Icons.inventory_2_outlined,
                          title: "Total Opened\nProduction",
                          value: formatAmount(totalOpenedProduction),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Daily Completed Qty \nAnalysis',
                    spacing: 20,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateDailyCompletedOrderExcel(dailyData);
                        },
                        child: const Text('Download Excel'),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          generateDailyCompletedOrderPDF(dailyData);
                        },
                        child: const Text('Download PDF'),
                      ),
                    ],
                    child: _dailyCompletedQtyAnalysis(screenWidth),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Daily Produced Boxes \nAnalysis',
                    spacing: 20,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateDailyCompletedBoxOrderExcel(dailyBoxData);
                        },
                        child: const Text('Download Excel'),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          generateDailyCompletedBoxOrderPDF(dailyBoxData);
                        },
                        child: const Text('Download PDF'),
                      ),
                    ],
                    child: _dailyProducedBoxesAnalysis(screenWidth),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Sterile Status Analysis',

                    trailing: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 8,
                                  width: 8,
                                  color: const Color(0xFFFF9F47),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  "Sterile",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),

                            const SizedBox(height: 5),

                            Row(
                              children: [
                                Container(
                                  height: 8,
                                  width: 8,
                                  color: const Color(0xFF97D7F3),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  "Un Sterile",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateSterileStatusExcel(sterileData);
                        },
                        child: const Text('Download Excel'),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          generateSterileStatusPDF(sterileData);
                        },
                        child: const Text('Download PDF'),
                      ),
                    ],

                    child: SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 30,
                          borderData: FlBorderData(show: false),
                          sections: showingSections(),
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title:
                        'Item-wise Planned,\nRejected & completed\nQty Analysis',
                    spacing: 20,
                    trailing: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 8,
                                  width: 8,
                                  color: const Color(0xFFFF9F47),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  "Planned Qty.",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(width: 5),
                            Row(
                              children: [
                                Container(
                                  height: 8,
                                  width: 8,
                                  color: const Color(0xFF97D7F3),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  "Completed Qty.",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateProductwiseOrderExcel(itemWiseData);
                        },
                        child: const Text('Download Excel'),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          generateProductwiseOrderPDF(itemWiseData);
                        },
                        child: const Text('Download PDF'),
                      ),
                    ],
                    child: _itemWiseQtyAnalysis(screenWidth),
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

  Widget buildKpiCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: 168,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2CA9DF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF2CA9DF)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _dailyCompletedQtyAnalysis(double screenWidth) {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = dailyData.dailyData.length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    return FinanceHorizontalChartScroll(
      controller: _dailyCompletedHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(dailyCompletedMaxY),
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
                  sideTitles: _bottomTitlesDailyCompletedQtyAnalysis,
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
              barGroups: dailyCompletedChartBars,
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedDay = touchedDay == ""
                          ? dailyData
                                .dailyData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .date
                          : "";
                      await applyFilter();
                    }
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
                              "Completed Qty : ${formatAmount(dailyData.dailyData[grpIndex].completedQty)}",
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
      ),
    );
  }

  Widget _dailyProducedBoxesAnalysis(double screenWidth) {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = dailyBoxData.dailyProducedData.length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    return FinanceHorizontalChartScroll(
      controller: _dailyProducedHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(dailyProducedBoxesMaxY),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: _leftProducedBoxesTitles,
                  axisNameSize: 14,
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
                bottomTitles: AxisTitles(
                  sideTitles: _bottomTitlesDailyProducedBoxesAnalysis,
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
              barGroups: dailyProducedBoxesBars,
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedDay = touchedDay == ""
                          ? dailyBoxData
                                .dailyProducedData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .date
                          : "";
                    }
                    await applyFilter();
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
                      '${dailyBoxData.dailyProducedData[grpIndex].date}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "Completed Qty : ${dailyBoxData.dailyProducedData[grpIndex].producedQty}",
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
      ),
    );
  }

  Widget _itemWiseQtyAnalysis(double screenWidth) {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = itemWiseData.itemWiseData.length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    return FinanceHorizontalChartScroll(
      controller: _itemWiseQtyHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(itemWiseMaxY),
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
                  sideTitles: _bottomTitlesItemWiseQtyAnalysis,
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
              barGroups: itemWiseChartBars,
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedItem = touchedItem == ""
                          ? itemWiseData
                                .itemWiseData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .itemName
                          : "";
                    }
                    await applyFilter();
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
                      '${itemWiseData.itemWiseData[grpIndex].itemName}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "Planned Qty : ${formatAmount(itemWiseData.itemWiseData[grpIndex].plannedQty)}\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Completed Qty : ${formatAmount(itemWiseData.itemWiseData[grpIndex].completedQty)}\n",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Rejected Qty : ${formatAmount(itemWiseData.itemWiseData[grpIndex].rejectedQty)}\n",
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
      ),
    );
  }
}
