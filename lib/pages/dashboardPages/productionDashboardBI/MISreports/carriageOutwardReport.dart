// ignore_for_file: non_constant_identifier_names, file_names, use_build_context_synchronously, library_private_types_in_public_api
import 'dart:convert';
import 'dart:io';
import 'package:optima/classes/globals.dart'; // Keep your original imports
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

// --- Global Variables (Matching your original structure) ---
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

// --- DATA CLASS ---
class CarriageOutwardList {
  final String invoiceNo;
  final String postingDate;
  final String customerCode;
  final String customerName;
  final String termsofDelivery;
  final String dispatchThrough;
  final String destinationDetails;
  final String state;
  final String lrNo;
  final String lrDate;
  final String totalNoofBoxes;
  final String totalNoofBundles;
  final String deliveryDate;
  final String totalFreightCharges;
  final String freightCharges;
  final String branchName;
  final String confirmationStatus;
  final String minimumOrderValue;
  final String customerCity;
  final String bpSubSubGroup;
  final String bpReferenceNo;
  final String documentDate;
  final String totalTax;
  final String totalDiscount;
  final String documentTotal;
  final String paidtoDate;
  final String difference;
  final String invStatus;
  final String remarks;

  CarriageOutwardList({
    required this.invoiceNo,
    required this.postingDate,
    required this.customerCode,
    required this.customerName,
    required this.termsofDelivery,
    required this.dispatchThrough,
    required this.destinationDetails,
    required this.state,
    required this.lrNo,
    required this.lrDate,
    required this.totalNoofBoxes,
    required this.totalNoofBundles,
    required this.deliveryDate,
    required this.totalFreightCharges,
    required this.freightCharges,
    required this.branchName,
    required this.confirmationStatus,
    required this.minimumOrderValue,
    required this.customerCity,
    required this.bpSubSubGroup,
    required this.bpReferenceNo,
    required this.documentDate,
    required this.totalTax,
    required this.totalDiscount,
    required this.documentTotal,
    required this.paidtoDate,
    required this.difference,
    required this.invStatus,
    required this.remarks,
  });

  factory CarriageOutwardList.fromJson(Map<String, dynamic> json) {
    return CarriageOutwardList(
      invoiceNo: json['invoiceNo']?.toString() ?? '',
      postingDate: json['postingDate']?.toString() ?? '',
      customerCode: json['customerCode']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      termsofDelivery: json['termsofDelivery']?.toString() ?? '',
      dispatchThrough: json['dispatchThrough']?.toString() ?? '',
      destinationDetails: json['destinationDetails']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      lrNo: json['lrNo']?.toString() ?? '',
      lrDate: json['lrDate']?.toString() ?? '',
      totalNoofBoxes: json['totalNoofBoxes']?.toString() ?? '',
      totalNoofBundles: json['totalNoofBundles']?.toString() ?? '',
      deliveryDate: json['deliveryDate']?.toString() ?? '',
      totalFreightCharges: json['totalFreightCharges']?.toString() ?? '0.0',
      freightCharges: json['freightCharges']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? '',
      confirmationStatus: json['confirmationStatus']?.toString() ?? '',
      minimumOrderValue: json['minimumOrderValue']?.toString() ?? '',
      customerCity: json['customerCity']?.toString() ?? '',
      bpSubSubGroup: json['bpSubSubGroup']?.toString() ?? '',
      bpReferenceNo: json['bpReferenceNo']?.toString() ?? '',
      documentDate: json['documentDate']?.toString() ?? '',
      totalTax: json['totalTax']?.toString() ?? '',
      totalDiscount: json['totalDiscount']?.toString() ?? '',
      documentTotal: json['documentTotal']?.toString() ?? '',
      paidtoDate: json['paidtoDate']?.toString() ?? '',
      difference: json['difference']?.toString() ?? '',
      invStatus: json['invStatus']?.toString() ?? '',
      remarks: json['remarks']?.toString() ?? '',
    );
  }
}

// Helper class for Graphing
class CustomerFreightData {
  final String customerName;
  final double totalFreight;
  CustomerFreightData({required this.customerName, required this.totalFreight});
}

class CarriageOutwardMISProvider with ChangeNotifier {
  List<CarriageOutwardList> _salesList = [];
  List<CarriageOutwardList> get salesList => _salesList;
  void updateProductionList(List<CarriageOutwardList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class CarriageOutwardPage extends StatefulWidget {
  const CarriageOutwardPage({super.key});

  @override
  State<CarriageOutwardPage> createState() => _CarriageOutwardPageState();
}

class _CarriageOutwardPageState extends State<CarriageOutwardPage> {
  // UI State
  DateTime _selectedMonth = DateTime.now();
  String? _selectedBranch;
  List<String> _availableBranches = [];
  List<CustomerFreightData> _graphData = [];
  double _totalFreight = 0;
  bool isLoading = false; // Internal loading for graph processing

  @override
  void initState() {
    super.initState();
    LoadDates();

    // Check Global login state (assuming these globals exist in your project)
    if (isUserLoggedIn && isBiDashboardStart) {
      if (!chartDataLoaded || carriageOutwardList.isEmpty) {
        // Load data if not already present
        loadDataFuture = loadData("");
      } else {
        // Data already exists, just process it
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _extractBranches();
          _processDataAndGenerateGraph();
        });
      }
    }
  }

  // --- 1. API LOADING LOGIC ---
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
          context.read<CarriageOutwardMISProvider>().updateProductionList(
            fetchedList,
          );
          chartDataLoaded = true;

          // Trigger UI Update
          _extractBranches();
          // Auto-select first branch and generate graph
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
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
  }

  // --- 2. DATA PROCESSING ---

  void _extractBranches() {
    // Get unique branch names
    final Set<String> branches = carriageOutwardList
        .map((e) => e.branchName)
        .where((element) => element.isNotEmpty)
        .toSet();

    if (mounted) {
      setState(() {
        _availableBranches = branches.toList()..sort();

        // Validation: Ensure selected branch is valid
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
    if (carriageOutwardList.isEmpty || _selectedBranch == null) return;

    setState(() => isLoading = true);

    Map<String, double> groupedData = {};
    double totalFreightSum = 0;

    // Date Format from API response: "4/8/2025 12:00:00 AM"
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
      if (postingDate.year == _selectedMonth.year &&
          postingDate.month == _selectedMonth.month) {
        double cost = double.tryParse(item.totalFreightCharges) ?? 0.0;
        String key = item.customerName.isEmpty
            ? "Unknown Customer"
            : item.customerName;

        // Summation
        groupedData[key] = (groupedData[key] ?? 0) + cost;
        totalFreightSum += cost;
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

    setState(() {
      _graphData = resultList;
      _totalFreight = totalFreightSum;
      isLoading = false;
    });
  }

  // --- 3. HELPER METHODS ---

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
  }

  String formatAmount(double amount) {
    if (amount >= 100000) return "${(amount / 1000).toStringAsFixed(1)}k";
    return amount.toStringAsFixed(0);
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

  // --- 4. EXCEL EXPORT ---
  Future<void> _generateExcel(BuildContext context) async {
    if (_graphData.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export.')));
      return;
    }
    try {
      final excel = xl.Excel.createExcel();
      String sheetName = "Outward Freight";
      excel.rename(excel.sheets.keys.first, sheetName);
      final sheet = excel[sheetName];

      sheet.appendRow([
        xl.TextCellValue("Branch: $_selectedBranch"),
        xl.TextCellValue(
          "Period: ${DateFormat('MMM yyyy').format(_selectedMonth)}",
        ),
      ]);
      sheet.appendRow([
        xl.TextCellValue("Customer Name"),
        xl.TextCellValue("Freight Charges"),
      ]);

      for (var item in _graphData) {
        sheet.appendRow([
          xl.TextCellValue(item.customerName),
          xl.DoubleCellValue(item.totalFreight),
        ]);
      }
      sheet.appendRow([
        xl.TextCellValue("TOTAL"),
        xl.DoubleCellValue(_totalFreight),
      ]);

      final fileBytes = excel.save();
      if (fileBytes != null && !kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File(
          '${dir.path}/Freight_Outward_${DateFormat('MMM_yyyy').format(_selectedMonth)}.xlsx',
        );
        await file.writeAsBytes(fileBytes);
        OpenFile.open(file.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // --- 5. UI BUILD ---

  @override
  Widget build(BuildContext context) {
    // If global data is not ready, show loader (handled by FutureBuilder logic typically, or simplistic bool check)
    if (!chartDataLoaded && carriageOutwardList.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carriage Outward Summary'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Controls Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildControls(),
              ),
            ),
            const SizedBox(height: 10),

            // Main Content Area
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
                            "Customer wise Freight Charges",
                            () => _generateExcel(context),
                          ),
                          const Divider(),
                          _buildChart(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    // Branch Dropdown
    final dropdown = SizedBox(
      height: 50,
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

    // Month Picker Button
    final monthButton = ElevatedButton.icon(
      onPressed: _pickMonth,
      icon: const Icon(Icons.calendar_month),
      label: Text(DateFormat('MMM yyyy').format(_selectedMonth)),
      style: ElevatedButton.styleFrom(minimumSize: const Size(130, 45)),
    );

    return Column(
      children: [
        dropdown,
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [monthButton],
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
        IconButton(
          icon: const Icon(Icons.download, color: Colors.green),
          onPressed: onDownload,
        ),
      ],
    );
  }

  Widget _buildChart() {
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate width to allow scrolling if many customers
    double chartWidth = _graphData.length > 5
        ? screenWidth + (60 * (_graphData.length - 5))
        : screenWidth;
    if (chartWidth < screenWidth) chartWidth = screenWidth;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 450,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0, right: 20.0, bottom: 10),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              // Add a bit of buffer to MaxY so bars don't hit the top
              maxY: _graphData.isEmpty
                  ? 100
                  : _graphData
                            .map((e) => e.totalFreight)
                            .reduce((a, b) => a > b ? a : b) *
                        1.2,
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
                                _graphData[v.toInt()].customerName,
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
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.white,
                  tooltipBorder: const BorderSide(color: Colors.grey),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final data = _graphData[groupIndex];
                    return BarTooltipItem(
                      "${data.customerName}\n",
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: formatAmount(data.totalFreight),
                          style: const TextStyle(color: Colors.blue),
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
