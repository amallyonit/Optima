// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference
import 'package:optima/excel_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/classes/leads.dart';
import '../../../classes/dashBoard.dart';

import 'package:optima/pages/dashboardPages/excel_helper_web.dart';

import 'package:excel/excel.dart' as xl;
import 'package:open_file/open_file.dart';

class DayWiseProductionReportwrtMPPresent extends StatefulWidget {
  const DayWiseProductionReportwrtMPPresent({super.key});

  @override
  State<DayWiseProductionReportwrtMPPresent> createState() =>
      _DayWiseProductionReportwrtMPPresentState();
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

bool chartDataLoaded = false;

List<ProductionOrderList> dayWiseProductionMP = [];
List<Users> usersList = [];

DailyCompletedQtyDayWisewrtMPList dailyData = DailyCompletedQtyDayWisewrtMPList(
  dailyData: [],
);

class DayWiseProductionwrtMPProvider with ChangeNotifier {
  List<ProductionOrderList> _salesList = [];
  List<ProductionOrderList> get salesList => _salesList;
  void updatePurchaseList(List<ProductionOrderList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class _DayWiseProductionReportwrtMPPresentState
    extends State<DayWiseProductionReportwrtMPPresent> {
  bool touchedMonthGoals = false;
  bool touchedQuarterGoals = false;
  bool touchedYTDGoals = false;

  int touchedIndex = -1;

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

  Map<String, DateTime> getMonthStartEndDates(int month) {
    DateTime now = DateTime.now();

    int currentYear = now.year;

    // Determine the correct year for the given month
    int yearForMonth;
    if (now.month >= 1 && now.month <= 3) {
      // If the call is happening in Jan–Mar
      yearForMonth = (month >= 4 && month <= 12)
          ? currentYear - 1
          : currentYear;
    } else {
      // If the call is happening in Apr–Dec
      yearForMonth = (month >= 4 && month <= 12)
          ? currentYear
          : currentYear + 1;
    }

    // Calculate the first and last days of the given month
    DateTime firstDayOfMonth = DateTime(yearForMonth, month, 1);
    DateTime lastDayOfMonth = DateTime(yearForMonth, month + 1, 0);

    return {'start': firstDayOfMonth, 'end': lastDayOfMonth};
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

  SideTitles get _bottomTitlesDailyCompletedQtyAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<DailyCompletedQtyDayWisewrtMPData> mData = dailyData.dailyData;
      text = mData.elementAt(value.toInt()).date;
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

  List<BarChartGroupData> _dailyCompletedQtyAnalysisChartData(
    List<DailyCompletedQtyDayWisewrtMPData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: chartData.wrapSheetQty,
                  show: true,
                  color: const Color(0xFF97D7F3),
                ),
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.gownQty,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  Future<void> _loadProductionOrderAnalysis(
    String UserName,
    String UserLevel,
  ) async {
    int index = 0;
    int limit = 10000; // Maximum limit to fetch all data
    int fetchedCount = 0;
    List<ProductionOrderList> salesList = [];
    int monthIndex = DateTime.now().month;
    try {
      do {
        var body = {
          "FromDate": formatDate(
            monthIndex == 4 ? lastMonthFromDate! : fiscalYearStartDate!,
          ),
          "ToDate": formatDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}BicxoProductionAnalysis';
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
            List<ProductionOrderList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => ProductionOrderList.fromJson(item))
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
        dayWiseProductionMP = salesList;
        context.read<DayWiseProductionwrtMPProvider>().updatePurchaseList(
          salesList,
        );
        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();
        menuNames.insert(0, UserName);
        if (int.parse(UserLevel) == 5) {
          dayWiseProductionMP = salesList.toList();
        } else if (int.parse(UserLevel) == 4) {
          dayWiseProductionMP = salesList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          dayWiseProductionMP = salesList.toList();
        } else {
          dayWiseProductionMP = salesList.toList();
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> _loadDailyCompletedQtyAnalysis() async {
    List<DailyCompletedQtyDayWisewrtMPData> dataList = [];
    Map<String, DateTime> monthDates = getMonthStartEndDates(
      DateTime.now().month,
    );

    Set<String> processedDates = {};

    var todayTarget = dayWiseProductionMP.where((target) {
      try {
        if (target.soDate.isEmpty) {
          return false;
        }

        DateTime dueOn = DateFormat('dd/MM/yyyy').parseStrict(target.soDate);
        return dueOn.isAtLeast(monthDates['start']!) &&
            dueOn.isAtMost(monthDates['end']!);
      } catch (e) {
        return false;
      }
    }).toList();

    for (var target in todayTarget) {
      if (processedDates.contains(target.soDate)) continue;

      double gownQty = 0;
      double wrapSheetQty = 0;
      todayTarget.where((t) => t.soDate == target.soDate).forEach((t) {
        if (t.itemSubGroup == "Gowns") {
          gownQty += double.tryParse(t.completedQty) ?? 0;
        } else if (t.itemSubGroup == "Drapes") {
          gownQty += double.tryParse(t.completedQty) ?? 0;
        } else if (t.itemSubGroup == "Packs") {
          gownQty += double.tryParse(t.completedQty) ?? 0;
        } else if (t.itemSubGroup == "Safety Packs") {
          gownQty += double.tryParse(t.completedQty) ?? 0;
        } else if (t.itemSubGroup == "Wrap Sheet") {
          wrapSheetQty += double.tryParse(t.completedQty) ?? 0;
        }
      });

      dataList.add(
        DailyCompletedQtyDayWisewrtMPData(
          date: target.soDate,
          gownQty: gownQty,
          wrapSheetQty: wrapSheetQty,
        ),
      );
      gownQty = 0;
      wrapSheetQty = 0;

      processedDates.add(target.soDate);
    }
    dataList.sort((a, b) => a.date.compareTo(b.date));
    dailyData = DailyCompletedQtyDayWisewrtMPList(dailyData: dataList);
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadProductionOrderAnalysis(userName, userLevel);
    await _loadDailyCompletedQtyAnalysis();
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

  Future<void> generateDailyMPOrderExcel(
    DailyCompletedQtyDayWisewrtMPList dailyCompletedQtyDayWisewrtMPList,
  ) async {
    double totalGownQty = 0, totalWrapsheetQty = 0;
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Date', 'Kits/Gown Qty.', 'Wrapsheet Qty.']));
      for (var dailyData in dailyCompletedQtyDayWisewrtMPList.dailyData) {
        sheet.appendRow(
          toCellRow([
            dailyData.date,
            dailyData.gownQty,
            dailyData.wrapSheetQty,
          ]),
        );
        totalGownQty += dailyData.gownQty;
        totalWrapsheetQty += dailyData.wrapSheetQty;
      }
      sheet.appendRow(toCellRow(["Total", totalGownQty, totalWrapsheetQty]));

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('daily_MP_order_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/daily_MP_order_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Daily Completed \nQty Analysis",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 8,
                                width: 8,
                                color: const Color(0xFFFF9F47),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                "Kits/Gowns",
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(width: 5),
                          Row(
                            children: [
                              Container(
                                height: 8,
                                width: 8,
                                color: const Color(0xFF97D7F3),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                "Wrap Sheet",
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _dailyCompletedQtyAnalysis(),
                ),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2ca9df),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        generateDailyMPOrderExcel(dailyData);
                      });
                    },
                    child: const SizedBox(
                      width: 400,
                      child: Center(
                        child: Text(
                          "Download Reports",
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
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

  Widget _dailyCompletedQtyAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = dailyData.dailyData.length;
    if (len > 5) {
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
            // maxY: getAgingMaxValue(receivablesAgingList),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesDailyCompletedQtyAnalysis,
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
            barGroups: _dailyCompletedQtyAnalysisChartData(dailyData.dailyData),
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
                    '${dailyData.dailyData[grpIndex].date}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Kits/Gown Qty : ${formatAmount(dailyData.dailyData[grpIndex].gownQty)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Wrap Sheet Qty : ${formatAmount(dailyData.dailyData[grpIndex].wrapSheetQty)}",
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
