// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
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

WarehouseInventoryList warehouseLocationList = WarehouseInventoryList(
  warehouseData: [],
);

class StockStatusListMISProvider with ChangeNotifier {
  List<InventoryLevelList> _salesList = [];
  List<InventoryLevelList> get salesList => _salesList;
  void updateInventoryLevelList(List<InventoryLevelList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class MinimumStockVsActualStockPage extends StatefulWidget {
  const MinimumStockVsActualStockPage({super.key});

  @override
  State<MinimumStockVsActualStockPage> createState() =>
      _MinimumStockVsActualStockPageState();
}

class _MinimumStockVsActualStockPageState
    extends State<MinimumStockVsActualStockPage> {
  late Future<void> loadDataFuture;
  DateTime? currentDate;
  DateTime? fiscalYearStartDate;
  bool chartDataLoaded = false;
  List<InventoryLevelList> inventoryLevel = [];
  List<InventoryLevelList> inventoryLevelTemp = [];

  double targetStock = 0,
      actualStock = 0,
      stockPercentage = 0,
      targetVal = 0,
      actualVal = 0,
      valPercentage = 0;

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

  SideTitles get _bottomTitlesWarehouseLocationInventory => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<WarehouseInventoryData> mData = warehouseLocationList.warehouseData;
      text = mData.elementAt(value.toInt()).warehouseName;
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

  List<BarChartGroupData> _warehouseLocationInventoryChartData(
    List<WarehouseInventoryData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.quantity,
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
        context.read<StockStatusListMISProvider>().updateInventoryLevelList(
          salesList,
        );

        inventoryLevel = salesList.toList();
        inventoryLevelTemp = salesList.toList();
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading inventory level.",
      );
    }
  }

  Future<void> _loadWarehouseLocationWiseInventory() async {
    var inventoryList = inventoryLevel;
    String warehouseCode = "";
    String warehouseName = "";
    List<WarehouseInventoryData> warehouseData = [];
    Set<String> processedWarehouseCodes = {};

    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) {
        final cleaned = v.replaceAll(',', '').trim();
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    for (var warehouse in inventoryList) {
      if (!processedWarehouseCodes.contains(warehouse.warehouseCode)) {
        warehouseCode = warehouse.warehouseCode;
        warehouseName = warehouse.warehouseName;

        double productSales = 0.0;

        double targetMinimumStockValue = 0.0;
        double actualMinimumStockValue = 0.0;
        double stockValueOtherThanMinValue = 0.0;

        for (var target in inventoryList.where(
          (prdelement) => prdelement.warehouseCode == warehouseCode,
        )) {
          final double minInv = toDouble(target.minInventory);
          final double qty = toDouble(target.quantity);

          productSales += minInv;

          if (minInv > targetMinimumStockValue) {
            targetMinimumStockValue = minInv;
          }

          if (minInv == 0.0) {
            stockValueOtherThanMinValue += qty;
          } else {
            actualMinimumStockValue += qty;
          }
        }

        final double excessValue =
            actualMinimumStockValue - targetMinimumStockValue;
        final double totalStockValue =
            stockValueOtherThanMinValue + actualMinimumStockValue;
        final double targetVsActualValuePercent = targetMinimumStockValue == 0.0
            ? 0.0
            : (totalStockValue / targetMinimumStockValue) * 100.0;

        warehouseData.add(
          WarehouseInventoryData(
            warehouseCode: warehouseCode,
            warehouseName: warehouseName,
            quantity: productSales,
            targetMinimumStockValue: targetMinimumStockValue,
            actualMinimumStockValue: actualMinimumStockValue,
            excessValue: excessValue,
            stockValueOtherThanMinValue: stockValueOtherThanMinValue,
            totalStockValue: totalStockValue,
            targetVsActualValuePercent: targetVsActualValuePercent,
          ),
        );

        processedWarehouseCodes.add(warehouse.warehouseCode);
      }
      warehouseCode = "";
      warehouseName = "";
    }

    warehouseData.sort((a, b) => b.quantity.compareTo(a.quantity));

    warehouseLocationList = WarehouseInventoryList(
      warehouseData: warehouseData,
    );
    targetStock = warehouseLocationList.warehouseData
        .map((e) => e.targetMinimumStockValue ?? 0)
        .fold(0.0, (a, b) => a + b);

    actualStock = warehouseLocationList.warehouseData
        .map((e) => e.actualMinimumStockValue ?? 0)
        .fold(0.0, (a, b) => a + b);

    stockPercentage = targetStock > 0 ? (actualStock / targetStock) * 100 : 0;

    targetVal = warehouseLocationList.warehouseData
        .map(
          (e) =>
              (e.totalStockValue ?? 0) - (e.stockValueOtherThanMinValue ?? 0),
        )
        .fold(0.0, (a, b) => a + b);

    actualVal = warehouseLocationList.warehouseData
        .map((e) => e.totalStockValue ?? 0)
        .fold(0.0, (a, b) => a + b);

    valPercentage = targetVal > 0 ? (actualVal / targetVal) * 100 : 0;
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadInventoryLevel(userName, userLevel);
    await _loadWarehouseLocationWiseInventory();
  }

  Future<void> loadDataWithBranchFilter(String branch) async {
    setState(() {
      chartDataLoaded = false;
    });
    inventoryLevel = inventoryLevelTemp;
    inventoryLevel = inventoryLevel
        .where((test) => test.warehouseName == branch)
        .toList();
    await _loadWarehouseLocationWiseInventory();

    setState(() {});
  }

  Future<void> loadDataClearFilter() async {
    setState(() {
      chartDataLoaded = false;
    });
    inventoryLevel = inventoryLevelTemp;
    await _loadWarehouseLocationWiseInventory();

    setState(() {});
  }

  Future<void> generateMinStockVsActualStock(BuildContext context) async {
    final headers = [
      'Branch',
      'Target Minimum stock value',
      'Actual minimum stock value',
      'Excess/Short stock value',
      'Stock value other than minimum stock',
      'Total stock value',
      'Target vs Actual stock %',
    ];
    await reportService.generateExcel(
      sheetName: 'MinimumVsActualStock',
      headers: headers,
      rows: warehouseLocationList.warehouseData
          .map(
            (whData) => [
              whData.warehouseName,
              whData.targetMinimumStockValue,
              whData.actualMinimumStockValue,
              whData.excessValue,
              whData.stockValueOtherThanMinValue,
              whData.totalStockValue,
              whData.targetVsActualValuePercent,
            ],
          )
          .toList(),
      fileName: 'minimum_vs_actual_stock.xlsx',
      amountColumns: [2, 3, 4, 5, 6, 7],
      addTotalRow: true,
      reportTitle: 'Production[MIS] - Minimum Vs Actual Stock Analysis',
    );
  }

  double getMaxValue(double maxValue, double divVal) {
    return (maxValue / divVal).ceil() * divVal;
  }

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  void clearVariables() {
    targetStock = 0;
    actualStock = 0;
    stockPercentage = 0;
    targetVal = 0;
    actualVal = 0;
    valPercentage = 0;
  }

  @override
  void initState() {
    super.initState();
    LoadDates();
    clearVariables();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
    }
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalController.dispose();
    clearVariables();
    super.dispose();
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
                "Minimum Vs Actual Stock",
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
                      title: 'Finished Goods Minimum Stock\nwith Actual Stock',
                      spacing: 20,
                      menuItems: [
                        PopupMenuItem(
                          onTap: () {
                            generateMinStockVsActualStock(context);
                          },
                          child: const Text("Download Excel"),
                        ),
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BranchPicker(
                            production: inventoryLevel,
                            onChanged: (b) {
                              if (b != null) {
                                loadDataWithBranchFilter(b);
                              }
                            },
                            onClear: () {
                              loadDataClearFilter();
                            },
                          ),
                          const SizedBox(height: 16),
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
                                          radius: 70.0,
                                          lineWidth: 27.0,
                                          animation: true,
                                          percent:
                                              (stockPercentage > 100
                                                  ? 100
                                                  : stockPercentage) /
                                              100,
                                          curve: Curves.linear,
                                          circularStrokeCap:
                                              CircularStrokeCap.butt,
                                          progressColor: const Color(
                                            0xFF2CA9DF,
                                          ),
                                          arcBackgroundColor: const Color(
                                            0xFFB8ECFF,
                                          ),
                                          center: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "${stockPercentage.toStringAsFixed(2)}%",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 11.0,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 5),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    formatAmount(actualStock),
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 10.0,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 5),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "Target : ${formatAmount(targetStock)}",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
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
                                          radius: 70.0,
                                          lineWidth: 27.0,
                                          animation: true,
                                          percent:
                                              (valPercentage > 100
                                                  ? 100
                                                  : valPercentage) /
                                              100,
                                          curve: Curves.linear,
                                          circularStrokeCap:
                                              CircularStrokeCap.butt,
                                          progressColor: const Color(
                                            0xFF2CA9DF,
                                          ),
                                          arcBackgroundColor: const Color(
                                            0xFFB8ECFF,
                                          ),
                                          center: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "${valPercentage.toStringAsFixed(2)}%",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 11.0,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 5),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    formatAmount(actualVal),
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 10.0,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 5),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "Target : ${formatAmount(targetVal)}",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
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
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: DashboardCardUI(
                      title: 'Warehouse Wise Analysis',
                      spacing: 20,
                      menuItems: [],
                      child: _warehouseLocationWiseInventory(),
                    ),
                  ),
                ],
              ),
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  Widget _warehouseLocationWiseInventory() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = warehouseLocationList.warehouseData.length;
    if (warehouseLocationList.warehouseData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    double? maxY = warehouseLocationList.warehouseData.isNotEmpty
        ? warehouseLocationList.warehouseData
              .map((e) => e.quantity > e.quantity ? e.quantity : e.quantity)
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
              maxY: getMaxValue(maxY, 5000000),
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
                  sideTitles: _bottomTitlesWarehouseLocationInventory,
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
              barGroups: _warehouseLocationInventoryChartData(
                warehouseLocationList.warehouseData,
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
                      warehouseLocationList
                          .warehouseData[grpIndex]
                          .warehouseName,
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "\nTarget Min.Stock : ${formatAmount(warehouseLocationList.warehouseData[grpIndex].targetMinimumStockValue ?? 0)}",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "\nMinimum Stock: ${formatAmount(warehouseLocationList.warehouseData[grpIndex].actualMinimumStockValue ?? 0)}",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "\nDifference: ${formatAmount(warehouseLocationList.warehouseData[grpIndex].excessValue ?? 0)}",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "\nStock value other\nthan minimum stock: ${formatAmount(warehouseLocationList.warehouseData[grpIndex].stockValueOtherThanMinValue ?? 0)}",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "\nTotal Stock Value: ${formatAmount(warehouseLocationList.warehouseData[grpIndex].totalStockValue ?? 0)}",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "\nTarget vs Actual stock %: ${formatAmount(warehouseLocationList.warehouseData[grpIndex].targetVsActualValuePercent ?? 0)}",
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

class BranchPicker extends StatefulWidget {
  final List<InventoryLevelList> production;
  final ValueChanged<String?>? onChanged;
  final VoidCallback? onClear; // called when the cross is pressed
  final VoidCallback? onSearchPressed; // optional override for search button
  final String title;

  const BranchPicker({
    super.key,
    required this.production,
    this.onChanged,
    this.onClear,
    this.onSearchPressed,
    this.title = 'Manpower Costing Report',
  });

  @override
  State<BranchPicker> createState() => _BranchPickerState();
}

class _BranchPickerState extends State<BranchPicker> {
  late final List<String> _branches;
  String? _selectedBranch;

  @override
  void initState() {
    super.initState();
    _branches = _extractBranches(widget.production);
    _selectedBranch = null; // show "Select Branch" hint initially
  }

  List<String> _extractBranches(List<InventoryLevelList> list) {
    final s = list
        .map((p) => (p.warehouseName).toString())
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList();
    s.sort((a, b) => a.compareTo(b));
    return s;
  }

  // Default search behavior: open a simple dialog to pick branch
  Future<void> _defaultOpenSearchDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        String filter = '';
        return StatefulBuilder(
          builder: (c, setStateDialog) {
            final filtered = _branches
                .where((b) => b.toLowerCase().contains(filter.toLowerCase()))
                .toList();
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: 320,
                height: 420,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search branches',
                          isDense: true,
                        ),
                        onChanged: (v) => setStateDialog(() => filter = v),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No branches found'))
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final b = filtered[i];
                                return ListTile(
                                  title: Text(b),
                                  onTap: () => Navigator.of(context).pop(b),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _selectedBranch = result);
      widget.onChanged?.call(result);
    }
  }

  void _onSearchPressed() {
    if (widget.onSearchPressed != null) {
      widget.onSearchPressed!();
    } else {
      _defaultOpenSearchDialog();
    }
  }

  void _onClearPressed() {
    setState(() => _selectedBranch = null);
    // call both onChanged (with null) and onClear if provided
    widget.onChanged?.call(null);
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(6.0);
    final borderSide = BorderSide(color: Colors.grey.shade300, width: 1.0);

    // Build the circular icon widget (search or clear) shown inside the field
    Widget buildCircularAction() {
      final bool hasSelection = _selectedBranch != null;
      final icon = hasSelection ? Icons.close : Icons.search;
      final onPressed = hasSelection ? _onClearPressed : _onSearchPressed;
      final iconColor = hasSelection ? Colors.black54 : Colors.blueAccent;
      final borderColor = hasSelection
          ? Colors.grey.shade300
          : Colors.blueAccent;

      return Container(
        margin: const EdgeInsets.only(right: 8),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          splashRadius: 18,
          icon: Icon(icon, size: 18, color: iconColor),
          onPressed: _branches.isEmpty ? null : onPressed,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top title row (like your screenshot)
        // Row(
        //   children: [
        //     Expanded(
        //       child: Text(
        //         widget.title,
        //         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        //       ),
        //     ),
        //   ],
        // ),
        const SizedBox(height: 8),
        // Wrap field and circular icon in a row so the icon appears inside-right visually.
        // We use Expanded for the Dropdown so it fills available space.
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedBranch,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                decoration: InputDecoration(
                  hintText: null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(borderRadius: borderRadius),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: borderSide,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  // Put a small right padding to avoid overlap with our manual circular icon
                  // (suffixIcon could be used but this approach gives consistent circular look)
                ),
                hint: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Branch',
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ),
                items: _branches
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedBranch = val);
                  widget.onChanged?.call(val);
                },
              ),
            ),

            // small spacing between field and circular icon
            const SizedBox(width: 8),

            // the circular search/clear icon
            buildCircularAction(),
          ],
        ),
      ],
    );
  }
}
