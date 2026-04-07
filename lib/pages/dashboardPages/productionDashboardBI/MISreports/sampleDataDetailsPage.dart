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
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:excel/excel.dart' as xl;

import 'package:optima/pages/dashboardPages/excel_helper_web.dart';

late Future<void> loadDataFuture;

class MonthlySampleData {
  final String monthName;
  double noOfSamples;

  MonthlySampleData({required this.monthName, required this.noOfSamples});
}

class MonthlySampleList {
  List<MonthlySampleData> monthlyData;

  MonthlySampleList({required this.monthlyData});
}

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

int CurrentMonthSalesPercentage = 0;
String CurrentMonthSalesPercentageStr = "";
String CurrentMonthSalesStr = "";
String SalesGoalStr = "";
int LastMonthPercentage = 0;
String LastMonthPercentageStr = "";
double LastMonthSales = 0;
String LastMonthSalesStr = "";
double LastMonthTarget = 0;
String LastMonthTargetStr = "";
double CurrentQtrSales = 0;
String CurrentQtrSalesStr = "";
double CurrentQtrTarget = 0;
String CurrentQtrTargetStr = "";
int CurrentQtrPercentage = 0;
String CurrentQtrPercentageStr = "";
int YtdPercentage = 0;
String YtdPercentageStr = "";
double YtdSales = 0;
String YtdSalesStr = "";
double YtdTarget = 0;
String YtdTargetStr = "";
double CurrentMonthTarget = 0;
String CurrentMonthTargetStr = "";
int CurrentMonthPercentage = 0;
double Q1Sales = 0;
double Q1Target = 0;
double Q1Diff = 0;
int Q1Percentage = 0;
String Q1SalesStr = "";
String Q1TargetStr = "";
String Q1DiffStr = "";
String Q1PercentageStr = "";
double Q2Sales = 0;
double Q2Target = 0;
double Q2Diff = 0;
int Q2Percentage = 0;
String Q2SalesStr = "";
String Q2TargetStr = "";
String Q2DiffStr = "";
String Q2PercentageStr = "";
double Q3Sales = 0;
double Q3Target = 0;
double Q3Diff = 0;
int Q3Percentage = 0;
String Q3SalesStr = "";
String Q3TargetStr = "";
String Q3DiffStr = "";
String Q3PercentageStr = "";
double Q4Sales = 0;
double Q4Target = 0;
double Q4Diff = 0;
int Q4Percentage = 0;
String Q4SalesStr = "";
String Q4TargetStr = "";
String Q4DiffStr = "";
String Q4PercentageStr = "";
double Q1Average = 0;
String Q1AverageStr = "";
double Q2Average = 0;
String Q2AverageStr = "";
double Q3Average = 0;
String Q3AverageStr = "";
double Q4Average = 0;
String Q4AverageStr = "";
DateTime? q1FromDate;
DateTime? q1ToDate;
DateTime? q2FromDate;
DateTime? q2ToDate;
DateTime? q3FromDate;
DateTime? q3ToDate;
DateTime? q4FromDate;
DateTime? q4ToDate;

bool chartDataLoaded = false;

List<SampleRequest> sampleData = [];
List<SampleRequest> sampleDataTemp = [];

StockItemList stockStatementData = StockItemList(stockData: []);

double completedOrders = 0;
double completedOrdersPercent = 0;
double completedOrdersPercentage = 0;
double pendingOrders = 0;
double pendingOrdersPercent = 0;
double pendingOrdersPercentage = 0;

MonthlySampleList monthlySampleList = MonthlySampleList(monthlyData: []);
String selectedBranch = "";

class SampleDetailsMISProvider with ChangeNotifier {
  List<SampleRequest> _salesList = [];
  List<SampleRequest> get salesList => _salesList;
  void updateInventoryLevelList(List<SampleRequest> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class SampleDataPage extends StatefulWidget {
  const SampleDataPage({super.key});

  @override
  State<SampleDataPage> createState() => _SampleDataPageState();
}

class _SampleDataPageState extends State<SampleDataPage> {
  DateTime? selectedDate = DateTime.now();

  void LoadAllQuarterFromToDates() {
    DateTime now = DateTime.now();

    int financialYearStart = (now.month >= 4) ? now.year : now.year - 1;

    q1FromDate = DateTime(financialYearStart, 4, 1);
    q1ToDate = DateTime(financialYearStart, 7, 0);

    q2FromDate = DateTime(financialYearStart, 7, 1);
    q2ToDate = DateTime(financialYearStart, 10, 0);

    q3FromDate = DateTime(financialYearStart, 10, 1);
    q3ToDate = DateTime(financialYearStart + 1, 1, 0); // December 31

    q4FromDate = DateTime(financialYearStart + 1, 1, 1);
    q4ToDate = DateTime(financialYearStart + 1, 4, 0); // March 31
  }

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
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

  int getCurrentQuarter() {
    int monthIndex = DateTime.now().month;
    switch (monthIndex) {
      case 4:
      case 5:
      case 6:
        return 1;
      case 7:
      case 8:
      case 9:
        return 2;
      case 10:
      case 11:
      case 12:
        return 3;
      case 1:
      case 2:
      case 3:
        return 4;
      default:
        throw Error();
    }
  }

  void getLastQuarterDates() {
    DateTime now = DateTime.now();
    switch (getCurrentQuarter()) {
      case 1:
        lastQuarterFromDate = DateTime(now.year, 1, 1);
        lastQuarterToDate = DateTime(now.year, 3, 31);
        break;
      case 2:
        lastQuarterFromDate = DateTime(now.year, 4, 1);
        lastQuarterToDate = DateTime(now.year, 6, 30);
        break;
      case 3:
        lastQuarterFromDate = DateTime(now.year, 7, 1);
        lastQuarterToDate = DateTime(now.year, 9, 30);
        break;
      case 4:
        lastQuarterFromDate = DateTime(now.year - 1, 10, 1);
        lastQuarterToDate = DateTime(now.year - 1, 12, 31);
        break;
      default:
        throw Error();
    }
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
    DateTime now = DateTime.now();
    switch (currentQuarter) {
      case 1:
        currentQuarterFromDate = DateTime(now.year, 4, 1);
        currentQuarterToDate = DateTime(now.year, 6, 30);
      case 2:
        currentQuarterFromDate = DateTime(now.year, 7, 1);
        currentQuarterToDate = DateTime(now.year, 9, 30);
      case 3:
        currentQuarterFromDate = DateTime(now.year, 10, 1);
        currentQuarterToDate = DateTime(now.year, 12, 31);
      case 4:
        currentQuarterFromDate = DateTime(now.year, 1, 1);
        currentQuarterToDate = DateTime(now.year, 3, 31);
      default:
        throw Error();
    }
    int fiscalYear = currentDate!.month >= fiscalYearStartMonth
        ? currentDate!.year
        : currentDate!.year - 1;
    fiscalYearStartDate = DateTime(fiscalYear, fiscalYearStartMonth, 1);
    prevFiscalYearStartDate = addMonth(fiscalYearStartDate!, -12);
    prevFiscalYearEndDate = DateTime(prevFiscalYearStartDate!.year + 1, 4, 0);
    int fiscalYearStartYear = currentDate!.month >= 4
        ? currentDate!.year
        : currentDate!.year - 1;

    int fiscalYearEndYear = fiscalYearStartYear + 1;
    financialYear =
        'FY${fiscalYearStartYear.toString().substring(2)}-${fiscalYearEndYear.toString().substring(2)}';

    int prevFiscalYearStartYear = fiscalYearStartYear - 1;
    int prevFiscalYearEndYear = prevFiscalYearStartYear + 1;
    prevFinancialYear =
        'FY${prevFiscalYearStartYear.toString().substring(2)}-${prevFiscalYearEndYear.toString().substring(2)}';
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
    List<SampleRequest> salesList = [];
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
            List<SampleRequest> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => SampleRequest.fromJson(item))
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

      setState(() {
        context.read<SampleDetailsMISProvider>().updateInventoryLevelList(
          salesList,
        );

        sampleData = salesList.toList();
        sampleDataTemp = salesList.toList();
      });
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Error: $e'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
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

    if (mounted) {
      setState(() {
        monthlySampleList = localList;
      });
    } else {
      monthlySampleList = localList;
    }
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;

    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadSamples(userName, userLevel);
    await _processMonthlySampleData();

    chartDataLoaded = true;
    setState(() {});
  }

  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  Future<void> generateSampleReportExcel(BuildContext context) async {
    try {
      final excel = xl.Excel.createExcel();
      // Name the sheet
      final sheet = excel['Sample_Report'];

      // Remove default 'Sheet1' if it exists and we aren't using it
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // 1. Define Headers
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

      // 2. Append Header Row
      // Using TextCellValue for compatibility with newer excel package versions
      List<xl.CellValue> headerRow = headers
          .map((h) => xl.TextCellValue(h))
          .toList();
      sheet.appendRow(headerRow);

      for (var sample in sampleData) {
        List<xl.CellValue> row = [
          xl.TextCellValue(sample.documentNo),
          xl.TextCellValue(sample.sampleReqNo),
          xl.TextCellValue(sample.srfDate),
          xl.TextCellValue(sample.customerExpDOD),
          xl.TextCellValue(sample.dispatchedDate),
          xl.TextCellValue(sample.nameoftheHospital),
          xl.TextCellValue(sample.counterType),
          xl.TextCellValue(sample.placeHQ),
          xl.TextCellValue(sample.distributorName),
          xl.TextCellValue(sample.sampleDeliverytoAddress),
          xl.TextCellValue(sample.marketingRep),
          xl.TextCellValue(sample.marketingManager),
          xl.TextCellValue(sample.product),
          xl.TextCellValue(sample.refNo),
          xl.TextCellValue(sample.productCategory),
          xl.TextCellValue(sample.designType),
          xl.TextCellValue(sample.uom),
          xl.DoubleCellValue(
            double.tryParse(sample.requestQty.toString()) ?? 0.0,
          ),
          xl.DoubleCellValue(double.tryParse(sample.price.toString()) ?? 0.0),
          xl.DoubleCellValue(
            double.tryParse(sample.rowTotal.toString()) ?? 0.0,
          ),
          xl.TextCellValue(sample.priority),
          xl.TextCellValue(sample.deliveryStatus),
          xl.TextCellValue(sample.dispatchedDate),
          xl.TextCellValue(sample.lrDetails),
          xl.TextCellValue(sample.remarks),
        ];
        sheet.appendRow(row);
      }

      if (kIsWeb) {
        final excelBytes = excel.save();
        if (excelBytes != null) {
          saveAndOpenExcel('Sample_Dispatch_Report.xlsx', excelBytes);
        }
      } else {
        final storageDir = await getStorageDirectory();
        final file = File('$storageDir/Sample_Dispatch_Report.xlsx');
        final bytes = excel.save();
        if (bytes != null) {
          await file.writeAsBytes(bytes);
          await OpenFile.open(file.path);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel generated successfully')),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error generating Excel: $e');
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating Excel: $e')));
    }
  }

  int touchedIndex = -1;

  Color getCategoryColor(int categoryId) {
    switch (categoryId) {
      case 1:
        return Colors.green;
      case 2:
        return const Color(0xFFF49136);
      case 3:
        return Colors.grey;
      case 4:
        return Colors.lightBlue;
      default:
        return const Color(0xFF6CCC3F);
    }
  }

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
  Widget build(BuildContext context) {
    String formattedFiscalYearStartDate = DateFormat(
      'dd/MM/yy',
    ).format(fiscalYearStartDate!);
    String formattedDateNow = DateFormat('dd/MM/yy').format(currentDate!);
    return chartDataLoaded == true
        ? SingleChildScrollView(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Monthly Sample Dispatch Report",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  // Call the Excel generation function here
                                  generateSampleReportExcel(context);
                                },
                                child: const Text("Download Excel"),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _monthlySamplesGraph(),
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
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
                if (barTouchResponse != null && barTouchResponse.spot != null) {
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
    );
  }
}
