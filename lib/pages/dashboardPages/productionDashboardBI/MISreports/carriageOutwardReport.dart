// ignore_for_file: non_constant_identifier_names, file_names, use_build_context_synchronously, library_private_types_in_public_api
import 'dart:convert';
import 'dart:io';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../classes/dashBoard.dart';
import '../../../../notificationService.dart';
import '../../dashboard_card_ui.dart';
import '../../ReportService.dart';

final reportService = ReportService();
List<CarriageOutwardList> carriageOutwardList = [];
late Future<void> loadDataFuture;
bool chartDataLoaded = false;

// Date Variables
DateTime? currentDate;
DateTime? currentMonthFromDate;
DateTime? currentMonthToDate;
DateTime? lastMonthFromDate;
DateTime? lastMonthToDate;
DateTime? fiscalYearStartDate;
int currentQuarter = 0;
String? formattedFiscalYearStartDate;
String? formattedDateNow;

// Helper class for Graphing
class CustomerFreightData {
  final String customerName;
  final double totalFreight;
  CustomerFreightData({required this.customerName, required this.totalFreight});
}

class CarriageOutwardPage extends StatefulWidget {
  const CarriageOutwardPage({super.key});

  @override
  State<CarriageOutwardPage> createState() => _CarriageOutwardPageState();
}

class _CarriageOutwardPageState extends State<CarriageOutwardPage> {
  // UI State
  DateTime selectedDate = DateTime.now();
  String? _selectedBranch;
  List<CustomerFreightData> _graphData = [];
  bool isLoading = false; // Internal loading for graph processing

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    LoadDates();
    loadDataFuture = loadData("");
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

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;

    // Call the specific API function
    await _fetchCarriageOutwardApi(userName);
  }

  Future<void> _fetchCarriageOutwardApi(String userName) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<CarriageOutwardList> fetchedList = [];
    int monthIndex = DateTime.now().month;

    DateTime fromDate = monthIndex == 4
        ? lastMonthFromDate!
        : fiscalYearStartDate!;

    try {
      do {
        var body = {
          "FromDate": formatApiRequestDate(fromDate),
          "ToDate": formatApiRequestDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken":
              DataManager.readSapToken(), // Ensure DataManager is imported
        };

        // Replace with your actual API Endpoint
        const apiUrl =
            '${ApiHelper.baseUrl}CRM_TransportCostList'; // Assuming Sales/Outward endpoint name

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final List list = json['responseData'] ?? [];
          final newList = list
              .map((e) => CarriageOutwardList.fromJson(e))
              .toList();

          fetchedList.addAll(newList);
          fetchedCount = newList.length;
          index++;
        } else {
          fetchedCount = 0;
          if (kDebugMode) print("API Error: ${response.statusCode}");
        }
      } while (fetchedCount == limit);

      if (mounted) {
        setState(() {
          // Update Global List
          carriageOutwardList = fetchedList;
          chartDataLoaded = true;
          _selectedBranch = "Karnataka State";
        });
        await _processDataAndGenerateGraph();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading data: $e");
      } else {
        if (!mounted) return;
        NotificationService.error(
          title: "Error",
          message: "Error occured while loading transportation cost data.",
        );
      }
    }
  }

  String formatApiRequestDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
  }

  Future<void> _processDataAndGenerateGraph() async {
    if (carriageOutwardList.isEmpty || _selectedBranch == null) return;

    setState(() => isLoading = true);

    await Future.delayed(Duration(milliseconds: 50));

    Map<String, double> groupedData = {};

    // 'M' handles single digits, 'd' handles single digits.
    final apiDateFormatter = DateFormat("M/d/yyyy hh:mm:ss a");

    for (var item in carriageOutwardList) {
      // Filter 1: Branch
      if (item.branchName != _selectedBranch) continue;

      // Filter 2: Date Parsing
      DateTime? postingDate;
      try {
        postingDate = apiDateFormatter.parse(item.postingDate);
      } catch (e) {
        continue;
      }

      // Filter 3: Selected Month/Year
      if (postingDate.year == selectedDate.year &&
          postingDate.month == selectedDate.month) {
        double cost = double.tryParse(item.totalFreightCharges) ?? 0.0;
        String key = item.customerName.isEmpty
            ? "Unknown Customer"
            : item.customerName;

        // Summation
        groupedData[key] = (groupedData[key] ?? 0) + cost;
      }
    }

    // Convert to Graph Data List
    List<CustomerFreightData> resultList = groupedData.entries.map((entry) {
      return CustomerFreightData(
        customerName: entry.key,
        totalFreight: entry.value,
      );
    }).toList();

    // Sort descending
    resultList.sort((a, b) => b.totalFreight.compareTo(a.totalFreight));

    if (!mounted) return;

    setState(() {
      _graphData = resultList;
      isLoading = false;
    });
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

  void LoadDates() {
    currentDate = DateTime.now();
    currentMonthFromDate = DateTime(currentDate!.year, currentDate!.month, 1);

    // Calculate Fiscal Year Start (Assuming April 1st)
    int fiscalYearStartMonth = 4;
    int fiscalYear = currentDate!.month >= fiscalYearStartMonth
        ? currentDate!.year
        : currentDate!.year - 1;
    fiscalYearStartDate = DateTime(fiscalYear, fiscalYearStartMonth, 1);

    lastMonthFromDate = DateTime(currentDate!.year, currentDate!.month - 1, 1);
    Map<String, DateTime> monthDates = getMonthStartEndDates(
      selectedDate.month,
    );
    formattedFiscalYearStartDate = DateFormat(
      'dd/MM/yy',
    ).format(monthDates["start"]!);
    formattedDateNow = DateFormat('dd/MM/yy').format(monthDates["end"]!);
  }

  String formatAmount(double amount) {
    if (amount >= 100000) return "${(amount / 1000).toStringAsFixed(1)}k";
    return amount.toStringAsFixed(0);
  }

  Future<void> _generateCarriageOutwardExcel(BuildContext context) async {
    if (_graphData.isEmpty) {
      if (!mounted) return;
      NotificationService.info(title: "Info", message: "No data to export.");
      return;
    }

    await reportService.generateExcel(
      sheetName: 'OutwardFreight',
      headers: ['Customer Name', 'Freight Charges'],
      rows: _graphData
          .map((data) => [data.customerName, data.totalFreight])
          .toList(),
      fileName: 'freight_outward.xlsx',
      amountColumns: [2],
      addTotalRow: true,
      reportTitle:
          'Production[MIS] - Freight Outward - Branch: $_selectedBranch - ${DateFormat('MMMM yyyy').format(selectedDate)}',
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
      await _processDataAndGenerateGraph();
    }
  }

  Future<void> loadDataClearFilter() async {
    setState(() {
      isLoading = true;
    });

    try {
      selectedDate = DateTime.now();
      LoadDates();
      await loadData("");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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

  SideTitles get _bottomTitlesFreightSuctomers => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<CustomerFreightData> mData = _graphData;
      text = mData.elementAt(value.toInt()).customerName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: text.length > 10
              ? Text(
                  '${text.substring(0, 10)}...',
                  style: const TextStyle(fontSize: 12),
                )
              : Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    // If global data is not ready, show loader (handled by FutureBuilder logic typically, or simplistic bool check)
    if (!chartDataLoaded && carriageOutwardList.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Stack(
      children: [
        FinanceVerticalScroll(
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
                      Text("$formattedFiscalYearStartDate - $formattedDateNow"),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 15),
                      Text(
                        "Outward Carriage Cost",
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.all(8),
                child: DashboardCardUI(
                  title: 'Customer wise Freight Charges',
                  spacing: 10,
                  menuItems: [
                    PopupMenuItem(
                      onTap: () {
                        _generateCarriageOutwardExcel(context);
                      },
                      child: const Text("Download Excel"),
                    ),
                  ],
                  
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          BranchDropdown(
                            production: carriageOutwardList,
                            onChanged: (newValue) async {
                              setState(() {
                                _selectedBranch = newValue;
                              });
                              if (newValue != null)
                                await _processDataAndGenerateGraph();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildFreightChart(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
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

  Widget _buildFreightChart() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = _graphData.length;
    if (_graphData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? _graphData
              .map((data) => data.totalFreight)
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
              alignment: BarChartAlignment.spaceAround,
              // Add a bit of buffer to MaxY so bars don't hit the top
              maxY: getMaxValue(maxAmount, 5000),
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
                  sideTitles: _bottomTitlesFreightSuctomers,
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
              barGroups: List.generate(_graphData.length, (index) {
                final data = _graphData[index];
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: data.totalFreight,
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
                      _graphData[grpIndex].customerName,
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "\nTotal Freight: ${formatAmount(_graphData[grpIndex].totalFreight)}",
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

class BranchDropdown extends StatefulWidget {
  final List production;
  final ValueChanged<String?> onChanged;
  final String placeholder;

  const BranchDropdown({
    super.key,
    required this.production,
    required this.onChanged,
    this.placeholder = 'Select Branch',
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
    _items = _extractItemSubGroups(widget.production);
    _selected = _items.isNotEmpty ? _items.first : null;
  }

  List<String> _extractItemSubGroups(List list) {
    final seen = <String>{};
    final out = <String>[];
    for (var e in list) {
      String val = '';
      try {
        val = (e.branchName ?? '').toString().trim();
      } catch (_) {
        if (e is Map && e.containsKey('branchName')) {
          val = (e['branchName'] ?? '').toString();
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
