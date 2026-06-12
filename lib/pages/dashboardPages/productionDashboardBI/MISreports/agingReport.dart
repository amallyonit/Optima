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
import '../../../../notificationService.dart';
import '../../dashboard_card_ui.dart';
import '../../ReportService.dart';

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

class AgingReportMISProvider with ChangeNotifier {
  List<InventoryList> _salesList = [];
  List<InventoryList> get salesList => _salesList;
  void updateInventoryList(List<InventoryList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class AgingReportPage extends StatefulWidget {
  const AgingReportPage({super.key});

  @override
  State<AgingReportPage> createState() => _AgingReportPageState();
}

class _AgingReportPageState extends State<AgingReportPage> {
  final reportService = ReportService();
  late Future<void> loadDataFuture;
  DateTime? currentDate;
  DateTime? fiscalYearStartDate;
  bool chartDataLoaded = false;
  List<InventoryLevelList> stockData = [];
  List<InventoryLevelList> stockDataTemp = [];
  List<InventoryList> inventory = [];

  InventoryAgingMISList inventoryAgingList = InventoryAgingMISList(
    agingData: [],
  );
  ItemGroupWiseInventoryMISList itemGroupList = ItemGroupWiseInventoryMISList(
    itemGroupData: [],
  );
  ItemGroupAgeingSummaryList itemGroupAgeingSummaryList =
      ItemGroupAgeingSummaryList(items: []);

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

  void LoadDates() {
    currentDate = DateTime.now();

    int fiscalYearStartMonth = 4;

    int fiscalYear = currentDate!.month >= fiscalYearStartMonth
        ? currentDate!.year
        : currentDate!.year - 1;
    fiscalYearStartDate = DateTime(fiscalYear, fiscalYearStartMonth, 1);
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
      List<InventoryAgingMISData> mData = inventoryAgingList.agingData;
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

  SideTitles get _bottomTitlesItemGroupWise => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<ItemGroupWiseInventoryMISData> mData = itemGroupList.itemGroupData;
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

  List<BarChartGroupData> _itemGroupWiseChartData(
    List<ItemGroupWiseInventoryMISData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.quantity,
                width: 30,
              ),
              BarChartRodData(
                color: Colors.lightBlue,
                borderRadius: BorderRadius.zero,
                toY: chartData.value,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _inventoryAgeingChartData(
    List<InventoryAgingMISData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.agingTotalQty,
                width: 30,
              ),
              BarChartRodData(
                color: Colors.lightBlue,
                borderRadius: BorderRadius.zero,
                toY: chartData.agingTotalVal,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  Future<void> _loadInventory(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<InventoryList> salesList = [];
    try {
      do {
        var body = {
          "ToDate": formatDate(currentDate!),
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
        context.read<AgingReportMISProvider>().updateInventoryList(salesList);

        inventory = salesList.toList();
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading inventory.",
      );
    }
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

  Future<void> _loadInventoryAgingData() async {
    List<InventoryAgingMISData> receivablesAgingDataList = [];
    double agingGroup30TotalQty = 0;
    double agingGroup30TotalVal = 0;
    double agingGroup31to45TotalQty = 0;
    double agingGroup31to45TotalVal = 0;
    double agingGroup46to60TotalQty = 0;
    double agingGroup46to60TotalVal = 0;
    double agingGroup61to90TotalQty = 0;
    double agingGroup61to90TotalVal = 0;
    double agingGroup91to120TotalQty = 0;
    double agingGroup91to120TotalVal = 0;
    double agingGroup121to150TotalQty = 0;
    double agingGroup121to150TotalVal = 0;
    double agingGroup151to180TotalQty = 0;
    double agingGroup151to180TotalVal = 0;
    double agingGroup181to365TotalQty = 0;
    double agingGroup181to365TotalVal = 0;
    double agingGroup366to730TotalQty = 0;
    double agingGroup366to730TotalVal = 0;
    double agingGroup730TotalQty = 0;
    double agingGroup730TotalVal = 0;

    var collectionTargetList = inventory;

    InventoryAgingSummaryMISReport summary = summarizeCollectionTargets(
      collectionTargetList,
    );
    agingGroup30TotalQty = summary.a0to30DaysTotalQty;
    agingGroup30TotalVal = summary.a0to30DaysTotalVal;
    agingGroup31to45TotalQty = summary.a31to45DaysTotalQty;
    agingGroup31to45TotalVal = summary.a31to45DaysTotalVal;
    agingGroup46to60TotalQty = summary.a46to60DaysTotalQty;
    agingGroup46to60TotalVal = summary.a46to60DaysTotalVal;
    agingGroup61to90TotalQty = summary.a61to90DaysTotalQty;
    agingGroup61to90TotalVal = summary.a61to90DaysTotalVal;
    agingGroup91to120TotalQty = summary.a91to120DaysTotalQty;
    agingGroup91to120TotalVal = summary.a91to120DaysTotalVal;
    agingGroup121to150TotalQty = summary.a121to150DaysTotalQty;
    agingGroup121to150TotalVal = summary.a121to150DaysTotalVal;
    agingGroup151to180TotalQty = summary.a151to180DaysTotalQty;
    agingGroup151to180TotalVal = summary.a151to180DaysTotalVal;
    agingGroup181to365TotalQty = summary.a181to365DaysTotalQty;
    agingGroup181to365TotalVal = summary.a181to365DaysTotalVal;
    agingGroup366to730TotalQty = summary.a366to730DaysTotalQty;
    agingGroup366to730TotalVal = summary.a366to730DaysTotalVal;
    agingGroup730TotalQty = summary.a730DaysTotalQty;
    agingGroup730TotalVal = summary.a730DaysTotalVal;
    receivablesAgingDataList.add(
      InventoryAgingMISData(
        agingGroup: "0-30",
        agingTotalQty: agingGroup30TotalQty,
        agingTotalVal: agingGroup30TotalVal,
      ),
    );
    receivablesAgingDataList.add(
      InventoryAgingMISData(
        agingGroup: "31-45",
        agingTotalQty: agingGroup31to45TotalQty,
        agingTotalVal: agingGroup31to45TotalVal,
      ),
    );
    receivablesAgingDataList.add(
      InventoryAgingMISData(
        agingGroup: "46-60",
        agingTotalQty: agingGroup46to60TotalQty,
        agingTotalVal: agingGroup46to60TotalVal,
      ),
    );
    receivablesAgingDataList.add(
      InventoryAgingMISData(
        agingGroup: "61-90",
        agingTotalQty: agingGroup61to90TotalQty,
        agingTotalVal: agingGroup61to90TotalVal,
      ),
    );
    receivablesAgingDataList.add(
      InventoryAgingMISData(
        agingGroup: "91-120",
        agingTotalQty: agingGroup91to120TotalQty,
        agingTotalVal: agingGroup91to120TotalVal,
      ),
    );
    receivablesAgingDataList.add(
      InventoryAgingMISData(
        agingGroup: "121-150",
        agingTotalQty: agingGroup121to150TotalQty,
        agingTotalVal: agingGroup121to150TotalVal,
      ),
    );
    receivablesAgingDataList.add(
      InventoryAgingMISData(
        agingGroup: "151-180",
        agingTotalQty: agingGroup151to180TotalQty,
        agingTotalVal: agingGroup151to180TotalVal,
      ),
    );
    receivablesAgingDataList.add(
      InventoryAgingMISData(
        agingGroup: "181-365",
        agingTotalQty: agingGroup181to365TotalQty,
        agingTotalVal: agingGroup181to365TotalVal,
      ),
    );
    receivablesAgingDataList.add(
      InventoryAgingMISData(
        agingGroup: "366-730",
        agingTotalQty: agingGroup366to730TotalQty,
        agingTotalVal: agingGroup366to730TotalVal,
      ),
    );
    receivablesAgingDataList.add(
      InventoryAgingMISData(
        agingGroup: "731+",
        agingTotalQty: agingGroup730TotalQty,
        agingTotalVal: agingGroup730TotalVal,
      ),
    );

    // for (InventoryAgingData agingData in receivablesAgingDataList) {
    //    agingData.agingPercentage = double.tryParse(
    //        ((agingData.agingGroupTotal / totalDueAmount) * 100)
    //            .toStringAsFixed(2)) ??
    //        0;
    //    agingData.agingGroupTotal = double.tryParse((agingData.agingGroupTotal).toStringAsFixed(2)) ?? 0;
    // }
    inventoryAgingList = InventoryAgingMISList(
      agingData: receivablesAgingDataList,
    );
  }

  Future<void> _loadItemGroupWiseInventory() async {
    var inventoryList = inventory;
    String groupName = "";
    double productSales = 0.00;
    double productValue = 0.00;
    List<ItemGroupWiseInventoryMISData> warehouseData = [];
    Set<String> processedGroupNames = {};

    for (var itemGroup in inventoryList) {
      if (!processedGroupNames.contains(itemGroup.groupName)) {
        groupName = itemGroup.groupName;
        for (var target in inventoryList.where(
          (prdelement) => prdelement.groupName == groupName,
        )) {
          double salesAmt = (double.parse(target.totalQuantity));
          productSales += salesAmt;
          double val = (double.parse(target.totalValue));
          productValue += val;
        }

        warehouseData.add(
          ItemGroupWiseInventoryMISData(
            groupName: groupName,
            quantity: productSales,
            value: productValue,
          ),
        );
        processedGroupNames.add(itemGroup.groupName);
      }
      productSales = 0;
      productValue = 0;
      groupName = "";
    }
    warehouseData.sort((a, b) => b.quantity.compareTo(a.quantity));

    itemGroupList = ItemGroupWiseInventoryMISList(itemGroupData: warehouseData);
  }

  Future<void> _loadItemGroupAgeingSummary() async {
    final inventoryList = inventory; // your source list
    final Map<String, ItemGroupAgeingSummary> grouped = {};

    for (var item in inventoryList) {
      final String groupName = (item.groupName).toString();
      final String ageing = (item.ageingBrackets).toString();
      final double qty =
          double.tryParse((item.totalQuantity).toString()) ?? 0.0;
      final double val = double.tryParse((item.totalValue).toString()) ?? 0.0;

      if (groupName.isEmpty) continue;

      grouped.putIfAbsent(
        groupName,
        () => ItemGroupAgeingSummary(groupName: groupName),
      );
      grouped[groupName]!.addToBracket(ageing, qty, val);
    }

    final List<ItemGroupAgeingSummary> result = grouped.values.toList();
    result.sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));

    itemGroupAgeingSummaryList = ItemGroupAgeingSummaryList(items: result);
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadInventory(userName, userLevel);
    await _loadInventoryAgingData();
    await _loadItemGroupWiseInventory();
    await _loadItemGroupAgeingSummary();
    setState(() {
      chartDataLoaded = true;
    });
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

  Future<void> generateAgeingReportExcel(BuildContext context) async {
    final headers = [
      'Group Name',
      'Sum of 0-30 Days Qty',
      'Sum of 0-30 Days Val',
      'Sum of 31-45 Days Qty',
      'Sum of 31-45 Days Val',
      'Sum of 46-60 Days Qty',
      'Sum of 46-60 Days Val',
      'Sum of 61-90 Days Qty',
      'Sum of 61-90 Days Val',
      'Sum of 91-120 Days Qty',
      'Sum of 91-120 Days Val',
      'Sum of 121-150 Days Qty',
      'Sum of 121-150 Days Val',
      'Sum of 151-180 Days Qty',
      'Sum of 151-180 Days Val',
      'Sum of 181-365 Days Qty',
      'Sum of 181-365 Days Val',
      'Sum of 366-730 Days Qty',
      'Sum of 366-730 Days Val',
      'Sum of >730 Days Days Qty',
      'Sum of >730 Days Days Val',
    ];
    await reportService.generateExcel(
      sheetName: 'FG-RM-AgeingReport',
      headers: headers,
      rows: itemGroupAgeingSummaryList.items
          .map(
            (data) => [
              data.groupName,
              data.lessThan30DaysQty,
              data.lessThan30DaysValue,
              data.days31to45Qty,
              data.days31to45Value,
              data.days46to60Qty,
              data.days46to60Value,
              data.days61to90Qty,
              data.days61to90Value,
              data.days91to120Qty,
              data.days91to120Value,
              data.days121to150Qty,
              data.days121to150Value,
              data.days151to180Qty,
              data.days151to180Value,
              data.days181to365Qty,
              data.days181to365Value,
              data.days366to730Qty,
              data.days366to730Value,
              data.greaterThan730DaysQty,
              data.greaterThan730DaysValue,
            ],
          )
          .toList(),
      fileName: 'fg_rm_ageingreport.xlsx',
      amountColumns: [3, 4, 5],
      addTotalRow: true,
      reportTitle: 'Production[MIS] - FG & RM Ageing Report',
    );
  
  }

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _ageingHorizontalController = ScrollController();
  final ScrollController _groupHorizontalController = ScrollController();

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
    _verticalScrollController.dispose();
    _ageingHorizontalController.dispose();
    _groupHorizontalController.dispose();
    super.dispose();
  }

  double getMaxValue(double maxValue, double divVal) {
    return (maxValue / divVal).ceil() * divVal;
  }

  @override
  Widget build(BuildContext context) {
    String formattedFiscalYearStartDate = DateFormat(
      'dd/MM/yy',
    ).format(fiscalYearStartDate!);
    String formattedDateNow = DateFormat('dd/MM/yy').format(currentDate!);
    return chartDataLoaded == true
        ? Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: true,
              backgroundColor: Colors.white,
              elevation: 0.0,
              title: const Text(
                "RM - Daily Inventory Vs Stock",
                style: TextStyle(
                  color: Colors.blue,
                  fontFamily: "Poppins",
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
            ),
            body: FinanceVerticalScroll(
              controller: _verticalScrollController,
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
                      const Row(children: [SizedBox(width: 5)]),
                    ],
                  ),

                  SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: DashboardCardUI(
                      title: 'Age Wise Finished Goods & Raw Material',
                      spacing: 10,
                      menuItems: [
                        PopupMenuItem(
                          onTap: () {
                            generateAgeingReportExcel(context);
                          },
                          child: const Text("Download Excel"),
                        ),
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _inventoryAgeing(),
                          const SizedBox(height: 16),
                          _itemGroupWiseInventory(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  Widget _inventoryAgeing() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = inventoryAgingList.agingData.length;
    if (inventoryAgingList.agingData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    double maxAmount = len > 0
        ? inventoryAgingList.agingData
              .map((data) => data.agingTotalVal)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return FinanceHorizontalChartScroll(
      controller: _ageingHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(maxAmount, 10000000),
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
              barGroups: _inventoryAgeingChartData(
                inventoryAgingList.agingData,
              ),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    setState(() {
                      if (flTouchEvent is FlTapUpEvent) {}
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
                      inventoryAgingList.agingData[grpIndex].agingGroup,
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "\nSum of Closing Stock Qty. : ${formatAmount(inventoryAgingList.agingData[grpIndex].agingTotalQty)}",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "\nSum of Closing Stock Val : ${formatAmount(inventoryAgingList.agingData[grpIndex].agingTotalVal)}",
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

  Widget _itemGroupWiseInventory() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = itemGroupList.itemGroupData.length;
    if (itemGroupList.itemGroupData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    double maxAmount = len > 0
        ? itemGroupList.itemGroupData
              .map((data) => data.value)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return FinanceHorizontalChartScroll(
      controller: _groupHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(maxAmount, 5000000),
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
                  sideTitles: _bottomTitlesItemGroupWise,
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
              barGroups: _itemGroupWiseChartData(itemGroupList.itemGroupData),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    setState(() {
                      if (flTouchEvent is FlTapUpEvent) {
                        // touchedItemGroup = touchedItemGroup == ""
                        //     ? itemGroupList
                        //     .itemGroupData[
                        // barTouchResponse.spot!.spot.x.toInt()]
                        //     .groupName
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
                      '${itemGroupList.itemGroupData[grpIndex].groupName}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "Sum of Closing Stock Qty.: ${formatAmount(itemGroupList.itemGroupData[grpIndex].quantity)}",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Sum of Closing Stock Val: ${formatAmount(itemGroupList.itemGroupData[grpIndex].value)}",
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
