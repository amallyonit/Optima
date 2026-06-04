// ignore_for_file: file_names, non_constant_identifier_names, strict_top_level_inference

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
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
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;
import 'package:optima/classes/leads.dart';

import 'package:optima/pages/dashboardPages/excel_helper_web.dart';
import 'package:optima/pages/dashboardPages/pdf_helper_web.dart';

import 'package:optima/excel_helper.dart';

import '../../../notificationService.dart';

class InventoryAgeingAnalysis extends StatefulWidget {
  const InventoryAgeingAnalysis({super.key});

  @override
  State<InventoryAgeingAnalysis> createState() =>
      _InventoryAgeingAnalysisState();
}

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

List<InventoryList> inventory = [];
List<Users> usersList = [];

ReceivablesFinanceList receivablesFinanceList = ReceivablesFinanceList(
  agingData: [],
);
InventoryAgingList inventoryAgingList = InventoryAgingList(agingData: []);

bool qtyOrValCheck = true;

class InventoryAgeingAnalysisProvider with ChangeNotifier {
  List<InventoryList> _salesList = [];
  List<InventoryList> get salesList => _salesList;
  void updateInventoryList(List<InventoryList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class _InventoryAgeingAnalysisState extends State<InventoryAgeingAnalysis> {
  bool touchedMonthGoals = false;
  bool touchedQuarterGoals = false;
  bool touchedYTDGoals = false;
  bool chartDataLoaded = false;

  int touchedIndex = -1;

  double getMaxValue(double maxValue) {
    double divVal = 0;
    if (maxValue > 1000000000) {
      divVal = 1000000000;
    } else if (maxValue >= 100000000 && maxValue <= 500000000) {
      divVal = 100000000;
    } else if (maxValue > 500000000 && maxValue <= 1000000000) {
      divVal = 250000000;
    } else if (maxValue > 10000000 && maxValue <= 100000000) {
      divVal = 10000000;
    } else if (maxValue > 1000000 && maxValue <= 10000000) {
      divVal = 1000000;
    } else if (maxValue > 100000 && maxValue <= 1000000) {
      if (maxValue <= 200000) {
        divVal = 10000;
      } else {
        if (maxValue >= 200000) {
          divVal = 20000;
        }
        if (maxValue >= 200000) {
          divVal = 30000;
        }
        if (maxValue >= 400000) {
          divVal = 40000;
        }
        if (maxValue >= 500000) {
          divVal = 50000;
        }
      }
    } else if (maxValue >= 10000 && maxValue <= 100000) {
      divVal = 10000;
    } else if (maxValue >= 100 && maxValue <= 1000) {
      divVal = 100;
    } else {
      divVal = 10;
    }
    double maxY = ((maxValue ~/ divVal) + 1) * divVal;
    return maxY;
  }

  String formatAmount(double amount) {
    if (amount >= 10000000) {
      // Amount in crores
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      // Amount in lakhs
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else {
      // Amount in thousands
      return '${(amount / 1000).toStringAsFixed(2)} K';
    }
  }

  double convertAmount(double amount) {
    if (amount >= 10000000) {
      // Amount in crores
      return double.parse((amount / 10000000).toStringAsFixed(2));
    } else if (amount >= 100000) {
      // Amount in lakhs
      return double.parse((amount / 100000).toStringAsFixed(2));
    } else {
      // Amount in thousands
      return double.parse((amount / 1000).toStringAsFixed(2));
    }
  }

  Color getCategoryColor(int categoryId) {
    switch (categoryId) {
      case 0:
        return const Color(0xFF97D7F3);
      case 1:
        return const Color(0xFFF49136);
      case 2:
        return const Color(0xFF6CCC3F);
      default:
        return const Color(0xFF6CCC3F);
    }
  }

  String formatFinanceAmount(double amount) {
    if (amount >= 1000000000) {
      return "${(amount / 1000000000).toStringAsFixed(2)} B";
    } else if (amount >= 1000000) {
      return "${(amount / 1000000).toStringAsFixed(2)} M";
    } else {
      return '${(amount / 1000).toStringAsFixed(2)} K';
    }
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

  String getMonthName(int month) {
    final formatter = DateFormat('MMMM');
    return formatter.format(DateTime(2000, month));
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

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
  }

  Future<void> removeFilter() async {}

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

  SideTitles get _bottomTitlesInventoryAgeing => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<InventoryAgingData> mData = inventoryAgingList.agingData;
      text = mData.elementAt(value.toInt()).agingGroup;
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

  List<BarChartGroupData> _inventoryAgeingChartData(
    List<InventoryAgingData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.agingTotal,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  Future<void> _loadInventory(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<InventoryList> salesList = [];
    try {
      do {
        var body = {
          // "FromDate": formatDate(monthIndex == 4 ? lastMonthFromDate! : fiscalYearStartDate!),
          // "ToDate": formatDate(currentDate!),
          "ToDate": formatDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}BicxoInventoryAgeingList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            // HttpHeaders.authorizationHeader:
            // 'Bearer    ${DataManager.readSapToken()}'
          },
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<InventoryList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => InventoryList.fromJson(item))
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
        context.read<InventoryAgeingAnalysisProvider>().updateInventoryList(
          salesList,
        );
        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();
        menuNames.insert(0, UserName);
        if (int.parse(UserLevel) == 5) {
          inventory = salesList.toList();
        } else if (int.parse(UserLevel) == 4) {
          inventory = salesList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          inventory = salesList.toList();
        } else {
          inventory = salesList.toList();
        }
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occurred while loading inventory data.",
      );
    }
  }

  InventoryAgingSummary summarizeCollectionTargets(
    Iterable<InventoryList> inventory,
  ) {
    InventoryAgingSummary summary = InventoryAgingSummary();
    String overDueDays = "";
    for (var element in inventory) {
      overDueDays = element.ageingBrackets;
      if (overDueDays == "<30 Days") {
        summary.a0to30DaysTotal += qtyOrValCheck
            ? (double.parse(element.totalQuantity))
            : (double.parse(element.totalValue));
      } else if (overDueDays == "31-45 Days") {
        summary.a31to45DaysTotal += qtyOrValCheck
            ? (double.parse(element.totalQuantity))
            : (double.parse(element.totalValue));
      } else if (overDueDays == "46-60 Days") {
        summary.a46to60DaysTotal += qtyOrValCheck
            ? (double.parse(element.totalQuantity))
            : (double.parse(element.totalValue));
      } else if (overDueDays == "61-90 Days") {
        summary.a61to90DaysTotal += qtyOrValCheck
            ? (double.parse(element.totalQuantity))
            : (double.parse(element.totalValue));
      } else if (overDueDays == "91-120 Days") {
        summary.a91to120DaysTotal += qtyOrValCheck
            ? (double.parse(element.totalQuantity))
            : (double.parse(element.totalValue));
      } else if (overDueDays == "121-150 Days") {
        summary.a121to150DaysTotal += qtyOrValCheck
            ? (double.parse(element.totalQuantity))
            : (double.parse(element.totalValue));
      } else if (overDueDays == "151-180 Days") {
        summary.a151to180DaysTotal += qtyOrValCheck
            ? (double.parse(element.totalQuantity))
            : (double.parse(element.totalValue));
      } else if (overDueDays == "181-365 Days") {
        summary.a181to365DaysTotal += qtyOrValCheck
            ? (double.parse(element.totalQuantity))
            : (double.parse(element.totalValue));
      } else if (overDueDays == "366-730 Days") {
        summary.a366to730DaysTotal += qtyOrValCheck
            ? (double.parse(element.totalQuantity))
            : (double.parse(element.totalValue));
      } else if (overDueDays == ">730 Days") {
        summary.a730DaysTotal += qtyOrValCheck
            ? (double.parse(element.totalQuantity))
            : (double.parse(element.totalValue));
      }
    }
    return summary;
  }

  Future<void> _loadInventoryAgingData() async {
    List<InventoryAgingData> receivablesAgingDataList = [];
    double agingGroup30Total = 0;
    double agingGroup31to45Total = 0;
    double agingGroup46to60Total = 0;
    double agingGroup61to90Total = 0;
    double agingGroup91to120Total = 0;
    double agingGroup121to150Total = 0;
    double agingGroup151to180Total = 0;
    double agingGroup181to365Total = 0;
    double agingGroup366to730Total = 0;
    double agingGroup730Total = 0;

    var collectionTargetList = inventory;

    InventoryAgingSummary summary = summarizeCollectionTargets(
      collectionTargetList,
    );
    agingGroup30Total = summary.a0to30DaysTotal;
    agingGroup31to45Total = summary.a31to45DaysTotal;
    agingGroup46to60Total = summary.a46to60DaysTotal;
    agingGroup61to90Total = summary.a61to90DaysTotal;
    agingGroup91to120Total = summary.a91to120DaysTotal;
    agingGroup121to150Total = summary.a121to150DaysTotal;
    agingGroup151to180Total = summary.a151to180DaysTotal;
    agingGroup181to365Total = summary.a181to365DaysTotal;
    agingGroup366to730Total = summary.a366to730DaysTotal;
    agingGroup730Total = summary.a730DaysTotal;
    receivablesAgingDataList.add(
      InventoryAgingData(agingGroup: "0-30", agingTotal: agingGroup30Total),
    );
    receivablesAgingDataList.add(
      InventoryAgingData(
        agingGroup: "31-45",
        agingTotal: agingGroup31to45Total,
      ),
    );
    receivablesAgingDataList.add(
      InventoryAgingData(
        agingGroup: "46-60",
        agingTotal: agingGroup46to60Total,
      ),
    );
    receivablesAgingDataList.add(
      InventoryAgingData(
        agingGroup: "61-90",
        agingTotal: agingGroup61to90Total,
      ),
    );
    receivablesAgingDataList.add(
      InventoryAgingData(
        agingGroup: "91-120",
        agingTotal: agingGroup91to120Total,
      ),
    );
    receivablesAgingDataList.add(
      InventoryAgingData(
        agingGroup: "121-150",
        agingTotal: agingGroup121to150Total,
      ),
    );
    receivablesAgingDataList.add(
      InventoryAgingData(
        agingGroup: "151-180",
        agingTotal: agingGroup151to180Total,
      ),
    );
    receivablesAgingDataList.add(
      InventoryAgingData(
        agingGroup: "181-365",
        agingTotal: agingGroup181to365Total,
      ),
    );
    receivablesAgingDataList.add(
      InventoryAgingData(
        agingGroup: "366-730",
        agingTotal: agingGroup366to730Total,
      ),
    );
    receivablesAgingDataList.add(
      InventoryAgingData(agingGroup: "731+", agingTotal: agingGroup730Total),
    );

    // for (InventoryAgingData agingData in receivablesAgingDataList) {
    //    agingData.agingPercentage = double.tryParse(
    //        ((agingData.agingGroupTotal / totalDueAmount) * 100)
    //            .toStringAsFixed(2)) ??
    //        0;
    //    agingData.agingGroupTotal = double.tryParse((agingData.agingGroupTotal).toStringAsFixed(2)) ?? 0;
    // }

    inventoryAgingList = InventoryAgingList(
      agingData: receivablesAgingDataList,
    );
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadInventory(userName, userLevel);
    await _loadInventoryAgingData();
    chartDataLoaded = true;
  }

  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  Future<void> generateInventoryTypeExcel(InventoryAgingList list) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Aging Group', 'Total']));
      for (var monthlyData in list.agingData) {
        sheet.appendRow(
          toCellRow([monthlyData.agingGroup, monthlyData.agingTotal]),
        );
      }

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('inventoryAgingAnalysis.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/inventoryAgingAnalysis.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occurred while generating Excel file.",
      );
    }
  }

  Future<void> generateInventoryTypePDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Inventory Aging',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Table(
              border: pw.TableBorder.all(),
              children: [
                // Table header
                pw.TableRow(
                  children: [
                    pw.Text(
                      'Type',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Qty',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var data in inventoryAgingList.agingData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        data.agingGroup,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.agingTotal.toString(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      );

      if (kIsWeb) {
        final pdfBytes = await pdf.save();
        saveAndOpenPDF(pdfBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/InventoryAging.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occurred while generating PDF file.",
      );
    }
  }

  void toggleCheckbox() {
    setState(() {
      chartDataLoaded = false;
      loadData("");
      qtyOrValCheck = !qtyOrValCheck;
    });
  }

  Future<void> loadQuantityOrValue(String selectedUser) async {
    await _loadInventoryAgingData();
    chartDataLoaded = true;
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
    String formattedQuarterStartDate = DateFormat(
      'dd/MM/yy',
    ).format(currentQuarterFromDate!);
    String formattedQuarterLastDate = DateFormat(
      'dd/MM/yy',
    ).format(currentQuarterToDate!);
    String formattedDateNow = DateFormat('dd/MM/yy').format(currentDate!);
    String formattedDateFirstOfLastMonth = DateFormat(
      'dd/MM/yy',
    ).format(DateTime(currentDate!.year, currentDate!.month - 1, 1));
    String formattedDateLastOfLastMonth = DateFormat(
      'dd/MM/yy',
    ).format(DateTime(currentDate!.year, currentDate!.month, 0));
    String formattedDateFirstOfThisMonth = DateFormat(
      'dd/MM/yy',
    ).format(DateTime(currentDate!.year, currentDate!.month, 1));
    return chartDataLoaded == true
        ? SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 15),
                        touchedMonthGoals == true
                            ? Text(
                                "$formattedDateFirstOfLastMonth - $formattedDateLastOfLastMonth",
                              )
                            : touchedQuarterGoals == true
                            ? Text(
                                "$formattedQuarterStartDate - $formattedQuarterLastDate",
                              )
                            : touchedYTDGoals == true
                            ? Text(
                                "$formattedFiscalYearStartDate - $formattedDateNow",
                              )
                            : Text(
                                "$formattedDateFirstOfThisMonth - $formattedDateNow",
                              ),
                      ],
                    ),
                    Row(
                      children: [
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
                Center(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Showing Data:"),
                      const SizedBox(width: 10),
                      const Text("Quantity"),
                      Checkbox(
                        checkColor: Colors.white,
                        value: qtyOrValCheck,
                        onChanged: (_) {
                          setState(() {});
                          toggleCheckbox();
                        },
                      ),
                      const SizedBox(width: 5),
                      const Text("Value"),
                      Checkbox(
                        checkColor: Colors.white,
                        value: !qtyOrValCheck,
                        onChanged: (_) {
                          setState(() {});
                          toggleCheckbox();
                        },
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Inventory Analysis",
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
                                    generateInventoryTypeExcel(
                                      inventoryAgingList,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateInventoryTypePDF();
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
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _inventoryAgeing(),
                ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  showPopupMenu() {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(25.0, 200.0, 0.0, 0.0),
      elevation: 8.0,
      items: [
        const PopupMenuItem<String>(value: '1', child: Text('Remove Filter?')),
      ],
    ).then((value) {
      if (value == '1') {
        setState(() {
          loadDataFuture = removeFilter();
        });
      }
    });
  }

  Widget _inventoryAgeing() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = inventoryAgingList.agingData.length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? inventoryAgingList.agingData
              .map((data) => data.agingTotal)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(maxAmount),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesInventoryAgeing,
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
            barGroups: _inventoryAgeingChartData(inventoryAgingList.agingData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
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
                    'Production Aging\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "${inventoryAgingList.agingData[0].agingGroup} : ${formatAmount(inventoryAgingList.agingData[0].agingTotal)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "${inventoryAgingList.agingData[1].agingGroup} : ${formatAmount(inventoryAgingList.agingData[1].agingTotal)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "${inventoryAgingList.agingData[2].agingGroup} : ${formatAmount(inventoryAgingList.agingData[2].agingTotal)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "${inventoryAgingList.agingData[3].agingGroup} : ${formatAmount(inventoryAgingList.agingData[3].agingTotal)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "${inventoryAgingList.agingData[4].agingGroup} : ${formatAmount(inventoryAgingList.agingData[4].agingTotal)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "${inventoryAgingList.agingData[5].agingGroup} : ${formatAmount(inventoryAgingList.agingData[5].agingTotal)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "${inventoryAgingList.agingData[6].agingGroup} : ${formatAmount(inventoryAgingList.agingData[6].agingTotal)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "${inventoryAgingList.agingData[7].agingGroup} : ${formatAmount(inventoryAgingList.agingData[7].agingTotal)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "${inventoryAgingList.agingData[8].agingGroup} : ${formatAmount(inventoryAgingList.agingData[8].agingTotal)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "${inventoryAgingList.agingData[9].agingGroup} : ${formatAmount(inventoryAgingList.agingData[9].agingTotal)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Total : ${formatAmount(inventoryAgingList.agingData[0].agingTotal + inventoryAgingList.agingData[1].agingTotal + inventoryAgingList.agingData[2].agingTotal + inventoryAgingList.agingData[3].agingTotal + inventoryAgingList.agingData[4].agingTotal + inventoryAgingList.agingData[5].agingTotal + inventoryAgingList.agingData[6].agingTotal + inventoryAgingList.agingData[7].agingTotal + inventoryAgingList.agingData[8].agingTotal + inventoryAgingList.agingData[9].agingTotal)}",
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
