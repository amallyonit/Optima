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
import 'package:optima/classes/dataManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

// --- Global Variables ---
List<CarriageInwardList> carriageInwardList = [];
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

class CarriageInwardList {
  final String invoiceNo;
  final String postingDate;
  final String vendorCode;
  final String vendorName;
  final String branchName;
  final String totalFreightCharges;

  CarriageInwardList({
    required this.invoiceNo,
    required this.postingDate,
    required this.vendorCode,
    required this.vendorName,
    required this.branchName,
    required this.totalFreightCharges,
  });

  factory CarriageInwardList.fromJson(Map<String, dynamic> json) {
    return CarriageInwardList(
      invoiceNo: json['invoiceNo']?.toString() ?? '',
      postingDate: json['postingDate']?.toString() ?? '',
      vendorCode: json['vendorCode']?.toString() ?? '',
      vendorName: json['vendorName']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? '',
      totalFreightCharges: json['totalFreightCharges']?.toString() ?? '0.0',
    );
  }
}

class VendorFreightData {
  final String vendorName;
  final double totalFreight;

  VendorFreightData({required this.vendorName, required this.totalFreight});
}

class CarriageInwardMISProvider with ChangeNotifier {
  List<CarriageInwardList> _salesList = [];
  List<CarriageInwardList> get salesList => _salesList;
  void updateProductionList(List<CarriageInwardList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class CarriageInwardPage extends StatefulWidget {
  const CarriageInwardPage({super.key});

  @override
  State<CarriageInwardPage> createState() => _CarriageInwardPageState();
}

class _CarriageInwardPageState extends State<CarriageInwardPage> {
  DateTime _selectedMonth = DateTime.now();

  // Graph Data
  List<VendorFreightData> _graphData = [];
  List<String> _availableBranches = [];

  bool isLoading = false;
  String? _selectedBranch;

  double _totalFreight = 0;

  @override
  void initState() {
    super.initState();
    LoadDates();

    if (isUserLoggedIn && isBiDashboardStart) {
      if (!chartDataLoaded || carriageInwardList.isEmpty) {
        loadDataFuture = loadData("");
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _extractBranches();
          _processDataAndGenerateGraph();
        });
      }
    }
  }

  // --- API Loading Logic ---
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
    List<CarriageInwardList> salesList = [];
    int monthIndex = DateTime.now().month;

    // Use global date logic for API Request
    DateTime fromDate = monthIndex == 4
        ? lastMonthFromDate!
        : fiscalYearStartDate!;

    try {
      do {
        var body = {
          "FromDate": formatApiRequestDate(fromDate), // yyyyMMdd for request
          "ToDate": formatApiRequestDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        const apiUrl = '${ApiHelper.baseUrl}CRM_PurchaseTransportCostList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<CarriageInwardList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => CarriageInwardList.fromJson(item))
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
          carriageInwardList = salesList;
          context.read<CarriageInwardMISProvider>().updateProductionList(
            salesList,
          );
          chartDataLoaded = true;

          _extractBranches();
          if (_availableBranches.isNotEmpty) {
            _selectedBranch ??= _availableBranches.first;
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

  String formatApiRequestDate(DateTime date) {
    // Format for API Payload (usually yyyyMMdd)
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
  }

  // --- Data Processing ---

  void _extractBranches() {
    final Set<String> branches = carriageInwardList
        .map((e) => e.branchName)
        .where((element) => element.isNotEmpty)
        .toSet();

    if (mounted) {
      setState(() {
        _availableBranches = branches.toList()..sort();
        // Default to first branch if selection is invalid/empty
        if (_selectedBranch == null && _availableBranches.isNotEmpty) {
          _selectedBranch = _availableBranches.first;
        } else if (_selectedBranch != null &&
            !_availableBranches.contains(_selectedBranch)) {
          _selectedBranch = _availableBranches.isNotEmpty
              ? _availableBranches.first
              : null;
        }
      });
    }
  }

  void _processDataAndGenerateGraph() {
    if (carriageInwardList.isEmpty) return;

    setState(() => isLoading = true);

    Map<String, double> groupedData = {};
    double totalFreightSum = 0;

    // **CRITICAL CHANGE**:
    // Format: "4/14/2025 12:00:00 AM" => "M/d/yyyy hh:mm:ss a"
    // 'M' handles 4 and 10. 'd' handles 4 and 14.
    final apiDateFormatter = DateFormat("M/d/yyyy hh:mm:ss a");

    for (var item in carriageInwardList) {
      // 1. Filter by Branch
      if (item.branchName != _selectedBranch) continue;

      // 2. Parse Date
      DateTime? orderDate;
      try {
        // Parse "4/14/2025 12:00:00 AM"
        orderDate = apiDateFormatter.parse(item.postingDate);
      } catch (e) {
        // Fallback in case of empty or malformed strings
        continue;
      }

      // 3. Filter by Selected Month
      if (orderDate.year == _selectedMonth.year &&
          orderDate.month == _selectedMonth.month) {
        double cost = double.tryParse(item.totalFreightCharges) ?? 0.0;
        String key = item.vendorName.isEmpty
            ? "Unknown Vendor"
            : item.vendorName;

        groupedData[key] = (groupedData[key] ?? 0) + cost;
        totalFreightSum += cost;
      }
    }

    // 4. Map to Chart Data
    List<VendorFreightData> resultList = groupedData.entries.map((entry) {
      return VendorFreightData(
        vendorName: entry.key,
        totalFreight: entry.value,
      );
    }).toList();

    // 5. Sort by Freight Cost Descending
    resultList.sort((a, b) => b.totalFreight.compareTo(a.totalFreight));

    setState(() {
      _graphData = resultList;
      _totalFreight = totalFreightSum;
      isLoading = false;
    });
  }

  String formatAmount(double amount) {
    if (amount >= 100000) {
      return "${(amount / 1000).toStringAsFixed(1)}k";
    }
    if (amount % 1 == 0) return amount.toInt().toString();
    return amount.toStringAsFixed(1);
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

  // --- Excel Export ---
  Future<void> _generateExcel(BuildContext context) async {
    if (_graphData.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export.')));
      return;
    }

    try {
      final excel = xl.Excel.createExcel();
      String defaultSheet = excel.sheets.keys.first;
      String sheetName = "Vendor Freight";
      excel.rename(defaultSheet, sheetName);
      final sheet = excel[sheetName];

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

      sheet.merge(
        xl.CellIndex.indexByString("A1"),
        xl.CellIndex.indexByString("B1"),
      );
      var titleCell = sheet.cell(xl.CellIndex.indexByString("A1"));
      titleCell.value = xl.TextCellValue(
        "Branch: $_selectedBranch - ${DateFormat('MMMM yyyy').format(_selectedMonth)}",
      );
      titleCell.cellStyle = titleStyle;

      List<String> headers = ["Vendor Name", "Total Freight Charges"];
      sheet.appendRow(headers.map((e) => xl.TextCellValue(e)).toList());

      for (int i = 0; i < headers.length; i++) {
        sheet
                .cell(
                  xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1),
                )
                .cellStyle =
            headerStyle;
      }

      for (var item in _graphData) {
        sheet.appendRow([
          xl.TextCellValue(item.vendorName),
          xl.DoubleCellValue(item.totalFreight),
        ]);
      }

      sheet.appendRow([
        xl.TextCellValue("TOTAL"),
        xl.DoubleCellValue(_totalFreight),
      ]);

      final fileBytes = excel.save();
      if (fileBytes != null && !kIsWeb) {
        final storageDir = await getStorageDirectory();
        final fileName =
            'Freight_${DateFormat('MMM_yyyy').format(_selectedMonth)}.xlsx';
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

  // --- Date Logic ---
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

  @override
  Widget build(BuildContext context) {
    return chartDataLoaded == true
        ? Scaffold(
            appBar: AppBar(
              title: const Text('Carriage Inward Summary'),
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
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.bar_chart,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "No data found for ${DateFormat('MMM yyyy').format(_selectedMonth)}",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                _buildSectionHeader(
                                  "Vendor wise Freight Charges",
                                  () => _generateExcel(context),
                                ),
                                const Divider(),
                                _buildProductionChart(),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          )
        : const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  Widget _buildControls() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Branch Dropdown
    final dropdown = SizedBox(
      width: 250,
      height: 45,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedBranch,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Select Branch',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
        ),
        items: _availableBranches
            .map(
              (branch) => DropdownMenuItem(
                value: branch,
                child: Text(branch, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() => _selectedBranch = value);
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

  Widget _buildSectionHeader(String title, VoidCallback onDownload) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
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

  Widget _buildProductionChart() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = _graphData.length > 3
        ? screenWidth + (80 * _graphData.length)
        : screenWidth;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 450,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0, right: 20.0),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (v, m) => Text(
                      formatAmount(v),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 100,
                    getTitlesWidget: (v, m) {
                      if (v.toInt() >= 0 && v.toInt() < _graphData.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: RotationTransition(
                            turns: const AlwaysStoppedAnimation(-20 / 360),
                            child: SizedBox(
                              width: 80,
                              child: Text(
                                _graphData[v.toInt()].vendorName,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
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
                      toY: data.totalFreight,
                      color: const Color(0xFF2ca9df),
                      width: 30,
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
                  getTooltipColor: (_) => Colors.white,
                  tooltipBorder: const BorderSide(color: Colors.grey, width: 1),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final data = _graphData[groupIndex];
                    return BarTooltipItem(
                      data.vendorName,
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: "\nFreight: ${formatAmount(data.totalFreight)}",
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
