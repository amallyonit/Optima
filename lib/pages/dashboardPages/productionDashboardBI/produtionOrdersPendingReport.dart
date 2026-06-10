// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/classes/leads.dart';
import '../../../notificationService.dart';
import '../ReportService.dart';
import '../dashboard_card_ui.dart';

class ProductionOrdersPendingReport extends StatefulWidget {
  const ProductionOrdersPendingReport({super.key});

  @override
  State<ProductionOrdersPendingReport> createState() =>
      _ProductionOrdersPendingReportState();
}

class _ProductionOrdersPendingReportState
    extends State<ProductionOrdersPendingReport> {
  bool touchedMonthGoals = false;
  bool touchedQuarterGoals = false;
  bool touchedYTDGoals = false;
  bool showDrillDownChart = false;
  int touchedIndex = -1;
  late Future<void> loadDataFuture;
  final reportService = ReportService();
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

  DailyOrderQtyAnalysisList dailyData = DailyOrderQtyAnalysisList(
    dailyData: [],
  );
  HospitalWiseAnalysisList hospitalData = HospitalWiseAnalysisList(
    hospitalData: [],
  );
  ProductWiseAnalysisList productData = ProductWiseAnalysisList(
    productData: [],
  );
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

  final http.Client client = http.Client();
  late String formattedFiscalYearStartDate;
  late String formattedQuarterStartDate;
  late String formattedQuarterLastDate;
  late String formattedDateNow;
  late String formattedDateFirstOfLastMonth;
  late String formattedDateLastOfLastMonth;
  late String formattedDateFirstOfThisMonth;

  double dailyMaxY = 0;
  double hospitalMaxY = 0;
  double productMaxY = 0;

  void prepareFormattedDates() {
    final formatter = DateFormat('dd/MM/yy');

    formattedFiscalYearStartDate = fiscalYearStartDate != null
        ? formatter.format(fiscalYearStartDate!)
        : '';

    formattedQuarterStartDate = currentQuarterFromDate != null
        ? formatter.format(currentQuarterFromDate!)
        : '';

    formattedQuarterLastDate = currentQuarterToDate != null
        ? formatter.format(currentQuarterToDate!)
        : '';

    formattedDateNow = currentDate != null
        ? formatter.format(currentDate!)
        : '';

    formattedDateFirstOfLastMonth = lastMonthFromDate != null
        ? formatter.format(lastMonthFromDate!)
        : '';

    formattedDateLastOfLastMonth = lastMonthToDate != null
        ? formatter.format(lastMonthToDate!)
        : '';

    formattedDateFirstOfThisMonth = currentMonthFromDate != null
        ? formatter.format(currentMonthFromDate!)
        : '';
  }

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

  void prepareMaxValues() {
    /// DAY WISE
    dailyMaxY = dailyData.dailyData.isNotEmpty
        ? dailyData.dailyData
              .map(
                (data) => data.orderedQty > data.dispatchedQty
                    ? data.orderedQty
                    : data.dispatchedQty,
              )
              .reduce((a, b) => a > b ? a : b)
        : 0;

    /// HOSPITAL WISE
    hospitalMaxY = hospitalData.hospitalData.isNotEmpty
        ? hospitalData.hospitalData
              .map(
                (data) => data.orderedQty > data.dispatchedQty
                    ? data.orderedQty
                    : data.dispatchedQty,
              )
              .reduce((a, b) => a > b ? a : b) // Find the max value
        : 0;

    /// PRODUCT WISE
    productMaxY = productData.productData.isNotEmpty
        ? productData.productData
              .map(
                (data) => data.orderedQty > data.dispatchedQty
                    ? data.orderedQty
                    : data.dispatchedQty,
              )
              .reduce((a, b) => a > b ? a : b) // Find the max value
        : 0;
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

  Color getCategoryColor(int categoryId) {
    switch (categoryId) {
      case 0:
        return const Color(0xFF6CCC3F);
      case 1:
        return const Color(0xFFF49136);
      case 2:
        return const Color(0xFF97D7F3);
      default:
        return const Color(0xFF6CCC3F);
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
        break;
      case 2:
        currentQuarterFromDate = DateTime(now.year, 7, 1);
        currentQuarterToDate = DateTime(now.year, 9, 30);
        break;
      case 3:
        currentQuarterFromDate = DateTime(now.year, 10, 1);
        currentQuarterToDate = DateTime(now.year, 12, 31);
        break;
      case 4:
        currentQuarterFromDate = DateTime(now.year, 1, 1);
        currentQuarterToDate = DateTime(now.year, 3, 31);
        break;
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

  final DateFormat appDateFormat = DateFormat('dd/MM/yyyy');
  DateTime parseAppDate(String date) {
    return appDateFormat.parse(date);
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
        value: categoryData.priorityPercentage.abs(),
        title: '${categoryData.priorityPercentage.abs().toStringAsFixed(2)} %',
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
    return List.generate(data.length, (index) {
      final chartData = data[index];

      return BarChartGroupData(
        x: index,
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
      );
    });
  }

  List<BarChartGroupData> _hospitalWiseAnalysisChartData(
    List<HospitalWiseAnalysisData> data,
  ) {
    return List.generate(data.length, (index) {
      final chartData = data[index];

      return BarChartGroupData(
        x: index,
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
      );
    });
  }

  List<BarChartGroupData> _productWiseQtyAnalysisChartData(
    List<ProductWiseAnalysisData> data,
  ) {
    return List.generate(data.length, (index) {
      final chartData = data[index];

      return BarChartGroupData(
        x: index,
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
      );
    });
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
        final response = await client.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
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
        pendingProduction = soDetailList.toList();

        var productSalesList = pendingProduction.where((target) {
          DateTime invoiceDate = parseAppDate(target.poDate);
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
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading pending production orders.",
      );
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

        final response = await client.post(
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
        pendingOrders = soDetailList.toList();
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message:
            "Error occured while loading pending production order for excel.",
      );
    }
  }

  Future<void> _loadDailyOrderQtyAnalysis() async {
    List<DailyOrderQtyAnalysisData> dailyOrderQtyDataList = [];
    Map<String, DailyOrderQtyAnalysisData> dailyOrderQtyDataMap = {};

    Map<String, DateTime> monthDates = getMonthStartEndDates(
      DateTime.now().month,
    );

    var todayTarget = pendingProduction.where((target) {
      DateTime dueon = parseAppDate(target.poDate);

      return dueon.isAtLeast(monthDates['start']!) &&
          dueon.isAtMost(monthDates['end']!);
    });

    for (var target in todayTarget) {
      final date = target.poDate;

      final ordered = double.tryParse(target.orderQuantity) ?? 0;

      final dispatched = double.tryParse(target.dispatchQuantity) ?? 0;

      final pending = double.tryParse(target.pendingQuantity) ?? 0;

      if (dailyOrderQtyDataMap.containsKey(date)) {
        final existing = dailyOrderQtyDataMap[date]!;

        dailyOrderQtyDataMap[date] = DailyOrderQtyAnalysisData(
          date: existing.date,
          orderedQty: existing.orderedQty + ordered,
          dispatchedQty: existing.dispatchedQty + dispatched,
          pendingQty: existing.pendingQty + pending,
        );
      } else {
        dailyOrderQtyDataMap[date] = DailyOrderQtyAnalysisData(
          date: date,
          orderedQty: ordered,
          dispatchedQty: dispatched,
          pendingQty: pending,
        );
      }
    }
    dailyOrderQtyDataList = dailyOrderQtyDataMap.values.toList();
    dailyOrderQtyDataList.sort((a, b) => a.date.compareTo(b.date));

    dailyData = DailyOrderQtyAnalysisList(dailyData: dailyOrderQtyDataList);
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
        DateTime invoiceDate = parseAppDate(target.poDate);
        return (invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!));
      });
    } else {
      productSalesList = pendingProduction.where((target) {
        DateTime invoiceDate = parseAppDate(target.poDate);
        return (invoiceDate.isAtLeast(
              DateFormat('dd/MM/yyyy').parse(selectedDay),
            ) &&
            invoiceDate.isAtMost(DateFormat('dd/MM/yyyy').parse(selectedDay)));
      });
    }
    productSalesList = filterProductionList(
      List<SODetailsList>.from(productSalesList),
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
        DateTime invoiceDate = parseAppDate(target.poDate);
        return (invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!));
      });
    } else {
      productSalesList = pendingProduction.where((target) {
        DateTime invoiceDate = parseAppDate(target.poDate);
        return (invoiceDate.isAtLeast(
              DateFormat('dd/MM/yyyy').parse(selectedDay),
            ) &&
            invoiceDate.isAtMost(DateFormat('dd/MM/yyyy').parse(selectedDay)));
      });
    }

    productSalesList = filterProductionList(
      List<SODetailsList>.from(productSalesList),
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
        DateTime invoiceDate = parseAppDate(target.poDate);
        return (invoiceDate.isAtLeast(monthDates['start']!) &&
            invoiceDate.isAtMost(monthDates['end']!));
      });
    } else {
      productSalesList = pendingProduction.where((target) {
        DateTime invoiceDate = parseAppDate(target.poDate);
        return (invoiceDate.isAtLeast(
              DateFormat('dd/MM/yyyy').parse(selectedDay),
            ) &&
            invoiceDate.isAtMost(DateFormat('dd/MM/yyyy').parse(selectedDay)));
      });
    }

    productSalesList = filterProductionList(
      List<SODetailsList>.from(productSalesList),
      itemCode: itemCode,
      hospitalCode: hospitalCode,
    );

    final priorityOrder = {'High': 1, 'Medium': 2, 'Low': 0};
    final sortedProducts = [...productSalesList]
      ..sort(
        (a, b) => (priorityOrder[a.priority] ?? 0).compareTo(
          priorityOrder[b.priority] ?? 0,
        ),
      );

    int categoryId = 0;
    for (var product in sortedProducts) {
      String statusName = product.priority;
      double ordQty = double.tryParse(product.orderQuantity) ?? 0;

      if (priorityDataMap.containsKey(statusName)) {
        var existingData = priorityDataMap[statusName]!;
        priorityDataMap[statusName] = PriorityWiseAnalysisData(
          priorityId: existingData.priorityId,
          priorityQty: existingData.priorityQty + ordQty,
          priorityName: existingData.priorityName,
          priorityPercentage: 0,
        );
      } else {
        priorityDataMap[statusName] = PriorityWiseAnalysisData(
          priorityId: categoryId++,
          priorityQty: ordQty,
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
    prepareMaxValues();

    if (mounted) {
      setState(() {});
    }
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
    prepareFormattedDates();
    await _loadHospitalWiseAnalysis("", "", "");
    await _loadProductWiseAnalysis("", "", "");
    await _loadPriorityWiseAnalysis("", "", "");
    chartDataLoaded = true;
    prepareMaxValues();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadDataWithFilter(
    String selectedDay,
    String hospitalCode,
    String itemCode,
  ) async {
    clearVariablesForFilter();
    LoadDates();
    prepareFormattedDates();
    await _loadHospitalWiseAnalysis(selectedDay, hospitalCode, itemCode);
    await _loadProductWiseAnalysis(selectedDay, hospitalCode, itemCode);
    await _loadPriorityWiseAnalysis(selectedDay, hospitalCode, itemCode);
    chartDataLoaded = true;
    prepareMaxValues();

    if (mounted) {
      setState(() {});
    }
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

  Future<void> generateDailyOrderExcel(
    DailyOrderQtyAnalysisList dailyOrderQtyAnalysisList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'DailyProduction',
      headers: ['Date', 'Ordered Qty.', 'Dispatched Qty.', 'Pending Qty.'],
      rows: dailyOrderQtyAnalysisList.dailyData
          .map((e) => [e.date, e.orderedQty, e.dispatchedQty, e.pendingQty])
          .toList(),
      fileName: 'daily_order_report.xlsx',
      amountColumns: [2, 3, 4],
      addTotalRow: true,
      reportTitle: 'Production - Daily Production Analysis',
    );
  }

  Future<void> generateDailyOrderPDF(
    DailyOrderQtyAnalysisList dailyOrderQtyAnalysisList,
  ) async {
    await reportService.generatePDF(
      title: 'DailyProduction',
      headers: ['Date', 'Ordered Qty.', 'Dispatched Qty.', 'Pending Qty.'],
      rows: dailyOrderQtyAnalysisList.dailyData
          .map((e) => [e.date, e.orderedQty, e.dispatchedQty, e.pendingQty])
          .toList(),
      fileName: 'daily_order_report.pdf',
      amountColumns: [2, 3, 4],
    );
  }

  Future<void> generateHospitalwiseOrderExcel(
    HospitalWiseAnalysisList hospitalWiseAnalysisList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'HospitalWiseProduction',
      headers: ['Hospital', 'Ordered Qty.', 'Dispatched Qty.', 'Pending Qty.'],
      rows: hospitalWiseAnalysisList.hospitalData
          .map(
            (e) => [
              e.hospitalName,
              e.orderedQty,
              e.dispatchedQty,
              e.pendingQty,
            ],
          )
          .toList(),
      fileName: 'hospitalwise_order_report.xlsx',
      amountColumns: [2, 3, 4],
      addTotalRow: true,
      reportTitle: 'Production - Hospital Wise Production Analysis',
    );
  }

  Future<void> generateHospitalwiseOrderPDF(
    HospitalWiseAnalysisList hospitalWiseAnalysisList,
  ) async {
    await reportService.generatePDF(
      title: 'HospitalWiseProduction',
      headers: ['Hospital', 'Ordered Qty.', 'Dispatched Qty.', 'Pending Qty.'],
      rows: hospitalWiseAnalysisList.hospitalData
          .map(
            (e) => [
              e.hospitalName,
              e.orderedQty,
              e.dispatchedQty,
              e.pendingQty,
            ],
          )
          .toList(),
      fileName: 'hospitalwise_order_report.pdf',
      amountColumns: [2, 3, 4],
    );
  }

  Future<void> generateProductwiseOrderExcel(
    ProductWiseAnalysisList productWiseAnalysisList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'ProductWiseProduction',
      headers: ['Product', 'Ordered Qty.', 'Dispatched Qty.', 'Pending Qty.'],
      rows: productWiseAnalysisList.productData
          .map(
            (e) => [e.productName, e.orderedQty, e.dispatchedQty, e.pendingQty],
          )
          .toList(),
      fileName: 'productwise_order_report.xlsx',
      amountColumns: [2, 3, 4],
      addTotalRow: true,
      reportTitle: 'Production - Product Wise Production Analysis',
    );
  }

  Future<void> generateProductwiseOrderPDF(
    ProductWiseAnalysisList productWiseAnalysisList,
  ) async {
    await reportService.generatePDF(
      title: 'ProductWiseProduction',
      headers: ['Product', 'Ordered Qty.', 'Dispatched Qty.', 'Pending Qty.'],
      rows: productWiseAnalysisList.productData
          .map(
            (e) => [e.productName, e.orderedQty, e.dispatchedQty, e.pendingQty],
          )
          .toList(),
      fileName: 'productwise_order_report.pdf',
      amountColumns: [2, 3, 4],
    );
  }

  Future<void> generatePrioritywiseOrderExcel(
    PriorityWiseAnalysisList priorityWiseAnalysisList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'PriorityWiseProduction',
      headers: ['Priority', 'Priority Qty.', 'Priority %'],
      rows: priorityWiseAnalysisList.priorityData
          .map((e) => [e.priorityName, e.priorityQty, e.priorityPercentage])
          .toList(),
      fileName: 'prioritywise_order_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Priority Wise Production Analysis',
    );
  }

  Future<void> generatePrioritywiseOrderPDF(
    PriorityWiseAnalysisList priorityWiseAnalysisList,
  ) async {
    await reportService.generatePDF(
      title: 'PriorityWiseProduction',
      headers: ['Priority', 'Priority Qty.', 'Priority %'],
      rows: priorityWiseAnalysisList.priorityData
          .map((e) => [e.priorityName, e.priorityQty, e.priorityPercentage])
          .toList(),
      fileName: 'prioritywise_order_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generatePendingOrderExcel() async {
    await reportService.generateExcel(
      sheetName: 'PendingOrderProduction',
      headers: [
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
      ],
      rows: pendingOrders
          .map(
            (element) => [
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
            ],
          )
          .toList(),
      fileName: 'production_pending_order_report.xlsx',
      amountColumns: [7, 8, 9, 10, 11, 12],
      addTotalRow: true,
      reportTitle: 'Production - Pending Order Analysis',
    );
  }

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _dailyOrderHorizontalController = ScrollController();
  final ScrollController _priorityWiseHorizontalController = ScrollController();
  final ScrollController _hospitalWiseHorizontalController = ScrollController();
  final ScrollController _productWiseHorizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    LoadDates();
    prepareFormattedDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
    }
  }

  @override
  void dispose() {
    client.close();
    _verticalScrollController.dispose();
    _dailyOrderHorizontalController.dispose();
    _priorityWiseHorizontalController.dispose();
    _hospitalWiseHorizontalController.dispose();
    _productWiseHorizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final screenWidth = media.width;
    return chartDataLoaded
        ? FinanceVerticalScroll(
            controller: _verticalScrollController,
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

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Daily Order\nQty Analysis',
                    spacing: 20,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFF2CA9DF),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Ordered Qty.',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 10),

                        Container(
                          height: 8,
                          width: 8,
                          color: Color(0xFFFF9F47),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Dispatched Qty.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateDailyOrderExcel(dailyData);
                        },
                        child: const Text("Download Excel"),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          generateDailyOrderPDF(dailyData);
                        },
                        child: const Text("Download PDF"),
                      ),
                    ],
                    child: _dailyOrderQtyAnalysis(screenWidth),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Priority wise Analysis',
                    trailing: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    height: 8,
                                    width: 16,
                                    color: getCategoryColor(0),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 8,
                                    width: 16,
                                    color: getCategoryColor(2),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 8,
                                    width: 16,
                                    color: getCategoryColor(1),
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
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generatePrioritywiseOrderExcel(priorityList);
                        },
                        child: const Text("Download Excel"),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          generatePrioritywiseOrderPDF(priorityList);
                        },
                        child: const Text("Download PDF"),
                      ),
                    ],

                    child: SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 30,
                          borderData: FlBorderData(show: false),
                          sections: showingSections(),
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Hospital\nWise Analysis',
                    spacing: 20,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFF2CA9DF),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Ordered Qty.',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 10),

                        Container(
                          height: 8,
                          width: 8,
                          color: Color(0xFFFF9F47),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Dispatched Qty.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateHospitalwiseOrderExcel(hospitalData);
                        },
                        child: const Text("Download Excel"),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          generateHospitalwiseOrderPDF(hospitalData);
                        },
                        child: const Text("Download PDF"),
                      ),
                    ],
                    child: _hospitalWiseAnalysis(screenWidth),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Product\nWise Analysis',
                    spacing: 20,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 8,
                          width: 8,
                          color: const Color(0xFF2CA9DF),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Ordered Qty.',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 10),

                        Container(
                          height: 8,
                          width: 8,
                          color: Color(0xFFFF9F47),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Dispatched Qty.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateProductwiseOrderExcel(productData);
                        },
                        child: const Text("Download Excel"),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          generateProductwiseOrderPDF(productData);
                        },
                        child: const Text("Download PDF"),
                      ),
                    ],
                    child: _productWiseQtyAnalysis(screenWidth),
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

  Widget _dailyOrderQtyAnalysis(double screenWidth) {
    double chartWidth = 0.0;
    int len = dailyData.dailyData.length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    return FinanceHorizontalChartScroll(
      controller: _dailyOrderHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(dailyMaxY),
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
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedDay = touchedDay == ""
                          ? dailyData
                                .dailyData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .date
                          : "";
                      showDrillDownChart = true;
                      await loadDataWithFilter(
                        touchedDay,
                        touchedHospital,
                        touchedItem,
                      );
                    }
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
      ),
    );
  }

  Widget _hospitalWiseAnalysis(double screenWidth) {
    double chartWidth = 0.0;
    int len = hospitalData.hospitalData.length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    return FinanceHorizontalChartScroll(
      controller: _hospitalWiseHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(hospitalMaxY),
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
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedHospital = touchedHospital == ""
                          ? hospitalData
                                .hospitalData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .hospitalName
                          : "";
                      showDrillDownChart = true;
                      await loadDataWithFilter(
                        touchedDay,
                        touchedHospital,
                        touchedItem,
                      );
                    }
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
      ),
    );
  }

  Widget _productWiseQtyAnalysis(double screenWidth) {
    double chartWidth = 0.0;
    int len = productData.productData.length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    return FinanceHorizontalChartScroll(
      controller: _productWiseHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(productMaxY),
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
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedItem = touchedItem == ""
                          ? productData
                                .productData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .productName
                          : "";
                      showDrillDownChart = true;
                      await loadDataWithFilter(
                        touchedDay,
                        touchedHospital,
                        touchedItem,
                      );
                    }
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
      ),
    );
  }
}
