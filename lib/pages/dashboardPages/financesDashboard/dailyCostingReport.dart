// ignore_for_file: file_names, use_build_context_synchronously, non_constant_identifier_names
// import 'package:optima/excel_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart' as xl;
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
import 'package:optima/classes/leads.dart';
import 'package:optima/login_screen.dart';

import '../platform_excel_helper.dart';

class DailyCostingReport extends StatefulWidget {
  const DailyCostingReport({super.key});

  @override
  State<DailyCostingReport> createState() => _DailyCostingReportState();
}

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

double medicalDeviceTarget = 0;
double ipdTarget = 0;
double inventoryTarget = 0;
double purchaseTarget = 0;
double cogsTarget = 0;
double productionTarget = 0;

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
double tillLastMonthPOSum = 0;
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

List<List<bool>> savedFinanceReceivablesOptions = filterOptions
    .map((options) => List<bool>.filled(options.length, false))
    .toList();

class DailyCostingSalesProvider with ChangeNotifier {
  List<SalesList> _salesList = [];
  List<SalesList> get salesList => _salesList;
  void updateSalesList(List<SalesList> newList) {
    _salesList = newList;
    notifyListeners();
  }
}

class DailyCostingSOListProvider with ChangeNotifier {
  List<SODetailsList> _soList = [];
  List<SODetailsList> get soList => _soList;
  void updateSOList(List<SODetailsList> newList) {
    _soList = newList;
    notifyListeners();
  }
}

class DailyCostingPurchaseProvider with ChangeNotifier {
  List<PurchaseList> _purchaseList = [];
  List<PurchaseList> get purchaseList => _purchaseList;
  void updatePurchaseList(List<PurchaseList> newList) {
    _purchaseList = newList;
    notifyListeners();
  }
}

class DailyCostingGRNProvider with ChangeNotifier {
  List<GRNList> _purchaseList = [];
  List<GRNList> get purchaseList => _purchaseList;
  void updatePurchaseList(List<GRNList> newList) {
    _purchaseList = newList;
    notifyListeners();
  }
}

class DailyCostingPOProvider with ChangeNotifier {
  List<POList> _poList = [];
  List<POList> get poList => _poList;
  void updatePOList(List<POList> newList) {
    _poList = newList;
    notifyListeners();
  }
}

class DailyCostingInventoryProvider with ChangeNotifier {
  List<InventoryList> _inventoryList = [];
  List<InventoryList> get inventoryList => _inventoryList;
  void updateInventoryList(List<InventoryList> newList) {
    _inventoryList = newList;
    notifyListeners();
  }
}

class DailyCostingInventoryClosingProvider with ChangeNotifier {
  List<InventoryList> _inventoryList = [];
  List<InventoryList> get inventoryList => _inventoryList;
  void updateInventoryList(List<InventoryList> newList) {
    _inventoryList = newList;
    notifyListeners();
  }
}

class DailyCostingSalesTargetProvider with ChangeNotifier {
  List<SalesTargetList> _salesTargetList = [];
  List<SalesTargetList> get salesTargetList => _salesTargetList;
  void updateSalesTargetList(List<SalesTargetList> newSalesTargetList) {
    _salesTargetList = newSalesTargetList;
    notifyListeners();
  }
}

// ---- Models used for isolate I/O ----
class DailyCostingInput {
  final String priority;
  final String warehouse;

  final List<SalesList> sales; // your existing models
  final List<SODetailsList> soList;
  final List<PurchaseList> purchasePrice;
  final List<GRNList> grnList;
  final List<POList> poListOpen;
  final List<InventoryList> inventory;
  final List<InventoryList> inventoryClosing;
  final List<SalesTargetList> salesTarget;

  final DateTime currentMonthFromDate;
  final DateTime currentMonthToDate;
  final DateTime lastMonthFromDate;
  final DateTime lastMonthToDate;
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
    required this.fiscalYearStartDate,
    required this.currentDate,
  });
}

class DailyCostingResult {
  // numeric totals
  final double monthlySales;
  final double medicalDevicesSales;
  final double ipdSales;
  final double monthlyPurchasePriceSum;
  final double monthlyPurchasePriceGrnSum;
  final double monthlyPOSum;
  final double currentMonthPOSum;
  final double lastMonthPOSum;
  final double tillLastMonthPOSum;
  final double inventoryOpeningValue;
  final double inventoryClosingValue;
  final double cogsValue;

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
    required this.tillLastMonthPOSum,
    required this.inventoryOpeningValue,
    required this.inventoryClosingValue,
    required this.cogsValue,
    required this.revenueGraph,
    required this.dailyCostingGraph,
    required this.saleOrderPriorityGraph,
    required this.saleOrderWarehouseGraph,
    required this.inventoryAgingGraph,
  });
}

// ---- Top-level compute function (runs in isolate) ----
DailyCostingResult _computeDailyCostingReport(DailyCostingInput input) {
  // Helper: convert DateTime to milliseconds for fast comparisons
  final int curFrom = input.currentMonthFromDate.millisecondsSinceEpoch;
  final int curTo = input.currentMonthToDate.millisecondsSinceEpoch;
  final int lastFrom = input.lastMonthFromDate.millisecondsSinceEpoch;
  final int lastTo = input.lastMonthToDate.millisecondsSinceEpoch;

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

  double medicalDeviceTarget = 0,
      ipdTarget = 0,
      purchaseTarget = 0,
      cogsTarget = 0,
      inventoryTarget = 0;

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
        case "PRODUCTION TARGET":
          productionTarget = v;
          break;
      }
    }
  }

  // Fast date parsing: convert record dates to epoch once and sum in single pass where possible

  double monthlySales = 0;
  double medicalDevicesSales = 0;
  double ipdSales = 0;

  for (final s in input.sales) {
    // assume invoiceDate in format dd/MM/yyyy -- convert safely
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

  double lowVal = 0, mediumVal = 0, highVal = 0;
  double karnatakaPOSum = 0, tamilNaduPOSum = 0, othersPOSum = 0;

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
  double monthlyPurchasePriceSum = 0;
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
  double monthlyPurchasePriceGrnSum = 0;
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
  double monthlyPOSum = 0,
      currentMonthPOSum = 0,
      lastMonthPOSum = 0,
      tillLastMonthPOSum = 0;

  for (final po in input.poListOpen) {
    final pending = double.tryParse(po.pendingValue) ?? 0;
    monthlyPOSum += pending;
    DateTime inv;
    try {
      inv = DateFormat('dd/MM/yyyy').parse(po.poDate);
    } catch (_) {
      continue;
    }
    final ms = inv.millisecondsSinceEpoch;
    if (ms >= curFrom && ms <= curTo) {
      currentMonthPOSum += pending;
    } else if (ms >= lastFrom && ms <= lastTo) {
      lastMonthPOSum += pending;
    } else if (ms < lastFrom) {
      tillLastMonthPOSum += pending;
    }
  }

  // Inventory ageing buckets
  double lessThan30DaysValue = 0,
      a30to60DaysValue = 0,
      a60to90DaysValue = 0,
      nearExpiryValue = 0,
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

  double inventoryClosingValue = 0;
  for (final it in input.inventoryClosing) {
    inventoryClosingValue += (double.tryParse(it.totalValue) ?? 0);
  }

  // COGS calculation
  final cogsValue =
      (inventoryOpeningValue + monthlyPurchasePriceGrnSum) -
      (lessThan30DaysValue +
          a30to60DaysValue +
          a60to90DaysValue +
          nearExpiryValue +
          expiredValue);

  final inventoryAchieved =
      lessThan30DaysValue +
      a30to60DaysValue +
      a60to90DaysValue +
      nearExpiryValue +
      expiredValue;

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
    tillLastMonthPOSum: tillLastMonthPOSum,
    inventoryOpeningValue: inventoryOpeningValue,
    inventoryClosingValue: inventoryClosingValue,
    cogsValue: cogsValue,
    revenueGraph: revenueGraph,
    dailyCostingGraph: dailyCostingGraph,
    saleOrderPriorityGraph: saleOrderPriorityGraph,
    saleOrderWarehouseGraph: saleOrderWarehouseGraph,
    inventoryAgingGraph: inventoryAgingGraph,
  );
}

class _DailyCostingReportState extends State<DailyCostingReport> {
  @override
  void initState() {
    super.initState();
    loadDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showLoadingOverlay(context, message: "Loading dashboard…");
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

    int currentYear = now.year - 1;

    int yearForMonth;
    if (now.month >= 1 && now.month <= 3) {
      yearForMonth = (month >= 4 && month <= 12)
          ? currentYear - 1
          : currentYear;
    } else {
      // If the call is happening in Apr–Dec
      yearForMonth = (month >= 4 && month <= 12)
          ? currentYear
          : currentYear + 1;
    }

    DateTime firstDayOfMonth = DateTime(yearForMonth, month, 1);
    DateTime lastDayOfMonth = DateTime(yearForMonth, month + 1, 0);

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
      String text = '';
      List<DailyCostingGraphData> mData = dailyCostingData.graphData;
      text = mData.elementAt(value.toInt()).name;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesRevenueBreakup => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<DailyCostingGraphData> mData = revenueBreakup.graphData;
      text = mData.elementAt(value.toInt()).name;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesSalesOrderPriority => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<DailyCostingGraphData> mData = saleOrderPriorityBreakup.graphData;
      text = mData.elementAt(value.toInt()).name;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesSalesOrderWarehouse => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<DailyCostingGraphData> mData = saleOrderWarehouseBreakup.graphData;
      text = mData.elementAt(value.toInt()).name;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  SideTitles get _bottomTitlesInventoryAging => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<DailyCostingGraphData> mData = inventoryAging.graphData;
      text = mData.elementAt(value.toInt()).name;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: Text(text, style: const TextStyle(fontSize: 12)),
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
    // SHOW ONLY ONCE
    showLoadingOverlay(context, message: "Loading dashboard…");

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
      await _loadDailyCostingReport("", "");

      // When everything is done
      setState(() => chartDataLoadedDailyCosting = true);

      hideLoadingOverlay();
      showBottomToast(context, "Dashboard Ready");
    } catch (e) {
      hideLoadingOverlay(); // avoid stuck overlay
      showBottomToast(context, "Failed: $e");
    }
  }

  Future<void> loadDataOld(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    userLevel = prefs.getString('userLevel') ?? '';
    await _loadSales(userName, userLevel);
    await _loadSODetails(userName, userLevel);
    showLoadingOverlay(context, message: "Sales order loaded…");
    await _loadPurchasePrice(userName, userLevel);
    showLoadingOverlay(context, message: "Purchase price loaded…");
    await _loadPOList(userName, userLevel);
    showLoadingOverlay(context, message: "Purchase order loaded…");
    await _loadInventory(userName, userLevel);
    showLoadingOverlay(context, message: "Inventory data loaded…");
    await _loadInventoryClosing(userName, userLevel);
    showLoadingOverlay(context, message: "Inventory closing data loaded…");
    await _loadSalesTarget(userName, userLevel);
    showLoadingOverlay(context, message: "Sales target loaded…");
    await _loadGRN(userName, userLevel);
    showLoadingOverlay(context, message: "GRN loaded…");
    await _loadDailyCostingReport("", "");
    showLoadingOverlay(context, message: "Finalizing…");

    setState(() => chartDataLoadedDailyCosting = true);

    hideLoadingOverlay();
    showBottomToast(context, "Dashboard Ready");
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

        late http.Response response;

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

        if (response.statusCode == 200) {
          final jsonMap = jsonDecode(response.body);
          final data = jsonMap["responseData"];

          if (data == null || (data is List && data.isEmpty)) {
            fetchedCount = 0;
          } else {
            // FIXED compute() call
            final parsed = await compute<List<dynamic>, List<SalesList>>(
              _parseSalesList,
              data,
            );

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
        context.read<DailyCostingSalesProvider>().updateSalesList(salesList);

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

  List<SalesList> _parseSalesList(List<dynamic> data) {
    return data.map((e) => SalesList.fromJson(e)).toList();
  }

  Future<void> _loadSODetails(String userName, String userLevel) async {
    int index = 0;
    const int limit = 10000;
    int fetchedCount = 0;

    List<SODetailsList> soDetailList = [];

    final fromDate = dateFilterFlag
        ? formatDate(fromDateFilter!)
        : formatDate(fiscalYearStartDate!);

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
          final List<dynamic>? data = jsonMap["responseData"];

          if (data == null || data.isEmpty) {
            fetchedCount = 0;
          } else {
            final parsed = await compute<List<dynamic>, List<SODetailsList>>(
              _parseSOList,
              data,
            );

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
        context.read<DailyCostingSOListProvider>().updateSOList(soDetailList);

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

  List<SODetailsList> _parseSOList(List<dynamic> data) {
    return data.map((e) => SODetailsList.fromJson(e)).toList();
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
          final List<dynamic>? data = jsonMap["responseData"];

          if (data == null || data.isEmpty) {
            fetchedCount = 0;
          } else {
            final parsed = await compute<List<dynamic>, List<PurchaseList>>(
              _parsePurchaseList,
              data,
            );

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

        context.read<DailyCostingPurchaseProvider>().updatePurchaseList(
          purchaseList,
        );
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

  List<PurchaseList> _parsePurchaseList(List<dynamic> data) {
    return data.map((e) => PurchaseList.fromJson(e)).toList();
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
          final List<dynamic>? data = jsonMap["responseData"];

          if (data == null || data.isEmpty) {
            fetchedCount = 0;
          } else {
            // 🧠 MOVE HEAVY PARSING TO ISOLATE
            final parsed = await compute<List<dynamic>, List<POList>>(
              _parsePOList,
              data,
            );

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
        context.read<DailyCostingPOProvider>().updatePOList(poItems);

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

  List<POList> _parsePOList(List<dynamic> data) {
    return data.map((e) => POList.fromJson(e)).toList();
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
          final List<dynamic>? data = jsonMap["responseData"];

          if (data == null || data.isEmpty) {
            fetchedCount = 0;
          } else {
            // 🧠 heavy parsing → background isolate
            final parsed = await compute<List<dynamic>, List<InventoryList>>(
              _parseInventoryList,
              data,
            );

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
        context.read<DailyCostingInventoryProvider>().updateInventoryList(
          inventoryList,
        );

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

  List<InventoryList> _parseInventoryList(List<dynamic> data) {
    return data.map((e) => InventoryList.fromJson(e)).toList();
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
          final List<dynamic>? data = jsonMap["responseData"];

          if (data == null || data.isEmpty) {
            fetchedCount = 0;
          } else {
            // Parse JSON on background isolate
            final parsed = await compute<List<dynamic>, List<InventoryList>>(
              _parseInventoryClosingList,
              data,
            );

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
        context
            .read<DailyCostingInventoryClosingProvider>()
            .updateInventoryList(closingList);

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

  List<InventoryList> _parseInventoryClosingList(List<dynamic> data) {
    return data.map((e) => InventoryList.fromJson(e)).toList();
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

      final List<dynamic>? data = jsonMap["responseData"];

      if (data == null || data.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No sales target data found.")),
        );
        return;
      }

      // Heavy parsing → isolate
      final parsedList = await compute<List<dynamic>, List<SalesTargetList>>(
        _parseSalesTargetList,
        data,
      );

      if (!mounted) return;

      // UPDATE UI
      setState(() {
        context.read<DailyCostingSalesTargetProvider>().updateSalesTargetList(
          parsedList,
        );

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

  List<SalesTargetList> _parseSalesTargetList(List<dynamic> data) {
    return data.map((e) => SalesTargetList.fromJson(e)).toList();
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
          final List<dynamic>? data = jsonMap["responseData"];

          if (data == null || data.isEmpty) {
            fetchedCount = 0;
          } else {
            // Heavy parsing → isolate
            final parsed = await compute<List<dynamic>, List<GRNList>>(
              _parseGRNList,
              data,
            );

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
        context.read<DailyCostingGRNProvider>().updatePurchaseList(grnItems);

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

  List<GRNList> _parseGRNList(List<dynamic> data) {
    return data.map((e) => GRNList.fromJson(e)).toList();
  }

  // ---- UI wrapper: call this from your widget (replaces your previous CPU-heavy function) ----
  Future<void> _loadDailyCostingReport(
    String priority,
    String warehouse,
  ) async {
    // show a small overlay or toast if you want. (Optional)
    showLoadingOverlay(context, message: "Preparing daily costing report...");

    final input = DailyCostingInput(
      priority: priority,
      warehouse: warehouse,
      sales: sales, // your global lists
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
        tillLastMonthPOSum = result.tillLastMonthPOSum;
        inventoryOpeningValue = result.inventoryOpeningValue;
        inventoryClosingValue = result.inventoryClosingValue;
        cogsValue = result.cogsValue;

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

  // Future<void> _loadSalesOld(String UserName, String UserLevel) async {
  //   int index = 0;
  //   int limit = 10000;
  //   int fetchedCount = 0;
  //   List<SalesList> salesList = [];
  //   final prefs = await SharedPreferences.getInstance();
  //   String selectedUser = '';
  //   final userName = selectedUser == ""
  //       ? prefs.getString('userName') ?? ''
  //       : selectedUser;
  //   try {
  //     do {
  //       var body = {
  //         // "FromDate": formatDate(monthIndex == 4 ? lastMonthFromDate! : fiscalYearStartDate!),
  //         "FromDate": dateFilterFlag
  //             ? formatDate(fromDateFilter!)
  //             : formatDate(fiscalYearStartDate!),
  //         "ToDate": dateFilterFlag
  //             ? formatDate(toDateFilter!)
  //             : formatDate(currentDate!),
  //         "Index": index.toString(),
  //         "Limit": limit.toString(),
  //         "sapToken": DataManager.readSapToken(),
  //       };
  //       const apiUrl = '${ApiHelper.baseUrl}Crm_SalesList';
  //       final response = await http.post(
  //         Uri.parse(apiUrl),
  //         headers: {
  //           HttpHeaders.contentTypeHeader: 'application/json',
  //           // HttpHeaders.authorizationHeader:
  //           //     'Bearer    ${DataManager.readSapToken()}'
  //         },
  //         body: jsonEncode(body),
  //       );

  //       if (response.statusCode == 200) {
  //         final Map<String, dynamic> responseJson = jsonDecode(response.body);
  //         if (responseJson["responseData"].toString().isNotEmpty) {
  //           List<SalesList> newSalesList =
  //               (responseJson['responseData'] as List)
  //                   .map((item) => SalesList.fromJson(item))
  //                   .toList();

  //           salesList.addAll(newSalesList);
  //           fetchedCount = newSalesList.length;
  //           index++;
  //         } else {
  //           fetchedCount = 0;
  //         }
  //       } else if (response.statusCode == 504) {
  //         await _loadSales(userName, userLevel);
  //       } else if (response.statusCode == 502) {
  //         await _loadSales(userName, userLevel);
  //       } else {
  //         fetchedCount = 0;
  //       }
  //     } while (fetchedCount == limit);

  //     setState(() {
  //       context.read<DailyCostingSalesProvider>().updateSalesList(salesList);
  //       List<String> menuNames = usersList
  //           .where((element) => element.parentMenuId == 0)
  //           .map((user) => user.menuName)
  //           .toList();
  //       menuNames.insert(0, UserName);
  //       if (int.parse(UserLevel) == 5) {
  //         if (sales.isEmpty) {
  //           sales = salesList.toList();
  //           salesTemp = salesList.toList();
  //         }
  //       } else if (int.parse(UserLevel) == 4) {
  //         if (sales.isEmpty) {
  //           sales = salesList.toList();
  //           salesTemp = salesList.toList();
  //         }
  //       } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
  //         if (sales.isEmpty) {
  //           sales = salesList.toList();
  //           salesTemp = salesList.toList();
  //         }
  //       } else {
  //         if (sales.isEmpty) {
  //           sales = salesList.toList();
  //           salesTemp = salesList.toList();
  //         }
  //       }
  //     });
  //   } catch (e) {
  //     final snackBar = SnackBar(
  //       duration: const Duration(seconds: 2),
  //       content: Text('Error: $e'),
  //     );
  //     ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //   }
  // }

  // Future<void> _loadSODetailsOld(String UserName, String UserLevel) async {
  //   int index = 0;
  //   int limit = 10000; // Maximum limit to fetch all data
  //   int fetchedCount = 0;
  //   List<SODetailsList> soDetailList = [];
  //   String selectedUser = '';
  //   final prefs = await SharedPreferences.getInstance();
  //   final userName = selectedUser == ""
  //       ? prefs.getString('userName') ?? ''
  //       : selectedUser;
  //   try {
  //     do {
  //       var body = {
  //         "FromDate": dateFilterFlag
  //             ? formatDate(fromDateFilter!)
  //             : formatDate(fiscalYearStartDate!),
  //         "ToDate": dateFilterFlag
  //             ? formatDate(toDateFilter!)
  //             : formatDate(currentDate!),
  //         "Index": index.toString(),
  //         "Limit": limit.toString(),
  //         "sapToken": DataManager.readSapToken(),
  //       };
  //       const apiUrl = '${ApiHelper.baseUrl}CRM_SOList';
  //       final response = await http.post(
  //         Uri.parse(apiUrl),
  //         headers: {
  //           HttpHeaders.contentTypeHeader: 'application/json',
  //           // HttpHeaders.authorizationHeader:
  //           //     'Bearer    ${DataManager.readSapToken()}'
  //         },
  //         body: jsonEncode(body),
  //       );

  //       if (response.statusCode == 200) {
  //         final Map<String, dynamic> responseJson = jsonDecode(response.body);
  //         if (responseJson["responseData"].toString().isNotEmpty) {
  //           List<SODetailsList> newSODetailDataList =
  //               (responseJson['responseData'] as List)
  //                   .map((item) => SODetailsList.fromJson(item))
  //                   .toList();

  //           soDetailList.addAll(newSODetailDataList);
  //           fetchedCount = newSODetailDataList.length;
  //           index++;
  //         } else {
  //           fetchedCount = 0;
  //         }
  //       } else if (response.statusCode == 504) {
  //         await _loadSODetails(userName, userLevel);
  //       } else if (response.statusCode == 502) {
  //         await _loadSODetails(userName, userLevel);
  //       } else {
  //         fetchedCount = 0;
  //       }
  //     } while (fetchedCount == limit);

  //     setState(() {
  //       context.read<DailyCostingSOListProvider>().updateSOList(soDetailList);
  //       List<String> menuNames = usersList
  //           .where((element) => element.parentMenuId == 0)
  //           .map((user) => user.menuName)
  //           .toList();
  //       menuNames.insert(0, UserName);
  //       soListTemp = soDetailList
  //           .where((test) => test.soStatus == "Open")
  //           .toList();
  //       if (int.parse(UserLevel) == 5) {
  //         if (soList.isEmpty) {
  //           soList = soDetailList
  //               .where((test) => test.soStatus == "Open")
  //               .toList();
  //         }
  //       } else if (int.parse(UserLevel) == 4) {
  //         if (soList.isEmpty) {
  //           soList = soDetailList
  //               .where((test) => test.soStatus == "Open")
  //               .toList();
  //         }
  //       } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
  //         if (soList.isEmpty) {
  //           soList = soDetailList
  //               .where((test) => test.soStatus == "Open")
  //               .toList();
  //         }
  //       } else {
  //         if (soList.isEmpty) {
  //           soList = soDetailList
  //               .where((test) => test.soStatus == "Open")
  //               .toList();
  //         }
  //       }
  //     });
  //   } catch (e) {
  //     final snackBar = SnackBar(
  //       duration: const Duration(seconds: 2),
  //       content: Text('Error: $e'),
  //     );
  //     ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //   }
  // }

  // Future<void> _loadPurchasePriceOld(String UserName, String UserLevel) async {
  //   int index = 0;
  //   int limit = 10000;
  //   int fetchedCount = 0;
  //   List<PurchaseList> salesList = [];
  //   final prefs = await SharedPreferences.getInstance();
  //   String selectedUser = '';
  //   final userName = selectedUser == ""
  //       ? prefs.getString('userName') ?? ''
  //       : selectedUser;

  //   try {
  //     do {
  //       var body = {
  //         "FromDate": dateFilterFlag
  //             ? formatDate(fromDateFilter!)
  //             : formatDate(fiscalYearStartDate!),
  //         "ToDate": dateFilterFlag
  //             ? formatDate(toDateFilter!)
  //             : formatDate(currentDate!),
  //         "Index": index.toString(),
  //         "Limit": limit.toString(),
  //         "sapToken": DataManager.readSapToken(),
  //       };
  //       const apiUrl = '${ApiHelper.baseUrl}BicxoPurchaseList';
  //       final response = await http.post(
  //         Uri.parse(apiUrl),
  //         headers: {
  //           HttpHeaders.contentTypeHeader: 'application/json',
  //           // HttpHeaders.authorizationHeader:
  //           //     'Bearer    ${DataManager.readSapToken()}'
  //         },
  //         body: jsonEncode(body),
  //       );

  //       if (response.statusCode == 200) {
  //         final Map<String, dynamic> responseJson = jsonDecode(response.body);
  //         if (responseJson["responseData"].toString().isNotEmpty) {
  //           List<PurchaseList> newSalesList =
  //               (responseJson['responseData'] as List)
  //                   .map((item) => PurchaseList.fromJson(item))
  //                   .toList();

  //           salesList.addAll(newSalesList);
  //           fetchedCount = newSalesList.length;
  //           index++;
  //         } else {
  //           fetchedCount = 0;
  //         }
  //       } else if (response.statusCode == 504) {
  //         await _loadPurchasePrice(userName, userLevel);
  //       } else if (response.statusCode == 504) {
  //         await _loadPurchasePrice(userName, userLevel);
  //       } else {
  //         fetchedCount = 0;
  //       }
  //     } while (fetchedCount == limit);

  //     setState(() {
  //       if (purchasePrice.isEmpty) {
  //         purchasePrice = salesList.toList();
  //       }
  //       context.read<DailyCostingPurchaseProvider>().updatePurchaseList(
  //         salesList,
  //       );

  //       List<String> menuNames = usersList
  //           .where((element) => element.parentMenuId == 0)
  //           .map((user) => user.menuName)
  //           .toList();
  //       menuNames.insert(0, UserName);
  //       purchasePriceTemp = salesList.toList();
  //       if (int.parse(UserLevel) == 5) {
  //         if (purchasePrice.isEmpty) {
  //           purchasePrice = salesList.toList();
  //         }
  //       } else if (int.parse(UserLevel) == 4) {
  //         if (purchasePrice.isEmpty) {
  //           purchasePrice = salesList.toList();
  //         }
  //       } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
  //         if (purchasePrice.isEmpty) {
  //           purchasePrice = salesList.toList();
  //         }
  //       } else {
  //         if (purchasePrice.isEmpty) {
  //           purchasePrice = salesList.toList();
  //         }
  //       }
  //       if (purchasePrice.isEmpty) {
  //         purchasePrice = salesList.toList();
  //       }
  //     });
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print(e);
  //     }
  //     final snackBar = SnackBar(
  //       duration: const Duration(seconds: 2),
  //       content: Text('Error: $e'),
  //     );
  //     ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //   }
  // }

  // Future<void> _loadGRNOld(String UserName, String UserLevel) async {
  //   int index = 0;
  //   int limit = 10000;
  //   int fetchedCount = 0;
  //   List<GRNList> salesList = [];
  //   final prefs = await SharedPreferences.getInstance();
  //   String selectedUser = '';
  //   final userName = selectedUser == ""
  //       ? prefs.getString('userName') ?? ''
  //       : selectedUser;

  //   try {
  //     do {
  //       var body = {
  //         "FromDate": dateFilterFlag
  //             ? formatDate(fromDateFilter!)
  //             : formatDate(fiscalYearStartDate!),
  //         "ToDate": dateFilterFlag
  //             ? formatDate(toDateFilter!)
  //             : formatDate(currentDate!),
  //         "Index": index.toString(),
  //         "Limit": limit.toString(),
  //         "sapToken": DataManager.readSapToken(),
  //       };
  //       const apiUrl = '${ApiHelper.baseUrl}BicxoGoodsReceiptNoteList';
  //       final response = await http.post(
  //         Uri.parse(apiUrl),
  //         headers: {
  //           HttpHeaders.contentTypeHeader: 'application/json',
  //           // HttpHeaders.authorizationHeader:
  //           //     'Bearer    ${DataManager.readSapToken()}'
  //         },
  //         body: jsonEncode(body),
  //       );

  //       if (response.statusCode == 200) {
  //         final Map<String, dynamic> responseJson = jsonDecode(response.body);
  //         if (responseJson["responseData"].toString().isNotEmpty) {
  //           List<GRNList> newSalesList = (responseJson['responseData'] as List)
  //               .map((item) => GRNList.fromJson(item))
  //               .toList();

  //           salesList.addAll(newSalesList);
  //           fetchedCount = newSalesList.length;
  //           index++;
  //         } else {
  //           fetchedCount = 0;
  //         }
  //       } else if (response.statusCode == 504) {
  //         await _loadGRN(userName, userLevel);
  //       } else if (response.statusCode == 504) {
  //         await _loadGRN(userName, userLevel);
  //       } else {
  //         fetchedCount = 0;
  //       }
  //     } while (fetchedCount == limit);

  //     setState(() {
  //       if (grnList.isEmpty) {
  //         grnList = salesList.toList();
  //       }
  //       context.read<DailyCostingGRNProvider>().updatePurchaseList(salesList);

  //       List<String> menuNames = usersList
  //           .where((element) => element.parentMenuId == 0)
  //           .map((user) => user.menuName)
  //           .toList();
  //       menuNames.insert(0, UserName);
  //       grnListTemp = salesList.toList();
  //       if (int.parse(UserLevel) == 5) {
  //         if (grnList.isEmpty) {
  //           grnList = salesList.toList();
  //         }
  //       } else if (int.parse(UserLevel) == 4) {
  //         if (grnList.isEmpty) {
  //           grnList = salesList.toList();
  //         }
  //       } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
  //         if (grnList.isEmpty) {
  //           grnList = salesList.toList();
  //         }
  //       } else {
  //         if (grnList.isEmpty) {
  //           grnList = salesList.toList();
  //         }
  //       }
  //       if (grnList.isEmpty) {
  //         grnList = salesList.toList();
  //       }
  //     });
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print(e);
  //     }
  //     final snackBar = SnackBar(
  //       duration: const Duration(seconds: 2),
  //       content: Text('Error: $e'),
  //     );
  //     ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //   }
  // }

  // Future<void> _loadPOListOld(String UserName, String UserLevel) async {
  //   int index = 0;
  //   int limit = 10000; // Maximum limit to fetch all data
  //   int fetchedCount = 0;
  //   List<POList> salesList = [];
  //   final prefs = await SharedPreferences.getInstance();
  //   String selectedUser = '';
  //   final userName = selectedUser == ""
  //       ? prefs.getString('userName') ?? ''
  //       : selectedUser;
  //   try {
  //     do {
  //       var body = {
  //         // "FromDate": dateFilterFlag
  //         //     ? formatDate(fromDateFilter!)
  //         //     : formatDate(fiscalYearStartDate!),
  //         "ToDate": dateFilterFlag
  //             ? formatDate(toDateFilter!)
  //             : formatDate(currentDate!),
  //         "Index": index.toString(),
  //         "Limit": limit.toString(),
  //         "sapToken": DataManager.readSapToken(),
  //       };
  //       const apiUrl = '${ApiHelper.baseUrl}BicxoPOList';
  //       final response = await http.post(
  //         Uri.parse(apiUrl),
  //         headers: {
  //           HttpHeaders.contentTypeHeader: 'application/json',
  //           // HttpHeaders.authorizationHeader:
  //           //     'Bearer    ${DataManager.readSapToken()}'
  //         },
  //         body: jsonEncode(body),
  //       );

  //       if (response.statusCode == 200) {
  //         final Map<String, dynamic> responseJson = jsonDecode(response.body);
  //         if (responseJson["responseData"].toString().isNotEmpty) {
  //           List<POList> newSalesList = (responseJson['responseData'] as List)
  //               .map((item) => POList.fromJson(item))
  //               .toList();
  //           salesList.addAll(newSalesList);
  //           fetchedCount = newSalesList.length;
  //           index++;
  //         } else {
  //           fetchedCount = 0;
  //         }
  //       } else if (response.statusCode == 504) {
  //         await _loadPOList(userName, userLevel);
  //       } else if (response.statusCode == 502) {
  //         await _loadPOList(userName, userLevel);
  //       } else {
  //         fetchedCount = 0;
  //       }
  //     } while (fetchedCount == limit);

  //     setState(() {
  //       // poList = salesList;
  //       context.read<DailyCostingPOProvider>().updatePOList(salesList);
  //       // poList = salesList.where((sale) => sale.type == "Item Purchase").toList();
  //       if (poListOpen.isEmpty) {
  //         poListOpen = salesList
  //             .where(
  //               (sale) => /*sale.type == "Item Purchase" && */
  //                   sale.poStatus == "Open" && sale.groupName != "Fixed Assets",
  //             )
  //             .toList();
  //         poListOpenTemp = salesList
  //             .where(
  //               (sale) => /*sale.type == "Item Purchase" && */
  //                   sale.poStatus == "Open" && sale.groupName != "Fixed Assets",
  //             )
  //             .toList();
  //       }
  //     });
  //   } catch (e) {
  //     final snackBar = SnackBar(
  //       duration: const Duration(seconds: 2),
  //       content: Text('Error: $e'),
  //     );
  //     ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //   }
  // }

  // Future<void> _loadInventoryOld(String UserName, String UserLevel) async {
  //   int index = 0;
  //   int limit = 10000;
  //   int fetchedCount = 0;
  //   List<InventoryList> salesList = [];
  //   final prefs = await SharedPreferences.getInstance();
  //   String selectedUser = '';
  //   final userName = selectedUser == ""
  //       ? prefs.getString('userName') ?? ''
  //       : selectedUser;
  //   try {
  //     do {
  //       var body = {
  //         "ToDate": dateFilterFlag
  //             ? formatDate(toDateFilter!)
  //             : formatDate(lastMonthToDate!),
  //         "Index": index.toString(),
  //         "Limit": limit.toString(),
  //         "sapToken": DataManager.readSapToken(),
  //       };
  //       const apiUrl = '${ApiHelper.baseUrl}BicxoInventoryAgeingList';
  //       final response = await http.post(
  //         Uri.parse(apiUrl),
  //         headers: {
  //           HttpHeaders.contentTypeHeader: 'application/json',
  //           // HttpHeaders.authorizationHeader:
  //           // 'Bearer    ${DataManager.readSapToken()}'
  //         },
  //         body: jsonEncode(body),
  //       );

  //       if (response.statusCode == 200) {
  //         final Map<String, dynamic> responseJson = jsonDecode(response.body);
  //         if (responseJson["responseData"].toString().isNotEmpty) {
  //           List<InventoryList> newSalesList =
  //               (responseJson['responseData'] as List)
  //                   .map((item) => InventoryList.fromJson(item))
  //                   .toList();

  //           salesList.addAll(newSalesList);
  //           fetchedCount = newSalesList.length;
  //           index++;
  //         } else {
  //           fetchedCount = 0;
  //         }
  //       } else if (response.statusCode == 504) {
  //         await _loadInventory(userName, userLevel);
  //       } else if (response.statusCode == 502) {
  //         await _loadInventory(userName, userLevel);
  //       } else {
  //         fetchedCount = 0;
  //       }
  //     } while (fetchedCount == limit);

  //     setState(() {
  //       context.read<DailyCostingInventoryProvider>().updateInventoryList(
  //         salesList,
  //       );
  //       List<String> menuNames = usersList
  //           .where((element) => element.parentMenuId == 0)
  //           .map((user) => user.menuName)
  //           .toList();
  //       menuNames.insert(0, UserName);
  //       if (int.parse(UserLevel) == 5) {
  //         if (inventory.isEmpty) {
  //           inventory = salesList.toList();
  //         }
  //       } else if (int.parse(UserLevel) == 4) {
  //         if (inventory.isEmpty) {
  //           inventory = salesList.toList();
  //         }
  //       } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
  //         if (inventory.isEmpty) {
  //           inventory = salesList.toList();
  //         }
  //       } else {
  //         if (inventory.isEmpty) {
  //           inventory = salesList.toList();
  //         }
  //       }
  //     });
  //   } catch (e) {
  //     if (mounted) {
  //       final snackBar = SnackBar(
  //         duration: const Duration(seconds: 2),
  //         content: Text('Error: $e'),
  //       );
  //       ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //     }
  //   }
  // }

  // Future<void> _loadInventoryClosingOld(
  //   String UserName,
  //   String UserLevel,
  // ) async {
  //   int index = 0;
  //   int limit = 10000;
  //   int fetchedCount = 0;
  //   List<InventoryList> salesList = [];
  //   final prefs = await SharedPreferences.getInstance();
  //   String selectedUser = '';
  //   final userName = selectedUser == ""
  //       ? prefs.getString('userName') ?? ''
  //       : selectedUser;
  //   try {
  //     do {
  //       var body = {
  //         "ToDate": dateFilterFlag
  //             ? formatDate(toDateFilter!)
  //             : formatDate(currentDate!),
  //         "Index": index.toString(),
  //         "Limit": limit.toString(),
  //         "sapToken": DataManager.readSapToken(),
  //       };
  //       const apiUrl = '${ApiHelper.baseUrl}BicxoInventoryAgeingList';
  //       final response = await http.post(
  //         Uri.parse(apiUrl),
  //         headers: {
  //           HttpHeaders.contentTypeHeader: 'application/json',
  //           // HttpHeaders.authorizationHeader:
  //           // 'Bearer    ${DataManager.readSapToken()}'
  //         },
  //         body: jsonEncode(body),
  //       );

  //       if (response.statusCode == 200) {
  //         final Map<String, dynamic> responseJson = jsonDecode(response.body);
  //         if (responseJson["responseData"].toString().isNotEmpty) {
  //           List<InventoryList> newSalesList =
  //               (responseJson['responseData'] as List)
  //                   .map((item) => InventoryList.fromJson(item))
  //                   .toList();

  //           salesList.addAll(newSalesList);
  //           fetchedCount = newSalesList.length;
  //           index++;
  //         } else {
  //           fetchedCount = 0;
  //         }
  //       } else if (response.statusCode == 504) {
  //         await _loadInventoryClosing(userName, userLevel);
  //       } else if (response.statusCode == 502) {
  //         await _loadInventoryClosing(userName, userLevel);
  //       } else {
  //         fetchedCount = 0;
  //       }
  //     } while (fetchedCount == limit);

  //     setState(() {
  //       context
  //           .read<DailyCostingInventoryClosingProvider>()
  //           .updateInventoryList(salesList);
  //       List<String> menuNames = usersList
  //           .where((element) => element.parentMenuId == 0)
  //           .map((user) => user.menuName)
  //           .toList();
  //       menuNames.insert(0, UserName);
  //       if (int.parse(UserLevel) == 5) {
  //         if (inventoryClosing.isEmpty) {
  //           inventoryClosing = salesList.toList();
  //         }
  //       } else if (int.parse(UserLevel) == 4) {
  //         if (inventoryClosing.isEmpty) {
  //           inventoryClosing = salesList.toList();
  //         }
  //       } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
  //         if (inventoryClosing.isEmpty) {
  //           inventoryClosing = salesList.toList();
  //         }
  //       } else {
  //         if (inventoryClosing.isEmpty) {
  //           inventoryClosing = salesList.toList();
  //         }
  //       }
  //     });
  //   } catch (e) {
  //     if (mounted) {
  //       final snackBar = SnackBar(
  //         duration: const Duration(seconds: 2),
  //         content: Text('Error: $e'),
  //       );
  //       ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //     }
  //   }
  // }

  // Future<void> _loadSalesTargetOld(String UserName, String UserLevel) async {
  //   final body = {
  //     "FromDate": dateFilterFlag
  //         ? formatDate(fromDateFilter!)
  //         : formatDate(fiscalYearStartDate!),
  //     "ToDate": dateFilterFlag
  //         ? formatDate(toDateFilter!)
  //         : formatDate(currentDate!),
  //     "Index": 0,
  //     "Limit": 0,
  //     "sapToken": DataManager.readSapToken(),
  //   };
  //   const apiUrl = '${ApiHelper.baseUrl}BicxoSalesTargetList';
  //   var headers = {
  //     HttpHeaders.contentTypeHeader: 'application/json',
  //     // HttpHeaders.authorizationHeader: 'Bearer    ${DataManager.readSapToken()}'
  //   };
  //   try {
  //     final response = await http.post(
  //       Uri.parse(apiUrl),
  //       body: jsonEncode(body),
  //       headers: headers,
  //     );
  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> responseJson = jsonDecode(response.body);
  //       if (responseJson["responseData"].toString().isNotEmpty) {
  //         List<dynamic> data = responseJson['responseData'];
  //         if (data.isNotEmpty) {
  //           List<SalesTargetList> newSalesTargetList = (data)
  //               .map((item) => SalesTargetList.fromJson(item))
  //               .toList();
  //           setState(() {
  //             List<String> menuNames = usersList
  //                 .where((element) => element.parentMenuId == 0)
  //                 .map((user) => user.menuName)
  //                 .toList();
  //             menuNames.insert(0, UserName);
  //             context
  //                 .read<DailyCostingSalesTargetProvider>()
  //                 .updateSalesTargetList(newSalesTargetList);
  //             if (int.parse(UserLevel) == 5) {
  //               salesTarget = newSalesTargetList;
  //             } else if (int.parse(UserLevel) == 4) {
  //               salesTarget = newSalesTargetList;
  //             } else if (int.parse(UserLevel) <= 3 &&
  //                 int.parse(UserLevel) >= 2) {
  //               salesTarget = newSalesTargetList;
  //             } else {
  //               salesTarget = newSalesTargetList;
  //             }
  //           });
  //         }
  //       } else {
  //         if (responseJson.containsKey("Error") &&
  //             responseJson["Error"].toString() == "Invalid or Expired Token") {
  //           final snackBar = SnackBar(
  //             duration: const Duration(seconds: 1),
  //             content: Text(
  //               responseJson["Error"].toString(),
  //               style: const TextStyle(color: Colors.white, fontSize: 16),
  //             ),
  //           );
  //           ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //           navigateToLoginScreen();
  //         } else {
  //           final snackBar = SnackBar(
  //             content: Text(responseJson["Error"].toString()),
  //           );
  //           ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //         }
  //       }
  //     } else {
  //       const snackBar = SnackBar(
  //         content: Text('Sales target details not found.'),
  //       );
  //       ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //     }
  //   } catch (e) {
  //     const snackBar = SnackBar(
  //       content: Text('SAP Server down, Please try again after some time.'),
  //     );
  //     ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //   }
  // }

  // Future<void> _loadDailyCostingReportOld(
  //   String priority,
  //   String warehouse,
  // ) async {
  //   clearVariables();
  //   List<SalesList> monthlySalesList = [];
  //   List<SODetailsList> salesOrderList = [];
  //   List<PurchaseList> purchaseListTemp = [];
  //   List<GRNList> grnTemp = [];
  //   List<POList> poListCurrentTemp = [];
  //   List<POList> poListLastMonthTemp = [];
  //   List<POList> poListBeforeLastMonth = [];
  //   List<InventoryList> inventoryTemp = [];
  //   List<InventoryList> inventoryClosingTemp = [];

  //   String getCurrentFinancialYearSuffix() {
  //     final now = DateTime.now();
  //     final year = now.year;
  //     final month = now.month;

  //     int startYear = (month >= 4) ? year : year - 1;
  //     int endYear = startYear + 1;

  //     return "FY${startYear % 100}-${endYear % 100}-T";
  //   }

  //   List<SalesTargetList> tempTarget = salesTarget
  //       .where((test) => test.financialYear == getCurrentFinancialYearSuffix())
  //       .toList();

  //   String Month = getMonthName(DateTime.now().month);

  //   for (var target in tempTarget) {
  //     if (target.salesRep == "MD SALES TARGET") {
  //       medicalDeviceTarget =
  //           double.tryParse(target.getTargetForMonth(Month)) ?? 0;
  //     }
  //     if (target.salesRep == "IPD SALES TARGET") {
  //       ipdTarget = double.tryParse(target.getTargetForMonth(Month)) ?? 0;
  //     }
  //     if (target.salesRep == "PURCHASE TARGET") {
  //       purchaseTarget = double.tryParse(target.getTargetForMonth(Month)) ?? 0;
  //     }
  //     if (target.salesRep == "COGS TARGET") {
  //       cogsTarget = double.tryParse(target.getTargetForMonth(Month)) ?? 0;
  //     }
  //     if (target.salesRep == "INVENTORY TARGET") {
  //       inventoryTarget = double.tryParse(target.getTargetForMonth(Month)) ?? 0;
  //     }
  //     if (target.salesRep == "PRODUCTION TARGET") {
  //       productionTarget =
  //           double.tryParse(target.getTargetForMonth(Month)) ?? 0;
  //     }
  //   }

  //   monthlySalesList = sales.where((target) {
  //     DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
  //     return invoiceDate.isAtLeast(currentMonthFromDate!) &&
  //         invoiceDate.isAtMost(currentMonthToDate!);
  //   }).toList();
  //   double salesAmt = 0;
  //   for (var target in monthlySalesList.toList()) {
  //     /*      if (target.invoiceType != "Sales Return") {
  //       salesAmt = double.tryParse(target.rowTotal) ?? 0;
  //     } else {*/
  //     salesAmt = (double.tryParse(target.rowTotal) ?? 0);

  //     if (target.itemSubGroup == "Medical Device") {
  //       medicalDevicesSales += double.tryParse(target.rowTotal) ?? 0;
  //     } else {
  //       ipdSales += (double.tryParse(target.rowTotal) ?? 0);
  //     }

  //     // }
  //     monthlySales += salesAmt;
  //   }

  //   revenueBreakup.graphData.add(
  //     DailyCostingGraphData(
  //       name: "Medical Device",
  //       target: medicalDeviceTarget,
  //       achievement: medicalDevicesSales,
  //       percentage: (medicalDeviceTarget == 0)
  //           ? 0
  //           : double.parse(
  //               ((medicalDevicesSales / medicalDeviceTarget) * 100)
  //                   .toStringAsFixed(0),
  //             ),
  //     ),
  //   );

  //   revenueBreakup.graphData.add(
  //     DailyCostingGraphData(
  //       name: "IPD",
  //       target: ipdTarget,
  //       achievement: ipdSales,
  //       percentage: (ipdTarget == 0)
  //           ? 0
  //           : double.parse(((ipdSales / ipdTarget) * 100).toStringAsFixed(0)),
  //     ),
  //   );

  //   double revenueTarget = medicalDeviceTarget + ipdTarget;

  //   dailyCostingData.graphData.add(
  //     DailyCostingGraphData(
  //       name: "Revenue",
  //       target: medicalDeviceTarget + ipdTarget,
  //       achievement: monthlySales,
  //       percentage: (revenueTarget == 0)
  //           ? 0
  //           : double.parse(
  //               ((monthlySales / revenueTarget) * 100).toStringAsFixed(0),
  //             ),
  //     ),
  //   );

  //   // salesOrderList = soList.where((target) {
  //   //   return target.soStatus == "Open";
  //   // }).toList();

  //   salesOrderList = soList.where((target) {
  //     if (target.soStatus != "Open") return false;

  //     if (priority.isNotEmpty && target.priority != priority) {
  //       return false;
  //     }

  //     if (warehouse.isNotEmpty) {
  //       if (warehouse == "Karnataka State" || warehouse == "Tamil Nadu State") {
  //         if (target.branchName != warehouse) return false;
  //       } else if (warehouse == "Others") {
  //         if (target.branchName == "Karnataka State" ||
  //             target.branchName == "Tamil Nadu State") {
  //           return false;
  //         }
  //       } else {
  //         return false;
  //       }
  //     }

  //     return true;
  //   }).toList();

  //   for (var target in salesOrderList) {
  //     if (target.priority == "Low") {
  //       lowVal += double.tryParse(target.pendingValue) ?? 0;
  //     } else if (target.priority == "Medium") {
  //       mediumVal += (double.tryParse(target.pendingValue) ?? 0);
  //     } else if (target.priority == "High") {
  //       highVal += (double.tryParse(target.pendingValue) ?? 0);
  //     }
  //     if (target.branchName == "Karnataka State") {
  //       karnatakaPOSum += double.tryParse(target.pendingValue) ?? 0;
  //     } else if (target.branchName == "Tamil Nadu State") {
  //       tamilNaduPOSum += (double.tryParse(target.pendingValue) ?? 0);
  //     } else {
  //       othersPOSum += (double.tryParse(target.pendingValue) ?? 0);
  //     }
  //     monthlySOvalue += (double.tryParse(target.pendingValue) ?? 0);
  //   }

  //   saleOrderPriorityBreakup.graphData.add(
  //     DailyCostingGraphData(
  //       name: "Low Priority",
  //       target: 0,
  //       achievement: lowVal,
  //       percentage: 0,
  //     ),
  //   );
  //   saleOrderPriorityBreakup.graphData.add(
  //     DailyCostingGraphData(
  //       name: "Medium Priority",
  //       target: 0,
  //       achievement: mediumVal,
  //       percentage: 0,
  //     ),
  //   );
  //   saleOrderPriorityBreakup.graphData.add(
  //     DailyCostingGraphData(
  //       name: "High Priority",
  //       target: 0,
  //       achievement: highVal,
  //       percentage: 0,
  //     ),
  //   );

  //   saleOrderWarehouseBreakup.graphData.add(
  //     DailyCostingGraphData(
  //       name: "Karnataka State",
  //       target: 0,
  //       achievement: karnatakaPOSum,
  //       percentage: 0,
  //     ),
  //   );
  //   saleOrderWarehouseBreakup.graphData.add(
  //     DailyCostingGraphData(
  //       name: "Tamil Nadu State",
  //       target: 0,
  //       achievement: tamilNaduPOSum,
  //       percentage: 0,
  //     ),
  //   );
  //   saleOrderWarehouseBreakup.graphData.add(
  //     DailyCostingGraphData(
  //       name: "Others",
  //       target: 0,
  //       achievement: othersPOSum,
  //       percentage: 0,
  //     ),
  //   );

  //   purchaseListTemp = purchasePrice.where((target) {
  //     DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.invoiceDate);
  //     return invoiceDate.isAtLeast(currentMonthFromDate!) &&
  //         invoiceDate.isAtMost(currentMonthToDate!);
  //   }).toList();

  //   for (var target in purchaseListTemp) {
  //     monthlyPurchasePriceSum += (double.tryParse(target.rowTotal) ?? 0);
  //   }

  //   dailyCostingData.graphData.add(
  //     DailyCostingGraphData(
  //       name: "Purchase",
  //       target: purchaseTarget,
  //       achievement: monthlyPurchasePriceSum,
  //       percentage: (purchaseTarget == 0)
  //           ? 0
  //           : double.parse(
  //               ((monthlyPurchasePriceSum / purchaseTarget) * 100)
  //                   .toStringAsFixed(0),
  //             ),
  //     ),
  //   );

  //   grnTemp = grnList.where((target) {
  //     DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.grnDate);
  //     return invoiceDate.isAtLeast(currentMonthFromDate!) &&
  //         invoiceDate.isAtMost(currentMonthToDate!);
  //   }).toList();

  //   for (var target in grnTemp) {
  //     monthlyPurchasePriceGrnSum += (double.tryParse(target.rowTotal) ?? 0);
  //   }

  //   poListCurrentTemp = poListOpen.where((target) {
  //     DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
  //     return invoiceDate.isAtLeast(currentMonthFromDate!) &&
  //         invoiceDate.isAtMost(currentMonthToDate!);
  //   }).toList();
  //   poListLastMonthTemp = poListOpen.where((target) {
  //     DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
  //     return invoiceDate.isAtLeast(lastMonthFromDate!) &&
  //         invoiceDate.isAtMost(lastMonthToDate!);
  //   }).toList();

  //   poListBeforeLastMonth = poListOpen.where((target) {
  //     DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.poDate);
  //     return invoiceDate.isAtMost(lastMonthFromDate!);
  //   }).toList();

  //   for (var target in poListOpen) {
  //     monthlyPOSum += (double.tryParse(target.pendingValue) ?? 0);
  //   }
  //   for (var target in poListCurrentTemp) {
  //     currentMonthPOSum += (double.tryParse(target.pendingValue) ?? 0);
  //   }
  //   for (var target in poListLastMonthTemp) {
  //     lastMonthPOSum += (double.tryParse(target.pendingValue) ?? 0);
  //   }
  //   for (var target in poListBeforeLastMonth) {
  //     tillLastMonthPOSum += (double.tryParse(target.pendingValue) ?? 0);
  //   }

  //   inventoryTemp = inventory;
  //   for (var target in inventoryTemp) {
  //     if (target.ageingBrackets == "<30 Days") {
  //       lessThan30DaysValue += (double.tryParse(target.totalValue) ?? 0);
  //     }
  //     if (target.ageingBrackets == "31-45 Days" ||
  //         target.ageingBrackets == "31-45 Days") {
  //       a30to60DaysValue += (double.tryParse(target.totalValue) ?? 0);
  //     }
  //     if (target.ageingBrackets == "61-90 Days") {
  //       a60to90DaysValue += (double.tryParse(target.totalValue) ?? 0);
  //     }
  //     if (target.ageingBrackets == "91-120 Days" ||
  //         target.ageingBrackets == "121-150 Days" ||
  //         target.ageingBrackets == "151-180 Days" ||
  //         target.ageingBrackets == "181-365 Days" ||
  //         target.ageingBrackets == "366-730 Days" ||
  //         target.ageingBrackets == ">730 Days") {
  //       a91DaysValue += (double.tryParse(target.totalValue) ?? 0);
  //     }
  //     if (target.ageingBrackets == "91-120 Days" ||
  //         target.ageingBrackets == "121-150 Days" ||
  //         target.ageingBrackets == "151-180 Days") {
  //       nearExpiryValue += (double.tryParse(target.totalValue) ?? 0);
  //     }
  //     if (target.ageingBrackets == "181-365 Days" ||
  //         target.ageingBrackets == "366-730 Days" ||
  //         target.ageingBrackets == ">730 Days") {
  //       expiredValue += (double.tryParse(target.totalValue) ?? 0);
  //     }

  //     inventoryOpeningValue += (double.parse(target.totalValue));
  //   }

  //   inventoryClosingTemp = inventoryClosing;
  //   for (var target in inventoryClosingTemp) {
  //     inventoryClosingValue += (double.parse(target.totalValue));
  //   }

  //   cogsValue =
  //       (inventoryOpeningValue + monthlyPurchasePriceGrnSum) -
  //       (lessThan30DaysValue +
  //           a30to60DaysValue +
  //           a60to90DaysValue +
  //           nearExpiryValue +
  //           expiredValue);

  //   double inventoryAchieved =
  //       lessThan30DaysValue +
  //       a30to60DaysValue +
  //       a60to90DaysValue +
  //       nearExpiryValue +
  //       expiredValue;

  //   dailyCostingData.graphData.add(
  //     DailyCostingGraphData(
  //       name: "Inventory",
  //       target: inventoryTarget,
  //       achievement: inventoryAchieved,
  //       percentage: (inventoryTarget == 0)
  //           ? 0
  //           : double.parse(
  //               ((inventoryAchieved / inventoryTarget) * 100).toStringAsFixed(
  //                 0,
  //               ),
  //             ),
  //     ),
  //   );
  //   dailyCostingData.graphData.add(
  //     DailyCostingGraphData(
  //       name: "COGS",
  //       target: cogsTarget,
  //       achievement: cogsValue,
  //       percentage: (cogsTarget == 0)
  //           ? 0
  //           : double.parse(((cogsValue / cogsTarget) * 100).toStringAsFixed(0)),
  //     ),
  //   );

  //   inventoryAging.graphData.add(
  //     DailyCostingGraphData(
  //       name: "> 30 Days",
  //       target: 0,
  //       achievement: lessThan30DaysValue,
  //       percentage: 0,
  //     ),
  //   );
  //   inventoryAging.graphData.add(
  //     DailyCostingGraphData(
  //       name: "31 - 60 Days",
  //       target: 0,
  //       achievement: a30to60DaysValue,
  //       percentage: 0,
  //     ),
  //   );
  //   inventoryAging.graphData.add(
  //     DailyCostingGraphData(
  //       name: "61 - 90 Days",
  //       target: 0,
  //       achievement: a30to60DaysValue,
  //       percentage: 0,
  //     ),
  //   );
  //   inventoryAging.graphData.add(
  //     DailyCostingGraphData(
  //       name: "Near Expiry",
  //       target: 0,
  //       achievement: nearExpiryValue,
  //       percentage: 0,
  //     ),
  //   );
  //   inventoryAging.graphData.add(
  //     DailyCostingGraphData(
  //       name: "Expired Stock",
  //       target: 0,
  //       achievement: expiredValue,
  //       percentage: 0,
  //     ),
  //   );
  // }

  // Future<void> generateDailyCostingReport() async {
  //   final excel = xl.Excel.createExcel();
  //   final sheet = excel['Sheet1'];
  //   // sheet.getColAutoFits;

  //   sheet.appendRow(
  //     toCellRow(toCellRow([(DateTime.now().toString().substring(0, 10))])),
  //   );
  //   sheet.appendRow(toCellRow(toCellRow(["Financial Year for 25-26"])));
  //   sheet.appendRow(
  //     toCellRow([
  //       "",
  //       "",
  //       "Target - ${getMonthName(DateTime.now().month)} ${DateTime.now().year}",
  //       "Achievement - ${getMonthName(DateTime.now().month)} ${DateTime.now().year}",
  //       "Percentage - ${getMonthName(DateTime.now().month)} ${DateTime.now().year}",
  //     ]),
  //   );

  //   sheet.appendRow(
  //     toCellRow([
  //       "Revenue",
  //       "",
  //       (medicalDeviceTarget + ipdTarget).toStringAsFixed(0),
  //       monthlySales.toStringAsFixed(0),
  //       ((monthlySales / (medicalDeviceTarget + ipdTarget)) * 100)
  //           .toStringAsFixed(0),
  //     ]),
  //   );
  //   sheet.appendRow(
  //     toCellRow([
  //       "",
  //       "Medical Devices",
  //       medicalDeviceTarget.toStringAsFixed(0),
  //       medicalDevicesSales.toStringAsFixed(0),
  //       ((medicalDevicesSales / medicalDeviceTarget) * 100).toStringAsFixed(0),
  //     ]),
  //   );
  //   sheet.appendRow(
  //     toCellRow([
  //       "",
  //       "IPD",
  //       ipdTarget.toStringAsFixed(0),
  //       ipdSales.toStringAsFixed(0),
  //       ((ipdSales / ipdTarget) * 100).toStringAsFixed(0),
  //     ]),
  //   );
  //   sheet.appendRow(toCellRow([""]));

  //   sheet.appendRow(
  //     toCellRow([
  //       "Pending Sales Order",
  //       "",
  //       "",
  //       monthlySOvalue.toStringAsFixed(0),
  //       "",
  //     ]),
  //   );
  //   sheet.appendRow(
  //     toCellRow(["", "Low Priority", "", lowVal.toStringAsFixed(0), ""]),
  //   );
  //   sheet.appendRow(
  //     toCellRow(["", "Medium Priority", "", mediumVal.toStringAsFixed(0), ""]),
  //   );
  //   sheet.appendRow(
  //     toCellRow(["", "High Priority", "", highVal.toStringAsFixed(0), ""]),
  //   );
  //   sheet.appendRow(toCellRow([""]));

  //   sheet.appendRow(
  //     toCellRow([
  //       "Pending Sales Order",
  //       "",
  //       "",
  //       (karnatakaPOSum + tamilNaduPOSum + othersPOSum).toStringAsFixed(0),
  //       "",
  //     ]),
  //   );
  //   sheet.appendRow(
  //     toCellRow(["", "Bangalore", "", karnatakaPOSum.toStringAsFixed(0), ""]),
  //   );
  //   sheet.appendRow(
  //     toCellRow(["", "Rajapalayam", "", tamilNaduPOSum.toStringAsFixed(0), ""]),
  //   );
  //   sheet.appendRow(
  //     toCellRow(["", "Others", "", othersPOSum.toStringAsFixed(0), ""]),
  //   );
  //   sheet.appendRow(toCellRow([""]));

  //   sheet.appendRow(
  //     toCellRow([
  //       "Purchases",
  //       "",
  //       purchaseTarget.toStringAsFixed(0),
  //       monthlyPurchasePriceGrnSum.toStringAsFixed(0),
  //       ((monthlyPurchasePriceGrnSum / purchaseTarget) * 100).toStringAsFixed(
  //         0,
  //       ),
  //     ]),
  //   );
  //   sheet.appendRow(toCellRow([""]));

  //   sheet.appendRow(
  //     toCellRow([
  //       "Pending Purchase Order",
  //       "",
  //       "",
  //       monthlyPOSum.toStringAsFixed(0),
  //       "",
  //     ]),
  //   );
  //   sheet.appendRow(
  //     toCellRow([
  //       "",
  //       "Till ${getMonthName(DateTime.now().month - 2)}",
  //       "",
  //       tillLastMonthPOSum.toStringAsFixed(0),
  //       "",
  //     ]),
  //   );
  //   sheet.appendRow(
  //     toCellRow([
  //       "",
  //       "${getMonthName(DateTime.now().month - 1)} ${DateTime.now().year}",
  //       "",
  //       lastMonthPOSum.toStringAsFixed(0),
  //       "",
  //     ]),
  //   );
  //   sheet.appendRow(
  //     toCellRow([
  //       "",
  //       "${getMonthName(DateTime.now().month - 0)} ${DateTime.now().year}",
  //       "",
  //       currentMonthPOSum.toStringAsFixed(0),
  //       "",
  //     ]),
  //   );
  //   sheet.appendRow(toCellRow([""]));
  //   sheet.appendRow(
  //     toCellRow([
  //       "Opening Stock",
  //       "",
  //       '',
  //       inventoryOpeningValue.toStringAsFixed(0),
  //     ]),
  //   );
  //   sheet.appendRow(toCellRow([""]));
  //   sheet.appendRow(
  //     toCellRow([
  //       "Inventory Aging",
  //       "",
  //       inventoryTarget.toStringAsFixed(0),
  //       (inventoryClosingValue).toStringAsFixed(0),
  //       (((lessThan30DaysValue +
  //                       a30to60DaysValue +
  //                       a60to90DaysValue +
  //                       nearExpiryValue +
  //                       expiredValue) /
  //                   inventoryTarget) *
  //               100)
  //           .toStringAsFixed(0),
  //     ]),
  //   );
  //   sheet.appendRow(
  //     toCellRow([
  //       "",
  //       "<30 Days",
  //       "",
  //       lessThan30DaysValue.toStringAsFixed(0),
  //       "",
  //     ]),
  //   );
  //   sheet.appendRow(
  //     toCellRow([
  //       "",
  //       "31-60 Days",
  //       "",
  //       a30to60DaysValue.toStringAsFixed(0),
  //       "",
  //     ]),
  //   );
  //   sheet.appendRow(
  //     toCellRow([
  //       "",
  //       "61-90 Days",
  //       "",
  //       a60to90DaysValue.toStringAsFixed(0),
  //       "",
  //     ]),
  //   );
  //   sheet.appendRow(
  //     toCellRow(["", "> 90 Days", "", (a91DaysValue).toStringAsFixed(0), ""]),
  //   );
  //   sheet.appendRow(
  //     toCellRow([
  //       "",
  //       "Near Expiry",
  //       "",
  //       nearExpiryValue.toStringAsFixed(0),
  //       "",
  //     ]),
  //   );
  //   sheet.appendRow(
  //     toCellRow([
  //       "",
  //       "Expired Stock",
  //       "",
  //       (expiredValue.toStringAsFixed(0)),
  //       "",
  //     ]),
  //   );
  //   sheet.appendRow(toCellRow([""]));

  //   sheet.appendRow(
  //     toCellRow([
  //       "COGS",
  //       "",
  //       cogsTarget.toStringAsFixed(0),
  //       cogsValue.toStringAsFixed(0),
  //       ((cogsValue / cogsTarget) * 100).toStringAsFixed(0),
  //     ]),
  //   );

  //   setState(() {
  //     // YtdSalesBarChartData = true;
  //   });

  //   if (kIsWeb) {
  //     // var fileBytes = excel.save(fileName: 'sales_analysis_ytd_report.xlsx');

  //     final excelBytes = excel.encode()!;
  //     saveAndOpenExcel('DailyCostingReport.xlsx', excelBytes);

  //     // var fileBytes = excel.encode();
  //     //
  //     // final blob = html.Blob([fileBytes]);
  //     // final url = html.Url.createObjectUrlFromBlob(blob);
  //     // final anchor = html.AnchorElement()
  //     //   ..href = url
  //     //   ..download = 'monthly_sales_report.xlsx'
  //     //   ..style.display = 'none';
  //     // html.document.body!.append(anchor);
  //     // anchor.click();
  //     // anchor.remove();
  //     // html.Url.revokeObjectUrl(url);
  //   } else {
  //     String storageDir = await getStorageDirectory();
  //     final file = File('$storageDir/DailyCostingReport.xlsx');
  //     await file.writeAsBytes(excel.encode()!);
  //     OpenFile.open(file.path);
  //   }
  // }

  Future<void> generateDailyCostingReport() async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Sheet1'];

    // ================= SAFE HELPERS =================
    double safeNum(num? v) => v?.toDouble() ?? 0;

    double safePercent(num? value, num? target) {
      final v = safeNum(value);
      final t = safeNum(target);
      if (t == 0) return 0;
      return (v / t) * 100;
    }

    // ================= STYLE =================
    xl.CellStyle borderedStyle(
      dynamic value, {
      bool bold = false,
      bool center = false,
    }) {
      return xl.CellStyle(
        bold: bold,
        horizontalAlign: center
            ? xl.HorizontalAlign.Center
            : (value is num
                  ? xl.HorizontalAlign.Right
                  : xl.HorizontalAlign.Left),
        verticalAlign: xl.VerticalAlign.Center,
        topBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
        bottomBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
        leftBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
        rightBorder: xl.Border(borderStyle: xl.BorderStyle.Thin),
      );
    }

    // ================= CELL HELPER =================
    void setCell({
      required int row,
      required int col,
      required dynamic value,
      bool bold = false,
      bool center = false,
    }) {
      final cell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
      );

      if (value is num) {
        if (value.isNaN || value.isInfinite) {
          cell.value = xl.DoubleCellValue(0);
        } else {
          cell.value = xl.DoubleCellValue(value.toDouble());
        }
      } else {
        cell.value = xl.TextCellValue(value?.toString() ?? "");
      }

      cell.cellStyle = borderedStyle(value, bold: bold, center: center);
    }

    int row = 0;

    // ================= HEADER =================
    setCell(
      row: row,
      col: 0,
      value: DateTime.now().toString().substring(0, 10),
      bold: true,
      center: true,
    );

    sheet.merge(
      xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
    );
    sheet.setRowHeight(row, 25);
    row++;

    setCell(
      row: row,
      col: 0,
      value: "Financial Target for FY 25-26",
      bold: true,
      center: true,
    );

    sheet.merge(
      xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
    );
    sheet.setRowHeight(row, 30);
    row++;

    // ================= TARGET HEADER =================
    setCell(row: row, col: 0, value: "");
    setCell(row: row, col: 1, value: "Target", bold: true, center: true);
    setCell(row: row, col: 2, value: "Achievement", bold: true, center: true);
    setCell(row: row, col: 3, value: "Percentage", bold: true, center: true);
    setCell(row: row, col: 4, value: "");
    row++;

    // ================= COLUMN HEADERS =================
    setCell(row: row, col: 0, value: "");
    setCell(row: row, col: 1, value: "Mar-26 Target", bold: true);
    setCell(row: row, col: 2, value: "");
    setCell(row: row, col: 3, value: "Mar-26", bold: true);
    setCell(row: row, col: 4, value: "%", bold: true);
    row++;

    // ================= REVENUE =================
    double totalTarget = safeNum(medicalDeviceTarget) + safeNum(ipdTarget);

    setCell(row: row, col: 0, value: "Revenue", bold: true);
    setCell(row: row, col: 1, value: totalTarget);
    setCell(row: row, col: 2, value: "");
    setCell(row: row, col: 3, value: safeNum(monthlySales));
    setCell(row: row, col: 4, value: safePercent(monthlySales, totalTarget));
    row++;

    setCell(row: row, col: 1, value: "Medical Devices");
    setCell(row: row, col: 2, value: safeNum(medicalDeviceTarget));
    setCell(row: row, col: 3, value: safeNum(medicalDevicesSales));
    setCell(
      row: row,
      col: 4,
      value: safePercent(medicalDevicesSales, medicalDeviceTarget),
    );
    row++;

    setCell(row: row, col: 1, value: "IPD");
    setCell(row: row, col: 2, value: safeNum(ipdTarget));
    setCell(row: row, col: 3, value: safeNum(ipdSales));
    setCell(row: row, col: 4, value: safePercent(ipdSales, ipdTarget));
    row++;

    // ================= PENDING SALES =================
    row++;

    setCell(row: row, col: 0, value: "Pending Sales Order", bold: true);
    setCell(row: row, col: 3, value: safeNum(monthlySOvalue));
    row++;

    setCell(row: row, col: 1, value: "Low Priority");
    setCell(row: row, col: 3, value: safeNum(lowVal));
    row++;

    setCell(row: row, col: 1, value: "Medium Priority");
    setCell(row: row, col: 3, value: safeNum(mediumVal));
    row++;

    setCell(row: row, col: 1, value: "High Priority");
    setCell(row: row, col: 3, value: safeNum(highVal));
    row++;

    // ================= RIGHT PANEL =================
    int rightCol = 6;

    setCell(row: 2, col: rightCol, value: "Pending Sales Order", bold: true);

    setCell(row: 3, col: rightCol, value: "Bangalore");
    setCell(row: 3, col: rightCol + 1, value: safeNum(karnatakaPOSum));

    setCell(row: 4, col: rightCol, value: "Rajapalayam");
    setCell(row: 4, col: rightCol + 1, value: safeNum(tamilNaduPOSum));

    setCell(row: 5, col: rightCol, value: "Others");
    setCell(row: 5, col: rightCol + 1, value: safeNum(othersPOSum));

    setCell(row: 6, col: rightCol, value: "Total", bold: true);
    setCell(
      row: 6,
      col: rightCol + 1,
      value:
          safeNum(karnatakaPOSum) +
          safeNum(tamilNaduPOSum) +
          safeNum(othersPOSum),
    );

    // ================= PURCHASE =================
    row += 2;

    setCell(row: row, col: 0, value: "Purchases", bold: true);
    setCell(row: row, col: 1, value: safeNum(purchaseTarget));
    setCell(row: row, col: 3, value: safeNum(monthlyPurchasePriceGrnSum));
    setCell(
      row: row,
      col: 4,
      value: safePercent(monthlyPurchasePriceGrnSum, purchaseTarget),
    );
    row++;

    // ================= INVENTORY =================
    row++;

    setCell(row: row, col: 0, value: "Inventory Aging", bold: true);
    setCell(row: row, col: 1, value: safeNum(inventoryTarget));
    setCell(row: row, col: 3, value: safeNum(inventoryClosingValue));
    row++;

    setCell(row: row, col: 1, value: "<30 Days");
    setCell(row: row, col: 3, value: safeNum(lessThan30DaysValue));
    row++;

    setCell(row: row, col: 1, value: "31-60 Days");
    setCell(row: row, col: 3, value: safeNum(a30to60DaysValue));
    row++;

    setCell(row: row, col: 1, value: "61-90 Days");
    setCell(row: row, col: 3, value: safeNum(a60to90DaysValue));
    row++;

    setCell(row: row, col: 1, value: ">90 Days");
    setCell(row: row, col: 3, value: safeNum(a91DaysValue));
    row++;

    // ================= COGS =================
    row++;

    setCell(row: row, col: 0, value: "COGS", bold: true);
    setCell(row: row, col: 1, value: safeNum(cogsTarget));
    setCell(row: row, col: 3, value: safeNum(cogsValue));
    setCell(row: row, col: 4, value: safePercent(cogsValue, cogsTarget));

    // ================= COLUMN WIDTH =================
    sheet.setColumnWidth(0, 28);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 10);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 12);
    sheet.setColumnWidth(6, 18);
    sheet.setColumnWidth(7, 18);

    // ================= SAVE =================
    final bytes = excel.encode();
    if (bytes == null) {
      // print("Excel encoding failed");
      return;
    }

    if (kIsWeb) {
      saveAndOpenExcel('DailyCostingReport.xlsx', bytes);
    } else {
      String dir = await getStorageDirectory();
      final file = File('$dir/DailyCostingReport.xlsx');
      await file.writeAsBytes(bytes);
      OpenFile.open(file.path);
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
      tillLastMonthPOSum = 0;

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
      // selectedCheckbox = index;
    });
  }

  Future<void> _dateFilterTarget() async {
    setState(() {
      context.read<DailyCostingInventoryClosingProvider>().updateInventoryList(
        inventoryClosing,
      );
      context.read<DailyCostingInventoryProvider>().updateInventoryList(
        inventory,
      );
      context.read<DailyCostingPOProvider>().updatePOList(poListOpen);
      context.read<DailyCostingGRNProvider>().updatePurchaseList(grnList);
      context.read<DailyCostingPurchaseProvider>().updatePurchaseList(
        purchasePrice,
      );
      context.read<DailyCostingSOListProvider>().updateSOList(soList);
      context.read<DailyCostingSalesProvider>().updateSalesList(sales);

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
    _loadDailyCostingReport(touchedPriority!, touchedWarehouse!);
    chartDataLoadedDailyCosting = true;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        chartDataLoadedDailyCosting
            ? SingleChildScrollView(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            PopupMenuButton(
                              onSelected: (value) {},
                              itemBuilder: (BuildContext bc) {
                                return [
                                  PopupMenuItem(
                                    onTap: () {
                                      generateDailyCostingReport();
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

                    const Padding(
                      padding: EdgeInsets.fromLTRB(10, 2, 8, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Daily Costing",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                      child: _dailyCostingGraph(),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0, right: 16.0),
                      child: Divider(thickness: 2),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(10, 16, 8, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Revenue",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                      child: _revenueBreakupGraph(),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0, right: 16.0),
                      child: Divider(thickness: 2),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(10, 16, 8, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Pending Sales Order - Priority Wise",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                      child: _pendingSalesOrderPriorityGraph(),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0, right: 16.0),
                      child: Divider(thickness: 2),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(10, 16, 8, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Pending Sales Order - Warehouse Wise",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                      child: _pendingSalesOrderWarehouseGraph(),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0, right: 16.0),
                      child: Divider(thickness: 2),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(10, 16, 8, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Inventory Aging",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                      child: _inventoryAgingGraph(),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0, right: 16.0),
                      child: Divider(thickness: 2),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
        // Overlay Loader (if active)
        if (_loadingOverlay != null) const SizedBox.shrink(),
      ],
    );
  }

  Widget buildOld(BuildContext context) {
    return chartDataLoadedDailyCosting == true
        ? SingleChildScrollView(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        PopupMenuButton(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext bc) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  generateDailyCostingReport();
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

                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 2, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Daily Costing",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _dailyCostingGraph(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 16, 8, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Revenue",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _revenueBreakupGraph(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 16, 8, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Pending Sales Order - Priority Wise",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _pendingSalesOrderPriorityGraph(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 16, 8, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Pending Sales Order - Warehouse Wise",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _pendingSalesOrderWarehouseGraph(),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Divider(thickness: 2),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 16, 8, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Inventory Aging",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: _inventoryAgingGraph(),
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

  Widget _dailyCostingGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = dailyCostingData.graphData.length;
    if (len > 5) {
      chartWidth = screenWidth + (80 * len);
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            maxY: chartMaxY,
            minY: chartMinY,
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
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
            barGroups: _monthlyAnalysisChartData(dailyCostingData.graphData),
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
    );
  }

  Widget _revenueBreakupGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = revenueBreakup.graphData.length;
    if (len > 5) {
      chartWidth = screenWidth + (80 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? revenueBreakup.graphData
              .map((data) => data.achievement)
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
    );
  }

  Widget _pendingSalesOrderPriorityGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = saleOrderPriorityBreakup.graphData.length;
    if (len > 5) {
      chartWidth = screenWidth + (80 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? saleOrderPriorityBreakup.graphData
              .map((data) => data.achievement)
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
                if (barTouchResponse != null && barTouchResponse.spot != null) {
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
    );
  }

  Widget _pendingSalesOrderWarehouseGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = saleOrderWarehouseBreakup.graphData.length;
    if (len > 5) {
      chartWidth = screenWidth + (80 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? saleOrderWarehouseBreakup.graphData
              .map((data) => data.achievement)
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
                if (barTouchResponse != null && barTouchResponse.spot != null) {
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
    );
  }

  Widget _inventoryAgingGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = inventoryAging.graphData.length;
    if (len > 5) {
      chartWidth = screenWidth + (80 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? inventoryAging.graphData
              .map((data) => data.achievement)
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
