// ignore_for_file: file_names, use_build_context_synchronously, library_private_types_in_public_api
import 'dart:convert';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb check
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optima/api_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Excel Imports
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

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

  // --- EXCEL: DAILY BREAKDOWN ---
  Future<void> _generateDailyExcel(BuildContext context) async {
    if (_graphData.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export.')));
      return;
    }
    _createAndOpenExcel(context, isSummary: false);
  }

  // --- EXCEL: MONTHLY SUMMARY ---
  Future<void> _generateSummaryExcel(BuildContext context) async {
    if (_graphData.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export.')));
      return;
    }
    _createAndOpenExcel(context, isSummary: true);
  }

  // --- SHARED EXCEL LOGIC ---
  Future<void> _createAndOpenExcel(
    BuildContext context, {
    required bool isSummary,
  }) async {
    try {
      final excel = xl.Excel.createExcel();
      String defaultSheet = excel.sheets.keys.first;
      String sheetName = isSummary ? "Monthly Summary" : "Daily Breakdown";
      excel.rename(defaultSheet, sheetName);
      final sheet = excel[sheetName];

      // Styles
      final headerStyle = xl.CellStyle(
        bold: true,
        horizontalAlign: xl.HorizontalAlign.Center,
        backgroundColorHex: xl.ExcelColor.fromHexString("#D3D3D3"),
      );
      final titleStyle = xl.CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: xl.HorizontalAlign.Center,
      );

      // Title
      sheet.merge(
        xl.CellIndex.indexByString("A1"),
        xl.CellIndex.indexByString("E1"),
      );
      var titleCell = sheet.cell(xl.CellIndex.indexByString("A1"));
      titleCell.value = xl.TextCellValue(
        "Plant: $_selectedPlant - ${DateFormat('MMMM yyyy').format(_selectedMonth)} (${isSummary ? 'Summary' : 'Daily'})",
      );
      titleCell.cellStyle = titleStyle;

      if (isSummary) {
        // --- SUMMARY SHEET CONTENT ---
        List<String> headers = ["Metric", "Average Value"];
        sheet.appendRow(headers.map((e) => xl.TextCellValue(e)).toList());

        // Apply Header Style
        for (int i = 0; i < headers.length; i++) {
          sheet
                  .cell(
                    xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1),
                  )
                  .cellStyle =
              headerStyle;
        }

        double avgAbsent = (_avgOnRoll - _avgPresent) < 0
            ? 0
            : (_avgOnRoll - _avgPresent);

        sheet.appendRow([
          xl.TextCellValue("Average Target"),
          xl.DoubleCellValue(double.parse(_avgTarget.toStringAsFixed(2))),
        ]);
        sheet.appendRow([
          xl.TextCellValue("Average OnRoll"),
          xl.DoubleCellValue(double.parse(_avgOnRoll.toStringAsFixed(2))),
        ]);
        sheet.appendRow([
          xl.TextCellValue("Average Present"),
          xl.DoubleCellValue(double.parse(_avgPresent.toStringAsFixed(2))),
        ]);
        sheet.appendRow([
          xl.TextCellValue("Average Absent"),
          xl.DoubleCellValue(double.parse(avgAbsent.toStringAsFixed(2))),
        ]);
      } else {
        // --- DAILY SHEET CONTENT ---
        List<String> headers = [
          "Date",
          "Target",
          "Onroll",
          "Present",
          "Absent",
        ];
        sheet.appendRow(headers.map((e) => xl.TextCellValue(e)).toList());

        // Apply Header Style
        for (int i = 0; i < headers.length; i++) {
          sheet
                  .cell(
                    xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1),
                  )
                  .cellStyle =
              headerStyle;
        }

        for (var item in _graphData) {
          double absent = (item.onRoll - item.present) < 0
              ? 0
              : (item.onRoll - item.present);
          sheet.appendRow([
            xl.TextCellValue(item.date),
            xl.DoubleCellValue(item.target),
            xl.DoubleCellValue(item.onRoll),
            xl.DoubleCellValue(item.present),
            xl.DoubleCellValue(absent),
          ]);
        }
      }

      // Save & Open
      final fileBytes = excel.save();
      if (fileBytes != null && !kIsWeb) {
        final storageDir = await getStorageDirectory();
        final fileName =
            'Workforce_${isSummary ? "Summary" : "Daily"}_${DateFormat('MMM_yyyy').format(_selectedMonth)}.xlsx';
        final file = File('$storageDir/$fileName');
        await file.writeAsBytes(fileBytes, flush: true);
        OpenFile.open(file.path);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Exported: $fileName')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<String> getStorageDirectory() async {
    if (Platform.isAndroid) {
      return (await getExternalStorageDirectory())?.path ??
          (await getApplicationDocumentsDirectory()).path;
    }
    return (await getApplicationDocumentsDirectory()).path;
  }

  // --- API LOGIC ---
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
    // ... (Same API Logic as before) ...
    // Note: I'm abbreviating standard boilerplate for brevity, paste your API call here.
    // Ensure you call _calculateAverages() after loading data.

    // MOCK API CALL START (Replace with your actual HTTP call)
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

  // --- CHART WIDGETS ---

  Widget _buildSectionHeader(String title, VoidCallback onDownload) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const SizedBox(width: 5),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: onDownload,
              child: const Row(
                children: [
                  Icon(Icons.download, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text("Download Excel"),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dailyBreakdownChart() {
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate width: screen width + 50px per item if items > 5
    double chartWidth = _graphData.length > 5
        ? screenWidth + (50 * _graphData.length)
        : screenWidth;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
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
              enabled: true, // Explicitly enable
              handleBuiltInTouches:
                  true, // MUST be true for tooltips to show on tap
              touchExtraThreshold: const EdgeInsets.all(
                10,
              ), // Makes it easier to tap thin bars
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.white,
                tooltipBorder: const BorderSide(
                  color: Colors.grey,
                  width: 1,
                ), // Optional border
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
    );
  }

  // 2. SUMMARY CHART
  Widget _summaryChart() {
    return SizedBox(
      height: 300,
      width: double.infinity, // Fixed width, no scroll needed for 3 bars
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, m) =>
                    Text(formatAmount(v), style: const TextStyle(fontSize: 10)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workforce Analysis'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Controls
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildControls(),
              ),
            ),
            const SizedBox(height: 10),

            // Content
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _graphData.isEmpty
                  ? const Center(child: Text("Select a month to view data"))
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          // 1. Legend
                          _buildLegend(),
                          const SizedBox(height: 20),

                          // 2. Daily Breakdown Section
                          _buildSectionHeader(
                            "Daily Breakdown",
                            () => _generateDailyExcel(context),
                          ),
                          const Divider(),
                          _dailyBreakdownChart(),
                          const SizedBox(height: 40),

                          // 3. Monthly Summary Section
                          _buildSectionHeader(
                            "Monthly Average Summary",
                            () => _generateSummaryExcel(context),
                          ),
                          const Divider(),
                          _summaryChart(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CONTROLS & LEGEND (Unchanged mostly) ---
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
            horizontal: 10,
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
