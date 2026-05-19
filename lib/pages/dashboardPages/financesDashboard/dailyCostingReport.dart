// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, file_names, use_build_context_synchronously, non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/classes/leads.dart';
import 'package:optima/login_screen.dart';
import '../ReportService.dart';
import 'dart:math';
import 'dart:ui';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:open_file/open_file.dart';
import '../report_service_platform.dart';

class DailyCostingReport extends StatefulWidget {
  const DailyCostingReport({super.key});

  @override
  State<DailyCostingReport> createState() => _DailyCostingReportState();
}

// ---- Models used for isolate I/O ----
class DailyCostingInput {
  final String priority;
  final String warehouse;

  final List<SalesList> sales;
  final List<SODetailsList> soList;
  final List<PurchaseList> purchasePrice;
  final List<GRNList> grnList;
  final List<POList> poListOpen;
  final List<InventoryList> inventory;
  final List<InventoryList> inventoryClosing;
  final List<SalesTargetList> salesTarget;
  final List<StockInTransitList> stockList;

  final DateTime currentMonthFromDate;
  final DateTime currentMonthToDate;
  final DateTime lastMonthFromDate;
  final DateTime lastMonthToDate;
  final DateTime nextMonthFromDate;
  final DateTime nextMonthToDate;
  final DateTime fiscalYearStartDate;
  final DateTime currentDate;

  DailyCostingInput({
    required this.priority,
    required this.warehouse,
    required this.sales,
    required this.soList,
    required this.purchasePrice,
    required this.grnList,
    required this.poListOpen,
    required this.inventory,
    required this.inventoryClosing,
    required this.salesTarget,
    required this.currentMonthFromDate,
    required this.currentMonthToDate,
    required this.lastMonthFromDate,
    required this.lastMonthToDate,
    required this.nextMonthFromDate,
    required this.nextMonthToDate,
    required this.fiscalYearStartDate,
    required this.currentDate,
    required this.stockList,
  });
}

class DailyCostingResult {
  final double monthlySales;
  final double medicalDevicesSales;
  final double ipdSales;
  final double monthlyPurchasePriceSum;
  final double monthlyPurchasePriceGrnSum;
  final double monthlyPOSum;
  final double currentMonthPOSum;
  final double lastMonthPOSum;
  final double nextMonthPOSum;
  final double karnatakaPOSum;
  final double tamilnaduPOSum;
  final double otherbranchPOSum;
  final double inventoryOpeningValue;
  final double inventoryClosingValue;
  final double cogsValue;
  final double inventoryAchieved;
  final double monthlySOvalue;
  final double lowVal;
  final double mediumVal;
  final double highVal;
  final double lessThan30DaysValue;
  final double a30to60DaysValue;
  final double a60to90DaysValue;
  final double a91DaysValue;
  final double medicalDeviceTarget;
  final double ipdTarget;
  final double purchaseTarget;
  final double cogsTarget;
  final double inventoryTarget;
  final double stockInTransitValue;
  final double readyToDispatchStock;
  // the graph arrays (your DailyCostingGraphData type)
  final List<DailyCostingGraphData> revenueGraph;
  final List<DailyCostingGraphData> dailyCostingGraph;
  final List<DailyCostingGraphData> saleOrderPriorityGraph;
  final List<DailyCostingGraphData> saleOrderWarehouseGraph;
  final List<DailyCostingGraphData> inventoryAgingGraph;

  DailyCostingResult({
    required this.monthlySales,
    required this.medicalDevicesSales,
    required this.ipdSales,
    required this.monthlyPurchasePriceSum,
    required this.monthlyPurchasePriceGrnSum,
    required this.monthlyPOSum,
    required this.currentMonthPOSum,
    required this.lastMonthPOSum,
    required this.nextMonthPOSum,
    required this.karnatakaPOSum,
    required this.tamilnaduPOSum,
    required this.otherbranchPOSum,
    required this.inventoryOpeningValue,
    required this.inventoryClosingValue,
    required this.cogsValue,
    required this.inventoryAchieved,
    required this.monthlySOvalue,
    required this.lowVal,
    required this.mediumVal,
    required this.highVal,
    required this.lessThan30DaysValue,
    required this.a30to60DaysValue,
    required this.a60to90DaysValue,
    required this.a91DaysValue,
    required this.medicalDeviceTarget,
    required this.ipdTarget,
    required this.purchaseTarget,
    required this.cogsTarget,
    required this.inventoryTarget,
    required this.revenueGraph,
    required this.dailyCostingGraph,
    required this.saleOrderPriorityGraph,
    required this.saleOrderWarehouseGraph,
    required this.inventoryAgingGraph,
    required this.stockInTransitValue,
    required this.readyToDispatchStock,
  });
}

double monthlySales = 0;
double medicalDevicesSales = 0;
double ipdSales = 0;
double lowVal = 0;
double mediumVal = 0;
double highVal = 0;
double monthlySOvalue = 0;
double monthlyPurchasePriceSum = 0;
double monthlyPurchasePriceGrnSum = 0;
double monthlyPOSum = 0;
double currentMonthPOSum = 0;
double lastMonthPOSum = 0;
double nextMonthPOSum = 0;
double karnatakaPOSum = 0;
double tamilNaduPOSum = 0;
double othersPOSum = 0;
double lessThan30DaysValue = 0;
double a30to60DaysValue = 0;
double a60to90DaysValue = 0;
double a91DaysValue = 0;
double nearExpiryValue = 0;
double expiredValue = 0;
double inventoryOpeningValue = 0;
double inventoryClosingValue = 0;
double cogsValue = 0;
double inventoryAchieved = 0;
double stockInTransitValue = 0;
double readyToDispatchStock = 0;
// ---- Top-level compute function (runs in isolate) ----
DailyCostingResult _computeDailyCostingReport(DailyCostingInput input) {
  // Helper: convert DateTime to milliseconds for fast comparisons
  final int curFrom = input.currentMonthFromDate.millisecondsSinceEpoch;
  final int curTo = input.currentMonthToDate.millisecondsSinceEpoch;
  final int lastFrom = input.lastMonthFromDate.millisecondsSinceEpoch;
  final int lastTo = input.lastMonthToDate.millisecondsSinceEpoch;
  final int nextFrom = input.nextMonthFromDate.millisecondsSinceEpoch;
  final int nextTo = input.nextMonthToDate.millisecondsSinceEpoch;

  // Get current financial year suffix function (same logic as you had)
  String getCurrentFinancialYearSuffix(DateTime now) {
    final year = now.year;
    final month = now.month;
    int startYear = (month >= 4) ? year : year - 1;
    int endYear = startYear + 1;
    return "FY${startYear % 100}-${endYear % 100}-T";
  }

  final currentFY = getCurrentFinancialYearSuffix(input.currentDate);

  // Precompute targets for current month name
  final monthName = (() {
    final m = input.currentDate.month;
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[m];
  })();

  double medicalDeviceTarget = 0;
  double ipdTarget = 0;
  double purchaseTarget = 0;
  double cogsTarget = 0;
  double inventoryTarget = 0;

  for (final t in input.salesTarget) {
    if (t.financialYear == currentFY) {
      final v = double.tryParse(t.getTargetForMonth(monthName)) ?? 0;
      switch (t.salesRep) {
        case "MD SALES TARGET":
          medicalDeviceTarget = v;
          break;
        case "IPD SALES TARGET":
          ipdTarget = v;
          break;
        case "PURCHASE TARGET":
          purchaseTarget = v;
          break;
        case "COGS TARGET":
          cogsTarget = v;
          break;
        case "INVENTORY TARGET":
          inventoryTarget = v;
          break;
      }
    }
  }

  // Fast date parsing: convert record dates to epoch once and sum in single pass where possible

  monthlySales = 0;
  medicalDevicesSales = 0;
  ipdSales = 0;

  for (final s in input.sales) {
    // invoiceDate in format dd/MM/yyyy -- convert safely
    DateTime inv;
    try {
      inv = s.invoiceDate;
    } catch (_) {
      continue;
    }
    final ms = inv.millisecondsSinceEpoch;
    if (ms >= curFrom && ms <= curTo) {
      final row = double.tryParse(s.rowTotal) ?? 0;
      monthlySales += row;
      if (s.itemSubGroup == "Medical Device") {
        medicalDevicesSales += row;
      } else {
        ipdSales += row;
      }
    }
  }

  // Sales order filtering
  final List<SODetailsList> filteredSO = [];
  for (final so in input.soList) {
    if (so.soStatus != "Open") continue;

    if (input.priority.isNotEmpty && so.priority != input.priority) continue;

    if (input.warehouse.isNotEmpty) {
      final w = input.warehouse;
      if (w == "Karnataka State" || w == "Tamil Nadu State") {
        if (so.branchName != w) continue;
      } else if (w == "Others") {
        if (so.branchName == "Karnataka State" ||
            so.branchName == "Tamil Nadu State") {
          continue;
        }
      } else {
        // unknown warehouse selection => skip
        continue;
      }
    }
    filteredSO.add(so);
  }

  lowVal = 0;
  mediumVal = 0;
  highVal = 0;
  karnatakaPOSum = 0;
  tamilNaduPOSum = 0;
  othersPOSum = 0;

  for (final so in filteredSO) {
    final pending = double.tryParse(so.pendingValue) ?? 0;
    monthlySOvalue += pending;
    if (so.priority == "Low") lowVal += pending;
    if (so.priority == "Medium") mediumVal += pending;
    if (so.priority == "High") highVal += pending;

    if (so.branchName == "Karnataka State") {
      karnatakaPOSum += pending;
    } else if (so.branchName == "Tamil Nadu State") {
      tamilNaduPOSum += pending;
    } else {
      othersPOSum += pending;
    }
  }

  // Purchase lists in current month
  monthlyPurchasePriceSum = 0;
  for (final p in input.purchasePrice) {
    DateTime inv;
    try {
      inv = DateFormat('dd/MM/yyyy').parse(p.invoiceDate);
    } catch (_) {
      continue;
    }
    final ms = inv.millisecondsSinceEpoch;
    if (ms >= curFrom && ms <= curTo) {
      monthlyPurchasePriceSum += (double.tryParse(p.rowTotal) ?? 0);
    }
  }

  // GRN sum in current month
  monthlyPurchasePriceGrnSum = 0;
  for (final g in input.grnList) {
    DateTime inv;
    try {
      inv = DateFormat('dd/MM/yyyy').parse(g.grnDate);
    } catch (_) {
      continue;
    }
    final ms = inv.millisecondsSinceEpoch;
    if (ms >= curFrom && ms <= curTo) {
      monthlyPurchasePriceGrnSum += (double.tryParse(g.rowTotal) ?? 0);
    }
  }

  // PO lists partitions
  monthlyPOSum = 0;
  currentMonthPOSum = 0;
  lastMonthPOSum = 0;
  nextMonthPOSum = 0;

  for (final po in input.poListOpen) {
    final pending = double.tryParse(po.pendingValue) ?? 0;
    monthlyPOSum += pending;
    DateTime inv;
    try {
      inv = DateFormat('dd/MM/yyyy').parse(po.expectedTimeofDelivey);
    } catch (_) {
      continue;
    }
    final ms = inv.millisecondsSinceEpoch;
    if (ms >= curFrom && ms <= curTo) {
      currentMonthPOSum += pending;
    } else if (ms >= lastFrom && ms <= lastTo) {
      lastMonthPOSum += pending;
    } else if (ms >= nextFrom && ms <= nextTo) {
      nextMonthPOSum += pending;
    }
  }

  // Inventory ageing buckets
  lessThan30DaysValue = 0;
  a30to60DaysValue = 0;
  a60to90DaysValue = 0;
  nearExpiryValue = 0;
  expiredValue = 0;

  double inventoryOpeningValue = 0;
  for (final it in input.inventory) {
    final val = double.tryParse(it.totalValue) ?? 0;
    final bracket = it.ageingBrackets.trim();
    inventoryOpeningValue += val;

    if (bracket == "<30 Days") {
      lessThan30DaysValue += val;
    } else if (bracket == "31-45 Days" || bracket == "31-60 Days") {
      a30to60DaysValue += val;
    } else if (bracket == "61-90 Days") {
      a60to90DaysValue += val;
    } else if (bracket == "91-120 Days" ||
        bracket == "121-150 Days" ||
        bracket == "151-180 Days" ||
        bracket == "181-365 Days" ||
        bracket == "366-730 Days" ||
        bracket == ">730 Days") {
      a91DaysValue += val;
    }

    if (bracket == "91-120 Days" ||
        bracket == "121-150 Days" ||
        bracket == "151-180 Days") {
      nearExpiryValue += val;
    }

    if (bracket == "181-365 Days" ||
        bracket == "366-730 Days" ||
        bracket == ">730 Days") {
      expiredValue += val;
    }
  }

  inventoryClosingValue = 0;
  for (final it in input.inventoryClosing) {
    inventoryClosingValue += (double.tryParse(it.totalValue) ?? 0);
  }

  // COGS calculation
  cogsValue =
      (inventoryOpeningValue + monthlyPurchasePriceGrnSum) -
      (lessThan30DaysValue +
          a30to60DaysValue +
          a60to90DaysValue +
          nearExpiryValue +
          expiredValue);

  inventoryAchieved =
      lessThan30DaysValue +
      a30to60DaysValue +
      a60to90DaysValue +
      nearExpiryValue +
      expiredValue;

  // Stock in transit
  stockInTransitValue = 0;
  for (final stk in input.stockList) {
    final stkValue = double.tryParse(stk.lineTotal) ?? 0;
    stockInTransitValue += stkValue;
  }

  //Ready to dispatch
  double pendingQty = 0, pendingVal = 0, warehouseQty = 0;
  readyToDispatchStock = 0;
  for (final so in filteredSO) {
    pendingQty = double.tryParse(so.pendingQuantity) ?? 0;
    if (pendingQty == 0) continue;
    pendingVal = double.tryParse(so.pendingValue) ?? 0;
    warehouseQty = double.tryParse(so.warehouseQty) ?? 0;
    if (pendingQty <= warehouseQty) {
      readyToDispatchStock += pendingVal;
    }
  }

  // Build graph data lists (Your DailyCostingGraphData assumed constructor fields)
  final revenueGraph = <DailyCostingGraphData>[];
  revenueGraph.add(
    DailyCostingGraphData(
      name: "Medical Device",
      target: medicalDeviceTarget,
      achievement: medicalDevicesSales,
      percentage: medicalDeviceTarget == 0
          ? 0
          : double.parse(
              ((medicalDevicesSales / medicalDeviceTarget) * 100)
                  .toStringAsFixed(0),
            ),
    ),
  );
  revenueGraph.add(
    DailyCostingGraphData(
      name: "IPD",
      target: ipdTarget,
      achievement: ipdSales,
      percentage: ipdTarget == 0
          ? 0
          : double.parse(((ipdSales / ipdTarget) * 100).toStringAsFixed(0)),
    ),
  );

  final dailyCostingGraph = <DailyCostingGraphData>[];
  final revenueTarget = medicalDeviceTarget + ipdTarget;
  dailyCostingGraph.add(
    DailyCostingGraphData(
      name: "Revenue",
      target: revenueTarget,
      achievement: monthlySales,
      percentage: revenueTarget == 0
          ? 0
          : double.parse(
              ((monthlySales / revenueTarget) * 100).toStringAsFixed(0),
            ),
    ),
  );
  dailyCostingGraph.add(
    DailyCostingGraphData(
      name: "Purchase",
      target: purchaseTarget,
      achievement: monthlyPurchasePriceSum,
      percentage: purchaseTarget == 0
          ? 0
          : double.parse(
              ((monthlyPurchasePriceSum / purchaseTarget) * 100)
                  .toStringAsFixed(0),
            ),
    ),
  );
  dailyCostingGraph.add(
    DailyCostingGraphData(
      name: "Inventory",
      target: inventoryTarget,
      achievement: inventoryAchieved,
      percentage: inventoryTarget == 0
          ? 0
          : double.parse(
              ((inventoryAchieved / inventoryTarget) * 100).toStringAsFixed(0),
            ),
    ),
  );
  dailyCostingGraph.add(
    DailyCostingGraphData(
      name: "COGS",
      target: cogsTarget,
      achievement: cogsValue,
      percentage: cogsTarget == 0
          ? 0
          : double.parse(((cogsValue / cogsTarget) * 100).toStringAsFixed(0)),
    ),
  );

  final saleOrderPriorityGraph = <DailyCostingGraphData>[];
  saleOrderPriorityGraph.add(
    DailyCostingGraphData(
      name: "Low Priority",
      target: 0,
      achievement: lowVal,
      percentage: 0,
    ),
  );
  saleOrderPriorityGraph.add(
    DailyCostingGraphData(
      name: "Medium Priority",
      target: 0,
      achievement: mediumVal,
      percentage: 0,
    ),
  );
  saleOrderPriorityGraph.add(
    DailyCostingGraphData(
      name: "High Priority",
      target: 0,
      achievement: highVal,
      percentage: 0,
    ),
  );

  final saleOrderWarehouseGraph = <DailyCostingGraphData>[];
  saleOrderWarehouseGraph.add(
    DailyCostingGraphData(
      name: "Karnataka State",
      target: 0,
      achievement: karnatakaPOSum,
      percentage: 0,
    ),
  );
  saleOrderWarehouseGraph.add(
    DailyCostingGraphData(
      name: "Tamil Nadu State",
      target: 0,
      achievement: tamilNaduPOSum,
      percentage: 0,
    ),
  );
  saleOrderWarehouseGraph.add(
    DailyCostingGraphData(
      name: "Others",
      target: 0,
      achievement: othersPOSum,
      percentage: 0,
    ),
  );

  final inventoryAgingGraph = <DailyCostingGraphData>[];
  inventoryAgingGraph.add(
    DailyCostingGraphData(
      name: "> 30 Days",
      target: 0,
      achievement: lessThan30DaysValue,
      percentage: 0,
    ),
  );
  inventoryAgingGraph.add(
    DailyCostingGraphData(
      name: "31 - 60 Days",
      target: 0,
      achievement: a30to60DaysValue,
      percentage: 0,
    ),
  );
  inventoryAgingGraph.add(
    DailyCostingGraphData(
      name: "61 - 90 Days",
      target: 0,
      achievement: a60to90DaysValue,
      percentage: 0,
    ),
  );
  inventoryAgingGraph.add(
    DailyCostingGraphData(
      name: "Near Expiry",
      target: 0,
      achievement: nearExpiryValue,
      percentage: 0,
    ),
  );
  inventoryAgingGraph.add(
    DailyCostingGraphData(
      name: "Expired Stock",
      target: 0,
      achievement: expiredValue,
      percentage: 0,
    ),
  );

  return DailyCostingResult(
    monthlySales: monthlySales,
    medicalDevicesSales: medicalDevicesSales,
    ipdSales: ipdSales,
    monthlyPurchasePriceSum: monthlyPurchasePriceSum,
    monthlyPurchasePriceGrnSum: monthlyPurchasePriceGrnSum,
    monthlyPOSum: monthlyPOSum,
    currentMonthPOSum: currentMonthPOSum,
    lastMonthPOSum: lastMonthPOSum,
    nextMonthPOSum: nextMonthPOSum,
    karnatakaPOSum: karnatakaPOSum,
    tamilnaduPOSum: tamilNaduPOSum,
    otherbranchPOSum: othersPOSum,
    inventoryOpeningValue: inventoryOpeningValue,
    inventoryClosingValue: inventoryClosingValue,
    cogsValue: cogsValue,
    inventoryAchieved: inventoryAchieved,
    monthlySOvalue: monthlySOvalue,
    lowVal: lowVal,
    mediumVal: mediumVal,
    highVal: highVal,
    lessThan30DaysValue: lessThan30DaysValue,
    a30to60DaysValue: a30to60DaysValue,
    a60to90DaysValue: a60to90DaysValue,
    a91DaysValue: a91DaysValue,
    medicalDeviceTarget: medicalDeviceTarget,
    ipdTarget: ipdTarget,
    purchaseTarget: purchaseTarget,
    cogsTarget: cogsTarget,
    inventoryTarget: inventoryTarget,
    revenueGraph: revenueGraph,
    dailyCostingGraph: dailyCostingGraph,
    saleOrderPriorityGraph: saleOrderPriorityGraph,
    saleOrderWarehouseGraph: saleOrderWarehouseGraph,
    inventoryAgingGraph: inventoryAgingGraph,
    stockInTransitValue: stockInTransitValue,
    readyToDispatchStock: readyToDispatchStock,
  );
}

class _DailyCostingReportState extends State<DailyCostingReport> {
  final reportService = ReportService();
  late Future<void> loadDataFuture;
  String userLevel = "0";
  List<Users> usersList = [];
  bool chartDataLoadedDailyCosting = false;

  DateTime? currentDate;
  DateTime? yearStartDate;
  DateTime? currentMonthFromDate;
  DateTime? currentMonthToDate;
  DateTime? lastMonthFromDate;
  DateTime? lastMonthToDate;
  DateTime? nextMonthFromDate;
  DateTime? nextMonthToDate;
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

  List<StockInTransitList> stockInTransitList = [];
  List<DebtorsAgingList> debtorsList = [];
  List<CollectionList> collection = [];
  List<SalesList> sales = [];
  List<SalesList> salesTemp = [];
  List<SODetailsList> soList = [];
  List<SODetailsList> soListTemp = [];
  List<PurchaseList> purchasePrice = [];
  List<PurchaseList> purchasePriceTemp = [];
  List<POList> poListOpen = [];
  List<POList> poListOpenTemp = [];
  List<InventoryList> inventory = [];
  List<InventoryList> inventoryClosing = [];
  List<SalesTargetList> salesTarget = [];
  List<GRNList> grnList = [];
  List<GRNList> grnListTemp = [];
  List<ModeOfPaymentList> modeOfPayment = [];
  List<PaymentAnalysisList> payables = [];
  List<MonthlyCogsData> monthlyCogsList = [];
  DailyAnalysisExpensesList purchaseMonthlyData = DailyAnalysisExpensesList(
    dailyData: [],
  );
  CashConversionGraphList monthlyAnalysisData = CashConversionGraphList(
    monthData: [],
  );
  List<MonthlyInventoryData> monthWiseInventory = [];

  double medicalDeviceTarget = 0;
  double ipdTarget = 0;
  double inventoryTarget = 0;
  double purchaseTarget = 0;
  double cogsTarget = 0;

  double pendingSalesOrderBranches = 0;

  double highPriorityPendingSO = 0;
  double mediumPriorityPendingSO = 0;
  double lowPriorityPendingSO = 0;

  double bangalorePendingSO = 0;
  double rajapalayamPendingSO = 0;
  double othersPendingSO = 0;
  double totalPendingSO = 0;

  double lastMonthPO = 0;
  double currentMonthPO = 0;
  double nextMonthPO = 0;
  double totalPendingPO = 0;

  double inventoryLess30Percent = 0;
  double inventory30to60Percent = 0;
  double inventory60to90Percent = 0;
  double inventoryAbove90Percent = 0;
  double stockInTransitPercent = 0;
  double stockInTransitValue = 0;

  double cogsPercentage = 0;
  double cogsTargetPercentage = 0;

  double cashConversionCycleDays = 0;
  double currentCashConversionCycleDays = 0;

  MonthlyCollectionReportList weeklyData = MonthlyCollectionReportList(
    weeklyData: [],
  );
  DailyCostingGraphList dailyCostingData = DailyCostingGraphList(graphData: []);
  DailyCostingGraphList revenueBreakup = DailyCostingGraphList(graphData: []);
  DailyCostingGraphList saleOrderPriorityBreakup = DailyCostingGraphList(
    graphData: [],
  );
  DailyCostingGraphList saleOrderWarehouseBreakup = DailyCostingGraphList(
    graphData: [],
  );
  DailyCostingGraphList inventoryAging = DailyCostingGraphList(graphData: []);

  DateTime? fromDateFilter;
  DateTime? toDateFilter;
  bool dateFilterFlag = false;

  String touchedPriority = "";
  String touchedWarehouse = "";

  bool fromFilter = false;

  Map<String, Map<String, bool>> allCategoriesState = {};

  final List<String> categories = ['Date'];

  List<List<String>> filterOptions = [[]];

  List<String> selectedSalesData = [];

  List<List<bool>> selectedFinanceReceivablesOptions = [];

  List<List<bool>> savedFinanceReceivablesOptionsTemp = [];

  late List<List<bool>> savedFinanceReceivablesOptions = filterOptions
      .map((options) => List<bool>.filled(options.length, false))
      .toList();

  List<StockInTransitList> parseStockList(List<dynamic>? data) {
    if (data == null) {
      return [];
    }
    return data
        .where((e) => e != null)
        .map((e) => StockInTransitList.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<SalesList> parseSalesList(List<dynamic> data) {
    return data.map((e) => SalesList.fromJson(e)).toList();
  }

  List<SODetailsList> parseSOList(List<dynamic> data) {
    return data.map((e) => SODetailsList.fromJson(e)).toList();
  }

  List<PurchaseList> parsePurchaseList(List<dynamic> data) {
    return data.map((e) => PurchaseList.fromJson(e)).toList();
  }

  List<POList> parsePOList(List<dynamic> data) {
    return data.map((e) => POList.fromJson(e)).toList();
  }

  List<InventoryList> parseInventoryList(List<dynamic> data) {
    return data.map((e) => InventoryList.fromJson(e)).toList();
  }

  List<InventoryList> parseInventoryClosingList(List<dynamic> data) {
    return data.map((e) => InventoryList.fromJson(e)).toList();
  }

  List<SalesTargetList> parseSalesTargetList(List<dynamic> data) {
    return data.map((e) => SalesTargetList.fromJson(e)).toList();
  }

  List<GRNList> parseGRNList(List<dynamic> data) {
    return data.map((e) => GRNList.fromJson(e)).toList();
  }

  final ScrollController _verticalScrollController = ScrollController();

  final ScrollController _dailyCostingHorizontalController = ScrollController();

  final ScrollController _revenueHorizontalController = ScrollController();

  final ScrollController _priorityHorizontalController = ScrollController();

  final ScrollController _warehouseHorizontalController = ScrollController();

  final ScrollController _inventoryHorizontalController = ScrollController();

  @override
  void initState() {
    super.initState();

    loadDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadDataFuture = loadData("");
      });
    }
    toDateFilter = currentDate;
    fromDateFilter = fiscalYearStartDate;
  }

  double roundUpTo50Lakhs(double value) {
    const step = 5000000; // 50 lakhs
    return (value / step).ceil() * step.toDouble();
  }

  double roundDownTo50Lakhs(double value) {
    const step = 5000000;
    return (value / step).floor() * step.toDouble();
  }

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
  }

  String getMonthName(int month) {
    final formatter = DateFormat('MMMM');
    return formatter.format(DateTime(2000, month));
  }

  Map<String, DateTime> getMonthStartEndDates(int month) {
    DateTime now = DateTime.now();

    int currentYear = now.year;

    /// Normalize 13,14,15 => 1,2,3
    int actualMonth = month > 12 ? month - 12 : month;

    int yearForMonth;

    if (now.month >= 1 && now.month <= 3) {
      yearForMonth = (actualMonth >= 4 && actualMonth <= 12)
          ? currentYear - 1
          : currentYear;
    } else {
      yearForMonth = (actualMonth >= 4 && actualMonth <= 12)
          ? currentYear
          : currentYear + 1;
    }

    DateTime firstDayOfMonth = DateTime(yearForMonth, actualMonth, 1);

    DateTime lastDayOfMonth = DateTime(yearForMonth, actualMonth + 1, 0);

    return {'start': firstDayOfMonth, 'end': lastDayOfMonth};
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

  void loadDates() {
    currentDate = DateTime.now();
    currentMonthFromDate = DateTime(currentDate!.year, currentDate!.month, 1);
    yearStartDate = DateTime(currentDate!.year, 1, 1);
    currentMonthToDate = addMonth(
      currentMonthFromDate!,
      1,
    ).add(const Duration(days: -1));
    lastMonthFromDate = DateTime(currentDate!.year, currentDate!.month - 1, 1);
    lastMonthToDate = DateTime(currentDate!.year, currentDate!.month, 0);

    nextMonthFromDate = addMonth(
      currentMonthFromDate!,
      1,
    ).add(const Duration(days: 0));
    nextMonthToDate = addMonth(
      nextMonthFromDate!,
      1,
    ).add(const Duration(days: -1));

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

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  SideTitles get _emptyTitlesTop =>
      SideTitles(showTitles: true, getTitlesWidget: getEmptyTopTitle);

  SideTitles get _leftTitles => SideTitles(
    reservedSize: 50,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String leftDouble = "";
      leftDouble = value.toString();
      return Text(
        formatAmount(double.parse(leftDouble)),
        style: const TextStyle(fontSize: 12),
      );
    },
  );

  Widget getEmptyTopTitle(double val, TitleMeta meta) {
    return const Text("");
  }

  SideTitles get _bottomTitlesMonthlyAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      List<DailyCostingGraphData> mData = dailyCostingData.graphData;
      final index = value.toInt();

      if (index < 0 || index >= mData.length) {
        return const SizedBox();
      }

      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(mData[index].name, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesRevenueBreakup => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      List<DailyCostingGraphData> mData = revenueBreakup.graphData;
      final index = value.toInt();

      if (index < 0 || index >= mData.length) {
        return const SizedBox();
      }

      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(mData[index].name, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesSalesOrderPriority => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      List<DailyCostingGraphData> mData = saleOrderPriorityBreakup.graphData;
      final index = value.toInt();

      if (index < 0 || index >= mData.length) {
        return const SizedBox();
      }

      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(mData[index].name, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesSalesOrderWarehouse => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      List<DailyCostingGraphData> mData = saleOrderWarehouseBreakup.graphData;
      final index = value.toInt();

      if (index < 0 || index >= mData.length) {
        return const SizedBox();
      }

      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(mData[index].name, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesInventoryAging => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      List<DailyCostingGraphData> mData = inventoryAging.graphData;
      final index = value.toInt();

      if (index < 0 || index >= mData.length) {
        return const SizedBox();
      }

      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(mData[index].name, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  List<BarChartGroupData> _monthlyAnalysisChartData(
    List<DailyCostingGraphData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.achievement,
                width: 15,
              ),
              BarChartRodData(
                color: const Color(0xFF2CA9DF),
                borderRadius: BorderRadius.zero,
                toY: chartData.target,
                width: 15,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _revenueBreakupChartData(
    List<DailyCostingGraphData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.achievement,
                width: 15,
              ),
              BarChartRodData(
                color: const Color(0xFF2CA9DF),
                borderRadius: BorderRadius.zero,
                toY: chartData.target,
                width: 15,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _pendingSalesOrderChartData(
    List<DailyCostingGraphData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.achievement,
                width: 15,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _pendingSalesOrderWarehouseChartData(
    List<DailyCostingGraphData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.achievement,
                width: 15,
              ),
            ],
          ),
        )
        .toList();
  }

  List<BarChartGroupData> _inventoryAgingChartData(
    List<DailyCostingGraphData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFFFF9F47),
                borderRadius: BorderRadius.zero,
                toY: chartData.achievement,
                width: 15,
              ),
            ],
          ),
        )
        .toList();
  }

  void showBottomToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 30,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.80),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2)).then((_) {
      overlayEntry.remove();
    });
  }

  OverlayEntry? _loadingOverlay;
  void showLoadingOverlay(
    BuildContext context, {
    String message = "Loading...",
  }) {
    if (_loadingOverlay != null) return;

    _loadingOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withValues(alpha: 0.3),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 15),
                  Text(message, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_loadingOverlay!);
  }

  void hideLoadingOverlay() {
    _loadingOverlay?.remove();
    _loadingOverlay = null;
  }

  Future<void> loadData(String selectedUser) async {
    showLoadingOverlay(context, message: "Loading daily costing report...");

    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = selectedUser.isEmpty
          ? prefs.getString('userName') ?? ''
          : selectedUser;

      userLevel = prefs.getString('userLevel') ?? '';

      // Run ALL API calls WITHOUT calling overlay again
      await _loadSales(userName, userLevel);
      await _loadSODetails(userName, userLevel);
      await _loadPurchasePrice(userName, userLevel);
      await _loadPOList(userName, userLevel);
      await _loadInventory(userName, userLevel);
      await _loadInventoryClosing(userName, userLevel);
      await _loadSalesTarget(userName, userLevel);
      await _loadGRN(userName, userLevel);
      await _loadStockInTransitList(userName, userLevel);
      await _loadCollectionTarget(userName, userLevel);
      await _loadCollection(userName, userLevel);
      await _loadPayables(userName, userLevel);
      await _loadModeOfPayment(userName, userLevel);
      await _loadMonthlyInventory(userName, userLevel);
      await _loadMonthlyAnalysisPurchase();
      await _loadMonthlySalesBarCashConversionChartData(userName, userLevel);

      await _loadDailyCostingReport("", "");

      if (!mounted) return;
      setState(() => chartDataLoadedDailyCosting = true);
      hideLoadingOverlay();
      showBottomToast(context, "Dashboard Ready");
    } catch (e) {
      hideLoadingOverlay(); // avoid stuck overlay
      showBottomToast(context, "Failed: $e");
    }
  }

  Future<void> _loadPayables(String UserName, String UserLevel) async {
    int index = 0;
    const int limit = 10000;

    List<PaymentAnalysisList> payablesList = [];

    try {
      final fromDate = dateFilterFlag
          ? formatDate(fromDateFilter!)
          : formatDate(fiscalYearStartDate!);

      final toDate = dateFilterFlag
          ? formatDate(toDateFilter!)
          : formatDate(currentDate!);

      while (true) {
        final body = {
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        const apiUrl = '${ApiHelper.baseUrl}BicxoCreditorsAgingList';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode != 200) break;

        final responseJson = jsonDecode(response.body);
        final data = responseJson['responseData'] as List?;

        if (data == null || data.isEmpty) break;

        final newList = data
            .map((item) => PaymentAnalysisList.fromJson(item))
            .toList();

        payablesList.addAll(newList);

        if (newList.length < limit) break;

        index++;
      }

      if (!mounted) return;

      setState(() {
        payables = payablesList;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Error: $e'),
        ),
      );
    }
  }

  Future<void> _loadCollectionTarget(String UserName, String UserLevel) async {
    int index = 0;
    const int limit = 10000;
    List<DebtorsAgingList> targetList = [];

    try {
      while (true) {
        final body = {
          "FromDate": dateFilterFlag
              ? formatDate(fromDateFilter!)
              : formatDate(fiscalYearStartDate!),
          "ToDate": dateFilterFlag
              ? formatDate(toDateFilter!)
              : formatDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        const apiUrl = '${ApiHelper.baseUrl}Bicxo_DebtorsAgingList';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode != 200) break;

        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        final data = responseJson['responseData'] as List?;

        if (data == null || data.isEmpty) break;

        final newList = data
            .map((item) => DebtorsAgingList.fromJson(item))
            .toList();

        targetList.addAll(newList);

        if (newList.length < limit) break;

        index++;
      }

      if (!mounted) return;

      setState(() {
        debtorsList = targetList;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Error: $e'),
        ),
      );
    }
  }

  Future<void> _loadCollection(String UserName, String UserLevel) async {
    int index = 0;
    const int limit = 10000;

    List<CollectionList> collectionList = [];

    try {
      final DateTime fromDate = dateFilterFlag
          ? fromDateFilter!
          : fiscalYearStartDate!;
      final prevDate = DateTime(fromDate.year, fromDate.month - 1, 1);

      final prevStart = DateTime(prevDate.year, prevDate.month, 1);

      final toDate = dateFilterFlag
          ? formatDate(toDateFilter!)
          : formatDate(currentDate!);

      while (true) {
        final body = {
          "FromDate": formatDate(prevStart),
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        const apiUrl = '${ApiHelper.baseUrl}CRMCollectionAnalysisList';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode != 200) break;

        final responseJson = jsonDecode(response.body);
        final data = responseJson['responseData'] as List?;

        if (data == null || data.isEmpty) break;

        final newList = data
            .map((item) => CollectionList.fromJson(item))
            .toList();

        collectionList.addAll(newList);

        if (newList.length < limit) break;

        index++;
      }

      if (!mounted) return;

      setState(() {
        collection = collectionList;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Error: $e'),
        ),
      );
    }
  }

  Future<void> _loadSales(String userName, String userLevel) async {
    int index = 0;
    const int limit = 10000;
    int fetchedCount = 0;

    List<SalesList> salesList = [];

    final fromDate = dateFilterFlag
        ? formatDate(fromDateFilter!)
        : formatDate(fiscalYearStartDate!);

    final toDate = dateFilterFlag
        ? formatDate(toDateFilter!)
        : formatDate(currentDate!);

    const apiUrl = '${ApiHelper.baseUrl}Crm_SalesList';

    try {
      do {
        final body = {
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        http.Response? response;

        // Retry logic
        for (int retry = 0; retry < 3; retry++) {
          try {
            response = await http
                .post(
                  Uri.parse(apiUrl),
                  headers: {HttpHeaders.contentTypeHeader: 'application/json'},
                  body: jsonEncode(body),
                )
                .timeout(const Duration(seconds: 25));

            if (response.statusCode == 200) break;
            if (response.statusCode == 502 || response.statusCode == 504) {
              await Future.delayed(const Duration(seconds: 2));
              continue;
            }
            break;
          } catch (_) {
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
        }

        if (response!.statusCode == 200) {
          final jsonMap = jsonDecode(response.body);
          final data = jsonMap["responseData"] ?? [];

          if (data == null || (data is List && data.isEmpty)) {
            fetchedCount = 0;
          } else {
            final parsed = parseSalesList(data);
            salesList.addAll(parsed);
            fetchedCount = parsed.length;
            index++;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      // UPDATE UI
      if (!mounted) return;

      setState(() {
        if (sales.isEmpty) {
          sales = salesList;
          salesTemp = salesList;
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Sales load failed: $e")));
    }
  }

  Future<void> _loadSODetails(String userName, String userLevel) async {
    int index = 0;
    const int limit = 10000;
    int fetchedCount = 0;

    List<SODetailsList> soDetailList = [];

    final fromDate = dateFilterFlag
        ? formatDate(fromDateFilter!)
        : formatDate(addMonth(fiscalYearStartDate!, -4));

    final toDate = dateFilterFlag
        ? formatDate(toDateFilter!)
        : formatDate(currentDate!);

    const apiUrl = '${ApiHelper.baseUrl}CRM_SOList';

    try {
      do {
        final body = {
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        late http.Response response;

        // Retry loop with timeout
        for (int retry = 0; retry < 3; retry++) {
          try {
            response = await http
                .post(
                  Uri.parse(apiUrl),
                  headers: {HttpHeaders.contentTypeHeader: 'application/json'},
                  body: jsonEncode(body),
                )
                .timeout(const Duration(seconds: 25));

            if (response.statusCode == 200) break;

            // Retry only on gateway issues
            if (response.statusCode == 502 || response.statusCode == 504) {
              await Future.delayed(const Duration(seconds: 2));
              continue;
            }

            break;
          } catch (_) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }

        if (response.statusCode == 200) {
          final jsonMap = jsonDecode(response.body);
          final List<dynamic>? data = jsonMap["responseData"] ?? [];

          if (data == null || data.isEmpty) {
            fetchedCount = 0;
          } else {
            final parsed = parseSOList(data);
            soDetailList.addAll(parsed);
            fetchedCount = parsed.length;
            index++;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      if (!mounted) return;

      // UPDATE UI
      setState(() {
        // Filter only open SO documents
        soListTemp = soDetailList
            .where((test) => test.soStatus == "Open")
            .toList();

        if (soList.isEmpty) {
          soList = List.from(soListTemp);
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("SO Details load failed: $e")));
    }
  }

  Future<void> _loadPurchasePrice(String userName, String userLevel) async {
    int index = 0;
    const int limit = 10000;
    int fetchedCount = 0;

    List<PurchaseList> purchaseList = [];

    final fromDate = dateFilterFlag
        ? formatDate(fromDateFilter!)
        : formatDate(fiscalYearStartDate!);

    final toDate = dateFilterFlag
        ? formatDate(toDateFilter!)
        : formatDate(currentDate!);

    const apiUrl = '${ApiHelper.baseUrl}BicxoPurchaseList';

    try {
      do {
        final body = {
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        late http.Response response;

        // Retry mechanism
        for (int retry = 0; retry < 3; retry++) {
          try {
            response = await http
                .post(
                  Uri.parse(apiUrl),
                  headers: {HttpHeaders.contentTypeHeader: 'application/json'},
                  body: jsonEncode(body),
                )
                .timeout(const Duration(seconds: 25));

            if (response.statusCode == 200) break;

            if (response.statusCode == 502 || response.statusCode == 504) {
              await Future.delayed(const Duration(seconds: 2));
              continue;
            }

            break;
          } catch (_) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }

        if (response.statusCode == 200) {
          final jsonMap = jsonDecode(response.body);
          final List<dynamic>? data = jsonMap["responseData"] ?? [];

          if (data == null || data.isEmpty) {
            fetchedCount = 0;
          } else {
            final parsed = parsePurchaseList(data);
            purchaseList.addAll(parsed);
            fetchedCount = parsed.length;
            index++;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      // Update UI safely
      if (!mounted) return;

      setState(() {
        if (purchasePrice.isEmpty) {
          purchasePrice = List.from(purchaseList);
        }

        purchasePriceTemp = List.from(purchaseList);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text("Purchase price load failed: $e"),
        ),
      );
    }
  }

  Future<void> _loadPOList(String userName, String userLevel) async {
    int index = 0;
    const int limit = 10000;
    int fetchedCount = 0;

    List<POList> poItems = [];

    final toDate = dateFilterFlag
        ? formatDate(toDateFilter!)
        : formatDate(currentDate!);

    const apiUrl = '${ApiHelper.baseUrl}BicxoPOList';

    try {
      do {
        final body = {
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        late http.Response response;

        // RETRY SAFE NETWORK CALL
        for (int retry = 0; retry < 3; retry++) {
          try {
            response = await http
                .post(
                  Uri.parse(apiUrl),
                  headers: {HttpHeaders.contentTypeHeader: 'application/json'},
                  body: jsonEncode(body),
                )
                .timeout(const Duration(seconds: 25));

            if (response.statusCode == 200) break;

            if (response.statusCode == 502 || response.statusCode == 504) {
              await Future.delayed(const Duration(seconds: 2));
              continue;
            }

            break;
          } catch (_) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }

        if (response.statusCode == 200) {
          final jsonMap = jsonDecode(response.body);
          final List<dynamic>? data = jsonMap["responseData"] ?? [];

          if (data == null || data.isEmpty) {
            fetchedCount = 0;
          } else {
            final parsed = parsePOList(data);
            poItems.addAll(parsed);
            fetchedCount = parsed.length;
            index++;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      if (!mounted) return;

      // UPDATE UI
      setState(() {
        // Filter open PO only once
        if (poListOpen.isEmpty) {
          final openList = poItems.where((p) {
            return p.poStatus == "Open" && p.groupName != "Fixed Assets";
          }).toList();

          poListOpen = openList;
          poListOpenTemp = List.from(openList);
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text("PO List load failed: $e"),
        ),
      );
    }
  }

  Future<void> _loadInventory(String userName, String userLevel) async {
    int index = 0;
    const int limit = 10000;
    int fetchedCount = 0;

    List<InventoryList> inventoryList = [];

    final toDate = dateFilterFlag
        ? formatDate(toDateFilter!)
        : formatDate(lastMonthToDate!);

    const apiUrl = '${ApiHelper.baseUrl}BicxoInventoryAgeingList';

    try {
      do {
        final body = {
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        late http.Response response;

        // Retry 3 times on network/server errors
        for (int retry = 0; retry < 3; retry++) {
          try {
            response = await http
                .post(
                  Uri.parse(apiUrl),
                  headers: {HttpHeaders.contentTypeHeader: 'application/json'},
                  body: jsonEncode(body),
                )
                .timeout(const Duration(seconds: 25));

            if (response.statusCode == 200) break;

            // retry only on temporary server errors
            if (response.statusCode == 502 || response.statusCode == 504) {
              await Future.delayed(const Duration(seconds: 2));
              continue;
            }

            break;
          } catch (_) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }

        if (response.statusCode == 200) {
          final jsonMap = jsonDecode(response.body);
          final List<dynamic>? data = jsonMap["responseData"] ?? [];

          if (data == null || data.isEmpty) {
            fetchedCount = 0;
          } else {
            final parsed = parseInventoryList(data);
            inventoryList.addAll(parsed);
            fetchedCount = parsed.length;
            index++;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      if (!mounted) return;

      setState(() {
        // Assign once per level
        if (inventory.isEmpty) {
          inventory = List.from(inventoryList);
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text("Inventory loading failed: $e"),
        ),
      );
    }
  }

  Future<void> _loadInventoryClosing(String userName, String userLevel) async {
    int index = 0;
    const int limit = 10000;
    int fetchedCount = 0;

    List<InventoryList> closingList = [];

    final toDate = dateFilterFlag
        ? formatDate(toDateFilter!)
        : formatDate(currentDate!);

    const apiUrl = '${ApiHelper.baseUrl}BicxoInventoryAgeingList';

    try {
      do {
        final body = {
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        late http.Response response;

        // Robust retry logic
        for (int retry = 0; retry < 3; retry++) {
          try {
            response = await http
                .post(
                  Uri.parse(apiUrl),
                  headers: {HttpHeaders.contentTypeHeader: 'application/json'},
                  body: jsonEncode(body),
                )
                .timeout(const Duration(seconds: 25));

            if (response.statusCode == 200) break;

            if (response.statusCode == 502 || response.statusCode == 504) {
              await Future.delayed(const Duration(seconds: 2));
              continue;
            }

            break;
          } catch (_) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }

        if (response.statusCode == 200) {
          final jsonMap = jsonDecode(response.body);
          final List<dynamic>? data = jsonMap["responseData"] ?? [];

          if (data == null || data.isEmpty) {
            fetchedCount = 0;
          } else {
            final parsed = parseInventoryClosingList(data);
            closingList.addAll(parsed);
            fetchedCount = parsed.length;
            index++;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      if (!mounted) return;

      // UPDATE UI
      setState(() {
        // Assign once for all user levels
        if (inventoryClosing.isEmpty) {
          inventoryClosing = List.from(closingList);
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text("Inventory Closing load failed: $e"),
        ),
      );
    }
  }

  Future<void> _loadSalesTarget(String userName, String userLevel) async {
    final fromDate = dateFilterFlag
        ? formatDate(fromDateFilter!)
        : formatDate(fiscalYearStartDate!);

    final toDate = dateFilterFlag
        ? formatDate(toDateFilter!)
        : formatDate(currentDate!);

    final body = {
      "FromDate": fromDate,
      "ToDate": toDate,
      "Index": 0,
      "Limit": 0,
      "sapToken": DataManager.readSapToken(),
    };

    const apiUrl = '${ApiHelper.baseUrl}BicxoSalesTargetList';

    try {
      late http.Response response;

      // Retry for network/504/502 issues
      for (int retry = 0; retry < 3; retry++) {
        try {
          response = await http
              .post(
                Uri.parse(apiUrl),
                headers: {HttpHeaders.contentTypeHeader: 'application/json'},
                body: jsonEncode(body),
              )
              .timeout(const Duration(seconds: 25));

          if (response.statusCode == 200) break;

          if (response.statusCode == 502 || response.statusCode == 504) {
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }

          break; // other errors → stop retry
        } catch (_) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      // Handle token expiration
      if (response.statusCode == 401 ||
          response.body.contains("Invalid or Expired Token")) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 2),
            content: Text("Token expired. Please login again."),
          ),
        );
        navigateToLoginScreen();
        return;
      }

      if (response.statusCode != 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load sales target.")),
        );
        return;
      }

      final jsonMap = jsonDecode(response.body);

      final List<dynamic>? data = jsonMap["responseData"] ?? [];

      if (data == null || data.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No sales target data found.")),
        );
        return;
      }

      final parsedList = parseSalesTargetList(data);
      if (!mounted) return;

      // UPDATE UI
      setState(() {
        salesTarget = List.from(parsedList); // applies to all user levels
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SAP server down. Please try again later.'),
        ),
      );
    }
  }

  Future<void> _loadGRN(String userName, String userLevel) async {
    int index = 0;
    const int limit = 10000;
    int fetchedCount = 0;

    List<GRNList> grnItems = [];

    final fromDate = dateFilterFlag
        ? formatDate(fromDateFilter!)
        : formatDate(fiscalYearStartDate!);

    final toDate = dateFilterFlag
        ? formatDate(toDateFilter!)
        : formatDate(currentDate!);

    const apiUrl = '${ApiHelper.baseUrl}BicxoGoodsReceiptNoteList';

    try {
      do {
        final body = {
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        late http.Response response;

        // Retry block for network issues
        for (int retry = 0; retry < 3; retry++) {
          try {
            response = await http
                .post(
                  Uri.parse(apiUrl),
                  headers: {HttpHeaders.contentTypeHeader: 'application/json'},
                  body: jsonEncode(body),
                )
                .timeout(const Duration(seconds: 25));

            if (response.statusCode == 200) break;

            // retry for temporary server errors
            if (response.statusCode == 502 || response.statusCode == 504) {
              await Future.delayed(const Duration(seconds: 2));
              continue;
            }

            break; // stop retry for other errors
          } catch (_) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }

        if (response.statusCode == 200) {
          final jsonMap = jsonDecode(response.body);
          final List<dynamic>? data = jsonMap["responseData"] ?? [];

          if (data == null || data.isEmpty) {
            fetchedCount = 0;
          } else {
            final parsed = parseGRNList(data);
            grnItems.addAll(parsed);
            fetchedCount = parsed.length;
            index++;
          }
        } else {
          fetchedCount = 0; // stop loop
        }
      } while (fetchedCount == limit);

      if (!mounted) return;

      setState(() {
        // Assign once (same for all user levels)
        if (grnList.isEmpty) {
          grnList = List.from(grnItems);
        }

        grnListTemp = List.from(grnItems);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text("GRN loading failed: $e"),
        ),
      );
    }
  }

  Future<void> _loadStockInTransitList(
    String userName,
    String userLevel,
  ) async {
    int index = 0;
    const int limit = 10000;
    int fetchedCount = 0;

    List<StockInTransitList> stkList = [];

    const apiUrl = '${ApiHelper.baseUrl}CRM_StockTransitReport';

    try {
      do {
        final body = {
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        http.Response? response;

        // Retry logic
        for (int retry = 0; retry < 3; retry++) {
          try {
            response = await http
                .post(
                  Uri.parse(apiUrl),
                  headers: {HttpHeaders.contentTypeHeader: 'application/json'},
                  body: jsonEncode(body),
                )
                .timeout(const Duration(seconds: 25));

            if (response.statusCode == 200) break;
            if (response.statusCode == 502 || response.statusCode == 504) {
              await Future.delayed(const Duration(seconds: 2));
              continue;
            }
            break;
          } catch (_) {
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
        }

        if (response!.statusCode == 200) {
          final jsonMap = jsonDecode(response.body);
          final data = jsonMap["responseData"] ?? [];

          if (data == null || (data is List && data.isEmpty)) {
            fetchedCount = 0;
          } else {
            final parsed = parseStockList(data);
            stkList.addAll(parsed);
            fetchedCount = parsed.length;
            index++;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      // UPDATE UI
      if (!mounted) return;

      setState(() {
        if (stkList.isEmpty) {
          stockInTransitList = stkList;
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Stock in transit load failed: $e")),
      );
    }
  }

  Future<void> _loadDailyCostingReport(
    String priority,
    String warehouse,
  ) async {
    final input = DailyCostingInput(
      stockList: stockInTransitList,
      priority: priority,
      warehouse: warehouse,
      sales: sales,
      soList: soList,
      purchasePrice: purchasePrice,
      grnList: grnList,
      poListOpen: poListOpen,
      inventory: inventory,
      inventoryClosing: inventoryClosing,
      salesTarget: salesTarget,
      currentMonthFromDate: currentMonthFromDate!,
      currentMonthToDate: currentMonthToDate!,
      lastMonthFromDate: lastMonthFromDate!,
      lastMonthToDate: lastMonthToDate!,
      nextMonthFromDate: nextMonthFromDate!,
      nextMonthToDate: nextMonthToDate!,
      fiscalYearStartDate: fiscalYearStartDate!,
      currentDate: currentDate!,
    );

    try {
      final DailyCostingResult result =
          await compute<DailyCostingInput, DailyCostingResult>(
            _computeDailyCostingReport,
            input,
          );

      // Apply result back to UI (only small work on main thread)
      if (!mounted) {
        hideLoadingOverlay(); // clean up
        return;
      }

      setState(() {
        // numeric totals
        monthlySales = result.monthlySales;
        medicalDevicesSales = result.medicalDevicesSales;
        ipdSales = result.ipdSales;
        monthlyPurchasePriceSum = result.monthlyPurchasePriceSum;
        monthlyPurchasePriceGrnSum = result.monthlyPurchasePriceGrnSum;
        monthlyPOSum = result.monthlyPOSum;
        currentMonthPOSum = result.currentMonthPOSum;
        lastMonthPOSum = result.lastMonthPOSum;
        nextMonthPOSum = result.nextMonthPOSum;
        inventoryOpeningValue = result.inventoryOpeningValue;
        inventoryClosingValue = result.inventoryClosingValue;
        cogsValue = result.cogsValue;
        inventoryAchieved = result.inventoryAchieved;

        monthlySOvalue = result.monthlySOvalue;
        lowVal = result.lowVal;
        mediumVal = result.mediumVal;
        highVal = result.highVal;

        lessThan30DaysValue = result.lessThan30DaysValue;
        a30to60DaysValue = result.a30to60DaysValue;
        a60to90DaysValue = result.a60to90DaysValue;
        a91DaysValue = result.a91DaysValue;
        stockInTransitValue = result.stockInTransitValue;

        medicalDeviceTarget = result.medicalDeviceTarget;
        ipdTarget = result.ipdTarget;
        purchaseTarget = result.purchaseTarget;
        cogsTarget = result.cogsTarget;
        inventoryTarget = result.inventoryTarget;

        pendingSalesOrderBranches = monthlySOvalue;

        highPriorityPendingSO = highVal;
        mediumPriorityPendingSO = mediumVal;
        lowPriorityPendingSO = lowVal;

        totalPendingSO =
            highPriorityPendingSO +
            mediumPriorityPendingSO +
            lowPriorityPendingSO;

        bangalorePendingSO = result.karnatakaPOSum;
        rajapalayamPendingSO = result.tamilnaduPOSum;
        othersPendingSO = result.otherbranchPOSum;

        lastMonthPO = 0;
        currentMonthPO = currentMonthPOSum;
        nextMonthPO = 0;

        totalPendingPO = lastMonthPO + currentMonthPO + nextMonthPO;

        inventoryLess30Percent = inventoryAchieved == 0
            ? 0
            : (lessThan30DaysValue / inventoryAchieved) * 100;

        inventory30to60Percent = inventoryAchieved == 0
            ? 0
            : (a30to60DaysValue / inventoryAchieved) * 100;

        inventory60to90Percent = inventoryAchieved == 0
            ? 0
            : (a60to90DaysValue / inventoryAchieved) * 100;

        inventoryAbove90Percent = inventoryAchieved == 0
            ? 0
            : (a91DaysValue / inventoryAchieved) * 100;

        stockInTransitPercent = inventoryAchieved == 0
            ? 0
            : (stockInTransitValue / inventoryAchieved) * 100;

        cogsPercentage = cogsTarget == 0 ? 0 : (cogsValue / cogsTarget) * 100;
        cogsTargetPercentage = cogsTarget == 0
            ? 0
            : (cogsTarget / (medicalDeviceTarget + ipdTarget)) * 100;

        cashConversionCycleDays = currentCashConversionCycleDays;

        readyToDispatchStock = result.readyToDispatchStock;

        // graphs — replace your graph data lists with the computed ones
        revenueBreakup.graphData = result.revenueGraph;
        dailyCostingData.graphData = result.dailyCostingGraph;
        saleOrderPriorityBreakup.graphData = result.saleOrderPriorityGraph;
        saleOrderWarehouseBreakup.graphData = result.saleOrderWarehouseGraph;
        inventoryAging.graphData = result.inventoryAgingGraph;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Daily costing failed: $e")));
      }
    } finally {
      hideLoadingOverlay();
    }
  }

  List<Map<String, DateTime>> getWeeksOfCurrentMonth() {
    DateTime now = DateTime.now();
    int year = now.year;
    int month = now.month;

    // Get the first and last day of the month
    DateTime firstDay = DateTime(year, month, 1);
    DateTime lastDay = DateTime(year, month + 1, 0); // Last day of the month

    List<Map<String, DateTime>> weeks = [];

    DateTime startOfWeek = firstDay;
    while (startOfWeek.isBefore(lastDay) ||
        startOfWeek.isAtSameMomentAs(lastDay)) {
      DateTime endOfWeek = startOfWeek.add(
        Duration(days: 6 - startOfWeek.weekday + 1),
      );
      if (endOfWeek.isAfter(lastDay)) {
        endOfWeek = lastDay;
      }

      weeks.add({"start": startOfWeek, "end": endOfWeek});

      startOfWeek = endOfWeek.add(const Duration(days: 1));
    }

    return weeks;
  }

  Future<void> generateDailyCostingReport() async {
    double safeNum(num? v) => v?.toDouble() ?? 0;

    double safePercent(num? value, num? target) {
      final v = safeNum(value);
      final t = safeNum(target);
      if (t == 0) return 0;
      return (v / t) * 100;
    }

    // ================= CALCULATIONS =================
    double totalTarget = safeNum(medicalDeviceTarget) + safeNum(ipdTarget);

    // ================= HEADERS =================
    final headers = ["Category", "Target", "Achievement", "%"];

    // ================= ROWS =================
    final rows = <List<dynamic>>[
      // ===== REVENUE =====
      [
        "Revenue",
        totalTarget,
        safeNum(monthlySales),
        safePercent(monthlySales, totalTarget),
      ],
      [
        "  Medical Devices",
        safeNum(medicalDeviceTarget),
        safeNum(medicalDevicesSales),
        safePercent(medicalDevicesSales, medicalDeviceTarget),
      ],
      [
        "  IPD",
        safeNum(ipdTarget),
        safeNum(ipdSales),
        safePercent(ipdSales, ipdTarget),
      ],

      ["", "", "", ""],

      // ===== PENDING SALES =====
      ["Pending Sales Order", "", safeNum(monthlySOvalue), ""],
      ["  Low Priority", "", safeNum(lowVal), ""],
      ["  Medium Priority", "", safeNum(mediumVal), ""],
      ["  High Priority", "", safeNum(highVal), ""],

      ["", "", "", ""],

      // ===== PURCHASE =====
      [
        "Purchases",
        safeNum(purchaseTarget),
        safeNum(monthlyPurchasePriceGrnSum),
        safePercent(monthlyPurchasePriceGrnSum, purchaseTarget),
      ],

      ["", "", "", ""],

      // ===== INVENTORY =====
      [
        "Inventory Aging",
        safeNum(inventoryTarget),
        safeNum(inventoryClosingValue),
        "",
      ],
      ["  <30 Days", "", safeNum(lessThan30DaysValue), ""],
      ["  31-60 Days", "", safeNum(a30to60DaysValue), ""],
      ["  61-90 Days", "", safeNum(a60to90DaysValue), ""],
      ["  >90 Days", "", safeNum(a91DaysValue), ""],

      ["", "", "", ""],

      // ===== COGS =====
      [
        "COGS",
        safeNum(cogsTarget),
        safeNum(cogsValue),
        safePercent(cogsValue, cogsTarget),
      ],
    ];

    // ================= CALL SERVICE =================
    await reportService.generateExcel(
      sheetName: "Daily Costing",
      headers: headers,
      rows: rows,
      fileName: "DailyCostingReport.xlsx",
      reportTitle: "Daily Costing Report",

      enableStyling: true,
      highlightSections: true,
      highlightNegative: true,

      amountColumns: [2, 3, 4], // Target, Achievement, %
    );
  }

  double getCompletedDaysInMonth(int year, int monthNumber) {
    DateTime now = DateTime.now();
    bool isCurrentMonth = (now.year == year && now.month == monthNumber);

    if (isCurrentMonth) {
      // Return the number of completed days in current month (excluding today if needed)
      return now.day
          .toDouble(); // or (now.day - 1).toDouble() if you mean "completed" as excluding today
    } else {
      // Return the full number of days in the given month
      return DateTime(year, monthNumber + 1, 0).day.toDouble();
    }
  }

  Future<void> _loadModeOfPayment(String UserName, String UserLevel) async {
    int index = 0;
    const int limit = 10000;

    List<ModeOfPaymentList> modeOfPaymentList = [];

    try {
      final fromDate = dateFilterFlag
          ? formatDate(fromDateFilter!)
          : formatDate(fiscalYearStartDate!);

      final toDate = dateFilterFlag
          ? formatDate(toDateFilter!)
          : formatDate(currentDate!);

      while (true) {
        final body = {
          "FromDate": fromDate,
          "ToDate": toDate,
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };

        const apiUrl = '${ApiHelper.baseUrl}BicxoPaymentAnalysisList';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode != 200) break;

        final responseJson = jsonDecode(response.body);
        final data = responseJson['responseData'] as List?;

        if (data == null || data.isEmpty) break;

        final newList = data
            .map((item) => ModeOfPaymentList.fromJson(item))
            .where((e) => e.vendorGroup.isNotEmpty)
            .toList();

        modeOfPaymentList.addAll(newList);

        if (newList.length < limit) break;

        index++;
      }

      if (!mounted) return;

      setState(() {
        modeOfPayment = modeOfPaymentList;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Error: $e'),
        ),
      );
    }
  }

  int _lastDayOfMonth(int year, int month) {
    final nextMonth = (month < 12)
        ? DateTime(year, month + 1, 1)
        : DateTime(year + 1, 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  Future<List<InventoryList>> _fetchInventoryForDate(DateTime toDate) async {
    int index = 0;
    const int limit = 10000;

    List<InventoryList> allItems = [];

    final formattedToDate = DateFormat('yyyyMMdd').format(toDate);

    int retryCount = 0;
    const maxRetry = 2;

    while (true) {
      final body = {
        "ToDate": formattedToDate,
        "Index": index.toString(),
        "Limit": limit.toString(),
        "sapToken": DataManager.readSapToken(),
      };

      const apiUrl = '${ApiHelper.baseUrl}BicxoInventoryAgeingList';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode(body),
      );

      // 🔁 retry logic (safe)
      if (response.statusCode == 504 && retryCount < maxRetry) {
        retryCount++;
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }

      if (response.statusCode != 200) break;

      retryCount = 0;

      final responseJson = jsonDecode(response.body);
      final data = responseJson['responseData'] as List?;

      if (data == null || data.isEmpty) break;

      final items = data.map((e) => InventoryList.fromJson(e)).toList();

      allItems.addAll(items);

      if (items.length < limit) break;

      index++;
    }

    return allItems;
  }

  Future<List<MonthlyInventoryData>> _loadMonthlyInventory(
    String userName,
    String userLevel,
  ) async {
    final now = DateTime.now();
    final fyStartYear = (now.month >= 4) ? now.year : now.year - 1;
    final marchDate = DateTime(fyStartYear, 3, _lastDayOfMonth(fyStartYear, 3));
    final endDate = DateTime(
      now.year,
      now.month,
      _lastDayOfMonth(now.year, now.month),
    );

    List<MonthlyInventoryData> result = [];
    DateTime cursor = marchDate;

    while (!cursor.isAfter(endDate)) {
      final monthData = await _fetchInventoryForDate(cursor);
      final label = DateFormat('MMM yyyy').format(cursor);
      result.add(MonthlyInventoryData(monthYear: label, inventory: monthData));

      final nextMonth = cursor.month < 12
          ? DateTime(cursor.year, cursor.month + 1, 1)
          : DateTime(cursor.year + 1, 1, 1);
      cursor = DateTime(
        nextMonth.year,
        nextMonth.month,
        _lastDayOfMonth(nextMonth.year, nextMonth.month),
      );
    }
    monthWiseInventory = result;
    return result;
  }

  Future<void> _loadMonthlySalesBarCashConversionChartData(
    String userName,
    String userLevel,
  ) async {
    List<CashConversionGraphData> soDataList = [];

    final now = DateTime.now();
    final int fiscalIndex = (now.month < 4) ? now.month + 12 : now.month;

    final dateFormat = DateFormat('dd/MM/yyyy');

    DateTime parseDate(String d) => dateFormat.parse(d);

    /// STEP 1: Pre-group (NO repeated where)
    final salesMap = {
      "NH": <SalesList>[],
      "OFFICE": <SalesList>[],
      "SALES": <SalesList>[],
    };

    for (var s in sales) {
      if (s.salesManager == "NH GROUP. - Drs.") {
        salesMap["NH"]!.add(s);
      } else if (s.salesManager == "OFFICE - Drs.") {
        salesMap["OFFICE"]!.add(s);
      } else {
        salesMap["SALES"]!.add(s);
      }
    }

    List filterByManager(List list, String key) {
      return list.where((e) {
        if (key == "NH") return e.salesManager == "NH GROUP. - Drs.";
        if (key == "OFFICE") return e.salesManager == "OFFICE - Drs.";
        return e.salesManager != "NH GROUP. - Drs." &&
            e.salesManager != "OFFICE - Drs.";
      }).toList();
    }

    final receivablesMap = {
      "NH": filterByManager(debtorsList, "NH"),
      "OFFICE": filterByManager(debtorsList, "OFFICE"),
      "SALES": filterByManager(debtorsList, "SALES"),
    };

    final collectionMap = {
      "NH": filterByManager(collection, "NH"),
      "OFFICE": filterByManager(collection, "OFFICE"),
      "SALES": filterByManager(collection, "SALES"),
    };

    /// STEP 2: Month Loop
    for (int i = 4; i <= 15; i++) {
      final monthName = getMonthName(i);

      if (i > fiscalIndex) {
        soDataList.add(
          CashConversionGraphData(
            monthName: monthName,
            dsoDaysSales: 0,
            dsoDaysNH: 0,
            dsoDaysOffice: 0,
            dsoAllDays: 0,
            payableDays: 0,
            inventoryDays: 0,
          ),
        );
        continue;
      }

      var dates = getMonthStartEndDates(i);
      final curStart = dates['start']!;
      final curEnd = dates['end']!;

      /// Previous month directly from current month
      final prevDate = DateTime(curStart.year, curStart.month - 1, 1);
      final prevStart = DateTime(prevDate.year, prevDate.month, 1);
      final prevEnd = DateTime(prevDate.year, prevDate.month + 1, 0);

      double calcDSO(
        List<SalesList> salesList,
        List receivableList,
        List collectionList,
      ) {
        double salesTotal = 0;
        double receivableTotal = 0;
        double collectionTotal = 0;

        /// SALES
        for (var s in salesList) {
          if (s.invoiceDate.isAtLeast(curStart) &&
              s.invoiceDate.isAtMost(curEnd)) {
            salesTotal += double.tryParse(s.rowTotal) ?? 0;
          }
        }
        double prevMthReceivableTotal = 0;
        double prevMthCollectionTotal = 0;

        /// RECEIVABLE
        for (var r in receivableList) {
          final d = parseDate(r.postingDate);
          final balance = double.tryParse(r.balance) ?? 0;

          /// Current Month
          if (d.isAtMost(curEnd)) {
            receivableTotal += balance;
          }

          /// Previous Month
          if (d.isAtMost(prevEnd)) {
            prevMthReceivableTotal += balance;
          }
        }

        /// COLLECTION
        for (var c in collectionList) {
          final d = parseDate(c.postingDate);
          final total = double.tryParse(c.total) ?? 0;

          /// Current Month
          if (d.isAtLeast(curStart) && d.isAtMost(curEnd)) {
            collectionTotal += total;
          }

          /// Previous Month
          if (d.isAtLeast(prevStart) && d.isAtMost(prevEnd)) {
            prevMthCollectionTotal += total;
          }
        }

        final avg =
            (prevMthReceivableTotal +
                prevMthCollectionTotal +
                receivableTotal +
                collectionTotal) /
            2;
        final days = getCompletedDaysInMonth(DateTime.now().year, i);

        return salesTotal != 0 ? (avg / salesTotal) * days : 0;
      }

      /// STEP 3: Calculate DSO
      final dsoNH = calcDSO(
        salesMap["NH"]!,
        receivablesMap["NH"]!,
        collectionMap["NH"]!,
      );

      final dsoOffice = calcDSO(
        salesMap["OFFICE"]!,
        receivablesMap["OFFICE"]!,
        collectionMap["OFFICE"]!,
      );

      final dsoSales = calcDSO(
        salesMap["SALES"]!,
        receivablesMap["SALES"]!,
        collectionMap["SALES"]!,
      );

      /// STEP 4: Payables & Paid
      double paid = 0;
      for (var c in modeOfPayment) {
        final d = parseDate(c.postingDate);
        if (d.isAtLeast(curStart) && d.isAtMost(curEnd)) {
          paid += double.tryParse(c.total) ?? 0;
        }
      }
      double payable = 0;
      for (var p in payables) {
        final d = parseDate(p.postingDate);
        if (d.isAtMost(curEnd)) {
          payable += double.tryParse(p.balance) ?? 0;
        }
      }

      /// STEP 5: Inventory
      final cogsIndex = i - 4;

      final cogsData = (cogsIndex >= 0 && cogsIndex < monthlyCogsList.length)
          ? monthlyCogsList[cogsIndex]
          : MonthlyCogsData(
              monthYear: monthName,
              openingStock: 0,
              purchases: 0,
              closingStock: 0,
              cogs: 0,
            );

      double avgInventory = (cogsData.openingStock + cogsData.closingStock) / 2;

      double inventoryDays = cogsData.cogs != 0
          ? (avgInventory / cogsData.cogs) *
                getCompletedDaysInMonth(DateTime.now().year, i)
          : 0;

      payable = payable.abs();
      final avg = (payable + paid) / 2;
      final days = getCompletedDaysInMonth(DateTime.now().year, i);

      payable = payable != 0 ? (avg / cogsData.cogs) * days : 0;

      final totalDSO = dsoNH + dsoSales + dsoOffice;

      soDataList.add(
        CashConversionGraphData(
          monthName: monthName,
          dsoDaysSales: dsoSales.roundToDouble(),
          dsoDaysNH: dsoNH.roundToDouble(),
          dsoDaysOffice: dsoOffice.roundToDouble(),
          dsoAllDays: totalDSO.roundToDouble(),
          payableDays: payable.abs().roundToDouble(),
          inventoryDays: inventoryDays.roundToDouble(),
        ),
      );
    }

    /// STEP 6: Graph Selection
    monthlyAnalysisData = CashConversionGraphList(monthData: soDataList);

    int displayIndex;

    displayIndex = DateTime.now().month - 4;

    displayIndex = displayIndex.clamp(0, soDataList.length - 1);

    currentCashConversionCycleDays = double.parse(
      ((soDataList[displayIndex].dsoAllDays +
                  soDataList[displayIndex].inventoryDays) -
              soDataList[displayIndex].payableDays)
          .toStringAsFixed(0),
    );
  }

  List<MonthlyCogsData> calculateMonthlyCogs({
    required List<MonthlyInventoryData> inventoryList,
    required List<DailyAnalysisExpensesData> purchaseMonthlyData,
  }) {
    final List<MonthlyCogsData> cogsList = [];

    if (inventoryList.length < 2) return cogsList;

    double sumInventory(List inventory) {
      return inventory.fold<double>(
        0.0,
        (sum, item) => sum + (double.tryParse(item.totalValue) ?? 0.0),
      );
    }

    for (int i = 1; i < inventoryList.length; i++) {
      final current = inventoryList[i];
      final previous = inventoryList[i - 1];

      final String monthYear = current.monthYear;

      final double openingStock = sumInventory(previous.inventory);
      final double closingStock = sumInventory(current.inventory);

      double purchases = 0.0;
      if (i - 1 < purchaseMonthlyData.length) {
        purchases = purchaseMonthlyData[i - 1].balance;
      }

      final double cogs = openingStock + purchases - closingStock;

      cogsList.add(
        MonthlyCogsData(
          monthYear: monthYear,
          openingStock: openingStock,
          purchases: purchases,
          closingStock: closingStock,
          cogs: cogs,
        ),
      );
    }

    return cogsList;
  }

  Future<void> _loadMonthlyAnalysisPurchase() async {
    final List<DailyAnalysisExpensesData> groupWiseDataList = [];

    final records = grnList;

    final startDate = dateFilterFlag ? fromDateFilter! : fiscalYearStartDate!;
    final endDate = dateFilterFlag ? toDateFilter! : currentDate!;

    final dateFormat = DateFormat('dd/MM/yyyy');
    final monthFormat = DateFormat('MM/yyyy');

    /// Single pass: filter + group
    final Map<String, double> monthlyBalanceMap = {};

    for (var record in records) {
      final invoiceDate = dateFormat.parse(record.grnDate);

      if (!invoiceDate.isAtLeast(startDate) || !invoiceDate.isAtMost(endDate)) {
        continue;
      }

      final key = monthFormat.format(invoiceDate);

      final balance = double.tryParse(record.rowTotal) ?? 0.0;

      monthlyBalanceMap[key] = (monthlyBalanceMap[key] ?? 0.0) + balance;
    }

    /// Ensure chronological order (important)
    final sortedKeys = monthlyBalanceMap.keys.toList()
      ..sort((a, b) {
        final d1 = DateFormat('MM/yyyy').parse(a);
        final d2 = DateFormat('MM/yyyy').parse(b);
        return d1.compareTo(d2);
      });

    for (var key in sortedKeys) {
      groupWiseDataList.add(
        DailyAnalysisExpensesData(balance: monthlyBalanceMap[key]!, date: key),
      );
    }

    purchaseMonthlyData = DailyAnalysisExpensesList(
      dailyData: groupWiseDataList,
    );

    monthlyCogsList = calculateMonthlyCogs(
      inventoryList: monthWiseInventory,
      purchaseMonthlyData: purchaseMonthlyData.dailyData,
    );
  }

  Future<void> generateFormattedDailyCostingReport() async {
    try {
      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];
      sheet.name = "Daily Costing";

      sheet.getRangeByIndex(1, 1).columnWidth = 32;
      sheet.getRangeByIndex(1, 2).columnWidth = 18;
      sheet.getRangeByIndex(1, 3).columnWidth = 30;
      sheet.getRangeByIndex(1, 4).columnWidth = 18;
      sheet.getRangeByIndex(1, 5).columnWidth = 14;
      sheet.getRangeByIndex(1, 6).columnWidth = 22;
      sheet.getRangeByIndex(1, 7).columnWidth = 20;

      final borderStyle = xlsio.LineStyle.thin;

      // HEADER STYLE
      final header = sheet.getRangeByName("A1:G1");
      header.merge();
      header.setText("DAILY COSTING DASHBOARD");
      header.cellStyle.bold = true;
      header.cellStyle.fontSize = 18;
      header.cellStyle.hAlign = xlsio.HAlignType.center;
      header.cellStyle.vAlign = xlsio.VAlignType.center;

      sheet.getRangeByIndex(1, 1).rowHeight = 28;

      // DATE
      final dateRange = sheet.getRangeByName("A2:G2");
      dateRange.merge();
      dateRange.setText("Date : ${formatDateString(currentDate!)}");
      dateRange.cellStyle.hAlign = xlsio.HAlignType.center;
      dateRange.cellStyle.bold = true;

      final fyHeader = sheet.getRangeByName("A4:E4");
      fyHeader.merge();
      final now = DateTime.now();
      final int startYear = now.month >= 4 ? now.year : now.year - 1;
      final int endYear = startYear + 1;
      final String fyText =
          "Financial Target for FY "
          "${startYear.toString().substring(2)}-"
          "${endYear.toString().substring(2)}";

      fyHeader.setText(fyText);
      fyHeader.cellStyle.bold = true;
      fyHeader.cellStyle.backColor = "#D9EAF7";
      fyHeader.cellStyle.hAlign = xlsio.HAlignType.center;
      fyHeader.cellStyle.borders.all.lineStyle = borderStyle;

      sheet.getRangeByIndex(5, 1).setText("Particulars");
      sheet.getRangeByIndex(5, 2).setText("Target");
      sheet.getRangeByIndex(5, 3).setText("");
      sheet.getRangeByIndex(5, 4).setText("Achieved");
      sheet.getRangeByIndex(5, 5).setText("%");

      final headingRange = sheet.getRangeByName("A5:E5");
      headingRange.cellStyle.bold = true;
      headingRange.cellStyle.backColor = "#EAF2F8";
      headingRange.cellStyle.hAlign = xlsio.HAlignType.center;
      headingRange.cellStyle.borders.all.lineStyle = borderStyle;

      void setDashboardRow({
        required int row,
        String? title,
        dynamic target,
        dynamic worksheet,
        dynamic achieved,
        dynamic percentage,
        bool red = false,
      }) {
        sheet.getRangeByIndex(row, 1).setText(title);

        if (target != null && target != "") {
          sheet
              .getRangeByIndex(row, 2)
              .setNumber(double.tryParse(target.toString()) ?? 0);
        }

        if (worksheet != null && worksheet != "") {
          final cell = sheet.getRangeByIndex(row, 3);
          cell.setText(worksheet);
          cell.cellStyle.wrapText = true;
          cell.cellStyle.vAlign = xlsio.VAlignType.center;
          cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
        }

        if (achieved != null && achieved != "") {
          sheet
              .getRangeByIndex(row, 4)
              .setNumber(double.tryParse(achieved.toString()) ?? 0);
        }

        sheet.getRangeByIndex(row, 5).setText(percentage ?? "");

        final rowRange = sheet.getRangeByIndex(row, 1, row, 5);

        rowRange.cellStyle.borders.all.lineStyle = borderStyle;

        rowRange.cellStyle.vAlign = xlsio.VAlignType.center;

        // COLUMN A - TITLE
        sheet.getRangeByIndex(row, 1).cellStyle.hAlign = xlsio.HAlignType.left;

        // COLUMN B - TARGET
        sheet.getRangeByIndex(row, 2).cellStyle.hAlign = xlsio.HAlignType.right;

        // COLUMN C - WORKSHEET
        sheet.getRangeByIndex(row, 3).cellStyle.hAlign = xlsio.HAlignType.right;

        // COLUMN D - ACHIEVED
        sheet.getRangeByIndex(row, 4).cellStyle.hAlign = xlsio.HAlignType.right;

        // COLUMN E - PERCENTAGE
        sheet.getRangeByIndex(row, 5).cellStyle.hAlign =
            xlsio.HAlignType.center;

        if (red) {
          sheet.getRangeByIndex(row, 3).cellStyle.fontColor = "#FF0000";
        }
      }

      setDashboardRow(
        row: 6,
        title: "Revenue",
        target: ipdTarget + medicalDeviceTarget,
        worksheet:
            "Medical Device: ${medicalDevicesSales.toStringAsFixed(2)}\n"
            "IPD           : ${ipdSales.toStringAsFixed(2)}",
        achieved: monthlySales,
        percentage:
            (((monthlySales /
                        ((ipdTarget + medicalDeviceTarget) == 0
                            ? 1
                            : (ipdTarget + medicalDeviceTarget))) *
                    100))
                .toStringAsFixed(2),
      );

      setDashboardRow(
        row: 7,
        title: "Pending Sales Orders",
        target: "",
        worksheet:
            "High Priority  : ${highPriorityPendingSO.toStringAsFixed(2)}\n"
            "Medium Priority: ${mediumPriorityPendingSO.toStringAsFixed(2)}\n"
            "Low Priority   : ${lowPriorityPendingSO.toStringAsFixed(2)}",
        achieved: totalPendingSO,
        percentage: "",
      );

      setDashboardRow(
        row: 8,
        title: "Purchases",
        target: purchaseTarget,
        achieved: monthlyPurchasePriceSum,
        percentage: purchaseTarget == 0
            ? "0"
            : ((monthlyPurchasePriceSum / purchaseTarget) * 100)
                  .toStringAsFixed(2),
      );

      setDashboardRow(
        row: 9,
        title: "Pending Purchase Orders",
        target: "",
        worksheet: "Last Month   : ",
        achieved: lastMonthPOSum.toStringAsFixed(2),
        percentage: "",
      );
      setDashboardRow(
        row: 10,
        target: "",
        worksheet: "Current Month: ",
        achieved: currentMonthPOSum.toStringAsFixed(2),
        percentage: "",
      );
      setDashboardRow(
        row: 11,
        target: "",
        worksheet: "Next Month   : ",
        achieved: nextMonthPOSum.toStringAsFixed(2),
        percentage: "",
      );
      setDashboardRow(
        row: 12,
        target: "",
        worksheet: "Total        : ",
        achieved: (lastMonthPOSum + currentMonthPOSum + nextMonthPOSum)
            .toStringAsFixed(2),
        percentage: "",
      );
      final pendingPoMerge = sheet.getRangeByName("A9:A12");
      pendingPoMerge.merge();
      pendingPoMerge.setText("Pending Purchase Orders");
      pendingPoMerge.cellStyle.wrapText = true;
      pendingPoMerge.cellStyle.hAlign = xlsio.HAlignType.left;
      pendingPoMerge.cellStyle.vAlign = xlsio.VAlignType.center;
      pendingPoMerge.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

      setDashboardRow(
        row: 13,
        title: "Closing Stock(Including Stock In Transit)",
        target: inventoryTarget,
        worksheet: "",
        achieved: inventoryAchieved,
        percentage: inventoryTarget == 0
            ? "0"
            : ((inventoryAchieved / inventoryTarget) * 100).toStringAsFixed(2),
      );

      setDashboardRow(
        row: 14,
        title: "Inventory Ageing",
        worksheet: "< 30 Days",
        achieved: lessThan30DaysValue,
        percentage: inventoryLess30Percent.toStringAsFixed(2),
      );

      setDashboardRow(
        row: 15,
        worksheet: "30 - 60 Days",
        achieved: a30to60DaysValue,
        percentage: inventory30to60Percent.toStringAsFixed(2),
      );

      setDashboardRow(
        row: 16,
        worksheet: "60 - 90 Days",
        achieved: a60to90DaysValue,
        percentage: inventory60to90Percent.toStringAsFixed(2),
      );

      setDashboardRow(
        row: 17,
        worksheet: "> 90 Days",
        achieved: a91DaysValue,
        percentage: inventoryAbove90Percent.toStringAsFixed(2),
      );

      setDashboardRow(
        row: 18,
        worksheet: "Stock In Transit",
        achieved: "0",
        percentage: 0.toStringAsFixed(2),
      );
      final inventoryMerge = sheet.getRangeByName("A13:A18");
      inventoryMerge.merge();
      inventoryMerge.setText("Inventory Ageing");
      inventoryMerge.cellStyle.wrapText = true;
      inventoryMerge.cellStyle.hAlign = xlsio.HAlignType.left;
      inventoryMerge.cellStyle.vAlign = xlsio.VAlignType.center;
      inventoryMerge.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

      setDashboardRow(
        row: 19,
        title: "COGS",
        target: cogsTarget,
        worksheet: "${cogsTargetPercentage.toStringAsFixed(0)}%",
        achieved: cogsValue,
        percentage: cogsPercentage.toStringAsFixed(2),
      );

      setDashboardRow(
        row: 20,
        title: "Cash Conversion Cycle",
        worksheet: "${cashConversionCycleDays.toStringAsFixed(0)} Days",
      );

      setDashboardRow(
        row: 21,
        title: "Note:-",
        worksheet: "Ready To Dispatch Stock(Customer)",
        achieved: readyToDispatchStock.toStringAsFixed(2),
      );

      final pendingHeader = sheet.getRangeByName("F4:G4");
      pendingHeader.merge();
      pendingHeader.setText("Pending Sales Orders");
      pendingHeader.cellStyle.bold = true;
      pendingHeader.cellStyle.backColor = "#E2EFDA";
      pendingHeader.cellStyle.hAlign = xlsio.HAlignType.center;
      pendingHeader.cellStyle.borders.all.lineStyle = borderStyle;

      sheet.getRangeByIndex(5, 6)
        ..setText("Bangalore: ")
        ..cellStyle.bold = true;
      sheet.getRangeByIndex(5, 7).setNumber(bangalorePendingSO);
      sheet.getRangeByIndex(6, 6)
        ..setText("Rajapalayam: ")
        ..cellStyle.bold = true;
      sheet.getRangeByIndex(6, 7).setNumber(rajapalayamPendingSO);
      sheet.getRangeByIndex(7, 6)
        ..setText("Others")
        ..cellStyle.bold = true;
      sheet.getRangeByIndex(7, 7).setNumber(othersPendingSO);
      sheet.getRangeByIndex(8, 6)
        ..setText("Total")
        ..cellStyle.bold = true;
      sheet
          .getRangeByIndex(8, 7)
          .setNumber(
            bangalorePendingSO + rajapalayamPendingSO + othersPendingSO,
          );
      final pendingRange = sheet.getRangeByName("F5:G8");
      pendingRange.cellStyle.borders.all.lineStyle = borderStyle;

      // ---------------- SAVE ----------------
      final bytes = List<int>.from(workbook.saveAsStream());
      workbook.dispose();

      if (kIsWeb) {
        downloadExcelWeb("daily_costing.xlsx", bytes);
      } else {
        final dir = await getStorageDirectory();
        final file = File('$dir/daily_costing.xlsx');
        await file.writeAsBytes(bytes, flush: true);
        OpenFile.open(file.path);
      }

      showBottomToast(context, "Excel exported successfully");
    } catch (e) {
      showBottomToast(context, "Excel generation failed: $e");
    }
  }

  String formatDateString(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  Future<void> removeFilter() async {
    clearVariables();
    LoadDates();
    allCategoriesState.forEach((category, options) {
      options.updateAll((key, value) => false);
    });
    loadData("");
    chartDataLoadedDailyCosting = true;
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

    nextMonthFromDate = addMonth(
      currentMonthFromDate!,
      1,
    ).add(const Duration(days: 0));
    nextMonthToDate = addMonth(
      nextMonthFromDate!,
      1,
    ).add(const Duration(days: -1));

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

  void clearVariables() {
    setState(() {
      medicalDevicesSales = 0;
      ipdSales = 0;
      monthlySales = 0;

      // Targets (optional if reloaded each time)
      medicalDeviceTarget = 0;
      ipdTarget = 0;
      purchaseTarget = 0;
      cogsTarget = 0;
      inventoryTarget = 0;

      // Sales Order counters
      lowVal = 0;
      mediumVal = 0;
      highVal = 0;
      karnatakaPOSum = 0;
      tamilNaduPOSum = 0;
      othersPOSum = 0;
      monthlySOvalue = 0;

      // Purchase & GRN
      monthlyPurchasePriceSum = 0;
      monthlyPurchasePriceGrnSum = 0;

      // Purchase Order sums
      monthlyPOSum = 0;
      currentMonthPOSum = 0;
      lastMonthPOSum = 0;
      nextMonthPOSum = 0;

      // Inventory Aging
      lessThan30DaysValue = 0;
      a30to60DaysValue = 0;
      a60to90DaysValue = 0;
      nearExpiryValue = 0;
      expiredValue = 0;
      inventoryOpeningValue = 0;
      inventoryClosingValue = 0;
      chartDataLoadedDailyCosting = false;
      dailyCostingData = DailyCostingGraphList(graphData: []);
      revenueBreakup = DailyCostingGraphList(graphData: []);
      saleOrderPriorityBreakup = DailyCostingGraphList(graphData: []);
      saleOrderWarehouseBreakup = DailyCostingGraphList(graphData: []);
      inventoryAging = DailyCostingGraphList(graphData: []);
    });
  }

  void toggleCheckbox() {
    setState(() {
      chartDataLoadedDailyCosting = false;
      loadData("");
    });
  }

  Future<void> _dateFilterTarget() async {
    setState(() {
      sales = sales.where((target) {
        DateTime dueon = target.invoiceDate;
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();

      poListOpen = poListOpen.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();

      collection = collection.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.postingDate);
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();

      grnList = grnList.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.grnDate);
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();

      purchasePrice = purchasePrice.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();

      soList = soList.where((target) {
        DateTime dueon = DateFormat('dd/MM/yyyy').parse(target.poDate);
        return (dueon.isAtLeast(fromDateFilter!) &&
            dueon.isAtMost(toDateFilter!));
      }).toList();
    });
  }

  Future<void> filterDateFunction() async {
    sales = salesTemp;
    poListOpen = poListOpenTemp;
    grnList = grnListTemp;
    purchasePrice = purchasePriceTemp;
    soList = soListTemp;
    _dateFilterTarget();
    await _loadDailyCostingReport("", "");
    setState(() {});
    chartDataLoadedDailyCosting = true;
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

  void clearVariablesForFilter() {
    setState(() {
      chartDataLoadedDailyCosting = false;
      saleOrderPriorityBreakup = DailyCostingGraphList(graphData: []);
      saleOrderWarehouseBreakup = DailyCostingGraphList(graphData: []);
    });
  }

  Future<void> loadDataWithFilter(
    String? touchedPriority,
    String? touchedWarehouse,
  ) async {
    clearVariablesForFilter();
    LoadDates();
    await _loadDailyCostingReport(touchedPriority!, touchedWarehouse!);
    chartDataLoadedDailyCosting = true;
  }

  @override
  void dispose() {
    hideLoadingOverlay(); // VERY IMPORTANT
    _verticalScrollController.dispose();

    _dailyCostingHorizontalController.dispose();
    _revenueHorizontalController.dispose();
    _priorityHorizontalController.dispose();
    _warehouseHorizontalController.dispose();
    _inventoryHorizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: false,
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.trackpad,
        },
      ),
      child: Stack(
        children: [
          chartDataLoadedDailyCosting
              ? Scrollbar(
                  controller: _verticalScrollController,
                  thumbVisibility: true,
                  radius: const Radius.circular(10),
                  child: SingleChildScrollView(
                    controller: _verticalScrollController,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 15),
                                dateFilterFlag
                                    ? Text(
                                        "${formatDateString(fromDateFilter!)} - ${formatDateString(toDateFilter!)}",
                                      )
                                    : Text(
                                        "${formatDateString(currentMonthFromDate!)} - ${formatDateString(currentDate!)}",
                                      ),
                              ],
                            ),
                          ],
                        ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Daily Costing",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      PopupMenuButton(
                                        tooltip: "Download",
                                        padding: EdgeInsets.zero,
                                        itemBuilder: (BuildContext bc) {
                                          return [
                                            PopupMenuItem(
                                              onTap: () {
                                                generateFormattedDailyCostingReport();
                                              },
                                              child: const Text(
                                                "Download Excel",
                                              ),
                                            ),
                                          ];
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.more_vert,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 14),

                                  SizedBox(
                                    height: 370,
                                    child: _dailyCostingGraph(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Revenue",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    height: 370,
                                    child: _revenueBreakupGraph(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Pending Sales Order - Priority Wise",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    height: 370,
                                    child: _pendingSalesOrderPriorityGraph(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Pending Sales Order - Warehouse Wise",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    height: 370,
                                    child: _pendingSalesOrderWarehouseGraph(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Inventory Aging",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    height: 370,
                                    child: _inventoryAgingGraph(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          // Overlay Loader (if active)
          if (_loadingOverlay != null) const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _dailyCostingGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = dailyCostingData.graphData.length;
    if (len > 5) {
      chartWidth = max(screenWidth * 0.45, len * 90);
    } else {
      chartWidth = screenWidth;
    }

    final amounts = dailyCostingData.graphData
        .map((e) => e.achievement)
        .whereType<double>()
        .toList();

    final hasPositive = amounts.any((a) => a > 0);
    final hasNegative = amounts.any((a) => a < 0);

    double chartMinY = 0;
    double chartMaxY = 0;

    if (hasPositive && hasNegative) {
      double maxPositive = amounts
          .where((a) => a > 0)
          .reduce((a, b) => a > b ? a : b);
      double maxNegative = amounts
          .where((a) => a < 0)
          .reduce((a, b) => a < b ? a : b);
      chartMaxY = roundUpTo50Lakhs(maxPositive);
      chartMinY = roundDownTo50Lakhs(maxNegative);
    } else if (hasPositive) {
      double maxPositive = amounts.reduce((a, b) => a > b ? a : b);
      chartMaxY = roundUpTo50Lakhs(maxPositive);
      chartMinY = 0;
    } else if (hasNegative) {
      double maxNegative = amounts.reduce((a, b) => a < b ? a : b);
      chartMaxY = 0;
      chartMinY = roundDownTo50Lakhs(maxNegative);
    }
    return Scrollbar(
      controller: _dailyCostingHorizontalController,
      thumbVisibility: true,
      // thickness: 5,
      radius: const Radius.circular(10),
      notificationPredicate: (_) => true,
      child: SingleChildScrollView(
        controller: _dailyCostingHorizontalController,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          height: 360,
          width: chartWidth,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: BarChart(
              BarChartData(
                maxY: chartMaxY,
                minY: chartMinY,
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
                    sideTitles: _bottomTitlesMonthlyAnalysis,
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
                barGroups: _monthlyAnalysisChartData(
                  dailyCostingData.graphData,
                ),
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
                        '${dailyCostingData.graphData[grpIndex].name}\n',
                        const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text:
                                'Target: ${formatAmount(dailyCostingData.graphData[grpIndex].target)}\n',
                            style: const TextStyle(
                              color: Color(0xFF2CA9DF),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text:
                                'Achievement: ${formatAmount(dailyCostingData.graphData[grpIndex].achievement)}\n',
                            style: const TextStyle(
                              color: Color(0xFFFF9F47),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text:
                                'Percentage: ${dailyCostingData.graphData[grpIndex].percentage}\n',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF78E25D),
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _revenueBreakupGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = revenueBreakup.graphData.length;
    if (len > 5) {
      chartWidth = max(screenWidth * 0.45, len * 90);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? revenueBreakup.graphData
              .map((data) => data.achievement)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return Scrollbar(
      controller: _revenueHorizontalController,
      thumbVisibility: true,
      // thickness: 5,
      radius: const Radius.circular(10),
      notificationPredicate: (_) => true,
      child: SingleChildScrollView(
        controller: _revenueHorizontalController,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          height: 360,
          width: chartWidth,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: BarChart(
              BarChartData(
                maxY: getMaxValue(maxAmount),
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
                    sideTitles: _bottomTitlesRevenueBreakup,
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
                barGroups: _revenueBreakupChartData(revenueBreakup.graphData),
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
                        '${revenueBreakup.graphData[grpIndex].name}\n',
                        const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text:
                                'Target: ${formatAmount(revenueBreakup.graphData[grpIndex].target)}\n',
                            style: const TextStyle(
                              color: Color(0xFF2CA9DF),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text:
                                'Achievement: ${formatAmount(revenueBreakup.graphData[grpIndex].achievement)}\n',
                            style: const TextStyle(
                              color: Color(0xFFFF9F47),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text:
                                'Percentage: ${revenueBreakup.graphData[grpIndex].percentage}\n',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF78E25D),
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _pendingSalesOrderPriorityGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = saleOrderPriorityBreakup.graphData.length;
    if (len > 5) {
      chartWidth = max(screenWidth * 0.45, len * 90);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? saleOrderPriorityBreakup.graphData
              .map((data) => data.achievement)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return Scrollbar(
      controller: _priorityHorizontalController,
      thumbVisibility: true,
      // thickness: 5,
      radius: const Radius.circular(10),
      notificationPredicate: (_) => true,
      child: SingleChildScrollView(
        controller: _priorityHorizontalController,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          height: 360,
          width: chartWidth,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: BarChart(
              BarChartData(
                maxY: getMaxValue(maxAmount),
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
                    sideTitles: _bottomTitlesSalesOrderPriority,
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
                barGroups: _pendingSalesOrderChartData(
                  saleOrderPriorityBreakup.graphData,
                ),
                barTouchData: BarTouchData(
                  allowTouchBarBackDraw: true,
                  touchCallback: (flTouchEvent, barTouchResponse) async {
                    if (barTouchResponse != null &&
                        barTouchResponse.spot != null) {
                      setState(() {
                        if (flTouchEvent is FlTapUpEvent) {
                          touchedPriority = touchedPriority == ""
                              ? saleOrderPriorityBreakup
                                    .graphData[barTouchResponse.spot!.spot.x
                                        .toInt()]
                                    .name
                              : "";
                          touchedPriority = touchedPriority.replaceAll(
                            " Priority",
                            "",
                          );
                          loadDataWithFilter(touchedPriority, touchedWarehouse);
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
                        '${saleOrderPriorityBreakup.graphData[grpIndex].name}\n',
                        const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text:
                                'Value: ${formatAmount(saleOrderPriorityBreakup.graphData[grpIndex].achievement)}\n',
                            style: const TextStyle(
                              color: Color(0xFFFF9F47),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _pendingSalesOrderWarehouseGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = saleOrderWarehouseBreakup.graphData.length;
    if (len > 5) {
      chartWidth = max(screenWidth * 0.45, len * 90);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? saleOrderWarehouseBreakup.graphData
              .map((data) => data.achievement)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return Scrollbar(
      controller: _warehouseHorizontalController,
      thumbVisibility: true,
      // thickness: 5,
      radius: const Radius.circular(10),
      notificationPredicate: (_) => true,
      child: SingleChildScrollView(
        controller: _warehouseHorizontalController,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          height: 360,
          width: chartWidth,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: BarChart(
              BarChartData(
                maxY: getMaxValue(maxAmount),
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
                    sideTitles: _bottomTitlesSalesOrderWarehouse,
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
                barGroups: _pendingSalesOrderWarehouseChartData(
                  saleOrderWarehouseBreakup.graphData,
                ),
                barTouchData: BarTouchData(
                  allowTouchBarBackDraw: true,
                  touchCallback: (flTouchEvent, barTouchResponse) async {
                    if (barTouchResponse != null &&
                        barTouchResponse.spot != null) {
                      setState(() {
                        if (flTouchEvent is FlTapUpEvent) {
                          touchedWarehouse = touchedWarehouse == ""
                              ? saleOrderWarehouseBreakup
                                    .graphData[barTouchResponse.spot!.spot.x
                                        .toInt()]
                                    .name
                              : "";
                          loadDataWithFilter(touchedPriority, touchedWarehouse);
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
                        '${saleOrderWarehouseBreakup.graphData[grpIndex].name}\n',
                        const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text:
                                'Value: ${formatAmount(saleOrderWarehouseBreakup.graphData[grpIndex].achievement)}\n',
                            style: const TextStyle(
                              color: Color(0xFFFF9F47),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _inventoryAgingGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = inventoryAging.graphData.length;
    if (len > 5) {
      chartWidth = max(screenWidth * 0.45, len * 90);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? inventoryAging.graphData
              .map((data) => data.achievement)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return Scrollbar(
      controller: _inventoryHorizontalController,
      thumbVisibility: true,
      // thickness: 5,
      radius: const Radius.circular(10),
      notificationPredicate: (_) => true,
      child: SingleChildScrollView(
        controller: _inventoryHorizontalController,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          height: 360,
          width: chartWidth,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: BarChart(
              BarChartData(
                maxY: getMaxValue(maxAmount),
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
                    sideTitles: _bottomTitlesInventoryAging,
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
                barGroups: _inventoryAgingChartData(inventoryAging.graphData),
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
                        '${inventoryAging.graphData[grpIndex].name}\n',
                        const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text:
                                'Value: ${formatAmount(inventoryAging.graphData[grpIndex].achievement)}\n',
                            style: const TextStyle(
                              color: Color(0xFFFF9F47),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }

  void showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        int selectedCategoryIndex = 0;

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Options',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  // Filter UI
                  Expanded(
                    child: Row(
                      children: [
                        // Left side: Categories
                        SizedBox(
                          width: 150,
                          child: ListView.builder(
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(categories[index]),
                                selected: selectedCategoryIndex == index,
                                onTap: () {
                                  setState(() {
                                    selectedCategoryIndex = index;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        // Right side: Filter options as checkboxes
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child:
                                    selectedCategoryIndex ==
                                        categories.length -
                                            1 // "Date" index
                                    ? Column(
                                        children: [
                                          ListTile(
                                            title: const Text("From Date"),
                                            subtitle: Text(
                                              fromDateFilter != null
                                                  ? "${fromDateFilter!.day}/${fromDateFilter!.month}/${fromDateFilter!.year}"
                                                  : formatDateString(
                                                      fiscalYearStartDate!,
                                                    ),
                                            ),
                                            trailing: const Icon(
                                              Icons.calendar_today,
                                            ),
                                            onTap: () async {
                                              final picked =
                                                  await showDatePicker(
                                                    context: context,
                                                    initialDate:
                                                        fromDateFilter ??
                                                        DateTime.now(),
                                                    firstDate:
                                                        fiscalYearStartDate!,
                                                    lastDate: currentDate!,
                                                  );
                                              if (picked != null) {
                                                setState(() {
                                                  fromDateFilter = picked;
                                                  dateFilterFlag = true;
                                                });
                                              }
                                            },
                                          ),
                                          ListTile(
                                            title: const Text("To Date"),
                                            subtitle: Text(
                                              toDateFilter != null
                                                  ? "${toDateFilter!.day}/${toDateFilter!.month}/${toDateFilter!.year}"
                                                  : formatDateString(
                                                      currentDate!,
                                                    ),
                                            ),
                                            trailing: const Icon(
                                              Icons.calendar_today,
                                            ),
                                            onTap: () async {
                                              final picked =
                                                  await showDatePicker(
                                                    context: context,
                                                    initialDate:
                                                        toDateFilter ??
                                                        DateTime.now(),
                                                    firstDate:
                                                        fiscalYearStartDate!,
                                                    lastDate: currentDate!,
                                                  );
                                              if (picked != null) {
                                                setState(() {
                                                  toDateFilter = picked;
                                                  dateFilterFlag = true;
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      )
                                    : ListView.builder(
                                        itemCount:
                                            filterOptions[selectedCategoryIndex]
                                                .length,
                                        itemBuilder: (context, index) {
                                          return CheckboxListTile(
                                            title: Text(
                                              filterOptions[selectedCategoryIndex][index],
                                            ),
                                            value:
                                                savedFinanceReceivablesOptions[selectedCategoryIndex][index],
                                            onChanged: (bool? value) {
                                              // your checkbox logic
                                            },
                                          );
                                        },
                                      ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff2ca9df),
                                      minimumSize: const Size(10, 10),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () {
                                      List<String> selectedFilterOptions = [];
                                      for (
                                        int i = 0;
                                        i <
                                            filterOptions[selectedCategoryIndex]
                                                .length;
                                        i++
                                      ) {
                                        if (selectedFinanceReceivablesOptions[selectedCategoryIndex][i]) {
                                          selectedFilterOptions.add(
                                            filterOptions[selectedCategoryIndex][i],
                                          );
                                        }
                                      }

                                      for (
                                        int catIndex = 0;
                                        catIndex < categories.length;
                                        catIndex++
                                      ) {
                                        String categoryName =
                                            categories[catIndex];
                                        Map<String, bool> optionsState = {};

                                        // Ensure the lengths match for your filterOptions and selectedFinanceReceivablesOptions lists
                                        for (
                                          int optionIndex = 0;
                                          optionIndex <
                                              filterOptions[catIndex].length;
                                          optionIndex++
                                        ) {
                                          optionsState[filterOptions[catIndex][optionIndex]] =
                                              selectedFinanceReceivablesOptions[catIndex][optionIndex];
                                        }

                                        allCategoriesState[categoryName] =
                                            optionsState;
                                      }

                                      Navigator.pop(context);

                                      selectedSalesData = selectedFilterOptions;

                                      savedFinanceReceivablesOptionsTemp =
                                          savedFinanceReceivablesOptions;

                                      fromFilter = false;

                                      // toggleCheckbox();
                                      filterDateFunction();
                                      setState(() {});
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Apply Filter',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      minimumSize: const Size(10, 10),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () {
                                      chartDataLoadedDailyCosting = false;
                                      fromFilter = false;
                                      savedFinanceReceivablesOptionsTemp
                                          .clear();
                                      setState(() {
                                        chartDataLoadedDailyCosting = false;
                                        loadDataFuture = removeFilter();
                                        Navigator.pop(context);
                                        chartDataLoadedDailyCosting = true;
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Clear Filter',
                                        style: TextStyle(
                                          color: Color(0xff2ca9df),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
