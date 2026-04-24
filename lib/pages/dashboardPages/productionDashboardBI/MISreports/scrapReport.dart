// ignore_for_file: file_names

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

class GroupProductionData {
  GroupProductionData({
    required this.groupName,
    required this.totalLineTotal,
    required this.totalQuantity,
  });

  final String groupName;
  final double totalLineTotal;
  final double totalQuantity;
}

class GroupProductionDataList {
  GroupProductionDataList({this.list = const []});
  final List<GroupProductionData> list;
}

class MonthlyGroupProductionData {
  MonthlyGroupProductionData({required this.groupName});

  final String groupName;
  double weekOneQuantity = 0.0;
  double weekOneLineTotal = 0.0;
  double weekTwoQuantity = 0.0;
  double weekTwoLineTotal = 0.0;
  double weekThreeQuantity = 0.0;
  double weekThreeLineTotal = 0.0;
  double weekFourQuantity = 0.0;
  double weekFourLineTotal = 0.0;
  double weekFiveQuantity = 0.0;
  double weekFiveLineTotal = 0.0;
}

class MonthlyGroupProductionDataList {
  MonthlyGroupProductionDataList({this.list = const []});
  final List<MonthlyGroupProductionData> list;
}

late Future<void> loadDataFuture;

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

DateTime? q1FromDate;
DateTime? q1ToDate;
DateTime? q2FromDate;
DateTime? q2ToDate;
DateTime? q3FromDate;
DateTime? q3ToDate;
DateTime? q4FromDate;
DateTime? q4ToDate;

bool chartDataLoaded = false;
String deviceOrientation = "";

List<InventoryLevelList> stockData = [];
List<InventoryLevelList> stockDataTemp = [];

List<ItemCostList> itemCostList = [];

double targetStockHeader = 0;
double actualStockHeader = 0;
double differenceStockHeader = 0;

List<InventoryLevelList> cmsData = [];
List<InventoryLevelList> cmsDataTemp = [];
double totalInventory = 0;

List<ProductionList> productionList = [];
GroupProductionDataList weeklyProductionBarData = GroupProductionDataList();
MonthlyGroupProductionDataList monthlyProductionBarData =
    MonthlyGroupProductionDataList();

ProductBarDataList productBarData = ProductBarDataList(list: []);
ItemProductionDataList inventoryLevelBarData = ItemProductionDataList(list: []);

class ScrapDetailProvider with ChangeNotifier {
  List<ProductionList> _salesList = [];
  List<ProductionList> get salesList => _salesList;
  void updateInventoryList(List<ProductionList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class ScrapReportPage extends StatefulWidget {
  const ScrapReportPage({super.key});

  @override
  State<ScrapReportPage> createState() => _ScrapReportPageState();
}

class _ScrapReportPageState extends State<ScrapReportPage> {
  void loadAllQuarterFromToDates() {
    DateTime now = DateTime.now();

    int financialYearStart = (now.month >= 4) ? now.year : now.year - 1;

    q1FromDate = DateTime(financialYearStart, 4, 1);
    q1ToDate = DateTime(financialYearStart, 7, 0);

    q2FromDate = DateTime(financialYearStart, 7, 1);
    q2ToDate = DateTime(financialYearStart, 10, 0);

    q3FromDate = DateTime(financialYearStart, 10, 1);
    q3ToDate = DateTime(financialYearStart + 1, 1, 0); // December 31

    q4FromDate = DateTime(financialYearStart + 1, 1, 1);
    q4ToDate = DateTime(financialYearStart + 1, 4, 0); // March 31
  }

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
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

  SideTitles get _bottomTitlesInventoryAgeing => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<GroupProductionData> mData = weeklyProductionBarData.list;
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

  SideTitles get _bottomTitlesWeekWise => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<MonthlyGroupProductionData> mData = monthlyProductionBarData.list;
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

  List<BarChartGroupData> _currentWeekChartData(
    List<GroupProductionData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: Colors.lightBlueAccent,
                borderRadius: BorderRadius.zero,
                toY: chartData.totalLineTotal,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _weekWiseChartData(
    List<MonthlyGroupProductionData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: Colors.lightBlueAccent,
                borderRadius: BorderRadius.zero,
                toY: chartData.weekFiveLineTotal,
                width: 10,
              ),
              BarChartRodData(
                color: Colors.lightBlueAccent,
                borderRadius: BorderRadius.zero,
                toY: chartData.weekTwoLineTotal,
                width: 10,
              ),
              BarChartRodData(
                color: Colors.lightBlueAccent,
                borderRadius: BorderRadius.zero,
                toY: chartData.weekThreeLineTotal,
                width: 10,
              ),
              BarChartRodData(
                color: Colors.lightBlueAccent,
                borderRadius: BorderRadius.zero,
                toY: chartData.weekFourLineTotal,
                width: 10,
              ),
              BarChartRodData(
                color: Colors.lightBlueAccent,
                borderRadius: BorderRadius.zero,
                toY: chartData.weekFiveLineTotal,
                width: 10,
              ),
            ],
          ),
        )
        .toList();
  }

  Future<void> _loadProductionList(String userName, String userLevel) async {
    const int limit = 100000;
    int index = 0;
    int fetchedCount = 0;
    int monthIndex = currentDate!.month;
    List<ProductionList> salesList = [];

    // Precomputed dates
    String fromDate = formatDate(
      monthIndex == 4 ? lastMonthFromDate! : fiscalYearStartDate!,
    );
    String toDate = formatDate(currentDate!);

    try {
      do {
        // Request body
        var body = {
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        // API call
        const apiUrl = '${ApiHelper.baseUrl}BicxoGoodsProducedList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final responseJson = jsonDecode(response.body);

          if (responseJson["responseData"] != null &&
              responseJson["responseData"].isNotEmpty) {
            // Parse response data
            List<ProductionList> newSalesList =
                (responseJson["responseData"] as List)
                    .map((item) => ProductionList.fromJson(item))
                    .toList();

            salesList.addAll(newSalesList);
            fetchedCount = newSalesList.length;
            index++;
          } else {
            fetchedCount = 0; // Stop fetching if no data is returned
          }
        } else {
          fetchedCount = 0; // Stop fetching on API error
        }
      } while (fetchedCount == limit);

      // Update state
      setState(() {
        // Notify the provider
        context.read<ScrapDetailProvider>().updateInventoryList(salesList);
      });
      productionList = salesList;
    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
      }
    }
  }

  Future<void> _loadWeeklyProductionBarData(
    List<dynamic> productionList,
  ) async {
    bool isCurrentWeek(String? dateString) {
      if (dateString == null) return false;

      DateTime? docDate;
      try {
        final DateFormat format = DateFormat('dd/MM/yyyy');
        docDate = format.parse(dateString);
      } catch (e) {
        docDate = null;
      }

      if (docDate == null) {
        return false;
      }

      final DateTime now = DateTime.now();

      final DateTime today = DateTime(now.year, now.month, now.day);

      final DateTime startOfWeek = today.subtract(
        Duration(days: now.weekday - 1),
      );

      final DateTime endOfWeek = startOfWeek.add(Duration(days: 7));

      final bool isThisWeek =
          (docDate.isAtSameMomentAs(startOfWeek) ||
              docDate.isAfter(startOfWeek)) &&
          docDate.isBefore(endOfWeek);

      return isThisWeek;
    }

    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) {
        final cleaned = v.replaceAll(',', '').trim();
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    Map<String, double> sumLineTotalMap = {};
    Map<String, double> sumQuantityMap = {};

    for (var item in productionList) {
      if (!isCurrentWeek(item.documentDate)) {
        continue;
      }

      String groupName = item.groupName ?? 'Unknown Group';
      if (groupName.trim().isEmpty) {
        groupName = 'Unknown Group';
      }

      double lineTotal = toDouble(item.lineTotal);
      sumLineTotalMap[groupName] =
          (sumLineTotalMap[groupName] ?? 0.0) + lineTotal;

      double quantity = toDouble(item.quantity);
      sumQuantityMap[groupName] = (sumQuantityMap[groupName] ?? 0.0) + quantity;
    }

    List<GroupProductionData> dataList = sumLineTotalMap.keys.map((
      groupNameKey,
    ) {
      return GroupProductionData(
        groupName: groupNameKey,
        totalLineTotal: sumLineTotalMap[groupNameKey] ?? 0.0,
        totalQuantity: sumQuantityMap[groupNameKey] ?? 0.0,
      );
    }).toList();

    dataList.sort((a, b) => b.totalLineTotal.compareTo(a.totalLineTotal));

    setState(() {
      weeklyProductionBarData = GroupProductionDataList(list: dataList);
    });
  }

  Future<void> _loadMonthlyProductionBarData(
    List<dynamic> productionList,
  ) async {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) {
        final cleaned = v.replaceAll(',', '').trim();
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    int getWeekOfMonth(DateTime docDate) {
      int day = docDate.day;

      if (day <= 7) return 1;
      if (day <= 14) return 2;
      if (day <= 21) return 3;
      if (day <= 28) return 4;
      return 5;
    }

    Map<String, MonthlyGroupProductionData> aggregationMap = {};
    final DateTime now = DateTime.now();

    final DateFormat format = DateFormat('dd/MM/yyyy');

    for (var item in productionList) {
      DateTime? docDate;
      try {
        docDate = format.parse(item.documentDate ?? '');
      } catch (e) {
        docDate = null;
      }

      if (docDate == null) {
        continue;
      }

      if (docDate.month != now.month || docDate.year != now.year) {
        continue;
      }

      int weekNumber = getWeekOfMonth(docDate);

      String groupName = item.groupName ?? 'Unknown Group';
      if (groupName.trim().isEmpty) {
        groupName = 'Unknown Group';
      }

      double quantity = toDouble(item.quantity);
      double lineTotal = toDouble(item.lineTotal);

      var data = aggregationMap.putIfAbsent(
        groupName,
        () => MonthlyGroupProductionData(groupName: groupName),
      );

      switch (weekNumber) {
        case 1:
          data.weekOneQuantity += quantity;
          data.weekOneLineTotal += lineTotal;
          break;
        case 2:
          data.weekTwoQuantity += quantity;
          data.weekTwoLineTotal += lineTotal;
          break;
        case 3:
          data.weekThreeQuantity += quantity;
          data.weekThreeLineTotal += lineTotal;
          break;
        case 4:
          data.weekFourQuantity += quantity;
          data.weekFourLineTotal += lineTotal;
          break;
        case 5:
          data.weekFiveQuantity += quantity;
          data.weekFiveLineTotal += lineTotal;
          break;
      }
    }

    List<MonthlyGroupProductionData> dataList = aggregationMap.values.toList();

    dataList.sort((a, b) => a.groupName.compareTo(b.groupName));

    setState(() {
      monthlyProductionBarData = MonthlyGroupProductionDataList(list: dataList);
    });
  }

  InventoryAgingSummaryMISReport summarizeCollectionTargets(
    Iterable<InventoryList> inventory,
  ) {
    InventoryAgingSummaryMISReport summary = InventoryAgingSummaryMISReport();
    String overDueDays = "";
    for (var element in inventory) {
      overDueDays = element.ageingBrackets;
      if (overDueDays == "<30 Days") {
        summary.a0to30DaysTotalQty += (double.parse(element.totalQuantity));
        summary.a0to30DaysTotalVal += (double.parse(element.totalValue));
      } else if (overDueDays == "31-45 Days") {
        summary.a31to45DaysTotalQty += (double.parse(element.totalQuantity));
        summary.a31to45DaysTotalVal += (double.parse(element.totalValue));
      } else if (overDueDays == "46-60 Days") {
        summary.a46to60DaysTotalQty += (double.parse(element.totalQuantity));
        summary.a46to60DaysTotalVal += (double.parse(element.totalValue));
      } else if (overDueDays == "61-90 Days") {
        summary.a61to90DaysTotalQty += (double.parse(element.totalQuantity));
        summary.a61to90DaysTotalVal += (double.parse(element.totalValue));
      } else if (overDueDays == "91-120 Days") {
        summary.a91to120DaysTotalQty += (double.parse(element.totalQuantity));
        summary.a91to120DaysTotalVal += (double.parse(element.totalValue));
      } else if (overDueDays == "121-150 Days") {
        summary.a121to150DaysTotalQty += (double.parse(element.totalQuantity));
        summary.a121to150DaysTotalVal += (double.parse(element.totalValue));
      } else if (overDueDays == "151-180 Days") {
        summary.a151to180DaysTotalQty += (double.parse(element.totalQuantity));
        summary.a151to180DaysTotalVal += (double.parse(element.totalValue));
      } else if (overDueDays == "181-365 Days") {
        summary.a181to365DaysTotalQty += (double.parse(element.totalQuantity));
        summary.a181to365DaysTotalVal += (double.parse(element.totalValue));
      } else if (overDueDays == "366-730 Days") {
        summary.a366to730DaysTotalQty += (double.parse(element.totalQuantity));
        summary.a366to730DaysTotalVal += (double.parse(element.totalValue));
      } else if (overDueDays == ">730 Days") {
        summary.a730DaysTotalQty += (double.parse(element.totalQuantity));
        summary.a730DaysTotalVal += (double.parse(element.totalValue));
      }
    }
    return summary;
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadProductionList(userName, userLevel);
    _loadWeeklyProductionBarData(productionList);
    _loadMonthlyProductionBarData(productionList);
    chartDataLoaded = true;
  }

  Future<void> loadDataWithBranchFilter(String branch) async {
    chartDataLoaded = false;
    stockData = stockDataTemp;
    stockData = stockData
        .where((test) => test.warehouseName == branch)
        .toList();

    setState(() {});
  }

  Future<void> loadDataClearFilter() async {
    chartDataLoaded = false;
    stockData = stockDataTemp;
    setState(() {});
  }

  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
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
    loadDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.width;
    if (screenHeight > 600) {
      deviceOrientation = "Landscape";
    } else {
      deviceOrientation = "Portrait";
    }
    String formattedFiscalYearStartDate = DateFormat(
      'dd/MM/yy',
    ).format(fiscalYearStartDate!);
    String formattedDateNow = DateFormat('dd/MM/yy').format(currentDate!);

    return chartDataLoaded == true
        ? SingleChildScrollView(
            child: SizedBox(
              height: deviceOrientation == "Landscape" ? 860 : 900,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 15),
                          Text(
                            "$formattedFiscalYearStartDate - $formattedDateNow",
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          // IconButton(
                          //     onPressed: () {
                          //       showPopupMenu();
                          //     },
                          //     icon: const Icon(Icons.filter_alt_outlined)),
                          SizedBox(width: 5),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: 15),
                          Text(
                            "Scrap Report",
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
                                      // generateAgeingReport(context);
                                    });
                                  },
                                  child: const Text("Download Excel"),
                                ),
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      // generateMonthlyProductionPDF(monthData);
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
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: 15),
                          Text(
                            "Current Week",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                    child: _currentWeek(),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0, right: 16.0),
                    child: Divider(thickness: 2),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: 15),
                          Text(
                            "Week Wise",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                    child: _weekWise(),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0, right: 16.0),
                    child: Divider(thickness: 2),
                  ),
                ],
              ),
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  Widget _currentWeek() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = weeklyProductionBarData.list.length;
    if (weeklyProductionBarData.list.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    // double maxAmount = len > 0
    //     ? inventoryAgingList.agingData
    //     .map((data) => data.Value)
    //     .reduce((a, b) => a > b ? a : b)
    //     : 0;
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
                sideTitles: _bottomTitlesInventoryAgeing,
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
            barGroups: _currentWeekChartData(weeklyProductionBarData.list),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      // touchedAging = touchedAging == ""
                      //     ? inventoryAgingList
                      //     .agingData[barTouchResponse.spot!.spot.x.toInt()]
                      //     .agingGroup
                      //     : "";
                      // selectedChart = barTouchResponse.spot!.spot.x;
                      // showDrillDownChart = true;
                      // loadDataWithFilter(
                      //   touchedAging,
                      //   touchedWarehouseLocation,
                      //   touchedItemGroup,
                      //   touchedItemSubGroup,
                      // );
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
                    weeklyProductionBarData.list[grpIndex].groupName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\nQty : ${formatAmount(weeklyProductionBarData.list[grpIndex].totalQuantity)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nAmount : ${formatAmount(weeklyProductionBarData.list[grpIndex].totalLineTotal)}",
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

  Widget _weekWise() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = monthlyProductionBarData.list.length;
    if (monthlyProductionBarData.list.length > 5) {
      chartWidth = screenWidth + (50 * len);
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
                sideTitles: _bottomTitlesWeekWise,
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
            barGroups: _weekWiseChartData(monthlyProductionBarData.list),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      // touchedAging = touchedAging == ""
                      //     ? inventoryAgingList
                      //     .agingData[barTouchResponse.spot!.spot.x.toInt()]
                      //     .agingGroup
                      //     : "";
                      // selectedChart = barTouchResponse.spot!.spot.x;
                      // showDrillDownChart = true;
                      // loadDataWithFilter(
                      //   touchedAging,
                      //   touchedWarehouseLocation,
                      //   touchedItemGroup,
                      //   touchedItemSubGroup,
                      // );
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
                    monthlyProductionBarData.list[grpIndex].groupName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\nQty Week 1: ${formatAmount(monthlyProductionBarData.list[grpIndex].weekOneQuantity)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nAmount Week 1: ${formatAmount(monthlyProductionBarData.list[grpIndex].weekOneLineTotal)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nQty Week 2: ${formatAmount(monthlyProductionBarData.list[grpIndex].weekTwoQuantity)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nAmount Week 2: ${formatAmount(monthlyProductionBarData.list[grpIndex].weekTwoLineTotal)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nQty Week 3: ${formatAmount(monthlyProductionBarData.list[grpIndex].weekThreeQuantity)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nAmount Week 3: ${formatAmount(monthlyProductionBarData.list[grpIndex].weekThreeQuantity)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nQty Week 4: ${formatAmount(monthlyProductionBarData.list[grpIndex].weekFourQuantity)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nAmount Week 4: ${formatAmount(monthlyProductionBarData.list[grpIndex].weekFourQuantity)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nQty Week 5: ${formatAmount(monthlyProductionBarData.list[grpIndex].weekFiveQuantity)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nAmount Week 5: ${formatAmount(monthlyProductionBarData.list[grpIndex].weekFiveQuantity)}",
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
}
