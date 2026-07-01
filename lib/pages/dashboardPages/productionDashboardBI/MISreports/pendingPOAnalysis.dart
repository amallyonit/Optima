// ignore_for_file: non_constant_identifier_names, file_names, use_build_context_synchronously, strict_top_level_inference
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import '../../../../notificationService.dart';
import '../../dashboard_card_ui.dart';

class PendingPOAnalysisPage extends StatefulWidget {
  const PendingPOAnalysisPage({super.key});

  @override
  State<PendingPOAnalysisPage> createState() => _PendingPOAnalysisPageState();
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

class _PendingPOAnalysisPageState extends State<PendingPOAnalysisPage> {
  int touchedIndex = -1;
  late Future<void> loadDataFuture;
  String UserLevel = '';
  String UserName = '';

  DateTime? currentDate;
  DateTime? fiscalYearStartDate;
  bool chartDataLoaded = false;

  List<POList> poList = [];
  List<POList> poListTemp = [];
  List<PendingPurchaseChartModel> pendingPurchaseChartData = [];
  List<SalesTargetList> salesTargetList = [];
  List<PurchaseList> purchaseList = [];
  List<PurchaseList> purchaseListTemp = [];

  final List<String> categories = ['Date'];
  bool fromFilter = false;
  int selectedCategoryIndex = 0;
  DateTime? fromDateFilter;
  DateTime? toDateFilter;
  bool dateFilterFlag = false;

  String formatAmount(double amount) {
    if (amount >= 10000000) {
      // Amount in crores
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      // Amount in lakhs
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else {
      // Amount in thousands
      return '${(amount / 1000).toStringAsFixed(2)} K';
    }
  }

  double convertAmount(double amount) {
    if (amount >= 10000000) {
      // Amount in crores
      return double.parse((amount / 10000000).toStringAsFixed(2));
    } else if (amount >= 100000) {
      // Amount in lakhs
      return double.parse((amount / 100000).toStringAsFixed(2));
    } else {
      // Amount in thousands
      return double.parse((amount / 1000).toStringAsFixed(2));
    }
  }

  String formatFinanceAmount(double amount) {
    if (amount >= 1000000000) {
      return "${(amount / 1000000000).toStringAsFixed(2)} B";
    } else if (amount >= 1000000) {
      return "${(amount / 1000000).toStringAsFixed(2)} M";
    } else {
      return '${(amount / 1000).toStringAsFixed(2)} K';
    }
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

  DateTime addDay(DateTime date, int addDays) {
    // Add the specified number of days to the given date
    DateTime newDate = date.add(Duration(days: addDays));

    // Return the resulting date
    return newDate;
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

  String getMonthName(int month) {
    final formatter = DateFormat('MMMM');
    return formatter.format(DateTime(2000, month));
  }

  void LoadDates() {
    currentDate = DateTime.now();

    int fiscalYearStartMonth = 4;

    int fiscalYear = currentDate!.month >= fiscalYearStartMonth
        ? currentDate!.year
        : currentDate!.year - 1;
    fiscalYearStartDate = DateTime(fiscalYear, fiscalYearStartMonth, 1);
  }

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
  }

  Map<String, DateTime> getMonthStartEndDates(int month) {
    DateTime now = DateTime.now();

    int currentYear = now.year;

    // Determine the correct year for the given month
    int yearForMonth;
    if (now.month >= 1 && now.month <= 3) {
      // If the call is happening in Jan–Mar
      yearForMonth = (month >= 4 && month <= 12)
          ? currentYear - 1
          : currentYear;
    } else {
      // If the call is happening in Apr–Dec
      yearForMonth = (month >= 4 && month <= 12)
          ? currentYear
          : currentYear + 1;
    }

    // Calculate the first and last days of the given month
    DateTime firstDayOfMonth = DateTime(yearForMonth, month, 1);
    DateTime lastDayOfMonth = DateTime(yearForMonth, month + 1, 0);

    return {'start': firstDayOfMonth, 'end': lastDayOfMonth};
  }

  SideTitles get _leftTitles => SideTitles(
    reservedSize: 60,
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

  late SideTitles _bottomTitlesPendingPurchase = SideTitles(
    showTitles: true,
    reservedSize: 55,
    getTitlesWidget: _bottomTitleWidgetsPendingPurchase,
  );

  Widget _bottomTitleWidgetsPendingPurchase(double value, TitleMeta meta) {
    if (value.toInt() >= pendingPurchaseChartData.length) {
      return const SizedBox();
    }

    final text = pendingPurchaseChartData[value.toInt()].description;

    return SideTitleWidget(
      meta: meta,
      space: 10,
      child: SizedBox(
        width: 90,
        child: Text(
          text.replaceAll(' ', '\n'),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  final List<Color> _pendingPurchaseColors = [
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.brown,
  ];

  final List<String> _pendingPurchaseLabels = [
    "Target Purchase Order",
    "Total Pending PO",
    "GRN Value",
    "Upto Previous Month Pending",
    "Current Month Pending",
    "Next Month Pending",
  ];

  List<BarChartGroupData> _PendingPurchaseChartData(
    List<PendingPurchaseChartModel> data,
  ) {
    return List.generate(data.length, (index) {
      final item = data[index];

      return BarChartGroupData(
        x: index,
        barsSpace: 3,
        barRods: List.generate(
          item.chartValues.length,
          (i) => BarChartRodData(
            toY: item.chartValues[i],
            width: 8,
            color: _pendingPurchaseColors[i],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    });
  }

  List<PendingPurchaseChartModel> prepareChartData({
    required List<PurchaseList> purchaseList,
    required List<POList> poList,
    required List<SalesTargetList> salesTargetList,
  }) {
    final months = getMonths(DateTime.now());
    purchaseList = purchaseList.where((e) => e.whsCode != 'BAGALUWH').toList();
    poList = poList.where((e) => e.warehouse != 'BAGALUWH').toList();
    // Fixed chart groups
    const chartGroups = [
      'Raw Material',
      'Packing Material',
      'Traded Material',
      'Other (GP)',
    ];

    final List<PendingPurchaseChartModel> chartData = [];

    for (final group in chartGroups) {
      //-----------------------------------------
      // STEP 6 : GRN VALUE
      //-----------------------------------------
      final now = DateTime.now();

      final currentMonthStart = DateTime(now.year, now.month, 1);
      final currentMonthEnd = DateTime(now.year, now.month + 1, 0);
      final nextMonthStart = DateTime(now.year, now.month + 1, 1);

      double grnValue = purchaseList
          .where((purchase) {
            // Group filter
            if (getChartGroup(purchase.itemGroup) != group) {
              return false;
            }

            final invoiceDate = tryParseDate(purchase.invoiceDate);

            if (invoiceDate == null) {
              return false;
            }

            // Include everything up to the last day of next month
            return (!invoiceDate.isBefore(currentMonthStart) &&
                !invoiceDate.isAfter(currentMonthEnd));
          })
          .fold(0.0, (sum, purchase) => sum + parseValue(purchase.rowTotal));

      //-----------------------------------------
      // STEP 7 : Previous / Current / Next Pending
      //-----------------------------------------

      double previousPending = 0;
      double currentPending = 0;
      double nextPending = 0;

      for (final po in poList) {
        // Convert API group to chart group
        if (getChartGroup(po.groupName) != group) {
          continue;
        }

        final poDate = tryParseDate(po.poDate);

        if (poDate == null) {
          continue;
        }

        final pendingValue = parseValue(po.pendingValue);

        // Previous Pending (everything before current month)
        if (poDate.isBefore(currentMonthStart)) {
          previousPending += pendingValue;
        }
        // Current Month
        else if (!poDate.isBefore(currentMonthStart) &&
            !poDate.isAfter(currentMonthEnd)) {
          currentPending += pendingValue;
        }
        // Next Month
        else if (!poDate.isBefore(nextMonthStart)) {
          nextPending += pendingValue;
        }
      }

      //-----------------------------------------
      // STEP 8 : Total Pending
      //-----------------------------------------
      double totalPending = previousPending + currentPending + nextPending;

      //-----------------------------------------
      // STEP 9 : Target Purchase Order
      //-----------------------------------------
      double targetPurchaseOrder = salesTargetList
          .where((target) {
            if (group == 'Other (GP)') {
              return target.salesRep != 'Raw Material' &&
                  target.salesRep != 'Packing Material' &&
                  target.salesRep != 'Traded Material';
            }

            return target.salesRep == group;
          })
          .fold(
            0.0,
            (sum, target) =>
                sum + parseValue(target.getTargetForMonth(months.current)),
          );

      chartData.add(
        PendingPurchaseChartModel(
          description: group,
          targetPurchaseOrder: targetPurchaseOrder,
          totalPendingPOValue: totalPending,
          grnValue: grnValue,
          previousMonthPending: previousPending,
          currentMonthPending: currentPending,
          nextMonthPending: nextPending,
        ),
      );
    }

    return chartData;
  }

  Future<void> _loadPOList(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000; // Maximum limit to fetch all data
    int fetchedCount = 0;
    List<POList> tmpList = [];
    final fromDate = formatDate(addMonth(fiscalYearStartDate!, -13));
    final toDate = formatDate(addMonth(currentDate!, 12));
    try {
      do {
        var body = {
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}BicxoPOList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<POList> newPoList = (responseJson['responseData'] as List)
                .map((item) => POList.fromJson(item))
                .toList();
            tmpList.addAll(newPoList);
            fetchedCount = newPoList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        poList = tmpList
            .where((po) => po.type == "Item Purchase" && po.poStatus == "Open")
            .toList();
        poListTemp = poList;
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading Purchase Order data",
      );
    }
  }

  Future<void> _loadPurchaseList(String userName, String userLevel) async {
    int index = 0;
    const int limit = 10000;
    int fetchedCount = 0;

    List<PurchaseList> tmpList = [];

    final fromDate = dateFilterFlag
        ? formatDate(fromDateFilter!)
        : formatDate(fiscalYearStartDate!);

    final toDate = dateFilterFlag
        ? formatDate(toDateFilter!)
        : formatDate(currentDate!);

    const apiUrl = '${ApiHelper.baseUrl}BicxoPurchaseList';

    try {
      do {
        final body = {
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        late http.Response response;

        // Retry mechanism
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
          }
        }

        if (response.statusCode == 200) {
          final jsonMap = jsonDecode(response.body);
          final List<dynamic>? data = jsonMap["responseData"] ?? [];

          if (data == null || data.isEmpty) {
            fetchedCount = 0;
          } else {
            final parsed = parsePurchaseList(data);
            tmpList.addAll(parsed);
            fetchedCount = parsed.length;
            index++;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      purchaseList = List.from(tmpList);

      purchaseListTemp = List.from(tmpList);
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading purchase price data.",
      );
    }
  }

  Future<void> _loadSalesTarget(String userName, String userLevel) async {
    final fromDate = dateFilterFlag
        ? formatDate(fromDateFilter!)
        : formatDate(fiscalYearStartDate!);

    final toDate = dateFilterFlag
        ? formatDate(toDateFilter!)
        : formatDate(currentDate!);

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

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';

    UserName = userName;
    UserLevel = userLevel;
    await Future.wait([
      _loadPOList(userName, userLevel),
      _loadPurchaseList(userName, userLevel),
      _loadSalesTarget(userName, userLevel),
    ]);
    // await _loadPOList(userName, userLevel);
    // await _loadPurchaseList(userName, userLevel);
    // await _loadSalesTarget(userName, userLevel);

    pendingPurchaseChartData = prepareChartData(
      purchaseList: purchaseList,
      poList: poList,
      salesTargetList: salesTargetList,
    );

    setState(() {
      chartDataLoaded = true;
    });
  }

  List<SalesTargetList> parseSalesTargetList(List<dynamic> data) {
    return data.map((e) => SalesTargetList.fromJson(e)).toList();
  }

  List<PurchaseList> parsePurchaseList(List<dynamic> data) {
    return data.map((e) => PurchaseList.fromJson(e)).toList();
  }

  void clearVariables() {
    setState(() {
      chartDataLoaded = false;
    });
  }

  void removeFilter() {
    setState(() {
      chartDataLoaded = false;
    });
    loadDataFuture = loadData("");
    toDateFilter = currentDate;
    fromDateFilter = fiscalYearStartDate;
    setState(() {
      chartDataLoaded = true;
    });
  }

  String formatDateString(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  Future<void> _dateFilterTarget(
    String UserName,
    String UserLevel,
    bool FromFilter,
  ) async {
    poList = poList.where((target) {
      DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.poDate);
      return (dueon.isAtLeast(fromDateFilter!) &&
          dueon.isAtMost(toDateFilter!));
    }).toList();
  }

  Future<void> filterFunction() async {
    setState(() {
      chartDataLoaded = false;
    });
    await Future.wait([
      _loadPOList(UserName, UserLevel),
      _loadPurchaseList(UserName, UserLevel),
      _loadSalesTarget(UserName, UserLevel),
    ]);
    pendingPurchaseChartData = prepareChartData(
      purchaseList: purchaseList,
      poList: poList,
      salesTargetList: salesTargetList,
    );
    setState(() {
      chartDataLoaded = true;
    });
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

  String getChartGroup(String group) {
    switch (group.trim()) {
      case 'Raw Material':
        return 'Raw Material';

      case 'Packing Material':
        return 'Packing Material';

      case 'Traded Material':
        return 'Traded Material';

      default:
        return 'Other (GP)';
    }
  }

  DateTime? tryParseDate(String? input) {
    if (input == null || input.trim().isEmpty) return null;

    try {
      return DateFormat('dd/MM/yyyy').parseStrict(input);
    } catch (_) {}

    try {
      return DateFormat('M/d/yyyy h:mm:ss a').parse(input);
    } catch (_) {}

    return DateTime.tryParse(input);
  }

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    LoadDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
      toDateFilter = currentDate;
      fromDateFilter = fiscalYearStartDate;
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
    return chartDataLoaded == true
        ? FinanceVerticalScroll(
            controller: _verticalScrollController,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 15),
                        dateFilterFlag
                            ? Text(
                                "${formatDateString(fromDateFilter!)} - ${formatDateString(toDateFilter!)}",
                              )
                            : Text(
                                "${formatDateString(fiscalYearStartDate!)} - ${formatDateString(currentDate!)}",
                              ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            showFilterBottomSheet(context);
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
                    title: 'Purchase Order Pending Analysis',
                    spacing: 10,

                    menuItems: [
                      PopupMenuItem(
                        onTap: () {},
                        child: const Text("Download Excel"),
                      ),
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _pendingPurchaseAnalysisGraph(),
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

  Widget _pendingPurchaseAnalysisGraph() {
    final screenWidth = MediaQuery.of(context).size.width;

    double chartWidth = screenWidth;

    if (pendingPurchaseChartData.length > 4) {
      chartWidth += (pendingPurchaseChartData.length - 4) * 140;
    }

    double maxAmount = 0;

    if (pendingPurchaseChartData.isNotEmpty) {
      maxAmount = pendingPurchaseChartData
          .expand((e) => e.chartValues)
          .reduce((a, b) => a > b ? a : b);
    }

    return Column(
      children: [
        _buildPendingPurchaseLegend(),

        const SizedBox(height: 10),

        FinanceHorizontalChartScroll(
          controller: _horizontalController,
          verticalController: _verticalScrollController,
          child: SizedBox(
            width: chartWidth,
            height: 400,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,

                  maxY: getMaxValue(maxAmount),

                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    checkToShowHorizontalLine: (value) => true,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: Colors.grey.shade300, strokeWidth: 1),
                  ),

                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade400,
                        width: .7,
                      ),
                      top: BorderSide(color: Colors.grey.shade400, width: .7),
                    ),
                  ),

                  titlesData: FlTitlesData(
                    show: true,

                    leftTitles: AxisTitles(sideTitles: _leftTitles),

                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),

                    topTitles: AxisTitles(sideTitles: _emptyTitlesTop),

                    bottomTitles: AxisTitles(
                      sideTitles: _bottomTitlesPendingPurchase,
                    ),
                  ),

                  barGroups: _PendingPurchaseChartData(
                    pendingPurchaseChartData,
                  ),

                  barTouchData: BarTouchData(
                    handleBuiltInTouches: true,

                    touchTooltipData: BarTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,

                      getTooltipColor: (group) => Colors.white,

                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final item = pendingPurchaseChartData[group.x];

                        final labels = _pendingPurchaseLabels;

                        return BarTooltipItem(
                          item.description,
                          const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(
                              text: "\n${labels[rodIndex]}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            TextSpan(
                              text: "\n${rod.toY.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
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
        ),
      ],
    );
  }

  Widget _buildPendingPurchaseLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 18,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: List.generate(
          _pendingPurchaseLabels.length,
          (index) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _pendingPurchaseColors[index],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _pendingPurchaseLabels[index],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  showPopupMenu() {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(25.0, 200.0, 0.0, 0.0),
      elevation: 8.0,
      items: [
        const PopupMenuItem<String>(value: '1', child: Text('Remove Filter?')),
      ],
    ).then((value) {
      if (value == '1') {
        removeFilter();
      }
    });
  }

  void showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Options',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 150,
                          child: ListView.builder(
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(categories[index]),
                                selected: selectedCategoryIndex == index,
                                onTap: () {
                                  setState(() {
                                    selectedCategoryIndex = index;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        // Right side: Filter options as checkboxes
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    ListTile(
                                      title: const Text("From Date"),
                                      subtitle: Text(
                                        fromDateFilter != null
                                            ? "${fromDateFilter!.day}/${fromDateFilter!.month}/${fromDateFilter!.year}"
                                            : formatDateString(
                                                fiscalYearStartDate!,
                                              ),
                                      ),
                                      trailing: const Icon(
                                        Icons.calendar_today,
                                      ),
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              fromDateFilter ?? DateTime.now(),
                                          firstDate: fiscalYearStartDate!,
                                          lastDate: currentDate!,
                                        );
                                        if (picked != null) {
                                          setState(() {
                                            fromDateFilter = picked;
                                            dateFilterFlag = true;
                                          });
                                        }
                                      },
                                    ),
                                    ListTile(
                                      title: const Text("To Date"),
                                      subtitle: Text(
                                        toDateFilter != null
                                            ? "${toDateFilter!.day}/${toDateFilter!.month}/${toDateFilter!.year}"
                                            : formatDateString(currentDate!),
                                      ),
                                      trailing: const Icon(
                                        Icons.calendar_today,
                                      ),
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              toDateFilter ?? DateTime.now(),
                                          firstDate: fiscalYearStartDate!,
                                          lastDate: currentDate!,
                                        );
                                        if (picked != null) {
                                          setState(() {
                                            toDateFilter = picked;
                                            dateFilterFlag = true;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff2ca9df),
                                      minimumSize: const Size(10, 10),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      fromFilter = false;
                                      loadDataFuture = filterFunction();
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Apply Filter',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      minimumSize: const Size(10, 10),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        chartDataLoaded = false;
                                      });
                                      fromFilter = false;
                                      setState(() {
                                        fromDateFilter = null;
                                        toDateFilter = null;
                                        dateFilterFlag = false;
                                        chartDataLoaded = false;
                                        chartDataLoaded = false;
                                        setState(() {
                                          chartDataLoaded = false;
                                        });
                                        removeFilter();
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Clear Filter',
                                        style: TextStyle(
                                          color: Color(0xff2ca9df),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
