// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import '../../../../notificationService.dart';
import '../../dashboard_card_ui.dart';
import '../../ReportService.dart';

class ItemGroupAgeingSummary {
  String itemGroupName;
  double lessThan60DaysQty = 0.0;
  double lessThan60DaysValue = 0.0;
  double days61to90Qty = 0.0;
  double days61to90Value = 0.0;
  double greaterThan90DaysQty = 0.0;
  double greaterThan90DaysValue = 0.0;

  ItemGroupAgeingSummary({required this.itemGroupName});

  // Convenience getters for totals across all brackets
  double get totalQuantity =>
      lessThan60DaysQty + days61to90Qty + greaterThan90DaysQty;

  double get totalValue =>
      lessThan60DaysValue + days61to90Value + greaterThan90DaysValue;

  // Add qty & value to the correct bracket (expects exact bracket strings)
  void addToBracket(String ageingBracket, double qty, double val) {
    switch (ageingBracket.trim()) {
      case "<30 Days":
        lessThan60DaysQty += qty;
        lessThan60DaysValue += val;
        break;
      case "31-45 Days":
        lessThan60DaysQty += qty;
        lessThan60DaysValue += val;
        break;
      case "46-60 Days":
        lessThan60DaysQty += qty;
        lessThan60DaysValue += val;
        break;
      case "61-90 Days":
        days61to90Qty += qty;
        days61to90Value += val;
        break;

      default:
        greaterThan90DaysQty += qty;
        greaterThan90DaysValue += val;
        break;
    }
  }
}

class ItemGroupAgeingSummaryList {
  final List<ItemGroupAgeingSummary> items;
  ItemGroupAgeingSummaryList({required this.items});
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
  List<InventoryList> inventory = [];
  List<InventoryList> inventoryTemp = [];
  String _selectedBranch = "";

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

  Future<void> _loadInventoryAPI(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<InventoryList> invList = [];
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
            List<InventoryList> newinvList =
                (responseJson['responseData'] as List)
                    .map((item) => InventoryList.fromJson(item))
                    .toList();

            invList.addAll(newinvList);
            fetchedCount = newinvList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      inventory = invList.toList();
      inventoryTemp = invList.toList();
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
        summary.a0to60DaysTotalQty += (double.parse(element.totalQuantity));
        summary.a0to60DaysTotalVal += (double.parse(element.totalValue));
      } else if (overDueDays == "31-45 Days" ||
          overDueDays == "46-60 Days" ||
          overDueDays == "61-90 Days") {
        summary.a61to90DaysTotalQty += (double.parse(element.totalQuantity));
        summary.a61to90DaysTotalVal += (double.parse(element.totalValue));
      } else {
        summary.a90DaysTotalQty += (double.parse(element.totalQuantity));
        summary.a90DaysTotalVal += (double.parse(element.totalValue));
      }
    }
    return summary;
  }

  Future<void> _loadInventoryAgingData() async {
    List<InventoryAgingMISData> receivablesAgingDataList = [];
    double a0to60DaysTotalQty = 0;
    double a0to60DaysTotalVal = 0;
    double a61to90DaysTotalQty = 0;
    double a61to90DaysTotalVal = 0;
    double a90DaysTotalQty = 0;
    double a90DaysTotalVal = 0;

    var collectionTargetList = inventory;

    InventoryAgingSummaryMISReport summary = summarizeCollectionTargets(
      collectionTargetList,
    );
    a0to60DaysTotalQty = summary.a0to60DaysTotalQty;
    a0to60DaysTotalVal = summary.a0to60DaysTotalVal;
    a61to90DaysTotalQty = summary.a61to90DaysTotalQty;
    a61to90DaysTotalVal = summary.a61to90DaysTotalVal;
    a90DaysTotalQty = summary.a90DaysTotalQty;
    a90DaysTotalVal = summary.a90DaysTotalVal;

    receivablesAgingDataList.add(
      InventoryAgingMISData(
        agingGroup: "0-60",
        agingTotalQty: a0to60DaysTotalQty,
        agingTotalVal: a0to60DaysTotalVal,
      ),
    );

    receivablesAgingDataList.add(
      InventoryAgingMISData(
        agingGroup: "61-90",
        agingTotalQty: a61to90DaysTotalQty,
        agingTotalVal: a61to90DaysTotalVal,
      ),
    );

    receivablesAgingDataList.add(
      InventoryAgingMISData(
        agingGroup: "91+",
        agingTotalQty: a90DaysTotalQty,
        agingTotalVal: a90DaysTotalVal,
      ),
    );

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
        () => ItemGroupAgeingSummary(itemGroupName: groupName),
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
    await _loadInventoryAPI(userName, userLevel);
    _selectedBranch = "All Warehouses";
    await _loadInventoryAgingData();
    await _loadItemGroupWiseInventory();
    await _loadItemGroupAgeingSummary();
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> loadDataWithFilter() async {
    chartDataLoaded = false;
    inventory = inventoryTemp;
    inventory = inventory.where((data) {
      final warehouseMatch =
          _selectedBranch.isEmpty ||
          _selectedBranch == "All Warehouses" ||
          data.warehouseName == _selectedBranch;

      return warehouseMatch;
    }).toList();

    await _loadInventoryAgingData();
    await _loadItemGroupWiseInventory();
    await _loadItemGroupAgeingSummary();
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> loadDataClearFilter() async {
    chartDataLoaded = false;
    inventory = inventoryTemp;
    _selectedBranch = "All Warehouses";
    await _loadInventoryAgingData();
    await _loadItemGroupWiseInventory();
    await _loadItemGroupAgeingSummary();
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> generateAgeingReportExcel(BuildContext context) async {
    final headers = [
      'Item Group Name',
      'Sum of 0-60 Days Qty',
      'Sum of 0-60 Days Val',
      'Sum of 61-90 Days Qty',
      'Sum of 61-90 Days Val',
      'Sum of >90 Days Qty',
      'Sum of >90 Days Val',
      'Sum of Closing Stock Qty',
      'Sum of Closing Stock Val',
    ];
    await reportService.generateExcel(
      sheetName: 'AgeingReport',
      headers: headers,
      rows: itemGroupAgeingSummaryList.items
          .map(
            (data) => [
              data.itemGroupName,
              data.lessThan60DaysQty,
              data.lessThan60DaysValue,
              data.days61to90Qty,
              data.days61to90Value,
              data.greaterThan90DaysQty,
              data.greaterThan90DaysValue,
              data.totalQuantity,
              data.totalValue,
            ],
          )
          .toList(),
      fileName: 'ageingreport.xlsx',
      amountColumns: [2, 3, 4, 5, 6, 7, 8, 9],
      addTotalRow: true,
      reportTitle: 'Production[MIS] - Ageing Report $_selectedBranch',
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
        ? FinanceVerticalScroll(
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
                    const Row(children: [SizedBox(width: 10)]),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            showPopupMenu();
                          },
                          icon: const Icon(Icons.filter_alt_outlined),
                        ),
                        const SizedBox(width: 5),
                      ],
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Inventory Ageing',
                    spacing: 10,
                    menuItems: [],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            BranchDropdown(
                              production: inventory,
                              selectedValue: _selectedBranch,
                              onChanged: (newValue) async {
                                setState(() {
                                  _selectedBranch =
                                      newValue ?? "All Warehouses";
                                });
                                if (newValue != null) {
                                  await loadDataWithFilter();
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

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
          )
        : const Center(child: CircularProgressIndicator());
  }

  showPopupMenu() {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(25.0, 50.0, 0.0, 0.0),
      elevation: 8.0,
      items: [
        const PopupMenuItem<String>(value: '1', child: Text('Remove Filter?')),
      ],
    ).then((value) {
      if (value == '1') {
        loadDataClearFilter();
      }
    });
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

class BranchDropdown extends StatefulWidget {
  final List production;
  final ValueChanged<String?> onChanged;
  final String placeholder;
  final String? selectedValue;

  const BranchDropdown({
    super.key,
    required this.production,
    required this.onChanged,
    this.selectedValue,
    this.placeholder = 'All Warehouses',
  });

  @override
  State<BranchDropdown> createState() => _BranchDropdownState();
}

class _BranchDropdownState extends State<BranchDropdown> {
  late final List<String> _items;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _items = _extractBranches(widget.production);
    _selected =
        widget.selectedValue ?? (_items.isNotEmpty ? _items.first : null);
  }

  @override
  void didUpdateWidget(covariant BranchDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedValue != oldWidget.selectedValue) {
      setState(() {
        _selected = widget.selectedValue;
      });
    }
  }

  List<String> _extractBranches(List list) {
    final seen = <String>{};
    final out = <String>[];
    out.add("All Warehouses");
    for (var e in list) {
      String val = '';
      try {
        val = (e.warehouseName ?? '').toString().trim();
      } catch (_) {
        if (e is Map && e.containsKey('warehouseName')) {
          val = (e['warehouseName'] ?? '').toString();
        }
      }
      if (val.trim().isEmpty) continue;
      if (!seen.contains(val)) {
        seen.add(val);
        out.add(val);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selected,
              hint: const SizedBox.shrink(),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              items: _items.map((s) {
                return DropdownMenuItem<String>(
                  value: s,
                  child: Text(s, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selected = val;
                });
                widget.onChanged(val);
              },
              isDense: true,
              isExpanded: false,
            ),
          ),
        ],
      ),
      onTap: () {},
    );
  }
}
