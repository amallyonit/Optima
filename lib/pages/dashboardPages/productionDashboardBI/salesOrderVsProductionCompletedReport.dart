// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, strict_top_level_inference
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/dataManager.dart';
import '../../../classes/globals.dart';
import '../../../classes/leads.dart';
import '../ReportService.dart';

final reportService = ReportService();

class SalesOrderVsProductionCompletedReport extends StatefulWidget {
  const SalesOrderVsProductionCompletedReport({super.key});

  @override
  State<SalesOrderVsProductionCompletedReport> createState() =>
      _SalesOrderVsProductionCompletedReportState();
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

double totalSalesOrderQty = 0;
double totalPendingQty = 0;
double totalBoxQty = 0;
String totalSalesOrderQtyStr = "";
String totalPendingQtyStr = "";
String totalBoxQtyStr = "";
int avgOrderCompletionDays = 0;
int avgDaysTakenToClose = 0;

bool chartDataLoaded = false;
String touchedHospital = "";
List<DeliveryReportList> productionCompleted = [];
List<Users> usersList = [];

PriorityStatusAnalysisList priorityData = PriorityStatusAnalysisList(
  priorityData: [],
);
OrderStatusAnalysisList orderData = OrderStatusAnalysisList(orderData: []);
HospitalWiseCompletedReportList hospitalData = HospitalWiseCompletedReportList(
  hospitalData: [],
);

class SalesOrderVsProductionProvider with ChangeNotifier {
  List<DeliveryReportList> _salesList = [];
  List<DeliveryReportList> get salesList => _salesList;
  void updateProductionList(List<DeliveryReportList> newSalesList) {
    _salesList = newSalesList;
    notifyListeners();
  }
}

class _SalesOrderVsProductionCompletedReportState
    extends State<SalesOrderVsProductionCompletedReport> {
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
    DateTime now = DateTime.now();
    int financialYearStart = (now.month >= 4) ? now.year : now.year - 1;

    // Adjust the year based on the financial year
    int year = (now.month >= 4 && now.month <= 12)
        ? financialYearStart
        : financialYearStart + 1;
    currentDate = DateTime.now();
    currentMonthFromDate = DateTime(year, currentDate!.month, 1);
    currentMonthToDate = addMonth(
      currentMonthFromDate!,
      1,
    ).add(const Duration(days: -1));

    Map<String, DateTime> monthDates = getMonthStartEndDates(
      DateTime.now().month == 1 ? 12 : DateTime.now().month,
    );
    lastMonthFromDate = monthDates['start']!;
    lastMonthToDate = monthDates['end']!;
    int fiscalYearStartMonth = 4;

    getLastQuarterDates();

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

  SideTitles get _bottomTitlesHospitalWiseAnalysis => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<HospitalWiseCompletedReportData> mData = hospitalData.hospitalData;
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

  List<PieChartSectionData> showingSections() {
    final List<PieChartSectionData> sections = [];
    for (final categoryData in priorityData.priorityData) {
      final fontSize = touchedIndex >= 1 ? 12.0 : 11.0;
      final radius = touchedIndex >= 1 ? 80.0 : 75.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      final sectionData = PieChartSectionData(
        color: getCategoryColor(categoryData.priorityId),
        value: categoryData.percentage,
        title: '${categoryData.percentage.toStringAsFixed(2)} %',
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

  List<PieChartSectionData> showingSectionsSOStatus() {
    final List<PieChartSectionData> sections = [];
    for (final categoryData in orderData.orderData) {
      final fontSize = touchedIndex >= 1 ? 12.0 : 11.0;
      final radius = touchedIndex >= 1 ? 80.0 : 75.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      final sectionData = PieChartSectionData(
        color: getCategoryColor(categoryData.orderStatusId),
        value: categoryData.percentage,
        title: '${categoryData.percentage.toStringAsFixed(2)} %',
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

  List<BarChartGroupData> _hospitalWiseAnalysisChartData(
    List<HospitalWiseCompletedReportData> data,
  ) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                backDrawRodData: BackgroundBarChartRodData(
                  fromY: 0,
                  show: true,
                  toY: chartData.plannedQty,
                  color: const Color(0xFFF49136),
                ),
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.completedQty,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  Future<void> _loadProductionCompletedReportAnalysis(
    String UserName,
    String UserLevel,
  ) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<DeliveryReportList> salesList = [];
    int monthIndex = currentDate!.month;
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
        const apiUrl = '${ApiHelper.baseUrl}BicxoDeliveryReportList';
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
            List<DeliveryReportList> newSalesList =
                (responseJson['responseData'] as List)
                    .map((item) => DeliveryReportList.fromJson(item))
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
        productionCompleted = salesList;
        context.read<SalesOrderVsProductionProvider>().updateProductionList(
          salesList,
        );
        List<String> menuNames = usersList
            .where((element) => element.parentMenuId == 0)
            .map((user) => user.menuName)
            .toList();
        menuNames.insert(0, UserName);
        if (int.parse(UserLevel) == 5) {
          productionCompleted = salesList.toList();
        } else if (int.parse(UserLevel) == 4) {
          productionCompleted = salesList.toList();
        } else if (int.parse(UserLevel) <= 3 && int.parse(UserLevel) >= 2) {
          productionCompleted = salesList.toList();
        } else {
          productionCompleted = salesList.toList();
        }
      });
      var totalSO = productionCompleted.where((target) {
        DateTime invoiceDate = DateFormat('dd/MM/yyyy').parse(target.soDate);
        return invoiceDate.isAtLeast(currentMonthFromDate!) &&
            invoiceDate.isAtMost(currentDate!);
      });
      double soQty = 0, pendingQty = 0, boxQty = 0;
      for (var target in totalSO.toList()) {
        soQty += (double.tryParse(target.soQuantity) ?? 0);
        pendingQty += (double.tryParse(target.pendingQuantity) ?? 0);
        boxQty +=
            (double.tryParse(target.dnQuantity) ?? 0) ~/
            (double.tryParse(target.boxQuantity) ?? 0);
      }

      totalSalesOrderQty = soQty;
      totalSalesOrderQtyStr =
          "${(totalSalesOrderQty / 1000).toStringAsFixed(2)} K";

      totalPendingQty = pendingQty;
      totalPendingQtyStr = "${(totalPendingQty / 1000).toStringAsFixed(2)} K";

      totalBoxQty = boxQty;
      totalBoxQtyStr = totalBoxQty.toString();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> _loadPriorityStatusAnalysis(String hospitalCode) async {
    List<PriorityStatusAnalysisData> statusList = [];
    var tempList = productionCompleted;
    String statusName = "";
    double productActual = 0.00;
    int categoryId = 0;

    var saleList = const Iterable.empty();
    saleList = tempList.toList();

    Map<String, DateTime> monthDates = getMonthStartEndDates(
      DateTime.now().month,
    );
    saleList = saleList.where((target) {
      DateTime invoiceDate = DateFormat(
        'dd/MM/yyyy',
      ).parse(target.actualDeliveryDate);
      return (invoiceDate.isAtLeast(monthDates['start']!) &&
          invoiceDate.isAtMost(monthDates['end']!));
    });

    saleList = filterDeliveryList(
      saleList.cast<DeliveryReportList>().toList(),
      hospitalCode: hospitalCode,
    );

    Set<String> processedProductCodes = {};
    for (var product in saleList.toList().toList()) {
      if (!processedProductCodes.contains(product.priority)) {
        statusName = product.priority;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.priority == statusName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.pendingQuantity) ?? 0;
          productActual += salesAmt;
        }

        statusList.add(
          PriorityStatusAnalysisData(
            priorityId: categoryId++,
            amount: productActual,
            priority: statusName,
            percentage: 0,
          ),
        );
        processedProductCodes.add(product.priority);
      }
      productActual = 0;
      statusName = "";
    }

    double totalAmount = statusList.fold(
      0,
      (double previousValue, PriorityStatusAnalysisData element) =>
          previousValue + element.amount,
    );

    for (PriorityStatusAnalysisData categoryData in statusList) {
      categoryData.percentage =
          double.tryParse(
            ((categoryData.amount / totalAmount) * 100).toStringAsFixed(2),
          ) ??
          0;
      // categoryData.percentage = double.tryParse(
      //     (categoryData.amount / 100000).toStringAsFixed(2)) ??
      //     0;
    }

    priorityData = PriorityStatusAnalysisList(priorityData: statusList);
  }

  Future<void> _loadOrderStatusAnalysis(String hospitalCode) async {
    List<OrderStatusAnalysisData> statusList = [];
    var tempList = productionCompleted;
    String statusName = "";
    double productActual = 0.00;
    int categoryId = 0;

    var saleList = const Iterable.empty();
    saleList = tempList.toList();

    Map<String, DateTime> monthDates = getMonthStartEndDates(
      DateTime.now().month,
    );
    saleList = saleList.where((target) {
      DateTime invoiceDate = DateFormat(
        'dd/MM/yyyy',
      ).parse(target.actualDeliveryDate);
      return (invoiceDate.isAtLeast(monthDates['start']!) &&
          invoiceDate.isAtMost(monthDates['end']!));
    });

    saleList = filterDeliveryList(
      saleList.cast<DeliveryReportList>().toList(),
      hospitalCode: hospitalCode,
    );

    Set<String> processedProductCodes = {};
    for (var product in saleList.toList().toList()) {
      if (!processedProductCodes.contains(product.soStatus)) {
        statusName = product.soStatus;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.soStatus == statusName,
        )) {
          double salesAmt = 0;
          salesAmt = double.tryParse(target.soQuantity) ?? 0;
          productActual += salesAmt;
        }

        statusList.add(
          OrderStatusAnalysisData(
            orderStatusId: categoryId++,
            amount: productActual,
            orderStatus: statusName,
            percentage: 0,
          ),
        );
        processedProductCodes.add(product.soStatus);
      }
      productActual = 0;
      statusName = "";
    }

    double totalAmount = statusList.fold(
      0,
      (double previousValue, OrderStatusAnalysisData element) =>
          previousValue + element.amount,
    );

    for (OrderStatusAnalysisData categoryData in statusList) {
      categoryData.percentage =
          double.tryParse(
            ((categoryData.amount / totalAmount) * 100).toStringAsFixed(2),
          ) ??
          0;
      // categoryData.percentage = double.tryParse(
      //     (categoryData.amount / 100000).toStringAsFixed(2)) ??
      //     0;
    }

    orderData = OrderStatusAnalysisList(orderData: statusList);
  }

  Future<void> _loadHospitalWiseAnalysis(String hospitalCode) async {
    List<HospitalWiseCompletedReportData> productwiseDataList = [];
    var tempList = productionCompleted;
    String hospitalName = "";
    double planned = 0.00;
    double completed = 0.00;

    var saleList = const Iterable.empty();
    saleList = tempList.toList();

    Map<String, DateTime> monthDates = getMonthStartEndDates(
      DateTime.now().month,
    );
    saleList = saleList.where((target) {
      DateTime invoiceDate = DateFormat(
        'dd/MM/yyyy',
      ).parse(target.actualDeliveryDate);
      return (invoiceDate.isAtLeast(monthDates['start']!) &&
          invoiceDate.isAtMost(monthDates['end']!));
    });

    saleList = filterDeliveryList(
      saleList.cast<DeliveryReportList>().toList(),
      hospitalCode: hospitalCode,
    );

    Set<String> processedProductCodes = {};
    for (var product in saleList.toList().toList()) {
      if (!processedProductCodes.contains(product.customerName)) {
        hospitalName = product.customerName;
        for (var target in saleList.toList().where(
          (prdelement) => prdelement.customerName == hospitalName,
        )) {
          double plannedQty = double.tryParse(target.soQuantity) ?? 0;
          double completedQty = double.tryParse(target.dnQuantity) ?? 0;
          planned += plannedQty;
          completed += completedQty;
        }

        productwiseDataList.add(
          HospitalWiseCompletedReportData(
            hospitalName: hospitalName,
            plannedQty: planned,
            completedQty: completed,
          ),
        );
        processedProductCodes.add(product.customerName);
      }
      planned = 0;
      completed = 0;
      hospitalName = "";
    }
    productwiseDataList.sort((a, b) => b.plannedQty.compareTo(a.plannedQty));

    hospitalData = HospitalWiseCompletedReportList(
      hospitalData: productwiseDataList,
    );
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadProductionCompletedReportAnalysis(userName, userLevel);
    await _loadPriorityStatusAnalysis("");
    await _loadOrderStatusAnalysis("");
    await _loadHospitalWiseAnalysis("");
    chartDataLoaded = true;
  }

  List<DeliveryReportList> filterDeliveryList(
    List<DeliveryReportList> deliveryList, {
    String? hospitalCode,
  }) {
    List<DeliveryReportList> filteredDeliveryList = [];
    for (var delivery in deliveryList) {
      if ((hospitalCode == null ||
          hospitalCode.isEmpty ||
          delivery.customerName == hospitalCode)) {
        filteredDeliveryList.add(delivery);
      }
    }
    return filteredDeliveryList;
  }

  Future<void> removeFilter() async {
    touchedHospital = "";

    touchedMonthGoals = false;
    touchedQuarterGoals = false;
    touchedYTDGoals = false;
    clearVariables();
    LoadDates();
    await _loadPriorityStatusAnalysis("");
    await _loadOrderStatusAnalysis("");
    await _loadHospitalWiseAnalysis("");
    chartDataLoaded = true;
  }

  Future<void> loadDataWithFilter(String hospitalCode) async {
    clearVariablesForFilter();
    LoadDates();
    await _loadPriorityStatusAnalysis(hospitalCode);
    await _loadOrderStatusAnalysis(hospitalCode);
    await _loadHospitalWiseAnalysis(hospitalCode);
    chartDataLoaded = true;
  }

  void clearVariables() {
    setState(() {
      chartDataLoaded = false;
      priorityData = PriorityStatusAnalysisList(priorityData: []);
      orderData = OrderStatusAnalysisList(orderData: []);
      hospitalData = HospitalWiseCompletedReportList(hospitalData: []);
      touchedHospital = "";
    });
  }

  void clearVariablesForFilter() {
    setState(() {
      chartDataLoaded = false;
      priorityData = PriorityStatusAnalysisList(priorityData: []);
      orderData = OrderStatusAnalysisList(orderData: []);
      hospitalData = HospitalWiseCompletedReportList(hospitalData: []);
    });
  }

  Future<void> generatePriorityStatusExcel(
    PriorityStatusAnalysisList priorityStatusAnalysisList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'SOVsProductionAnalysis',
      headers: ['Priority', 'Priority Qty.', 'Priority %'],
      rows: priorityStatusAnalysisList.priorityData
          .map(
            (priorityData) => [
              priorityData.priority,
              priorityData.amount,
              priorityData.percentage,
            ],
          )
          .toList(),
      fileName: 'priority_status_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - SO Vs Production Analysis',
    );
  }

  Future<void> generatePriorityStatusPDF(
    PriorityStatusAnalysisList priorityStatusAnalysisList,
  ) async {
    await reportService.generatePDF(
      title: 'SOVsProductionAnalysis',
      headers: ['Priority', 'Priority Qty.', 'Priority %'],
      rows: priorityStatusAnalysisList.priorityData
          .map(
            (priorityData) => [
              priorityData.priority,
              priorityData.amount,
              priorityData.percentage,
            ],
          )
          .toList(),
      fileName: 'priority_status_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateOrderStatusExcel(
    OrderStatusAnalysisList orderStatusAnalysisList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'OrderStatusAnalysis',
      headers: ['Status', 'Status Qty.', 'Status %'],
      rows: orderStatusAnalysisList.orderData
          .map(
            (orderData) => [
              orderData.orderStatus,
              orderData.amount,
              orderData.percentage,
            ],
          )
          .toList(),
      fileName: 'order_status_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Order Status Analysis',
    );
  }

  Future<void> generateOrderStatusPDF(
    OrderStatusAnalysisList orderStatusAnalysisList,
  ) async {
    await reportService.generatePDF(
      title: 'OrderStatusAnalysis',
      headers: ['Status', 'Status Qty.', 'Status %'],
      rows: orderStatusAnalysisList.orderData
          .map(
            (orderData) => [
              orderData.orderStatus,
              orderData.amount,
              orderData.percentage,
            ],
          )
          .toList(),
      fileName: 'order_status_report.pdf',
      amountColumns: [2, 3],
    );
  }

  Future<void> generateHospitalwiseOrderExcel(
    HospitalWiseCompletedReportList hospitalWiseCompletedReportList,
  ) async {
    await reportService.generateExcel(
      sheetName: 'HospitalWiseOrderAnalysis',
      headers: ['Hospital Name', 'Planned Qty.', 'Completed Qty.'],
      rows: hospitalWiseCompletedReportList.hospitalData
          .map(
            (hospitalData) => [
              hospitalData.hospitalName,
              hospitalData.plannedQty,
              hospitalData.completedQty,
            ],
          )
          .toList(),
      fileName: 'hospitalwise_order_report.xlsx',
      amountColumns: [2, 3],
      addTotalRow: true,
      reportTitle: 'Production - Hospital Wise Order Analysis',
    );
  }

  Future<void> generateHospitalwiseOrderPDF(
    HospitalWiseCompletedReportList hospitalWiseCompletedReportList,
  ) async {
    await reportService.generatePDF(
      title: 'HospitalWiseOrderAnalysis',
      headers: ['Hospital Name', 'Planned Qty.', 'Completed Qty.'],
      rows: hospitalWiseCompletedReportList.hospitalData
          .map(
            (hospitalData) => [
              hospitalData.hospitalName,
              hospitalData.plannedQty,
              hospitalData.completedQty,
            ],
          )
          .toList(),
      fileName: 'hospitalwise_order_report.pdf',
      amountColumns: [2, 3],
    );
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
    return chartDataLoaded == true
        ? SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(children: [SizedBox(width: 15)]),
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
                        padding: const EdgeInsets.all(6.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF97D7F3),
                            border: Border.all(color: Colors.transparent),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "Total Sales Orders: $totalSalesOrderQtyStr",
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF97D7F3),
                            border: Border.all(color: Colors.transparent),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Total Pending Quantity: $totalPendingQtyStr',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF97D7F3),
                            border: Border.all(color: Colors.transparent),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('Total Box Quantity: $totalBoxQtyStr'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
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
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Avg Order Completion Days - \n$avgOrderCompletionDays',
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
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Avg Days taken to close - \n$avgDaysTakenToClose',
                                ),
                              ],
                            ),
                          ),
                        ),
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
                          "Priority Status Analysis",
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
                                    generatePriorityStatusExcel(priorityData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generatePriorityStatusPDF(priorityData);
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
                                      color: const Color(0xFF97D7F3),
                                      // color: getCategoryColor(categoryData.categoryId),
                                    ),
                                    const SizedBox(height: 6),
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
                          "Order Status Analysis",
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
                                    generateOrderStatusExcel(orderData);
                                  });
                                },
                                child: const Text("Download Excel"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  setState(() {
                                    generateOrderStatusPDF(orderData);
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
                            sections: showingSectionsSOStatus(),
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
                                      color: const Color(0xFFFF9F47),
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
                                  "Open",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Text(
                                  "Closed",
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
                          "Hospital Wise Analysis",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                  "Planned Qty.",
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
                                  "Completed Qty.",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
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
                (data) => data.plannedQty > data.completedQty
                    ? data.plannedQty
                    : data.completedQty,
              )
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
                      loadDataWithFilter(touchedHospital);
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
                    '${hospitalData.hospitalData[grpIndex].hospitalName}\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "Planned Qty : ${hospitalData.hospitalData[grpIndex].plannedQty}\n",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "Completed Qty : ${hospitalData.hospitalData[grpIndex].completedQty}\n",
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
