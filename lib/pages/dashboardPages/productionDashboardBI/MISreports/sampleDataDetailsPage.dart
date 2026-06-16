// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously
import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import '../../../../notificationService.dart';
import '../../ReportService.dart';
import '../../dashboard_card_ui.dart';

class MonthlySampleData {
  final String monthName;
  double noOfSamples;

  MonthlySampleData({required this.monthName, required this.noOfSamples});
}

class MonthlySampleList {
  List<MonthlySampleData> monthlyData;

  MonthlySampleList({required this.monthlyData});
}

class SampleDataPage extends StatefulWidget {
  const SampleDataPage({super.key});

  @override
  State<SampleDataPage> createState() => _SampleDataPageState();
}

class _SampleDataPageState extends State<SampleDataPage> {
  DateTime? selectedDate = DateTime.now();
  final reportService = ReportService();
  DateTime? currentDate;
  DateTime? fiscalYearStartDate;
  DateTime? lastMonthFromDate;
  bool chartDataLoaded = false;
  String? formattedFiscalYearStartDate;
  String? formattedDateNow;
  late Future<void> loadDataFuture;
  List<SampleRequest> sampleData = [];
  List<SampleRequest> sampleDataTemp = [];
  MonthlySampleList monthlySampleList = MonthlySampleList(monthlyData: []);

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
  }

  String formatDateForReport(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';

    try {
      return DateFormat(
        'dd/MM/yyyy',
      ).format(DateFormat('M/d/yyyy h:mm:ss a').parse(dateStr));
    } catch (_) {
      try {
        return DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr));
      } catch (_) {
        return dateStr;
      }
    }
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
    lastMonthFromDate = DateTime(
      fiscalYearStartDate!.year,
      fiscalYearStartDate!.month - 1,
      1,
    );
    formattedFiscalYearStartDate = DateFormat(
      'dd/MM/yy',
    ).format(fiscalYearStartDate!);
    formattedDateNow = DateFormat('dd/MM/yy').format(currentDate!);
  }

  SideTitles get _leftTitles => SideTitles(
    reservedSize: 50,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String leftDouble = "";
      leftDouble = value.toInt().toString();
      return Text(leftDouble, style: const TextStyle(fontSize: 12));
    },
  );

  SideTitles get _emptyTitlesTop =>
      SideTitles(showTitles: true, getTitlesWidget: getEmptyTopTitle);

  Widget getEmptyTopTitle(double val, TitleMeta meta) {
    return const Text("");
  }

  SideTitles get _bottomTitlesMonthlySamples => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      if (value.toInt() >= 0 &&
          value.toInt() < monthlySampleList.monthlyData.length) {
        List<MonthlySampleData> mData = monthlySampleList.monthlyData;
        text = mData.elementAt(value.toInt()).monthName;
      }
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

  List<BarChartGroupData> _MonthlySampleChartData(
    List<MonthlySampleData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.noOfSamples,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
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

  Future<void> _loadSamples(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<SampleRequest> tmpSampleList = [];
    try {
      do {
        var body = {
          "FromDate": formatDate(fiscalYearStartDate!),
          "ToDate": formatDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}CRMSampleList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<SampleRequest> newSampleList =
                (responseJson['responseData'] as List)
                    .map((item) => SampleRequest.fromJson(item))
                    .toList();

            tmpSampleList.addAll(newSampleList);
            fetchedCount = newSampleList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        sampleData = tmpSampleList;
        sampleDataTemp = tmpSampleList;
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading samples.",
      );
    }
  }

  Future<void> _processMonthlySampleData() async {
    var sList = sampleData;

    Map<int, double> monthCounts = {for (var i = 1; i <= 12; i++) i: 0.0};

    final formatSlashes = DateFormat('MM/dd/yyyy h:mm:ss a');
    final formatHyphens = DateFormat('dd-MM-yyyy HH:mm:ss');

    for (var sample in sList) {
      String? dateStr = sample.dispatchedDate;

      if (dateStr.trim().isEmpty) {
        continue;
      }

      DateTime? dispatchedDate;

      try {
        dispatchedDate = formatSlashes.parse(dateStr);
      } catch (_) {
        try {
          dispatchedDate = formatHyphens.parse(dateStr);
        } catch (e) {
          if (kDebugMode) {
            print('Date Parsing Error for "$dateStr": $e');
          }
        }
      }

      if (dispatchedDate != null) {
        int month = dispatchedDate.month;
        if (monthCounts.containsKey(month)) {
          monthCounts[month] = monthCounts[month]! + 1.0;
        }
      }
    }

    List<MonthlySampleData> finalMonthlyList = [];

    String getMonthAbbr(int month) {
      return DateFormat('MMM').format(DateTime(2024, month, 1));
    }

    List<int> fiscalMonthOrder = [4, 5, 6, 7, 8, 9, 10, 11, 12, 1, 2, 3];

    for (int month in fiscalMonthOrder) {
      double count = monthCounts[month] ?? 0.0;
      if (count >= 0) {
        finalMonthlyList.add(
          MonthlySampleData(monthName: getMonthAbbr(month), noOfSamples: count),
        );
      }
    }

    final localList = MonthlySampleList(monthlyData: finalMonthlyList);
    monthlySampleList = localList;
    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;

    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadSamples(userName, userLevel);
    await _processMonthlySampleData();
  }

  Future<void> generateSampleReportExcel(BuildContext context) async {
    final headers = [
      "Document Number",
      "Sample Req. No.",
      "SRF. Date",
      "Customer Exp. DOD.",
      "Dispatch Date",
      "Name of the Hospital",
      "Counter Type",
      "Place / HQ",
      "Distributor Name",
      "Sample Delivery to Address",
      "Marketing Rep",
      "Marketing Manager",
      "Product",
      "Ref. No.",
      "Product Category",
      "Design Type",
      "Unit",
      "Request Qty",
      "Price after Discount",
      "Row Total",
      "Priority",
      "Delivery Status",
      "Dispatched Date",
      "LR Details",
      "Remarks",
    ];
    await reportService.generateExcel(
      sheetName: 'SamplesDispatchReport',
      headers: headers,
      rows: sampleData
          .map(
            (sample) => [
              sample.documentNo,
              sample.sampleReqNo,
              formatDateForReport(sample.srfDate),
              formatDateForReport(sample.customerExpDOD),
              formatDateForReport(sample.dispatchedDate),
              sample.nameoftheHospital,
              sample.counterType,
              sample.placeHQ,
              sample.distributorName,
              sample.sampleDeliverytoAddress,
              sample.marketingRep,
              sample.marketingManager,
              sample.product,
              sample.refNo,
              sample.productCategory,
              sample.designType,
              sample.uom,
              sample.requestQty,
              sample.price,
              sample.rowTotal,
              sample.priority,
              sample.deliveryStatus,
              formatDateForReport(sample.dispatchedDate),
              sample.lrDetails,
              sample.remarks,
            ],
          )
          .toList(),
      fileName: 'sample_dispatch_report.xlsx',
      amountColumns: [18, 19, 20],
      addTotalRow: true,
      reportTitle: 'Production[MIS] - Sample Dispatch Details',
    );
  }

  double getMaxValue(double maxValue, double divVal) {
    return (maxValue / divVal).ceil() * divVal;
  }

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    selectedDate = DateTime.now();
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
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Monthly Sample Dispatch Report.',
                    spacing: 10,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateSampleReportExcel(context);
                        },
                        child: const Text("Download Excel"),
                      ),
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _monthlySamplesGraph(),
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

  Widget _monthlySamplesGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = monthlySampleList.monthlyData.length;
    if (len > 5) {
      chartWidth = screenWidth + (40 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? monthlySampleList.monthlyData
              .map((data) => data.noOfSamples)
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
              maxY: getMaxValue(maxAmount, 50),
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
                  sideTitles: _bottomTitlesMonthlySamples,
                  axisNameSize: 20,
                ),
              ),
              gridData: FlGridData(
                show: true,
                checkToShowHorizontalLine: (value) => value % 5 == 0,
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
              barGroups: _MonthlySampleChartData(monthlySampleList.monthlyData),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    // Handle touches if needed
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
                      monthlySampleList.monthlyData[grpIndex].monthName,
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "\nTotal Samples: ${monthlySampleList.monthlyData[grpIndex].noOfSamples.toInt()}",
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
