// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:math';
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
import '../../ReportService.dart';
import '../../dashboard_card_ui.dart';

class CMSCostingReportPage extends StatefulWidget {
  const CMSCostingReportPage({super.key});

  @override
  State<CMSCostingReportPage> createState() => _CMSCostingReportPageState();
}

class _CMSCostingReportPageState extends State<CMSCostingReportPage> {
  final reportService = ReportService();
  DateTime? currentDate;
  DateTime? fiscalYearStartDate;
  DateTime? lastMonthFromDate;
  bool chartDataLoaded = false;
  String? formattedFiscalYearStartDate;
  String? formattedDateNow;
  late Future<void> loadDataFuture;
  List<InventoryLevelList> stockData = [];
  List<InventoryLevelList> stockDataTemp = [];
  List<InventoryLevelList> cmsData = [];
  List<InventoryLevelList> cmsDataTemp = [];
  ProductBarDataList productBarData = ProductBarDataList(list: []);
  ItemProductionDataList inventoryLevelBarData = ItemProductionDataList(
    list: [],
  );

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

  void LoadDates() {
    currentDate = DateTime.now();
    int fiscalYearStartMonth = 4;
    int fiscalYear = currentDate!.month >= fiscalYearStartMonth
        ? currentDate!.year
        : currentDate!.year - 1;
    fiscalYearStartDate = DateTime(fiscalYear, fiscalYearStartMonth, 1);
    lastMonthFromDate = DateTime(
      fiscalYearStartDate!.year,
      fiscalYearStartDate!.month - 1,
      1,
    );
    formattedFiscalYearStartDate = DateFormat(
      'dd/MM/yy',
    ).format(fiscalYearStartDate!);
    formattedDateNow = DateFormat('dd/MM/yy').format(currentDate!);
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

  SideTitles get _bottomTitlesCmsCosting => SideTitles(
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

  List<BarChartGroupData> _cmsCostingChartData(List<ItemProductionData> data) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: Colors.lightBlueAccent,
                borderRadius: BorderRadius.zero,
                toY: chartData.productionTarget,
                width: 15,
              ),
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.totalOutput,
                width: 15,
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
    List<InventoryLevelList> invLevelList = [];
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
            List<InventoryLevelList> newInvLevelList =
                (responseJson['responseData'] as List)
                    .map((item) => InventoryLevelList.fromJson(item))
                    .toList();

            invLevelList.addAll(newInvLevelList);
            fetchedCount = newInvLevelList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        cmsData = invLevelList.toList();
        cmsDataTemp = invLevelList.toList();
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

  double getMaxValue(double maxValue, double divVal) {
    return (maxValue / divVal).ceil() * divVal;
  }

  Future<void> generateCMSCostingExcel(BuildContext context) async {
    String reportTitle =
        'Production[MIS] - CMS Costing  $formattedFiscalYearStartDate - $formattedDateNow';

    await reportService.generateExcel(
      sheetName: 'CMSCosting',
      headers: ['Product Name', 'Production Target', 'Production Achievement'],
      rows: inventoryLevelBarData.list
          .map(
            (dailyData) => [
              dailyData.itemDescription,
              dailyData.productionTarget,
              dailyData.totalOutput,
            ],
          )
          .toList(),
      fileName: 'cms_costing_analysis.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: reportTitle,
    );
  }

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

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
    _horizontalController.dispose();
    super.dispose();
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
                        const SizedBox(width: 20),
                        Text(
                          "$formattedFiscalYearStartDate - $formattedDateNow",
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'CMS Costing Analysis.',
                    spacing: 10,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(height: 8, width: 8, color: Colors.blue),
                        const SizedBox(width: 5),
                        const Text('Target', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 10),
                        Container(
                          height: 8,
                          width: 8,
                          color: Color(0xFFFF9F47),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Achievement',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateCMSCostingExcel(context);
                        },
                        child: const Text("Download Excel"),
                      ),
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _cmsCostingChart(),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
              
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  Widget _cmsCostingChart() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = inventoryLevelBarData.list.length;
    if (inventoryLevelBarData.list.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    double maxAmount = len > 0
        ? inventoryLevelBarData.list
              .map((data) => data.totalOutput)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return FinanceHorizontalChartScroll(
      controller: _horizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(maxAmount, 500000),
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
                  sideTitles: _bottomTitlesCmsCosting,
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
              barGroups: _cmsCostingChartData(inventoryLevelBarData.list),
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
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "\nProduction Achievement : ${formatAmount(inventoryLevelBarData.list[grpIndex].totalOutput)}",
                          style: const TextStyle(
                            color: Colors.black,
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
