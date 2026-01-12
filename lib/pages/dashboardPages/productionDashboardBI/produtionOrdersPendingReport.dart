// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference
import 'package:optima/excel_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/classes/leads.dart';
import 'package:optima/pages/dashboardPages/platform_excel_helper.dart';
import 'package:optima/pages/dashboardPages/platform_pdf_helper.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;
import 'package:open_file/open_file.dart';

class ProductionOrdersPendingReport extends StatefulWidget {
  const ProductionOrdersPendingReport({super.key});

  @override
  State<ProductionOrdersPendingReport> createState() =>
      _ProductionOrdersPendingReportState();
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

DailyOrderQtyAnalysisList dailyData = DailyOrderQtyAnalysisList(dailyData: []);
HospitalWiseAnalysisList hospitalData = HospitalWiseAnalysisList(
  hospitalData: [],
);
ProductWiseAnalysisList productData = ProductWiseAnalysisList(productData: []);
PriorityWiseAnalysisList priorityList = PriorityWiseAnalysisList(
  priorityData: [],
);

List<SODetailsList> pendingProduction = [];
List<PendingOrderList> pendingOrders = [];
List<Users> usersList = [];

double orderedQtyHeader = 0;
double pendingQtyHeader = 0;
double dispatchedQtyHeader = 0;

bool chartDataLoaded = false;
String touchedDay = "";
String touchedItem = "";
String touchedHospital = "";

class ProductionOrderSPendingReportProvider with ChangeNotifier {
  List<SODetailsList> _soList = [];
  List<SODetailsList> get soList => _soList;
  void updateSalesOrder(List<SODetailsList> newSalesOrderList) {
    _soList = newSalesOrderList;
    notifyListeners();
  }
}

class PendingOrderExcelProvider with ChangeNotifier {
  List<PendingOrderList> _soList = [];
  List<PendingOrderList> get soList => _soList;
  void updateSalesOrder(List<PendingOrderList> newSalesOrderList) {
    _soList = newSalesOrderList;
    notifyListeners();
  }
}

class _ProductionOrdersPendingReportState
    extends State<ProductionOrdersPendingReport> {
  bool touchedMonthGoals = false;
  bool touchedQuarterGoals = false;
  bool touchedYTDGoals = false;
  bool showDrillDownChart = false;
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

  SideTitles get _bottomTitlesDailyOrderQtyAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<DailyOrderQtyAnalysisData> mData = dailyData.dailyData;
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

  SideTitles get _bottomTitlesHospitalWiseAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<HospitalWiseAnalysisData> mData = hospitalData.hospitalData;
      text = mData.elementAt(value.toInt()).hospitalName;
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

  SideTitles get _bottomTitlesProductWiseQtyAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<ProductWiseAnalysisData> mData = productData.productData;
      text = mData.elementAt(value.toInt()).productName;
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

  List<PieChartSectionData> showingSections() {
    final List<PieChartSectionData> sections = [];
    for (final categoryData in priorityList.priorityData) {
      final fontSize = touchedIndex >= 1 ? 12.0 : 11.0;
      final radius = touchedIndex >= 1 ? 80.0 : 75.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      final sectionData = PieChartSectionData(
        color: getCategoryColor(categoryData.priorityId),
        value: categoryData.priorityPercentage,
        title: '${categoryData.priorityPercentage.toStringAsFixed(2)} %',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          color: Colors.black,
          shadows: shadows,
        ),
      );
      sections.add(sectionData);
    }
    return sections;
  }

  List<BarChartGroupData> _dailyOrderQtyChartData(
    List<DailyOrderQtyAnalysisData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: chartData.orderedQty,
                  show: true,
                  color: const Color(0xFFFF9F47),
                ),
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.dispatchedQty,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _hospitalWiseAnalysisChartData(
    List<HospitalWiseAnalysisData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: chartData.orderedQty,
                  show: true,
                  color: const Color(0xFFFF9F47),
                ),
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.dispatchedQty,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _productWiseQtyAnalysisChartData(
    List<ProductWiseAnalysisData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  toY: chartData.orderedQty,
                  show: true,
                  color: const Color(0xFFFF9F47),
                ),
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.dispatchedQty,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  Future<void> _loadPendingProductionOrders(
    String UserName,
    String UserLevel,
  ) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<SODetailsList> soDetailList = [];
    try {
      do {
        var body = {
          "FromDate": formatDate(fiscalYearStartDate!),
          "ToDate": formatDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}CRM_SOList';
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
            List<SODetailsList> newSODetailDataList =
                (responseJson['responseData'] as List)
                    .map((item) => SODetailsList.fromJson(item))
                    .toList();

            soDetailList.addAll(newSODetailDataList);
            fetchedCount = newSODetailDataList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        context.read<ProductionOrderSPendingReportProvider>().updateSalesOrder(
          soDetailList,
        );
        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();
        menuNames.insert(0, UserName);
        if (int.parse(UserLevel) == 5) {
          pendingProduction = soDetailList.toList();
        } else if (int.parse(UserLevel) == 4) {
          pendingProduction = soDetailList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          pendingProduction = soDetailList.toList();
        } else {
          pendingProduction = soDetailList.toList();
        }

        var productSalesList = pendingProduction.where((target) {
          DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
          return invoiceDate.isAtLeast(fiscalYearStartDate!) &&
              invoiceDate.isAtMost(currentDate!);
        });

        double orderedQty = 0;
        double dispatchedQty = 0;
        double pendingQty = 0;
        double orderedQtyTotal = 0;
        double dispatchedQtyTotal = 0;
        double pendingQtyTotal = 0;
        for (var val in productSalesList.toList()) {
          orderedQty = double.tryParse(val.orderQuantity) ?? 0;
          dispatchedQty = double.tryParse(val.dispatchQuantity) ?? 0;
          pendingQty = double.tryParse(val.pendingQuantity) ?? 0;
          orderedQtyTotal += orderedQty;
          dispatchedQtyTotal += dispatchedQty;
          pendingQtyTotal += pendingQty;
        }
        orderedQtyHeader = orderedQtyTotal;
        dispatchedQtyHeader = dispatchedQtyTotal;
        pendingQtyHeader = pendingQtyTotal;
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

  Future<void> _loadPendingOrdersExcel(
    String UserName,
    String UserLevel,
  ) async {
    int limit = 10000;
    int fetchedCount = 0;
    List<PendingOrderList> soDetailList = [];
    try {
      do {
        var body = {"WareHouse": "BANGALWH"};
        const apiUrl = '${ApiHelper.baseUrl}GetProductionOrderPending';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["productionOrderPendingList"]
              .toString()
              .isNotEmpty) {
            List<PendingOrderList> newSODetailDataList =
                (responseJson['productionOrderPendingList'] as List)
                    .map((item) => PendingOrderList.fromJson(item))
                    .toList();
            soDetailList.addAll(newSODetailDataList);
            fetchedCount = newSODetailDataList.length;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        context.read<PendingOrderExcelProvider>().updateSalesOrder(
          soDetailList,
        );
        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();
        menuNames.insert(0, UserName);
        if (int.parse(UserLevel) == 5) {
          pendingOrders = soDetailList.toList();
        } else if (int.parse(UserLevel) == 4) {
          pendingOrders = soDetailList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          pendingOrders = soDetailList.toList();
        } else {
          pendingOrders = soDetailList.toList();
        }
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

  Future<void> _loadDailyOrderQtyAnalysis() async {
    List<DailyOrderQtyAnalysisData> dataList = [];
    String date = "";
    double dispatchedQty = 0;
    double orderedQty = 0;
    double pendingQty = 0;
    Map<String, DateTime> monthDates = getMonthStartEndDates(
      DateTime.now().month,
    );
    var todayTarget = pendingProduction.where((target) {
      DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.poDate);
      return dueon.isAtLeast(monthDates['start']!) &&
          dueon.isAtMost(monthDates['end']!);
    });
    Set<String> processedDates = {};
    for (var target in todayTarget.toList()) {
      if (!processedDates.contains(target.poDate)) {
        String poDate = target.poDate;
        date = poDate;
        double ordered = double.tryParse(target.orderQuantity) ?? 0;
        orderedQty += ordered;
        double dispatched = double.tryParse(target.dispatchQuantity) ?? 0;
        dispatchedQty += dispatched;
        double pending = double.tryParse(target.pendingQuantity) ?? 0;
        pendingQty += pending;
        dataList.add(
          DailyOrderQtyAnalysisData(
            date: date,
            orderedQty: orderedQty,
            dispatchedQty: dispatchedQty,
            pendingQty: pendingQty,
          ),
        );
        processedDates.add(target.poDate);
      }
    }
    date = "";
    orderedQty = 0;
    dispatchedQty = 0;
    pendingQty = 0;
    dailyData = DailyOrderQtyAnalysisList(dailyData: dataList);
  }

  Future<void> _loadHospitalWiseAnalysis(
    String selectedDay,
    String hospitalCode,
    String itemCode,
  ) async {
    List<HospitalWiseAnalysisData> productwiseDataList = [];
    Map<String, HospitalWiseAnalysisData> hospitalDataMap = {};
    // ignore: prefer_typing_uninitialized_variables
    var productSalesList;
    if (selectedDay == "") {
      Map<String, DateTime> monthDates = getMonthStartEndDates(
        DateTime.now().month,
      );
      productSalesList = pendingProduction.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return (invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!));
      });
    } else {
      productSalesList = pendingProduction.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return (invoiceDate.isAtLeast(
              DateFormat('dd/MM/yyyy').parse(selectedDay),
            ) &&
            invoiceDate.isAtMost(DateFormat('dd/MM/yyyy').parse(selectedDay)));
      });
    }
    productSalesList = filterProductionList(
      productSalesList.cast<SODetailsList>().toList(),
      itemCode: itemCode,
      hospitalCode: hospitalCode,
    );

    for (var product in productSalesList) {
      String hospitalName = product.customerName;
      double orderQty = double.tryParse(product.orderQuantity) ?? 0;
      double dispatchQty = double.tryParse(product.dispatchQuantity) ?? 0;
      double pendingQty = double.tryParse(product.pendingQuantity) ?? 0;

      if (hospitalDataMap.containsKey(hospitalName)) {
        var existingData = hospitalDataMap[hospitalName]!;

        hospitalDataMap[hospitalName] = HospitalWiseAnalysisData(
          hospitalName: existingData.hospitalName,
          orderedQty: existingData.orderedQty + orderQty,
          dispatchedQty: existingData.dispatchedQty + dispatchQty,
          pendingQty: existingData.pendingQty + pendingQty,
        );
      } else {
        hospitalDataMap[hospitalName] = HospitalWiseAnalysisData(
          hospitalName: hospitalName,
          orderedQty: orderQty,
          dispatchedQty: dispatchQty,
          pendingQty: pendingQty,
        );
      }
    }

    productwiseDataList = hospitalDataMap.values.toList();
    productwiseDataList.sort((a, b) => b.orderedQty.compareTo(a.orderedQty));

    hospitalData = HospitalWiseAnalysisList(hospitalData: productwiseDataList);
  }

  Future<void> _loadProductWiseAnalysis(
    String selectedDay,
    String hospitalCode,
    String itemCode,
  ) async {
    List<ProductWiseAnalysisData> productwiseDataList = [];
    Map<String, ProductWiseAnalysisData> productDataMap = {};

    // ignore: prefer_typing_uninitialized_variables
    var productSalesList;
    if (selectedDay == "") {
      Map<String, DateTime> monthDates = getMonthStartEndDates(
        DateTime.now().month,
      );
      productSalesList = pendingProduction.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return (invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!));
      });
    } else {
      productSalesList = pendingProduction.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return (invoiceDate.isAtLeast(
              DateFormat('dd/MM/yyyy').parse(selectedDay),
            ) &&
            invoiceDate.isAtMost(DateFormat('dd/MM/yyyy').parse(selectedDay)));
      });
    }

    productSalesList = filterProductionList(
      productSalesList.cast<SODetailsList>().toList(),
      itemCode: itemCode,
      hospitalCode: hospitalCode,
    );

    for (var product in productSalesList) {
      String productName = product.productName;
      double orderQty = double.tryParse(product.orderQuantity) ?? 0;
      double dispatchQty = double.tryParse(product.dispatchQuantity) ?? 0;
      double pendingQty = double.tryParse(product.pendingQuantity) ?? 0;

      if (productDataMap.containsKey(productName)) {
        var existingData = productDataMap[productName]!;

        productDataMap[productName] = ProductWiseAnalysisData(
          productName: existingData.productName,
          orderedQty: existingData.orderedQty + orderQty,
          dispatchedQty: existingData.dispatchedQty + dispatchQty,
          pendingQty: existingData.pendingQty + pendingQty,
        );
      } else {
        productDataMap[productName] = ProductWiseAnalysisData(
          productName: productName,
          orderedQty: orderQty,
          dispatchedQty: dispatchQty,
          pendingQty: pendingQty,
        );
      }
    }

    productwiseDataList = productDataMap.values.toList();
    productwiseDataList.sort((a, b) => b.orderedQty.compareTo(a.orderedQty));

    productData = ProductWiseAnalysisList(productData: productwiseDataList);
  }

  Future<void> _loadPriorityWiseAnalysis(
    String selectedDay,
    String hospitalCode,
    String itemCode,
  ) async {
    List<PriorityWiseAnalysisData> statusList = [];
    Map<String, PriorityWiseAnalysisData> priorityDataMap = {};

    // ignore: prefer_typing_uninitialized_variables
    var productSalesList;
    if (selectedDay == "") {
      Map<String, DateTime> monthDates = getMonthStartEndDates(
        DateTime.now().month,
      );
      productSalesList = pendingProduction.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return (invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!));
      });
    } else {
      productSalesList = pendingProduction.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return (invoiceDate.isAtLeast(
              DateFormat('dd/MM/yyyy').parse(selectedDay),
            ) &&
            invoiceDate.isAtMost(DateFormat('dd/MM/yyyy').parse(selectedDay)));
      });
    }

    productSalesList = filterProductionList(
      productSalesList.cast<SODetailsList>().toList(),
      itemCode: itemCode,
      hospitalCode: hospitalCode,
    );

    int categoryId = 0;
    for (var product in productSalesList) {
      String statusName = product.priority;
      double salesAmt = double.tryParse(product.orderQuantity) ?? 0;

      if (priorityDataMap.containsKey(statusName)) {
        var existingData = priorityDataMap[statusName]!;
        priorityDataMap[statusName] = PriorityWiseAnalysisData(
          priorityId: existingData.priorityId,
          priorityQty: existingData.priorityQty + salesAmt,
          priorityName: existingData.priorityName,
          priorityPercentage: 0,
        );
      } else {
        priorityDataMap[statusName] = PriorityWiseAnalysisData(
          priorityId: categoryId++,
          priorityQty: salesAmt,
          priorityName: statusName,
          priorityPercentage: 0,
        );
      }
    }

    statusList = priorityDataMap.values.toList();

    double totalAmount = statusList.fold(
      0,
      (previousValue, element) => previousValue + element.priorityQty,
    );

    for (var categoryData in statusList) {
      categoryData.priorityPercentage =
          double.tryParse(
            ((categoryData.priorityQty / totalAmount) * 100).toStringAsFixed(2),
          ) ??
          0;
      categoryData.priorityQty =
          double.tryParse(
            (categoryData.priorityQty / 100000).toStringAsFixed(2),
          ) ??
          0;
    }

    priorityList = PriorityWiseAnalysisList(priorityData: statusList);
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadPendingProductionOrders(userName, userLevel);
    await _loadPendingOrdersExcel(userName, userLevel);
    await _loadDailyOrderQtyAnalysis();
    await _loadHospitalWiseAnalysis("", "", "");
    await _loadProductWiseAnalysis("", "", "");
    await _loadPriorityWiseAnalysis("", "", "");
    chartDataLoaded = true;
  }

  List<SODetailsList> filterProductionList(
    List<SODetailsList> productionList, {
    String? selectedDay,
    String? hospitalCode,
    String? itemCode,
  }) {
    List<SODetailsList> filteredProductionList = [];
    for (var production in productionList) {
      if ((itemCode == null ||
              itemCode.isEmpty ||
              production.productName == itemCode) &&
          (hospitalCode == null ||
              hospitalCode.isEmpty ||
              production.customerName == hospitalCode)) {
        filteredProductionList.add(production);
      }
    }
    return filteredProductionList;
  }

  Future<void> removeFilter() async {
    touchedDay = "";
    touchedItem = "";
    touchedHospital = "";

    touchedMonthGoals = false;
    touchedQuarterGoals = false;
    touchedYTDGoals = false;
    clearVariables();
    LoadDates();
    await _loadHospitalWiseAnalysis("", "", "");
    await _loadProductWiseAnalysis("", "", "");
    await _loadPriorityWiseAnalysis("", "", "");
    chartDataLoaded = true;
  }

  Future<void> loadDataWithFilter(
    String selectedDay,
    String hospitalCode,
    String itemCode,
  ) async {
    clearVariablesForFilter();
    LoadDates();
    await _loadHospitalWiseAnalysis(selectedDay, hospitalCode, itemCode);
    await _loadProductWiseAnalysis(selectedDay, hospitalCode, itemCode);
    await _loadPriorityWiseAnalysis(selectedDay, hospitalCode, itemCode);
    chartDataLoaded = true;
  }

  void clearVariables() {
    setState(() {
      chartDataLoaded = false;
      hospitalData = HospitalWiseAnalysisList(hospitalData: []);
      productData = ProductWiseAnalysisList(productData: []);
      priorityList = PriorityWiseAnalysisList(priorityData: []);
      touchedDay = "";
      touchedItem = "";
      touchedHospital = "";
    });
  }

  void clearVariablesForFilter() {
    setState(() {
      chartDataLoaded = false;
      hospitalData = HospitalWiseAnalysisList(hospitalData: []);
      productData = ProductWiseAnalysisList(productData: []);
      priorityList = PriorityWiseAnalysisList(priorityData: []);
    });
  }

  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  Future<void> generateDailyOrderExcel(
    DailyOrderQtyAnalysisList dailyOrderQtyAnalysisList,
  ) async {
    double totalOrderedQty = 0, totalDispatchedQty = 0, totalPendingQty = 0;
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow(['Date', 'Ordered Qty.', 'Dispatched Qty.', 'Pending Qty.']),
      );
      for (var dailyData in dailyOrderQtyAnalysisList.dailyData) {
        sheet.appendRow(
          toCellRow([
            dailyData.date,
            dailyData.orderedQty,
            dailyData.dispatchedQty,
            dailyData.pendingQty,
          ]),
        );
        totalOrderedQty += dailyData.orderedQty;
        totalDispatchedQty += dailyData.dispatchedQty;
        totalPendingQty += dailyData.pendingQty;
      }
      sheet.appendRow(
        toCellRow([
          "Total",
          totalOrderedQty,
          totalDispatchedQty,
          totalPendingQty,
        ]),
      );

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('daily_order_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/daily_order_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateDailyOrderPDF(
    DailyOrderQtyAnalysisList dailyOrderQtyAnalysisList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Daily Order Report',
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
                      'Date',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Ordered Qty.',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Dispatched Qty.',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Pending Qty.',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var dailyData in dailyOrderQtyAnalysisList.dailyData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        dailyData.date,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        dailyData.orderedQty.toStringAsFixed(2),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        dailyData.dispatchedQty.toStringAsFixed(2),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        dailyData.pendingQty.toStringAsFixed(2),
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
        final file = File('$storageDir/daily_order_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateHospitalwiseOrderExcel(
    HospitalWiseAnalysisList hospitalWiseAnalysisList,
  ) async {
    double totalOrderedQty = 0, totalDispatchedQty = 0, totalPendingQty = 0;
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'Hospital Name',
          'Ordered Qty.',
          'Dispatched Qty.',
          'Pending Qty.',
        ]),
      );
      for (var data in hospitalWiseAnalysisList.hospitalData) {
        sheet.appendRow(
          toCellRow([
            data.hospitalName,
            data.orderedQty,
            data.dispatchedQty,
            data.pendingQty,
          ]),
        );
        totalOrderedQty += data.orderedQty;
        totalDispatchedQty += data.dispatchedQty;
        totalPendingQty += data.pendingQty;
      }
      sheet.appendRow(
        toCellRow([
          "Total",
          totalOrderedQty,
          totalDispatchedQty,
          totalPendingQty,
        ]),
      );

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('hospitalwise_order_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/hospitalwise_order_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateHospitalwiseOrderPDF(
    HospitalWiseAnalysisList hospitalWiseAnalysisList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Hospitalwise Order Report',
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
                      'Hospital Name',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Ordered Qty.',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Dispatched Qty.',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Pending Qty.',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var data in hospitalWiseAnalysisList.hospitalData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        data.hospitalName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.orderedQty.toStringAsFixed(2),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.dispatchedQty.toStringAsFixed(2),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.pendingQty.toStringAsFixed(2),
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
        final file = File('$storageDir/hospital_order_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateProductwiseOrderExcel(
    ProductWiseAnalysisList productWiseAnalysisList,
  ) async {
    double totalOrderedQty = 0, totalDispatchedQty = 0, totalPendingQty = 0;
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'Product Name',
          'Ordered Qty.',
          'Dispatched Qty.',
          'Pending Qty.',
        ]),
      );
      for (var data in productWiseAnalysisList.productData) {
        sheet.appendRow(
          toCellRow([
            data.productName,
            data.orderedQty,
            data.dispatchedQty,
            data.pendingQty,
          ]),
        );
        totalOrderedQty += data.orderedQty;
        totalDispatchedQty += data.dispatchedQty;
        totalPendingQty += data.pendingQty;
      }
      sheet.appendRow(
        toCellRow([
          "Total",
          totalOrderedQty,
          totalDispatchedQty,
          totalPendingQty,
        ]),
      );

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('productwise_order_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/productwise_order_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generateProductwiseOrderPDF(
    ProductWiseAnalysisList productWiseAnalysisList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Productwise Order Report',
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
                      'Product Name',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Ordered Qty.',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Dispatched Qty.',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Pending Qty.',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var data in productWiseAnalysisList.productData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        data.productName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.orderedQty.toStringAsFixed(2),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.dispatchedQty.toStringAsFixed(2),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.pendingQty.toStringAsFixed(2),
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
        final file = File('$storageDir/product_order_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generatePrioritywiseOrderExcel(
    PriorityWiseAnalysisList priorityWiseAnalysisList,
  ) async {
    double totalPriorityQty = 0;
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(toCellRow(['Priority', 'Priority Qty.', 'Priority %']));
      for (var data in priorityWiseAnalysisList.priorityData) {
        sheet.appendRow(
          toCellRow([
            data.priorityName,
            data.priorityQty,
            data.priorityPercentage,
          ]),
        );
        totalPriorityQty += data.priorityQty;
      }
      sheet.appendRow(toCellRow(["Total", totalPriorityQty, ""]));

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('prioritywise_order_report.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/prioritywise_order_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generatePrioritywiseOrderPDF(
    PriorityWiseAnalysisList priorityWiseAnalysisList,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'Prioritywise Order Report',
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
                      'Priority',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Priority Qty.',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Priority %.',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Table data rows
                for (var data in priorityWiseAnalysisList.priorityData)
                  pw.TableRow(
                    children: [
                      pw.Text(
                        data.priorityName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.priorityQty.toStringAsFixed(2),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.Text(
                        data.priorityPercentage.toString(),
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
        final file = File('$storageDir/priority_order_report.pdf');
        await file.writeAsBytes(await pdf.save());
        OpenFile.open(file.path);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> generatePendingOrderExcel() async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow(
        toCellRow([
          'Sl.No',
          'PO No.',
          'PO Date',
          'Hospital Name',
          'ItemCode',
          'ItemName',
          'Ordered Qty',
          'Dispatched Qty',
          'BangStock',
          'RajStock',
          'Pending Qty',
          'Box Qty',
          'Item MRP',
          'Order Priority',
        ]),
      );
      for (var element in pendingOrders) {
        sheet.appendRow(
          toCellRow([
            element.SlNo,
            element.PoNo,
            element.PoDate,
            element.HospitalName,
            element.ItemCode,
            element.ItemName,
            element.OrderedQty,
            element.DespatchedQty,
            element.BangStock,
            element.RajStock,
            element.PendingQty,
            element.BoxQty,
            element.ItemMrp,
            element.OrderPriority,
          ]),
        );
        // totalOrderedQty += dailyData.orderedQty;
        // totalDispatchedQty += dailyData.dispatchedQty;
        // totalPendingQty += dailyData.pendingQty;
      }
      // sheet.appendRow(toCellRow(
      //     ["Total", totalOrderedQty, totalDispatchedQty, totalPendingQty]);

      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('pendingOrders.xlsx', excelBytes);
      } else {
        String storageDir = await getStorageDirectory();
        final file = File('$storageDir/pendingOrders.xlsx');
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF49136),
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
                                  'Total Order Quantity: ${formatAmount(orderedQtyHeader)}',
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
                                  'Dispatched Quantity: ${formatAmount(dispatchedQtyHeader)}',
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
                            color: const Color(0xFF78E25D),
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
                                  'Total Pending Quantity: ${formatAmount(pendingQtyHeader)}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2ca9df),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      onPressed: () {
                        generatePendingOrderExcel();
                      },
                      child: const SizedBox(
                        width: 400,
                        child: Center(
                          child: Text(
                            "Download Pending Orders For Production",
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
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
                          "Daily Order\nQty Analysis",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFFFF9F47),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "Ordered Qty.",
                          style: TextStyle(fontSize: 12),
                        ),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFF97D7F3),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "Dispatched Qty.",
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 5),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateDailyOrderExcel(dailyData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateDailyOrderPDF(dailyData);
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
                  child: _dailyOrderQtyAnalysis(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Priority wise Analysis",
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
                                    generatePrioritywiseOrderExcel(
                                      priorityList,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generatePrioritywiseOrderPDF(priorityList);
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
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        height: 250,
                        width: 100,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback:
                                  (FlTouchEvent event, pieTouchResponse) {},
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 1,
                            centerSpaceRadius: 0,
                            startDegreeOffset: 180,
                            sections: showingSections(),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // for (final categoryData in receivablesCategoryList.categoryData)
                                Column(
                                  children: [
                                    Container(
                                      height: 8,
                                      width: 16,
                                      color: const Color(0xFF78E25D),
                                      // color: getCategoryColor(categoryData.categoryId),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 8,
                                      width: 16,
                                      color: const Color(0xFF97D7F3),
                                      // color: getCategoryColor(categoryData.categoryId),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 8,
                                      width: 16,
                                      color: const Color(0xFFFF9F47),
                                      // color: getCategoryColor(categoryData.categoryId),
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // for (final categoryData
                              // in receivablesCategoryList.categoryData)
                              Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Text(
                                  "Low",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Text(
                                  "Medium",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Text(
                                  "High",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Hospital Wise\nAnalysis",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFFFF9F47),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "Ordered Qty.",
                          style: TextStyle(fontSize: 12),
                        ),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFF97D7F3),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "Dispatched Qty.",
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 5),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateHospitalwiseOrderExcel(
                                      hospitalData,
                                    );
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateHospitalwiseOrderPDF(hospitalData);
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
                  child: _hospitalWiseAnalysis(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15),
                        Text(
                          "Product Wise\nQty Analysis",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFFFF9F47),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "Ordered Qty.",
                          style: TextStyle(fontSize: 12),
                        ),
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFF97D7F3),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "Dispatched Qty.",
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 5),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateProductwiseOrderExcel(productData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateProductwiseOrderPDF(productData);
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
                  child: _productWiseQtyAnalysis(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
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

  Widget _dailyOrderQtyAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = dailyData.dailyData.length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxValue = len > 0
        ? dailyData.dailyData
              .map(
                (data) => data.orderedQty > data.dispatchedQty
                    ? data.orderedQty
                    : data.dispatchedQty,
              ) // Compare salesAmount and monthsAvg
              .reduce((a, b) => a > b ? a : b) // Find the max value
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(maxValue),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesDailyOrderQtyAnalysis,
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
            barGroups: _dailyOrderQtyChartData(dailyData.dailyData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedDay = touchedDay == ""
                          ? dailyData
                                .dailyData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .date
                          : "";
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedDay,
                        touchedHospital,
                        touchedItem,
                      );
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
                    "${dailyData.dailyData[grpIndex].date}\n",
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Ordered Qty: ${formatAmount(dailyData.dailyData[grpIndex].orderedQty)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Dispatched Qty: ${formatAmount(dailyData.dailyData[grpIndex].dispatchedQty)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Pending Qty: ${formatAmount(dailyData.dailyData[grpIndex].pendingQty)}",
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

  Widget _hospitalWiseAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = hospitalData.hospitalData.length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxValue = len > 0
        ? hospitalData.hospitalData
              .map(
                (data) => data.orderedQty > data.dispatchedQty
                    ? data.orderedQty
                    : data.dispatchedQty,
              ) // Compare salesAmount and monthsAvg
              .reduce((a, b) => a > b ? a : b) // Find the max value
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(maxValue),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesHospitalWiseAnalysis,
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
            barGroups: _hospitalWiseAnalysisChartData(
              hospitalData.hospitalData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedHospital = touchedHospital == ""
                          ? hospitalData
                                .hospitalData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .hospitalName
                          : "";
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedDay,
                        touchedHospital,
                        touchedItem,
                      );
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
                    "${hospitalData.hospitalData[grpIndex].hospitalName}\n",
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Ordered Qty: ${formatAmount(hospitalData.hospitalData[grpIndex].orderedQty)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Dispatched Qty: ${formatAmount(hospitalData.hospitalData[grpIndex].dispatchedQty)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Pending Qty: ${formatAmount(hospitalData.hospitalData[grpIndex].pendingQty)}\n",
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

  Widget _productWiseQtyAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = productData.productData.length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxValue = len > 0
        ? productData.productData
              .map(
                (data) => data.orderedQty > data.dispatchedQty
                    ? data.orderedQty
                    : data.dispatchedQty,
              ) // Compare salesAmount and monthsAvg
              .reduce((a, b) => a > b ? a : b) // Find the max value
        : 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: getMaxValue(maxValue),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesProductWiseQtyAnalysis,
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
            barGroups: _productWiseQtyAnalysisChartData(
              productData.productData,
            ),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
                  setState(() {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedItem = touchedItem == ""
                          ? productData
                                .productData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .productName
                          : "";
                      showDrillDownChart = true;
                      loadDataWithFilter(
                        touchedDay,
                        touchedHospital,
                        touchedItem,
                      );
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
                    '${productData.productData[grpIndex].productName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Ordered Qty : ${formatAmount(productData.productData[grpIndex].orderedQty)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Dispatched Qty : ${formatAmount(productData.productData[grpIndex].dispatchedQty)}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Pending Qty : ${formatAmount(productData.productData[grpIndex].pendingQty)}",
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
