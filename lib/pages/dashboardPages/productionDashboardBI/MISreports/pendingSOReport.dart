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

class PendingSOReportPage extends StatefulWidget {
  const PendingSOReportPage({super.key});

  @override
  State<PendingSOReportPage> createState() => _PendingSOReportPageState();
}

class _PendingSOReportPageState extends State<PendingSOReportPage> {
  final reportService = ReportService();
  List<SODetailsList> SODetailList = [];
  List<SODetailsList> SODetailListTemp = [];
  List<PendingSOChartData> pendingSOChartData = [];
  List<ReadyToDispatchChartData> readyToDispatchChartData = [];
  List<PartialDispatchChartData> partialDispatchChartData = [];

  double totalReadyValue = 0;
  double totalPartialValue = 0;
  late Future<void> loadDataFuture;
  DateTime? currentDate;
  DateTime? fiscalYearStartDate;
  bool chartDataLoaded = false;

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
  }

  String touchedSubGroup = "";
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

  String selectedWarehouse = "";

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

  SideTitles get _totalPendingSOBottomTitle => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<PendingSOChartData> mData = getFilteredPendingSOData();
      text = mData.elementAt(value.toInt()).groupName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(text, style: const TextStyle(fontSize: 11)),
        ),
      );
    },
  );

  Widget _readyDispatchBottomTitle(double value, TitleMeta meta) {
    final data = getFilteredReadyData();

    if (value.toInt() >= data.length) {
      return const SizedBox();
    }

    return SideTitleWidget(
      meta: meta,
      angle: -0.5,
      child: Text(
        data[value.toInt()].groupName,
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  Widget _partialReadyBottomTitle(double value, TitleMeta meta) {
    final data = getFilteredPartialReadyData();

    if (value.toInt() >= data.length) {
      return const SizedBox();
    }

    return SideTitleWidget(
      meta: meta,
      angle: -0.5,
      child: Text(
        data[value.toInt()].groupName,
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  SideTitles get _readyDispatchBottomTitles => SideTitles(
    showTitles: true,
    reservedSize: 40,
    getTitlesWidget: _readyDispatchBottomTitle,
  );

  SideTitles get _partialReadyBottomTitles => SideTitles(
    showTitles: true,
    reservedSize: 40,
    getTitlesWidget: _partialReadyBottomTitle,
  );

  List<PendingSOChartData> getFilteredPendingSOData() {
    final warehouse = selectedWarehouse;

    if (warehouse.isEmpty) {
      return [];
    }

    return pendingSOChartData
        .where((e) => e.warehouseValues.containsKey(warehouse))
        .toList();
  }

  List<BarChartGroupData> _pendingTotalSOBarGroups(
    List<PendingSOChartData> data,
  ) {
    return List.generate(data.length, (index) {
      final value = data[index].warehouseValues[selectedWarehouse] ?? 0;

      return BarChartGroupData(
        x: index,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            color: const Color.fromARGB(255, 199, 7, 173),
            toY: value,
            width: 30,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  List<ReadyToDispatchChartData> getFilteredReadyData() {
    if (selectedWarehouse == "" || selectedWarehouse.isEmpty) {
      return [];
    }

    return readyToDispatchChartData
        .where(
          (e) =>
              e.readyValues.containsKey(selectedWarehouse) ||
              e.partialValues.containsKey(selectedWarehouse),
        )
        .toList();
  }

  List<BarChartGroupData> _readyToDispatchBarGroups(
    List<ReadyToDispatchChartData> data,
  ) {
    return List.generate(data.length, (index) {
      final value = data[index].readyValues[selectedWarehouse] ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            width: 22,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  List<ReadyToDispatchChartData> getFilteredPartialReadyData() {
    if (selectedWarehouse == "" || selectedWarehouse.isEmpty) {
      return [];
    }

    return readyToDispatchChartData
        .where((e) => e.partialValues.containsKey(selectedWarehouse))
        .toList();
  }

  List<BarChartGroupData> _partialReadyBarGroups(
    List<ReadyToDispatchChartData> data,
  ) {
    return List.generate(data.length, (index) {
      final value = data[index].partialValues[selectedWarehouse] ?? 0;

      return BarChartGroupData(
        x: index,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: value,
            width: 22,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  Future<void> _loadSODetailsAPI(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<SODetailsList> soDetailList = [];

    try {
      do {
        var body = {
          "FromDate": formatDate(addMonth(fiscalYearStartDate!, -6)),
          "ToDate": formatDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        const apiUrl = '${ApiHelper.baseUrl}CRM_SOList';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final List list = json['responseData'] ?? [];

          final newSalesOrder = list
              .map((e) => SODetailsList.fromJson(e))
              .toList();

          soDetailList.addAll(newSalesOrder);
          fetchedCount = newSalesOrder.length;
          index++;
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        SODetailList = soDetailList
            .where(
              (e) =>
                  e.soStatus == "Open" &&
                  e.bpGroup != "AH GROUP" &&
                  ["Finished Goods", "Traded Material"].contains(e.groupName),
            )
            .toList();
        SODetailListTemp = soDetailList
            .where(
              (e) =>
                  e.soStatus == "Open" &&
                  e.bpGroup != "AH GROUP" &&
                  ["Finished Goods", "Traded Material"].contains(e.groupName),
            )
            .toList();
      });

      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading SO data.",
      );
    }
  }

  String getPendingSOGroupName(SODetailsList item) {
    switch (item.itemSubGroup.trim()) {
      case 'Medical Device':
        return 'Finished Goods-MD';

      case 'Wrap Sheet':
        return 'Finished Goods-WS';

      case 'Cap, Mask & Shoe Cover':
        return 'Traded Material-CMS';

      default:
        return item.groupName.trim();
    }
  }

  Future<void> _preparePendingSOChartData() async {
    Map<String, Map<String, double>> pivot = {};
    for (final item in SODetailList) {
      final groupName = getPendingSOGroupName(item);
      final warehouse = item.warehouse.trim();

      final pendingValue =
          double.tryParse(item.pendingValue.replaceAll(',', '')) ?? 0;

      pivot.putIfAbsent(groupName, () => {});

      pivot[groupName]![warehouse] =
          (pivot[groupName]![warehouse] ?? 0) + pendingValue;
    }

    pendingSOChartData = pivot.entries.map((entry) {
      return PendingSOChartData(
        groupName: entry.key,
        warehouseValues: entry.value,
      );
    }).toList()..sort((a, b) => a.groupName.compareTo(b.groupName));
  }

  Future<void> prepareReadyToDispatchData() async {
    final soGroups = <String, List<SODetailsList>>{};

    for (final row in SODetailList) {
      soGroups.putIfAbsent(row.soNo, () => []);
      soGroups[row.soNo]!.add(row);
    }

    final sortedSOs = soGroups.entries.toList()
      ..sort((a, b) {
        final d1 = DateFormat('dd/MM/yyyy').parse(a.value.first.soDate);

        final d2 = DateFormat('dd/MM/yyyy').parse(b.value.first.soDate);

        return d1.compareTo(d2);
      });

    Map<String, Map<String, double>> readyPivot = {};
    Map<String, Map<String, double>> partialPivot = {};

    totalReadyValue = 0;
    totalPartialValue = 0;

    for (final so in sortedSOs) {
      final items = so.value;

      bool fullyReady = true;

      for (final item in items) {
        final pendingQty = double.tryParse(item.pendingQuantity) ?? 0;

        final warehouseQty = double.tryParse(item.warehouseQty) ?? 0;

        if (pendingQty > warehouseQty) {
          fullyReady = false;
          break;
        }
      }

      for (final item in items) {
        final groupName = getPendingSOGroupName(item);

        final warehouse = item.warehouse.trim();

        final pendingValue =
            double.tryParse(item.pendingValue.replaceAll(',', '')) ?? 0;

        if (fullyReady) {
          readyPivot.putIfAbsent(groupName, () => {});

          readyPivot[groupName]![warehouse] =
              (readyPivot[groupName]![warehouse] ?? 0) + pendingValue;

          totalReadyValue += pendingValue;
        } else {
          partialPivot.putIfAbsent(groupName, () => {});

          partialPivot[groupName]![warehouse] =
              (partialPivot[groupName]![warehouse] ?? 0) + pendingValue;

          totalPartialValue += pendingValue;
        }
      }
    }

    final groupNames = {...readyPivot.keys, ...partialPivot.keys};

    readyToDispatchChartData = groupNames.map((groupName) {
      return ReadyToDispatchChartData(
        groupName: groupName,
        readyValues: readyPivot[groupName] ?? {},
        partialValues: partialPivot[groupName] ?? {},
      );
    }).toList()..sort((a, b) => a.groupName.compareTo(b.groupName));
  }

  Future<void> preparePartialDispatchData() async {
    partialDispatchChartData = readyToDispatchChartData.map((e) {
      return PartialDispatchChartData(
        groupName: e.groupName,
        partialValues: e.partialValues,
      );
    }).toList();
  }

  List<String> getWarehouseList() {
    return pendingSOChartData
        .expand((e) => e.warehouseValues.keys)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> getReadyWarehouses() {
    return readyToDispatchChartData
        .expand((e) => e.readyValues.keys)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadSODetailsAPI(userName, userLevel);
    await _preparePendingSOChartData();
    await prepareReadyToDispatchData();
    await preparePartialDispatchData();
    final warehouses = getWarehouseList();
    if (warehouses.isNotEmpty && selectedWarehouse == "") {
      selectedWarehouse = warehouses.first;
    }
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> loadDataWithFilter(String subGroup) async {
    setState(() {
      chartDataLoaded = false;
    });
    SODetailList = SODetailListTemp;

    SODetailList = SODetailList.where((data) {
      final warehouseMatch =
          selectedWarehouse.isEmpty ||
          selectedWarehouse == "BANGALWH" ||
          data.warehouse == selectedWarehouse;

      final subGroupMatch = subGroup.isEmpty || data.itemSubGroup == subGroup;

      return warehouseMatch && subGroupMatch;
    }).toList();

    await _preparePendingSOChartData();
    await prepareReadyToDispatchData();
    await preparePartialDispatchData();
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> loadDataClearFilter() async {
    chartDataLoaded = false;
    SODetailList = SODetailListTemp;
    touchedSubGroup = "";
    selectedWarehouse = "BANGALWH";
    await _preparePendingSOChartData();
    await prepareReadyToDispatchData();
    await preparePartialDispatchData();
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> generateTotalPendingSoExcel(
    BuildContext context,
    List<PendingSOChartData> pendingSOChartData,
  ) async {
    final warehouses =
        pendingSOChartData
            .expand((e) => e.warehouseValues.keys)
            .toSet()
            .toList()
          ..sort();

    final headers = ['SL NO', 'Group Name', ...warehouses, 'Total'];

    int slNo = 1;

    final rows = pendingSOChartData.map((data) {
      final row = <dynamic>[slNo++, data.groupName];

      double total = 0;

      for (final warehouse in warehouses) {
        final value = data.warehouseValues[warehouse] ?? 0;

        row.add(value);
        total += value;
      }

      row.add(total);

      return row;
    }).toList();

    final amountColumns = List.generate(
      warehouses.length + 1,
      (index) => index + 3,
    );

    await reportService.generateExcel(
      sheetName: 'TotalSoPending',
      headers: headers,
      rows: rows,
      fileName: 'pending_total_so_report.xlsx',
      amountColumns: amountColumns,
      addTotalRow: true,
      reportTitle: 'Production[MIS] - Total Pending SO Report',
    );
  }

  Future<void> generateReadyToDispatchExcel(
    BuildContext context,
    List<ReadyToDispatchChartData> chartData,
  ) async {
    final warehouses =
        chartData.expand((e) => e.readyValues.keys).toSet().toList()..sort();

    final headers = ['SL NO', 'Group Name', ...warehouses, 'Grand Total'];

    int slNo = 1;

    double grandTotal = 0;
    double totalPartial = 0;

    final rows = chartData.map((data) {
      final row = <dynamic>[slNo++, data.groupName];

      double rowTotal = 0;

      for (final warehouse in warehouses) {
        final value = data.readyValues[warehouse] ?? 0;

        row.add(value);

        rowTotal += value;
        grandTotal += value;
      }

      row.add(rowTotal);

      return row;
    }).toList();

    // Calculate overall partial value
    for (final data in chartData) {
      totalPartial += data.partialValues.values.fold(0.0, (a, b) => a + b);
    }

    rows.add([
      '',
      'Partially Ready',
      ...List.filled(warehouses.length, ''),
      totalPartial,
    ]);

    rows.add([
      '',
      'Total Ready Stock',
      ...List.filled(warehouses.length, ''),
      grandTotal + totalPartial,
    ]);

    final amountColumns = List.generate(
      warehouses.length + 1,
      (index) => index + 3,
    );

    await reportService.generateExcel(
      sheetName: 'ReadyToDispatch',
      headers: headers,
      rows: rows,
      fileName: 'ready_to_dispatch.xlsx',
      amountColumns: amountColumns,
      addTotalRow: false,
      reportTitle: 'Production[MIS] - Order Wise Ready to Dispatch Report',
    );
  }

  Future<void> generatePartialReadyExcel(
    BuildContext context,
    List<ReadyToDispatchChartData> chartData,
  ) async {
    final warehouses =
        chartData.expand((e) => e.partialValues.keys).toSet().toList()..sort();

    final headers = ['SL NO', 'Group Name', ...warehouses, 'Grand Total'];

    int slNo = 1;

    final rows = chartData.map((data) {
      final row = <dynamic>[slNo++, data.groupName];

      double rowTotal = 0;

      for (final warehouse in warehouses) {
        final value = data.partialValues[warehouse] ?? 0;

        row.add(value);

        rowTotal += value;
      }

      row.add(rowTotal);

      return row;
    }).toList();

    final amountColumns = List.generate(
      warehouses.length + 1,
      (index) => index + 3,
    );

    await reportService.generateExcel(
      sheetName: 'PartialReady',
      headers: headers,
      rows: rows,
      fileName: 'partial_ready.xlsx',
      amountColumns: amountColumns,
      addTotalRow: true,
      reportTitle: 'Production[MIS] - Pending for Production Report',
    );
  }

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _totalPendingHorizontalController = ScrollController();
  final ScrollController _readyToDispatchHorizontalController =
      ScrollController();
  final ScrollController _pendingForProductionHorizontalController =
      ScrollController();

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
    _totalPendingHorizontalController.dispose();
    _readyToDispatchHorizontalController.dispose();
    _pendingForProductionHorizontalController.dispose();
    super.dispose();
  }

  double getMaxValue(double maxValue) {
    if (maxValue <= 100000) {
      return (maxValue / 10000).ceil() * 10000;
    } else if (maxValue <= 500000) {
      return (maxValue / 50000).ceil() * 50000;
    } else if (maxValue <= 1000000) {
      return (maxValue / 100000).ceil() * 100000;
    } else if (maxValue <= 5000000) {
      return (maxValue / 500000).ceil() * 500000;
    } else if (maxValue <= 10000000) {
      return (maxValue / 1000000).ceil() * 1000000;
    } else {
      return (maxValue / 5000000).ceil() * 5000000;
    }
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
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateTotalPendingSoExcel(
                                      context,
                                      pendingSOChartData,
                                    );
                                  });
                                },
                                child: const Row(
                                  children: [Text("Download Excel")],
                                ),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Select Warehouse',
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
                              production: SODetailList,
                              selectedValue: selectedWarehouse,
                              onChanged: (newValue) async {
                                setState(() {
                                  selectedWarehouse = newValue ?? "BANGALWH";
                                });
                                if (newValue != null) {
                                  await loadDataWithFilter(touchedSubGroup);
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
                    title: 'Customer Pending SO',
                    spacing: 10,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateTotalPendingSoExcel(
                            context,
                            pendingSOChartData,
                          );
                        },
                        child: const Text("Download Excel"),
                      ),
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _totalPendingSOGraph(),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Order Wise Ready to Dispatch Details',
                    spacing: 10,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateReadyToDispatchExcel(
                            context,
                            readyToDispatchChartData,
                          );
                        },
                        child: const Text("Download Excel"),
                      ),
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _readyToDispatchGraph(),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Pending for Production',
                    spacing: 10,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generatePartialReadyExcel(
                            context,
                            readyToDispatchChartData,
                          );
                        },
                        child: const Text("Download Excel"),
                      ),
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _partialReadyGraph(),
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

  Widget _totalPendingSOGraph() {
    final data = getFilteredPendingSOData();

    if (data.isEmpty) {
      return const Center(child: Text("No data available"));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = data.length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    if (data.length > 5) {
      chartWidth = screenWidth + (data.length * 50);
    }

    double maxY = 0;
    for (final item in data) {
      final value = item.warehouseValues[selectedWarehouse] ?? 0;
      if (value > maxY) {
        maxY = value;
      }
    }

    return FinanceHorizontalChartScroll(
      controller: _totalPendingHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(maxY),
              alignment: BarChartAlignment.spaceAround,
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
                  sideTitles: _totalPendingSOBottomTitle,
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
              barGroups: _pendingTotalSOBarGroups(data),

              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (group) => Colors.white,

                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final row = data[groupIndex];

                    final value = row.warehouseValues[selectedWarehouse] ?? 0;

                    return BarTooltipItem(
                      row.groupName,
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: "\nWarehouse : $selectedWarehouse",
                          style: const TextStyle(color: Colors.black),
                        ),
                        TextSpan(
                          text: "\nPending : ${formatAmount(value)}",
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _readyToDispatchGraph() {
    final data = getFilteredReadyData();

    if (data.isEmpty) {
      return const Center(child: Text("No data available"));
    }

    final screenWidth = MediaQuery.of(context).size.width;

    double chartWidth = screenWidth;

    if (data.length > 5) {
      chartWidth = screenWidth + (data.length * 60);
    }

    double maxY = 0;

    for (final item in data) {
      final value = item.readyValues[selectedWarehouse] ?? 0;

      if (value > maxY) {
        maxY = value;
      }
    }

    return FinanceHorizontalChartScroll(
      controller: _readyToDispatchHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 320,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(maxY),

              titlesData: FlTitlesData(
                show: true,

                leftTitles: AxisTitles(sideTitles: _leftTitles),

                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),

                topTitles: AxisTitles(sideTitles: _emptyTitlesTop),

                bottomTitles: AxisTitles(
                  sideTitles: _readyDispatchBottomTitles,
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

              barGroups: _readyToDispatchBarGroups(data),

              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,

                  getTooltipColor: (group) => Colors.white,

                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final row = data[groupIndex];

                    final readyValue = row.readyValues[selectedWarehouse] ?? 0;

                    final partialValue =
                        row.partialValues[selectedWarehouse] ?? 0;

                    return BarTooltipItem(
                      row.groupName,
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: "\nReady Value : ${formatAmount(readyValue)}",
                          style: const TextStyle(color: Colors.black),
                        ),

                        TextSpan(
                          text:
                              "\nPartial Value : ${formatAmount(partialValue)}",
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _partialReadyGraph() {
    final data = getFilteredPartialReadyData();

    if (data.isEmpty) {
      return const Center(child: Text("No data available"));
    }

    final screenWidth = MediaQuery.of(context).size.width;

    double chartWidth = screenWidth;

    if (data.length > 5) {
      chartWidth = screenWidth + (data.length * 60);
    }

    double maxY = 0;

    for (final item in data) {
      final value = item.partialValues[selectedWarehouse] ?? 0;

      if (value > maxY) {
        maxY = value;
      }
    }

    return FinanceHorizontalChartScroll(
      controller: _pendingForProductionHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 320,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(maxY),

              titlesData: FlTitlesData(
                show: true,

                leftTitles: AxisTitles(sideTitles: _leftTitles),

                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),

                topTitles: AxisTitles(sideTitles: _emptyTitlesTop),

                bottomTitles: AxisTitles(sideTitles: _partialReadyBottomTitles),
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
              barGroups: _partialReadyBarGroups(data),

              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,

                  fitInsideVertically: true,

                  getTooltipColor: (group) => Colors.white,

                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final row = data[groupIndex];

                    final value = row.partialValues[selectedWarehouse] ?? 0;

                    return BarTooltipItem(
                      row.groupName,
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: "\nPartial Value : ${formatAmount(value)}",
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    );
                  },
                ),
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
    this.placeholder = 'BANGALWH',
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
    for (var e in list) {
      String val = '';
      try {
        val = (e.warehouse ?? '').toString().trim();
      } catch (_) {
        if (e is Map && e.containsKey('warehouse')) {
          val = (e['warehouse'] ?? '').toString();
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
