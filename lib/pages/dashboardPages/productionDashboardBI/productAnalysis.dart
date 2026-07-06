// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import '../ReportService.dart';
import '../dashboard_card_ui.dart';

class ProductAnalysis extends StatefulWidget {
  const ProductAnalysis({super.key});

  @override
  State<ProductAnalysis> createState() => _ProductAnalysisState();
}

class _ProductAnalysisState extends State<ProductAnalysis> {
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

  List<ConsumptionList> consumptionList = [];
  List<ProductionList> productionList = [];

  ProductionVsConsumptionProductionList productionData =
      ProductionVsConsumptionProductionList(productionData: []);
  ProductionVsConsumptionConsumptionList consumptionData =
      ProductionVsConsumptionConsumptionList(consumptionData: []);
  ItemWiseProductionProductAnalysisList itemWiseData =
      ItemWiseProductionProductAnalysisList(itemWiseData: []);
  ItemWiseConsumptionProductAnalysisList itemWiseConsumptionData =
      ItemWiseConsumptionProductAnalysisList(itemWiseConsumptionData: []);
  ItemGroupWiseProductionProductAnalysisList itemGroupWiseProductionData =
      ItemGroupWiseProductionProductAnalysisList(itemGroupWiseData: []);
  ItemGroupWiseConsumptionProductAnalysisList itemGroupWiseConsumptionData =
      ItemGroupWiseConsumptionProductAnalysisList(
        itemGroupWiseConsumptionData: [],
      );
  ItemSubGroupWiseProductionProductAnalysisList itemSubGroupWiseProductionData =
      ItemSubGroupWiseProductionProductAnalysisList(
        itemSubGroupWiseProductionData: [],
      );
  ItemSubGroupWiseConsumptionProductAnalysisList
  itemSubGroupWiseConsumptionData =
      ItemSubGroupWiseConsumptionProductAnalysisList(
        itemSubGroupWiseConsumptionData: [],
      );
  WarehouseWiseProductionList warehouseProductionList =
      WarehouseWiseProductionList(warehouseWiseProductionData: []);
  WarehouseWiseConsumptionList warehouseConsumptionList =
      WarehouseWiseConsumptionList(warehouseWiseConsumptionData: []);

  double productionValueHeader = 0;
  double productionQuantityHeader = 0;
  double consumptionValueHeader = 0;
  double consumptionQuantityHeader = 0;

  bool chartDataLoaded = false;
  int touchedMonthIndex = 0;
  String touchedMonth = "";
  String touchedItemCode = "";
  String touchedItemGroup = "";
  String touchedItemSubGroup = "";
  String touchedWarehouse = "";
  double selectedChart = 0;

  bool touchedMonthGoals = false;
  bool touchedQuarterGoals = false;
  bool touchedYTDGoals = false;
  bool showDrillDownChart = false;
  int touchedIndex = -1;

  double monthWiseMaxY = 0;
  double itemWiseMaxY = 0;
  double itemGroupMaxY = 0;
  double itemSubGroupMaxY = 0;
  double warehouseWiseMaxY = 0;

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
        currentQuarterFromDate = DateTime(now.year - 1, 1, 1);
        currentQuarterToDate = DateTime(now.year - 1, 3, 31);
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

  SideTitles get _bottomTitlesProductionVsConsumptionProduction => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<ProductionVsConsumptionProductionData> mData =
          productionData.productionData;
      text = mData.elementAt(value.toInt()).monthName;
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

  SideTitles get _bottomTitlesItemWiseProduction => SideTitles(
    reservedSize: 30,
    showTitles: true,
    interval: 6,
    getTitlesWidget: (value, meta) {
      if (value.toInt() >= itemWiseData.itemWiseData.length) {
        return const SizedBox.shrink();
      }
      String text = '';
      List<ItemWiseProductionProductAnalysisData> mData =
          itemWiseData.itemWiseData;
      text = mData.elementAt(value.toInt()).itemName;
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

  SideTitles get _bottomTitlesItemGroupWiseProduction => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<ItemGroupWiseProductionProductAnalysisData> mData =
          itemGroupWiseProductionData.itemGroupWiseData;
      text = mData.elementAt(value.toInt()).itemGroupName;
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

  SideTitles get _bottomTitlesItemSubGroupWiseProduction => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<ItemSubGroupWiseProductionProductAnalysisData> mData =
          itemSubGroupWiseProductionData.itemSubGroupWiseProductionData;
      text = mData.elementAt(value.toInt()).itemSubGroupName;
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

  SideTitles get _bottomTitlesWarehouseWiseProductionAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<WarehouseWiseProductionData> mData =
          warehouseProductionList.warehouseWiseProductionData;
      text = mData.elementAt(value.toInt()).warehouseCode;
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
    return List.generate(3, (i) {
      const radius = 80.0;
      switch (i) {
        case 0:
          return PieChartSectionData(
            color: const Color(0xFF8F8F8F),
            value: 5,
            radius: radius,
            showTitle: false,
          );
        case 1:
          return PieChartSectionData(
            color: const Color.fromARGB(255, 145, 59, 99),
            value: 35,
            radius: radius,
            showTitle: false,
          );
        case 2:
          return PieChartSectionData(
            color: const Color.fromARGB(255, 10, 153, 5),
            value: 60,
            radius: radius,
            showTitle: false,
          );
        default:
          throw Error();
      }
    });
  }

  List<BarChartGroupData> _productionVsConsumptionMonthlyChartData(
    List<ProductionVsConsumptionProductionData> productionData,
    List<ProductionVsConsumptionConsumptionData> consumptionData,
  ) {
    // Map consumptionData by monthName for quick lookup
    Map<String, double> consumptionMap = {
      for (var data in consumptionData) data.monthName: data.consumptionQty,
    };

    // Generate the bar chart group data
    return productionData.map((production) {
      // Lookup the consumption data for the same month
      double consumptionQty = consumptionMap[production.monthName] ?? 0.0;

      return BarChartGroupData(
        x: productionData.indexOf(production), // Index for X-axis
        barRods: [
          // Production bar
          BarChartRodData(
            color: const Color.fromARGB(255, 10, 153, 5),
            borderRadius: BorderRadius.zero,
            toY: production.productionQty, // Production value
            width: 20, // Adjust width
          ),
          // Consumption bar
          BarChartRodData(
            color: const Color.fromARGB(255, 145, 59, 99),
            borderRadius: BorderRadius.zero,
            toY: consumptionQty, // Consumption value
            width: 20, // Adjust width
          ),
        ],
        // Adjust bar spacing
        barsSpace: 5,
      );
    }).toList();
  }

  List<BarChartGroupData> _productionVsConsumptionItemWiseChartData(
    List<ItemWiseProductionProductAnalysisData> productionData,
    List<ItemWiseConsumptionProductAnalysisData> consumptionData,
  ) {
    // Map consumptionData by monthName for quick lookup
    Map<String, double> consumptionMap = {
      for (var data in consumptionData) data.itemName: data.consumptionQty,
    };

    // Generate the bar chart group data
    return productionData.map((production) {
      // Lookup the consumption data for the same month
      double consumptionQty = consumptionMap[production.itemName] ?? 0.0;

      return BarChartGroupData(
        x: productionData.indexOf(production), // Index for X-axis
        barRods: [
          // Production bar
          BarChartRodData(
            color: const Color.fromARGB(255, 10, 153, 5),
            borderRadius: BorderRadius.zero,
            toY: production.productionQty, // Production value
            width: 20, // Adjust width
          ),
          // Consumption bar
          BarChartRodData(
            color: const Color.fromARGB(255, 145, 59, 99),
            borderRadius: BorderRadius.zero,
            toY: consumptionQty, // Consumption value
            width: 20, // Adjust width
          ),
        ],
        // Adjust bar spacing
        barsSpace: 5,
      );
    }).toList();
  }

  List<BarChartGroupData> _productionVsConsumptionItemGroupWiseChartData(
    List<ItemGroupWiseProductionProductAnalysisData> productionData,
    List<ItemGroupWiseConsumptionProductAnalysisData> consumptionData,
  ) {
    // Map consumptionData by monthName for quick lookup
    Map<String, double> consumptionMap = {
      for (var data in consumptionData) data.itemGroupName: data.consumptionQty,
    };

    // Generate the bar chart group data
    return productionData.map((production) {
      // Lookup the consumption data for the same month
      double consumptionQty = consumptionMap[production.itemGroupName] ?? 0.0;

      return BarChartGroupData(
        x: productionData.indexOf(production), // Index for X-axis
        barRods: [
          // Production bar
          BarChartRodData(
            color: const Color.fromARGB(255, 10, 153, 5),
            borderRadius: BorderRadius.zero,
            toY: production.productionQty, // Production value
            width: 20, // Adjust width
          ),
          // Consumption bar
          BarChartRodData(
            color: const Color.fromARGB(255, 145, 59, 99),
            borderRadius: BorderRadius.zero,
            toY: consumptionQty, // Consumption value
            width: 20, // Adjust width
          ),
        ],
        // Adjust bar spacing
        barsSpace: 5,
      );
    }).toList();
  }

  List<BarChartGroupData> _productionVsConsumptionItemSubGroupWiseChartData(
    List<ItemSubGroupWiseProductionProductAnalysisData> productionData,
    List<ItemSubGroupWiseConsumptionProductAnalysisData> consumptionData,
  ) {
    // Map consumptionData by monthName for quick lookup
    Map<String, double> consumptionMap = {
      for (var data in consumptionData)
        data.itemSubGroupName: data.consumptionQty,
    };

    // Generate the bar chart group data
    return productionData.map((production) {
      // Lookup the consumption data for the same month
      double consumptionQty =
          consumptionMap[production.itemSubGroupName] ?? 0.0;

      return BarChartGroupData(
        x: productionData.indexOf(production), // Index for X-axis
        barRods: [
          // Production bar
          BarChartRodData(
            color: const Color.fromARGB(255, 10, 153, 5),
            borderRadius: BorderRadius.zero,
            toY: production.productionQty, // Production value
            width: 20, // Adjust width
          ),
          // Consumption bar
          BarChartRodData(
            color: const Color.fromARGB(255, 145, 59, 99),
            borderRadius: BorderRadius.zero,
            toY: consumptionQty, // Consumption value
            width: 20, // Adjust width
          ),
        ],
        // Adjust bar spacing
        barsSpace: 5,
      );
    }).toList();
  }

  List<BarChartGroupData> _productionVsConsumptionWarehouseWiseChartData(
    List<WarehouseWiseProductionData> productionData,
    List<WarehouseWiseConsumptionData> consumptionData,
  ) {
    // Map consumptionData by monthName for quick lookup
    Map<String, double> consumptionMap = {
      for (var data in consumptionData) data.warehouseName: data.consumptionQty,
    };

    // Generate the bar chart group data
    return productionData.map((production) {
      // Lookup the consumption data for the same month
      double consumptionQty = consumptionMap[production.warehouseName] ?? 0.0;

      return BarChartGroupData(
        x: productionData.indexOf(production), // Index for X-axis
        barRods: [
          // Production bar
          BarChartRodData(
            color: const Color.fromARGB(255, 10, 153, 5),
            borderRadius: BorderRadius.zero,
            toY: production.productionQty, // Production value
            width: 20, // Adjust width
          ),
          // Consumption bar
          BarChartRodData(
            color: const Color.fromARGB(255, 145, 59, 99),
            borderRadius: BorderRadius.zero,
            toY: consumptionQty, // Consumption value
            width: 20, // Adjust width
          ),
        ],
        // Adjust bar spacing
        barsSpace: 5,
      );
    }).toList();
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

  String extractOrderNumber(String remarks) {
    final regex = RegExp(
      r'Order :\d+',
    ); // Regular expression to match "Order :<number>"
    final match = regex.firstMatch(
      remarks,
    ); // Find the first match in the string
    return match != null
        ? match.group(0)!
        : ''; // Return the match or an empty string
  }

  Future<void> _loadProductionList(String userName, String userLevel) async {
    const int limit = 10000;
    int index = 0;
    int fetchedCount = 0;
    int monthIndex = currentDate!.month;
    List<ProductionList> salesList = [];

    // Precomputed dates
    String fromDate = formatDate(
      monthIndex == 4 ? lastMonthFromDate! : fiscalYearStartDate!,
    );
    String toDate = formatDate(currentDate!);

    try {
      do {
        // Request body
        var body = {
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        // API call
        const apiUrl = '${ApiHelper.baseUrl}BicxoGoodsProducedList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final responseJson = jsonDecode(response.body);

          if (responseJson["responseData"] != null &&
              responseJson["responseData"].isNotEmpty) {
            // Parse response data
            List<ProductionList> newSalesList =
                (responseJson["responseData"] as List)
                    .map((item) => ProductionList.fromJson(item))
                    .toList();

            salesList.addAll(newSalesList);
            fetchedCount = newSalesList.length;
            index++;
          } else {
            fetchedCount = 0; // Stop fetching if no data is returned
          }
        } else {
          fetchedCount = 0; // Stop fetching on API error
        }
      } while (fetchedCount == limit);

      // Update state
      setState(() {
        productionList = salesList;
      });

      // Filter the production list by date
      var productSalesList = productionList.where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.documentDate);
        return invoiceDate.isAtLeast(fiscalYearStartDate!) &&
            invoiceDate.isAtMost(currentDate!);
      });

      // Calculate totals
      double qtyTotal = 0;
      double valueTotal = 0;

      for (var val in productSalesList) {
        qtyTotal += double.tryParse(val.quantity) ?? 0;
        valueTotal += double.tryParse(val.lineTotal) ?? 0;
      }

      // Update headers
      productionQuantityHeader = qtyTotal;
      productionValueHeader = valueTotal;
    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
      }
    }
  }

  Future<void> _loadConsumptionList(String userName, String userLevel) async {
    const int limit = 10000;
    int index = 0;
    int fetchedCount = 0;
    int monthIndex = currentDate!.month;
    List<ConsumptionList> salesList = [];

    // Precomputed dates
    String fromDate = formatDate(
      monthIndex == 4 ? lastMonthFromDate! : fiscalYearStartDate!,
    );
    String toDate = formatDate(currentDate!);

    try {
      do {
        // Request body
        var body = {
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        // API call
        const apiUrl = '${ApiHelper.baseUrl}BicxoGoodsConsumptionList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final responseJson = jsonDecode(response.body);

          if (responseJson["responseData"] != null &&
              responseJson["responseData"].isNotEmpty) {
            // Parse the response data
            List<ConsumptionList> newSalesList =
                (responseJson["responseData"] as List)
                    .map((item) => ConsumptionList.fromJson(item))
                    .toList();

            salesList.addAll(newSalesList);
            fetchedCount = newSalesList.length;
            index++;
          } else {
            fetchedCount = 0; // Stop fetching if there's no more data
          }
        } else {
          fetchedCount = 0; // Stop fetching on API error
        }
      } while (fetchedCount == limit);

      // Update state
      setState(() {
        // Update consumptionList based on user level
        consumptionList = salesList;
      });

      // Filter the consumption list by date
      var productSalesList = consumptionList.where((target) {
        DateTime invoiceDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(target.documentDate);
        return invoiceDate.isAtLeast(fiscalYearStartDate!) &&
            invoiceDate.isAtMost(currentDate!);
      });

      // Calculate totals
      double qtyTotal = 0;
      double valueTotal = 0;

      for (var val in productSalesList) {
        qtyTotal += double.tryParse(val.quantity) ?? 0;
        valueTotal += double.tryParse(val.lineTotal) ?? 0;
      }

      // Update headers
      consumptionQuantityHeader = qtyTotal;
      consumptionValueHeader = valueTotal;
    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
      }
    }
  }

  Future<void> _loadProductionVsConsumptionProductionGraph() async {
    List<ProductionVsConsumptionProductionData> monthlyDataList = [];

    // Group data by month/year while parsing only once
    Map<String, double> monthlyProductionQty = {};
    Map<String, double> monthlyProductionValue = {};

    for (var target in productionList) {
      // Parse date once
      DateTime invoiceDate = DateFormat(
        'dd/MM/yyyy',
      ).parse(target.documentDate);
      String key = '${invoiceDate.year}-${invoiceDate.month}';

      // Accumulate production quantity and value
      double quantity = double.tryParse(target.quantity) ?? 0.0;
      double lineTotal = double.tryParse(target.lineTotal) ?? 0.0;

      monthlyProductionQty[key] = (monthlyProductionQty[key] ?? 0.0) + quantity;
      monthlyProductionValue[key] =
          (monthlyProductionValue[key] ?? 0.0) + lineTotal;
    }

    // Generate the monthly data for April (4) to March (15)
    for (int i = 4; i <= 15; i++) {
      String monthName = getMonthName(i);
      DateTime startDate;
      Map<String, DateTime> monthDates;
      if (i >= 4 && i <= 12) {
        monthDates = getMonthStartEndDates(i);
      } else {
        monthDates = getMonthStartEndDates(i - 12);
      }
      startDate = monthDates['start']!;
      String key = '${startDate.year}-${startDate.month}';
      double productionQty = monthlyProductionQty[key] ?? 0.0;
      double productionValue = monthlyProductionValue[key] ?? 0.0;

      // Add to the monthly data list
      monthlyDataList.add(
        ProductionVsConsumptionProductionData(
          monthName: monthName,
          productionQty: productionQty,
          productionValue: productionValue,
        ),
      );
    }

    // Update the final data
    productionData = ProductionVsConsumptionProductionList(
      productionData: monthlyDataList,
    );
  }

  Future<void> _loadProductionVsConsumptionConsumptionGraph() async {
    List<ProductionVsConsumptionConsumptionData> monthlyDataList = [];

    // Group data by month/year while parsing only once
    Map<String, double> monthlyConsumptionQty = {};
    Map<String, double> monthlyConsumptionValue = {};

    for (var target in consumptionList) {
      // Parse date once
      DateTime invoiceDate = DateFormat(
        'dd/MM/yyyy',
      ).parse(target.documentDate);
      String key = '${invoiceDate.year}-${invoiceDate.month}';

      // Accumulate consumption quantity and value
      double quantity = double.tryParse(target.quantity) ?? 0.0;
      double lineTotal = double.tryParse(target.lineTotal) ?? 0.0;

      monthlyConsumptionQty[key] =
          (monthlyConsumptionQty[key] ?? 0.0) + quantity;
      monthlyConsumptionValue[key] =
          (monthlyConsumptionValue[key] ?? 0.0) + lineTotal;
    }

    // Generate the monthly data for April (4) to March (15)
    for (int i = 4; i <= 15; i++) {
      String monthName = getMonthName(i);
      DateTime startDate;
      Map<String, DateTime> monthDates;
      if (i >= 4 && i <= 12) {
        monthDates = getMonthStartEndDates(i);
      } else {
        monthDates = getMonthStartEndDates(i - 12);
      }
      startDate = monthDates['start']!;
      String key = '${startDate.year}-${startDate.month}';
      double consumptionQty = monthlyConsumptionQty[key] ?? 0.0;
      double consumptionValue = monthlyConsumptionValue[key] ?? 0.0;

      // Add to the monthly data list
      monthlyDataList.add(
        ProductionVsConsumptionConsumptionData(
          monthName: monthName,
          consumptionQty: consumptionQty,
          consumptionValue: consumptionValue,
        ),
      );
    }

    // Update the final data
    consumptionData = ProductionVsConsumptionConsumptionList(
      consumptionData: monthlyDataList,
    );
  }

  Future<void> _loadItemWiseProductionGraph(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String warehouseCode,
  ) async {
    List<ItemWiseProductionProductAnalysisData> productwiseDataList = [];
    // int currentYear = DateTime.now().year;

    // Determine the start and end dates for the given month
    DateTime startDate, endDate;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
    } else if (monthIndex >= 4 && monthIndex <= 12) {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      startDate = monthDates['start']!;
      endDate = monthDates['end']!;
    } else {
      // startDate = DateTime(currentYear + 1, monthIndex, 1);
      // endDate = DateTime(currentYear + 1, monthIndex + 1, 0);
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      startDate = monthDates['start']!;
      endDate = monthDates['end']!;
    }

    // Convert start and end dates to `DateTime` objects
    final startTime = startDate.millisecondsSinceEpoch;
    final endTime = endDate.millisecondsSinceEpoch;

    // Filter production list only once by comparing timestamps directly
    var filteredData = productionList.where((target) {
      DateTime invoiceDate = DateFormat(
        'dd/MM/yyyy',
      ).parse(target.documentDate);
      return invoiceDate.millisecondsSinceEpoch >= startTime &&
          invoiceDate.millisecondsSinceEpoch <= endTime;
    }).toList();

    // Apply additional filters for itemCode, itemGroup, itemSubGroup, and warehouse
    filteredData = filterProductionList(
      filteredData.cast<ProductionList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      warehouseCode: warehouseCode,
    );

    // Aggregate data by itemDescription
    Map<String, ItemWiseProductionProductAnalysisData> productDataMap = {};
    for (var target in filteredData) {
      String itemName = target.itemDescription;
      String remarks = target.remarks;
      String group = target.groupName;
      String subGroup = target.itemSubGroup;
      double productionQty = double.tryParse(target.quantity) ?? 0;
      double productionValue = double.tryParse(target.lineTotal) ?? 0;

      if (productDataMap.containsKey(itemName)) {
        productDataMap[itemName]!.productionQty += productionQty;
        productDataMap[itemName]!.productionValue += productionValue;
      } else {
        productDataMap[itemName] = ItemWiseProductionProductAnalysisData(
          itemName: itemName,
          remarks: remarks,
          groupName: group,
          subGroupName: subGroup,
          productionQty: productionQty,
          productionValue: productionValue,
        );
      }
    }

    // Convert the map to a sorted list
    productwiseDataList = productDataMap.values.toList()
      ..sort((a, b) => b.productionQty.compareTo(a.productionQty));

    // Update the final data
    itemWiseData = ItemWiseProductionProductAnalysisList(
      itemWiseData: productwiseDataList,
    );
  }

  Future<void> _loadItemWiseConsumptionGraph(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String warehouseName,
  ) async {
    List<ItemWiseConsumptionProductAnalysisData> productwiseDataList = [];
    // int currentYear = DateTime.now().year;

    // Determine the start and end dates for the given month
    DateTime startDate, endDate;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
    } else if (monthIndex >= 4 && monthIndex <= 12) {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      startDate = monthDates['start']!;
      endDate = monthDates['end']!;
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      startDate = monthDates['start']!;
      endDate = monthDates['end']!;
    }

    // Convert start and end dates to `DateTime` objects
    final startTime = startDate.millisecondsSinceEpoch;
    final endTime = endDate.millisecondsSinceEpoch;

    // Pre-filter consumption data by comparing timestamps directly
    var filteredData = consumptionList.where((target) {
      DateTime invoiceDate = DateFormat(
        'dd/MM/yyyy',
      ).parse(target.documentDate);
      return invoiceDate.millisecondsSinceEpoch >= startTime &&
          invoiceDate.millisecondsSinceEpoch <= endTime;
    }).toList();

    filteredData = filterConsumptionList(
      filteredData.cast<ConsumptionList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      warehouseName: warehouseName,
    );

    Map<String, ItemWiseConsumptionProductAnalysisData> productDataMap = {};
    for (var product in filteredData) {
      String item = product.itemDescription;
      double consumptionQty = double.tryParse(product.quantity) ?? 0;
      double consumptionValue = double.tryParse(product.lineTotal) ?? 0;

      if (productDataMap.containsKey(item)) {
        productDataMap[item]!.consumptionQty += consumptionQty;
        productDataMap[item]!.consumptionValue += consumptionValue;
      } else {
        productDataMap[item] = ItemWiseConsumptionProductAnalysisData(
          itemName: item,
          consumptionQty: consumptionQty,
          consumptionValue: consumptionValue,
        );
      }
    }

    // Convert the map to a sorted list
    productwiseDataList = productDataMap.values.toList()
      ..sort((a, b) => b.consumptionQty.compareTo(a.consumptionQty));

    // Update the final data
    itemWiseConsumptionData = ItemWiseConsumptionProductAnalysisList(
      itemWiseConsumptionData: productwiseDataList,
    );
  }

  Future<void> _loadItemGroupWiseProductionGraph(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String warehouseCode,
  ) async {
    List<ItemGroupWiseProductionProductAnalysisData> productwiseDataList = [];
    // int currentYear = DateTime.now().year;

    // Determine the start and end dates for the given month
    DateTime startDate, endDate;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
    } else if (monthIndex >= 4 && monthIndex <= 12) {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      startDate = monthDates['start']!;
      endDate = monthDates['end']!;
    } else {
      // startDate = DateTime(currentYear + 1, monthIndex, 1);
      // endDate = DateTime(currentYear + 1, monthIndex + 1, 0);
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      startDate = monthDates['start']!;
      endDate = monthDates['end']!;
    }

    // Convert start and end dates to `DateTime` objects
    final startTime = startDate.millisecondsSinceEpoch;
    final endTime = endDate.millisecondsSinceEpoch;

    // Filter production list only once by comparing timestamps directly
    var filteredData = productionList.where((target) {
      DateTime invoiceDate = DateFormat(
        'dd/MM/yyyy',
      ).parse(target.documentDate);
      return invoiceDate.millisecondsSinceEpoch >= startTime &&
          invoiceDate.millisecondsSinceEpoch <= endTime;
    }).toList();

    // Apply additional filters for itemCode, itemGroup, itemSubGroup, and warehouse
    filteredData = filterProductionList(
      filteredData.cast<ProductionList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      warehouseCode: warehouseCode,
    );

    // Aggregate data by itemDescription
    Map<String, ItemGroupWiseProductionProductAnalysisData> productDataMap = {};
    for (var target in filteredData) {
      String itemGroupName = target.groupName;
      String remarks = target.remarks;
      double productionQty = double.tryParse(target.quantity) ?? 0;
      double productionValue = double.tryParse(target.lineTotal) ?? 0;

      if (productDataMap.containsKey(itemGroupName)) {
        productDataMap[itemGroupName]!.productionQty += productionQty;
        productDataMap[itemGroupName]!.productionValue += productionValue;
      } else {
        productDataMap[itemGroupName] =
            ItemGroupWiseProductionProductAnalysisData(
              itemGroupName: itemGroupName,
              remarks: remarks,
              productionQty: productionQty,
              productionValue: productionValue,
            );
      }
    }

    // Convert the map to a sorted list
    productwiseDataList = productDataMap.values.toList()
      ..sort((a, b) => b.productionQty.compareTo(a.productionQty));

    // Update the final data
    itemGroupWiseProductionData = ItemGroupWiseProductionProductAnalysisList(
      itemGroupWiseData: productwiseDataList,
    );
  }

  Future<void> _loadItemGroupWiseConsumptionGraph(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String warehouseName,
  ) async {
    List<ItemGroupWiseConsumptionProductAnalysisData> productwiseDataList = [];
    // int currentYear = DateTime.now().year;

    // Determine the start and end dates for the given month
    DateTime startDate, endDate;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
    } else if (monthIndex >= 4 && monthIndex <= 12) {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      startDate = monthDates['start']!;
      endDate = monthDates['end']!;
    } else {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      startDate = monthDates['start']!;
      endDate = monthDates['end']!;
    }

    // Convert start and end dates to `DateTime` objects
    final startTime = startDate.millisecondsSinceEpoch;
    final endTime = endDate.millisecondsSinceEpoch;

    // Pre-filter consumption data by comparing timestamps directly
    var filteredData = consumptionList.where((target) {
      DateTime invoiceDate = DateFormat(
        'dd/MM/yyyy',
      ).parse(target.documentDate);
      return invoiceDate.millisecondsSinceEpoch >= startTime &&
          invoiceDate.millisecondsSinceEpoch <= endTime;
    }).toList();

    filteredData = filterConsumptionList(
      filteredData.cast<ConsumptionList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      warehouseName: warehouseName,
    );

    // Aggregate consumption data by item group
    Map<String, ItemGroupWiseConsumptionProductAnalysisData> productDataMap =
        {};
    for (var product in filteredData) {
      String groupName = product.groupName;
      double consumptionQty = double.tryParse(product.quantity) ?? 0;
      double consumptionValue = double.tryParse(product.lineTotal) ?? 0;

      if (productDataMap.containsKey(groupName)) {
        productDataMap[groupName]!.consumptionQty += consumptionQty;
        productDataMap[groupName]!.consumptionValue += consumptionValue;
      } else {
        productDataMap[groupName] = ItemGroupWiseConsumptionProductAnalysisData(
          itemGroupName: groupName,
          consumptionQty: consumptionQty,
          consumptionValue: consumptionValue,
        );
      }
    }

    // Convert the map to a sorted list
    productwiseDataList = productDataMap.values.toList()
      ..sort((a, b) => b.consumptionQty.compareTo(a.consumptionQty));

    itemGroupWiseConsumptionData = ItemGroupWiseConsumptionProductAnalysisList(
      itemGroupWiseConsumptionData: productwiseDataList,
    );
  }

  Future<void> _loadItemSubGroupWiseProductionGraph(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String warehouseCode,
  ) async {
    List<ItemSubGroupWiseProductionProductAnalysisData> productwiseDataList =
        [];
    // int currentYear = DateTime.now().year;

    // Determine the start and end dates for the given month
    DateTime startDate, endDate;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
    } else if (monthIndex >= 4 && monthIndex <= 12) {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      startDate = monthDates['start']!;
      endDate = monthDates['end']!;
    } else {
      // startDate = DateTime(currentYear + 1, monthIndex, 1);
      // endDate = DateTime(currentYear + 1, monthIndex + 1, 0);
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      startDate = monthDates['start']!;
      endDate = monthDates['end']!;
    }

    // Convert start and end dates to `DateTime` objects
    final startTime = startDate.millisecondsSinceEpoch;
    final endTime = endDate.millisecondsSinceEpoch;

    // Filter production list only once by comparing timestamps directly
    var filteredData = productionList.where((target) {
      DateTime invoiceDate = DateFormat(
        'dd/MM/yyyy',
      ).parse(target.documentDate);
      return invoiceDate.millisecondsSinceEpoch >= startTime &&
          invoiceDate.millisecondsSinceEpoch <= endTime;
    }).toList();

    // Apply additional filters for itemCode, itemGroup, itemSubGroup, and warehouse
    filteredData = filterProductionList(
      filteredData.cast<ProductionList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      warehouseCode: warehouseCode,
    );

    // Aggregate data by itemDescription
    Map<String, ItemSubGroupWiseProductionProductAnalysisData> productDataMap =
        {};
    for (var target in filteredData) {
      String itemSubGroupName = target.itemSubGroup;
      String remarks = target.remarks;
      double productionQty = double.tryParse(target.quantity) ?? 0;
      double productionValue = double.tryParse(target.lineTotal) ?? 0;

      if (productDataMap.containsKey(itemSubGroupName)) {
        productDataMap[itemSubGroupName]!.productionQty += productionQty;
        productDataMap[itemSubGroupName]!.productionValue += productionValue;
      } else {
        productDataMap[itemSubGroupName] =
            ItemSubGroupWiseProductionProductAnalysisData(
              itemSubGroupName: itemSubGroupName,
              remarks: remarks,
              productionQty: productionQty,
              productionValue: productionValue,
            );
      }
    }

    // Convert the map to a sorted list
    productwiseDataList = productDataMap.values.toList()
      ..sort((a, b) => b.productionQty.compareTo(a.productionQty));

    itemSubGroupWiseProductionData =
        ItemSubGroupWiseProductionProductAnalysisList(
          itemSubGroupWiseProductionData: productwiseDataList,
        );
  }

  Future<void> _loadItemSubGroupWiseConsumptionGraph(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String warehouseName,
  ) async {
    List<ItemSubGroupWiseConsumptionProductAnalysisData> productwiseDataList =
        [];
    // int currentYear = DateTime.now().year;

    // Determine the start and end dates for the given month
    DateTime startDate, endDate;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
    } else if (monthIndex >= 4 && monthIndex <= 12) {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      startDate = monthDates['start']!;
      endDate = monthDates['end']!;
    } else {
      // startDate = DateTime(currentYear, monthIndex, 1);
      // endDate = DateTime(currentYear, monthIndex + 1, 0);
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      startDate = monthDates['start']!;
      endDate = monthDates['end']!;
    }

    // Convert start and end dates to `DateTime` objects
    final startTime = startDate.millisecondsSinceEpoch;
    final endTime = endDate.millisecondsSinceEpoch;

    // Pre-filter consumption data by comparing timestamps directly
    var filteredData = consumptionList.where((target) {
      DateTime invoiceDate = DateFormat(
        'dd/MM/yyyy',
      ).parse(target.documentDate);
      return invoiceDate.millisecondsSinceEpoch >= startTime &&
          invoiceDate.millisecondsSinceEpoch <= endTime;
    }).toList();

    filteredData = filterConsumptionList(
      filteredData.cast<ConsumptionList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      warehouseName: warehouseName,
    );

    Map<String, ItemSubGroupWiseConsumptionProductAnalysisData> productDataMap =
        {};
    for (var product in filteredData) {
      String subGroupName = product.itemSubGroup;
      double consumptionQty = double.tryParse(product.quantity) ?? 0;
      double consumptionValue = double.tryParse(product.lineTotal) ?? 0;

      if (productDataMap.containsKey(subGroupName)) {
        productDataMap[subGroupName]!.consumptionQty += consumptionQty;
        productDataMap[subGroupName]!.consumptionValue += consumptionValue;
      } else {
        productDataMap[subGroupName] =
            ItemSubGroupWiseConsumptionProductAnalysisData(
              itemSubGroupName: subGroupName,
              consumptionQty: consumptionQty,
              consumptionValue: consumptionValue,
            );
      }
    }

    // Convert the map to a sorted list
    productwiseDataList = productDataMap.values.toList()
      ..sort((a, b) => b.consumptionQty.compareTo(a.consumptionQty));

    itemSubGroupWiseConsumptionData =
        ItemSubGroupWiseConsumptionProductAnalysisList(
          itemSubGroupWiseConsumptionData: productwiseDataList,
        );
  }

  Future<void> _loadWarehouseWiseWiseProductionGraph(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String warehouseCode,
  ) async {
    List<WarehouseWiseProductionData> productwiseDataList = [];
    // int currentYear = DateTime.now().year;

    // Determine the start and end dates for the given month
    DateTime startDate, endDate;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
    } else if (monthIndex >= 4 && monthIndex <= 12) {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      startDate = monthDates['start']!;
      endDate = monthDates['end']!;
    } else {
      // startDate = DateTime(currentYear + 1, monthIndex, 1);
      // endDate = DateTime(currentYear + 1, monthIndex + 1, 0);
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      startDate = monthDates['start']!;
      endDate = monthDates['end']!;
    }

    // Convert start and end dates to `DateTime` objects
    final startTime = startDate.millisecondsSinceEpoch;
    final endTime = endDate.millisecondsSinceEpoch;

    // Filter production list only once by comparing timestamps directly
    var filteredData = productionList.where((target) {
      DateTime invoiceDate = DateFormat(
        'dd/MM/yyyy',
      ).parse(target.documentDate);
      return invoiceDate.millisecondsSinceEpoch >= startTime &&
          invoiceDate.millisecondsSinceEpoch <= endTime;
    }).toList();

    // Apply additional filters for itemCode, itemGroup, itemSubGroup, and warehouse
    filteredData = filterProductionList(
      filteredData.cast<ProductionList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      warehouseCode: warehouseCode,
    );

    // Aggregate data by itemDescription
    Map<String, WarehouseWiseProductionData> productDataMap = {};
    for (var target in filteredData) {
      String warehouse = target.warehouseCode;
      String warehouseName = target.warehouseName;
      double productionQty = double.tryParse(target.quantity) ?? 0;
      double productionValue = double.tryParse(target.lineTotal) ?? 0;

      if (productDataMap.containsKey(warehouseName)) {
        productDataMap[warehouseName]!.productionQty += productionQty;
        productDataMap[warehouseName]!.productionValue += productionValue;
      } else {
        productDataMap[warehouseName] = WarehouseWiseProductionData(
          warehouseCode: warehouse,
          warehouseName: warehouseName,
          productionQty: productionQty,
          productionValue: productionValue,
        );
      }
    }

    // Convert the map to a sorted list
    productwiseDataList = productDataMap.values.toList()
      ..sort((a, b) => b.productionQty.compareTo(a.productionQty));

    warehouseProductionList = WarehouseWiseProductionList(
      warehouseWiseProductionData: productwiseDataList,
    );
  }

  Future<void> _loadWarehouseWiseWiseConsumptionGraph(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String warehouseName,
  ) async {
    List<WarehouseWiseConsumptionData> productwiseDataList = [];
    // int currentYear = DateTime.now().year;

    // Determine the start and end dates for the given month
    DateTime startDate, endDate;
    if (monthIndex == 0) {
      startDate = currentMonthFromDate!;
      endDate = currentDate!;
    } else if (monthIndex >= 4 && monthIndex <= 12) {
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      startDate = monthDates['start']!;
      endDate = monthDates['end']!;
    } else {
      // startDate = DateTime(currentYear, monthIndex, 1);
      // endDate = DateTime(currentYear, monthIndex + 1, 0);
      Map<String, DateTime> monthDates = getMonthStartEndDates(monthIndex);
      startDate = monthDates['start']!;
      endDate = monthDates['end']!;
    }

    // Convert start and end dates to `DateTime` objects
    final startTime = startDate.millisecondsSinceEpoch;
    final endTime = endDate.millisecondsSinceEpoch;

    // Pre-filter consumption data by comparing timestamps directly
    var filteredData = consumptionList.where((target) {
      DateTime invoiceDate = DateFormat(
        'dd/MM/yyyy',
      ).parse(target.documentDate);
      return invoiceDate.millisecondsSinceEpoch >= startTime &&
          invoiceDate.millisecondsSinceEpoch <= endTime;
    }).toList();

    // Apply additional filters
    filteredData = filterConsumptionList(
      filteredData.cast<ConsumptionList>().toList(),
      itemCode: itemCode,
      itemGroup: itemGroup,
      itemSubGroup: itemSubGroup,
      warehouseName: warehouseName,
    );

    // Aggregate consumption data by item description
    Map<String, WarehouseWiseConsumptionData> productDataMap = {};
    for (var product in filteredData) {
      String warehouseCode = product.warehouseCode;
      String warehouseName = product.warehouseName;
      double consumptionQty = double.tryParse(product.quantity) ?? 0;
      double consumptionValue = double.tryParse(product.lineTotal) ?? 0;

      if (productDataMap.containsKey(warehouseName)) {
        productDataMap[warehouseName]!.consumptionQty += consumptionQty;
        productDataMap[warehouseName]!.consumptionValue += consumptionValue;
      } else {
        productDataMap[warehouseName] = WarehouseWiseConsumptionData(
          warehouseCode: warehouseCode,
          warehouseName: warehouseName,
          consumptionQty: consumptionQty,
          consumptionValue: consumptionValue,
        );
      }
    }

    // Convert the map to a sorted list
    productwiseDataList = productDataMap.values.toList()
      ..sort((a, b) => b.consumptionQty.compareTo(a.consumptionQty));

    warehouseConsumptionList = WarehouseWiseConsumptionList(
      warehouseWiseConsumptionData: productwiseDataList,
    );
  }

  void prepareMaxValues() {
    /// MONTH WISE
    monthWiseMaxY = 0;
    if (productionData.productionData.isNotEmpty ||
        consumptionData.consumptionData.isNotEmpty) {
      List<double> allValues = [
        ...productionData.productionData.map((data) => data.productionQty),
        ...consumptionData.consumptionData.map((data) => data.consumptionQty),
      ];

      monthWiseMaxY = allValues.reduce((a, b) => a > b ? a : b);
    }

    /// ITEM WISE
    itemWiseMaxY = 0;
    if (itemWiseData.itemWiseData.isNotEmpty ||
        itemWiseConsumptionData.itemWiseConsumptionData.isNotEmpty) {
      List<double> allValues = [
        ...itemWiseData.itemWiseData.map((data) => data.productionQty),
        ...itemWiseConsumptionData.itemWiseConsumptionData.map(
          (data) => data.consumptionQty,
        ),
      ];

      itemWiseMaxY = allValues.reduce((a, b) => a > b ? a : b);
    }

    /// ITEM GROUP WISE
    itemGroupMaxY = 0;
    if (itemGroupWiseProductionData.itemGroupWiseData.isNotEmpty ||
        itemGroupWiseConsumptionData.itemGroupWiseConsumptionData.isNotEmpty) {
      List<double> allValues = [
        ...itemGroupWiseConsumptionData.itemGroupWiseConsumptionData.map(
          (data) => data.consumptionQty,
        ),
        ...itemGroupWiseProductionData.itemGroupWiseData.map(
          (data) => data.productionQty,
        ),
      ];

      itemGroupMaxY = allValues.reduce((a, b) => a > b ? a : b);
    }

    /// ITEM SUB GROUP WISE
    itemSubGroupMaxY = 0;
    if (itemSubGroupWiseProductionData
            .itemSubGroupWiseProductionData
            .isNotEmpty ||
        itemSubGroupWiseConsumptionData
            .itemSubGroupWiseConsumptionData
            .isNotEmpty) {
      List<double> allValues = [
        ...itemSubGroupWiseProductionData.itemSubGroupWiseProductionData.map(
          (data) => data.productionQty,
        ),
        ...itemSubGroupWiseConsumptionData.itemSubGroupWiseConsumptionData.map(
          (data) => data.consumptionQty,
        ),
      ];

      itemSubGroupMaxY = allValues.reduce((a, b) => a > b ? a : b);
    }

    /// WAREHOUSE WISE
    warehouseWiseMaxY = 0;
    if (warehouseProductionList.warehouseWiseProductionData.isNotEmpty ||
        warehouseConsumptionList.warehouseWiseConsumptionData.isNotEmpty) {
      List<double> allValues = [
        ...warehouseProductionList.warehouseWiseProductionData.map(
          (data) => data.productionQty,
        ),
        ...warehouseConsumptionList.warehouseWiseConsumptionData.map(
          (data) => data.consumptionQty,
        ),
      ];

      warehouseWiseMaxY = allValues.reduce((a, b) => a > b ? a : b);
    }
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadConsumptionList(userName, userLevel);
    await _loadProductionList(userName, userLevel);
    await _loadProductionVsConsumptionProductionGraph();
    await _loadProductionVsConsumptionConsumptionGraph();
    await _loadItemWiseProductionGraph(0, "", "", "", "");
    await _loadItemWiseConsumptionGraph(0, "", "", "", "");
    await _loadItemGroupWiseProductionGraph(0, "", "", "", "");
    await _loadItemGroupWiseConsumptionGraph(0, "", "", "", "");
    await _loadItemSubGroupWiseProductionGraph(0, "", "", "", "");
    await _loadItemSubGroupWiseConsumptionGraph(0, "", "", "", "");
    await _loadWarehouseWiseWiseProductionGraph(0, "", "", "", "");
    await _loadWarehouseWiseWiseConsumptionGraph(0, "", "", "", "");
    chartDataLoaded = true;
    prepareMaxValues();

    if (mounted) {
      setState(() {});
    }
  }

  List<ProductionList> filterProductionList(
    List<ProductionList> productionList, {
    String? itemCode,
    String? itemGroup,
    String? itemSubGroup,
    String? warehouseCode,
  }) {
    List<ProductionList> filteredProductionList = [];
    for (var production in productionList) {
      if ((itemCode == null ||
              itemCode.isEmpty ||
              production.itemDescription == itemCode) &&
          (itemGroup == null ||
              itemGroup.isEmpty ||
              production.groupName == itemGroup) &&
          (itemSubGroup == null ||
              itemSubGroup.isEmpty ||
              production.itemSubGroup == itemSubGroup) &&
          (warehouseCode == null ||
              warehouseCode.isEmpty ||
              production.warehouseCode == warehouseCode)) {
        filteredProductionList.add(production);
      }
    }
    return filteredProductionList;
  }

  List<ConsumptionList> filterConsumptionList(
    List<ConsumptionList> consumptionList, {
    String? itemCode,
    String? itemGroup,
    String? itemSubGroup,
    String? warehouseName,
  }) {
    List<ConsumptionList> filteredConsumptionList = [];
    for (var consumption in consumptionList) {
      if ((itemCode == null ||
              itemCode.isEmpty ||
              consumption.itemDescription == itemCode) &&
          (itemGroup == null ||
              itemGroup.isEmpty ||
              consumption.groupName == itemGroup) &&
          (itemSubGroup == null ||
              itemSubGroup.isEmpty ||
              consumption.itemSubGroup == itemSubGroup) &&
          (warehouseName == null ||
              warehouseName.isEmpty ||
              consumption.warehouseName == warehouseName)) {
        filteredConsumptionList.add(consumption);
      }
    }
    return filteredConsumptionList;
  }

  Future<void> removeFilter() async {
    touchedMonthIndex = 0;
    touchedItemCode = "";
    touchedItemGroup = "";
    touchedItemSubGroup = "";
    touchedWarehouse = "";

    touchedMonthGoals = false;
    touchedQuarterGoals = false;
    touchedYTDGoals = false;
    clearVariables();
    LoadDates();
    await _loadItemWiseProductionGraph(0, "", "", "", "");
    await _loadItemWiseConsumptionGraph(0, "", "", "", "");
    await _loadItemGroupWiseProductionGraph(0, "", "", "", "");
    await _loadItemGroupWiseConsumptionGraph(0, "", "", "", "");
    await _loadItemSubGroupWiseProductionGraph(0, "", "", "", "");
    await _loadItemSubGroupWiseConsumptionGraph(0, "", "", "", "");
    await _loadWarehouseWiseWiseProductionGraph(0, "", "", "", "");
    await _loadWarehouseWiseWiseConsumptionGraph(0, "", "", "", "");
    chartDataLoaded = true;
    prepareMaxValues();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadDataWithFilter(
    int monthIndex,
    String itemCode,
    String itemGroup,
    String itemSubGroup,
    String warehouseCode,
  ) async {
    clearVariablesForFilter();
    LoadDates();
    await _loadItemWiseProductionGraph(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      warehouseCode,
    );
    await _loadItemWiseConsumptionGraph(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      warehouseCode,
    );
    await _loadItemGroupWiseProductionGraph(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      warehouseCode,
    );
    await _loadItemGroupWiseConsumptionGraph(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      warehouseCode,
    );
    await _loadItemSubGroupWiseProductionGraph(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      warehouseCode,
    );
    await _loadItemSubGroupWiseConsumptionGraph(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      warehouseCode,
    );
    await _loadWarehouseWiseWiseProductionGraph(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      warehouseCode,
    );
    await _loadWarehouseWiseWiseConsumptionGraph(
      monthIndex,
      itemCode,
      itemGroup,
      itemSubGroup,
      warehouseCode,
    );
    chartDataLoaded = true;
    prepareMaxValues();

    if (mounted) {
      setState(() {});
    }
  }

  void clearVariables() {
    setState(() {
      chartDataLoaded = false;

      itemWiseData = ItemWiseProductionProductAnalysisList(itemWiseData: []);
      itemWiseConsumptionData = ItemWiseConsumptionProductAnalysisList(
        itemWiseConsumptionData: [],
      );
      itemGroupWiseProductionData = ItemGroupWiseProductionProductAnalysisList(
        itemGroupWiseData: [],
      );
      itemGroupWiseConsumptionData =
          ItemGroupWiseConsumptionProductAnalysisList(
            itemGroupWiseConsumptionData: [],
          );
      itemSubGroupWiseProductionData =
          ItemSubGroupWiseProductionProductAnalysisList(
            itemSubGroupWiseProductionData: [],
          );
      itemSubGroupWiseConsumptionData =
          ItemSubGroupWiseConsumptionProductAnalysisList(
            itemSubGroupWiseConsumptionData: [],
          );
      warehouseProductionList = WarehouseWiseProductionList(
        warehouseWiseProductionData: [],
      );
      warehouseConsumptionList = WarehouseWiseConsumptionList(
        warehouseWiseConsumptionData: [],
      );
      touchedMonthIndex = 0;
      touchedItemCode = "";
      touchedItemGroup = "";
      touchedItemSubGroup = "";
      touchedWarehouse = "";
    });
  }

  void clearVariablesForFilter() {
    setState(() {
      chartDataLoaded = false;

      itemWiseData = ItemWiseProductionProductAnalysisList(itemWiseData: []);
      itemWiseConsumptionData = ItemWiseConsumptionProductAnalysisList(
        itemWiseConsumptionData: [],
      );
      itemGroupWiseProductionData = ItemGroupWiseProductionProductAnalysisList(
        itemGroupWiseData: [],
      );
      itemGroupWiseConsumptionData =
          ItemGroupWiseConsumptionProductAnalysisList(
            itemGroupWiseConsumptionData: [],
          );
      itemSubGroupWiseProductionData =
          ItemSubGroupWiseProductionProductAnalysisList(
            itemSubGroupWiseProductionData: [],
          );
      itemSubGroupWiseConsumptionData =
          ItemSubGroupWiseConsumptionProductAnalysisList(
            itemSubGroupWiseConsumptionData: [],
          );
      warehouseProductionList = WarehouseWiseProductionList(
        warehouseWiseProductionData: [],
      );
      warehouseConsumptionList = WarehouseWiseConsumptionList(
        warehouseWiseConsumptionData: [],
      );
    });
  }

  Future<void> generateMonthlyProductionVsConsumtionExcel(
    ProductionVsConsumptionProductionList monthlyProductionList,
    ProductionVsConsumptionConsumptionList monthlyConsumptionList,
  ) async {
    Map<String, double> consumptionMap = {
      for (var data in monthlyConsumptionList.consumptionData)
        data.monthName: data.consumptionQty,
    };
    await reportService.generateExcel(
      sheetName: 'ProductionVsConsumptionAnalysis',
      headers: ['Month', 'Production', 'Consumption'],
      rows: monthlyProductionList.productionData
          .map(
            (e) => [
              e.monthName,
              e.productionQty,
              consumptionMap[e.monthName] ?? 0.0,
            ],
          )
          .toList(),
      fileName: 'monthly_production_consumption_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Monthly Production Vs Consumption Analysis',
    );
  }

  Future<void> generateMonthlyProductionVsConsumtionPDF(
    ProductionVsConsumptionProductionList monthlyProductionList,
    ProductionVsConsumptionConsumptionList monthlyConsumptionList,
  ) async {
    Map<String, double> consumptionMap = {
      for (var data in monthlyConsumptionList.consumptionData)
        data.monthName: data.consumptionQty,
    };
    await reportService.generatePDF(
      title: 'ProductionVsConsumptionAnalysis',
      headers: ['Month', 'Production', 'Consumption'],
      rows: monthlyProductionList.productionData
          .map(
            (e) => [
              e.monthName,
              e.productionQty,
              consumptionMap[e.monthName] ?? 0.0,
            ],
          )
          .toList(),
      fileName: 'monthly_production_consumption_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateItemwiseProductionVsConsumtionExcel(
    ItemWiseProductionProductAnalysisList productionList,
    ItemWiseConsumptionProductAnalysisList consumptionList,
  ) async {
    Map<String, double> consumptionMap = {
      for (var data in consumptionList.itemWiseConsumptionData)
        data.itemName: data.consumptionQty,
    };
    await reportService.generateExcel(
      sheetName: 'ItemWiseProductionVsConsumptionAnalysis',
      headers: ['Product Name', 'Production', 'Consumption'],
      rows: productionList.itemWiseData
          .map(
            (e) => [
              e.itemName,
              e.productionQty,
              consumptionMap[e.itemName] ?? 0.0,
            ],
          )
          .toList(),
      fileName: 'itemwise_production_consumption_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Item Wise Production Vs Consumption Analysis',
    );
  }

  Future<void> generateItemwiseProductionVsConsumtionPDF(
    ItemWiseProductionProductAnalysisList productionList,
    ItemWiseConsumptionProductAnalysisList consumptionList,
  ) async {
    Map<String, double> consumptionMap = {
      for (var data in consumptionList.itemWiseConsumptionData)
        data.itemName: data.consumptionQty,
    };
    await reportService.generatePDF(
      title: 'ItemWiseProductionVsConsumptionAnalysis',
      headers: ['Product Name', 'Production', 'Consumption'],
      rows: productionList.itemWiseData
          .map(
            (e) => [
              e.itemName,
              e.productionQty,
              consumptionMap[e.itemName] ?? 0.0,
            ],
          )
          .toList(),
      fileName: 'itemwise_production_consumption_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateItemGroupwiseProductionVsConsumtionExcel(
    ItemGroupWiseProductionProductAnalysisList productionList,
    ItemGroupWiseConsumptionProductAnalysisList consumptionList,
  ) async {
    Map<String, double> consumptionMap = {
      for (var data in consumptionList.itemGroupWiseConsumptionData)
        data.itemGroupName: data.consumptionQty,
    };
    await reportService.generateExcel(
      sheetName: 'ItemGroupWiseProductionVsConsumptionAnalysis',
      headers: ['Product Group', 'Production', 'Consumption'],
      rows: productionList.itemGroupWiseData
          .map(
            (e) => [
              e.itemGroupName,
              e.productionQty,
              consumptionMap[e.itemGroupName] ?? 0.0,
            ],
          )
          .toList(),
      fileName: 'itemgroupwise_production_consumption_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle:
          'Production - Item Group Wise Production Vs Consumption Analysis',
    );
  }

  Future<void> generateItemGroupwiseProductionVsConsumtionPDF(
    ItemGroupWiseProductionProductAnalysisList productionList,
    ItemGroupWiseConsumptionProductAnalysisList consumptionList,
  ) async {
    Map<String, double> consumptionMap = {
      for (var data in consumptionList.itemGroupWiseConsumptionData)
        data.itemGroupName: data.consumptionQty,
    };
    await reportService.generatePDF(
      title: 'ItemGroupWiseProductionVsConsumptionAnalysis',
      headers: ['Product Group', 'Production', 'Consumption'],
      rows: productionList.itemGroupWiseData
          .map(
            (e) => [
              e.itemGroupName,
              e.productionQty,
              consumptionMap[e.itemGroupName] ?? 0.0,
            ],
          )
          .toList(),
      fileName: 'itemgroupwise_production_consumption_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateItemSubGroupwiseProductionVsConsumtionExcel(
    ItemSubGroupWiseProductionProductAnalysisList productionList,
    ItemSubGroupWiseConsumptionProductAnalysisList consumptionList,
  ) async {
    Map<String, double> consumptionMap = {
      for (var data in consumptionList.itemSubGroupWiseConsumptionData)
        data.itemSubGroupName: data.consumptionQty,
    };
    await reportService.generateExcel(
      sheetName: 'ItemSubGroupWiseProductionVsConsumptionAnalysis',
      headers: ['Product Sub Group', 'Production', 'Consumption'],
      rows: productionList.itemSubGroupWiseProductionData
          .map(
            (e) => [
              e.itemSubGroupName,
              e.productionQty,
              consumptionMap[e.itemSubGroupName] ?? 0.0,
            ],
          )
          .toList(),
      fileName: 'itemsubgroupwise_production_consumption_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle:
          'Production - Item Sub Group Wise Production Vs Consumption Analysis',
    );
  }

  Future<void> generateItemSubGroupwiseProductionVsConsumtionPDF(
    ItemSubGroupWiseProductionProductAnalysisList productionList,
    ItemSubGroupWiseConsumptionProductAnalysisList consumptionList,
  ) async {
    Map<String, double> consumptionMap = {
      for (var data in consumptionList.itemSubGroupWiseConsumptionData)
        data.itemSubGroupName: data.consumptionValue,
    };
    await reportService.generatePDF(
      title: 'ItemSubGroupWiseProductionVsConsumptionAnalysis',
      headers: ['Product Sub Group', 'Production', 'Consumption'],
      rows: productionList.itemSubGroupWiseProductionData
          .map(
            (e) => [
              e.itemSubGroupName,
              e.productionQty,
              consumptionMap[e.itemSubGroupName] ?? 0.0,
            ],
          )
          .toList(),
      fileName: 'itemsubgroupwise_production_consumption_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateWarehousewiseProductionVsConsumtionExcel(
    WarehouseWiseProductionList productionList,
    WarehouseWiseConsumptionList consumptionList,
  ) async {
    Map<String, double> consumptionMap = {
      for (var data in consumptionList.warehouseWiseConsumptionData)
        data.warehouseName: data.consumptionQty,
    };
    await reportService.generateExcel(
      sheetName: 'WarehouseWiseProductionVsConsumptionAnalysis',
      headers: ['Warehouse', 'Production', 'Consumption'],
      rows: productionList.warehouseWiseProductionData
          .map(
            (e) => [
              e.warehouseName,
              e.productionQty,
              consumptionMap[e.warehouseName] ?? 0.0,
            ],
          )
          .toList(),
      fileName: 'warehousewise_production_consumption_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle:
          'Production - Warehouse Wise Production Vs Consumption Analysis',
    );
  }

  Future<void> generateWarehousewiseProductionVsConsumtionPDF(
    WarehouseWiseProductionList productionList,
    WarehouseWiseConsumptionList consumptionList,
  ) async {
    Map<String, double> consumptionMap = {
      for (var data in consumptionList.warehouseWiseConsumptionData)
        data.warehouseName: data.consumptionQty,
    };
    await reportService.generatePDF(
      title: 'WarehouseWiseProductionVsConsumptionAnalysis',
      headers: ['Warehouse', 'Production', 'Consumption'],
      rows: productionList.warehouseWiseProductionData
          .map(
            (e) => [
              e.warehouseName,
              e.productionQty,
              consumptionMap[e.warehouseName] ?? 0.0,
            ],
          )
          .toList(),
      fileName: 'warehousewise_production_consumption_report.pdf',
      amountColumns: [2, 3],
    );
  }

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _monthWiseHorizontalController = ScrollController();
  final ScrollController _itemWiseHorizontalController = ScrollController();
  final ScrollController _itemGroupWiseHorizontalController =
      ScrollController();
  final ScrollController _itemSubGroupWiseHorizontalController =
      ScrollController();
  final ScrollController _warehouseWiseHorizontalController =
      ScrollController();

  @override
  void initState() {
    super.initState();
    LoadDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
    }
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _monthWiseHorizontalController.dispose();
    _itemWiseHorizontalController.dispose();
    _warehouseWiseHorizontalController.dispose();
    _itemGroupWiseHorizontalController.dispose();
    _itemSubGroupWiseHorizontalController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final screenWidth = media.width;
    String formattedQuarterStartDate = DateFormat(
      'dd/MM/yy',
    ).format(currentQuarterFromDate!);
    String formattedDateNow = DateFormat('dd/MM/yy').format(currentDate!);
    return chartDataLoaded == true
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
                        Text("$formattedQuarterStartDate - $formattedDateNow"),
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
                            color: const Color.fromARGB(255, 10, 153, 5),
                            border: Border.all(
                              color: const Color.fromARGB(0, 249, 248, 248),
                            ),
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
                                  'Production Value: ${formatAmount(productionValueHeader)}',
                                  style: TextStyle(color: Colors.white),
                                ),

                                Text(
                                  'Production Quantity: ${formatAmount(productionQuantityHeader)}',
                                  style: TextStyle(color: Colors.white),
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
                            color: Color.fromARGB(255, 145, 59, 99),
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
                                  'Consumption Value: ${formatAmount(consumptionValueHeader)}',
                                  style: TextStyle(color: Colors.white),
                                ),
                                Text(
                                  'Consumption Quantity: ${formatAmount(consumptionQuantityHeader)}',
                                  style: TextStyle(color: Colors.white),
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
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Production vs Consumption - Monthly',
                    spacing: 20,
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
                                    color: Color.fromARGB(255, 10, 153, 5),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 8,
                                    width: 16,
                                    color: Color.fromARGB(255, 145, 59, 99),
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
                                "Production",
                                textAlign: TextAlign.left,
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(
                                "Consumption",
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
                          setState(() {
                            generateMonthlyProductionVsConsumtionExcel(
                              productionData,
                              consumptionData,
                            );
                          });
                        },
                        child: const Text("Download Excel"),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          setState(() {
                            generateMonthlyProductionVsConsumtionPDF(
                              productionData,
                              consumptionData,
                            );
                          });
                        },
                        child: const Text("Download PDF"),
                      ),
                    ],
                    child: _productionVsConsumptionMonthly(screenWidth),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Production vs Consumption - Item Wise',
                    spacing: 20,
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
                                    color: Color.fromARGB(255, 10, 153, 5),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 8,
                                    width: 16,
                                    color: Color.fromARGB(255, 145, 59, 99),
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
                                "Production",
                                textAlign: TextAlign.left,
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(
                                "Consumption",
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
                          setState(() {
                            generateItemwiseProductionVsConsumtionExcel(
                              itemWiseData,
                              itemWiseConsumptionData,
                            );
                          });
                        },
                        child: const Text("Download Excel"),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          setState(() {
                            generateItemwiseProductionVsConsumtionPDF(
                              itemWiseData,
                              itemWiseConsumptionData,
                            );
                          });
                        },
                        child: const Text("Download PDF"),
                      ),
                    ],
                    child: _productionVsConsumptionItemWise(screenWidth),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Production vs Consumption - Item Group Wise',
                    spacing: 20,
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
                                    color: Color.fromARGB(255, 10, 153, 5),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 8,
                                    width: 16,
                                    color: Color.fromARGB(255, 145, 59, 99),
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
                                "Production",
                                textAlign: TextAlign.left,
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(
                                "Consumption",
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
                          setState(() {
                            generateItemGroupwiseProductionVsConsumtionExcel(
                              itemGroupWiseProductionData,
                              itemGroupWiseConsumptionData,
                            );
                          });
                        },
                        child: const Text("Download Excel"),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          setState(() {
                            generateItemGroupwiseProductionVsConsumtionPDF(
                              itemGroupWiseProductionData,
                              itemGroupWiseConsumptionData,
                            );
                          });
                        },
                        child: const Text("Download PDF"),
                      ),
                    ],
                    child: _productionVsConsumptionItemGroupWise(screenWidth),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Production vs Consumption - Item Sub Group Wise',
                    spacing: 20,
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
                                    color: Color.fromARGB(255, 10, 153, 5),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 8,
                                    width: 16,
                                    color: Color.fromARGB(255, 145, 59, 99),
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
                                "Production",
                                textAlign: TextAlign.left,
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(
                                "Consumption",
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
                          setState(() {
                            generateItemSubGroupwiseProductionVsConsumtionExcel(
                              itemSubGroupWiseProductionData,
                              itemSubGroupWiseConsumptionData,
                            );
                          });
                        },
                        child: const Text("Download Excel"),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          setState(() {
                            generateItemSubGroupwiseProductionVsConsumtionPDF(
                              itemSubGroupWiseProductionData,
                              itemSubGroupWiseConsumptionData,
                            );
                          });
                        },
                        child: const Text("Download PDF"),
                      ),
                    ],
                    child: _productionVsConsumptionItemSubGroupWise(
                      screenWidth,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Production vs Consumption - Warehouse Wise',
                    spacing: 20,
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
                                    color: Color.fromARGB(255, 10, 153, 5),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 8,
                                    width: 16,
                                    color: Color.fromARGB(255, 145, 59, 99),
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
                                "Production",
                                textAlign: TextAlign.left,
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(
                                "Consumption",
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
                          setState(() {
                            generateWarehousewiseProductionVsConsumtionExcel(
                              warehouseProductionList,
                              warehouseConsumptionList,
                            );
                          });
                        },
                        child: const Text("Download Excel"),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          setState(() {
                            generateWarehousewiseProductionVsConsumtionPDF(
                              warehouseProductionList,
                              warehouseConsumptionList,
                            );
                          });
                        },
                        child: const Text("Download PDF"),
                      ),
                    ],
                    child: _productionVsConsumptionWarehouseWise(screenWidth),
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

  Widget _productionVsConsumptionMonthly(double screenWidth) {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = productionData.productionData.length;
    if (len > 5) {
      chartWidth = screenWidth + (42 * len);
    } else {
      chartWidth = screenWidth;
    }
    return FinanceHorizontalChartScroll(
      controller: _monthWiseHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(monthWiseMaxY),
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
                  sideTitles: _bottomTitlesProductionVsConsumptionProduction,
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
              barGroups: _productionVsConsumptionMonthlyChartData(
                productionData.productionData,
                consumptionData.consumptionData,
              ),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    touchedMonth = productionData
                        .productionData[barTouchResponse.spot!.spot.x.toInt()]
                        .monthName;
                    List months = [
                      'Jan',
                      'Feb',
                      'Mar',
                      'Apr',
                      'May',
                      'Jun',
                      'Jul',
                      'Aug',
                      'Sep',
                      'Oct',
                      'Nov',
                      'Dec',
                    ];
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedMonthIndex = (touchedMonthIndex == 0
                          ? months.indexOf(touchedMonth.substring(0, 3)) + 1
                          : 0);
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      await loadDataWithFilter(
                        touchedMonthIndex,
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedWarehouse,
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
                    // Retrieve both Production and Consumption data for the current month
                    String monthName =
                        productionData.productionData[grpIndex].monthName;
                    double production =
                        productionData.productionData[grpIndex].productionQty;
                    double consumption = consumptionData
                        .consumptionData[grpIndex]
                        .consumptionQty;

                    // Create the tooltip content with both values
                    return BarTooltipItem(
                      "$monthName\n", // Display the month name
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: "Production : ${formatAmount(production)}\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: "Consumption : ${formatAmount(consumption)}",
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

  Widget _productionVsConsumptionItemWise(double screenWidth) {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = itemWiseData.itemWiseData.length;
    if (len > 5) {
      chartWidth = screenWidth + (70 * len);
    } else {
      chartWidth = screenWidth;
    }
    Map<String, ItemWiseConsumptionProductAnalysisData> consumptionMap = {
      for (var data in itemWiseConsumptionData.itemWiseConsumptionData)
        data.itemName: data,
    };
    return FinanceHorizontalChartScroll(
      controller: _itemWiseHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(itemWiseMaxY),
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
                  sideTitles: _bottomTitlesItemWiseProduction,
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
              barGroups: _productionVsConsumptionItemWiseChartData(
                itemWiseData.itemWiseData,
                itemWiseConsumptionData.itemWiseConsumptionData,
              ),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedItemCode = touchedItemCode == ""
                          ? itemWiseData
                                .itemWiseData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .itemName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      await loadDataWithFilter(
                        touchedMonthIndex,
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedWarehouse,
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
                    // Retrieve both Production and Consumption data for the current month
                    String itemName =
                        itemWiseData.itemWiseData[grpIndex].itemName;
                    double production =
                        itemWiseData.itemWiseData[grpIndex].productionQty;
                    double consumption =
                        consumptionMap[itemName]?.consumptionQty ?? 0.0;

                    // Create the tooltip content with both values
                    return BarTooltipItem(
                      "$itemName\n", // Display the month name
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: "Production : ${formatAmount(production)}\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: "Consumption : ${formatAmount(consumption)}",
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

  Widget _productionVsConsumptionItemGroupWise(double screenWidth) {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = itemGroupWiseProductionData.itemGroupWiseData.length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    Map<String, ItemGroupWiseConsumptionProductAnalysisData> consumptionMap = {
      for (var data
          in itemGroupWiseConsumptionData.itemGroupWiseConsumptionData)
        data.itemGroupName: data,
    };
    return FinanceHorizontalChartScroll(
      controller: _itemGroupWiseHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(itemGroupMaxY),
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
                  sideTitles: _bottomTitlesItemGroupWiseProduction,
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
              barGroups: _productionVsConsumptionItemGroupWiseChartData(
                itemGroupWiseProductionData.itemGroupWiseData,
                itemGroupWiseConsumptionData.itemGroupWiseConsumptionData,
              ),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedItemGroup = touchedItemGroup == ""
                          ? itemGroupWiseProductionData
                                .itemGroupWiseData[barTouchResponse.spot!.spot.x
                                    .toInt()]
                                .itemGroupName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      await loadDataWithFilter(
                        touchedMonthIndex,
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedWarehouse,
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
                    // Retrieve both Production and Consumption data for the current month
                    String groupName = itemGroupWiseProductionData
                        .itemGroupWiseData[grpIndex]
                        .itemGroupName;
                    double production = itemGroupWiseProductionData
                        .itemGroupWiseData[grpIndex]
                        .productionQty;
                    double consumption =
                        consumptionMap[groupName]?.consumptionQty ?? 0.0;

                    // Create the tooltip content with both values
                    return BarTooltipItem(
                      "$groupName\n",
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: "Production : ${formatAmount(production)}\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: "Consumption : ${formatAmount(consumption)}",
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

  Widget _productionVsConsumptionItemSubGroupWise(double screenWidth) {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len =
        itemSubGroupWiseProductionData.itemSubGroupWiseProductionData.length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    Map<String, ItemSubGroupWiseConsumptionProductAnalysisData>
    consumptionMap = {
      for (var data
          in itemSubGroupWiseConsumptionData.itemSubGroupWiseConsumptionData)
        data.itemSubGroupName: data,
    };
    return FinanceHorizontalChartScroll(
      controller: _itemSubGroupWiseHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(itemSubGroupMaxY),
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
                  sideTitles: _bottomTitlesItemSubGroupWiseProduction,
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
              barGroups: _productionVsConsumptionItemSubGroupWiseChartData(
                itemSubGroupWiseProductionData.itemSubGroupWiseProductionData,
                itemSubGroupWiseConsumptionData.itemSubGroupWiseConsumptionData,
              ),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedItemSubGroup = touchedItemSubGroup == ""
                          ? itemSubGroupWiseProductionData
                                .itemSubGroupWiseProductionData[barTouchResponse
                                    .spot!
                                    .spot
                                    .x
                                    .toInt()]
                                .itemSubGroupName
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      await loadDataWithFilter(
                        touchedMonthIndex,
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedWarehouse,
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
                    // Retrieve both Production and Consumption data for the current month
                    String itemSubGroupName = itemSubGroupWiseProductionData
                        .itemSubGroupWiseProductionData[grpIndex]
                        .itemSubGroupName;
                    double production = itemSubGroupWiseProductionData
                        .itemSubGroupWiseProductionData[grpIndex]
                        .productionQty;
                    double consumption =
                        consumptionMap[itemSubGroupName]?.consumptionQty ?? 0.0;

                    // Create the tooltip content with both values
                    return BarTooltipItem(
                      "$itemSubGroupName\n",
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: "Production : ${formatAmount(production)}\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: "Consumption : ${formatAmount(consumption)}",
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

  Widget _productionVsConsumptionWarehouseWise(double screenWidth) {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = warehouseProductionList.warehouseWiseProductionData.length;
    if (len > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    return FinanceHorizontalChartScroll(
      controller: _warehouseWiseHorizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(warehouseWiseMaxY),
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
                  sideTitles: _bottomTitlesWarehouseWiseProductionAnalysis,
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
              barGroups: _productionVsConsumptionWarehouseWiseChartData(
                warehouseProductionList.warehouseWiseProductionData,
                warehouseConsumptionList.warehouseWiseConsumptionData,
              ),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    if (flTouchEvent is FlTapUpEvent) {
                      touchedWarehouse = touchedWarehouse == ""
                          ? warehouseProductionList
                                .warehouseWiseProductionData[barTouchResponse
                                    .spot!
                                    .spot
                                    .x
                                    .toInt()]
                                .warehouseCode
                          : "";
                      selectedChart = barTouchResponse.spot!.spot.x;
                      showDrillDownChart = true;
                      await loadDataWithFilter(
                        touchedMonthIndex,
                        touchedItemCode,
                        touchedItemGroup,
                        touchedItemSubGroup,
                        touchedWarehouse,
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
                    // Retrieve both Production and Consumption data for the current month
                    String warehouseName = warehouseProductionList
                        .warehouseWiseProductionData[grpIndex]
                        .warehouseName;
                    warehouseName == ""
                        ? warehouseConsumptionList
                              .warehouseWiseConsumptionData[grpIndex]
                              .warehouseName
                        : warehouseName;
                    double production = warehouseProductionList
                        .warehouseWiseProductionData[grpIndex]
                        .productionQty;
                    double consumption = warehouseConsumptionList
                        .warehouseWiseConsumptionData[grpIndex]
                        .consumptionQty;

                    // Create the tooltip content with both values
                    return BarTooltipItem(
                      "$warehouseName\n",
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: "Production : ${formatAmount(production)}\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: "Consumption : ${formatAmount(consumption)}",
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
