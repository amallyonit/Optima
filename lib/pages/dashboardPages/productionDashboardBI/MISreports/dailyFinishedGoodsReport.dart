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

class DailyFinishedGoodsReport extends StatefulWidget {
  const DailyFinishedGoodsReport({super.key});

  @override
  State<DailyFinishedGoodsReport> createState() =>
      _DailyFinishedGoodsReportState();
}

class MonthInfo {
  final String previous;
  final String current;
  final String next;

  MonthInfo({
    required this.previous,
    required this.current,
    required this.next,
  });
}

class _DailyFinishedGoodsReportState extends State<DailyFinishedGoodsReport> {
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

  List<CRMInventoryList> stockData = [];
  List<CRMInventoryList> stockDataTemp = [];
  List<CRMInventorySummaryList> stockSummaryData = [];
  List<CRMInventorySummaryList> stockSummaryDataTemp = [];
  List<StockInTransitList> stockInTransitList = [];
  List<StockInTransitList> stockInTransitListTemp = [];
  List<SalesTargetList> salesTargetList = [];

  String selectedGroup = '';

  DateTime selectedDate = DateTime.now();
  String formattedStartDate = "";
  String formattedEndDate = "";
  double targetStock = 0, actualStock = 0;
  Set<String>? selectedItems;
  String UserName = "";
  String UserLevel = "";

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
              BarChartRodData(
                color: const Color.fromARGB(255, 239, 202, 18),
                borderRadius: BorderRadius.zero,
                toY: chartData.actualStockValue,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<SalesTargetList> parseSalesTargetList(List<dynamic> data) {
    return data.map((e) => SalesTargetList.fromJson(e)).toList();
  }

  Future<void> _loadSalesTargetAPI(String userName, String userLevel) async {
    final fromDate = formatDate(fiscalYearStartDate!);

    final toDate = formatDate(currentDate!);

    final body = {
      "FromDate": fromDate,
      "ToDate": toDate,
      "Index": 0,
      "Limit": 0,
      "sapToken": DataManager.readSapToken(),
    };

    const apiUrl = '${ApiHelper.baseUrl}BicxoSalesTargetList';

    try {
      late http.Response response;

      // Retry for network/504/502 issues
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

          break; // other errors → stop retry
        } catch (_) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      // Handle token expiration
      if (response.statusCode == 401 ||
          response.body.contains("Invalid or Expired Token")) {
        if (!mounted) return;
        NotificationService.warning(
          title: "Security Alert",
          message: "Invalid or Expired Token.",
        );
        return;
      }

      if (response.statusCode != 200) {
        if (!mounted) return;
        NotificationService.error(
          title: "Error",
          message: "Error occured while loading sales target data.",
        );
        return;
      }

      final jsonMap = jsonDecode(response.body);

      final List<dynamic>? data = jsonMap["responseData"] ?? [];

      if (data == null || data.isEmpty) {
        if (!mounted) return;
        NotificationService.error(
          title: "Error",
          message: "Error occured while loading sales target data.",
        );
        return;
      }

      final parsedList = parseSalesTargetList(data);
      if (!mounted) return;

      // UPDATE UI
      setState(() {
        salesTargetList = List.from(parsedList); // applies to all user levels
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading sales target data.",
      );
    }
  }

  Future<void> _loadDailyFGStatementAPI(
    String UserName,
    String UserLevel,
  ) async {
    int index = 0;
    int limit = 10000; // Maximum limit to fetch all data
    int fetchedCount = 0;
    List<CRMInventoryList> stockList = [];
    List<CRMInventoryList> filteredStockList = [];
    final toDate = formatDate(currentDate!);
    try {
      do {
        var body = {
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}CRMInventoryList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<CRMInventoryList> newStockList =
                (responseJson['responseData'] as List)
                    .map((item) => CRMInventoryList.fromJson(item))
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

      filteredStockList = stockList
          .where((e) => e.misfgItemGroups != "")
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

  Future<void> _loadDailyFGSummaryAPI(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000; // Maximum limit to fetch all data
    int fetchedCount = 0;
    List<CRMInventorySummaryList> stockSummaryList = [];
    List<CRMInventorySummaryList> filteredStockSummaryList = [];
    Map<String, DateTime> monthDates = getMonthStartEndDates(
      selectedDate.month,
    );
    final DateTime startDate = monthDates["start"]!;
    final DateTime endDate = monthDates["end"]!;
    try {
      do {
        var body = {
          "FromDate": formatDate(startDate),
          "ToDate": formatDate(endDate),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}CRMInventorySummaryList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<CRMInventorySummaryList> newStockList =
                (responseJson['responseData'] as List)
                    .map((item) => CRMInventorySummaryList.fromJson(item))
                    .toList();

            stockSummaryList.addAll(newStockList);
            fetchedCount = newStockList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      filteredStockSummaryList = stockSummaryList
          .where((e) => e.fgLocation != "")
          .toList();

      setState(() {
        stockSummaryData = filteredStockSummaryList.toList();
        stockSummaryDataTemp = filteredStockSummaryList.toList();
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading stock summary data.",
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
          .where((e) => e.itemGroup == selectedGroup)
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

  List<String> get groupsList {
    final groups =
        ([...dailyStockAchievementData.stockData]
              ..sort((a, b) => b.targetStock.compareTo(a.targetStock)))
            .map((e) => e.itemGroup.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();

    return groups;
  }

  MonthInfo getMonths(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final previous = months[(date.month + 10) % 12];
    final current = months[date.month - 1];
    final next = months[(date.month) % 12];

    return MonthInfo(previous: previous, current: current, next: next);
  }

  double parseValue(String? value) {
    return double.tryParse(value?.replaceAll(',', '') ?? '') ?? 0;
  }

  DateTime? parseDate(String value) {
    for (final format in [
      DateFormat('dd-MM-yyyy'),
      DateFormat('dd/MM/yyyy'),
      DateFormat('yyyy-MM-dd'),
    ]) {
      try {
        return format.parseStrict(value);
      } catch (_) {}
    }
    return null;
  }

  Future<void> _loadDailyFGGraph() async {
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
    final months = getMonths(selected);
    List<DailyStockAchievementData> stockDataList = [];

    // Filter selected month records
    final filteredList = stockData.where((e) {
      try {
        final docDate = parseDate(e.docDate);
        if (docDate == null) return false;
        return docDate.isAtLeast(startDate) && docDate.isAtMost(endDate);
      } catch (_) {
        return false;
      }
    }).toList();

    // Group by Date + SubGroup
    final Map<String, List<CRMInventoryList>> groupedData = {};

    for (final item in filteredList) {
      if (_selectedBranch != "All Warehouses") {
        if (item.warehouseName != _selectedBranch) continue;
      }
      DateTime docDate = parseDate(item.docDate)!;

      String key =
          "${DateFormat('yyyy-MM-dd').format(docDate)}|${item.misfgItemGroups}";

      groupedData.putIfAbsent(key, () => []);
      groupedData[key]!.add(item);
    }

    for (final entry in groupedData.entries) {
      final rows = entry.value;

      double actualStock = 0;
      double targetStock = 0;

      targetStock = salesTargetList
          .where((target) {
            return target.salesRep == rows.first.misfgItemGroups;
          })
          .fold(
            0.0,
            (sum, target) =>
                sum + parseValue(target.getTargetForMonth(months.current)),
          );

      for (final row in rows) {
        actualStock += double.tryParse(row.totalValue) ?? 0;
      }

      double achievedPercentage = targetStock > 0
          ? (actualStock / targetStock) * 100
          : 0;

      stockDataList.add(
        DailyStockAchievementData(
          date: parseDate(rows.first.docDate)!,
          itemGroup: rows.first.misfgItemGroups,
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

    final groups =
        ([...dailyStockAchievementData.stockData]
              ..sort((a, b) => b.targetStock.compareTo(a.targetStock)))
            .map((e) => e.itemGroup.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();

    if (groups.isNotEmpty && !groups.contains(selectedGroup)) {
      selectedGroup = groups.first;
    }
  }

  Future<void> _loadItemGraph() async {
    if (stockData.isEmpty || _selectedBranch == null) return;
    final months = getMonths(selectedDate);
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
        final docDate = parseDate(e.docDate);
        if (docDate == null) return false;
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

    var inventoryList = filteredList.where((e) {
      return e.misfgItemGroups == selectedGroup;
    });

    selectedItems = filteredList
        .where((e) {
          return e.misfgItemGroups == selectedGroup;
        })
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
          double actualQty = double.parse(list.totalQuantity);
          actualStockQty += actualQty;
        }

        targetStockQty = salesTargetList
            .where((target) {
              return target.salesRep == invList.misfgItemGroups;
            })
            .fold(
              0.0,
              (sum, target) =>
                  sum + parseValue(target.getTargetForMonth(months.current)),
            );

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
  }

  Future<void> _loadTransitGraph() async {
    if (stockInTransitList.isEmpty || selectedGroup == "") return;

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
        final docDate = parseDate(e.documentDate);
        if (docDate == null) return false;
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
      final groupMatch =
          selectedGroup.isEmpty ||
          (selectedItems?.contains(data.itemDescription.trim()) ?? false);

      return groupMatch;
    }).toList();

    String itemDescription = "";
    double actualStockQty = 0.00;
    double actualStockVal = 0.00;
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
          actualStockVal += double.parse(list.lineTotal);
        }

        stkData.add(
          StockItemData(
            itemSubGroup: itemDescription,
            targetStock: 0,
            actualStock: actualStockQty,
            difference: 0,
            actualStockValue: actualStockVal,
          ),
        );
        processedItemCodes.add(invList.itemDescription);
      }
      actualStockQty = 0;
      actualStockVal = 0;
      itemDescription = "";
    }

    stkData.sort((a, b) => (b.actualStockValue).compareTo(a.actualStockValue));

    stockStatementTransitData = StockItemList(stockData: stkData);
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadDailyFGStatementAPI(userName, userLevel);
    await _loadDailyFGSummaryAPI(userName, userLevel);
    await _loadStockInTransitListAPI(userName, userLevel);
    await _loadSalesTargetAPI(userName, userLevel);
    _selectedBranch = "All Warehouses";
    UserName = userName;
    UserLevel = userLevel;
    await _loadDailyFGGraph();
    await _loadItemGraph();
    await _loadTransitGraph();
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> loadDataWithFilter() async {
    stockData = stockDataTemp;
    stockInTransitList = stockInTransitListTemp;

    await _loadItemGraph();
    await _loadTransitGraph();
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> loadDataClearFilter() async {
    setState(() {
      chartDataLoaded = false;
    });
    stockData = stockDataTemp;
    stockInTransitList = stockInTransitListTemp;
    selectedGroup = '';
    _selectedBranch = "All Warehouses";
    await _loadDailyFGGraph();
    await _loadItemGraph();
    await _loadTransitGraph();
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> exportDailyFGExcel() async {
    if (stockSummaryData.isEmpty) return;
    Map<String, DateTime> monthDates = getMonthStartEndDates(
      selectedDate.month,
    );

    final DateTime startDate = monthDates["start"]!;

    final DateTime endDate =
        (selectedDate.year == currentDate!.year &&
            selectedDate.month == currentDate!.month)
        ? currentDate!
        : monthDates["end"]!;
    List<List<dynamic>> rows = [];
    List<String> dayHeaders = [];
    List<String> dayKeys = [];
    final months = getMonths(selectedDate);

    Map<String, double> targetMap = {};
    for (final target in salesTargetList) {
      targetMap[target.salesRep] =
          (targetMap[target.salesRep] ?? 0) +
          parseValue(target.getTargetForMonth(months.current));
    }

    for (
      DateTime d = endDate;
      !d.isBefore(startDate);
      d = d.add(const Duration(days: -1))
    ) {
      final key = DateFormat('dd-MMM').format(d);

      dayKeys.add(key);
      dayHeaders.add('$key (Ach %)');
    }

    final headers = [
      "Name of Branch/Depot",
      "Closing Stock Target",
      "Actual Stock",
      ...dayHeaders,
      "Average %",
    ];
    
    final filteredList = stockSummaryData
        .where((e) {
          final docDate = parseDate(e.docDate);
          if (docDate == null) return false;

          return !docDate.isBefore(startDate) && !docDate.isAfter(endDate);
        })
        .where((e) => e.fgLocation.toLowerCase() != 'bagluru')
        .toList();

    addWarehouseSection(
      rows: rows,
      data: filteredList,
      targetMap: targetMap,
      headers: headers,
      dayKeys: dayKeys,
      endDate: endDate,
      showWarehouseHeader: true,
    );

    addTotalRow(
      rows: rows,
      data: filteredList,
      title: "TOTAL (Excluding Bagluru & Export)",
      targetMap: targetMap,
      dayKeys: dayKeys,
      endDate: endDate,
    );

    //Data for Bagluru, MD Export-RM+PM, IPD Export-RM+PM
    final footerDataList = stockSummaryData
        .where((e) {
          final docDate = parseDate(e.docDate);

          if (docDate == null) return false;

          return !docDate.isBefore(startDate) && !docDate.isAfter(endDate);
        })
        .where((e) => e.fgLocation.toLowerCase() == 'bagluru')
        .toList();

    rows.add(List.filled(headers.length, ""));
    addWarehouseSection(
      rows: rows,
      data: footerDataList,
      targetMap: targetMap,
      headers: headers,
      dayKeys: dayKeys,
      endDate: endDate,
      showWarehouseHeader: true,
    );
    final grandTotalList = stockSummaryData.where((e) {
      final docDate = parseDate(e.docDate);
      if (docDate == null) return false;

      return !docDate.isBefore(startDate) && !docDate.isAfter(endDate);
    }).toList();
    addTotalRow(
      rows: rows,
      data: grandTotalList,
      title: "GRAND TOTAL",
      targetMap: targetMap,
      dayKeys: dayKeys,
      endDate: endDate,
    );
    await reportService.generateExcel(
      sheetName: "Daily FG Report",
      headers: headers,
      rows: rows,
      fileName:
          "Daily_FG_Report_${DateFormat('MMM_yyyy').format(selectedDate)}.xlsx",
      amountColumns: [],
      addTotalRow: false,
      reportTitle:
          'Production[MIS] - Daily Finished Goods Report ${DateFormat('MMM yyyy').format(selectedDate)}',
      highlightSections: true,
    );
  }

  void addWarehouseSection({
    required List<List<dynamic>> rows,
    required List<CRMInventorySummaryList> data,
    required Map<String, double> targetMap,
    required List<String> headers,
    required List<String> dayKeys,
    required DateTime endDate,
    required bool showWarehouseHeader,
  }) {
    late Map<String, List<CRMInventorySummaryList>> warehouseGroups = {};

    for (final item in data.where((e) => e.fgLocation.isNotEmpty)) {
      warehouseGroups.putIfAbsent(item.fgLocation, () => []);

      warehouseGroups[item.fgLocation]!.add(item);
    }

    warehouseGroups = Map.fromEntries(
      warehouseGroups.entries.toList()
        ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase())),
    );

    for (final warehouseEntry in warehouseGroups.entries) {
      final warehouseName = warehouseEntry.key;

      if (showWarehouseHeader) {
        rows.add([
          warehouseName.toUpperCase(),
          "",
          "",
          ...List.filled(dayKeys.length, ""),
          "",
        ]);
      }

      final Map<String, List<CRMInventorySummaryList>> groupMap = {};

      for (final item in warehouseEntry.value.where(
        (e) => e.misfgItemGroups.isNotEmpty,
      )) {
        groupMap.putIfAbsent(item.misfgItemGroups, () => []);

        groupMap[item.misfgItemGroups]!.add(item);
      }

      final sortedEntries = groupMap.entries.toList()
        ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

      for (final groupEntry in sortedEntries) {
        final group = groupEntry.key;

        double totalTarget = targetMap[group] ?? 0;
        double totalActual = 0;

        Map<String, double> dayPercentages = {};

        for (final item in groupEntry.value) {
          final dayActual = double.tryParse(item.totalValue) ?? 0;

          final percentage = totalTarget > 0
              ? (dayActual / totalTarget) * 100
              : 0;

          final day = DateFormat('dd-MMM').format(parseDate(item.docDate)!);

          dayPercentages[day] = double.parse(percentage.toStringAsFixed(2));
        }

        groupEntry.value.sort(
          (a, b) => parseDate(b.docDate)!.compareTo(parseDate(a.docDate)!),
        );

        totalActual = double.tryParse(groupEntry.value.last.totalValue) ?? 0;

        final row = <dynamic>[
          group,
          totalTarget.toStringAsFixed(2),
          totalActual.toStringAsFixed(2),
        ];

        for (final day in dayKeys) {
          row.add(dayPercentages[day] ?? 0);
        }

        double avg = dayPercentages.isEmpty
            ? 0
            : dayPercentages.values.reduce((a, b) => a + b) /
                  dayPercentages.length;

        row.add(double.parse(avg.toStringAsFixed(2)));

        rows.add(row);
      }

      rows.add(List.filled(headers.length, ""));
    }
  }

  void addTotalRow({
    required List<List<dynamic>> rows,
    required List<CRMInventorySummaryList> data,
    required String title,
    required Map<String, double> targetMap,
    required List<String> dayKeys,
    required DateTime endDate,
  }) {
    double totalTarget = 0;
    double totalActual = 0;

    Map<String, double> dayActualMap = {};

    // Target
    // Target (only displayed groups)
    final processedGroups = <String>{};

    for (final item in data) {
      processedGroups.add(item.misfgItemGroups);
    }

    for (final group in processedGroups) {
      totalTarget += targetMap[group] ?? 0;
    }

    // =================== ACTUALS ===================

    // Group by MIS Group
    Map<String, List<CRMInventorySummaryList>> groupMap = {};

    for (final item in data) {
      groupMap.putIfAbsent(item.misfgItemGroups, () => []);
      groupMap[item.misfgItemGroups]!.add(item);
    }

    // Process each group
    for (final group in groupMap.values) {
      // Sort by Day Number
      group.sort((a, b) => int.parse(a.dayNo).compareTo(int.parse(b.dayNo)));

      // Last day's closing stock for this group
      totalActual += parseValue(group.last.totalValue);
      // Build day totals for Ach %
      for (final item in group) {
        final value = parseValue(item.totalValue);

        final day = DateFormat('dd-MMM').format(parseDate(item.docDate)!);

        dayActualMap[day] = (dayActualMap[day] ?? 0) + value;
      }
    }

    List<dynamic> row = [
      title,
      totalTarget.toStringAsFixed(2),
      totalActual.toStringAsFixed(2),
    ];

    double totalPercentage = 0;

    for (final day in dayKeys) {
      final actual = dayActualMap[day] ?? 0;

      final percentage = totalTarget == 0 ? 0 : (actual / totalTarget) * 100;

      row.add(double.parse(percentage.toStringAsFixed(2)));

      totalPercentage += percentage;
    }

    row.add(
      double.parse((totalPercentage / dayKeys.length).toStringAsFixed(2)),
    );

    rows.add(row);
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
      fileName: 'fg_item_wise_stock_statement.xlsx',
      amountColumns: [3, 4, 5],
      addTotalRow: true,
      reportTitle:
          'Production[MIS] - FG Item Wise Stock Statement ${DateFormat('MMM yyyy').format(selectedDate)} - $selectedGroup',
    );
  }

  Future<void> generateStockTransitStatementExcel(
    BuildContext context,
    StockItemList stockStatementTransitData,
  ) async {
    int slNo = 1;
    await reportService.generateExcel(
      sheetName: 'StockInTransitStatement',
      headers: ['SL NO', 'Item Name', 'S I T (QTY)', 'S I T (Value)'],
      rows: stockStatementTransitData.stockData
          .map(
            (stkData) => [
              slNo++,
              stkData
                  .itemSubGroup, // Item name will come in itemSubGroup field in this chart
              stkData.actualStock,
              stkData.actualStockValue,
            ],
          )
          .toList(),
      fileName: 'fg_stock_in_transit_statement.xlsx',
      amountColumns: [3, 4],
      addTotalRow: true,
      reportTitle:
          'Production[MIS] - FG Stock In Transit Statement ${DateFormat('MMM yyyy').format(selectedDate)} - $selectedGroup',
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
        chartDataLoaded = false;
      });
      LoadDates();
      await _loadDailyFGSummaryAPI(UserName, UserLevel);
      await _loadDailyFGGraph();
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
                    title: "Daily Finished Goods Achievement Trend",
                    spacing: 10,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          exportDailyFGExcel();
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
                                  await _loadDailyFGGraph();
                                  await _loadItemGraph();
                                  await _loadTransitGraph();
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _groupTabs(),
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
                        const Text('Quantity', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color.fromARGB(255, 239, 202, 18),
                        ),
                        const SizedBox(width: 5),
                        const Text('Value', style: TextStyle(fontSize: 12)),
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

  Widget _groupTabs() {
    if (groupsList.isEmpty) {
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
                children: List.generate(groupsList.length, (index) {
                  final group = groupsList[index];
                  final isSelected = group == selectedGroup;

                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == groupsList.length - 1 ? 0 : 8,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: () {
                        setState(() {
                          selectedGroup = group;
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
                (e) => e.actualStock > e.actualStockValue
                    ? e.actualStock
                    : e.actualStockValue,
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
                              "\nS I T(QTY): ${formatAmount(stockStatementTransitData.stockData[grpIndex].actualStock)}",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "\nS I T(Value): ${formatAmount(stockStatementTransitData.stockData[grpIndex].actualStockValue)}",
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
