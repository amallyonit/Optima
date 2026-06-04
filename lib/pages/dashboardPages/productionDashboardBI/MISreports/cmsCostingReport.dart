// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
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

import '../../../../notificationService.dart';

class ItemGroupAgeingSummary {
  String groupName;

  // <30 Days
  double lessThan30DaysQty = 0.0;
  double lessThan30DaysValue = 0.0;

  // 31-45 Days
  double days31to45Qty = 0.0;
  double days31to45Value = 0.0;

  // 46-60 Days
  double days46to60Qty = 0.0;
  double days46to60Value = 0.0;

  // 61-90 Days
  double days61to90Qty = 0.0;
  double days61to90Value = 0.0;

  // 91-120 Days
  double days91to120Qty = 0.0;
  double days91to120Value = 0.0;

  // 121-150 Days
  double days121to150Qty = 0.0;
  double days121to150Value = 0.0;

  // 151-180 Days
  double days151to180Qty = 0.0;
  double days151to180Value = 0.0;

  // 181-365 Days
  double days181to365Qty = 0.0;
  double days181to365Value = 0.0;

  // 366-730 Days
  double days366to730Qty = 0.0;
  double days366to730Value = 0.0;

  // >730 Days
  double greaterThan730DaysQty = 0.0;
  double greaterThan730DaysValue = 0.0;

  ItemGroupAgeingSummary({required this.groupName});

  // Convenience getters for totals across all brackets
  double get totalQuantity =>
      lessThan30DaysQty +
      days31to45Qty +
      days46to60Qty +
      days61to90Qty +
      days91to120Qty +
      days121to150Qty +
      days151to180Qty +
      days181to365Qty +
      days366to730Qty +
      greaterThan730DaysQty;

  double get totalValue =>
      lessThan30DaysValue +
      days31to45Value +
      days46to60Value +
      days61to90Value +
      days91to120Value +
      days121to150Value +
      days151to180Value +
      days181to365Value +
      days366to730Value +
      greaterThan730DaysValue;

  // Add qty & value to the correct bracket (expects exact bracket strings)
  void addToBracket(String ageingBracket, double qty, double val) {
    switch (ageingBracket.trim()) {
      case "<30 Days":
        lessThan30DaysQty += qty;
        lessThan30DaysValue += val;
        break;
      case "31-45 Days":
        days31to45Qty += qty;
        days31to45Value += val;
        break;
      case "46-60 Days":
        days46to60Qty += qty;
        days46to60Value += val;
        break;
      case "61-90 Days":
        days61to90Qty += qty;
        days61to90Value += val;
        break;
      case "91-120 Days":
        days91to120Qty += qty;
        days91to120Value += val;
        break;
      case "121-150 Days":
        days121to150Qty += qty;
        days121to150Value += val;
        break;
      case "151-180 Days":
        days151to180Qty += qty;
        days151to180Value += val;
        break;
      case "181-365 Days":
        days181to365Qty += qty;
        days181to365Value += val;
        break;
      case "366-730 Days":
        days366to730Qty += qty;
        days366to730Value += val;
        break;
      case ">730 Days":
        greaterThan730DaysQty += qty;
        greaterThan730DaysValue += val;
        break;
      default:
        // If ageingBracket might come in different formats, you can
        // either log it or attempt a normalization here.
        break;
    }
  }
}

class ItemGroupAgeingSummaryList {
  final List<ItemGroupAgeingSummary> items;
  ItemGroupAgeingSummaryList({required this.items});
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

int CurrentMonthSalesPercentage = 0;
String CurrentMonthSalesPercentageStr = "";
String CurrentMonthSalesStr = "";
String SalesGoalStr = "";
int LastMonthPercentage = 0;
String LastMonthPercentageStr = "";
double LastMonthSales = 0;
String LastMonthSalesStr = "";
double LastMonthTarget = 0;
String LastMonthTargetStr = "";
double CurrentQtrSales = 0;
String CurrentQtrSalesStr = "";
double CurrentQtrTarget = 0;
String CurrentQtrTargetStr = "";
int CurrentQtrPercentage = 0;
String CurrentQtrPercentageStr = "";
int YtdPercentage = 0;
String YtdPercentageStr = "";
double YtdSales = 0;
String YtdSalesStr = "";
double YtdTarget = 0;
String YtdTargetStr = "";
double CurrentMonthTarget = 0;
String CurrentMonthTargetStr = "";
int CurrentMonthPercentage = 0;
double Q1Sales = 0;
double Q1Target = 0;
double Q1Diff = 0;
int Q1Percentage = 0;
String Q1SalesStr = "";
String Q1TargetStr = "";
String Q1DiffStr = "";
String Q1PercentageStr = "";
double Q2Sales = 0;
double Q2Target = 0;
double Q2Diff = 0;
int Q2Percentage = 0;
String Q2SalesStr = "";
String Q2TargetStr = "";
String Q2DiffStr = "";
String Q2PercentageStr = "";
double Q3Sales = 0;
double Q3Target = 0;
double Q3Diff = 0;
int Q3Percentage = 0;
String Q3SalesStr = "";
String Q3TargetStr = "";
String Q3DiffStr = "";
String Q3PercentageStr = "";
double Q4Sales = 0;
double Q4Target = 0;
double Q4Diff = 0;
int Q4Percentage = 0;
String Q4SalesStr = "";
String Q4TargetStr = "";
String Q4DiffStr = "";
String Q4PercentageStr = "";
double Q1Average = 0;
String Q1AverageStr = "";
double Q2Average = 0;
String Q2AverageStr = "";
double Q3Average = 0;
String Q3AverageStr = "";
double Q4Average = 0;
String Q4AverageStr = "";
DateTime? q1FromDate;
DateTime? q1ToDate;
DateTime? q2FromDate;
DateTime? q2ToDate;
DateTime? q3FromDate;
DateTime? q3ToDate;
DateTime? q4FromDate;
DateTime? q4ToDate;

bool chartDataLoaded = false;

List<InventoryLevelList> stockData = [];
List<InventoryLevelList> stockDataTemp = [];

List<ItemCostList> itemCostList = [];

double targetStockHeader = 0;
double actualStockHeader = 0;
double differenceStockHeader = 0;

List<InventoryLevelList> cmsData = [];
List<InventoryLevelList> cmsDataTemp = [];
double totalInventory = 0;

ProductBarDataList productBarData = ProductBarDataList(list: []);
ItemProductionDataList inventoryLevelBarData = ItemProductionDataList(list: []);

class CMSDetailsMISProvider with ChangeNotifier {
  List<InventoryLevelList> _salesList = [];
  List<InventoryLevelList> get salesList => _salesList;
  void updateInventoryList(List<InventoryLevelList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

// class BOMCostMISProvider with ChangeNotifier {
//   List<ItemCostList> _itemCostList = [];
//   List<ItemCostList> get itemCostList => _itemCostList;
//   void updateItemCostList(List<ItemCostList> newCostList) {
//     _itemCostList = newCostList;
//     notifyListeners();
//   }
// }

class CMSCostingReportPage extends StatefulWidget {
  const CMSCostingReportPage({super.key});

  @override
  State<CMSCostingReportPage> createState() => _CMSCostingReportPageState();
}

class _CMSCostingReportPageState extends State<CMSCostingReportPage> {
  void LoadAllQuarterFromToDates() {
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
      List<ItemProductionData> mData = inventoryLevelBarData.list;
      text = mData.elementAt(value.toInt()).itemDescription;
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

  List<BarChartGroupData> _inventoryAgeingChartData(
    List<ItemProductionData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: Colors.lightBlueAccent,
                borderRadius: BorderRadius.zero,
                toY: chartData.productionTarget,
                width: 30,
              ),
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.totalOutput,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  Future<void> _loadInventoryLevel(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000; // Maximum limit to fetch all data
    int fetchedCount = 0;
    List<InventoryLevelList> salesList = [];
    try {
      do {
        var body = {
          "Index": index.toString(),
          "Limit": limit.toString(),
          "type": "CMS",
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}BicxoStockStatusList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<InventoryLevelList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => InventoryLevelList.fromJson(item))
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
        context.read<CMSDetailsMISProvider>().updateInventoryList(salesList);

        cmsData = salesList.toList();
        cmsDataTemp = salesList.toList();
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading inventory level.",
      );
    }
  }

  Future<void> _loadInventoryLevelBarData(
    List<InventoryLevelList> cmsData,
  ) async {
    Map<String, double> sumOutputMap = {};
    Map<String, double> maxTargetMap = {};
    Map<String, String> itemDescriptionMap = {};

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

    for (var item in cmsData) {
      String itemNo = item.itemNo;
      if (itemNo.trim().isEmpty) continue;

      double itemValue = toDouble(item.value);
      sumOutputMap[itemNo] = (sumOutputMap[itemNo] ?? 0.0) + itemValue;

      double currentMinInventory = toDouble(item.minInventory);
      double existingMax = maxTargetMap[itemNo] ?? 0.0;
      maxTargetMap[itemNo] = max(existingMax, currentMinInventory);

      itemDescriptionMap.putIfAbsent(itemNo, () => item.itemDescription);
    }

    List<ItemProductionData> dataList = sumOutputMap.keys.map((itemNoKey) {
      return ItemProductionData(
        itemDescription: itemDescriptionMap[itemNoKey] ?? 'Unknown Item',
        totalOutput: sumOutputMap[itemNoKey] ?? 0.0,
        productionTarget: maxTargetMap[itemNoKey] ?? 0.0,
      );
    }).toList();

    dataList.sort((a, b) => b.totalOutput.compareTo(a.totalOutput));

    inventoryLevelBarData = ItemProductionDataList(list: dataList);
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
    await _loadInventoryLevel(userName, userLevel);
    // await _loadItemCost(userName, userLevel);
    await _loadInventoryLevelBarData(cmsData);
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
    LoadDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedFiscalYearStartDate = DateFormat(
      'dd/MM/yy',
    ).format(fiscalYearStartDate!);
    String formattedDateNow = DateFormat('dd/MM/yy').format(currentDate!);
    return chartDataLoaded == true
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
                          "Age Wise Finished Goods & Raw Material",
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
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _inventoryAgeing(),
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

  Widget _inventoryAgeing() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = inventoryLevelBarData.list.length;
    if (inventoryLevelBarData.list.length > 5) {
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
            barGroups: _inventoryAgeingChartData(inventoryLevelBarData.list),
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
                    inventoryLevelBarData.list[grpIndex].itemDescription,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\nProduction Target : ${formatAmount(inventoryLevelBarData.list[grpIndex].productionTarget)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nTotal Output : ${formatAmount(inventoryLevelBarData.list[grpIndex].totalOutput)}",
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
