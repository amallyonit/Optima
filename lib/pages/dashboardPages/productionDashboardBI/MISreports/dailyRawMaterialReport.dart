// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import '../../../../notificationService.dart';
import '../../dashboard_card_ui.dart';
import '../../ReportService.dart';

class DailyRawMaterialReport extends StatefulWidget {
  const DailyRawMaterialReport({super.key});

  @override
  State<DailyRawMaterialReport> createState() => _DailyRawMaterialReportState();
}

class _DailyRawMaterialReportState extends State<DailyRawMaterialReport> {
  DailyStockAchievementList dailyStockAchievementData =
      DailyStockAchievementList(stockData: []);
  StockItemList stockStatementItemData = StockItemList(stockData: []);
  StockItemList stockStatementTransitData = StockItemList(stockData: []);
  final reportService = ReportService();
  final ScrollController _tabScrollController = ScrollController();
  late Future<void> loadDataFuture;
  DateTime? currentDate;
  DateTime? fiscalYearStartDate;
  bool chartDataLoaded = false;
  String? _selectedBranch;

  List<InventoryLevelList> stockData = [];
  List<InventoryLevelList> stockDataTemp = [];
  List<StockInTransitList> stockInTransitList = [];
  List<StockInTransitList> stockInTransitListTemp = [];
  String selectedSubGroup = 'Raw Material';

  DateTime selectedDate = DateTime.now();
  String formattedStartDate = "";
  String formattedEndDate = "";
  double targetStock = 0, actualStock = 0;
  Set<String>? selectedItems;

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
    Map<String, DateTime> monthDates = getMonthStartEndDates(
      selectedDate.month,
    );

    formattedStartDate = DateFormat('dd/MM/yy').format(monthDates["start"]!);
    formattedEndDate = DateFormat('dd/MM/yy').format(monthDates["end"]!);
  }

  Map<String, DateTime> getMonthStartEndDates(int month) {
    DateTime now = DateTime.now();

    int currentYear = now.year;

    int yearForMonth;
    if (now.month >= 1 && now.month <= 3) {
      yearForMonth = (month >= 4 && month <= 12)
          ? currentYear - 1
          : currentYear;
    } else {
      yearForMonth = (month >= 4 && month <= 12)
          ? currentYear
          : currentYear + 1;
    }

    DateTime firstDayOfMonth = DateTime(yearForMonth, month, 1);
    DateTime lastDayOfMonth = DateTime(yearForMonth, month + 1, 0);

    return {'start': firstDayOfMonth, 'end': lastDayOfMonth};
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

  SideTitles get _bottomTitlesItemStock => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<StockItemData> mData = stockStatementItemData.stockData;
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

  SideTitles get _bottomTitlesStockInTransit => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<StockItemData> mData = stockStatementTransitData.stockData;
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

  List<BarChartGroupData> _itemStockChartData(List<StockItemData> data) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color.fromARGB(255, 180, 157, 47),
                borderRadius: BorderRadius.zero,
                toY: chartData.targetStock,
                width: 15,
              ),
              BarChartRodData(
                color: const Color.fromARGB(255, 91, 181, 103),
                borderRadius: BorderRadius.zero,
                toY: chartData.actualStock,
                width: 15,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _stockInTransitChartData(List<StockItemData> data) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color.fromARGB(255, 199, 7, 173),
                borderRadius: BorderRadius.zero,
                toY: chartData.actualStock,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  Future<void> _loadDailyRMStatementAPI(
    String UserName,
    String UserLevel,
  ) async {
    int index = 0;
    int limit = 10000; // Maximum limit to fetch all data
    int fetchedCount = 0;
    List<InventoryLevelList> stockList = [];
    List<InventoryLevelList> filteredStockList = [];
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
            List<InventoryLevelList> newStockList =
                (responseJson['responseData'] as List)
                    .map((item) => InventoryLevelList.fromJson(item))
                    .toList();

            stockList.addAll(newStockList);
            fetchedCount = newStockList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      const groups = {'Raw Material', 'Packing Material', 'General Products'};

      filteredStockList = stockList
          .where((e) => groups.contains(e.groupName))
          .toList();

      setState(() {
        stockData = filteredStockList.toList();
        stockDataTemp = filteredStockList.toList();
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading stock statement.",
      );
    }
  }

  Future<void> _loadStockInTransitListAPI(
    String userName,
    String userLevel,
  ) async {
    int index = 0;
    const int limit = 10000;
    int fetchedCount = 0;
    List<StockInTransitList> stkList = [];
    const apiUrl = '${ApiHelper.baseUrl}CRM_StockTransitReport';
    try {
      do {
        final body = {
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        http.Response? response;

        // Retry logic
        for (int retry = 0; retry < 3; retry++) {
          try {
            response = await http
                .post(
                  Uri.parse(apiUrl),
                  headers: {HttpHeaders.contentTypeHeader: 'application/json'},
                  body: jsonEncode(body),
                )
                .timeout(const Duration(seconds: 25));

            if (response.statusCode == 200) break;
            if (response.statusCode == 502 || response.statusCode == 504) {
              await Future.delayed(const Duration(seconds: 2));
              continue;
            }
            break;
          } catch (_) {
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
        }

        if (response!.statusCode == 200) {
          final jsonMap = jsonDecode(response.body);
          final data = jsonMap["responseData"] ?? [];

          if (data == null || (data is List && data.isEmpty)) {
            fetchedCount = 0;
          } else {
            final parsed = parseStockList(data);
            stkList.addAll(parsed);
            fetchedCount = parsed.length;
            index++;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      // UPDATE UI
      if (!mounted) return;

      setState(() {
        if (stkList.isNotEmpty) {
          stockInTransitList = stkList;
          stockInTransitListTemp = stkList;
        }
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading stock in transit data.",
      );
    }
  }

  List<StockInTransitList> parseStockList(List<dynamic>? data) {
    if (data == null) {
      return [];
    }
    return data
        .where((e) => e != null)
        .map((e) => StockInTransitList.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<DailyStockAchievementData> get chartData =>
      dailyStockAchievementData.stockData
          .where((e) => e.itemSubGroup == selectedSubGroup)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  double get maxStockValue {
    if (chartData.isEmpty) return 0;

    return chartData
        .map(
          (e) => e.actualStock > e.targetStock ? e.actualStock : e.targetStock,
        )
        .reduce((a, b) => a > b ? a : b);
  }

  List<String> get subGroups {
    final groups =
        dailyStockAchievementData.stockData
            .map((e) => e.itemSubGroup.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return groups;
  }

  Future<void> _loadDailyRMGraph() async {
    if (stockData.isEmpty || _selectedBranch == null) return;
    final DateTime selected = selectedDate;

    final DateTime startDate = DateTime(selected.year, selected.month, 1);

    final DateTime endDate = DateTime(
      selected.year,
      selected.month + 1,
      0,
      23,
      59,
      59,
    );

    List<DailyStockAchievementData> stockDataList = [];

    // Filter selected month records
    final filteredList = stockData.where((e) {
      try {
        final docDate = DateFormat('dd/MM/yyyy').parse(e.documentDate);

        return docDate.isAtLeast(startDate) && docDate.isAtMost(endDate);
      } catch (_) {
        return false;
      }
    }).toList();

    // Group by Date + SubGroup
    final Map<String, List<InventoryLevelList>> groupedData = {};

    for (final item in filteredList) {
      if (_selectedBranch != "All Warehouses") {
        if (item.warehouseName != _selectedBranch) continue;
      }
      DateTime docDate = DateFormat('dd/MM/yyyy').parse(item.documentDate);

      String key =
          "${DateFormat('yyyy-MM-dd').format(docDate)}|${item.itemSubGroup}";

      groupedData.putIfAbsent(key, () => []);
      groupedData[key]!.add(item);
    }

    for (final entry in groupedData.entries) {
      final rows = entry.value;

      double actualStock = 0;
      double targetStock = 0;

      for (final row in rows) {
        actualStock += double.tryParse(row.quantity) ?? 0;
        targetStock += double.tryParse(row.minInventory) ?? 0;
      }

      double achievedPercentage = targetStock > 0
          ? (actualStock / targetStock) * 100
          : 0;

      stockDataList.add(
        DailyStockAchievementData(
          date: DateFormat('dd/MM/yyyy').parse(rows.first.documentDate),
          itemSubGroup: rows.first.itemSubGroup,
          targetStock: targetStock,
          actualStock: actualStock,
          achievedPercentage: achievedPercentage,
        ),
      );
    }

    stockDataList.sort((a, b) => a.date.compareTo(b.date));

    dailyStockAchievementData = DailyStockAchievementList(
      stockData: stockDataList,
    );

    final groups = stockDataList
        .map((e) => e.itemSubGroup.trim())
        .toSet()
        .toList();

    if (groups.isNotEmpty && !groups.contains(selectedSubGroup)) {
      selectedSubGroup = groups.first;
    }

    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> _loadItemGraph() async {
    if (stockData.isEmpty || _selectedBranch == null) return;

    Map<String, DateTime> monthDates = getMonthStartEndDates(
      selectedDate.month,
    );
    final DateTime startDate = monthDates["start"]!;
    final DateTime endDate = monthDates["end"]!;

    // Filter selected month records
    final applyWarehouseFilter =
        _selectedBranch != null &&
        _selectedBranch!.isNotEmpty &&
        _selectedBranch != 'All Warehouses';

    final filteredList = stockData.where((e) {
      try {
        final docDate = DateFormat('dd/MM/yyyy').parse(e.documentDate);

        if (!(docDate.isAtLeast(startDate) && docDate.isAtMost(endDate))) {
          return false;
        }

        if (applyWarehouseFilter && e.warehouseName != _selectedBranch) {
          return false;
        }

        return true;
      } catch (_) {
        return false;
      }
    }).toList();

    var inventoryList = filteredList.where(
      (e) => e.itemSubGroup == selectedSubGroup,
    );

    selectedItems = filteredList
        .where((e) => e.itemSubGroup == selectedSubGroup)
        .map((e) => e.itemDescription.trim())
        .toSet(); // to filter the stock in transit list

    String itemDescription = "";
    double actualStockQty = 0.00;
    double targetStockQty = 0.00;
    List<StockItemData> stkData = [];
    Set<String> processedItemCodes = {};

    for (var invList in inventoryList) {
      if (!processedItemCodes.contains(invList.itemDescription)) {
        itemDescription = invList.itemDescription;
        for (var list in inventoryList.where(
          (e) => e.itemDescription == itemDescription,
        )) {
          double actualQty = double.parse(list.quantity);
          actualStockQty += actualQty;
          double targetQty = double.parse(list.minInventory);
          targetStockQty += targetQty;
        }

        stkData.add(
          StockItemData(
            itemSubGroup: itemDescription,
            targetStock: targetStockQty,
            actualStock: actualStockQty,
            difference: targetStockQty - actualStockQty,
          ),
        );
        processedItemCodes.add(invList.itemDescription);
      }
      actualStockQty = 0;
      targetStockQty = 0;
      itemDescription = "";
    }

    stkData.sort(
      (a, b) => (b.targetStock - b.actualStock).compareTo(
        a.targetStock - a.actualStock,
      ),
    );

    stockStatementItemData = StockItemList(stockData: stkData);
    chartDataLoaded = true;
  }

  Future<void> _loadTransitGraph() async {
    if (stockInTransitList.isEmpty || selectedSubGroup == "") return;

    Map<String, DateTime> monthDates = getMonthStartEndDates(
      selectedDate.month,
    );
    final DateTime startDate = monthDates["start"]!;
    final DateTime endDate = monthDates["end"]!;

    // Filter selected month and warehouse records
    String selectedWarehouseCode = "";

    if (_selectedBranch != null &&
        _selectedBranch!.isNotEmpty &&
        _selectedBranch != "All Warehouses") {
      final warehouse = stockData.where(
        (e) => e.warehouseName == _selectedBranch,
      );

      if (warehouse.isNotEmpty) {
        selectedWarehouseCode = warehouse.first.warehouseCode;
      }
    }

    final applyWarehouseFilter =
        _selectedBranch != null &&
        _selectedBranch!.isNotEmpty &&
        _selectedBranch != 'All Warehouses';

    final filteredList = stockInTransitList.where((e) {
      try {
        final docDate = DateFormat('dd/MM/yyyy').parse(e.documentDate);

        if (!(docDate.isAtLeast(startDate) && docDate.isAtMost(endDate))) {
          return false;
        }

        if (applyWarehouseFilter && e.fromWarehouse != selectedWarehouseCode) {
          return false;
        }

        return true;
      } catch (_) {
        return false;
      }
    }).toList();

    var inventoryList = filteredList.where((data) {
      final subGroupMatch =
          selectedSubGroup.isEmpty ||
          (selectedItems?.contains(data.itemDescription.trim()) ?? false);

      return subGroupMatch;
    }).toList();

    String itemDescription = "";
    double actualStockQty = 0.00;
    List<StockItemData> stkData = [];
    Set<String> processedItemCodes = {};

    for (var invList in inventoryList) {
      if (!processedItemCodes.contains(invList.itemDescription)) {
        itemDescription = invList.itemDescription;
        for (var list in inventoryList.where(
          (e) => e.itemDescription == itemDescription,
        )) {
          double actualQty = double.parse(list.quantity);
          actualStockQty += actualQty;
        }

        stkData.add(
          StockItemData(
            itemSubGroup: itemDescription,
            targetStock: 0,
            actualStock: actualStockQty,
            difference: 0,
          ),
        );
        processedItemCodes.add(invList.itemDescription);
      }
      actualStockQty = 0;
      itemDescription = "";
    }

    stkData.sort((a, b) => (b.actualStock).compareTo(a.actualStock));

    stockStatementTransitData = StockItemList(stockData: stkData);
    chartDataLoaded = true;
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadDailyRMStatementAPI(userName, userLevel);
    await _loadStockInTransitListAPI(userName, userLevel);
    _selectedBranch = "All Warehouses";
    await _loadDailyRMGraph();
    await _loadItemGraph();
    await _loadTransitGraph();
  }

  Future<void> loadDataWithFilter() async {
    setState(() {
      chartDataLoaded = false;
    });
    stockData = stockDataTemp;
    stockInTransitList = stockInTransitListTemp;

    await _loadItemGraph();
    await _loadTransitGraph();
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> loadDataClearFilter() async {
    chartDataLoaded = false;
    stockData = stockDataTemp;
    stockInTransitList = stockInTransitListTemp;
    selectedSubGroup = selectedSubGroup = 'Raw Material';
    _selectedBranch = "All Warehouses";
    await _loadDailyRMGraph();
    await _loadItemGraph();
    await _loadTransitGraph();
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> exportDailyRMExcel() async {
    if (stockData.isEmpty) return;
    Map<String, DateTime> monthDates = getMonthStartEndDates(
      selectedDate.month,
    );

    final DateTime startDate = monthDates["start"]!;
    final DateTime endDate = monthDates["end"]!;
    List<List<dynamic>> rows = [];

    List<String> dayHeaders = [];

    for (
      DateTime d = startDate;
      !d.isAfter(endDate);
      d = d.add(const Duration(days: 1))
    ) {
      dayHeaders.add(DateFormat('dd-MMM').format(d));
    }
    final headers = [
      "Warehouse / Item Sub Group",
      "Closing Stock Target",
      "Actual Stock",
      ...dayHeaders,
      "Average %",
    ];
    final filteredList = stockData.where((e) {
      try {
        final docDate = DateFormat('dd/MM/yyyy').parse(e.documentDate);

        return !docDate.isBefore(startDate) && !docDate.isAfter(endDate);
      } catch (_) {
        return false;
      }
    }).toList();

    final Map<String, List<InventoryLevelList>> warehouseGroups = {};

    for (final item in filteredList) {
      warehouseGroups.putIfAbsent(item.warehouseName, () => []);

      warehouseGroups[item.warehouseName]!.add(item);
    }

    for (final warehouseEntry in warehouseGroups.entries) {
      final warehouseName = warehouseEntry.key;

      // Warehouse Header Row
      rows.add([
        warehouseName.toUpperCase(),
        "",
        "",
        ...List.filled(dayHeaders.length, ""),
        "",
      ]);

      final Map<String, List<InventoryLevelList>> subGroupMap = {};

      for (final item in warehouseEntry.value) {
        subGroupMap.putIfAbsent(item.itemSubGroup, () => []);

        subGroupMap[item.itemSubGroup]!.add(item);
      }

      for (final subGroupEntry in subGroupMap.entries) {
        final subGroup = subGroupEntry.key;

        double totalTarget = 0;
        double totalActual = 0;

        Map<String, double> dayPercentages = {};

        final Map<String, List<InventoryLevelList>> dateGroups = {};

        for (final item in subGroupEntry.value) {
          dateGroups.putIfAbsent(item.documentDate, () => []);

          dateGroups[item.documentDate]!.add(item);
        }

        for (final dateEntry in dateGroups.entries) {
          double dayActual = 0;
          double dayTarget = 0;

          for (final row in dateEntry.value) {
            dayActual += double.tryParse(row.quantity) ?? 0;
            dayTarget += double.tryParse(row.minInventory) ?? 0;
          }

          double percentage = dayTarget > 0
              ? double.parse(((dayActual / dayTarget) * 100).toStringAsFixed(2))
              : 0;

          final day = DateFormat(
            'dd-MMM',
          ).format(DateFormat('dd/MM/yyyy').parse(dateEntry.key));

          dayPercentages[day] = percentage;

          totalActual += dayActual;
          totalTarget += dayTarget;
        }

        final row = <dynamic>[
          subGroup,
          totalTarget.toStringAsFixed(2),
          totalActual.toStringAsFixed(2),
        ];

        for (final day in dayHeaders) {
          row.add(dayPercentages[day] ?? 0);
        }

        final avg = dayPercentages.isEmpty
            ? 0
            : dayPercentages.values.reduce((a, b) => a + b) /
                  dayPercentages.length;

        row.add(avg);

        rows.add(row);
      }

      // Blank Row After Each Warehouse
      rows.add(List.filled(headers.length, ""));
    }

    rows.add([
      "BAGLUR - RAW Material",
      0,
      0,
      ...List.filled(dayHeaders.length, 0),
      0,
    ]);

    rows.add([
      "MD Export-RM+PM",
      0,
      0,
      ...List.filled(dayHeaders.length, 0),
      0,
    ]);

    rows.add([
      "IPD Export-RM+PM",
      0,
      0,
      ...List.filled(dayHeaders.length, 0),
      0,
    ]);

    await reportService.generateExcel(
      sheetName: "Daily RM Report",
      headers: headers,
      rows: rows,
      fileName:
          "Daily_RM_Report_${DateFormat('MMM_yyyy').format(selectedDate)}.xlsx",
      amountColumns: [],
      addTotalRow: false,
      reportTitle: 'Production[MIS] - Daily Raw Materials Report',
    );
  }

  Future<void> generateItemStockStatementExcel(
    BuildContext context,
    StockItemList stockStatementItemData,
  ) async {
    int slNo = 1;
    await reportService.generateExcel(
      sheetName: 'ItemWiseStockStatement',
      headers: ['SL NO', 'Item Name', 'Target', 'Actual stock', 'Difference'],
      rows: stockStatementItemData.stockData
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
      fileName: 'rm_item_wise_stock_statement.xlsx',
      amountColumns: [3, 4, 5],
      addTotalRow: true,
      reportTitle: 'Production[MIS] - RM Item Wise Stock Statement',
    );
  }

  Future<void> generateStockTransitStatementExcel(
    BuildContext context,
    StockItemList stockStatementTransitData,
  ) async {
    int slNo = 1;
    await reportService.generateExcel(
      sheetName: 'StockInTransitStatement',
      headers: ['SL NO', 'Item Name', 'Stock In Transit'],
      rows: stockStatementTransitData.stockData
          .map(
            (stkData) => [
              slNo++,
              stkData
                  .itemSubGroup, // Item name will come in itemSubGroup field in this chart
              stkData.actualStock,
            ],
          )
          .toList(),
      fileName: 'rm_stock_in_transit_statement.xlsx',
      amountColumns: [3],
      addTotalRow: true,
      reportTitle: 'Production[MIS] - RM Stock In Transit Statement',
    );
  }

  Future<void> selectMonth(BuildContext context) async {
    final DateTime? picked = await showMonthPicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2100),
    );
    if (picked != null &&
        (picked.month != selectedDate.month ||
            picked.year != selectedDate.year)) {
      setState(() {
        selectedDate = picked;
      });
      LoadDates();
      await _loadDailyRMGraph();
      loadDataWithFilter();
    }
  }

  int get aboveAverageDays {
    return chartData
        .where((e) => e.achievedPercentage >= monthlyAveragePercentage)
        .length;
  }

  double get monthlyAveragePercentage {
    final values = chartData
        .map((e) => e.achievedPercentage)
        .where((e) => e > 0)
        .toList();

    if (values.isEmpty) return 0;

    return values.reduce((a, b) => a + b) / values.length;
  }

  double get bestAchievement {
    if (chartData.isEmpty) return 0;

    return chartData.map((e) => e.achievedPercentage).reduce(max);
  }

  double get worstAchievement {
    final values = chartData
        .map((e) => e.achievedPercentage)
        .where((e) => e > 0)
        .toList();

    if (values.isEmpty) return 0;

    return values.reduce(min);
  }

  List<FlSpot> _achievementSpots() {
    return chartData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.achievedPercentage);
    }).toList();
  }

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _itemHorizontalController = ScrollController();
  final ScrollController _transitHorizontalController = ScrollController();
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
    _itemHorizontalController.dispose();
    _transitHorizontalController.dispose();
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
                        Text("$formattedStartDate - $formattedEndDate"),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            selectMonth(context);
                          },
                          icon: const Icon(Icons.calendar_month),
                        ),
                        const SizedBox(width: 5),
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
                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: "Daily Raw Material Achievement Trend",
                    spacing: 10,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          exportDailyRMExcel();
                        },
                        child: const Text("Download Excel"),
                      ),
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            BranchDropdown(
                              production: stockData,
                              selectedValue: _selectedBranch,
                              onChanged: (newValue) async {
                                setState(() {
                                  _selectedBranch =
                                      newValue ?? "All Warehouses";
                                });
                                if (newValue != null) {
                                  await _loadDailyRMGraph();
                                  await _loadItemGraph();
                                  await _loadTransitGraph();
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _subGroupTabs(),
                        const SizedBox(height: 10),
                        _achievementKPIs(),
                        const SizedBox(height: 12),
                        _achievementTrendChart(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Item Wise Stock',
                    spacing: 10,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color.fromARGB(255, 180, 157, 47),
                        ),
                        const SizedBox(width: 5),
                        const Text('Target', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 10),

                        Container(
                          height: 8,
                          width: 8,
                          color: const Color.fromARGB(255, 91, 181, 103),
                        ),
                        const SizedBox(width: 5),
                        const Text('Actual', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateItemStockStatementExcel(
                            context,
                            stockStatementItemData,
                          );
                        },
                        child: const Text("Download Excel"),
                      ),
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [const SizedBox(height: 16), _itemGraph()],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Stock In Transit',
                    spacing: 10,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color.fromARGB(255, 199, 7, 173),
                        ),
                        const SizedBox(width: 5),
                        const Text('Transit', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateStockTransitStatementExcel(
                            context,
                            stockStatementTransitData,
                          );
                        },
                        child: const Text("Download Excel"),
                      ),
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _stockInTransitGraph(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  Widget _achievementKPIs() {
    double cardWidth = MediaQuery.of(context).size.width > 1200
        ? 180
        : MediaQuery.of(context).size.width > 800
        ? 150
        : 100;
    return Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          width: cardWidth,
          child: _buildInfoCard(
            'Average',
            '${monthlyAveragePercentage.toStringAsFixed(1)}%',
          ),
        ),
        SizedBox(
          width: cardWidth,
          child: _buildInfoCard(
            'Best',
            '${bestAchievement.toStringAsFixed(1)}%',
          ),
        ),
        SizedBox(
          width: cardWidth,
          child: _buildInfoCard(
            'Worst',
            '${worstAchievement.toStringAsFixed(1)}%',
          ),
        ),
      ],
    );
  }

  Widget _achievementBottomTitle(double value, TitleMeta meta) {
    if (value != value.roundToDouble()) {
      return const SizedBox();
    }

    final index = value.toInt();

    if (index < 0 || index >= chartData.length) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(
        DateFormat('dd').format(chartData[index].date),
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _achievementTrendChart() {
    if (chartData.isEmpty) {
      return const SizedBox(
        height: 350,
        child: Center(child: Text("No data available")),
      );
    }
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = chartData.length;
    if (chartData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    return FinanceHorizontalChartScroll(
      controller: _horizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: max(
                60,
                chartData
                        .map((e) => e.achievedPercentage)
                        .reduce((a, b) => a > b ? a : b) *
                    1.1,
              ),

              gridData: FlGridData(show: true),

              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 45),
                ),

                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),

                topTitles: AxisTitles(sideTitles: _emptyTitlesTop),

                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: _achievementBottomTitle,
                  ),
                ),
              ),

              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,

                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (_) => Colors.white,
                  tooltipBorder: const BorderSide(color: Colors.grey, width: 1),

                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      if (spot.barIndex == 1) {
                        return null;
                      }

                      final item = chartData[spot.x.toInt()];

                      return LineTooltipItem(
                        "${DateFormat('dd-MMM-yyyy').format(item.date)}\n"
                        "Target : ${formatAmount(item.targetStock)}\n"
                        "Actual : ${formatAmount(item.actualStock)}\n"
                        "Achievement : ${item.achievedPercentage.toStringAsFixed(1)}%\n"
                        "Monthly Avg : ${monthlyAveragePercentage.toStringAsFixed(1)}%",
                        const TextStyle(color: Colors.black, fontSize: 12),
                      );
                    }).toList();
                  },
                ),
              ),

              lineBarsData: [
                // Achievement Line
                LineChartBarData(
                  spots: _achievementSpots(),
                  isCurved: true,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                ),
              ],
              // Monthly Average Line
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: monthlyAveragePercentage,
                    dashArray: [5, 5],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF97D7F3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Center(
            child: Text('$title\n$value', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  Widget _subGroupTabs() {
    if (subGroups.isEmpty) {
      return const SizedBox();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 50,
          child: SingleChildScrollView(
            controller: _tabScrollController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(subGroups.length, (index) {
                  final group = subGroups[index];
                  final isSelected = group == selectedSubGroup;

                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == subGroups.length - 1 ? 0 : 8,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: () {
                        setState(() {
                          selectedSubGroup = group;
                        });
                        loadDataWithFilter();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1976D2)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          group,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _itemGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = stockStatementItemData.stockData.take(50).length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double? maxY = stockStatementItemData.stockData.isNotEmpty
        ? stockStatementItemData.stockData
              .map(
                (e) => e.actualStock > e.targetStock
                    ? e.actualStock
                    : e.targetStock,
              )
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return FinanceHorizontalChartScroll(
      controller: _itemHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 300,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(maxY),
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
                  sideTitles: _bottomTitlesItemStock,
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
              barGroups: _itemStockChartData(
                stockStatementItemData.stockData.take(50).toList(),
              ),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  maxContentWidth: 200,
                  tooltipBorder: const BorderSide(
                    width: 2.0,
                    color: Colors.black12,
                    style: BorderStyle.none,
                  ),
                  getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                    return BarTooltipItem(
                      stockStatementItemData.stockData[grpIndex].itemSubGroup,
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "\nTarget Stock : ${formatAmount(stockStatementItemData.stockData[grpIndex].targetStock)}",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "\nActual Stock : ${formatAmount(stockStatementItemData.stockData[grpIndex].actualStock)}",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "\nDifference : ${formatAmount(stockStatementItemData.stockData[grpIndex].difference)}",
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

  Widget _stockInTransitGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = stockStatementTransitData.stockData.take(50).length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double? maxY = stockStatementTransitData.stockData.isNotEmpty
        ? stockStatementTransitData.stockData
              .map(
                (e) => e.actualStock > e.targetStock
                    ? e.actualStock
                    : e.targetStock,
              )
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return FinanceHorizontalChartScroll(
      controller: _transitHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 300,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(maxY),
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
                  sideTitles: _bottomTitlesStockInTransit,
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
              barGroups: _stockInTransitChartData(
                stockStatementTransitData.stockData.take(50).toList(),
              ),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  maxContentWidth: 200,
                  tooltipBorder: const BorderSide(
                    width: 2.0,
                    color: Colors.black12,
                    style: BorderStyle.none,
                  ),
                  getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                    return BarTooltipItem(
                      stockStatementTransitData
                          .stockData[grpIndex]
                          .itemSubGroup,
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "\nStock In Transit: ${formatAmount(stockStatementTransitData.stockData[grpIndex].actualStock)}",
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
        setState(() {
          loadDataFuture = loadDataClearFilter();
        });
      }
    });
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
