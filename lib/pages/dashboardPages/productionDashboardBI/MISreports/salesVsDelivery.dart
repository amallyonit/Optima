// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import '../../../../notificationService.dart';
import '../../dashboard_card_ui.dart';
import '../../ReportService.dart';
import '../../report_service_platform.dart';

class SalesVsDeliveryDetailsMISProvider with ChangeNotifier {
  List<SalesVsProductionMIS> _salesList = [];
  List<SalesVsProductionMIS> get salesList => _salesList;
  void updateInventoryLevelList(List<SalesVsProductionMIS> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class SalesVsDeliveryPage extends StatefulWidget {
  const SalesVsDeliveryPage({super.key});

  @override
  State<SalesVsDeliveryPage> createState() => _SalesVsDeliveryPageState();
}

class _SalesVsDeliveryPageState extends State<SalesVsDeliveryPage> {
  DateTime? selectedDate = DateTime.now();
  final reportService = ReportService();
  late Future<void> loadDataFuture;
  DateTime? currentDate;
  DateTime? fiscalYearStartDate;
  bool chartDataLoaded = false;
  String? formattedFiscalYearStartDate;
  String? formattedDateNow;

  List<InventoryLevelList> stockData = [];
  List<SalesVsProductionMIS> deliveryData = [];
  List<SalesVsProductionMIS> deliveryDataTemp = [];
  List<InventoryLevelList> stockDataTemp = [];

  StockItemList stockStatementData = StockItemList(stockData: []);

  double completedOrders = 0;
  double completedOrdersPercent = 0;
  double completedOrdersPercentage = 0;
  double pendingOrders = 0;
  double pendingOrdersPercent = 0;
  double pendingOrdersPercentage = 0;

  SalesVsProductionPieChartList receivablesCategoryList =
      SalesVsProductionPieChartList(categoryData: []);
  MonthlySalesVsProductionList monthlyData = MonthlySalesVsProductionList(
    monthlyData: [],
  );

  String selectedBranch = "";

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

  void LoadDates() {
    currentDate = DateTime.now();

    int fiscalYearStartMonth = 4;

    int fiscalYear = currentDate!.month >= fiscalYearStartMonth
        ? currentDate!.year
        : currentDate!.year - 1;
    fiscalYearStartDate = DateTime(fiscalYear, fiscalYearStartMonth, 1);

    Map<String, DateTime> monthDates = getMonthStartEndDates(
      selectedDate!.month,
    );
    formattedFiscalYearStartDate = DateFormat(
      'dd/MM/yy',
    ).format(monthDates["start"]!);
    formattedDateNow = DateFormat('dd/MM/yy').format(monthDates["end"]!);
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

  SideTitles get _bottomTitlesMonthlyInventory => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<MonthlySalesVsProductionData> mData = monthlyData.monthlyData;
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

  List<BarChartGroupData> _MonthlyChartData(
    List<MonthlySalesVsProductionData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.noOfOrders,
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

  Future<void> _loadDeliveryDetailsAPI(
    String UserName,
    String UserLevel,
  ) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<SalesVsProductionMIS> salesList = [];
    try {
      do {
        var body = {
          "FromDate": formatDate(fiscalYearStartDate!),
          "ToDate": formatDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}BicxoDeliveryReportList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<SalesVsProductionMIS> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => SalesVsProductionMIS.fromJson(item))
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
        context
            .read<SalesVsDeliveryDetailsMISProvider>()
            .updateInventoryLevelList(salesList);

        deliveryData = salesList.toList();
        deliveryDataTemp = salesList.toList();
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading delivery details.",
      );
    }
  }

  Future<void> _loadSalesVsProduction() async {
    var inventoryList = deliveryData;
    List<SalesVsProductionMIS> customerTargetList = [];

    Map<String, DateTime> monthDates = getMonthStartEndDates(
      selectedDate!.month,
    );

    customerTargetList = inventoryList.where((target) {
      DateTime dueon = DateFormat(
        'dd/MM/yyyy',
      ).parse(target.actualDeliveryDate);
      return dueon.isAtLeast(monthDates["start"]!) &&
          dueon.isAtMost(monthDates['end']!);
    }).toList();

    final int closedCount = customerTargetList
        .where((t) => (t.soStatus).toLowerCase() == 'close')
        .length;

    final int notClosedCount = customerTargetList.length - closedCount;
    final int totalCount = customerTargetList.length;

    completedOrders = closedCount.toDouble();
    pendingOrders = notClosedCount.toDouble();

    completedOrdersPercent = completedOrders == 0
        ? 0.0
        : (pendingOrders * 100.0) / totalCount;

    completedOrdersPercentage = totalCount == 0
        ? 0.0
        : (closedCount * 100.0) / totalCount;
    pendingOrdersPercentage = totalCount == 0
        ? 0.0
        : (notClosedCount * 100.0) / totalCount;

    if (completedOrdersPercentage >= 100) {
      completedOrdersPercentage = 100;
    }
    if (completedOrdersPercent >= 100) {
      completedOrdersPercent = 100;
    }

    final receivablesCategoryListLocal = SalesVsProductionPieChartList(
      categoryData: [
        SalesVsProductionPieChartData(
          categoryId: 1,
          categoryName: 'On Time',
          noOfOrders: 0.0,
        ),
        SalesVsProductionPieChartData(
          categoryId: 2,
          categoryName: 'Orders delayed by 1 to 5 Days',
          noOfOrders: 0.0,
        ),
        SalesVsProductionPieChartData(
          categoryId: 3,
          categoryName: 'Orders delayed by 6 to 10 Days',
          noOfOrders: 0.0,
        ),
        SalesVsProductionPieChartData(
          categoryId: 4,
          categoryName: 'Orders delayed > 10 Days',
          noOfOrders: 0.0,
        ),
      ],
    );

    void incSafe(int categoryId, String categoryName, double inc) {
      final idx = receivablesCategoryListLocal.categoryData.indexWhere(
        (c) => c.categoryId == categoryId,
      );
      if (idx >= 0) {
        receivablesCategoryListLocal.categoryData[idx].noOfOrders += inc;
      } else {
        receivablesCategoryListLocal.categoryData.add(
          SalesVsProductionPieChartData(
            categoryId: categoryId,
            categoryName: categoryName,
            noOfOrders: inc,
          ),
        );
      }
    }

    for (var t in customerTargetList) {
      final rawStatus = (t.status).toString();
      final status = rawStatus.toLowerCase().trim();

      final isOnTime =
          status == 'on time' ||
          status == 'ontime' ||
          (status.contains('on') && status.contains('time'));
      final isDelay =
          status == 'delay' || status == 'delayed' || status.contains('delay');

      if (isOnTime) {
        incSafe(1, 'On Time', 1.0);
        continue;
      }

      if (isDelay) {
        final leadtimeStr = (t.sOtoDDLeadtime).toString();
        final match = RegExp(r'(-?\d+)').firstMatch(leadtimeStr);
        final int days = match != null
            ? (int.tryParse(match.group(0)!) ?? 0)
            : 0;

        if (days >= 1 && days <= 5) {
          incSafe(2, 'Orders delayed by 1 to 5 Days', 1.0);
        } else if (days >= 6 && days <= 10) {
          incSafe(3, 'Orders delayed by 6 to 10 Days', 1.0);
        } else if (days > 10) {
          incSafe(4, 'Orders delayed > 10 Days', 1.0);
        } else {
          incSafe(2, 'Orders delayed by 1 to 5 Days', 1.0);
        }
        continue;
      }
    }

    final double totalOrders = receivablesCategoryListLocal.categoryData.fold(
      0.0,
      (prev, elem) => prev + (elem.noOfOrders),
    );

    if (totalOrders <= 0.0) {
      for (var c in receivablesCategoryListLocal.categoryData) {
        c.noOfOrdersPercentage = 0.0;
      }
    } else {
      for (var c in receivablesCategoryListLocal.categoryData) {
        c.noOfOrdersPercentage = (c.noOfOrders / totalOrders) * 100.0;
      }
    }

    if (mounted) {
      setState(() {
        receivablesCategoryList = receivablesCategoryListLocal;
      });
    } else {
      receivablesCategoryList = receivablesCategoryListLocal;
    }
  }

  DateTime? tryParseDate(String? input) {
    if (input == null || input.trim().isEmpty) return null;

    try {
      return DateFormat('dd/MM/yyyy').parseStrict(input);
    } catch (_) {}

    try {
      return DateFormat('M/d/yyyy h:mm:ss a').parse(input);
    } catch (_) {}

    return DateTime.tryParse(input);
  }

  Future<void> _loadMonthlySalesVsDelivery() async {
    final inventoryList = deliveryData;

    final DateTime selected = selectedDate ?? DateTime.now();

    // Financial year start
    final int fyStartYear = selected.month >= 4
        ? selected.year
        : selected.year - 1;

    List<MonthlySalesVsProductionData> months = [];

    for (int i = 0; i < 12; i++) {
      int month = i < 9 ? i + 4 : i - 8; // 4..12,1..3

      int year = month >= 4 ? fyStartYear : fyStartYear + 1;

      final DateTime monthStart = DateTime(year, month, 1);
      final DateTime monthEnd = DateTime(
        year,
        month + 1,
        1,
      ).subtract(const Duration(days: 1));

      final monthItems = inventoryList.where((target) {
        final DateTime? dueOn = tryParseDate(target.actualDeliveryDate);
        if (dueOn == null) return false;

        return dueOn.isAtLeast(monthStart) && dueOn.isAtMost(monthEnd);
      }).toList();

      final int totalCount = monthItems.length;

      final int closedCount = monthItems
          .where((t) => t.soStatus.toString().toLowerCase().trim() == 'close')
          .length;

      final int pendingCount = totalCount - closedCount;

      months.add(
        MonthlySalesVsProductionData(
          monthName: DateFormat('MMMM').format(monthStart),
          noOfOrders: totalCount.toDouble(),
          completed: closedCount.toDouble(),
          pending: pendingCount.toDouble(),
        ),
      );
    }

    final result = MonthlySalesVsProductionList(monthlyData: months);

    if (mounted) {
      setState(() {
        monthlyData = result;
      });
    } else {
      monthlyData = result;
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

  List<PieChartSectionData> _receivablesCategoryChart() {
    final List<PieChartSectionData> sections = [];
    for (final categoryData in receivablesCategoryList.categoryData) {
      final isTouched = (categoryData.categoryId) == touchedIndex;
      final fontSize = touchedIndex >= 1 ? 12.0 : 11.0;
      final radius = touchedIndex >= 1 ? 80.0 : 75.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      final sectionData = PieChartSectionData(
        color: getCategoryColor(categoryData.categoryId),
        value: categoryData.noOfOrdersPercentage,
        title: '${categoryData.noOfOrdersPercentage?.toStringAsFixed(2)} %',
        radius: radius,
        badgeWidget: isTouched
            ? Visibility(
                visible: isTouched,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Text(""),
                ),
              )
            : null,
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

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    selectedBranch = "All Branches";
    await _loadDeliveryDetailsAPI(userName, userLevel);
    await _loadSalesVsProduction();
    await _loadMonthlySalesVsDelivery();
    chartDataLoaded = true;
  }

  Future<void> loadDataWithBranchFilter(String branch) async {
    selectedBranch = branch;
    await applyFilters();
  }

  Future<void> loadDataWithDateFilter(DateTime date) async {
    selectedDate = date;
    LoadDates();
    await applyFilters();
  }

  Future<void> loadDataClearFilter() async {
    setState(() {
      chartDataLoaded = false;
    });
    selectedDate = currentDate;
    selectedBranch = "All Branches";
    LoadDates();
    await applyFilters();

    setState(() {
      chartDataLoaded = true;
    });
  }

  Future<void> generateWarehouseWiseSalesVsDeliveryExcel() async {
    try {
      final inventoryList = deliveryData;

      Map<String, DateTime> monthDates = getMonthStartEndDates(
        selectedDate!.month,
      );

      final customerTargetList = inventoryList.where((target) {
        final dueOn = tryParseDate(target.actualDeliveryDate);

        if (dueOn == null) return false;

        return dueOn.isAtLeast(monthDates["start"]!) &&
            dueOn.isAtMost(monthDates["end"]!);
      }).toList();

      Map<String, WarehouseSalesSummary> warehouseSummary = {};

      for (var item in customerTargetList) {
        final whs = item.whsCode.trim().isEmpty
            ? "Others"
            : item.whsCode.trim();

        warehouseSummary.putIfAbsent(whs, () => WarehouseSalesSummary());

        final summary = warehouseSummary[whs]!;

        final value = double.tryParse(item.soValue.replaceAll(',', '')) ?? 0;

        summary.totalOrders++;
        summary.totalValue += value;

        final isClosed = item.soStatus.toLowerCase().trim() == "close";

        if (isClosed) {
          summary.deliveredOrders++;
          summary.deliveredValue += value;
        } else {
          summary.pendingOrders++;
          summary.pendingValue += value;
        }

        final status = item.status.toLowerCase().trim();

        if (status.contains("on") && status.contains("time")) {
          summary.onTimeOrders++;
          summary.onTimeValue += value;
        } else if (status.contains("delay")) {
          final match = RegExp(r'(-?\d+)').firstMatch(item.sOtoDDLeadtime);

          final days = match == null ? 0 : int.tryParse(match.group(0)!) ?? 0;

          if (days >= 1 && days <= 5) {
            summary.delay1to5Orders++;
            summary.delay1to5Value += value;
          } else if (days >= 6 && days <= 10) {
            summary.delay6to10Orders++;
            summary.delay6to10Value += value;
          } else if (days > 10) {
            summary.delayAbove10Orders++;
            summary.delayAbove10Value += value;
          }
        }
      }

      final total = WarehouseSalesSummary();

      for (final s in warehouseSummary.values) {
        total.totalOrders += s.totalOrders;
        total.totalValue += s.totalValue;

        total.deliveredOrders += s.deliveredOrders;
        total.deliveredValue += s.deliveredValue;

        total.pendingOrders += s.pendingOrders;
        total.pendingValue += s.pendingValue;

        total.onTimeOrders += s.onTimeOrders;
        total.onTimeValue += s.onTimeValue;

        total.delay1to5Orders += s.delay1to5Orders;
        total.delay1to5Value += s.delay1to5Value;

        total.delay6to10Orders += s.delay6to10Orders;
        total.delay6to10Value += s.delay6to10Value;

        total.delayAbove10Orders += s.delayAbove10Orders;
        total.delayAbove10Value += s.delayAbove10Value;
      }

      warehouseSummary["TOTAL"] = total;

      final warehouses = [
        "TOTAL",
        ...warehouseSummary.keys.where((e) => e != "TOTAL").toList()..sort(),
      ];

      final workbook = xlsio.Workbook();

      final sheet = workbook.worksheets[0];

      sheet.name = "Warehouse Wise Sales Vs Delivery Summary";

      final lastColumn = 2 + (warehouses.length * 3);

      final userName = await reportService.getUserName();

      final now = DateTime.now();

      final formattedDate =
          "${now.day.toString().padLeft(2, '0')}/"
          "${now.month.toString().padLeft(2, '0')}/"
          "${now.year} "
          "${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}";

      sheet.getRangeByIndex(1, 1, 1, lastColumn).merge();

      final reportTitle =
          "Production[MIS] - Warehouse Wise Sales Order vs Delivery - "
          "$selectedBranch - "
          "${DateFormat('MMM yyyy').format(selectedDate!)}";

      final titleText =
          "${ApiHelper.companyName}\n"
          "Optima CRM - $reportTitle";

      sheet.getRangeByIndex(1, 1).setText(titleText);

      sheet.getRangeByIndex(1, 1).cellStyle.wrapText = true;

      sheet.getRangeByIndex(1, 1).cellStyle.bold = true;

      sheet.getRangeByIndex(1, 1).cellStyle.fontSize = 14;

      sheet.getRangeByIndex(1, 1, 1, lastColumn).rowHeight = 53;

      sheet.getRangeByIndex(1, lastColumn).setText("Created: $formattedDate");

      sheet.getRangeByIndex(1, lastColumn).cellStyle.hAlign =
          xlsio.HAlignType.right;

      sheet.getRangeByIndex(1, lastColumn).cellStyle.bold = true;

      sheet.getRangeByIndex(2, 1).setText("User: $userName");

      sheet.getRangeByIndex(3, 1).setText("Sl No");
      sheet.getRangeByIndex(3, 2).setText("Description");

      sheet.getRangeByIndex(3, 1, 4, 1).merge();
      sheet.getRangeByIndex(3, 2, 4, 2).merge();

      int col = 3;

      for (final whs in warehouses) {
        sheet.getRangeByIndex(3, col, 3, col + 2).merge();

        sheet.getRangeByIndex(3, col).setText(whs);

        sheet.getRangeByIndex(4, col).setText("Orders");

        sheet.getRangeByIndex(4, col + 1).setText("Value");

        sheet.getRangeByIndex(4, col + 2).setText("%");

        col += 3;
      }

      final headerRange = sheet.getRangeByIndex(3, 1, 4, lastColumn);

      headerRange.cellStyle.bold = true;
      headerRange.cellStyle.backColor = "#D9EAF7";

      headerRange.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

      void writeRow(
        int row,
        String description,
        double Function(WarehouseSalesSummary) orderFn,
        double Function(WarehouseSalesSummary) valueFn,
      ) {
        sheet.getRangeByIndex(row, 1).setNumber((row - 4).toDouble());

        sheet.getRangeByIndex(row, 2).setText(description);

        int col = 3;

        for (final whs in warehouses) {
          final s = warehouseSummary[whs]!;

          final orders = orderFn(s);
          final value = valueFn(s);

          final percent = s.totalOrders == 0
              ? 0.0
              : (orders * 100) / s.totalOrders;

          sheet.getRangeByIndex(row, col).setNumber(orders);

          sheet.getRangeByIndex(row, col + 1).setNumber(value);

          sheet.getRangeByIndex(row, col + 2).setNumber(percent);

          col += 3;
        }
      }

      int currentRow = 5;

      writeRow(
        currentRow++,
        "Total No. of sales orders for the Month ${DateFormat('MMM yyyy').format(selectedDate!)}",
        (s) => s.totalOrders,
        (s) => s.totalValue,
      );

      writeRow(
        currentRow++,
        "Total No. of orders delivered in the Month ${DateFormat('MMM yyyy').format(selectedDate!)}",
        (s) => s.deliveredOrders,
        (s) => s.deliveredValue,
      );

      writeRow(
        currentRow++,
        "Total No. of Pending delivery's (Transit)",
        (s) => s.pendingOrders,
        (s) => s.pendingValue,
      );

      writeRow(
        currentRow++,
        "No. of Dispatches  Delivered   before /on time",
        (s) => s.onTimeOrders,
        (s) => s.onTimeValue,
      );

      writeRow(
        currentRow++,
        "No. of Dispatches, delivery delayed by 1 to 5 days",
        (s) => s.delay1to5Orders,
        (s) => s.delay1to5Value,
      );

      writeRow(
        currentRow++,
        "No. of orders Dispatches, delivery delayed by 6 to 10 days",
        (s) => s.delay6to10Orders,
        (s) => s.delay6to10Value,
      );

      writeRow(
        currentRow++,
        "No. of Dispatches, delivery delayed above 10 days",
        (s) => s.delayAbove10Orders,
        (s) => s.delayAbove10Value,
      );

      for (int c = 4; c <= lastColumn; c += 3) {
        sheet.getRangeByIndex(5, c, currentRow - 1, c).numberFormat =
            '#,##0.00';
      }

      for (int c = 5; c <= lastColumn; c += 3) {
        sheet.getRangeByIndex(5, c, currentRow - 1, c).numberFormat = '0.00';
      }

      sheet.getRangeByIndex(3, 1, 4, lastColumn).cellStyle.hAlign =
          xlsio.HAlignType.center;

      sheet.getRangeByIndex(3, 1, 4, lastColumn).cellStyle.vAlign =
          xlsio.VAlignType.center;

      sheet
              .getRangeByIndex(3, 1, currentRow - 1, lastColumn)
              .cellStyle
              .borders
              .all
              .lineStyle =
          xlsio.LineStyle.thin;

      sheet.getRangeByIndex(3, 3, currentRow - 1, 5).cellStyle.backColor =
          "#FFF2CC";

      sheet.getRangeByIndex(3, 3, currentRow - 1, 5).cellStyle.bold = true;

      // sheet.freezePanes(5, 3);

      for (int c = 1; c <= lastColumn; c++) {
        sheet.autoFitColumn(c);
      }

      sheet.getRangeByIndex(1, 2).columnWidth = 40;

      final bytes = List<int>.from(workbook.saveAsStream());

      workbook.dispose();

      if (kIsWeb) {
        downloadExcelWeb('warehouse_sales_vs_delivery.xlsx', bytes);
      } else {
        final dir = await getStorageDirectory();

        final file = File('$dir/warehouse_sales_vs_delivery.xlsx');

        await file.writeAsBytes(bytes, flush: true);

        OpenFile.open(file.path);
      }
      // MORE CODE STILL COMING
    } catch (e) {
      debugPrint("Excel Error: $e");
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

  Future<void> generateSalesVsDeliveryExcel(BuildContext context) async {
    await reportService.generateExcel(
      sheetName: 'SalesVsDelivery',
      headers: const ['Description', 'Total Order', '%'],
      rows: [
        [
          "Total No. of sales orders for the Month ${DateFormat('MMM yyyy').format(selectedDate!).toString()}",
          completedOrders + pendingOrders,
          "100%",
        ],
        [
          "Total No. of orders delivered in the Month ${DateFormat('MMM yyyy').format(selectedDate!).toString()}",
          completedOrders,
          "${completedOrdersPercentage.toStringAsFixed(2)} %",
        ],
        [
          "Total No. of Pending delivery's (Transit)",
          pendingOrders,
          "${pendingOrdersPercentage.toStringAsFixed(2)} %",
        ],
        [
          "No. of Dispatches Delivered before /on time",
          receivablesCategoryList.categoryData[0].noOfOrders,
          "${receivablesCategoryList.categoryData[0].noOfOrdersPercentage!.toStringAsFixed(2)} %",
        ],
        [
          "No. of Dispatches, delivery delayed by 1 to 5 days ",
          receivablesCategoryList.categoryData[1].noOfOrders,
          "${receivablesCategoryList.categoryData[1].noOfOrdersPercentage!.toStringAsFixed(2)} %",
        ],
        [
          "No. of Dispatches, delivery delayed above 5days",
          receivablesCategoryList.categoryData[2].noOfOrders,
          "${receivablesCategoryList.categoryData[2].noOfOrdersPercentage!.toStringAsFixed(2)} %",
        ],
        [
          "No. of orders delayed above 10 days",
          receivablesCategoryList.categoryData[3].noOfOrders,
          "${receivablesCategoryList.categoryData[3].noOfOrdersPercentage!.toStringAsFixed(2)} %",
        ],
      ],
      fileName: 'sales_vs_delivery_report.xlsx',
      amountColumns: [],
      addTotalRow: false,
      reportTitle:
          'Production[MIS] - Summary of Sale Order punched vs delivery of $selectedBranch - ${DateFormat('MMM yyyy').format(selectedDate!).toString()}',
    );
  }

  Future<void> selectMonth(BuildContext context) async {
    final DateTime? picked = await showMonthPicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2100),
    );
    if (picked != null &&
        (picked.month != selectedDate!.month ||
            picked.year != selectedDate!.year)) {
      setState(() {
        selectedDate = picked;
        loadDataWithDateFilter(picked);
      });
    }
  }

  Future<void> applyFilters() async {
    completedOrders = 0;
    completedOrdersPercent = 0;
    completedOrdersPercentage = 0;
    pendingOrders = 0;
    pendingOrdersPercent = 0;
    pendingOrdersPercentage = 0;

    chartDataLoaded = false;

    deliveryData = deliveryDataTemp.where((data) {
      final warehouseMatch =
          selectedBranch.isEmpty ||
          selectedBranch == "All Branches" ||
          data.branchName == selectedBranch;

      return warehouseMatch;
    }).toList();

    await _loadSalesVsProduction();
    await _loadMonthlySalesVsDelivery();

    setState(() {
      chartDataLoaded = true;
    });
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

  double getMaxValue(double maxValue, double divVal) {
    return (maxValue / divVal).ceil() * divVal;
  }

  @override
  Widget build(BuildContext context) {
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
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            selectMonth(context);
                          },
                          icon: const Icon(Icons.calendar_month),
                        ),
                        const SizedBox(width: 5),
                        IconButton(
                          onPressed: () {
                            showPopupMenu();
                          },
                          icon: const Icon(Icons.filter_alt_outlined),
                        ),
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateWarehouseWiseSalesVsDeliveryExcel();
                                  });
                                },
                                child: const Row(
                                  children: [Text("Download Excel")],
                                ),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'Sales Vs Delivery',
                    spacing: 10,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateSalesVsDeliveryExcel(context);
                        },
                        child: const Text("Download Excel"),
                      ),
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            BranchDropdown(
                              production: deliveryDataTemp,
                              onChanged: (newValue) {
                                selectedBranch = newValue ?? "All Branches";
                                loadDataWithBranchFilter(newValue!);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // COUNT INDICATOR
                              Column(
                                children: [
                                  CircularPercentIndicator(
                                    arcType: ArcType.HALF,
                                    radius: 70.0,
                                    lineWidth: 27.0,
                                    animation: true,
                                    percent: completedOrdersPercent / 100,
                                    curve: Curves.linear,
                                    circularStrokeCap: CircularStrokeCap.butt,
                                    progressColor: Colors.green,
                                    arcBackgroundColor: Colors.red,
                                    center: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.blue.shade200,
                                        ),
                                      ),
                                      child: const Text(
                                        "Count",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: const Offset(0, -45),
                                    child: Column(
                                      children: [
                                        Text(
                                          "Completed: $completedOrders",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.green,
                                          ),
                                        ),
                                        Text(
                                          "Pending: $pendingOrders",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 40),

                              // PERCENTAGE INDICATOR
                              Column(
                                children: [
                                  CircularPercentIndicator(
                                    arcType: ArcType.HALF,
                                    radius: 70.0,
                                    lineWidth: 27.0,
                                    animation: true,
                                    percent: completedOrdersPercentage / 100,
                                    curve: Curves.linear,
                                    circularStrokeCap: CircularStrokeCap.butt,
                                    progressColor: Colors.green,
                                    arcBackgroundColor: Colors.red,
                                    center: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.purple.shade200,
                                        ),
                                      ),
                                      child: const Text(
                                        "%",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: const Offset(0, -45),
                                    child: Column(
                                      children: [
                                        Text(
                                          "Completed: ${completedOrdersPercentage.toStringAsFixed(2)}%",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.green,
                                          ),
                                        ),
                                        Text(
                                          "Pending: ${pendingOrdersPercentage.toStringAsFixed(2)}%",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Transform.translate(
                          offset: const Offset(0, -45),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  right: 16.0,
                                  bottom: 0.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    SizedBox(
                                      height: 150,
                                      width: 100,
                                      child: PieChart(
                                        PieChartData(
                                          pieTouchData: PieTouchData(
                                            touchCallback:
                                                (
                                                  FlTouchEvent event,
                                                  pieTouchResponse,
                                                ) {
                                                  setState(() {
                                                    if (!event
                                                            .isInterestedForInteractions ||
                                                        pieTouchResponse ==
                                                            null ||
                                                        pieTouchResponse
                                                                .touchedSection ==
                                                            null) {
                                                      touchedIndex = -1;
                                                      return;
                                                    }
                                                    touchedIndex =
                                                        pieTouchResponse
                                                            .touchedSection!
                                                            .touchedSectionIndex;
                                                  });
                                                },
                                          ),
                                          borderData: FlBorderData(show: false),
                                          sectionsSpace: 1,
                                          centerSpaceRadius: 0,
                                          startDegreeOffset: 180,
                                          sections: _receivablesCategoryChart(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -20),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      height: 8,
                                      width: 16,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 8,
                                      width: 16,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 8,
                                      width: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 8,
                                      width: 16,
                                      color: Colors.lightBlue,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "No. orders cleared before/on time: ${receivablesCategoryList.categoryData[0].noOfOrders}",
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    Text(
                                      "No. of orders delayed by 1 to 5 days: ${receivablesCategoryList.categoryData[1].noOfOrders}",
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    Text(
                                      "No. of orders delayed by 6 to 10 days: ${receivablesCategoryList.categoryData[2].noOfOrders}",
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    Text(
                                      "No. of orders delayed > 10 days: ${receivablesCategoryList.categoryData[3].noOfOrders}",
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        _itemSubGroupGraph(),
                      ],
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
      position: const RelativeRect.fromLTRB(25.0, 100.0, 0.0, 0.0),
      elevation: 8.0,
      items: [
        const PopupMenuItem<String>(value: '1', child: Text('Remove Filter?')),
      ],
    ).then((value) {
      if (value == '1') {
        setState(() {
          loadDataFuture = loadDataClearFilter();
        });
      }
    });
  }

  Widget _itemSubGroupGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = monthlyData.monthlyData.length;
    if (monthlyData.monthlyData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? monthlyData.monthlyData
              .map((data) => data.noOfOrders)
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
              maxY: getMaxValue(maxAmount, 500),
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
                  sideTitles: _bottomTitlesMonthlyInventory,
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
              barGroups: _MonthlyChartData(monthlyData.monthlyData),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
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
                      monthlyData.monthlyData[grpIndex].monthName,
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "\nTotal Orders: ${monthlyData.monthlyData[grpIndex].noOfOrders}",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "\nCompleted: ${monthlyData.monthlyData[grpIndex].completed}",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "\nPending : ${monthlyData.monthlyData[grpIndex].pending}",
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

class BranchDropdown extends StatefulWidget {
  final List production;
  final ValueChanged<String?> onChanged;
  final String placeholder;

  const BranchDropdown({
    super.key,
    required this.production,
    required this.onChanged,
    this.placeholder = 'Select Branch',
  });

  @override
  State<BranchDropdown> createState() => _BranchDropdownState();
}

class _BranchDropdownState extends State<BranchDropdown> {
  late final List<String> _items;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _items = _extractBranches(widget.production);
    _selected = _items.isNotEmpty ? _items.first : null;
  }

  List<String> _extractBranches(List list) {
    final seen = <String>{};
    final out = <String>[];
    out.add("All Branches");
    for (var e in list) {
      String val = '';
      try {
        val = (e.branchName ?? '').toString().trim();
      } catch (_) {
        if (e is Map && e.containsKey('branchName')) {
          val = (e['branchName'] ?? '').toString();
        }
      }
      if (val.trim().isEmpty) continue;
      if (!seen.contains(val)) {
        seen.add(val);
        out.add(val);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selected,
              hint: const SizedBox.shrink(),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              items: _items.map((s) {
                return DropdownMenuItem<String>(
                  value: s,
                  child: Text(s, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selected = val;
                });
                widget.onChanged(val);
              },
              isDense: true,
              isExpanded: false,
            ),
          ),
        ],
      ),
      onTap: () {},
    );
  }
}
