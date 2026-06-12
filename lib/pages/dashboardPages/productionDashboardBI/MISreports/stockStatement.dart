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

final reportService = ReportService();

StockItemList stockStatementData = StockItemList(stockData: []);

class StockStatementMISProvider with ChangeNotifier {
  List<InventoryLevelList> _salesList = [];
  List<InventoryLevelList> get salesList => _salesList;
  void updateInventoryLevelList(List<InventoryLevelList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class StockStatementPage extends StatefulWidget {
  const StockStatementPage({super.key});

  @override
  State<StockStatementPage> createState() => _StockStatementPageState();
}

class _StockStatementPageState extends State<StockStatementPage> {
  late Future<void> loadDataFuture;
  DateTime? currentDate;
  DateTime? fiscalYearStartDate;
  bool chartDataLoaded = false;

  List<InventoryLevelList> stockData = [];
  List<InventoryLevelList> stockDataTemp = [];

  double targetStockHeader = 0;
  double actualStockHeader = 0;
  double differenceStockHeader = 0;

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

  SideTitles get _bottomTitlesStock => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<StockItemData> mData = stockStatementData.stockData;
      text = mData.elementAt(value.toInt()).itemSubGroup;
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

  List<BarChartGroupData> _stockChartData(List<StockItemData> data) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.actualStock,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  Future<void> _loadStockStatement(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000; // Maximum limit to fetch all data
    int fetchedCount = 0;
    List<InventoryLevelList> salesList = [];
    try {
      do {
        var body = {
          "Index": index.toString(),
          "Limit": limit.toString(),
          "type": "All",
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
        context.read<StockStatementMISProvider>().updateInventoryLevelList(
          salesList,
        );

        stockData = salesList.toList();
        stockDataTemp = salesList.toList();
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading stock statement.",
      );
    }
  }

  Future<void> _loadItemSubGroupGraph() async {
    var inventoryList = stockData;
    String itemSubGroup = "";
    double productSales = 0.00;
    double targetStockQty = 0.00;
    List<StockItemData> data = [];
    Set<String> processedWarehouseCodes = {};

    for (var warehouse in inventoryList) {
      if (!processedWarehouseCodes.contains(warehouse.itemSubGroup)) {
        itemSubGroup = warehouse.itemSubGroup;
        for (var target in inventoryList.where(
          (prdelement) => prdelement.itemSubGroup == itemSubGroup,
        )) {
          double salesAmt = double.parse(target.minInventory);
          productSales += salesAmt;
          double targetStock = double.parse(target.quantity);
          targetStockQty += targetStock;
        }

        data.add(
          StockItemData(
            itemSubGroup: itemSubGroup,
            targetStock: targetStockQty,
            actualStock: productSales,
            difference: targetStockQty - productSales,
          ),
        );
        processedWarehouseCodes.add(warehouse.itemSubGroup);
      }
      productSales = 0;
      targetStockQty = 0;
      itemSubGroup = "";
    }
    for (var warehouse in inventoryList) {
      double salesAmt = double.parse(warehouse.minInventory);
      actualStockHeader += salesAmt;
      double targetStock = double.parse(warehouse.quantity);
      targetStockHeader += targetStock;
      differenceStockHeader = actualStockHeader - targetStockHeader;
    }

    data.sort((a, b) => b.actualStock.compareTo(a.actualStock));

    stockStatementData = StockItemList(stockData: data);
    chartDataLoaded = true;
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadStockStatement(userName, userLevel);
    await _loadItemSubGroupGraph();
    chartDataLoaded = true;
  }

  Future<void> loadDataWithBranchFilter(String branch) async {
    chartDataLoaded = false;
    stockData = stockDataTemp;
    stockData = stockData
        .where((test) => test.warehouseName == branch)
        .toList();
    await _loadItemSubGroupGraph();

    setState(() {});
  }

  Future<void> loadDataClearFilter() async {
    chartDataLoaded = false;
    stockData = stockDataTemp;
    await _loadItemSubGroupGraph();

    setState(() {});
  }

  Future<void> generateStockStatementExcel(
    BuildContext context,
    StockItemList stockStatementData,
  ) async {
    int slNo = 1;
    await reportService.generateExcel(
      sheetName: 'StockStatement',
      headers: ['SL NO', 'Row Labels', 'Target', 'Actual stock', 'Difference'],
      rows: stockStatementData.stockData
          .map(
            (stkData) => [
              slNo++,
              stkData.itemSubGroup,
              stkData.targetStock,
              stkData.actualStock,
              stkData.difference,
            ],
          )
          .toList(),
      fileName: 'stock_statement.xlsx',
      amountColumns: [3, 4, 5],
      addTotalRow: true,
      reportTitle: 'Production[MIS] - Stock Statement',
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
                "Stock Statement",
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
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: DashboardCardUI(
                      title: 'Stock Statement',
                      spacing: 10,
                      menuItems: [
                        PopupMenuItem(
                          onTap: () {
                            generateStockStatementExcel(
                              context,
                              stockStatementData,
                            );
                          },
                          child: const Text("Download Excel"),
                        ),
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildInfoCard(
                                    'Target Stock',
                                    formatAmount(targetStockHeader),
                                  ),
                                ),
                                Expanded(
                                  child: _buildInfoCard(
                                    'Actual Stock',
                                    formatAmount(actualStockHeader),
                                  ),
                                ),
                                Expanded(
                                  child: _buildInfoCard(
                                    'Difference',
                                    formatAmount(differenceStockHeader),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _itemSubGroupGraph(),
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

  Widget _buildInfoCard(String title, String value) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF97D7F3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Text('$title\n$value', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  Widget _itemSubGroupGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = stockStatementData.stockData.length;
    if (stockStatementData.stockData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double? maxY = stockStatementData.stockData.isNotEmpty
        ? stockStatementData.stockData
              .map(
                (e) => e.actualStock > e.targetStock
                    ? e.actualStock
                    : e.targetStock,
              )
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
              maxY: getMaxValue(maxY, 10000000),
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
                  sideTitles: _bottomTitlesStock,
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
              barGroups: _stockChartData(stockStatementData.stockData),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    setState(() {
                      if (flTouchEvent is FlTapUpEvent) {
                        // touchedWarehouseLocation = touchedWarehouseLocation == ""
                        //     ? warehouseLocationList
                        //     .warehouseData[
                        // barTouchResponse.spot!.spot.x.toInt()]
                        //     .warehouseName
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
                      stockStatementData.stockData[grpIndex].itemSubGroup,
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "\nTarget Stock : ${formatAmount(stockStatementData.stockData[grpIndex].targetStock)}",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "\nActual Stock : ${formatAmount(stockStatementData.stockData[grpIndex].actualStock)}",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "\nDifference : ${formatAmount(stockStatementData.stockData[grpIndex].difference)}",
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
