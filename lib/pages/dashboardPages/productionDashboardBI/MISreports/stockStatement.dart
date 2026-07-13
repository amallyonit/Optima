// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import '../../../../notificationService.dart';
import '../../dashboard_card_ui.dart';
import '../../ReportService.dart';
import '../../report_service_platform.dart';

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

class WarehouseStockRow {
  final String rowLabel;

  final Map<String, double> target;
  final Map<String, double> actual;
  final Map<String, double> difference;

  WarehouseStockRow({
    required this.rowLabel,
    required this.target,
    required this.actual,
    required this.difference,
  });
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

class _StockStatementPageState extends State<StockStatementPage> {
  final reportService = ReportService();

  StockItemList stockStatementData = StockItemList(stockData: []);
  StockItemList stockStatementItemData = StockItemList(stockData: []);
  StockItemList stockStatementTransitData = StockItemList(stockData: []);
  late Future<void> loadDataFuture;
  DateTime? currentDate;
  DateTime? fiscalYearStartDate;
  bool chartDataLoaded = false;

  // List<InventoryLevelList> stockData = [];
  // List<InventoryLevelList> stockDataTemp = [];
  List<CRMInventoryList> stockData = [];
  List<CRMInventoryList> stockDataTemp = [];
  List<StockInTransitList> stockInTransitList = [];
  List<StockInTransitList> stockInTransitListTemp = [];
  List<WarehouseWiseStockData> warehouseWiseStockData = [];
  List<SalesTargetList> salesTargetList = [];
  List<SalesTargetList> salesTargetListTemp = [];

  double targetStockHeader = 0;
  double actualStockHeader = 0;
  double differenceStockHeader = 0;

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
  }

  String touchedGroup = "";
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

  String? _selectedBranch;

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

  List<BarChartGroupData> _stockChartData(List<StockItemData> data) {
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

  Future<void> _loadStockStatementAPI(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000; // Maximum limit to fetch all data
    int fetchedCount = 0;
    List<CRMInventoryList> invList = [];
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
            List<CRMInventoryList> newList =
                (responseJson['responseData'] as List)
                    .map((item) => CRMInventoryList.fromJson(item))
                    .toList();
            invList.addAll(newList);
            fetchedCount = newList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        stockData = invList.where((e) => e.fgLocation != "").toList();
        stockDataTemp = invList.where((e) => e.fgLocation != "").toList();
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading stock statement.",
      );
    }
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
        salesTargetListTemp = List.from(
          parsedList,
        ); // applies to all user levels
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading sales target data.",
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

  Future<void> _loadItemGroupGraph() async {
    var inventoryList = stockData;
    String itemGroup = "";
    double actualStockVal = 0.00;
    double targetStockVal = 0.00;
    List<StockItemData> stkData = [];
    Set<String> processedItemGroupCodes = {};
    List<SalesTargetList> tmpTargetList = [];
    final Map<String, double> targetCache = {};
    final months = getMonths(currentDate!);

    for (var invList in inventoryList) {
      if (!processedItemGroupCodes.contains(invList.itemGroup)) {
        itemGroup = invList.itemGroup;
        for (var list in inventoryList.where((e) => e.itemGroup == itemGroup)) {
          double actualVal = double.parse(list.totalValue);
          actualStockVal += actualVal;

          tmpTargetList = salesTargetList
              .where(
                (e) => e.salesRep.toLowerCase().startsWith(
                  invList.fgLocation.toLowerCase(),
                ),
              )
              .toList();

          final key = '${list.fgLocation}|${list.itemGroup}';
          targetStockVal = targetCache.putIfAbsent(key, () {
            final expected = '${list.fgLocation}-${list.itemGroup}'
                .toLowerCase()
                .trim();

            return tmpTargetList.fold(0.0, (sum, t) {
              if (t.salesRep.toLowerCase().trim() == expected) {
                return sum + parseValue(t.getTargetForMonth(months.current));
              }
              return sum;
            });
          });
          // targetStockVal = salesTargetList
          //     .where((target) {
          //       return target.salesRep.toLowerCase() ==
          //           invList.fgLocation.toLowerCase() +
          //               '-' +
          //               itemGroup.toLowerCase();
          //     })
          //     .fold(
          //       0.0,
          //       (sum, target) =>
          //           sum + parseValue(target.getTargetForMonth(months.current)),
          //     );
        }

        stkData.add(
          StockItemData(
            itemSubGroup: itemGroup,
            targetStock: targetStockVal,
            actualStock: actualStockVal,
            difference: targetStockVal - actualStockVal,
          ),
        );
        processedItemGroupCodes.add(invList.itemGroup);
      }
      actualStockVal = 0;
      targetStockVal = 0;
      itemGroup = "";
    }

    actualStockHeader = stkData
        .map((e) => e.actualStock)
        .reduce((a, b) => a + b);

    targetStockHeader = stkData
        .map((e) => e.targetStock)
        .reduce((a, b) => a + b);

    differenceStockHeader = targetStockHeader - actualStockHeader;

    stkData.sort(
      (a, b) => (b.targetStock - b.actualStock).compareTo(
        a.targetStock - a.actualStock,
      ),
    );

    stockStatementData = StockItemList(stockData: stkData);
  }

  Future<void> _loadItemGraph() async {
    var inventoryList = stockData;
    String itemDescription = "";
    double actualStockVal = 0.00;
    double targetStockVal = 0.00;
    List<StockItemData> stkData = [];
    Set<String> processedItemCodes = {};
    Set<String> processedItemGroups = {};
    final months = getMonths(currentDate!);
    List<SalesTargetList> tmpTargetList = [];
    final Map<String, double> targetCache = {};

    for (var invList in inventoryList) {
      if (!processedItemCodes.contains(invList.itemDescription)) {
        itemDescription = invList.itemDescription;
        for (var list in inventoryList.where(
          (e) => e.itemDescription == itemDescription,
        )) {
          double actualVal = double.parse(list.totalValue);
          actualStockVal += actualVal;
        }
        if (!processedItemGroups.contains(invList.itemGroup)) {
          tmpTargetList = salesTargetList
              .where(
                (e) => e.salesRep.toLowerCase().startsWith(
                  invList.fgLocation.toLowerCase(),
                ),
              )
              .toList();

          final key = '${invList.fgLocation}|${invList.itemGroup}';
          targetStockVal = targetCache.putIfAbsent(key, () {
            final expected = '${invList.fgLocation}-${invList.itemGroup}'
                .toLowerCase()
                .trim();

            return tmpTargetList.fold(0.0, (sum, t) {
              if (t.salesRep.toLowerCase().trim() == expected) {
                return sum + parseValue(t.getTargetForMonth(months.current));
              }
              return sum;
            });
          });
          // targetStockVal = salesTargetList
          //     .where((target) {
          //       return target.salesRep.toLowerCase() ==
          //           invList.fgLocation.toLowerCase() +
          //               '-' +
          //               invList.itemGroup.toLowerCase();
          //     })
          //     .fold(
          //       0.0,
          //       (sum, target) =>
          //           sum + parseValue(target.getTargetForMonth(months.current)),
          //     );
        }
        stkData.add(
          StockItemData(
            itemSubGroup: itemDescription,
            targetStock: targetStockVal,
            actualStock: actualStockVal,
            difference: targetStockVal - actualStockVal,
          ),
        );
        processedItemCodes.add(invList.itemDescription);
        processedItemGroups.add(invList.itemGroup);
      }
      actualStockVal = 0;
      targetStockVal = 0;
      itemDescription = "";
    }

    actualStockHeader = stkData
        .map((e) => e.actualStock)
        .reduce((a, b) => a + b);

    targetStockHeader = stkData
        .map((e) => e.targetStock)
        .reduce((a, b) => a + b);

    differenceStockHeader = targetStockHeader - actualStockHeader;

    stkData.sort(
      (a, b) => (b.targetStock - b.actualStock).compareTo(
        a.targetStock - a.actualStock,
      ),
    );

    stockStatementItemData = StockItemList(stockData: stkData);
  }

  Future<void> _loadTransitGraph() async {
    var inventoryList = stockInTransitList;
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
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadStockStatementAPI(userName, userLevel);
    await _loadSalesTargetAPI(userName, userLevel);
    await _loadStockInTransitListAPI(userName, userLevel);
    _selectedBranch = "All Warehouses";
    await _loadItemGroupGraph();
    await _loadItemGraph();
    await _loadTransitGraph();
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> loadDataWithFilter(String subGroup) async {
    setState(() {
      chartDataLoaded = false;
    });
    stockData = stockDataTemp;
    stockInTransitList = stockInTransitListTemp;
    salesTargetList = salesTargetListTemp;

    salesTargetList = salesTargetList.where((data) {
      final expected = '${_selectedBranch}-'.toLowerCase().trim();
      final warehouseMatch =
          _selectedBranch!.isEmpty ||
          _selectedBranch == "All Warehouses" ||
          data.salesRep.toLowerCase().trim().contains(expected);

      return warehouseMatch;
    }).toList();

    stockData = stockData.where((data) {
      final warehouseMatch =
          _selectedBranch!.isEmpty ||
          _selectedBranch == "All Warehouses" ||
          data.fgLocation == _selectedBranch;

      final subGroupMatch = subGroup.isEmpty || data.itemGroup == subGroup;

      return warehouseMatch && subGroupMatch;
    }).toList();

    final selectedItems = stockData
        .map((e) => e.itemDescription.trim())
        .toSet();

    String selectedWarehouseCode = "";

    if (_selectedBranch != null &&
        _selectedBranch!.isNotEmpty &&
        _selectedBranch != "All Warehouses") {
      final warehouse = stockData.where((e) => e.fgLocation == _selectedBranch);

      if (warehouse.isNotEmpty) {
        selectedWarehouseCode = warehouse.first.fgLocation;
      }
    }

    stockInTransitList = stockInTransitList.where((data) {
      final warehouseMatch =
          _selectedBranch!.isEmpty ||
          _selectedBranch == "All Warehouses" ||
          data.fgLocation == selectedWarehouseCode;

      final subGroupMatch =
          subGroup.isEmpty ||
          selectedItems.contains(data.itemDescription.trim());

      return warehouseMatch && subGroupMatch;
    }).toList();
    await _loadItemGroupGraph();
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
    touchedGroup = "";
    _selectedBranch = "All Warehouses";
    await _loadItemGroupGraph();
    await _loadItemGraph();
    await _loadTransitGraph();
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  String _getExcelColumnName(int columnNumber) {
    String columnName = '';

    while (columnNumber > 0) {
      int remainder = (columnNumber - 1) % 26;

      columnName = String.fromCharCode(65 + remainder) + columnName;

      columnNumber = (columnNumber - remainder - 1) ~/ 26;
    }

    return columnName;
  }

  List<WarehouseStockRow> _prepareWarehouseWiseStockData() {
    List<SalesTargetList> tmpTargetList = [];
    final Map<String, double> targetCache = {};
    final Map<String, WarehouseStockRow> result = {};
    final months = getMonths(currentDate!);
    for (final item in stockData) {
      final rowLabel = item.itemGroup;
      final warehouse = item.fgLocation;
      tmpTargetList = salesTargetList
          .where(
            (e) => e.salesRep.toLowerCase().startsWith(warehouse.toLowerCase()),
          )
          .toList();

      final key = '${item.fgLocation}|${item.itemGroup}';

      final target = targetCache.putIfAbsent(key, () {
        final expected = '${item.fgLocation}-${item.itemGroup}'
            .toLowerCase()
            .trim();

        return tmpTargetList.fold(0.0, (sum, t) {
          if (t.salesRep.toLowerCase().trim() == expected) {
            return sum + parseValue(t.getTargetForMonth(months.current));
          }
          return sum;
        });
      });

      final actual = double.tryParse(item.totalValue.replaceAll(',', '')) ?? 0;

      result.putIfAbsent(
        rowLabel,
        () => WarehouseStockRow(
          rowLabel: rowLabel,
          target: {},
          actual: {},
          difference: {},
        ),
      );

      final row = result[rowLabel]!;

      row.target.putIfAbsent(warehouse, () => target);
      row.actual[warehouse] = (row.actual[warehouse] ?? 0) + actual;
      row.difference[warehouse] =
          row.target[warehouse]! - row.actual[warehouse]!;
    }

    return result.values.toList();
  }

  Future<void> exportWarehouseWiseStockExcel() async {
    try {
      final data = _prepareWarehouseWiseStockData();

      if (data.isEmpty) {
        NotificationService.warning(
          title: "Warning",
          message: "No data available to export.",
        );
        return;
      }

      final warehouses = stockData.map((e) => e.fgLocation).toSet().toList()
        ..sort();

      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];

      sheet.name = "Stock Statement";

      // --------------------------------------------------
      // TITLE
      // --------------------------------------------------

      final totalColumns = 2 + (warehouses.length * 3) + 3;

      final titleRange = sheet.getRangeByIndex(1, 1, 1, totalColumns);

      titleRange.merge();

      titleRange.setText(
        "${ApiHelper.companyName}\nOptima CRM - Production[MIS] - Stock Statement",
      );

      titleRange.cellStyle.bold = true;
      titleRange.cellStyle.fontSize = 14;
      titleRange.cellStyle.wrapText = true;

      sheet.getRangeByIndex(1, 1).rowHeight = 50;

      // --------------------------------------------------
      // USER
      // --------------------------------------------------

      final userName = await reportService.getUserName();

      sheet.getRangeByIndex(2, 1).setText("User : $userName");

      // --------------------------------------------------
      // HEADER ROW 1
      // --------------------------------------------------

      sheet.getRangeByIndex(4, 1, 5, 1).merge();
      sheet.getRangeByIndex(4, 1).setText("SL NO");

      sheet.getRangeByIndex(4, 2, 5, 2).merge();
      sheet.getRangeByIndex(4, 2).setText("Row Labels");

      int col = 3;

      for (final warehouse in warehouses) {
        sheet.getRangeByIndex(4, col, 4, col + 2).merge();

        sheet.getRangeByIndex(4, col).setText(warehouse.toUpperCase());

        sheet.getRangeByIndex(5, col).setText("Target");

        sheet.getRangeByIndex(5, col + 1).setText("Actual Stock");

        sheet.getRangeByIndex(5, col + 2).setText("Difference");

        col += 3;
      }
      sheet.getRangeByIndex(4, col, 4, col + 2).merge();

      sheet.getRangeByIndex(4, col).setText('Grand Total');

      sheet.getRangeByIndex(5, col).setText('Target');

      sheet.getRangeByIndex(5, col + 1).setText('Actual Stock');

      sheet.getRangeByIndex(5, col + 2).setText('Difference');

      // --------------------------------------------------
      // HEADER STYLE
      // --------------------------------------------------

      final headerRange = sheet.getRangeByIndex(4, 1, 5, totalColumns);

      headerRange.cellStyle.bold = true;
      headerRange.cellStyle.backColor = "#E7F3FF";
      headerRange.cellStyle.hAlign = xlsio.HAlignType.center;
      headerRange.cellStyle.vAlign = xlsio.VAlignType.center;

      sheet.getRangeByIndex(4, col, 5, col + 2).cellStyle.backColor = '#FFF2CC';

      sheet.getRangeByIndex(4, col, 5, col + 2).cellStyle.bold = true;
      // --------------------------------------------------
      // DATA
      // --------------------------------------------------

      int rowIndex = 6;
      int slNo = 1;

      for (final rowData in data) {
        sheet.getRangeByIndex(rowIndex, 1).setNumber(slNo.toDouble());

        sheet.getRangeByIndex(rowIndex, 2).setText(rowData.rowLabel);

        col = 3;
        double grandTarget = 0;
        double grandActual = 0;
        double grandDifference = 0;

        for (final warehouse in warehouses) {
          final target = rowData.target[warehouse] ?? 0;

          final actual = rowData.actual[warehouse] ?? 0;

          final difference = rowData.difference[warehouse] ?? 0;

          grandTarget += target;
          grandActual += actual;
          grandDifference += difference;

          sheet.getRangeByIndex(rowIndex, col).setNumber(target);

          sheet.getRangeByIndex(rowIndex, col + 1).setNumber(actual);

          sheet.getRangeByIndex(rowIndex, col + 2).setNumber(difference);

          col += 3;
        }

        sheet.getRangeByIndex(rowIndex, col).setNumber(grandTarget);

        sheet.getRangeByIndex(rowIndex, col + 1).setNumber(grandActual);

        sheet.getRangeByIndex(rowIndex, col + 2).setNumber(grandDifference);

        rowIndex++;
        slNo++;
      }

      // --------------------------------------------------
      // TOTAL ROW
      // --------------------------------------------------

      sheet.getRangeByIndex(rowIndex, 1).setText("Total");

      sheet
              .getRangeByIndex(rowIndex, 1, rowIndex, totalColumns)
              .cellStyle
              .backColor =
          "#FFF2CC";

      sheet
              .getRangeByIndex(rowIndex, 1, rowIndex, totalColumns)
              .cellStyle
              .bold =
          true;

      for (int c = 3; c <= totalColumns; c++) {
        final letter = _getExcelColumnName(c);

        sheet
            .getRangeByIndex(rowIndex, c)
            .setFormula('SUM(${letter}6:${letter}${rowIndex - 1})');
      }

      // --------------------------------------------------
      // NUMBER FORMAT
      // --------------------------------------------------

      for (int c = 3; c <= totalColumns; c++) {
        sheet.getRangeByIndex(6, c, rowIndex, c).numberFormat = '#,##0';
      }

      // --------------------------------------------------
      // BORDERS
      // --------------------------------------------------

      final fullRange = sheet.getRangeByIndex(4, 1, rowIndex, totalColumns);

      fullRange.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

      // --------------------------------------------------
      // AUTOFIT
      // --------------------------------------------------

      for (int c = 1; c <= totalColumns; c++) {
        sheet.autoFitColumn(c);
      }

      // --------------------------------------------------
      // SAVE
      // --------------------------------------------------

      final bytes = workbook.saveAsStream();
      workbook.dispose();

      final fileName =
          "stock_statement_${DateTime.now().millisecondsSinceEpoch}.xlsx";

      if (kIsWeb) {
        downloadExcelWeb(fileName, bytes);
      } else {
        final dir = await getStorageDirectory();

        final file = File('$dir/$fileName');

        await file.writeAsBytes(bytes, flush: true);

        OpenFile.open(file.path);
      }
    } catch (e) {
      debugPrint("Stock Statement Excel Error : $e");
    }
  }

  Future<void> generateStockStatementExcel(
    BuildContext context,
    StockItemList stockStatementData,
  ) async {
    int slNo = 1;
    await reportService.generateExcel(
      sheetName: 'StockStatement',
      headers: [
        'SL NO',
        'Sub Group Name',
        'Target',
        'Actual stock',
        'Difference',
      ],
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
      fileName: 'item_wise_stock_statement.xlsx',
      amountColumns: [3, 4, 5],
      addTotalRow: true,
      reportTitle: 'Production[MIS] - Item Wise Stock Statement',
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
      fileName: 'stock_in_transit_statement.xlsx',
      amountColumns: [3],
      addTotalRow: true,
      reportTitle: 'Production[MIS] - Stock In Transit Statement',
    );
  }

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _subGroupHorizontalController = ScrollController();
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
    _subGroupHorizontalController.dispose();
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
                                    exportWarehouseWiseStockExcel();
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
                    title: 'Stock Statement',
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
                              production: stockData,
                              selectedValue: _selectedBranch,
                              onChanged: (newValue) async {
                                setState(() {
                                  _selectedBranch =
                                      newValue ?? "All Warehouses";
                                });
                                if (newValue != null) {
                                  await loadDataWithFilter(touchedGroup);
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
                    title: 'Sub Group Wise Stock',
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
      controller: _subGroupHorizontalController,
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
                        touchedGroup = touchedGroup == ""
                            ? stockStatementData
                                  .stockData[barTouchResponse.spot!.spot.x
                                      .toInt()]
                                  .itemSubGroup
                            : "";

                        loadDataWithFilter(touchedGroup);
                      }
                    });
                  }
                },
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
        val = (e.fgLocation ?? '').toString().trim();
      } catch (_) {
        if (e is Map && e.containsKey('fgLocation')) {
          val = (e['fgLocation'] ?? '').toString();
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
