// ignore_for_file: no_leading_underscores_for_local_identifiers, non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'manpower_dashboard_page.dart';
import 'manpower_models.dart';

class ManpowerController extends ChangeNotifier {
  DateTime? currentDate;
  DateTime? currentMonthFromDate;
  DateTime? currentMonthToDate;
  DateTime? lastMonthFromDate;
  DateTime? lastMonthToDate;
  DateTime? fiscalYearStartDate;
  DateTime? q1FromDate;
  DateTime? q1ToDate;
  DateTime? q2FromDate;
  DateTime? q2ToDate;
  DateTime? q3FromDate;
  DateTime? q3ToDate;
  DateTime? q4FromDate;
  DateTime? q4ToDate;
  List<ProductionOrderList> production = [];
  List<ProductionOrderList> productionTemp = [];
  List<RCPList> rcpList = [];
  List<MonthlyCTCList> ctcList = [];
  Map<String, double> monthlyProductionMap = {};
  Map<String, double> monthlyBoxMap = {};
  Map<String, Map<int, DailyProductionData>> dailyProductionMap = {};
  double qtyPercent = 0;
  double boxPercent = 0;
  double qtyProduced = 0;
  double boxProduced = 0;
  bool loaded = false;
  final totals = ProductionTotals();
  final targets = ProductionTargets();
  final charts = ChartData();
  final table = TableDataModel();
  List<SalesTargetList> salesTargets = [];
  final DateFormat _df = DateFormat('dd/MM/yyyy');
  double currentMonthAverageBoxes = 0;
  int selectedMonthIndex = -1;
  int? selectedMonth;
  int? selectedYear;

  String getMonthName(int month) {
    final formatter = DateFormat('MMMM');
    return formatter.format(DateTime(2000, month));
  }

  String getApiMonthKey(int month) {
    const months = [
      '',
      'jan',
      'feb',
      'mar',
      'april',
      'may',
      'june',
      'july',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];

    return months[month];
  }

  double _percent(double value, double target) {
    if (target <= 0) return 0;

    final p = (value * 100) / target;

    return p > 100 ? 100 : p;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    return double.tryParse(v.toString()) ?? 0;
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

    int fiscalYear = currentDate!.month >= fiscalYearStartMonth
        ? currentDate!.year
        : currentDate!.year - 1;
    fiscalYearStartDate = DateTime(fiscalYear, fiscalYearStartMonth, 1);
  }

  Map<String, dynamic> _baseRequest(int index, int limit) {
    return {
      "FromDate": formatDate(fiscalYearStartDate!),
      "ToDate": formatDate(currentDate!),
      "Index": index.toString(),
      "Limit": limit.toString(),
      "sapToken": DataManager.readSapToken(),
    };
  }

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

  void calculateDailyAverage(List<DailyProductionData> list) {
    double sum = 0;

    for (final d in list) {
      sum += d.boxNo;
    }

    if (list.isNotEmpty) {
      currentMonthAverageBoxes = sum / list.length;
    }
  }

  Map<String, DateTime> getLastThreeMonthsRange(int monthIndex) {
    // Ensure the month index is valid (1 to 12)
    if (monthIndex < 1 || monthIndex > 12) {
      throw ArgumentError('Invalid month index. Must be between 1 and 12.');
    }

    DateTime now = DateTime.now();

    // Financial year start (April to March)
    int financialYearStart = (now.month >= 4) ? now.year : now.year - 1;

    // Determine the year for the given month
    int yearForMonth = (monthIndex >= 4)
        ? financialYearStart
        : financialYearStart + 1;

    // Adjust the start month to handle wrapping to the previous year
    int startMonthIndex = monthIndex - 3;
    int startYear = yearForMonth;
    if (startMonthIndex < 1) {
      startMonthIndex += 12; // Wrap to the previous year
      startYear--; // Adjust the year
    }

    // Calculate start and end dates
    DateTime startDate = DateTime(startYear, startMonthIndex, 1);
    DateTime endDate = DateTime(yearForMonth, monthIndex, 0);

    return {'fromDate': startDate, 'toDate': endDate};
  }

  void _prepareProductionCache() {
    monthlyProductionMap.clear();
    monthlyBoxMap.clear();
    dailyProductionMap.clear();

    totals.currentMonthQty = 0;
    totals.currentMonthBoxes = 0;

    totals.last3MonthQty = 0;
    totals.last3MonthBoxes = 0;

    totals.financialYearQty = 0;
    totals.financialYearBoxes = 0;

    final int year = selectedYear ?? currentDate!.year;
    final int month = selectedMonth == -1
        ? currentDate!.month
        : selectedMonth ?? currentDate!.month;

    final DateTime monthFromDate = DateTime(year, month, 1);
    final DateTime monthToDate = DateTime(year, month + 1, 0);

    final DateTime last3MonthFromDate = DateTime(year, month - 3, 1);
    final DateTime last3MonthToDate = DateTime(year, month, 0);

    for (final rec in production) {
      final DateTime d = _df.parse(rec.orderDate);

      final qty = _toDouble(rec.completedQty);
      final boxQty = _toDouble(rec.boxQty);

      final boxes = boxQty > 0 ? qty / boxQty : 0;

      /// CURRENT MONTH TOTAL
      if (!d.isBefore(monthFromDate) && !d.isAfter(monthToDate)) {
        totals.currentMonthQty += qty;
        totals.currentMonthBoxes += boxes;
      }

      /// LAST 3 MONTH TOTAL
      if (!d.isBefore(last3MonthFromDate) && !d.isAfter(last3MonthToDate)) {
        totals.last3MonthQty += qty;
        totals.last3MonthBoxes += boxes;
      }

      /// FINANCIAL YEAR TOTAL
      if (!d.isBefore(fiscalYearStartDate!) && !d.isAfter(currentDate!)) {
        totals.financialYearQty += qty;
        totals.financialYearBoxes += boxes;
      }

      /// MONTH KEY
      final String monthKey = "${d.year}-${d.month}";

      monthlyProductionMap[monthKey] =
          (monthlyProductionMap[monthKey] ?? 0) + qty;

      monthlyBoxMap[monthKey] = (monthlyBoxMap[monthKey] ?? 0) + boxes;

      /// DAILY MAP
      final String dailyKey = "${d.year}-${d.month}";

      dailyProductionMap.putIfAbsent(dailyKey, () => {});

      final dayMap = dailyProductionMap[dailyKey]!;

      if (!dayMap.containsKey(d.day)) {
        dayMap[d.day] = DailyProductionData(
          date: DateTime(d.year, d.month, d.day),
          dayLabel: DateFormat(
            'dd MMM',
          ).format(DateTime(d.year, d.month, d.day)),
          production: qty,
          boxNo: boxes.round(),
        );
      } else {
        final existing = dayMap[d.day]!;

        dayMap[d.day] = DailyProductionData(
          date: existing.date,
          dayLabel: existing.dayLabel,
          production: existing.production + qty,
          boxNo: existing.boxNo + boxes.round(),
        );
      }
    }
  }

  void rebuildCharts() {
    _prepareProductionCache();

    _buildMonthlyBarChart();
    _buildMonthlyLineChart();

    _buildDailyBarChart();
    _buildDailyLineChart();
    targets.qtyAchievementPercent = _percent(
      totals.currentMonthQty,
      targets.qtyTarget,
    );

    targets.boxAchievementPercent = _percent(
      totals.currentMonthBoxes,
      targets.boxTarget,
    );

    _calculateMetrics();
  }

  void applyBranchFilter(String branch) {
    production = productionTemp.where((e) => e.branch == branch).toList();

    rebuildCharts();
    notifyListeners();
  }

  void applyMonthFilter(int month) {
    // selectedMonth = month;
    selectedMonth = month == -1 ? currentDate!.month : month;

    final int fyStartYear = fiscalYearStartDate!.year;
    selectedYear = month != -1
        ? (month >= 4)
              ? fyStartYear
              : fyStartYear + 1
        : currentDate!.year;
    LoadDates();
    if (month < 0) {
      clearMonthFilter();

      return;
    }

    /// Jan–Mar belong to next calendar year
    final int year = (month >= 4) ? fyStartYear : fyStartYear + 1;

    final DateTime fromDate = DateTime(year, month, 1);
    final DateTime toDate = DateTime(year, month + 1, 0);

    production = productionTemp.where((rec) {
      final DateTime d = _df.parse(rec.orderDate);

      return !d.isBefore(fromDate) && !d.isAfter(toDate);
    }).toList();

    rebuildCharts();
    // notifyListeners();
  }

  void clearMonthFilter() {
    production = List.from(productionTemp);
    rebuildCharts();
  }

  void clearBranchFilter() {
    production = productionTemp;

    rebuildCharts();
  }

  String? _getItemSubGroup(dynamic item) {
    try {
      return (item.itemSubGroup ?? '').toString().trim();
    } catch (_) {
      if (item is Map && item.containsKey('itemSubGroup')) {
        return (item['itemSubGroup'] ?? '').toString().trim();
      }
    }
    return null;
  }

  Future<String> loadDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('userName') ?? '';
      final userLevel = prefs.getString('userLevel') ?? '';
      final userJwtToken = prefs.getString('userJwtToken') ?? '';
      final userMailID = prefs.getString('userMailID') ?? '';
      LoadDates();
      await Future.wait([
        _loadProductionOrderTargetAnalysis(userName, userLevel),
        _loadRCPList(userName, userLevel),
        _loadTarget(userName, userLevel),
        _loadMonthlyCTCList(userName, userLevel, userJwtToken, userMailID),
      ]);

      _prepareProductionCache();

      _buildMonthlyBarChart();
      _buildMonthlyLineChart();

      _buildDailyBarChart();
      _buildDailyLineChart();

      _calculateMetrics();
      _buildTable();
      loaded = true;
      return ""; // success
    } catch (e) {
      if (kDebugMode) {
        print("Dashboard error: $e");
      }
      return "Failed to load dashboard data.";
    }
  }

  Future<void> _loadProductionOrderTargetAnalysis(
    String userName,
    String userLevel,
  ) async {
    LoadAllQuarterFromToDates();

    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;

    List<ProductionOrderList> salesList = [];

    try {
      do {
        final body = _baseRequest(index, limit);

        const apiUrl = '${ApiHelper.baseUrl}BicxoProductionAnalysis';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode != 200) return;
        final json = jsonDecode(response.body);
        final List list = json['responseData'] ?? [];
        final newSalesList = list
            .where(
              (e) =>
                  (e['status'] ?? '').toString().toLowerCase().trim() !=
                  'canceled',
            )
            .map((e) => ProductionOrderList.fromJson(e))
            .toList();

        salesList.addAll(newSalesList);

        fetchedCount = list.length;

        index++;
      } while (fetchedCount == limit);

      /// FILTER REQUIRED ITEM SUBGROUPS

      final allowed = {
        'Wrap Sheet',
        'Packs',
        'Gowns',
        'Safety Packs',
        'Drapes',
      };

      production = salesList
          .where((e) => allowed.contains(e.itemSubGroup))
          .toList();

      // productionTemp = production;
      productionTemp = List.from(production);
    } catch (e) {
      if (kDebugMode) {
        print("Production API error: $e");
      }
    }
  }

  Future<void> _loadRCPList(String userName, String userLevel) async {
    int index = 0;
    const int limit = 10000;

    final List<RCPList> list = [];

    try {
      while (true) {
        final body = _baseRequest(index, limit);

        const apiUrl = '${ApiHelper.baseUrl}BicxoRCPList';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode != 200) break;

        final Map<String, dynamic> responseJson = jsonDecode(response.body);

        final data = responseJson["responseData"];

        if (data == null || data.toString().isEmpty) break;

        final newList = (data as List)
            .map((item) => RCPList.fromJson(item))
            .toList();

        list.addAll(newList);

        /// if fewer than limit returned → last page
        if (newList.length < limit) break;

        index++;
      }

      /// assign final list
      rcpList = list;
    } catch (e) {
      if (kDebugMode) {
        print("RCP API error: $e");
      }
    }
  }

  Future<void> _loadMonthlyCTCList(
    String userName,
    String userLevel,
    String userJwtToken,
    String userMailID,
  ) async {
    try {
      final body = {
        "UsermailID": userMailID,
        "UserJwtToken": userJwtToken,
        "MonthYear": DateFormat('yyyy-MM').format(currentDate!),
      };

      const apiUrl = '${ApiHelper.baseUrl}selectmonthlyctcdetails';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        if (kDebugMode) {
          print("CTC API error: ${response.statusCode}");
        }
        return;
      }

      final Map<String, dynamic> responseJson = jsonDecode(response.body);

      if (responseJson["Status"] != true ||
          responseJson["Data"] == null ||
          (responseJson["Data"] as List).isEmpty) {
        ctcList = [];
        return;
      }

      /// Parse response

      final List data = responseJson["Data"];

      ctcList = data.map((item) => MonthlyCTCList.fromJson(item)).toList();
    } catch (e) {
      if (kDebugMode) {
        print("CTC API exception: $e");
      }
    }
  }

  Future<String?> _loadTarget(String userName, String userLevel) async {
    final body = _baseRequest(0, 0);
    const apiUrl = '${ApiHelper.baseUrl}BicxoSalesTargetList';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        return "Sales target details not found.";
      }

      final Map<String, dynamic> responseJson = jsonDecode(response.body);

      if (responseJson["responseData"] == null ||
          responseJson["responseData"].toString().isEmpty) {
        return responseJson["Error"]?.toString() ?? "No target data found";
      }

      final List data = responseJson['responseData'];

      salesTargets = data
          .map((item) => SalesTargetList.fromJson(item))
          .toList();

      /// FIND TARGETS  qtyPercent, boxPercent, qtyProduced, boxProduced

      final monthName = getMonthName(currentDate!.month);

      for (var target in salesTargets) {
        if (target.salesRep == "PRODUCTION QTY TARGET") {
          targets.qtyTarget =
              double.tryParse(target.getTargetForMonth(monthName)) ?? 0;
        }

        if (target.salesRep == "PRODUCTION BOX QTY TARGET") {
          targets.boxTarget =
              double.tryParse(target.getTargetForMonth(monthName)) ?? 0;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print("Target API error: $e");
      }

      return "SAP Server down. Please try again later.";
    }
  }

  Future<void> filterByItemSubGroup(String subGroup) async {
    // reset list
    loaded = false;
    production = productionTemp;
    if (subGroup == "All") {
      rebuildCharts();
      loaded = true;
      return;
    }

    final sel = subGroup.trim().toLowerCase();
    const kitsGroups = {'packs', 'gowns', 'safety packs', 'drapes'};

    production = production.where((item) {
      final val = _getItemSubGroup(item);
      if (val == null) return false;

      final normalized = val.toLowerCase();

      if (sel == 'kits/gowns') {
        return kitsGroups.contains(normalized);
      }

      return normalized == sel;
    }).toList();

    /// rebuild charts
    rebuildCharts();
    loaded = true;
  }

  void _buildMonthlyBarChart() {
    final List<MonthlyProductionData> list = [];
    final DateTime start = fiscalYearStartDate!; // April of FY start
    for (int i = 0; i < 12; i++) {
      final DateTime m = DateTime(start.year, start.month + i, 1);

      final int year = m.year;
      final int month = m.month;

      final String monthName = getMonthName(month);

      final String key = "$year-$month";

      final productionSum = monthlyProductionMap[key] ?? 0;
      final boxSum = monthlyBoxMap[key] ?? 0;

      double monthlyTarget = 0;

      for (final t in salesTargets) {
        if (t.salesRep == "PRODUCTION QTY TARGET") {
          monthlyTarget = double.tryParse(t.getTargetForMonth(monthName)) ?? 0;
        }
      }

      list.add(
        MonthlyProductionData(
          monthName: monthName,
          target: monthlyTarget,
          production: productionSum,
          boxNo: boxSum.round(),
        ),
      );
    }

    charts.monthlyBar = list;
  }

  void _buildMonthlyLineChart() {
    final List<MonthlyProductionData> list = [];

    final int fyStartYear = fiscalYearStartDate!.year;

    for (int i = 4; i <= 15; i++) {
      final int month = i > 12 ? i - 12 : i;

      final int year = i <= 12 ? fyStartYear : fyStartYear + 1;

      final String monthName = getMonthName(month);

      final String key = "$year-$month";

      final productionSum = monthlyProductionMap[key] ?? 0;
      final boxSum = monthlyBoxMap[key] ?? 0;

      final range = getLastThreeMonthsRange(month);

      double targetSum = 0;

      for (final rec in production) {
        final d = _df.parse(rec.orderDate);

        if (!d.isBefore(range['fromDate']!) && !d.isAfter(range['toDate']!)) {
          targetSum += _toDouble(rec.completedQty);
        }
      }

      final monthlyTarget = targetSum / 3;

      list.add(
        MonthlyProductionData(
          monthName: monthName,
          target: monthlyTarget,
          production: productionSum,
          boxNo: boxSum.round(),
        ),
      );
    }

    charts.monthlyLine = list;
  }

  void _buildDailyBarChart() {
    final int year = selectedYear ?? currentDate!.year;
    final int month = selectedMonth == -1
        ? currentDate!.month
        : selectedMonth ?? currentDate!.month;

    final String key = "$year-$month";

    final Map<int, DailyProductionData> map = dailyProductionMap[key] ?? {};

    final List<DailyProductionData> list = map.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    calculateDailyAverage(list);

    charts.dailyBar = list;
  }

  void _buildDailyLineChart() {
    charts.dailyLine = charts.dailyBar;
  }

  void _calculateMetrics() {
    qtyProduced = totals.currentMonthQty;
    boxProduced = totals.currentMonthBoxes;
    qtyPercent = _percent(qtyProduced, targets.qtyTarget);
    boxPercent = _percent(boxProduced, targets.boxTarget);
  }

  void _buildTable() {
    table.particulars = particulars;

    table.rows = [
      /// Produced Qty
      _row(
        totals.currentMonthQty,
        targets.qtyTarget,
        totals.currentMonthQty,
        totals.last3MonthQty,
        totals.financialYearQty,
      ),

      _row(
        totals.currentMonthBoxes,
        targets.boxTarget,
        totals.currentMonthBoxes,
        totals.last3MonthBoxes,
        totals.financialYearBoxes,
      ),
    ];
  }

  List<String> _row(
    double total,
    double target,
    double month,
    double last3,
    double fy,
  ) {
    return [
      total.toStringAsFixed(2),
      _percent(total, target).toStringAsFixed(2),

      month.toStringAsFixed(2),
      _percent(month, total).toStringAsFixed(2),

      last3.toStringAsFixed(2),
      _percent(last3, total).toStringAsFixed(2),

      fy.toStringAsFixed(2),
      _percent(fy, total).toStringAsFixed(2),
    ];
  }
}
