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
  final reportService = ReportService();
  final ScrollController _tabScrollController = ScrollController();
  late Future<void> loadDataFuture;
  DateTime? currentDate;
  DateTime? fiscalYearStartDate;
  bool chartDataLoaded = false;
  String? _selectedBranch;

  List<InventoryLevelList> stockData = [];
  List<InventoryLevelList> stockDataTemp = [];

  String selectedSubGroup = 'Raw Material';

  DateTime selectedDate = DateTime.now();
  String formattedStartDate = "";
  String formattedEndDate = "";
  double targetStock = 0,
      actualStock = 0,
      stockPercentage = 0,
      avgStockVal = 0,
      stockValAgainstAvgStockVal = 0,
      excessOrShortStockValAgainstAvgStockTarget = 0,
      stockOtherThanAvgStockVal = 0,
      totalRMStock = 0,
      totalExcessStockAgainstAvgVal = 0;

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

  SideTitles get _emptyTitlesTop =>
      SideTitles(showTitles: true, getTitlesWidget: getEmptyTopTitle);

  Widget getEmptyTopTitle(double val, TitleMeta meta) {
    return const Text("");
  }

  Future<void> _loadDailyRMStatement(String UserName, String UserLevel) async {
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

    if (selectedSubGroup.isNotEmpty && groups.contains(selectedSubGroup)) {
      groups.remove(selectedSubGroup);
      groups.insert(0, selectedSubGroup);
    }

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
        actualStock += double.tryParse(row.minInventory) ?? 0;
        targetStock += double.tryParse(row.quantity) ?? 0;
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

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadDailyRMStatement(userName, userLevel);
    // _selectedBranch = "Bangalore FG Inventory Store Warehouse";
    _selectedBranch = "All Warehouses";
    await _loadDailyRMGraph();
  }

  Future<void> loadDataClearFilter() async {
    chartDataLoaded = false;
    stockData = stockDataTemp;

    setState(() {});
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
            // SAME LOGIC AS YOUR CHART
            dayActual += double.tryParse(row.minInventory) ?? 0;

            dayTarget += double.tryParse(row.quantity) ?? 0;
          }

          double percentage = dayTarget > 0 ? (dayActual / dayTarget) * 100 : 0;

          final day = DateFormat(
            'dd-MMM',
          ).format(DateFormat('dd/MM/yyyy').parse(dateEntry.key));

          dayPercentages[day] = percentage;

          totalActual += dayActual;
          totalTarget += dayTarget;
        }

        final row = <dynamic>[subGroup, totalTarget, totalActual];

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

  Future<void> generateRMExcel(
    BuildContext context,
    DailyStockAchievementList dailyStockAchievementData,
  ) async {
    int slNo = 1;
    await reportService.generateExcel(
      sheetName: 'RMSummary',
      headers: ['SL NO', 'Row Labels', 'Target', 'Actual stock', 'Difference'],
      rows: dailyStockAchievementData.stockData
          .map(
            (stkData) => [
              slNo++,
              stkData.itemSubGroup,
              stkData.targetStock,
              stkData.actualStock,
              0,
            ],
          )
          .toList(),
      fileName: 'rm_summary.xlsx',
      amountColumns: [3, 4, 5],
      addTotalRow: true,
      reportTitle: 'Production[MIS] - RM Summary',
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
    }
  }

  int get aboveAverageDays {
    return chartData
        .where((e) => e.achievedPercentage >= monthlyAveragePercentage)
        .length;
  }

  double get monthlyAveragePercentage {
    if (chartData.isEmpty) return 0;

    return chartData.map((e) => e.achievedPercentage).reduce((a, b) => a + b) /
        chartData.length;
  }

  double get bestAchievement {
    if (chartData.isEmpty) return 0;

    return chartData.map((e) => e.achievedPercentage).reduce(max);
  }

  double get worstAchievement {
    if (chartData.isEmpty) return 0;

    return chartData.map((e) => e.achievedPercentage).reduce(min);
  }

  List<FlSpot> _achievementSpots() {
    return chartData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.achievedPercentage);
    }).toList();
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            BranchDropdown(
                              production: stockData,
                              onChanged: (newValue) async {
                                setState(() {
                                  _selectedBranch = newValue;
                                });
                                if (newValue != null) await _loadDailyRMGraph();
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
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  Widget _achievementKPIs() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(width: 4),
        SizedBox(
          width: 100,
          child: _buildInfoCard(
            'Average',
            '${monthlyAveragePercentage.toStringAsFixed(1)}%',
          ),
        ),
        SizedBox(
          width: 100,
          child: _buildInfoCard(
            'Best',
            '${bestAchievement.toStringAsFixed(1)}%',
          ),
        ),
        SizedBox(
          width: 100,
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

                  // getTooltipItems: (spots) {
                  //   return spots.map((spot) {
                  //     final item = chartData[spot.x.toInt()];
                  //     print(
                  //       "barIndex=${spot.barIndex}, "
                  //       "spotIndex=${spot.spotIndex}, "
                  //       "x=${spot.x}, "
                  //       "y=${spot.y}",
                  //     );
                  //     return LineTooltipItem(
                  //       "${DateFormat('dd-MMM-yyyy').format(item.date)}\n"
                  //       "Target : ${formatAmount(item.targetStock)}\n"
                  //       "Actual : ${formatAmount(item.actualStock)}\n"
                  //       "Achievement : ${item.achievedPercentage.toStringAsFixed(1)}%\n"
                  //       "Monthly Avg : ${monthlyAveragePercentage.toStringAsFixed(1)}%",
                  //       const TextStyle(color: Colors.black, fontSize: 12),
                  //     );
                  //   }).toList();
                  // },
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
        height: 70,
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

  Widget _subGroupTabs() {
    if (subGroups.isEmpty) {
      return const SizedBox();
    }

    return SizedBox(
      height: 45,
      child: ListView.separated(
        controller: _tabScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: subGroups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final group = subGroups[index];
          final isSelected = group == selectedSubGroup;

          return InkWell(
            onTap: () {
              setState(() {
                selectedSubGroup = group;
              });
              _tabScrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1976D2)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                group,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  showPopupMenu() {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(25.0, 100.0, 0.0, 0.0),
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

  const BranchDropdown({
    super.key,
    required this.production,
    required this.onChanged,
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
    _selected = _items.isNotEmpty ? _items.first : null;
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
