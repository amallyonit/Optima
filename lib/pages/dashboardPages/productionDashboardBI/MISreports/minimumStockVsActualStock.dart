// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously
import 'package:optima/excel_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart' as xl;
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

import 'package:optima/pages/dashboardPages/excel_helper_web.dart';

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

List<InventoryLevelList> inventoryLevel = [];
List<InventoryLevelList> inventoryLevelTemp = [];

WarehouseInventoryList warehouseLocationList = WarehouseInventoryList(
  warehouseData: [],
);

class StockStatusListMISProvider with ChangeNotifier {
  List<InventoryLevelList> _salesList = [];
  List<InventoryLevelList> get salesList => _salesList;
  void updateInventoryLevelList(List<InventoryLevelList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class MinimumStockVsActualStockPage extends StatefulWidget {
  const MinimumStockVsActualStockPage({super.key});

  @override
  State<MinimumStockVsActualStockPage> createState() =>
      _MinimumStockVsActualStockPageState();
}

class _MinimumStockVsActualStockPageState
    extends State<MinimumStockVsActualStockPage> {
  void LoadAllQuarterFromToDates() {
    DateTime now = DateTime.now();

    // Determine the financial year start
    int financialYearStart = (now.month >= 4) ? now.year : now.year - 1;

    // Define quarters
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

  SideTitles get _bottomTitlesWarehouseLocationInventory => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<WarehouseInventoryData> mData = warehouseLocationList.warehouseData;
      text = mData.elementAt(value.toInt()).warehouseName;
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

  List<BarChartGroupData> _warehouseLocationInventoryChartData(
    List<WarehouseInventoryData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.quantity,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  Future<void> _loadInventoryLevel(String UserName, String UserLevel) async {
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
        context.read<StockStatusListMISProvider>().updateInventoryLevelList(
          salesList,
        );

        inventoryLevel = salesList.toList();
        inventoryLevelTemp = salesList.toList();
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

  Future<void> _loadWarehouseLocationWiseInventory() async {
    var inventoryList = inventoryLevel;
    String warehouseCode = "";
    String warehouseName = "";
    List<WarehouseInventoryData> warehouseData = [];
    Set<String> processedWarehouseCodes = {};

    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) {
        final cleaned = v.replaceAll(',', '').trim();
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    for (var warehouse in inventoryList) {
      if (!processedWarehouseCodes.contains(warehouse.warehouseCode)) {
        warehouseCode = warehouse.warehouseCode;
        warehouseName = warehouse.warehouseName;

        double productSales = 0.0;

        double targetMinimumStockValue = 0.0;
        double actualMinimumStockValue = 0.0;
        double stockValueOtherThanMinValue = 0.0;

        for (var target in inventoryList.where(
          (prdelement) => prdelement.warehouseCode == warehouseCode,
        )) {
          final double minInv = toDouble(target.minInventory);
          final double qty = toDouble(target.quantity);

          productSales += minInv;

          if (minInv > targetMinimumStockValue) {
            targetMinimumStockValue = minInv;
          }

          if (minInv == 0.0) {
            stockValueOtherThanMinValue += qty;
          } else {
            actualMinimumStockValue += qty;
          }
        }

        final double excessValue =
            actualMinimumStockValue - targetMinimumStockValue;
        final double totalStockValue =
            stockValueOtherThanMinValue + actualMinimumStockValue;
        final double targetVsActualValuePercent = targetMinimumStockValue == 0.0
            ? 0.0
            : (totalStockValue / targetMinimumStockValue) * 100.0;

        warehouseData.add(
          WarehouseInventoryData(
            warehouseCode: warehouseCode,
            warehouseName: warehouseName,
            quantity: productSales,
            targetMinimumStockValue: targetMinimumStockValue,
            actualMinimumStockValue: actualMinimumStockValue,
            excessValue: excessValue,
            stockValueOtherThanMinValue: stockValueOtherThanMinValue,
            totalStockValue: totalStockValue,
            targetVsActualValuePercent: targetVsActualValuePercent,
          ),
        );

        processedWarehouseCodes.add(warehouse.warehouseCode);
      }
      warehouseCode = "";
      warehouseName = "";
    }

    warehouseData.sort((a, b) => b.quantity.compareTo(a.quantity));

    warehouseLocationList = WarehouseInventoryList(
      warehouseData: warehouseData,
    );
    chartDataLoaded = true;
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadInventoryLevel(userName, userLevel);
    await _loadWarehouseLocationWiseInventory();
    chartDataLoaded = true;
  }

  Future<void> loadDataWithBranchFilter(String branch) async {
    chartDataLoaded = false;
    inventoryLevel = inventoryLevelTemp;
    inventoryLevel = inventoryLevel
        .where((test) => test.warehouseName == branch)
        .toList();
    await _loadWarehouseLocationWiseInventory();

    setState(() {});
  }

  Future<void> loadDataClearFilter() async {
    chartDataLoaded = false;
    inventoryLevel = inventoryLevelTemp;
    await _loadWarehouseLocationWiseInventory();

    setState(() {});
  }

  Future<void> generateMinStockVsActualStock(BuildContext context) async {
    try {
      final excel = xl.Excel.createExcel();

      final sheet = excel['Minimum Stock with Actual Stock'];
      try {
        if (excel.sheets.containsKey('Sheet1')) {
          excel.delete('Sheet1');
        }
      } catch (_) {}

      sheet.appendRow(
        toCellRow([
          'FINISHED GOODS MINIMUM STOCK TARGET WITH ACTUAL STOCK',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
        ]),
      );

      sheet.appendRow(toCellRow([])); // spacer

      final headers = [
        'Branch',
        'Target Minimum stock value',
        'Actual minimum stock value',
        'Excess/Short stock value',
        'Stock value other than minimum stock',
        'Total stock value',
        'Target vs Actual stock %',
      ];
      sheet.appendRow(toCellRow(headers));

      for (var data in warehouseLocationList.warehouseData) {
        sheet.appendRow(
          toCellRow([
            data.warehouseName,
            data.targetMinimumStockValue,
            data.actualMinimumStockValue,
            data.excessValue,
            data.stockValueOtherThanMinValue,
            data.totalStockValue,
            data.targetVsActualValuePercent,
          ]),
        );
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('manpower_report.xlsx', excelBytes);
      } else {
        final storageDir = await getStorageDirectory();
        final file = File('$storageDir/manpower_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error exporting Excel: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
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
                          "Finished Goods Minimum Stock\nwith Actual Stock",
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
                                    generateMinStockVsActualStock(context);
                                  });
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
                  padding: const EdgeInsets.all(12.0),
                  child: BranchPicker(
                    production: inventoryLevel,
                    onChanged: (b) {
                      if (b != null) {
                        loadDataWithBranchFilter(b);
                      }
                    },
                    onClear: () {
                      loadDataClearFilter();
                    },
                  ),
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
                                          "Target : 1,53,46,256",
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
                            const SizedBox(width: 30),
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
                                          "Target : 1,53,46,256",
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
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _warehouseLocationWiseInventory(),
                ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  Widget _warehouseLocationWiseInventory() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = warehouseLocationList.warehouseData.length;
    if (warehouseLocationList.warehouseData.length > 5) {
      chartWidth = screenWidth + (50 * len);
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
                sideTitles: _bottomTitlesWarehouseLocationInventory,
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
            barGroups: _warehouseLocationInventoryChartData(
              warehouseLocationList.warehouseData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      // touchedWarehouseLocation = touchedWarehouseLocation == ""
                      //     ? warehouseLocationList
                      //     .warehouseData[
                      // barTouchResponse.spot!.spot.x.toInt()]
                      //     .warehouseName
                      //     : "";
                      // selectedChart = barTouchResponse.spot!.spot.x;
                      // showDrillDownChart = true;
                      // loadDataWithFilter(
                      //   touchedAging,
                      //   touchedWarehouseLocation,
                      //   touchedItemGroup,
                      //   touchedItemSubGroup,
                      // );
                    }
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
                    warehouseLocationList.warehouseData[grpIndex].warehouseName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\nTarget Min.Stock : ${formatAmount(warehouseLocationList.warehouseData[grpIndex].targetMinimumStockValue ?? 0)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nMinimum Stock: ${formatAmount(warehouseLocationList.warehouseData[grpIndex].actualMinimumStockValue ?? 0)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nDifference: ${formatAmount(warehouseLocationList.warehouseData[grpIndex].excessValue ?? 0)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nStock value other\nthan minimum stock: ${formatAmount(warehouseLocationList.warehouseData[grpIndex].stockValueOtherThanMinValue ?? 0)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nTotal Stock Value: ${formatAmount(warehouseLocationList.warehouseData[grpIndex].totalStockValue ?? 0)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nTarget vs Actual stock %: ${formatAmount(warehouseLocationList.warehouseData[grpIndex].targetVsActualValuePercent ?? 0)}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
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

class BranchPicker extends StatefulWidget {
  final List<InventoryLevelList> production;
  final ValueChanged<String?>? onChanged;
  final VoidCallback? onClear; // called when the cross is pressed
  final VoidCallback? onSearchPressed; // optional override for search button
  final String title;

  const BranchPicker({
    super.key,
    required this.production,
    this.onChanged,
    this.onClear,
    this.onSearchPressed,
    this.title = 'Manpower Costing Report',
  });

  @override
  State<BranchPicker> createState() => _BranchPickerState();
}

class _BranchPickerState extends State<BranchPicker> {
  late final List<String> _branches;
  String? _selectedBranch;

  @override
  void initState() {
    super.initState();
    _branches = _extractBranches(widget.production);
    _selectedBranch = null; // show "Select Branch" hint initially
  }

  List<String> _extractBranches(List<InventoryLevelList> list) {
    final s = list
        .map((p) => (p.warehouseName).toString())
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList();
    s.sort((a, b) => a.compareTo(b));
    return s;
  }

  // Default search behavior: open a simple dialog to pick branch
  Future<void> _defaultOpenSearchDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        String filter = '';
        return StatefulBuilder(
          builder: (c, setStateDialog) {
            final filtered = _branches
                .where((b) => b.toLowerCase().contains(filter.toLowerCase()))
                .toList();
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: 320,
                height: 420,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search branches',
                          isDense: true,
                        ),
                        onChanged: (v) => setStateDialog(() => filter = v),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No branches found'))
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final b = filtered[i];
                                return ListTile(
                                  title: Text(b),
                                  onTap: () => Navigator.of(context).pop(b),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _selectedBranch = result);
      widget.onChanged?.call(result);
    }
  }

  void _onSearchPressed() {
    if (widget.onSearchPressed != null) {
      widget.onSearchPressed!();
    } else {
      _defaultOpenSearchDialog();
    }
  }

  void _onClearPressed() {
    setState(() => _selectedBranch = null);
    // call both onChanged (with null) and onClear if provided
    widget.onChanged?.call(null);
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(6.0);
    final borderSide = BorderSide(color: Colors.grey.shade300, width: 1.0);

    // Build the circular icon widget (search or clear) shown inside the field
    Widget buildCircularAction() {
      final bool hasSelection = _selectedBranch != null;
      final icon = hasSelection ? Icons.close : Icons.search;
      final onPressed = hasSelection ? _onClearPressed : _onSearchPressed;
      final iconColor = hasSelection ? Colors.black54 : Colors.blueAccent;
      final borderColor = hasSelection
          ? Colors.grey.shade300
          : Colors.blueAccent;

      return Container(
        margin: const EdgeInsets.only(right: 8),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          splashRadius: 18,
          icon: Icon(icon, size: 18, color: iconColor),
          onPressed: _branches.isEmpty ? null : onPressed,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top title row (like your screenshot)
        // Row(
        //   children: [
        //     Expanded(
        //       child: Text(
        //         widget.title,
        //         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        //       ),
        //     ),
        //   ],
        // ),
        const SizedBox(height: 8),
        // Wrap field and circular icon in a row so the icon appears inside-right visually.
        // We use Expanded for the Dropdown so it fills available space.
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedBranch,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                decoration: InputDecoration(
                  hintText: null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(borderRadius: borderRadius),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: borderSide,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  // Put a small right padding to avoid overlap with our manual circular icon
                  // (suffixIcon could be used but this approach gives consistent circular look)
                ),
                hint: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Branch',
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ),
                items: _branches
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedBranch = val);
                  widget.onChanged?.call(val);
                },
              ),
            ),

            // small spacing between field and circular icon
            const SizedBox(width: 8),

            // the circular search/clear icon
            buildCircularAction(),
          ],
        ),
      ],
    );
  }
}
