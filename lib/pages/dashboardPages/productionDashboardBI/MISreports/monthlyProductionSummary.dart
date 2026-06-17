// ignore_for_file: non_constant_identifier_names, file_names, use_build_context_synchronously, library_private_types_in_public_api
import 'dart:convert';
import 'dart:io';
import 'package:optima/classes/globals.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb check
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../notificationService.dart';
import '../../ReportService.dart';
import '../../dashboard_card_ui.dart';

// --- Global Variables ---
List<ProductionOrderList> dayWiseProduction = [];
late Future<void> loadDataFuture;
bool chartDataLoaded = false;

// Date Variables
DateTime? currentDate;
DateTime? currentMonthFromDate;
DateTime? currentMonthToDate;
DateTime? lastMonthFromDate;
DateTime? lastMonthToDate;
DateTime? currentQuarterFromDate;
DateTime? currentQuarterToDate;
DateTime? lastQuarterFromDate;
DateTime? lastQuarterToDate;
DateTime? fiscalYearStartDate;
DateTime? prevFiscalYearStartDate;
DateTime? prevFiscalYearEndDate;
String financialYear = "";
String prevFinancialYear = "";
int currentQuarter = 0;

class SubGroupProductionData {
  final String subGroupName;
  final double totalQty;

  SubGroupProductionData({required this.subGroupName, required this.totalQty});
}

class MonthlyProductionMISProvider with ChangeNotifier {
  List<ProductionOrderList> _salesList = [];
  List<ProductionOrderList> get salesList => _salesList;
  void updateProductionList(List<ProductionOrderList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class MonthlyProductionSummaryPage extends StatefulWidget {
  const MonthlyProductionSummaryPage({super.key});

  @override
  State<MonthlyProductionSummaryPage> createState() =>
      _MonthlyProductionSummaryPageState();
}

class _MonthlyProductionSummaryPageState
    extends State<MonthlyProductionSummaryPage> {
  DateTime _selectedMonth = DateTime.now();
  List<SubGroupProductionData> _graphData = [];
  List<String> _availablePlants = [];
  bool isLoading = false;
  String? _selectedPlant;
  final reportService = ReportService();

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    LoadDates();

    if (isUserLoggedIn && isBiDashboardStart) {
      if (!chartDataLoaded || dayWiseProduction.isEmpty) {
        loadDataFuture = loadData("");
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _extractPlants();
          _processDataAndGenerateGraph();
        });
      }
    }
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;

    final userLevel = prefs.getString('userLevel') ?? '';

    await _loadProductionOrderAnalysis(userName, userLevel);
  }

  Future<void> _loadProductionOrderAnalysis(
    String UserName,
    String UserLevel,
  ) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<ProductionOrderList> salesList = [];
    int monthIndex = DateTime.now().month;

    // We send 'yyyyMMdd' to the API as per your original request payload structure
    DateTime fromDate = monthIndex == 4
        ? lastMonthFromDate!
        : fiscalYearStartDate!;

    try {
      do {
        var body = {
          "FromDate": formatApiDate(fromDate),
          "ToDate": formatApiDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        const apiUrl = '${ApiHelper.baseUrl}BicxoProductionAnalysis';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<ProductionOrderList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => ProductionOrderList.fromJson(item))
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

      if (mounted) {
        setState(() {
          dayWiseProduction = salesList;
          context.read<MonthlyProductionMISProvider>().updateProductionList(
            salesList,
          );
          chartDataLoaded = true;

          _extractPlants();
          if (_availablePlants.isNotEmpty) {
            _selectedPlant ??= _availablePlants.first;
            _processDataAndGenerateGraph();
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading data: $e");
      }
    }
  }

  String formatApiDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
  }

  void _extractPlants() {
    final Set<String> plants = dayWiseProduction
        .map((e) => e.plant)
        .where((element) => element.isNotEmpty)
        .toSet();

    if (mounted) {
      setState(() {
        _availablePlants = plants.toList()..sort();
        if (_selectedPlant == null && _availablePlants.isNotEmpty) {
          _selectedPlant = _availablePlants.first;
        } else if (_selectedPlant != null &&
            !_availablePlants.contains(_selectedPlant)) {
          _selectedPlant = _availablePlants.isNotEmpty
              ? _availablePlants.first
              : null;
        }
      });
    }
  }

  void _processDataAndGenerateGraph() {
    if (dayWiseProduction.isEmpty) return;

    setState(() => isLoading = true);

    Map<String, double> groupedData = {};

    // **CHANGED**: Formatter specifically for "dd/MM/yyyy"
    final inputDateFormatter = DateFormat('dd/MM/yyyy');

    for (var order in dayWiseProduction) {
      // 1. Filter by Plant
      if (order.plant != _selectedPlant) continue;

      // 2. Parse Date Safely using dd/MM/yyyy
      DateTime? orderDate;
      try {
        // The API returns dates like "01/04/2025"
        orderDate = inputDateFormatter.parse(order.orderDate);
      } catch (e) {
        // Fallback: try default parsing if the specific format fails
        orderDate = DateTime.tryParse(order.orderDate);
      }

      if (orderDate == null) continue;

      // 3. Filter by Selected Month
      // Check if date falls within the selected month
      if (orderDate.year == _selectedMonth.year &&
          orderDate.month == _selectedMonth.month) {
        double qty = double.tryParse(order.completedQty) ?? 0.0;
        String key = order.itemSubGroup.isEmpty
            ? "Unknown"
            : order.itemSubGroup;

        groupedData[key] = (groupedData[key] ?? 0) + qty;
      }
    }

    // 4. Convert to List
    List<SubGroupProductionData> resultList = groupedData.entries.map((entry) {
      return SubGroupProductionData(
        subGroupName: entry.key,
        totalQty: entry.value,
      );
    }).toList();

    // 5. Sort Descending
    resultList.sort((a, b) => b.totalQty.compareTo(a.totalQty));

    setState(() {
      _graphData = resultList;
      isLoading = false;
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: "SELECT MONTH",
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
      _processDataAndGenerateGraph();
    }
  }

  Future<void> _generateExcel(BuildContext context) async {
    if (_graphData.isEmpty) {
      if (!mounted) return;
      NotificationService.info(title: "Info", message: "No data to export.");
      return;
    }

    await reportService.generateExcel(
      sheetName: 'ProductionSummary',
      headers: ["Item SubGroup", "Completed Qty"],
      rows: _graphData
          .map((data) => [data.subGroupName, data.totalQty])
          .toList(),
      fileName:
          'monthly_production_${DateFormat('MMM_yyyy').format(_selectedMonth)}.xlsx',
      amountColumns: [2],
      addTotalRow: true,
      reportTitle:
          'Production[MIS] - Monthly Production of Plant: $_selectedPlant - ${DateFormat('MMMM yyyy').format(_selectedMonth)}",',
    );
  }

  void LoadDates() {
    currentDate = DateTime.now();
    currentMonthFromDate = DateTime(currentDate!.year, currentDate!.month, 1);
    currentMonthToDate = addMonth(
      currentMonthFromDate!,
      1,
    ).add(const Duration(days: -1));
    lastMonthFromDate = DateTime(currentDate!.year, currentDate!.month - 1, 1);
    lastMonthToDate = DateTime(currentDate!.year, currentDate!.month, 0);

    int fiscalYearStartMonth = 4;
    currentQuarter = getCurrentQuarter();
    getLastQuarterDates();

    int fiscalYear = currentDate!.month >= fiscalYearStartMonth
        ? currentDate!.year
        : currentDate!.year - 1;
    fiscalYearStartDate = DateTime(fiscalYear, fiscalYearStartMonth, 1);

    prevFiscalYearStartDate = addMonth(fiscalYearStartDate!, -12);
    prevFiscalYearEndDate = DateTime(prevFiscalYearStartDate!.year + 1, 4, 0);
  }

  DateTime addMonth(DateTime date, int addMonth) {
    int currentMonth = date.month;
    int currentYear = date.year;
    int nextMonth = currentMonth + addMonth;
    int nextYear = currentYear;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }
    int lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
    int originalDay = date.day;
    if (originalDay > lastDayOfNextMonth) originalDay = lastDayOfNextMonth;
    return DateTime(nextYear, nextMonth, originalDay);
  }

  int getCurrentQuarter() {
    int m = DateTime.now().month;
    if (m >= 4 && m <= 6) return 1;
    if (m >= 7 && m <= 9) return 2;
    if (m >= 10 && m <= 12) return 3;
    return 4;
  }

  void getLastQuarterDates() {
    DateTime now = DateTime.now();
    int q = getCurrentQuarter();
    if (q == 1) {
      lastQuarterFromDate = DateTime(now.year, 1, 1);
      lastQuarterToDate = DateTime(now.year, 3, 31);
    } else if (q == 2) {
      lastQuarterFromDate = DateTime(now.year, 4, 1);
      lastQuarterToDate = DateTime(now.year, 6, 30);
    } else if (q == 3) {
      lastQuarterFromDate = DateTime(now.year, 7, 1);
      lastQuarterToDate = DateTime(now.year, 9, 30);
    } else {
      lastQuarterFromDate = DateTime(now.year - 1, 10, 1);
      lastQuarterToDate = DateTime(now.year - 1, 12, 31);
    }
  }

  double getMaxValue(double maxValue, double divVal) {
    return (maxValue / divVal).ceil() * divVal;
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

  @override
  Widget build(BuildContext context) {
    return chartDataLoaded == true
        ? FinanceVerticalScroll(
            controller: _verticalScrollController,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: '',
                    spacing: 10,
                    menuItems: [],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [_buildControls()],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _graphData.isEmpty
                    ? Center(
                        child: Text(
                          "No data found for ${DateFormat('MMM yyyy').format(_selectedMonth)}",
                        ),
                      )
                    : SizedBox(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: DashboardCardUI(
                                title: 'SubGroup wise Completed Qty',
                                spacing: 10,
                                menuItems: [
                                  PopupMenuItem(
                                    onTap: () {
                                      _generateExcel(context);
                                    },
                                    child: const Text("Download Excel"),
                                  ),
                                ],
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 15),
                                    _buildProductionChart(),
                                    const SizedBox(height: 15),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          )
        : const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  Widget _buildControls() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final dropdown = SizedBox(
      width: 250,
      height: 45,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedPlant,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Select Plant',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
        ),
        items: _availablePlants
            .map(
              (plant) => DropdownMenuItem(
                value: plant,
                child: Text(plant, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() => _selectedPlant = value);
          if (value != null) _processDataAndGenerateGraph();
        },
      ),
    );

    final monthButton = ElevatedButton.icon(
      onPressed: _pickMonth,
      icon: const Icon(Icons.calendar_month),
      label: Text(DateFormat('MMM yyyy').format(_selectedMonth)),
      style: ElevatedButton.styleFrom(minimumSize: const Size(130, 45)),
    );

    final generateButton = ElevatedButton(
      onPressed: _processDataAndGenerateGraph,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff2ca9df),
        foregroundColor: Colors.white,
        minimumSize: const Size(130, 45),
      ),
      child: const Text('Generate'),
    );

    if (isLandscape) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SizedBox(width: 15),
                  Text(
                    "Monthly Production Details",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          dropdown,
          const SizedBox(width: 12),
          monthButton,
          const SizedBox(width: 12),
          generateButton,
        ],
      );
    }
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const SizedBox(width: 15),
                Text(
                  "Monthly Production Details",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        dropdown,
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [monthButton, generateButton],
        ),
      ],
    );
  }

  Widget _buildProductionChart() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = _graphData.length > 4
        ? screenWidth + (60 * _graphData.length)
        : screenWidth;
    int len = _graphData.length;
    double maxAmount = len > 0
        ? _graphData
              .map((data) => data.totalQty)
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
              maxY: getMaxValue(maxAmount, 50000),
              alignment: BarChartAlignment.spaceAround,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, m) {
                      if (v.toInt() >= 0 && v.toInt() < _graphData.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: RotationTransition(
                            turns: const AlwaysStoppedAnimation(-20 / 360),
                            child: SizedBox(
                              width: 60,
                              child: Text(
                                _graphData[v.toInt()].subGroupName,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade400),
                  top: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              barGroups: List.generate(_graphData.length, (index) {
                final data = _graphData[index];
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: data.totalQty,
                      color: const Color(0xFF2ca9df),
                      width: 25,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }),
              barTouchData: BarTouchData(
                enabled: true,
                handleBuiltInTouches: true,
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (_) => Colors.white,
                  tooltipBorder: const BorderSide(color: Colors.grey, width: 1),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final data = _graphData[groupIndex];
                    return BarTooltipItem(
                      data.subGroupName,
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: "\nQty: ${formatAmount(data.totalQty)}",
                          style: const TextStyle(
                            color: Color(0xFF2ca9df),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
    );
  }
}
