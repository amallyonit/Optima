// ignore_for_file: file_names, use_build_context_synchronously, library_private_types_in_public_api
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optima/api_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../notificationService.dart';
import '../../dashboard_card_ui.dart';
import '../../ReportService.dart';

class DailyAttendanceData {
  final String date;
  final double target;
  final double onRoll;
  final double present;

  DailyAttendanceData({
    required this.date,
    required this.target,
    required this.onRoll,
    required this.present,
  });
}

class MonthlyWorkforceSummaryPage extends StatefulWidget {
  const MonthlyWorkforceSummaryPage({super.key});

  @override
  State<MonthlyWorkforceSummaryPage> createState() =>
      _MonthlyWorkforceSummaryPageState();
}

class _MonthlyWorkforceSummaryPageState
    extends State<MonthlyWorkforceSummaryPage> {
  DateTime _selectedMonth = DateTime.now();
  List<DailyAttendanceData> _graphData = [];
  bool isLoading = false;
  String? _selectedPlant = 'Rajapalayam Plant';
  final reportService = ReportService();

  // Summary Variables
  double _avgTarget = 0;
  double _avgOnRoll = 0;
  double _avgPresent = 0;

  String formatAmount(double amount) {
    if (amount % 1 == 0) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(1);
  }

  void _calculateAverages() {
    if (_graphData.isEmpty) {
      setState(() {
        _avgTarget = 0;
        _avgOnRoll = 0;
        _avgPresent = 0;
      });
      return;
    }

    double totalTarget = 0;
    double totalOnRoll = 0;
    double totalPresent = 0;

    for (var item in _graphData) {
      totalTarget += item.target;
      totalOnRoll += item.onRoll;
      totalPresent += item.present;
    }

    setState(() {
      _avgTarget = totalTarget / _graphData.length;
      _avgOnRoll = totalOnRoll / _graphData.length;
      _avgPresent = totalPresent / _graphData.length;
    });
  }

  Future<void> _createAndOpenExcel(
    BuildContext context, {
    required bool isSummary,
  }) async {
    if (_graphData.isEmpty) {
      if (!mounted) return;
      NotificationService.info(title: "Info", message: "No data to export.");
      return;
    }
    List<String> headers = [];
    List<List<dynamic>> _rows = [];
    List<int> _amountColumns = [];

    if (isSummary) {
      headers = ["Metric", "Average Value"];

      final avgAbsent = math.max(0, _avgOnRoll - _avgPresent);

      _rows = [
        ["Average Target", _avgTarget],
        ["Average OnRoll", _avgOnRoll],
        ["Average Present", _avgPresent],
        ["Average Absent", avgAbsent],
      ];
    } else {
      headers = ["Date", "Target", "Onroll", "Present", "Absent"];

      _rows = _graphData.map((item) {
        final absent = math.max(0, item.onRoll - item.present);

        return [item.date, item.target, item.onRoll, item.present, absent];
      }).toList();

      _amountColumns = [2, 3, 4, 5];
    }
    await reportService.generateExcel(
      sheetName: isSummary ? "Monthly Summary" : "Daily Breakdown",
      headers: headers,
      rows: _rows,
      fileName:
          'workforce_${isSummary ? "Summary" : "Daily"}_${DateFormat('MMM_yyyy').format(_selectedMonth)}.xlsx',
      amountColumns: _amountColumns,
      addTotalRow: true,
      reportTitle:
          'Production[MIS] - Workforce Plant: $_selectedPlant - ${DateFormat('MMMM yyyy').format(_selectedMonth)} (${isSummary ? 'Summary' : 'Daily'})"',
    );
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
        _graphData.clear();
      });
      _fetchAndGenerateGraph();
    }
  }

  Future<void> _fetchAndGenerateGraph() async {
    setState(() => isLoading = true);

    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    );
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'UserJwtToken': prefs.getString('userJwtToken') ?? '',
      'UsermailID': prefs.getString('userMailID') ?? '',
      "AttendancePlant": _selectedPlant,
      "FromDate": startOfMonth.toIso8601String(),
      "ToDate": endOfMonth.toIso8601String(),
    };
    const apiUrl = '${ApiHelper.baseUrl}selectmonthlyattendance';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(payload),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['Status'] == true && decoded['Data'] != null) {
          _loadGraphData(decoded['Data']);
        } else {
          setState(() => _graphData = []);
        }
      }
    } catch (e) {
      // Handle Error
    }
    // MOCK API CALL END

    setState(() => isLoading = false);
  }

  void _loadGraphData(List<dynamic> apiResult) {
    List<DailyAttendanceData> processedList = [];
    for (var item in apiResult) {
      String dateStr = item['AttendanceDate'] ?? '';
      DateTime? dt = DateTime.tryParse(dateStr);
      String displayDate = dt != null
          ? DateFormat('dd MMM').format(dt)
          : dateStr;

      double target =
          double.tryParse(item['AttendanceTarget']?.toString() ?? '0') ?? 0.0;
      double onroll =
          double.tryParse(item['AttendanceOnroll']?.toString() ?? '0') ?? 0.0;
      double present =
          double.tryParse(item['AttendancePresent']?.toString() ?? '0') ?? 0.0;

      processedList.add(
        DailyAttendanceData(
          date: displayDate,
          target: target,
          onRoll: onroll,
          present: present,
        ),
      );
    }
    setState(() {
      _graphData = processedList;
      _calculateAverages(); // <--- Important: Recalculate averages when data loads
    });
  }

  double getMaxValue(double maxValue, double divVal) {
    return (maxValue / divVal).ceil() * divVal;
  }

  SideTitles get _leftTitles => SideTitles(
    reservedSize: 40,
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

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _dailyHorizontalController = ScrollController();
  final ScrollController _monthlyHorizontalController = ScrollController();

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _dailyHorizontalController.dispose();
    _monthlyHorizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FinanceVerticalScroll(
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
              ? const Center(child: Text("Select a month to view data"))
              : SizedBox(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: DashboardCardUI(
                          title: 'Daily Breakdown',
                          spacing: 10,
                          menuItems: [
                            PopupMenuItem(
                              onTap: () {
                                _createAndOpenExcel(context, isSummary: false);
                              },
                              child: const Text("Download Excel"),
                            ),
                          ],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLegend(),
                              const SizedBox(height: 10),
                              _dailyBreakdownChart(),
                            ],
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: DashboardCardUI(
                          title: 'Monthly Average Summary',
                          spacing: 10,
                          menuItems: [
                            PopupMenuItem(
                              onTap: () {
                                _createAndOpenExcel(context, isSummary: true);
                              },
                              child: const Text("Download Excel"),
                            ),
                          ],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 15),
                              _summaryChart(),
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
    );
  }

  Widget _dailyBreakdownChart() {
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate width: screen width + 50px per item if items > 5
    double chartWidth = _graphData.length > 5
        ? screenWidth + (50 * _graphData.length)
        : screenWidth;
    final len = _graphData.length;

    double maxAmount = len > 0
        ? _graphData.fold<double>(
            0,
            (max, e) =>
                [max, e.present, e.target].reduce((a, b) => a > b ? a : b),
          )
        : 0;
    return FinanceHorizontalChartScroll(
      controller: _dailyHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(maxAmount, 50),
              alignment: BarChartAlignment.spaceEvenly,
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
                    reservedSize: 40,
                    getTitlesWidget: (v, m) {
                      if (v.toInt() >= 0 && v.toInt() < _graphData.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: RotationTransition(
                            turns: const AlwaysStoppedAnimation(-45 / 360),
                            child: Text(
                              _graphData[v.toInt()].date,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
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
                      toY: data.target,
                      color: Colors.grey.shade400,
                      width: 12,
                      borderRadius: BorderRadius.zero,
                    ),
                    BarChartRodData(
                      toY: data.onRoll,
                      color: const Color(0xFF97D7F3),
                      width: 12,
                      borderRadius: BorderRadius.zero,
                    ),
                    BarChartRodData(
                      toY: data.present,
                      color: Colors.lightGreen,
                      width: 12,
                      borderRadius: BorderRadius.zero,
                    ),
                  ],
                );
              }),

              // --- FIXED TOUCH DATA ---
              barTouchData: BarTouchData(
                enabled: true,
                handleBuiltInTouches: true,
                touchExtraThreshold: const EdgeInsets.all(10),
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (_) => Colors.white,
                  tooltipBorder: const BorderSide(color: Colors.grey, width: 1),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final data = _graphData[groupIndex];
                    return BarTooltipItem(
                      data.date,
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: "\nTarget: ${formatAmount(data.target)}",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: "\nOnRoll: ${formatAmount(data.onRoll)}",
                          style: const TextStyle(
                            color: Color(0xFF2ca9df),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: "\nPresent: ${formatAmount(data.present)}",
                          style: const TextStyle(
                            color: Colors.green,
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

  Widget _summaryChart() {
    double maxValue = math.max(_avgTarget, math.max(_avgPresent, _avgOnRoll));
    return FinanceHorizontalChartScroll(
      controller: _monthlyHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: 330,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(maxValue, 50),
              alignment: BarChartAlignment.spaceEvenly,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (v, m) => Text(
                      formatAmount(v),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (v, m) {
                      switch (v.toInt()) {
                        case 0:
                          return const Text(
                            "Avg Target",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        case 1:
                          return const Text(
                            "Avg OnRoll",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        case 2:
                          return const Text(
                            "Avg Present",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
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
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: _avgTarget,
                      color: Colors.grey.shade400,
                      width: 25,
                      borderRadius: BorderRadius.zero,
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: _avgOnRoll,
                      color: const Color(0xFF97D7F3),
                      width: 25,
                      borderRadius: BorderRadius.zero,
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 2,
                  barRods: [
                    BarChartRodData(
                      toY: _avgPresent,
                      color: Colors.lightGreen,
                      width: 25,
                      borderRadius: BorderRadius.zero,
                    ),
                  ],
                ),
              ],
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.white,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    String label = "";
                    if (group.x == 0) label = "Average Target";
                    if (group.x == 1) label = "Average OnRoll";
                    if (group.x == 2) label = "Average Present";
                    return BarTooltipItem(
                      label,
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: '\n${rod.toY.toStringAsFixed(1)}',
                          style: TextStyle(color: rod.color, fontSize: 14),
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

  Widget _buildControls() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final dropdown = SizedBox(
      width: 200,
      height: 45,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedPlant,
        decoration: InputDecoration(
          labelText: 'Select Plant',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
        ),
        items: const [
          DropdownMenuItem(
            value: 'Rajapalayam Plant',
            child: Text('Rajapalayam Plant'),
          ),
          DropdownMenuItem(
            value: 'Bangalore IPD Plant',
            child: Text('Bangalore IPD Plant'),
          ),
          DropdownMenuItem(
            value: 'Bangalore MD Plant',
            child: Text('Bangalore MD Plant'),
          ),
        ],
        onChanged: (value) => setState(() => _selectedPlant = value),
      ),
    );
    final monthButton = ElevatedButton.icon(
      onPressed: _pickMonth,
      icon: const Icon(Icons.calendar_month),
      label: Text(DateFormat('MMM yyyy').format(_selectedMonth)),
      style: ElevatedButton.styleFrom(minimumSize: const Size(130, 45)),
    );
    final generateButton = ElevatedButton(
      onPressed: _fetchAndGenerateGraph,
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
                    "Monthly Workforce Details",
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
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const SizedBox(width: 15),
                Text(
                  "Monthly Workforce Details",
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

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem("Target", Colors.grey.shade400),
        const SizedBox(width: 15),
        _legendItem("OnRoll", const Color(0xFF97D7F3)),
        const SizedBox(width: 15),
        _legendItem("Present", Colors.lightGreen),
      ],
    );
  }

  Widget _legendItem(String text, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
