// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously
import 'package:optima/excel_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:excel/excel.dart' as xl;
import '../../platform_excel_helper.dart';

late Future<void> loadDataFuture;

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

List<InventoryLevelList> stockData = [];
List<InventoryLevelList> stockDataTemp = [];

double targetStockHeader = 0;
double actualStockHeader = 0;
double differenceStockHeader = 0;

StockItemList stockStatementData = StockItemList(stockData: []);

class SummOfRawMaterialMISProvider with ChangeNotifier {
  List<InventoryLevelList> _salesList = [];
  List<InventoryLevelList> get salesList => _salesList;
  void updateInventoryLevelList(List<InventoryLevelList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class SummaryOfRawMaterials extends StatefulWidget {
  const SummaryOfRawMaterials({super.key});

  @override
  State<SummaryOfRawMaterials> createState() => _SummaryOfRawMaterialsState();
}

class _SummaryOfRawMaterialsState extends State<SummaryOfRawMaterials> {
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

  Widget getEmptyTopTitle(double val, TitleMeta meta) {
    return const Text("");
  }

  Future<void> _loadStockStatement(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000; // Maximum limit to fetch all data
    int fetchedCount = 0;
    List<InventoryLevelList> salesList = [];
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
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            // HttpHeaders.authorizationHeader:
            //     'Bearer    ${DataManager.readSapToken()}'
          },
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<InventoryLevelList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => InventoryLevelList.fromJson(item))
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
        context.read<SummOfRawMaterialMISProvider>().updateInventoryLevelList(
          salesList,
        );

        stockData = salesList.toList();
        stockDataTemp = salesList.toList();
      });
      // var currentMonthSales = inventory.where((target) {
      //   DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
      //
      //   return invoiceDate.isAtLeast(currentMonthFromDate!) &&
      //       invoiceDate.isAtMost(currentDate!);
      // });

      // double salesAmt = 0;
      // for (var target in currentMonthSales.toList()) {
      //   if (target.invoiceType != "Sales Return") {
      //     salesAmt = double.tryParse(target.rowTotal) ?? 0;
      //   } else {
      //     salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
      //   }
      //   sum += salesAmt;
      // }

      // CurrentMonthSales = sum;
      // CurrentMonthSalesStr =
      // "${(CurrentMonthSales / 100000).toStringAsFixed(2)} L";
      // if (CurrentMonthSales == 0) {
      //   CurrentMonthSalesPercentage = 0;
      // } else {
      //   CurrentMonthSalesPercentage = double.tryParse(
      //       ((CurrentMonthSales / SalesGoal) * 100).toStringAsFixed(0))
      //       ?.ceil() ??
      //       0;
      // }
      // CurrentMonthSalesPercentageStr =
      // "${CurrentMonthSalesPercentage.toString()} %";
      //
      // if (CurrentMonthSalesPercentage > 100) {
      //   CurrentMonthSalesPercentage = 100;
      // }

      // var lastMonthSales = sales.where((target) {
      //   DateTime invoiceDate =
      //   DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
      //
      //   return invoiceDate.isAtLeast(lastMonthFromDate!) &&
      //       invoiceDate.isAtMost(lastMonthToDate!);
      // });

      // sum = 0;
      // salesAmt = 0;
      // for (var target in lastMonthSales.toList()) {
      //   if (target.invoiceType != "Sales Return") {
      //     salesAmt = double.tryParse(target.rowTotal) ?? 0;
      //   } else {
      //     salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
      //   }
      //   sum += salesAmt;
      // }

      // LastMonthSales = sum;
      // LastMonthSalesStr = "${(LastMonthSales / 100000).toStringAsFixed(2)} L";
      // if (LastMonthSales == 0) {
      //   LastMonthPercentage = 0;
      // } else {
      //   LastMonthPercentage = double.tryParse(
      //       ((LastMonthSales / LastMonthTarget) * 100)
      //           .toStringAsFixed(2))
      //       ?.ceil() ??
      //       0;
      // }
      // LastMonthPercentageStr = "${LastMonthPercentage.toString()} %";
      // if (LastMonthPercentage > 100) {
      //   LastMonthPercentage = 100;
      // }
      //
      // var curQtrSales = sales.where((target) {
      //   DateTime invoiceDate =
      //   DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
      //   return invoiceDate.isAtLeast(currentQuarterFromDate!) &&
      //       invoiceDate.isAtMost(currentQuarterToDate!);
      // });

      // sum = 0;
      // salesAmt = 0;
      // for (var target in curQtrSales.toList()) {
      //   if (target.invoiceType != "Sales Return") {
      //     salesAmt = double.tryParse(target.rowTotal) ?? 0;
      //   } else {
      //     salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
      //   }
      //   sum += salesAmt;
      // }

      // CurrentQtrSales = sum;
      // CurrentQtrSalesStr = "${(CurrentQtrSales / 100000).toStringAsFixed(2)} L";
      // if (CurrentQtrSales == 0) {
      //   CurrentQtrPercentage = 0;
      // } else {
      //   CurrentQtrPercentage = double.tryParse(
      //       ((CurrentQtrSales / CurrentQtrTarget) * 100)
      //           .toStringAsFixed(2))
      //       ?.ceil() ??
      //       0;
      // }
      // CurrentQtrPercentageStr = "${CurrentQtrPercentage.toString()} %";
      // if (CurrentQtrPercentage > 100) {
      //   CurrentQtrPercentage = 100;
      // }
      //
      // var ytdSales = sales.where((target) {
      //   DateTime invoiceDate =
      //   DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
      //   return invoiceDate.isAtLeast(fiscalYearStartDate!) &&
      //       invoiceDate.isAtMost(currentDate!);
      // });
      //
      // sum = 0;
      // salesAmt = 0;
      // for (var target in ytdSales.toList()) {
      //   if (target.invoiceType != "Sales Return") {
      //     salesAmt = double.tryParse(target.rowTotal) ?? 0;
      //   } else {
      //     salesAmt = (double.tryParse(target.rowTotal) ?? 0) * -1;
      //   }
      //   sum += salesAmt;
      // }
      //
      // YtdSales = sum;
      // YtdSalesStr = "${(YtdSales / 100000).toStringAsFixed(2)} L";
      // if (YtdSales == 0) {
      //   YtdPercentage = 0;
      // } else {
      //   YtdPercentage =
      //       double.tryParse(((YtdSales / YtdTarget) * 100).toStringAsFixed(2))
      //           ?.ceil() ??
      //           0;
      // }
      // YtdPercentageStr = "${YtdPercentage.toString()} %";
      //
      // if (YtdPercentage > 100) {
      //   YtdPercentage = 100;
      // }zs
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

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadStockStatement(userName, userLevel);
    chartDataLoaded = true;
  }

  Future<void> loadDataWithBranchFilter(String branch) async {
    chartDataLoaded = false;
    stockData = stockDataTemp;
    stockData = stockData
        .where((test) => test.warehouseName == branch)
        .toList();

    setState(() {});
  }

  Future<void> loadDataClearFilter() async {
    chartDataLoaded = false;
    stockData = stockDataTemp;

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

  String _formatIndian(double value) {
    try {
      final formatter = NumberFormat('#,##,##0.00', 'en_IN');
      return formatter.format(value);
    } catch (_) {
      final negative = value < 0;
      final absVal = value.abs();
      final rupee = absVal.floor();
      final paise = ((absVal - rupee) * 100).round().toString().padLeft(2, '0');

      String intPart = rupee.toString();
      if (intPart.length <= 3) {
        final result = '$intPart.$paise';
        return negative ? '-$result' : result;
      }

      final last3 = intPart.substring(intPart.length - 3);
      String rest = intPart.substring(0, intPart.length - 3);

      final parts = <String>[];
      while (rest.length > 2) {
        parts.insert(0, rest.substring(rest.length - 2));
        rest = rest.substring(0, rest.length - 2);
      }
      if (rest.isNotEmpty) parts.insert(0, rest);

      final formattedInt = '${parts.join(',')},$last3';
      final result = '$formattedInt.$paise';
      return negative ? '-$result' : result;
    }
  }

  Future<void> generateStockStatementExcel(
    BuildContext context,
    StockItemList stockStatementData,
  ) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Stock Statement'];

      try {
        if (excel.sheets.containsKey('Sheet1')) {
          excel.delete('Sheet1');
        }
      } catch (_) {}

      sheet.appendRow(toCellRow(['', 'Jan-25', '', 'Grand Total', '', '']));
      sheet.appendRow(
        toCellRow([
          'SL NO',
          'Row Labels',
          'Target',
          'Actual stock',
          'Difference',
        ]),
      );

      double totalTarget = 0.0;
      double totalActual = 0.0;
      double totalDiff = 0.0;
      int slNo = 1;

      for (final item in stockStatementData.stockData) {
        totalTarget += item.targetStock;
        totalActual += item.actualStock;
        totalDiff += item.difference;

        final targetStr = _formatIndian(item.targetStock);
        final actualStr = _formatIndian(item.actualStock);
        final diffStr = _formatIndian(item.difference);

        sheet.appendRow(
          toCellRow([
            slNo.toString(),
            item.itemSubGroup,
            targetStr,
            actualStr,
            diffStr,
          ]),
        );

        slNo++;
      }

      sheet.appendRow(toCellRow([]));
      sheet.appendRow(
        toCellRow([
          '',
          'Grand Total',
          _formatIndian(totalTarget),
          _formatIndian(totalActual),
          _formatIndian(totalDiff),
        ]),
      );

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('stock_statement.xlsx', excelBytes);
      } else {
        final storageDir = await getStorageDirectory();
        final file = File('$storageDir/stock_statement.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error exporting Excel: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  void initState() {
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
                    const Row(
                      children: [
                        // IconButton(
                        //     onPressed: () {
                        //       showPopupMenu();
                        //     },
                        //     icon: const Icon(Icons.filter_alt_outlined)),
                        SizedBox(width: 5),
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
                          "Summary of Raw Materials",
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
                                  setState(() {
                                    generateStockStatementExcel(
                                      context,
                                      stockStatementData,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    // generateMonthlyProductionPDF(monthData);
                                  });
                                },
                                child: const Text("Download PDF"),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4.0,
                                right: 4.0,
                              ),
                              child: CircularPercentIndicator(
                                arcType: ArcType.HALF,
                                radius: 70.0,
                                lineWidth: 27.0,
                                animation: true,
                                percent: 88 / 100,
                                curve: Curves.linear,
                                circularStrokeCap: CircularStrokeCap.butt,
                                progressColor: const Color(0xFF2CA9DF),
                                arcBackgroundColor: const Color(0xFFB8ECFF),
                                center: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "88%",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.0,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "7,50,000",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 10.0,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Produced Qty",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 10.0,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF97D7F3),
                            border: Border.all(color: Colors.transparent),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Average Stock Value (Sales):\n${formatAmount(targetStockHeader)}',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF97D7F3),
                            border: Border.all(color: Colors.transparent),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stock value against average \nstock value${formatAmount(actualStockHeader)}',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF97D7F3),
                            border: Border.all(color: Colors.transparent),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Excess/shortage stock holding against\naverage stock target:${formatAmount(targetStockHeader)}',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF97D7F3),
                            border: Border.all(color: Colors.transparent),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stock other than the average\nsales stock: ${formatAmount(actualStockHeader)}',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF97D7F3),
                            border: Border.all(color: Colors.transparent),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total RM Stock :${formatAmount(targetStockHeader)}',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF97D7F3),
                            border: Border.all(color: Colors.transparent),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Excess stock against\naverage sales value: ${formatAmount(actualStockHeader)}',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
